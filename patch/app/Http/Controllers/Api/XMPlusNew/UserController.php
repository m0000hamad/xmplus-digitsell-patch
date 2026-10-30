<?php
namespace App\Http\Controllers\Api\XMPlusNew;

use App\Helpers\Helpers;
use App\Http\Models\User;
use App\Http\Models\Server;
use App\Http\Models\OnlineIp;
use App\Http\Models\TrafficLog;
use App\Http\Controllers\Controller;
use Illuminate\Database\Query\Builder;
use Illuminate\Database\Capsule\Manager as DB;

class UserController extends Controller
{
	public function getUsers($request, $response, $args)
    {
		ini_set('memory_limit', '-1');
		if(!isset($args['id'])){
			$res = ['data' => 'UsersApi: ServerID Not Found'];
            $response->getBody()->write(json_encode($res));
		    return $response;
		}
		
		$serverid = $args['id'];
		$server = Server::find($serverid);
        if ($server == null){
            $res = ['ret' => 0, 'data' => 'UsersApi: ServerID Not Found'];
            $response->getBody()->write(json_encode($res));
		    return $response;
        }
		
		if ($server->bandwidth_limit != 0 && ($server->bandwidth_limit < $server->bandwidth))
		{
			$res = ['ret' => 1,'data' => []];
			$response->getBody()->write(json_encode($res));
			return $response;
		}
		
		$server->update([
			"heartbeat"   => time()
		]);
		
		$server_group = explode(',', $server->server_group);
		
		$users_raw = DB::table(User::getTableName())
			->select(['id','uuid','speedlimit','iplimit','u','d','transfer_enable','server_group','verify'])
			->where('status', 1)->where('expire_in', '>', date('Y-m-d H:i:s', time()))->whereRaw('transfer_enable > u + d')
			->where(static function (Builder $query) use ($server_group): void {
                $query->whereIn('server_group', $server_group);
            })->get();
		
		$users = array();
        $key_list = array('id','email','uuid','passwd','speedlimit','iplimit','ipcount');
		
		$alive_ip = (new OnlineIp)->getUserAliveIpCount();
		
		foreach ($users_raw as $user){
			if($this->config->get('verify') == 1 && $this->config->get('disconnect_unverified') == 1 && $user->verify == 0){
				continue;
			}
			
			$ipcount = 0;
			if(isset($alive_ip[strval($user->id)])){
				$ipcount += (int)$alive_ip[strval($user->id)];
			}
			
			if ($user->iplimit != 0 &&
                $user->iplimit < $ipcount
            ) {
                continue;
            }
			
			$user->iplimit = (int)$user->iplimit;
			$user->speedlimit = (float)$user->speedlimit;
			$user->id = (int)$user->id;
			$user->email = "user_".$user->id.'@xmplus.user';
			// Global occupancy cannot reserve capacity for a future source IP.
			// Keep native per-node admission; a known IP may switch nodes at full quota.
			$user->ipcount = 0;
			$user->passwd = $user->uuid;
			
			$user = self::keyFilter($user, $key_list);
            $users[] = $user;
		}

		$etag = sha1(json_encode($users));
		if (strpos($request->getHeaderLine('If-None-Match'), $etag) !== false) {
			return $response->withStatus(304);
		}
		
		$response->withHeader('Etag', $etag);
		$response->getBody()->write(json_encode(['subscriptions' => $users]));
		return $response;
	}
	
	public function addTraffic($request, $response, $args)
    {
		ini_set('memory_limit', '-1');
		$serverid = $args['id'];		
        $server = Server::where('id', '=', $serverid)->first();
        if ($server == null){
            $res = ['data' => 'TrafficApi: ServerID Not Found'];
            $response->getBody()->write(json_encode($res));
		    return $response;
        }

		$data = $request->getParsedBody()['data'];
	
		$rate = (float) $server->server_rate;
		$sum = 0;		
		
        foreach ($data as $log){
            $u = $log['u'];
            $d = $log['d'];
			
            $user = User::find($log['subscription_id']);
			if ($user == null){
                continue;
            }
			
			$user->update([
				'u' => $user->u + (int)($u * $rate),
				'd' => $user->d + (int)($d* $rate),
				'total_data_used' => $user->total_data_used + (int)(($u* $rate) + ($d* $rate)),
				't' => time()
			]);
			
			$sum += $u + $d;	
			
			if ($this->config->get('disable_trafficlog') == 0) {	
				TrafficLog::insert([
					'userid' 		=> $user->id,
					'username' 		=> $user->username,
					'serverid' 		=> $serverid,
					'email' 	    => $user->email,
					'u' 			=> $u * $rate,
					'd' 			=> $d * $rate,
					'servername' 	=> $server->name,
					'rate' 			=> $rate,
					'total' 		=> ($u + $d) * $rate,
					'datetime' 		=> time(),
				]);
			}
        }
        
        $server->increment('bandwidth', $sum);
		
        $res = ['data' => 'ok'];
        $response->getBody()->write(json_encode($res));
		return $response;
    }

    public function addOnlineIP($request, $response, $args)
    { 
	    ini_set('memory_limit', '-1');
        $serverid = $args['id'];
        $server = Server::where('id', '=', $serverid)->first();
        if ($server == null){
            $res = ['data' => 'OnlineApi: ServerID Not Found'];
            $response->getBody()->write(json_encode($res));
		    return $response;
        }
		
        $data = $request->getParsedBody()['data'];
		
        foreach ($data as $log){
            $ip = $log['ip'];
          
			$user = User::find($log['subscription_id']);
			if($user == null){
                continue;
            }
			
			$ip = (new \App\Helpers\Helpers)->getRealIp($ip);
			if (Server::where('server_ip', $ip)->first() != null) {
				continue;
			}
			
			
			$exist = DB::table(OnlineIp::getTableName())->where('userid', $user->id)
				->where('ip', $ip)->where('serverid', $serverid)->orderBy('id', 'desc')->take(1)->first();
			if($exist){
				DB::table(Onlineip::getTableName())->where('id', $exist->id)->update([
					'serverid' => $serverid,
					'servername' => $server->name,
					'datetime' => time(),
				]);
			}else{	
				OnlineIp::insert([
					'userid' 		=> $user->id,
					'serverid' 		=> $serverid,
					'ip' 			=> $ip,
					'datetime' 		=> time(),
					'username' 		=> $user->username,
					'servername' 	=> $server->name
				]);
			}
			
        }
			
        $res = [
			'data' => 'ok' 
		];
		
       $response->getBody()->write(json_encode($res));
	   return $response;
    }	
	
    public function keyFilter($object, $filter_array)
    {
        foreach ($object as $key => $value) {
            if (!in_array($key, $filter_array)) {
                unset($object->$key);
            }
        }
        return $object;
    }
}
