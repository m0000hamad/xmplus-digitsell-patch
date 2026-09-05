{literal}
<style>
/* ---- checkout step two: the order and how to pay for it ---- */
.py-card {
	border: 0;
	border-radius: 18px;
	background: #fff;
	box-shadow: 0 10px 26px rgba(23, 32, 61, .07);
	overflow: hidden;
	margin-bottom: 18px;
}
.py-card-head {
	padding: 15px 18px;
	border-bottom: 1px solid rgba(23, 32, 61, .07);
	display: flex;
	align-items: center;
	gap: 9px;
	flex-wrap: wrap;
}
.py-card-emoji {
	width: 34px;
	height: 34px;
	flex: 0 0 auto;
	border-radius: 12px;
	background: rgba(99, 102, 241, .13);
	display: inline-flex;
	align-items: center;
	justify-content: center;
	font-size: 17px;
}
.py-card-title { font-size: 15px; font-weight: 800; color: #16203d; margin: 0; }
.py-card-body { padding: 17px 18px; }

.py-order-id {
	margin-inline-start: auto;
	font-size: 11.5px;
	font-weight: 700;
	color: #4338ca;
	background: rgba(99, 102, 241, .12);
	border-radius: 10px;
	padding: 5px 11px;
	direction: ltr;
	unicode-bidi: isolate;
}

.py-plan-name {
	font-size: 15.5px;
	font-weight: 800;
	color: #16203d;
	margin-bottom: 13px;
	line-height: 1.7;
}
.py-specs { display: grid; grid-template-columns: repeat(auto-fit, minmax(175px, 1fr)); gap: 10px; }
.py-spec {
	display: flex;
	align-items: center;
	gap: 10px;
	border-radius: 14px;
	padding: 11px 13px;
	background: var(--soft, rgba(99, 102, 241, .08));
}
.py-spec-emoji { font-size: 18px; line-height: 1; flex: 0 0 auto; }
.py-spec-label { font-size: 11px; font-weight: 700; color: #8c98ab; display: block; }
.py-spec-value {
	font-size: 13.5px;
	font-weight: 800;
	color: #16203d;
	line-height: 1.6;
	word-break: break-word;
}
.py-note {
	margin-top: 14px;
	border-radius: 14px;
	padding: 13px 15px;
	background: rgba(245, 158, 11, .08);
	border: 1px dashed rgba(245, 158, 11, .35);
	font-size: 12.5px;
	line-height: 2;
	color: #3b4a6b;
}

/* ---- gateways ---- */
.py-ways { display: grid; grid-template-columns: repeat(auto-fit, minmax(160px, 1fr)); gap: 11px; }
.py-way { position: relative; margin: 0; }
.py-way input {
	position: absolute;
	opacity: 0;
	width: 0;
	height: 0;
	pointer-events: none;
}
.py-way-box {
	display: flex;
	align-items: center;
	justify-content: center;
	gap: 8px;
	min-height: 62px;
	border: 1.5px solid rgba(23, 32, 61, .11);
	border-radius: 16px;
	padding: 13px;
	text-align: center;
	cursor: pointer;
	background: #fff;
	font-size: 13.5px;
	font-weight: 800;
	color: #16203d;
	transition: border-color .16s ease, transform .16s ease, box-shadow .16s ease, background .16s ease;
}
.py-way-box:hover { border-color: #10b981; transform: translateY(-2px); }
.py-way input:checked + .py-way-box {
	border-color: #10b981;
	background: linear-gradient(135deg, rgba(16, 185, 129, .13), rgba(6, 182, 212, .1));
	box-shadow: 0 9px 22px rgba(16, 185, 129, .18);
}
.py-way input:checked + .py-way-box::after {
	content: "✓";
	position: absolute;
	top: 9px;
	inset-inline-end: 11px;
	width: 19px;
	height: 19px;
	border-radius: 50%;
	background: #10b981;
	color: #fff;
	font-size: 11px;
	line-height: 19px;
	font-weight: 700;
}
.py-way-icon { font-size: 19px; line-height: 1; }

html[data-hs-theme="dark"] .py-card { background: #1c2536; box-shadow: 0 10px 26px rgba(0, 0, 0, .35); }
html[data-hs-theme="dark"] .py-card-head { border-bottom-color: rgba(255, 255, 255, .08); }
html[data-hs-theme="dark"] .py-card-title,
html[data-hs-theme="dark"] .py-plan-name,
html[data-hs-theme="dark"] .py-spec-value { color: #e7eaf3; }
html[data-hs-theme="dark"] .py-way-box { background: #1c2536; border-color: rgba(255, 255, 255, .1); color: #e7eaf3; }
html[data-hs-theme="dark"] .py-note { color: #b9c2d4; }
html[data-hs-theme="dark"] .py-order-id { color: #c7d2fe; background: rgba(99, 102, 241, .2); }
</style>
{/literal}

<div class="col-12">
	<div class="py-card">
		<div class="py-card-head">
			<span class="py-card-emoji">🧾</span>
			<h3 class="py-card-title">{$translate->get('TransactionNo')}</h3>
			<span class="py-order-id">{$order->order_id}</span>
		</div>
		<div class="py-card-body">
			<div class="py-plan-name">🛒 {$package->name}</div>

			<div class="py-specs">
				<div class="py-spec" style="--soft:rgba(99,102,241,.09)">
					<span class="py-spec-emoji">📊</span>
					<span>
						<span class="py-spec-label">{$translate->get('Bandwidth')}</span>
						<span class="py-spec-value">{if $package->bandwidth < 10000}{$package->bandwidth} GB{else}{$translate->get('Unlimited')}{/if}</span>
					</span>
				</div>

				{if $order->packagetype == 2}
					<div class="py-spec" style="--soft:rgba(14,165,233,.09)">
						<span class="py-spec-emoji">⚡</span>
						<span>
							<span class="py-spec-label">{$translate->get('PortSpeed')}</span>
							<span class="py-spec-value">{$helpers->PortSpd($package->speedlimit)}</span>
						</span>
					</div>
					<div class="py-spec" style="--soft:rgba(139,92,246,.09)">
						<span class="py-spec-emoji">👥</span>
						<span>
							<span class="py-spec-label">{$translate->get('ConnLimit')}</span>
							<span class="py-spec-value">{$package->iplimit}</span>
						</span>
					</div>
					<div class="py-spec" style="--soft:rgba(6,182,212,.09)">
						<span class="py-spec-emoji">🌍</span>
						<span>
							<span class="py-spec-label">{$translate->get('ServerGroup')}</span>
							<span class="py-spec-value">{str_replace([' | '],[''],$helpers->serveGroup($package->server_group))}</span>
						</span>
					</div>
					<div class="py-spec" style="--soft:rgba(245,158,11,.09)">
						<span class="py-spec-emoji">⏳</span>
						<span>
							<span class="py-spec-label">{$translate->get('ValidityPeriod')}</span>
							<span class="py-spec-value">{if $order->plan != "onetime"}{$order->plan_expire} {$translate->get('Days')}{else}{$translate->get('NotExpire')}{/if}</span>
						</span>
					</div>
					<div class="py-spec" style="--soft:rgba(16,185,129,.09)">
						<span class="py-spec-emoji">{if $package->reset_days > 0}🔄{else}🚫{/if}</span>
						<span>
							<span class="py-spec-label">{$translate->get('AllowReset')}</span>
							<span class="py-spec-value">{if $package->reset_days > 0}{$translate->get('Every')} {$package->reset_days} {$translate->get('Days')}{else}{$translate->get('None')}{/if}</span>
						</span>
					</div>
				{/if}
			</div>

			{if $order->packagetype == 2 && $package->order_note != null}
				<div class="py-note">
					📋 {$content = json_decode($package->order_note,true)}{assign var=lang value="_"|explode:$session->get('locale')}{if isset($content[$lang[1]])}{$content[$lang[1]]}{else}{$package->order_note}{/if}
				</div>
			{/if}
		</div>
	</div>

	<div class="py-card">
		<div class="py-card-head">
			<span class="py-card-emoji">💳</span>
			<h3 class="py-card-title">{$translate->get('PaymentMethods')}</h3>
		</div>
		<div class="py-card-body">
			<div class="py-ways">
				{$g = 0}
				{foreach $payments as $payment}
					{$g = $g + 1}
					{$config = json_decode($payment->config,true)}
					<label class="py-way">
						<input type="radio" name="payments" id="{$payment->id}" {if $g == 1}checked{/if} value="{$payment->id}" onClick="Gatewayfee()">
						<span class="py-way-box">
							<span class="py-way-icon">{if isset($config['icon']) && $config['icon'] != ""}{$config['icon']}{else}💳{/if}</span>
							{$payment->name}
						</span>
					</label>
				{/foreach}
			</div>
		</div>
	</div>
</div>
