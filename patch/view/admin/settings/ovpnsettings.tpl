{*
  OpenVPN servers on the same subscription - admin side.
  Included by settings.tpl; talks to /xmplus-patch.php?do=ovpn.* (app/Patch/Ovpn.php).
  A server is added here, which gives it a key shown once; the install command
  built from it sets OpenVPN and the agent up on the server
  (node/openvpn/install.sh in the patch repository).
*}
<div class="card card-shadow shadow-lg rounded mb-3 mb-lg-5" id="OvpnSettings">
	<div class="card-header">
		<h4 class="card-header-title">🛡️ {$translate->get('OvpnAdmTitle')}</h4>
	</div>
	<div class="card-body ov">
		<p class="text-muted small">{$translate->get('OvpnAdmIntro')}</p>

		<div class="d-flex flex-wrap align-items-center justify-content-between gap-3 mb-3">
			<label class="ov-check"><input type="checkbox" id="ovEnabled"> {$translate->get('OvpnAdmEnabled')}</label>
			<button type="button" class="btn btn-primary btn-sm" id="ovSaveEnabled">💾 {$translate->get('Save')}</button>
		</div>

		<h5 class="ov-h">🖥 {$translate->get('OvpnAdmServers')}</h5>
		<div class="table-responsive">
			<table class="table table-sm ov-table">
				<thead><tr>
					<th>{$translate->get('OvpnAdmName')}</th>
					<th>{$translate->get('OvpnAdmState')}</th>
					<th>{$translate->get('OvpnAdmAddress')}</th>
					<th>{$translate->get('OvpnAdmGroups')}</th>
					<th>{$translate->get('OvpnAdmRate')}</th>
					<th>{$translate->get('OvpnAdmToday')}</th>
					<th></th>
				</tr></thead>
				<tbody id="ovNodes"><tr><td colspan="7" class="text-muted">…</td></tr></tbody>
			</table>
		</div>

		<h5 class="ov-h" id="ovFormTitle">➕ {$translate->get('OvpnAdmAdd')}</h5>
		<input type="hidden" id="ovId" value="0">
		<div class="row g-3">
			<div class="col-md-6">
				<label class="form-label" for="ovName">{$translate->get('OvpnAdmName')}</label>
				<input type="text" class="form-control" id="ovName" maxlength="100" placeholder="Germany 1">
			</div>
			<div class="col-md-3">
				<label class="form-label" for="ovRate">{$translate->get('OvpnAdmRate')}</label>
				<input type="text" class="form-control" id="ovRate" dir="ltr" value="1">
			</div>
			<div class="col-md-3">
				<label class="form-label" for="ovSort">{$translate->get('OvpnAdmSort')}</label>
				<input type="text" class="form-control" id="ovSort" dir="ltr" value="0">
			</div>
			<div class="col-md-6">
				<label class="form-label" for="ovHost">{$translate->get('OvpnAdmHost')}</label>
				<input type="text" class="form-control" id="ovHost" dir="ltr" placeholder="vpn.example.com">
				<small class="text-muted">{$translate->get('OvpnAdmHostHint')}</small>
			</div>
			<div class="col-md-6">
				<label class="form-label">{$translate->get('OvpnAdmGroups')}</label>
				<div class="ov-groups" id="ovGroups"></div>
				<small class="text-muted">{$translate->get('OvpnAdmGroupsHint')}</small>
			</div>
			<div class="col-12">
				<label class="ov-check"><input type="checkbox" id="ovNodeEnabled" checked> {$translate->get('OvpnAdmNodeEnabled')}</label>
			</div>
		</div>
		<div class="d-flex justify-content-end gap-2 mt-3">
			<button type="button" class="btn btn-outline-secondary btn-sm d-none" id="ovCancel">{$translate->get('OvpnAdmCancel')}</button>
			<button type="button" class="btn btn-primary btn-sm" id="ovSaveNode">💾 {$translate->get('Save')}</button>
		</div>

		<div class="ov-install d-none" id="ovInstall">
			<h5 class="ov-h">🚀 {$translate->get('OvpnAdmInstall')}</h5>
			<p class="small text-muted mb-2">{$translate->get('OvpnAdmInstallHint')}</p>
			<div class="row g-2 mb-2">
				<div class="col-md-8">
					<label class="form-label small" for="ovPanelUrl">{$translate->get('OvpnAdmPanelUrl')}</label>
					<input type="text" class="form-control form-control-sm" id="ovPanelUrl" dir="ltr">
				</div>
				<div class="col-md-2">
					<label class="form-label small" for="ovPort">Port</label>
					<input type="text" class="form-control form-control-sm" id="ovPort" dir="ltr" value="1194">
				</div>
				<div class="col-md-2">
					<label class="form-label small" for="ovProto">Proto</label>
					<select class="form-select form-select-sm" id="ovProto"><option>udp</option><option>tcp</option></select>
				</div>
			</div>
			<pre class="ov-cmd copy-text" id="ovCmd" dir="ltr"></pre>
			<p class="small text-danger mb-0">{$translate->get('OvpnAdmKeyOnce')}</p>
		</div>

		<details class="ov-more mt-3" id="ovSessionsBox">
			<summary>👥 {$translate->get('OvpnAdmSessions')}</summary>
			<div class="table-responsive">
				<table class="table table-sm ov-table">
					<thead><tr>
						<th>{$translate->get('OvpnAdmName')}</th>
						<th>{$translate->get('OvpnAdmUser')}</th>
						<th>IP</th>
						<th>{$translate->get('OvpnAdmVolume')}</th>
						<th>{$translate->get('OvpnAdmSince')}</th>
					</tr></thead>
					<tbody id="ovSessions"></tbody>
				</table>
			</div>
		</details>

		<p class="small text-muted mt-3 mb-0">{$translate->get('OvpnAdmPriceNote')}</p>
	</div>
</div>
<script>
	/* new Object(), not a brace literal: Smarty would read the brace as a tag */
	window.OvpnWords = new Object();
	window.OvpnWords.saved    = "{$translate->get('OvpnAdmSaved')|escape:'javascript'}";
	window.OvpnWords.failed   = "{$translate->get('OvpnAdmFailed')|escape:'javascript'}";
	window.OvpnWords.live     = "{$translate->get('OvpnAdmLive')|escape:'javascript'}";
	window.OvpnWords.down     = "{$translate->get('OvpnAdmDown')|escape:'javascript'}";
	window.OvpnWords.waiting  = "{$translate->get('OvpnAdmWaiting')|escape:'javascript'}";
	window.OvpnWords.off      = "{$translate->get('OvpnAdmOff')|escape:'javascript'}";
	window.OvpnWords.all      = "{$translate->get('OvpnAdmAllGroups')|escape:'javascript'}";
	window.OvpnWords.edit     = "{$translate->get('OvpnAdmEdit')|escape:'javascript'}";
	window.OvpnWords.newKey   = "{$translate->get('OvpnAdmNewKey')|escape:'javascript'}";
	window.OvpnWords.remove   = "{$translate->get('OvpnAdmDelete')|escape:'javascript'}";
	window.OvpnWords.confirmKey = "{$translate->get('OvpnAdmConfirmKey')|escape:'javascript'}";
	window.OvpnWords.confirmDel = "{$translate->get('OvpnAdmConfirmDelete')|escape:'javascript'}";
	window.OvpnWords.add      = "{$translate->get('OvpnAdmAdd')|escape:'javascript'}";
	window.OvpnWords.editing  = "{$translate->get('OvpnAdmEditing')|escape:'javascript'}";
	window.OvpnWords.none     = "{$translate->get('OvpnAdmNone')|escape:'javascript'}";
	window.OvpnWords.online   = "{$translate->get('OvpnAdmOnline')|escape:'javascript'}";
</script>
{literal}
<style>
.ov-h { font-size: 15px; font-weight: 700; margin: 18px 0 10px; }
.ov-check { display: inline-flex; align-items: center; gap: 7px; font-weight: 600; cursor: pointer; }
.ov-table td, .ov-table th { vertical-align: middle; white-space: nowrap; }
.ov-dot { display: inline-block; width: 9px; height: 9px; border-radius: 50%; margin-inline-end: 5px; background: #94a3b8; }
.ov-dot.is-live { background: #10b981; }
.ov-dot.is-down { background: #f43f5e; }
.ov-groups { display: flex; flex-wrap: wrap; gap: 6px 14px; padding: 6px 0; }
.ov-groups label { display: inline-flex; gap: 5px; align-items: center; cursor: pointer; font-size: 13px; }
.ov-cmd {
	white-space: pre-wrap;
	word-break: break-all;
	font-size: 12px;
	padding: 12px;
	border-radius: 10px;
	background: #0f172a;
	color: #e2e8f0;
	cursor: pointer;
	text-align: left;
}
.ov-more summary { cursor: pointer; font-weight: 600; }
.ov-actions { display: flex; gap: 4px; justify-content: flex-end; }
</style>
<script>
(function () {
	var endpoint = '/xmplus-patch.php';
	var words = window.OvpnWords || {};
	var token = '';
	var state = { nodes: [], groups: [], repo: '', branch: 'main' };
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
		var body = $('ovNodes');
		if (!state.nodes.length) {
			body.innerHTML = '<tr><td colspan="7" class="text-muted">' + esc(words.none) + '</td></tr>';
			return;
		}

		body.innerHTML = state.nodes.map(function (node) {
			var dot, stateText;
			if (!node.enabled) {
				dot = ''; stateText = words.off;
			} else if (!node.heartbeat) {
				dot = ''; stateText = words.waiting;
			} else if (node.live) {
				dot = 'is-live'; stateText = words.live + ' · ' + node.online + ' ' + words.online;
			} else {
				dot = 'is-down'; stateText = words.down;
			}

			var address = node.host_override || node.host;
			address = address ? address + ':' + node.port + '/' + node.proto : '—';
			var groups = node.groups.length ? node.groups.map(groupName).join('، ') : words.all;

			return '<tr>'
				+ '<td><b>' + esc(node.name) + '</b>' + (node.version ? ' <small class="text-muted">v' + esc(node.version) + '</small>' : '') + '</td>'
				+ '<td><span class="ov-dot ' + dot + '"></span>' + esc(stateText) + '</td>'
				+ '<td dir="ltr">' + esc(address) + '</td>'
				+ '<td>' + esc(groups) + '</td>'
				+ '<td dir="ltr">×' + esc(node.rate) + '</td>'
				+ '<td dir="ltr">' + gb(node.today_bytes) + '</td>'
				+ '<td><div class="ov-actions">'
				+ '<button type="button" class="btn btn-outline-primary btn-xs btn-sm" data-ov-edit="' + node.id + '">' + esc(words.edit) + '</button>'
				+ '<button type="button" class="btn btn-outline-warning btn-xs btn-sm" data-ov-key="' + node.id + '">' + esc(words.newKey) + '</button>'
				+ '<button type="button" class="btn btn-outline-danger btn-xs btn-sm" data-ov-del="' + node.id + '">' + esc(words.remove) + '</button>'
				+ '</div></td>'
				+ '</tr>';
		}).join('');
	}

	function renderGroups(selected) {
		var chosen = (selected || []).map(Number);
		$('ovGroups').innerHTML = state.groups.map(function (group) {
			var on = chosen.indexOf(Number(group.id)) !== -1 ? ' checked' : '';
			return '<label><input type="checkbox" value="' + Number(group.id) + '"' + on + '> ' + esc(group.name) + ' <small class="text-muted">#' + Number(group.id) + '</small></label>';
		}).join('');
	}

	function resetForm() {
		$('ovId').value = '0';
		$('ovName').value = '';
		$('ovRate').value = '1';
		$('ovSort').value = '0';
		$('ovHost').value = '';
		$('ovNodeEnabled').checked = true;
		$('ovFormTitle').textContent = '➕ ' + words.add;
		$('ovCancel').classList.add('d-none');
		renderGroups([]);
	}

	function editNode(id) {
		var node = state.nodes.filter(function (n) { return n.id === id; })[0];
		if (!node) { return; }
		$('ovId').value = String(node.id);
		$('ovName').value = node.name;
		$('ovRate').value = String(node.rate);
		$('ovSort').value = String(node.sort);
		$('ovHost').value = node.host_override;
		$('ovNodeEnabled').checked = !!node.enabled;
		$('ovFormTitle').textContent = '✏️ ' + words.editing + ' ' + node.name;
		$('ovCancel').classList.remove('d-none');
		renderGroups(node.groups);
		$('ovName').focus();
	}

	function shellQuote(text) {
		return "'" + String(text).replace(/'/g, "'\\''") + "'";
	}

	function renderInstall() {
		if (!lastKey) {
			$('ovInstall').classList.add('d-none');
			return;
		}
		var panel = $('ovPanelUrl').value.trim().replace(/\/+$/, '');
		var script = 'https://raw.githubusercontent.com/' + state.repo + '/' + state.branch + '/node/openvpn/install.sh';
		$('ovCmd').textContent = 'curl -fsSL ' + script + ' -o ovpn-install.sh && sudo bash ovpn-install.sh'
			+ ' --panel ' + shellQuote(panel)
			+ ' --node ' + lastKey.id
			+ ' --key ' + lastKey.key
			+ ' --port ' + (parseInt($('ovPort').value, 10) || 1194)
			+ ' --proto ' + $('ovProto').value;
		$('ovCmd').setAttribute('data-clipboard-text', $('ovCmd').textContent);
		$('ovInstall').classList.remove('d-none');
	}

	function renderSessions(rows) {
		var names = {};
		state.nodes.forEach(function (n) { names[n.id] = n.name; });
		$('ovSessions').innerHTML = rows.length ? rows.map(function (row) {
			return '<tr>'
				+ '<td>' + esc(names[row.node] || ('#' + row.node)) + '</td>'
				+ '<td>' + row.email + ' <small class="text-muted">u' + Number(row.userid) + '</small></td>'
				+ '<td dir="ltr">' + esc(row.ip) + '</td>'
				+ '<td dir="ltr">' + gb(row.bytes) + '</td>'
				+ '<td dir="ltr">' + esc(new Date(row.started * 1000).toLocaleString()) + '</td>'
				+ '</tr>';
		}).join('') : '<tr><td colspan="5" class="text-muted">' + esc(words.none) + '</td></tr>';
	}

	function load() {
		return get('ovpn.admin').then(function (data) {
			if (!data.ok) { throw new Error(data.error || 'failed'); }
			token = data.token || '';
			state.nodes = data.nodes || [];
			state.groups = data.groups || [];
			state.repo = data.repo || '';
			state.branch = data.branch || 'main';
			$('ovEnabled').checked = !!data.enabled;
			renderNodes();
			if ($('ovId').value === '0') { renderGroups([]); }
		}).catch(function (error) {
			$('ovNodes').innerHTML = '<tr><td colspan="7" class="text-danger">' + esc(error.message) + '</td></tr>';
		});
	}

	$('ovPanelUrl').value = location.origin;
	['ovPanelUrl', 'ovPort', 'ovProto'].forEach(function (id) {
		$(id).addEventListener('input', renderInstall);
		$(id).addEventListener('change', renderInstall);
	});

	$('ovSaveEnabled').addEventListener('click', function () {
		post('ovpn.save', { enabled: $('ovEnabled').checked ? '1' : '0' }).then(function (data) {
			say(data.ok ? words.saved : words.failed + ': ' + data.error);
		});
	});

	$('ovCancel').addEventListener('click', resetForm);

	$('ovSaveNode').addEventListener('click', function () {
		var groups = Array.prototype.map.call($('ovGroups').querySelectorAll('input:checked'), function (box) { return box.value; });
		post('ovpn.nodesave', {
			id: $('ovId').value,
			name: $('ovName').value,
			rate: $('ovRate').value,
			sort: $('ovSort').value,
			host_override: $('ovHost').value,
			enabled: $('ovNodeEnabled').checked ? '1' : '0',
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

	$('ovNodes').addEventListener('click', function (event) {
		var button = event.target.closest('button');
		if (!button) { return; }

		if (button.hasAttribute('data-ov-edit')) {
			editNode(Number(button.getAttribute('data-ov-edit')));
		} else if (button.hasAttribute('data-ov-key')) {
			if (!confirm(words.confirmKey)) { return; }
			post('ovpn.nodekey', { id: button.getAttribute('data-ov-key') }).then(function (data) {
				if (!data.ok) { say(words.failed + ': ' + data.error); return; }
				lastKey = { id: data.id, key: data.key };
				renderInstall();
				$('ovInstall').scrollIntoView({ behavior: 'smooth', block: 'center' });
			});
		} else if (button.hasAttribute('data-ov-del')) {
			if (!confirm(words.confirmDel)) { return; }
			post('ovpn.nodedel', { id: button.getAttribute('data-ov-del') }).then(function (data) {
				if (!data.ok) { say(words.failed + ': ' + data.error); return; }
				load();
			});
		}
	});

	$('ovSessionsBox').addEventListener('toggle', function () {
		if (!this.open) { return; }
		get('ovpn.sessions').then(function (data) {
			renderSessions(data.ok ? data.sessions || [] : []);
		});
	});

	load();
})();
</script>
{/literal}
