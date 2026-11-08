{*
  The big stickers on a plan card (plan.tpl): starbursts on the empty side of
  the coloured cap, straddling its bottom edge so they pop out onto the card.
  Discount, special and prize occupy adjacent slots in that order. Expects
  $promo. Colours, the corner ornament and the particles come from the theme
  class on the card (promo-theme-*, see promostyle.tpl); the particles are
  drawn by CSS, so the <i> stay empty.
*}
{$slot = 0}
{if $promo.kind == 'discount'}
	{$slot = $slot + 1}
	<div class="promo-sticker promo-sticker-discount promo-sticker-slot{$slot} promo-only" aria-hidden="true">
		<div class="promo-sticker-burst">
			{if $promo.percent == 100}
				<span class="promo-sticker-icon">🎁</span>
				<b class="promo-sticker-mid">{$translate->get('PromoFree')}</b>
			{else}
				<b class="promo-sticker-big" dir="ltr">{$promo.percent}٪</b>
				<span class="promo-sticker-small">{$translate->get('PromoStickerOff')}</span>
			{/if}
		</div>
		<i class="promo-sticker-spark"></i><i class="promo-sticker-spark"></i><i class="promo-sticker-spark"></i>
	</div>
{/if}
{if !empty($promo.special) || $promo.kind == 'special'}
	{$slot = $slot + 1}
	<div class="promo-sticker promo-sticker-special{if !empty($promo.special_theme)} promo-special-theme-{$promo.special_theme}{/if} promo-sticker-slot{$slot} promo-only" aria-hidden="true">
		<div class="promo-sticker-burst">
			<span class="promo-sticker-icon">{if isset($promo.special_icon)}{$promo.special_icon}{else}{$promo.theme_icon}{/if}</span>
			<b class="promo-sticker-big">{$translate->get('PromoSpecialLabel')}</b>
		</div>
		<i class="promo-sticker-spark"></i><i class="promo-sticker-spark"></i><i class="promo-sticker-spark"></i>
	</div>
{/if}
{if $promo.prize != ''}
	{$slot = $slot + 1}
	<div class="promo-sticker promo-sticker-prize promo-sticker-slot{$slot} promo-only" aria-hidden="true">
		<div class="promo-sticker-burst">
			<span class="promo-sticker-icon">🎁</span>
			<b class="promo-sticker-mid">{$translate->get('PromoPrizeLabel')}</b>
		</div>
		<i class="promo-sticker-spark"></i><i class="promo-sticker-spark"></i><i class="promo-sticker-spark"></i>
	</div>
{/if}
