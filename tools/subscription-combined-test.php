<?php
/** Exercise native model expansion without any database writes. */
namespace App\Http\Models {
    class Model {
        public static $scopes = [];
        private $attributes;
        public function __construct(array $values) { $this->attributes = $values; }
        public function __get($name) {
            $method = 'get' . ucfirst($name) . 'Attribute';
            return method_exists($this, $method) ? $this->$method($this->attributes[$name] ?? null) : ($this->attributes[$name] ?? null);
        }
        public static function addGlobalScope($name, $scope) { self::$scopes[$name] = $scope; }
        public function newCollection(array $models = []) { return $models; }
    }
}
namespace Illuminate\Database\Capsule {
    class Manager {
        public static function table($table) { return new class {
            public function whereIn(...$args) { return $this; }
            public function where(...$args) { return $this; }
            public function pluck(...$args) { return $this; }
            public function all() { return []; }
            public function first(...$args) { return (object) ['server_group' => 2]; }
        }; }
    }
}
namespace {
require __DIR__ . '/../patch/app/Http/Models/Server.php';
require __DIR__ . '/../patch/app/Patch/SubscriptionProfiles.php';
function check($ok, $message) { if (!$ok) throw new \RuntimeException($message); echo "PASS $message\n"; }
$a = ['enabled'=>true,'groups'=>[2],'servers'=>[11,12]];
$b = ['enabled'=>true,'groups'=>[4],'servers'=>[12,13]];
$combined = SubscriptionProfiles::combined('{"enabled":true}');
check(SubscriptionProfiles::resolve([$a,$b],'3',['server_group'=>2],$combined)['servers'] === [11,12], 'combined never grants the other subscriber group');
$b['groups'] = [2];
check(SubscriptionProfiles::resolve([$a,$b],'3',['server_group'=>2],$combined)['servers'] === [11,12,13], 'union updates automatically and deduplicates server IDs');
check(!SubscriptionProfiles::resolve([$a,$b],'3',['server_group'=>99],$combined), 'unentitled subscriber denied');
check(!SubscriptionProfiles::resolve([$a,$b],'3',['server_group'=>2],['enabled'=>false]), 'unchecked combined endpoint denied');
$b['enabled'] = false;
check(SubscriptionProfiles::resolve([$a,$b],'3',['server_group'=>2],$combined)['servers'] === [11,12], 'disabled source excluded');
$a['servers']=[11,12];$b=$a;
$settings=['sub_profiles'=>json_encode([$a,$b]),'sub_profiles_combined'=>json_encode($combined),'sub_profiles_secret'=>'fixture',
 'server_profile_domains_11'=>'{"1":"first.example.invalid","2":"second.example.invalid"}',
 'server_profile_billing_11'=>'{"enabled":true,"ports":{"1":1443,"2":2443}}'];
$_SERVER['REQUEST_URI']='/link/fixture_token';$until=time()+60;
$_SERVER['HTTP_X_DIGITSELL_PROFILE']='3:'.$until.':'.hash_hmac('sha256','3:'.$until.':fixture_token','fixture');
SubscriptionProfiles::scope($settings);
$node=new \App\Http\Models\Server(['id'=>11,'address'=>'native.example.invalid','name'=>'Same name','port'=>443]);
$same=new \App\Http\Models\Server(['id'=>12,'address'=>'duplicate.example.invalid','name'=>'Duplicate','port'=>443]);
$rows=$node->newCollection([$node,$same]);
check(count($rows)===3, 'distinct per-profile endpoints retained and exact duplicates removed');
check($node->newCollection($rows)===$rows, 'ORM rebuilding a collection must not expand variants twice');
check([$rows[0]->address,$rows[0]->port(),$rows[1]->address,$rows[1]->port()]===['first.example.invalid',1443,'second.example.invalid',2443], 'native clones retain each source hostname and billing port');
check($rows[0]->name!==$rows[1]->name, 'structured formats receive unique proxy labels');
check($node->address==='native.example.invalid' && $node->port()===443, 'stored/native model remains unchanged');
$query=new class { public $ids; public function getQuery(){return $this;} public $wheres=[]; public function whereIn($key,$ids){$this->ids=$ids;} };
ob_start(); (\App\Http\Models\Model::$scopes['digitsell_subscription_profile'])($query);ob_end_clean();
check($query->ids===[11,12], 'native query remains restricted to authorized source IDs');
}
