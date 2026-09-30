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
| `uninstall.sh` | Removes what `install.sh` set up |

## Setting a server up

1. Panel → **Settings → سرورهای OpenVPN** → add a server (name, groups,
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
(`my.digitsell-shop.ir`).

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

OpenVPN itself listens on one port (`--port`, 1194 by default), but every
other port of each protocol is redirected to that protocol's instance, so the port customers
connect to is chosen in the panel: **Settings → OpenVPN servers → edit →
پورت‌ها برای کاربران**. Several ports can be given (`443, 8443, 2083`); the
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

```bash
digitsell-ovpn-nat excluded udp  # the UDP ports left alone right now
digitsell-ovpn-nat excluded tcp  # the TCP ports left alone right now
```

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

- OpenVPN is easy for DPI to recognise. `--proto tcp --port 443` survives more
  networks than the default UDP 1194, but neither is guaranteed from Iran.
- The device limit (`user.iplimit`) counts the addresses in `online_ip` (the
  Xray nodes' reports) plus live OpenVPN sessions, at login time only.
