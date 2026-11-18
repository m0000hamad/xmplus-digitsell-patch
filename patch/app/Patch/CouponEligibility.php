<?php
declare(strict_types=1);

namespace App\Patch;

use PDO;

final class CouponEligibility
{
    private PDO $db;

    public function __construct(PDO $db)
    {
        $this->db = $db;
    }

    public function rule(int $couponId): array
    {
        $query = $this->db->prepare('SELECT fresh, unique_ip FROM patch_coupon_rules WHERE coupon_id = ?');
        $query->execute([$couponId]);
        $rule = $query->fetch(PDO::FETCH_ASSOC);

        return [
            'fresh' => !empty($rule['fresh']),
            'unique_ip' => !empty($rule['unique_ip']),
        ];
    }

    public function store(int $couponId, bool $fresh, bool $uniqueIp): void
    {
        if (!$fresh && !$uniqueIp) {
            $this->db->prepare('DELETE FROM patch_coupon_rules WHERE coupon_id = ?')->execute([$couponId]);
            return;
        }
        $query = $this->db->prepare('INSERT INTO patch_coupon_rules (coupon_id, fresh, unique_ip) VALUES (?, ?, ?)
            ON DUPLICATE KEY UPDATE fresh = VALUES(fresh), unique_ip = VALUES(unique_ip)');
        $query->execute([$couponId, (int) $fresh, (int) $uniqueIp]);
    }

    public function reasonForCode(string $code, int $userId): ?string
    {
        $query = $this->db->prepare('SELECT digitsell_coupon_eligibility(?, ?)');
        $query->execute([$code, $userId]);
        $reason = $query->fetchColumn();
        return is_string($reason) ? $reason : null;
    }
}
