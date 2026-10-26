<?php
declare(strict_types=1);
define('INVOICE_CORE_ONLY',true);
require_once ROOT.'/app/Patch/Invoice.php';
require_once ROOT.'/app/Patch/CheckoutFunds.php';
$uid=invoiceSession();
$number=(string)($_POST['order_id']??$_GET['order_id']??'');
$useWallet=(string)($_POST['use_wallet']??$_GET['use_wallet']??'0')==='1';
$useCommission=(string)($_POST['use_commission']??$_GET['use_commission']??'0')==='1';
$method=(string)($_POST['method']??$_GET['method']??'');
$funds=new CheckoutFunds(db(),setting('commission_wallet_enabled','0')==='1');
try{
    if($action==='funds.quote'){
        $q=$funds->quote($uid,$number,$useWallet,$useCommission,$method);
        $gateways=db()->query('SELECT id,name FROM payments WHERE status=1 ORDER BY id')->fetchAll(PDO::FETCH_ASSOC);
        done($q+['token'=>invoiceToken(),'gateways'=>$gateways]);
    }
    invoiceWrite();
    if(!in_array($action,['funds.pay','funds.reserve'],true))throw new CheckoutFundsException('عملیات پرداخت معتبر نیست.');
    $q=$funds->quote($uid,$number,$useWallet,$useCommission,$method);
    if($q['remaining']>0 && ($method==='' || $method==='-1'))throw new CheckoutFundsException('برای مبلغ باقی‌مانده درگاه انتخاب کنید.');
    $lock='checkout-funds:'.$uid.':'.hash('sha256',$number);
    // MySQL names have a 64-character limit.
    $lock=substr($lock,0,64);
    $stmt=db()->prepare('SELECT GET_LOCK(?,10)');$stmt->execute([$lock]);
    if((int)$stmt->fetchColumn()!==1)throw new CheckoutFundsException('پرداخت در حال پردازش است؛ دوباره تلاش کنید.');
    try{
        $expected=isset($_POST['expected_total']) && is_numeric($_POST['expected_total'])?(float)$_POST['expected_total']:null;
        if($expected===null)throw new CheckoutFundsException('مبلغ پرداخت را دوباره محاسبه کنید.');
        $q=$funds->reserve($uid,$number,$useWallet,$useCommission,$method,$expected);
        if($action==='funds.reserve')done($q);
        if($method==='c2c' && $q['remaining']>0)throw new CheckoutFundsException('پرداخت کارت‌به‌کارت را از پنجره مربوط انجام دهید.');
        invoiceBootstrap();
        class FundsNativeController extends \App\Http\Controllers\User\OrderController {
            public function __construct($user){parent::__construct();$user->money=0;$this->user=$user;}
        }
        $controller=new FundsNativeController(\App\Http\Models\User::find($uid));
        $req=\Slim\Psr7\Factory\ServerRequestFactory::createFromGlobals()->withParsedBody([
            'order_id'=>$number,'method'=>$q['remaining']<=0?-1:$method,'token'=>'']);
        $res=$controller->checkout($req,new \Slim\Psr7\Response(),[]);
        $body=json_decode((string)$res->getBody(),true);
        $stmt=db()->prepare('SELECT id FROM orders WHERE userid=? AND order_id=?');$stmt->execute([$uid,$number]);
        $funds->reconcile((int)$stmt->fetchColumn());
        if(!is_array($body))throw new CheckoutFundsException('پاسخ درگاه معتبر نیست.');
        // Existing payment UI expects the native ret/type/data schema.
        echo json_encode($body,JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES);
    }finally{$stmt=db()->prepare('SELECT RELEASE_LOCK(?)');$stmt->execute([$lock]);}
}catch(Throwable $e){
    error_log('Checkout funds: '.$e->getMessage());
    echo json_encode(['ok'=>false,'ret'=>0,'error'=>$e instanceof CheckoutFundsException?$e->getMessage():'محاسبه موجودی انجام نشد.',
        'msg'=>$e instanceof CheckoutFundsException?$e->getMessage():'محاسبه موجودی انجام نشد.'],JSON_UNESCAPED_UNICODE);
}
