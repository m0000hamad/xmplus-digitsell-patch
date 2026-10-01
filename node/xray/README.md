**English** | [فارسی](README.fa.md)

# Xray node — standalone Xray backend for the XMPlus panel

A drop-in replacement for the XMPlus node binary: the **official, latest Xray-core** (from
XTLS/Xray-core) plus a small agent that talks to the panel's node API. The panel needs no
change; servers are still defined and edited in the panel and this node pulls their settings.

| | XMPlus node | This node |
|---|---|---|
| Xray core | XMPlus fork, updated when they update it | official; `digitsell-xray update` always gets the newest |
| XHTTP (`mode` and extras) | `mode` is ignored (bug) | complete; any xhttp key from the panel's network settings |
| Add / remove users | no restart | no restart (Xray API) |
| Updating the node | all connections drop | agent is separate from Xray; nobody is disconnected |
| Panel briefly down | traffic of that period is lost | traffic stays on disk and is reported later |
| Reboot while panel is down | node does not come up | comes up with the last saved settings and users |
| Device limit (IP limit) | yes | yes (extra IPs go to a blackhole) |
| Speed limit | yes | **no** — official Xray has no per-user speed limit |

## Install

### Guided (any server)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/m0000hamad/xmplus-digitsell-patch/main/node/xray/install.sh)
```

Run as root at a terminal, the installer asks before it changes anything:

1. **Panel address** (the origin, not one behind a CDN) and **API key** (the ApiKey in the panel's
   API settings; typed hidden). A wrong key is refused on the spot.
2. It lists **every server of the panel** — id, name, protocol, port, domain / IP — and marks
   **HERE** the ones whose domain or IP points at this machine. Those are the default answer.
3. **Which node ids this server runs**: ids (comma separated), `all` for every server listed, or `here` for the HERE ones. Each one is checked against the panel.
4. What the chosen nodes need: a Let's Encrypt e-mail (cert mode http / tls / dns), the DNS
   provider and its keys (mode dns), the certificate files (mode file: a certificate on the server made out for the node's domain
   is found by itself - /root, /root/cert, /etc/XMPlus, letsencrypt... - with the key that really
   belongs to it, its expiry checked, and a key other users can read made root-only). Warnings: two nodes on one port, a port another program holds, a domain
   that does not point here yet (its certificate would fail).
5. A summary, and **"Install? [Y/n]"**. Nothing is installed before this answer.

On a server that runs XMPlus, `config.yml` fills in every answer (panel, key, nodes, certificate
files), so it is Enter, Enter, `y`. `--yes` takes the defaults without asking (scripts).

The list needs the Digitsell patch **1.19.0** on the panel (`xmplus-patch.php?do=node.list`). With
an older panel the installer says so and asks for the node ids, checking each against the
panel's node API.

`--pick` asks again on a server that is already set up — to add or drop nodes.

### Automatic (servers that already run XMPlus, no questions)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/m0000hamad/xmplus-digitsell-patch/main/node/xray/install.sh) --yes
```

The installer:

1. finds the XMPlus node `config.yml` (`/etc/XMPlus/config.yml` or `/root/config.yml`) and reads
   the panel URL, ApiKey, all NodeIDs, certificate e-mail and DNS provider, fallbacks, rulelist
   and ConnectionConfig;
2. reuses XMPlus's Let's Encrypt certificates (nothing is re-issued);
3. downloads the latest Xray and lego and verifies checksums;
4. **stops and disables** XMPlus (it is not removed, see "Going back to XMPlus");
5. turns on BBR and network tuning (replaces `bbr.sh`, no kernel change);
6. asks the panel for each node's settings, prints a summary, and opens ports in ufw if needed.

### Manual (fresh server)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/m0000hamad/xmplus-digitsell-patch/main/node/xray/install.sh) \
  --panel https://origin.example.com --key <ApiKey> --node 74
```

- `--key` is the `ApiKey` of the XMPlus node's config.yml (the panel API key).
- Several nodes on one server: `--node 74 --node 75` or `--node 74,75`.
- DNS certificate (e.g. Cloudflare; best behind a CDN):
  `--email you@example.com --dns-provider cloudflare --dns-env CF_DNS_API_TOKEN=xxxx`
  (provider and variable names are lego's: `lego dnshelp`; same as in XMPlus's config.yml).
- `--keep-xmplus` does not stop XMPlus (only if the ports differ), `--no-bbr` leaves sysctl alone,
  `--xray-version v26.9.30` pins a version.

Re-running is safe: `agent.json` is merged, not replaced.

### Commands

```bash
digitsell-xray status     # nodes, user count, online, certificate, last traffic report
digitsell-xray log        # live log (agent + Xray)
digitsell-xray doctor     # full check: services, API, panel, ports, certificate, DNS, BBR, clock
digitsell-xray check      # each node's panel settings + warnings
digitsell-xray update     # latest Xray / geo / lego / agent (settings are kept)
digitsell-xray config     # edit agent.json and restart
digitsell-xray render     # print the Xray config that gets generated
digitsell-xray uninstall  # remove (--keep-config, --restore-xmplus)
```

`dxray` is a short alias of the same command.

## Protocols and recommended panel settings

Everything is set in panel → Servers → edit server, under "Network settings" and "Security
settings". After saving, the node picks the change up within a minute; users only refresh their
subscription.

Notes that apply to all profiles:

- **Turn `allowInsecure` off.** New Xray removed it, and apps on the new core refuse links that
  contain `allowInsecure=1`. With a real certificate (Let's Encrypt or CDN) it is not needed.
- The WebSocket "deprecated" line in the log is a notice, not an error (WS stays supported;
  XHTTP is the successor).

### 1. VLESS + XHTTP + TLS behind a CDN (recommended; replaces WS)

Server type VLESS · port `443` (or a Cloudflare HTTPS port: 2053, 2083, 2087, 2096, 8443) ·
security tls · certificate mode `dns` (best behind a CDN) or `http`.

Network settings:

```json
{
  "transport": "xhttp",
  "acceptProxyProtocol": false,
  "path": "/openai",
  "host": "s1.example.com",
  "mode": "auto",
  "cdn_host": "chatgpt.com"
}
```

Security settings:

```json
{
  "serverName": "s1.example.com",
  "rejectUnknownSni": false,
  "allowInsecure": false,
  "fingerprint": "chrome",
  "flow": "none"
}
```

- Cloudflare: DNS record orange (Proxied), SSL/TLS **Full (strict)** (**Full** with a self-signed cert).
- `mode: auto` suits a CDN. If your CDN buffers requests and it is slow, try `"mode": "packet-up"`.
- Do not add `?ed=2560` (WebSocket only).
- Apps without XHTTP (core older than 2025) cannot connect; keep profile 5 on another node/port
  for them.

### 2. VLESS + XHTTP + TLS direct (no CDN)

Same as profile 1 with a grey-cloud (DNS only) record, certificate mode `http` (port 80 must be
free) or `dns`, and without `cdn_host`.

### 3. VLESS + REALITY + Vision (fastest; no domain, no certificate)

Server type VLESS · port `443` · security reality.

Generate keys (PrivateKey goes in the panel; Password/PublicKey is for the links):

```bash
/usr/local/lib/digitsell-xray/xray x25519
```

Network settings:

```json
{
  "transport": "tcp",
  "acceptProxyProtocol": false,
  "flow": "xtls-rprx-vision",
  "header": { "type": "none" }
}
```

Security settings:

```json
{
  "show": false,
  "dest": "www.example-site.com:443",
  "serverNames": ["www.example-site.com"],
  "privatekey": "<PrivateKey>",
  "publickey": "<Password (PublicKey)>",
  "shortids": ["", "a1b2c3d4"],
  "fingerprint": "chrome",
  "flow": "xtls-rprx-vision"
}
```

- `dest` / `serverNames`: a foreign site with TLS 1.3 and HTTP/2 that is not blocked in Iran,
  ideally in the same data center / country as your server. Very famous sites (microsoft,
  apple) are flagged by Xray itself as raising the risk of an IP block.
- The node does not need `publickey`; the panel uses it to build links.
- Does not work behind a CDN (REALITY is direct).

### 4. VLESS + XHTTP + REALITY

Like profile 3, with XHTTP network settings:

```json
{
  "transport": "xhttp",
  "acceptProxyProtocol": false,
  "path": "/api/v2",
  "mode": "auto"
}
```

Security settings as in profile 3 but with `"flow": "none"`.

### 5. VMess / VLESS + WebSocket + TLS (legacy, still works)

Your existing settings, with `allowInsecure` set to `false`:

```json
{
  "transport": "ws",
  "acceptProxyProtocol": false,
  "path": "/openai?ed=2560",
  "host": "s1.example.com",
  "heartbeatperiod": 10,
  "cdn_host": "chatgpt.com"
}
```

Security settings as in profile 1.

### 6. Shadowsocks 2022

Server type Shadowsocks · method `2022-blake3-aes-128-gcm` · network `{"transport": "tcp"}` ·
security none · server key in the panel: output of `openssl rand -base64 16`
(`openssl rand -base64 32` for `aes-256` and `chacha20`).

### Extra XHTTP settings

Any of these keys can go into the panel's network settings and is passed to Xray as-is: `mode`
(`auto` / `packet-up` / `stream-up` / `stream-one`), `xPaddingBytes`, `noSSEHeader`,
`scMaxEachPostBytes`, `scMaxBufferedPosts`, `scStreamUpServerSecs`, `serverMaxHeaderBytes`,
`headers`, `extra`, and the rest of xhttpSettings in the
[Xray docs](https://xtls.github.io/config/transports/xhttp.html).

## Direct (bypass) for Iran and chosen sites

Panel → Servers → OpenVPN servers → **Direct bypass** → tick **"Apply to Xray (V2Ray) users too —
Happ app"** (patch 1.17.0).

The same list as OpenVPN (Iranian IPs and domains plus your own destinations) is sent in the
subscription link to the **Happ** app, which opens those destinations directly (not through the
server). Users just refresh the subscription. Unticking the box turns the profile off in users'
Happ too.

Why only Happ, and why in the panel rather than on the server: in Xray the decision of what
should not go through the server belongs to the **user's app**; once traffic reaches the server
it is too late. Among common apps only Happ takes routing from the subscription link. In
v2rayNG / V2Box / Shadowrocket the user turns on the app's own "Bypass Iran" routing. This works
for links that come from `xmplus-patch.php?do=sub` (the "subscription info in apps" link).

## agent.json

`/etc/digitsell-xray/agent.json` — written by the installer; edit with `digitsell-xray config`.

| Key | Default | Meaning |
|---|---|---|
| `panel` | — | panel URL (one that is not behind a CDN, e.g. `https://origin.example.com`) |
| `key` | — | panel ApiKey |
| `nodes` | — | node IDs: `[74, 75]`, or objects for per-node settings: `{"id": 74, "panel": "...", "key": "...", "cert_file": "...", "key_file": "...", "fallbacks": [...]}` |
| `interval` | `60` | seconds between panel polls / traffic reports |
| `limit_interval` | `15` | seconds between device-limit checks |
| `ip_limit` | `true` | enforce the panel's device limit |
| `block_private` | `true` | users cannot reach the server's internal / LAN IPs |
| `block_bittorrent` | `false` | block torrents |
| `block_regex_file` | — | file of blocked-domain regexes, one per line (like XMPlus's rulelist). The panel's "rules" are applied automatically too |
| `domain_strategy` | `AsIs` | freedom: `AsIs`, `UseIP`, `UseIPv4`, `UseIPv6` |
| `dns` | — | Xray's own `dns` object, verbatim |
| `policy` | — | `handshake`, `connIdle`, `uplinkOnly`, `downlinkOnly`, `bufferSize` |
| `log_level` | `warning` | `debug`, `info`, `warning`, `error`, `none` |
| `access_log` | — | path of a connection log (off by default) |
| `trusted_xff` | `["CF-Connecting-IP", "X-Real-IP", "True-Client-IP"]` | behind a CDN: when one of these headers (set by the CDN) is present, the user's real IP is read from `X-Forwarded-For`; without it every user has the CDN's IP and the device limit misbehaves. `[]` turns it off |
| `api` | `127.0.0.1:10085` | Xray's internal API |
| `cert.email` | — | Let's Encrypt e-mail |
| `cert.provider` / `cert.env` | — | DNS provider and its keys for certificate mode `dns` (lego names) |
| `cert.file` / `cert.key` | — | ready-made certificate for mode `file` (or `/etc/digitsell-xray/certs/<domain>.crt` and `.key`) |
| `nodes[].tor` | — | this node's traffic leaves through a [tor-geo](https://github.com/m0000hamad/tor-multi-location) node on this server, e.g. `"fr"` (see below) |
| `nodes[].proxy` | — | this node's traffic leaves through a SOCKS5 proxy: `"socks5://host:port"` or `"socks5://user:pass@host:port"` |

## Exit location per node (Tor / SOCKS5)

One server can sell several countries: each panel server (node) gets its own exit.

1. Install [tor-geo](https://github.com/m0000hamad/tor-multi-location) on the node server and
   add the countries: `tor-geo add fr de us`. `tor-geo list` shows the node names (`fr`, `de`, …).
2. In the panel, add one server per country on its own port (and set its flag).
3. In `agent.json` (`digitsell-xray config`) give each of those nodes its exit:

```json
"nodes": [
  {"id": 74, "tor": "fr"},
  {"id": 75, "tor": "de"},
  {"id": 76}
]
```

Node 76 keeps leaving directly from the server's own IP. `digitsell-xray status` shows each
node's exit; a `tor` name that does not exist is reported there and that node leaves directly.

Tor carries TCP only: for a `tor` node QUIC (UDP 443) is refused, so browsers fall back to TCP
through Tor, and other UDP (DNS, games, calls) leaves directly from the server. The panel's block
rules and the device limit still apply first.

### From the panel (agent 1.2.0, patch 1.18.0)

With the patch 1.18.0 or later on the panel, none of the above has to be done by hand:
**Servers → Exit location per server (Tor)** lists every server with its agent's report and a
country picker (the list, with exit counts, comes from the node itself). After a choice is saved
the agent, within a minute:

1. installs tor-geo if the server does not have it yet;
2. starts a tor-geo node for that country (`tor-geo add`);
3. waits until that exit answers (checked through it against api.ipify.org);
4. only then switches the server over (one Xray restart).

Until step 4 the server keeps its previous exit, so customers never land on an exit that does not
work yet. tor-geo nodes the agent started and no server wants any more are removed again; nodes
you added by hand are never touched. "As set on the server (agent.json)" hands the choice back to
`agent.json`. The panel's choice is kept in `state.json`, so a reboot while the panel is down
keeps every server where it was.

The agent calls `xmplus-patch.php?do=torexit.sync` with the panel's API key (in an `X-Panel-Key`
header) every minute. The panel never connects to the servers and stores no server password.

## How it works

- **Two services:** `digitsell-xray` (the official Xray) and `digitsell-xray-agent` (Python,
  standard library only). Restarting or updating the agent disconnects nobody.
- **Node settings** come from the panel's `GET /api/server/<id>` with an ETag (only when
  changed). Xray restarts only when node settings change; the new config is first tested with
  `xray run -test`, and if Xray rejects it the node keeps the previous settings and the error
  shows in `status`.
- **Users** from `GET /api/subscriptions/<id>`; added / removed with `xray api adu` / `rmu`,
  no restart.
- **Traffic** is read from Xray's counters every minute, reset, and sent to
  `POST /api/traffic/<id>`; if the panel does not answer it stays on disk and goes with the next
  report.
- **Online users** go to `POST /api/onlineip/<id>`. Behind a CDN the real IP comes from
  `X-Forwarded-For` (new Xray accepts it only if a CDN header such as `CF-Connecting-IP` is also
  present — `trusted_xff`).
- **Device limit** as in XMPlus: `iplimit - ipcount + (this node's IPs in the previous report)`;
  an account with no free slot does not come up on this node at all, and IPs beyond this node's
  share are sent to a blackhole by a rule. An IP that holds a slot keeps it for 2 minutes after
  its last connection closes.
- **Certificates** via lego (the panel's `http`, `tls`, `dns` modes), renewed 30 days before
  expiry; Xray rereads the certificate file hourly by itself (no restart). Until a real
  certificate is obtained a self-signed one is used so the node comes up (works behind a CDN in
  Full mode), and it retries every 10 minutes.
- Panel **relay** (chain to another node) and **sendthrough** are supported.

## Going back to XMPlus

```bash
digitsell-xray uninstall --restore-xmplus
```

or without removing: `systemctl disable --now digitsell-xray digitsell-xray-agent && systemctl enable --now XMPlus`.

## Troubleshooting

### After adding an xhttp node, the subscription update or the Servers page (/portal/servers) returns "Internal Server Error"

This is a bug in the **panel**, not the node. The panel's link builders (`app/Http/Schema/`:
`Xray.php` for the subscription link, `VlessURI.php` and relatives for the Servers page) read
keys such as `headerType` and `alpn` without checking, and for xhttp the controller does not
send them; Whoops turns the PHP warning into a fatal error, which breaks the subscription of
**every** account that sees that node. The message is `Undefined index: headerType` in
`Xray.php:85` (subscription) or `VlessURI.php:12` (Servers page). To see the real message (on
the panel server):

```bash
curl -sk --resolve <panel-domain>:443:127.0.0.1 "https://<panel-domain>/link/<token>?config=1" -o /tmp/err.html
python3 -c "import re,html;t=open('/tmp/err.html',errors='ignore').read();t=re.sub(r'(?s)<(style|script).*?</\1>','',t);t=re.sub(r'<[^>]+>','\n',t);print('\n'.join(l.strip() for l in html.unescape(t).splitlines() if l.strip())[:700])"
```

**From patch 1.17.1 on you need to do nothing:** the patch fixes these files at install time and
checks hourly (output in `storage/logs/schemafix.log` only when something changes); if a panel
update reverts the files, they are fixed again within an hour. Just install 1.17.1 (or newer)
under "Settings → Patch update". The script below is for a panel without the patch, or if you
do not want to wait an hour.

Manual fix, once, on the **panel server**. It checks every file in `app/Http/Schema/` and
touches only what is needed (backs up each file, checks syntax, rolls back on error):

```bash
curl -fsSL https://raw.githubusercontent.com/m0000hamad/xmplus-digitsell-patch/main/node/xray/fix-panel-xhttp.py | python3 - /www/wwwroot/panel.example.com
```

Then enable the xhttp node and run the `curl` above again: it should return `200`. If it stays
500, disable the node immediately and send the message. The fix is lost whenever a panel update
changes `Xray.php`; run it again. (Disabling any node that returns 500 restores the
subscription at once.)

### Node is up but "0 online" and no usage is reported

```bash
ss -tn state established '( sport = :PORT )'     # empty = nobody reaches this server
ss -ltnp | grep ':PORT '                         # must be xray, not XMPlus
systemctl is-active XMPlus xmplus                # both inactive
echo | openssl s_client -connect 127.0.0.1:PORT -servername DOMAIN 2>/dev/null | openssl x509 -noout -subject -dates
```

If no connection is established the problem is the route, not the node: the domain's DNS record
does not point to this server's IP (or to a CDN with the right origin). `dxray doctor` only says
"something is listening on the port", not what.

### Normal things in the log

- `node N: +2 -0 account(s)` every minute: the panel's device limit (an account that hit its
  cap on other nodes is dropped).
- `starting Xray: ...` after a node's settings changed in the panel; connections re-establish.
- `TLS handshake error ... i/o timeout` and `client sent an HTTP request to an HTTPS server`:
  internet scanners.
- The installer takes the Xray version from GitHub's "latest release" (it may lag the newest
  pre-release): `dxray update --xray-version v26.9.30`.
- A certificate you supplied as a file (mode `file`) is not renewed; `dxray status` shows the
  days left.

## Limitations

- The panel's speed limit is not applied; `check` warns for a node that has one.
- mKCP with `seed` / `header`: new Xray moved these to finalmask; clients that have a seed
  cannot connect.
- HTTP/2 and QUIC transports were removed from Xray; `check` says so and the node does not come
  up — use XHTTP.
- The agent does not build subscription links; the panel does. If your panel's transport list
  has no XHTTP, keep WS (profile 5) — this node works with it too.
