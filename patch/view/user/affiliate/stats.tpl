{literal}
<style>
.aff-grid {
	display: grid;
	grid-template-columns: repeat(auto-fit, minmax(190px, 1fr));
	gap: 14px;
}
.aff-tile {
	position: relative;
	border-radius: 18px;
	padding: 18px;
	overflow: hidden;
	background: #fff;
	border: 1px solid rgba(23, 32, 61, .07);
}
.aff-tile::before {
	content: "";
	position: absolute;
	inset: 0 0 auto 0;
	height: 84px;
	background: linear-gradient(135deg, var(--aff, #6366f1), var(--aff2, #8b5cf6));
	opacity: .12;
}
.aff-tile::after {
	content: "";
	position: absolute;
	inset: auto 0 0 0;
	height: 3px;
	background: linear-gradient(90deg, var(--aff, #6366f1), var(--aff2, #8b5cf6));
}
.aff-tile-head {
	position: relative;
	display: flex;
	align-items: center;
	gap: 8px;
	font-size: 12px;
	font-weight: 700;
	color: #5c6b8a;
	margin-bottom: 10px;
}
.aff-tile-emoji {
	width: 30px;
	height: 30px;
	border-radius: 10px;
	display: flex;
	align-items: center;
	justify-content: center;
	font-size: 15px;
	background: #fff;
	box-shadow: 0 3px 10px rgba(23, 32, 61, .12);
}
.aff-tile-value {
	position: relative;
	font-size: 22px;
	font-weight: 800;
	color: #16203d;
	line-height: 1.3;
	direction: ltr;
	unicode-bidi: isolate;
	text-align: start;
}
.aff-tile-note {
	position: relative;
	font-size: 11px;
	font-weight: 600;
	color: #8c98ab;
	margin-top: 5px;
}

html[data-hs-theme="dark"] .aff-tile {
	background: rgba(255, 255, 255, .04);
	border-color: rgba(255, 255, 255, .08);
}
html[data-hs-theme="dark"] .aff-tile-value { color: #e7eaf3; }
html[data-hs-theme="dark"] .aff-tile-head { color: #9fb0cc; }
html[data-hs-theme="dark"] .aff-tile-emoji { background: rgba(255, 255, 255, .1); box-shadow: none; }
</style>
{/literal}

<div class="col-12 mb-3">
	<div class="aff-grid">

		<div class="aff-tile" style="--aff:#6366f1;--aff2:#8b5cf6">
			<div class="aff-tile-head"><span class="aff-tile-emoji">🤝</span>{$translate->get('Referrals')}</div>
			<div class="aff-tile-value">{$referrals}</div>
			<div class="aff-tile-note">{$translate->get('ReferralsNote')}</div>
		</div>

		<div class="aff-tile" style="--aff:#059669;--aff2:#10b981">
			<div class="aff-tile-head"><span class="aff-tile-emoji">💸</span>{$translate->get('CommissionPaid')}</div>
			<div class="aff-tile-value">{$currency->symbol_left} {number_format((float)$user->commissionCredited(), (int)$currency->decimals)} {$currency->symbol_right}</div>
			<div class="aff-tile-note">{$translate->get('CommissionPaidNote')}</div>
		</div>

		<div class="aff-tile" style="--aff:#0284c7;--aff2:#0891b2">
			<div class="aff-tile-head"><span class="aff-tile-emoji">👛</span>{$translate->get('SettleAmt')}</div>
			<div class="aff-tile-value">{$currency->symbol_left} {number_format((float)$user->payout_balance, (int)$currency->decimals)} {$currency->symbol_right}</div>
			<div class="aff-tile-note">{$translate->get('SettleAmtNote')}</div>
		</div>

		<div class="aff-tile" style="--aff:#c2410c;--aff2:#ea580c">
			<div class="aff-tile-head"><span class="aff-tile-emoji">🎯</span>{$translate->get('RebatePer')}</div>
			<div class="aff-tile-value">{$Config['commission']} %</div>
			<div class="aff-tile-note">{$translate->get('RebatePerNote')}</div>
		</div>

	</div>
</div>
