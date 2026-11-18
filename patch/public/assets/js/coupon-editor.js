(() => {
  const route = location.pathname.match(/^\/admin\/coupon\/(?:add|(\d+)\/edit)\/?$/);
  if (!route) return;

  function mountEditor() {
    const template = document.getElementById('coupon-editor-template');
    const start = document.getElementById('start_date');
    const end = document.getElementById('expire_date');
    const host = start && (start.form || start.closest('.card'));
    if (!template || !host || !end || !host.contains(end)) return;
    const required = ['code', 'credit', 'type'];
    if (required.some(id => !host.querySelector('#' + id))) return;
    const cancel = host.querySelector('a[href="/admin/coupons"]');
    const actions = Array.from(host.querySelectorAll('button, input[type="submit"]'));
    const save = actions.filter(button => !button.closest('.input-group, .ts-wrapper')).at(-1);
    if (!cancel || !save) return;

    const editor = template.content.firstElementChild.cloneNode(true);
    const stock = document.createElement('div');
    stock.dataset.couponStock = '';

    for (const cell of editor.querySelectorAll('[data-control]')) {
      const field = host.querySelector('#' + cell.dataset.control);
      if (!field) {
        cell.hidden = true;
        continue;
      }
      const label = cell.querySelector('label');
      const oldLabel = field.labels?.[0] || field.closest('.row')?.querySelector('label');
      label.htmlFor = field.tomselect?.control_input?.id || field.id;
      if (!label.textContent.trim()) label.textContent = oldLabel?.textContent.trim() || field.placeholder;
      const group = field.id === 'code' && field.closest('.input-group');
      const mount = cell.querySelector('[data-control-mount]');
      mount.append(group || field);
      if (field.tomselect?.wrapper) mount.append(field.tomselect.wrapper);
    }

    const cycles = editor.querySelector('[data-cycles]');
    for (const id of ['onetime', 'month', 'quater', 'semiannual', 'annual', 'custom']) {
      const field = host.querySelector('#' + id);
      if (!field) continue;
      const oldLabel = field.labels?.[0] || field.parentElement.querySelector('label');
      const label = document.createElement('label');
      label.append(field, document.createTextNode(oldLabel?.textContent.trim() || id));
      cycles.append(label);
    }
    const editorActions = editor.querySelector('[data-native-actions]');
    editorActions.append(cancel, save);

    if (route[1]) {
      editor.querySelector('h2').textContent = editor.dataset.edit;
      editor.querySelector('[data-campaign-link]').href = '/admin/coupons?campaign_coupon=' + route[1] + '#couponCampaignPanel';
    }

    const type = editor.querySelector('#type');
    const creditLabel = editor.querySelector('[data-credit-label]');
    function labelCredit() {
      const selected = type.selectedOptions[0];
      const isPercent = ['2', 'percentage_amount'].includes(selected?.value)
        || selected?.textContent.trim() === editor.dataset.percent;
      creditLabel.textContent = isPercent ? creditLabel.dataset.percent : creditLabel.dataset.credit;
    }
    type.addEventListener('change', labelCredit);
    labelCredit();
    setupDates(editor, start, end, save);

    stock.append(...host.childNodes);
    host.append(stock, editor);
    host.classList.add('coupon-editor-host');
  }

  function setupDates(editor, start, end, save) {
    const startPicker = editor.querySelector('[data-start-calendar]');
    const endPicker = editor.querySelector('[data-end-calendar]');
    const days = editor.querySelector('[data-days]');
    const error = editor.querySelector('[data-date-error]');
    let changed = false;
    for (const [field, picker] of [[start, startPicker], [end, endPicker]]) {
      picker.value = field.value.trim().replace(' ', 'T');
      if (picker.type !== 'datetime-local' || (field.value && !picker.value)) {
        picker.type = 'text';
        picker.value = field.value;
      }
    }
    function writeValue(picker, field) {
      changed = true;
      error.hidden = true;
      let value = picker.value.trim().replace('T', ' ').replace(/\.\d+$/, '');
      if (value.length === 16) value += ':00';
      field.value = value;
      field.dispatchEvent(new Event('input', {bubbles: true}));
      field.dispatchEvent(new Event('change', {bubbles: true}));
    }
    function civilTime(picker) {
      return Date.parse(picker.value.trim().replace(' ', 'T') + 'Z');
    }

    function writeCalendar(picker, value) {
      picker.value = picker.type === 'datetime-local' ? value : value.replace('T', ' ');
    }

    function tehranNow() {
      const options = {
        timeZone: 'Asia/Tehran', year: 'numeric', month: '2-digit', day: '2-digit',
        hour: '2-digit', minute: '2-digit', second: '2-digit', hourCycle: 'h23',
      };
      const items = new Intl.DateTimeFormat('en', options).formatToParts(new Date());
      const value = Object.fromEntries(items.map(part => [part.type, part.value]));
      return value.year + '-' + value.month + '-' + value.day + 'T' + value.hour + ':' + value.minute + ':' + value.second;
    }

    function calculateEnd() {
      const count = days.valueAsNumber;
      if (!Number.isInteger(count) || count < 1) return;
      if (!startPicker.value) {
        writeCalendar(startPicker, tehranNow());
        writeValue(startPicker, start);
      }
      const day = civilTime(startPicker);
      if (!Number.isFinite(day)) return;
      const result = new Date(day + count * 86400000);
      if (!Number.isFinite(result.getTime()) || result.getUTCFullYear() > 9999) return;
      const to = result.toISOString().slice(0, 19);
      writeCalendar(endPicker, to);
      writeValue(endPicker, end);
    }
    startPicker.addEventListener('change', () => {
      writeValue(startPicker, start);
      calculateEnd();
    });
    endPicker.addEventListener('change', () => {
      days.value = '';
      writeValue(endPicker, end);
    });
    days.addEventListener('input', calculateEnd);
    save.addEventListener('click', event => {
      if (!changed || civilTime(endPicker) > civilTime(startPicker)) return;
      event.preventDefault();
      event.stopImmediatePropagation();
      error.textContent = error.dataset.message;
      error.hidden = false;
      endPicker.focus();
    }, true);
  }

  if (document.readyState === 'complete') mountEditor();
  else window.addEventListener('load', mountEditor, {once: true});
})();
