
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
										{* a top-up can be limited to certain subscription plans *}
										{if $timeplan->topupAllowed($tpackage['id'], $user)}
											<option value="{$tpackage['id']}" >{$tpackage['name']} - {$tpackage['bandwidth']}G</option>
										{/if}
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

			{* Gift card redeem - Redeem() and RedeemReset() live in dashboard.tpl; #redeem_modal and #code are kept for them *}
{literal}
<style>
#redeem_modal .grd { border: 0; border-radius: 28px; overflow: hidden; background: #fff; box-shadow: 0 30px 80px -20px rgba(15, 23, 42, .45); }
#redeem_modal .grd-hero { position: relative; overflow: hidden; padding: 30px 22px 26px; text-align: center; color: #fff;
	background: radial-gradient(120% 90% at 100% 0%, rgba(255, 255, 255, .28), transparent 55%), linear-gradient(145deg, #fbbf24, #fb923c 45%, #ec4899); }
#redeem_modal .grd-hero::before, #redeem_modal .grd-hero::after { content: ''; position: absolute; border-radius: 50%; background: rgba(255, 255, 255, .14); }
#redeem_modal .grd-hero::before { width: 160px; height: 160px; top: -70px; left: -50px; }
#redeem_modal .grd-hero::after { width: 90px; height: 90px; bottom: -40px; right: -20px; }
#redeem_modal .grd-close { position: absolute; top: 14px; left: 14px; z-index: 2; width: 32px; height: 32px; border: 0; border-radius: 50%; display: flex; align-items: center; justify-content: center;
	background: rgba(255, 255, 255, .22); color: #fff; font-size: 20px; line-height: 1; cursor: pointer; transition: background .2s; }
#redeem_modal .grd-close:hover { background: rgba(255, 255, 255, .35); }
#redeem_modal .grd-badge { position: relative; z-index: 1; width: 76px; height: 76px; margin: 0 auto 12px; border-radius: 26px; display: flex; align-items: center; justify-content: center; font-size: 36px;
	background: rgba(255, 255, 255, .22); box-shadow: inset 0 0 0 1px rgba(255, 255, 255, .4), 0 12px 28px -8px rgba(0, 0, 0, .3); animation: grd-bob 2.4s ease-in-out infinite; }
#redeem_modal .grd-spark { position: absolute; z-index: 1; font-size: 14px; opacity: .9; animation: grd-twinkle 2s ease-in-out infinite; }
#redeem_modal .grd-spark.s1 { top: 24px; right: 30%; }
#redeem_modal .grd-spark.s2 { top: 64px; left: 30%; animation-delay: .7s; }
#redeem_modal .grd-spark.s3 { top: 18px; left: 24%; animation-delay: 1.3s; font-size: 10px; }
@keyframes grd-bob { 0%, 100% { transform: translateY(0) rotate(-6deg); } 50% { transform: translateY(-6px) rotate(6deg); } }
@keyframes grd-twinkle { 0%, 100% { opacity: .2; transform: scale(.7); } 50% { opacity: 1; transform: scale(1.1); } }
#redeem_modal .grd-title { position: relative; z-index: 1; margin: 0; font-size: 19px; font-weight: 700; line-height: 1.7; color: #fff; }
#redeem_modal .grd-sub { position: relative; z-index: 1; margin: 4px 0 0; font-size: 13px; line-height: 1.8; color: rgba(255, 255, 255, .92); }
#redeem_modal .grd-body { padding: 22px 22px 24px; }
#redeem_modal .grd-ticket { position: relative; display: flex; align-items: center; gap: 10px; padding: 8px 14px 8px 8px; border-radius: 18px;
	border: 2px dashed #fdba74; background: #fff7ed; transition: border-color .2s, box-shadow .2s, background .2s; }
#redeem_modal .grd-ticket::before, #redeem_modal .grd-ticket::after { content: ''; position: absolute; top: 50%; width: 16px; height: 16px; margin-top: -8px; border-radius: 50%; background: #fff; }
#redeem_modal .grd-ticket::before { right: -10px; box-shadow: inset 2px 0 0 #fdba74; }
#redeem_modal .grd-ticket::after { left: -10px; box-shadow: inset -2px 0 0 #fdba74; }
#redeem_modal .grd-ticket:focus-within { border-style: solid; border-color: #fb923c; box-shadow: 0 0 0 4px rgba(251, 146, 60, .18); background: #fff; }
#redeem_modal .grd-ticket-icon { flex: 0 0 auto; width: 38px; height: 38px; border-radius: 12px; display: flex; align-items: center; justify-content: center; font-size: 17px;
	background: linear-gradient(145deg, #fbbf24, #f97316); color: #fff; }
#redeem_modal .grd-ticket input { flex: 1 1 auto; min-width: 0; border: 0; outline: 0; background: transparent; padding: 6px 0;
	font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace; font-size: 17px; font-weight: 700; letter-spacing: 0; color: #7c2d12; }
#redeem_modal .grd-ticket input:not(:placeholder-shown) { letter-spacing: 2px; }
#redeem_modal .grd-ticket input:placeholder-shown { direction: rtl; text-align: right; font-family: IRANSans, Tahoma, sans-serif; }
#redeem_modal .grd-ticket input::placeholder { font-family: IRANSans, Tahoma, sans-serif; font-size: 13px; font-weight: 400; letter-spacing: 0; color: #c2410c; opacity: .6; }
#redeem_modal .grd-paste { flex: 0 0 auto; border: 0; border-radius: 12px; padding: 8px 12px; font-size: 12px; font-weight: 700; cursor: pointer;
	background: #ffedd5; color: #c2410c; transition: background .2s; }
#redeem_modal .grd-paste:hover { background: #fed7aa; }
#redeem_modal .grd-paste[hidden] { display: none; }
#redeem_modal .grd-msg { margin: 10px 4px 0; font-size: 13px; line-height: 1.7; color: #e11d48; }
#redeem_modal .grd-msg:empty { margin: 0; }
#redeem_modal .grd-shake { animation: grd-shake .4s ease; }
@keyframes grd-shake { 20%, 60% { transform: translateX(-6px); } 40%, 80% { transform: translateX(6px); } }
#redeem_modal .grd-btn { width: 100%; margin-top: 16px; border: 0; border-radius: 16px; padding: 13px 16px; display: flex; align-items: center; justify-content: center; gap: 8px;
	font-size: 15px; font-weight: 700; color: #fff; cursor: pointer; background: linear-gradient(90deg, #f59e0b, #f97316 50%, #ec4899);
	box-shadow: 0 12px 24px -10px rgba(236, 72, 153, .6); transition: transform .15s, box-shadow .2s, opacity .2s; }
#redeem_modal .grd-btn:hover { box-shadow: 0 14px 28px -10px rgba(236, 72, 153, .75); }
#redeem_modal .grd-btn:active { transform: scale(.98); }
#redeem_modal .grd-btn[disabled] { opacity: .75; cursor: wait; }
#redeem_modal .grd-spin { display: none; width: 16px; height: 16px; border: 2px solid rgba(255, 255, 255, .45); border-top-color: #fff; border-radius: 50%; animation: grd-rot .7s linear infinite; }
#redeem_modal .grd-btn[disabled] .grd-spin { display: inline-block; }
@keyframes grd-rot { to { transform: rotate(360deg); } }
#redeem_modal .grd-done { display: none; text-align: center; padding: 6px 0 2px; }
#redeem_modal.grd-success .grd-form { display: none; }
#redeem_modal.grd-success .grd-done { display: block; }
#redeem_modal .grd-check { width: 68px; height: 68px; margin: 0 auto 12px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 30px; color: #fff;
	background: linear-gradient(145deg, #34d399, #10b981); box-shadow: 0 12px 26px -10px rgba(16, 185, 129, .7); animation: grd-pop .5s cubic-bezier(.2, .9, .3, 1.5); }
@keyframes grd-pop { 0% { transform: scale(.3); opacity: 0; } 100% { transform: scale(1); opacity: 1; } }
#redeem_modal .grd-done-msg { margin: 0 0 12px; font-size: 14px; line-height: 1.9; color: #334155; }
#redeem_modal .grd-balance { display: inline-flex; align-items: center; gap: 6px; padding: 8px 14px; border-radius: 9999px; font-size: 13px; font-weight: 700;
	background: #ecfdf5; color: #047857; }
#redeem_modal .grd-balance[hidden] { display: none; }
#redeem_modal .grd-actions { display: flex; gap: 8px; margin-top: 18px; }
#redeem_modal .grd-actions button { flex: 1 1 0; border: 0; border-radius: 14px; padding: 11px 12px; font-size: 14px; font-weight: 700; cursor: pointer; }
#redeem_modal .grd-again { background: #fff7ed; color: #c2410c; }
#redeem_modal .grd-ok { background: linear-gradient(90deg, #f59e0b, #ec4899); color: #fff; }

html[data-hs-theme="dark"] #redeem_modal .grd { background: #1b2033; box-shadow: 0 30px 80px -20px rgba(0, 0, 0, .7); }
html[data-hs-theme="dark"] #redeem_modal .grd-ticket { background: rgba(251, 146, 60, .08); border-color: rgba(251, 146, 60, .55); }
html[data-hs-theme="dark"] #redeem_modal .grd-ticket::before, html[data-hs-theme="dark"] #redeem_modal .grd-ticket::after { background: #1b2033; }
html[data-hs-theme="dark"] #redeem_modal .grd-ticket::before { box-shadow: inset 2px 0 0 rgba(251, 146, 60, .55); }
html[data-hs-theme="dark"] #redeem_modal .grd-ticket::after { box-shadow: inset -2px 0 0 rgba(251, 146, 60, .55); }
html[data-hs-theme="dark"] #redeem_modal .grd-ticket:focus-within { background: rgba(251, 146, 60, .12); border-color: #fb923c; }
html[data-hs-theme="dark"] #redeem_modal .grd-ticket input { color: #fed7aa; }
html[data-hs-theme="dark"] #redeem_modal .grd-ticket input::placeholder { color: #fdba74; }
html[data-hs-theme="dark"] #redeem_modal .grd-paste, html[data-hs-theme="dark"] #redeem_modal .grd-again { background: rgba(251, 146, 60, .15); color: #fdba74; }
html[data-hs-theme="dark"] #redeem_modal .grd-paste:hover { background: rgba(251, 146, 60, .25); }
html[data-hs-theme="dark"] #redeem_modal .grd-msg { color: #fb7185; }
html[data-hs-theme="dark"] #redeem_modal .grd-done-msg { color: #cbd5e1; }
html[data-hs-theme="dark"] #redeem_modal .grd-balance { background: rgba(16, 185, 129, .15); color: #6ee7b7; }

@media (prefers-reduced-motion: reduce) {
	#redeem_modal .grd-badge, #redeem_modal .grd-spark, #redeem_modal .grd-check, #redeem_modal .grd-shake { animation: none; }
}
</style>
{/literal}
			<div class="modal fade" id="redeem_modal" tabindex="-1" data-bs-backdrop="static" role="dialog" aria-labelledby="redeemModalLabel" aria-hidden="true">
			  <div class="modal-dialog modal-dialog-centered" role="document" style="max-width: 400px;">
				<div class="modal-content grd">
				  <div class="grd-hero">
					<button type="button" class="grd-close" data-bs-dismiss="modal" aria-label="{$translate->get('Close')}">&times;</button>
					<span class="grd-spark s1" aria-hidden="true">✦</span>
					<span class="grd-spark s2" aria-hidden="true">✦</span>
					<span class="grd-spark s3" aria-hidden="true">✦</span>
					<div class="grd-badge" aria-hidden="true">🎁</div>
					<h4 class="grd-title" id="redeemModalLabel">{$translate->get('GiftRedeemTitle')}</h4>
					<p class="grd-sub">{$translate->get('GiftRedeemSub')}</p>
				  </div>
				  <div class="grd-body">
					<form class="grd-form" onsubmit="Redeem(); return false;" novalidate>
						<label for="code" class="visually-hidden">{$translate->get('GiftCard')}</label>
						<div class="grd-ticket">
							<span class="grd-ticket-icon" aria-hidden="true"><i class="fa-solid fa-ticket"></i></span>
							<input type="text" name="code" id="code" dir="ltr" autocomplete="off" autocapitalize="off" spellcheck="false" placeholder="{$translate->get('EnterGiftCard')}">
							<button type="button" class="grd-paste" id="redeem_paste" hidden>{$translate->get('GiftRedeemPaste')}</button>
						</div>
						<p class="grd-msg" id="redeem_msg" role="alert"></p>
						<button type="submit" class="grd-btn" id="redeem_btn">
							<span class="grd-spin" aria-hidden="true"></span>
							<span>{$translate->get('GiftRedeemBtn')}</span>
						</button>
					</form>
					<div class="grd-done" aria-live="polite">
						<div class="grd-check" aria-hidden="true"><i class="fa-solid fa-check"></i></div>
						<p class="grd-done-msg" id="redeem_done_msg"></p>
						<span class="grd-balance" id="redeem_balance" hidden>👛 {$translate->get('GiftRedeemBalance')}: <span id="redeem_balance_val"></span></span>
						<div class="grd-actions">
							<button type="button" class="grd-again" onclick="RedeemReset()">{$translate->get('GiftRedeemAgain')}</button>
							<button type="button" class="grd-ok" data-bs-dismiss="modal">{$translate->get('Close')}</button>
						</div>
					</div>
				  </div>
				</div>
			  </div>
			</div>			