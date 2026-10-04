<?php
/**
 * WireGuard servers on the same subscription (app/Patch/Wg.php).
 *
 * A WireGuard server runs node/wireguard/wg-agent.py next to the wg-quick
 * interface. There is no login to ask about: a customer is given a .conf file
 * built from their account, and the agent adds, removes and reports their peers
 * through wg.push. The growth since the last push is added to user.u / user.d
 * (times the node's multiplier, as the panel does for its own servers) and
 * written to trafficlog (raw), so the plan's quota, the wallet billing in
 * PaygJob, the charts and the reports count WireGuard like any other server.
 * The answer names the peers whose account may no longer connect (plan over,
 * quota used, disabled, moved to another group) and the agent removes them -
 * the same cut-off the OpenVPN nodes and the Xray nodes apply.
 *
 *   wg_node       one row per WireGuard server: its key (hashed), the groups
 *                 it serves, its traffic multiplier, its listen port and the
 *                 public key customers need, sent by the agent itself
 *   wg_session    the last byte counters seen for each peer
 *   wg_credential the customer's public key, derived from their uuid and the
 *                 `wg_secret` setting (nothing secret is stored). The node's
 *                 agent reports peers by public key only, so this is what maps
 *                 a peer back to an account.
 *
 * `wg_enabled` starts off. `wg_secret` is what the customers' keys are derived
 * from - changing it changes every key, so wg_credential has to be emptied
 * afterwards (TRUNCATE wg_credential; the peers come back on the next push).
 *
 * Deriving the public key needs the sodium extension (sodium_crypto_box_
 * publickey_from_secretkey). Without it no .conf file can be built, so the
 * cards say so instead of handing out a file that cannot work.
 *
 * Traffic is logged under the virtual server id 950000 + node id. 900000 is
 * OpenVPN's; see OVPN_SERVER_BASE in app/Patch/Ovpn.php.
 */
return static function (PDO $db): void {
    $db->exec("CREATE TABLE IF NOT EXISTS `wg_node` (
        `id` INT(11) NOT NULL AUTO_INCREMENT,
        `name` VARCHAR(100) NOT NULL DEFAULT '',
        `keyhash` CHAR(64) NOT NULL DEFAULT '',
        `allowed_groups` VARCHAR(255) NOT NULL DEFAULT '',
        `rate` DECIMAL(8,2) NOT NULL DEFAULT 1.00,
        `enabled` TINYINT(1) NOT NULL DEFAULT 1,
        `sort` INT(11) NOT NULL DEFAULT 0,
        `host` VARCHAR(255) NOT NULL DEFAULT '',
        `host_override` VARCHAR(255) NOT NULL DEFAULT '',
        `listen_port` INT(11) NOT NULL DEFAULT 51820,
        `pubkey` VARCHAR(64) NOT NULL DEFAULT '',
        `dns` VARCHAR(255) NOT NULL DEFAULT '',
        `mtu` INT(11) NOT NULL DEFAULT 1420,
        `agent_version` VARCHAR(32) NOT NULL DEFAULT '',
        `heartbeat` INT(11) NOT NULL DEFAULT 0,
        `online` INT(11) NOT NULL DEFAULT 0,
        `created` INT(11) NOT NULL DEFAULT 0,
        `updated` INT(11) NOT NULL DEFAULT 0,
        PRIMARY KEY (`id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");

    $db->exec("CREATE TABLE IF NOT EXISTS `wg_session` (
        `id` BIGINT(20) NOT NULL AUTO_INCREMENT,
        `nodeid` INT(11) NOT NULL,
        `pubkey` VARCHAR(64) NOT NULL,
        `userid` INT(11) NOT NULL,
        `ip` VARCHAR(64) NOT NULL DEFAULT '',
        `endpoint` VARCHAR(64) NOT NULL DEFAULT '',
        `rx` BIGINT(20) NOT NULL DEFAULT 0,
        `tx` BIGINT(20) NOT NULL DEFAULT 0,
        `started` INT(11) NOT NULL DEFAULT 0,
        `seen` INT(11) NOT NULL DEFAULT 0,
        `closed` INT(11) NOT NULL DEFAULT 0,
        PRIMARY KEY (`id`),
        UNIQUE KEY `uniq_node_pubkey` (`nodeid`, `pubkey`),
        KEY `idx_user_seen` (`userid`, `seen`),
        KEY `idx_seen` (`seen`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");

    // A peer's public key is derived from the account, not chosen, so one per
    // account is enough; UNIQUE because two accounts must never share a peer.
    //
    // The tunnel address is NOT derived from the key alone: two accounts whose
    // keys hash alike would get the same address on a node and their traffic
    // would be indistinguishable. It is derived from the key and then nudged
    // until it is free, so `address` + `nodeid` is what makes it unique - the
    // column the panel reserves it in.
    $db->exec("CREATE TABLE IF NOT EXISTS `wg_credential` (
        `userid` INT(11) NOT NULL,
        `pubkey` VARCHAR(64) NOT NULL DEFAULT '',
        `updated` INT(11) NOT NULL DEFAULT 0,
        `nodeid` INT(11) DEFAULT NULL,
        `address` VARCHAR(16) DEFAULT NULL,
        PRIMARY KEY (`userid`),
        UNIQUE KEY `uniq_pubkey` (`pubkey`),
        UNIQUE KEY `uniq_node_address` (`nodeid`, `address`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");

    $defaults = [
        'wg_enabled'      => '0',
        'wg_secret'       => bin2hex(random_bytes(32)),
        'wg_notify'       => '1',
        'wg_notify_state' => '',
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