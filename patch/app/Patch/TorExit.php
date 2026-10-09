<?php
/**
 * Exit location per Xray server: which country a server's customers appear
 * to come from.
 *
 * Included by public/xmplus-patch.php, in its global scope, before the blanket
 * requireAdmin(): torexit.sync is called by the Xray nodes, not by a browser.
 * Borrows db(), fail(), done(), setting(), requireAdmin() and requireToken().
 * Every path ends in done() or fail().
 *
 * Nothing here reaches out to a server. The Xray agent on each node
 * (node/xray/xray-agent.py, 1.2.0 and later) asks every minute: it reports
 * its state and gets back the country the admin picked for each of its nodes.
 * The agent installs tor-geo (github.com/m0000hamad/tor-multi-location) when
 * it is first needed, starts a Tor client for that country, and switches the
 * node's traffic to it once that client works. So the panel needs no SSH
 * access and holds no server password.
 *
 *   node, header X-Panel-Key = the panel's API key (the ApiKey in agent.json):
 *     torexit.sync    report in, wanted exits out (POST, JSON)
 *   admin, panel session (+ patch_csrf token for writes):
 *     torexit.admin   every server with its report and choice (GET)
 *     torexit.save    pick an exit for one server (POST)
 *     torexit.rotate  ask for a new exit IP on a server that leaves through Tor (POST)
 */

declare(strict_types=1);

/* a node not heard from for this long is shown as not reporting */
const TOREXIT_STALE = 300;
/* one node's report is a few KB; anything far bigger is not from our agent */
const TOREXIT_REPORT_MAX = 65536;

function torexitToken(): string
{
    if (empty($_SESSION['patch_csrf'])) {
        $_SESSION['patch_csrf'] = bin2hex(random_bytes(24));
    }

    return (string) $_SESSION['patch_csrf'];
}

require_once __DIR__ . '/NodeKey.php';

function torexitServerIds(): array
{
    $ids = [];
    foreach (db()->query('SELECT id FROM servers') as $row) {
        $ids[(int) $row['id']] = true;
    }

    return $ids;
}

function torexitCountry($value): string
{
    $value = strtolower(trim((string) $value));

    return preg_match('~^[a-z]{2}$~', $value) ? $value : '';
}

// ------------------------------------------------------------------- node

function torexitSync(): void
{
    patchRequireNodeKey();

    $body = json_decode((string) file_get_contents('php://input'), true);
    if (!is_array($body) || !is_array($body['nodes'] ?? null)) {
        fail('the body must be {"nodes": {"<server id>": {...}}}');
    }

    $known = torexitServerIds();
    $now = time();
    $save = db()->prepare(
        'INSERT INTO torexit_node (server_id, report_json, seen_at) VALUES (?, ?, ?)
         ON DUPLICATE KEY UPDATE report_json = VALUES(report_json), seen_at = VALUES(seen_at)');

    $ids = [];
    foreach ($body['nodes'] as $id => $report) {
        $id = (int) $id;
        if ($id <= 0 || !isset($known[$id]) || !is_array($report)) {
            continue;
        }
        $json = json_encode($report, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        if ($json === false || strlen($json) > TOREXIT_REPORT_MAX) {
            continue;
        }
        $save->execute([$id, $json, $now]);
        $ids[] = $id;
    }

    // only servers an admin has decided for; the agent keeps its own
    // agent.json setting for every server left out of the answer
    $wanted = new stdClass();
    if ($ids) {
        $marks = implode(',', array_fill(0, count($ids), '?'));
        $rows = db()->prepare("SELECT server_id, want, rotate_at FROM torexit_node WHERE managed = 1 AND server_id IN ($marks)");
        $rows->execute($ids);
        foreach ($rows as $row) {
            $wanted->{(string) $row['server_id']} = [
                'want'      => torexitCountry($row['want']),
                'rotate_at' => (int) $row['rotate_at'],
            ];
        }
    }

    done(['nodes' => $wanted, 'now' => $now]);
}

// ------------------------------------------------------------------ admin

function torexitAdmin(): void
{
    requireAdmin();

    $rows = [];
    foreach (db()->query('SELECT * FROM torexit_node') as $row) {
        $rows[(int) $row['server_id']] = $row;
    }

    $now = time();
    $servers = [];
    foreach (db()->query('SELECT * FROM servers ORDER BY id ASC') as $server) {
        $id = (int) $server['id'];
        $row = $rows[$id] ?? null;
        $report = null;
        if ($row !== null && (string) $row['report_json'] !== '') {
            $decoded = json_decode((string) $row['report_json'], true);
            $report = is_array($decoded) ? $decoded : null;
        }
        $seen = $row === null ? 0 : (int) $row['seen_at'];

        $servers[] = [
            'id'       => $id,
            'name'     => (string) ($server['name'] ?? ('#' . $id)),
            'type'     => strtolower((string) ($server['type'] ?? '')),
            'managed'  => $row !== null && (int) $row['managed'] === 1,
            'want'     => $row === null ? '' : torexitCountry($row['want']),
            'want_at'  => $row === null ? 0 : (int) $row['want_at'],
            'rotate_at' => $row === null ? 0 : (int) $row['rotate_at'],
            'seen_at'  => $seen,
            'live'     => $seen > 0 && $now - $seen <= TOREXIT_STALE,
            'report'   => $report,
        ];
    }

    done(['token' => torexitToken(), 'servers' => $servers, 'now' => $now]);
}

function torexitSave(): void
{
    requireAdmin();
    requireToken();

    $id = (int) ($_POST['id'] ?? 0);
    if ($id <= 0 || !isset(torexitServerIds()[$id])) {
        fail('unknown server');
    }

    // 'agent' = hand the choice back to agent.json, 'direct' = no exit proxy
    $choice = strtolower(trim((string) ($_POST['want'] ?? '')));
    if ($choice === 'agent') {
        $managed = 0;
        $want = '';
    } elseif ($choice === 'direct') {
        $managed = 1;
        $want = '';
    } else {
        $want = torexitCountry($choice);
        if ($want === '') {
            fail('pick a country, "direct" or "agent"');
        }
        $managed = 1;
    }

    db()->prepare(
        'INSERT INTO torexit_node (server_id, managed, want, want_at) VALUES (?, ?, ?, ?)
         ON DUPLICATE KEY UPDATE managed = VALUES(managed), want = VALUES(want), want_at = VALUES(want_at)')
        ->execute([$id, $managed, $want, time()]);

    done(['id' => $id, 'managed' => $managed === 1, 'want' => $want]);
}

function torexitRotate(): void
{
    requireAdmin();
    requireToken();

    $id = (int) ($_POST['id'] ?? 0);
    if ($id <= 0 || !isset(torexitServerIds()[$id])) {
        fail('unknown server');
    }

    $row = db()->prepare('SELECT managed, want, rotate_at FROM torexit_node WHERE server_id = ?');
    $row->execute([$id]);
    $row = $row->fetch();
    if (!$row || (int) $row['managed'] !== 1 || torexitCountry($row['want']) === '') {
        fail('pick a country for this server first');
    }

    $now = time();
    if ($now - (int) $row['rotate_at'] < 60) {
        fail('a new IP was asked for a moment ago');
    }

    db()->prepare('UPDATE torexit_node SET rotate_at = ? WHERE server_id = ?')->execute([$now, $id]);

    done(['id' => $id, 'rotate_at' => $now]);
}

// --------------------------------------------------------------- dispatch

$torexitAction = (string) ($_GET['do'] ?? '');

if (in_array($torexitAction, ['torexit.sync', 'torexit.save', 'torexit.rotate'], true) && $_SERVER['REQUEST_METHOD'] !== 'POST') {
    fail('this action needs POST', 405);
}

switch ($torexitAction) {
    case 'torexit.sync':
        torexitSync();
    case 'torexit.admin':
        torexitAdmin();
    case 'torexit.save':
        torexitSave();
    case 'torexit.rotate':
        torexitRotate();
}

fail('unknown exit location action');
