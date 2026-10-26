# User-edit wallet and commission fields — installed 1.37.1

1.37.1 repairs native profile mass assignment: the browser's balance metadata,
request key and CSRF token are now filtered out through an explicit native-field
allowlist. Native `money` is always supplied from the freshly locked legacy
commission value. The full browser POST is included in the native integration
regression and verifies that neither unknown columns nor user token changes
occur. Native SQL error details are logged instead of reflected in the UI.
The reported failed edit rolled back its wallet change; the agent did not apply
the requested balance automatically. Backup:
`/root/digitsell-user-balances-fix-20261026-113301`.

Installed 2026-10-26 over live 1.36.3, migration `029_admin_balance_edits.php`.
Full database, previous settings and affected-file backup:
`/root/digitsell-user-balances-backup-20261026-154931`.

## Usage and amounts

Admin → Users → Edit replaces the old editable `money` control with:

- Usage wallet balance, from `payg_wallet.balance` only.
- Commission balance, the sum of legacy `user.money` and dedicated
  `commission_wallet.balance`, matching checkout source classification.

Enter the desired **final** balance in rial, including explicit zero to clear a
balance, optionally enter a reason, then use the existing Save button. Persian
and Arabic digits and common thousands separators are accepted. Negative target
balances and amounts over the supported limit are rejected. Rebate percentage
and withdrawable payout balance retain their existing meanings and controls.

As with the old money control, only the primary administrator (`role=1`) can
change balances. Other administrators can use their existing native profile-save
permissions without acquiring financial-edit permission. Loading the form or
deploying this feature does not modify any customer's balance.

## Save behavior

Only controls actually changed by the operator update money. Unchanged balance
fields are never written back from a stale browser snapshot. Explicit balance
edits validate the original source values under row locks and reject concurrent
changes rather than silently overwriting a purchase, charge or commission.

A commission increase goes into the dedicated commission wallet, retaining
legacy credit. A decrease uses dedicated commission first, then legacy credit.
Usage-wallet edits never alter either commission source, and commission edits
never alter the usage wallet. Adjustments update the existing ledgers plus a
source-level `admin_balance_edit` audit record with administrator, request key,
before/after amounts, reason and timestamp. Retrying a completed balance save
does not apply it or call native profile saving twice.

The native profile save and money edits share one PDO transaction. The native
controller receives the freshly locked legacy component as `money`, never the
editable aggregate commission amount. Its actual `save-user` route context is
resolved through the captured native Slim application so the existing route
authorization hook remains in effect. Failure rolls back both profile changes
and balance/audit/ledger writes.

## Files and validation

- `app/Patch/AdminUserBalances.php`: amount parsing, reads, absolute edits,
  optimistic concurrency, ledger/audit and native routed-request adapter.
- `app/Patch/AdminUserBalancesEndpoint.php`: authenticated reads and CSRF-protected
  native profile-save integration.
- `app/Patch/Invoice.php`: retains the native Slim application during the existing
  standalone bootstrap for the native admin authorization hook.
- `view/admin/users/edit.tpl` and `balances.tpl`: separate fields, loading state,
  change detection and existing Save-button integration.
- The standalone dispatcher routes `userbalances.*` before the blanket admin
  gate; the endpoint checks authorization itself. The updater rejects archives
  that remove this integration.

`tools/admin-user-balances-integration.php` runs against connection-local temporary
user, wallet, queue, ledger and audit tables on the installed runtime. It verifies
the real native profile-save transaction, independent absolute edits, legacy
commission handling, audit, idempotency, preservation of concurrent untouched
commission, rejection of stale explicit edits, atomic rollback, permissions,
localized numeric input, missing wallet rows and clearing balances to zero.

The installed Smarty compiler accepted both user-edit templates and the nearby
plan/payment templates. JavaScript syntax and updater-preservation tests passed.
A read-only authenticated live request for user #1 confirmed both separate,
editable balance fields; the new audit table remained empty after deployment.
The panel login returns HTTP 200. No actual user balance was edited by the agent.

The repository still predates other live modules. This was a scoped installation;
do not publish its whole manifest without synchronizing the other live sources.
