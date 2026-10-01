[English](README.md) | **فارسی**

<div dir="rtl" align="right">

# نود Xray — بک‌اند مستقل Xray برای پنل XMPlus

جایگزین باینری نود XMPlus: **Xray-core رسمی و جدیدترین نسخه** (از XTLS/Xray-core) به‌اضافهٔ یک
ایجنت کوچک که با API نود پنل حرف می‌زند. پنل نیازی به هیچ تغییری ندارد؛ سرورها مثل قبل در پنل
تعریف و ویرایش می‌شوند و این نود تنظیماتشان را خودش می‌گیرد.

| | نود XMPlus | این نود |
|---|---|---|
| هستهٔ Xray | فورک XMPlus، هر وقت آن‌ها به‌روز کنند | رسمی؛ `digitsell-xray update` همیشه آخرین نسخه |
| XHTTP (`mode` و تنظیمات اضافه) | `mode` خوانده نمی‌شود (باگ) | کامل؛ هر کلید xhttp در تنظیمات شبکهٔ پنل |
| اضافه / حذف کاربر | بدون ری‌استارت | بدون ری‌استارت (API خود Xray) |
| به‌روزرسانی نود | اتصال همه قطع می‌شود | ایجنت جدا از Xray است؛ اتصال کسی قطع نمی‌شود |
| قطع موقت پنل | ترافیک آن مدت گم می‌شود | ترافیک روی دیسک می‌ماند و بعداً گزارش می‌شود |
| ریبوت وقتی پنل در دسترس نیست | نود بالا نمی‌آید | با آخرین تنظیمات و کاربران ذخیره‌شده بالا می‌آید |
| محدودیت دستگاه (IP limit) | دارد | دارد (IP اضافه به blackhole می‌رود) |
| محدودیت سرعت | دارد | **ندارد** — Xray رسمی محدودیت سرعت برای هر کاربر ندارد |

## نصب

### نصب خودکار (سرورهایی که الان XMPlus دارند)

بدون هیچ گزینه‌ای:

<div dir="ltr" align="left">

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/m0000hamad/xmplus-digitsell-patch/main/node/xray/install.sh)
```

</div>

نصب‌کننده این کارها را انجام می‌دهد:

1. فایل `config.yml` نود XMPlus را پیدا می‌کند (`/etc/XMPlus/config.yml` یا `/root/config.yml`)
   و از آن آدرس پنل، ApiKey، شمارهٔ نودها، ایمیل و DNS provider گواهی، fallbackها، فایل rulelist
   و ConnectionConfig را برمی‌دارد؛
2. گواهی‌های Let's Encrypt همان XMPlus را استفاده می‌کند (دوباره صادر نمی‌شود)؛
3. آخرین Xray و lego را دانلود و checksum را بررسی می‌کند؛
4. XMPlus را **متوقف و غیرفعال** می‌کند (پاک نمی‌کند؛ بخش «برگشتن به XMPlus» را ببینید)؛
5. BBR و تنظیمات شبکه را روشن می‌کند (جای `bbr.sh`، بدون تغییر کرنل)؛
6. تنظیمات هر نود را از پنل می‌گیرد، خلاصه‌اش را چاپ می‌کند و اگر پورتی در ufw بسته بود باز می‌کند.

### نصب دستی (سرور تازه)

<div dir="ltr" align="left">

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/m0000hamad/xmplus-digitsell-patch/main/node/xray/install.sh) \
  --panel https://origin.example.com --key <ApiKey> --node 74
```

</div>

- `--key` همان `ApiKey` در config.yml نود XMPlus است (کلید API پنل).
- چند نود روی یک سرور: `--node 74 --node 75` یا `--node 74,75`.
- گواهی با DNS (مثلاً Cloudflare؛ پشت CDN بهترین حالت است):
  `--email you@example.com --dns-provider cloudflare --dns-env CF_DNS_API_TOKEN=xxxx`
  (نام provider و متغیرها همان نام‌های lego است: `lego dnshelp`؛ همان چیزی که در config.yml XMPlus بود).
- `--keep-xmplus`: XMPlus را متوقف نمی‌کند (فقط اگر پورت‌ها فرق دارند).
- `--no-bbr`: به sysctl دست نمی‌زند.
- `--xray-version v26.9.30`: نسخهٔ مشخص.

اجرای دوبارهٔ نصب‌کننده امن است: `agent.json` ادغام می‌شود، جایگزین نمی‌شود.

### دستورها

<div dir="ltr" align="left">

```bash
digitsell-xray status     # نودها، تعداد کاربر، آنلاین‌ها، گواهی، آخرین گزارش ترافیک
digitsell-xray log        # لاگ زنده (ایجنت + Xray)
digitsell-xray doctor     # بررسی کامل: سرویس‌ها، API، پنل، پورت‌ها، گواهی، DNS، BBR، ساعت
digitsell-xray check      # تنظیمات هر نود از پنل + هشدارها
digitsell-xray update     # آخرین Xray / geo / lego / ایجنت (تنظیمات می‌ماند)
digitsell-xray config     # ویرایش agent.json و ری‌استارت
digitsell-xray render     # نمایش کانفیگ Xray که ساخته می‌شود
digitsell-xray uninstall  # حذف (--keep-config ، --restore-xmplus)
```

</div>

`dxray` نام کوتاه همین دستور است.

## پروتکل‌ها و تنظیمات پیشنهادی در پنل

همه‌چیز در پنل ← سرورها ← ویرایش سرور، بخش «تنظیمات شبکه» و «تنظیمات امنیتی» انجام می‌شود.
بعد از ذخیره، نود ظرف یک دقیقه تنظیمات را می‌گیرد و کاربران فقط اشتراک را به‌روز می‌کنند.

نکته‌هایی که برای همهٔ پروفایل‌ها صدق می‌کنند:

- **`allowInsecure` را خاموش کنید.** در Xray جدید حذف شده و اپ‌هایی که هستهٔ جدید دارند لینکی را
  که `allowInsecure=1` دارد وصل نمی‌کنند. با گواهی واقعی (Let's Encrypt یا گواهی CDN) لازم هم نیست.
- هشدار «deprecated» مربوط به WebSocket در لاگ خطا نیست؛ فقط یادآوری است که WS منسوخ‌شده و
  جانشینش XHTTP است (WS هنوز پشتیبانی می‌شود).

### ۱. VLESS + XHTTP + TLS پشت CDN (پیشنهاد اصلی؛ جایگزین WS)

نوع سرور: VLESS · پورت: `443` (یا یکی از پورت‌های HTTPS کلادفلر: 2053، 2083، 2087، 2096، 8443) ·
امنیت: tls · حالت گواهی: `dns` (بهترین حالت پشت CDN) یا `http`

تنظیمات شبکه:

<div dir="ltr" align="left">

```json
{
  "transport": "xhttp",
  "acceptProxyProtocol": false,
  "path": "/openai",
  "host": "s1.example.com",
  "mode": "auto",
  "cdn_host": "chatgpt.com"
}
```

</div>

تنظیمات امنیتی:

<div dir="ltr" align="left">

```json
{
  "serverName": "s1.example.com",
  "rejectUnknownSni": false,
  "allowInsecure": false,
  "fingerprint": "chrome",
  "flow": "none"
}
```

</div>

- کلادفلر: رکورد DNS نارنجی (Proxied) و SSL/TLS روی **Full (strict)** (با گواهی self-signed فقط **Full**).
- `mode: auto` برای CDN مناسب است. اگر CDN درخواست‌ها را بافر می‌کند و کند است، `"mode": "packet-up"` را امتحان کنید.
- `?ed=2560` را نگذارید (فقط برای WebSocket است).
- اپ‌های قدیمی بدون XHTTP (هستهٔ قبل از ۲۰۲۵) وصل نمی‌شوند؛ برای آن‌ها پروفایل ۵ را روی نود
  یا پورت دیگری نگه دارید.

### ۲. VLESS + XHTTP + TLS مستقیم (بدون CDN)

مثل پروفایل ۱، با رکورد DNS خاکستری (DNS only)، حالت گواهی `http` (پورت 80 باید آزاد باشد) یا `dns`،
و بدون `cdn_host`.

### ۳. VLESS + REALITY + Vision (سریع‌ترین؛ بدون دامنه و گواهی)

نوع سرور: VLESS · پورت: `443` · امنیت: reality

کلید بسازید (PrivateKey را در پنل بگذارید؛ Password/PublicKey برای لینک‌هاست):

<div dir="ltr" align="left">

```bash
/usr/local/lib/digitsell-xray/xray x25519
```

</div>

تنظیمات شبکه:

<div dir="ltr" align="left">

```json
{
  "transport": "tcp",
  "acceptProxyProtocol": false,
  "flow": "xtls-rprx-vision",
  "header": { "type": "none" }
}
```

</div>

تنظیمات امنیتی:

<div dir="ltr" align="left">

```json
{
  "show": false,
  "dest": "www.example-site.com:443",
  "serverNames": ["www.example-site.com"],
  "privatekey": "<PrivateKey>",
  "publickey": "<Password (PublicKey)>",
  "shortids": ["", "a1b2c3d4"],
  "fingerprint": "chrome",
  "flow": "xtls-rprx-vision"
}
```

</div>

- `dest` و `serverNames`: یک سایت خارجی با TLS 1.3 و HTTP/2 که در ایران فیلتر نیست و
  ترجیحاً در همان دیتاسنتر یا کشور سرور شماست. دربارهٔ سایت‌های خیلی معروف (microsoft، apple)
  خود Xray هشدار می‌دهد که خطر بلاک شدن IP را بالا می‌برند.
- نود به `publickey` نیازی ندارد؛ پنل برای ساختن لینک‌ها از آن استفاده می‌کند.
- پشت CDN کار نمی‌کند (REALITY مستقیم است).

### ۴. VLESS + XHTTP + REALITY

مثل پروفایل ۳، ولی با تنظیمات شبکهٔ XHTTP:

<div dir="ltr" align="left">

```json
{
  "transport": "xhttp",
  "acceptProxyProtocol": false,
  "path": "/api/v2",
  "mode": "auto"
}
```

</div>

تنظیمات امنیتی مثل پروفایل ۳، فقط با `"flow": "none"`.

### ۵. VMess / VLESS + WebSocket + TLS (قدیمی، هنوز کار می‌کند)

همان تنظیمات فعلی شما، فقط `allowInsecure` را `false` کنید:

<div dir="ltr" align="left">

```json
{
  "transport": "ws",
  "acceptProxyProtocol": false,
  "path": "/openai?ed=2560",
  "host": "s1.example.com",
  "heartbeatperiod": 10,
  "cdn_host": "chatgpt.com"
}
```

</div>

تنظیمات امنیتی مثل پروفایل ۱.

### ۶. Shadowsocks 2022

نوع سرور: Shadowsocks · روش: `2022-blake3-aes-128-gcm` · شبکه: `{"transport": "tcp"}` ·
امنیت: none · کلید سرور (server_key) در پنل: خروجی `openssl rand -base64 16`
(برای `aes-256` و `chacha20`: `openssl rand -base64 32`).

### تنظیمات اضافهٔ XHTTP

هر کدام از این کلیدها را می‌شود در «تنظیمات شبکه»ی پنل گذاشت و نود عیناً به Xray می‌دهد:
`mode` (`auto` / `packet-up` / `stream-up` / `stream-one`)، `xPaddingBytes`، `noSSEHeader`،
`scMaxEachPostBytes`، `scMaxBufferedPosts`، `scStreamUpServerSecs`، `serverMaxHeaderBytes`،
`headers`، `extra` و بقیهٔ کلیدهای xhttpSettings در
[مستندات Xray](https://xtls.github.io/config/transports/xhttp.html).

## عبور مستقیم برای ایران و سایت‌های منتخب (بای‌پس)

پنل ← سرورها ← سرورهای OpenVPN ← **عبور مستقیم** ← تیک **«برای کاربران Xray (V2Ray) هم اعمال
شود — اپ Happ»** (پچ 1.17.0).

همان فهرست OpenVPN (آی‌پی‌ها و دامنه‌های ایران + مقصدهای دلخواه شما) در لینک اشتراک برای اپ
**Happ** فرستاده می‌شود و Happ این مقصدها را مستقیم (بدون عبور از سرور) باز می‌کند. کاربر فقط
اشتراک را به‌روز می‌کند. برداشتن تیک، پروفایل را از Happ کاربران هم خاموش می‌کند.

چرا فقط Happ، و چرا در پنل نه روی سرور: در Xray تصمیم اینکه چه چیزی از سرور رد نشود با
**اپ کاربر** است؛ وقتی ترافیک به سرور برسد دیگر دیر است. از اپ‌های رایج فقط Happ مسیریابی را از
لینک اشتراک می‌گیرد. در v2rayNG / V2Box / Shadowrocket کاربر باید خودش گزینهٔ مسیریابی «ایران مستقیم»
(Bypass Iran) اپ را روشن کند. این روش برای لینک‌هایی کار می‌کند که از
`xmplus-patch.php?do=sub` می‌آیند (همان لینک «اطلاعات اشتراک در اپ‌ها»).

## agent.json

`/etc/digitsell-xray/agent.json` را نصب‌کننده می‌نویسد؛ با `digitsell-xray config` ویرایشش کنید.

| کلید | پیش‌فرض | معنی |
|---|---|---|
| `panel` | — | آدرس پنل (آدرسی که پشت CDN نیست، مثلاً `https://origin.example.com`) |
| `key` | — | ApiKey پنل |
| `nodes` | — | شمارهٔ نودها: `[74, 75]`، یا شیء برای تنظیم جدا: `{"id": 74, "panel": "...", "key": "...", "cert_file": "...", "key_file": "...", "fallbacks": [...]}` |
| `interval` | `60` | هر چند ثانیه از پنل بپرسد و ترافیک را گزارش کند |
| `limit_interval` | `15` | هر چند ثانیه محدودیت دستگاه بررسی شود |
| `ip_limit` | `true` | اجرای محدودیت دستگاه پنل |
| `block_private` | `true` | کاربران به IPهای داخلی / LAN سرور نرسند |
| `block_bittorrent` | `false` | بستن تورنت |
| `block_regex_file` | — | فایل regex دامنه‌های بسته، یکی در هر خط (مثل rulelist در XMPlus). قانون‌های «rules» پنل هم خودکار اعمال می‌شوند |
| `domain_strategy` | `AsIs` | freedom: `AsIs`، `UseIP`، `UseIPv4`، `UseIPv6` |
| `dns` | — | شیء `dns` خود Xray، عیناً |
| `policy` | — | `handshake`، `connIdle`، `uplinkOnly`، `downlinkOnly`، `bufferSize` |
| `log_level` | `warning` | `debug`، `info`، `warning`، `error`، `none` |
| `access_log` | — | مسیر فایل لاگ اتصال‌ها (به‌طور پیش‌فرض خاموش) |
| `trusted_xff` | `["CF-Connecting-IP", "X-Real-IP", "True-Client-IP"]` | پشت CDN: اگر یکی از این هدرها (که CDN می‌گذارد) باشد، IP واقعی کاربر از `X-Forwarded-For` خوانده می‌شود؛ بدون آن همهٔ کاربران IP خود CDN را دارند و محدودیت دستگاه غلط کار می‌کند. `[]` یعنی خاموش |
| `api` | `127.0.0.1:10085` | API داخلی Xray |
| `cert.email` | — | ایمیل Let's Encrypt |
| `cert.provider` / `cert.env` | — | DNS provider و کلیدهایش برای حالت گواهی `dns` (نام‌های lego) |
| `cert.file` / `cert.key` | — | گواهی آماده برای حالت `file` (یا `/etc/digitsell-xray/certs/<domain>.crt` و `.key`) |

## چطور کار می‌کند

- **دو سرویس:** `digitsell-xray` (خود Xray رسمی) و `digitsell-xray-agent` (ایجنت پایتون، فقط
  با کتابخانهٔ استاندارد). ری‌استارت یا آپدیت ایجنت اتصال هیچ کاربری را قطع نمی‌کند.
- **تنظیمات نود** از `GET /api/server/<id>` پنل گرفته می‌شود، با ETag (فقط وقتی عوض شده). Xray
  فقط وقتی تنظیمات نود عوض شود ری‌استارت می‌شود؛ کانفیگ جدید قبلش با `xray run -test` امتحان
  می‌شود و اگر Xray قبولش نکند، نود با تنظیمات قبلی می‌ماند و خطا در `status` دیده می‌شود.
- **کاربران** از `GET /api/subscriptions/<id>` می‌آیند؛ اضافه و حذف با `xray api adu` / `rmu`
  و بدون ری‌استارت.
- **ترافیک** هر دقیقه از شمارنده‌های Xray خوانده و صفر می‌شود و به `POST /api/traffic/<id>`
  می‌رود؛ اگر پنل جواب ندهد روی دیسک می‌ماند و با گزارش بعدی فرستاده می‌شود.
- **آنلاین‌ها** به `POST /api/onlineip/<id>` می‌روند. پشت CDN، IP واقعی کاربر از `X-Forwarded-For`
  خوانده می‌شود (Xray جدید فقط وقتی قبولش می‌کند که هدر CDN مثل `CF-Connecting-IP` هم باشد؛
  همان `trusted_xff`).
- **محدودیت دستگاه** مثل XMPlus: `iplimit - ipcount + (IPهای همین نود در گزارش قبل)`. حسابی که
  جای خالی ندارد اصلاً روی این نود بالا نمی‌آید و IPهای بیشتر از سهم این نود با یک rule به
  blackhole می‌روند. IPی که جا گرفته تا ۲ دقیقه بعد از بسته شدن آخرین اتصالش جایش را نگه می‌دارد.
- **گواهی** با lego صادر می‌شود (حالت‌های `http`، `tls`، `dns` پنل) و ۳۰ روز مانده به انقضا تمدید
  می‌شود؛ Xray فایل گواهی را هر ساعت خودش دوباره می‌خواند (بدون ری‌استارت). تا گواهی واقعی گرفته
  نشده، یک گواهی self-signed گذاشته می‌شود تا نود بالا بیاید (پشت CDN در حالت Full کار می‌کند)
  و هر ۱۰ دقیقه دوباره تلاش می‌شود.
- **Relay** (زنجیره به نود دیگر) و **sendthrough** پنل پشتیبانی می‌شوند.

## برگشتن به XMPlus

<div dir="ltr" align="left">

```bash
digitsell-xray uninstall --restore-xmplus
```

</div>

یا بدون حذف: `systemctl disable --now digitsell-xray digitsell-xray-agent && systemctl enable --now XMPlus`.

## عیب‌یابی

### بعد از گذاشتن نود xhttp، آپدیت اشتراک یا صفحهٔ «سرورها» (/portal/servers) «Internal Server Error» می‌دهد

این باگ **خود پنل** است، نه نود. سازنده‌های لینک پنل (در `app/Http/Schema/`: فایل `Xray.php` برای
لینک اشتراک و `VlessURI.php` و هم‌خانواده‌ها برای صفحهٔ سرورها) کلیدهایی مثل `headerType` و `alpn`
را بدون بررسی می‌خوانند، و برای xhttp کنترلر آن‌ها را نمی‌فرستد. Whoops هشدار PHP را به خطای کشنده
تبدیل می‌کند و اشتراک **همهٔ** اکانت‌هایی که آن نود را می‌بینند خراب می‌شود. پیام خطا:
`Undefined index: headerType` در `Xray.php:85` (اشتراک) یا `VlessURI.php:12` (صفحهٔ سرورها).
برای دیدن پیام واقعی (روی سرور پنل):

<div dir="ltr" align="left">

```bash
curl -sk --resolve <دامنه‌ی پنل>:443:127.0.0.1 "https://<دامنه‌ی پنل>/link/<توکن>?config=1" -o /tmp/err.html
python3 -c "import re,html;t=open('/tmp/err.html',errors='ignore').read();t=re.sub(r'(?s)<(style|script).*?</\1>','',t);t=re.sub(r'<[^>]+>','\n',t);print('\n'.join(l.strip() for l in html.unescape(t).splitlines() if l.strip())[:700])"
```

</div>

**از پچ 1.17.1 به بعد لازم نیست کاری بکنید:** پچ این فایل‌ها را موقع نصب اصلاح می‌کند و هر ساعت
بررسی می‌کند (خروجی در `storage/logs/schemafix.log` و فقط وقتی چیزی عوض شود). اگر به‌روزرسانی خود
پنل فایل‌ها را به حالت اول برگرداند، ظرف یک ساعت دوباره اصلاح می‌شوند. فقط نسخهٔ 1.17.1 یا بالاتر
را در «تنظیمات ← به‌روزرسانی پچ» نصب کنید. اسکریپت زیر برای پنلی است که پچ ندارد، یا اگر
نمی‌خواهید یک ساعت صبر کنید.

راه‌حل دستی (یک بار، روی **سرور پنل**): همهٔ فایل‌های `app/Http/Schema/` را بررسی می‌کند و فقط
جایی که لازم است دست می‌زند؛ از هر فایل پشتیبان می‌گیرد، syntax را می‌سنجد و در صورت خطا
برمی‌گرداند:

<div dir="ltr" align="left">

```bash
curl -fsSL https://raw.githubusercontent.com/m0000hamad/xmplus-digitsell-patch/main/node/xray/fix-panel-xhttp.py | python3 - /www/wwwroot/panel.example.com
```

</div>

بعد نود xhttp را فعال کنید و همان `curl` بالا را دوباره بزنید؛ باید `200` بدهد. اگر ۵۰۰ ماند،
نود را فوراً غیرفعال کنید و پیام خطا را بفرستید. این اصلاح با هر به‌روزرسانی پنل که `Xray.php`
را عوض کند از بین می‌رود؛ دوباره اجرا کنید. (غیرفعال کردن هر نودی که ۵۰۰ می‌دهد اشتراک را
فوراً برمی‌گرداند.)

### نود بالاست ولی «0 آنلاین» است و مصرفی گزارش نمی‌شود

<div dir="ltr" align="left">

```bash
ss -tn state established '( sport = :PORT )'     # اگر خالی است، کسی به این سرور نمی‌رسد
ss -ltnp | grep ':PORT '                         # باید xray باشد، نه XMPlus
systemctl is-active XMPlus xmplus                # هر دو باید inactive باشند
echo | openssl s_client -connect 127.0.0.1:PORT -servername دامنه 2>/dev/null | openssl x509 -noout -subject -dates
```

</div>

اگر هیچ اتصالی برقرار نیست، مشکل مسیر است نه نود: رکورد DNS دامنه به IP این سرور (یا به CDN
با origin درست) نمی‌رود. `dxray doctor` فقط می‌گوید «چیزی روی پورت گوش می‌دهد» و نمی‌گوید چه چیزی.

### چیزهای عادی در لاگ

- `node N: +2 -0 account(s)` هر دقیقه: محدودیت دستگاه پنل (اکانتی که روی نودهای دیگر به سقف
  رسیده کنار گذاشته می‌شود).
- `starting Xray: ...` بعد از تغییر تنظیمات نود در پنل؛ اتصال‌ها دوباره برقرار می‌شوند.
- `TLS handshake error ... i/o timeout` و `client sent an HTTP request to an HTTPS server`:
  اسکنرهای اینترنتی‌اند.
- نصب‌کننده نسخهٔ Xray را از «latest release» گیت‌هاب می‌گیرد (ممکن است از جدیدترین پیش‌انتشار
  عقب‌تر باشد): `dxray update --xray-version v26.9.30`.
- گواهی‌ای که خودتان به‌صورت فایل داده‌اید (حالت `file`) تمدید نمی‌شود؛ `dxray status` روزهای
  باقی‌مانده را نشان می‌دهد.

## محدودیت‌ها

- محدودیت سرعت پنل (speedlimit) اعمال نمی‌شود؛ `check` برای نودی که دارد هشدار می‌دهد.
- mKCP با `seed` / `header`: Xray جدید این‌ها را به finalmask برده؛ کلاینت‌هایی که seed دارند وصل
  نمی‌شوند.
- HTTP/2 و QUIC به‌عنوان transport از Xray حذف شده‌اند؛ `check` این را می‌گوید و نود بالا
  نمی‌آید. به‌جایش XHTTP بگذارید.
- ایجنت لینک‌های اشتراک را نمی‌سازد؛ پنل می‌سازد. اگر پنل شما XHTTP را در فهرست transport
  ندارد، همان WS (پروفایل ۵) را نگه دارید؛ این نود با آن هم کار می‌کند.

</div>
