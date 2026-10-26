<?php
declare(strict_types=1);

/** Order-bound wallet reservations. Gateway callbacks remain native. Quotes
 * never alter balances or native order amounts. Money is reserved only at Pay,
 * and returned to its exact source after native cancellation/expiry. */
class CheckoutFundsException extends RuntimeException {}
final class CheckoutFunds
{
    private $db;
    private $commission;
    public function __construct(PDO $db, bool $commission) { $this->db=$db; $this->commission=$commission; }
    private function one(string $sql,array $args=[]): ?array {
        $q=$this->db->prepare($sql);$q->execute($args);$r=$q->fetch(PDO::FETCH_ASSOC);return $r===false?null:$r;
    }
    private function exec(string $sql,array $args=[]): void { $this->db->prepare($sql)->execute($args); }
    private function cents($n): int { return (int) round((float)$n*100); }
    private function amount(int $n): string { return number_format($n/100,2,'.',''); }
    private function order(int $uid,string $number,bool $lock=false): array {
        $o=$this->one('SELECT * FROM orders WHERE userid=? AND order_id=?'.($lock?' FOR UPDATE':''),[$uid,$number]);
        if(!$o)throw new CheckoutFundsException('سفارش پیدا نشد.');
        if((int)$o['status']!==0)throw new CheckoutFundsException('سفارش پرداخت شده یا بسته شده است.');
        return $o;
    }
    private function sourceBalances(int $uid,bool $lock=false): array {
        $suffix=$lock?' FOR UPDATE':'';
        $w=$this->one('SELECT balance FROM payg_wallet WHERE userid=?'.$suffix,[$uid]);
        $c=$this->one('SELECT balance FROM commission_wallet WHERE userid=?'.$suffix,[$uid]);
        $u=$this->one('SELECT money FROM user WHERE id=?'.$suffix,[$uid]);
        if(!$u)throw new CheckoutFundsException('کاربر پیدا نشد.');
        return ['wallet'=>max(0,$this->cents($w['balance']??0)),
            'commission'=>max(0,$this->cents($c['balance']??0)), 'cash'=>max(0,$this->cents($u['money']))];
    }
    private function calculate(array $o,array $balances,?array $hold,bool $wallet,bool $commission,string $method): array {
        $frozen=$hold && $hold['state']==='reserved';
        // Legacy account credit has not yet been debited. Undo its implicit
        // allocation in the preview; selection is now explicit.
        $base=$hold?$this->cents($hold['base_amount']):max(0,$this->cents($o['total_amount'])+$this->cents($o['user_balance'])-$this->cents($o['gateway_fee']));
        $restrictedEligible=$this->commission && (int)$o['packagetype']===2;
        $package=$this->one('SELECT order_note FROM package WHERE id=?',[$o['packageid']]);
        $walletEligible=strpos((string)($package['order_note']??''),'"paygcharge"')===false;
        if($frozen){
            $cash=$this->cents($hold['cash_amount']);$used=$this->cents($hold['wallet_amount']);$comm=$this->cents($hold['commission_amount']);
            $wallet=(bool)$hold['use_wallet'];$commission=(bool)$hold['use_commission'];
            $balances['cash']+=$cash;$balances['wallet']+=$used;$balances['commission']+=$comm;
        }else{
            $used=$wallet && $walletEligible?min($base,$balances['wallet']):0;
            // user.money is the panel's legacy commission credit, not usage
            // wallet money. It follows the commission checkbox exclusively.
            $cash=$commission?min($base-$used,$balances['cash']):0;
            $comm=$commission && $restrictedEligible?min($base-$used-$cash,$balances['commission']):0;
        }
        $eligible=$balances['cash']>0 || $restrictedEligible;
        $remaining=max(0,$base-$cash-$used-$comm);$fee=0;
        if($remaining>0 && $method!=='' && $method!=='c2c' && $method!=='-1'){
            $gateway=$this->one('SELECT fee_percent,fee_fixed FROM payments WHERE id=? AND status=1',[(int)$method]);
            if(!$gateway)throw new CheckoutFundsException('درگاه پرداخت فعال نیست.');
            $fee=max(0,(int)round($remaining*(float)$gateway['fee_percent']/100)+$this->cents($gateway['fee_fixed']));
        }
        return ['base'=>$base/100,'wallet_balance'=>$balances['wallet']/100,
            'commission_balance'=>($balances['commission']+$balances['cash'])/100,'commission_eligible'=>$eligible,'wallet_eligible'=>$walletEligible,
            'wallet_used'=>$used/100,'commission_used'=>($cash+$comm)/100,'remaining'=>$remaining/100,
            'fee'=>$fee/100,'total'=>($remaining+$fee)/100,'frozen'=>(bool)$frozen,
            'use_wallet'=>$wallet,'use_commission'=>$commission,'cash_amount'=>$cash/100,'payg_amount'=>$used/100,'commission_amount'=>$comm/100];
    }
    public function quote(int $uid,string $number,bool $wallet,bool $commission,string $method): array {
        $o=$this->order($uid,$number);$h=$this->one('SELECT * FROM checkout_funds WHERE orderid=?',[$o['id']]);
        return $this->calculate($o,$this->sourceBalances($uid),$h,$wallet,$commission,$method);
    }
    public function reserve(int $uid,string $number,bool $wallet,bool $commission,string $method,?float $expectedTotal=null): array {
        $this->db->beginTransaction();
        try{
            $o=$this->order($uid,$number,true);
            $h=$this->one('SELECT * FROM checkout_funds WHERE orderid=? FOR UPDATE',[$o['id']]);
            if($h && $h['state']!=='reserved')throw new CheckoutFundsException('سفارش قابل پرداخت نیست.');
            $b=$this->sourceBalances($uid,true);
            $q=$this->calculate($o,$b,$h,$wallet,$commission,$method);
            if($expectedTotal!==null && $this->cents($expectedTotal)!==$this->cents($q['total'])){
                throw new CheckoutFundsException('موجودی یا مبلغ تغییر کرده است؛ محاسبه را تازه و دوباره تأیید کنید.');
            }
            if($h){$this->db->commit();return $q;}
            // Never change the amount of an already issued gateway request.
            if(!empty($o['pay_url']) || !empty($o['gateway_create']) || !empty($o['callback_no'])){
                throw new CheckoutFundsException('پرداخت این سفارش قبلاً شروع شده است؛ آن را تکمیل یا لغو کنید.');
            }
            if($commission && !$q['commission_eligible'] && $b['commission']>0){
                throw new CheckoutFundsException('پورسانت فقط برای خرید و تمدید اشتراک قابل استفاده است.');
            }
            if($wallet && !$q['wallet_eligible'])throw new CheckoutFundsException('شارژ کیف پول با موجودی همان کیف پول ممکن نیست.');
            $cash=$this->cents($q['cash_amount']);$used=$this->cents($q['payg_amount']);$comm=$this->cents($q['commission_amount']);$now=time();
            $this->exec('INSERT INTO checkout_funds (orderid,userid,base_amount,cash_amount,wallet_amount,commission_amount,use_wallet,use_commission,state,created,updated) VALUES (?,?,?,?,?,?,?,?,\'reserved\',?,?)',
                [$o['id'],$uid,$q['base'],$this->amount($cash),$this->amount($used),$this->amount($comm),(int)$wallet,(int)$commission,$now,$now]);
            if($cash)$this->exec('UPDATE user SET money=money-? WHERE id=?',[$this->amount($cash),$uid]);
            if($used){
                $this->exec('UPDATE payg_wallet SET balance=balance-?,spent=spent+?,updated=? WHERE userid=?',[$this->amount($used),$this->amount($used),$now,$uid]);
                $this->walletLog($uid,'purchase','checkout:'.$o['id'],-$used,$b['wallet']-$used,'پرداخت سفارش #'.$o['id']);
            }
            if($comm){
                $this->exec('UPDATE commission_wallet SET balance=balance-?,spent=spent+?,updated=? WHERE userid=?',[$this->amount($comm),$this->amount($comm),$now,$uid]);
                $this->commissionLog($uid,'purchase','checkout:'.$o['id'],-$comm,$b['commission']-$comm,'پرداخت سفارش #'.$o['id']);
            }
            // Native paid() debits user_balance from user.money. These sources
            // are already debited above, so do not let it debit them again.
            $this->exec('UPDATE orders SET user_balance=0,total_amount=?,gateway_fee=0 WHERE id=?',[$q['remaining'],$o['id']]);
            $this->db->commit();return $q;
        }catch(Throwable $e){if($this->db->inTransaction())$this->db->rollBack();throw $e;}
    }
    private function walletLog(int $uid,string $kind,string $ref,int $amount,int $balance,string $note): void {
        $this->exec('INSERT INTO payg_ledger (userid,kind,ref,amount,balance_after,serverid,bytes,free_bytes,rate,note,created,updated) VALUES (?,?,?,?,?,0,0,0,0,?,?,?)',
            [$uid,$kind,$ref,$this->amount($amount),$this->amount($balance),$note,time(),time()]);
    }
    private function commissionLog(int $uid,string $kind,string $ref,int $amount,int $balance,string $note): void {
        $this->exec('INSERT INTO commission_wallet_log (userid,kind,ref,amount,balance_after,note,created) VALUES (?,?,?,?,?,?,?)',
            [$uid,$kind,$ref,$this->amount($amount),$this->amount($balance),$note,time()]);
    }
    public function reconcile(int $orderid): void {
        $this->db->beginTransaction();
        try{
            $o=$this->one('SELECT status FROM orders WHERE id=? FOR UPDATE',[$orderid]);
            $h=$this->one('SELECT * FROM checkout_funds WHERE orderid=? FOR UPDATE',[$orderid]);
            if(!$o || !$h || $h['state']!=='reserved'){$this->db->commit();return;}
            if((int)$o['status']===1){$this->exec("UPDATE checkout_funds SET state='spent',updated=? WHERE orderid=?",[time(),$orderid]);}
            elseif((int)$o['status']<0){
                $uid=(int)$h['userid'];$b=$this->sourceBalances($uid,true);
                $cash=$this->cents($h['cash_amount']);$used=$this->cents($h['wallet_amount']);$comm=$this->cents($h['commission_amount']);
                if($cash)$this->exec('UPDATE user SET money=money+? WHERE id=?',[$this->amount($cash),$uid]);
                if($used){
                    $this->exec('UPDATE payg_wallet SET balance=balance+?,spent=spent-?,updated=? WHERE userid=?',[$this->amount($used),$this->amount($used),time(),$uid]);
                    $this->walletLog($uid,'refund','checkout-refund:'.$orderid,$used,$b['wallet']+$used,'برگشت سفارش #'.$orderid);
                }
                if($comm){
                    $this->exec('UPDATE commission_wallet SET balance=balance+?,spent=spent-?,updated=? WHERE userid=?',[$this->amount($comm),$this->amount($comm),time(),$uid]);
                    $this->commissionLog($uid,'refund','checkout-refund:'.$orderid,$comm,$b['commission']+$comm,'برگشت سفارش #'.$orderid);
                }
                $this->exec("UPDATE checkout_funds SET state='returned',updated=? WHERE orderid=?",[time(),$orderid]);
            }
            $this->db->commit();
        }catch(Throwable $e){if($this->db->inTransaction())$this->db->rollBack();throw $e;}
    }
    public function reconcileAll(): void {
        $rows=$this->db->query("SELECT f.orderid FROM checkout_funds f JOIN orders o ON o.id=f.orderid WHERE f.state='reserved' AND (o.status=1 OR o.status<0) ORDER BY f.orderid LIMIT 500");
        foreach($rows->fetchAll(PDO::FETCH_ASSOC) as $r)$this->reconcile((int)$r['orderid']);
    }
}
