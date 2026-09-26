<style>
	.nav-pills .nav-item .nav-link.active {
		background-color: var(--bs-dark);
		color:var(--bs-body-bg);
	}
	
	.match-height > [class*='col'] {
	  display : -webkit-box;
	  display : -webkit-flex;
	  display : -ms-flexbox;
	  display :         flex;
	  -webkit-box-orient : vertical;
	  -webkit-box-direction : normal;
	  -webkit-flex-flow : column;
		  -ms-flex-flow : column;
			  flex-flow : column;
	}

	.match-height > [class*='col'] > .card {
	  -webkit-box-flex : 1;
	  -webkit-flex : 1 1 auto;
		  -ms-flex : 1 1 auto;
			  flex : 1 1 auto;
	}
	.overflow-text { 
		text-overflow: ellipsis;
		overflow: hidden; 
		width: 60%;  
		white-space: nowrap;
		display:inline-block;
	}	

	.nav-vertical.nav-tabs .nav-item.show>.nav-link, .nav-vertical.nav-tabs .nav-link.active {
		border-color: var(--bs-dark);
	}

	.nav-tabs .nav-item.show .nav-link, .nav-tabs .nav-link.active {
		color: var(--bs-dark);
		background-color: var(--bs-nav-tabs-link-active-bg);
		border-color: var(--bs-dark);
	}

	.nav-link.active, .navbar-nav .nav-link.active {
		color: var(--bs-dark);
	}	
	
	@media (min-width: 992px) {
		.col-lg-divider>:not(:first-child) {
			position:relative
		}

		.col-lg-divider>:not(:first-child)::before {
			position: absolute;
			top: 0;
			right: 0;
			width: .0625rem;
			height: 100%;
			background-color: rgba(231,234,243,.7);
			content: ""
		}
	}
</style>

{literal}
<style>
/* ================================================================== *
 * Sidebar and its toggle.
 *
 * The hamburger used to be a bare dark icon on a white bar, so most
 * visitors never noticed the site had a menu at all. It is now a glass
 * pill with a written label and a short attention pulse, and the menu
 * behind it got a translucent tint per section.
 * ================================================================== */

/* ---- the toggle ---- */
/* menu-pill-fixed */
.navbar-aside-toggler {
	position: relative;
	width: auto !important;
	height: auto !important;
	min-width: 0 !important;
	display: inline-flex !important;
	align-items: center;
	justify-content: center;
	gap: 8px;
	min-height: 42px;
	padding: 8px 14px !important;
	border: 1.5px solid rgba(99, 102, 241, .45) !important;
	border-radius: 15px !important;
	background: linear-gradient(135deg, rgba(99, 102, 241, .17), rgba(168, 85, 247, .17)) !important;
	color: #4f46e5 !important;
	font-size: 15px;
	line-height: 1;
	cursor: pointer;
	-webkit-backdrop-filter: blur(12px) saturate(170%);
	backdrop-filter: blur(12px) saturate(170%);
	box-shadow: 0 5px 16px rgba(99, 102, 241, .2), inset 0 1px 0 rgba(255, 255, 255, .65);
	transition: background .16s ease, box-shadow .16s ease, transform .16s ease;
}
.navbar-aside-toggler:hover {
	background: linear-gradient(135deg, rgba(99, 102, 241, .27), rgba(168, 85, 247, .27)) !important;
	box-shadow: 0 8px 22px rgba(99, 102, 241, .3), inset 0 1px 0 rgba(255, 255, 255, .7);
}
.navbar-aside-toggler:active { transform: scale(.96); }
.navbar-aside-toggler i { color: #4f46e5 !important; font-size: 16px; }

.navbar-aside-toggler-label {
	font-size: 13px;
	font-weight: 800;
	letter-spacing: .2px;
	color: #4f46e5;
	white-space: nowrap;
}


html[data-hs-theme="dark"] .navbar-aside-toggler {
	border-color: rgba(165, 180, 252, .42) !important;
	background: linear-gradient(135deg, rgba(129, 140, 248, .22), rgba(192, 132, 252, .22)) !important;
	box-shadow: 0 5px 16px rgba(0, 0, 0, .35), inset 0 1px 0 rgba(255, 255, 255, .14);
}
html[data-hs-theme="dark"] .navbar-aside-toggler i,
html[data-hs-theme="dark"] .navbar-aside-toggler-label { color: #c7d2fe !important; }

/* the sidebar carries its own copy on a dark ground */
.navbar-vertical-aside .navbar-aside-toggler {
	border-color: rgba(255, 255, 255, .22) !important;
	background: rgba(255, 255, 255, .1) !important;
	box-shadow: none;
}
.navbar-vertical-aside .navbar-aside-toggler i { color: #dbe1ff !important; }

/* ---- the sidebar itself ---- */
.navbar-vertical-aside {
	background: linear-gradient(180deg, rgba(22, 30, 58, .93), rgba(15, 21, 42, .96)) !important;
	-webkit-backdrop-filter: blur(20px) saturate(150%);
	backdrop-filter: blur(20px) saturate(150%);
	border-inline-end: 1px solid rgba(255, 255, 255, .07);
}
.navbar-vertical-aside .navbar-vertical-footer {
	background: rgba(255, 255, 255, .04);
	border-top: 1px solid rgba(255, 255, 255, .07);
}

/* ---- section captions ---- */
#navbarVerticalMenu .dropdown-header {
	color: rgba(255, 255, 255, .4) !important;
	font-size: 10.5px;
	font-weight: 800;
	letter-spacing: .7px;
	text-transform: uppercase;
	padding-inline: 20px;
	margin-top: 17px !important;
	margin-bottom: 3px;
}

/* ---- the items ---- */
#navbarVerticalMenu .nav-item {
	--mc: #6366f1;
	--mcs: rgba(99, 102, 241, .12);
	--mch: rgba(99, 102, 241, .24);
}
#navbarVerticalMenu .nav-link {
	display: flex;
	align-items: center;
	margin: 4px 11px;
	padding: 9px 11px !important;
	border-radius: 14px;
	background: var(--mcs);
	border: 1px solid transparent;
	color: rgba(255, 255, 255, .82) !important;
	font-size: 13.5px;
	font-weight: 600;
	transition: background .16s ease, border-color .16s ease, transform .16s ease, box-shadow .16s ease;
}
#navbarVerticalMenu .nav-link:hover {
	background: var(--mch);
	border-color: var(--mc);
	color: #fff !important;
	transform: translateY(-1px);
}
#navbarVerticalMenu .nav-icon {
	flex: 0 0 auto;
	width: 31px;
	height: 31px;
	border-radius: 11px;
	background: var(--mch);
	color: var(--mc) !important;
	display: inline-flex;
	align-items: center;
	justify-content: center;
	font-size: 14px;
	margin-inline-end: 10px;
	margin-block: 0;
	transition: background .16s ease, color .16s ease;
}
/* the icons are emoji now, so they carry their own colour */
#navbarVerticalMenu .nav-sticker {
	font-size: 16px;
	line-height: 1;
	filter: saturate(115%);
	transition: transform .16s ease;
}
#navbarVerticalMenu .nav-link:hover .nav-sticker { transform: scale(1.14) rotate(-5deg); }
#navbarVerticalMenu .nav-link-title { line-height: 1.4; }

/* the page you are on */
#navbarVerticalMenu .nav-link.nav-here {
	background: var(--mc);
	border-color: var(--mc);
	color: #fff !important;
	box-shadow: 0 7px 18px var(--mch);
}
#navbarVerticalMenu .nav-link.nav-here .nav-icon {
	background: rgba(255, 255, 255, .22);
	color: #fff !important;
}
#navbarVerticalMenu .nav-link.nav-here::after {
	content: "";
	width: 5px;
	height: 5px;
	border-radius: 50%;
	background: #fff;
	margin-inline-start: auto;
	flex: 0 0 auto;
}

/* the mini rail keeps only the icon, so the pill has to shrink with it */
.navbar-vertical-aside-mini-mode #navbarVerticalMenu .nav-link {
	justify-content: center;
	margin-inline: 9px;
	padding: 9px 6px !important;
}
.navbar-vertical-aside-mini-mode #navbarVerticalMenu .nav-icon { margin-inline-end: 0; }
.navbar-vertical-aside-mini-mode #navbarVerticalMenu .nav-link.nav-here::after { display: none; }

/* ---- footer buttons ---- */
.navbar-vertical-footer-list-item .btn-icon {
	border: 1px solid rgba(255, 255, 255, .16) !important;
	background: rgba(255, 255, 255, .08) !important;
	-webkit-backdrop-filter: blur(8px);
	backdrop-filter: blur(8px);
	transition: background .16s ease, transform .16s ease;
}
.navbar-vertical-footer-list-item .btn-icon:hover {
	background: rgba(255, 255, 255, .17) !important;
	transform: translateY(-1px);
}

@media (max-width: 575.98px) {
	.navbar-aside-toggler { padding: 8px 12px !important; }
	.navbar-aside-toggler-label { font-size: 12.5px; }
}
</style>
{/literal}

{literal}
<style>
/* the toggle now carries words only, and needs to clear the logo */
.navbar-nav-wrap-content-start {
	margin-inline-start: 14px;
	padding-inline-start: 14px;
	border-inline-start: 1px solid rgba(23, 32, 61, .12);
}
html[data-hs-theme="dark"] .navbar-nav-wrap-content-start {
	border-inline-start-color: rgba(255, 255, 255, .13);
}

/* countdown: an old LCD watch face (DSEG7, embedded so it needs no asset path);
   the frame colour follows the time left, like the traffic bar */
@font-face {
	font-family: "cd-seg";
	font-weight: 700;
	font-display: block;
	src: url(data:font/woff2;base64,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) format("woff2");
}
.countdown-pill {
	--cd: #22c55e;
	--cd-rgb: 34, 197, 94;
	display: inline-flex;
	align-items: center;
	gap: 7px;
	padding: 5px 11px;
	border-radius: 6px;
	direction: ltr;
	unicode-bidi: isolate;
	color: #1b2416;
	background: linear-gradient(#b3c2a3, #8fa07f);
	border: 3px solid var(--cd);
	box-shadow: inset 0 2px 5px rgba(0, 0, 0, .35), 0 0 8px rgba(var(--cd-rgb), .55);
	font: 700 12px/1 Tahoma, sans-serif;
	transition: border-color .4s, box-shadow .4s;
}
/* on phones the theme stacks and squeezes .navbar-nav, which left only the frame (a dot) */
.navbar-nav-wrap-content-end:has(.countdown-pill) { flex-shrink: 0; min-width: max-content; }
.countdown-pill {
	flex-direction: row !important;
	flex-wrap: nowrap !important;
	flex-shrink: 0;
	min-width: max-content;
	white-space: nowrap;
	overflow: visible;
}
.countdown-pill .cd-g { display: inline-flex !important; align-items: baseline; gap: 2px; visibility: visible; }
.countdown-pill .cd-n, .countdown-pill .cd-u { display: inline-block !important; }
.countdown-pill .cd-n { position: relative; font: 700 17px/1 "cd-seg", monospace; }
.countdown-pill .cd-off { position: absolute; inset: 0; color: rgba(0, 0, 0, .09); }
.countdown-pill .cd-u { font: 800 9px/1 Tahoma, sans-serif; opacity: .8; }
.countdown-pill.cd-ok   { --cd: #22c55e; --cd-rgb: 34, 197, 94; }
.countdown-pill.cd-mid  { --cd: #facc15; --cd-rgb: 250, 204, 21; }
.countdown-pill.cd-low  { --cd: #f97316; --cd-rgb: 249, 115, 22; }
.countdown-pill.cd-crit,
.countdown-pill.cd-dead { --cd: #ef4444; --cd-rgb: 239, 68, 68; }
.countdown-pill.cd-crit { animation: cd-pulse 1.1s ease-in-out infinite; }
@keyframes cd-pulse {
	50% { box-shadow: inset 0 2px 5px rgba(0, 0, 0, .35), 0 0 16px rgba(var(--cd-rgb), 1); }
}
@media (prefers-reduced-motion: reduce) { .countdown-pill.cd-crit { animation: none; } }

@media (max-width: 575.98px) {
	.navbar-nav-wrap-content-start { margin-inline-start: 9px; padding-inline-start: 9px; }
	.countdown-pill { padding: 4px 8px; gap: 5px; }
	.countdown-pill .cd-n { font-size: 14px; }
}
</style>
{/literal}

{literal}
<style>
/* ---- phones and tablets: the panel used to swallow its own switch ---- */
.toggler-label-close { display: none; }

@media (max-width: 1199.98px) {
	#header {
		z-index: 1001 !important;
	}

	/* the bar already shows the logo, the panel need not repeat it */
	.navbar-vertical-aside .navbar-brand { display: none !important; }

	/* and the panel starts below the bar instead of under it */
	.navbar-vertical-aside .navbar-vertical-container { padding-top: 64px; }

	/* while it is open the button is a close button, so it should say so */
	body.has-navbar-vertical-aside:not(.navbar-vertical-aside-closed-mode) .toggler-label-close {
		display: inline;
	}
	body.has-navbar-vertical-aside:not(.navbar-vertical-aside-closed-mode)
		.navbar-aside-toggler-label:not(.toggler-label-close) {
		display: none;
	}
	body.has-navbar-vertical-aside:not(.navbar-vertical-aside-closed-mode) .navbar-aside-toggler {
		border-color: rgba(244, 63, 94, .45) !important;
		background: linear-gradient(135deg, rgba(244, 63, 94, .17), rgba(236, 72, 153, .17)) !important;
	}
	body.has-navbar-vertical-aside:not(.navbar-vertical-aside-closed-mode) .toggler-label-close {
		color: #be123c;
	}
	html[data-hs-theme="dark"] body.has-navbar-vertical-aside:not(.navbar-vertical-aside-closed-mode) .toggler-label-close {
		color: #fda4af;
	}
}
</style>
{/literal}

{literal}
<style>
/* ================= sidebar in day mode ================= */
.navbar-vertical-aside {
	background: linear-gradient(180deg, rgba(255, 255, 255, .93), rgba(244, 247, 252, .96)) !important;
	border-inline-end: 1px solid rgba(23, 32, 61, .09);
}
.navbar-vertical-aside .navbar-vertical-footer {
	background: rgba(23, 32, 61, .035);
	border-top: 1px solid rgba(23, 32, 61, .08);
}

#navbarVerticalMenu .dropdown-header { color: rgba(23, 32, 61, .42) !important; }
#navbarVerticalMenu .nav-link { color: #16203d !important; }
#navbarVerticalMenu .nav-link:hover { color: #0b1226 !important; }
#navbarVerticalMenu .nav-link.nav-here { color: #fff !important; }

/* these buttons carry .text-white in the markup, which day mode cannot use */
.navbar-vertical-footer-list-item .btn-icon,
.navbar-vertical-footer-list-item .btn-icon i {
	color: #16203d !important;
}
.navbar-vertical-footer-list-item .btn-icon {
	border-color: rgba(23, 32, 61, .12) !important;
	background: rgba(23, 32, 61, .05) !important;
}
.navbar-vertical-footer-list-item .btn-icon:hover {
	background: rgba(23, 32, 61, .1) !important;
}

/* ================= and back to night ================= */
html[data-hs-theme="dark"] .navbar-vertical-aside {
	background: linear-gradient(180deg, rgba(22, 30, 58, .93), rgba(15, 21, 42, .96)) !important;
	border-inline-end-color: rgba(255, 255, 255, .07);
}
html[data-hs-theme="dark"] .navbar-vertical-aside .navbar-vertical-footer {
	background: rgba(255, 255, 255, .04);
	border-top-color: rgba(255, 255, 255, .07);
}
html[data-hs-theme="dark"] #navbarVerticalMenu .dropdown-header { color: rgba(255, 255, 255, .4) !important; }
html[data-hs-theme="dark"] #navbarVerticalMenu .nav-link { color: rgba(255, 255, 255, .82) !important; }
html[data-hs-theme="dark"] #navbarVerticalMenu .nav-link:hover { color: #fff !important; }
html[data-hs-theme="dark"] .navbar-vertical-footer-list-item .btn-icon,
html[data-hs-theme="dark"] .navbar-vertical-footer-list-item .btn-icon i {
	color: #e7eaf3 !important;
}
html[data-hs-theme="dark"] .navbar-vertical-footer-list-item .btn-icon {
	border-color: rgba(255, 255, 255, .16) !important;
	background: rgba(255, 255, 255, .08) !important;
}
html[data-hs-theme="dark"] .navbar-vertical-footer-list-item .btn-icon:hover {
	background: rgba(255, 255, 255, .17) !important;
}
</style>
{/literal}

{literal}
<style>
/* ============ day mode, with the colour actually turned on ============ */
.navbar-vertical-aside {
	background:
		radial-gradient(120% 55% at 50% 0%, rgba(99, 102, 241, .13), transparent 70%),
		linear-gradient(180deg, #ffffff, #eef1f8) !important;
	border-inline-end: 1px solid rgba(23, 32, 61, .1);
	box-shadow: inset 0 1px 0 rgba(255, 255, 255, .9);
}

#navbarVerticalMenu .nav-link {
	background: linear-gradient(135deg, var(--mch), var(--mcs));
	border: 1px solid var(--mch);
	color: var(--mcd, #16203d) !important;
	font-weight: 700;
}
#navbarVerticalMenu .nav-link:hover {
	background: linear-gradient(135deg, var(--mc), var(--mch));
	border-color: var(--mc);
	color: #fff !important;
	box-shadow: 0 7px 18px var(--mch);
}
#navbarVerticalMenu .nav-link:hover .nav-icon {
	background: rgba(255, 255, 255, .3);
	color: #fff !important;
}

#navbarVerticalMenu .nav-icon {
	background: rgba(255, 255, 255, .72);
	color: var(--mcd, #6366f1) !important;
	box-shadow: 0 2px 6px var(--mcs);
}

#navbarVerticalMenu .nav-link.nav-here {
	background: linear-gradient(135deg, var(--mc), var(--mcd));
	border-color: var(--mcd);
	color: #fff !important;
	box-shadow: 0 9px 22px var(--mch);
}
#navbarVerticalMenu .nav-link.nav-here .nav-icon {
	background: rgba(255, 255, 255, .26);
	color: #fff !important;
}

/* the captions get a hairline so the groups read as groups */
#navbarVerticalMenu .dropdown-header {
	color: rgba(23, 32, 61, .5) !important;
	display: flex;
	align-items: center;
	gap: 9px;
}
#navbarVerticalMenu .dropdown-header::after {
	content: "";
	flex: 1 1 auto;
	height: 1px;
	background: linear-gradient(90deg, rgba(23, 32, 61, .16), transparent);
}

/* ============ night keeps its calmer reading ============ */
html[data-hs-theme="dark"] .navbar-vertical-aside {
	background:
		radial-gradient(120% 55% at 50% 0%, rgba(129, 140, 248, .16), transparent 70%),
		linear-gradient(180deg, rgba(22, 30, 58, .95), rgba(15, 21, 42, .97)) !important;
	border-inline-end-color: rgba(255, 255, 255, .07);
	box-shadow: none;
}
html[data-hs-theme="dark"] #navbarVerticalMenu .nav-link {
	background: var(--mcs);
	border-color: transparent;
	color: rgba(255, 255, 255, .84) !important;
}
html[data-hs-theme="dark"] #navbarVerticalMenu .nav-link:hover {
	background: var(--mch);
	border-color: var(--mc);
	color: #fff !important;
	box-shadow: none;
}
html[data-hs-theme="dark"] #navbarVerticalMenu .nav-icon {
	background: var(--mch);
	color: var(--mc) !important;
	box-shadow: none;
}
html[data-hs-theme="dark"] #navbarVerticalMenu .nav-link:hover .nav-icon {
	background: rgba(255, 255, 255, .2);
	color: #fff !important;
}
html[data-hs-theme="dark"] #navbarVerticalMenu .nav-link.nav-here {
	background: var(--mc);
	border-color: var(--mc);
	box-shadow: 0 7px 18px var(--mch);
}
html[data-hs-theme="dark"] #navbarVerticalMenu .dropdown-header {
	color: rgba(255, 255, 255, .42) !important;
}
html[data-hs-theme="dark"] #navbarVerticalMenu .dropdown-header::after {
	background: linear-gradient(90deg, rgba(255, 255, 255, .16), transparent);
}
</style>
{/literal}

{literal}
<style>
/* ================= menu items light up like a lamp on hover =================
   Each item already carries its own colour in --mc. On hover a bulb of that
   colour switches on behind the icon - with the short flicker of a lamp
   catching - and its light spreads across the pill from the icon's side.
   The light stays inside the pill; only a thin halo of the same colour sits
   around its edge. */
#navbarVerticalMenu .nav-link {
	position: relative;
	overflow: hidden;
	isolation: isolate;
}
#navbarVerticalMenu .nav-link > * { position: relative; z-index: 1; }
/* the light itself, anchored on the icon's side whichever way the page runs */
#navbarVerticalMenu .nav-link::before {
	content: "";
	position: absolute;
	top: 50%;
	inset-inline-start: -30px;
	width: 170px;
	height: 170px;
	margin-top: -85px;
	border-radius: 50%;
	background: radial-gradient(circle, color-mix(in srgb, var(--mc) 60%, #fff) 0%, color-mix(in srgb, var(--mc) 45%, transparent) 28%, transparent 62%);
	opacity: 0;
	transform: scale(.55);
	transition: opacity .22s ease, transform .35s cubic-bezier(.2, .8, .2, 1);
	pointer-events: none;
	z-index: 0;
}
#navbarVerticalMenu .nav-link:hover::before,
#navbarVerticalMenu .nav-link:focus-visible::before {
	opacity: .55;
	transform: scale(1);
	animation: navLampOn .45s steps(1, end) 1;
}
#navbarVerticalMenu .nav-link:hover,
#navbarVerticalMenu .nav-link:focus-visible {
	border-color: var(--mc);
	box-shadow: 0 0 0 1px color-mix(in srgb, var(--mc) 35%, transparent), 0 0 14px -2px var(--mc);
}
/* the bulb: the icon tile turns into a lit lamp */
#navbarVerticalMenu .nav-link:hover .nav-icon,
#navbarVerticalMenu .nav-link:focus-visible .nav-icon {
	background: radial-gradient(circle at 50% 40%, #fff 0%, color-mix(in srgb, var(--mc) 55%, #fff) 35%, var(--mc) 100%);
	box-shadow: 0 0 10px 1px var(--mc), inset 0 0 6px rgba(255, 255, 255, .7);
}
#navbarVerticalMenu .nav-link:hover .nav-sticker,
#navbarVerticalMenu .nav-link:focus-visible .nav-sticker {
	filter: saturate(125%) drop-shadow(0 0 5px rgba(255, 255, 255, .85));
}
/* a lamp catching: two quick flickers, then steady */
@keyframes navLampOn {
	0%   { opacity: .15; }
	18%  { opacity: .6; }
	30%  { opacity: .2; }
	48%  { opacity: .55; }
	60%  { opacity: .3; }
	100% { opacity: .55; }
}

/* at night the lamp is brighter and the text catches its light */
html[data-hs-theme="dark"] #navbarVerticalMenu .nav-link:hover::before,
html[data-hs-theme="dark"] #navbarVerticalMenu .nav-link:focus-visible::before { opacity: .8; }
html[data-hs-theme="dark"] #navbarVerticalMenu .nav-link:hover,
html[data-hs-theme="dark"] #navbarVerticalMenu .nav-link:focus-visible {
	box-shadow: 0 0 0 1px color-mix(in srgb, var(--mc) 55%, transparent), 0 0 18px -2px var(--mc);
}
html[data-hs-theme="dark"] #navbarVerticalMenu .nav-link:hover .nav-link-title {
	text-shadow: 0 0 10px color-mix(in srgb, var(--mc) 70%, #fff);
}
@keyframes navLampOnNight {
	0%   { opacity: .2; }
	18%  { opacity: .85; }
	30%  { opacity: .25; }
	48%  { opacity: .8; }
	60%  { opacity: .4; }
	100% { opacity: .8; }
}
html[data-hs-theme="dark"] #navbarVerticalMenu .nav-link:hover::before { animation-name: navLampOnNight; }

/* the page you are on is already lit; keep its solid pill readable */
#navbarVerticalMenu .nav-link.nav-here::before { display: none; }

@media (prefers-reduced-motion: reduce) {
	#navbarVerticalMenu .nav-link::before { transition: opacity .2s ease; transform: none; animation: none !important; }
}
</style>
{/literal}
