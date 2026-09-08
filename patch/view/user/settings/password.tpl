			<div id="passwordSection" class="set-card set-c-pass">
				<div class="set-card-head">
					<span class="set-card-ico">🔑</span>
					<div>
						<h4 class="set-card-title">{$translate->get('ChangePass')}</h4>
						<p class="set-card-sub">{$translate->get('PasswordSettingsSub')}</p>
					</div>
				</div>

				<div class="set-card-body">
					<div class="set-field">
						<label class="set-label" for="currentpassword">{$translate->get('CurrentPass')}</label>
						<input type="password" class="set-input" name="currentpassword" id="currentpassword" placeholder="{$translate->get('EnterCurrentPass')}" aria-label="{$translate->get('EnterCurrentPass')}">
					</div>

					<div class="set-field">
						<label class="set-label" for="newpassword">{$translate->get('NewPass')}</label>
						<input type="password" class="set-input" name="newpassword" id="newpassword" placeholder="{$translate->get('EnterNewPass')}" aria-label="{$translate->get('EnterNewPass')}">
					</div>

					<div class="set-field">
						<label class="set-label" for="confirmnewpassword">{$translate->get('ConfirmNewPass')}</label>
						<input type="password" class="set-input" name="confirmNewPassword" id="confirmnewpassword" placeholder="{$translate->get('ConfirmYNewPass')}" aria-label="{$translate->get('ConfirmYNewPass')}">
					</div>

					{if $Config['passwordmode'] == 1}
					<div class="set-note-intro" style="background:rgba(139,92,246,.08);border-color:rgba(139,92,246,.18);">
						<b>{$translate->get('PassReq')}</b> — {$translate->get('Requirements')}
						<ul class="mb-0 mt-2 ps-3">
							<li>{$translate->get('MinimumChar')}</li>
							<li>{$translate->get('LowercaseChar')}</li>
							<li>{$translate->get('UppercaseChar')}</li>
							<li>{$translate->get('NumberSymbol')}</li>
						</ul>
					</div>
					{/if}

					<div class="set-actions">
						<button type="submit" class="set-btn set-btn-primary updatePassword">💾 {$translate->get('Update')}</button>
					</div>
				</div>
			</div>
