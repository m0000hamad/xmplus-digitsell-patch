<?php
declare(strict_types=1);
$pdo = new PDO('sqlite::memory:', null, null, [PDO::ATTR_ERRMODE=>PDO::ERRMODE_EXCEPTION, PDO::ATTR_DEFAULT_FETCH_MODE=>PDO::FETCH_ASSOC]);
$pdo->exec('CREATE TABLE settings(name TEXT PRIMARY KEY,value TEXT); CREATE TABLE servers(id INTEGER PRIMARY KEY,name TEXT); INSERT INTO servers VALUES(1,"one"),(2,"two")');
function db(): PDO { return $GLOBALS['pdo']; }
function setting(string $name, ?string $fallback=null): ?string { $q=db()->prepare('SELECT value FROM settings WHERE name=?'); $q->execute([$name]); $v=$q->fetchColumn(); return $v===false?$fallback:(string)$v; }
function putSetting(string $name,string $value): void { db()->prepare('INSERT OR REPLACE INTO settings VALUES(?,?)')->execute([$name,$value]); }
class Result extends RuntimeException { public $data; public function __construct(array $data) { $this->data=$data; } }
function done(array $data): void { throw new Result(['ok'=>true]+$data); }
function fail(string $message,int $status=200): void { throw new Result(['ok'=>false,'error'=>$message]); }
function requireAdmin(): void { if (empty($GLOBALS['admin'])) fail('denied'); }
function requireToken(): void { if (($_POST['token']??'')!==($_SESSION['patch_csrf']??null)) fail('bad token'); }
function callWarp(string $action,array $post=[]): array { $_POST=$post; try { $action(); } catch(Result $r) { return $r->data; } throw new RuntimeException('no response'); }
function check(bool $ok,string $message): void { if(!$ok) throw new RuntimeException($message); echo 'PASS '.$message.PHP_EOL; }
$_GET=[]; $_SESSION=[]; $admin=true;
require dirname(__DIR__).'/patch/app/Patch/Warp.php';
$first=callWarp('warpAdmin'); $token=$first['token'];
check(!$first['servers'][0]['enabled']&&!$first['servers'][1]['enabled'],'defaults off');
check(!callWarp('warpSave',['id'=>1,'enabled'=>'1','token'=>'wrong'])['ok'],'CSRF denied');
check(!callWarp('warpSave',['id'=>999,'enabled'=>'1','token'=>$token])['ok'],'unknown node denied');
check(!callWarp('warpSave',['id'=>1,'enabled'=>'yes','token'=>$token])['ok'],'invalid value denied');
check(callWarp('warpSave',['id'=>1,'enabled'=>'1','token'=>$token])['ok']&&warpEnabled(1)&&!warpEnabled(2),'independent enable');
check(callWarp('warpSave',['id'=>1,'enabled'=>'0','token'=>$token])['ok']&&!warpEnabled(1),'disable persists');
$admin=false;
check(!callWarp('warpAdmin')['ok']&&!callWarp('warpSave',['id'=>1,'enabled'=>'1','token'=>$token])['ok'],'anonymous read/write denied');
