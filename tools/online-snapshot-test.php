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
echo "PASS online snapshots: cross-node isolation, distinct NAT IPs, disconnect, validation, rollback and normalization\n";
