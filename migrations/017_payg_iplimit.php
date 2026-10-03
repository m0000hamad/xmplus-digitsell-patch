<?php
/** iplimit override for payg wallet mode. */
return static function (PDO $db): void {
    $exists = $db->prepare('SELECT 1 FROM settings WHERE name = ? LIMIT 1');
    $exists->execute(['payg_iplimit']);

    if ($exists->fetch() === false) {
        $db->prepare('INSERT INTO settings (name, value) VALUES (?, ?)')
            ->execute(['payg_iplimit', '0']);
    }
};