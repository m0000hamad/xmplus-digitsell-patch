{*
  OpenVPN on the same subscription (app/Patch/Ovpn.php). Included by
  dashboard.tpl only when User::ovpnEnabled() - the switch is on and at least
  one OpenVPN server serves this account's group. The login and password come
  from the model; the profile is downloaded from
  /xmplus-patch.php?do=ovpn.profile&node=N, which checks the session again.
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

<div class="row">
	<div class="col-12 mb-4">
		<div class="card card-shadow shadow-lg rounded ovpn-card" id="ovpnCard">
			<div class="card-header card-header-content-between border-bottom">
				<h4 class="card-header-title mb-0">🛡️ {$translate->get('OvpnTitle')}</h4>
				<span class="ovpn-badge">🔗 {$translate->get('OvpnSameSub')}</span>
			</div>
			<div class="card-body">
				<p class="ovpn-intro">{$translate->get('OvpnIntro')}</p>

				<div class="ovpn-grid">
					<div class="ovpn-box">
						<h5 class="ovpn-box-title"><span class="ovpn-num">1</span>{$translate->get('OvpnStepApp')}</h5>
						<div class="ovpn-apps">
							<a class="ovpn-app" href="https://play.google.com/store/apps/details?id=net.openvpn.openvpn" target="_blank" rel="noopener">🤖 Android</a>
							<a class="ovpn-app" href="https://apps.apple.com/app/openvpn-connect/id590379981" target="_blank" rel="noopener">📱 iPhone / iPad</a>
							<a class="ovpn-app" href="https://openvpn.net/client/" target="_blank" rel="noopener">💻 Windows / Mac</a>
						</div>
						<p class="ovpn-note">{$translate->get('OvpnAppHint')}</p>
					</div>

					<div class="ovpn-box">
						<h5 class="ovpn-box-title"><span class="ovpn-num">2</span>{$translate->get('OvpnStepProfile')}</h5>
						<ul class="ovpn-servers">
							{foreach $user->ovpnNodes() as $ovpnNode}
								<li class="ovpn-server">
									<span class="ovpn-dot{if !$ovpnNode.live} is-down{/if}" title="{if $ovpnNode.live}{$translate->get('OvpnServerUp')}{else}{$translate->get('OvpnServerDown')}{/if}"></span>
									<span class="ovpn-server-name">{$ovpnNode.name}</span>
									<a class="ovpn-get" href="/xmplus-patch.php?do=ovpn.profile&amp;node={$ovpnNode.id}" download>⬇️ {$translate->get('OvpnDownload')}</a>
								</li>
							{/foreach}
						</ul>
					</div>

					<div class="ovpn-box">
						<h5 class="ovpn-box-title"><span class="ovpn-num">3</span>{$translate->get('OvpnStepLogin')}</h5>
						<div class="ovpn-cred">
							<span class="ovpn-cred-label">{$translate->get('OvpnUsername')}</span>
							<span class="ovpn-cred-value">{$user->ovpnLogin()}</span>
							<button type="button" class="ovpn-icon-btn copy-text" data-clipboard-text="{$user->ovpnLogin()}" title="{$translate->get('OvpnCopy')}"><i class="fa-regular fa-copy"></i></button>
						</div>
						<div class="ovpn-cred">
							<span class="ovpn-cred-label">{$translate->get('OvpnPassword')}</span>
							<span class="ovpn-cred-value" id="ovpnPass" data-pass="{$user->ovpnPassword()}">••••••••••••</span>
							<button type="button" class="ovpn-icon-btn" id="ovpnPassShow" title="{$translate->get('OvpnShow')}"><i class="fa-regular fa-eye"></i></button>
							<button type="button" class="ovpn-icon-btn copy-text" data-clipboard-text="{$user->ovpnPassword()}" title="{$translate->get('OvpnCopy')}"><i class="fa-regular fa-copy"></i></button>
						</div>
						<ol class="ovpn-steps">
							<li>{$translate->get('OvpnHow1')}</li>
							<li>{$translate->get('OvpnHow2')}</li>
							<li>{$translate->get('OvpnHow3')}</li>
						</ol>
						<p class="ovpn-note">{$translate->get('OvpnResetNote')}</p>
					</div>
				</div>
			</div>
		</div>
	</div>
</div>

{literal}
<script>
(function () {
	var box = document.getElementById('ovpnPass');
	var button = document.getElementById('ovpnPassShow');
	if (!box || !button) { return; }

	button.addEventListener('click', function () {
		var shown = box.getAttribute('data-shown') === '1';
		box.textContent = shown ? '••••••••••••' : box.getAttribute('data-pass');
		box.setAttribute('data-shown', shown ? '0' : '1');
		button.innerHTML = shown ? '<i class="fa-regular fa-eye"></i>' : '<i class="fa-regular fa-eye-slash"></i>';
	});
})();
</script>
{/literal}
