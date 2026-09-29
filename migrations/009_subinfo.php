<?php
/**
 * Status rows in the client apps (app/Patch/SubInfo.php).
 *
 * `sub_info_enabled` only decides which link the dashboard hands out; it starts
 * off so the owner can try the new link by hand first. `sub_origin_ip` pins the
 * wrapper's fetch of the panel's own /link/ to this machine.
 */
return static function (PDO $db): void {
    $defaults = [
        'sub_info_enabled' => '0',
        'sub_origin'       => '',
        'sub_origin_ip'    => '127.0.0.1',
    ];

    $exists = $db->prepare('SELECT 1 FROM settings WHERE name = ? LIMIT 1');
    $insert = $db->prepare('INSERT INTO settings (name, value) VALUES (?, ?)');

    foreach ($defaults as $name => $value) {
        $exists->execute([$name]);
        if ($exists->fetch() === false) {
            $insert->execute([$name, $value]);
        }
    }
};
