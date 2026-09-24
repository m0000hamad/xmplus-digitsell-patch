{*
 * Ready-to-send invite message: the visitor's own link wrapped in a short pitch,
 * with one-tap buttons for Telegram, WhatsApp, the system share sheet and copy.
 * Used on the affiliate page ($shareEditable = 1, the text can be edited and is
 * remembered in this browser) and, as $shareCompact = 1 (one big Telegram button,
 * no text box), inside the dashboard invite popup.
 * Safe to include more than once - the script defines itself only once.
 *}
{$shareLink = "{$helpers->InviteUrl()}/register?aff={$user->afflink}"}

{literal}
<style>
.ivs-box { display: flex; flex-direction: column; gap: 10px; font-family: inherit; }
.ivs-text {
	width: 100%;
	min-height: 96px;
	resize: vertical;
	font-family: inherit;
	border-radius: 14px;
	border: 1px solid rgba(99, 102, 241, .2);
	background: rgba(99, 102, 241, .04);
	color: #1e2436;
	font-size: 13px;
	font-weight: 400;
	line-height: 2;
	padding: 12px 14px;
	white-space: pre-wrap;
	transition: border-color .15s ease, box-shadow .15s ease;
}
.ivs-text:focus { outline: 0; border-color: #6366f1; box-shadow: 0 0 0 4px rgba(99, 102, 241, .12); }
.ivs-link { direction: ltr; unicode-bidi: isolate; color: #4f46e5; word-break: break-all; }
.ivs-row { display: flex; gap: 8px; flex-wrap: wrap; }
.ivs-btn {
	flex: 1 1 120px;
	display: inline-flex;
	align-items: center;
	justify-content: center;
	gap: 8px;
	border: 0;
	border-radius: 12px;
	padding: 11px 14px;
	font-family: inherit;
	font-size: 13px;
	font-weight: 500;
	line-height: 1.4;
	cursor: pointer;
	color: #fff !important;
	text-decoration: none !important;
	white-space: nowrap;
	transition: transform .15s ease, box-shadow .15s ease, filter .15s ease;
}
.ivs-btn i { font-size: 15px; }
.ivs-btn:hover { transform: translateY(-1px); filter: brightness(1.05); }
.ivs-tg { background: linear-gradient(135deg, #2aabee, #229ed9); box-shadow: 0 8px 20px -8px rgba(34, 158, 217, .7); }
.ivs-wa { background: linear-gradient(135deg, #25d366, #1ea952); box-shadow: 0 8px 20px -8px rgba(30, 169, 82, .6); }
.ivs-more { background: linear-gradient(135deg, #6366f1, #8b5cf6); }
.ivs-copy { background: rgba(23, 32, 61, .06); color: #1e2436 !important; }
.ivs-copy.ivs-done, .ivs-mini .ivs-done { background: #10b981 !important; color: #fff !important; }
.ivs-hint { font-size: 11.5px; color: #9aa3b5; font-weight: 400; }

/* compact variant - the popup: one big Telegram button, the rest as small chips */
.ivs-main {
	display: flex;
	align-items: center;
	justify-content: center;
	gap: 10px;
	width: 100%;
	padding: 14px 18px;
	border-radius: 16px;
	font-family: inherit;
	font-size: 14.5px;
	font-weight: 700;
	color: #fff !important;
	text-decoration: none !important;
	background: linear-gradient(135deg, #2aabee, #1d8fd0);
	box-shadow: 0 12px 26px -10px rgba(34, 158, 217, .8), inset 0 1px 0 rgba(255, 255, 255, .25);
	transition: transform .15s ease, box-shadow .15s ease;
}
.ivs-main i { font-size: 19px; }
.ivs-main:hover { transform: translateY(-2px); box-shadow: 0 16px 30px -10px rgba(34, 158, 217, .85), inset 0 1px 0 rgba(255, 255, 255, .25); }
.ivs-mini { display: flex; gap: 8px; }
.ivs-mini > * {
	flex: 1 1 0;
	min-width: 0;
	display: inline-flex;
	align-items: center;
	justify-content: center;
	gap: 6px;
	padding: 10px 8px;
	border: 1px solid rgba(23, 32, 61, .08);
	border-radius: 13px;
	background: rgba(23, 32, 61, .03);
	color: #3b4459 !important;
	font-family: inherit;
	font-size: 12.5px;
	font-weight: 500;
	text-decoration: none !important;
	white-space: nowrap;
	cursor: pointer;
	transition: background .15s ease, border-color .15s ease;
}
.ivs-mini > *:hover { background: rgba(23, 32, 61, .06); border-color: rgba(23, 32, 61, .14); }
.ivs-mini > [hidden] { display: none; }
.ivs-mini .fa-whatsapp { color: #25d366; font-size: 15px; }
.ivs-mini .ivs-done i { color: #fff; }

/* invite friends only - the link is tied to the account that shares it */
.ivs-safe {
	display: flex;
	align-items: flex-start;
	gap: 8px;
	padding: 9px 12px;
	border-radius: 12px;
	background: rgba(245, 158, 11, .1);
	border: 1px solid rgba(245, 158, 11, .28);
	color: #92400e;
	font-size: 11.5px;
	font-weight: 500;
	line-height: 1.9;
	text-align: start;
}
.ivs-safe i { flex: 0 0 auto; margin-top: 4px; font-size: 13px; color: #d97706; }
.ivs-compact .ivs-safe { padding: 7px 10px; font-size: 11px; line-height: 1.8; }
html[data-hs-theme="dark"] .ivs-safe { background: rgba(245, 158, 11, .1); border-color: rgba(245, 158, 11, .3); color: #fcd34d; }
html[data-hs-theme="dark"] .ivs-safe i { color: #fbbf24; }
html[data-hs-theme="dark"] .ivs-text { background: rgba(255, 255, 255, .04); border-color: rgba(255, 255, 255, .1); color: #e7eaf3; }
html[data-hs-theme="dark"] .ivs-link { color: #a5b4fc; }
html[data-hs-theme="dark"] .ivs-copy { background: rgba(255, 255, 255, .08); color: #e7eaf3 !important; }
html[data-hs-theme="dark"] .ivs-mini > * { background: rgba(255, 255, 255, .04); border-color: rgba(255, 255, 255, .08); color: #d5dbe8 !important; }
html[data-hs-theme="dark"] .ivs-mini > *:hover { background: rgba(255, 255, 255, .08); }
@media (max-width: 575.98px) { .ivs-row .ivs-btn { flex: 1 1 calc(50% - 8px); } }
</style>
{/literal}

{if isset($shareCompact) && $shareCompact}
<div class="ivs-box ivs-compact" data-ivs data-link="{$shareLink|escape:'html'}" data-default="{$translate->get('InviteShareText')|escape:'html'}">
	<a class="ivs-main" data-ivs-go="tg" href="#" target="_blank" rel="noopener"><i class="fa-brands fa-telegram"></i> {$translate->get('InviteShareTelegramBig')}</a>
	<div class="ivs-mini">
		<a data-ivs-go="wa" href="#" target="_blank" rel="noopener"><i class="fa-brands fa-whatsapp"></i> {$translate->get('InviteShareWhatsapp')}</a>
		<button type="button" data-ivs-go="copy" data-done="<i class='fa-solid fa-check'></i> {$translate->get('InviteShareCopied')|escape:'html'}"><i class="fa-regular fa-copy"></i> {$translate->get('InviteShareCopy')}</button>
		<button type="button" data-ivs-go="more" hidden><i class="fa-solid fa-share-nodes"></i> {$translate->get('InviteShareMore')}</button>
	</div>
	<div class="ivs-safe"><i class="fa-solid fa-user-shield"></i><span>{$translate->get('InviteSafeNote')}</span></div>
</div>
{else}
<div class="ivs-box" data-ivs data-link="{$shareLink|escape:'html'}" data-default="{$translate->get('InviteShareText')|escape:'html'}">
	{if isset($shareEditable) && $shareEditable}
		<textarea class="ivs-text" data-ivs-text rows="3">{$translate->get('InviteShareText')|escape:'html'}</textarea>
		<div class="ivs-hint"><i class="fa-regular fa-pen-to-square"></i> {$translate->get('InviteShareEditHint')}</div>
	{else}
		<div class="ivs-text" data-ivs-text>{$translate->get('InviteShareText')|escape:'html'}
<span class="ivs-link">{$shareLink|escape:'html'}</span></div>
	{/if}
	<div class="ivs-row">
		<a class="ivs-btn ivs-tg" data-ivs-go="tg" href="#" target="_blank" rel="noopener"><i class="fa-brands fa-telegram"></i> {$translate->get('InviteShareTelegram')}</a>
		<a class="ivs-btn ivs-wa" data-ivs-go="wa" href="#" target="_blank" rel="noopener"><i class="fa-brands fa-whatsapp"></i> {$translate->get('InviteShareWhatsapp')}</a>
		<button type="button" class="ivs-btn ivs-more" data-ivs-go="more" hidden><i class="fa-solid fa-share-nodes"></i> {$translate->get('InviteShareMore')}</button>
		<button type="button" class="ivs-btn ivs-copy" data-ivs-go="copy" data-done="<i class='fa-solid fa-check'></i> {$translate->get('InviteShareCopied')|escape:'html'}"><i class="fa-regular fa-copy"></i> {$translate->get('InviteShareCopy')}</button>
	</div>
	<div class="ivs-safe"><i class="fa-solid fa-user-shield"></i><span>{$translate->get('InviteSafeNote')}</span></div>
</div>
{/if}

{literal}
<script>
(function () {
	if (window.dsInviteShare) { return; }

	var STORE = 'dsInviteText';

	function read(key) { try { return window.localStorage.getItem(key); } catch (e) { return null; } }
	function write(key, value) { try { window.localStorage.setItem(key, value); } catch (e) {} }
	function drop(key) { try { window.localStorage.removeItem(key); } catch (e) {} }

	// the pitch without the link: the edited copy on the affiliate page, else the default
	function pitch(box) {
		var field = box.querySelector('textarea[data-ivs-text]');
		if (field) { return field.value.trim(); }
		return (read(STORE) || box.getAttribute('data-default') || '').trim();
	}

	function copy(text) {
		if (navigator.clipboard && window.isSecureContext) {
			return navigator.clipboard.writeText(text);
		}
		var area = document.createElement('textarea');
		area.value = text;
		area.setAttribute('readonly', '');
		area.style.position = 'fixed';
		area.style.opacity = '0';
		document.body.appendChild(area);
		area.select();
		try { document.execCommand('copy'); } catch (e) {}
		document.body.removeChild(area);
		return Promise.resolve();
	}

	function wire(box) {
		if (box.getAttribute('data-ivs-ready')) { return; }
		box.setAttribute('data-ivs-ready', '1');

		var link = box.getAttribute('data-link');
		var field = box.querySelector('textarea[data-ivs-text]');
		if (field) {
			var saved = read(STORE);
			if (saved) { field.value = saved; }
			field.addEventListener('input', function () {
				var value = field.value.trim();
				if (!value || value === box.getAttribute('data-default').trim()) { drop(STORE); } else { write(STORE, value); }
			});
		} else {
			// the popup preview follows an edit made on the affiliate page
			var saved = read(STORE);
			var shown = box.querySelector('div[data-ivs-text]');
			if (saved && shown && shown.firstChild) { shown.firstChild.nodeValue = saved + '\n'; }
		}

		var more = box.querySelector('[data-ivs-go="more"]');
		if (more && navigator.share) { more.hidden = false; }

		box.addEventListener('click', function (event) {
			var button = event.target.closest('[data-ivs-go]');
			if (!button) { return; }

			var kind = button.getAttribute('data-ivs-go');
			var text = pitch(box);
			var full = text + '\n' + link;

			if (kind === 'tg') {
				// t.me/share puts the url above the text, so the link leads the message
				button.href = 'https://t.me/share/url?url=' + encodeURIComponent(link) + '&text=' + encodeURIComponent(text);
			} else if (kind === 'wa') {
				button.href = 'https://wa.me/?text=' + encodeURIComponent(full);
			} else if (kind === 'more') {
				event.preventDefault();
				navigator.share({ text: text, url: link }).catch(function () {});
			} else if (kind === 'copy') {
				event.preventDefault();
				copy(full).then(function () {
					var label = button.innerHTML;
					button.classList.add('ivs-done');
					button.innerHTML = button.getAttribute('data-done');
					window.setTimeout(function () { button.classList.remove('ivs-done'); button.innerHTML = label; }, 1800);
				});
			}

			box.dispatchEvent(new CustomEvent('ivs:shared', { bubbles: true, detail: { kind: kind } }));
		});
	}

	window.dsInviteShare = function () {
		var boxes = document.querySelectorAll('[data-ivs]');
		for (var i = 0; i < boxes.length; i++) { wire(boxes[i]); }
	};

	if (document.readyState === 'loading') {
		document.addEventListener('DOMContentLoaded', window.dsInviteShare);
	} else {
		window.dsInviteShare();
	}
})();
</script>
{/literal}
