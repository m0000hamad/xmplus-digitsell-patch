{*
 * "Pay from the commission wallet" for subscription checkouts.
 *
 * Commission lives in its own wallet (app/Patch/Payg.php) and pays for
 * subscription plans only. The panel's encoded checkout spends user.money, so
 * right before /portal/order/create the part of the price the money does not
 * cover is moved there (commission.apply); app/Jobs/PaygJob.php returns what
 * the checkout did not use.
 *
 * Included by plan/plan-details.tpl (with the switch) and by the dashboard for
 * the renew button (headless=1: no switch, commission is used when there is any).
 * Callers wrap their checkout: CommissionUse.before(packageid, cycle, next).
 *}
<script>
	window.CommissionWords = new Object();
	window.CommissionWords.label = "{$translate->get('PaygUseCommission')|escape:'javascript'}";
	window.CommissionWords.toman = "{$translate->get('PaygToman')|escape:'javascript'}";
	window.CommissionWords.rial  = "{$translate->get('PaygRial')|escape:'javascript'}";
	window.CommissionWords.used  = "{$translate->get('PaygCommissionUsed')|escape:'javascript'}";
</script>
{if !isset($headless) || !$headless}
<div class="pd-card" id="commissionUseCard" hidden>
	<div class="pd-card-body">
		<label class="pd-switch">
			<span class="pd-switch-wrap">
				<input type="checkbox" id="commissionUse" checked>
				<span class="pd-knob"></span>
			</span>
			<span class="pd-switch-text">
				🤝 <span id="commissionUseLabel"></span>
				<br><small class="text-muted">{$translate->get('PaygUseCommissionHint')}</small>
			</span>
		</label>
	</div>
</div>
{/if}
{literal}
<script>
(function () {
	var endpoint = '/xmplus-patch.php';
	var W = window.CommissionWords;
	var info = null;
	var rtl = (document.documentElement.getAttribute('dir') || '').toLowerCase() === 'rtl';

	function money(rial) {
		var toman = info && info.toman;
		var value = Math.round(toman ? rial / 10 : rial).toLocaleString(rtl ? 'fa-IR' : 'en-US');
		return value + ' ' + (toman ? W.toman : W.rial);
	}

	function say(text) {
		if (window.layer && layer.msg) {
			layer.msg(text, { time: 5000, offset: '100px' });
		}
	}

	window.CommissionUse = {
		passed: false,

		wanted: function () {
			if (!info || !info.enabled || !(info.balance > 0)) {
				return false;
			}
			var box = document.getElementById('commissionUse');
			return box ? box.checked : true;
		},

		before: function (packageid, cycle, next) {
			var self = this;

			if (self.passed || !self.wanted()) {
				self.passed = true;
				next();
				return;
			}

			var body = new FormData();
			body.append('token', info.token);
			body.append('packageid', packageid);
			body.append('plan', cycle || '');

			fetch(endpoint + '?do=commission.apply', { method: 'POST', credentials: 'same-origin', body: body })
				.then(function (r) { return r.json(); })
				.then(function (data) {
					self.passed = true;
					if (!data.ok) {
						say(data.error);
						return;
					}
					if (data.moved > 0) {
						say(W.used.replace('%amount%', money(data.moved)));
					}
					next();
				})
				.catch(function () {
					self.passed = true;
					next();
				});
		}
	};

	fetch(endpoint + '?do=commission.me', { credentials: 'same-origin' })
		.then(function (r) { return r.json(); })
		.then(function (data) {
			if (!data || !data.ok) {
				return;
			}
			info = data;
			var card = document.getElementById('commissionUseCard');
			if (card && data.enabled && data.balance > 0) {
				document.getElementById('commissionUseLabel').textContent =
					W.label.replace('%amount%', money(data.balance));
				card.hidden = false;
			}
		})
		.catch(function () {});
})();
</script>
{/literal}
