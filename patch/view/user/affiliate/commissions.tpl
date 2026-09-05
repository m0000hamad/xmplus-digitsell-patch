{literal}
<style>
.cm-card { border: 0; border-radius: 18px; overflow: hidden; }
.cm-card .card-header { background: transparent; }
.cm-total {
	display: inline-flex;
	align-items: center;
	gap: 6px;
	padding: 5px 13px;
	border-radius: 999px;
	font-size: 11.5px;
	font-weight: 700;
	background: rgba(16, 185, 129, .13);
	color: #047857;
}
.cm-list { margin: 0; }
.cm-row {
	display: flex;
	align-items: center;
	gap: 12px;
	padding: 12px 0;
	border-bottom: 1px dashed rgba(23, 32, 61, .08);
}
.cm-row:last-child { border-bottom: 0; }
.cm-ico {
	width: 34px;
	height: 34px;
	flex: 0 0 auto;
	border-radius: 11px;
	display: flex;
	align-items: center;
	justify-content: center;
	font-size: 16px;
	background: rgba(16, 185, 129, .14);
}
.cm-ico.cm-ico-mig { background: rgba(99, 102, 241, .14); }
.cm-ico.cm-ico-pay { background: rgba(14, 165, 233, .16); }
.cm-dest {
	display: inline-block;
	margin-inline-start: 8px;
	font-size: 10px;
	font-weight: 700;
	color: #6366f1;
	background: rgba(99, 102, 241, .1);
	border-radius: 999px;
	padding: 2px 8px;
}
html[data-hs-theme="dark"] .cm-dest { color: #a5b4fc; background: rgba(99, 102, 241, .2); }
.cm-body { flex: 1 1 auto; min-width: 0; }
.cm-title {
	font-size: 13px;
	font-weight: 700;
	color: #16203d;
	margin-bottom: 3px;
	overflow: hidden;
	text-overflow: ellipsis;
	white-space: nowrap;
}
.cm-when {
	font-size: 11px;
	color: #8c98ab;
	font-weight: 600;
	direction: ltr;
	unicode-bidi: isolate;
	display: inline-block;
}
.cm-amount {
	flex: 0 0 auto;
	font-size: 13.5px;
	font-weight: 800;
	color: #047857;
	direction: ltr;
	unicode-bidi: isolate;
	white-space: nowrap;
}
.cm-empty {
	text-align: center;
	padding: 34px 16px;
	color: #97a4af;
	font-size: 12.5px;
}
.cm-empty span { font-size: 30px; display: block; margin-bottom: 8px; opacity: .6; }

html[data-hs-theme="dark"] .cm-title { color: #e7eaf3; }
html[data-hs-theme="dark"] .cm-row { border-bottom-color: rgba(255, 255, 255, .08); }
html[data-hs-theme="dark"] .cm-amount { color: #34d399; }
html[data-hs-theme="dark"] .cm-total { background: rgba(16, 185, 129, .2); color: #6ee7b7; }
html[data-hs-theme="dark"] .cm-when { color: #8b9ab5; }
</style>
{/literal}

<div class="col-12 mb-3 mb-lg-5">
	<div class="card card-shadow shadow-lg rounded cm-card">
		<div class="card-header card-header-content-between border-bottom">
			<h4 class="card-header-title mb-0">💸 {$translate->get('CommissionLog')}</h4>
			<span class="cm-total">{$currency->symbol_left} {number_format((float)$user->commissionCredited(), (int)$currency->decimals)} {$currency->symbol_right}</span>
		</div>

		<div class="card-body">
			{$history = $user->commissionHistory(30)}
			{if count($history) > 0}
				<div class="cm-list">
					{foreach $history as $entry}
						<div class="cm-row">
							<span class="cm-ico{if $entry->source == 'migration'} cm-ico-mig{elseif $entry->destination == 'payout'} cm-ico-pay{/if}">{if $entry->source == 'migration'}🎁{elseif $entry->destination == 'payout'}🏦{else}💰{/if}</span>
							<div class="cm-body">
								<div class="cm-title">
									{if $entry->source == 'migration'}
										{$translate->get('CommissionMigrated')}
									{else}
										{str_replace(['%user%'],[$entry->buyer_username],$translate->get('CommissionFrom'))}
									{/if}
								</div>
								<span class="cm-when">{date('Y-m-d H:i', $entry->datetime)}</span>
								<span class="cm-dest">{if $entry->destination == 'payout'}{$translate->get('WentToPayout')}{else}{$translate->get('WentToWallet')}{/if}</span>
							</div>
							<span class="cm-amount">+ {number_format((float)$entry->amount, (int)$currency->decimals)}</span>
						</div>
					{/foreach}
				</div>
			{else}
				<div class="cm-empty">
					<span>🌱</span>
					{$translate->get('NoCommissionYet')}
				</div>
			{/if}
		</div>
	</div>
</div>
