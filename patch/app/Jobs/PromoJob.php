<?php
namespace App\Jobs;

use App\Http\Models\Package;
use App\Http\Models\Queue;
use Illuminate\Database\Capsule\Manager as DB;

/**
 * Runs promotions on subscription plans (see Package::PROMO_SETTING).
 *
 * Every minute, from bin/promos.php:
 *
 *  1. Paid orders on a promoted plan are logged once each in `promo_log`
 *     (UNIQUE orderid, claimed before anything else happens). A prize plan
 *     draws its prize at that point and applies it. Orders are only picked up
 *     PRIZE_DELAY seconds after payment: the encoded pipeline that runs on
 *     payment sets the plan's traffic and expiry, and a prize added before it
 *     finished would be overwritten.
 *  2. A promotion whose end date passed or whose sales limit was reached is
 *     closed and, for a discount, the list prices are written back into
 *     price_option.
 *  3. The customer (Telegram and e-mail) and the admin chats hear about each
 *     promoted purchase and prize; the admin chats also hear about a
 *     promotion starting and ending.
 *  5. A promotion saved with "channel" is posted in the Telegram channel set
 *     in `promo_channel_id`, like the plan card: tags, list and promo price
 *     per cycle, prize, occasion, deadline, stock, and a buy button. The post
 *     is edited when the promotion changes (or its stock drops) and marked as
 *     ended when it closes.
 *  4. A promotion saved with "announce" is sent to every customer, BROADCAST
 *     per run, each one claimed in `promo_broadcast` first so nobody gets it
 *     twice. Customers who switched notices off in their settings are skipped.
 *
 * Times are compared in PHP: MySQL's NOW() runs on UTC on this server while
 * expire_in is stored in local time (+03:30), and pay_date is an epoch.
 */
class PromoJob
{
	/** seconds to wait after payment before a prize is applied */
	const PRIZE_DELAY = 60;

	/** orders handled per run */
	const BATCH = 100;

	/** customers told about a new promotion per run - Telegram allows ~30/s */
	const BROADCAST = 150;

	private $token = '';

	public function dispatch()
	{
		$this->ensureTables();

		$this->token = $this->setting('telegram') == 1 ? trim((string) $this->setting('telegramtoken')) : '';

		$logged = 0;

		foreach ($this->map() as $key => $entry) {
			if (!is_array($entry) || empty($entry['started_at'])) {
				continue;
			}

			$logged += $this->logOrders((int) $key, $entry);
		}

		foreach ($this->map() as $key => $entry) {
			if (!is_array($entry)) {
				continue;
			}

			$this->closeIfDone((int) $key, $entry);
		}

		foreach ($this->map() as $key => $entry) {
			if (!is_array($entry)) {
				continue;
			}

			$this->announce((int) $key, $entry);
		}

		foreach ($this->map() as $key => $entry) {
			if (is_array($entry) && !empty($entry['announce']) && empty($entry['broadcast_done'])) {
				$this->broadcast((int) $key, $entry);
			}
		}

		foreach ($this->map() as $key => $entry) {
			if (is_array($entry) && (!empty($entry['channel']) || !empty($entry['channel_msg']))) {
				$this->channel((int) $key, $entry);
			}
		}

		return $logged;
	}

	private function setting($name)
	{
		return DB::table('settings')->where('name', $name)->value('value');
	}

	/* read fresh every time: the admin may save the plan form while this runs */
	private function map()
	{
		$decoded = json_decode((string) $this->setting(Package::PROMO_SETTING), true);

		return is_array($decoded) ? $decoded : [];
	}

	/* changes a few fields of one entry, re-reading the row so an admin save is not lost */
	private function patchEntry($packageId, array $fields)
	{
		$map = $this->map();
		$key = (string) $packageId;

		if (!isset($map[$key]) || !is_array($map[$key])) {
			return;
		}

		$map[$key] = array_merge($map[$key], $fields);

		DB::table('settings')->where('name', Package::PROMO_SETTING)
			->update(['value' => json_encode($map, JSON_UNESCAPED_UNICODE)]);
	}

	private function ensureTables()
	{
		DB::statement(
			'CREATE TABLE IF NOT EXISTS promo_log (
				id BIGINT(20) NOT NULL AUTO_INCREMENT,
				orderid BIGINT(20) NOT NULL,
				userid INT(11) NOT NULL,
				packageid BIGINT(20) NOT NULL,
				kind VARCHAR(16) NOT NULL DEFAULT \'\',
				percent INT(11) NOT NULL DEFAULT 0,
				prize_kind VARCHAR(8) NULL,
				prize_amount INT(11) NOT NULL DEFAULT 0,
				applied TINYINT(1) NOT NULL DEFAULT 0,
				expire_before DATETIME NULL,
				expire_after DATETIME NULL,
				created_at BIGINT(20) NOT NULL,
				PRIMARY KEY (id),
				UNIQUE KEY orderid (orderid),
				KEY userid (userid),
				KEY packageid (packageid)
			) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4');

		// the dashboard's prize popup (User::newGifts); rows from before it existed
		// count as seen, so nobody gets a popup for an old prize
		if (count(DB::select("SHOW COLUMNS FROM promo_log LIKE 'seen'")) === 0) {
			DB::statement('ALTER TABLE promo_log ADD COLUMN seen TINYINT(1) NOT NULL DEFAULT 1');
		}

		DB::statement(
			'CREATE TABLE IF NOT EXISTS promo_broadcast (
				id BIGINT(20) NOT NULL AUTO_INCREMENT,
				promo VARCHAR(32) NOT NULL,
				userid INT(11) NOT NULL,
				sent_at BIGINT(20) NOT NULL,
				PRIMARY KEY (id),
				UNIQUE KEY promo_user (promo, userid)
			) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4');
	}

	// ------------------------------------------------------------ purchases

	private function logOrders($packageId, array $entry)
	{
		$until = !empty($entry['closed_at']) ? (int) $entry['closed_at'] : 0;

		// a closed promotion stops accepting orders at its close; one closed long
		// ago has nothing left to pick up
		if ($until > 0 && $until < time() - 7 * 86400) {
			return 0;
		}

		$query = DB::table('orders')
			->leftJoin('promo_log', 'promo_log.orderid', '=', 'orders.id')
			->where('orders.packageid', $packageId)
			->where('orders.status', 1)
			->whereNotNull('orders.pay_date')
			->where('orders.pay_date', '>=', (int) $entry['started_at'])
			->where('orders.pay_date', '<=', time() - self::PRIZE_DELAY)
			->whereNull('promo_log.id');

		if ($until > 0) {
			$query->where('orders.pay_date', '<=', $until);
		}

		$orders = $query
			->select('orders.id', 'orders.userid', 'orders.packageid', 'orders.pay_date', 'orders.total_amount')
			->orderBy('orders.id', 'asc')
			->limit(self::BATCH)
			->get();

		$logged = 0;

		foreach ($orders as $order) {
			if ($this->logOrder($order, $entry)) {
				$logged++;
			}
		}

		return $logged;
	}

	private function logOrder($order, array $entry)
	{
		$user = DB::table('user')->where('id', $order->userid)->first();

		if (!$user) {
			return false;
		}

		$prize = !empty($entry['prize']['on']) ? $this->draw($entry['prize']) : null;

		// claim first: a duplicate key means another run already has this order
		try {
			DB::table('promo_log')->insert([
				'orderid'       => $order->id,
				'userid'        => $order->userid,
				'packageid'     => $order->packageid,
				'kind'          => (string) ($entry['kind'] ?? 'none'),
				'percent'       => (int) ($entry['percent'] ?? 0),
				'prize_kind'    => $prize ? $prize['kind'] : null,
				'prize_amount'  => $prize ? $prize['amount'] : 0,
				'applied'       => 0,
				'expire_before' => $user->expire_in,
				'expire_after'  => null,
				'created_at'    => time(),
				// a drawn prize waits for its popup on the dashboard
				'seen'          => $prize ? 0 : 1,
			]);
		} catch (\Throwable $error) {
			return false;
		}

		if ($prize) {
			$this->applyPrize($user, $prize);
		}

		$after = DB::table('user')->where('id', $user->id)->value('expire_in');

		DB::table('promo_log')->where('orderid', $order->id)->update([
			'applied'      => $prize ? 1 : 0,
			'expire_after' => $after,
		]);

		echo date('Y-m-d H:i:s') . sprintf(' order %d: user %d, package %d, %s%s',
			$order->id, $order->userid, $order->packageid, $entry['kind'] ?? 'none',
			$prize ? " + prize {$prize['amount']} {$prize['kind']}" : '') . PHP_EOL;

		$this->tellCustomer($user, $order, $entry, $prize);
		$this->tellAdmins($this->adminPurchase($user, $order, $entry, $prize));

		return true;
	}

	/* a whole number in the admin's range; "either" tosses a coin first */
	private function draw(array $prize)
	{
		$mode = $prize['mode'] ?? 'either';

		if ($mode === 'either') {
			$mode = random_int(0, 1) === 0 ? 'gb' : 'days';
		}

		if ($mode === 'gb') {
			$min = max(1, (int) ($prize['gb_min'] ?? 1));
			$max = max($min, (int) ($prize['gb_max'] ?? $min));

			return ['kind' => 'gb', 'amount' => random_int($min, $max)];
		}

		$min = max(1, (int) ($prize['days_min'] ?? 1));
		$max = max($min, (int) ($prize['days_max'] ?? $min));

		return ['kind' => 'days', 'amount' => random_int($min, $max)];
	}

	private function applyPrize($user, array $prize)
	{
		if ($prize['kind'] === 'gb') {
			DB::update('UPDATE user SET transfer_enable = transfer_enable + ? WHERE id = ?',
				[(int) $prize['amount'] * 1073741824, $user->id]);
			return;
		}

		// from the later of the plan's end and now, worked out in PHP (see above)
		$current = DB::table('user')->where('id', $user->id)->value('expire_in');
		$base = max((int) strtotime((string) $current), time());

		DB::table('user')->where('id', $user->id)->update([
			'expire_in' => date('Y-m-d H:i:s', $base + (int) $prize['amount'] * 86400),
		]);
	}

	// ------------------------------------------------------------ open / close

	private function sold($packageId, array $entry)
	{
		$query = DB::table('orders')
			->where('packageid', $packageId)
			->where('status', 1)
			->where('pay_date', '>=', (int) ($entry['started_at'] ?? 0));

		if (!empty($entry['closed_at'])) {
			$query->where('pay_date', '<=', (int) $entry['closed_at']);
		}

		return $query->count();
	}

	private function closeIfDone($packageId, array $entry)
	{
		if (!empty($entry['closed_at'])) {
			return;
		}

		$reason = '';
		$max = (int) ($entry['max_sales'] ?? 0);

		if (!empty($entry['ends_at']) && (int) $entry['ends_at'] <= time()) {
			$reason = 'time';
		} elseif ($max > 0 && $this->sold($packageId, $entry) >= $max) {
			$reason = 'sold_out';
		}

		$package = DB::table('package')->where('id', $packageId)->first(['id', 'type']);

		if (!$package) {
			$reason = 'deleted';
		}

		if ($reason === '') {
			return;
		}

		// the admin may have saved a new promotion on this plan since it was read
		$fresh = $this->map()[(string) $packageId] ?? null;
		if (!is_array($fresh) || !empty($fresh['closed_at'])
			|| (int) ($fresh['updated_at'] ?? 0) !== (int) ($entry['updated_at'] ?? 0)) {
			return;
		}

		if ($package && ($entry['kind'] ?? '') === 'discount' && isset($entry['original']) && is_array($entry['original'])) {
			DB::table('package')->where('id', $packageId)
				->update(['price_option' => json_encode($entry['original'])]);
		}

		$this->patchEntry($packageId, [
			'closed_at'     => time(),
			'closed_reason' => $reason,
			'end_told'      => 0,
		]);

		echo date('Y-m-d H:i:s') . " promotion on package {$packageId} closed ({$reason})" . PHP_EOL;
	}

	/* start and end notes for the admin chats, each sent once */
	private function announce($packageId, array $entry)
	{
		$name = (string) DB::table('package')->where('id', $packageId)->value('name');
		$name = $name !== '' ? $name : "#{$packageId}";

		if (empty($entry['closed_at']) && empty($entry['start_told']) && !empty($entry['started_at'])) {
			$this->patchEntry($packageId, ['start_told' => 1]);
			$this->tellAdmins("🚀 شروع پروموشن\n📦 {$name}\n" . $this->describe($entry));
			return;
		}

		if (!empty($entry['closed_at']) && empty($entry['end_told'])) {
			$this->patchEntry($packageId, ['end_told' => 1]);

			$reasons = [
				'time'     => 'مهلت تمام شد',
				'sold_out' => 'ظرفیت فروش تکمیل شد',
				'admin'    => 'ادمین آن را بست',
				'deleted'  => 'پکیج حذف شده',
			];
			$reason = $reasons[$entry['closed_reason'] ?? ''] ?? (string) ($entry['closed_reason'] ?? '');
			$sold = $this->sold($packageId, $entry);

			$text = "🏁 پایان پروموشن\n📦 {$name}\n❔ دلیل: {$reason}\n🛒 فروش در این پروموشن: {$sold}";
			if (($entry['kind'] ?? '') === 'discount') {
				$text .= "\n💰 قیمت‌ها به قیمت اصلی برگشت.";
			}

			$this->tellAdmins($text);
		}
	}

	// ------------------------------------------------------------ the channel

	const CYCLE_NAMES = [
		'onetime' => 'یکبار', 'month' => 'ماهانه', 'quater' => 'سه‌ماهه',
		'semiannual' => 'شش‌ماهه', 'annual' => 'سالانه', 'custom' => 'دوره‌ی ویژه',
	];

	private function channel($packageId, array $entry)
	{
		$chat = trim((string) $this->setting('promo_channel_id'));

		if ($chat === '' || $this->token === '') {
			return;
		}

		$posted = (int) ($entry['channel_msg'] ?? 0);

		// closed: the post says so and loses its button, once
		if (!empty($entry['closed_at'])) {
			if ($posted > 0 && empty($entry['channel_closed'])) {
				$this->patchEntry($packageId, ['channel_closed' => 1]);
				$this->api('editMessageText', [
					'chat_id'    => $chat,
					'message_id' => $posted,
					'text'       => "⛔️ <b>این پروموشن به پایان رسید</b>\n\n" . $this->channelText($packageId, $entry),
					'parse_mode' => 'HTML',
				]);
			}
			return;
		}

		// run out but not closed yet: the next run closes it and handles the post
		if (empty($entry['channel']) || !Package::promoRunning($entry + ['packageid' => $packageId])) {
			return;
		}

		$text = $this->channelText($packageId, $entry);
		$hash = md5($text);

		if ($posted > 0 && $hash === (string) ($entry['channel_hash'] ?? '')) {
			return;
		}

		$site = rtrim(trim((string) $this->setting('promo_site_url')) ?: 'https://p.digitsell-shop.ir', '/');
		$params = [
			'chat_id'      => $chat,
			'text'         => $text,
			'parse_mode'   => 'HTML',
			'reply_markup' => json_encode(['inline_keyboard' => [[[
				'text' => '🛒 خرید همین پکیج',
				'url'  => "{$site}/portal/plan/details?id={$packageId}",
			]]]], JSON_UNESCAPED_UNICODE),
		];

		if ($posted > 0) {
			$reply = $this->api('editMessageText', $params + ['message_id' => $posted]);
			// "message is not modified" is fine: the text on Telegram is already right
			$this->patchEntry($packageId, ['channel_hash' => $hash]);
			return;
		}

		$reply = $this->api('sendMessage', $params);

		if (is_array($reply) && !empty($reply['ok']) && !empty($reply['result']['message_id'])) {
			$this->patchEntry($packageId, ['channel_msg' => (int) $reply['result']['message_id'], 'channel_hash' => $hash]);
			echo date('Y-m-d H:i:s') . " promotion on package {$packageId} posted in the channel" . PHP_EOL;
		} else {
			echo date('Y-m-d H:i:s') . " channel post for package {$packageId} refused: "
				. (is_array($reply) ? (string) ($reply['description'] ?? '?') : 'no answer') . PHP_EOL;
		}
	}

	/* the plan card, in Telegram's HTML */
	private function channelText($packageId, array $entry)
	{
		$package = DB::table('package')->where('id', $packageId)->first();

		if (!$package) {
			return '';
		}

		$e = function ($text) {
			return htmlspecialchars((string) $text, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
		};

		$tags = [];
		if (($entry['kind'] ?? '') === 'discount') {
			$tags[] = '🔥 <b>' . (int) $entry['percent'] . '٪ تخفیف</b>';
		} elseif (($entry['kind'] ?? '') === 'special') {
			$tags[] = '⭐ <b>ویژه</b>';
		}
		if (!empty($entry['prize']['on'])) {
			$tags[] = '🎁 <b>جایزه‌دار</b>';
		}

		$lines = [];
		if ($tags) {
			$lines[] = implode('  ·  ', $tags);
			$lines[] = '━━━━━━━━━━━━━━';
		}
		$lines[] = '📦 <b>' . $e($package->name) . '</b>';

		$now = json_decode((string) $package->price_option, true);
		$now = is_array($now) ? $now : [];
		$list = ($entry['kind'] ?? '') === 'discount' && isset($entry['original']) && is_array($entry['original'])
			? $entry['original'] : $now;
		$unit = $this->currencyUnit();

		foreach (self::CYCLE_NAMES as $cycle => $label) {
			if (!isset($now[$cycle]['price']) || $now[$cycle]['price'] === '' || $now[$cycle]['price'] === null) {
				continue;
			}

			if ($cycle === 'custom' && !empty($now['custom']['expire'])) {
				$label = (int) $now['custom']['expire'] . ' روزه';
			}

			$price = (float) $now[$cycle]['price'];
			$was = isset($list[$cycle]['price']) ? (float) $list[$cycle]['price'] : $price;
			$line = "💰 {$label}: ";

			if ($was > $price) {
				$line .= '<s>' . number_format($was) . '</s> ⬅️ ';
			}

			$lines[] = $line . '<b>' . number_format($price) . '</b>' . ($unit !== '' ? " {$unit}" : '');
		}

		$specs = [];
		if ((float) $package->bandwidth > 0) {
			$specs[] = '📶 ' . ((float) $package->bandwidth >= 10000 ? 'نامحدود' : rtrim(rtrim(number_format((float) $package->bandwidth, 2, '.', ''), '0'), '.') . ' گیگ');
		}
		if ((int) $package->iplimit > 0) {
			$specs[] = '👥 ' . (int) $package->iplimit . ' کاربر همزمان';
		}
		if ($specs) {
			$lines[] = implode('  ·  ', $specs);
		}

		$extra = [];
		if (!empty($entry['prize']['on'])) {
			$p = $entry['prize'];
			$gb = (int) ($p['gb_min'] ?? 0) . ' تا ' . (int) ($p['gb_max'] ?? 0) . ' گیگ';
			$days = (int) ($p['days_min'] ?? 0) . ' تا ' . (int) ($p['days_max'] ?? 0) . ' روز';
			$mode = $p['mode'] ?? 'either';
			$extra[] = '🎁 هر خرید جایزه دارد: <b>' . ($mode === 'gb' ? $gb : ($mode === 'days' ? $days : "{$gb} یا {$days}")) . '</b>';
		}
		if (trim((string) ($entry['occasion'] ?? '')) !== '') {
			$extra[] = '📣 ' . $e(trim((string) $entry['occasion']));
		}
		if (!empty($entry['ends_at'])) {
			$extra[] = '⏳ مهلت: تا ' . $this->date((int) $entry['ends_at'], true);
		}
		$max = (int) ($entry['max_sales'] ?? 0);
		if ($max > 0 && !empty($entry['show_left'])) {
			$left = max(0, $max - $this->sold($packageId, $entry));
			$extra[] = "🔢 فقط <b>{$left}</b> عدد باقی مانده";
		}

		if ($extra) {
			$lines[] = '';
			$lines = array_merge($lines, $extra);
		}

		return implode("\n", $lines);
	}

	/* "تومان" / "ریال" as the site shows it, or nothing */
	private function currencyUnit()
	{
		static $unit = null;

		if ($unit === null) {
			$unit = '';
			try {
				$row = \App\Http\Models\Currency::where('currency', $this->setting('default_currency'))->first();
				if ($row) {
					$unit = trim((string) $row->symbol_right) !== '' ? trim((string) $row->symbol_right) : trim((string) $row->symbol_left);
				}
			} catch (\Throwable $error) {
				$unit = '';
			}
		}

		return $unit;
	}

	// ------------------------------------------------------------ announcing

	/*
	 * Tells every customer about a running promotion, a batch per run. The key
	 * is package + start time, so a promotion reopened later is announced
	 * again but one that is only edited is not.
	 */
	private function broadcast($packageId, array $entry)
	{
		if (!empty($entry['closed_at']) || !Package::promoRunning($entry + ['packageid' => $packageId])) {
			return;
		}

		$promo = $packageId . ':' . (int) $entry['started_at'];

		$users = DB::table('user')
			->leftJoin('promo_broadcast', function ($join) use ($promo) {
				$join->on('promo_broadcast.userid', '=', 'user.id')->where('promo_broadcast.promo', '=', $promo);
			})
			->where('user.role', 0)
			->whereNull('promo_broadcast.id')
			->select('user.id', 'user.username', 'user.email', 'user.telegram_id', 'user.notification')
			->orderBy('user.id', 'asc')
			->limit(self::BROADCAST)
			->get();

		if (count($users) === 0) {
			$this->patchEntry($packageId, ['broadcast_done' => 1]);
			echo date('Y-m-d H:i:s') . " promotion on package {$packageId} announced to every customer" . PHP_EOL;
			return;
		}

		$text = $this->announcement($packageId, $entry);
		$sent = 0;

		foreach ($users as $user) {
			try {
				DB::table('promo_broadcast')->insert(['promo' => $promo, 'userid' => $user->id, 'sent_at' => time()]);
			} catch (\Throwable $error) {
				continue;
			}

			// the "notices" switch on the settings page; unset means on
			$prefs = json_decode((string) $user->notification, true);
			if (is_array($prefs) && isset($prefs['sendnotices']) && (int) $prefs['sendnotices'] === 0) {
				continue;
			}

			if ($this->token !== '' && !empty($user->telegram_id)) {
				$this->api('sendMessage', ['chat_id' => $user->telegram_id, 'text' => $text]);
				usleep(40000);
			}

			$this->mail($user, '🔥 پروموشن جدید', $text);
			$sent++;
		}

		echo date('Y-m-d H:i:s') . " promotion on package {$packageId}: announced to {$sent} customer(s)" . PHP_EOL;
	}

	private function announcement($packageId, array $entry)
	{
		$name = (string) DB::table('package')->where('id', $packageId)->value('name');
		$site = rtrim(trim((string) $this->setting('promo_site_url')) ?: 'https://p.digitsell-shop.ir', '/');

		return "🔥 پروموشن جدید: «{$name}»\n"
			. $this->describe($entry)
			. "\n\n👉 خرید: {$site}/portal/plan/details?id={$packageId}";
	}

	// ------------------------------------------------------------ messages

	/* "20٪ تخفیف · 🎁 1 تا 5 گیگ · ⏳ تا … · 🔢 سقف 10" */
	private function describe(array $entry)
	{
		$lines = [];

		if (($entry['kind'] ?? '') === 'discount') {
			$lines[] = '🏷 ' . (int) $entry['percent'] . '٪ تخفیف';
		} elseif (($entry['kind'] ?? '') === 'special') {
			$lines[] = '⭐ پکیج ویژه';
		}

		if (!empty($entry['prize']['on'])) {
			$p = $entry['prize'];
			$gb = (int) ($p['gb_min'] ?? 0) . ' تا ' . (int) ($p['gb_max'] ?? 0) . ' گیگ';
			$days = (int) ($p['days_min'] ?? 0) . ' تا ' . (int) ($p['days_max'] ?? 0) . ' روز';
			$mode = $p['mode'] ?? 'either';
			$lines[] = '🎁 جایزه: ' . ($mode === 'gb' ? $gb : ($mode === 'days' ? $days : "{$gb} یا {$days}"));
		}

		if (!empty($entry['ends_at'])) {
			$lines[] = '⏳ پایان: ' . $this->date((int) $entry['ends_at'], true);
		}

		if (!empty($entry['max_sales'])) {
			$lines[] = '🔢 سقف فروش: ' . (int) $entry['max_sales'];
		}

		if (trim((string) ($entry['occasion'] ?? '')) !== '') {
			$lines[] = '📣 ' . trim((string) $entry['occasion']);
		}

		return implode("\n", $lines);
	}

	/* LRM marks keep a Latin date reading left to right inside Persian text */
	private function date($stamp, $withTime = false)
	{
		return "\u{200E}" . date($withTime ? 'Y-m-d H:i' : 'Y-m-d', $stamp) . "\u{200E}";
	}

	private function prizeText(array $prize)
	{
		return $prize['kind'] === 'gb' ? "{$prize['amount']} گیگ حجم" : "{$prize['amount']} روز اعتبار";
	}

	/* where the plan stands now, read after the prize was applied */
	private function balance($userId)
	{
		$u = DB::table('user')->where('id', $userId)->first(['transfer_enable', 'u', 'd', 'expire_in']);

		if (!$u) {
			return '';
		}

		$left = max(0, ((float) $u->transfer_enable - (float) $u->u - (float) $u->d) / 1073741824);
		$left = $left < 1
			? (int) round($left * 1024) . ' مگ'
			: rtrim(rtrim(number_format($left, 2, '.', ''), '0'), '.') . ' گیگ';
		$until = strtotime((string) $u->expire_in);

		return $until > time()
			? "📦 حجم باقی‌مانده: {$left} · اعتبار تا " . $this->date($until)
			: '';
	}

	private function customerText($user, $order, array $entry, $prize)
	{
		$name = (string) DB::table('package')->where('id', $order->packageid)->value('name');
		$text = "🎉 خرید «{$name}» با موفقیت انجام شد.\n";

		if (($entry['kind'] ?? '') === 'discount') {
			$text .= '🏷 با ' . (int) $entry['percent'] . "٪ تخفیف پروموشن خریدی.\n";
		} elseif (($entry['kind'] ?? '') === 'special') {
			$text .= "⭐ این یکی از پکیج‌های ویژه بود.\n";
		}

		if ($prize) {
			$text .= '🎁 جایزه‌ات: ' . $this->prizeText($prize) . " که همین الان به اشتراکت اضافه شد.\n";
		}

		return $text . "\n" . $this->balance($user->id);
	}

	private function tellCustomer($user, $order, array $entry, $prize)
	{
		$text = $this->customerText($user, $order, $entry, $prize);

		if ($this->token !== '' && !empty($user->telegram_id)) {
			$this->api('sendMessage', ['chat_id' => $user->telegram_id, 'text' => $text]);
		}

		$this->mail($user, $prize ? '🎁 جایزه‌ی خرید پروموشن' : '🎉 خرید پروموشن', $text);
	}

	private function adminPurchase($user, $order, array $entry, $prize)
	{
		$name = (string) DB::table('package')->where('id', $order->packageid)->value('name');
		$who = "👤 {$user->username} (#{$user->id})";

		if ((string) ($user->telegram_name ?? '') !== '') {
			$who .= " · @{$user->telegram_name}";
		}

		$text = "🛍 خرید پکیج پروموشن‌دار\n{$who}\n📦 {$name} · سفارش #{$order->id}";

		if (isset($order->total_amount)) {
			$text .= ' · ' . number_format((float) $order->total_amount);
		}

		if (($entry['kind'] ?? '') === 'discount') {
			$text .= "\n🏷 " . (int) $entry['percent'] . '٪ تخفیف';
		} elseif (($entry['kind'] ?? '') === 'special') {
			$text .= "\n⭐ ویژه";
		}

		if ($prize) {
			$text .= "\n🎁 جایزه: " . $this->prizeText($prize);
		}

		$max = (int) ($entry['max_sales'] ?? 0);
		if ($max > 0) {
			$text .= "\n🔢 فروش: " . $this->sold((int) $order->packageid, $entry) . " از {$max}";
		}

		$balance = $this->balance($user->id);

		return $text . ($balance !== '' ? "\n{$balance}" : '');
	}

	private function tellAdmins($text)
	{
		if ($this->token === '') {
			return;
		}

		$chats = trim((string) $this->setting('tgjoin_admin_chats'));
		if ($chats === '') {
			$chats = trim((string) $this->setting('telegramchatid'));
		}

		foreach (preg_split('~[\s,]+~', $chats, -1, PREG_SPLIT_NO_EMPTY) as $chat) {
			$this->api('sendMessage', ['chat_id' => $chat, 'text' => $text]);
		}
	}

	/*
	 * E-mail goes through the panel's own queue, the way UserJob sends its
	 * notices, so it uses whatever the admin configured under Settings → Mail
	 * and only when mail is switched on (`maildriver` = 1). `telegramid` is left
	 * empty on purpose: the Telegram message was sent above.
	 */
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
