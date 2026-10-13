<?php
namespace App\Jobs;

use App\Http\Models\Package;
use App\Http\Models\Queue;
use Illuminate\Database\Capsule\Manager as DB;

/**
 * Starts the plans customers reserved earlier - and tells them so.
 *
 * A reservation is sold as an ordinary traffic top-up (type 1, bandwidth 0)
 * whose package carries the `planreserve` marker - see app/Patch/Reserve.php.
 * The panel's own checkout marks the order paid and adds its (zero) gigabytes;
 * nothing in that encoded pipeline knows about a later start, so this job:
 *
 *   1. links each paid reserve order to the reservation that prepared it,
 *   2. once the current plan has ended (and the chosen date has come), starts
 *      the subscription itself - the same fields the panel resets when a plan
 *      begins,
 *   3. tells the customer, in three places at once: a notice on the dashboard
 *      (reserve_notice, read by user/layout/reservebanner.tpl), Telegram and
 *      e-mail - both when the reservation is taken and when it starts,
 *   4. records the order as the subscription purchase it really was.
 *
 * A conditional UPDATE claims each step, so two overlapping runs can never
 * start the same plan twice. Linking is also exposed as linkForUser() so the
 * dashboard can pull in a just-paid reservation without waiting for the cron.
 */
class ReserveJob
{
	/** a prepared check-out left unpaid for this long is dropped */
	const PENDING_TTL = 3600;

	const GB = 1073741824;

	/** one process only has to make the tables once */
	private static $ready = false;

	private $settings = [];

	public function dispatch()
	{
		$this->ensureTables();

		$this->voidStale();
		$linked = $this->linkPaid();
		$started = $this->activateDue();

		return ['linked' => $linked, 'started' => $started];
	}

	private function ensureTables()
	{
		if (self::$ready) {
			return;
		}

		DB::statement(
			'CREATE TABLE IF NOT EXISTS plan_reserve (
				id BIGINT(20) NOT NULL AUTO_INCREMENT,
				userid INT(11) NOT NULL,
				orderid BIGINT(20) DEFAULT NULL,
				packageid BIGINT(20) NOT NULL,
				planid BIGINT(20) NOT NULL,
				cycle VARCHAR(16) NOT NULL DEFAULT \'month\',
				days INT(11) NOT NULL DEFAULT 30,
				mode VARCHAR(8) NOT NULL DEFAULT \'after\',
				activate_at BIGINT(20) NOT NULL DEFAULT 0,
				amount DECIMAL(12,2) NOT NULL DEFAULT 0,
				name VARCHAR(255) NOT NULL DEFAULT \'\',
				bandwidth INT(11) NOT NULL DEFAULT 0,
				iplimit INT(11) NOT NULL DEFAULT 0,
				speedlimit INT(11) NOT NULL DEFAULT 0,
				server_group INT(11) NOT NULL DEFAULT 0,
				status TINYINT(1) NOT NULL DEFAULT 0,
				created_at BIGINT(20) NOT NULL DEFAULT 0,
				paid_at BIGINT(20) NOT NULL DEFAULT 0,
				activated_at BIGINT(20) NOT NULL DEFAULT 0,
				cancelled_at BIGINT(20) NOT NULL DEFAULT 0,
				expire_before DATETIME NULL,
				expire_after DATETIME NULL,
				PRIMARY KEY (id),
				KEY userid (userid),
				KEY orderid (orderid),
				KEY status (status)
			) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4');

		DB::statement(
			'CREATE TABLE IF NOT EXISTS reserve_notice (
				id BIGINT(20) NOT NULL AUTO_INCREMENT,
				userid INT(11) NOT NULL,
				kind VARCHAR(16) NOT NULL DEFAULT \'\',
				ref VARCHAR(64) NOT NULL,
				name VARCHAR(255) NOT NULL DEFAULT \'\',
				cycle VARCHAR(16) NOT NULL DEFAULT \'month\',
				days INT(11) NOT NULL DEFAULT 0,
				mode VARCHAR(8) NOT NULL DEFAULT \'after\',
				activate_at BIGINT(20) NOT NULL DEFAULT 0,
				amount DECIMAL(12,2) NOT NULL DEFAULT 0,
				expire_after DATETIME NULL,
				seen TINYINT(1) NOT NULL DEFAULT 0,
				created BIGINT(20) NOT NULL DEFAULT 0,
				PRIMARY KEY (id),
				UNIQUE KEY ref (ref),
				KEY user_seen (userid, seen)
			) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4');

		self::$ready = true;
	}

	/** A prepared check-out nobody paid for must not block the next one. */
	private function voidStale()
	{
		DB::table('plan_reserve')->where('status', 0)
			->where('created_at', '<', time() - self::PENDING_TTL)->delete();
	}

	/** Paid orders on a reserve package that no reservation holds yet. */
	private function pendingOrders($userId = null)
	{
		$query = DB::table('orders')
			->join('package', 'package.id', '=', 'orders.packageid')
			->leftJoin('plan_reserve', 'plan_reserve.orderid', '=', 'orders.id')
			->where('orders.status', 1)
			->whereNotNull('orders.pay_date')
			->where('package.order_note', 'like', '%' . Package::RESERVE_MARKER . '%')
			->whereNull('plan_reserve.id')
			->select('orders.id as orderid', 'orders.userid', 'orders.packageid', 'orders.total_amount', 'package.order_note')
			->orderBy('orders.id', 'asc')
			->limit(200);

		if ($userId !== null) {
			$query->where('orders.userid', $userId);
		}

		return $query->get();
	}

	/*
	 * Links one account's paid reserve orders - called by the dashboard so a
	 * reservation shows the moment the customer is back, and by dispatch() for
	 * everybody on the cron.
	 */
	public function linkForUser(int $userId)
	{
		$this->ensureTables();

		$linked = 0;

		foreach ($this->pendingOrders($userId) as $order) {
			if ($this->linkOrder($order)) {
				$linked++;
			}
		}

		return $linked;
	}

	private function linkPaid()
	{
		$linked = 0;

		foreach ($this->pendingOrders() as $order) {
			if ($this->linkOrder($order)) {
				$linked++;
			}
		}

		return $linked;
	}

	private function linkOrder($order): bool
	{
		$meta = Package::decodeReserveMeta($order->order_note);

		if ($meta === null) {
			return false;
		}

		$planid = (int) ($meta['plan'] ?? 0);
		$cycle = (string) ($meta['cycle'] ?? '');
		$days = (int) ($meta['days'] ?? 0);

		$pending = DB::table('plan_reserve')
			->where('userid', $order->userid)
			->where('planid', $planid)
			->where('cycle', $cycle)
			->where('status', 0)
			->orderBy('id', 'desc')
			->first();

		if ($pending) {
			$claim = DB::table('plan_reserve')
				->where('id', $pending->id)
				->where('status', 0)
				->update([
					'orderid' => $order->orderid,
					'status'  => 1,
					'paid_at' => time(),
					'amount'  => (float) $order->total_amount,
				]);

			if ($claim < 1) {
				return false;
			}

			echo date('Y-m-d H:i:s') . sprintf(
				' order %d: reservation %d paid (user %d)', $order->orderid, $pending->id, $order->userid) . PHP_EOL;

			$this->announceReserved((int) $order->userid, (int) $pending->id, $pending);

			return true;
		}

		// no pending intent: rebuild it from the marker, "after this plan"
		$plan = DB::table('package')->where('id', $planid)->first();

		$id = DB::table('plan_reserve')->insertGetId([
			'userid'       => $order->userid,
			'orderid'      => $order->orderid,
			'packageid'    => (int) $order->packageid,
			'planid'       => $planid,
			'cycle'        => $cycle,
			'days'         => $days,
			'mode'         => 'after',
			'activate_at'  => 0,
			'amount'       => (float) $order->total_amount,
			'name'         => $plan ? (string) $plan->name : '',
			'bandwidth'    => $plan ? (int) $plan->bandwidth : 0,
			'iplimit'      => $plan ? (int) $plan->iplimit : 0,
			'speedlimit'   => $plan ? (int) $plan->speedlimit : 0,
			'server_group' => $plan ? (int) $plan->server_group : 0,
			'status'       => 1,
			'created_at'   => time(),
			'paid_at'      => time(),
		]);

		echo date('Y-m-d H:i:s') . sprintf(
			' order %d: reservation rebuilt from marker (user %d)', $order->orderid, $order->userid) . PHP_EOL;

		$this->announceReserved((int) $order->userid, (int) $id, (object) [
			'name'        => $plan ? (string) $plan->name : '',
			'cycle'       => $cycle,
			'days'        => $days,
			'mode'        => 'after',
			'activate_at' => 0,
			'amount'      => (float) $order->total_amount,
		]);

		return true;
	}

	/*
	 * Start every paid reservation whose turn has come.
	 *
	 * "After the current plan" means the account must have no running plan any
	 * more; a reserved date only ever pushes that later, it never cuts a live
	 * subscription short - the buyer's choice was that the reserved plan
	 * replaces the current one once it ends.
	 */
	private function activateDue()
	{
		$due = DB::table('plan_reserve')
			->where('plan_reserve.status', 1)
			->join('user', 'user.id', '=', 'plan_reserve.userid')
			->select('plan_reserve.*', 'user.expire_in as user_expire', 'user.packageid as user_packageid')
			->orderBy('plan_reserve.id', 'asc')
			->limit(200)
			->get();

		$started = 0;

		foreach ($due as $row) {
			$now = time();
			$current = $row->user_expire ? (int) strtotime((string) $row->user_expire) : 0;

			// the plan the customer is on has not ended yet, so an "after it
			// ends" reservation waits. A dated one waits too - except against a
			// plan that never expires, where the date is the only thing that can
			// ever decide.
			if ($current > $now && !($row->mode === 'date' && $current > $now + 315360000)) {
				continue;
			}

			// a chosen date that has not come yet
			if ($row->mode === 'date' && (int) $row->activate_at > $now) {
				continue;
			}

			// claim it; a zero row count means another run took it
			$claim = DB::table('plan_reserve')
				->where('id', $row->id)
				->where('status', 1)
				->update(['status' => 2, 'activated_at' => $now]);

			if ($claim < 1) {
				continue;
			}

			$user = DB::table('user')->where('id', $row->userid)->first();

			if (!$user) {
				continue;
			}

			$this->startSubscription($row, $user, $now);
			$started++;
		}

		return $started;
	}

	private function startSubscription($row, $user, int $now)
	{
		$days = max(1, (int) $row->days);
		$bandwidth = (int) $row->bandwidth;
		$quota = $bandwidth * self::GB;

		// a fresh plan: the same fields the panel resets when a subscription
		// starts. "Now" comes from PHP: MySQL's NOW() runs on UTC here while
		// expire_in is stored in the panel's local time, 3.5 hours apart.
		$expire = date('Y-m-d H:i:s', $now + $days * 86400);

		DB::update(
			'UPDATE user SET packageid = ?, plan = ?, server_group = ?, iplimit = ?, speedlimit = ?,
				transfer_enable = ?, u = 0, d = 0, used = 0, data_expire_cron = 0, data_used_cron = 0,
				expire_in = ?
			 WHERE id = ?',
			[(int) $row->planid, (string) $row->cycle, (int) $row->server_group,
				(int) $row->iplimit, (int) $row->speedlimit, $quota, $expire, (int) $row->userid]);

		// the reserve order becomes the subscription purchase it really was,
		// so order history, "current plan" and the time-plan allowance window
		// all see it. The payment date is left where it was: the money did
		// change hands when it was paid.
		if (!empty($row->orderid) && DB::table('package')->where('id', (int) $row->planid)->exists()) {
			DB::table('orders')->where('id', (int) $row->orderid)->update([
				'packageid'   => (int) $row->planid,
				'packagetype' => 2,
				'plan'        => (string) $row->cycle,
				'plan_expire' => $days,
				'expire'      => $now + $days * 86400,
			]);
		}

		DB::table('plan_reserve')->where('id', (int) $row->id)->update([
			'expire_before' => $user->expire_in,
			'expire_after'  => $expire,
		]);

		echo date('Y-m-d H:i:s') . sprintf(
			' reservation %d: started %s (%d days) for user %d, %s -> %s',
			(int) $row->id, (string) $row->cycle, $days, (int) $row->userid,
			(string) $user->expire_in, $expire) . PHP_EOL;

		$this->announceStarted((int) $row->userid, (int) $row->id, $row, $expire, $days);
	}

	// ---------------------------------------------------------------- notice

	/*
	 * A reservation was taken (paid): a dashboard notice and a message.
	 */
	private function announceReserved(int $userId, int $reservationId, $row)
	{
		$when = (string) $row->mode === 'date' && (int) $row->activate_at > 0
			? 'از تاریخ ' . Package::jalaliText((int) $row->activate_at) . ' فعال می‌شود'
			: 'به‌محض پایان بسته‌ی فعلی فعال می‌شود';

		$text = "پلن «{$row->name}» برای شما رزرو شد.\n{$when}.";
		$text .= "\nتا آن زمان بسته‌ی فعلی‌تان دست‌نخورده می‌ماند.";

		$this->announce($userId, 'reserved', 'r:' . $reservationId,
			'🎉 پلن رزرو شما ثبت شد', $text, $row);
	}

	/**
	 * A reservation started: a dashboard notice and a message.
	 */
	private function announceStarted(int $userId, int $reservationId, $row, string $expire, int $days)
	{
		$text = "پلن رزروشده‌ی «{$row->name}» فعال شد.\n"
			. $days . ' روز اعتبار از امروز برای شما شروع شد'
			. ($expire !== '' ? ' (تا ' . Package::jalaliText((int) strtotime($expire)) . ').' : '.');

		$this->announce($userId, 'started', 's:' . $reservationId,
			'✅ پلن رزرو شما فعال شد', $text, (object) [
				'name'        => $row->name,
				'cycle'       => $row->cycle,
				'days'        => $days,
				'mode'        => $row->mode,
				'activate_at' => (int) $row->activate_at,
				'amount'      => (float) $row->amount,
			], $expire);
	}

	/**
	 * One message, three places: dashboard (reserve_notice), Telegram and
	 * e-mail. The unique key on `ref` is the guard - a row that already exists
	 * means this event was announced before, and nothing is sent again.
	 */
	private function announce(int $userId, string $kind, string $ref, string $title, string $text, $row, ?string $expireAfter = null)
	{
		try {
			$fresh = DB::table('reserve_notice')->insertOrIgnore([
				'userid'       => $userId,
				'kind'         => $kind,
				'ref'          => $ref,
				'name'         => (string) $row->name,
				'cycle'        => (string) $row->cycle,
				'days'         => (int) $row->days,
				'mode'         => (string) $row->mode,
				'activate_at'  => (int) $row->activate_at,
				'amount'       => (float) $row->amount,
				'expire_after' => $expireAfter,
				'seen'         => 0,
				'created'      => time(),
			]);
		} catch (\Throwable $error) {
			echo date('Y-m-d H:i:s') . ' reserve notice not stored for user ' . $userId . ': ' . $error->getMessage() . PHP_EOL;
			return;
		}

		if ($fresh < 1) {
			return;
		}

		$this->notify($userId, $title, $text);
	}

	/*
	 * The message itself - Telegram and e-mail - shared by every
	 * reservation event, with or without a dashboard notice.
	 */
	private function notify(int $userId, string $title, string $text)
	{
		$user = DB::table('user')->where('id', $userId)->first(['id', 'username', 'email', 'telegram_id']);

		if (!$user) {
			return;
		}

		$token = $this->setting('telegram') == 1 ? trim((string) $this->setting('telegramtoken')) : '';

		if ($token !== '' && !empty($user->telegram_id)) {
			$this->api($token, 'sendMessage', ['chat_id' => $user->telegram_id, 'text' => $title . "\n\n" . $text]);
		}

		$this->mail($user, $title, $text);
	}

	/*
	 * A reservation was cancelled and its price went back into the
	 * buyer's account credit. The checkout spends that credit
	 * first, so the money is already at work on the next purchase.
	 */
	public function announceRefund(int $userId, float $amount)
	{
		$this->notify($userId, 'برگشت به موجودی', sprintf(
			"مبلغ %s ریال به موجودی اعتبار شما برگشت خورد.\n"
			. "این مبلغ در خریدهای بعدی به صورت خودکار اعمال می‌شود.",
			number_format(round($amount))
		));
	}

	private function mail($user, string $subject, string $text)
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
					'lines'    => array_values(array_filter(explode("\n", $text), 'strlen')),
				], JSON_UNESCAPED_UNICODE),
				'time'       => time(),
			]);
		} catch (\Throwable $error) {
			echo date('Y-m-d H:i:s') . ' mail not queued for user ' . $user->id . ': ' . $error->getMessage() . PHP_EOL;
		}
	}

	private function api(string $token, string $method, array $params)
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

	private function setting(string $name)
	{
		if (!array_key_exists($name, $this->settings)) {
			$this->settings[$name] = DB::table('settings')->where('name', $name)->value('value');
		}

		return $this->settings[$name];
	}
}
