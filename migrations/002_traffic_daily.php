<?php
/**
 * Daily traffic roll-up.
 *
 * `trafficlog` is emptied every night by LogsJob, so the usage chart had no
 * history to draw. TrafficStatsJob folds each day into this table first.
 */
return static function (PDO $db): void {
    $db->exec("
        CREATE TABLE IF NOT EXISTS `traffic_daily` (
          `id` bigint(20) NOT NULL AUTO_INCREMENT,
          `userid` int(11) NOT NULL,
          `day` date NOT NULL,
          `serverid` int(11) NOT NULL DEFAULT '0',
          `servername` varchar(191) NOT NULL DEFAULT '',
          `u` bigint(20) NOT NULL DEFAULT '0',
          `d` bigint(20) NOT NULL DEFAULT '0',
          `total` bigint(20) NOT NULL DEFAULT '0',
          PRIMARY KEY (`id`),
          UNIQUE KEY `uniq_user_day_server` (`userid`,`day`,`serverid`),
          KEY `idx_user_day` (`userid`,`day`),
          KEY `idx_day` (`day`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ");
};
