<?php
/**
 * Promotions on subscription plans - the admin save.
 *
 * Included by public/xmplus-patch.php after requireAdmin(), in its global
 * scope, and borrows its helpers: db(), fail(), done(), setting(), putSetting()
 * and requireToken(). Every path ends in done() or fail().
 *
 * The plan form posts to the encoded /admin/plan/save first, always with the
 * LIST prices, then calls promo.save. So when this runs, package.price_option
 * holds the list prices the admin just typed: they are kept as `original` and
 * the discounted prices are written over price_option, which is what the
 * encoded checkout charges. PromoJob (bin/promos.php) writes `original` back
 * when the promotion ends. See app/Http/Models/Package.php for the shape.
 */

declare(strict_types=1);

const PROMO_SETTING = 'promo_plans';
const PROMO_CYCLES = ['onetime', 'month', 'quater', 'semiannual', 'annual', 'custom'];
const PROMO_MAX_PERCENT = 95;
const PROMO_MAX_GB = 1000;
const PROMO_MAX_DAYS = 365;

function promoMap(): array
{
    $decoded = json_decode((string) setting(PROMO_SETTING, ''), true);

    return is_array($decoded) ? $decoded : [];
}

function promoInt($value, int $fallback = 0): int
{
    return is_numeric($value) ? (int) $value : $fallback;
}

/** The price a cycle costs at a discount, rounded to a whole unit. */
function promoDiscounted($price, int $percent): string
{
    $clean = str_replace([',', ' ', '،'], '', (string) $price);

    if (!is_numeric($clean)) {
        return (string) $price;
    }

    return (string) (int) round((float) $clean * (100 - $percent) / 100);
}

/** price_option with every priced cycle discounted; `topup` and `expire` untouched. */
function promoApplyDiscount(array $options, int $percent): array
{
    foreach (PROMO_CYCLES as $cycle) {
        if (isset($options[$cycle]['price']) && $options[$cycle]['price'] !== '' && $options[$cycle]['price'] !== null) {
            $options[$cycle]['price'] = promoDiscounted($options[$cycle]['price'], $percent);
        }
    }

    return $options;
}

/** "2026-10-01T23:59" from a datetime-local input, read in the server's time zone. */
function promoEndsAt(string $raw): int
{
    $raw = trim($raw);

    if ($raw === '') {
        return 0;
    }

    $stamp = strtotime(str_replace('T', ' ', $raw));

    if ($stamp === false) {
        fail('the end date is not valid');
    }

    return $stamp;
}

/*
 * The list prices behind the plan's current price_option. Normally the encoded
 * save has just written them. If price_option still holds exactly the prices a
 * running discount produced, that save did not happen (or wrote the discounted
 * figures back), and the stored list prices are used instead - otherwise a
 * second save would discount the discount.
 */
function promoListPrices(array $package, ?array $previous): array
{
    $current = json_decode((string) $package['price_option'], true);
    $current = is_array($current) ? $current : [];

    if ($previous !== null && empty($previous['closed_at']) && ($previous['kind'] ?? '') === 'discount'
        && isset($previous['original']) && is_array($previous['original'])
        && promoApplyDiscount($previous['original'], (int) ($previous['percent'] ?? 0)) == $current) {
        return $previous['original'];
    }

    return $current;
}

function promoPackage(): array
{
    $id = promoInt($_POST['id'] ?? 0);

    if ($id > 0) {
        $statement = db()->prepare('SELECT * FROM package WHERE id = ? LIMIT 1');
        $statement->execute([$id]);
    } else {
        // a package that was just created: the encoded save does not return its id
        $name = trim((string) ($_POST['name'] ?? ''));

        if ($name === '') {
            fail('the package is not identified');
        }

        $statement = db()->prepare('SELECT * FROM package WHERE type = 2 AND name = ? ORDER BY id DESC LIMIT 1');
        $statement->execute([$name]);
    }

    $row = $statement->fetch();

    if ($row === false) {
        fail('that package was not found');
    }

    if ((int) $row['type'] !== 2) {
        fail('promotions are for subscription plans only');
    }

    return $row;
}

function promoSave(): void
{
    requireToken();

    $package = promoPackage();
    $id = (int) $package['id'];
    $key = (string) $id;
    $now = time();

    $map = promoMap();
    $previous = isset($map[$key]) && is_array($map[$key]) ? $map[$key] : null;
    $wasOpen = $previous !== null && empty($previous['closed_at']);

    $kind = (string) ($_POST['kind'] ?? 'none');
    if (!in_array($kind, ['none', 'discount', 'special'], true)) {
        $kind = 'none';
    }

    $prizeOn = !empty($_POST['prize_on']) && $_POST['prize_on'] !== '0';

    // nothing chosen: close a running promotion and make sure the list prices stand
    $original = promoListPrices($package, $previous);

    if ($kind === 'none' && !$prizeOn) {
        if ($wasOpen) {
            db()->prepare('UPDATE package SET price_option = ? WHERE id = ?')
                ->execute([(string) json_encode($original), $id]);

            $map[$key]['closed_at'] = $now;
            $map[$key]['closed_reason'] = 'admin';
            $map[$key]['end_told'] = 0;
            putSetting(PROMO_SETTING, (string) json_encode($map, JSON_UNESCAPED_UNICODE));
        }

        done(['packageid' => $id, 'running' => false]);
    }

    $percent = promoInt($_POST['percent'] ?? 0);

    if ($kind === 'discount' && ($percent < 1 || $percent > PROMO_MAX_PERCENT)) {
        fail('the discount must be between 1 and ' . PROMO_MAX_PERCENT . ' percent');
    }

    $prize = ['on' => 0];

    if ($prizeOn) {
        $mode = (string) ($_POST['prize_mode'] ?? 'either');
        if (!in_array($mode, ['gb', 'days', 'either'], true)) {
            $mode = 'either';
        }

        $prize = [
            'on'       => 1,
            'mode'     => $mode,
            'gb_min'   => promoInt($_POST['gb_min'] ?? 0),
            'gb_max'   => promoInt($_POST['gb_max'] ?? 0),
            'days_min' => promoInt($_POST['days_min'] ?? 0),
            'days_max' => promoInt($_POST['days_max'] ?? 0),
        ];

        if ($mode !== 'days' && ($prize['gb_min'] < 1 || $prize['gb_max'] < $prize['gb_min'] || $prize['gb_max'] > PROMO_MAX_GB)) {
            fail('the gigabyte range is not valid (1 to ' . PROMO_MAX_GB . ', minimum not above maximum)');
        }

        if ($mode !== 'gb' && ($prize['days_min'] < 1 || $prize['days_max'] < $prize['days_min'] || $prize['days_max'] > PROMO_MAX_DAYS)) {
            fail('the day range is not valid (1 to ' . PROMO_MAX_DAYS . ', minimum not above maximum)');
        }
    }

    $endsAt = promoEndsAt((string) ($_POST['ends_at'] ?? ''));

    if ($endsAt > 0 && $endsAt <= $now) {
        fail('the end date has already passed');
    }

    $maxSales = max(0, promoInt($_POST['max_sales'] ?? 0));

    if ($original === []) {
        fail('this plan has no prices yet');
    }

    $priced = false;
    foreach (PROMO_CYCLES as $cycle) {
        if (isset($original[$cycle]['price']) && $original[$cycle]['price'] !== '') {
            $priced = true;
        }
    }

    if ($kind === 'discount' && !$priced) {
        fail('this plan has no price to discount');
    }

    $entry = [
        'kind'       => $kind,
        'percent'    => $kind === 'discount' ? $percent : 0,
        'original'   => $original,
        'prize'      => $prize,
        'occasion'   => mb_substr(trim(strip_tags((string) ($_POST['occasion'] ?? ''))), 0, 300),
        'ends_at'    => $endsAt,
        'max_sales'  => $maxSales,
        'show_left'  => !empty($_POST['show_left']) && $_POST['show_left'] !== '0' ? 1 : 0,
        // tell every customer once (PromoJob, promo_broadcast); an edit does not repeat it
        'announce'   => !empty($_POST['announce']) && $_POST['announce'] !== '0' ? 1 : 0,
        'broadcast_done' => $wasOpen ? (int) ($previous['broadcast_done'] ?? 0) : 0,
        // post it in the promotion channel (promo_channel_id); PromoJob keeps the post up to date
        'channel'    => !empty($_POST['channel']) && $_POST['channel'] !== '0' ? 1 : 0,
        'channel_msg'  => $wasOpen ? (int) ($previous['channel_msg'] ?? 0) : 0,
        'channel_hash' => $wasOpen ? (string) ($previous['channel_hash'] ?? '') : '',
        // a promotion that is still running keeps counting from where it began
        'started_at' => $wasOpen ? (int) ($previous['started_at'] ?? $now) : $now,
        'start_told' => $wasOpen ? (int) ($previous['start_told'] ?? 0) : 0,
        'closed_at'  => 0,
        'closed_reason' => '',
        'end_told'   => 0,
        'updated_at' => $now,
    ];

    if ($maxSales > 0 && $wasOpen) {
        $sold = db()->prepare('SELECT COUNT(*) FROM orders WHERE packageid = ? AND status = 1 AND pay_date >= ?');
        $sold->execute([$id, $entry['started_at']]);

        if ((int) $sold->fetchColumn() >= $maxSales) {
            fail('this promotion has already sold that many - raise the limit or leave it empty');
        }
    }

    $options = $kind === 'discount' ? promoApplyDiscount($original, $percent) : $original;

    $map[$key] = $entry;

    // prices first: if the settings write failed, a later save repairs both
    db()->prepare('UPDATE package SET price_option = ? WHERE id = ?')
        ->execute([(string) json_encode($options), $id]);

    putSetting(PROMO_SETTING, (string) json_encode($map, JSON_UNESCAPED_UNICODE));

    done(['packageid' => $id, 'running' => true, 'prices' => $options]);
}

// ------------------------------------------------------- the channel setting

const PROMO_CHANNEL_SETTING = 'promo_channel_id';

/** "-1001234567890", or "@name" for a public channel */
function promoChannelId(string $raw): string
{
    $raw = trim($raw);

    if ($raw !== '' && !preg_match('~^(-?\d{5,20}|@[A-Za-z0-9_]{5,32})$~', $raw)) {
        fail('the channel id must be the numeric id (for example -1001234567890) or @name');
    }

    return $raw;
}

function promoTelegram(string $method, array $params): ?array
{
    $token = trim((string) setting('telegramtoken', ''));

    if ($token === '') {
        fail('the panel has no Telegram bot token (Settings → Telegram)');
    }

    $handle = curl_init('https://api.telegram.org/bot' . $token . '/' . $method);
    curl_setopt_array($handle, [
        CURLOPT_POST           => true,
        CURLOPT_POSTFIELDS     => http_build_query($params),
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_CONNECTTIMEOUT => 5,
        CURLOPT_TIMEOUT        => 10,
    ]);
    $body = curl_exec($handle);
    curl_close($handle);

    return $body === false ? null : json_decode((string) $body, true);
}

/* the settings card: current value, and the token its buttons need */
function promoChannelState(): void
{
    if (empty($_SESSION['patch_csrf'])) {
        $_SESSION['patch_csrf'] = bin2hex(random_bytes(24));
    }

    done([
        'token'   => $_SESSION['patch_csrf'],
        'channel' => (string) setting(PROMO_CHANNEL_SETTING, ''),
    ]);
}

function promoChannelSave(): void
{
    requireToken();

    $channel = promoChannelId((string) ($_POST['channel'] ?? ''));
    putSetting(PROMO_CHANNEL_SETTING, $channel);

    done(['channel' => $channel]);
}

/* one message to the channel, so the admin sees the bot may post there */
function promoChannelTest(): void
{
    requireToken();

    $channel = promoChannelId((string) ($_POST['channel'] ?? setting(PROMO_CHANNEL_SETTING, '')));

    if ($channel === '') {
        fail('enter the channel id first');
    }

    $reply = promoTelegram('sendMessage', [
        'chat_id' => $channel,
        'text'    => "✅ ربات سایت می‌تواند در این کانال پیام بفرستد.\nپروموشن‌هایی که «ارسال به کانال» دارند اینجا منتشر می‌شوند.",
    ]);

    if (!is_array($reply) || empty($reply['ok'])) {
        fail('Telegram refused: ' . (is_array($reply) ? (string) ($reply['description'] ?? 'unknown error') : 'no answer')
            . ' — the bot must be an admin of the channel with the right to post');
    }

    done(['sent' => true]);
}

// ---------------------------------------------------------------- dispatch

$promoAction = substr((string) ($_GET['do'] ?? ''), strlen('promo.'));

if (in_array($promoAction, ['save', 'channelsave', 'channeltest'], true) && $_SERVER['REQUEST_METHOD'] !== 'POST') {
    fail('this action needs POST', 405);
}

switch ($promoAction) {
    case 'save':
        promoSave();
    case 'channel':
        promoChannelState();
    case 'channelsave':
        promoChannelSave();
    case 'channeltest':
        promoChannelTest();
}

fail('unknown promotion action');
