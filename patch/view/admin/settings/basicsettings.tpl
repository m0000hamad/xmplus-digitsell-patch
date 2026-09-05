           <div id="BasicSettings" class="card shadow-lg rounded">
				<div class="card-header">
					<h4 class="card-title">{$translate->get('BasicSettings')}</h4>
				</div>
				<div class="card-body">
					<div class="row">
						<div class="col-xl-4 col-lg-4 col-sm-12 col-md-4">
							<div class="form-check form-check-secondary form-switch mb-3">
							  <input type="checkbox" class="form-check-input" id="maintenance" {if $Config['maintenance'] == 1}checked{/if}>
							  <label class="form-check-label" for="maintenance">{$translate->get('Maintenance')}</label>
							</div>			  
							<div class="form-check form-check-secondary form-switch mb-3">
							  <input type="checkbox" class="form-check-input" id="loginverify" {if $Config['loginverify'] == 1}checked{/if}>
							  <label class="form-check-label" for="loginverify">{$translate->get('LoginVerify')}</label>
							</div>	
							<div class="form-check form-check-secondary form-switch mb-3">
							  <input type="checkbox" class="form-check-input" id="allow_coupon_use" {if $Config['allow_coupon_use'] == 1}checked{/if}>
							  <label class="form-check-label" for="allow_coupon_use">{$translate->get('UseCoupon')}</label>
							</div>	
						</div>	
						<div class="col-xl-4 col-lg-4col-sm-12 col-md-4">
							<div class="form-check form-check-secondary form-switch mb-3">
							  <input type="checkbox" class="form-check-input" id="loginbind" {if $Config['loginbind'] == 1}checked{/if}>
							  <label class="form-check-label" for="loginbind">{$translate->get('LoginBind')}</label>
							</div>	
							<div class="form-check form-check-secondary form-switch mb-3">
							  <input type="checkbox" class="form-check-input" id="language_selector" {if $Config['language_selector'] == 1}checked{/if}>
							  <label class="form-check-label" for="language_selector">{$translate->get('langSelector')}</label>
							</div>	
							<div class="form-check form-check-secondary form-switch mb-3">
							  <input type="checkbox" class="form-check-input" id="disable_trafficlog" {if $Config['disable_trafficlog'] == 1}checked{/if}>
							  <label class="form-check-label" for="disable_trafficlog">{$translate->get('DisableTrafficlog')}</label>
							</div>
						</div>
						<div class="col-xl-4 col-lg-4 col-sm-12 col-md-4">
							<div class="form-check form-check-secondary form-switch mb-3">
							  <input type="checkbox" class="form-check-input" id="verify" {if $Config['verify'] == 1}checked{/if}>
							  <label class="form-check-label" for="verify">{$translate->get('VerifyAcc')}</label>
							</div>	
							<div class="form-check form-check-secondary form-switch mb-3">
							  <input type="checkbox" class="form-check-input" id="disconnect_unverified" {if $Config['disconnect_unverified'] == 1}checked{/if}>
							  <label class="form-check-label" for="disconnect_unverified">{$translate->get('Unverified')}</label>
							</div>
						</div>
					</div>
					<hr>
					<div class="row mb-2">
							<label class="col-sm-3 col-form-label form-label" for="latest_notice">{$translate->get('PopUpNotice')}</label>
							<div class="col-sm-9 tom-select-custom">
								<select class="js-select form-select shadow-lg mb-1" id="latest_notice" name="latest_notice" data-hs-tom-select-options='{
									"hideSearch": true
								}'>
									<option value="0" {if $Config['latest_notice'] == 0}selected{/if}>{$translate->get('Disable')}</option>
									<option value="1" {if $Config['latest_notice'] == 1}selected{/if}>{$translate->get('Enable')}</option>
								</select>
							</div>
					</div>
					
					<div class="row mb-2">
							<label class="col-sm-3 col-form-label form-label" for="accounts">{$translate->get('EnableAccounts')}</label>
							<div class="col-sm-9 tom-select-custom">
								<select class="js-select form-select shadow-lg mb-1" id="accounts" name="accounts" data-hs-tom-select-options='{
									"hideSearch": true
								}'>
									<option value="0" {if $Config['accounts'] == 0}selected{/if}>{$translate->get('Disable')}</option>
									<option value="1" {if $Config['accounts'] == 1}selected{/if}>{$translate->get('Enable')}</option>
								</select>
							</div>
					</div>
					
					<div class="row mb-2">
							<label class="col-sm-3 col-form-label form-label" for="exchange_rate">{$translate->get('AutoExchange')}</label>
							<div class="col-sm-9 tom-select-custom">
								<select class="js-select form-select shadow-lg mb-1" id="exchange_rate" name="exchange_rate" data-hs-tom-select-options='{
									"hideSearch": true
								}'>
									<option value="0" {if $Config['exchange_rate'] == 0}selected{/if}>{$translate->get('Disable')}</option>
									<option value="1" {if $Config['exchange_rate'] == 1}selected{/if}>{$translate->get('Enable')}</option>
								</select>
							</div>
					</div>
					
					<div class="row mb-2">
							<label class="col-sm-3 col-form-label form-label" for="sameGroup">{$translate->get('AllowPlanGroup')}</label>
							<div class="col-sm-9 tom-select-custom">
								<select class="js-select form-select shadow-lg mb-1" id="sameGroup" name="sameGroup" data-hs-tom-select-options='{
									"hideSearch": true
								}'>
									<option value="0" {if $Config['sameGroup'] == 0}selected{/if}>{$translate->get('AllPlanGroup')}</option>
									<option value="1" {if $Config['sameGroup'] == 1}selected{/if}>{$translate->get('SamePlanGroup')}</option>
								</select>
							</div>
					</div>			
					
					<div class="row mb-2">
							<label for="upload_" class="col-sm-3 col-form-label form-label">{$translate->get('MaintenanceNote')}</label>
							<div class="col-sm-9">
									<input type="text" class="form-control shadow-lg" name="maintenance_note" id="maintenance_note" value="{$Config['maintenance_note']}"  placeholder="{$translate->get('MaintenanceNote')}" >
							</div>
					</div>				

					<div class="row mb-2">
							<label for="ticket_signature" class="col-sm-3 col-form-label form-label">{$translate->get('TicketSignature')}</label>
							<div class="col-sm-9">
								<textarea rows="3" class="form-control shadow-lg mb-1" name="ticket_signature" id="ticket_signature" placeholder="{$translate->get('TicketSignatureHint')}">{$Config['ticket_signature']}</textarea>
								<small class="text-muted">{$translate->get('TicketSignatureHint')}</small>
							</div>
					</div>
					<div class="row mb-2">
							<label for="ideal_logout" class="col-sm-3 col-form-label form-label">{$translate->get('logoutSeconds')} ({$translate->get('s')})</label>
							<div class="col-sm-9">
								<input type="number" class="form-control shadow-lg mb-1" value="{$Config['ideal_logout_seconds']}" name="ideal_logout_seconds" id="ideal_logout_seconds" placeholder="{$translate->get('logoutSeconds')}" >
							</div>
					</div>
					<div class="row mb-2">
							<label for="default_lang" class="col-sm-3 col-form-label form-label">{$translate->get('DefaultLanguage')}</label>
							<div class="col-sm-9 tom-select-custom">
								<select multiple class="js-select form-select shadow-lg mb-1" id="languages" name="languages" data-hs-tom-select-options='{
									  "hideSearch": true,
									  "placeholder" : "{$translate->get('DefaultLanguage')}"
									}'>
									{$language = explode(',',$Config['languages'])}
									{foreach $locales as $locale}
									    {assign var=lang value="_"|explode:$locale}
										<option value="{$locale}"   {if in_array($locale, $language)} selected{/if} data-option-template='<span class="d-flex align-items-center"><img class="avatar avatar-xss avatar-circle me-2" src="/assets/vendor/flag-icon-css/flags/1x1/{$lang[1]|lower|escape}.svg"  /><span class="text-truncate">{$translate->get({$locale})}</span></span>'>{$translate->get({$locale})}</option>
									{/foreach}
								</select>
							</div>
					</div>
					
					<div class="row mb-2">
							<label for="default_lang" class="col-sm-3 col-form-label form-label">{$translate->get('RTLLanguage')}</label>
							<div class="col-sm-9 tom-select-custom">
								<select multiple class="js-select form-select shadow-lg mb-1" id="rtlanguages" name="rtlanguages" data-hs-tom-select-options='{
									  "hideSearch": true,
									  "placeholder" : "{$translate->get('RTLLanguage')}"
									}'>
									{$rtlanguages = explode(',',$Config['rtlanguages'])}
									{foreach $locales as $rlocale}
									    {assign var=rlang value="_"|explode:$rlocale}
										<option value="{$rlocale}"  {if in_array($rlocale, $rtlanguages)} selected{/if} data-option-template='<span class="d-flex align-items-center"><img class="avatar avatar-xss avatar-circle me-2" src="/assets/vendor/flag-icon-css/flags/1x1/{$rlang[1]|lower|escape}.svg"  /><span class="text-truncate">{$translate->get({$rlocale})}</span></span>'>{$translate->get({$rlocale})}</option>
									{/foreach}
								</select>
							</div>
					</div>
					
					<div class="row mb-3">
							<label for="default_country" class="col-sm-3 col-form-label form-label">{$translate->get('DefaultCurrency')}</label>
							<div class="col-sm-9 tom-select-custom">
								<select class="js-select form-select shadow-lg mb-1" id="default_currency" name="default_currency" >
									{foreach $Currencies as $currenci}
										<option value="{$currenci->currency}" {if $Config['default_currency'] == $currenci->currency}selected{/if}> {$currenci->country} - {$currenci->currency}</option>
									{/foreach}
								</select>
							</div>
					</div>
					
					<div class="row mb-2">
							<label for="licenseKey" class="col-sm-3 col-form-label form-label">{$translate->get('licenseKey')}</label>
							<div class="col-sm-9">
								<input type="text" class="form-control shadow-lg mb-1" name="licenseKey" id="licenseKey" value="{$Config['licenseKey']}" >
							</div>
					</div>	
					
					<div class="d-flex justify-content-end gap-3">
						 <button type="submit" class="btn btn-dark" onClick="Basic()">{$translate->get('Submit')}</button>
					</div>
				</div>
            </div>