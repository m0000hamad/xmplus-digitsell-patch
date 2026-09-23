<script>localStorage.setItem('toggleID', ''); </script>
{include file='admin/layout/header.tpl'}
{$rtl = explode(',',$Config['rtlanguages'])}
{literal}
<style>
	/* Chart colours are roles, swapped in one place for dark mode. The
	   categorical order (blue, orange, aqua, yellow, magenta) is the
	   CVD-checked order; status colours are kept for health only. */
	.dx {
		--dx-s1: #2a78d6; --dx-s2: #eb6834; --dx-s3: #1baf7a; --dx-s4: #eda100; --dx-s5: #e87ba4;
		--dx-ok: #0e9f6e; --dx-warn: #d98a00; --dx-fail: #e02424;
		--dx-muted: #6b7280; --dx-line: rgba(127,127,127,.16); --dx-soft: rgba(127,127,127,.07);
	}
	html[data-hs-appearance="dark"] .dx, .dx.dx-dark {
		--dx-s1: #3987e5; --dx-s2: #d95926; --dx-s3: #199e70; --dx-s4: #c98500; --dx-s5: #d55181;
		--dx-ok: #31c48d; --dx-warn: #f0b429; --dx-fail: #f05252;
		--dx-muted: #9aa3b2; --dx-line: rgba(200,200,200,.12); --dx-soft: rgba(200,200,200,.05);
	}
	.dx .card { border-radius: 14px; }
	.dx .card-header { padding-top: .9rem; padding-bottom: .9rem; }
	.dx .card-header-title { font-size: .95rem; font-weight: 600; }
	.dx-hero { display: flex; align-items: center; justify-content: space-between; gap: 1rem; flex-wrap: wrap; }
	.dx-hero small { color: var(--dx-muted); }
	.dx-hero .btn { border-radius: 10px; }
	.dx-spin { display: inline-block; }
	.dx-loading .dx-spin { animation: dx-rot 1s linear infinite; }
	@keyframes dx-rot { to { transform: rotate(360deg); } }

	.dx-kpi { position: relative; overflow: hidden; height: 100%; }
	.dx-kpi .card-body { padding: 1.1rem 1.2rem .4rem; }
	.dx-kpi-top { display: flex; align-items: center; justify-content: space-between; gap: .5rem; }
	.dx-kpi-label { color: var(--dx-muted); font-size: .8rem; margin: 0; }
	.dx-kpi-icon { width: 38px; height: 38px; border-radius: 11px; display: grid; place-items: center; font-size: 1rem; }
	.dx-kpi-value { font-size: 1.45rem; font-weight: 700; margin: .45rem 0 .2rem; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
	.dx-kpi-value small { font-size: .75rem; font-weight: 500; color: var(--dx-muted); }
	.dx-kpi-foot { display: flex; align-items: center; gap: .4rem; font-size: .75rem; color: var(--dx-muted); flex-wrap: wrap; }
	.dx-spark { margin: 0 -.4rem; height: 54px; }
	.dx-delta { display: inline-flex; align-items: center; gap: .2rem; padding: .1rem .45rem; border-radius: 999px; font-weight: 600; font-size: .72rem; direction: ltr; }
	.dx-delta.up { color: var(--dx-ok); background: color-mix(in srgb, var(--dx-ok) 13%, transparent); }
	.dx-delta.down { color: var(--dx-fail); background: color-mix(in srgb, var(--dx-fail) 13%, transparent); }
	.dx-delta.flat { color: var(--dx-muted); background: var(--dx-soft); }

	.dx-strip { display: grid; grid-template-columns: repeat(6, minmax(0, 1fr)); }
	.dx-strip > div { padding: .85rem 1rem; border-inline-start: 1px solid var(--dx-line); min-width: 0; }
	.dx-strip > div:first-child { border-inline-start: 0; }
	.dx-strip b { display: block; font-size: 1.05rem; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
	.dx-strip span { color: var(--dx-muted); font-size: .75rem; }
	.dx-strip em { font-style: normal; }
	.dx-strip a { color: inherit; }
	@media (max-width: 1199px) { .dx-strip { grid-template-columns: repeat(3, minmax(0, 1fr)); } .dx-strip > div:nth-child(4) { border-inline-start: 0; } .dx-strip > div:nth-child(n+4) { border-top: 1px solid var(--dx-line); } }
	@media (max-width: 575px) { .dx-strip { grid-template-columns: repeat(2, minmax(0, 1fr)); } .dx-strip > div { border-inline-start: 0 !important; border-top: 1px solid var(--dx-line); } .dx-strip > div:nth-child(-n+2) { border-top: 0; } .dx-strip > div:nth-child(even) { border-inline-start: 1px solid var(--dx-line) !important; } }

	.dx-seg { display: inline-flex; padding: 3px; border-radius: 10px; background: var(--dx-soft); gap: 2px; }
	.dx-seg button { border: 0; background: transparent; color: var(--dx-muted); font-size: .78rem; padding: .25rem .7rem; border-radius: 8px; }
	.dx-seg button.on { background: var(--bs-body-bg, #fff); color: inherit; box-shadow: 0 1px 3px rgba(0,0,0,.12); font-weight: 600; }

	.dx-legend { display: flex; flex-wrap: wrap; gap: .35rem 1rem; font-size: .78rem; color: var(--dx-muted); }
	.dx-legend i { display: inline-block; width: 10px; height: 10px; border-radius: 3px; margin-inline-end: .35rem; vertical-align: -1px; }
	.dx-legend b { color: var(--bs-body-color); font-weight: 600; margin-inline-start: .25rem; }

	.dx-health-score { display: flex; align-items: center; gap: .9rem; padding: .2rem 0 .9rem; border-bottom: 1px solid var(--dx-line); margin-bottom: .4rem; }
	.dx-health-ring { width: 54px; height: 54px; border-radius: 50%; display: grid; place-items: center; font-size: 1.3rem; flex: none; }
	.dx-health-ring.ok { color: var(--dx-ok); background: color-mix(in srgb, var(--dx-ok) 14%, transparent); }
	.dx-health-ring.warn { color: var(--dx-warn); background: color-mix(in srgb, var(--dx-warn) 16%, transparent); }
	.dx-health-ring.fail { color: var(--dx-fail); background: color-mix(in srgb, var(--dx-fail) 14%, transparent); }
	.dx-health-score b { display: block; font-size: 1rem; }
	.dx-health-score span { color: var(--dx-muted); font-size: .78rem; }
	.dx-check { display: flex; align-items: center; justify-content: space-between; gap: .75rem; padding: .48rem 0; border-bottom: 1px dashed var(--dx-line); font-size: .82rem; }
	.dx-check:last-child { border-bottom: 0; }
	.dx-check .dx-check-name { display: flex; align-items: center; gap: .5rem; min-width: 0; }
	.dx-check .dx-check-val { color: var(--dx-muted); direction: ltr; white-space: nowrap; font-size: .76rem; }
	.dx-state { width: 20px; height: 20px; border-radius: 50%; display: grid; place-items: center; font-size: .65rem; color: #fff; flex: none; }
	.dx-state.ok { background: var(--dx-ok); } .dx-state.warn { background: var(--dx-warn); } .dx-state.fail { background: var(--dx-fail); }

	.dx-rank { display: grid; gap: .7rem; }
	.dx-rank-row { display: grid; grid-template-columns: minmax(0, 1fr) auto; gap: .2rem .75rem; font-size: .82rem; }
	.dx-rank-row .dx-rank-name { white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
	.dx-rank-row .dx-rank-val { color: var(--dx-muted); font-size: .76rem; white-space: nowrap; }
	.dx-rank-bar { grid-column: 1 / -1; height: 8px; border-radius: 4px; background: var(--dx-soft); overflow: hidden; }
	.dx-rank-bar i { display: block; height: 100%; border-radius: 4px; transition: width .6s ease; }

	.dx-table { width: 100%; font-size: .8rem; }
	.dx-table th { color: var(--dx-muted); font-weight: 500; padding: .5rem .6rem; border-bottom: 1px solid var(--dx-line); white-space: nowrap; }
	.dx-table td { padding: .55rem .6rem; border-bottom: 1px solid var(--dx-line); white-space: nowrap; }
	.dx-table tr:last-child td { border-bottom: 0; }
	.dx-table .dx-num { direction: ltr; text-align: end; }
	.dx-pill { display: inline-flex; align-items: center; gap: .35rem; font-size: .74rem; padding: .12rem .5rem; border-radius: 999px; background: var(--dx-soft); }
	.dx-pill i { width: 7px; height: 7px; border-radius: 50%; display: inline-block; }
	.dx-loadbar { display: inline-block; width: 46px; height: 6px; border-radius: 3px; background: var(--dx-soft); vertical-align: middle; margin-inline-end: .35rem; overflow: hidden; }
	.dx-loadbar i { display: block; height: 100%; border-radius: 3px; }
	.dx-empty { color: var(--dx-muted); font-size: .82rem; text-align: center; padding: 2rem 0; }
	.dx-chart { min-height: 120px; direction: ltr; }
	.dx-skel .dx-kpi-value, .dx-skel .dx-strip b { color: transparent; background: var(--dx-soft); border-radius: 6px; }
	.dx .apexcharts-tooltip { border-radius: 10px !important; box-shadow: 0 8px 24px rgba(0,0,0,.14) !important; }
	.dx .apexcharts-tooltip-title { font-weight: 600 !important; }
	.dx .apexcharts-text, .dx .apexcharts-tooltip, .dx .apexcharts-legend-text { font-family: inherit !important; }
</style>
{/literal}

<div class="dx dx-skel" id="dx">
	<div class="page-header mb-3">
		<div class="dx-hero">
			<div>
				<h1 class="page-header-title mb-1">{$translate->get('Dashboard')}</h1>
				<small>{$translate->get('DashSubtitle')} · <span id="dxUpdated">…</span></small>
			</div>
			<button type="button" class="btn btn-sm btn-white" id="dxRefresh"><i class="fa-duotone fa-arrows-rotate dx-spin"></i> {$translate->get('DashRefresh')}</button>
		</div>
	</div>

	<div class="alert alert-soft-danger d-none" id="dxError"></div>

	<!-- headline numbers -->
	<div class="row g-3 mb-3">
		<div class="col-xl-3 col-sm-6">
			<div class="card card-shadow dx-kpi">
				<div class="card-body">
					<div class="dx-kpi-top">
						<p class="dx-kpi-label">{$translate->get('DashRevenueToday')}</p>
						<span class="dx-kpi-icon icon-soft-primary"><i class="fa-duotone fa-sack-dollar text-primary"></i></span>
					</div>
					<div class="dx-kpi-value" id="kRevToday">—</div>
					<div class="dx-kpi-foot"><span id="kRevTodayDelta"></span><span>{$translate->get('DashVsYesterday')}</span></div>
				</div>
				<div class="dx-spark" id="sRevToday"></div>
			</div>
		</div>
		<div class="col-xl-3 col-sm-6">
			<div class="card card-shadow dx-kpi">
				<div class="card-body">
					<div class="dx-kpi-top">
						<p class="dx-kpi-label">{$translate->get('DashRevenue30')}</p>
						<span class="dx-kpi-icon icon-soft-success"><i class="fa-duotone fa-chart-line-up text-success"></i></span>
					</div>
					<div class="dx-kpi-value" id="kRev30">—</div>
					<div class="dx-kpi-foot"><span id="kRev30Delta"></span><span>{$translate->get('DashVsPrev30')}</span></div>
				</div>
				<div class="dx-spark" id="sRev30"></div>
			</div>
		</div>
		<div class="col-xl-3 col-sm-6">
			<div class="card card-shadow dx-kpi">
				<div class="card-body">
					<div class="dx-kpi-top">
						<p class="dx-kpi-label">{$translate->get('DashOrders30')}</p>
						<span class="dx-kpi-icon icon-soft-warning"><i class="fa-duotone fa-cart-shopping text-warning"></i></span>
					</div>
					<div class="dx-kpi-value" id="kOrders30">—</div>
					<div class="dx-kpi-foot"><span id="kOrders30Delta"></span><span>{$translate->get('DashConversion')} <b id="kConversion"></b></span></div>
				</div>
				<div class="dx-spark" id="sOrders30"></div>
			</div>
		</div>
		<div class="col-xl-3 col-sm-6">
			<div class="card card-shadow dx-kpi">
				<div class="card-body">
					<div class="dx-kpi-top">
						<p class="dx-kpi-label">{$translate->get('DashActiveUsers')}</p>
						<span class="dx-kpi-icon icon-soft-info"><i class="fa-duotone fa-users text-info"></i></span>
					</div>
					<div class="dx-kpi-value" id="kActive">—</div>
					<div class="dx-kpi-foot"><span class="dx-delta flat"><i class="fa-solid fa-circle" style="font-size:.45rem;color:var(--dx-ok)"></i> <span id="kOnline"></span></span><span>{$translate->get('DashOnlineNow')}</span></div>
				</div>
				<div class="dx-spark" id="sUsers"></div>
			</div>
		</div>
	</div>

	<!-- secondary numbers -->
	<div class="card card-shadow mb-3">
		<div class="dx-strip">
			<div><b id="kAov">—</b><span>{$translate->get('DashAov')} <em id="kAovDelta"></em></span></div>
			<div><b id="kBuyers">—</b><span>{$translate->get('DashBuyers')}</span></div>
			<div><b id="kNewUsers">—</b><span>{$translate->get('DashNewUsers')} <em id="kNewUsersDelta"></em></span></div>
			<div><b id="kWallet">—</b><span>{$translate->get('DashWallet')}</span></div>
			<div><b id="kLapsed">—</b><span>{$translate->get('DashLapsed')}</span></div>
			<div><a href="/admin/tickets"><b>{$Stats->waitTicket()}</b><span>{$translate->get('DashTickets')}</span></a></div>
		</div>
	</div>

	<!-- revenue + health -->
	<div class="row g-3 mb-3">
		<div class="col-xl-8">
			<div class="card card-shadow h-100">
				<div class="card-header card-header-content-sm-between">
					<h4 class="card-header-title mb-2 mb-sm-0">{$translate->get('DashRevenueDaily')}</h4>
					<div class="dx-seg" data-range="revenue">
						<button type="button" data-days="30" class="on">{$translate->get('DashDays30')}</button>
						<button type="button" data-days="90">{$translate->get('DashDays90')}</button>
					</div>
				</div>
				<div class="card-body">
					<div class="dx-legend mb-2" id="lRevenue"></div>
					<div class="dx-chart" id="cRevenue"></div>
				</div>
			</div>
		</div>
		<div class="col-xl-4">
			<div class="card card-shadow h-100">
				<div class="card-header">
					<h4 class="card-header-title">{$translate->get('DashHealth')}</h4>
				</div>
				<div class="card-body pt-2" id="hHealth">
					<div class="dx-empty">…</div>
				</div>
			</div>
		</div>
	</div>

	<!-- monthly + mix -->
	<div class="row g-3 mb-3">
		<div class="col-xl-8">
			<div class="card card-shadow h-100">
				<div class="card-header"><h4 class="card-header-title">{$translate->get('DashMonthly')}</h4></div>
				<div class="card-body"><div class="dx-chart" id="cMonthly"></div></div>
			</div>
		</div>
		<div class="col-xl-4">
			<div class="card card-shadow h-100">
				<div class="card-header"><h4 class="card-header-title">{$translate->get('DashMix')}</h4></div>
				<div class="card-body">
					<div class="dx-chart" id="cMix"></div>
					<div class="dx-legend justify-content-center mt-2" id="lMix"></div>
					<hr class="my-3">
					<h6 class="text-muted mb-3" style="font-size:.78rem">{$translate->get('DashGateways')}</h6>
					<div class="dx-rank" id="rGateways"></div>
				</div>
			</div>
		</div>
	</div>

	<!-- plans + heatmap -->
	<div class="row g-3 mb-3">
		<div class="col-xl-5">
			<div class="card card-shadow h-100">
				<div class="card-header"><h4 class="card-header-title">{$translate->get('DashTopPlans')}</h4></div>
				<div class="card-body"><div class="dx-rank" id="rPlans"></div></div>
			</div>
		</div>
		<div class="col-xl-7">
			<div class="card card-shadow h-100">
				<div class="card-header"><h4 class="card-header-title">{$translate->get('DashHeat')}</h4></div>
				<div class="card-body"><div class="dx-chart" id="cHeat"></div></div>
			</div>
		</div>
	</div>

	<!-- users -->
	<div class="row g-3 mb-3">
		<div class="col-xl-4 col-lg-6">
			<div class="card card-shadow h-100">
				<div class="card-header"><h4 class="card-header-title">{$translate->get('DashSegments')}</h4></div>
				<div class="card-body">
					<div class="dx-chart" id="cSegments"></div>
					<div class="dx-legend justify-content-center mt-2" id="lSegments"></div>
				</div>
			</div>
		</div>
		<div class="col-xl-4 col-lg-6">
			<div class="card card-shadow h-100">
				<div class="card-header"><h4 class="card-header-title">{$translate->get('DashPipeline')}</h4></div>
				<div class="card-body"><div class="dx-chart" id="cPipeline"></div></div>
			</div>
		</div>
		<div class="col-xl-4">
			<div class="card card-shadow h-100">
				<div class="card-header card-header-content-sm-between">
					<h4 class="card-header-title mb-2 mb-sm-0">{$translate->get('DashRegistrations')}</h4>
					<div class="dx-seg" data-range="registrations">
						<button type="button" data-days="30" class="on">{$translate->get('DashDays30')}</button>
						<button type="button" data-days="90">{$translate->get('DashDays90')}</button>
					</div>
				</div>
				<div class="card-body"><div class="dx-chart" id="cRegistrations"></div></div>
			</div>
		</div>
	</div>

	<!-- traffic -->
	<div class="row g-3 mb-3">
		<div class="col-xl-8">
			<div class="card card-shadow h-100">
				<div class="card-header card-header-content-sm-between">
					<h4 class="card-header-title mb-2 mb-sm-0">{$translate->get('DashTraffic')}</h4>
					<div class="dx-seg" data-range="traffic">
						<button type="button" data-days="30" class="on">{$translate->get('DashDays30')}</button>
						<button type="button" data-days="90">{$translate->get('DashDays90')}</button>
					</div>
				</div>
				<div class="card-body"><div class="dx-chart" id="cTraffic"></div></div>
			</div>
		</div>
		<div class="col-xl-4">
			<div class="card card-shadow h-100">
				<div class="card-header"><h4 class="card-header-title">{$translate->get('DashTrafficServers')}</h4></div>
				<div class="card-body"><div class="dx-rank" id="rServers"></div></div>
			</div>
		</div>
	</div>

	<!-- nodes + recent orders -->
	<div class="row g-3 mb-3">
		<div class="col-xl-6">
			<div class="card card-shadow h-100">
				<div class="card-header"><h4 class="card-header-title">{$translate->get('DashNodes')}</h4></div>
				<div class="card-body p-2 table-responsive"><table class="dx-table" id="tNodes"></table></div>
			</div>
		</div>
		<div class="col-xl-6">
			<div class="card card-shadow h-100">
				<div class="card-header card-header-content-between">
					<h4 class="card-header-title">{$translate->get('DashRecent')}</h4>
					<a class="btn btn-sm btn-ghost-secondary" href="/admin/orders">{$translate->get('DashAll')}</a>
				</div>
				<div class="card-body p-2 table-responsive"><table class="dx-table" id="tRecent"></table></div>
			</div>
		</div>
	</div>
</div>

{include file='admin/layout/footer.tpl'}
<script src="/assets/js/apexcharts.js"></script>
{include file='admin/dashboard/dashboardjs.tpl'}
