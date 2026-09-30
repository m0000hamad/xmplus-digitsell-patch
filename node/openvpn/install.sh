#!/usr/bin/env bash
#
# Digitsell OpenVPN node - installs OpenVPN and the agent that ties it to the
# XMPlus panel, so OpenVPN logins and traffic go through the customer's
# existing subscription.
#
# Add the server first in the panel (Settings -> OpenVPN servers); that gives
# the node id and key and prints this command ready to paste:
#
#   sudo bash install.sh --panel https://panel.example.com --node 1 --key <key> \
#        [--port 1194] [--proto udp|tcp] [--host vpn.example.com] \
#        [--dns "1.1.1.1 8.8.8.8"] [--subnet 10.8.0.0/16] \
#        [--single-port] [--exclude "80 443"]
#
# By default every port of the chosen protocol is redirected to OpenVPN, so the
# port customers connect to is set in the panel (Settings -> OpenVPN servers ->
# ports for customers) without touching this server. Ports another program here
# listens on (SSH, a web server, Xray...) are left alone automatically;
# --exclude names more to leave alone, --single-port turns the redirect off.
#
# Ubuntu 20.04+ / Debian 11+. Safe to run again: the certificate authority is
# kept, so profiles customers already downloaded keep working; settings and
# the key are rewritten (that is how a new key is put in place).

set -euo pipefail

REPO_RAW="${DIGITSELL_REPO_RAW:-https://raw.githubusercontent.com/m0000hamad/xmplus-digitsell-patch/main}"

PANEL=""
NODE=""
KEY=""
PORT="1194"
PROTO="udp"
HOST=""
DNS="1.1.1.1 8.8.8.8"
SUBNET="10.8.0.0/16"
ALL_PORTS=1
EXCLUDE=""

while [ $# -gt 0 ]; do
    case "$1" in
        --panel)  PANEL="$2"; shift 2 ;;
        --node)   NODE="$2"; shift 2 ;;
        --key)    KEY="$2"; shift 2 ;;
        --port)   PORT="$2"; shift 2 ;;
        --proto)  PROTO="$2"; shift 2 ;;
        --host)   HOST="$2"; shift 2 ;;
        --dns)    DNS="$2"; shift 2 ;;
        --subnet) SUBNET="$2"; shift 2 ;;
        --single-port) ALL_PORTS=0; shift ;;
        --exclude) EXCLUDE="$2"; shift 2 ;;
        *) echo "unknown option: $1" >&2; exit 1 ;;
    esac
done

die() { echo "error: $*" >&2; exit 1; }

# run a noisy command; show what it printed only if it fails
quiet() {
    local out
    if ! out=$("$@" 2>&1); then
        echo "$out" >&2
        die "failed: $*"
    fi
}

[ "$(id -u)" -eq 0 ] || die "run as root (sudo bash install.sh ...)"
[ -n "$PANEL" ] && [ -n "$NODE" ] && [ -n "$KEY" ] || die "--panel, --node and --key are required"
[[ "$PANEL" =~ ^https?://[A-Za-z0-9.:-]+(/.*)?$ ]] || die "--panel must look like https://panel.example.com"
[[ "$NODE" =~ ^[0-9]+$ ]] || die "--node must be a number"
[[ "$KEY" =~ ^[A-Za-z0-9]{32,128}$ ]] || die "--key does not look like a node key"
[[ "$PORT" =~ ^[0-9]+$ ]] && [ "$PORT" -ge 1 ] && [ "$PORT" -le 65535 ] || die "bad --port"
[ "$PROTO" = "udp" ] || [ "$PROTO" = "tcp" ] || die "--proto must be udp or tcp"
[[ "$SUBNET" =~ ^([0-9]+\.){3}[0-9]+/(1[6-9]|2[0-4])$ ]] || die "--subnet must be like 10.8.0.0/16 (/16 to /24)"
command -v apt-get >/dev/null || die "this installer supports Debian and Ubuntu only"

[ -z "$HOST" ] || [[ "$HOST" =~ ^[A-Za-z0-9.:-]{1,253}$ ]] || die "--host may only hold a host name or an IP"
for server in $DNS; do
    [[ "$server" =~ ^[0-9a-fA-F.:]+$ ]] || die "--dns takes IP addresses separated by spaces"
done
[[ "$EXCLUDE" =~ ^[0-9\ ,]*$ ]] || die "--exclude takes port numbers"

echo "==> installing packages"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq openvpn easy-rsa python3 curl iptables iproute2 ca-certificates openssl >/dev/null

NET="${SUBNET%/*}"
MASK=$(python3 -c "import ipaddress,sys; print(ipaddress.ip_network(sys.argv[1], strict=False).netmask)" "$SUBNET")

# openvpn --version exits 1, and head closing the pipe early would trip pipefail
OVPN_VERSION=$( (openvpn --version 2>/dev/null || true) | awk 'NR == 1 {print $2}')
case "$OVPN_VERSION" in
    2.4*|2.5*|2.6*|2.7*|2.[89]*) ;;
    *) die "OpenVPN 2.4 or newer is needed (found ${OVPN_VERSION:-none})" ;;
esac

SERVER_DIR=/etc/openvpn/server
RSA_DIR=$SERVER_DIR/easy-rsa
AGENT_DIR=/usr/local/lib/digitsell-ovpn
CONF_DIR=/etc/digitsell-ovpn
mkdir -p "$SERVER_DIR" "$AGENT_DIR" "$CONF_DIR"
chmod 700 "$CONF_DIR"

echo "==> certificate authority"
if [ ! -f "$RSA_DIR/pki/ca.crt" ]; then
    rm -rf "$RSA_DIR"
    cp -r /usr/share/easy-rsa "$RSA_DIR"
    (
        cd "$RSA_DIR"
        export EASYRSA_BATCH=1 EASYRSA_ALGO=ec EASYRSA_CURVE=prime256v1
        export EASYRSA_CA_EXPIRE=7300 EASYRSA_CERT_EXPIRE=7300
        quiet ./easyrsa init-pki
        # the common name only for the CA: Easy-RSA 3.1 refuses one on build-server-full
        quiet env EASYRSA_REQ_CN="Digitsell OpenVPN CA" ./easyrsa build-ca nopass
        quiet ./easyrsa build-server-full server nopass
    )
else
    echo "    kept the existing one"
fi
[ -f "$RSA_DIR/pki/issued/server.crt" ] || die "easy-rsa did not produce a server certificate"

if [ ! -f "$SERVER_DIR/tc.key" ]; then
    openvpn --genkey secret "$SERVER_DIR/tc.key" 2>/dev/null || openvpn --genkey --secret "$SERVER_DIR/tc.key"
fi
chmod 600 "$SERVER_DIR/tc.key"

if [ ! -f "$SERVER_DIR/mgmt.pw" ]; then
    openssl rand -hex 24 > "$SERVER_DIR/mgmt.pw"
fi
chmod 600 "$SERVER_DIR/mgmt.pw"

echo "==> OpenVPN configuration"
DNS_LINES=""
for server in $DNS; do
    DNS_LINES="${DNS_LINES}push \"dhcp-option DNS ${server}\""$'\n'
done
EXIT_NOTIFY=""
[ "$PROTO" = "udp" ] && EXIT_NOTIFY="explicit-exit-notify 1"

cat > "$SERVER_DIR/digitsell.conf" <<EOF
# written by the Digitsell installer; run install.sh again rather than editing
port $PORT
proto $PROTO
dev tun
ca $RSA_DIR/pki/ca.crt
cert $RSA_DIR/pki/issued/server.crt
key $RSA_DIR/pki/private/server.key
dh none
ecdh-curve prime256v1
tls-crypt $SERVER_DIR/tc.key
tls-version-min 1.2
topology subnet
server $NET $MASK
push "redirect-gateway def1 bypass-dhcp"
${DNS_LINES}keepalive 10 60
user nobody
group nogroup
persist-key
persist-tun
# logins are username + password, decided by the panel through the agent
verify-client-cert none
username-as-common-name
duplicate-cn
management 127.0.0.1 7505 $SERVER_DIR/mgmt.pw
management-client-auth
reneg-sec 0
max-clients 4000
verb 3
$EXIT_NOTIFY
EOF

echo "==> routing"
cat > /etc/sysctl.d/99-digitsell-ovpn.conf <<EOF
net.ipv4.ip_forward = 1
EOF
sysctl -q -p /etc/sysctl.d/99-digitsell-ovpn.conf

SELF_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
fetch() {  # a file from node/openvpn/: next to this script, or from the repository
    if [ -f "$SELF_DIR/$1" ]; then cp "$SELF_DIR/$1" "$2"; else curl -fsSL "$REPO_RAW/node/openvpn/$1" -o "$2"; fi
}

cat > "$CONF_DIR/nat.conf" <<EOF
# read by /usr/local/sbin/digitsell-ovpn-nat; run install.sh again to change
SUBNET=$SUBNET
PROTO=$PROTO
PORT=$PORT
ALL_PORTS=$ALL_PORTS
EXCLUDE="$EXCLUDE"
EOF
fetch digitsell-ovpn-nat /usr/local/sbin/digitsell-ovpn-nat
chmod 755 /usr/local/sbin/digitsell-ovpn-nat

cat > /etc/systemd/system/digitsell-ovpn-nat.service <<EOF
[Unit]
Description=NAT for the Digitsell OpenVPN node
Before=openvpn-server@digitsell.service
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/sbin/digitsell-ovpn-nat start
ExecStop=/usr/local/sbin/digitsell-ovpn-nat stop

[Install]
WantedBy=multi-user.target
EOF

# the ports left alone are looked at again every minute, so a service started
# later (a web server, Xray) is never redirected into OpenVPN
cat > /etc/systemd/system/digitsell-ovpn-nat-refresh.service <<EOF
[Unit]
Description=Refresh the ports the Digitsell OpenVPN redirect leaves alone
After=digitsell-ovpn-nat.service

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/digitsell-ovpn-nat refresh
EOF

cat > /etc/systemd/system/digitsell-ovpn-nat-refresh.timer <<EOF
[Unit]
Description=Refresh the Digitsell OpenVPN port redirect every minute

[Timer]
OnBootSec=30
OnUnitActiveSec=60

[Install]
WantedBy=timers.target
EOF

if command -v ufw >/dev/null && ufw status 2>/dev/null | grep -q "Status: active"; then
    ufw allow "$PORT/$PROTO" >/dev/null
fi

echo "==> agent"
fetch ovpn-agent.py "$AGENT_DIR/ovpn-agent.py"
chmod 755 "$AGENT_DIR/ovpn-agent.py"

if [ -z "$HOST" ]; then
    HOST=$(curl -4 -fsS --max-time 10 https://api.ipify.org 2>/dev/null || true)
fi
if [ -z "$HOST" ]; then
    HOST=$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{for (i = 1; i < NF; i++) if ($i == "src") { print $(i + 1); exit }}')
fi
[ -n "$HOST" ] || die "could not work out this server's public address; pass --host"

python3 - "$CONF_DIR/agent.json" <<EOF
import json, sys
json.dump({
    "panel": "$PANEL",
    "node": $NODE,
    "key": "$KEY",
    "host": "$HOST",
    "port": $PORT,
    "proto": "$PROTO",
    "ca": "$RSA_DIR/pki/ca.crt",
    "tls_crypt": "$SERVER_DIR/tc.key",
    "mgmt_host": "127.0.0.1",
    "mgmt_port": 7505,
    "mgmt_password_file": "$SERVER_DIR/mgmt.pw",
    "all_ports": $ALL_PORTS == 1,
    "excluded_file": "/run/digitsell-ovpn-nat.excluded"
}, open(sys.argv[1], "w"), indent=2)
EOF
chmod 600 "$CONF_DIR/agent.json"

cat > /etc/systemd/system/digitsell-ovpn-agent.service <<EOF
[Unit]
Description=Digitsell OpenVPN agent (logins and traffic through the panel)
After=network-online.target openvpn-server@digitsell.service
Wants=network-online.target

[Service]
ExecStart=/usr/bin/python3 $AGENT_DIR/ovpn-agent.py $CONF_DIR/agent.json
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

echo "==> checking the panel"
if ! python3 "$AGENT_DIR/ovpn-agent.py" "$CONF_DIR/agent.json" --check; then
    die "the panel refused this node - check --panel, --node and --key (a new key in the panel invalidates the old one)"
fi

echo "==> starting"
systemctl daemon-reload
systemctl enable --now digitsell-ovpn-nat.service >/dev/null
systemctl restart digitsell-ovpn-nat.service
systemctl enable --now digitsell-ovpn-nat-refresh.timer >/dev/null
systemctl enable openvpn-server@digitsell.service >/dev/null
systemctl restart openvpn-server@digitsell.service
systemctl enable digitsell-ovpn-agent.service >/dev/null
systemctl restart digitsell-ovpn-agent.service

sleep 2
systemctl is-active --quiet openvpn-server@digitsell.service || die "OpenVPN did not start: journalctl -u openvpn-server@digitsell -n 50"
systemctl is-active --quiet digitsell-ovpn-agent.service || die "the agent did not start: journalctl -u digitsell-ovpn-agent -n 50"

echo
echo "Done. OpenVPN listens on $HOST:$PORT/$PROTO and answers to the panel at $PANEL."
if [ "$ALL_PORTS" = "1" ]; then
    echo "Every $PROTO port is redirected to it except: $(/usr/local/sbin/digitsell-ovpn-nat excluded | tr '\n' ' ')"
    echo "Choose the port customers use in the panel: Settings -> OpenVPN servers -> edit."
fi
echo "Logs: journalctl -u digitsell-ovpn-agent -f"
