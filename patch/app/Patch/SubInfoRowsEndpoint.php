<?php
declare(strict_types=1);
require_once __DIR__.'/SubInfoRows.php';
if($action==='subprofiles.inforows.save'){
    if(($_SERVER['REQUEST_METHOD']??'')!=='POST')fail('POST required',405);
    requireToken();
    $value=json_decode((string)($_POST['profiles']??''),true);
    if(!is_array($value))fail('تنظیمات معتبر نیست.');
    try{$profiles=SubInfoRows::normalize($value);}catch(InvalidArgumentException $error){fail($error->getMessage());}
    try{putSetting('sub_info_profile_rows',json_encode($profiles,JSON_UNESCAPED_UNICODE));}
    catch(Throwable $error){fail('تنظیمات ذخیره نشد.');}
    done(['saved'=>true]);
}
if($action!=='subprofiles.inforows.get')fail('Unknown info-row action');
$fallback=SubInfoRows::defaults(setting('sub_info_enabled','1')!=='0');
$profiles=SubInfoRows::read((string)setting('sub_info_profile_rows',''))??[1=>$fallback,2=>$fallback];
$links=SubscriptionProfiles::read((string)setting('sub_profiles','[]'));
done(['profiles'=>(object)$profiles,'definitions'=>SubInfoRows::definitions(),'tokens'=>SubInfoRows::tokens(),
    'titles'=>[$links[0]['name']??'لینک ۱',$links[1]['name']??'لینک ۲'],
    'token'=>($_SESSION['patch_csrf']??($_SESSION['patch_csrf']=bin2hex(random_bytes(24))))]);
