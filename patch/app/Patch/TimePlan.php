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
        'applies_to'    => array_map('intval', $meta['applies_to'] ?? []),
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

    $statement = db()->prepare('SELECT id, packageid, expire_in, plan FROM user WHERE id = ? LIMIT 1');
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

function timeplanAllowedForUser(array $meta, array $user): bool
{
    $applies = timeplanAppliesTo($meta['applies_to'] ?? []);

    return $applies === [] || in_array((int) $user['packageid'], $applies, true);
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

    done([
        'token'     => $_SESSION['patch_csrf'],
        'plans'     => $plans,
        'packages'  => $packages,
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
        if (timeplanRow($id) === null) {
            fail('that time plan no longer exists');
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
        unset($view['applies_to'], $view['status'], $view['sort']);

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

    // a fixed plan is already buyable as it stands
    if (($meta['mode'] ?? '') !== 'perday') {
        done(['packageid' => $parentId, 'days' => timeplanInt($meta['days'] ?? 0)]);
    }

    $days = timeplanInt($_POST['days'] ?? 0);
    $min = timeplanInt($meta['min_days'] ?? 1, 1);
    $max = timeplanInt($meta['max_days'] ?? 30, 30);

    if ($days < $min || $days > $max) {
        fail(sprintf('choose between %d and %d days', $min, $max));
    }

    $childMeta = [
        'mode'       => 'minted',
        'days'       => $days,
        'parent'     => $parentId,
        'created'    => time(),
        'applies_to' => timeplanAppliesTo($meta['applies_to'] ?? []),
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

$timeplanNeedsPost = ['save', 'delete', 'settings', 'options', 'mint'];

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
    case 'settings':
        timeplanAdminSettings();
    case 'options':
        timeplanUserOptions();
    case 'mint':
        timeplanUserMint();
}

fail('unknown time plan action');
