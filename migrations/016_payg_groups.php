<?php
/** Server groups allowed to continue through the pay-as-you-go wallet. */
return static function (PDO $db): void {
    $exists = $db->prepare('SELECT 1 FROM settings WHERE name = ? LIMIT 1');
    $exists->execute(['payg_allowed_groups']);

    if ($exists->fetch() === false) {
        $db->prepare('INSERT INTO settings (name, value) VALUES (?, ?)')
            ->execute(['payg_allowed_groups', '[]']);
    }
};
