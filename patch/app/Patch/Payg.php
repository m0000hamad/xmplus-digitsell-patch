<?php
/**
 * Pay-as-you-go wallet and the commission wallet - the web half.
 *
 * Included by public/xmplus-patch.php, in its global scope, before the blanket
 * requireAdmin(): the customer actions answer ordinary users. Borrows db(),
 * fail(), done(), setting(), putSetting(), startPanelSession(), requireAdmin()
 * and requireToken(). Every path ends in done() or fail().
 *
 * The money moves themselves - crediting paid charges, billing usage, the
 * plan/balance/empty modes - happen in app/Jobs/PaygJob.php. What is here:
 *
 *   payg.me              the customer's wallet card (GET)
 *   payg.mint            turn an amount into a buyable charge package
 *   payg.auto            the "fall back on the wallet" switch
 *   commission.apply     move commission into money right before a
 *                        subscription checkout (returned by the job if unused)
 *   payg.admin / payg.users / payg.ledger     admin reports (GET)
 *   payg.save / payg.rates / payg.adjust / commission.migrate   admin writes
 *
 * Amounts are in the panel's currency (rial).
 */

declare(strict_types=1);

const PAYG_MARKER = '"paygcharge"';
const PAYG_GB = 1073741824;
const PAYG_MAX_CHARGE = 100000000000;

// ------------------------------------------------------------------ helpers

function paygNumber($value): float
{
    $clean = str_replace([',', ' ', '،', '٬'], '', strtr((string) $value, [
        '۰' => '0', '۱' => '1', '۲' => '2', '۳' => '3', '۴' => '4',
        '۵' => '5', '۶' => '6', '۷' => '7', '۸' => '8', '۹' => '9', '٫' => '.', '−' => '-',
    ]));

    return is_numeric($clean) ? (float) $clean : 0.0;
}

function paygSetting(string $name, string $fallback): string
{
    $value = setting($name, null);

    return $value === null || $value === '' ? $fallback : (string) $value;
}

function paygEnabled(): bool
{
    return paygSetting('payg_enabled', '0') === '1';
}

function paygCommissionEnabled(): bool
{
    return paygSetting('commission_wallet_enabled', '0') === '1';
}

function paygTiers(): array
{
    $decoded = json_decode(paygSetting('payg_bonus_tiers', '[]'), true);
    $tiers = [];

    foreach (is_array($decoded) ? $decoded : [] as $tier) {
        $min = (float) ($tier['min'] ?? 0);
        $percent = (float) ($tier['percent'] ?? 0);

        if ($min > 0 && $percent > 0) {
            $tiers[] = ['min' => $min, 'percent' => min(100.0, $percent)];
        }
    }

    usort($tiers, static function (array $a, array $b): int {
        return $a['min'] <=> $b['min'];
    });

    return $tiers;
}

function paygBonusPercent(float $amount): float
{
    $best = 0.0;

    foreach (paygTiers() as $tier) {
        if ($amount >= $tier['min']) {
            $best = $tier['percent'];
        }
    }

    return $best;
}

/** Every server with its price per GB and whether it counts as down right now. */
function paygServers(): array
{
    $default = (float) paygSetting('payg_default_price', '0');
    $rates = [];

    foreach (db()->query('SELECT serverid, price FROM payg_rate') as $row) {
        $rates[(int) $row['serverid']] = (float) $row['price'];
    }

    $list = [];

    foreach (db()->query('SELECT id, name, status, alive, heartbeat FROM servers ORDER BY sort, id') as $row) {
        $id = (int) $row['id'];
        $age = (int) $row['heartbeat'] > 0 ? time() - (int) $row['heartbeat'] : PHP_INT_MAX;

        $list[] = [
            'id'      => $id,
            'name'    => (string) $row['name'],
            'enabled' => (int) $row['status'] === 1,
            'custom'  => array_key_exists($id, $rates),
            'price'   => array_key_exists($id, $rates) ? $rates[$id] : $default,
            'down'    => (int) $row['alive'] !== 1 || $age > 300,
        ];
    }

    return $list;
}

function paygMaxPrice(array $servers): float
{
    $max = (float) paygSetting('payg_default_price', '0');

    foreach ($servers as $server) {
        if ($server['enabled']) {
            $max = max($max, $server['price']);
        }
    }

    return $max;
}

function paygPriceOption(string $price): string
{
    return (string) json_encode([
        'topup'      => ['price' => $price],
        'custom'     => ['price' => '', 'expire' => ''],
        'onetime'    => ['price' => ''],
        'month'      => ['price' => ''],
        'quater'     => ['price' => ''],
        'semiannual' => ['price' => ''],
        'annual'     => ['price' => ''],
    ]);
}

function paygToman(): bool
{
    return paygSetting('payg_show_toman', '1') === '1';
}

/** "200,000 تومان" - the package name customers see on invoices. */
function paygMoneyText(float $rial): string
{
    return paygToman()
        ? number_format(round($rial / 10)) . ' تومان'
        : number_format(round($rial)) . ' ریال';
}

// --------------------------------------------------------------------- auth

function paygRequireUser(): array
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
        'SELECT id, username, money, packageid, expire_in, transfer_enable, u, d FROM user WHERE id = ? LIMIT 1');
    $statement->execute([(int) $login['uid']]);
    $user = $statement->fetch();

    if ($user === false) {
        fail('account not found', 403);
    }

    return $user;
}

function paygUserToken(): string
{
    if (empty($_SESSION['payg_csrf'])) {
        $_SESSION['payg_csrf'] = bin2hex(random_bytes(24));
    }

    return (string) $_SESSION['payg_csrf'];
}

function paygRequireUserToken(): void
{
    $sent = $_POST['token'] ?? '';
    $held = $_SESSION['payg_csrf'] ?? '';

    if ($held === '' || !is_string($sent) || !hash_equals($held, $sent)) {
        fail('bad or missing token', 403);
    }
}

function paygAdminToken(): string
{
    if (empty($_SESSION['patch_csrf'])) {
        $_SESSION['patch_csrf'] = bin2hex(random_bytes(24));
    }

    return (string) $_SESSION['patch_csrf'];
}

// ------------------------------------------------------------------ wallets

function paygWallet(int $userId): array
{
    $statement = db()->prepare('SELECT * FROM payg_wallet WHERE userid = ? LIMIT 1');
    $statement->execute([$userId]);
    $row = $statement->fetch();

    return $row === false
        ? ['userid' => $userId, 'balance' => 0, 'charged' => 0, 'bonus' => 0, 'adjusted' => 0,
           'spent' => 0, 'mode' => 'plan', 'auto' => 1, 'since' => 0]
        : $row;
}

function paygCommissionBalance(int $userId): float
{
    $statement = db()->prepare('SELECT balance FROM commission_wallet WHERE userid = ? LIMIT 1');
    $statement->execute([$userId]);

    return (float) ($statement->fetchColumn() ?: 0);
}

/**
 * Hand back commission sitting in money for a checkout that did not happen,
 * before a wallet charge is bought - the panel's checkout spends money first,
 * and commission must not turn into charge credit. Same bookkeeping as
 * PaygJob::resolveHolds().
 */
function paygReturnHolds(int $userId): void
{
    $pdo = db();
    $open = $pdo->prepare('SELECT id FROM commission_hold WHERE userid = ? AND resolved = 0');
    $open->execute([$userId]);
    $ids = $open->fetchAll(PDO::FETCH_COLUMN);

    foreach ($ids as $id) {
        $pdo->beginTransaction();

        try {
            $hold = $pdo->prepare('SELECT * FROM commission_hold WHERE id = ? FOR UPDATE');
            $hold->execute([(int) $id]);
            $row = $hold->fetch();

            if ($row === false || (int) $row['resolved'] === 1) {
                $pdo->commit();
                continue;
            }

            $user = $pdo->prepare('SELECT money FROM user WHERE id = ? FOR UPDATE');
            $user->execute([$userId]);
            $money = max(0.0, (float) $user->fetchColumn());
            $back = round(min((float) $row['amount'], $money), 2);

            $pdo->prepare('INSERT IGNORE INTO commission_wallet (userid, updated) VALUES (?, ?)')->execute([$userId, time()]);
            $wallet = $pdo->prepare('SELECT balance FROM commission_wallet WHERE userid = ? FOR UPDATE');
            $wallet->execute([$userId]);
            $balance = (float) $wallet->fetchColumn() + $back;

            $pdo->prepare('UPDATE user SET money = money - ? WHERE id = ?')->execute([$back, $userId]);
            $pdo->prepare('UPDATE commission_wallet SET balance = ?, spent = spent + ?, updated = ? WHERE userid = ?')
                ->execute([$balance, (float) $row['amount'] - $back, time(), $userId]);
            $pdo->prepare('INSERT INTO commission_wallet_log (userid, kind, ref, amount, balance_after, note, created)
                           VALUES (?, \'return\', ?, ?, ?, ?, ?)')
                ->execute([$userId, 'hold:' . $row['id'], $back, $balance, 'before a wallet charge', time()]);
            $pdo->prepare('UPDATE commission_hold SET resolved = 1, returned = ?, resolved_at = ? WHERE id = ?')
                ->execute([$back, time(), (int) $row['id']]);

            $pdo->commit();
        } catch (Throwable $error) {
            $pdo->rollBack();
        }
    }
}

// --------------------------------------------------------------------- user

function paygUserMe(): void
{
    $user = paygRequireUser();
    $id = (int) $user['id'];
    $wallet = paygWallet($id);
    $servers = paygServers();
    $max = paygMaxPrice($servers);
    $today = strtotime('today');

    $spent = db()->prepare(
        "SELECT COALESCE(SUM(CASE WHEN updated >= ? THEN -amount ELSE 0 END), 0) AS today,
                COALESCE(SUM(-amount), 0) AS month,
                COALESCE(SUM(CASE WHEN updated >= ? THEN bytes + free_bytes ELSE 0 END), 0) AS today_bytes
           FROM payg_ledger
          WHERE userid = ? AND kind = 'usage' AND updated >= ?");
    $spent->execute([$today, $today, $id, $today - 29 * 86400]);
    $totals = $spent->fetch() ?: ['today' => 0, 'month' => 0, 'today_bytes' => 0];

    $history = db()->prepare(
        'SELECT l.kind, l.amount, l.balance_after, l.bytes, l.free_bytes, l.created, l.updated, l.note,
                COALESCE(s.name, \'\') AS server
           FROM payg_ledger l LEFT JOIN servers s ON s.id = l.serverid
          WHERE l.userid = ? ORDER BY l.updated DESC, l.id DESC LIMIT 60');
    $history->execute([$id]);

    // paid top-ups the job has not credited yet (it runs once a minute)
    $pending = 0.0;
    $open = db()->prepare(
        "SELECT o.id, o.discount, p.order_note
           FROM orders o JOIN package p ON p.id = o.packageid
          WHERE o.userid = ? AND o.status = 1 AND p.order_note LIKE ?
            AND NOT EXISTS (SELECT 1 FROM payg_ledger l WHERE l.ref = CONCAT('order:', o.id))
          LIMIT 20");
    $open->execute([$id, '%' . PAYG_MARKER . '%']);
    foreach ($open as $row) {
        $meta = json_decode((string) $row['order_note'], true);
        $pending += max(0.0, (float) ($meta['paygcharge']['amount'] ?? 0) - max(0.0, (float) $row['discount']));
    }

    $notices = db()->prepare(
        'SELECT id, kind, text, created FROM payg_notice WHERE userid = ? AND seen = 0 ORDER BY id DESC LIMIT 5');
    $notices->execute([$id]);
    $unseen = $notices->fetchAll();

    // an admin previewing someone's portal leaves their notices unread
    if ($unseen !== [] && empty($_SESSION['adminview'])) {
        db()->prepare('UPDATE payg_notice SET seen = 1 WHERE userid = ? AND seen = 0')->execute([$id]);
    }

    $balance = (float) $wallet['balance'];

    done([
        'token'    => paygUserToken(),
        'enabled'  => paygEnabled(),
        'toman'    => paygToman(),
        'wallet'   => [
            'balance' => $balance,
            'charged' => (float) $wallet['charged'],
            'bonus'   => (float) $wallet['bonus'] + (float) $wallet['adjusted'],
            'spent'   => (float) $wallet['spent'],
            'mode'    => (string) $wallet['mode'],
            'auto'    => (int) $wallet['auto'] === 1,
            'since'   => (int) $wallet['since'],
        ],
        'pending'     => $pending,
        'today'       => (float) $totals['today'],
        'month'       => (float) $totals['month'],
        'today_bytes' => (float) $totals['today_bytes'],
        'headroom'    => $max > 0 ? max(0.0, $balance) / $max * PAYG_GB : null,
        'rates'       => array_values(array_map(static function (array $s): array {
            return ['name' => $s['name'], 'price' => $s['price'], 'down' => $s['down']];
        }, array_filter($servers, static function (array $s): bool {
            return $s['enabled'];
        }))),
        'outage_free' => paygSetting('payg_outage_free', '1') === '1',
        'min'         => (float) paygSetting('payg_min_charge', '2000000'),
        'step'        => (float) paygSetting('payg_charge_step', '100000'),
        'tiers'       => paygTiers(),
        'history'     => $history->fetchAll(),
        'notices'     => $unseen,
        'commission'  => [
            'enabled' => paygCommissionEnabled(),
            'balance' => paygCommissionEnabled() ? paygCommissionBalance($id) : 0,
        ],
    ]);
}

/**
 * An amount becomes a package the panel's checkout can sell: a topup row with
 * no traffic, priced at the amount, carrying the marker PaygJob credits from.
 * One row per amount, reused; rows nobody bought are removed after a day.
 */
function paygUserMint(): void
{
    $user = paygRequireUser();
    paygRequireUserToken();

    if (!paygEnabled()) {
        fail('شارژ کیف پول فعلاً غیرفعال است');
    }

    $min = (float) paygSetting('payg_min_charge', '2000000');
    $step = max(1.0, (float) paygSetting('payg_charge_step', '100000'));
    $amount = paygNumber($_POST['amount'] ?? 0);

    if ($amount <= 0) {
        fail('مبلغ شارژ را وارد کنید');
    }

    if ($amount < $min) {
        fail('حداقل مبلغ شارژ ' . paygMoneyText($min) . ' است');
    }

    if ($amount > PAYG_MAX_CHARGE) {
        fail('این مبلغ بیش از حد مجاز است');
    }

    // whole amounts are written as integers, so the marker lookup below matches
    $amount = ceil($amount / $step) * $step;
    $amount = floor($amount) == $amount ? (int) $amount : $amount;

    if (paygCommissionEnabled()) {
        paygReturnHolds((int) $user['id']);
    }

    $name = 'شارژ حساب ' . paygMoneyText($amount);
    $note = (string) json_encode(['paygcharge' => ['v' => 1, 'amount' => $amount, 'created' => time()]]);
    $price = number_format($amount, 2, '.', '');

    $existing = db()->prepare(
        'SELECT id FROM package WHERE type = 1 AND order_note LIKE ? AND order_note LIKE ? LIMIT 1');
    $existing->execute(['%' . PAYG_MARKER . '%', '%"amount":' . json_encode($amount) . ',%']);
    $row = $existing->fetch();

    if ($row !== false) {
        db()->prepare('UPDATE package SET status = 1, name = ?, price_option = ?, order_note = ? WHERE id = ?')
            ->execute([$name, paygPriceOption($price), $note, (int) $row['id']]);

        done(['packageid' => (int) $row['id'], 'amount' => $amount, 'bonus' => paygBonusPercent($amount)]);
    }

    $statement = db()->prepare(
        'INSERT INTO package (type, name, status, price_option, upgrade, bandwidth, iplimit,
                              speedlimit, server_group, order_note, sort, renew_type, reset_days,
                              stocks, stockcount, order_type)
              VALUES (1, ?, 1, ?, 0, ?, 0, 0, 1, ?, 0, 0, 0, 0, 0, 1)');

    $statement->execute([$name, paygPriceOption($price), paygSetting('timeplan_bandwidth', '0'), $note]);

    done(['packageid' => (int) db()->lastInsertId(), 'amount' => $amount, 'bonus' => paygBonusPercent($amount)]);
}

function paygUserAuto(): void
{
    $user = paygRequireUser();
    paygRequireUserToken();

    $on = (int) ($_POST['on'] ?? 1) === 1 ? 1 : 0;

    db()->prepare('INSERT INTO payg_wallet (userid, auto, updated) VALUES (?, ?, ?)
                   ON DUPLICATE KEY UPDATE auto = VALUES(auto), updated = VALUES(updated)')
        ->execute([(int) $user['id'], $on, time()]);

    done(['auto' => $on === 1]);
}

/** What the checkout pages need to offer the commission wallet. */
function paygCommissionMe(): void
{
    $user = paygRequireUser();

    done([
        'token'   => paygUserToken(),
        'enabled' => paygCommissionEnabled(),
        'balance' => paygCommissionEnabled() ? paygCommissionBalance((int) $user['id']) : 0,
        'money'   => max(0.0, (float) $user['money']),
        'toman'   => paygToman(),
    ]);
}

/**
 * Commission pays for subscription plans only. The encoded checkout spends
 * user.money, so just before the order is created the needed part of the
 * commission wallet is moved there, and remembered in commission_hold; the job
 * returns whatever the checkout did not use.
 */
function paygCommissionApply(): void
{
    $user = paygRequireUser();
    paygRequireUserToken();

    if (!paygCommissionEnabled()) {
        fail('the commission wallet is switched off');
    }

    $packageId = (int) ($_POST['packageid'] ?? 0);
    $cycle = (string) ($_POST['plan'] ?? '');

    $statement = db()->prepare('SELECT id, type, status, price_option FROM package WHERE id = ? LIMIT 1');
    $statement->execute([$packageId]);
    $package = $statement->fetch();

    if ($package === false || (int) $package['type'] !== 2 || (int) $package['status'] !== 1) {
        fail('commission can only pay for a subscription plan');
    }

    $options = json_decode((string) $package['price_option'], true);
    $price = paygNumber($options[$cycle]['price'] ?? 0);

    if ($price <= 0) {
        fail('that billing cycle has no price');
    }

    $userId = (int) $user['id'];
    $pdo = db();
    $pdo->beginTransaction();

    try {
        $pdo->prepare('INSERT IGNORE INTO commission_wallet (userid, updated) VALUES (?, ?)')->execute([$userId, time()]);
        $wallet = $pdo->prepare('SELECT balance FROM commission_wallet WHERE userid = ? FOR UPDATE');
        $wallet->execute([$userId]);
        $balance = (float) $wallet->fetchColumn();

        // money already there is spent first by the checkout; only the gap is moved
        $money = $pdo->prepare('SELECT money FROM user WHERE id = ? FOR UPDATE');
        $money->execute([$userId]);
        $have = max(0.0, (float) $money->fetchColumn());
        $move = round(min($balance, max(0.0, $price - $have)), 2);

        if ($move <= 0) {
            $pdo->commit();
            done(['moved' => 0, 'balance' => $balance]);
        }

        $after = $balance - $move;

        $pdo->prepare('UPDATE commission_wallet SET balance = ?, updated = ? WHERE userid = ?')
            ->execute([$after, time(), $userId]);
        $pdo->prepare('UPDATE user SET money = money + ? WHERE id = ?')->execute([$move, $userId]);
        $pdo->prepare('INSERT INTO commission_hold (userid, packageid, amount, created) VALUES (?, ?, ?, ?)')
            ->execute([$userId, $packageId, $move, time()]);
        $holdId = (int) $pdo->lastInsertId();
        $pdo->prepare('INSERT INTO commission_wallet_log (userid, kind, ref, amount, balance_after, note, created)
                       VALUES (?, \'apply\', ?, ?, ?, ?, ?)')
            ->execute([$userId, 'apply:' . $holdId, -$move, $after, 'package #' . $packageId . ' ' . $cycle, time()]);

        $pdo->commit();
    } catch (Throwable $error) {
        $pdo->rollBack();
        fail('could not use the commission wallet');
    }

    done(['moved' => $move, 'balance' => $after]);
}

// ------------------------------------------------------------------- admin

/** The wallet settings as the admin form shows them. Amounts stay in rial. */
function paygAdminSettings(): array
{
    $settings = [];
    foreach (['payg_enabled' => '0', 'payg_min_charge' => '2000000', 'payg_charge_step' => '100000',
              'payg_default_price' => '0', 'payg_low_balance' => '500000', 'payg_outage_free' => '1',
              'payg_warn_percent' => '80,95', 'payg_warn_days' => '3,1', 'payg_show_toman' => '1',
              'payg_group' => '0', 'commission_wallet_enabled' => '0', 'sub_info_enabled' => '0',
              'sub_origin' => ''] as $name => $fallback) {
        $settings[$name] = paygSetting($name, $fallback);
    }

    // an empty origin IP is a real choice (do not pin), not "unset"
    $settings['sub_origin_ip'] = (string) setting('sub_origin_ip', '127.0.0.1');

    return $settings;
}

function paygAdminBootstrap(): void
{
    requireAdmin();

    $settings = paygAdminSettings();

    $totals = db()->query(
        "SELECT COUNT(*) AS wallets,
                COALESCE(SUM(charged), 0) AS charged, COALESCE(SUM(bonus), 0) AS bonus,
                COALESCE(SUM(adjusted), 0) AS adjusted, COALESCE(SUM(spent), 0) AS spent,
                COALESCE(SUM(CASE WHEN balance > 0 THEN balance ELSE 0 END), 0) AS unspent,
                COALESCE(SUM(CASE WHEN balance < 0 THEN -balance ELSE 0 END), 0) AS owed,
                SUM(mode = 'balance') AS on_balance, SUM(mode = 'empty') AS empty
           FROM payg_wallet")->fetch();

    $today = strtotime('today');
    $usage = db()->prepare(
        "SELECT COALESCE(SUM(CASE WHEN updated >= ? THEN -amount ELSE 0 END), 0) AS today,
                COALESCE(SUM(-amount), 0) AS month
           FROM payg_ledger WHERE kind = 'usage' AND updated >= ?");
    $usage->execute([$today, $today - 29 * 86400]);

    $perServer = db()->prepare(
        "SELECT l.serverid, COALESCE(MAX(s.name), CONCAT('#', l.serverid)) AS name,
                COALESCE(SUM(-l.amount), 0) AS revenue, COALESCE(SUM(l.bytes), 0) AS bytes,
                COALESCE(SUM(l.free_bytes), 0) AS free_bytes
           FROM payg_ledger l LEFT JOIN servers s ON s.id = l.serverid
          WHERE l.kind = 'usage' AND l.updated >= ?
          GROUP BY l.serverid ORDER BY revenue DESC");
    $perServer->execute([$today - 29 * 86400]);

    $commission = ['balance' => 0, 'earned' => 0, 'spent' => 0, 'wallets' => 0];
    try {
        $commission = db()->query(
            'SELECT COUNT(*) AS wallets, COALESCE(SUM(balance), 0) AS balance,
                    COALESCE(SUM(earned), 0) AS earned, COALESCE(SUM(spent), 0) AS spent
               FROM commission_wallet')->fetch();
    } catch (Throwable $error) {
    }

    $legacy = (float) db()->query('SELECT COALESCE(SUM(money), 0) FROM user WHERE money > 0')->fetchColumn();

    done([
        'token'      => paygAdminToken(),
        'settings'   => $settings,
        'tiers'      => paygTiers(),
        'servers'    => paygServers(),
        'totals'     => $totals,
        'usage'      => $usage->fetch(),
        'per_server' => $perServer->fetchAll(),
        'commission' => $commission,
        'money_total' => $legacy,
        'migrated'   => (string) setting('commission_wallet_migrated', ''),
        'last_run'   => (int) setting('payg_last_log_time', '0'),
    ]);
}

function paygAdminUsers(): void
{
    requireAdmin();

    $q = trim((string) ($_GET['q'] ?? ''));
    $mode = (string) ($_GET['mode'] ?? '');
    $page = max(1, (int) ($_GET['page'] ?? 1));
    $per = 50;

    $where = ['1 = 1'];
    $args = [];

    if ($q !== '') {
        if (ctype_digit($q)) {
            $where[] = '(u.id = ? OR u.username LIKE ? OR u.email LIKE ?)';
            $args[] = (int) $q;
        } else {
            $where[] = '(u.username LIKE ? OR u.email LIKE ?)';
        }
        $args[] = '%' . $q . '%';
        $args[] = '%' . $q . '%';
    }

    if (in_array($mode, ['plan', 'balance', 'empty'], true)) {
        $where[] = 'w.mode = ?';
        $args[] = $mode;
    }

    $sql = 'FROM payg_wallet w JOIN user u ON u.id = w.userid WHERE ' . implode(' AND ', $where);

    $count = db()->prepare('SELECT COUNT(*) ' . $sql);
    $count->execute($args);

    $rows = db()->prepare(
        'SELECT w.userid, u.username, u.email, w.balance, w.charged, w.bonus, w.adjusted, w.spent,
                w.mode, w.auto, w.updated,
                (SELECT MAX(l.updated) FROM payg_ledger l WHERE l.userid = w.userid AND l.kind = \'usage\') AS last_usage
           ' . $sql . ' ORDER BY w.updated DESC LIMIT ' . $per . ' OFFSET ' . (($page - 1) * $per));
    $rows->execute($args);

    done(['total' => (int) $count->fetchColumn(), 'page' => $page, 'per' => $per, 'rows' => $rows->fetchAll()]);
}

function paygAdminLedger(): void
{
    requireAdmin();

    $userId = (int) ($_GET['userid'] ?? 0);

    $rows = db()->prepare(
        'SELECT l.id, l.kind, l.amount, l.balance_after, l.bytes, l.free_bytes, l.rate, l.note,
                l.created, l.updated, COALESCE(s.name, \'\') AS server
           FROM payg_ledger l LEFT JOIN servers s ON s.id = l.serverid
          WHERE l.userid = ? ORDER BY l.updated DESC, l.id DESC LIMIT 200');
    $rows->execute([$userId]);

    $commission = [];
    try {
        $log = db()->prepare(
            'SELECT kind, amount, balance_after, note, created FROM commission_wallet_log
              WHERE userid = ? ORDER BY id DESC LIMIT 50');
        $log->execute([$userId]);
        $commission = $log->fetchAll();
    } catch (Throwable $error) {
    }

    done([
        'wallet'     => paygWallet($userId),
        'commission_balance' => paygCommissionBalance($userId),
        'rows'       => $rows->fetchAll(),
        'commission' => $commission,
    ]);
}

function paygAdminSave(): void
{
    requireAdmin();
    requireToken();

    $numbers = [
        'payg_min_charge'    => [0, PAYG_MAX_CHARGE],
        'payg_charge_step'   => [1, PAYG_MAX_CHARGE],
        'payg_default_price' => [0, PAYG_MAX_CHARGE],
        'payg_low_balance'   => [0, PAYG_MAX_CHARGE],
        'payg_group'         => [0, 1000000],
    ];

    foreach ($numbers as $name => [$low, $high]) {
        if (!isset($_POST[$name])) {
            continue;
        }

        $value = paygNumber($_POST[$name]);

        if ($value < $low || $value > $high) {
            fail($name . ' is out of range');
        }

        putSetting($name, (string) (floor($value) == $value ? (int) $value : $value));
    }

    // where SubInfo.php fetches the panel's own /link/ from
    if (isset($_POST['sub_origin'])) {
        $origin = rtrim(trim((string) $_POST['sub_origin']), '/');
        if ($origin !== '' && !preg_match('~^https?://[A-Za-z0-9.-]+(:\d+)?$~', $origin)) {
            fail('the panel address must look like https://my.example.com');
        }
        putSetting('sub_origin', $origin);
    }

    if (isset($_POST['sub_origin_ip'])) {
        $ip = trim((string) $_POST['sub_origin_ip']);
        if ($ip !== '' && filter_var($ip, FILTER_VALIDATE_IP) === false) {
            fail('the origin IP is not an IP address');
        }
        putSetting('sub_origin_ip', $ip);
    }

    foreach (['payg_enabled', 'payg_outage_free', 'payg_show_toman', 'commission_wallet_enabled',
              'sub_info_enabled'] as $name) {
        if (isset($_POST[$name])) {
            putSetting($name, (int) $_POST[$name] === 1 ? '1' : '0');
        }
    }

    foreach (['payg_warn_percent' => 100, 'payg_warn_days' => 60] as $name => $max) {
        if (!isset($_POST[$name])) {
            continue;
        }

        $list = [];
        foreach (preg_split('~[\s,]+~', (string) $_POST[$name], -1, PREG_SPLIT_NO_EMPTY) as $part) {
            $n = (int) paygNumber($part);
            if ($n > 0 && $n <= $max && !in_array($n, $list, true)) {
                $list[] = $n;
            }
        }
        sort($list);
        putSetting($name, implode(',', $list));
    }

    // "min:percent" per line, e.g. 10000000:5
    if (isset($_POST['payg_bonus_tiers'])) {
        $tiers = [];
        foreach (preg_split('~[\r\n;]+~', (string) $_POST['payg_bonus_tiers'], -1, PREG_SPLIT_NO_EMPTY) as $line) {
            $parts = preg_split('~\s*[:=]\s*~', trim($line));
            if (count($parts) !== 2) {
                continue;
            }
            $min = paygNumber($parts[0]);
            $percent = paygNumber(str_replace('%', '', $parts[1]));
            if ($min > 0 && $percent > 0 && $percent <= 100) {
                $tiers[] = ['min' => $min, 'percent' => $percent];
            }
        }
        usort($tiers, static function (array $a, array $b): int {
            return $a['min'] <=> $b['min'];
        });
        putSetting('payg_bonus_tiers', (string) json_encode($tiers));
    }

    // the first switch-on starts billing from now, never from old traffic
    if (paygEnabled() && (int) setting('payg_last_log_time', '0') <= 0) {
        putSetting('payg_last_log_time', (string) (time() - 60));
    }

    // what is stored now, read back, so the form shows exactly that
    done(['saved' => true, 'settings' => paygAdminSettings(), 'tiers' => paygTiers()]);
}

function paygAdminRates(): void
{
    requireAdmin();
    requireToken();

    $rates = $_POST['rates'] ?? [];

    if (!is_array($rates)) {
        fail('no rates sent');
    }

    $set = db()->prepare('INSERT INTO payg_rate (serverid, price, updated) VALUES (?, ?, ?)
                          ON DUPLICATE KEY UPDATE price = VALUES(price), updated = VALUES(updated)');
    $clear = db()->prepare('DELETE FROM payg_rate WHERE serverid = ?');
    $saved = 0;

    foreach ($rates as $serverId => $price) {
        $serverId = (int) $serverId;

        if ($serverId <= 0) {
            continue;
        }

        // an empty box means "use the default price"
        if (trim((string) $price) === '') {
            $clear->execute([$serverId]);
            continue;
        }

        $value = paygNumber($price);

        if ($value < 0 || $value > PAYG_MAX_CHARGE) {
            fail('a price is out of range');
        }

        $set->execute([$serverId, $value, time()]);
        $saved++;
    }

    done(['saved' => $saved, 'servers' => paygServers()]);
}

/** A manual credit or debit, on the charge wallet or the commission wallet. */
function paygAdminAdjust(): void
{
    $admin = requireAdmin();
    requireToken();

    $who = trim((string) ($_POST['user'] ?? ''));
    $amount = round(paygNumber($_POST['amount'] ?? 0), 2);
    $reason = trim((string) ($_POST['reason'] ?? ''));
    $target = ($_POST['wallet'] ?? 'payg') === 'commission' ? 'commission' : 'payg';

    if ($amount == 0.0) {
        fail('enter an amount (negative to deduct)');
    }

    if ($reason === '') {
        fail('a reason is required');
    }

    $find = db()->prepare('SELECT id FROM user WHERE id = ? OR username = ? OR email = ? LIMIT 1');
    $find->execute([ctype_digit($who) ? (int) $who : 0, $who, $who]);
    $userId = (int) $find->fetchColumn();

    if ($userId <= 0) {
        fail('user not found');
    }

    $pdo = db();
    $pdo->beginTransaction();

    try {
        $note = mb_substr($reason . ' · admin #' . $admin, 0, 250);
        $ref = 'adjust:' . $admin . ':' . microtime(true);

        if ($target === 'payg') {
            $pdo->prepare('INSERT IGNORE INTO payg_wallet (userid, updated) VALUES (?, ?)')->execute([$userId, time()]);
            $wallet = $pdo->prepare('SELECT balance FROM payg_wallet WHERE userid = ? FOR UPDATE');
            $wallet->execute([$userId]);
            $balance = (float) $wallet->fetchColumn() + $amount;

            $pdo->prepare('UPDATE payg_wallet SET balance = ?, adjusted = adjusted + ?, updated = ? WHERE userid = ?')
                ->execute([$balance, $amount, time(), $userId]);
            $pdo->prepare("INSERT INTO payg_ledger (userid, kind, ref, amount, balance_after, note, created, updated)
                           VALUES (?, 'adjust', ?, ?, ?, ?, ?, ?)")
                ->execute([$userId, $ref, $amount, $balance, $note, time(), time()]);
        } else {
            $pdo->prepare('INSERT IGNORE INTO commission_wallet (userid, updated) VALUES (?, ?)')->execute([$userId, time()]);
            $wallet = $pdo->prepare('SELECT balance FROM commission_wallet WHERE userid = ? FOR UPDATE');
            $wallet->execute([$userId]);
            $balance = (float) $wallet->fetchColumn() + $amount;

            if ($balance < 0) {
                throw new RuntimeException('the commission wallet cannot go below zero');
            }

            $pdo->prepare('UPDATE commission_wallet SET balance = ?, earned = earned + ?, updated = ? WHERE userid = ?')
                ->execute([$balance, max(0.0, $amount), time(), $userId]);
            $pdo->prepare("INSERT INTO commission_wallet_log (userid, kind, ref, amount, balance_after, note, created)
                           VALUES (?, 'adjust', ?, ?, ?, ?, ?)")
                ->execute([$userId, $ref, $amount, $balance, $note, time()]);
        }

        $pdo->commit();
    } catch (Throwable $error) {
        $pdo->rollBack();
        fail($error instanceof RuntimeException ? $error->getMessage() : 'the adjustment was not saved');
    }

    done(['userid' => $userId, 'balance' => $balance, 'wallet' => $target]);
}

/**
 * One-off: every positive user.money balance moves into the commission wallet,
 * so from now on it pays for subscription plans only. Refused a second time.
 */
function paygCommissionMigrate(): void
{
    $admin = requireAdmin();
    requireToken();

    if ((string) setting('commission_wallet_migrated', '') !== '') {
        fail('the wallets were already moved on ' . setting('commission_wallet_migrated', ''));
    }

    $pdo = db();
    $ids = $pdo->query('SELECT id FROM user WHERE money > 0 ORDER BY id')->fetchAll(PDO::FETCH_COLUMN);
    $moved = 0;
    $total = 0.0;

    foreach ($ids as $id) {
        $pdo->beginTransaction();

        try {
            $user = $pdo->prepare('SELECT money FROM user WHERE id = ? FOR UPDATE');
            $user->execute([(int) $id]);
            $money = (float) $user->fetchColumn();

            if ($money <= 0) {
                $pdo->commit();
                continue;
            }

            $pdo->prepare('INSERT IGNORE INTO commission_wallet (userid, updated) VALUES (?, ?)')->execute([(int) $id, time()]);
            $wallet = $pdo->prepare('SELECT balance FROM commission_wallet WHERE userid = ? FOR UPDATE');
            $wallet->execute([(int) $id]);
            $balance = (float) $wallet->fetchColumn() + $money;

            $pdo->prepare('UPDATE user SET money = 0 WHERE id = ?')->execute([(int) $id]);
            $pdo->prepare('UPDATE commission_wallet SET balance = ?, earned = earned + ?, updated = ? WHERE userid = ?')
                ->execute([$balance, $money, time(), (int) $id]);
            $pdo->prepare("INSERT INTO commission_wallet_log (userid, kind, ref, amount, balance_after, note, created)
                           VALUES (?, 'migrate', ?, ?, ?, ?, ?)")
                ->execute([(int) $id, 'migrate:' . $id, $money, $balance, 'user.money moved · admin #' . $admin, time()]);

            $pdo->commit();
            $moved++;
            $total += $money;
        } catch (Throwable $error) {
            $pdo->rollBack();
        }
    }

    putSetting('commission_wallet_migrated', date('Y-m-d H:i:s'));

    done(['users' => $moved, 'total' => $total]);
}

// ---------------------------------------------------------------- dispatch

$paygAction = (string) ($_GET['do'] ?? '');

$paygNeedsPost = ['payg.mint', 'payg.auto', 'commission.apply', 'payg.save', 'payg.rates',
    'payg.adjust', 'commission.migrate'];

if (in_array($paygAction, $paygNeedsPost, true) && $_SERVER['REQUEST_METHOD'] !== 'POST') {
    fail('this action needs POST', 405);
}

switch ($paygAction) {
    case 'payg.me':
        paygUserMe();
    case 'payg.mint':
        paygUserMint();
    case 'payg.auto':
        paygUserAuto();
    case 'commission.me':
        paygCommissionMe();
    case 'commission.apply':
        paygCommissionApply();
    case 'payg.admin':
        paygAdminBootstrap();
    case 'payg.users':
        paygAdminUsers();
    case 'payg.ledger':
        paygAdminLedger();
    case 'payg.save':
        paygAdminSave();
    case 'payg.rates':
        paygAdminRates();
    case 'payg.adjust':
        paygAdminAdjust();
    case 'commission.migrate':
        paygCommissionMigrate();
}

fail('unknown wallet action');
