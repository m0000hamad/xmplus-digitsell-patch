<template id="coupon-campaign-admin">
  <section class="card my-3" aria-labelledby="coupon-campaign-admin-title">
    <div class="card-body">
      <h2 class="h4" id="coupon-campaign-admin-title">{$translate->get('CouponCampaigns')}</h2>
      <p class="text-muted">{$translate->get('CouponCampaignHint')}</p>
      <label class="d-block mb-3">
        {$translate->get('CouponCampaigns')}
        <select class="form-select" data-campaign-picker>
          <option value="">{$translate->get('CouponCampaignNew')}</option>
        </select>
      </label>
      <form class="row g-3">
        <label class="col-md-4">
          {$translate->get('CouponCode')}
          <input name="code" dir="ltr" class="form-control" required maxlength="128" autocomplete="off">
        </label>
        <label class="col-md-4">
          {$translate->get('CouponCampaignTitle')}
          <input name="title" class="form-control" required maxlength="100">
        </label>
        <label class="col-md-4">
          {$translate->get('CouponCampaignTheme')}
          <select name="theme" class="form-select">
            <option value="black_friday">🛍️ {$translate->get('PromoThemeBlackFriday')}</option>
            <option value="nowruz">🌱 {$translate->get('PromoThemeNowruz')}</option>
            <option value="yalda">🍉 {$translate->get('PromoThemeYalda')}</option>
            <option value="christmas">🎄 {$translate->get('PromoThemeChristmas')}</option>
            <option value="classic">🎟️ {$translate->get('PromoThemeClassic')}</option>
          </select>
        </label>
        <div class="col-12 d-flex gap-3 flex-wrap">
          <label><input type="checkbox" class="form-check-input" name="enabled" checked> {$translate->get('CouponCampaignShow')}</label>
          <label><input type="checkbox" class="form-check-input" name="notify" checked> {$translate->get('CouponCampaignNotify')}</label>
        </div>
        <div class="col-12">
          <button type="submit" class="btn btn-primary" disabled>{$translate->get('CouponCampaignSave')}</button>
          <span class="ms-2" role="status"
            data-error="{$translate->get('CouponCampaignError')|escape:'html'}"
            data-timed="{$translate->get('CouponCampaignTimed')|escape:'html'}"
            data-duplicate="{$translate->get('CouponCampaignDuplicate')|escape:'html'}"
            data-saved="{$translate->get('CouponCampaignSaved')|escape:'html'}"></span>
        </div>
      </form>
    </div>
  </section>
</template>
<template id="coupon-campaign-add-hint">
  <p class="small text-muted mt-2">{$translate->get('CouponCampaignCreateHint')}</p>
</template>
{literal}
<script>
if (/^\/admin\/coupon\/add\/?$/.test(location.pathname)) {
  document.addEventListener('DOMContentLoaded', function () {
    const expiry = document.getElementById('expire_date');
    if (expiry) expiry.parentElement.append(document.getElementById('coupon-campaign-add-hint').content.cloneNode(true));
  });
} else if (/^\/admin\/coupons\/?$/.test(location.pathname)) {
  document.addEventListener('DOMContentLoaded', function () {
    const content = document.querySelector('main');
    if (!content) return;
    const panel = document.getElementById('coupon-campaign-admin').content.firstElementChild.cloneNode(true);
    const firstCard = content.querySelector('.card');
    if (firstCard) firstCard.before(panel);
    else content.prepend(panel);

    const picker = panel.querySelector('[data-campaign-picker]');
    const form = panel.querySelector('form');
    const fields = form.elements;
    const save = form.querySelector('button');
    const status = panel.querySelector('[role="status"]');
    const url = '/xmplus-patch.php?do=couponcampaign.';
    let token = '';
    let entries = {};

    function edit(id) {
      const entry = entries[id];
      form.reset();
      fields.code.readOnly = Boolean(entry);
      if (!entry) return;
      for (const name of ['code', 'title', 'theme']) fields[name].value = entry[name];
      for (const name of ['enabled', 'notify']) fields[name].checked = entry[name];
    }

    function populate(next, id = '') {
      entries = next;
      picker.length = 1;
      for (const [key, entry] of Object.entries(entries)) {
        picker.add(new Option(entry.title + ' · ' + entry.code, key));
      }
      picker.value = id;
      edit(id);
    }

    picker.addEventListener('change', () => {
      status.textContent = '';
      edit(picker.value);
    });
    fetch(url + 'list').then(response => response.json()).then(data => {
      if (!data.ok) throw new Error();
      token = data.token;
      populate(data.entries);
      save.disabled = false;
    }).catch(() => { status.textContent = status.dataset.error; });

    form.addEventListener('submit', async event => {
      event.preventDefault();
      const id = picker.value;
      const body = new URLSearchParams({
        token, id, code: fields.code.value, title: fields.title.value, theme: fields.theme.value,
        enabled: fields.enabled.checked ? '1' : '0', notify: fields.notify.checked ? '1' : '0',
      });
      save.disabled = picker.disabled = true;
      status.textContent = '';
      try {
        const data = await fetch(url + 'save', {method: 'POST', body}).then(response => response.json());
        if (!data.entries) {
          status.textContent = status.dataset[data.reason] || status.dataset.error;
          return;
        }
        populate(data.entries, data.id);
        status.textContent = status.dataset.saved;
      } catch (error) {
        status.textContent = status.dataset.error;
      } finally {
        save.disabled = picker.disabled = false;
      }
    });
  });
}
</script>
{/literal}
