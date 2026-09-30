# Xray node (بک‌اند مستقل Xray برای پنل XMPlus)

جایگزین باینری نود XMPlus: **Xray-core رسمی و جدیدترین نسخه** (از XTLS/Xray-core) به‌اضافهٔ یک
ایجنت کوچک که با همان API نودِ پنل حرف می‌زند. پنل هیچ تغییری لازم ندارد؛ سرورها مثل قبل در
پنل تعریف و ویرایش می‌شوند و این نود تنظیماتشان را خودش می‌گیرد.

| | XMPlus node | این نود |
|---|---|---|
| هستهٔ Xray | فورک XMPlus، هر وقت آن‌ها به‌روز کنند | رسمی، `digitsell-xray update` همیشه آخرین نسخه |
| XHTTP (mode و تنظیمات اضافه) | `mode` خوانده نمی‌شود (باگ) | کامل، هر کلید xhttp در تنظیمات شبکهٔ پنل |
| اضافه / حذف کاربر | بی‌ری‌استارت | بی‌ری‌استارت (API خود Xray) |
| به‌روزرسانی نود | اتصال همه قطع می‌شود | ایجنت جدا از Xray است؛ اتصال کسی قطع نمی‌شود |
| قطع موقت پنل | ترافیک آن مدت گم می‌شود | ترافیک روی دیسک می‌ماند و بعداً گزارش می‌شود |
| ریبوت وقتی پنل در دسترس نیست | نود بالا نمی‌آید | با آخرین تنظیمات و کاربران ذخیره‌شده بالا می‌آید |
| محدودیت دستگاه (IP limit) | دارد | دارد (IP اضافه به blackhole می‌رود) |
| محدودیت سرعت | دارد | **ندارد** — Xray رسمی محدودیت سرعت per-user ندارد |

## نصب

### حالت اتوماتیک (سرورهایی که الان XMPlus دارند)

بدون هیچ گزینه‌ای:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/m0000hamad/xmplus-digitsell-patch/main/node/xray/install.sh)
```

نصب‌کننده خودش:

1. `config.yml` نود XMPlus را پیدا می‌کند (`/etc/XMPlus/config.yml`، یا `/root/config.yml`)؛
   آدرس پنل، ApiKey، همهٔ NodeIDها، ایمیل و DNS provider گواهی، fallbackها، فایل rulelist
   و ConnectionConfig را برمی‌دارد؛
2. گواهی‌های Let's Encrypt همان XMPlus را برمی‌دارد (دوباره صادر نمی‌شود)؛
3. آخرین Xray و lego را دانلود و با checksum بررسی می‌کند؛
4. XMPlus را **stop و disable** می‌کند (پاک نمی‌کند — پایین «برگشتن به XMPlus» را ببینید)؛
5. BBR و تنظیمات شبکه را روشن می‌کند (جای `bbr.sh`، بدون عوض کردن کرنل)؛
6. از پنل تنظیمات هر نود را می‌پرسد و خلاصه‌اش را چاپ می‌کند؛ اگر پورتی در ufw بسته باشد باز می‌کند.

### نصب دستی (سرور تازه)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/m0000hamad/xmplus-digitsell-patch/main/node/xray/install.sh) \
  --panel https://my.digitsell-shop.ir --key <ApiKey> --node 74
```

- `--key` همان `ApiKey` در config.yml نود XMPlus است (کلید API پنل).
- چند نود روی یک سرور: `--node 74 --node 75` یا `--node 74,75`.
- گواهی با DNS (مثلاً Cloudflare؛ بهترین حالت پشت CDN):
  `--email you@example.com --dns-provider cloudflare --dns-env CF_DNS_API_TOKEN=xxxx`
  (نام provider و متغیرها همان lego است: `lego dnshelp`؛ همان‌هایی که در config.yml XMPlus بود).
- `--keep-xmplus` XMPlus را متوقف نمی‌کند (فقط اگر پورت‌ها فرق دارند)،
  `--no-bbr` دست به sysctl نمی‌زند، `--xray-version v26.9.30` نسخهٔ خاص.

دوباره اجرا کردنش امن است: `agent.json` ادغام می‌شود، جایگزین نمی‌شود.

### دستورها

```bash
digitsell-xray status     # نودها، تعداد کاربر، آنلاین‌ها، گواهی، آخرین گزارش ترافیک
digitsell-xray log        # لاگ زنده (ایجنت + Xray)
digitsell-xray doctor     # بررسی کامل: سرویس‌ها، API، پنل، پورت‌ها، گواهی، DNS، BBR، ساعت
digitsell-xray check      # تنظیمات هر نود از پنل + هشدارها
digitsell-xray update     # آخرین Xray / geo / lego / ایجنت (تنظیمات می‌ماند)
digitsell-xray config     # ویرایش agent.json و ری‌استارت
digitsell-xray render     # کانفیگ Xray که ساخته می‌شود
digitsell-xray uninstall  # حذف (--keep-config ، --restore-xmplus)
```

`dxray` اسم کوتاه همین دستور است.

## تنظیمات پیشنهادی در پنل

همه در پنل → سرورها → ویرایش سرور، بخش «تنظیمات شبکه» و «تنظیمات امنیتی». بعد از ذخیره،
نود ظرف یک دقیقه تنظیمات را می‌گیرد؛ کاربران فقط اشتراک را به‌روز می‌کنند.

> **درباره هشدار WebSocket در لاگ:** آن خط خطا نیست؛ Xray فقط می‌گوید WebSocket «منسوخ» است و
> جایگزینش XHTTP است (حذف نمی‌شود). با پروفایل ۱ یا ۲ پایین دیگر نمی‌آید.
>
> **`allowInsecure` را خاموش کنید:** در Xray جدید این گزینه **حذف شده** و اپ‌هایی که هستهٔ جدید دارند
> لینکی که `allowInsecure=1` دارد را اصلاً وصل نمی‌کنند. وقتی گواهی واقعی است (Let's Encrypt یا
> گواهی CDN) لازم هم نیست.

### ۱. VLESS + XHTTP + TLS پشت CDN — پیشنهاد اصلی (جایگزین WS فعلی)

نوع سرور: VLESS · پورت: `443` (یا یکی از پورت‌های HTTPS کلادفلر: 2053، 2083، 2087، 2096، 8443) ·
امنیت: tls · حالت گواهی: `dns` (بهترین پشت CDN) یا `http`

تنظیمات شبکه:

```json
{
  "transport": "xhttp",
  "acceptProxyProtocol": false,
  "path": "/openai",
  "host": "s1.dgtshop.ir",
  "mode": "auto",
  "cdn_host": "chatgpt.com"
}
```

تنظیمات امنیتی:

```json
{
  "serverName": "s1.dgtshop.ir",
  "rejectUnknownSni": false,
  "allowInsecure": false,
  "fingerprint": "chrome",
  "flow": "none"
}
```

- `?ed=2560` فقط مال WebSocket است؛ در XHTTP نگذارید.
- کلادفلر: رکورد DNS نارنجی (Proxied)، SSL/TLS روی **Full (strict)** (با گواهی self-signed فقط **Full**).
- `mode: auto` برای CDN درست است (اپ از طریق CDN حالت packet-up را انتخاب می‌کند). اگر CDN شما
  درخواست‌ها را بافر می‌کند و کند است، `"mode": "packet-up"` را امتحان کنید.
- اپ‌های قدیمی که XHTTP ندارند (هستهٔ قبل از ۲۰۲۵) وصل نمی‌شوند؛ اگر هنوز چنین کاربرانی دارید،
  پروفایل ۵ را روی یک نود دیگر (پورت دیگر، مثلاً 8443) نگه دارید.

### ۲. VLESS + XHTTP + TLS مستقیم (بدون CDN)

همان پروفایل ۱ با رکورد DNS خاکستری (DNS only) و حالت گواهی `http` (پورت 80 باید آزاد باشد) یا `dns`.
`cdn_host` را بردارید.

### ۳. VLESS + REALITY + Vision — سریع‌ترین، بدون دامنه و گواهی

نوع: VLESS · پورت: `443` · امنیت: reality

کلید بسازید (خروجی PrivateKey در پنل، Password/PublicKey برای لینک‌ها):

```bash
/usr/local/lib/digitsell-xray/xray x25519
```

تنظیمات شبکه:

```json
{
  "transport": "tcp",
  "acceptProxyProtocol": false,
  "flow": "xtls-rprx-vision",
  "header": { "type": "none" }
}
```

تنظیمات امنیتی:

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

- `dest` / `serverNames`: یک سایت خارجی با TLS 1.3 و HTTP/2 که در ایران فیلتر نیست و
  ترجیحاً در همان دیتاسنتر / کشور سرور شماست. سایت‌های خیلی معروف (microsoft، apple) را
  خود Xray هشدار می‌دهد که ریسک بلاک شدن IP را بالا می‌برند.
- `publickey` را نود لازم ندارد؛ پنل برای ساختن لینک‌ها از آن استفاده می‌کند (اگر فرم پنل فیلد
  جدا برای کلید عمومی دارد همان‌جا بگذارید).
- پشت CDN کار نمی‌کند (REALITY مستقیم است).

### ۴. VLESS + XHTTP + REALITY

مثل پروفایل ۳ ولی با XHTTP (اپ حالت stream-one را انتخاب می‌کند):

```json
{
  "transport": "xhttp",
  "acceptProxyProtocol": false,
  "path": "/api/v2",
  "mode": "auto"
}
```

تنظیمات امنیتی همان پروفایل ۳، با `"flow": "none"`.

### ۵. VMess / VLESS + WebSocket + TLS (قدیمی، هنوز کار می‌کند)

همان تنظیمات فعلی شما — فقط `allowInsecure` را `false` کنید:

```json
{
  "transport": "ws",
  "acceptProxyProtocol": false,
  "path": "/openai?ed=2560",
  "host": "s1.dgtshop.ir",
  "heartbeatperiod": 10,
  "cdn_host": "chatgpt.com"
}
```

```json
{
  "serverName": "s1.dgtshop.ir",
  "rejectUnknownSni": false,
  "allowInsecure": false,
  "fingerprint": "chrome",
  "flow": "none"
}
```

هشدار «deprecated» در لاگ می‌ماند و بی‌خطر است.

### ۶. Shadowsocks 2022

نوع: Shadowsocks · روش: `2022-blake3-aes-128-gcm` · شبکه: `{"transport": "tcp"}` ·
امنیت: none · کلید سرور (server_key) در پنل: خروجی `openssl rand -base64 16`
(برای `aes-256` و `chacha20`: `openssl rand -base64 32`).

### تنظیمات اضافهٔ XHTTP

هر کدام از این کلیدها را می‌شود در «تنظیمات شبکه»ی پنل گذاشت و نود عیناً به Xray می‌دهد:
`mode` (`auto` / `packet-up` / `stream-up` / `stream-one`)، `xPaddingBytes`، `noSSEHeader`،
`scMaxEachPostBytes`، `scMaxBufferedPosts`، `scStreamUpServerSecs`، `serverMaxHeaderBytes`،
`headers`، `extra`، و بقیهٔ کلیدهای xhttpSettings در
[مستندات Xray](https://xtls.github.io/config/transports/xhttp.html).

## عبور مستقیم ایران و سایت‌های منتخب (بای‌پس)

پنل → سرورها → سرورهای OpenVPN → **عبور مستقیم** → تیک **«برای کاربران Xray (V2Ray) هم اعمال
شود — اپ Happ»** (پچ 1.17.0).

همان فهرست OpenVPN (آی‌پی‌ها و دامنه‌های ایران + مقصدهای دلخواه شما) با لینک اشتراک به اپ
**Happ** فرستاده می‌شود و Happ این مقصدها را مستقیم (بدون سرور) باز می‌کند؛ کاربر فقط اشتراک را
به‌روز می‌کند. برداشتن تیک، پروفایل را از Happ کاربران هم خاموش می‌کند.

چرا فقط Happ و چرا در پنل، نه روی سرور: در Xray تصمیم اینکه چه چیزی از سرور رد نشود با
**اپ کاربر** است؛ وقتی ترافیک به سرور رسید دیگر دیر است. از اپ‌های رایج فقط Happ مسیریابی را از
لینک اشتراک می‌گیرد. در v2rayNG / V2Box / Shadowrocket کاربر خودش گزینهٔ مسیریابی «ایران مستقیم»
(Bypass Iran) اپ را روشن می‌کند. این برای لینک‌هایی کار می‌کند که از
`xmplus-patch.php?do=sub` می‌آیند (همان لینک «اطلاعات اشتراک در اپ‌ها»).

## agent.json

`/etc/digitsell-xray/agent.json` — نصب‌کننده می‌نویسد؛ با `digitsell-xray config` ویرایش کنید.

| کلید | پیش‌فرض | معنی |
|---|---|---|
| `panel` | — | آدرس پنل (آدرسی که پشت CDN نیست، مثلاً `https://my.digitsell-shop.ir`) |
| `key` | — | ApiKey پنل |
| `nodes` | — | شمارهٔ نودها: `[74, 75]`، یا شیء برای تنظیم جدا: `{"id": 74, "panel": "...", "key": "...", "cert_file": "...", "key_file": "...", "fallbacks": [...]}` |
| `interval` | `60` | هر چند ثانیه از پنل بپرسد و ترافیک را گزارش کند |
| `limit_interval` | `15` | هر چند ثانیه محدودیت دستگاه بررسی شود |
| `ip_limit` | `true` | اجرای محدودیت دستگاه (iplimit پنل) |
| `block_private` | `true` | کاربران به IPهای داخلی / LAN سرور نرسند |
| `block_bittorrent` | `false` | بستن تورنت |
| `block_regex_file` | — | فایل regex دامنه‌های بسته، یکی در هر خط (مثل rulelist در XMPlus). قانون‌های «rules» پنل هم خودکار اعمال می‌شوند |
| `domain_strategy` | `AsIs` | freedom: `AsIs`، `UseIP`، `UseIPv4`، `UseIPv6` |
| `dns` | — | شیء `dns` خود Xray، عیناً |
| `policy` | — | `handshake`، `connIdle`، `uplinkOnly`، `downlinkOnly`، `bufferSize` |
| `log_level` | `warning` | `debug`، `info`، `warning`، `error`، `none` |
| `access_log` | — | مسیر فایل لاگ اتصال‌ها (خاموش به‌طور پیش‌فرض) |
| `trusted_xff` | `["CF-Connecting-IP", "X-Real-IP", "True-Client-IP"]` | پشت CDN: وقتی یکی از این هدرها (که CDN می‌گذارد) باشد، IP واقعی کاربر از `X-Forwarded-For` خوانده می‌شود؛ بدون آن همهٔ کاربران IP خود CDN را دارند و محدودیت دستگاه غلط کار می‌کند. `[]` خاموش |
| `api` | `127.0.0.1:10085` | API داخلی Xray |
| `cert.email` | — | ایمیل Let's Encrypt |
| `cert.provider` / `cert.env` | — | DNS provider و کلیدهایش برای حالت گواهی `dns` (نام‌های lego) |
| `cert.file` / `cert.key` | — | گواهی آماده برای حالت `file` (یا `/etc/digitsell-xray/certs/<domain>.crt` و `.key`) |

## چطور کار می‌کند

- **دو سرویس:** `digitsell-xray` (خود Xray رسمی) و `digitsell-xray-agent` (ایجنت پایتون، فقط
  کتابخانهٔ استاندارد). ری‌استارت یا آپدیت ایجنت اتصال هیچ کاربری را قطع نمی‌کند.
- **تنظیمات نود** از `GET /api/server/<id>` پنل با ETag (فقط وقتی عوض شده). Xray فقط وقتی
  تنظیمات نود عوض شود ری‌استارت می‌شود؛ قبلش کانفیگ جدید با `xray run -test` امتحان می‌شود و اگر
  Xray قبولش نکند نود با تنظیمات قبلی می‌ماند و خطا در `status` نشان داده می‌شود.
- **کاربران** از `GET /api/subscriptions/<id>`؛ اضافه / حذف با `xray api adu` / `rmu`، بی‌ری‌استارت.
- **ترافیک** هر دقیقه از شمارنده‌های Xray خوانده و صفر می‌شود و به `POST /api/traffic/<id>` می‌رود؛
  اگر پنل جواب ندهد روی دیسک می‌ماند و با گزارش بعدی فرستاده می‌شود.
- **آنلاین‌ها** به `POST /api/onlineip/<id>`. پشت CDN، IP واقعی کاربر از `X-Forwarded-For` خوانده
  می‌شود (Xray جدید فقط وقتی قبولش می‌کند که هدر CDN مثل `CF-Connecting-IP` هم باشد — `trusted_xff`).
- **محدودیت دستگاه** مثل XMPlus: `iplimit - ipcount + (IPهای همین نود در گزارش قبل)`؛ حساب بدون
  جای خالی اصلاً روی این نود نمی‌آید، و IPهای بیشتر از سهم این نود با یک rule به blackhole می‌روند.
  IPی که جا گرفته تا ۲ دقیقه بعد از بسته شدن آخرین اتصالش جایش را نگه می‌دارد.
- **گواهی** با lego (حالت‌های `http`، `tls`، `dns` پنل)، تمدید ۳۰ روز مانده به انقضا؛ Xray فایل
  گواهی را هر ساعت خودش دوباره می‌خواند (بی‌ری‌استارت). تا گواهی واقعی گرفته نشده یک گواهی
  self-signed می‌گذارد تا نود بالا بیاید (پشت CDN در حالت Full کار می‌کند) و هر ۱۰ دقیقه دوباره تلاش می‌کند.
- **Relay** (زنجیره به نود دیگر) و **sendthrough** پنل پشتیبانی می‌شوند.

## برگشتن به XMPlus

```bash
digitsell-xray uninstall --restore-xmplus
```

یا بدون حذف: `systemctl disable --now digitsell-xray digitsell-xray-agent && systemctl enable --now XMPlus`.

## محدودیت‌ها

- محدودیت سرعت (speedlimit پنل) اعمال نمی‌شود؛ `check` برای نودی که دارد هشدار می‌دهد.
- mKCP با `seed` / `header`: Xray جدید این‌ها را به finalmask برده؛ کلاینت‌هایی که seed دارند وصل نمی‌شوند.
- HTTP/2 و QUIC به‌عنوان transport از Xray حذف شده‌اند؛ `check` می‌گوید و نود بالا نمی‌آید — XHTTP بگذارید.
- ایجنت لینک‌های اشتراک را نمی‌سازد؛ آن‌ها را پنل می‌سازد. اگر پنل شما XHTTP را در فهرست transport
  ندارد، همان WS (پروفایل ۵) را نگه دارید — این نود با آن هم کار می‌کند.
