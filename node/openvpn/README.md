# OpenVPN node

Runs on a separate server next to OpenVPN and ties it to the panel, so
customers connect with OpenVPN on the **same subscription**: same end date,
same data allowance, same charge wallet. Nothing here is copied into the panel
by the updater; it is fetched by the server that runs OpenVPN.

| File | What it is |
|---|---|
| `install.sh` | Installs OpenVPN, a CA, NAT and the agent on Ubuntu 20.04+ / Debian 11+ |
| `ovpn-agent.py` | Holds OpenVPN's management socket; asks the panel about logins and reports usage |
| `digitsell-ovpn-nat` | NAT, firewall openings and the every-port redirect (installed in `/usr/local/sbin`) |
| `digitsell-ovpn-cert` | Gives OpenVPN a certificate for the server's domain (run by the agent; `/usr/local/sbin`) |
| `uninstall.sh` | Removes what `install.sh` set up |

## Setting a server up

1. Panel → **Servers (سرورها) → سرورهای OpenVPN**, under the server list → add a server (name, groups,
   multiplier). The page shows an install command with the server's key.
   The key is shown once; **کلید جدید** makes a new one.
2. Run that command as root on the OpenVPN server. It is safe to run again
   (to put a new key in place, or change port / protocol); the CA is kept, so
   profiles customers already downloaded keep working.
3. Try it yourself first: the server's row has a **📥 فایل** button that
   downloads a profile for your admin account, even while OpenVPN is still
   switched off for customers. Import it into OpenVPN Connect and sign in with
   the username / password on your own dashboard card (`u<your id>`).
4. Switch **OpenVPN برای کاربران فعال باشد** on.
5. Optional: to show OpenVPN next to the other apps on the dashboard, add an
   app named e.g. "OpenVPN Connect" for each platform in the panel's own
   client apps list. Its download link, icon and guide are edited there, and
   its step shows the server files and the username / password. Customers whose group the
   server serves see an OpenVPN card on their dashboard with a profile
   download, a username (`u<account id>`) and a password.

Use the panel address that is not behind the CDN for `--panel`
(`origin.example.com`).

## How it works

- OpenVPN runs with `--management-client-auth`: every login waits for the
  agent. The agent posts the username, password and client IP to
  `xmplus-patch.php?do=ovpn.auth`; the panel answers allow / deny with a
  reason (password, expired, quota, disabled, group, iplimit, off, node).
- Every minute the agent reads `status 3` and posts each session's running
  byte counters to `ovpn.push`. The panel keeps the last counters per session
  (`ovpn_session`) and counts only the growth, so a resent push adds nothing.
  The growth goes to `user.u` / `user.d` (times the server's multiplier) and,
  raw, to `trafficlog` under server id `900000 + node id` — the wallet billing,
  charts and reports read it from there.
- The answer lists sessions whose account may no longer connect; the agent
  kills them. The client reconnects, is refused, and shows the reason.
- A disconnect's final counters are sent with the next push.
- If the panel is unreachable, a login that the panel approved in the last six
  hours with the same password is let in; counters keep running and are
  reported when the panel is back.

## UDP and TCP

`--proto both` (the default) runs two OpenVPN instances side by side:
`openvpn-server@digitsell` for UDP (subnet `--subnet`, management port 7505)
and `openvpn-server@digitsell-tcp` for TCP (`--subnet-tcp`, 7506), both on
`--port`, sharing the certificates, so one file's CA fits both. `--proto udp`
or `--proto tcp` runs only one; running the installer again with another
choice adds or removes the other instance.

What customers get is chosen in the panel per server (**پروتکل برای کاربران**):
automatic (whatever the server runs), both, UDP only or TCP only, with
separate UDP and TCP port lists. With both, the dashboard offers one file that
lists the UDP remotes first and the TCP ones after (the app moves on to TCP
when UDP does not answer within 10 seconds), plus a UDP-only and a TCP-only
file. Sessions of the TCP instance are reported with a `t` prefix, so the two
never mix up in the panel.

## Ports

OpenVPN itself listens on one port (`--port`). With `--port auto` (the
default since 1.15.0) the installer keeps the port of an earlier install,
else takes 1194, else the first port from 1195 that no program uses for UDP
or TCP, so it never takes a port another service (Xray, a web server…)
already holds. An explicit `--port` that is taken stops the install.

Every other port of each protocol is redirected to that protocol's instance, so the port customers
connect to is chosen in the panel: **Servers → OpenVPN servers → edit →
پورت‌ها برای کاربران**. Left empty, customers get the ports the server
found free by itself (**خودکار**): the agent (1.3.0) suggests the first two free
ones from 443, 8443, 2053, 2083, 2087, 2096, 80, 8080 (TCP) or 443, 8443,
2053, 2083, 1194, 51820 (UDP), and the panel keeps its choice while those
ports stay free, so files already downloaded keep working; a port another
program takes later is replaced with the next free one. Several ports can be given (`443, 8443, 2083`); the
profile lists one `remote` per port and the app moves on to the next when one
does not answer within 10 seconds. Changing them needs no reinstall — customers
only download the file again. Profiles downloaded earlier keep working, since
their old port is redirected too.

Never redirected (checked again every minute by
`digitsell-ovpn-nat-refresh.timer`, so a program started later is safe):
ports another program on the server listens on (SSH, a web server, Xray…),
the SSH ports from sshd's configuration, 22, and `--exclude "80 443"`. The
agent reports that list to the panel, which refuses a port from it and marks
the server's row if a chosen port stops working. Only new connections to this
server's own addresses on the public interface are redirected; replies to the
server's own outgoing traffic are not touched. IPv4 only.

`--single-port` turns the redirect off; the panel then only accepts the port
OpenVPN listens on.

### On a server that already runs Xray (XMPlus node) or a firewall

- Ports some program has a socket on are skipped live, per packet
  (`-m socket`), not from a list: Xray relaying customers' UDP opens hundreds
  of sockets on random ports and replaces them all the time, and listing them
  rebuilt the redirect every minute. The listed ports are only 22, sshd's,
  the listeners outside the ephemeral range and `--exclude`; the chain is
  replaced in one `iptables-restore`, never half built.
- The openings (INPUT for OpenVPN's port, FORWARD for the VPN subnets, the
  NAT) live in chains of their own, `DIGITSELL_OVPN_IN` / `_FWD` / `_POST`,
  jumped to **first** from INPUT / FORWARD / POSTROUTING. The refresh timer
  puts them back every minute when another program (a firewall reload,
  Docker, a script) removed them or put a DROP in front.
- Where the server also has `iptables-legacy` rules (a legacy DROP policy
  drops what iptables-nft accepted) or nftables tables of its own whose input
  or forward chain drops by default (`/etc/nftables.conf`), the openings are
  added there too (nftables rules carry the comment `digitsell-ovpn`).
  `stop` removes all of it.

- The connection tracking table is raised to 128 entries per MB of RAM
  (65536 - 262144, `CONNTRACK_MAX` in nat.conf, never lowered) with its hash
  sized to match: a 1 GB VPS allows 7680, Xray alone half fills that, and a
  full table drops every new connection - OpenVPN logins and the traffic of
  connected customers.

Customers cannot connect, or connect without internet:

```bash
digitsell-ovpn-nat doctor
```

prints the interface, `ip_forward`, whether OpenVPN listens, the redirect
chains and their jumps, where our jumps sit in INPUT / FORWARD / POSTROUTING
and each policy, iptables-legacy, nftables chains that drop, ufw, firewalld,
Docker, UDP socket counts, conntrack (warns at 70%), and per protocol how
many connection attempts reached OpenVPN in the last 15 minutes and how many
got through the handshake, with the last lines that matter. No attempts while
a phone is trying means the packets never arrive: a filter on the way, not
this server. A `TLS Error: can not extract tls-crypt-v2 client key` from some
address on port 443 is a stray packet (a closed QUIC connection of Xray's),
not a customer. `IF=eth1` in
`/etc/digitsell-ovpn/nat.conf` picks another public interface.

```bash
digitsell-ovpn-nat excluded udp  # the UDP ports left alone right now
digitsell-ovpn-nat excluded tcp  # the TCP ports left alone right now
```

## Domain and certificate

Put a domain in the server's **آدرس برای کاربران** (with an A record to the
server's IP), or install with `--host vpn.example.com`. Customers' files then
connect to the domain, and the agent (1.4.0) gets OpenVPN a certificate for it
by itself within a minute (`digitsell-ovpn-cert`): issued by the server's own
CA — the one already in every file — valid 20 years, no port 80 and no
renewal. The OpenVPN instances restart once (connected customers reconnect).
Files downloaded after that also check the server's name
(`verify-x509-name <domain> name`); older files keep working. The server's
row shows 🔒 when the certificate is in place, and warns when the domain does
not point to the server.

A public (Let's Encrypt) certificate is not used on purpose: OpenVPN apps
trust only the CA inside the file, not public CAs, so it would add nothing but
a 90-day renewal and a port 80 that the every-port redirect hands to OpenVPN.

Removing the domain keeps the last certificate, so files that check it keep
working. Changing to another domain: customers download the file again.

## Direct routes (bypass)

**Servers → OpenVPN → عبور مستقیم**: destinations that skip the tunnel and
open over the customer's own connection. "Iranian addresses" adds the Iran
IPv4 list (about 1,750 ranges from ipverse/rir-ip, CC0, shipped with the
patch and refreshable from the card); custom lines take domains, addresses
and networks. The panel looks domains up (and again every 6 hours) and writes
everything as `route <net> <mask> net_gateway` lines into the file, so
customers download the file again after a change.

A file holds at most 1200 such routes: OpenVPN Connect refuses a profile
over 262144 bytes as it counts them (64 per line plus 16 per word, about 166
per route), and all 1745 Iran ranges came to about 298000 ("profile is too
large"). Custom entries always go in; the Iran ranges fill the rest, largest
first — about 98.5% of Iran's addresses. The smallest ranges left out go
through the tunnel, as without the bypass; merging ranges instead would have
sent foreign addresses around the tunnel. The card shows how many ranges fit. Works in OpenVPN Connect
and OpenVPN 2.x; routes are IPv4 only.

## Status and messages

The agent (1.3.0) reports every minute which OpenVPN instances it can reach,
so the panel tells three states apart: online, part of it down (e.g. the UDP
instance stopped while TCP runs — 🟠), and offline (agent gone, or the agent
alive with no OpenVPN running — 🔴). Older agents only report while something
is running, so stopping one instance of two went unnoticed.

## Removing a server

On the OpenVPN server, as root (the same command is in the panel under
**حذف از سرور**):

```bash
curl -fsSL https://raw.githubusercontent.com/m0000hamad/xmplus-digitsell-patch/main/node/openvpn/uninstall.sh -o ovpn-uninstall.sh
sudo bash ovpn-uninstall.sh              # everything, including the CA
sudo bash ovpn-uninstall.sh --keep-ca    # keep the CA for a later reinstall
sudo bash ovpn-uninstall.sh --purge      # also remove the openvpn / easy-rsa packages
```

It stops and removes the agent, the OpenVPN server config and the NAT rules
and their services, and closes the ufw port it opened. With `--keep-ca` a
later `install.sh` reuses the same CA, so profiles customers downloaded keep
working. IP forwarding is left as it is (Docker and others need it). Then
delete the server in the panel; recorded usage stays.

## Passwords

`password = 12 characters of HMAC-SHA256(ovpn_secret, "<id>:<uuid>")`. Resetting
the subscription link (new uuid) changes it. Changing `ovpn_secret` changes
every customer's password.

## Operating

```bash
journalctl -u digitsell-ovpn-agent -f          # logins, cuts, push errors
journalctl -u openvpn-server@digitsell -n 50
systemctl restart digitsell-ovpn-agent
```

Files: `/etc/openvpn/server/digitsell.conf`, `/etc/openvpn/server/easy-rsa/`
(the CA — back it up), `/etc/digitsell-ovpn/agent.json` (panel address and
key, root only).

## Caveats

- OpenVPN is easy for DPI to recognise. TCP 443 survives more networks than
  UDP, but neither is guaranteed from Iran.
- The device limit (`user.iplimit`) counts the addresses in `online_ip` (the
  Xray nodes' reports) plus live OpenVPN sessions, at login time only.
