{*
  Promotion look for the plan pages (plan.tpl, plan-details.tpl): animated
  badges, the struck-through list price, the occasion line, the countdown and
  the "N left" counter. Included once per page, before the cards.

  The countdown hides everything marked .promo-only when it reaches zero and
  turns the list price back into the price: the cron restores price_option
  within a minute, so the page must already stop promising the discount.
*}
{literal}
<style>
/* ---------- badges ---------- */
.promo-badge {
	position: relative;
	display: inline-flex;
	align-items: center;
	gap: 5px;
	padding: 6px 15px 6px 14px;
	border-radius: 999px;
	font-size: 13px;
	font-weight: 900;
	line-height: 1.35;
	white-space: nowrap;
	color: #fff;
	overflow: hidden;
	isolation: isolate;
	background: var(--pb-bg);
	box-shadow: 0 0 0 1.5px rgba(255, 255, 255, .55) inset, 0 4px 14px var(--pb-glow);
	animation: promoGlow 2.2s ease-in-out infinite;
	text-shadow: 0 1px 2px rgba(0, 0, 0, .18);
}
/* the moving band of light */
.promo-badge::after {
	content: "";
	position: absolute;
	inset: 0;
	z-index: -1;
	background: linear-gradient(110deg, transparent 20%, rgba(255, 255, 255, .6) 45%, transparent 70%);
	transform: translateX(-120%);
	animation: promoShine 2.8s ease-in-out infinite;
}
.promo-badge-discount { --pb-bg: linear-gradient(135deg, #ff3d6e, #ff7a3d); --pb-glow: rgba(255, 61, 110, .45); }
.promo-badge-special  { --pb-bg: linear-gradient(135deg, #f59e0b, #fcd34d 55%, #f59e0b); --pb-glow: rgba(245, 158, 11, .5); color: #4a2a00; text-shadow: 0 1px 0 rgba(255, 255, 255, .45); }
.promo-badge-prize    { --pb-bg: linear-gradient(135deg, #7c3aed, #db2777); --pb-glow: rgba(124, 58, 237, .45); }

/* twinkling stars around a badge */
.promo-star {
	position: absolute;
	z-index: 1;
	font-size: 10px;
	line-height: 1;
	color: #fff;
	opacity: 0;
	pointer-events: none;
	animation: promoTwinkle 1.9s ease-in-out infinite;
}
.promo-star:nth-of-type(1) { top: 1px; inset-inline-end: 7px; }
.promo-star:nth-of-type(2) { bottom: 1px; inset-inline-end: 22px; animation-delay: .65s; font-size: 6px; }
.promo-star:nth-of-type(3) { top: 3px; inset-inline-start: 3px; animation-delay: 1.3s; font-size: 7px; }
.promo-badge-special .promo-star { color: #fffbe6; }

@keyframes promoShine {
	0%, 35% { transform: translateX(-120%); }
	75%, 100% { transform: translateX(120%); }
}
@keyframes promoGlow {
	0%, 100% { box-shadow: 0 0 0 1.5px rgba(255, 255, 255, .55) inset, 0 4px 14px var(--pb-glow); }
	50% { box-shadow: 0 0 0 1.5px rgba(255, 255, 255, .8) inset, 0 4px 22px var(--pb-glow), 0 0 12px var(--pb-glow); }
}
@keyframes promoTwinkle {
	0%, 100% { opacity: 0; transform: scale(.4) rotate(0deg); }
	50% { opacity: 1; transform: scale(1.15) rotate(35deg); }
}

/* ---------- a promoted card gets a slowly turning halo ---------- */
.plan-card.is-promo {
	border-color: transparent;
	background:
		linear-gradient(#fff, #fff) padding-box,
		conic-gradient(from var(--promo-turn, 0deg), #ff3d6e, #f59e0b, #7c3aed, #06b6d4, #ff3d6e) border-box;
	animation: promoTurn 6s linear infinite;
}
@property --promo-turn { syntax: "<angle>"; inherits: false; initial-value: 0deg; }
@keyframes promoTurn { to { --promo-turn: 360deg; } }

/* ---------- the big sticker on a plan card ---------- */
.plan-card.is-promo .plan-top { overflow: visible; z-index: 2; }
.promo-sticker {
	position: absolute;
	z-index: 4;
	inset-inline-end: 14px;
	bottom: -34px;
	width: 96px;
	height: 96px;
	pointer-events: none;
	filter: drop-shadow(0 6px 10px rgba(0, 0, 0, .28)) drop-shadow(0 0 10px var(--st-glow));
	--st-rot: -12deg;
	animation: promoWobble 3.2s ease-in-out infinite, promoGlowSticker 2.2s ease-in-out infinite;
}
/* the second sticker sits beside the first, tilted the other way and a beat behind */
.promo-sticker-slot2 {
	inset-inline-end: 100px;
	width: 88px;
	height: 88px;
	bottom: -30px;
	--st-rot: 10deg;
	animation-delay: -1.6s, -1.1s;
}
.promo-sticker-prize { --st-bg: radial-gradient(circle at 35% 30%, #f5d0fe, #c026d3 42%, #7c3aed 80%, #5b21b6); --st-ink: #fff; --st-glow: rgba(192, 38, 211, .7); }
.promo-sticker-special { --st-bg: radial-gradient(circle at 35% 30%, #fff7cc, #fcd34d 38%, #f59e0b 75%, #d97706); --st-ink: #5a2d00; --st-glow: rgba(252, 211, 77, .75); }
.promo-sticker-discount { --st-bg: radial-gradient(circle at 35% 30%, #ffd1dc, #ff5c85 40%, #e11d48 78%, #9f1239); --st-ink: #fff; --st-glow: rgba(255, 61, 110, .7); }
.promo-sticker-burst {
	position: relative;
	width: 100%;
	height: 100%;
	display: flex;
	flex-direction: column;
	align-items: center;
	justify-content: center;
	gap: 1px;
	overflow: hidden;
	color: var(--st-ink);
	background: var(--st-bg);
	clip-path: polygon(50.0% 0.0%, 59.1% 10.0%, 71.7% 5.0%, 75.6% 17.9%, 89.1% 18.8%, 86.9% 32.2%, 98.7% 38.9%, 91.0% 50.0%, 98.7% 61.1%, 86.9% 67.8%, 89.1% 81.2%, 75.6% 82.1%, 71.7% 95.0%, 59.1% 90.0%, 50.0% 100.0%, 40.9% 90.0%, 28.3% 95.0%, 24.4% 82.1%, 10.9% 81.2%, 13.1% 67.8%, 1.3% 61.1%, 9.0% 50.0%, 1.3% 38.9%, 13.1% 32.2%, 10.9% 18.8%, 24.4% 17.9%, 28.3% 5.0%, 40.9% 10.0%);
	text-shadow: 0 1px 0 rgba(255, 255, 255, .35);
}
.promo-sticker-discount .promo-sticker-burst,
.promo-sticker-prize .promo-sticker-burst { text-shadow: 0 1px 2px rgba(0, 0, 0, .3); }
/* a dashed ring inside the burst, like a printed seal */
.promo-sticker-burst::before {
	content: "";
	position: absolute;
	inset: 17%;
	border-radius: 50%;
	border: 1.5px dashed currentColor;
	opacity: .35;
}
/* the moving band of light */
.promo-sticker-burst::after {
	content: "";
	position: absolute;
	inset: 0;
	background: linear-gradient(115deg, transparent 30%, rgba(255, 255, 255, .75) 48%, transparent 64%);
	transform: translateX(-130%);
	animation: promoShine 2.6s ease-in-out infinite;
}
.promo-sticker-icon { font-size: 17px; line-height: 1; }
.promo-sticker-big { position: relative; font-size: 20px; font-weight: 900; line-height: 1.1; letter-spacing: -.3px; }
.promo-sticker-discount .promo-sticker-big { font-size: 23px; }
.promo-sticker-mid { position: relative; font-size: 14.5px; font-weight: 900; line-height: 1.15; }
.promo-sticker-small { position: relative; font-size: 11.5px; font-weight: 900; line-height: 1.1; }
.promo-sticker-spark {
	position: absolute;
	font-style: normal;
	font-size: 13px;
	color: #fff;
	text-shadow: 0 0 6px var(--st-glow);
	opacity: 0;
	animation: promoTwinkle 1.8s ease-in-out infinite;
}
.promo-sticker-spark:nth-of-type(1) { top: -6px; inset-inline-start: 6px; }
.promo-sticker-spark:nth-of-type(2) { bottom: 4px; inset-inline-end: -8px; font-size: 10px; animation-delay: .6s; }
.promo-sticker-spark:nth-of-type(3) { top: 10px; inset-inline-end: -10px; font-size: 9px; animation-delay: 1.2s; }
@keyframes promoWobble {
	0%, 100% { transform: rotate(var(--st-rot)) scale(1); }
	50% { transform: rotate(calc(var(--st-rot) + 8deg)) scale(1.07); }
}
@keyframes promoGlowSticker {
	0%, 100% { filter: drop-shadow(0 6px 10px rgba(0, 0, 0, .28)) drop-shadow(0 0 6px var(--st-glow)); }
	50% { filter: drop-shadow(0 6px 10px rgba(0, 0, 0, .28)) drop-shadow(0 0 16px var(--st-glow)); }
}
.plan-card.is-promo .plan-body { position: relative; z-index: 1; }
/* room for the part of a sticker that hangs over onto the card */
.plan-card.has-sticker .plan-body { padding-top: 26px; }
/* two stickers: the price moves up so the second one does not cover it */
.plan-card.has-two-stickers .plan-top { padding-bottom: 62px; }
.plan-card.has-two-stickers .plan-body { padding-top: 36px; }
.promo-over .promo-sticker { display: none; }

/* ---------- prices ---------- */
.promo-was {
	font-size: 13px;
	font-weight: 700;
	opacity: .78;
	text-decoration: line-through;
	text-decoration-thickness: 2px;
	direction: ltr;
	unicode-bidi: isolate;
}
.promo-off {
	display: inline-flex;
	align-items: center;
	font-size: 10.5px;
	font-weight: 900;
	padding: 2px 8px;
	border-radius: 7px;
	background: #fff;
	color: #e11d48;
	box-shadow: 0 2px 8px rgba(0, 0, 0, .15);
}
.pd-cycle-price .promo-was { display: block; font-size: 11.5px; color: #8c98ab; opacity: 1; }
.pd-cycle-price .promo-off { margin-inline-start: 6px; background: #ffe4ea; box-shadow: none; }

/* ---------- occasion, countdown, stock ---------- */
.promo-strip {
	display: flex;
	flex-direction: column;
	gap: 7px;
	margin: 0 18px 4px;
	padding: 11px 13px;
	border-radius: 14px;
	background: linear-gradient(135deg, rgba(255, 61, 110, .08), rgba(124, 58, 237, .08));
	border: 1px dashed rgba(255, 61, 110, .35);
	font-size: 12px;
	color: #3b4a6b;
}
.promo-strip-line { display: flex; align-items: baseline; gap: 6px; line-height: 1.8; }
.promo-strip-line > span:not(.promo-timer) { flex: 1 1 auto; min-width: 0; }
.promo-strip-line > span.promo-timer-label { flex: 0 0 auto; white-space: nowrap; }
.promo-strip-line.promo-timer-line { flex-wrap: wrap; align-items: center; row-gap: 4px; }

/* on a promoted card the badges sit in a row at the top of the coloured cap,
   clear of the cycle pill on the other side */
.plan-badges.plan-badges-flow {
	position: relative;
	top: auto;
	inset-inline-start: auto;
	flex-direction: row;
	flex-wrap: wrap;
	padding-inline-end: 64px;
	margin: -6px 0 12px;
}
.promo-strip-line b { color: #16203d; }
.promo-timer {
	display: inline-flex;
	gap: 4px;
	direction: ltr;
	unicode-bidi: isolate;
	font-variant-numeric: tabular-nums;
}
.promo-timer span {
	min-width: 26px;
	padding: 2px 5px;
	border-radius: 7px;
	text-align: center;
	font-weight: 900;
	color: #fff;
	background: linear-gradient(135deg, #ff3d6e, #7c3aed);
}
.promo-timer small { font-weight: 700; opacity: .9; margin-inline-start: 2px; }
.promo-left b { color: #e11d48; }

/* the large banner on the plan detail page */
.promo-banner {
	position: relative;
	border-radius: 20px;
	padding: 16px 18px;
	margin-bottom: 18px;
	overflow: hidden;
	color: #fff;
	background: linear-gradient(135deg, #ff3d6e, #7c3aed 60%, #06b6d4);
	box-shadow: 0 14px 34px rgba(124, 58, 237, .28);
}
.promo-banner::after {
	content: "";
	position: absolute;
	inset: 0;
	background: linear-gradient(110deg, transparent 30%, rgba(255, 255, 255, .22) 48%, transparent 66%);
	transform: translateX(-120%);
	animation: promoShine 4s ease-in-out infinite;
	pointer-events: none;
}
.promo-banner-badges { display: flex; flex-wrap: wrap; gap: 6px; margin-bottom: 10px; }
.promo-banner .promo-badge { box-shadow: 0 0 0 1.5px rgba(255, 255, 255, .7) inset; }
.promo-banner .promo-banner-line { position: relative; z-index: 1; font-size: 13px; font-weight: 600; line-height: 1.9; }
.promo-banner .promo-banner-line b { color: #fff; font-weight: 900; }
.promo-banner .promo-timer span { background: rgba(255, 255, 255, .22); }

/* the countdown reached zero */
.promo-over .promo-only { display: none !important; }
.promo-over .promo-was { text-decoration: none; opacity: 1; }
.promo-over .plan-price-was .promo-was { font-size: 22px; font-weight: 800; }
.plan-card.promo-over { animation: none; background: #fff; border-color: rgba(23, 32, 61, .08); }

/* ---------- night ---------- */
html[data-hs-theme="dark"] .plan-card.is-promo {
	background:
		linear-gradient(#18213a, #18213a) padding-box,
		conic-gradient(from var(--promo-turn, 0deg), #ff3d6e, #f59e0b, #7c3aed, #06b6d4, #ff3d6e) border-box;
}
html[data-hs-theme="dark"] .plan-card.promo-over { background: #18213a; border-color: rgba(255, 255, 255, .09); }
html[data-hs-theme="dark"] .promo-strip {
	background: linear-gradient(135deg, rgba(255, 61, 110, .14), rgba(124, 58, 237, .16));
	border-color: rgba(255, 122, 150, .4);
	color: #c9d4ea;
}
html[data-hs-theme="dark"] .promo-strip-line b { color: #f1f4fb; }
html[data-hs-theme="dark"] .promo-left b { color: #ff8fab; }
html[data-hs-theme="dark"] .pd-cycle-price .promo-was { color: #8b9ab5; }
html[data-hs-theme="dark"] .pd-cycle-price .promo-off { background: rgba(255, 61, 110, .2); color: #ff9fb5; }

@media (max-width: 575.98px) {
	.promo-sticker { width: 86px; height: 86px; bottom: -30px; }
	.promo-sticker-slot2 { width: 80px; height: 80px; inset-inline-end: 92px; bottom: -28px; }
	.promo-sticker-big { font-size: 18px; }
	.promo-sticker-discount .promo-sticker-big { font-size: 21px; }
	.promo-badge { font-size: 12px; padding: 5px 12px; }
	.promo-strip { margin: 0 14px 4px; font-size: 11.5px; }
	.promo-banner { padding: 14px; }
	.promo-banner .promo-banner-line { font-size: 12.5px; }
}

@media (prefers-reduced-motion: reduce) {
	.promo-badge, .promo-badge::after, .promo-star, .plan-card.is-promo, .promo-banner::after,
	.promo-sticker, .promo-sticker-burst::after, .promo-sticker-spark { animation: none !important; }
	.promo-sticker { transform: rotate(var(--st-rot)); }
	.promo-star { opacity: .8; }
}
</style>

<script>
	/*
	 * Counts down every .promo-timer on the page. data-end and data-now are the
	 * server's clock, so a wrong clock on the phone does not matter.
	 */
	(function () {
		var timers = [];
		var started = Date.now();

		function pad(n) {
			return (n < 10 ? "0" : "") + n;
		}

		function tick() {
			timers.forEach(function (t) {
				var left = t.end - (t.now + Math.floor((Date.now() - started) / 1000));

				if (left <= 0) {
					if (t.scope) {
						t.scope.classList.add("promo-over");
					}
					return;
				}

				var d = Math.floor(left / 86400);
				var h = Math.floor(left % 86400 / 3600);
				var m = Math.floor(left % 3600 / 60);
				var s = left % 60;

				t.el.innerHTML = (d > 0 ? "<span>" + d + "<small>" + t.dayWord + "</small></span>" : "")
					+ "<span>" + pad(h) + "</span><span>" + pad(m) + "</span><span>" + pad(s) + "</span>";
			});
		}

		document.addEventListener("DOMContentLoaded", function () {
			document.querySelectorAll(".promo-timer[data-end]").forEach(function (el) {
				timers.push({
					el: el,
					end: parseInt(el.getAttribute("data-end"), 10),
					now: parseInt(el.getAttribute("data-now"), 10),
					dayWord: el.getAttribute("data-day") || "d",
					scope: el.closest("[data-promo-scope]")
				});
			});

			if (timers.length) {
				tick();
				window.setInterval(tick, 1000);
			}
		});
	})();
</script>
{/literal}
