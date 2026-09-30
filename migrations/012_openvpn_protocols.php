<?php
/**
 * OpenVPN: UDP and TCP on the same server, separately or together.
 *
 *   listen_json       what the node runs, reported by agents from 1.2.0:
 *                     {"udp": {"port":1194,"all_ports":true,"excluded":[22]},
 *                      "tcp": {...}}. Empty for older agents, whose single
 *                     instance is still described by proto / port /
 *                     all_ports / excluded_ports.
 *   offer             what customers get: '' (whatever the node runs), 'udp',
 *                     'tcp' or 'both'
 *   public_ports_tcp  the TCP ports for customers; public_ports holds the UDP
 *                     ones from now on
 *
 * A node that ran TCP alone had its customer ports in public_ports; they move
 * to public_ports_tcp.
 */
return static function (PDO $db): void {
    $columns = [
        'listen_json'      => "ALTER TABLE `ovpn_node` ADD COLUMN `listen_json` TEXT NULL AFTER `excluded_ports`",
        'offer'            => "ALTER TABLE `ovpn_node` ADD COLUMN `offer` VARCHAR(8) NOT NULL DEFAULT '' AFTER `listen_json`",
        'public_ports_tcp' => "ALTER TABLE `ovpn_node` ADD COLUMN `public_ports_tcp` VARCHAR(255) NOT NULL DEFAULT '' AFTER `public_ports`",
    ];

    $exists = $db->prepare(
        'SELECT 1 FROM information_schema.COLUMNS
          WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? AND COLUMN_NAME = ? LIMIT 1');

    $added = [];
    foreach ($columns as $name => $sql) {
        $exists->execute(['ovpn_node', $name]);
        if ($exists->fetch() === false) {
            $db->exec($sql);
            $added[$name] = true;
        }
    }

    if (isset($added['public_ports_tcp'])) {
        $db->exec("UPDATE `ovpn_node` SET `public_ports_tcp` = `public_ports`, `public_ports` = ''
                    WHERE `proto` = 'tcp' AND `public_ports` <> ''");
    }
};
