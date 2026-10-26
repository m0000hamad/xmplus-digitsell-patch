<?php
/**
 * Plan reservation - buy a subscription now, let it start later.
 *
 * The panel's order pipeline is ionCube encoded: paying for a subscription
 * package applies it at once and none of that code can be edited. A reserved
 * plan is therefore sold as an ordinary traffic top-up (type 1, bandwidth 0)
 * whose `order_note` carries a marker - the same trick the time plans use - so
 * checkout, coupon, gateway, invoice and order history stay the panel's own.
 * The subscription itself is started later by app/Jobs/ReserveJob.php, once the
 * current plan has ended (or the chosen date has come).
 *
 * One row per reservation:
 *
 *   status 0  a check-out was prepared, nobody has paid yet
 *   status 1  paid, waiting for the current plan to end / the chosen date
 *   status 2  applied - the subscription has been started from it
 *   status 3  cancelled (the buyer was refunded into their account credit)
 *
 * `plan_reserve.packageid` is the minted top-up row the order points at, and
 * `orderid` links the paid order once ReserveJob finds it. The plan's numbers
 * are snapshotted so a reservation still works if the plan is later edited or
 * switched off.
 *
 * ReserveJob creates the table itself if the migration did not run, so an
 * install that skipped it still works.
 */
return static function (PDO $db): void {
    $db->exec("
        CREATE TABLE IF NOT EXISTS `plan_reserve` (
          `id` bigint(20) NOT NULL AUTO_INCREMENT,
          `userid` int(11) NOT NULL,
          `orderid` bigint(20) DEFAULT NULL,
          `packageid` bigint(20) NOT NULL,
          `planid` bigint(20) NOT NULL,
          `cycle` varchar(16) NOT NULL DEFAULT 'month',
          `days` int(11) NOT NULL DEFAULT 30,
          `mode` varchar(8) NOT NULL DEFAULT 'after',
          `activate_at` bigint(20) NOT NULL DEFAULT 0,
          `amount` decimal(12,2) NOT NULL DEFAULT '0.00',
          `name` varchar(255) NOT NULL DEFAULT '',
          `bandwidth` int(11) NOT NULL DEFAULT 0,
          `iplimit` int(11) NOT NULL DEFAULT 0,
          `speedlimit` int(11) NOT NULL DEFAULT 0,
          `server_group` int(11) NOT NULL DEFAULT 0,
          `status` tinyint(1) NOT NULL DEFAULT '0',
          `created_at` bigint(20) NOT NULL DEFAULT 0,
          `paid_at` bigint(20) NOT NULL DEFAULT 0,
          `activated_at` bigint(20) NOT NULL DEFAULT 0,
          `cancelled_at` bigint(20) NOT NULL DEFAULT 0,
          `expire_before` datetime DEFAULT NULL,
          `expire_after` datetime DEFAULT NULL,
          PRIMARY KEY (`id`),
          KEY `userid` (`userid`),
          KEY `orderid` (`orderid`),
          KEY `status` (`status`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ");

    $defaults = [
        'reserve_enabled'  => '1',
        'reserve_max_days' => '365',
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
