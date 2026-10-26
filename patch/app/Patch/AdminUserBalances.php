<?php
declare(strict_types=1);
class AdminUserBalanceException extends RuntimeException {}

/** Absolute balance edits share a transaction with the native profile save.
 * Only explicitly changed controls can alter balances. Legacy commission is
 * never posted as an editable native money field or mixed into usage credit. */
final class AdminUserBalances
{
    private $db;
    public function __construct(PDO $db){$this->db=$db;}
    public static function nativeProfileData(array $input,string $legacy): array {
        // Native save mass-assigns its parsed body. Auxiliary form/CSRF fields
        // must never become user columns (including the real user.token).
        $allowed=['id','status','role','email','passwd','transfer_enable','server_group',
            'speedlimit','iplimit','expire_in','payout_balance','rebate'];
        $data=array_intersect_key($input,array_flip($allowed));
        $data['money']=$legacy;
        return $data;
    }
    public static function nativeRequest(array $data) {
        global $invoiceNativeApp;
        if(!$invoiceNativeApp instanceof \Slim\App)throw new RuntimeException('Native application context missing');
        $request=\Slim\Psr7\Factory\ServerRequestFactory::createFromGlobals()->withMethod('POST')->withParsedBody($data);
        $request=$request->withUri($request->getUri()->withPath('/admin/user/save')->withQuery(''));
        $routing=new \Slim\Middleware\RoutingMiddleware($invoiceNativeApp->getRouteResolver(),$invoiceNativeApp->getRouteCollector()->getRouteParser());
        return $routing->performRouting($request);
    }
    private function one(string $sql,array $params=[]): ?array {
        $q=$this->db->prepare($sql);$q->execute($params);$r=$q->fetch(PDO::FETCH_ASSOC);return $r===false?null:$r;
    }
    private function exec(string $sql,array $params=[]): void {$this->db->prepare($sql)->execute($params);}
    private function cents($v): int {return (int)round((float)$v*100);}
    private function money(int $v): string {return number_format($v/100,2,'.','');}
    public static function parse(string $raw): int {
        $s=strtr(trim($raw),['۰'=>'0','۱'=>'1','۲'=>'2','۳'=>'3','۴'=>'4','۵'=>'5','۶'=>'6','۷'=>'7','۸'=>'8','۹'=>'9',
            '٠'=>'0','١'=>'1','٢'=>'2','٣'=>'3','٤'=>'4','٥'=>'5','٦'=>'6','٧'=>'7','٨'=>'8','٩'=>'9','٫'=>'.']);
        $s=str_replace([',','٬','،',' '], '',$s);
        if(!preg_match('/^[0-9]{1,12}(?:\.[0-9]{1,2})?$/D',$s)||(float)$s>100000000000){
            throw new AdminUserBalanceException('موجودی نهایی را به ریال، صفر یا بیشتر و با حداکثر دو رقم اعشار وارد کنید.');
        }
        return (int)round((float)$s*100);
    }
    public function read(int $uid): array {
        $u=$this->one('SELECT money FROM user WHERE id=?',[$uid]);if(!$u)throw new AdminUserBalanceException('کاربر پیدا نشد.');
        $w=$this->one('SELECT balance FROM payg_wallet WHERE userid=?',[$uid]);
        $c=$this->one('SELECT balance FROM commission_wallet WHERE userid=?',[$uid]);
        return ['wallet_balance'=>$this->money($this->cents($w['balance']??0)),
            'commission_balance'=>$this->money($this->cents($u['money'])+$this->cents($c['balance']??0)),
            'legacy'=>$this->money($this->cents($u['money'])),'dedicated'=>$this->money($this->cents($c['balance']??0))];
    }
    public function save(int $admin,int $uid,array $input,callable $nativeSave): array {
        $changeWallet=($input['wallet_changed']??'0')==='1';$changeCommission=($input['commission_changed']??'0')==='1';
        $key=(string)($input['request_key']??'');
        if(!preg_match('/^[a-f0-9]{48}$/D',$key))throw new AdminUserBalanceException('شناسه ذخیره معتبر نیست؛ صفحه را تازه کنید.');
        $targetWallet=$changeWallet?self::parse((string)($input['wallet_balance']??'')):null;
        $targetCommission=$changeCommission?self::parse((string)($input['commission_balance']??'')):null;
        $this->db->beginTransaction();
        try{
            $role=$this->one('SELECT role FROM user WHERE id=?',[$admin]);
            if(!$role||(int)$role['role']<=0)throw new AdminUserBalanceException('دسترسی مدیر لازم است.');
            if(($changeWallet||$changeCommission)&&(int)$role['role']!==1)throw new AdminUserBalanceException('فقط مدیر اصلی می‌تواند موجودی را تغییر دهد.');
            $prior=$this->one('SELECT userid FROM admin_balance_edit WHERE adminid=? AND request_key=?',[$admin,$key]);
            if($prior){
                if((int)$prior['userid']!==$uid)throw new AdminUserBalanceException('شناسه ذخیره تکراری است.');
                $this->db->commit();return ['ret'=>1,'msg'=>'این تغییر قبلاً ثبت شده است.'];
            }
            // Same lock order as checkout and billing: usage, commission, user.
            $w=$this->one('SELECT balance FROM payg_wallet WHERE userid=? FOR UPDATE',[$uid]);
            $c=$this->one('SELECT balance FROM commission_wallet WHERE userid=? FOR UPDATE',[$uid]);
            $u=$this->one('SELECT money FROM user WHERE id=? FOR UPDATE',[$uid]);
            if(!$u)throw new AdminUserBalanceException('کاربر پیدا نشد.');
            $oldWallet=$this->cents($w['balance']??0);$oldLegacy=$this->cents($u['money']);$oldCommission=$this->cents($c['balance']??0);
            if($changeWallet && (string)($input['expected_wallet']??'')!==$this->money($oldWallet))throw new AdminUserBalanceException('موجودی کیف پول از زمان باز شدن صفحه تغییر کرده است؛ صفحه را تازه کنید.');
            if($changeCommission && ((string)($input['expected_legacy']??'')!==$this->money($oldLegacy)||(string)($input['expected_dedicated']??'')!==$this->money($oldCommission)))throw new AdminUserBalanceException('موجودی پورسانت از زمان باز شدن صفحه تغییر کرده است؛ صفحه را تازه کنید.');
            $newWallet=$targetWallet??$oldWallet;$newLegacy=$oldLegacy;$newCommission=$oldCommission;
            if($changeCommission){
                if($oldLegacy<0||$oldCommission<0)throw new AdminUserBalanceException('مانده قدیمی پورسانت منفی است؛ ابتدا گردش حساب را بررسی کنید.');
                $delta=$targetCommission-$oldLegacy-$oldCommission;
                if($delta>=0)$newCommission+=$delta;
                else{$fromDedicated=min($oldCommission,-$delta);$newCommission-=$fromDedicated;$newLegacy-=(-$delta-$fromDedicated);}
            }
            $now=time();$note=trim((string)($input['balance_reason']??''));if($note==='')$note='ویرایش موجودی از فرم کاربر';
            $note=mb_substr($note.' · admin #'.$admin,0,250);$ref='user-edit:'.substr(hash('sha256',$admin.':'.$key),0,48);
            $dw=$newWallet-$oldWallet;$dc=$newCommission-$oldCommission;
            if($dw){
                if(!$w)$this->exec('INSERT INTO payg_wallet (userid,updated) VALUES (?,?)',[$uid,$now]);
                $this->exec('UPDATE payg_wallet SET balance=?,adjusted=adjusted+?,updated=? WHERE userid=?',[$this->money($newWallet),$this->money($dw),$now,$uid]);
                $this->exec("INSERT INTO payg_ledger (userid,kind,ref,amount,balance_after,serverid,bytes,free_bytes,rate,note,created,updated) VALUES (?,'adjust',?,?,?,0,0,0,0,?,?,?)",[$uid,$ref,$this->money($dw),$this->money($newWallet),$note,$now,$now]);
            }
            if($dc){
                if(!$c)$this->exec('INSERT INTO commission_wallet (userid,updated) VALUES (?,?)',[$uid,$now]);
                $this->exec('UPDATE commission_wallet SET balance=?,earned=earned+?,updated=? WHERE userid=?',[$this->money($newCommission),$this->money(max(0,$dc)),$now,$uid]);
                $this->exec("INSERT INTO commission_wallet_log (userid,kind,ref,amount,balance_after,note,created) VALUES (?,'adjust',?,?,?,?,?)",[$uid,$ref,$this->money($dc),$this->money($newCommission),$note,$now]);
            }
            if($newLegacy!==$oldLegacy)$this->exec('UPDATE user SET money=? WHERE id=?',[$this->money($newLegacy),$uid]);
            // The native controller must receive the freshly locked legacy
            // component, never the editable aggregate commission amount.
            $result=$nativeSave($this->money($newLegacy));
            if(!is_array($result)||(int)($result['ret']??0)!==1){
                $msg=strip_tags((string)($result['msg']??'اطلاعات کاربر ذخیره نشد.'));
                if(stripos($msg,'SQLSTATE')!==false || stripos($msg,'SQL:')!==false){error_log('Native profile save failed: '.$msg);$msg='ذخیره اطلاعات کاربر انجام نشد؛ با پشتیبانی تماس بگیرید.';}
                throw new AdminUserBalanceException($msg);
            }
            if(!$this->db->inTransaction())throw new RuntimeException('Native profile save ended the enclosing transaction');
            $actual=$this->one('SELECT money FROM user WHERE id=?',[$uid]);
            if(!$actual || $this->cents($actual['money'])!==$newLegacy)throw new RuntimeException('Native profile save changed protected legacy commission');
            // A record also makes retry of a successful absolute edit idempotent.
            if($changeWallet||$changeCommission)$this->exec('INSERT INTO admin_balance_edit (adminid,userid,request_key,wallet_before,wallet_after,legacy_before,legacy_after,commission_before,commission_after,reason,created) VALUES (?,?,?,?,?,?,?,?,?,?,?)',
                [$admin,$uid,$key,$this->money($oldWallet),$this->money($newWallet),$this->money($oldLegacy),$this->money($newLegacy),$this->money($oldCommission),$this->money($newCommission),$note,$now]);
            $this->db->commit();return $result;
        }catch(Throwable $e){if($this->db->inTransaction())$this->db->rollBack();throw $e;}
    }
}
