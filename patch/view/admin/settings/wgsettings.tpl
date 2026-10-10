{*
  WireGuard servers on the same subscription - admin side.
  Included by admin/servers/index.tpl (the servers page); talks to
  /xmplus-patch.php?do=wg.* (app/Patch/Wg.php).
  A server is added here, which gives it a key shown once; the install command
  built from it sets WireGuard and the agent up on the server
  (node/wireguard/install.sh in the patch repository).

  The direct-route card is the OpenVPN one, settings and all: the same Iran
  list and the admin's own destinations, applied here on the server and there
  in the customer's file. This card only points at it.
*}
<div class="card card-shadow shadow-lg rounded mb-3 mb-lg-5" id="WgSettings">
	<div class="card-header">
		<h4 class="card-header-title">🛡️ {$translate->get('WgAdmTitle')}</h4>
	</div>
	<div class="card-body wv">
		<p class="text-muted small">{$translate->get('WgAdmIntro')}</p>

		<div class="alert alert-danger d-none" id="wvSodium" role="alert"></div>

		<div class="d-flex flex-wrap align-items-center justify-content-between gap-3 mb-3">
			<div class="d-flex flex-column gap-2">
				<label class="wv-check"><input type="checkbox" id="wvEnabled"> {$translate->get('WgAdmEnabled')}</label>
				<label class="wv-check"><input type="checkbox" id="wvNotify"> {$translate->get('WgAdmNotify')}</label>
				<label class="wv-check"><input type="checkbox" id="wvChains"> {$translate->get('WgAdmChains')}</label>
				<small class="text-muted">{$translate->get('WgAdmChainsHint')}</small>
			</div>
			<div class="d-flex flex-wrap gap-2">
				<button type="button" class="btn btn-outline-secondary btn-sm" id="wvNotifyTest">✉️ {$translate->get('WgAdmNotifyTest')}</button>
				<button type="button" class="btn btn-primary btn-sm" id="wvSaveEnabled">💾 {$translate->get('Save')}</button>
			</div>
		</div>
		<p class="small mb-3" id="wvJob"></p>

		<h5 class="wv-h">🖥 {$translate->get('WgAdmServers')}</h5>
		<div class="table-responsive">
			<table class="table table-sm wv-table">
				<thead><tr>
					<th>{$translate->get('WgAdmName')}</th>
					<th>{$translate->get('WgAdmState')}</th>
					<th>{$translate->get('WgAdmAddress')}</th>
					<th>{$translate->get('WgAdmGroups')}</th>
					<th>{$translate->get('WgAdmRate')}</th>
					<th>{$translate->get('WgAdmToday')}</th>
					<th></th>
				</tr></thead>
				<tbody id="wvNodes"><tr><td colspan="7" class="text-muted">…</td></tr></tbody>
			</table>
		</div>

		<h5 class="wv-h" id="wvFormTitle">➕ {$translate->get('WgAdmAdd')}</h5>
		<input type="hidden" id="wvId" value="0">
		<div class="row g-3">
			<div class="col-md-6">
				<label class="form-label" for="wvName">{$translate->get('WgAdmName')}</label>
				<input type="text" class="form-control" id="wvName" maxlength="100" placeholder="Finland 1">
			</div>
			<div class="col-md-3">
				<label class="form-label" for="wvRate">{$translate->get('WgAdmRate')}</label>
				<input type="text" class="form-control" id="wvRate" dir="ltr" value="1">
			</div>
			<div class="col-md-3">
				<label class="form-label" for="wvSort">{$translate->get('WgAdmSort')}</label>
				<input type="text" class="form-control" id="wvSort" dir="ltr" value="0">
			</div>
			<div class="col-md-6">
				<label class="form-label" for="wvHost">{$translate->get('WgAdmHost')}</label>
				<input type="text" class="form-control" id="wvHost" dir="ltr" placeholder="vpn.example.com">
				<small class="text-muted">{$translate->get('WgAdmHostHint')}</small>
			</div>
			<div class="col-md-3">
				<label class="form-label" for="wvPort">{$translate->get('WgAdmPort')}</label>
				<input type="text" class="form-control" id="wvPort" dir="ltr" placeholder="{$translate->get('WgAdmPortHint')}">
				<small class="text-muted">{$translate->get('WgAdmPortHint2')}</small>
			</div>
			<div class="col-md-3">
				<label class="form-label" for="wvMtu">{$translate->get('WgAdmMtu')}</label>
				<input type="number" class="form-control" id="wvMtu" dir="ltr" min="1280" max="1500" value="1420" placeholder="1420">
				<small class="text-muted">{$translate->get('WgAdmMtuHint')}</small>
			</div>
		</div>

		<h5 class="wv-h">{$translate->get('WgAdmGroups')}</h5>
		<p class="small text-muted mb-2">فقط کاربرانی که در گروه‌های انتخاب‌شده باشند به این سرور دسترسی خواهند داشت. در صورت انتخاب نکردن هیچ گروهی، سرور برای هیچ کاربری فعال نخواهد شد.</p>
		<div class="wv-groups" id="wvGroups"></div>

		<label class="wv-check mt-2"><input type="checkbox" id="wvNodeEnabled"> {$translate->get('WgAdmNodeEnabled')}</label>

		<div class="d-flex justify-content-end gap-2 mt-3">
			<button type="button" class="btn btn-outline-secondary btn-sm d-none" id="wvCancel">{$translate->get('WgAdmCancel')}</button>
			<button type="button" class="btn btn-primary btn-sm" id="wvSaveNode">💾 {$translate->get('Save')}</button>
		</div>

		<div class="wv-install d-none" id="wvInstall">
			<h5 class="wv-h">🚀 {$translate->get('WgAdmInstall')}</h5>
			<p class="small text-muted mb-2">{$translate->get('WgAdmInstallHint')}</p>
			<div class="row g-2 mb-2">
				<div class="col-md-6">
					<label class="form-label small" for="wvPanelUrl">{$translate->get('WgAdmPanelUrl')}</label>
					<input type="text" class="form-control form-control-sm" id="wvPanelUrl" dir="ltr">
				</div>
				<div class="col-md-3">
					<label class="form-label small" for="wvListenPort">Port</label>
					<input type="text" class="form-control form-control-sm" id="wvListenPort" dir="ltr" value="auto">
				</div>
				<div class="col-md-3">
					<label class="form-label small" for="wvInstallMtu">MTU</label>
					<input type="number" class="form-control form-control-sm" id="wvInstallMtu" dir="ltr" value="1420" min="1280" max="1500">
				</div>
			</div>
			<pre class="wv-cmd copy-text" id="wvCmd" dir="ltr"></pre>
			<p class="small text-danger mb-0">{$translate->get('WgAdmKeyOnce')}</p>
		</div>

		<details class="wv-more mt-3">
			<summary>🗑 {$translate->get('WgAdmUninstall')}</summary>
			<p class="small text-muted my-2">{$translate->get('WgAdmUninstallHint')}</p>
			<pre class="wv-cmd copy-text" id="wvUninstallCmd" dir="ltr"></pre>
		</details>

		<details class="wv-more mt-3" id="wvSessionsBox">
			<summary>👥 {$translate->get('WgAdmSessions')}</summary>
			<div class="table-responsive">
				<table class="table table-sm wv-table">
					<thead><tr>
						<th>{$translate->get('WgAdmName')}</th>
						<th>{$translate->get('WgAdmUser')}</th>
						<th>IP</th>
						<th>{$translate->get('WgAdmVolume')}</th>
						<th>{$translate->get('WgAdmSince')}</th>
					</tr></thead>
					<tbody id="wvSessions"></tbody>
				</table>
			</div>
		</details>

		
		<h5 class="wv-h mt-4" id="WgBypass">🇮🇷 {$translate->get('OvpnAdmBypass')}</h5>
		<p class="small text-muted">{$translate->get('OvpnAdmBypassIntro')}</p>
		<label class="wv-check mb-2"><input type="checkbox" id="wvBypassIran"> {$translate->get('OvpnAdmBypassIran')}</label>
		<p class="small text-muted mb-2">
			<span id="wvIranInfo"></span>
			<button type="button" class="btn btn-link btn-sm p-0 ms-2" id="wvIranRefresh">🔄 {$translate->get('OvpnAdmIranRefresh')}</button>
		</p>
		<label class="form-label" for="wvBypassCustom">{$translate->get('OvpnAdmBypassCustom')}</label>
		<textarea class="form-control" id="wvBypassCustom" rows="6" dir="ltr" placeholder="bmi.ir&#10;shaparak.ir&#10;digikala.com&#10;185.143.232.0/22&#10;# 1.2.3.4"></textarea>
		<small class="text-muted d-block mb-2">{$translate->get('OvpnAdmBypassCustomHint')}</small>
		<div class="small mb-2" id="wvBypassHosts"></div>
		<label class="wv-check mb-1"><input type="checkbox" id="wvBypassXray"> {$translate->get('OvpnAdmBypassXray')}</label>
		<small class="text-muted d-block mb-2">{$translate->get('OvpnAdmBypassXrayHint')}</small>
		<div class="d-flex justify-content-end">
			<button type="button" class="btn btn-primary btn-sm" id="wvBypassSave">💾 {$translate->get('Save')}</button>
		</div>

		<p class="small text-muted mt-3 mb-0">{$translate->get('WgAdmPriceNote')}</p>
		<p class="small text-muted mt-2 mb-0">📱 {$translate->get('WgAdmAppNote')}</p>
	</div>
</div>
<script>
	/* new Object(), not a brace literal: Smarty would read the brace as a tag */
	window.WgWords = new Object();
		window.WgWords.iranInfo   = "{$translate->get('OvpnAdmIranInfo')|escape:'javascript'}";
	window.WgWords.routes     = "{$translate->get('OvpnAdmRoutes')|escape:'javascript'}";
	window.WgWords.iranCapped = "{$translate->get('OvpnAdmIranCapped')|escape:'javascript'}";
	window.WgWords.saved     = "{$translate->get('WgAdmSaved')|escape:'javascript'}";
	window.WgWords.failed    = "{$translate->get('WgAdmFailed')|escape:'javascript'}";
	window.WgWords.live      = "{$translate->get('WgAdmLive')|escape:'javascript'}";
	window.WgWords.down      = "{$translate->get('WgAdmDown')|escape:'javascript'}";
	window.WgWords.waiting   = "{$translate->get('WgAdmWaiting')|escape:'javascript'}";
	window.WgWords.off       = "{$translate->get('WgAdmOff')|escape:'javascript'}";
	window.WgWords.all       = "{$translate->get('WgAdmAllGroups')|escape:'javascript'}";
	window.WgWords.edit      = "{$translate->get('WgAdmEdit')|escape:'javascript'}";
	window.WgWords.newKey    = "{$translate->get('WgAdmNewKey')|escape:'javascript'}";
	window.WgWords.remove    = "{$translate->get('WgAdmDelete')|escape:'javascript'}";
	window.WgWords.confirmKey = "{$translate->get('WgAdmConfirmKey')|escape:'javascript'}";
	window.WgWords.confirmDel = "{$translate->get('WgAdmConfirmDelete')|escape:'javascript'}";
	window.WgWords.add       = "{$translate->get('WgAdmAdd')|escape:'javascript'}";
	window.WgWords.editing   = "{$translate->get('WgAdmEditing')|escape:'javascript'}";
	window.WgWords.none      = "{$translate->get('WgAdmNone')|escape:'javascript'}";
	window.WgWords.online    = "{$translate->get('WgAdmOnline')|escape:'javascript'}";
	window.WgWords.jobLast   = "{$translate->get('WgAdmJobLast')|escape:'javascript'}";
	window.WgWords.jobNever  = "{$translate->get('WgAdmJobNever')|escape:'javascript'}";
	window.WgWords.jobLate   = "{$translate->get('WgAdmJobLate')|escape:'javascript'}";
	window.WgWords.testSent  = "{$translate->get('WgAdmTestSent')|escape:'javascript'}";
	window.WgWords.noSodium  = "{$translate->get('WgAdmNoSodium')|escape:'javascript'}";
	window.WgWords.download  = "{$translate->get('WgAdmDownload')|escape:'javascript'}";
	window.WgWords.portInfo  = "{$translate->get('WgAdmPortInfo')|escape:'javascript'}";
	window.WgWords.noPort    = "{$translate->get('WgAdmNoPort')|escape:'javascript'}";
	window.WgWords.dnsOk     = "{$translate->get('WgAdmDnsOk')|escape:'javascript'}";
	window.WgWords.dnsBad    = "{$translate->get('WgAdmDnsBad')|escape:'javascript'}";
	window.WgWords.notFound  = "{$translate->get('WgAdmNotFound')|escape:'javascript'}";
</script>
{literal}
<style>
.wv-h { font-size: 15px; font-weight: 700; margin: 18px 0 10px; }
.wv-check { display: inline-flex; align-items: center; gap: 7px; font-weight: 600; cursor: pointer; }
.wv-table td, .wv-table th { vertical-align: middle; white-space: nowrap; }
.wv-table .wv-note { display: inline-block; margin-inline-start: 8px; }
.wv-groups { display: flex; flex-wrap: wrap; gap: 12px; font-size: 13px; }
.wv-groups label { display: inline-flex; align-items: center; gap: 5px; cursor: pointer; }
.wv-dot { display: inline-block; width: 9px; height: 9px; border-radius: 50%; margin-inline-end: 6px; vertical-align: middle; }
.wv-dot.is-live { background: #10b981; }
.wv-dot.is-down { background: #f43f5e; }
.wv-dot.is-wait { background: #f59e0b; }
.wv-install { margin-top: 18px; padding: 14px; border-radius: 12px; background: rgba(15, 118, 110, .06); border: 1px dashed rgba(15, 118, 110, .3); }
.wv-cmd { margin: 0; padding: 10px; border-radius: 10px; background: #0f172a; color: #e2e8f0; font-size: 12px; line-height: 1.7; overflow-x: auto; white-space: pre-wrap; word-break: break-all; }
.wv-more summary { cursor: pointer; font-weight: 600; }
.wv-actions { display: flex; gap: 4px; justify-content: flex-end; }
</style>
{/literal}
<script>
(function () {
	var endpoint = '/xmplus-patch.php';
	var words = window.WgWords || {};
	var token = '';
	var state = { nodes: [], groups: [], repo: '', branch: 'main', sessions: [] };
	var lastKey = null; // { id, key } right after a server was added or re-keyed

	function $(id) { return document.getElementById(id); }

	function esc(text) {
		return String(text == null ? '' : text).replace(/[&<>"']/g, function (c) {
			return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c];
		});
	}

	function say(text) {
		if (window.layer && layer.msg) {
			layer.msg(text, { time: 5000, offset: '100px' });
		} else {
			alert(text);
		}
	}

	function gb(bytes) {
		return (Number(bytes || 0) / 1073741824).toFixed(2) + ' GB';
	}

	function get(action) {
		return fetch(endpoint + '?do=' + action + '&_=' + Date.now(), { credentials: 'same-origin', cache: 'no-store' })
			.then(function (r) { return r.json(); });
	}

	function post(action, fields) {
		var body = new FormData();
		body.append('token', token);
		Object.keys(fields).forEach(function (name) {
			var value = fields[name];
			if (Array.isArray(value)) {
				value.forEach(function (item) { body.append(name + '[]', item); });
			} else {
				body.append(name, value);
			}
		});
		return fetch(endpoint + '?do=' + action, { method: 'POST', credentials: 'same-origin', body: body })
			.then(function (r) { return r.json(); });
	}

	function groupName(id) {
		for (var i = 0; i < state.groups.length; i++) {
			if (Number(state.groups[i].id) === Number(id)) { return state.groups[i].name + ' (#' + id + ')'; }
		}
		return '#' + id;
	}

	function renderNodes() {
		var body = $('wvNodes');
		if (!state.nodes.length) {
			body.innerHTML = '<tr><td colspan="7" class="text-muted">' + esc(words.none) + '</td></tr>';
			return;
		}

		body.innerHTML = state.nodes.map(function (node) {
			var dot, stateText;
			if (!node.enabled) {
				dot = ''; stateText = words.off;
			} else if (!node.heartbeat) {
				dot = 'is-wait'; stateText = words.waiting;
			} else if (node.live) {
				dot = 'is-live'; stateText = words.live + ' · ' + node.online + ' ' + words.online;
			} else {
				dot = 'is-down'; stateText = words.down;
			}

			var host = node.host_override || node.host;
			// WireGuard has one socket: the port customers use is the port the
			// server listens on, so there is nothing to choose here
			var address = node.heartbeat
				? '<span dir="ltr">UDP ' + esc(host) + ' : ' + esc(node.port) + '</span> <span class="badge badge-light" dir="ltr">MTU ' + (node.mtu || 1420) + '</span>'
				: '<span class="text-muted">UDP ' + esc(host || '—') + ' : ' + esc(words.noPort) + '</span>';

			if (node.domain) {
				var dom = node.domain;
				if (dom.points_ok === true) {
					address += '<br><small class="text-success">✓ ' + esc(words.dnsOk) + ' <span dir="ltr">(' + esc(dom.name) + ')</span></small>';
				} else if (dom.points_ok === false) {
					address += '<br><small class="text-danger">⚠️ ' + esc(words.dnsBad.replace('%ip%', dom.server_ip)) + ' <span dir="ltr">'
						+ esc(dom.points.length ? dom.points.join(', ') : words.notFound) + '</span></small>';
				}
			}

			var groups = node.groups.length ? esc(node.groups.map(groupName).join('، ')) : '<span class="text-danger small fw-bold">⚠️ بدون گروه (غیرفعال)</span>';

			return '<tr>'
				+ '<td><b>' + esc(node.name) + '</b>' + (node.version ? ' <small class="text-muted">v' + esc(node.version) + '</small>' : '') + '</td>'
				+ '<td><span class="wv-dot ' + dot + '"></span>' + esc(stateText) + '</td>'
				+ '<td>' + address + '</td>'
				+ '<td>' + groups + '</td>'
				+ '<td dir="ltr">×' + esc(node.rate) + '</td>'
				+ '<td dir="ltr">' + gb(node.today_bytes) + '</td>'
				+ '<td><div class="wv-actions">'
				+ (node.ready ? '<a class="btn btn-outline-success btn-xs btn-sm" href="' + endpoint + '?do=wg.profile&amp;node=' + node.id + '" download>📥 ' + esc(words.download) + '</a>' : '')
				+ '<button type="button" class="btn btn-outline-primary btn-xs btn-sm" data-wv-edit="' + node.id + '">' + esc(words.edit) + '</button>'
				+ '<button type="button" class="btn btn-outline-warning btn-xs btn-sm" data-wv-key="' + node.id + '">' + esc(words.newKey) + '</button>'
				+ '<button type="button" class="btn btn-outline-danger btn-xs btn-sm" data-wv-del="' + node.id + '">' + esc(words.remove) + '</button>'
				+ '</div></td>'
				+ '</tr>';
		}).join('');
	}

	function renderGroups(selected) {
		var chosen = (selected || []).map(Number);
		$('wvGroups').innerHTML = state.groups.map(function (group) {
			var on = chosen.indexOf(Number(group.id)) !== -1 ? ' checked' : '';
			return '<label><input type="checkbox" value="' + Number(group.id) + '"' + on + '> ' + esc(group.name) + ' <small class="text-muted">#' + Number(group.id) + '</small></label>';
		}).join('');
	}

	function resetForm() {
		$('wvId').value = '0';
		$('wvName').value = '';
		$('wvRate').value = '1';
		$('wvSort').value = '0';
		$('wvHost').value = '';
		$('wvPort').value = '';
		$('wvMtu').value = '1420';
		$('wvNodeEnabled').checked = true;
		$('wvFormTitle').textContent = '➕ ' + words.add;
		$('wvCancel').classList.add('d-none');
		renderGroups([]);
	}

	function editNode(id) {
		var node = state.nodes.filter(function (n) { return n.id === id; })[0];
		if (!node) { return; }
		$('wvId').value = String(node.id);
		$('wvName').value = node.name;
		$('wvRate').value = String(node.rate);
		$('wvSort').value = String(node.sort);
		$('wvHost').value = node.host_override;
		// blank: the port the server itself reported, which is the only one it has
		$('wvPort').value = '';
		$('wvMtu').value = String(node.mtu || 1420);
		$('wvNodeEnabled').checked = !!node.enabled;
		$('wvFormTitle').textContent = '✏️ ' + words.editing + ' ' + node.name;
		$('wvCancel').classList.remove('d-none');
		renderGroups(node.groups);
		$('wvName').focus();
	}

	function shellQuote(text) {
		return "'" + String(text).replace(/'/g, "'\\''") + "'";
	}

	function renderInstall() {
		if (!lastKey) {
			$('wvInstall').classList.add('d-none');
			return;
		}
		var panel = $('wvPanelUrl').value.trim().replace(/\/+$/, '');
		if (/^https?:\/[^\/]/.test(panel)) {
			panel = panel.replace(/^(https?):\/([^\/])/, '$1://$2');
		}
		var script = 'https://raw.githubusercontent.com/' + state.repo + '/' + state.branch + '/node/wireguard/install.sh';
		var mtu = parseInt($('wvInstallMtu') ? $('wvInstallMtu').value : '', 10) || 1420;
		if (mtu < 1280 || mtu > 1500) { mtu = 1420; }
		$('wvCmd').textContent = 'curl -fsSL ' + script + ' -o wg-install.sh && sudo bash wg-install.sh'
			+ ' --panel ' + shellQuote(panel)
			+ ' --node ' + lastKey.id
			+ ' --key ' + lastKey.key
			+ ' --listen ' + (parseInt($('wvListenPort').value, 10) || 'auto')
			+ ' --mtu ' + mtu;
		$('wvCmd').setAttribute('data-clipboard-text', $('wvCmd').textContent);
		$('wvInstall').classList.remove('d-none');
	}

	function renderUninstall() {
		var script = 'https://raw.githubusercontent.com/' + state.repo + '/' + state.branch + '/node/wireguard/uninstall.sh';
		$('wvUninstallCmd').textContent = 'curl -fsSL ' + script + ' -o wg-uninstall.sh && sudo bash wg-uninstall.sh';
		$('wvUninstallCmd').setAttribute('data-clipboard-text', $('wvUninstallCmd').textContent);
	}

	function renderSessions(rows) {
		var names = {};
		state.nodes.forEach(function (n) { names[n.id] = n.name; });
		$('wvSessions').innerHTML = rows.length ? rows.map(function (row) {
			return '<tr>'
				+ '<td>' + esc(names[row.node] || ('#' + row.node)) + '</td>'
				+ '<td>' + row.email + ' <small class="text-muted">u' + Number(row.userid) + '</small></td>'
				+ '<td dir="ltr">' + esc(row.ip) + '</td>'
				+ '<td dir="ltr">' + gb(row.bytes) + '</td>'
				+ '<td dir="ltr">' + esc(new Date(row.started * 1000).toLocaleString()) + '</td>'
				+ '</tr>';
		}).join('') : '<tr><td colspan="5" class="text-muted">' + esc(words.none) + '</td></tr>';
	}

	
	function renderBypass(bypass) {
		if (!bypass) { return; }
		$('wvBypassIran').checked = !!bypass.iran;
		$('wvBypassXray').checked = !!bypass.xray;
		$('wvBypassCustom').value = bypass.custom || '';
		$('wvIranInfo').textContent = words.iranInfo.replace('%count%', bypass.iran_ranges).replace('%date%', bypass.iran_date || '—')
			+ ' · ' + words.routes.replace('%count%', bypass.routes)
			+ (bypass.iran && bypass.iran_used < bypass.iran_ranges
				? ' · ' + words.iranCapped.replace('%used%', bypass.iran_used).replace('%share%', bypass.iran_share) : '');
		var hosts = bypass.hosts || {};
		$('wvBypassHosts').innerHTML = Object.keys(hosts).map(function (domain) {
			var ips = hosts[domain] || [];
			return '<div dir="ltr"><b>' + esc(domain) + '</b> → '
				+ (ips.length ? esc(ips.join(', ')) : '<span class="text-danger">' + esc(words.notFound) + '</span>') + '</div>';
		}).join('');
	}

	$('wvBypassSave').addEventListener('click', function () {
		post('wg.bypasssave', { iran: $('wvBypassIran').checked ? '1' : '0', xray: $('wvBypassXray').checked ? '1' : '0', custom: $('wvBypassCustom').value }).then(function (data) {
			if (!data.ok) { say(words.failed + ': ' + data.error); return; }
			renderBypass(data.bypass);
			say(words.saved + (data.failed && data.failed.length ? ' · ' + words.notFound + ': ' + data.failed.join(', ') : ''));
		});
	});

	$('wvIranRefresh').addEventListener('click', function () {
		post('wg.iranrefresh', {}).then(function (data) {
			if (!data.ok) { say(words.failed + ': ' + data.error); return; }
			renderBypass(data.bypass);
			say(words.saved);
		});
	});

	function load() {
		return get('wg.admin').then(function (data) {
			if (!data.ok) { throw new Error(data.error || 'failed'); }
			token = data.token || '';
			state.nodes = data.nodes || [];
			state.groups = data.groups || [];
			state.repo = data.repo || '';
			state.branch = data.branch || 'main';
			// the same snapshot the card's online count came from
			state.sessions = data.sessions || [];
			$('wvEnabled').checked = !!data.enabled;
			$('wvNotify').checked = data.notify !== false;
			$('wvChains').checked = data.chains !== false;
			// without sodium the panel cannot derive a customer's key, so no file
			// can be built at all - say so here instead of failing on download
			$('wvSodium').textContent = data.sodium ? '' : '🚨 ' + words.noSodium;
			$('wvSodium').classList.toggle('d-none', !!data.sodium);
			renderJob(data.job_last, data.now);
			renderNodes();
			renderSessions(state.sessions);
			renderUninstall();
			renderBypass(data.bypass);
			if ($('wvId').value === '0') { renderGroups([]); }
		}).catch(function (error) {
			$('wvNodes').innerHTML = '<tr><td colspan="7" class="text-danger">' + esc(error.message) + '</td></tr>';
		});
	}

	function ago(seconds) {
		var m = Math.max(1, Math.round(seconds / 60));
		return m < 60 ? m + "'" : Math.floor(m / 60) + 'h ' + (m % 60) + "'";
	}

	// whether the scheduler runs the job that sends the Telegram messages
	function renderJob(last, now) {
		var box = $('wvJob');
		if (!last) {
			box.className = 'small mb-3 text-danger';
			box.textContent = '⚠️ ' + words.jobNever;
		} else if (now - last > 300) {
			box.className = 'small mb-3 text-danger';
			box.textContent = '⚠️ ' + words.jobLate + ' ' + ago(now - last);
		} else {
			box.className = 'small mb-3 text-success';
			box.textContent = '✓ ' + words.jobLast + ' ' + ago(now - last);
		}
	}

	$('wvNotifyTest').addEventListener('click', function () {
		post('wg.notifytest', {}).then(function (data) {
			if (!data.ok) { say(words.failed + ': ' + data.error); return; }
			say(Object.keys(data.results).map(function (chat) {
				return chat + ': ' + (data.results[chat] === 'sent' ? words.testSent : data.results[chat]);
			}).join(' · '));
		});
	});

	$('wvPanelUrl').value = location.origin;
	['wvPanelUrl', 'wvListenPort', 'wvInstallMtu'].forEach(function (id) {
		$(id).addEventListener('input', renderInstall);
		$(id).addEventListener('change', renderInstall);
	});

	$('wvSaveEnabled').addEventListener('click', function () {
		post('wg.save', { enabled: $('wvEnabled').checked ? '1' : '0',
			notify: $('wvNotify').checked ? '1' : '0',
			chains: $('wvChains').checked ? '1' : '0' }).then(function (data) {
			say(data.ok ? words.saved : words.failed + ': ' + data.error);
		});
	});

	$('wvCancel').addEventListener('click', resetForm);

	$('wvSaveNode').addEventListener('click', function () {
		var groups = Array.prototype.map.call($('wvGroups').querySelectorAll('input:checked'), function (box) { return box.value; });
		post('wg.nodesave', {
			id: $('wvId').value,
			name: $('wvName').value,
			rate: $('wvRate').value,
			sort: $('wvSort').value,
			host_override: $('wvHost').value,
			port: $('wvPort').value,
			mtu: $('wvMtu').value,
			enabled: $('wvNodeEnabled').checked ? '1' : '0',
			groups: groups
		}).then(function (data) {
			if (!data.ok) { say(words.failed + ': ' + data.error); return; }
			say(words.saved);
			if (data.key) {
				lastKey = { id: data.node.id, key: data.key };
				renderInstall();
			}
			resetForm();
			load();
		});
	});

	$('wvNodes').addEventListener('click', function (event) {
		var button = event.target.closest('button');
		if (!button) { return; }

		if (button.hasAttribute('data-wv-edit')) {
			editNode(Number(button.getAttribute('data-wv-edit')));
		} else if (button.hasAttribute('data-wv-key')) {
			if (!confirm(words.confirmKey)) { return; }
			post('wg.nodekey', { id: button.getAttribute('data-wv-key') }).then(function (data) {
				if (!data.ok) { say(words.failed + ': ' + data.error); return; }
				lastKey = { id: data.id, key: data.key };
				renderInstall();
				$('wvInstall').scrollIntoView({ behavior: 'smooth', block: 'center' });
			});
		} else if (button.hasAttribute('data-wv-del')) {
			if (!confirm(words.confirmDel)) { return; }
			post('wg.nodedel', { id: button.getAttribute('data-wv-del') }).then(function (data) {
				if (!data.ok) { say(words.failed + ': ' + data.error); return; }
				load();
			});
		}
	});

	$('wvSessionsBox').addEventListener('toggle', function () {
		if (!this.open) { return; }
		// refresh the nodes and the list together, so the card's count and the
		// rows below it are always the same snapshot
		load();
	});

	load();
	setInterval(load, 60000);
})();
</script>