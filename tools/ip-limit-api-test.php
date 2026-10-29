<?php
/** Execute both shipped controllers against synthetic accounts and node reports. */
namespace Illuminate\Database\Query { class Builder { public function whereIn(...$args){return $this;} } }
namespace Illuminate\Database\Capsule { class Manager { public static $rows=[]; public static function table($name){return new Query;} } class Query extends \Illuminate\Database\Query\Builder { public function __call($name,$args){return $this;} public function where($a,...$args){if(is_callable($a))$a($this);return $this;} public function get(){return array_map(function($r){return clone $r;},Manager::$rows);} } }
namespace App\Http\Models { class User { public static function getTableName(){return 'fixture';} } class Server { public static function find($id){return new self;} public $bandwidth_limit=0,$server_group='1';public function update($values){} } class OnlineIp { public static $count=0; public function getUserAliveIpCount(){return ['7'=>self::$count];} } }
namespace App\Http\Controllers { class Controller { public $config; public function __construct(){$this->config=new class {public function get($key){return 0;}};} } }
namespace { class Body {public $text='';function write($text){$this->text.=$text;}} class Response {public $body,$status=200;function __construct(){$this->body=new Body;}function getBody(){return $this->body;}function withStatus($v){$this->status=$v;return $this;}function withHeader(...$args){return $this;}} class Request {public $etag='';function getHeaderLine($name){return $this->etag;}}
function check($ok,$message){if(!$ok)throw new \RuntimeException($message);}
foreach(['XMPlus'=>'users','XMPlusNew'=>'subscriptions'] as $api=>$key){
 require __DIR__.'/../patch/app/Http/Controllers/Api/'.$api.'/UserController.php';
 $class='App\\Http\\Controllers\\Api\\'.$api.'\\UserController';$controller=new $class;
 foreach([[0,3,true],[2,3,true],[3,3,true],[4,3,false],[5,0,true]] as [$count,$limit,$present]){
 \App\Http\Models\OnlineIp::$count=$count;
 \Illuminate\Database\Capsule\Manager::$rows=[(object)['id'=>7,'uuid'=>'fixture','iplimit'=>$limit,'speedlimit'=>0,'verify'=>1]];
 $response=$controller->getUsers(new Request,new Response,['id'=>1]);$rows=json_decode($response->body->text,true)[$key];
 check(count($rows)===($present?1:0),$api.' admission');
 if($present){check($rows[0]['ipcount']===$count,$api.' must forward global active count');check($rows[0]['iplimit']===$limit,$api.' limit must stay intact');}
 }
 // Online count affects the ETag, preventing cached zero-count replies.
 \App\Http\Models\OnlineIp::$count=2;$request=new Request;$request->etag=sha1(json_encode($rows));
 check($controller->getUsers($request,new Response,['id'=>1])->status===200,$api.' count change invalidates cache');
 echo 'PASS '.$api.' global count, admission, unlimited account and cache'.PHP_EOL;
}
}
