<?php
declare(strict_types=1);

use App\Patch\CouponCampaigns;
use App\Patch\CouponEligibility;

define('INVOICE_CORE_ONLY', true);
require_once ROOT . '/app/Patch/Invoice.php';
require_once ROOT . '/app/Patch/CouponCampaigns.php';
require_once ROOT . '/app/Patch/CouponEligibility.php';

try {
    if ($action === 'couponrules.check') {
        $uid = invoiceSession();
        if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
            fail('POST required.', 405);
        }
        $code = $_POST['code'] ?? '';
        if (!is_string($code) || $code === '' || strlen($code) > 1024) {
            fail('Invalid coupon code.');
        }
        done(['reason' => (new CouponEligibility(db()))->reasonForCode($code, $uid)]);
    }

    requireAdmin();
    if (!in_array($action, ['couponrules.get', 'couponrules.save'], true)) {
        fail('Unknown coupon rule action.');
    }
    $save = $action === 'couponrules.save';
    if ($save) {
        if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
            fail('POST required.', 405);
        }
        requireToken();
    }
    $id = filter_var(($save ? $_POST : $_GET)['coupon_id'] ?? null, FILTER_VALIDATE_INT, ['options' => ['min_range' => 1]]);
    if (!$id) {
        fail('Invalid coupon ID.');
    }
    invoiceBootstrap();
    $coupon = CouponCampaigns::couponById($id);
    if (!$coupon) {
        fail('Coupon not found.');
    }
    $rules = new CouponEligibility(db());
    if ($save) {
        $fresh = ($_POST['fresh'] ?? '') === '1';
        $uniqueIp = ($_POST['unique_ip'] ?? '') === '1';
        if ($fresh && ($coupon['start'] <= 0 || $coupon['end'] <= $coupon['start'])) {
            done(['reason' => 'schedule']);
        }
        $rules->store($id, $fresh, $uniqueIp);
    }
    $_SESSION['patch_csrf'] ??= bin2hex(random_bytes(32));
    done(['token' => $_SESSION['patch_csrf'], 'rule' => $rules->rule($id)]);
} catch (Throwable $error) {
    error_log('Coupon rule request: ' . $error->getMessage());
    fail('Coupon rule request failed.');
}
