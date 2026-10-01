[English](README.md) | **فارسی**
<h1 dir="rtl">نود Xray — بک‌اند مستقل Xray برای پنل XMPlus</h1>
<p dir="rtl">جایگزین باینری نود XMPlus: <strong>Xray-core رسمی و جدیدترین نسخه</strong> (از XTLS/Xray-core) به‌اضافهٔ یک
ایجنت کوچک که با API نود پنل حرف می‌زند. پنل نیازی به هیچ تغییری ندارد؛ سرورها مثل قبل در پنل
تعریف و ویرایش می‌شوند و این نود تنظیماتشان را خودش می‌گیرد.</p>
<table dir="rtl">
<thead>
<tr>
<th></th>
<th>نود XMPlus</th>
<th>این نود</th>
</tr>
</thead>
<tbody>
<tr>
<td>هستهٔ Xray</td>
<td>فورک XMPlus، هر وقت آن‌ها به‌روز کنند</td>
<td>رسمی؛ <code>digitsell-xray update</code> همیشه آخرین نسخه</td>
</tr>
<tr>
<td>XHTTP (<code>mode</code> و تنظیمات اضافه)</td>
<td><code>mode</code> خوانده نمی‌شود (باگ)</td>
<td>کامل؛ هر کلید xhttp در تنظیمات شبکهٔ پنل</td>
</tr>
<tr>
<td>اضافه / حذف کاربر</td>
<td>بدون ری‌استارت</td>
<td>بدون ری‌استارت (API خود Xray)</td>
</tr>
<tr>
<td>به‌روزرسانی نود</td>
<td>اتصال همه قطع می‌شود</td>
<td>ایجنت جدا از Xray است؛ اتصال کسی قطع نمی‌شود</td>
</tr>
<tr>
<td>قطع موقت پنل</td>
<td>ترافیک آن مدت گم می‌شود</td>
<td>ترافیک روی دیسک می‌ماند و بعداً گزارش می‌شود</td>
</tr>
<tr>
<td>ریبوت وقتی پنل در دسترس نیست</td>
<td>نود بالا نمی‌آید</td>
<td>با آخرین تنظیمات و کاربران ذخیره‌شده بالا می‌آید</td>
</tr>
<tr>
<td>محدودیت دستگاه (IP limit)</td>
<td>دارد</td>
<td>دارد (IP اضافه به blackhole می‌رود)</td>
</tr>
<tr>
<td>محدودیت سرعت</td>
<td>دارد</td>
<td><strong>ندارد</strong> — Xray رسمی محدودیت سرعت برای هر کاربر ندارد</td>
</tr>
</tbody>
</table>
<h2 dir="rtl">نصب</h2>
<h3 dir="rtl">نصب با راهنما (هر سروری)</h3>

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/m0000hamad/xmplus-digitsell-patch/main/node/xray/install.sh)
```

<p dir="rtl">با root و در ترمینال اجرا کنید؛ نصب‌کننده قبل از هر تغییری می‌پرسد:</p>
<ol dir="rtl">
<li><strong>آدرس پنل</strong> (آدرس اصلی، نه پشت CDN) و <strong>کلید API</strong> (همان ApiKey در تنظیمات API پنل؛ موقع تایپ دیده نمی‌شود). کلید اشتباه همان‌جا رد می‌شود.</li>
<li><strong>همهٔ سرورهای پنل</strong> را نشان می‌دهد — شماره، نام، پروتکل، پورت، دامنه / IP — و جلوی سرورهایی که دامنه یا IP آن‌ها به همین سرور اشاره می‌کند <strong>HERE</strong> می‌گذارد؛ پیش‌فرض جواب همین‌ها هستند.</li>
<li><strong>این سرور کدام نود(ها) را اجرا کند</strong>: شماره‌ها با کاما، <code>all</code> (یا «همه») برای همهٔ سرورهای فهرست، یا <code>here</code> برای آن‌هایی که HERE دارند. هر کدام با پنل چک می‌شود.</li>
<li>چیزهایی که نودهای انتخابی لازم دارند: ایمیل Let's Encrypt (حالت گواهی http / tls / dns)، DNS provider و کلیدهایش (حالت dns)، فایل‌های گواهی (حالت file؛ فایل‌هایی که روی سرور هست پیشنهاد می‌شود). هشدارها: دو نود روی یک پورت، پورتی که برنامهٔ دیگری گرفته، دامنه‌ای که هنوز به این سرور اشاره نمی‌کند (گواهی‌اش صادر نمی‌شود).</li>
<li>خلاصه و سؤال <strong>«نصب شود؟ [Y/n]»</strong>. تا جواب ندهید چیزی نصب نمی‌شود.</li>
</ol>
<p dir="rtl">روی سروری که XMPlus دارد، <code>config.yml</code> همهٔ جواب‌ها را پر می‌کند (پنل، کلید، نودها، فایل‌های گواهی)؛ کافی است Enter و Enter و <code>y</code>. با <code>--yes</code> بدون سؤال با پیش‌فرض‌ها نصب می‌شود.</p>
<p dir="rtl">برای فهرست سرورها پچ Digitsell نسخهٔ <strong>1.19.0</strong> روی پنل لازم است (<code>xmplus-patch.php?do=node.list</code>). با پنل قدیمی‌تر، نصب‌کننده همین را می‌گوید و شمارهٔ نودها را می‌پرسد و هر کدام را از API نود پنل چک می‌کند.</p>
<p dir="rtl"><code>--pick</code> روی سروری که قبلاً نصب شده دوباره همین سؤال‌ها را می‌پرسد — برای اضافه یا کم کردن نود.</p>
<h3 dir="rtl">نصب خودکار بدون سؤال (سرورهایی که الان XMPlus دارند)</h3>

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/m0000hamad/xmplus-digitsell-patch/main/node/xray/install.sh) --yes
```

<p dir="rtl">نصب‌کننده این کارها را انجام می‌دهد:</p>
<ol dir="rtl">
<li>فایل <code>config.yml</code> نود XMPlus را پیدا می‌کند (<code>/etc/XMPlus/config.yml</code> یا <code>/root/config.yml</code>)
   و از آن آدرس پنل، ApiKey، شمارهٔ نودها، ایمیل و DNS provider گواهی، fallbackها، فایل rulelist
   و ConnectionConfig را برمی‌دارد؛</li>
<li>گواهی‌های Let's Encrypt همان XMPlus را استفاده می‌کند (دوباره صادر نمی‌شود)؛</li>
<li>آخرین Xray و lego را دانلود و checksum را بررسی می‌کند؛</li>
<li>XMPlus را <strong>متوقف و غیرفعال</strong> می‌کند (پاک نمی‌کند؛ بخش «برگشتن به XMPlus» را ببینید)؛</li>
<li>BBR و تنظیمات شبکه را روشن می‌کند (جای <code>bbr.sh</code>، بدون تغییر کرنل)؛</li>
<li>تنظیمات هر نود را از پنل می‌گیرد، خلاصه‌اش را چاپ می‌کند و اگر پورتی در ufw بسته بود باز می‌کند.</li>
</ol>
<h3 dir="rtl">نصب دستی (سرور تازه)</h3>

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/m0000hamad/xmplus-digitsell-patch/main/node/xray/install.sh) \
  --panel https://origin.example.com --key <ApiKey> --node 74
```

<ul dir="rtl">
<li><code>--key</code> همان <code>ApiKey</code> در config.yml نود XMPlus است (کلید API پنل).</li>
<li>چند نود روی یک سرور: <code>--node 74 --node 75</code> یا <code>--node 74,75</code>.</li>
<li>گواهی با DNS (مثلاً Cloudflare؛ پشت CDN بهترین حالت است):
  <code>--email you@example.com --dns-provider cloudflare --dns-env CF_DNS_API_TOKEN=xxxx</code>
  (نام provider و متغیرها همان نام‌های lego است: <code>lego dnshelp</code>؛ همان چیزی که در config.yml XMPlus بود).</li>
<li><code>--keep-xmplus</code>: XMPlus را متوقف نمی‌کند (فقط اگر پورت‌ها فرق دارند).</li>
<li><code>--no-bbr</code>: به sysctl دست نمی‌زند.</li>
<li><code>--xray-version v26.9.30</code>: نسخهٔ مشخص.</li>
</ul>
<p dir="rtl">اجرای دوبارهٔ نصب‌کننده امن است: <code>agent.json</code> ادغام می‌شود، جایگزین نمی‌شود.</p>
<h3 dir="rtl">دستورها</h3>

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

<p dir="rtl"><code>dxray</code> نام کوتاه همین دستور است.</p>
<h2 dir="rtl">پروتکل‌ها و تنظیمات پیشنهادی در پنل</h2>
<p dir="rtl">همه‌چیز در پنل ← سرورها ← ویرایش سرور، بخش «تنظیمات شبکه» و «تنظیمات امنیتی» انجام می‌شود.
بعد از ذخیره، نود ظرف یک دقیقه تنظیمات را می‌گیرد و کاربران فقط اشتراک را به‌روز می‌کنند.</p>
<p dir="rtl">نکته‌هایی که برای همهٔ پروفایل‌ها صدق می‌کنند:</p>
<ul dir="rtl">
<li><strong><code>allowInsecure</code> را خاموش کنید.</strong> در Xray جدید حذف شده و اپ‌هایی که هستهٔ جدید دارند لینکی را
  که <code>allowInsecure=1</code> دارد وصل نمی‌کنند. با گواهی واقعی (Let's Encrypt یا گواهی CDN) لازم هم نیست.</li>
<li>هشدار «deprecated» مربوط به WebSocket در لاگ خطا نیست؛ فقط یادآوری است که WS منسوخ‌شده و
  جانشینش XHTTP است (WS هنوز پشتیبانی می‌شود).</li>
</ul>
<h3 dir="rtl">۱. VLESS + XHTTP + TLS پشت CDN (پیشنهاد اصلی؛ جایگزین WS)</h3>
<p dir="rtl">نوع سرور: VLESS · پورت: <code>443</code> (یا یکی از پورت‌های HTTPS کلادفلر: 2053، 2083، 2087، 2096، 8443) ·
امنیت: tls · حالت گواهی: <code>dns</code> (بهترین حالت پشت CDN) یا <code>http</code></p>
<p dir="rtl">تنظیمات شبکه:</p>

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

<p dir="rtl">تنظیمات امنیتی:</p>

```json
{
  "serverName": "s1.example.com",
  "rejectUnknownSni": false,
  "allowInsecure": false,
  "fingerprint": "chrome",
  "flow": "none"
}
```

<ul dir="rtl">
<li>کلادفلر: رکورد DNS نارنجی (Proxied) و SSL/TLS روی <strong>Full (strict)</strong> (با گواهی self-signed فقط <strong>Full</strong>).</li>
<li><code>mode: auto</code> برای CDN مناسب است. اگر CDN درخواست‌ها را بافر می‌کند و کند است، <code>"mode": "packet-up"</code> را امتحان کنید.</li>
<li><code>?ed=2560</code> را نگذارید (فقط برای WebSocket است).</li>
<li>اپ‌های قدیمی بدون XHTTP (هستهٔ قبل از ۲۰۲۵) وصل نمی‌شوند؛ برای آن‌ها پروفایل ۵ را روی نود
  یا پورت دیگری نگه دارید.</li>
</ul>
<h3 dir="rtl">۲. VLESS + XHTTP + TLS مستقیم (بدون CDN)</h3>
<p dir="rtl">مثل پروفایل ۱، با رکورد DNS خاکستری (DNS only)، حالت گواهی <code>http</code> (پورت 80 باید آزاد باشد) یا <code>dns</code>،
و بدون <code>cdn_host</code>.</p>
<h3 dir="rtl">۳. VLESS + REALITY + Vision (سریع‌ترین؛ بدون دامنه و گواهی)</h3>
<p dir="rtl">نوع سرور: VLESS · پورت: <code>443</code> · امنیت: reality</p>
<p dir="rtl">کلید بسازید (PrivateKey را در پنل بگذارید؛ Password/PublicKey برای لینک‌هاست):</p>

```bash
/usr/local/lib/digitsell-xray/xray x25519
```

<p dir="rtl">تنظیمات شبکه:</p>

```json
{
  "transport": "tcp",
  "acceptProxyProtocol": false,
  "flow": "xtls-rprx-vision",
  "header": { "type": "none" }
}
```

<p dir="rtl">تنظیمات امنیتی:</p>

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

<ul dir="rtl">
<li><code>dest</code> و <code>serverNames</code>: یک سایت خارجی با TLS 1.3 و HTTP/2 که در ایران فیلتر نیست و
  ترجیحاً در همان دیتاسنتر یا کشور سرور شماست. دربارهٔ سایت‌های خیلی معروف (microsoft، apple)
  خود Xray هشدار می‌دهد که خطر بلاک شدن IP را بالا می‌برند.</li>
<li>نود به <code>publickey</code> نیازی ندارد؛ پنل برای ساختن لینک‌ها از آن استفاده می‌کند.</li>
<li>پشت CDN کار نمی‌کند (REALITY مستقیم است).</li>
</ul>
<h3 dir="rtl">۴. VLESS + XHTTP + REALITY</h3>
<p dir="rtl">مثل پروفایل ۳، ولی با تنظیمات شبکهٔ XHTTP:</p>

```json
{
  "transport": "xhttp",
  "acceptProxyProtocol": false,
  "path": "/api/v2",
  "mode": "auto"
}
```

<p dir="rtl">تنظیمات امنیتی مثل پروفایل ۳، فقط با <code>"flow": "none"</code>.</p>
<h3 dir="rtl">۵. VMess / VLESS + WebSocket + TLS (قدیمی، هنوز کار می‌کند)</h3>
<p dir="rtl">همان تنظیمات فعلی شما، فقط <code>allowInsecure</code> را <code>false</code> کنید:</p>

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

<p dir="rtl">تنظیمات امنیتی مثل پروفایل ۱.</p>
<h3 dir="rtl">۶. Shadowsocks 2022</h3>
<p dir="rtl">نوع سرور: Shadowsocks · روش: <code>2022-blake3-aes-128-gcm</code> · شبکه: <code>{"transport": "tcp"}</code> ·
امنیت: none · کلید سرور (server_key) در پنل: خروجی <code>openssl rand -base64 16</code>
(برای <code>aes-256</code> و <code>chacha20</code>: <code>openssl rand -base64 32</code>).</p>
<h3 dir="rtl">تنظیمات اضافهٔ XHTTP</h3>
<p dir="rtl">هر کدام از این کلیدها را می‌شود در «تنظیمات شبکه»ی پنل گذاشت و نود عیناً به Xray می‌دهد:
<code>mode</code> (<code>auto</code> / <code>packet-up</code> / <code>stream-up</code> / <code>stream-one</code>)، <code>xPaddingBytes</code>، <code>noSSEHeader</code>،
<code>scMaxEachPostBytes</code>، <code>scMaxBufferedPosts</code>، <code>scStreamUpServerSecs</code>، <code>serverMaxHeaderBytes</code>،
<code>headers</code>، <code>extra</code> و بقیهٔ کلیدهای xhttpSettings در
<a href="https://xtls.github.io/config/transports/xhttp.html">مستندات Xray</a>.</p>
<h2 dir="rtl">عبور مستقیم برای ایران و سایت‌های منتخب (بای‌پس)</h2>
<p dir="rtl">پنل ← سرورها ← سرورهای OpenVPN ← <strong>عبور مستقیم</strong> ← تیک <strong>«برای کاربران Xray (V2Ray) هم اعمال
شود — اپ Happ»</strong> (پچ 1.17.0).</p>
<p dir="rtl">همان فهرست OpenVPN (آی‌پی‌ها و دامنه‌های ایران + مقصدهای دلخواه شما) در لینک اشتراک برای اپ
<strong>Happ</strong> فرستاده می‌شود و Happ این مقصدها را مستقیم (بدون عبور از سرور) باز می‌کند. کاربر فقط
اشتراک را به‌روز می‌کند. برداشتن تیک، پروفایل را از Happ کاربران هم خاموش می‌کند.</p>
<p dir="rtl">چرا فقط Happ، و چرا در پنل نه روی سرور: در Xray تصمیم اینکه چه چیزی از سرور رد نشود با
<strong>اپ کاربر</strong> است؛ وقتی ترافیک به سرور برسد دیگر دیر است. از اپ‌های رایج فقط Happ مسیریابی را از
لینک اشتراک می‌گیرد. در v2rayNG / V2Box / Shadowrocket کاربر باید خودش گزینهٔ مسیریابی «ایران مستقیم»
(Bypass Iran) اپ را روشن کند. این روش برای لینک‌هایی کار می‌کند که از
<code>xmplus-patch.php?do=sub</code> می‌آیند (همان لینک «اطلاعات اشتراک در اپ‌ها»).</p>
<h2 dir="rtl">agent.json</h2>
<p dir="rtl"><code>/etc/digitsell-xray/agent.json</code> را نصب‌کننده می‌نویسد؛ با <code>digitsell-xray config</code> ویرایشش کنید.</p>
<table dir="rtl">
<thead>
<tr>
<th>کلید</th>
<th>پیش‌فرض</th>
<th>معنی</th>
</tr>
</thead>
<tbody>
<tr>
<td><code>panel</code></td>
<td>—</td>
<td>آدرس پنل (آدرسی که پشت CDN نیست، مثلاً <code>https://origin.example.com</code>)</td>
</tr>
<tr>
<td><code>key</code></td>
<td>—</td>
<td>ApiKey پنل</td>
</tr>
<tr>
<td><code>nodes</code></td>
<td>—</td>
<td>شمارهٔ نودها: <code>[74, 75]</code>، یا شیء برای تنظیم جدا: <code>{"id": 74, "panel": "...", "key": "...", "cert_file": "...", "key_file": "...", "fallbacks": [...]}</code></td>
</tr>
<tr>
<td><code>interval</code></td>
<td><code>60</code></td>
<td>هر چند ثانیه از پنل بپرسد و ترافیک را گزارش کند</td>
</tr>
<tr>
<td><code>limit_interval</code></td>
<td><code>15</code></td>
<td>هر چند ثانیه محدودیت دستگاه بررسی شود</td>
</tr>
<tr>
<td><code>ip_limit</code></td>
<td><code>true</code></td>
<td>اجرای محدودیت دستگاه پنل</td>
</tr>
<tr>
<td><code>block_private</code></td>
<td><code>true</code></td>
<td>کاربران به IPهای داخلی / LAN سرور نرسند</td>
</tr>
<tr>
<td><code>block_bittorrent</code></td>
<td><code>false</code></td>
<td>بستن تورنت</td>
</tr>
<tr>
<td><code>block_regex_file</code></td>
<td>—</td>
<td>فایل regex دامنه‌های بسته، یکی در هر خط (مثل rulelist در XMPlus). قانون‌های «rules» پنل هم خودکار اعمال می‌شوند</td>
</tr>
<tr>
<td><code>domain_strategy</code></td>
<td><code>AsIs</code></td>
<td>freedom: <code>AsIs</code>، <code>UseIP</code>، <code>UseIPv4</code>، <code>UseIPv6</code></td>
</tr>
<tr>
<td><code>dns</code></td>
<td>—</td>
<td>شیء <code>dns</code> خود Xray، عیناً</td>
</tr>
<tr>
<td><code>policy</code></td>
<td>—</td>
<td><code>handshake</code>، <code>connIdle</code>، <code>uplinkOnly</code>، <code>downlinkOnly</code>، <code>bufferSize</code></td>
</tr>
<tr>
<td><code>log_level</code></td>
<td><code>warning</code></td>
<td><code>debug</code>، <code>info</code>، <code>warning</code>، <code>error</code>، <code>none</code></td>
</tr>
<tr>
<td><code>access_log</code></td>
<td>—</td>
<td>مسیر فایل لاگ اتصال‌ها (به‌طور پیش‌فرض خاموش)</td>
</tr>
<tr>
<td><code>trusted_xff</code></td>
<td><code>["CF-Connecting-IP", "X-Real-IP", "True-Client-IP"]</code></td>
<td>پشت CDN: اگر یکی از این هدرها (که CDN می‌گذارد) باشد، IP واقعی کاربر از <code>X-Forwarded-For</code> خوانده می‌شود؛ بدون آن همهٔ کاربران IP خود CDN را دارند و محدودیت دستگاه غلط کار می‌کند. <code>[]</code> یعنی خاموش</td>
</tr>
<tr>
<td><code>api</code></td>
<td><code>127.0.0.1:10085</code></td>
<td>API داخلی Xray</td>
</tr>
<tr>
<td><code>cert.email</code></td>
<td>—</td>
<td>ایمیل Let's Encrypt</td>
</tr>
<tr>
<td><code>cert.provider</code> / <code>cert.env</code></td>
<td>—</td>
<td>DNS provider و کلیدهایش برای حالت گواهی <code>dns</code> (نام‌های lego)</td>
</tr>
<tr>
<td><code>cert.file</code> / <code>cert.key</code></td>
<td>—</td>
<td>گواهی آماده برای حالت <code>file</code> (یا <code>/etc/digitsell-xray/certs/&lt;domain&gt;.crt</code> و <code>.key</code>)</td>
</tr>
<tr>
<td><code>nodes[].tor</code></td>
<td>—</td>
<td>ترافیک این نود از یک نود <a href="https://github.com/m0000hamad/tor-multi-location">tor-geo</a> روی همین سرور خارج شود، مثلاً <code>"fr"</code> (پایین‌تر)</td>
</tr>
<tr>
<td><code>nodes[].proxy</code></td>
<td>—</td>
<td>ترافیک این نود از یک پروکسی SOCKS5 خارج شود: <code>"socks5://host:port"</code> یا <code>"socks5://user:pass@host:port"</code></td>
</tr>
</tbody>
</table>
<h2 dir="rtl">لوکیشن خروجی برای هر نود (Tor / SOCKS5)</h2>
<p dir="rtl">یک سرور می‌تواند چند کشور بفروشد: هر سرورِ پنل (نود) خروجی خودش را دارد.</p>
<ol dir="rtl">
<li><a href="https://github.com/m0000hamad/tor-multi-location">tor-geo</a> را روی سرور نود نصب کنید و کشورها را اضافه کنید: <code>tor-geo add fr de us</code>. نام نودها را <code>tor-geo list</code> نشان می‌دهد (<code>fr</code>، <code>de</code>، …).</li>
<li>در پنل برای هر کشور یک سرور با پورت جدا بسازید (و پرچمش را بگذارید).</li>
<li>در <code>agent.json</code> (<code>digitsell-xray config</code>) خروجی هر نود را بنویسید:</li>
</ol>

```json
"nodes": [
  {"id": 74, "tor": "fr"},
  {"id": 75, "tor": "de"},
  {"id": 76}
]
```

<p dir="rtl">نود 76 مثل قبل مستقیم از IP خود سرور خارج می‌شود. <code>digitsell-xray status</code> خروجی هر نود را نشان می‌دهد؛ اگر نام <code>tor</code> وجود نداشته باشد همان‌جا گزارش می‌شود و آن نود مستقیم خارج می‌شود.</p>
<p dir="rtl">Tor فقط TCP می‌برد: برای نود <code>tor</code>، QUIC (UDP 443) رد می‌شود تا مرورگر به TCP از مسیر Tor برگردد، و بقیهٔ UDP (DNS، بازی، تماس) مستقیم از سرور خارج می‌شود. قانون‌های بلاک پنل و محدودیت دستگاه همچنان اول اعمال می‌شوند.</p>
<h3 dir="rtl">از داخل پنل (agent 1.2.0، پچ 1.18.0)</h3>
<p dir="rtl">با پچ 1.18.0 یا جدیدتر روی پنل، هیچ‌کدام از کارهای بالا دستی لازم نیست: <strong>سرورها ← لوکیشن خروجی سرورها (Tor)</strong> همهٔ سرورها را با گزارش برنامهٔ نودشان و یک انتخاب کشور نشان می‌دهد (فهرست کشورها و تعداد exitها را خود سرور می‌فرستد). بعد از ذخیره، agent ظرف یک دقیقه:</p>
<ol dir="rtl">
<li>اگر tor-geo روی سرور نیست، نصبش می‌کند؛</li>
<li>برای آن کشور یک نود tor-geo می‌سازد (<code>tor-geo add</code>)؛</li>
<li>صبر می‌کند تا آن خروجی واقعاً جواب بدهد (از داخل همان خروجی با api.ipify.org تست می‌شود)؛</li>
<li>و فقط بعد از آن سرور را سوییچ می‌کند (یک بار ری‌استارت Xray).</li>
</ol>
<p dir="rtl">تا مرحلهٔ ۴ سرور با خروجی قبلی‌اش کار می‌کند، پس کاربر هیچ‌وقت روی خروجی‌ای که هنوز کار نمی‌کند نمی‌افتد. نودهای tor-geo که خود agent ساخته و دیگر هیچ سروری نمی‌خواهدشان دوباره حذف می‌شوند؛ نودهایی که دستی ساخته‌اید دست نمی‌خورند. گزینهٔ «طبق تنظیم خود سرور (agent.json)» انتخاب را به <code>agent.json</code> برمی‌گرداند. انتخاب پنل در <code>state.json</code> هم نگه داشته می‌شود تا اگر سرور وقتی پنل در دسترس نیست ری‌استارت شد، جابه‌جا نشود.</p>
<p dir="rtl">agent هر دقیقه <code>xmplus-patch.php?do=torexit.sync</code> را با کلید API پنل (در هدر <code>X-Panel-Key</code>) صدا می‌زند. پنل هیچ‌وقت به سرورها وصل نمی‌شود و رمز هیچ سروری را نگه نمی‌دارد.</p>
<h2 dir="rtl">چطور کار می‌کند</h2>
<ul dir="rtl">
<li><strong>دو سرویس:</strong> <code>digitsell-xray</code> (خود Xray رسمی) و <code>digitsell-xray-agent</code> (ایجنت پایتون، فقط
  با کتابخانهٔ استاندارد). ری‌استارت یا آپدیت ایجنت اتصال هیچ کاربری را قطع نمی‌کند.</li>
<li><strong>تنظیمات نود</strong> از <code>GET /api/server/&lt;id&gt;</code> پنل گرفته می‌شود، با ETag (فقط وقتی عوض شده). Xray
  فقط وقتی تنظیمات نود عوض شود ری‌استارت می‌شود؛ کانفیگ جدید قبلش با <code>xray run -test</code> امتحان
  می‌شود و اگر Xray قبولش نکند، نود با تنظیمات قبلی می‌ماند و خطا در <code>status</code> دیده می‌شود.</li>
<li><strong>کاربران</strong> از <code>GET /api/subscriptions/&lt;id&gt;</code> می‌آیند؛ اضافه و حذف با <code>xray api adu</code> / <code>rmu</code>
  و بدون ری‌استارت.</li>
<li><strong>ترافیک</strong> هر دقیقه از شمارنده‌های Xray خوانده و صفر می‌شود و به <code>POST /api/traffic/&lt;id&gt;</code>
  می‌رود؛ اگر پنل جواب ندهد روی دیسک می‌ماند و با گزارش بعدی فرستاده می‌شود.</li>
<li><strong>آنلاین‌ها</strong> به <code>POST /api/onlineip/&lt;id&gt;</code> می‌روند. پشت CDN، IP واقعی کاربر از <code>X-Forwarded-For</code>
  خوانده می‌شود (Xray جدید فقط وقتی قبولش می‌کند که هدر CDN مثل <code>CF-Connecting-IP</code> هم باشد؛
  همان <code>trusted_xff</code>).</li>
<li><strong>محدودیت دستگاه</strong> مثل XMPlus: <code>iplimit - ipcount + (IPهای همین نود در گزارش قبل)</code>. حسابی که
  جای خالی ندارد اصلاً روی این نود بالا نمی‌آید و IPهای بیشتر از سهم این نود با یک rule به
  blackhole می‌روند. IPی که جا گرفته تا ۲ دقیقه بعد از بسته شدن آخرین اتصالش جایش را نگه می‌دارد.</li>
<li><strong>گواهی</strong> با lego صادر می‌شود (حالت‌های <code>http</code>، <code>tls</code>، <code>dns</code> پنل) و ۳۰ روز مانده به انقضا تمدید
  می‌شود؛ Xray فایل گواهی را هر ساعت خودش دوباره می‌خواند (بدون ری‌استارت). تا گواهی واقعی گرفته
  نشده، یک گواهی self-signed گذاشته می‌شود تا نود بالا بیاید (پشت CDN در حالت Full کار می‌کند)
  و هر ۱۰ دقیقه دوباره تلاش می‌شود.</li>
<li><strong>Relay</strong> (زنجیره به نود دیگر) و <strong>sendthrough</strong> پنل پشتیبانی می‌شوند.</li>
</ul>
<h2 dir="rtl">برگشتن به XMPlus</h2>

```bash
digitsell-xray uninstall --restore-xmplus
```

<p dir="rtl">یا بدون حذف: <code>systemctl disable --now digitsell-xray digitsell-xray-agent &amp;&amp; systemctl enable --now XMPlus</code>.</p>
<h2 dir="rtl">عیب‌یابی</h2>
<h3 dir="rtl">بعد از گذاشتن نود xhttp، آپدیت اشتراک یا صفحهٔ «سرورها» (/portal/servers) «Internal Server Error» می‌دهد</h3>
<p dir="rtl">این باگ <strong>خود پنل</strong> است، نه نود. سازنده‌های لینک پنل (در <code>app/Http/Schema/</code>: فایل <code>Xray.php</code> برای
لینک اشتراک و <code>VlessURI.php</code> و هم‌خانواده‌ها برای صفحهٔ سرورها) کلیدهایی مثل <code>headerType</code> و <code>alpn</code>
را بدون بررسی می‌خوانند، و برای xhttp کنترلر آن‌ها را نمی‌فرستد. Whoops هشدار PHP را به خطای کشنده
تبدیل می‌کند و اشتراک <strong>همهٔ</strong> اکانت‌هایی که آن نود را می‌بینند خراب می‌شود. پیام خطا:
<code>Undefined index: headerType</code> در <code>Xray.php:85</code> (اشتراک) یا <code>VlessURI.php:12</code> (صفحهٔ سرورها).
برای دیدن پیام واقعی (روی سرور پنل):</p>

```bash
curl -sk --resolve <دامنه‌ی پنل>:443:127.0.0.1 "https://<دامنه‌ی پنل>/link/<توکن>?config=1" -o /tmp/err.html
python3 -c "import re,html;t=open('/tmp/err.html',errors='ignore').read();t=re.sub(r'(?s)<(style|script).*?</\1>','',t);t=re.sub(r'<[^>]+>','\n',t);print('\n'.join(l.strip() for l in html.unescape(t).splitlines() if l.strip())[:700])"
```

<p dir="rtl"><strong>از پچ 1.17.1 به بعد لازم نیست کاری بکنید:</strong> پچ این فایل‌ها را موقع نصب اصلاح می‌کند و هر ساعت
بررسی می‌کند (خروجی در <code>storage/logs/schemafix.log</code> و فقط وقتی چیزی عوض شود). اگر به‌روزرسانی خود
پنل فایل‌ها را به حالت اول برگرداند، ظرف یک ساعت دوباره اصلاح می‌شوند. فقط نسخهٔ 1.17.1 یا بالاتر
را در «تنظیمات ← به‌روزرسانی پچ» نصب کنید. اسکریپت زیر برای پنلی است که پچ ندارد، یا اگر
نمی‌خواهید یک ساعت صبر کنید.</p>
<p dir="rtl">راه‌حل دستی (یک بار، روی <strong>سرور پنل</strong>): همهٔ فایل‌های <code>app/Http/Schema/</code> را بررسی می‌کند و فقط
جایی که لازم است دست می‌زند؛ از هر فایل پشتیبان می‌گیرد، syntax را می‌سنجد و در صورت خطا
برمی‌گرداند:</p>

```bash
curl -fsSL https://raw.githubusercontent.com/m0000hamad/xmplus-digitsell-patch/main/node/xray/fix-panel-xhttp.py | python3 - /www/wwwroot/panel.example.com
```

<p dir="rtl">بعد نود xhttp را فعال کنید و همان <code>curl</code> بالا را دوباره بزنید؛ باید <code>200</code> بدهد. اگر ۵۰۰ ماند،
نود را فوراً غیرفعال کنید و پیام خطا را بفرستید. این اصلاح با هر به‌روزرسانی پنل که <code>Xray.php</code>
را عوض کند از بین می‌رود؛ دوباره اجرا کنید. (غیرفعال کردن هر نودی که ۵۰۰ می‌دهد اشتراک را
فوراً برمی‌گرداند.)</p>
<h3 dir="rtl">نود بالاست ولی «0 آنلاین» است و مصرفی گزارش نمی‌شود</h3>

```bash
ss -tn state established '( sport = :PORT )'     # اگر خالی است، کسی به این سرور نمی‌رسد
ss -ltnp | grep ':PORT '                         # باید xray باشد، نه XMPlus
systemctl is-active XMPlus xmplus                # هر دو باید inactive باشند
echo | openssl s_client -connect 127.0.0.1:PORT -servername دامنه 2>/dev/null | openssl x509 -noout -subject -dates
```

<p dir="rtl">اگر هیچ اتصالی برقرار نیست، مشکل مسیر است نه نود: رکورد DNS دامنه به IP این سرور (یا به CDN
با origin درست) نمی‌رود. <code>dxray doctor</code> فقط می‌گوید «چیزی روی پورت گوش می‌دهد» و نمی‌گوید چه چیزی.</p>
<h3 dir="rtl">چیزهای عادی در لاگ</h3>
<ul dir="rtl">
<li><code>node N: +2 -0 account(s)</code> هر دقیقه: محدودیت دستگاه پنل (اکانتی که روی نودهای دیگر به سقف
  رسیده کنار گذاشته می‌شود).</li>
<li><code>starting Xray: ...</code> بعد از تغییر تنظیمات نود در پنل؛ اتصال‌ها دوباره برقرار می‌شوند.</li>
<li><code>TLS handshake error ... i/o timeout</code> و <code>client sent an HTTP request to an HTTPS server</code>:
  اسکنرهای اینترنتی‌اند.</li>
<li>نصب‌کننده نسخهٔ Xray را از «latest release» گیت‌هاب می‌گیرد (ممکن است از جدیدترین پیش‌انتشار
  عقب‌تر باشد): <code>dxray update --xray-version v26.9.30</code>.</li>
<li>گواهی‌ای که خودتان به‌صورت فایل داده‌اید (حالت <code>file</code>) تمدید نمی‌شود؛ <code>dxray status</code> روزهای
  باقی‌مانده را نشان می‌دهد.</li>
</ul>
<h2 dir="rtl">محدودیت‌ها</h2>
<ul dir="rtl">
<li>محدودیت سرعت پنل (speedlimit) اعمال نمی‌شود؛ <code>check</code> برای نودی که دارد هشدار می‌دهد.</li>
<li>mKCP با <code>seed</code> / <code>header</code>: Xray جدید این‌ها را به finalmask برده؛ کلاینت‌هایی که seed دارند وصل
  نمی‌شوند.</li>
<li>HTTP/2 و QUIC به‌عنوان transport از Xray حذف شده‌اند؛ <code>check</code> این را می‌گوید و نود بالا
  نمی‌آید. به‌جایش XHTTP بگذارید.</li>
<li>ایجنت لینک‌های اشتراک را نمی‌سازد؛ پنل می‌سازد. اگر پنل شما XHTTP را در فهرست transport
  ندارد، همان WS (پروفایل ۵) را نگه دارید؛ این نود با آن هم کار می‌کند.</li>
</ul>
