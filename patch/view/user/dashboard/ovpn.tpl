{*
  OpenVPN on the same subscription (app/Patch/Ovpn.php). Included by
  dashboard.tpl only when User::ovpnEnabled() - the switch is on and at least
  one OpenVPN server serves this account's group. The generated profile embeds
  credentials derived from the current subscription token and is downloaded from
  /xmplus-patch.php?do=ovpn.profile&node=N, which checks the session again.
*}
{include file='user/dashboard/ovpnstyle.tpl'}

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
								{include file='user/dashboard/ovpnnode.tpl' node=$ovpnNode}
							{/foreach}
						</ul>
					</div>

					<div class="ovpn-box">
						<h5 class="ovpn-box-title"><span class="ovpn-num">3</span>{$translate->get('OvpnStepLogin')}</h5>
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
