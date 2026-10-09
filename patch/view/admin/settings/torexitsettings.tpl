{*
  Exit location per Xray server - admin side.
  Included by admin/servers/index.tpl; talks to /xmplus-patch.php?do=torexit.*
  (app/Patch/TorExit.php). The panel only stores the choice: the Xray agent on
  the node (digitsell-xray 1.2.0+) asks for it every minute, installs tor-geo
  when needed, starts a Tor client for the country and switches the server
  over once that client works.
*}
<div class="card card-shadow shadow-lg rounded mb-3 mb-lg-5" id="TorExitSettings">
	<div class="card-header card-header-content-between flex-wrap gap-2">
		<h4 class="card-header-title">🌍 {$translate->get('TorExitTitle')}</h4>
		<button type="button" class="btn btn-outline-secondary btn-sm" id="teReload">🔄 {$translate->get('TorExitReload')}</button>
	</div>
	<div class="card-body">
		<div id="teAlerts"></div>
		<p class="text-muted small">{$translate->get('TorExitIntro')}</p>
		<div class="table-responsive">
			<table class="table table-sm te-table">
				<thead><tr>
					<th>{$translate->get('TorExitServer')}</th>
					<th>{$translate->get('TorExitAgent')}</th>
					<th>{$translate->get('TorExitNow')}</th>
					<th>{$translate->get('TorExitChoose')}</th>
					<th></th>
				</tr></thead>
				<tbody id="teRows"><tr><td colspan="5" class="text-muted">…</td></tr></tbody>
			</table>
		</div>
		<p class="small text-muted mb-1">⏱ {$translate->get('TorExitNoteRestart')}</p>
		<p class="small text-muted mb-1">📡 {$translate->get('TorExitNoteTcp')}</p>
		<p class="small text-muted mb-0">🧩 {$translate->get('TorExitNoteAgent')}</p>
	</div>
</div>
<script>
	/* new Object(), not a brace literal: Smarty would read the brace as a tag */
	window.TorExitWords = new Object();
	window.TorExitWords.saved      = "{$translate->get('TorExitSaved')|escape:'javascript'}";
	window.TorExitWords.failed     = "{$translate->get('TorExitFailed')|escape:'javascript'}";
	window.TorExitWords.none       = "{$translate->get('TorExitNone')|escape:'javascript'}";
	window.TorExitWords.agentFile  = "{$translate->get('TorExitAgentFile')|escape:'javascript'}";
	window.TorExitWords.direct     = "{$translate->get('TorExitDirect')|escape:'javascript'}";
	window.TorExitWords.exits      = "{$translate->get('TorExitExits')|escape:'javascript'}";
	window.TorExitWords.save       = "{$translate->get('Save')|escape:'javascript'}";
	window.TorExitWords.live       = "{$translate->get('TorExitLive')|escape:'javascript'}";
	window.TorExitWords.stale      = "{$translate->get('TorExitStale')|escape:'javascript'}";
	window.TorExitWords.never      = "{$translate->get('TorExitNever')|escape:'javascript'}";
	window.TorExitWords.noTorGeo   = "{$translate->get('TorExitNoTorGeo')|escape:'javascript'}";
	window.TorExitWords.fromPanel  = "{$translate->get('TorExitFromPanel')|escape:'javascript'}";
	window.TorExitWords.fromFile   = "{$translate->get('TorExitFromFile')|escape:'javascript'}";
	window.TorExitWords.serverIp   = "{$translate->get('TorExitServerIp')|escape:'javascript'}";
	window.TorExitWords.pending    = "{$translate->get('TorExitPending')|escape:'javascript'}";
	window.TorExitWords.working    = "{$translate->get('TorExitWorking')|escape:'javascript'}";
	window.TorExitWords.notWorking = "{$translate->get('TorExitNotWorking')|escape:'javascript'}";
	window.TorExitWords.ago        = "{$translate->get('TorExitAgo')|escape:'javascript'}";
	window.TorExitWords.noList     = "{$translate->get('TorExitNoList')|escape:'javascript'}";
	window.TorExitWords.confirm    = "{$translate->get('TorExitConfirm')|escape:'javascript'}";
	window.TorExitWords.proxy      = "{$translate->get('TorExitProxy')|escape:'javascript'}";
	window.TorExitWords.stInstalling   = "{$translate->get('TorExitStInstalling')|escape:'javascript'}";
	window.TorExitWords.stInstallWait  = "{$translate->get('TorExitStInstallWait')|escape:'javascript'}";
	window.TorExitWords.stInstallFailed = "{$translate->get('TorExitStInstallFailed')|escape:'javascript'}";
	window.TorExitWords.stStarting     = "{$translate->get('TorExitStStarting')|escape:'javascript'}";
	window.TorExitWords.stStartWait    = "{$translate->get('TorExitStStartWait')|escape:'javascript'}";
	window.TorExitWords.stStartFailed  = "{$translate->get('TorExitStStartFailed')|escape:'javascript'}";
	window.TorExitWords.stConnecting   = "{$translate->get('TorExitStConnecting')|escape:'javascript'}";
	window.TorExitWords.etaLeft    = "{$translate->get('TorExitEtaLeft')|escape:'javascript'}";
	window.TorExitWords.etaOver    = "{$translate->get('TorExitEtaOver')|escape:'javascript'}";
	window.TorExitWords.applying   = "{$translate->get('TorExitApplying')|escape:'javascript'}";
	window.TorExitWords.okMsg      = "{$translate->get('TorExitOkMsg')|escape:'javascript'}";
	window.TorExitWords.failMsg    = "{$translate->get('TorExitFailMsg')|escape:'javascript'}";
	window.TorExitWords.timeoutMsg = "{$translate->get('TorExitTimeoutMsg')|escape:'javascript'}";
	window.TorExitWords.dismiss    = "{$translate->get('TorExitDismiss')|escape:'javascript'}";
	window.TorExitWords.search     = "{$translate->get('TorExitSearch')|escape:'javascript'}";
	window.TorExitWords.nodeOff    = "{$translate->get('TorExitNodeOff')|escape:'javascript'}";
	window.TorExitWords.rotate        = "{$translate->get('TorExitRotate')|escape:'javascript'}";
	window.TorExitWords.rotateConfirm = "{$translate->get('TorExitRotateConfirm')|escape:'javascript'}";
	window.TorExitWords.rotating      = "{$translate->get('TorExitRotating')|escape:'javascript'}";
	window.TorExitWords.rotOkMsg      = "{$translate->get('TorExitRotOkMsg')|escape:'javascript'}";
	window.TorExitWords.rotSameMsg    = "{$translate->get('TorExitRotSameMsg')|escape:'javascript'}";
	window.TorExitWords.rotFailMsg    = "{$translate->get('TorExitRotFailMsg')|escape:'javascript'}";
	window.TorExitWords.rotTimeout    = "{$translate->get('TorExitRotTimeout')|escape:'javascript'}";
	window.TorExitWords.rotOldAgent   = "{$translate->get('TorExitRotOldAgent')|escape:'javascript'}";
	window.TorExitWords.rotAsked      = "{$translate->get('TorExitRotAsked')|escape:'javascript'}";
</script>
{literal}
<style>
.te-table td, .te-table th { vertical-align: middle; }
.te-table td { white-space: nowrap; }
.te-table .te-wrap { white-space: normal; min-width: 180px; max-width: 340px; display: inline-block; }
.te-dot { display: inline-block; width: 9px; height: 9px; border-radius: 50%; margin-inline-end: 5px; background: #94a3b8; }
.te-dot.is-live { background: #10b981; }
.te-dot.is-down { background: #f43f5e; }
.te-flag { font-size: 1.15em; margin-inline-end: 4px; }
.te-select { min-width: 240px; }
.te-filter { min-width: 240px; margin-bottom: 4px; }
.te-flagimg { width: 20px; height: 15px; object-fit: cover; border-radius: 2px; margin-inline-end: 5px; vertical-align: -2px; }
.te-op { white-space: normal; min-width: 200px; margin-top: 6px; padding: 6px 8px; border-radius: 8px; background: rgba(99,102,241,.08); }
.te-op .progress { height: 5px; margin: 4px 0; }
.te-hourglass { display: inline-block; animation: te-flip 2s ease-in-out infinite; }
@keyframes te-flip { 0%, 45% { transform: rotate(0); } 55%, 100% { transform: rotate(180deg); } }
.te-eta { font-variant-numeric: tabular-nums; direction: ltr; unicode-bidi: embed; }
</style>
<script>
(function () {
	var endpoint = '/xmplus-patch.php';
	var words = window.TorExitWords || {};
	var token = '';
	var servers = [];
	// shown when a node has not sent its list yet: the countries with the most exits
	var FALLBACK = ['de', 'nl', 'us', 'fr', 'se', 'ch', 'fi', 'at', 'gb', 'ro', 'lu', 'no', 'ca', 'pl', 'sg', 'jp'];

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

	var IS_WIN = /Win/i.test(navigator.platform || navigator.userAgent || '');
	// <html lang="en_US"> is not a valid language tag and made Intl throw, so the names fell back to two letters
	var faNames = null, enNames = null;
	try { faNames = new Intl.DisplayNames(['fa'], { type: 'region' }); } catch (error) { faNames = null; }
	try { enNames = new Intl.DisplayNames(['en'], { type: 'region' }); } catch (error) { enNames = null; }

	function nameIn(source, cc) {
		try {
			var name = source ? source.of(cc.toUpperCase()) : '';
			return name && name.toUpperCase() !== cc.toUpperCase() ? name : '';
		} catch (error) {
			return '';
		}
	}

	// full name, Persian and English, so a country can be found in either
	function countryName(cc) {
		if (!cc) { return ''; }
		var fa = nameIn(faNames, cc), en = nameIn(enNames, cc);
		if (fa && en && fa !== en) { return fa + ' (' + en + ')'; }
		return fa || en || cc.toUpperCase();
	}

	// Windows draws flag emoji as two letters; use it only where it is a flag
	function flag(cc) {
		if (IS_WIN || !/^[a-z]{2}$/.test(cc || '')) { return ''; }
		return String.fromCodePoint(0x1F1E6 + cc.charCodeAt(0) - 97, 0x1F1E6 + cc.charCodeAt(1) - 97) + ' ';
	}

	function flagImg(cc) {
		if (!/^[a-z]{2}$/.test(cc || '')) { return ''; }
		return '<img class="te-flagimg" alt="" src="https://flagcdn.com/w40/' + cc + '.png" onerror="this.style.display=\'none\'">';
	}

	function ago(seconds) {
		seconds = Math.max(0, Math.round(seconds));
		if (seconds < 90) { return seconds + 's'; }
		if (seconds < 5400) { return Math.round(seconds / 60) + 'm'; }
		if (seconds < 172800) { return Math.round(seconds / 3600) + 'h'; }
		return Math.round(seconds / 86400) + 'd';
	}

	function get(action) {
		return fetch(endpoint + '?do=' + action + '&_=' + Date.now(), { credentials: 'same-origin', cache: 'no-store' })
			.then(function (r) { return r.json(); });
	}

	function post(action, fields) {
		var body = new FormData();
		body.append('token', token);
		Object.keys(fields).forEach(function (name) { body.append(name, fields[name]); });
		return fetch(endpoint + '?do=' + action, { method: 'POST', credentials: 'same-origin', body: body })
			.then(function (r) { return r.json(); });
	}

	function agentCell(server, now) {
		var report = server.report;
		if (!report || !server.seen_at) {
			return '<span class="te-dot"></span>' + esc(words.never);
		}
		var head = server.live
			? '<span class="te-dot is-live"></span>' + esc(words.live)
			: '<span class="te-dot is-down"></span>' + esc(words.stale) + ' · ' + esc(ago(now - server.seen_at)) + ' ' + esc(words.ago);
		var parts = ['<small class="text-muted" dir="ltr">agent ' + esc(report.agent || '?')
			+ (report.host ? ' · ' + esc(report.host) : '') + '</small>'];
		parts.push('<small class="text-muted">' + (report.torgeo ? 'tor-geo ' + esc(report.torgeo) : esc(words.noTorGeo)) + '</small>');
		if (report.busy) {
			var busy = report.busy_code === 'installing' ? words.stInstalling
				: (report.busy_code === 'starting' ? words.stStarting + ' ' + countryName(report.busy_cc) : report.busy);
			parts.push('<small class="text-primary">⏳ ' + esc(busy) + '</small>');
		}
		if (report.error) {
			parts.push('<small class="te-wrap text-danger">⚠️ ' + esc(report.error) + '</small>');
		}
		return head + '<br>' + parts.join('<br>');
	}

	function exitCell(server) {
		var report = server.report;
		if (!report || !report.exit) { return '—'; }
		var exit = report.exit;
		var line;
		if (exit.mode === 'tor' && exit.cc) {
			line = flagImg(exit.cc) + '<b>' + esc(countryName(exit.cc)) + '</b>';
		} else if (exit.mode === 'proxy') {
			line = '🔀 <b>' + esc(words.proxy) + '</b>';
		} else {
			line = '🏠 <b>' + esc(words.direct) + '</b>';
		}
		var source = exit.source === 'panel' ? words.fromPanel : (exit.source === 'agent.json' ? words.fromFile : '');
		if (source) { line += ' <small class="text-muted">(' + esc(source) + ')</small>'; }
		var lines = [line];
		if (exit.ip) {
			lines.push('<small dir="ltr" class="' + (exit.ok === false ? 'text-danger' : 'text-success') + '">'
				+ (exit.mode === 'direct' ? esc(words.serverIp) + ' ' : '') + esc(exit.ip) + '</small>');
		} else if (exit.ok === false) {
			lines.push('<small class="text-danger">' + esc(words.notWorking) + '</small>');
		}
		if (exit.error) {
			lines.push('<small class="te-wrap text-danger">⚠️ ' + esc(exit.error) + '</small>');
		}
		if (report.pending) {
			var stateWords = {
				installing: words.stInstalling, install_wait: words.stInstallWait, install_failed: words.stInstallFailed,
				starting: words.stStarting, start_wait: words.stStartWait, start_failed: words.stStartFailed,
				connecting: words.stConnecting
			};
			var pendingText = stateWords[report.pending_code] || report.pending_state || '';
			var failed = report.pending_code === 'install_failed' || report.pending_code === 'start_failed';
			lines.push('<small class="te-wrap ' + (failed ? 'text-danger' : 'text-primary') + '">' + (failed ? '⚠️ ' : '⏳ ')
				+ esc(words.pending) + ' ' + esc(countryName(report.pending))
				+ (pendingText ? ' · ' + esc(pendingText) : '') + '</small>');
			if (report.pending_detail) {
				lines.push('<small class="te-wrap text-muted" dir="ltr">' + esc(report.pending_detail) + '</small>');
			}
		}
		return lines.join('<br>') + opCell(server) + rotCell(server);
	}

	function selectCell(server) {
		var report = server.report || {};
		var list = Array.isArray(report.countries) && report.countries.length ? report.countries : null;
		var current = !server.managed ? 'agent' : (server.want || 'direct');
		var options = [
			'<option value="agent"' + (current === 'agent' ? ' selected' : '') + '>⚙️ ' + esc(words.agentFile) + '</option>',
			'<option value="direct"' + (current === 'direct' ? ' selected' : '') + '>🏠 ' + esc(words.direct) + '</option>'
		];
		var seen = {};
		var items = [];
		(list || FALLBACK.map(function (cc) { return [cc, null]; })).forEach(function (item) {
			var cc = String(item[0] || '').toLowerCase();
			if (!/^[a-z]{2}$/.test(cc) || seen[cc]) { return; }
			seen[cc] = true;
			items.push({ cc: cc, name: countryName(cc), count: item[1] });
		});
		items.sort(function (a, b) { return a.name.localeCompare(b.name, 'fa'); });
		items.forEach(function (item) {
			options.push('<option value="' + item.cc + '"' + (current === item.cc ? ' selected' : '') + '>' + esc(flag(item.cc) + item.name)
				+ (item.count != null ? ' — ' + Number(item.count) + ' ' + esc(words.exits) : '') + '</option>');
		});
		// a choice no longer in the node's list stays visible
		if (current.length === 2 && !seen[current]) {
			options.push('<option value="' + current + '" selected>' + esc(flag(current) + countryName(current)) + '</option>');
		}
		var note = list ? '' : '<br><small class="text-muted te-wrap">' + esc(words.noList) + '</small>';
		var filter = server.report ? '<input type="search" class="form-control form-control-sm te-filter" data-te-filter="' + server.id
			+ '" placeholder="🔍 ' + esc(words.search) + '"><br>' : '';
		return filter + '<select class="form-select form-select-sm te-select" data-te-select="' + server.id + '"'
			+ (server.report ? '' : ' disabled') + '>' + options.join('') + '</select>' + note;
	}

	// ---- a choice being carried out: live countdown, then a success or failure message ----
	var clockOffset = 0;          // server time minus browser time, seconds
	var lastNow = 0;
	var running = false;
	var seenRunning = {};
	var ACK = 'teAck:';

	function ackKey(server) { return ACK + server.id + ':' + server.want_at; }
	function isAcked(server) { try { return localStorage.getItem(ackKey(server)) === '1'; } catch (e) { return false; } }
	function setAcked(server) { try { localStorage.setItem(ackKey(server), '1'); } catch (e) { /* private mode */ } }

	function clock(seconds) {
		seconds = Math.max(0, Math.round(seconds));
		var m = Math.floor(seconds / 60), s = seconds % 60;
		return (m < 10 ? '0' : '') + m + ':' + (s < 10 ? '0' : '') + s;
	}

	function stageText(report) {
		var map = {
			installing: words.stInstalling, install_wait: words.stInstallWait, install_failed: words.stInstallFailed,
			starting: words.stStarting, start_wait: words.stStartWait, start_failed: words.stStartFailed,
			connecting: words.stConnecting
		};
		return (report && (map[report.pending_code] || report.pending_state)) || words.applying;
	}

	// kind: run | ok | fail | null (nothing chosen from the panel)
	function opState(server, now) {
		if (!server.managed || !server.want_at) { return null; }
		var target = server.want || 'direct';
		var report = server.report || {};
		var exit = report.exit || {};
		var elapsed = now - server.want_at;
		var eta = report.torgeo ? 240 : 600;
		var maxWait = report.torgeo ? 900 : 1500;
		var matches = target === 'direct' ? exit.mode === 'direct' : (exit.mode === 'tor' && exit.cc === target);
		var fresh = server.seen_at >= server.want_at;
		var state = { target: target, elapsed: elapsed, eta: eta, report: report, exit: exit };
		if (matches && fresh && exit.ok !== false && !report.pending) { state.kind = 'ok'; return state; }
		if (/_failed$/.test(report.pending_code || '') && report.pending === target) {
			state.kind = 'fail';
			state.reason = stageText(report) + (report.pending_detail ? ' · ' + report.pending_detail : '');
			return state;
		}
		if (elapsed > maxWait) {
			state.kind = 'fail';
			state.reason = words.timeoutMsg.replace('%min%', Math.round(maxWait / 60)) + (report.error ? ' · ' + report.error : '')
				+ (exit.error ? ' · ' + exit.error : '');
			return state;
		}
		state.kind = 'run';
		return state;
	}

	function serverById(id) {
		return servers.filter(function (s) { return String(s.id) === String(id); })[0];
	}

	function versionBelow(version, wanted) {
		var a = String(version || '0').split('.'), b = wanted.split('.');
		for (var i = 0; i < 3; i++) {
			var x = parseInt(a[i], 10) || 0, y = parseInt(b[i], 10) || 0;
			if (x !== y) { return x < y; }
		}
		return false;
	}

	function rotAckKey(server) { return 'teAckR:' + server.id + ':' + server.rotate_at; }
	function rotAcked(server) { try { return localStorage.getItem(rotAckKey(server)) === '1'; } catch (e) { return false; } }
	function setRotAcked(server) { try { localStorage.setItem(rotAckKey(server), '1'); } catch (e) { /* private mode */ } }

	// a new exit IP asked for: run | ok | fail | null
	function rotState(server, now) {
		if (!server.rotate_at) { return null; }
		var report = server.report || {};
		var rotate = report.rotate || null;
		var elapsed = now - server.rotate_at;
		var state = { elapsed: elapsed, eta: 120, rotate: rotate };
		if (report.agent && versionBelow(report.agent, '1.3.0')) {
			state.kind = 'fail';
			state.reason = words.rotOldAgent;
			return state;
		}
		if (rotate && rotate.at === server.rotate_at) {
			if (rotate.state === 'done') { state.kind = 'ok'; return state; }
			if (rotate.state === 'failed') { state.kind = 'fail'; state.reason = rotate.error || ''; return state; }
		}
		if (elapsed > 420) {
			state.kind = 'fail';
			state.reason = words.rotTimeout;
			return state;
		}
		state.kind = 'run';
		return state;
	}

	function rotCell(server) {
		var state = rotState(server, lastNow);
		if (!state || state.kind !== 'run') { return ''; }
		return '<div class="te-op" data-te-op-rot="' + server.id + '">'
			+ '<span class="te-hourglass">⏳</span> <b>' + esc(words.rotating) + '</b> '
			+ '<span class="te-eta" data-te-eta-rot="' + server.id + '"></span>'
			+ '<div class="progress"><div class="progress-bar" data-te-bar-rot="' + server.id + '" style="width:3%"></div></div>'
			+ (server.live ? '' : '<small class="text-danger">⚠️ ' + esc(words.nodeOff) + '</small>') + '</div>';
	}

	function opCell(server) {
		var state = opState(server, lastNow);
		if (!state || state.kind !== 'run') { return ''; }
		var html = '<div class="te-op" data-te-op="' + server.id + '">'
			+ '<span class="te-hourglass">⏳</span> <b>' + esc(words.applying) + '</b> '
			+ '<span class="te-eta" data-te-eta="' + server.id + '"></span>'
			+ '<div class="progress"><div class="progress-bar" data-te-bar="' + server.id + '" style="width:3%"></div></div>'
			+ '<small class="text-muted">' + esc(stageText(state.report)) + '</small>';
		if (!server.live) {
			html += '<br><small class="text-danger">⚠️ ' + esc(words.nodeOff) + '</small>';
		}
		return html + '</div>';
	}

	function tick() {
		var now = Date.now() / 1000 + clockOffset;
		tickRotations(now);
		var nodes = document.querySelectorAll('[data-te-eta]');
		Array.prototype.forEach.call(nodes, function (node) {
			var id = node.getAttribute('data-te-eta');
			var server = serverById(id);
			if (!server) { return; }
			var state = opState(server, now);
			if (!state || state.kind !== 'run') { return; }
			var left = state.eta - state.elapsed;
			node.textContent = left > 0 ? clock(left) + ' ' + words.etaLeft : '+' + clock(-left) + ' ' + words.etaOver;
			var bar = document.querySelector('[data-te-bar="' + id + '"]');
			if (bar) { bar.style.width = Math.max(3, Math.min(95, state.elapsed / state.eta * 100)) + '%'; }
		});
	}

	function tickRotations(now) {
		Array.prototype.forEach.call(document.querySelectorAll('[data-te-eta-rot]'), function (node) {
			var id = node.getAttribute('data-te-eta-rot');
			var server = serverById(id);
			var state = server && rotState(server, now);
			if (!state || state.kind !== 'run') { return; }
			var left = state.eta - state.elapsed;
			node.textContent = left > 0 ? clock(left) + ' ' + words.etaLeft : '+' + clock(-left) + ' ' + words.etaOver;
			var bar = document.querySelector('[data-te-bar-rot="' + id + '"]');
			if (bar) { bar.style.width = Math.max(3, Math.min(95, state.elapsed / state.eta * 100)) + '%'; }
		});
	}

	function describeExit(state) {
		if (state.target === 'direct') { return words.direct; }
		return countryName(state.target);
	}

	function alertsHtml(now) {
		var out = [];
		servers.forEach(function (server) {
			var rot = rotState(server, now);
			if (rot) {
				var rkey = server.id + ':r' + server.rotate_at;
				if (rot.kind === 'run') { seenRunning[rkey] = true; }
				else if (!rotAcked(server) && rot.elapsed <= 21600) {
					var good = rot.kind === 'ok';
					var info = rot.rotate || {};
					var same = good && info.old_ip && info.old_ip === info.new_ip;
					var rtext = (good ? (same ? words.rotSameMsg : words.rotOkMsg) : words.rotFailMsg)
						.replace('%server%', server.name).replace('%ip%', info.new_ip || '').replace('%old%', info.old_ip || '-')
						.replace('%reason%', rot.reason || '').replace('%time%', clock(rot.elapsed));
					if (seenRunning[rkey] && !seenRunning[rkey + ':told']) {
						seenRunning[rkey + ':told'] = true;
						say((good ? (same ? '⚠️ ' : '✅ ') : '❌ ') + rtext);
					}
					out.push('<div class="alert ' + (good ? (same ? 'alert-warning' : 'alert-success') : 'alert-danger')
						+ ' d-flex justify-content-between align-items-start py-2 mb-2" role="alert"><span>'
						+ (good ? (same ? '⚠️ ' : '✅ ') : '❌ ') + esc(rtext) + '</span>'
						+ '<button type="button" class="btn btn-sm btn-outline-secondary ms-2" data-te-ack-rot="' + server.id + '">' + esc(words.dismiss) + '</button></div>');
				}
			}
			var state = opState(server, now);
			if (!state) { return; }
			var key = server.id + ':' + server.want_at;
			if (state.kind === 'run') { seenRunning[key] = true; return; }
			// only recent choices are reported; an old, unacknowledged one would just be noise
			if (isAcked(server) || state.elapsed > 21600) { return; }
			var ok = state.kind === 'ok';
			var text = (ok ? words.okMsg : words.failMsg)
				.replace('%server%', server.name).replace('%exit%', describeExit(state))
				.replace('%ip%', (state.exit && state.exit.ip) || '').replace('%reason%', state.reason || '')
				.replace('%time%', clock(state.elapsed));
			if (seenRunning[key] && !seenRunning[key + ':told']) {
				seenRunning[key + ':told'] = true;
				say((ok ? '✅ ' : '❌ ') + text);
			}
			out.push('<div class="alert ' + (ok ? 'alert-success' : 'alert-danger') + ' d-flex justify-content-between align-items-start py-2 mb-2" role="alert">'
				+ '<span>' + (ok ? '✅ ' : '❌ ') + esc(text) + '</span>'
				+ '<button type="button" class="btn btn-sm btn-outline-secondary ms-2" data-te-ack="' + server.id + '">' + esc(words.dismiss) + '</button></div>');
		});
		return out.join('');
	}

	// only where the server leaves through a Tor exit chosen in the panel
	function rotateButton(server) {
		var report = server.report || {};
		var exit = report.exit || {};
		if (!server.managed || !server.want || exit.mode !== 'tor') { return ''; }
		var state = rotState(server, lastNow);
		return '<br><button type="button" class="btn btn-outline-primary btn-sm mt-1" data-te-rotate="' + server.id + '"'
			+ (state && state.kind === 'run' ? ' disabled' : '') + '>🔄 ' + esc(words.rotate) + '</button>';
	}

	function render(now) {
		lastNow = now;
		running = servers.some(function (server) {
			var state = opState(server, now), rot = rotState(server, now);
			return (state && state.kind === 'run') || (rot && rot.kind === 'run');
		});
		$('teAlerts').innerHTML = alertsHtml(now);
		var body = $('teRows');
		if (!servers.length) {
			body.innerHTML = '<tr><td colspan="5" class="text-muted">' + esc(words.none) + '</td></tr>';
			return;
		}
		body.innerHTML = servers.map(function (server) {
			return '<tr>'
				+ '<td><b>' + esc(server.name) + '</b> <small class="text-muted" dir="ltr">#' + server.id
				+ (server.type ? ' · ' + esc(server.type) : '') + '</small></td>'
				+ '<td>' + agentCell(server, now) + '</td>'
				+ '<td>' + exitCell(server) + '</td>'
				+ '<td>' + selectCell(server) + '</td>'
				+ '<td><button type="button" class="btn btn-primary btn-sm" data-te-save="' + server.id + '"'
				+ (server.report ? '' : ' disabled') + '>💾 ' + esc(words.save) + '</button>' + rotateButton(server) + '</td>'
				+ '</tr>';
		}).join('');
		tick();
	}

	function load() {
		get('torexit.admin').then(function (data) {
			if (!data.ok) {
				$('teRows').innerHTML = '<tr><td colspan="5" class="text-danger">' + esc(words.failed + ': ' + data.error) + '</td></tr>';
				return;
			}
			token = data.token;
			servers = data.servers || [];
			clockOffset = data.now - Date.now() / 1000;
			render(data.now);
		}).catch(function () {
			$('teRows').innerHTML = '<tr><td colspan="5" class="text-danger">' + esc(words.failed) + '</td></tr>';
		});
	}

	$('teRows').addEventListener('click', function (event) {
		var button = event.target.closest('button[data-te-save]');
		if (!button) { return; }
		var id = button.getAttribute('data-te-save');
		var select = document.querySelector('select[data-te-select="' + id + '"]');
		if (!select) { return; }
		var server = servers.filter(function (s) { return String(s.id) === String(id); })[0];
		var label = select.options[select.selectedIndex].text;
		if (!confirm(words.confirm.replace('%server%', server ? server.name : '#' + id).replace('%exit%', label))) { return; }
		button.disabled = true;
		post('torexit.save', { id: id, want: select.value }).then(function (data) {
			button.disabled = false;
			if (!data.ok) { say(words.failed + ': ' + data.error); return; }
			say(words.saved);
			dirty = false;
			load();
		}).catch(function () {
			button.disabled = false;
			say(words.failed);
		});
	});

	$('teRows').addEventListener('click', function (event) {
		var button = event.target.closest('button[data-te-rotate]');
		if (!button) { return; }
		var id = button.getAttribute('data-te-rotate');
		var server = serverById(id);
		if (!confirm(words.rotateConfirm.replace('%server%', server ? server.name : '#' + id))) { return; }
		button.disabled = true;
		post('torexit.rotate', { id: id }).then(function (data) {
			if (!data.ok) { button.disabled = false; say(words.failed + ': ' + data.error); return; }
			say(words.rotAsked);
			load();
		}).catch(function () {
			button.disabled = false;
			say(words.failed);
		});
	});

	// a choice not saved yet must not be wiped by the automatic refresh
	var dirty = false;
	$('teRows').addEventListener('change', function (event) {
		if (event.target.matches('select[data-te-select]')) { dirty = true; }
	});

	$('teAlerts').addEventListener('click', function (event) {
		var rotButton = event.target.closest('button[data-te-ack-rot]');
		if (rotButton) {
			var rotServer = serverById(rotButton.getAttribute('data-te-ack-rot'));
			if (rotServer) { setRotAcked(rotServer); }
			render(lastNow);
			return;
		}
		var button = event.target.closest('button[data-te-ack]');
		if (!button) { return; }
		var server = serverById(button.getAttribute('data-te-ack'));
		if (server) { setAcked(server); }
		render(lastNow);
	});

	$('teRows').addEventListener('input', function (event) {
		var box = event.target.closest('input[data-te-filter]');
		if (!box) { return; }
		var select = document.querySelector('select[data-te-select="' + box.getAttribute('data-te-filter') + '"]');
		if (!select) { return; }
		var needle = box.value.trim().toLowerCase();
		Array.prototype.forEach.call(select.options, function (option) {
			var keep = !needle || option.value.length > 2 || option.selected
				|| option.text.toLowerCase().indexOf(needle) !== -1 || option.value.indexOf(needle) !== -1;
			option.hidden = !keep;
		});
	});

	$('teReload').addEventListener('click', function () { dirty = false; load(); });

	load();
	setInterval(tick, 1000);
	// the agents report every minute; while a change is being carried out look more often
	(function poll() {
		setTimeout(function () {
			if (!document.hidden && !dirty) { load(); }
			poll();
		}, running ? 10000 : 60000);
	})();
})();
</script>
{/literal}
