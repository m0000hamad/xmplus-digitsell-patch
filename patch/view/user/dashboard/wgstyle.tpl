{*
  Shared by wg.tpl (the WireGuard card) and wgapp.tpl (WireGuard inside the
  apps card, possibly once per platform tab): styles and the key toggle.
  Everything is keyed on classes and data attributes, never ids, because the
  markup can be on the page more than once. A copy of ovpnstyle.tpl in
  WireGuard's own green.
*}
{literal}
<style>
.wg-card { border: 0; border-radius: 18px; }
.wg-card .card-header { background: transparent; }
.wg-badge {
	display: inline-flex;
	align-items: center;
	gap: 5px;
	padding: 4px 10px;
	border-radius: 999px;
	font-size: 11.5px;
	font-weight: 700;
	color: #047857;
	background: rgba(16, 185, 129, .13);
	white-space: nowrap;
}
.wg-intro { font-size: 13px; color: #5b6b86; margin-bottom: 16px; }
.wg-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(260px, 1fr)); gap: 16px; }
.wg-box {
	border-radius: 16px;
	padding: 15px;
	background: linear-gradient(135deg, rgba(15, 118, 110, .07), rgba(20, 184, 166, .08));
	border: 1.5px dashed rgba(15, 118, 110, .28);
}
.wg-box-title { font-size: 13.5px; font-weight: 700; color: #16203d; margin: 0 0 10px; display: flex; gap: 8px; align-items: center; }
.wg-num {
	flex: 0 0 auto;
	width: 24px;
	height: 24px;
	border-radius: 8px;
	display: inline-flex;
	align-items: center;
	justify-content: center;
	font-size: 12px;
	color: #fff;
	background: linear-gradient(135deg, #0f766e, #14b8a6);
}
.wg-cred { display: flex; align-items: center; gap: 8px; margin-bottom: 8px; }
.wg-cred-label { flex: 0 0 72px; font-size: 12px; color: #8c98ab; font-weight: 600; }
.wg-cred-value {
	flex: 1 1 auto;
	min-width: 0;
	direction: ltr;
	text-align: left;
	font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
	font-size: 14px;
	letter-spacing: .5px;
	background: #fff;
	border: 1px solid rgba(23, 32, 61, .12);
	border-radius: 10px;
	padding: 8px 11px;
	color: #16203d;
	overflow: hidden;
	text-overflow: ellipsis;
	white-space: nowrap;
}
.wg-icon-btn {
	flex: 0 0 auto;
	border: 0;
	width: 36px;
	height: 36px;
	border-radius: 10px;
	background: rgba(15, 118, 110, .12);
	color: #0d9488;
	cursor: pointer;
}
.wg-icon-btn:hover { background: rgba(15, 118, 110, .2); }
.wg-apps { display: flex; flex-wrap: wrap; gap: 8px; }
.wg-app {
	display: inline-flex;
	align-items: center;
	gap: 6px;
	padding: 8px 12px;
	border-radius: 11px;
	background: #fff;
	border: 1px solid rgba(23, 32, 61, .1);
	font-size: 12.5px;
	font-weight: 600;
	color: #16203d !important;
	text-decoration: none;
}
.wg-app:hover { border-color: #0f766e; }
.wg-servers { list-style: none; padding: 0; margin: 0; display: flex; flex-direction: column; gap: 8px; }
.wg-server {
	display: flex;
	flex-wrap: wrap;
	row-gap: 8px;
	align-items: center;
	gap: 10px;
	padding: 8px 10px;
	border-radius: 12px;
	background: #fff;
	border: 1px solid rgba(23, 32, 61, .1);
}
.wg-dot { width: 9px; height: 9px; border-radius: 50%; background: #10b981; flex: 0 0 auto; }
.wg-dot.is-down { background: #f43f5e; }
/* where the row is narrow (a phone, a third of a desktop card) the buttons
   wrap under the name instead of squeezing it away */
.wg-server-name { flex: 1 1 110px; font-size: 13px; font-weight: 600; color: #16203d; min-width: 0; overflow-wrap: anywhere; }
.wg-get {
	flex: 0 0 auto;
	display: inline-flex;
	align-items: center;
	gap: 6px;
	padding: 7px 12px;
	border-radius: 10px;
	background: linear-gradient(135deg, #0f766e, #14b8a6);
	color: #fff !important;
	font-size: 12px;
	font-weight: 700;
	text-decoration: none;
}
.wg-proto {
	flex: 0 0 auto;
	padding: 5px 9px;
	border-radius: 9px;
	font-size: 11px;
	font-weight: 700;
	letter-spacing: .4px;
	color: #0d9488 !important;
	background: rgba(15, 118, 110, .12);
	text-decoration: none;
}
.wg-proto:hover { background: rgba(15, 118, 110, .22); }
.wg-proto.is-static { background: rgba(23, 32, 61, .06); color: #5b6b86 !important; }
html[data-hs-theme="dark"] .wg-proto { color: #5eead4 !important; background: rgba(45, 212, 191, .18); }
html[data-hs-theme="dark"] .wg-proto.is-static { color: #b6c0d3 !important; background: rgba(255, 255, 255, .08); }
.wg-steps { margin: 0; padding-inline-start: 18px; font-size: 12.5px; color: #3b4a6b; line-height: 1.9; }
.wg-note { font-size: 11.5px; color: #8c98ab; margin-top: 10px; }

html[data-hs-theme="dark"] .wg-badge { color: #6ee7b7; background: rgba(16, 185, 129, .18); }
html[data-hs-theme="dark"] .wg-intro,
html[data-hs-theme="dark"] .wg-steps { color: #b6c0d3; }
html[data-hs-theme="dark"] .wg-box { background: linear-gradient(135deg, rgba(15, 118, 110, .12), rgba(20, 184, 166, .1)); border-color: rgba(45, 212, 191, .35); }
html[data-hs-theme="dark"] .wg-box-title,
html[data-hs-theme="dark"] .wg-server-name { color: #e7eaf3; }
html[data-hs-theme="dark"] .wg-cred-value,
html[data-hs-theme="dark"] .wg-app,
html[data-hs-theme="dark"] .wg-server { background: #1b2336; border-color: rgba(255, 255, 255, .1); color: #e7eaf3 !important; }
html[data-hs-theme="dark"] .wg-icon-btn { background: rgba(45, 212, 191, .18); color: #5eead4; }

@media (max-width: 575.98px) {
	.wg-cred-label { flex-basis: 56px; }
	.wg-cred-value { font-size: 13px; }
}
</style>
{/literal}
{literal}
<script>
(function () {
	if (window.wgToggleBound) { return; }
	window.wgToggleBound = true;

	document.addEventListener('click', function (event) {
		var button = event.target.closest ? event.target.closest('[data-wg-show]') : null;
		if (!button) { return; }

		var box = button.parentNode.querySelector('[data-wg-pass]');
		if (!box) { return; }

		var shown = box.getAttribute('data-shown') === '1';
		box.textContent = shown ? '••••••••••••' : box.getAttribute('data-wg-pass');
		box.setAttribute('data-shown', shown ? '0' : '1');
		button.innerHTML = shown ? '<i class="fa-regular fa-eye"></i>' : '<i class="fa-regular fa-eye-slash"></i>';
	});
})();
</script>
{/literal}
