<?php
// Authenticated image transport, included before the updater's admin-only gate.
startPanelSession();
$login = $_SESSION['login_session'] ?? null;
if (!is_array($login) || empty($login['uid']) || (!empty($login['expire']) && $login['expire'] < time())) fail('login required', 403);
$q = db()->prepare('SELECT id,role FROM user WHERE id=?');
$q->execute([(int) $login['uid']]);
$viewer = $q->fetch();
if (!$viewer) fail('login required', 403);
if (empty($_SESSION['ticket_csrf'])) $_SESSION['ticket_csrf'] = bin2hex(random_bytes(24));

if ($action === 'ticket.token') done(['token' => $_SESSION['ticket_csrf']]);

if ($action === 'ticket.manage') {
    if ((int) $viewer['role'] <= 0) fail('access denied', 403);
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') fail('POST required', 405);
    if (!is_string($_POST['token'] ?? null) || !hash_equals($_SESSION['ticket_csrf'], $_POST['token'])) fail('bad token', 403);
    $operation = $_POST['operation'] ?? '';
    $ids = $_POST['ids'] ?? [];
    if (!in_array($operation, ['close', 'delete'], true) || !is_array($ids) || !$ids || count($ids) > 100) fail('invalid selection');
    foreach ($ids as $id) if (!is_scalar($id) || !preg_match('/^[1-9][0-9]*$/D', (string) $id)) fail('invalid selection');
    $ids = array_values(array_unique(array_map('intval', $ids)));
    sort($ids, SORT_NUMERIC);
    $pdo = db();
    $pdo->beginTransaction();
    try {
        $marks = implode(',', array_fill(0, count($ids), '?'));
        $q = $pdo->prepare('SELECT id FROM tickets WHERE rootid=0 AND id IN ('.$marks.') ORDER BY id FOR UPDATE');
        $q->execute($ids);
        $roots = $q->fetchAll(PDO::FETCH_COLUMN);
        if (count($roots) !== count($ids)) throw new RuntimeException('انتخاب تغییر کرده است؛ فهرست را تازه کنید.');
        if ($operation === 'close') {
            $q = $pdo->prepare('UPDATE tickets SET status=0 WHERE rootid=0 AND id IN ('.$marks.')');
            $q->execute($ids);
        } else {
            $q = $pdo->prepare('DELETE FROM ticket_close_notice WHERE ticketid IN ('.$marks.')');
            $q->execute($ids);
            $q = $pdo->prepare('DELETE FROM tickets WHERE id IN ('.$marks.') OR main_id IN ('.$marks.') OR rootid IN ('.$marks.')');
            $q->execute(array_merge($ids, $ids, $ids));
        }
        $pdo->commit();
    } catch (Throwable $e) {
        $pdo->rollBack();
        fail('عملیات انجام نشد؛ فهرست را تازه کنید و دوباره تلاش کنید.');
    }
    done(['count' => count($ids)]);
}

if ($action === 'ticket.upload') {
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') fail('POST required', 405);
    if (!is_string($_POST['token'] ?? null) || !hash_equals($_SESSION['ticket_csrf'], $_POST['token'])) fail('bad token', 403);
    $file = $_FILES['image'] ?? [];
    if (($file['error'] ?? -1) !== UPLOAD_ERR_OK || !is_uploaded_file($file['tmp_name'] ?? '')) fail('آپلود عکس ناموفق بود.');
    if (($file['size'] ?? 0) < 1 || $file['size'] > 5 * 1024 * 1024) fail('حداکثر حجم عکس ۵ مگابایت است.');
    $info = @getimagesize($file['tmp_name']);
    $types = ['image/jpeg' => 'jpg', 'image/png' => 'png', 'image/webp' => 'webp'];
    $mime = (new finfo(FILEINFO_MIME_TYPE))->file($file['tmp_name']);
    if (!$info || !isset($types[$mime]) || ($info['mime'] ?? '') !== $mime || $info[0] * $info[1] > 24000000) fail('فقط عکس JPG، PNG یا WebP تا ۲۴ مگاپیکسل مجاز است.');
    $dir = ROOT . '/storage/ticket-images';
    if (!is_dir($dir) && !mkdir($dir, 0750, true)) fail('ذخیره عکس ناموفق بود.');
    $name = 'tk_' . (int) $viewer['id'] . '_' . bin2hex(random_bytes(24)) . '.' . $types[$mime];
    if (!move_uploaded_file($file['tmp_name'], $dir . '/' . $name)) fail('ذخیره عکس ناموفق بود.');
    chmod($dir . '/' . $name, 0640);
    done(['file' => $name]);
}

if ($action === 'ticket.image') {
    $name = $_GET['file'] ?? '';
    if (!is_string($name) || !preg_match('/^tk_([1-9][0-9]*)_[a-f0-9]{48}\.(jpg|png|webp)$/D', $name)) fail('invalid image', 403);
    // Only attached images can be read; an unsubmitted upload is not public.
    $q = db()->prepare('SELECT main_id, id, rootid FROM tickets WHERE files=? LIMIT 1');
    $q->execute([$name]);
    $message = $q->fetch();
    if (!$message) fail('image unavailable', 403);
    $q = db()->prepare('SELECT userid FROM tickets WHERE id=? AND rootid=0');
    $q->execute([(int) ($message['rootid'] ? $message['main_id'] : $message['id'])]);
    $owner = $q->fetch();
    if (!$owner || ((int) $viewer['role'] <= 0 && (int) $owner['userid'] !== (int) $viewer['id'])) fail('access denied', 403);
    $path = ROOT . '/storage/ticket-images/' . $name;
    if (!is_file($path)) fail('image unavailable', 403);
    $ext = pathinfo($name, PATHINFO_EXTENSION);
    header('Content-Type: image/' . ($ext === 'jpg' ? 'jpeg' : $ext));
    header('Content-Disposition: ' . (isset($_GET['download']) ? 'attachment' : 'inline') . '; filename="ticket-image.' . $ext . '"');
    header('Content-Length: ' . filesize($path));
    header("Content-Security-Policy: default-src 'none'; sandbox");
    session_write_close();
    readfile($path);
    exit;
}
fail('unknown ticket action');
