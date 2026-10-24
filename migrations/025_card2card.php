<?php
/**
 * Card-to-card payments (app/Patch/Card2Card.php).
 *
 * `c2c_card`   the receiving cards, in rotation order, each with its own cap
 *              (amount and/or count, per day / per month / in total). The first
 *              card that still has room is the one the checkout shows.
 * `c2c_request` one row per order: what the customer says they transferred -
 *              last four digits, payer name, date/time, reference - plus the
 *              decision, the Telegram message it was announced in, and the
 *              one-time tokens the Telegram approve/reject buttons carry.
 * `c2c_notice` the confirmation the customer sees in the panel, the same idea
 *              as reserve_notice: the unique key on `ref` makes the banner,
 *              the Telegram message and the e-mail go out exactly once.
 *
 * Settings are inserted only when missing, so re-running the migration can
 * never overwrite what the admin configured. Card-to-card ships switched off.
 */
return static function (PDO $db): void {
    $db->exec("
        CREATE TABLE IF NOT EXISTS `c2c_card` (
          `id` int(11) NOT NULL AUTO_INCREMENT,
          `number` varchar(32) NOT NULL DEFAULT '',
          `holder` varchar(120) NOT NULL DEFAULT '',
          `bank` varchar(120) NOT NULL DEFAULT '',
          `limit_amount` bigint(20) NOT NULL DEFAULT 0,
          `limit_count` int(11) NOT NULL DEFAULT 0,
          `limit_period` varchar(10) NOT NULL DEFAULT 'day',
          `enabled` tinyint(1) NOT NULL DEFAULT 1,
          `sort` int(11) NOT NULL DEFAULT 0,
          `note` varchar(255) NOT NULL DEFAULT '',
          `created` bigint(20) NOT NULL DEFAULT 0,
          `updated` bigint(20) NOT NULL DEFAULT 0,
          PRIMARY KEY (`id`),
          KEY `enabled_sort` (`enabled`, `sort`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ");

    $db->exec("
        CREATE TABLE IF NOT EXISTS `c2c_request` (
          `id` bigint(20) NOT NULL AUTO_INCREMENT,
          `orderid` bigint(20) NOT NULL,
          `userid` int(11) NOT NULL,
          `cardid` int(11) NOT NULL DEFAULT 0,
          `amount` decimal(14,2) NOT NULL DEFAULT '0.00',
          `plan_name` varchar(190) NOT NULL DEFAULT '',
          `plan_cycle` varchar(20) NOT NULL DEFAULT '',
          `plan_days` int(11) NOT NULL DEFAULT 0,
          `last4` char(4) NOT NULL DEFAULT '',
          `payer` varchar(120) NOT NULL DEFAULT '',
          `paid_at` varchar(80) NOT NULL DEFAULT '',
          `ref` varchar(80) NOT NULL DEFAULT '',
          `status` tinyint(4) NOT NULL DEFAULT 0,
          `note` varchar(255) NOT NULL DEFAULT '',
          `token` char(64) NOT NULL DEFAULT '',
          `token_expire` bigint(20) NOT NULL DEFAULT 0,
          `created` bigint(20) NOT NULL DEFAULT 0,
          `updated` bigint(20) NOT NULL DEFAULT 0,
          `decided_at` bigint(20) NOT NULL DEFAULT 0,
          `decided_by` varchar(40) NOT NULL DEFAULT '',
          `tg_sent` tinyint(1) NOT NULL DEFAULT 0,
          `tg_chat` varchar(64) NOT NULL DEFAULT '',
          `tg_message` bigint(20) NOT NULL DEFAULT 0,
          `tg_closed` tinyint(1) NOT NULL DEFAULT 0,
          `user_sent` tinyint(1) NOT NULL DEFAULT 0,
          PRIMARY KEY (`id`),
          UNIQUE KEY `orderid` (`orderid`),
          KEY `status_created` (`status`, `created`),
          KEY `userid` (`userid`),
          KEY `cardid` (`cardid`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ");

    $db->exec("
        CREATE TABLE IF NOT EXISTS `c2c_notice` (
          `id` bigint(20) NOT NULL AUTO_INCREMENT,
          `userid` int(11) NOT NULL,
          `kind` varchar(16) NOT NULL DEFAULT 'approved',
          `ref` varchar(64) NOT NULL,
          `orderid` bigint(20) NOT NULL DEFAULT 0,
          `order_no` varchar(64) NOT NULL DEFAULT '',
          `name` varchar(190) NOT NULL DEFAULT '',
          `amount` decimal(14,2) NOT NULL DEFAULT '0.00',
          `reason` varchar(255) NOT NULL DEFAULT '',
          `seen` tinyint(1) NOT NULL DEFAULT 0,
          `created` bigint(20) NOT NULL DEFAULT 0,
          PRIMARY KEY (`id`),
          UNIQUE KEY `ref` (`ref`),
          KEY `user_seen` (`userid`, `seen`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ");

    $defaults = [
        'c2c_enabled'       => '0',
        'c2c_telegram_chat' => '',
        'c2c_note'          => "مبلغ را دقیقاً به شماره کارت بالا واریز کنید.\nپس از واریز، اطلاعات پرداخت را همین‌جا ثبت کنید تا پس از بررسی، بسته به‌صورت خودکار فعال شود.",
        'c2c_reject_hours'  => '72',
        'c2c_hold_hours'    => '48',
        'c2c_grant_mode'    => 'auto',
        'c2c_site_url'      => '',
    ];

    foreach ($defaults as $name => $value) {
        try {
            $exists = $db->prepare('SELECT 1 FROM `settings` WHERE `name` = ? LIMIT 1');
            $exists->execute([$name]);

            if ($exists->fetch() === false) {
                $db->prepare('INSERT INTO `settings` (`name`, `value`) VALUES (?, ?)')
                    ->execute([$name, $value]);
            }
        } catch (Throwable $error) {
            // no settings table on a fresh install: the code defaults apply
        }
    }
};
