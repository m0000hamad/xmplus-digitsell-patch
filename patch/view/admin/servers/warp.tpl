<div class="card card-shadow shadow-lg rounded mb-3" id="warpSettings" dir="rtl">
 <div class="card-header"><h4>وارپ (Cloudflare WARP)</h4></div>
 <div class="card-body">
  <p class="text-muted">برای هر سرور روشن کنید؛ نصب، ثبت و اتصال خودکار انجام می‌شود. پس از تأیید اتصال، خروجی کاربران آن سرور از وارپ عبور می‌کند. UDP در این حالت مسدود است. خاموش‌کردن، خروجی قبلی سرور را برمی‌گرداند.</p>
  <div id="warpError" role="alert" class="text-danger"></div>
  <div class="table-responsive"><table class="table"><thead><tr><th>سرور</th><th>وارپ</th><th>وضعیت</th></tr></thead><tbody id="warpRows"></tbody></table></div>
  <small class="text-muted">نیازمند نود digitsell-xray با پشتیبانی وارپ است. نودهای قدیمی ابتدا باید به‌روزرسانی شوند. نصب خودکار روی Debian و Ubuntu پشتیبانی می‌شود؛ اعمال تغییر ممکن است چند دقیقه طول بکشد.</small>
 </div>
</div>
{literal}
<script>
(function () {
 var token = '', busy = false, rows = document.getElementById('warpRows'), error = document.getElementById('warpError');
 var states = {off:'خاموش', installing:'در حال نصب و فعال‌سازی', connecting:'در حال اتصال', ready:'متصل؛ در انتظار اعمال', active:'فعال', failed:'خطا؛ تلاش مجدد خودکار'};
 function esc(v) { return String(v || '').replace(/[&<>"']/g, function(c) { return {'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]; }); }
 async function load() {
  if (busy) return;
  try {
   var r = await fetch('/xmplus-patch.php?do=warp.admin', {credentials:'same-origin',cache:'no-store'}), data = await r.json();
   if (!data.ok) throw new Error(data.error);
   token = data.token; error.textContent = '';
   rows.innerHTML = data.servers.map(function(s) {
    var p = s.report || {}, status = !s.live ? 'نود گزارش نمی‌دهد؛ نیاز به نصب یا به‌روزرسانی نود' : (states[p.state] || 'در انتظار نود');
    if (s.live && Boolean(p.enabled) !== s.enabled) status = 'در انتظار اعمال تغییر';
    return '<tr><td>'+esc(s.name)+' #'+s.id+'</td><td><input type="checkbox" role="switch" aria-label="WARP '+s.id+'" data-warp="'+s.id+'" '+(s.enabled?'checked':'')+'></td><td>'+esc(status)+(p.ip?' · '+esc(p.ip):'')+(p.error?'<br><small class="text-danger">'+esc(p.error)+'</small>':'')+'</td></tr>';
   }).join('');
  } catch(e) { error.textContent = e.message; }
 }
 rows.addEventListener('change', async function(e) {
  var box = e.target; if (!box.matches('[data-warp]')) return;
  busy = true; box.disabled = true;
  try {
   var body = new FormData(); body.append('token', token); body.append('id', box.dataset.warp); body.append('enabled', box.checked?'1':'0');
   var r = await fetch('/xmplus-patch.php?do=warp.save', {method:'POST',credentials:'same-origin',body:body}), data = await r.json();
   if (!data.ok) throw new Error(data.error);
  } catch(e) { box.checked = !box.checked; error.textContent = e.message; }
  finally { busy = false; box.disabled = false; }
 });
 load(); setInterval(function() { if (!document.hidden) load(); }, 10000);
})();
</script>
{/literal}
