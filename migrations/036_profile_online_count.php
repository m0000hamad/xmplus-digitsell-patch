<?php
return static function (PDO $db): void {
    $columns = $db->query("SHOW COLUMNS FROM node_user_profile_online LIKE 'ip_count'");
    if ($columns->fetch() === false) {
        $db->exec('ALTER TABLE node_user_profile_online ADD COLUMN ip_count INT UNSIGNED NOT NULL DEFAULT 1');
    }
};
