{*
  The big "special" / "N% off" sticker on a plan card (plan.tpl): a starburst
  on the empty side of the coloured cap, straddling its bottom edge so it pops
  out onto the card. Expects $promo; draws nothing for a prize-only promotion.
*}
{if $promo.kind == 'discount' || $promo.kind == 'special'}
	<div class="promo-sticker promo-sticker-{$promo.kind} promo-only" aria-hidden="true">
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
