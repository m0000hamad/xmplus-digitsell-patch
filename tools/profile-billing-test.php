<?php
declare(strict_types=1);
require __DIR__ . '/../patch/app/Patch/ProfileBilling.php';
$native = isset($argv[1]);
if ($native) {
    require $argv[1] . '/config/config.php';
    $dsn = !empty($DB['db_socket']) ? 'mysql:unix_socket='.$DB['db_socket'].';dbname='.$DB['db_database'] : 'mysql:host='.$DB['db_host'].';dbname='.$DB['db_database'];
    $db = new PDO($dsn,$DB['db_username'],$DB['db_password'],[PDO::ATTR_ERRMODE=>PDO::ERRMODE_EXCEPTION]);
} else $db = new PDO('sqlite::memory:', null, null, [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]);
$ddl = 'CREATE TABLE settings(name VARCHAR(191) PRIMARY KEY,value TEXT);
CREATE TABLE servers(id INTEGER PRIMARY KEY,name TEXT,bandwidth INTEGER DEFAULT 0);
CREATE TABLE user(id INTEGER PRIMARY KEY,username TEXT,email TEXT,u INTEGER DEFAULT 0,d INTEGER DEFAULT 0,total_data_used INTEGER DEFAULT 0,t INTEGER);
CREATE TABLE trafficlog(userid INTEGER,username TEXT,serverid INTEGER,email TEXT,u INTEGER,d INTEGER,servername TEXT,rate REAL,total INTEGER,datetime INTEGER);
CREATE TABLE profile_traffic_batch(node_id INTEGER,batch_id VARCHAR(32),digest VARCHAR(64),created_at INTEGER,PRIMARY KEY(node_id,batch_id));
INSERT INTO servers(id,name) VALUES(25,"Fixture"); INSERT INTO user(id,username,email) VALUES(7,"fixture","fixture@example.invalid")';
$db->exec($native ? str_replace('CREATE TABLE','CREATE TEMPORARY TABLE',$ddl) : $ddl);
function check($value, string $message): void { if (!$value) throw new RuntimeException($message); echo "PASS $message\n"; }
function rejected(callable $work): bool { try { $work(); } catch (Throwable $e) { return true; } return false; }
$config = ProfileBilling::normalize(['enabled' => true, 'ports' => [1 => 443, 2 => 8443], 'rates' => [1 => 1, 2 => 4]]);
$key = 'server_profile_billing_history_25_' . $config['revision'];
$db->prepare('INSERT INTO settings VALUES(?,?)')->execute([$key, json_encode($config)]);
$rows = [];
foreach ([1,2] as $slot) $rows[] = ['subscription_id'=>7,'profile'=>$slot,'revision'=>$config['revision'],'u'=>100,'d'=>150];
$body = ['node_id'=>25,'batch_id'=>str_repeat('a',32),'data'=>$rows];
check(ProfileBilling::charge($db,$body)['accepted'], 'same native account accepts usage from two profile ports');
$user = $db->query('SELECT u,d,total_data_used FROM user WHERE id=7')->fetch(PDO::FETCH_NUM);
check(array_map('intval',$user)===[500,750,1250], 'profile 1 at 1x and profile 2 at 4x debit the same quota exactly');
check((int)$db->query('SELECT bandwidth FROM servers WHERE id=25')->fetchColumn()===500, 'node bandwidth keeps unweighted bytes');
check($db->query('SELECT rate FROM trafficlog ORDER BY rate')->fetchAll(PDO::FETCH_COLUMN)==[1,4], 'native traffic logs preserve the applied rates');
check(ProfileBilling::charge($db,$body)['duplicate'] && (int)$db->query('SELECT total_data_used FROM user')->fetchColumn()===1250, 'retry after lost HTTP acknowledgement never charges twice');
$changed=$body;$changed['data'][0]['u']=101;
check(rejected(function()use($db,$changed){ProfileBilling::charge($db,$changed);}), 'same batch ID cannot be reused with different counters');
$bad=$body;$bad['batch_id']=str_repeat('b',32);$bad['data'][1]['revision']=str_repeat('0',64);
check(rejected(function()use($db,$bad){ProfileBilling::charge($db,$bad);}) && (int)$db->query('SELECT total_data_used FROM user')->fetchColumn()===1250, 'unknown revision rejects entire batch without partial debit');
$later=ProfileBilling::normalize(['enabled'=>true,'ports'=>[1=>443,2=>8443],'rates'=>[1=>2,2=>8]]);
$db->prepare('INSERT INTO settings VALUES(?,?)')->execute(['server_profile_billing_25',json_encode($later)]);
$body['batch_id']=str_repeat('c',32);
check(ProfileBilling::charge($db,$body)['accepted'] && (int)$db->query('SELECT total_data_used FROM user')->fetchColumn()===2500, 'queued usage retains the old revision rate after a price change');
check(rejected(function(){ProfileBilling::normalize(['enabled'=>true,'ports'=>[1=>443,2=>443]]);}), 'duplicate profile ports rejected');
check(rejected(function(){ProfileBilling::normalize(['enabled'=>true,'ports'=>[1=>443,2=>70000]]);}), 'out-of-range port rejected');
check(rejected(function(){ProfileBilling::normalize(['rates'=>[1=>-1,2=>4]]);}), 'negative multiplier rejected');
$bad=$body;$bad['batch_id']=str_repeat('d',32);$bad['data'][0]['u']=-1;
check(rejected(function()use($db,$bad){ProfileBilling::charge($db,$bad);}), 'negative traffic cannot increase quota');
