<?php
declare(strict_types=1);

/** Expand only already-authorized native server cards, never query extra nodes. */
final class ServerProfileCards
{
    public static function expand(iterable $cards, array $settings, array $user): array
    {
        require_once __DIR__ . '/SubscriptionProfiles.php';
        $profiles = SubscriptionProfiles::sources(
            SubscriptionProfiles::read((string) ($settings['sub_profiles'] ?? '[]')), $user);
        $result = [];
        foreach ($cards as $card) {
            $id = (int) $card['id'];
            $billing = json_decode((string) ($settings['server_profile_billing_' . $id] ?? '{}'), true);
            $domains = json_decode((string) ($settings['server_profile_domains_' . $id] ?? '{}'), true);
            $names = json_decode((string) ($settings['server_profile_names_' . $id] ?? '{}'), true);
            $variants = [];
            if (!empty($billing['enabled'])) foreach ($profiles as $index => $profile) {
                $slot = $index + 1;
                if (!in_array($id, array_map('intval', $profile['servers'] ?? []), true)) continue;
                $port = filter_var($billing['ports'][$slot] ?? null, FILTER_VALIDATE_INT,
                    ['options' => ['min_range' => 1, 'max_range' => 65535]]);
                if (!$port) continue;
                $name = ($names[$slot] ?? '') ?: $card['name'];
                // The port keeps otherwise-identical names distinguishable in imports and search.
                $name .= ' (' . $port . ')';
                $link = self::link((string) $card['link'], (string) ($domains[$slot] ?? ''), $port, $name);
                if ($link === null) continue;
                $variants[$link] = array_replace($card, ['name' => $name, 'link' => $link]);
            }
            foreach ($variants ?: [$card] as $variant) $result[] = $variant;
        }
        return $result;
    }

    /** Preserve credentials, TLS/SNI, transport, plugin and all native query options. */
    public static function link(string $link, string $host, int $port, string $name): ?string
    {
        if (strpos($link, 'vmess://') === 0) {
            $payload = self::decode(substr($link, 8));
            $config = $payload === false ? null : json_decode($payload, true);
            if (!is_array($config) || !isset($config['add'], $config['port'])) return null;
            if ($host !== '') $config['add'] = $host;
            $config['port'] = $port;
            $config['ps'] = $name;
            return 'vmess://' . base64_encode(json_encode($config, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE));
        }
        if (!preg_match('~^(vless|trojan|ss)://([^#]*)(?:#.*)?$~s', $link, $match)) return null;
        $scheme = $match[1];
        $body = $match[2];
        // Legacy Shadowsocks encodes the entire userinfo@host:port, unlike SIP002.
        $legacy = $scheme === 'ss' && strpos($body, '@') === false;
        if ($legacy) {
            $queryAt = strpos($body, '?');
            $query = $queryAt === false ? '' : substr($body, $queryAt);
            $body = self::decode($queryAt === false ? $body : substr($body, 0, $queryAt));
            if ($body === false) return null;
        }
        if (!preg_match('~^(.*@)(\[[^\]]+\]|[^:/?]+):[0-9]+(.*)$~s', $body, $endpoint)) return null;
        $address = $host === '' ? $endpoint[2] : $host;
        if (strpos($address, ':') !== false && $address[0] !== '[') $address = '[' . $address . ']';
        $body = $endpoint[1] . $address . ':' . $port . $endpoint[3];
        if ($legacy) $body = base64_encode($body) . $query;
        return $scheme . '://' . $body . '#' . rawurlencode($name);
    }

    private static function decode(string $value)
    {
        return base64_decode(strtr($value, '-_', '+/'), true);
    }
}
