# Handoff — Digitsell XMPlus panel patch

Living document. **Update it after every change**, alongside the release it
describes.

> This repository is **public**. No password, token, connection string or
> customer data belongs in any file here. Server and database credentials are
> held by the owner and passed in the working session only.

Last updated: 2026-09-30 · installed version **1.9.2** · latest release **1.17.0** · repo
<https://github.com/m0000hamad/xmplus-digitsell-patch>

---

## 1. What this is

`p.digitsell-shop.ir` is an **XMPlus** proxy-subscription panel. This repository
holds every customisation made to it, plus an updater that lets the owner apply
new releases from inside the admin panel instead of over SSH.

Local clone: `E:\Ai-Folder\digitsell` (moved here from a temp directory on
2026-09-06 so it survives between sessions).

## 2. The constraint everything else follows from

The install is **ionCube encoded**. These cannot be read or changed:

- `app/Http/Controllers/**`, `routes/**`, middleware, `app/Services/**`
- `app/Helpers/**`, `public/index.php`, `bootstrap/**`

These are plain source and are what the patch edits:

- `app/Http/Models/**`, `app/Jobs/**`, `app/Console/Commands/**`
- `view/**` (Smarty 3), `localization/*.php`, `bin/*.php`

**Consequences that bite constantly:**

- **No new HTTP route can be added.** The updater exists only because nginx
  passes any `.php` under `public/` straight to php-fpm, so a standalone file
  works as an endpoint.
- Whatever an encoded controller passes to a template is all a template gets.
  Several requests have had to be scoped down for this reason — see §7.

## 3. Repository shape

```
patch/          mirrors the panel's own directory layout; copied in verbatim
migrations/     idempotent PDO migrations, run once each, in filename order
tools/          build_manifest.php — regenerates manifest.json
install.php     first-time install, run once from the server shell
manifest.json   version, per-file SHA-256, migration list
VERSION         the version manifest.json was last built with
NOTES.txt       release notes; the builder copies them into the manifest
HANDOFF.md      this file
```

### Releasing

```bash
# edit files under patch/
php tools/build_manifest.php 1.4.3 --notes="what changed"
git commit -am "release 1.4.3 — ..."
git push
```

The manifest **must** be rebuilt after any change under `patch/`, or the
updater refuses the release. That is the safe failure, but still a failure.

On Windows the clone needs `core.autocrlf=false` (already set here) and the repo
carries `.gitattributes` with `* -text`: the manifest hashes exact bytes, and a
line-ending rewrite makes a correct release fail its own checksum.

## 4. The in-panel updater

`patch/public/xmplus-patch.php`, reached at `/xmplus-patch.php`. Admin UI is
**Settings → به‌روزرسانی پچ** (`patch/view/admin/settings/patchsettings.tpl`).

Flow: ask the GitHub API which commit `main` points at → read `manifest.json`
**at that SHA** → download the archive **at that SHA** → verify every file's
SHA-256 → back up what it replaces into `storage/patch/backup-<stamp>/` → copy →
run new migrations → clear `storage/smarty/compile` → record the version.

Refuses: a request without an admin session; without the CSRF token that
`?do=status` issues; a manifest naming a path outside `app/ bin/ localization/
view/ public/xmplus-patch.php`; any path containing `..`; any checksum mismatch.

Auth is checked twice — the session must claim `is_admin`, **and** the account's
`role` is re-read from the database. A session with a forged `is_admin` is
refused.

**It does not protect against a compromised repository.** Anyone who can push
here can run code on the server as the web user. Keep write access tight.

**1.4.4 was deployed by hand over SSH**, not through the updater: the manifest
files were diffed against live, the seven changed files copied in (backup in
`storage/patch/backup-manual-20260908-181913/`), `storage/smarty/compile`
cleared, and the `patch_version` setting bumped to 1.4.4. 1.4.3 had already been
applied through the panel. Live, repo and manifest are in sync at 1.4.4.

## 5. Environment facts worth knowing before touching anything

| Thing | Value |
|---|---|
| Panel root | `/www/wwwroot/p.digitsell-shop.ir` |
| Web user | `www` |
| PHP | 7.4 · MySQL 5.7 · nginx via aaPanel |
| Session cookie | **`xmplus`**, not `PHPSESSID` |
| Session store | files in `/tmp/sess_*`, owner `www` |
| DB config | `config/config.php`, `$DB` array |
| Public hostname | `p.digitsell-shop.ir` — **behind an Iranian CDN** |
| Direct hostname | `my.digitsell-shop.ir` — resolves straight to the origin |
| Backups | hourly encrypted zips in `storage/backup/`, password in the `backuppass` setting |

### Traps that have each cost an outage

- **nginx eats 404 and 502.** The vhost sets `error_page` to files that do not
  exist, so those responses are handed to `index.php` and the caller gets the
  panel's HTML 404. The updater answers **200 with `ok:false`** for every
  failure; only 403 and 405 pass through.
- **`display_errors` is on.** One warning printed before JSON breaks the whole
  response. The updater disables it for itself.
- **Whoops turns every `E_NOTICE` into a fatal.** An undefined index takes the
  page down.
- **PDO returns numeric columns as strings.** `=== 0` never matches `"0"`. This
  put the dashboard behind a Whoops page for 2518 zero-quota accounts. Cast
  before comparing, and distrust `===` against numbers anywhere in this codebase.
- **Ownership comes from the app directory, not from a file in it.**
  `public/index.php` is `root:root` while the directories are `www:www`.
- **Never delete rows by a name pattern.** MySQL's collation here is
  case-insensitive; a `LIKE 'zz_%'` cleanup deleted a real customer. Delete test
  data by the exact ids you created.
- **Never edit a file with an inline `sed`/`php -r` regex over SSH.** Quoting
  passes through several shells and mangled a Persian localization file, taking
  the site down. Upload a script and run it.
- **Never leave a `.bak` file inside the app.** The admin settings page scans
  `localization/` and treats any file there as a locale.
- **Smarty:** `{literal}` around CSS/JS with braces; `{}` in JS is read as a tag;
  a `{literal}` region cannot straddle `</script>`; escaping is **off**, so
  anything user-authored must be escaped in PHP.

### Dark mode — the single most load-bearing detail

`hs.theme-appearance.js` swaps stylesheet `<link>` elements and **never marks
the document**, so `html[data-hs-appearance="dark"]` matches nothing. A mirror
script in `patch/view/user/layout/header.tpl` stamps the resolved theme on
`<html data-hs-theme>`, and **every dark rule in this patch keys off that**.

Do not reuse the name `data-hs-appearance` on `<html>` — the theme script
queries that attribute to find its stylesheet nodes, and theme switching breaks.

## 6. What the patch changes, by area

| Area | Summary |
|---|---|
| Dashboard | Usage chart on ApexCharts (day/week/month/year, per server, up/down/total); subscription card, balance and IP tiles; apps card as a guided flow; Telegram link row |
| Servers | QR and copy as real buttons; per-protocol colours; config link as text |
| Tickets | Paragraphs survive, links clickable, Telegram-style sides, stickers, staff signature; **stored XSS closed** |
| Affiliate | Invite tab and commission tab; per-referral earnings; withdrawal form with card and IBAN; written cash-out rules |
| Commission | Automatic payout, popup, ledger, cash/credit routing |
| Invites | Dashboard invite popup in three stages with an "assistant" quoting the visitor's own numbers; ready-to-send invite message with share buttons on the affiliate page; friends-only note. Released in 1.8.0 — see below |
| Telegram channel gift | One-time weighted gift for new channel members (GB on a running plan, a free plan otherwise), `TgJoinJob`. Released in 1.8.0 — see below |
| Purchase flow | Plans, plan detail, checkout and orders redesigned; a verdict popup states the result and survives the redirect |
| Admin dashboard | Rebuilt on ApexCharts from one read-only call, `xmplus-patch.php?do=dashboard.overview` (`app/Patch/Dashboard.php`): KPI cards with sparklines and deltas, daily revenue by kind, 12-month trend (Solar Hijri months for fa_IR), sales mix and gateways, top plans, weekday x hour heatmap, user status, 14-day expiry pipeline, sign-ups, traffic by day and server, node table, latest paid orders, and a system health card (DB, nodes, cron locks, trafficlog freshness, 24h paid rate, disk, load, cache dir, unapplied time orders, patch version). Released in 1.7.0 |
| Invoice | A real document with seller, buyer, line item and totals; prints on one sheet; readable on a phone |
| Settings (user) | Gradient hero, glass section rail with a colour per section and the current one lit, cards carrying that accent; notification rows became switches; 2FA dialog restyled; every input id, button class and section anchor kept so the encoded controller and page JS are untouched |
| Notices | User timeline shows the title and reads as coloured cards; latest-notice popup restyled with a labelled dismiss switch; admin add/edit got RTL Persian TinyMCE, one-click snippets and a live user-popup preview |
| Time plans | A third plan type selling days only — see the section below |
| Menu | Labelled glass toggle, per-item colours, current page marked, works on phones |
| Themes | Dark mode fixed panel-wide (see above) |
| Gift cards | Redeem dialog redesigned, Telegram notice on redemption (1.8.9) - see below |
| Sign-in page | `view/auth/login.tpl` redesigned (1.8.6) — see below |
| Sign-up page | `view/auth/register.tpl` in the sign-in page's design (1.9.1) — see below |
| Promotions | Discount / special / prize on subscription plans, with occasion text, countdown and sales limit (1.10.0) — see below |
| Charge wallet | Pay-as-you-go wallet: top up any amount (min 200k toman, tiered bonus), the plan runs out → usage billed per server at a price per GB, no billing on a down server, plan-ending / balance notices; separate commission wallet for plans only (1.11.0) — see below |
| OpenVPN | OpenVPN servers on the same subscription: logins and traffic go through the panel, usage counts against the plan's data and the charge wallet, cut-off when the plan ends; admin server list with install command, dashboard card with profile download and credentials (1.12.0) — see below |

### Time plans — how days are sold without touching the order pipeline

A time plan is **not** a new package type. It is an ordinary topup package
(`package.type = 1`, `bandwidth = 0`) whose `order_note` carries a marker, a
field nothing renders for type 1:

```json
{"timeplan":{"v":1,"mode":"fixed","days":7,"applies_to":[2,3]}}
{"timeplan":{"v":1,"mode":"perday","price_per_day":150000,"min_days":1,"max_days":60,"applies_to":[]}}
{"timeplan":{"v":1,"mode":"minted","days":12,"parent":41,"created":1789537529,"applies_to":[]}}
```

That keeps checkout — coupon, gateway, invoice, order history — inside the
panel's own encoded code: the browser posts `plan: "topup"` with the package id
to `/portal/order/create`, exactly as "add data" does. `applies_to` empty means
every plan. A `perday` row is a parent and is never bought directly; picking N
days calls `timeplan.mint`, which finds or creates a `minted` row priced at
N × the daily rate, so the row count is bounded by `max_days`. Unsold minted
rows are switched off after a day and switched back on if the same N comes up.

Nothing in the paid path knows about days, so `bin/timeplans.php`
(`app/Jobs/TimePlanJob.php`, scheduled every minute from `TaskCommand`) grants
them. `timeplan_log.orderid` is UNIQUE and is claimed **before** the expiry is
moved, so a grant happens exactly once even if two runs overlap.

**A minted row is not a plan and must never be edited as one.** It is priced
for the exact day count it was made for, and the pay page
(`view/user/pay/cycle.tpl`) and order history read the name from it, so it
cannot be deleted once an order points at it either. The plans list hides these
rows client-side (`timeplanHideGenerated()` in `timeplanjs.tpl`, re-run on every
DataTable draw), the edit page refuses to save one, and `timeplanAdminSave()`
refuses server-side as well. Before that guard existed, opening one and saving
turned it into a priceless `fixed` plan.

Each plan carries two limits, `max_buys` and `max_total` (days), zero meaning
none. They are counted per subscription: `timeplanUsage()` sums `timeplan_log`
since the user's last paid `packagetype = 2` order, so renewing resets the
allowance. A minted row counts against its parent. `timeplan.options` drops a
plan with nothing left and narrows a per-day plan's range to what remains;
`timeplan.mint` checks again, because the browser is not to be trusted.

Watch out for these:

- **`UserJob` zeroes `transfer_enable` the moment a plan expires.** Buying days
  in the grace window afterwards would otherwise return a working account with
  no data. `UserJob` now writes the remaining traffic to `timeplan_snapshot`
  before wiping, and the grant restores it — only when the snapshot's
  `expire_in` still equals the user's, so old traffic can never come back.
- **A paid order is `orders.status = 1`.** `orders.state` is 0 on essentially
  every row; `Package::period_sales()`, which filters `state = 1`, counts
  nothing. Do not copy it.
- **`Package::topupList()` filters the marker out**, or time plans would show up
  inside the "add data" modal.
- The admin and user endpoints are in `app/Patch/TimePlan.php`, dispatched from
  `public/xmplus-patch.php` **before** its blanket `requireAdmin()`, because the
  buying half answers ordinary users. It has its own CSRF token,
  `$_SESSION['timeplan_csrf']`, and re-checks eligibility server-side.
- Visibility is two settings, `timeplan_visible_days` (7) and
  `timeplan_grace_hours` (24), edited in the time plan form and read by
  `User::timePlanVisible()`.
- If `/portal/order/create` ever refuses a zero-gigabyte package, set the
  `timeplan_bandwidth` setting to `0.01`; the endpoint reads it when writing the
  package row.
- Smarty's `{$x = ...}` assignment rejects ternaries — `edit.tpl` uses `{if}`
  blocks to unpack the marker.

### Limiting a traffic top-up to certain plans

Same idea, different storage. A top-up is saved through the encoded
`/admin/plan/save`, which rewrites `order_note` on every save, so the marker
trick would be wiped. The scope lives in one settings row instead:

    timeplan_topup_scope = {"7":[18,19],"8":[]}

package id → the subscription packages it is offered on; missing or empty means
everyone, which is what every pre-existing top-up is. The page writes it with
`timeplan.topupscope` right after the encoded save returns, identifying a brand
new package by name because that save does not report the id.

`Package::topupList()` and `topupAllowed()` do the filtering, and
`Package::scopeViewer()` deliberately returns null for staff — the admin pages
list top-ups too and must keep seeing all of them.

### Two scoping dimensions, not one

Both a time plan and a top-up can be limited by **subscription plan** and by
**server group**, independently. Each list is open when empty, and both have to
pass. The group is matched against `user.server_group` — not `user.user_group`,
which is the staff permission role and has nothing to do with this.

A time plan keeps `groups` in its marker next to `applies_to`. A top-up cannot,
for the reason above, so it gets a second settings row alongside the first:

    timeplan_topup_groups = {"7":[3,8]}

Both rows are written by the same `timeplan.topupscope` call.

### Commission — money rules already decided. Do not redo without asking.

- Only **new** commission is credited automatically.
- The watermark setting `commission_last_affiliate_id` marks the last paid row.
  **Never lower it** — everything below would pay a second time.
  `commission_log.affiliate_id` is UNIQUE as a second guard.
- Routing (the owner chose this): the referrer keeps it in `payout_balance` and
  can cash out **only** if their subscription is active **and** the gap since
  their previous one is at most `withdraw_max_gap_days` (90). Otherwise it is
  **moved** into `user.money` as spendable credit — moved, not added.
- Minimum cash withdrawal: `min_withdrawal` = 10,000,000 IRR. The server's own
  limit is the `payoutlimit` setting, measured at the same value.
- Two one-off migrations already ran: 143 active users (113,219,705 IRR) and
  219 expired users (171,144,159 IRR). **Staff keep their commission on
  purpose** — confirmed twice.

### Invites — popup, assistant, share bar (1.8.0)

Files: `view/user/affiliate/invitepopup.tpl` (included at the end of
`dashboard.tpl` when `rebate` is on), `inviteinsight.tpl` (the assistant
bubbles), `sharebar.tpl` (message + buttons; `shareEditable=1` on the affiliate
page, `shareCompact=1` in the popup), `User::referralCount()`,
`User::inviteInsight()`.

- Stages: 0 offer → dismissed → 12 h → 1 "what is lost" → 2 days → 2
  "discount on your next plan" → 7 days → back to 1. Any share button = done,
  quiet for 30 days. State is `localStorage['dsInvitePop:<uid>']` — there is no
  endpoint for it, and losing it only shows the offer once more.
- It never stacks: it waits until no `.modal.show`, `.swal2-container` or layer
  dialog is open, then 2 s of quiet.
- The owner decided the wording: **no "permanent income"** — the pitch is "your
  next plan at a discount, and your friends get a quality service". The
  service features list (fixed-location servers, SSL/encryption, battery, no
  YouTube ads, speed, 7 years / works in full shutdowns) comes from the owner.
- Telegram's `t.me/share/url` writes `url` ABOVE `text`. The whole message
  (pitch + link) goes in `url` alone, and the system share sheet gets it as
  `text` only, so the link stays at the end where the message points to it.
- Invite only friends and acquaintances, never public channels — a note under
  the share buttons says so. No penalty is stated because none was decided.
- `inviteInsight()` estimates with the **real average commission per purchase
  over the last 90 days** (`affiliate.ref_get`), not a made-up price.
- Warm palette only (orange/pink/amber); the owner rejected the first
  indigo design and its heavy font weights. The panel font is IRANSans with
  weights 200/300/400/500/700/900 — 800 renders as Black.

### Invite QR code (1.16.0)

`view/user/affiliate/inviteqr.tpl`, included on the affiliate page after the
withdrawal modal; the 📱 button on the link card opens it (`#afQrModal`).

- The QR is drawn on a `<canvas>` by a small encoder inside the template
  (`dsQrEncode`, byte mode, versions 1-40, after Nayuki's qrcodegen). No
  library and no CDN, for the same reason as the sign-in page. Tested by
  decoding every version back with jsQR.
- It reads the link from `#invitelink` when the dialog opens, so what it draws
  is always what the card shows.
- White ground and a 4-module margin in dark mode too, or phones fail to scan.
- "Send image" only shows where `navigator.canShare({files})` is true
  (phones); "Save image" downloads `digitsell-invite.png`.

### Telegram channel gift (1.8.0)

`app/Jobs/TgJoinJob.php`, `bin/tgjoin.php`, scheduled every minute in
`TaskCommand`. Log: `storage/logs/tgjoin.log`. Card:
`view/user/dashboard/tgjoin.tpl` under the subscription card, fed by
`User::tgJoin()`.

- The channel ("دوستان دیجیتسل", `-1001642779233`) is private with join
  requests. The panel bot (`settings.telegramtoken`) is an admin there and the
  job calls `getChatMember` for linked accounts (`user.telegram_id`).
- **New members only:** the account has to be seen outside the channel before
  it is seen inside (rechecked every 2 minutes). Inside at the first look = closed as `existing`, never
  gifted. Never-checked accounts are asked first, so a fresh link is looked at
  within a minute — before an admin approves the request. Loophole nobody can
  close from the bot: an old member who has not linked yet could leave, link,
  and rejoin. The admin approval is the only gate for that.
- **Exactly once:** `tgjoin_log` is UNIQUE on `userid` AND `telegram_id`, and
  the row is claimed before anything is applied.
- Gift (owner's ranges, weighting chosen to keep cost down): running plan →
  1–50 GB added (60 % 1–3, 25 % 4–10, 10 % 11–25, 5 % 26–50; mean ≈ 6.7 GB);
  no running plan → a free plan of 100 MB–1 GB (mean ≈ 360 MB; 10–50 GB until 1.9.0) for
  `tgjoin_free_days` (30) copying server group, IP and speed limit from
  `tgjoin_free_package` (18, "10 GB one month single user").
- **MySQL `NOW()` runs on UTC here while `expire_in` is local time (+03:30).**
  The free plan's expiry is computed in PHP for that reason.
- **Bot-link gift (1.8.2):** `TgJoinJob::bindGifts()`, same run. 1-10 GB
  (50 % 1-2, 30 % 3-5, 15 % 6-8, 5 % 9-10; mean 3.5) once per account and per
  Telegram id (`tgbind_log`). Needs a running plan AND at least one paid order
  (a trial plus a fresh Telegram account must not farm it). The first run after
  `tgbind_gift` = 1 marks every account already linked as `existing`
  (`tgbind_seeded` = 1 records that it happened). Badge on the dashboard
  Telegram row: `User::tgBindGiftOpen()`, key `TgBindGift`.
- **Telling the customer (1.8.3):** the bot's message and the dashboard popup
  (`view/user/dashboard/giftpopup.tpl`, `User::newGifts()`) state the gift,
  the plan's total traffic after it and the end date. `seen` on both logs
  drives the popup; reading marks it seen unless `adminview`. Dates inside
  Persian text need LRM marks (bot) or `<bdi dir=ltr>` (site), or they read
  backwards. One gift per SITE account: linking several Telegram accounts to
  one panel account earns nothing extra (UNIQUE userid).
- **Admin notes (1.8.4):** `tellAdmins()` writes to `tgjoin_admin_chats`
  (comma list) or, if empty, the panel's `telegramchatid`. A new link is
  detected as the first `tgjoin_check` row for the account; the bot-link gift
  is reported from `bindGifts()` and not repeated (`$reported`).
- **No manual refresh (1.8.5):** `view/user/dashboard/tgpoll.tpl` polls
  `xmplus-patch.php?do=tggift.poll` (`app/Patch/TgGift.php`, dispatched before
  `requireAdmin()` because users call it) every 15 s while visible, max 30 min,
  and reloads on an unseen gift or a changed link - never over an open dialog.
  `nudge=1` on returning to the tab sets `tgjoin_check.checked_at = 0` (at most
  every 30 s per session) so the next cron run checks that account first.
- Settings rows: `tgjoin_channel_id`, `tgjoin_link`, `tgjoin_free_package`,
  `tgjoin_free_days`. Empty channel id switches everything off.

### Sign-in page (1.8.6)

`view/auth/login.tpl` + `view/auth/loginsocial.tpl` (the icon row, included
twice: side panel on desktop, bottom of the card on phones). Desktop from
1024 px is a split screen, form on the right; below that only the card shows
and it fits one screen.

- **Do not edit `patch/view/auth/login.tpl` by hand.** It is built: the source
  is `tools/login/login.src.tpl`, and `node tools/login/build.js` compiles
  Tailwind 3 (npx) over it and inlines the CSS at `/*TAILWIND*/`. A class used
  in the source but not rebuilt simply has no CSS.
- No outside CDN on purpose: the site sits behind an Iranian CDN and
  `public/assets` is outside the updater's paths, so fonts (IRANSans, Inter)
  and Font Awesome come from the panel's own `/assets`, and the CSS is inline.
  Font Awesome here has no `fa-x-twitter`; X uses `fa-twitter`.
- **Icons are a subset (1.9.2).** The page does not load Font Awesome. A new
  `fa-*` class in the source needs `python tools/login/icons.py` (fonttools +
  brotlicffi; the panel's FA css and webfonts copied into `tools/login/fa/`,
  which is gitignored) before `node tools/login/build.js`, or it shows as a
  blank box. Only `fa-solid` and `fa-brands` exist on this page.
- IRANSans is declared in the page itself, 400 and 700 only - `font-black`
  renders as Bold and `font-medium` as Regular on purpose. No `iransans.css`,
  no Inter. The background is one static gradient (`.backdrop`); keep big
  animated blur filters off this page, they were what made it heavy.
- What is left is the server: the encoded controller takes ~0.48 s to answer
  `/login` at the origin, ~1 s through the CDN. PHP 7.4 here runs **without
  OPcache** (`opcache.so` exists but is not loaded in `php.ini`); it loads fine
  next to ionCube (checked with the CLI).
- Contract kept from the stock template: POST `/login` with `email`, `passwd`,
  `hcaptcha` / `turnstile`; `ret 1` → `/portal/dashboard`, `ret 2` →
  `/verify`, anything else shows `msg` under the form. No jQuery: the stock
  `captcha/*.tpl` partials need `$`, so the page loads the captcha APIs itself.
- The stock "Google / Telegram bot" quick sign-in and the `/tos` `/privacy`
  footer links were dropped: those routes do not exist (the last two answer
  500).
- Telegram support is `t.me/digitsellshop`; the other social links still point
  at the networks' home pages until the owner gives real ones.
- **Theme switch (1.8.7):** night / day / automatic in the header. Stored in
  the panel's own `localStorage['hs_theme']` (`dark` / `default` / `auto`), so
  the choice carries both ways between this page and the panel. Nothing stored
  means night on this page. A head script resolves it into
  `<html data-theme="dark|light">` before paint; the light look is a block of
  `[data-theme="light"]` overrides on the Tailwind classes in the source (any
  `text-white` without a `bg-gradient-*` class turns dark ink), so a new
  element with a new colour class needs its own override.
- Deployed by hand before each release commit; stock template and the 1.8.6
  version backed up in `/root/login-backup-20260924-181400/`.

### Sign-up page (1.9.1)

`view/auth/register.tpl`, same design, theme switch and breakpoints as the
sign-in page; the side panel lists the site's benefits instead (no "free
start" and no daily plans: the owner asked for neither).

- **Built, not hand-edited:** source `tools/register/register.src.tpl`,
  `node tools/register/build.js` inlines the Tailwind CSS, as for login.
- Contract kept from the stock template (copy supplied by the owner on
  2026-09-25): POST `/register` with `name` (username), `email`, `passwd`,
  `aff` (from the controller's `{$aff}`), `hcaptcha` / `turnstile`; `ret 1` →
  `/portal/dashboard`, anything else shows `msg`. With
  `enable_restrict_email_list` = 1 the email is a local part plus a suffix
  from `restrict_email_list`, joined before sending, as stock does.
- Additions are client-side only: repeat-password check, strength bar, the
  `passwordmode` hint, and an "invited by a friend" note when `{$aff}` is set.
- Dropped: the terms checkbox (client-side only in stock, and it linked to
  `/terms`, a route like `/tos` that the panel does not serve), the language
  selector (as on the sign-in page), and the WeChat block.

### Promotions on subscription plans (1.10.0)

Files: `app/Patch/Promo.php` (the save, `promo.save`, admin only, after
`requireAdmin()`), `app/Jobs/PromoJob.php` + `bin/promos.php` (every minute from
`TaskCommand`, log `storage/logs/promos.log`), `Package::promo()` /
`promoAdmin()` / `promoRunning()`, admin `view/admin/plans/promoform.tpl` +
`promojs.tpl` (included by `add.tpl` and `edit.tpl`, shown for type 2 only),
user `view/user/plan/promostyle.tpl`, `promobadges.tpl`, `promostrip.tpl`,
`promosticker.tpl` (the big starbursts on a card: discount/special, then the prize; 1.10.2-1.10.3)
(included by `plan.tpl` and `plan-details.tpl`), mail `view/email/promo.tpl`,
migration `005_promo.php`, keys `Promo*` in all three locales.

- **Storage:** one settings row, `promo_plans` = `{"<package id>": {...}}`.
  A subscription plan's `order_note` is shown to customers, so the time-plan
  marker trick is not available here.
- **A discount is real.** The form always shows and posts the **list** prices
  to the encoded `/admin/plan/save`; then `promo.save` reads `price_option`
  back as the list prices, keeps them in `original`, and writes the discounted
  prices (rounded to a whole unit) over `price_option` — the field the encoded
  checkout charges. `edit.tpl` swaps `original` into the price fields while a
  discount is open. `promoListPrices()` refuses to discount a discount: if
  `price_option` still equals exactly what the running discount produced, the
  stored list prices are used instead.
- **Kinds:** `none` / `discount` / `special` (a badge, price untouched), plus an
  independent **prize** switch: `gb`, `days` or `either` (a coin toss, then a
  whole number in the admin's min–max range). Optional: occasion text, end
  date (a `datetime-local`, read in the server's time zone), sales limit and
  whether customers see how many are left.
- **Counting:** a sale is `orders.status = 1` with `pay_date` (epoch) at or
  after `started_at` (and at or before `closed_at` once closed). Saving a
  running promotion keeps its `started_at`; a closed one restarts from zero.
  A closed promotion is not loaded back into the form, so saving never
  silently reopens it.
- **Prizes, exactly once:** `promo_log.orderid` is UNIQUE and claimed before
  the prize is applied. Orders are picked up only **60 s after payment**
  (`PRIZE_DELAY`): the encoded pipeline sets traffic and expiry on payment and
  would overwrite a prize added earlier. GB are added to `transfer_enable`;
  days extend `expire_in` from the later of its value and now, **computed in
  PHP** (MySQL `NOW()` is UTC here, `expire_in` is local).
- **Ending:** when the end date passes or the limit is reached, the job writes
  `original` back into `price_option` and sets `closed_at` / `closed_reason`
  (`time`, `sold_out`, `admin`, `deleted`). The pages stop showing a promotion
  the moment it is over (`promoRunning()` checks the date and the count), and
  the countdown hides the promo parts at zero (`.promo-over`), so the minute
  until the cron runs does not promise anything. A sale or two can still land
  in that minute at the discounted price — the sales limit is not a hard lock.
  Renewals and upgrades of the same plan also go through `price_option`, so
  they get the discount while it runs.
- **Messages:** every promoted purchase and every prize → the customer on
  Telegram (`user.telegram_id`) and by e-mail, and the admin chats
  (`tgjoin_admin_chats`, else `telegramchatid`). Start and end of a promotion →
  admin chats. Plain text, LRM marks around dates, like `TgJoinJob`.
- **Announcing to every customer (1.10.1, the owner said yes):** the
  "📢 announce" switch (on by default) makes `PromoJob::broadcast()` send the
  offer and a link to `/portal/plan/details?id=` to every `role = 0` account,
  150 a run: Telegram if linked, e-mail through the queue. `promo_broadcast`
  is UNIQUE on (`promo`, `userid`) with `promo` = `<package>:<started_at>`, and
  the row is claimed before sending, so an edit never repeats it while a
  reopened promotion is announced afresh. Accounts whose `notification`
  JSON has `sendnotices` = 0 (the "notices" switch on their settings page) are
  skipped. Only a running promotion is announced. The link's host is the
  `promo_site_url` setting, default `https://p.digitsell-shop.ir`.
- **Channel posts (1.10.4):** setting `promo_channel_id` (numeric id or
  `@name`), edited in the "promotion channel" card that
  `view/admin/settings/promochannel.tpl` adds under the patch updater
  (`promo.channel` / `promo.channelsave` / `promo.channeltest`, the last one
  sends a real test message so the admin sees whether the bot may post). A
  promotion with its `channel` switch on is posted by `PromoJob::channel()` in
  Telegram HTML: tags, list price struck through next to the promo price per
  cycle, traffic and users, prize range, occasion, deadline, "N left", and a
  buy button. `channel_msg` / `channel_hash` in the entry: the post is edited
  only when its text changes; on close it gets an "ended" header and loses
  the button (`channel_closed`). The stickers themselves are not images -
  Telegram gets the same tags as emoji.
- **Sticker themes (1.10.9):** entry key `theme` (`auto` default, else a key of
  `Package::PROMO_THEMES`; Promo.php keeps its own list). `Package::promoTheme()`
  resolves `auto` with `promoSeason()` (Iranian seasons by Gregorian date: spring
  from 21 Mar, summer 22 Jun, autumn 23 Sep, winter 22 Dec). The card and the
  details banner get `promo-theme-<name>`; promostyle.tpl sets the sticker colours
  (`--st-bg/--st-ink/--st-glow`), the corner ornament (`--st-orn`) and the particle
  glyph (`--st-part`). Picking an occasion theme in the form fills
  `#promo_occasion` only when it is empty or still holds another theme text.
- **End date (1.10.10):** `promoEndsAt()` sets the panel zone (`$_ENV['timeZone']`,
  as Dashboard.php does) before reading the datetime-local value, and a year
  1300-1599 is taken as Solar Hijri (`promoJalaliToGregorian`). The form does not
  prefill an `ends_at` in the past (it was the cause of "the end date has already
  passed" when a promotion was re-used after its time ran out).
- **Solar Hijri dates (1.10.11):** `Package::jalaliParts/jalaliText/jalaliField`
  format an epoch on `Package::PROMO_ZONE` (Asia/Tehran) whatever PHP's zone is;
  `PromoJob::date()` uses `jalaliText`. The end-date field is a text input
  holding `1405/07/30 23:59` (`promoAdmin` gives `ends_field` / `closed_text`);
  `promoEndsAt()` (Promo.php) and `promoEndsStamp()` (promojs.tpl) parse it the
  same way on Tehran time (+03:30), reject 30 Esfand outside leap years, and
  still take a Gregorian date.
- **End-date picker (1.10.12):** all in promojs.tpl, no library: `promoCalToggle/
  promoCalDraw` draw the month grid from `promoGregorianToJalali` /
  `promoJalaliToGregorian`; `promoEndsFromSpan` turns `#promo_ends_days` +
  `#promo_ends_hour` into a date on Tehran time. Both only write
  `#promo_ends_at`, which is still what is sent and parsed server side.
- **Prizes on the site (1.10.5):** `promo_log.seen` (added by the job and
  by migration 007; older rows count as seen) feeds `User::newGifts()`, so the
  dashboard's gift popup (`giftpopup.tpl`) shows a purchase prize as
  `source = promo`, GB or days, with the plan's name. The buyer lands on the
  dashboard after paying; while `User::promoPrizePending()` (a paid order on a
  prize plan in the last 30 min with no `promo_log` row yet) a gold toast says
  the draw is coming, `tgpoll.tpl` keeps polling and `tggift.poll` counts unseen
  prizes, so the page reloads into the popup. `User::promoPrize()` sums the
  prizes of the running subscription (orders paid since the last `packagetype
  = 2` purchase); usage is counted against the prize first
  (`promoPrizeLeft()` = prize - used, `promoPlanLeft()` = total - max(used,
  prize)). Shown in gold: chips on the subscription card, an inner ring and a
  line on the statistics card. Display only - the panel still holds one
  `transfer_enable`. Smarty 3 cannot index a method call
  (`$user->promoPrize()['gb']` fails to compile), hence `$uPrize`.
- **E-mail** goes through the panel's own queue (`App\Http\Models\Queue`,
  exactly like `UserJob`), so it uses the SMTP settings under Settings → Mail
  and is sent only while `maildriver` = 1. The queue row carries
  `telegramid = 0` on purpose — the Telegram message is sent by the job. The
  template is `promo.tpl`, shipped as `view/email/promo.tpl`, next to the
  stock `expired.tpl` and `dataused.tpl` (confirmed on the server 2026-09-26).
  The name can be changed with the `promo_mail_template` setting.

### Charge wallet and commission wallet (1.11.0)

Asked for: the customer tops up any amount from 200,000 toman; when the plan
runs out (data or time) they stay connected and usage comes off the balance,
like an Iranian SIM card; a price per GB per server; the admin sees what was
spent and what is still unspent; commission kept apart and only usable for
subscription plans; tiered top-up bonus; no billing while a server is down.

**Everything ships switched off.** Settings → کیف پول شارژ و پورسانت turns it
on (`payg_enabled`, `commission_wallet_enabled`). Amounts are rial.

Pieces:

- `migrations/008_payg.php` — `payg_wallet`, `payg_ledger`, `payg_rate`,
  `payg_notice`, `commission_wallet`, `commission_wallet_log`,
  `commission_hold`, and the `payg_*` settings.
- `app/Jobs/PaygJob.php` via `bin/payg.php`, every minute from `TaskCommand`.
- `app/Patch/Payg.php` — `payg.*` / `commission.*` actions, dispatched from
  `public/xmplus-patch.php` **before** `requireAdmin()` (customer half has its
  own CSRF token `$_SESSION['payg_csrf']`; admin half calls `requireAdmin()`).
- `view/user/dashboard/payg.tpl` (wallet card, charge dialog),
  `view/user/plan/commissionuse.tpl` (plan page switch + renew button),
  `view/admin/settings/paygsettings.tpl` (settings, prices, report, wallets,
  manual adjustment, commission migration).

**Top-up = the time-plan trick.** `payg.mint` finds or creates a topup
package (bandwidth 0, `order_note` = `{"paygcharge":{"v":1,"amount":N,"created":T}}`)
priced at the amount, rounded up to `payg_charge_step`; the browser then posts
`/portal/order/create` with `plan: "topup"`. `PaygJob` credits every paid order
on such a package once — `payg_ledger.ref = 'order:<id>'` is UNIQUE — minus the
order's coupon discount, plus the bonus tier (`bonus:<id>` row). Unsold rows are
deleted after a day. `Package::topupList()` and the admin plan list hide them.

**Modes** (`payg_wallet.mode`), moved by the job:

- `plan` — the job does not touch the account.
- `balance` — entered when the plan is over (`expire_in` within 3 minutes, or
  `u + d >= transfer_enable`), the switch is on and the balance is positive.
  The job keeps `expire_in` at least a day ahead (so `UserJob` never wipes the
  account) and `transfer_enable = u + d + balance / dearest price per GB`, so
  **the panel's own quota check is the cut-off**; no encoded field is needed.
- `empty` — balance ≤ 0: `transfer_enable = u + d`. A top-up resumes.
- Back to `plan` when a subscription order is paid after `since`, or the plan's
  periodic reset lowers `u + d` while a subscription is still running. Unused
  plan data is not carried into the wallet (operator behaviour).
- The customer switch (`auto`) off while on balance cuts at once.
- While not in `plan`, the top-up list and time plans are hidden
  (`User::paygOnBalance()`), because the job owns quota and expiry.

**Billing is exactly-once.** Under `GET_LOCK('payg_bill')`, one transaction
reads `trafficlog` rows with `datetime` in (`payg_last_log_time`,
now − 60s] for accounts not in `plan` (and newer than their `since`),
debits the wallets, upserts one `usage` row per user/server/day and moves the
watermark. A server with `alive != 1` or a heartbeat older than 5 minutes is
billed at 0 (`free_bytes`) when `payg_outage_free` is on; a price of 0 is free.
The balance may dip slightly below zero (billing lags up to ~2 minutes); the
next top-up covers it. Known loss: rows written in the last minute before
`LogsJob` prunes yesterday at 00:00 are not billed (in the customer's favour).
Bytes billed are `trafficlog.u + d` (raw, not the panel's server multiplier).

**Notices** go to `payg_notice` (dashboard card, shown once), Telegram (the
panel's bot) and e-mail (`promo.tpl` through the queue): top-up credited,
billing started, low balance (once per top-up), balance empty, resumed, plan
active again, and plan ending (`payg_warn_days`, `payg_warn_percent`, every 5
minutes, once per plan period; skipped when the customer turned `dataexpire`
notices off). The unique key on `payg_notice` is what stops duplicates.

**Commission wallet.** With `commission_wallet_enabled`, `CommissionJob` puts
the "wallet" share of commission into `commission_wallet` instead of
`user.money` (the cash-eligible share still stays in `payout_balance`). The
encoded checkout only spends `user.money`, so right before a subscription
order `commission.apply` moves the gap between the price and the current money
into money and writes `commission_hold`; the job returns whatever is still
there once a subscription is paid or after 30 minutes. `payg.mint` returns open
holds first, so commission never turns into wallet credit. The one-off
"move panel wallets" button moves every positive `user.money` into the
commission wallet (owner asked for all of it; refused a second time).

**Status in the client apps** (`app/Patch/SubInfo.php`, `?do=sub`). The
panel's `/link/<token>?config=N` output is encoded, and the apps only read
numbers from `subscription-userinfo` (dates come out Gregorian), so the text
rides in information-only rows. The wrapper
`https://<host>/xmplus-patch.php?do=sub&t=<token>&config=N`:

1. fetches the panel's own link with the same query and User-Agent, pinned
   to `sub_origin_ip` (127.0.0.1) or from `sub_origin` if set, sending
   `X-Sub-Raw: 1`;
2. finds the account by the uuid inside the configs (vmess JSON decoded too),
   then by a `token` column or a `link` table if either exists;
3. for a URI list (base64 or plain) puts rows first, named with the message:
   Solar Hijri end date and days left, data left, wallet balance, "on balance" /
   "balance empty" / "plan over", and "updated HH:MM; update the subscription
   for the live balance". They point at `127.0.0.1:1`. Since 1.11.5 each row is
   kept to about 25 characters (the apps cut a long server name off on a
   phone), so end date / days left and updated / "update to refresh" are two
   rows each;
4. passes the headers through and adds `announce: base64:…` (Happ shows it as a
   banner); Shadowrocket also gets a first `STATUS=` line. Since 1.11.2 the
   `subscription-userinfo` header is replaced whenever the rows are added
   (owner: the app must not show the old total and Gregorian expiry). 1.11.3:
   dropping it was not enough - the apps keep the values from their last
   update - so it is sent as `upload=0; download=0; total=0; expire=0`; Clash /
   sing-box, which get no rows, keep it (with `expire=0` while on the wallet).
   1.11.4: the panel also puts its own info entries in the list ("Total:1000.5G
   Used:0.71G", "Expire:2027-09-29", shown as VMESS servers); when the rows go
   in, entries whose name starts with Total/Used/Expire/Remaining/Traffic/Reset
   and a colon are dropped (`subinfoIsPanelInfo`);
5. leaves Clash YAML / sing-box JSON untouched; if anything fails it answers
   302 to the panel's own link, so nobody loses their servers.

Apps in use (owner, 2026-09-29): Happ, V2Box, v2rayNG, Shadowrocket — all read
base64 URI lists. The dashboard hands out the wrapper link only when
`sub_info_enabled` = 1 (application.tpl, `$subLink`); links already imported
keep pointing at `/link/`. To move those too, one nginx line on the server
(not part of the patch), inside the panel's `server {}`:

```nginx
location ~ ^/link/([A-Za-z0-9_-]+)$ {
    if ($http_x_sub_raw = "") { rewrite ^/link/([A-Za-z0-9_-]+)$ /xmplus-patch.php?do=sub&t=$1 last; }
    try_files $uri /index.php$is_args$args;
}
```

(`X-Sub-Raw` stops the wrapper's own fetch from looping; check the panel's
existing `location /` before adding it.) Tested locally with a stand-in
upstream: base64 and plain lists, Happ/v2rayNG/Shadowrocket User-Agents, plan,
expired, on-balance and empty accounts, a YAML pass-through, a bad token (403)
and a dead upstream (302 to the old link).

**1.11.1 — where the wallet lives on the dashboard.** The owner found the
1.11.0 card, a full-width block between the dashboard rows, confusing and
asked for the operator-app layout instead:

- The balance tile in the subscription card becomes the **wallet tile**
  (`view/user/dashboard/wallettile.tpl`): balance, "≈ N GB", commission and
  panel-money lines when present, a red dot for unread messages, **➕ افزایش
  موجودی** and **جزئیات ‹**. Without `payg_enabled` the old balance tile stays.
- While the account is on the wallet, the top of the subscription card
  (`walletstate.tpl`) says so — "⚡ اتصال از کیف پول" / "⛔ اتصال قطع است",
  balance and headroom chips, a one-line explanation — instead of the plan's
  name, traffic chip and a misleading "1 day left" clock. Add funds and Buy a
  plan lead the button row. `statistics.tpl` explains what "remaining" means.
- Everything else is in a **side panel** (`view/user/dashboard/wallet.tpl`):
  from the inline end on desktop, a bottom sheet under 576 px. Bank-card hero,
  a pending line for paid-but-not-credited top-ups (`payg.me` → `pending`), and
  four tabs: add funds (sticky pay button), transactions grouped by day,
  prices, settings (auto switch, commission wallet). Opened by any
  `[data-wallet-open="charge|history|prices|settings"]` and by
  `/portal/dashboard#wallet` (`#wallet-history` etc.) — the new **💳 کیف پول**
  menu item points there (`usermenu.tpl`, only with `payg_enabled`). Esc,
  backdrop, ✕ close it; the page does not scroll behind it.
- Billing-job messages are a **toast** at the top with "مشاهده", no longer a
  block in the page. `payg.tpl` is gone (the updater leaves the old file on the
  server, unused).
- `User` got `paygEnabled()`, `paygMode()`, `paygBalanceShown()`,
  `paygToman()`, `paygHeadroomGb()`, `paygUnseen()`,
  `commissionWalletEnabled()`; the per-user cache is a static array now, not a
  property on the Eloquent model. Headroom (and the job's quota) use the dearest
  **enabled** server.

**1.11.1 — "the minimum goes back to 200k".** No server-side bug was found;
the save path was made observable and robust instead:

- Admin amounts are shown and typed in **toman** while `payg_show_toman` is on
  (rial in the database; the page multiplies/divides by 10): minimum, step,
  default price, low-balance threshold, bonus tiers, server prices, report,
  wallets, ledger, adjustment, migration total.
- `payg.save` answers with the stored settings and the form is refilled from
  that answer ("✓ ذخیره شد — حداقل شارژ: X تومان"); no follow-up GET that a cache
  could answer. Enter in a box saves.
- Every GET from the wallet pages carries `&_=<ms>` and `cache: 'no-store'`:
  the site is behind an Iranian CDN, and a cached `payg.admin` would show the
  old minimum after a save — the most likely cause of the report.
- A POST refused for its token fetches a fresh token and retries once (the
  panel's own requests can rewrite the session file).
- Minimum 0 means no minimum; `payg.mint` still refuses 0 and rounds up to the
  step. Customer-facing mint errors are Persian.

Not yet verified on the live panel — see §8.

### OpenVPN on the same subscription (1.12.0)

Asked for: an OpenVPN backend whose traffic is merged with the existing
subscription. **Ships switched off** (`ovpn_enabled`).

Pieces:

- `migrations/010_openvpn.php` — `ovpn_node` (one row per OpenVPN server:
  key hash, `allowed_groups`, multiplier `rate`, and what a profile needs —
  address, port, proto, CA, tls-crypt key — reported by the node itself),
  `ovpn_session` (last counters per live session), settings `ovpn_enabled`
  and `ovpn_secret`.
- `app/Patch/Ovpn.php`, dispatched from `xmplus-patch.php` **before**
  `requireAdmin()`: node actions (`ovpn.hello`, `ovpn.auth`, `ovpn.push`)
  authenticate with headers `X-Ovpn-Node` / `X-Ovpn-Key`; `ovpn.profile` takes
  the customer's session; the admin half calls `requireAdmin()` and, for
  writes, `requireToken()` (`patch_csrf`).
- `view/admin/settings/ovpnsettings.tpl` (servers, add / edit, new key, delete,
  install command, connected users, bypass, messages) — included by
  `view/admin/servers/index.tpl` under the server list since 1.15.0 (it was
  the last card of the settings page before), `view/user/dashboard/ovpn.tpl` (included
  by `dashboard.tpl` only when `User::ovpnEnabled()`).
- `node/openvpn/` — `install.sh`, `ovpn-agent.py` and `uninstall.sh`
  (1.12.1; `--keep-ca`, `--purge`) for the OpenVPN server.
  **Not part of the manifest**; the install command fetches them from this
  repository. See `node/openvpn/README.md`.
- **Ports are chosen in the panel (1.13.0).** `node/openvpn/digitsell-ovpn-nat`
  (reading `/etc/digitsell-ovpn/nat.conf`) redirects every port of the node's
  protocol to OpenVPN through the nat chain `DIGITSELL_OVPN`, except ports a
  local program listens on (`ss`), sshd's ports, 22 and `--exclude`; a timer
  rebuilds the list every minute. The agent (1.1.0) reports `all_ports` and the
  excluded list in `ovpn.hello` (every 10 minutes). `migrations/011` adds
  `ovpn_node.public_ports`, `all_ports`, `excluded_ports`. The admin form's
  "پورت‌ها برای کاربران" takes up to 8 ports; the profile gets one `remote` per
  port plus `server-poll-timeout 10`. `ovpn.nodesave` refuses a port the node
  reported as taken, or any port other than its own on a node without the
  redirect (installed with 1.12.x or `--single-port`); the row turns red if a
  chosen port stops working later. The protocol is still fixed at install.
- **OpenVPN in the apps card (1.13.1):** an app in the panel's own client
  apps list whose name contains "OpenVPN" (e.g. "OpenVPN Connect", one per
  platform) gets `view/user/dashboard/ovpnapp.tpl` as its step 3 in
  `application.tpl`: server files, username / password, the app's own download
  link and guide — all edited in the panel's apps list like any other app.
  While such an app exists, `dashboard.tpl` hides the separate OpenVPN card.
  Its icon is written like the panel's others,
  `<span class='xmplus xmplus-openvpn fs-15'></span>`: the panel's xmplus icon
  font has no OpenVPN glyph, so `view/common/ovpnicon.tpl` (included from
  `user/layout/style.tpl` and `admin/layout/footer.tpl`) draws one as a
  currentColor mask (1.13.2). That did not show on the live panel (cause not
  known: the icon font's own CSS or a CSP on data: URIs are the suspects), so
  since 1.13.3 `application.tpl` draws any OpenVPN app's picker icon itself
  with inline SVG (`view/common/ovpnsvg.tpl`), whatever the icon field says.
  Styles and the password toggle live in `ovpnstyle.tpl` (class / data
  attributes only, since the markup can appear once per platform tab).
- **UDP and TCP (1.14.0).** `install.sh --proto both` (default) runs
  `openvpn-server@digitsell` (UDP, 10.8.0.0/16, management 7505) and
  `openvpn-server@digitsell-tcp` (TCP, 10.9.0.0/16, 7506) on the same port;
  `digitsell-ovpn-nat` keeps a redirect chain per protocol
  (`DIGITSELL_OVPN_UDP` / `_TCP`, skip lists in
  `/run/digitsell-ovpn-nat.excluded.<proto>`) and removes the 1.13 chain.
  The agent (1.2.0) holds one management connection per instance and
  reports `listen` = {udp: {port, all_ports, excluded}, tcp: {...}};
  TCP session ids get a `t` prefix. `migrations/012` adds `listen_json`,
  `offer` ('' automatic / udp / tcp / both) and `public_ports_tcp`
  (`public_ports` is now UDP; a TCP-only node's ports were moved).
  `ovpnListen()` falls back to proto / port / excluded_ports for older agents;
  `ovpnOffered()` (mirrored in `User::ovpnOffered()`) decides what customers
  get. `ovpn.profile&proto=udp|tcp|both`: both lists the UDP remotes first and
  the TCP ones after, each with its protocol, and leaves out
  `explicit-exit-notify`. The dashboard row (`ovpnnode.tpl`) shows UDP / TCP
  buttons plus the combined download when both are offered. A session
  closed for silence and reported live again is reopened (usage is still
  counted once: the growth is against stored counters).
- **Online / offline messages (1.14.1).** `app/Jobs/OvpnJob.php` via
  `bin/ovpn.php`, every minute from `TaskCommand` (log `storage/logs/ovpn.log`):
  a server whose heartbeat is older than 180 s is offline; a change sends
  "🔴 … آفلاین شد" (last contact) or "🟢 … دوباره آنلاین شد" (how long it was
  down) with the panel bot (`telegramtoken`) to `tgjoin_admin_chats`, else
  `telegramchatid`. First sight only records; switched-off servers and ones
  that never reported are skipped. State in the `ovpn_notify_state` setting,
  written before sending. `ovpn_notify` = 0 (the switch on the OpenVPN
  settings card) turns it off.
- **Status, auto ports, bypass, domain certificate (1.15.0).**
  `migrations/013` adds `ovpn_node.up_json`, `cert_name` and the settings
  `ovpn_bypass_iran`, `ovpn_bypass_custom`, `ovpn_bypass_cache`.
  - *Why the Telegram message did not come:* stopping one instance of two
    (`openvpn-server@digitsell`) left the other one feeding the agent, so the
    heartbeat stayed fresh. Agent 1.3.0 pushes every minute even with nothing
    running and sends `instances` {udp: bool, tcp: bool} → `up_json`.
    `ovpnNodeLive()` / `User::ovpnLive()`: fresh heartbeat and not every
    offered protocol down; `ovpnNodeDownProtos()` names the rest. `OvpnJob`
    now has three levels (2 online / 1 part down 🟠 / 0 offline 🔴, with "agent
    link lost" vs "agent alive, OpenVPN not running"), state
    `{"s", "since"}` (the old `{"up"}` is still read), writes
    `ovpn_job_last` every run and logs each send result. The card shows when
    the job last ran (never / late → the cron is the problem) and a
    **پیام آزمایشی** button (`ovpn.notifytest`, per-chat result: token, chat
    id and reachability problems show there).
  - *Auto ports:* `install.sh --port auto` (default) picks a port no program
    holds (`ss`, both protocols; an earlier install's port first). The agent
    suggests the best free public ports (`PREFERRED_PORTS`, first 2) and
    reports the preferred ones that are `busy` (skip list + `/proc/net`
    listeners, since the skip list does not exist yet at `--check`).
    `ovpn.hello` keeps the previous `auto` while none of it is excluded or
    busy, else takes `suggested`; `ovpnNodePorts()` uses the admin's ports,
    else `auto`, else the node's own port.
  - *Bypass:* `route <net> <mask> net_gateway` lines in the profile
    (`ovpnBypassLines()`): the Iran IPv4 list (`app/Patch/data/iran-ipv4.txt`,
    ipverse/rir-ip, CC0; **به‌روزرسانی** fetches it into
    `storage/patch/iran-ipv4.txt`, refused under 500 ranges) plus custom
    lines (domains / IPs / networks, max 200 lines, 40 domains, prefix ≥ 8).
    Domains are resolved by the panel on save and every 6 h by `OvpnJob`
    (`ovpn_bypass_cache`). **At most `OVPN_BYPASS_MAX_ROUTES` = 1200 routes
    (1.15.1):** OpenVPN Connect (OpenVPN 3, `cliconstants.hpp`) refuses a
    profile over 262144 bytes counted as 64 per line + 16 per word + the
    words (~166 per route); 1745 Iran routes came to ~298000 → "option_error:
    profile is too large". Custom entries always go in, the Iran ranges fill
    the rest largest first (~98.5% of the addresses; the smallest go through
    the tunnel — merging would send foreign space around it), and a custom
    entry is dropped only if a range that made it in covers it.
  - *Domain certificate:* when the address customers get
    (`ovpnNodeHost()`) is a domain, hello and push answers carry
    `cert_name`; agent 1.4.0 runs `/usr/local/sbin/digitsell-ovpn-cert
    <domain>` (easy-rsa, the node's own CA, CN = SAN = domain, 20 years),
    which points both configs at it and `try-restart`s the instances, then
    reports `cert_name` back. Only when the reported name equals the wanted
    one does the profile add `verify-x509-name <domain> name`
    (`ovpnCertReady()`), so a file never pins a name the server does not
    have yet. An empty wanted name leaves the last certificate in place;
    `install.sh` keeps it on reinstall (`/etc/digitsell-ovpn/cert-name`).
    Not Let's Encrypt: OpenVPN apps trust only the file's CA, and port 80 is
    redirected to OpenVPN. Agent 1.4.1 (node files only, no panel release):
    `--check` issues the certificate synchronously, so it is in place before
    the installer starts OpenVPN; with 1.4.0 the freshly started agent issued
    it and restarted OpenVPN right under the installer's 2-second
    `is-active` check ("OpenVPN (udp) did not start" on a node with a
    domain). `install.sh` now waits up to 20 s for each unit to stay active
    and prints its journal when it does not.
- **Servers that already run Xray / a firewall (1.16.1, node files).** It
  worked only on clean servers. `digitsell-ovpn-nat` now: skips ports with a
  live socket via `-m socket --nowildcard` in the redirect chain (Xray's
  hundreds of ever-changing UDP relay sockets were listed from `ss -lun`, so
  the chain was rebuilt every minute; UDP listeners in the ephemeral range are
  no longer listed when the match exists), builds the chain atomically with
  `iptables-restore --noflush`, keeps the openings in its own chains
  (`DIGITSELL_OVPN_IN` / `_FWD` / `_POST`) jumped to first and re-asserted by
  the refresh timer, mirrors them into `iptables-legacy` when that backend has
  rules or a DROP policy, and inserts accept rules (comment `digitsell-ovpn`)
  into native nftables input / forward chains with `policy drop`. `start`
  removes the 1.12 - 1.15.1 rules written straight into the built-in chains.
  `digitsell-ovpn-nat doctor` reports the lot. Later (node files only): the
  installer writes `CONNTRACK_MAX` (128 per MB of RAM, 65536 - 262144) to
  nat.conf and the nat script raises `nf_conntrack_max` and the hash to it
  (a live XMPlus server showed 3353 of 7680 used); `doctor` warns at 70% and
  counts attempts per protocol in the last 15 min (`peer info: IV_VER=` =
  passed tls-crypt, `Peer Connection Initiated` = handshake done). A
  reinstall keeps an `IF=` line of nat.conf. **That broke every first
  install** (no nat.conf yet: the `sed` reading it failed under
  `set -euo pipefail` and the script ended silently after "==> routing");
  fixed, and install.sh now traps ERR to print the line and command it
  stopped at. Agent 1.4.2: `--check` prints one line (panel unreachable, or
  its refusal) instead of a traceback. Tested with 400 churning UDP
  sockets, a foreign DROP inserted at the top of FORWARD, an `inet` table
  with `policy drop`, and iptables-legacy `FORWARD DROP`: each cut tunnel
  traffic before a refresh and passed after. Which of these the live servers
  had is not known; `doctor` output from one would say.
- **Copy on iPhone (1.16.1).** `common/copy.tpl` copies synchronously inside
  the tap first on iOS / iPadOS (a selected `<span>`, checked with
  `getSelection().toString()` before `execCommand`), then the Clipboard API.
  Safari refuses the Clipboard API while the page has no focus (after the
  profile download sheet or back from OpenVPN Connect), and the old fallback
  ran after that refusal, outside the tap, with an off-screen read-only
  textarea that iOS does not select. The helper goes inside an open dialog so
  a focus trap cannot steal the selection.
- **No client certificate on purpose:** customers sign in with username /
  password; the server is checked against the CA inside the file and the
  handshake is wrapped in tls-crypt. The profile carries
  `setenv CLIENT_CERT 0` (1.13.1) so OpenVPN Connect stops asking for one.
- **Downloading the file:** customers from the dashboard card; admins from
  the 📥 button on the server's row, which works while OpenVPN is still off and
  whatever the group (`ovpn.profile` lets staff through), with the admin's own
  test login shown under the list.

How it fits the panel:

- **Nodes are not `servers` rows.** The encoded subscription builder would put
  them into every Xray link. Their traffic is logged under the virtual server
  id `900000 + node id` (`OVPN_SERVER_BASE`), with `servername` =
  "OpenVPN · <name>", so the charts, the admin server report and
  `traffic_daily` show them by name.
- **Usage:** the push carries running byte counters per session; the growth
  since the stored counters goes to `user.u` / `user.d` (× the node's `rate`,
  as the panel applies a server's multiplier), `total_data_used` and `t` if
  those columns exist, and raw to `trafficlog`, which is what `PaygJob` bills.
  Counters are compared under `FOR UPDATE` in one transaction, so a resent or
  overlapping push counts once.
- **`trafficlog` and `online_ip` belong to the encoded panel**, so
  `ovpnInsert()` reads `SHOW COLUMNS` and writes only columns that exist,
  filling a NOT NULL column without a default with 0 / '' / now.
- **Who may connect** (`ovpnRefusal()`, the admin dashboard's reading of an
  account): `status = 1`, `expire_in` in the future, not `transfer_enable > 0
  AND u + d >= transfer_enable`, `server_group` in the node's groups (empty =
  all), plus the device limit at login (`iplimit` over `online_ip` of the last
  2 minutes and live OpenVPN sessions). Every push answers the sessions that
  fail this now; the agent kills them. Because `PaygJob` keeps
  `transfer_enable` = what the balance buys, the wallet cut-off works the same.
- **Wallet prices:** `PaygJob::servers()`, `paygServers()` and
  `User::paygHeadroomGb()` include OpenVPN nodes under their virtual ids, so
  each gets a row in the wallet price table ("OpenVPN · <name>") and is free
  while its heartbeat is older than 5 minutes (outage rule). Ledger queries name
  them through `paygLedgerServerJoin()` with an explicit collation, because
  `servers` and the new table may not share one.
- **Credentials:** login `u<id>`, password = 12 characters of
  HMAC-SHA256(`ovpn_secret`, "<id>:<uuid>"), computed in both `Ovpn.php` and
  `User::ovpnPassword()` — **keep the two identical**. Resetting the link
  changes the password. Nothing is stored.
- **Profile:** built by the panel from what the node reported; `ovpnPem()`
  keeps only the marked PEM block, so a node cannot inject directives into
  customers' profiles. No cipher lines (negotiated; a 2.4 client rejects
  `data-ciphers`).
- The agent lets a login in from a 6-hour cache of panel approvals while the
  panel is unreachable, and reports the accumulated counters afterwards.

Tested locally (2026-09-30) with real OpenVPN 2.6 server and client against
MariaDB with stub panel tables: installer on Ubuntu 24.04 (systemd stubbed),
wrong password refused, valid login connected, usage in `user` (× 1.5) and raw
in `trafficlog` with an unknown NOT NULL column, online mark, resent push
counted once, every refusal reason, device limit, quota cut-off killing the
live session and refusing the reconnect, final counters of a disconnect
settled, login from cache with the panel down and catch-up after, wallet ledger
names, all 83 templates compiled with Smarty 3, dashboard card rendered light /
dark / phone.

### Xray node of our own (`node/xray/`, 2026-09-30)

Asked for: an independent backend for the new Xray, because the XMPlus node
logged "WebSocket transport ... is deprecated" (a warning, not an error; Xray
keeps WebSocket, `PrintNonRemovalDeprecatedFeatureWarning`) and the owner
wanted to stop depending on XMPlus's fork.

- **Nothing in the panel changes.** `xray-agent.py` calls the same node API as
  XMPlusDev/XMPlus (`api/xmplus/xmplus.go`): `GET /api/server/<id>?key=` (ETag),
  `GET /api/subscriptions/<id>`, `POST /api/traffic/<id>` (`{"data":[{"subscription_id","u","d"}]}`),
  `POST /api/onlineip/<id>` (`{"data":[{"subscription_id","ip"}]}`). The answer
  shapes, user email format (`n<node>|<email>|<uid>`), SS2022 user keys
  (base64 of the first 16/32 bytes of `passwd`), relay outbounds and the device
  limit formula (`iplimit - ipcount + last report here`, else not let on) copy
  XMPlus. XMPlus's own bug: `mode` / `noSSEHeader` are unexported Go fields, so
  its xhttp `mode` was always empty; ours reads them.
- **Xray is the unmodified release**, as its own unit `digitsell-xray`; the agent
  (`digitsell-xray-agent`) restarts it only when a node's settings or
  certificate change (tested first with `xray run -test`; a refused config
  keeps the old settings for the nodes that broke it). Accounts go in and out
  through `xray api adu` / `rmu`; routing (panel block rules, relay per user,
  sendthrough, device-limit blocks) is replaced as one list with `adrules`
  (without `-append`, which would put new rules after catch-alls).
- **Things current Xray (26.9.30) changed that bit during testing:**
  `allowInsecure` is removed (config error; clients on new cores refuse links
  carrying it - tell admins to turn it off); `freedom` blackholes private / LAN
  targets by default for VLESS/VMess/Trojan/SS (so `block_private` needs no
  rule, and `false` needs an explicit `finalRules` allow); `X-Forwarded-For`
  is believed only with `sockopt.trustedXForwardedFor` (header names that must
  be present, set to CF-Connecting-IP / X-Real-IP / True-Client-IP), otherwise
  behind a CDN every customer has the CDN's address and the device limit
  misfires; mKCP seed / header moved to finalmask; `ocspStapling` only adds
  warnings for Let's Encrypt certs (no OCSP URL) - cert files are re-read hourly
  without it.
- **Usage is never lost:** counters are read with `-reset` into
  `/var/lib/digitsell-xray/state.json` before posting, and cleared per node only
  when the panel accepted them. The last server / subscription answers are kept
  there too, so a reboot during a panel outage still starts every node.
- **Certificates:** lego v5 (`run --renew-days 30`), storage
  `/etc/digitsell-xray/lego/certificates/<domain>.crt`; a self-signed stand-in
  until the real one is had (retried every 10 minutes).
- **Automatic install:** `install.sh` with no options reads XMPlus's
  `config.yml` (`/etc/XMPlus/`, `/root/config.yml`), copies its lego directory
  and runs `lego migrate`, disables (not deletes) `XMPlus.service`, turns BBR on.
- **Not done:** per-user / per-node speed limits (official Xray has none; the
  agent warns). Tested locally against a stand-in panel with the real Xray
  26.9.30 binary: VLESS+XHTTP+TLS, VMess+WS, Trojan+gRPC+TLS, SS2022 and
  SS-AES carry traffic; usage byte-exact per node; add / remove without
  restart; device limit refuses the second address; relay outbounds and rules
  added and removed live; installer / update / uninstall with systemd stubbed.
  Not yet run on a real node server or behind a real CDN.

**First live deploy (2026-09-30, nodes 69 and 74 on one server, Xray 26.3.27):**
`install.sh` with no options migrated from `/root/config.yml` (file-mode
certificates kept, both nodes found); `dxray doctor` all green; 330 accounts
per node; certificates 88 days left (Let's Encrypt, 90 days, given as files -
nothing renews them unless the owner's own tooling does). Findings:

- **The panel's own subscription builder crashed on an xhttp node.** Every
  account that can see that node got HTTP 500 on `/link/<token>` (a ~960 KB
  Whoops page, so it was easy to misread as a CDN or TLS problem; the nginx
  error log has nothing, the exception only appears in the response body).
  `app/Http/Schema/Xray.php` (plain PHP, readable) reads `$item['headerType']`,
  `['alpn']`, `['mode']`... with no check, and its encoded controller leaves
  keys out for xhttp; Whoops makes the notice fatal. Accounts whose group does
  not include the node were fine, which made it look intermittent (phone fine,
  Windows not). Disabling the node in the panel fixed it at once. First guess
  (add `headerType` to the node's network JSON) was wrong - the array is built
  by the controller, not copied from the JSON. Fix: `node/xray/fix-panel-xhttp.py`
  puts defaults in front of `Xray::build()` (`$item += [...]`, keeps keys that
  exist). Tested on the owner's file with bare / full / REALITY / VMess /
  Trojan / SS items; confirmed working live on the panel. Not committed as a
  file: it is the panel vendor's code and this repository is public. A panel
  update that replaces the file removes the fix.
- **Zero traffic right after the swap** was not the agent: no established
  connections on the node ports, scanners reached them (so the firewall was
  open), the certificates were served, XMPlus was inactive. Usage only appears
  once clients actually connect; `dxray status` shows it.
- `dxray doctor` says "something listens on port N" without saying who; the
  check that XMPlus is not the one holding it is `ss -ltnp`.
- `latest_tag` gave Xray 26.3.27 on the server (GitHub's "latest release"
  skips pre-releases); the agent ran fine on it.
- Not checked live yet: Happ picking up the direct-routes profile (the link
  that failed was the panel's own `/link/`, which never carries it), traffic
  and online numbers once customers connect.

### Direct routes for Xray customers (1.17.0)

Asked for right after: "a place for the servers to bypass Iran or chosen sites,
like OpenVPN". In Xray the client app decides what skips the server, so this
is done in the subscription, not on the node: the OpenVPN direct-routes card
got a switch (`xray_bypass`), and `SubInfo.php` sends Happ
`routing: happ://routing/onadd/<base64 JSON>` (DirectSites / DirectIp from the
same Iran toggle and custom lines; format as in MHSanaei/3x-ui's Happ presets).
Turning it off stores `off`, which sends `happ://routing/off` so the pushed
profile stops too. Only Happ reads routing from a subscription; v2rayNG /
V2Box / Shadowrocket users turn on the app's own Iran preset. Only links
served by `?do=sub` carry it. Not tested inside the Happ app itself.

### Gift card redeem (1.8.9)

- **Dialog:** `#redeem_modal` in `view/user/dashboard/order.tpl`, opened by
  `RedeemCard()` from the subscription card. `Redeem()`, `RedeemReset()`,
  `RedeemFail()` are in `dashboard.tpl`; the request is unchanged (POST
  `/portal/redeem`, `code`), `ret 1` switches the dialog to its success view
  and writes `data.money` into `#money` as before. Keys `GiftRedeem*` in all
  three locales.
- The code input is `dir=ltr` monospace with letter-spacing, but only once
  something is typed: the Persian placeholder gets RTL and IRANSans, because
  letter-spacing or a monospace fallback breaks Persian letter joining.
- **Telegram notice:** `app/Jobs/GiftCardNotifyJob.php`, `bin/giftcards.php`,
  every minute in `TaskCommand`, log `storage/logs/giftcards.log`. The redeem
  endpoint is encoded, so the job reads `giftcard_logs` above the watermark
  `giftcard_notify_last_id` (seeded at 78 on the first run, so nothing older
  was announced). The watermark moves before sending: at most once, never
  twice. Customer gets amount + wallet balance if `user.telegram_id` is set;
  the admin chat (`tgjoin_admin_chats`, else `telegramchatid`) gets user, card
  and code. `giftcard_notify` = 0 switches it off.
- Not verified with a real redemption yet - the first real one is the test.
  Backup of the replaced files: `/root/giftcard-backup-20260924-201335/`.

## 7. Things asked for that could not be done, and why

- **More fields on the invoice** (plan size, wallet credit used). The details
  endpoint is encoded and returns only nine values.
- **Admin writing settlement details onto a withdrawal.** Needs a new endpoint;
  never approved, never built.
- **The payment page could not be render-tested** from the tooling — the
  controller rejects synthetic orders. It is compile-checked only. A real
  click-through is the only proof.
- **A "time" badge in the admin plans list.** The list is a server-side
  DataTable fed by an encoded endpoint, so a time plan shows there with the
  topup type. Opening it shows the type correctly.
- ~~A real gateway purchase of a time plan has not been made.~~ **Done.** On
  2026-09-16 a customer bought three days through the gateway on a per-day plan
  and the days landed. `/portal/order/create` accepts a zero-gigabyte package.

## 8. Open items

- **Notices redesign — done in 1.4.4.** User timeline
  (`patch/view/user/notice/notice.tpl`) now shows `notice.title`, cards with a
  colour spine, a date pill and a three-day "new" flag. The latest-notice popup
  on the dashboard was restyled (gradient header, title shown, labelled
  "don't show again" switch — `#noticemodal` and `.modal-check[name=modal-check]`
  kept for the cookie JS). Admin `add/edit` got a two-pane layout, an RTL
  IRANSans TinyMCE for fa_IR, one-click ready-made snippets (also in the
  template menu), and a live preview of the user's popup. Save contract
  unchanged: `#title #status #sendmail #content` (+ id on edit) to
  `/admin/notice/save`. The `template` plugin was already in the stock plugin
  list; the snippet HTML is Persian and brace-free so Smarty leaves it alone.
- **`/portal/switch` crashes.** `switchtoAdmin` dereferences
  `login_session_old`, which is `NULL` in every session on the server. The
  controller is encoded. Proposed fix, **offered and not yet approved**: guard
  the menu link in `patch/view/user/layout/usermenu.tpl` so it only appears when
  `$session->get('login_session_old')` is set, falling back to the admin link.
- **The plan page toggle direction** was flipped in 1.3.3 — confirm it reads
  correctly before assuming it is settled.
- **Security, outstanding:** rotate the server root password and the MySQL
  password (both were pasted into a chat); MySQL listens on `*:3306`; `public/`
  is `root:root` with mode `0777`.
- 14 stale session files sit in `/tmp`; harmless, could be swept by cron.

- **Admin dashboard (2026-09-23):** `user` has a column named `d`, so a
  `SELECT DATE(x) AS d ... GROUP BY d` groups by download bytes, not the day;
  Dashboard.php aliases days as `day` and groups by the expression. A
  "renewal" is any subscription bought by a user who paid for one before,
  because the panel's own `renew` flag is only set by its renew button. The
  traffic chart drops the days before `traffic_daily` existed. The old
  `admin/dashboard/{stats,chart,side}.tpl` are no longer included but left on
  disk; backup of the replaced files: `/root/dash-backup-20260923-121621`.
  Not yet verified by an admin in a real browser session.

- **User dashboard night theme (2026-09-23, released in 1.8.0):** the
  chart code read `data-hs-appearance` on `<html>`, which is never set - the
  header mirrors the theme into `data-hs-theme` - so charts always drew
  light-theme ink on dark cards. Fixed in `isDark()`; night palette added.
  `User::usageStats()` now returns `live`: server ids with an `online_ip` row
  for this user in the last 5 minutes. That server's bar is taller, Gemini-
  gradient, with packets streaming through the track. The days-left bar ends
  in a sparkler (`.sub-fuse`, sparks spawned by a small script, capped by
  their lifetime, off for reduced motion). The owner asked for **no glow or
  blur outside the bars** - halogen colour stays inside the tracks.
  Backup: `/root/userdash-backup-20260923-130021`.
  Menu items in `layout/style.tpl` light up like a lamp on hover (a bulb of
  the item's own `--mc` colour behind the icon, a short flicker, light
  kept inside the pill plus a thin edge halo).

- **Charge wallet (1.11.0) — check on the live panel before switching it on:**
  1. `trafficlog` really carries `datetime` as the insert time and `u`/`d` per
     push (billing reads exactly that).
  2. A customer whose quota is used up (`transfer_enable = u + d`) is really
     disconnected by the nodes, and reconnected when it is raised.
  3. The checkout spends `user.money` for a topup order too; a charge bought
     with some money in the wallet converts that money into charge credit
     (intended once commission lives in its own wallet).
  4. Customers who never had a plan: set `payg_group` so they get servers.
  5. Try one 200,000-toman top-up with a test account end to end.
  6. Status in the apps: open `…/xmplus-patch.php?do=sub&t=<your token>&config=1`
     in Happ and v2rayNG with a test account; confirm the rows and that the real
     servers still connect, then switch `sub_info_enabled` on.
  Tested locally against MariaDB with stub panel tables (credit, bonus, double
  run, billing per server, outage, low/empty/resume, plan back, warnings,
  commission hold/return, migration, admin reports) and in a headless browser
  (wallet card light/dark/phone, charge dialog → order create, admin page).


- **OpenVPN (1.12.0) — check on the live panel before switching it on:**
  1. `trafficlog` / `online_ip` columns: open Settings → OpenVPN, add a test
     server, connect once, then look at the new `trafficlog` row (serverid
     900001) and at the admin dashboard's traffic chart.
  2. That the Xray nodes do not stumble over `online_ip` rows with serverid
     900000+ (they should only read their own).
  3. Put `--panel https://my.digitsell-shop.ir` (not the CDN host) in the
     install command; the CDN may cache or block the node's POSTs.
  4. Set a wallet price for the OpenVPN server if it should differ from the
     default.
  5. Whether OpenVPN gets through from Iran at all on the chosen port /
     protocol (`--proto tcp --port 443` is the usual first try).

## 9. Testing rules learned the hard way

- **Render every page as at least two accounts** — a normal one and an edge
  case. Every check was run as the admin, whose quota is not zero, which is why
  the division-by-zero reached production.
- **Compile templates against a copy of the live `view` tree before applying.**
  Copy `view/`, overlay the release, compile with Smarty. This catches the
  errors that would otherwise show as a Whoops page.
- After applying: render the touched pages and count `Whoops` in the output.
- `php -l` every localization file. A single quote inside a single-quoted
  Persian string has taken the site down before; the installers refuse an
  apostrophe in a value for that reason.

## 10. Version history

| Version | What it did |
|---|---|
| 1.0.0 | First packaged release of everything built through 2026-09-05 |
| 1.0.1 | Let the web user write `storage/patch` |
| 1.0.2 | Read the manifest past GitHub's cache |
| 1.1.0 | Pin each update to one commit SHA |
| 1.1.1 | Hash the bytes GitHub actually ships (CRLF fix) |
| 1.1.2 | Take ownership from the app directory |
| 1.1.3 | Open the session the panel actually uses (`xmplus` cookie) |
| 1.2.0 | Show what the update is doing — dialog, stages, result |
| 1.3.0 | Design the purchase flow; state the purchase verdict |
| 1.3.1 | Stop dividing by a zero quota |
| 1.3.2 | Make the disable-subscription toggle visible |
| 1.3.3 | Turn that toggle the right way round |
| 1.4.0 | Make the invoice a document, and printable |
| 1.4.1 | Print the invoice on one sheet |
| 1.4.2 | Fit the invoice on a phone |
| 1.4.3 | Redesign the user settings page to match the rest of the panel |
| 1.4.4 | Redesign notices: user timeline, latest-notice popup, admin editor |
| 1.5.0 | Add the "time" plan type — sell extra days, fixed bundles or per day |
| 1.5.1 | Hide the rows a per-day purchase generates, and cap time plans per subscription |
| 1.5.2 | Limit a traffic top-up to chosen subscription plans |
| 1.6.0 | Scope time plans and top-ups by server group as well as by plan |
| 1.7.0 | Rebuild the admin dashboard with a health card; per-server traffic on the servers page |
| 1.8.0 | Invite popup with a personal assistant, share bar, friends-only note; one-time Telegram channel gift; user dashboard night theme and menu lamps |
| 1.8.1 | Share buttons keep the invite link at the end of the message (Telegram's share page put it first) |
| 1.8.2 | One-time 1-10 GB gift for linking the Telegram bot (paying customers with a running plan, new links only) |
| 1.8.3 | Gift messages state the new total and end date; congratulation popup on the dashboard; channel recheck every 2 minutes |
| 1.8.4 | Admin chat is told about every new bot link and every Telegram gift |
| 1.8.5 | Dashboard reloads itself when a Telegram gift lands (tggift.poll) |
| 1.8.6 | New sign-in page: split screen on desktop, one-screen card on phones, icon-only social row, no outside CDN |
| 1.8.7 | Night / day / automatic switch on the sign-in page, night by default, shared with the panel's theme |
| 1.8.8 | Sign-in page: the light next to the logo is green |
| 1.8.9 | Gift card redeem dialog redesigned; Telegram message to the customer (and the admins) when a card is applied |
| 1.9.0 | Channel gift without a running plan: a free 100 MB-1 GB plan (was 10-50 GB); MB shown below a gigabyte |
| 1.9.1 | Sign-up page in the sign-in page's design, with a benefits column |
| 1.9.2 | Lighter sign-in page: icon subset instead of Font Awesome, two font weights, static background (~520 KB to ~72 KB) |
| 1.10.0 | Promotions on subscription plans: real percentage discount (list price kept aside), special badge, random GB/day prize per purchase, occasion text, countdown, sales limit, animated badges, Telegram and e-mail notices. Also: `User::sendMail` passes the template its values, queues as JSON and reports failures |
| 1.10.1 | Promotion box visible on the add-plan page from the start (it only appeared after changing the type); announce a promotion to every customer on Telegram and by e-mail |
| 1.10.2 | Plan cards: "special" / discount shown as a big tilted starburst sticker poking out of the coloured cap, animated |
| 1.10.3 | Prize shown as a big sticker too; two stickers side by side when a plan has both; larger badges on the plan page banner |
| 1.10.4 | Promotions posted in a Telegram channel (id in settings, switch per promotion), post kept up to date and marked when it ends |
| 1.10.5 | Purchase prizes shown on the site: "being drawn" note and popup after paying; prize share in gold on the subscription and statistics cards, used first |
| 1.10.6 | Expiry countdown as a neon digital clock, coloured by time left |
| 1.10.7 | Countdown drawn as an old LCD watch face |
| 1.10.8 | Countdown keeps its full width on phones |
| 1.10.9 | Promotion stickers about 30% smaller; sticker theme per promotion (auto = current season, spring/summer/autumn/winter, Nowruz, Yalda, Christmas, Mother/Father/Girl/Boy day, classic) with its colours, ornament and falling particles; an occasion theme fills the occasion text |
| 1.10.10 | Promotion end date: read in the panel time zone, a Solar Hijri date typed into the field (1405-07-10, Persian digits too) is converted, an end time already passed is no longer prefilled, and the form shows the date in the Solar Hijri calendar and warns before saving a past one |
| 1.10.11 | Promotion dates in the Solar Hijri calendar on Tehran time everywhere: the admin end-date field (1405/07/30 23:59), the ended note, and the Telegram, channel and e-mail texts (۳۰ مهر ۱۴۰۵ ساعت ۲۳:۵۹) |
| 1.10.12 | Promotion end date: a Solar Hijri calendar popup (📅, Saturday first, past days disabled, hour and minute, today / no deadline) and "N days from today until HH:MM"; both fill the same field |
| 1.10.13 | Discount up to 100% (free): price written as 0, "رایگان" on the card, the details page and the sticker, "رایگان (۱۰۰٪ تخفیف)" in Telegram/channel texts, and a warning in the form to set a sales limit and try a zero-amount purchase first |
| 1.11.0 | Charge wallet (pay-as-you-go): top up any amount from 200k toman with tiered bonus, plan runs out → usage billed from the balance at each server's price per GB (free while a server is down), plan-ending / low / empty / resumed notices on the dashboard, Telegram and e-mail; admin report of charged / spent / unspent, per-user ledger, manual adjustment; separate commission wallet usable for subscription plans only; status rows in Happ / V2Box / v2rayNG / Shadowrocket (Solar Hijri end date, data left, wallet balance, "update for the live balance"). Off until switched on |
| 1.11.1 | Wallet in the operator-app layout: wallet tile in the subscription card, wallet state at the top of the card while on balance, side panel / bottom sheet with add funds, transactions, prices and settings, toast for billing messages, menu item; admin amounts in toman, minimum any value including 0, save answered with the stored values, GETs bypass the CDN cache, token retry; status rows in the client apps (from the 1.11.0 branch) |
| 1.11.2 | Client apps: the `?do=sub` link no longer sends `subscription-userinfo` when it adds the status rows, so the app's own total / Gregorian expiry bar is gone; Clash / sing-box keep it |
| 1.11.3 | Client apps: the status link sends `subscription-userinfo` with all zeros instead of leaving it out, because the apps kept the old total / Gregorian expiry from their previous update |
| 1.11.4 | Client apps: the status link drops the panel's own "Total:… Used:…" / "Expire:…" info entries from the list, which still showed the Gregorian expiry under the Persian rows |
| 1.11.5 | Client apps: shorter status rows (about 25 characters) so they are not cut off on a phone; end date / days left and updated time / "update to refresh" split into two rows each |
| 1.12.0 | OpenVPN servers on the same subscription: node agent + installer (`node/openvpn/`), login and usage through `xmplus-patch.php?do=ovpn.*`, traffic counted against the plan and billed by the charge wallet, cut-off when the plan or data ends, admin server list with install command, dashboard card with profile download and credentials. Off until switched on |
| 1.12.1 | OpenVPN: `node/openvpn/uninstall.sh` removes a node from its server (agent, OpenVPN config, NAT rules, services; `--keep-ca`, `--purge`); the admin page shows the command |
| 1.13.0 | OpenVPN: the node redirects every port of its protocol to OpenVPN (except ports in use, SSH and `--exclude`), and the ports customers use are chosen in the panel, several allowed with fallback; admin 📥 profile download per server and a test login, working before OpenVPN is switched on. Existing nodes: run the install command again |
| 1.13.1 | OpenVPN: shown inside the apps card for any panel app named OpenVPN (download link / icon / guide edited in the panel's apps list), with server files and login instead of the subscription link; profile says `setenv CLIENT_CERT 0` so OpenVPN Connect no longer asks for a certificate; push errors carry the database message to the agent log |
| 1.13.2 | OpenVPN: `xmplus-openvpn` icon class in the panel's own icon style (`<span class='xmplus xmplus-openvpn fs-15'></span>`) for the OpenVPN app in the client apps list |
| 1.13.3 | OpenVPN: the app picker draws the OpenVPN icon as inline SVG for any app named OpenVPN, since the `xmplus-openvpn` class did not show on the live panel |
| 1.14.0 | OpenVPN: UDP and TCP side by side (`install.sh --proto both`, default), per-server choice in the panel (automatic / both / UDP / TCP) with separate UDP and TCP ports; with both, customers get a combined file (UDP first, TCP fallback) and a UDP-only and TCP-only file. Existing nodes: run the install command again |
| 1.14.1 | OpenVPN: online / offline messages for OpenVPN servers to the admin Telegram chat (`OvpnJob`, every minute), with a switch on the OpenVPN settings card |
| 1.15.0 | OpenVPN: card moved to the Servers page; per-instance status (🟠 part down) so stopping UDP or TCP alone is reported, scheduler last-run line and Telegram test button; bypass (Iranian IPs, custom domains / IPs / networks) as `net_gateway` routes; automatic free install port and customer ports that avoid ports other programs use; automatic certificate for the server's domain with `verify-x509-name` in new files. Nodes: run the install command again (agent 1.4.0) |
| 1.15.1 | OpenVPN: bypass files stay under OpenVPN Connect's profile size limit ("profile is too large"): at most 1200 routes, custom entries first, then the largest Iran ranges (~98.5% of Iran's addresses) |
| 1.16.0 | Affiliate page: 📱 QR code button on the invite link card opens a dialog with the link as a QR code (drawn in the browser, no library), save as PNG, send the image (phones), copy the link |
| 1.16.1 | Copy buttons work on iPhone / iPad after downloading the OpenVPN profile (synchronous copy inside the tap first). OpenVPN nodes on servers that already run Xray or a firewall: live socket skip, atomic redirect, openings kept first and mirrored into iptables-legacy / nftables, `digitsell-ovpn-nat doctor` (run the install command again) |
| 1.17.0 | Direct routes for Xray customers: "Xray customers too (Happ)" switch on the OpenVPN direct-routes card sends the Iran / custom list to Happ with the subscription (`routing` header). `node/xray/`: our own Xray node with the official Xray-core in place of the XMPlus node binary (node files, not copied into the panel) |
