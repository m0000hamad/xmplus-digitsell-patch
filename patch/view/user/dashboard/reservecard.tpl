{*
  The reserved plan this account is waiting on (app/Patch/Reserve.php and
  app/Jobs/ReserveJob.php). Included from subsciption.tpl. Renders nothing when
  there is no paid reservation, so the card stays out of the way for everyone
  else.
*}
{assign var=reserveRow value=$user->planReserveWaiting()}
{if $reserveRow}
{literal}
<style>
.sub-reserve {
	margin-top: 14px;
	border-radius: 16px;
	border: 1.5px solid rgba(99, 102, 241, .3);
	overflow: hidden;
	background: linear-gradient(135deg, rgba(99, 102, 241, .1), rgba(6, 182, 212, .1));
}
.sub-reserve-head {
	display: flex;
	align-items: center;
	gap: 10px;
	padding: 12px 14px;
	border-bottom: 1px dashed rgba(99, 102, 241, .3);
}
.sub-reserve-emoji {
	flex: 0 0 auto;
	width: 34px;
	height: 34px;
	border-radius: 11px;
	background: rgba(99, 102, 241, .18);
	display: inline-flex;
	align-items: center;
	justify-content: center;
	font-size: 17px;
}
.sub-reserve-title { flex: 1 1 auto; min-width: 0; font-size: 13px; font-weight: 800; color: #16203d; line-height: 1.6; }
.sub-reserve-badge {
	flex: 0 0 auto;
	font-size: 10px;
	font-weight: 800;
	padding: 4px 9px;
	border-radius: 999px;
	color: #4338ca;
	background: rgba(99, 102, 241, .16);
	white-space: nowrap;
}
.sub-reserve-body { padding: 12px 14px; }
.sub-reserve-plan { font-size: 13px; font-weight: 800; color: #16203d; margin-bottom: 9px; line-height: 1.7; }
.sub-reserve-chips { display: flex; flex-wrap: wrap; gap: 6px; }
.sub-reserve-chip {
	display: inline-flex;
	align-items: center;
	gap: 5px;
	font-size: 11.5px;
	font-weight: 600;
	color: #3b4a6b;
	background: rgba(255, 255, 255, .6);
	border-radius: 9px;
	padding: 4px 9px;
}
.sub-reserve-chip b { direction: ltr; unicode-bidi: isolate; color: #16203d; font-weight: 700; }
.sub-reserve-note { margin-top: 10px; font-size: 11px; line-height: 1.9; color: #5c6b8a; }
.sub-reserve-foot { padding: 0 14px 13px; }
.sub-reserve-cancel {
	width: 100%;
	border: 0;
	cursor: pointer;
	border-radius: 11px;
	padding: 9px 14px;
	font-size: 12.5px;
	font-weight: 800;
	color: #be123c;
	background: rgba(244, 63, 94, .13);
	transition: background .15s ease;
}
.sub-reserve-cancel:hover { background: rgba(244, 63, 94, .22); }
html[data-hs-theme="dark"] .sub-reserve {
	background: linear-gradient(135deg, rgba(99, 102, 241, .2), rgba(6, 182, 212, .12));
}
html[data-hs-theme="dark"] .sub-reserve-title,
html[data-hs-theme="dark"] .sub-reserve-plan,
html[data-hs-theme="dark"] .sub-reserve-chip b { color: #e7eaf3; }
html[data-hs-theme="dark"] .sub-reserve-chip { background: rgba(255, 255, 255, .07); color: #cbd5e1; }
html[data-hs-theme="dark"] .sub-reserve-note { color: #9fb0cc; }
html[data-hs-theme="dark"] .sub-reserve-cancel { color: #fda4af; background: rgba(244, 63, 94, .2); }
</style>
{/literal}

<div class="sub-reserve">
	<div class="sub-reserve-head">
		<span class="sub-reserve-emoji">🗓️</span>
		<span class="sub-reserve-title">{$translate->get('ReserveHaveTitle')}</span>
		<span class="sub-reserve-badge">{$translate->get('ReserveWaitingBadge')}</span>
	</div>

	<div class="sub-reserve-body">
		<div class="sub-reserve-plan">{$reserveRow.name}</div>
		<div class="sub-reserve-chips">
			<span class="sub-reserve-chip">⏱ <b>
				{if $reserveRow.cycle == 'month'}{$translate->get('Monthly')}
				{elseif $reserveRow.cycle == 'quater'}{$translate->get('Quaterly')}
				{elseif $reserveRow.cycle == 'semiannual'}{$translate->get('SemiAnnually')}
				{elseif $reserveRow.cycle == 'annual'}{$translate->get('Annually')}
				{else}{$translate->get('Custom')}{/if}
			</b></span>
			<span class="sub-reserve-chip">📅 <b>{$reserveRow.days}</b> {$translate->get('Days')}</span>
			<span class="sub-reserve-chip">📶 <b>{if $reserveRow.bandwidth >= 10000}{$translate->get('Unlimited')}{else}{$reserveRow.bandwidth} GB{/if}</b></span>
			<span class="sub-reserve-chip">💳 <b>{$currency->symbol_left} {number_format((float)$reserveRow.amount,(int){$currency->decimals})} {$currency->symbol_right}</b></span>
		</div>

		<div class="sub-reserve-note">
			{if $reserveRow.mode == 'date'}
				🚀 {$translate->get('ReserveStartsOnDate')} <b>{date("Y-m-d",$reserveRow.activate_at)}</b>
			{else}
				🚀 {$translate->get('ReserveStartsAfter')}{if $user->planIsActive() && !$user->planNeverExpires()} ({$translate->get('Until')} {date("Y-m-d",strtotime($user->expire_in))}){/if}
			{/if}
			<br>{$translate->get('ReserveNotifyHint')}
		</div>
	</div>

	<div class="sub-reserve-foot">
		<button type="button" class="sub-reserve-cancel"
			data-reserve-cancel
			data-title="{$translate->get('ReserveCancel')|escape:'html'}"
			data-confirm="{$translate->get('ReserveCancelConfirm')|escape:'html'}"
			data-no="{$translate->get('Close')|escape:'html'}"
			data-yes="{$translate->get('ReserveCancelYes')|escape:'html'}"
			data-done="{$translate->get('ReserveCancelDone')|escape:'html'}"
			data-error="{$translate->get('ReserveCancelError')|escape:'html'}">{$translate->get('ReserveCancel')}</button>
	</div>
</div>

{literal}
<script>
(function () {
	var button = document.querySelector('[data-reserve-cancel]');
	if (!button) { return; }

	button.addEventListener('click', function () {
		Swal.fire({
			title: button.getAttribute('data-title'),
			html: button.getAttribute('data-confirm'),
			icon: 'warning',
			showCancelButton: true,
			showConfirmButton: true,
			confirmButtonText: button.getAttribute('data-yes'),
			cancelButtonText: button.getAttribute('data-no'),
			allowOutsideClick: false,
			customClass: {
				confirmButton: 'btn btn-danger ms-1',
				cancelButton: 'btn btn-secondary ms-1'
			},
			buttonsStyling: false
		}).then(function (result) {
			if (!result.isConfirmed) { return; }

			$.ajax({
				type: 'GET',
				url: '/xmplus-patch.php?do=reserve.mine',
				dataType: 'json',
				success: function (mine) {
					if (!mine.ok || !mine.token) {
						layer.msg(button.getAttribute('data-error'));
						return;
					}

					$.ajax({
						type: 'POST',
						url: '/xmplus-patch.php?do=reserve.cancel',
						dataType: 'json',
						data: { token: mine.token },
						success: function (data) {
							if (data.ok) {
								layer.msg(button.getAttribute('data-done'));
								window.setTimeout(function () { location.reload(); }, 900);
							} else {
								layer.msg(data.error || button.getAttribute('data-error'));
							}
						},
						error: function () { layer.msg(button.getAttribute('data-error')); }
					});
				},
				error: function () { layer.msg(button.getAttribute('data-error')); }
			});
		});
	});
})();
</script>
{/literal}
{/if}
