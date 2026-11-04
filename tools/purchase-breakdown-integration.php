<?php
namespace App\Jobs {
    function curl_init($url) { return fopen('php://memory','r+'); }
    function curl_setopt_array($ch,$options) { $GLOBALS['purchase_test_sends']++; return true; }
    function curl_exec($ch) { return '{"ok":true}'; }
    function curl_close($ch) { fclose($ch); }
}
namespace {
require ($argv[1] ?? '/www/wwwroot/p.digitsell-shop.ir').'/bin/console.php';
$db=\Illuminate\Database\Capsule\Manager::connection('default')->getPdo();
foreach(['settings','orders','checkout_funds','purchase_breakdown_notice'] as $t){$create=$db->query('SHOW CREATE TABLE `'.$t.'`')->fetch(\PDO::FETCH_NUM);$db->exec(str_replace('CREATE TABLE','CREATE TEMPORARY TABLE',$create[1]));}
$db->exec("INSERT INTO settings(name,value) VALUES ('telegram','1'),('telegramtoken','fake'),('telegramchatid','123'),('purchase_breakdown_since','100')");
$db->exec("INSERT INTO orders(id,order_id,package_amount,discount,total_amount,user_balance,gateway_fee,pay_date,status) VALUES (1,'TEST',1000,0,1100,0,100,101,1),(2,'OLD',1000,0,1100,0,100,99,1),(3,'PENDING',1000,0,1100,0,100,0,0)");
$GLOBALS['purchase_test_sends']=0;
$j=new \App\Jobs\PurchaseBreakdownJob();$j->dispatch();$j->dispatch();
if($GLOBALS['purchase_test_sends']!==1)throw new \RuntimeException('Delivery/dedup/cutoff failed');
if($db->query("SELECT state FROM purchase_breakdown_notice WHERE orderid=1")->fetchColumn()!=='sent')throw new \RuntimeException('State failed');
echo "PASS live runtime: one paid notice, no duplicate, historical/pending excluded; Telegram mocked\n";
}


