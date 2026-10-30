<?php
/** Exercise the shipped native model with a minimal attribute/query substitute. */
namespace App\Http\Models {
    class Model {
        public static $rows = [];
        public static $scopes = [];
        private $attributes;
        public function __construct(array $attributes) { $this->attributes = $attributes; }
        public function __get($name) {
            $method = 'get' . ucfirst($name) . 'Attribute';
            $value = $this->attributes[$name] ?? null;
            return method_exists($this, $method) ? $this->$method($value) : $value;
        }
        public static function find($id) { return self::$rows[$id]; }
        public static function addGlobalScope($name, $scope) { self::$scopes[$name] = $scope; }
    }
    class User { public $uuid = '00000000-1111-4222-8333-444444444444'; }
}
namespace Illuminate\Database\Capsule {
    class Manager {
        public static function table($table) { return new class {
            public function whereIn($key, $value) { return $this; }
            public function where($key, $value) { return $this; }
            public function pluck($key) { return $this; }
            public function all() { return [12]; }
        }; }
    }
}
namespace {
require __DIR__ . '/../patch/app/Http/Models/Server.php';
require __DIR__ . '/../patch/app/Patch/SubscriptionProfiles.php';
function check($condition, $message) { if (!$condition) throw new \RuntimeException($message); echo "PASS $message\n"; }
$slot = $argv[1] ?? '1';
$attributes = ['id' => 11, 'address' => 'original.example.com', 'server_ip' => '192.0.2.1', 'name' => 'Fixture',
    'port' => 443, 'cipher' => 'aes-128-gcm', 'security' => 'tls', 'fragment' => 0, 'fragment_value' => '',
    'relayid' => 0, 'relay_type' => 0, 'securitySettings' => json_encode(['serverName' => 'tls.example.com', 'sni' => 'tls.example.com']),
    'networkSettings' => json_encode(['transport' => 'ws', 'path' => '/fixed', 'host' => 'host.example.com'])];
$node = new \App\Http\Models\Server($attributes);
\App\Http\Models\Model::$rows[12] = new \App\Http\Models\Server(array_replace($attributes, ['id' => 12, 'address' => 'transport.example.com']));
$relay = new \App\Http\Models\Server(array_replace($attributes, ['relayid' => 12, 'relay_type' => 2]));
$user = new \App\Http\Models\User();
$baseline = []; $relayBaseline = [];
foreach (['Trojan', 'Vless', 'Vmess', 'Shadowsocks'] as $type) {
    $baseline[$type] = $node->getServerItem($user, $type, false);
    $relayBaseline[$type] = $relay->getServerItem($user, $type, false);
}
$profile = ['enabled' => true, 'groups' => [2], 'servers' => [11]];
$settings = ['sub_profiles_secret' => 'fixture-secret', 'sub_profiles' => json_encode([$profile, $profile]),
    'server_profile_domains_11' => '{"1":"first.example.com","2":"second.example.com"}',
    'server_profile_domains_12' => '{"1":"hidden.example.com","2":"hidden.example.com"}'];
if (($argv[2] ?? '') === 'names') $settings['server_profile_names_11'] = json_encode([1 => 'آلمان مستقیم', 2 => 'آلمان تانل']);
if (($argv[2] ?? '') === 'empty') $settings['server_profile_domains_11'] = '{"1":"","2":""}';
$_SERVER['REQUEST_URI'] = '/link/fixture_token';
$_SERVER['HTTP_X_DIGITSELL_PROFILE'] = $slot . ':' . (time() + 60) . ':forged';
\SubscriptionProfiles::scope($settings);
check($node->address === 'original.example.com', 'unverified header cannot alter native model');
$until = (string) (time() + 60);
$_SERVER['HTTP_X_DIGITSELL_PROFILE'] = "$slot:$until:" . hash_hmac('sha256', "$slot:$until:fixture_token", 'fixture-secret');
\SubscriptionProfiles::scope($settings);
$expected = $slot === '1' ? 'first.example.com' : 'second.example.com';
if (($argv[2] ?? '') === 'empty') $expected = 'original.example.com';
foreach (array_keys($baseline) as $type) {
    $want = array_replace($baseline[$type], ['add' => $expected]);
    if (($argv[2] ?? '') === 'names') $want['name'] = $want['remark'] = $slot === '1' ? 'آلمان مستقیم' : 'آلمان تانل';
    check($node->getServerItem($user, $type, false) === $want, "$type profile $slot changes only connection address");
    $want = array_replace($relayBaseline[$type], ['add' => $expected]);
    if (($argv[2] ?? '') === 'names') $want['name'] = $want['remark'] = $slot === '1' ? 'آلمان مستقیم' : 'آلمان تانل';
    check($relay->getServerItem($user, $type, false) === $want, "$type relay profile $slot preserves every transport and credential field");
}
check(\App\Http\Models\Model::$rows[12]->address === 'transport.example.com', 'private relay dependency does not inherit subscription address mapping');
}
