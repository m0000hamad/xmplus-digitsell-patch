<?php
/**
 * Card-to-card payments.
 *
 * This file is included by public/xmplus-patch.php, in its global scope, and
 * borrows that file's helpers: db(), fail(), done(), setting(), putSetting(),
 * startPanelSession(), requireAdmin() and requireToken(). It never returns -
 * every path ends in done(), fail(), or (for the Telegram decision page) an
 * HTML response with exit.
 *
 * Why it exists: the panel's payment drivers are ionCube encoded, so a new
 * gateway cannot be added to `/portal/order/pay`. What can be patched is the
 * page around it. The customer's order is created by the panel's own checkout
 * and stays unpaid; the checkout page offers "card to card" as an extra choice,
 * and the customer records the transfer here. An administrator approves it in
 * Settings -> Card to card, or with the two buttons the Telegram message
 * carries; approval marks the order paid and grants what it bought.
 *
 * The panel's own paid-order pipeline is encoded, so the grant is done here for
 * a normal plan / top-up. Time plans, reserved plans and pay-as-you-go charges
 * already have jobs that watch for `orders.status = 1` and grant themselves;
 * this file only marks those orders paid and lets those jobs run.
 *
 * Cards rotate: each carries its own cap (amount and/or number of payments,
 * measured per day / per month / in total), and the checkout always shows the
 * first enabled card in sort order that still has room.
 */
declare(strict_types=1);

/** how long a Telegram approve/reject link keeps working */
const C2C_TOKEN_TTL = 604800;

const C2C_GB = 1073741824;

const C2C_MARKER_TIME = '"timeplan"';
const C2C_MARKER_CHARGE = '"paygcharge"';
const C2C_MARKER_RESERVE = '"planreserve"';

// ------------------------------------------------------------------ helpers

function c2cSetting(string $name, string $fallback = ''): string
{
    $value = setting($name, null);

    return $value === null || $value === '' ? $fallback : (string) $value;
}

function c2cEnabled(): bool
{
    return c2cSetting('c2c_enabled', '0') === '1';
}

/** The Telegram support handle shown to buyers (default: the shop's own). */
function c2cSupport(): string
{
    $value = trim(c2cSetting('c2c_support', '@digitsellshop'));

    if ($value === '') {
        $value = '@digitsellshop';
    }

    if ($value[0] !== '@' && !preg_match('~^(https?://|t\.me/)~i', $value)) {
        $value = '@' . ltrim($value, '@');
    }

    return $value;
}

function c2cInt($value, int $fallback = 0): int
{
    return is_numeric($value) ? (int) $value : $fallback;
}

function c2cHours(string $name, int $fallback): int
{
    $hours = c2cInt(c2cSetting($name, (string) $fallback), $fallback);

    if ($hours < 0) {
        $hours = 0;
    }

    return min($hours, 8760);
}

function c2cDigits(string $value): string
{
    $digits = preg_replace('~\D+~', '', $value);

    return is_string($digits) ? $digits : '';
}

/** "6037 9911 2233 4455" */
function c2cCardNumber(string $value): string
{
    $digits = c2cDigits($value);

    return $digits === '' ? '' : implode(' ', str_split($digits, 4));
}

function c2cLast4(string $value): string
{
    $digits = c2cDigits($value);

    return strlen($digits) >= 4 ? substr($digits, -4) : $digits;
}

function c2cPeriodStart(string $period): int
{
    if ($period === 'total') {
        return 0;
    }

    if ($period === 'month') {
        return (int) strtotime('first day of this month 00:00:00');
    }

    return (int) strtotime('today 00:00:00');
}

/**
 * What this card has actually taken in the current window.
 *
 * Only settled (approved) requests count: a pending request is a claim, not
 * money received, and a pile of abandoned test submissions must not keep a card
 * "full" forever. The cap is the bank's, and it is about money that arrived.
 */
function c2cCardUsage(int $cardId, string $period): array
{
    $sql = 'SELECT COUNT(*) AS n, COALESCE(SUM(amount), 0) AS s
              FROM c2c_request
             WHERE cardid = ? AND status = 1';
    $args = [$cardId];

    $from = c2cPeriodStart($period);
    if ($from > 0) {
        $sql .= ' AND updated >= ?';
        $args[] = $from;
    }

    try {
        $statement = db()->prepare($sql);
        $statement->execute($args);
        $row = $statement->fetch();
    } catch (Throwable $error) {
        return ['count' => 0, 'amount' => 0.0];
    }

    return [
        'count'  => (int) ($row['n'] ?? 0),
        'amount' => (float) ($row['s'] ?? 0),
    ];
}

function c2cCardHasRoom(array $card): bool
{
    $usage = c2cCardUsage((int) $card['id'], (string) $card['limit_period']);

    $limitAmount = (float) $card['limit_amount'];
    $limitCount = (int) $card['limit_count'];

    if ($limitAmount > 0 && $usage['amount'] >= $limitAmount) {
        return false;
    }

    if ($limitCount > 0 && $usage['count'] >= $limitCount) {
        return false;
    }

    return true;
}

function c2cCards(bool $onlyEnabled = false): array
{
    $sql = 'SELECT * FROM c2c_card';
    if ($onlyEnabled) {
        $sql .= ' WHERE enabled = 1';
    }
    $sql .= ' ORDER BY sort ASC, id ASC';

    try {
        return db()->query($sql)->fetchAll();
    } catch (Throwable $error) {
        return [];
    }
}

function c2cCardById(int $id): ?array
{
    if ($id <= 0) {
        return null;
    }

    try {
        $statement = db()->prepare('SELECT * FROM c2c_card WHERE id = ? LIMIT 1');
        $statement->execute([$id]);
        $row = $statement->fetch();
    } catch (Throwable $error) {
        return null;
    }

    return $row === false ? null : $row;
}

/** The first enabled card in order that still has room, or null. */
function c2cActiveCard(): ?array
{
    foreach (c2cCards(true) as $card) {
        if (c2cCardHasRoom($card)) {
            return $card;
        }
    }

    return null;
}

/** An enabled card whose number ends with these four digits. */
function c2cCardByLast4(string $last4): ?array
{
    if (strlen($last4) !== 4) {
        return null;
    }

    foreach (c2cCards(true) as $card) {
        if (c2cLast4((string) $card['number']) === $last4) {
            return $card;
        }
    }

    return null;
}

// -------------------------------------------------------------------- auth

function c2cRequireUser(): array
{
    startPanelSession();

    $login = $_SESSION['login_session'] ?? null;

    if (!is_array($login) || empty($login['uid'])) {
        fail('login required', 403);
    }

    if (!empty($login['expire']) && (int) $login['expire'] < time()) {
        fail('session expired', 403);
    }

    $statement = db()->prepare(
        'SELECT id, username, email, expire_in, transfer_enable, u, d, used, plan
           FROM user WHERE id = ? LIMIT 1');
    $statement->execute([(int) $login['uid']]);
    $user = $statement->fetch();

    if ($user === false) {
        fail('account not found', 403);
    }

    return $user;
}

function c2cUserToken(): string
{
    if (empty($_SESSION['c2c_csrf'])) {
        $_SESSION['c2c_csrf'] = bin2hex(random_bytes(24));
    }

    return (string) $_SESSION['c2c_csrf'];
}

function c2cRequireUserToken(): void
{
    $sent = $_POST['token'] ?? '';
    $held = $_SESSION['c2c_csrf'] ?? '';

    if ($held === '' || !is_string($sent) || !hash_equals($held, $sent)) {
        fail('bad or missing token', 403);
    }
}

// ------------------------------------------------------------------ orders

function c2cOrder(int $orderId, int $userId): ?array
{
    if ($orderId <= 0) {
        return null;
    }

    try {
        $statement = db()->prepare(
            'SELECT o.*, p.name AS package_name, p.type AS package_type,
                    p.bandwidth AS package_bandwidth, p.server_group AS package_group,
                    p.iplimit AS package_iplimit, p.speedlimit AS package_speedlimit,
                    p.order_note AS package_note, p.renew_type AS package_renew
               FROM orders o
               LEFT JOIN package p ON p.id = o.packageid
              WHERE o.id = ? AND o.userid = ?
              LIMIT 1');
        $statement->execute([$orderId, $userId]);
        $row = $statement->fetch();
    } catch (Throwable $error) {
        return null;
    }

    return $row === false ? null : $row;
}

function c2cRequestForOrder(int $orderId): ?array
{
    try {
        $statement = db()->prepare('SELECT * FROM c2c_request WHERE orderid = ? LIMIT 1');
        $statement->execute([$orderId]);
        $row = $statement->fetch();
    } catch (Throwable $error) {
        return null;
    }

    return $row === false ? null : $row;
}

function c2cRequestById(int $id): ?array
{
    try {
        $statement = db()->prepare('SELECT * FROM c2c_request WHERE id = ? LIMIT 1');
        $statement->execute([$id]);
        $row = $statement->fetch();
    } catch (Throwable $error) {
        return null;
    }

    return $row === false ? null : $row;
}

/**
 * Whether approval knows how to grant this order: a normal top-up or
 * subscription, or one of the marked packages whose own job takes over.
 */
function c2cOrderPayable(array $order): bool
{
    $note = (string) ($order['package_note'] ?? '');

    foreach ([C2C_MARKER_TIME, C2C_MARKER_CHARGE, C2C_MARKER_RESERVE] as $marker) {
        if (strpos($note, $marker) !== false) {
            return true;
        }
    }

    return in_array((int) ($order['packagetype'] ?? 0), [1, 2], true);
}

/** The request without its private token, safe to hand to the browser. */
function c2cPresent(?array $row): ?array
{
    if ($row === null) {
        return null;
    }

    return [
        'id'         => (int) $row['id'],
        'orderid'    => (int) $row['orderid'],
        'cardid'     => (int) $row['cardid'],
        'amount'     => (float) $row['amount'],
        'plan_name'  => (string) $row['plan_name'],
        'plan_cycle' => (string) $row['plan_cycle'],
        'plan_days'  => (int) $row['plan_days'],
        'last4'      => (string) $row['last4'],
        'payer'      => (string) $row['payer'],
        'paid_at'    => (string) $row['paid_at'],
        'ref'        => (string) $row['ref'],
        'status'     => (int) $row['status'],
        'note'       => (string) $row['note'],
        'created'    => (int) $row['created'],
        'decided_at' => (int) $row['decided_at'],
    ];
}

function c2cPresentCard(?array $card): ?array
{
    if ($card === null) {
        return null;
    }

    return [
        'id'        => (int) $card['id'],
        'number'    => c2cDigits((string) $card['number']),
        'formatted' => c2cCardNumber((string) $card['number']),
        'holder'    => (string) $card['holder'],
        'bank'      => (string) $card['bank'],
        'note'      => (string) $card['note'],
        'last4'     => c2cLast4((string) $card['number']),
    ];
}

// ----------------------------------------------------------------- telegram

function c2cTelegramToken(): string
{
    return trim(c2cSetting('telegramtoken', ''));
}

function c2cChats(): array
{
    $raw = trim(c2cSetting('c2c_telegram_chat', ''));

    if ($raw === '') {
        $raw = trim(c2cSetting('telegramchatid', ''));
    }

    if ($raw === '') {
        return [];
    }

    return array_values(array_filter(preg_split('~[\s,]+~', $raw, -1, PREG_SPLIT_NO_EMPTY) ?: []));
}

function c2cSiteUrl(): string
{
    $configured = trim(c2cSetting('c2c_site_url', ''));
    if ($configured !== '') {
        return rtrim($configured, '/');
    }

    foreach (['appName', 'baseUrl'] as $name) {
        $value = trim(c2cSetting($name, ''));

        if ($value === '') {
            continue;
        }

        if (preg_match('~^https?://~i', $value)) {
            return rtrim($value, '/');
        }

        if (strpos($value, '.') !== false && !preg_match('~\s~', $value)) {
            return 'https://' . rtrim($value, '/');
        }
    }

    $host = (string) ($_SERVER['HTTP_HOST'] ?? '');

    return $host === '' ? '' : 'https://' . $host;
}

function c2cDecideUrl(array $row, string $act): string
{
    return c2cSiteUrl() . '/xmplus-patch.php?do=c2c.decide'
        . '&id=' . (int) $row['id']
        . '&act=' . urlencode($act)
        . '&t=' . urlencode((string) $row['token']);
}

function c2cApi(string $method, array $params): ?array
{
    return c2cApiWith(c2cTelegramToken(), $method, $params);
}

function c2cApiWith(string $token, string $method, array $params): ?array
{
    if ($token === '') {
        return null;
    }

    $ch = curl_init('https://api.telegram.org/bot' . $token . '/' . $method);
    curl_setopt_array($ch, [
        CURLOPT_POST           => true,
        CURLOPT_POSTFIELDS     => http_build_query($params),
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_CONNECTTIMEOUT => 4,
        CURLOPT_TIMEOUT        => 6,
    ]);

    $body = curl_exec($ch);
    curl_close($ch);

    return $body === false ? null : json_decode($body, true);
}

/** The optional bot dedicated to card-to-card approvals. */
function c2cBotToken(): string
{
    return trim(c2cSetting('c2c_bot_token', ''));
}

function c2cBotSecret(): string
{
    return trim(c2cSetting('c2c_bot_secret', ''));
}

/**
 * How the dedicated bot receives taps. `poll` is the default: the panel pulls
 * updates from Telegram, so no inbound webhook is needed and a CDN that blocks
 * Telegram's servers cannot break it. `webhook` answers instantly but needs
 * Telegram to reach this host.
 */
function c2cBotMode(): string
{
    return c2cSetting('c2c_bot_mode', 'poll') === 'webhook' ? 'webhook' : 'poll';
}

/** The bot that talks to the admin: the dedicated one when configured. */
function c2cAdminBotToken(): string
{
    $bot = c2cBotToken();

    return $bot !== '' ? $bot : c2cTelegramToken();
}

function c2cNewSecret(): string
{
    return bin2hex(random_bytes(16));
}

function c2cCallbackSig(int $id, string $act): string
{
    $secret = c2cBotSecret();

    if ($secret === '') {
        return '';
    }

    return substr(hash_hmac('sha256', $act . '|' . $id, $secret), 0, 20);
}

function c2cCallbackData(int $id, string $act): string
{
    return 'c2c|' . ($act === 'approve' ? 'a' : 'r') . '|' . $id . '|' . c2cCallbackSig($id, $act);
}

/** Splits and verifies a callback_data payload. */
function c2cCallbackParse(string $data, ?int &$id, ?string &$act): bool
{
    $id = 0;
    $act = '';

    $parts = explode('|', $data);
    if (count($parts) !== 4 || $parts[0] !== 'c2c') {
        return false;
    }

    $act = $parts[1] === 'a' ? 'approve' : ($parts[1] === 'r' ? 'reject' : '');
    if ($act === '') {
        return false;
    }

    $id = (int) $parts[2];
    $expected = c2cCallbackSig($id, $act);

    return $id > 0 && $expected !== '' && hash_equals($expected, (string) $parts[3]);
}

function c2cWebhookUrl(): string
{
    return c2cSiteUrl() . '/xmplus-patch.php?do=c2c.tgwebhook';
}

/** Registers the dedicated bot's webhook. Returns [ok, message]. */
function c2cSetWebhook(string $token, string $secret): array
{
    $url = c2cWebhookUrl();

    if (!preg_match('~^https://~i', $url)) {
        return [false, 'the site URL is not absolute'];
    }

    $answer = c2cApiWith($token, 'setWebhook', [
        'url'             => $url,
        'secret_token'    => $secret,
        'allowed_updates' => json_encode(['callback_query', 'message']),
    ]);

    if (!is_array($answer) || empty($answer['ok'])) {
        return [false, (string) ($answer['description'] ?? 'Telegram did not accept the webhook')];
    }

    return [true, ''];
}

/** Polling and a webhook cannot coexist: this clears one before polling. */
function c2cDeleteWebhook(string $token): array
{
    $answer = c2cApiWith($token, 'deleteWebhook', []);

    if (!is_array($answer) || empty($answer['ok'])) {
        return [false, (string) ($answer['description'] ?? 'Telegram did not accept deleteWebhook')];
    }

    return [true, ''];
}

function c2cUsesCallbacks(): bool
{
    return c2cBotToken() !== '' && c2cBotSecret() !== '';
}
/**
 * The inline keyboard for the admin message: callback buttons when a dedicated
 * bot is configured (the decision happens inside Telegram), URL buttons
 * otherwise (the decision happens when the page opens).
 */
function c2cKeyboard(array $row): ?string
{
    if (c2cUsesCallbacks()) {
        return json_encode([
            'inline_keyboard' => [[
                ['text' => '✅ تایید', 'callback_data' => c2cCallbackData((int) $row['id'], 'approve')],
                ['text' => '❌ رد', 'callback_data' => c2cCallbackData((int) $row['id'], 'reject')],
            ]],
        ], JSON_UNESCAPED_UNICODE);
    }

    if (preg_match('~^https?://~i', c2cSiteUrl())) {
        return json_encode([
            'inline_keyboard' => [[
                ['text' => '✅ تایید', 'url' => c2cDecideUrl($row, 'approve')],
                ['text' => '❌ رد', 'url' => c2cDecideUrl($row, 'reject')],
            ]],
        ], JSON_UNESCAPED_UNICODE);
    }

    return null;
}

function c2cMoney(float $amount): string
{
    return number_format(round($amount));
}

function c2cAdminText(array $row, array $order, ?array $card): string
{
    $lines = [
        '💳 درخواست تایید کارت به کارت',
        '🧾 سفارش: ' . (string) ($order['order_id'] ?? ('#' . (int) $row['orderid'])),
        '👤 کاربر: ' . (string) ($order['username'] ?? ('#' . (int) $row['userid']))
            . ' (#' . (int) $row['userid'] . ')',
        '📦 بسته: ' . ((string) $row['plan_name'] !== '' ? (string) $row['plan_name'] : '—')
            . ((int) $row['plan_days'] > 0 ? ' · ' . (int) $row['plan_days'] . ' روز' : ''),
        '💰 مبلغ: ' . c2cMoney((float) $row['amount']) . ' ریال',
    ];

    if ($card !== null) {
        $lines[] = '🏦 کارت: ' . trim((string) $card['bank'] . ' · ' . (string) $card['holder'])
            . ' · ' . c2cCardNumber((string) $card['number']);
    }

    $lines[] = '🔢 چهار رقم آخر: ' . (string) $row['last4'];

    if ((string) $row['payer'] !== '') {
        $lines[] = '✍️ پرداخت‌کننده: ' . (string) $row['payer'];
    }

    if ((string) $row['paid_at'] !== '') {
        $lines[] = '🕒 زمان واریز: ' . (string) $row['paid_at'];
    }

    if ((string) $row['ref'] !== '') {
        $lines[] = '🔖 پیگیری: ' . (string) $row['ref'];
    }

    $lines[] = '📥 ثبت در سایت: ' . date('Y-m-d H:i', (int) $row['created']);
    $lines[] = '🆔 درخواست: #' . (int) $row['id'];
    $lines[] = '';
    $lines[] = 'با دکمه‌های زیر تایید یا رد کنید؛ تایید، بسته را خودکار اعمال می‌کند.';

    return implode("\n", $lines);
}

/**
 * Sends the admin message with its two buttons. Returns whether at least one
 * chat accepted it; a failure is retried by Card2CardJob every minute.
 */
function c2cSendAdmin(array $row): bool
{
    $chats = c2cChats();
    $token = c2cAdminBotToken();

    if ($chats === [] || $token === '') {
        return false;
    }

    $order = null;
    try {
        $statement = db()->prepare('SELECT order_id, userid, username FROM orders WHERE id = ? LIMIT 1');
        $statement->execute([(int) $row['orderid']]);
        $order = $statement->fetch() ?: null;
    } catch (Throwable $error) {
    }

    $card = c2cCardById((int) $row['cardid']);
    $text = c2cAdminText($row, $order === null ? $row : $order, $card);

    $keyboard = c2cKeyboard($row);

    $sentTo = [];
    $firstMessage = 0;

    foreach ($chats as $chat) {
        $params = [
            'chat_id' => $chat,
            'text'    => $text,
        ];

        if ($keyboard !== null) {
            $params['reply_markup'] = $keyboard;
        }

        $answer = c2cApiWith($token, 'sendMessage', $params);

        if (is_array($answer) && !empty($answer['ok'])) {
            $sentTo[] = $chat;
            if ($firstMessage === 0) {
                $firstMessage = (int) ($answer['result']['message_id'] ?? 0);
            }
        }
    }

    if ($sentTo === []) {
        return false;
    }

    try {
        db()->prepare('UPDATE c2c_request SET tg_sent = 1, tg_chat = ?, tg_message = ? WHERE id = ?')
            ->execute([(string) $sentTo[0], $firstMessage, (int) $row['id']]);
    } catch (Throwable $error) {
    }

    return true;
}

// -------------------------------------------------------------- the grant

/**
 * Grants what a paid order bought.
 *
 * Time plans, reserved plans and wallet charges are granted by their own jobs
 * once the order says paid; the marker on the package row decides.
 */
/**
 * The kind of order whose grant another job owns, decided without the package:
 * the panel can delete a minted top-up row between the checkout and the
 * approval, so the marker on the package is not always there to read. A reserve
 * is recognised by its plan_reserve row (which holds the minted package id).
 */
function c2cDeferredKind(array $order): ?string
{
    try {
        $statement = db()->prepare(
            'SELECT 1 FROM plan_reserve
              WHERE userid = ? AND (packageid = ? OR orderid = ?)
              LIMIT 1');
        $statement->execute([(int) $order['userid'], (int) $order['packageid'], (int) $order['id']]);

        if ($statement->fetch() !== false) {
            return 'reserve';
        }
    } catch (Throwable $error) {
    }

    return null;
}

/**
 * Links the buyer's pending reservation to this paid order and marks it paid,
 * exactly what ReserveJob::linkOrder does. It is done here (not left to the
 * cron) because ReserveJob finds the order through the package, which the panel
 * may already have deleted - the reservation would otherwise be voided after
 * its pending TTL. The reservation itself starts later through activateDue().
 */
function c2cLinkReservation(array $order): void
{
    db()->prepare(
        'UPDATE plan_reserve
            SET orderid = ?, status = 1, paid_at = ?, amount = ?
          WHERE userid = ? AND status = 0
          ORDER BY id DESC LIMIT 1')
        ->execute([(int) $order['id'], time(), (float) $order['total_amount'], (int) $order['userid']]);
}

function c2cApplyOrder(array $order): array
{
    // A reserve whose minted package is gone still completes: the reservation
    // rides in plan_reserve and never needed the package after it is linked.
    $deferred = c2cDeferredKind($order);

    if ($deferred === 'reserve') {
        c2cLinkReservation($order);
        return ['mode' => 'deferred', 'kind' => 'reserve'];
    }

    $hasPackage = ($order['package_type'] ?? null) !== null;

    // A live package carries the marker that says another job owns the grant.
    if ($hasPackage) {
        $note = (string) ($order['package_note'] ?? '');

        foreach ([C2C_MARKER_TIME, C2C_MARKER_CHARGE, C2C_MARKER_RESERVE] as $marker) {
            if (strpos($note, $marker) !== false) {
                return ['mode' => 'deferred'];
            }
        }
    }

    $userId = (int) $order['userid'];
    $now = time();

    $statement = db()->prepare('SELECT * FROM user WHERE id = ? LIMIT 1');
    $statement->execute([$userId]);
    $user = $statement->fetch();

    if ($user === false) {
        throw new RuntimeException('user not found');
    }

    $type = (int) ($order['packagetype'] ?? 0);

    // The order snapshots the bandwidth it was sold with (`orders.bandwidth`),
    // so a package deleted after the checkout is not fatal.
    $bandwidth = $hasPackage
        ? (float) ($order['package_bandwidth'] ?? 0)
        : (float) ($order['bandwidth'] ?? 0);

    $quota = $bandwidth * C2C_GB;

    // ---- traffic top-up: add the gigabytes, leave the plan alone ---------
    if ($type === 1) {
        if ($quota > 0) {
            db()->prepare('UPDATE user SET transfer_enable = transfer_enable + ? WHERE id = ?')
                ->execute([$quota, $userId]);

            return ['mode' => 'topup', 'gb' => $bandwidth, 'snapshot' => !$hasPackage];
        }

        // a marked top-up (time plan, wallet charge, reserve) with no package
        // left to identify it: the order is paid, the owning job takes over
        return ['mode' => 'deferred', 'kind' => 'topup'];
    }

    if ($type !== 2) {
        throw new RuntimeException('unsupported package type ' . $type);
    }

    // ---- subscription -----------------------------------------------------
    $cycle = (string) ($order['plan'] ?? '');
    $days = (int) ($order['plan_expire'] ?? 0);
    $onetime = $cycle === 'onetime';

    if ($days <= 0 && !$onetime) {
        $cycles = ['month' => 30, 'quater' => 90, 'semiannual' => 180, 'annual' => 360];
        $days = $cycles[$cycle] ?? 0;
    }

    if ($days <= 0 && !$onetime) {
        throw new RuntimeException('the order carries no plan length');
    }

    // no package and no bandwidth in the order snapshot: rebuilding the plan
    // would wipe whatever traffic the account has, so leave it to the admin
    if (!$hasPackage && $quota <= 0) {
        return ['mode' => 'deferred', 'kind' => 'no-bandwidth'];
    }

    $current = strtotime((string) $user['expire_in']) ?: 0;
    $active = $current > $now;

    $renewType = $hasPackage ? (int) ($order['package_renew'] ?? 0) : 0;
    if ($renewType < 1 || $renewType > 6) {
        $renewType = 1;
    }

    // auto: a real renewal (the panel's renew button) follows the plan's own
    // renew_type; everything else starts a fresh plan. "fresh" always starts
    // a fresh plan, for an owner who would rather not have the six modes.
    $renew = c2cSetting('c2c_grant_mode', 'auto') === 'auto'
        && (int) ($order['renew'] ?? 0) === 1
        && $active
        && !$onetime;

    $expireAt = $onetime ? $now + 36500 * 86400 : $now + max(1, $days) * 86400;
    $extendAt = $onetime ? $expireAt : max($now, $current) + max(1, $days) * 86400;

    $sets = ['packageid = ?', 'plan = ?'];
    $args = [(int) $order['packageid'], $cycle];

    // a live package also carries the routing limits; without it keep the
    // account's current ones instead of zeroing them
    if ($hasPackage) {
        $sets[] = 'server_group = ?';
        $args[] = (int) ($order['package_group'] ?? 0);
        $sets[] = 'iplimit = ?';
        $args[] = (int) ($order['package_iplimit'] ?? 0);
        $sets[] = 'speedlimit = ?';
        $args[] = (int) ($order['package_speedlimit'] ?? 0);
    }

    $addBytes = static function (float $bytes) use (&$sets, &$args): void {
        $sets[] = 'transfer_enable = transfer_enable + ?';
        $args[] = $bytes;
    };

    $mode = 'fresh';

    if (!$renew) {
        $sets[] = 'transfer_enable = ?';
        $args[] = $quota;
        $sets[] = 'u = 0';
        $sets[] = 'd = 0';
        $sets[] = 'used = 0';
        $sets[] = 'data_expire_cron = 0';
        $sets[] = 'data_used_cron = 0';
        $sets[] = 'expire_in = ?';
        $args[] = date('Y-m-d H:i:s', $expireAt);
    } else {
        $mode = 'renew-' . $renewType;

        if ($renewType === 1) {
            $sets[] = 'transfer_enable = ?';
            $args[] = $quota;
            $sets[] = 'u = 0';
            $sets[] = 'd = 0';
            $sets[] = 'used = 0';
            $sets[] = 'data_expire_cron = 0';
            $sets[] = 'data_used_cron = 0';
            $sets[] = 'expire_in = ?';
            $args[] = date('Y-m-d H:i:s', $expireAt);
        } elseif ($renewType === 2) {
            $sets[] = 'u = 0';
            $sets[] = 'd = 0';
            $sets[] = 'used = 0';
            $sets[] = 'data_expire_cron = 0';
            $sets[] = 'expire_in = ?';
            $args[] = date('Y-m-d H:i:s', $extendAt);
        } elseif ($renewType === 3) {
            $addBytes($quota);
            $sets[] = 'data_expire_cron = 0';
            $sets[] = 'expire_in = ?';
            $args[] = date('Y-m-d H:i:s', $expireAt);
        } elseif ($renewType === 4) {
            $addBytes($quota);
            $sets[] = 'data_expire_cron = 0';
            $sets[] = 'expire_in = ?';
            $args[] = date('Y-m-d H:i:s', $extendAt);
        } elseif ($renewType === 5) {
            $sets[] = 'data_expire_cron = 0';
            $sets[] = 'expire_in = ?';
            $args[] = date('Y-m-d H:i:s', $extendAt);
        } else {
            $addBytes($quota);
        }
    }

    $args[] = $userId;

    db()->prepare('UPDATE user SET ' . implode(', ', $sets) . ' WHERE id = ?')->execute($args);

    $finalExpire = null;
    $check = db()->prepare('SELECT expire_in FROM user WHERE id = ? LIMIT 1');
    $check->execute([$userId]);
    $finalExpire = $check->fetchColumn();

    // the order itself becomes the subscription purchase it was
    try {
        db()->prepare(
            'UPDATE orders SET packagetype = 2, plan = ?, plan_expire = ?, expire = ? WHERE id = ?')
            ->execute([$cycle, $days, (int) $expireAt, (int) $order['id']]);
    } catch (Throwable $error) {
        // an ancient orders table may not carry `expire`; the grant stands
    }

    // an upgrade refunds the unused part of the old plan into account credit,
    // exactly what the checkout page promises
    $refund = 0.0;
    if ((int) ($order['upgrade'] ?? 0) === 1 && (float) ($order['refund_amount'] ?? 0) > 0) {
        $refund = (float) $order['refund_amount'];
        db()->prepare('UPDATE user SET money = money + ? WHERE id = ?')->execute([$refund, $userId]);
    }

    return [
        'mode'    => $mode,
        'days'    => $days,
        'expire'  => $finalExpire === false ? null : (string) $finalExpire,
        'refund'  => $refund,
    ];
}

/**
 * Marks an order paid and grants it, exactly once.
 *
 * The caller must already have claimed the request row (status 0 -> 1) inside
 * its transaction; a second approval therefore never reaches this function.
 */
function c2cGrantOrder(array $order): array
{
    $statement = db()->prepare(
        "UPDATE orders
            SET status = 1, pay_date = ?, gateway_name = 'کارت به کارت', gateway_expire = 0
          WHERE id = ? AND (status <> 1 OR pay_date IS NULL)");
    $statement->execute([time(), (int) $order['id']]);

    if ($statement->rowCount() < 1) {
        throw new RuntimeException('this order is already marked paid');
    }

    return c2cApplyOrder($order);
}

// ------------------------------------------------------------------ notices

/**
 * One row per decision. The ref carries the decision time as well as the
 * request, so a rejected request that is resubmitted and decided again gets a
 * second notice instead of colliding with the first one.
 */
function c2cNotice(array $request, ?array $order, string $kind, string $reason = '', int $stamp = 0): void
{
    if ($stamp <= 0) {
        $stamp = (int) ($request['decided_at'] ?? 0);
    }
    if ($stamp <= 0) {
        $stamp = time();
    }

    $ref = 'c2c:' . (int) $request['id'] . ':' . ($kind === 'approved' ? 'a' : 'r') . ':' . $stamp;

    $orderNo = $order === null ? '' : (string) ($order['order_id'] ?? '');
    $name = (string) $request['plan_name'];

    // a rejection always tells the buyer where to follow up
    if ($kind === 'rejected') {
        $support = c2cSupport();

        if ($support !== '' && strpos($reason, $support) === false) {
            $reason = trim($reason . ' · پشتیبانی: ' . $support);
        }
    }

    try {
        db()->prepare(
            'INSERT IGNORE INTO c2c_notice
                (userid, kind, ref, orderid, order_no, name, amount, reason, seen, created)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, 0, ?)')
            ->execute([
                (int) $request['userid'], $kind, $ref, (int) $request['orderid'],
                $orderNo, $name, (float) $request['amount'], $reason, time(),
            ]);
    } catch (Throwable $error) {
        // the banner is a nicety; a missing table must not undo the payment
    }
}

// --------------------------------------------------------------- user half

function c2cUserInfo(): void
{
    $user = c2cRequireUser();

    $orderId = (int) ($_GET['order'] ?? 0);
    $order = $orderId > 0 ? c2cOrder($orderId, (int) $user['id']) : null;

    if ($orderId > 0 && $order === null) {
        fail('order not found');
    }

    $request = $order === null ? null : c2cRequestForOrder((int) $order['id']);

    // The card is only handed out for a real unpaid order: reading it needs
    // nothing but a login otherwise, and there is no reason to publish it.
    $card = null;

    if ($order !== null) {
        if ($request !== null && (int) $request['status'] === 0) {
            $card = c2cCardById((int) $request['cardid']);
        }

        if ($card === null) {
            $card = c2cActiveCard();
        }

        // an order the grant does not understand must not be offered this way
        if ($request === null && !c2cOrderPayable($order)) {
            $card = null;
        }
    }

    $lastPayer = '';
    try {
        $statement = db()->prepare(
            'SELECT payer FROM c2c_request WHERE userid = ? ORDER BY id DESC LIMIT 1');
        $statement->execute([(int) $user['id']]);
        $lastPayer = (string) ($statement->fetchColumn() ?: '');
    } catch (Throwable $error) {
    }

    done([
        'token'     => c2cUserToken(),
        'enabled'   => c2cEnabled() ? 1 : 0,
        'available' => $card !== null ? 1 : 0,
        'card'      => c2cPresentCard($card),
        'note'      => c2cSetting('c2c_note', ''),
        'order'     => $order === null ? null : [
            'id'        => (int) $order['id'],
            'order_no'  => (string) ($order['order_id'] ?? ''),
            'amount'    => (float) $order['total_amount'],
            'plan'      => (string) ($order['package_name'] ?? ''),
            'days'      => (int) ($order['plan_expire'] ?? 0),
        ],
        'request'   => c2cPresent($request),
        'last_payer' => $lastPayer,
        'support'   => c2cSupport(),
    ]);
}

function c2cUserSubmit(): void
{
    $user = c2cRequireUser();
    c2cRequireUserToken();

    if (!c2cEnabled()) {
        fail('card-to-card payments are switched off');
    }

    try {
        db()->query('SELECT 1 FROM c2c_card LIMIT 1');
        db()->query('SELECT 1 FROM c2c_request LIMIT 1');
    } catch (Throwable $error) {
        fail('card-to-card storage is not ready; run the patch migrations');
    }

    $order = c2cOrder(c2cInt($_POST['order'] ?? 0), (int) $user['id']);

    if ($order === null) {
        fail('order not found');
    }

    if ((int) $order['status'] === 1) {
        fail('this order is already paid');
    }

    if ((int) $order['status'] === -2) {
        fail('this order was cancelled');
    }

    if (!c2cOrderPayable($order)) {
        fail('this order cannot be paid this way');
    }

    $amount = (float) $order['total_amount'];
    if ($amount <= 0) {
        fail('this order has nothing to pay');
    }

    // The last four digits are the whole declaration: the bank SMS the admin
    // already receives carries the name, the time and the reference. The other
    // fields are optional and only help when the buyer chooses to fill them.
    $last4 = c2cLast4((string) ($_POST['last4'] ?? ''));
    if (strlen($last4) !== 4) {
        fail('last four digits of the card are required');
    }

    $payer = trim((string) ($_POST['payer'] ?? ''));
    $payer = preg_replace('~[\x00-\x1F\x7F]+~', ' ', $payer) ?? '';
    $payer = trim(preg_replace('~\s+~', ' ', $payer) ?? '');

    if (strlen($payer) > 120) {
        $payer = function_exists('mb_substr')
            ? mb_substr($payer, 0, 120, 'UTF-8')
            : substr($payer, 0, 120);
    }

    $paidAt = trim((string) ($_POST['paid_at'] ?? ''));
    if (strlen($paidAt) > 80) {
        $paidAt = substr($paidAt, 0, 80);
    }

    $reference = trim((string) ($_POST['ref'] ?? ''));
    $reference = preg_replace('~[\x00-\x1F\x7F]+~', ' ', $reference) ?? '';
    if (strlen($reference) > 80) {
        $reference = substr($reference, 0, 80);
    }

    // Which card did they pay? The one on screen, unless the last four digits
    // point at another enabled card (the page may have rotated meanwhile).
    $card = c2cCardById(c2cInt($_POST['card'] ?? 0));
    if ($card === null || (int) $card['enabled'] !== 1) {
        $card = c2cCardByLast4($last4);
    }
    if ($card === null) {
        $card = c2cActiveCard();
    }
    if ($card === null) {
        fail('no active card is available right now');
    }

    $existing = c2cRequestForOrder((int) $order['id']);
    if ($existing !== null && (int) $existing['status'] === 1) {
        fail('this order already has an approved card-to-card payment');
    }

    if ($existing !== null && (int) $existing['status'] === 0) {
        fail('this transfer is already waiting for approval');
    }

    $token = bin2hex(random_bytes(32));
    $now = time();
    $days = (int) ($order['plan_expire'] ?? 0);

    if ($existing !== null) {
        // a rejected request may be corrected and sent again
        $update = db()->prepare(
            'UPDATE c2c_request
                SET status = 0, cardid = ?, amount = ?, plan_name = ?, plan_cycle = ?, plan_days = ?,
                    last4 = ?, payer = ?, paid_at = ?, ref = ?, note = \'\',
                    token = ?, token_expire = ?, updated = ?, decided_at = 0, decided_by = \'\',
                    tg_sent = 0, tg_closed = 0, user_sent = 1
              WHERE id = ? AND status = 2');
        $update->execute([
            (int) $card['id'], $amount, (string) ($order['package_name'] ?? ''),
            (string) ($order['plan'] ?? ''), $days, $last4, $payer, $paidAt, $reference,
            $token, $now + C2C_TOKEN_TTL, $now, (int) $existing['id'],
        ]);

        if ($update->rowCount() < 1) {
            fail('this request could not be saved');
        }

        $requestId = (int) $existing['id'];
    } else {
        db()->prepare(
            'INSERT INTO c2c_request
                (orderid, userid, cardid, amount, plan_name, plan_cycle, plan_days,
                 last4, payer, paid_at, ref, status, note, token, token_expire,
                 created, updated, tg_sent, tg_closed, user_sent)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, \'\', ?, ?, ?, ?, 0, 0, 1)')
            ->execute([
                (int) $order['id'], (int) $user['id'], (int) $card['id'], $amount,
                (string) ($order['package_name'] ?? ''), (string) ($order['plan'] ?? ''), $days,
                $last4, $payer, $paidAt, $reference, $token, $now + C2C_TOKEN_TTL, $now, $now,
            ]);
        $requestId = (int) db()->lastInsertId();
    }

    // the panel's 2-minute job cancels unpaid orders; a card transfer takes
    // longer than a gateway redirect, so the order is kept open while it waits
    $hold = c2cHours('c2c_hold_hours', 48) * 3600;
    db()->prepare('UPDATE orders SET status = 0, gateway_expire = ? WHERE id = ? AND status IN (0, -1)')
        ->execute([$now + max(3600, $hold), (int) $order['id']]);

    $request = c2cRequestById($requestId);
    if ($request !== null) {
        // instant when Telegram answers; otherwise the cron retries every minute
        c2cSendAdmin($request);
    }

    done([
        'id'      => $requestId,
        'status'  => 0,
        'amount'  => $amount,
        'card'    => c2cPresentCard($card),
    ]);
}

function c2cUserStatus(): void
{
    $user = c2cRequireUser();

    $order = c2cOrder(c2cInt($_GET['order'] ?? 0), (int) $user['id']);
    if ($order === null) {
        fail('order not found');
    }

    $request = c2cRequestForOrder((int) $order['id']);

    done([
        'order'   => (int) $order['id'],
        'paid'    => (int) $order['status'] === 1 ? 1 : 0,
        'request' => c2cPresent($request),
        'card'    => c2cPresentCard($request === null ? null : c2cCardById((int) $request['cardid'])),
    ]);
}

function c2cUserAck(): void
{
    $user = c2cRequireUser();
    c2cRequireUserToken();

    try {
        db()->prepare('UPDATE c2c_notice SET seen = 1 WHERE userid = ? AND seen = 0')
            ->execute([(int) $user['id']]);
    } catch (Throwable $error) {
    }

    done(['ok' => 1]);
}

// -------------------------------------------------------------- admin half

function c2cAdminData(): array
{
    $settings = [
        'enabled'      => c2cEnabled() ? 1 : 0,
        'chat'         => c2cSetting('c2c_telegram_chat', ''),
        'note'         => c2cSetting('c2c_note', ''),
        'reject_hours' => c2cHours('c2c_reject_hours', 72),
        'hold_hours'   => c2cHours('c2c_hold_hours', 48),
        'grant_mode'   => c2cSetting('c2c_grant_mode', 'auto') === 'fresh' ? 'fresh' : 'auto',
        'site_url'     => c2cSetting('c2c_site_url', ''),
        'fallback_chat' => c2cSetting('telegramchatid', ''),
        'telegram'     => c2cTelegramToken() !== '',
        'bot_token'    => c2cBotToken(),
        'bot_secret'   => c2cBotSecret() !== '' ? 1 : 0,
        'webhook_url'  => c2cWebhookUrl(),
        'webhook_ok'   => c2cSetting('c2c_bot_webhook_ok', '0') === '1' ? 1 : 0,
        'webhook_error' => c2cSetting('c2c_bot_webhook_error', ''),
        'callbacks'    => c2cUsesCallbacks() ? 1 : 0,
        'support'      => c2cSupport(),
        'mode'         => c2cBotMode(),
    ];

    $cards = [];
    $activeId = 0;

    foreach (c2cCards() as $card) {
        $usage = c2cCardUsage((int) $card['id'], (string) $card['limit_period']);
        $room = c2cCardHasRoom($card);

        if ($room && $activeId === 0 && (int) $card['enabled'] === 1) {
            $activeId = (int) $card['id'];
        }

        $cards[] = [
            'id'           => (int) $card['id'],
            'number'       => c2cDigits((string) $card['number']),
            'formatted'    => c2cCardNumber((string) $card['number']),
            'holder'       => (string) $card['holder'],
            'bank'         => (string) $card['bank'],
            'limit_amount' => (float) $card['limit_amount'],
            'limit_count'  => (int) $card['limit_count'],
            'period'       => (string) $card['limit_period'],
            'enabled'      => (int) $card['enabled'],
            'sort'         => (int) $card['sort'],
            'note'         => (string) $card['note'],
            'used_amount'  => $usage['amount'],
            'used_count'   => $usage['count'],
            'room'         => $room ? 1 : 0,
            'active'       => $room && (int) $card['enabled'] === 1 && (int) $card['id'] === $activeId ? 1 : 0,
        ];
    }

    $pending = [];
    $history = [];

    $select = 'SELECT r.*, o.order_id AS order_no, o.status AS order_status, o.username AS username,
                      c.number AS card_number, c.bank AS card_bank, c.holder AS card_holder
                 FROM c2c_request r
                 LEFT JOIN orders o ON o.id = r.orderid
                 LEFT JOIN c2c_card c ON c.id = r.cardid ';

    $collect = static function (array $rows): array {
        $out = [];

        foreach ($rows as $row) {
            $present = c2cPresent($row);
            $present['order_no'] = (string) ($row['order_no'] ?? '');
            $present['username'] = (string) ($row['username'] ?? '');
            $present['order_status'] = (int) ($row['order_status'] ?? 0);
            $present['card_last4'] = c2cLast4((string) ($row['card_number'] ?? ''));
            $present['card_bank'] = (string) ($row['card_bank'] ?? '');
            $present['card_holder'] = (string) ($row['card_holder'] ?? '');
            $present['tg_sent'] = (int) $row['tg_sent'];
            $out[] = $present;
        }

        return $out;
    };

    try {
        $pending = $collect(db()->query(
            $select . 'WHERE r.status = 0 ORDER BY r.id DESC LIMIT 50')->fetchAll());
    } catch (Throwable $error) {
        $pending = [];
    }

    try {
        $history = $collect(db()->query(
            $select . 'WHERE r.status <> 0 ORDER BY r.id DESC LIMIT 40')->fetchAll());
    } catch (Throwable $error) {
        $history = [];
    }

    $counts = ['pending' => count($pending), 'history' => count($history)];

    return [
        'settings' => $settings,
        'cards'    => $cards,
        'active'   => $activeId,
        'pending'  => $pending,
        'history'  => $history,
        'counts'   => $counts,
        'now'      => time(),
    ];
}

function c2cAdminBootstrap(): void
{
    requireAdmin();

    if (empty($_SESSION['patch_csrf'])) {
        $_SESSION['patch_csrf'] = bin2hex(random_bytes(24));
    }

    done(['token' => $_SESSION['patch_csrf']] + c2cAdminData());
}

function c2cAdminSettings(): void
{
    requireAdmin();
    requireToken();

    $enabled = c2cInt($_POST['enabled'] ?? 0) === 1 ? 1 : 0;
    $chat = trim((string) ($_POST['chat'] ?? ''));
    $note = trim((string) ($_POST['note'] ?? ''));
    $reject = c2cInt($_POST['reject_hours'] ?? 72, 72);
    $hold = c2cInt($_POST['hold_hours'] ?? 48, 48);
    $mode = (string) ($_POST['grant_mode'] ?? 'auto');
    $site = trim((string) ($_POST['site_url'] ?? ''));
    $bot = trim((string) ($_POST['bot_token'] ?? ''));
    $support = trim((string) ($_POST['support'] ?? ''));
    $botMode = (string) ($_POST['bot_mode'] ?? 'poll');
    if ($botMode !== 'webhook') {
        $botMode = 'poll';
    }

    if ($bot !== '' && !preg_match('~^\d{5,}:[A-Za-z0-9_-]{20,}$~', $bot)) {
        fail('the bot token does not look like a Telegram bot token');
    }

    if ($bot !== '' && $bot !== c2cBotToken() && $site === '' && !preg_match('~^https://~i', c2cSiteUrl())) {
        fail('set the site URL first: the webhook must be an absolute HTTPS address');
    }

    if ($reject < 0 || $reject > 8760) {
        fail('the auto-reject window must be between 0 and 8760 hours');
    }

    if ($hold < 1 || $hold > 8760) {
        fail('the hold window must be between 1 and 8760 hours');
    }

    if ($mode !== 'auto' && $mode !== 'fresh') {
        $mode = 'auto';
    }

    if ($site !== '' && !preg_match('~^https?://~i', $site)) {
        $site = 'https://' . $site;
    }

    putSetting('c2c_enabled', (string) $enabled);
    putSetting('c2c_telegram_chat', $chat);
    putSetting('c2c_note', $note);
    putSetting('c2c_reject_hours', (string) $reject);
    putSetting('c2c_hold_hours', (string) $hold);
    putSetting('c2c_grant_mode', $mode);
    putSetting('c2c_site_url', rtrim($site, '/'));
    putSetting('c2c_bot_token', $bot);
    putSetting('c2c_support', $support !== '' ? $support : '@digitsellshop');
    putSetting('c2c_bot_mode', $botMode);

    // a dedicated bot needs a secret: it is both the webhook header and the
    // key that signs the callback buttons
    $secret = c2cBotSecret();
    if ($bot !== '' && $secret === '') {
        $secret = c2cNewSecret();
        putSetting('c2c_bot_secret', $secret);
    }

    if ($bot !== '' && $secret !== '') {
        if ($botMode === 'webhook') {
            list($ok, $error) = c2cSetWebhook($bot, $secret);
            putSetting('c2c_bot_webhook_cleared', '0');
        } else {
            // polling is the default: Telegram cannot reach this host through
            // the CDN, but the panel can reach Telegram
            list($ok, $error) = c2cDeleteWebhook($bot);
            putSetting('c2c_bot_webhook_cleared', '1');
            $ok = true;
            $error = '';
        }

        putSetting('c2c_bot_webhook_ok', $ok ? '1' : '0');
        putSetting('c2c_bot_webhook_error', $error);
    } else {
        putSetting('c2c_bot_webhook_ok', '0');
        putSetting('c2c_bot_webhook_error', '');
    }

    done(['saved' => 1] + c2cAdminData());
}

function c2cAdminWebhook(): void
{
    requireAdmin();
    requireToken();

    $token = c2cBotToken();
    $secret = c2cBotSecret();

    if ($token === '') {
        fail('set the bot token first');
    }

    if ($secret === '') {
        $secret = c2cNewSecret();
        putSetting('c2c_bot_secret', $secret);
    }

    if (c2cBotMode() === 'webhook') {
        list($ok, $error) = c2cSetWebhook($token, $secret);
        putSetting('c2c_bot_webhook_cleared', '0');
    } else {
        list($ok, $error) = c2cDeleteWebhook($token);
        putSetting('c2c_bot_webhook_cleared', '1');
        $ok = true;
        $error = '';
    }

    putSetting('c2c_bot_webhook_ok', $ok ? '1' : '0');
    putSetting('c2c_bot_webhook_error', $error);

    if (!$ok) {
        fail('Telegram refused the setup: ' . $error);
    }

    done(['saved' => 1] + c2cAdminData());
}

function c2cAdminCards(): void
{
    requireAdmin();
    requireToken();

    $raw = (string) ($_POST['cards'] ?? '');
    $rows = json_decode($raw, true);

    if (!is_array($rows)) {
        fail('the card list is not readable');
    }

    $periods = ['day', 'month', 'total'];

    db()->beginTransaction();

    try {
        foreach ($rows as $row) {
            if (!is_array($row)) {
                continue;
            }

            $id = c2cInt($row['id'] ?? 0);
            $delete = !empty($row['deleted']);

            if ($delete) {
                if ($id > 0) {
                    $used = db()->prepare('SELECT 1 FROM c2c_request WHERE cardid = ? LIMIT 1');
                    $used->execute([$id]);

                    if ($used->fetch() !== false) {
                        // history points at it: keep the row, switch it off
                        db()->prepare('UPDATE c2c_card SET enabled = 0, updated = ? WHERE id = ?')
                            ->execute([time(), $id]);
                    } else {
                        db()->prepare('DELETE FROM c2c_card WHERE id = ?')->execute([$id]);
                    }
                }
                continue;
            }

            $number = c2cDigits((string) ($row['number'] ?? ''));
            if (strlen($number) !== 16) {
                throw new RuntimeException('every card number must have 16 digits');
            }

            $holder = trim((string) ($row['holder'] ?? ''));
            $bank = trim((string) ($row['bank'] ?? ''));
            $limitAmount = max(0, c2cInt($row['limit_amount'] ?? 0));
            $limitCount = max(0, c2cInt($row['limit_count'] ?? 0));
            $period = (string) ($row['period'] ?? 'day');
            $enabled = c2cInt($row['enabled'] ?? 1) === 1 ? 1 : 0;
            $sort = c2cInt($row['sort'] ?? 0);
            $note = trim((string) ($row['note'] ?? ''));

            if ($holder === '' || strlen($holder) > 120) {
                throw new RuntimeException('every card needs a holder name');
            }

            if (strlen($bank) > 120) {
                throw new RuntimeException('the bank name is too long');
            }

            if (!in_array($period, $periods, true)) {
                $period = 'day';
            }

            if (strlen($note) > 255) {
                $note = substr($note, 0, 255);
            }

            if ($id > 0 && c2cCardById($id) !== null) {
                db()->prepare(
                    'UPDATE c2c_card
                        SET number = ?, holder = ?, bank = ?, limit_amount = ?, limit_count = ?,
                            limit_period = ?, enabled = ?, sort = ?, note = ?, updated = ?
                      WHERE id = ?')
                    ->execute([
                        $number, $holder, $bank, $limitAmount, $limitCount, $period,
                        $enabled, $sort, $note, time(), $id,
                    ]);
            } else {
                db()->prepare(
                    'INSERT INTO c2c_card
                        (number, holder, bank, limit_amount, limit_count, limit_period,
                         enabled, sort, note, created, updated)
                     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)')
                    ->execute([
                        $number, $holder, $bank, $limitAmount, $limitCount, $period,
                        $enabled, $sort, $note, time(), time(),
                    ]);
            }
        }

        db()->commit();
    } catch (Throwable $error) {
        db()->rollBack();
        fail($error->getMessage());
    }

    done(['saved' => 1] + c2cAdminData());
}

function c2cApprove(int $id, string $by, string $note = ''): array
{
    $request = c2cRequestById($id);

    if ($request === null) {
        throw new RuntimeException('request not found');
    }

    // A duplicate tap (Telegram opens the link, then the admin taps again, or a
    // message is opened twice) must read as done, not as a failure.
    if ((int) $request['status'] !== 0) {
        return ['request' => $request, 'order' => null, 'grant' => ['mode' => 'already-decided']];
    }

    $order = null;
    try {
        $statement = db()->prepare('SELECT * FROM orders WHERE id = ? LIMIT 1');
        $statement->execute([(int) $request['orderid']]);
        $order = $statement->fetch() ?: null;
    } catch (Throwable $error) {
    }

    if ($order === null) {
        throw new RuntimeException('the order behind this request is gone');
    }

    // The order is already paid - through a gateway, the panel itself, or an
    // earlier tap whose write landed between our reads. Close the request
    // without granting anything a second time and report it as handled.
    if ((int) $order['status'] === 1) {
        $closed = c2cCloseAsPaid($id, $by, $order);

        return [
            'request' => $closed ?? (c2cRequestById($id) ?? $request),
            'order'   => $order,
            'grant'   => ['mode' => $closed !== null ? 'already-paid' : 'already-decided'],
        ];
    }

    $note = trim($note);
    if (strlen($note) > 255) {
        $note = substr($note, 0, 255);
    }

    db()->beginTransaction();

    try {
        $claim = db()->prepare(
            'UPDATE c2c_request
                SET status = 1, decided_at = ?, decided_by = ?, note = ?, user_sent = 0, tg_closed = 0
              WHERE id = ? AND status = 0');
        $claim->execute([time(), $by, $note, $id]);

        if ($claim->rowCount() < 1) {
            throw new RuntimeException('this request was already decided');
        }

        $grant = c2cGrantOrder($order);

        // the package was gone and the grant used the order's own snapshot:
        // leave a trace on the request for the admin
        if (!empty($grant['snapshot'])) {
            db()->prepare('UPDATE c2c_request SET note = ? WHERE id = ?')
                ->execute(['بسته حذف شده بود؛ از اطلاعات سفارش اعمال شد', $id]);
        }

        $request = c2cRequestById($id) ?? $request;
        c2cNotice($request, $order, 'approved');

        db()->commit();
    } catch (Throwable $error) {
        db()->rollBack();
        throw $error;
    }

    return ['request' => $request, 'order' => $order, 'grant' => $grant];
}

/**
 * The order is already paid, so nothing may be granted again. The request is
 * closed as approved with a note saying why, and the buyer is told that their
 * card payment was received (the admin confirmed it by tapping approve).
 */
function c2cCloseAsPaid(int $id, string $by, array $order): ?array
{
    db()->beginTransaction();

    try {
        $claim = db()->prepare(
            'UPDATE c2c_request
                SET status = 1, decided_at = ?, decided_by = ?,
                    note = ?, user_sent = 0, tg_closed = 0
              WHERE id = ? AND status = 0');
        $claim->execute([time(), $by, 'سفارش قبلاً پرداخت شده بود؛ اعمال دوباره انجام نشد', $id]);

        if ($claim->rowCount() < 1) {
            db()->rollBack();
            return null;
        }

        $request = c2cRequestById($id);
        if ($request !== null) {
            c2cNotice($request, $order, 'approved');
        }

        db()->commit();

        return $request;
    } catch (Throwable $error) {
        db()->rollBack();
        throw $error;
    }
}

function c2cReject(int $id, string $by, string $reason): void
{
    $request = c2cRequestById($id);

    if ($request === null) {
        throw new RuntimeException('request not found');
    }

    if ((int) $request['status'] !== 0) {
        throw new RuntimeException('this request was already decided');
    }

    $reason = trim($reason);
    if (strlen($reason) > 255) {
        $reason = substr($reason, 0, 255);
    }

    db()->beginTransaction();

    try {
        $claim = db()->prepare(
            'UPDATE c2c_request
                SET status = 2, decided_at = ?, decided_by = ?, note = ?, user_sent = 0, tg_closed = 0
              WHERE id = ? AND status = 0');
        $claim->execute([time(), $by, $reason, $id]);

        if ($claim->rowCount() < 1) {
            throw new RuntimeException('this request was already decided');
        }

        $order = null;
        try {
            $statement = db()->prepare('SELECT * FROM orders WHERE id = ? LIMIT 1');
            $statement->execute([(int) $request['orderid']]);
            $order = $statement->fetch() ?: null;
        } catch (Throwable $error) {
        }

        $request = c2cRequestById($id) ?? $request;
        c2cNotice($request, $order, 'rejected', $reason);

        if ($order !== null && (int) $order['status'] === 0) {
            db()->prepare('UPDATE orders SET gateway_expire = ? WHERE id = ?')
                ->execute([time(), (int) $order['id']]);
        }

        db()->commit();
    } catch (Throwable $error) {
        db()->rollBack();
        throw $error;
    }
}

function c2cAdminApprove(): void
{
    requireAdmin();
    requireToken();

    try {
        $result = c2cApprove(c2cInt($_POST['id'] ?? 0), 'site', (string) ($_POST['note'] ?? ''));
    } catch (Throwable $error) {
        fail($error->getMessage());
    }

    done(['message' => 'approved', 'grant' => $result['grant']] + c2cAdminData());
}

function c2cAdminReject(): void
{
    requireAdmin();
    requireToken();

    try {
        c2cReject(c2cInt($_POST['id'] ?? 0), 'site', (string) ($_POST['note'] ?? ''));
    } catch (Throwable $error) {
        fail($error->getMessage());
    }

    done(['message' => 'rejected'] + c2cAdminData());
}

// ------------------------------------------------- the Telegram decision page

function c2cHtml(string $body, string $title): void
{
    header('Content-Type: text/html; charset=utf-8');
    header('Cache-Control: no-store');
    header('X-Robots-Tag: noindex');

    $safe = htmlspecialchars($title, ENT_QUOTES, 'UTF-8');

    echo '<!DOCTYPE html><html lang="fa" dir="rtl"><head><meta charset="utf-8">'
        . '<meta name="viewport" content="width=device-width,initial-scale=1">'
        . '<title>' . $safe . '</title><style>'
        . 'body{margin:0;font-family:system-ui,-apple-system,"Segoe UI",Tahoma,sans-serif;background:#0f172a;color:#e2e8f0;display:flex;min-height:100vh;align-items:center;justify-content:center;padding:18px}'
        . '.card{width:100%;max-width:460px;background:#1c2536;border:1px solid rgba(255,255,255,.08);border-radius:20px;padding:22px;box-shadow:0 20px 50px rgba(0,0,0,.4)}'
        . 'h1{font-size:17px;margin:0 0 14px}.row{display:flex;justify-content:space-between;gap:12px;padding:9px 0;border-bottom:1px dashed rgba(255,255,255,.09);font-size:13px}'
        . '.row span:first-child{color:#94a3b8}.row span:last-child{font-weight:700;text-align:left;direction:ltr;unicode-bidi:isolate}'
        . '.btns{display:flex;gap:10px;margin-top:18px}.btn{flex:1;border:0;border-radius:14px;padding:13px;font-size:14px;font-weight:800;cursor:pointer;color:#fff}'
        . '.lbl{display:block;margin:16px 0 6px;font-size:12px;color:#cbd5e1}'
        . '.inp{width:100%;box-sizing:border-box;border:1px solid rgba(255,255,255,.16);border-radius:12px;background:#0f172a;color:#e2e8f0;padding:11px 12px;font-size:13px;font-family:inherit}'
        . '.inp:focus{outline:none;border-color:#34d399}'
        . '.ok{background:#059669}.no{background:#dc2626}.muted{color:#94a3b8;font-size:12px;line-height:2;margin-top:14px}'
        . 'a{color:#93c5fd;text-decoration:none}'
        . '</style></head><body><div class="card">' . $body . '</div></body></html>';

    exit;
}

function c2cDecidePage(): void
{
    $id = c2cInt($_GET['id'] ?? 0);
    $act = (string) ($_GET['act'] ?? '');
    $token = (string) ($_GET['t'] ?? '');

    $request = c2cRequestById($id);

    if ($request === null
        || !in_array($act, ['approve', 'reject'], true)
        || strlen($token) !== 64
        || !hash_equals((string) $request['token'], $token)
        || (int) $request['token_expire'] < time()) {
        c2cHtml('<h1>لینک نامعتبر است</h1><p class="muted">این لینک منقضی شده یا مربوط به درخواست دیگری است.</p>', 'لینک نامعتبر');
    }

    if ((int) $request['status'] !== 0) {
        $label = (int) $request['status'] === 1 ? 'قبلاً تایید شده است' : 'قبلاً رد شده است';
        c2cHtml('<h1>این درخواست ' . $label . '</h1>'
            . '<p class="muted">درخواست #' . (int) $request['id'] . ' پیش‌تر بررسی شده بود.</p>', 'بررسی‌شده');
    }

    // one tap, no form: the button in Telegram performs the decision straight
    // away (the one-time token is the whole credential). The browser opens for
    // a moment and shows the outcome.
    $amount = c2cMoney((float) $request['amount']);

    try {
        if ($act === 'approve') {
            $result = c2cApprove($id, 'telegram', 'تایید از تلگرام');
            $mode = (string) ($result['grant']['mode'] ?? '');
            $expire = isset($result['grant']['expire']) ? (string) $result['grant']['expire'] : '';

            $heading = '✅ پرداخت تایید شد';
            $note = 'بسته اعمال شد و به مشتری اطلاع داده می‌شود.';

            if ($mode === 'already-paid') {
                $heading = '✅ درخواست بسته شد';
                $note = 'این سفارش قبلاً پرداخت شده بود؛ بسته دوباره اعمال نشد و فقط درخواست کارت به کارت بسته شد.';
            } elseif ($mode === 'already-decided') {
                $heading = '✅ قبلاً بررسی شده بود';
                $note = 'این درخواست پیش‌تر بررسی شده است؛ کار دیگری لازم نیست.';
            }

            c2cHtml(
                '<h1>' . $heading . '</h1>'
                . '<div class="row"><span>درخواست</span><span>#' . $id . '</span></div>'
                . '<div class="row"><span>مبلغ</span><span>' . $amount . ' ریال</span></div>'
                . ($expire !== '' ? '<div class="row"><span>اعتبار تا</span><span>' . htmlspecialchars($expire, ENT_QUOTES, 'UTF-8') . '</span></div>' : '')
                . '<p class="muted">' . $note . '</p>',
                'تایید شد');
        }

        c2cReject($id, 'telegram', 'رد از تلگرام');
        c2cHtml(
            '<h1>❌ درخواست رد شد</h1>'
            . '<div class="row"><span>درخواست</span><span>#' . $id . '</span></div>'
            . '<div class="row"><span>مبلغ</span><span>' . $amount . ' ریال</span></div>'
            . '<p class="muted">مشتری پیام رد شدن را در پنل می‌بیند.</p>',
            'رد شد');
    } catch (Throwable $error) {
        c2cHtml('<h1>انجام نشد</h1><p class="muted">'
            . htmlspecialchars($error->getMessage(), ENT_QUOTES, 'UTF-8') . '</p>', 'خطا');
    }
}

// -------------------------------------------------------- the bot webhook

/**
 * Telegram posts callback queries here (the dedicated bot's webhook). The
 * buttons decide on the spot: approve applies the order, reject closes it with
 * a reason, and the buttons are removed from the message so it cannot be used
 * again. Only the secret header Telegram sends, plus a chat in the admin list,
 * is accepted.
 */
function c2cTelegramWebhook(): void
{
    $secret = c2cBotSecret();
    $sent = (string) ($_SERVER['HTTP_X_TELEGRAM_BOT_API_SECRET_TOKEN'] ?? '');

    if ($secret === '' || !hash_equals($secret, $sent)) {
        fail('unauthorized', 403);
    }

    $token = c2cBotToken();
    if ($token === '') {
        done(['ok' => true]);
    }

    $update = json_decode((string) file_get_contents('php://input'), true);
    if (!is_array($update)) {
        done(['ok' => true]);
    }

    $chats = array_map('strval', c2cChats());

    // /start (or any chat message): tell the admin this bot is ready
    if (isset($update['message'])) {
        $chatId = (string) ($update['message']['chat']['id'] ?? '');

        if (in_array($chatId, $chats, true)) {
            c2cApiWith($token, 'sendMessage', [
                'chat_id' => $chatId,
                'text'    => 'این ربات برای تایید/رد کارت به کارت است. پیام هر درخواست همین‌جا می‌آید و با دکمه‌های همان پیام تایید یا رد می‌شود.',
            ]);
        }

        done(['ok' => true]);
    }

    if (!isset($update['callback_query']) || !is_array($update['callback_query'])) {
        done(['ok' => true]);
    }

    $callback = $update['callback_query'];
    $callbackId = (string) ($callback['id'] ?? '');
    $data = (string) ($callback['data'] ?? '');
    $chatId = (string) ($callback['message']['chat']['id'] ?? '');
    $messageId = (int) ($callback['message']['message_id'] ?? 0);

    $id = 0;
    $act = '';
    $answer = '';

    if (!c2cCallbackParse($data, $id, $act)) {
        $answer = 'دکمه نامعتبر است';
    } elseif (!in_array($chatId, $chats, true)) {
        $answer = 'اجازه ندارید';
    } else {
        $request = c2cRequestById($id);

        try {
            if ($request === null) {
                $answer = 'درخواست پیدا نشد';
            } elseif ((int) $request['status'] !== 0) {
                $answer = (int) $request['status'] === 1 ? 'قبلاً تایید شده است' : 'قبلاً رد شده است';
            } elseif ($act === 'approve') {
                $result = c2cApprove($id, 'telegram', 'تایید از تلگرام');
                $mode = (string) ($result['grant']['mode'] ?? '');
                $answer = $mode === 'already-paid' ? 'سفارش قبلاً پرداخت شده بود؛ درخواست بسته شد' : 'تایید شد';
            } else {
                c2cReject($id, 'telegram', 'رد از تلگرام');
                $answer = 'رد شد';
            }
        } catch (Throwable $error) {
            $answer = 'انجام نشد: ' . $error->getMessage();
        }
    }

    if ($callbackId !== '') {
        c2cApiWith($token, 'answerCallbackQuery', [
            'callback_query_id' => $callbackId,
            'text'              => $answer,
        ]);
    }

    // take the buttons off the message: a decided request cannot be tapped again
    if ($messageId > 0 && $chatId !== '') {
        c2cApiWith($token, 'editMessageReplyMarkup', [
            'chat_id'      => $chatId,
            'message_id'   => $messageId,
            'reply_markup' => json_encode(['inline_keyboard' => []]),
        ]);
    }

    done(['ok' => true]);
}

// ---------------------------------------------------------------- dispatch

$c2cAction = substr((string) ($_GET['do'] ?? ''), strlen('c2c.'));

$c2cNeedsPost = ['submit', 'ack', 'settings', 'cards', 'approve', 'reject'];

if (in_array($c2cAction, $c2cNeedsPost, true) && $_SERVER['REQUEST_METHOD'] !== 'POST') {
    fail('this action needs POST', 405);
}

switch ($c2cAction) {
    case 'info':
        c2cUserInfo();
    case 'submit':
        c2cUserSubmit();
    case 'status':
        c2cUserStatus();
    case 'ack':
        c2cUserAck();
    case 'admin':
        c2cAdminBootstrap();
    case 'settings':
        c2cAdminSettings();
    case 'webhook':
        c2cAdminWebhook();
    case 'cards':
        c2cAdminCards();
    case 'approve':
        c2cAdminApprove();
    case 'reject':
        c2cAdminReject();
    case 'decide':
        c2cDecidePage();
    case 'tgwebhook':
        c2cTelegramWebhook();
}

fail('unknown card-to-card action');
