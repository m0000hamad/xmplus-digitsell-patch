{*
 * Dashboard invite nudge. Three messages in turn, each one only after the
 * previous was dismissed and a pause has passed:
 *   stage 0  the offer            (first visit)
 *   stage 1  what is lost         (12 hours after stage 0 was dismissed)
 *   stage 2  last reminder        (2 days after stage 1)
 * after stage 2 it rests 7 days and starts again from stage 1. Using any share
 * button counts as "done" and silences it for 30 days.
 * State lives in localStorage per user id - there is no endpoint to keep it
 * server side, and a lost state only means the offer is shown once more.
 * It waits for the notice modal / Swal popups on the same page to close first.
 * On phones it opens as a bottom sheet.
 *}
{literal}
<style>
.ivp-back {
	position: fixed;
	inset: 0;
	z-index: 1060;
	display: flex;
	align-items: center;
	justify-content: center;
	padding: 16px;
	background: rgba(10, 14, 30, .5);
	backdrop-filter: blur(6px);
	-webkit-backdrop-filter: blur(6px);
	opacity: 0;
	transition: opacity .25s ease;
}
.ivp-back[hidden] { display: none; }
.ivp-back.ivp-open { opacity: 1; }

.ivp {
	--ivp-a: #fb923c;
	--ivp-b: #ec4899;
	--ivp-soft: rgba(249, 115, 22, .1);
	--ivp-ink: #ea580c;
	position: relative;
	width: 100%;
	max-width: 380px;
	max-height: calc(100vh - 32px);
	overflow-y: auto;
	border-radius: 28px;
	background: #fff;
	box-shadow: 0 30px 80px -20px rgba(15, 23, 42, .45), 0 0 0 1px rgba(15, 23, 42, .04);
	transform: translateY(18px) scale(.96);
	transition: transform .32s cubic-bezier(.2, .9, .3, 1.2);
	font-family: inherit;
	text-align: center;
	scrollbar-width: none;
}
.ivp::-webkit-scrollbar { display: none; }
.ivp-open .ivp { transform: none; }
/* the chat bubbles start typing when the popup opens, not when the page loads */
.ivp-back:not(.ivp-open) .ivi-b { animation: none; }
.ivp[data-stage="1"] { --ivp-a: #f59e0b; --ivp-b: #ef4444; --ivp-soft: rgba(239, 68, 68, .09); --ivp-ink: #dc2626; }
.ivp[data-stage="2"] { --ivp-a: #fbbf24; --ivp-b: #f43f5e; --ivp-soft: rgba(244, 63, 94, .09); --ivp-ink: #e11d48; }

.ivp-hero {
	position: relative;
	padding: 26px 22px 20px;
	overflow: hidden;
	color: #fff;
	background:
		radial-gradient(120% 90% at 100% 0%, rgba(255, 255, 255, .22), transparent 55%),
		radial-gradient(90% 80% at 0% 100%, rgba(0, 0, 0, .12), transparent 60%),
		linear-gradient(145deg, var(--ivp-a), var(--ivp-b));
}
.ivp-hero::before,
.ivp-hero::after {
	content: "";
	position: absolute;
	border-radius: 50%;
	border: 1px solid rgba(255, 255, 255, .18);
}
.ivp-hero::before { width: 220px; height: 220px; inset-block-start: -120px; inset-inline-start: -70px; }
.ivp-hero::after { width: 150px; height: 150px; inset-block-end: -80px; inset-inline-end: -40px; }

.ivp-badge {
	position: relative;
	z-index: 1;
	width: 62px;
	height: 62px;
	margin: 0 auto 12px;
	border-radius: 20px;
	display: flex;
	align-items: center;
	justify-content: center;
	font-size: 28px;
	color: #fff;
	background: rgba(255, 255, 255, .2);
	box-shadow: inset 0 0 0 1px rgba(255, 255, 255, .35), 0 12px 28px -8px rgba(0, 0, 0, .3);
	animation: ivp-float 3.2s ease-in-out infinite;
}
@keyframes ivp-float { 0%, 100% { transform: translateY(0) rotate(-4deg); } 50% { transform: translateY(-6px) rotate(4deg); } }

.ivp-title {
	position: relative;
	z-index: 1;
	margin: 0;
	font-size: 18px;
	font-weight: 700;
	line-height: 1.7;
	color: #fff;
}
.ivp-chip {
	position: relative;
	z-index: 1;
	display: inline-flex;
	align-items: center;
	gap: 7px;
	margin-top: 10px;
	padding: 6px 14px;
	border-radius: 999px;
	font-size: 12.5px;
	font-weight: 500;
	background: rgba(255, 255, 255, .95);
	color: var(--ivp-ink);
	box-shadow: 0 6px 16px -6px rgba(0, 0, 0, .25);
}
.ivp-chip b { font-weight: 900; }

.ivp-close {
	position: absolute;
	z-index: 2;
	inset-block-start: 14px;
	inset-inline-end: 14px;
	width: 32px;
	height: 32px;
	border: 0;
	border-radius: 50%;
	display: flex;
	align-items: center;
	justify-content: center;
	background: rgba(255, 255, 255, .18);
	color: #fff;
	font-size: 14px;
	cursor: pointer;
	transition: background .15s ease;
}
.ivp-close:hover { background: rgba(255, 255, 255, .3); }

.ivp-body { padding: 18px 20px 14px; }
.ivp-feats {
	position: relative;
	z-index: 1;
	margin: 16px 0 0;
	padding: 12px 12px 10px;
	border-radius: 16px;
	background: rgba(255, 255, 255, .14);
	box-shadow: inset 0 0 0 1px rgba(255, 255, 255, .22);
	text-align: start;
}
.ivp-feats-title {
	margin-bottom: 10px;
	font-size: 12.5px;
	font-weight: 700;
	color: #fff;
	text-align: center;
}
.ivp-feats ul {
	list-style: none;
	margin: 0;
	padding: 0;
	display: grid;
	grid-template-columns: 1fr 1fr;
	gap: 8px 10px;
}
.ivp-feats li {
	display: flex;
	align-items: center;
	gap: 8px;
	font-size: 12px;
	font-weight: 500;
	line-height: 1.6;
	color: #fff;
}
.ivp-feats li.ivp-wide { grid-column: 1 / -1; }
.ivp-feats li i {
	flex: 0 0 26px;
	width: 26px;
	height: 26px;
	border-radius: 9px;
	display: flex;
	align-items: center;
	justify-content: center;
	font-size: 12px;
	color: #fff;
	background: rgba(255, 255, 255, .22);
}

/* the share buttons stay in view however long the conversation above gets */
.ivp-foot {
	position: sticky;
	bottom: 0;
	z-index: 2;
	margin: 0 -20px -14px;
	padding: 14px 20px 10px;
	background: linear-gradient(to bottom, rgba(255, 255, 255, 0), #fff 22px);
}
.ivp .ivs-main {
	background: linear-gradient(135deg, var(--ivp-a), var(--ivp-b));
	box-shadow: 0 12px 26px -10px var(--ivp-ink), inset 0 1px 0 rgba(255, 255, 255, .3);
}
.ivp .ivs-main:hover { box-shadow: 0 16px 30px -10px var(--ivp-ink), inset 0 1px 0 rgba(255, 255, 255, .3); }
.ivp-later {
	margin-top: 8px;
	padding: 4px 10px;
	border: 0;
	background: none;
	color: #9aa3b5;
	font-size: 12.5px;
	font-weight: 500;
	cursor: pointer;
	font-family: inherit;
}
.ivp-later:hover { color: #5b6478; }

html[data-hs-theme="dark"] .ivp { background: #182132; box-shadow: 0 30px 80px -20px rgba(0, 0, 0, .7), 0 0 0 1px rgba(255, 255, 255, .06); }
html[data-hs-theme="dark"] .ivp-chip { background: rgba(15, 23, 42, .85); color: #fff; }
html[data-hs-theme="dark"] .ivp-later { color: #7d889e; }
html[data-hs-theme="dark"] .ivp-foot { background: linear-gradient(to bottom, rgba(24, 33, 50, 0), #182132 22px); }

/* wide screens: hero with the features on one side, the conversation on the other */
@media (min-width: 820px) {
	.ivp { max-width: 780px; display: grid; grid-template-columns: 330px 1fr; overflow: hidden; }
	.ivp-hero { display: flex; flex-direction: column; justify-content: center; }
	.ivp-body { max-height: calc(100vh - 32px); overflow-y: auto; scrollbar-width: none; display: flex; flex-direction: column; }
	.ivp-body::-webkit-scrollbar { display: none; }
	.ivp-body .ivi { flex: 1 1 auto; }
	.ivp-foot { margin-top: auto; }
}

@media (max-width: 575.98px) {
	.ivp-back { align-items: flex-end; padding: 0; }
	.ivp {
		max-width: none;
		max-height: 92vh;
		border-radius: 26px 26px 0 0;
		transform: translateY(100%);
		padding-bottom: env(safe-area-inset-bottom);
	}
	.ivp-hero { padding-top: 30px; }
	.ivp-hero .ivp-grip {
		position: absolute;
		z-index: 2;
		inset-block-start: 9px;
		inset-inline-start: 50%;
		width: 40px;
		height: 4px;
		margin-inline-start: -20px;
		border-radius: 4px;
		background: rgba(255, 255, 255, .45);
	}
}
@media (prefers-reduced-motion: reduce) {
	.ivp, .ivp-back { transition: none; }
	.ivp-badge { animation: none; }
}
</style>
{/literal}

<div class="ivp-back" id="ivpBack" hidden>
	<div class="ivp" role="dialog" aria-modal="true" aria-labelledby="ivpTitle" data-stage="0">
		<div class="ivp-hero">
			<span class="ivp-grip"></span>
			<button type="button" class="ivp-close" data-ivp-close aria-label="close"><i class="fa-solid fa-xmark"></i></button>
			<div class="ivp-badge"><i class="fa-solid fa-gift" data-ivp-icon></i></div>
			<h5 class="ivp-title" id="ivpTitle"></h5>
			<div class="ivp-chip"><i class="fa-solid fa-coins"></i><span data-ivp-chip></span></div>
			<div class="ivp-feats">
				<div class="ivp-feats-title">{$translate->get('InviteFeatTitle')}</div>
				<ul>
					<li><i class="fa-solid fa-location-dot"></i>{$translate->get('InviteFeat1')}</li>
					<li><i class="fa-solid fa-bolt"></i>{$translate->get('InviteFeat5')}</li>
					<li><i class="fa-solid fa-shield-halved"></i>{$translate->get('InviteFeat2')}</li>
					<li><i class="fa-solid fa-battery-three-quarters"></i>{$translate->get('InviteFeat3')}</li>
					<li class="ivp-wide"><i class="fa-solid fa-ban"></i>{$translate->get('InviteFeat4')}</li>
					<li class="ivp-wide"><i class="fa-solid fa-award"></i>{$translate->get('InviteFeat6')}</li>
				</ul>
			</div>
		</div>
		<div class="ivp-body">
			{include file='user/affiliate/inviteinsight.tpl' insLead=1}
			<div class="ivp-foot">
				{include file='user/affiliate/sharebar.tpl' shareEditable=0 shareCompact=1}
				<button type="button" class="ivp-later" data-ivp-close></button>
			</div>
		</div>
	</div>
</div>

<script>
	window.dsInvitePop = {
		uid: {$user->id},
		chip: "{$translate->get('InvitePopChip')|escape:'javascript'}",
		stages: [
			{ icon: "fa-gift", title: "{$translate->get('InvitePop1Title')|escape:'javascript'}", body: "{$translate->get('InvitePop1Body')|escape:'javascript'}", later: "{$translate->get('InvitePopLater')|escape:'javascript'}" },
			{ icon: "fa-hourglass-half", title: "{$translate->get('InvitePop2Title')|escape:'javascript'}", body: "{$translate->get('InvitePop2Body')|escape:'javascript'}", later: "{$translate->get('InvitePopNotNow')|escape:'javascript'}" },
			{ icon: "fa-tags", title: "{$translate->get('InvitePop3Title')|escape:'javascript'}", body: "{$translate->get('InvitePop3Body')|escape:'javascript'}", later: "{$translate->get('InvitePopNotNow')|escape:'javascript'}" }
		],
		percent: "{$Config['commission']|escape:'javascript'}"
	};
</script>

{literal}
<script>
(function () {
	var cfg = window.dsInvitePop;
	var back = document.getElementById('ivpBack');
	if (!cfg || !back) { return; }

	var HOUR = 3600 * 1000;
	var PAUSE = [12 * HOUR, 48 * HOUR, 7 * 24 * HOUR]; // wait after dismissing stage 0, 1, 2
	var AFTER_SHARE = 30 * 24 * HOUR;
	var KEY = 'dsInvitePop:' + cfg.uid;

	function load() {
		try {
			var state = JSON.parse(window.localStorage.getItem(KEY) || 'null');
			if (state && typeof state.stage === 'number') { return state; }
		} catch (e) {}
		return { stage: 0, next: 0 };
	}
	function save(state) {
		try { window.localStorage.setItem(KEY, JSON.stringify(state)); } catch (e) {}
	}

	var state = load();
	if (Date.now() < state.next) { return; }

	var stage = Math.min(Math.max(state.stage, 0), cfg.stages.length - 1);
	var text = cfg.stages[stage];
	var percent = function (s) { return s.split('%percent%').join(cfg.percent); };

	back.querySelector('.ivp').setAttribute('data-stage', stage);
	back.querySelector('[data-ivp-icon]').className = 'fa-solid ' + text.icon;
	back.querySelector('#ivpTitle').textContent = text.title;
	back.querySelector('[data-ivp-chip]').innerHTML = percent(cfg.chip);
	back.querySelector('[data-ivp-msg]').innerHTML = percent(text.body);
	back.querySelector('.ivp-later').textContent = text.later;

	var shown = false;

	function close(shared) {
		if (!shown) { return; }
		shown = false;
		if (shared) {
			save({ stage: 0, next: Date.now() + AFTER_SHARE });
		} else {
			// after the last message go round again from the "what is lost" one
			save({ stage: stage + 1 >= cfg.stages.length ? 1 : stage + 1, next: Date.now() + PAUSE[stage] });
		}
		back.classList.remove('ivp-open');
		window.setTimeout(function () { back.hidden = true; }, 320);
		document.removeEventListener('keydown', onKey);
	}

	function onKey(event) { if (event.key === 'Escape') { close(false); } }

	function open() {
		shown = true;
		back.hidden = false;
		if (window.dsInviteShare) { window.dsInviteShare(); }
		window.requestAnimationFrame(function () {
			window.requestAnimationFrame(function () { back.classList.add('ivp-open'); });
		});
		document.addEventListener('keydown', onKey);
	}

	back.addEventListener('click', function (event) {
		if (event.target === back || event.target.closest('[data-ivp-close]')) { close(false); }
	});
	// any share button counts as done; after a copy stay open long enough to show the tick
	back.addEventListener('ivs:shared', function (event) {
		var kind = event.detail && event.detail.kind;
		if (kind === 'copy') {
			window.setTimeout(function () { close(true); }, 1400);
		} else {
			close(true);
		}
	});

	// never stack on top of the notice modal or a Swal message - wait until the page is quiet
	function busy() {
		return document.querySelector('.modal.show, .swal2-container, .layui-layer-dialog, .gfp-back:not([hidden])') !== null;
	}

	var quietSince = 0;
	var started = Date.now();
	var timer = window.setInterval(function () {
		if (Date.now() - started > 120000) { window.clearInterval(timer); return; }
		if (Date.now() - started < 3000) { return; }
		if (busy()) { quietSince = 0; return; }
		if (!quietSince) { quietSince = Date.now(); return; }
		if (Date.now() - quietSince >= 2000) {
			window.clearInterval(timer);
			open();
		}
	}, 500);
})();
</script>
{/literal}
