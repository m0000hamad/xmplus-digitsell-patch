<?php
namespace App\Jobs;

use Illuminate\Database\Capsule\Manager as DB;

/**
 * OpenVPN housekeeping, run every minute from TaskCommand (bin/ovpn.php):
 *
 *   1. tells the admin on Telegram when an OpenVPN server goes offline, loses
 *      one protocol, or comes back, as the panel does for its own servers;
 *   2. keeps the addresses of the domains on the bypass list up to date
 *      (app/Patch/Ovpn.php builds the customers' files from them).
 *
 * The agents report to app/Patch/Ovpn.php once a minute and each report moves
 * ovpn_node.heartbeat and says which OpenVPN instances (UDP, TCP) it could
 * reach. A server is
 *
 *   2  up        reporting, and every protocol on offer is running
 *   1  partial   reporting, but a protocol on offer is not running
 *   0  down      no report for STALE seconds, or nothing is running
 *
 * A message goes out when that changes. The first time a server is seen its
 * state is only recorded, so installing this sends nothing for servers that
 * are already up. Switched-off servers, and ones whose agent never reported,
 * are left out and forgotten. The state is written BEFORE the messages are
 * sent: a failed send loses one message, it never sends two.
 *
 * The job stamps `ovpn_job_last` on every run, which the OpenVPN settings card
 * shows - "never" there means the scheduler does not run this job.
 *
 * Settings rows (`settings.name`):
 *   ovpn_notify          0 switches the messages off (missing = on)
 *   ovpn_notify_state    {"<node id>": {"s": 2|1|0, "since": <unix time>}},
 *                        written by this job
 *   ovpn_job_last        unix time of the last run, written by this job
 *   tgjoin_admin_chats   admin chat ids, shared with the other patch jobs
 *                        (default: the panel's `telegramchatid`)
 *   telegramtoken        the panel's bot
 *   ovpn_bypass_custom   the bypass list, read here for its domains
 *   ovpn_bypass_cache    the domains' addresses, written here
 */
class OvpnJob
{
	/* same as OVPN_STALE in app/Patch/Ovpn.php: three missed reports */
	const STALE = 180;

	/* domains are looked up again this often */
	const RESOLVE_EVERY = 21600;

	/* at most this many domains, and this long per run */
	const RESOLVE_MAX = 40;
	const RESOLVE_BUDGET = 30;

	public function dispatch()
	{
		$this->putSetting('ovpn_job_last', time());

		try {
			$this->refreshBypass();
		} catch (\Throwable $e) {
			echo date('Y-m-d H:i:s') . ' bypass lookup failed: ' . $e->getMessage() . "\n";
		}

		if ((string) $this->setting('ovpn_notify') === '0') {
			return;
		}

		try {
			$nodes = DB::table('ovpn_node')->get();
		} catch (\Throwable $e) {
			return; // OpenVPN not installed yet
		}

		$state = json_decode((string) $this->setting('ovpn_notify_state'), true);
		$state = is_array($state) ? $state : [];
		$next = [];
		$messages = [];
		$now = time();

		foreach ($nodes as $node) {
			$id = (string) (int) $node->id;

			// a switched-off server, or one whose agent never reported, is not watched
			if ((int) $node->enabled !== 1 || (int) $node->heartbeat <= 0) {
				continue;
			}

			list($level, $down) = $this->level($node, $now);

			$before = isset($state[$id]) && is_array($state[$id]) ? $state[$id] : null;

			if ($before === null) {
				$next[$id] = ['s' => $level, 'since' => $now];
				continue;
			}

			// the first version of this state was {"up": 0|1}
			$was = isset($before['s']) ? (int) $before['s'] : (!empty($before['up']) ? 2 : 0);

			if ($was === $level) {
				$next[$id] = ['s' => $was, 'since' => (int) ($before['since'] ?? $now)];
				continue;
			}

			$next[$id] = ['s' => $level, 'since' => $now];
			$messages[] = $this->text($node, $was, $level, $down, $now, $now - (int) ($before['since'] ?? $now));
		}

		// recorded first: a send that fails is not repeated next minute
		$this->putSetting('ovpn_notify_state', json_encode((object) $next));

		if ($messages === []) {
			return;
		}

		$token = trim((string) $this->setting('telegramtoken'));
		$chats = trim((string) $this->setting('tgjoin_admin_chats'));
		if ($chats === '') {
			$chats = trim((string) $this->setting('telegramchatid'));
		}
		if ($token === '' || $chats === '') {
			echo date('Y-m-d H:i:s') . ' ' . count($messages) . " message(s) not sent: no bot token or no admin chat\n";
			return;
		}

		foreach ($messages as $text) {
			foreach (preg_split('~[\s,]+~', $chats, -1, PREG_SPLIT_NO_EMPTY) as $chat) {
				$reply = $this->api($token, 'sendMessage', ['chat_id' => $chat, 'text' => $text]);
				echo date('Y-m-d H:i:s') . ' to ' . $chat . ': '
					. (!empty($reply['ok']) ? 'sent' : 'FAILED ' . ($reply['description'] ?? 'no answer from Telegram')) . "\n";
			}
		}
	}

	// ------------------------------------------------------------ the state

	/* the protocols customers get from a node - keep in step with ovpnOffered() in app/Patch/Ovpn.php */
	private function offered($node)
	{
		$running = [];
		$listen = json_decode((string) ($node->listen_json ?? ''), true);

		if (is_array($listen) && $listen !== []) {
			foreach (['udp', 'tcp'] as $proto) {
				if (isset($listen[$proto])) {
					$running[] = $proto;
				}
			}
		} else {
			$running[] = strpos(strtolower((string) $node->proto), 'tcp') === 0 ? 'tcp' : 'udp';
		}

		$offer = (string) ($node->offer ?? '');
		$wanted = in_array($offer, ['udp', 'tcp'], true) ? [$offer] : ['udp', 'tcp'];

		return array_values(array_filter(['udp', 'tcp'], function ($proto) use ($running, $wanted) {
			return in_array($proto, $running, true) && in_array($proto, $wanted, true);
		}));
	}

	/* [2|1|0, the offered protocols that are not running] */
	private function level($node, $now)
	{
		if ((int) $node->heartbeat <= $now - self::STALE) {
			return [0, []];
		}

		$offered = $this->offered($node);
		$up = json_decode((string) ($node->up_json ?? ''), true);

		// an agent older than 1.3.0 says nothing about its instances
		if ($offered === [] || !is_array($up) || $up === []) {
			return [2, []];
		}

		$down = array_values(array_filter($offered, function ($proto) use ($up) {
			return isset($up[$proto]) && empty($up[$proto]);
		}));

		if (count($down) === 0) {
			return [2, []];
		}

		return [count($down) >= count($offered) ? 0 : 1, $down];
	}

	// ----------------------------------------------------------- the words

	private function head($node)
	{
		$host = trim((string) $node->host_override) !== '' ? $node->host_override : $node->host;

		// left-to-right mark: an address inside Persian text reads backwards otherwise
		return "🖥 {$node->name}" . (trim((string) $host) !== '' ? " · \u{200E}{$host}\u{200E}" : '');
	}

	private function protos($list)
	{
		return implode(' و ', array_map('strtoupper', $list));
	}

	private function text($node, $was, $level, $down, $now, $for)
	{
		$head = $this->head($node);

		if ($level === 0) {
			$last = (int) $node->heartbeat;
			$silent = $last <= $now - self::STALE;

			return "🔴 سرور OpenVPN آفلاین شد\n{$head}\n"
				. ($silent
					? "⚠️ ارتباط عامل سرور با پنل قطع است\n🕒 آخرین ارتباط: \u{200E}" . date('H:i', $last) . "\u{200E} (" . $this->duration($now - $last) . ' پیش)'
					: '⚠️ عامل سرور زنده است ولی OpenVPN اجرا نیست' . ($down ? ' (' . $this->protos($down) . ')' : ''));
		}

		if ($level === 1) {
			return ($was === 0 ? "🟡 سرور OpenVPN برگشت، ولی بخشی از آن هنوز خاموش است\n" : "🟠 بخشی از سرور OpenVPN قطع شد\n")
				. "{$head}\n⚠️ خاموش: " . $this->protos($down)
				. ($was === 0 ? "\n⏱ مدت قطعی: " . $this->duration($for) : '');
		}

		return "🟢 سرور OpenVPN دوباره آنلاین شد\n{$head}\n⏱ مدت قطعی: " . $this->duration($for);
	}

	/* 3 دقیقه / 2 ساعت و 5 دقیقه / 1 روز و 3 ساعت */
	private function duration($seconds)
	{
		$minutes = max(1, (int) round($seconds / 60));

		if ($minutes < 60) {
			return $minutes . ' دقیقه';
		}

		$hours = intdiv($minutes, 60);
		$minutes %= 60;

		if ($hours < 24) {
			return $hours . ' ساعت' . ($minutes > 0 ? ' و ' . $minutes . ' دقیقه' : '');
		}

		$days = intdiv($hours, 24);
		$hours %= 24;

		return $days . ' روز' . ($hours > 0 ? ' و ' . $hours . ' ساعت' : '');
	}

	// ------------------------------------------------- bypass list domains

	/* the domains on the bypass list: the lines that are not an address or a network */
	private function bypassDomains()
	{
		$domains = [];

		foreach (preg_split('~\R~', (string) $this->setting('ovpn_bypass_custom')) as $line) {
			$line = strtolower(trim(preg_replace('~\s*#.*$~', '', $line)));

			if ($line !== '' && !preg_match('~^[0-9.]+(/[0-9]{1,2})?$~', $line)
				&& preg_match('~^(?=.{1,253}$)([a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z][a-z0-9-]{1,62}$~', $line)) {
				$domains[$line] = $line;
			}
		}

		return array_slice(array_values($domains), 0, self::RESOLVE_MAX);
	}

	private function refreshBypass()
	{
		$domains = $this->bypassDomains();
		$cache = json_decode((string) $this->setting('ovpn_bypass_cache'), true);
		$cache = is_array($cache) ? $cache : [];
		$hosts = isset($cache['hosts']) && is_array($cache['hosts']) ? $cache['hosts'] : [];
		$now = time();

		if ($domains === []) {
			if ($hosts !== []) {
				$this->putSetting('ovpn_bypass_cache', '');
			}
			return;
		}

		$fresh = (int) ($cache['at'] ?? 0) > $now - self::RESOLVE_EVERY;
		$missing = array_diff($domains, array_keys($hosts));

		if ($fresh && $missing === []) {
			return;
		}

		$deadline = microtime(true) + self::RESOLVE_BUDGET;
		$result = [];

		foreach ($domains as $domain) {
			// what is already known is kept when a lookup fails or time runs out
			$result[$domain] = isset($hosts[$domain]) ? $hosts[$domain] : [];

			if (microtime(true) > $deadline) {
				continue;
			}

			$ips = @gethostbynamel($domain);
			if (is_array($ips) && $ips !== []) {
				$result[$domain] = array_slice(array_values(array_unique($ips)), 0, 16);
			}
		}

		$this->putSetting('ovpn_bypass_cache', json_encode(['at' => $now, 'hosts' => $result]));
	}

	// ------------------------------------------------------------- plumbing

	protected function setting($name)
	{
		return DB::table('settings')->where('name', $name)->value('value');
	}

	protected function putSetting($name, $value)
	{
		if (DB::table('settings')->where('name', $name)->exists()) {
			DB::table('settings')->where('name', $name)->update(['value' => $value]);
		} else {
			DB::table('settings')->insert(['name' => $name, 'value' => $value]);
		}
	}

	protected function api($token, $method, array $params)
	{
		$ch = curl_init('https://api.telegram.org/bot' . $token . '/' . $method);
		curl_setopt_array($ch, [
			CURLOPT_POST           => true,
			CURLOPT_POSTFIELDS     => http_build_query($params),
			CURLOPT_RETURNTRANSFER => true,
			CURLOPT_CONNECTTIMEOUT => 5,
			CURLOPT_TIMEOUT        => 10,
		]);
		$body = curl_exec($ch);
		$error = curl_error($ch);
		curl_close($ch);

		if ($body === false) {
			return ['ok' => false, 'description' => 'curl: ' . $error];
		}

		$decoded = json_decode($body, true);

		return is_array($decoded) ? $decoded : ['ok' => false, 'description' => 'unreadable answer'];
	}
}
