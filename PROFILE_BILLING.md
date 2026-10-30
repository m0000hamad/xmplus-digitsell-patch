# Two profile ports and traffic multipliers

Follow-up 1.38.7 restricts two-row online display to nodes whose split checkbox
is enabled in current settings. Unchecked nodes keep their original native
single counter; clearing the checkbox restores it even if old profile snapshots
remain. Only checked nodes use the “—” state when split observations are missing.

Online-count follow-up 1.38.6 is installed and published with matching live
installed/latest status. Agent 1.4.1 is published and required for actual
per-profile presence; older/unsplit observations remain unclassified. This
panel deployment did not update node agents or change profile ports/rates.

Panel 1.38.5 is installed and published; authenticated installed/latest agree.
Agent 1.4.0 is published and must be installed on intended node machines before
activation. No real port/rate configuration or node agent was changed by the
panel release. Source: `dca5b417abc23fd269f67918912d2014e5e984a4`.
Backup: `storage/patch/backup-20261031-015701`. All 184 installed file checksums,
live migration/editor/auth/health and installed-code synthetic billing/port
fixtures passed.

Panel 1.38.5 and standalone Xray agent 1.4.0 add opt-in per-profile ports and
traffic multipliers to the existing server editor. There is still one native
server record, API identity, physical machine and account UUID/password. TLS,
SNI, transport, relay, exit routes, node membership and account quota are shared.
The agent generates two inbounds on the selected ports; it does not clone panel
servers or customer accounts.

For example, 1 GB through link 1 at rate 1 debits 1 GB; 1 GB through link 2 at
rate 4 debits 4 GB from the same user's balance of traffic. The native traffic
log records weighted bytes and the applied multiplier; node bandwidth remains
the actual unweighted bytes. The existing pay-as-you-go job consumes those
native weighted traffic logs as it does for ordinary node multipliers.

## Activation

1. Install the panel release, then update the standalone Xray agent on each
   intended machine to 1.4.0. Existing agents/ports keep working while this
   feature is disabled. An agent reports its capability at its next sync.
2. In Admin → Server → Edit, enter the two profile ports and multipliers beside
   the existing profile names/domains. Suggested rates are 1 and 4. Enable the
   per-profile ports checkbox and save with that block's own button. No port is
   chosen or changed automatically during installation.
3. Both ports must be reachable through the machine's firewall and, where used,
   the external tunnel/forwarder. This feature does not rewrite an external
   tunnel or firewall. Reserved API/other-inbound ports reported by the same
   agent cannot be selected. The two ports must differ and lie in 1–65535.
4. The next agent sync applies the two inbounds. Activation, deactivation,
   changing ports or changing rates rebuilds Xray once and reconnects users of
   that process. Users refresh subscriptions after changing ports. Names and
   domain-only changes do not rebuild Xray.

The original address is hidden. With profile ports enabled, the original port,
listening-port and multiplier controls are also hidden; their native values
remain for legacy accounting and disabling this feature. A recent 1.4-capable
agent heartbeat is required before enabling separate ports, so an old XMPlus
binary or old standalone agent cannot silently advertise a nonexistent second
inbound. The owner previously elected to update the other machines personally;
publication of this agent does not imply those machines were upgraded.

## Accounting and failure behavior

`server_profile_billing_<node>` stores the enabled flag, two ports, rates and a
deterministic SHA-256 revision. Each enabled revision is retained as
`server_profile_billing_history_<node>_<revision>`. Names, hostnames, billing
settings and the revision snapshot are saved in one transaction. Existing
unconfigured servers keep their original ports and native multiplier.

Signed subscription requests receive only their profile's advertised port.
The node uses the shared account credential on both inbounds, with an internal
counter label that carries profile and revision. Block/relay/exit/device-limit
rules cover both tags. Online IPs are merged by the native account so one device
using both ports occupies one IP slot rather than two.

The agent freezes each profile traffic report with a persistent batch ID before
sending `node.profiletraffic`. Migration 030 creates `profile_traffic_batch`;
its unique node/batch key and digest are committed in the same transaction as
atomic quota increments, native traffic logs and raw node-bandwidth increments.
A lost reply or agent restart replays the same batch and cannot debit it twice.
A changed payload under the same ID, unknown revision, invalid profile or
negative counters is refused. A rejected/outage report stays queued. An old
revision is billed at its historical rate even after settings change.

Legacy traffic continues through the native API. Its two shipped controllers
now increment counters atomically too, preventing a concurrent legacy report
from overwriting a profile debit. Profile usage is never also posted through
the legacy traffic endpoint.

## Verification and rollback

Panel 1.38.6 with agent 1.4.1 also splits Admin → Servers → online-users into
two rows, profile 1 above profile 2. These count unique accounts actually
observed on each inbound, not everyone allowed to access that link. One account
can appear in both rows, regardless of its number of IPs/devices. The ordinary
native online-IP union and device limits are preserved. Only aggregate counts
are stored in new `node_profile_online` (migration 031).

Missing, stale, unsplit or old-agent observations display “—”, not a fabricated
profile count; known empty observations display 0. Counts expire after 60 seconds
and refresh every 15 seconds. A tooltip identifies the configured link and warns
if some observed accounts could not be classified. Empty reports clear the
reporting node only. The new admin endpoint returns no account/IP details.

Local tests cover exact 1x/4x shared quota, raw bandwidth, native logs, immutable
rates, replay deduplication, invalid/atomic configuration and negative usage.
Linux agent tests cover two generated inbounds with one credential, rules for
both ports, durable retry IDs and merged device/IP limits. Native MySQL fixtures
use connection-local temporary copies of the actual schemas and exercise both
native accounting controllers alongside the new debit path. Native subscription
fixtures verify both advertised ports across supported client formats/relays.

```
php tools/profile-billing-test.php
php tools/subscription-profiles-endpoint-test.php
python3 -m unittest discover -s node/xray -p 'test_*.py'
php tools/profile-traffic-native-test.php PANEL_ROOT SOURCE_ROOT
```

Before rolling back panel support, disable profile billing, wait for the agent
to apply the native inbound and drain all profile batches. Keep the revision
history and batch table: deleting them would prevent historical reconciliation
or replay protection. An agent keeps cached profile ports during an outage;
rolling back the endpoint while leaving profiles enabled is not a deactivation.
Do not downgrade the installed version merely to conceal missing publication.
