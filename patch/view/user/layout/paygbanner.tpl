{*
 * Slim banner at the top of every customer page that tells people about the
 * charge wallet: when the plan runs out the connection is not cut, the balance
 * pays per GB. Included by usermenu.tpl, right where the page content starts.
 *
 * Shown while the wallet is on (payg_enabled) and the admin has not switched
 * the banner off (payg_banner = 0; a missing key counts as on). The wording
 * follows the wallet mode, and the close button only hides it for three days
 * in this browser - per mode, so a change of mode shows it again. The button
 * opens the wallet side panel (user/dashboard/wallet.tpl): straight away on
 * the dashboard through [data-wallet-open], by the #wallet-charge hash from
 * any other page.
 *}
{if isset($Config['payg_enabled']) && $Config['payg_enabled'] == 1 && (!isset($Config['payg_banner']) || $Config['payg_banner'] != '0')}
{$pgbMode = $user->paygMode()}
{if $pgbMode == 'plan' && $user->paygBalance() > 0}{$pgbMode = 'balance'}{/if}
{if $user->paygToman()}{$pgbUnit = $translate->get('PaygToman')}{else}{$pgbUnit = $translate->get('PaygRial')}{/if}
<div class="pgb pgb-{$pgbMode}" id="pgBanner" data-mode="{$pgbMode}" role="note" hidden>
	<span class="pgb-icon" aria-hidden="true">{if $pgbMode == 'empty'}⚠️{else}💳{/if}</span>
	<div class="pgb-body">
		{if $pgbMode == 'balance'}
			{$pgbGb = $user->paygHeadroomGb()}
			<strong>{$translate->get('PaygBannerBalanceTitle')}</strong>
			<span class="pgb-text">{if $pgbGb !== null}{$translate->get('PaygBannerBalanceText')|replace:'%balance%':$user->paygBalanceShown()|replace:'%unit%':$pgbUnit|replace:'%gb%':$pgbGb}{else}{$translate->get('PaygBannerBalanceFree')|replace:'%balance%':$user->paygBalanceShown()|replace:'%unit%':$pgbUnit}{/if}</span>
		{elseif $pgbMode == 'empty'}
			<strong>{$translate->get('PaygBannerEmptyTitle')}</strong>
			<span class="pgb-text">{$translate->get('PaygBannerEmptyText')}</span>
		{else}
			<strong>{$translate->get('PaygBannerPlanTitle')}</strong>
			<span class="pgb-text">{$translate->get('PaygBannerPlanText')}</span>
		{/if}
	</div>
	<div class="pgb-actions">
		<a class="pgb-btn" href="/portal/dashboard#wallet-charge" data-wallet-open="charge">{if $pgbMode == 'balance'}{$translate->get('PaygBannerChargeMore')}{else}{$translate->get('PaygBannerCharge')}{/if}</a>
		<a class="pgb-link" href="/portal/dashboard#wallet-prices" data-wallet-open="prices">{$translate->get('PaygBannerHow')}</a>
	</div>
	<button type="button" class="pgb-close" id="pgbClose" aria-label="{$translate->get('PaygBannerClose')|escape}" title="{$translate->get('PaygBannerClose')|escape}">×</button>
</div>
<style>
.pgb {
	position: relative;
	display: flex;
	align-items: center;
	gap: .85rem;
	margin-block-end: 1.1rem;
	padding: .7rem 1rem;
	border: 1px solid rgba(34, 197, 94, .35);
	border-radius: .85rem;
	background: linear-gradient(100deg, rgba(34, 197, 94, .14), rgba(16, 185, 129, .06));
	color: inherit;
	line-height: 1.7;
}
.pgb[hidden] { display: none; }
.pgb-balance {
	border-color: rgba(245, 158, 11, .4);
	background: linear-gradient(100deg, rgba(245, 158, 11, .15), rgba(250, 204, 21, .06));
}
.pgb-empty {
	border-color: rgba(244, 63, 94, .45);
	background: linear-gradient(100deg, rgba(244, 63, 94, .16), rgba(251, 146, 60, .06));
}
.pgb-icon { flex: none; font-size: 1.5rem; line-height: 1; }
.pgb-body { flex: 1 1 auto; min-width: 0; }
.pgb-body strong { margin-inline-end: .4rem; }
.pgb-text { opacity: .85; }
.pgb-actions { flex: none; display: flex; align-items: center; gap: .9rem; }
.pgb-btn {
	display: inline-block;
	padding: .35rem .95rem;
	border-radius: 2rem;
	background: #16a34a;
	color: #fff !important;
	font-weight: 700;
	white-space: nowrap;
	text-decoration: none;
	box-shadow: 0 2px 8px rgba(22, 163, 74, .35);
}
.pgb-balance .pgb-btn { background: #d97706; box-shadow: 0 2px 8px rgba(217, 119, 6, .35); }
.pgb-empty .pgb-btn { background: #e11d48; box-shadow: 0 2px 8px rgba(225, 29, 72, .35); }
.pgb-btn:hover { filter: brightness(1.08); }
.pgb-link { color: inherit !important; font-size: .85em; white-space: nowrap; text-decoration: underline; opacity: .8; }
.pgb-close {
	flex: none;
	width: 1.9rem;
	height: 1.9rem;
	padding: 0;
	border: 0;
	border-radius: 50%;
	background: transparent;
	color: inherit;
	font-size: 1.4rem;
	line-height: 1;
	opacity: .55;
	cursor: pointer;
}
.pgb-close:hover { opacity: 1; background: rgba(127, 127, 127, .18); }
html[data-hs-theme="dark"] .pgb { background: linear-gradient(100deg, rgba(34, 197, 94, .2), rgba(16, 185, 129, .07)); }
html[data-hs-theme="dark"] .pgb-balance { background: linear-gradient(100deg, rgba(245, 158, 11, .22), rgba(250, 204, 21, .07)); }
html[data-hs-theme="dark"] .pgb-empty { background: linear-gradient(100deg, rgba(244, 63, 94, .24), rgba(251, 146, 60, .08)); }
@media (max-width: 767px) {
	.pgb { flex-wrap: wrap; padding: .7rem .8rem; gap: .5rem .7rem; }
	.pgb-body { flex-basis: calc(100% - 4.5rem); padding-inline-end: 1.6rem; }
	.pgb-actions { flex-basis: 100%; justify-content: space-between; }
	.pgb-close { position: absolute; top: .3rem; inset-inline-end: .3rem; }
}
</style>
<script>
(function () {
	var box = document.getElementById('pgBanner');
	if (!box) { return; }
	var key = 'pgBannerHide-' + box.getAttribute('data-mode');
	var hold = 3 * 24 * 3600 * 1000;
	var hiddenUntil = 0;
	try { hiddenUntil = Number(window.localStorage.getItem(key)) || 0; } catch (e) {}
	if (Date.now() >= hiddenUntil) { box.hidden = false; }
	document.getElementById('pgbClose').addEventListener('click', function () {
		box.hidden = true;
		try { window.localStorage.setItem(key, String(Date.now() + hold)); } catch (e) {}
	});
})();
</script>
{/if}
