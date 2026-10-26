{include file='user/layout/header.tpl'}

{literal}
<style>
/* ---- checkout step one: choosing the cycle ---- */
.pd-head {
	border: 0;
	padding: 0;
	margin-bottom: 18px;
}
.pd-head-inner {
	border-radius: 20px;
	padding: 20px 22px;
	background: linear-gradient(135deg, #4f46e5, #7c3aed 55%, #0ea5e9);
	color: #fff;
	box-shadow: 0 14px 34px rgba(79, 70, 229, .28);
}
.pd-steps { display: flex; align-items: center; gap: 8px; flex-wrap: wrap; margin-bottom: 9px; }
.pd-step {
	display: inline-flex;
	align-items: center;
	gap: 6px;
	font-size: 11.5px;
	font-weight: 700;
	padding: 5px 11px;
	border-radius: 999px;
	background: rgba(255, 255, 255, .16);
	border: 1px solid rgba(255, 255, 255, .24);
	color: rgba(255, 255, 255, .82);
}
.pd-step.is-now { background: #fff; color: #4338ca; border-color: #fff; }
.pd-step-sep { color: rgba(255, 255, 255, .5); font-size: 11px; }
.pd-head-title { font-size: 20px; font-weight: 800; margin: 0; color: #fff; }

.pd-card {
	border: 0;
	border-radius: 18px;
	background: #fff;
	box-shadow: 0 10px 26px rgba(23, 32, 61, .07);
	overflow: hidden;
	margin-bottom: 18px;
}
.pd-card-head {
	padding: 15px 18px;
	border-bottom: 1px solid rgba(23, 32, 61, .07);
	display: flex;
	align-items: center;
	gap: 9px;
}
.pd-card-emoji {
	width: 34px;
	height: 34px;
	flex: 0 0 auto;
	border-radius: 12px;
	background: rgba(99, 102, 241, .13);
	display: inline-flex;
	align-items: center;
	justify-content: center;
	font-size: 17px;
}
.pd-card-title { font-size: 15px; font-weight: 800; color: #16203d; margin: 0; }
.pd-card-body { padding: 17px 18px; }

/* ---- what you get ---- */
.pd-specs { display: grid; grid-template-columns: repeat(auto-fit, minmax(178px, 1fr)); gap: 10px; }
.pd-spec {
	display: flex;
	align-items: center;
	gap: 10px;
	border-radius: 14px;
	padding: 11px 13px;
	background: var(--soft, rgba(99, 102, 241, .08));
}
.pd-spec-emoji { font-size: 18px; line-height: 1; flex: 0 0 auto; }
.pd-spec-label { font-size: 11px; font-weight: 700; color: #8c98ab; display: block; }
.pd-spec-value {
	font-size: 13.5px;
	font-weight: 800;
	color: #16203d;
	line-height: 1.6;
	word-break: break-word;
}
.pd-note {
	margin-top: 14px;
	border-radius: 14px;
	padding: 13px 15px;
	background: rgba(245, 158, 11, .08);
	border: 1px dashed rgba(245, 158, 11, .35);
	font-size: 12.5px;
	line-height: 2;
	color: #3b4a6b;
}

/* ---- the billing cycles ---- */
.pd-cycles { display: grid; grid-template-columns: repeat(auto-fit, minmax(158px, 1fr)); gap: 11px; }
.pd-cycle { position: relative; margin: 0; }
.pd-cycle input {
	position: absolute;
	opacity: 0;
	width: 0;
	height: 0;
	pointer-events: none;
}
.pd-cycle-box {
	display: block;
	border: 1.5px solid rgba(23, 32, 61, .11);
	border-radius: 16px;
	padding: 15px 13px;
	text-align: center;
	cursor: pointer;
	background: #fff;
	transition: border-color .16s ease, transform .16s ease, box-shadow .16s ease, background .16s ease;
}
.pd-cycle-box:hover { border-color: #6366f1; transform: translateY(-2px); }
.pd-cycle input:checked + .pd-cycle-box {
	border-color: #6366f1;
	background: linear-gradient(135deg, rgba(99, 102, 241, .12), rgba(14, 165, 233, .1));
	box-shadow: 0 9px 22px rgba(99, 102, 241, .18);
}
.pd-cycle input:checked + .pd-cycle-box::after {
	content: "✓";
	position: absolute;
	top: 9px;
	inset-inline-end: 11px;
	width: 19px;
	height: 19px;
	border-radius: 50%;
	background: #6366f1;
	color: #fff;
	font-size: 11px;
	line-height: 19px;
	font-weight: 700;
}
.pd-cycle-price {
	font-size: 16px;
	font-weight: 800;
	color: #16203d;
	direction: ltr;
	unicode-bidi: isolate;
	display: block;
}
.pd-cycle-name { font-size: 12.5px; font-weight: 700; color: #4338ca; margin-top: 6px; display: block; }
.pd-cycle-days { font-size: 11px; color: #8c98ab; margin-top: 2px; display: block; }
.pd-cycle-tag {
	position: absolute;
	top: -8px;
	inset-inline-start: 12px;
	background: #10b981;
	color: #fff;
	font-size: 9.5px;
	font-weight: 800;
	padding: 2px 8px;
	border-radius: 999px;
	box-shadow: 0 3px 8px rgba(16, 185, 129, .38);
}

/* ---- coupon ---- */
.pd-coupon { display: flex; gap: 8px; flex-wrap: wrap; }
.pd-coupon input {
	flex: 1 1 140px;
	min-width: 0;
	border: 1.5px solid rgba(23, 32, 61, .12);
	border-radius: 13px;
	padding: 11px 13px;
	font-size: 13px;
	font-weight: 600;
	color: #16203d;
	background: #fff;
	outline: none;
}
.pd-coupon input:focus { border-color: #6366f1; box-shadow: 0 0 0 4px rgba(99, 102, 241, .12); }
.pd-coupon input:disabled { background: rgba(16, 185, 129, .09); border-color: rgba(16, 185, 129, .35); }
.pd-mini {
	flex: 0 0 auto;
	border: 0;
	border-radius: 13px;
	padding: 11px 17px;
	font-size: 12.5px;
	font-weight: 800;
	cursor: pointer;
	color: #fff;
	background: linear-gradient(135deg, #4f46e5, #7c3aed);
}
.pd-mini-off { background: linear-gradient(135deg, #be123c, #f43f5e); }

/* ---- the switch ----
 * Drawn here rather than left to the theme: the redesign dropped the theme's
 * own switch markup, and a bare .form-check-input rendered as an empty white
 * box with nothing to show whether it was on. */
.pd-switch {
	display: flex;
	align-items: center;
	gap: 12px;
	border-radius: 14px;
	padding: 13px 14px;
	background: rgba(245, 158, 11, .08);
	border: 1px solid rgba(245, 158, 11, .28);
	cursor: pointer;
	transition: background .16s ease, border-color .16s ease;
}
.pd-switch:hover { background: rgba(245, 158, 11, .14); }
.pd-switch-wrap {
	position: relative;
	width: 48px;
	height: 27px;
	flex: 0 0 auto;
	display: inline-block;
}
.pd-switch-wrap input {
	position: absolute;
	inset: 0;
	width: 100%;
	height: 100%;
	margin: 0;
	opacity: 0;
	cursor: pointer;
	z-index: 2;
}
.pd-knob {
	position: absolute;
	inset: 0;
	border-radius: 999px;
	background: #c3cbd9;
	box-shadow: inset 0 1px 3px rgba(23, 32, 61, .22);
	transition: background .18s ease;
}
.pd-knob::after {
	content: "";
	position: absolute;
	top: 3px;
	/* physical left on purpose: the logical inset flips with the RTL page and
	   put the knob on the left when the switch was on, which reads as off */
	left: 3px;
	width: 21px;
	height: 21px;
	border-radius: 50%;
	background: #fff;
	box-shadow: 0 2px 6px rgba(23, 32, 61, .3);
	transition: left .18s ease;
}
.pd-switch-wrap input:checked + .pd-knob {
	background: linear-gradient(135deg, #d97706, #f59e0b);
	box-shadow: inset 0 1px 3px rgba(180, 83, 9, .35);
}
.pd-switch-wrap input:checked + .pd-knob::after { left: 24px; }
.pd-switch-wrap input:focus-visible + .pd-knob { outline: 2px solid #6366f1; outline-offset: 2px; }

.pd-switch-text { font-size: 12.5px; font-weight: 700; color: #16203d; margin: 0; line-height: 1.7; }
.pd-switch-state {
	font-size: 11px;
	font-weight: 700;
	color: #b45309;
	display: block;
	margin-top: 2px;
}

/* ---- the total ---- */
.pd-sum { position: sticky; top: 84px; }
.pd-line {
	display: flex;
	justify-content: space-between;
	align-items: center;
	gap: 10px;
	font-size: 13px;
	color: #56617a;
	margin-bottom: 11px;
}
.pd-line span:last-child { font-weight: 700; color: #16203d; direction: ltr; unicode-bidi: isolate; }
.pd-line-off span:last-child { color: #be123c; }
.pd-total {
	display: flex;
	justify-content: space-between;
	align-items: center;
	gap: 10px;
	border-top: 1.5px dashed rgba(23, 32, 61, .12);
	padding-top: 14px;
	margin-top: 4px;
}
.pd-total-label { font-size: 14px; font-weight: 800; color: #16203d; }
.pd-total-value {
	font-size: 19px;
	font-weight: 800;
	color: #047857;
	direction: ltr;
	unicode-bidi: isolate;
}
.pd-buy {
	display: block;
	width: 100%;
	margin-top: 16px;
	border: 0;
	border-radius: 15px;
	padding: 14px 18px;
	font-size: 14.5px;
	font-weight: 800;
	color: #fff;
	cursor: pointer;
	background: linear-gradient(135deg, #059669, #10b981);
	box-shadow: 0 8px 20px rgba(16, 185, 129, .34);
	transition: transform .14s ease, box-shadow .14s ease;
}
.pd-buy:hover { box-shadow: 0 12px 26px rgba(16, 185, 129, .44); }
.pd-buy:active { transform: scale(.98); }
.pd-safe {
	margin-top: 11px;
	font-size: 11.5px;
	color: #8c98ab;
	text-align: center;
	line-height: 1.9;
}

html[data-hs-theme="dark"] .pd-card { background: #1c2536; box-shadow: 0 10px 26px rgba(0, 0, 0, .35); }
html[data-hs-theme="dark"] .pd-card-head { border-bottom-color: rgba(255, 255, 255, .08); }
html[data-hs-theme="dark"] .pd-card-title,
html[data-hs-theme="dark"] .pd-spec-value,
html[data-hs-theme="dark"] .pd-cycle-price,
html[data-hs-theme="dark"] .pd-total-label,
html[data-hs-theme="dark"] .pd-switch-text { color: #e7eaf3; }
html[data-hs-theme="dark"] .pd-cycle-box { background: #1c2536; border-color: rgba(255, 255, 255, .1); }
html[data-hs-theme="dark"] .pd-coupon input { background: #1c2536; border-color: rgba(255, 255, 255, .12); color: #e7eaf3; }
html[data-hs-theme="dark"] .pd-note { color: #b9c2d4; }
html[data-hs-theme="dark"] .pd-line span:last-child { color: #e7eaf3; }
html[data-hs-theme="dark"] .pd-total-value { color: #34d399; }
html[data-hs-theme="dark"] .pd-total { border-top-color: rgba(255, 255, 255, .14); }
html[data-hs-theme="dark"] .pd-knob { background: #3d4761; }
html[data-hs-theme="dark"] .pd-switch-state { color: #fcd34d; }

@media (max-width: 575.98px) {
	.pd-head-inner { padding: 17px; }
	.pd-head-title { font-size: 17.5px; }
	.pd-sum { position: static; }
}
</style>
{/literal}
{include file='user/plan/promostyle.tpl'}
{$promo = $timeplan->promo($package->id)}

	<div class="page-header pd-head">
		<div class="pd-head-inner">
			<div class="pd-steps">
				<span class="pd-step is-now">1 · {$translate->get('PlanDetails')}</span>
				<span class="pd-step-sep">›</span>
				<span class="pd-step">2 · {$translate->get('Checkout')}</span>
				<span class="pd-step-sep">›</span>
				<span class="pd-step">3 · {$translate->get('Pay')}</span>
			</div>
			<h1 class="pd-head-title">🛒 {$package->name}</h1>
		</div>
	</div>

	<div class="row mb-3"{if $promo} data-promo-scope{/if}>
		<div class="col-xl-8 col-lg-8 col-md-12 col-sm-12">

			{if $promo}
				<div class="promo-banner promo-only promo-theme-{$promo.theme}">
					<div class="promo-banner-badges">{include file='user/plan/promobadges.tpl'}</div>
					{if $promo.kind == 'discount'}
						<div class="promo-banner-line">🏷️ {$translate->get('PromoBannerDiscount')|replace:'%n%':"<b>{$promo.percent}</b>"}</div>
					{elseif $promo.kind == 'special'}
						<div class="promo-banner-line">⭐ {$translate->get('PromoBannerSpecial')}</div>
					{/if}
					{include file='user/plan/promostrip.tpl'}
				</div>
			{/if}

			<div class="pd-card">
				<div class="pd-card-head">
					<span class="pd-card-emoji">📦</span>
					<h3 class="pd-card-title">{$translate->get('PlanDetails')}</h3>
				</div>
				<div class="pd-card-body">
					<div class="pd-specs">
						<div class="pd-spec" style="--soft:rgba(99,102,241,.09)">
							<span class="pd-spec-emoji">📊</span>
							<span>
								<span class="pd-spec-label">{$translate->get('Bandwidth')}</span>
								<span class="pd-spec-value">{if $package->bandwidth < 10000}{$package->bandwidth} GB{else}{$translate->get('Unlimited')}{/if}</span>
							</span>
						</div>
						<div class="pd-spec" style="--soft:rgba(14,165,233,.09)">
							<span class="pd-spec-emoji">⚡</span>
							<span>
								<span class="pd-spec-label">{$translate->get('PortSpeed')}</span>
								<span class="pd-spec-value">{$helpers->PortSpd($package->speedlimit)}</span>
							</span>
						</div>
						<div class="pd-spec" style="--soft:rgba(139,92,246,.09)">
							<span class="pd-spec-emoji">👥</span>
							<span>
								<span class="pd-spec-label">{$translate->get('ConnLimit')}</span>
								<span class="pd-spec-value">{$package->iplimit}</span>
							</span>
						</div>
						<div class="pd-spec" style="--soft:rgba(6,182,212,.09)">
							<span class="pd-spec-emoji">🌍</span>
							<span>
								<span class="pd-spec-label">{$translate->get('ServerGroup')}</span>
								<span class="pd-spec-value">{str_replace([' | '],[''],$helpers->serveGroup($package->server_group))}</span>
							</span>
						</div>
						<div class="pd-spec" style="--soft:rgba(16,185,129,.09)">
							<span class="pd-spec-emoji">{if $package->reset_days > 0}🔄{else}🚫{/if}</span>
							<span>
								<span class="pd-spec-label">{$translate->get('AllowReset')}</span>
								<span class="pd-spec-value">{if $package->reset_days > 0}{$translate->get('Every')} {$package->reset_days} {$translate->get('Days')}{else}{$translate->get('None')}{/if}</span>
							</span>
						</div>
					</div>

					{if $package->order_note != null}
						<div class="pd-note">
							📋 {$content = json_decode($package->order_note,true)}{assign var=lang value="_"|explode:$session->get('locale')}{if isset($content[$lang[1]])}{$content[$lang[1]]}{else}{$package->order_note}{/if}
						</div>
					{/if}
				</div>
			</div>

			<div class="pd-card">
				<div class="pd-card-head">
					<span class="pd-card-emoji">📅</span>
					<h3 class="pd-card-title">{$translate->get('BillingCycle')}</h3>
				</div>
				<div class="pd-card-body">
					<div class="pd-cycles">
						{$options = json_decode($package->price_option,true)}
						{$p = 0}
						{foreach $options as $option => $value}
							{if $option != "topup" && isset($value['price']) && $value['price'] !== ""}
								{$p = $p + 1}
								<label class="pd-cycle">
									<input type="radio" name="plan" id="{$option}" {if $p == 1}checked{/if} value="{$option}" onClick="Billing('{$option}')">
									<span class="pd-cycle-box">
										{if $option == "annual"}<span class="pd-cycle-tag">⭐ {$translate->get('BestValue')}</span>{/if}
										<span class="pd-cycle-price">
											{if $promo && $promo.kind == 'discount' && isset($promo.original[$option]) && $promo.original[$option] > (float)$value['price']}
												<span class="promo-was promo-only">{number_format((float)$promo.original[$option], (int){$currency->decimals})}</span>
											{/if}
											{if $promo && $promo.percent == 100}<b>{$translate->get('PromoFree')}</b>{else}{$currency->symbol_left} {number_format((float)$value['price'], (int){$currency->decimals})} {$currency->symbol_right}{/if}
											{if $promo && $promo.kind == 'discount' && isset($promo.original[$option]) && $promo.original[$option] > (float)$value['price']}
												<span class="promo-off promo-only">{$translate->get('PromoOffLabel')|replace:'%n%':$promo.percent}</span>
											{/if}
										</span>
										{if $option == "onetime"}
											<span class="pd-cycle-name">{$translate->get('Onetime')}</span>
											<span class="pd-cycle-days">♾️ {$translate->get('NotExpire')}</span>
										{elseif $option == "month"}
											<span class="pd-cycle-name">{$translate->get('Monthly')}</span>
											<span class="pd-cycle-days">30 {$translate->get('Days')}</span>
										{elseif $option == "quater"}
											<span class="pd-cycle-name">{$translate->get('Quaterly')}</span>
											<span class="pd-cycle-days">90 {$translate->get('Days')}</span>
										{elseif $option == "semiannual"}
											<span class="pd-cycle-name">{$translate->get('SemiAnnually')}</span>
											<span class="pd-cycle-days">180 {$translate->get('Days')}</span>
										{elseif $option == "annual"}
											<span class="pd-cycle-name">{$translate->get('Annually')}</span>
											<span class="pd-cycle-days">360 {$translate->get('Days')}</span>
										{elseif $option == "custom"}
											<span class="pd-cycle-name">{$translate->get('Custom')}</span>
											<span class="pd-cycle-days">{$value['expire']} {$translate->get('Days')}</span>
										{/if}
									</span>
								</label>
							{/if}
						{/foreach}
					</div>
				</div>
			</div>

		</div>

		<div class="col-xl-4 col-lg-4 col-md-12 col-sm-12">
			<div class="pd-sum">

				{* ---- reserve this plan to start later ---- *}
				{if $package->type == 2 && $user && $user->reserveFeatureOn()}
					{assign var=reserveRow value=$user->planReserveWaiting()}
					{if $reserveRow}
						<div class="pd-card">
							<div class="pd-card-head">
								<span class="pd-card-emoji">🗓️</span>
								<h3 class="pd-card-title">{$translate->get('ReserveTitle')}</h3>
							</div>
							<div class="pd-card-body">
								<div class="pd-note" style="margin-top:0">
									{$translate->get('ReserveAlreadyHave')} <b>{$reserveRow.name}</b>
									<br><a href="/portal/dashboard">{$translate->get('ReserveSeeDashboard')}</a>
								</div>
							</div>
						</div>
					{else}
						<div class="pd-card" id="reserveCard">
							<div class="pd-card-head">
								<span class="pd-card-emoji">🗓️</span>
								<h3 class="pd-card-title">{$translate->get('ReserveTitle')}</h3>
							</div>
							<div class="pd-card-body">
								<label class="pd-switch">
									<span class="pd-switch-wrap">
										<input type="checkbox" id="reserveOn" onClick="ReserveToggle()">
										<span class="pd-knob"></span>
									</span>
									<span class="pd-switch-text">
										{$translate->get('ReserveSwitch')}
										<span class="pd-switch-state" id="reserveState">{$translate->get('SwitchOff')}</span>
									</span>
								</label>

								<div id="reserveBox" style="display:none;margin-top:13px">
									<label class="pd-cycle" style="margin-bottom:9px">
										<input type="radio" name="reserve_mode" id="reserve_after" value="after" checked onClick="ReserveMode()">
										<span class="pd-cycle-box" style="padding:11px 12px">{$translate->get('ReserveModeAfter')}</span>
									</label>
									<label class="pd-cycle" style="margin-bottom:9px">
										<input type="radio" name="reserve_mode" id="reserve_date" value="date" onClick="ReserveMode()">
										<span class="pd-cycle-box" style="padding:11px 12px">{$translate->get('ReserveModeDate')}</span>
									</label>
									<div id="reserveDateWrap" style="display:none">
										<label class="pd-spec-label" for="reserveDate">{$translate->get('ReserveDateLabel')}</label>
										<input type="date" id="reserveDate" class="pd-coupon" style="width:100%;display:block" dir="ltr">
									</div>
									<div class="pd-note" style="margin-top:11px">{$translate->get('ReserveNote')}</div>
								</div>
							</div>
						</div>
					{/if}
				{/if}

				{if $Config['allow_coupon_use'] == 1}
					<div class="pd-card">
						<div class="pd-card-head">
							<span class="pd-card-emoji">🎟️</span>
							<h3 class="pd-card-title">{$translate->get('InputCoupon')}</h3>
						</div>
						<div class="pd-card-body">
							<div class="pd-coupon">
								<input id="coupon" type="text" placeholder="{$translate->get('InputCoupon')}" autocomplete="off">
								<button type="button" class="pd-mini" id="redeem">{$translate->get('Redeem')}</button>
								<button type="button" class="pd-mini pd-mini-off" id="remove" onClick="Remove()" hidden>{$translate->get('Remove')}</button>
							</div>
						</div>
					</div>
				{/if}

				<div class="pd-card" id="disableactiveCard">
					<div class="pd-card-body">
						<label class="pd-switch">
							<span class="pd-switch-wrap">
								<input type="checkbox" id="disableactive" onClick="DisableActive()">
								<span class="pd-knob"></span>
							</span>
							<span class="pd-switch-text">
								{$translate->get('DisableActive')}
								<span class="pd-switch-state" id="disableactiveState">{$translate->get('SwitchOff')}</span>
							</span>
						</label>
					</div>
				</div>

				{include file='user/plan/commissionuse.tpl'}

				<div class="pd-card">
					<div class="pd-card-head">
						<span class="pd-card-emoji">🧾</span>
						<h3 class="pd-card-title">{$translate->get('Summary')}</h3>
					</div>
					<div class="pd-card-body">
						<div class="pd-line">
							<span>{$translate->get('SubTotal')}</span>
							<span>{$currency->symbol_left} <span id="subtotal">{$price}</span> {$currency->symbol_right}</span>
						</div>
						<div class="pd-line pd-line-off">
							<span>{$translate->get('Discount')}</span>
							<span>- {$currency->symbol_left} <span id="discount">{number_format((float)0, (int){$currency->decimals})}</span> {$currency->symbol_right}</span>
						</div>
						<div class="pd-total">
							<span class="pd-total-label">{$translate->get('Total')}</span>
							<span class="pd-total-value">{$currency->symbol_left} <span id="total">{$price}</span> {$currency->symbol_right}</span>
						</div>

						<button type="button" class="pd-buy" onClick="Checkout()">🛒 {$translate->get('Checkout')}</button>
						<div class="pd-safe">🔒 {$translate->get('CheckoutSafeNote')}</div>
					</div>
				</div>

			</div>
		</div>
	</div>

{include file='user/layout/footer.tpl'}
{include file='common/orderresult.tpl'}
<script>
	checkBill();
	reserveBoot();
	
	{if $Config['allow_coupon_use'] == 1}
		var coupon = localStorage.getItem('coupon');
		if(coupon != null){
			localStorage.removeItem('coupon');
		}
	{/if}
	
	function DisableActive(){
		var mark = document.getElementById('disableactiveState');
		if (mark) {
			mark.textContent = document.getElementById('disableactive').checked
				? "{$translate->get('SwitchOn')}" : "{$translate->get('SwitchOff')}";
		}

		if(document.getElementById('disableactive').checked == 1){
			Swal.fire({
				title: '',
				html: "{$translate->get('DisableActiveNote')}",
				icon: 'warning',
				showCancelButton: false,
				showConfirmButton:true,
				confirmButtonText: "{$translate->get('ok')}",
				allowOutsideClick: false,
				customClass: {
					confirmButton: 'btn btn-secondary ms-1',
					cancelButton: 'btn btn-danger ms-1'
				},
				buttonsStyling: false
			})
		}
	}
	
	function Remove(){
		document.getElementById("coupon").disabled = false;
		document.getElementById("remove").setAttribute("hidden", true);
		document.getElementById("redeem").removeAttribute("hidden");
		localStorage.removeItem('coupon');
		$("#coupon").val("");
		location.reload();
	}	
	
	function checkBill(){
		var type = $("input[name='plan']:checked").val();
		Billing(type);
	}
	
	function Billing(type){
		var coupon = localStorage.getItem('coupon');
		if(coupon != null){
			var code = coupon;
		}else{
			var code = "";
		}
		$.ajax({
			type: "POST",
			url: "/portal/checkout/billing",
			dataType: "json",
			data: {
				packageid : {$package->id},
				type: type,
				code: code,
			},
			success: (data) => {
				if (data.ret) {
					$("#total").html(data.total);
					$("#subtotal").html(data.subtotal);
					$("#discount").html(data.discount);
				}else{
					layer.msg(data.msg, {
						time: 3000,
						offset:  '100px'
					});
				}
			},
			error: (jqXHR) => {
				layer.msg(jqXHR.responseText, {
					time: 8000,
					offset:  '100px'
				});
			}
		});
	}	

	
	{if $Config['allow_coupon_use'] == 1}
	$('#redeem').click(function (){
		var plan =  $("input[name='plan']:checked").val();
		localStorage.setItem('coupon', $("#coupon").val());
		$.ajax({
			type: "POST",
			url: "/portal/checkout/redeem",
			dataType: "json",
			data: {
				packageid : {$package->id},
				plan: plan,
				code: localStorage.getItem('coupon'),
			},
			success: (data) => {
				if (data.ret) {
					$("#total").html(data.total);
					$("#subtotal").html(data.subtotal);
					$("#discount").html(data.discount);
					document.getElementById("coupon").disabled = true;
					document.getElementById("redeem").setAttribute("hidden", true);
					document.getElementById("remove").removeAttribute("hidden");
				}else{
				    localStorage.removeItem('coupon');
					layer.msg(data.msg, {
						time: 3000,
						offset:  '100px'
					});
				}
			},
			error: (jqXHR) => {
				layer.msg(jqXHR.responseText, {
					time: 8000,
					offset:  '100px'
				});
			}
		});
	});
	{/if}
	
	/* ---- reserve this plan to start later (app/Patch/Reserve.php) ---- */
	var reserveToken = "";
	var reserveMaxDays = 365;

	function reserveBoot(){
		if(!document.getElementById('reserveCard')){
			return;
		}

		$.ajax({
			type: "GET",
			url: "/xmplus-patch.php?do=reserve.mine",
			dataType: "json",
			success: (data) => {
				if(!data.ok){
					return;
				}

				reserveToken = data.token || "";
				reserveMaxDays = parseInt(data.max_days, 10) || 365;

				// the admin can switch reservations off without a release
				if(data.enabled != 1){
					document.getElementById('reserveCard').style.display = 'none';
					return;
				}

				var input = document.getElementById('reserveDate');
				if(input){
					input.min = new Date().toISOString().slice(0, 10);
					input.max = new Date(Date.now() + reserveMaxDays * 86400000).toISOString().slice(0, 10);
				}
			}
		});
	}

	function ReserveToggle(){
		var on = document.getElementById('reserveOn').checked;
		document.getElementById('reserveBox').style.display = on ? 'block' : 'none';
		document.getElementById('reserveState').textContent = on ? "{$translate->get('SwitchOn')}" : "{$translate->get('SwitchOff')}";

		// reserving keeps the current plan, so there is nothing for the
		// "cancel my plan" switch to do here (and the reserve order never sends
		// it as cancel). Hide it; leave the customer's own choice untouched.
		var card = document.getElementById('disableactiveCard');
		if(card){
			card.style.display = on ? 'none' : '';
		}
		if(on){
			ReserveMode();
		}
	}

	function ReserveMode(){
		var chosen = document.getElementById('reserve_date');
		document.getElementById('reserveDateWrap').style.display = (chosen && chosen.checked) ? 'block' : 'none';
	}

	function ReserveReady(){
		var box = document.getElementById('reserveOn');
		return box && box.checked;
	}

	function reservePrepare(cycle, code){
		var useDate = document.getElementById('reserve_date') && document.getElementById('reserve_date').checked;
		var mode = useDate ? 'date' : 'after';
		var when = useDate ? ($('#reserveDate').val() || '') : '';

		if(mode == 'date' && when == ''){
			layer.msg("{$translate->get('ReservePickDate')}", {
				time: 3000,
				offset:  '100px'
			});
			return;
		}

		if(!reserveToken){
			layer.msg("{$translate->get('ReserveError')}", {
				time: 3000,
				offset:  '100px'
			});
			return;
		}

		$.ajax({
			type: "POST",
			url: "/xmplus-patch.php?do=reserve.prepare",
			dataType: "json",
			data: {
				token: reserveToken,
				plan: {$package->id},
				cycle: cycle,
				mode: mode,
				activate_at: when
			},
			success: (data) => {
				if(data.ok && data.packageid){
					// the reservation is now a normal top-up row; the panel's
					// own checkout takes it from here.
					//
					// disableactive is sent as 1 because the encoded checkout
					// refuses any order while the account has a running plan
					// unless it is set - that is what "اشتراک فعال دارید"
					// means. It is ignored for a type-1 top-up, so the plan the
					// customer is on is NOT cancelled - exactly what "add data"
					// and "add time" send (dashboard.tpl:751/971).
					SubmitOrder(data.packageid, 'topup', code, 1);
				}else{
					layer.msg(data.error || "{$translate->get('ReserveError')}", {
						time: 4000,
						offset:  '100px'
					});
				}
			},
			error: (jqXHR) => {
				layer.msg(jqXHR.responseText, {
					time: 8000,
					offset:  '100px'
				});
			}
		});
	}

	function SubmitOrder(packageid, panelPlan, code, disableactive){
		$.ajax({
			type: "POST",
			url: "/portal/order/create",
			dataType: "json",
			data: {
				packageid : packageid,
				plan: panelPlan,
				code: code,
				renew: 0,
				upgrade: 0,
				disableactive: disableactive
			},
			success: (data) => {
				localStorage.removeItem('coupon');
				if (data.ret == -4) {
					Swal.fire({
						title: '',
						html: data.msg,
						icon: 'error',
						showCancelButton: false,
						showConfirmButton:true,
						confirmButtonText: "{$translate->get('ok')}",
						allowOutsideClick: false,
						customClass: {
						  confirmButton: 'btn btn-secondary ms-1',
						  cancelButton: 'btn btn-danger ms-1'
						},
						buttonsStyling: false
					}).then(function (result) {
						if (result.isConfirmed) {
							window.setTimeout("location.href='/portal/dashboard'", 100);
						}
					});
				}else
				if (data.ret == 1) {
					window.location.href = data.url;
				}else
				if (data.ret == -1) {
					Swal.fire({
						title: '',
						html: data.msg,
						icon: 'info',
						showCancelButton: false,
						showConfirmButton:true,
						confirmButtonText: "{$translate->get('ok')}",
						allowOutsideClick: false,
						customClass: {
						  confirmButton: 'btn btn-secondary ms-1',
						  cancelButton: 'btn btn-danger ms-1'
						},
						buttonsStyling: false
					}).then(function (result) {
						if (result.isConfirmed) {
							window.location.href = data.url;
						}
					});
				}else{
					layer.msg(data.msg, {
						time: 3000,
						offset:  '100px'
					});
				}
			},
			error: (jqXHR) => {
				layer.msg(jqXHR.responseText, {
					time: 8000,
					offset:  '100px'
				});
			}
		});
	}

	function Checkout(){
		var plan =  $("input[name='plan']:checked").val();
		// commission pays for plans: move it into the wallet first, then check out
		if (window.CommissionUse && !window.CommissionUse.passed) {
			window.CommissionUse.before({$package->id}, plan, Checkout);
			return;
		}
		var coupon = localStorage.getItem('coupon');
		if(coupon != null){
			var code = coupon;
		}else{
			var code = "";
		}

		if (ReserveReady()) {
			reservePrepare(plan, code);
			return;
		}

		if (document.getElementById('disableactive').checked) {
			var disableactive = 1;
		} else {
			var disableactive = 0;
		}
		SubmitOrder({$package->id}, plan, code, disableactive);
	}	
</script>
	
	