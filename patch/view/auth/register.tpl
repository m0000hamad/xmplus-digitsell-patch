<!DOCTYPE html>
<html lang="fa" dir="rtl">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
  <meta name="theme-color" content="#0b0f19">
  <title>{$Config['appName']} - {$translate->get('SignUp')}</title>
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
*,:after,:before{--tw-border-spacing-x:0;--tw-border-spacing-y:0;--tw-translate-x:0;--tw-translate-y:0;--tw-rotate:0;--tw-skew-x:0;--tw-skew-y:0;--tw-scale-x:1;--tw-scale-y:1;--tw-pan-x: ;--tw-pan-y: ;--tw-pinch-zoom: ;--tw-scroll-snap-strictness:proximity;--tw-gradient-from-position: ;--tw-gradient-via-position: ;--tw-gradient-to-position: ;--tw-ordinal: ;--tw-slashed-zero: ;--tw-numeric-figure: ;--tw-numeric-spacing: ;--tw-numeric-fraction: ;--tw-ring-inset: ;--tw-ring-offset-width:0px;--tw-ring-offset-color:#fff;--tw-ring-color:rgba(59,130,246,.5);--tw-ring-offset-shadow:0 0 #0000;--tw-ring-shadow:0 0 #0000;--tw-shadow:0 0 #0000;--tw-shadow-colored:0 0 #0000;--tw-blur: ;--tw-brightness: ;--tw-contrast: ;--tw-grayscale: ;--tw-hue-rotate: ;--tw-invert: ;--tw-saturate: ;--tw-sepia: ;--tw-drop-shadow: ;--tw-backdrop-blur: ;--tw-backdrop-brightness: ;--tw-backdrop-contrast: ;--tw-backdrop-grayscale: ;--tw-backdrop-hue-rotate: ;--tw-backdrop-invert: ;--tw-backdrop-opacity: ;--tw-backdrop-saturate: ;--tw-backdrop-sepia: ;--tw-contain-size: ;--tw-contain-layout: ;--tw-contain-paint: ;--tw-contain-style: }::backdrop{--tw-border-spacing-x:0;--tw-border-spacing-y:0;--tw-translate-x:0;--tw-translate-y:0;--tw-rotate:0;--tw-skew-x:0;--tw-skew-y:0;--tw-scale-x:1;--tw-scale-y:1;--tw-pan-x: ;--tw-pan-y: ;--tw-pinch-zoom: ;--tw-scroll-snap-strictness:proximity;--tw-gradient-from-position: ;--tw-gradient-via-position: ;--tw-gradient-to-position: ;--tw-ordinal: ;--tw-slashed-zero: ;--tw-numeric-figure: ;--tw-numeric-spacing: ;--tw-numeric-fraction: ;--tw-ring-inset: ;--tw-ring-offset-width:0px;--tw-ring-offset-color:#fff;--tw-ring-color:rgba(59,130,246,.5);--tw-ring-offset-shadow:0 0 #0000;--tw-ring-shadow:0 0 #0000;--tw-shadow:0 0 #0000;--tw-shadow-colored:0 0 #0000;--tw-blur: ;--tw-brightness: ;--tw-contrast: ;--tw-grayscale: ;--tw-hue-rotate: ;--tw-invert: ;--tw-saturate: ;--tw-sepia: ;--tw-drop-shadow: ;--tw-backdrop-blur: ;--tw-backdrop-brightness: ;--tw-backdrop-contrast: ;--tw-backdrop-grayscale: ;--tw-backdrop-hue-rotate: ;--tw-backdrop-invert: ;--tw-backdrop-opacity: ;--tw-backdrop-saturate: ;--tw-backdrop-sepia: ;--tw-contain-size: ;--tw-contain-layout: ;--tw-contain-paint: ;--tw-contain-style: }/*! tailwindcss v3.4.17 | MIT License | https://tailwindcss.com*/*,:after,:before{box-sizing:border-box;border:0 solid #e5e7eb}:after,:before{--tw-content:""}:host,html{line-height:1.5;-webkit-text-size-adjust:100%;-moz-tab-size:4;-o-tab-size:4;tab-size:4;font-family:ui-sans-serif,system-ui,sans-serif,Apple Color Emoji,Segoe UI Emoji,Segoe UI Symbol,Noto Color Emoji;font-feature-settings:normal;font-variation-settings:normal;-webkit-tap-highlight-color:transparent}body{margin:0;line-height:inherit}hr{height:0;color:inherit;border-top-width:1px}abbr:where([title]){-webkit-text-decoration:underline dotted;text-decoration:underline dotted}h1,h2,h3,h4,h5,h6{font-size:inherit;font-weight:inherit}a{color:inherit;text-decoration:inherit}b,strong{font-weight:bolder}code,kbd,pre,samp{font-family:ui-monospace,SFMono-Regular,Menlo,Monaco,Consolas,Liberation Mono,Courier New,monospace;font-feature-settings:normal;font-variation-settings:normal;font-size:1em}small{font-size:80%}sub,sup{font-size:75%;line-height:0;position:relative;vertical-align:baseline}sub{bottom:-.25em}sup{top:-.5em}table{text-indent:0;border-color:inherit;border-collapse:collapse}button,input,optgroup,select,textarea{font-family:inherit;font-feature-settings:inherit;font-variation-settings:inherit;font-size:100%;font-weight:inherit;line-height:inherit;letter-spacing:inherit;color:inherit;margin:0;padding:0}button,select{text-transform:none}button,input:where([type=button]),input:where([type=reset]),input:where([type=submit]){-webkit-appearance:button;background-color:transparent;background-image:none}:-moz-focusring{outline:auto}:-moz-ui-invalid{box-shadow:none}progress{vertical-align:baseline}::-webkit-inner-spin-button,::-webkit-outer-spin-button{height:auto}[type=search]{-webkit-appearance:textfield;outline-offset:-2px}::-webkit-search-decoration{-webkit-appearance:none}::-webkit-file-upload-button{-webkit-appearance:button;font:inherit}summary{display:list-item}blockquote,dd,dl,figure,h1,h2,h3,h4,h5,h6,hr,p,pre{margin:0}fieldset{margin:0}fieldset,legend{padding:0}menu,ol,ul{list-style:none;margin:0;padding:0}dialog{padding:0}textarea{resize:vertical}input::-moz-placeholder,textarea::-moz-placeholder{opacity:1;color:#9ca3af}input::placeholder,textarea::placeholder{opacity:1;color:#9ca3af}[role=button],button{cursor:pointer}:disabled{cursor:default}audio,canvas,embed,iframe,img,object,svg,video{display:block;vertical-align:middle}img,video{max-width:100%;height:auto}[hidden]:where(:not([hidden=until-found])){display:none}.pointer-events-none{pointer-events:none}.fixed{position:fixed}.absolute{position:absolute}.relative{position:relative}.-inset-1{inset:-.25rem}.inset-0{inset:0}.-bottom-16{bottom:-4rem}.-bottom-\[20\%\]{bottom:-20%}.-left-\[10\%\]{left:-10%}.-right-16{right:-4rem}.-right-\[15\%\]{right:-15%}.-top-\[25\%\]{top:-25%}.left-0{left:0}.left-\[30\%\]{left:30%}.right-0{right:0}.top-0{top:0}.top-\[35\%\]{top:35%}.z-0{z-index:0}.z-10{z-index:10}.z-20{z-index:20}.order-1{order:1}.order-2{order:2}.m-0{margin:0}.mx-1{margin-left:.25rem;margin-right:.25rem}.mx-auto{margin-left:auto;margin-right:auto}.mb-0{margin-bottom:0}.mb-1\.5{margin-bottom:.375rem}.mb-2{margin-bottom:.5rem}.mb-3{margin-bottom:.75rem}.mb-4{margin-bottom:1rem}.ml-1{margin-left:.25rem}.ml-2\.5{margin-left:.625rem}.mr-1{margin-right:.25rem}.mt-0{margin-top:0}.mt-0\.5{margin-top:.125rem}.mt-1{margin-top:.25rem}.mt-1\.5{margin-top:.375rem}.mt-4{margin-top:1rem}.block{display:block}.flex{display:flex}.inline-flex{display:inline-flex}.grid{display:grid}.hidden{display:none}.h-1{height:.25rem}.h-10{height:2.5rem}.h-12{height:3rem}.h-14{height:3.5rem}.h-2{height:.5rem}.h-2\.5{height:.625rem}.h-36{height:9rem}.h-8{height:2rem}.h-\[3px\]{height:3px}.h-\[550px\]{height:550px}.h-\[600px\]{height:600px}.h-\[650px\]{height:650px}.h-full{height:100%}.w-10{width:2.5rem}.w-12{width:3rem}.w-14{width:3.5rem}.w-2{width:.5rem}.w-2\.5{width:.625rem}.w-36{width:9rem}.w-8{width:2rem}.w-\[550px\]{width:550px}.w-\[600px\]{width:600px}.w-\[650px\]{width:650px}.w-full{width:100%}.min-w-0{min-width:0}.max-w-\[1680px\]{max-width:1680px}.max-w-md{max-width:28rem}.max-w-xl{max-width:36rem}.flex-1{flex:1 1 0%}.flex-shrink-0{flex-shrink:0}.transform{transform:translate(var(--tw-translate-x),var(--tw-translate-y)) rotate(var(--tw-rotate)) skewX(var(--tw-skew-x)) skewY(var(--tw-skew-y)) scaleX(var(--tw-scale-x)) scaleY(var(--tw-scale-y))}@keyframes ping{75%,to{transform:scale(2);opacity:0}}.animate-ping{animation:ping 1s cubic-bezier(0,0,.2,1) infinite}.cursor-pointer{cursor:pointer}.select-none{-webkit-user-select:none;-moz-user-select:none;user-select:none}.list-none{list-style-type:none}.grid-cols-1{grid-template-columns:repeat(1,minmax(0,1fr))}.grid-cols-2{grid-template-columns:repeat(2,minmax(0,1fr))}.flex-col{flex-direction:column}.items-center{align-items:center}.justify-center{justify-content:center}.justify-between{justify-content:space-between}.gap-1{gap:.25rem}.gap-1\.5{gap:.375rem}.gap-2{gap:.5rem}.gap-2\.5{gap:.625rem}.gap-3{gap:.75rem}.gap-3\.5{gap:.875rem}.gap-4{gap:1rem}.gap-6{gap:1.5rem}.space-y-2>:not([hidden])~:not([hidden]){--tw-space-y-reverse:0;margin-top:calc(.5rem*(1 - var(--tw-space-y-reverse)));margin-bottom:calc(.5rem*var(--tw-space-y-reverse))}.space-y-3>:not([hidden])~:not([hidden]){--tw-space-y-reverse:0;margin-top:calc(.75rem*(1 - var(--tw-space-y-reverse)));margin-bottom:calc(.75rem*var(--tw-space-y-reverse))}.overflow-hidden{overflow:hidden}.whitespace-nowrap{white-space:nowrap}.rounded-2xl{border-radius:1rem}.rounded-3xl{border-radius:1.5rem}.rounded-full{border-radius:9999px}.rounded-md{border-radius:.375rem}.rounded-xl{border-radius:.75rem}.border{border-width:1px}.border-0{border-width:0}.border-b{border-bottom-width:1px}.border-t{border-top-width:1px}.border-cyan-500\/30{border-color:rgba(6,182,212,.3)}.border-emerald-500\/30{border-color:rgba(16,185,129,.3)}.border-pink-500\/30{border-color:rgba(236,72,153,.3)}.border-purple-500\/30{border-color:rgba(168,85,247,.3)}.border-red-400\/40{border-color:hsla(0,91%,71%,.4)}.border-violet-400\/30{border-color:rgba(167,139,250,.3)}.border-white{--tw-border-opacity:1;border-color:rgb(255 255 255/var(--tw-border-opacity,1))}.border-white\/10{border-color:hsla(0,0%,100%,.1)}.border-white\/15{border-color:hsla(0,0%,100%,.15)}.border-white\/20{border-color:hsla(0,0%,100%,.2)}.bg-cyan-500\/20{background-color:rgba(6,182,212,.2)}.bg-emerald-400{--tw-bg-opacity:1;background-color:rgb(52 211 153/var(--tw-bg-opacity,1))}.bg-emerald-500\/15{background-color:rgba(16,185,129,.15)}.bg-emerald-500\/20{background-color:rgba(16,185,129,.2)}.bg-green-400{--tw-bg-opacity:1;background-color:rgb(74 222 128/var(--tw-bg-opacity,1))}.bg-pink-500\/15{background-color:rgba(236,72,153,.15)}.bg-pink-500\/20{background-color:rgba(236,72,153,.2)}.bg-purple-500\/20{background-color:rgba(168,85,247,.2)}.bg-slate-950{--tw-bg-opacity:1;background-color:rgb(2 6 23/var(--tw-bg-opacity,1))}.bg-slate-950\/40{background-color:rgba(2,6,23,.4)}.bg-transparent{background-color:transparent}.bg-violet-500\/15{background-color:rgba(139,92,246,.15)}.bg-violet-500\/20{background-color:rgba(139,92,246,.2)}.bg-white{--tw-bg-opacity:1;background-color:rgb(255 255 255/var(--tw-bg-opacity,1))}.bg-white\/10{background-color:hsla(0,0%,100%,.1)}.bg-white\/5{background-color:hsla(0,0%,100%,.05)}.bg-\[radial-gradient\(\#8b5cf6_1px\2c transparent_1px\)\]{background-image:radial-gradient(#8b5cf6 1px,transparent 0)}.bg-gradient-to-br{background-image:linear-gradient(to bottom right,var(--tw-gradient-stops))}.bg-gradient-to-r{background-image:linear-gradient(to right,var(--tw-gradient-stops))}.bg-gradient-to-tl{background-image:linear-gradient(to top left,var(--tw-gradient-stops))}.bg-gradient-to-tr{background-image:linear-gradient(to top right,var(--tw-gradient-stops))}.from-amber-400{--tw-gradient-from:#fbbf24 var(--tw-gradient-from-position);--tw-gradient-to:rgba(251,191,36,0) var(--tw-gradient-to-position);--tw-gradient-stops:var(--tw-gradient-from),var(--tw-gradient-to)}.from-amber-500{--tw-gradient-from:#f59e0b var(--tw-gradient-from-position);--tw-gradient-to:rgba(245,158,11,0) var(--tw-gradient-to-position);--tw-gradient-stops:var(--tw-gradient-from),var(--tw-gradient-to)}.from-cyan-400{--tw-gradient-from:#22d3ee var(--tw-gradient-from-position);--tw-gradient-to:rgba(34,211,238,0) var(--tw-gradient-to-position);--tw-gradient-stops:var(--tw-gradient-from),var(--tw-gradient-to)}.from-cyan-500{--tw-gradient-from:#06b6d4 var(--tw-gradient-from-position);--tw-gradient-to:rgba(6,182,212,0) var(--tw-gradient-to-position);--tw-gradient-stops:var(--tw-gradient-from),var(--tw-gradient-to)}.from-emerald-400{--tw-gradient-from:#34d399 var(--tw-gradient-from-position);--tw-gradient-to:rgba(52,211,153,0) var(--tw-gradient-to-position);--tw-gradient-stops:var(--tw-gradient-from),var(--tw-gradient-to)}.from-fuchsia-500{--tw-gradient-from:#d946ef var(--tw-gradient-from-position);--tw-gradient-to:rgba(217,70,239,0) var(--tw-gradient-to-position);--tw-gradient-stops:var(--tw-gradient-from),var(--tw-gradient-to)}.from-indigo-600{--tw-gradient-from:#4f46e5 var(--tw-gradient-from-position);--tw-gradient-to:rgba(79,70,229,0) var(--tw-gradient-to-position);--tw-gradient-stops:var(--tw-gradient-from),var(--tw-gradient-to)}.from-pink-500{--tw-gradient-from:#ec4899 var(--tw-gradient-from-position);--tw-gradient-to:rgba(236,72,153,0) var(--tw-gradient-to-position);--tw-gradient-stops:var(--tw-gradient-from),var(--tw-gradient-to)}.from-red-600{--tw-gradient-from:#dc2626 var(--tw-gradient-from-position);--tw-gradient-to:rgba(220,38,38,0) var(--tw-gradient-to-position);--tw-gradient-stops:var(--tw-gradient-from),var(--tw-gradient-to)}.from-violet-500{--tw-gradient-from:#8b5cf6 var(--tw-gradient-from-position);--tw-gradient-to:rgba(139,92,246,0) var(--tw-gradient-to-position);--tw-gradient-stops:var(--tw-gradient-from),var(--tw-gradient-to)}.from-violet-600{--tw-gradient-from:#7c3aed var(--tw-gradient-from-position);--tw-gradient-to:rgba(124,58,237,0) var(--tw-gradient-to-position);--tw-gradient-stops:var(--tw-gradient-from),var(--tw-gradient-to)}.from-violet-600\/30{--tw-gradient-from:rgba(124,58,237,.3) var(--tw-gradient-from-position);--tw-gradient-to:rgba(124,58,237,0) var(--tw-gradient-to-position);--tw-gradient-stops:var(--tw-gradient-from),var(--tw-gradient-to)}.via-blue-600{--tw-gradient-to:rgba(37,99,235,0) var(--tw-gradient-to-position);--tw-gradient-stops:var(--tw-gradient-from),#2563eb var(--tw-gradient-via-position),var(--tw-gradient-to)}.via-fuchsia-400{--tw-gradient-to:rgba(232,121,249,0) var(--tw-gradient-to-position);--tw-gradient-stops:var(--tw-gradient-from),#e879f9 var(--tw-gradient-via-position),var(--tw-gradient-to)}.via-fuchsia-500{--tw-gradient-to:rgba(217,70,239,0) var(--tw-gradient-to-position);--tw-gradient-stops:var(--tw-gradient-from),#d946ef var(--tw-gradient-via-position),var(--tw-gradient-to)}.via-orange-500{--tw-gradient-to:rgba(249,115,22,0) var(--tw-gradient-to-position);--tw-gradient-stops:var(--tw-gradient-from),#f97316 var(--tw-gradient-via-position),var(--tw-gradient-to)}.via-pink-600{--tw-gradient-to:rgba(219,39,119,0) var(--tw-gradient-to-position);--tw-gradient-stops:var(--tw-gradient-from),#db2777 var(--tw-gradient-via-position),var(--tw-gradient-to)}.via-purple-500{--tw-gradient-to:rgba(168,85,247,0) var(--tw-gradient-to-position);--tw-gradient-stops:var(--tw-gradient-from),#a855f7 var(--tw-gradient-via-position),var(--tw-gradient-to)}.via-purple-600{--tw-gradient-to:rgba(147,51,234,0) var(--tw-gradient-to-position);--tw-gradient-stops:var(--tw-gradient-from),#9333ea var(--tw-gradient-via-position),var(--tw-gradient-to)}.via-rose-500{--tw-gradient-to:rgba(244,63,94,0) var(--tw-gradient-to-position);--tw-gradient-stops:var(--tw-gradient-from),#f43f5e var(--tw-gradient-via-position),var(--tw-gradient-to)}.via-teal-500{--tw-gradient-to:rgba(20,184,166,0) var(--tw-gradient-to-position);--tw-gradient-stops:var(--tw-gradient-from),#14b8a6 var(--tw-gradient-via-position),var(--tw-gradient-to)}.to-amber-300{--tw-gradient-to:#fcd34d var(--tw-gradient-to-position)}.to-amber-500{--tw-gradient-to:#f59e0b var(--tw-gradient-to-position)}.to-cyan-600{--tw-gradient-to:#0891b2 var(--tw-gradient-to-position)}.to-fuchsia-600{--tw-gradient-to:#c026d3 var(--tw-gradient-to-position)}.to-indigo-600{--tw-gradient-to:#4f46e5 var(--tw-gradient-to-position)}.to-orange-500{--tw-gradient-to:#f97316 var(--tw-gradient-to-position)}.to-pink-500{--tw-gradient-to:#ec4899 var(--tw-gradient-to-position)}.to-pink-600\/30{--tw-gradient-to:rgba(219,39,119,.3) var(--tw-gradient-to-position)}.to-red-500{--tw-gradient-to:#ef4444 var(--tw-gradient-to-position)}.to-rose-600{--tw-gradient-to:#e11d48 var(--tw-gradient-to-position)}.to-violet-600{--tw-gradient-to:#7c3aed var(--tw-gradient-to-position)}.bg-clip-text{-webkit-background-clip:text;background-clip:text}.p-0{padding:0}.p-1{padding:.25rem}.p-3{padding:.75rem}.p-5{padding:1.25rem}.px-1{padding-left:.25rem;padding-right:.25rem}.px-2{padding-left:.5rem;padding-right:.5rem}.px-2\.5{padding-left:.625rem;padding-right:.625rem}.px-3{padding-left:.75rem;padding-right:.75rem}.px-3\.5{padding-left:.875rem;padding-right:.875rem}.px-4{padding-left:1rem;padding-right:1rem}.px-5{padding-left:1.25rem;padding-right:1.25rem}.py-0\.5{padding-top:.125rem;padding-bottom:.125rem}.py-1{padding-top:.25rem;padding-bottom:.25rem}.py-2{padding-top:.5rem;padding-bottom:.5rem}.py-3{padding-top:.75rem;padding-bottom:.75rem}.py-4{padding-top:1rem;padding-bottom:1rem}.pt-3{padding-top:.75rem}.pt-4{padding-top:1rem}.text-center{text-align:center}.text-2xl{font-size:1.5rem;line-height:2rem}.text-3xl{font-size:1.875rem;line-height:2.25rem}.text-\[10px\]{font-size:10px}.text-\[11px\]{font-size:11px}.text-base{font-size:1rem;line-height:1.5rem}.text-lg{font-size:1.125rem;line-height:1.75rem}.text-sm{font-size:.875rem;line-height:1.25rem}.text-xl{font-size:1.25rem;line-height:1.75rem}.text-xs{font-size:.75rem;line-height:1rem}.font-black{font-weight:900}.font-bold{font-weight:700}.font-medium{font-weight:500}.leading-relaxed{line-height:1.625}.leading-tight{line-height:1.25}.tracking-tight{letter-spacing:-.025em}.tracking-wide{letter-spacing:.025em}.tracking-wider{letter-spacing:.05em}.text-cyan-300{--tw-text-opacity:1;color:rgb(103 232 249/var(--tw-text-opacity,1))}.text-emerald-300{--tw-text-opacity:1;color:rgb(110 231 183/var(--tw-text-opacity,1))}.text-emerald-400{--tw-text-opacity:1;color:rgb(52 211 153/var(--tw-text-opacity,1))}.text-indigo-400{--tw-text-opacity:1;color:rgb(129 140 248/var(--tw-text-opacity,1))}.text-orange-500{--tw-text-opacity:1;color:rgb(249 115 22/var(--tw-text-opacity,1))}.text-pink-300{--tw-text-opacity:1;color:rgb(249 168 212/var(--tw-text-opacity,1))}.text-pink-400{--tw-text-opacity:1;color:rgb(244 114 182/var(--tw-text-opacity,1))}.text-pink-500{--tw-text-opacity:1;color:rgb(236 72 153/var(--tw-text-opacity,1))}.text-purple-300{--tw-text-opacity:1;color:rgb(216 180 254/var(--tw-text-opacity,1))}.text-red-500{--tw-text-opacity:1;color:rgb(239 68 68/var(--tw-text-opacity,1))}.text-sky-400{--tw-text-opacity:1;color:rgb(56 189 248/var(--tw-text-opacity,1))}.text-slate-100{--tw-text-opacity:1;color:rgb(241 245 249/var(--tw-text-opacity,1))}.text-slate-200{--tw-text-opacity:1;color:rgb(226 232 240/var(--tw-text-opacity,1))}.text-slate-300{--tw-text-opacity:1;color:rgb(203 213 225/var(--tw-text-opacity,1))}.text-slate-400{--tw-text-opacity:1;color:rgb(148 163 184/var(--tw-text-opacity,1))}.text-transparent{color:transparent}.text-violet-200{--tw-text-opacity:1;color:rgb(221 214 254/var(--tw-text-opacity,1))}.text-violet-400{--tw-text-opacity:1;color:rgb(167 139 250/var(--tw-text-opacity,1))}.text-white{--tw-text-opacity:1;color:rgb(255 255 255/var(--tw-text-opacity,1))}.no-underline{text-decoration-line:none}.placeholder-slate-400::-moz-placeholder{--tw-placeholder-opacity:1;color:rgb(148 163 184/var(--tw-placeholder-opacity,1))}.placeholder-slate-400::placeholder{--tw-placeholder-opacity:1;color:rgb(148 163 184/var(--tw-placeholder-opacity,1))}.opacity-15{opacity:.15}.opacity-30{opacity:.3}.opacity-35{opacity:.35}.opacity-40{opacity:.4}.opacity-75{opacity:.75}.shadow-\[0_0_6px_\#4ade80\]{--tw-shadow:0 0 6px #4ade80;--tw-shadow-colored:0 0 6px var(--tw-shadow-color)}.shadow-\[0_0_6px_\#4ade80\],.shadow-lg{box-shadow:var(--tw-ring-offset-shadow,0 0 #0000),var(--tw-ring-shadow,0 0 #0000),var(--tw-shadow)}.shadow-lg{--tw-shadow:0 10px 15px -3px rgba(0,0,0,.1),0 4px 6px -4px rgba(0,0,0,.1);--tw-shadow-colored:0 10px 15px -3px var(--tw-shadow-color),0 4px 6px -4px var(--tw-shadow-color)}.shadow-xl{--tw-shadow:0 20px 25px -5px rgba(0,0,0,.1),0 8px 10px -6px rgba(0,0,0,.1);--tw-shadow-colored:0 20px 25px -5px var(--tw-shadow-color),0 8px 10px -6px var(--tw-shadow-color);box-shadow:var(--tw-ring-offset-shadow,0 0 #0000),var(--tw-ring-shadow,0 0 #0000),var(--tw-shadow)}.shadow-cyan-500\/30{--tw-shadow-color:rgba(6,182,212,.3);--tw-shadow:var(--tw-shadow-colored)}.shadow-orange-500\/35{--tw-shadow-color:rgba(249,115,22,.35);--tw-shadow:var(--tw-shadow-colored)}.shadow-pink-500\/35{--tw-shadow-color:rgba(236,72,153,.35);--tw-shadow:var(--tw-shadow-colored)}.shadow-purple-500\/35{--tw-shadow-color:rgba(168,85,247,.35);--tw-shadow:var(--tw-shadow-colored)}.shadow-teal-500\/35{--tw-shadow-color:rgba(20,184,166,.35);--tw-shadow:var(--tw-shadow-colored)}.outline{outline-style:solid}.blur{--tw-blur:blur(8px)}.blur,.blur-2xl{filter:var(--tw-blur) var(--tw-brightness) var(--tw-contrast) var(--tw-grayscale) var(--tw-hue-rotate) var(--tw-invert) var(--tw-saturate) var(--tw-sepia) var(--tw-drop-shadow)}.blur-2xl{--tw-blur:blur(40px)}.blur-\[130px\]{--tw-blur:blur(130px)}.blur-\[130px\],.blur-\[140px\]{filter:var(--tw-blur) var(--tw-brightness) var(--tw-contrast) var(--tw-grayscale) var(--tw-hue-rotate) var(--tw-invert) var(--tw-saturate) var(--tw-sepia) var(--tw-drop-shadow)}.blur-\[140px\]{--tw-blur:blur(140px)}.blur-\[150px\]{--tw-blur:blur(150px);filter:var(--tw-blur) var(--tw-brightness) var(--tw-contrast) var(--tw-grayscale) var(--tw-hue-rotate) var(--tw-invert) var(--tw-saturate) var(--tw-sepia) var(--tw-drop-shadow)}.backdrop-blur-md{--tw-backdrop-blur:blur(12px)}.backdrop-blur-md,.backdrop-filter{-webkit-backdrop-filter:var(--tw-backdrop-blur) var(--tw-backdrop-brightness) var(--tw-backdrop-contrast) var(--tw-backdrop-grayscale) var(--tw-backdrop-hue-rotate) var(--tw-backdrop-invert) var(--tw-backdrop-opacity) var(--tw-backdrop-saturate) var(--tw-backdrop-sepia);backdrop-filter:var(--tw-backdrop-blur) var(--tw-backdrop-brightness) var(--tw-backdrop-contrast) var(--tw-backdrop-grayscale) var(--tw-backdrop-hue-rotate) var(--tw-backdrop-invert) var(--tw-backdrop-opacity) var(--tw-backdrop-saturate) var(--tw-backdrop-sepia)}.transition{transition-property:color,background-color,border-color,text-decoration-color,fill,stroke,opacity,box-shadow,transform,filter,-webkit-backdrop-filter;transition-property:color,background-color,border-color,text-decoration-color,fill,stroke,opacity,box-shadow,transform,filter,backdrop-filter;transition-property:color,background-color,border-color,text-decoration-color,fill,stroke,opacity,box-shadow,transform,filter,backdrop-filter,-webkit-backdrop-filter;transition-timing-function:cubic-bezier(.4,0,.2,1);transition-duration:.15s}.transition-colors{transition-property:color,background-color,border-color,text-decoration-color,fill,stroke;transition-timing-function:cubic-bezier(.4,0,.2,1);transition-duration:.15s}.duration-200{transition-duration:.2s}.duration-300{transition-duration:.3s}.ease-in-out{transition-timing-function:cubic-bezier(.4,0,.2,1)}.\[background-size\:28px_28px\]{background-size:28px 28px}.selection\:bg-pink-500 ::-moz-selection{--tw-bg-opacity:1;background-color:rgb(236 72 153/var(--tw-bg-opacity,1))}.selection\:bg-pink-500 ::selection{--tw-bg-opacity:1;background-color:rgb(236 72 153/var(--tw-bg-opacity,1))}.selection\:text-white ::-moz-selection{--tw-text-opacity:1;color:rgb(255 255 255/var(--tw-text-opacity,1))}.selection\:text-white ::selection{--tw-text-opacity:1;color:rgb(255 255 255/var(--tw-text-opacity,1))}.selection\:bg-pink-500::-moz-selection{--tw-bg-opacity:1;background-color:rgb(236 72 153/var(--tw-bg-opacity,1))}.selection\:bg-pink-500::selection{--tw-bg-opacity:1;background-color:rgb(236 72 153/var(--tw-bg-opacity,1))}.selection\:text-white::-moz-selection{--tw-text-opacity:1;color:rgb(255 255 255/var(--tw-text-opacity,1))}.selection\:text-white::selection{--tw-text-opacity:1;color:rgb(255 255 255/var(--tw-text-opacity,1))}.hover\:from-violet-700:hover{--tw-gradient-from:#6d28d9 var(--tw-gradient-from-position);--tw-gradient-to:rgba(109,40,217,0) var(--tw-gradient-to-position);--tw-gradient-stops:var(--tw-gradient-from),var(--tw-gradient-to)}.hover\:via-fuchsia-600:hover{--tw-gradient-to:rgba(192,38,211,0) var(--tw-gradient-to-position);--tw-gradient-stops:var(--tw-gradient-from),#c026d3 var(--tw-gradient-via-position),var(--tw-gradient-to)}.hover\:to-pink-600:hover{--tw-gradient-to:#db2777 var(--tw-gradient-to-position)}.hover\:text-emerald-300:hover{--tw-text-opacity:1;color:rgb(110 231 183/var(--tw-text-opacity,1))}.hover\:text-indigo-300:hover{--tw-text-opacity:1;color:rgb(165 180 252/var(--tw-text-opacity,1))}.hover\:text-orange-400:hover{--tw-text-opacity:1;color:rgb(251 146 60/var(--tw-text-opacity,1))}.hover\:text-pink-300:hover{--tw-text-opacity:1;color:rgb(249 168 212/var(--tw-text-opacity,1))}.hover\:text-pink-400:hover{--tw-text-opacity:1;color:rgb(244 114 182/var(--tw-text-opacity,1))}.hover\:text-red-400:hover{--tw-text-opacity:1;color:rgb(248 113 113/var(--tw-text-opacity,1))}.hover\:text-sky-300:hover{--tw-text-opacity:1;color:rgb(125 211 252/var(--tw-text-opacity,1))}.hover\:text-white:hover{--tw-text-opacity:1;color:rgb(255 255 255/var(--tw-text-opacity,1))}.active\:scale-\[0\.98\]:active{--tw-scale-x:0.98;--tw-scale-y:0.98;transform:translate(var(--tw-translate-x),var(--tw-translate-y)) rotate(var(--tw-rotate)) skewX(var(--tw-skew-x)) skewY(var(--tw-skew-y)) scaleX(var(--tw-scale-x)) scaleY(var(--tw-scale-y))}.group:hover .group-hover\:opacity-100{opacity:1}@media (min-width:640px){.sm\:inline-block{display:inline-block}.sm\:inline{display:inline}.sm\:p-6{padding:1.5rem}.sm\:px-6{padding-left:1.5rem;padding-right:1.5rem}}@media (min-width:1024px){.lg\:col-span-5{grid-column:span 5/span 5}.lg\:col-span-7{grid-column:span 7/span 7}.lg\:block{display:block}.lg\:flex{display:flex}.lg\:hidden{display:none}.lg\:h-full{height:100%}.lg\:max-h-\[calc\(100dvh-145px\)\]{max-height:calc(100dvh - 145px)}.lg\:grid-cols-12{grid-template-columns:repeat(12,minmax(0,1fr))}.lg\:justify-between{justify-content:space-between}.lg\:gap-8{gap:2rem}.lg\:overflow-hidden{overflow:hidden}.lg\:p-7{padding:1.75rem}.lg\:px-12{padding-left:3rem;padding-right:3rem}.lg\:text-2xl{font-size:1.5rem;line-height:2rem}.lg\:text-base{font-size:1rem;line-height:1.5rem}.lg\:text-sm{font-size:.875rem;line-height:1.25rem}.lg\:text-xs{font-size:.75rem;line-height:1rem}}
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

    <section class="lg:col-span-5 order-1 flex justify-center items-center w-full" aria-labelledby="regTitle">
      <div class="glass-panel w-full max-w-md rounded-3xl p-5 sm:p-6 lg:p-7 relative overflow-hidden">
        <div class="absolute top-0 right-0 left-0 h-[3px] bg-gradient-to-r from-cyan-400 via-purple-500 to-pink-500" aria-hidden="true"></div>
        <div class="absolute -right-16 -bottom-16 w-36 h-36 bg-violet-500/20 rounded-full blur-2xl pointer-events-none" aria-hidden="true"></div>

        <div class="flex items-center justify-between mb-4">
          <div class="flex items-center gap-2.5">
            <div class="w-10 h-10 rounded-2xl bg-gradient-to-tr from-violet-500 to-fuchsia-600 flex items-center justify-center shadow-lg shadow-purple-500/35 text-white text-lg" aria-hidden="true">
              <i class="fa-solid fa-user-plus"></i>
            </div>
            <div>
              <h1 id="regTitle" class="text-xl lg:text-2xl font-black text-white tracking-tight m-0">ساخت حساب کاربری</h1>
              <p class="text-[11px] lg:text-xs text-slate-300 mt-0.5 mb-0">کمتر از یک دقیقه؛ بعدش مستقیم وارد پنل می‌شوید</p>
            </div>
          </div>
          <span class="text-xl anim-float select-none" aria-hidden="true">🚀</span>
        </div>

        <p id="affNote" class="hidden text-[11px] font-bold text-emerald-300 bg-emerald-500/15 border border-emerald-500/30 rounded-xl px-3 py-2 mb-3 mt-0">
          <i class="fa-solid fa-gift ml-1" aria-hidden="true"></i> با لینک دعوت یکی از دوستانتان آمده‌اید
        </p>

        <form id="formsubmit" class="space-y-3" novalidate>
          <div>
            <label for="email" class="block text-xs font-bold text-slate-200 mb-1.5 mr-1">{$translate->get('LoginEmail')}</label>
            <div class="glass-input rounded-2xl flex items-center px-3.5 py-2">
              <span class="w-8 h-8 rounded-xl bg-pink-500/15 flex items-center justify-center text-pink-400 ml-2.5 flex-shrink-0" aria-hidden="true">
                <i class="fa-solid fa-envelope text-sm"></i>
              </span>
              <input id="email" name="email" type="email" dir="ltr" autocomplete="email" autocapitalize="off" spellcheck="false" placeholder="name@domain.com" required
                     class="w-full text-base lg:text-sm text-white placeholder-slate-400 font-latin">
            </div>
          </div>

          <div id="codeRow" class="hidden">
            <label for="emailcode" class="block text-xs font-bold text-slate-200 mb-1.5 mr-1">{$translate->get('VerificationCode')}</label>
            <div class="glass-input rounded-2xl flex items-center px-3.5 py-2">
              <span class="w-8 h-8 rounded-xl bg-cyan-500/20 flex items-center justify-center text-cyan-300 ml-2.5 flex-shrink-0" aria-hidden="true">
                <i class="fa-solid fa-key text-sm"></i>
              </span>
              <input id="emailcode" name="emailcode" type="text" dir="ltr" inputmode="numeric" autocomplete="one-time-code" placeholder="------"
                     class="w-full text-base lg:text-sm text-white placeholder-slate-400 font-latin tracking-wider">
              <button type="button" id="sendCode" class="whitespace-nowrap text-[11px] font-bold text-pink-400 hover:text-pink-300 bg-transparent border-0 p-1 mr-1 cursor-pointer">ارسال کد</button>
            </div>
          </div>

          <div>
            <label for="password" class="block text-xs font-bold text-slate-200 mb-1.5 mr-1">{$translate->get('LoginPass')}</label>
            <div class="glass-input rounded-2xl flex items-center px-3.5 py-2">
              <span class="w-8 h-8 rounded-xl bg-violet-500/15 flex items-center justify-center text-violet-400 ml-2.5 flex-shrink-0" aria-hidden="true">
                <i class="fa-solid fa-lock-keyhole text-sm"></i>
              </span>
              <input id="password" name="password" type="password" dir="ltr" autocomplete="new-password" placeholder="••••••••" required
                     class="w-full text-base lg:text-sm text-white placeholder-slate-400 font-latin tracking-wider">
              <button type="button" id="togglePassword" class="bg-transparent border-0 text-slate-400 hover:text-white p-1 transition-colors flex items-center mr-1 cursor-pointer" aria-label="نمایش رمز" aria-pressed="false">
                <i class="fa-solid fa-eye text-sm" aria-hidden="true"></i>
              </button>
            </div>
            <div class="flex gap-1 mt-1.5 mx-1" aria-hidden="true">
              <span class="pw-bar flex-1 h-1 rounded-full bg-white/10"></span>
              <span class="pw-bar flex-1 h-1 rounded-full bg-white/10"></span>
              <span class="pw-bar flex-1 h-1 rounded-full bg-white/10"></span>
              <span class="pw-bar flex-1 h-1 rounded-full bg-white/10"></span>
            </div>
          </div>

          <div>
            <label for="repassword" class="block text-xs font-bold text-slate-200 mb-1.5 mr-1">{$translate->get('ConfirmPass')}</label>
            <div class="glass-input rounded-2xl flex items-center px-3.5 py-2">
              <span class="w-8 h-8 rounded-xl bg-emerald-500/20 flex items-center justify-center text-emerald-400 ml-2.5 flex-shrink-0" aria-hidden="true">
                <i class="fa-solid fa-shield-check text-sm"></i>
              </span>
              <input id="repassword" name="repassword" type="password" dir="ltr" autocomplete="new-password" placeholder="••••••••" required
                     class="w-full text-base lg:text-sm text-white placeholder-slate-400 font-latin tracking-wider">
            </div>
          </div>

          {if $Config['hcaptcha_secrete'] != null && $Config['hcaptcha_key'] != null && $Config['enable_captcha'] == "1"}
          <div class="flex justify-center"><div class="h-captcha" data-sitekey="{$Config['hcaptcha_key']}" data-theme="dark"></div></div>
          {/if}
          {if $Config['turnstile_secrete'] != null && $Config['turnstile_key'] != null && $Config['enable_captcha'] == "2"}
          <div class="flex justify-center"><div class="cf-turnstile" data-sitekey="{$Config['turnstile_key']}" data-theme="dark"></div></div>
          {/if}

          <p id="formMsg" class="form-msg hidden text-xs px-1 m-0" role="alert"></p>

          <button type="submit" id="sign-up"
                  class="btn-shimmer btn-submit w-full py-3 px-5 rounded-2xl border border-white/20 bg-gradient-to-r from-violet-600 via-fuchsia-500 to-pink-500 hover:from-violet-700 hover:via-fuchsia-600 hover:to-pink-600 text-white font-bold text-sm lg:text-base flex items-center justify-center gap-2 shadow-lg shadow-purple-500/35 active:scale-[0.98] transition duration-200 cursor-pointer">
            <span class="spin" aria-hidden="true"></span>
            <span>ساخت حساب و ورود به پنل</span>
            <i class="fa-solid fa-arrow-left" aria-hidden="true"></i>
          </button>

          <p class="text-[11px] text-emerald-400 flex items-center justify-center gap-1 font-bold m-0">
            <i class="fa-solid fa-shield-check" aria-hidden="true"></i> اطلاعات شما با اتصال امن SSL منتقل می‌شود
          </p>
        </form>

        <p class="text-center text-xs text-slate-400 mt-4 mb-0">
          قبلاً ثبت‌نام کرده‌اید؟
          <a href="/login" class="font-bold text-pink-400 hover:text-pink-300 no-underline">وارد شوید</a>
        </p>

        <ul class="lg:hidden mt-4 pt-4 border-t border-white/10 grid grid-cols-2 gap-2 list-none p-0 text-[11px] font-bold text-slate-300">
          <li class="flex items-center gap-1.5"><span aria-hidden="true">⚡</span> فعال‌سازی فوری</li>
          <li class="flex items-center gap-1.5"><span aria-hidden="true">🌍</span> سرور در چند کشور</li>
          <li class="flex items-center gap-1.5"><span aria-hidden="true">📱</span> همه دستگاه‌ها</li>
          <li class="flex items-center gap-1.5"><span aria-hidden="true">💰</span> درآمد از دعوت</li>
        </ul>
      </div>
    </section>

    <section class="hidden lg:flex lg:col-span-7 order-2 flex-col gap-4 lg:justify-between lg:h-full lg:max-h-[calc(100dvh-145px)] py-1">
      <div class="flex items-center justify-between gap-4">
        <div>
          <div class="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-gradient-to-r from-violet-600/30 to-pink-600/30 border border-violet-400/30 text-violet-200 text-xs font-bold mb-2">
            <span class="text-sm" aria-hidden="true">✨</span>
            <span>چرا Digitsell Shop؟</span>
          </div>
          <h2 class="text-3xl font-black tracking-tight leading-tight m-0">
            <span class="text-white">اینترنت آزاد،</span>
            <span class="grad-title text-transparent bg-clip-text bg-gradient-to-r from-cyan-400 via-fuchsia-400 to-amber-300">بدون دردسر</span>
          </h2>
          <p class="text-sm text-slate-300 mt-1 mb-0 max-w-xl leading-relaxed">
            حساب بسازید، پلن دلخواهتان را بخرید و در کمتر از یک دقیقه وصل شوید.
          </p>
        </div>
        <div class="flex flex-col items-center justify-center p-3 rounded-2xl bg-white/5 border border-white/10 flex-shrink-0 anim-float" aria-hidden="true">
          <div class="w-14 h-14 rounded-2xl bg-gradient-to-tr from-cyan-500 via-blue-600 to-indigo-600 flex items-center justify-center text-3xl shadow-xl shadow-cyan-500/30">🛡️</div>
          <span class="text-[10px] font-bold text-cyan-300 mt-1.5 font-latin">99.9% Uptime</span>
        </div>
      </div>

      <ul class="space-y-2 list-none p-0 m-0">
        <li class="feature-card rounded-2xl p-3 flex items-center gap-3.5">
          <div class="w-12 h-12 rounded-2xl bg-gradient-to-tr from-amber-400 via-orange-500 to-red-500 flex items-center justify-center text-2xl shadow-lg shadow-orange-500/35 flex-shrink-0" aria-hidden="true">⚡</div>
          <div class="flex-1 min-w-0">
            <div class="flex items-center justify-between gap-2">
              <h3 class="text-sm font-bold text-white m-0">فعال‌سازی فوری، بدون معطلی</h3>
              <span class="text-[10px] px-2 py-0.5 rounded-md bg-emerald-500/20 text-emerald-300 border border-emerald-500/30 font-bold whitespace-nowrap">چند ثانیه</span>
            </div>
            <p class="text-xs text-slate-300 mt-0.5 mb-0">بعد از پرداخت، اشتراک در چند ثانیه آماده است؛ نه منتظر ماندن، نه پیام دادن.</p>
          </div>
        </li>
        <li class="feature-card rounded-2xl p-3 flex items-center gap-3.5">
          <div class="w-12 h-12 rounded-2xl bg-gradient-to-tr from-cyan-500 via-blue-600 to-indigo-600 flex items-center justify-center text-2xl shadow-lg shadow-cyan-500/30 flex-shrink-0" aria-hidden="true">🌍</div>
          <div class="flex-1 min-w-0">
            <div class="flex items-center justify-between gap-2">
              <h3 class="text-sm font-bold text-white m-0">سرورهای پرسرعت در چند کشور</h3>
              <span class="text-[10px] px-2 py-0.5 rounded-md bg-cyan-500/20 text-cyan-300 border border-cyan-500/30 font-bold whitespace-nowrap">پینگ پایین</span>
            </div>
            <p class="text-xs text-slate-300 mt-0.5 mb-0">اتصال پایدار روی همه اپراتورهای همراه و اینترنت ثابت.</p>
          </div>
        </li>
        <li class="feature-card rounded-2xl p-3 flex items-center gap-3.5">
          <div class="w-12 h-12 rounded-2xl bg-gradient-to-tr from-emerald-400 via-teal-500 to-cyan-600 flex items-center justify-center text-2xl shadow-lg shadow-teal-500/35 flex-shrink-0" aria-hidden="true">📱</div>
          <div class="flex-1 min-w-0">
            <div class="flex items-center justify-between gap-2">
              <h3 class="text-sm font-bold text-white m-0">یک اشتراک، همه دستگاه‌ها</h3>
              <span class="text-[10px] px-2 py-0.5 rounded-md bg-cyan-500/20 text-cyan-300 border border-cyan-500/30 font-bold whitespace-nowrap">همه پلتفرم‌ها</span>
            </div>
            <p class="text-xs text-slate-300 mt-0.5 mb-0">اندروید، آیفون، ویندوز، مک و لینوکس؛ با آموزش قدم‌به‌قدم.</p>
          </div>
        </li>
        <li class="feature-card rounded-2xl p-3 flex items-center gap-3.5">
          <div class="w-12 h-12 rounded-2xl bg-gradient-to-tr from-fuchsia-500 via-purple-600 to-indigo-600 flex items-center justify-center text-2xl shadow-lg shadow-purple-500/35 flex-shrink-0" aria-hidden="true">💰</div>
          <div class="flex-1 min-w-0">
            <div class="flex items-center justify-between gap-2">
              <h3 class="text-sm font-bold text-white m-0">کسب درآمد با دعوت دوستان</h3>
              <span class="text-[10px] px-2 py-0.5 rounded-md bg-purple-500/20 text-purple-300 border border-purple-500/30 font-bold whitespace-nowrap">پورسانت</span>
            </div>
            <p class="text-xs text-slate-300 mt-0.5 mb-0">از هر خرید دوستانی که دعوت کرده‌اید پورسانت می‌گیرید و به کیف پولتان اضافه می‌شود.</p>
          </div>
        </li>
        <li class="feature-card rounded-2xl p-3 flex items-center gap-3.5">
          <div class="w-12 h-12 rounded-2xl bg-gradient-to-tr from-pink-500 via-rose-500 to-amber-500 flex items-center justify-center text-2xl shadow-lg shadow-pink-500/35 flex-shrink-0" aria-hidden="true">🛟</div>
          <div class="flex-1 min-w-0">
            <div class="flex items-center justify-between gap-2">
              <h3 class="text-sm font-bold text-white m-0">پشتیبانی واقعی و سریع</h3>
              <span class="text-[10px] px-2 py-0.5 rounded-md bg-pink-500/20 text-pink-300 border border-pink-500/30 font-bold whitespace-nowrap">تیکت + تلگرام</span>
            </div>
            <p class="text-xs text-slate-300 mt-0.5 mb-0">تیکت داخل پنل و پشتیبانی تلگرام؛ سؤالتان بی‌جواب نمی‌ماند.</p>
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
    var repass = document.getElementById('repassword');
    var code = document.getElementById('emailcode');
    var toggle = document.getElementById('togglePassword');
    var btn = document.getElementById('sign-up');
    var msg = document.getElementById('formMsg');
    var bars = document.querySelectorAll('.pw-bar');
    var aff = new URLSearchParams(location.search).get('aff') || '';
    if (aff) document.getElementById('affNote').classList.remove('hidden');

    function say(text, ok) {
      msg.textContent = text || '';
      msg.className = 'form-msg text-xs px-1 m-0 ' + (ok ? 'ok' : 'err') + (text ? '' : ' hidden');
    }
    function busy(on) { btn.disabled = on; }

    toggle.addEventListener('click', function () {
      var show = pass.type === 'password';
      pass.type = repass.type = show ? 'text' : 'password';
      toggle.setAttribute('aria-pressed', String(show));
      toggle.setAttribute('aria-label', show ? 'پنهان کردن رمز' : 'نمایش رمز');
      var icon = toggle.querySelector('i');
      icon.classList.toggle('fa-eye', !show);
      icon.classList.toggle('fa-eye-slash', show);
    });

    pass.addEventListener('input', function () {
      var v = pass.value, s = 0;
      if (v.length >= 8) s++;
      if (/[a-z]/.test(v) && /[A-Z]/.test(v)) s++;
      if (/\d/.test(v)) s++;
      if (/[^A-Za-z0-9]/.test(v)) s++;
      if (v && !s) s = 1;
      var colors = ['#fb7185', '#f59e0b', '#22d3ee', '#34d399'];
      for (var i = 0; i < bars.length; i++) bars[i].style.background = i < s ? colors[s - 1] : '';
    });

    function post(url, body) {
      return fetch(url, {
        method: 'POST',
        credentials: 'same-origin',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8', 'X-Requested-With': 'XMLHttpRequest' },
        body: body.toString()
      }).then(function (r) {
        return r.text().then(function (t) {
          try { return JSON.parse(t); } catch (err) { throw new Error(t || ('HTTP ' + r.status)); }
        });
      });
    }

    form.addEventListener('submit', function (e) {
      e.preventDefault();
      var em = email.value.trim();
      if (!em || !pass.value || !repass.value) {
        say('لطفاً ایمیل و کلمه عبور را کامل وارد کنید.', false);
        (!em ? email : (!pass.value ? pass : repass)).focus();
        return;
      }
      if (pass.value !== repass.value) {
        say('رمز عبور و تکرار آن یکسان نیستند.', false);
        repass.focus();
        return;
      }
      var body = new URLSearchParams();
      body.append('email', em);
      body.append('passwd', pass.value);
      body.append('repasswd', repass.value);
      body.append('emailcode', code.value.trim());
      body.append('aff', aff);
      if (document.querySelector('.h-captcha') && window.hcaptcha) body.append('hcaptcha', window.hcaptcha.getResponse());
      if (document.querySelector('.cf-turnstile') && window.turnstile) body.append('turnstile', window.turnstile.getResponse());

      say('', true);
      busy(true);
      post('/register', body).then(function (data) {
        if (data.ret == 1) {
          say(data.msg, true);
          setTimeout(function () { location.href = '/portal/dashboard'; }, 800);
        } else {
          say(data.msg || 'ثبت‌نام ناموفق بود.', false);
          busy(false);
          if (window.hcaptcha && document.querySelector('.h-captcha')) window.hcaptcha.reset();
          if (window.turnstile && document.querySelector('.cf-turnstile')) window.turnstile.reset();
        }
      }).catch(function () {
        say('خطا در اتصال به سرور. دوباره تلاش کنید.', false);
        busy(false);
      });
    });
  })();
  </script>
{/literal}
</body>
</html>
