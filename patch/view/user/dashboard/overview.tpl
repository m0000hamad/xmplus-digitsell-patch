{literal}
<style>
.dash-overview { margin-bottom: 14px; }
.dash-overview-grid { display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); gap: 10px; }
.dash-overview-item {
	position: relative; min-width: 0; padding: 15px 16px; overflow: hidden;
	border: 1px solid rgba(23, 32, 61, .08); border-radius: 16px; background: #fff;
	box-shadow: 0 8px 24px rgba(23, 32, 61, .055);
}
.dash-overview-item::after { content: ""; position: absolute; inset-inline: 0; bottom: 0; height: 3px; background: var(--overview, #6366f1); }
.dash-overview-head { display: flex; align-items: center; gap: 8px; margin-bottom: 8px; font-size: 11.5px; font-weight: 700; color: #7a869f; }
.dash-overview-icon { display: inline-flex; align-items: center; justify-content: center; width: 30px; height: 30px; border-radius: 10px; color: var(--overview, #6366f1); background: rgba(99, 102, 241, .1); }
.dash-overview-value { font-size: 20px; font-weight: 900; line-height: 1.35; color: #16203d; direction: ltr; unicode-bidi: isolate; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.dash-more { border: 1px solid rgba(23, 32, 61, .08); border-radius: 16px; background: rgba(255, 255, 255, .72); overflow: hidden; }
.dash-more > summary { display: flex; align-items: center; justify-content: center; gap: 9px; padding: 13px 16px; font-size: 12.5px; font-weight: 800; color: #4f46e5; cursor: pointer; list-style: none; }
.dash-more > summary::-webkit-details-marker { display: none; }
.dash-more > summary i { transition: transform .18s ease; }
.dash-more[open] > summary i { transform: rotate(180deg); }
.dash-more-body { padding: 0 12px 12px; }
.dash-more-body > [class*="col-"] { width: 100%; max-width: 100%; margin-bottom: 0 !important; }
html[data-hs-theme="dark"] .dash-overview-item, html[data-hs-theme="dark"] .dash-more { background: rgba(255, 255, 255, .04); border-color: rgba(255, 255, 255, .09); }
html[data-hs-theme="dark"] .dash-overview-value { color: #e7eaf3; }
html[data-hs-theme="dark"] .dash-overview-head { color: #aab6cc; }
html[data-hs-theme="dark"] .dash-more > summary { color: #c7d2fe; }
@media (max-width: 991.98px) { .dash-overview-grid { grid-template-columns: repeat(2, minmax(0, 1fr)); } }
@media (max-width: 479.98px) {
	.dash-overview-grid { gap: 8px; }
	.dash-overview-item { padding: 12px; border-radius: 14px; }
	.dash-overview-value { font-size: 16px; }
	.dash-overview-head { font-size: 10.5px; gap: 6px; }
	.dash-overview-icon { width: 26px; height: 26px; border-radius: 8px; }
}
</style>
{/literal}
<section class="dash-overview" aria-label="{$translate->get('Statistics')}">
	<div class="dash-overview-grid">
		<div class="dash-overview-item" style="--overview:#6366f1"><div class="dash-overview-head"><span class="dash-overview-icon">📶</span>{$translate->get('DashRemainingTraffic')}</div><div class="dash-overview-value">{$user->unusedTraffic()}</div></div>
		<div class="dash-overview-item" style="--overview:#8b5cf6"><div class="dash-overview-head"><span class="dash-overview-icon">📅</span>{$translate->get('DashRemainingDays')}</div><div class="dash-overview-value">{if $user->planNeverExpires()}∞{else}{$user->daysLeft()} {$translate->get('DashDayUnit')}{/if}</div></div>
		<div class="dash-overview-item" style="--overview:#06b6d4"><div class="dash-overview-head"><span class="dash-overview-icon">〽️</span>{$translate->get('TodayData')}</div><div class="dash-overview-value">{$user->TodayTraffic()}</div></div>
		<div class="dash-overview-item" style="--overview:#10b981"><div class="dash-overview-head"><span class="dash-overview-icon">💳</span>{$translate->get('DashWalletBalance')}</div><div class="dash-overview-value">{if $user->paygEnabled()}{$user->paygBalanceShown()} {if $user->paygToman()}{$translate->get('PaygToman')}{else}{$translate->get('PaygRial')}{/if}{else}{number_format((float)$user->money, (int){$currency->decimals})} {$translate->get('PaygRial')}{/if}</div></div>
	</div>
</section>
