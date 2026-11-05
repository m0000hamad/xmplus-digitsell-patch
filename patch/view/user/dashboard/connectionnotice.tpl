{* Important connection notice. Replaces the dashboard referral nudge, independently of rebates. *}
{literal}
<style>
.dcn-back{position:fixed;inset:0;z-index:1070;display:flex;align-items:center;justify-content:center;box-sizing:border-box;padding:16px;background:rgba(10,14,30,.64);backdrop-filter:blur(6px);-webkit-backdrop-filter:blur(6px)}
.dcn-back[hidden]{display:none!important}
.dcn-dialog{box-sizing:border-box;display:flex;flex-direction:column;width:100%;max-width:600px;max-height:calc(100vh - 32px);max-height:calc(100dvh - 32px);overflow:hidden;border:2px solid #dc1230;border-radius:22px;background:#fff;color:#20242c;box-shadow:0 28px 90px rgba(0,0,0,.4);font-family:inherit;text-align:center;direction:rtl}
.dcn-bar{flex-shrink:0;display:flex;align-items:center;justify-content:space-between;gap:16px;padding:8px 16px;background:#bd001c;color:#fff;font-size:18px;font-weight:800}
.dcn-close{display:grid;place-items:center;width:44px;height:44px;padding:0;border:0;border-radius:10px;background:transparent;color:#fff;font:32px/1 sans-serif;cursor:pointer}
.dcn-close:hover{background:rgba(255,255,255,.18)}
.dcn-body{overflow-y:auto;overscroll-behavior:contain;padding:24px 24px 12px;min-height:0}
.dcn-warning{display:grid;place-items:center;width:78px;height:78px;margin:0 auto 12px;border-radius:50%;background:#ffe1e5;color:#bd001c}
.dcn-warning svg{width:48px;height:48px}
.dcn-dialog .dcn-title{margin:0 0 12px;color:#20242c;font-size:clamp(23px,4.8vw,34px);font-weight:900;line-height:1.5}
.dcn-chip{display:inline-block;padding:5px 18px;border-radius:999px;background:#ffe1e5;color:#aa0019;font-size:15px;font-weight:800}
.dcn-dialog .dcn-copy{margin:16px 0 12px;color:#303642;font-size:16px;line-height:1.95}
.dcn-dialog .dcn-lead{margin:0 0 16px;color:#303642;font-size:16px;line-height:1.9}
.dcn-apps{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:10px;direction:ltr;list-style:none;margin:0;padding:0}
.dcn-apps li{display:flex;flex-direction:column;align-items:center;justify-content:center;gap:10px;min-width:0;padding:16px 8px;border:1px solid #cbd1dc;border-radius:14px;background:#f5f7fa;color:#20242c;font-size:16px;font-weight:800;line-height:1.5}
.dcn-app-icon{display:grid;place-items:center;width:32px;height:32px;border-radius:10px;color:#fff;font:bold 21px/1 sans-serif;background:#7054df}
.dcn-app-icon.dcn-openvpn{background:#c45b00}.dcn-app-icon.dcn-amnezia{background:#30495c}
.dcn-dialog .dcn-hint{margin:14px 0 0;font-size:13px;line-height:1.9;color:#555f70}
.dcn-footer{flex-shrink:0;padding:14px 24px 20px;padding-bottom:max(20px,env(safe-area-inset-bottom));background:#fff}
.dcn-ok{width:100%;min-height:52px;padding:12px 16px;border:0;border-radius:12px;background:#bd001c;color:#fff;font-family:inherit;font-size:18px;font-weight:800;line-height:1.5;cursor:pointer}
.dcn-ok:hover{background:#9e0017}.dcn-dialog button:focus-visible,.dcn-dialog:focus-visible{outline:3px solid #2475dd;outline-offset:3px}
html[data-hs-theme="dark"] .dcn-dialog{background:#182132;color:#f8fafc}
html[data-hs-theme="dark"] .dcn-dialog .dcn-title{color:#f8fafc}
html[data-hs-theme="dark"] .dcn-dialog .dcn-copy,html[data-hs-theme="dark"] .dcn-dialog .dcn-lead{color:#e2e8f0}
html[data-hs-theme="dark"] .dcn-dialog .dcn-hint{color:#cbd5e1}
html[data-hs-theme="dark"] .dcn-apps li{background:#253246;border-color:#58677d;color:#f8fafc}
html[data-hs-theme="dark"] .dcn-footer{background:#182132}
@media(max-width:575.98px){.dcn-back{padding:12px}.dcn-dialog{max-height:calc(100vh - 24px);max-height:calc(100dvh - 24px);border-radius:18px}.dcn-bar{padding:4px 12px;font-size:16px}.dcn-body{padding:18px 16px 8px}.dcn-warning{width:60px;height:60px;margin-bottom:10px}.dcn-warning svg{width:38px;height:38px}.dcn-dialog .dcn-copy,.dcn-dialog .dcn-lead{font-size:14px;line-height:1.9}.dcn-apps{grid-template-columns:1fr;gap:8px}.dcn-apps li{flex-direction:row;gap:12px;padding:9px 12px;font-size:15px}.dcn-app-icon{width:28px;height:28px;font-size:18px}.dcn-footer{padding:12px 16px 16px;padding-bottom:max(16px,env(safe-area-inset-bottom))}}
</style>
<div class="dcn-back" id="dsConnectionNotice" hidden>
 <section class="dcn-dialog" role="alertdialog" aria-modal="true" aria-labelledby="dcnTitle" aria-describedby="dcnCopy dcnLead dcnHint" tabindex="-1" lang="fa" dir="rtl">
  <header class="dcn-bar"><span>دیجیتسل</span><button type="button" class="dcn-close" data-dcn-close aria-label="بستن اطلاعیه">×</button></header>
  <div class="dcn-body">
   <div class="dcn-warning" aria-hidden="true"><svg viewBox="0 0 48 48" fill="none" stroke="currentColor" stroke-width="3.5" stroke-linecap="round" stroke-linejoin="round"><path d="M21 7a3.5 3.5 0 0 1 6 0l17 29a3.5 3.5 0 0 1-3 5H7a3.5 3.5 0 0 1-3-5Z"/><path d="M24 17v10m0 7v.2"/></svg></div>
   <h2 class="dcn-title" id="dcnTitle">اطلاعیه مهم اتصال</h2>
   <span class="dcn-chip">ویژه کاربران <bdi dir="ltr">Happ</bdi></span>
   <p class="dcn-copy" id="dcnCopy">اپلیکیشن <bdi dir="ltr">Happ</bdi> در حال حاضر باگ دارد و ممکن است اتصال شما را مختل کند. این مشکل مربوط به خود برنامه است.</p>
   <p class="dcn-lead" id="dcnLead">برای اتصال، لطفاً از یکی از برنامه‌های زیر استفاده کنید:</p>
   <ul class="dcn-apps" aria-label="برنامه‌های جایگزین">
    <li><span class="dcn-app-icon" aria-hidden="true">◇</span><bdi dir="ltr">V2Box</bdi></li>
    <li><span class="dcn-app-icon dcn-openvpn" aria-hidden="true">⏻</span><bdi dir="ltr">OpenVPN</bdi></li>
    <li><span class="dcn-app-icon dcn-amnezia" aria-hidden="true">A</span><bdi dir="ltr">Amnezia VPN</bdi></li>
   </ul>
   <p class="dcn-hint" id="dcnHint">برنامه مناسب کانفیگ خود را انتخاب کنید.</p>
  </div>
  <footer class="dcn-footer"><button type="button" class="dcn-ok" data-dcn-close>متوجه شدم</button></footer>
 </section>
</div>
<script>
(function () {
 'use strict';
 var back = document.getElementById('dsConnectionNotice');
 if (!back) { return; }
 // Escape layout stacking contexts; show on each dashboard entry, without the old referral cooldown.
 document.body.appendChild(back);
 var dialog = back.querySelector('.dcn-dialog');
 var previousFocus, previousOverflow, shown = false;
 function busy() {
  return document.querySelector('.modal.show, .swal2-container, .layui-layer-dialog, .gfp-back:not([hidden])') !== null;
 }
 function close() {
  if (!shown) { return; }
  shown = false;
  back.hidden = true;
  document.body.style.overflow = previousOverflow;
  document.removeEventListener('keydown', onKey, true);
  document.removeEventListener('focusin', keepFocus);
  if (previousFocus && document.documentElement.contains(previousFocus)) { previousFocus.focus(); }
 }
 function keepFocus(event) {
  if (shown && !back.contains(event.target)) { dialog.focus(); }
 }
 function onKey(event) {
  if (event.key === 'Escape') { event.preventDefault(); event.stopImmediatePropagation(); close(); return; }
  if (event.key !== 'Tab') { return; }
  var first = back.querySelector('.dcn-close');
  var last = back.querySelector('.dcn-ok');
  if (event.shiftKey && (document.activeElement === first || document.activeElement === dialog)) {
   event.preventDefault(); last.focus();
  } else if (!event.shiftKey && (document.activeElement === last || document.activeElement === dialog)) {
   event.preventDefault(); first.focus();
  }
 }
 back.addEventListener('click', function (event) {
  // The backdrop cannot silently dismiss this important announcement.
  if (event.target.closest('[data-dcn-close]')) { close(); }
 });
 var quietSince = 0;
 var readyAt = Date.now() + 1800;
 var timer = window.setInterval(function () {
  if (!back.isConnected) { window.clearInterval(timer); return; }
  if (Date.now() < readyAt || document.hidden || busy()) { quietSince = 0; return; }
  if (!quietSince) { quietSince = Date.now(); return; }
  if (Date.now() - quietSince < 800) { return; }
  window.clearInterval(timer);
  previousFocus = document.activeElement;
  previousOverflow = document.body.style.overflow;
  shown = true;
  back.hidden = false;
  document.body.style.overflow = 'hidden';
  document.addEventListener('keydown', onKey, true);
  document.addEventListener('focusin', keepFocus);
  dialog.focus();
 }, 250);
})();
</script>
{/literal}
