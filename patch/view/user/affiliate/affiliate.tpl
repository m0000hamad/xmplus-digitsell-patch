{if $Config['rebate'] == 0}
   <script>window.location.href="/portal/dashboard"</script>
{/if}
{include file='user/layout/header.tpl'}

{literal}
<style>
.af-hero {
	position: relative;
	border-radius: 20px;
	padding: 20px 22px;
	margin-bottom: 18px;
	overflow: hidden;
	background: linear-gradient(135deg, rgba(99, 102, 241, .14), rgba(139, 92, 246, .14), rgba(16, 185, 129, .12));
	border: 1px solid rgba(99, 102, 241, .18);
}
.af-hero h1 { font-size: 20px; font-weight: 800; color: #16203d; margin: 0 0 5px; }
.af-hero p { font-size: 12.5px; color: #5c6b8a; margin: 0; font-weight: 600; }

.af-tabs {
	display: inline-flex;
	padding: 4px;
	gap: 3px;
	border-radius: 999px;
	background: rgba(255, 255, 255, .72);
	margin-top: 14px;
	flex-wrap: wrap;
}
.af-tab {
	border: 0;
	background: transparent;
	color: #5c6b8a;
	font-size: 12.5px;
	font-weight: 700;
	line-height: 1;
	padding: 9px 16px;
	border-radius: 999px;
	cursor: pointer;
	white-space: nowrap;
	transition: background .16s ease, color .16s ease, box-shadow .16s ease;
}
.af-tab:hover { color: #4f46e5; }
.af-tab.active {
	background: linear-gradient(135deg, #4f46e5, #7c3aed);
	color: #fff;
	box-shadow: 0 5px 14px rgba(99, 102, 241, .34);
}

.af-link-card {
	border: 0;
	border-radius: 18px;
	overflow: hidden;
	background: linear-gradient(135deg, #4f46e5, #7c3aed);
	color: #fff;
	padding: 22px;
	position: relative;
}
.af-link-card::after {
	content: "";
	position: absolute;
	inset-block-start: -50px;
	inset-inline-end: -40px;
	width: 170px;
	height: 170px;
	border-radius: 50%;
	background: rgba(255, 255, 255, .1);
}
.af-link-head {
	position: relative;
	display: flex;
	align-items: center;
	gap: 8px;
	font-size: 13.5px;
	font-weight: 800;
	margin-bottom: 4px;
}
.af-link-note { position: relative; font-size: 11.5px; opacity: .88; margin-bottom: 14px; font-weight: 600; }
.af-link-row { position: relative; display: flex; gap: 8px; flex-wrap: wrap; }
.af-link-field {
	flex: 1 1 240px;
	min-width: 0;
	font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
	font-size: 12px;
	direction: ltr;
	background: rgba(255, 255, 255, .95);
	border: 0;
	border-radius: 11px;
	padding: 11px 13px;
	color: #3b4a6b;
}
.af-btn {
	display: inline-flex;
	align-items: center;
	justify-content: center;
	gap: 6px;
	border: 0;
	border-radius: 11px;
	padding: 11px 16px;
	font-size: 12.5px;
	font-weight: 800;
	line-height: 1.2;
	cursor: pointer;
	text-decoration: none !important;
	white-space: nowrap;
	transition: transform .14s ease, filter .14s ease;
}
.af-btn:hover { transform: translateY(-1px); filter: brightness(1.05); }
.af-btn-copy { background: #fff; color: #4f46e5 !important; }
.af-btn-reset { background: rgba(255, 255, 255, .22); color: #fff !important; }

/* ---- withdrawal ---- */
.af-cash {
	border-radius: 18px;
	padding: 18px;
	border: 1.5px dashed rgba(16, 185, 129, .4);
	background: linear-gradient(135deg, rgba(16, 185, 129, .09), rgba(6, 182, 212, .09));
}
.af-cash.af-cash-locked {
	border-color: rgba(148, 163, 184, .45);
	background: rgba(148, 163, 184, .09);
}
.af-cash-head { display: flex; align-items: center; gap: 8px; font-size: 13px; font-weight: 800; color: #16203d; margin-bottom: 4px; }
.af-cash-amount {
	font-size: 22px;
	font-weight: 800;
	color: #047857;
	direction: ltr;
	unicode-bidi: isolate;
	text-align: start;
	margin-bottom: 4px;
}
.af-cash-locked .af-cash-amount { color: #64748b; }
.af-cash-note { font-size: 11.5px; font-weight: 600; color: #5c6b8a; margin-bottom: 13px; }
.af-cash-actions { display: flex; gap: 8px; flex-wrap: wrap; }
.af-btn-cash { background: linear-gradient(135deg, #059669, #10b981); color: #fff !important; box-shadow: 0 7px 18px rgba(16, 185, 129, .3); }
.af-btn-cash[disabled] {
	background: rgba(23, 32, 61, .12) !important;
	color: #8c98ab !important;
	box-shadow: none;
	cursor: not-allowed;
}
.af-btn-cash[disabled]:hover { transform: none; filter: none; }
.af-btn-hist { background: rgba(23, 32, 61, .08); color: #16203d !important; }
.af-progress { height: 6px; border-radius: 999px; background: rgba(23, 32, 61, .1); overflow: hidden; margin-bottom: 11px; }
.af-progress span { display: block; height: 100%; border-radius: 999px; background: linear-gradient(90deg, #059669, #10b981); }

/* ---- who earned what ---- */
.af-ref-row {
	display: flex;
	align-items: center;
	gap: 12px;
	padding: 11px 0;
	border-bottom: 1px dashed rgba(23, 32, 61, .08);
}
.af-ref-row:last-child { border-bottom: 0; }
.af-ref-rank {
	width: 30px;
	height: 30px;
	flex: 0 0 auto;
	border-radius: 10px;
	display: flex;
	align-items: center;
	justify-content: center;
	font-size: 12px;
	font-weight: 800;
	color: #fff;
}
.af-ref-body { flex: 1 1 auto; min-width: 0; }
.af-ref-name {
	font-size: 13px;
	font-weight: 700;
	color: #16203d;
	overflow: hidden;
	text-overflow: ellipsis;
	white-space: nowrap;
}
.af-ref-meta { font-size: 11px; color: #8c98ab; font-weight: 600; margin-top: 2px; }
.af-ref-meta time { direction: ltr; unicode-bidi: isolate; }
.af-ref-total {
	flex: 0 0 auto;
	font-size: 13.5px;
	font-weight: 800;
	color: #047857;
	direction: ltr;
	unicode-bidi: isolate;
	white-space: nowrap;
}
.af-rules {
	margin-top: 14px;
	border-radius: 15px;
	padding: 15px 17px;
	background: rgba(99, 102, 241, .07);
	border: 1px solid rgba(99, 102, 241, .2);
}
.af-rules-title { font-size: 12.5px; font-weight: 800; color: #16203d; margin-bottom: 9px; }
.af-rules-list {
	margin: 0;
	padding-inline-start: 18px;
	font-size: 11.5px;
	line-height: 2.1;
	color: #3b4a6b;
	font-weight: 600;
}
.af-rules-list li::marker { color: #6366f1; font-weight: 800; }
html[data-hs-theme="dark"] .af-rules {
	background: rgba(99, 102, 241, .13);
	border-color: rgba(99, 102, 241, .3);
}
html[data-hs-theme="dark"] .af-rules-title { color: #e7eaf3; }
html[data-hs-theme="dark"] .af-rules-list { color: #b6c4dc; }

.af-empty { text-align: center; padding: 34px 16px; color: #97a4af; font-size: 12.5px; }
.af-empty span { font-size: 30px; display: block; margin-bottom: 8px; opacity: .6; }

html[data-hs-theme="dark"] .af-hero h1 { color: #e7eaf3; }
html[data-hs-theme="dark"] .af-hero p { color: #9fb0cc; }
html[data-hs-theme="dark"] .af-tabs { background: rgba(255, 255, 255, .07); }
html[data-hs-theme="dark"] .af-tab { color: #9fb0cc; }
html[data-hs-theme="dark"] .af-cash-head,
html[data-hs-theme="dark"] .af-ref-name { color: #e7eaf3; }
html[data-hs-theme="dark"] .af-cash-amount { color: #34d399; }
html[data-hs-theme="dark"] .af-cash-locked .af-cash-amount { color: #94a3b8; }
html[data-hs-theme="dark"] .af-cash-note { color: #9fb0cc; }
html[data-hs-theme="dark"] .af-ref-row { border-bottom-color: rgba(255, 255, 255, .08); }
html[data-hs-theme="dark"] .af-btn-hist { background: rgba(255, 255, 255, .1); color: #e7eaf3 !important; }
html[data-hs-theme="dark"] .af-progress { background: rgba(255, 255, 255, .1); }
html[data-hs-theme="dark"] .af-btn-cash[disabled] { background: rgba(255, 255, 255, .09) !important; color: #8b9ab5 !important; }

@media (max-width: 575.98px) {
	.af-tab { padding: 8px 12px; font-size: 11.5px; }
	.af-btn { width: 100%; }
	.af-link-field { flex: 1 1 100%; }
}
</style>
{/literal}

<div class="af-hero">
	<h1>🤝 {$translate->get('Invitation')}</h1>
	<p>{str_replace(['%percent%'],[$Config['commission']],$translate->get('AffiliateIntro'))}</p>

	<div class="af-tabs" id="afTabs">
		<button type="button" class="af-tab active" data-pane="invite">🔗 {$translate->get('Invitation')}</button>
		<button type="button" class="af-tab" data-pane="commission">💸 {$translate->get('MyCommission')}</button>
	</div>
</div>

<!-- ============================ invite ============================ -->
<div id="pane-invite">

	<div class="row mb-3">
		<div class="col-12">
			<div class="af-link-card">
				<div class="af-link-head">🔗 {$translate->get('ReferralLink')}</div>
				<div class="af-link-note">{$translate->get('ReferralLinkNote')}</div>
				<div class="af-link-row">
					<input readonly type="text" class="af-link-field copy-text" id="invitelink" onclick="this.select()" data-clipboard-text="{$helpers->InviteUrl()}/register?aff={$user->afflink}" value="{$helpers->InviteUrl()}/register?aff={$user->afflink}">
					<button type="button" class="af-btn af-btn-copy copy-text" data-clipboard-text="{$helpers->InviteUrl()}/register?aff={$user->afflink}">
						📋 {$translate->get('CopyInviteLink')}
					</button>
					<a class="af-btn af-btn-reset" onClick="resetLink()" data-bs-placement="top" data-bs-toggle="tooltip" title="{$translate->get('resetLink')}">
						🔄 {$translate->get('resetLink')}
					</a>
				</div>
			</div>
		</div>
	</div>

	<div class="row mb-3">
		<div class="col-12">
			<div class="card card-shadow shadow-lg rounded">
				<div class="card-header card-header-content-between border-bottom">
					<h4 class="card-header-title mb-0">📣 {$translate->get('InviteShareTitle')}</h4>
				</div>
				<div class="card-body">
					{include file='user/affiliate/inviteinsight.tpl'}
					{include file='user/affiliate/sharebar.tpl' shareEditable=1}
				</div>
			</div>
		</div>
	</div>

	<div class="row match-height">
		{include file='user/affiliate/datatable.tpl'}
	</div>

</div>

<!-- ========================== commission ========================== -->
<div id="pane-commission" hidden>

	<div class="row match-height">
		{include file='user/affiliate/stats.tpl'}
	</div>

	<div class="row mb-3">
		<div class="col-12">
			{$canWithdraw = $user->canWithdraw()}
			<div class="af-cash{if !$canWithdraw} af-cash-locked{/if}">
				<div class="af-cash-head">🏦 {$translate->get('WithdrawalAmt')}</div>
				<div class="af-cash-amount">{$currency->symbol_left} {number_format((float)$user->payout_balance, (int)$currency->decimals)} {$currency->symbol_right}</div>

				{if $canWithdraw}
					<div class="af-cash-note">{$translate->get('WithdrawReady')}</div>
				{else}
					{$blockReason = $user->withdrawBlockReason()}
					{if $blockReason == 'inactive'}
						<div class="af-cash-note">&#9888;&#65039; {$translate->get('WithdrawNeedActive')}</div>
					{elseif $blockReason == 'gap'}
						<div class="af-cash-note">&#9888;&#65039; {str_replace(['%days%','%gap%'],[$user->withdrawMaxGapDays(),$user->subscriptionGapDays()],$translate->get('WithdrawGapBlocked'))}</div>
					{/if}
					<div class="af-progress">
						<span style="width:{if $user->minWithdrawal() > 0}{$user->payout_balance / $user->minWithdrawal() * 100}{else}0{/if}%"></span>
					</div>
					<div class="af-cash-note">
						{str_replace(['%amount%'],[{number_format((float)$user->withdrawalShortfall(), (int)$currency->decimals)}],$translate->get('WithdrawShortfall'))}
						&nbsp;·&nbsp;
						{str_replace(['%amount%'],[{number_format((float)$user->minWithdrawal(), (int)$currency->decimals)}],$translate->get('MinWithdrawal'))}
					</div>
				{/if}

				<div class="af-cash-actions">
					{if $Config['payouts'] == 1}
						<button type="button" class="af-btn af-btn-cash" {if $canWithdraw}data-bs-toggle="modal" data-bs-target="#withdrawal"{else}disabled{/if}>
							💰 {$translate->get('Withdraw')}
						</button>
						<a class="af-btn af-btn-hist" href="/portal/withdrawals">📄 {$translate->get('Payouts')}</a>
					{/if}
				</div>
			</div>

			<div class="af-rules">
				<div class="af-rules-title">📜 {$translate->get('WithdrawRulesTitle')}</div>
				<ol class="af-rules-list">
					<li>{str_replace(['%amount%'],[{number_format((float)$user->minWithdrawal(), (int)$currency->decimals)}],$translate->get('WithdrawRule1'))}</li>
					<li>{$translate->get('WithdrawRule2')}</li>
					<li>{str_replace(['%days%'],[$user->withdrawMaxGapDays()],$translate->get('WithdrawRule3'))}</li>
					<li>{$translate->get('WithdrawRule4')}</li>
				</ol>
			</div>
		</div>
	</div>

	<div class="row mb-3">
		<div class="col-12">
			<div class="card card-shadow shadow-lg rounded cm-card">
				<div class="card-header card-header-content-between border-bottom">
					<h4 class="card-header-title mb-0">👥 {$translate->get('CommissionByUser')}</h4>
				</div>
				<div class="card-body">
					{$byref = $user->commissionByReferral()}
					{if count($byref) > 0}
						{$rank = 0}
						{foreach $byref as $ref}
						{$rank = $rank + 1}
						{$tone = $rank % 6}
							<div class="af-ref-row">
								<span class="af-ref-rank" style="background:{if $tone == 1}#4f46e5{elseif $tone == 2}#0284c7{elseif $tone == 3}#047857{elseif $tone == 4}#c2410c{elseif $tone == 5}#be123c{else}#6d28d9{/if}">{$rank}</span>
								<div class="af-ref-body">
									<div class="af-ref-name">{$ref->username}</div>
									<div class="af-ref-meta">
										{str_replace(['%count%'],[$ref->purchases],$translate->get('PurchaseCount'))}
										&nbsp;·&nbsp; <time>{date('Y-m-d', $ref->last_at)}</time>
									</div>
								</div>
								<span class="af-ref-total">{number_format((float)$ref->total, (int)$currency->decimals)}</span>
							</div>
						{/foreach}
					{else}
						<div class="af-empty"><span>🌱</span>{$translate->get('NoCommissionYet')}</div>
					{/if}
				</div>
			</div>
		</div>
	</div>

	<div class="row match-height">
		{include file='user/affiliate/commissions.tpl'}
	</div>

</div>

{include file='user/affiliate/widthdraw.tpl'}

{include file='user/layout/footer.tpl'}
<script>
    {include file='table/table_storage.tpl'}
	{include file='table/table_desc.tpl'}
		
	function resetLink(){
		$.ajax({
			type: "POST",
			url: "/portal/affiliate/resetlink",
			dataType: "json",
			data: {},	
			success: data => {
				if (data.ret == 1) {
					$("#invitelink").val(data.link);
					layer.msg(data.msg, {
						time: 3000,
						offset:  '100px'
					});
					window.setTimeout("location.href='/portal/affiliate'", 2000);
				}else{
					layer.msg(data.msg, {
						time: 5000,
						offset:  '100px'
					});
				}
			},
			error: jqXHR => {
				layer.msg(jqXHR.responseText, {
					time: 8000,
					offset: '100px'
				});
			}
		})
	}
	
    function Account(){
		var withdrawal_method = $("input[name='withdrawal_method']:checked").val();
		if(withdrawal_method == "{$translate->get('Account')}"){
			$("#withdrawal_account").val("{$user->email}");
		}else{
			$("#withdrawal_account").val('');
		}
    }
	
	Account();
	
	$('#WidthdrawNow').click(function(e) {
		var me = $(this);
		e.preventDefault();
		if ( me.data('requestRunning') ) {
			return;
		}
		me.data('requestRunning', true);
		
		var withdrawal_account = window.buildWithdrawalAccount();
		if (!withdrawal_account) {
			me.data('requestRunning', false);
			return;
		}

		layer.load(2);
		$.ajax({
			type: "POST",
			url: "/portal/affiliate/widthdraw",
			dataType: "json",
			data: {
				withdrawal_amount: {$user->payout_balance},
				withdrawal_account: withdrawal_account,
				withdrawal_method: window.withdrawalMethod(),
			},
			success: data => {
				layer.closeAll('loading');
				if (data.ret == 1) {
					layer.msg(data.msg, {
						time: 3000,
						offset: '100px'
					});
					$("#withdrawal").modal('hide');
					window.setTimeout("location.href='/portal/withdrawals'", 1500);
				}else{
					layer.msg(data.msg, {
						time: 3000,
						offset: '100px'
					});
				}
			},
			error: jqXHR => {
				layer.closeAll('loading');
				layer.msg(jqXHR.responseText, {
					time: 8000,
					offset: '100px'
				});
			},
			complete: () => {
				me.data('requestRunning', false);
				return;
			}
		})
	})	
</script>

{literal}
<script>
/*
 * Two views share this one route - the panel's routing table is encoded, so the
 * "commission" menu entry points at #commission on this same page.
 */
(function () {
	var box = document.getElementById('afTabs');
	if (!box) { return; }

	function show(name) {
		var panes = { invite: document.getElementById('pane-invite'),
		              commission: document.getElementById('pane-commission') };
		if (!panes[name]) { name = 'invite'; }

		panes.invite.hidden = name !== 'invite';
		panes.commission.hidden = name !== 'commission';

		var buttons = box.querySelectorAll('.af-tab');
		for (var i = 0; i < buttons.length; i++) {
			buttons[i].classList.toggle('active', buttons[i].getAttribute('data-pane') === name);
		}

		if (window.table_1 && name === 'invite') {
			// the table was laid out while hidden, so its widths are wrong
			try { window.table_1.columns.adjust(); } catch (e) {}
		}
	}

	box.addEventListener('click', function (event) {
		var button = event.target.closest('.af-tab');
		if (!button) { return; }
		var name = button.getAttribute('data-pane');
		show(name);
		if (history.replaceState) { history.replaceState(null, '', '#' + name); }
	});

	show((location.hash || '').replace('#', '') || 'invite');
	window.addEventListener('hashchange', function () {
		show((location.hash || '').replace('#', '') || 'invite');
	});
})();
</script>
{/literal}
