# Online presence across Xray nodes

## 2026-10-29 hotfix

Native XMPlus/XMPlusNew online-IP ingestion looked up an existing row by user
and IP only, then overwrote its server ID. Simultaneous connections from one
public IP to different nodes therefore competed for one row: the country shown
depended on which heartbeat arrived last. The narrow native-controller fix adds
server ID to that lookup. It does not change account admission or global device
limits; counting distinct public IPs still counts a shared NAT address once.

The authenticated `node.online` action accepts an authoritative snapshot for one
server, including an empty list. It validates all input before a transaction,
locks the server row on MySQL, replaces only that server's online-IP membership,
and rolls back on failure. Other countries and protocol nodes are unaffected.
The panel's existing freshness timeout still covers node/agent failure.

Agent 1.3.1 reports presence at most 15 seconds apart, independently of the slower
settings/usage sync. It sends successful empty observations to clear disconnected
membership. Older panels with an unknown action retain legacy heartbeat support.
A stats API failure no longer reposts cached users and renews stale panel rows.
Existing long-lived connections are not declared offline just because Xray's
connection-start timestamp is old. A broken network without a close packet can
still require Xray's connection timeout; subscription-URL rotation alone is not
proof that all previously authenticated sockets ended.

## Verification

`php tools/online-snapshot-test.php` exercises concurrent-country membership from
one IP, unchanged distinct-IP count, empty snapshots, invalid payloads, missing
nodes/users, IPv4-mapped IPv6 normalization and transactional rollback.
All 18 Python node tests pass, including stats outage/recovery, empty online
observations, long-lived sockets and old-panel fallback. PHP syntax passes.

On production, the narrow native-controller edits were applied without the
separate pending 1.38.2 account-admission changes. Panel backups:
`/root/digitsell-online-presence-20261029-021726`. Subsequent read-only checks
observed separate memberships for the user's US and Turkey connections. No
subscription UUID, token, device limit or customer configuration was changed.

Turkey agent 1.3.1 was installed after checking SHA-256 against the staged code,
with backup `/root/xray-agent.before-online-presence-20261029.py`. Only the agent
was restarted; Xray retained PID 2492122 and its previous activation timestamp.
The user confirmed simultaneous countries became visible. In the final live
test the user disconnected only the Turkey phone: Xray's user-1 presence became
empty, the panel removed Turkey, and US node 58 remained live. This verifies
disconnect propagation without waiting for the legacy freshness window.
Other nodes have not received the agent update in this session; panel-side
cross-country isolation applies to their legacy reports too.

The working tree already contained the related global-IP-count fix for 1.38.2.
The owner authorized committing and pushing the prepared update on 2026-10-29.
The package preserves that fix, its regression test and the presence fix together;
both native API suites pass. Publishing this package does not itself install the
full panel update or change the other nodes' agent binaries.

## Agent 1.3.2: credential revocation

Follow-up evidence found continuously refreshed online rows backed by genuinely
established TCP sockets long after the owner reset subscription credentials.
Removing/replacing an account through Xray's HandlerService changes subsequent
authentication; it does not close existing authenticated sessions. Their old IPs
can therefore keep occupying capacity even though the new link is being used.

Immediate recovery closed only the existing TCP tuples for the two reported
accounts after verifying that their source IPs were not shared with other accounts
on that inbound. Both accounts then had zero online IPs in Xray. Other users and
the Xray process were left running. This operational recovery did not change
customer credentials, quotas or limits.

Agent 1.3.2 detects UUID/password changes both in installed clients and in raw
subscription rows (so full-quota admission cannot hide a credential reset).
It saves the new config, collects pending traffic and restarts Xray once per sync
batch to revoke established sessions. Such a restart briefly reconnects **all
users on the same Xray process**, including other inbounds. Ordinary additions,
IP-limit removals and noncredential client changes retain the hot-update path.
The owner explicitly approved this behavior change and a one-time Xray restart
on 2026-10-29. The agent also restores its own existing online-IP capacity before
the first admission sync, avoiding account eviction merely from restarting the
agent. All 24 Linux node tests pass, including credential changes masked by quota,
usage collection before restart and normal updates without restart.

The owner elected to update the remaining node machines personally. Deployment
to Turkey and publication are tracked in HANDOFF.md; do not claim other machines
were restarted by this chat. Other nodes can run `dxray update` followed by
`systemctl restart digitsell-xray` for the approved one-time cleanup.

Agent source was published at 87226aa and installed on Turkey from that immutable
URL after SHA-256 verification. Backup: /root/xray-agent.before-1.3.2-20261029.py.
Both node services are active and the live status reports agent 1.3.2. The full
panel package was installed through its authenticated native updater, with
installed/latest both 1.38.2 and uptodate=true. GET /login returned HTTP 200.
