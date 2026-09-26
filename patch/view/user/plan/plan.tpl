{include file='user/layout/header.tpl'}

{literal}
<style>
.plans-head {
	position: relative;
	border-radius: 20px;
	padding: 22px 24px;
	margin-bottom: 22px;
	overflow: hidden;
	background: linear-gradient(135deg, rgba(99, 102, 241, .13), rgba(139, 92, 246, .13), rgba(6, 182, 212, .13));
	border: 1px solid rgba(99, 102, 241, .18);
}
.plans-head h1 {
	font-size: 21px;
	font-weight: 800;
	color: #16203d;
	margin: 0 0 6px;
}
.plans-head p { font-size: 12.5px; color: #5c6b8a; margin: 0; font-weight: 600; }

.plan-card {
	position: relative;
	height: 100%;
	display: flex;
	flex-direction: column;
	border: 1.5px solid rgba(23, 32, 61, .08);
	border-radius: 20px;
	background: #fff;
	overflow: hidden;
	transition: transform .2s ease, box-shadow .2s ease, border-color .2s ease;
}
.plan-card:hover {
	transform: translateY(-5px);
	border-color: var(--plan, #6366f1);
	box-shadow: 0 18px 40px rgba(23, 32, 61, .13);
}
.plan-card.plan-out { opacity: .62; }
.plan-card.plan-out:hover { transform: none; box-shadow: none; }

/* coloured cap so each plan is instantly distinguishable */
.plan-top {
	position: relative;
	padding: 20px 20px 18px;
	background: linear-gradient(135deg, var(--plan, #6366f1), var(--plan2, #8b5cf6));
	color: #fff;
}
.plan-top::after {
	content: "";
	position: absolute;
	inset-block-start: -40px;
	inset-inline-end: -30px;
	width: 120px;
	height: 120px;
	border-radius: 50%;
	background: rgba(255, 255, 255, .13);
}
.plan-name {
	position: relative;
	font-size: 13.5px;
	font-weight: 700;
	line-height: 1.85;
	margin: 0 0 14px;
	min-height: 50px;
	display: -webkit-box;
	-webkit-line-clamp: 2;
	-webkit-box-orient: vertical;
	overflow: hidden;
}
.plan-price {
	position: relative;
	display: flex;
	align-items: baseline;
	flex-wrap: wrap;
	gap: 6px;
}
.plan-price b {
	font-size: 26px;
	font-weight: 800;
	direction: ltr;
	unicode-bidi: isolate;
	line-height: 1.1;
}
.plan-cur { font-size: 12.5px; font-weight: 700; opacity: .92; }
.plan-cycle {
	position: absolute;
	top: 14px;
	inset-inline-end: 16px;
	z-index: 2;
	font-size: 10px;
	font-weight: 700;
	background: rgba(255, 255, 255, .25);
	border-radius: 999px;
	padding: 4px 10px;
	backdrop-filter: blur(2px);
}

.plan-badges {
	position: absolute;
	top: 12px;
	inset-inline-start: 14px;
	display: flex;
	flex-direction: column;
	gap: 5px;
	z-index: 2;
}
.plan-badge {
	display: inline-flex;
	align-items: center;
	gap: 4px;
	font-size: 9.5px;
	font-weight: 800;
	padding: 3px 9px;
	border-radius: 999px;
	background: #fff;
	color: #16203d;
	box-shadow: 0 3px 10px rgba(23, 32, 61, .18);
	white-space: nowrap;
}
.plan-badge-hot { background: #f43f5e; color: #fff; }
.plan-badge-inf { background: #10b981; color: #fff; }

.plan-body { flex: 1 1 auto; padding: 16px 18px 6px; }
.plan-feature {
	display: flex;
	align-items: center;
	gap: 9px;
	padding: 7px 0;
	font-size: 12.5px;
	color: #3b4a6b;
	border-bottom: 1px dashed rgba(23, 32, 61, .07);
}
.plan-feature:last-child { border-bottom: 0; }
.plan-feature-ico {
	width: 26px;
	height: 26px;
	flex: 0 0 auto;
	border-radius: 9px;
	display: flex;
	align-items: center;
	justify-content: center;
	font-size: 13px;
	background: var(--plan-soft, rgba(99, 102, 241, .11));
}
.plan-feature b { color: #16203d; font-weight: 700; }
.plan-feature.plan-feature-off { color: #97a4af; }
.plan-feature.plan-feature-off .plan-feature-ico { background: rgba(23, 32, 61, .05); }

.plan-foot { padding: 14px 18px 18px; }
.plan-btn {
	display: flex;
	align-items: center;
	justify-content: center;
	gap: 7px;
	width: 100%;
	border: 0;
	border-radius: 13px;
	padding: 12px 16px;
	font-size: 13.5px;
	font-weight: 800;
	line-height: 1.2;
	text-decoration: none !important;
	cursor: pointer;
	color: #fff !important;
	background: linear-gradient(135deg, var(--plan, #6366f1), var(--plan2, #8b5cf6));
	box-shadow: 0 8px 20px var(--plan-glow, rgba(99, 102, 241, .3));
	transition: transform .15s ease, box-shadow .15s ease, filter .15s ease;
}
.plan-btn:hover { transform: translateY(-2px); filter: brightness(1.06); }
.plan-btn-out {
	background: rgba(23, 32, 61, .1) !important;
	color: #7a869f !important;
	box-shadow: none;
	cursor: not-allowed;
}
.plan-btn-out:hover { transform: none; filter: none; }

.plan-empty {
	text-align: center;
	padding: 50px 20px;
	color: #97a4af;
	font-size: 13px;
}

html[data-hs-theme="dark"] .plans-head h1 { color: #e7eaf3; }
html[data-hs-theme="dark"] .plans-head p { color: #9fb0cc; }
html[data-hs-theme="dark"] .plans-head { border-color: rgba(139, 92, 246, .3); }
html[data-hs-theme="dark"] .plan-card {
	background: #18213a;
	border-color: rgba(255, 255, 255, .09);
}
html[data-hs-theme="dark"] .plan-feature { color: #b6c4dc; border-bottom-color: rgba(255, 255, 255, .08); }
html[data-hs-theme="dark"] .plan-feature b { color: #e7eaf3; }
html[data-hs-theme="dark"] .plan-badge { background: #e7eaf3; color: #16203d; }
html[data-hs-theme="dark"] .plan-btn-out { background: rgba(255, 255, 255, .09) !important; color: #8b9ab5 !important; }

@media (max-width: 575.98px) {
	.plans-head { padding: 18px; }
	.plans-head h1 { font-size: 18px; }
	.plan-name { min-height: 0; }
}
</style>
{/literal}
{include file='user/plan/promostyle.tpl'}

<div class="plans-head">
	<h1>🛒 {$translate->get('Plans')}</h1>
	<p>{$translate->get('PlansIntro')}</p>
</div>

<div class="row mb-3">

	{$shown = 0}
	{foreach $packages as $package}
		{if $package->type == 2}
		{$shown = $shown + 1}

		{* a repeating palette so neighbouring cards never share a colour *}
		{$tone = $package@index % 6}
		{if $tone == 0}{$plan = "--plan:#4f46e5;--plan2:#7c3aed;--plan-soft:rgba(99,102,241,.12);--plan-glow:rgba(99,102,241,.34)"}
		{elseif $tone == 1}{$plan = "--plan:#0284c7;--plan2:#0891b2;--plan-soft:rgba(14,165,233,.12);--plan-glow:rgba(14,165,233,.34)"}
		{elseif $tone == 2}{$plan = "--plan:#047857;--plan2:#10b981;--plan-soft:rgba(16,185,129,.12);--plan-glow:rgba(16,185,129,.34)"}
		{elseif $tone == 3}{$plan = "--plan:#c2410c;--plan2:#ea580c;--plan-soft:rgba(245,158,11,.13);--plan-glow:rgba(234,88,12,.34)"}
		{elseif $tone == 4}{$plan = "--plan:#be123c;--plan2:#e11d48;--plan-soft:rgba(244,63,94,.12);--plan-glow:rgba(244,63,94,.34)"}
		{else}{$plan = "--plan:#6d28d9;--plan2:#9333ea;--plan-soft:rgba(139,92,246,.12);--plan-glow:rgba(139,92,246,.34)"}
		{/if}

		{$option = json_decode($package->price_option,true)}
		{$outofstock = ($package->stocks == 1 && $package->stockcount <= 0)}
		{$promo = $timeplan->promo($package->id)}

		{* the cycle whose price the card shows: the first one that has a price *}
		{$cyc = ''}
		{foreach ['onetime', 'month', 'quater', 'semiannual', 'annual', 'custom'] as $c}
			{if $cyc == '' && isset($option[$c]['price']) && $option[$c]['price'] != ""}{$cyc = $c}{/if}
		{/foreach}
		{$was = false}
		{if $promo && $promo.kind == 'discount' && $cyc != '' && isset($promo.original[$cyc]) && $promo.original[$cyc] > (float)$option[$cyc]['price']}
			{$was = $promo.original[$cyc]}
		{/if}

		<div class="col-xl-3 col-lg-4 col-md-6 col-sm-12 mb-4">
			<div class="plan-card{if $outofstock} plan-out{/if}{if $promo} is-promo{/if}" style="{$plan}"{if $promo} data-promo-scope{/if}>

				{capture name=badges}
					{if $package->bandwidth >= 10000}
						<span class="plan-badge plan-badge-inf">♾️ {$translate->get('Unlimited')}</span>
					{/if}
					{if $package->stocks == 1 && $package->stockcount > 0 && $package->stockcount <= 5}
						<span class="plan-badge plan-badge-hot">🔥 {$package->stockcount} {$translate->get('LeftInStock')}</span>
					{/if}
					{if $promo}{include file='user/plan/promobadges.tpl' nokind=1}{/if}
				{/capture}

				{if !$promo}
					<div class="plan-badges">{$smarty.capture.badges}</div>
				{/if}

				<div class="plan-top">
					{* with a promotion the badges line up above the name instead of floating over it *}
					{if $promo}
						{if trim($smarty.capture.badges) != ''}
							<div class="plan-badges plan-badges-flow">{$smarty.capture.badges}</div>
						{/if}
						{include file='user/plan/promosticker.tpl'}
					{/if}
					<span class="plan-cycle">
						{if isset($option['onetime']['price']) && $option['onetime']['price'] != ""}{$translate->get('Onetime')}
						{elseif isset($option['month']['price']) && $option['month']['price'] != ""}{$translate->get('Monthly')}
						{else if isset($option['quater']['price']) && $option['quater']['price'] != ""}{$translate->get('Quaterly')}
						{else if isset($option['semiannual']['price']) && $option['semiannual']['price'] != ""}{$translate->get('SemiAnnually')}
						{else if isset($option['annual']['price']) && $option['annual']['price'] != ""}{$translate->get('Annually')}
						{else if isset($option['custom']['price']) && $option['custom']['price'] != ""}{$translate->get('Custom')}
						{/if}
					</span>
					<h6 class="plan-name">{$package->name}</h6>
					{if $was}
						<div class="plan-price plan-price-was">
							<span class="promo-was">{$currency->symbol_left} {number_format((float)$was, (int){$currency->decimals})} {$currency->symbol_right}</span>
							<span class="promo-off promo-only">{$translate->get('PromoOffLabel')|replace:'%n%':$promo.percent}</span>
						</div>
					{/if}
					<div class="plan-price{if $was} promo-only{/if}">
						{if $currency->symbol_left != ""}<span class="plan-cur">{$currency->symbol_left}</span>{/if}
						<b>{if $cyc != ''}{number_format((float)$option[$cyc]['price'], (int){$currency->decimals})}{/if}</b>
						{if $currency->symbol_right != ""}<span class="plan-cur">{$currency->symbol_right}</span>{/if}
					</div>
				</div>

				<div class="plan-body">
					<div class="plan-feature">
						<span class="plan-feature-ico">📶</span>
						<span>{$translate->get('Bandwidth')}: <b>{if $package->bandwidth < 10000}{$package->bandwidth} GB{else}{$translate->get('Unlimited')}{/if}</b></span>
					</div>
					<div class="plan-feature">
						<span class="plan-feature-ico">⚡</span>
						<span>{$translate->get('PortSpeed')}: <b>{$helpers->PortSpd($package->speedlimit)}</b></span>
					</div>
					<div class="plan-feature">
						<span class="plan-feature-ico">👥</span>
						<span>{$translate->get('ConnLimit')}: <b>{$package->iplimit}</b></span>
					</div>
					<div class="plan-feature">
						<span class="plan-feature-ico">🌍</span>
						<span>{$translate->get('ServerGroup')}: <b>{str_replace([' | '],[' '],$helpers->serveGroup($package->server_group))}</b></span>
					</div>
					{if $package->reset_days > 0}
						<div class="plan-feature">
							<span class="plan-feature-ico">🔄</span>
							<span>{$translate->get('AllowReset')}: <b>{$translate->get('Every')}{$package->reset_days} {$translate->get('Days')}</b></span>
						</div>
					{else}
						<div class="plan-feature plan-feature-off">
							<span class="plan-feature-ico">🚫</span>
							<span>{$translate->get('AllowReset')}: <b>{$translate->get('None')}</b></span>
						</div>
					{/if}
				</div>

				{if $promo && ($promo.occasion != '' || $promo.prize != '' || $promo.ends_at > 0 || $promo.left !== null)}
					<div class="promo-strip promo-only">
						{include file='user/plan/promostrip.tpl'}
					</div>
				{/if}

				<div class="plan-foot">
					{if $outofstock}
						<a class="plan-btn plan-btn-out">😴 {$translate->get('NoStock')}</a>
					{else}
						<a href="/portal/plan/details?id={$package->id}" class="plan-btn">🚀 {$translate->get('SelectPlan')}</a>
					{/if}
				</div>

			</div>
		</div>
		{/if}
	{/foreach}

	{if $shown == 0}
		<div class="col-12"><div class="plan-empty">{$translate->get('NoPlansYet')}</div></div>
	{/if}

</div>
{include file='user/layout/footer.tpl'}
