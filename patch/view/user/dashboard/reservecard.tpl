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
	display: flex;
	align-items: center;
	justify-content: space-between;
	flex-wrap: wrap;
	gap: 11px;
	margin-top: 14px;
	padding: 12px 14px;
	border-radius: 15px;
	border: 1.5px solid rgba(99, 102, 241, .3);
	background: linear-gradient(135deg, rgba(99, 102, 241, .1), rgba(14, 165, 233, .1));
}
.sub-reserve-left { display: flex; align-items: center; gap: 10px; min-width: 0; }
.sub-reserve-emoji {
	flex: 0 0 auto;
	width: 36px;
	height: 36px;
	border-radius: 12px;
	background: rgba(99, 102, 241, .16);
	display: inline-flex;
	align-items: center;
	justify-content: center;
	font-size: 18px;
}
.sub-reserve-title { font-size: 13px; font-weight: 800; color: #16203d; line-height: 1.6; }
.sub-reserve-state { display: flex; flex-wrap: wrap; gap: 6px; font-size: 11.5px; font-weight: 700; color: #4338ca; }
.sub-reserve-state b { direction: ltr; unicode-bidi: isolate; }
.sub-reserve-cancel {
	flex: 0 0 auto;
	border: 0;
	cursor: pointer;
	border-radius: 12px;
	padding: 9px 15px;
	font-size: 12.5px;
	font-weight: 800;
	color: #be123c;
	background: rgba(244, 63, 94, .13);
	transition: background .15s ease;
}
.sub-reserve-cancel:hover { background: rgba(244, 63, 94, .22); }
html[data-hs-theme="dark"] .sub-reserve-title { color: #e7eaf3; }
html[data-hs-theme="dark"] .sub-reserve-state { color: #c7d2fe; }
html[data-hs-theme="dark"] .sub-reserve-cancel { color: #fda4af; background: rgba(244, 63, 94, .2); }
@media (max-width: 420px) {
	.sub-reserve { padding: 11px 12px; }
	.sub-reserve-cancel { width: 100%; }
}
</style>
{/literal}

<div class="sub-reserve">
	<div class="sub-reserve-left">
		<span class="sub-reserve-emoji">🗓️</span>
		<div>
			<div class="sub-reserve-title">{$translate->get('ReserveHaveTitle')} · {$reserveRow.name}</div>
			<div class="sub-reserve-state">
				<span>
					{if $reserveRow.mode == 'date'}
						{$translate->get('ReserveStartsOnDate')} <b>{date("Y-m-d",$reserveRow.activate_at)}</b>
					{else}
						{$translate->get('ReserveStartsAfter')}
					{/if}
				</span>
				<span>·</span>
				<span>{$translate->get('ReserveAmount')}: <b>{$currency->symbol_left} {number_format((float)$reserveRow.amount,(int){$currency->decimals})} {$currency->symbol_right}</b></span>
			</div>
		</div>
	</div>

	<button type="button" class="sub-reserve-cancel"
		data-reserve-cancel
		data-title="{$translate->get('ReserveCancel')|escape:'html'}"
		data-confirm="{$translate->get('ReserveCancelConfirm')|escape:'html'}"
		data-no="{$translate->get('Close')|escape:'html'}"
		data-yes="{$translate->get('ReserveCancelYes')|escape:'html'}"
		data-done="{$translate->get('ReserveCancelDone')|escape:'html'}"
		data-error="{$translate->get('ReserveCancelError')|escape:'html'}">{$translate->get('ReserveCancel')}</button>
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
