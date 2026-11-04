<?php
return static function (PDO $db): void {
    $db->exec("CREATE TABLE IF NOT EXISTS purchase_breakdown_notice (
        orderid BIGINT NOT NULL, chat VARCHAR(64) NOT NULL,
        state VARCHAR(16) NOT NULL, updated BIGINT NOT NULL,
        PRIMARY KEY(orderid,chat)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");
    $q=$db->prepare('INSERT INTO settings (name,value) SELECT ?,? WHERE NOT EXISTS (SELECT 1 FROM settings WHERE name=?)');
    $q->execute(['purchase_breakdown_since',(string)time(),'purchase_breakdown_since']);
};
