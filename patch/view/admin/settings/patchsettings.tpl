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
.pt-btn-ghost { color: #56617a; background: rgba(23, 32, 61, .07); }

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

/* ---------------- the working dialog ---------------- */
.pt-veil {
	position: fixed;
	inset: 0;
	z-index: 20050;
	display: flex;
	align-items: center;
	justify-content: center;
	padding: 18px;
	background: rgba(9, 14, 30, .62);
	-webkit-backdrop-filter: blur(4px);
	backdrop-filter: blur(4px);
}
.pt-veil[hidden] { display: none !important; }

.pt-modal {
	width: 100%;
	max-width: 430px;
	border-radius: 20px;
	background: #fff;
	box-shadow: 0 26px 70px rgba(9, 14, 30, .4);
	overflow: hidden;
}
.pt-modal-head {
	padding: 22px 22px 6px;
	text-align: center;
}
.pt-glass {
	font-size: 40px;
	line-height: 1;
	display: inline-block;
	animation: ptTurn 2.4s ease-in-out infinite;
}
@keyframes ptTurn {
	0%, 42%   { transform: rotate(0deg); }
	50%, 92%  { transform: rotate(180deg); }
	100%      { transform: rotate(360deg); }
}
.pt-modal-title {
	margin: 12px 0 4px;
	font-size: 16.5px;
	font-weight: 800;
	color: #16203d;
}
.pt-modal-sub { font-size: 12.5px; color: #7a869f; margin: 0; line-height: 1.9; }

.pt-modal-body { padding: 14px 22px 20px; }

.pt-steps { list-style: none; margin: 14px 0 0; padding: 0; }
.pt-step {
	display: flex;
	align-items: center;
	gap: 9px;
	padding: 7px 0;
	font-size: 12.5px;
	font-weight: 700;
	color: #a3adc0;
	transition: color .2s ease;
}
.pt-step-mark {
	width: 20px;
	height: 20px;
	flex: 0 0 auto;
	border-radius: 50%;
	border: 2px solid rgba(23, 32, 61, .14);
	display: inline-flex;
	align-items: center;
	justify-content: center;
	font-size: 11px;
	color: transparent;
}
.pt-step.is-now { color: #4338ca; }
.pt-step.is-now .pt-step-mark {
	border-color: #6366f1;
	border-top-color: transparent;
	animation: ptSpin .8s linear infinite;
}
@keyframes ptSpin { to { transform: rotate(360deg); } }
.pt-step.is-done { color: #047857; }
.pt-step.is-done .pt-step-mark {
	border-color: #10b981;
	background: #10b981;
	color: #fff;
}
.pt-step.is-done .pt-step-mark::after { content: "\2713"; }

.pt-bar {
	height: 6px;
	border-radius: 999px;
	background: rgba(23, 32, 61, .09);
	overflow: hidden;
	margin-top: 16px;
}
.pt-bar span {
	display: block;
	height: 100%;
	width: 0;
	border-radius: 999px;
	background: linear-gradient(90deg, #6366f1, #0ea5e9);
	transition: width .5s ease;
}

.pt-result { text-align: center; }
.pt-result-emoji { font-size: 42px; line-height: 1; }
.pt-result-lines {
	margin-top: 14px;
	border-radius: 14px;
	background: rgba(23, 32, 61, .04);
	padding: 12px 14px;
	font-size: 12.5px;
	line-height: 2;
	color: #3b4a6b;
	text-align: start;
}
.pt-result-lines b { direction: ltr; unicode-bidi: isolate; }
.pt-modal-foot { display: flex; gap: 9px; justify-content: center; margin-top: 16px; }

html[data-hs-theme="dark"] .pt-row { background: rgba(255, 255, 255, .04); border-color: rgba(255, 255, 255, .1); }
html[data-hs-theme="dark"] .pt-row-value { color: #e7eaf3; }
html[data-hs-theme="dark"] .pt-notes { color: #b9c2d4; background: rgba(99, 102, 241, .12); }
html[data-hs-theme="dark"] .pt-modal { background: #1c2536; }
html[data-hs-theme="dark"] .pt-modal-title { color: #e7eaf3; }
html[data-hs-theme="dark"] .pt-modal-sub { color: #9fb0cc; }
html[data-hs-theme="dark"] .pt-result-lines { background: rgba(255, 255, 255, .06); color: #b9c2d4; }
html[data-hs-theme="dark"] .pt-btn-ghost { color: #cfd8ea; background: rgba(255, 255, 255, .08); }
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

<div class="pt-veil" id="ptVeil" hidden>
	<div class="pt-modal">
		<div class="pt-modal-head">
			<span class="pt-glass" id="ptGlass">⏳</span>
			<h5 class="pt-modal-title" id="ptModalTitle">{$translate->get('PatchApplying')}</h5>
			<p class="pt-modal-sub" id="ptModalSub">{$translate->get('PatchKeepOpen')}</p>
		</div>

		<div class="pt-modal-body">
			<div id="ptProgress">
				<ul class="pt-steps" id="ptSteps">
					<li class="pt-step" data-step="0"><i class="pt-step-mark"></i>{$translate->get('PatchStepConnect')}</li>
					<li class="pt-step" data-step="1"><i class="pt-step-mark"></i>{$translate->get('PatchStepDownload')}</li>
					<li class="pt-step" data-step="2"><i class="pt-step-mark"></i>{$translate->get('PatchStepVerify')}</li>
					<li class="pt-step" data-step="3"><i class="pt-step-mark"></i>{$translate->get('PatchStepWrite')}</li>
					<li class="pt-step" data-step="4"><i class="pt-step-mark"></i>{$translate->get('PatchStepFinish')}</li>
				</ul>
				<div class="pt-bar"><span id="ptBar"></span></div>
			</div>

			<div class="pt-result" id="ptResult" hidden>
				<div class="pt-result-emoji" id="ptResultEmoji">✅</div>
				<div class="pt-result-lines" id="ptResultLines"></div>
			</div>

			<div class="pt-modal-foot" id="ptModalFoot" hidden>
				<button type="button" class="pt-btn pt-btn-apply" id="ptGo">{$translate->get('PatchYes')}</button>
				<button type="button" class="pt-btn pt-btn-ghost" id="ptNo">{$translate->get('PatchNo')}</button>
			</div>
		</div>
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
	window.PatchWords.keepOpen   = "{$translate->get('PatchKeepOpen')|escape:'javascript'}";
	window.PatchWords.confirmT   = "{$translate->get('PatchConfirmTitle')|escape:'javascript'}";
	window.PatchWords.undoTitle  = "{$translate->get('PatchRollbackTitle')|escape:'javascript'}";
	window.PatchWords.rollingOn  = "{$translate->get('PatchRollingBack')|escape:'javascript'}";
	window.PatchWords.doneTitle  = "{$translate->get('PatchDoneTitle')|escape:'javascript'}";
	window.PatchWords.failTitle  = "{$translate->get('PatchFailedTitle')|escape:'javascript'}";
	window.PatchWords.nothing    = "{$translate->get('PatchNothingToDo')|escape:'javascript'}";
	window.PatchWords.lVersion   = "{$translate->get('PatchLineVersion')|escape:'javascript'}";
	window.PatchWords.lUpdated   = "{$translate->get('PatchLineUpdated')|escape:'javascript'}";
	window.PatchWords.lSame      = "{$translate->get('PatchLineSame')|escape:'javascript'}";
	window.PatchWords.lMigration = "{$translate->get('PatchLineMigrations')|escape:'javascript'}";
	window.PatchWords.lBackup    = "{$translate->get('PatchLineBackup')|escape:'javascript'}";
	window.PatchWords.lRestored  = "{$translate->get('PatchLineRestored')|escape:'javascript'}";
	window.PatchWords.close      = "{$translate->get('PatchClose')|escape:'javascript'}";
	window.PatchWords.reload     = "{$translate->get('PatchReload')|escape:'javascript'}";
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

	var veil = el('ptVeil');
	var steps = el('ptSteps').querySelectorAll('.pt-step');
	var bar = el('ptBar');
	var timers = [];

	function say(kind, text) {
		state.className = 'pt-state pt-' + kind;
		stateText.textContent = text;
	}

	function note(line) {
		log.textContent += line + '\n';
		log.scrollTop = log.scrollHeight;
	}

	/* ---------------- the dialog ---------------- */

	function openVeil(title, sub) {
		el('ptModalTitle').textContent = title;
		el('ptModalSub').textContent = sub || '';
		el('ptGlass').textContent = '⏳';
		el('ptProgress').hidden = true;
		el('ptResult').hidden = true;
		el('ptModalFoot').hidden = true;
		veil.hidden = false;
	}

	function closeVeil() {
		veil.hidden = true;
		clearTimers();
	}

	function clearTimers() {
		for (var i = 0; i < timers.length; i++) { clearTimeout(timers[i]); }
		timers = [];
	}

	function markStep(index) {
		for (var i = 0; i < steps.length; i++) {
			steps[i].classList.remove('is-now', 'is-done');
			if (i < index) { steps[i].classList.add('is-done'); }
			if (i === index) { steps[i].classList.add('is-now'); }
		}
		bar.style.width = Math.round((index / steps.length) * 100) + '%';
	}

	/* one POST does the whole job, so the stages are paced rather than reported;
	   the last one holds until the answer arrives */
	function runProgress() {
		el('ptProgress').hidden = false;
		clearTimers();
		markStep(0);

		var waits = [1200, 3200, 5200, 7200];
		for (var i = 0; i < waits.length; i++) {
			(function (step, wait) {
				timers.push(setTimeout(function () { markStep(step); }, wait));
			})(i + 1, waits[i]);
		}
	}

	function finish(ok, title, lines) {
		clearTimers();

		for (var i = 0; i < steps.length; i++) {
			steps[i].classList.remove('is-now');
			steps[i].classList.add('is-done');
		}
		bar.style.width = '100%';

		el('ptGlass').textContent = ok ? '🎉' : '⚠️';
		el('ptModalTitle').textContent = title;
		el('ptModalSub').textContent = '';
		el('ptProgress').hidden = true;

		el('ptResultEmoji').textContent = ok ? '✅' : '❌';
		el('ptResultLines').innerHTML = lines;
		el('ptResult').hidden = false;

		el('ptGo').textContent = window.PatchWords.reload;
		el('ptNo').textContent = window.PatchWords.close;
		el('ptModalFoot').hidden = false;

		el('ptGo').onclick = function () { window.location.reload(); };
		el('ptNo').onclick = closeVeil;
	}

	function askFirst(title, question, onYes) {
		openVeil(title, question);
		el('ptGlass').textContent = '❓';
		el('ptGo').textContent = window.PatchWords.confirmT;
		el('ptNo').textContent = window.PatchWords.close;
		el('ptModalFoot').hidden = false;

		el('ptGo').onclick = function () {
			el('ptModalFoot').hidden = true;
			el('ptGlass').textContent = '⏳';
			onYes();
		};
		el('ptNo').onclick = closeVeil;
	}

	/* ---------------- talking to the updater ---------------- */

	function call(action, method) {
		var options = { method: method || 'GET', credentials: 'same-origin' };

		if (method === 'POST') {
			var body = new FormData();
			body.append('token', token);
			options.body = body;
		}

		return fetch(endpoint + '?do=' + action, options).then(function (response) {
			return response.text().then(function (text) {
				try {
					return JSON.parse(text);
				} catch (error) {
					// a proxy or an error page answered instead of the updater
					throw new Error('HTTP ' + response.status + ': ' + text.slice(0, 160));
				}
			});
		}).then(function (data) {
			if (!data.ok) { throw new Error(data.error || 'unknown error'); }
			return data;
		});
	}

	function line(label, value) {
		return '<div>' + label + ' <b>' + value + '</b></div>';
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

			say(data.uptodate ? 'ok' : 'new',
				data.uptodate ? window.PatchWords.upToDate
				              : window.PatchWords.available + ' — ' + data.latest);
			apply.disabled = false;
		}).catch(function (error) {
			say('error', error.message);
			if (!quiet) { note('status: ' + error.message); }
		});
	}

	el('ptCheck').addEventListener('click', function () { log.textContent = ''; check(); });

	apply.addEventListener('click', function () {
		askFirst(window.PatchWords.applying, window.PatchWords.confirm, function () {
			say('busy', window.PatchWords.applying);
			apply.disabled = true;
			runProgress();

			call('apply', 'POST').then(function (data) {
				var lines = line(window.PatchWords.lVersion, data.version)
					+ line(window.PatchWords.lUpdated, data.updated)
					+ line(window.PatchWords.lSame, data.unchanged);

				if (data.migrations && data.migrations.length) {
					lines += line(window.PatchWords.lMigration, data.migrations.join(', '));
				}
				if (data.backup) {
					lines += line(window.PatchWords.lBackup, data.backup);
				}
				if (data.updated === 0) {
					lines += '<div>' + window.PatchWords.nothing + '</div>';
				}

				finish(true, window.PatchWords.doneTitle, lines);
				say('ok', window.PatchWords.applied + ' — ' + data.version);
				note('applied ' + data.version + ': ' + data.updated + ' updated, '
					+ data.unchanged + ' unchanged');

				return check(true);
			}).catch(function (error) {
				finish(false, window.PatchWords.failTitle, '<div>' + error.message + '</div>');
				say('error', error.message);
				note('apply: ' + error.message);
				apply.disabled = false;
			});
		});
	});

	el('ptUndo').addEventListener('click', function () {
		askFirst(window.PatchWords.undoTitle, window.PatchWords.undoAsk, function () {
			say('busy', window.PatchWords.rollingOn);
			runProgress();

			call('rollback', 'POST').then(function (data) {
				finish(true, window.PatchWords.doneTitle,
					line(window.PatchWords.lRestored, data.restored)
					+ line(window.PatchWords.lBackup, data.from));
				say('ok', window.PatchWords.rolledBack);
				note('rolled back ' + data.restored + ' file(s) from ' + data.from);
				return check(true);
			}).catch(function (error) {
				finish(false, window.PatchWords.failTitle, '<div>' + error.message + '</div>');
				say('error', error.message);
				note('rollback: ' + error.message);
			});
		});
	});

	check(true);
})();
</script>
{/literal}
