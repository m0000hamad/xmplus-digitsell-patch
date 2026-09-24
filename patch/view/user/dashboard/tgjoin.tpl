{*
 * Telegram channel gift row under the subscription card. TgJoinJob does the
 * granting; this only tells the visitor what is on offer and what to do next.
 *}
{$tgj = $user->tgJoin()}
{if $tgj['state'] == 'link' || $tgj['state'] == 'join'}

{literal}
<style>
.tgj {
	position: relative;
	overflow: hidden;
	display: flex;
	align-items: center;
	gap: 12px;
	flex-wrap: wrap;
	margin-top: 12px;
	padding: 14px 16px;
	border-radius: 18px;
	color: #fff;
	background:
		radial-gradient(120% 120% at 100% 0%, rgba(255, 255, 255, .22), transparent 55%),
		linear-gradient(135deg, #fb923c, #ec4899);
	box-shadow: 0 12px 28px -14px rgba(236, 72, 153, .75);
}
.tgj::after {
	content: "";
	position: absolute;
	width: 140px;
	height: 140px;
	inset-block-start: -70px;
	inset-inline-end: -40px;
	border-radius: 50%;
	border: 1px solid rgba(255, 255, 255, .25);
	pointer-events: none;
}
.tgj-ico {
	flex: 0 0 44px;
	width: 44px;
	height: 44px;
	border-radius: 14px;
	display: flex;
	align-items: center;
	justify-content: center;
	font-size: 20px;
	background: rgba(255, 255, 255, .2);
	box-shadow: inset 0 0 0 1px rgba(255, 255, 255, .35);
	animation: tgj-wiggle 3.4s ease-in-out infinite;
}
@keyframes tgj-wiggle { 0%, 100% { transform: rotate(-6deg); } 50% { transform: rotate(6deg); } }
.tgj-body { position: relative; z-index: 1; flex: 1 1 180px; min-width: 0; }
.tgj-title { font-size: 13.5px; font-weight: 700; line-height: 1.8; }
.tgj-title b { font-weight: 900; }
.tgj-note { font-size: 11.5px; font-weight: 400; opacity: .92; margin-top: 2px; line-height: 1.9; }
.tgj-btn {
	position: relative;
	z-index: 1;
	display: inline-flex;
	align-items: center;
	gap: 7px;
	border-radius: 12px;
	padding: 10px 16px;
	font-size: 13px;
	font-weight: 700;
	color: #ea580c !important;
	text-decoration: none !important;
	white-space: nowrap;
	background: #fff;
	box-shadow: 0 8px 18px -8px rgba(0, 0, 0, .35);
	transition: transform .15s ease;
}
.tgj-btn:hover { transform: translateY(-1px); }
.tgj-btn i { font-size: 16px; color: #229ed9; }
@media (max-width: 575.98px) { .tgj-btn { width: 100%; justify-content: center; } }
@media (prefers-reduced-motion: reduce) { .tgj-ico { animation: none; } }
</style>
{/literal}

<div class="tgj">
	<span class="tgj-ico"><i class="fa-solid fa-gift"></i></span>
	<div class="tgj-body">
		<div class="tgj-title">{if $tgj['free']}{$translate->get('TgJoinTitleFree')}{else}{$translate->get('TgJoinTitle')}{/if}</div>
		<div class="tgj-note">
			{if $tgj['state'] == 'link'}
				{$translate->get('TgJoinNeedLink')}
			{else}
				{$translate->get('TgJoinHow')}
			{/if}
		</div>
	</div>
	{if $tgj['state'] == 'link'}
		<a class="tgj-btn" href="https://telegram.me/{$Config['telegrambot']|escape:'url'}?start={$user->tg_token|escape:'url'}" target="_blank" rel="noopener"><i class="fa-brands fa-telegram"></i> {$translate->get('TelegramConnect')}</a>
	{else}
		<a class="tgj-btn" href="{$tgj['link']|escape:'html'}" target="_blank" rel="noopener"><i class="fa-brands fa-telegram"></i> {$translate->get('TgJoinButton')}</a>
	{/if}
</div>
{/if}
