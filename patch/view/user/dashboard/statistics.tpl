{literal}
<style>
.quota-card { display: flex; flex-direction: column; }
.quota-card .card-body {
	padding-bottom: 8px;
	flex: 1 1 auto;
	display: flex;
	flex-direction: column;
	justify-content: center;
}
.quota-chart { direction: ltr; min-height: 250px; }
.quota-legend {
	display: flex;
	justify-content: center;
	flex-wrap: wrap;
	gap: 8px 18px;
	margin-top: -6px;
	margin-bottom: 6px;
}
.quota-legend-item {
	display: inline-flex;
	align-items: center;
	gap: 7px;
	font-size: 12px;
	color: #7a869f;
}
.quota-legend-dot {
	width: 9px;
	height: 9px;
	border-radius: 3px;
	background: var(--dot, #6366f1);
	flex: 0 0 auto;
}
.quota-legend-item b {
	font-weight: 700;
	color: #16203d;
	direction: ltr;
	unicode-bidi: isolate;
}
.quota-stats {
	display: grid;
	grid-template-columns: repeat(3, minmax(0, 1fr));
	border-top: 1px solid rgba(23, 32, 61, .07);
}
.quota-stat {
	position: relative;
	padding: 12px 6px 13px;
	text-align: center;
}
.quota-stat + .quota-stat::before {
	content: "";
	position: absolute;
	top: 22%;
	bottom: 22%;
	inset-inline-start: 0;
	width: 1px;
	background: rgba(23, 32, 61, .08);
}
.quota-stat-value {
	font-size: 14px;
	font-weight: 700;
	color: #16203d;
	direction: ltr;
	unicode-bidi: isolate;
	display: block;
}
.quota-stat-label {
	font-size: 11.5px;
	color: #97a4af;
	margin-top: 2px;
	display: block;
}
.quota-stat-bullet {
	display: inline-block;
	width: 6px;
	height: 6px;
	border-radius: 50%;
	margin-inline-end: 5px;
	background: var(--dot, #6366f1);
	vertical-align: middle;
}

html[data-hs-theme="dark"] .quota-legend-item { color: #9fb0cc; }
html[data-hs-theme="dark"] .quota-legend-item b,
html[data-hs-theme="dark"] .quota-stat-value { color: #e7eaf3; }
html[data-hs-theme="dark"] .quota-stats { border-top-color: rgba(255, 255, 255, .08); }
html[data-hs-theme="dark"] .quota-stat + .quota-stat::before { background: rgba(255, 255, 255, .1); }
html[data-hs-theme="dark"] .quota-stat-label { color: #8b9ab5; }
</style>
{/literal}

<div class="col-lg-12 col-xl-4 col-md-12 col-sm-12 mb-3 mb-lg-5">
	<div class="card card-shadow shadow-lg rounded usage-card quota-card">
		<div class="card-header card-header-content-between border-bottom">
			<h3 class="card-header-title mb-0">{$translate->get('Statistics')}</h3>
			{if $note != null}<span class="usage-badge">{$note}</span>{/if}
		</div>

		<div class="card-body">
			<div class="quota-chart" id="quotaChart"></div>
			<div class="quota-legend">
				<span class="quota-legend-item">
					<span class="quota-legend-dot" id="quotaLegendDot"></span>
					{$translate->get('unUsedData')} <b>{$user->unusedTraffic()}</b>
				</span>
				<span class="quota-legend-item">
					<span class="quota-legend-dot" style="--dot:#f43f5e"></span>
					{$translate->get('UsedData')} <b>{$user->usedTraffic()}</b>
				</span>
			</div>
		</div>

		<div class="quota-stats">
			<div class="quota-stat">
				<span class="quota-stat-value">{$user->TodayTraffic()}</span>
				<span class="quota-stat-label"><i class="quota-stat-bullet" style="--dot:#06b6d4"></i>{$translate->get('TodayData')}</span>
			</div>
			<div class="quota-stat">
				<span class="quota-stat-value">{$user->usedTraffic()}</span>
				<span class="quota-stat-label"><i class="quota-stat-bullet" style="--dot:#f43f5e"></i>{$translate->get('UsedData')}</span>
			</div>
			<div class="quota-stat">
				<span class="quota-stat-value">{$user->enableTraffic()}</span>
				<span class="quota-stat-label"><i class="quota-stat-bullet" style="--dot:#8b5cf6"></i>{$translate->get('TotalData')}</span>
			</div>
		</div>
	</div>
</div>
