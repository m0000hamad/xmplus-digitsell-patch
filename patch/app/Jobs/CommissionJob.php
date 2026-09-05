<?php
namespace App\Jobs;

use App\Http\Models\User;
use App\Provider\ConfigProvider;
use Illuminate\Database\Capsule\Manager as DB;

/*
 * Pays referral commission straight into the referrer's wallet.
 *
 * Before this job existed the commission only piled up in user.payout_balance and
 * somebody had to approve a withdrawal by hand. Now every new row in `affiliate`
 * is moved into user.money within a minute and written to commission_log, which
 * is what the dashboard popup and the commission history read.
 *
 * The money is MOVED, not added: payout_balance already holds it, so crediting
 * the wallet without deducting there would pay the same commission twice.
 */
class CommissionJob
{
	/* settings key holding the highest affiliate row already paid out */
	const WATERMARK = 'commission_last_affiliate_id';

	public function dispatch()
	{
		ini_set('memory_limit', '-1');

		$this->createTable();

		$config = new ConfigProvider;
		$last = (int) $config->get(self::WATERMARK);

		$rows = DB::connection('default')->table('affiliate')
			->where('id', '>', $last)
			->orderBy('id')
			->limit(500)
			->get();

		if (count($rows) === 0) {
			return 0;
		}

		$paid = 0;
		$highest = $last;

		foreach ($rows as $row) {
			$highest = max($highest, (int) $row->id);

			if ($this->credit($row)) {
				$paid++;
			}
		}

		$config->set(self::WATERMARK, $highest);

		return $paid;
	}

	/*
	 * Move one commission row into the referrer's wallet. Returns false when the
	 * row cannot or should not be paid (missing user, zero amount, already done).
	 */
	/*
	 * One commission row. Where it lands depends on the referrer:
	 *
	 *   eligible for cash  -> left in payout_balance, ready to be withdrawn
	 *   not eligible       -> moved into money, spendable inside the panel only
	 *
	 * Either way it is written to commission_log so the dashboard can show it.
	 */
	private function credit($row)
	{
		$amount = (float) $row->ref_get;
		$userid = (int) $row->ref_by;

		if ($amount <= 0 || $userid <= 0) {
			return false;
		}

		$already = DB::connection('default')->table('commission_log')
			->where('affiliate_id', (int) $row->id)->exists();

		if ($already) {
			return false;
		}

		$user = User::find($userid);
		if (!$user) {
			return false;
		}

		$cashEligible = $user->planIsActive() && $user->hasContinuousSubscription();

		$connection = DB::connection('default');
		$connection->beginTransaction();

		try {
			if ($cashEligible) {
				// the checkout already put it in payout_balance, leave it there
				$destination = 'payout';
				$balance = (float) $user->payout_balance;
			} else {
				$destination = 'wallet';
				$balance = (float) $user->money + $amount;
				$pending = (float) $user->payout_balance - $amount;

				$connection->table('user')->where('id', $userid)->update([
					'money'          => $balance,
					'payout_balance' => $pending > 0 ? $pending : 0,
				]);
			}

			$connection->table('commission_log')->insert([
				'userid'         => $userid,
				'affiliate_id'   => (int) $row->id,
				'amount'         => $amount,
				'balance_after'  => $balance,
				'buyer_username' => (string) $row->username,
				'package_id'     => $row->package_id,
				'source'         => 'affiliate',
				'destination'    => $destination,
				'seen'           => 0,
				'datetime'       => time(),
			]);

			$connection->commit();
		} catch (\Throwable $e) {
			$connection->rollBack();
			return false;
		}

		return true;
	}

	/*
	 * One-off transfer of commission that had already piled up before the job
	 * was introduced. $filter narrows who gets it; $dryRun only reports.
	 */
	public function migrate($activeOnly = true, $skipStaff = true, $dryRun = true)
	{
		$this->createTable();

		$query = DB::connection('default')->table('user')->where('payout_balance', '>', 0);

		if ($activeOnly) {
			$query->where('expire_in', '>', date('Y-m-d H:i:s'));
		}
		if ($skipStaff) {
			$query->where('role', 0);
		}

		$users = $query->orderBy('id')->get();

		$report = ['users' => 0, 'total' => 0.0, 'rows' => []];

		foreach ($users as $user) {
			$amount = (float) $user->payout_balance;
			if ($amount <= 0) {
				continue;
			}

			$report['users']++;
			$report['total'] += $amount;
			$report['rows'][] = [
				'id'       => (int) $user->id,
				'username' => (string) $user->username,
				'amount'   => $amount,
			];

			if ($dryRun) {
				continue;
			}

			$connection = DB::connection('default');
			$connection->beginTransaction();

			try {
				$balance = (float) $user->money + $amount;

				$connection->table('user')->where('id', $user->id)->update([
					'money'          => $balance,
					'payout_balance' => 0,
				]);

				$connection->table('commission_log')->insert([
					'userid'         => (int) $user->id,
					'affiliate_id'   => null,
					'amount'         => $amount,
					'balance_after'  => $balance,
					'buyer_username' => '',
					'package_id'     => null,
					'source'         => 'migration',
					'seen'           => 0,
					'datetime'       => time(),
				]);

				$connection->commit();
			} catch (\Throwable $e) {
				$connection->rollBack();
			}
		}

		return $report;
	}

	public function createTable()
	{
		DB::connection('default')->statement("
			CREATE TABLE IF NOT EXISTS `commission_log` (
			  `id` BIGINT(20) NOT NULL AUTO_INCREMENT,
			  `userid` BIGINT(20) NOT NULL,
			  `affiliate_id` BIGINT(20) DEFAULT NULL,
			  `amount` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
			  `balance_after` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
			  `buyer_username` VARCHAR(300) NOT NULL DEFAULT '',
			  `package_id` INT(11) DEFAULT NULL,
			  `source` VARCHAR(20) NOT NULL DEFAULT 'affiliate',
			  `seen` TINYINT(1) NOT NULL DEFAULT 0,
			  `datetime` BIGINT(20) NOT NULL,
			  PRIMARY KEY (`id`),
			  UNIQUE KEY `uniq_affiliate` (`affiliate_id`),
			  KEY `idx_user_time` (`userid`,`datetime`),
			  KEY `idx_user_seen` (`userid`,`seen`)
			) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
		");
	}
}
