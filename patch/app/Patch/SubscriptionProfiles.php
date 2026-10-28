<?php
declare(strict_types=1);

/** Two independent presentation profiles; native node entitlements still apply. */
final class SubscriptionProfiles
{
    public static function allowed(array $profile, array $user): bool
    {
        return !empty($profile['enabled']) && in_array((int) ($user['server_group'] ?? 0), $profile['groups'] ?? [], true);
    }

    public static function read(string $json): array
    {
        $rows = json_decode($json, true);
        return is_array($rows) && array_keys($rows) === [0, 1]
            && is_array($rows[0]) && is_array($rows[1]) ? $rows : [];
    }

    /** A selected relay's private transport lookup must not add a list entry. */
    public static function queryIds(array $ids, array $dependencies, array $wheres): array
    {
        if (count($wheres) === 1) {
            $where = $wheres[0];
            if (($where['type'] ?? '') === 'Basic' && ($where['operator'] ?? '') === '='
                && in_array($where['column'] ?? '', ['id', 'servers.id'], true)
                && in_array((int) ($where['value'] ?? 0), $dependencies, true)) {
                return [(int) $where['value']];
            }
        }
        return $ids;
    }

    /** Keep native managed-config refresh URLs inside their chosen profile. */
    public static function rewriteUrls(string $body, string $token, string $base): string
    {
        return (string) preg_replace_callback('~https?://[A-Za-z0-9.:-]+/link/' . preg_quote($token, '~')
            . '(?=\?|[\s"\'<>]|$)(\?)?~', static function ($match) use ($base) {
                return $base . (!empty($match[1]) ? '&' : '');
            }, $body);
    }

    /** Called from ConfigProvider only for authenticated internal /link requests. */
    public static function scope(array $settings): void
    {
        static $installed = false;
        if ($installed || empty($_SERVER['HTTP_X_DIGITSELL_PROFILE'])) return;
        $parts = explode(':', (string) $_SERVER['HTTP_X_DIGITSELL_PROFILE']);
        if (count($parts) !== 3) return;
        [$slot, $until, $mac] = $parts;
        $path = (string) parse_url($_SERVER['REQUEST_URI'] ?? '', PHP_URL_PATH);
        $secret = (string) ($settings['sub_profiles_secret'] ?? '');
        if ($secret === '' || !preg_match('~^/link/([A-Za-z0-9_-]{6,128})/?$~', $path, $match)
            || !in_array($slot, ['1', '2'], true) || !ctype_digit($until)
            || (int) $until < time() || (int) $until > time() + 90
            || !hash_equals(hash_hmac('sha256', $slot . ':' . $until . ':' . $match[1], $secret), $mac)) return;
        $profiles = self::read((string) ($settings['sub_profiles'] ?? '[]'));
        $profile = $profiles[(int) $slot - 1] ?? [];
        $ids = array_map('intval', $profile['servers'] ?? []);
        $dependencies = array_map('intval', \Illuminate\Database\Capsule\Manager::table('servers')
            ->whereIn('id', $ids)->where('relay_type', 2)->pluck('relayid')->all());
        $installed = true;
        \App\Http\Models\Server::addGlobalScope('digitsell_subscription_profile', static function ($query) use ($ids, $dependencies, $slot) {
            $query->whereIn('servers.id', self::queryIds($ids, $dependencies, $query->getQuery()->wheres ?? []));
            header('X-Digitsell-Profile-Applied: ' . $slot);
        });
    }
}
