{literal}
<style>
/* ------------------------------------------------------------------ *
 * The purchase verdict.
 *
 * Coming back from a gateway used to show a one-line toast for a moment
 * and then a redirect, so buyers could not tell whether their money had
 * gone through. This says it plainly, waits, and gets out of the way.
 * ------------------------------------------------------------------ */
.ores-veil {
	position: fixed;
	inset: 0;
	z-index: 20100;
	display: flex;
	align-items: center;
	justify-content: center;
	padding: 18px;
	background: rgba(9, 14, 30, .55);
	-webkit-backdrop-filter: blur(4px);
	backdrop-filter: blur(4px);
	opacity: 0;
	transition: opacity .25s ease;
}
.ores-veil.ores-on { opacity: 1; }
.ores-veil[hidden] { display: none !important; }

.ores-card {
	width: 100%;
	max-width: 380px;
	border-radius: 22px;
	background: #fff;
	box-shadow: 0 26px 70px rgba(9, 14, 30, .42);
	overflow: hidden;
	text-align: center;
	transform: translateY(14px) scale(.97);
	transition: transform .28s cubic-bezier(.2, .9, .3, 1.2);
}
.ores-veil.ores-on .ores-card { transform: translateY(0) scale(1); }

.ores-top {
	padding: 26px 22px 18px;
	color: #fff;
	background: linear-gradient(135deg, #059669, #10b981);
}
.ores-fail .ores-top { background: linear-gradient(135deg, #be123c, #f43f5e); }
.ores-wait .ores-top { background: linear-gradient(135deg, #b45309, #f59e0b); }

.ores-emoji {
	font-size: 46px;
	line-height: 1;
	display: block;
	animation: oresPop .5s cubic-bezier(.2, .9, .3, 1.4);
}
@keyframes oresPop {
	0%   { transform: scale(.4); opacity: 0; }
	100% { transform: scale(1); opacity: 1; }
}
.ores-title {
	margin: 12px 0 0;
	font-size: 18px;
	font-weight: 800;
	color: #fff;
}

.ores-body { padding: 18px 22px 20px; }
.ores-text {
	font-size: 13.5px;
	line-height: 2;
	color: #3b4a6b;
	margin: 0;
}
.ores-meta {
	margin-top: 14px;
	border-radius: 14px;
	background: rgba(23, 32, 61, .045);
	padding: 11px 14px;
	font-size: 12px;
	line-height: 2;
	color: #56617a;
	text-align: start;
}
.ores-meta b { direction: ltr; unicode-bidi: isolate; font-weight: 800; }
.ores-meta div { display: flex; justify-content: space-between; gap: 10px; }

.ores-btn {
	display: inline-flex;
	align-items: center;
	justify-content: center;
	gap: 7px;
	width: 100%;
	margin-top: 16px;
	border: 0;
	border-radius: 14px;
	padding: 12px 18px;
	font-size: 13.5px;
	font-weight: 800;
	color: #fff;
	cursor: pointer;
	background: linear-gradient(135deg, #4f46e5, #7c3aed);
	box-shadow: 0 6px 16px rgba(99, 102, 241, .32);
}
.ores-btn:active { transform: scale(.97); }

/* the bar drains over the time left, so the wait is visible */
.ores-timer {
	height: 4px;
	background: rgba(23, 32, 61, .09);
	overflow: hidden;
}
.ores-timer span {
	display: block;
	height: 100%;
	width: 100%;
	background: linear-gradient(90deg, #6366f1, #0ea5e9);
	transform-origin: right;
}
.ores-fail .ores-timer span { background: linear-gradient(90deg, #f43f5e, #fb7185); }

html[data-hs-theme="dark"] .ores-card { background: #1c2536; }
html[data-hs-theme="dark"] .ores-text { color: #cfd8ea; }
html[data-hs-theme="dark"] .ores-meta { background: rgba(255, 255, 255, .06); color: #9fb0cc; }
html[data-hs-theme="dark"] .ores-timer { background: rgba(255, 255, 255, .1); }

@media (max-width: 420px) {
	.ores-card { max-width: 100%; border-radius: 18px; }
	.ores-top { padding: 22px 18px 15px; }
	.ores-emoji { font-size: 40px; }
	.ores-title { font-size: 16.5px; }
	.ores-body { padding: 16px 18px 18px; }
}
</style>

<div class="ores-veil" id="oresVeil" hidden>
	<div class="ores-card" id="oresCard">
		<div class="ores-top">
			<span class="ores-emoji" id="oresEmoji">🎉</span>
			<h5 class="ores-title" id="oresTitle"></h5>
		</div>
		<div class="ores-body">
			<p class="ores-text" id="oresText"></p>
			<div class="ores-meta" id="oresMeta" hidden></div>
			<button type="button" class="ores-btn" id="oresBtn"></button>
		</div>
		<div class="ores-timer"><span id="oresBar"></span></div>
	</div>
</div>

<script>
/*
 * window.OrderResult.show({kind, title, text, meta, button, seconds, then})
 *
 *   kind    'ok' | 'fail' | 'wait'
 *   meta    array of [label, value] pairs, drawn as rows
 *   seconds how long before it fades by itself (0 keeps it up)
 *   then    called once, when it closes either way
 *
 * A verdict can also be handed to the next page: OrderResult.carry(payload)
 * stores it, and any page including this file shows it once on load.
 */
window.OrderResult = (function () {
	var KEY = 'xm_order_result';

	var veil = document.getElementById('oresVeil');
	var card = document.getElementById('oresCard');
	var bar = document.getElementById('oresBar');
	var button = document.getElementById('oresBtn');

	var timer = null;
	var after = null;

	function close() {
		if (timer) { clearTimeout(timer); timer = null; }

		veil.classList.remove('ores-on');
		setTimeout(function () { veil.hidden = true; }, 260);

		var callback = after;
		after = null;
		if (typeof callback === 'function') { callback(); }
	}

	function show(options) {
		var settings = options || {};
		var kind = settings.kind || 'ok';
		var seconds = typeof settings.seconds === 'number' ? settings.seconds : 7;

		card.className = 'ores-card' + (kind === 'fail' ? ' ores-fail' : (kind === 'wait' ? ' ores-wait' : ''));

		document.getElementById('oresEmoji').textContent =
			settings.emoji || (kind === 'fail' ? '😔' : (kind === 'wait' ? '⏳' : '🎉'));
		document.getElementById('oresTitle').textContent = settings.title || '';
		document.getElementById('oresText').textContent = settings.text || '';

		var meta = document.getElementById('oresMeta');
		meta.innerHTML = '';

		if (settings.meta && settings.meta.length) {
			for (var i = 0; i < settings.meta.length; i++) {
				var row = document.createElement('div');
				var label = document.createElement('span');
				var value = document.createElement('b');

				label.textContent = settings.meta[i][0];
				value.textContent = settings.meta[i][1];

				row.appendChild(label);
				row.appendChild(value);
				meta.appendChild(row);
			}
			meta.hidden = false;
		} else {
			meta.hidden = true;
		}

		button.textContent = settings.button || 'OK';
		after = settings.then || null;

		veil.hidden = false;
		void veil.offsetWidth;          // let the transition start from zero
		veil.classList.add('ores-on');

		bar.style.transition = 'none';
		bar.style.transform = 'scaleX(1)';

		if (seconds > 0) {
			void bar.offsetWidth;
			bar.style.transition = 'transform ' + seconds + 's linear';
			bar.style.transform = 'scaleX(0)';
			timer = setTimeout(close, seconds * 1000);
		} else {
			bar.style.transform = 'scaleX(0)';
		}
	}

	button.addEventListener('click', close);
	veil.addEventListener('click', function (event) {
		if (event.target === veil) { close(); }
	});

	/* hand a verdict to whatever page loads next */
	function carry(payload) {
		try {
			sessionStorage.setItem(KEY, JSON.stringify(payload));
		} catch (error) { /* private mode: the popup on this page has to do */ }
	}

	function takeCarried() {
		var raw = null;

		try {
			raw = sessionStorage.getItem(KEY);
			sessionStorage.removeItem(KEY);
		} catch (error) {
			return null;
		}

		if (!raw) { return null; }

		try {
			return JSON.parse(raw);
		} catch (error) {
			return null;
		}
	}

	var waiting = takeCarried();
	if (waiting) {
		// let the page paint first, or the card appears against a blank screen
		setTimeout(function () { show(waiting); }, 350);
	}

	return { show: show, close: close, carry: carry };
})();
</script>
{/literal}
