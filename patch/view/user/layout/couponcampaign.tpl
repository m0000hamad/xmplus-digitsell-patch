<div id="coupon-offers" hidden
  data-locale="{$session->get('locale')|escape:'html'}"
  data-applied="{$translate->get('CouponCampaignSelected')|escape:'html'}"
  data-use="{$translate->get('CouponCampaignUse')|escape:'html'}">
  <button type="button" class="offer-corner" aria-haspopup="dialog" aria-controls="offer-dialog">
    <span class="offer-icon" aria-hidden="true"></span>
    <span class="offer-corner-copy">
      <strong></strong>
      <small><span data-offer-selected hidden></span><bdi dir="ltr" data-offer-clock></bdi></small>
    </span>
    <span class="offer-count" hidden></span>
  </button>
  <dialog id="offer-dialog" class="offer-dialog" aria-labelledby="offer-title">
    <header>
      <h2 id="offer-title">{$translate->get('CouponCampaignOffers')}</h2>
      <button type="button" class="offer-close" aria-label="{$translate->get('Close')|escape:'html'}">×</button>
    </header>
    <div class="offer-list"></div>
  </dialog>
  <template>
    <article class="offer-ticket">
      <div class="offer-ticket-art">
        <span class="offer-icon" aria-hidden="true"></span>
        <div><h3></h3><strong class="offer-percent" data-offer-percent hidden></strong></div>
      </div>
      <div class="offer-ticket-actions">
        <span class="offer-time">{$translate->get('CouponCampaignRemaining')} <bdi dir="ltr" data-offer-clock></bdi></span>
        <button type="button" class="offer-use"></button>
      </div>
    </article>
  </template>
</div>
<link rel="stylesheet" href="/assets/css/coupon-campaign.css?v=1.38.50">
<script defer src="/assets/js/coupon-campaign.js?v=1.38.50"></script>
