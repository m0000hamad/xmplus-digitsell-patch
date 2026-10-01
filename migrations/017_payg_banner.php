<?php
/**
 * Charge wallet: the banner at the top of customer pages that announces it.
 *
 *   payg_banner   1 = show it while the wallet is on (default), 0 = hide it
 */
return static function (PDO $db): void {
    $exists = $db->prepare('SELECT 1 FROM settings WHERE name = ? LIMIT 1');
    $exists->execute(['payg_banner']);
    if ($exists->fetch() === false) {
        $db->prepare('INSERT INTO settings (name, value) VALUES (?, ?)')->execute(['payg_banner', '1']);
    }
};
