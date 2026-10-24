			<div class="col-lg-12 col-xl-12 col-md-12 col-sm-12 mb-3 mb-lg-5">
				<div class="card card-shadow shadow-lg rounded">
					<div class="card-body">
					
						<div class="row mb-2">
							<label class="col-sm-3 col-form-label form-label" for="rebate">{$translate->get('EnableRebate')}</label>
							<div class="col-sm-9 tom-select-custom">
								<select class="js-select form-select  shadow-lg" id="rebate" name="rebate" data-hs-tom-select-options='{
									"hideSearch": true
								}'>
									<option value="0" {if $Config['rebate'] == 0}selected{/if}>{$translate->get('Disable')}</option>
									<option value="1" {if $Config['rebate'] == 1}selected{/if}>{$translate->get('Enable')}</option>
								</select>
							</div>
						</div>
						
						<div class="row mb-2">
							<label class="col-sm-3 col-form-label form-label" for="rebatetype">{$translate->get('RebateType')}</label>
							<div class="col-sm-9 tom-select-custom">
								<select class="js-select form-select rebatetype shadow-lg mb-1" id="rebatetype" name="rebatetype" data-hs-tom-select-options='{
									"hideSearch": true
								}'>
									<option value="1" {if $Config['rebatetype'] == 1}selected{/if}>{$translate->get('RebateOnce')}</option>
									<option value="2" {if $Config['rebatetype'] == 2}selected{/if}>{$translate->get('RebateMultiple')}</option>
								</select> 
							</div>
							
						</div>	
						
						<div class="row mb-2">
							<label class="col-sm-3 col-form-label form-label" for="commission">{$translate->get('Commission')} (%)</label>
							<div class="col-sm-9">
								<input type="text" class="form-control shadow-lg mb-1" id="commission" name="commission" placeholder="{$translate->get('Commission')}" value="{$Config['commission']}">
							</div>
						</div>
						
						<div class="row mb-2">
							<label class="col-sm-3 col-form-label form-label" for="payouts">{$translate->get('Payouts')}</label>
							<div class="col-sm-9 tom-select-custom">
								<select class="js-select form-select shadow-lg" id="payouts" name="payouts" data-hs-tom-select-options='{
									"hideSearch": true
								}'>
									<option value="0" {if $Config['payouts'] == 0}selected{/if}>{$translate->get('Disable')}</option>
									<option value="1" {if $Config['payouts'] == 1}selected{/if}>{$translate->get('Enable')}</option>
								</select>
							</div>
						</div>
						
						<div class="row mb-2">
							<label class="col-sm-3 col-form-label form-label" for="payoutlimit">{$translate->get('PayoutLimit')} ({$Config['default_currency_symbol']})</label>
							<div class="col-sm-9">
								<input type="text" class="form-control shadow-lg mb-1" id="payoutlimit" name="payoutlimit" placeholder="{$translate->get('PayoutLimit')}" value="{$Config['payoutlimit']}">
							</div>
						</div>	
						
						<div class="row mb-2">
							<label class="col-sm-3 col-form-label form-label" for="payoutmethod">{$translate->get('PayoutMethod')}</label>
							<div class="col-sm-9">
								<input type="text" class="form-control shadow-lg mb-1" id="payoutmethod" name="payoutmethod" placeholder="{$translate->get('PayoutMethod')}" value="{$Config['payoutmethod']}">
							</div>
						</div>
						
						<div class="row mb-2">
							<label class="col-sm-3 col-form-label form-label" for="widthdrawnote">{$translate->get('PayoutNote')}</label>
							<div class="col-sm-9">
								<textarea id="widthdrawnote" class="shadow-lg" name="widthdrawnote">{$Config['widthdrawnote']}</textarea>
							</div>
						</div>
						
						<div class="row mb-2">	
							<label class="col-sm-3 col-form-label form-label"></label>
							<div class="col-sm-9 d-grid">
								<button type="submit" class="btn btn-dark" onClick="Save()">{$translate->get('Submit')}</button>
							</div> 
						</div>
						
					</div>
				</div>

				<div class="card card-shadow shadow-lg rounded mt-3" id="dsCommissionRoute" data-saved="{$translate->get('CommissionRoutingSaved')|escape:'html'}">
					<div class="card-body">
						<h4 class="card-header-title mb-1">🤝 {$translate->get('CommissionRouting')}</h4>
						<p class="text-muted small">{$translate->get('CommissionRoutingIntro')}</p>

						<div class="row mb-2">
							<label class="col-sm-3 col-form-label form-label" for="dsCommissionDestination">{$translate->get('CommissionDestination')}</label>
							<div class="col-sm-9">
								<select class="form-select shadow-lg" id="dsCommissionDestination">
									<option value="payout">{$translate->get('CommissionDestPayout')}</option>
									<option value="money">{$translate->get('CommissionDestMoney')}</option>
									<option value="wallet">{$translate->get('CommissionDestWallet')}</option>
								</select>
								<div class="text-muted small mt-1" id="dsCommissionWalletNote" hidden>{$translate->get('CommissionWalletOff')}</div>
							</div>
						</div>

						<div class="form-check mb-3">
							<input class="form-check-input" type="checkbox" id="dsCommissionChoice" value="1">
							<label class="form-check-label" for="dsCommissionChoice">{$translate->get('CommissionUserChoice')}</label>
							<div class="text-muted small">{$translate->get('CommissionUserChoiceHint')}</div>
						</div>

						<div class="d-flex align-items-center gap-2">
							<button type="button" class="btn btn-dark" id="dsCommissionSave">{$translate->get('Submit')}</button>
							<span class="small" id="dsCommissionMsg"></span>
						</div>
					</div>
				</div>

				{literal}
				<script>
				(function () {
					var url = '/xmplus-patch.php?do=commission.routing';
					var card = document.getElementById('dsCommissionRoute');
					var select = document.getElementById('dsCommissionDestination');
					var choice = document.getElementById('dsCommissionChoice');
					var save = document.getElementById('dsCommissionSave');
					var msg = document.getElementById('dsCommissionMsg');
					var note = document.getElementById('dsCommissionWalletNote');
					if (!card || !select || !choice || !save) { return; }

					var token = '';
					var walletReady = true;

					function say(text, bad) {
						msg.textContent = text || '';
						msg.style.color = bad ? '#dc2626' : '#059669';
					}

					function walletNote() {
						if (note) { note.hidden = !(select.value === 'wallet' && !walletReady); }
					}

					fetch(url, { credentials: 'same-origin' })
						.then(function (r) { return r.json(); })
						.then(function (data) {
							if (!data.ok) { say(data.error || 'error', true); return; }
							token = data.token || '';
							walletReady = !!data.wallet_ready;
							select.value = data.destination || 'payout';
							choice.checked = !!data.user_choice;
							walletNote();
						})
						.catch(function () { say('network error', true); });

					select.addEventListener('change', walletNote);

					save.addEventListener('click', function () {
						save.disabled = true;
						var body = new FormData();
						body.append('token', token);
						body.append('destination', select.value);
						body.append('user_choice', choice.checked ? '1' : '0');

						fetch(url, { method: 'POST', body: body, credentials: 'same-origin' })
							.then(function (r) { return r.json(); })
							.then(function (data) {
								save.disabled = false;
								if (!data.ok) { say(data.error || 'error', true); return; }
								token = data.token || token;
								walletReady = !!data.wallet_ready;
								walletNote();
								say(card.getAttribute('data-saved'), false);
							})
							.catch(function () {
								save.disabled = false;
								say('network error', true);
							});
					});
				})();
				</script>
				{/literal}
			</div>
