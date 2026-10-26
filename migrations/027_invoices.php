<?php
return static function (PDO $db): void {
    $db->exec("CREATE TABLE IF NOT EXISTS patch_invoice (
        id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
        userid BIGINT NOT NULL,
        adminid BIGINT NOT NULL,
        title VARCHAR(200) NOT NULL,
        description TEXT NOT NULL,
        kind VARCHAR(12) NOT NULL,
        packageid BIGINT NOT NULL,
        plan VARCHAR(15) NOT NULL,
        renew TINYINT NOT NULL DEFAULT 0,
        amount DECIMAL(14,2) NOT NULL,
        orderid BIGINT NULL,
        checkout_url VARCHAR(500) NOT NULL DEFAULT '',
        canceled TINYINT NOT NULL DEFAULT 0,
        created BIGINT NOT NULL,
        request_key CHAR(48) NOT NULL,
        mail_status VARCHAR(20) NOT NULL DEFAULT 'off',
        telegram_status VARCHAR(20) NOT NULL DEFAULT 'off',
        UNIQUE KEY request_once (adminid, request_key),
        UNIQUE KEY order_once (orderid),
        KEY user_invoices (userid, id)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");
};
