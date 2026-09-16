<?php
/**
 * Time plans - selling extra days.
 *
 * `timeplan_log` makes granting exactly-once: one row per paid order, keyed by
 * the order id. `timeplan_snapshot` holds the traffic a user had left when
 * their plan expired, so buying days during the grace window right afterwards
 * does not hand back an empty account.
 *
 * TimePlanJob creates both tables itself if they are missing, so an install
 * that skipped this migration still works.
 */
return static function (PDO $db): void {
    $db->exec("
        CREATE TABLE IF NOT EXISTS `timeplan_log` (
          `id` bigint(20) NOT NULL AUTO_INCREMENT,
          `orderid` bigint(20) NOT NULL,
          `userid` int(11) NOT NULL,
          `packageid` bigint(20) NOT NULL,
          `days` int(11) NOT NULL,
          `restored` tinyint(1) NOT NULL DEFAULT '0',
          `expire_before` datetime DEFAULT NULL,
          `expire_after` datetime DEFAULT NULL,
          `granted_at` bigint(20) NOT NULL,
          PRIMARY KEY (`id`),
          UNIQUE KEY `orderid` (`orderid`),
          KEY `userid` (`userid`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ");

    $db->exec("
        CREATE TABLE IF NOT EXISTS `timeplan_snapshot` (
          `userid` int(11) NOT NULL,
          `transfer_enable` bigint(20) NOT NULL DEFAULT '0',
          `u` bigint(20) NOT NULL DEFAULT '0',
          `d` bigint(20) NOT NULL DEFAULT '0',
          `used` bigint(20) NOT NULL DEFAULT '0',
          `total_data_used` bigint(20) NOT NULL DEFAULT '0',
          `expire_in` datetime DEFAULT NULL,
          `taken_at` bigint(20) NOT NULL,
          PRIMARY KEY (`userid`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ");
};
