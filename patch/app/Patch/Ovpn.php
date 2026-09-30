<?php
/**
 * OpenVPN servers on the same subscription.
 *
 * Included by public/xmplus-patch.php, in its global scope, before the blanket
 * requireAdmin(): the node actions are called by the OpenVPN servers and the
 * profile download by ordinary users. Borrows db(), fail(), done(), setting(),
 * putSetting(), startPanelSession(), requireAdmin() and requireToken(). Every
 * path ends in done() or fail().
 *
 * An OpenVPN server runs node/openvpn/ovpn-agent.py next to OpenVPN, holding
 * OpenVPN's management socket with --management-client-auth. For each login
 * it asks ovpn.auth; once a minute it sends every session's running byte
 * counters to ovpn.push. The growth since the last push is added to
 * user.u / user.d (times the node's multiplier, as the panel does for its own
 * servers) and written to trafficlog (raw), so the plan's quota, the wallet
 * billing in PaygJob, the charts and the reports count OpenVPN like any other
 * server. The answer names the sessions whose account may no longer connect
 * (plan over, quota used, disabled, moved to another group) and the agent
 * kills them - the same cut-off the Xray nodes apply.
 *
 *   node, header X-Ovpn-Node / X-Ovpn-Key:
 *     ovpn.hello      the node reports its address and what a profile needs
 *     ovpn.auth       may this login connect (JSON: user, pass, ip)
 *     ovpn.push       session counters; answers the sessions to kill
 *   customer, panel session:
 *     ovpn.profile    the .ovpn file for one node
 *   admin, panel session (+ patch_csrf token for writes):
 *     ovpn.admin / ovpn.sessions                      reports (GET)
 *     ovpn.save / ovpn.nodesave / ovpn.nodekey / ovpn.nodedel
 *
 * Logins are "u<user id>". The password is derived from the account's uuid
 * and the `ovpn_secret` setting (see ovpnPassword(); User::ovpnPassword()
 * must stay identical), so resetting the subscription link in the panel also
 * changes the OpenVPN password, and nothing extra has to be stored.
 *
 * Nodes are not rows in `servers`: the panel's encoded subscription builder
 * would put them into every customer's Xray link. Their traffic is logged
 * under the virtual server id OVPN_SERVER_BASE + node id, which PaygJob and
 * the price list know about.
 */

declare(strict_types=1);

const OVPN_SERVER_BASE = 900000;
/* a session not pushed for this long has gone; a node silent this long is down */
const OVPN_STALE = 180;
const OVPN_PUSH_INTERVAL = 60;
const OVPN_PASS_ALPHABET = 'abcdefghjkmnpqrstuvwxyz23456789';

// ------------------------------------------------------------------ helpers

function ovpnSetting(string $name, string $fallback): string
{
    $value = setting($name, null);

    return $value === null || $value === '' ? $fallback : (string) $value;
}

function ovpnEnabled(): bool
{
    return ovpnSetting('ovpn_enabled', '0') === '1';
}

/** expire_in is written in the panel's local time, so compare it there. */
function ovpnTimezone(): void
{
    db(); // loads config/config.php, which fills $_ENV['timeZone']
    $zone = (string) ($_ENV['timeZone'] ?? '');
    if ($zone !== '' && in_array($zone, timezone_identifiers_list(), true)) {
        date_default_timezone_set($zone);
    }
}

function ovpnLogin(int $userId): string
{
    return 'u' . $userId;
}

function ovpnUserIdFromLogin(string $login): int
{
    return preg_match('~^u([1-9][0-9]{0,9})$~', trim($login), $match) ? (int) $match[1] : 0;
}

/** Keep in step with User::ovpnPassword(). */
function ovpnPassword(int $userId, string $uuid): string
{
    $secret = ovpnSetting('ovpn_secret', '');

    if ($secret === '' || trim($uuid) === '') {
        return '';
    }

    $raw = hash_hmac('sha256', $userId . ':' . strtolower(trim($uuid)), $secret, true);
    $size = strlen(OVPN_PASS_ALPHABET);
    $out = '';

    for ($i = 0; $i < 12; $i++) {
        $out .= OVPN_PASS_ALPHABET[ord($raw[$i]) % $size];
    }

    return $out;
}

/** "3,8" -> [3, 8]; empty means every group. */
function ovpnGroups($value): array
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

function ovpnServerId(int $nodeId): int
{
    return OVPN_SERVER_BASE + $nodeId;
}

function ovpnJsonBody(): array
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
function ovpnColumns(string $table): array
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

function ovpnHasColumn(string $table, string $column): bool
{
    return isset(ovpnColumns($table)[$column]);
}

/** Insert into a panel-owned table; $upsert columns are refreshed on a duplicate key. */
function ovpnInsert(string $table, array $values, array $upsert = []): void
{
    $columns = ovpnColumns($table);

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

function ovpnBytesText(float $bytes): string
{
    $units = ['B', 'KB', 'MB', 'GB', 'TB'];
    $i = 0;

    while ($bytes >= 1024 && $i < count($units) - 1) {
        $bytes /= 1024;
        $i++;
    }

    return round($bytes, 2) . $units[$i];
}

// -------------------------------------------------------------------- nodes

function ovpnNode(int $id): ?array
{
    $statement = db()->prepare('SELECT * FROM ovpn_node WHERE id = ? LIMIT 1');
    $statement->execute([$id]);
    $row = $statement->fetch();

    return $row === false ? null : $row;
}

/** The calling OpenVPN server, by the key it was given when it was added. */
function ovpnRequireNode(): array
{
    $id = (int) ($_SERVER['HTTP_X_OVPN_NODE'] ?? 0);
    $key = (string) ($_SERVER['HTTP_X_OVPN_KEY'] ?? '');

    if ($id <= 0 || strlen($key) < 32) {
        fail('node credentials missing', 403);
    }

    $node = ovpnNode($id);

    if ($node === null || !hash_equals((string) $node['keyhash'], hash('sha256', $key))) {
        fail('unknown node or wrong key', 403);
    }

    return $node;
}

function ovpnNodeHost(array $node): string
{
    $override = trim((string) $node['host_override']);

    return $override !== '' ? $override : trim((string) $node['host']);
}

function ovpnNodeLive(array $node): bool
{
    return (int) $node['heartbeat'] > time() - OVPN_STALE;
}

/** A node a customer can be given a profile for. */
function ovpnNodeUsable(array $node): bool
{
    return (int) $node['enabled'] === 1 && ovpnNodeHost($node) !== ''
        && trim((string) $node['ca']) !== '' && trim((string) $node['tls_crypt']) !== '';
}

function ovpnNodeServes(array $node, array $user): bool
{
    $groups = ovpnGroups($node['allowed_groups']);

    return $groups === [] || in_array((int) ($user['server_group'] ?? 0), $groups, true);
}

// -------------------------------------------------------------------- users

function ovpnUser(int $id): ?array
{
    if ($id <= 0) {
        return null;
    }

    $statement = db()->prepare('SELECT * FROM user WHERE id = ? LIMIT 1');
    $statement->execute([$id]);
    $row = $statement->fetch();

    return $row === false ? null : $row;
}

/**
 * Why this account may not use this node right now, or '' when it may. The
 * same reading of the account the admin dashboard uses: status 1 is active,
 * the plan runs until expire_in, and a quota is used up at u + d.
 */
function ovpnRefusal(?array $user, array $node): string
{
    if (!ovpnEnabled()) {
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

    if (!ovpnNodeServes($node, $user)) {
        return 'group';
    }

    return '';
}

/**
 * The account's device limit, counted over the addresses the Xray nodes
 * reported in online_ip and the live OpenVPN sessions. An address already
 * connected does not count twice.
 */
function ovpnOverIpLimit(array $user, string $ip): bool
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
        // no online_ip table: count OpenVPN alone
    }

    $statement = db()->prepare('SELECT DISTINCT ip FROM ovpn_session WHERE userid = ? AND closed = 0 AND seen >= ?');
    $statement->execute([(int) $user['id'], time() - OVPN_STALE]);
    foreach ($statement->fetchAll(PDO::FETCH_COLUMN) as $seen) {
        $ips[(string) $seen] = true;
    }

    unset($ips['']);

    return !isset($ips[$ip]) && count($ips) >= $limit;
}

// ------------------------------------------------------------- node actions

/**
 * The one block between $begin and $end, and nothing else: whatever is kept
 * here ends up inside every customer's profile, so comments around it (the
 * tls-crypt key file starts with some) are dropped and the body may only be
 * base64 / hex.
 */
function ovpnPem(string $text, string $begin, string $end): string
{
    $text = str_replace("\r", '', $text);
    $pattern = '~' . preg_quote($begin, '~') . '\n([A-Za-z0-9+/=\n]+?)\n?' . preg_quote($end, '~') . '~';

    if (strlen($text) > 16384 || !preg_match($pattern, $text, $match)) {
        return '';
    }

    return $begin . "\n" . trim($match[1]) . "\n" . $end;
}

function ovpnHello(): void
{
    $node = ovpnRequireNode();
    $body = ovpnJsonBody();

    $host = trim((string) ($body['host'] ?? ''));
    if ($host !== '' && !preg_match('~^[A-Za-z0-9.:-]{1,253}$~', $host)) {
        fail('bad host');
    }

    $port = (int) ($body['port'] ?? 0);
    if ($port < 1 || $port > 65535) {
        fail('bad port');
    }

    $proto = strtolower((string) ($body['proto'] ?? 'udp'));
    $proto = strpos($proto, 'tcp') === 0 ? 'tcp' : 'udp';

    $ca = ovpnPem((string) ($body['ca'] ?? ''), '-----BEGIN CERTIFICATE-----', '-----END CERTIFICATE-----');
    $tlsCrypt = ovpnPem((string) ($body['tls_crypt'] ?? ''),
        '-----BEGIN OpenVPN Static key V1-----', '-----END OpenVPN Static key V1-----');

    if ($ca === '' || $tlsCrypt === '') {
        fail('ca or tls_crypt missing or malformed');
    }

    $version = substr(preg_replace('~[^A-Za-z0-9._-]~', '', (string) ($body['version'] ?? '')), 0, 32);

    db()->prepare('UPDATE ovpn_node SET host = ?, port = ?, proto = ?, ca = ?, tls_crypt = ?, agent_version = ?,
                          heartbeat = ?, updated = ? WHERE id = ?')
        ->execute([$host, $port, $proto, $ca, $tlsCrypt, $version, time(), time(), (int) $node['id']]);

    done(['node' => (int) $node['id'], 'name' => (string) $node['name'], 'interval' => OVPN_PUSH_INTERVAL]);
}

function ovpnAuth(): void
{
    ovpnTimezone();
    $node = ovpnRequireNode();
    $body = ovpnJsonBody();

    $login = (string) ($body['user'] ?? '');
    $pass = (string) ($body['pass'] ?? '');
    $ip = substr(trim((string) ($body['ip'] ?? '')), 0, 64);

    $user = ovpnUser(ovpnUserIdFromLogin($login));
    $expected = $user === null ? '' : ovpnPassword((int) $user['id'], (string) ($user['uuid'] ?? ''));

    if ($user === null || $expected === '' || !hash_equals($expected, strtolower(trim($pass)))) {
        done(['allow' => false, 'reason' => 'password']);
    }

    $reason = ovpnRefusal($user, $node);

    if ($reason === '' && ovpnOverIpLimit($user, $ip)) {
        $reason = 'iplimit';
    }

    done(['allow' => $reason === '', 'reason' => $reason, 'user' => ovpnLogin((int) $user['id'])]);
}

function ovpnPush(): void
{
    ovpnTimezone();
    $node = ovpnRequireNode();
    $body = ovpnJsonBody();
    $pdo = db();
    $now = time();
    $nodeId = (int) $node['id'];
    $rate = max(0.0, (float) $node['rate']);
    $serverId = ovpnServerId($nodeId);
    $serverName = 'OpenVPN · ' . (string) $node['name'];

    $reports = [];
    foreach (['sessions' => false, 'closed' => true] as $key => $closed) {
        foreach (is_array($body[$key] ?? null) ? $body[$key] : [] as $item) {
            if (!is_array($item)) {
                continue;
            }
            $sid = (string) ($item['sid'] ?? '');
            if (!preg_match('~^[A-Za-z0-9._:-]{1,80}$~', $sid)) {
                continue;
            }
            $reports[] = [
                'sid'    => $sid,
                'userid' => ovpnUserIdFromLogin((string) ($item['user'] ?? '')),
                'ip'     => substr(trim((string) ($item['ip'] ?? '')), 0, 64),
                'vip'    => substr(trim((string) ($item['vip'] ?? '')), 0, 64),
                'rx'     => max(0, (int) ($item['rx'] ?? 0)),
                'tx'     => max(0, (int) ($item['tx'] ?? 0)),
                'closed' => $closed,
            ];
        }
    }

    $usage = [];   // user id => [upload, download] in raw bytes
    $live = [];    // sid => user id, sessions still connected

    $pdo->beginTransaction();

    try {
        $find = $pdo->prepare('SELECT id, userid, rx, tx, closed FROM ovpn_session WHERE nodeid = ? AND sid = ? FOR UPDATE');
        $create = $pdo->prepare('INSERT INTO ovpn_session (nodeid, sid, userid, ip, vip, rx, tx, started, seen, closed)
                                 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)');
        $update = $pdo->prepare('UPDATE ovpn_session SET rx = ?, tx = ?, ip = ?, vip = ?, seen = ?, closed = ? WHERE id = ?');

        foreach ($reports as $report) {
            if ($report['userid'] <= 0) {
                continue;
            }

            $find->execute([$nodeId, $report['sid']]);
            $row = $find->fetch();
            $closedAt = $report['closed'] ? $now : 0;
            // a session belongs to the account it connected as
            $owner = $row === false ? $report['userid'] : (int) $row['userid'];

            if ($row === false) {
                // counters start at zero when a session connects
                $up = $report['rx'];
                $down = $report['tx'];
                $create->execute([$nodeId, $report['sid'], $report['userid'], $report['ip'], $report['vip'],
                    $report['rx'], $report['tx'], $now, $now, $closedAt]);
            } else {
                if ((int) $row['closed'] > 0) {
                    continue; // already settled; a repeated "closed" report counts nothing
                }
                // running totals: only the growth counts, so a resent push adds nothing
                $up = max(0, $report['rx'] - (int) $row['rx']);
                $down = max(0, $report['tx'] - (int) $row['tx']);
                $update->execute([max($report['rx'], (int) $row['rx']), max($report['tx'], (int) $row['tx']),
                    $report['ip'], $report['vip'], $now, $closedAt, (int) $row['id']]);
            }

            if ($up + $down > 0) {
                $usage[$owner][0] = ($usage[$owner][0] ?? 0) + $up;
                $usage[$owner][1] = ($usage[$owner][1] ?? 0) + $down;
            }

            if (!$report['closed']) {
                $live[$report['sid']] = $owner;
            }
        }

        $total = ovpnHasColumn('user', 'total_data_used');
        $touch = ovpnHasColumn('user', 't');
        $sql = 'UPDATE user SET u = u + ?, d = d + ?'
            . ($total ? ', total_data_used = total_data_used + ?' : '')
            . ($touch ? ', t = ?' : '')
            . ' WHERE id = ?';
        $charge = $pdo->prepare($sql);

        foreach ($usage as $userId => [$up, $down]) {
            $upCharged = (int) round($up * $rate);
            $downCharged = (int) round($down * $rate);

            $params = [$upCharged, $downCharged];
            if ($total) {
                $params[] = $upCharged + $downCharged;
            }
            if ($touch) {
                $params[] = $now;
            }
            $params[] = $userId;
            $charge->execute($params);

            // raw bytes, as the nodes log them; PaygJob bills from these
            ovpnInsert('trafficlog', [
                'userid'     => $userId,
                'serverid'   => $serverId,
                'servername' => $serverName,
                'u'          => $up,
                'd'          => $down,
                'total'      => $up + $down,
                'rate'       => $rate,
                'traffic'    => ovpnBytesText((float) ($up + $down)),
                'datetime'   => $now,
            ]);
        }

        $pdo->commit();
    } catch (Throwable $error) {
        $pdo->rollBack();
        error_log('ovpn.push: ' . $error->getMessage());
        fail('push not stored');
    }

    // who is online, for the device limit and the dashboard's "connected" mark
    $seenIp = [];
    foreach ($reports as $report) {
        if (!$report['closed'] && $report['userid'] > 0 && $report['ip'] !== ''
            && !isset($seenIp[$report['userid'] . '|' . $report['ip']])) {
            $seenIp[$report['userid'] . '|' . $report['ip']] = true;
            try {
                ovpnInsert('online_ip', [
                    'userid'   => $report['userid'],
                    'serverid' => $serverId,
                    'ip'       => $report['ip'],
                    'datetime' => $now,
                ], ['datetime', 'serverid']);
            } catch (Throwable $error) {
                // the mark is cosmetic; the usage above is already stored
            }
        }
    }

    // sessions whose account may not connect any more
    $kick = [];
    $verdicts = [];
    foreach ($live as $sid => $userId) {
        if (!array_key_exists($userId, $verdicts)) {
            $verdicts[$userId] = ovpnRefusal(ovpnUser($userId), $node);
        }
        if ($verdicts[$userId] !== '') {
            $kick[] = ['sid' => $sid, 'reason' => $verdicts[$userId]];
        }
    }

    $pdo->prepare('UPDATE ovpn_node SET heartbeat = ?, online = ?, updated = ? WHERE id = ?')
        ->execute([$now, count($live), $now, $nodeId]);

    // a session the agent stopped reporting (agent or OpenVPN restarted) is over
    $pdo->prepare('UPDATE ovpn_session SET closed = ? WHERE nodeid = ? AND closed = 0 AND seen < ?')
        ->execute([$now, $nodeId, $now - OVPN_STALE]);
    $pdo->prepare('DELETE FROM ovpn_session WHERE nodeid = ? AND closed > 0 AND closed < ?')
        ->execute([$nodeId, $now - 86400]);

    done(['kick' => $kick, 'interval' => OVPN_PUSH_INTERVAL, 'enabled' => (int) $node['enabled'] === 1]);
}

// --------------------------------------------------------- customer actions

function ovpnRequireUser(): array
{
    startPanelSession();

    $login = $_SESSION['login_session'] ?? null;

    if (!is_array($login) || empty($login['uid'])) {
        fail('login required', 403);
    }

    if (!empty($login['expire']) && (int) $login['expire'] < time()) {
        fail('session expired', 403);
    }

    $user = ovpnUser((int) $login['uid']);

    if ($user === null) {
        fail('account not found', 403);
    }

    return $user;
}

function ovpnProfileText(array $node, string $login): string
{
    $proto = (string) $node['proto'] === 'tcp' ? 'tcp' : 'udp';
    $lines = [
        '# ' . preg_replace('~[\r\n]+~', ' ', (string) $node['name']),
        '# OVPN_ACCESS_SERVER_USERNAME=' . $login,
        'client',
        'dev tun',
        'proto ' . $proto,
        'remote ' . ovpnNodeHost($node) . ' ' . (int) $node['port'],
        'resolv-retry infinite',
        'nobind',
        'persist-key',
        'persist-tun',
        'remote-cert-tls server',
        'auth-user-pass',
        // no cipher lines: the data cipher is negotiated, and a 2.4 client
        // refuses the whole file over an option it does not know
        'verb 3',
    ];

    if ($proto === 'udp') {
        $lines[] = 'explicit-exit-notify 1';
    }

    $lines[] = '<ca>';
    $lines[] = trim((string) $node['ca']);
    $lines[] = '</ca>';
    $lines[] = '<tls-crypt>';
    $lines[] = trim((string) $node['tls_crypt']);
    $lines[] = '</tls-crypt>';

    return implode("\n", $lines) . "\n";
}

function ovpnProfile(): void
{
    $user = ovpnRequireUser();
    $node = ovpnNode((int) ($_GET['node'] ?? 0));

    if (!ovpnEnabled() || $node === null || !ovpnNodeUsable($node) || !ovpnNodeServes($node, $user)) {
        fail('this server is not available for your account');
    }

    $slug = strtolower(trim(preg_replace('~[^A-Za-z0-9]+~', '-', (string) $node['name']), '-'));
    $file = 'digitsell-' . ($slug !== '' ? $slug : 'server-' . (int) $node['id']) . '.ovpn';

    header('Content-Type: application/x-openvpn-profile');
    header('Content-Disposition: attachment; filename="' . $file . '"');
    header('Cache-Control: no-store, private');
    echo ovpnProfileText($node, ovpnLogin((int) $user['id']));
    exit;
}

// ------------------------------------------------------------ admin actions

function ovpnAdminToken(): string
{
    if (empty($_SESSION['patch_csrf'])) {
        $_SESSION['patch_csrf'] = bin2hex(random_bytes(24));
    }

    return (string) $_SESSION['patch_csrf'];
}

function ovpnNodeView(array $node): array
{
    return [
        'id'            => (int) $node['id'],
        'name'          => (string) $node['name'],
        'groups'        => ovpnGroups($node['allowed_groups']),
        'rate'          => (float) $node['rate'],
        'enabled'       => (int) $node['enabled'] === 1,
        'sort'          => (int) $node['sort'],
        'host'          => (string) $node['host'],
        'host_override' => (string) $node['host_override'],
        'port'          => (int) $node['port'],
        'proto'         => (string) $node['proto'],
        'ready'         => ovpnNodeUsable($node),
        'live'          => ovpnNodeLive($node),
        'heartbeat'     => (int) $node['heartbeat'],
        'online'        => ovpnNodeLive($node) ? (int) $node['online'] : 0,
        'version'       => (string) $node['agent_version'],
        'serverid'      => ovpnServerId((int) $node['id']),
    ];
}

function ovpnAdminBootstrap(): void
{
    requireAdmin();

    $nodes = [];
    foreach (db()->query('SELECT * FROM ovpn_node ORDER BY sort, id') as $row) {
        $nodes[] = ovpnNodeView($row);
    }

    $groups = [];
    try {
        $groups = db()->query('SELECT id, name FROM `group` ORDER BY id ASC')->fetchAll();
    } catch (Throwable $error) {
        $groups = [];
    }

    $today = strtotime('today');
    $usage = db()->prepare(
        'SELECT serverid, COALESCE(SUM(u + d), 0) AS bytes FROM trafficlog
          WHERE serverid > ? AND datetime >= ? GROUP BY serverid');
    $usage->execute([OVPN_SERVER_BASE, $today]);
    $todayBytes = [];
    foreach ($usage as $row) {
        $todayBytes[(int) $row['serverid']] = (float) $row['bytes'];
    }
    foreach ($nodes as &$node) {
        $node['today_bytes'] = $todayBytes[$node['serverid']] ?? 0.0;
    }
    unset($node);

    done([
        'token'   => ovpnAdminToken(),
        'enabled' => ovpnEnabled(),
        'nodes'   => $nodes,
        'groups'  => $groups,
        'repo'    => repo(),
        'branch'  => branch(),
    ]);
}

function ovpnAdminSave(): void
{
    requireAdmin();
    requireToken();

    putSetting('ovpn_enabled', !empty($_POST['enabled']) && $_POST['enabled'] !== '0' ? '1' : '0');

    done(['enabled' => ovpnEnabled()]);
}

function ovpnNewKey(): string
{
    return bin2hex(random_bytes(24));
}

function ovpnAdminNodeSave(): void
{
    requireAdmin();
    requireToken();

    $id = (int) ($_POST['id'] ?? 0);
    $name = trim(preg_replace('~[\x00-\x1F\x7F]+~u', ' ', (string) ($_POST['name'] ?? '')));
    $name = function_exists('mb_substr') ? mb_substr($name, 0, 100) : substr($name, 0, 100);

    if ($name === '') {
        fail('give the server a name');
    }

    $rate = (float) str_replace(',', '.', (string) ($_POST['rate'] ?? '1'));
    if ($rate < 0 || $rate > 100) {
        fail('the multiplier must be between 0 and 100');
    }

    $host = trim((string) ($_POST['host_override'] ?? ''));
    if ($host !== '' && !preg_match('~^[A-Za-z0-9.:-]{1,253}$~', $host)) {
        fail('the address may only hold a host name or an IP');
    }

    $groups = implode(',', ovpnGroups($_POST['groups'] ?? []));
    $enabled = !empty($_POST['enabled']) && $_POST['enabled'] !== '0' ? 1 : 0;
    $sort = (int) ($_POST['sort'] ?? 0);
    $now = time();

    if ($id > 0) {
        if (ovpnNode($id) === null) {
            fail('no such server');
        }

        db()->prepare('UPDATE ovpn_node SET name = ?, allowed_groups = ?, rate = ?, enabled = ?, sort = ?, host_override = ?,
                              updated = ? WHERE id = ?')
            ->execute([$name, $groups, $rate, $enabled, $sort, $host, $now, $id]);

        done(['node' => ovpnNodeView(ovpnNode($id))]);
    }

    $key = ovpnNewKey();
    db()->prepare('INSERT INTO ovpn_node (name, keyhash, allowed_groups, rate, enabled, sort, host_override, created, updated)
                   VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)')
        ->execute([$name, hash('sha256', $key), $groups, $rate, $enabled, $sort, $host, $now, $now]);
    $id = (int) db()->lastInsertId();

    // the key is shown this once; only its hash is kept
    done(['node' => ovpnNodeView(ovpnNode($id)), 'key' => $key]);
}

function ovpnAdminNodeKey(): void
{
    requireAdmin();
    requireToken();

    $id = (int) ($_POST['id'] ?? 0);
    if (ovpnNode($id) === null) {
        fail('no such server');
    }

    $key = ovpnNewKey();
    db()->prepare('UPDATE ovpn_node SET keyhash = ?, updated = ? WHERE id = ?')
        ->execute([hash('sha256', $key), time(), $id]);

    done(['id' => $id, 'key' => $key]);
}

function ovpnAdminNodeDelete(): void
{
    requireAdmin();
    requireToken();

    $id = (int) ($_POST['id'] ?? 0);
    if (ovpnNode($id) === null) {
        fail('no such server');
    }

    // trafficlog / traffic_daily keep the rows under the node's name
    db()->prepare('DELETE FROM ovpn_session WHERE nodeid = ?')->execute([$id]);
    db()->prepare('DELETE FROM ovpn_node WHERE id = ?')->execute([$id]);
    db()->prepare('DELETE FROM payg_rate WHERE serverid = ?')->execute([ovpnServerId($id)]);

    done(['id' => $id]);
}

function ovpnAdminSessions(): void
{
    requireAdmin();

    $statement = db()->prepare(
        'SELECT s.nodeid, s.userid, s.ip, s.vip, s.rx, s.tx, s.started, s.seen,
                COALESCE(u.email, \'\') AS email, COALESCE(u.username, \'\') AS username
           FROM ovpn_session s LEFT JOIN user u ON u.id = s.userid
          WHERE s.closed = 0 AND s.seen >= ?
          ORDER BY s.nodeid, s.started DESC
          LIMIT 500');
    $statement->execute([time() - OVPN_STALE]);

    $rows = [];
    foreach ($statement as $row) {
        $rows[] = [
            'node'     => (int) $row['nodeid'],
            'userid'   => (int) $row['userid'],
            'email'    => htmlspecialchars((string) $row['email'], ENT_QUOTES, 'UTF-8'),
            'username' => htmlspecialchars((string) $row['username'], ENT_QUOTES, 'UTF-8'),
            'ip'       => (string) $row['ip'],
            'vip'      => (string) $row['vip'],
            'bytes'    => (float) $row['rx'] + (float) $row['tx'],
            'started'  => (int) $row['started'],
        ];
    }

    done(['sessions' => $rows]);
}

// ---------------------------------------------------------------- dispatch

$ovpnAction = (string) ($_GET['do'] ?? '');

$ovpnNeedsPost = ['ovpn.hello', 'ovpn.auth', 'ovpn.push', 'ovpn.save', 'ovpn.nodesave', 'ovpn.nodekey',
    'ovpn.nodedel'];

if (in_array($ovpnAction, $ovpnNeedsPost, true) && $_SERVER['REQUEST_METHOD'] !== 'POST') {
    fail('this action needs POST', 405);
}

switch ($ovpnAction) {
    case 'ovpn.hello':
        ovpnHello();
    case 'ovpn.auth':
        ovpnAuth();
    case 'ovpn.push':
        ovpnPush();
    case 'ovpn.profile':
        ovpnProfile();
    case 'ovpn.admin':
        ovpnAdminBootstrap();
    case 'ovpn.sessions':
        ovpnAdminSessions();
    case 'ovpn.save':
        ovpnAdminSave();
    case 'ovpn.nodesave':
        ovpnAdminNodeSave();
    case 'ovpn.nodekey':
        ovpnAdminNodeKey();
    case 'ovpn.nodedel':
        ovpnAdminNodeDelete();
}

fail('unknown OpenVPN action');
