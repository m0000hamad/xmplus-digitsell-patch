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

function runDomains(string $verb, array $body): array {
    $action = 'subprofiles.domains.' . $verb;
    $_GET = $body; $_POST = $body; $_SERVER['REQUEST_METHOD'] = $verb === 'save' ? 'POST' : 'GET';
    try { require ROOT . '/app/Patch/SubscriptionProfilesEndpoint.php'; } catch (EndpointResult $e) { return $e->data; }
    throw new RuntimeException('No response');
}
$before = setting('sub_profiles');
$body = ['server_id' => 11, 'token' => $initial['token'], 'domains' => '{"1":" First.Example.com. ","2":"second.example.com"}'];
check(runDomains('get', ['server_id' => 11])['ok'], 'server editor loads existing profiles without changing configuration');
check(!runDomains('save', array_replace($body, ['token' => 'bad']))['ok'], 'domain save requires CSRF');
check(!runDomains('save', array_replace($body, ['server_id' => 999]))['ok'], 'domain save rejects nonexistent server');
check(runDomains('save', $body)['ok'], 'two domains saved for same native server');
check(runDomains('get', ['server_id' => 11])['domains'] == [1 => 'first.example.com', 2 => 'second.example.com'], 'normalized per-link domains round trip');
$saved = setting('server_profile_domains_11');
foreach (['https://bad.example.com', 'bad.example.com:443', 'bad.example.com/path', 'bad.example.com?x=1', 'bad_example.com', '<script>'] as $bad) {
    check(!runDomains('save', array_replace($body, ['domains' => json_encode([1 => 'good.example.com', 2 => $bad])]))['ok']
        && setting('server_profile_domains_11') === $saved, 'invalid domain rejected atomically: ' . $bad);
}
check(!runDomains('save', array_replace($body, ['domains' => '{"1":"only.example.com"}']))['ok'], 'partial mapping rejected');
check(runDomains('save', array_replace($body, ['server_id' => 12]))['ok'] && setting('server_profile_domains_11') === $saved, 'editing another server preserves first mapping');
check(runDomains('save', array_replace($body, ['domains' => '{"1":"","2":"second.example.com"}']))['ok'], 'empty domain permits native fallback');
check(setting('sub_profiles') === $before && setting('sub_profiles_secret') === $secret, 'domain saves preserve link membership and signing secret');
$named = array_replace($body, ['names' => json_encode([1 => 'آلمان مستقیم', 2 => 'آلمان تانل'])]);
check(runDomains('save', $named)['ok'], 'per-link names and domains save together');
check(runDomains('get', ['server_id' => 11])['names'] == [1 => 'آلمان مستقیم', 2 => 'آلمان تانل'], 'independent UTF-8 names round trip');
$saved = setting('server_profile_domains_11'); $savedNames = setting('server_profile_names_11');
foreach ([json_encode([1 => 'valid', 2 => str_repeat('x', 241)]), json_encode([1 => 'valid', 2 => "invalid\nname"]), '{"1":"only"}'] as $bad) {
    check(!runDomains('save', array_replace($named, ['domains' => '{"1":"changed.example.com","2":"changed.example.com"}', 'names' => $bad]))['ok']
        && setting('server_profile_domains_11') === $saved && setting('server_profile_names_11') === $savedNames, 'invalid name rejects names and domains atomically');
}
$billing=['enabled'=>true,'ports'=>[1=>443,2=>8443],'rates'=>[1=>1,2=>4]];
check(!runDomains('save',array_replace($named,['billing'=>json_encode($billing)]))['ok'], 'profile ports cannot be enabled on an old or offline agent');
putSetting('profile_agent_11',json_encode(['at'=>time(),'capability'=>'profile-billing-v1']));
check(runDomains('save',array_replace($named,['billing'=>json_encode($billing)]))['ok'], 'capable agent permits two ports and independent multipliers');
$stored=json_decode(setting('server_profile_billing_11'),true);
check(json_decode(setting('server_profile_billing_history_11_'.$stored['revision']),true)===$stored, 'immutable billing revision saved atomically with current settings');
$billing['ports'][2]=443;
check(!runDomains('save',array_replace($named,['billing'=>json_encode($billing)]))['ok'] && json_decode(setting('server_profile_billing_11'),true)===$stored, 'conflicting ports preserve the previous working configuration');
$billing['ports'][2]=8443;
putSetting('profile_agent_11',json_encode(['at'=>time(),'capability'=>'profile-billing-v1','reserved_ports'=>[8443]]));
check(!runDomains('save',array_replace($named,['billing'=>json_encode($billing)]))['ok'], 'ports reserved by another inbound or API cannot be selected');
$pdo->exec('CREATE TABLE node_profile_online(serverid INTEGER PRIMARY KEY,profile1 INTEGER,profile2 INTEGER,unclassified INTEGER,ready INTEGER,datetime INTEGER)');
$online=runEndpoint('online');
check($online['ok'] && (array)$online['nodes']===[], 'online endpoint leaves unreported nodes unknown');
$pdo->prepare('INSERT INTO node_profile_online VALUES(?,?,?,?,?,?)')->execute([11,2,3,1,1,time()]);
$online=runEndpoint('online');
check($online['nodes']->{11}['counts']===[2,3] && $online['nodes']->{11}['unclassified']===1, 'online endpoint returns actual independent counts in profile order');
check(array_keys($online['nodes']->{11})===['counts','unclassified','ready','at'], 'online endpoint exposes aggregate counts without account or IP details');
