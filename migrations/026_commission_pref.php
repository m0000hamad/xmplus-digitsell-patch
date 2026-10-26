<?php
/**
 * The customer's own pick for where a new commission lands.
 *
 * Only read while the admin's "let the customer choose" switch is on; the
 * admin's default in `commission_destination` applies otherwise.
 */
return static function (PDO $db): void {
    $db->exec("
        CREATE TABLE IF NOT EXISTS `commission_pref` (
          `userid` bigint(20) NOT NULL,
          `destination` varchar(10) NOT NULL,
          `updated` bigint(20) NOT NULL DEFAULT 0,
          PRIMARY KEY (`userid`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ");
};
