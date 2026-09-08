# Handoff — Digitsell XMPlus panel patch

Living document. **Update it after every change**, alongside the release it
describes.

> This repository is **public**. No password, token, connection string or
> customer data belongs in any file here. Server and database credentials are
> held by the owner and passed in the working session only.

Last updated: 2026-09-06 · installed version **1.4.2** · repo
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
| Purchase flow | Plans, plan detail, checkout and orders redesigned; a verdict popup states the result and survives the redirect |
| Invoice | A real document with seller, buyer, line item and totals; prints on one sheet; readable on a phone |
| Menu | Labelled glass toggle, per-item colours, current page marked, works on phones |
| Themes | Dark mode fixed panel-wide (see above) |

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

## 7. Things asked for that could not be done, and why

- **More fields on the invoice** (plan size, wallet credit used). The details
  endpoint is encoded and returns only nine values.
- **Admin writing settlement details onto a withdrawal.** Needs a new endpoint;
  never approved, never built.
- **The payment page could not be render-tested** from the tooling — the
  controller rejects synthetic orders. It is compile-checked only. A real
  click-through is the only proof.

## 8. Open items

- **Notices redesign — requested, not started.** Both sides:
  `patch/view/user/notice/notice.tpl` (a timeline that **never shows the
  notice's title**, though `notice.title` exists and is filled) and
  `patch/view/admin/notices/{add,edit}.tpl` (plain selects, TinyMCE with no
  Persian defaults). Wanted: colour, better layout, and conveniences for the
  admin writing them — ready-made text snippets and a live preview of how the
  notice will look to users were the intended additions.
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
