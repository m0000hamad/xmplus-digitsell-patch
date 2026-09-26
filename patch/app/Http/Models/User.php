<?php
namespace App\Http\Models;

use App\Helpers\Helpers;
use App\Services\MailService;
use Illuminate\Database\Capsule\Manager as DB;

final class User extends Model
{
	public $isLogin;
	
    protected $connection = 'default';
    protected $table = 'user';
	
    protected $casts = [
        'status'          => 'int',
        'role'        	  => 'int',
        'speedlimit'      => 'float',
		'ref_by'          => 'int'
    ];

    public function image()
    {
        $hash = md5(strtolower(trim($this->email)));
        return 'https://api.dicebear.com/6.x/identicon/svg?seed=' . $hash;
    }
	
	public function enableTraffic()
    {
        return (new Helpers)->trafficConvert($this->transfer_enable);
    }
	
    public function usedTraffic()
    {
        $total = $this->u + $this->d;
        return (new Helpers)->trafficConvert($total);
    }
	
	public function enableTrafficInGB()
    {
        $transfer_enable = $this->transfer_enable;
        return (new Helpers)->flowToGB($transfer_enable);
    }
	
    public function unusedTraffic()
    {
        $total = $this->u + $this->d;
        $transfer_enable = $this->transfer_enable;
        return (new Helpers)->trafficConvert($transfer_enable - $total);
    }
	
    public function TodayTraffic()
    {
        $total = ($this->u + $this->d) - $this->used;
        return (new Helpers)->trafficConvert($total);
    }
	
	public function usedTrafficPercent(): float
    {
        // PDO hands this back as a string, so === never matched "0" and an
        // account with no quota divided by zero and took the dashboard down
        if ((float) $this->transfer_enable <= 0) {
            return 0;
        }
        $percent = ($this->u + $this->d) / $this->transfer_enable;
        $percent = round($percent, 2);
        return (float) $percent * 100;
    }
	
	public function unusedTrafficPercent(): float
    {
        if ((float) $this->transfer_enable <= 0) {
            return 0;
        }
        $unused = $this->transfer_enable - ($this->u + $this->d);
		if ($unused == 0) {
            return 0;
        }
        $percent = $unused / $this->transfer_enable;
        $percent = round($percent, 2);
        return $percent * 100;
    }

    public function getRawUnusedTrafficUsage()
    {
        return $this->transfer_enable - ($this->u + $this->d);
    }
	
	public function getRawusedTrafficUsage()
    {
        return  ($this->u + $this->d);
    }

    public function getRawTotalTraffic()
    {
        return $this->transfer_enable;
    }
	
    public function UserHash()
    {
        return hash_hmac('sha256',$this->email, (new \App\Provider\ConfigProvider)->get('tawkapi'));
    }

	private function IpCount()
    {
		$db = DB::getPdo();
        $res = [];
		foreach ($db->query("SELECT `userid`, COUNT(DISTINCT `ip`) AS `count` FROM `online_ip` WHERE `datetime` >= UNIX_TIMESTAMP(NOW()) - 60 GROUP BY `userid`") as $line) {
            $res[strval($line->userid)] = $line->count;
        }
        return $res;
    }
	
	
	public function online_ip_count(): int
    {
		$ip_count = 0;
		$ipcount = $this->IpCount();
		if(isset($ipcount[strval($this->id)])){
			$ip_count += $ipcount[strval($this->id)];
		}
		return $ip_count;
    }	
	
    public function sendMail(string $subject, string $template, array $arr = [], array $files = [], $is_queue = false): bool
    {
        if ($is_queue) {
            // the column holds JSON (UserJob writes it the same way) - assigning
            // the raw array through the model failed with "Array to string
            // conversion" and the mail was never queued
            Queue::insert([
                'to_email'   => $this->email,
                'subject'    => $subject,
                'telegramid' => $this->telegram_id,
                'template'   => $template,
                'array'      => \json_encode($arr),
                'time'       => time()
            ]);
            return true;
        }

        if (!filter_var($this->email, FILTER_VALIDATE_EMAIL)) {
            return false;
        }

        try {
            // $arr was dropped here and [] passed instead, so every template
            // went out without its code, link or name
            (new MailService)->send(
                $this->email,
                $subject,
                $template,
                $arr,
                $files
            );
            return true;
        } catch (\Throwable $e) {
            // this used to return the message, which a bool return turns into
            // true - a failed send was reported as sent and nothing was logged
            error_log('sendMail to ' . $this->email . ' failed: ' . $e->getMessage());
            return false;
        }
    }	
	
	public function trafficChart()
    {
		ini_set('memory_limit', '-1');
	
		$userslog = [];
		$time = [];
		
		$now = date('H',strtotime('now'))+1;
		for ($hour = 0; $hour < $now; $hour++)
		{
			$times = strtotime('today 00:00:00') + ($hour * 3600);
			$userslog[] = (new Helpers)->flowToMB(TrafficLog::where('userid', $this->id)->where("datetime", ">=",$times)->where('datetime', '<',$times + 3600)->sum('total'));
			$time[] = date('H:i',$times);
		}

		$data["data"]   = $userslog;
		$data["labels"] = $time;

		return $data;	
	}	
	
	/* ------------------------------------------------------------------
	 * Usage statistics used by the dashboard chart.
	 * Today comes straight from trafficlog (live), everything older comes
	 * from the traffic_daily roll-up table filled by TrafficStatsJob.
	 * ------------------------------------------------------------------ */

	private function toMB($up, $down)
	{
		return [
			'up'    => round($up / 1048576, 2),
			'down'  => round($down / 1048576, 2),
			'total' => round(($up + $down) / 1048576, 2),
		];
	}

	private function liveTodayTraffic()
	{
		$row = TrafficLog::where('userid', $this->id)
			->where('datetime', '>=', strtotime('today 00:00:00'))
			->selectRaw('COALESCE(SUM(u),0) AS su, COALESCE(SUM(d),0) AS sd')
			->first();

		return ['u' => (float) ($row ? $row->su : 0), 'd' => (float) ($row ? $row->sd : 0)];
	}

	private function liveTodayServers()
	{
		$out = [];
		$rows = TrafficLog::where('userid', $this->id)
			->where('datetime', '>=', strtotime('today 00:00:00'))
			->selectRaw('serverid, MAX(servername) AS sname, COALESCE(SUM(u),0) AS su, COALESCE(SUM(d),0) AS sd')
			->groupBy('serverid')
			->get();

		foreach ($rows as $row) {
			$out[(int) $row->serverid] = [
				'name' => (string) $row->sname,
				'u'    => (float) $row->su,
				'd'    => (float) $row->sd,
			];
		}
		return $out;
	}

	private function historyByDay($fromDate)
	{
		$map = [];
		try {
			$rows = TrafficDaily::where('userid', $this->id)
				->where('day', '>=', $fromDate)
				->where('day', '<', date('Y-m-d'))
				->selectRaw('day, COALESCE(SUM(u),0) AS su, COALESCE(SUM(d),0) AS sd')
				->groupBy('day')
				->get();

			foreach ($rows as $row) {
				$map[substr((string) $row->day, 0, 10)] = ['u' => (float) $row->su, 'd' => (float) $row->sd];
			}
		} catch (\Throwable $e) {
			$map = [];
		}

		$map[date('Y-m-d')] = $this->liveTodayTraffic();
		return $map;
	}

	private function historyByServer($fromDate)
	{
		$map = [];
		try {
			$rows = TrafficDaily::where('userid', $this->id)
				->where('day', '>=', $fromDate)
				->where('day', '<', date('Y-m-d'))
				->selectRaw('serverid, MAX(servername) AS sname, COALESCE(SUM(u),0) AS su, COALESCE(SUM(d),0) AS sd')
				->groupBy('serverid')
				->get();

			foreach ($rows as $row) {
				$map[(int) $row->serverid] = [
					'name' => (string) $row->sname,
					'u'    => (float) $row->su,
					'd'    => (float) $row->sd,
				];
			}
		} catch (\Throwable $e) {
			$map = [];
		}

		foreach ($this->liveTodayServers() as $id => $server) {
			if (isset($map[$id])) {
				$map[$id]['u'] += $server['u'];
				$map[$id]['d'] += $server['d'];
				if ($server['name'] != '') {
					$map[$id]['name'] = $server['name'];
				}
			} else {
				$map[$id] = $server;
			}
		}

		return $map;
	}

	private function serverList($map)
	{
		$list = [];
		foreach ($map as $id => $server) {
			$mb = $this->toMB($server['u'], $server['d']);
			if ($mb['total'] <= 0) {
				continue;
			}
			$list[] = [
				'id'    => (int) $id,
				'name'  => $server['name'] != '' ? $server['name'] : ('#' . $id),
				'up'    => $mb['up'],
				'down'  => $mb['down'],
				'total' => $mb['total'],
			];
		}

		usort($list, function ($a, $b) {
			if ($a['total'] == $b['total']) {
				return 0;
			}
			return ($a['total'] < $b['total']) ? 1 : -1;
		});

		return $list;
	}

	private function sumSeries($series)
	{
		return [
			'up'    => round(array_sum($series['up']), 2),
			'down'  => round(array_sum($series['down']), 2),
			'total' => round(array_sum($series['total']), 2),
		];
	}

	public function usageStats()
	{
		ini_set('memory_limit', '-1');

		$stats = ['ranges' => [], 'servers' => [], 'totals' => []];

		/* ---- today, hour by hour ---- */
		$start   = strtotime('today 00:00:00');
		$hours   = (int) date('G') + 1;
		$buckets = array_fill(0, $hours, ['u' => 0.0, 'd' => 0.0]);

		$rows = TrafficLog::where('userid', $this->id)
			->where('datetime', '>=', $start)
			->selectRaw('FLOOR((datetime - ' . (int) $start . ') / 3600) AS bucket, COALESCE(SUM(u),0) AS su, COALESCE(SUM(d),0) AS sd')
			->groupBy('bucket')
			->get();

		foreach ($rows as $row) {
			$bucket = (int) $row->bucket;
			if ($bucket >= 0 && $bucket < $hours) {
				$buckets[$bucket] = ['u' => (float) $row->su, 'd' => (float) $row->sd];
			}
		}

		$day = ['labels' => [], 'up' => [], 'down' => [], 'total' => []];
		foreach ($buckets as $hour => $bucket) {
			$mb = $this->toMB($bucket['u'], $bucket['d']);
			$day['labels'][] = sprintf('%02d:00', $hour);
			$day['up'][]     = $mb['up'];
			$day['down'][]   = $mb['down'];
			$day['total'][]  = $mb['total'];
		}
		$stats['ranges']['day'] = $day;

		/* ---- the day history feeding week / month / year ---- */
		$history = $this->historyByDay(date('Y-m-d', strtotime('-370 days')));

		$byDays = function ($days) use ($history) {
			$series = ['labels' => [], 'up' => [], 'down' => [], 'total' => []];
			for ($i = $days - 1; $i >= 0; $i--) {
				$date   = date('Y-m-d', strtotime('-' . $i . ' days'));
				$bucket = isset($history[$date]) ? $history[$date] : ['u' => 0, 'd' => 0];
				$mb     = $this->toMB($bucket['u'], $bucket['d']);

				$series['labels'][] = $date;
				$series['up'][]     = $mb['up'];
				$series['down'][]   = $mb['down'];
				$series['total'][]  = $mb['total'];
			}
			return $series;
		};

		$stats['ranges']['week']  = $byDays(7);
		$stats['ranges']['month'] = $byDays(30);

		$year = ['labels' => [], 'up' => [], 'down' => [], 'total' => []];
		for ($i = 11; $i >= 0; $i--) {
			$month = date('Y-m', strtotime('first day of -' . $i . ' month'));
			$up = $down = 0.0;
			foreach ($history as $date => $bucket) {
				if (strpos($date, $month) === 0) {
					$up   += $bucket['u'];
					$down += $bucket['d'];
				}
			}
			$mb = $this->toMB($up, $down);
			$year['labels'][] = $month;
			$year['up'][]     = $mb['up'];
			$year['down'][]   = $mb['down'];
			$year['total'][]  = $mb['total'];
		}
		$stats['ranges']['year'] = $year;

		/* ---- totals + per server breakdown for every range ---- */
		$froms = [
			'day'   => date('Y-m-d'),
			'week'  => date('Y-m-d', strtotime('-6 days')),
			'month' => date('Y-m-d', strtotime('-29 days')),
			'year'  => date('Y-m-d', strtotime('-364 days')),
		];

		foreach ($stats['ranges'] as $range => $series) {
			$stats['totals'][$range]  = $this->sumSeries($series);
			$stats['servers'][$range] = $range == 'day'
				? $this->serverList($this->liveTodayServers())
				: $this->serverList($this->historyByServer($froms[$range]));
		}

		/* ---- servers this user is connected to right now ---- */
		$stats['live'] = [];
		try {
			// nodes report online IPs about once a minute; five minutes of
			// silence means the connection is gone
			$stats['live'] = DB::table('online_ip')
				->where('userid', $this->id)
				->where('datetime', '>=', time() - 300)
				->distinct()
				->pluck('serverid')
				->map(function ($id) { return (int) $id; })
				->values()
				->all();
		} catch (\Throwable $e) {
			$stats['live'] = [];
		}

		return $stats;
	}

	/* ------------------------------------------------------------------
	 * Plan clock helpers for the dashboard subscription card.
	 * There is no plan-start column, so the remaining share of the cycle is
	 * derived from the billing period stored on the account.
	 * ------------------------------------------------------------------ */

	/*
	 * Share of the device slots currently in use, for the little tile bar.
	 */
	public function ipPercent()
	{
		$limit = (int) $this->iplimit;

		if ($limit <= 0) {
			return 0;
		}

		$percent = ($this->online_ip_count() / $limit) * 100;

		return $percent > 100 ? 100 : round($percent, 1);
	}

	public function planIsActive()
	{
		return $this->expire_in > date('Y-m-d H:i:s', time());
	}

	/*
	 * Lifetime accounts come in two shapes: the 'onetime' billing plan, and
	 * accounts the admin set up by hand with an expiry decades away. Both must
	 * read as permanent rather than "9,000 days left".
	 */
	public function planNeverExpires()
	{
		// an expired one-time plan is expired, not permanent
		if (!$this->planIsActive()) {
			return false;
		}

		if ($this->plan == 'onetime') {
			return true;
		}

		return strtotime($this->expire_in) > strtotime('+10 years');
	}

	public function secondsLeft()
	{
		$left = strtotime($this->expire_in) - time();
		return $left > 0 ? $left : 0;
	}

	public function daysLeft()
	{
		return (int) floor($this->secondsLeft() / 86400);
	}

	public function hoursLeft()
	{
		return (int) floor(($this->secondsLeft() % 86400) / 3600);
	}

	public function planCycleDays()
	{
		$cycles = [
			'month'        => 30,
			'month_price'  => 30,
			'quarter'      => 90,
			'half_year'    => 182,
			'year'         => 365,
			'two_year'     => 730,
			'three_year'   => 1095,
		];

		$plan = (string) $this->plan;
		return isset($cycles[$plan]) ? $cycles[$plan] : 30;
	}

	/*
	 * How much of the current billing period is still ahead, as a percentage.
	 */
	public function planTimePercent()
	{
		if ($this->planNeverExpires()) {
			return 100;
		}

		$days = $this->secondsLeft() / 86400;
		$cycle = $this->planCycleDays();

		if ($cycle <= 0) {
			return 0;
		}

		$percent = ($days / $cycle) * 100;

		if ($percent > 100) { $percent = 100; }
		if ($percent < 0) { $percent = 0; }

		return round($percent, 1);
	}

	/*
	 * good / warn / critical / expired - drives the colour of the card.
	 */
	public function planHealth()
	{
		if ($this->planNeverExpires()) {
			return 'good';
		}
		if (!$this->planIsActive()) {
			return 'expired';
		}

		$days = $this->daysLeft();

		if ($days <= 2) {
			return 'critical';
		}
		if ($days <= 7) {
			return 'warn';
		}
		return 'good';
	}

	/* ------------------------------------------------------------------
	 * Buying extra days ("time plans").
	 * ------------------------------------------------------------------ */

	/*
	 * The button only appears once the subscription is close to running out,
	 * and stays reachable for a short grace window after it has. Both limits
	 * are settings so the admin can retune them without a release.
	 */
	public function timePlanWindowDays()
	{
		$days = (int) Settings::where('name', 'timeplan_visible_days')->value('value');
		return $days > 0 ? $days : 7;
	}

	public function timePlanGraceHours()
	{
		$hours = Settings::where('name', 'timeplan_grace_hours')->value('value');
		return $hours === null || $hours === '' ? 24 : (int) $hours;
	}

	public function timePlanVisible()
	{
		// a lifetime account has no expiry to extend
		if ($this->planNeverExpires() || $this->expire_in === null) {
			return false;
		}

		if ($this->planIsActive()) {
			return $this->daysLeft() <= $this->timePlanWindowDays();
		}

		$grace = $this->timePlanGraceHours();

		if ($grace <= 0) {
			return false;
		}

		return time() - strtotime($this->expire_in) <= $grace * 3600;
	}

	/* ------------------------------------------------------------------
	 * Referral commission paid straight into the wallet.
	 * ------------------------------------------------------------------ */

	/* commission that went into the spendable wallet */
	public function commissionCredited()
	{
		try {
			return (float) CommissionLog::where('userid', $this->id)
				->where('destination', 'wallet')->sum('amount');
		} catch (\Throwable $e) {
			return 0;
		}
	}

	/* commission left in the withdrawable pot because the account qualifies for cash */
	public function commissionWithdrawable()
	{
		try {
			return (float) CommissionLog::where('userid', $this->id)
				->where('destination', 'payout')->sum('amount');
		} catch (\Throwable $e) {
			return 0;
		}
	}

	public function commissionTotalEarned()
	{
		try {
			return (float) CommissionLog::where('userid', $this->id)->sum('amount');
		} catch (\Throwable $e) {
			return 0;
		}
	}

	/*
	 * Wallet money that did not come from commission - manual top-ups, refunds
	 * and the like. Shown next to the commission figure so the two are never
	 * confused with each other.
	 */
	public function walletTopUp()
	{
		$rest = (float) $this->money - $this->commissionCredited();
		return $rest > 0 ? $rest : 0;
	}

	public function commissionHistory($limit = 30)
	{
		try {
			return CommissionLog::where('userid', $this->id)
				->orderBy('id', 'desc')->limit($limit)->get();
		} catch (\Throwable $e) {
			return [];
		}
	}

	/*
	 * Credits the visitor has not been told about yet. Reading them marks them as
	 * seen, so the popup fires once per payment on whatever device gets there
	 * first - there is no route available to acknowledge it from the browser.
	 */
	public function newCommissions()
	{
		try {
			$rows = CommissionLog::where('userid', $this->id)->where('seen', 0)
				->orderBy('id', 'desc')->limit(5)->get();

			// An admin looking at someone else's portal sets $_SESSION['adminview'];
			// they still see the popup as a preview, but it stays unread so the
			// person it belongs to gets it too.
			$preview = !empty($_SESSION['adminview']);

			if (count($rows) > 0 && !$preview) {
				CommissionLog::where('userid', $this->id)->where('seen', 0)
					->update(['seen' => 1]);
			}

			return $rows;
		} catch (\Throwable $e) {
			return [];
		}
	}

	/*
	 * Which referred account produced how much commission - the money view the
	 * affiliate page shows, straight from the affiliate ledger.
	 */
	public function commissionByReferral($limit = 50)
	{
		try {
			return DB::connection('default')->table('affiliate')
				->selectRaw('userid, MAX(username) AS username, COUNT(*) AS purchases, SUM(ref_get) AS total, MAX(datetime) AS last_at')
				->where('ref_by', $this->id)
				->groupBy('userid')
				->orderByRaw('SUM(ref_get) DESC')
				->limit($limit)
				->get();
		} catch (\Throwable $e) {
			return [];
		}
	}

	/*
	 * How many accounts signed up through this user's invite link - the invite
	 * popup shows it so the nudge talks about the visitor's own numbers.
	 */
	public function referralCount()
	{
		try {
			return (int) self::where('ref_by', $this->id)->count();
		} catch (\Throwable $e) {
			return 0;
		}
	}

	/*
	 * The visitor's own invite numbers, for the invite popup and the affiliate
	 * page to talk about: who they brought in, who bought, what it earned, and
	 * what the ones who have not bought yet would bring. `per_buy` is the real
	 * average commission of one purchase over the last 90 days (falling back to
	 * the commission rate on the average paid amount), so the estimate follows
	 * actual prices instead of a made-up figure. `ask` is the handful of idle
	 * referrals the estimate is phrased around - five, or fewer if that is all.
	 */
	public function inviteInsight()
	{
		static $perBuy = null;

		$out = ['invited' => 0, 'buyers' => 0, 'earned' => 0.0, 'idle' => 0, 'per_buy' => 0.0, 'ask' => 0, 'potential' => 0.0];

		try {
			$out['invited'] = $this->referralCount();

			$mine = DB::connection('default')->table('affiliate')->where('ref_by', $this->id)
				->selectRaw('COUNT(DISTINCT userid) AS buyers, COALESCE(SUM(ref_get), 0) AS earned')
				->first();
			$out['buyers'] = (int) ($mine ? $mine->buyers : 0);
			$out['earned'] = (float) ($mine ? $mine->earned : 0);

			if ($perBuy === null) {
				$avg = DB::connection('default')->table('affiliate')
					->where('datetime', '>', time() - 90 * 86400)
					->selectRaw('AVG(ref_get) AS per_buy, AVG(paid_amount) AS paid')
					->first();
				$perBuy = (float) ($avg ? $avg->per_buy : 0);
				if ($perBuy <= 0 && $avg && $avg->paid > 0) {
					$rate = (float) (new \App\Provider\ConfigProvider)->get('commission');
					$perBuy = $avg->paid * $rate / 100;
				}
			}
			$out['per_buy'] = $perBuy;

			$out['idle'] = max(0, $out['invited'] - $out['buyers']);
			$out['ask'] = min(5, $out['idle']);
			$out['potential'] = $out['ask'] * $perBuy;
		} catch (\Throwable $e) {
		}

		return $out;
	}

	/*
	 * Telegram gifts (bot link, channel) this account has not been shown yet,
	 * for the congratulation popup on the dashboard. Reading them marks them
	 * seen - except for an admin previewing someone's portal, same as
	 * newCommissions(). Each row: source (bind|channel), kind (gb|free), gb, days.
	 */
	public function newGifts()
	{
		$out = [];

		try {
			$preview = !empty($_SESSION['adminview']);

			foreach (['bind' => 'tgbind_log', 'channel' => 'tgjoin_log'] as $source => $table) {
				$rows = DB::table($table)->where('userid', $this->id)->where('seen', 0)
					->whereIn('kind', ['gb', 'free'])->get();

				foreach ($rows as $row) {
					$out[] = [
						'source' => $source,
						'kind'   => $row->kind,
						'gb'     => (float) $row->gb,
						'mb'     => (int) round((float) $row->gb * 1024),
						'days'   => isset($row->days) ? (int) $row->days : 0,
					];
				}

				if (count($rows) > 0 && !$preview) {
					DB::table($table)->where('userid', $this->id)->where('seen', 0)->update(['seen' => 1]);
				}
			}
		} catch (\Throwable $e) {
			// the tables or the seen column do not exist before TgJoinJob's first run
		}

		// a prize won with a promoted plan (PromoJob)
		try {
			$rows = DB::table('promo_log')
				->leftJoin('package', 'package.id', '=', 'promo_log.packageid')
				->where('promo_log.userid', $this->id)->where('promo_log.seen', 0)
				->where('promo_log.applied', 1)->whereIn('promo_log.prize_kind', ['gb', 'days'])
				->select('promo_log.id', 'promo_log.prize_kind', 'promo_log.prize_amount', 'package.name')
				->get();

			foreach ($rows as $row) {
				$out[] = [
					'source' => 'promo',
					'kind'   => $row->prize_kind,
					'gb'     => $row->prize_kind === 'gb' ? (float) $row->prize_amount : 0,
					'mb'     => $row->prize_kind === 'gb' ? (int) $row->prize_amount * 1024 : 0,
					'days'   => $row->prize_kind === 'days' ? (int) $row->prize_amount : 0,
					'plan'   => (string) $row->name,
				];
			}

			if (count($rows) > 0 && empty($_SESSION['adminview'])) {
				DB::table('promo_log')->whereIn('id', $rows->pluck('id')->all())->update(['seen' => 1]);
			}
		} catch (\Throwable $e) {
			// promo_log or its seen column is created by PromoJob's first run
		}

		return $out;
	}

	/*
	 * ------------------------------------------------------------------
	 * Prizes won with a promoted plan (PromoJob, promo_log)
	 * ------------------------------------------------------------------
	 * The prizes that belong to the running subscription: those drawn for
	 * orders paid since the last subscription purchase. A renewal starts a new
	 * plan, and the prize of the old one is gone with its traffic.
	 */
	private $promoPrizeCache = null;

	public function promoPrize()
	{
		if ($this->promoPrizeCache !== null) {
			return $this->promoPrizeCache;
		}

		$prize = ['gb' => 0, 'days' => 0];

		try {
			if ($this->planIsActive()) {
				$since = (int) DB::table('orders')->where('userid', $this->id)->where('status', 1)
					->where('packagetype', 2)->max('pay_date');

				$rows = DB::table('promo_log')
					->join('orders', 'orders.id', '=', 'promo_log.orderid')
					->where('promo_log.userid', $this->id)
					->where('promo_log.applied', 1)
					->where('orders.pay_date', '>=', $since)
					->selectRaw('promo_log.prize_kind AS kind, SUM(promo_log.prize_amount) AS amount')
					->groupBy('promo_log.prize_kind')
					->get();

				foreach ($rows as $row) {
					if ($row->kind === 'gb' || $row->kind === 'days') {
						$prize[$row->kind] = (int) $row->amount;
					}
				}
			}
		} catch (\Throwable $e) {
			// promo_log is created by PromoJob's first run
		}

		return $this->promoPrizeCache = $prize;
	}

	/* prize traffic still unused: usage eats the prize first, then the plan's own */
	public function promoPrizeLeftBytes()
	{
		$prize = (float) $this->promoPrize()['gb'] * 1073741824;

		return max(0, $prize - ((float) $this->u + (float) $this->d));
	}

	public function promoPrizeLeft()
	{
		return (new Helpers)->trafficConvert($this->promoPrizeLeftBytes());
	}

	/* the plan's own traffic still unused, the prize not counted */
	public function promoPlanLeft()
	{
		$prize = (float) $this->promoPrize()['gb'] * 1073741824;
		$used = (float) $this->u + (float) $this->d;

		return (new Helpers)->trafficConvert(max(0, (float) $this->transfer_enable - max($used, $prize)));
	}

	public function promoPrizeLeftPercent()
	{
		if ((float) $this->transfer_enable <= 0) {
			return 0;
		}

		return round($this->promoPrizeLeftBytes() / (float) $this->transfer_enable * 100, 1);
	}

	/*
	 * A prize is on its way: a paid order on a plan whose running promotion has
	 * a prize, in the last half hour, not drawn yet. The dashboard shows a
	 * "being drawn" note and keeps asking until it lands.
	 */
	public function promoPrizePending()
	{
		try {
			$ids = [];
			foreach (Package::promoMap() as $id => $entry) {
				if (is_array($entry) && !empty($entry['prize']['on'])) {
					$ids[] = (int) $id;
				}
			}

			if ($ids === []) {
				return false;
			}

			return DB::table('orders')
				->leftJoin('promo_log', 'promo_log.orderid', '=', 'orders.id')
				->where('orders.userid', $this->id)
				->where('orders.status', 1)
				->whereIn('orders.packageid', $ids)
				->where('orders.pay_date', '>=', time() - 1800)
				->whereNull('promo_log.id')
				->exists();
		} catch (\Throwable $e) {
			return false;
		}
	}

	/*
	 * Traffic left on the plan in GB, one decimal, for the gift popup.
	 */
	public function giftTrafficLeftMb()
	{
		return (int) round(max(0, (float) $this->transfer_enable - (float) $this->u - (float) $this->d) / 1048576);
	}

	public function giftTrafficLeft()
	{
		$left = max(0, ((float) $this->transfer_enable - (float) $this->u - (float) $this->d) / 1073741824);
		return rtrim(rtrim(number_format($left, 1, '.', ''), '0'), '.');
	}

	/*
	 * Whether linking the bot would earn this account the one-time gift (see
	 * TgJoinJob::bindGifts): switched on, not linked yet, never gifted or
	 * marked existing, a running plan and at least one paid order.
	 */
	public function tgBindGiftOpen()
	{
		try {
			if ((int) $this->telegram_id > 0 || !$this->planIsActive()
				|| Settings::where('name', 'tgbind_gift')->value('value') != 1) {
				return false;
			}

			return !DB::table('tgbind_log')->where('userid', $this->id)->exists()
				&& DB::table('orders')->where('userid', $this->id)->where('status', 1)->exists();
		} catch (\Throwable $e) {
			return false;
		}
	}

	/*
	 * The Telegram channel gift as the dashboard shows it (see TgJoinJob).
	 * state: off | done (gifted, or closed as an existing member) | link (no
	 * Telegram linked) | join. `free` says which gift is on offer: a free plan
	 * when there is no running subscription, otherwise gigabytes.
	 */
	public function tgJoin()
	{
		$off = ['state' => 'off'];

		try {
			$rows = Settings::whereIn('name', ['tgjoin_channel_id', 'tgjoin_link'])
				->pluck('value', 'name');

			if (trim((string) ($rows['tgjoin_channel_id'] ?? '')) === '' || trim((string) ($rows['tgjoin_link'] ?? '')) === '') {
				return $off;
			}

			$done = DB::table('tgjoin_log')->where('userid', $this->id)
				->orWhere(function ($q) {
					$q->where('telegram_id', '>', 0)->where('telegram_id', (int) $this->telegram_id);
				})->exists();

			if ($done) {
				$state = 'done';
			} elseif ((int) $this->telegram_id <= 0) {
				$state = 'link';
			} else {
				$state = 'join';
			}

			return [
				'state' => $state,
				'link'  => trim($rows['tgjoin_link']),
				'free'  => !$this->planIsActive(),
			];
		} catch (\Throwable $e) {
			// tgjoin_log does not exist until the job's first run
			return $off;
		}
	}

	/*
	 * The payout controller enforces `payoutlimit` server side, so the figure the
	 * page shows has to be that one - a second, display-only minimum would just
	 * disagree with the error the visitor gets back.
	 */
	public function minWithdrawal()
	{
		$config = new \App\Provider\ConfigProvider;

		$limit = (float) $config->get('payoutlimit');
		if ($limit > 0) {
			return $limit;
		}

		return (float) $config->get('min_withdrawal');
	}

	/*
	 * Cash withdrawal is only offered once the withdrawable balance clears the
	 * configured floor - anything below that just makes work for support.
	 */
	public function canWithdraw()
	{
		if ((float) $this->payout_balance <= 0) {
			return false;
		}

		return $this->withdrawBlockReason() === '';
	}

	public function withdrawalShortfall()
	{
		$missing = $this->minWithdrawal() - (float) $this->payout_balance;
		return $missing > 0 ? $missing : 0;
	}

	/* ------------------------------------------------------------------
	 * Cash withdrawal eligibility.
	 *
	 * Commission always lands in the wallet and can always be spent inside the
	 * panel. Paying it out as cash is the restricted path: the account has to be
	 * a current customer, not somebody who bought once two years ago and came
	 * back only to collect.
	 * ------------------------------------------------------------------ */

	public function withdrawMaxGapDays()
	{
		$days = (int) (new \App\Provider\ConfigProvider)->get('withdraw_max_gap_days');
		return $days > 0 ? $days : 90;
	}

	/*
	 * Days the account sat without a subscription between the current one and the
	 * one before it. null when there is no earlier subscription to compare with.
	 */
	public function subscriptionGapDays()
	{
		$orders = Order::where('userid', $this->id)
			->where('status', 1)
			->where('packagetype', 2)
			->orderBy('pay_date', 'desc')
			->limit(2)
			->get();

		if (count($orders) < 2) {
			return null;
		}

		$gap = (int) $orders[0]->pay_date - (int) $orders[1]->expire;

		return $gap > 0 ? (int) floor($gap / 86400) : 0;
	}

	public function hasContinuousSubscription()
	{
		$gap = $this->subscriptionGapDays();

		if ($gap === null) {
			return true;
		}

		return $gap <= $this->withdrawMaxGapDays();
	}

	/*
	 * Empty string when the visitor may withdraw, otherwise the rule that blocks
	 * them - the template turns it into a message.
	 */
	public function withdrawBlockReason()
	{
		if (!$this->planIsActive()) {
			return 'inactive';
		}

		if (!$this->hasContinuousSubscription()) {
			return 'gap';
		}

		if ((float) $this->payout_balance < $this->minWithdrawal()) {
			return 'amount';
		}

		return '';
	}

    public function isAbleToCheckin()
    {
		if($this->last_check_in == null || $this->last_check_in == ""){
			return true;
		}elseif(date('Ymd') !== date('Ymd', $this->last_check_in) && (new Order)->getSubsciption($this->id)){
			return true;
		}
        return false;
    }	

    public function TGCheckin()
    { 
		$return = [];
		$translate =  new \App\Library\Localization\Localization;
		
		if($this->expire_in < date('Y-m-d H:i:s', time())){
			$return['msg'] = $translate->get('NoActivePlan');
			$return['ret'] = 0;
			$return['ok'] = false;
		}elseif(date('Ymd') === date('Ymd', $this->last_check_in)){
			$return['msg'] = $translate->get('CheckedIn');
			$return['ret'] = 0;
			$return['ok'] = false;
		}elseif(!in_array($this->server_group, explode(',', (new \App\Provider\ConfigProvider)->get('CheckInGroup')))){
			$return['msg'] = $translate->get('CheckedNotAllowed');
			$return['ret'] = 0;
			$return['ok'] = false;
		}else{
			switch((new \App\Provider\ConfigProvider)->get('checkinType')){
				case 1:
					$data = random_int((int) (new \App\Provider\ConfigProvider)->get('checkinDataMin'), (int) (new \App\Provider\ConfigProvider)->get('checkinDataMax'));
					$this->transfer_enable += (new Helpers)->toMB($data);
					$return['msg'] =  str_replace(['%data%'], [$data], $translate->get('CheckInDataSuccess'));
					break;
				case 2: 
					$days = mt_rand((int) (new \App\Provider\ConfigProvider)->get('checkinDaysMin'), (int) (new \App\Provider\ConfigProvider)->get('checkinDaysMax'))/10;
					$time = strtotime($this->expire_in) + (86400 * $days);
					$this->expire_in = date('Y-m-d H:i:s', $time);
					$return['msg'] =  str_replace(['%days%'], [$days], $translate->get('CheckInDaySuccess'));
					break;
				case 3:
					$data = random_int ((int) (new \App\Provider\ConfigProvider)->get('checkinDataMin'), (int) (new \App\Provider\ConfigProvider)->get('checkinDataMax'));
					$days = mt_rand((int) (new \App\Provider\ConfigProvider)->get('checkinDaysMin'), (int) (new \App\Provider\ConfigProvider)->get('checkinDaysMax'))/10;
					$this->transfer_enable += (new Helpers)->toMB($data);
					$time = strtotime($this->expire_in) + (86400 * $days);
					$this->expire_in = date('Y-m-d H:i:s', $time);
					$return['msg'] = str_replace(['%days%','%data%' ], [$days, $data], $translate->get('CheckInSuccess'));
					break;
			}
			
			$this->last_check_in = time();
			$this->save();
			
			$return['ret'] = 1;
			$return['ok'] = true;
		}
        return $return;
    }	
}
