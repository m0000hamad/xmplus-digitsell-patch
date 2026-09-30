<?php
/**
 * OpenVPN: the port customers connect to is chosen in the panel.
 *
 *   public_ports    comma list the profile's `remote` lines use, in order;
 *                   empty means the port OpenVPN itself listens on
 *   all_ports       the node redirects every port of its protocol to OpenVPN
 *                   (reported by the agent, see node/openvpn/digitsell-ovpn-nat)
 *   excluded_ports  ports the node leaves alone because something else on the
 *                   server listens there (reported by the agent)
 */
return static function (PDO $db): void {
    $columns = [
        'public_ports'   => "ALTER TABLE `ovpn_node` ADD COLUMN `public_ports` VARCHAR(255) NOT NULL DEFAULT '' AFTER `proto`",
        'all_ports'      => "ALTER TABLE `ovpn_node` ADD COLUMN `all_ports` TINYINT(1) NOT NULL DEFAULT 0 AFTER `public_ports`",
        'excluded_ports' => "ALTER TABLE `ovpn_node` ADD COLUMN `excluded_ports` TEXT NULL AFTER `all_ports`",
    ];

    $exists = $db->prepare(
        'SELECT 1 FROM information_schema.COLUMNS
          WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? AND COLUMN_NAME = ? LIMIT 1');

    foreach ($columns as $name => $sql) {
        $exists->execute(['ovpn_node', $name]);
        if ($exists->fetch() === false) {
            $db->exec($sql);
        }
    }
};
