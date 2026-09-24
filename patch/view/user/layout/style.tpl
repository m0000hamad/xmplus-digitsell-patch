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

/* the countdown used .text-dark, which vanished on the dark bar */
.countdown-pill {
	display: inline-flex;
	align-items: center;
	padding: 7px 13px;
	border-radius: 12px;
	font-size: 13px;
	font-weight: 800;
	letter-spacing: .3px;
	direction: ltr;
	unicode-bidi: isolate;
	color: #b45309;
	background: rgba(245, 158, 11, .14);
	border: 1px solid rgba(245, 158, 11, .3);
}
html[data-hs-theme="dark"] .countdown-pill {
	color: #fcd34d;
	background: rgba(245, 158, 11, .17);
	border-color: rgba(245, 158, 11, .34);
}

@media (max-width: 575.98px) {
	.navbar-nav-wrap-content-start { margin-inline-start: 9px; padding-inline-start: 9px; }
	.countdown-pill { padding: 6px 10px; font-size: 12px; }
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
