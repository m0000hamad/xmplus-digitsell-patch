# Optional checkout funding — installed 1.36.3

Installed 2026-10-26 over 1.35.2, using a scoped file manifest and migration
`028_checkout_funds.php`. Database/settings/affected-file backup:
`/root/digitsell-checkout-funds-backup-20261026-135211`.

## Customer behavior

The payment page offers separate, initially unchecked boxes for wallet and
commission balances. Since 1.36.2 both boxes remain visible, with zero balances
disabled, so customers can distinguish the two sources. Since 1.36.3 wallet
means `payg_wallet` only. Commission includes legacy `user.money` commission
credit plus `commission_wallet`; the dedicated commission wallet follows its
enabled/subscription-only rule, while legacy commission retains its original
spend-anywhere eligibility. A usage wallet cannot fund its own topup.

Selecting a box obtains a server-side quote and updates deductions, remaining
principal, gateway fee and total. Quotes never debit funds. When both sources
are selected, usage-wallet credit is used first, then legacy commission and
dedicated commission, each capped at the remaining principal. The user pays only the
remainder through the native gateway. Full coverage uses native balance
settlement with zero gateway fee. Card-to-card dialogs receive the same reduced
amount. The prior pre-checkout commission switch/automatic application is removed
in favor of explicit payment-page choices, including renewal checkout.

## Settlement and cancellation

`CheckoutFunds.php` calculates and reserves funds against a single native order.
Reservations use order/source row locks, an order primary key, expected-total
validation and permanent source ledger entries. A stale amount is rejected
before debiting. Repeated payment requests reuse the existing reservation.

Native `user_balance` is zeroed after manual reservation to prevent native
`OrderService::paid()` from debiting the same credit again. Native order price
and discount remain available; its payable total becomes the gateway remainder.
The native checkout controller and gateway callback still settle and provision
the service. The adapter supplies an authenticated user with zero implicit
account credit so unchecked sources remain untouched.

`bin/checkout-funds.php`, scheduled every minute by `TaskCommand`, marks paid
reservations spent and returns canceled/expired ones to each original source
exactly once. Until payment begins the preview creates no reservation. After
payment begins the funding choices are locked to keep issued gateway amounts
consistent. Cancel an abandoned order through native order management; do not
delete reserved orders before their cancellation/refund has been reconciled.
Older orders with an already issued gateway request cannot change their funding:
finish or cancel them before starting a fresh checkout.

The patch updater refuses an archive that would remove this funding dispatcher,
template or refund scheduler. Existing reservation/card-to-card modules are
preserved. The local repository still predates other live modules: do not
publish its whole manifest without synchronizing those modules first.

## Validation

`tools/checkout-funds-integration.php` uses connection-local temporary tables
on the installed PHP/ionCube runtime. It verifies unchecked defaults, each
source alone and both together, gateway-fee reduction, quote purity, ownership,
stale-quote rejection, atomic reservation, repeat-click protection, full-credit
native settlement, no native double debit, exact-source refunds and refund
idempotence. Rendering tests verify two initially unchecked controls.

The named test account's live wallet quote was checked without debiting it or
creating a persistent order. The reconciliation script runs successfully and
the panel login returns HTTP 200. No real payment was performed by the agent.

1.36.1 repairs the commission compatibility template's missing Smarty literal
wrapper, which briefly broke plan details in 1.36.0. The installed Smarty engine
then compiled plan details, commission shim, funds controls, checkout, summary,
card-to-card and wallet templates successfully. The affected plan page was also
observed rendering normally in the user's existing browser session.

1.36.3 corrects the original grouping of legacy commission under the wallet
checkbox. Both quotes and reservations now isolate usage-wallet credit from
legacy/dedicated commission, including source-specific refunds. No customer
balances were migrated or moved. Before deployment there were no active
legacy-credit reservations to reinterpret. The named test account's actual
source balances and each single-checkbox quote were verified read-only.
Previous service backup: `/root/checkout-funds-classification-20261026-094058.php`.
