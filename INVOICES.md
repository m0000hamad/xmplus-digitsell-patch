# Admin-issued invoices — installed release 1.35.0

Checkout repair installed 2026-10-26, version **1.35.2**: standalone `db()` had
already included config in its function scope, so console `require_once` skipped
it during a fresh checkout and native bootstrap saw null database settings.
Load config explicitly and share `$DB` and `$i18n` with native bootstrap; preserve
the session and keep debug notices out of JSON. The integration test now starts
without preloading the console and verifies DB settings, translations, shared
PDO and empty bootstrap output. All settlement checks pass without PHP notices.
The user's affected invoice was observed on the native `/portal/pay` gateway
page after installation. No final payment action was performed by the agent.
Backup: `/root/digitsell-invoice-bootstrap-20261026-064642`.

Repair installed 2026-10-26, version **1.35.1**: an upstream updater attempt
replaced the standalone endpoint and removed its `invoice.*` dispatch. The form
survived but all lookups returned `this action needs POST`. Restored the dispatch
and customer template includes against the latest live files; the updater now
rejects archives missing installed invoice dispatch, the shared form or its
customer alert include before it overwrites any file. Regression test:
`php tools/invoice-update-guard-test.php`. Browser verification on the existing
admin session confirmed user lookup, selectable invoice type, populated plans
and populated billing periods. No customer invoice or notification was issued.
Repair backup: `/root/digitsell-invoice-repair-20261026-063518`.

Installed on production on 2026-10-26 over live 1.34.0. Deployment copied only
the eight invoice files, preserving the existing reservation and card-to-card
dispatchers and navigation banners. Migration is `027_invoices.php`, after the
live panel's existing migration 026. No GitHub release was published.

Ownership repair, 2026-10-26: the deployment selected the root-owned storage
directory as its ownership reference. All eight installed files are now
`www:www`, mode `0644`, matching the PHP-FPM worker. The updater's write access
was verified as `www`; login still returns HTTP 200. Do not infer worker ownership
from the panel/storage directory when installing from a root shell.

Full database and affected-file backup:
`/root/digitsell-invoice-backup-20261026-061627`. The backup includes settings
metadata, an affected-file inventory and installed-file checksums. Login returns
HTTP 200; authenticated admin/customer invoice reads passed; anonymous and
customer attempts at admin operations return HTTP 403. Native browser pages
require additional login credentials beyond the temporary test session, so the
post-install check covered invoice APIs; template compatibility was separately
verified with the installed Smarty runtime.

## Usage

Open **Admin → Orders → Issued invoices**. Search by user ID, username or email,
select the intended account, enter a title and description, and choose:

- **Services**: a positive amount in rial. Settlement collects the money without
  adding wallet credit, traffic, time or a subscription.
- **Plan**: an enabled subscription package and one of its priced periods.
  Select renewal only for that user's current package. Otherwise payment buys
  a new package, replacing the existing subscription according to native rules.

Issue the invoice. The user sees an alert across authenticated panel pages and
the invoice under **Orders**. Email uses the existing mail queue when its driver
is enabled and the account has a valid address; Telegram uses the existing bot
when enabled and linked. The admin list distinguishes queued, sent, off and
failed channels. Queued email is not proof of delivery. No SMS provider is added.

The user opens the invoice and continues to the panel's original checkout,
which presents its active gateways and applies its existing fees and account
balance behavior. The native payment callback is the sole settlement authority.
Closing or paying a native order updates the invoice's displayed state.

Admin cancellation is available before checkout starts. Thereafter use native
order management, which owns cancellations and refunds. If native checkout
returns an existing unrelated pending order, the invoice refuses to attach it:
pay or cancel that older order first. Canceled/expired payment attempts require
a newly issued invoice. Prices are checked again at checkout; a changed plan
price requires a replacement invoice. Lists show the latest 100 records.

## Integration

- `migrations/027_invoices.php`: invoice table; no changes to native order schema.
- `app/Patch/Invoice.php`: session ownership, per-session CSRF, admin search and
  issue/cancel, idempotent issue keys, native checkout adapter, notifications.
- `public/xmplus-patch.php`: dispatch before the admin-only gate; each action
  applies its own authorization.
- `view/common/invoices.tpl`: shared admin/customer form and list, all user
  text rendered via `textContent`.
- `view/user/layout/invoicenotice.tpl`: pending-invoice alert.
- `view/email/patch-invoice.tpl`: escaped email body and authenticated deep link.

Service invoices use private, inactive zero-bandwidth topup packages. A package
is enabled only inside the transaction that invokes the native order controller,
then disabled before commit. Native checkout and invoice attachment share PDO
and commit together; user/package/invoice locks serialize creation. No browser
input selects an owner, price or package during settlement. The authenticated
owner is supplied to a small controller subclass because a standalone endpoint
does not run Slim's authentication middleware. No encoded source is modified.

## Verification

PHP lint, JavaScript syntax and `git diff --check`. Integration was exercised on
the installed PHP/ionCube runtime using connection-local temporary copies of
commerce and user tables. Fixture contacts are blank; email verification uses a
temporary queue with an `example.invalid` destination. Settlement runs inside a
rolled-back transaction. No gateway request or customer notification is made.

Verified: duplicate issue, ownership rejection, checkout reuse, hidden service
packages, unchanged service/balance on service settlement, new plan activation,
renewal, active service unchanged until payment, account-credit compatibility,
queued email and canonical invoice URLs. A real gateway transaction and actual
email/Telegram delivery still require verification after installation.

To repeat on an installed panel, copy `app/Patch/Invoice.php`,
`migrations/027_invoices.php`, and `tools/invoice-integration.php` together into a
temporary directory, then run the integration script with the panel's PHP CLI
and the absolute panel root as its first argument. The fixture script relies on
the native schema and a seeded user row; none of that row's values are printed.

## Installation / rollback

For a future packaged install use the existing patch updater with a database/files backup; migration
020 must run before invoice endpoints are used. Clear compiled Smarty templates.
Rollback code with the normal updater backup, retaining `patch_invoice` and its
inactive package rows for order history. Do not delete packages referenced by
native orders or remove paid invoice records.

The local checkout predates several live 1.34.0 modules. Do not publish its full
manifest as a replacement release without synchronizing those sources. This
deployment deliberately used a scoped manifest and retained the live modules.
