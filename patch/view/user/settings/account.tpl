			<div id="deleteAccountSection" class="set-card set-c-danger">
				<div class="set-card-head">
					<span class="set-card-ico">🗑️</span>
					<div>
						<h4 class="set-card-title">{$translate->get('DeleteAcc')}</h4>
						<p class="set-card-sub">{$translate->get('DeleteAccountSettingsSub')}</p>
					</div>
				</div>

				<div class="set-card-body">
					<p class="set-current">{str_replace(["%appName%"],[$Config['appName']],$translate->get('DeleteAccNote'))}</p>

					<div class="set-field">
						<label class="set-label" for="login_password">{$translate->get('CurrentPass')}</label>
						<input type="password" class="set-input" name="login_password" id="login_password" placeholder="{$translate->get('EnterCurrentPass')}" aria-label="{$translate->get('EnterCurrentPass')}">
						<span class="set-hint">{str_replace(["%AppName%"],[$Config['appName']],$translate->get('EnterLoginPass'))}</span>
					</div>

					<div class="set-field">
						<div class="form-check form-check-dark">
							<input class="form-check-input" type="checkbox" id="deleteAccountCheckbox">
							<label class="form-check-label" for="deleteAccountCheckbox">{$translate->get('ConfirmDeleteAcc')}</label>
						</div>
					</div>

					<div class="set-actions">
						<button type="submit" class="set-btn set-btn-danger DeleteAccount">🗑️ {$translate->get('Delete')}</button>
					</div>
				</div>
			</div>
