<?php
return static function (PDO $db): void {
    $db->exec("CREATE TABLE IF NOT EXISTS checkout_funds (
        orderid BIGINT NOT NULL PRIMARY KEY, userid BIGINT NOT NULL,
        base_amount DECIMAL(14,2) NOT NULL, cash_amount DECIMAL(14,2) NOT NULL DEFAULT 0,
        wallet_amount DECIMAL(14,2) NOT NULL DEFAULT 0, commission_amount DECIMAL(14,2) NOT NULL DEFAULT 0,
        use_wallet TINYINT NOT NULL DEFAULT 0, use_commission TINYINT NOT NULL DEFAULT 0,
        state VARCHAR(12) NOT NULL DEFAULT 'reserved', created BIGINT NOT NULL, updated BIGINT NOT NULL,
        KEY pending (state,orderid), KEY customer (userid,orderid)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");
};
