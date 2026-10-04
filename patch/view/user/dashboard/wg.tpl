{*
  WireGuard on the same subscription (app/Patch/Wg.php). Included by
  dashboard.tpl only when User::wgEnabled() - the switch is on and at least
  one WireGuard server serves this account's group. The file is downloaded
  from /xmplus-patch.php?do=wg.profile&node=N, which checks the account again.
*}
{include file='user/dashboard/wgstyle.tpl'}

<div class="row">
	<div class="col-12 mb-4">
		<div class="card card-shadow shadow-lg rounded wg-card" id="wgCard">
			<div class="card-header card-header-content-between border-bottom">
				<h4 class="card-header-title mb-0">🛡️ {$translate->get('WgTitle')}</h4>
				<span class="wg-badge">🔗 {$translate->get('WgSameSub')}</span>
			</div>
			<div class="card-body">
				<p class="wg-intro">{$translate->get('WgIntro')}</p>

				<div class="wg-grid">
					<div class="wg-box">
						<h5 class="wg-box-title"><span class="wg-num">1</span>{$translate->get('WgStepApp')}</h5>
						<div class="wg-apps">
							<a class="wg-app" href="https://play.google.com/store/apps/details?id=com.wireguard.android" target="_blank" rel="noopener">🤖 Android</a>
							<a class="wg-app" href="https://apps.apple.com/app/wireguard/id1431205801" target="_blank" rel="noopener">📱 iPhone / iPad</a>
							<a class="wg-app" href="https://www.wireguard.com/install/" target="_blank" rel="noopener">💻 Windows / Mac</a>
						</div>
						<p class="wg-note">{$translate->get('WgAppHint')}</p>
					</div>

					<div class="wg-box">
						<h5 class="wg-box-title"><span class="wg-num">2</span>{$translate->get('WgStepProfile')}</h5>
						<ul class="wg-servers">
							{foreach $user->wgNodes() as $wgNode}
								{include file='user/dashboard/wgnode.tpl' node=$wgNode}
							{/foreach}
						</ul>
						<p class="wg-note">{$translate->get('WgFileNote')}</p>
					</div>

					<div class="wg-box">
						<h5 class="wg-box-title"><span class="wg-num">3</span>{$translate->get('WgStepConnect')}</h5>
						<ol class="wg-steps">
							<li>{$translate->get('WgHow1')}</li>
							<li>{$translate->get('WgHow2')}</li>
							<li>{$translate->get('WgHow3')}</li>
						</ol>
						<p class="wg-note">{$translate->get('WgResetNote')}</p>
					</div>
				</div>
			</div>
		</div>
	</div>
</div>