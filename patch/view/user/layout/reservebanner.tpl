{*
 * Announcement for plan reservations, at the top of every customer page right
 * after the wallet banner. Two moments produce a row (app/Jobs/ReserveJob.php,
 * table reserve_notice): the reservation being taken ("reserved") and the plan
 * actually starting ("started"). Unseen rows are drawn here; the close button
 * posts reserve.ack so they do not come back. Styled after paygbanner.tpl.
 *}
{$rsvNotes = $user->planReserveNotices()}
{if $rsvNotes}
<div id="rsvBanner" class="rsv-wrap">
	{foreach $rsvNotes as $rsvNote}
	<div class="rsv rsv-{$rsvNote.kind}">
		<span class="rsv-icon" aria-hidden="true">{if $rsvNote.kind == 'started'}✅{else}🗓️{/if}</span>
		<div class="rsv-body">
			<strong>{if $rsvNote.kind == 'started'}{$translate->get('ReserveNoticeStartedTitle')}{else}{$translate->get('ReserveNoticeReservedTitle')}{/if}</strong>
			<span class="rsv-text">
				{if $rsvNote.kind == 'started'}
					{$translate->get('ReserveNoticeStartedText')|replace:'%plan%':$rsvNote.name|replace:'%days%':$rsvNote.days}
				{else}
					{capture assign=rsvWhen}{if $rsvNote.mode == 'date'}{$translate->get('ReserveStartsOnDate')} {date("Y-m-d",$rsvNote.activate_at)}{else}{$translate->get('ReserveStartsAfter')}{/if}{/capture}
					{$translate->get('ReserveNoticeReservedText')|replace:'%plan%':$rsvNote.name|replace:'%when%':$rsvWhen}
				{/if}
			</span>
		</div>
		<div class="rsv-actions">
			<a class="rsv-btn" href="/portal/dashboard">{$translate->get('ReserveNoticeGo')}</a>
		</div>
		<button type="button" class="rsv-close" data-reserve-ack aria-label="{$translate->get('Close')|escape}" title="{$translate->get('Close')|escape}">×</button>
	</div>
	{/foreach}
</div>
<style>
.rsv-wrap { display: grid; gap: .7rem; margin-block-end: 1.1rem; }
.rsv {
	position: relative;
	display: flex;
	align-items: center;
	gap: .85rem;
	padding: .8rem 1rem;
	border: 1px solid rgba(99, 102, 241, .38);
	border-radius: .85rem;
	background: linear-gradient(100deg, rgba(99, 102, 241, .15), rgba(6, 182, 212, .07));
	line-height: 1.7;
}
.rsv-started { border-color: rgba(16, 185, 129, .4); background: linear-gradient(100deg, rgba(16, 185, 129, .16), rgba(52, 211, 153, .06)); }
.rsv-icon { flex: none; font-size: 1.55rem; line-height: 1; }
.rsv-body { flex: 1 1 auto; min-width: 0; }
.rsv-body strong { margin-inline-end: .45rem; }
.rsv-text { opacity: .88; }
.rsv-text b { direction: ltr; unicode-bidi: isolate; }
.rsv-actions { flex: none; }
.rsv-btn {
	display: inline-block;
	padding: .35rem .95rem;
	border-radius: 2rem;
	background: #4f46e5;
	color: #fff !important;
	font-weight: 700;
	white-space: nowrap;
	text-decoration: none;
	box-shadow: 0 2px 8px rgba(79, 70, 229, .35);
}
.rsv-started .rsv-btn { background: #059669; box-shadow: 0 2px 8px rgba(5, 150, 105, .35); }
.rsv-btn:hover { filter: brightness(1.08); }
.rsv-close {
	flex: none;
	width: 1.9rem;
	height: 1.9rem;
	padding: 0;
	border: 0;
	border-radius: 50%;
	background: transparent;
	color: inherit;
	font-size: 1.4rem;
	line-height: 1;
	opacity: .55;
	cursor: pointer;
}
.rsv-close:hover { opacity: 1; background: rgba(127, 127, 127, .18); }
html[data-hs-theme="dark"] .rsv { background: linear-gradient(100deg, rgba(99, 102, 241, .22), rgba(6, 182, 212, .08)); }
html[data-hs-theme="dark"] .rsv-started { background: linear-gradient(100deg, rgba(16, 185, 129, .24), rgba(52, 211, 153, .09)); }
@media (max-width: 767px) {
	.rsv { flex-wrap: wrap; padding: .7rem .8rem; gap: .5rem .7rem; }
	.rsv-body { flex-basis: calc(100% - 4.5rem); padding-inline-end: 1.6rem; }
	.rsv-actions { flex-basis: 100%; }
	.rsv-close { position: absolute; top: .3rem; inset-inline-end: .3rem; }
}
</style>
<script>
/* vanilla on purpose: this banner renders where usermenu.tpl opens the page,
   before the footer has loaded jQuery, so $ does not exist here yet */
(function () {
	var wrap = document.getElementById('rsvBanner');
	if (!wrap) { return; }

	function ack() {
		fetch('/xmplus-patch.php?do=reserve.mine', { credentials: 'same-origin' })
			.then(function (r) { return r.json(); })
			.then(function (mine) {
				if (!mine || !mine.ok || !mine.token) { return; }

				var body = new FormData();
				body.append('token', mine.token);

				return fetch('/xmplus-patch.php?do=reserve.ack', {
					method: 'POST',
					credentials: 'same-origin',
					body: body
				});
			})
			.catch(function () {});
	}

	wrap.addEventListener('click', function (event) {
		var node = event.target;
		while (node && node !== wrap && !(node.getAttribute && node.getAttribute('data-reserve-ack') !== null)) {
			node = node.parentNode;
		}

		if (!node || node === wrap) { return; }

		var card = node;
		while (card && card !== wrap && (' ' + card.className + ' ').indexOf(' rsv ') === -1) {
			card = card.parentNode;
		}

		if (card && card !== wrap && card.parentNode) {
			card.parentNode.removeChild(card);
		}

		if (!wrap.querySelector('.rsv')) {
			if (wrap.parentNode) { wrap.parentNode.removeChild(wrap); }
		}

		ack();
	});
})();
</script>
{/if}
