<?php
return static function(PDO $db): void {
    $db->exec("CREATE TABLE IF NOT EXISTS admin_balance_edit (
        id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, adminid BIGINT NOT NULL, userid BIGINT NOT NULL,
        request_key CHAR(48) NOT NULL, wallet_before DECIMAL(14,2) NOT NULL, wallet_after DECIMAL(14,2) NOT NULL,
        legacy_before DECIMAL(14,2) NOT NULL, legacy_after DECIMAL(14,2) NOT NULL,
        commission_before DECIMAL(14,2) NOT NULL, commission_after DECIMAL(14,2) NOT NULL,
        reason VARCHAR(250) NOT NULL, created BIGINT NOT NULL,
        UNIQUE KEY edit_once (adminid,request_key), KEY customer (userid,id)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");
};
