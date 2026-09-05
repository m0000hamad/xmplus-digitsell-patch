<?php
/**
 * Settings the patch reads.
 *
 * Each one is only inserted when absent. The commission watermark especially:
 * lowering it would pay out historical referrals a second time.
 */
return static function (PDO $db): void {
    $defaults = [
        'min_withdrawal'       => '10000000',
        'withdraw_max_gap_days' => '90',
    ];

    $exists = $db->prepare('SELECT 1 FROM settings WHERE name = ? LIMIT 1');
    $insert = $db->prepare('INSERT INTO settings (name, value) VALUES (?, ?)');

    foreach ($defaults as $name => $value) {
        $exists->execute([$name]);
        if ($exists->fetch() === false) {
            $insert->execute([$name, $value]);
        }
    }

    // start the watermark at the newest referral, so nothing historical is paid
    $exists->execute(['commission_last_affiliate_id']);
    if ($exists->fetch() === false) {
        $newest = (int) $db->query('SELECT COALESCE(MAX(id), 0) FROM affiliate')->fetchColumn();
        $insert->execute(['commission_last_affiliate_id', (string) $newest]);
    }
};
