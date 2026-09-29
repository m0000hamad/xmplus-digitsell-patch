{*
 * The wallet side panel - the "my wallet" screen of an operator app.
 *
 * Nothing here sits in the page flow: the panel slides in from the side (from
 * the bottom on a phone) when something with [data-wallet-open] is pressed -
 * the wallet tile and the buttons in the subscription card - or when the page
 * is opened as /portal/dashboard#wallet, which is where the menu item points.
 * New messages from the billing job show as a short toast at the top.
 *
 * Data: /xmplus-patch.php?do=payg.me (app/Patch/Payg.php). A top-up is sold by
 * the panel's own checkout: payg.mint turns the amount into a topup package and
 * /portal/order/create sells it like "add data"; app/Jobs/PaygJob.php credits it.
 *
 * Included once, at the bottom of dashboard.tpl.
 *}
{if $user->paygEnabled()}
<script>
	/* new Object(), not a brace literal: Smarty would read the brace as a tag */
	window.PaygWords = new Object();
	window.PaygWords.wallet       = "{$translate->get('PaygWallet')|escape:'javascript'}";
	window.PaygWords.modePlan     = "{$translate->get('PaygModePlan')|escape:'javascript'}";
	window.PaygWords.modeBalance  = "{$translate->get('PaygModeBalance')|escape:'javascript'}";
	window.PaygWords.modeEmpty    = "{$translate->get('PaygModeEmpty')|escape:'javascript'}";
	window.PaygWords.headroom     = "{$translate->get('PaygHeadroom')|escape:'javascript'}";
	window.PaygWords.unlimited    = "{$translate->get('PaygUnlimited')|escape:'javascript'}";
	window.PaygWords.toman        = "{$translate->get('PaygToman')|escape:'javascript'}";
	window.PaygWords.rial         = "{$translate->get('PaygRial')|escape:'javascript'}";
	window.PaygWords.gb           = "{$translate->get('PaygGb')|escape:'javascript'}";
	window.PaygWords.mb           = "{$translate->get('PaygMb')|escape:'javascript'}";
	window.PaygWords.free         = "{$translate->get('PaygFree')|escape:'javascript'}";
	window.PaygWords.down         = "{$translate->get('PaygServerDown')|escape:'javascript'}";
	window.PaygWords.perGb        = "{$translate->get('PaygPerGb')|escape:'javascript'}";
	window.PaygWords.kindCharge   = "{$translate->get('PaygKindCharge')|escape:'javascript'}";
	window.PaygWords.kindBonus    = "{$translate->get('PaygKindBonus')|escape:'javascript'}";
	window.PaygWords.kindUsage    = "{$translate->get('PaygKindUsage')|escape:'javascript'}";
	window.PaygWords.kindAdjust   = "{$translate->get('PaygKindAdjust')|escape:'javascript'}";
	window.PaygWords.noHistory    = "{$translate->get('PaygNoHistory')|escape:'javascript'}";
	window.PaygWords.minNote      = "{$translate->get('PaygMinNote')|escape:'javascript'}";
	window.PaygWords.tooLow       = "{$translate->get('PaygTooLow')|escape:'javascript'}";
	window.PaygWords.enterAmount  = "{$translate->get('PaygEnterAmount')|escape:'javascript'}";
	window.PaygWords.bonusNote    = "{$translate->get('PaygBonusNote')|escape:'javascript'}";
	window.PaygWords.tierFrom     = "{$translate->get('PaygTierFrom')|escape:'javascript'}";
	window.PaygWords.payAmount    = "{$translate->get('PaygPayAmount')|escape:'javascript'}";
	window.PaygWords.autoOn       = "{$translate->get('PaygAutoOnSaved')|escape:'javascript'}";
	window.PaygWords.autoOff      = "{$translate->get('PaygAutoOffSaved')|escape:'javascript'}";
	window.PaygWords.freeNote     = "{$translate->get('PaygFreeTraffic')|escape:'javascript'}";
	window.PaygWords.pending      = "{$translate->get('PaygPending')|escape:'javascript'}";
	window.PaygWords.today        = "{$translate->get('PaygDayToday')|escape:'javascript'}";
	window.PaygWords.yesterday    = "{$translate->get('PaygDayYesterday')|escape:'javascript'}";
	window.PaygWords.failed       = "{$translate->get('PaygFailed')|escape:'javascript'}";
</script>

{literal}
<style>
/* ---- side panel ---- */
.wd-backdrop {
	position: fixed;
	inset: 0;
	z-index: 1070;
	background: rgba(15, 23, 42, .5);
	backdrop-filter: blur(3px);
	opacity: 0;
	transition: opacity .25s ease;
}
.wd-backdrop.is-open { opacity: 1; }
.wd {
	--wd-off: 105%;
	position: fixed;
	z-index: 1080;
	inset-block: 0;
	inset-inline-end: 0;
	width: min(440px, 100vw);
	display: flex;
	flex-direction: column;
	color: #1f2a44;
	background: #f6f7fb;
	box-shadow: 0 0 60px -12px rgba(15, 23, 42, .45);
	transform: translateX(var(--wd-off));
	transition: transform .3s cubic-bezier(.2, .8, .2, 1);
	outline: none;
}
html[dir="rtl"] .wd { --wd-off: -105%; }
.wd.is-open { transform: none; }
.wd[hidden], .wd-backdrop[hidden], .wd-toast[hidden] { display: none; }
html.wd-lock, html.wd-lock body { overflow: hidden; }

.wd-grip { display: none; }
.wd-head {
	display: flex;
	align-items: center;
	justify-content: space-between;
	gap: 10px;
	padding: 16px 18px 10px;
}
.wd-title { margin: 0; font-size: 16px; font-weight: 900; color: inherit; }
.wd-x {
	width: 34px;
	height: 34px;
	border: 0;
	border-radius: 11px;
	cursor: pointer;
	font-size: 15px;
	color: inherit;
	background: rgba(15, 23, 42, .06);
}
.wd-x:hover { background: rgba(15, 23, 42, .1); }

/* the balance, drawn like a bank card */
.wd-hero {
	position: relative;
	overflow: hidden;
	margin: 0 18px;
	padding: 16px 18px;
	border-radius: 20px;
	color: #fff;
	background:
		radial-gradient(90% 120% at 100% 0%, rgba(255, 255, 255, .22), transparent 55%),
		linear-gradient(135deg, #047857, #10b981 55%, #0ea5e9);
	box-shadow: 0 18px 34px -18px rgba(5, 150, 105, .9);
}
.wd-hero.is-balance { background: radial-gradient(90% 120% at 100% 0%, rgba(255, 255, 255, .22), transparent 55%), linear-gradient(135deg, #b45309, #f59e0b 60%, #f97316); box-shadow: 0 18px 34px -18px rgba(217, 119, 6, .9); }
.wd-hero.is-empty { background: radial-gradient(90% 120% at 100% 0%, rgba(255, 255, 255, .2), transparent 55%), linear-gradient(135deg, #9f1239, #e11d48 60%, #f43f5e); box-shadow: 0 18px 34px -18px rgba(225, 29, 72, .9); }
.wd-hero::after {
	content: "";
	position: absolute;
	width: 180px;
	height: 180px;
	inset-block-end: -90px;
	inset-inline-start: -50px;
	border-radius: 50%;
	border: 1px solid rgba(255, 255, 255, .25);
	pointer-events: none;
}
.wd-hero-top { display: flex; align-items: center; justify-content: space-between; gap: 8px; font-size: 12px; opacity: .92; }
.wd-mode { font-size: 11px; font-weight: 800; padding: 4px 10px; border-radius: 999px; background: rgba(255, 255, 255, .2); }
.wd-balance { font-size: 30px; font-weight: 900; line-height: 1.35; margin-top: 6px; }
.wd-balance small { font-size: 13px; font-weight: 700; opacity: .9; }
.wd-headroom { font-size: 12px; opacity: .92; }
.wd-pending {
	margin-top: 10px;
	font-size: 11.5px;
	font-weight: 700;
	padding: 6px 10px;
	border-radius: 10px;
	background: rgba(255, 255, 255, .18);
}

/* tabs: a segmented control */
.wd-tabs {
	display: grid;
	grid-template-columns: repeat(4, 1fr);
	gap: 4px;
	margin: 14px 18px 0;
	padding: 4px;
	border-radius: 14px;
	background: rgba(15, 23, 42, .06);
}
.wd-tab {
	border: 0;
	cursor: pointer;
	border-radius: 11px;
	padding: 8px 4px;
	font-size: 12px;
	font-weight: 700;
	color: #64748b;
	background: transparent;
	white-space: nowrap;
}
.wd-tab[aria-selected="true"] { color: #0f172a; background: #fff; box-shadow: 0 2px 8px -2px rgba(15, 23, 42, .2); }

.wd-body { flex: 1 1 auto; overflow-y: auto; padding: 14px 18px 18px; overscroll-behavior: contain; }
.wd-pane[hidden] { display: none; }
.wd-label { display: block; font-size: 12.5px; font-weight: 800; margin-bottom: 8px; }
.wd-field { position: relative; }
.wd-field input {
	width: 100%;
	font-size: 22px;
	font-weight: 900;
	text-align: center;
	direction: ltr;
	border-radius: 16px;
	padding: 14px 70px 14px 14px;
	color: inherit;
	background: #fff;
	border: 2px solid rgba(16, 185, 129, .35);
}
.wd-field input:focus { outline: none; border-color: #10b981; box-shadow: 0 0 0 4px rgba(16, 185, 129, .15); }
.wd-unit { position: absolute; inset-block-start: 50%; right: 16px; transform: translateY(-50%); font-size: 12px; font-weight: 700; color: #64748b; }
.wd-chips { display: grid; grid-template-columns: repeat(2, 1fr); gap: 8px; margin-top: 12px; }
.wd-chip {
	border: 1.5px solid rgba(15, 23, 42, .08);
	cursor: pointer;
	border-radius: 13px;
	padding: 10px 8px;
	font-size: 13px;
	font-weight: 800;
	color: inherit;
	background: #fff;
}
.wd-chip:hover, .wd-chip.is-on { border-color: #10b981; background: rgba(16, 185, 129, .08); }
.wd-bonus { font-size: 13px; font-weight: 800; color: #059669; margin-top: 12px; }
.wd-bonus:empty, .wd-note:empty { display: none; }
.wd-note { font-size: 12px; color: #64748b; margin-top: 6px; line-height: 1.9; }
.wd-box {
	margin-top: 14px;
	padding: 12px 14px;
	border-radius: 16px;
	background: #fff;
	border: 1px solid rgba(15, 23, 42, .06);
}
.wd-box-title { font-size: 12.5px; font-weight: 800; margin-bottom: 6px; }
.wd-tier { display: flex; justify-content: space-between; gap: 8px; font-size: 12px; padding: 6px 0; border-top: 1px dashed rgba(15, 23, 42, .1); }
.wd-tier:first-of-type { border-top: 0; }
.wd-tier b { color: #7c3aed; }

.wd-stats { display: grid; grid-template-columns: repeat(3, 1fr); gap: 8px; }
.wd-stat { padding: 10px; border-radius: 14px; background: #fff; border: 1px solid rgba(15, 23, 42, .06); }
.wd-stat-label { font-size: 11px; color: #64748b; }
.wd-stat-value { font-size: 13px; font-weight: 900; margin-top: 3px; }
.wd-day { font-size: 11.5px; font-weight: 800; color: #64748b; margin: 16px 2px 6px; }
.wd-item {
	display: flex;
	align-items: center;
	gap: 11px;
	padding: 10px 12px;
	border-radius: 14px;
	background: #fff;
	border: 1px solid rgba(15, 23, 42, .05);
	margin-bottom: 6px;
}
.wd-ico {
	flex: 0 0 38px;
	width: 38px;
	height: 38px;
	border-radius: 12px;
	display: flex;
	align-items: center;
	justify-content: center;
	font-size: 17px;
	background: rgba(15, 23, 42, .05);
}
.wd-item.is-charge .wd-ico { background: rgba(16, 185, 129, .12); }
.wd-item.is-bonus .wd-ico { background: rgba(139, 92, 246, .12); }
.wd-item.is-usage .wd-ico { background: rgba(244, 63, 94, .1); }
.wd-item-main { flex: 1 1 auto; min-width: 0; }
.wd-item-title { font-size: 13px; font-weight: 800; }
.wd-item-sub { font-size: 11.5px; color: #64748b; margin-top: 2px; }
.wd-amount { font-size: 13px; font-weight: 900; white-space: nowrap; }
.wd-amount bdi { unicode-bidi: isolate; direction: ltr; }
.wd-amount.is-free { color: #64748b; }
.wd-amount.is-plus { color: #059669; }
.wd-amount.is-minus { color: #e11d48; }
.wd-empty { text-align: center; color: #64748b; font-size: 12.5px; padding: 30px 10px; }

.wd-rate { display: flex; align-items: center; justify-content: space-between; gap: 10px; padding: 12px 14px; border-radius: 14px; background: #fff; border: 1px solid rgba(15, 23, 42, .05); margin-bottom: 6px; }
.wd-rate-name { font-size: 13px; font-weight: 800; }
.wd-rate-down { display: inline-block; font-size: 10.5px; font-weight: 800; color: #b45309; background: rgba(245, 158, 11, .14); padding: 2px 8px; border-radius: 999px; margin-inline-start: 6px; }
.wd-rate-price { font-size: 13px; font-weight: 900; color: #0f766e; white-space: nowrap; }

.wd-switch { display: flex; gap: 12px; align-items: flex-start; cursor: pointer; }
.wd-switch input { position: absolute; opacity: 0; pointer-events: none; }
.wd-knob { flex: 0 0 46px; height: 26px; border-radius: 999px; background: #cbd5e1; position: relative; transition: background .2s ease; margin-top: 2px; }
.wd-knob::after { content: ""; position: absolute; top: 3px; inset-inline-start: 3px; width: 20px; height: 20px; border-radius: 50%; background: #fff; box-shadow: 0 2px 5px rgba(0, 0, 0, .25); transition: inset-inline-start .2s ease; }
.wd-switch input:checked + .wd-knob { background: #10b981; }
.wd-switch input:checked + .wd-knob::after { inset-inline-start: 23px; }
.wd-switch input:focus-visible + .wd-knob { box-shadow: 0 0 0 4px rgba(16, 185, 129, .25); }
.wd-switch-title { font-size: 13px; font-weight: 800; }
.wd-switch-hint { font-size: 12px; color: #64748b; line-height: 1.9; margin-top: 2px; }

.wd-foot { padding: 12px 18px calc(12px + env(safe-area-inset-bottom)); background: #f6f7fb; border-top: 1px solid rgba(15, 23, 42, .06); }
.wd-foot[hidden] { display: none; }
.wd-pay {
	width: 100%;
	border: 0;
	cursor: pointer;
	border-radius: 16px;
	padding: 14px;
	font-size: 15px;
	font-weight: 900;
	color: #fff;
	background: linear-gradient(135deg, #059669, #10b981 60%, #0ea5e9);
	box-shadow: 0 14px 26px -14px rgba(5, 150, 105, .9);
}
.wd-pay:disabled { opacity: .6; cursor: wait; }

/* ---- toast for billing messages ---- */
.wd-toast {
	position: fixed;
	z-index: 1090;
	inset-block-start: 16px;
	inset-inline-start: 50%;
	transform: translateX(50%);
	width: min(440px, calc(100vw - 24px));
	display: flex;
	align-items: flex-start;
	gap: 10px;
	padding: 12px 14px;
	border-radius: 16px;
	color: #1f2a44;
	background: #fff;
	box-shadow: 0 20px 40px -16px rgba(15, 23, 42, .45), inset 0 0 0 1px rgba(15, 23, 42, .06);
	border-inline-start: 4px solid #3b82f6;
	animation: wd-drop .35s cubic-bezier(.2, .8, .2, 1);
}
html:not([dir="rtl"]) .wd-toast { transform: translateX(-50%); }
.wd-toast.is-empty, .wd-toast.is-low { border-color: #f43f5e; }
.wd-toast.is-started, .wd-toast.is-warn { border-color: #f59e0b; }
.wd-toast.is-charge, .wd-toast.is-resumed, .wd-toast.is-planback { border-color: #10b981; }
.wd-toast-text { flex: 1 1 auto; font-size: 12.5px; line-height: 1.9; white-space: pre-line; }
.wd-toast-open { border: 0; cursor: pointer; border-radius: 10px; padding: 7px 10px; font-size: 12px; font-weight: 800; color: #fff; background: #10b981; white-space: nowrap; }
.wd-toast-x { border: 0; cursor: pointer; background: transparent; color: #94a3b8; font-size: 14px; padding: 4px; }
@keyframes wd-drop { from { opacity: 0; margin-top: -20px; } to { opacity: 1; margin-top: 0; } }

/* ---- night ---- */
html[data-hs-theme="dark"] .wd { color: #e5e7eb; background: #111827; }
html[data-hs-theme="dark"] .wd-x { background: rgba(255, 255, 255, .08); }
html[data-hs-theme="dark"] .wd-tabs { background: rgba(255, 255, 255, .06); }
html[data-hs-theme="dark"] .wd-tab { color: #94a3b8; }
html[data-hs-theme="dark"] .wd-tab[aria-selected="true"] { color: #f8fafc; background: #1f2937; }
html[data-hs-theme="dark"] .wd-field input,
html[data-hs-theme="dark"] .wd-chip,
html[data-hs-theme="dark"] .wd-box,
html[data-hs-theme="dark"] .wd-stat,
html[data-hs-theme="dark"] .wd-item,
html[data-hs-theme="dark"] .wd-rate { background: #1a2335; border-color: rgba(255, 255, 255, .07); }
html[data-hs-theme="dark"] .wd-ico { background: rgba(255, 255, 255, .06); }
html[data-hs-theme="dark"] .wd-unit,
html[data-hs-theme="dark"] .wd-note,
html[data-hs-theme="dark"] .wd-stat-label,
html[data-hs-theme="dark"] .wd-day,
html[data-hs-theme="dark"] .wd-item-sub,
html[data-hs-theme="dark"] .wd-switch-hint,
html[data-hs-theme="dark"] .wd-empty { color: #94a3b8; }
html[data-hs-theme="dark"] .wd-foot { background: #111827; border-color: rgba(255, 255, 255, .07); }
html[data-hs-theme="dark"] .wd-toast { color: #e5e7eb; background: #1a2335; }
html[data-hs-theme="dark"] .wd-tier { border-color: rgba(255, 255, 255, .1); }
html[data-hs-theme="dark"] .wd-tier b { color: #c4b5fd; }
html[data-hs-theme="dark"] .wd-rate-price { color: #5eead4; }
html[data-hs-theme="dark"] .wd-bonus,
html[data-hs-theme="dark"] .wd-amount.is-plus { color: #34d399; }
html[data-hs-theme="dark"] .wd-amount.is-minus { color: #fb7185; }

/* ---- phone: a bottom sheet ---- */
@media (max-width: 575.98px) {
	.wd {
		--wd-off: 0;
		inset: auto 0 0 0;
		width: 100%;
		max-height: 92vh;
		border-radius: 24px 24px 0 0;
		transform: translateY(105%);
	}
	html[dir="rtl"] .wd { --wd-off: 0; }
	.wd.is-open { transform: none; }
	.wd-grip { display: block; width: 44px; height: 5px; border-radius: 999px; background: rgba(100, 116, 139, .4); margin: 10px auto 0; }
	.wd-head { padding-top: 8px; }
	.wd-balance { font-size: 26px; }
	.wd-tab { font-size: 11.5px; }
}
@media (prefers-reduced-motion: reduce) {
	.wd, .wd-backdrop { transition: none; }
	.wd-toast { animation: none; }
}
</style>
{/literal}

<div class="wd-backdrop" id="wdBackdrop" hidden></div>

<aside class="wd" id="walletDrawer" role="dialog" aria-modal="true" aria-labelledby="wdTitle" tabindex="-1" hidden>
	<div class="wd-grip" aria-hidden="true"></div>
	<div class="wd-head">
		<h3 class="wd-title" id="wdTitle">💳 {$translate->get('PaygWallet')}</h3>
		<button type="button" class="wd-x" data-wallet-close aria-label="{$translate->get('Close')}">✕</button>
	</div>

	<div class="wd-hero" id="wdHero">
		<div class="wd-hero-top">
			<span>{$translate->get('PaygBalance')}</span>
			<span class="wd-mode" id="wdMode"></span>
		</div>
		<div class="wd-balance" id="wdBalance">…</div>
		<div class="wd-headroom" id="wdHeadroom"></div>
		<div class="wd-pending" id="wdPending" hidden></div>
	</div>

	<div class="wd-tabs" role="tablist">
		<button type="button" class="wd-tab" role="tab" data-tab="charge" aria-selected="true">{$translate->get('PaygAddFunds')}</button>
		<button type="button" class="wd-tab" role="tab" data-tab="history" aria-selected="false">{$translate->get('PaygTabHistory')}</button>
		<button type="button" class="wd-tab" role="tab" data-tab="prices" aria-selected="false">{$translate->get('PaygTabPrices')}</button>
		<button type="button" class="wd-tab" role="tab" data-tab="settings" aria-selected="false">{$translate->get('PaygTabSettings')}</button>
	</div>

	<div class="wd-body">
		<section class="wd-pane" data-pane="charge" role="tabpanel">
			<label class="wd-label" for="wdAmount">{$translate->get('PaygAmountLabel')}</label>
			<div class="wd-field">
				<input type="text" inputmode="numeric" id="wdAmount" autocomplete="off">
				<span class="wd-unit" id="wdUnit"></span>
			</div>
			<div class="wd-chips" id="wdChips"></div>
			<div class="wd-bonus" id="wdBonus"></div>
			<div class="wd-note" id="wdMin"></div>
			<div class="wd-box" id="wdTiersBox" hidden>
				<div class="wd-box-title">🎁 {$translate->get('PaygTiersTitle')}</div>
				<div id="wdTiers"></div>
			</div>
			<div class="wd-note">🔒 {$translate->get('PaygChargeHint')}</div>
		</section>

		<section class="wd-pane" data-pane="history" role="tabpanel" hidden>
			<div class="wd-stats">
				<div class="wd-stat"><div class="wd-stat-label">{$translate->get('PaygToday')}</div><div class="wd-stat-value" id="wdToday">—</div></div>
				<div class="wd-stat"><div class="wd-stat-label">{$translate->get('PaygMonth')}</div><div class="wd-stat-value" id="wdMonth">—</div></div>
				<div class="wd-stat"><div class="wd-stat-label">{$translate->get('PaygTotalCharged')}</div><div class="wd-stat-value" id="wdCharged">—</div></div>
			</div>
			<div id="wdHistory"></div>
			<div class="wd-note">🔄 {$translate->get('PaygLiveHint')}</div>
		</section>

		<section class="wd-pane" data-pane="prices" role="tabpanel" hidden>
			<div id="wdRates"></div>
			<div class="wd-note" id="wdOutage">🛠 {$translate->get('PaygOutageNote')}</div>
		</section>

		<section class="wd-pane" data-pane="settings" role="tabpanel" hidden>
			<div class="wd-box">
				<label class="wd-switch">
					<input type="checkbox" id="wdAuto">
					<span class="wd-knob" aria-hidden="true"></span>
					<span>
						<span class="wd-switch-title">{$translate->get('PaygAuto')}</span>
						<span class="wd-switch-hint d-block">{$translate->get('PaygAutoHint')}</span>
					</span>
				</label>
			</div>
			<div class="wd-box" id="wdCommission" hidden>
				<div class="wd-box-title">🤝 {$translate->get('PaygCommission')}</div>
				<div class="wd-stat-value" id="wdCommissionBalance"></div>
				<div class="wd-note">{$translate->get('PaygCommissionNote')}</div>
			</div>
		</section>
	</div>

	<div class="wd-foot" id="wdFoot">
		<button type="button" class="wd-pay" id="wdPay">💳 …</button>
	</div>
</aside>

<div class="wd-toast" id="wdToast" role="status" aria-live="polite" hidden>
	<div class="wd-toast-text" id="wdToastText"></div>
	<button type="button" class="wd-toast-open" id="wdToastOpen">{$translate->get('PaygView')}</button>
	<button type="button" class="wd-toast-x" id="wdToastClose" aria-label="{$translate->get('Close')}">✕</button>
</div>

{literal}
<script>
(function () {
	var endpoint = '/xmplus-patch.php';
	var W = window.PaygWords;
	var state = null;
	var tab = 'charge';
	var opener = null;
	var drawer = document.getElementById('walletDrawer');
	var backdrop = document.getElementById('wdBackdrop');
	var rtl = (document.documentElement.getAttribute('dir') || '').toLowerCase() === 'rtl';
	var locale = rtl ? 'fa-IR' : 'en-US';

	function $id(id) { return document.getElementById(id); }

	function say(text) {
		if (window.layer && layer.msg) {
			layer.msg(text, { time: 5000, offset: '100px' });
		} else {
			alert(text);
		}
	}

	function esc(text) {
		return String(text == null ? '' : text).replace(/[&<>"']/g, function (c) {
			return ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[c];
		});
	}

	function num(n) {
		return Math.round(Number(n) || 0).toLocaleString(locale);
	}

	/* amounts arrive in rial; shown in toman unless the admin chose rial */
	function unit() { return state && state.toman ? W.toman : W.rial; }
	function shown(rial) { return state && state.toman ? (Number(rial) || 0) / 10 : (Number(rial) || 0); }
	function money(rial) { return num(shown(rial)) + ' ' + unit(); }
	function toRial(value) { return state && state.toman ? value * 10 : value; }

	function volume(bytes) {
		var gb = (Number(bytes) || 0) / 1073741824;
		if (gb < 1) {
			return num(gb * 1024) + ' ' + W.mb;
		}
		return gb.toLocaleString(locale, { maximumFractionDigits: 1 }) + ' ' + W.gb;
	}

	function time(stamp) {
		try {
			return new Date(stamp * 1000).toLocaleTimeString(locale, { hour: '2-digit', minute: '2-digit' });
		} catch (e) {
			return '';
		}
	}

	function dayLabel(stamp) {
		var d = new Date(stamp * 1000);
		var today = new Date();
		var yesterday = new Date();
		yesterday.setDate(today.getDate() - 1);
		if (d.toDateString() === today.toDateString()) {
			return W.today;
		}
		if (d.toDateString() === yesterday.toDateString()) {
			return W.yesterday;
		}
		try {
			return d.toLocaleDateString(locale, { weekday: 'long', day: 'numeric', month: 'long' });
		} catch (e) {
			return d.toDateString();
		}
	}

	/* the CDN in front of the panel must never hand back an old answer */
	function get(action) {
		return fetch(endpoint + '?do=' + action + '&_=' + Date.now(), { credentials: 'same-origin', cache: 'no-store' })
			.then(function (r) { return r.json(); });
	}

	function post(action, fields, retried) {
		var body = new FormData();
		body.append('token', state ? state.token : '');
		Object.keys(fields || {}).forEach(function (k) { body.append(k, fields[k]); });
		return fetch(endpoint + '?do=' + action, { method: 'POST', credentials: 'same-origin', cache: 'no-store', body: body })
			.then(function (r) { return r.json(); })
			.then(function (data) {
				// a lost session token: fetch a fresh one and try once more
				if (!data.ok && !retried && /token/i.test(String(data.error || ''))) {
					return load().then(function () { return post(action, fields, true); });
				}
				return data;
			});
	}

	// ---- rendering

	function renderHero() {
		var w = state.wallet;
		var hero = $id('wdHero');
		hero.className = 'wd-hero' + (w.mode === 'balance' ? ' is-balance' : (w.mode === 'empty' ? ' is-empty' : ''));
		$id('wdMode').textContent = w.mode === 'balance' ? W.modeBalance : (w.mode === 'empty' ? W.modeEmpty : W.modePlan);
		$id('wdBalance').innerHTML = esc(num(shown(w.balance))) + ' <small>' + esc(unit()) + '</small>';
		$id('wdHeadroom').textContent = state.headroom === null ? W.unlimited : W.headroom.replace('%gb%', volume(state.headroom));

		var pending = $id('wdPending');
		pending.hidden = !(state.pending > 0);
		pending.textContent = state.pending > 0 ? W.pending.replace('%amount%', money(state.pending)) : '';
	}

	function renderCharge() {
		var min = Number(state.min) || 0;
		$id('wdUnit').textContent = unit();
		$id('wdMin').textContent = min > 0 ? W.minNote.replace('%min%', money(min)) : '';

		var base = min > 0 ? [min, min * 2.5, min * 5, min * 10] : [1000000, 2000000, 5000000, 10000000];
		$id('wdChips').innerHTML = base.map(roundUp).map(function (c) {
			return '<button type="button" class="wd-chip" data-rial="' + c + '">' + esc(money(c)) + '</button>';
		}).join('');

		var tiers = state.tiers || [];
		$id('wdTiersBox').hidden = tiers.length === 0;
		$id('wdTiers').innerHTML = tiers.map(function (t) {
			return '<div class="wd-tier"><span>' + esc(W.tierFrom.replace('%min%', money(t.min))) + '</span>'
				+ '<b>+' + esc(num(t.percent)) + '٪</b></div>';
		}).join('');

		if (!$id('wdAmount').value) {
			$id('wdAmount').value = num(shown(roundUp(min > 0 ? min : base[0])));
		}
		preview();
	}

	function renderHistory() {
		var w = state.wallet;
		$id('wdToday').textContent = money(state.today);
		$id('wdMonth').textContent = money(state.month);
		$id('wdCharged').textContent = money(w.charged);

		var icons = { charge: '💳', bonus: '🎁', usage: '📶', adjust: '✍️' };
		var kinds = { charge: W.kindCharge, bonus: W.kindBonus, usage: W.kindUsage, adjust: W.kindAdjust };
		var html = '';
		var lastDay = '';

		(state.history || []).forEach(function (h) {
			var stamp = Number(h.updated) || Number(h.created) || 0;
			var day = dayLabel(stamp);
			if (day !== lastDay) {
				html += '<div class="wd-day">' + esc(day) + '</div>';
				lastDay = day;
			}

			var amount = Number(h.amount) || 0;
			var title = kinds[h.kind] || h.kind;
			var sub = [time(stamp)];

			if (h.kind === 'usage') {
				if (h.server) { title += ' · ' + h.server; }
				sub.push(volume(Number(h.bytes) + Number(h.free_bytes)));
				if (Number(h.free_bytes) > 0 && Number(h.bytes) === 0) { sub.push(W.freeNote); }
			}

			// the sign stays with the number in a right-to-left line
			var figure = amount === 0 && h.kind === 'usage'
				? '<div class="wd-amount is-free">' + esc(W.free) + '</div>'
				: '<div class="wd-amount ' + (amount >= 0 ? 'is-plus' : 'is-minus') + '"><bdi>'
					+ (amount >= 0 ? '+' : '−') + esc(num(shown(Math.abs(amount)))) + '</bdi> ' + esc(unit()) + '</div>';

			html += '<div class="wd-item is-' + esc(h.kind) + '">'
				+ '<span class="wd-ico" aria-hidden="true">' + (icons[h.kind] || '•') + '</span>'
				+ '<div class="wd-item-main"><div class="wd-item-title">' + esc(title) + '</div>'
				+ '<div class="wd-item-sub">' + esc(sub.join(' · ')) + '</div></div>'
				+ figure + '</div>';
		});

		$id('wdHistory').innerHTML = html || '<div class="wd-empty">🧾 ' + esc(W.noHistory) + '</div>';
	}

	function renderPrices() {
		$id('wdRates').innerHTML = (state.rates || []).map(function (r) {
			var down = r.down && state.outage_free ? '<span class="wd-rate-down">' + esc(W.down) + '</span>' : '';
			var price = r.price > 0 ? money(r.price) + ' ' + W.perGb : W.free;
			return '<div class="wd-rate"><div class="wd-rate-name">🌍 ' + esc(r.name) + down + '</div>'
				+ '<div class="wd-rate-price">' + esc(price) + '</div></div>';
		}).join('');
		$id('wdOutage').hidden = !state.outage_free;
	}

	function renderSettings() {
		$id('wdAuto').checked = !!state.wallet.auto;
		var c = state.commission || {};
		$id('wdCommission').hidden = !c.enabled;
		$id('wdCommissionBalance').textContent = money(c.balance || 0);
	}

	function render() {
		renderHero();
		renderCharge();
		renderHistory();
		renderPrices();
		renderSettings();
	}

	function load() {
		return get('payg.me').then(function (data) {
			if (!data || !data.ok) {
				return;
			}
			state = data;
			render();
			toast();
		}).catch(function () {});
	}

	// ---- the drawer

	function show(name) {
		tab = name || tab;
		document.querySelectorAll('#walletDrawer .wd-tab').forEach(function (b) {
			b.setAttribute('aria-selected', b.getAttribute('data-tab') === tab ? 'true' : 'false');
		});
		document.querySelectorAll('#walletDrawer .wd-pane').forEach(function (p) {
			p.hidden = p.getAttribute('data-pane') !== tab;
		});
		$id('wdFoot').hidden = tab !== 'charge';
	}

	function open(name) {
		opener = document.activeElement;
		$id('wdToast').hidden = true;
		show(name === 'history' || name === 'prices' || name === 'settings' ? name : 'charge');
		drawer.hidden = false;
		backdrop.hidden = false;
		document.documentElement.classList.add('wd-lock');
		// let the hidden -> shown change paint first, so the slide animates
		requestAnimationFrame(function () {
			requestAnimationFrame(function () {
				drawer.classList.add('is-open');
				backdrop.classList.add('is-open');
				drawer.focus({ preventScroll: true });
			});
		});
		load();
	}

	function close() {
		if (drawer.hidden) {
			return;
		}
		drawer.classList.remove('is-open');
		backdrop.classList.remove('is-open');
		document.documentElement.classList.remove('wd-lock');
		setTimeout(function () {
			drawer.hidden = true;
			backdrop.hidden = true;
		}, 300);
		if (/^#wallet/.test(location.hash) && window.history && history.replaceState) {
			history.replaceState(null, '', location.pathname + location.search);
		}
		if (opener && opener.focus) {
			opener.focus({ preventScroll: true });
		}
	}

	function fromHash() {
		var m = /^#wallet(?:-(charge|history|prices|settings))?$/.exec(location.hash);
		if (m) {
			open(m[1] || 'charge');
		}
	}

	window.WalletDrawer = { open: open, close: close };

	document.addEventListener('click', function (e) {
		var trigger = e.target.closest('[data-wallet-open]');
		if (trigger) {
			e.preventDefault();
			open(trigger.getAttribute('data-wallet-open'));
			return;
		}
		if (e.target.closest('[data-wallet-close]') || e.target === backdrop) {
			close();
		}
	});

	document.addEventListener('keydown', function (e) {
		if (e.key === 'Escape') {
			close();
		}
	});

	document.querySelectorAll('#walletDrawer .wd-tab').forEach(function (b) {
		b.addEventListener('click', function () { show(b.getAttribute('data-tab')); });
	});

	window.addEventListener('hashchange', fromHash);

	// ---- top-up

	function bonusPercent(rial) {
		var best = 0;
		(state.tiers || []).forEach(function (t) {
			if (rial >= t.min) {
				best = t.percent;
			}
		});
		return best;
	}

	function roundUp(rial) {
		var step = Math.max(1, Number(state && state.step) || 1);
		return Math.ceil(rial / step) * step;
	}

	function amountRial() {
		var raw = $id('wdAmount').value
			.replace(/[۰-۹]/g, function (d) { return '۰۱۲۳۴۵۶۷۸۹'.indexOf(d); })
			.replace(/[٠-٩]/g, function (d) { return '٠١٢٣٤٥٦٧٨٩'.indexOf(d); })
			.replace(/[^0-9.]/g, '');
		return toRial(Number(raw) || 0);
	}

	function preview() {
		var rial = amountRial();
		var p = bonusPercent(rial);
		$id('wdBonus').textContent = p > 0
			? W.bonusNote.replace('%p%', num(p)).replace('%amount%', money(Math.round(rial * p / 100)))
			: '';
		$id('wdPay').textContent = '💳 ' + (rial > 0 ? W.payAmount.replace('%amount%', money(roundUp(rial))) : W.enterAmount);
		document.querySelectorAll('#wdChips .wd-chip').forEach(function (c) {
			c.classList.toggle('is-on', Number(c.getAttribute('data-rial')) === roundUp(rial));
		});
	}

	/* the same checkout the data top-up uses - only the package id differs */
	function createOrder(packageid) {
		$.ajax({
			type: 'POST',
			url: '/portal/order/create',
			dataType: 'json',
			data: { packageid: packageid, plan: 'topup', code: '', renew: 0, upgrade: 0, disableactive: 1 },
			success: function (data) {
				if (window.layer) { layer.closeAll('loading'); }
				$id('wdPay').disabled = false;
				if (data.ret == 1 || (data.ret == -1 && data.url)) {
					window.location.href = data.url;
					return;
				}
				say(data.msg || W.failed);
			},
			error: function (jqXHR) {
				if (window.layer) { layer.closeAll('loading'); }
				$id('wdPay').disabled = false;
				say(jqXHR.responseText || W.failed);
			}
		});
	}

	function pay() {
		if (!state) {
			return;
		}
		var rial = amountRial();

		if (rial <= 0) {
			say(W.enterAmount);
			return;
		}
		if (Number(state.min) > 0 && rial < Number(state.min)) {
			say(W.tooLow.replace('%min%', money(state.min)));
			return;
		}

		$id('wdPay').disabled = true;
		if (window.layer) { layer.load(2); }

		post('payg.mint', { amount: roundUp(rial) }).then(function (data) {
			if (!data.ok) {
				$id('wdPay').disabled = false;
				if (window.layer) { layer.closeAll('loading'); }
				say(data.error || W.failed);
				return;
			}
			createOrder(data.packageid);
		}).catch(function () {
			$id('wdPay').disabled = false;
			if (window.layer) { layer.closeAll('loading'); }
			say(W.failed);
		});
	}

	$id('wdAmount').addEventListener('input', preview);
	$id('wdAmount').addEventListener('keydown', function (e) {
		if (e.key === 'Enter') { pay(); }
	});
	$id('wdChips').addEventListener('click', function (e) {
		var chip = e.target.closest('.wd-chip');
		if (chip) {
			$id('wdAmount').value = num(shown(Number(chip.getAttribute('data-rial'))));
			preview();
		}
	});
	$id('wdPay').addEventListener('click', pay);

	$id('wdAuto').addEventListener('change', function () {
		var box = this;
		post('payg.auto', { on: box.checked ? 1 : 0 }).then(function (data) {
			if (data.ok) {
				state.wallet.auto = data.auto;
				say(data.auto ? W.autoOn : W.autoOff);
			} else {
				box.checked = !box.checked;
				say(data.error || W.failed);
			}
		});
	});

	// ---- messages from the billing job: a toast, not a block in the page

	var toastShown = false;

	function toast() {
		var list = (state && state.notices) || [];
		if (toastShown || list.length === 0) {
			return;
		}
		toastShown = true;
		var n = list[0];
		var box = $id('wdToast');
		box.className = 'wd-toast is-' + String(n.kind || '').replace(/[^a-z]/g, '');
		$id('wdToastText').textContent = n.text;
		box.hidden = false;
		setTimeout(function () { box.hidden = true; }, 12000);
	}

	$id('wdToastOpen').addEventListener('click', function () {
		$id('wdToast').hidden = true;
		open('history');
	});
	$id('wdToastClose').addEventListener('click', function () {
		$id('wdToast').hidden = true;
	});

	load();
	fromHash();
})();
</script>
{/literal}
{/if}
