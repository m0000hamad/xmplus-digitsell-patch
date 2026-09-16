<?php
namespace App\Jobs;

use App\Helpers\Helpers;
use App\Http\Models\Queue;
use App\Http\Models\User;
use App\Http\Models\Order;
use App\Http\Models\Currency;
use Illuminate\Database\Capsule\Manager;

class UserJob
{
	public $settings;
	
	public $translate;
	
	public function __construct()
    {
		$this->settings  = new \App\Provider\ConfigProvider;
		$this->translate = new \App\Library\Localization\Localization;
	}	
	
	public function genUUID()
	{
		echo 'Resetting all users uuid' . PHP_EOL;
		$users = Manager::table(User::getTableName())->get();
		foreach ($users as $user) {
			Manager::table(User::getTableName())->where('id', $user->id)->update([
				"uuid" => (new Helpers)->gUID(true),
			]);
		}
		echo 'Resetting all users uuid complete' . PHP_EOL;
	}	
	
	/*
	 * One row per user, overwritten at every expiry. Written defensively: a
	 * missing table must never stop the expiry job from running.
	 */
	private function snapshotTraffic($user)
	{
		try {
			Manager::table('timeplan_snapshot')->updateOrInsert(
				['userid' => $user->id],
				[
					'transfer_enable' => $user->transfer_enable,
					'u'               => $user->u,
					'd'               => $user->d,
					'used'            => $user->used,
					'total_data_used' => $user->total_data_used,
					'expire_in'       => $user->expire_in,
					'taken_at'        => time(),
				]
			);
		} catch (\Throwable $error) {
			// nothing to do - the grace-window restore simply has no snapshot
		}
	}

	public function dispatch()
	{
		ini_set('memory_limit', '-1');
	
		$orders =  Manager::table(Order::getTableName())->where('status', 0)->where("gateway_expire", "<", time())->get();
		if($orders){
			foreach ($orders as $order) {
				Manager::table(Order::getTableName())->where('id', $order->id)->update([
					'status' => -1
				]);
			}
		}
		
		$users =  Manager::table(User::getTableName())->get();
		
		foreach ($users as $user) {	
			if($user->currency != $this->settings->get("default_currency")){
				$ex = Manager::table(Currency::getTableName())
					->where('currency', strtoupper($this->settings->get("default_currency")))->first();
			
				Manager::table(User::getTableName())->where('id', $user->id)->update([
					"money" => $user->money * $ex->rate,
					'currency' => $this->settings->get("default_currency")
				]);
			}
			
			if ((strtotime($user->expire_in) < time()) && $user->data_expire_cron == 0)
			{
				/*
				 * The traffic is about to be wiped. Someone who buys extra time
				 * during the grace window right after expiry paid for days, not
				 * for data, so what they had left is kept here and put back by
				 * bin/timeplans.php - see app/Http/Models/Package.php.
				 */
				$this->snapshotTraffic($user);

				Manager::table(User::getTableName())->where('id', $user->id)->update([
					"transfer_enable" => 0,
					'u' => 0,
					'd' => 0,
					'used' => 0,
					'total_data_used' => 0,
					'data_expire_cron'=> 1
				]);
				
				$notification = json_decode($user->notification,true);
			
				if ($this->settings->get('enablenotifications') == 1 && 
					$this->settings->get('maildriver') == 1 && 
					(isset($notification['dataexpire']) && $notification['dataexpire'] == 1) 
				){
					$subject  = $this->settings->get('appName') . " - " . $this->translate->get('ExpireNotice');					
					$array = [
						'username' => $user->username,
					];
							
					Queue::insert([
						'to_email' 	=> $user->email,
						'subject' 	=> $subject,
						'telegramid' => $user->telegram_id,
						'template' 	=> 'expired.tpl',
						'array'	=> \json_encode($array),
						'time' 		=> time()
					]);
				}
			}elseif ((strtotime($user->expire_in) > time()) && $user->data_expire_cron == 1) {
				Manager::table(User::getTableName())->where('id', $user->id)->update([
					'data_expire_cron'=> 0
				]);
            }
			
			if (strtotime($user->expire_in) > time() && $user->transfer_enable <= ($user->u + $user->d) && $user->data_used_cron == 0)
			{
				Manager::table(User::getTableName())->where('id', $user->id)->update([
					'data_used_cron'=> 1
				]);
				
				$notification = json_decode($user->notification,true);
			
				if ($this->settings->get('enablenotifications') == 1 && 
					$this->settings->get('maildriver') == 1 && 
					(isset($notification['dataused']) && $notification['dataused'] == 1) 
				){
					$subject  = $this->settings->get('appName') . " - " . $this->translate->get('DataUsedUpNotice');
					$array = [
						'username' => $user->username,
						'enableddata'=> (new Helpers)->trafficConvert($user->transfer_enable),
						'useddata'	=> (new Helpers)->trafficConvert($user->u + $user->d),
					];
							
					Queue::insert([
						'to_email' 	=> $user->email,
						'subject' 	=> $subject,
						'telegramid' => $user->telegram_id,
						'template' 	=> 'dataused.tpl',
						'array'	=> \json_encode($array),
						'time' 		=> time()
					]);
				}
            } elseif ((strtotime($user->expire_in) < time() && $user->data_used_cron == 1) || (strtotime($user->expire_in) > time() && $user->transfer_enable > ($user->u + $user->d) && $user->data_used_cron == 1)) {
				Manager::table(User::getTableName())->where('id', $user->id)->update([
					'data_used_cron'=> 0
				]);
            }	
		}
	}
}