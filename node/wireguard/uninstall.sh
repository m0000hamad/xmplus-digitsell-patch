#!/usr/bin/env bash
#
# Digitsell WireGuard node - removes what install.sh put on this server:
# the agent, the interface config, the direct-route rules and their services.
#
#   sudo bash uninstall.sh [--purge]
#
#   --purge     also remove the wireguard-tools package
#
# The server's key pair is kept unless --purge is given, so running install.sh
# again later gives the same key and files customers already downloaded keep
# working. Everything else goes.
#
# Removing the server in the panel (Servers -> WireGuard servers -> Delete) is
# a separate step; the panel keeps the usage already recorded either way.

set -euo pipefail

PURGE=0

while [ $# -gt 0 ]; do
    case "$1" in
        --purge) PURGE=1; shift ;;
        *) echo "unknown option: $1" >&2; exit 1 ;;
    esac
done

[ "$(id -u)" -eq 0 ] || { echo "error: run as root (sudo bash uninstall.sh)" >&2; exit 1; }

CONF=/etc/digitsell-wg/agent.json
IFACE=wg0

# the port the firewall was opened for, before the config goes
LISTEN=""
if [ -f "$CONF" ]; then
    LISTEN=$(sed -n 's/.*"listen_port"[[:space:]]*:[[:space:]]*\([0-9]*\).*/\1/p' "$CONF" | head -1)
fi

echo "==> stopping services"
systemctl disable --now digitsell-wg-agent.service >/dev/null 2>&1 || true
# stopping the bypass unit runs "bypass-stop", which removes the iptables rules
# and the routing table; run it directly too, in case the unit was never started
systemctl disable --now "wg-quick@$IFACE.service" >/dev/null 2>&1 || true
if [ -x /usr/local/sbin/digitsell-wg-agent ] && [ -f "$CONF" ]; then
    /usr/local/sbin/digitsell-wg-agent bypass-stop "$CONF" >/dev/null 2>&1 || true
fi
systemctl disable digitsell-wg-bypass.service >/dev/null 2>&1 || true

echo "==> firewall"
if [ -n "$LISTEN" ] && command -v ufw >/dev/null && ufw status 2>/dev/null | grep -q "Status: active"; then
    ufw --force delete "$LISTEN/udp" >/dev/null 2>&1 || true
fi
echo "    if you opened UDP $LISTEN in the firewall by hand, close it there too"

echo "==> files"
rm -f /etc/systemd/system/digitsell-wg-agent.service
rm -f /etc/systemd/system/digitsell-wg-bypass.service
rm -f /usr/local/sbin/digitsell-wg-agent
rm -rf /usr/local/lib/digitsell-wg
rm -f "/etc/wireguard/$IFACE.conf"
rm -f /etc/sysctl.d/99-digitsell-wg.conf
systemctl daemon-reload

if [ "$PURGE" = "1" ]; then
    echo "==> packages"
    DEBIAN_FRONTEND=noninteractive apt-get remove -y wireguard-tools >/dev/null 2>&1 || true
    rm -f "$CONF/server.key" "$CONF/server.pub"
    rmdir /etc/digitsell-wg 2>/dev/null || true
fi

# what is left: the key pair, so files customers already downloaded keep
# working on a later install
if [ ! -f "$CONF" ]; then
    rmdir /etc/digitsell-wg 2>/dev/null || true
fi

echo "==> done. Delete the server in the panel too (Servers -> WireGuard servers)."