<?php
/** Keep each profile-port usage row separate in dashboard history. */
return static function (PDO $db): void {
    $indexes = $db->query("SHOW INDEX FROM `traffic_daily` WHERE Key_name='uniq_user_day_server'")->fetchAll(PDO::FETCH_ASSOC);
    if ($indexes) {
        $db->exec('ALTER TABLE `traffic_daily` DROP INDEX `uniq_user_day_server`');
    }
    $db->exec('ALTER TABLE `traffic_daily` ADD UNIQUE KEY `uniq_user_day_server` (`userid`,`day`,`serverid`,`servername`)');
};
