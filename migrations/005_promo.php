<?php
/**
 * Promotions on subscription plans.
 *
 * `promo_log` makes each promoted purchase exactly-once: one row per paid
 * order, keyed by the order id, holding the prize that was drawn for it.
 * The promotions themselves live in the `promo_plans` settings row, written by
 * the plan form (app/Patch/Promo.php).
 *
 * PromoJob creates the table itself if it is missing, so an install that
 * skipped this migration still works.
 */
return static function (PDO $db): void {
    $db->exec("
        CREATE TABLE IF NOT EXISTS `promo_log` (
          `id` bigint(20) NOT NULL AUTO_INCREMENT,
          `orderid` bigint(20) NOT NULL,
          `userid` int(11) NOT NULL,
          `packageid` bigint(20) NOT NULL,
          `kind` varchar(16) NOT NULL DEFAULT '',
          `percent` int(11) NOT NULL DEFAULT '0',
          `prize_kind` varchar(8) DEFAULT NULL,
          `prize_amount` int(11) NOT NULL DEFAULT '0',
          `applied` tinyint(1) NOT NULL DEFAULT '0',
          `expire_before` datetime DEFAULT NULL,
          `expire_after` datetime DEFAULT NULL,
          `created_at` bigint(20) NOT NULL,
          PRIMARY KEY (`id`),
          UNIQUE KEY `orderid` (`orderid`),
          KEY `userid` (`userid`),
          KEY `packageid` (`packageid`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ");

    $exists = $db->prepare('SELECT 1 FROM settings WHERE name = ? LIMIT 1');
    $exists->execute(['promo_plans']);
    if ($exists->fetch() === false) {
        $db->prepare('INSERT INTO settings (name, value) VALUES (?, ?)')->execute(['promo_plans', '{}']);
    }
};
