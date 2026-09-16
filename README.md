# XMPlus panel patch — Digitsell

A set of replacement files for an XMPlus proxy-sales panel, plus an in-panel
updater so later releases can be applied from **Settings → Patch updates**
instead of over SSH.

The panel it targets is an ionCube-encoded install: controllers, routes,
middleware and services cannot be read or changed. Everything here lives in the
parts that stayed as plain source — models, jobs, console commands, Smarty
templates and the localization files — plus one standalone PHP file under
`public/`, which nginx serves directly and which therefore needs no route.

## What is in it

| Area | What changed |
|---|---|
| Dashboard | Usage chart rebuilt on ApexCharts with day/week/month/year ranges, per-server split and upload/download/total; subscription card, balance and IP tiles redesigned; apps card rewritten as a guided flow |
| Servers page | QR and copy are real buttons instead of hidden click targets; per-protocol colours; config link shown as text with its own copy button |
| Tickets | Multi-paragraph messages survive, links are clickable, Telegram-style sides, sticker support, staff signature; stored XSS in ticket bodies closed |
| Affiliate | Split into an invite tab and a commission tab; per-referral earnings; withdrawal form with card and IBAN; written cash-out rules |
| Commission | Automatic payout of referral commission with a popup, a log, and cash/credit routing |
| Purchase flow | Plans and payment pages redesigned; currency shown as ریال in Persian |
| Time plans | A third plan type that sells days on their own — fixed bundles or a per-day rate, limited to chosen plans, offered near the end of a subscription |
| Menu | Labelled glass toggle instead of a bar icon, per-item colours, current page marked, works on phones |
| Themes | Dark mode fixed panel-wide (see the note below) |

### The dark-mode note

`hs.theme-appearance.js` swaps stylesheet `<link>` elements and never marks the
document, so no page CSS could ask which theme is active. A small mirror script
in `view/user/layout/header.tpl` stamps the resolved theme on
`<html data-hs-theme>`, and every rule in this patch keys off that. The
attribute is deliberately **not** `data-hs-appearance`: that is the one the
theme script queries to find its stylesheet nodes, and putting it on `<html>`
would break theme switching.

## Installing for the first time

On the panel server:

```bash
cd /tmp
curl -sL https://codeload.github.com/m0000hamad/xmplus-digitsell-patch/zip/refs/heads/main -o patch.zip
unzip -q -o patch.zip
php /tmp/xmplus-digitsell-patch-main/install.php /www/wwwroot/YOUR-PANEL-DIR
```

The installer verifies every file against `manifest.json`, backs up anything it
replaces into `storage/patch/backup-<timestamp>/`, runs the migrations, and
records the version.

Two things it does not do, on purpose:

- **Scheduling.** `app/Console/Commands/TaskCommand.php` ships with an entry
  running `php bin/commissions.php` every minute. If your panel already has a
  jobby schedule, check that the entry survived the file replacement.
- **The commission watermark.** `migrations/003_settings.php` seeds
  `commission_last_affiliate_id` to the newest row in `affiliate`, so nothing
  historical is paid out. If the setting already exists it is left alone.
  **Never lower it** — every referral below it would be paid a second time.

## Updating afterwards

Admin panel → **Settings → Patch updates** → *Download and apply*.

The updater:

1. reads `manifest.json` from the repository,
2. downloads the branch archive,
3. checks the archive's own manifest matches the published one,
4. verifies the SHA-256 of every file before writing anything,
5. copies each file into place, backing up what was there,
6. runs migrations that have not run yet,
7. clears the compiled templates and records the new version.

*Roll back* restores the most recent backup.

### What the updater will refuse

- a request without a logged-in administrator session
- a request without the CSRF token the settings page fetched
- a manifest naming a path outside `app/`, `bin/`, `localization/`, `view/` or
  `public/xmplus-patch.php`
- a path containing `..`
- any file whose checksum does not match the manifest
- an archive whose manifest version differs from the published one

### What it does not protect against

The checksums prove the files arrived intact from **this repository**. They
prove nothing about whether the repository itself is honest. Anyone who can
push here can push code that the panel will fetch and run as the web user. Keep
the repository's write access tight, and if it is public, remember that its
contents are readable by anyone.

## Releasing a new version

```bash
# edit files under patch/
php tools/build_manifest.php 1.1.0 --notes="what changed"
git commit -am "release 1.1.0"
git push
```

`manifest.json` must be rebuilt after any change under `patch/`. A stale
manifest makes the updater refuse the release — which is the safe failure, but
still a failure.

## Layout

```
patch/          files copied into the panel, mirroring its directory layout
migrations/     idempotent PDO migrations, run in filename order, once each
tools/          manifest builder
install.php     first-time installer, run from the shell
manifest.json   version, per-file SHA-256, migration list
```

## Requirements

PHP 7.4+ with `curl`, `zip`, `pdo_mysql` and `hash`; MySQL 5.7+; outbound HTTPS
to `raw.githubusercontent.com` and `codeload.github.com`; the patched files
writable by the PHP-FPM user.

## Caveats

- The patch ships **whole files**, not diffs. If XMPlus itself is upgraded, its
  new versions of these files will be overwritten the next time the patch is
  applied. Re-check after any panel upgrade.
- `localization/*.php` are shipped whole for the same reason: new stock strings
  added by an XMPlus upgrade would be lost.
- The templates carry Persian copy and a Digitsell support handle. Anyone
  reusing this will want to go through `localization/fa_IR.php` first.
