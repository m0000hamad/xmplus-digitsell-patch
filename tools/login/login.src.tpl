<!DOCTYPE html>
<html lang="fa" dir="rtl">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
  <meta name="theme-color" content="#0b0f19">
  <title>{$Config['appName']} - {$translate->get('SignIn')}</title>
  <link rel="shortcut icon" href="{$Config['logo_path']}">
{literal}
  <script>
    (function () {
      var pref = null;
      try { pref = localStorage.getItem('hs_theme'); } catch (e) {}
      if (pref !== 'dark' && pref !== 'default' && pref !== 'auto') pref = 'dark';
      var mode = pref === 'auto'
        ? (window.matchMedia && matchMedia('(prefers-color-scheme: light)').matches ? 'light' : 'dark')
        : (pref === 'default' ? 'light' : 'dark');
      document.documentElement.setAttribute('data-theme', mode);
      document.documentElement.setAttribute('data-theme-pref', pref);
    })();
  </script>
{/literal}
  <link rel="stylesheet" href="/assets/css/inter.css?family=Inter:wght@400;600&amp;display=swap">
  <link rel="stylesheet" href="/assets/css/iransans.css">
  <link rel="stylesheet" href="/assets/fonts/fontawesome/css/all.min.css">
{literal}
  <style>
/*TAILWIND*/
    html, body { min-height: 100vh; min-height: 100dvh; margin: 0; background-color: #0b0f19; }
    body { font-family: IRANSans, Tahoma, sans-serif; }
    .font-latin { font-family: Inter, IRANSans, sans-serif; }
    @media (min-width: 1024px) { html, body { height: 100dvh; overflow: hidden; } }

    @keyframes aurora { 0% { transform: scale(1) translate(0, 0); } 50% { transform: scale(1.15) translate(-4%, 3%); } 100% { transform: scale(1) translate(3%, -3%); } }
    @keyframes floaty { 0%, 100% { transform: translateY(0) rotate(0); } 50% { transform: translateY(-10px) rotate(3deg); } }
    @keyframes pulseGlow { 0%, 100% { opacity: .45; transform: scale(1); } 50% { opacity: .8; transform: scale(1.08); } }
    @keyframes shimmer { 0% { transform: translateX(-150%) rotate(30deg); } 100% { transform: translateX(150%) rotate(30deg); } }
    @keyframes spin { to { transform: rotate(360deg); } }
    .anim-aurora { animation: aurora 18s ease-in-out infinite alternate; }
    .anim-float { animation: floaty 5s ease-in-out infinite; }
    .anim-glow { animation: pulseGlow 3s ease-in-out infinite; }

    .glass-panel { background: rgba(18, 24, 38, .72); backdrop-filter: blur(24px); -webkit-backdrop-filter: blur(24px); border: 1px solid rgba(255, 255, 255, .12); box-shadow: 0 25px 50px -12px rgba(0, 0, 0, .65), 0 0 35px -5px rgba(124, 58, 237, .25); }
    .glass-input { background: rgba(13, 17, 28, .65); border: 1.5px solid rgba(255, 255, 255, .12); transition: border-color .2s, box-shadow .2s; }
    .glass-input:focus-within { border-color: #ec4899; box-shadow: 0 0 20px -3px rgba(236, 72, 153, .45); }
    .glass-input input { background: transparent; border: 0; outline: 0; box-shadow: none; }
    .social-icon { transition: transform .25s cubic-bezier(.34, 1.56, .64, 1), color .2s; }
    .social-icon:hover, .social-icon:focus-visible { transform: translateY(-3px) scale(1.1); }
    .feature-card { transition: transform .25s, background .25s, border-color .25s; border: 1px solid rgba(255, 255, 255, .08); background: linear-gradient(135deg, rgba(255, 255, 255, .05) 0%, rgba(255, 255, 255, .015) 100%); }
    .feature-card:hover { transform: translateX(-4px); background: linear-gradient(135deg, rgba(255, 255, 255, .09) 0%, rgba(255, 255, 255, .03) 100%); border-color: rgba(255, 255, 255, .22); }
    .btn-shimmer { position: relative; overflow: hidden; }
    .btn-shimmer::after { content: ''; position: absolute; inset: -50%; background: linear-gradient(60deg, transparent 30%, rgba(255, 255, 255, .35) 50%, transparent 70%); animation: shimmer 3.5s infinite; pointer-events: none; }
    .btn-submit[disabled] { opacity: .75; cursor: wait; }
    .btn-submit .spin { display: none; width: 1rem; height: 1rem; border: 2px solid rgba(255, 255, 255, .4); border-top-color: #fff; border-radius: 50%; animation: spin .7s linear infinite; }
    .btn-submit[disabled] .spin { display: inline-block; }
    .btn-submit[disabled] .fa-arrow-left { display: none; }
    .form-msg.ok { color: #34d399; }
    .form-msg.err { color: #fb7185; }

    /* theme switch */
    .theme-switch { display: inline-flex; gap: 2px; padding: 3px; border-radius: 9999px; background: rgba(255, 255, 255, .08); border: 1px solid rgba(255, 255, 255, .14); }
    .theme-switch button { display: inline-flex; align-items: center; gap: 6px; border: 0; background: transparent; color: #cbd5e1; font: inherit; font-size: 12px; font-weight: 700; padding: 6px 10px; border-radius: 9999px; cursor: pointer; transition: background .2s, color .2s; }
    .theme-switch button:hover { color: #fff; }
    .theme-switch button[aria-checked="true"] { background: linear-gradient(135deg, #ec4899, #8b5cf6); color: #fff; box-shadow: 0 4px 14px -4px rgba(236, 72, 153, .6); }
    .theme-switch button:focus-visible { outline: 2px solid #ec4899; outline-offset: 1px; }

    /* light theme */
    html[data-theme="light"], html[data-theme="light"] body { background-color: #f4f1fb; }
    [data-theme="light"] body { color: #1e293b; }
    [data-theme="light"] .anim-aurora, [data-theme="light"] .anim-glow { opacity: .18; }
    [data-theme="light"] .glass-panel { background: rgba(255, 255, 255, .78); border-color: rgba(15, 23, 42, .08); box-shadow: 0 25px 50px -20px rgba(76, 29, 149, .25), 0 0 35px -10px rgba(236, 72, 153, .18); }
    [data-theme="light"] .glass-input { background: rgba(255, 255, 255, .9); border-color: rgba(15, 23, 42, .14); }
    [data-theme="light"] .feature-card { background: rgba(255, 255, 255, .6); border-color: rgba(15, 23, 42, .08); }
    [data-theme="light"] .feature-card:hover { background: rgba(255, 255, 255, .85); border-color: rgba(15, 23, 42, .16); }
    [data-theme="light"] .bg-slate-950\/40 { background-color: rgba(255, 255, 255, .6); }
    [data-theme="light"] .bg-white\/10, [data-theme="light"] .bg-white\/5 { background-color: rgba(15, 23, 42, .05); }
    [data-theme="light"] .border-white\/10, [data-theme="light"] .border-white\/15 { border-color: rgba(15, 23, 42, .1); }
    [data-theme="light"] .text-white:not([class*="bg-gradient"]) { color: #0f172a; }
    [data-theme="light"] .text-slate-200 { color: #334155; }
    [data-theme="light"] .text-slate-300 { color: #475569; }
    [data-theme="light"] .text-slate-400 { color: #64748b; }
    [data-theme="light"] .hover\:text-white:hover { color: #0f172a; }
    [data-theme="light"] .text-pink-300, [data-theme="light"] .text-pink-400 { color: #db2777; }
    [data-theme="light"] .text-violet-200 { color: #6d28d9; }
    [data-theme="light"] .text-cyan-300 { color: #0e7490; }
    [data-theme="light"] .text-emerald-300, [data-theme="light"] .text-emerald-400 { color: #059669; }
    [data-theme="light"] .text-purple-300 { color: #7e22ce; }
    [data-theme="light"] .grad-title { background-image: linear-gradient(to right, #0891b2, #c026d3, #ea580c); }
    [data-theme="light"] .form-msg.ok { color: #059669; }
    [data-theme="light"] .form-msg.err { color: #e11d48; }
    [data-theme="light"] .theme-switch { background: rgba(15, 23, 42, .05); border-color: rgba(15, 23, 42, .1); }
    [data-theme="light"] .theme-switch button { color: #475569; }
    [data-theme="light"] .theme-switch button:hover { color: #0f172a; }
    [data-theme="light"] .theme-switch button[aria-checked="true"] { color: #fff; }

    @media (prefers-reduced-motion: reduce) {
      *, *::before, *::after { animation: none !important; transition: none !important; }
    }
  </style>
{/literal}
</head>
<body class="text-slate-100 flex flex-col relative selection:bg-pink-500 selection:text-white">

  <div class="fixed inset-0 pointer-events-none z-0 overflow-hidden" aria-hidden="true">
    <div class="absolute -top-[25%] -left-[10%] w-[650px] h-[650px] rounded-full bg-gradient-to-br from-indigo-600 via-purple-600 to-pink-500 blur-[130px] opacity-40 anim-aurora"></div>
    <div class="absolute top-[35%] -right-[15%] w-[600px] h-[600px] rounded-full bg-gradient-to-tl from-cyan-500 via-blue-600 to-violet-600 blur-[140px] opacity-35 anim-aurora"></div>
    <div class="hidden lg:block absolute -bottom-[20%] left-[30%] w-[550px] h-[550px] rounded-full bg-gradient-to-tr from-amber-500 via-rose-500 to-fuchsia-600 blur-[150px] opacity-30 anim-glow"></div>
    <div class="absolute inset-0 opacity-15 bg-[radial-gradient(#8b5cf6_1px,transparent_1px)] [background-size:28px_28px]"></div>
  </div>

  <header class="relative z-20 w-full px-4 sm:px-6 lg:px-12 py-3 flex items-center justify-between border-b border-white/10 backdrop-blur-md bg-slate-950/40">
    <a href="/" class="flex items-center gap-3 no-underline" aria-label="Digitsell Shop">
      <span class="relative group">
        <span class="absolute -inset-1 bg-gradient-to-r from-red-600 via-pink-600 to-orange-500 rounded-xl blur opacity-75 group-hover:opacity-100 transition duration-300"></span>
        <span class="relative flex items-center gap-2.5 px-4 py-2 bg-gradient-to-r from-red-600 to-rose-600 rounded-xl text-white font-black font-latin text-sm tracking-wide shadow-lg border border-red-400/40">
          <span class="flex h-2.5 w-2.5 relative">
            <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-green-400 opacity-75"></span>
            <span class="relative inline-flex rounded-full h-2.5 w-2.5 bg-green-400 shadow-[0_0_6px_#4ade80]"></span>
          </span>
          <span>Digitsell Shop</span>
        </span>
      </span>
      <span class="hidden sm:inline-block text-xs font-bold px-2.5 py-1 rounded-full bg-white/10 border border-white/15 text-pink-300">
        شبکه پرسرعت نسل جدید ⚡
      </span>
    </a>

    <div class="theme-switch" role="radiogroup" aria-label="تم">
      <button type="button" role="radio" data-pref="dark" aria-checked="false" title="شب"><i class="fa-solid fa-moon" aria-hidden="true"></i><span class="hidden sm:inline">شب</span></button>
      <button type="button" role="radio" data-pref="default" aria-checked="false" title="روز"><i class="fa-solid fa-sun" aria-hidden="true"></i><span class="hidden sm:inline">روز</span></button>
      <button type="button" role="radio" data-pref="auto" aria-checked="false" title="خودکار (مطابق دستگاه)"><i class="fa-solid fa-circle-half-stroke" aria-hidden="true"></i><span class="hidden sm:inline">خودکار</span></button>
    </div>
  </header>

  <main class="relative z-10 flex-1 grid grid-cols-1 lg:grid-cols-12 gap-6 lg:gap-8 px-4 sm:px-6 lg:px-12 py-4 items-center max-w-[1680px] mx-auto w-full lg:overflow-hidden">

    <section class="lg:col-span-5 order-1 flex justify-center items-center w-full" aria-labelledby="loginTitle">
      <div class="glass-panel w-full max-w-md rounded-3xl p-5 sm:p-6 lg:p-8 relative overflow-hidden">
        <div class="absolute top-0 right-0 left-0 h-[3px] bg-gradient-to-r from-pink-500 via-purple-500 to-cyan-400" aria-hidden="true"></div>
        <div class="absolute -right-16 -bottom-16 w-36 h-36 bg-pink-500/20 rounded-full blur-2xl pointer-events-none" aria-hidden="true"></div>

        <div class="flex items-center justify-between mb-4 lg:mb-5">
          <div class="flex items-center gap-2.5">
            <div class="w-10 h-10 rounded-2xl bg-gradient-to-tr from-pink-500 to-rose-600 flex items-center justify-center shadow-lg shadow-pink-500/30 text-white text-lg" aria-hidden="true">
              <i class="fa-solid fa-right-to-bracket"></i>
            </div>
            <div>
              <h1 id="loginTitle" class="text-xl lg:text-2xl font-black text-white tracking-tight m-0">ورود به حساب کاربری</h1>
              <p class="text-[11px] lg:text-xs text-slate-300 mt-0.5 mb-0">جهت دسترسی به پنل و سرویس‌ها وارد شوید</p>
            </div>
          </div>
          <span class="text-xl anim-float select-none" aria-hidden="true">✨</span>
        </div>

        <form id="formsubmit" class="space-y-3.5" novalidate>
          <div>
            <label for="email" class="block text-xs font-bold text-slate-200 mb-1.5 mr-1">{$translate->get('LoginEmail')}</label>
            <div class="glass-input rounded-2xl flex items-center px-3.5 py-2.5">
              <span class="w-8 h-8 rounded-xl bg-pink-500/15 flex items-center justify-center text-pink-400 ml-2.5 flex-shrink-0" aria-hidden="true">
                <i class="fa-solid fa-envelope text-sm"></i>
              </span>
              <input id="email" name="email" type="email" dir="ltr" autocomplete="username" autocapitalize="off" spellcheck="false" placeholder="name@domain.com" required
                     class="w-full text-base lg:text-sm text-white placeholder-slate-400 font-latin">
            </div>
          </div>

          <div>
            <div class="flex items-center justify-between mb-1.5 mx-1">
              <label for="password" class="text-xs font-bold text-slate-200">{$translate->get('LoginPass')}</label>
              <a href="/password/reset" class="text-[11px] font-medium text-pink-400 hover:text-pink-300 transition-colors no-underline">{$translate->get('ForgotPass')}</a>
            </div>
            <div class="glass-input rounded-2xl flex items-center px-3.5 py-2.5">
              <span class="w-8 h-8 rounded-xl bg-violet-500/15 flex items-center justify-center text-violet-400 ml-2.5 flex-shrink-0" aria-hidden="true">
                <i class="fa-solid fa-lock-keyhole text-sm"></i>
              </span>
              <input id="password" name="password" type="password" dir="ltr" autocomplete="current-password" placeholder="••••••••" required
                     class="w-full text-base lg:text-sm text-white placeholder-slate-400 font-latin tracking-wider">
              <button type="button" id="togglePassword" class="bg-transparent border-0 text-slate-400 hover:text-white p-1 transition-colors flex items-center mr-1 cursor-pointer" aria-label="نمایش رمز" aria-pressed="false">
                <i class="fa-solid fa-eye text-sm" aria-hidden="true"></i>
              </button>
            </div>
          </div>

          {if $Config['hcaptcha_secrete'] != null && $Config['hcaptcha_key'] != null && $Config['enable_captcha'] == "1"}
          <div class="flex justify-center"><div class="h-captcha" data-sitekey="{$Config['hcaptcha_key']}" data-theme="dark"></div></div>
          {/if}
          {if $Config['turnstile_secrete'] != null && $Config['turnstile_key'] != null && $Config['enable_captcha'] == "2"}
          <div class="flex justify-center"><div class="cf-turnstile" data-sitekey="{$Config['turnstile_key']}" data-theme="dark"></div></div>
          {/if}

          <p id="formMsg" class="form-msg hidden text-xs px-1 m-0" role="alert"></p>

          <div class="flex items-center justify-end text-xs px-1 py-0.5">
            <span class="text-[11px] text-emerald-400 flex items-center gap-1 font-bold">
              <i class="fa-solid fa-shield-check" aria-hidden="true"></i> اتصال امن SSL
            </span>
          </div>

          <button type="submit" id="sign-in"
                  class="btn-shimmer btn-submit w-full py-3 px-5 rounded-2xl border border-white/20 bg-gradient-to-r from-pink-500 via-rose-500 to-amber-500 hover:from-pink-600 hover:via-rose-600 hover:to-amber-600 text-white font-bold text-sm lg:text-base flex items-center justify-center gap-2 shadow-lg shadow-pink-500/35 active:scale-[0.98] transition duration-200 cursor-pointer">
            <span class="spin" aria-hidden="true"></span>
            <span>ورود به سامانه</span>
            <i class="fa-solid fa-arrow-left" aria-hidden="true"></i>
          </button>
        </form>

        {if $Config['enable_register'] == 1 && $Config['invitation_only'] == 0}
        <p class="text-center text-xs text-slate-400 mt-4 mb-0">
          حساب ندارید؟
          <a href="/register" class="font-bold text-pink-400 hover:text-pink-300 no-underline">ثبت‌نام کنید</a>
        </p>
        {/if}

        <nav class="lg:hidden mt-4 pt-4 border-t border-white/10 flex items-center justify-center gap-5 text-2xl" aria-label="شبکه‌های اجتماعی">
          {include file='auth/loginsocial.tpl'}
        </nav>
      </div>
    </section>

    <section class="hidden lg:flex lg:col-span-7 order-2 flex-col gap-4 lg:justify-between lg:h-full lg:max-h-[calc(100dvh-145px)] py-1">
      <div class="flex items-center justify-between gap-4">
        <div>
          <div class="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-gradient-to-r from-violet-600/30 to-pink-600/30 border border-violet-400/30 text-violet-200 text-xs font-bold mb-2">
            <span class="text-sm" aria-hidden="true">⚙️</span>
            <span>نسل چهارم تونلینگ و بهینه‌سازی سرعت</span>
          </div>
          <h2 class="text-4xl font-black tracking-tight leading-tight font-latin m-0" dir="ltr" style="text-align:right">
            <span class="text-white">Network</span>
            <span class="grad-title text-transparent bg-clip-text bg-gradient-to-r from-cyan-400 via-fuchsia-400 to-amber-300">Optimizer</span>
          </h2>
          <p class="text-sm text-slate-300 mt-1 mb-0 max-w-xl leading-relaxed">
            دسترسی فوق‌سریع و نامحدود به سراسر اینترنت با پینگ فوق‌العاده پایین و بدون قطعی
          </p>
        </div>
        <div class="flex flex-col items-center justify-center p-3 rounded-2xl bg-white/5 border border-white/10 flex-shrink-0 anim-float" aria-hidden="true">
          <div class="w-14 h-14 rounded-2xl bg-gradient-to-tr from-cyan-500 via-blue-600 to-indigo-600 flex items-center justify-center text-3xl shadow-xl shadow-cyan-500/30">🚀</div>
          <span class="text-[10px] font-bold text-cyan-300 mt-1.5 font-latin">10 Gbps Ultra</span>
        </div>
      </div>

      <ul class="space-y-2.5 list-none p-0 m-0">
        <li class="feature-card rounded-2xl p-3 flex items-center gap-3.5">
          <div class="w-12 h-12 rounded-2xl bg-gradient-to-tr from-amber-400 via-orange-500 to-red-500 flex items-center justify-center text-2xl shadow-lg shadow-orange-500/35 flex-shrink-0" aria-hidden="true">⚡</div>
          <div class="flex-1 min-w-0">
            <div class="flex items-center justify-between gap-2">
              <h3 class="text-sm font-bold text-white m-0">اتصال پایدار و پرسرعت</h3>
              <span class="text-[10px] px-2 py-0.5 rounded-md bg-emerald-500/20 text-emerald-300 border border-emerald-500/30 font-bold font-latin whitespace-nowrap">99.9% Uptime</span>
            </div>
            <p class="text-xs text-slate-300 truncate mt-0.5 mb-0">وبگردی پرسرعت و بدون افت کیفیت روی تمامی اپراتورهای همراه و ثابت</p>
          </div>
        </li>
        <li class="feature-card rounded-2xl p-3 flex items-center gap-3.5">
          <div class="w-12 h-12 rounded-2xl bg-gradient-to-tr from-fuchsia-500 via-purple-600 to-indigo-600 flex items-center justify-center text-2xl shadow-lg shadow-purple-500/35 flex-shrink-0" aria-hidden="true">🎬</div>
          <div class="flex-1 min-w-0">
            <div class="flex items-center justify-between gap-2">
              <h3 class="text-sm font-bold text-white m-0">رفع محدودیت استریم و سرویس‌های مدیا</h3>
              <span class="text-[10px] px-2 py-0.5 rounded-md bg-purple-500/20 text-purple-300 border border-purple-500/30 font-bold font-latin whitespace-nowrap">4K HDR</span>
            </div>
            <p class="text-xs text-slate-300 truncate mt-0.5 mb-0">پشتیبانی کامل از Netflix, Hulu, HBO Max, Disney+, YouTube 4K و اسپاتیفای</p>
          </div>
        </li>
        <li class="feature-card rounded-2xl p-3 flex items-center gap-3.5">
          <div class="w-12 h-12 rounded-2xl bg-gradient-to-tr from-emerald-400 via-teal-500 to-cyan-600 flex items-center justify-center text-2xl shadow-lg shadow-teal-500/35 flex-shrink-0" aria-hidden="true">📱</div>
          <div class="flex-1 min-w-0">
            <div class="flex items-center justify-between gap-2">
              <h3 class="text-sm font-bold text-white m-0">راه‌اندازی فوری روی تمامی دستگاه‌ها</h3>
              <span class="text-[10px] px-2 py-0.5 rounded-md bg-cyan-500/20 text-cyan-300 border border-cyan-500/30 font-bold font-latin whitespace-nowrap">All Platforms</span>
            </div>
            <p class="text-xs text-slate-300 truncate mt-0.5 mb-0">سازگاری با سیستم‌های Android, iOS, Windows, macOS, Linux و روترها</p>
          </div>
        </li>
      </ul>

      <nav class="pt-3 border-t border-white/10 flex items-center gap-4 text-2xl" aria-label="شبکه‌های اجتماعی">
        {include file='auth/loginsocial.tpl'}
      </nav>
    </section>
  </main>

  <footer class="relative z-20 w-full px-4 sm:px-6 lg:px-12 py-2 flex items-center justify-between text-[11px] text-slate-400 border-t border-white/10 bg-slate-950/40 backdrop-blur-md">
    <span class="flex items-center gap-1.5 text-emerald-400 font-medium">
      <span class="h-2 w-2 rounded-full bg-emerald-400 animate-ping" aria-hidden="true"></span>
      سرورها آنلاین
    </span>
    <span class="font-latin" dir="ltr">© {$smarty.now|date_format:"%Y"} Digitsell Shop</span>
  </footer>

{if $Config['hcaptcha_secrete'] != null && $Config['hcaptcha_key'] != null && $Config['enable_captcha'] == "1"}
  <script src="https://hcaptcha.com/1/api.js" async defer></script>
{/if}
{if $Config['turnstile_secrete'] != null && $Config['turnstile_key'] != null && $Config['enable_captcha'] == "2"}
  <script src="https://challenges.cloudflare.com/turnstile/v0/api.js" async defer></script>
{/if}
{literal}
  <script>
  (function () {
    var root = document.documentElement;
    var media = window.matchMedia ? matchMedia('(prefers-color-scheme: light)') : null;
    var buttons = document.querySelectorAll('.theme-switch button');
    var metaColor = document.querySelector('meta[name="theme-color"]');

    function applyTheme(pref) {
      var mode = pref === 'auto' ? (media && media.matches ? 'light' : 'dark') : (pref === 'default' ? 'light' : 'dark');
      root.setAttribute('data-theme', mode);
      root.setAttribute('data-theme-pref', pref);
      if (metaColor) metaColor.setAttribute('content', mode === 'light' ? '#f4f1fb' : '#0b0f19');
      for (var i = 0; i < buttons.length; i++) {
        buttons[i].setAttribute('aria-checked', String(buttons[i].getAttribute('data-pref') === pref));
      }
    }

    for (var i = 0; i < buttons.length; i++) {
      buttons[i].addEventListener('click', function () {
        var pref = this.getAttribute('data-pref');
        try { localStorage.setItem('hs_theme', pref); } catch (e) {}
        applyTheme(pref);
      });
    }
    if (media) {
      var onChange = function () { if (root.getAttribute('data-theme-pref') === 'auto') applyTheme('auto'); };
      media.addEventListener ? media.addEventListener('change', onChange) : media.addListener(onChange);
    }
    applyTheme(root.getAttribute('data-theme-pref') || 'dark');
  })();

  (function () {
    var form = document.getElementById('formsubmit');
    var email = document.getElementById('email');
    var pass = document.getElementById('password');
    var toggle = document.getElementById('togglePassword');
    var btn = document.getElementById('sign-in');
    var msg = document.getElementById('formMsg');

    function say(text, ok) {
      msg.textContent = text || '';
      msg.className = 'form-msg text-xs px-1 m-0 ' + (ok ? 'ok' : 'err') + (text ? '' : ' hidden');
    }

    function busy(on) { btn.disabled = on; }

    toggle.addEventListener('click', function () {
      var show = pass.type === 'password';
      pass.type = show ? 'text' : 'password';
      toggle.setAttribute('aria-pressed', String(show));
      toggle.setAttribute('aria-label', show ? 'پنهان کردن رمز' : 'نمایش رمز');
      var icon = toggle.querySelector('i');
      icon.classList.toggle('fa-eye', !show);
      icon.classList.toggle('fa-eye-slash', show);
    });

    form.addEventListener('submit', function (e) {
      e.preventDefault();
      var em = email.value.trim();
      if (!em || !pass.value) {
        say('لطفاً ایمیل و کلمه عبور را وارد کنید.', false);
        (em ? pass : email).focus();
        return;
      }
      var body = new URLSearchParams();
      body.append('email', em);
      body.append('passwd', pass.value);
      if (document.querySelector('.h-captcha') && window.hcaptcha) body.append('hcaptcha', window.hcaptcha.getResponse());
      if (document.querySelector('.cf-turnstile') && window.turnstile) body.append('turnstile', window.turnstile.getResponse());

      say('', true);
      busy(true);
      fetch('/login', {
        method: 'POST',
        credentials: 'same-origin',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8', 'X-Requested-With': 'XMLHttpRequest' },
        body: body.toString()
      }).then(function (r) {
        return r.text().then(function (t) {
          try { return JSON.parse(t); } catch (err) { throw new Error(t || ('HTTP ' + r.status)); }
        });
      }).then(function (data) {
        if (data.ret == 1) {
          say(data.msg, true);
          setTimeout(function () { location.href = '/portal/dashboard'; }, 500);
        } else if (data.ret == 2) {
          setTimeout(function () { location.href = '/verify'; }, 500);
        } else {
          say(data.msg || 'ورود ناموفق بود.', false);
          busy(false);
          if (window.hcaptcha && document.querySelector('.h-captcha')) window.hcaptcha.reset();
          if (window.turnstile && document.querySelector('.cf-turnstile')) window.turnstile.reset();
        }
      }).catch(function (err) {
        say('خطا در اتصال به سرور. دوباره تلاش کنید.', false);
        busy(false);
      });
    });
  })();
  </script>
{/literal}
</body>
</html>
