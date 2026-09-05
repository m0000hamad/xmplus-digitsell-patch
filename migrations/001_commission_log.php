<?php
/**
 * The ledger every automatic commission payout writes to.
 *
 * affiliate_id is unique on purpose: it is the second guard against paying the
 * same referral twice, after the watermark setting.
 */
return static function (PDO $db): void {
    $db->exec("
        CREATE TABLE IF NOT EXISTS `commission_log` (
          `id` bigint(20) NOT NULL AUTO_INCREMENT,
          `userid` bigint(20) NOT NULL,
          `affiliate_id` bigint(20) DEFAULT NULL,
          `amount` decimal(12,2) NOT NULL DEFAULT '0.00',
          `balance_after` decimal(12,2) NOT NULL DEFAULT '0.00',
          `buyer_username` varchar(300) NOT NULL DEFAULT '',
          `package_id` int(11) DEFAULT NULL,
          `source` varchar(20) NOT NULL DEFAULT 'affiliate',
          `destination` varchar(10) NOT NULL DEFAULT 'wallet',
          `seen` tinyint(1) NOT NULL DEFAULT '0',
          `datetime` bigint(20) NOT NULL,
          PRIMARY KEY (`id`),
          UNIQUE KEY `uniq_affiliate` (`affiliate_id`),
          KEY `idx_user_time` (`userid`,`datetime`),
          KEY `idx_user_seen` (`userid`,`seen`),
          KEY `idx_user_dest` (`userid`,`destination`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ");

    // installs made before option B shipped predate the destination column
    if ($db->query("SHOW COLUMNS FROM `commission_log` LIKE 'destination'")->fetch() === false) {
        $db->exec("ALTER TABLE `commission_log`
                   ADD COLUMN `destination` varchar(10) NOT NULL DEFAULT 'wallet' AFTER `source`,
                   ADD KEY `idx_user_dest` (`userid`,`destination`)");
    }
};
