{literal}
<style>
.dash-primary > [class*="col-"] { display: flex; flex-direction: column; }
.dash-primary .sub-card, .dash-primary .usage-card { flex: 1 1 auto; }
.online-compact-wrap { display: flex; margin: 0 0 14px; }
.online-compact {
	display: inline-flex;
	align-items: center;
	gap: 12px;
	width: max-content;
	max-width: 100%;
	min-height: 54px;
	padding: 10px 14px;
	border: 1px solid rgba(6, 182, 212, .22);
	border-radius: 15px;
	background: #fff;
	box-shadow: 0 7px 20px rgba(23, 32, 61, .05);
}
.online-compact-title { display: flex; align-items: center; gap: 7px; font-size: 11.5px; font-weight: 800; color: #52627e; white-space: nowrap; }
.online-compact-count { font-size: 16px; font-weight: 900; color: #16203d; direction: ltr; unicode-bidi: isolate; white-space: nowrap; }
.online-compact-people { display: flex; align-items: center; flex-wrap: wrap; gap: 4px; max-width: 420px; }
.online-compact-person { position: relative; display: inline-block; width: 16px; height: 20px; filter: drop-shadow(0 3px 4px rgba(6, 182, 212, .24)); }
.online-compact-person::before { content: ""; position: absolute; top: 1px; inset-inline-start: 5px; width: 7px; height: 7px; border-radius: 50%; background: linear-gradient(135deg, #06b6d4, #2563eb); }
.online-compact-person::after { content: ""; position: absolute; bottom: 1px; inset-inline-start: 1px; width: 14px; height: 9px; border-radius: 9px 9px 4px 4px; background: linear-gradient(135deg, #06b6d4, #2563eb); }
.online-compact-empty { font-size: 11px; color: #97a4af; white-space: nowrap; }
html[data-hs-theme="dark"] .online-compact { background: rgba(255, 255, 255, .04); border-color: rgba(34, 211, 238, .2); }
html[data-hs-theme="dark"] .online-compact-title { color: #aab6cc; }
html[data-hs-theme="dark"] .online-compact-count { color: #e7eaf3; }
.usage-card .online-compact-wrap { margin: 8px 0 4px; padding-top: 10px; border-top: 1px dashed rgba(23, 32, 61, .09); }
.usage-card .online-compact { min-height: 42px; padding: 7px 10px; border-radius: 12px; box-shadow: none; background: rgba(6, 182, 212, .045); }
html[data-hs-theme="dark"] .usage-card .online-compact-wrap { border-top-color: rgba(255, 255, 255, .09); }
.dash-more { border: 1px solid rgba(23, 32, 61, .08); border-radius: 16px; background: rgba(255, 255, 255, .72); overflow: hidden; }
.dash-more > summary { display: flex; align-items: center; justify-content: center; gap: 9px; padding: 13px 16px; font-size: 12.5px; font-weight: 800; color: #4f46e5; cursor: pointer; list-style: none; }
.dash-more > summary::-webkit-details-marker { display: none; }
.dash-more > summary i { transition: transform .18s ease; }
.dash-more[open] > summary i { transform: rotate(180deg); }
.dash-more-body { padding: 0 12px 12px; }
.dash-more-body > [class*="col-"] { width: 100%; max-width: 100%; margin-bottom: 0 !important; }
html[data-hs-theme="dark"] .dash-more { background: rgba(255, 255, 255, .04); border-color: rgba(255, 255, 255, .09); }
html[data-hs-theme="dark"] .dash-more > summary { color: #c7d2fe; }
@media (max-width: 575.98px) {
	.online-compact { gap: 9px; padding: 9px 12px; }
	.online-compact-people { max-width: 220px; }
}
</style>
{/literal}
{$onlinePeople = $user->online_ip_count()}
<div class="online-compact-wrap">
	<div class="online-compact">
		<div class="online-compact-title"><span>👥</span>{$translate->get('OnlinePeople')}</div>
		<div class="online-compact-count">{$onlinePeople} / {$user->iplimit}</div>
		<div class="online-compact-people" aria-label="{$translate->get('OnlinePeople')}: {$onlinePeople}">
			{section name=onlinePerson loop=$onlinePeople}<span class="online-compact-person" aria-hidden="true"></span>{sectionelse}<span class="online-compact-empty">{$translate->get('NobodyOnline')}</span>{/section}
		</div>
	</div>
</div>
