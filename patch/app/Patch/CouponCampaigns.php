<?php
declare(strict_types=1);

namespace App\Patch;

use App\Http\Models\Coupon;
use DateTimeImmutable;
use DateTimeZone;
use PDO;
use RuntimeException;

final class CouponCampaigns
{
    public const SETTING = 'coupon_campaigns';
    public const THEMES = ['classic', 'black_friday', 'nowruz', 'yalda', 'christmas'];

    public static function read(?string $value): array
    {
        $entries = json_decode((string) $value, true);
        return is_array($entries) ? $entries : [];
    }

    /** Serialize changes by the admin and the Telegram worker. */
    public static function change(PDO $db, callable $change): array
    {
        $lock = 'digitsell:coupon-campaigns';
        $query = $db->prepare('SELECT GET_LOCK(?, 5)');
        $query->execute([$lock]);
        if ((int) $query->fetchColumn() !== 1) {
            throw new RuntimeException('Coupon campaign settings are busy.');
        }
        try {
            $query = $db->prepare('SELECT value FROM settings WHERE name = ? LIMIT 1');
            $query->execute([self::SETTING]);
            $stored = $query->fetchColumn();
            $current = self::read($stored === false ? null : (string) $stored);
            $updated = $change($current);
            if ($current !== $updated) {
                $value = json_encode($updated, JSON_UNESCAPED_UNICODE | JSON_THROW_ON_ERROR);
                $sql = $stored === false ? 'INSERT INTO settings (value, name) VALUES (?, ?)'
                    : 'UPDATE settings SET value = ? WHERE name = ?';
                $db->prepare($sql)->execute([$value, self::SETTING]);
            }
            return $updated;
        } finally {
            $db->prepare('SELECT RELEASE_LOCK(?)')->execute([$lock]);
        }
    }

    public static function coupon(string $code): ?array
    {
        return self::describe(Coupon::where('code', $code)->first());
    }

    public static function couponById(int $id): ?array
    {
        return self::describe(Coupon::find($id));
    }

    public static function choices(): array
    {
        $coupons = [];
        foreach (Coupon::orderBy('id', 'desc')->get() as $coupon) {
            $coupons[] = self::describe($coupon);
        }
        return $coupons;
    }

    private static function describe(?Coupon $coupon): ?array
    {
        if ($coupon === null) {
            return null;
        }
        $row = $coupon->getAttributes();
        $type = strtolower((string) ($row['type'] ?? ''));
        $credit = $row['credit'] ?? null;
        return [
            'id' => (int) $coupon->getKey(),
            'code' => (string) $row['code'],
            'enabled' => (int) ($row['status'] ?? 0) === 1,
            'start' => self::timestamp($row['start_date'] ?? null),
            'end' => self::timestamp($row['expire_date'] ?? null),
            'credit' => is_numeric($credit) ? (float) $credit : null,
            'percentage' => in_array($type, ['2', 'percentage_amount', 'percentage', 'percent'], true),
        ];
    }

    private static function timestamp($value): int
    {
        if (is_numeric($value)) {
            return (int) $value;
        }
        if (!is_string($value) || !preg_match('/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$/D', $value)) {
            return 0;
        }
        $date = DateTimeImmutable::createFromFormat('!Y-m-d H:i:s', $value, new DateTimeZone('Asia/Tehran'));
        return $date && $date->format('Y-m-d H:i:s') === $value ? $date->getTimestamp() : 0;
    }

    public static function schedule(array $entry): ?array
    {
        return self::couponById((int) $entry['coupon_id']);
    }

    public static function isActive(array $entry, ?array $coupon, int $now): bool
    {
        return !empty($entry['enabled']) && $coupon && $coupon['enabled']
            && $coupon['start'] > 0 && $coupon['start'] <= $now && $now < $coupon['end'];
    }
}
