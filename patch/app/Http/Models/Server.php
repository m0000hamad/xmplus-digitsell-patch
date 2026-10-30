<?php

namespace App\Http\Models;

use App\Helpers\Helpers;
use App\Helpers\Emoji;

final class Server extends Model
{
    /** Only a verified subscription-profile request supplies an override. */
    public function getAddressAttribute($value)
    {
        require_once dirname(__DIR__, 2) . '/Patch/SubscriptionProfiles.php';
        return \SubscriptionProfiles::address((int) $this->id, $value);
    }

    public function getNameAttribute($value)
    {
        require_once dirname(__DIR__, 2) . '/Patch/SubscriptionProfiles.php';
        return \SubscriptionProfiles::name((int) $this->id, $value);
    }

    protected $connection = 'default';
    protected $table = 'servers';
	protected $guarded = ['id'];

    public function is_relay()
    {
		if($this->relayid > 0 && $this->relay_type == 1) {
           return "<span class='badge bg-soft-success text-success'>" . $this->id . " <i class='fa-solid fa-arrow-right-long'></i> " . $this->relayid . "</span>";
        }elseif($this->relayid > 0 && $this->relay_type == 2) {
			return "<span class='badge bg-soft-success text-info'>" . $this->id . " <i class='fa-solid fa-arrow-right-long'></i> " . $this->relayid . "</span>";
		}else{
		   return '---';
		}
    }

    public function onlinecount()
    {
		$config = new \App\Provider\ConfigProvider;
		return OnlineIp::where('datetime', '>', (time() - 60))->where('serverid', $this->id)->count();
	}

    public function online()
    {
		$state = $this->getServerStatus();

		if($state == 1){
			return	'<i class="fa fa-circle" style="color: #05b34d"></i> ';
		}elseif($state == -1){
			return	'<i class="fa fa-circle" style="color: #ff0808"></i> ';
		}elseif($state == 0){
			return  '<i class="fa fa-circle" style="color: #ffc107"></i> ';
		}elseif($state == 2){
			return  '<i class="fa fa-circle" style="color: #ffc107"></i> ';
		}
    }

	public function getServerStatus(): int
    {
		$config = new \App\Provider\ConfigProvider;
        if ($this->relayid > 0 && $this->relay_type == 2) {
            $server = Server::find($this->relayid);
			if ($server->heartbeat == 0){
				return 0;
			}
			return $server->heartbeat > time() - 70 ? 1 : -1;
        }else if ($this->heartbeat == 0){
			 return 0;
		}
        return $this->heartbeat > time() - 70 ? 1 : -1;
    }

    public function isServerOnline()
    {
        $config = new \App\Provider\ConfigProvider;
        if ($this->heartbeat === 0) {
            return false;
        }
        return ($this->heartbeat > time() - 120);
    }

    public function servername($emoji)
    {
		/*
		if($emoji == true){
			$country = Country::where('iso',$this->country)->first();
			return $country->emoji.' '.$this->name;
		}else{
			return $this->name;
		}
		*/
		if($emoji == true){
			$emoji = (new Emoji)->getEmoji($this->country);
			return $emoji.' '.$this->name;
		}else{
			return $this->name;
		}
    }

	public function getServerItem(User $user, string $type, bool $emoji): array
    {
		if($this->relayid > 0 && $this->relay_type == 2) {
			$item = $this->getRelayServerItem($user, $type, $emoji);
		}else{
			$item = $this->getRealServerItem($user, $type, $emoji);
		}
		return $item;
	}

    public function port(): int
    {
        $server_port = explode("-", $this->port);
        if (count($server_port) > 1) {
            return (int)rand((int)$server_port[0], (int)$server_port[1]);
        } else {
            return (int)$this->port;
        }
    }

    public function listeningport(): int
    {
        $server_port = explode("-", $this->listeningport);
        if (count($server_port) > 1) {
            return (int)rand((int)$server_port[0], (int)$server_port[1]);
        } else {
            return (int)$this->listeningport;
        }
    }

	public function getRealServerItem(User $user, string $type, bool $emoji): array
    {
		$securitySettings 	= json_decode($this->securitySettings,true, JSON_UNESCAPED_SLASHES);
		$networkSettings 	= json_decode($this->networkSettings,true, JSON_UNESCAPED_SLASHES);
		$network = isset($networkSettings['transport']) ? $networkSettings['transport'] : '';

		$shortid = '';
		if(isset($securitySettings['shortids'])){
			$shortids = (array)$securitySettings['shortids'] ;
			$shortid = $shortids[array_rand($shortids)];
		}

		$serverName ='';
		if(isset($securitySettings['serverNames'])){
			$serverNames = (array)$securitySettings['serverNames'] ;
			$serverName = $serverNames[array_rand($serverNames)];
		}else{
			$serverName = $securitySettings['serverName'];
		}

		$item['type']   	= strtolower($type);
		$item['name']     	= $this->name;
		$item['remark']   	= self::servername($emoji);
		$item['add'] 		= $this->address;
		$item['ip'] 		= $this->server_ip;
		$item['port'] 		= (int)$this->port();
		$item['method'] 	= $this->cipher;
		$item['net']	  	= $network;
		$item['tls']	  	= $this->security != "none" ? $this->security : "";
		$item['fingerprint'] = $securitySettings['fingerprint'] ?? '';
		$item['sni']      	= isset($securitySettings['sni']) ? $securitySettings['sni'] : $serverName;
		$item['verify_cert'] 	= isset($securitySettings['allowInsecure']) && $securitySettings['allowInsecure'] == true  ? 1 : 0;
		$item['allowinsecure'] 	= isset($securitySettings['allowInsecure']) && $securitySettings['allowInsecure'] == true  ? 1 : 0;
		$item['spiderx'] = $securitySettings['spiderx'] ?? '';
		$item['publickey'] = $securitySettings['publickey'] ?? '';
		$item['shortid'] = $shortid;
		$item['fragment'] = (int)$this->fragment;
		$item['fragment_value'] = $this->fragment_value;
		$item['alpn'] = $securitySettings['alpn'] ?? [];
		switch ($network) {
			case 'tcp':
				$item['headerType'] = isset($networkSettings['header']['type']) ? $networkSettings['header']['type'] : "none";
				$item['path'] = isset($networkSettings['header']['request']['path']) ? $networkSettings['header']['request']['path'] : "/";

				if(isset($networkSettings['header']['request']['headers']['Host'])){
					$host = (array)$networkSettings['header']['request']['headers']['Host'];
					$item['host'] = $host[array_rand($host)];
				}else{
					$item['host'] = "";
				}
				break;
			case 'grpc':
				$item['headerType'] = "none";
				$item['serviceName'] = $networkSettings['serviceName'] ?? "";
				$item['authority']  = $networkSettings['authority'] ?? "";
				break;
			case 'quic':
				$item['quic_security'] = $networkSettings['security'] ?? "";
				$item['quic_key']  = $networkSettings['key'] ?? "";
				$item['headerType'] = isset($networkSettings['header']['type']) ? $networkSettings['header']['type'] : "none";
				break;
			case 'kcp':
				$item['headerType'] = isset($networkSettings['header']['type']) ? $networkSettings['header']['type'] : "none";
				$item['seed'] = $networkSettings['seed'] ?? "";
				$item['congestion'] = $networkSettings['congestion'] ?? false;
				break;
			case 'h2':
			case 'ws':
			case 'httpupgrade':
			case 'splithttp':
				$item['headerType'] = "none";
				$item['path']  = $networkSettings['path'] ?? "/";
				if(isset($networkSettings['host']) && $networkSettings['host'] == "" && (isset($networkSettings['cdn_host']) || isset($networkSettings['custom_host']))){
					$item['host'] =  $networkSettings['cdn_host'] ?? $networkSettings['custom_host'];
				}elseif(isset($networkSettings['host']) && $networkSettings['host'] != ""){
					$item['host'] = $networkSettings['host'];
				}else{
					$item['host'] = "";
				}
				break;
		}

		$methods = [
			'2022-blake3-aes-128-gcm',
			'2022-blake3-aes-256-gcm',
			'2022-blake3-chacha8-poly1305',
			'2022-blake3-chacha12-poly1305',
			'2022-blake3-chacha20-poly1305',
		];
		switch ($type) {
			case 'Shadowsocks':
				if (in_array($this->cipher, $methods)) {
					if ($this->cipher == '2022-blake3-aes-128-gcm') {
						$userKey = (new Helpers)->uuidToBase64($user->uuid, 16);
						$serverKey = (new Helpers)->getServerKey($this->created_at, 16);
					}else{
						$userKey = (new Helpers)->uuidToBase64($user->uuid, 32);
						$serverKey = (new Helpers)->getServerKey($this->created_at, 32);
					}
					$password = "{$serverKey}:{$userKey}";
				}else{
					$password = $user->uuid;
				}
				$item['passwd']   = $password;
				break;
			case 'Vless':
				$item['id']		  = $user->uuid;
				$item['passwd']   = $user->uuid;
				$item['flow']	  = isset($networkSettings['flow']) ? $networkSettings['flow'] : "";
				break;
			case 'Vmess':
				$item['id']		  = $user->uuid;
				$item['passwd']   = $user->uuid;
				$item['alterid']  = 0;
				break;
			case 'Trojan':
				$item['passwd']   = $user->uuid;
				break;
		}
		return $item;
	}

	public function getRelayServerItem(User $user, string $type, bool $emoji): array
    {
		$server = Server::find($this->relayid);

		$securitySettings 	= json_decode($server->securitySettings,true, JSON_UNESCAPED_SLASHES);
		$networkSettings 	= json_decode($server->networkSettings,true, JSON_UNESCAPED_SLASHES);
		$network = $networkSettings['transport'] ?? '';

		$shortid = '';
		if(isset($securitySettings['shortids'])){
			$shortids = (array)$securitySettings['shortids'] ;
			$shortid = $shortids[array_rand($shortids)];
		}

		$serverName ='';
		if(isset($securitySettings['serverNames'])){
			$serverNames = (array)$securitySettings['serverNames'] ;
			$serverName = $serverNames[array_rand($serverNames)];
		}else{
			$serverName = $securitySettings['serverName'];
		}

		$item['type']   	= strtolower($type);
		$item['name']     	= $this->name;
		$item['remark']   	= self::servername($emoji);
		$item['add'] 		= $this->address;
		$item['port'] 		= (int)$this->port();
		$item['method'] 	= $server->cipher;
		$item['net']	  	= $network;
		$item['tls']	  	= $server->security != "none" ? $server->security : "";
		$item['fingerprint'] = $securitySettings['fingerprint'] ?? '';
		$item['ip'] 		= $this->server_ip;
		$item['sni']      	= isset($securitySettings['sni']) ? $securitySettings['sni'] : $serverName;
		$item['verify_cert'] 	= (isset($securitySettings['allowInsecure']) && $securitySettings['allowInsecure'] == true  ? 1 : 0);
		$item['allowinsecure'] 	= (isset($securitySettings['allowInsecure']) && $securitySettings['allowInsecure'] == true  ? 1 : 0);
		$item['spiderx'] = $securitySettings['spiderx'] ?? '';
		$item['publickey'] = $securitySettings['publickey'] ?? '';
		$item['shortid'] = $shortid;
		$item['fragment'] = (int)$server->fragment;
		$item['fragment_value'] = $server->fragment_value;
		$item['alpn'] = $securitySettings['alpn'] ?? [];
		switch ($network) {
			case 'tcp':
				$item['headerType'] = isset($networkSettings['header']['type']) ? $networkSettings['header']['type'] : "none";
				$item['path'] = isset($networkSettings['header']['request']['path']) ? $networkSettings['header']['request']['path'] : "/";
				if(isset($networkSettings['header']['request']['headers']['Host'])){
					$host = (array)$networkSettings['header']['request']['headers']['Host'];
					$item['host'] = $host[array_rand($host)];
				}else{
					$item['host'] = "";
				}
				break;
			case 'grpc':
				$item['headerType'] = "none";
				$item['serviceName'] = $networkSettings['serviceName'] ?? "";
				$item['authority']  = $networkSettings['authority'] ?? "";
				break;
			case 'quic':
				$item['quic_security'] = $networkSettings['security'] ?? "";
				$item['quic_key']  = $networkSettings['key'] ?? "";
				$item['headerType'] = isset($networkSettings['header']['type']) ? $networkSettings['header']['type'] : "none";
				break;
			case 'kcp':
				$item['headerType'] = isset($networkSettings['header']['type']) ? $networkSettings['header']['type'] : "none";
				$item['seed'] = $networkSettings['seed'] ?? "";
				$item['congestion'] = $networkSettings['congestion'] ?? false;
				break;
			case 'h2':
			case 'ws':
			case 'httpupgrade':
			case 'splithttp':
				$item['headerType'] = "none";
				$item['path']  = $networkSettings['path'] ?? "/";
				if(isset($networkSettings['host']) && $networkSettings['host'] == "" && (isset($networkSettings['cdn_host']) || isset($networkSettings['custom_host']))){
					$item['host'] =  $networkSettings['cdn_host'] ?? $networkSettings['custom_host'];
				}elseif(isset($networkSettings['host']) && $networkSettings['host'] != ""){
					$item['host'] = $networkSettings['host'];
				}else{
					$item['host'] = "";
				}
				break;
		}

		$methods = [
			'2022-blake3-aes-128-gcm',
			'2022-blake3-aes-256-gcm',
			'2022-blake3-chacha8-poly1305',
			'2022-blake3-chacha12-poly1305',
			'2022-blake3-chacha20-poly1305',
		];
		switch ($type) {
			case 'Shadowsocks':
				if (in_array($server->cipher, $methods)) {
					if ($server->cipher == '2022-blake3-aes-128-gcm') {
						$userKey = (new Helpers)->uuidToBase64($user->uuid, 16);
						$server_key = (new Helpers)->getServerKey($server->created_at, 16);
					}else{
						$userKey = (new Helpers)->uuidToBase64($user->uuid, 32);
						$server_key = (new Helpers)->getServerKey($server->created_at, 32);
					}
					$password = "{$server_key}:{$userKey}";
				}else{
					$password = $user->uuid;
				}
				$item['passwd']   = $password;
				break;
			case 'Vless':
				$item['id']		  = $user->uuid;
				$item['passwd']   = $user->uuid;
				$item['flow']	  = isset($networkSettings['flow']) ? $networkSettings['flow'] : "";
				break;
			case 'Vmess':
				$item['id']		  = $user->uuid;
				$item['passwd']   = $user->uuid;
				$item['alterid']  = 0;
				break;
			case 'Trojan':
				$item['passwd']   = $user->uuid;
				$item['flow']	  = isset($networkSettings['flow']) ? $networkSettings['flow'] : "";
				break;
		}
		return $item;
	}
}
