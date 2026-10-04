<?php
namespace App\Jobs;

use Illuminate\Database\Capsule\Manager as DB;

/**
 * WireGuard housekeeping, run every minute from TaskCommand (bin/wg.php):
 * tells the admin on Telegram when a WireGuard server goes offline or comes
 * back, as the panel does for its own servers and OvpnJob does for OpenVPN.
 *
 * The agents report to app/Patch/Wg.php once a minute and each report moves
 * wg_node.heartbeat. A server is
 *
 *   1  up      reporting, so its agent reaches the panel
 *   0  down    no report for STALE seconds, or switched off
 *
 * A message goes out when that changes. The first time a server is seen its
 * state is only recorded, so installing this sends nothing for servers that
 * are already up. Servers whose agent never reported are left out and
 * forgotten. The state is written BEFORE the messages are sent: a failed send
 * loses one message, it never sends two.
 *
 * WireGuard has a single instance, so unlike OvpnJob there is no "partial"
 * level. The bypass domains are not looked up here either: OvpnJob refreshes
 * ovpn_bypass_cache every six hours and the agents read that same cache.
 *
 * The job stamps `wg_job_last` on every run, which the WireGuard settings card
 * shows - "never" there means the scheduler does not run this job.
 *
 * Settings rows (`settings.name`):
 *   wg_notify          0 switches the messages off (missing = on)
 *   wg_notify_state    {"<node id>": {"s": 1|0, "since": <unix time>}}, written
 *                      by this job
 *   wg_job_last        unix time of the last run, written by this job
 *   tgjoin_admin_chats admin chat ids, shared with the other patch jobs
 *                      (default: the panel's `telegramchatid`)
 *   telegramtoken      the panel's bot
 */
class WgJob
{
	/* same as WG_STALE in app/Patch/Wg.php: three missed reports */
	const STALE = 180;

	public function dispatch()
	{
		$this->putSetting('wg_job_last', time());

		if ((string) $this->setting('wg_notify') === '0') {
			return;
		}

		try {
			$nodes = DB::table('wg_node')->get();
		} catch (\Throwable $e) {
			return; // WireGuard not installed yet
		}

		$state = json_decode((string) $this->setting('wg_notify_state'), true);
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

			$level = (int) $node->heartbeat > $now - self::STALE ? 1 : 0;

			$before = isset($state[$id]) && is_array($state[$id]) ? $state[$id] : null;

			if ($before === null) {
				$next[$id] = ['s' => $level, 'since' => $now];
				continue;
			}

			// the first version of this state was {"up": 0|1}
			$was = isset($before['s']) ? (int) $before['s'] : (!empty($before['up']) ? 1 : 0);

			if ($was === $level) {
				$next[$id] = ['s' => $was, 'since' => (int) ($before['since'] ?? $now)];
				continue;
			}

			$next[$id] = ['s' => $level, 'since' => $now];
			$messages[] = $level === 0
				? $this->downText($node, $now)
				: $this->upText($node, $now);
		}

		// servers whose state is gone (deleted, or never reported) are forgotten
		$this->putSetting('wg_notify_state', json_encode((object) $next));

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

	// --------------------------------------------------------------- the words

	private function head($node)
	{
		$host = trim((string) $node->host_override) !== '' ? $node->host_override : $node->host;

		// left-to-right mark: an address inside Persian text reads backwards otherwise
		return "🖥 {$node->name}" . (trim((string) $host) !== '' ? " · \u{200E}{$host}\u{200E}" : '');
	}

	private function downText($node, $now)
	{
		$last = (int) $node->heartbeat;
		$silent = $last <= $now - self::STALE;

		return "🔴 سرور WireGuard آفلاین شد\n" . $this->head($node) . "\n"
			. ($silent
				? "⚠️ ارتباط عامل سرور با پنل قطع است\n🕒 آخرین ارتباط: \u{200E}" . date('H:i', $last) . "\u{200E} (" . $this->duration($now - $last) . ' پیش)'
				: '⚠️ عامل سرور زنده است ولی WireGuard اجرا نیست');
	}

	private function upText($node, $now)
	{
		return "🟢 سرور WireGuard برگشت\n" . $this->head($node) . "\n"
			. '📶 اتصال‌های فعال: ' . (int) $node->online . "\n"
			. '🕒 ' . date('H:i', $now) . ' · ' . $this->duration((int) $node->heartbeat > 0 ? $now - (int) $node->heartbeat : 0) . ' از قطعی';
	}

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

	// ---------------------------------------------------------------- plumbing

	protected function setting($name)
	{
		try {
			return DB::table('settings')->where('name', $name)->value('value');
		} catch (\Throwable $e) {
			return '';
		}
	}

	protected function putSetting($name, $value)
	{
		if ($this->setting($name) === null) {
			DB::table('settings')->insert(['name' => $name, 'value' => $value]);
		} else {
			DB::table('settings')->where('name', $name)->update(['value' => $value]);
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