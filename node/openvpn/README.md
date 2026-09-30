# OpenVPN node

Runs on a separate server next to OpenVPN and ties it to the panel, so
customers connect with OpenVPN on the **same subscription**: same end date,
same data allowance, same charge wallet. Nothing here is copied into the panel
by the updater; it is fetched by the server that runs OpenVPN.

| File | What it is |
|---|---|
| `install.sh` | Installs OpenVPN, a CA, NAT and the agent on Ubuntu 20.04+ / Debian 11+ |
| `ovpn-agent.py` | Holds OpenVPN's management socket; asks the panel about logins and reports usage |

## Setting a server up

1. Panel → **Settings → سرورهای OpenVPN** → add a server (name, groups,
   multiplier). The page shows an install command with the server's key.
   The key is shown once; **کلید جدید** makes a new one.
2. Run that command as root on the OpenVPN server. It is safe to run again
   (to put a new key in place, or change port / protocol); the CA is kept, so
   profiles customers already downloaded keep working.
3. Switch **OpenVPN برای کاربران فعال باشد** on. Customers whose group the
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
