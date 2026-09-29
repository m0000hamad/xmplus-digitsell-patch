<?php
/**
 * Subscription link with a status on top - what the client apps show.
 *
 * Included by public/xmplus-patch.php for `?do=sub`, before any session or
 * admin check: the token in the link is the only credential, exactly as on the
 * panel's own /link/<token>. Borrows db() and setting().
 *
 * The panel's subscription output is encoded and cannot be changed, so this
 * fetches it from the panel itself (/link/<token>?<same query>), passes its
 * headers through, and puts a few information-only rows first. Their names are
 * the message - Solar Hijri end date, data left, charge wallet balance, and
 * "update the subscription to see the live balance". The rows point at
 * 127.0.0.1:1, so picking one by mistake connects nowhere.
 *
 *   https://<host>/xmplus-patch.php?do=sub&t=<token>&config=1
 *
 * Anything that goes wrong sends the app to the panel's own link instead, so a
 * customer never ends up with less than they had.
 */

declare(strict_types=1);

const SUBINFO_GB = 1073741824;
const SUBINFO_ZONE = 'Asia/Tehran';
const SUBINFO_MONTHS = ['فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور',
    'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند'];

/** Response headers of the panel's link that are passed on unchanged. */
const SUBINFO_PASS = ['subscription-userinfo', 'profile-title', 'profile-update-interval',
    'profile-web-page-url', 'support-url', 'content-disposition', 'content-type', 'announce',
    'routing', 'providerid', 'update-always', 'hide-settings'];

function subinfoFa(string $text): string
{
    return strtr($text, ['0' => '۰', '1' => '۱', '2' => '۲', '3' => '۳', '4' => '۴',
        '5' => '۵', '6' => '۶', '7' => '۷', '8' => '۸', '9' => '۹', ',' => '٬', '.' => '٫']);
}

/** "۱۲ آبان ۱۴۰۵" on Tehran time; same arithmetic as Package::jalaliParts(). */
function subinfoJalali(int $stamp, bool $withTime = false): string
{
    $at = (new DateTime('@' . $stamp))->setTimezone(new DateTimeZone(SUBINFO_ZONE));
    $gy = (int) $at->format('Y');
    $gm = (int) $at->format('n');
    $gd = (int) $at->format('j');

    $days = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];
    $gy2 = $gm > 2 ? $gy + 1 : $gy;
    $total = 355666 + 365 * $gy + intdiv($gy2 + 3, 4) - intdiv($gy2 + 99, 100)
        + intdiv($gy2 + 399, 400) + $gd + $days[$gm - 1];

    $jy = -1595 + 33 * intdiv($total, 12053);
    $total %= 12053;
    $jy += 4 * intdiv($total, 1461);
    $total %= 1461;
    if ($total > 365) {
        $jy += intdiv($total - 1, 365);
        $total = ($total - 1) % 365;
    }
    $jm = $total < 186 ? 1 + intdiv($total, 31) : 7 + intdiv($total - 186, 30);
    $jd = 1 + ($total < 186 ? $total % 31 : ($total - 186) % 30);

    $text = $jd . ' ' . SUBINFO_MONTHS[$jm - 1] . ' ' . $jy;
    if ($withTime) {
        $text .= ' ' . $at->format('H:i');
    }

    return subinfoFa($text);
}

function subinfoTime(int $stamp): string
{
    return subinfoFa((new DateTime('@' . $stamp))->setTimezone(new DateTimeZone(SUBINFO_ZONE))->format('H:i'));
}

function subinfoGb(float $bytes): string
{
    $gb = max(0.0, $bytes) / SUBINFO_GB;

    if ($gb < 1) {
        return subinfoFa((string) (int) round($gb * 1024)) . ' مگ';
    }

    return subinfoFa(rtrim(rtrim(number_format($gb, 1, '.', ''), '0'), '.')) . ' گیگ';
}

function subinfoMoney(float $rial): string
{
    return setting('payg_show_toman', '1') === '0'
        ? subinfoFa(number_format(round($rial))) . ' ریال'
        : subinfoFa(number_format(round($rial / 10))) . ' تومان';
}

// ------------------------------------------------------------------ upstream

/** Query of this request minus our own parameters, as "?a=b" or "". */
function subinfoQuery(): string
{
    $query = $_GET;
    unset($query['do'], $query['t']);

    return $query ? '?' . http_build_query($query) : '';
}

/** The public host the app used, falling back to the `sub_host` setting. */
function subinfoHost(): string
{
    $host = trim((string) setting('sub_host', ''));
    if ($host === '') {
        $host = (string) ($_SERVER['HTTP_HOST'] ?? '');
    }

    return preg_match('~^[A-Za-z0-9.-]+(:\d+)?$~', $host) ? $host : 'localhost';
}

/**
 * The panel's own link for the same token and query, as fetched from here:
 * `sub_origin` (e.g. https://origin.example.com) when set, else the host the
 * app used.
 */
function subinfoOrigin(string $token): string
{
    $base = rtrim(trim((string) setting('sub_origin', '')), '/');

    if (!preg_match('~^https?://[A-Za-z0-9.-]+(:\d+)?$~', $base)) {
        $base = 'https://' . subinfoHost();
    }

    return $base . '/link/' . $token . subinfoQuery();
}

/** Go back to the panel's own public link: never leave the app with nothing. */
function subinfoBail(string $token): void
{
    header_remove('Content-Type');
    header('Location: https://' . subinfoHost() . '/link/' . $token . subinfoQuery(), true, 302);
    exit;
}

/**
 * Fetches the panel's link. The request is pinned to this machine
 * (`sub_origin_ip`, 127.0.0.1 by default) so it does not go out through the CDN
 * and back; the TLS name is still the public one, so the certificate checks.
 */
function subinfoFetch(string $url): ?array
{
    $headers = [];
    $host = (string) parse_url($url, PHP_URL_HOST);
    $pin = trim((string) setting('sub_origin_ip', '127.0.0.1'));

    foreach ($pin === '' ? [false] : [true, false] as $pinned) {
        $headers = [];
        $handle = curl_init($url);
        $options = [
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_FOLLOWLOCATION => false,
            CURLOPT_CONNECTTIMEOUT => 5,
            CURLOPT_TIMEOUT => 15,
            CURLOPT_USERAGENT => (string) ($_SERVER['HTTP_USER_AGENT'] ?? 'xmplus-subinfo'),
            CURLOPT_HTTPHEADER => ['X-Sub-Raw: 1', 'Accept: */*'],
            CURLOPT_HEADERFUNCTION => static function ($curl, string $line) use (&$headers): int {
                $parts = explode(':', $line, 2);
                if (count($parts) === 2) {
                    $headers[strtolower(trim($parts[0]))] = trim($parts[1]);
                }
                return strlen($line);
            },
        ];

        if ($pinned && $host !== '' && strpos($url, 'https://') === 0) {
            $options[CURLOPT_RESOLVE] = [$host . ':443:' . $pin];
        }

        curl_setopt_array($handle, $options);
        $body = curl_exec($handle);
        $status = (int) curl_getinfo($handle, CURLINFO_RESPONSE_CODE);
        curl_close($handle);

        if (is_string($body) && $status === 200 && $body !== '') {
            return ['body' => $body, 'headers' => $headers];
        }
    }

    return null;
}

// --------------------------------------------------------------------- user

/**
 * Whose link is this. Every config in the answer carries the account's uuid,
 * so that is matched first; a `token` column on user or a `link` table are
 * tried as well, for installs where they exist.
 */
function subinfoUser(string $token, string $plain): ?array
{
    $fields = 'id, transfer_enable, u, d, expire_in, plan';

    $text = $plain;
    // vmess:// carries its settings as base64 JSON
    if (preg_match_all('~vmess://([A-Za-z0-9+/=_-]+)~', $plain, $vmess)) {
        foreach ($vmess[1] as $chunk) {
            $text .= "\n" . (string) base64_decode(strtr($chunk, '-_', '+/'), false);
        }
    }

    if (preg_match_all('~[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}~i', $text, $found)) {
        $uuids = array_slice(array_values(array_unique(array_map('strtolower', $found[0]))), 0, 20);
        $marks = implode(',', array_fill(0, count($uuids), '?'));

        try {
            $statement = db()->prepare("SELECT {$fields} FROM user WHERE LOWER(uuid) IN ({$marks}) LIMIT 2");
            $statement->execute($uuids);
            $rows = $statement->fetchAll();

            if (count($rows) === 1) {
                return $rows[0];
            }
        } catch (Throwable $error) {
        }
    }

    foreach (["SELECT {$fields} FROM user WHERE token = ? LIMIT 2",
              "SELECT {$fields} FROM user WHERE id = (SELECT userid FROM link WHERE token = ? LIMIT 1)"] as $sql) {
        try {
            $statement = db()->prepare($sql);
            $statement->execute([$token]);
            $rows = $statement->fetchAll();

            if (count($rows) === 1) {
                return $rows[0];
            }
        } catch (Throwable $error) {
        }
    }

    return null;
}

function subinfoWallet(int $userId): ?array
{
    try {
        $statement = db()->prepare('SELECT balance, mode, auto FROM payg_wallet WHERE userid = ? LIMIT 1');
        $statement->execute([$userId]);
        $row = $statement->fetch();

        return $row === false ? null : $row;
    } catch (Throwable $error) {
        return null;
    }
}

// ------------------------------------------------------------------ message

/** The rows' names, top to bottom. */
function subinfoLines(array $user): array
{
    $now = time();
    $expire = $user['expire_in'] ? (int) strtotime((string) $user['expire_in']) : 0;
    $quota = (float) $user['transfer_enable'];
    $used = (float) $user['u'] + (float) $user['d'];
    $left = max(0.0, $quota - $used);

    $walletOn = setting('payg_enabled', '0') === '1';
    $wallet = $walletOn ? subinfoWallet((int) $user['id']) : null;
    $mode = $wallet ? (string) $wallet['mode'] : 'plan';
    $balance = $wallet ? (float) $wallet['balance'] : 0.0;

    $lines = [];

    if ($mode === 'balance') {
        $lines[] = '⚡ بسته تمام شده؛ مصرف از موجودی کسر می‌شود';
    } elseif ($mode === 'empty') {
        $lines[] = '⛔ موجودی تمام شد؛ از سایت حساب را شارژ کنید';
    } elseif ($expire > 0 && $expire <= $now) {
        $lines[] = '⛔ بسته تمام شده (' . subinfoJalali($expire) . ')؛ تمدید یا شارژ کنید';
    } else {
        $never = ($user['plan'] ?? '') === 'onetime' || $expire > strtotime('+10 years');

        if ($never) {
            $lines[] = '📅 بسته بدون تاریخ انقضا';
        } elseif ($expire > 0) {
            $days = (int) ceil(($expire - $now) / 86400);
            $lines[] = '📅 پایان بسته: ' . subinfoJalali($expire) . ' (' . subinfoFa((string) $days) . ' روز مانده)';
        }

        $lines[] = $quota > 0 && $left <= 0
            ? '📦 حجم بسته تمام شده'
            : '📦 حجم باقی‌مانده: ' . subinfoGb($left) . ' از ' . subinfoGb($quota);
    }

    if ($walletOn) {
        $lines[] = '💰 موجودی شارژ: ' . subinfoMoney($balance);
    }

    $lines[] = '🔄 به‌روز شده ' . subinfoTime($now) . '؛ برای موجودی لحظه‌ای، اشتراک را آپدیت کنید';

    return $lines;
}

function subinfoRow(string $name, int $i): string
{
    return sprintf('vless://00000000-0000-4000-8000-%012d@127.0.0.1:1?encryption=none&type=tcp#%s',
        $i + 1, rawurlencode($name));
}

// --------------------------------------------------------------------- main

$subToken = (string) ($_GET['t'] ?? '');

if (!preg_match('~^[A-Za-z0-9_-]{6,128}$~', $subToken)) {
    http_response_code(403);
    exit;
}

$config = $_GET['config'] ?? null;
if ($config !== null && !preg_match('~^[A-Za-z0-9_-]{1,32}$~', (string) $config)) {
    subinfoBail($subToken);
}

$upstream = subinfoFetch(subinfoOrigin($subToken));

if ($upstream === null) {
    subinfoBail($subToken);
}

$raw = trim($upstream['body']);
$decoded = base64_decode(strtr((string) preg_replace('~\s+~', '', $raw), '-_', '+/'), true);
$isBase64 = $decoded !== false && strpos($decoded, '://') !== false;
$plain = $isBase64 ? $decoded : $raw;

// only URI lists get rows; Clash YAML and sing-box JSON pass through untouched
$isList = (bool) preg_match('~^[a-z0-9+.-]+://~im', $plain)
    && strpos(ltrim($plain), '{') !== 0
    && !preg_match('~^\s*(proxies|port|mixed-port)\s*:~m', $plain);

$user = subinfoUser($subToken, $plain);
$lines = $user !== null && setting('sub_info_enabled', '1') !== '0' ? subinfoLines($user) : [];

header_remove('Content-Type');
header('Content-Type: text/plain; charset=utf-8');
foreach ($upstream['headers'] as $name => $value) {
    // an HTML type would make some apps treat the list as a web page
    if ($name === 'content-type' && stripos($value, 'text/html') !== false) {
        continue;
    }
    if (in_array($name, SUBINFO_PASS, true)) {
        header($name . ': ' . $value);
    }
}

if ($user !== null && $lines !== []) {
    // Happ shows this text above the server list
    header('announce: base64:' . base64_encode(implode("\n", $lines)));

    // on the wallet the expiry is the billing job's, a day ahead; do not show it
    $wallet = setting('payg_enabled', '0') === '1' ? subinfoWallet((int) $user['id']) : null;
    if ($wallet && (string) $wallet['mode'] !== 'plan') {
        header(sprintf('subscription-userinfo: upload=%d; download=%d; total=%d; expire=0',
            (int) $user['u'], (int) $user['d'], (int) $user['transfer_enable']));
    }
}

if (!$isList || $lines === []) {
    echo $upstream['body'];
    exit;
}

$rows = [];
foreach ($lines as $i => $line) {
    $rows[] = subinfoRow($line, $i);
}

$ua = strtolower((string) ($_SERVER['HTTP_USER_AGENT'] ?? ''));
$head = implode("\n", $rows) . "\n";

// Shadowrocket reads a first STATUS= line as the subscription's status text
if (strpos($ua, 'shadowrocket') !== false) {
    $head = 'STATUS=' . implode(' | ', $lines) . "\n" . $head;
}

$out = $head . $plain;

echo $isBase64 ? base64_encode($out) : $out;
exit;
