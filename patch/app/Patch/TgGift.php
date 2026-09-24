<?php
/**
 * Telegram gifts - the dashboard's "has anything arrived?" call.
 *
 * Included by public/xmplus-patch.php in its global scope, before the admin
 * check, because it answers ordinary users; it borrows db(), fail(), done()
 * and startPanelSession() from there. It never returns.
 *
 * The gifts themselves are granted by bin/tgjoin.php (TgJoinJob) every minute.
 * This only lets the open dashboard notice them without a manual refresh:
 *
 *   tggift.poll   { gifts: unseen gifts, linked: Telegram linked or not }
 *                 With nudge=1 (the visitor just came back to the tab, likely
 *                 from Telegram) the account is moved to the front of the next
 *                 channel check instead of waiting out the 2-minute recheck.
 */

declare(strict_types=1);

$action = $_GET['do'] ?? '';

if ($action === 'tggift.poll') {
    startPanelSession();

    $login = $_SESSION['login_session'] ?? null;
    if (!is_array($login) || empty($login['uid'])) {
        fail('login required', 403);
    }
    if (!empty($login['expire']) && (int) $login['expire'] < time()) {
        fail('session expired', 403);
    }

    $uid = (int) $login['uid'];

    $user = db()->prepare('SELECT telegram_id FROM user WHERE id = ? LIMIT 1');
    $user->execute([$uid]);
    $row = $user->fetch();
    if ($row === false) {
        fail('account not found', 403);
    }

    $gifts = 0;
    foreach (['tgbind_log', 'tgjoin_log'] as $table) {
        try {
            $count = db()->prepare(
                "SELECT COUNT(*) AS n FROM {$table} WHERE userid = ? AND seen = 0 AND kind IN ('gb', 'free')");
            $count->execute([$uid]);
            $gifts += (int) $count->fetch()['n'];
        } catch (Throwable $error) {
            // the table or its seen column is created by the job's first run
        }
    }

    // at most one nudge per half minute, so a busy tab cannot starve the others
    if (!empty($_GET['nudge']) && time() - (int) ($_SESSION['tggift_nudged'] ?? 0) >= 30) {
        $_SESSION['tggift_nudged'] = time();
        try {
            db()->prepare('UPDATE tgjoin_check SET checked_at = 0 WHERE userid = ?')->execute([$uid]);
        } catch (Throwable $error) {
        }
    }

    session_write_close();

    done([
        'gifts'  => $gifts,
        'linked' => (int) $row['telegram_id'] > 0,
    ]);
}
