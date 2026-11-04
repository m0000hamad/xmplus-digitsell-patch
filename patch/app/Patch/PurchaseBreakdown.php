<?php
/** Pure formatter; all amounts come from the paid order and its funding hold. */
final class PurchaseBreakdown
{
    public static function text(array $o, ?array $h): string
    {
        $c = static function ($n): int { return (int) round((float) $n * 100); };
        $m = static function (int $n): string { return number_format($n / 100, $n % 100 ? 2 : 0) . ' ریال'; };
        $price = $c($o['package_amount']);
        $discount = $c($o['discount']);
        $wallet = $h ? $c($h['wallet_amount']) : 0;
        $commission = $h ? $c($h['cash_amount']) + $c($h['commission_amount']) : $c($o['user_balance']);
        $fee = $c($o['gateway_fee']);
        $paid = $c($o['total_amount']);
        $text = 'ریز محاسبه خرید' . "\nشماره سفارش: " . $o['order_id']
            . "\nقیمت اشتراک: " . $m($price)
            . "\nکسر تخفیف: " . $m($discount)
            . "\nکسر کیف پول: " . $m($wallet)
            . "\nکسر پورسانت: " . $m($commission);
        // Upgrades and prorations can adjust the principal independently of coupons.
        $adjustment = $paid - ($price - $discount - $wallet - $commission + $fee);
        if ($adjustment !== 0) {
            $text .= "\nتعدیل مبلغ سفارش: " . ($adjustment > 0 ? '+' : '−') . $m(abs($adjustment));
        }
        return $text . "\nکارمزد درگاه: " . $m($fee)
            . "\nمبلغ نهایی پرداخت‌شده: " . $m($paid)
            . "\nمحاسبه: قیمت − تخفیف − کیف پول − پورسانت"
            . ($adjustment ? ' ± تعدیل' : '') . ' + کارمزد = پرداخت نهایی';
    }
}
