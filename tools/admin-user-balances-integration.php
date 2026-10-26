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

require __DIR__.'/AdminUserBalances.php';
foreach(['payg_wallet','commission_wallet','payg_ledger','commission_wallet_log'] as $table){$ddl=$pdo->query("SHOW CREATE TABLE `$table`")->fetch(PDO::FETCH_NUM)[1];$pdo->exec(str_replace('CREATE TABLE','CREATE TEMPORARY TABLE',$ddl));}
$src=file_get_contents(__DIR__.'/029_admin_balance_edits.php');$migration=eval(substr(str_replace('CREATE TABLE IF NOT EXISTS','CREATE TEMPORARY TABLE IF NOT EXISTS',$src),5));$migration($pdo);
$adminSeed=$seed;$adminSeed['id']=900000002;$adminSeed['role']=1;$adminSeed['username']='balance-admin-fixture';$adminSeed['email']='admin@example.invalid';
if(array_key_exists('uuid',$adminSeed))$adminSeed['uuid']='01234567-0123-4123-8123-012345678901';
if(array_key_exists('token',$adminSeed))$adminSeed['token']=bin2hex(random_bytes(16));
$pdo->prepare('INSERT INTO user (`'.implode('`,`',$cols).'`) VALUES ('.implode(',',array_fill(0,count($cols),'?')).')')->execute(array_values($adminSeed));
$pdo->exec('INSERT INTO payg_wallet (userid,balance) VALUES (900000001,500000)');
$pdo->exec('INSERT INTO commission_wallet (userid,balance) VALUES (900000001,100000)');
$pdo->exec('UPDATE user SET money=300000 WHERE id=900000001');
$_SESSION['login_session']=['uid'=>900000002,'is_admin'=>1,'expire'=>time()+3600];
$_SESSION['locale']='fa_IR';
class BalanceProfileFixtureController extends \App\Http\Controllers\Admin\UserController {public function __construct($user){parent::__construct();$this->user=$user;}}
function nativeProfile(string $legacy): array {
 $data=['id'=>900000001,'status'=>1,'role'=>0,'email'=>'balance-fixture@example.invalid','passwd'=>'','money'=>$legacy,
  'transfer_enable'=>0,'server_group'=>1,'speedlimit'=>0,'iplimit'=>2,'expire_in'=>date('Y-m-d H:i:s',time()+86400),'payout_balance'=>0,'rebate'=>10];
 // Match the complete browser POST, rather than a profile-only fixture.
 $data+=['token'=>'fixture-csrf-not-a-user-token','request_key'=>bin2hex(random_bytes(24)),
  'wallet_changed'=>'1','commission_changed'=>'0','wallet_balance'=>'555555','commission_balance'=>'775375.00',
  'expected_wallet'=>'0.00','expected_legacy'=>'340000.00','expected_dedicated'=>'435375.00','balance_reason'=>'fixture'];
 $_POST=$data;
 $data=AdminUserBalances::nativeProfileData($data,$legacy);
 if(isset($data['token'])||isset($data['request_key'])||isset($data['wallet_balance']))throw new RuntimeException('Auxiliary fields forwarded to native profile save');
 $request=AdminUserBalances::nativeRequest($data);
 $response=(new BalanceProfileFixtureController(\App\Http\Models\User::find(900000002)))->save($request,new \Slim\Psr7\Response(),[]);
 return json_decode((string)$response->getBody(),true);
}
$b=new AdminUserBalances($pdo);
function inputFor(AdminUserBalances $b,bool $wallet,bool $commission,string $w,string $c): array {
 $o=$b->read(900000001);return ['wallet_changed'=>$wallet?'1':'0','commission_changed'=>$commission?'1':'0',
 'wallet_balance'=>$w,'commission_balance'=>$c,'expected_wallet'=>$o['wallet_balance'],'expected_legacy'=>$o['legacy'],
 'expected_dedicated'=>$o['dedicated'],'request_key'=>bin2hex(random_bytes(24)),'balance_reason'=>'fixture'];
}
$r=$b->read(900000001);check($r['wallet_balance']==='500000.00' && $r['commission_balance']==='400000.00','edit reads usage wallet separately from total commission');
$input=inputFor($b,true,true,'800000','650000');
$originalToken=$pdo->query('SELECT token FROM user WHERE id=900000001')->fetchColumn();
$r=$b->save(900000002,900000001,$input,'nativeProfile');
check((int)$r['ret']===1,'real native profile save participates in the balance transaction');
check($originalToken===$pdo->query('SELECT token FROM user WHERE id=900000001')->fetchColumn(),'full browser POST saves without auxiliary columns or changing user token');
$r=$b->read(900000001);check($r['wallet_balance']==='800000.00' && $r['commission_balance']==='650000.00' && $r['legacy']==='300000.00' && $r['dedicated']==='350000.00','both balances set absolutely with legacy commission preserved');
check((int)$pdo->query('SELECT COUNT(*) FROM admin_balance_edit')->fetchColumn()===1,'balance edit records audit');
$b->save(900000002,900000001,$input,function(){throw new RuntimeException('duplicate native save');});
check((int)$pdo->query('SELECT COUNT(*) FROM payg_ledger')->fetchColumn()===1 && (int)$pdo->query('SELECT COUNT(*) FROM commission_wallet_log')->fetchColumn()===1,'retry does not duplicate balance changes or ledger entries');
$input=inputFor($b,true,false,'950000','0');$pdo->exec('UPDATE user SET money=350000 WHERE id=900000001');
$b->save(900000002,900000001,$input,'nativeProfile');
$r=$b->read(900000001);check($r['wallet_balance']==='950000.00' && $r['legacy']==='350000.00' && $r['commission_balance']==='700000.00','wallet-only edit preserves concurrent commission credit');
$input=inputFor($b,false,true,'0','200000');$b->save(900000002,900000001,$input,'nativeProfile');
$r=$b->read(900000001);check($r['wallet_balance']==='950000.00' && $r['commission_balance']==='200000.00' && $r['legacy']==='200000.00' && $r['dedicated']==='0.00','commission reduction never touches usage wallet');
$input=inputFor($b,true,false,'1','0');$pdo->exec('UPDATE payg_wallet SET balance=balance+1 WHERE userid=900000001');
try{$b->save(900000002,900000001,$input,'nativeProfile');throw new RuntimeException('stale edit accepted');}catch(AdminUserBalanceException $e){check(true,'stale wallet value is rejected');}
$before=$b->read(900000001);$audit=(int)$pdo->query('SELECT COUNT(*) FROM admin_balance_edit')->fetchColumn();
$input=inputFor($b,true,true,'1','1');
try{$b->save(900000002,900000001,$input,function($legacy)use($pdo){$pdo->exec("UPDATE user SET email='must-rollback@example.invalid' WHERE id=900000001");return ['ret'=>0,'msg'=>'fixture native failure'];});throw new RuntimeException('profile failure accepted');}catch(AdminUserBalanceException $e){check(true,'native failure is reported');}
check($before===$b->read(900000001) && $audit===(int)$pdo->query('SELECT COUNT(*) FROM admin_balance_edit')->fetchColumn(),'native failure rolls back balances and audit together');
check($pdo->query('SELECT email FROM user WHERE id=900000001')->fetchColumn()==='balance-fixture@example.invalid','native profile changes roll back with balances');
try{$b->save(900000001,900000001,inputFor($b,true,false,'0','0'),'nativeProfile');throw new RuntimeException('non-admin accepted');}catch(AdminUserBalanceException $e){check(true,'non-admin cannot edit balances');}
$pdo->exec('UPDATE user SET role=2 WHERE id=900000002');
try{$b->save(900000002,900000001,inputFor($b,true,false,'0','0'),'nativeProfile');throw new RuntimeException('staff balance edit accepted');}catch(AdminUserBalanceException $e){check(true,'non-root staff cannot edit balances');}
check(AdminUserBalances::parse('۱۲۳٬۴۵۶٫۷۸')===12345678,'Persian amounts parse without unit confusion');
try{AdminUserBalances::parse('-1');throw new RuntimeException('negative target accepted');}catch(AdminUserBalanceException $e){check(true,'negative final balances rejected');}
$pdo->exec('UPDATE user SET role=1 WHERE id=900000002');
$fresh=$b->read(900000002);
$freshInput=['wallet_changed'=>'1','commission_changed'=>'1','wallet_balance'=>'100000','commission_balance'=>'200000',
 'expected_wallet'=>$fresh['wallet_balance'],'expected_legacy'=>$fresh['legacy'],'expected_dedicated'=>$fresh['dedicated'],'request_key'=>bin2hex(random_bytes(24))];
$b->save(900000002,900000002,$freshInput,function(){return ['ret'=>1];});
$fresh=$b->read(900000002);
check($fresh['wallet_balance']==='100000.00' && $fresh['commission_balance']==='200000.00','users without wallet rows can receive independent balances');
$freshInput['wallet_balance']='0';$freshInput['commission_balance']='0';$freshInput['expected_wallet']=$fresh['wallet_balance'];$freshInput['expected_legacy']=$fresh['legacy'];$freshInput['expected_dedicated']=$fresh['dedicated'];$freshInput['request_key']=bin2hex(random_bytes(24));
$b->save(900000002,900000002,$freshInput,function(){return ['ret'=>1];});
$fresh=$b->read(900000002);check($fresh['wallet_balance']==='0.00' && $fresh['commission_balance']==='0.00','explicit zero clears both balances independently');
echo "ALL ADMIN BALANCE CHECKS PASSED\n";
