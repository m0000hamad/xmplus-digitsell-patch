<?php
namespace App\Jobs;

use Illuminate\Database\Capsule\Manager as DB;

/**
 * One-time gift for joining the Telegram channel - and, in the same run, a
 * one-time gift for linking the bot (see bindGifts()).
 *
 * The channel is private with join requests, so there is no join event we can
 * hook (the bot's webhook belongs to the encoded panel). Instead this job asks
 * Telegram, through the panel's own bot, whether each linked account is a member
 * yet, and grants the gift the first time it is.
 *
 * New members only: the gift needs this job to have seen the account OUTSIDE
 * the channel at least once before it sees it inside. An account that is
 * already a member the first time it is looked at is written to `tgjoin_log`
 * as 'existing' with no gift, which closes it for good. Join requests wait for
 * an admin, so a newly linked account is always looked at (next minute,
 * never-checked accounts go first) before its request is approved.
 *
 * Exactly once, whatever the member does afterwards: `tgjoin_log` has a UNIQUE
 * key on the site account AND on the Telegram account. Leaving and rejoining,
 * relinking a different Telegram account, or linking the same Telegram account
 * to a second site account all hit an existing row, and the gift is never
 * given again. The row is written before the gift is applied, so two runs at
 * once cannot both grant.
 *
 * The gift is a draw, weighted towards the small end (see GB_TIERS/FREE_TIERS_MB):
 *   running subscription     -> 1 to 50 GB added to it
 *   no running subscription  -> a free plan of 100 MB to 1 GB, built on the
 *                               package in `tgjoin_free_package` (its server
 *                               group, IP and speed limits) for `tgjoin_free_days`
 *
 * Settings rows (`settings.name`):
 *   tgjoin_channel_id    numeric channel id (-100…). Empty = feature off.
 *                        The panel bot must be an admin of the channel.
 *   tgjoin_link          invite link shown to users
 *   tgjoin_free_package  package the free plan copies (default 18)
 *   tgjoin_free_days     length of the free plan in days (default 30)
 *   tgjoin_admin_chats   comma-separated Telegram chat ids told about every new
 *                        link and every gift (default: the panel's admin chat,
 *                        `telegramchatid`)
 */
class TgJoinJob
{
	/** how many accounts are asked about per run - the job runs every minute */
	const BATCH = 60;

	/** an account that is not a member yet is asked again after this long */
	const RECHECK = 120;

	/** [chance %, min GB, max GB] - the average gift is about 6.7 GB */
	const GB_TIERS = [[60, 1, 3], [25, 4, 10], [10, 11, 25], [5, 26, 50]];

	/** [chance %, min MB, max MB] for the free plan - the average is about 355 MB */
	const FREE_TIERS_MB = [[60, 100, 300], [25, 301, 600], [10, 601, 900], [5, 901, 1024]];

	/** [chance %, min GB, max GB] for linking the bot - the average is about 3.5 GB */
	const BIND_TIERS = [[50, 1, 2], [30, 3, 5], [15, 6, 8], [5, 9, 10]];

	/** accounts whose bot-link gift was already reported to the admins in this run */
	private $reported = [];

	public function dispatch()
	{
		$token = trim((string) $this->setting('telegramtoken'));
		if ($token === '' || $this->setting('telegram') != 1) {
			return 0;
		}

		$this->ensureTables();

		$granted = 0;

		if ($this->setting('tgbind_gift') == 1) {
			$granted += $this->bindGifts($token);
		}

		$channel = trim((string) $this->setting('tgjoin_channel_id'));
		if ($channel === '') {
			return $granted;
		}

		foreach ($this->candidates() as $user) {
			$status = $this->memberStatus($token, $channel, $user->telegram_id);
			if ($status === null) {
				// Telegram refused (bot not admin, bad id, rate limit): stop, retry next run
				break;
			}

			$member = in_array($status, ['member', 'administrator', 'creator', 'restricted'], true);

			// never looked at before = linked since the last run; the bot-link gift, if
			// any, has been reported already
			if ($user->check_tg === null && empty($this->reported[$user->id])) {
				$this->tellAdmins($token, $user->id, '🔗 اتصال به ربات', '🎁 جایزه‌ی اتصال: ندارد (' . $this->bindReason($user->id) . ')');
			}

			// a different Telegram account on the same site account starts over
			$seenOut = $user->check_tg !== null && (string) $user->check_tg === (string) $user->telegram_id
				&& (int) $user->seen_out === 1;

			DB::statement(
				'INSERT INTO tgjoin_check (userid, telegram_id, checked_at, seen_out) VALUES (?, ?, ?, ?)
				 ON DUPLICATE KEY UPDATE telegram_id = VALUES(telegram_id), checked_at = VALUES(checked_at), seen_out = VALUES(seen_out)',
				[$user->id, $user->telegram_id, time(), ($seenOut || !$member) ? 1 : 0]);

			if ($member) {
				if ($seenOut) {
					$gift = $this->grant($user);
					if ($gift) {
						$granted++;
						$this->notify($token, $user->telegram_id, $gift, $user->id);
						$this->tellAdmins($token, $user->id, '📢 عضویت در کانال', $gift['kind'] === 'free'
							? '🎁 جایزه: اشتراک رایگان ' . $this->size($gift['gb']) . " {$gift['days']} روزه"
							: "🎁 جایزه: {$gift['gb']} گیگ");
					}
				} else {
					// already inside the first time we looked: an existing member, no gift ever
					$this->close($user);
				}
			}

			usleep(50000);
		}

		return $granted;
	}

	private function setting($name)
	{
		return DB::table('settings')->where('name', $name)->value('value');
	}

	private function ensureTables()
	{
		DB::statement(
			'CREATE TABLE IF NOT EXISTS tgjoin_log (
				id INT(11) NOT NULL AUTO_INCREMENT,
				userid INT(11) NOT NULL,
				telegram_id BIGINT(20) NOT NULL,
				kind VARCHAR(10) NOT NULL,
				gb INT(11) NOT NULL DEFAULT 0,
				days INT(11) NOT NULL DEFAULT 0,
				granted_at BIGINT(20) NOT NULL,
				PRIMARY KEY (id),
				UNIQUE KEY userid (userid),
				UNIQUE KEY telegram_id (telegram_id)
			) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4');

		DB::statement(
			'CREATE TABLE IF NOT EXISTS tgbind_log (
				id INT(11) NOT NULL AUTO_INCREMENT,
				userid INT(11) NOT NULL,
				telegram_id BIGINT(20) NOT NULL,
				kind VARCHAR(10) NOT NULL,
				gb INT(11) NOT NULL DEFAULT 0,
				granted_at BIGINT(20) NOT NULL,
				PRIMARY KEY (id),
				UNIQUE KEY userid (userid),
				UNIQUE KEY telegram_id (telegram_id)
			) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4');

		$type = DB::select("SHOW COLUMNS FROM tgjoin_log LIKE 'gb'");
		if ($type && strtolower((string) $type[0]->Type) !== 'decimal(10,4)') {
			DB::statement('ALTER TABLE tgjoin_log MODIFY gb DECIMAL(10,4) NOT NULL DEFAULT 0');
		}

		foreach (['tgjoin_log', 'tgbind_log'] as $table) {
			$has = DB::select("SHOW COLUMNS FROM {$table} LIKE 'seen'");
			if (!$has) {
				DB::statement("ALTER TABLE {$table} ADD COLUMN seen TINYINT(1) NOT NULL DEFAULT 0");
			}
		}

		DB::statement(
			'CREATE TABLE IF NOT EXISTS tgjoin_check (
				userid INT(11) NOT NULL,
				telegram_id BIGINT(20) NOT NULL DEFAULT 0,
				checked_at BIGINT(20) NOT NULL,
				seen_out TINYINT(1) NOT NULL DEFAULT 0,
				PRIMARY KEY (userid)
			) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4');
	}

	/*
	 * One-time gift for linking the bot (`tgbind_gift` = 1 switches it on).
	 *
	 * Only links made after the switch count: the first run writes every account
	 * already linked into `tgbind_log` as 'existing'. Only paying customers with
	 * a running plan get it - at least one paid order, so a free trial account
	 * plus a fresh Telegram account cannot farm it. Someone who links while
	 * expired stays pending and gets it once they buy. Exactly once per site
	 * account and per Telegram account, like the channel gift.
	 */
	private function bindGifts($token)
	{
		if ($this->setting('tgbind_seeded') != 1) {
			DB::statement(
				"INSERT IGNORE INTO tgbind_log (userid, telegram_id, kind, gb, granted_at)
				 SELECT id, telegram_id, 'existing', 0, ? FROM user WHERE telegram_id > 0",
				[time()]);
			DB::table('settings')->where('name', 'tgbind_seeded')->delete();
			DB::table('settings')->insert(['name' => 'tgbind_seeded', 'value' => '1']);
			echo date('Y-m-d H:i:s') . ' bot-link gift: accounts already linked marked as existing' . PHP_EOL;
			return 0;
		}

		$users = DB::table('user')
			->where('telegram_id', '>', 0)
			->where('expire_in', '>', date('Y-m-d H:i:s'))
			->whereNotExists(function ($q) {
				$q->select(DB::raw(1))->from('tgbind_log')
					->whereRaw('tgbind_log.userid = user.id OR tgbind_log.telegram_id = user.telegram_id');
			})
			->whereExists(function ($q) {
				$q->select(DB::raw(1))->from('orders')
					->whereRaw('orders.userid = user.id AND orders.status = 1');
			})
			->limit(self::BATCH)
			->get(['id', 'telegram_id']);

		$granted = 0;
		foreach ($users as $user) {
			$gb = $this->draw(self::BIND_TIERS);
			try {
				DB::table('tgbind_log')->insert([
					'userid'      => $user->id,
					'telegram_id' => $user->telegram_id,
					'kind'        => 'gb',
					'gb'          => $gb,
					'granted_at'  => time(),
				]);
			} catch (\Throwable $e) {
				continue;
			}

			DB::update('UPDATE user SET transfer_enable = transfer_enable + ? WHERE id = ?',
				[$gb * 1073741824, $user->id]);
			echo date('Y-m-d H:i:s') . sprintf(' user %d (tg %s): bot-link gift +%d GB', $user->id, $user->telegram_id, $gb) . PHP_EOL;

			$text = "🎉 تلگرامت به حساب دیجیتسل وصل شد و {$gb} گیگ جایزه بردی!\n\n"
				. $this->balanceLine($user->id);

			// point at the channel gift when it is still open to this account
			$link = trim((string) $this->setting('tgjoin_link'));
			$channelOpen = trim((string) $this->setting('tgjoin_channel_id')) !== '' && $link !== ''
				&& !DB::table('tgjoin_log')->where('userid', $user->id)
					->orWhere('telegram_id', $user->telegram_id)->exists();
			if ($channelOpen) {
				$text .= "\n\n📢 حالا اگر عضو کانال «دوستان دیجیتسل» هم بشی، ممکن است تا ۵۰ گیگ دیگر هم ببری:\n{$link}";
			}

			$this->api($token, 'sendMessage', ['chat_id' => $user->telegram_id, 'text' => $text]);
			$this->tellAdmins($token, $user->id, '🔗 اتصال به ربات', "🎁 جایزه: {$gb} گیگ");
			$this->reported[$user->id] = true;
			$granted++;
		}

		return $granted;
	}

	/*
	 * Linked accounts that have never been gifted or closed, under either id,
	 * and were not asked about in the last RECHECK seconds. Never-asked
	 * accounts go first, so a fresh link is looked at within a minute.
	 */
	private function candidates()
	{
		return DB::table('user')
			->leftJoin('tgjoin_check', 'tgjoin_check.userid', '=', 'user.id')
			->where('user.telegram_id', '>', 0)
			->whereNotExists(function ($q) {
				$q->select(DB::raw(1))->from('tgjoin_log')
					->whereRaw('tgjoin_log.userid = user.id OR tgjoin_log.telegram_id = user.telegram_id');
			})
			->where(function ($q) {
				$q->whereNull('tgjoin_check.checked_at')
					->orWhere('tgjoin_check.checked_at', '<', time() - self::RECHECK);
			})
			->orderByRaw('tgjoin_check.checked_at IS NOT NULL, tgjoin_check.checked_at')
			->limit(self::BATCH)
			->get(['user.id', 'user.telegram_id',
				'tgjoin_check.telegram_id AS check_tg', 'tgjoin_check.seen_out']);
	}

	/*
	 * The member's status in the channel, 'left' when Telegram does not know the
	 * user there, or null when the call itself failed and nothing can be concluded.
	 */
	private function memberStatus($token, $channel, $telegramId)
	{
		$reply = $this->api($token, 'getChatMember', ['chat_id' => $channel, 'user_id' => $telegramId]);
		if (!is_array($reply)) {
			return null;
		}
		if (!empty($reply['ok'])) {
			return isset($reply['result']['status']) ? $reply['result']['status'] : 'left';
		}

		// a deleted or never-seen account is simply not a member; anything else is our problem
		$error = isset($reply['description']) ? $reply['description'] : '';
		if (stripos($error, 'user not found') !== false || stripos($error, 'PARTICIPANT_ID_INVALID') !== false) {
			return 'left';
		}

		echo date('Y-m-d H:i:s') . ' getChatMember failed: ' . $error . PHP_EOL;
		return null;
	}

	/*
	 * Claims the one row this account and this Telegram id will ever get.
	 * False when either already has one.
	 */
	private function claim($user, $kind, $gb, $days)
	{
		try {
			DB::table('tgjoin_log')->insert([
				'userid'      => $user->id,
				'telegram_id' => $user->telegram_id,
				'kind'        => $kind,
				'gb'          => $gb,
				'days'        => $days,
				'granted_at'  => time(),
			]);
			return true;
		} catch (\Throwable $e) {
			return false;
		}
	}

	private function close($user)
	{
		if ($this->claim($user, 'existing', 0, 0)) {
			echo date('Y-m-d H:i:s') . sprintf(' user %d (tg %s): existing member, closed without gift', $user->id, $user->telegram_id) . PHP_EOL;
		}
	}

	private function draw(array $tiers)
	{
		$roll = random_int(1, 100);
		foreach ($tiers as $tier) {
			$roll -= $tier[0];
			if ($roll <= 0) {
				return random_int($tier[1], $tier[2]);
			}
		}
		$last = end($tiers);
		return random_int($last[1], $last[2]);
	}

	/*
	 * Draws and applies the gift. The subscription state is read again here, not
	 * taken from the candidate query, so a purchase made in between is respected.
	 * Returns ['kind' => gb|free, 'gb' => n, 'days' => n] or null.
	 */
	private function grant($user)
	{
		$active = DB::table('user')->where('id', $user->id)
			->where('expire_in', '>', date('Y-m-d H:i:s'))->exists();

		if ($active) {
			$gb = $this->draw(self::GB_TIERS);
			if (!$this->claim($user, 'gb', $gb, 0)) {
				return null;
			}
			DB::update('UPDATE user SET transfer_enable = transfer_enable + ? WHERE id = ?',
				[$gb * 1073741824, $user->id]);

			echo date('Y-m-d H:i:s') . sprintf(' user %d (tg %s): +%d GB', $user->id, $user->telegram_id, $gb) . PHP_EOL;
			return ['kind' => 'gb', 'gb' => $gb, 'days' => 0];
		}

		$packageId = (int) $this->setting('tgjoin_free_package') ?: 18;
		$days = (int) $this->setting('tgjoin_free_days') ?: 30;
		$package = DB::table('package')->where('id', $packageId)->first();
		if (!$package) {
			echo date('Y-m-d H:i:s') . " free-plan package {$packageId} is missing" . PHP_EOL;
			return null;
		}

		$mb = $this->draw(self::FREE_TIERS_MB);
		$gb = round($mb / 1024, 4);
		if (!$this->claim($user, 'free', $gb, $days)) {
			return null;
		}

		// a fresh plan: the same fields the panel resets when a subscription starts.
		// The expiry is computed in PHP: MySQL's NOW() runs on UTC here while
		// expire_in is stored in the panel's local time, 3.5 hours apart.
		DB::update(
			'UPDATE user SET packageid = ?, plan = ?, server_group = ?, iplimit = ?, speedlimit = ?,
				transfer_enable = ?, u = 0, d = 0, used = 0, data_expire_cron = 0, data_used_cron = 0,
				expire_in = ?
			 WHERE id = ?',
			[$package->id, 'month', $package->server_group, $package->iplimit, $package->speedlimit,
				$mb * 1048576, date('Y-m-d H:i:s', time() + $days * 86400), $user->id]);

		echo date('Y-m-d H:i:s') . sprintf(' user %d (tg %s): free plan %d MB / %d days (package %d)',
			$user->id, $user->telegram_id, $mb, $days, $package->id) . PHP_EOL;
		return ['kind' => 'free', 'gb' => $gb, 'days' => $days];
	}

	private function notify($token, $telegramId, array $gift, $userId)
	{
		if ($gift['kind'] === 'free') {
			$text = "🎉 ممنون که عضو کانال شدی!\n"
				. "🎁 جایزه‌ات یک اشتراک رایگان " . $this->size($gift['gb']) . " {$gift['days']} روزه است که همین الان فعال شد.\n\n";
		} else {
			$text = "🎉 ممنون که عضو کانال شدی و {$gift['gb']} گیگ جایزه بردی!\n\n";
		}

		$this->api($token, 'sendMessage', ['chat_id' => $telegramId, 'text' => $text . $this->balanceLine($userId)]);
	}

	/*
	 * Tells the admin chat(s) about a new link or a gift: who, what for, what
	 * they got and where their plan stands now. Plain text, no parse mode, so a
	 * username can never break the message.
	 */
	private function tellAdmins($token, $userId, $event, $giftLine)
	{
		$chats = trim((string) $this->setting('tgjoin_admin_chats'));
		if ($chats === '') {
			$chats = trim((string) $this->setting('telegramchatid'));
		}
		if ($chats === '') {
			return;
		}

		$u = DB::table('user')->where('id', $userId)->first(['id', 'username', 'email', 'telegram_name']);
		if (!$u) {
			return;
		}

		$who = "👤 {$u->username} (#{$u->id})";
		if ((string) $u->telegram_name !== '') {
			$who .= " · @{$u->telegram_name}";
		}

		$text = "{$event}\n{$who}\n{$giftLine}\n" . $this->balanceLine($userId, true);

		foreach (preg_split('~[\s,]+~', $chats, -1, PREG_SPLIT_NO_EMPTY) as $chat) {
			$this->api($token, 'sendMessage', ['chat_id' => $chat, 'text' => $text]);
		}
	}

	/*
	 * Why a newly linked account got no bot-link gift, for the admin note.
	 */
	private function bindReason($userId)
	{
		if ($this->setting('tgbind_gift') != 1) {
			return 'جایزه‌ی اتصال خاموش است';
		}
		if (DB::table('tgbind_log')->where('userid', $userId)->exists()) {
			return 'قبلاً جایزه گرفته یا از قبل وصل بوده';
		}
		if (!DB::table('user')->where('id', $userId)->where('expire_in', '>', date('Y-m-d H:i:s'))->exists()) {
			return 'اشتراک فعال ندارد؛ بعد از خرید می‌گیرد';
		}
		if (!DB::table('orders')->where('userid', $userId)->where('status', 1)->exists()) {
			return 'هنوز خریدی نکرده';
		}
		return 'همین آیدی تلگرام قبلاً جایزه گرفته';
	}

	/*
	 * "350 مگ" below a gigabyte, "2 گیگ" / "1.5 گیگ" from there on.
	 */
	private function size($gb)
	{
		$gb = (float) $gb;
		if ($gb < 1) {
			return (int) round($gb * 1024) . ' مگ';
		}
		return rtrim(rtrim(number_format($gb, 2, '.', ''), '0'), '.') . ' گیگ';
	}

	/*
	 * "You now have N GB in total, usable until <date> (D days)" - read after
	 * the gift was applied, so it is the figure the customer will see on the site.
	 */
	private function balanceLine($userId, $forAdmin = false)
	{
		$u = DB::table('user')->where('id', $userId)->first(['transfer_enable', 'u', 'd', 'expire_in']);
		if (!$u) {
			return '';
		}

		$left = $this->size(max(0, ((float) $u->transfer_enable - (float) $u->u - (float) $u->d) / 1073741824));
		$until = strtotime((string) $u->expire_in);
		$days = max(0, (int) floor(($until - time()) / 86400));

		if ($forAdmin) {
			return $until > time()
				? "📦 حجم باقی‌مانده: {$left} · تا " . "\u{200E}" . date('Y-m-d', $until) . "\u{200E}" . " ({$days} روز)"
				: '📦 اشتراک فعال ندارد';
		}

		return "📦 حالا مجموعاً {$left} حجم داری که تا پایان اشتراکت، "
			// LRM marks keep the date reading left to right inside the Persian sentence
			. "\u{200E}" . date('Y-m-d', $until) . "\u{200E}" . " ({$days} روز دیگر)، قابل استفاده است.";
	}

	private function api($token, $method, array $params)
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
