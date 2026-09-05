<?php
namespace App\Jobs;

use Illuminate\Database\Capsule\Manager as DB;

/*
 * Rolls the raw trafficlog rows up into the traffic_daily summary table.
 * trafficlog is pruned every day by LogsJob, so this has to run before the
 * delete happens or the history is gone for good.
 *
 * The statement is idempotent: for every (user, day, server) still present in
 * trafficlog it recomputes the sums and overwrites the stored row, so running
 * it twice on the same data changes nothing.
 */
class TrafficStatsJob
{
	public function dispatch()
	{
		ini_set('memory_limit', '-1');

		$this->createTable();

		DB::connection('default')->statement("
			INSERT INTO `traffic_daily` (`userid`,`day`,`serverid`,`servername`,`u`,`d`,`total`)
			SELECT `userid`,
			       DATE(FROM_UNIXTIME(`datetime`)) AS `day`,
			       `serverid`,
			       SUBSTRING(MAX(`servername`),1,191),
			       SUM(`u`), SUM(`d`), SUM(`total`)
			FROM `trafficlog`
			GROUP BY `userid`, `day`, `serverid`
			ON DUPLICATE KEY UPDATE
			  `servername` = VALUES(`servername`),
			  `u` = VALUES(`u`),
			  `d` = VALUES(`d`),
			  `total` = VALUES(`total`)
		");

		// keep two years of history, that is enough for the yearly chart
		DB::connection('default')->table('traffic_daily')
			->where('day', '<', date('Y-m-d', strtotime('-730 days')))
			->delete();
	}

	public function createTable()
	{
		DB::connection('default')->statement("
			CREATE TABLE IF NOT EXISTS `traffic_daily` (
			  `id` BIGINT(20) NOT NULL AUTO_INCREMENT,
			  `userid` INT(11) NOT NULL,
			  `day` DATE NOT NULL,
			  `serverid` INT(11) NOT NULL DEFAULT 0,
			  `servername` VARCHAR(191) NOT NULL DEFAULT '',
			  `u` BIGINT(20) NOT NULL DEFAULT 0,
			  `d` BIGINT(20) NOT NULL DEFAULT 0,
			  `total` BIGINT(20) NOT NULL DEFAULT 0,
			  PRIMARY KEY (`id`),
			  UNIQUE KEY `uniq_user_day_server` (`userid`,`day`,`serverid`),
			  KEY `idx_user_day` (`userid`,`day`),
			  KEY `idx_day` (`day`)
			) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
		");
	}
}
