<?php
return static function (PDO $db): void {
    $db->exec('CREATE TABLE IF NOT EXISTS ticket_close_notice (
        ticketid BIGINT NOT NULL PRIMARY KEY, userid BIGINT NOT NULL,
        created BIGINT NOT NULL, mail_sent TINYINT NOT NULL DEFAULT 0,
        telegram_sent TINYINT NOT NULL DEFAULT 0
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4');
};
