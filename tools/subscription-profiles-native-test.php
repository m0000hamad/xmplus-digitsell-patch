<?php
/** Run only on an installed panel. Every fixture table is connection-local. */
declare(strict_types=1);
if (PHP_SAPI !== 'cli') exit(1);
$panel = $argv[1];
$source = $argv[2];
$slot = $argv[3] ?? '1';
$format = $argv[4] ?? 'config';
require $source . '/app/Provider/ConfigProvider.php';
require $panel . '/bin/console.php';
if (!class_exists('App\\Http\\Models\\Server', false) && is_file($source . '/app/Http/Models/Server.php')) {
    require $source . '/app/Http/Models/Server.php';
}
chdir($panel . '/public');
error_reporting(E_ALL & ~E_USER_DEPRECATED & ~E_DEPRECATED);
// Supply minimal native serializer templates explicitly for the CLI fixture.
$_ENV['Config_EN'] = ['proxy-groups' => [
    ['name'=>'Fixture','type'=>'select','proxies'=>['DIRECT']],
    ['name'=>'Direct','type'=>'select','proxies'=>['DIRECT']],
    ['name'=>'Block','type'=>'select','proxies'=>['REJECT']]], 'rules'=>['MATCH,Fixture']];
$_ENV['SingBox'] = ['outbounds'=>[
    ['type'=>'selector','tag'=>'proxy','outbounds'=>[]],
    ['type'=>'urltest','tag'=>'auto','outbounds'=>[]],
    ['type'=>'direct','tag'=>'direct']], 'inbounds'=>[]];
$pdo = Illuminate\Database\Capsule\Manager::connection()->getPdo();
$pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
$user = $pdo->query('SELECT * FROM user LIMIT 1')->fetch();
$server = $pdo->query('SELECT * FROM servers LIMIT 1')->fetch();
$settings = $pdo->query('SELECT * FROM settings')->fetchAll();
foreach (['user', 'servers', 'settings', 'subscribe_log', 'group'] as $table) {
    $ddl = $pdo->query('SHOW CREATE TABLE `' . $table . '`')->fetch(PDO::FETCH_NUM)[1];
    $pdo->exec(str_replace('CREATE TABLE', 'CREATE TEMPORARY TABLE', $ddl));
}
function insertRow(string $table, array $row): void {
    global $pdo;
    $pdo->prepare('INSERT INTO `' . $table . '` (`' . implode('`,`', array_keys($row)) . '`) VALUES (' . implode(',', array_fill(0, count($row), '?')) . ')')->execute(array_values($row));
}
foreach ($settings as $row) insertRow('settings', $row);
function settingFixture(string $name, string $value): void {
    global $pdo;
    $pdo->prepare('DELETE FROM settings WHERE name=?')->execute([$name]);
    insertRow('settings', ['name' => $name, 'value' => $value]);
}
$token = 'profile_fixture_token_123456';
$user = array_replace($user, ['id' => 900001, 'username' => 'profile-fixture', 'email' => 'fixture@example.invalid',
    'uuid' => '00000000-1111-4222-8333-444444444444', 'token' => $token, 'role' => 0, 'status' => 1,
    'server_group' => 7999, 'user_group' => '', 'transfer_enable' => 107374182400, 'u' => 0, 'd' => 0,
    'expire_in' => date('Y-m-d H:i:s', time() + 86400 * 10), 'money' => 0, 'plan' => 1]);
insertRow('user', $user);
foreach ([900001 => 'DIRECT', 900002 => 'TUNNEL', 900003 => 'TRANSPORT'] as $id => $label) {
    $row = array_replace($server, ['id' => $id, 'name' => 'PROFILE-' . $label, 'address' => strtolower($label) . '.example.invalid',
        'server_ip' => '192.0.2.1', 'server' => ($argv[5] ?? 'Trojan'), 'status' => 1, 'bandwidth' => 0, 'bandwidth_limit' => 0, 'server_group' => '7999', 'sort' => $id,
        'port' => 443, 'listeningport' => 443, 'relayid' => 0, 'relay_type' => 0, 'security' => 'tls', 'cipher' => 'aes-128-gcm',
        'securitySettings' => json_encode(['serverName' => 'example.invalid', 'sni' => 'example.invalid', 'alpn' => ['h2'], 'fingerprint' => 'chrome']),
        'network' => 'tcp', 'networkSettings' => json_encode(['transport' => 'tcp', 'header' => ['type' => 'none'], 'flow' => '']), 'country' => 'DE']);
    if ($id === 900003) { $row['status'] = 0; $row['server_group'] = '0'; }
    if ($id === 900001 && ($argv[6] ?? '') === 'relay') { $row['relayid'] = 900003; $row['relay_type'] = 2; }
    insertRow('servers', $row);
}
$profiles = [['enabled' => true, 'name' => 'Direct', 'description' => 'first', 'groups' => [7999], 'servers' => [900001]],
    ['enabled' => true, 'name' => 'Tunnel', 'description' => 'second', 'groups' => [7999], 'servers' => [900002]]];
$domainFixture = ($argv[7] ?? '') === 'domains';
if ($domainFixture) {
    $profiles[1]['servers'] = [900001];
    settingFixture('server_profile_domains_900001', json_encode([1 => 'first.example.invalid', 2 => 'second.example.invalid']));
    settingFixture('server_profile_names_900001', json_encode([1 => 'PROFILE-FIRST', 2 => 'PROFILE-SECOND']));
}
settingFixture('sub_profiles', json_encode($profiles));
settingFixture('sub_profiles_secret', 'fixture-secret-not-a-production-key');
settingFixture('sub_info_enabled', '0');
$_SERVER['REQUEST_URI'] = '/link/' . $token . '?' . $format . '=1';
$_SERVER['HTTP_HOST'] = 'p.digitsell-shop.ir';
$_SERVER['REMOTE_ADDR'] = '127.0.0.1';
$_SERVER['SERVER_PORT'] = '443';
$_SERVER['REQUEST_SCHEME'] = 'https';
$_SERVER['HTTPS'] = 'on';
if ($slot !== '0') {
    $until = (string) (time() + 60);
    $_SERVER['HTTP_X_DIGITSELL_PROFILE'] = $slot . ':' . $until . ':' . hash_hmac('sha256', $slot . ':' . $until . ':' . $token, 'fixture-secret-not-a-production-key');
}
$config = new App\Provider\ConfigProvider();
if ($domainFixture) {
    $node = App\Http\Models\Server::find(900001);
    $item = $node->getServerItem(App\Http\Models\User::find(900001), $argv[5] ?? 'Trojan', false);
    $expectedAddress = $slot === '0' ? 'direct.example.invalid' : ($slot === '1' ? 'first.example.invalid' : 'second.example.invalid');
    $expectedName = $slot === '0' ? 'PROFILE-DIRECT' : ($slot === '1' ? 'PROFILE-FIRST' : 'PROFILE-SECOND');
    if ($item['add'] !== $expectedAddress || $item['sni'] !== 'example.invalid' || $item['port'] !== 443
        || $item['name'] !== $expectedName || $item['remark'] !== $expectedName
        || ($item['passwd'] ?? '') !== $user['uuid']) throw new RuntimeException('Profile overrides changed shared connection settings');
    if ($pdo->query('SELECT address FROM servers WHERE id=900001')->fetchColumn() !== 'direct.example.invalid') throw new RuntimeException('Native address mutated');
}
class ProfileFixtureController extends App\Http\Controllers\User\SubController {
    public function __construct($user) { parent::__construct(); $this->user = $user; }
}
$request = (new Slim\Psr7\Factory\ServerRequestFactory())->createServerRequest('GET', 'https://p.digitsell-shop.ir' . $_SERVER['REQUEST_URI'], $_SERVER)
    ->withQueryParams(['config' => '0', $format => '1'])->withHeader('User-Agent', 'profile-fixture/1.0');
$response = (new ProfileFixtureController(App\Http\Models\User::find(900001)))->GetContent($request, new Slim\Psr7\Response(), ['token' => $token]);
$body = (string) $response->getBody();
$decoded = base64_decode($body, true);
if ($decoded !== false) $body = $decoded;
$want = $slot === '2' && !$domainFixture ? 'TUNNEL' : 'DIRECT';
$other = $slot === '2' && !$domainFixture ? 'DIRECT' : 'TUNNEL';
if ($domainFixture && $slot !== '0') $want = $slot === '1' ? 'FIRST' : 'SECOND';
if ($domainFixture && strpos($body, $expectedAddress) === false) {
    // Native VMess, Shadowrocket VLESS and SS URIs can encode the endpoint again.
    if (preg_match_all('~(?:vmess|vless|ss)://([A-Za-z0-9+/_=-]+)(?=[?#\s]|$)~', $body, $links)) {
        foreach ($links[1] as $link) $body .= "\n" . base64_decode(strtr($link, '-_', '+/'));
    }
    if (strpos($body, $expectedAddress) === false) {
        if ($slot === '0' && strpos($body, 'PROFILE-DIRECT') === false && strpos($body, 'PROFILE-TUNNEL') === false) {
            echo 'SKIP native baseline omits this protocol/format combination' . "\n";
            exit(2);
        }
        throw new RuntimeException('Serialized domain missing');
    }
}
if ($response->getStatusCode() !== 200 || strpos($body, 'PROFILE-' . $want) === false
    || ($slot !== '0' && strpos($body, 'PROFILE-' . $other) !== false)) {
    echo 'FAIL native fixture slot=' . $slot . ' format=' . $format . ' status=' . $response->getStatusCode() . ' bytes=' . strlen($body) . "\n";
    // Only synthetic fixture output may be displayed on failure.
    echo substr($body, 0, 500) . "\n";
    exit(1);
}
echo 'PASS native fixture slot=' . $slot . ' format=' . $format . "\n";
