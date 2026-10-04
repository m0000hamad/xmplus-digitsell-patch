#!/usr/bin/env bash
#
# Digitsell WireGuard node - installs WireGuard and the agent that ties it to
# the XMPlus panel, so WireGuard traffic goes through the customer's existing
# subscription.
#
# Add the server first in the panel (Servers -> WireGuard servers); that gives
# the node id and key and prints this command ready to paste:
#
#   sudo bash install.sh --panel https://panel.example.com --node 1 --key <key> \
#        [--listen auto|443] [--host vpn.example.com] [--dns "1.1.1.1 8.8.8.8"] \
#        [--interface wg0] [--mtu 1420]
#
# --listen auto (the default) keeps the port of an earlier install, else takes
# 51820, else the first free port above it - never one another program uses.
# Unlike OpenVPN there is nothing to redirect: WireGuard has a single socket,
# so the port has to be open in the firewall and is what customers connect to.
# The panel shows the port the server reported; changing it means running this
# command again with a different --listen.
#
# The agent (node/wireguard/wg-agent.py) reports every peer's byte counters to
# the panel once a minute and applies the panel's answers: it adds the peers of
# customers who may connect and removes the ones whose plan or data has run
# out. It also keeps an ipset with the panel's direct-route list (Iranian
# addresses and the admin's own destinations) and two iptables rules, so those
# destinations leave this server directly instead of through the tunnel. That
# is done here, on the server, which is why a customer's .conf file is the same
# on every client.
#
# Ubuntu 20.04+ / Debian 11+. Safe to run again: the server key pair is kept, so
# files customers already downloaded keep working; the settings and the key are
# rewritten (that is how a new key is put in place).

set -euo pipefail
# never stop without saying where: set -e alone exits silently
trap 'echo "error: install.sh stopped at line $LINENO: $BASH_COMMAND (exit $?)" >&2' ERR

REPO_RAW="${DIGITSELL_REPO_RAW:-https://raw.githubusercontent.com/m0000hamad/xmplus-digitsell-patch/main}"

PANEL=""
NODE=""
KEY=""
LISTEN="auto"
HOST=""
DNS="1.1.1.1 8.8.8.8"
IFACE="wg0"
MTU="1420"
AGENT_DIR=/usr/local/lib/digitsell-wg
CONF_DIR=/etc/digitsell-wg

die() { echo "error: $*" >&2; exit 1; }

while [ $# -gt 0 ]; do
    case "$1" in
        --panel)   PANEL="${2:-}"; shift 2 ;;
        --node)    NODE="${2:-}"; shift 2 ;;
        --key)     KEY="${2:-}"; shift 2 ;;
        --listen)  LISTEN="${2:-}"; shift 2 ;;
        --host)    HOST="${2:-}"; shift 2 ;;
        --dns)     DNS="${2:-}"; shift 2 ;;
        --interface) IFACE="${2:-}"; shift 2 ;;
        --mtu)     MTU="${2:-}"; shift 2 ;;
        -h|--help) sed -n '2,25p' "$0"; exit 0 ;;
        *) die "unknown option: $1" ;;
    esac
done

[ -n "$PANEL" ] || die "--panel is required (e.g. --panel https://panel.example.com)"
[ -n "$NODE" ] || die "--node is required (the server's number in the panel)"
[ -n "$KEY" ] || die "--key is required (the key the panel showed when the server was added)"
[[ "$NODE" =~ ^[0-9]+$ ]] || die "--node must be a number, got: $NODE"
if [[ "$PANEL" =~ ^(https?):/([^/].*) ]]; then
    PANEL="${BASH_REMATCH[1]}://${BASH_REMATCH[2]}"
fi
case "$PANEL" in
    https://*|http://*) ;;
    *) die "--panel must start with http:// or https://" ;;
esac
PANEL="${PANEL%/}"
[[ "$IFACE" =~ ^[a-zA-Z0-9_]{1,15}$ ]] || die "--interface must be a short interface name"
[[ "$MTU" =~ ^[0-9]+$ ]] && [ "$MTU" -ge 1280 ] && [ "$MTU" -le 1500 ] || die "--mtu must be 1280 to 1500"

# run a noisy command; show what it printed only if it fails
quiet() {
    if ! "$@" >/tmp/digitsell-wg-install.log 2>&1; then
        cat /tmp/digitsell-wg-install.log >&2
        die "command failed: $*"
    fi
}

need_root() {
    [ "$(id -u)" = "0" ] || die "run this with sudo"
}

# is this UDP port already taken by something on this server?
port_taken() {
    local port="$1"
    ss -lun 2>/dev/null | awk '{print $5}' | sed 's/.*://' | grep -qx -- "$port"
}

fetch() {
    local name="$1" dest="$2"
    quiet curl -fsSL "$REPO_RAW/node/wireguard/$name" -o "$dest"
}

need_root
command -v apt-get >/dev/null || die "this script is for Debian / Ubuntu"

echo "==> packages"
if ! command -v wg >/dev/null; then
    quiet env DEBIAN_FRONTEND=noninteractive apt-get update
    quiet env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        wireguard-tools iproute2 ipset iptables python3 curl
fi
for tool in wg wg-quick ipset iptables python3; do
    command -v "$tool" >/dev/null || die "$tool is missing; install it and run this again"
done

if [ "$LISTEN" = "auto" ]; then
    LISTEN=""
    # an earlier install's port: files customers already have point at it
    if [ -f "/etc/wireguard/$IFACE.conf" ]; then
        LISTEN=$(awk -F= '/^ListenPort/ {gsub(/[[:space:]]/, "", $2); print $2; exit}' "/etc/wireguard/$IFACE.conf")
    fi
    if [ -z "$LISTEN" ] || port_taken "$LISTEN"; then
        LISTEN=""
        for candidate in 51820 $(seq 51821 51920); do
            if ! port_taken "$candidate"; then LISTEN=$candidate; break; fi
        done
    fi
    [ -n "$LISTEN" ] || die "no free port found for WireGuard; pass --listen"
    echo "==> WireGuard will listen on UDP port $LISTEN (free on this server)"
elif port_taken "$LISTEN"; then
    die "UDP port $LISTEN is already used by another program here; pass another --listen or --listen auto"
fi

mkdir -p /etc/wireguard "$AGENT_DIR" "$CONF_DIR"
chmod 700 /etc/wireguard

# the server's own key pair: kept across installs, so files customers already
# downloaded keep working
SERVER_KEY_FILE="$CONF_DIR/server.key"
if [ ! -s "$SERVER_KEY_FILE" ]; then
    echo "==> server key pair"
    umask 077
    wg genkey > "$SERVER_KEY_FILE"
    wg pubkey < "$SERVER_KEY_FILE" > "$CONF_DIR/server.pub"
else
    echo "==> server key pair: kept the existing one"
    [ -s "$CONF_DIR/server.pub" ] || wg pubkey < "$SERVER_KEY_FILE" > "$CONF_DIR/server.pub"
fi
chmod 600 "$SERVER_KEY_FILE"

SERVER_PUBKEY=$(cat "$CONF_DIR/server.pub")
SERVER_IP=$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{for (i = 1; i <= NF; i++) if ($i == "src") print $(i + 1); exit}')
[ -n "$SERVER_IP" ] || die "cannot work out this server's IPv4 address"

echo "==> the address customers connect to"
cat > "$CONF_DIR/agent.json" <<EOF
{
  "panel": "$PANEL",
  "node": $NODE,
  "key": "$KEY",
  "interface": "$IFACE",
  "listen_port": $LISTEN,
  "host": "${HOST:-$SERVER_IP}",
  "server_ip": "$SERVER_IP",
  "public_key": "$SERVER_PUBKEY",
  "dns": "$DNS",
  "mtu": $MTU,
  "bypass_set": "ds-bypass",
  "bypass_mark": "0x51820",
  "bypass_table": "51820",
  "log": "/var/log/digitsell-wg-agent.log"
}
EOF
chmod 600 "$CONF_DIR/agent.json"

echo "==> WireGuard interface config"
cat > "/etc/wireguard/$IFACE.conf" <<EOF
[Interface]
Address = 10.$NODE.0.1/16
ListenPort = $LISTEN
PrivateKey = $(cat "$SERVER_KEY_FILE")
MTU = $MTU
Table = off
EOF
chmod 600 "/etc/wireguard/$IFACE.conf"

echo "==> routing"
cat > /etc/sysctl.d/99-digitsell-wg.conf <<EOF
net.ipv4.ip_forward = 1
EOF
sysctl -q -p /etc/sysctl.d/99-digitsell-wg.conf 2>/dev/null || sysctl -w net.ipv4.ip_forward=1 >/dev/null || true

echo "==> agent"
fetch wg-agent.py "$AGENT_DIR/wg-agent.py"
chmod 755 "$AGENT_DIR/wg-agent.py"
ln -sf "$AGENT_DIR/wg-agent.py" /usr/local/sbin/digitsell-wg-agent

cat > /etc/systemd/system/digitsell-wg-agent.service <<EOF
[Unit]
Description=Agent for the Digitsell WireGuard node
After=network-online.target wg-quick@$IFACE.service
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/local/sbin/digitsell-wg-agent $CONF_DIR/agent.json
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# the direct-route list is applied by the agent, which also needs the routing
# mark and its table to exist before the first packet arrives
cat > /etc/systemd/system/digitsell-wg-bypass.service <<EOF
[Unit]
Description=Direct routes for the Digitsell WireGuard node
Before=wg-quick@$IFACE.service
After=network-pre.target
Wants=network-pre.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/sbin/digitsell-wg-agent bypass-start $CONF_DIR/agent.json
ExecStop=/usr/local/sbin/digitsell-wg-agent bypass-stop $CONF_DIR/agent.json

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable "digitsell-wg-bypass.service" "digitsell-wg-agent.service" "wg-quick@$IFACE.service" >/dev/null

echo "==> starting services"
systemctl restart "digitsell-wg-bypass.service"
systemctl restart "wg-quick@$IFACE.service"
systemctl restart "digitsell-wg-agent.service"

echo "==> telling the panel who we are"
# the agent does its own hello on start; this only makes the admin's card fill in
# right away instead of on the next report
quiet curl -fsS -X POST \
    -H "X-Wg-Node: $NODE" -H "X-Wg-Key: $KEY" -H "Content-Type: application/json" \
    -d "{\"host\":\"${HOST:-$SERVER_IP}\",\"port\":$LISTEN,\"pubkey\":\"$SERVER_PUBKEY\",\"dns\":\"$DNS\",\"mtu\":$MTU}" \
    "$PANEL/xmplus-patch.php?do=wg.hello" >/dev/null || \
    echo "    the panel did not answer; the agent will report in a moment"

cat <<EOF

==> done

  interface        $IFACE on UDP $LISTEN
  server address   $SERVER_IP
  server key       $SERVER_PUBKEY
  customer file    $PANEL  (a customer downloads it in the panel)
  agent log        /var/log/digitsell-wg-agent.log
  panel cron       bin/wg.php runs every minute for the online / offline messages

Open this port in the firewall (and at the provider) or customers cannot
connect:

  iptables -I INPUT -p udp --dport $LISTEN -j ACCEPT

To watch customers connect:

  wg show $IFACE
  journalctl -u digitsell-wg-agent -f
EOF
