<?php
/**
 * Exit location: "new IP" on a server that leaves through Tor.
 *
 *   rotate_at  when an admin last asked for a new exit IP (0 = never). The
 *              Xray agent compares it with the last request it carried out,
 *              restarts that country's Tor node (tor-geo rotate) and reports
 *              the old and the new IP.
 */
return static function (PDO $db): void {
    $exists = $db->prepare(
        'SELECT 1 FROM information_schema.COLUMNS
          WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? AND COLUMN_NAME = ? LIMIT 1');
    $exists->execute(['torexit_node', 'rotate_at']);
    if ($exists->fetch() === false) {
        $db->exec('ALTER TABLE `torexit_node` ADD COLUMN `rotate_at` INT UNSIGNED NOT NULL DEFAULT 0 AFTER `want_at`');
    }
};
