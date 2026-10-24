{*
  The card-to-card confirmation, at the top of every customer page right after
  the reservation banner. Rows are written when an administrator approves or
  rejects a transfer (app/Patch/Card2Card.php, table c2c_notice); the close
  button posts c2c.ack so they do not come back. Styled after reservebanner.tpl.
*}
{$c2cNotes = $user->cardToCardNotices()}
{if $c2cNotes}
<div id="c2cBanner" class="c2c-wrap">
	{foreach $c2cNotes as $c2cNote}
	<div class="c2c-bn c2c-{$c2cNote.kind}">
		<span class="c2c-bn-icon" aria-hidden="true">{if $c2cNote.kind == 'approved'}✅{else}❌{/if}</span>
		<div class="c2c-bn-body">
			<strong>{if $c2cNote.kind == 'approved'}{$translate->get('C2cNoticeApprovedTitle')}{else}{$translate->get('C2cNoticeRejectedTitle')}{/if}</strong>
			<span class="c2c-bn-text">
				{capture assign=c2cAmount}{$c2cNote.amount|number_format}{/capture}
				{if $c2cNote.kind == 'approved'}
					{$translate->get('C2cNoticeApprovedText')|replace:'%amount%':$c2cAmount|replace:'%order%':$c2cNote.order_no|escape:'html'}
				{else}
					{$translate->get('C2cNoticeRejectedText')|replace:'%order%':$c2cNote.order_no|replace:'%reason%':$c2cNote.reason|escape:'html'}
				{/if}
			</span>
		</div>
		<div class="c2c-bn-actions">
			<a class="c2c-bn-btn" href="/portal/orders">{$translate->get('C2cNoticeGo')}</a>
		</div>
		<button type="button" class="c2c-bn-close" data-c2c-ack aria-label="{$translate->get('Close')|escape}" title="{$translate->get('Close')|escape}">×</button>
	</div>
	{/foreach}
</div>
<style>
.c2c-wrap { display: grid; gap: .7rem; margin-block-end: 1.1rem; }
.c2c-bn {
	position: relative;
	display: flex;
	align-items: center;
	gap: .85rem;
	padding: .8rem 1rem;
	border: 1px solid rgba(16, 185, 129, .38);
	border-radius: .85rem;
	background: linear-gradient(100deg, rgba(16, 185, 129, .15), rgba(6, 182, 212, .07));
	line-height: 1.7;
}
.c2c-rejected { border-color: rgba(244, 63, 94, .4); background: linear-gradient(100deg, rgba(244, 63, 94, .14), rgba(251, 113, 133, .06)); }
.c2c-bn-icon { flex: none; font-size: 1.55rem; line-height: 1; }
.c2c-bn-body { flex: 1 1 auto; min-width: 0; }
.c2c-bn-body strong { margin-inline-end: .45rem; }
.c2c-bn-text { opacity: .88; }
.c2c-bn-actions { flex: none; }
.c2c-bn-btn {
	display: inline-block;
	padding: .35rem .95rem;
	border-radius: 2rem;
	background: #059669;
	color: #fff !important;
	font-weight: 700;
	white-space: nowrap;
	text-decoration: none;
	box-shadow: 0 2px 8px rgba(5, 150, 105, .35);
}
.c2c-rejected .c2c-bn-btn { background: #be123c; box-shadow: 0 2px 8px rgba(190, 18, 60, .35); }
.c2c-bn-btn:hover { filter: brightness(1.08); }
.c2c-bn-close {
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
.c2c-bn-close:hover { opacity: 1; background: rgba(127, 127, 127, .18); }
html[data-hs-theme="dark"] .c2c-bn { background: linear-gradient(100deg, rgba(16, 185, 129, .22), rgba(6, 182, 212, .08)); }
html[data-hs-theme="dark"] .c2c-rejected { background: linear-gradient(100deg, rgba(244, 63, 94, .22), rgba(251, 113, 133, .08)); }
@media (max-width: 767px) {
	.c2c-bn { flex-wrap: wrap; padding: .7rem .8rem; gap: .5rem .7rem; }
	.c2c-bn-body { flex-basis: calc(100% - 4.5rem); padding-inline-end: 1.6rem; }
	.c2c-bn-actions { flex-basis: 100%; }
	.c2c-bn-close { position: absolute; top: .3rem; inset-inline-end: .3rem; }
}
</style>
<script>
/* vanilla on purpose: this banner renders where usermenu.tpl opens the page,
   before the footer has loaded jQuery, so $ does not exist here yet */
(function () {
	var wrap = document.getElementById('c2cBanner');
	if (!wrap) { return; }

	function ack() {
		fetch('/xmplus-patch.php?do=c2c.info', { credentials: 'same-origin' })
			.then(function (r) { return r.json(); })
			.then(function (info) {
				if (!info || !info.ok || !info.token) { return; }

				var body = new FormData();
				body.append('token', info.token);

				return fetch('/xmplus-patch.php?do=c2c.ack', {
					method: 'POST',
					credentials: 'same-origin',
					body: body
				});
			})
			.catch(function () {});
	}

	wrap.addEventListener('click', function (event) {
		var node = event.target;
		while (node && node !== wrap && !(node.getAttribute && node.getAttribute('data-c2c-ack') !== null)) {
			node = node.parentNode;
		}

		if (!node || node === wrap) { return; }

		var card = node;
		while (card && card !== wrap && (' ' + card.className + ' ').indexOf(' c2c-bn ') === -1) {
			card = card.parentNode;
		}

		if (card && card !== wrap && card.parentNode) {
			card.parentNode.removeChild(card);
		}

		if (!wrap.querySelector('.c2c-bn')) {
			if (wrap.parentNode) { wrap.parentNode.removeChild(wrap); }
		}

		ack();
	});
})();
</script>
{/if}
