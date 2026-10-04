# Digitsell WireGuard node

Ties a WireGuard server to the XMPlus panel, so its traffic goes through the
customer's existing subscription: it counts against their plan, is taken off
the wallet while they are on it, shows in the charts and reports, and is cut
when the plan or the data runs out.

Same shape as the OpenVPN node in `node/openvpn`, and the panel half is the
same code (`app/Patch/Vpn.php`). What is different:

- **no login to ask about.** A customer is given a `.conf` file built from
  their own keys, and from then on the agent adds and removes their peer as the
  panel says.
- **one port.** WireGuard has a single socket, so the port has to be open in
  the firewall and is what customers connect to. Nothing is redirected, and
  there is no port scan.
- **the direct routes are applied here, on the server.** Iranian addresses and
  the admin's own destinations leave this server directly, from an ipset and
  two iptables rules. A customer's file therefore holds no route lines and
  works in any client — which is what the OpenVPN node had to work around with
  `route … net_gateway` lines.

## Install

Add the server in the panel first (**Servers → WireGuard servers**); that gives
the node id and key, and prints this command ready to paste:

```bash
sudo bash install.sh --panel https://panel.example.com --node 1 --key <key> \
     [--listen auto|443] [--host vpn.example.com] [--dns "1.1.1.1 8.8.8.8"] \
     [--interface wg0] [--mtu 1420]
```

Ubuntu 20.04+ / Debian 11+. Safe to run again: the server key pair is kept, so
files customers already downloaded keep working; the settings and the key are
rewritten, which is how a new key is put in place.

`--listen auto` keeps the port of an earlier install, else takes 51820, else the
first free port above it. Changing the port means running this again with a
different `--listen`, and the panel will then show the port the server reported.

The script does not open the firewall — it prints the rule for you:

```bash
iptables -I INPUT -p udp --dport 443 -j ACCEPT
```

Open the port at the provider too, or customers cannot connect.

## What it puts on the server

```
/etc/digitsell-wg/agent.json          the agent's settings (root only)
/etc/digitsell-wg/server.key          the server's private key (root only)
/etc/wireguard/wg0.conf               the interface
/usr/local/lib/digitsell-wg/wg-agent.py
/usr/local/sbin/digitsell-wg-agent    symlink, run by the services
digitsell-wg-bypass.service           the routing mark, table and ipset
digitsell-wg-agent.service            reports to the panel every minute
```

## Watch it work

```bash
wg show wg0                       # peers, their addresses and counters
journalctl -u digitsell-wg-agent -f
ipset list ds-bypass | head       # the direct-route list
ip rule show                      # the marked traffic's table
```

The direct routes really are outside the tunnel: pick an address from the set
and it keeps the route it had before.

```bash
ipset test ds-bypass 5.61.23.100   # true for a listed address
ip route get 5.61.23.100          # no "table 51820" for it
```

## Remove

```bash
sudo bash uninstall.sh [--purge]
```

Takes the agent, the interface, the services, the ipset and the routing rules
down. `--purge` also removes the `wireguard-tools` package and the server's key
pair; without it the key stays, so a later install gives the same key and files
customers already downloaded keep working. Delete the server in the panel as
well — the panel keeps the usage already recorded either way.

## Troubleshooting

**The panel says the server is waiting.** The agent has not reported yet. Check
`journalctl -u digitsell-wg-agent`; it reports once a minute, and the first
hello is immediate.

**Customers connect but nothing is counted.** The agent may be running while the
push fails. Look for `push failed:` in its log — the panel refused, and the line
says why (a network problem, or a token).

**A customer's file does not connect.** Check `Endpoint` in it against
`wg show wg0 listen-port`, and that the port is open in the firewall.

**The panel offers the file but the download fails.** The panel needs the
sodium extension to derive each customer's public key. `php -m | grep -i
sodium` on the panel's PHP; without it the admin card says so at the top.

Persian version: [README.fa.md](README.fa.md).