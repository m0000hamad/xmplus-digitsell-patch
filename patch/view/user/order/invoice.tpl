{literal}
<style>
/* ------------------------------------------------------------------ *
 * The invoice.
 *
 * It used to be a short list of four numbers with no seller, no buyer
 * and nothing to print. It now reads as a document, and prints as one.
 * The nine values the details endpoint returns keep their element ids,
 * so the existing handler fills this without changing.
 * ------------------------------------------------------------------ */
#InvoiceModal .modal-dialog { max-width: 760px; }
#InvoiceModal .modal-content {
	border: 0;
	border-radius: 20px;
	overflow: hidden;
	background: #fff;
}

.inv-top {
	background: linear-gradient(135deg, #4f46e5, #7c3aed 55%, #0ea5e9);
	color: #fff;
	padding: 20px 24px;
	display: flex;
	align-items: flex-start;
	justify-content: space-between;
	gap: 14px;
	flex-wrap: wrap;
}
.inv-brand { display: flex; align-items: center; gap: 11px; }
.inv-logo {
	width: 44px;
	height: 44px;
	border-radius: 13px;
	background: rgba(255, 255, 255, .18);
	display: inline-flex;
	align-items: center;
	justify-content: center;
	font-size: 21px;
	flex: 0 0 auto;
	overflow: hidden;
}
.inv-logo img { max-width: 100%; max-height: 100%; display: block; }
.inv-shop { font-size: 16px; font-weight: 800; color: #fff; margin: 0; line-height: 1.6; }
.inv-shop-sub { font-size: 11.5px; color: rgba(255, 255, 255, .8); direction: ltr; unicode-bidi: isolate; }

.inv-label { text-align: end; }
.inv-doc { font-size: 19px; font-weight: 800; margin: 0 0 4px; color: #fff; }
.inv-no {
	font-size: 12px;
	font-weight: 700;
	background: rgba(255, 255, 255, .18);
	border: 1px solid rgba(255, 255, 255, .3);
	border-radius: 999px;
	padding: 4px 12px;
	display: inline-block;
	direction: ltr;
	unicode-bidi: isolate;
}

.inv-body { padding: 22px 24px 24px; }

.inv-parties {
	display: grid;
	grid-template-columns: repeat(auto-fit, minmax(230px, 1fr));
	gap: 12px;
	margin-bottom: 18px;
}
.inv-party {
	border: 1.5px solid rgba(23, 32, 61, .1);
	border-radius: 15px;
	padding: 14px 16px;
	background: rgba(23, 32, 61, .02);
}
.inv-party-role {
	font-size: 10.5px;
	font-weight: 800;
	letter-spacing: .5px;
	text-transform: uppercase;
	color: #8c98ab;
	margin-bottom: 7px;
}
.inv-party-name { font-size: 14px; font-weight: 800; color: #16203d; line-height: 1.8; }
.inv-party-line {
	font-size: 12px;
	color: #56617a;
	line-height: 2;
	word-break: break-word;
}
.inv-party-line b { direction: ltr; unicode-bidi: isolate; font-weight: 700; }

.inv-meta {
	display: grid;
	grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
	gap: 10px;
	margin-bottom: 18px;
}
.inv-meta-box {
	border-radius: 14px;
	padding: 12px 14px;
	background: var(--soft, rgba(99, 102, 241, .08));
}
.inv-meta-label { font-size: 10.5px; font-weight: 700; color: #8c98ab; display: block; margin-bottom: 3px; }
.inv-meta-value {
	font-size: 13px;
	font-weight: 800;
	color: #16203d;
	line-height: 1.7;
	word-break: break-word;
}

.inv-table { width: 100%; border-collapse: collapse; margin-bottom: 16px; }
.inv-table th {
	font-size: 11px;
	font-weight: 800;
	letter-spacing: .4px;
	text-transform: uppercase;
	color: #8c98ab;
	padding: 10px 12px;
	border-bottom: 1.5px solid rgba(23, 32, 61, .1);
	text-align: start;
}
.inv-table th:last-child, .inv-table td:last-child { text-align: end; }
.inv-table td {
	padding: 14px 12px;
	font-size: 13.5px;
	color: #16203d;
	border-bottom: 1px solid rgba(23, 32, 61, .06);
	vertical-align: top;
}
.inv-item-name { font-weight: 800; line-height: 1.8; }
.inv-item-sub { font-size: 11.5px; color: #8c98ab; margin-top: 2px; }
.inv-amount { font-weight: 700; direction: ltr; unicode-bidi: isolate; white-space: nowrap; }

.inv-totals { margin-inline-start: auto; max-width: 330px; }
.inv-total-line {
	display: flex;
	justify-content: space-between;
	align-items: center;
	gap: 12px;
	font-size: 13px;
	color: #56617a;
	padding: 7px 0;
}
.inv-total-line span:last-child { font-weight: 700; color: #16203d; direction: ltr; unicode-bidi: isolate; }
.inv-total-off span:last-child { color: #be123c; }
.inv-grand {
	display: flex;
	justify-content: space-between;
	align-items: center;
	gap: 12px;
	margin-top: 8px;
	padding: 13px 15px;
	border-radius: 14px;
	background: linear-gradient(135deg, rgba(16, 185, 129, .12), rgba(6, 182, 212, .1));
	border: 1.5px solid rgba(16, 185, 129, .32);
}
.inv-grand-label { font-size: 13.5px; font-weight: 800; color: #16203d; }
.inv-grand-value {
	font-size: 18px;
	font-weight: 800;
	color: #047857;
	direction: ltr;
	unicode-bidi: isolate;
}

.inv-status {
	display: inline-flex;
	align-items: center;
	gap: 6px;
	font-size: 11.5px;
	font-weight: 800;
	border-radius: 999px;
	padding: 5px 12px;
	background: rgba(16, 185, 129, .14);
	color: #047857;
}
.inv-status::before {
	content: "";
	width: 7px;
	height: 7px;
	border-radius: 50%;
	background: #10b981;
}

.inv-foot {
	margin-top: 18px;
	border-top: 1.5px dashed rgba(23, 32, 61, .12);
	padding-top: 15px;
	font-size: 12px;
	color: #7a869f;
	line-height: 2.1;
	text-align: center;
}
.inv-thanks { font-size: 13px; font-weight: 800; color: #16203d; margin-bottom: 5px; }

.inv-actions { display: flex; gap: 9px; margin-top: 18px; }
.inv-btn {
	flex: 1 1 0;
	border: 0;
	border-radius: 14px;
	padding: 12px 16px;
	font-size: 13px;
	font-weight: 800;
	cursor: pointer;
	transition: transform .14s ease, box-shadow .14s ease;
}
.inv-btn:active { transform: scale(.98); }
.inv-btn-print {
	flex: 2 1 0;
	color: #fff;
	background: linear-gradient(135deg, #4f46e5, #7c3aed);
	box-shadow: 0 6px 16px rgba(99, 102, 241, .32);
}
.inv-btn-close { color: #56617a; background: rgba(23, 32, 61, .07); }

html[data-hs-theme="dark"] #InvoiceModal .modal-content { background: #1c2536; }
html[data-hs-theme="dark"] .inv-party { background: rgba(255, 255, 255, .04); border-color: rgba(255, 255, 255, .1); }
html[data-hs-theme="dark"] .inv-party-name,
html[data-hs-theme="dark"] .inv-meta-value,
html[data-hs-theme="dark"] .inv-table td,
html[data-hs-theme="dark"] .inv-grand-label,
html[data-hs-theme="dark"] .inv-thanks,
html[data-hs-theme="dark"] .inv-total-line span:last-child { color: #e7eaf3; }
html[data-hs-theme="dark"] .inv-party-line { color: #9fb0cc; }
html[data-hs-theme="dark"] .inv-table td { border-bottom-color: rgba(255, 255, 255, .07); }
html[data-hs-theme="dark"] .inv-table th { border-bottom-color: rgba(255, 255, 255, .12); }
html[data-hs-theme="dark"] .inv-grand-value { color: #34d399; }
html[data-hs-theme="dark"] .inv-btn-close { color: #cfd8ea; background: rgba(255, 255, 255, .08); }

@media (max-width: 575.98px) {
	.inv-top { padding: 17px; }
	.inv-label { text-align: start; }
	.inv-body { padding: 18px; }
	.inv-actions { flex-wrap: wrap; }
	.inv-btn, .inv-btn-print { flex: 1 1 100%; }
	.inv-totals { max-width: 100%; }
}

/* ---- on paper ---- */
@media print {
	body * { visibility: hidden !important; }
	#InvoiceModal, #InvoiceModal * { visibility: visible !important; }

	#InvoiceModal {
		position: absolute !important;
		inset: 0 !important;
		display: block !important;
		overflow: visible !important;
		background: #fff !important;
		padding: 0 !important;
	}
	#InvoiceModal .modal-dialog {
		max-width: 100% !important;
		width: 100% !important;
		margin: 0 !important;
		transform: none !important;
	}
	#InvoiceModal .modal-content {
		border-radius: 0 !important;
		box-shadow: none !important;
		background: #fff !important;
	}

	/* a colour-managed gradient does not survive most printers */
	.inv-top {
		background: #fff !important;
		color: #16203d !important;
		border-bottom: 2px solid #16203d;
		padding-bottom: 14px;
	}
	.inv-shop, .inv-doc { color: #16203d !important; }
	.inv-shop-sub { color: #56617a !important; }
	.inv-logo { background: rgba(23, 32, 61, .08) !important; }
	.inv-no { background: transparent !important; border-color: #16203d !important; color: #16203d !important; }
	.inv-grand { background: transparent !important; border: 1.5px solid #16203d !important; }
	.inv-grand-value, .inv-party-name, .inv-meta-value, .inv-table td { color: #16203d !important; }
	.inv-status { background: transparent !important; border: 1px solid #047857; }

	.modal-backdrop { display: none !important; }
	.inv-noprint { display: none !important; }

	@page { margin: 12mm; }
}
</style>
{/literal}

<div class="modal fade" id="InvoiceModal" tabindex="-1" aria-labelledby="InvoiceModal" role="dialog" aria-hidden="true" data-bs-backdrop="static" data-bs-keyboard="false">
	<div class="modal-dialog modal-dialog-centered modal-dialog-scrollable" role="document">
		<div class="modal-content">

			<div class="inv-top">
				<div class="inv-brand">
					<span class="inv-logo">
						{if isset($Config['logo_path']) && $Config['logo_path'] != ""}
							<img src="{$Config['logo_path']}" alt="">
						{else}
							🏪
						{/if}
					</span>
					<div>
						<h5 class="inv-shop">{$Config['appName']}</h5>
						<span class="inv-shop-sub">{$Config['appName']|lower}</span>
					</div>
				</div>

				<div class="inv-label">
					<h4 class="inv-doc">🧾 {$translate->get('InvoiceTitle')}</h4>
					<span class="inv-no">#<span id="order_id"></span></span>
				</div>
			</div>

			<div class="inv-body">

				<div class="inv-parties">
					<div class="inv-party">
						<div class="inv-party-role">{$translate->get('InvoiceFrom')}</div>
						<div class="inv-party-name">{$Config['appName']}</div>
						<div class="inv-party-line">
							{if isset($Config['tg_grouplink']) && $Config['tg_grouplink'] != ""}
								{$translate->get('Support')}: <b>{$Config['tg_grouplink']|escape:'html'}</b>
							{/if}
						</div>
					</div>

					<div class="inv-party">
						<div class="inv-party-role">{$translate->get('InvoiceTo')}</div>
						<div class="inv-party-name">{$user->username|escape:'html'}</div>
						<div class="inv-party-line">
							{$translate->get('Email')}: <b>{$user->email|escape:'html'}</b><br>
							{$translate->get('UserID')}: <b>{$user->id}</b>
						</div>
					</div>
				</div>

				<div class="inv-meta">
					<div class="inv-meta-box" style="--soft:rgba(16,185,129,.1)">
						<span class="inv-meta-label">{$translate->get('Status')}</span>
						<span class="inv-meta-value"><span class="inv-status"><span id="order_status"></span></span></span>
					</div>
					<div class="inv-meta-box" style="--soft:rgba(99,102,241,.09)">
						<span class="inv-meta-label">{$translate->get('DatePaid')}</span>
						<span class="inv-meta-value" id="order_date"></span>
					</div>
					<div class="inv-meta-box" style="--soft:rgba(14,165,233,.09)">
						<span class="inv-meta-label">{$translate->get('GMethod')}</span>
						<span class="inv-meta-value" id="order_method"></span>
					</div>
				</div>

				<table class="inv-table">
					<thead>
						<tr>
							<th>{$translate->get('InvoiceItem')}</th>
							<th>{$translate->get('InvoiceAmount')}</th>
						</tr>
					</thead>
					<tbody>
						<tr>
							<td>
								<div class="inv-item-name" id="order_name"></div>
								<div class="inv-item-sub">{$translate->get('InvoiceItemNote')}</div>
							</td>
							<td class="inv-amount" id="order_price"></td>
						</tr>
					</tbody>
				</table>

				<div class="inv-totals">
					<div class="inv-total-line">
						<span>{$translate->get('SubTotal')}</span>
						<span id="order_price_2"></span>
					</div>
					<div class="inv-total-line inv-total-off">
						<span>{$translate->get('Discount')}</span>
						<span id="order_discount"></span>
					</div>
					<div class="inv-total-line">
						<span>{$translate->get('GatewayFee')}</span>
						<span id="order_fee"></span>
					</div>
					<div class="inv-grand">
						<span class="inv-grand-label">{$translate->get('AmountPaid')}</span>
						<span class="inv-grand-value" id="order_total"></span>
					</div>
				</div>

				<div class="inv-foot">
					<div class="inv-thanks">🙏 {$translate->get('InvoiceThanks')}</div>
					{$translate->get('InvoiceAuto')}
				</div>

				<div class="inv-actions inv-noprint">
					<button type="button" class="inv-btn inv-btn-print" onClick="window.print()">🖨️ {$translate->get('InvoicePrint')}</button>
					<button type="button" class="inv-btn inv-btn-close" data-bs-dismiss="modal">{$translate->get('Close')}</button>
				</div>

			</div>
		</div>
	</div>
</div>

{literal}
<script>
/* The details endpoint sends one subtotal, and the document shows it twice:
   once against the line item and once in the totals. Mirror it rather than
   asking the encoded controller for a second copy. */
(function () {
	var source = document.getElementById('order_price');
	var mirror = document.getElementById('order_price_2');
	if (!source || !mirror || typeof MutationObserver === 'undefined') { return; }

	new MutationObserver(function () {
		mirror.textContent = source.textContent;
	}).observe(source, { childList: true, characterData: true, subtree: true });
})();
</script>
{/literal}
