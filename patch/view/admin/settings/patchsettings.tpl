{literal}
<style>
.pt-card { border: 0; border-radius: 18px; overflow: hidden; }
.pt-head {
	background: linear-gradient(135deg, #4f46e5, #7c3aed 55%, #0ea5e9);
	color: #fff;
	padding: 18px 20px;
}
.pt-head h4 { margin: 0 0 4px; font-size: 17px; font-weight: 800; color: #fff; }
.pt-head p { margin: 0; font-size: 12.5px; color: rgba(255, 255, 255, .85); }
.pt-body { padding: 20px; }

.pt-rows { display: grid; grid-template-columns: repeat(auto-fit, minmax(190px, 1fr)); gap: 11px; }
.pt-row {
	border: 1.5px solid rgba(23, 32, 61, .1);
	border-radius: 14px;
	padding: 12px 14px;
	background: rgba(23, 32, 61, .02);
}
.pt-row-label {
	font-size: 11px;
	font-weight: 700;
	letter-spacing: .4px;
	text-transform: uppercase;
	color: #8c98ab;
	margin-bottom: 5px;
}
.pt-row-value {
	font-size: 15px;
	font-weight: 800;
	color: #16203d;
	direction: ltr;
	unicode-bidi: isolate;
	text-align: start;
	word-break: break-all;
}

.pt-state {
	display: inline-flex;
	align-items: center;
	gap: 7px;
	margin-top: 15px;
	padding: 9px 14px;
	border-radius: 999px;
	font-size: 12.5px;
	font-weight: 800;
}
.pt-state-dot { width: 8px; height: 8px; border-radius: 50%; flex: 0 0 auto; }
.pt-ok    { background: rgba(16, 185, 129, .13); color: #047857; }
.pt-ok    .pt-state-dot { background: #10b981; }
.pt-new   { background: rgba(245, 158, 11, .15); color: #b45309; }
.pt-new   .pt-state-dot { background: #f59e0b; }
.pt-error { background: rgba(239, 68, 68, .13); color: #b91c1c; }
.pt-error .pt-state-dot { background: #ef4444; }
.pt-busy  { background: rgba(99, 102, 241, .13); color: #4338ca; }
.pt-busy  .pt-state-dot { background: #6366f1; animation: ptBlink 1s ease-in-out infinite; }
@keyframes ptBlink { 0%, 100% { opacity: 1; } 50% { opacity: .3; } }

.pt-actions { display: flex; flex-wrap: wrap; gap: 9px; margin-top: 16px; }
.pt-btn {
	display: inline-flex;
	align-items: center;
	gap: 7px;
	border: 0;
	border-radius: 13px;
	padding: 11px 18px;
	font-size: 13px;
	font-weight: 800;
	cursor: pointer;
	transition: transform .14s ease, box-shadow .14s ease, opacity .14s ease;
}
.pt-btn:disabled { opacity: .5; cursor: not-allowed; }
.pt-btn:not(:disabled):active { transform: scale(.97); }
.pt-btn-check { color: #4338ca; background: rgba(99, 102, 241, .14); }
.pt-btn-apply {
	color: #fff;
	background: linear-gradient(135deg, #059669, #10b981);
	box-shadow: 0 6px 16px rgba(16, 185, 129, .34);
}
.pt-btn-undo { color: #b91c1c; background: rgba(239, 68, 68, .12); }

.pt-notes {
	margin-top: 15px;
	border-radius: 14px;
	padding: 13px 15px;
	background: rgba(99, 102, 241, .07);
	border: 1px dashed rgba(99, 102, 241, .3);
	font-size: 12.5px;
	line-height: 1.9;
	color: #3b4a6b;
	white-space: pre-wrap;
}
.pt-log {
	margin-top: 14px;
	border-radius: 13px;
	background: #0f172a;
	color: #cbd5e1;
	padding: 13px 15px;
	font-family: monospace;
	font-size: 11.5px;
	line-height: 1.8;
	direction: ltr;
	text-align: left;
	max-height: 220px;
	overflow: auto;
	white-space: pre-wrap;
	word-break: break-word;
}
.pt-log:empty { display: none; }

html[data-hs-theme="dark"] .pt-row { background: rgba(255, 255, 255, .04); border-color: rgba(255, 255, 255, .1); }
html[data-hs-theme="dark"] .pt-row-value { color: #e7eaf3; }
html[data-hs-theme="dark"] .pt-notes { color: #b9c2d4; background: rgba(99, 102, 241, .12); }
</style>
{/literal}

<div id="PatchSettings" class="card pt-card shadow-lg rounded mb-4">
	<div class="pt-head">
		<h4>🩹 {$translate->get('PatchTitle')}</h4>
		<p>{$translate->get('PatchIntro')}</p>
	</div>

	<div class="pt-body">
		<div class="pt-rows">
			<div class="pt-row">
				<div class="pt-row-label">{$translate->get('PatchInstalled')}</div>
				<div class="pt-row-value" id="ptInstalled">—</div>
			</div>
			<div class="pt-row">
				<div class="pt-row-label">{$translate->get('PatchLatest')}</div>
				<div class="pt-row-value" id="ptLatest">—</div>
			</div>
			<div class="pt-row">
				<div class="pt-row-label">{$translate->get('PatchSource')}</div>
				<div class="pt-row-value" id="ptRepo">—</div>
			</div>
		</div>

		<div class="pt-state pt-busy" id="ptState">
			<i class="pt-state-dot"></i>
			<span id="ptStateText">{$translate->get('PatchChecking')}</span>
		</div>

		<div class="pt-notes" id="ptNotes" hidden></div>

		<div class="pt-actions">
			<button type="button" class="pt-btn pt-btn-check" id="ptCheck">🔄 {$translate->get('PatchCheck')}</button>
			<button type="button" class="pt-btn pt-btn-apply" id="ptApply" disabled>⬇️ {$translate->get('PatchApply')}</button>
			<button type="button" class="pt-btn pt-btn-undo" id="ptUndo">↩️ {$translate->get('PatchRollback')}</button>
		</div>

		<div class="pt-log" id="ptLog"></div>
	</div>
</div>

<script>
	/* new Object(), not a brace literal: Smarty would read {} as a tag */
	window.PatchWords = new Object();
	window.PatchWords.upToDate   = "{$translate->get('PatchUpToDate')|escape:'javascript'}";
	window.PatchWords.available  = "{$translate->get('PatchAvailable')|escape:'javascript'}";
	window.PatchWords.checking   = "{$translate->get('PatchChecking')|escape:'javascript'}";
	window.PatchWords.applying   = "{$translate->get('PatchApplying')|escape:'javascript'}";
	window.PatchWords.applied    = "{$translate->get('PatchApplied')|escape:'javascript'}";
	window.PatchWords.rolledBack = "{$translate->get('PatchRolledBack')|escape:'javascript'}";
	window.PatchWords.confirm    = "{$translate->get('PatchConfirm')|escape:'javascript'}";
	window.PatchWords.undoAsk    = "{$translate->get('PatchRollbackConfirm')|escape:'javascript'}";
	window.PatchWords.never      = "{$translate->get('PatchNever')|escape:'javascript'}";
</script>

{literal}
<script>
(function () {
	var endpoint = '/xmplus-patch.php';
	var token = '';

	var el = function (id) { return document.getElementById(id); };
	var state = el('ptState');
	var stateText = el('ptStateText');
	var log = el('ptLog');
	var apply = el('ptApply');

	function say(kind, text) {
		state.className = 'pt-state pt-' + kind;
		stateText.textContent = text;
	}

	function note(line) {
		log.textContent += line + '\n';
		log.scrollTop = log.scrollHeight;
	}

	function call(action, method) {
		var options = { method: method || 'GET', credentials: 'same-origin' };

		if (method === 'POST') {
			var body = new FormData();
			body.append('token', token);
			options.body = body;
		}

		return fetch(endpoint + '?do=' + action, options).then(function (response) {
			return response.json().catch(function () {
				throw new Error('the updater answered with something that is not JSON (HTTP ' + response.status + ')');
			});
		}).then(function (data) {
			if (!data.ok) { throw new Error(data.error || 'unknown error'); }
			return data;
		});
	}

	function check(quiet) {
		say('busy', window.PatchWords.checking);
		apply.disabled = true;

		return call('status').then(function (data) {
			token = data.token || '';

			el('ptInstalled').textContent = data.installed || window.PatchWords.never;
			el('ptLatest').textContent = data.latest;
			el('ptRepo').textContent = data.repo + ' @ ' + data.branch
				+ (data.commit ? ' (' + data.commit + ')' : '');

			var notes = el('ptNotes');
			if (data.notes) {
				notes.textContent = data.notes;
				notes.hidden = false;
			} else {
				notes.hidden = true;
			}

			if (data.uptodate) {
				say('ok', window.PatchWords.upToDate);
				apply.disabled = false;   /* re-applying is harmless and repairs edited files */
			} else {
				say('new', window.PatchWords.available + ' — ' + data.latest);
				apply.disabled = false;
			}
		}).catch(function (error) {
			say('error', error.message);
			if (!quiet) { note('status: ' + error.message); }
		});
	}

	el('ptCheck').addEventListener('click', function () { log.textContent = ''; check(); });

	apply.addEventListener('click', function () {
		if (!window.confirm(window.PatchWords.confirm)) { return; }

		say('busy', window.PatchWords.applying);
		apply.disabled = true;

		call('apply', 'POST').then(function (data) {
			say('ok', window.PatchWords.applied + ' — ' + data.version);
			note('version   ' + data.version);
			note('updated   ' + data.updated + ' file(s)');
			note('unchanged ' + data.unchanged + ' file(s)');
			if (data.migrations && data.migrations.length) {
				note('migrations ' + data.migrations.join(', '));
			}
			if (data.backup) { note('backup    storage/patch/' + data.backup); }
			return check(true);
		}).catch(function (error) {
			say('error', error.message);
			note('apply: ' + error.message);
			apply.disabled = false;
		});
	});

	el('ptUndo').addEventListener('click', function () {
		if (!window.confirm(window.PatchWords.undoAsk)) { return; }

		say('busy', window.PatchWords.applying);

		call('rollback', 'POST').then(function (data) {
			say('ok', window.PatchWords.rolledBack + ' — ' + data.restored);
			note('restored ' + data.restored + ' file(s) from ' + data.from);
			return check(true);
		}).catch(function (error) {
			say('error', error.message);
			note('rollback: ' + error.message);
		});
	});

	check(true);
})();
</script>
{/literal}
