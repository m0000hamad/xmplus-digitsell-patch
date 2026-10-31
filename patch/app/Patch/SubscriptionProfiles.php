<?php
declare(strict_types=1);

/** Two independent presentation profiles; native node entitlements still apply. */
final class SubscriptionProfiles
{
    private static $addresses = [];
    private static $names = [];
    private static $ports = [];
    private static $variants = [];

    public static function combined(string $json): array
    {
        $value = json_decode($json, true);
        return ['enabled' => !empty($value['enabled']),
            'name' => (string) ($value['name'] ?? 'لینک اشتراک ترکیبی'),
            'description' => (string) ($value['description'] ?? 'همه سرورهای مجاز دو لینک')];
    }

    /** Union only the enabled source profiles this subscriber may access. */
    public static function sources(array $profiles, array $user): array
    {
        return array_filter($profiles, static function ($profile) use ($user) { return self::allowed($profile, $user); });
    }

    public static function resolve(array $profiles, string $slot, array $user, array $combined): array
    {
        if (in_array($slot, ['1', '2'], true)) {
            $profile = $profiles[(int) $slot - 1] ?? [];
            return self::allowed($profile, $user) ? $profile : [];
        }
        if ($slot !== '3' || empty($combined['enabled'])) return [];
        $sources = self::sources($profiles, $user);
        if (!$sources) return [];
        $ids = [];
        foreach ($sources as $profile) $ids = array_merge($ids, $profile['servers'] ?? []);
        return $combined + ['servers' => array_values(array_unique(array_map('intval', $ids)))];
    }

    /** Expand read-only model results before the native serializers build any format. */
    public static function expand(array $models): array
    {
        if (!self::$variants) return $models;
        $result = [];
        $usedNames = [];
        foreach ($models as $model) {
            // Eloquent calls newCollection during both hydration and get().
            // These instances already represent their individual source variant.
            if ($model->subscriptionProfileSlot !== null) {
                $usedNames[$model->name] = true;
                $result[] = $model;
                continue;
            }
            $seen = [];
            foreach (self::$variants[(int) $model->id] ?? [] as $slot => $overrides) {
                $copy = clone $model;
                $copy->subscriptionProfileSlot = $slot;
                $signature = json_encode([$copy->address, $copy->name, self::port((int) $model->id, $model->port, $slot)]);
                if (isset($seen[$signature])) continue;
                $seen[$signature] = true;
                $number = 2;
                while (isset($usedNames[$copy->name])) $copy->subscriptionProfileNameSuffix = ' (' . $number++ . ')';
                $usedNames[$copy->name] = true;
                $result[] = $copy;
            }
            // A selected relay's transport is an internal dependency, not a profile entry.
            if (!isset(self::$variants[(int) $model->id])) $result[] = $model;
        }
        return $result;
    }

    public static function port(int $serverId, $fallback, ?int $slot = null)
    {
        if ($slot !== null) return self::$variants[$serverId][$slot]['port'] ?? $fallback;
        return self::$ports[$serverId] ?? $fallback;
    }

    public static function name(int $serverId, $fallback, ?int $slot = null)
    {
        if ($slot !== null) return self::$variants[$serverId][$slot]['name'] ?? $fallback;
        return self::$names[$serverId] ?? $fallback;
    }

    public static function address(int $serverId, $fallback, ?int $slot = null)
    {
        if ($slot !== null) return self::$variants[$serverId][$slot]['address'] ?? $fallback;
        return self::$addresses[$serverId] ?? $fallback;
    }

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
            || !in_array($slot, ['1', '2', '3'], true) || !ctype_digit($until)
            || (int) $until < time() || (int) $until > time() + 90
            || !hash_equals(hash_hmac('sha256', $slot . ':' . $until . ':' . $match[1], $secret), $mac)) return;
        $profiles = self::read((string) ($settings['sub_profiles'] ?? '[]'));
        $profile = $profiles[(int) $slot - 1] ?? [];
        if ($slot === '3') {
            $user = \Illuminate\Database\Capsule\Manager::table('user')->where('token', $match[1])->first(['server_group']);
            if (!$user) return;
            $profile = self::resolve($profiles, $slot, (array) $user, self::combined((string) ($settings['sub_profiles_combined'] ?? '{}')));
            if (!$profile) return;
            foreach (self::sources($profiles, (array) $user) as $index => $source) {
                $sourceSlot = $index + 1;
                foreach ($source['servers'] as $id) {
                    $billing = json_decode((string) ($settings['server_profile_billing_' . $id] ?? '{}'), true);
                    $domains = json_decode((string) ($settings['server_profile_domains_' . $id] ?? '{}'), true);
                    $names = json_decode((string) ($settings['server_profile_names_' . $id] ?? '{}'), true);
                    self::$variants[(int) $id][$sourceSlot] = [
                        'port' => !empty($billing['enabled']) ? ($billing['ports'][$sourceSlot] ?? null) : null,
                        'address' => ($domains[$sourceSlot] ?? '') ?: null,
                        'name' => ($names[$sourceSlot] ?? '') ?: null];
                }
            }
        }
        $ids = array_map('intval', $profile['servers'] ?? []);
        foreach ($ids as $id) {
            $billing = json_decode((string) ($settings['server_profile_billing_' . $id] ?? '{}'), true);
            if (!empty($billing['enabled']) && !empty($billing['ports'][$slot])) self::$ports[$id] = (int) $billing['ports'][$slot];
            $domains = json_decode((string) ($settings['server_profile_domains_' . $id] ?? '{}'), true);
            $domain = is_array($domains) ? ($domains[$slot] ?? '') : '';
            if (is_string($domain) && $domain !== '') self::$addresses[$id] = $domain;
            $names = json_decode((string) ($settings['server_profile_names_' . $id] ?? '{}'), true);
            $name = is_array($names) ? ($names[$slot] ?? '') : '';
            if (is_string($name) && $name !== '') self::$names[$id] = $name;
        }
        $dependencies = array_map('intval', \Illuminate\Database\Capsule\Manager::table('servers')
            ->whereIn('id', $ids)->where('relay_type', 2)->pluck('relayid')->all());
        $installed = true;
        \App\Http\Models\Server::addGlobalScope('digitsell_subscription_profile', static function ($query) use ($ids, $dependencies, $slot) {
            $query->whereIn('servers.id', self::queryIds($ids, $dependencies, $query->getQuery()->wheres ?? []));
            header('X-Digitsell-Profile-Applied: ' . $slot);
        });
    }
}
