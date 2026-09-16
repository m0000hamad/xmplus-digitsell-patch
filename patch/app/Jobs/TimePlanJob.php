<?php
namespace App\Jobs;

use App\Http\Models\Package;
use Illuminate\Database\Capsule\Manager as DB;

/**
 * Grants the days bought through a time plan.
 *
 * A time plan is sold as an ordinary topup package, so the panel's encoded
 * checkout marks the order paid and adds its (zero) gigabytes. Nothing in that
 * pipeline knows about days, and none of it can be edited, so this job picks up
 * paid orders whose package carries the time-plan marker and extends the
 * subscription itself. `timeplan_log` makes that exactly-once.
 */
class TimePlanJob
{
	/** minted rows left unpaid for this long stop being offered */
	const MINTED_TTL = 86400;

	public function dispatch()
	{
		$this->ensureTables();

		$granted = 0;

		foreach ($this->pendingOrders() as $order) {
			if ($this->grant($order)) {
				$granted++;
			}
		}

		$this->retireStaleMinted();

		return $granted;
	}

	private function ensureTables()
	{
		DB::statement(
			'CREATE TABLE IF NOT EXISTS timeplan_log (
				id BIGINT(20) NOT NULL AUTO_INCREMENT,
				orderid BIGINT(20) NOT NULL,
				userid INT(11) NOT NULL,
				packageid BIGINT(20) NOT NULL,
				days INT(11) NOT NULL,
				restored TINYINT(1) NOT NULL DEFAULT 0,
				expire_before DATETIME NULL,
				expire_after DATETIME NULL,
				granted_at BIGINT(20) NOT NULL,
				PRIMARY KEY (id),
				UNIQUE KEY orderid (orderid),
				KEY userid (userid)
			) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4');

		DB::statement(
			'CREATE TABLE IF NOT EXISTS timeplan_snapshot (
				userid INT(11) NOT NULL,
				transfer_enable BIGINT(20) NOT NULL DEFAULT 0,
				u BIGINT(20) NOT NULL DEFAULT 0,
				d BIGINT(20) NOT NULL DEFAULT 0,
				used BIGINT(20) NOT NULL DEFAULT 0,
				total_data_used BIGINT(20) NOT NULL DEFAULT 0,
				expire_in DATETIME NULL,
				taken_at BIGINT(20) NOT NULL,
				PRIMARY KEY (userid)
			) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4');
	}

	/*
	 * Paid orders on a time-plan package that have not been granted yet. No
	 * date floor is needed: before this feature shipped no order could point at
	 * such a package, so there is no history to grant retroactively.
	 */
	private function pendingOrders()
	{
		return DB::table('orders')
			->join('package', 'package.id', '=', 'orders.packageid')
			->leftJoin('timeplan_log', 'timeplan_log.orderid', '=', 'orders.id')
			->where('orders.status', 1)
			->whereNotNull('orders.pay_date')
			->where('package.order_note', 'like', '%' . Package::TIME_MARKER . '%')
			->whereNull('timeplan_log.id')
			->select(
				'orders.id as orderid',
				'orders.userid',
				'orders.packageid',
				'package.order_note'
			)
			->orderBy('orders.id', 'asc')
			->limit(200)
			->get();
	}

	private function grant($order)
	{
		$meta = Package::decodeTimeMeta($order->order_note);
		$days = isset($meta['days']) ? (int) $meta['days'] : 0;

		if ($days < 1) {
			return false;
		}

		$user = DB::table('user')->where('id', $order->userid)->first();

		if (!$user) {
			return false;
		}

		// claim the order first: a duplicate key here means another run took it
		try {
			DB::table('timeplan_log')->insert([
				'orderid'       => $order->orderid,
				'userid'        => $order->userid,
				'packageid'     => $order->packageid,
				'days'          => $days,
				'restored'      => 0,
				'expire_before' => $user->expire_in,
				'expire_after'  => null,
				'granted_at'    => time(),
			]);
		} catch (\Throwable $error) {
			return false;
		}

		$expired = strtotime($user->expire_in) < time();

		// days bought after expiry start from now, not from a date in the past
		DB::statement(
			'UPDATE user SET expire_in = DATE_ADD(GREATEST(expire_in, NOW()), INTERVAL ? DAY) WHERE id = ?',
			[$days, $order->userid]
		);

		$restored = $expired ? $this->restoreTraffic($user) : false;

		$after = DB::table('user')->where('id', $order->userid)->value('expire_in');

		DB::table('timeplan_log')->where('orderid', $order->orderid)->update([
			'restored'     => $restored ? 1 : 0,
			'expire_after' => $after,
		]);

		echo date('Y-m-d H:i:s') . sprintf(
			' order %d: +%d day(s) for user %d, %s -> %s%s',
			$order->orderid, $days, $order->userid, $user->expire_in, $after,
			$restored ? ' (traffic restored)' : ''
		) . PHP_EOL;

		return true;
	}

	/*
	 * Buying time during the grace window must not hand back an account with
	 * zero data: UserJob wipes the traffic at expiry and saves what was left
	 * first. Only a snapshot taken at the very expiry being extended is used,
	 * so an old one can never resurrect stale traffic.
	 */
	private function restoreTraffic($user)
	{
		$snapshot = DB::table('timeplan_snapshot')->where('userid', $user->id)->first();

		if (!$snapshot || $snapshot->expire_in !== $user->expire_in) {
			return false;
		}

		if ((int) $user->transfer_enable > 0) {
			return false;
		}

		DB::table('user')->where('id', $user->id)->update([
			'transfer_enable'  => $snapshot->transfer_enable,
			'u'                => $snapshot->u,
			'd'                => $snapshot->d,
			'used'             => $snapshot->used,
			'total_data_used'  => $snapshot->total_data_used,
			'data_expire_cron' => 0,
		]);

		DB::table('timeplan_snapshot')->where('userid', $user->id)->delete();

		return true;
	}

	/*
	 * A per-day plan mints one package row per day count. Rows nobody paid for
	 * are switched off after a day so the admin's plan list stays readable;
	 * they are switched back on if the same day count is picked again.
	 */
	private function retireStaleMinted()
	{
		$rows = DB::table('package')
			->where('type', 1)
			->where('status', 1)
			->where('order_note', 'like', '%"mode":"minted"%')
			->select('id', 'order_note')
			->get();

		foreach ($rows as $row) {
			$meta = Package::decodeTimeMeta($row->order_note);
			$created = isset($meta['created']) ? (int) $meta['created'] : 0;

			if ($created === 0 || time() - $created < self::MINTED_TTL) {
				continue;
			}

			$sold = DB::table('orders')->where('packageid', $row->id)->exists();

			if (!$sold) {
				DB::table('package')->where('id', $row->id)->update(['status' => 0]);
			}
		}
	}
}
