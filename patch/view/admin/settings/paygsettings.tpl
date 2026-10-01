{*
  Pay-as-you-go wallet and commission wallet - admin side.
  Included by settings.tpl; everything is read from and written to
  /xmplus-patch.php?do=payg.* / commission.* (app/Patch/Payg.php).
  Amounts are stored in rial; the form shows and takes them in toman while
  "show amounts in toman" is on (the JS multiplies/divides by 10).
*}
<div class="card card-shadow shadow-lg rounded mb-3 mb-lg-5" id="PaygSettings">
	<div class="card-header">
		<h4 class="card-header-title">💰 {$translate->get('PaygAdmTitle')}</h4>
	</div>
	<div class="card-body pa">
		<p class="text-muted small">{$translate->get('PaygAdmIntro')}</p>

		{* ---------------------------------------------------------- report *}
		<h5 class="pa-h">📊 {$translate->get('PaygAdmReport')}</h5>
		<div class="pa-kpis" id="paKpis"></div>
		<div class="pa-foot" id="paLastRun"></div>

		<details class="pa-more">
			<summary>🖥 {$translate->get('PaygAdmPerServer')}</summary>
			<div class="table-responsive">
				<table class="table table-sm pa-table">
					<thead><tr>
						<th>{$translate->get('PaygAdmServer')}</th>
						<th>{$translate->get('PaygAdmRevenue')} <span class="pa-unit"></span></th>
						<th>{$translate->get('PaygAdmBilledVolume')}</th>
						<th>{$translate->get('PaygAdmFreeVolume')}</th>
					</tr></thead>
					<tbody id="paPerServer"></tbody>
				</table>
			</div>
		</details>

		{* -------------------------------------------------------- settings *}
		<h5 class="pa-h">⚙️ {$translate->get('PaygAdmSettings')}</h5>
		<div class="pa-grid">
			<label class="pa-check"><input type="checkbox" id="pa_payg_enabled"> {$translate->get('PaygAdmEnabled')}</label>
			<label class="pa-check"><input type="checkbox" id="pa_payg_outage_free"> {$translate->get('PaygAdmOutage')}</label>
			<label class="pa-check"><input type="checkbox" id="pa_payg_show_toman"> {$translate->get('PaygAdmToman')}</label>
			<label class="pa-check"><input type="checkbox" id="pa_commission_wallet_enabled"> {$translate->get('PaygAdmCommissionEnabled')}</label>
		</div>
		<div class="row g-3 mt-1">
			<div class="col-md-6">
				<label class="form-label" for="pa_payg_min_charge">{$translate->get('PaygAdmMin')} <span class="pa-unit"></span></label>
				<input type="text" class="form-control" id="pa_payg_min_charge" dir="ltr">
				<small class="text-muted">{$translate->get('PaygAdmMinHint')}</small>
			</div>
			<div class="col-md-6">
				<label class="form-label" for="pa_payg_charge_step">{$translate->get('PaygAdmStep')} <span class="pa-unit"></span></label>
				<input type="text" class="form-control" id="pa_payg_charge_step" dir="ltr">
			</div>
			<div class="col-md-6">
				<label class="form-label" for="pa_payg_default_price">{$translate->get('PaygAdmDefault')} <span class="pa-unit"></span></label>
				<input type="text" class="form-control" id="pa_payg_default_price" dir="ltr">
			</div>
			<div class="col-md-6">
				<label class="form-label" for="pa_payg_low_balance">{$translate->get('PaygAdmLow')} <span class="pa-unit"></span></label>
				<input type="text" class="form-control" id="pa_payg_low_balance" dir="ltr">
			</div>
			<div class="col-md-6">
				<label class="form-label" for="pa_payg_warn_percent">{$translate->get('PaygAdmWarnPct')}</label>
				<input type="text" class="form-control" id="pa_payg_warn_percent" dir="ltr">
			</div>
			<div class="col-md-6">
				<label class="form-label" for="pa_payg_warn_days">{$translate->get('PaygAdmWarnDays')}</label>
				<input type="text" class="form-control" id="pa_payg_warn_days" dir="ltr">
			</div>
			<div class="col-md-6">
				<label class="form-label" for="pa_payg_group">{$translate->get('PaygAdmGroup')}</label>
				<input type="text" class="form-control" id="pa_payg_group" dir="ltr">
			</div>
			<div class="col-md-6">
				<label class="form-label" for="pa_payg_bonus_tiers">{$translate->get('PaygAdmTiers')}</label>
				<textarea class="form-control" id="pa_payg_bonus_tiers" rows="3" dir="ltr" placeholder="1000000:5&#10;2000000:10"></textarea>
				<small class="text-muted">{$translate->get('PaygAdmTiersHint')}</small>
			</div>
		</div>
		<div class="d-flex justify-content-end align-items-center gap-3 mt-3">
			<span class="pa-status" id="paStatus" role="status"></span>
			<button type="button" class="btn btn-primary" id="paSave">💾 {$translate->get('Save')}</button>
		</div>

		{* ------------------------------------------------------ client apps *}
		<h5 class="pa-h">📱 {$translate->get('SubInfoTitle')}</h5>
		<p class="text-muted small">{$translate->get('SubInfoIntro')}</p>
		<label class="pa-check"><input type="checkbox" id="pa_sub_info_enabled"> {$translate->get('SubInfoEnabled')}</label>
		<div class="row g-3 mt-1">
			<div class="col-md-6">
				<label class="form-label" for="pa_sub_origin">{$translate->get('SubInfoOrigin')}</label>
				<input type="text" class="form-control" id="pa_sub_origin" dir="ltr" placeholder="https://origin.example.com">
			</div>
			<div class="col-md-6">
				<label class="form-label" for="pa_sub_origin_ip">{$translate->get('SubInfoOriginIp')}</label>
				<input type="text" class="form-control" id="pa_sub_origin_ip" dir="ltr" placeholder="127.0.0.1">
			</div>
		</div>
		<small class="text-muted d-block">{$translate->get('SubInfoHint')}</small>
		<code class="d-block mt-1" dir="ltr" id="paSubExample"></code>
		<div class="d-flex justify-content-end mt-3">
			<button type="button" class="btn btn-primary pa-save-all">💾 {$translate->get('Save')}</button>
		</div>

		{* ----------------------------------------------------------- rates *}
		<h5 class="pa-h">🏷 {$translate->get('PaygAdmRates')}</h5>
		<p class="text-muted small">{$translate->get('PaygAdmRatesHint')}</p>
		<div class="table-responsive">
			<table class="table table-sm pa-table">
				<thead><tr>
					<th>{$translate->get('PaygAdmServer')}</th>
					<th>{$translate->get('PaygAdmState')}</th>
					<th>{$translate->get('PaygAdmPrice')} <span class="pa-unit"></span></th>
				</tr></thead>
				<tbody id="paRates"></tbody>
			</table>
		</div>
		<div class="d-flex justify-content-end">
			<button type="button" class="btn btn-primary" id="paSaveRates">💾 {$translate->get('PaygAdmSaveRates')}</button>
		</div>

		{* ----------------------------------------------------------- users *}
		<h5 class="pa-h">👥 {$translate->get('PaygAdmUsers')}</h5>
		<div class="d-flex flex-wrap gap-2 mb-2">
			<input type="text" class="form-control pa-search" id="paQuery" placeholder="{$translate->get('PaygAdmSearch')}">
			<select class="form-select pa-select" id="paMode">
				<option value="">{$translate->get('PaygAdmAllModes')}</option>
				<option value="plan">{$translate->get('PaygModePlan')}</option>
				<option value="balance">{$translate->get('PaygModeBalance')}</option>
				<option value="empty">{$translate->get('PaygModeEmpty')}</option>
			</select>
			<button type="button" class="btn btn-outline-primary" id="paFind">🔎</button>
		</div>
		<div class="table-responsive">
			<table class="table table-sm table-hover pa-table">
				<thead><tr>
					<th>{$translate->get('PaygAdmUser')}</th>
					<th>{$translate->get('PaygAdmCharged')}</th>
					<th>{$translate->get('PaygAdmBonusCol')}</th>
					<th>{$translate->get('PaygAdmSpent')}</th>
					<th>{$translate->get('PaygAdmUnspent')}</th>
					<th>{$translate->get('PaygAdmMode')}</th>
					<th>{$translate->get('PaygAdmLastUse')}</th>
				</tr></thead>
				<tbody id="paUsers"></tbody>
			</table>
		</div>
		<div class="d-flex justify-content-between align-items-center">
			<small class="text-muted" id="paUsersCount"></small>
			<div class="d-flex gap-2">
				<button type="button" class="btn btn-sm btn-outline-secondary" id="paPrev">›</button>
				<button type="button" class="btn btn-sm btn-outline-secondary" id="paNext">‹</button>
			</div>
		</div>
		<div class="pa-ledger" id="paLedger" hidden></div>

		{* ---------------------------------------------------------- adjust *}
		<h5 class="pa-h">✍️ {$translate->get('PaygAdmAdjust')}</h5>
		<div class="row g-3">
			<div class="col-md-4">
				<label class="form-label" for="paAdjUser">{$translate->get('PaygAdmAdjustUser')}</label>
				<input type="text" class="form-control" id="paAdjUser">
			</div>
			<div class="col-md-4">
				<label class="form-label" for="paAdjAmount">{$translate->get('PaygAdmAdjustAmount')} <span class="pa-unit"></span></label>
				<input type="text" class="form-control" id="paAdjAmount" dir="ltr" placeholder="50000 / -50000">
			</div>
			<div class="col-md-4">
				<label class="form-label" for="paAdjWallet">{$translate->get('PaygAdmAdjustWallet')}</label>
				<select class="form-select" id="paAdjWallet">
					<option value="payg">{$translate->get('PaygTitle')}</option>
					<option value="commission">{$translate->get('PaygCommission')}</option>
				</select>
			</div>
			<div class="col-12">
				<label class="form-label" for="paAdjReason">{$translate->get('PaygAdmAdjustReason')}</label>
				<input type="text" class="form-control" id="paAdjReason">
			</div>
		</div>
		<div class="d-flex justify-content-end mt-3">
			<button type="button" class="btn btn-warning" id="paAdjust">✍️ {$translate->get('PaygAdmAdjustDo')}</button>
		</div>

		{* ------------------------------------------------------ commission *}
		<h5 class="pa-h">🤝 {$translate->get('PaygCommission')}</h5>
		<p class="text-muted small">{$translate->get('PaygAdmCommissionIntro')}</p>
		<div class="pa-kpis" id="paCommission"></div>
		<div class="d-flex flex-wrap gap-2 align-items-center justify-content-end mt-2">
			<small class="text-muted" id="paMigrated"></small>
			<button type="button" class="btn btn-outline-danger" id="paMigrate">↪️ {$translate->get('PaygAdmMigrate')}</button>
		</div>
	</div>
</div>

<script>
	window.PaygAdmWords = new Object();
	window.PaygAdmWords.charged   = "{$translate->get('PaygAdmCharged')|escape:'javascript'}";
	window.PaygAdmWords.bonus     = "{$translate->get('PaygAdmBonusCol')|escape:'javascript'}";
	window.PaygAdmWords.spent     = "{$translate->get('PaygAdmSpent')|escape:'javascript'}";
	window.PaygAdmWords.unspent   = "{$translate->get('PaygAdmUnspent')|escape:'javascript'}";
	window.PaygAdmWords.owed      = "{$translate->get('PaygAdmOwed')|escape:'javascript'}";
	window.PaygAdmWords.today     = "{$translate->get('PaygAdmUsageToday')|escape:'javascript'}";
	window.PaygAdmWords.month     = "{$translate->get('PaygAdmUsageMonth')|escape:'javascript'}";
	window.PaygAdmWords.wallets   = "{$translate->get('PaygAdmWallets')|escape:'javascript'}";
	window.PaygAdmWords.onBalance = "{$translate->get('PaygModeBalance')|escape:'javascript'}";
	window.PaygAdmWords.empty     = "{$translate->get('PaygModeEmpty')|escape:'javascript'}";
	window.PaygAdmWords.plan      = "{$translate->get('PaygModePlan')|escape:'javascript'}";
	window.PaygAdmWords.cBalance  = "{$translate->get('PaygAdmCommissionBalance')|escape:'javascript'}";
	window.PaygAdmWords.cEarned   = "{$translate->get('PaygAdmCommissionEarned')|escape:'javascript'}";
	window.PaygAdmWords.cSpent    = "{$translate->get('PaygAdmCommissionSpent')|escape:'javascript'}";
	window.PaygAdmWords.money     = "{$translate->get('PaygAdmMoneyTotal')|escape:'javascript'}";
	window.PaygAdmWords.migrateQ  = "{$translate->get('PaygAdmMigrateConfirm')|escape:'javascript'}";
	window.PaygAdmWords.migrated  = "{$translate->get('PaygAdmMigrated')|escape:'javascript'}";
	window.PaygAdmWords.migrateOk = "{$translate->get('PaygAdmMigrateDone')|escape:'javascript'}";
	window.PaygAdmWords.saved     = "{$translate->get('PaygAdmSaved')|escape:'javascript'}";
	window.PaygAdmWords.lastRun   = "{$translate->get('PaygAdmLastRun')|escape:'javascript'}";
	window.PaygAdmWords.never     = "{$translate->get('PaygAdmNever')|escape:'javascript'}";
	window.PaygAdmWords.up        = "{$translate->get('PaygAdmUp')|escape:'javascript'}";
	window.PaygAdmWords.down      = "{$translate->get('PaygAdmDown')|escape:'javascript'}";
	window.PaygAdmWords.off       = "{$translate->get('PaygAdmOff')|escape:'javascript'}";
	window.PaygAdmWords.defaultP  = "{$translate->get('PaygAdmDefaultPrice')|escape:'javascript'}";
	window.PaygAdmWords.count     = "{$translate->get('PaygAdmCount')|escape:'javascript'}";
	window.PaygAdmWords.nothing   = "{$translate->get('PaygNoHistory')|escape:'javascript'}";
	window.PaygAdmWords.adjusted  = "{$translate->get('PaygAdmAdjusted')|escape:'javascript'}";
	window.PaygAdmWords.kCharge   = "{$translate->get('PaygKindCharge')|escape:'javascript'}";
	window.PaygAdmWords.kBonus    = "{$translate->get('PaygKindBonus')|escape:'javascript'}";
	window.PaygAdmWords.kUsage    = "{$translate->get('PaygKindUsage')|escape:'javascript'}";
	window.PaygAdmWords.kAdjust   = "{$translate->get('PaygKindAdjust')|escape:'javascript'}";
	window.PaygAdmWords.close     = "{$translate->get('Close')|escape:'javascript'}";
	window.PaygAdmWords.toman     = "{$translate->get('PaygToman')|escape:'javascript'}";
	window.PaygAdmWords.rial      = "{$translate->get('PaygRial')|escape:'javascript'}";
	window.PaygAdmWords.savedMin  = "{$translate->get('PaygAdmSavedMin')|escape:'javascript'}";
	window.PaygAdmWords.noMin     = "{$translate->get('PaygAdmNoMin')|escape:'javascript'}";
	window.PaygAdmWords.failed    = "{$translate->get('PaygAdmSaveFailed')|escape:'javascript'}";
</script>
{literal}
<style>
.pa-h { font-size: 15px; font-weight: 800; margin: 26px 0 10px; }
.pa-h:first-of-type { margin-top: 6px; }
.pa-kpis { display: grid; grid-template-columns: repeat(auto-fit, minmax(160px, 1fr)); gap: 10px; }
.pa-kpi { border-radius: 14px; padding: 12px; background: rgba(55, 125, 255, .07); }
.pa-kpi.is-green { background: rgba(16, 185, 129, .1); }
.pa-kpi.is-amber { background: rgba(245, 158, 11, .12); }
.pa-kpi.is-red { background: rgba(244, 63, 94, .1); }
.pa-kpi.is-violet { background: rgba(139, 92, 246, .1); }
.pa-kpi-label { font-size: 12px; opacity: .75; }
.pa-kpi-value { font-size: 16px; font-weight: 800; margin-top: 2px; }
.pa-foot { font-size: 11.5px; opacity: .7; margin-top: 6px; }
.pa-grid { display: flex; flex-wrap: wrap; gap: 10px 22px; }
.pa-check { display: inline-flex; gap: 8px; align-items: center; font-weight: 600; cursor: pointer; }
.pa-check input { width: 18px; height: 18px; }
.pa-table td, .pa-table th { vertical-align: middle; white-space: nowrap; }
.pa-table input { max-width: 180px; }
.pa-search { max-width: 260px; }
.pa-select { max-width: 200px; }
.pa-more summary { cursor: pointer; font-weight: 700; margin-top: 10px; }
.pa-user { cursor: pointer; }
.pa-neg { color: #e11d48; font-weight: 700; }
.pa-ledger { margin-top: 10px; padding: 12px; border-radius: 14px; background: rgba(55, 125, 255, .05); }
.pa-unit { font-weight: 400; opacity: .75; }
.pa-status { font-size: 12.5px; font-weight: 700; }
.pa-status.is-ok { color: #059669; }
.pa-status.is-bad { color: #e11d48; }
</style>
<script>
(function () {
	var endpoint = '/xmplus-patch.php';
	var W = window.PaygAdmWords;
	var token = '';
	var page = 1;
	var fields = ['payg_enabled', 'payg_outage_free', 'payg_show_toman', 'commission_wallet_enabled',
		'payg_min_charge', 'payg_charge_step', 'payg_default_price', 'payg_low_balance',
		'payg_warn_percent', 'payg_warn_days', 'payg_group', 'sub_info_enabled', 'sub_origin', 'sub_origin_ip'];
	var checks = ['payg_enabled', 'payg_outage_free', 'payg_show_toman', 'commission_wallet_enabled', 'sub_info_enabled'];
	var moneyFields = ['payg_min_charge', 'payg_charge_step', 'payg_default_price', 'payg_low_balance'];

	/* rial in the database; toman on screen while "show in toman" is on */
	var factor = 10;

	function $id(id) { return document.getElementById(id); }

	function say(text) {
		if (window.layer && layer.msg) {
			layer.msg(text, { time: 6000, offset: '100px' });
		} else {
			alert(text);
		}
	}

	function status(text, ok) {
		var el = $id('paStatus');
		el.textContent = text;
		el.className = 'pa-status ' + (ok ? 'is-ok' : 'is-bad');
	}

	function esc(text) {
		return String(text == null ? '' : text).replace(/[&<>"']/g, function (c) {
			return ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[c];
		});
	}

	function num(n) {
		return Math.round(Number(n) || 0).toLocaleString('en-US');
	}

	/* a stored rial amount, as the form shows it */
	function shown(rial) {
		var v = (Number(rial) || 0) / factor;
		return Math.round(v * 100) / 100;
	}

	function money(rial) {
		return num(shown(rial)) + ' ' + (factor === 10 ? W.toman : W.rial);
	}

	/* what the admin typed (Persian digits and separators too), back in rial */
	function toRial(text) {
		var clean = String(text == null ? '' : text)
			.replace(/[۰-۹]/g, function (d) { return '۰۱۲۳۴۵۶۷۸۹'.indexOf(d); })
			.replace(/[٠-٩]/g, function (d) { return '٠١٢٣٤٥٦٧٨٩'.indexOf(d); })
			.replace(/[−–]/g, '-')
			.replace(/[^0-9.\-]/g, '');
		if (clean === '' || clean === '-') {
			return '';
		}
		return String(Math.round(Number(clean) * factor * 100) / 100);
	}

	function vol(bytes) {
		var gb = (Number(bytes) || 0) / 1073741824;
		return gb.toLocaleString('en-US', { maximumFractionDigits: 2 }) + ' GB';
	}

	function when(stamp) {
		stamp = Number(stamp) || 0;
		return stamp > 0 ? new Date(stamp * 1000).toLocaleString('fa-IR') : '—';
	}

	function kpi(label, value, tone) {
		return '<div class="pa-kpi ' + (tone || '') + '"><div class="pa-kpi-label">' + esc(label)
			+ '</div><div class="pa-kpi-value">' + esc(value) + '</div></div>';
	}

	/* the CDN in front of the panel must never answer from a cache */
	function get(action, query) {
		return fetch(endpoint + '?do=' + action + (query || '') + '&_=' + Date.now(),
			{ credentials: 'same-origin', cache: 'no-store' })
			.then(function (r) { return r.json(); });
	}

	function post(action, body, retried) {
		body.set('token', token);
		return fetch(endpoint + '?do=' + action, { method: 'POST', credentials: 'same-origin', cache: 'no-store', body: body })
			.then(function (r) { return r.json(); })
			.then(function (data) {
				// the session lost its token: take a fresh one and try once more
				if (!data.ok && !retried && /token/i.test(String(data.error || ''))) {
					return get('payg.admin').then(function (fresh) {
						token = fresh.token || token;
						return post(action, body, true);
					});
				}
				return data;
			})
			.catch(function () {
				return { ok: false, error: 'network / server error' };
			});
	}

	function modeName(mode) {
		return mode === 'balance' ? W.onBalance : (mode === 'empty' ? W.empty : W.plan);
	}

	function fillForm(settings, tiers) {
		factor = String(settings.payg_show_toman) === '0' ? 1 : 10;

		document.querySelectorAll('#PaygSettings .pa-unit').forEach(function (el) {
			el.textContent = '(' + (factor === 10 ? W.toman : W.rial) + ')';
		});

		fields.forEach(function (name) {
			var el = $id('pa_' + name);
			if (!el) { return; }
			if (checks.indexOf(name) >= 0) {
				el.checked = String(settings[name]) === '1';
			} else if (moneyFields.indexOf(name) >= 0) {
				el.value = shown(settings[name]);
			} else {
				el.value = settings[name];
			}
		});

		$id('pa_payg_bonus_tiers').value = (tiers || []).map(function (t) {
			return shown(t.min) + ':' + t.percent;
		}).join('\n');
	}

	function load() {
		return get('payg.admin').then(function (data) {
			if (!data.ok) {
				say(data.error);
				return;
			}
			token = data.token;
			fillForm(data.settings, data.tiers);

			var t = data.totals || {};
			var u = data.usage || {};
			$id('paKpis').innerHTML =
				kpi(W.charged, money(t.charged), 'is-green')
				+ kpi(W.bonus, money(Number(t.bonus) + Number(t.adjusted)), 'is-violet')
				+ kpi(W.spent, money(t.spent), 'is-amber')
				+ kpi(W.unspent, money(t.unspent), '')
				+ kpi(W.owed, money(t.owed), 'is-red')
				+ kpi(W.today, money(u.today), 'is-amber')
				+ kpi(W.month, money(u.month), 'is-amber')
				+ kpi(W.wallets, num(t.wallets), '')
				+ kpi(W.onBalance, num(t.on_balance), 'is-amber')
				+ kpi(W.empty, num(t.empty), 'is-red');

			$id('paLastRun').textContent = W.lastRun + ': ' + (data.last_run > 0 ? when(data.last_run) : W.never);

			$id('paPerServer').innerHTML = (data.per_server || []).map(function (r) {
				return '<tr><td>' + esc(r.name) + '</td><td>' + num(shown(r.revenue)) + '</td><td>' + vol(r.bytes)
					+ '</td><td>' + vol(r.free_bytes) + '</td></tr>';
			}).join('') || '<tr><td colspan="4">' + esc(W.nothing) + '</td></tr>';

			$id('paRates').innerHTML = (data.servers || []).map(function (s) {
				var state = !s.enabled ? W.off : (s.down ? W.down : W.up);
				return '<tr><td>' + esc(s.name) + ' <small class="text-muted">#' + s.id + '</small></td>'
					+ '<td>' + esc(state) + '</td>'
					+ '<td><input type="text" class="form-control form-control-sm pa-rate" dir="ltr" data-id="' + s.id + '"'
					+ ' value="' + (s.custom ? esc(shown(s.price)) : '') + '" placeholder="' + esc(W.defaultP) + ' ' + num(shown(data.settings.payg_default_price)) + '"></td></tr>';
			}).join('');

			var c = data.commission || {};
			$id('paCommission').innerHTML =
				kpi(W.cBalance, money(c.balance), 'is-violet')
				+ kpi(W.cEarned, money(c.earned), 'is-green')
				+ kpi(W.cSpent, money(c.spent), 'is-amber')
				+ kpi(W.money, money(data.money_total), '');

			$id('paMigrated').textContent = data.migrated ? W.migrated.replace('%date%', data.migrated) : '';
			$id('paMigrate').disabled = !!data.migrated;
			$id('paMigrate').setAttribute('data-total', data.money_total);
		});
	}

	function users() {
		var q = encodeURIComponent($id('paQuery').value.trim());
		var mode = encodeURIComponent($id('paMode').value);

		get('payg.users', '&q=' + q + '&mode=' + mode + '&page=' + page).then(function (data) {
			if (!data.ok) {
				say(data.error);
				return;
			}

			$id('paUsers').innerHTML = (data.rows || []).map(function (r) {
				var balance = Number(r.balance);
				return '<tr class="pa-user" data-id="' + r.userid + '">'
					+ '<td>' + esc(r.username) + ' <small class="text-muted">#' + r.userid + '</small><br><small class="text-muted">' + esc(r.email) + '</small></td>'
					+ '<td>' + money(r.charged) + '</td>'
					+ '<td>' + money(Number(r.bonus) + Number(r.adjusted)) + '</td>'
					+ '<td>' + money(r.spent) + '</td>'
					+ '<td class="' + (balance < 0 ? 'pa-neg' : '') + '">' + money(balance) + '</td>'
					+ '<td>' + esc(modeName(r.mode)) + (Number(r.auto) === 1 ? '' : ' ⏸') + '</td>'
					+ '<td>' + when(r.last_usage) + '</td></tr>';
			}).join('') || '<tr><td colspan="7">' + esc(W.nothing) + '</td></tr>';

			var pages = Math.max(1, Math.ceil(data.total / data.per));
			$id('paUsersCount').textContent = W.count.replace('%n%', num(data.total)) + ' · ' + page + '/' + pages;
			$id('paPrev').disabled = page <= 1;
			$id('paNext').disabled = page >= pages;
		});
	}

	function ledger(userId) {
		get('payg.ledger', '&userid=' + userId).then(function (data) {
			if (!data.ok) {
				say(data.error);
				return;
			}
			var kinds = { charge: W.kCharge, bonus: W.kBonus, usage: W.kUsage, adjust: W.kAdjust };
			var rows = (data.rows || []).map(function (r) {
				var detail = r.kind === 'usage'
					? (r.server || '#') + ' · ' + vol(Number(r.bytes)) + (Number(r.free_bytes) > 0 ? ' (+' + vol(r.free_bytes) + ' free)' : '') + ' @ ' + money(r.rate)
					: r.note;
				return '<tr><td>' + when(r.updated) + '</td><td>' + esc(kinds[r.kind] || r.kind) + '</td><td>' + esc(detail)
					+ '</td><td class="' + (Number(r.amount) < 0 ? 'pa-neg' : '') + '">' + money(r.amount) + '</td><td>' + money(r.balance_after) + '</td></tr>';
			}).join('');
			var box = $id('paLedger');
			box.innerHTML = '<div class="d-flex justify-content-between align-items-center mb-2"><b>#' + userId
				+ ' · ' + esc(W.unspent) + ': ' + money(data.wallet.balance) + ' · ' + esc(W.cBalance) + ': ' + money(data.commission_balance)
				+ '</b><button type="button" class="btn btn-sm btn-outline-secondary" id="paLedgerClose">' + esc(W.close) + '</button></div>'
				+ '<div class="table-responsive"><table class="table table-sm pa-table"><tbody>'
				+ (rows || '<tr><td>' + esc(W.nothing) + '</td></tr>') + '</tbody></table></div>';
			box.hidden = false;
			$id('paLedgerClose').addEventListener('click', function () { box.hidden = true; });
			$id('paAdjUser').value = userId;
		});
	}

	/*
	 * Saves the form and shows what the server stored, from the same answer:
	 * no second request that a cache could answer with the old numbers.
	 */
	function saveSettings() {
		var body = new FormData();
		fields.forEach(function (name) {
			var el = $id('pa_' + name);
			if (checks.indexOf(name) >= 0) {
				body.append(name, el.checked ? 1 : 0);
			} else if (moneyFields.indexOf(name) >= 0) {
				body.append(name, toRial(el.value) || '0');
			} else {
				body.append(name, el.value);
			}
		});
		body.append('payg_bonus_tiers', $id('pa_payg_bonus_tiers').value.split(/\r?\n/).map(function (line) {
			var parts = line.split(/[:=]/);
			return parts.length === 2 ? toRial(parts[0]) + ':' + parts[1].replace(/[^0-9.۰-۹]/g, '') : '';
		}).filter(Boolean).join('\n'));

		document.querySelectorAll('#paSave, .pa-save-all').forEach(function (b) { b.disabled = true; });

		post('payg.save', body).then(function (data) {
			document.querySelectorAll('#paSave, .pa-save-all').forEach(function (b) { b.disabled = false; });

			if (!data.ok) {
				var text = W.failed.replace('%error%', data.error || '?');
				status(text, false);
				say(text);
				return;
			}

			fillForm(data.settings, data.tiers);
			var min = Number(data.settings.payg_min_charge) || 0;
			var text = W.savedMin.replace('%min%', min > 0 ? money(min) : W.noMin);
			status(text, true);
			say(text);
		});
	}

	$id('paSave').addEventListener('click', saveSettings);
	document.querySelectorAll('.pa-save-all').forEach(function (b) { b.addEventListener('click', saveSettings); });

	/* Enter in a settings box saves, instead of doing nothing */
	document.querySelectorAll('#PaygSettings input[id^="pa_"]').forEach(function (input) {
		input.addEventListener('keydown', function (e) {
			if (e.key === 'Enter') {
				e.preventDefault();
				saveSettings();
			}
		});
	});

	$id('paSaveRates').addEventListener('click', function () {
		var body = new FormData();
		document.querySelectorAll('.pa-rate').forEach(function (input) {
			body.append('rates[' + input.getAttribute('data-id') + ']', toRial(input.value.trim()));
		});
		post('payg.rates', body).then(function (data) {
			say(data.ok ? W.saved : W.failed.replace('%error%', data.error || '?'));
			if (data.ok) { load(); }
		});
	});

	$id('paFind').addEventListener('click', function () { page = 1; users(); });
	$id('paQuery').addEventListener('keydown', function (e) {
		if (e.key === 'Enter') { page = 1; users(); }
	});
	$id('paMode').addEventListener('change', function () { page = 1; users(); });
	$id('paPrev').addEventListener('click', function () { page = Math.max(1, page - 1); users(); });
	$id('paNext').addEventListener('click', function () { page++; users(); });
	$id('paUsers').addEventListener('click', function (e) {
		var row = e.target.closest('.pa-user');
		if (row) { ledger(row.getAttribute('data-id')); }
	});

	$id('paAdjust').addEventListener('click', function () {
		var body = new FormData();
		body.append('user', $id('paAdjUser').value.trim());
		body.append('amount', toRial($id('paAdjAmount').value.trim()));
		body.append('reason', $id('paAdjReason').value.trim());
		body.append('wallet', $id('paAdjWallet').value);
		post('payg.adjust', body).then(function (data) {
			if (!data.ok) {
				say(W.failed.replace('%error%', data.error || '?'));
				return;
			}
			say(W.saved + ' · ' + money(data.balance));
			$id('paAdjAmount').value = '';
			$id('paAdjReason').value = '';
			load();
			users();
		});
	});

	$id('paMigrate').addEventListener('click', function () {
		var total = money(this.getAttribute('data-total'));
		if (!window.confirm(W.migrateQ.replace('%total%', total))) {
			return;
		}
		post('commission.migrate', new FormData()).then(function (data) {
			say(data.ok ? W.migrateOk.replace('%users%', num(data.users)).replace('%total%', money(data.total)) : W.failed.replace('%error%', data.error || '?'));
			if (data.ok) { load(); }
		});
	});

	$id('paSubExample').textContent = location.origin + '/xmplus-patch.php?do=sub&t=TOKEN&config=1';

	load().then(users);
})();
</script>
{/literal}
