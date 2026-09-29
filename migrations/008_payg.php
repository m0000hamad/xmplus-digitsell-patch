<?php
/**
 * Pay-as-you-go wallet and the separate commission wallet.
 *
 *   payg_wallet       one row per customer who ever charged: balance, totals,
 *                     and the mode the billing job has them in
 *   payg_ledger       every credit and debit; usage is one row per user, server
 *                     and day, grown in place, so the table stays small
 *   payg_rate         price per GB for a server; a server without a row uses
 *                     the `payg_default_price` setting
 *   payg_notice       messages already sent (plan ending, balance low, ...);
 *                     the unique key is what stops a message going out twice
 *   commission_wallet referral commission, spendable on subscription plans only
 *   commission_wallet_log / commission_hold
 *                     its ledger, and the amounts moved into user.money just
 *                     before a subscription checkout (returned if unused)
 *
 * PaygJob creates the same tables when they are missing, so an install that
 * skipped this migration still works. Everything starts switched off.
 */
return static function (PDO $db): void {
    $db->exec("
        CREATE TABLE IF NOT EXISTS `payg_wallet` (
          `userid` int(11) NOT NULL,
          `balance` decimal(16,2) NOT NULL DEFAULT '0.00',
          `charged` decimal(16,2) NOT NULL DEFAULT '0.00',
          `bonus` decimal(16,2) NOT NULL DEFAULT '0.00',
          `adjusted` decimal(16,2) NOT NULL DEFAULT '0.00',
          `spent` decimal(16,2) NOT NULL DEFAULT '0.00',
          `mode` varchar(8) NOT NULL DEFAULT 'plan',
          `since` bigint(20) NOT NULL DEFAULT '0',
          `auto` tinyint(1) NOT NULL DEFAULT '1',
          `last_used` bigint(20) NOT NULL DEFAULT '0',
          `updated` bigint(20) NOT NULL DEFAULT '0',
          PRIMARY KEY (`userid`),
          KEY `idx_mode` (`mode`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ");

    $db->exec("
        CREATE TABLE IF NOT EXISTS `payg_ledger` (
          `id` bigint(20) NOT NULL AUTO_INCREMENT,
          `userid` int(11) NOT NULL,
          `kind` varchar(12) NOT NULL,
          `ref` varchar(64) DEFAULT NULL,
          `amount` decimal(16,2) NOT NULL DEFAULT '0.00',
          `balance_after` decimal(16,2) NOT NULL DEFAULT '0.00',
          `serverid` int(11) NOT NULL DEFAULT '0',
          `bytes` bigint(20) NOT NULL DEFAULT '0',
          `free_bytes` bigint(20) NOT NULL DEFAULT '0',
          `rate` decimal(16,2) NOT NULL DEFAULT '0.00',
          `note` varchar(255) NOT NULL DEFAULT '',
          `created` bigint(20) NOT NULL,
          `updated` bigint(20) NOT NULL,
          PRIMARY KEY (`id`),
          UNIQUE KEY `uniq_ref` (`ref`),
          KEY `idx_user` (`userid`,`id`),
          KEY `idx_kind_time` (`kind`,`created`),
          KEY `idx_server` (`serverid`,`kind`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ");

    $db->exec("
        CREATE TABLE IF NOT EXISTS `payg_rate` (
          `serverid` int(11) NOT NULL,
          `price` decimal(16,2) NOT NULL DEFAULT '0.00',
          `updated` bigint(20) NOT NULL DEFAULT '0',
          PRIMARY KEY (`serverid`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ");

    $db->exec("
        CREATE TABLE IF NOT EXISTS `payg_notice` (
          `id` bigint(20) NOT NULL AUTO_INCREMENT,
          `userid` int(11) NOT NULL,
          `kind` varchar(16) NOT NULL,
          `ref` varchar(64) NOT NULL,
          `text` text,
          `seen` tinyint(1) NOT NULL DEFAULT '0',
          `created` bigint(20) NOT NULL,
          PRIMARY KEY (`id`),
          UNIQUE KEY `uniq_notice` (`userid`,`kind`,`ref`),
          KEY `idx_user_seen` (`userid`,`seen`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ");

    $db->exec("
        CREATE TABLE IF NOT EXISTS `commission_wallet` (
          `userid` int(11) NOT NULL,
          `balance` decimal(16,2) NOT NULL DEFAULT '0.00',
          `earned` decimal(16,2) NOT NULL DEFAULT '0.00',
          `spent` decimal(16,2) NOT NULL DEFAULT '0.00',
          `updated` bigint(20) NOT NULL DEFAULT '0',
          PRIMARY KEY (`userid`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ");

    $db->exec("
        CREATE TABLE IF NOT EXISTS `commission_wallet_log` (
          `id` bigint(20) NOT NULL AUTO_INCREMENT,
          `userid` int(11) NOT NULL,
          `kind` varchar(12) NOT NULL,
          `ref` varchar(64) DEFAULT NULL,
          `amount` decimal(16,2) NOT NULL DEFAULT '0.00',
          `balance_after` decimal(16,2) NOT NULL DEFAULT '0.00',
          `note` varchar(255) NOT NULL DEFAULT '',
          `created` bigint(20) NOT NULL,
          PRIMARY KEY (`id`),
          UNIQUE KEY `uniq_ref` (`ref`),
          KEY `idx_user` (`userid`,`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ");

    $db->exec("
        CREATE TABLE IF NOT EXISTS `commission_hold` (
          `id` bigint(20) NOT NULL AUTO_INCREMENT,
          `userid` int(11) NOT NULL,
          `packageid` int(11) NOT NULL DEFAULT '0',
          `amount` decimal(16,2) NOT NULL DEFAULT '0.00',
          `returned` decimal(16,2) NOT NULL DEFAULT '0.00',
          `resolved` tinyint(1) NOT NULL DEFAULT '0',
          `created` bigint(20) NOT NULL,
          `resolved_at` bigint(20) NOT NULL DEFAULT '0',
          PRIMARY KEY (`id`),
          KEY `idx_open` (`resolved`,`created`),
          KEY `idx_user` (`userid`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ");

    // amounts are in the panel's currency (rial): 2,000,000 = 200 thousand toman
    $defaults = [
        'payg_enabled'         => '0',
        'payg_min_charge'      => '2000000',
        'payg_charge_step'     => '100000',
        'payg_default_price'   => '0',
        'payg_low_balance'     => '500000',
        'payg_bonus_tiers'     => '[]',
        'payg_outage_free'     => '1',
        'payg_warn_percent'    => '80,95',
        'payg_warn_days'       => '3,1',
        'commission_wallet_enabled' => '0',
    ];

    $exists = $db->prepare('SELECT 1 FROM settings WHERE name = ? LIMIT 1');
    $insert = $db->prepare('INSERT INTO settings (name, value) VALUES (?, ?)');

    foreach ($defaults as $name => $value) {
        $exists->execute([$name]);
        if ($exists->fetch() === false) {
            $insert->execute([$name, $value]);
        }
    }
};
