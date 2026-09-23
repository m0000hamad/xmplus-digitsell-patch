<?php
/**
 * Data for the admin dashboard.
 *
 * Included by public/xmplus-patch.php, in its global scope, after
 * requireAdmin() - so only an admin ever reaches it. Borrows db(), fail() and
 * done(). Read-only: it never writes anything, which is why it takes GET and
 * needs no CSRF token.
 *
 * Everything the page draws comes from one call, so the page makes a single
 * request. Paid orders of the last year are read once and bucketed in PHP;
 * at this panel's size that is a few thousand small rows and cheaper to
 * reason about than a dozen GROUP BY queries.
 *
 * Paid means orders.status = 1. The `state` column is 0 on practically every
 * row, so nothing here filters on it.
 */

declare(strict_types=1);

const DASHBOARD_GB = 1073741824;

/** Seconds of silence after which a node, or the cron runner, counts as down. */
const DASHBOARD_NODE_STALE = 300;
const DASHBOARD_CRON_STALE = 300;

function dashboardTimezone(): void
{
    db(); // loads config/config.php, which fills $_ENV['timeZone']
    $zone = (string) ($_ENV['timeZone'] ?? '');
    if ($zone !== '' && in_array($zone, timezone_identifiers_list(), true)) {
        date_default_timezone_set($zone);
    }

    // FROM_UNIXTIME and NOW() follow the session zone; make it the panel's
    db()->exec("SET time_zone = '" . date('P') . "'");
}

/** Package ids that are time plans (a top-up with the timeplan marker). */
function dashboardTimePlanIds(): array
{
    $ids = [];
    $statement = db()->query("SELECT id FROM package WHERE order_note LIKE '%\"timeplan\"%'");
    foreach ($statement as $row) {
        $ids[(int) $row['id']] = true;
    }
    return $ids;
}

/** id => name for every package, including disabled and generated ones. */
function dashboardPackageNames(): array
{
    $names = [];
    foreach (db()->query('SELECT id, name FROM package') as $row) {
        $names[(int) $row['id']] = (string) $row['name'];
    }
    return $names;
}

/** userid => time of that user's first paid subscription. */
function dashboardFirstPurchases(): array
{
    $first = [];
    $statement = db()->query(
        'SELECT userid, MIN(COALESCE(pay_date, create_date)) AS t
           FROM orders WHERE status = 1 AND packagetype = 2 GROUP BY userid');
    foreach ($statement as $row) {
        $first[(int) $row['userid']] = (int) $row['t'];
    }
    return $first;
}

/**
 * What kind of sale an order was. Time plans are top-ups underneath, so the
 * marker decides. A subscription counts as a renewal when the same user had
 * paid for one before: the panel's own `renew` flag is only set by its renew
 * button, and most customers renew by simply buying the plan again.
 */
function dashboardKind(array $order, array $timeIds, array $first): string
{
    if ((int) $order['packagetype'] === 1) {
        return isset($timeIds[(int) $order['packageid']]) ? 'time' : 'topup';
    }
    if ((int) $order['upgrade'] === 1) {
        return 'upgrade';
    }
    if ((int) $order['renew'] === 1) {
        return 'renew';
    }
    $since = $first[(int) $order['userid']] ?? null;
    return $since !== null && (int) $order['t'] > $since ? 'renew' : 'new';
}

/** [year, month] in the Solar Hijri calendar, for the month buckets. */
function dashboardJalali(int $t): array
{
    $gy = (int) date('Y', $t);
    $gm = (int) date('n', $t);
    $gd = (int) date('j', $t);

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

    return [$jy, $jm];
}

/** Month key of a timestamp in the calendar the page asked for. */
function dashboardMonth(int $t, bool $jalali): string
{
    if (!$jalali) {
        return date('Y-m', $t);
    }
    [$jy, $jm] = dashboardJalali($t);
    return sprintf('%04d-%02d', $jy, $jm);
}

/** An empty series keyed by Y-m-d, oldest first. */
function dashboardDays(int $count, $zero): array
{
    $days = [];
    for ($i = $count - 1; $i >= 0; $i--) {
        $days[date('Y-m-d', strtotime("-$i days"))] = $zero;
    }
    return $days;
}

function dashboardSales(array $timeIds, array $names, bool $jalali): array
{
    $first = dashboardFirstPurchases();
    $today = strtotime('today');
    $yesterday = strtotime('yesterday');
    $start30 = strtotime('-29 days', $today);
    $start60 = strtotime('-59 days', $today);
    $start90 = strtotime('-89 days', $today);

    // twelve month buckets, oldest first, in whichever calendar; stepping
    // back 25 days at a time cannot skip a month of either calendar
    $monthly = [];
    for ($t = $today, $i = 0; count($monthly) < 12 && $i < 40; $i++, $t -= 25 * 86400) {
        $monthly[dashboardMonth($t, $jalali)] = ['revenue' => 0.0, 'orders' => 0];
    }
    $monthly = array_reverse(array_slice($monthly, 0, 12, true), true);
    $from = min($start90, $today - 372 * 86400);

    $daily = dashboardDays(90, ['sub' => 0.0, 'topup' => 0.0, 'time' => 0.0, 'orders' => 0]);

    // weekday (0 = Saturday, the first day of the Iranian week) x hour
    $heat = array_fill(0, 7, array_fill(0, 24, 0));

    $sum = ['today' => 0.0, 'yesterday' => 0.0, 'r30' => 0.0, 'p30' => 0.0];
    $count = ['today' => 0, 'yesterday' => 0, 'r30' => 0, 'p30' => 0];
    $mix = ['new' => 0, 'renew' => 0, 'upgrade' => 0, 'topup' => 0, 'time' => 0];
    $mixRevenue = $mix;
    $plans = [];
    $gateways = [];
    $buyers30 = [];
    $coupons = ['orders' => 0, 'discount' => 0.0];

    $statement = db()->prepare(
        'SELECT COALESCE(pay_date, create_date) AS t, total_amount, discount, coupon,
                packagetype, packageid, renew, upgrade, gateway_name, userid
           FROM orders
          WHERE status = 1 AND COALESCE(pay_date, create_date) >= ?');
    $statement->execute([$from]);

    foreach ($statement as $order) {
        $t = (int) $order['t'];
        $amount = (float) $order['total_amount'];
        $kind = dashboardKind($order, $timeIds, $first);

        $month = dashboardMonth($t, $jalali);
        if (isset($monthly[$month])) {
            $monthly[$month]['revenue'] += $amount;
            $monthly[$month]['orders']++;
        }

        if ($t < $start90) {
            continue;
        }

        $day = date('Y-m-d', $t);
        if (isset($daily[$day])) {
            $bucket = $kind === 'time' ? 'time' : ($kind === 'topup' ? 'topup' : 'sub');
            $daily[$day][$bucket] += $amount;
            $daily[$day]['orders']++;
        }

        $heat[((int) date('w', $t) + 1) % 7][(int) date('G', $t)]++;

        if ($t >= $today) {
            $sum['today'] += $amount;
            $count['today']++;
        } elseif ($t >= $yesterday) {
            $sum['yesterday'] += $amount;
            $count['yesterday']++;
        }

        if ($t >= $start30) {
            $sum['r30'] += $amount;
            $count['r30']++;
            $mix[$kind]++;
            $mixRevenue[$kind] += $amount;
            $buyers30[(int) $order['userid']] = true;

            $pid = (int) $order['packageid'];
            if (!isset($plans[$pid])) {
                $plans[$pid] = ['name' => $names[$pid] ?? ('#' . $pid), 'kind' => $kind, 'revenue' => 0.0, 'orders' => 0];
            }
            $plans[$pid]['revenue'] += $amount;
            $plans[$pid]['orders']++;

            $gateway = trim((string) $order['gateway_name']);
            if ($gateway === '') {
                $gateway = $amount > 0 ? 'balance' : 'free';
            }
            if (!isset($gateways[$gateway])) {
                $gateways[$gateway] = ['name' => $gateway, 'revenue' => 0.0, 'orders' => 0];
            }
            $gateways[$gateway]['revenue'] += $amount;
            $gateways[$gateway]['orders']++;

            if (trim((string) $order['coupon']) !== '') {
                $coupons['orders']++;
                $coupons['discount'] += (float) $order['discount'];
            }
        } elseif ($t >= $start60) {
            $sum['p30'] += $amount;
            $count['p30']++;
        }
    }

    // generated time-plan rows each carry their own name ("12 days"); fold
    // them into one line so the ranking shows plans, not day counts
    $folded = [];
    foreach ($plans as $pid => $plan) {
        $key = $plan['kind'] === 'time' ? 'time' : (string) $pid;
        if (!isset($folded[$key])) {
            $folded[$key] = $plan;
            continue;
        }
        $folded[$key]['revenue'] += $plan['revenue'];
        $folded[$key]['orders'] += $plan['orders'];
    }
    usort($folded, function ($a, $b) { return $b['revenue'] <=> $a['revenue']; });
    usort($gateways, function ($a, $b) { return $b['revenue'] <=> $a['revenue']; });

    $created = db()->prepare('SELECT COUNT(*) FROM orders WHERE create_date >= ?');
    $created->execute([$start30]);
    $created30 = (int) $created->fetchColumn();

    $series = [];
    foreach ($daily as $day => $row) {
        $series[] = ['d' => $day] + $row;
    }
    $months = [];
    foreach ($monthly as $month => $row) {
        $months[] = ['m' => $month] + $row;
    }

    return [
        'kpi' => [
            'revenue_today' => $sum['today'],
            'revenue_yesterday' => $sum['yesterday'],
            'revenue_30' => $sum['r30'],
            'revenue_prev30' => $sum['p30'],
            'orders_today' => $count['today'],
            'orders_yesterday' => $count['yesterday'],
            'orders_30' => $count['r30'],
            'orders_prev30' => $count['p30'],
            'aov_30' => $count['r30'] ? $sum['r30'] / $count['r30'] : 0,
            'aov_prev30' => $count['p30'] ? $sum['p30'] / $count['p30'] : 0,
            'buyers_30' => count($buyers30),
            'created_30' => $created30,
            'conversion_30' => $created30 ? round($count['r30'] / $created30 * 100, 1) : 0,
            'coupon_orders_30' => $coupons['orders'],
            'coupon_discount_30' => $coupons['discount'],
        ],
        'daily' => $series,
        'monthly' => $months,
        'mix' => $mix,
        'mix_revenue' => $mixRevenue,
        'plans' => array_slice(array_values($folded), 0, 8),
        'gateways' => array_values($gateways),
        'heat' => $heat,
    ];
}

function dashboardUsers(): array
{
    $now = date('Y-m-d H:i:s');
    $soon = date('Y-m-d H:i:s', strtotime('+7 days'));

    $row = db()->prepare(
        "SELECT COUNT(*) AS total,
                SUM(status = 0) AS disabled,
                SUM(status = 1 AND expire_in <= ?) AS expired,
                SUM(status = 1 AND expire_in > ? AND transfer_enable > 0 AND u + d >= transfer_enable) AS exhausted,
                SUM(status = 1 AND expire_in > ? AND expire_in <= ? AND NOT (transfer_enable > 0 AND u + d >= transfer_enable)) AS soon,
                SUM(status = 1 AND expire_in > ? AND NOT (transfer_enable > 0 AND u + d >= transfer_enable)) AS active,
                COALESCE(SUM(money), 0) AS balance
           FROM user WHERE role = 0");
    $row->execute([$now, $now, $now, $soon, $soon]);
    $users = $row->fetch();

    // registrations per day, and the same window a month earlier for the delta.
    // `user` has a column named d (download bytes), so the day is never
    // aliased as d here: GROUP BY d would group by that column instead.
    $registered = dashboardDays(90, 0);
    $statement = db()->prepare('SELECT DATE(reg_date) AS day, COUNT(*) AS n FROM user WHERE role = 0 AND reg_date >= ? GROUP BY DATE(reg_date)');
    $statement->execute([date('Y-m-d', strtotime('-89 days'))]);
    foreach ($statement as $r) {
        if (isset($registered[$r['day']])) {
            $registered[$r['day']] = (int) $r['n'];
        }
    }

    $window = db()->prepare('SELECT COUNT(*) FROM user WHERE role = 0 AND reg_date >= ? AND reg_date < ?');
    $window->execute([date('Y-m-d', strtotime('-29 days')), date('Y-m-d', strtotime('+1 day'))]);
    $new30 = (int) $window->fetchColumn();
    $window->execute([date('Y-m-d', strtotime('-59 days')), date('Y-m-d', strtotime('-29 days'))]);
    $newPrev30 = (int) $window->fetchColumn();

    // who runs out over the next two weeks: the renewal pipeline
    $expiring = [];
    for ($i = 0; $i < 14; $i++) {
        $expiring[date('Y-m-d', strtotime("+$i days"))] = 0;
    }
    $statement = db()->prepare(
        'SELECT DATE(expire_in) AS day, COUNT(*) AS n FROM user
          WHERE role = 0 AND status = 1 AND expire_in > ? AND expire_in < ? GROUP BY DATE(expire_in)');
    $statement->execute([$now, date('Y-m-d', strtotime('+14 days'))]);
    foreach ($statement as $r) {
        if (isset($expiring[$r['day']])) {
            $expiring[$r['day']] = (int) $r['n'];
        }
    }

    $lapsed = db()->prepare('SELECT COUNT(*) FROM user WHERE role = 0 AND status = 1 AND expire_in <= ? AND expire_in > ?');
    $lapsed->execute([$now, date('Y-m-d H:i:s', strtotime('-7 days'))]);

    $online = (int) db()->query('SELECT COUNT(DISTINCT userid) FROM online_ip WHERE datetime > UNIX_TIMESTAMP() - 600')->fetchColumn();

    $series = [];
    foreach ($registered as $day => $n) {
        $series[] = ['d' => $day, 'n' => $n];
    }
    $pipeline = [];
    foreach ($expiring as $day => $n) {
        $pipeline[] = ['d' => $day, 'n' => $n];
    }

    return [
        'total' => (int) $users['total'],
        'active' => (int) $users['active'],
        'soon' => (int) $users['soon'],
        'exhausted' => (int) $users['exhausted'],
        'expired' => (int) $users['expired'],
        'disabled' => (int) $users['disabled'],
        'balance' => (float) $users['balance'],
        'online' => $online,
        'new_30' => $new30,
        'new_prev30' => $newPrev30,
        'lapsed_7' => (int) $lapsed->fetchColumn(),
        'registered' => $series,
        'expiring' => $pipeline,
    ];
}

function dashboardTraffic(): array
{
    $daily = dashboardDays(90, 0.0);
    $servers = [];
    $start30 = date('Y-m-d', strtotime('-29 days'));

    try {
        $statement = db()->prepare('SELECT day, COALESCE(SUM(total), 0) AS bytes FROM traffic_daily WHERE day >= ? GROUP BY day');
        $statement->execute([date('Y-m-d', strtotime('-89 days'))]);
        foreach ($statement as $r) {
            if (isset($daily[$r['day']])) {
                $daily[$r['day']] = round((float) $r['bytes'] / DASHBOARD_GB, 2);
            }
        }

        $statement = db()->prepare(
            'SELECT t.serverid, COALESCE(s.name, MAX(t.servername)) AS name, SUM(t.total) AS bytes
               FROM traffic_daily t LEFT JOIN servers s ON s.id = t.serverid
              WHERE t.day >= ? GROUP BY t.serverid, s.name ORDER BY bytes DESC');
        $statement->execute([$start30]);
        foreach ($statement as $r) {
            $servers[] = ['name' => (string) $r['name'], 'gb' => round((float) $r['bytes'] / DASHBOARD_GB, 2)];
        }
    } catch (Throwable $error) {
        // traffic_daily comes from migration 002; without it the chart is empty
    }

    $series = [];
    foreach ($daily as $day => $gb) {
        $series[] = ['d' => $day, 'gb' => $gb];
    }

    return ['daily' => $series, 'servers' => $servers];
}

function dashboardNodes(): array
{
    $online = [];
    $statement = db()->query('SELECT serverid, COUNT(DISTINCT userid) AS n FROM online_ip WHERE datetime > UNIX_TIMESTAMP() - 600 GROUP BY serverid');
    foreach ($statement as $r) {
        $online[(int) $r['serverid']] = (int) $r['n'];
    }

    $today = [];
    try {
        $statement = db()->prepare('SELECT serverid, SUM(total) AS bytes FROM traffic_daily WHERE day = ? GROUP BY serverid');
        $statement->execute([date('Y-m-d')]);
        foreach ($statement as $r) {
            $today[(int) $r['serverid']] = round((float) $r['bytes'] / DASHBOARD_GB, 2);
        }
    } catch (Throwable $error) {
    }

    $nodes = [];
    foreach (db()->query('SELECT id, name, status, heartbeat, alive, server_load FROM servers ORDER BY sort, id') as $r) {
        $id = (int) $r['id'];
        $age = (int) $r['heartbeat'] > 0 ? time() - (int) $r['heartbeat'] : null;
        $load = (float) strtok((string) $r['server_load'], ' ');
        $enabled = (int) $r['status'] === 1;
        $up = $enabled && (int) $r['alive'] === 1 && $age !== null && $age <= DASHBOARD_NODE_STALE;

        $nodes[] = [
            'name' => (string) $r['name'],
            'state' => !$enabled ? 'off' : ($up ? 'up' : 'down'),
            'age' => $age,
            'load' => $enabled ? $load : null,
            'online' => $online[$id] ?? 0,
            'today_gb' => $today[$id] ?? 0,
        ];
    }

    return $nodes;
}

function dashboardRecent(array $names): array
{
    $recent = [];
    $statement = db()->query(
        'SELECT order_id, username, packageid, packagetype, total_amount, gateway_name,
                COALESCE(pay_date, create_date) AS t
           FROM orders WHERE status = 1 ORDER BY id DESC LIMIT 8');
    foreach ($statement as $r) {
        $recent[] = [
            'id' => (string) $r['order_id'],
            'user' => (string) $r['username'],
            'plan' => $names[(int) $r['packageid']] ?? ('#' . (int) $r['packageid']),
            'topup' => (int) $r['packagetype'] === 1,
            'amount' => (float) $r['total_amount'],
            'gateway' => (string) ($r['gateway_name'] ?? ''),
            't' => (int) $r['t'],
        ];
    }
    return $recent;
}

/** Newest modification time among files matching a glob, or null. */
function dashboardNewest(string $pattern): ?int
{
    $newest = null;
    foreach (glob($pattern) ?: [] as $file) {
        $time = @filemtime($file);
        if ($time !== false && ($newest === null || $time > $newest)) {
            $newest = $time;
        }
    }
    return $newest;
}

/**
 * The health checks. Each one is ok / warn / fail with a value the page shows
 * as is; `key` picks the translated label. Nothing here may throw: a check
 * that cannot run reports warn instead of taking the dashboard down with it.
 */
function dashboardHealth(array $nodes, float $dbMs): array
{
    $checks = [];
    $add = function (string $key, string $state, string $value) use (&$checks) {
        $checks[] = ['key' => $key, 'state' => $state, 'value' => $value];
    };

    $add('db', $dbMs < 200 ? 'ok' : 'warn', round($dbMs) . ' ms');

    $enabled = array_filter($nodes, function ($n) { return $n['state'] !== 'off'; });
    $down = array_filter($enabled, function ($n) { return $n['state'] === 'down'; });
    $add('nodes', count($down) === 0 ? 'ok' : (count($down) < count($enabled) ? 'warn' : 'fail'),
        (count($enabled) - count($down)) . ' / ' . count($enabled));

    // jobby touches a lock per job every time it runs one
    $cron = dashboardNewest(ROOT . '/storage/cron/*.lck');
    $cronAge = $cron === null ? null : time() - $cron;
    $add('cron', $cronAge !== null && $cronAge <= DASHBOARD_CRON_STALE ? 'ok' : 'fail',
        $cronAge === null ? '-' : dashboardAge($cronAge));

    // nodes push trafficlog rows every minute or so while anyone is connected
    $last = (int) db()->query('SELECT COALESCE(MAX(datetime), 0) FROM trafficlog')->fetchColumn();
    $trafficAge = $last > 0 ? time() - $last : null;
    $add('traffic', $trafficAge !== null && $trafficAge <= 900 ? 'ok' : 'warn',
        $trafficAge === null ? '-' : dashboardAge($trafficAge));

    // orders left unpaid for more than an hour today: a gateway that fails
    // quietly shows up here first
    $statement = db()->prepare(
        'SELECT COUNT(*) AS created, SUM(status = 1) AS paid FROM orders WHERE create_date >= ? AND create_date < ?');
    $statement->execute([time() - 86400, time() - 3600]);
    $orders = $statement->fetch();
    $created = (int) $orders['created'];
    $paid = (int) $orders['paid'];
    $rate = $created > 0 ? $paid / $created * 100 : 100;
    $add('payments', $created < 5 || $rate >= 40 ? 'ok' : ($rate >= 15 ? 'warn' : 'fail'),
        $created > 0 ? round($rate) . '% · ' . $paid . '/' . $created : '-');

    $free = @disk_free_space(ROOT);
    $total = @disk_total_space(ROOT);
    if ($free !== false && $total) {
        $pct = $free / $total * 100;
        $add('disk', $pct >= 15 ? 'ok' : ($pct >= 5 ? 'warn' : 'fail'), round($free / DASHBOARD_GB, 1) . ' GB · ' . round($pct) . '%');
    }

    if (function_exists('sys_getloadavg')) {
        $load = sys_getloadavg();
        $cores = dashboardCores();
        if (is_array($load)) {
            $ratio = $load[0] / max(1, $cores);
            $add('load', $ratio < 0.8 ? 'ok' : ($ratio < 1.5 ? 'warn' : 'fail'), number_format($load[0], 2) . ' / ' . $cores);
        }
    }

    $compile = ROOT . '/storage/smarty/compile';
    $add('storage', is_dir($compile) && is_writable($compile) ? 'ok' : 'warn', '');

    try {
        $pending = (int) db()->query(
            'SELECT COUNT(*) FROM orders o LEFT JOIN timeplan_log l ON l.orderid = o.id
              JOIN package p ON p.id = o.packageid
             WHERE o.status = 1 AND o.packagetype = 1 AND p.order_note LIKE \'%"timeplan"%\'
               AND l.id IS NULL AND COALESCE(o.pay_date, o.create_date) < UNIX_TIMESTAMP() - 300')->fetchColumn();
        $add('timeplan', $pending === 0 ? 'ok' : 'fail', (string) $pending);
    } catch (Throwable $error) {
        // no timeplan_log yet: nothing was ever sold, nothing can be pending
    }

    $add('patch', 'ok', (string) setting('patch_version', '-') . ' · PHP ' . PHP_VERSION);

    return $checks;
}

function dashboardCores(): int
{
    $info = @file_get_contents('/proc/cpuinfo');
    if (is_string($info) && preg_match_all('/^processor\s*:/m', $info, $m)) {
        return max(1, count($m[0]));
    }
    return 1;
}

function dashboardAge(int $seconds): string
{
    if ($seconds < 90) {
        return $seconds . 's';
    }
    if ($seconds < 5400) {
        return round($seconds / 60) . 'm';
    }
    if ($seconds < 172800) {
        return round($seconds / 3600) . 'h';
    }
    return round($seconds / 86400) . 'd';
}

function dashboardOverview(): void
{
    $started = microtime(true);
    dashboardTimezone();
    db()->query('SELECT 1')->fetchColumn();
    $dbMs = (microtime(true) - $started) * 1000;

    $names = dashboardPackageNames();
    $nodes = dashboardNodes();

    done([
        'generated' => date('Y-m-d H:i:s'),
        'sales' => dashboardSales(dashboardTimePlanIds(), $names, ($_GET['cal'] ?? '') === 'jalali'),
        'users' => dashboardUsers(),
        'traffic' => dashboardTraffic(),
        'nodes' => $nodes,
        'recent' => dashboardRecent($names),
        'health' => dashboardHealth($nodes, $dbMs),
        'took_ms' => (int) round((microtime(true) - $started) * 1000),
    ]);
}

if ($action === 'dashboard.overview') {
    dashboardOverview();
}
