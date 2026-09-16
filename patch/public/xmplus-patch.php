<?php
/**
 * In-panel updater for the Digitsell XMPlus patch.
 *
 * The panel's controllers and routes are ionCube encoded, so no route can be
 * added to the application itself. nginx passes any .php under public/ to
 * php-fpm, so this file is the endpoint: it answers directly, outside Slim.
 *
 * Every request must come from a logged-in admin and carry the CSRF token that
 * the settings page put in the session. Files are only ever written to paths
 * that the release manifest names, each one checked against its SHA-256 and
 * confined to the four directories the patch owns.
 */

declare(strict_types=1);

// the answer is JSON; a stray warning printed ahead of it would make the page
// unable to parse the response, so warnings go to the log only
ini_set('display_errors', '0');
error_reporting(E_ALL);

const PATCH_ENDPOINT_VERSION = '1.2.0';

/** Where releases come from. Overridable by the `patch_repo` setting. */
const DEFAULT_REPO = 'm0000hamad/xmplus-digitsell-patch';
const DEFAULT_BRANCH = 'main';

/** Only these prefixes may be written. Anything else in a manifest is refused. */
const ALLOWED_PREFIXES = ['app/', 'bin/', 'localization/', 'view/', 'public/xmplus-patch.php'];

const ROOT = __DIR__ . '/..';

header('Content-Type: application/json; charset=utf-8');
header('X-Content-Type-Options: nosniff');
header('Cache-Control: no-store');

// ---------------------------------------------------------------- plumbing

/**
 * nginx here is configured with `error_page 404 /404.html; error_page 502 ...`,
 * and those pages do not exist, so it hands such responses to index.php and the
 * caller gets the panel's HTML 404 instead of this JSON. Failures therefore
 * answer 200 and carry the outcome in the body; only 403 and 405, which nginx
 * passes through untouched, are used as real status codes.
 */
function fail(string $message, int $status = 200): void
{
    http_response_code(in_array($status, [403, 405], true) ? $status : 200);
    echo json_encode(['ok' => false, 'error' => $message], JSON_UNESCAPED_UNICODE);
    exit;
}

function done(array $payload): void
{
    echo json_encode(['ok' => true] + $payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}

function db(): PDO
{
    static $pdo = null;
    if ($pdo instanceof PDO) {
        return $pdo;
    }

    $config = ROOT . '/config/config.php';
    if (!is_file($config)) {
        fail('config/config.php not found');
    }

    require $config;
    if (!isset($DB) || !is_array($DB)) {
        fail('database configuration not readable');
    }

    $dsn = sprintf('mysql:host=%s;dbname=%s;charset=utf8mb4',
        $DB['db_host'] ?? 'localhost', $DB['db_database'] ?? '');

    if (!empty($DB['db_socket'])) {
        $dsn = sprintf('mysql:unix_socket=%s;dbname=%s;charset=utf8mb4',
            $DB['db_socket'], $DB['db_database'] ?? '');
    }

    try {
        $pdo = new PDO($dsn, $DB['db_username'] ?? '', $DB['db_password'] ?? '', [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        ]);
    } catch (Throwable $error) {
        fail('cannot reach the database');
    }

    return $pdo;
}

function setting(string $name, ?string $fallback = null): ?string
{
    $statement = db()->prepare('SELECT value FROM settings WHERE name = ? LIMIT 1');
    $statement->execute([$name]);
    $row = $statement->fetch();

    return $row === false ? $fallback : (string) $row['value'];
}

function putSetting(string $name, string $value): void
{
    $exists = db()->prepare('SELECT 1 FROM settings WHERE name = ? LIMIT 1');
    $exists->execute([$name]);

    if ($exists->fetch() === false) {
        db()->prepare('INSERT INTO settings (name, value) VALUES (?, ?)')->execute([$name, $value]);
        return;
    }

    db()->prepare('UPDATE settings SET value = ? WHERE name = ?')->execute([$value, $name]);
}

// -------------------------------------------------------------------- auth

/**
 * The panel does not use PHP's default session cookie name: its middleware
 * renames the session to `xmplus`, so a plain session_start() here opened an
 * empty session and every request looked logged out. Pick the name from the
 * cookies the browser actually sent.
 */
function startPanelSession(): void
{
    if (session_status() === PHP_SESSION_ACTIVE) {
        return;
    }

    foreach (['xmplus', session_name()] as $name) {
        if (isset($_COOKIE[$name])) {
            session_name($name);
            break;
        }
    }

    session_start();
}

function requireAdmin(): int
{
    startPanelSession();

    $login = $_SESSION['login_session'] ?? null;
    if (!is_array($login) || empty($login['uid']) || empty($login['is_admin'])) {
        fail('admin session required', 403);
    }

    if (!empty($login['expire']) && (int) $login['expire'] < time()) {
        fail('session expired', 403);
    }

    // the session claim is only believed if the account still says so
    $statement = db()->prepare('SELECT role FROM user WHERE id = ? LIMIT 1');
    $statement->execute([(int) $login['uid']]);
    $row = $statement->fetch();

    if ($row === false || (int) $row['role'] <= 0) {
        fail('this account is not an administrator', 403);
    }

    return (int) $login['uid'];
}

function requireToken(): void
{
    $sent = $_POST['token'] ?? ($_SERVER['HTTP_X_PATCH_TOKEN'] ?? '');
    $held = $_SESSION['patch_csrf'] ?? '';

    if ($held === '' || !is_string($sent) || !hash_equals($held, $sent)) {
        fail('bad or missing token', 403);
    }
}

// ------------------------------------------------------------------ github

function repo(): string
{
    $configured = trim((string) setting('patch_repo', ''));
    $repo = $configured !== '' ? $configured : DEFAULT_REPO;

    if (!preg_match('~^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$~', $repo)) {
        fail('the configured repository name is not valid');
    }

    return $repo;
}

function branch(): string
{
    $configured = trim((string) setting('patch_branch', ''));
    $branch = $configured !== '' ? $configured : DEFAULT_BRANCH;

    if (!preg_match('~^[A-Za-z0-9_./-]{1,80}$~', $branch)) {
        fail('the configured branch name is not valid');
    }

    return $branch;
}

function fetch(string $url, ?string $saveTo = null)
{
    $handle = curl_init($url);
    curl_setopt_array($handle, [
        CURLOPT_FOLLOWLOCATION => true,
        CURLOPT_MAXREDIRS => 5,
        CURLOPT_CONNECTTIMEOUT => 15,
        CURLOPT_TIMEOUT => 180,
        CURLOPT_SSL_VERIFYPEER => true,
        CURLOPT_SSL_VERIFYHOST => 2,
        CURLOPT_PROTOCOLS => CURLPROTO_HTTPS,
        CURLOPT_REDIR_PROTOCOLS => CURLPROTO_HTTPS,
        CURLOPT_USERAGENT => 'xmplus-digitsell-patch/' . PATCH_ENDPOINT_VERSION,
        CURLOPT_HTTPHEADER => ['Cache-Control: no-cache', 'Pragma: no-cache'],
    ]);

    $file = null;
    if ($saveTo === null) {
        curl_setopt($handle, CURLOPT_RETURNTRANSFER, true);
    } else {
        $file = fopen($saveTo, 'wb');
        if ($file === false) {
            fail('cannot write to ' . $saveTo);
        }
        curl_setopt($handle, CURLOPT_FILE, $file);
    }

    $body = curl_exec($handle);
    $status = (int) curl_getinfo($handle, CURLINFO_RESPONSE_CODE);
    $error = curl_error($handle);
    curl_close($handle);

    if ($file !== null) {
        fclose($file);
    }

    if ($body === false && $saveTo === null) {
        fail('download failed: ' . $error);
    }
    if ($status !== 200) {
        fail('GitHub answered ' . $status . ' for ' . $url);
    }

    return $saveTo === null ? $body : true;
}

/**
 * The commit the branch currently points at.
 *
 * Branch-named URLs are served from caches that move at different speeds:
 * raw.githubusercontent handed back an old manifest while codeload already
 * served the new archive, and the version guard — correctly — refused the pair.
 * A commit SHA is immutable, so the manifest and the archive read at one SHA
 * always belong together.
 */
function headCommit(): string
{
    $url = sprintf('https://api.github.com/repos/%s/commits/%s', repo(), branch());
    $decoded = json_decode((string) fetch($url), true);

    if (!is_array($decoded) || empty($decoded['sha']) || !preg_match('~^[0-9a-f]{40}$~', $decoded['sha'])) {
        fail('could not read the current commit from GitHub');
    }

    return (string) $decoded['sha'];
}

function remoteManifest(string $commit): array
{
    $url = sprintf('https://raw.githubusercontent.com/%s/%s/manifest.json', repo(), $commit);
    $decoded = json_decode((string) fetch($url), true);

    if (!is_array($decoded) || empty($decoded['version']) || !is_array($decoded['files'] ?? null)) {
        fail('the release manifest is malformed');
    }

    return $decoded;
}

// ------------------------------------------------------------------ paths

function safeDestination(string $relative): string
{
    $relative = str_replace('\\', '/', trim($relative));

    if ($relative === '' || strpos($relative, '..') !== false || $relative[0] === '/') {
        fail('the manifest names an unsafe path: ' . $relative);
    }

    $allowed = false;
    foreach (ALLOWED_PREFIXES as $prefix) {
        if (strpos($relative, $prefix) === 0) {
            $allowed = true;
            break;
        }
    }

    if (!$allowed) {
        fail('the manifest names a path outside the patch: ' . $relative);
    }

    return ROOT . '/' . $relative;
}

function removeTree(string $path): void
{
    if (!is_dir($path)) {
        if (is_file($path)) {
            unlink($path);
        }
        return;
    }

    $items = new RecursiveIteratorIterator(
        new RecursiveDirectoryIterator($path, FilesystemIterator::SKIP_DOTS),
        RecursiveIteratorIterator::CHILD_FIRST);

    foreach ($items as $item) {
        $item->isDir() ? rmdir($item->getPathname()) : unlink($item->getPathname());
    }

    rmdir($path);
}

/**
 * Ownership is taken from the application directory, not from a file inside it:
 * on this install public/index.php is root-owned while every directory belongs
 * to the web user, so copying a file's ownership handed files to root and the
 * next update could no longer write them.
 */
function ownLikeTheApp(string $path, int $mode = 0644): void
{
    $reference = ROOT;
    if (!is_dir($reference)) {
        return;
    }

    $owner = fileowner($reference);
    $group = filegroup($reference);

    if ($owner !== false) {
        @chown($path, $owner);
    }
    if ($group !== false) {
        @chgrp($path, $group);
    }
    @chmod($path, $mode);
}

// ------------------------------------------------------------- migrations

function appliedMigrations(): array
{
    $raw = (string) setting('patch_migrations', '');
    return $raw === '' ? [] : array_filter(explode(',', $raw));
}

function runMigrations(string $source, array $manifest): array
{
    $applied = appliedMigrations();
    $ran = [];

    foreach ($manifest['migrations'] ?? [] as $name) {
        if (in_array($name, $applied, true)) {
            continue;
        }

        $file = $source . '/migrations/' . basename((string) $name);
        if (!is_file($file)) {
            continue;
        }

        $migration = require $file;
        if (!is_callable($migration)) {
            continue;
        }

        $migration(db());

        $applied[] = $name;
        $ran[] = $name;
    }

    putSetting('patch_migrations', implode(',', array_unique($applied)));

    return $ran;
}

function clearCompiledTemplates(): void
{
    $compile = ROOT . '/storage/smarty/compile';
    if (!is_dir($compile)) {
        return;
    }

    foreach (glob($compile . '/*') ?: [] as $item) {
        removeTree($item);
    }
}

// --------------------------------------------------------------- the verbs

$action = $_GET['do'] ?? 'status';

// Time plans live in their own file and answer ordinary users as well as
// admins, so they are dispatched before the blanket admin check below.
if (strpos($action, 'timeplan.') === 0) {
    require ROOT . '/app/Patch/TimePlan.php';
    fail('unknown time plan action');
}

requireAdmin();

if ($action === 'status') {
    $commit = headCommit();
    $manifest = remoteManifest($commit);
    $installed = (string) setting('patch_version', '');

    // the write actions need this back; a cross-site page cannot read it,
    // because reading this response requires being on the panel's own origin
    if (empty($_SESSION['patch_csrf'])) {
        $_SESSION['patch_csrf'] = bin2hex(random_bytes(24));
    }

    done([
        'token' => $_SESSION['patch_csrf'],
        'installed' => $installed,
        'latest' => (string) $manifest['version'],
        'files' => count($manifest['files']),
        'notes' => (string) ($manifest['notes'] ?? ''),
        'released' => (string) ($manifest['released'] ?? ''),
        'repo' => repo(),
        'branch' => branch(),
        'commit' => substr($commit, 0, 7),
        'uptodate' => $installed === (string) $manifest['version'],
        'endpoint' => PATCH_ENDPOINT_VERSION,
    ]);
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    fail('this action needs POST', 405);
}

requireToken();

if ($action === 'apply') {
    $commit = headCommit();
    $manifest = remoteManifest($commit);
    $stamp = date('Ymd-His');

    $work = ROOT . '/storage/patch';
    if (!is_dir($work) && !mkdir($work, 0755, true) && !is_dir($work)) {
        fail('cannot create storage/patch');
    }

    ownLikeTheApp($work, 0755);

    if (!is_writable($work)) {
        fail('storage/patch is not writable by the web user — run: '
            . 'chown -R <web user> ' . $work);
    }

    $archive = $work . '/release-' . $stamp . '.zip';
    fetch(sprintf('https://codeload.github.com/%s/zip/%s', repo(), $commit), $archive);

    $unpacked = $work . '/unpacked-' . $stamp;
    $zip = new ZipArchive();

    if ($zip->open($archive) !== true) {
        @unlink($archive);
        fail('the downloaded release is not a readable zip');
    }

    $zip->extractTo($unpacked);
    $zip->close();
    @unlink($archive);

    // GitHub wraps everything in <repo>-<commit>/
    $inner = glob($unpacked . '/*', GLOB_ONLYDIR);
    $source = ($inner && count($inner) === 1) ? $inner[0] : $unpacked;

    // the manifest that travelled with the files is the one that counts
    $shipped = json_decode((string) @file_get_contents($source . '/manifest.json'), true);
    if (!is_array($shipped) || ($shipped['version'] ?? null) !== $manifest['version']) {
        $found = is_array($shipped) ? (string) ($shipped['version'] ?? '?') : 'unreadable';
        removeTree($unpacked);
        fail(sprintf(
            'the archive holds version %s but the manifest advertised %s — '
            . 'if you have just pushed, wait a minute for GitHub to catch up',
            $found, (string) $manifest['version']));
    }

    // ---- verify before touching anything -------------------------------
    $planned = [];
    foreach ($shipped['files'] as $relative => $expected) {
        $from = $source . '/patch/' . $relative;

        if (!is_file($from)) {
            removeTree($unpacked);
            fail('the release is missing ' . $relative);
        }

        $actual = hash_file('sha256', $from);
        if (!is_string($expected) || !hash_equals(strtolower($expected), (string) $actual)) {
            removeTree($unpacked);
            fail('checksum mismatch on ' . $relative);
        }

        $planned[$relative] = ['from' => $from, 'to' => safeDestination($relative)];
    }

    // ---- keep what is there now ----------------------------------------
    $backup = $work . '/backup-' . $stamp;
    $changed = 0;
    $kept = 0;

    foreach ($planned as $relative => $move) {
        if (is_file($move['to']) && hash_file('sha256', $move['to']) === hash_file('sha256', $move['from'])) {
            $kept++;
            continue;
        }

        if (is_file($move['to'])) {
            $target = $backup . '/' . $relative;
            if (!is_dir(dirname($target))) {
                mkdir(dirname($target), 0755, true);
            }
            copy($move['to'], $target);
        }

        if (!is_dir(dirname($move['to']))) {
            mkdir(dirname($move['to']), 0755, true);
        }

        if (!copy($move['from'], $move['to'])) {
            fail('could not write ' . $relative . ' — check ownership');
        }

        ownLikeTheApp($move['to']);
        $changed++;
    }

    $ran = runMigrations($source, $shipped);

    clearCompiledTemplates();
    putSetting('patch_version_before', (string) setting('patch_version', ''));
    putSetting('patch_version', (string) $shipped['version']);
    putSetting('patch_applied_at', date('Y-m-d H:i:s'));

    if (is_dir($backup)) {
        putSetting('patch_last_backup', 'backup-' . $stamp);
    }

    removeTree($unpacked);

    done([
        'version' => (string) $shipped['version'],
        'commit' => substr($commit, 0, 7),
        'updated' => $changed,
        'unchanged' => $kept,
        'migrations' => $ran,
        'backup' => is_dir($backup) ? 'backup-' . $stamp : null,
    ]);
}

if ($action === 'rollback') {
    $name = (string) setting('patch_last_backup', '');
    $backup = ROOT . '/storage/patch/' . basename($name);

    if ($name === '' || !is_dir($backup)) {
        fail('there is no backup to go back to');
    }

    $restored = 0;
    $items = new RecursiveIteratorIterator(
        new RecursiveDirectoryIterator($backup, FilesystemIterator::SKIP_DOTS));

    foreach ($items as $item) {
        if ($item->isDir()) {
            continue;
        }

        $relative = ltrim(str_replace('\\', '/', substr($item->getPathname(), strlen($backup))), '/');
        $to = safeDestination($relative);

        if (copy($item->getPathname(), $to)) {
            ownLikeTheApp($to);
            $restored++;
        }
    }

    clearCompiledTemplates();
    putSetting('patch_version', (string) setting('patch_version_before', ''));

    done(['restored' => $restored, 'from' => $name]);
}

fail('unknown action');
