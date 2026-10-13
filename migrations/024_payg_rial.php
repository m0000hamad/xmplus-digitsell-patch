<?php
/**
 * The pay-as-you-go wallet shows its amounts in rial from now
 * on. Everything it holds is stored in rial, and the panel
 * wallet (user.money) shows rial too, so both wallets and the
 * order totals speak the same unit - no /10 toman conversion
 * anywhere: the balance, the charge presets, the minimum
 * charge, every price and every message are written in rial.
 * The admin can switch the toman display back on in Settings
 * ("Show amounts to customers in toman").
 */
return static function (PDO $db): void {
    try {
        $db->prepare("UPDATE `settings` SET value = '0' WHERE name = 'payg_show_toman'")->execute();
    } catch (Throwable $error) {
        // no settings table (fresh install): the code default is rial already
    }
};
