{*
  The animated badges of one running promotion. Expects $promo from
  Package::promo(). Label text sits directly in the badge (not in a span) so
  the stars' :nth-of-type positions stay right.
*}
{if $promo.kind == 'discount'}
	<span class="promo-badge promo-badge-discount promo-only"><i class="promo-star">✦</i><i class="promo-star">✦</i><i class="promo-star">✦</i>🔥 {$translate->get('PromoOffLabel')|replace:'%n%':$promo.percent}</span>
{elseif $promo.kind == 'special'}
	<span class="promo-badge promo-badge-special promo-only"><i class="promo-star">✦</i><i class="promo-star">✦</i><i class="promo-star">✦</i>⭐ {$translate->get('PromoSpecialLabel')}</span>
{/if}
{if $promo.prize != ''}
	<span class="promo-badge promo-badge-prize promo-only"><i class="promo-star">✦</i><i class="promo-star">✦</i><i class="promo-star">✦</i>🎁 {$translate->get('PromoPrizeLabel')}</span>
{/if}
