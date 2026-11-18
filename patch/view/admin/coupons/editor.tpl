{if strpos($smarty.server.REQUEST_URI, '/admin/coupon/') === 0}
<template id="coupon-editor-template">
  <section class="coupon-editor" aria-labelledby="coupon-editor-heading"
    data-edit="{$translate->get('EditCoupon')|escape:'html'}"
    data-percent="{$translate->get('Percentage')|escape:'html'}">
    <header class="coupon-editor-header">
      <h2 id="coupon-editor-heading">{$translate->get('AddCoupon')}</h2>
      <div data-control="status"><label>{$translate->get('Status')}</label><div data-control-mount></div></div>
    </header>
    <div class="coupon-editor-body">
      <section class="coupon-editor-section" aria-labelledby="coupon-discount-heading">
        <h3 id="coupon-discount-heading">{$translate->get('Discount')}</h3>
        <div class="coupon-editor-grid">
          <div data-control="code"><label>{$translate->get('CouponCode')}</label><div data-control-mount></div></div>
          <div data-control="type"><label>{$translate->get('Type')}</label><div data-control-mount></div></div>
          <div data-control="credit"><label data-credit-label
            data-credit="{$translate->get('Credit')|escape:'html'}"
            data-percent="{$translate->get('PromoPercent')|escape:'html'}">{$translate->get('Credit')}</label><div data-control-mount></div></div>
        </div>
      </section>
      <section class="coupon-editor-section" aria-labelledby="coupon-schedule-heading">
        <h3 id="coupon-schedule-heading">{$translate->get('CouponCampaignDuration')}</h3>
        <div class="coupon-editor-grid">
          <label>{$translate->get('CouponCampaignStarts')}<input type="datetime-local" step="1" class="form-control" data-start-calendar></label>
          <label>{$translate->get('CouponCampaignEnds')}<input type="datetime-local" step="1" class="form-control" data-end-calendar></label>
          <label>{$translate->get('CouponEditorDays')}<input type="number" min="1" step="1" class="form-control" data-days></label>
        </div>
        <p class="coupon-editor-help mb-0">{$translate->get('CouponEditorDaysHint')}</p>
        <p class="text-danger small mb-0" role="status" data-date-error
          data-message="{$translate->get('CouponEditorInvalidWindow')|escape:'html'}" hidden></p>
      </section>
      <section class="coupon-editor-section" aria-labelledby="coupon-eligibility-heading">
        <h3 id="coupon-eligibility-heading">{$translate->get('CouponEditorEligibility')}</h3>
        <div class="coupon-editor-grid">
          <div data-control="newuser"><label>{$translate->get('CouponEditorFirstOrder')}</label><div data-control-mount></div></div>
          <div class="coupon-editor-wide" data-control="packageid"><label>{$translate->get('SelectPlan')}</label><div data-control-mount></div></div>
        </div>
        <p class="coupon-editor-help mb-0">{$translate->get('CouponEditorFirstOrderHint')}</p>
        {if !isset($coupon->id)}
        <p class="coupon-editor-help mb-0">{$translate->get('CouponRuleAfterCreate')}</p>
        {/if}
      </section>
      <details class="coupon-editor-section">
        <summary>{$translate->get('CouponEditorLimits')}</summary>
        <div class="coupon-editor-grid mt-3">
          <div data-control="plan_limit"><label></label><div data-control-mount></div></div>
          <div data-control="usage_type"><label>{$translate->get('UsageType')}</label><div data-control-mount></div></div>
          <div data-control="usage_count"><label></label><div data-control-mount></div></div>
          <div data-control="userlimit"><label>{$translate->get('UserLimit')}</label><div data-control-mount></div></div>
          <div class="coupon-editor-cycles" data-cycles></div>
        </div>
      </details>
      <section class="coupon-editor-section coupon-editor-publish" aria-labelledby="coupon-editor-campaign-heading">
        <div>
          <h3 id="coupon-editor-campaign-heading">{$translate->get('CouponCampaigns')}</h3>
          <p class="coupon-editor-help mb-0">{$translate->get('CouponEditorCampaignHint')}</p>
        </div>
        <a href="/admin/coupons#couponCampaignPanel" class="btn btn-outline-primary btn-sm" data-campaign-link>{$translate->get('CouponCampaigns')}</a>
      </section>
    </div>
    <footer class="coupon-editor-actions" data-native-actions></footer>
  </section>
</template>
{if isset($coupon->id) && $coupon->id > 0}
<fieldset class="coupon-editor coupon-editor-rules" data-coupon-rules="{$coupon->id|escape:'html'}" disabled>
  <legend>{$translate->get('CouponRuleTitle')}</legend>
  <label class="coupon-rule-check">
    <input type="checkbox" class="form-check-input" data-rule-fresh>
    <span>{$translate->get('CouponRuleFresh')}<small>{$translate->get('CouponRuleFreshHint')}</small></span>
  </label>
  <label class="coupon-rule-check">
    <input type="checkbox" class="form-check-input" data-rule-ip>
    <span>{$translate->get('CouponRuleIp')}<small>{$translate->get('CouponRuleIpHint')}</small></span>
  </label>
  <button type="button" class="btn btn-outline-primary btn-sm" data-rule-save>{$translate->get('CouponRuleSave')}</button>
  <span class="coupon-editor-help" role="status" data-rule-status
    data-error="{$translate->get('CouponCampaignError')|escape:'html'}"
    data-schedule="{$translate->get('CouponRuleSchedule')|escape:'html'}"
    data-saved="{$translate->get('CouponRuleSaved')|escape:'html'}"></span>
</fieldset>
{/if}
<link rel="stylesheet" href="/assets/css/coupon-editor.css?v=1.38.53">
<script defer src="/assets/js/coupon-editor.js?v=1.38.53"></script>
{/if}
