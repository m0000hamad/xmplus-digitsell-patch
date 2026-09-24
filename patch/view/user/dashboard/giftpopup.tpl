{*
 * Congratulation popup for a Telegram gift (bot link or channel) the visitor
 * has not been shown yet - User::newGifts() marks what it returns as seen.
 * Shows what was won and why, the traffic now on the plan and until when, and
 * while the channel gift is still open to them, a nudge towards it.
 *}
{$gifts = $user->newGifts()}
{if count($gifts) > 0}
{$gfUntil = strtotime($user->expire_in)}
{$gfDays = max(0, floor(($gfUntil - time()) / 86400))}
{$gfJoin = $user->tgJoin()}

{literal}
<style>
.gfp-back {
	position: fixed;
	inset: 0;
	z-index: 1065;
	display: flex;
	align-items: center;
	justify-content: center;
	padding: 16px;
	background: rgba(10, 14, 30, .5);
	backdrop-filter: blur(6px);
	-webkit-backdrop-filter: blur(6px);
	opacity: 0;
	transition: opacity .25s ease;
}
.gfp-back[hidden] { display: none; }
.gfp-back.gfp-open { opacity: 1; }
.gfp {
	position: relative;
	width: 100%;
	max-width: 380px;
	max-height: calc(100vh - 32px);
	overflow-y: auto;
	scrollbar-width: none;
	border-radius: 28px;
	background: #fff;
	text-align: center;
	box-shadow: 0 30px 80px -20px rgba(15, 23, 42, .45);
	transform: translateY(18px) scale(.94);
	transition: transform .4s cubic-bezier(.2, .9, .3, 1.35);
}
.gfp::-webkit-scrollbar { display: none; }
.gfp-open .gfp { transform: none; }
.gfp-hero {
	position: relative;
	overflow: hidden;
	padding: 30px 22px 24px;
	color: #fff;
	background:
		radial-gradient(120% 90% at 100% 0%, rgba(255, 255, 255, .25), transparent 55%),
		linear-gradient(145deg, #fbbf24, #fb923c 45%, #ec4899);
}
.gfp-badge {
	width: 72px;
	height: 72px;
	margin: 0 auto 12px;
	border-radius: 24px;
	display: flex;
	align-items: center;
	justify-content: center;
	font-size: 32px;
	background: rgba(255, 255, 255, .22);
	box-shadow: inset 0 0 0 1px rgba(255, 255, 255, .4), 0 12px 28px -8px rgba(0, 0, 0, .3);
	animation: gfp-pop 1.6s ease-in-out infinite;
}
@keyframes gfp-pop { 0%, 100% { transform: scale(1) rotate(-5deg); } 50% { transform: scale(1.08) rotate(5deg); } }
.gfp-title { margin: 0; font-size: 18px; font-weight: 700; line-height: 1.7; color: #fff; }
.gfp-win {
	margin-top: 10px;
	display: flex;
	flex-direction: column;
	gap: 8px;
	align-items: center;
}
.gfp-amount {
	display: inline-flex;
	align-items: baseline;
	gap: 6px;
	padding: 6px 18px;
	border-radius: 999px;
	background: #fff;
	color: #ea580c;
	font-weight: 900;
	font-size: 22px;
	box-shadow: 0 8px 20px -8px rgba(0, 0, 0, .35);
}
.gfp-amount { direction: ltr; unicode-bidi: isolate; }
.gfp-amount small { font-size: 13px; font-weight: 700; }
.gfp-why { font-size: 12.5px; font-weight: 500; opacity: .95; }
.gfp-body { padding: 18px 22px 18px; }
.gfp-total {
	margin: 0 0 14px;
	padding: 11px 13px;
	border-radius: 14px;
	background: rgba(249, 115, 22, .09);
	color: #3b4459;
	font-size: 13px;
	line-height: 2;
}
.gfp-total b { color: #c2410c; font-weight: 700; }
.gfp-hint {
	display: flex;
	align-items: center;
	gap: 10px;
	margin: 0 0 14px;
	padding: 10px 12px;
	border-radius: 14px;
	text-align: start;
	font-size: 12.5px;
	line-height: 1.9;
	color: #3b4459;
	border: 1px dashed rgba(34, 158, 217, .45);
	background: rgba(34, 158, 217, .06);
}
.gfp-hint b { color: #0e7ac4; }
.gfp-hint a {
	flex: 0 0 auto;
	display: inline-flex;
	align-items: center;
	gap: 6px;
	padding: 8px 12px;
	border-radius: 11px;
	font-size: 12px;
	font-weight: 700;
	color: #fff !important;
	text-decoration: none !important;
	background: linear-gradient(135deg, #2aabee, #229ed9);
	white-space: nowrap;
}
.gfp-ok {
	width: 100%;
	padding: 13px 18px;
	border: 0;
	border-radius: 16px;
	font-family: inherit;
	font-size: 14.5px;
	font-weight: 700;
	color: #fff;
	cursor: pointer;
	background: linear-gradient(135deg, #fb923c, #ec4899);
	box-shadow: 0 12px 26px -10px rgba(236, 72, 153, .8);
}
.gfp-confetti { position: absolute; inset: 0; pointer-events: none; overflow: hidden; }
.gfp-confetti i {
	position: absolute;
	top: -12px;
	width: 7px;
	height: 12px;
	border-radius: 2px;
	opacity: 0;
	animation: gfp-fall 2.6s ease-in forwards;
}
@keyframes gfp-fall {
	0% { opacity: 1; transform: translateY(0) rotate(0); }
	100% { opacity: 0; transform: translateY(260px) rotate(540deg); }
}
html[data-hs-theme="dark"] .gfp { background: #182132; }
html[data-hs-theme="dark"] .gfp-total { background: rgba(251, 146, 60, .12); color: #d5dbe8; }
html[data-hs-theme="dark"] .gfp-total b { color: #fdba74; }
html[data-hs-theme="dark"] .gfp-hint { color: #d5dbe8; background: rgba(34, 158, 217, .1); }
html[data-hs-theme="dark"] .gfp-hint b { color: #7dd3fc; }
@media (max-width: 575.98px) {
	.gfp-back { align-items: flex-end; padding: 0; }
	.gfp { max-width: none; border-radius: 26px 26px 0 0; transform: translateY(100%); padding-bottom: env(safe-area-inset-bottom); }
}
@media (prefers-reduced-motion: reduce) {
	.gfp, .gfp-back { transition: none; }
	.gfp-badge, .gfp-confetti i { animation: none; }
}
</style>
{/literal}

<div class="gfp-back" id="gfpBack" hidden>
	<div class="gfp" role="dialog" aria-modal="true" aria-labelledby="gfpTitle">
		<div class="gfp-hero">
			<div class="gfp-confetti" id="gfpConfetti"></div>
			<div class="gfp-badge"><i class="fa-solid fa-gift"></i></div>
			<h5 class="gfp-title" id="gfpTitle">{$translate->get('GiftPopTitle')}</h5>
			<div class="gfp-win">
				{foreach $gifts as $g}
					{if $g['kind'] == 'free'}
						{if $g['mb'] < 1024}{$gSize = str_replace(['%n%'],[$g['mb']],$translate->get('SizeMB'))}{else}{$gSize = str_replace(['%n%'],[$g['mb'] / 1024],$translate->get('SizeGB'))}{/if}
						<span class="gfp-amount">{str_replace(['%size%','%days%'],[$gSize,$g['days']],$translate->get('GiftPopFree'))}</span>
					{else}
						<span class="gfp-amount">+{$g['gb']} <small>GB</small></span>
					{/if}
					<span class="gfp-why">{if $g['source'] == 'bind'}{$translate->get('GiftPopBind')}{else}{$translate->get('GiftPopChannel')}{/if}</span>
				{/foreach}
			</div>
		</div>
		<div class="gfp-body">
			{$gLeftMb = $user->giftTrafficLeftMb()}
			{if $gLeftMb < 1024}{$gLeft = str_replace(['%n%'],[$gLeftMb],$translate->get('SizeMB'))}{else}{$gLeft = str_replace(['%n%'],[$user->giftTrafficLeft()],$translate->get('SizeGB'))}{/if}
			<p class="gfp-total">{str_replace(['%left%','%until%','%days%'],[$gLeft,"<bdi dir=\"ltr\">{date('Y-m-d', $gfUntil)}</bdi>",$gfDays],$translate->get('GiftPopTotal'))}</p>
			{if $gfJoin['state'] == 'join'}
				<div class="gfp-hint">
					<span>{$translate->get('GiftPopChannelHint')}</span>
					<a href="{$gfJoin['link']|escape:'html'}" target="_blank" rel="noopener"><i class="fa-brands fa-telegram"></i> {$translate->get('TgJoinButton')}</a>
				</div>
			{/if}
			<button type="button" class="gfp-ok" data-gfp-close>{$translate->get('GiftPopOk')}</button>
		</div>
	</div>
</div>

{literal}
<script>
(function () {
	var back = document.getElementById('gfpBack');
	if (!back) { return; }

	function close() {
		back.classList.remove('gfp-open');
		window.setTimeout(function () { back.hidden = true; }, 300);
	}

	function confetti() {
		var box = document.getElementById('gfpConfetti');
		var colors = ['#fff', '#fde68a', '#fbcfe8', '#bae6fd', '#bbf7d0'];
		for (var i = 0; i < 36; i++) {
			var bit = document.createElement('i');
			bit.style.left = (Math.random() * 100) + '%';
			bit.style.background = colors[i % colors.length];
			bit.style.animationDelay = (Math.random() * .9) + 's';
			bit.style.transform = 'rotate(' + (Math.random() * 180) + 'deg)';
			box.appendChild(bit);
		}
	}

	back.addEventListener('click', function (event) {
		if (event.target === back || event.target.closest('[data-gfp-close]')) { close(); }
	});
	document.addEventListener('keydown', function (event) {
		if (event.key === 'Escape' && !back.hidden) { close(); }
	});

	// after the notice modal or a commission message, never on top of them
	var started = Date.now();
	var timer = window.setInterval(function () {
		if (Date.now() - started > 120000) { window.clearInterval(timer); return; }
		if (Date.now() - started < 1200) { return; }
		if (document.querySelector('.modal.show, .swal2-container, .layui-layer-dialog')) { return; }
		window.clearInterval(timer);
		back.hidden = false;
		window.requestAnimationFrame(function () {
			window.requestAnimationFrame(function () { back.classList.add('gfp-open'); confetti(); });
		});
	}, 400);
})();
</script>
{/literal}
{/if}
