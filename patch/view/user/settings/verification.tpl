			<div id="twoStepVerificationSection" class="set-card set-c-2fa">
				<div class="set-card-head">
					<span class="set-card-ico">🛡️</span>
					<div>
						<h4 class="set-card-title">
							{$translate->get('TwoStep')}
							{if $user->ga_status == 0}
								<span class="set-badge set-badge-off">● {$translate->get('Disabled')}</span>
							{else}
								<span class="set-badge set-badge-on">● {$translate->get('Enabled')}</span>
							{/if}
						</h4>
						<p class="set-card-sub">{$translate->get('TwoStepSettingsSub')}</p>
					</div>
				</div>

				<div class="set-card-body">
					<p class="set-current">{if $user->ga_status == 0}{$translate->get('AuthEnable')}{else}{$translate->get('AuthDisable')}{/if}</p>

					<div class="set-field">
						<label class="set-label" for="confirmpasswd">{$translate->get('CurrentPass')}</label>
						<input type="password" class="set-input" name="confirmpasswd" id="confirmpasswd" placeholder="{$translate->get('EnterCurrentPass')}" aria-label="{$translate->get('EnterCurrentPass')}">
						<span class="set-hint">{str_replace(["%AppName%"],[$Config['appName']],$translate->get('EnterLoginPass'))}</span>
					</div>

					<div class="set-actions">
						<button type="submit" class="set-btn set-btn-primary confirmpasswd">{if $user->ga_status == 0}🛡️ {$translate->get('Setup')}{else}⛔ {$translate->get('Disable')}{/if}</button>
					</div>
				</div>
			</div>

			<div class="modal fade" id="_auth" data-bs-backdrop="static" tabindex="-1" role="dialog" aria-labelledby="staticBackdropLabel" aria-hidden="true">
				<div class="modal-dialog modal-dialog-centered modal-lg" role="document">
					<div class="modal-content set-card" style="box-shadow:0 24px 60px rgba(23,32,61,.28);">
						<div class="modal-header border-0">
							<h5 class="modal-title set-card-title" id="staticBackdropLabel">🛡️ {$translate->get('TwoStep')}</h5>
							<button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
						</div>
						<div class="modal-body">
							<div class="set-2fa-grid">
								<div>
									<div class="set-label">{$translate->get('Secret')}</div>
									<code class="set-2fa-secret">{$user->ga|escape:'html'}</code>
									<div class="set-2fa-qr"><img src="{$UserService->getGAurl()}" alt="QR"></div>
								</div>
								<div>
									<div class="set-label">{$translate->get('DownloadAuth')}</div>
									<div class="set-2fa-store">
										<a target="_blank" href="https://play.google.com/store/apps/details?id=com.google.android.apps.authenticator2"><img src="/assets/img/android.png" alt="Google Play"></a>
										<a target="_blank" href="https://apps.apple.com/us/app/google-authenticator/id388497605"><img src="/assets/img/ios.png" alt="App Store"></a>
									</div>
									<div class="set-field">
										<label class="set-label" for="ga_code">{$translate->get('InstallScan')}</label>
										<input type="number" class="set-input" name="ga_code" id="ga_code" placeholder="{$translate->get('AuthCode')}" aria-label="{$translate->get('AuthCode')}">
									</div>
								</div>
							</div>
						</div>
						<div class="modal-footer border-0">
							<a class="set-btn set-btn-ghost gaReset">♻️ {$translate->get('Reset')}</a>
							<button type="button" class="set-btn set-btn-primary gaSet">{if $user->ga_status == 0}{$translate->get('Setup')}{else}{$translate->get('Disable')}{/if}</button>
						</div>
					</div>
				</div>
			</div>
