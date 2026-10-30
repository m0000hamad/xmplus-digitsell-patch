<?php
/** CLI only: real native controllers, with connection-local copies of all rows. */
declare(strict_types=1);
if (PHP_SAPI !== 'cli') exit(1);
$panel=$argv[1]; $source=$argv[2];
require $panel.'/bin/console.php';
require_once $source.'/app/Patch/ProfileBilling.php';
$pdo=Illuminate\Database\Capsule\Manager::connection()->getPdo();
$pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE,PDO::FETCH_ASSOC);
$user=$pdo->query('SELECT * FROM user LIMIT 1')->fetch();
$node=$pdo->query('SELECT * FROM servers LIMIT 1')->fetch();
$settings=$pdo->query('SELECT * FROM settings')->fetchAll();
foreach(['user','servers','settings','trafficlog'] as $table){
    $ddl=$pdo->query('SHOW CREATE TABLE `'.$table.'`')->fetch(PDO::FETCH_NUM)[1];
    $pdo->exec(str_replace('CREATE TABLE','CREATE TEMPORARY TABLE',$ddl));
}
$pdo->exec('CREATE TEMPORARY TABLE profile_traffic_batch(node_id INT,batch_id CHAR(32),digest CHAR(64),created_at BIGINT,PRIMARY KEY(node_id,batch_id)) ENGINE=InnoDB');
function fixtureInsert(string $table,array $row):void{
    global $pdo;
    $pdo->prepare('INSERT INTO `'.$table.'` (`'.implode('`,`',array_keys($row)).'`) VALUES('.implode(',',array_fill(0,count($row),'?')).')')->execute(array_values($row));
}
foreach($settings as $setting)fixtureInsert('settings',$setting);
$pdo->exec("UPDATE settings SET value='0' WHERE name='disable_trafficlog'");
fixtureInsert('user',array_replace($user,['id'=>900001,'username'=>'profile-traffic-fixture','email'=>'fixture@example.invalid','u'=>0,'d'=>0,'total_data_used'=>0]));
fixtureInsert('servers',array_replace($node,['id'=>900001,'name'=>'Profile traffic fixture','server_rate'=>3,'bandwidth'=>0]));
$billing=ProfileBilling::normalize(['enabled'=>true,'ports'=>[1=>1443,2=>2443],'rates'=>[1=>1,2=>4]]);
fixtureInsert('settings',['name'=>'server_profile_billing_history_900001_'.$billing['revision'],'value'=>json_encode($billing)]);
foreach(['XMPlus'=>'userid','XMPlusNew'=>'subscription_id'] as $api=>$idKey){
    $pdo->exec('UPDATE user SET u=0,d=0,total_data_used=0; UPDATE servers SET bandwidth=0; DELETE FROM trafficlog; DELETE FROM profile_traffic_batch');
    require $source.'/app/Http/Controllers/Api/'.$api.'/UserController.php';
    $class='App\\Http\\Controllers\\Api\\'.$api.'\\UserController';
    $request=(new Slim\Psr7\Factory\ServerRequestFactory())->createServerRequest('POST','https://example.invalid/api/traffic/900001')
        ->withParsedBody(['data'=>[[$idKey=>900001,'u'=>100,'d'=>150]]]);
    $response=(new $class)->addTraffic($request,new Slim\Psr7\Response(),['id'=>900001]);
    if((json_decode((string)$response->getBody(),true)['data']??'')!=='ok')throw new RuntimeException('Native traffic API rejected fixture');
    $rows=[];foreach([1,2] as $slot)$rows[]=['subscription_id'=>900001,'profile'=>$slot,'revision'=>$billing['revision'],'u'=>100,'d'=>150];
    $body=['node_id'=>900001,'batch_id'=>str_repeat('a',32),'data'=>$rows];
    ProfileBilling::charge($pdo,$body);
    ProfileBilling::charge($pdo,$body);
    $got=array_map('intval',$pdo->query('SELECT u,d,total_data_used FROM user WHERE id=900001')->fetch(PDO::FETCH_NUM));
    if($got!==[800,1200,2000])throw new RuntimeException('Native and profile accounting did not share the same quota');
    if((int)$pdo->query('SELECT bandwidth FROM servers WHERE id=900001')->fetchColumn()!==750)throw new RuntimeException('Node raw bandwidth mismatch');
    if(array_map('floatval',$pdo->query('SELECT rate FROM trafficlog ORDER BY rate')->fetchAll(PDO::FETCH_COLUMN))!==[1.0,3.0,4.0])throw new RuntimeException('Native traffic logs lost a multiplier');
    echo 'PASS '.$api.' actual schema, atomic native increments, shared profile quota, rates and retry deduplication'.PHP_EOL;
}
