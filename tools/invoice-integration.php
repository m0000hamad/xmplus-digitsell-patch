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
$_POST=['userid'=>900000001,'kind'=>'service','title'=>'Fixture service','description'=>'fixture',
    'amount'=>'1000000','request_key'=>bin2hex(random_bytes(24))];
$id=invoiceCreate(1);
check(invoiceCreate(1)===$id,'duplicate creation returns same invoice');
$i=$pdo->query('SELECT * FROM patch_invoice')->fetch();
check((int)$pdo->query('SELECT status FROM package')->fetchColumn()===0,'service package is private');
try { invoiceCheckout(900000002,$id); throw new RuntimeException('ownership bypass'); }
catch(RuntimeException $e) { check($e->getMessage()!=='ownership bypass','other user denied'); }
$result=invoiceCheckout(900000001,$id);
check(!empty($result['url']),'native service checkout returns URL');
echo 'CHECKOUT_PATH: '.parse_url($result['url'],PHP_URL_PATH)."\n";
check(invoiceCheckout(900000001,$id)===$result,'repeated checkout reuses order');
check((int)$pdo->query('SELECT COUNT(*) FROM orders')->fetchColumn()===1,'only one order created');
check((int)$pdo->query('SELECT status FROM package')->fetchColumn()===0,'service package remains private');
$before=$pdo->query('SELECT money,packageid,transfer_enable,u,d,expire_in,server_group FROM user')->fetch();
$pdo->beginTransaction();
try {
    $order=\App\Http\Models\Order::first();
    $service=new \App\Services\OrderService($order);
    $service->paid('invoice-fixture-no-gateway');
    $after=$pdo->query('SELECT money,packageid,transfer_enable,u,d,expire_in,server_group FROM user')->fetch();
    check($before===$after,'service settlement leaves balance and subscription unchanged');
    check((int)$pdo->query('SELECT status FROM orders')->fetchColumn()===1,'native settlement marks paid');
    check(invoiceRows(900000001,false)[0]['status']==='paid','invoice follows native paid status');
} finally { if($pdo->inTransaction())$pdo->rollBack(); }
$pdo->exec('UPDATE orders SET status=-2');
$pdo->exec("INSERT INTO package (type,name,status,price_option,bandwidth,order_note,stocks,stockcount,order_type,renew_type,reset_days,server_group)
 VALUES (2,'Fixture plan',1,'{\"month\":{\"price\":\"2000000\"}}',5,'',0,100,1,1,0,1)");
$pid=(int)$pdo->lastInsertId();
$_POST=['userid'=>900000001,'kind'=>'plan','title'=>'Fixture plan','description'=>'fixture',
    'packageid'=>$pid,'plan'=>'month','renew'=>0,'request_key'=>bin2hex(random_bytes(24))];
$id=invoiceCreate(1);
$result=invoiceCheckout(900000001,$id);
check(!empty($result['url']),'subscription invoice enters native checkout');
$pdo->beginTransaction();
try {
    $order=\App\Http\Models\Order::orderBy('id','desc')->first();
    (new \App\Services\OrderService($order))->paid('invoice-plan-fixture');
    $user=\App\Http\Models\User::find(900000001);
    check((int)$user->packageid===$pid && (float)$user->transfer_enable>0,'subscription settlement provisions service');
    check(strtotime($user->expire_in)>time(),'subscription settlement sets future expiry');
} finally { if($pdo->inTransaction())$pdo->rollBack(); }
$pdo->exec('UPDATE orders SET status=-2');
$pdo->exec('UPDATE user SET money=4000000');
$_POST=['userid'=>900000001,'kind'=>'service','title'=>'Fixture with balance','description'=>'fixture',
    'amount'=>'1000000','request_key'=>bin2hex(random_bytes(24))];
$id=invoiceCreate(1);
$result=invoiceCheckout(900000001,$id);
check(!empty($result['url']),'invoice checkout supports accounts with existing balance');
$pdo->exec('UPDATE orders SET status=-2');
$pdo->exec('UPDATE user SET money=0,packageid='.$pid.',transfer_enable=5368709120,expire_in=DATE_ADD(NOW(),INTERVAL 10 DAY)');
$pdo->exec('UPDATE orders SET status=1,pay_date=UNIX_TIMESTAMP(),expire=UNIX_TIMESTAMP()+864000 WHERE packageid='.$pid);
$_POST=['userid'=>900000001,'kind'=>'plan','title'=>'Fixture renewal','description'=>'fixture',
    'packageid'=>$pid,'plan'=>'month','renew'=>1,'request_key'=>bin2hex(random_bytes(24))];
$id=invoiceCreate(1);
$activeBefore=$pdo->query('SELECT id,status FROM orders WHERE status=1 ORDER BY id')->fetchAll();
$result=invoiceCheckout(900000001,$id);
check(!empty($result['url']),'renewal invoice enters native checkout');
check($activeBefore===$pdo->query('SELECT id,status FROM orders WHERE status=1 ORDER BY id')->fetchAll(),'renewal checkout leaves current subscription active until payment');
$expiry=$pdo->query('SELECT expire_in FROM user')->fetchColumn();
$pdo->beginTransaction();
try {
    $order=\App\Http\Models\Order::orderBy('id','desc')->first();
    (new \App\Services\OrderService($order))->paid('invoice-renew-fixture');
    $newExpiry=$pdo->query('SELECT expire_in FROM user')->fetchColumn();
    check(strtotime($newExpiry)>strtotime($expiry),'renewal settlement extends subscription');
} finally { if($pdo->inTransaction())$pdo->rollBack(); }
$pdo->exec('UPDATE orders SET status=-2 WHERE status=0');
$_POST=['userid'=>900000001,'kind'=>'service','title'=>'Active account service','description'=>'fixture',
    'amount'=>'1000000','request_key'=>bin2hex(random_bytes(24))];
$id=invoiceCreate(1);
$before=$pdo->query('SELECT money,packageid,transfer_enable,u,d,expire_in,server_group FROM user')->fetch();
invoiceCheckout(900000001,$id);
check($before===$pdo->query('SELECT money,packageid,transfer_enable,u,d,expire_in,server_group FROM user')->fetch(),'service checkout preserves active subscription');
$pdo->beginTransaction();
try {
    (new \App\Services\OrderService(\App\Http\Models\Order::orderBy('id','desc')->first()))->paid('active-fixture');
    check($before===$pdo->query('SELECT money,packageid,transfer_enable,u,d,expire_in,server_group FROM user')->fetch(),'service settlement preserves active subscription');
} finally { if($pdo->inTransaction())$pdo->rollBack(); }
$pdo->exec("UPDATE user SET email='invoice@example.invalid'");
$GLOBALS['invoiceTestSettings']=['maildriver'=>'1'];
invoiceNotify($id);
$mail=$pdo->query('SELECT * FROM queue_messages ORDER BY id DESC LIMIT 1')->fetch();
check($mail && $mail['template']==='patch-invoice.tpl','invoice email enters existing queue');
$data=json_decode($mail['array'],true);
check(strpos($data['invoice_url'],'https://')===0 && strpos($data['invoice_url'],'/portal/orders#invoice-')!==false,'notification uses canonical authenticated invoice link');
if (is_file(__DIR__.'/invoices.tpl') && is_file(__DIR__.'/patch-invoice.tpl')) {
    $smarty=new \Smarty();
    $compile=sys_get_temp_dir().'/digitsell-invoice-smarty-'.bin2hex(random_bytes(6));
    mkdir($compile,0700);
    $smarty->setCompileDir($compile);
    foreach($data as $k=>$v) { $smarty->assign($k,$v); }
    check(strpos($smarty->fetch(__DIR__.'/invoices.tpl'),'di-form')!==false,'invoice UI compiles with installed Smarty');
    check(strpos($smarty->fetch(__DIR__.'/patch-invoice.tpl'),'https://')!==false,'invoice email renders payment link');
    foreach(glob($compile.'/*') as $file) { unlink($file); }
    rmdir($compile);
}
echo "ALL INVOICE CHECKS PASSED\n";
