<?php
require __DIR__.'/../patch/app/Patch/PurchaseBreakdown.php';
$o=['order_id'=>'TEST','package_amount'=>3870000,'discount'=>0,'user_balance'=>0,'gateway_fee'=>387000,'total_amount'=>4257000];
function check($yes){if(!$yes)throw new RuntimeException('Failed');}
$t=PurchaseBreakdown::text($o,null);check(strpos($t,'4,257,000 ریال')!==false);check(strpos($t,'تعدیل')===false);
$o['discount']=100000;$o['gateway_fee']=277000;$o['total_amount']=3047000;
$h=['wallet_amount'=>500000,'cash_amount'=>200000,'commission_amount'=>300000];
$t=PurchaseBreakdown::text($o,$h);check(strpos($t,'کسر پورسانت: 500,000 ریال')!==false);check(strpos($t,'تعدیل')===false);
$o['total_amount']=0;$o['gateway_fee']=0;$h['wallet_amount']=3770000;$h['cash_amount']=0;$h['commission_amount']=0;
check(strpos(PurchaseBreakdown::text($o,$h),'تعدیل')===false);
$o['total_amount']=100;check(strpos(PurchaseBreakdown::text($o,$h),'تعدیل مبلغ سفارش: +100 ریال')!==false);
$o['user_balance']=500000;$o['discount']=0;$o['total_amount']=3370000;
check(strpos(PurchaseBreakdown::text($o,null),'تعدیل')===false);
echo "PASS: gateway fee, mixed funding, full wallet, adjustment, legacy commission\n";
