<?php

namespace App\Http\Models;

final class Package extends Model
{
    protected $connection = 'default';
    protected $table = 'package';
	protected $guarded = ['id'];

	/*
	 * ------------------------------------------------------------------
	 * Time plans
	 * ------------------------------------------------------------------
	 * A time plan sells days, not gigabytes. The panel's order pipeline is
	 * ionCube encoded and only knows two package types, so a time plan is
	 * stored as a real topup package (type 1, bandwidth 0) carrying a marker
	 * in `order_note`, which nothing renders for type 1:
	 *
	 *   {"timeplan":{"v":1,"mode":"fixed","days":7,"applies_to":[2,3]}}
	 *   {"timeplan":{"v":1,"mode":"perday","price_per_day":150000,
	 *                "min_days":1,"max_days":60,"applies_to":[]}}
	 *   {"timeplan":{"v":1,"mode":"minted","days":12,"parent":41,"applies_to":[]}}
	 *
	 * Checkout is therefore the panel's own topup flow; the days are granted
	 * afterwards by bin/timeplans.php. A `minted` row is one the user's day
	 * count produced for a per-day plan - buyable, but never listed.
	 */

	const TIME_MARKER = '"timeplan"';

	public function timeMeta()
	{
		return self::decodeTimeMeta($this->order_note);
	}

	public static function decodeTimeMeta($note)
	{
		if (!is_string($note) || strpos($note, self::TIME_MARKER) === false) {
			return null;
		}

		$data = json_decode($note, true);

		if (!is_array($data) || !isset($data['timeplan']) || !is_array($data['timeplan'])) {
			return null;
		}

		return $data['timeplan'];
	}

	public function isTimePlan()
	{
		return $this->timeMeta() !== null;
	}

	/* every row carrying the marker, minted ones included */
	public static function timeRows()
	{
		return self::where('type', 1)->where('order_note', 'like', '%' . self::TIME_MARKER . '%');
	}

	/*
	 * The time plans a given user may buy: enabled, not minted, and either
	 * open to every plan (`applies_to` empty) or naming the package the user
	 * is currently subscribed to.
	 */
	public static function timePlansFor($user)
	{
		if (!$user || !isset($user->id)) {
			return [];
		}

		$current = (int) $user->packageid;
		$list = [];

		foreach (self::timeRows()->where('status', 1)->orderBy('sort', 'asc')->orderBy('id', 'asc')->get() as $row) {
			$meta = $row->timeMeta();

			if ($meta === null || ($meta['mode'] ?? '') === 'minted') {
				continue;
			}

			$applies = isset($meta['applies_to']) && is_array($meta['applies_to'])
				? array_map('intval', $meta['applies_to'])
				: [];

			if ($applies !== [] && !in_array($current, $applies, true)) {
				continue;
			}

			$list[] = $row;
		}

		return $list;
	}

	public function timePlanCount($user)
	{
		return count(self::timePlansFor($user));
	}

	/* price of this plan for a number of days, as a float */
	public function timePrice($days = null)
	{
		$meta = $this->timeMeta();

		if ($meta === null) {
			return 0.0;
		}

		if (($meta['mode'] ?? '') === 'perday') {
			$days = (int) ($days === null ? ($meta['min_days'] ?? 1) : $days);
			return (float) ($meta['price_per_day'] ?? 0) * $days;
		}

		$options = json_decode((string) $this->price_option, true);

		return (float) ($options['topup']['price'] ?? 0);
	}

	public function period_sales($id)
    {
        $period = 360 * 24 * 60 * 60;
        $sales = Order::where('packageid', $id)->where('pay_date', '>', time() - $period)->where('state', 1)->count();
		return $sales;
	}

	public function upgradeList($sameGroup, $user)
    {
		if($sameGroup == 1){
			return self::where('status', 1)->where('type', 2)->where('upgrade', 1)
				->where('server_group', $this->user->server_group)->orderBy('sort',"asc")->get();
		}else{
			return self::where('status', 1)->where('type', 2)->where('upgrade', 1)
				->orderBy('sort',"asc")->get();
		}
	}

	/* time plans ride on type 1, so they are kept out of the data top-up list */
	public function topupList()
    {
		return self::where('status', 1)->where('type', 1)
			->where(function ($query) {
				$query->whereNull('order_note')
					->orWhere('order_note', 'not like', '%' . self::TIME_MARKER . '%');
			})
			->orderBy('sort',"asc")->get();
	}

	public function topupCount()
    {
		return $this->topupList()->count();
	}

	public function AllowReset()
    {
        if($this->reset_days > 0 && $this->bandwidth > 0){
			return true;
		}
		return false;
    }
}
