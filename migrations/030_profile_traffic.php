<?php
return static function (PDO $db): void {
    $db->exec('CREATE TABLE IF NOT EXISTS profile_traffic_batch (
        node_id INT NOT NULL,
        batch_id CHAR(32) NOT NULL,
        digest CHAR(64) NOT NULL,
        created_at BIGINT NOT NULL,
        PRIMARY KEY (node_id,batch_id)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4');
};
