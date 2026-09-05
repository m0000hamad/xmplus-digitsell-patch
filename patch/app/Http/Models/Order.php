<?php

namespace App\Http\Models;

use App\Library\Localization\Localization;

final class Order extends Model
{
    protected $connection = 'default';
    protected $table = 'orders';
	protected $guarded = ['id'];

	public function user(): ?User
    {
        return User::find($this->userid);
    }
	
    public function package()
    {
		$package = Package::where('id', $this->packageid)->first();
		if($package){
			return $package->name;
		}else{
			return "--";
		}
	}
	
	public function gateway($id){
		if($id == -1) return (new Localization())->get('AccBalance');
		$gateway = Payment::find($id);
		if($gateway){
			return $gateway->name;
		}
		return "---";
	}
	
	public function Plan(){
		return Package::find($this->packageid);
	}
	
	public function OrderCount($userid){
		return self::where('status', 1)->where('userid', $userid)->count();
	}
	
	public function getActive($userid){
		return self::where('userid', $userid)->where("status", 1)->where("packagetype", 2)
			->where("expire", '>', time())->orderBy('id', 'desc')->get();
	}
	
	public function getSubsciption($userid)
	{
		// The expiry filter used to be commented out, so every account that had
		// ever paid still looked subscribed - 1,764 of them. Filtering on `expire`
		// matches getActive() above, which is the convention the rest of the code
		// already follows.
		return self::where('userid', $userid)->where("status", 1)->where("packagetype", 2)
			->where("expire", '>', time())->orderBy('id', 'desc')->take(1)->first();
		/*
		self::where("status", 1)->where('userid', $userid)->where("packagetype",2)
			->where(static function ($query): void {
                $query->whereRaw('((plan_expire * 86400) + pay_date) > UNIX_TIMESTAMP(NOW())');
            })->orderBy('id', 'desc')->take(1)->first();*/	
	}

	public function getPackage($userid)
    {
		$order = self::where("status", 1)->where('userid', $userid)->where("packagetype", 2)->orderBy('id', 'desc')->take(1)->first();	
			
		if(!$order){
			return null;
		}
		
		$package = Package::find($order->packageid);
		if($package){
			return $package;
		}else{
			return null;
		}	
	}
	
	public function Valid(): bool
    {
		$time = (time() - ($this->plan_expire * 86400));
        if ($time < $this->pay_date) {
            return true;
        }
        return false;
    }
	
	public function RemDays($user): int
    {
		$now = new \DateTime('today');
		$expire_in = new \DateTime($user->expire_in);
		$interval = $now->diff($expire_in);
		$day_lefts = $interval->format('%a');
		return $day_lefts;		
    }
	
    public function resetTime($unix = false)
    {
        if ($this->reset_days > 0) {
            $day = 24 * 60 * 60;
            $resetIndex = 1 + (int) ((time() - $this->pay_date - $day) / ($this->reset_days * $day));
			
            $restTime = $resetIndex * $this->reset_days * $day + $this->pay_date;
            $time = time() + ($day * 86400);
            return ! $unix ? date('Y-m-d', strtotime('+1 day', strtotime(date('Y-m-d', (int) $restTime)))) : $time;
        }
        return ! $unix ? '-' : 0;
    }
	
	public function expTime($unix = false)
    {
        $time = $this->pay_date + ($this->plan_expire * 86400);
        return ! $unix ? date('Y-m-d H:i:s', (int) $time) : $time;
    }
	
	public function ResetIn($userid)
    {	
		$order = self::where('userid', $userid)->where("status", 1)->where("packagetype", 2)
			->where("expire", '>', time())->orderBy('id', 'desc')->take(1)->first();
		
		if(!$order || ($order->reset_days <= 0 || $order->reset_days == "")){
			return null; 
		}
		$user = User::find($order->userid);
		
		$now = new \DateTime('today');
		$expire_in = new \DateTime($user->expire_in);
		$interval = $now->diff($expire_in);
		$day_lefts =  $interval->format('%a');

		if(($day_lefts % $order->reset_days) == 0 && $day_lefts > $order->reset_days){
			$reset = str_replace(['%traffic%','%days%'], [$order->bandwidth, $order->reset_days], (new Localization())->get('TrafficReset'));
		}elseif(($day_lefts % $order->reset_days) != 0){
			$reset = str_replace(['%traffic%','%days%'], [$order->bandwidth, ($day_lefts % $order->reset_days)], (new Localization())->get('TrafficReset'));
		}else{
			$reset = null;
		}
		
		return	$reset;
	}
	
	public function order_status($value)
	{
		$translate = new Localization;
		switch($value){
			case -2:	
				return '<span class="badge bg-soft-danger text-danger" style="width:100px">'.$translate->get('Canceled').'</span>';
				break;
			case -1:
				return '<span class="badge bg-soft-warning text-warning" style="width:100px">'.$translate->get('Timedout').'</span>';
				break;
			case 0:
				return '<span class="badge bg-soft-info text-info" style="width:100px">'.$translate->get('Pending').'</span>';
				break;
			case 1:
				return  '<span class="badge bg-soft-success text-success" style="width:100px">'.$translate->get('Paid').'</span>';
				break;
			case 2:
				return '<span class="badge bg-soft-dark text-dark" style="width:100px">'.$translate->get('Notified').'</span>';
				break;
		}
	}	
}
