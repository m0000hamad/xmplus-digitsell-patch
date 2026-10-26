<?php
/** Run ONLY with PHP CLI on an installed panel. All commerce/user tables below
 * are connection-local TEMPORARY tables; native payment settlement is additionally
 * rolled back. No gateway request is made and fixture contacts are blank. */
if (PHP_SAPI !== 'cli') { exit(1); }
define('ROOT', $argv[1] ?? getcwd());
define('INVOICE_TEST', true);
function db(): PDO {
    global $pdo;
    if ($pdo instanceof PDO) { return $pdo; }
    // Match the standalone endpoint: config first loads in db()'s local scope.
    require ROOT . '/config/config.php';
    $dsn=!empty($DB['db_socket'])?'mysql:unix_socket='.$DB['db_socket'].';dbname='.$DB['db_database'].';charset=utf8mb4'
        :'mysql:host='.($DB['db_host']??'localhost').';dbname='.$DB['db_database'].';charset=utf8mb4';
    return $pdo=new PDO($dsn,$DB['db_username'],$DB['db_password'],[PDO::ATTR_ERRMODE=>PDO::ERRMODE_EXCEPTION]);
}
function setting(string $name, ?string $fallback=null): ?string {
    if (isset($GLOBALS['invoiceTestSettings'][$name])) { return $GLOBALS['invoiceTestSettings'][$name]; }
    if (in_array($name,['maildriver','telegram'],true)) { return '0'; }
    $q=db()->prepare('SELECT value FROM settings WHERE name=?');$q->execute([$name]);
    $v=$q->fetchColumn();return $v===false?$fallback:(string)$v;
}
require __DIR__ . '/Invoice.php';
function check($ok,string $label): void { if(!$ok) { throw new RuntimeException('FAIL: '.$label); } echo 'PASS: '.$label."\n"; }
$_SESSION=[];
$pdo=db();
$bootstrapWarnings=[];
set_error_handler(static function($level,$message,$file)use(&$bootstrapWarnings){
    if(strpos($file,'bootstrap/settings.php')!==false)$bootstrapWarnings[]=$message;
    return false;
});
ob_start();
try { invoiceBootstrap(); $bootstrapOutput=ob_get_contents(); }
finally { ob_end_clean(); restore_error_handler(); }
check(!$bootstrapWarnings,'cold standalone bootstrap has valid database settings');
check($bootstrapOutput==='' && ini_get('display_errors')==='0','cold bootstrap preserves a clean JSON response');
check(\Illuminate\Database\Capsule\Manager::connection('default')->getPdo()===$pdo,'cold bootstrap shares endpoint PDO');
check(\App\Library\Localization\Localization::get('Orders')!==null,'cold bootstrap exports native translations');
$pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE,PDO::FETCH_ASSOC);
$seed=$pdo->query('SELECT * FROM user ORDER BY id LIMIT 1')->fetch();
foreach(['user','orders','package','queue_messages','payments'] as $table) {
    $ddl=$pdo->query("SHOW CREATE TABLE `$table`")->fetch(PDO::FETCH_NUM)[1];
    $pdo->exec(str_replace('CREATE TABLE','CREATE TEMPORARY TABLE',$ddl));
}
$pdo->exec("INSERT INTO payments (gateway,name,status,config,uuid) VALUES ('test','Test only',1,'{}','invoice-fixture')");
$seed['id']=900000001;$seed['username']='invoice-fixture';$seed['email']='';$seed['telegram_id']=0;
$seed['role']=0;$seed['money']=0;$seed['ref_by']=0;$seed['packageid']=0;
$seed['transfer_enable']=0;$seed['u']=0;$seed['d']=0;$seed['expire_in']='2020-01-01 00:00:00';
$cols=array_keys($seed);
$pdo->prepare('INSERT INTO user (`'.implode('`,`',$cols).'`) VALUES ('.implode(',',array_fill(0,count($cols),'?')).')')->execute(array_values($seed));
$migration=require __DIR__.'/027_invoices.php';
// Convert migration DDL to TEMPORARY without creating persistent schema.
$source=file_get_contents(__DIR__.'/027_invoices.php');
$source=str_replace('CREATE TABLE IF NOT EXISTS','CREATE TEMPORARY TABLE IF NOT EXISTS',$source);
$temp=eval(substr($source,5));$temp($pdo);
$_SESSION=['login_session'=>['uid'=>900000001,'is_admin'=>0,'expire'=>time()+3600]];
$_SERVER['HTTP_HOST']='p.digitsell-shop.ir';$_SERVER['REQUEST_METHOD']='POST';
$_SERVER['SERVER_PORT']=443;$_SERVER['REQUEST_SCHEME']='https';$_SERVER['HTTPS']='on';

require __DIR__.'/CheckoutFunds.php';
foreach(['payg_wallet','commission_wallet','payg_ledger','commission_wallet_log'] as $table){$ddl=$pdo->query("SHOW CREATE TABLE `$table`")->fetch(PDO::FETCH_NUM)[1];$pdo->exec(str_replace('CREATE TABLE','CREATE TEMPORARY TABLE',$ddl));}
$src=file_get_contents(__DIR__.'/028_checkout_funds.php');$migration=eval(substr(str_replace('CREATE TABLE IF NOT EXISTS','CREATE TEMPORARY TABLE IF NOT EXISTS',$src),5));$migration($pdo);
$pdo->exec('UPDATE payments SET id=1,fee_percent=10,fee_fixed=0');
$pdo->exec('INSERT INTO payg_wallet (userid,balance) VALUES (900000001,300000)');
$pdo->exec('INSERT INTO commission_wallet (userid,balance) VALUES (900000001,250000)');
$pdo->exec('UPDATE user SET money=100000');
$_POST=['userid'=>900000001,'kind'=>'service','title'=>'Funds fixture','description'=>'fixture','amount'=>'1000000','request_key'=>bin2hex(random_bytes(24))];
$id=invoiceCreate(1);invoiceCheckout(900000001,$id);
// Make the fixture a subscription for commission eligibility without changing any live package.
$pdo->exec('UPDATE orders SET packagetype=2');
$o=\App\Http\Models\Order::first();$number=$o->order_id;
$f=new CheckoutFunds($pdo,true);
$q=$f->quote(900000001,$number,false,false,'1');
check($q['remaining']===1000000 && $q['wallet_used']===0 && $q['commission_used']===0,'both sources opt out by default, including native account credit');
check($q['fee']===100000 && $q['total']===1100000,'gateway fee applies to remaining principal');
$q=$f->quote(900000001,$number,true,false,'1');
check($q['wallet_used']===300000 && $q['commission_used']===0 && $q['remaining']===700000 && $q['total']===770000,'wallet-only quote excludes all commission, including legacy account credit');
$q=$f->quote(900000001,$number,false,true,'1');
check($q['commission_used']===350000 && $q['wallet_used']===0 && $q['remaining']===650000,'commission-only quote includes legacy commission and excludes usage wallet');
$q=$f->quote(900000001,$number,true,true,'1');
check($q['wallet_used']===300000 && $q['commission_used']===350000 && $q['remaining']===350000 && $q['total']===385000,'both separately classified sources reduce the payable amount and fee');
check((float)$pdo->query('SELECT balance FROM payg_wallet')->fetchColumn()===300000.0,'preview never debits money');
try{$f->reserve(900000002,$number,true,true,'1');throw new RuntimeException('ownership bypass');}catch(CheckoutFundsException $e){check(true,'other user cannot reserve funds');}
try{$f->reserve(900000001,$number,true,true,'1',1.0);throw new RuntimeException('changed quote accepted');}catch(CheckoutFundsException $e){check(true,'stale amount rejected before debit');}
$q=$f->reserve(900000001,$number,true,true,'1',385000);
check((float)$pdo->query('SELECT balance FROM payg_wallet')->fetchColumn()===0.0 && (float)$pdo->query('SELECT balance FROM commission_wallet')->fetchColumn()===0.0,'selected sources reserved atomically');
check((float)$pdo->query('SELECT money FROM user')->fetchColumn()===0.0,'selected native account credit debited once');
$f->reserve(900000001,$number,true,true,'1',385000);
check((int)$pdo->query('SELECT COUNT(*) FROM payg_ledger')->fetchColumn()===1,'repeated Pay does not double debit');
$native=\App\Http\Models\Order::first();
check((float)$native->user_balance===0.0 && (float)$native->total_amount===350000.0,'native order receives only gateway remainder and no second wallet debit');
$pdo->exec('UPDATE orders SET status=-2');$f->reconcile((int)$o->id);$f->reconcile((int)$o->id);
check((float)$pdo->query('SELECT balance FROM payg_wallet')->fetchColumn()===300000.0 && (float)$pdo->query('SELECT balance FROM commission_wallet')->fetchColumn()===250000.0 && (float)$pdo->query('SELECT money FROM user')->fetchColumn()===100000.0,'cancellation returns each source exactly once');
check((int)$pdo->query('SELECT COUNT(*) FROM payg_ledger')->fetchColumn()===2,'refund ledger recorded once');
// A second fixture is fully covered; native settlement must not debit wallets again.
$_POST['request_key']=bin2hex(random_bytes(24));$_POST['amount']='500000';
$id=invoiceCreate(1);invoiceCheckout(900000001,$id);$o=\App\Http\Models\Order::orderBy('id','desc')->first();$pdo->exec('UPDATE orders SET packagetype=2 WHERE id='.(int)$o->id);
$q=$f->reserve(900000001,$o->order_id,true,true,'1');check($q['remaining']===0 && $q['fee']===0,'full wallet coverage needs no gateway or fee');
$u=\App\Http\Models\User::find(900000001);$u->money=0;$controller=new InvoiceCheckoutController($u);
$request=\Slim\Psr7\Factory\ServerRequestFactory::createFromGlobals()->withParsedBody(['order_id'=>$o->order_id,'method'=>-1,'token'=>'']);
$response=$controller->checkout($request,new \Slim\Psr7\Response(),[]);$res=json_decode((string)$response->getBody(),true);
check(!empty($res['ret']),'fully covered order settles through native checkout');
$f->reconcile((int)$o->id);$f->reconcile((int)$o->id);
check($pdo->query('SELECT state FROM checkout_funds WHERE orderid='.(int)$o->id)->fetchColumn()==='spent','successful payment finalizes reservation');
check((float)$pdo->query('SELECT balance FROM commission_wallet')->fetchColumn()===150000.0,'commission is charged once without native double debit');
// A fresh order with both boxes unchecked must preserve every source on paid().
$pdo->exec('UPDATE user SET money=100000');
$_POST['request_key']=bin2hex(random_bytes(24));$_POST['amount']='1000000';
$id=invoiceCreate(1);invoiceCheckout(900000001,$id);$o=\App\Http\Models\Order::orderBy('id','desc')->first();
$cashBefore=$pdo->query('SELECT money FROM user')->fetchColumn();
$commissionBefore=$pdo->query('SELECT balance FROM commission_wallet')->fetchColumn();
$q=$f->reserve(900000001,$o->order_id,false,false,'1');
check($q['wallet_used']===0 && $q['commission_used']===0,'unchecked sources reserve no funds');
(new \App\Services\OrderService(\App\Http\Models\Order::find($o->id)))->paid('opt-out-fixture');
$f->reconcile((int)$o->id);
check($cashBefore===$pdo->query('SELECT money FROM user')->fetchColumn() && $commissionBefore===$pdo->query('SELECT balance FROM commission_wallet')->fetchColumn(),'native settlement preserves unselected funds');
if(is_file(__DIR__.'/funds.tpl')){
    $smarty=new \Smarty();$compile=sys_get_temp_dir().'/checkout-funds-'.bin2hex(random_bytes(6));mkdir($compile,0700);
    $smarty->setCompileDir($compile);$smarty->assign('order',$o);
    $html=$smarty->fetch(__DIR__.'/funds.tpl');
    check(strpos($html,'id="cf-wallet"')!==false && strpos($html,'id="cf-commission"')!==false,'optional source controls render with installed Smarty');
    preg_match_all('~<input[^>]+id="cf-(?:wallet|commission)"[^>]*>~',$html,$inputs);
    check(count($inputs[0])===2 && strpos(implode('',$inputs[0]),'checked')===false,'rendered source controls start unchecked');
    foreach(glob($compile.'/*') as $file)unlink($file);rmdir($compile);
}
echo "ALL CHECKOUT FUNDS CHECKS PASSED\n";
