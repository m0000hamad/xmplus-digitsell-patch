<?php
namespace App\Jobs;

use Illuminate\Database\Capsule\Manager as DB;

/**
 * Tells the admin on Telegram when an OpenVPN server goes offline and when it
 * comes back, as the panel does for its own servers.
 *
 * The OpenVPN agents report to app/Patch/Ovpn.php once a minute and each
 * report moves ovpn_node.heartbeat. This job runs every minute: a server whose
 * heartbeat is older than STALE is offline, any other is online. A message
 * goes out when that changes. The first time a server is seen, its state is
 * only recorded, so installing this sends nothing for servers already up.
 * Switched-off servers are left out and forgotten.
 *
 * The state is written BEFORE the message is sent: a failed send loses one
 * message, it never sends two.
 *
 * Settings rows (`settings.name`):
 *   ovpn_notify          0 switches the messages off (missing = on)
 *   ovpn_notify_state    {"<node id>": {"up": 1, "since": <unix time>}},
 *                        written by this job
 *   tgjoin_admin_chats   admin chat ids, shared with the other patch jobs
 *                        (default: the panel's `telegramchatid`)
 *   telegramtoken        the panel's bot
 */
class OvpnJob
{
	/* same as OVPN_STALE in app/Patch/Ovpn.php: three missed reports */
	const STALE = 180;

	public function dispatch()
	{
		if ((string) $this->setting('ovpn_notify') === '0') {
			return;
		}

		try {
			$nodes = DB::table('ovpn_node')->get(['id', 'name', 'enabled', 'heartbeat', 'online', 'host', 'host_override']);
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

			$up = (int) $node->heartbeat > $now - self::STALE;
			$before = isset($state[$id]) && is_array($state[$id]) ? $state[$id] : null;

			if ($before === null) {
				$next[$id] = ['up' => $up ? 1 : 0, 'since' => $now];
				continue;
			}

			if ((int) $before['up'] === ($up ? 1 : 0)) {
				$next[$id] = $before;
				continue;
			}

			$next[$id] = ['up' => $up ? 1 : 0, 'since' => $now];
			$messages[] = $up
				? $this->onlineText($node, $now - (int) ($before['since'] ?? $now))
				: $this->offlineText($node, $now);
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
			return;
		}

		foreach ($messages as $text) {
			foreach (preg_split('~[\s,]+~', $chats, -1, PREG_SPLIT_NO_EMPTY) as $chat) {
				$this->api($token, 'sendMessage', ['chat_id' => $chat, 'text' => $text]);
			}
		}
	}

	private function address($node)
	{
		$host = trim((string) $node->host_override) !== '' ? $node->host_override : $node->host;

		// left-to-right mark: an address inside Persian text reads backwards otherwise
		return trim((string) $host) === '' ? '' : "\u{200E}" . $host . "\u{200E}";
	}

	private function offlineText($node, $now)
	{
		$last = (int) $node->heartbeat;

		return "🔴 سرور OpenVPN آفلاین شد\n"
			. "🖥 {$node->name}" . ($this->address($node) !== '' ? ' · ' . $this->address($node) : '') . "\n"
			. "🕒 آخرین ارتباط: \u{200E}" . date('H:i', $last) . "\u{200E} (" . $this->duration($now - $last) . " پیش)";
	}

	private function onlineText($node, $downFor)
	{
		return "🟢 سرور OpenVPN دوباره آنلاین شد\n"
			. "🖥 {$node->name}" . ($this->address($node) !== '' ? ' · ' . $this->address($node) : '') . "\n"
			. "⏱ مدت قطعی: " . $this->duration($downFor);
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
		curl_close($ch);

		return $body === false ? null : json_decode($body, true);
	}
}
