{literal}
<script>
document.addEventListener('DOMContentLoaded', function () {
  const match = location.pathname.match(/^\/admin\/server\/(\d+)\/edit\/?$/);
  const address = document.getElementById('address');
  if (!match || !address) return;
  const box = document.createElement('div'); box.className = 'border rounded p-3 my-3';
  const title = document.createElement('h5'); title.textContent = 'نام و دامنه هر لینک اشتراک'; box.appendChild(title);
  const hint = document.createElement('p'); hint.className = 'small text-muted';
  hint.textContent = 'برای هر لینک، نام نمایشی و دامنه اتصال همین سرور را تعیین کنید. پورت، UUID، SNI و سایر تنظیمات مشترک می‌مانند. نام‌ها و دامنه‌ها را با دکمه همین بخش ذخیره کنید.';
  box.appendChild(hint);
  const fields = document.createElement('div'); box.appendChild(fields);
  const save = document.createElement('button'); save.type = 'button'; save.className = 'btn btn-primary mt-2'; save.textContent = 'ذخیره نام و دامنه‌های اشتراک'; save.disabled = true; box.appendChild(save);
  const status = document.createElement('div'); status.setAttribute('role', 'status'); status.className = 'small mt-2'; box.appendChild(status);
  address.closest('.row').after(box);
  // Retain the native value for the encoded save handler, without a third UI field.
  address.closest('.row').hidden = true;
  const endpoint = '/xmplus-patch.php?do=subprofiles.domains.';
  let token = ''; const inputs = {}, names = {};
  const nativeName = document.getElementById('name');
  const nativeNameLabel = document.querySelector('label[for="name"]');
  if (nativeNameLabel) nativeNameLabel.textContent = 'نام سرور در پنل';
  fetch(endpoint + 'get&server_id=' + match[1], {credentials: 'same-origin', cache: 'no-store'})
    .then(r => r.json()).then(data => {
      if (!data.ok) throw new Error(data.error); token = data.token;
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
    save.disabled = true; status.textContent = 'در حال ذخیره…';
    try {
      const body = new URLSearchParams({token, server_id: match[1], domains: JSON.stringify({1: inputs[1].value, 2: inputs[2].value}), names: JSON.stringify({1: names[1].value, 2: names[2].value})});
      const data = await (await fetch(endpoint + 'save', {method: 'POST', credentials: 'same-origin', body})).json();
      if (!data.ok) throw new Error(data.error); status.textContent = 'نام و دامنه‌های هر دو لینک ذخیره شد.';
    } catch (e) {status.textContent = e.message;} finally {save.disabled = false;}
  });
});
</script>
{/literal}
