<?php
return static function (PDO $db): void {
    $db->exec('CREATE TABLE IF NOT EXISTS node_profile_online (
        serverid INT NOT NULL PRIMARY KEY,
        profile1 INT NOT NULL DEFAULT 0,
        profile2 INT NOT NULL DEFAULT 0,
        unclassified INT NOT NULL DEFAULT 0,
        ready TINYINT NOT NULL DEFAULT 0,
        datetime BIGINT NOT NULL
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4');
};
