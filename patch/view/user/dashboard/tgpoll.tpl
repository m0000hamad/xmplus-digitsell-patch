{*
 * While a Telegram gift could still arrive (not linked yet, the channel card
 * showing, or the bot-link gift on offer), the dashboard asks
 * xmplus-patch.php?do=tggift.poll now and then and reloads itself once a gift
 * lands - the congratulation popup and the new traffic figures then show
 * without a manual refresh. Linking the bot also reloads, so the cards move on.
 *
 * Coming back to the tab (usually from Telegram) asks at once and nudges the
 * account to the front of the next channel check. Polling only runs while the
 * tab is visible, every 15 s, and stops for good after 30 minutes.
 *}
{$tgpState = $user->tgJoin()}
{if $tgpState['state'] == 'link' || $tgpState['state'] == 'join' || $user->telegram_id <= 0 || $user->tgBindGiftOpen()}
<script>
	window.dsGiftPoll = { linked: {if $user->telegram_id > 0}true{else}false{/if} };
</script>
{literal}
<script>
(function () {
	var cfg = window.dsGiftPoll;
	if (!cfg || !window.fetch) { return; }

	var started = Date.now();
	var busy = false;
	var timer = null;

	function ask(nudge) {
		if (busy || document.visibilityState !== 'visible') { return; }
		if (Date.now() - started > 30 * 60 * 1000) { window.clearInterval(timer); return; }
		busy = true;
		fetch('/xmplus-patch.php?do=tggift.poll' + (nudge ? '&nudge=1' : ''), { credentials: 'same-origin', cache: 'no-store' })
			.then(function (response) { return response.json(); })
			.then(function (data) {
				if (!data || !data.ok) { return; }
				if (data.gifts > 0 || data.linked !== cfg.linked) {
					// never pull the page away from someone mid-purchase or mid-dialog;
					// the next tick tries again
					if (document.querySelector('.modal.show, .swal2-container, .layui-layer, .ivp-back:not([hidden])')) { return; }
					window.location.reload();
				}
			})
			.catch(function () {})
			.then(function () { busy = false; });
	}

	timer = window.setInterval(function () { ask(false); }, 15000);
	document.addEventListener('visibilitychange', function () {
		if (document.visibilityState === 'visible') { ask(true); }
	});
	window.addEventListener('focus', function () { ask(true); });
})();
</script>
{/literal}
{/if}
