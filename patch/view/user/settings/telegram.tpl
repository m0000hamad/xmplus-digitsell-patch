		{if $Config['telegram'] == 1 && $Config['telegrambind'] == 1 && $Config['telegrambot'] != ""}
			<div id="telegramSection" class="set-card set-c-tg">
				<div class="set-card-head">
					<span class="set-card-ico">✈️</span>
					<div>
						<h4 class="set-card-title">
							Telegram {$translate->get('Account')}
							{if $user->telegram_id > 0}
								<span class="set-badge set-badge-on">● {$translate->get('Enabled')}</span>
							{else}
								<span class="set-badge set-badge-off">● {$translate->get('Disabled')}</span>
							{/if}
						</h4>
						<p class="set-card-sub">{$translate->get('TelegramSettingsSub')}</p>
					</div>
				</div>

				<div class="set-card-body">
					<div class="set-field">
						<label class="set-label" for="telegram_id">Telegram ID</label>
						<input type="text" class="set-input" name="telegram_id" id="telegram_id" value="{if $user->telegram_id == 0}{else}{$user->telegram_id|escape:'html'}{/if}" disabled>
					</div>

					<div class="set-field">
						<label class="set-label" for="telegram_name">Telegram {$translate->get('Username')}</label>
						<input type="text" class="set-input" name="telegram_name" id="telegram_name" value="{$user->telegram_name|escape:'html'}" disabled>
					</div>

					<div class="set-actions">
						{if $user->telegram_id <= 0}
							<a class="set-btn set-btn-primary" href="https://telegram.me/{$Config['telegrambot']}?start={$user->tg_token}" target="_blank">✈️ {$translate->get('BindTelegramAcc')}</a>
						{else}
							<button type="submit" class="set-btn set-btn-danger unbind">🔌 {$translate->get('UnBindTG')}</button>
						{/if}
					</div>
				</div>
			</div>
		{/if}
