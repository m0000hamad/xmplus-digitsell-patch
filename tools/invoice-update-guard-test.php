<?php
// Exercise the actual pre-copy updater guard against compatible and incomplete archives.
$endpoint = file_get_contents(__DIR__ . '/../patch/public/xmplus-patch.php');
$start = strpos($endpoint, '    // An upstream archive must preserve installed invoice support.');
$end = strpos($endpoint, '    // ---- keep what is there now', $start);
if ($start === false || $end === false) { throw new RuntimeException('Invoice update guard missing'); }
$guard = substr($endpoint, $start, $end - $start);
$base = sys_get_temp_dir() . '/invoice-guard-' . bin2hex(random_bytes(6));
define('ROOT', $base . '/live');
$source = $base . '/archive';
$unpacked = $source;
$created = [];
function fixture(string $file, string $text): void {
    global $created;
    if (!is_dir(dirname($file))) { mkdir(dirname($file), 0700, true); }
    file_put_contents($file, $text); $created[] = $file;
}
class InvoiceUpdateBlocked extends RuntimeException {}
function fail(string $message): void { throw new InvoiceUpdateBlocked($message); }
function removeTree(string $path): void { $GLOBALS['cleaned'] = true; }
try {
    fixture(ROOT . '/app/Patch/Invoice.php', '<?php');
    fixture($source . '/patch/public/xmplus-patch.php', '<?php // old release');
    $blocked = false;
    try { eval($guard); } catch (InvoiceUpdateBlocked $e) { $blocked = true; }
    if (!$blocked || empty($GLOBALS['cleaned'])) { throw new RuntimeException('Incomplete update was not blocked'); }
    echo "PASS: incomplete upstream archive rejected before file replacement\n";
    fixture($source . '/patch/public/xmplus-patch.php', $endpoint);
    fixture($source . '/patch/view/common/invoices.tpl', 'invoice form');
    fixture($source . '/patch/view/user/layout/usermenu.tpl', "{include file='user/layout/invoicenotice.tpl'}");
    eval($guard);
    echo "PASS: archive retaining invoice integration accepted\n";
    fixture(ROOT . '/app/Patch/CheckoutFunds.php', '<?php');
    $blocked = false;
    try { eval($guard); } catch (InvoiceUpdateBlocked $e) { $blocked = true; }
    if (!$blocked) { throw new RuntimeException('Update losing checkout refunds accepted'); }
    echo "PASS: archive losing payment reservations/refunds rejected\n";
    fixture($source . '/patch/app/Console/Commands/TaskCommand.php', 'CheckoutFundsJob');
    fixture($source . '/patch/view/user/pay/funds.tpl', 'funds controls');
    fixture($source . '/patch/bin/checkout-funds.php', '<?php');
    eval($guard);
    echo "PASS: archive retaining payment reservations/refunds accepted\n";
    fixture(ROOT . '/app/Patch/AdminUserBalances.php', '<?php');
    $blocked = false;
    try { eval($guard); } catch (InvoiceUpdateBlocked $e) { $blocked = true; }
    if (!$blocked) { throw new RuntimeException('Update losing independent balance editor accepted'); }
    echo "PASS: archive losing independent balance editor rejected\n";
    fixture($source . '/patch/view/admin/users/edit.tpl', 'userbalances.save');
    fixture($source . '/patch/app/Patch/AdminUserBalances.php', '<?php');
    fixture($source . '/patch/view/admin/users/balances.tpl', 'independent balances');
    eval($guard);
    echo "PASS: archive retaining independent balance editor accepted\n";
} finally {
    foreach (array_unique($created) as $file) { if (is_file($file)) { unlink($file); } }
    $dirs = [];
    foreach ($created as $file) {
        for ($dir = dirname($file); strpos($dir, $base) === 0; $dir = dirname($dir)) { $dirs[$dir] = true; }
    }
    $dirs = array_keys($dirs);
    usort($dirs, static function ($a, $b) { return strlen($b) <=> strlen($a); });
    foreach ($dirs as $dir) { if (is_dir($dir)) { rmdir($dir); } }
}
