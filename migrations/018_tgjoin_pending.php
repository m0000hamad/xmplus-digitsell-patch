<?php
/** Pending Telegram gifts for users with zero payg balance. */
return static function (PDO $db): void {
    $db->exec(
        "CREATE TABLE IF NOT EXISTS `tgjoin_pending` (
            `userid`      INT(11) NOT NULL,
            `telegram_id` BIGINT(20) NOT NULL,
            `kind`        VARCHAR(10) NOT NULL,
            `gb`          DECIMAL(10,4) NOT NULL,
            `days`        INT(11) NOT NULL DEFAULT 0,
            `created_at`  BIGINT(20) NOT NULL,
            PRIMARY KEY (`userid`, `kind`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4"
    );

    // MySQL 5.7 doesn't support ADD COLUMN IF NOT EXISTS
    $col = $db->query("SHOW COLUMNS FROM `payg_wallet` LIKE 'gifted'");
    if (!$col->fetch()) {
        $db->exec("ALTER TABLE `payg_wallet` ADD COLUMN `gifted` DECIMAL(16,2) NOT NULL DEFAULT 0 AFTER `bonus`");
    }
};