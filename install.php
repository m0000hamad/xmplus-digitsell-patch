<?php
/**
 * First-time installer. Run once, from the shell, on the panel server:
 *
 *   cd /www/wwwroot/<panel>
 *   curl -sL https://codeload.github.com/m0000hamad/xmplus-digitsell-patch/zip/refs/heads/main -o /tmp/patch.zip
 *   unzip -q -o /tmp/patch.zip -d /tmp && php /tmp/xmplus-digitsell-patch-main/install.php /www/wwwroot/<panel>
 *
 * After this, every later release is applied from the panel itself:
 * Settings -> Patch updates -> Download and apply.
 *
 * The installer copies the same files the in-panel updater would, runs the
 * migrations, and records the version. It backs up anything it overwrites.
 */

$source = __DIR__;
$target = rtrim($argv[1] ?? '', '/');

if ($target === '' || !is_dir($target . '/public') || !is_file($target . '/config/config.php')) {
    exit("usage: php install.php /path/to/panel   (the directory holding public/ and config/)\n");
}

$manifest = json_decode((string) @file_get_contents($source . '/manifest.json'), true);
if (!is_array($manifest) || empty($manifest['files'])) {
    exit("manifest.json is missing or malformed\n");
}

echo "installing patch {$manifest['version']} into {$target}\n\n";

// ------------------------------------------------------------- the files
$stamp = date('Ymd-His');
$backup = $target . '/storage/patch/backup-' . $stamp;
$written = 0;
$same = 0;

foreach ($manifest['files'] as $relative => $expected) {
    $from = $source . '/patch/' . $relative;

    if (!is_file($from)) {
        exit("FAIL: the release is missing {$relative}\n");
    }
    if (!hash_equals(strtolower($expected), hash_file('sha256', $from))) {
        exit("FAIL: checksum mismatch on {$relative} — rebuild the manifest\n");
    }
    if (strpos($relative, '..') !== false) {
        exit("FAIL: unsafe path {$relative}\n");
    }

    $to = $target . '/' . $relative;

    if (is_file($to) && hash_file('sha256', $to) === hash_file('sha256', $from)) {
        $same++;
        continue;
    }

    if (is_file($to)) {
        $keep = $backup . '/' . $relative;
        if (!is_dir(dirname($keep))) {
            mkdir(dirname($keep), 0755, true);
        }
        copy($to, $keep);
    }

    if (!is_dir(dirname($to))) {
        mkdir(dirname($to), 0755, true);
    }

    if (!copy($from, $to)) {
        exit("FAIL: could not write {$relative}\n");
    }

    echo "  wrote {$relative}\n";
    $written++;
}

// keep the ownership the web server needs
$reference = $target . '/public/index.php';
if (is_file($reference)) {
    $owner = fileowner($reference);
    $group = filegroup($reference);

    foreach (array_keys($manifest['files']) as $relative) {
        @chown($target . '/' . $relative, $owner);
        @chgrp($target . '/' . $relative, $group);
        @chmod($target . '/' . $relative, 0644);
    }
}

// the in-panel updater runs as the web user and needs to write here
$work = $target . '/storage/patch';
if (is_dir($work) && is_file($reference)) {
    @chown($work, fileowner($reference));
    @chgrp($work, filegroup($reference));
    @chmod($work, 0755);
}

printf("\n%d file(s) written, %d already current\n", $written, $same);
if (is_dir($backup)) {
    echo "previous versions kept in storage/patch/backup-{$stamp}\n";
}

// -------------------------------------------------------- the database
require $target . '/config/config.php';

$dsn = sprintf('mysql:host=%s;dbname=%s;charset=utf8mb4',
    $DB['db_host'] ?? 'localhost', $DB['db_database'] ?? '');
if (!empty($DB['db_socket'])) {
    $dsn = sprintf('mysql:unix_socket=%s;dbname=%s;charset=utf8mb4',
        $DB['db_socket'], $DB['db_database'] ?? '');
}

$db = new PDO($dsn, $DB['db_username'] ?? '', $DB['db_password'] ?? '', [
    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
]);

function put(PDO $db, string $name, string $value): void
{
    $exists = $db->prepare('SELECT 1 FROM settings WHERE name = ? LIMIT 1');
    $exists->execute([$name]);

    if ($exists->fetch() === false) {
        $db->prepare('INSERT INTO settings (name, value) VALUES (?, ?)')->execute([$name, $value]);
        return;
    }
    $db->prepare('UPDATE settings SET value = ? WHERE name = ?')->execute([$value, $name]);
}

$appliedRow = $db->prepare('SELECT value FROM settings WHERE name = ? LIMIT 1');
$appliedRow->execute(['patch_migrations']);
$row = $appliedRow->fetch();
$applied = ($row && $row['value'] !== '') ? explode(',', $row['value']) : [];

echo "\nmigrations:\n";
foreach ($manifest['migrations'] ?? [] as $name) {
    if (in_array($name, $applied, true)) {
        echo "  skipped {$name}\n";
        continue;
    }

    $migration = require $source . '/migrations/' . basename($name);
    $migration($db);
    $applied[] = $name;
    echo "  ran     {$name}\n";
}

put($db, 'patch_migrations', implode(',', array_unique($applied)));
put($db, 'patch_version', (string) $manifest['version']);
put($db, 'patch_applied_at', date('Y-m-d H:i:s'));

// ------------------------------------------------------- the compiled views
function wipe(string $path): void
{
    if (is_file($path)) {
        unlink($path);
        return;
    }
    if (!is_dir($path)) {
        return;
    }

    foreach (glob($path . '/*') ?: [] as $child) {
        wipe($child);
    }
    rmdir($path);
}

$compile = $target . '/storage/smarty/compile';
if (is_dir($compile)) {
    foreach (glob($compile . '/*') ?: [] as $item) {
        wipe($item);
    }
    echo "\ncleared storage/smarty/compile\n";
}

echo "\ndone. open Settings -> Patch updates in the admin panel.\n";
