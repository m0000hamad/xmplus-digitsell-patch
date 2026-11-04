<?php
declare(strict_types=1);

/** Per-server desired state; transport and reports reuse the authenticated node sync. */
function warpEnabled(int $id): bool
{
    return setting('warp_enabled_' . $id, '0') === '1';
}

function warpAdmin(): void
{
    requireAdmin();
    $servers = [];
    foreach (db()->query('SELECT id, name FROM servers ORDER BY id') as $row) {
        $id = (int) $row['id'];
        $status = json_decode((string) setting('warp_report_' . $id, '{}'), true) ?: [];
        $servers[] = ['id' => $id, 'name' => $row['name'], 'enabled' => warpEnabled($id),
            'report' => $status, 'live' => time() - (int) ($status['seen_at'] ?? 0) < 300];
    }
    if (empty($_SESSION['patch_csrf'])) $_SESSION['patch_csrf'] = bin2hex(random_bytes(24));
    done(['servers' => $servers, 'token' => $_SESSION['patch_csrf']]);
}

function warpSave(): void
{
    requireAdmin();
    requireToken();
    $id = filter_var($_POST['id'] ?? '', FILTER_VALIDATE_INT);
    $query = db()->prepare('SELECT id FROM servers WHERE id = ?');
    $query->execute([$id]);
    if (!$id || !$query->fetch()) fail('unknown server');
    $enabled = (string) ($_POST['enabled'] ?? '');
    if (!in_array($enabled, ['0', '1'], true)) fail('invalid enabled value');
    putSetting('warp_enabled_' . $id, $enabled);
    done(['id' => $id, 'enabled' => $enabled === '1']);
}

// The sync handler includes this file for helpers only.
if (strpos((string) ($_GET['do'] ?? ''), 'warp.') === 0) {
    if ($_GET['do'] === 'warp.admin' && $_SERVER['REQUEST_METHOD'] === 'GET') warpAdmin();
    if ($_GET['do'] === 'warp.save' && $_SERVER['REQUEST_METHOD'] === 'POST') warpSave();
    fail('invalid WARP action or method', 405);
}
