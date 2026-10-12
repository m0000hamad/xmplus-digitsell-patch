<?php
namespace App\Jobs;

use App\Http\Models\Queue;
use Illuminate\Database\Capsule\Manager as DB;

/**
 * Broadcasts the two announcement campaigns (see app/Patch/Announce.php).
 *
 * Every minute, from bin/announce.php:
 *
 *  1. c1 is the notice: the title and body copied in when the notice form was
 *     saved. c2 is the dashboard invite nudge. A campaign that was stamped
 *     (its switch set and "send" pressed, or a notice saved with a channel on)
 *     is queued; the stamp is what makes each send happen once.
 *  2. Telegram and e-mail go to every customer, BROADCAST per run, each one
 *     claimed in `announce_broadcast` first so nobody gets it twice. Customers
 *     who switched notices off in their settings are skipped.
 *  3. "Group" is a single post in the chat set as announce_group_id, once per
 *     stamp.
 *
 * Times and the site URL work as in PromoJob: MySQL's NOW() runs on UTC here,
 * and appName holds the panel's hostname.
 */
class AnnounceJob
{
	/** customers told per run - Telegram allows ~30/s */
	const BATCH = 150;

	private $token = '';

	public function dispatch()
	{
		$this->ensureTables();

		$this->token = $this->setting('telegram') == 1 ? trim((string) $this->setting('telegramtoken')) : '';

		$map = $this->map();
		$sent = 0;

		foreach (['c1', 'c2'] as $key) {
			if (isset($map[$key]) && is_array($map[$key])) {
				$sent += $this->campaign($key, $map[$key]);
			}
		}

		return $sent;
	}

	private function setting($name, $fallback = null)
	{
		$row = DB::table('settings')->where('name', $name)->first();

		return $row === null ? $fallback : $row->value;
	}

	/* read fresh every time: the admin may save the card while this runs */
	private function map()
	{
		$decoded = json_decode((string) $this->setting('announce_campaigns', ''), true);

		return is_array($decoded) ? $decoded : [];
	}

	/* changes a few fields of one campaign, re-reading the row so an admin save is not lost */
	private function patchEntry($key, array $fields)
	{
		$map = $this->map();

		if (!isset($map[$key]) || !is_array($map[$key])) {
			return;
		}

		$map[$key] = array_merge($map[$key], $fields);

		DB::table('settings')->where('name', 'announce_campaigns')
			->update(['value' => json_encode($map, JSON_UNESCAPED_UNICODE)]);
	}

	private function ensureTables()
	{
		DB::statement(
			'CREATE TABLE IF NOT EXISTS announce_broadcast (
				id BIGINT(20) NOT NULL AUTO_INCREMENT,
				campaign VARCHAR(32) NOT NULL,
				userid INT(11) NOT NULL,
				sent_at BIGINT(20) NOT NULL,
				PRIMARY KEY (id),
				UNIQUE KEY campaign_user (campaign, userid),
				KEY campaign (campaign)
			) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4');
	}

	private function sourceUrl()
	{
		$override = trim((string) $this->setting('promo_site_url'));

		if ($override !== '' && preg_match('~^https?://~i', $override)) {
			return rtrim($override, '/');
		}

		$site = trim((string) $this->setting('appName', ''));

		if ($site !== '' && preg_match('~^https?://~i', $site)) {
			return rtrim($site, '/');
		}

		if ($site !== '' && strpos($site, '.') !== false && !preg_match('/\s/', $site)) {
			return 'https://' . rtrim($site, '/');
		}

		$base = trim((string) $this->setting('baseUrl', ''));

		if ($base !== '' && preg_match('~^https?://~i', $base)) {
			return rtrim($base, '/');
		}

		return 'https://p.digitsell-shop.ir';
	}

	/*
	 * The chat the group channel posts in. announce_group_id is ours and wins
	 * once it exists, so an admin who empties it really turns the group off;
	 * before that it falls back to the channel / admin chat the panel already
	 * has, so the switch works out of the box.
	 */
	private function groupId()
	{
		$own = $this->setting('announce_group_id');

		if ($own !== null && $own !== false) {
			return trim((string) $own);
		}

		foreach (['promo_channel_id', 'telegramgroup', 'TGGroupID', 'telegramchatid'] as $name) {
			$value = trim((string) $this->setting($name));

			if ($value !== '') {
				return $value;
			}
		}

		return '';
	}

	// ------------------------------------------------------------ one campaign

	private function campaign($key, array $entry)
	{
		$stamp = (int) ($entry['stamp'] ?? 0);

		if ($stamp <= (int) ($entry['sent_stamp'] ?? 0)) {
			return 0; // nothing queued
		}

		$tg = !empty($entry['tg']);
		$mail = !empty($entry['mail']);
		$group = !empty($entry['grp']);

		if (!$tg && !$mail && !$group) {
			$this->patchEntry($key, ['sent_stamp' => $stamp, 'sent_at' => time()]);
			return 0;
		}

		$text = $this->text($key, $entry);
		$promo = $key . ':' . $stamp;

		if (trim($text) === '') {
			// nothing to say (e.g. a notice saved before its text was copied in)
			$this->patchEntry($key, ['sent_stamp' => $stamp, 'sent_at' => time()]);
			echo date('Y-m-d H:i:s') . " campaign {$key} #{$stamp} skipped: empty message" . PHP_EOL;
			return 0;
		}

		// the group post happens once per stamp, whichever run gets there first
		if ($group && (int) ($entry['grp_stamp'] ?? 0) !== $stamp) {
			$this->group($text);
			$this->patchEntry($key, ['grp_stamp' => $stamp]);
		}

		$users = DB::table('user')
			->leftJoin('announce_broadcast', function ($join) use ($promo) {
				$join->on('announce_broadcast.userid', '=', 'user.id')
					->where('announce_broadcast.campaign', '=', $promo);
			})
			->where('user.role', 0)
			->whereNull('announce_broadcast.id')
			->select('user.id', 'user.username', 'user.email', 'user.telegram_id', 'user.notification')
			->orderBy('user.id', 'asc')
			->limit(self::BATCH)
			->get();

		if (count($users) === 0) {
			$this->patchEntry($key, [
				'sent_stamp' => $stamp,
				'sent_at'    => time(),
				'sent_users' => $this->claimed($promo),
			]);
			echo date('Y-m-d H:i:s') . " campaign {$key} #{$stamp} done" . PHP_EOL;
			return 0;
		}

		$sent = 0;

		foreach ($users as $user) {
			try {
				DB::table('announce_broadcast')->insert(['campaign' => $promo, 'userid' => $user->id, 'sent_at' => time()]);
			} catch (\Throwable $error) {
				continue;
			}

			// the "notices" switch on the user's settings page; unset means on
			$prefs = json_decode((string) $user->notification, true);
			if (is_array($prefs) && isset($prefs['sendnotices']) && (int) $prefs['sendnotices'] === 0) {
				continue;
			}

			if ($mail) {
				$this->mail($user, $this->subject($key, $entry, $text), $text);
			}

			if ($tg && $this->token !== '' && !empty($user->telegram_id)) {
				$this->api('sendMessage', ['chat_id' => $user->telegram_id, 'text' => $text]);
				usleep(40000);
			}

			$sent++;
		}

		echo date('Y-m-d H:i:s') . " campaign {$key} #{$stamp}: told {$sent} customer(s)" . PHP_EOL;

		return $sent;
	}

	private function claimed($promo)
	{
		return (int) DB::table('announce_broadcast')->where('campaign', $promo)->count();
	}

	private function subject($key, array $entry, $text)
	{
		if ($key === 'c1') {
			$title = trim((string) ($entry['title'] ?? ''));
			return $title !== '' ? $title : 'اطلاعیه‌ی جدید';
		}

		return 'دعوت از دوستان';
	}

	/* the message each channel gets */
	private function text($key, array $entry)
	{
		if ($key === 'c2') {
			$text = trim((string) ($entry['text'] ?? ''));

			if ($text === '') {
				$text = "🎁 دوستانت را دعوت کن، ارزان‌تر تمدید کن!\n"
					. "از هر خرید دوستانت " . trim((string) $this->setting('commission', ''))
					. " درصد پورسانت می‌گیری و اشتراک بعدیت را با تخفیف می‌خری.";
			}

			$text = str_replace('%percent%', trim((string) $this->setting('commission', '')), $text);
			$site = $this->sourceUrl();

			if (strpos($text, $site) === false) {
				$text .= "\n\n👉 " . $site;
			}

			return $text;
		}

		$title = trim((string) ($entry['title'] ?? ''));
		$body = trim(strip_tags((string) ($entry['body'] ?? '')));
		$body = trim((string) preg_replace('~[ \t]*\n[ \t]*~', "\n", $body));

		return trim($title . ($title !== '' && $body !== '' ? "\n\n" : '') . $body);
	}

	private function group($text)
	{
		$chat = $this->groupId();

		if ($chat === '' || $this->token === '') {
			echo date('Y-m-d H:i:s') . " group channel skipped: no announce_group_id or bot token" . PHP_EOL;
			return;
		}

		$reply = $this->api('sendMessage', ['chat_id' => $chat, 'text' => $text]);

		echo date('Y-m-d H:i:s') . " group post to {$chat}: "
			. (is_array($reply) && !empty($reply['ok']) ? 'sent' : 'refused '
				. (is_array($reply) ? (string) ($reply['description'] ?? '?') : 'no answer')) . PHP_EOL;
	}

	// ------------------------------------------------------------ messages

	private function mail($user, $subject, $text)
	{
		if ($this->setting('maildriver') != 1 || !filter_var((string) $user->email, FILTER_VALIDATE_EMAIL)) {
			return;
		}

		$template = trim((string) $this->setting('promo_mail_template'));

		try {
			Queue::insert([
				'to_email'   => $user->email,
				'subject'    => $this->setting('appName') . ' - ' . $subject,
				'telegramid' => 0,
				'template'   => $template !== '' ? $template : 'promo.tpl',
				'array'      => json_encode([
					'username' => $user->username,
					'title'    => $subject,
					'lines'    => array_values(array_filter(explode("\n", str_replace("\u{200E}", '', $text)), 'strlen')),
				], JSON_UNESCAPED_UNICODE),
				'time'       => time(),
			]);
		} catch (\Throwable $error) {
			echo date('Y-m-d H:i:s') . ' mail not queued for user ' . $user->id . ': ' . $error->getMessage() . PHP_EOL;
		}
	}

	protected function api($method, array $params)
	{
		$ch = curl_init('https://api.telegram.org/bot' . $this->token . '/' . $method);
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
