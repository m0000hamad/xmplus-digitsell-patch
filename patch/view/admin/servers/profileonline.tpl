{literal}
<style>
.profile-online-counts {display:inline-flex;flex-direction:column;gap:.4rem;min-width:7rem;text-align:start;}
.profile-online-counts span {display:flex;justify-content:space-between;align-items:center;gap:.7rem;}
.profile-online-counts small {font-size:.7rem;color:var(--bs-secondary-color,#71869d);}
.profile-online-counts b {font-weight:500;font-variant-numeric:tabular-nums;}
.profile-online-counts span + span {border-top:1px solid rgba(127,127,127,.15);padding-top:.4rem;}
</style>
<script>
document.addEventListener('DOMContentLoaded', function () {
  const el = document.getElementById('pagination');
  if (!el || !window.jQuery || !$.fn.dataTable.isDataTable(el)) return;
  const table = $(el).DataTable();
  let column = null, snapshot = null, received = 0, pending = false;
  table.columns().every(function (index) {if (this.dataSrc() === 'count') column = index;});
  if (column === null) return;
  function render() {
    table.rows({page: 'current'}).every(function () {
      const data = this.data(), id = Number(data.id), cell = table.cell(this.index(), column).node();
      if (!cell || !Number.isInteger(id) || id <= 0) return;
      if (!snapshot || !(snapshot.split || []).includes(id)) {
        cell.innerHTML = data.count == null ? '' : String(data.count);
        return;
      }
      const node = snapshot && snapshot.nodes[id];
      const age = node ? (snapshot.now - node.at) + (Date.now() - received) / 1000 : Infinity;
      const ready = !!(node && node.ready && age >= 0 && age < 60);
      const box = document.createElement('div'); box.className = 'profile-online-counts';
      [0, 1].forEach(slot => {
        const row = document.createElement('span'), title = document.createElement('small'), count = document.createElement('b');
        title.textContent = 'لینک ' + (slot + 1);
        row.title = snapshot ? snapshot.titles[slot] : title.textContent;
        count.textContent = ready ? String(node.counts[slot]) + (node.unclassified ? '*' : '') : '—';
        count.setAttribute('aria-label', title.textContent + ': ' + count.textContent);
        if (!ready) row.title += ' — آمار تفکیکی تازه موجود نیست؛ نیازمند عامل ۱.۴.۱ و فعال‌بودن پورت‌های جدا است.';
        else if (node.unclassified) row.title += ' — ' + node.unclassified + ' حساب بدون شناسه لینک گزارش شده؛ این عدد فقط حساب‌های شناسایی‌شده این لینک است.';
        row.append(title, count); box.appendChild(row);
      });
      cell.replaceChildren(box);
    });
  }
  async function refresh() {
    render();
    if (pending || document.visibilityState === 'hidden') return;
    pending = true;
    const started = Date.now();
    try {
      const response = await fetch('/xmplus-patch.php?do=subprofiles.online', {credentials: 'same-origin', cache: 'no-store'});
      const data = await response.json(); if (!data.ok) throw new Error(data.error);
      snapshot = data; received = started; render();
    } catch (_) {render();} finally {pending = false;}
  }
  $(el).on('draw.dt', render);
  document.addEventListener('visibilitychange', function () {if (document.visibilityState === 'visible') refresh();});
  refresh(); setInterval(refresh, 15000);
});
</script>
{/literal}
