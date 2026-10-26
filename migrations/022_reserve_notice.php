<?php
/**
 * The notice a reservation leaves behind (app/Patch/Reserve.php).
 *
 * One row per event: a reservation being taken ("reserved") and one being
 * started ("started"). ReserveJob writes it as the guard for the whole
 * announcement - the unique key on `ref` means Telegram, the e-mail and the
 * dashboard banner each go out exactly once. The dashboard reads the unseen
 * rows through user/layout/reservebanner.tpl, and reserve.ack marks them seen.
 *
 * ReserveJob creates the table itself if the migration did not run, so an
 * install that skipped it still works.
 */
return static function (PDO $db): void {
    $db->exec("
        CREATE TABLE IF NOT EXISTS `reserve_notice` (
          `id` bigint(20) NOT NULL AUTO_INCREMENT,
          `userid` int(11) NOT NULL,
          `kind` varchar(16) NOT NULL DEFAULT '',
          `ref` varchar(64) NOT NULL,
          `name` varchar(255) NOT NULL DEFAULT '',
          `cycle` varchar(16) NOT NULL DEFAULT 'month',
          `days` int(11) NOT NULL DEFAULT 0,
          `mode` varchar(8) NOT NULL DEFAULT 'after',
          `activate_at` bigint(20) NOT NULL DEFAULT 0,
          `amount` decimal(12,2) NOT NULL DEFAULT '0.00',
          `expire_after` datetime DEFAULT NULL,
          `seen` tinyint(1) NOT NULL DEFAULT '0',
          `created` bigint(20) NOT NULL DEFAULT 0,
          PRIMARY KEY (`id`),
          UNIQUE KEY `ref` (`ref`),
          KEY `user_seen` (`userid`, `seen`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ");
};
