<?php
declare(strict_types=1);
require __DIR__ . '/../patch/app/Patch/NodeOnline.php';
function onlineCheck(bool $condition, string $message): void {
    if (!$condition) throw new RuntimeException($message);
}
$db = new PDO('sqlite::memory:', null, null, [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]);
$db->exec('CREATE TABLE servers (id INTEGER PRIMARY KEY, name TEXT);
CREATE TABLE user (id INTEGER PRIMARY KEY, username TEXT);
CREATE TABLE online_ip (id INTEGER PRIMARY KEY, userid INTEGER, serverid INTEGER, ip TEXT, datetime INTEGER, username TEXT, servername TEXT);
CREATE TABLE node_profile_online(serverid INTEGER PRIMARY KEY,profile1 INTEGER,profile2 INTEGER,unclassified INTEGER,ready INTEGER,datetime INTEGER);
CREATE TABLE node_user_profile_online(serverid INTEGER,userid INTEGER,profile INTEGER,datetime INTEGER,ip_count INTEGER NOT NULL,PRIMARY KEY(serverid,userid,profile));
INSERT INTO servers VALUES (58,"US"),(59,"TR"); INSERT INTO user VALUES (1,"fixture"),(2,"fixture2");');
$ip = ['subscription_id' => 1, 'ip' => '198.51.100.7'];
nodeOnlineSnapshot($db, 58, [$ip], 1000);
nodeOnlineSnapshot($db, 59, [$ip], 1001);
onlineCheck((int)$db->query('SELECT COUNT(*) FROM online_ip')->fetchColumn() === 2, 'same IP on two nodes must produce two memberships');
onlineCheck((int)$db->query('SELECT COUNT(DISTINCT ip) FROM online_ip')->fetchColumn() === 1, 'global IP count must remain distinct, not count NAT devices twice');
nodeOnlineSnapshot($db, 58, [$ip], 1002);
onlineCheck((int)$db->query('SELECT datetime FROM online_ip WHERE serverid=59')->fetchColumn() === 1001, 'report cannot move or refresh another node');
nodeOnlineSnapshot($db, 58, [], 1003);
onlineCheck((int)$db->query('SELECT COUNT(*) FROM online_ip WHERE serverid=58')->fetchColumn() === 0, 'empty snapshot must clear disconnected node');
onlineCheck((int)$db->query('SELECT COUNT(*) FROM online_ip WHERE serverid=59')->fetchColumn() === 1, 'disconnect must not clear another node');
$before = $db->query('SELECT * FROM online_ip')->fetchAll(PDO::FETCH_ASSOC);
foreach ([['subscription_id' => 1, 'ip' => 'invalid'], ['subscription_id' => 0, 'ip' => '198.51.100.8']] as $invalid) {
    try { nodeOnlineSnapshot($db, 59, [$invalid], 1004); throw new RuntimeException('invalid input accepted'); }
    catch (InvalidArgumentException $e) {}
}
onlineCheck($db->query('SELECT * FROM online_ip')->fetchAll(PDO::FETCH_ASSOC) === $before, 'bad payload must leave previous observation intact');
try { nodeOnlineSnapshot($db, 999, [], 1005); throw new RuntimeException('unknown node accepted'); }
catch (InvalidArgumentException $e) {}
onlineCheck(!$db->inTransaction(), 'transaction must close after errors');
$db->exec("CREATE TRIGGER fail_insert BEFORE INSERT ON online_ip WHEN NEW.serverid=59 BEGIN SELECT RAISE(ABORT, 'synthetic insert failure'); END");
try { nodeOnlineSnapshot($db, 59, [$ip], 1006); throw new RuntimeException('injected failure ignored'); }
catch (PDOException $e) {}
onlineCheck($db->query('SELECT * FROM online_ip')->fetchAll(PDO::FETCH_ASSOC) === $before, 'failed insert must roll back the preceding delete');
$db->exec('DROP TRIGGER fail_insert');
nodeOnlineSnapshot($db, 59, [$ip, $ip, ['subscription_id' => 1, 'ip' => '::ffff:198.51.100.7']], 1007);
onlineCheck((int)$db->query('SELECT COUNT(*) FROM online_ip')->fetchColumn() === 1, 'duplicate IPv4/mapped IPv6 addresses must be normalized');
nodeOnlineSnapshot($db, 59, [['subscription_id' => 999, 'ip' => '198.51.100.9']], 1008);
onlineCheck((int)$db->query('SELECT COUNT(*) FROM online_ip')->fetchColumn() === 0, 'deleted users must not be recreated in online membership');

$online=[['subscription_id'=>1,'ip'=>'198.51.100.1'],['subscription_id'=>1,'ip'=>'198.51.100.2'],['subscription_id'=>2,'ip'=>'198.51.100.3']];
$profiles=[['subscription_id'=>1,'ip'=>'198.51.100.1','profile'=>1],['subscription_id'=>1,'ip'=>'198.51.100.2','profile'=>1],
    ['subscription_id'=>1,'ip'=>'198.51.100.1','profile'=>2],['subscription_id'=>2,'ip'=>'198.51.100.3','profile'=>2]];
nodeOnlineSnapshot($db,58,$online,1100,$profiles,true);
$counts=$db->query('SELECT profile1,profile2,unclassified,ready FROM node_profile_online WHERE serverid=58')->fetch(PDO::FETCH_NUM);
onlineCheck(array_map('intval',$counts)===[1,2,0,1], 'count each account once per actual inbound profile, including users on both');
onlineCheck((int)$db->query('SELECT COUNT(*) FROM online_ip WHERE serverid=58')->fetchColumn()===3, 'profile counting must preserve native IP memberships and device limits');
$before=$db->query('SELECT * FROM online_ip WHERE serverid=58 ORDER BY ip')->fetchAll(PDO::FETCH_ASSOC);
$bad=$profiles;$bad[0]['ip']='203.0.113.99';
try {nodeOnlineSnapshot($db,58,$online,1101,$bad,true);throw new RuntimeException('unobserved profile IP accepted');}catch(InvalidArgumentException $e){}
onlineCheck($db->query('SELECT * FROM online_ip WHERE serverid=58 ORDER BY ip')->fetchAll(PDO::FETCH_ASSOC)===$before, 'invalid profile input cannot clear native online data');
nodeOnlineSnapshot($db,58,$online,1102,[],false);
onlineCheck((int)$db->query('SELECT ready FROM node_profile_online WHERE serverid=58')->fetchColumn()===0, 'legacy observations are explicitly unknown, not split into guessed counts');
nodeOnlineSnapshot($db,58,[],1103,[],true);
onlineCheck(array_map('intval',$db->query('SELECT profile1,profile2,ready FROM node_profile_online WHERE serverid=58')->fetch(PDO::FETCH_NUM))===[0,0,1], 'authoritative empty profile report clears both counts');
nodeOnlineSnapshot($db,59,[$ip],1104,[['subscription_id'=>1,'ip'=>$ip['ip'],'profile'=>2]],true);
onlineCheck((int)$db->query('SELECT profile2 FROM node_profile_online WHERE serverid=59')->fetchColumn()===1, 'another node maintains its own independent profile counts');
onlineCheck((int)$db->query('SELECT profile2 FROM node_profile_online WHERE serverid=58')->fetchColumn()===0, 'updating another node must not move memberships');
$members = 'SELECT profile FROM node_user_profile_online WHERE serverid = 59 AND userid = 1 ORDER BY profile';
onlineCheck(array_map('intval', $db->query($members)->fetchAll(PDO::FETCH_COLUMN)) === [2], 'report stores the real profile for the user');
nodeOnlineSnapshot($db, 59, [$ip], 1105, [['subscription_id'=>1,'ip'=>$ip['ip'],'profile'=>1]], true);
onlineCheck(array_map('intval', $db->query($members)->fetchAll(PDO::FETCH_COLUMN)) === [1], 'direct profile clears tunnel presence');
nodeOnlineSnapshot($db, 59, [$ip], 1106);
onlineCheck($db->query($members)->fetchAll(PDO::FETCH_COLUMN) === [], 'unclassified reports clear stale profile memberships');
$tenIps = [];
for ($host = 1; $host <= 10; ++$host) {
    $tenIps[] = ['subscription_id'=>1, 'ip'=>'198.51.100.' . $host];
}
$direct = array_map(static function ($row) { return $row + ['profile'=>1]; }, $tenIps);
$tunnel = $tenIps[0] + ['profile'=>2];
nodeOnlineSnapshot($db, 58, $tenIps, 1107, array_merge($direct, [$direct[0], $tunnel]), true);
$profileCounts = $db->query('SELECT ip_count FROM node_user_profile_online WHERE serverid=58 AND userid=1 ORDER BY profile')->fetchAll(PDO::FETCH_COLUMN);
onlineCheck(array_map('intval', $profileCounts) === [10, 1], 'count distinct addresses per profile without a two-device cap');
nodeOnlineSnapshot($db, 58, array_slice($tenIps, 0, 2), 1108, array_slice($direct, 0, 2), true);
$profileCounts = $db->query('SELECT ip_count FROM node_user_profile_online WHERE serverid=58 AND userid=1 ORDER BY profile')->fetchAll(PDO::FETCH_COLUMN);
onlineCheck(array_map('intval', $profileCounts) === [2], 'the next report updates the count and clears the disconnected profile');
echo "PASS online snapshots: cross-node isolation, distinct NAT IPs, disconnect, validation, rollback and normalization\n";
