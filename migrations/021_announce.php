<?php
/**
 * Announcements: the two broadcast campaigns on the admin notices page.
 *
 *   invite_popup   1 = show the dashboard invite popup (default), 0 = hide it
 *
 * announce_campaigns and announce_group_id are written by the card itself
 * (app/Patch/Announce.php) and do not need a default row: a missing row reads
 * as "popup on, no group set", which is what the panel did before.
 */
return static function (PDO $db): void {
    $exists = $db->prepare('SELECT 1 FROM settings WHERE name = ? LIMIT 1');
    $exists->execute(['invite_popup']);
    if ($exists->fetch() === false) {
        $db->prepare('INSERT INTO settings (name, value) VALUES (?, ?)')->execute(['invite_popup', '1']);
    }
};
