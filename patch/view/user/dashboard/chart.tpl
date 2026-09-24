{literal}
<style>
.usage-card {
	border: 0;
	border-radius: 18px;
	overflow: hidden;
}
.usage-card .card-header {
	display: flex;
	align-items: center;
	justify-content: space-between;
	flex-wrap: wrap;
	gap: .75rem;
	background: transparent;
}
.usage-range {
	display: inline-flex;
	padding: 4px;
	gap: 2px;
	border-radius: 999px;
	background: #eef1f8;
}
.usage-range-btn {
	border: 0;
	background: transparent;
	color: #5c6b8a;
	font-size: 12.5px;
	font-weight: 600;
	line-height: 1;
	padding: 8px 14px;
	border-radius: 999px;
	cursor: pointer;
	white-space: nowrap;
	transition: background .18s ease, color .18s ease, box-shadow .18s ease;
}
.usage-range-btn:hover { color: #2f3d5c; }
.usage-range-btn.active {
	background: #ffffff;
	color: #4f46e5;
	box-shadow: 0 2px 8px rgba(23, 32, 61, .12);
}
.usage-badge {
	display: inline-flex;
	align-items: center;
	padding: 5px 12px;
	border-radius: 999px;
	font-size: 11.5px;
	font-weight: 600;
	line-height: 1;
	color: #4f46e5;
	background: rgba(99, 102, 241, .1);
}
html[data-hs-theme="dark"] .usage-badge {
	color: #c7d2fe;
	background: rgba(99, 102, 241, .22);
}
.usage-kpis {
	display: grid;
	grid-template-columns: repeat(3, minmax(0, 1fr));
	gap: 12px;
	margin-bottom: 18px;
}
.usage-kpi {
	position: relative;
	border-radius: 14px;
	padding: 14px 16px;
	background: #f7f8fc;
	border: 1px solid rgba(23, 32, 61, .06);
	overflow: hidden;
}
.usage-kpi::after {
	content: "";
	position: absolute;
	inset: auto 0 0 0;
	height: 3px;
	background: var(--kpi-color, #6366f1);
	opacity: .9;
}
.usage-kpi-label {
	display: flex;
	align-items: center;
	gap: 6px;
	font-size: 12px;
	font-weight: 600;
	color: #7a869f;
	margin-bottom: 6px;
}
.usage-kpi-dot {
	width: 8px;
	height: 8px;
	border-radius: 50%;
	background: var(--kpi-color, #6366f1);
	flex: 0 0 auto;
}
.usage-kpi-value {
	font-size: 20px;
	font-weight: 700;
	color: #16203d;
	line-height: 1.2;
}
/* ApexCharts draws its own axis/legend layout, RTL only mangles the numbers */
#usageArea, #usageDonut { direction: ltr; }
.usage-num { direction: ltr; unicode-bidi: isolate; }
.usage-kpi-sub {
	font-size: 11.5px;
	color: #97a4af;
	margin-top: 2px;
}
.usage-empty {
	display: flex;
	flex-direction: column;
	align-items: center;
	justify-content: center;
	gap: 8px;
	min-height: 240px;
	color: #97a4af;
	font-size: 13px;
}
.usage-empty i { font-size: 30px; opacity: .5; }
.usage-servers-list { margin: 0; }
.usage-server {
	display: flex;
	align-items: center;
	gap: 12px;
	padding: 10px 0;
	border-bottom: 1px dashed rgba(23, 32, 61, .08);
}
.usage-server:last-child { border-bottom: 0; }
.usage-server-rank {
	width: 26px;
	height: 26px;
	flex: 0 0 auto;
	border-radius: 9px;
	display: flex;
	align-items: center;
	justify-content: center;
	font-size: 11.5px;
	font-weight: 700;
	color: #fff;
}
.usage-server-body { flex: 1 1 auto; min-width: 0; }
.usage-server-head {
	display: flex;
	align-items: baseline;
	justify-content: space-between;
	gap: 10px;
	margin-bottom: 5px;
}
.usage-server-name {
	font-size: 13px;
	font-weight: 600;
	color: #16203d;
	white-space: nowrap;
	overflow: hidden;
	text-overflow: ellipsis;
}
.usage-server-total {
	font-size: 12.5px;
	font-weight: 700;
	color: #16203d;
	direction: ltr;
	unicode-bidi: isolate;
	white-space: nowrap;
}
.usage-server-bar {
	height: 6px;
	border-radius: 999px;
	background: rgba(23, 32, 61, .07);
	overflow: hidden;
}
.usage-server-bar span {
	display: block;
	height: 100%;
	border-radius: 999px;
	transition: width .4s ease;
}
.usage-server-meta {
	display: flex;
	gap: 14px;
	margin-top: 5px;
	font-size: 11px;
	color: #8c98ab;
}
.usage-server-meta b { font-weight: 600; direction: ltr; unicode-bidi: isolate; }

html[data-hs-theme="dark"] .usage-range { background: rgba(255, 255, 255, .06); }
html[data-hs-theme="dark"] .usage-range-btn { color: #9fb0cc; }
html[data-hs-theme="dark"] .usage-range-btn.active {
	background: rgba(255, 255, 255, .12);
	color: #c7d2fe;
	box-shadow: none;
}
html[data-hs-theme="dark"] .usage-kpi {
	background: rgba(255, 255, 255, .04);
	border-color: rgba(255, 255, 255, .07);
}
html[data-hs-theme="dark"] .usage-kpi-value,
html[data-hs-theme="dark"] .usage-server-name,
html[data-hs-theme="dark"] .usage-server-total { color: #e7eaf3; }
html[data-hs-theme="dark"] .usage-server { border-bottom-color: rgba(255, 255, 255, .08); }
html[data-hs-theme="dark"] .usage-server-bar { background: rgba(255, 255, 255, .09); }

html[data-hs-theme="dark"] .usage-kpi-label,
html[data-hs-theme="dark"] .usage-server-meta { color: #aab6cc; }
html[data-hs-theme="dark"] .usage-kpi-sub { color: #9aa8c0; }
html[data-hs-theme="dark"] .usage-empty { color: #aab6cc; }
/* ---- the server this user is connected to: a Gemini-style halogen line ----
   The colour lives only inside the bar's own track - no glow or blur
   spilling outside it. */
/* a wider track, with halogen packets streaming through the empty part of it
   to say data is moving right now */
.usage-server.is-live .usage-server-bar {
	position: relative;
	height: 12px;
	overflow: hidden;
	isolation: isolate;
}
.usage-server.is-live .usage-server-bar::before {
	content: "";
	position: absolute;
	inset: 0;
	z-index: 0;
	background:
		linear-gradient(90deg, transparent 0 22%, rgba(71, 150, 227, .55) 30%, rgba(145, 119, 199, .65) 36%, transparent 44% 100%),
		linear-gradient(90deg, transparent 0 60%, rgba(202, 102, 115, .5) 66%, rgba(242, 166, 90, .55) 71%, transparent 78% 100%);
	/* tile widths equal the distance each moves per loop, so it never jumps */
	background-size: 110px 100%, 76px 100%;
	background-repeat: repeat-x;
	animation: usageStream 1.6s linear infinite;
}
.usage-server.is-live .usage-server-bar span {
	position: relative;
	z-index: 1;
	min-width: 18%;
	overflow: hidden;
	background: linear-gradient(90deg, #4796e3, #9177c7, #ca6673, #f2a65a, #9177c7, #4796e3) !important;
	background-size: 300% 100% !important;
	animation: usageHalogen 4s linear infinite;
}
/* a bright packet running along the filled part too, kept inside it */
.usage-server.is-live .usage-server-bar span::after {
	content: "";
	position: absolute;
	inset: 0;
	background: linear-gradient(90deg, transparent 0 40%, rgba(255, 255, 255, .55) 50%, transparent 60% 100%);
	background-size: 250% 100%;
	animation: usageShine 1.4s linear infinite;
}
@keyframes usageShine {
	from { background-position: 100% 0; }
	to   { background-position: -150% 0; }
}
@keyframes usageStream {
	from { background-position: 0 0, 0 0; }
	to   { background-position: 110px 0, 76px 0; }
}
.usage-server.is-live .usage-server-rank {
	background: linear-gradient(135deg, #4796e3, #9177c7 55%, #ca6673) !important;
}
@keyframes usageHalogen {
	from { background-position: 0% 50%; }
	to   { background-position: 300% 50%; }
}
.usage-live {
	display: inline-flex;
	align-items: center;
	gap: 5px;
	margin-inline-start: 6px;
	padding: 2px 8px;
	border-radius: 999px;
	font-size: 10.5px;
	font-weight: 700;
	vertical-align: 1px;
	color: #fff;
	background: linear-gradient(90deg, #4796e3, #9177c7, #ca6673);
}
.usage-live i {
	width: 6px;
	height: 6px;
	border-radius: 50%;
	background: #fff;
	animation: usageLivePulse 1.6s ease-in-out infinite;
}
@keyframes usageLivePulse {
	0%, 100% { opacity: 1; box-shadow: 0 0 0 0 rgba(255, 255, 255, .7); }
	50%      { opacity: .6; box-shadow: 0 0 0 4px rgba(255, 255, 255, 0); }
}
@media (prefers-reduced-motion: reduce) {
	.usage-server.is-live .usage-server-bar span,
	.usage-server.is-live .usage-server-bar span::after,
	.usage-server.is-live .usage-server-bar::before,
	.usage-live i { animation: none; }
}

@media (max-width: 575.98px) {
	.usage-kpis { grid-template-columns: 1fr; }
	.usage-range {
		max-width: 100%;
		overflow-x: auto;
		scrollbar-width: none;
	}
	.usage-range::-webkit-scrollbar { display: none; }
	.usage-range-btn { padding: 7px 10px; font-size: 11.5px; }
	.usage-card .card-header { gap: .5rem; }
	.usage-server-meta { gap: 10px; font-size: 10.5px; }
	.usage-server { gap: 9px; }
}
</style>
{/literal}

<div class="col-lg-12 col-xl-8 col-md-12 col-sm-12 mb-3 mb-lg-5">
	<div class="card card-shadow shadow-lg rounded usage-card">
		<div class="card-header card-header-content-between border-bottom">
			<h4 class="card-header-title mb-0">{$translate->get('TrafficUsageChart')}</h4>
			<div class="usage-range" id="usageRange" role="tablist">
				<button type="button" class="usage-range-btn active" data-range="day">{$translate->get('RangeDay')}</button>
				<button type="button" class="usage-range-btn" data-range="week">{$translate->get('RangeWeek')}</button>
				<button type="button" class="usage-range-btn" data-range="month">{$translate->get('RangeMonth')}</button>
				<button type="button" class="usage-range-btn" data-range="year">{$translate->get('RangeYear')}</button>
			</div>
		</div>

		<div class="card-body">
			<div class="usage-kpis">
				<div class="usage-kpi" style="--kpi-color:#8b5cf6">
					<div class="usage-kpi-label"><span class="usage-kpi-dot"></span>{$translate->get('TotalUsage')}</div>
					<div class="usage-kpi-value" id="usageKpiTotal">0</div>
					<div class="usage-kpi-sub" id="usageKpiPeak">&nbsp;</div>
				</div>
				<div class="usage-kpi" style="--kpi-color:#6366f1">
					<div class="usage-kpi-label"><span class="usage-kpi-dot"></span>{$translate->get('Downloaded')}</div>
					<div class="usage-kpi-value" id="usageKpiDown">0</div>
					<div class="usage-kpi-sub" id="usageKpiDownPct">&nbsp;</div>
				</div>
				<div class="usage-kpi" style="--kpi-color:#f59e0b">
					<div class="usage-kpi-label"><span class="usage-kpi-dot"></span>{$translate->get('Uploaded')}</div>
					<div class="usage-kpi-value" id="usageKpiUp">0</div>
					<div class="usage-kpi-sub" id="usageKpiUpPct">&nbsp;</div>
				</div>
			</div>

			<div id="usageArea" style="min-height:280px"></div>
		</div>
	</div>
</div>
