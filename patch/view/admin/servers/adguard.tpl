<div class="card card-shadow shadow-lg rounded mb-3" id="adguardSettings" dir="rtl">
 <div class="card-header"><h4>ادگارد (AdGuard Home)</h4></div>
 <div class="card-body">
  <p class="text-muted">AdGuard Home: فیلتر DNS معمولی عبوری از تونل، مستقل برای هر سرور Xray. حذف تبلیغات یوتیوب و پوشش DNS رمزگذاری‌شده تضمین نمی‌شود. خاموش‌کردن مسیر قبلی DNS را برمی‌گرداند.</p>
  <div id="adguardError" role="alert" class="text-danger"></div>
  <div class="table-responsive"><table class="table"><thead><tr><th>سرور</th><th>ادگارد</th><th>وضعیت</th></tr></thead><tbody id="adguardRows"></tbody></table></div>
  <small class="text-muted">نیازمند نود digitsell-xray با پشتیبانی ادگارد است. نودهای قدیمی ابتدا باید به‌روزرسانی شوند. نصب خودکار روی Linux با systemd و معماری amd64 یا arm64 پشتیبانی می‌شود؛ اعمال تغییر ممکن است چند دقیقه طول بکشد.</small>
 </div>
</div>
{literal}
<script>
(function () {
 var token = '', busy = false, rows = document.getElementById('adguardRows'), error = document.getElementById('adguardError');
 var states = {off:'خاموش', installing:'در حال نصب و فعال‌سازی', connecting:'در حال بررسی DNS', ready:'DNS سالم؛ در انتظار اعمال', active:'فعال؛ DNS تونل فیلتر می‌شود', failed:'خطا؛ تلاش مجدد خودکار'};
 function esc(v) { return String(v || '').replace(/[&<>"']/g, function(c) { return {'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]; }); }
 async function load() {
  if (busy) return;
  try {
   var r = await fetch('/xmplus-patch.php?do=adguard.admin', {credentials:'same-origin',cache:'no-store'}), data = await r.json();
   if (!data.ok) throw new Error(data.error);
   token = data.token; error.textContent = '';
   rows.innerHTML = data.servers.map(function(s) {
    var p = s.report || {}, status = !s.live ? 'نود گزارش نمی‌دهد؛ نیاز به نصب یا به‌روزرسانی نود' : (states[p.state] || 'در انتظار نود');
    if (s.live && Boolean(p.enabled) !== s.enabled) status = 'در انتظار اعمال تغییر';
    return '<tr><td>'+esc(s.name)+' #'+s.id+'</td><td><input type="checkbox" role="switch" aria-label="AdGuard Home '+s.id+'" data-adguard="'+s.id+'" '+(s.enabled?'checked':'')+'></td><td>'+esc(status)+(p.ip?' · '+esc(p.ip):'')+(p.error?'<br><small class="text-danger">'+esc(p.error)+'</small>':'')+'</td></tr>';
   }).join('');
  } catch(e) { error.textContent = e.message; }
 }
 rows.addEventListener('change', async function(e) {
  var box = e.target; if (!box.matches('[data-adguard]')) return;
  busy = true; box.disabled = true;
  try {
   var body = new FormData(); body.append('token', token); body.append('id', box.dataset.adguard); body.append('enabled', box.checked?'1':'0');
   var r = await fetch('/xmplus-patch.php?do=adguard.save', {method:'POST',credentials:'same-origin',body:body}), data = await r.json();
   if (!data.ok) throw new Error(data.error);
  } catch(e) { box.checked = !box.checked; error.textContent = e.message; }
  finally { busy = false; box.disabled = false; }
 });
 load(); setInterval(function() { if (!document.hidden) load(); }, 10000);
})();
</script>
{/literal}
