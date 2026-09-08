			{$notification = json_decode($user->notification,true)}
			<div id="notificationsSection" class="set-card set-c-notif">
				<div class="set-card-head">
					<span class="set-card-ico">🔔</span>
					<div>
						<h4 class="set-card-title">{$translate->get('Notifications')}</h4>
						<p class="set-card-sub">{$translate->get('NotificationsSettingsSub')}</p>
					</div>
				</div>

				<div class="set-card-body">
					<div class="set-note-intro">{$translate->get('NotifyStatus')}</div>

					<form>
						<div class="set-toggle-row">
							<span class="set-toggle-label"><span class="set-toggle-emoji">🔐</span>{$translate->get('LoginNotify')}</span>
							<div class="form-check form-switch">
								<input class="form-check-input" type="checkbox" role="switch" id="Login" name="Login" {if isset($notification['loginnotify']) && $notification['loginnotify'] == 1}checked{/if}>
							</div>
						</div>

						<div class="set-toggle-row">
							<span class="set-toggle-label"><span class="set-toggle-emoji">📊</span>{$translate->get('DataNotify')}</span>
							<div class="form-check form-switch">
								<input class="form-check-input" type="checkbox" role="switch" name="DataUsed" id="DataUsed" {if isset($notification['dataused']) && $notification['dataused']== 1}checked{/if}>
							</div>
						</div>

						<div class="set-toggle-row">
							<span class="set-toggle-label"><span class="set-toggle-emoji">📢</span>{$translate->get('NoticeNotify')}</span>
							<div class="form-check form-switch">
								<input class="form-check-input" type="checkbox" role="switch" name="Notices" id="Notices" {if isset($notification['sendnotices']) && $notification['sendnotices'] == 1}checked{/if}>
							</div>
						</div>

						<div class="set-toggle-row">
							<span class="set-toggle-label"><span class="set-toggle-emoji">⏳</span>{$translate->get('ExpireNotify')}</span>
							<div class="form-check form-switch">
								<input class="form-check-input" type="checkbox" role="switch" name="DataExpire" id="DataExpire" {if isset($notification['dataexpire'])&& $notification['dataexpire'] == 1}checked{/if}>
							</div>
						</div>
					</form>

					<div class="set-actions">
						<button type="submit" class="set-btn set-btn-primary setNotifications">💾 {$translate->get('Update')}</button>
					</div>
				</div>
			</div>
