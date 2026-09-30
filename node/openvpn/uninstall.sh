#!/usr/bin/env bash
#
# Digitsell OpenVPN node - removes what install.sh put on this server:
# the agent, the OpenVPN server config, the NAT rules and their services.
#
#   sudo bash uninstall.sh [--keep-ca] [--purge]
#
#   --keep-ca   keep the certificate authority (/etc/openvpn/server/easy-rsa and
#               tc.key), so running install.sh again later gives the same CA and
#               profiles customers already downloaded keep working
#   --purge     also remove the openvpn and easy-rsa packages
#
# Removing the server in the panel (Settings -> OpenVPN servers -> Delete) is a
# separate step; the panel keeps the usage already recorded either way.

set -euo pipefail

KEEP_CA=0
PURGE=0

while [ $# -gt 0 ]; do
    case "$1" in
        --keep-ca) KEEP_CA=1; shift ;;
        --purge)   PURGE=1; shift ;;
        *) echo "unknown option: $1" >&2; exit 1 ;;
    esac
done

[ "$(id -u)" -eq 0 ] || { echo "error: run as root (sudo bash uninstall.sh)" >&2; exit 1; }

SERVER_DIR=/etc/openvpn/server

# the ports and protocols the firewall was opened for, before the configs go
OPENINGS=""
for conf in "$SERVER_DIR/digitsell.conf" "$SERVER_DIR/digitsell-tcp.conf"; do
    [ -f "$conf" ] || continue
    OPENINGS="$OPENINGS $(awk '$1 == "port" {p = $2} $1 == "proto" {q = $2} END {if (p && q) print p "/" q}' "$conf")"
done

echo "==> stopping services"
for unit in digitsell-ovpn-nat-refresh.timer digitsell-ovpn-agent.service \
            openvpn-server@digitsell.service openvpn-server@digitsell-tcp.service; do
    systemctl disable --now "$unit" >/dev/null 2>&1 || true
done
# stopping the NAT unit runs "digitsell-ovpn-nat stop", which removes its iptables rules
systemctl disable --now digitsell-ovpn-nat.service >/dev/null 2>&1 || true
# and once more directly, in case the unit was never started
[ -x /usr/local/sbin/digitsell-ovpn-nat ] && /usr/local/sbin/digitsell-ovpn-nat stop || true

if command -v ufw >/dev/null && ufw status 2>/dev/null | grep -q "Status: active"; then
    for opening in $OPENINGS; do
        ufw delete allow "$opening" >/dev/null 2>&1 || true
    done
fi

echo "==> removing files"
rm -f /etc/systemd/system/digitsell-ovpn-agent.service \
      /etc/systemd/system/digitsell-ovpn-nat-refresh.service \
      /etc/systemd/system/digitsell-ovpn-nat-refresh.timer \
      /run/digitsell-ovpn-nat.excluded \
      /run/digitsell-ovpn-nat.excluded.udp \
      /run/digitsell-ovpn-nat.excluded.tcp \
      /etc/systemd/system/digitsell-ovpn-nat.service \
      /usr/local/sbin/digitsell-ovpn-nat \
      /etc/sysctl.d/99-digitsell-ovpn.conf \
      "$SERVER_DIR/digitsell.conf" \
      "$SERVER_DIR/digitsell-tcp.conf" \
      "$SERVER_DIR/mgmt.pw"
rm -rf /usr/local/lib/digitsell-ovpn /etc/digitsell-ovpn
systemctl daemon-reload >/dev/null 2>&1 || true

if [ "$KEEP_CA" -eq 1 ]; then
    echo "    kept the CA in $SERVER_DIR/easy-rsa"
else
    rm -rf "$SERVER_DIR/easy-rsa" "$SERVER_DIR/tc.key"
fi

if [ "$PURGE" -eq 1 ]; then
    echo "==> removing packages"
    DEBIAN_FRONTEND=noninteractive apt-get purge -y -qq openvpn easy-rsa >/dev/null
    DEBIAN_FRONTEND=noninteractive apt-get autoremove -y -qq >/dev/null || true
fi

echo
echo "Done. The OpenVPN node is removed from this server."
echo "IP forwarding was left as it is now (it is needed by Docker and similar);"
echo "to switch it off: sysctl -w net.ipv4.ip_forward=0"
echo "Delete the server in the panel too: Settings -> OpenVPN servers -> Delete."
