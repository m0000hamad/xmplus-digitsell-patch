{*
  The big stickers on a plan card (plan.tpl): starbursts on the empty side of
  the coloured cap, straddling its bottom edge so they pop out onto the card.
  "special" / "N% off" takes the first slot, the prize the next one. Expects
  $promo.
*}
{$slot = 0}
{if $promo.kind == 'discount' || $promo.kind == 'special'}
	{$slot = $slot + 1}
	<div class="promo-sticker promo-sticker-{$promo.kind} promo-sticker-slot{$slot} promo-only" aria-hidden="true">
		<div class="promo-sticker-burst">
			{if $promo.kind == 'discount'}
				<b class="promo-sticker-big" dir="ltr">{$promo.percent}٪</b>
				<span class="promo-sticker-small">{$translate->get('PromoStickerOff')}</span>
			{else}
				<span class="promo-sticker-icon">⭐</span>
				<b class="promo-sticker-big">{$translate->get('PromoSpecialLabel')}</b>
			{/if}
		</div>
		<i class="promo-sticker-spark">✦</i><i class="promo-sticker-spark">✦</i><i class="promo-sticker-spark">✦</i>
	</div>
{/if}
{if $promo.prize != ''}
	{$slot = $slot + 1}
	<div class="promo-sticker promo-sticker-prize promo-sticker-slot{$slot} promo-only" aria-hidden="true">
		<div class="promo-sticker-burst">
			<span class="promo-sticker-icon">🎁</span>
			<b class="promo-sticker-mid">{$translate->get('PromoPrizeLabel')}</b>
		</div>
		<i class="promo-sticker-spark">✦</i><i class="promo-sticker-spark">✦</i><i class="promo-sticker-spark">✦</i>
	</div>
{/if}
