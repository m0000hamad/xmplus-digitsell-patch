<?php
/**
 * The check shared by every endpoint a node server calls (torexit.sync,
 * node.list): the caller sends the panel's API key - the ApiKey a node is
 * configured with - in the X-Panel-Key header.
 *
 * The encoded settings page stores that key under a name this patch cannot
 * read from source, so every *apikey* setting is a candidate; the comparison
 * is constant-time and an empty or short value never matches.
 *
 * Borrows db() and fail() from public/xmplus-patch.php.
 */

declare(strict_types=1);

function patchRequireNodeKey(): void
{
    $sent = (string) ($_SERVER['HTTP_X_PANEL_KEY'] ?? '');
    if (strlen($sent) < 8) {
        fail('panel key missing', 403);
    }

    $rows = db()->query("SELECT value FROM settings WHERE name LIKE '%apikey%'")->fetchAll();
    foreach ($rows as $row) {
        $value = (string) $row['value'];
        if (strlen($value) >= 8 && hash_equals($value, $sent)) {
            return;
        }
    }

    fail('wrong panel key', 403);
}
