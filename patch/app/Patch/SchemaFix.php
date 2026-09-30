<?php
/**
 * Keeps the panel's own link builders from crashing on xhttp nodes.
 *
 * The builders in app/Http/Schema/ (Xray.php for the subscription link,
 * VlessURI.php and its siblings for the Servers page) read keys such as
 * `headerType` and `alpn` without checking they exist, and the encoded
 * controller leaves some of them out for the xhttp transport. Whoops turns the
 * PHP notice into a fatal error, so ONE xhttp node made every page that builds
 * its link answer "Internal Server Error" - for every account that can see it.
 *
 * For each file in app/Http/Schema/ that has a single build(array $item), this
 * puts `$item += [...]` defaults in front of the body, for the keys that file
 * only ever reads without isset / empty / ??. Keys that are there are not
 * touched (array union), and a key the file guards anywhere is left alone, so
 * the links of nodes that work today stay exactly the same.
 *
 * A panel update puts the original files back, so this runs once when the
 * patch is installed (migration 014) and then every hour from TaskCommand
 * (bin/schemafix.php). The same logic is in node/xray/fix-panel-xhttp.py, for
 * a panel that does not run the patch.
 *
 * Every changed file is copied to storage/patch/schema-backup/ first, parsed
 * afterwards (token_get_all with TOKEN_PARSE - nothing is executed), and put
 * back if it does not parse.
 */

if (!defined('SCHEMAFIX_MARKER')) {
    define('SCHEMAFIX_MARKER', '// digitsell: defaults');

    /* PHP literal each key gets when the panel left it out */
    define('SCHEMAFIX_DEFAULTS', [
        'headerType' => "'none'", 'alpn' => '[]', 'mode' => "'auto'", 'path' => "''", 'host' => "''",
        'sni' => "''", 'tls' => "''", 'fingerprint' => "''", 'flow' => "''", 'serviceName' => "''",
        'authority' => "''", 'quic_security' => "''", 'quic_key' => "''", 'seed' => "''",
        'allowinsecure' => '0', 'publickey' => "''", 'spiderx' => "''", 'shortid' => "''",
    ]);
}

/** True when every read of $item['key'] is unchecked and the file never sets it itself. */
function schemafixUnguarded(string $src, string $key): bool
{
    $ref = '\$item\[\s*[\'"]' . preg_quote($key, '~') . '[\'"]\s*\]';

    if (preg_match('~' . $ref . '\s*(?:\.|\+|-)?=(?!=)~', $src)) {
        return false;
    }

    if (!preg_match_all('~' . $ref . '~', $src, $found, PREG_OFFSET_CAPTURE)) {
        return false;
    }

    foreach ($found[0] as $hit) {
        $text = $hit[0];
        $offset = $hit[1];
        $before = substr($src, max(0, $offset - 16), min(16, $offset));
        $after = substr($src, $offset + strlen($text), 8);

        if (preg_match('~(?:isset|empty)\s*\(\s*$~', $before) || preg_match('~^\s*\?\?~', $after)) {
            return false;
        }
    }

    return true;
}

function schemafixParses(string $code): bool
{
    try {
        token_get_all($code, TOKEN_PARSE);
        return true;
    } catch (\ParseError $e) {
        return false;
    }
}

/** The text with defaults added, null when there is nothing to add, or a reason string. */
function schemafixBuild(string $source)
{
    if (strpos($source, SCHEMAFIX_MARKER) !== false) {
        return 'already patched';
    }

    $build = '~function\s+build\s*\(\s*array\s+\$item\s*\)\s*\{~';
    $count = preg_match_all($build, $source, $all);

    if ($count !== 1) {
        return 'skipped (' . $count . ' build(array $item) functions)';
    }

    $keys = [];
    foreach (SCHEMAFIX_DEFAULTS as $key => $literal) {
        if (schemafixUnguarded($source, $key)) {
            $keys[$key] = $literal;
        }
    }

    if ($keys === []) {
        return 'nothing to do';
    }

    $lines = [
        '',
        '        ' . SCHEMAFIX_MARKER . ' - the panel leaves keys out for some transports (xhttp); an undefined',
        '        // index is fatal here (Whoops) and breaks every page that builds this link',
        '        $item += [',
    ];
    foreach ($keys as $key => $literal) {
        $lines[] = "            '" . $key . "' => " . $literal . ',';
    }
    $lines[] = '        ];';

    preg_match($build, $source, $match, PREG_OFFSET_CAPTURE);
    $end = $match[0][1] + strlen($match[0][0]);

    return [substr($source, 0, $end) . implode("\n", $lines) . substr($source, $end), array_keys($keys)];
}

function schemafixFile(string $path, string $backupDir): string
{
    $source = @file_get_contents($path);
    if ($source === false) {
        return 'ERROR: cannot read';
    }

    $built = schemafixBuild($source);
    if (is_string($built)) {
        return $built;
    }

    [$patched, $keys] = $built;

    if (!schemafixParses($patched)) {
        return 'ERROR: the patched file would not parse, left as it is';
    }

    if (!is_writable($path)) {
        return 'ERROR: not writable (' . $path . ')';
    }

    if (!is_dir($backupDir) && !@mkdir($backupDir, 0755, true)) {
        return 'ERROR: cannot create ' . $backupDir;
    }

    $copy = $backupDir . '/' . basename($path) . '.' . date('Ymd-His');
    if (!@copy($path, $copy)) {
        return 'ERROR: cannot back up to ' . $copy;
    }
    // a cron run as root must not leave files the web user cannot remove
    $owner = @fileowner(dirname($backupDir));
    if ($owner !== false) {
        @chown($copy, $owner);
        @chown($backupDir, $owner);
    }

    if (@file_put_contents($path, $patched, LOCK_EX) !== strlen($patched)) {
        @file_put_contents($path, $source, LOCK_EX);
        return 'ERROR: could not write the file, the original was put back';
    }

    $after = (string) @file_get_contents($path);
    if ($after !== $patched || !schemafixParses($after)) {
        @file_put_contents($path, $source, LOCK_EX);
        return 'ERROR: the file did not read back right, the original was put back';
    }

    if (function_exists('opcache_invalidate')) {
        @opcache_invalidate($path, true);
    }

    return 'patched (' . implode(', ', $keys) . ') - original in ' . $copy;
}

/** ['VlessURI.php' => 'patched (...)', ...] for every file in app/Http/Schema. */
function schemafixRun(string $root): array
{
    $files = glob($root . '/app/Http/Schema/*.php') ?: [];
    sort($files);

    $out = [];
    foreach ($files as $path) {
        $out[basename($path)] = schemafixFile($path, $root . '/storage/patch/schema-backup');
    }

    return $out;
}
