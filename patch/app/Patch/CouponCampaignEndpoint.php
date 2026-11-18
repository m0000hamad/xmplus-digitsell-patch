<?php
declare(strict_types=1);

use App\Patch\CouponCampaigns;

define('INVOICE_CORE_ONLY', true);
require_once ROOT . '/app/Patch/Invoice.php';
require_once ROOT . '/app/Patch/CouponCampaigns.php';

try {
    if ($action === 'couponcampaign.active') {
        $uid = invoiceSession();
        $now = time();
        $entries = CouponCampaigns::read(setting(CouponCampaigns::SETTING));
        if (setting('allow_coupon_use') !== '1' || !$entries) {
            done(['user' => $uid, 'now' => $now, 'offers' => []]);
        }

        invoiceBootstrap();
        $offers = [];
        $next = null;
        foreach ($entries as $id => $entry) {
            if (!$entry['enabled']) {
                continue;
            }
            $coupon = CouponCampaigns::schedule($entry);
            if (CouponCampaigns::isActive($entry, $coupon, $now)) {
                $offers[] = [
                    'id' => $id, 'title' => $entry['title'], 'theme' => $entry['theme'],
                    'code' => $coupon['code'], 'start' => $coupon['start'], 'end' => $coupon['end'],
                    'percent' => $coupon['percentage'] ? $coupon['credit'] : null,
                ];
            } elseif ($coupon && $coupon['enabled'] && $coupon['start'] > $now && $coupon['start'] < $coupon['end']) {
                $next = min($next ?? $coupon['start'], $coupon['start']);
            }
        }
        usort($offers, static fn ($a, $b) => $b['start'] <=> $a['start']);
        done(['user' => $uid, 'now' => $now, 'next' => $next, 'offers' => $offers]);
    }

    requireAdmin();
    if ($action === 'couponcampaign.list') {
        $_SESSION['patch_csrf'] ??= bin2hex(random_bytes(32));
        invoiceBootstrap();
        done([
            'token' => $_SESSION['patch_csrf'],
            'entries' => (object) CouponCampaigns::read(setting(CouponCampaigns::SETTING)),
            'coupons' => CouponCampaigns::choices(),
        ]);
    }
    if ($action !== 'couponcampaign.save') {
        fail('Unknown coupon campaign action.');
    }
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        fail('POST required.', 405);
    }
    requireToken();
    $id = $_POST['id'] ?? '';
    $code = $_POST['code'] ?? '';
    $couponId = filter_var($_POST['coupon_id'] ?? null, FILTER_VALIDATE_INT, ['options' => ['min_range' => 1]]);
    $title = $_POST['title'] ?? '';
    $theme = $_POST['theme'] ?? '';
    if (!is_string($id) || ($id !== '' && !preg_match('/^[a-f0-9]{24}$/D', $id))
        || !is_string($title) || !in_array($theme, CouponCampaigns::THEMES, true)
        || (!$couponId && (!is_string($code) || trim($code) === '' || mb_strlen($code) > 128))
        || trim($title) === '' || mb_strlen($title) > 100) {
        done(['reason' => 'invalid']);
    }
    $enabled = ($_POST['enabled'] ?? '') === '1';
    $notify = ($_POST['notify'] ?? '') === '1';
    invoiceBootstrap();
    $coupon = $couponId ? CouponCampaigns::couponById($couponId) : CouponCampaigns::coupon(trim($code));
    // A missing/untimed code can still have its old campaign paused.
    if ((!$coupon || $coupon['start'] <= 0 || $coupon['end'] <= $coupon['start']) && ($enabled || $id === '')) {
        done(['reason' => 'timed']);
    }
    $new = $id === '';
    $id = $new ? bin2hex(random_bytes(12)) : $id;
    $entries = CouponCampaigns::change(db(), static function (array $entries) use ($new, $id, $coupon, $couponId, $title, $theme, $enabled, $notify) {
        if (!$new && !isset($entries[$id])) {
            throw new RuntimeException('Unknown coupon campaign.');
        }
        foreach ($entries as $key => $entry) {
            if ($key !== $id && $coupon && $entry['coupon_id'] === $coupon['id']) {
                throw new DomainException('duplicate');
            }
        }
        $old = $entries[$id] ?? [];
        if (!$new && $couponId && (int) $old['coupon_id'] !== $couponId) {
            throw new RuntimeException('Coupon selection changed.');
        }
        $boundId = $coupon['id'] ?? $old['coupon_id'];
        $entries[$id] = [
            'coupon_id' => $boundId,
            'code' => $coupon['code'] ?? $old['code'],
            'title' => trim($title),
            'theme' => $theme,
            'enabled' => $enabled,
            'notify' => $notify,
            'sent' => (int) ($old['coupon_id'] ?? 0) === $boundId ? ($old['sent'] ?? null) : null,
        ];
        return $entries;
    });
    done(['id' => $id, 'entries' => (object) $entries]);
} catch (DomainException $error) {
    done(['reason' => 'duplicate']);
} catch (Throwable $error) {
    error_log('Coupon campaign: ' . $error->getMessage());
    fail('Coupon campaign request failed.');
}
