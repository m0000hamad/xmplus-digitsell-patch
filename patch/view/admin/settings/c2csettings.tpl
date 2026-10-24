{*
  Card-to-card - admin side.
  Included by settings.tpl; everything is read from and written to
  /xmplus-patch.php?do=c2c.* (app/Patch/Card2Card.php).

  Cards rotate: each one carries a cap (amount and/or number of payments,
  measured per day / per month / in total). The checkout always shows the first
  enabled card in sort order that still has room, and moves to the next one by
  itself when a cap is reached.
*}
<div class="card card-shadow shadow-lg rounded mb-3 mb-lg-5" id="C2cSettings">
	<div class="card-header">
		<h4 class="card-header-title">💳 {$translate->get('C2cAdmTitle')}</h4>
	</div>
	<div class="card-body cc">
		<p class="text-muted small">{$translate->get('C2cAdmIntro')}</p>

		<div class="cc-kpis" id="ccKpis"></div>

		<h5 class="cc-h">⚙️ {$translate->get('C2cAdmSettings')}</h5>
		<div class="cc-grid">
			<label class="cc-check"><input type="checkbox" id="cc_enabled"> {$translate->get('C2cAdmEnabled')}</label>
			<label class="cc-check"><input type="checkbox" id="cc_tg_ready" disabled> {$translate->get('C2cAdmTelegram')}</label>
		</div>
		<div class="row g-3 mt-1">
			<div class="col-md-6">
				<label class="form-label" for="cc_chat">{$translate->get('C2cAdmChat')}</label>
				<input type="text" class="form-control" id="cc_chat" dir="ltr" placeholder="123456789, -100123456789">
				<small class="text-muted">{$translate->get('C2cAdmChatHint')}</small>
			</div>
			<div class="col-md-6">
				<label class="form-label" for="cc_site_url">{$translate->get('C2cAdmSiteUrl')}</label>
				<input type="text" class="form-control" id="cc_site_url" dir="ltr" placeholder="https://panel.example.com">
				<small class="text-muted">{$translate->get('C2cAdmSiteUrlHint')}</small>
			</div>
			<div class="col-md-6">
				<label class="form-label" for="cc_bot_mode">{$translate->get('C2cAdmMode')}</label>
				<select class="form-select" id="cc_bot_mode">
					<option value="poll">{$translate->get('C2cAdmModePoll')}</option>
					<option value="webhook">{$translate->get('C2cAdmModeHook')}</option>
				</select>
				<small class="text-muted">{$translate->get('C2cAdmModeHint')}</small>
			</div>
			<div class="col-12">
				<label class="form-label" for="cc_bot_token">{$translate->get('C2cAdmBot')}</label>
				<input type="text" class="form-control" id="cc_bot_token" dir="ltr" autocomplete="off" placeholder="123456789:AAH...">
				<small class="text-muted">{$translate->get('C2cAdmBotHint')}</small>
				<div class="d-flex align-items-center gap-2 mt-2 flex-wrap">
					<span class="cc-webhook" id="ccWebhookStatus"></span>
					<button type="button" class="btn btn-sm btn-outline-primary" id="ccWebhook">{$translate->get('C2cAdmWebhookSet')}</button>
				</div>
			</div>
			<div class="col-md-3">
				<label class="form-label" for="cc_reject_hours">{$translate->get('C2cAdmRejectHours')}</label>
				<input type="number" class="form-control" id="cc_reject_hours" min="0" max="8760" dir="ltr">
				<small class="text-muted">{$translate->get('C2cAdmRejectHint')}</small>
			</div>
			<div class="col-md-3">
				<label class="form-label" for="cc_hold_hours">{$translate->get('C2cAdmHoldHours')}</label>
				<input type="number" class="form-control" id="cc_hold_hours" min="1" max="8760" dir="ltr">
				<small class="text-muted">{$translate->get('C2cAdmHoldHint')}</small>
			</div>
			<div class="col-md-6">
				<label class="form-label" for="cc_grant_mode">{$translate->get('C2cAdmGrantMode')}</label>
				<select class="form-select" id="cc_grant_mode">
					<option value="auto">{$translate->get('C2cAdmGrantAuto')}</option>
					<option value="fresh">{$translate->get('C2cAdmGrantFresh')}</option>
				</select>
				<small class="text-muted">{$translate->get('C2cAdmGrantHint')}</small>
			</div>
			<div class="col-md-6">
				<label class="form-label" for="cc_support">{$translate->get('C2cAdmSupport')}</label>
				<input type="text" class="form-control" id="cc_support" dir="ltr" autocomplete="off" placeholder="@digitsellshop">
				<small class="text-muted">{$translate->get('C2cAdmSupportHint')}</small>
			</div>
			<div class="col-md-6">
				<label class="form-label" for="cc_test_user">{$translate->get('C2cAdmTestUser')}</label>
				<input type="number" class="form-control" id="cc_test_user" min="0" dir="ltr" placeholder="0">
				<small class="text-muted">{$translate->get('C2cAdmTestHint')}</small>
			</div>
			<div class="col-12">
				<label class="form-label" for="cc_note">{$translate->get('C2cAdmNote')}</label>
				<textarea class="form-control" id="cc_note" rows="3"></textarea>
			</div>
		</div>
		<div class="d-flex justify-content-end align-items-center gap-3 mt-3">
			<span class="cc-status" id="ccStatus" role="status"></span>
			<button type="button" class="btn btn-primary" id="ccSave">💾 {$translate->get('Save')}</button>
		</div>

		<div class="cc-head">
			<h5 class="cc-h">🏦 {$translate->get('C2cAdmCards')}</h5>
			<span class="cc-active" id="ccActive"></span>
			<button type="button" class="btn btn-sm btn-outline-primary ms-auto" id="ccAddCard">＋ {$translate->get('C2cAdmAddCard')}</button>
		</div>
		<p class="text-muted small mb-2">{$translate->get('C2cAdmCardsHint')}</p>
		<div class="table-responsive">
			<table class="table table-sm align-middle cc-table">
				<thead><tr>
					<th>{$translate->get('C2cAdmNumber')}</th>
					<th>{$translate->get('C2cAdmHolder')}</th>
					<th>{$translate->get('C2cAdmBank')}</th>
					<th>{$translate->get('C2cAdmLimitAmount')}</th>
					<th>{$translate->get('C2cAdmLimitCount')}</th>
					<th>{$translate->get('C2cAdmPeriod')}</th>
					<th>{$translate->get('C2cAdmUsage')}</th>
					<th>{$translate->get('C2cAdmSort')}</th>
					<th>{$translate->get('C2cAdmOn')}</th>
					<th></th>
				</tr></thead>
				<tbody id="ccCards"></tbody>
			</table>
		</div>
		<div class="d-flex justify-content-end align-items-center gap-3 mt-2">
			<small class="text-muted">{$translate->get('C2cAdmLimitHint')}</small>
			<button type="button" class="btn btn-primary" id="ccSaveCards">💾 {$translate->get('C2cAdmSaveCards')}</button>
		</div>

		<h5 class="cc-h">🕒 {$translate->get('C2cAdmPending')} <span class="cc-count" id="ccPendingCount">0</span></h5>
		<div id="ccPending" class="cc-pending"></div>

		<h5 class="cc-h">📋 {$translate->get('C2cAdmHistory')}</h5>
		<div class="table-responsive">
			<table class="table table-sm cc-table">
				<thead><tr>
					<th>#</th>
					<th>{$translate->get('C2cAdmOrder')}</th>
					<th>{$translate->get('C2cAdmUser')}</th>
					<th>{$translate->get('C2cAdmPlan')}</th>
					<th>{$translate->get('C2cAdmAmount')}</th>
					<th>{$translate->get('C2cAdmLast4')}</th>
					<th>{$translate->get('C2cAdmStatus')}</th>
					<th>{$translate->get('C2cAdmDecided')}</th>
				</tr></thead>
				<tbody id="ccHistory"></tbody>
			</table>
		</div>
		<div class="d-flex justify-content-end mt-2">
			<button type="button" class="btn btn-outline-danger" id="ccReset">🗑 {$translate->get('C2cAdmReset')}</button>
		</div>
	</div>
</div>

<script>
window.C2CAdminWords = {
	saved:      "{$translate->get('C2cAdmSaved')|escape:'javascript'}",
	error:      "{$translate->get('C2cAdmError')|escape:'javascript'}",
	empty:      "{$translate->get('C2cAdmEmpty')|escape:'javascript'}",
	approve:    "{$translate->get('C2cAdmApprove')|escape:'javascript'}",
	reject:     "{$translate->get('C2cAdmReject')|escape:'javascript'}",
	notePh:     "{$translate->get('C2cAdmNotePh')|escape:'javascript'}",
	approved:   "{$translate->get('C2cAdmApproveOk')|escape:'javascript'}",
	rejected:   "{$translate->get('C2cAdmRejectOk')|escape:'javascript'}",
	fail:       "{$translate->get('C2cAdmFail')|escape:'javascript'}",
	sPending:   "{$translate->get('C2cAdmStatusPending')|escape:'javascript'}",
	sApproved:  "{$translate->get('C2cAdmStatusApproved')|escape:'javascript'}",
	sRejected:  "{$translate->get('C2cAdmStatusRejected')|escape:'javascript'}",
	sCancelled: "{$translate->get('C2cAdmStatusCancelled')|escape:'javascript'}",
	activeCard: "{$translate->get('C2cAdmActive')|escape:'javascript'}",
	full:       "{$translate->get('C2cAdmFull')|escape:'javascript'}",
	unlimited:  "{$translate->get('C2cAdmUnlimited')|escape:'javascript'}",
	day:        "{$translate->get('C2cAdmPeriodDay')|escape:'javascript'}",
	month:      "{$translate->get('C2cAdmPeriodMonth')|escape:'javascript'}",
	total:      "{$translate->get('C2cAdmPeriodTotal')|escape:'javascript'}",
	noCard:     "{$translate->get('C2cAdmNoCardAvailable')|escape:'javascript'}",
	refresh:    "{$translate->get('C2cAdmRefresh')|escape:'javascript'}",
	deleteOne:  "{$translate->get('C2cAdmDelete')|escape:'javascript'}",
	enabled:    "{$translate->get('C2cAdmEnabled')|escape:'javascript'}",
	webhookOk:   "{$translate->get('C2cAdmWebhookOk')|escape:'javascript'}",
	webhookFail: "{$translate->get('C2cAdmWebhookFail')|escape:'javascript'}",
	webhookNone: "{$translate->get('C2cAdmWebhookNone')|escape:'javascript'}",
	pollOk:      "{$translate->get('C2cAdmPollOk')|escape:'javascript'}",
	testBadge:   "{$translate->get('C2cAdmTestBadge')|escape:'javascript'}",
	resetAsk:    "{$translate->get('C2cAdmResetAsk')|escape:'javascript'}",
	resetOk:     "{$translate->get('C2cAdmResetOk')|escape:'javascript'}"
};
</script>

{literal}
<style>
.cc-kpis { display: flex; flex-wrap: wrap; gap: 8px; margin-bottom: 14px; }
.cc-chip {
	display: inline-flex;
	align-items: center;
	gap: 6px;
	background: rgba(16, 185, 129, .12);
	border-radius: 999px;
	padding: 5px 12px;
	font-size: 12px;
	font-weight: 700;
	color: #047857;
}
.cc-chip.warn { background: rgba(245, 158, 11, .14); color: #b45309; }
.cc-chip.bad { background: rgba(244, 63, 94, .12); color: #be123c; }
.cc-h { margin: 18px 0 10px; font-size: 14px; font-weight: 800; }
.cc-head { display: flex; align-items: center; gap: 10px; flex-wrap: wrap; }
.cc-active { font-size: 11.5px; font-weight: 700; color: #047857; background: rgba(16, 185, 129, .12); border-radius: 999px; padding: 5px 11px; }
.cc-grid { display: flex; flex-wrap: wrap; gap: 14px; margin-top: 4px; }
.cc-check { display: inline-flex; align-items: center; gap: 7px; font-size: 12.5px; font-weight: 700; color: #475569; }
.cc-status { font-size: 12px; font-weight: 700; color: #047857; }
.cc-webhook { font-size: 11.5px; font-weight: 700; color: #047857; }
.cc-webhook.bad { color: #be123c; }
.cc-webhook.none { color: #64748b; }
.cc-table { min-width: 760px; font-size: 12px; }
.cc-table th { font-size: 11px; color: #64748b; white-space: nowrap; }
.cc-table td { vertical-align: middle; }
.cc-table .form-control, .cc-table .form-select { font-size: 11.5px; padding: 5px 8px; min-width: 70px; }
.cc-table .cc-num { min-width: 150px; direction: ltr; }
.cc-used { font-size: 10.5px; color: #64748b; white-space: nowrap; line-height: 1.8; }
.cc-used b { color: #16203d; }
.cc-row-off { opacity: .55; }
.cc-del { border: 0; background: rgba(244, 63, 94, .12); color: #be123c; border-radius: 8px; width: 28px; height: 28px; font-size: 14px; line-height: 1; cursor: pointer; }
.cc-pending { display: grid; gap: 12px; }
.cc-pend {
	border: 1px solid rgba(16, 185, 129, .3);
	border-radius: 14px;
	padding: 13px 14px;
	background: linear-gradient(135deg, rgba(16, 185, 129, .07), rgba(6, 182, 212, .04));
}
.cc-pend-head { display: flex; align-items: center; gap: 8px; flex-wrap: wrap; margin-bottom: 6px; }
.cc-pend-id { font-size: 11.5px; font-weight: 800; color: #047857; }
.cc-pend-amount { font-size: 14px; font-weight: 800; color: #0f172a; direction: ltr; unicode-bidi: isolate; margin-inline-start: auto; }
.cc-pend-meta { font-size: 11.5px; color: #475569; line-height: 2; }
.cc-pend-meta b { color: #16203d; }
.cc-pend-lines { display: grid; grid-template-columns: 1fr 1fr; gap: 4px 14px; margin: 6px 0 10px; }
.cc-pend-actions { display: flex; gap: 8px; align-items: center; }
.cc-pend-actions .form-control { flex: 1 1 auto; font-size: 11.5px; }
.cc-ok { border: 0; border-radius: 10px; padding: 8px 14px; font-size: 12px; font-weight: 800; color: #fff; background: #059669; cursor: pointer; }
.cc-no { border: 0; border-radius: 10px; padding: 8px 14px; font-size: 12px; font-weight: 800; color: #fff; background: #dc2626; cursor: pointer; }
.cc-count { font-size: 11px; font-weight: 800; color: #b45309; background: rgba(245, 158, 11, .16); border-radius: 999px; padding: 2px 9px; }
.cc-empty { font-size: 12px; color: #94a3b8; padding: 10px 0; }
.cc-badge { border-radius: 999px; padding: 3px 10px; font-size: 10.5px; font-weight: 800; }
.cc-badge.p { background: rgba(245, 158, 11, .16); color: #b45309; }
.cc-badge.a { background: rgba(16, 185, 129, .16); color: #047857; }
.cc-badge.r { background: rgba(244, 63, 94, .14); color: #be123c; }
.cc-badge.c { background: rgba(100, 116, 139, .16); color: #475569; }
html[data-hs-theme="dark"] .cc-table td { color: #cbd5e1; }
html[data-hs-theme="dark"] .cc-used b, html[data-hs-theme="dark"] .cc-pend-amount,
html[data-hs-theme="dark"] .cc-pend-meta b { color: #e7eaf3; }
html[data-hs-theme="dark"] .cc-pend { background: linear-gradient(135deg, rgba(16, 185, 129, .13), rgba(6, 182, 212, .06)); }
@media (max-width: 575px) {
	.cc-pend-lines { grid-template-columns: 1fr; }
	.cc-pend-actions { flex-wrap: wrap; }
	.cc-pend-actions .form-control { flex-basis: 100%; }
}
</style>
{/literal}

{literal}
<script>
(function () {
	var words = window.C2CAdminWords || {};
	var token = '';
	var data = { cards: [], pending: [], history: [], active: 0, settings: {} };

	function money(value) {
		return Number(value || 0).toLocaleString('en-US');
	}

	function esc(value) {
		return String(value === null || value === undefined ? '' : value)
			.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
			.replace(/"/g, '&quot;').replace(/'/g, '&#39;');
	}

	function stamp(value) {
		if (!value) { return '—'; }
		var d = new Date(Number(value) * 1000);
		var pad = function (n) { return String(n).padStart(2, '0'); };
		return d.getFullYear() + '-' + pad(d.getMonth() + 1) + '-' + pad(d.getDate())
			+ ' ' + pad(d.getHours()) + ':' + pad(d.getMinutes());
	}

	function statusBadge(status) {
		var map = {
			'0': ['p', words.sPending],
			'1': ['a', words.sApproved],
			'2': ['r', words.sRejected],
			'3': ['c', words.sCancelled]
		};
		var item = map[String(status)] || ['c', String(status)];
		return '<span class="cc-badge ' + item[0] + '">' + esc(item[1]) + '</span>';
	}

	function periodWord(period) {
		if (period === 'month') { return words.month; }
		if (period === 'total') { return words.total; }
		return words.day;
	}

	function post(action, payload) {
		var body = new FormData();
		body.append('token', token);
		Object.keys(payload).forEach(function (key) { body.append(key, payload[key]); });

		return fetch('/xmplus-patch.php?do=' + action, {
			method: 'POST',
			credentials: 'same-origin',
			body: body
		}).then(function (response) { return response.json(); });
	}

	function flash(text, bad) {
		var node = document.getElementById('ccStatus');
		if (!node) { return; }
		node.textContent = text || '';
		node.style.color = bad ? '#be123c' : '#047857';
		if (text) { window.setTimeout(function () { node.textContent = ''; }, 4000); }
	}

	function apply(next) {
		data = {
			settings: next.settings || {},
			cards: next.cards || [],
			pending: next.pending || [],
			history: next.history || [],
			active: next.active || 0
		};

		if (next.token) { token = next.token; }

		renderSettings();
		renderCards();
		renderPending();
		renderHistory();
		renderKpis();
	}

	function load() {
		fetch('/xmplus-patch.php?do=c2c.admin', { credentials: 'same-origin' })
			.then(function (response) { return response.json(); })
			.then(function (next) { if (next && next.ok) { apply(next); } })
			.catch(function () {});
	}

	function renderSettings() {
		var s = data.settings || {};
		var set = function (id, value) {
			var node = document.getElementById(id);
			if (node) { node.value = value; }
		};

		var enabled = document.getElementById('cc_enabled');
		if (enabled) { enabled.checked = Number(s.enabled) === 1; }

		var tg = document.getElementById('cc_tg_ready');
		if (tg) { tg.checked = s.telegram ? true : false; }

		set('cc_chat', s.chat || '');
		set('cc_site_url', s.site_url || '');
		set('cc_note', s.note || '');
		set('cc_reject_hours', s.reject_hours);
		set('cc_hold_hours', s.hold_hours);
		set('cc_bot_token', s.bot_token || '');
		set('cc_support', s.support || '');
		set('cc_test_user', s.test_user || 0);

		var mode = document.getElementById('cc_grant_mode');
		if (mode) { mode.value = s.grant_mode === 'fresh' ? 'fresh' : 'auto'; }

		var botMode = document.getElementById('cc_bot_mode');
		if (botMode) { botMode.value = s.mode === 'webhook' ? 'webhook' : 'poll'; }

		var chat = document.getElementById('cc_chat');
		if (chat && !chat.value && s.fallback_chat) {
			chat.placeholder = s.fallback_chat;
		}

		var hook = document.getElementById('ccWebhookStatus');
		if (hook) {
			hook.className = 'cc-webhook';

			if (!s.bot_token) {
				hook.textContent = words.webhookNone;
				hook.className = 'cc-webhook none';
			} else if (s.mode !== 'webhook') {
				hook.textContent = words.pollOk;
			} else if (Number(s.webhook_ok) === 1) {
				hook.textContent = words.webhookOk;
			} else {
				hook.textContent = words.webhookFail + (s.webhook_error ? ' — ' + s.webhook_error : '');
				hook.className = 'cc-webhook bad';
			}
		}
	}

	function renderKpis() {
		var box = document.getElementById('ccKpis');
		if (!box) { return; }

		var waiting = data.pending.length;
		var active = null;
		data.cards.forEach(function (card) { if (Number(card.id) === Number(data.active)) { active = card; } });

		var html = '<span class="cc-chip ' + (waiting > 0 ? 'warn' : '') + '">🕒 '
			+ esc(words.sPending) + ': <b>' + waiting + '</b></span>';

		if (active) {
			html += '<span class="cc-chip">💳 ' + esc(words.activeCard) + ': '
				+ esc(active.bank) + ' · ' + esc(active.formatted) + '</span>';
		} else {
			html += '<span class="cc-chip bad">' + esc(words.noCard) + '</span>';
		}

		var on = document.getElementById('cc_enabled');
		html += '<span class="cc-chip ' + (on && on.checked ? '' : 'warn') + '">'
			+ (on && on.checked ? '✅ ' : '⏸ ') + esc(words.enabled) + '</span>';

		box.innerHTML = html;
	}

	function renderCards() {
		var body = document.getElementById('ccCards');
		if (!body) { return; }

		body.innerHTML = '';

		if (!data.cards.length) {
			body.innerHTML = '<tr><td colspan="10" class="cc-empty">' + esc(words.noCard) + '</td></tr>';
		}

		data.cards.forEach(function (card) {
			var tr = document.createElement('tr');
			tr.setAttribute('data-id', card.id);
			tr.innerHTML =
				'<td><input class="form-control cc-num" data-f="number" dir="ltr" maxlength="19" value="' + esc(card.number) + '"></td>'
				+ '<td><input class="form-control" data-f="holder" maxlength="120" value="' + esc(card.holder) + '"></td>'
				+ '<td><input class="form-control" data-f="bank" maxlength="120" value="' + esc(card.bank) + '"></td>'
				+ '<td><input class="form-control" data-f="limit_amount" type="number" min="0" dir="ltr" value="' + esc(card.limit_amount) + '"></td>'
				+ '<td><input class="form-control" data-f="limit_count" type="number" min="0" dir="ltr" value="' + esc(card.limit_count) + '"></td>'
				+ '<td><select class="form-select" data-f="period">'
				+ '<option value="day"' + (card.period === 'day' ? ' selected' : '') + '>' + esc(words.day) + '</option>'
				+ '<option value="month"' + (card.period === 'month' ? ' selected' : '') + '>' + esc(words.month) + '</option>'
				+ '<option value="total"' + (card.period === 'total' ? ' selected' : '') + '>' + esc(words.total) + '</option>'
				+ '</select></td>'
				+ '<td><div class="cc-used">' + money(card.used_amount) + ' / '
				+ (Number(card.limit_amount) > 0 ? money(card.limit_amount) : esc(words.unlimited)) + '<br>'
				+ card.used_count + ' / ' + (Number(card.limit_count) > 0 ? card.limit_count : esc(words.unlimited))
				+ (Number(card.room) === 1 ? '' : ' · <b>' + esc(words.full) + '</b>') + '</div></td>'
				+ '<td><input class="form-control" data-f="sort" type="number" dir="ltr" value="' + esc(card.sort) + '" style="min-width:60px"></td>'
				+ '<td><input type="checkbox" data-f="enabled"' + (Number(card.enabled) === 1 ? ' checked' : '') + '></td>'
				+ '<td><button type="button" class="cc-del" data-del="' + card.id + '" title="' + esc(words.deleteOne) + '">×</button></td>';

			if (Number(card.room) !== 1) { tr.classList.add('cc-row-off'); }
			body.appendChild(tr);
		});

		var activeBox = document.getElementById('ccActive');
		if (activeBox) {
			var active = null;
			data.cards.forEach(function (card) { if (Number(card.id) === Number(data.active)) { active = card; } });
			activeBox.textContent = active
				? (words.activeCard + ': ' + active.bank + ' · ' + active.formatted)
				: words.noCard;
		}
	}

	function cardRow() {
		var tr = document.createElement('tr');
		tr.setAttribute('data-id', '0');
		tr.innerHTML =
			'<td><input class="form-control cc-num" data-f="number" dir="ltr" maxlength="19" placeholder="6037 9911 2233 4455"></td>'
			+ '<td><input class="form-control" data-f="holder" maxlength="120"></td>'
			+ '<td><input class="form-control" data-f="bank" maxlength="120"></td>'
			+ '<td><input class="form-control" data-f="limit_amount" type="number" min="0" dir="ltr" value="0"></td>'
			+ '<td><input class="form-control" data-f="limit_count" type="number" min="0" dir="ltr" value="0"></td>'
			+ '<td><select class="form-select" data-f="period">'
			+ '<option value="day">' + esc(words.day) + '</option>'
			+ '<option value="month">' + esc(words.month) + '</option>'
			+ '<option value="total">' + esc(words.total) + '</option>'
			+ '</select></td>'
			+ '<td class="cc-used">—</td>'
			+ '<td><input class="form-control" data-f="sort" type="number" dir="ltr" value="0" style="min-width:60px"></td>'
			+ '<td><input type="checkbox" data-f="enabled" checked></td>'
			+ '<td><button type="button" class="cc-del" data-del="new" title="' + esc(words.deleteOne) + '">×</button></td>';
		return tr;
	}

	function collectCards() {
		var rows = [];
		document.querySelectorAll('#ccCards tr[data-id]').forEach(function (tr) {
			var id = Number(tr.getAttribute('data-id'));
			var get = function (field) {
				var node = tr.querySelector('[data-f="' + field + '"]');
				return node ? node.value : '';
			};
			var checked = tr.querySelector('[data-f="enabled"]');

			rows.push({
				id: id,
				number: get('number').replace(/\D+/g, ''),
				holder: get('holder'),
				bank: get('bank'),
				limit_amount: get('limit_amount'),
				limit_count: get('limit_count'),
				period: get('period'),
				sort: get('sort'),
				enabled: checked && checked.checked ? 1 : 0,
				deleted: tr.getAttribute('data-deleted') === '1' ? 1 : 0
			});
		});
		return rows;
	}

	function renderPending() {
		var box = document.getElementById('ccPending');
		if (!box) { return; }

		var count = document.getElementById('ccPendingCount');
		if (count) { count.textContent = data.pending.length; }

		box.innerHTML = '';

		if (!data.pending.length) {
			box.innerHTML = '<div class="cc-empty">' + esc(words.empty) + '</div>';
			return;
		}

		data.pending.forEach(function (row) {
			var node = document.createElement('div');
			node.className = 'cc-pend';
			node.setAttribute('data-id', row.id);
			node.innerHTML =
				'<div class="cc-pend-head">'
				+ '<span class="cc-pend-id">#' + row.id + ' · ' + esc(row.order_no || ('#' + row.orderid)) + '</span>'
				+ (row.tg_sent ? '<span class="cc-badge a">TG</span>' : '<span class="cc-badge p">TG?</span>')
				+ (Number(row.test) === 1 ? '<span class="cc-badge c">🧪 ' + esc(words.testBadge) + '</span>' : '')
				+ '<span class="cc-pend-amount">' + money(row.amount) + ' <small>ریال</small></span>'
				+ '</div>'
				+ '<div class="cc-pend-lines">'
				+ '<div class="cc-pend-meta">👤 <b>' + esc(row.username || ('#' + row.userid)) + '</b> (#' + row.userid + ')</div>'
				+ '<div class="cc-pend-meta">📦 <b>' + esc(row.plan_name || '—') + '</b>'
				+ (Number(row.plan_days) > 0 ? ' · ' + row.plan_days + ' روز' : '') + '</div>'
				+ '<div class="cc-pend-meta">🏦 ' + esc(row.card_bank || '') + ' · <b>' + esc(row.card_last4 || '') + '</b></div>'
				+ (row.payer ? '<div class="cc-pend-meta">✍️ ' + esc(row.payer) + '</div>' : '')
				+ (row.paid_at ? '<div class="cc-pend-meta">🕒 ' + esc(row.paid_at) + '</div>' : '')
				+ (row.ref ? '<div class="cc-pend-meta">🔖 ' + esc(row.ref) + '</div>' : '')
				+ '<div class="cc-pend-meta">📥 ' + stamp(row.created) + '</div>'
				+ '</div>'
				+ '<div class="cc-pend-actions">'
				+ '<input class="form-control" data-note placeholder="' + esc(words.notePh) + '">'
				+ '<button type="button" class="cc-ok" data-approve>✔ ' + esc(words.approve) + '</button>'
				+ '<button type="button" class="cc-no" data-reject>✖ ' + esc(words.reject) + '</button>'
				+ '</div>';

			box.appendChild(node);
		});
	}

	function renderHistory() {
		var body = document.getElementById('ccHistory');
		if (!body) { return; }

		body.innerHTML = '';

		if (!data.history.length) {
			body.innerHTML = '<tr><td colspan="8" class="cc-empty">' + esc(words.empty) + '</td></tr>';
			return;
		}

		data.history.forEach(function (row) {
			var tr = document.createElement('tr');
			tr.innerHTML = '<td>' + row.id + '</td>'
				+ '<td>' + esc(row.order_no || ('#' + row.orderid)) + '</td>'
				+ '<td>' + esc(row.username || ('#' + row.userid)) + '</td>'
				+ '<td>' + esc(row.plan_name || '—') + '</td>'
				+ '<td>' + money(row.amount) + '</td>'
				+ '<td dir="ltr">' + esc(row.card_last4 || '') + '</td>'
				+ '<td>' + statusBadge(row.status) + '</td>'
				+ '<td>' + stamp(row.decided_at) + (row.note ? ' · ' + esc(row.note) : '') + '</td>';
			body.appendChild(tr);
		});
	}

	function ready(fn) {
		if (document.readyState === 'loading') {
			document.addEventListener('DOMContentLoaded', fn);
		} else {
			fn();
		}
	}

	// no jQuery here: the admin page loads it in the footer, after this
	// inline script runs, so "$" does not exist yet at parse time
	ready(function () {
		load();

		document.getElementById('cc_enabled').addEventListener('change', function () {
			renderKpis();
		});

		document.getElementById('ccAddCard').addEventListener('click', function () {
			document.getElementById('ccCards').appendChild(cardRow());
		});

		document.getElementById('ccCards').addEventListener('click', function (event) {
			var button = event.target.closest('[data-del]');
			if (!button) { return; }

			var tr = button.closest('tr');
			if (!tr) { return; }

			if (tr.getAttribute('data-id') === '0') {
				tr.parentNode.removeChild(tr);
				return;
			}

			tr.setAttribute('data-deleted', '1');
			tr.style.display = 'none';
		});

		document.getElementById('ccSave').addEventListener('click', function () {
			post('c2c.settings', {
				enabled: document.getElementById('cc_enabled').checked ? 1 : 0,
				chat: document.getElementById('cc_chat').value.trim(),
				site_url: document.getElementById('cc_site_url').value.trim(),
				note: document.getElementById('cc_note').value,
				reject_hours: document.getElementById('cc_reject_hours').value,
				hold_hours: document.getElementById('cc_hold_hours').value,
				grant_mode: document.getElementById('cc_grant_mode').value,
				bot_token: document.getElementById('cc_bot_token').value.trim(),
				support: document.getElementById('cc_support').value.trim(),
				test_user: document.getElementById('cc_test_user').value || 0,
				bot_mode: document.getElementById('cc_bot_mode').value
			}).then(function (next) {
				if (!next || !next.ok) {
					flash((next && next.error) || words.error, true);
					return;
				}
				apply(next);
				flash(words.saved);
			}).catch(function () { flash(words.error, true); });
		});

		var hook = document.getElementById('ccWebhook');
		if (hook) {
			hook.addEventListener('click', function () {
				post('c2c.webhook', {}).then(function (next) {
					if (!next || !next.ok) {
						flash((next && next.error) || words.webhookFail, true);
						return;
					}
					apply(next);
					flash(words.webhookOk);
				}).catch(function () { flash(words.webhookFail, true); });
			});
		}

		var reset = document.getElementById('ccReset');
		if (reset) {
			reset.addEventListener('click', function () {
				if (!window.confirm(words.resetAsk)) { return; }

				post('c2c.reset', {}).then(function (next) {
					if (!next || !next.ok) {
						flash((next && next.error) || words.error, true);
						return;
					}
					apply(next);
					flash(words.resetOk);
				}).catch(function () { flash(words.error, true); });
			});
		}

		document.getElementById('ccSaveCards').addEventListener('click', function () {
			var cards = collectCards();

			post('c2c.cards', { cards: JSON.stringify(cards) }).then(function (next) {
				if (!next || !next.ok) {
					flash((next && next.error) || words.error, true);
					return;
				}
				apply(next);
				flash(words.saved);
			}).catch(function () { flash(words.error, true); });
		});

		document.getElementById('ccPending').addEventListener('click', function (event) {
			var approve = event.target.closest('[data-approve]');
			var reject = event.target.closest('[data-reject]');
			if (!approve && !reject) { return; }

			var card = event.target.closest('.cc-pend');
			if (!card) { return; }

			var id = card.getAttribute('data-id');
			var note = card.querySelector('[data-note]');

			(approve ? post('c2c.approve', { id: id, note: note ? note.value : '' })
				: post('c2c.reject', { id: id, note: note ? note.value : '' }))
				.then(function (next) {
					if (!next || !next.ok) {
						flash((next && next.error) || words.fail, true);
						return;
					}
					apply(next);
					flash(approve ? words.approved : words.rejected);
				}).catch(function () { flash(words.fail, true); });
		});
	});
})();
</script>
{/literal}
