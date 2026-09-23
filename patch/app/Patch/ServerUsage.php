<?php
/**
 * Per-server traffic for the admin servers page.
 *
 * Included by public/xmplus-patch.php, in its global scope, after
 * requireAdmin() - so only an admin ever reaches it. Borrows db(), fail() and
 * done(). Read-only: it never writes anything, which is why it takes GET and
 * needs no CSRF token.
 *
 * Sources:
 *   trafficlog     raw rows, today only (LogsJob prunes everything older)
 *   traffic_daily  per user/day/server roll-up written by TrafficStatsJob
 */

declare(strict_types=1);

const SERVERUSAGE_GB = 1073741824;

function serverUsageTimezone(): void
{
    db(); // loads config/config.php, which fills $_ENV['timeZone']
    $zone = (string) ($_ENV['timeZone'] ?? '');
    if ($zone !== '' && in_array($zone, timezone_identifiers_list(), true)) {
        date_default_timezone_set($zone);
    }
}

function serverUsageGb(float $bytes): float
{
    return round($bytes / SERVERUSAGE_GB, 2);
}

/** id => current name, from the servers table; deleted servers fall back to the log name. */
function serverUsageNames(): array
{
    $names = [];
    foreach (db()->query('SELECT id, name FROM servers') as $row) {
        $names[(int) $row['id']] = (string) $row['name'];
    }
    return $names;
}

function serverUsageReport(): void
{
    serverUsageTimezone();

    $names = serverUsageNames();
    $start = strtotime('today 00:00:00');
    $today = date('Y-m-d');
    $hours = (int) date('G') + 1;

    // ---- today, hour by hour, per server
    $hourly = [];
    $statement = db()->prepare(
        'SELECT serverid, FLOOR((datetime - ?) / 3600) AS h, MAX(servername) AS sname,
                COALESCE(SUM(u + d), 0) AS bytes
           FROM trafficlog
          WHERE datetime >= ?
          GROUP BY serverid, h');
    $statement->execute([$start, $start]);

    foreach ($statement as $row) {
        $id = (int) $row['serverid'];
        $h = (int) $row['h'];
        if ($h < 0 || $h >= $hours) {
            continue;
        }
        if (!isset($names[$id]) && (string) $row['sname'] !== '') {
            $names[$id] = (string) $row['sname'];
        }
        $hourly[$id][$h] = ($hourly[$id][$h] ?? 0.0) + (float) $row['bytes'];
    }

    // ---- earlier days, per server, from the roll-up
    $daily = [];
    $since = $today;
    try {
        $since = (string) (db()->query('SELECT MIN(day) FROM traffic_daily')->fetchColumn() ?: $today);

        $statement = db()->prepare(
            'SELECT day, serverid, MAX(servername) AS sname, COALESCE(SUM(total), 0) AS bytes
               FROM traffic_daily
              WHERE day >= ? AND day < ?
              GROUP BY day, serverid');
        $statement->execute([date('Y-m-d', strtotime('-29 days')), $today]);

        foreach ($statement as $row) {
            $id = (int) $row['serverid'];
            if (!isset($names[$id]) && (string) $row['sname'] !== '') {
                $names[$id] = (string) $row['sname'];
            }
            $daily[$id][substr((string) $row['day'], 0, 10)] = (float) $row['bytes'];
        }
    } catch (Throwable $error) {
        $daily = []; // table missing on an install that never ran TrafficStatsJob
    }

    // today's live total goes into the day series too
    foreach ($hourly as $id => $buckets) {
        $daily[$id][$today] = (float) array_sum($buckets);
    }

    // ---- build the ranges
    $ids = array_unique(array_merge(array_keys($hourly), array_keys($daily)));

    $dayLabels = [];
    for ($h = 0; $h < $hours; $h++) {
        $dayLabels[] = sprintf('%02d:00', $h);
    }

    $dates = function (int $count): array {
        $out = [];
        for ($i = $count - 1; $i >= 0; $i--) {
            $out[] = date('Y-m-d', strtotime('-' . $i . ' days'));
        }
        return $out;
    };
    $week = $dates(7);
    $month = $dates(30);

    $ranges = [
        'day'   => ['labels' => $dayLabels, 'series' => []],
        'week'  => ['labels' => $week, 'series' => []],
        'month' => ['labels' => $month, 'series' => []],
    ];
    $servers = [];

    foreach ($ids as $id) {
        $daySeries = [];
        for ($h = 0; $h < $hours; $h++) {
            $daySeries[] = serverUsageGb($hourly[$id][$h] ?? 0.0);
        }

        $weekSeries = [];
        $weekBytes = 0.0;
        foreach ($week as $date) {
            $bytes = $daily[$id][$date] ?? 0.0;
            $weekBytes += $bytes;
            $weekSeries[] = serverUsageGb($bytes);
        }

        $monthSeries = [];
        $monthBytes = 0.0;
        foreach ($month as $date) {
            $bytes = $daily[$id][$date] ?? 0.0;
            $monthBytes += $bytes;
            $monthSeries[] = serverUsageGb($bytes);
        }

        if ($monthBytes <= 0) {
            continue;
        }

        $key = (string) $id;
        $ranges['day']['series'][$key] = $daySeries;
        $ranges['week']['series'][$key] = $weekSeries;
        $ranges['month']['series'][$key] = $monthSeries;

        $servers[] = [
            'id'    => $id,
            'name'  => $names[$id] ?? ('#' . $id),
            'today' => serverUsageGb((float) array_sum($hourly[$id] ?? [])),
            'week'  => serverUsageGb($weekBytes),
            'month' => serverUsageGb($monthBytes),
        ];
    }

    usort($servers, function (array $a, array $b): int {
        return $b['month'] <=> $a['month'];
    });

    done([
        'servers'   => $servers,
        'ranges'    => $ranges,
        'since'     => substr($since, 0, 10),
        'generated' => date('Y-m-d H:i'),
    ]);
}

// ---------------------------------------------------------------- dispatch

switch (substr((string) ($_GET['do'] ?? ''), strlen('servers.'))) {
    case 'usage':
        serverUsageReport();
}

fail('unknown servers action');
