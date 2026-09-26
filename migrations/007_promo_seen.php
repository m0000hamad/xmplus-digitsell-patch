<?php
/**
 * The dashboard's prize popup reads promo_log.seen (User::newGifts). Prizes
 * drawn before it existed count as seen. PromoJob adds the column itself too.
 */
return static function (PDO $db): void {
    $table = $db->query("SHOW TABLES LIKE 'promo_log'")->fetchColumn();
    if ($table === false) {
        return;
    }

    $column = $db->query("SHOW COLUMNS FROM promo_log LIKE 'seen'")->fetch();
    if ($column === false) {
        $db->exec('ALTER TABLE promo_log ADD COLUMN seen TINYINT(1) NOT NULL DEFAULT 1');
    }
};
