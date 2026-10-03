<?php
namespace App\Jobs;

use App\Http\Models\Package;
use App\Http\Models\Queue;
use Illuminate\Database\Capsule\Manager as DB;

/**
 * Pay-as-you-go: a charge wallet the account falls back on when its plan ends,
 * the way Iranian mobile operators do it.
 *
 * Every minute (bin/payg.php) this job:
 *
 *   1. credits paid charge orders to the wallet, with the tiered bonus;
 *   2. returns commission that was moved into user.money for a subscription
 *      checkout and not spent;
 *   3. bills the trafficlog rows of accounts running on balance, at each
 *      server's price per GB - nothing is billed for a server that is down;
 *   4. moves accounts between modes:
 *        plan     the plan pays; the job does not touch the account
 *        balance  the plan ran out (time or data) and there is money: the job
 *                 keeps expire_in a day ahead and transfer_enable at what the
 *                 balance buys, so the panel's own quota check does the cut-off
 *        empty    on balance, but the money ran out: transfer_enable = used
 *   5. tells the customer - Telegram, e-mail and a notice on the dashboard -
 *      when the plan is ending, when billing starts, when the balance is low
 *      or gone, and when a charge lands.
 *
 * A charge is sold by the panel's own encoded checkout as a topup package
 * (bandwidth 0) whose order_note carries {"paygcharge":{...}}, minted per
 * amount by app/Patch/Payg.php - the same trick as the per-day time plans.
 *
 * Billing is exactly-once: the trafficlog window is read and the watermark
 * moved inside one transaction, under a MySQL named lock.
 */
class PaygJob
{
	const GB = 1073741824;
	const MARKER = '"paygcharge"';

	/* trafficlog rows up to this recent are billed; newer ones may still be arriving */
	const LAG = 60;

	/* a node silent for this long counts as down */
	const STALE_NODE = 300;

	/* OpenVPN servers log their traffic under this + node id (app/Patch/Ovpn.php) */
	const OVPN_SERVER_BASE = 900000;

	/* while on balance, expire_in is kept at least this far ahead */
	const KEEP_AHEAD = 86400;

	/* a plan closer than this to its expiry counts as ended */
	const PLAN_MARGIN = 180;

	/* charge packages nobody bought are deleted after this long */
	const MINTED_TTL = 86400;

	/* commission moved into money for a checkout is returned after this long */
	const HOLD_TTL = 1800;

	/* no headroom limit when every server is free */
	const FREE_HEADROOM = 1099511627776;

	private $settings = [];

	private $token = '';

	private $servers = null;

	public function dispatch()
	{
		if (!DB::schema()->hasTable('payg_wallet')) {
			echo date('Y-m-d H:i:s') . ' payg tables missing - run the patch migrations' . PHP_EOL;
			return 0;
		}

		$this->settings = DB::table('settings')->pluck('value', 'name')->all();
		$this->token = $this->setting('telegram') == 1 ? trim((string) $this->setting('telegramtoken')) : '';

		$credited = $this->creditCharges();
		$this->resolveHolds();

		$billed = 0;

		if ($this->setting('payg_enabled') == 1) {
			$this->transitions();
			$billed = $this->bill();

			if ((int) date('i') % 5 === 0) {
				$this->warnings();
			}
		}

		$this->retireCharges();

		return $credited + $billed;
	}

	private function setting($name, $fallback = null)
	{
		return array_key_exists($name, $this->settings) ? $this->settings[$name] : $fallback;
	}

	private function putSetting($name, $value)
	{
		if (DB::table('settings')->where('name', $name)->exists()) {
			DB::table('settings')->where('name', $name)->update(['value' => (string) $value]);
		} else {
			DB::table('settings')->insert(['name' => $name, 'value' => (string) $value]);
		}

		$this->settings[$name] = (string) $value;
	}

	// ---------------------------------------------------------------- charges

	public static function decodeCharge($note)
	{
		if (!is_string($note) || strpos($note, self::MARKER) === false) {
			return null;
		}

		$data = json_decode($note, true);

		return isset($data['paygcharge']) && is_array($data['paygcharge']) ? $data['paygcharge'] : null;
	}

	/* the percentage of the tier the amount reaches, 0 when none */
	public static function bonusPercent($amount, $tiers)
	{
		$tiers = is_array($tiers) ? $tiers : json_decode((string) $tiers, true);
		$best = 0.0;
		$reached = -1.0;

		foreach (is_array($tiers) ? $tiers : [] as $tier) {
			$min = (float) ($tier['min'] ?? 0);
			$percent = (float) ($tier['percent'] ?? 0);

			if ($min > 0 && $amount >= $min && $min > $reached) {
				$reached = $min;
				$best = $percent;
			}
		}

		return max(0.0, min(100.0, $best));
	}

	private function creditCharges()
	{
		$orders = DB::table('orders')
			->join('package', 'package.id', '=', 'orders.packageid')
			->where('orders.status', 1)
			->where('package.order_note', 'like', '%' . self::MARKER . '%')
			->whereRaw("NOT EXISTS (SELECT 1 FROM payg_ledger l WHERE l.ref = CONCAT('order:', orders.id))")
			->select('orders.id', 'orders.userid', 'orders.discount', 'orders.total_amount',
				'orders.gateway_name', 'package.order_note')
			->orderBy('orders.id')
			->limit(200)
			->get();

		$credited = 0;

		foreach ($orders as $order) {
			$meta = self::decodeCharge($order->order_note);
			$amount = round((float) ($meta['amount'] ?? 0) - max(0, (float) $order->discount), 2);

			if ($amount <= 0) {
				// nothing to credit, but claim the order so it is not looked at again
				$this->claimEmpty($order);
				continue;
			}

			$percent = self::bonusPercent($amount, $this->setting('payg_bonus_tiers', '[]'));
			$bonus = round($amount * $percent / 100, 0);

			try {
				$balance = DB::connection()->transaction(function () use ($order, $amount, $bonus, $percent) {
					$wallet = $this->lockWallet((int) $order->userid);
					$balance = (float) $wallet->balance + $amount;
					$now = time();

					$this->ledger((int) $order->userid, 'charge', 'order:' . $order->id, $amount, $balance,
						'order #' . $order->id . ($order->gateway_name ? ' · ' . $order->gateway_name : ''));

					if ($bonus > 0) {
						$balance += $bonus;
						$this->ledger((int) $order->userid, 'bonus', 'bonus:' . $order->id, $bonus, $balance,
							rtrim(rtrim(number_format($percent, 2, '.', ''), '0'), '.') . '%');
					}

					// apply any pending tgjoin gifts for this user
					$pending = DB::table('tgjoin_pending')->where('userid', $order->userid)->get();
					if ($pending) {
						foreach ($pending as $p) {
							$bytes = (float) $p->gb * 1073741824;
							$balance += $bytes;
							$wallet = DB::table('payg_wallet')->where('userid', $order->userid)->first();
							$newGifted = ($wallet ? (float) $wallet->gifted : 0.0) + $bytes;
							DB::table('payg_wallet')->updateOrInsert(
								['userid' => $order->userid],
								['balance' => $balance, 'gifted' => $newGifted, 'charged' => DB::raw('charged + ' . $bytes), 'updated' => time()]
							);
							DB::table('payg_ledger')->insert([
								'userid'        => $order->userid,
								'kind'          => 'tggift',
								'ref'           => 'tgjoin_pending:' . $p->kind . ':' . $order->userid . ':' . time(),
								'amount'        => $bytes,
								'balance_after' => $balance,
								'serverid'      => 0,
								'bytes'         => 0,
								'free_bytes'    => 0,
								'rate'          => 0,
								'note'          => 'Telegram gift applied on charge (' . $p->kind . ')',
								'created'       => time(),
								'updated'       => time(),
							]);
						}
						DB::table('tgjoin_pending')->where('userid', $order->userid)->delete();
						echo date('Y-m-d H:i:s') . " user {$order->userid}: applied " . count($pending) . " pending tgjoin gift(s) on charge" . PHP_EOL;
					}

					DB::table('payg_wallet')->where('userid', $order->userid)->update([
						'balance' => $balance,
						'charged' => DB::raw('charged + ' . (float) $amount),
						'bonus'   => DB::raw('bonus + ' . (float) $bonus),
						'updated' => $now,
					]);

					return $balance;
				});
			} catch (\Throwable $error) {
				// a duplicate ref means another run got there first
				continue;
			}

			$credited++;
			echo date('Y-m-d H:i:s') . sprintf(' order %d: user %d charged %s (+%s bonus), balance %s',
				$order->id, $order->userid, $amount, $bonus, $balance) . PHP_EOL;

			$text = '✅ حسابت ' . $this->money($amount) . ' شارژ شد.';
			if ($bonus > 0) {
				$text .= "\n🎁 هدیه‌ی شارژ: " . $this->money($bonus);
			}
			$text .= "\n💰 موجودی فعلی: " . $this->money($balance);

			$this->notify((int) $order->userid, 'charge', 'order:' . $order->id, '💳 شارژ حساب', $text, true);
		}

		return $credited;
	}

	private function claimEmpty($order)
	{
		try {
			DB::connection()->transaction(function () use ($order) {
				$wallet = $this->lockWallet((int) $order->userid);
				$this->ledger((int) $order->userid, 'charge', 'order:' . $order->id, 0, (float) $wallet->balance,
					'order #' . $order->id . ' · nothing to credit');
			});
		} catch (\Throwable $error) {
		}
	}

	private function lockWallet($userId)
	{
		DB::statement('INSERT IGNORE INTO payg_wallet (userid, updated) VALUES (?, ?)', [$userId, time()]);

		return DB::table('payg_wallet')->where('userid', $userId)->lockForUpdate()->first();
	}

	private function ledger($userId, $kind, $ref, $amount, $balanceAfter, $note = '', $serverId = 0, $bytes = 0, $free = 0, $rate = 0)
	{
		$now = time();

		DB::table('payg_ledger')->insert([
			'userid'        => $userId,
			'kind'          => $kind,
			'ref'           => $ref,
			'amount'        => $amount,
			'balance_after' => $balanceAfter,
			'serverid'      => $serverId,
			'bytes'         => $bytes,
			'free_bytes'    => $free,
			'rate'          => $rate,
			'note'          => mb_substr((string) $note, 0, 250),
			'created'       => $now,
			'updated'       => $now,
		]);
	}

	/* charge rows nobody bought are removed; one an order points at stays forever */
	private function retireCharges()
	{
		$rows = DB::table('package')
			->where('type', 1)
			->where('order_note', 'like', '%' . self::MARKER . '%')
			->select('id', 'order_note')
			->get();

		foreach ($rows as $row) {
			$meta = self::decodeCharge($row->order_note);
			$created = (int) ($meta['created'] ?? 0);

			if ($created === 0 || time() - $created < self::MINTED_TTL) {
				continue;
			}

			if (!DB::table('orders')->where('packageid', $row->id)->exists()) {
				DB::table('package')->where('id', $row->id)->delete();
			}
		}
	}

	// ------------------------------------------------------------ commission

	/*
	 * Commission lives in commission_wallet and only reaches user.money for a
	 * subscription checkout (app/Patch/Payg.php, commission.apply). Whatever of
	 * it the checkout did not use goes back - as soon as a subscription is paid,
	 * or after HOLD_TTL when none was.
	 */
	private function resolveHolds()
	{
		if (!DB::schema()->hasTable('commission_hold')) {
			return;
		}

		$holds = DB::table('commission_hold')->where('resolved', 0)->orderBy('id')->limit(200)->get();

		foreach ($holds as $hold) {
			$paid = DB::table('orders')
				->where('userid', $hold->userid)
				->where('status', 1)
				->where('packagetype', 2)
				->where('pay_date', '>=', (int) $hold->created)
				->exists();

			if (!$paid && time() - (int) $hold->created < self::HOLD_TTL) {
				continue;
			}

			try {
				DB::connection()->transaction(function () use ($hold) {
					$fresh = DB::table('commission_hold')->where('id', $hold->id)->lockForUpdate()->first();

					if (!$fresh || (int) $fresh->resolved === 1) {
						return;
					}

					$user = DB::table('user')->where('id', $hold->userid)->lockForUpdate()->first(['money']);
					$money = $user ? max(0.0, (float) $user->money) : 0.0;
					$back = round(min((float) $hold->amount, $money), 2);

					DB::statement('INSERT IGNORE INTO commission_wallet (userid, updated) VALUES (?, ?)', [$hold->userid, time()]);
					$wallet = DB::table('commission_wallet')->where('userid', $hold->userid)->lockForUpdate()->first();
					$balance = (float) $wallet->balance + $back;

					if ($back > 0) {
						DB::table('user')->where('id', $hold->userid)->update(['money' => $money - $back]);
					}

					DB::table('commission_wallet')->where('userid', $hold->userid)->update([
						'balance' => $balance,
						'spent'   => DB::raw('spent + ' . (float) ((float) $hold->amount - $back)),
						'updated' => time(),
					]);

					DB::table('commission_wallet_log')->insert([
						'userid'        => $hold->userid,
						'kind'          => 'return',
						'ref'           => 'hold:' . $hold->id,
						'amount'        => $back,
						'balance_after' => $balance,
						'note'          => 'spent ' . round((float) $hold->amount - $back, 2),
						'created'       => time(),
					]);

					DB::table('commission_hold')->where('id', $hold->id)->update([
						'resolved'    => 1,
						'returned'    => $back,
						'resolved_at' => time(),
					]);
				});
			} catch (\Throwable $error) {
				echo date('Y-m-d H:i:s') . ' hold ' . $hold->id . ': ' . $error->getMessage() . PHP_EOL;
			}
		}
	}

	// --------------------------------------------------------------- billing

	/* id => ['price' => per GB, 'down' => bool] for every server */
	private function servers()
	{
		if ($this->servers !== null) {
			return $this->servers;
		}

		$default = (float) $this->setting('payg_default_price', 0);
		$rates = DB::table('payg_rate')->pluck('price', 'serverid')->all();
		$list = [];

		foreach (DB::table('servers')->get(['id', 'status', 'alive', 'heartbeat']) as $server) {
			$id = (int) $server->id;
			$age = (int) $server->heartbeat > 0 ? time() - (int) $server->heartbeat : PHP_INT_MAX;

			$list[$id] = [
				'price'   => array_key_exists($id, $rates) ? (float) $rates[$id] : $default,
				'down'    => (int) $server->alive !== 1 || $age > self::STALE_NODE,
				'enabled' => (int) $server->status === 1,
			];
		}

		try {
			foreach (DB::table('ovpn_node')->get(['id', 'enabled', 'heartbeat']) as $node) {
				$id = self::OVPN_SERVER_BASE + (int) $node->id;
				$age = (int) $node->heartbeat > 0 ? time() - (int) $node->heartbeat : PHP_INT_MAX;

				$list[$id] = [
					'price'   => array_key_exists($id, $rates) ? (float) $rates[$id] : $default,
					'down'    => $age > self::STALE_NODE,
					'enabled' => (int) $node->enabled === 1,
				];
			}
		} catch (\Throwable $e) {
			// no OpenVPN table yet
		}

		return $this->servers = $list;
	}

	/* the dearest enabled server decides how many bytes the balance is guaranteed to buy */
	private function maxPrice()
	{
		$max = (float) $this->setting('payg_default_price', 0);

		foreach ($this->servers() as $server) {
			if ($server['enabled']) {
				$max = max($max, $server['price']);
			}
		}

		return $max;
	}

	private function bill()
	{
		$lock = DB::selectOne("SELECT GET_LOCK('payg_bill', 0) AS got");

		if (!$lock || (int) $lock->got !== 1) {
			return 0;
		}

		try {
			return $this->billWindow();
		} finally {
			DB::select("SELECT RELEASE_LOCK('payg_bill')");
		}
	}

	private function billWindow()
	{
		$from = (int) $this->setting('payg_last_log_time', 0);
		$upper = time() - self::LAG;

		// first run: nothing before now is billed
		if ($from <= 0) {
			$this->putSetting('payg_last_log_time', $upper);
			return 0;
		}

		if ($upper <= $from) {
			return 0;
		}

		// catch up an hour at a time after an outage of the cron itself
		$upper = min($upper, $from + 3600);

		$rows = DB::select(
			"SELECT t.userid, t.serverid, SUM(t.u + t.d) AS bytes
			   FROM trafficlog t
			   JOIN payg_wallet w ON w.userid = t.userid
			  WHERE t.datetime > ? AND t.datetime <= ?
			    AND w.mode <> 'plan' AND t.datetime > w.since
			  GROUP BY t.userid, t.serverid",
			[$from, $upper]);

		$byUser = [];
		foreach ($rows as $row) {
			if ((float) $row->bytes > 0) {
				$byUser[(int) $row->userid][(int) $row->serverid] = (float) $row->bytes;
			}
		}

		$servers = $this->servers();
		$default = (float) $this->setting('payg_default_price', 0);
		$outageFree = $this->setting('payg_outage_free', '1') == 1;
		$day = date('Ymd', $upper);

		DB::connection()->transaction(function () use ($byUser, $servers, $default, $outageFree, $day, $upper) {
			foreach ($byUser as $userId => $perServer) {
				$wallet = $this->lockWallet($userId);
				$balance = (float) $wallet->balance;
				$gifted = (float) $wallet->gifted;
				$total = 0.0;

				foreach ($perServer as $serverId => $bytes) {
					$server = $servers[$serverId] ?? ['price' => $default, 'down' => false];
					$free = ($outageFree && $server['down']) || $server['price'] <= 0;
					$cost = $free ? 0.0 : round($bytes / self::GB * $server['price'], 2);

					// spend gifted balance first, then regular balance
					if ($gifted >= $cost) {
						$gifted -= $cost;
					} else {
						$costRemaining = $cost - $gifted;
						$gifted = 0;
						$balance -= $costRemaining;
					}
					$total += $cost;

					DB::statement(
						"INSERT INTO payg_ledger
						        (userid, kind, ref, amount, balance_after, serverid, bytes, free_bytes, rate, note, created, updated)
						 VALUES (?, 'usage', ?, ?, ?, ?, ?, ?, ?, '', ?, ?)
						 ON DUPLICATE KEY UPDATE
						        amount = amount + VALUES(amount),
						        balance_after = VALUES(balance_after),
						        bytes = bytes + VALUES(bytes),
						        free_bytes = free_bytes + VALUES(free_bytes),
						        rate = VALUES(rate),
						        updated = VALUES(updated)",
						[$userId, "use:{$userId}:{$serverId}:{$day}", -$cost, $balance, $serverId,
							$free ? 0 : (int) $bytes, $free ? (int) $bytes : 0, $server['price'], time(), time()]);
				}

				DB::table('payg_wallet')->where('userid', $userId)->update([
					'balance' => $balance,
					'gifted'  => $gifted,
					'spent'   => DB::raw('spent + ' . (float) $total),
					'updated' => time(),
				]);
			}

			// same transaction: a crash here bills nothing and moves nothing
			$this->putSetting('payg_last_log_time', $upper);
		});

		return count($byUser);
	}

	// ------------------------------------------------------------ transitions

	private function transitions()
	{
		$rows = DB::table('payg_wallet as w')
			->join('user as usr', 'usr.id', '=', 'w.userid')
			->where(function ($query) {
				$query->where('w.mode', '<>', 'plan')->orWhere('w.balance', '>', 0);
			})
			->select('w.userid', 'w.balance', 'w.mode', 'w.since', 'w.auto', 'w.last_used',
				'usr.transfer_enable', 'usr.u as used_up', 'usr.d as used_down', 'usr.expire_in',
				'usr.server_group',
				DB::raw("EXISTS (SELECT 1 FROM orders o WHERE o.userid = usr.id AND o.status = 1 AND o.packagetype = 2) AS had_plan"))
			->get();

		foreach ($rows as $row) {
			try {
				$this->step($row);
			} catch (\Throwable $error) {
				echo date('Y-m-d H:i:s') . ' user ' . $row->userid . ': ' . $error->getMessage() . PHP_EOL;
			}
		}
	}

	private function step($row)
	{
		$userId = (int) $row->userid;
		$used = (float) $row->used_up + (float) $row->used_down;
		$expire = $row->expire_in ? (int) strtotime((string) $row->expire_in) : 0;
		$balance = (float) $row->balance;
		$auto = (int) $row->auto === 1;
		$now = time();

		if ($row->mode === 'plan') {
			$planLive = $expire > $now + self::PLAN_MARGIN && (float) $row->transfer_enable > $used;

			if ($planLive || !$auto || $balance <= 0) {
				return;
			}

			if (!$this->prepareGroup($row)) {
				$this->cut($userId);
				return;
			}

			$this->setMode($userId, 'balance', $used, true);
			$this->grant($row, $balance, $used);

			$this->notify($userId, 'started', (string) $now, '⚡ اتصال از موجودی',
				"📦 بسته‌ات تمام شد و از این لحظه مصرفت از موجودی شارژ کسر می‌شود.\n"
				. '💰 موجودی: ' . $this->money($balance) . "\n"
				. '📶 با این موجودی حدود ' . $this->gbText($this->headroom($balance)) . ' مصرف داری.', true);

			return;
		}

		// a new subscription, or a periodic data reset of the plan, hands the account back
		if ($this->newSubscription($userId, (int) $row->since) || $this->planReset($userId, $used, (float) $row->last_used)) {
			$this->setMode($userId, 'plan', $used, true);
			$this->notify($userId, 'planback', (string) $now, '📦 بسته‌ی فعال',
				"📦 بسته‌ات فعال است؛ کسر از موجودی متوقف شد.\n💰 موجودی شارژ دست‌نخورده می‌ماند: " . $this->money($balance), true);

			return;
		}

		if ($row->mode === 'balance') {
			if (!$auto) {
				$this->cut($userId);
				$this->setMode($userId, 'plan', $used, true);

				return;
			}

			if ($balance <= 0) {
				$this->cut($userId);
				$this->setMode($userId, 'empty', $used);
				$this->notify($userId, 'empty', (string) $now, '⛔ موجودی تمام شد',
					"⛔ موجودی شارژت تمام شد و اتصال قطع شد.\n💳 با شارژ حساب یا خرید بسته دوباره وصل می‌شوی.", true);

				return;
			}

			if (!$this->prepareGroup($row)) {
				$this->cut($userId);
				$this->setMode($userId, 'empty', $used);
				return;
			}

			$this->grant($row, $balance, $used);
			$this->touchUsed($userId, $used);
			$this->lowBalance($userId, $balance);

			return;
		}

		// empty
		if ($auto && $balance > 0 && $this->prepareGroup($row)) {
			$this->setMode($userId, 'balance', $used);
			$this->grant($row, $balance, $used);
			$this->notify($userId, 'resumed', (string) $now, '✅ اتصال برقرار شد',
				"✅ حسابت شارژ شد و اتصال دوباره برقرار است.\n💰 موجودی: " . $this->money($balance), true);

			return;
		}

		$this->cut($userId);
		$this->touchUsed($userId, $used);
	}

	private function setMode($userId, $mode, $used, $resetSince = false)
	{
		$update = ['mode' => $mode, 'last_used' => (int) $used, 'updated' => time()];

		if ($resetSince) {
			$update['since'] = time();
		}

		DB::table('payg_wallet')->where('userid', $userId)->update($update);
	}

	private function touchUsed($userId, $used)
	{
		DB::table('payg_wallet')->where('userid', $userId)->update(['last_used' => (int) $used]);
	}

	private function prepareGroup($row)
	{
		$allowed = json_decode((string) $this->setting('payg_allowed_groups', '[]'), true);
		$allowed = is_array($allowed) ? array_values(array_unique(array_map('intval', $allowed))) : [];
		$current = (int) $row->server_group;

		if ((int) $row->had_plan === 1) {
			// user had a subscription: allow their current group even if not in payg_allowed_groups
			// (they were using it with their plan, so it should continue in balance mode)
			if ($allowed !== [] && !in_array($current, $allowed, true)) {
				echo date('Y-m-d H:i:s') . " user {$row->userid}: group $current not in payg_allowed_groups but had_plan=1, allowing anyway" . PHP_EOL;
			}
			return true;
		}

		$default = (int) $this->setting('payg_group', 0);
		if ($default <= 0 || ($allowed !== [] && !in_array($default, $allowed, true))) {
			return false;
		}

		if ($current !== $default) {
			DB::table('user')->where('id', $row->userid)->update(['server_group' => $default]);
			$row->server_group = $default;
		}

		return true;
	}

	private function headroom($balance)
	{
		$max = $this->maxPrice();

		return $max > 0 ? max(0.0, $balance) / $max * self::GB : self::FREE_HEADROOM;
	}

	/*
	 * What the balance buys, at the dearest server, on top of what is used.
	 * The expiry is only pushed when it gets close, so the row is not rewritten
	 * every minute.
	 */
	private function grant($row, $balance, $used)
	{
		$target = (int) floor($used + $this->headroom($balance));
		$update = [];

		if ((int) $row->transfer_enable !== $target) {
			$update['transfer_enable'] = $target;
		}

		$iplimit = (int) $this->setting('payg_iplimit', 0);
		if ($iplimit > 0 && (int) $row->iplimit !== $iplimit) {
			$update['iplimit'] = $iplimit;
		}

		if ($update !== []) {
			DB::table('user')->where('id', $row->userid)->update($update);
		}

		$expire = $row->expire_in ? (int) strtotime((string) $row->expire_in) : 0;

		if ($expire < time() + self::KEEP_AHEAD / 2) {
			DB::table('user')->where('id', $row->userid)->update([
				'expire_in' => date('Y-m-d H:i:s', time() + self::KEEP_AHEAD),
			]);
		}
	}

	/* the panel's own quota check disconnects an account whose quota is used up */
	private function cut($userId)
	{
		DB::statement('UPDATE user SET transfer_enable = u + d WHERE id = ? AND transfer_enable > u + d', [$userId]);
	}

	private function newSubscription($userId, $since)
	{
		return DB::table('orders')
			->where('userid', $userId)
			->where('status', 1)
			->where('packagetype', 2)
			->where('pay_date', '>', $since)
			->exists();
	}

	/* the plan's periodic reset zeroed the counters while it still has time left */
	private function planReset($userId, $used, $lastUsed)
	{
		if ($used >= $lastUsed - 1048576) {
			return false;
		}

		return DB::table('orders')
			->where('userid', $userId)
			->where('status', 1)
			->where('packagetype', 2)
			->where('expire', '>', time())
			->exists();
	}

	private function lowBalance($userId, $balance)
	{
		$low = (float) $this->setting('payg_low_balance', 0);

		if ($low <= 0 || $balance >= $low) {
			return;
		}

		// once per charge: the newest credit row names the episode
		$last = (int) DB::table('payg_ledger')->where('userid', $userId)
			->whereIn('kind', ['charge', 'adjust'])->max('id');

		$this->notify($userId, 'low', 'after:' . $last, '⚠️ موجودی کم',
			'⚠️ موجودی شارژت کم شده: ' . $this->money($balance) . "\n"
			. '📶 حدود ' . $this->gbText($this->headroom($balance)) . " دیگر مصرف داری.\n"
			. '💳 برای قطع نشدن، حسابت را شارژ کن.', true);
	}

	// --------------------------------------------------------------- warnings

	/*
	 * The plan is running out: a few days before the end and at a few
	 * percentages of the data. What happens next depends on the wallet, and the
	 * message says so. The unique key on payg_notice sends each one once per
	 * plan period (the period is named by expire_in and the quota).
	 */
	private function warnings()
	{
		$days = $this->numbers($this->setting('payg_warn_days', '3,1'));
		$percents = $this->numbers($this->setting('payg_warn_percent', '80,95'));
		$maxDays = $days === [] ? 0 : max($days);

		if ($maxDays <= 0 && $percents === []) {
			return;
		}

		$query = DB::table('user as usr')
			->leftJoin('payg_wallet as w', 'w.userid', '=', 'usr.id')
			->where('usr.expire_in', '>', date('Y-m-d H:i:s'))
			->where(function ($q) {
				$q->whereNull('w.mode')->orWhere('w.mode', 'plan');
			})
			->where(function ($q) use ($maxDays, $percents) {
				if ($maxDays > 0) {
					$q->orWhere('usr.expire_in', '<', date('Y-m-d H:i:s', time() + $maxDays * 86400));
				}
				if ($percents !== []) {
					$q->orWhereRaw('usr.transfer_enable > 0 AND (usr.u + usr.d) >= usr.transfer_enable * ?', [min($percents) / 100]);
				}
			})
			->select('usr.id', 'usr.transfer_enable', 'usr.u as used_up', 'usr.d as used_down', 'usr.expire_in',
				'usr.notification', 'w.balance', 'w.auto')
			->limit(2000);

		// the highest share reached is the one reported
		$highFirst = $percents;
		rsort($highFirst);

		foreach ($query->get() as $user) {
			$notification = json_decode((string) $user->notification, true);

			// the customer switched plan notices off in their settings
			if (is_array($notification) && isset($notification['dataexpire']) && (int) $notification['dataexpire'] === 0) {
				continue;
			}

			$expire = (int) strtotime((string) $user->expire_in);
			$used = (float) $user->used_up + (float) $user->used_down;
			$quota = (float) $user->transfer_enable;
			$left = $expire - time();
			$period = $user->expire_in . '/' . (int) $quota;

			$reason = null;
			$ref = null;

			foreach ($days as $d) {
				if ($left <= $d * 86400) {
					$reason = '⏳ فقط ' . $this->fa(max(1, (int) ceil($left / 86400))) . ' روز از بسته‌ات مانده (تا ' . Package::jalaliText($expire) . ').';
					$ref = 'd' . $d . ':' . $period;
					break;
				}
			}

			if ($reason === null && $quota > 0) {
				foreach ($highFirst as $p) {
					if ($used >= $quota * $p / 100) {
						$reason = '📦 ' . $this->fa((int) $p) . '٪ حجم بسته‌ات مصرف شده؛ ' . $this->gbText(max(0, $quota - $used)) . ' مانده.';
						$ref = 'p' . $p . ':' . $period;
						break;
					}
				}
			}

			if ($reason === null) {
				continue;
			}

			$balance = (float) ($user->balance ?? 0);
			$auto = $user->auto === null || (int) $user->auto === 1;

			if ($balance > 0 && $auto) {
				$next = "\n⚡ بعد از تمام شدن بسته، اتصالت قطع نمی‌شود و مصرف از موجودی شارژ کسر می‌شود.\n"
					. '💰 موجودی: ' . $this->money($balance);
			} else {
				$next = "\n💳 برای قطع نشدن، بسته را تمدید کن یا حسابت را شارژ کن تا بعد از بسته، مصرف از موجودی کسر شود.";
			}

			$this->notify((int) $user->id, 'warn', $ref, '⏳ بسته رو به اتمام است', $reason . $next, false);
		}
	}

	private function numbers($csv)
	{
		$list = [];

		foreach (preg_split('~[\s,]+~', (string) $csv, -1, PREG_SPLIT_NO_EMPTY) as $part) {
			if (is_numeric($part) && (float) $part > 0) {
				$list[] = (float) $part;
			}
		}

		sort($list);

		return $list;
	}

	// ----------------------------------------------------------------- notify

	/*
	 * One message, three places: the dashboard (payg_notice, read by the
	 * wallet card), Telegram and e-mail. The unique key on payg_notice is the
	 * guard - if the row already exists nothing is sent again.
	 */
	private function notify($userId, $kind, $ref, $title, $text, $always)
	{
		try {
			DB::table('payg_notice')->insert([
				'userid'  => $userId,
				'kind'    => $kind,
				'ref'     => mb_substr((string) $ref, 0, 64),
				'text'    => $text,
				'seen'    => 0,
				'created' => time(),
			]);
		} catch (\Throwable $error) {
			return;
		}

		$user = DB::table('user')->where('id', $userId)->first(['id', 'username', 'email', 'telegram_id']);

		if (!$user) {
			return;
		}

		if ($this->token !== '' && !empty($user->telegram_id)) {
			$this->api('sendMessage', ['chat_id' => $user->telegram_id, 'text' => $title . "\n\n" . $text]);
		}

		$this->mail($user, $title, $text);
	}

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
					'lines'    => array_values(array_filter(explode("\n", $text), 'strlen')),
				], JSON_UNESCAPED_UNICODE),
				'time'       => time(),
			]);
		} catch (\Throwable $error) {
			echo date('Y-m-d H:i:s') . ' mail not queued for user ' . $user->id . ': ' . $error->getMessage() . PHP_EOL;
		}
	}

	private function api($method, array $params)
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

	// ----------------------------------------------------------------- format

	private function fa($text)
	{
		return strtr((string) $text, ['0' => '۰', '1' => '۱', '2' => '۲', '3' => '۳', '4' => '۴',
			'5' => '۵', '6' => '۶', '7' => '۷', '8' => '۸', '9' => '۹', ',' => '٬', '.' => '٫']);
	}

	/* amounts are stored in rial; customers think in toman */
	private function money($rial)
	{
		if ($this->setting('payg_show_toman', '1') == 1) {
			return $this->fa(number_format(round((float) $rial / 10))) . ' تومان';
		}

		return $this->fa(number_format(round((float) $rial))) . ' ریال';
	}

	private function gbText($bytes)
	{
		$gb = (float) $bytes / self::GB;

		if ($gb >= 1024) {
			return $this->fa('∞') . ' گیگ';
		}

		return $gb < 1
			? $this->fa((int) round($gb * 1024)) . ' مگ'
			: $this->fa(rtrim(rtrim(number_format($gb, 1, '.', ''), '0'), '.')) . ' گیگ';
	}
}
