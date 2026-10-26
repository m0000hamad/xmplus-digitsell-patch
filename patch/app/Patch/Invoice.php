<?php
/** Admin-issued invoices. Settlement stays in the panel's native checkout.
 * No gateway callback or payment-success flag is accepted from the browser.
 */
declare(strict_types=1);

class InvoiceException extends RuntimeException {}

function invoiceSession(): int
{
    startPanelSession();
    $login = $_SESSION['login_session'] ?? [];
    if (empty($login['uid']) || (!empty($login['expire']) && $login['expire'] < time())) {
        fail('ابتدا وارد حساب خود شوید.', 403);
    }
    $q = db()->prepare('SELECT id FROM user WHERE id = ?');
    $q->execute([(int) $login['uid']]);
    if (!$q->fetchColumn()) { fail('حساب کاربری پیدا نشد.', 403); }
    return (int) $login['uid'];
}

function invoiceToken(): string
{
    if (empty($_SESSION['invoice_csrf'])) { $_SESSION['invoice_csrf'] = bin2hex(random_bytes(24)); }
    return $_SESSION['invoice_csrf'];
}

function invoiceWrite(): void
{
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') { fail('POST required', 405); }
    $token = $_POST['token'] ?? '';
    if (!is_string($token) || !hash_equals(invoiceToken(), $token)) { fail('درخواست نامعتبر است.', 403); }
}

function invoicePrice(array $package, string $plan): string
{
    $options = json_decode((string) $package['price_option'], true);
    $value = $options[$plan]['price'] ?? null;
    if (!is_numeric($value) || (float) $value <= 0 || (float) $value > 100000000000) {
        throw new InvoiceException('دوره یا قیمت پلن معتبر نیست.');
    }
    return number_format((float) $value, 2, '.', '');
}

function invoiceRows(int $uid, bool $admin): array
{
    $q = db()->prepare('SELECT i.*, o.status AS order_status, o.order_id AS order_number,
        o.total_amount AS payable, u.username FROM patch_invoice i
        LEFT JOIN orders o ON o.id = i.orderid LEFT JOIN user u ON u.id = i.userid '
        . ($admin ? '' : 'WHERE i.userid = ? ') . 'ORDER BY i.id DESC LIMIT 100');
    $q->execute($admin ? [] : [$uid]);
    $rows = $q->fetchAll();
    foreach ($rows as &$r) {
        $r['status'] = (int) ($r['order_status'] ?? 0) === 1 ? 'paid'
            : ((int) $r['canceled'] === 1 ? 'canceled'
                : ((int) ($r['order_status'] ?? 0) < 0 ? 'closed' : 'pending'));
        // The URL opens the authenticated invoice list; the ID confers no access.
        $r['url'] = '/portal/orders#invoice-' . $r['id'];
        unset($r['request_key']);
    }
    return $rows;
}

function invoiceNotify(int $id): void
{
    $q = db()->prepare('SELECT i.*, u.username, u.email, u.telegram_id FROM patch_invoice i
        JOIN user u ON u.id = i.userid WHERE i.id = ?');
    $q->execute([$id]);
    $i = $q->fetch();
    // Use the configured canonical URL, never a request Host header.
    $base = rtrim((string) setting('baseUrl', setting('appUrl', '')), '/');
    if ($base === '') {
        require ROOT . '/config/config.php';
        $base = rtrim((string) ($_ENV['appUrl'] ?? $_ENV['baseUrl'] ?? ''), '/');
    }
    $link = $base . '/portal/orders#invoice-' . $id;
    $text = 'فاکتور #' . $id . ': ' . $i['title'] . "\n"
        . number_format((float) $i['amount']) . ' ریال' . "\n" . $i['description']
        . "\nمشاهده و پرداخت: " . $link;
    $mail = 'off';
    $tg = 'off';
    if (setting('maildriver', '0') === '1' && filter_var($i['email'], FILTER_VALIDATE_EMAIL)) {
        try {
            $q = db()->prepare('INSERT INTO queue_messages (to_email,subject,template,telegramid,time,`array`)
                VALUES (?,?,?,?,?,?)');
            $q->execute([$i['email'], 'فاکتور جدید دیجیتسل', 'patch-invoice.tpl', 0, time(),
                json_encode(['username' => $i['username'], 'title' => 'فاکتور جدید دیجیتسل',
                    'lines' => explode("\n", $text), 'invoice_url' => $link], JSON_UNESCAPED_UNICODE)]);
            $mail = 'queued';
        } catch (Throwable $e) { $mail = 'failed'; error_log('Invoice mail queue failed'); }
    }
    if (setting('telegram', '0') === '1' && !empty($i['telegram_id'])) {
        $tg = 'failed';
        $token = (string) setting('telegramtoken', '');
        if ($token !== '' && function_exists('curl_init')) {
            $ch = curl_init('https://api.telegram.org/bot' . $token . '/sendMessage');
            curl_setopt_array($ch, [CURLOPT_POST => true, CURLOPT_POSTFIELDS => http_build_query([
                'chat_id' => $i['telegram_id'], 'text' => $text]), CURLOPT_RETURNTRANSFER => true,
                CURLOPT_CONNECTTIMEOUT => 4, CURLOPT_TIMEOUT => 10]);
            $result = json_decode((string) curl_exec($ch), true);
            curl_close($ch);
            if (!empty($result['ok'])) { $tg = 'sent'; }
        }
    }
    db()->prepare('UPDATE patch_invoice SET mail_status=?, telegram_status=? WHERE id=?')->execute([$mail, $tg, $id]);
}

function invoiceCreate(int $admin): int
{
    $key = (string) ($_POST['request_key'] ?? '');
    if (!preg_match('/^[a-f0-9]{48}$/D', $key)) { throw new InvoiceException('شناسه درخواست نامعتبر است.'); }
    $q = db()->prepare('SELECT id FROM patch_invoice WHERE adminid=? AND request_key=?');
    $q->execute([$admin, $key]);
    if ($id = $q->fetchColumn()) { return (int) $id; }
    $uid = filter_var($_POST['userid'] ?? '', FILTER_VALIDATE_INT);
    $title = trim((string) ($_POST['title'] ?? ''));
    $description = trim((string) ($_POST['description'] ?? ''));
    $kind = (string) ($_POST['kind'] ?? '');
    if (!$uid || $title === '' || mb_strlen($title) > 200 || mb_strlen($description) > 2000
        || !in_array($kind, ['service', 'plan'], true)) { throw new InvoiceException('اطلاعات فاکتور معتبر نیست.'); }
    $q = db()->prepare('SELECT id,packageid FROM user WHERE id=?');
    $q->execute([$uid]);
    $user = $q->fetch();
    if (!$user) { throw new InvoiceException('کاربر پیدا نشد.'); }
    $plan = 'topup';
    $renew = 0;
    $pdo = db();
    $pdo->beginTransaction();
    try {
        if ($kind === 'plan') {
            $q = $pdo->prepare('SELECT * FROM package WHERE id=? AND status=1 AND type=2 FOR UPDATE');
            $q->execute([(int) ($_POST['packageid'] ?? 0)]);
            $package = $q->fetch();
            if (!$package) { throw new InvoiceException('پلن فعال انتخاب کنید.'); }
            $plan = (string) ($_POST['plan'] ?? '');
            if (!in_array($plan, ['month','quater','semiannual','annual','onetime','custom'], true)) {
                throw new InvoiceException('دوره معتبر انتخاب کنید.');
            }
            $amount = invoicePrice($package, $plan);
            $packageid = (int) $package['id'];
            $renew = !empty($_POST['renew']) ? 1 : 0;
            if ($renew && (int) $user['packageid'] !== $packageid) {
                throw new InvoiceException('برای تمدید، پلن فعلی کاربر را انتخاب کنید.');
            }
        } else {
            $raw = (string) ($_POST['amount'] ?? '');
            if (!preg_match('/^[0-9]{1,12}(?:\.[0-9]{1,2})?$/D', $raw)
                || (float) $raw <= 0 || (float) $raw > 100000000000) {
                throw new InvoiceException('مبلغ را به ریال و با ارقام انگلیسی وارد کنید.');
            }
            $amount = number_format((float) $raw, 2, '.', '');
            // Inactive except inside the checkout transaction. Never publicly buyable.
            $q = $pdo->prepare('INSERT INTO package (type,name,status,price_option,bandwidth,order_note,
                stocks,stockcount,order_type) VALUES (1,?,0,?,0,?,0,100,1)');
            $q->execute([$title, json_encode(['topup' => ['price' => $amount]]),
                json_encode(['serviceinvoice' => ['userid' => $uid]])]);
            $packageid = (int) $pdo->lastInsertId();
        }
        $q = $pdo->prepare('INSERT INTO patch_invoice
            (userid,adminid,title,description,kind,packageid,plan,renew,amount,created,request_key)
            VALUES (?,?,?,?,?,?,?,?,?,?,?)');
        $q->execute([$uid,$admin,$title,$description,$kind,$packageid,$plan,$renew,$amount,time(),$key]);
        $id = (int) $pdo->lastInsertId();
        $pdo->commit();
    } catch (Throwable $e) { $pdo->rollBack(); throw $e; }
    invoiceNotify($id);
    return $id;
}

/** Bootstrap once, retaining the authenticated browser session. Use one PDO so
 * native order creation and invoice attachment commit or roll back together. */
function invoiceBootstrap(): void
{
    global $DB, $i18n, $invoiceNativeApp;
    $held = $_SESSION;
    $level = ob_get_level();
    ob_start();
    try {
        if (!defined('BASE_PATH')) {
            // db() already included config in its own function scope. The
            // console's require_once would skip it, leaving bootstrap's DB
            // settings undefined in this cold web request.
            require ROOT . '/config/config.php';
            require ROOT . '/bin/console.php';
            foreach (get_defined_vars() as $nativeValue) {
                if ($nativeValue instanceof \Slim\App) { $invoiceNativeApp = $nativeValue; break; }
            }
        }
    } finally {
        while (ob_get_level() > $level) { ob_end_clean(); }
        // console.php enables display_errors in debug mode; JSON endpoints
        // must keep notices in the PHP log instead of the response body.
        ini_set('display_errors', '0');
        $_SESSION = $held;
    }
    \Illuminate\Database\Capsule\Manager::connection('default')->setPdo(db());
    \Illuminate\Database\Capsule\Manager::connection('default')->setReadPdo(db());
}

function invoiceCheckout(int $uid, int $id): array
{
    invoiceBootstrap();
    $pdo = db();
    $pdo->beginTransaction();
    try {
        $q = $pdo->prepare('SELECT * FROM patch_invoice WHERE id=? AND userid=? FOR UPDATE');
        $q->execute([$id,$uid]);
        $i = $q->fetch();
        if (!$i || $i['canceled']) { throw new InvoiceException('فاکتور قابل پرداخت نیست.'); }
        $q = $pdo->prepare('SELECT packageid FROM user WHERE id=? FOR UPDATE');
        $q->execute([$uid]);
        $currentPackage = (int) $q->fetchColumn();
        if ($i['kind'] === 'plan' && (int) $i['renew'] === 1 && $currentPackage !== (int) $i['packageid']) {
            throw new InvoiceException('پلن فعلی تغییر کرده؛ از پشتیبانی فاکتور جدید بخواهید.');
        }
        if ($i['orderid']) {
            $order = \App\Http\Models\Order::find($i['orderid']);
            if (!$order || (int) $order->status !== 0) { throw new InvoiceException('این فاکتور پرداخت شده یا بسته شده است.'); }
            $url = $i['checkout_url'];
        } else {
            if (!$pdo->query('SELECT COUNT(*) FROM payments WHERE status=1')->fetchColumn()) {
                throw new InvoiceException('درگاه پرداخت فعالی وجود ندارد.');
            }
            $q = $pdo->prepare('SELECT * FROM package WHERE id=? FOR UPDATE');
            $q->execute([$i['packageid']]);
            $package = $q->fetch();
            if (!$package || invoicePrice($package, $i['plan']) !== $i['amount']) {
                throw new InvoiceException('قیمت پلن تغییر کرده؛ از پشتیبانی فاکتور جدید بخواهید.');
            }
            if ($i['kind'] === 'service') {
                $pdo->prepare('UPDATE package SET status=1 WHERE id=?')->execute([$i['packageid']]);
            } elseif ((int) $package['status'] !== 1) { throw new InvoiceException('پلن غیرفعال است.'); }
            $before = (int) $pdo->query('SELECT COALESCE(MAX(id),0) FROM orders')->fetchColumn();
            $request = \Slim\Psr7\Factory\ServerRequestFactory::createFromGlobals()->withParsedBody([
                'packageid' => $i['packageid'], 'plan' => $i['plan'], 'code' => '',
                'renew' => (int) $i['renew'], 'upgrade' => 0, 'disableactive' => 1]);
            // Standalone endpoints do not run Slim's authentication middleware.
            // Supply only the already authenticated owner, never a POSTed user.
            if (!class_exists('InvoiceCheckoutController', false)) {
                class InvoiceCheckoutController extends \App\Http\Controllers\User\OrderController {
                    public function __construct($user) { parent::__construct(); $this->user = $user; }
                }
            }
            $response = (new InvoiceCheckoutController(\App\Http\Models\User::find($uid)))->save(
                $request, new \Slim\Psr7\Response(), []);
            $result = json_decode((string) $response->getBody(), true);
            if ($i['kind'] === 'service') {
                $pdo->prepare('UPDATE package SET status=0 WHERE id=?')->execute([$i['packageid']]);
            }
            $q = $pdo->prepare('SELECT id,order_id FROM orders WHERE id>? AND userid=? AND packageid=? AND status=0 ORDER BY id DESC LIMIT 1');
            $q->execute([$before,$uid,$i['packageid']]);
            $order = $q->fetch();
            if (!$order && !empty($result['url'])) {
                throw new InvoiceException('ابتدا سفارش پرداخت‌نشده قبلی را پرداخت یا لغو کنید، سپس این فاکتور را باز کنید.');
            }
            if (!$order || empty($result['url'])) {
                throw new InvoiceException(strip_tags((string) ($result['msg'] ?? 'ساخت سفارش پرداخت ممکن نشد.')));
            }
            $parts = parse_url((string) $result['url']);
            $url = (string) ($parts['path'] ?? '');
            if (isset($parts['query'])) { $url .= '?' . $parts['query']; }
            if (strpos($url, '/portal/') !== 0 || strpos($url, '//') === 0) { throw new InvoiceException('نشانی پرداخت معتبر نیست.'); }
            $pdo->prepare('UPDATE patch_invoice SET orderid=?,checkout_url=? WHERE id=?')->execute([$order['id'],$url,$id]);
        }
        $pdo->commit();
        return ['url' => $url];
    } catch (Throwable $e) {
        if ($pdo->inTransaction()) { $pdo->rollBack(); }
        throw $e;
    }
}

if (defined('INVOICE_TEST') || defined('INVOICE_CORE_ONLY')) { return; }
$uid = invoiceSession();
try {
    if ($action === 'invoice.me') { done(['token'=>invoiceToken(),'invoices'=>invoiceRows($uid,false)]); }
    if ($action === 'invoice.checkout') {
        invoiceWrite();
        done(invoiceCheckout($uid, (int) ($_POST['id'] ?? 0)));
    }
    $admin = requireAdmin();
    if ($action === 'invoice.admin') {
        $packages = db()->query('SELECT id,name,price_option FROM package WHERE status=1 AND type=2 ORDER BY sort,id')->fetchAll();
        done(['token'=>invoiceToken(),'request_key'=>bin2hex(random_bytes(24)),
            'packages'=>$packages,'invoices'=>invoiceRows($uid,true)]);
    }
    if ($action === 'invoice.users') {
        $term = trim((string) ($_GET['q'] ?? ''));
        if (mb_strlen($term) < 2) { done(['users'=>[]]); }
        $q = db()->prepare('SELECT id,username,email,packageid FROM user WHERE id=? OR username LIKE ? OR email LIKE ? LIMIT 20');
        $q->execute([(int) $term,'%'.$term.'%','%'.$term.'%']);
        done(['users'=>$q->fetchAll()]);
    }
    invoiceWrite();
    if ($action === 'invoice.create') { done(['id'=>invoiceCreate($admin)]); }
    if ($action === 'invoice.cancel') {
        // Once checkout starts, native order cancellation owns refunds and state.
        $q = db()->prepare('UPDATE patch_invoice SET canceled=1 WHERE id=? AND orderid IS NULL');
        $q->execute([(int) ($_POST['id'] ?? 0)]);
        if (!$q->rowCount()) { throw new InvoiceException('پس از شروع پرداخت، لغو را از مدیریت سفارش‌ها انجام دهید.'); }
        done([]);
    }
    fail('unknown invoice action');
} catch (Throwable $e) {
    error_log('Invoice action failed: ' . $e->getMessage());
    fail($e instanceof InvoiceException ? $e->getMessage() : 'عملیات فاکتور انجام نشد؛ با پشتیبانی تماس بگیرید.');
}
