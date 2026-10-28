<?php
declare(strict_types=1);
define('ROOT', dirname(__DIR__) . '/patch');
$pdo = new PDO('sqlite::memory:', null, null, [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION, PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC]);
$pdo->exec('CREATE TABLE settings(name TEXT PRIMARY KEY,value TEXT); CREATE TABLE "group"(id INTEGER,name TEXT); CREATE TABLE servers(id INTEGER,name TEXT,sort INTEGER); INSERT INTO "group" VALUES(2,"standard"),(4,"special"); INSERT INTO servers VALUES(11,"direct",1),(12,"tunnel",2)');
function db(): PDO { return $GLOBALS['pdo']; }
function setting(string $key, ?string $fallback = null): ?string {
    $q=db()->prepare('SELECT value FROM settings WHERE name=?'); $q->execute([$key]); $v=$q->fetchColumn(); return $v === false ? $fallback : (string) $v;
}
function putSetting(string $key, string $value): void { db()->prepare('INSERT OR REPLACE INTO settings(name,value) VALUES(?,?)')->execute([$key,$value]); }
class EndpointResult extends RuntimeException { public $data; public function __construct(array $data) { $this->data=$data; } }
function done(array $data): void { throw new EndpointResult(['ok'=>true]+$data); }
function fail(string $message, int $status=200): void { throw new EndpointResult(['ok'=>false,'error'=>$message]); }
function requireAdmin(): int { return 1; } // Auth itself is covered by the shared endpoint.
function requireToken(): void { if (($_POST['token']??'') !== ($_SESSION['patch_csrf']??null)) fail('bad token'); }
function runEndpoint(string $verb, array $body=[]): array {
    $action='subprofiles.'.$verb; $_POST=$body; $_SERVER['REQUEST_METHOD']=$verb==='save'?'POST':'GET';
    try { require ROOT.'/app/Patch/SubscriptionProfilesEndpoint.php'; } catch (EndpointResult $e) { return $e->data; }
    throw new RuntimeException('No response');
}
function check($value, string $message): void { if (!$value) throw new RuntimeException($message); echo 'PASS '.$message."\n"; }
$_SESSION=[];
$initial=runEndpoint('get');
check($initial['ok'] && strlen($initial['token'])===48 && $initial['profiles']===[], 'bootstrap creates CSRF and leaves legacy subscriptions unchanged');
$profiles=[['name'=>'سرورهای مستقیم','description'=>"خط اول\nخط دوم",'enabled'=>true,'groups'=>[2,4],'servers'=>[11]],['name'=>'سرورهای تانل','description'=>'توضیح مستقل','enabled'=>true,'groups'=>[2],'servers'=>[12]]];
check(!runEndpoint('save',['profiles'=>json_encode($profiles),'token'=>'bad'])['ok'], 'save rejects invalid CSRF');
$save=runEndpoint('save',['profiles'=>json_encode($profiles),'token'=>$initial['token']]);
check($save['ok'], 'save two independent profiles');
check(json_decode(setting('sub_profiles'),true)==$profiles, 'titles, multiline descriptions, shared groups and distinct servers round trip');
check(strlen(setting('sub_profiles_secret'))===64, 'internal signing key generated');
$secret=setting('sub_profiles_secret'); $before=setting('sub_profiles');
$invalid=$profiles; $invalid[1]['servers']=[999];
check(!runEndpoint('save',['profiles'=>json_encode($invalid),'token'=>$initial['token']])['ok'] && setting('sub_profiles')===$before, 'invalid server rejects entire save');
$invalid=$profiles; $invalid[0]['groups']=[];
check(!runEndpoint('save',['profiles'=>json_encode($invalid),'token'=>$initial['token']])['ok'], 'enabled link requires groups');
$invalid=$profiles; $invalid[0]['servers']=[];
check(!runEndpoint('save',['profiles'=>json_encode($invalid),'token'=>$initial['token']])['ok'], 'enabled link requires servers');
$profiles[0]['groups']=[4]; $profiles[1]['groups']=[2];
check(runEndpoint('save',['profiles'=>json_encode($profiles),'token'=>$initial['token']])['ok'] && setting('sub_profiles_secret')===$secret, 'distinct groups save without rotating signing key');
$invalid=$profiles; $invalid[0]['description']=str_repeat('x',4001);
check(!runEndpoint('save',['profiles'=>json_encode($invalid),'token'=>$initial['token']])['ok'], 'description size validated');
check(!runEndpoint('save',['profiles'=>'{"a":{},"b":{}}','token'=>$initial['token']])['ok'], 'non-list profile object rejected');
