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
        $coupon = Coupon::where('code', $code)->first();
        if (!$coupon) {
            return null;
        }
        $row = $coupon->getAttributes();
        return [
            'id' => (int) $coupon->getKey(),
            'code' => (string) $row['code'],
            'enabled' => (int) ($row['status'] ?? 0) === 1,
            'start' => self::timestamp($row['start_date'] ?? null),
            'end' => self::timestamp($row['expire_date'] ?? null),
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
        $coupon = self::coupon($entry['code']);
        return $coupon && $coupon['id'] === $entry['coupon_id'] ? $coupon : null;
    }

    public static function isActive(array $entry, ?array $coupon, int $now): bool
    {
        return !empty($entry['enabled']) && $coupon && $coupon['enabled']
            && $coupon['start'] > 0 && $coupon['start'] <= $now && $now < $coupon['end'];
    }
}
