<?php
declare(strict_types=1);

/** Plain-text information rows; placeholders never execute code. */
final class SubInfoRows
{
    public static function definitions(): array
    {
        return [
            'balance_mode'=>['label'=>'مصرف از موجودی شارژ','text'=>'⚡ مصرف از موجودی شارژ'],
            'empty_wallet'=>['label'=>'تمام‌شدن موجودی','text'=>'⛔ موجودی تمام؛ شارژ کنید'],
            'expired'=>['label'=>'تمام‌شدن اشتراک','text'=>'⛔ بسته تمام شد؛ تمدید کنید'],
            'never'=>['label'=>'اشتراک بدون انقضا','text'=>'📅 بدون تاریخ انقضا'],
            'expiry'=>['label'=>'تاریخ پایان','text'=>'📅 پایان: {expire_date}'],
            'days'=>['label'=>'روزهای باقی‌مانده','text'=>'⏳ {days_left} روز مانده'],
            'traffic'=>['label'=>'حجم باقی‌مانده و کل','text'=>'📦 {remaining_short} از {total}'],
            'traffic_empty'=>['label'=>'تمام‌شدن حجم','text'=>'📦 حجم تمام شد'],
            'used'=>['label'=>'حجم مصرف‌شده','text'=>'📊 مصرف: {used}','enabled'=>false],
            'wallet'=>['label'=>'موجودی کیف پول','text'=>'💰 موجودی: {balance}'],
            'updated'=>['label'=>'زمان به‌روزرسانی','text'=>'🔄 به‌روز: {updated_time}'],
            'hint'=>['label'=>'پیام راهنما','text'=>'👆 برای تازه‌شدن آپدیت کنید'],
        ];
    }

    public static function tokens(): array
    {
        return ['expire_date','days_left','remaining','remaining_short','total','used','balance','updated_time'];
    }

    public static function defaults(bool $enabled = true): array
    {
        $rows=[];
        foreach(self::definitions() as $key=>$definition) $rows[$key]=['enabled'=>$definition['enabled']??true,'text'=>$definition['text']];
        return ['enabled'=>$enabled,'rows'=>$rows];
    }

    public static function normalize(array $profiles): array
    {
        if(count($profiles)!==2 || !isset($profiles[1],$profiles[2])) throw new InvalidArgumentException('تنظیمات هر دو لینک لازم است.');
        $out=[];$keys=array_keys(self::definitions());
        foreach([1,2] as $slot){
            $profile=$profiles[$slot];
            if(!is_array($profile) || !is_bool($profile['enabled']??null) || !is_array($profile['rows']??null)
                || count($profile['rows'])!==count($keys) || array_diff($keys,array_keys($profile['rows']))) throw new InvalidArgumentException('تنظیمات ردیف‌های لینک معتبر نیست.');
            $out[$slot]=['enabled'=>$profile['enabled'],'rows'=>[]];
            foreach($keys as $key){
                $row=$profile['rows'][$key];
                if(!is_array($row) || !is_bool($row['enabled']??null) || !is_string($row['text']??null)) throw new InvalidArgumentException('تنظیمات ردیف معتبر نیست.');
                $text=trim($row['text']);
                if(strlen($text)>800 || preg_match('//u',$text)!==1 || preg_match('/[\x00-\x1F\x7F]/',$text)
                    || ($row['enabled'] && $text==='')) throw new InvalidArgumentException('متن ردیف باید کوتاه و تک‌خطی باشد.');
                preg_match_all('/\{([^{}]+)\}/u',$text,$matches);
                if(array_diff($matches[1],self::tokens())) throw new InvalidArgumentException('جای‌نگهدار ناشناخته در متن ردیف وجود دارد.');
                $out[$slot]['rows'][$key]=['enabled'=>$row['enabled'],'text'=>$text];
            }
        }
        return $out;
    }

    public static function read(string $json): ?array
    {
        $value=json_decode($json,true);
        if(!is_array($value))return null;
        try{return self::normalize($value);}catch(InvalidArgumentException $error){return null;}
    }

    public static function lines(array $profile, array $values, array $visible): array
    {
        if(empty($profile['enabled']))return [];
        $replace=[];foreach(self::tokens() as $token)$replace['{'.$token.'}']=(string)($values[$token]??'');
        $lines=[];
        foreach(self::definitions() as $key=>$definition){
            $row=$profile['rows'][$key];
            if(!empty($row['enabled']) && !empty($visible[$key]))$lines[]=strtr($row['text'],$replace);
        }
        return $lines;
    }

    public static function visibility(string $mode,int $expire,bool $never,float $quota,float $left,bool $walletOn,int $now): array
    {
        $expired=!in_array($mode,['balance','empty'],true) && $expire>0 && $expire<=$now;
        $plan=!in_array($mode,['balance','empty'],true) && !$expired;
        $empty=$quota>0 && $left<=0;
        return ['balance_mode'=>$mode==='balance','empty_wallet'=>$mode==='empty','expired'=>$expired,
            'never'=>$plan && $never,'expiry'=>$plan && !$never && $expire>0,
            'days'=>$plan && !$never && $expire>0,'traffic'=>$plan && !$empty,
            'traffic_empty'=>$plan && $empty,'used'=>true,'wallet'=>$walletOn,'updated'=>true,'hint'=>true];
    }
}
