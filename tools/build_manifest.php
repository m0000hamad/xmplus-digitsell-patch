<?php
/**
 * Regenerates manifest.json from whatever is in patch/.
 *
 * Run it after changing any file, and before committing. The updater refuses a
 * release whose files do not hash to what the manifest says, so a stale
 * manifest means a refused update rather than a broken panel.
 *
 *   php tools/build_manifest.php [version] [--notes="what changed"]
 */

$root = dirname(__DIR__);
$patch = $root . '/patch';

if (!is_dir($patch)) {
    exit("patch/ not found\n");
}

$version = $argv[1] ?? trim((string) @file_get_contents($root . '/VERSION'));
if ($version === '' || !preg_match('~^\d+\.\d+\.\d+$~', $version)) {
    exit("give a version like 1.0.0, or put one in VERSION\n");
}

$notes = '';
foreach (array_slice($argv, 1) as $argument) {
    if (strpos($argument, '--notes=') === 0) {
        $notes = substr($argument, 8);
    }
}

if ($notes === '' && is_file($root . '/NOTES.txt')) {
    $notes = trim((string) file_get_contents($root . '/NOTES.txt'));
}

$files = [];
$items = new RecursiveIteratorIterator(
    new RecursiveDirectoryIterator($patch, FilesystemIterator::SKIP_DOTS));

foreach ($items as $item) {
    if ($item->isDir()) {
        continue;
    }

    $relative = str_replace('\\', '/', substr($item->getPathname(), strlen($patch) + 1));

    // editors and archives leave these behind; they must never ship
    if (preg_match('~(^|/)\.|\.(bak|orig|rej|swp|zip|tar\.gz)$~', $relative)) {
        echo "skipped  {$relative}\n";
        continue;
    }

    $files[$relative] = hash_file('sha256', $item->getPathname());
}

ksort($files);

$migrations = [];
foreach (glob($root . '/migrations/*.php') ?: [] as $file) {
    $migrations[] = basename($file);
}
sort($migrations);

$manifest = [
    'version' => $version,
    'released' => date('Y-m-d'),
    'notes' => $notes,
    'migrations' => $migrations,
    'files' => $files,
];

file_put_contents($root . '/manifest.json',
    json_encode($manifest, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE) . "\n");

file_put_contents($root . '/VERSION', $version . "\n");

printf("manifest.json written: version %s, %d files, %d migration(s)\n",
    $version, count($files), count($migrations));
