{$rtl = explode(',',$Config['rtlanguages'])}
<script>
var dxConf = {
	locale: '{$session->get('locale')}',
	rtl: {if in_array($session->get('locale'), $rtl)}true{else}false{/if},
	currencyLeft: '{$currency->symbol_left}',
	currencyRight: '{$currency->symbol_right}',
	decimals: {(int)$currency->decimals}
};
var dxText = {
	updated: '{$translate->get('DashUpdated')}',
	loadError: '{$translate->get('DashLoadError')}',
	empty: '{$translate->get('DashEmpty')}',
	orders: '{$translate->get('DashOrders')}',
	total: '{$translate->get('DashTotal')}',
	subscription: '{$translate->get('DashSubscription')}',
	topup: '{$translate->get('DashTopup')}',
	time: '{$translate->get('DashTime')}',
	new: '{$translate->get('DashNew')}',
	renew: '{$translate->get('DashRenew')}',
	upgrade: '{$translate->get('DashUpgrade')}',
	balance: '{$translate->get('DashBalance')}',
	free: '{$translate->get('DashFree')}',
	weekdays: '{$translate->get('DashWeekdays')}',
	segActive: '{$translate->get('DashSegActive')}',
	segSoon: '{$translate->get('DashSegSoon')}',
	segExhausted: '{$translate->get('DashSegExhausted')}',
	segExpired: '{$translate->get('DashSegExpired')}',
	segDisabled: '{$translate->get('DashSegDisabled')}',
	users: '{$translate->get('DashUsers')}',
	expiring: '{$translate->get('DashExpiring')}',
	registrations: '{$translate->get('DashRegistrations')}',
	traffic: '{$translate->get('DashTraffic')}',
	node: '{$translate->get('DashNode')}',
	load: '{$translate->get('DashLoad')}',
	online: '{$translate->get('DashOnline')}',
	today: '{$translate->get('DashToday')}',
	up: '{$translate->get('DashUp')}',
	down: '{$translate->get('DashDown')}',
	off: '{$translate->get('DashOff')}',
	user: '{$translate->get('DashUser')}',
	plan: '{$translate->get('DashPlan')}',
	amount: '{$translate->get('DashAmount')}',
	when: '{$translate->get('DashWhen')}',
	healthOk: '{$translate->get('DashHealthOk')}',
	healthWarn: '{$translate->get('DashHealthWarn')}',
	healthFail: '{$translate->get('DashHealthFail')}',
	healthSummary: '{$translate->get('DashHealthSummary')}',
	check: {
		db: '{$translate->get('DashCheckDb')}',
		nodes: '{$translate->get('DashCheckNodes')}',
		cron: '{$translate->get('DashCheckCron')}',
		traffic: '{$translate->get('DashCheckTraffic')}',
		payments: '{$translate->get('DashCheckPayments')}',
		disk: '{$translate->get('DashCheckDisk')}',
		load: '{$translate->get('DashCheckLoad')}',
		storage: '{$translate->get('DashCheckStorage')}',
		timeplan: '{$translate->get('DashCheckTimeplan')}',
		patch: '{$translate->get('DashCheckPatch')}'
	}
};
</script>
<script>
{literal}
(function () {
	var root = document.getElementById('dx');
	var data = null;
	var charts = {};
	var range = { revenue: 30, registrations: 30, traffic: 30 };
	var loc = dxConf.locale === 'fa_IR' ? 'fa-IR' : (dxConf.locale === 'zh_CN' ? 'zh-CN' : 'en-US');
	var jalali = loc === 'fa-IR';

	// ------------------------------------------------------------ formatting
	var nf = new Intl.NumberFormat(loc, { maximumFractionDigits: dxConf.decimals });
	var nf1 = new Intl.NumberFormat(loc, { maximumFractionDigits: 1 });
	var cf;
	try { cf = new Intl.NumberFormat(loc, { notation: 'compact', maximumFractionDigits: 1 }); } catch (e) { cf = nf1; }
	var dayFmt = new Intl.DateTimeFormat(jalali ? 'fa-IR-u-ca-persian' : loc, { month: 'short', day: 'numeric' });
	// axis ticks are numeric (6/31): a month name next to a digit gets
	// reordered by the bidi algorithm inside the left-to-right chart
	var tickFmt = new Intl.DateTimeFormat(jalali ? 'fa-IR-u-ca-persian' : loc, { month: 'numeric', day: 'numeric' });
	var dayLong = new Intl.DateTimeFormat(jalali ? 'fa-IR-u-ca-persian' : loc, { weekday: 'long', month: 'long', day: 'numeric' });
	var monthFmt = new Intl.DateTimeFormat(jalali ? 'fa-IR-u-ca-persian' : loc, { month: 'short', year: '2-digit' });
	var timeFmt = new Intl.DateTimeFormat(jalali ? 'fa-IR-u-ca-persian' : loc, { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' });
	var persianMonths = ['فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور', 'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند'];

	function num(v) { return nf.format(v || 0); }
	function compact(v) { return cf.format(v || 0); }
	function money(v) { return (dxConf.currencyLeft ? dxConf.currencyLeft + ' ' : '') + num(v) + (dxConf.currencyRight ? ' ' + dxConf.currencyRight : ''); }
	function moneyShort(v) { return compact(v) + (dxConf.currencyRight ? ' ' + dxConf.currencyRight : ''); }
	function gb(v) { return v >= 1024 ? nf1.format(v / 1024) + ' TB' : nf1.format(v) + ' GB'; }
	function day(d) { return dayFmt.format(new Date(d + 'T12:00:00')); }
	/* Category labels for a daily axis: every few days only, so they never
	   overlap. The tooltip reads the full date from the rows, not from here. */
	function ticks(rows, every) {
		var step = every || Math.max(1, Math.ceil(rows.length / 8));
		return rows.map(function (r, i) {
			return (rows.length - 1 - i) % step === 0 ? tickFmt.format(new Date(r.d + 'T12:00:00')) : '';
		});
	}
	function fullDay(rows) {
		return function (v, opt) { var r = opt && rows[opt.dataPointIndex]; return r ? dayLong.format(new Date(r.d + 'T12:00:00')) : v; };
	}
	function month(m, withYear) {
		if (jalali) {
			var p = m.split('-');
			return persianMonths[Number(p[1]) - 1] + (withYear ? ' ' + new Intl.NumberFormat('fa-IR', { useGrouping: false }).format(Number(p[0])) : '');
		}
		return monthFmt.format(new Date(m + '-15T12:00:00'));
	}
	function esc(s) { return String(s == null ? '' : s).replace(/[&<>"']/g, function (c) { return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]; }); }
	function delta(now, before) {
		if (!before) { return '<span class="dx-delta ' + (now ? 'up' : 'flat') + '">' + (now ? '▲' : '•') + '</span>'; }
		var p = (now - before) / before * 100;
		var cls = Math.abs(p) < 0.5 ? 'flat' : (p > 0 ? 'up' : 'down');
		var arrow = cls === 'up' ? '▲' : (cls === 'down' ? '▼' : '•');
		return '<span class="dx-delta ' + cls + '">' + arrow + ' ' + nf1.format(Math.abs(p)) + '%</span>';
	}
	function set(id, html) { var el = document.getElementById(id); if (el) { el.innerHTML = html; } }

	// ---------------------------------------------------------------- theme
	function dark() {
		try { return typeof HSThemeAppearance !== 'undefined' && HSThemeAppearance.getAppearance() === 'dark'; } catch (e) { return false; }
	}
	function css(name) { return getComputedStyle(root).getPropertyValue(name).trim(); }
	function palette() {
		root.classList.toggle('dx-dark', dark());
		return {
			s: [css('--dx-s1'), css('--dx-s2'), css('--dx-s3'), css('--dx-s4'), css('--dx-s5')],
			ok: css('--dx-ok'), warn: css('--dx-warn'), fail: css('--dx-fail'),
			muted: css('--dx-muted'), line: css('--dx-line'),
			surface: getComputedStyle(root.querySelector('.card') || document.body).backgroundColor
		};
	}
	function base(type, height, pal) {
		return {
			chart: {
				type: type, height: height, fontFamily: 'inherit', toolbar: { show: false }, zoom: { enabled: false },
				background: 'transparent', foreColor: pal.muted,
				animations: { enabled: true, easing: 'easeout', speed: 500, animateGradually: { enabled: false } }
			},
			theme: { mode: dark() ? 'dark' : 'light' },
			grid: { borderColor: pal.line, strokeDashArray: 4, padding: { left: 6, right: 6 } },
			dataLabels: { enabled: false },
			legend: { show: false },
			tooltip: { theme: dark() ? 'dark' : 'light' }
		};
	}
	function draw(key, el, options) {
		if (charts[key]) { charts[key].destroy(); }
		var node = document.getElementById(el);
		if (!node) { return; }
		node.innerHTML = '';
		charts[key] = new ApexCharts(node, options);
		charts[key].render();
	}
	function legend(id, items) {
		set(id, items.map(function (i) {
			return '<span><i style="background:' + i.color + '"></i>' + esc(i.label) + (i.value != null ? '<b>' + i.value + '</b>' : '') + '</span>';
		}).join(''));
	}
	function spark(key, el, values, labels, color, fmt, type) {
		var pal = palette();
		var o = base(type || 'area', 54, pal);
		o.chart.sparkline = { enabled: true };
		o.series = [{ name: '', data: values }];
		o.labels = labels;
		o.colors = [color];
		o.stroke = { curve: 'smooth', width: 2 };
		if (type === 'bar') {
			// sign-ups are a handful a day: bars read better than a spiky line
			o.stroke = { width: 0 };
			o.plotOptions = { bar: { columnWidth: '55%', borderRadius: 2 } };
		} else {
			o.fill = { type: 'gradient', gradient: { shadeIntensity: 1, opacityFrom: .35, opacityTo: 0, stops: [0, 100] } };
		}
		o.tooltip = { theme: o.tooltip.theme, x: { show: true }, y: { title: { formatter: function () { return ''; } }, formatter: fmt }, marker: { show: false } };
		o.xaxis = { categories: labels };
		draw(key, el, o);
	}
	function rank(id, rows, colorOf, valueOf, noteOf) {
		if (!rows.length) { set(id, '<div class="dx-empty">' + dxText.empty + '</div>'); return; }
		var top = Math.max.apply(null, rows.map(valueOf)) || 1;
		set(id, rows.map(function (r, i) {
			return '<div class="dx-rank-row"><span class="dx-rank-name">' + esc(r.label) + '</span><span class="dx-rank-val">' + noteOf(r) + '</span>' +
				'<div class="dx-rank-bar"><i style="width:' + (valueOf(r) / top * 100).toFixed(1) + '%;background:' + colorOf(r, i) + '"></i></div></div>';
		}).join(''));
	}

	// ------------------------------------------------------------- sections
	function kpis() {
		var k = data.sales.kpi, u = data.users, pal = palette();
		var d30 = data.sales.daily.slice(-30), d14 = data.sales.daily.slice(-14);
		set('kRevToday', money(k.revenue_today));
		set('kRevTodayDelta', delta(k.revenue_today, k.revenue_yesterday));
		set('kRev30', money(k.revenue_30));
		set('kRev30Delta', delta(k.revenue_30, k.revenue_prev30));
		set('kOrders30', num(k.orders_30));
		set('kOrders30Delta', delta(k.orders_30, k.orders_prev30));
		set('kConversion', nf1.format(k.conversion_30) + '%');
		set('kActive', num(u.active + u.soon + u.exhausted) + ' <small>/ ' + num(u.total) + '</small>');
		set('kOnline', num(u.online));
		set('kAov', money(k.aov_30));
		set('kAovDelta', delta(k.aov_30, k.aov_prev30));
		set('kBuyers', num(k.buyers_30));
		set('kNewUsers', num(u.new_30));
		set('kNewUsersDelta', delta(u.new_30, u.new_prev30));
		set('kWallet', moneyShort(u.balance));
		set('kLapsed', num(u.lapsed_7));

		var total = function (r) { return r.sub + r.topup + r.time; };
		spark('sRevToday', 'sRevToday', d14.map(total), d14.map(function (r) { return day(r.d); }), pal.s[0], money);
		spark('sRev30', 'sRev30', d30.map(total), d30.map(function (r) { return day(r.d); }), pal.s[2], money);
		spark('sOrders30', 'sOrders30', d30.map(function (r) { return r.orders; }), d30.map(function (r) { return day(r.d); }), pal.s[3], num);
		var reg = u.registered.slice(-30);
		spark('sUsers', 'sUsers', reg.map(function (r) { return r.n; }), reg.map(function (r) { return day(r.d); }), pal.s[4], num, 'bar');
	}

	function revenue() {
		var pal = palette(), rows = data.sales.daily.slice(-range.revenue);
		var series = [
			{ name: dxText.subscription, data: rows.map(function (r) { return Math.round(r.sub); }) },
			{ name: dxText.topup, data: rows.map(function (r) { return Math.round(r.topup); }) },
			{ name: dxText.time, data: rows.map(function (r) { return Math.round(r.time); }) }
		];
		var sums = series.map(function (s) { return s.data.reduce(function (a, b) { return a + b; }, 0); });
		legend('lRevenue', [
			{ label: dxText.subscription, color: pal.s[0], value: moneyShort(sums[0]) },
			{ label: dxText.topup, color: pal.s[1], value: moneyShort(sums[1]) },
			{ label: dxText.time, color: pal.s[2], value: moneyShort(sums[2]) }
		]);
		var o = base('bar', 300, pal);
		o.chart.stacked = true;
		o.series = series;
		o.colors = pal.s.slice(0, 3);
		o.plotOptions = { bar: { columnWidth: range.revenue > 30 ? '78%' : '58%', borderRadius: 3 } };
		o.stroke = { show: true, width: range.revenue > 30 ? 1 : 2, colors: [pal.surface] };
		o.xaxis = { categories: ticks(rows), labels: { rotate: 0 }, axisBorder: { show: false }, axisTicks: { show: false } };
		o.yaxis = { tickAmount: 4, labels: { formatter: compact } };
		o.tooltip.shared = true;
		o.tooltip.intersect = false;
		o.tooltip.x = { formatter: function (v, opt) { var r = rows[opt.dataPointIndex]; return r ? dayLong.format(new Date(r.d + 'T12:00:00')) + ' · ' + num(r.orders) + ' ' + dxText.orders : v; } };
		o.tooltip.y = { formatter: money };
		draw('revenue', 'cRevenue', o);
	}

	function monthly() {
		var pal = palette(), rows = data.sales.monthly;
		var o = base('area', 280, pal);
		o.series = [{ name: dxText.total, data: rows.map(function (r) { return Math.round(r.revenue); }) }];
		o.colors = [pal.s[0]];
		o.stroke = { curve: 'smooth', width: 2 };
		o.markers = { size: 4, strokeWidth: 2, strokeColors: pal.surface, hover: { size: 6 } };
		o.fill = { type: 'gradient', gradient: { shadeIntensity: 1, opacityFrom: .3, opacityTo: .02, stops: [0, 95] } };
		o.xaxis = { categories: rows.map(function (r) { return month(r.m); }), labels: { rotate: 0 }, axisBorder: { show: false }, axisTicks: { show: false }, tooltip: { enabled: false } };
		o.yaxis = { tickAmount: 4, labels: { formatter: compact } };
		o.tooltip.x = { formatter: function (v, opt) { var r = opt && rows[opt.dataPointIndex]; return r ? month(r.m, true) : v; } };
		o.tooltip.y = { formatter: function (v, opt) { var r = rows[opt.dataPointIndex]; return money(v) + (r ? ' · ' + num(r.orders) + ' ' + dxText.orders : ''); } };
		draw('monthly', 'cMonthly', o);
	}

	function mix() {
		var pal = palette(), m = data.sales.mix, mr = data.sales.mix_revenue;
		var keys = ['new', 'renew', 'upgrade', 'topup', 'time'].filter(function (k) { return m[k] > 0; });
		var colorOf = { new: pal.s[0], renew: pal.s[2], upgrade: pal.s[4], topup: pal.s[1], time: pal.s[3] };
		var o = base('donut', 230, pal);
		o.series = keys.map(function (k) { return m[k]; });
		o.labels = keys.map(function (k) { return dxText[k]; });
		o.colors = keys.map(function (k) { return colorOf[k]; });
		o.stroke = { width: 2, colors: [pal.surface] };
		o.plotOptions = { pie: { donut: { size: '72%', labels: { show: true, name: { fontSize: '12px' }, value: { fontSize: '20px', fontWeight: 700, formatter: function (v) { return num(Number(v)); } }, total: { show: true, label: dxText.orders, color: pal.muted, formatter: function (w) { return num(w.globals.seriesTotals.reduce(function (a, b) { return a + b; }, 0)); } } } } } };
		o.tooltip.y = { formatter: function (v, opt) { return num(v) + ' · ' + moneyShort(mr[keys[opt.seriesIndex]]); } };
		draw('mix', 'cMix', o);
		var total = keys.reduce(function (a, k) { return a + m[k]; }, 0) || 1;
		legend('lMix', keys.map(function (k) { return { label: dxText[k], color: colorOf[k], value: nf1.format(m[k] / total * 100) + '%' }; }));

		var gws = data.sales.gateways.map(function (g) {
			return { label: g.name === 'balance' ? dxText.balance : (g.name === 'free' ? dxText.free : g.name), revenue: g.revenue, orders: g.orders };
		});
		rank('rGateways', gws, function (r, i) { return pal.s[i % 5]; }, function (r) { return r.orders; },
			function (r) { return num(r.orders) + ' ' + dxText.orders + ' · ' + moneyShort(r.revenue); });
	}

	function plans() {
		var pal = palette();
		var rows = data.sales.plans.map(function (p) { return { label: p.kind === 'time' ? dxText.time : p.name, kind: p.kind, revenue: p.revenue, orders: p.orders }; });
		rank('rPlans', rows, function (r) { return r.kind === 'topup' ? pal.s[1] : (r.kind === 'time' ? pal.s[2] : pal.s[0]); },
			function (r) { return r.revenue; },
			function (r) { return moneyShort(r.revenue) + ' · ' + num(r.orders) + ' ' + dxText.orders; });
	}

	function heat() {
		var pal = palette(), names = dxText.weekdays.split(',');
		var max = 0;
		data.sales.heat.forEach(function (row) { row.forEach(function (v) { if (v > max) { max = v; } }); });
		// ApexCharts draws the first series at the bottom; reverse so Saturday is on top
		var series = data.sales.heat.map(function (row, i) {
			return { name: names[i] || String(i), data: row.map(function (v, h) { return { x: String(h), y: v }; }) };
		}).reverse();
		var step = Math.max(1, Math.ceil(max / 5));
		var o = base('heatmap', 280, pal);
		o.series = series;
		o.stroke = { width: 2, colors: [pal.surface] };
		o.plotOptions = { heatmap: { radius: 4, enableShades: false, colorScale: { ranges: [
			{ from: 0, to: 0, color: dark() ? '#2b2f36' : '#eef2f7' },
			{ from: 1, to: step, color: '#b7d3f6' },
			{ from: step + 1, to: step * 2, color: '#86b6ef' },
			{ from: step * 2 + 1, to: step * 3, color: '#5598e7' },
			{ from: step * 3 + 1, to: step * 4, color: '#2a78d6' },
			{ from: step * 4 + 1, to: Math.max(max, step * 5), color: '#1c5cab' }
		] } } };
		o.xaxis = { labels: { formatter: function (v) { return Number(v) % 3 === 0 ? num(Number(v)) : ''; } }, axisBorder: { show: false }, axisTicks: { show: false }, tooltip: { enabled: false } };
		o.tooltip.y = { formatter: function (v) { return num(v) + ' ' + dxText.orders; } };
		o.tooltip.x = { show: true, formatter: function (v, opt) { return ''; } };
		o.tooltip.custom = function (opt) {
			var s = opt.w.config.series[opt.seriesIndex], p = s.data[opt.dataPointIndex];
			return '<div class="px-3 py-2" style="font-size:.8rem"><b>' + esc(s.name) + ' · ' + num(Number(p.x)) + ':00</b><br>' + num(p.y) + ' ' + dxText.orders + '</div>';
		};
		draw('heat', 'cHeat', o);
	}

	function segments() {
		var pal = palette(), u = data.users;
		var parts = [
			{ label: dxText.segActive, v: u.active, c: pal.ok },
			{ label: dxText.segSoon, v: u.soon, c: pal.warn },
			{ label: dxText.segExhausted, v: u.exhausted, c: pal.s[1] },
			{ label: dxText.segExpired, v: u.expired, c: dark() ? '#4b5563' : '#cbd5e1' },
			{ label: dxText.segDisabled, v: u.disabled, c: pal.fail }
		].filter(function (p) { return p.v > 0; });
		var o = base('donut', 230, pal);
		o.series = parts.map(function (p) { return p.v; });
		o.labels = parts.map(function (p) { return p.label; });
		o.colors = parts.map(function (p) { return p.c; });
		o.stroke = { width: 2, colors: [pal.surface] };
		o.plotOptions = { pie: { donut: { size: '72%', labels: { show: true, name: { fontSize: '12px' }, value: { fontSize: '20px', fontWeight: 700, formatter: function (v) { return num(Number(v)); } }, total: { show: true, label: dxText.users, color: pal.muted, formatter: function () { return num(u.total); } } } } } };
		o.tooltip.y = { formatter: function (v) { return num(v) + ' · ' + nf1.format(v / (u.total || 1) * 100) + '%'; } };
		draw('segments', 'cSegments', o);
		legend('lSegments', parts.map(function (p) { return { label: p.label, color: p.c, value: num(p.v) }; }));
	}

	function pipeline() {
		var pal = palette(), rows = data.users.expiring;
		var o = base('bar', 260, pal);
		o.series = [{ name: dxText.expiring, data: rows.map(function (r) { return r.n; }) }];
		o.colors = [pal.s[3]];
		o.plotOptions = { bar: { columnWidth: '55%', borderRadius: 4, distributed: false } };
		o.xaxis = { categories: ticks(rows, 2), labels: { rotate: 0 }, axisBorder: { show: false }, axisTicks: { show: false } };
		o.tooltip.x = { formatter: fullDay(rows) };
		o.yaxis = { labels: { formatter: function (v) { return num(Math.round(v)); } }, forceNiceScale: true, min: 0 };
		o.dataLabels = { enabled: true, formatter: function (v) { return v ? num(v) : ''; }, offsetY: -18, style: { fontSize: '10px', colors: [pal.muted] } };
		o.plotOptions.bar.dataLabels = { position: 'top' };
		o.tooltip.y = { formatter: function (v) { return num(v) + ' ' + dxText.users; } };
		draw('pipeline', 'cPipeline', o);
	}

	function registrations() {
		var pal = palette(), rows = data.users.registered.slice(-range.registrations);
		var o = base('bar', 260, pal);
		o.series = [{ name: dxText.registrations, data: rows.map(function (r) { return r.n; }) }];
		o.colors = [pal.s[4]];
		o.plotOptions = { bar: { columnWidth: '60%', borderRadius: 3 } };
		o.xaxis = { categories: ticks(rows, Math.ceil(rows.length / 5)), labels: { rotate: 0 }, axisBorder: { show: false }, axisTicks: { show: false } };
		o.yaxis = { labels: { formatter: function (v) { return num(Math.round(v)); } }, forceNiceScale: true, min: 0 };
		o.tooltip.x = { formatter: fullDay(rows) };
		o.tooltip.y = { formatter: function (v) { return num(v) + ' ' + dxText.users; } };
		draw('registrations', 'cRegistrations', o);
	}

	function traffic() {
		var pal = palette(), rows = data.traffic.daily.slice(-range.traffic);
		// the daily roll-up only exists from the day it was installed; days
		// before that are missing, not zero, so they are left off the chart
		while (rows.length > 1 && !rows[0].gb) { rows = rows.slice(1); }
		var o = base('area', 290, pal);
		o.series = [{ name: dxText.traffic, data: rows.map(function (r) { return r.gb; }) }];
		o.colors = [pal.s[2]];
		o.stroke = { curve: 'smooth', width: 2 };
		o.fill = { type: 'gradient', gradient: { shadeIntensity: 1, opacityFrom: .35, opacityTo: .02, stops: [0, 95] } };
		o.xaxis = { categories: ticks(rows), labels: { rotate: 0 }, axisBorder: { show: false }, axisTicks: { show: false }, tooltip: { enabled: false } };
		o.yaxis = { tickAmount: 4, labels: { formatter: function (v) { return gb(v); } }, min: 0 };
		o.tooltip.x = { formatter: fullDay(rows) };
		o.tooltip.y = { formatter: gb };
		draw('traffic', 'cTraffic', o);

		var servers = data.traffic.servers, sum = servers.reduce(function (a, s) { return a + s.gb; }, 0) || 1;
		rank('rServers', servers.map(function (s) { return { label: s.name, gb: s.gb }; }),
			function (r, i) { return pal.s[i % 5]; }, function (r) { return r.gb; },
			function (r) { return gb(r.gb) + ' · ' + nf1.format(r.gb / sum * 100) + '%'; });
	}

	function nodes() {
		var pal = palette();
		var head = '<thead><tr><th>' + dxText.node + '</th><th>' + dxText.load + '</th><th class="dx-num">' + dxText.online + '</th><th class="dx-num">' + dxText.today + '</th></tr></thead>';
		var body = data.nodes.map(function (n) {
			var color = n.state === 'up' ? pal.ok : (n.state === 'down' ? pal.fail : pal.muted);
			var label = dxText[n.state];
			var load = n.load == null ? '—' : '<span class="dx-loadbar"><i style="width:' + Math.min(100, n.load * 50).toFixed(0) + '%;background:' + (n.load < 1 ? pal.ok : (n.load < 2 ? pal.warn : pal.fail)) + '"></i></span>' + nf1.format(n.load);
			return '<tr' + (n.state === 'off' ? ' style="opacity:.55"' : '') + '><td><b>' + esc(n.name) + '</b> <span class="dx-pill ms-1"><i style="background:' + color + '"></i>' + label + '</span></td>' +
				'<td>' + load + '</td><td class="dx-num">' + num(n.online) + '</td><td class="dx-num">' + gb(n.today_gb) + '</td></tr>';
		}).join('');
		set('tNodes', head + '<tbody>' + body + '</tbody>');
	}

	function recent() {
		var pal = palette();
		var head = '<thead><tr><th>' + dxText.user + '</th><th>' + dxText.plan + '</th><th class="dx-num">' + dxText.amount + '</th><th>' + dxText.when + '</th></tr></thead>';
		var body = data.recent.map(function (r) {
			return '<tr><td>' + esc(r.user) + '</td><td><span class="dx-pill"><i style="background:' + (r.topup ? pal.s[1] : pal.s[0]) + '"></i>' + esc(r.plan) + '</span></td>' +
				'<td class="dx-num">' + money(r.amount) + '</td><td class="text-muted">' + timeFmt.format(new Date(r.t * 1000)) + '</td></tr>';
		}).join('');
		set('tRecent', head + '<tbody>' + (body || '<tr><td colspan="4" class="dx-empty">' + dxText.empty + '</td></tr>') + '</tbody>');
	}

	function health() {
		var checks = data.health, worst = 'ok', counts = { ok: 0, warn: 0, fail: 0 };
		checks.forEach(function (c) {
			counts[c.state]++;
			if (c.state === 'fail' || (c.state === 'warn' && worst === 'ok')) { worst = c.state; }
		});
		var icon = { ok: 'fa-check', warn: 'fa-exclamation', fail: 'fa-xmark' };
		var title = worst === 'ok' ? dxText.healthOk : (worst === 'warn' ? dxText.healthWarn : dxText.healthFail);
		var html = '<div class="dx-health-score"><div class="dx-health-ring ' + worst + '"><i class="fa-solid ' + icon[worst] + '"></i></div><div><b>' + title + '</b><span>' +
			dxText.healthSummary.replace('%ok%', num(counts.ok)).replace('%all%', num(checks.length)) + ' · ' + num(data.took_ms) + ' ms</span></div></div>';
		html += checks.map(function (c) {
			return '<div class="dx-check"><span class="dx-check-name"><span class="dx-state ' + c.state + '"><i class="fa-solid ' + icon[c.state] + '"></i></span>' +
				esc(dxText.check[c.key] || c.key) + '</span><span class="dx-check-val">' + esc(c.value) + '</span></div>';
		}).join('');
		set('hHealth', html);
	}

	function render() {
		if (!data) { return; }
		var steps = [kpis, revenue, health, monthly, mix, plans, heat, segments, pipeline, registrations, traffic, nodes, recent];
		steps.forEach(function (fn) {
			// one broken section must not blank the rest of the page
			try { fn(); } catch (e) { if (window.console) { console.error('dashboard', fn.name, e); } }
		});
	}

	// ------------------------------------------------------------- loading
	function load() {
		root.classList.add('dx-loading');
		document.getElementById('dxError').classList.add('d-none');
		$.ajax({
			type: 'GET',
			url: '/xmplus-patch.php?do=dashboard.overview' + (jalali ? '&cal=jalali' : ''),
			dataType: 'json',
			success: function (res) {
				root.classList.remove('dx-loading');
				if (!res || !res.ok) { fail(res && res.error); return; }
				data = res;
				root.classList.remove('dx-skel');
				set('dxUpdated', dxText.updated + ' ' + timeFmt.format(new Date()));
				render();
			},
			error: function (xhr) { root.classList.remove('dx-loading'); fail(xhr && xhr.status ? 'HTTP ' + xhr.status : ''); }
		});
	}
	function fail(detail) {
		var box = document.getElementById('dxError');
		box.textContent = dxText.loadError + (detail ? ' — ' + detail : '');
		box.classList.remove('d-none');
	}

	document.getElementById('dxRefresh').addEventListener('click', load);
	document.querySelectorAll('.dx-seg').forEach(function (seg) {
		seg.addEventListener('click', function (e) {
			var btn = e.target.closest('button');
			if (!btn) { return; }
			seg.querySelectorAll('button').forEach(function (b) { b.classList.toggle('on', b === btn); });
			var key = seg.getAttribute('data-range');
			range[key] = Number(btn.getAttribute('data-days'));
			try { ({ revenue: revenue, registrations: registrations, traffic: traffic })[key](); } catch (err) { if (window.console) { console.error(err); } }
		});
	});
	window.addEventListener('on-hs-appearance-change', function () { setTimeout(render, 50); });

	load();
	// keep the numbers fresh while the page is open
	setInterval(function () { if (!document.hidden) { load(); } }, 5 * 60 * 1000);
})();
{/literal}
</script>
