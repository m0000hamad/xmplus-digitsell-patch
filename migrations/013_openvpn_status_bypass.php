<?php
/**
 * OpenVPN: which instances are running, the domain certificate, and the bypass
 * (direct route) lists.
 *
 *   up_json   {"udp": 1, "tcp": 0}: which OpenVPN instances the agent could
 *             reach at its last report (agents from 1.3.0). Empty for older
 *             agents, which only report while something is running.
 *   cert_name the domain OpenVPN's certificate is for (agents from 1.4.0
 *             issue it for the domain customers connect to); empty for the
 *             certificate of the install. Customer files check the name
 *             (verify-x509-name) once it matches.
 *
 * Settings (rows in `settings`), all off / empty by default:
 *   ovpn_bypass_iran    1 sends Iranian addresses outside the tunnel
 *   ovpn_bypass_custom  extra addresses, networks and domains, one per line
 *   ovpn_bypass_cache   the addresses the domains resolved to (written by the
 *                       panel), {"at": <unix time>, "hosts": {"domain": [ips]}}
 */
return static function (PDO $db): void {
    $exists = $db->prepare(
        'SELECT 1 FROM information_schema.COLUMNS
          WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? AND COLUMN_NAME = ? LIMIT 1');
    $exists->execute(['ovpn_node', 'up_json']);
    if ($exists->fetch() === false) {
        $db->exec('ALTER TABLE `ovpn_node` ADD COLUMN `up_json` TEXT NULL AFTER `listen_json`');
    }

    $exists->execute(['ovpn_node', 'cert_name']);
    if ($exists->fetch() === false) {
        $db->exec("ALTER TABLE `ovpn_node` ADD COLUMN `cert_name` VARCHAR(253) NOT NULL DEFAULT '' AFTER `up_json`");
    }

    $defaults = [
        'ovpn_bypass_iran'   => '0',
        'ovpn_bypass_custom' => '',
        'ovpn_bypass_cache'  => '',
    ];

    $has = $db->prepare('SELECT 1 FROM settings WHERE name = ? LIMIT 1');
    $insert = $db->prepare('INSERT INTO settings (name, value) VALUES (?, ?)');

    foreach ($defaults as $name => $value) {
        $has->execute([$name]);
        if ($has->fetch() === false) {
            $insert->execute([$name, $value]);
        }
    }
};
