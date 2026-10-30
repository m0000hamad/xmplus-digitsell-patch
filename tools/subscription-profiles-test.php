<?php
/** Standalone tests, with a recording native-model substitute. */
namespace App\Http\Models {
    class Server {
        public static $scopes = [];
        public static function addGlobalScope($name, $scope) { self::$scopes[$name] = $scope; }
    }
}
namespace Illuminate\Database\Capsule {
    class Manager {
        public static function table($name) {
            return new class {
                public function whereIn($column, $value) { return $this; }
                public function where($column, $value) { return $this; }
                public function pluck($column) { return $this; }
                public function all() { return []; }
            };
        }
    }
}
namespace {
require __DIR__ . '/../patch/app/Patch/SubscriptionProfiles.php';
function check($value, $name) { if (!$value) throw new \RuntimeException($name); echo 'PASS ' . $name . "\n"; }
$profile = ['enabled' => true, 'groups' => [2, 4], 'servers' => [11]];
check(SubscriptionProfiles::allowed($profile, ['server_group' => 2]), 'selected group allowed');
check(!SubscriptionProfiles::allowed($profile, ['server_group' => 3]), 'other group denied');
check(!SubscriptionProfiles::allowed(['enabled' => false] + $profile, ['server_group' => 2]), 'disabled link denied');
check(!SubscriptionProfiles::allowed(['enabled' => true, 'groups' => []], ['server_group' => 2]), 'empty groups deny everyone');
check(SubscriptionProfiles::read('invalid') === [], 'invalid settings rejected');
check(SubscriptionProfiles::queryIds([11], [12], []) === [11], 'relay dependency never expands subscription list');
check(SubscriptionProfiles::queryIds([11], [12], [['type'=>'Basic','column'=>'servers.id','operator'=>'=','value'=>12]]) === [12], 'selected relay may resolve its transport');
check(SubscriptionProfiles::queryIds([11], [12], [['type'=>'Basic','column'=>'servers.id','operator'=>'=','value'=>13]]) === [11], 'unrelated direct lookup stays restricted');
$base = 'https://sub.example/xmplus-patch.php?do=sub&t=test_token&profile=2';
check(SubscriptionProfiles::rewriteUrls('https://native.example/link/test_token?surfboard=1', 'test_token', $base) === $base . '&surfboard=1', 'managed refresh preserves selected profile and format');
check(SubscriptionProfiles::rewriteUrls('https://native.example/link/test_token', 'test_token', $base) === $base, 'bare native URL remains scoped');
check(SubscriptionProfiles::rewriteUrls('https://native.example/link/test_token_other?config=1', 'test_token', $base) === 'https://native.example/link/test_token_other?config=1', 'other tokens are never rewritten');
$_SERVER['REQUEST_URI'] = '/link/test_token?config=1';
$until = (string) (time() + 60);
$settings = ['sub_profiles_secret' => 'test-secret', 'sub_profiles' => json_encode([$profile, ['enabled' => true, 'groups' => [2], 'servers' => [12]]])];
$settings['server_profile_domains_11'] = '{"1":"first.example.com","2":"second.example.com"}';
$_SERVER['HTTP_X_DIGITSELL_PROFILE'] = '1:' . $until . ':forged';
SubscriptionProfiles::scope($settings);
check(!\App\Http\Models\Server::$scopes, 'forged header cannot change native queries');
check(SubscriptionProfiles::address(11, 'original.example.com') === 'original.example.com', 'forged request cannot override an address');
foreach ([time() - 1, time() + 120] as $badTime) {
    $_SERVER['HTTP_X_DIGITSELL_PROFILE'] = '1:' . $badTime . ':' . hash_hmac('sha256', '1:' . $badTime . ':test_token', 'test-secret');
    SubscriptionProfiles::scope($settings);
    check(!\App\Http\Models\Server::$scopes, 'expired or excessively future signature rejected');
}
$_SERVER['HTTP_X_DIGITSELL_PROFILE'] = '1:' . $until . ':' . hash_hmac('sha256', '1:' . $until . ':other_token', 'test-secret');
SubscriptionProfiles::scope($settings);
check(!\App\Http\Models\Server::$scopes, 'signature bound to subscription credential');
$_SERVER['HTTP_X_DIGITSELL_PROFILE'] = '1:' . $until . ':' . hash_hmac('sha256', '1:' . $until . ':test_token', 'test-secret');
SubscriptionProfiles::scope($settings);
check(count(\App\Http\Models\Server::$scopes) === 1, 'signed request installs one native scope');
check(SubscriptionProfiles::address(11, 'original.example.com') === 'first.example.com', 'verified profile selects its own domain');
check(SubscriptionProfiles::address(12, 'original.example.com') === 'original.example.com', 'unmapped server retains original address');
$query = new class { public $ids; public $wheres = []; public function getQuery() { return $this; } public function whereIn($column, $ids) { $this->ids = [$column, $ids]; }};
ob_start(); (\App\Http\Models\Server::$scopes['digitsell_subscription_profile'])($query); ob_end_clean();
check($query->ids === ['servers.id', [11]], 'native query restricted to exact server IDs');
}
