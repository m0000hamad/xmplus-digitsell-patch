			<div id="emailSection" class="set-card set-c-mail">
				<div class="set-card-head">
					<span class="set-card-ico">✉️</span>
					<div>
						<h4 class="set-card-title">{$translate->get('Email')}</h4>
						<p class="set-card-sub">{$translate->get('EmailSettingsSub')}</p>
					</div>
				</div>

				<div class="set-card-body">
					<p class="set-current">{$translate->get('currentMail')} <b>{$user->email|escape:'html'}</b></p>

					<div class="set-field">
						<label class="set-label" for="email">{$translate->get('NewMail')}</label>
						<input type="email" class="set-input" name="email" id="email" placeholder="{$translate->get('EnterNewMail')}" aria-label="{$translate->get('EnterNewMail')}">
					</div>

					{if $Config['maildriver'] == 1}
					<div class="set-field">
						<label class="set-label" for="code">{$translate->get('VerificationCode')}</label>
						<div class="set-inline">
							<input type="number" class="set-input" name="code" id="code" placeholder="{$translate->get('EnterCode')}" aria-label="{$translate->get('EnterCode')}">
							<a type="submit" class="set-btn set-btn-ghost" id="email_verify">{$translate->get('GetCode')}</a>
						</div>
					</div>
					{/if}

					<div class="set-actions">
						<button type="submit" class="set-btn set-btn-primary UpdateEmail">💾 {$translate->get('Update')}</button>
					</div>
				</div>
			</div>
