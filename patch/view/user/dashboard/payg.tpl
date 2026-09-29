{*
 * The pay-as-you-go wallet card on the dashboard.
 *
 * Everything on it comes from /xmplus-patch.php?do=payg.me (app/Patch/Payg.php);
 * the card stays hidden until that answers and says the wallet is switched on.
 * A charge is bought through the panel's own checkout: payg.mint turns the
 * amount into a topup package, then /portal/order/create sells it exactly as
 * "add data" does. app/Jobs/PaygJob.php credits it once the order is paid.
 *}
<script>
	/* new Object(), not a brace literal: Smarty would read the brace as a tag */
	window.PaygWords = new Object();
	window.PaygWords.modePlan     = "{$translate->get('PaygModePlan')|escape:'javascript'}";
	window.PaygWords.modeBalance  = "{$translate->get('PaygModeBalance')|escape:'javascript'}";
	window.PaygWords.modeEmpty    = "{$translate->get('PaygModeEmpty')|escape:'javascript'}";
	window.PaygWords.headroom     = "{$translate->get('PaygHeadroom')|escape:'javascript'}";
	window.PaygWords.unlimited    = "{$translate->get('PaygUnlimited')|escape:'javascript'}";
	window.PaygWords.toman        = "{$translate->get('PaygToman')|escape:'javascript'}";
	window.PaygWords.rial         = "{$translate->get('PaygRial')|escape:'javascript'}";
	window.PaygWords.gb           = "{$translate->get('PaygGb')|escape:'javascript'}";
	window.PaygWords.mb           = "{$translate->get('PaygMb')|escape:'javascript'}";
	window.PaygWords.free         = "{$translate->get('PaygFree')|escape:'javascript'}";
	window.PaygWords.down         = "{$translate->get('PaygServerDown')|escape:'javascript'}";
	window.PaygWords.perGb        = "{$translate->get('PaygPerGb')|escape:'javascript'}";
	window.PaygWords.kindCharge   = "{$translate->get('PaygKindCharge')|escape:'javascript'}";
	window.PaygWords.kindBonus    = "{$translate->get('PaygKindBonus')|escape:'javascript'}";
	window.PaygWords.kindUsage    = "{$translate->get('PaygKindUsage')|escape:'javascript'}";
	window.PaygWords.kindAdjust   = "{$translate->get('PaygKindAdjust')|escape:'javascript'}";
	window.PaygWords.noHistory    = "{$translate->get('PaygNoHistory')|escape:'javascript'}";
	window.PaygWords.minNote      = "{$translate->get('PaygMinNote')|escape:'javascript'}";
	window.PaygWords.tooLow       = "{$translate->get('PaygTooLow')|escape:'javascript'}";
	window.PaygWords.bonusNote    = "{$translate->get('PaygBonusNote')|escape:'javascript'}";
	window.PaygWords.tierLine     = "{$translate->get('PaygTierLine')|escape:'javascript'}";
	window.PaygWords.payNow       = "{$translate->get('PaygPayNow')|escape:'javascript'}";
	window.PaygWords.autoOn       = "{$translate->get('PaygAutoOnSaved')|escape:'javascript'}";
	window.PaygWords.autoOff      = "{$translate->get('PaygAutoOffSaved')|escape:'javascript'}";
	window.PaygWords.ok           = "{$translate->get('ok')|escape:'javascript'}";
	window.PaygWords.freeNote     = "{$translate->get('PaygFreeTraffic')|escape:'javascript'}";
</script>

{literal}
<style>
.pw {
	position: relative;
	overflow: hidden;
	border-radius: 22px;
	padding: 18px;
	margin-bottom: 1.5rem;
	color: #1f2a44;
	background:
		radial-gradient(120% 90% at 100% 0%, rgba(16, 185, 129, .16), transparent 60%),
		radial-gradient(120% 90% at 0% 100%, rgba(59, 130, 246, .14), transparent 60%),
		#fff;
	box-shadow: 0 18px 40px -26px rgba(15, 23, 42, .45), inset 0 0 0 1px rgba(15, 23, 42, .06);
}
html[data-hs-theme="dark"] .pw {
	color: #e5e7eb;
	background:
		radial-gradient(120% 90% at 100% 0%, rgba(16, 185, 129, .18), transparent 60%),
		radial-gradient(120% 90% at 0% 100%, rgba(59, 130, 246, .16), transparent 60%),
		#1b2334;
	box-shadow: 0 18px 40px -26px rgba(0, 0, 0, .8), inset 0 0 0 1px rgba(255, 255, 255, .06);
}
.pw[hidden] { display: none; }
.pw-head { display: flex; align-items: center; gap: 10px; flex-wrap: wrap; }
.pw-title { font-size: 15px; font-weight: 800; margin: 0; flex: 1 1 auto; }
.pw-badge {
	font-size: 11.5px;
	font-weight: 700;
	padding: 4px 10px;
	border-radius: 999px;
	background: rgba(16, 185, 129, .14);
	color: #047857;
}
.pw-badge.is-balance { background: rgba(245, 158, 11, .16); color: #b45309; }
.pw-badge.is-empty { background: rgba(244, 63, 94, .15); color: #be123c; }
html[data-hs-theme="dark"] .pw-badge { color: #6ee7b7; }
html[data-hs-theme="dark"] .pw-badge.is-balance { color: #fcd34d; }
html[data-hs-theme="dark"] .pw-badge.is-empty { color: #fda4af; }

.pw-main { display: flex; align-items: flex-end; justify-content: space-between; gap: 14px; flex-wrap: wrap; margin-top: 14px; }
.pw-balance-label { font-size: 12px; opacity: .7; }
.pw-balance { font-size: 26px; font-weight: 900; line-height: 1.4; }
.pw-balance.is-neg { color: #e11d48; }
.pw-headroom { font-size: 12px; opacity: .8; margin-top: 2px; }
.pw-charge {
	border: 0;
	cursor: pointer;
	border-radius: 14px;
	padding: 11px 20px;
	font-weight: 800;
	font-size: 14px;
	color: #fff;
	background: linear-gradient(135deg, #10b981, #3b82f6);
	box-shadow: 0 12px 24px -12px rgba(16, 185, 129, .9);
}
.pw-charge:hover { filter: brightness(1.06); }

.pw-stats { display: grid; grid-template-columns: repeat(auto-fit, minmax(140px, 1fr)); gap: 10px; margin-top: 14px; }
.pw-stat { border-radius: 14px; padding: 10px 12px; background: rgba(15, 23, 42, .04); }
html[data-hs-theme="dark"] .pw-stat { background: rgba(255, 255, 255, .05); }
.pw-stat-label { font-size: 11.5px; opacity: .7; }
.pw-stat-value { font-size: 14px; font-weight: 800; margin-top: 2px; }
.pw-stat-note { font-size: 11px; opacity: .7; }

.pw-auto { display: flex; gap: 10px; align-items: flex-start; margin-top: 14px; cursor: pointer; }
.pw-auto input { margin-top: 5px; width: 18px; height: 18px; accent-color: #10b981; flex: 0 0 auto; }
.pw-auto-title { font-size: 13px; font-weight: 700; }
.pw-auto-hint { font-size: 11.5px; opacity: .75; line-height: 1.9; }

.pw-notices { margin-top: 12px; display: grid; gap: 8px; }
.pw-notice {
	white-space: pre-line;
	font-size: 12.5px;
	line-height: 1.9;
	padding: 10px 12px;
	border-radius: 12px;
	background: rgba(59, 130, 246, .1);
	border-inline-start: 3px solid #3b82f6;
}
.pw-notice.is-empty, .pw-notice.is-low { background: rgba(244, 63, 94, .1); border-color: #f43f5e; }
.pw-notice.is-started, .pw-notice.is-warn { background: rgba(245, 158, 11, .12); border-color: #f59e0b; }
.pw-notice.is-charge, .pw-notice.is-resumed { background: rgba(16, 185, 129, .12); border-color: #10b981; }

.pw-commission {
	display: flex; gap: 8px; align-items: center; flex-wrap: wrap;
	margin-top: 12px; padding: 10px 12px; border-radius: 14px;
	background: rgba(139, 92, 246, .1); font-size: 12.5px;
}
.pw-commission b { font-weight: 800; }
.pw-commission span.pw-muted { opacity: .75; font-size: 11.5px; }

.pw-more { margin-top: 12px; }
.pw-more summary { cursor: pointer; font-size: 13px; font-weight: 700; padding: 6px 0; }
.pw-table { width: 100%; font-size: 12.5px; border-collapse: collapse; margin-top: 6px; }
.pw-table td, .pw-table th { padding: 7px 6px; border-bottom: 1px solid rgba(15, 23, 42, .07); text-align: start; }
html[data-hs-theme="dark"] .pw-table td, html[data-hs-theme="dark"] .pw-table th { border-color: rgba(255, 255, 255, .07); }
.pw-table th { font-weight: 700; opacity: .7; font-size: 11.5px; }
.pw-plus { color: #059669; font-weight: 800; }
.pw-minus { color: #e11d48; font-weight: 800; }
.pw-down { color: #b45309; font-size: 11px; }
.pw-foot { font-size: 11px; opacity: .7; margin-top: 6px; }

.pw-overlay {
	position: fixed; inset: 0; z-index: 1080;
	display: flex; align-items: center; justify-content: center;
	padding: 16px; background: rgba(15, 23, 42, .55);
	backdrop-filter: blur(4px);
}
.pw-overlay[hidden] { display: none; }
.pw-modal {
	width: 100%; max-width: 420px; border-radius: 22px; padding: 20px;
	background: #fff; color: #1f2a44;
	box-shadow: 0 30px 60px -20px rgba(0, 0, 0, .5);
}
html[data-hs-theme="dark"] .pw-modal { background: #1b2334; color: #e5e7eb; }
.pw-modal-head { display: flex; align-items: center; justify-content: space-between; gap: 8px; }
.pw-modal-title { font-size: 16px; font-weight: 800; margin: 0; }
.pw-x { border: 0; background: transparent; font-size: 20px; cursor: pointer; color: inherit; opacity: .6; }
.pw-field { margin-top: 14px; position: relative; }
.pw-field input {
	width: 100%; font-size: 20px; font-weight: 800; text-align: center; direction: ltr;
	border-radius: 14px; padding: 12px 70px 12px 12px;
	border: 2px solid rgba(16, 185, 129, .35); background: transparent; color: inherit;
}
.pw-field input:focus { outline: none; border-color: #10b981; }
.pw-field-unit { position: absolute; inset-block-start: 50%; right: 14px; transform: translateY(-50%); font-size: 12px; opacity: .7; }
.pw-chips { display: flex; flex-wrap: wrap; gap: 8px; margin-top: 12px; }
.pw-chip {
	border: 0; cursor: pointer; border-radius: 999px; padding: 7px 12px; font-size: 12.5px; font-weight: 700;
	background: rgba(59, 130, 246, .1); color: inherit;
}
.pw-chip:hover { background: rgba(59, 130, 246, .2); }
.pw-modal-note { font-size: 12px; opacity: .8; margin-top: 10px; line-height: 1.9; }
.pw-bonus { font-size: 13px; font-weight: 800; color: #059669; margin-top: 8px; min-height: 20px; }
.pw-tiers { font-size: 11.5px; opacity: .8; margin-top: 6px; line-height: 1.9; }
.pw-pay { width: 100%; margin-top: 14px; }
@media (max-width: 575.98px) {
	.pw-balance { font-size: 22px; }
	.pw-charge { width: 100%; }
}
</style>
{/literal}

<div class="col-12">
	<div class="pw" id="paygCard" hidden>
		<div class="pw-head">
			<h3 class="pw-title">💰 {$translate->get('PaygTitle')}</h3>
			<span class="pw-badge" id="paygMode"></span>
		</div>

		<div class="pw-main">
			<div>
				<div class="pw-balance-label">{$translate->get('PaygBalance')}</div>
				<div class="pw-balance" id="paygBalance">—</div>
				<div class="pw-headroom" id="paygHeadroom"></div>
			</div>
			<button type="button" class="pw-charge" id="paygOpen">➕ {$translate->get('PaygCharge')}</button>
		</div>

		<div class="pw-notices" id="paygNotices"></div>

		<div class="pw-stats">
			<div class="pw-stat">
				<div class="pw-stat-label">{$translate->get('PaygToday')}</div>
				<div class="pw-stat-value" id="paygToday">—</div>
				<div class="pw-stat-note" id="paygTodayBytes"></div>
			</div>
			<div class="pw-stat">
				<div class="pw-stat-label">{$translate->get('PaygMonth')}</div>
				<div class="pw-stat-value" id="paygMonth">—</div>
			</div>
			<div class="pw-stat">
				<div class="pw-stat-label">{$translate->get('PaygTotalCharged')}</div>
				<div class="pw-stat-value" id="paygCharged">—</div>
				<div class="pw-stat-note" id="paygBonus"></div>
			</div>
		</div>

		<label class="pw-auto">
			<input type="checkbox" id="paygAuto">
			<span>
				<span class="pw-auto-title">{$translate->get('PaygAuto')}</span><br>
				<span class="pw-auto-hint">{$translate->get('PaygAutoHint')}</span>
			</span>
		</label>

		<div class="pw-commission" id="paygCommission" hidden>
			🤝 {$translate->get('PaygCommission')}: <b id="paygCommissionBalance"></b>
			<span class="pw-muted">— {$translate->get('PaygCommissionNote')}</span>
		</div>

		<details class="pw-more">
			<summary>🏷 {$translate->get('PaygRates')}</summary>
			<table class="pw-table"><tbody id="paygRates"></tbody></table>
			<div class="pw-foot" id="paygOutage">{$translate->get('PaygOutageNote')}</div>
		</details>

		<details class="pw-more">
			<summary>🧾 {$translate->get('PaygHistory')}</summary>
			<table class="pw-table"><tbody id="paygHistory"></tbody></table>
		</details>

		<div class="pw-foot">🔄 {$translate->get('PaygLiveHint')}</div>
	</div>
</div>

<div class="pw-overlay" id="paygOverlay" hidden>
	<div class="pw-modal" role="dialog" aria-modal="true" aria-labelledby="paygModalTitle">
		<div class="pw-modal-head">
			<h4 class="pw-modal-title" id="paygModalTitle">💳 {$translate->get('PaygCharge')}</h4>
			<button type="button" class="pw-x" id="paygClose" aria-label="close">✕</button>
		</div>
		<div class="pw-field">
			<input type="text" inputmode="numeric" id="paygAmount" autocomplete="off">
			<span class="pw-field-unit" id="paygUnit"></span>
		</div>
		<div class="pw-chips" id="paygChips"></div>
		<div class="pw-bonus" id="paygBonusPreview"></div>
		<div class="pw-modal-note" id="paygMin"></div>
		<div class="pw-tiers" id="paygTiers"></div>
		<button type="button" class="pw-charge pw-pay" id="paygPay">{$translate->get('PaygPayNow')}</button>
	</div>
</div>

{literal}
<script>
(function () {
	var endpoint = '/xmplus-patch.php';
	var W = window.PaygWords;
	var state = null;
	var card = document.getElementById('paygCard');
	var rtl = (document.documentElement.getAttribute('dir') || '').toLowerCase() === 'rtl';
	var numLocale = rtl ? 'fa-IR' : 'en-US';

	function $id(id) { return document.getElementById(id); }

	function say(text) {
		if (window.layer && layer.msg) {
			layer.msg(text, { time: 5000, offset: '100px' });
		} else {
			alert(text);
		}
	}

	function esc(text) {
		return String(text == null ? '' : text).replace(/[&<>"']/g, function (c) {
			return ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[c];
		});
	}

	function num(n) {
		return Math.round(n).toLocaleString(numLocale);
	}

	/* amounts arrive in rial; shown in toman when the admin asked for it */
	function money(rial) {
		rial = Number(rial) || 0;
		return state && state.toman ? num(rial / 10) + ' ' + W.toman : num(rial) + ' ' + W.rial;
	}

	function unitToRial(value) {
		return state && state.toman ? value * 10 : value;
	}

	function rialToUnit(value) {
		return state && state.toman ? value / 10 : value;
	}

	function volume(bytes) {
		var gb = (Number(bytes) || 0) / 1073741824;
		if (gb < 1) {
			return num(gb * 1024) + ' ' + W.mb;
		}
		return gb.toLocaleString(numLocale, { maximumFractionDigits: 1 }) + ' ' + W.gb;
	}

	function date(stamp) {
		try {
			return new Date(stamp * 1000).toLocaleDateString(rtl ? 'fa-IR' : 'en-US',
				{ month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' });
		} catch (e) {
			return '';
		}
	}

	function post(action, fields) {
		var body = new FormData();
		body.append('token', state ? state.token : '');
		Object.keys(fields || {}).forEach(function (k) { body.append(k, fields[k]); });
		return fetch(endpoint + '?do=' + action, { method: 'POST', credentials: 'same-origin', body: body })
			.then(function (r) { return r.json(); });
	}

	function render() {
		var w = state.wallet;
		var show = state.enabled || w.balance !== 0 || state.commission.balance > 0;

		card.hidden = !show;
		if (!show) {
			return;
		}

		var mode = $id('paygMode');
		mode.className = 'pw-badge' + (w.mode === 'balance' ? ' is-balance' : (w.mode === 'empty' ? ' is-empty' : ''));
		mode.textContent = w.mode === 'balance' ? W.modeBalance : (w.mode === 'empty' ? W.modeEmpty : W.modePlan);

		var bal = $id('paygBalance');
		bal.textContent = money(w.balance);
		bal.className = 'pw-balance' + (w.balance < 0 ? ' is-neg' : '');

		$id('paygHeadroom').textContent = state.headroom === null
			? W.unlimited
			: W.headroom.replace('%gb%', volume(state.headroom));

		$id('paygToday').textContent = money(state.today);
		$id('paygTodayBytes').textContent = state.today_bytes > 0 ? volume(state.today_bytes) : '';
		$id('paygMonth').textContent = money(state.month);
		$id('paygCharged').textContent = money(w.charged);
		$id('paygBonus').textContent = w.bonus > 0 ? '🎁 ' + money(w.bonus) : '';

		$id('paygAuto').checked = !!w.auto;
		$id('paygOpen').hidden = !state.enabled;

		if (state.commission.enabled) {
			$id('paygCommission').hidden = false;
			$id('paygCommissionBalance').textContent = money(state.commission.balance);
		}

		$id('paygNotices').innerHTML = (state.notices || []).map(function (n) {
			return '<div class="pw-notice is-' + esc(n.kind) + '">' + esc(n.text) + '</div>';
		}).join('');

		$id('paygRates').innerHTML = (state.rates || []).map(function (r) {
			var price = r.price > 0 ? money(r.price) + ' ' + W.perGb : W.free;
			var down = r.down && state.outage_free ? ' <span class="pw-down">· ' + esc(W.down) + '</span>' : '';
			return '<tr><td>' + esc(r.name) + down + '</td><td>' + esc(price) + '</td></tr>';
		}).join('');
		$id('paygOutage').hidden = !state.outage_free;

		var kinds = { charge: W.kindCharge, bonus: W.kindBonus, usage: W.kindUsage, adjust: W.kindAdjust };
		var rows = (state.history || []).map(function (h) {
			var amount = Number(h.amount) || 0;
			var label = kinds[h.kind] || h.kind;
			var detail = '';

			if (h.kind === 'usage') {
				label += h.server ? ' · ' + h.server : '';
				detail = volume(Number(h.bytes) + Number(h.free_bytes));
				if (Number(h.free_bytes) > 0 && Number(h.bytes) === 0) {
					detail += ' · ' + W.freeNote;
				}
			}

			return '<tr><td>' + esc(date(h.updated)) + '</td><td>' + esc(label)
				+ (detail ? '<br><small>' + esc(detail) + '</small>' : '') + '</td>'
				+ '<td class="' + (amount >= 0 ? 'pw-plus' : 'pw-minus') + '">'
				+ (amount >= 0 ? '+' : '−') + esc(money(Math.abs(amount))) + '</td></tr>';
		});
		$id('paygHistory').innerHTML = rows.length ? rows.join('') : '<tr><td>' + esc(W.noHistory) + '</td></tr>';
	}

	function load() {
		fetch(endpoint + '?do=payg.me', { credentials: 'same-origin' })
			.then(function (r) { return r.json(); })
			.then(function (data) {
				if (!data || !data.ok) {
					return;
				}
				state = data;
				render();
			})
			.catch(function () {});
	}

	// ---- charge dialog

	function bonusPercent(rial) {
		var best = 0;
		(state.tiers || []).forEach(function (t) {
			if (rial >= t.min) {
				best = t.percent;
			}
		});
		return best;
	}

	function roundUp(rial) {
		var step = Math.max(1, Number(state.step) || 1);
		return Math.ceil(rial / step) * step;
	}

	function amountRial() {
		var raw = $id('paygAmount').value
			.replace(/[۰-۹]/g, function (d) { return '۰۱۲۳۴۵۶۷۸۹'.indexOf(d); })
			.replace(/[^0-9.]/g, '');
		return unitToRial(Number(raw) || 0);
	}

	function preview() {
		var rial = amountRial();
		var p = bonusPercent(rial);
		$id('paygBonusPreview').textContent = p > 0
			? W.bonusNote.replace('%p%', num(p)).replace('%amount%', money(Math.round(rial * p / 100)))
			: '';
	}

	function openDialog() {
		var min = Number(state.min) || 0;
		$id('paygUnit').textContent = state.toman ? W.toman : W.rial;
		$id('paygAmount').value = num(rialToUnit(min));
		$id('paygMin').textContent = W.minNote.replace('%min%', money(min));

		var chips = [min, min * 2.5, min * 5, min * 10].map(roundUp);
		$id('paygChips').innerHTML = chips.map(function (c) {
			return '<button type="button" class="pw-chip" data-rial="' + c + '">' + esc(money(c)) + '</button>';
		}).join('');

		$id('paygTiers').innerHTML = (state.tiers || []).map(function (t) {
			return '🎁 ' + esc(W.tierLine.replace('%min%', money(t.min)).replace('%p%', num(t.percent)));
		}).join('<br>');

		preview();
		$id('paygOverlay').hidden = false;
		$id('paygAmount').focus();
	}

	function closeDialog() {
		$id('paygOverlay').hidden = true;
	}

	/* the same checkout the data top-up uses - only the package id differs */
	function createOrder(packageid) {
		$.ajax({
			type: 'POST',
			url: '/portal/order/create',
			dataType: 'json',
			data: { packageid: packageid, plan: 'topup', code: '', renew: 0, upgrade: 0, disableactive: 1 },
			success: function (data) {
				if (window.layer) { layer.closeAll('loading'); }
				if (data.ret == 1 || (data.ret == -1 && data.url)) {
					window.location.href = data.url;
					return;
				}
				say(data.msg || 'error');
			},
			error: function (jqXHR) {
				if (window.layer) { layer.closeAll('loading'); }
				say(jqXHR.responseText);
			}
		});
	}

	function pay() {
		var rial = amountRial();

		if (rial < Number(state.min)) {
			say(W.tooLow.replace('%min%', money(state.min)));
			return;
		}

		$id('paygPay').disabled = true;
		if (window.layer) { layer.load(2); }

		post('payg.mint', { amount: roundUp(rial) }).then(function (data) {
			$id('paygPay').disabled = false;
			if (!data.ok) {
				if (window.layer) { layer.closeAll('loading'); }
				say(data.error);
				return;
			}
			createOrder(data.packageid);
		}).catch(function () {
			$id('paygPay').disabled = false;
			if (window.layer) { layer.closeAll('loading'); }
		});
	}

	$id('paygOpen').addEventListener('click', openDialog);
	$id('paygClose').addEventListener('click', closeDialog);
	$id('paygOverlay').addEventListener('click', function (e) {
		if (e.target === this) { closeDialog(); }
	});
	document.addEventListener('keydown', function (e) {
		if (e.key === 'Escape') { closeDialog(); }
	});
	$id('paygAmount').addEventListener('input', preview);
	$id('paygChips').addEventListener('click', function (e) {
		var chip = e.target.closest('.pw-chip');
		if (chip) {
			$id('paygAmount').value = num(rialToUnit(Number(chip.getAttribute('data-rial'))));
			preview();
		}
	});
	$id('paygPay').addEventListener('click', pay);

	$id('paygAuto').addEventListener('change', function () {
		var on = this.checked ? 1 : 0;
		post('payg.auto', { on: on }).then(function (data) {
			if (data.ok) {
				state.wallet.auto = data.auto;
				say(data.auto ? W.autoOn : W.autoOff);
			} else {
				say(data.error);
			}
		});
	});

	load();
})();
</script>
{/literal}
