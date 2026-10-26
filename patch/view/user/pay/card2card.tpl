{*
  Card-to-card - the customer's half, included at the end of user/pay/pay.tpl.
  The order already exists (the panel's own checkout created it); this offers a
  way to pay it by transfer and records what the customer transferred
  (/xmplus-patch.php?do=c2c.*, app/Patch/Card2Card.php). The card shown is the
  first one in rotation that still has room; approval happens in Settings ->
  Card to card or on the Telegram message.
*}
<div id="c2cRoot"
	data-order="{$order->id}"
	data-order-no="{$order->order_id|escape:'html'}"
	data-amount="{$order->total_amount}"
	style="display:none"></div>

<script>
window.C2CWords = {
	title:      "{$translate->get('C2cPayTitle')|escape:'javascript'}",
	sub:        "{$translate->get('C2cPaySub')|escape:'javascript'}",
	cardNo:     "{$translate->get('C2cCardNumber')|escape:'javascript'}",
	holder:     "{$translate->get('C2cCardHolder')|escape:'javascript'}",
	bank:       "{$translate->get('C2cBank')|escape:'javascript'}",
	amount:     "{$translate->get('C2cAmount')|escape:'javascript'}",
	copy:       "{$translate->get('C2cCopy')|escape:'javascript'}",
	copied:     "{$translate->get('C2cCopied')|escape:'javascript'}",
	formTitle:  "{$translate->get('C2cFormTitle')|escape:'javascript'}",
	last4:      "{$translate->get('C2cLast4')|escape:'javascript'}",
	last4Hint:  "{$translate->get('C2cLast4Hint')|escape:'javascript'}",
	payer:      "{$translate->get('C2cPayer')|escape:'javascript'}",
	paidAt:     "{$translate->get('C2cPaidAt')|escape:'javascript'}",
	ref:        "{$translate->get('C2cRef')|escape:'javascript'}",
	submit:     "{$translate->get('C2cSubmit')|escape:'javascript'}",
	more:       "{$translate->get('C2cMore')|escape:'javascript'}",
	pendingT:   "{$translate->get('C2cPendingTitle')|escape:'javascript'}",
	pendingX:   "{$translate->get('C2cPendingText')|escape:'javascript'}",
	orderNo:    "{$translate->get('C2cPendingOrder')|escape:'javascript'}",
	checkNow:   "{$translate->get('C2cCheckNow')|escape:'javascript'}",
	rejected:   "{$translate->get('C2cRejected')|escape:'javascript'}",
	required:   "{$translate->get('C2cRequired')|escape:'javascript'}",
	badLast4:   "{$translate->get('C2cBadLast4')|escape:'javascript'}",
	noCard:     "{$translate->get('C2cNoCard')|escape:'javascript'}",
	noteTitle:  "{$translate->get('C2cNoteTitle')|escape:'javascript'}",
	close:      "{$translate->get('C2cClose')|escape:'javascript'}",
	wait:       "{$translate->get('C2cWait')|escape:'javascript'}",
	error:      "{$translate->get('C2cError')|escape:'javascript'}",
	exact:      "{$translate->get('C2cExactAmount')|escape:'javascript'}",
	approvedT:  "{$translate->get('C2cApprovedTitle')|escape:'javascript'}",
	approvedX:  "{$translate->get('C2cApprovedText')|escape:'javascript'}",
	goOrders:   "{$translate->get('C2cNoticeGo')|escape:'javascript'}",
	again:      "{$translate->get('C2cTryAgain')|escape:'javascript'}",
	pendingPill:"{$translate->get('C2cPendingPill')|escape:'javascript'}",
	support:    "{$translate->get('C2cSupport')|escape:'javascript'}",
	curLeft:    "{$currency->symbol_left|escape:'javascript'}",
	curRight:   "{$currency->symbol_right|escape:'javascript'}"
};
</script>

{literal}
<style>
.c2c-modal { z-index: 20000 !important; }
.c2c-modal .modal-dialog {
	margin: 72px auto 18px;
	max-width: 460px;
	max-height: calc(100vh - 90px);
}
.c2c-modal .modal-content {
	display: flex;
	flex-direction: column;
	max-height: calc(100vh - 90px);
	border: 0;
	border-radius: 20px;
	overflow: hidden;
	background: #fff;
	box-shadow: 0 24px 60px rgba(15, 23, 42, .28);
}
.c2c-top {
	padding: 18px 20px 16px;
	background: linear-gradient(135deg, #0f766e, #10b981 55%, #06b6d4);
	color: #fff;
	position: relative;
}
.c2c-top h5 { margin: 0; font-size: 16px; font-weight: 800; }
.c2c-top p { margin: 5px 0 0; font-size: 12px; opacity: .92; line-height: 1.9; }
.c2c-x {
	position: absolute;
	top: 12px;
	inset-inline-end: 14px;
	border: 0;
	background: rgba(255, 255, 255, .18);
	color: #fff;
	width: 30px;
	height: 30px;
	border-radius: 50%;
	font-size: 17px;
	line-height: 1;
	cursor: pointer;
}
.c2c-body {
	flex: 1 1 auto;
	min-height: 0;
	padding: 18px 20px 20px;
	overflow-y: auto;
}
.c2c-top,
.c2c-foot { flex: 0 0 auto; }
.c2c-foot { padding: 0 20px 18px; }
.c2c-cancel {
	width: 100%;
	border: 0;
	border-radius: 14px;
	padding: 12px;
	font-size: 13px;
	font-weight: 800;
	color: #475569;
	background: rgba(15, 23, 42, .06);
	cursor: pointer;
}
.c2c-cancel:hover { background: rgba(15, 23, 42, .1); }
.c2c-card {
	border-radius: 16px;
	padding: 15px;
	background: linear-gradient(135deg, #f0fdfa, #ecfeff);
	border: 1px solid rgba(13, 148, 136, .2);
	margin-bottom: 14px;
}
.c2c-bank { display: flex; align-items: center; gap: 8px; font-size: 12.5px; color: #0f766e; font-weight: 800; }
.c2c-holder { margin-top: 4px; font-size: 12px; color: #64748b; }
.c2c-number {
	display: flex;
	align-items: center;
	justify-content: space-between;
	gap: 10px;
	margin-top: 10px;
	direction: ltr;
}
.c2c-number b {
	font-size: 19px;
	letter-spacing: 1.5px;
	color: #0f172a;
	font-variant-numeric: tabular-nums;
	white-space: nowrap;
}
.c2c-copy {
	border: 0;
	background: #0d9488;
	color: #fff;
	border-radius: 10px;
	padding: 7px 11px;
	font-size: 11.5px;
	font-weight: 700;
	cursor: pointer;
	flex: 0 0 auto;
}
.c2c-copy:hover { filter: brightness(1.08); }
.c2c-amount {
	display: flex;
	align-items: center;
	justify-content: space-between;
	gap: 10px;
	border-radius: 14px;
	padding: 12px 14px;
	background: rgba(245, 158, 11, .1);
	border: 1px dashed rgba(245, 158, 11, .4);
	font-size: 12.5px;
	color: #92400e;
	margin-bottom: 8px;
}
.c2c-amount b { font-size: 17px; direction: ltr; unicode-bidi: isolate; color: #78350f; }
.c2c-exact { font-size: 11.5px; color: #92400e; margin-bottom: 14px; line-height: 1.9; }
.c2c-label { display: block; font-size: 12px; font-weight: 700; color: #475569; margin: 0 0 6px; }
.c2c-input, .c2c-select {
	width: 100%;
	border: 1.5px solid rgba(15, 23, 42, .12);
	border-radius: 12px;
	padding: 11px 12px;
	font-size: 13px;
	background: #fff;
	color: #16203d;
	outline: none;
	transition: border-color .16s ease, box-shadow .16s ease;
}
.c2c-input:focus { border-color: #10b981; box-shadow: 0 0 0 3px rgba(16, 185, 129, .14); }
.c2c-last4 {
	text-align: center;
	font-size: 22px;
	font-weight: 800;
	letter-spacing: 8px;
	padding: 12px;
	font-variant-numeric: tabular-nums;
}
.c2c-more {
	border-radius: 12px;
	background: rgba(15, 23, 42, .04);
	padding: 0 12px;
	margin: 2px 0 14px;
}
.c2c-more summary {
	cursor: pointer;
	font-size: 11.5px;
	font-weight: 700;
	color: #64748b;
	padding: 10px 0;
	list-style: none;
}
.c2c-more summary::-webkit-details-marker { display: none; }
.c2c-more summary::before { content: '＋'; margin-inline-end: 6px; color: #0d9488; }
.c2c-more[open] summary::before { content: '－'; }
.c2c-more .c2c-field:first-of-type { margin-top: 2px; }
.c2c-more .c2c-field:last-child { margin-bottom: 10px; }
.c2c-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
.c2c-field { margin-bottom: 12px; }
.c2c-hint { display: block; margin-top: 5px; font-size: 10.5px; color: #94a3b8; }
.c2c-submit {
	width: 100%;
	border: 0;
	border-radius: 14px;
	padding: 13px;
	font-size: 14px;
	font-weight: 800;
	color: #fff;
	background: linear-gradient(135deg, #059669, #10b981);
	box-shadow: 0 8px 20px rgba(16, 185, 129, .32);
	cursor: pointer;
}
.c2c-submit:disabled { opacity: .6; cursor: wait; }
.c2c-err { display: none; border-radius: 12px; padding: 10px 12px; margin-bottom: 12px; font-size: 12px; background: rgba(244, 63, 94, .1); color: #be123c; }
.c2c-pending, .c2c-done, .c2c-fail { text-align: center; padding: 10px 4px 4px; }
.c2c-spin {
	width: 46px;
	height: 46px;
	margin: 0 auto 12px;
	border-radius: 50%;
	border: 4px solid rgba(245, 158, 11, .22);
	border-top-color: #f59e0b;
	animation: c2c-spin 1s linear infinite;
}
@keyframes c2c-spin { to { transform: rotate(360deg); } }
.c2c-pending h6, .c2c-done h6, .c2c-fail h6 { font-size: 15px; font-weight: 800; margin: 0 0 6px; color: #16203d; }
.c2c-pending p, .c2c-fail p { font-size: 12.5px; color: #64748b; line-height: 2; margin: 0 0 10px; }
.c2c-pill {
	display: inline-flex;
	align-items: center;
	gap: 6px;
	border-radius: 999px;
	padding: 6px 12px;
	font-size: 11.5px;
	font-weight: 700;
	background: rgba(245, 158, 11, .14);
	color: #b45309;
	margin: 0 4px;
}
.c2c-note {
	border-radius: 14px;
	padding: 12px 14px;
	background: rgba(99, 102, 241, .07);
	color: #475569;
	font-size: 11.5px;
	line-height: 2;
	margin-top: 6px;
	white-space: pre-line;
}
.c2c-wait {
	display: none;
	margin-top: 10px;
	font-size: 11.5px;
	color: #b45309;
	background: rgba(245, 158, 11, .12);
	border-radius: 10px;
	padding: 8px 11px;
}
.c2c-ok-icon, .c2c-no-icon { font-size: 40px; line-height: 1; display: block; margin-bottom: 8px; }
.c2c-btn-line { display: flex; gap: 9px; margin-top: 12px; }
.c2c-btn-ghost {
	flex: 1;
	border: 0;
	border-radius: 12px;
	padding: 11px;
	font-size: 12.5px;
	font-weight: 700;
	background: rgba(15, 23, 42, .07);
	color: #334155;
	cursor: pointer;
}
html[data-hs-theme="dark"] .c2c-modal .modal-content { background: #1c2536; }
html[data-hs-theme="dark"] .c2c-card { background: linear-gradient(135deg, rgba(13, 148, 136, .18), rgba(6, 182, 212, .1)); border-color: rgba(45, 212, 191, .25); }
html[data-hs-theme="dark"] .c2c-number b, html[data-hs-theme="dark"] .c2c-pending h6,
html[data-hs-theme="dark"] .c2c-done h6, html[data-hs-theme="dark"] .c2c-fail h6 { color: #e7eaf3; }
html[data-hs-theme="dark"] .c2c-input { background: #16203d; border-color: rgba(255, 255, 255, .12); color: #e7eaf3; }
html[data-hs-theme="dark"] .c2c-note { background: rgba(99, 102, 241, .14); color: #b9c2d4; }
html[data-hs-theme="dark"] .c2c-more { background: rgba(255, 255, 255, .05); }
html[data-hs-theme="dark"] .c2c-more summary { color: #b9c2d4; }
html[data-hs-theme="dark"] .c2c-btn-ghost { background: rgba(255, 255, 255, .08); color: #cbd5e1; }
html[data-hs-theme="dark"] .c2c-cancel { background: rgba(255, 255, 255, .08); color: #cbd5e1; }
html[data-hs-theme="dark"] .c2c-label { color: #b9c2d4; }
@media (max-width: 420px) {
	.c2c-grid { grid-template-columns: 1fr; }
	.c2c-number b { font-size: 16px; letter-spacing: 1px; }
}
</style>
{/literal}

<div class="modal fade c2c-modal" id="c2cModal" tabindex="-1" aria-hidden="true">
	<div class="modal-dialog modal-dialog-centered modal-dialog-scrollable">
		<div class="modal-content">
			<div class="c2c-top">
				<h5>💳 <span id="c2cTopTitle"></span></h5>
				<p id="c2cTopSub"></p>
				<button type="button" class="c2c-x" data-bs-dismiss="modal" aria-label="close">×</button>
			</div>
			<div class="c2c-body" id="c2cBody"></div>
			<div class="c2c-foot">
				<button type="button" class="c2c-cancel" data-bs-dismiss="modal">{$translate->get('C2cCancel')}</button>
			</div>
		</div>
	</div>
</div>

{literal}
<script>
(function () {
	var root = document.getElementById('c2cRoot');
	if (!root) { return; }

	// the page has fixed/transformed containers, and a dialog left inside one
	// is drawn under the panel header on phones; move it to <body>
	var modalHost = document.getElementById('c2cModal');
	if (modalHost && modalHost.parentNode !== document.body) {
		document.body.appendChild(modalHost);
	}

	var words = window.C2CWords || {};
	var orderId = root.getAttribute('data-order');
	var orderNo = root.getAttribute('data-order-no') || '';
	var amount = parseFloat(root.getAttribute('data-amount') || '0');
	var token = '';
	var card = null;
	var request = null;
	var enabled = false;
	var available = false;
	var ready = false;
	var timer = null;
	var mounted = false;
	var lastPayer = '';
	var noteText = '';
	var supportText = '';
	var titleText = words.title || '';

	function money(value) {
		return Number(value || 0).toLocaleString('en-US');
	}

	function withUnit(value) {
		var unit = '';
		if (words.curLeft) { unit += ' ' + words.curLeft; }
		if (words.curRight) { unit += ' ' + words.curRight; }

		return money(value) + unit;
	}

	function esc(value) {
		return String(value === null || value === undefined ? '' : value)
			.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
			.replace(/"/g, '&quot;').replace(/'/g, '&#39;');
	}

	function api(url, options) {
		return fetch(url, options || { credentials: 'same-origin' })
			.then(function (response) { return response.json(); });
	}

	function post(action, data) {
		var body = new FormData();
		Object.keys(data).forEach(function (key) { body.append(key, data[key]); });
		return api('/xmplus-patch.php?do=' + action, { method: 'POST', credentials: 'same-origin', body: body });
	}

	function nowLocal() {
		var d = new Date();
		var pad = function (n) { return String(n).padStart(2, '0'); };
		return d.getFullYear() + '-' + pad(d.getMonth() + 1) + '-' + pad(d.getDate())
			+ 'T' + pad(d.getHours()) + ':' + pad(d.getMinutes());
	}

	function showError(text) {
		var box = document.getElementById('c2cErr');
		if (!box) { return; }
		box.textContent = text;
		box.style.display = 'block';
	}

	function clearError() {
		var box = document.getElementById('c2cErr');
		if (box) { box.style.display = 'none'; }
	}

	function copyNumber() {
		if (!card) { return; }
		var value = card.number;
		var done = function () {
			var btn = document.getElementById('c2cCopy');
			if (btn) {
				var old = btn.textContent;
				btn.textContent = words.copied || old;
				window.setTimeout(function () { btn.textContent = old; }, 1600);
			}
		};

		if (navigator.clipboard && navigator.clipboard.writeText) {
			navigator.clipboard.writeText(value).then(done).catch(function () {});
			return;
		}

		var area = document.createElement('textarea');
		area.value = value;
		area.style.position = 'fixed';
		area.style.opacity = '0';
		document.body.appendChild(area);
		area.select();
		try { document.execCommand('copy'); done(); } catch (e) {}
		document.body.removeChild(area);
	}

	function cardBox() {
		if (!card) { return ''; }
		return '<div class="c2c-card">'
			+ '<div class="c2c-bank">🏦 ' + esc(card.bank || words.bank) + '</div>'
			+ '<div class="c2c-holder">' + esc(words.holder) + ': ' + esc(card.holder) + '</div>'
			+ '<div class="c2c-number"><b>' + esc(card.formatted) + '</b>'
			+ '<button type="button" class="c2c-copy" id="c2cCopy">' + esc(words.copy) + '</button></div>'
			+ '</div>';
	}

	function amountBox() {
		return '<div class="c2c-amount"><span>' + esc(words.amount) + '</span><b>' + withUnit(amount) + '</b></div>'
			+ '<div class="c2c-exact">' + esc(words.exact) + '</div>';
	}

	function renderForm() {
		var body = document.getElementById('c2cBody');
		if (!body) { return; }

		body.innerHTML = cardBox() + amountBox()
			+ '<div class="c2c-err" id="c2cErr"></div>'
			+ '<div class="c2c-field">'
			+ '  <label class="c2c-label" for="c2cLast4">' + esc(words.last4) + '</label>'
			+ '  <input class="c2c-input c2c-last4" id="c2cLast4" inputmode="numeric" maxlength="4" dir="ltr" autocomplete="off">'
			+ '  <span class="c2c-hint">' + esc(words.last4Hint) + '</span>'
			+ '</div>'
			+ '<details class="c2c-more">'
			+ '  <summary>' + esc(words.more) + '</summary>'
			+ '  <div class="c2c-field">'
			+ '    <label class="c2c-label" for="c2cPayer">' + esc(words.payer) + '</label>'
			+ '    <input class="c2c-input" id="c2cPayer" maxlength="120" value="' + esc(lastPayer) + '">'
			+ '  </div>'
			+ '  <div class="c2c-grid">'
			+ '    <div class="c2c-field">'
			+ '      <label class="c2c-label" for="c2cPaidAt">' + esc(words.paidAt) + '</label>'
			+ '      <input class="c2c-input" id="c2cPaidAt" type="datetime-local" value="' + nowLocal() + '">'
			+ '    </div>'
			+ '    <div class="c2c-field">'
			+ '      <label class="c2c-label" for="c2cRef">' + esc(words.ref) + '</label>'
			+ '      <input class="c2c-input" id="c2cRef" maxlength="80" dir="ltr" autocomplete="off">'
			+ '    </div>'
			+ '  </div>'
			+ '</details>'
			+ '<button type="button" class="c2c-submit" id="c2cSubmit">' + esc(words.submit) + '</button>'
			+ (noteText ? '<div class="c2c-note">' + esc(noteText) + '</div>' : '');

		var copy = document.getElementById('c2cCopy');
		if (copy) { copy.addEventListener('click', copyNumber); }

		var submit = document.getElementById('c2cSubmit');
		if (submit) { submit.addEventListener('click', submitForm); }

		var last4 = document.getElementById('c2cLast4');
		if (last4) {
			last4.addEventListener('input', function () {
				var digits = this.value.replace(/\D+/g, '');
				this.value = digits.length > 4 ? digits.slice(-4) : digits;
			});
			window.setTimeout(function () { last4.focus(); }, 250);
		}

		clearError();
	}

	function submitForm() {
		clearError();

		var last4 = (document.getElementById('c2cLast4') || {}).value || '';
		var payer = (document.getElementById('c2cPayer') || {}).value || '';
		var paidAt = (document.getElementById('c2cPaidAt') || {}).value || '';
		var reference = (document.getElementById('c2cRef') || {}).value || '';

		last4 = last4.replace(/\D+/g, '');
		if (last4.length > 4) { last4 = last4.slice(-4); }

		if (last4.length !== 4) { showError(words.badLast4); return; }
		if (!card) { showError(words.noCard); return; }

		var button = document.getElementById('c2cSubmit');
		if (button) { button.disabled = true; button.textContent = words.wait; }

		post('c2c.submit', {
			token: token,
			order: orderId,
			card: card.id,
			last4: last4,
			payer: payer.trim(),
			paid_at: paidAt.replace('T', ' '),
			ref: reference.trim()
		}).then(function (data) {
			if (!data || !data.ok) {
				if (button) { button.disabled = false; button.textContent = words.submit; }
				showError((data && data.error) ? data.error : words.error);
				return;
			}

			lastPayer = payer.trim();
			request = data.request || { status: 0, amount: amount, payer: payer.trim(), paid_at: paidAt.replace('T', ' ') };
			renderPending();
			waitPill(true);
		}).catch(function () {
			if (button) { button.disabled = false; button.textContent = words.submit; }
			showError(words.error);
		});
	}

	function stopPoll() {
		if (timer) { window.clearTimeout(timer); timer = null; }
	}

	function startPoll(first) {
		stopPoll();
		if (first) { checkStatus(); return; }
		timer = window.setTimeout(checkStatus, 5000);
	}

	function checkStatus() {
		api('/xmplus-patch.php?do=c2c.status&order=' + encodeURIComponent(orderId))
			.then(function (data) {
				if (!data || !data.ok) { startPoll(false); return; }
				if (data.request) { request = data.request; }
				if (data.request && Number(data.request.status) === 1) { renderApproved(); return; }
				if (data.request && Number(data.request.status) === 2) { renderRejected(data.request.note || ''); return; }
				renderPending();
				startPoll(false);
			})
			.catch(function () { startPoll(false); });
	}

	function renderPending() {
		var body = document.getElementById('c2cBody');
		if (!body) { return; }

		body.innerHTML = '<div class="c2c-pending">'
			+ '<div class="c2c-spin"></div>'
			+ '<h6>' + esc(words.pendingT) + '</h6>'
			+ '<p>' + esc(words.pendingX) + '</p>'
			+ '<span class="c2c-pill">🧾 ' + esc(words.orderNo) + ': ' + esc(orderNo) + '</span>'
			+ '<span class="c2c-pill">💰 ' + withUnit(request && request.amount ? request.amount : amount) + '</span>'
			+ '</div>'
			+ (card ? '<div class="c2c-note">🏦 ' + esc(card.bank) + ' · ' + esc(card.formatted) + '</div>' : '')
			+ (supportText ? '<div class="c2c-note">' + esc(words.support) + ': ' + esc(supportText) + '</div>' : '')
			+ '<div class="c2c-btn-line">'
			+ '<button type="button" class="c2c-btn-ghost" id="c2cRefresh">' + esc(words.checkNow) + '</button>'
			+ '<button type="button" class="c2c-btn-ghost" data-bs-dismiss="modal">' + esc(words.close) + '</button>'
			+ '</div>';

		var refresh = document.getElementById('c2cRefresh');
		if (refresh) { refresh.addEventListener('click', function () { checkStatus(); }); }

		startPoll(false);
	}

	function renderRejected(reason) {
		stopPoll();
		var body = document.getElementById('c2cBody');
		if (!body) { return; }

		body.innerHTML = '<div class="c2c-fail">'
			+ '<span class="c2c-no-icon">❌</span>'
			+ '<h6>' + esc(words.rejected) + '</h6>'
			+ '<p>' + esc(reason || '') + '</p>'
			+ '</div>'
			+ (supportText ? '<div class="c2c-note">' + esc(words.support) + ': ' + esc(supportText) + '</div>' : '')
			+ '<div class="c2c-btn-line">'
			+ '<button type="button" class="c2c-btn-ghost" id="c2cAgain">' + esc(words.again) + '</button>'
			+ '<button type="button" class="c2c-btn-ghost" data-bs-dismiss="modal">' + esc(words.close) + '</button>'
			+ '</div>';

		var again = document.getElementById('c2cAgain');
		if (again) {
			again.addEventListener('click', function () {
				request = null;
				renderForm();
			});
		}
	}

	function renderApproved() {
		stopPoll();
		waitPill(false);

		var body = document.getElementById('c2cBody');
		if (body) {
			body.innerHTML = '<div class="c2c-done">'
				+ '<span class="c2c-ok-icon">✅</span>'
				+ '<h6>' + esc(words.approvedT) + '</h6>'
				+ '<p>' + esc(words.approvedX) + '</p>'
				+ '</div>'
				+ '<div class="c2c-btn-line">'
				+ '<a class="c2c-submit" style="text-align:center;text-decoration:none;line-height:1.4" href="/portal/orders">'
				+ esc(words.goOrders) + '</a>'
				+ '</div>';
		}

		if (window.OrderResult && window.OrderResult.show) {
			window.OrderResult.show({
				kind: 'ok',
				title: words.approvedT,
				text: words.approvedX,
				button: words.goOrders,
				seconds: 6,
				meta: []
			});
		}

		window.setTimeout(function () { window.location.href = '/portal/dashboard'; }, 5000);
	}

	function waitPill(on) {
		var pill = document.getElementById('c2cWaitPill');
		if (pill) { pill.style.display = on ? 'block' : 'none'; }
	}

	function open() {
		if (!enabled) {
			return;
		}

		var modal = document.getElementById('c2cModal');
		if (modal && modal.classList.contains('show')) { return; }

		document.getElementById('c2cTopTitle').textContent = titleText;
		document.getElementById('c2cTopSub').textContent = words.sub || '';

		if (request && Number(request.status) === 1) {
			renderApproved();
		} else if (request && Number(request.status) === 2) {
			renderRejected(request.note || '');
		} else if (request && Number(request.status) === 0) {
			renderPending();
		} else if (card) {
			renderForm();
		} else {
			var body = document.getElementById('c2cBody');
			if (body) {
				body.innerHTML = '<div class="c2c-pending"><h6>' + esc(words.noCard) + '</h6></div>';
			}
		}

		var modalEl = document.getElementById('c2cModal');
		if (modalEl) {
			if (window.bootstrap && window.bootstrap.Modal) {
				window.bootstrap.Modal.getOrCreateInstance(modalEl, {}).show();
			} else if (window.jQuery) {
				window.jQuery(modalEl).modal('show');
			}
		}
	}

	function mount() {
		if (mounted || !enabled) { return; }

		var grid = document.querySelector('.py-ways');
		if (!grid) { return; }

		var label = document.createElement('label');
		label.className = 'py-way';
		label.innerHTML = '<input type="radio" name="payments" id="pay-c2c" value="c2c" onClick="Gatewayfee()">'
			+ '<span class="py-way-box"><span class="py-way-icon">🏦</span>' + esc(titleText) + '</span>';
		grid.appendChild(label);

		// the pay button only gets the panel's own handler when a gateway was
		// found; without one, card-to-card still needs to open its dialog
		var checkout = document.getElementById('checkout');
		if (checkout) {
			checkout.addEventListener('click', function (event) {
				var picked = document.querySelector("input[name='payments']:checked");
				if (!picked || picked.value !== 'c2c') { return; }

				event.preventDefault();
				open();
			});
		}

		var pill = document.createElement('div');
		pill.className = 'c2c-wait';
		pill.id = 'c2cWaitPill';
		pill.textContent = words.pendingPill || '';
		grid.parentNode.appendChild(pill);

		var picked = document.querySelector("input[name='payments']:checked");
		if (!picked) {
			document.getElementById('pay-c2c').checked = true;
			if (typeof window.Gatewayfee === 'function') { window.Gatewayfee(); }
		}

		if (request && Number(request.status) === 0) {
			waitPill(true);
		}

		mounted = true;
	}

	function load() {
		api('/xmplus-patch.php?do=c2c.info&order=' + encodeURIComponent(orderId))
			.then(function (data) {
				if (!data || !data.ok) { return; }

				enabled = Number(data.enabled) === 1;
				available = Number(data.available) === 1;
				token = data.token || '';
				card = data.card || null;
				request = data.request || null;
				lastPayer = data.last_payer || '';
				noteText = data.note || '';
				supportText = data.support || '';
				titleText = data.title || words.title || '';
				ready = true;

				if (enabled && (available || request)) {
					mount();
				}
			})
			.catch(function () {});
	}

	window.C2C = { open: open, setAmount: function(value) { amount = Math.max(0, Number(value) || 0); root.setAttribute('data-amount', String(amount)); } };

	if (document.readyState === 'loading') {
		document.addEventListener('DOMContentLoaded', load);
	} else {
		load();
	}
})();
</script>
{/literal}
