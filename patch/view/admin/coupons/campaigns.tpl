<template id="coupon-campaign-admin">
  <section class="card my-3" id="couponCampaignPanel" aria-labelledby="coupon-campaign-admin-title"
    data-locale="{$session->get('locale')|escape:'html'}">
    <div class="card-body">
      <div class="d-flex flex-wrap align-items-start justify-content-between gap-2">
        <div>
          <h2 class="h4" id="coupon-campaign-admin-title">{$translate->get('CouponCampaigns')}</h2>
          <p class="text-muted">{$translate->get('CouponCampaignHint')}</p>
        </div>
        <a href="/admin/coupon/add" class="btn btn-outline-primary btn-sm">{$translate->get('AddCoupon')}</a>
      </div>
      <form>
        <label class="d-block">
          {$translate->get('CouponCampaignChoose')}
          <select class="form-select mt-1" name="coupon_id" required disabled>
            <option value="">{$translate->get('CouponCampaignChoose')}</option>
          </select>
        </label>
        <section class="border rounded p-3 mt-3" data-coupon-details hidden>
          <dl class="row g-3 mb-2">
            <div class="col-6 col-lg-2"><dt>{$translate->get('CouponCode')}</dt><dd class="mb-0"><bdi data-code></bdi></dd></div>
            <div class="col-6 col-lg-2"><dt>{$translate->get('Discount')}</dt><dd class="mb-0"><bdi data-credit></bdi></dd></div>
            <div class="col-6 col-lg-2"><dt>{$translate->get('CouponCampaignStarts')}</dt><dd class="mb-0" data-start></dd></div>
            <div class="col-6 col-lg-2"><dt>{$translate->get('CouponCampaignEnds')}</dt><dd class="mb-0" data-end></dd></div>
            <div class="col-6 col-lg-2"><dt>{$translate->get('CouponCampaignDuration')}</dt><dd class="mb-0" data-duration></dd></div>
          </dl>
          <p class="text-muted small mb-2" data-schedule
            data-disabled="{$translate->get('CouponCampaignCodeDisabled')|escape:'html'}"
            data-expired="{$translate->get('CouponCampaignCodeExpired')|escape:'html'}"></p>
          <a class="btn btn-outline-primary btn-sm" data-edit-code href="/admin/coupons" hidden>{$translate->get('CouponCampaignEditCode')}</a>
        </section>
        <fieldset class="mt-3" data-campaign-fields disabled hidden>
          <div class="row g-3">
            <label class="col-md-6">
              {$translate->get('CouponCampaignTitle')}
              <input name="title" class="form-control mt-1" required maxlength="100">
            </label>
            <label class="col-md-6">
              {$translate->get('CouponCampaignTheme')}
              <select name="theme" class="form-select mt-1">
                <option value="black_friday">🛍️ {$translate->get('PromoThemeBlackFriday')}</option>
                <option value="nowruz">🌱 {$translate->get('PromoThemeNowruz')}</option>
                <option value="yalda">🍉 {$translate->get('PromoThemeYalda')}</option>
                <option value="christmas">🎄 {$translate->get('PromoThemeChristmas')}</option>
                <option value="classic">🎟️ {$translate->get('PromoThemeClassic')}</option>
              </select>
            </label>
          </div>
          <div class="coupon-campaign-checks mt-3">
            <label class="coupon-campaign-check"><input type="checkbox" class="form-check-input" name="enabled" checked><span>{$translate->get('CouponCampaignShow')}</span></label>
            <label class="coupon-campaign-check"><input type="checkbox" class="form-check-input" name="notify" checked><span>{$translate->get('CouponCampaignNotify')}</span></label>
          </div>
          <button type="submit" class="btn btn-primary mt-3" disabled>{$translate->get('CouponCampaignSave')}</button>
        </fieldset>
        <p class="mb-0 mt-2" role="status"
          data-error="{$translate->get('CouponCampaignError')|escape:'html'}"
          data-timed="{$translate->get('CouponCampaignTimed')|escape:'html'}"
          data-missing="{$translate->get('CouponCampaignMissing')|escape:'html'}"
          data-duplicate="{$translate->get('CouponCampaignDuplicate')|escape:'html'}"
          data-saved="{$translate->get('CouponCampaignSaved')|escape:'html'}"></p>
      </form>
    </div>
  </section>
</template>
<template id="coupon-campaign-native-hint">
  <p class="small text-muted mt-2">
    {$translate->get('CouponCampaignCreateHint')}
    <a data-campaign-link href="/admin/coupons#couponCampaignPanel">{$translate->get('CouponCampaigns')}</a>
  </p>
</template>
{literal}
<style>
#couponCampaignPanel [hidden] { display: none !important; }
#couponCampaignPanel .coupon-campaign-checks { display: flex; flex-wrap: wrap; gap: .7rem 1.5rem; }
#couponCampaignPanel .coupon-campaign-check { display: inline-flex; align-items: flex-start; gap: .65rem; }
#couponCampaignPanel .coupon-campaign-check .form-check-input {
  position: static;
  float: none;
  flex: 0 0 auto;
  margin: .23em 0 0;
}
</style>
<script>
document.addEventListener('DOMContentLoaded', function () {
  const native = location.pathname.match(/^\/admin\/coupon\/(?:add|(\d+)\/edit)\/?$/);
  if (native) {
    const expiry = document.getElementById('expire_date');
    if (expiry) {
      const hint = document.getElementById('coupon-campaign-native-hint').content.cloneNode(true);
      if (native[1]) hint.querySelector('a').href = '/admin/coupons?campaign_coupon=' + native[1] + '#couponCampaignPanel';
      expiry.parentElement.append(hint);
    }
    return;
  }
  if (!/^\/admin\/coupons\/?$/.test(location.pathname)) return;
  const content = document.querySelector('main');
  if (!content) return;
  const panel = document.getElementById('coupon-campaign-admin').content.firstElementChild.cloneNode(true);
  const firstCard = content.querySelector('.card');
  if (firstCard) firstCard.before(panel);
  else content.prepend(panel);

  const form = panel.querySelector('form');
  const fields = form.elements;
  const picker = fields.coupon_id;
  const editor = form.querySelector('[data-campaign-fields]');
  const details = form.querySelector('[data-coupon-details]');
  const editCode = details.querySelector('[data-edit-code]');
  const save = editor.querySelector('button');
  const status = form.querySelector('[role="status"]');
  const url = '/xmplus-patch.php?do=couponcampaign.';
  const locale = (panel.dataset.locale || document.documentElement.lang || 'en').replace('_', '-');
  const date = new Intl.DateTimeFormat(locale, {
    timeZone: 'Asia/Tehran', calendar: 'gregory', dateStyle: 'medium', timeStyle: 'short',
  });
  const number = new Intl.NumberFormat(locale);
  const percent = new Intl.NumberFormat(locale, {style: 'percent', maximumFractionDigits: 2});
  const timeUnits = [['day', 86400], ['hour', 3600], ['minute', 60], ['second', 1]];
  const coupons = new Map();
  let token = '';
  let entries = {};

  function campaign(couponId) {
    return Object.entries(entries).find(([, entry]) => String(entry.coupon_id) === couponId);
  }

  function duration(seconds) {
    if (seconds <= 0) return '—';
    const parts = [];
    for (const [unit, length] of timeUnits) {
      const count = Math.floor(seconds / length);
      seconds %= length;
      if (count) parts.push(new Intl.NumberFormat(locale, {style: 'unit', unit, unitDisplay: 'long'}).format(count));
    }
    return new Intl.ListFormat(locale).format(parts);
  }

  function timed(coupon) {
    return coupon && coupon.start > 0 && coupon.end > coupon.start;
  }

  function showSchedule(coupon) {
    const schedule = details.querySelector('[data-schedule]');
    if (!coupon) schedule.textContent = status.dataset.missing;
    else if (!timed(coupon)) schedule.textContent = status.dataset.timed;
    else if (!coupon.enabled) schedule.textContent = schedule.dataset.disabled;
    else if (coupon.end <= Date.now() / 1000) schedule.textContent = schedule.dataset.expired;
    else schedule.textContent = '';
    schedule.hidden = !schedule.textContent;
  }

  function edit() {
    const coupon = coupons.get(picker.value);
    const entry = campaign(picker.value)?.[1];
    details.hidden = editor.hidden = editor.disabled = !picker.value;
    status.textContent = '';
    fields.title.value = entry?.title || '';
    fields.theme.value = entry?.theme || 'black_friday';
    fields.enabled.checked = entry ? entry.enabled : true;
    fields.notify.checked = entry ? entry.notify : true;
    if (!picker.value) return;
    details.querySelector('[data-code]').textContent = coupon?.code || entry?.code || '—';
    details.querySelector('[data-credit]').textContent = coupon?.credit == null ? '—'
      : coupon.percentage ? percent.format(coupon.credit / 100) : number.format(coupon.credit);
    details.querySelector('[data-start]').textContent = coupon?.start ? date.format(coupon.start * 1000) : '—';
    details.querySelector('[data-end]').textContent = coupon?.end ? date.format(coupon.end * 1000) : '—';
    details.querySelector('[data-duration]').textContent = timed(coupon) ? duration(coupon.end - coupon.start) : '—';
    showSchedule(coupon);
    editCode.hidden = !coupon;
    if (coupon) editCode.href = '/admin/coupon/' + coupon.id + '/edit';
    updateSave();
  }

  function updateSave() {
    save.disabled = !timed(coupons.get(picker.value)) && (fields.enabled.checked || !campaign(picker.value));
  }

  function populate(id = '') {
    picker.length = 1;
    for (const [key, coupon] of coupons) {
      const entry = campaign(key)?.[1];
      picker.add(new Option(entry ? coupon.code + ' · ' + entry.title : coupon.code, key));
    }
    for (const entry of Object.values(entries)) {
      if (!coupons.has(String(entry.coupon_id))) {
        picker.add(new Option(entry.code + ' · ' + status.dataset.missing, String(entry.coupon_id)));
      }
    }
    picker.value = id;
    edit();
  }

  picker.addEventListener('change', edit);
  fields.enabled.addEventListener('change', updateSave);
  fetch(url + 'list').then(response => response.json()).then(data => {
    if (!data.ok || !Array.isArray(data.coupons)) throw new Error();
    token = data.token;
    entries = data.entries;
    data.coupons.forEach(coupon => coupons.set(String(coupon.id), coupon));
    populate(new URLSearchParams(location.search).get('campaign_coupon') || '');
    picker.disabled = false;
  }).catch(() => { status.textContent = status.dataset.error; });

  form.addEventListener('submit', async event => {
    event.preventDefault();
    if (save.disabled || !picker.value) return;
    const couponId = picker.value;
    const id = campaign(couponId)?.[0] || '';
    const body = new URLSearchParams({
      token, id, coupon_id: couponId, title: fields.title.value, theme: fields.theme.value,
      enabled: fields.enabled.checked ? '1' : '0', notify: fields.notify.checked ? '1' : '0',
    });
    picker.disabled = editor.disabled = true;
    status.textContent = '';
    try {
      const data = await fetch(url + 'save', {method: 'POST', body}).then(response => response.json());
      if (!data.entries) {
        status.textContent = status.dataset[data.reason] || status.dataset.error;
        return;
      }
      entries = data.entries;
      populate(couponId);
      status.textContent = status.dataset.saved;
    } catch (error) {
      status.textContent = status.dataset.error;
    } finally {
      picker.disabled = editor.disabled = false;
      updateSave();
    }
  });
});
</script>
{/literal}
