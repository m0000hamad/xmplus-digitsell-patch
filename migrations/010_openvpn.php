<?php
/**
 * OpenVPN servers on the same subscription (app/Patch/Ovpn.php).
 *
 * An OpenVPN server runs node/openvpn/ovpn-agent.py next to OpenVPN. The agent
 * asks the panel whether a login may connect and reports each session's byte
 * counters once a minute; the panel adds the usage to user.u / user.d and to
 * trafficlog, so the plan's quota, the wallet billing and the charts all see
 * it the same way they see an Xray node.
 *
 *   ovpn_node     one row per OpenVPN server: its key (hashed), the groups it
 *                 serves, its traffic multiplier, and what its client profile
 *                 needs (CA, tls-crypt key, address), sent by the agent itself
 *   ovpn_session  the last byte counters seen for each live session; the push
 *                 sends running totals and only the growth is counted, so a
 *                 push sent twice is counted once
 *
 * `ovpn_enabled` starts off. `ovpn_secret` is what the customers' OpenVPN
 * passwords are derived from - changing it changes every password.
 */
return static function (PDO $db): void {
    $db->exec("CREATE TABLE IF NOT EXISTS `ovpn_node` (
        `id` INT(11) NOT NULL AUTO_INCREMENT,
        `name` VARCHAR(100) NOT NULL DEFAULT '',
        `keyhash` CHAR(64) NOT NULL DEFAULT '',
        `allowed_groups` VARCHAR(255) NOT NULL DEFAULT '',
        `rate` DECIMAL(8,2) NOT NULL DEFAULT 1.00,
        `enabled` TINYINT(1) NOT NULL DEFAULT 1,
        `sort` INT(11) NOT NULL DEFAULT 0,
        `host` VARCHAR(255) NOT NULL DEFAULT '',
        `host_override` VARCHAR(255) NOT NULL DEFAULT '',
        `port` INT(11) NOT NULL DEFAULT 1194,
        `proto` VARCHAR(8) NOT NULL DEFAULT 'udp',
        `ca` TEXT NULL,
        `tls_crypt` TEXT NULL,
        `agent_version` VARCHAR(32) NOT NULL DEFAULT '',
        `heartbeat` INT(11) NOT NULL DEFAULT 0,
        `online` INT(11) NOT NULL DEFAULT 0,
        `created` INT(11) NOT NULL DEFAULT 0,
        `updated` INT(11) NOT NULL DEFAULT 0,
        PRIMARY KEY (`id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");

    $db->exec("CREATE TABLE IF NOT EXISTS `ovpn_session` (
        `id` BIGINT(20) NOT NULL AUTO_INCREMENT,
        `nodeid` INT(11) NOT NULL,
        `sid` VARCHAR(80) NOT NULL,
        `userid` INT(11) NOT NULL,
        `ip` VARCHAR(64) NOT NULL DEFAULT '',
        `vip` VARCHAR(64) NOT NULL DEFAULT '',
        `rx` BIGINT(20) NOT NULL DEFAULT 0,
        `tx` BIGINT(20) NOT NULL DEFAULT 0,
        `started` INT(11) NOT NULL DEFAULT 0,
        `seen` INT(11) NOT NULL DEFAULT 0,
        `closed` INT(11) NOT NULL DEFAULT 0,
        PRIMARY KEY (`id`),
        UNIQUE KEY `uniq_node_sid` (`nodeid`, `sid`),
        KEY `idx_user_seen` (`userid`, `seen`),
        KEY `idx_seen` (`seen`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");

    $defaults = [
        'ovpn_enabled' => '0',
        'ovpn_secret'  => bin2hex(random_bytes(32)),
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
