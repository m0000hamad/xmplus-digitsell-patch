<?php
declare(strict_types=1);
define('INVOICE_CORE_ONLY',true);
require_once ROOT.'/app/Patch/Invoice.php';
require_once ROOT.'/app/Patch/AdminUserBalances.php';
$admin=requireAdmin();
$uid=(int)($_POST['id']??$_GET['id']??0);
$balances=new AdminUserBalances(db());
try{
    if($action==='userbalances.get'){
        $q=db()->prepare('SELECT role FROM user WHERE id=?');$q->execute([$admin]);
        done($balances->read($uid)+['editable'=>(int)$q->fetchColumn()===1,'token'=>invoiceToken(),'request_key'=>bin2hex(random_bytes(24))]);
    }
    invoiceWrite();if($action!=='userbalances.save')throw new AdminUserBalanceException('عملیات معتبر نیست.');
    invoiceBootstrap();
    class UserBalanceNativeController extends \App\Http\Controllers\Admin\UserController {
        public function __construct($user){parent::__construct();$this->user=$user;}
    }
    $result=$balances->save($admin,$uid,$_POST,function(string $legacy)use($admin){
        $data=AdminUserBalances::nativeProfileData($_POST,$legacy);
        $request=AdminUserBalances::nativeRequest($data);
        $response=(new UserBalanceNativeController(\App\Http\Models\User::find($admin)))->save($request,new \Slim\Psr7\Response(),[]);
        return json_decode((string)$response->getBody(),true);
    });
    echo json_encode($result,JSON_UNESCAPED_UNICODE|JSON_UNESCAPED_SLASHES);
}catch(Throwable $e){
    error_log('Admin balance edit: '.$e->getMessage());
    $msg=$e instanceof AdminUserBalanceException?$e->getMessage():'ذخیره انجام نشد؛ با پشتیبانی تماس بگیرید.';
    echo json_encode(['ok'=>false,'ret'=>0,'msg'=>$msg,'error'=>$msg],JSON_UNESCAPED_UNICODE);
}
