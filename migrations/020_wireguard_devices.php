<?php
/**
 * WireGuard / AmneziaWG multi-device support per account (migrations/020_wireguard_devices.php).
 *
 * Adds device_id and device name to wg_credential, allowing each user to have
 * up to iplimit concurrent devices with unique keys and internal IPs.
 */
return static function (PDO $db): void {
    $cols = [];
    foreach ($db->query("SHOW COLUMNS FROM wg_credential") as $row) {
        $cols[] = $row['Field'];
    }

    if (!in_array('device_id', $cols, true)) {
        $db->exec("ALTER TABLE `wg_credential` ADD COLUMN `device_id` INT(11) NOT NULL DEFAULT 1 AFTER `userid`");
    }

    if (!in_array('name', $cols, true)) {
        $db->exec("ALTER TABLE `wg_credential` ADD COLUMN `name` VARCHAR(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'دستگاه اصلی' AFTER `device_id`");
    }

    $hasCompositePk = false;
    foreach ($db->query("SHOW KEYS FROM wg_credential WHERE Key_name = 'PRIMARY'") as $k) {
        if ($k['Column_name'] === 'device_id') {
            $hasCompositePk = true;
        }
    }

    if (!$hasCompositePk) {
        $db->exec("ALTER TABLE `wg_credential` DROP PRIMARY KEY, ADD PRIMARY KEY (`userid`, `device_id`)");
    }

    $destDir = (defined('ROOT') ? ROOT : dirname(__DIR__)) . '/public/assets/img';
    $srcDir = dirname(__DIR__) . '/resources/assets/img';
    if (!is_dir($destDir)) {
        @mkdir($destDir, 0755, true);
    }
    foreach (['amneziawg.png', 'amneziavpn.png', 'happ.png'] as $img) {
        if (is_file($srcDir . '/' . $img) && !is_file($destDir . '/' . $img)) {
            @copy($srcDir . '/' . $img, $destDir . '/' . $img);
        }
    }
};
