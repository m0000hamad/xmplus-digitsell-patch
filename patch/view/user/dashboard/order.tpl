
			<div class="modal fade" id="plan_upgrade" tabindex="-1" data-bs-backdrop="static" role="dialog" aria-labelledby="plan_upgradeModalLabel" aria-hidden="true">
			  <div class="modal-dialog modal-dialog-centered" role="document">
				<div class="modal-content">
				  <div class="modal-header">
					<h4 class="modal-title">{$translate->get('Change')}</h4>
					<button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
				  </div>
				  <div class="modal-body">
						{$plans = json_decode($Packages,true)}
						<div class="row mb-2">
							<label for="package" class="col-sm-4 col-form-label form-label">{$translate->get('PlanList')}</label>
							<div class="col-sm-8 tom-select-custom">
								<select class="js-select form-select shadow-lg" id="package" name="package" onchange="UpgradeOptions()" data-hs-tom-select-options='{
										"hideSearch": true
									}'>
									{foreach $plans as $package}
										<option value="{$package['id']}" >{$package['name']} - {$package['bandwidth']}G</option>
									{/foreach}
								</select>
							</div>
						</div>
						<div class="row mb-2">
							<label for="plan" class="col-sm-4 col-form-label form-label">{$translate->get('PlanOptions')}</label>
							<div class="col-sm-8 tom-select-custom">
								<select class="form-control form-select shadow-lg" id="plan">
								</select>
							</div>
						</div>
						
				  </div>
				  <div class="modal-footer">
					<button type="submit" class="btn btn-dark upgrade">{$translate->get('Submit')}</button>
				  </div>
				</div>
			  </div>
			</div>
			
			
			<div class="modal fade" id="plan_topup" tabindex="-1" data-bs-backdrop="static" role="dialog" aria-labelledby="plan_topupModalLabel" aria-hidden="true">
			  <div class="modal-dialog modal-dialog-centered" role="document">
				<div class="modal-content">
				  <div class="modal-header">
					<h4 class="modal-title">{$translate->get('AddData')}</h4>
					<button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
				  </div>
				  <div class="modal-body">
						{$topups = json_decode($TPackages,true)}
						<div class="row mb-2">
							<label for="tpackage" class="col-sm-4 col-form-label form-label">{$translate->get('PlanList')}</label>
							<div class="col-sm-8 tom-select-custom">
								<select class="js-select form-select shadow-lg" id="tpackage" name="tpackage" onchange="TopupOptions()" data-hs-tom-select-options='{
										"hideSearch": true
									}'>
									{foreach $topups as $tpackage}
										<option value="{$tpackage['id']}" >{$tpackage['name']} - {$tpackage['bandwidth']}G</option>
									{/foreach}
								</select>
							</div>
						</div>
						<div class="row mb-2">
							<label for="tplan" class="col-sm-4 col-form-label form-label">{$translate->get('PlanOptions')}</label>
							<div class="col-sm-8 tom-select-custom">
								<select class="form-control form-select shadow-lg" id="tplan">
								</select>
							</div>
						</div>
						
				  </div>
				  <div class="modal-footer">
					<button type="submit" class="btn btn-dark topupplan">{$translate->get('Submit')}</button>
				  </div>
				</div>
			  </div>
			</div>

			{* buying days rather than gigabytes - filled in by TimeOptions() *}
			<div class="modal fade" id="plan_time" tabindex="-1" data-bs-backdrop="static" role="dialog" aria-labelledby="plan_timeModalLabel" aria-hidden="true">
			  <div class="modal-dialog modal-dialog-centered" role="document">
				<div class="modal-content">
				  <div class="modal-header">
					<h4 class="modal-title">{$translate->get('AddTime')}</h4>
					<button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
				  </div>
				  <div class="modal-body">
						<div class="row mb-2">
							<label for="timeplan_select" class="col-sm-4 col-form-label form-label">{$translate->get('PlanList')}</label>
							<div class="col-sm-8">
								<select class="form-control form-select shadow-lg" id="timeplan_select" onchange="TimePlanPick()"></select>
							</div>
						</div>
						<div class="row mb-2" id="timeplan_days_row" hidden>
							<label for="timeplan_days" class="col-sm-4 col-form-label form-label">{$translate->get('TimePlanChooseDays')}</label>
							<div class="col-sm-8">
								<input type="number" min="1" step="1" class="form-control shadow-lg" id="timeplan_days" oninput="TimePlanPrice()">
							</div>
						</div>
						<div class="row mb-2">
							<label class="col-sm-4 col-form-label form-label">{$translate->get('TimePlanTotal')}</label>
							<div class="col-sm-8">
								<div class="form-control shadow-lg" id="timeplan_total">-</div>
							</div>
						</div>
						<small class="text-muted">{$translate->get('TimePlanNote')}</small>
				  </div>
				  <div class="modal-footer">
					<button type="submit" class="btn btn-dark timeplanbuy">{$translate->get('Submit')}</button>
				  </div>
				</div>
			  </div>
			</div>

			<div class="modal fade" id="redeem_modal" tabindex="-1" data-bs-backdrop="static" role="dialog" aria-labelledby="redeemModalLabel" aria-hidden="true">
			  <div class="modal-dialog modal-xs modal-dialog-centered" role="document">
				<div class="modal-content">
				  <div class="modal-header">
					<h4 class="modal-title">{$translate->get('RedeemCard')}</h4>
					<button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
				  </div>
				  <div class="modal-body">
					<div class="row mb-3">
						<label for="code" class="col-sm-4 col-form-label form-label">{$translate->get('GiftCard')}</label>
						<div class="col-sm-8">
							<input type="text" class="form-control shadow-lg" name="code" id="code" placeholder="{$translate->get('EnterGiftCard')}">
						</div>
					</div>	
					<div class="row mb-3">
						<label for="Submit" class="col-sm-4 col-form-label form-label">{$translate->get('Submit')}</label>
						<div class="d-grid col-sm-8">
							<button type="submit" class="btn btn-dark" onClick="Redeem()">{$translate->get('Submit')}</button>
						</div>
					</div>	
				  </div>
				</div>
			  </div>
			</div>			