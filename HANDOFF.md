# Handoff — Digitsell XMPlus panel patch

Living document. **Update it after every change**, alongside the release it
describes.

> This repository is **public**. No password, token, connection string or
> customer data belongs in any file here. Server and database credentials are
> held by the owner and passed in the working session only.

Last updated: 2026-09-25 · installed version **1.9.0** · latest release **1.9.1** · repo
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
