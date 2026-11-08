<?php
// Isolated SQLite harness for the actual management endpoint; no panel data touched.
class TestPDO extends PDO {
    public function prepare(string $query, array $options = []): PDOStatement|false {
        return parent::prepare(str_replace(' FOR UPDATE', '', $query), $options);
    }
}
$pdo = new TestPDO('sqlite::memory:');
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
$pdo->exec('CREATE TABLE user(id INTEGER,role INTEGER); INSERT INTO user VALUES(1,1); CREATE TABLE tickets(id INTEGER,rootid INTEGER,main_id INTEGER,status INTEGER); INSERT INTO tickets VALUES(10,0,10,1),(11,10,10,1),(20,0,20,1); CREATE TABLE ticket_close_notice(ticketid INTEGER); INSERT INTO ticket_close_notice VALUES(10),(20)');
function db(){global $pdo;return $pdo;}
function startPanelSession(){}
function fail($message,$status=400){echo json_encode(['status'=>$status,'error'=>$message]);exit;}
function done($result){global $pdo;echo json_encode(['ok'=>true,'result'=>$result,'rows'=>$pdo->query('SELECT * FROM tickets ORDER BY id')->fetchAll(PDO::FETCH_ASSOC),'notices'=>$pdo->query('SELECT ticketid FROM ticket_close_notice ORDER BY ticketid')->fetchAll(PDO::FETCH_COLUMN)]);exit;}
$_SESSION=['login_session'=>['uid'=>1],'ticket_csrf'=>'valid'];
$_SERVER['REQUEST_METHOD']='POST';$action='ticket.manage';
$_POST=['token'=>'valid','operation'=>$argv[1]??'close','ids'=>['10','20']];
if(($argv[2]??'')==='user')$pdo->exec('UPDATE user SET role=0');
if(($argv[2]??'')==='csrf')$_POST['token']='wrong';
if(($argv[2]??'')==='child')$_POST['ids']=['11'];
if(($argv[2]??'')==='missing')$_POST['ids']=['10','999'];
if(($argv[2]??'')==='method')$_SERVER['REQUEST_METHOD']='GET';
if(($argv[2]??'')==='limit')$_POST['ids']=array_fill(0,101,'10');
require dirname(__DIR__).'/patch/app/Patch/Tickets.php';
