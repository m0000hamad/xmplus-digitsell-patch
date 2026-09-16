<?php
/**
 * Time plans - selling days instead of gigabytes.
 *
 * This file is included by public/xmplus-patch.php, in its global scope, and
 * borrows that file's helpers: db(), fail(), done(), startPanelSession() and
 * requireAdmin(). It never returns - every path ends in done() or fail().
 *
 * A time plan is a real topup package (type 1, bandwidth 0) whose `order_note`
 * carries a marker, so the panel's own encoded checkout sells it and the days
 * are granted afterwards by bin/timeplans.php. See app/Http/Models/Package.php
 * for the marker's shape.
 */

declare(strict_types=1);

const TIMEPLAN_MARKER = '"timeplan"';
const TIMEPLAN_MAX_DAYS = 3650;

// ------------------------------------------------------------------ helpers

function timeplanMeta($note): ?array
{
    if (!is_string($note) || strpos($note, TIMEPLAN_MARKER) === false) {
        return null;
    }

    $data = json_decode($note, true);

    return isset($data['timeplan']) && is_array($data['timeplan']) ? $data['timeplan'] : null;
}

function timeplanNote(array $meta): string
{
    return (string) json_encode(['timeplan' => ['v' => 1] + $meta], JSON_UNESCAPED_UNICODE);
}

/** The panel writes every billing cycle into price_option; only topup is used here. */
function timeplanPriceOption(string $price): string
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

function timeplanPriceOf(array $row): float
{
    $options = json_decode((string) $row['price_option'], true);

    return (float) ($options['topup']['price'] ?? 0);
}

function timeplanInt($value, int $fallback = 0): int
{
    return is_numeric($value) ? (int) $value : $fallback;
}

function timeplanMoney($value): string
{
    $clean = str_replace([',', ' ', '،'], '', (string) $value);

    return is_numeric($clean) ? number_format((float) $clean, 2, '.', '') : '0.00';
}

/** Package ids this plan is limited to. An empty list means every plan. */
function timeplanAppliesTo($raw): array
{
    if (is_string($raw)) {
        $raw = $raw === '' ? [] : explode(',', $raw);
    }

    if (!is_array($raw)) {
        return [];
    }

    $ids = [];
    foreach ($raw as $id) {
        $id = timeplanInt($id);
        if ($id > 0 && !in_array($id, $ids, true)) {
            $ids[] = $id;
        }
    }

    return $ids;
}

function timeplanDayWord(): string
{
    $locale = $_SESSION['locale'] ?? 'fa_IR';

    if ($locale === 'zh_CN') {
        return '天';
    }

    return $locale === 'en_US' ? 'days' : 'روز';
}

function timeplanSetting(string $name, string $fallback): string
{
    $value = setting($name, null);

    return $value === null || $value === '' ? $fallback : (string) $value;
}

function timeplanRow(int $id): ?array
{
    $statement = db()->prepare('SELECT * FROM package WHERE id = ? LIMIT 1');
    $statement->execute([$id]);
    $row = $statement->fetch();

    if ($row === false || timeplanMeta($row['order_note']) === null) {
        return null;
    }

    return $row;
}

/** Every time plan, newest definition last. Minted rows are left out. */
function timeplanAll(bool $enabledOnly = false): array
{
    $sql = 'SELECT * FROM package WHERE type = 1 AND order_note LIKE ?'
        . ($enabledOnly ? ' AND status = 1' : '')
        . ' ORDER BY sort ASC, id ASC';

    $statement = db()->prepare($sql);
    $statement->execute(['%' . TIMEPLAN_MARKER . '%']);

    $plans = [];

    foreach ($statement->fetchAll() as $row) {
        $meta = timeplanMeta($row['order_note']);

        if ($meta === null || ($meta['mode'] ?? '') === 'minted') {
            continue;
        }

        $plans[] = ['row' => $row, 'meta' => $meta];
    }

    return $plans;
}

function timeplanPresent(array $row, array $meta): array
{
    return [
        'id'            => (int) $row['id'],
        'name'          => (string) $row['name'],
        'status'        => (int) $row['status'],
        'sort'          => (int) $row['sort'],
        'mode'          => (string) ($meta['mode'] ?? 'fixed'),
        'days'          => timeplanInt($meta['days'] ?? 0),
        'price'         => timeplanPriceOf($row),
        'price_per_day' => (float) ($meta['price_per_day'] ?? 0),
        'min_days'      => timeplanInt($meta['min_days'] ?? 1, 1),
        'max_days'      => timeplanInt($meta['max_days'] ?? 30, 30),
        'max_buys'      => timeplanInt($meta['max_buys'] ?? 0),
        'max_total'     => timeplanInt($meta['max_total'] ?? 0),
        'applies_to'    => array_map('intval', $meta['applies_to'] ?? []),
        'groups'        => array_map('intval', $meta['groups'] ?? []),
    ];
}

/**
 * How much of a time plan a user has already taken on the subscription they
 * are on now.
 *
 * The window starts at their last paid data order, so renewing or switching
 * plan gives them a fresh allowance. Only granted purchases count - an order
 * left unpaid never reaches timeplan_log.
 */
function timeplanUsage(int $userId, int $planId): array
{
    $since = db()->prepare(
        'SELECT pay_date FROM orders
          WHERE userid = ? AND status = 1 AND packagetype = 2 AND pay_date IS NOT NULL
          ORDER BY pay_date DESC LIMIT 1');
    $since->execute([$userId]);
    $row = $since->fetch();
    $from = $row === false ? 0 : (int) $row['pay_date'];

    // a minted row is bought in its parent's name, so both count together
    $statement = db()->prepare(
        'SELECT COUNT(*) AS buys, COALESCE(SUM(l.days), 0) AS days
           FROM timeplan_log l
           JOIN package p ON p.id = l.packageid
          WHERE l.userid = ? AND l.granted_at >= ?
            AND (l.packageid = ? OR p.order_note LIKE ?)');
    $statement->execute([$userId, $from, $planId, '%"parent":' . $planId . '%']);
    $used = $statement->fetch();

    return [
        'buys' => (int) ($used['buys'] ?? 0),
        'days' => (int) ($used['days'] ?? 0),
    ];
}

/**
 * What is still allowed for this user on this plan: how many more purchases,
 * and how many more days. A limit of 0 means no limit, and is reported as null.
 */
function timeplanAllowance(array $meta, int $userId, int $planId): array
{
    $maxBuys = timeplanInt($meta['max_buys'] ?? 0);
    $maxTotal = timeplanInt($meta['max_total'] ?? 0);

    if ($maxBuys <= 0 && $maxTotal <= 0) {
        return ['buys_left' => null, 'days_left' => null];
    }

    $used = timeplanUsage($userId, $planId);

    return [
        'buys_left' => $maxBuys > 0 ? max(0, $maxBuys - $used['buys']) : null,
        'days_left' => $maxTotal > 0 ? max(0, $maxTotal - $used['days']) : null,
    ];
}

// --------------------------------------------------------------------- auth

/**
 * The buying half of this endpoint answers ordinary users, so it cannot go
 * through requireAdmin(). Same session, same expiry check, no role demand.
 */
function timeplanRequireUser(): array
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

function timeplanUserToken(): string
{
    if (empty($_SESSION['timeplan_csrf'])) {
        $_SESSION['timeplan_csrf'] = bin2hex(random_bytes(24));
    }

    return (string) $_SESSION['timeplan_csrf'];
}

function timeplanRequireUserToken(): void
{
    $sent = $_POST['token'] ?? '';
    $held = $_SESSION['timeplan_csrf'] ?? '';

    if ($held === '' || !is_string($sent) || !hash_equals($held, $sent)) {
        fail('bad or missing token', 403);
    }
}

/**
 * Mirrors User::timePlanVisible(): close to the end of the subscription, or
 * just past it. Checked here too, because the browser is not to be trusted.
 */
function timeplanUserEligible(array $user): bool
{
    if (empty($user['expire_in'])) {
        return false;
    }

    $expire = strtotime((string) $user['expire_in']);

    if ($user['plan'] === 'onetime' || $expire > strtotime('+10 years')) {
        return false;
    }

    $window = (int) timeplanSetting('timeplan_visible_days', '7');
    $grace = (int) timeplanSetting('timeplan_grace_hours', '24');

    if ($expire > time()) {
        return (int) floor(($expire - time()) / 86400) <= ($window > 0 ? $window : 7);
    }

    return $grace > 0 && time() - $expire <= $grace * 3600;
}

/*
 * Two independent filters, each one open when its list is empty: the plan the
 * user is on, and the server group they are in. Both have to pass.
 */
function timeplanAllowedForUser(array $meta, array $user): bool
{
    $applies = timeplanAppliesTo($meta['applies_to'] ?? []);

    if ($applies !== [] && !in_array((int) $user['packageid'], $applies, true)) {
        return false;
    }

    $groups = timeplanAppliesTo($meta['groups'] ?? []);

    return $groups === [] || in_array((int) $user['server_group'], $groups, true);
}

// ------------------------------------------------------------------- admin

function timeplanAdminBootstrap(): void
{
    requireAdmin();

    if (empty($_SESSION['patch_csrf'])) {
        $_SESSION['patch_csrf'] = bin2hex(random_bytes(24));
    }

    $plans = [];
    foreach (timeplanAll() as $plan) {
        $plans[] = timeplanPresent($plan['row'], $plan['meta']);
    }

    /*
     * Only enabled plans are worth offering. A plan already named by the time
     * plan being edited is kept in the list even if it has since been turned
     * off, so opening the page and saving does not silently drop it.
     */
    $keep = timeplanAppliesTo($_GET['keep'] ?? []);
    $sql = 'SELECT id, name, status FROM package WHERE type = 2 AND status = 1';

    if ($keep !== []) {
        $sql .= ' OR (type = 2 AND id IN (' . implode(',', $keep) . '))';
    }

    $packages = db()->query($sql . ' ORDER BY sort ASC, id ASC')->fetchAll();
    $groups = db()->query('SELECT id, name FROM `group` ORDER BY id ASC')->fetchAll();

    // the plans list is drawn by an encoded endpoint that lists every package,
    // so the page hides these rows itself
    $generated = db()->query(
        'SELECT id FROM package WHERE type = 1 AND order_note LIKE \'%"mode":"minted"%\'')
        ->fetchAll(PDO::FETCH_COLUMN);

    done([
        'token'     => $_SESSION['patch_csrf'],
        'plans'     => $plans,
        'packages'  => $packages,
        'generated' => array_map('intval', $generated),
        'groups'    => $groups,
        'topup_scope' => timeplanTopupScopes(),
        'topup_groups' => timeplanTopupGroups(),
        'settings'  => [
            'visible_days' => (int) timeplanSetting('timeplan_visible_days', '7'),
            'grace_hours'  => (int) timeplanSetting('timeplan_grace_hours', '24'),
        ],
    ]);
}

function timeplanAdminSave(): void
{
    requireAdmin();
    requireToken();

    $id = timeplanInt($_POST['id'] ?? 0);
    $name = trim((string) ($_POST['name'] ?? ''));
    $mode = ($_POST['mode'] ?? 'fixed') === 'perday' ? 'perday' : 'fixed';

    if ($name === '') {
        fail('the plan needs a name');
    }

    $meta = [
        'mode'       => $mode,
        'applies_to' => timeplanAppliesTo($_POST['applies_to'] ?? []),
        'groups'     => timeplanAppliesTo($_POST['groups'] ?? []),
        'max_buys'   => max(0, timeplanInt($_POST['max_buys'] ?? 0)),
        'max_total'  => max(0, timeplanInt($_POST['max_total'] ?? 0)),
    ];

    if ($mode === 'fixed') {
        $days = timeplanInt($_POST['days'] ?? 0);

        if ($days < 1 || $days > TIMEPLAN_MAX_DAYS) {
            fail('the number of days must be between 1 and ' . TIMEPLAN_MAX_DAYS);
        }

        $price = timeplanMoney($_POST['price'] ?? 0);

        if ((float) $price <= 0) {
            fail('the price must be greater than zero');
        }

        $meta['days'] = $days;
    } else {
        $perDay = timeplanMoney($_POST['price_per_day'] ?? 0);
        $min = timeplanInt($_POST['min_days'] ?? 1, 1);
        $max = timeplanInt($_POST['max_days'] ?? 30, 30);

        if ((float) $perDay <= 0) {
            fail('the daily price must be greater than zero');
        }

        if ($min < 1 || $max < $min || $max > TIMEPLAN_MAX_DAYS) {
            fail('the day range is not valid');
        }

        $meta['price_per_day'] = (float) $perDay;
        $meta['min_days'] = $min;
        $meta['max_days'] = $max;

        // the parent row is never bought directly; minted children carry the price
        $price = '0.00';
    }

    $status = timeplanInt($_POST['status'] ?? 1) === 1 ? 1 : 0;
    $sort = timeplanInt($_POST['sort'] ?? 0);

    if ($id > 0) {
        $existing = timeplanRow($id);

        if ($existing === null) {
            fail('that time plan no longer exists');
        }

        // a minted row belongs to a per-day plan and is priced by the day count
        // it was made for; editing it as a plan would break the order it backs
        $existingMeta = timeplanMeta($existing['order_note']);

        if (($existingMeta['mode'] ?? '') === 'minted') {
            fail('this row was generated for a purchase and cannot be edited as a plan');
        }

        $statement = db()->prepare(
            'UPDATE package SET name = ?, status = ?, sort = ?, price_option = ?, order_note = ?,
                    type = 1, bandwidth = ?, upgrade = 0, renew_type = 0, reset_days = 0
               WHERE id = ?');

        $statement->execute([$name, $status, $sort, timeplanPriceOption($price), timeplanNote($meta),
            timeplanSetting('timeplan_bandwidth', '0'), $id]);

        done(['id' => $id, 'created' => false]);
    }

    $statement = db()->prepare(
        'INSERT INTO package (type, name, status, price_option, upgrade, bandwidth, iplimit,
                              speedlimit, server_group, order_note, sort, renew_type, reset_days,
                              stocks, stockcount, order_type)
              VALUES (1, ?, ?, ?, 0, ?, 0, 0, 1, ?, ?, 0, 0, 0, 0, 1)');

    $statement->execute([$name, $status, timeplanPriceOption($price),
        timeplanSetting('timeplan_bandwidth', '0'), timeplanNote($meta), $sort]);

    done(['id' => (int) db()->lastInsertId(), 'created' => true]);
}

function timeplanAdminDelete(): void
{
    requireAdmin();
    requireToken();

    $id = timeplanInt($_POST['id'] ?? 0);

    if (timeplanRow($id) === null) {
        fail('that time plan no longer exists');
    }

    // a plan someone has already bought keeps its row, or old invoices break
    $used = db()->prepare('SELECT 1 FROM orders WHERE packageid = ? LIMIT 1');
    $used->execute([$id]);

    $minted = db()->prepare('SELECT 1 FROM package WHERE order_note LIKE ? LIMIT 1');
    $minted->execute(['%"parent":' . $id . '%']);

    if ($used->fetch() !== false || $minted->fetch() !== false) {
        db()->prepare('UPDATE package SET status = 0 WHERE id = ?')->execute([$id]);
        db()->prepare('UPDATE package SET status = 0 WHERE order_note LIKE ?')
            ->execute(['%"parent":' . $id . '%']);

        done(['disabled' => true]);
    }

    db()->prepare('DELETE FROM package WHERE id = ?')->execute([$id]);

    done(['disabled' => false]);
}

const TIMEPLAN_TOPUP_SCOPE = 'timeplan_topup_scope';
const TIMEPLAN_TOPUP_GROUPS = 'timeplan_topup_groups';

function timeplanTopupScopes(): array
{
    $decoded = json_decode((string) setting(TIMEPLAN_TOPUP_SCOPE, '{}'), true);

    return is_array($decoded) ? $decoded : [];
}

function timeplanTopupGroups(): array
{
    $decoded = json_decode((string) setting(TIMEPLAN_TOPUP_GROUPS, '{}'), true);

    return is_array($decoded) ? $decoded : [];
}

/**
 * Limits a traffic top-up to certain subscription plans.
 *
 * A top-up is saved through the encoded /admin/plan/save, which rewrites
 * order_note every time, so this cannot ride along in the package row the way
 * a time plan's settings do. One settings row holds the whole map instead.
 *
 * On a new package the id is not known yet - the encoded save does not report
 * it - so the newest type 1 row with that name is taken.
 */
function timeplanAdminTopupScope(): void
{
    requireAdmin();
    requireToken();

    $id = timeplanInt($_POST['id'] ?? 0);

    if ($id <= 0) {
        $name = trim((string) ($_POST['name'] ?? ''));

        if ($name === '') {
            fail('the package is not identified');
        }

        $statement = db()->prepare(
            'SELECT id FROM package WHERE type = 1 AND name = ? ORDER BY id DESC LIMIT 1');
        $statement->execute([$name]);
        $row = $statement->fetch();

        if ($row === false) {
            fail('that package was not found');
        }

        $id = (int) $row['id'];
    }

    $statement = db()->prepare('SELECT type, order_note FROM package WHERE id = ? LIMIT 1');
    $statement->execute([$id]);
    $package = $statement->fetch();

    if ($package === false || (int) $package['type'] !== 1) {
        fail('that package is not a traffic top-up');
    }

    // a time plan carries its own applies_to and must not be touched here
    if (timeplanMeta($package['order_note']) !== null) {
        fail('a time plan keeps its own plan list');
    }

    $scopes = timeplanTopupScopes();
    $applies = timeplanAppliesTo($_POST['applies_to'] ?? []);

    if ($applies === []) {
        unset($scopes[(string) $id]);
    } else {
        $scopes[(string) $id] = $applies;
    }

    putSetting(TIMEPLAN_TOPUP_SCOPE, (string) json_encode($scopes));

    $groupMap = timeplanTopupGroups();
    $groups = timeplanAppliesTo($_POST['groups'] ?? []);

    if ($groups === []) {
        unset($groupMap[(string) $id]);
    } else {
        $groupMap[(string) $id] = $groups;
    }

    putSetting(TIMEPLAN_TOPUP_GROUPS, (string) json_encode($groupMap));

    done(['id' => $id, 'applies_to' => $applies, 'groups' => $groups]);
}

function timeplanAdminSettings(): void
{
    requireAdmin();
    requireToken();

    $days = timeplanInt($_POST['visible_days'] ?? 7, 7);
    $grace = timeplanInt($_POST['grace_hours'] ?? 24, 24);

    if ($days < 1 || $days > 365) {
        fail('the visibility window must be between 1 and 365 days');
    }

    if ($grace < 0 || $grace > 720) {
        fail('the grace window must be between 0 and 720 hours');
    }

    putSetting('timeplan_visible_days', (string) $days);
    putSetting('timeplan_grace_hours', (string) $grace);

    done(['visible_days' => $days, 'grace_hours' => $grace]);
}

// -------------------------------------------------------------------- user

function timeplanUserOptions(): void
{
    $user = timeplanRequireUser();

    if (!timeplanUserEligible($user)) {
        fail('this account cannot buy extra time right now');
    }

    $plans = [];

    foreach (timeplanAll(true) as $plan) {
        if (!timeplanAllowedForUser($plan['meta'], $user)) {
            continue;
        }

        $view = timeplanPresent($plan['row'], $plan['meta']);
        $left = timeplanAllowance($plan['meta'], (int) $user['id'], $view['id']);

        // nothing left on this subscription - do not offer it at all
        if ($left['buys_left'] === 0 || $left['days_left'] === 0) {
            continue;
        }

        // a per-day plan may only offer part of its range now
        if ($view['mode'] === 'perday' && $left['days_left'] !== null) {
            $view['max_days'] = min($view['max_days'], $left['days_left']);

            if ($view['max_days'] < $view['min_days']) {
                continue;
            }
        }

        if ($view['mode'] === 'fixed' && $left['days_left'] !== null
            && $view['days'] > $left['days_left']) {
            continue;
        }

        $view += $left;
        unset($view['applies_to'], $view['status'], $view['sort'],
            $view['max_buys'], $view['max_total']);

        $plans[] = $view;
    }

    done(['token' => timeplanUserToken(), 'plans' => $plans]);
}

/**
 * Turn "N days of this per-day plan" into something the panel's checkout can
 * sell: a package row priced at N x the daily rate. The same N is reused on
 * later purchases, so the number of these rows stays bounded by max_days.
 */
function timeplanUserMint(): void
{
    $user = timeplanRequireUser();
    timeplanRequireUserToken();

    if (!timeplanUserEligible($user)) {
        fail('this account cannot buy extra time right now');
    }

    $parentId = timeplanInt($_POST['id'] ?? 0);
    $parent = timeplanRow($parentId);

    if ($parent === null || (int) $parent['status'] !== 1) {
        fail('that time plan is not available');
    }

    $meta = timeplanMeta($parent['order_note']);

    if (!timeplanAllowedForUser($meta, $user)) {
        fail('that time plan does not apply to your subscription');
    }

    $left = timeplanAllowance($meta, (int) $user['id'], $parentId);

    if ($left['buys_left'] === 0) {
        fail('you have used this time plan as many times as allowed on this subscription');
    }

    // a fixed plan is already buyable as it stands
    if (($meta['mode'] ?? '') !== 'perday') {
        $fixedDays = timeplanInt($meta['days'] ?? 0);

        if ($left['days_left'] !== null && $fixedDays > $left['days_left']) {
            fail(sprintf('only %d more day(s) can be added on this subscription', $left['days_left']));
        }

        done(['packageid' => $parentId, 'days' => $fixedDays]);
    }

    $days = timeplanInt($_POST['days'] ?? 0);
    $min = timeplanInt($meta['min_days'] ?? 1, 1);
    $max = timeplanInt($meta['max_days'] ?? 30, 30);

    if ($left['days_left'] !== null) {
        $max = min($max, $left['days_left']);
    }

    if ($days < $min || $days > $max) {
        fail(sprintf('choose between %d and %d days', $min, $max));
    }

    $childMeta = [
        'mode'       => 'minted',
        'days'       => $days,
        'parent'     => $parentId,
        'created'    => time(),
        'applies_to' => timeplanAppliesTo($meta['applies_to'] ?? []),
        'groups'     => timeplanAppliesTo($meta['groups'] ?? []),
    ];

    $price = timeplanMoney((float) ($meta['price_per_day'] ?? 0) * $days);
    $name = sprintf('%s - %d %s', $parent['name'], $days, timeplanDayWord());

    $existing = db()->prepare(
        'SELECT id FROM package WHERE type = 1 AND order_note LIKE ? AND order_note LIKE ? LIMIT 1');
    $existing->execute(['%"parent":' . $parentId . '%', '%"days":' . $days . ',%']);
    $row = $existing->fetch();

    if ($row !== false) {
        db()->prepare('UPDATE package SET status = 1, name = ?, price_option = ? WHERE id = ?')
            ->execute([$name, timeplanPriceOption($price), (int) $row['id']]);

        done(['packageid' => (int) $row['id'], 'days' => $days, 'price' => (float) $price]);
    }

    $statement = db()->prepare(
        'INSERT INTO package (type, name, status, price_option, upgrade, bandwidth, iplimit,
                              speedlimit, server_group, order_note, sort, renew_type, reset_days,
                              stocks, stockcount, order_type)
              VALUES (1, ?, 1, ?, 0, ?, 0, 0, 1, ?, 0, 0, 0, 0, 0, 1)');

    $statement->execute([$name, timeplanPriceOption($price),
        timeplanSetting('timeplan_bandwidth', '0'), timeplanNote($childMeta)]);

    done(['packageid' => (int) db()->lastInsertId(), 'days' => $days, 'price' => (float) $price]);
}

// ---------------------------------------------------------------- dispatch

$timeplanAction = substr((string) ($_GET['do'] ?? ''), strlen('timeplan.'));

$timeplanNeedsPost = ['save', 'delete', 'settings', 'topupscope', 'options', 'mint'];

if (in_array($timeplanAction, $timeplanNeedsPost, true) && $_SERVER['REQUEST_METHOD'] !== 'POST') {
    fail('this action needs POST', 405);
}

switch ($timeplanAction) {
    case 'admin':
        timeplanAdminBootstrap();
    case 'save':
        timeplanAdminSave();
    case 'delete':
        timeplanAdminDelete();
    case 'topupscope':
        timeplanAdminTopupScope();
    case 'settings':
        timeplanAdminSettings();
    case 'options':
        timeplanUserOptions();
    case 'mint':
        timeplanUserMint();
}

fail('unknown time plan action');
