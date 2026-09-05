<?php
namespace App\Jobs;

use App\Http\Models\Verify;
use App\Http\Models\OnlineIp;
use App\Http\Models\TrafficLog;
use App\Http\Models\SubscribeLog;

class LogsJob 
{
	public function dispatch()
    {
		ini_set('memory_limit', '-1');
        Verify::truncate();
        OnlineIp::where('datetime','<',time() - 100)->delete();

		// summarise the raw rows before they are dropped, otherwise the
		// weekly/monthly/yearly usage charts have nothing to read from
		(new TrafficStatsJob)->dispatch();

		TrafficLog::where('datetime','<',strtotime('today 00:00:00'))->delete();	
		SubscribeLog::truncate();
	}	
}
