{*
  Occasion, prize, countdown and stock of one running promotion, under a plan
  card (plan.tpl) or in the banner (plan-details.tpl). Expects $promo.
*}
{if $promo.occasion != ''}
	<div class="promo-strip-line promo-banner-line">📣 <span>{$promo.occasion|escape:'html'}</span></div>
{/if}
{if $promo.prize != ''}
	<div class="promo-strip-line promo-banner-line">🎁 <span>{$translate->get('PromoPrizeLine')|replace:'%range%':$promo.prize}</span></div>
{/if}
{if $promo.ends_at > 0}
	<div class="promo-strip-line promo-banner-line promo-timer-line">⏳ <span class="promo-timer-label">{$translate->get('PromoEndsIn')}</span>
		<span class="promo-timer" data-end="{$promo.ends_at}" data-now="{$promo.now}" data-day="{$translate->get('PromoDayShort')|escape:'html'}"></span>
	</div>
{/if}
{if $promo.left !== null}
	<div class="promo-strip-line promo-banner-line promo-left">🔢 <span>{$translate->get('PromoLeft')|replace:'%n%':"<b>{$promo.left}</b>"}</span></div>
{/if}
