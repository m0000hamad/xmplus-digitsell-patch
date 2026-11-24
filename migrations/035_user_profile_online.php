<?php
return static function (PDO $db): void {
    $db->exec('CREATE TABLE IF NOT EXISTS node_user_profile_online (
        serverid INT NOT NULL,
        userid INT NOT NULL,
        profile TINYINT NOT NULL,
        datetime BIGINT NOT NULL,
        PRIMARY KEY (serverid, userid, profile),
        KEY user_freshness (userid, datetime)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4');
};
