<?php
/**
 * Plan reservation - buy a subscription now, have it start later.
 *
 * This file is included by public/xmplus-patch.php, in its global scope, and
 * borrows that file's helpers: db(), fail(), done(), setting(), putSetting(),
 * startPanelSession(), requireAdmin() and requireToken(). It never returns -
 * every path ends in done() or fail().
 *
 * A reservation cannot be a deferred subscription order: the panel's checkout
 * and the code that applies a subscription are ionCube encoded, so a paid
 * subscription would start at once. Instead the reservation is sold as an
 * ordinary traffic top-up (type 1, bandwidth 0) whose `order_note` carries a
 * marker, exactly like a time plan - coupon, gateway, invoice and order history
 * all stay the panel's own. The subscription is started later by
 * app/Jobs/ReserveJob.php, once the current plan has ended (or the chosen date
 * has come); the plan's numbers ride in `plan_reserve` so the row itself may be
 * switched off in the meantime.
 */
declare(strict_types=1);

const RESERVE_MARKER = '"planreserve"';
const RESERVE_SETTING_ENABLED = 'reserve_enabled';
const RESERVE_SETTING_MAX_DAYS = 'reserve_max_days';
const RESERVE_MAX_AHEAD = 3650;

/* the billing cycles that can be reserved, with their length in days */
const RESERVE_CYCLES = [
    'month'      => 30,
    'quater'     => 90,
    'semiannual' => 180,
    'annual'     => 360,
];

// ------------------------------------------------------------------ helpers

function reserveMeta($note): ?array
{
    if (!is_string($note) || strpos($note, RESERVE_MARKER) === false) {
        return null;
    }

    $data = json_decode($note, true);

    return isset($data['planreserve']) && is_array($data['planreserve']) ? $data['planreserve'] : null;
}

function reserveInt($value, int $fallback = 0): int
{
    return is_numeric($value) ? (int) $value : $fallback;
}

function reserveSetting(string $name, string $fallback): string
{
    $value = setting($name, null);

    return $value === null || $value === '' ? $fallback : (string) $value;
}

function reserveEnabled(): bool
{
    return reserveSetting(RESERVE_SETTING_ENABLED, '1') === '1';
}

function reserveMaxDays(): int
{
    $days = reserveInt(reserveSetting(RESERVE_SETTING_MAX_DAYS, '365'), 365);

    if ($days < 1) {
        $days = 365;
    }

    return min($days, RESERVE_MAX_AHEAD);
}

/** The word a cycle's name carries in the buyer's language. */
function reserveCycleWord(string $cycle): string
{
    $locale = $_SESSION['locale'] ?? 'fa_IR';

    if ($locale === 'en_US') {
        $words = ['month' => 'monthly', 'quater' => 'quarterly',
            'semiannual' => 'semi-annual', 'annual' => 'annual', 'custom' => 'custom'];
    } elseif ($locale === 'zh_CN') {
        $words = ['month' => 'monthly', 'quater' => 'quarterly',
            'semiannual' => 'semi-annual', 'annual' => 'annual', 'custom' => 'custom'];
    } else {
        $words = ['month' => 'ماهانه', 'quater' => 'س‌ماهه',
            'semiannual' => 'شش‌ماهه', 'annual' => 'سالانه', 'custom' => 'سفارشی'];
    }

    return $words[$cycle] ?? $cycle;
}

/** The sentence a reservation's own top-up row is named after. */
function reserveRowName(array $plan, string $cycle): string
{
    $locale = $_SESSION['locale'] ?? 'fa_IR';

    $prefix = $locale === 'en_US' ? 'Reserved'
        : ($locale === 'zh_CN' ? 'Reserved' : 'رزرو');

    return sprintf('%s %s - %s', $prefix, (string) $plan['name'], reserveCycleWord($cycle));
}

/** A subscription plan that may be reserved, or null. */
function reservePlan(int $id): ?array
{
    if ($id <= 0) {
        return null;
    }

    $statement = db()->prepare('SELECT * FROM package WHERE id = ? AND type = 2 AND status = 1 LIMIT 1');
    $statement->execute([$id]);
    $row = $statement->fetch();

    return $row === false ? null : $row;
}

/** The chosen cycle's price, as it stands on the plan right now. */
function reserveCyclePrice(array $plan, string $cycle): float
{
    $options = json_decode((string) $plan['price_option'], true);

    return (float) ($options[$cycle]['price'] ?? 0);
}

/** The chosen cycle's length in days, or 0 when it cannot be reserved. */
function reserveCycleDays(array $plan, string $cycle): int
{
    if (isset(RESERVE_CYCLES[$cycle])) {
        return RESERVE_CYCLES[$cycle];
    }

    if ($cycle === 'custom') {
        $options = json_decode((string) $plan['price_option'], true);

        return reserveInt($options['custom']['expire'] ?? 0);
    }

    return 0;
}

/**
 * The package row the encoded checkout will charge.
 *
 * One row per (plan, cycle), kept in step with the plan: its price is the
 * plan's price for that cycle as it stands now (a running promotion's
 * discounted price included), and it carries the marker ReserveJob reads. The
 * row is never shown as a top-up or as a plan, and it is only ever found by its
 * exact marker.
 */
function reserveMintRow(array $plan, string $cycle, int $days): int
{
    $meta = [
        'v'     => 1,
        'plan'  => (int) $plan['id'],
        'cycle' => $cycle,
        'days'  => $days,
    ];

    $note = (string) json_encode(['planreserve' => $meta], JSON_UNESCAPED_UNICODE);
    $price = number_format(reserveCyclePrice($plan, $cycle), 2, '.', '');

    $option = (string) json_encode([
        'topup'      => ['price' => $price],
        'custom'     => ['price' => '', 'expire' => ''],
        'onetime'    => ['price' => ''],
        'month'      => ['price' => ''],
        'quater'     => ['price' => ''],
        'semiannual' => ['price' => ''],
        'annual'     => ['price' => ''],
    ]);

    $bandwidth = reserveSetting('timeplan_bandwidth', '0');
    $name = reserveRowName($plan, $cycle);

    $existing = db()->prepare('SELECT id FROM package WHERE type = 1 AND order_note = ? LIMIT 1');
    $existing->execute([$note]);
    $row = $existing->fetch();

    if ($row !== false) {
        db()->prepare('UPDATE package SET name = ?, status = 1, price_option = ?, bandwidth = ? WHERE id = ?')
            ->execute([$name, $option, $bandwidth, (int) $row['id']]);

        return (int) $row['id'];
    }

    $statement = db()->prepare(
        'INSERT INTO package (type, name, status, price_option, upgrade, bandwidth, iplimit,
                              speedlimit, server_group, order_note, sort, renew_type, reset_days,
                              stocks, stockcount, order_type)
              VALUES (1, ?, 1, ?, 0, ?, 0, 0, 1, ?, 0, 0, 0, 0, 0, 1)');

    $statement->execute([$name, $option, $bandwidth, $note]);

    return (int) db()->lastInsertId();
}

/**
 * The reservation this user is sitting on - prepared but unpaid, or paid and
 * waiting to start. Only one is ever allowed at a time.
 */
function reserveActiveRow(int $userId, bool $throw = false): ?array
{
    $statement = db()->prepare(
        'SELECT * FROM plan_reserve WHERE userid = ? AND status IN (0, 1) ORDER BY id DESC LIMIT 1');
    $statement->execute([$userId]);
    $row = $statement->fetch();

    return $row === false ? null : $row;
}

/** An abandoned check-out must not block a fresh one. */
function reserveVoidStale(): void
{
    db()->prepare('DELETE FROM plan_reserve WHERE status = 0 AND created_at < ?')
        ->execute([time() - 3600]);
}

// --------------------------------------------------------------------- auth

/**
 * The buying half answers ordinary users, so it cannot go through
 * requireAdmin(). Same session and expiry check, no role demand.
 */
function reserveRequireUser(): array
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
        'SELECT id, packageid, server_group, expire_in, plan FROM user WHERE id = ? LIMIT 1');
    $statement->execute([(int) $login['uid']]);
    $user = $statement->fetch();

    if ($user === false) {
        fail('account not found', 403);
    }

    return $user;
}

function reserveUserToken(): string
{
    if (empty($_SESSION['reserve_csrf'])) {
        $_SESSION['reserve_csrf'] = bin2hex(random_bytes(24));
    }

    return (string) $_SESSION['reserve_csrf'];
}

function reserveRequireUserToken(): void
{
    $sent = $_POST['token'] ?? '';
    $held = $_SESSION['reserve_csrf'] ?? '';

    if ($held === '' || !is_string($sent) || !hash_equals($held, $sent)) {
        fail('bad or missing token', 403);
    }
}

// ----------------------------------------------------------------- user ui

/** What the plan page needs: the token, the rules and any live reservation. */
function reserveUserMine(): void
{
    $user = reserveRequireUser();
    reserveVoidStale();

    $row = reserveActiveRow((int) $user['id']);

    done([
        'token'    => reserveUserToken(),
        'enabled'  => reserveEnabled() ? 1 : 0,
        'max_days' => reserveMaxDays(),
        'active'   => $row === null ? null : reservePresent($row),
    ]);
}

function reservePresent(array $row): array
{
    return [
        'id'          => (int) $row['id'],
        'plan'        => (int) $row['planid'],
        'name'        => (string) $row['name'],
        'cycle'       => (string) $row['cycle'],
        'days'        => (int) $row['days'],
        'mode'        => (string) $row['mode'],
        'activate_at' => (int) $row['activate_at'],
        'amount'      => (float) $row['amount'],
        'status'      => (int) $row['status'],
    ];
}

/**
 * Turns "reserve this plan for this cycle" into a buyable package.
 *
 * The answer names the package and the topup plan the browser must post to the
 * panel's own checkout, exactly as the "add data" flow does.
 */
function reservePrepare(): void
{
    $user = reserveRequireUser();
    reserveRequireUserToken();

    if (!reserveEnabled()) {
        fail('reserving a plan is switched off');
    }

    reserveVoidStale();

    // an abandoned check-out must not block a fresh one: drop this user's
    // unpaid intents. Only a *paid* reservation is a real block.
    db()->prepare('DELETE FROM plan_reserve WHERE userid = ? AND status = 0')
        ->execute([(int) $user['id']]);

    if (reserveActiveRow((int) $user['id']) !== null) {
        fail('you already have a reserved plan');
    }

    $plan = reservePlan(reserveInt($_POST['plan'] ?? 0));

    if ($plan === null) {
        fail('that plan is not available');
    }

    $cycle = (string) ($_POST['cycle'] ?? '');
    $days = reserveCycleDays($plan, $cycle);

    if ($days < 1) {
        fail('that billing cycle cannot be reserved');
    }

    if (reserveCyclePrice($plan, $cycle) <= 0) {
        fail('that billing cycle has no price');
    }

    $mode = ($_POST['mode'] ?? 'after') === 'date' ? 'date' : 'after';
    $activateAt = 0;

    if ($mode === 'date') {
        $raw = trim((string) ($_POST['activate_at'] ?? ''));
        $stamp = $raw === '' ? false : strtotime($raw);

        if ($stamp === false) {
            fail('choose the date the reserved plan should start');
        }

        $today = strtotime('today');

        if ($stamp < $today) {
            fail('the date cannot be in the past');
        }

        if ($stamp > time() + reserveMaxDays() * 86400) {
            fail('that date is too far ahead');
        }

        $activateAt = (int) $stamp;
    }

    $packageid = reserveMintRow($plan, $cycle, $days);

    $statement = db()->prepare(
        'INSERT INTO plan_reserve
            (userid, orderid, packageid, planid, cycle, days, mode, activate_at, amount, name,
             bandwidth, iplimit, speedlimit, server_group, status, created_at)
         VALUES (?, NULL, ?, ?, ?, ?, ?, ?, 0, ?, ?, ?, ?, ?, 0, ?)');

    $statement->execute([
        (int) $user['id'], $packageid, (int) $plan['id'], $cycle, $days, $mode, $activateAt,
        (string) $plan['name'], (int) $plan['bandwidth'], (int) $plan['iplimit'],
        (int) $plan['speedlimit'], (int) $plan['server_group'], time(),
    ]);

    done([
        'packageid'   => $packageid,
        'plan'        => 'topup',
        'days'        => $days,
        'mode'        => $mode,
        'activate_at' => $activateAt,
    ]);
}

/**
 * Cancel a reservation and put the money back into the buyer's account credit.
 *
 * Only a reservation that has not started can be cancelled. A paid one is
 * refunded in full into `user.money` (the payment itself is not reversed - it
 * becomes store credit, which is what the buyer asked for); an unpaid one is
 * simply dropped. The reservation row is claimed first, so a second request
 * can never refund twice.
 */
function reserveCancel(): void
{
    $user = reserveRequireUser();
    reserveRequireUserToken();

    $row = reserveActiveRow((int) $user['id']);

    if ($row === null) {
        fail('you have no reservation to cancel');
    }

    // claim it: a zero row count means another request got there first
    $claim = db()->prepare(
        'UPDATE plan_reserve SET status = 3, cancelled_at = ? WHERE id = ? AND status IN (0, 1)');
    $claim->execute([time(), (int) $row['id']]);

    if ($claim->rowCount() < 1) {
        fail('that reservation was already settled');
    }

    $refunded = 0.0;

    if ((int) $row['status'] === 1 && !empty($row['orderid'])) {
        $order = db()->prepare('SELECT id, total_amount, pay_date FROM orders WHERE id = ? LIMIT 1');
        $order->execute([(int) $row['orderid']]);
        $paid = $order->fetch();

        // pay_date is the durable proof the money moved: the
        // panel may have moved the order's status since payment
        // (its own order list can cancel a paid order), and the
        // reservation row remembers the amount even when the
        // order row itself is gone
        if ($paid !== false && !empty($paid['pay_date'])) {
            $refunded = (float) $paid['total_amount'];

            // total_amount is in rial, so the credit must be ریال too
            db()->prepare('UPDATE user SET money = money + ? WHERE id = ?')
                ->execute([$refunded, (int) $user['id']]);
        } elseif ($paid === false && (float) $row['amount'] > 0) {
            $refunded = (float) $row['amount'];

            db()->prepare('UPDATE user SET money = money + ? WHERE id = ?')
                ->execute([$refunded, (int) $user['id']]);
        }
    }

    // the banner had shown "your reserved plan is booked" for it; that notice
    // must not come back now that it was cancelled
    try {
        db()->prepare('UPDATE reserve_notice SET seen = 1 WHERE userid = ? AND seen = 0 AND `ref` = ?')
            ->execute([(int) $user['id'], 'r:' . (int) $row['id']]);
    } catch (Throwable $error) {
    }

    // the money went back to the buyer's credit: tell them, the
    // same way the other reservation events are told
    if ($refunded > 0) {
        try {
            (new \App\Jobs\ReserveJob)->announceRefund((int) $user['id'], $refunded);
        } catch (Throwable $error) {
        }
    }

    done(['refunded' => $refunded]);
}

/**
 * The banner's close button: mark the account's reservation notices as seen,
 * so they do not come back on the next page.
 */
function reserveAck(): void
{
    $user = reserveRequireUser();
    reserveRequireUserToken();

    try {
        db()->prepare('UPDATE reserve_notice SET seen = 1 WHERE userid = ? AND seen = 0')
            ->execute([(int) $user['id']]);
    } catch (Throwable $error) {
        // the table is created by the migration or by ReserveJob; a missing one
        // simply means there is nothing to acknowledge
    }

    done(['ok' => 1]);
}

// ------------------------------------------------------------------- admin

function reserveAdminBootstrap(): void
{
    requireAdmin();

    if (empty($_SESSION['patch_csrf'])) {
        $_SESSION['patch_csrf'] = bin2hex(random_bytes(24));
    }

    $list = db()->query(
        'SELECT r.*, u.username, u.email
           FROM plan_reserve r
           LEFT JOIN user u ON u.id = r.userid
          ORDER BY r.id DESC LIMIT 100')->fetchAll();

    $rows = [];
    foreach ($list as $row) {
        $rows[] = [
            'id'          => (int) $row['id'],
            'userid'      => (int) $row['userid'],
            'username'    => (string) ($row['username'] ?? ''),
            'email'       => (string) ($row['email'] ?? ''),
            'name'        => (string) $row['name'],
            'cycle'       => (string) $row['cycle'],
            'days'        => (int) $row['days'],
            'mode'        => (string) $row['mode'],
            'activate_at' => (int) $row['activate_at'],
            'amount'      => (float) $row['amount'],
            'status'      => (int) $row['status'],
            'created_at'  => (int) $row['created_at'],
            'activated_at' => (int) $row['activated_at'],
            'cancelled_at' => (int) $row['cancelled_at'],
        ];
    }

    $counts = db()->query(
        'SELECT status, COUNT(*) AS n FROM plan_reserve GROUP BY status')->fetchAll();
    $byStatus = ['pending' => 0, 'waiting' => 0, 'activated' => 0, 'cancelled' => 0];
    foreach ($counts as $count) {
        switch ((int) $count['status']) {
            case 0: $byStatus['pending'] = (int) $count['n']; break;
            case 1: $byStatus['waiting'] = (int) $count['n']; break;
            case 2: $byStatus['activated'] = (int) $count['n']; break;
            case 3: $byStatus['cancelled'] = (int) $count['n']; break;
        }
    }

    done([
        'token'    => $_SESSION['patch_csrf'],
        'settings' => [
            'enabled'  => reserveEnabled() ? 1 : 0,
            'max_days' => reserveMaxDays(),
        ],
        'counts' => $byStatus,
        'list'   => $rows,
    ]);
}

function reserveAdminSettings(): void
{
    requireAdmin();
    requireToken();

    $enabled = reserveInt($_POST['enabled'] ?? 0) === 1 ? 1 : 0;
    $maxDays = reserveInt($_POST['max_days'] ?? 365, 365);

    if ($maxDays < 1 || $maxDays > RESERVE_MAX_AHEAD) {
        fail('the maximum lead time must be between 1 and ' . RESERVE_MAX_AHEAD . ' days');
    }

    putSetting(RESERVE_SETTING_ENABLED, (string) $enabled);
    putSetting(RESERVE_SETTING_MAX_DAYS, (string) $maxDays);

    done(['enabled' => $enabled, 'max_days' => $maxDays]);
}

// ---------------------------------------------------------------- dispatch

$reserveAction = substr((string) ($_GET['do'] ?? ''), strlen('reserve.'));

$reserveNeedsPost = ['prepare', 'cancel', 'ack', 'settings'];

if (in_array($reserveAction, $reserveNeedsPost, true) && $_SERVER['REQUEST_METHOD'] !== 'POST') {
    fail('this action needs POST', 405);
}

switch ($reserveAction) {
    case 'mine':
        reserveUserMine();
    case 'prepare':
        reservePrepare();
    case 'cancel':
        reserveCancel();
    case 'ack':
        reserveAck();
    case 'admin':
        reserveAdminBootstrap();
    case 'settings':
        reserveAdminSettings();
}

fail('unknown reservation action');
