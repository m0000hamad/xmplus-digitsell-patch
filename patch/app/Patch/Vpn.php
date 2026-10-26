<?php
/**
 * What every extra protocol on this panel shares: the derived login and its
 * password, the account checks, the direct-route (bypass) lists, and writing
 * into the panel's own tables.
 *
 * OpenVPN (app/Patch/Ovpn.php) and WireGuard (app/Patch/Wg.php) both require
 * this file. Nothing in here knows which protocol it is serving.
 *
 * The bypass lists are one setting set, edited on the OpenVPN settings card:
 * OpenVPN puts them in the customer's file as `route … net_gateway` lines,
 * WireGuard applies them on the server (ipset + a routing mark). The Xray
 * customers get the same lists from SubInfo.php when `xray_bypass` is on.
 *
 *   ovpn_bypass_iran    1 sends Iranian addresses outside the tunnel
 *   ovpn_bypass_custom  extra addresses, networks and domains, one per line
 *   ovpn_bypass_cache   the addresses those domains resolved to, written here
 */

declare(strict_types=1);

const VPN_PASS_ALPHABET = 'abcdefghjkmnpqrstuvwxyz23456789';
const VPN_BYPASS_MAX_LINES = 200;
const VPN_BYPASS_MAX_DOMAINS = 40;
// routes in one list. OpenVPN Connect (OpenVPN 3) refuses a profile over
// 262144 bytes as it counts them (64 per line, 16 + length per word): about
// 166 per route, so 1745 Iran routes failed with "profile is too large".
// 1200 routes stay near 205000 with the rest of the file.
const VPN_BYPASS_MAX_ROUTES = 1200;
const VPN_BYPASS_MIN_PREFIX = 8;
const VPN_IRAN_SOURCE = 'https://raw.githubusercontent.com/ipverse/rir-ip/master/country/ir/ipv4-aggregated.txt';

// ------------------------------------------------------------------ helpers

if (!function_exists('setting')) {
    function setting(string $name, ?string $fallback = null): ?string
    {
        try {
            $statement = db()->prepare('SELECT value FROM settings WHERE name = ? LIMIT 1');
            $statement->execute([$name]);
            $row = $statement->fetch(PDO::FETCH_ASSOC);
            return $row === false ? $fallback : (string) $row['value'];
        } catch (Throwable $e) {
            return $fallback;
        }
    }
}

if (!function_exists('putSetting')) {
    function putSetting(string $name, string $value): void
    {
        $exists = db()->prepare('SELECT 1 FROM settings WHERE name = ? LIMIT 1');
        $exists->execute([$name]);

        if ($exists->fetch() === false) {
            db()->prepare('INSERT INTO settings (name, value) VALUES (?, ?)')->execute([$name, $value]);
            return;
        }

        db()->prepare('UPDATE settings SET value = ? WHERE name = ?')->execute([$value, $name]);
    }
}

/** A setting as a string, or $fallback when it is unset or empty. */
function vpnSetting(string $name, string $fallback): string
{
    $value = setting($name, null);

    return $value === null || $value === '' ? $fallback : (string) $value;
}

/** expire_in is written in the panel's local time, so compare it there. */
function vpnTimezone(): void
{
    db(); // loads config/config.php, which fills $_ENV['timeZone']
    $zone = (string) ($_ENV['timeZone'] ?? '');
    if ($zone !== '' && in_array($zone, timezone_identifiers_list(), true)) {
        date_default_timezone_set($zone);
    }
}

function vpnLogin(int $userId): string
{
    return 'u' . $userId;
}

function vpnUserIdFromLogin(string $login): int
{
    return preg_match('~^u([1-9][0-9]{0,9})$~', trim($login), $match) ? (int) $match[1] : 0;
}

/**
 * The password a customer signs in with, derived from the account's uuid and
 * the protocol's secret setting, so resetting the subscription link in the
 * panel changes it too and nothing extra has to be stored. $setting names the
 * secret. User::ovpnPassword() must stay identical to this for OpenVPN.
 */
function vpnPassword(int $userId, string $uuid, string $setting): string
{
    $secret = vpnSetting($setting, '');

    if ($secret === '' || trim($uuid) === '') {
        return '';
    }

    $raw = hash_hmac('sha256', $userId . ':' . strtolower(trim($uuid)), $secret, true);
    $size = strlen(VPN_PASS_ALPHABET);
    $out = '';

    for ($i = 0; $i < 12; $i++) {
        $out .= VPN_PASS_ALPHABET[ord($raw[$i]) % $size];
    }

    return $out;
}

/** "3,8" -> [3, 8]; empty means every group. */
function vpnGroups($value): array
{
    $list = is_array($value) ? $value : explode(',', (string) $value);
    $ids = [];

    foreach ($list as $item) {
        $id = (int) trim((string) $item);
        if ($id > 0) {
            $ids[$id] = $id;
        }
    }

    return array_values($ids);
}

/** The address the node reported, unless the admin named another one. */
function vpnNodeHost(array $node): string
{
    $override = trim((string) ($node['host_override'] ?? ''));

    return $override !== '' ? $override : trim((string) $node['host']);
}

/** A host name that can carry a certificate: letters in it, not an IP. Lower case, or ''. */
function vpnDomainName(string $host): string
{
    $host = strtolower(trim($host));

    return strlen($host) <= 253
        && preg_match('~^([a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]([a-z0-9-]{0,61}[a-z0-9])?$~', $host) ? $host : '';
}

function vpnJsonBody(): array
{
    $raw = (string) file_get_contents('php://input');
    $body = json_decode($raw, true);

    if (!is_array($body)) {
        fail('the body must be a JSON object');
    }

    return $body;
}

/**
 * The columns of a panel table that the patch does not own. trafficlog and
 * online_ip belong to the encoded panel, so rows are written with whatever
 * columns are really there: unknown keys are dropped, and a NOT NULL column
 * without a default gets 0 or '' instead of failing the insert.
 */
function vpnColumns(string $table): array
{
    static $cache = [];

    if (!isset($cache[$table])) {
        $cache[$table] = [];
        try {
            foreach (db()->query('SHOW COLUMNS FROM `' . str_replace('`', '', $table) . '`') as $row) {
                $cache[$table][(string) $row['Field']] = $row;
            }
        } catch (Throwable $error) {
            $cache[$table] = [];
        }
    }

    return $cache[$table];
}

function vpnHasColumn(string $table, string $column): bool
{
    return isset(vpnColumns($table)[$column]);
}

/** Insert into a panel-owned table; $upsert columns are refreshed on a duplicate key. */
function vpnInsert(string $table, array $values, array $upsert = []): void
{
    $columns = vpnColumns($table);

    if ($columns === []) {
        return;
    }

    $row = [];

    foreach ($columns as $name => $column) {
        if (array_key_exists($name, $values)) {
            $row[$name] = $values[$name];
            continue;
        }

        $autoIncrement = stripos((string) $column['Extra'], 'auto_increment') !== false;
        $required = strtoupper((string) $column['Null']) === 'NO' && $column['Default'] === null;

        if ($required && !$autoIncrement) {
            $type = (string) $column['Type'];
            if (preg_match('~^(datetime|timestamp)~i', $type)) {
                $row[$name] = date('Y-m-d H:i:s');
            } elseif (preg_match('~^date~i', $type)) {
                $row[$name] = date('Y-m-d');
            } else {
                $row[$name] = preg_match('~int|decimal|float|double|bit|year~i', $type) ? 0 : '';
            }
        }
    }

    if ($row === []) {
        return;
    }

    $names = array_keys($row);
    $sql = sprintf('INSERT INTO `%s` (`%s`) VALUES (%s)', $table, implode('`, `', $names),
        implode(', ', array_fill(0, count($names), '?')));

    $refresh = [];
    foreach ($upsert as $name) {
        if (isset($row[$name])) {
            $refresh[] = sprintf('`%s` = VALUES(`%s`)', $name, $name);
        }
    }
    if ($refresh !== []) {
        $sql .= ' ON DUPLICATE KEY UPDATE ' . implode(', ', $refresh);
    }

    db()->prepare($sql)->execute(array_values($row));
}

function vpnBytesText(float $bytes): string
{
    $units = ['B', 'KB', 'MB', 'GB', 'TB'];
    $i = 0;

    while ($bytes >= 1024 && $i < count($units) - 1) {
        $bytes /= 1024;
        $i++;
    }

    return round($bytes, 2) . $units[$i];
}

function vpnNewKey(): string
{
    return bin2hex(random_bytes(24));
}

// -------------------------------------------------------------------- users

function vpnUser(int $id): ?array
{
    if ($id <= 0) {
        return null;
    }

    $statement = db()->prepare('SELECT * FROM user WHERE id = ? LIMIT 1');
    $statement->execute([$id]);
    $row = $statement->fetch(PDO::FETCH_ASSOC);

    return $row === false ? null : $row;
}

/**
 * Why this account may not use this node right now, or '' when it may. The
 * same reading of the account the admin dashboard uses: status 1 is active,
 * the plan runs until expire_in, and a quota is used up at u + d. $enabled is
 * the protocol's master switch and $node['enabled'] the server's.
 */
function vpnRefusal(?array $user, array $node, string $enabled): string
{
    if ($enabled !== '1') {
        return 'off';
    }

    if ((int) $node['enabled'] !== 1) {
        return 'node';
    }

    if ($user === null) {
        return 'account';
    }

    if (isset($user['status']) && (int) $user['status'] !== 1) {
        return 'disabled';
    }

    $expire = strtotime((string) ($user['expire_in'] ?? ''));
    if ($expire === false || $expire <= time()) {
        return 'expired';
    }

    $quota = (float) ($user['transfer_enable'] ?? 0);
    if ($quota > 0 && (float) $user['u'] + (float) $user['d'] >= $quota) {
        return 'quota';
    }

    if (!vpnNodeServes($node, $user)) {
        return 'group';
    }

    return '';
}

/**
 * A node serves an account only when its group is explicitly in the node's allowed_groups.
 * Empty node groups means no account can access this server until the admin assigns groups.
 */
function vpnNodeServes(array $node, array $user): bool
{
    $groups = vpnGroups($node['allowed_groups'] ?? '');
    if ($groups === []) {
        return false;
    }

    $userGroup = (int) ($user['server_group'] ?? 0);
    if ($userGroup > 0 && in_array($userGroup, $groups, true)) {
        return true;
    }

    if (!empty($user['user_group'])) {
        foreach (explode(',', (string) $user['user_group']) as $g) {
            $gid = (int) trim($g);
            if ($gid > 0 && in_array($gid, $groups, true)) {
                return true;
            }
        }
    }

    return false;
}

/**
 * The account's device limit, counted over the addresses the Xray nodes
 * reported in online_ip and the live sessions of this protocol
 * ($sessionTable). An address already connected does not count twice.
 */
function vpnOverIpLimit(array $user, string $ip, string $sessionTable, int $stale): bool
{
    $limit = (int) ($user['iplimit'] ?? 0);

    if ($limit <= 0) {
        return false;
    }

    $ips = [];

    try {
        $statement = db()->prepare('SELECT DISTINCT ip FROM online_ip WHERE userid = ? AND datetime >= ?');
        $statement->execute([(int) $user['id'], time() - 120]);
        foreach ($statement->fetchAll(PDO::FETCH_COLUMN) as $seen) {
            $ips[(string) $seen] = true;
        }
    } catch (Throwable $error) {
        // no online_ip table: count this protocol's sessions alone
    }

    try {
        $statement = db()->prepare('SELECT DISTINCT ip FROM ' . $sessionTable
            . ' WHERE userid = ? AND closed = 0 AND seen >= ?');
        $statement->execute([(int) $user['id'], time() - $stale]);
        foreach ($statement->fetchAll(PDO::FETCH_COLUMN) as $seen) {
            $ips[(string) $seen] = true;
        }
    } catch (Throwable $error) {
        // no session table yet
    }

    unset($ips['']);

    return !isset($ips[$ip]) && count($ips) >= $limit;
}

/** The logged-in customer, from the panel's own session. */
function vpnRequireUser(): array
{
    startPanelSession();

    $login = $_SESSION['login_session'] ?? null;

    if (!is_array($login) || empty($login['uid'])) {
        fail('login required', 403);
    }

    if (!empty($login['expire']) && (int) $login['expire'] < time()) {
        fail('session expired', 403);
    }

    $user = vpnUser((int) $login['uid']);

    if ($user === null) {
        fail('account not found', 403);
    }

    return $user;
}

// ------------------------------------------------------------------ bypass
/*
 * Addresses that go outside the tunnel. What goes there:
 *
 *   - the Iranian IPv4 ranges (ovpn_bypass_iran = 1), from
 *     app/Patch/data/iran-ipv4.txt or, once refreshed from the panel,
 *     storage/patch/iran-ipv4.txt
 *   - the extra list (ovpn_bypass_custom): one address, network (a.b.c.d/nn,
 *     nn 8 to 32) or domain per line, # starts a comment. A domain is looked up
 *     by the panel (here on saving, and every six hours from OvpnJob) and its
 *     addresses are put in the list, so a site behind a CDN that is not in the
 *     Iranian ranges can still be sent direct.
 *
 * OpenVPN writes them into the customer's file as `route <net> <mask>
 * net_gateway`; WireGuard applies them on the server.
 */

function vpnIranFile(): string
{
    $refreshed = ROOT . '/storage/patch/iran-ipv4.txt';

    return is_file($refreshed) ? $refreshed : __DIR__ . '/data/iran-ipv4.txt';
}

/** "a.b.c.d/nn" lines of a list -> [[network as int, prefix]], sorted, valid ones only. */
function vpnParseRanges(string $text): array
{
    $nets = [];

    foreach (preg_split('~\R~', $text) ?: [] as $line) {
        $line = trim(preg_replace('~\s*#.*$~', '', $line));

        if (!preg_match('~^(\d{1,3}(?:\.\d{1,3}){3})/(\d{1,2})$~', $line, $match)
            || filter_var($match[1], FILTER_VALIDATE_IP, FILTER_FLAG_IPV4) === false) {
            continue;
        }

        $bits = (int) $match[2];
        if ($bits < VPN_BYPASS_MIN_PREFIX || $bits > 32) {
            continue;
        }

        $mask = (0xFFFFFFFF << (32 - $bits)) & 0xFFFFFFFF;
        $network = ip2long($match[1]) & $mask;
        $nets[$network . '/' . $bits] = [$network, $bits];
    }

    $nets = array_values($nets);
    usort($nets, static function (array $a, array $b): int {
        return $a[0] <=> $b[0] ?: $a[1] <=> $b[1];
    });

    return $nets;
}

function vpnIranRanges(): array
{
    static $cache = null;

    if ($cache === null) {
        $file = vpnIranFile();
        $cache = is_file($file) ? vpnParseRanges((string) file_get_contents($file)) : [];
    }

    return $cache;
}

function vpnNetInside(array $net, array $outer): bool
{
    return $outer[1] <= $net[1] && ($net[0] & ((0xFFFFFFFF << (32 - $outer[1])) & 0xFFFFFFFF)) === $outer[0];
}

function vpnNetInAny(array $net, array $list): bool
{
    foreach ($list as $outer) {
        if (vpnNetInside($net, $outer)) {
            return true;
        }
    }

    return false;
}

function vpnDomainOk(string $name): bool
{
    return (bool) preg_match('~^(?=.{1,253}$)([a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z][a-z0-9-]{1,62}$~', $name);
}

/**
 * The extra list, line by line: ['nets' => [[int, prefix]], 'domains' => [name],
 * 'errors' => ["line 3: ..."]].
 */
function vpnBypassParse(string $text): array
{
    $out = ['nets' => [], 'domains' => [], 'errors' => []];
    $lines = preg_split('~\R~', $text) ?: [];

    if (count($lines) > VPN_BYPASS_MAX_LINES) {
        $out['errors'][] = 'at most ' . VPN_BYPASS_MAX_LINES . ' lines';
        return $out;
    }

    foreach ($lines as $number => $raw) {
        $line = strtolower(trim(preg_replace('~\s*#.*$~', '', $raw)));

        if ($line === '') {
            continue;
        }

        $where = 'line ' . ($number + 1) . ' (' . mb_substr($line, 0, 60) . ')';

        if (preg_match('~^(\d{1,3}(?:\.\d{1,3}){3})(?:/(\d{1,2}))?$~', $line, $match)) {
            $bits = isset($match[2]) && $match[2] !== '' ? (int) $match[2] : 32;

            if (filter_var($match[1], FILTER_VALIDATE_IP, FILTER_FLAG_IPV4) === false) {
                $out['errors'][] = $where . ': not an IPv4 address';
            } elseif ($bits < VPN_BYPASS_MIN_PREFIX || $bits > 32) {
                $out['errors'][] = $where . ': the prefix must be from ' . VPN_BYPASS_MIN_PREFIX . ' to 32';
            } else {
                $mask = (0xFFFFFFFF << (32 - $bits)) & 0xFFFFFFFF;
                $network = ip2long($match[1]) & $mask;
                $out['nets'][$network . '/' . $bits] = [$network, $bits];
            }
            continue;
        }

        // a domain; an accented one is converted to its ASCII form
        $name = $line;
        if (preg_match('~[^\x20-\x7e]~', $name) && function_exists('idn_to_ascii')) {
            $ascii = idn_to_ascii($name, IDNA_DEFAULT, INTL_IDNA_VARIANT_UTS46);
            $name = is_string($ascii) ? $ascii : $name;
        }

        if (vpnDomainOk($name)) {
            $out['domains'][$name] = $name;
        } else {
            $out['errors'][] = $where . ': not an address, a network or a domain';
        }
    }

    $out['nets'] = array_values($out['nets']);
    $out['domains'] = array_values($out['domains']);

    if (count($out['domains']) > VPN_BYPASS_MAX_DOMAINS) {
        $out['errors'][] = 'at most ' . VPN_BYPASS_MAX_DOMAINS . ' domains';
    }

    return $out;
}

/** The addresses each domain last resolved to: ['domain' => ['1.2.3.4']] and when. */
function vpnBypassCache(): array
{
    $decoded = json_decode(vpnSetting('ovpn_bypass_cache', ''), true);

    return [
        'at'    => is_array($decoded) ? (int) ($decoded['at'] ?? 0) : 0,
        'hosts' => is_array($decoded) && is_array($decoded['hosts'] ?? null) ? $decoded['hosts'] : [],
    ];
}

/** Look the domains up now, keeping what is known for one that does not answer. */
function vpnBypassResolve(array $domains): array
{
    $known = vpnBypassCache()['hosts'];
    $result = [];
    $deadline = microtime(true) + 25;
    $failed = [];

    foreach (array_slice($domains, 0, VPN_BYPASS_MAX_DOMAINS) as $domain) {
        $result[$domain] = isset($known[$domain]) && is_array($known[$domain]) ? $known[$domain] : [];

        if (microtime(true) > $deadline) {
            $failed[] = $domain;
            continue;
        }

        $ips = @gethostbynamel($domain);
        if (is_array($ips) && $ips !== []) {
            $result[$domain] = array_slice(array_values(array_unique($ips)), 0, 16);
        } elseif ($result[$domain] === []) {
            $failed[] = $domain;
        }
    }

    putSetting('ovpn_bypass_cache', $domains === [] ? '' : json_encode(['at' => time(), 'hosts' => $result]));

    return ['hosts' => $result, 'failed' => $failed];
}

/**
 * The networks that skip the tunnel: the custom ones, and as many Iran ranges
 * as the rest of VPN_BYPASS_MAX_ROUTES allows, largest first. A range left out
 * (the smallest; about 1.5% of Iran's addresses) goes through the tunnel, as
 * without the bypass; merging ranges instead would send foreign addresses
 * around the tunnel. $info: iran_total, iran_used, iran_share (0..1).
 */
function vpnBypassNets(?array &$info = null): array
{
    $iran = vpnSetting('ovpn_bypass_iran', '0') === '1' ? vpnIranRanges() : [];
    $custom = vpnBypassParse(vpnSetting('ovpn_bypass_custom', ''));
    $extra = [];

    $candidates = $custom['nets'];
    foreach (vpnBypassCache()['hosts'] as $domain => $ips) {
        if (!in_array($domain, $custom['domains'], true)) {
            continue; // a domain that is no longer on the list
        }
        foreach (is_array($ips) ? $ips : [] as $ip) {
            if (filter_var($ip, FILTER_VALIDATE_IP, FILTER_FLAG_IPV4) !== false) {
                $candidates[] = [ip2long($ip), 32];
            }
        }
    }
    foreach ($candidates as $net) {
        $extra[$net[0] . '/' . $net[1]] = $net;
    }

    // the custom entries always fit; the Iran ranges share what is left
    $extra = array_slice($extra, 0, VPN_BYPASS_MAX_ROUTES, true);
    $room = max(0, VPN_BYPASS_MAX_ROUTES - count($extra));
    $kept = $iran;
    if (count($kept) > $room) {
        usort($kept, static function (array $a, array $b): int {
            return $a[1] <=> $b[1] ?: $a[0] <=> $b[0]; // shorter prefix = larger range
        });
        $kept = array_slice($kept, 0, $room);
        usort($kept, static function (array $a, array $b): int {
            return $a[0] <=> $b[0];
        });
    }

    $all = 0;
    $used = 0;
    foreach ($iran as [, $bits]) {
        $all += 2 ** (32 - $bits);
    }
    foreach ($kept as [, $bits]) {
        $used += 2 ** (32 - $bits);
    }
    $info = [
        'iran_total' => count($iran),
        'iran_used'  => count($kept),
        'iran_share' => $all > 0 ? $used / $all : 0.0,
    ];

    $nets = $kept;
    foreach ($extra as $net) {
        // inside a range already in the list: nothing to add
        if ($kept === [] || !vpnNetInAny($net, $kept)) {
            $nets[] = $net;
        }
    }

    return $nets;
}

/** "a.b.c.d/nn" lines, the form both protocols apply (OpenVPN: with net_gateway). */
function vpnBypassCidrs(): array
{
    $lines = [];

    foreach (vpnBypassNets() as [$network, $bits]) {
        $mask = (0xFFFFFFFF << (32 - $bits)) & 0xFFFFFFFF;
        $lines[] = long2ip($network) . '/' . $bits;
    }

    return $lines;
}

/** The day the list was fetched, from its header (an update resets the file time). */
function vpnIranDate(string $file): string
{
    $head = is_file($file) ? (string) @file_get_contents($file, false, null, 0, 600) : '';

    return preg_match('~fetched (\d{4}-\d{2}-\d{2})~i', $head, $match) ? $match[1] : '';
}

function vpnBypassView(): array
{
    $file = vpnIranFile();
    $cache = vpnBypassCache();

    return [
        'iran'        => vpnSetting('ovpn_bypass_iran', '0') === '1',
        'custom'      => vpnSetting('ovpn_bypass_custom', ''),
        // the same list for Xray customers on Happ, through the subscription (SubInfo.php)
        'xray'        => vpnSetting('xray_bypass', '0') === '1',
        'iran_ranges' => count(vpnIranRanges()),
        'iran_date'   => vpnIranDate($file),
        'iran_source' => strpos($file, '/storage/') !== false ? 'refreshed' : 'shipped',
        'hosts'       => (object) $cache['hosts'],
        'resolved_at' => $cache['at'],
        'routes'      => count(vpnBypassNets($info)),
        // how many Iran ranges the list has room for (VPN_BYPASS_MAX_ROUTES)
        'iran_used'   => $info['iran_used'],
        'iran_share'  => round($info['iran_share'] * 100, 1),
    ];
}

/** Save the bypass lists. Both protocols' cards post here. */
function vpnBypassSave(): void
{
    requireAdmin();
    requireToken();

    $custom = str_replace("\r", '', (string) ($_POST['custom'] ?? ''));
    $parsed = vpnBypassParse($custom);

    if ($parsed['errors'] !== []) {
        fail(implode(' · ', array_slice($parsed['errors'], 0, 5)));
    }

    putSetting('ovpn_bypass_iran', !empty($_POST['iran']) && $_POST['iran'] !== '0' ? '1' : '0');
    putSetting('ovpn_bypass_custom', trim($custom));

    // turned off after being on: 'off' tells Happ to drop the profile it was given
    $xrayWas = vpnSetting('xray_bypass', '0');
    $xrayOn = !empty($_POST['xray']) && $_POST['xray'] !== '0';
    putSetting('xray_bypass', $xrayOn ? '1' : ($xrayWas === '0' ? '0' : 'off'));

    // the domains are looked up now, so the next file downloaded carries them
    $resolved = vpnBypassResolve($parsed['domains']);

    done(['bypass' => vpnBypassView(), 'failed' => $resolved['failed']]);
}

/** Fetch the Iranian ranges again and keep them under storage/patch. */
function vpnIranRefresh(): void
{
    requireAdmin();
    requireToken();

    $text = (string) fetch(VPN_IRAN_SOURCE);
    $ranges = vpnParseRanges($text);

    // a short or empty answer must never replace a good list
    if (count($ranges) < 500) {
        fail('the downloaded list looks wrong (' . count($ranges) . ' ranges); the current one is kept');
    }

    $dir = ROOT . '/storage/patch';
    if (!is_dir($dir) && !@mkdir($dir, 0755, true)) {
        fail('cannot create storage/patch');
    }

    $lines = ['# Iran (IR) IPv4 ranges from ' . VPN_IRAN_SOURCE . ' (CC0), fetched ' . date('Y-m-d H:i')];
    foreach ($ranges as [$network, $bits]) {
        $lines[] = long2ip($network) . '/' . $bits;
    }

    if (@file_put_contents($dir . '/iran-ipv4.txt.tmp', implode("\n", $lines) . "\n") === false
        || !@rename($dir . '/iran-ipv4.txt.tmp', $dir . '/iran-ipv4.txt')) {
        fail('cannot write storage/patch/iran-ipv4.txt');
    }

    done(['bypass' => vpnBypassView()]);
}

// --------------------------------------------------------------- telegram

/** Send a message to the admin chats, the way the jobs do; per chat: 'sent' or Telegram's reason. */
function vpnTelegram(string $text): array
{
    $token = trim(vpnSetting('telegramtoken', ''));
    $chats = trim(vpnSetting('tgjoin_admin_chats', ''));
    if ($chats === '') {
        $chats = trim(vpnSetting('telegramchatid', ''));
    }

    if ($token === '') {
        fail('the panel has no Telegram bot token (settings: telegramtoken)');
    }
    if ($chats === '') {
        fail('no admin chat: set the panel Telegram chat id (telegramchatid) or tgjoin_admin_chats');
    }

    $results = [];
    foreach (preg_split('~[\s,]+~', $chats, -1, PREG_SPLIT_NO_EMPTY) as $chat) {
        $handle = curl_init('https://api.telegram.org/bot' . $token . '/sendMessage');
        curl_setopt_array($handle, [
            CURLOPT_POST           => true,
            CURLOPT_POSTFIELDS     => http_build_query(['chat_id' => $chat, 'text' => $text]),
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_CONNECTTIMEOUT => 5,
            CURLOPT_TIMEOUT        => 10,
        ]);
        $body = curl_exec($handle);
        $error = curl_error($handle);
        curl_close($handle);

        $reply = is_string($body) ? json_decode($body, true) : null;
        $results[$chat] = !empty($reply['ok']) ? 'sent'
            : ($body === false ? 'cannot reach Telegram: ' . $error : (string) ($reply['description'] ?? 'unreadable answer'));
    }

    return $results;
}

/** The test button on either protocol's settings card. */
function vpnNotifyTest(string $what): void
{
    requireAdmin();
    requireToken();

    done(['results' => vpnTelegram("✅ آزمایش پیام سرورهای {$what}\n"
        . "این پیام از پنل فرستاده شد؛ پیام‌های آنلاین و آفلاین شدن سرورها به همین‌جا می‌آید.")]);
}