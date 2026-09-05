{literal}
<style>
.py-sum { position: sticky; top: 84px; }
.py-line {
	display: flex;
	justify-content: space-between;
	align-items: center;
	gap: 10px;
	font-size: 13px;
	color: #56617a;
	margin-bottom: 11px;
}
.py-line span:last-child { font-weight: 700; color: #16203d; direction: ltr; unicode-bidi: isolate; }
.py-line-off span:last-child { color: #be123c; }
.py-line-credit span:last-child { color: #047857; }
.py-total {
	display: flex;
	justify-content: space-between;
	align-items: center;
	gap: 10px;
	border-top: 1.5px dashed rgba(23, 32, 61, .12);
	padding-top: 14px;
	margin-top: 4px;
}
.py-total-label { font-size: 14px; font-weight: 800; color: #16203d; }
.py-total-value {
	font-size: 20px;
	font-weight: 800;
	color: #047857;
	direction: ltr;
	unicode-bidi: isolate;
}
.py-buttons { display: flex; gap: 9px; margin-top: 16px; }
.py-btn {
	flex: 1 1 0;
	border: 0;
	border-radius: 15px;
	padding: 13px 14px;
	font-size: 13.5px;
	font-weight: 800;
	cursor: pointer;
	transition: transform .14s ease, box-shadow .14s ease;
}
.py-btn:active { transform: scale(.98); }
.py-btn-pay {
	flex: 2 1 0;
	color: #fff;
	background: linear-gradient(135deg, #059669, #10b981);
	box-shadow: 0 8px 20px rgba(16, 185, 129, .34);
}
.py-btn-pay:hover { box-shadow: 0 12px 26px rgba(16, 185, 129, .44); }
.py-btn-cancel { color: #be123c; background: rgba(244, 63, 94, .12); }
.py-btn-cancel:hover { background: rgba(244, 63, 94, .2); }
.py-safe { margin-top: 11px; font-size: 11.5px; color: #8c98ab; text-align: center; line-height: 1.9; }

html[data-hs-theme="dark"] .py-line span:last-child,
html[data-hs-theme="dark"] .py-total-label { color: #e7eaf3; }
html[data-hs-theme="dark"] .py-total-value { color: #34d399; }
html[data-hs-theme="dark"] .py-total { border-top-color: rgba(255, 255, 255, .14); }
html[data-hs-theme="dark"] .py-btn-cancel { color: #fda4af; background: rgba(244, 63, 94, .18); }

@media (max-width: 991.98px) {
	.py-sum { position: static; }
}
@media (max-width: 420px) {
	.py-buttons { flex-wrap: wrap; }
	.py-btn, .py-btn-pay { flex: 1 1 100%; }
}
</style>
{/literal}

<div class="col-xl-4 col-lg-4 col-md-12 col-sm-12">
	<div class="py-sum">
		<div class="py-card">
			<div class="py-card-head">
				<span class="py-card-emoji">💰</span>
				<h3 class="py-card-title">{$translate->get('Summary')}</h3>
			</div>
			<div class="py-card-body">
				<div class="py-line">
					<span>{$translate->get('SubTotal')}</span>
					<span>{$currency->symbol_left} {number_format((float)$order->package_amount, (int){$currency->decimals})} {$currency->symbol_right}</span>
				</div>
				<div class="py-line py-line-off">
					<span>{$translate->get('Discount')}</span>
					<span>- {$currency->symbol_left} {number_format((float)$order->discount, (int){$currency->decimals})} {$currency->symbol_right}</span>
				</div>
				<div class="py-line py-line-credit">
					<span>💳 {$translate->get('AvailAmnt')}</span>
					<span>- {$currency->symbol_left} {number_format((float)$order->user_balance, (int){$currency->decimals})} {$currency->symbol_right}</span>
				</div>
				<div class="py-line">
					<span>{$translate->get('GatewayFee')}</span>
					<span>{$currency->symbol_left} <span id="gateway_fee">{number_format((float)$order->user_balance, (int){$currency->decimals})}</span> {$currency->symbol_right}</span>
				</div>

				<div class="py-total">
					<span class="py-total-label">{$translate->get('Total')}</span>
					<span class="py-total-value">{$currency->symbol_left} <span id="total">{number_format((float)$order->total_amount, (int){$currency->decimals})}</span> {$currency->symbol_right}</span>
				</div>

				<div class="py-buttons">
					<button type="button" class="py-btn py-btn-pay {if $payments->count() > 0}checkout{/if}" id="checkout">💳 {$translate->get('Pay')}</button>
					<button type="button" class="py-btn py-btn-cancel cancel">{$translate->get('CancelOrder')}</button>
				</div>

				<div class="py-safe">🔒 {$translate->get('CheckoutSafeNote')}</div>
			</div>
		</div>
	</div>
</div>
