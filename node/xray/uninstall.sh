#!/usr/bin/env bash
#
# Digitsell Xray node - removes what install.sh put on this server.
#
#   sudo bash uninstall.sh [--keep-config] [--restore-xmplus]
#
#   --keep-config     keep /etc/digitsell-xray (agent.json and the certificates),
#                     so a later install.sh picks them up again
#   --restore-xmplus  start and enable XMPlus again, if it is still on disk
#
# Usage already reported stays in the panel; what was counted in the last
# minute is sent first (the agent reports on stop).

set -euo pipefail

KEEP=0
RESTORE=0
while [ $# -gt 0 ]; do
    case "$1" in
        --keep-config)    KEEP=1; shift ;;
        --restore-xmplus) RESTORE=1; shift ;;
        -h|--help)        sed -n '2,13p' "$0"; exit 0 ;;
        *) echo "unknown option: $1" >&2; exit 1 ;;
    esac
done

[ "$(id -u)" -eq 0 ] || { echo "error: run as root" >&2; exit 1; }

echo "==> stopping services"
systemctl disable --now digitsell-xray-agent >/dev/null 2>&1 || true
systemctl disable --now digitsell-xray >/dev/null 2>&1 || true

echo "==> removing files"
rm -f /etc/systemd/system/digitsell-xray.service /etc/systemd/system/digitsell-xray-agent.service \
      /usr/local/bin/digitsell-xray /usr/local/bin/dxray \
      /etc/sysctl.d/99-digitsell-xray.conf /etc/sysctl.d/98-digitsell-bbr.conf
rm -rf /usr/local/lib/digitsell-xray /var/lib/digitsell-xray
if [ "$KEEP" -eq 0 ]; then
    rm -rf /etc/digitsell-xray
else
    echo "    kept /etc/digitsell-xray"
fi
systemctl daemon-reload

if [ "$RESTORE" -eq 1 ]; then
    for unit in XMPlus xmplus; do
        if systemctl list-unit-files "$unit.service" 2>/dev/null | grep -q "^$unit.service"; then
            echo "==> starting $unit again"
            systemctl enable --now "$unit" || true
        fi
    done
fi
echo "done"
