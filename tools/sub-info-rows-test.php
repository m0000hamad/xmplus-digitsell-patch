<?php
declare(strict_types=1);
require __DIR__.'/../patch/app/Patch/SubInfoRows.php';
function infoCheck(bool $value,string $message):void{if(!$value)throw new RuntimeException($message);echo 'PASS '.$message.PHP_EOL;}
function infoRejected(callable $work):bool{try{$work();}catch(InvalidArgumentException $e){return true;}return false;}
$defaults=SubInfoRows::defaults();$profiles=[1=>$defaults,2=>$defaults];
$profiles[1]['rows']['expiry']['text']='Direct {expire_date}';
$profiles[2]['rows']['expiry']['text']='Tunnel {expire_date}';
$profiles[2]['rows']['days']['enabled']=false;
$profiles=SubInfoRows::normalize($profiles);
$values=['expire_date'=>'۱۵ آبان','days_left'=>'۵','remaining_short'=>'۲۰','remaining'=>'۲۰ گیگ','total'=>'۱۰۰ گیگ','used'=>'۸۰ گیگ','balance'=>'۵۰ ریال','updated_time'=>'۱۲:۳۰'];
$visible=SubInfoRows::visibility('plan',2000,false,100,20,false,1000);
$one=SubInfoRows::lines($profiles[1],$values,$visible);$two=SubInfoRows::lines($profiles[2],$values,$visible);
infoCheck(in_array('Direct ۱۵ آبان',$one,true)&&in_array('Tunnel ۱۵ آبان',$two,true),'each subscription keeps its own edited expiry label');
infoCheck(in_array('⏳ ۵ روز مانده',$one,true)&&!in_array('⏳ ۵ روز مانده',$two,true),'unchecking a row applies only to that subscription');
$hidden=$profiles[1];foreach($hidden['rows'] as &$row)$row['enabled']=false;unset($row);
infoCheck(SubInfoRows::lines($hidden,$values,$visible)===[],'all rows can be hidden');
$hidden=$profiles[1];$hidden['enabled']=false;
infoCheck(SubInfoRows::lines($hidden,$values,$visible)===[],'master switch is independent per link');
$legacy=SubInfoRows::lines($defaults,$values,$visible);
infoCheck($legacy===['📅 پایان: ۱۵ آبان','⏳ ۵ روز مانده','📦 ۲۰ از ۱۰۰ گیگ','🔄 به‌روز: ۱۲:۳۰','👆 برای تازه‌شدن آپدیت کنید'],'unconfigured defaults retain the existing active-plan rows');
foreach(['balance'=>'⚡ مصرف از موجودی شارژ','empty'=>'⛔ موجودی تمام؛ شارژ کنید'] as $mode=>$expected){
    $lines=SubInfoRows::lines($defaults,$values,SubInfoRows::visibility($mode,2000,false,100,20,true,1000));
    infoCheck($lines[0]===$expected&&!in_array('📅 پایان: ۱۵ آبان',$lines,true),'wallet '.$mode.' preserves conditional rows');
}
$lines=SubInfoRows::lines($defaults,$values,SubInfoRows::visibility('plan',900,false,100,20,false,1000));
infoCheck($lines[0]==='⛔ بسته تمام شد؛ تمدید کنید','expired-plan condition remains native');
$lines=SubInfoRows::lines($defaults,$values,SubInfoRows::visibility('plan',2000,true,100,0,false,1000));
infoCheck($lines[0]==='📅 بدون تاریخ انقضا'&&$lines[1]==='📦 حجم تمام شد','unlimited date and exhausted traffic preserve separate conditions');
$bad=$profiles;$bad[2]['rows']['expiry']['text']='{unknown}';
infoCheck(infoRejected(function()use($bad){SubInfoRows::normalize($bad);}), 'unknown placeholders reject both profiles before persistence');
$bad=$profiles;$bad[1]['rows']['hint']['text']="hello\r\nInjected: yes";
infoCheck(infoRejected(function()use($bad){SubInfoRows::normalize($bad);}), 'multiline/control input rejected');
$bad=$profiles;unset($bad[2]['rows']['hint']);
infoCheck(infoRejected(function()use($bad){SubInfoRows::normalize($bad);}), 'partial row set rejected');
infoCheck(SubInfoRows::read(json_encode($profiles,JSON_UNESCAPED_UNICODE))===$profiles,'both complete profiles round trip');
