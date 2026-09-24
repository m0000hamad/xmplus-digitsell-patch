{*
 * The panel "talking" to the visitor about their own invite numbers, as a few
 * chat bubbles that appear one after another. Numbers come from
 * User::inviteInsight(); used in the dashboard invite popup and on the
 * affiliate page. With insLead=1 the first bubble is left empty for the popup
 * to fill with its stage message.
 *}
{$ins = $user->inviteInsight()}
{$insMoney = "{$currency->symbol_left} %s {$currency->symbol_right}"}

{literal}
<style>
.ivi { display: flex; gap: 10px; align-items: flex-start; text-align: start; margin: 0 0 6px; }
.ivi-ava {
	flex: 0 0 34px;
	width: 34px;
	height: 34px;
	border-radius: 50%;
	display: flex;
	align-items: center;
	justify-content: center;
	font-size: 15px;
	color: #fff;
	background: linear-gradient(135deg, #fb923c, #ec4899);
	box-shadow: 0 6px 14px -6px rgba(236, 72, 153, .7);
}
.ivi-lines { flex: 1 1 auto; min-width: 0; display: flex; flex-direction: column; gap: 6px; }
.ivi-name { font-size: 11px; font-weight: 700; color: #ea580c; margin-bottom: 1px; }
.ivi-b {
	align-self: flex-start;
	max-width: 100%;
	padding: 8px 12px;
	border-radius: 16px;
	border-start-start-radius: 5px;
	background: rgba(249, 115, 22, .09);
	color: #3b4459;
	font-size: 12.5px;
	font-weight: 400;
	line-height: 1.85;
	opacity: 0;
	transform: translateY(6px);
	animation: ivi-in .35s ease forwards;
}
.ivi-b + .ivi-b { border-start-start-radius: 16px; }
.ivi-b b { font-weight: 700; color: #c2410c; }
.ivi-b:nth-of-type(2) { animation-delay: .5s; }
.ivi-b:nth-of-type(3) { animation-delay: 1.1s; }
.ivi-b:nth-of-type(4) { animation-delay: 1.7s; }
.ivi-b:nth-of-type(5) { animation-delay: 2.3s; }
.ivi-lead { color: #1e2436; font-weight: 500; }
html[data-hs-theme="dark"] .ivi-lead { color: #eef1f7; }
@keyframes ivi-in { to { opacity: 1; transform: none; } }
html[data-hs-theme="dark"] .ivi-b { background: rgba(251, 146, 60, .12); color: #d5dbe8; }
html[data-hs-theme="dark"] .ivi-b b { color: #fdba74; }
html[data-hs-theme="dark"] .ivi-name { color: #fdba74; }
@media (prefers-reduced-motion: reduce) { .ivi-b { animation: none; opacity: 1; transform: none; } }
</style>
{/literal}

<div class="ivi">
	<span class="ivi-ava"><i class="fa-solid fa-headset"></i></span>
	<div class="ivi-lines">
		<div class="ivi-name">{$translate->get('InsightName')}</div>
		{if isset($insLead) && $insLead}
			<div class="ivi-b ivi-lead" data-ivp-msg></div>
		{/if}
		{if $ins['invited'] > 0}
			<div class="ivi-b">{str_replace(['%invited%','%buyers%','%earned%'],[$ins['invited'],$ins['buyers'],sprintf($insMoney, number_format($ins['earned'], (int)$currency->decimals))],$translate->get('InsightStats'))}</div>
		{else}
			<div class="ivi-b">{$translate->get('InsightNone')}</div>
		{/if}
		{if $ins['ask'] > 0 && $ins['per_buy'] > 0}
			{if $ins['ask'] < $ins['idle']}{$insIdleKey = 'InsightIdle'}{else}{$insIdleKey = 'InsightIdleAll'}{/if}
			<div class="ivi-b">{str_replace(['%ask%','%idle%','%potential%'],[$ins['ask'],$ins['idle'],sprintf($insMoney, number_format($ins['potential'], (int)$currency->decimals))],$translate->get($insIdleKey))}</div>
		{/if}
		{if $ins['per_buy'] > 0}
			<div class="ivi-b">{str_replace(['%percent%','%per%'],[$Config['commission'],sprintf($insMoney, number_format($ins['per_buy'], (int)$currency->decimals))],$translate->get('InsightPerBuy'))}</div>
		{/if}
	</div>
</div>
