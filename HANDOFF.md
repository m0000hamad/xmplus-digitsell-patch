## Prepared 1.38.8 — editable information rows per subscription link

Owner requested row-level checkboxes and editable subscription information text
at the bottom of Admin → Servers, then clarified that link 1 and link 2 must
be independently configured. The new final card has two separate master switches
and complete row/template controls, with safe sample previews and documented
dynamic placeholders. One admin/POST/CSRF-protected setting write saves both
validated profile configurations atomically. No schema/agent change is needed.

SubInfo keeps account-specific dynamic values and its existing status conditions.
Configured profile links use their own row settings; unconfigured and unprofiled
links retain legacy behavior. All-off cannot resurrect native English metadata
or Shadowrocket STATUS rows. Real connection entries are retained, including
real endpoints with Total/Expire-like labels. Structured configuration bodies
remain pass-through. No real profile settings, tokens, quota, agent, port or
customer account was modified during preparation.

Pure rendering/settings suites, the headless two-card editor test, native Smarty
and loopback HTTP/native serializer tests passed for both profiles. See
SUB_INFO_ROWS.md for behavior, compatibility and validation. Private staging is
/tmp/digitsell-sub-info-rows-check. Final publication/installation checks pending.
The owner explicitly accepted 1.38.8 transfer, publication and panel installation
after the approval block. Final release transfer and actual-runtime PHP lint
passed; the installed source matches the preceding published baseline. Final
publication, native installation and authenticated live checks are next. No
agent update is required.

## Installed and published 1.38.7 — retain native count for nodes without split enabled

Owner clarified that only nodes with the saved per-profile billing/ports
checkbox enabled should render two online-count rows. The admin aggregate API
now returns enabled native node IDs from current billing settings only (not
history or snapshot readiness). The renderer leaves/restores the native count
for all other nodes, including before the first API response. Stale snapshots
cannot keep split display enabled after the checkbox is cleared. No agent,
presence, quota or migration change is needed.

Endpoint tests and headless Edge using real DataTables passed unchecked/native
counts, checked two-row counts, live enable/disable, paging and stale/zero
behavior. Owner explicitly approved transfer, publication and installation.
Source 6d7683022fb0813bec3290f17257aaccb4ef8272 was published to origin/main;
its immutable manifest and all 185 committed-source checksums were verified.
The authenticated native updater installed 1.38.7; backup:
storage/patch/backup-20261031-070648. All 185 installed checksums match.
Authenticated installed=latest=1.38.7, aggregate API, server editor, authorization
and login health checks passed. No profile settings, node agents, ports, rates,
presence tables or schema were changed by this fix. No agent update is needed
for unchecked nodes to regain their native counter.

## Installed and published 1.38.6 — online accounts split by subscription profile

Owner requested two rows in Admin → Servers → online-users column: profile 1
above profile 2. The existing DataTables count cell is now rendered as two
labelled counts without changing row IDs, filtering, pagination or native
online/accounting/device-limit data. Counts are distinct native account IDs per
actual inbound profile; an account connected through both appears once in each.

Agent 1.4.1 retains profile membership from the same successful Xray observation
before merging IPs for shared device limits. Only allowed IPs are reported, and
the native union snapshot is unchanged. An optional profile payload on node.online
updates new aggregate-only node_profile_online rows in the same transaction as
native presence (migration 031). Empty snapshots clear only that node. Legacy
or inactive-profile reports are explicitly unclassified, rather than guessed
from group access or profile selections. No extra account/IP identifiers leave
the new admin-only aggregate endpoint.

Counts refresh every 15 seconds and expire after 60 seconds, including request
latency. Missing/stale/legacy counts display “—”; known empty profiles show 0.
Tooltip marks partial/unclassified data and identifies each configured link.
On old agents or unsplit ports, actual per-link attribution is unavailable and
requires agent 1.4.1 plus separate profile inbounds. No node agent was upgraded
or production port setting changed by this preparation.

Verification: snapshot/endpoint suites, all 33 Linux agent tests, native MySQL
temporary-table membership/count tests and native Smarty rendering passed.
Headless Edge with the actual panel DataTables libraries passed vertical order,
paging, unknown versus zero, stale expiry and script-error checks. Native server
list contract verified: row.id is numeric; online-users data key is count.
Private test staging: /tmp/digitsell-profile-online-check. Owner confirmed final
transfer/publication and panel installation. Source release
4ca6a9e725c2fda07e060f19177d4f13e0a7c6b7 was published to origin/main; its immutable
manifest and all 185 committed-source hashes were verified. The native updater
installed 1.38.6 and migration 031; backup:
storage/patch/backup-20261031-042136. All 185 installed hashes match.
Authenticated status confirmed installed=latest=1.38.6. Live two-row server-list
markup, private aggregate API, migrations, CSRF and anonymous denial, server-edit
controls and login health passed. Installed-code MySQL/Smarty fixtures passed
using connection-local temporary tables. Customer profile configuration and
signing key were unchanged. Agent 1.4.1 is published; no node agent or core was
restarted or upgraded by this deployment. Real split counts require that running
agent and configured profile ports; older/unsplit observations show “—”.
Final documentation publication was interrupted by automatic approval-review
usage exhaustion; the owner requested continuation to finish that step.

## Installed and published 1.38.5 — separate profile ports and traffic multipliers

Owner approved separate ports while sharing one native server/configuration and
quota. The server editor now adds an opt-in checkbox, port and rate per profile
(suggested rates 1 and 4). No port or multiplier is activated automatically.
Activation requires a recent standalone agent 1.4.0 capability heartbeat and
rejects equal/out-of-range or agent-reserved ports. While enabled, legacy
port/listening-port/rate controls are hidden but their values are retained.

Agent 1.4.0 builds two inbounds using the same account credential, certificates,
transport, relay and exit settings. Counter labels distinguish profile/revision;
block/exit/relay rules expand to both ports and online IP limits merge both by
the native account. A rate or port change rebuilds Xray once and reconnects its
users; names/domains alone do not. External firewall/tunnel forwarding remains
the owner's configuration. Other machines were previously elected for the
owner's own updates; publishing this agent does not claim deployment there.

New authenticated node.profileconfig and node.profiletraffic actions use the
existing node API key. Billing revisions are immutable settings snapshots.
Profile batches have durable IDs, retry on failure, and are acknowledged only
after a transaction records replay protection, atomic shared-quota increments,
native weighted traffic logs and raw node bandwidth. Migration 030 adds
profile_traffic_batch; existing native traffic controllers now use atomic
increments so legacy reports cannot overwrite a concurrent profile debit.

Validation: local billing/endpoint/scope/native-model suites passed; all 31 Linux
agent/menu tests passed as root. MySQL temporary-table fixtures passed exact
1x/4x quota, replay deduplication, old-revision rates, and both actual native
controller/schema paths. Native baseline/profile port serializer matrix passed
72 supported Trojan/VLESS direct/relay cases across seven formats; four native
protocol/relay/format combinations are already omitted by the original baseline.
Tests and source staged privately in /tmp/digitsell-profile-billing-check.
Owner explicitly authorized final transfer, publication and panel installation
following the automatic approval rejection. Source release:
dca5b417abc23fd269f67918912d2014e5e984a4, published to origin/main. The immutable
manifest and all 184 committed-source checksums were verified. The authenticated
native updater installed 1.38.5 and migration 030; backup:
storage/patch/backup-20261031-015701. All 184 installed checksums match.
Authenticated updater confirms installed=latest=1.38.5. Live editor port/rate
controls, migration presence, bootstrap, invalid-CSRF denial, unauthenticated
denial and login health passed. Both native billing controller/schema fixtures
and both VLESS relay profile-port fixtures passed against actually installed
code using connection-local temporary tables.
No production profile port/rate configuration or node agent was changed. Agent
1.4.0 is published with this source; install it on the intended machines before
enabling their two ports/rates. Remaining-node updates follow the owner's prior
self-update choice. No node/core restart was performed by this deployment.
See PROFILE_BILLING.md for
activation, accounting, tests and safe rollback/draining requirements.

## Installed and published 1.38.4 — per-profile server names and hostnames

Owner authorized installation on 2026-10-30 and then requested separate server
names so direct/tunnel entries can be distinguished. Every native server edit
page now includes two subscription-profile groups, each with its own display
name and connection hostname, labeled with the configured profile title. The
original address row is hidden; its native input is kept for compatibility with
the encoded save handler. The original name is labeled “نام سرور در پنل”.
Unconfigured hostname inputs start with the existing address; suggested names
append the profile title. All four visible fields are required and saved using
the block's own button. The shared server-save remains independent.

A verified profile request applies that profile's name/address through two
accessors on the native Server model. Both links may contain the same node and
retain its UUID/password, SNI, TLS, transport, port and relay dependency. Legacy
or missing overrides retain the stored native values. Names/domains are stored
per server in existing settings and saved together in one transaction, with
admin/CSRF, server existence, hostname and UTF-8 validation. No schema change,
node restart or production domain/profile selection was performed.

Validation passed: local scopes/endpoints/model tests, both names and empty
fallbacks, four native protocol item constructors and relays, 156 supported
native serializer cases across baseline/both profiles and seven formats, plus
loopback HTTP name/domain separation and disabled/wrong-group/missing-marker
denials. Four protocol/relay/format combinations are omitted by the original
native baseline and are not claimed as newly supported. VMess, Shadowrocket
VLESS and SS assertions decode the extra URI base64 layer. Synthetic database
fixtures are connection-local temporary tables; customer rows stay untouched.

Source release: aaf73382ec8c8c056549ecab9534c32f75037fa8, published to origin/main.
The immutable manifest and all 183 committed-source checksums were verified.
Installation used the authenticated native updater; backup:
storage/patch/backup-20261030-224735. All 183 installed checksums match the
published manifest. Authenticated updater reports installed=latest=1.38.4;
server 25 edit renders both name/domain groups and hides the original address.
Live bootstrap, CSRF denial, unauthenticated denial and login health passed;
customer profile definitions, signing secret and per-server mappings were
unchanged. Deployment/test scratch stays private in
/tmp/digitsell-server-domains-check. No service or node restart was performed.

## 1.38.3 — restore native node capacity during connection incident

Emergency compatibility rollback: 1.38.2 began forwarding global online-IP
occupancy to XMPlus/XMPlusNew agents. The agent subtracts that count from the
node quota and drops account admission entirely on a new node at full quota.
This cannot distinguish a new device from an existing public IP switching nodes.
Reproduced: quota=2, global=2, local=0 produces no client; local=1 produces
capacity=1. Live Turkey logs also showed a two-IP account being constrained to
one local IP. This is a confirmed connection-failure mechanism, not proof of
every reported latency symptom.

Restore the native ipcount=0 API contract, preserving configured iplimit,
existing global over-limit eligibility, expiry, traffic, subscriber groups,
profile links and per-node authoritative presence. No customer account changes
or node/core restarts are required; normal API refresh removes reduced local
quotas. This temporarily forgoes the added cross-node residual allocation and
may again permit aggregate occupancy above a plan limit between polling cycles.
A future global solution must recognize source-IP membership rather than evict
whole accounts based on occupancy alone. Do not re-enable count-only allocation.

Diagnostics: real configs in both profiles exactly matched native link entries
for both reported accounts; all six endpoints accepted TCP and verified TLS
from the panel. Turkey has no request-count cap, no listen drops/overflow and
no recent agent/core restart. TLS handshake timeouts were also observed but
cannot be attributed to this quota regression or a particular customer.
Regression: both API suites cover stable full-quota admission, intact per-node
limits, existing over-limit exclusion, unlimited accounts and stable caching.
Published source: 772a1e94275bfe6ed25ab7e7b258575a0dbd9c40, verified against
origin/main and the immutable raw manifest. Two controller files installed
atomically after checking their prior hashes; backup:
storage/patch/backup-20261030-131142-subprofiles. Native PHP regression passed
against installed files. Authenticated updater reports installed=latest=1.38.3;
profile settings unchanged. From the Turkey machine, both live subscriptions
APIs returned ipcount=0 for all 339 accounts, including all reported accounts.
No node/core restart was performed. End-user latency recovery remains unconfirmed.

## 1.38.2 — online presence and global IP count propagation

Approved follow-up (agent 1.3.2): old authenticated
TCP sessions survive HandlerService account replacement. Targeted recovery for
the two reported accounts cleared their old sessions without restarting other
users. Agent fix detects UUID/password rotation even when IP admission masks the
new client and collects usage before one Xray restart per changed batch. The
restart briefly reconnects all users in that Xray process; the owner explicitly
approved activation and one-time Xray cleanup on 2026-10-29. Startup now restores
this node's own online-IP share before admission, preventing full-quota users
being evicted merely by an agent restart. All 24 node tests pass. Owner will
update the other machines personally. Published agent source: 87226aa. Turkey
is running agent 1.3.2 with healthy S3/S5 services; the approved one-time core
restart completed, and credential-revocation restarts were observed in the live
log. The full native panel updater applied 1.38.2 from published source, backup
storage/patch/backup-20261030-003519 (server-generated name). Authenticated status
confirms installed=latest=1.38.2, uptodate=true; GET /login returns 200. Other
machines were not restarted by this chat after the owner elected to handle them.
See ONLINE_PRESENCE.md.

2026-10-29 online-presence hotfix: native ingestion now scopes membership to
user + IP + server instead of letting a heartbeat move a shared-IP row between
countries. Authenticated node.online snapshots clear only the reporting node,
including on empty reports. Agent 1.3.1 reports presence independently at 15 s
and never refreshes cached users after a stats API failure. See
[ONLINE_PRESENCE.md](ONLINE_PRESENCE.md) for deployment, rollback and tests.

XMPlus and XMPlusNew subscription APIs now return the calculated active global IP count instead of constant zero. This restores the existing node-agent contract for remaining device capacity across nodes. Existing expiry, traffic, group, verification and over-limit admission rules are unchanged. Dashboard continues reporting distinct observed IPs; IPs are not physical device identities. Polling and node enforcement still apply, so this is not an atomic connection reservation system.

Regression: tools/ip-limit-api-test.php passes for both shipped controllers (empty, partially occupied, full, over-limit and unlimited accounts, plus count-sensitive response caching). The online snapshot PHP suite and all 24 Python tests pass. The online-presence hotfix is deployed on the panel and Turkey agent; its real disconnect test passed. The full 1.38.2 package, including global IP counts, has now been installed through the native updater and verified against the published version. Publication authorized by the owner on 2026-10-29.

# Handoff â€” Digitsell XMPlus panel patch

Installed and published 2026-10-28: **1.38.1** layout follow-up: dashboard subscription titles and multiline
descriptions now sit inside their respective link cards. Both cards are adjacent;
the connection heading, application download/help actions and how-to render once
per app. Native Smarty/DOM regression verifies title-description order, adjacent
cards, no download inside either card, one shared download below both, correct
profile copy/import URLs, disabled/group scoping and legacy behavior. Only the
dashboard template changes at runtime; profile settings and access are unchanged.
Live customer dashboard verification passed for the two titled/described cards
and single download below them. The updater reports installed=latest=1.38.1.
Backup: storage/patch/backup-20261028-200011-subprofiles.

Installed 2026-10-28: **1.38.0**, two independently configurable subscription
links with editable titles and multiline descriptions, subscriber-group and
server-ID selection, per-profile customer/admin copy/import blocks and signed
native-query filtering. Relay transport lookups stay private; managed refresh
URLs retain their profile. Unconfigured installations keep the old link.
The owner explicitly approved server transfer/testing/installation after the
initial automatic approval rejection. Local suites, native baseline/both-profile
serializer matrix (URI, Shadowrocket, Surfboard, Stash, Clash, Meta, sing-box),
loopback HTTP filtering/denial tests and native Smarty rendering passed. Live
admin settings rendering, real auth/CSRF/validation and invalid-token denial
passed. No production profile/group/server selection was changed; the owner
must configure the new Settings → لینک‌های اتصال card. No migrations.
Backup: storage/patch/backup-20261028-193347-subprofiles. Installed metadata and
rollback pointer updated. Publication follow-up: this release includes the
complete source, manifest and version for the updater repository. AGENTS.md now
requires publication plus matching live installed/latest status before any
future release is reported complete. Live authenticated updater verification
confirmed installed=latest=1.38.0 after publication. See SUBSCRIPTION_PROFILES.md.

Living document. **Update it after every change**, alongside the release it
describes.

2026-10-27 node-selection follow-up: Add now reads the source XMPlus YAML even
when agent.json already exists. Discovery checks the remembered source_config,
standard XMPlus/root paths and the current directory; --from selects a custom
file. Imports record source_config for subsequent additions. Display labels mark
installed, YAML and newly configured nodes alongside all other panel nodes.
Enter defaults to the installed/YAML ID union; Enter confirms additions, q cancels.
New YAML nodes retain API credentials, certificate/key paths (relative to YAML
when needed) and enabled fallbacks; existing node objects are never overwritten.
The installer now always includes PyYAML, also during updates. No customer
configuration or credentials were copied into the repository. Validation: all
13 Linux tests pass, including a synthetic multi-node YAML fixture added through
the actual CLI with two blank answers, real agent parsing, certificate references,
private backup, single agent restart and firewall handling. Bash syntax passed.

2026-10-27 follow-up: menu Install and dxray install now use --reuse-config,
preferring installed agent.json and otherwise discovering XMPlus YAML (both
extensions under /etc/XMPlus, /usr/local/XMPlus, /root or the working directory).
Only a missing configuration enters guided setup; explicit menu 17 / dxray setup
retains the reconfiguration wizard. Explicit --from supports custom YAML paths.
YAML certificate/key references resolve relative to that file and fail clearly
if missing instead of being silently dropped. Existing node configuration is
retained when an old XMPlus YAML also exists.
Validation: all eleven Linux tests pass, including agent/YAML discovery
precedence, missing-config setup fallback, relative certificate paths and an
explicit error for a missing referenced private key. Bash syntax passed.

2026-10-27: Xray standalone installer now opens a management menu by default,
including on installations with an old dxray command. The bootstrap fetches the
current CLI and node manager; explicit installer flags retain their old behavior.
Installed dxray defaults to the same menu. Add/remove membership is separate from
binary installation, preserves existing per-node objects, checks additions against
the panel and port conflicts, confirms changes, writes private atomic config and
backup files, detects concurrent edits and rolls back if restarting the agent
fails. Removal affects this machine only and cannot leave an empty node list.
Menu offers lifecycle, status, recent/live logs, diagnostics, update, configuration
and confirmed uninstall with keep-config/restore-XMPlus options. No panel release
version change: these standalone node files are fetched directly from main.
Validation: nine Linux unittest cases passed under WSL, including PTY tests for
the /dev/fd process-substitution entry point, cancellation of stop/uninstall,
headless-menu refusal, real agent parsing, per-node credential/override retention,
port conflict and last-node guards, private backups, rollback and concurrent-edit
detection. Bash syntax and git diff whitespace checks passed. The node server was
unreachable by SSH during this change; no production configuration was modified.

> This repository is **public**. No password, token, connection string or
> customer data belongs in any file here. Server and database credentials are
> held by the owner and passed in the working session only.

2026-10-26: owner confirmed the 1.37.1 save fix works. Repository synchronized
with upstream 1.34.0 before publication, preserving its existing features.
Deployment scratch files are excluded from Git.

Installed 2026-10-26: **1.37.1**, filter all balance-edit/CSRF metadata out of the
native user-save body. Full browser payload regression now verifies successful
saving and unchanged user token. The reported failed wallet edit was rolled
back; no actual balance was modified by the agent. See
[ADMIN_USER_BALANCES.md](ADMIN_USER_BALANCES.md).

Installed 2026-10-26: **1.37.0**, separate editable usage-wallet and total
commission fields on Admin → Users → Edit. Native profile saving and balance
adjustments are atomic, source-isolated, primary-admin-only for money, audited
and guarded against stale snapshots/retries. Migration 029, native integration
tests and live read-only health passed. No real balance changed. Details:
[ADMIN_USER_BALANCES.md](ADMIN_USER_BALANCES.md).

Installed 2026-10-26: **1.36.3** separates legacy `user.money` commission from
the usage wallet in both payment-source quotes and reservations. Both source
checkboxes remain visible; zero balances are disabled (1.36.2). Source isolation
and exact-source refunds tested, including read-only checks on the named test
account. No balance migration. See [CHECKOUT_FUNDS.md](CHECKOUT_FUNDS.md).

Installed 2026-10-26: **1.36.1**, explicit optional wallet/commission funding on
the payment page, transactional reservations, native gateway remainder and
exact-source cancellation refunds. Includes the immediate Smarty literal fix
for the commission shim; package page verified in browser. Architecture, backup,
validation and operational limits: [CHECKOUT_FUNDS.md](CHECKOUT_FUNDS.md).

2026-10-26 operational reconciliation: with explicit owner approval, the
principal of one paid service invoice was credited to its owner's usage wallet.
The invoice/order/payment records were retained. Wallet balance and charged
total changed atomically with a `charge` ledger entry using the native `order:`
reference to prevent duplicate credit; gateway fees and bonuses were excluded.
The private before-state backup is under `/root/digitsell-invoice-credit-*`.
This was a one-time correction; future service invoices still collect fees for
services and do not automatically charge wallets.

Installed checkout repair 2026-10-26: **1.35.2** fixes cold-request database and
translation initialization and keeps checkout JSON clean. Regression starts
without a preloaded console; native gateway page verified for the affected
invoice. See [INVOICES.md](INVOICES.md).

Installed repair 2026-10-26: **1.35.1** restores invoice dispatch removed by an
upstream update and guards against incompatible archives. Customer/plan/period
dropdowns verified in the user's browser; see [INVOICES.md](INVOICES.md).

Installed 2026-10-26: **1.35.0**, admin-issued service/subscription/renewal invoices,
customer alerts, existing email/Telegram channels and native gateway checkout.
Scoped installation over live 1.34.0, preserving reservations/card-to-card;
migration 027 and full database/file backup. Live invoice API health passed.
Usage, architecture, validation, backup and installation: [INVOICES.md](INVOICES.md).
Invoice installation ownership repaired the same day: eight affected files now
www:www/0644; updater write access verified as the PHP-FPM worker.

> This repository is **public**. No password, token, connection string or
> customer data belongs in any file here. Server and database credentials are
> held by the owner and passed in the working session only.

Last updated: 2026-10-24 Â· installed version **1.9.2** Â· latest release **1.32.2** Â· repo
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
  Several requests have had to be scoped down for this reason â€” see Â§7.

## 3. Repository shape

```
patch/          mirrors the panel's own directory layout; copied in verbatim
migrations/     idempotent PDO migrations, run once each, in filename order
tools/          build_manifest.php â€” regenerates manifest.json
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
git commit -am "release 1.4.3 â€” ..."
git push
```

> **A release must land on `main`.** The updater reads the commit `main` points
> at, and only that (see Â§4). Work committed to a side branch â€” a worktree
> branch like `kilo/...`, a `claude/...` branch, any PR branch â€” is **invisible
> to the panel** until it is merged into `main` and `main` is pushed. Push the
> release to `main` (or merge the branch into `main` with a fast-forward and
> push), and confirm `git branch -r --contains <commit>` lists `origin/main`.
> The updater's `DEFAULT_BRANCH` is `main` (`patch/public/xmplus-patch.php`);
> only a `patch_branch` setting on the server could point it elsewhere.

**1.24.0 got this wrong once.** The plan-reservation release was committed and
pushed to the worktree branch `kilo/add-plan-reservation-capability`, so
Settings â†’ Patch updates saw nothing to update. Fixed by fast-forwarding
`main` to that commit and pushing `main`; `origin/main` and the release commit
are the same tree. If a release seems to have "not arrived" in the panel, check
this first: `git log --oneline origin/main..HEAD`.

**Pick one path, not both.** Either push the release straight to `main`, or
open a PR from the branch and merge it into `main` â€” do not do both. Once `main`
already holds every commit of the branch (`git log --oneline origin/main..HEAD`
is empty), GitHub refuses the PR with *"No commits between main and â€¦"*: there
is nothing left to merge. An empty PR like that is not an error to fix; the
release is simply already on `main`.

The manifest **must** be rebuilt after any change under `patch/`, or the
updater refuses the release. That is the safe failure, but still a failure.

On Windows the clone needs `core.autocrlf=false` (already set here) and the repo
carries `.gitattributes` with `* -text`: the manifest hashes exact bytes, and a
line-ending rewrite makes a correct release fail its own checksum.

## 4. The in-panel updater

`patch/public/xmplus-patch.php`, reached at `/xmplus-patch.php`. Admin UI is
**Settings â†’ Ø¨Ù‡â€ŒØ±ÙˆØ²Ø±Ø³Ø§Ù†ÛŒ Ù¾Ú†** (`patch/view/admin/settings/patchsettings.tpl`).

Flow: ask the GitHub API which commit `main` points at â†’ read `manifest.json`
**at that SHA** â†’ download the archive **at that SHA** â†’ verify every file's
SHA-256 â†’ back up what it replaces into `storage/patch/backup-<stamp>/` â†’ copy â†’
run new migrations â†’ clear `storage/smarty/compile` â†’ record the version.

Refuses: a request without an admin session; without the CSRF token that
`?do=status` issues; a manifest naming a path outside `app/ bin/ localization/
view/ public/xmplus-patch.php`; any path containing `..`; any checksum mismatch.

Auth is checked twice â€” the session must claim `is_admin`, **and** the account's
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
| PHP | 7.4 Â· MySQL 5.7 Â· nginx via aaPanel |
| Session cookie | **`xmplus`**, not `PHPSESSID` |
| Session store | files in `/tmp/sess_*`, owner `www` |
| DB config | `config/config.php`, `$DB` array |
| Public hostname | `p.digitsell-shop.ir` â€” **behind an Iranian CDN** |
| Direct hostname | `my.digitsell-shop.ir` â€” resolves straight to the origin |
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

### Dark mode â€” the single most load-bearing detail

`hs.theme-appearance.js` swaps stylesheet `<link>` elements and **never marks
the document**, so `html[data-hs-appearance="dark"]` matches nothing. A mirror
script in `patch/view/user/layout/header.tpl` stamps the resolved theme on
`<html data-hs-theme>`, and **every dark rule in this patch keys off that**.

Do not reuse the name `data-hs-appearance` on `<html>` â€” the theme script
queries that attribute to find its stylesheet nodes, and theme switching breaks.

## 6. What the patch changes, by area

| Area | Summary |
|---|---|
| Dashboard | Usage chart on ApexCharts (day/week/month/year, per server, up/down/total); subscription card, balance and IP tiles; apps card as a guided flow; Telegram link row |
| Servers | QR and copy as real buttons; per-protocol colours; config link as text |
| Tickets | Paragraphs survive, links clickable, Telegram-style sides, stickers, staff signature; **stored XSS closed** |
| Affiliate | Invite tab and commission tab; per-referral earnings; withdrawal form with card and IBAN; written cash-out rules |
| Commission | Automatic payout, popup, ledger, cash/credit routing |
| Invites | Dashboard invite popup in three stages with an "assistant" quoting the visitor's own numbers; ready-to-send invite message with share buttons on the affiliate page; friends-only note. Released in 1.8.0 â€” see below |
| Telegram channel gift | One-time weighted gift for new channel members (GB on a running plan, a free plan otherwise), `TgJoinJob`. Released in 1.8.0 â€” see below |
| Purchase flow | Plans, plan detail, checkout and orders redesigned; a verdict popup states the result and survives the redirect |
| Admin dashboard | Rebuilt on ApexCharts from one read-only call, `xmplus-patch.php?do=dashboard.overview` (`app/Patch/Dashboard.php`): KPI cards with sparklines and deltas, daily revenue by kind, 12-month trend (Solar Hijri months for fa_IR), sales mix and gateways, top plans, weekday x hour heatmap, user status, 14-day expiry pipeline, sign-ups, traffic by day and server, node table, latest paid orders, and a system health card (DB, nodes, cron locks, trafficlog freshness, 24h paid rate, disk, load, cache dir, unapplied time orders, patch version). Released in 1.7.0 |
| Invoice | A real document with seller, buyer, line item and totals; prints on one sheet; readable on a phone |
| Settings (user) | Gradient hero, glass section rail with a colour per section and the current one lit, cards carrying that accent; notification rows became switches; 2FA dialog restyled; every input id, button class and section anchor kept so the encoded controller and page JS are untouched |
| Notices | User timeline shows the title and reads as coloured cards; latest-notice popup restyled with a labelled dismiss switch; admin add/edit got RTL Persian TinyMCE, one-click snippets and a live user-popup preview |
| Time plans | A third plan type selling days only â€” see the section below |
| Card to card | A manual payment method the encoded gateway list cannot hold: several receiving cards, each with its own cap, rotating automatically; a transfer form on the checkout; approval on the site or from the Telegram message; automatic package grant and a confirmation banner. Off until switched on - see the section below |
| Reserved plans | Buy a subscription now, have it start later (after the current plan ends, or on a chosen date) â€” see the section below |
| Menu | Labelled glass toggle, per-item colours, current page marked, works on phones |
| Themes | Dark mode fixed panel-wide (see above) |
| Gift cards | Redeem dialog redesigned, Telegram notice on redemption (1.8.9) - see below |
| Sign-in page | `view/auth/login.tpl` redesigned (1.8.6) â€” see below |
| Sign-up page | `view/auth/register.tpl` in the sign-in page's design (1.9.1) â€” see below |

### Time plans â€” how days are sold without touching the order pipeline

A time plan is **not** a new package type. It is an ordinary topup package
(`package.type = 1`, `bandwidth = 0`) whose `order_note` carries a marker, a
field nothing renders for type 1:

```json
{"timeplan":{"v":1,"mode":"fixed","days":7,"applies_to":[2,3]}}
{"timeplan":{"v":1,"mode":"perday","price_per_day":150000,"min_days":1,"max_days":60,"applies_to":[]}}
{"timeplan":{"v":1,"mode":"minted","days":12,"parent":41,"created":1789537529,"applies_to":[]}}
```

That keeps checkout â€” coupon, gateway, invoice, order history â€” inside the
panel's own encoded code: the browser posts `plan: "topup"` with the package id
to `/portal/order/create`, exactly as "add data" does. `applies_to` empty means
every plan. A `perday` row is a parent and is never bought directly; picking N
days calls `timeplan.mint`, which finds or creates a `minted` row priced at
N Ã— the daily rate, so the row count is bounded by `max_days`. Unsold minted
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
  before wiping, and the grant restores it â€” only when the snapshot's
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
- Smarty's `{$x = ...}` assignment rejects ternaries â€” `edit.tpl` uses `{if}`
  blocks to unpack the marker.

### Limiting a traffic top-up to certain plans

Same idea, different storage. A top-up is saved through the encoded
`/admin/plan/save`, which rewrites `order_note` on every save, so the marker
trick would be wiped. The scope lives in one settings row instead:

    timeplan_topup_scope = {"7":[18,19],"8":[]}

package id â†’ the subscription packages it is offered on; missing or empty means
everyone, which is what every pre-existing top-up is. The page writes it with
`timeplan.topupscope` right after the encoded save returns, identifying a brand
new package by name because that save does not report the id.

`Package::topupList()` and `topupAllowed()` do the filtering, and
`Package::scopeViewer()` deliberately returns null for staff â€” the admin pages
list top-ups too and must keep seeing all of them.

### Two scoping dimensions, not one

Both a time plan and a top-up can be limited by **subscription plan** and by
**server group**, independently. Each list is open when empty, and both have to
pass. The group is matched against `user.server_group` â€” not `user.user_group`,
which is the staff permission role and has nothing to do with this.

A time plan keeps `groups` in its marker next to `applies_to`. A top-up cannot,
for the reason above, so it gets a second settings row alongside the first:

    timeplan_topup_groups = {"7":[3,8]}

Both rows are written by the same `timeplan.topupscope` call.

### Reserved plans â€” buy now, start later

A customer can reserve a subscription plan at checkout: the money is paid
today and the plan starts later, either **after the current plan ends** or on a
**chosen date**. Same trick as the time plans: the panel's checkout and the code
that applies a subscription are encoded, so a reserved plan is sold as an
ordinary traffic top-up (`type = 1`, `bandwidth = 0`) whose `order_note` carries
a marker, and the subscription is started afterwards by `bin/reserve.php`.

```json
{"planreserve":{"v":1,"plan":41,"cycle":"month","days":30}}
```

- One package row per `(plan, cycle)`, named `Ø±Ø²Ø±Ùˆ <plan> - <cycle>`, priced at
  the plan's price for that cycle as it stands at mint time (a running
  promotion's discounted price included). It is hidden from the customer's
  "add data" list (`Package::topupList()` drops `RESERVE_MARKER`) and from the
  admin plan list (added to `generated` in `TimePlan.php`).
- `plan_reserve` (migration 021) holds the reservation: the buyer, the plan and
  cycle, the plan's numbers (so it survives the plan being edited or switched
  off), the mode and date, and the state â€” `0` prepared/unpaid, `1` paid and
  waiting, `2` started, `3` cancelled.
- `app/Jobs/ReserveJob.php` (`bin/reserve.php`, scheduled every minute from
  `TaskCommand`) links each paid reserve order to its reservation (rebuilding it
  from the marker if the intent is gone), then starts the subscription once the
  current plan has ended **and** the chosen date has come â€” the "replace when
  the current plan ends" rule the owner chose. Starting is the same fresh-plan
  write `TgJoinJob` uses (`packageid`, `plan`, `server_group`, `iplimit`,
  `speedlimit`, `transfer_enable = bandwidth * GiB`, `u = d = used = 0`,
  `expire_in = now + days`), and the reserve order is turned into the
  subscription order it really was (`packagetype = 2`, `plan`, `plan_expire`,
  `expire`), leaving `pay_date` where the money changed hands.
- A conditional `UPDATE ... WHERE status = 1` claims each activation, so two
  overlapping runs can never start the same plan twice.
- **Only one reservation per customer.** Cancel (before it starts) refunds the
  full amount into `user.money` â€” the payment is not reversed, it becomes store
  credit, which is what the owner asked for. The reservation row is claimed
  first, so a second request can never refund twice. An unpaid check-out older
  than an hour is dropped, and an unpaid intent never blocks a fresh one.
- The user half answers ordinary users and therefore rides the `reserve.*`
  dispatch in `public/xmplus-patch.php` **before** the blanket `requireAdmin()`;
  it has its own CSRF token, `$_SESSION['reserve_csrf']`, handed out by
  `reserve.mine`. `reserve.prepare` re-checks everything server-side.
- Visibility and the date horizon are two settings, `reserve_enabled` (1) and
  `reserve_max_days` (365), edited in Settings â†’ Plan reservations and read by
  `User::reserveFeatureOn()`. `User::planReserveWaiting()` draws the dashboard
  card (`view/user/dashboard/reservecard.tpl`, included from `subsciption.tpl`):
  plan, cycle, days, quota, when it starts, amount paid, cancel.
- **A reservation announces itself in three places, at both moments** â€” when it
  is taken and when it starts. The dashboard half is the `reserve_notice` table
  (migration 022): `view/user/layout/reservebanner.tpl`, included from
  `usermenu.tpl` right after the wallet banner, draws the unseen rows on every
  customer page and its close button posts `reserve.ack`. The other two are
  Telegram and e-mail, sent by `ReserveJob` through the panel's own bot and
  `Queue`. The unique key on `reserve_notice.ref` is the guard for all three, so
  nothing is sent twice.
- `User::planReserveWaiting()` first calls `ReserveJob::linkForUser()` (once per
  account per request), so a just-paid reservation is linked on the first page
  load after the gateway rather than waiting for the cron â€” the card and the
  banner are there the moment the customer is back.
- The plan page (`view/user/plan/plan-details.tpl`) gained a "Ø±Ø²Ø±Ùˆ Ù¾Ù„Ù†" card;
  when it is on, Checkout calls `reserve.prepare` and then posts the minted row
  to `/portal/order/create` with `plan: "topup"`, exactly as the "add data"
  flow does.
- The reserve order sends **`disableactive: 1`**, and that is deliberate. The
  encoded checkout refuses *any* order while the account has a running plan
  unless this flag is set â€” that is the "Ø§Ø´ØªØ±Ø§Ú© ÙØ¹Ø§Ù„ Ø¯Ø§Ø±ÛŒØ¯" (you have an active
  subscription) it answers with otherwise. For a `type 1` top-up the flag is
  ignored, so nothing is cancelled; every customer top-up flow on the panel
  sends it too ("add data" `dashboard.tpl:751`, "add time" `dashboard.tpl:971`,
  wallet charge `wallet.tpl:794`). Sending `0` here is the bug the 1.24.1 fix
  undid: reserving was impossible while a subscription was running. The
  customer's own "cancel my plan" switch is only *hidden* in reserve mode; its
  state is left untouched and the reserve order never acts on it.

- At checkout (iew/user/pay/cycle.tpl, included from pay/pay.tpl) the balance (AccBalance, alue=-1) is shown above the gateways whenever user.money > 0, pre-selected when it covers the order's 	otal_amount. The buy button then posts method=-1 to /portal/order/pay, the same wallet-balance path the panel already uses (Order::gateway(-1)), so a refunded reservation credit is consumed automatically and the user is not sent to a gateway when the balance is enough.

### Card to card - a manual gateway the encoded checkout cannot have

Files: `app/Patch/Card2Card.php` (customer + admin + the Telegram decision
page), `app/Jobs/Card2CardJob.php`, `bin/c2c.php`,
`migrations/025_card2card.php`, `view/user/pay/card2card.tpl`,
`view/user/layout/c2cbanner.tpl`, `view/admin/settings/c2csettings.tpl`,
`User::cardToCardNotices()`.

The panel's payment drivers are ionCube encoded, so `/portal/order/pay` cannot
be taught a new one. The checkout page can be patched: `card2card.tpl` adds a
fourth choice to the gateway grid and takes over the Pay button. The order is
still the panel's own, created by `/portal/order/create`; it simply stays
unpaid while the transfer waits.

- The customer transfers the exact `orders.total_amount` to the card shown and
  records the last four digits of their own card. That is the whole declaration:
  the bank SMS already carries the name, the time and the reference, so payer
  name, transfer date/time and reference live in an optional "more details"
  section (pre-filled, editable) and may stay empty. There is one request per
  order (`c2c_request.orderid` UNIQUE); a rejected one can be corrected and
  sent again.
- Cards rotate (`c2c_card`): each carries an amount cap and/or a count cap,
  measured per day / per month / in total (0 = no cap). The checkout always
  shows the first enabled card in `sort` order that still has room, and moves
  to the next one by itself. Pending requests count towards a cap too, so a
  burst of transfers cannot overrun a card before anyone is approved.
- The administrator gets a Telegram message with everything needed to match
  the transfer. With a **dedicated bot** (`c2c_bot_token`, optional) the two
  buttons are callbacks: `setWebhook` points that bot at
  `xmplus-patch.php?do=c2c.tgwebhook`, the update is verified by the secret
  header Telegram sends, the callback payload is `c2c|a|id|sig` where `sig` is
  an HMAC with `c2c_bot_secret`, only chats in `c2c_telegram_chat` may decide,
  and approve/reject happens on the spot, removes the buttons and shows a
  toast. Without a dedicated bot the buttons are one-tap URL links to
  `c2c.decide` (the request's own 64-hex token, 7 days, one decision).
  Approving from Settings -> Card to card does the same.
- Approval marks the order paid (`status = 1`, `pay_date`, `gateway_name`) and
  grants what it bought. Time plans, reserved plans and pay-as-you-go charges
  are left to their own jobs, which watch for a paid order; a plain top-up
  adds its gigabytes. A subscription follows the plan's `renew_type` when the
  order is a renewal (`c2c_grant_mode = fresh` forces a fresh plan). The
  request row is claimed first, so overlapping approvals can never grant
  twice.
- **A transfer takes longer than a gateway redirect.** The panel's `UserJob`
  cancels an unpaid order once `gateway_expire` passes, so `Card2CardJob`
  keeps moving that window ahead while a request waits (`c2c_hold_hours`,
  default 48) and brings a `-1` order back to `0`. `c2c_reject_hours` (72)
  auto-rejects a request nobody looked at.
- The outcome reaches the buyer three ways: the pay page polls `c2c.status`,
  `c2c_notice` drives `c2cbanner.tpl` on every customer page (its close button
  posts `c2c.ack`), and Telegram/e-mail are sent by the job. The notice `ref`
  includes the decision time, so a rejected-then-approved request leaves two
  rows instead of colliding.
- Paid still means `orders.status = 1`; `orders.state` is not used here (it is
  0 on almost every row, as noted above).

Settings: `c2c_enabled` (off until switched on), `c2c_telegram_chat`
(fallback: `telegramchatid`), `c2c_note` (text under the transfer form),
`c2c_reject_hours`, `c2c_hold_hours`, `c2c_grant_mode` (`auto` / `fresh`),
`c2c_site_url` (fallback: `appName` / `baseUrl`).

Watch out for these:

- `c2c.info` hands out the full card number only with one of the caller's own
  orders; without an order it returns no card. The banner's close button calls
  it only for the CSRF token.
- The Pay button only carries the panel's `.checkout` class when a gateway
  exists. `card2card.tpl` binds its own click handler for the gateway-less
  case, and `Gatewayfee()` answers `c2c` locally (no fee, the full total) -
  the encoded fee endpoint has no row for it.
- Do not create a `payment` row for card to card. The encoded gateway list
  would offer it at checkout and try to load a driver that does not exist.
- The Telegram approve/reject action runs on the first request: with a dedicated
  bot it is a callback answered by the webhook; without one it is a one-tap GET
  to `c2c.decide`, whose 64-hex token is the credential. Do not add a second
  confirmation step - the owner asked for one tap.
- The webhook (`c2c.tgwebhook`) is public, so it trusts nothing but the
  `X-Telegram-Bot-Api-Secret-Token` header, the callback HMAC, and the chat id
  against `c2c_telegram_chat`. Keep all three checks.
- The dedicated bot is for admin approvals only. Customer notices still go
  through the panel's own bot (`telegramtoken`), so turning the panel bot off
  does not silence the buyer.

### Commission â€” money rules already decided. Do not redo without asking.

- Only **new** commission is credited automatically.
- The watermark setting `commission_last_affiliate_id` marks the last paid row.
  **Never lower it** â€” everything below would pay a second time.
  `commission_log.affiliate_id` is UNIQUE as a second guard.
- Routing (the owner chose this): the referrer keeps it in `payout_balance` and
  can cash out **only** if their subscription is active **and** the gap since
  their previous one is at most `withdraw_max_gap_days` (90). Otherwise it is
  **moved** into `user.money` as spendable credit â€” moved, not added.
- Minimum cash withdrawal: `min_withdrawal` = 10,000,000 IRR. The server's own
  limit is the `payoutlimit` setting, measured at the same value.
- Two one-off migrations already ran: 143 active users (113,219,705 IRR) and
  219 expired users (171,144,159 IRR). **Staff keep their commission on
  purpose** â€” confirmed twice.

- Routing fix, installed by hand on the server on 2026-10-24 (a release is
  still to be cut from this worktree): when `commission_wallet_enabled` is on,
  **every** commission goes to `commission_wallet`, whether or not the referrer
  could cash out. The `payout_balance` route only applies while that switch is
  off. Before this, an active account's rows were left in `payout_balance`,
  invisible in the dashboard and unusable below the 10M withdrawal minimum.
  A reported account's whole payout balance was moved into its commission
  wallet by hand; the other 85 payout balances (70 of them active and below the
  minimum) were left for the owner to decide on.
- 1.33.0: the destination is a setting, not a rule. The admin picks
  `commission_destination` (payout | money | wallet) in the affiliate page
  (`view/admin/affiliates/option.tpl`, a new card saved through
  `xmplus-patch.php?do=commission.routing`), and may switch on
  `commission_user_choice` so the customer picks on the invite page
  (`view/user/affiliate/commissionroute.tpl`, `commission.pref`). The customer's
  pick lives in `commission_pref` (migration 026). Only new commission is
  routed; existing balances stay where they are. Choosing `wallet` turns
  `commission_wallet_enabled` on. With no setting saved, the legacy routing
  above applies. A customer's saved wallet pick falls back to account credit
  while that feature is off. The card-to-card gap remains.
- 1.34.0: the admin also ticks which of the three the customer may pick
  (`commission_user_options`). The invite-page selector only offers those, and
  the default destination must be one of them; the server refuses a save
  otherwise. Empty/missing options mean all three, as before.
- Known gap: a card-to-card approval grants the plan directly
  (`Card2Card::c2cApplyOrder`) and never writes an `affiliate` row, so a
  purchase paid by card-to-card earns **no** referral commission yet.

### Invites â€” popup, assistant, share bar (1.8.0)

Files: `view/user/affiliate/invitepopup.tpl` (included at the end of
`dashboard.tpl` when `rebate` is on), `inviteinsight.tpl` (the assistant
bubbles), `sharebar.tpl` (message + buttons; `shareEditable=1` on the affiliate
page, `shareCompact=1` in the popup), `User::referralCount()`,
`User::inviteInsight()`.

- Stages: 0 offer â†’ dismissed â†’ 12 h â†’ 1 "what is lost" â†’ 2 days â†’ 2
  "discount on your next plan" â†’ 7 days â†’ back to 1. Any share button = done,
  quiet for 30 days. State is `localStorage['dsInvitePop:<uid>']` â€” there is no
  endpoint for it, and losing it only shows the offer once more.
- It never stacks: it waits until no `.modal.show`, `.swal2-container` or layer
  dialog is open, then 2 s of quiet.

---

## 7. Release history

| Version | Changes |
|---|---|
| 1.0.0 | Initial patch release: dashboard rebuild, tickets redesign, affiliate tab, commission payout |
| 1.1.0 | Time plans â€” a third plan type selling days only, fixed or per-day price |
| 1.2.0 | Plan scoping â€” limit time plans and top-ups to chosen subscription plans and server groups |
| 1.3.0 | Commission payout redesign â€” automatic, with popup and ledger |
| 1.4.0 | Invoice redesign, printable, readable on phone |
| 1.5.0 | Time plan per-day mode with minted rows |
| 1.6.0 | Limit traffic top-up to chosen subscription plans |
| 1.7.0 | Admin dashboard rebuild with ApexCharts |
| 1.8.0 | Invite popup, assistant, share bar; Telegram channel gift |
| 1.9.0 | Sign-in page redesign |
| 1.10.0 | Purchase flow redesign â€” plans, payment pages, verdict popup |
| 1.11.0 | Charge wallet (pay-as-you-go): top up any amount from 200k toman with tiered bonus, plan runs out â†’ usage billed from the balance at each server's price per GB (free while a server is down), plan-ending / low / empty / resumed notices on the dashboard, Telegram and e-mail; admin report of charged / spent / unspent, per-user ledger, manual adjustment; separate commission wallet usable for subscription plans only; status rows in Happ / V2Box / v2rayNG / Shadowrocket (Solar Hijri end date, data left, wallet balance, "update for the live balance"). Off until switched on |
| 1.11.1 | Wallet in the operator-app layout: wallet tile in the subscription card, wallet state at the top of the card while on balance, side panel / bottom sheet with add funds, transactions, prices and settings, toast for billing messages, menu item; admin amounts in toman, minimum any value including 0, save answered with the stored values, GETs bypass the CDN cache, token retry; status rows in the client apps (from the 1.11.0 branch) |
| 1.11.2 | Client apps: the `?do=sub` link no longer sends `subscription-userinfo` when it adds the status rows, so the app's own total / Gregorian expiry bar is gone; Clash / sing-box keep it |
| 1.11.3 | Client apps: the status link sends `subscription-userinfo` with all zeros instead of leaving it out, because the apps kept the old total / Gregorian expiry from their previous update |
| 1.11.4 | Client apps: the status link drops the panel's own "Total:â€¦ Used:â€¦" / "Expire:â€¦" info entries from the list, which still showed the Gregorian expiry under the Persian rows |
| 1.11.5 | Client apps: shorter status rows (about 25 characters) so they are not cut off on a phone; end date / days left and updated time / "update to refresh" split into two rows each |
| 1.12.0 | OpenVPN servers on the same subscription: node agent + installer (`node/openvpn/`), login and usage through `xmplus-patch.php?do=ovpn.*`, traffic counted against the plan and billed by the charge wallet, cut-off when the plan or data ends, admin server list with install command, dashboard card with profile download and credentials. Off until switched on |
| 1.12.1 | OpenVPN: `node/openvpn/uninstall.sh` removes a node from its server (agent, OpenVPN config, NAT rules, services; `--keep-ca`, `--purge`); the admin page shows the command |
| 1.13.0 | OpenVPN: the node redirects every port of its protocol to OpenVPN (except ports in use, SSH and `--exclude`), and the ports customers use are chosen in the panel, several allowed with fallback; admin ðŸ“¥ profile download per server and a test login, working before OpenVPN is switched on. Existing nodes: run the install command again |
| 1.13.1 | OpenVPN: shown inside the apps card for any panel app named OpenVPN (download link / icon / guide edited in the panel's apps list), with server files and login instead of the subscription link; profile says `setenv CLIENT_CERT 0` so OpenVPN Connect no longer asks for a certificate; push errors carry the database message to the agent log |
| 1.13.2 | OpenVPN: `xmplus-openvpn` icon class in the panel's own icon style (`<span class='xmplus xmplus-openvpn fs-15'></span>`) for the OpenVPN app in the client apps list |
| 1.13.3 | OpenVPN: the app picker draws the OpenVPN icon as inline SVG for any app named OpenVPN, since the `xmplus-openvpn` class did not show on the live panel |
| 1.14.0 | OpenVPN: UDP and TCP side by side (`install.sh --proto both`, default), per-server choice in the panel (automatic / both / UDP / TCP) with separate UDP and TCP ports; with both, customers get a combined file (UDP first, TCP fallback) and a UDP-only and TCP-only file. Existing nodes: run the install command again |
| 1.14.1 | OpenVPN: online / offline messages for OpenVPN servers to the admin Telegram chat (`OvpnJob`, every minute), with a switch on the OpenVPN settings card |
| 1.15.0 | OpenVPN: card moved to the Servers page; per-instance status (ðŸŸ  part down) so stopping UDP or TCP alone is reported, scheduler last-run line and Telegram test button; bypass (Iranian IPs, custom domains / IPs / networks) as `net_gateway` routes; automatic free install port and customer ports that avoid ports other programs use; automatic certificate for the server's domain with `verify-x509-name` in new files. Nodes: run the install command again (agent 1.4.0) |
| 1.15.1 | OpenVPN: bypass files stay under OpenVPN Connect's profile size limit ("profile is too large"): at most 1200 routes, custom entries first, then the largest Iran ranges (~98.5% of Iran's addresses) |
| 1.16.0 | Affiliate page: ðŸ“± QR code button on the invite link card opens a dialog with the link as a QR code (drawn in the browser, no library), save as PNG, send the image (phones), copy the link |
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
| 1.22.4 | Header countdown shows nicer payg balance format (ðŸ’° balance Â· ðŸ“¶ GB) when wallet balance > 0 |
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
| 1.23.22 | Promotions: the single "Ø§Ø¹Ù„Ø§Ù… Ø¨Ù‡ Ù‡Ù…Ù‡â€ŒÛŒ Ú©Ø§Ø±Ø¨Ø±Ø§Ù†" switch split into separate **Telegram** and **Ø§ÛŒÙ…ÛŒÙ„** switches, so a promotion can be announced on either channel on its own (both on by default). Saving writes `announce_telegram` / `announce_email` next to the old `announce`, which stays the master flag the cron checks (`announce` = either channel on); `PromoJob::broadcast()` sends each channel only when its switch is on, and entries saved before the split (no per-channel keys) still announce on both. UI in `view/admin/plans/promoform.tpl` + `promojs.tpl`, keys added to `localization/{fa_IR,en_US,zh_CN}.php`. |
| 1.24.0 | Plan reservation: reserve a subscription at checkout â€” pay now, start later, either after the current plan ends or on a chosen date. Sold as a marked traffic top-up and started by `bin/reserve.php` (`app/Jobs/ReserveJob.php`); one active reservation per customer, cancellable before it starts with a full refund into account credit. New table `plan_reserve` (migration 021), admin card in Settings, reservation card on the dashboard, new keys in all three locales |
| 1.24.1 | Fix: reserving while the account still had a running plan was refused by the checkout ("Ø§Ø´ØªØ±Ø§Ú© ÙØ¹Ø§Ù„ Ø¯Ø§Ø±ÛŒØ¯"). The reserve order now sends `disableactive: 1` like every other customer top-up (ignored for a type-1 top-up, so the current plan is untouched); the "cancel my plan" switch is only hidden in reserve mode |
| 1.25.0 | Reserved plans are announced everywhere: a notice banner on every customer page when a reservation is taken and when it starts (dismissible, `reserve.ack`, new table `reserve_notice`, migration 022), a fuller dashboard card, and Telegram + e-mail at both moments exactly once each. A just-paid reservation is linked on the first page load (`ReserveJob::linkForUser`) instead of waiting for the cron |
| 1.25.1 | Fix: the reservation banner crashed every customer page with "Cannot use object of type stdClass as array" - the notice rows are now plain arrays (User::planReserveNotices) |
| 1.25.2 | At checkout the payment page now surfaces the wallet balance (`AccBalance`, value -1) above the gateways whenever `user.money > 0` - pre-selected when it covers the total - so a reservation refund credit is spent automatically |
| 1.25.3 | Fix: the ghost reservation banner. Its close button used jQuery where usermenu.tpl renders, before the footer loads that library, so the x never worked - it is vanilla JS now (fetch + FormData). A booked notice also shows only while its reservation still waits: User::planReserveNotices joins plan_reserve and hides the notice once the reservation is cancelled, started or deleted; cancelling marks the notice seen, and migration 023 marks such stale notices seen |
| 1.25.4 | Fix: checkout popped up "Trying to get property 'fee_percent' of non-object" whenever the account balance was pre-selected - which happens when the balance covers the total, typically a small order (e.g. one paid with a reservation refund credit). The wallet is not a gateway and the encoded `gateway_fee` endpoint has no row for method -1, so `Gatewayfee()` now fills the fee (0) and the total in locally for it |
| 1.25.5 | The panel wallet (`user.money`) now shows its real unit, rial - the checkout balance radio, the dashboard money tile and the payg panel-money line label the amount `PaygRial` instead of the panel currency symbol, so the balance is never read as toman next to the payg wallet (which divides by ten). The raw number is kept, like the order totals next to it, so the checkout balance-covers-total check and its display agree |
| 1.26.0 | (1) Cancelling a reservation now tells the buyer on Telegram (and e-mail) that the amount went back to their account credit and is applied automatically in future purchases - `ReserveJob::announceRefund`, fired by `reserve.cancel` right after the refund. (2) The pay-as-you-go wallet shows rial like everything else: `payg_show_toman` now defaults to 0 and migration 024 flips the stored setting, so the balance, the charge presets, the minimum charge, every price and every message are written in rial; the admin can re-enable the toman display in Settings |
| 1.26.1 | Fix: cancelling a paid reservation sometimes did not refund and sent no Telegram notice. The check read `orders.status === 1`, but the panel's own order list can move a paid order out of that status (or delete the row) between payment and cancel, while `pay_date` is the durable paid proof and `plan_reserve.amount` remembers the price. `reserve.cancel` now refunds on `pay_date` (falling back to `plan_reserve.amount` when the order row is gone), and `ReserveJob::reconcile()` (every minute, between `linkPaid` and `activateDue`) cancels, refunds and notifies any waiting reservation whose order is missing or dead (`-2/-1/0`) |
| 1.26.2 | Fix: every cancel now sends a notice - `announceRefund` when there is a refund, `announceCancelled` when there is none (unpaid, zero-amount, or already reconciled). `reconcile()` no longer skips zero-amount rows, and `reserve.cancel` notifies in both branches so the action is never silent on Telegram/e-mail |
| 1.26.3 | Fix: an account on its plan with a charged wallet showed "paying from credit". The subscription card and wallet banner follow the real wallet mode; `PaygJob` no longer switches to balance mode for a plan paid in the last 10 minutes and `newSubscription()` allows a 10 minute grace |
| 1.26.4 | Fix: a reserved plan only started once the current plan's time had expired, so a customer whose traffic ran out while days remained never got their reservation. `ReserveJob::activateDue()` now treats a used-up quota the same as an expired plan - the reservation starts when the current plan's time is up or its traffic is used up; a dated reservation still waits for its date |
| 1.27.0 | Card-to-card payments: a manual method on the checkout (the encoded gateway list cannot hold one). Several receiving cards, each with an amount and/or count cap per day / month / in total, rotating automatically when a cap is reached; the customer pays the exact order total and records the last four digits, payer name, date/time and an optional reference. A new request is announced on the admin Telegram chat with approve/reject buttons (signed one-time links, no webhook) and is also approvable in Settings -> Card to card; approval marks the order paid and grants it (time plans, reservations and wallet charges by their own jobs; normal plans and top-ups here, following the plan's renewal type), then tells the buyer in the panel, on Telegram and by e-mail. A job keeps waiting orders open, auto-rejects unanswered requests, and closes the Telegram buttons. New tables `c2c_card`, `c2c_request`, `c2c_notice` (migration 025). Off until switched on |
| 1.27.1 | Card to card, minimal declaration: the buyer only enters the last four digits of their own card - the bank SMS already has the name, the time and the reference. Payer name, transfer date/time and reference moved into an optional "more details" section (pre-filled and editable); the admin Telegram message shows only the fields that were filled, plus the submission time. A rejection carries the admin's reason to the buyer's Telegram whenever they have started the bot, independently of the panel's Telegram master switch, and to the panel banner. |
| 1.27.2 | Fix: the card-to-card admin section and the checkout dialog were bound inside `$(function(){...})`, but the panel loads jQuery in the footer, after these inline scripts run, so `$` is undefined at parse time - the section rendered but every button (Add card, Save, approve/reject) did nothing. The admin manager now binds with a plain DOM-ready guard and the checkout dialog opens through the Bootstrap Modal API. |
| 1.27.3 | Fix: approving a reserved plan could fail with "the package behind this order is gone" - the panel deletes the minted top-up row between checkout and approval, and the grant read the marker off that row. A reserve is now recognised through `plan_reserve` instead, its reservation is linked and marked paid, and the grant is deferred to the reserve job. The Telegram approve/reject buttons are now one-tap: the decision runs straight from the link (the one-time token is the credential) and shows a one-line outcome. |
| 1.27.4 | Fix: approving a request whose order was already paid (a gateway, the panel, or a duplicate tap racing the first) no longer reports "could not complete / this order was already paid another way". The request is closed as approved with a note, nothing is granted twice, and the Telegram page says the order was already paid. A repeated tap on a decided request reads as already handled. |
| 1.27.5 | Fix: approving a subscription/top-up whose package row was deleted no longer fails. The order snapshots `bandwidth`, `plan` and `plan_expire`, so the grant is rebuilt from the order when the package is missing; the routing limits are left as they are instead of being zeroed. A top-up with no snapshot bandwidth, and a marked top-up that cannot be identified without its package, are marked paid and left to their job. |
| 1.28.0 | Card to card approvals can happen entirely inside Telegram. A dedicated bot token (Settings -> Card to card) is registered as a webhook on save (`xmplus-patch.php?do=c2c.tgwebhook`, verified by Telegram's secret header); the admin message then carries callback buttons, so approve/reject decides on the spot, shows a toast and removes the buttons - no page opens. The callback payload is `c2c|a|id|hmac`, and only the configured admin chats may decide. Without a dedicated token the one-tap URL buttons remain. Customer notices still use the panel bot. |
| 1.28.1 | Fix: a card's cap counts only **approved** payments, so abandoned/pending test requests no longer keep a card full and hide card to card at checkout. The amount cap is in rial and the hint now says so. The support handle (`c2c_support`, default `@digitsellshop`) is shown in the buyer's approval/rejection message, in the panel rejection reason, and in the checkout dialog. |
| 1.29.0 | Fix: dedicated-bot callbacks spun forever because Telegram could not reach the panel's webhook through the CDN, so answerCallbackQuery never ran. The bot now polls `getUpdates` from `bin/c2c.php` (mode `poll`, the default) and applies a tap through the same `c2c.decide` endpoint the URL buttons use, then answers the callback and edits the message with the outcome. Only outbound Telegram access is needed. `webhook` mode remains a setting for hosts Telegram can reach. |
| 1.30.0 | Rejection reasons from Telegram: tapping "❌ رد" asks the bot for the reason (text reply; `/skip` = no reason, `/cancel` = keep it pending), then rejects with that reason and edits the original message. The reason is stored in `c2c_request.note`, so the panel banner, the Telegram/e-mail notice and the support line all carry it. The site's note field already did this. Polling picks the reply up within a minute. |
| 1.31.0 | Reset and test mode. Settings -> Card to card gets a "reset all card-to-card transactions" button (deletes `c2c_request` and `c2c_notice`; cards, settings and orders stay). `c2c_test_user` marks one account as a test account: its requests are applied but excluded from card caps and from the admin history (they still show while pending with a "تست" badge) and produce no customer notice; the Telegram admin message says "🧪 تست". 0 turns it off. |
| 1.32.0 | The display title is editable (`c2c_title`, default "کارت به کارت", up to 60 characters) in Settings -> Card to card -> "Display title". It is used at checkout, in the dialog header, in the admin request message, in the buyer's approval/rejection message, in the bot's /start text, and as the order's payment-method label (shortened for the column). |
| 1.32.1 | Mobile fix for the card-to-card dialog: it is scrollable and capped to the viewport, and a full-width "انصراف" button at the bottom closes it in every state (form, waiting, rejected, approved), so the top X is no longer the only way out. |
| 1.32.2 | The dialog is moved to `<body>` at runtime (escaping the page's stacking context), gets a high z-index, starts 72px below the top and is capped to the viewport as a flex column: the title and the cancel footer stay fixed while the body scrolls. This fixes the title still sitting under the menu bar on phones. |
