<?php
/**
 * Announcing a promotion to every customer: one row per promotion and
 * customer, claimed before the message is sent, so nobody hears about the same
 * promotion twice. `promo` is "<package id>:<started_at>".
 *
 * PromoJob creates the table itself if it is missing.
 */
return static function (PDO $db): void {
    $db->exec("
        CREATE TABLE IF NOT EXISTS `promo_broadcast` (
          `id` bigint(20) NOT NULL AUTO_INCREMENT,
          `promo` varchar(32) NOT NULL,
          `userid` int(11) NOT NULL,
          `sent_at` bigint(20) NOT NULL,
          PRIMARY KEY (`id`),
          UNIQUE KEY `promo_user` (`promo`, `userid`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ");
};
