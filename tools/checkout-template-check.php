<?php
$panel=$argv[1]??getcwd();
require $panel.'/bin/console.php';
error_reporting(E_ALL & ~E_USER_DEPRECATED & ~E_DEPRECATED);
$s=new Smarty();$dir='/tmp/checkout-template-check-'.bin2hex(random_bytes(5));mkdir($dir,0700);$s->setCompileDir($dir);$s->setTemplateDir($panel.'/view');
foreach(['user/plan/commissionuse.tpl','user/plan/plan-details.tpl','user/pay/funds.tpl','user/pay/pay.tpl','user/pay/summary.tpl','user/pay/card2card.tpl','user/dashboard/wallet.tpl'] as $file){
 $t=$s->createTemplate($file);$t->compileTemplateSource();echo 'PASS '.$file."\n";
}
foreach(glob($dir.'/*')?:[] as $f)if(is_file($f))unlink($f);rmdir($dir);
