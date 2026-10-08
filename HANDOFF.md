# Handoff — Digitsell XMPlus panel patch

Living document. **Update it after every change**, alongside the release it
describes.

> This repository is **public**. No password, token, connection string or
> customer data belongs in any file here. Server and database credentials are
> held by the owner and passed in the working session only.

Last updated: 2026-10-08 · installed version **1.9.2** · latest release **1.23.18** · repo
<https://github.com/m0000hamad/xmplus-digitsell-patch>

---

## 1. What this is

`panel.example.com` is an **XMPlus** proxy-subscription panel. This repository
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

---

## 7. Release history

| Version | Changes |
|---|---|
| 1.0.0 | Initial patch release: dashboard rebuild, tickets redesign, affiliate tab, commission payout |
| 1.1.0 | Time plans — a third plan type selling days only, fixed or per-day price |
| 1.2.0 | Plan scoping — limit time plans and top-ups to chosen subscription plans and server groups |
| 1.3.0 | Commission payout redesign — automatic, with popup and ledger |
| 1.4.0 | Invoice redesign, printable, readable on phone |
| 1.5.0 | Time plan per-day mode with minted rows |
| 1.6.0 | Limit traffic top-up to chosen subscription plans |
| 1.7.0 | Admin dashboard rebuild with ApexCharts |
| 1.8.0 | Invite popup, assistant, share bar; Telegram channel gift |
| 1.9.0 | Sign-in page redesign |
| 1.10.0 | Purchase flow redesign — plans, payment pages, verdict popup |
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
| 1.17.1 | The panel's own link builders (`app/Http/Schema`) are fixed automatically so an xhttp node cannot take the subscription link and the Servers page down: once at install (migration 014) and every hour (`bin/schemafix.php`), since a panel update puts the originals back |
| 1.18.0 | Exit location per server: card on the Servers page picks a Tor exit country per Xray server; the node's agent (digitsell-xray 1.2.0) installs tor-geo, starts the country and switches once it answers (`torexit.*`, migration 015) |
| 1.19.0 | Guided node install: `node.list` (servers with their domains / IPs, API key) so `node/xray/install.sh` asks for the panel and key, lists the panel's servers with the ones pointing at the machine marked, asks which nodes it runs (and their certificates), then installs; also for servers moving from XMPlus (`--yes` = old silent path) |
| 1.20.0 | Charge wallet server-group routing: admin selects groups allowed after subscription expiry and a default group for accounts without subscription; invalid groups stay disconnected without wallet spending |
| 1.21.0 | Charge wallet banner: a slim closable bar at the top of every customer page (`view/user/layout/paygbanner.tpl`, included from `usermenu.tpl`) tells people the connection is not cut when the plan ends and the balance pays per GB; wording follows the wallet mode (plan / balance / empty), the button opens the wallet drawer (`#wallet-charge`), close hides it 3 days per mode in this browser. Admin switch `payg_banner` in the wallet settings (default on, migration 017) |
| 1.21.1 | Sign-in and sign-up pages announce the charge wallet (a "new" card at the top of the benefits list, a short line on phones; only while `payg_enabled` is on). Sources in `tools/login/login.src.tpl` and `tools/register/register.src.tpl`, rebuilt with their `build.js` |
| 1.21.2 | Happ direct routes: Iranian services outside .ir (filimo.com, aparat.com, digikala.com, ...) added to the Iran list; `routing-enable` header sent with `routing`. The profile still only reaches Happ through `xmplus-patch.php?do=sub` links, not `/link/` |
| 1.21.3 | Pay-as-you-go charge mint: cancel any pending payg order for the user when a new amount is chosen, so changing the amount on the wallet page always creates a fresh package instead of reusing an old pending order |
| 1.22.0 | PAYG iplimit override: admin sets a connection limit (`payg_iplimit`) applied when a plan expires and the account falls back to wallet balance; server_group stays unchanged from the subscription; 0 = keep package value |
| 1.22.1 | Show wallet state in subscription card immediately after charge (payg balance > 0) instead of waiting for the minute-cron job to switch the mode from plan to balance |
| 1.22.2 | Payg banner now shows balance mode immediately when wallet balance > 0 (instead of waiting for cron job to switch mode from plan to balance) |
| 1.22.3 | Header countdown shows payg balance instead of Expired text when wallet balance > 0 |
| 1.22.4 | Header countdown shows nicer payg balance format (💰 balance · 📶 GB) when wallet balance > 0 |
| 1.23.1 | Wg.php PHP 7.4 compatibility |
| 1.23.2 | WireGuard node installer fixed: wg0.conf generated, ip_forward, bypass-start argument order, NAT + forwarding rules, TCPMSS clamping, rp_filter=2 (agent 1.0.2) |
| 1.23.3 | WireGuard icon (xmplus-wireguard) for the client apps list |
| 1.23.4 | Auto-fallback to SERVER_IP when a node has no host; app-download button in the WireGuard tab |
| 1.23.5 | WireGuard UI text and instruction list on the customer card |
| 1.23.6 | Public keys preserved byte-exact (strtolower had corrupted base64 PublicKey values) |
| 1.23.7 | Live DNS check for a WireGuard node's domain in the admin panel |
| 1.23.8 | Single-slash panel URL auto-fix (protocol error) |
| 1.23.9 | MTU per WireGuard server in the admin panel |
| 1.23.10 | Preshared keys synced to the agent; policy-routing default route fixed; pending-peers query improved |
| 1.23.11 | Pending peers no longer restricted to one node; address reserved again when switching nodes |
| 1.23.12 | Multi-device support: several keys / addresses per account with a shared quota, device manager card, awg auto-detect (migration 020) |
| 1.23.13 | Customer session authentication fixed inside the WireGuard device manager |
| 1.23.14 | High-contrast dark mode for the device manager |
| 1.23.15 | Server-group access strictly enforced: nodes without groups serve nobody, accounts limited to their group's servers |
| 1.23.16 | Site URL resolved from General Settings for promo links and broadcasts |
| 1.23.17 | AmneziaWG: disconnected customers no longer shown online (a peer whose counters do not grow across two pushes is closed); resetting the subscription link now rotates the WireGuard key (stale wg_credential rows repaired, old sessions dropped); obfuscation randomized per file - junk train Jc/Jmin/Jmax varies and optional I1-I3 chains added, on/off by the admin switch wg_awg_chains (default on); agent 1.0.3 reports handshake age (nodes pick it up on their next install run) |
| 1.23.18 | WireGuard liveness switched to **inbound rx growth only**: a peer is live iff its rx counter grew since the previous push, so a closed app whose tx keeps advancing no longer keeps the session online. Online freshness windows (dashboard, per-server, IpCount()) cut from 600/300 s to 120 s. Closed-session rows now preserve their original closed timestamp instead of being refreshed on every push, so they are cleaned up after 24 h. |
