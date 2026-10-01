<?php
/**
 * What a node server's installer may ask the panel before it is set up.
 *
 * Included by public/xmplus-patch.php, in its global scope, before the blanket
 * requireAdmin(): the caller is node/xray/install.sh on a server, not a
 * browser. Borrows db(), fail() and done(). Every path ends in done() or fail().
 *
 *   node, header X-Panel-Key = the panel's API key:
 *     node.list   every server of the panel: id, name, type, whether it is
 *                 switched on, and the addresses (domain / IP) it is entered
 *                 with, so the installer can show the list and tell which
 *                 servers point at the machine it runs on (POST)
 *
 * The servers table belongs to the encoded panel and its column names are not
 * documented, so addresses are taken from columns whose name says address
 * (ip / host / domain / address / server), and only values that look like a
 * host name or an IP address leave: a key or a password never matches.
 */

declare(strict_types=1);

require_once __DIR__ . '/NodeKey.php';

function nodeApiLooksLikeHost(string $value): bool
{
    $value = trim($value);
    if ($value === '' || strlen($value) > 253) {
        return false;
    }
    if (filter_var($value, FILTER_VALIDATE_IP) !== false) {
        return true;
    }

    return (bool) preg_match('~^(?=.{1,253}$)([a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,63}$~i', $value);
}

function nodeApiAddresses(array $row): array
{
    $found = [];
    foreach ($row as $column => $value) {
        $column = strtolower((string) $column);
        if (!preg_match('~(ip|host|domain|address|addr|server)~', $column)
            || preg_match('~(key|pass|secret|token|cert|private|path|group|id$|limit|port)~', $column)
            || !is_scalar($value)) {
            continue;
        }
        // a cell may hold several, comma or space separated
        foreach (preg_split('~[\s,;]+~', (string) $value) ?: [] as $part) {
            $part = strtolower(trim($part));
            if (nodeApiLooksLikeHost($part)) {
                $found[$part] = true;
            }
        }
    }

    return array_keys($found);
}

function nodeApiList(): void
{
    patchRequireNodeKey();

    $servers = [];
    foreach (db()->query('SELECT * FROM servers ORDER BY id ASC') as $row) {
        $enabled = null;
        foreach (['enable', 'enabled', 'status'] as $column) {
            if (array_key_exists($column, $row) && is_numeric($row[$column])) {
                $enabled = (int) $row[$column] === 1;
                break;
            }
        }
        $servers[] = [
            'id'        => (int) $row['id'],
            'name'      => (string) ($row['name'] ?? ''),
            'type'      => strtolower((string) ($row['type'] ?? '')),
            'enabled'   => $enabled,
            'addresses' => nodeApiAddresses($row),
        ];
    }

    done(['servers' => $servers]);
}

// --------------------------------------------------------------- dispatch

$nodeApiAction = (string) ($_GET['do'] ?? '');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    fail('this action needs POST', 405);
}

switch ($nodeApiAction) {
    case 'node.list':
        nodeApiList();
}

fail('unknown node action');
