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
		$group = (int) $user->server_group;
		$list = [];

		foreach (self::timeRows()->where('status', 1)->orderBy('sort', 'asc')->orderBy('id', 'asc')->get() as $row) {
			$meta = $row->timeMeta();

			if ($meta === null || ($meta['mode'] ?? '') === 'minted') {
				continue;
			}

			// plan and server group are separate filters, each open when empty
			$applies = isset($meta['applies_to']) && is_array($meta['applies_to'])
				? array_map('intval', $meta['applies_to'])
				: [];

			if ($applies !== [] && !in_array($current, $applies, true)) {
				continue;
			}

			$groups = isset($meta['groups']) && is_array($meta['groups'])
				? array_map('intval', $meta['groups'])
				: [];

			if ($groups !== [] && !in_array($group, $groups, true)) {
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

	/*
	 * ------------------------------------------------------------------
	 * Which subscription plans a traffic top-up is offered on
	 * ------------------------------------------------------------------
	 * Time plans keep this in their own marker, but a traffic package is saved
	 * through the encoded /admin/plan/save, which rewrites order_note on every
	 * save and would wipe it. So the scope lives in one settings row instead:
	 *
	 *   timeplan_topup_scope = {"7":[18,19],"8":[]}
	 *
	 * package id -> the subscription packages it is offered on. Missing or
	 * empty means every plan, which is what every existing top-up has.
	 */
	const TOPUP_SCOPE_SETTING = 'timeplan_topup_scope';
	const TOPUP_GROUP_SETTING = 'timeplan_topup_groups';

	private static function scopeMap($name)
	{
		static $maps = [];

		if (!array_key_exists($name, $maps)) {
			$raw = Settings::where('name', $name)->value('value');
			$decoded = json_decode((string) $raw, true);
			$maps[$name] = is_array($decoded) ? $decoded : [];
		}

		return $maps[$name];
	}

	public static function topupScopes()
	{
		return self::scopeMap(self::TOPUP_SCOPE_SETTING);
	}

	public static function topupGroups()
	{
		return self::scopeMap(self::TOPUP_GROUP_SETTING);
	}

	/* an empty or missing list means no restriction on that dimension */
	private static function scopePasses(array $map, $packageId, $value)
	{
		$key = (string) (int) $packageId;

		if (!isset($map[$key]) || !is_array($map[$key]) || $map[$key] === []) {
			return true;
		}

		return $value !== null
			&& in_array((int) $value, array_map('intval', $map[$key]), true);
	}

	public function topupAllowed($packageId, $user = null)
	{
		$plan = $user && isset($user->packageid) ? $user->packageid : null;
		$group = $user && isset($user->server_group) ? $user->server_group : null;

		return self::scopePasses(self::topupScopes(), $packageId, $plan)
			&& self::scopePasses(self::topupGroups(), $packageId, $group);
	}

	/*
	 * The signed-in customer, or null. Staff are deliberately not treated as
	 * customers here: the admin pages list top-ups too, and must keep seeing
	 * all of them.
	 */
	private static function scopeViewer()
	{
		try {
			$user = \App\Services\AuthService::getUser();
		} catch (\Throwable $error) {
			return null;
		}

		if (!$user || !isset($user->id) || (int) $user->role !== 0) {
			return null;
		}

		return $user;
	}

	/*
	 * ------------------------------------------------------------------
	 * Promotions on subscription plans
	 * ------------------------------------------------------------------
	 * A subscription plan's order_note is shown to customers, so a promotion
	 * cannot ride in it the way a time plan does. It lives in one settings row
	 * instead, keyed by package id:
	 *
	 *   promo_plans = {"12":{"kind":"discount","percent":20,
	 *                        "original":{"month":{"price":"1500000"},...},
	 *                        "prize":{"on":1,"mode":"either","gb_min":1,...},
	 *                        "occasion":"...","ends_at":1790000000,
	 *                        "max_sales":10,"show_left":1,
	 *                        "started_at":1789000000,"closed_at":0,...}}
	 *
	 * A discount is real: the discounted prices are written into price_option,
	 * which is what the encoded checkout charges, and `original` keeps the list
	 * price until bin/promos.php (PromoJob) puts it back. Written by
	 * app/Patch/Promo.php.
	 */
	const PROMO_SETTING = 'promo_plans';

	/** the billing cycles a promotion can discount, in the order they are shown */
	const PROMO_CYCLES = ['onetime', 'month', 'quater', 'semiannual', 'annual', 'custom'];

	public static function promoMap()
	{
		static $map = null;

		if ($map === null) {
			$decoded = json_decode((string) Settings::where('name', self::PROMO_SETTING)->value('value'), true);
			$map = is_array($decoded) ? $decoded : [];
		}

		return $map;
	}

	/* paid orders on a package inside a promotion's window */
	public static function promoSold($packageId, $since, $until = 0)
	{
		static $counts = [];

		$key = $packageId . ':' . $since . ':' . $until;

		if (!array_key_exists($key, $counts)) {
			$query = Order::where('packageid', (int) $packageId)
				->where('status', 1)
				->where('pay_date', '>=', (int) $since);

			if ($until > 0) {
				$query->where('pay_date', '<=', (int) $until);
			}

			$counts[$key] = $query->count();
		}

		return $counts[$key];
	}

	/*
	 * Whether an entry is running right now. The cron closes a finished one
	 * within a minute; until then the pages must already stop showing it.
	 */
	public static function promoRunning($entry, $now = null)
	{
		$now = $now ?: time();

		if (!is_array($entry) || !empty($entry['closed_at'])) {
			return false;
		}

		$kind = $entry['kind'] ?? 'none';
		$prize = !empty($entry['prize']['on']);

		if ($kind === 'none' && !$prize) {
			return false;
		}

		if (!empty($entry['ends_at']) && (int) $entry['ends_at'] <= $now) {
			return false;
		}

		$max = (int) ($entry['max_sales'] ?? 0);

		if ($max > 0 && self::promoSold($entry['packageid'] ?? 0, (int) ($entry['started_at'] ?? 0)) >= $max) {
			return false;
		}

		return true;
	}

	/*
	 * What the plan pages need to draw a running promotion, or null. `original`
	 * is the list price per cycle, only present for a discount.
	 */
	public function promo($packageId)
	{
		$map = self::promoMap();
		$key = (string) (int) $packageId;

		if (!isset($map[$key]) || !is_array($map[$key])) {
			return null;
		}

		$entry = $map[$key] + ['packageid' => (int) $packageId];

		if (!self::promoRunning($entry)) {
			return null;
		}

		$kind = in_array($entry['kind'] ?? 'none', ['discount', 'special'], true) ? $entry['kind'] : 'none';
		$max = (int) ($entry['max_sales'] ?? 0);

		$view = [
			'kind'     => $kind,
			'percent'  => $kind === 'discount' ? (int) ($entry['percent'] ?? 0) : 0,
			'original' => [],
			'prize'    => !empty($entry['prize']['on']) ? $this->promoPrizeRange($entry['prize']) : '',
			'occasion' => trim((string) ($entry['occasion'] ?? '')),
			'ends_at'  => (int) ($entry['ends_at'] ?? 0),
			'left'     => null,
			'now'      => time(),
		];

		if ($kind === 'discount' && isset($entry['original']) && is_array($entry['original'])) {
			foreach ($entry['original'] as $cycle => $value) {
				if (is_array($value) && isset($value['price']) && $value['price'] !== '') {
					$view['original'][$cycle] = (float) $value['price'];
				}
			}
		}

		if ($max > 0 && !empty($entry['show_left'])) {
			$view['left'] = max(0, $max - self::promoSold($packageId, (int) ($entry['started_at'] ?? 0)));
		}

		return $view;
	}

	/*
	 * The whole entry for the admin form, running or not, with its sales so
	 * far. The form shows list prices, so it reads `original` from here.
	 */
	public function promoAdmin($packageId)
	{
		$map = self::promoMap();
		$key = (string) (int) $packageId;

		if (!isset($map[$key]) || !is_array($map[$key])) {
			return null;
		}

		$entry = $map[$key] + ['packageid' => (int) $packageId];
		$entry['running'] = self::promoRunning($entry);
		$entry['sold'] = self::promoSold($packageId, (int) ($entry['started_at'] ?? 0), (int) ($entry['closed_at'] ?? 0));

		return $entry;
	}

	/* "1 to 5 GB or 3 to 7 days", in the viewer's language */
	private function promoPrizeRange(array $prize)
	{
		$t = new \App\Library\Localization\Localization;
		$gb = str_replace(['%min%', '%max%'], [(int) ($prize['gb_min'] ?? 0), (int) ($prize['gb_max'] ?? 0)], $t->get('PromoPrizeGbRange'));
		$days = str_replace(['%min%', '%max%'], [(int) ($prize['days_min'] ?? 0), (int) ($prize['days_max'] ?? 0)], $t->get('PromoPrizeDaysRange'));

		switch ($prize['mode'] ?? 'either') {
			case 'gb':
				return $gb;
			case 'days':
				return $days;
			default:
				return $gb . ' ' . $t->get('PromoOr') . ' ' . $days;
		}
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

	/*
	 * Time plans ride on type 1, so they are kept out of the data top-up list,
	 * and a top-up limited to certain plans is hidden from everyone else.
	 */
	public function topupList()
    {
		$list = self::where('status', 1)->where('type', 1)
			->where(function ($query) {
				$query->whereNull('order_note')
					->orWhere('order_note', 'not like', '%' . self::TIME_MARKER . '%');
			})
			->orderBy('sort',"asc")->get();

		$viewer = self::scopeViewer();

		if ($viewer === null) {
			return $list;
		}

		return $list->filter(function ($row) use ($viewer) {
			return $this->topupAllowed($row->id, $viewer);
		})->values();
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
