{* Owner-approved Telegram invitation; existing channel gift job remains authoritative. *}
{$dci = $user->tgJoin()}
{if $dci['state'] != 'off'}
{literal}<style>

.dci-back{position:fixed;inset:0;z-index:1070;display:flex;align-items:center;justify-content:center;padding:16px;box-sizing:border-box;background:rgba(13,14,20,.72);backdrop-filter:blur(7px);-webkit-backdrop-filter:blur(7px)}
.dci-back[hidden]{display:none!important}.dci-dialog{width:100%;max-width:580px;max-height:calc(100vh - 32px);max-height:calc(100dvh - 32px);overflow:auto;overscroll-behavior:contain;border-radius:24px;background:#fffaf5;color:#202128;box-shadow:0 28px 90px #0007;font-family:inherit;direction:rtl;text-align:center;box-sizing:border-box}
.dci-header{display:flex;align-items:center;justify-content:space-between;padding:14px 20px}.dci-brand{display:flex;align-items:center;gap:10px;font-size:26px;font-weight:900}.dci-logo{width:48px;height:48px;border-radius:50%;object-fit:contain;background:#fff}.dci-close{width:44px;height:44px;border:0;border-radius:12px;background:transparent;color:#292b32;font:34px/1 sans-serif;cursor:pointer}
.dci-hero{display:flex;align-items:center;justify-content:center;gap:20px;padding:22px 24px;background:radial-gradient(ellipse at 15% 100%,#e91c37,transparent 60%),linear-gradient(120deg,#790010,#bd0023);color:#fff}.dci-hero h2{margin:0;color:#fff;font-size:28px;line-height:1.7;font-weight:900}.dci-gift{font-size:88px;line-height:1.2;filter:drop-shadow(0 8px 12px #39000b66)}
.dci-body{padding:22px 24px}.dci-reward{display:flex;align-items:center;justify-content:center;gap:8px;flex-wrap:wrap;margin:0 auto 22px;padding:8px 14px;border:2px solid #d7a537;border-radius:999px;background:linear-gradient(110deg,#fff7e4,#ffe8b6);box-shadow:inset 0 0 0 4px #fffaf5;font-size:24px;font-weight:900;line-height:1.6;color:#252126}.dci-reward strong{font-size:54px;line-height:1.2;color:#c70028}
.dci-join{display:flex;align-items:center;justify-content:center;gap:12px;width:100%;min-height:68px;box-sizing:border-box;padding:15px 12px;border:1px solid #53c2f2;border-radius:17px;background:linear-gradient(170deg,#15b8ee,#168acc 60%,#0863b6);color:#fff!important;text-decoration:none!important;font-size:26px;font-weight:900;line-height:1.5;box-shadow:0 8px 20px #168acc55;transition:filter .15s}.dci-join:hover{filter:brightness(1.08)}.dci-join svg{width:30px;height:30px;flex-shrink:0}
.dci-copy{margin:20px 0 16px;font-size:16px;line-height:2;font-weight:600;color:#272730}.dci-note{display:inline-block;margin:0;padding:8px 14px;border-radius:12px;background:#ffedca;color:#68400a;font-size:13px;line-height:1.9}.dci-link-help{margin:12px 0 0;font-size:13px;line-height:1.9;color:#484852}.dci-link-help a{color:#096baf;text-decoration:underline}.dci-footer{padding:0 20px 20px;padding-bottom:max(20px,env(safe-area-inset-bottom))}.dci-later{min-height:44px;padding:6px 14px;border:0;background:transparent;color:#67646a;text-decoration:underline;font-family:inherit;font-size:14px;cursor:pointer}.dci-dialog :focus-visible,.dci-dialog:focus-visible{outline:3px solid #168acc;outline-offset:3px}
@media(max-width:575.98px){.dci-back{padding:12px}.dci-dialog{max-height:calc(100vh - 24px);max-height:calc(100dvh - 24px);border-radius:20px}.dci-header{padding:10px 14px}.dci-brand{font-size:22px}.dci-logo{width:40px;height:40px}.dci-hero{padding:18px 14px;gap:10px}.dci-hero h2{font-size:23px}.dci-gift{font-size:62px}.dci-body{padding:18px 16px}.dci-reward{font-size:19px;gap:5px;margin-bottom:18px;padding:8px}.dci-reward strong{font-size:42px}.dci-join{font-size:20px;min-height:60px;gap:8px}.dci-join svg{width:25px;height:25px}.dci-copy{font-size:14px;line-height:1.95;margin-top:18px}.dci-note{font-size:12px}}
@media(prefers-reduced-motion:reduce){.dci-join{transition:none}}
</style>{/literal}

<div class="dci-back" id="dsChannelInvite" hidden>
 <section class="dci-dialog" role="dialog" aria-modal="true" aria-labelledby="dciTitle" aria-describedby="dciCopy dciNote" tabindex="-1" lang="fa" dir="rtl">
  <header class="dci-header"><div class="dci-brand"><img class="dci-logo" src="/uploads/digit.jpg" alt="لوگوی دیجیتسل" width="48" height="48"><span>دیجیتسل</span></div><button type="button" class="dci-close" data-dcn-close aria-label="بستن دعوت کانال">×</button></header>
  <div class="dci-hero"><h2 id="dciTitle">عضو کانال شو، جایزه بگیر!</h2><span class="dci-gift" aria-hidden="true">🎁</span></div>
  <div class="dci-body">
   <div class="dci-reward"><span>تا</span><strong>۵۰</strong><span>گیگابایت جایزه</span></div>
   <a class="dci-join" href="{$dci['link']|escape:'html'}" target="_blank" rel="noopener noreferrer"><svg aria-hidden="true" viewBox="0 0 24 24" fill="currentColor"><path d="M21.9 3.2 18.5 20c-.3 1.2-1 1.5-2 .9l-5.2-3.8-2.5 2.4c-.3.3-.5.5-1 .5l.4-5.3 9.7-8.7c.4-.4-.1-.6-.6-.3L5.3 13.2.2 11.6c-1.1-.4-1.1-1.1.2-1.6L20.4 2.3c.9-.3 1.7.2 1.5.9Z"/></svg><span>عضویت در کانال تلگرام</span></a>
   <p class="dci-copy" id="dciCopy">با عضویت در کانال تلگرام دیجیتسل، از خبرها و اطلاعیه‌های مهم باخبر شو و فرصت دریافت تا ۵۰ گیگابایت جایزه را داشته باش.</p>
   <p class="dci-note" id="dciNote">برای دریافت جایزه، عضو کانال بمانید.</p>
   {if $dci['state'] == 'link'}<p class="dci-link-help">برای شناسایی عضویت و دریافت جایزه، <a href="https://telegram.me/{$Config['telegrambot']|escape:'url'}?start={$user->tg_token|escape:'url'}" target="_blank" rel="noopener noreferrer">حساب تلگرام خود را هم متصل کنید</a>.</p>{/if}
  </div>
  <footer class="dci-footer"><button type="button" class="dci-later" data-dcn-close>بعداً عضو می‌شوم</button></footer>
 </section>
</div>

{literal}
<script>
(function () {
 'use strict';
 var back = document.getElementById('dsChannelInvite');
 if (!back) { return; }
 // Show on dashboard entry after other notifications; no reward is granted client-side.
 document.body.appendChild(back);
 var dialog = back.querySelector('.dci-dialog');
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
  var first = back.querySelector('.dci-close');
  var last = back.querySelector('.dci-later');
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
{/if}
