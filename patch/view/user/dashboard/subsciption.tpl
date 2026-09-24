{literal}
<style>
.sub-card {
	position: relative;
	border: 0;
	border-radius: 20px;
	overflow: hidden;
}
/* a soft colour wash at the top so the card reads as the hero of the page */
.sub-card::before {
	content: "";
	position: absolute;
	inset: 0 0 auto 0;
	height: 106px;
	background: linear-gradient(135deg, var(--sub-a, #6366f1), var(--sub-b, #8b5cf6));
	opacity: .11;
	pointer-events: none;
}
.sub-card .card-header,
.sub-card .card-body { position: relative; }
.sub-card .card-header { background: transparent; }

.sub-gift {
	display: inline-flex;
	align-items: center;
	gap: 6px;
	border: 1.5px solid rgba(245, 158, 11, .4);
	background: rgba(245, 158, 11, .12);
	color: #b45309;
	border-radius: 999px;
	padding: 6px 13px;
	font-size: 11.5px;
	font-weight: 700;
	line-height: 1;
	cursor: pointer;
	white-space: nowrap;
	transition: background .15s ease, border-color .15s ease, transform .15s ease;
}
.sub-gift:hover {
	background: rgba(245, 158, 11, .22);
	border-color: rgba(245, 158, 11, .65);
	transform: translateY(-1px);
}

.sub-status {
	display: inline-flex;
	align-items: center;
	gap: 6px;
	padding: 5px 12px;
	border-radius: 999px;
	font-size: 11.5px;
	font-weight: 700;
	line-height: 1;
	margin-bottom: 11px;
	background: var(--sub-soft, rgba(16, 185, 129, .14));
	color: var(--sub-ink, #047857);
}
.sub-dot {
	width: 7px;
	height: 7px;
	border-radius: 50%;
	background: currentColor;
	box-shadow: 0 0 0 0 currentColor;
	animation: subPulse 2.2s infinite;
}
@keyframes subPulse {
	0%   { box-shadow: 0 0 0 0 rgba(16, 185, 129, .55); }
	70%  { box-shadow: 0 0 0 7px rgba(16, 185, 129, 0); }
	100% { box-shadow: 0 0 0 0 rgba(16, 185, 129, 0); }
}

.sub-name {
	font-size: 15px;
	font-weight: 800;
	color: #16203d;
	line-height: 1.75;
	margin: 0 0 10px;
}
.sub-chips { display: flex; flex-wrap: wrap; gap: 7px; margin-bottom: 15px; }
.sub-chip {
	display: inline-flex;
	align-items: center;
	gap: 5px;
	background: rgba(23, 32, 61, .055);
	border-radius: 9px;
	padding: 5px 10px;
	font-size: 11.5px;
	font-weight: 600;
	color: #3b4a6b;
}

/* ---- the countdown ---- */
.sub-clock {
	border-radius: 15px;
	padding: 13px 15px;
	background: rgba(255, 255, 255, .66);
	border: 1px solid rgba(23, 32, 61, .07);
	margin-bottom: 15px;
}
.sub-clock-top {
	display: flex;
	align-items: baseline;
	justify-content: space-between;
	gap: 10px;
	margin-bottom: 9px;
}
.sub-days {
	font-size: 13.5px;
	font-weight: 800;
	color: var(--sub-ink, #047857);
}
.sub-days b {
	font-size: 21px;
	direction: ltr;
	unicode-bidi: isolate;
	margin-inline-end: 3px;
}
.sub-until { font-size: 10.5px; color: #8c98ab; font-weight: 600; }
.sub-until time { direction: ltr; unicode-bidi: isolate; }
.sub-bar {
	height: 8px;
	border-radius: 999px;
	background: rgba(23, 32, 61, .09);
	overflow: hidden;
}
.sub-bar span {
	display: block;
	height: 100%;
	border-radius: 999px;
	background: linear-gradient(90deg, var(--sub-a, #10b981), var(--sub-b, #34d399));
	transition: width .6s ease;
}
.sub-mood {
	display: flex;
	align-items: center;
	gap: 6px;
	margin-top: 9px;
	font-size: 11.5px;
	font-weight: 600;
	color: #5c6b8a;
}

/* ---- actions ---- */
.sub-actions { display: flex; flex-wrap: wrap; gap: 8px; }
.sub-btn {
	display: inline-flex;
	align-items: center;
	justify-content: center;
	gap: 6px;
	border: 0;
	border-radius: 12px;
	padding: 10px 15px;
	font-size: 12.5px;
	font-weight: 700;
	line-height: 1.2;
	cursor: pointer;
	text-decoration: none !important;
	white-space: nowrap;
	transition: transform .14s ease, box-shadow .14s ease;
}
.sub-btn:hover { transform: translateY(-1px); }
.sub-btn-main { background: linear-gradient(135deg, #4f46e5, #7c3aed); color: #fff !important; box-shadow: 0 7px 18px rgba(99, 102, 241, .32); }
.sub-btn-buy { background: linear-gradient(135deg, #059669, #10b981); color: #fff !important; box-shadow: 0 7px 18px rgba(16, 185, 129, .3); }
.sub-btn-data { background: linear-gradient(135deg, #d97706, #f59e0b); color: #fff !important; box-shadow: 0 7px 18px rgba(245, 158, 11, .3); }
.sub-btn-time { background: linear-gradient(135deg, #0e7490, #06b6d4); color: #fff !important; box-shadow: 0 7px 18px rgba(6, 182, 212, .3); }

/* ---- the two small tiles ---- */
.sub-tiles {
	display: grid;
	grid-template-columns: 1fr 1fr;
	gap: 12px;
}
.sub-tile {
	position: relative;
	border-radius: 16px;
	padding: 14px;
	background: #fff;
	border: 1px solid rgba(23, 32, 61, .07);
	overflow: hidden;
}
.sub-tile::before {
	content: "";
	position: absolute;
	inset: auto 0 0 0;
	height: 3px;
	background: var(--tile, #6366f1);
}
.sub-tile-head {
	display: flex;
	align-items: center;
	gap: 7px;
	font-size: 11.5px;
	font-weight: 600;
	color: #7a869f;
	margin-bottom: 7px;
}
.sub-tile-emoji { font-size: 15px; }
.sub-tile-value {
	font-size: 18px;
	font-weight: 800;
	color: #16203d;
	direction: ltr;
	unicode-bidi: isolate;
	text-align: start;
	line-height: 1.3;
}
.sub-tile-bar {
	height: 5px;
	border-radius: 999px;
	background: rgba(23, 32, 61, .08);
	margin-top: 9px;
	overflow: hidden;
}
.sub-tile-bar span {
	display: block;
	height: 100%;
	border-radius: 999px;
	background: var(--tile, #6366f1);
	transition: width .6s ease;
}
.sub-tile-note { font-size: 10.5px; color: #97a4af; margin-top: 6px; font-weight: 600; }

html[data-hs-theme="dark"] .sub-name,
html[data-hs-theme="dark"] .sub-tile-value { color: #e7eaf3; }
html[data-hs-theme="dark"] .sub-chip { background: rgba(255, 255, 255, .07); color: #cfd8ea; }
html[data-hs-theme="dark"] .sub-clock {
	background: rgba(255, 255, 255, .05);
	border-color: rgba(255, 255, 255, .08);
}
html[data-hs-theme="dark"] .sub-bar,
html[data-hs-theme="dark"] .sub-tile-bar { background: rgba(255, 255, 255, .1); }
html[data-hs-theme="dark"] .sub-tile {
	background: rgba(255, 255, 255, .04);
	border-color: rgba(255, 255, 255, .08);
}
html[data-hs-theme="dark"] .sub-mood { color: #b6c4dc; }
html[data-hs-theme="dark"] .sub-gift {
	background: rgba(245, 158, 11, .16);
	border-color: rgba(245, 158, 11, .42);
	color: #fcd34d;
}
html[data-hs-theme="dark"] .sub-card::before { opacity: .16; }
/* the light-theme ink is too dark to sit on the tinted header at night */
html[data-hs-theme="dark"] .sub-status {
	background: rgba(255, 255, 255, .1);
	color: var(--sub-b, #34d399);
}
html[data-hs-theme="dark"] .sub-days { color: var(--sub-b, #34d399); }
html[data-hs-theme="dark"] .sub-until { color: #9fb0cc; }

/* ---- the days-left bar burns down like a sparkler ----
   The fill is the time that is left, so its far end is where the day is
   burning: a white-hot tip there, and sparks thrown off it by the script
   below. The bar may not clip, or the sparks would be cut off. */
.sub-bar-fuse { overflow: visible; position: relative; }
.sub-bar-fuse span { position: relative; }
.sub-bar-fuse span::after {
	content: "";
	position: absolute;
	inset-block: 0;
	inset-inline-end: 0;
	width: 34px;
	max-width: 100%;
	border-radius: inherit;
	background: linear-gradient(to var(--fuse-end, left), transparent, rgba(255, 214, 120, .9));
	pointer-events: none;
}
.sub-fuse {
	position: absolute;
	top: 50%;
	inset-inline-end: -6px;
	width: 12px;
	height: 12px;
	margin-top: -6px;
	border-radius: 50%;
	background: radial-gradient(circle, #ffffff 0%, #fff4c4 30%, #ffc44d 58%, rgba(255, 140, 40, 0) 72%);
	box-shadow: 0 0 6px 2px rgba(255, 210, 110, .9), 0 0 16px 5px rgba(255, 140, 40, .45);
	animation: subFuseFlicker .11s ease-in-out infinite alternate;
	z-index: 2;
}
.sub-spark {
	position: absolute;
	top: 50%;
	left: 50%;
	width: 3.5px;
	height: 3.5px;
	margin: -1.75px 0 0 -1.75px;
	border-radius: 50%;
	background: var(--c, #ffd36b);
	box-shadow: 0 0 4px 1px var(--c, #ffd36b);
	pointer-events: none;
	animation: subSpark var(--t, .7s) cubic-bezier(.15, .6, .35, 1) forwards;
}
/* some sparks are streaks: a short tail pointing back at the tip */
.sub-spark.is-streak {
	width: 11px;
	height: 1.8px;
	margin: -.9px 0 0 -5.5px;
	border-radius: 2px;
	background: linear-gradient(90deg, rgba(255, 255, 255, 0), var(--c, #ffd36b));
	transform-origin: center;
}
@keyframes subFuseFlicker {
	from { transform: scale(.82); opacity: .85; }
	to   { transform: scale(1.18); opacity: 1; }
}
@keyframes subSpark {
	0%   { transform: translate(0, 0) rotate(var(--r, 0deg)) scale(1); opacity: 1; }
	65%  { opacity: 1; }
	100% { transform: translate(var(--x, 10px), calc(var(--y, 0px) + var(--g, 10px))) rotate(var(--r, 0deg)) scale(.2); opacity: 0; }
}
html[data-hs-theme="dark"] .sub-fuse {
	box-shadow: 0 0 8px 3px rgba(255, 220, 130, 1), 0 0 22px 8px rgba(255, 150, 50, .6), 0 0 40px 12px rgba(255, 90, 40, .25);
}
@media (prefers-reduced-motion: reduce) {
	.sub-fuse { animation: none; }
}

/* ---- night theme: halogen colour inside the existing bar tracks only ---- */
html[data-hs-theme="dark"] .sub-tile-bar span {
	background: linear-gradient(90deg, #4796e3, #9177c7, #ca6673);
}

@media (max-width: 400px) {
	.sub-tiles { grid-template-columns: 1fr; }
	.sub-btn { flex: 1 1 100%; }
}

/* ---- the Telegram row ---- */
.sub-tg {
	display: flex;
	align-items: center;
	justify-content: space-between;
	flex-wrap: wrap;
	gap: 11px;
	margin-top: 14px;
	padding: 12px 14px;
	border-radius: 15px;
	border: 1.5px solid rgba(59, 130, 246, .28);
	background: linear-gradient(135deg, rgba(59, 130, 246, .08), rgba(14, 165, 233, .08));
}
.sub-tg-off {
	border-color: rgba(244, 63, 94, .3);
	background: linear-gradient(135deg, rgba(244, 63, 94, .07), rgba(251, 113, 133, .07));
}
.sub-tg-left { display: flex; align-items: center; gap: 10px; min-width: 0; }
.sub-tg-emoji i { color: #229ed9; }
.sub-tg-btn i { font-size: 15px; }
.sub-tg-emoji {
	flex: 0 0 auto;
	width: 36px;
	height: 36px;
	border-radius: 12px;
	background: rgba(59, 130, 246, .16);
	display: inline-flex;
	align-items: center;
	justify-content: center;
	font-size: 18px;
}
.sub-tg-off .sub-tg-emoji { background: rgba(244, 63, 94, .14); }
.sub-tg-title {
	font-size: 13px;
	font-weight: 800;
	color: #16203d;
	line-height: 1.6;
}
.sub-tg-state {
	display: flex;
	align-items: center;
	gap: 6px;
	font-size: 11.5px;
	font-weight: 700;
	color: #1d4ed8;
	flex-wrap: wrap;
}
.sub-tg-off .sub-tg-state { color: #be123c; }
.sub-tg-state b { direction: ltr; unicode-bidi: isolate; }
.sub-tg-gift {
	display: inline-flex;
	align-items: center;
	gap: 6px;
	margin-top: 5px;
	padding: 3px 10px;
	border-radius: 999px;
	font-size: 11.5px;
	font-weight: 700;
	color: #fff;
	background: linear-gradient(135deg, #fb923c, #ec4899);
	box-shadow: 0 4px 12px -4px rgba(236, 72, 153, .6);
}
.sub-tg-dot {
	width: 8px;
	height: 8px;
	border-radius: 50%;
	background: #22c55e;
	flex: 0 0 auto;
	box-shadow: 0 0 0 3px rgba(34, 197, 94, .22);
}
.sub-tg-off .sub-tg-dot {
	background: #ef4444;
	box-shadow: 0 0 0 3px rgba(239, 68, 68, .2);
	animation: subTgBlink 1.9s ease-in-out infinite;
}
@keyframes subTgBlink {
	0%, 100% { opacity: 1; }
	50%      { opacity: .35; }
}
.sub-tg-btn {
	flex: 0 0 auto;
	display: inline-flex;
	align-items: center;
	gap: 6px;
	padding: 9px 15px;
	border-radius: 12px;
	font-size: 12.5px;
	font-weight: 800;
	text-decoration: none;
	color: #fff !important;
	background: linear-gradient(135deg, #2563eb, #0ea5e9);
	box-shadow: 0 5px 14px rgba(37, 99, 235, .32);
	transition: transform .14s ease, box-shadow .14s ease;
}
.sub-tg-btn:hover { transform: translateY(-1px); box-shadow: 0 8px 20px rgba(37, 99, 235, .42); }
.sub-tg-btn-manage {
	color: #1d4ed8 !important;
	background: rgba(59, 130, 246, .14);
	box-shadow: none;
}
.sub-tg-btn-manage:hover { background: rgba(59, 130, 246, .22); box-shadow: none; }

html[data-hs-theme="dark"] .sub-tg-title { color: #e7eaf3; }
html[data-hs-theme="dark"] .sub-tg-state { color: #93c5fd; }
html[data-hs-theme="dark"] .sub-tg-off .sub-tg-state { color: #fda4af; }
html[data-hs-theme="dark"] .sub-tg-btn-manage { color: #bfdbfe !important; background: rgba(59, 130, 246, .2); }

@media (max-width: 420px) {
	.sub-tg { padding: 11px 12px; }
	.sub-tg-btn { width: 100%; justify-content: center; }
}
</style>
{/literal}

{$health = $user->planHealth()}
{if $health == 'good'}
	{$palette = "--sub-a:#10b981;--sub-b:#34d399;--sub-soft:rgba(16,185,129,.14);--sub-ink:#047857"}
	{$moodEmoji = "✨"}
	{$moodText = $translate->get('MoodGood')}
{elseif $health == 'warn'}
	{$palette = "--sub-a:#f59e0b;--sub-b:#fbbf24;--sub-soft:rgba(245,158,11,.16);--sub-ink:#b45309"}
	{$moodEmoji = "⏰"}
	{$moodText = $translate->get('MoodWarn')}
{elseif $health == 'critical'}
	{$palette = "--sub-a:#f43f5e;--sub-b:#fb7185;--sub-soft:rgba(244,63,94,.15);--sub-ink:#be123c"}
	{$moodEmoji = "🔥"}
	{$moodText = $translate->get('MoodCritical')}
{else}
	{$palette = "--sub-a:#94a3b8;--sub-b:#cbd5e1;--sub-soft:rgba(148,163,184,.2);--sub-ink:#475569"}
	{$moodEmoji = "💤"}
	{$moodText = $translate->get('MoodExpired')}
{/if}

<div class="col-lg-12 col-xl-4 col-md-12 col-sm-12 mb-3">

	<div class="card card-shadow shadow-lg rounded mb-3 sub-card" style="{$palette}">
		<div class="card-header card-header-content-between border-bottom">
			<h4 class="card-header-title mb-0"><i class="fa-duotone fa-cart-shopping"></i> {$translate->get('Subscription')}</h4>
			<button type="button" class="sub-gift" onClick="RedeemCard()" data-bs-toggle="tooltip" data-bs-placement="bottom" title="{$translate->get('RedeemCardHint')}">
				🎁 <span>{$translate->get('RedeemCard')}</span>
			</button>
		</div>

		<div class="card-body">

			<span class="sub-status">
				<span class="sub-dot"></span>
				{if $user->planNeverExpires()}{$translate->get('PlanDontExpire')}
				{elseif $user->planIsActive()}{$translate->get('PlanActive')}
				{else}{$translate->get('PlanExpired')}{/if}
			</span>

			<h4 class="sub-name">{if $user->planIsActive() && $Order->getPackage($user->id)}{$Order->getPackage($user->id)->name}{else}{$translate->get('NoActivePlan')}{/if}</h4>

			{if $user->planIsActive()}
				<div class="sub-chips">
					<span class="sub-chip">⚡ {$helpers->PortSpd($user->speedlimit)}</span>
					<span class="sub-chip">🌍 {str_replace([' | '],[' '],$helpers->serveGroup($user->server_group))}</span>
					<span class="sub-chip">📶 {$user->enableTraffic()}</span>
				</div>
			{/if}

			{if $user->planIsActive() && !$user->planNeverExpires()}
				<div class="sub-clock">
					<div class="sub-clock-top">
						<span class="sub-days"><b>{$user->daysLeft()}</b> {$translate->get('DaysLeft')}</span>
						<span class="sub-until">{$translate->get('Until')} <time>{date("Y-m-d H:i",strtotime($user->expire_in))}</time></span>
					</div>
					<div class="sub-bar sub-bar-fuse"><span style="width:{$user->planTimePercent()}%"><i class="sub-fuse" aria-hidden="true"></i></span></div>
					<div class="sub-mood"><span>{$moodEmoji}</span> {$moodText}</div>
				</div>
			{elseif $user->planNeverExpires()}
				<div class="sub-clock">
					<div class="sub-days">♾️ {$translate->get('PlanDontExpire')}</div>
					<div class="sub-mood"><span>{$moodEmoji}</span> {$moodText}</div>
				</div>
			{else}
				<div class="sub-clock">
					<div class="sub-days">{$translate->get('NoPlanNote')}</div>
					<div class="sub-mood"><span>{$moodEmoji}</span> {$moodText}</div>
				</div>
			{/if}

			<div class="sub-actions">
				{* topupCount() already drops the ones this plan is not offered on *}
				{if $timeplan->topupCount() > 0 && $Order->getSubsciption($user->id) && $user->planIsActive()}
					<button type="button" class="sub-btn sub-btn-data" onClick="TopupOptions()">📶 {$translate->get('AddData')}</button>
				{/if}
				{* buying days only makes sense near the end of the subscription *}
				{if $Order->getSubsciption($user->id) && $user->timePlanVisible() && $timeplan->timePlanCount($user) > 0}
					<button type="button" class="sub-btn sub-btn-time" onClick="TimeOptions()">⏳ {$translate->get('AddTime')}</button>
				{/if}
				{if $Order->getSubsciption($user->id) != null && $bought > 0 && $Order->getPackage($user->id) && $Order->getPackage($user->id)->renew_type > 0}
					<button type="button" class="sub-btn sub-btn-main renew">🔄 {$translate->get('RenewPlan')}</button>
				{/if}
				{if !$user->planIsActive()}
					<a href="/portal/plans" class="sub-btn sub-btn-buy">🛒 {$translate->get('OrderApaln')}</a>
				{/if}
			</div>

			{if isset($Config['telegram']) && $Config['telegram'] == 1
				&& isset($Config['telegrambind']) && $Config['telegrambind'] == 1
				&& isset($Config['telegrambot']) && $Config['telegrambot'] != ""}
				<div class="sub-tg {if $user->telegram_id > 0}sub-tg-on{else}sub-tg-off{/if}">
					<div class="sub-tg-left">
						<span class="sub-tg-emoji"><i class="fa-brands fa-telegram"></i></span>
						<div>
							<div class="sub-tg-title">{$translate->get('TelegramNotify')}</div>
							<div class="sub-tg-state">
								<i class="sub-tg-dot"></i>
								{if $user->telegram_id > 0}
									{$translate->get('TelegramLinked')}{if $user->telegram_name != ""} &middot; <b>@{$user->telegram_name|escape:'html'}</b>{/if}
								{else}
									{$translate->get('TelegramNotLinked')}
								{/if}
							</div>
							{if $user->telegram_id <= 0 && $user->tgBindGiftOpen()}
								<div class="sub-tg-gift"><i class="fa-solid fa-gift"></i> {$translate->get('TgBindGift')}</div>
							{/if}
						</div>
					</div>
					{if $user->telegram_id > 0}
						<a class="sub-tg-btn sub-tg-btn-manage" href="/portal/settings#telegramSection">⚙️ {$translate->get('TelegramManage')}</a>
					{else}
						<a class="sub-tg-btn" href="https://telegram.me/{$Config['telegrambot']|escape:'url'}?start={$user->tg_token|escape:'url'}" target="_blank" rel="noopener"><i class="fa-brands fa-telegram"></i> {$translate->get('TelegramConnect')}</a>
					{/if}
				</div>
			{/if}

			{include file='user/dashboard/tgjoin.tpl'}

		</div>
	</div>

	<div class="sub-tiles mb-2">
		<div class="sub-tile" style="--tile:#8b5cf6">
			<div class="sub-tile-head"><span class="sub-tile-emoji">💰</span>{$translate->get('Money')}</div>
			<div class="sub-tile-value"><span id="money">{$currency->symbol_left} {number_format((float)$user->money, (int){$currency->decimals})} {$currency->symbol_right}</span></div>
			<div class="sub-tile-note sub-tile-note-money">
				{if $user->commissionCredited() > 0}
					🤝 {$translate->get('FromCommission')}: {number_format((float)$user->commissionCredited(), (int){$currency->decimals})}
					{if $user->walletTopUp() > 0}<br>💳 {$translate->get('FromTopUp')}: {number_format((float)$user->walletTopUp(), (int){$currency->decimals})}{/if}
				{else}
					💳 {$translate->get('FromTopUp')}
				{/if}
			</div>
		</div>

		<div class="sub-tile" style="--tile:#06b6d4">
			<div class="sub-tile-head"><span class="sub-tile-emoji">📱</span>{$translate->get('OnlineIp')}</div>
			<div class="sub-tile-value">{$user->online_ip_count()} / {$user->iplimit}</div>
			<div class="sub-tile-bar">
				<span style="width:{$user->ipPercent()}%"></span>
			</div>
			<div class="sub-tile-note">{$translate->get('DevicesConnected')}</div>
		</div>
	</div>

</div>

{literal}
<script>
/* Sparks for the days-left bar. Each one is a tiny element thrown off the
   tip with its own angle, speed and colour, pulled down a little as if by
   gravity, and removed when its animation ends - so there are never more
   than a couple of dozen on the page. Stops while the tab is hidden and does
   nothing for people who asked for reduced motion. */
(function () {
	var fuse = document.querySelector('.sub-fuse');
	if (!fuse) { return; }
	if (window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches) { return; }

	var colors = ['#ffffff', '#fff4c4', '#ffe08a', '#ffc44d', '#ff9f3d', '#ffd36b'];
	var bar = fuse.closest('.sub-bar');
	// the empty side of the bar: sparks mostly fly that way
	var away = getComputedStyle(bar).direction === 'rtl' ? -1 : 1;
	// the hot glow on the fill leans toward the tip, whichever side that is
	bar.style.setProperty('--fuse-end', away < 0 ? 'left' : 'right');

	function spark() {
		var el = document.createElement('b');
		var streak = Math.random() < 0.45;
		// an arc centred on the empty side, wide enough to spray up and down
		var angle = (away > 0 ? 0 : Math.PI) + (Math.random() - 0.5) * Math.PI * 1.5;
		var dist = 14 + Math.random() * 34;
		var x = Math.cos(angle) * dist;
		var y = Math.sin(angle) * dist - 4;

		el.className = 'sub-spark' + (streak ? ' is-streak' : '');
		el.style.setProperty('--x', x.toFixed(1) + 'px');
		el.style.setProperty('--y', y.toFixed(1) + 'px');
		el.style.setProperty('--g', (6 + Math.random() * 10).toFixed(1) + 'px');
		el.style.setProperty('--r', (angle * 180 / Math.PI).toFixed(0) + 'deg');
		el.style.setProperty('--t', (0.45 + Math.random() * 0.5).toFixed(2) + 's');
		el.style.setProperty('--c', colors[Math.floor(Math.random() * colors.length)]);
		el.addEventListener('animationend', function () { el.remove(); });
		fuse.appendChild(el);
	}

	setInterval(function () {
		if (document.hidden) { return; }
		var n = 2 + Math.floor(Math.random() * 3);
		for (var i = 0; i < n; i++) { spark(); }
	}, 70);
})();
</script>
{/literal}
