<?php
/**
 * WireGuard servers on the same subscription.
 *
 * The same arrangement as OpenVPN (app/Patch/Ovpn.php), and the code that is
 * not about the protocol is literally the same code - see app/Patch/Vpn.php.
 *
 * A WireGuard server runs node/wireguard/wg-agent.py next to its wg-quick
 * interface. Once a minute the agent sends every peer's running byte counters
 * to wg.push; the growth since the last push is added to user.u / user.d
 * (times the node's multiplier, as the panel does for its own servers) and
 * written to trafficlog (raw), so the plan's quota, the wallet billing in
 * PaygJob, the charts and the reports count WireGuard like any other server.
 * The answer carries the peers to add (a customer who has just been given a
 * file) and the peers to remove (plan over, quota used, disabled, moved to
 * another group), and the agent applies them - the same cut-off the OpenVPN and
 * Xray nodes apply.
 *
 *   node, header X-Wg-Node / X-Wg-Key:
 *     wg.hello       the node reports its address, port and public key
 *     wg.push        peer counters; answers the peers to add and to remove
 *   customer, panel session:
 *     wg.profile     the .conf file for one node
 *   admin, panel session (+ patch_csrf token for writes):
 *     wg.admin / wg.sessions                         reports (GET)
 *     wg.save / wg.nodesave / wg.nodekey / wg.nodedel
 *
 * There is no wg.auth: WireGuard has no login. Whether an account may use a
 * node is decided when its .conf file is built, and enforced from then on by
 * the push, exactly as OpenVPN cuts a session whose plan has run out.
 *
 * A customer's keys are derived from the account's uuid and the `wg_secret`
 * setting (see wgPrivateKey(); User::wgPublicKey() must stay identical), so
 * resetting the subscription link in the panel changes the keys too, and
 * nothing secret is stored anywhere. Turning the public key into a WireGuard
 * one needs the sodium extension; without it no file can be built, and both
 * cards say so instead of handing out a file that cannot work.
 *
 * The direct routes (the Iran list and the admin's own destinations) are
 * applied on the server by the agent, from the same lists OpenVPN writes into
 * its customers' files - see vpnBypassNets() in app/Patch/Vpn.php. That is
 * why a .conf file here has no route lines: it works in every client.
 *
 * Nodes are not rows in `servers`, for the same reason as OpenVPN nodes. Their
 * traffic is logged under the virtual server id WG_SERVER_BASE + node id, which
 * PaygJob and the price list know about.
 */

declare(strict_types=1);

require_once __DIR__ . '/Vpn.php';

if (!function_exists('db')) {
    function db(): PDO
    {
        static $pdo = null;
        if ($pdo instanceof PDO) {
            return $pdo;
        }

        $root = dirname(__DIR__, 2);
        $config = $root . '/config/config.php';
        if (!is_file($config)) {
            throw new RuntimeException('config/config.php not found');
        }

        require $config;
        if (!isset($DB) || !is_array($DB)) {
            throw new RuntimeException('database configuration not readable');
        }

        $dsn = sprintf('mysql:host=%s;dbname=%s;charset=utf8mb4',
            $DB['db_host'] ?? 'localhost', $DB['db_database'] ?? '');

        if (!empty($DB['db_socket'])) {
            $dsn = sprintf('mysql:unix_socket=%s;dbname=%s;charset=utf8mb4',
                $DB['db_socket'], $DB['db_database'] ?? '');
        }

        $pdo = new PDO($dsn, $DB['db_username'] ?? '', $DB['db_password'] ?? '', [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        ]);

        return $pdo;
    }
}

const WG_SERVER_BASE = 950000;
/* a peer not pushed for this long has gone; a node silent this long is down */
const WG_STALE = 180;
const WG_PUSH_INTERVAL = 60;

/* the ports a server may listen on, in the order an admin should try them */
const WG_PREFERRED_PORTS = [443, 51820, 2053, 2083, 8443, 1194, 4500];
/* the customer file says AllowedIPs = 0.0.0.0/0; ::/0 needs an IPv6 subnet */
const WG_MTU_DEFAULT = 1420;

/* ------------------------------------------------------------------ keys */

/**
 * The private key of an account: 32 bytes, clamped the way X25519 requires
 * and base64-encoded as WireGuard writes it. Derived, never stored - see the
 * header for why.
 */
function wgPrivateKey(int $userId, string $uuid, int $deviceId = 1): string
{
    $secret = vpnSetting('wg_secret', '');

    if ($secret === '' || trim($uuid) === '') {
        return '';
    }

    $suffix = $deviceId > 1 ? ':' . $deviceId : '';
    $raw = hash_hmac('sha256', 'key:' . $userId . ':' . strtolower(trim($uuid)) . $suffix, $secret, true);

    return sodium_bin2base64(wgClampScalar($raw), SODIUM_BASE64_VARIANT_ORIGINAL);
}

/**
 * The scalar as `wg genkey` would have produced it: clamped, so the three low
 * bits of the first byte and the high two of the last are forced. Clamping here
 * rather than leaning on sodium's own copy of it, so the key is the same one on
 * every build of PHP.
 */
function wgClampScalar(string $raw): string
{
    $key = $raw;
    $key[0] = chr(ord($key[0]) & 248);
    $key[31] = chr((ord($key[31]) & 127) | 64);

    return $key;
}

/**
 * The second layer of the handshake, which hides which peer a packet came from
 * and is independent of the key pair. Also derived.
 */
function wgPresharedKey(int $userId, string $uuid): string
{
    $secret = vpnSetting('wg_secret', '');

    if ($secret === '' || trim($uuid) === '') {
        return '';
    }

    $raw = hash_hmac('sha256', 'psk:' . $userId . ':' . strtolower(trim($uuid)), $secret, true);

    return base64_encode($raw);
}

/**
 * The account's public key, derived from its private one and kept in
 * wg_credential so the agent's peers can be matched by an indexed lookup.
 * '' when sodium is missing, the secret is unset, or the row cannot be read.
 */
function wgPublicKey(int $userId, string $uuid, int $deviceId = 1): string
{
    static $cache = [];
    $cacheKey = $userId . ':' . $deviceId;

    if (isset($cache[$cacheKey])) {
        return $cache[$cacheKey];
    }

    $cache[$cacheKey] = '';

    try {
        $statement = db()->prepare('SELECT pubkey FROM wg_credential WHERE userid = ? AND device_id = ? LIMIT 1');
        $statement->execute([$userId, $deviceId]);
        $known = $statement->fetch();
    } catch (Throwable $error) {
        return '';
    }

    if ($known !== false && trim((string) $known['pubkey']) !== '') {
        return $cache[$cacheKey] = trim((string) $known['pubkey']);
    }

    $private = wgPrivateKey($userId, $uuid, $deviceId);

    if ($private === '') {
        return '';
    }

    $key = sodium_bin2base64(
        sodium_crypto_box_publickey_from_secretkey(sodium_base642bin($private, SODIUM_BASE64_VARIANT_ORIGINAL)), SODIUM_BASE64_VARIANT_ORIGINAL);

    try {
        $devName = $deviceId === 1 ? 'دستگاه اصلی' : ('دستگاه ' . $deviceId);
        db()->prepare('INSERT INTO wg_credential (userid, device_id, name, pubkey, updated) VALUES (?, ?, ?, ?, ?)
                       ON DUPLICATE KEY UPDATE pubkey = VALUES(pubkey), updated = VALUES(updated)')
            ->execute([$userId, $deviceId, $devName, $key, time()]);
    } catch (Throwable $error) {
        // the key is still good for this request; it is written next time
    }

    return $cache[$cacheKey] = $key;
}

/** The account behind a peer's public key, or 0. */
function wgUserIdFromKey(string $pubkey): int
{
    $key = trim($pubkey);

    if (!preg_match('~^[A-Za-z0-9+/]{43}=$~', $key)) {
        return 0;
    }

    try {
        $statement = db()->prepare('SELECT userid FROM wg_credential WHERE pubkey = ? LIMIT 1');
        $statement->execute([$key]);
        $row = $statement->fetch();
    } catch (Throwable $error) {
        return 0;
    }

    return $row === false ? 0 : (int) $row['userid'];
}

/**
 * The panel can derive a customer's keys only with the sodium extension.
 * Every file path checks this first, so a missing extension costs the admin
 * one clear line rather than a customer a file that will not connect.
 */
function wgSodiumOk(): bool
{
    static $ok = null;

    if ($ok === null) {
        $ok = function_exists('sodium_crypto_box_secretkey')
            && function_exists('sodium_crypto_box_publickey_from_secretkey')
            && function_exists('sodium_base642bin')
            && function_exists('sodium_bin2base64');
    }

    return $ok;
}

// ------------------------------------------------------------------ helpers

function wgSetting(string $name, string $fallback): string
{
    return vpnSetting($name, $fallback);
}

function wgEnabled(): bool
{
    return wgSetting('wg_enabled', '0') === '1';
}

function wgServerId(int $nodeId): int
{
    return WG_SERVER_BASE + $nodeId;
}

function wgServerName(string $name): string
{
    return 'WireGuard · ' . $name;
}

/** "443, 51820" -> [443, 51820]: at most $max, in the order given, each once. */
function wgPortList($value, int $max = 8): array
{
    $ports = [];

    foreach (preg_split('~[\s,،]+~u', (string) $value) ?: [] as $item) {
        if ($item === '') {
            continue;
        }
        if (!preg_match('~^[0-9]{1,5}$~', $item) || (int) $item < 1 || (int) $item > 65535) {
            return [];
        }
        $ports[(int) $item] = (int) $item;
    }

    return array_slice(array_values($ports), 0, $max);
}

/** A base64 public key: 32 bytes, which is what every one of them is. */
function wgKeyOk(string $key): bool
{
    return (bool) preg_match('~^[A-Za-z0-9+/]{43}=$~', $key);
}

/** "1.1.1.1, 8.8.8.8" -> ['1.1.1.1', '8.8.8.8']: valid IPv4 addresses, at most two. */
function wgDnsList($value): array
{
    $list = [];

    foreach (preg_split('~[\s,،]+~u', (string) $value) ?: [] as $item) {
        $item = trim($item);
        if ($item !== '' && filter_var($item, FILTER_VALIDATE_IP, FILTER_FLAG_IPV4) !== false) {
            $list[$item] = $item;
        }
    }

    return array_slice(array_values($list), 0, 2);
}

/**
 * The address a customer's peer gets on this node: a /32 out of a /16 of the
 * node's own (node 1 is 10.1, node 2 is 10.2, so 65 000 customers a node), so
 * two nodes never hand the same address to the same customer.
 *
 * The host part starts from the first four bytes of sha256 of the public key in
 * base64 text - the text, not the decoded key, because that is what PHP's
 * hash() and Python's hashlib both hash the same way. But two accounts whose
 * keys hash alike would then share an address and their traffic would be
 * indistinguishable, so the value that is taken is written to wg_credential
 * under a UNIQUE (nodeid, address) and a clash moves on to the next address.
 * The peer already on the interface keeps the address it has.
 *
 * Keep in step with address_for() in node/wireguard/wg-agent.py, which reads
 * the address off the interface rather than deriving it, so it needs none of
 * this.
 */
function wgPeerAddress(array $node, string $pubkey, int $userId = 0): string
{
    $nodeId = max(0, (int) $node['id']);

    if ($userId > 0) {
        $reserved = wgReservedAddress($userId, $nodeId, $pubkey);

        if ($reserved !== null) {
            return $reserved;
        }
    }

    return wgAddressFor($nodeId, $pubkey);
}

/**
 * The start of the range, before any collision is ruled out. $step moves on one
 * address at a time, wrapping inside the node's /16.
 */
function wgAddressFor(int $nodeId, string $pubkey, int $step = 0): string
{
    $hash = unpack('N', substr(hash('sha256', $pubkey, true), 0, 4));
    $start = ($hash === false ? 0 : $hash[1] % 65534) + 1;

    // 65521 is prime and one under the 65 534 usable addresses, so step * n
    // visits a different address every time and comes back only after a full
    // cycle: a customer whose address is taken lands on a free one rather
    // than walking into the occupied run next to it
    $host = ((($start - 1) + $step * 65521) % 65534) + 1;

    return '10.' . $nodeId . '.' . intdiv($host, 256) . '.' . ($host % 256);
}

/**
 * The address this account already holds on this node, claiming one if it has
 * none. Null when the table cannot be read, which leaves the caller with the
 * derived address rather than failing a download over it.
 */
function wgReservedAddress(int $userId, int $nodeId, string $pubkey): ?string
{
    try {
        $find = db()->prepare('SELECT address FROM wg_credential WHERE userid = ? AND nodeid = ? AND pubkey = ? LIMIT 1');
        $find->execute([$userId, $nodeId, $pubkey]);
        $have = $find->fetch();

        if ($have !== false && $have['address'] !== null && $have['address'] !== '') {
            return (string) $have['address'];
        }
    } catch (Throwable $error) {
        return null;
    }

    // step by a prime, not by one: the sequence visits every address in the
    // node's /16 before repeating, so a customer whose address is taken lands
    // on a free one instead of walking into the occupied run beside it
    for ($step = 0; $step < 512; $step++) {
        $address = wgAddressFor($nodeId, $pubkey, $step);

        try {
            $claim = db()->prepare('UPDATE wg_credential SET nodeid = ?, address = ?, updated = ?
                                    WHERE userid = ? AND pubkey = ?
                                    LIMIT 1');
            $claim->execute([$nodeId, $address, time(), $userId, $pubkey]);
        } catch (Throwable $error) {
            continue;
        }

        $check = db()->prepare('SELECT userid, pubkey FROM wg_credential WHERE nodeid = ? AND address = ? LIMIT 1');
        $check->execute([$nodeId, $address]);
        $holder = $check->fetch();

        if ($holder !== false && (int) $holder['userid'] === $userId && trim((string)$holder['pubkey']) === $pubkey) {
            return $address;
        }
    }

    return wgAddressFor($nodeId, $pubkey);
}

// -------------------------------------------------------------------- nodes

function wgNode(int $id): ?array
{
    $statement = db()->prepare('SELECT * FROM wg_node WHERE id = ? LIMIT 1');
    $statement->execute([$id]);
    $row = $statement->fetch();

    return $row === false ? null : $row;
}

/** The calling WireGuard server, by the key it was given when it was added. */
function wgRequireNode(): array
{
    $id = (int) ($_SERVER['HTTP_X_WG_NODE'] ?? 0);
    $key = (string) ($_SERVER['HTTP_X_WG_KEY'] ?? '');

    if ($id <= 0 || strlen($key) < 32) {
        fail('node credentials missing', 403);
    }

    $node = wgNode($id);

    if ($node === null || !hash_equals((string) $node['keyhash'], hash('sha256', $key))) {
        fail('unknown node or wrong key', 403);
    }

    return $node;
}

/** The address customers connect to, unless the admin named another one. */
function wgNodeHost(array $node): string
{
    $override = trim((string) ($node['host_override'] ?? ''));

    return $override !== '' ? $override : trim((string) $node['host']);
}

/** The port customers connect to. One port: WireGuard has a single socket. */
function wgNodePort(array $node): int
{
    $port = (int) $node['listen_port'];

    return $port >= 1 && $port <= 65535 ? $port : 51820;
}

/** A node silent for WG_STALE has gone down, agent or not. */
function wgNodeLive(array $node): bool
{
    return (int) $node['heartbeat'] > time() - WG_STALE;
}

/** A node a customer can be given a file for. */
function wgNodeUsable(array $node): bool
{
    return (int) $node['enabled'] === 1 && wgNodeHost($node) !== ''
        && wgKeyOk((string) $node['pubkey']) && wgNodeLive($node);
}

/**
 * Why this account may not use this node right now, or '' when it may.
 * '' for a node the account may not have (the file endpoint checks that
 * separately) - this only covers the account itself.
 */
function wgRefusal(?array $user, array $node): string
{
    return vpnRefusal($user, $node, wgEnabled() ? '1' : '0');
}

// ------------------------------------------------------------- node actions

function wgHello(): void
{
    $node = wgRequireNode();
    $body = vpnJsonBody();

    $host = trim((string) ($body['host'] ?? ''));
    if ($host !== '' && !preg_match('~^[A-Za-z0-9.:-]{1,253}$~', $host)) {
        fail('bad host');
    }

    $port = (int) ($body['port'] ?? 0);
    if ($port < 1 || $port > 65535) {
        fail('bad port');
    }

    $pubkey = trim((string) ($body['pubkey'] ?? ''));
    if (!wgKeyOk($pubkey)) {
        fail('bad public key');
    }

    $version = substr(preg_replace('~[^A-Za-z0-9._-]~', '', (string) ($body['version'] ?? '')), 0, 32);
    $dns = implode(', ', wgDnsList($body['dns'] ?? ''));
    $mtu = (int) ($body['mtu'] ?? WG_MTU_DEFAULT);
    $mtu = $mtu >= 1280 && $mtu <= 1500 ? $mtu : WG_MTU_DEFAULT;

    db()->prepare('UPDATE wg_node SET host = ?, listen_port = ?, pubkey = ?, agent_version = ?, dns = ?,
                          mtu = IF(mtu >= 1280 AND mtu <= 1500, mtu, ?),
                          heartbeat = IF(heartbeat = 0, ?, heartbeat), updated = ? WHERE id = ?')
        ->execute([$host, $port, $pubkey, $version, $dns, $mtu, time(), time(), (int) $node['id']]);

    done(['node' => (int) $node['id'], 'name' => (string) $node['name'], 'interval' => WG_PUSH_INTERVAL]);
}

function wgPush(): void
{
    vpnTimezone();
    $node = wgRequireNode();
    $body = vpnJsonBody();
    $pdo = db();
    $now = time();
    $nodeId = (int) $node['id'];
    $rate = max(0.0, (float) $node['rate']);
    $serverId = wgServerId($nodeId);
    $serverName = wgServerName((string) $node['name']);

    $reports = [];
    foreach (['peers' => false, 'closed' => true] as $key => $closed) {
        foreach (is_array($body[$key] ?? null) ? $body[$key] : [] as $item) {
            if (!is_array($item)) {
                continue;
            }
            $pubkey = trim((string) ($item['pubkey'] ?? ''));
            if (!wgKeyOk($pubkey)) {
                continue;
            }
            $reports[] = [
                'pubkey' => $pubkey,
                'userid' => wgUserIdFromKey($pubkey),
                'ip'     => substr(trim((string) ($item['ip'] ?? '')), 0, 64),
                'endpoint' => substr(trim((string) ($item['endpoint'] ?? '')), 0, 64),
                'rx'     => max(0, (int) ($item['rx'] ?? 0)),
                'tx'     => max(0, (int) ($item['tx'] ?? 0)),
                'closed' => $closed,
            ];
        }
    }

    $usage = [];   // user id => [upload, download] in raw bytes
    $live = [];    // pubkey => user id, peers still connected
    $remove = [];  // pubkey => reason, peers to remove from interface

    $pdo->beginTransaction();

    try {
        $find = $pdo->prepare('SELECT id, userid, rx, tx, closed FROM wg_session WHERE nodeid = ? AND pubkey = ? FOR UPDATE');
        $create = $pdo->prepare('INSERT INTO wg_session (nodeid, pubkey, userid, ip, endpoint, rx, tx, started, seen, closed)
                                 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)');
        $update = $pdo->prepare('UPDATE wg_session SET rx = ?, tx = ?, ip = ?, endpoint = ?, seen = ?, closed = ?
                                 WHERE id = ?');

        foreach ($reports as $report) {
            if ($report['userid'] <= 0) {
                if (!$report['closed']) {
                    $remove[] = ['pubkey' => $report['pubkey'], 'reason' => 'device deleted or not registered'];
                }
                continue; // a peer nobody in the panel owns
            }

            $find->execute([$nodeId, $report['pubkey']]);
            $row = $find->fetch();
            $closedAt = $report['closed'] ? $now : 0;
            // a peer belongs to the account it was made for
            $owner = $row === false ? $report['userid'] : (int) $row['userid'];

            if ($row === false) {
                // counters start at zero when a peer connects
                $up = $report['rx'];
                $down = $report['tx'];
                $create->execute([$nodeId, $report['pubkey'], $report['userid'], $report['ip'], $report['endpoint'],
                    $report['rx'], $report['tx'], $now, $now, $closedAt]);
            } else {
                // running totals: only the growth counts, so a resent push - or a
                // repeated "closed" report - adds nothing; a peer marked closed
                // for silence and reported again is simply open again
                $up = max(0, $report['rx'] - (int) $row['rx']);
                $down = max(0, $report['tx'] - (int) $row['tx']);
                $update->execute([max($report['rx'], (int) $row['rx']), max($report['tx'], (int) $row['tx']),
                    $report['ip'], $report['endpoint'], $now, $closedAt, (int) $row['id']]);
            }

            if ($up + $down > 0) {
                $usage[$owner][0] = ($usage[$owner][0] ?? 0) + $up;
                $usage[$owner][1] = ($usage[$owner][1] ?? 0) + $down;
            }

            if (!$report['closed']) {
                $live[$report['pubkey']] = $owner;
            }
        }

        $total = vpnHasColumn('user', 'total_data_used');
        $touch = vpnHasColumn('user', 't');
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
            vpnInsert('trafficlog', [
                'userid'     => $userId,
                'serverid'   => $serverId,
                'servername' => $serverName,
                'u'          => $up,
                'd'          => $down,
                'total'      => $up + $down,
                'rate'       => $rate,
                'traffic'    => vpnBytesText((float) ($up + $down)),
                'datetime'   => $now,
            ]);
        }

        $pdo->commit();
    } catch (Throwable $error) {
        $pdo->rollBack();
        error_log('wg.push: ' . $error->getMessage());
        // only the node sees this; it lands in its log, where the admin looks
        fail('push not stored: ' . substr($error->getMessage(), 0, 300));
    }

    // who is online, for the device limit and the dashboard's "connected" mark
    $seenIp = [];
    foreach ($reports as $report) {
        if (!$report['closed'] && $report['userid'] > 0 && $report['ip'] !== ''
            && !isset($seenIp[$report['userid'] . '|' . $report['ip']])) {
            $seenIp[$report['userid'] . '|' . $report['ip']] = true;
            try {
                vpnInsert('online_ip', [
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

    // peers whose account may not connect any more, and ones to hand out
    $verdicts = [];
    foreach ($live as $pubkey => $userId) {
        if (!array_key_exists($userId, $verdicts)) {
            $verdicts[$userId] = wgRefusal(vpnUser($userId), $node);
        }
        if ($verdicts[$userId] !== '') {
            $remove[] = ['pubkey' => $pubkey, 'reason' => $verdicts[$userId]];
        }
    }

    $add = [];
    if (wgEnabled()) {
        foreach (wgPendingPeers($node) as $pubkey => $userId) {
            if (!isset($live[$pubkey])) {
                // the address the customer's file already carries: the agent is
                // told it rather than deriving it, so the two can never differ
                $user = vpnUser($userId);
                $psk = ($user !== null) ? wgPresharedKey($userId, (string) ($user['uuid'] ?? '')) : '';
                $add[] = [
                    'pubkey'  => $pubkey,
                    'userid'  => $userId,
                    'address' => wgPeerAddress($node, $pubkey, $userId),
                    'psk'     => $psk,
                ];
            }
        }
    }

    $pdo->prepare('UPDATE wg_node SET heartbeat = ?, online = ?, updated = ? WHERE id = ?')
        ->execute([$now, count($live), $now, $nodeId]);

    // a peer the agent stopped reporting (agent or WireGuard restarted) is over
    $pdo->prepare('UPDATE wg_session SET closed = ? WHERE nodeid = ? AND closed = 0 AND seen < ?')
        ->execute([$now, $nodeId, $now - WG_STALE]);
    $pdo->prepare('DELETE FROM wg_session WHERE nodeid = ? AND closed > 0 AND closed < ?')
        ->execute([$nodeId, $now - 86400]);

    done([
        'add'      => $add,
        'remove'   => $remove,
        'interval' => WG_PUSH_INTERVAL,
        'enabled'  => (int) $node['enabled'] === 1,
        // the direct-route list, so the agent can refresh its ipset
        'bypass'   => vpnBypassCidrs(),
    ]);
}

/**
 * The accounts that may use this node but have no peer on it yet, as
 * pubkey => user id. A customer whose file has just been built is on this
 * list until the agent has it; after that they are in wg_session.
 */
function wgPendingPeers(array $node): array
{
    try {
        // only accounts whose address is reserved on this node: a key derived
        // for one node's file says nothing about another node's, and adding a
        // peer that has no file would hold an address nobody can use
        //
        // ORDER BY userid with the LIMIT, so the cut-off falls on the same
        // 500 every minute rather than moving and leaving the rest of the
        // accounts waiting forever
        $statement = db()->prepare(
            'SELECT c.userid, c.pubkey FROM wg_credential c
              WHERE c.pubkey <> \'\'
              ORDER BY c.userid
              LIMIT 500');
        $statement->execute();
    } catch (Throwable $error) {
        return [];
    }

    $out = [];
    $verdicts = [];

    foreach ($statement as $row) {
        $userId = (int) $row['userid'];
        if (!array_key_exists($userId, $verdicts)) {
            $verdicts[$userId] = wgRefusal(vpnUser($userId), $node);
        }
        if ($verdicts[$userId] === '') {
            $out[trim((string) $row['pubkey'])] = $userId;
        }
    }

    return $out;
}

// --------------------------------------------------------- customer actions

/**
 * The .conf file. One peer per file: AllowedIPs is always 0.0.0.0/0, because
 * the direct routes are applied on the server (the agent's ipset), which is
 * what makes this file work in a client that has no routing rules of its own.
 */
function wgProfileText(array $node, array $user, int $deviceId = 1): string
{
    $pubkey = wgPublicKey((int) $user['id'], (string) ($user['uuid'] ?? ''), $deviceId);

    if ($pubkey === '') {
        fail('this server cannot make a file for your account');
    }

    $lines = [
        '# ' . preg_replace('~[\r\n]+~', ' ', (string) $node['name']),
        '[Interface]',
        'PrivateKey = ' . wgPrivateKey((int) $user['id'], (string) ($user['uuid'] ?? ''), $deviceId),
        'Address = ' . wgPeerAddress($node, $pubkey, (int) $user['id']) . '/32',
        'Jc = 4',
        'Jmin = 40',
        'Jmax = 70',
        'S1 = 0',
        'S2 = 0',
        'H1 = 1',
        'H2 = 2',
        'H3 = 3',
        'H4 = 4',
    ];

    $dns = wgDnsList($node['dns'] ?? '');
    if ($dns !== []) {
        $lines[] = 'DNS = ' . implode(', ', $dns);
    }
    $mtu = (int) $node['mtu'];
    $lines[] = 'MTU = ' . ($mtu >= 1280 && $mtu <= 1500 ? $mtu : WG_MTU_DEFAULT);

    return implode("\n", array_merge($lines, [
        '',
        '[Peer]',
        'PublicKey = ' . trim((string) $node['pubkey']),
        // a second layer of the handshake, so a reader of the server's config
        // cannot tell which customer a packet belongs to
        'PresharedKey = ' . wgPresharedKey((int) $user['id'], (string) ($user['uuid'] ?? '')),
        'Endpoint = ' . wgNodeHost($node) . ':' . wgNodePort($node),
        'AllowedIPs = 0.0.0.0/0, ::/0',
        'PersistentKeepalive = 25',
    ])) . "\n";
}

function wgProfile(): void
{
    $user = vpnRequireUser();
    $node = wgNode((int) ($_GET['node'] ?? 0));

    if (!wgSodiumOk()) {
        fail('this server cannot make WireGuard files: the panel is missing the sodium extension');
    }

    // staff may fetch any ready server's file, to test it before switching on
    $staff = (int) ($user['role'] ?? 0) > 0;

    if ($node === null || !wgNodeUsable($node)
        || (!$staff && (!wgEnabled() || !vpnNodeServes($node, $user)))) {
        fail('this server is not available for your account');
    }

    $reason = $staff ? '' : wgRefusal($user, $node);

    if ($reason !== '' && !in_array($reason, ['group'], true)) {
        $messages = [
            'disabled' => 'your account is disabled',
            'expired'  => 'your subscription has ended',
            'quota'    => 'no data left on your subscription',
            'iplimit'  => 'device limit reached',
            'off'      => 'this server is switched off',
            'node'     => 'this server is switched off',
        ];
        fail($messages[$reason] ?? 'this server is not available for your account');
    }

    $deviceId = max(1, (int) ($_GET['device'] ?? 1));
    $slug = strtolower(trim(preg_replace('~[^A-Za-z0-9]+~', '-', (string) $node['name']), '-'));
    $devSuffix = '';
    if ($deviceId > 1) {
        $devName = 'device-' . $deviceId;
        try {
            $stmt = db()->prepare('SELECT name FROM wg_credential WHERE userid = ? AND device_id = ? LIMIT 1');
            $stmt->execute([(int) $user['id'], $deviceId]);
            $row = $stmt->fetch();
            if ($row && !empty($row['name'])) {
                $devName = strtolower(trim(preg_replace('~[^A-Za-z0-9]+~', '-', (string) $row['name']), '-')) ?: ('device-' . $deviceId);
            }
        } catch (Throwable $e) {}
        $devSuffix = '-' . $devName;
    }
    $file = 'digitsell-' . ($slug !== '' ? $slug : 'server-' . (int) $node['id']) . $devSuffix . '.conf';

    header('Content-Type: application/octet-stream');
    header('Content-Disposition: attachment; filename="' . $file . '"');
    header('Cache-Control: no-store, private');
    echo wgProfileText($node, $user, $deviceId);
    exit;
}

// ------------------------------------------------------------ admin actions

function wgAdminToken(): string
{
    if (empty($_SESSION['patch_csrf'])) {
        $_SESSION['patch_csrf'] = bin2hex(random_bytes(24));
    }

    return (string) $_SESSION['patch_csrf'];
}

/** The domain status for the admin: wanted domain, where it points, and whether that is the server. */
function wgDomainView(array $node): ?array
{
    $domain = vpnDomainName((string) ($node['host_override'] ?? ''));
    if ($domain === '') {
        return null;
    }

    $serverIp = trim((string) $node['host']);
    $points = @gethostbynamel($domain) ?: [];
    sort($points);

    return [
        'name'      => $domain,
        'points'    => $points,
        'points_ok' => filter_var($serverIp, FILTER_VALIDATE_IP) ? in_array($serverIp, $points, true) : null,
        'server_ip' => filter_var($serverIp, FILTER_VALIDATE_IP) ? $serverIp : '',
    ];
}

function wgNodeView(array $node): array
{
    return [
        'id'            => (int) $node['id'],
        'name'          => (string) $node['name'],
        'groups'        => vpnGroups($node['allowed_groups']),
        'rate'          => (float) $node['rate'],
        'enabled'       => (int) $node['enabled'] === 1,
        'sort'          => (int) $node['sort'],
        'host'          => (string) $node['host'],
        'host_override' => (string) $node['host_override'],
        'domain'        => wgDomainView($node),
        'port'          => wgNodePort($node),
        'listen_port'   => (int) $node['listen_port'],
        'pubkey'        => (string) $node['pubkey'],
        'dns'           => (string) $node['dns'],
        'mtu'           => (int) $node['mtu'],
        'ready'         => wgNodeUsable($node),
        'live'          => wgNodeLive($node),
        'heartbeat'     => (int) $node['heartbeat'],
        'online'        => wgNodeLive($node) ? (int) $node['online'] : 0,
        'version'       => (string) $node['agent_version'],
        'serverid'      => wgServerId((int) $node['id']),
    ];
}

function wgAdminBootstrap(): void
{
    requireAdmin();

    $nodes = [];
    foreach (db()->query('SELECT * FROM wg_node ORDER BY sort, id') as $row) {
        $nodes[] = wgNodeView($row);
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
    $usage->execute([WG_SERVER_BASE, $today]);
    $todayBytes = [];
    foreach ($usage as $row) {
        $todayBytes[(int) $row['serverid']] = (float) $row['bytes'];
    }
    foreach ($nodes as &$node) {
        $node['today_bytes'] = $todayBytes[$node['serverid']] ?? 0.0;
    }
    unset($node);

    done([
        'token'   => wgAdminToken(),
        'enabled' => wgEnabled(),
        'notify'  => wgSetting('wg_notify', '1') === '1',
        // without this the panel cannot derive a customer's public key, and no
        // .conf file can be built at all
        'sodium'  => wgSodiumOk(),
        'nodes'   => $nodes,
        'groups'  => $groups,
        // when WgJob last ran; 0 means the scheduler never started it
        'job_last' => (int) wgSetting('wg_job_last', '0'),
        'now'      => time(),
        'bypass'   => vpnBypassView(),
        'repo'    => repo(),
        'branch'  => branch(),
    ]);
}

function wgAdminSave(): void
{
    requireAdmin();
    requireToken();

    putSetting('wg_enabled', !empty($_POST['enabled']) && $_POST['enabled'] !== '0' ? '1' : '0');

    // online / offline messages to the admin on Telegram (app/Jobs/WgJob.php)
    if (isset($_POST['notify'])) {
        putSetting('wg_notify', $_POST['notify'] !== '0' ? '1' : '0');
    }

    done(['enabled' => wgEnabled(), 'notify' => wgSetting('wg_notify', '1') === '1']);
}

function wgAdminNodeSave(): void
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

    // WireGuard has one socket, so the port the customers use is the port the
    // server listens on. A server cannot answer on a second one.
    $portText = trim((string) ($_POST['port'] ?? ''));
    $port = $portText === '' ? 0 : (int) $portText;
    if ($portText !== '' && ($port < 1 || $port > 65535)) {
        fail('the port must be a number from 1 to 65535');
    }

    $groups = implode(',', vpnGroups($_POST['groups'] ?? []));
    $enabled = !empty($_POST['enabled']) && $_POST['enabled'] !== '0' ? 1 : 0;
    $sort = (int) ($_POST['sort'] ?? 0);
    $mtuText = trim((string) ($_POST['mtu'] ?? ''));
    $mtu = (int) $mtuText;
    if ($mtu < 1280 || $mtu > 1500) {
        $mtu = WG_MTU_DEFAULT;
    }
    $now = time();

    if ($id > 0) {
        if (wgNode($id) === null) {
            fail('no such server');
        }

        if ($port > 0) {
            // what the server said about itself decides which port can work
            $live = (int) db()->query('SELECT listen_port FROM wg_node WHERE id = ' . $id)->fetch()['listen_port'];
            if ($live > 0 && $port !== $live) {
                fail('this server listens on port ' . $live
                    . ' - run the install command again to change the port');
            }
        }

        db()->prepare('UPDATE wg_node SET name = ?, allowed_groups = ?, rate = ?, enabled = ?, sort = ?,
                              host_override = ?, mtu = ?, updated = ? WHERE id = ?')
            ->execute([$name, $groups, $rate, $enabled, $sort, $host, $mtu, $now, $id]);

        done(['node' => wgNodeView(wgNode($id))]);
    }

    $key = vpnNewKey();
    db()->prepare('INSERT INTO wg_node (name, keyhash, allowed_groups, rate, enabled, sort, host_override, mtu,
                                          created, updated)
                   VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)')
        ->execute([$name, hash('sha256', $key), $groups, $rate, $enabled, $sort, $host, $mtu, $now, $now]);
    $id = (int) db()->lastInsertId();

    // the key is shown this once; only its hash is kept
    done(['node' => wgNodeView(wgNode($id)), 'key' => $key]);
}

function wgAdminNodeKey(): void
{
    requireAdmin();
    requireToken();

    $id = (int) ($_POST['id'] ?? 0);
    if (wgNode($id) === null) {
        fail('no such server');
    }

    $key = vpnNewKey();
    db()->prepare('UPDATE wg_node SET keyhash = ?, updated = ? WHERE id = ?')
        ->execute([hash('sha256', $key), time(), $id]);

    done(['id' => $id, 'key' => $key]);
}

function wgAdminNodeDelete(): void
{
    requireAdmin();
    requireToken();

    $id = (int) ($_POST['id'] ?? 0);
    if (wgNode($id) === null) {
        fail('no such server');
    }

    // trafficlog / traffic_daily keep the rows under the node's name
    db()->prepare('DELETE FROM wg_session WHERE nodeid = ?')->execute([$id]);
    db()->prepare('DELETE FROM wg_node WHERE id = ?')->execute([$id]);
    db()->prepare('DELETE FROM payg_rate WHERE serverid = ?')->execute([wgServerId($id)]);

    done(['id' => $id]);
}

function wgAdminSessions(): void
{
    requireAdmin();

    $statement = db()->prepare(
        'SELECT s.nodeid, s.userid, s.ip, s.endpoint, s.rx, s.tx, s.started,
                COALESCE(u.email, \'\') AS email, COALESCE(u.username, \'\') AS username
           FROM wg_session s LEFT JOIN user u ON u.id = s.userid
          WHERE s.closed = 0 AND s.seen >= ?
          ORDER BY s.nodeid, s.started DESC
          LIMIT 500');
    $statement->execute([time() - WG_STALE]);

    $rows = [];
    foreach ($statement as $row) {
        $rows[] = [
            'node'     => (int) $row['nodeid'],
            'userid'   => (int) $row['userid'],
            'email'    => htmlspecialchars((string) $row['email'], ENT_QUOTES, 'UTF-8'),
            'username' => htmlspecialchars((string) $row['username'], ENT_QUOTES, 'UTF-8'),
            'ip'       => (string) $row['ip'],
            'endpoint' => (string) $row['endpoint'],
            'bytes'    => (float) $row['rx'] + (float) $row['tx'],
            'started'  => (int) $row['started'],
        ];
    }

    done(['sessions' => $rows]);
}

function wgAdminNotifyTest(): void
{
    vpnNotifyTest('WireGuard');
}


function wgAdminBypassSave(): void
{
    vpnBypassSave();
}

function wgAdminIranRefresh(): void
{
    vpnIranRefresh();
}


function wgUserDevices(int $userId, string $uuid): array
{
    try {
        $stmt = db()->prepare('SELECT device_id, name, pubkey, updated FROM wg_credential WHERE userid = ? ORDER BY device_id ASC');
        $stmt->execute([$userId]);
        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
    } catch (Throwable $e) {
        $rows = [];
    }

    if (empty($rows)) {
        $pk = wgPublicKey($userId, $uuid, 1);
        return [
            ['id' => 1, 'name' => 'دستگاه اصلی', 'pubkey' => $pk]
        ];
    }

    $devices = [];
    foreach ($rows as $r) {
        $devices[] = [
            'id' => (int) ($r['device_id'] ?? 1),
            'name' => (string) ($r['name'] ?? ('دستگاه ' . ($r['device_id'] ?? 1))),
            'pubkey' => (string) ($r['pubkey'] ?? ''),
        ];
    }

    return $devices;
}

function wgUserLimit(array $user): int
{
    $userId = (int) ($user['id'] ?? 0);
    $limit = (int) ($user['iplimit'] ?? 0);
    $pkgId = (int) ($user['packageid'] ?? 0);

    if ($pkgId > 0) {
        try {
            $stmt = db()->prepare('SELECT iplimit FROM package WHERE id = ? LIMIT 1');
            $stmt->execute([$pkgId]);
            $row = $stmt->fetch();
            if ($row && isset($row['iplimit'])) {
                $pkgLimit = (int) $row['iplimit'];
                if ($pkgLimit > 0) {
                    $limit = max($limit, $pkgLimit);
                }
            }
        } catch (Throwable $e) {}
    }

    if ($limit <= 0 && $userId > 0) {
        try {
            $stmt = db()->prepare('SELECT packageid FROM orders WHERE userid = ? AND status = 1 ORDER BY id DESC LIMIT 1');
            $stmt->execute([$userId]);
            $row = $stmt->fetch();
            if ($row && !empty($row['packageid'])) {
                $stmt2 = db()->prepare('SELECT iplimit FROM package WHERE id = ? LIMIT 1');
                $stmt2->execute([(int) $row['packageid']]);
                $row2 = $stmt2->fetch();
                if ($row2 && isset($row2['iplimit'])) {
                    $pkgLimit = (int) $row2['iplimit'];
                    if ($pkgLimit > 0) {
                        $limit = max($limit, $pkgLimit);
                    }
                }
            }
        } catch (Throwable $e) {}
    }

    return max(1, $limit);
}

function wgRequireCustomer(): array
{
    startPanelSession();

    $login = $_SESSION['login_session'] ?? null;
    $uid = 0;

    if (is_array($login) && !empty($login['uid'])) {
        if (!empty($login['expire']) && (int) $login['expire'] < time()) {
            fail('نشست کاربری شما منقضی شده است. لطفاً مجدداً وارد شوید.', 401);
        }
        $uid = (int) $login['uid'];
    } elseif (!empty($_SESSION['uid'])) {
        $uid = (int) $_SESSION['uid'];
    } elseif (!empty($_SESSION['user_id'])) {
        $uid = (int) $_SESSION['user_id'];
    }

    if ($uid <= 0) {
        fail('ابتدا وارد حساب کاربری خود شوید', 401);
    }

    $user = vpnUser($uid);
    if ($user === null) {
        fail('حساب کاربری یافت نشد', 401);
    }

    return $user;
}

function wgDeviceList(): void
{
    $user = wgRequireCustomer();
    $userId = (int) $user['id'];
    $uuid = (string) ($user['uuid'] ?? '');
    $limit = wgUserLimit($user);
    $devices = wgUserDevices($userId, $uuid);

    done([
        'ok' => true,
        'devices' => $devices,
        'limit' => $limit,
        'count' => count($devices),
        'can_add' => count($devices) < $limit,
    ]);
}

function wgDeviceAdd(): void
{
    $user = wgRequireCustomer();
    $userId = (int) $user['id'];
    $uuid = (string) ($user['uuid'] ?? '');
    $limit = wgUserLimit($user);
    $devices = wgUserDevices($userId, $uuid);

    if (count($devices) >= $limit) {
        fail("سقف تعداد دستگاه‌های مجاز برای اشتراک شما ({$limit} دستگاه) تکمیل شده است.", 400);
    }

    $maxId = 0;
    foreach ($devices as $d) {
        if ($d['id'] > $maxId) {
            $maxId = $d['id'];
        }
    }
    $nextId = $maxId + 1;

    $name = trim((string) ($_POST['name'] ?? ''));
    if ($name === '') {
        $name = 'دستگاه ' . $nextId;
    }
    if (mb_strlen($name) > 50) {
        $name = mb_substr($name, 0, 50);
    }

    $pubkey = wgPublicKey($userId, $uuid, $nextId);
    if ($pubkey === '') {
        fail('خطا در تولید کلید دستگاه', 500);
    }

    try {
        $stmt = db()->prepare('INSERT INTO wg_credential (userid, device_id, name, pubkey, updated) VALUES (?, ?, ?, ?, ?)
                               ON DUPLICATE KEY UPDATE name = VALUES(name), pubkey = VALUES(pubkey), updated = VALUES(updated)');
        $stmt->execute([$userId, $nextId, $name, $pubkey, time()]);
    } catch (Throwable $e) {
        fail('خطا در ذخیره دستگاه در پایگاه داده: ' . $e->getMessage(), 500);
    }

    done(['ok' => true, 'device' => ['id' => $nextId, 'name' => $name, 'pubkey' => $pubkey]]);
}

function wgDeviceDel(): void
{
    $user = wgRequireCustomer();
    $userId = (int) $user['id'];

    $deviceId = (int) ($_POST['device_id'] ?? 0);
    if ($deviceId <= 1) {
        fail('دستگاه اصلی قابل حذف نیست', 400);
    }

    try {
        $stmt = db()->prepare('SELECT pubkey FROM wg_credential WHERE userid = ? AND device_id = ? LIMIT 1');
        $stmt->execute([$userId, $deviceId]);
        $row = $stmt->fetch();
        $pubkey = $row ? trim((string) $row['pubkey']) : '';

        db()->prepare('DELETE FROM wg_credential WHERE userid = ? AND device_id = ?')->execute([$userId, $deviceId]);
        if ($pubkey !== '') {
            db()->prepare('DELETE FROM wg_session WHERE userid = ? AND pubkey = ?')->execute([$userId, $pubkey]);
        }
    } catch (Throwable $e) {
        fail('خطا در حذف دستگاه: ' . $e->getMessage(), 500);
    }

    done(['ok' => true]);
}

// ---------------------------------------------------------------- dispatch

$wgAction = (string) ($_GET['do'] ?? '');

if (strpos($wgAction, 'wg.') !== 0) {
    return;
}

$wgNeedsPost = ['wg.device.add', 'wg.device.del', 'wg.hello', 'wg.push', 'wg.save', 'wg.nodesave', 'wg.nodekey',
    'wg.nodedel', 'wg.notifytest', 'wg.bypasssave', 'wg.iranrefresh'];

if (in_array($wgAction, $wgNeedsPost, true) && $_SERVER['REQUEST_METHOD'] !== 'POST') {
    fail('this action needs POST', 405);
}

switch ($wgAction) {
    case 'wg.devices':
        wgDeviceList();
    case 'wg.device.add':
        wgDeviceAdd();
    case 'wg.device.del':
        wgDeviceDel();
    case 'wg.hello':
        wgHello();
    case 'wg.push':
        wgPush();
    case 'wg.profile':
        wgProfile();
    case 'wg.admin':
        wgAdminBootstrap();
    case 'wg.sessions':
        wgAdminSessions();
    case 'wg.save':
        wgAdminSave();
    case 'wg.nodesave':
        wgAdminNodeSave();
    case 'wg.nodekey':
        wgAdminNodeKey();
    case 'wg.nodedel':
        wgAdminNodeDelete();
    case 'wg.notifytest':
        wgAdminNotifyTest();
    case 'wg.bypasssave':
        wgAdminBypassSave();
    case 'wg.iranrefresh':
        wgAdminIranRefresh();
}

fail('unknown WireGuard action');