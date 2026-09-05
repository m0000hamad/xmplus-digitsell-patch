{literal}
<style>
.wd-modal .modal-content { border: 0; border-radius: 20px; overflow: hidden; }
.wd-head {
	position: relative;
	padding: 20px 22px;
	background: linear-gradient(135deg, #059669, #10b981);
	color: #fff;
	overflow: hidden;
}
.wd-head::after {
	content: "";
	position: absolute;
	inset-block-start: -50px;
	inset-inline-end: -40px;
	width: 160px;
	height: 160px;
	border-radius: 50%;
	background: rgba(255, 255, 255, .12);
}
.wd-head-title { position: relative; font-size: 14px; font-weight: 800; margin-bottom: 6px; }
.wd-head-amount {
	position: relative;
	font-size: 27px;
	font-weight: 800;
	direction: ltr;
	unicode-bidi: isolate;
	text-align: start;
	line-height: 1.2;
}
.wd-head-note { position: relative; font-size: 11.5px; opacity: .9; font-weight: 600; margin-top: 4px; }
.wd-close {
	position: absolute;
	top: 14px;
	inset-inline-start: 16px;
	z-index: 3;
	border: 0;
	background: rgba(255, 255, 255, .2);
	color: #fff;
	width: 28px;
	height: 28px;
	border-radius: 50%;
	font-size: 15px;
	line-height: 1;
	cursor: pointer;
}
.wd-body { padding: 20px 22px; }
.wd-methods { margin-bottom: 16px; }
.wd-method {
	display: flex;
	align-items: center;
	gap: 9px;
	border: 1.5px solid rgba(23, 32, 61, .12);
	border-radius: 13px;
	padding: 11px 13px;
	margin-bottom: 8px;
	font-size: 12.5px;
	font-weight: 700;
	color: #16203d;
	cursor: pointer;
	transition: border-color .15s ease, background .15s ease;
}
.wd-method input { accent-color: #10b981; }
.wd-method-emoji { font-size: 17px; }
.wd-method.wd-method-on {
	border-color: #10b981;
	background: rgba(16, 185, 129, .09);
}
html[data-hs-theme="dark"] .wd-method { border-color: rgba(255, 255, 255, .13); color: #e7eaf3; }
html[data-hs-theme="dark"] .wd-method.wd-method-on { background: rgba(16, 185, 129, .16); }
.wd-field { margin-bottom: 14px; }
.wd-label {
	display: flex;
	align-items: center;
	gap: 6px;
	font-size: 12.5px;
	font-weight: 700;
	color: #16203d;
	margin-bottom: 6px;
}
.wd-label i { color: #f43f5e; font-style: normal; }
.wd-input {
	width: 100%;
	border: 1.5px solid rgba(23, 32, 61, .12);
	border-radius: 12px;
	padding: 11px 13px;
	font-size: 13px;
	background: #fff;
	color: #16203d;
	transition: border-color .15s ease, box-shadow .15s ease;
}
.wd-input:focus {
	outline: 0;
	border-color: #10b981;
	box-shadow: 0 0 0 3px rgba(16, 185, 129, .16);
}
.wd-input.wd-bad { border-color: #f43f5e; box-shadow: 0 0 0 3px rgba(244, 63, 94, .14); }
.wd-input.wd-ltr { direction: ltr; text-align: left; font-family: ui-monospace, SFMono-Regular, Menlo, monospace; letter-spacing: .5px; }
.wd-hint { font-size: 11px; color: #8c98ab; margin-top: 5px; font-weight: 600; }
.wd-error { font-size: 11.5px; color: #e11d48; margin-top: 5px; font-weight: 700; display: none; }
.wd-error.wd-show { display: block; }
.wd-note {
	border-radius: 13px;
	padding: 13px 15px;
	background: rgba(245, 158, 11, .1);
	border: 1px solid rgba(245, 158, 11, .3);
	font-size: 11.5px;
	line-height: 1.9;
	color: #92400e;
	font-weight: 600;
}
.wd-note b { font-weight: 800; }
.wd-foot { padding: 0 22px 20px; display: flex; gap: 8px; flex-wrap: wrap; }
.wd-btn {
	flex: 1 1 150px;
	border: 0;
	border-radius: 13px;
	padding: 12px 16px;
	font-size: 13.5px;
	font-weight: 800;
	cursor: pointer;
	transition: transform .14s ease, filter .14s ease;
}
.wd-btn:hover { transform: translateY(-1px); filter: brightness(1.05); }
.wd-btn-go { background: linear-gradient(135deg, #059669, #10b981); color: #fff; box-shadow: 0 7px 18px rgba(16, 185, 129, .3); }
.wd-btn-cancel { background: rgba(23, 32, 61, .08); color: #16203d; }

html[data-hs-theme="dark"] .wd-modal .modal-content { background: #18213a; }
html[data-hs-theme="dark"] .wd-label { color: #e7eaf3; }
html[data-hs-theme="dark"] .wd-input {
	background: rgba(255, 255, 255, .05);
	border-color: rgba(255, 255, 255, .13);
	color: #e7eaf3;
}
html[data-hs-theme="dark"] .wd-note {
	background: rgba(245, 158, 11, .13);
	border-color: rgba(245, 158, 11, .3);
	color: #fcd34d;
}
html[data-hs-theme="dark"] .wd-btn-cancel { background: rgba(255, 255, 255, .1); color: #e7eaf3; }
html[data-hs-theme="dark"] .wd-hint { color: #8b9ab5; }
</style>
{/literal}

<div class="modal fade wd-modal" id="withdrawal" tabindex="-1" data-bs-backdrop="static" role="dialog" aria-labelledby="withdrawalModalLabel" aria-hidden="true">
	<div class="modal-dialog modal-dialog-centered" role="document">
		<div class="modal-content">

			<div class="wd-head">
				<button type="button" class="wd-close" data-bs-dismiss="modal" aria-label="Close">&times;</button>
				<div class="wd-head-title">🏦 {$translate->get('WithdrawalAmt')}</div>
				<div class="wd-head-amount">{$currency->symbol_left} {number_format((float)$user->payout_balance, (int)$currency->decimals)} {$currency->symbol_right}</div>
				<div class="wd-head-note">{$translate->get('WithdrawIntro')}</div>
			</div>

			<div class="wd-body">

				<div class="wd-methods">
					<div class="wd-label" style="margin-bottom:9px">{$translate->get('WithdrawPickMethod')}</div>
					<label class="wd-method wd-method-on" id="wd_m_bank">
						<input type="radio" name="wd_method" value="bank" checked>
						<span class="wd-method-emoji">🏦</span>
						<span>{$translate->get('WithdrawToBank')}</span>
					</label>
					<label class="wd-method" id="wd_m_wallet">
						<input type="radio" name="wd_method" value="wallet">
						<span class="wd-method-emoji">👛</span>
						<span>{$translate->get('WithdrawToWallet')}</span>
					</label>
				</div>

				<div id="wd_bank_fields">

				<div class="wd-field">
					<label class="wd-label" for="wd_name">👤 {$translate->get('WithdrawFullName')} <i>*</i></label>
					<input class="wd-input" type="text" id="wd_name" autocomplete="name" placeholder="{$translate->get('WithdrawFullNameHint')}">
					<div class="wd-error" id="wd_name_err"></div>
				</div>

				<div class="wd-field">
					<label class="wd-label" for="wd_mobile">📱 {$translate->get('WithdrawMobile')} <i>*</i></label>
					<input class="wd-input wd-ltr" type="tel" id="wd_mobile" inputmode="numeric" maxlength="11" placeholder="09121234567">
					<div class="wd-error" id="wd_mobile_err"></div>
				</div>

				<div class="wd-field">
					<label class="wd-label" for="wd_card">💳 {$translate->get('WithdrawCard')} <i>*</i></label>
					<input class="wd-input wd-ltr" type="text" id="wd_card" inputmode="numeric" maxlength="19" placeholder="6037-9911-2233-4455">
					<div class="wd-hint">{$translate->get('WithdrawCardHint')}</div>
					<div class="wd-error" id="wd_card_err"></div>
				</div>

				<div class="wd-field">
					<label class="wd-label" for="wd_sheba">🏛️ {$translate->get('WithdrawSheba')} <i>*</i></label>
					<input class="wd-input wd-ltr" type="text" id="wd_sheba" maxlength="26" placeholder="IR000000000000000000000000">
					<div class="wd-hint">{$translate->get('WithdrawShebaHint')}</div>
					<div class="wd-error" id="wd_sheba_err"></div>
				</div>

				</div>

				<div class="wd-note">
					<b>{$translate->get('WithdrawRulesTitle')}</b><br>
					1. {str_replace(['%amount%'],[{number_format((float)$user->minWithdrawal(), (int)$currency->decimals)}],$translate->get('WithdrawRule1'))}<br>
					2. {$translate->get('WithdrawRule2')}<br>
					3. {str_replace(['%days%'],[$user->withdrawMaxGapDays()],$translate->get('WithdrawRule3'))}<br>
					4. {$translate->get('WithdrawRule4')}<br><br>
					{$translate->get('WithdrawRules')}
					{if $Config['widthdrawnote'] != ""}<br>{$Config['widthdrawnote']}{/if}
				</div>

			</div>

			<div class="wd-foot">
				<button type="button" class="wd-btn wd-btn-go" id="WidthdrawNow">💰 {$translate->get('Withdraw')}</button>
				<button type="button" class="wd-btn wd-btn-cancel" data-bs-dismiss="modal">{$translate->get('Cancel')}</button>
			</div>

		</div>
	</div>
</div>

<script>
	window.WithdrawI18n = new Object();
	window.WithdrawI18n.name   = "{$translate->get('WithdrawErrName')|escape:'javascript'}";
	window.WithdrawI18n.mobile = "{$translate->get('WithdrawErrMobile')|escape:'javascript'}";
	window.WithdrawI18n.card   = "{$translate->get('WithdrawErrCard')|escape:'javascript'}";
	window.WithdrawI18n.sheba  = "{$translate->get('WithdrawErrSheba')|escape:'javascript'}";
	window.WithdrawMethod        = "{$translate->get('WithdrawMethodBank')|escape:'javascript'}";
	window.WithdrawWalletMethod  = "{$translate->get('Account')|escape:'javascript'}";
	window.WithdrawWalletAccount = "{$user->email|escape:'javascript'}";
{literal}
	/*
	 * The payout endpoint only accepts a single free-text `withdrawal_account`,
	 * so the four fields are validated here and packed into one line that the
	 * admin can read straight off the payouts table.
	 */
	(function () {
		var STORE = 'wd_profile';

		function el(id) { return document.getElementById(id); }

		function digits(value) { return (value || '').replace(/[^0-9]/g, ''); }

		function fail(field, message) {
			var input = el('wd_' + field);
			var box = el('wd_' + field + '_err');
			if (input) { input.classList.add('wd-bad'); }
			if (box) { box.textContent = message; box.classList.add('wd-show'); }
		}

		function clear() {
			['name', 'mobile', 'card', 'sheba'].forEach(function (field) {
				var input = el('wd_' + field);
				var box = el('wd_' + field + '_err');
				if (input) { input.classList.remove('wd-bad'); }
				if (box) { box.classList.remove('wd-show'); }
			});
		}

		function chosenMethod() {
			var picked = document.querySelector('input[name="wd_method"]:checked');
			return picked ? picked.value : 'bank';
		}

		/* the panel decides "pay into the wallet" by the method string itself */
		window.withdrawalMethod = function () {
			return chosenMethod() === 'wallet' ? window.WithdrawWalletMethod : window.WithdrawMethod;
		};

		window.buildWithdrawalAccount = function () {
			clear();

			if (chosenMethod() === 'wallet') {
				return window.WithdrawWalletAccount;
			}

			var name = (el('wd_name').value || '').trim();
			var mobile = digits(el('wd_mobile').value);
			var card = digits(el('wd_card').value);
			var sheba = (el('wd_sheba').value || '').toUpperCase().replace(/\s/g, '');

			var ok = true;

			if (name.length < 5 || name.indexOf(' ') === -1) {
				fail('name', window.WithdrawI18n.name); ok = false;
			}
			if (!/^09[0-9]{9}$/.test(mobile)) {
				fail('mobile', window.WithdrawI18n.mobile); ok = false;
			}
			if (card.length !== 16) {
				fail('card', window.WithdrawI18n.card); ok = false;
			}
			if (!/^IR[0-9]{24}$/.test(sheba)) {
				fail('sheba', window.WithdrawI18n.sheba); ok = false;
			}

			if (!ok) { return null; }

			try {
				localStorage.setItem(STORE, JSON.stringify({ name: name, mobile: mobile, card: card, sheba: sheba }));
			} catch (e) {}

			return name + ' | ' + mobile + ' | ' + card + ' | ' + sheba;
		};

		/* prefill from the last request so nobody retypes their card number */
		document.addEventListener('DOMContentLoaded', function () {
			var saved;
			try { saved = JSON.parse(localStorage.getItem(STORE) || '{}'); } catch (e) { saved = {}; }

			['name', 'mobile', 'card', 'sheba'].forEach(function (field) {
				if (saved && saved[field] && el('wd_' + field)) { el('wd_' + field).value = saved[field]; }
			});
		});

		/* only the bank route needs card details */
		var methods = document.querySelectorAll('input[name="wd_method"]');
		var bankFields = el('wd_bank_fields');

		function paintMethod() {
			var wallet = chosenMethod() === 'wallet';
			if (bankFields) { bankFields.hidden = wallet; }
			el('wd_m_bank').classList.toggle('wd-method-on', !wallet);
			el('wd_m_wallet').classList.toggle('wd-method-on', wallet);
		}

		for (var i = 0; i < methods.length; i++) {
			methods[i].addEventListener('change', paintMethod);
		}
		paintMethod();

		/* group the card number as the visitor types */
		var cardInput = el('wd_card');
		if (cardInput) {
			cardInput.addEventListener('input', function () {
				var value = digits(this.value).slice(0, 16);
				this.value = value.replace(/(.{4})/g, '$1-').replace(/-$/, '');
			});
		}
	})();
{/literal}
</script>
