<div class="card card-shadow shadow-lg rounded mb-3 mb-lg-5" id="SubscriptionProfiles">
  <div class="card-header"><h4 class="card-header-title">🔗 لینک‌های اتصال</h4></div>
  <div class="card-body">
    <p class="text-muted">برای هر لینک عنوان، توضیحات، گروه کاربران و سرورها را جدا انتخاب کنید. گروه مشترک می‌تواند هر دو لینک را ببیند. انتخاب سرورها دسترسی اصلی اشتراک را گسترش نمی‌دهد.</p>
    <p class="small text-muted">با غیرفعال‌کردن هر دو لینک، لینک اتصالی به کاربران نمایش داده نمی‌شود.</p>
    <div id="spForms" class="row g-3"></div>
    <fieldset id="spCombined" class="border rounded p-3 mt-3" disabled>
      <label class="form-check"><input id="spCombinedEnabled" type="checkbox" class="form-check-input"> نمایش لینک اشتراک ترکیبی</label>
      <p class="small text-muted mt-2">سرورهای هر دو لینک خودکار ترکیب می‌شوند. هر کاربر فقط سرورهای لینک‌های مجاز گروه خودش را می‌گیرد؛ تنظیمات دامنه و پورت هر لینک حفظ می‌شود.</p>
      <label class="d-block mb-2">عنوان لینک ترکیبی<input id="spCombinedName" class="form-control" maxlength="80"></label>
      <label class="d-block">توضیحات<textarea id="spCombinedDescription" class="form-control" rows="2" maxlength="1000"></textarea></label>
    </fieldset>
    <button id="spSave" type="button" class="btn btn-primary mt-3" disabled>ذخیره لینک‌ها</button>
    <span id="spStatus" role="status" class="ms-2"></span>
  </div>
</div>
{literal}
<script>
document.addEventListener('DOMContentLoaded', function () {
  const root = document.getElementById('spForms'), save = document.getElementById('spSave'), status = document.getElementById('spStatus');
  const endpoint = '/xmplus-patch.php?do=subprofiles.';
  let token = '';
  function element(tag, cls, text) {
    const el = document.createElement(tag); if (cls) el.className = cls; if (text) el.textContent = text; return el;
  }
  function field(box, label, input) {
    const wrap = element('label', 'd-block mb-3', label); wrap.appendChild(input); box.appendChild(wrap); return input;
  }
  function choices(box, label, rows, selected, key) {
    const group = element('fieldset', 'mb-3'); group.dataset.key = key;
    group.appendChild(element('legend', 'fs-6', label));
    rows.forEach(row => {
      const line = element('label', 'd-block'); const input = element('input', 'form-check-input me-2'); input.type = 'checkbox'; input.value = row.id;
      input.checked = selected.includes(Number(row.id)); line.appendChild(input); line.appendChild(document.createTextNode('#' + row.id + ' — ' + row.name)); group.appendChild(line);
    });
    group.style.maxHeight = '240px'; group.style.overflowY = 'auto'; box.appendChild(group);
  }
  fetch(endpoint + 'get', {credentials: 'same-origin', cache: 'no-store'}).then(r => r.json()).then(data => {
    if (!data.ok) throw new Error(data.error); token = data.token;
    [0, 1].forEach(i => {
      const profile = data.profiles[i] || {name: i ? 'سرورهای تانل' : 'سرورهای مستقیم', description: '', enabled: false, groups: [], servers: []};
      const col = element('div', 'col-lg-6'), box = element('div', 'border rounded p-3 h-100'); box.dataset.profile = i;
      box.appendChild(element('h5', '', 'لینک ' + (i + 1)));
      const enabled = element('input', 'form-check-input ms-2'); enabled.type = 'checkbox'; enabled.checked = profile.enabled; enabled.dataset.key = 'enabled'; field(box, 'فعال', enabled);
      const name = element('input', 'form-control mt-1'); name.value = profile.name; name.maxLength = 80; name.dataset.key = 'name'; field(box, 'عنوان لینک', name);
      const desc = element('textarea', 'form-control mt-1'); desc.value = profile.description || ''; desc.rows = 3; desc.maxLength = 1000; desc.dataset.key = 'description'; field(box, 'توضیحات زیر عنوان', desc);
      choices(box, 'گروه کاربران (گروه اشتراک)', data.groups, profile.groups, 'groups');
      choices(box, 'سرورهای این لینک', data.servers, profile.servers, 'servers');
      col.appendChild(box); root.appendChild(col);
    });
    document.getElementById('spCombinedEnabled').checked = !!data.combined.enabled;
    document.getElementById('spCombinedName').value = data.combined.name;
    document.getElementById('spCombinedDescription').value = data.combined.description;
    document.getElementById('spCombined').disabled = false;
    save.disabled = false;
  }).catch(e => {status.textContent = 'بارگذاری انجام نشد: ' + e.message;});
  save.addEventListener('click', async function () {
    const profiles = Array.from(root.querySelectorAll('[data-profile]')).map(box => {
      const read = key => box.querySelector('[data-key="' + key + '"]');
      const ids = key => Array.from(read(key).querySelectorAll('input:checked')).map(input => Number(input.value));
      return {enabled: read('enabled').checked, name: read('name').value, description: read('description').value, groups: ids('groups'), servers: ids('servers')};
    });
    save.disabled = true; status.textContent = 'در حال ذخیره…';
    try {
      const combined = {enabled: document.getElementById('spCombinedEnabled').checked,
        name: document.getElementById('spCombinedName').value, description: document.getElementById('spCombinedDescription').value};
      const body = new URLSearchParams({token, profiles: JSON.stringify(profiles), combined: JSON.stringify(combined)});
      const data = await (await fetch(endpoint + 'save', {method: 'POST', credentials: 'same-origin', body})).json();
      if (!data.ok) throw new Error(data.error); status.textContent = 'ذخیره شد';
    } catch (e) {status.textContent = e.message;} finally {save.disabled = false;}
  });
});
</script>
{/literal}
