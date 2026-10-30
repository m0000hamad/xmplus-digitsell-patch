<?php
/** CLI only; connection-local temporary copies protect every production row. */
declare(strict_types=1);
if (PHP_SAPI !== 'cli') exit(1);
$panel=$argv[1];$source=$argv[2];
require $panel.'/bin/console.php';
require_once $source.'/app/Patch/NodeOnline.php';
$db=Illuminate\Database\Capsule\Manager::connection()->getPdo();
$db->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE,PDO::FETCH_ASSOC);
$user=$db->query('SELECT * FROM user LIMIT 1')->fetch();
$server=$db->query('SELECT * FROM servers LIMIT 1')->fetch();
foreach(['user','servers','online_ip'] as $table){
    $ddl=$db->query('SHOW CREATE TABLE `'.$table.'`')->fetch(PDO::FETCH_NUM)[1];
    $db->exec(str_replace('CREATE TABLE','CREATE TEMPORARY TABLE',$ddl));
}
$db->exec('CREATE TEMPORARY TABLE node_profile_online(serverid INT PRIMARY KEY,profile1 INT,profile2 INT,unclassified INT,ready TINYINT,datetime BIGINT) ENGINE=InnoDB');
function insertProfileFixture(string $table,array $row):void{
    global $db;
    $db->prepare('INSERT INTO `'.$table.'` (`'.implode('`,`',array_keys($row)).'`) VALUES('.implode(',',array_fill(0,count($row),'?')).')')->execute(array_values($row));
}
insertProfileFixture('user',array_replace($user,['id'=>900001,'username'=>'online-fixture','email'=>'online@example.invalid']));
foreach([900001,900002] as $id)insertProfileFixture('servers',array_replace($server,['id'=>$id,'name'=>'Online fixture '.$id]));
$base=[['subscription_id'=>900001,'ip'=>'198.51.100.1'],['subscription_id'=>900001,'ip'=>'198.51.100.2']];
$profiles=[['subscription_id'=>900001,'ip'=>'198.51.100.1','profile'=>1],['subscription_id'=>900001,'ip'=>'198.51.100.2','profile'=>1],
    ['subscription_id'=>900001,'ip'=>'198.51.100.1','profile'=>2]];
nodeOnlineSnapshot($db,900001,$base,time(),$profiles,true);
if(array_map('intval',$db->query('SELECT profile1,profile2,ready FROM node_profile_online WHERE serverid=900001')->fetch(PDO::FETCH_NUM))!==[1,1,1])throw new RuntimeException('Profile account counts were not unique');
if((int)$db->query('SELECT COUNT(*) FROM online_ip WHERE serverid=900001')->fetchColumn()!==2)throw new RuntimeException('Native IP membership changed');
nodeOnlineSnapshot($db,900002,$base,time(),$profiles,true);
nodeOnlineSnapshot($db,900001,[],time(),[],true);
if((int)$db->query('SELECT profile1 FROM node_profile_online WHERE serverid=900001')->fetchColumn()!==0
    ||(int)$db->query('SELECT profile1 FROM node_profile_online WHERE serverid=900002')->fetchColumn()!==1)throw new RuntimeException('Empty snapshot crossed node boundaries');
nodeOnlineSnapshot($db,900001,$base,time());
if((int)$db->query('SELECT ready FROM node_profile_online WHERE serverid=900001')->fetchColumn()!==0)throw new RuntimeException('Legacy presence was classified without evidence');
$unknown=$profiles;$unknown[0]['ip']='203.0.113.99';
try{nodeOnlineSnapshot($db,900001,$base,time(),$unknown,true);throw new RuntimeException('Unobserved IP accepted');}catch(InvalidArgumentException $expected){}
echo "PASS native profile presence: distinct accounts, shared IP limits, per-node disconnect, unknown legacy and validation\n";
$smarty=new Smarty();$smarty->setTemplateDir([$source.'/view',$panel.'/view']);
$compile=dirname(__DIR__).'/compile-profile-online';if(!is_dir($compile))mkdir($compile,0700,true);
$smarty->setCompileDir($compile);
$html=$smarty->fetch('admin/servers/profileonline.tpl');
if(strpos($html,'profile-online-counts')===false || strpos($html,"dataSrc() === 'count'")===false)throw new RuntimeException('Native template did not render');
echo "PASS native Smarty profile count template\n";
