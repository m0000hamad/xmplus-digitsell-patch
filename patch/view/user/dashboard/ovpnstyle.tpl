{*
  Shared by ovpn.tpl (the OpenVPN card) and ovpnapp.tpl (OpenVPN inside the
  apps card, possibly once per platform tab): styles and the password toggle.
  Everything is keyed on classes and data attributes, never ids, because the
  markup can be on the page more than once.
*}
{literal}
<style>
.ovpn-card { border: 0; border-radius: 18px; }
.ovpn-card .card-header { background: transparent; }
.ovpn-badge {
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
.ovpn-intro { font-size: 13px; color: #5b6b86; margin-bottom: 16px; }
.ovpn-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(260px, 1fr)); gap: 16px; }
.ovpn-box {
	border-radius: 16px;
	padding: 15px;
	background: linear-gradient(135deg, rgba(234, 88, 12, .07), rgba(245, 158, 11, .08));
	border: 1.5px dashed rgba(234, 88, 12, .28);
}
.ovpn-box-title { font-size: 13.5px; font-weight: 700; color: #16203d; margin: 0 0 10px; display: flex; gap: 8px; align-items: center; }
.ovpn-num {
	flex: 0 0 auto;
	width: 24px;
	height: 24px;
	border-radius: 8px;
	display: inline-flex;
	align-items: center;
	justify-content: center;
	font-size: 12px;
	color: #fff;
	background: linear-gradient(135deg, #ea580c, #f59e0b);
}
.ovpn-cred { display: flex; align-items: center; gap: 8px; margin-bottom: 8px; }
.ovpn-cred-label { flex: 0 0 72px; font-size: 12px; color: #8c98ab; font-weight: 600; }
.ovpn-cred-value {
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
.ovpn-icon-btn {
	flex: 0 0 auto;
	border: 0;
	width: 36px;
	height: 36px;
	border-radius: 10px;
	background: rgba(234, 88, 12, .12);
	color: #c2410c;
	cursor: pointer;
}
.ovpn-icon-btn:hover { background: rgba(234, 88, 12, .2); }
.ovpn-apps { display: flex; flex-wrap: wrap; gap: 8px; }
.ovpn-app {
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
.ovpn-app:hover { border-color: #ea580c; }
.ovpn-servers { list-style: none; padding: 0; margin: 0; display: flex; flex-direction: column; gap: 8px; }
.ovpn-server {
	display: flex;
	align-items: center;
	gap: 10px;
	padding: 8px 10px;
	border-radius: 12px;
	background: #fff;
	border: 1px solid rgba(23, 32, 61, .1);
}
.ovpn-dot { width: 9px; height: 9px; border-radius: 50%; background: #10b981; flex: 0 0 auto; }
.ovpn-dot.is-down { background: #f43f5e; }
.ovpn-server-name { flex: 1 1 auto; font-size: 13px; font-weight: 600; color: #16203d; min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.ovpn-get {
	flex: 0 0 auto;
	display: inline-flex;
	align-items: center;
	gap: 6px;
	padding: 7px 12px;
	border-radius: 10px;
	background: linear-gradient(135deg, #ea580c, #f59e0b);
	color: #fff !important;
	font-size: 12px;
	font-weight: 700;
	text-decoration: none;
}
.ovpn-steps { margin: 0; padding-inline-start: 18px; font-size: 12.5px; color: #3b4a6b; line-height: 1.9; }
.ovpn-note { font-size: 11.5px; color: #8c98ab; margin-top: 10px; }

html[data-hs-theme="dark"] .ovpn-badge { color: #6ee7b7; background: rgba(16, 185, 129, .18); }
html[data-hs-theme="dark"] .ovpn-intro,
html[data-hs-theme="dark"] .ovpn-steps { color: #b6c0d3; }
html[data-hs-theme="dark"] .ovpn-box { background: linear-gradient(135deg, rgba(234, 88, 12, .12), rgba(245, 158, 11, .1)); border-color: rgba(251, 146, 60, .35); }
html[data-hs-theme="dark"] .ovpn-box-title,
html[data-hs-theme="dark"] .ovpn-server-name { color: #e7eaf3; }
html[data-hs-theme="dark"] .ovpn-cred-value,
html[data-hs-theme="dark"] .ovpn-app,
html[data-hs-theme="dark"] .ovpn-server { background: #1b2336; border-color: rgba(255, 255, 255, .1); color: #e7eaf3 !important; }
html[data-hs-theme="dark"] .ovpn-icon-btn { background: rgba(251, 146, 60, .18); color: #fdba74; }

@media (max-width: 575.98px) {
	.ovpn-cred-label { flex-basis: 56px; }
	.ovpn-cred-value { font-size: 13px; }
}
</style>
{/literal}
{literal}
<script>
(function () {
	if (window.ovpnToggleBound) { return; }
	window.ovpnToggleBound = true;

	document.addEventListener('click', function (event) {
		var button = event.target.closest ? event.target.closest('[data-ovpn-show]') : null;
		if (!button) { return; }

		var box = button.parentNode.querySelector('[data-ovpn-pass]');
		if (!box) { return; }

		var shown = box.getAttribute('data-shown') === '1';
		box.textContent = shown ? '••••••••••••' : box.getAttribute('data-ovpn-pass');
		box.setAttribute('data-shown', shown ? '0' : '1');
		button.innerHTML = shown ? '<i class="fa-regular fa-eye"></i>' : '<i class="fa-regular fa-eye-slash"></i>';
	});
})();
</script>
{/literal}
