<?php
/** Native Smarty render tests; only connection-local settings are changed. */
declare(strict_types=1);
if (PHP_SAPI !== 'cli') exit(1);
$panel=$argv[1]; $source=$argv[2];
require $panel.'/vendor/autoload.php';
require $source.'/app/Provider/ConfigProvider.php';
require $source.'/app/Http/Models/User.php';
require $panel.'/bin/console.php';
error_reporting(E_ALL & ~E_USER_DEPRECATED & ~E_DEPRECATED);
$pdo=Illuminate\Database\Capsule\Manager::connection()->getPdo();
$ddl=$pdo->query('SHOW CREATE TABLE settings')->fetch(PDO::FETCH_NUM)[1];
$pdo->exec(str_replace('CREATE TABLE','CREATE TEMPORARY TABLE',$ddl));
function setProfiles(array $profiles): void {
    global $pdo;
    $pdo->exec('DELETE FROM settings');
    $pdo->prepare('INSERT INTO settings(name,value) VALUES(?,?)')->execute(['sub_profiles',json_encode($profiles)]);
}
$profiles=[['enabled'=>true,'name'=>'Direct <script>bad()</script>','description'=>"First line\n<b>plain text</b>",'groups'=>[2],'servers'=>[11]],
    ['enabled'=>true,'name'=>'Tunnel','description'=>'Other description','groups'=>[2,4],'servers'=>[12]]];
$s=new Smarty(); $s->setTemplateDir([$source.'/view',$panel.'/view']);
$s->setCompileDir($source.'/compile');
$s->assign('translate',new class { public function get($key){return $key;} });
$clients=[];
foreach(['Clash'=>'?clash=1','Shadowrocket'=>'?shadowrocket=1','Surfboard'=>'?surfboard=1','Stash'=>'?stash=1','QuantumultX'=>'quantumultx=1'] as $name=>$link) {
    $clients[]=(object)['type'=>'windows','client'=>$name,'link'=>$link,'icon'=>'','url'=>'https://example.invalid','uuid'=>0];
}
$s->assign('clients',$clients);
$s->assign('SubUrl','https://sub.example/link/fixture_token_123');
function renderGroup(int $group): string {
    global $s;
    $user=new App\Http\Models\User();$user->server_group=$group;
    $s->assign('user',$user);$s->assign('Config',(new App\Provider\ConfigProvider())->get());
    return $s->fetch('application.tpl');
}
function check($ok,string $message): void {if(!$ok)throw new RuntimeException($message);echo 'PASS '.$message."\n";}
setProfiles($profiles);$html=renderGroup(2);
check(substr_count($html,'class="app-link-field"')===10,'shared group sees both profiles for all apps');
check(strpos($html,'&profile=1&quantumultx=1')!==false,'format selector without question mark is normalized');
check(strpos($html,'<script>bad()</script>')===false && strpos($html,'&lt;script&gt;bad()&lt;/script&gt;')!==false,'editable titles escaped');
check(strpos($html,'&lt;b&gt;plain text&lt;/b&gt;')!==false,'descriptions are plain text');
$dom=new DOMDocument();@$dom->loadHTML('<?xml encoding="UTF-8">'.$html);$xp=new DOMXPath($dom);
$lists=$xp->query('//div[contains(concat(" ",normalize-space(@class)," ")," app-profile-list ")]');
check($lists->length===5,'one profile list per application');
foreach($lists as $list) {
    $cards=$xp->query('./article[contains(@class,"app-profile")]',$list);
    check($cards->length===2,'both subscription cards are consecutive');
    foreach($cards as $card) {
        check($xp->query('./h5[contains(@class,"app-profile-title")]/following-sibling::p[contains(@class,"app-profile-description")][1]',$card)->length===1,'subscription title immediately precedes its description');
        check($xp->query('.//a[contains(@class,"app-btn-get")]',$card)->length===0,'no download button between subscription cards');
    }
    check($xp->query('following-sibling::div[contains(@class,"app-download")][1]//a[contains(@class,"app-btn-get")]',$list)->length===1,'one download below both subscriptions');
}
check($xp->query('//a[contains(@class,"app-btn-get")]')->length===5,'download is not duplicated per profile');

foreach($xp->query('//input[contains(@class,"app-link-field")]') as $input) {
    check(strpos($input->getAttribute('value'),'do=sub&t=fixture_token_123&profile=')!==false,'copy field uses profile URL');
}
foreach($xp->query('//a[contains(@class,"app-btn-import")][@href]') as $link) {
    check(strpos(urldecode($link->getAttribute('href')),'&profile=')!==false,'native import uses profile URL');
}
check(substr_count(renderGroup(4),'class="app-link-field"')===5,'distinct group sees only its selected profile');
check(substr_count(renderGroup(99),'class="app-link-field"')===0,'unselected group has no link');
$profiles[1]['enabled']=false;setProfiles($profiles);
check(substr_count(renderGroup(4),'class="app-link-field"')===0,'disabled profile hidden');
setProfiles([]);$html=renderGroup(99);
check(substr_count($html,'class="app-link-field"')===5 && strpos($html,'&profile=')===false,'unconfigured feature retains legacy links');
$s->fetch('subprofiles.tpl');echo "PASS admin settings render\n";
$s->createTemplate('admin-edit.tpl')->compileTemplateSource();echo "PASS admin user edit compiles\n";
