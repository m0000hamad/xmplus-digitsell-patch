{literal}
<script>
document.addEventListener('DOMContentLoaded', function () {
  const match = location.pathname.match(/^\/admin\/server\/(\d+)\/edit\/?$/);
  const address = document.getElementById('address');
  if (!match || !address) return;
  const box = document.createElement('div'); box.className = 'border rounded p-3 my-3';
  const title = document.createElement('h5'); title.textContent = 'نام و دامنه هر لینک اشتراک'; box.appendChild(title);
  const hint = document.createElement('p'); hint.className = 'small text-muted';
  hint.textContent = 'هر لینک نام، دامنه، پورت و ضریب ترافیک خودش را دارد؛ UUID، SNI و سایر تنظیمات مشترک می‌مانند. مصرف هر دو از حجم همان حساب کم می‌شود. این بخش را با دکمه خودش ذخیره کنید.';
  box.appendChild(hint);
  const fields = document.createElement('div'); box.appendChild(fields);
  const enabledLabel = document.createElement('label'); enabledLabel.className = 'd-block mb-3';
  const enabled = document.createElement('input'); enabled.type = 'checkbox'; enabled.className = 'form-check-input me-2';
  enabledLabel.appendChild(enabled); enabledLabel.appendChild(document.createTextNode('فعال‌سازی پورت و ضریب جدا برای دو لینک')); box.appendChild(enabledLabel);
  const billingHint = document.createElement('p'); billingHint.className = 'small text-muted';
  billingHint.textContent = 'نیازمند عامل Xray نسخه ۱.۴.۰ روی همین سرور است. هر پورت باید در فایروال و مسیر تانل باز باشد. فعال‌سازی یا تغییر پورت یا ضریب، اتصال‌های این سرور را برای اعمال تنظیمات دوباره برقرار می‌کند؛ کاربران اشتراک را به‌روزرسانی کنند.'; box.appendChild(billingHint);
  const save = document.createElement('button'); save.type = 'button'; save.className = 'btn btn-primary mt-2'; save.textContent = 'ذخیره تنظیمات لینک‌ها'; save.disabled = true; box.appendChild(save);
  const status = document.createElement('div'); status.setAttribute('role', 'status'); status.className = 'small mt-2'; box.appendChild(status);
  address.closest('.row').after(box);
  // Retain the native value for the encoded save handler, without a third UI field.
  address.closest('.row').hidden = true;
  const endpoint = '/xmplus-patch.php?do=subprofiles.domains.';
  let token = ''; const inputs = {}, names = {}, ports = {}, rates = {};
  const nativeName = document.getElementById('name');
  const nativeNameLabel = document.querySelector('label[for="name"]');
  if (nativeNameLabel) nativeNameLabel.textContent = 'نام سرور در پنل';
  function showPorts() {
    ['port', 'listeningport', 'server_rate'].forEach(id => {
      const field = document.getElementById(id); if (field) field.closest('.row').hidden = enabled.checked;
    });
  }
  enabled.addEventListener('change', showPorts);
  fetch(endpoint + 'get&server_id=' + match[1], {credentials: 'same-origin', cache: 'no-store'})
    .then(r => r.json()).then(data => {
      if (!data.ok) throw new Error(data.error); token = data.token;
      enabled.checked = !!data.billing.enabled;
      showPorts();
      [1, 2].forEach(slot => {
        const profile = data.profiles[slot - 1];
        const group = document.createElement('fieldset'); group.className = 'border rounded p-3 mb-3';
        const heading = document.createElement('legend'); heading.className = 'fs-6';
        heading.textContent = 'لینک ' + slot + (profile ? ' — ' + profile.name + (profile.enabled ? '' : ' (غیرفعال)') : ' (تعریف نشده)');
        group.appendChild(heading);
        const nameLabel = document.createElement('label'); nameLabel.className = 'd-block mb-2'; nameLabel.textContent = 'نام سرور در این لینک';
        const name = document.createElement('input'); name.type = 'text'; name.className = 'form-control mt-1'; name.maxLength = 80; name.required = true;
        name.value = data.names[slot] || ((nativeName ? nativeName.value : '') + (profile ? ' — ' + profile.name : ''));
        names[slot] = name; nameLabel.appendChild(name); group.appendChild(nameLabel);
        const label = document.createElement('label'); label.className = 'd-block mb-2';
        label.textContent = 'دامنه اتصال این لینک';
        const input = document.createElement('input'); input.type = 'text'; input.className = 'form-control mt-1'; input.dir = 'ltr'; input.maxLength = 253;
        input.placeholder = 'sub.example.com'; input.value = data.domains[slot] || address.value;
        input.required = true;
        inputs[slot] = input; label.appendChild(input); group.appendChild(label); fields.appendChild(group);
        [['پورت این لینک', ports, 'ports', 1, 65535, 1], ['ضریب ترافیک این لینک', rates, 'rates', 0, 1000, 0.01]].forEach(([text, target, key, min, max, step]) => {
          const label = document.createElement('label'); label.className = 'd-block mb-2'; label.textContent = text;
          const field = document.createElement('input'); field.type = 'number'; field.className = 'form-control mt-1'; field.dir = 'ltr'; field.min = min; field.max = max; field.step = step;
          field.value = data.billing[key] && data.billing[key][slot] != null ? data.billing[key][slot] : (key === 'rates' ? (slot === 1 ? 1 : 4) : '');
          target[slot] = field; label.appendChild(field); group.appendChild(label);
        });
        if (profile && !profile.servers.includes(Number(match[1]))) {
          const note = document.createElement('div'); note.className = 'small text-muted mb-2';
          note.textContent = 'این سرور در انتخاب سرورهای این لینک نیست؛ ابتدا آن را در تنظیمات لینک‌های اتصال انتخاب کنید.'; group.appendChild(note);
        }
      }); save.disabled = false;
    }).catch(e => {status.textContent = 'بارگذاری انجام نشد: ' + e.message;});
  save.addEventListener('click', async function () {
    for (const input of [...Object.values(inputs), ...Object.values(names)]) {
      if (!input.value.trim()) { input.value = ''; input.reportValidity(); return; }
    }
    if (enabled.checked) {
      for (const field of [...Object.values(ports), ...Object.values(rates)]) {
        field.required = true; if (!field.reportValidity()) return;
      }
    }
    save.disabled = true; status.textContent = 'در حال ذخیره…';
    try {
      const billing = {enabled: enabled.checked, ports: {1: ports[1].value, 2: ports[2].value}, rates: {1: rates[1].value, 2: rates[2].value}};
      const body = new URLSearchParams({token, server_id: match[1], domains: JSON.stringify({1: inputs[1].value, 2: inputs[2].value}), names: JSON.stringify({1: names[1].value, 2: names[2].value}), billing: JSON.stringify(billing)});
      const data = await (await fetch(endpoint + 'save', {method: 'POST', credentials: 'same-origin', body})).json();
      if (!data.ok) throw new Error(data.error); status.textContent = 'تنظیمات هر دو لینک ذخیره شد.';
    } catch (e) {status.textContent = e.message;} finally {save.disabled = false;}
  });
});
</script>
{/literal}
