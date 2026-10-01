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
.te-select { min-width: 220px; }
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

	var regionNames = null;
	try {
		regionNames = new Intl.DisplayNames([document.documentElement.lang || 'fa', 'en'], { type: 'region' });
	} catch (error) {
		regionNames = null;
	}

	function countryName(cc) {
		if (!cc) { return ''; }
		try {
			return regionNames ? regionNames.of(cc.toUpperCase()) : cc.toUpperCase();
		} catch (error) {
			return cc.toUpperCase();
		}
	}

	function flag(cc) {
		if (!/^[a-z]{2}$/.test(cc || '')) { return '🏳️'; }
		return String.fromCodePoint(0x1F1E6 + cc.charCodeAt(0) - 97, 0x1F1E6 + cc.charCodeAt(1) - 97);
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
				: (report.busy_code === 'starting' ? words.stStarting + ' ' + flag(report.busy_cc) + ' ' + countryName(report.busy_cc) : report.busy);
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
			line = '<span class="te-flag">' + flag(exit.cc) + '</span><b>' + esc(countryName(exit.cc)) + '</b>';
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
				+ esc(words.pending) + ' ' + flag(report.pending) + ' ' + esc(countryName(report.pending))
				+ (pendingText ? ' · ' + esc(pendingText) : '') + '</small>');
			if (report.pending_detail) {
				lines.push('<small class="te-wrap text-muted" dir="ltr">' + esc(report.pending_detail) + '</small>');
			}
		}
		return lines.join('<br>');
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
		(list || FALLBACK.map(function (cc) { return [cc, null]; })).forEach(function (item) {
			var cc = String(item[0] || '').toLowerCase();
			if (!/^[a-z]{2}$/.test(cc) || seen[cc]) { return; }
			seen[cc] = true;
			options.push('<option value="' + cc + '"' + (current === cc ? ' selected' : '') + '>' + flag(cc) + ' '
				+ esc(countryName(cc)) + (item[1] != null ? ' — ' + Number(item[1]) + ' ' + esc(words.exits) : '') + '</option>');
		});
		// a choice no longer in the node's list stays visible
		if (current.length === 2 && !seen[current]) {
			options.push('<option value="' + current + '" selected>' + flag(current) + ' ' + esc(countryName(current)) + '</option>');
		}
		var note = list ? '' : '<br><small class="text-muted te-wrap">' + esc(words.noList) + '</small>';
		return '<select class="form-select form-select-sm te-select" data-te-select="' + server.id + '"'
			+ (server.report ? '' : ' disabled') + '>' + options.join('') + '</select>' + note;
	}

	function render(now) {
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
				+ (server.report ? '' : ' disabled') + '>💾 ' + esc(words.save) + '</button></td>'
				+ '</tr>';
		}).join('');
	}

	function load() {
		get('torexit.admin').then(function (data) {
			if (!data.ok) {
				$('teRows').innerHTML = '<tr><td colspan="5" class="text-danger">' + esc(words.failed + ': ' + data.error) + '</td></tr>';
				return;
			}
			token = data.token;
			servers = data.servers || [];
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

	// a choice not saved yet must not be wiped by the automatic refresh
	var dirty = false;
	$('teRows').addEventListener('change', function (event) {
		if (event.target.matches('select[data-te-select]')) { dirty = true; }
	});

	$('teReload').addEventListener('click', function () { dirty = false; load(); });

	load();
	// the agents report every minute; keep the page roughly in step
	setInterval(function () {
		if (!document.hidden && !dirty) { load(); }
	}, 60000);
})();
</script>
{/literal}
