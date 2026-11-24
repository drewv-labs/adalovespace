#!/usr/bin/env bash
# ==============================================================================
# DREW-V Labs // MaryGuider-RPZ2 Decommissioning & usb0 Cutover Hygiene
# Path: adalovespace/src/adastak/adascope/nodes/adactrl/decommission-maryguider.sh
#
# Description:
#   Idempotently removes retired MaryGuider-RPZ2 USB-gadget (`usb0` / `Mary-Bridge`
#   / `maryguider-link`) network configs and legacy `maryguider-phd2.service` so
#   neither `NetworkManager-wait-online` nor `systemd-networkd-wait-online` can
#   stall boot waiting on an unpopulated USB gadget tether.
# ==============================================================================
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ADA_ENGINE_ROOT="${ADA_ENGINE_ROOT:-$(cd "${SCRIPT_DIR}/../../../../.." && pwd)}"
# shellcheck source=../../../../../lib/common.sh
source "${ADA_ENGINE_ROOT}/lib/common.sh"

REMOVED_ANY="false"

# 1. Clean NetworkManager usb0 / MaryGuider profiles
if command -v nmcli >/dev/null 2>&1 && systemctl is-active --quiet NetworkManager.service 2>/dev/null; then
    while IFS=: read -r cname cuuid cdev; do
        [[ -n "$cuuid" ]] || continue
        if [[ "$cname" == "Mary-Bridge" || "$cname" == "maryguider-link" || "$cname" == "usb-link" || "$cdev" == "usb0" ]]; then
            nmcli connection delete uuid "$cuuid" >/dev/null 2>&1 || true
            log_ok "Removed NetworkManager tether profile '${cname}' (${cuuid})"
            REMOVED_ANY="true"
        fi
    done < <(nmcli -t -f NAME,UUID,DEVICE connection show 2>/dev/null || true)
fi

if [[ -d /etc/NetworkManager/system-connections ]]; then
    for nm_file in /etc/NetworkManager/system-connections/*.nmconnection; do
        [[ -f "$nm_file" ]] || continue
        if grep -Eq '^(id=(Mary-Bridge|maryguider-link|usb-link)|interface-name=usb0)$' "$nm_file" 2>/dev/null; then
            rm -f "$nm_file"
            if command -v nmcli >/dev/null 2>&1; then
                nmcli connection reload >/dev/null 2>&1 || true
            fi
            log_ok "Removed residual NM connection file ${nm_file}"
            REMOVED_ANY="true"
        fi
    done
fi

# 2. Clean ifupdown & systemd-networkd usb0 tether artifacts
if [[ -f /etc/network/interfaces.d/usb0 ]]; then
    rm -f /etc/network/interfaces.d/usb0
    log_ok "Removed /etc/network/interfaces.d/usb0"
    REMOVED_ANY="true"
fi

for net_f in /etc/systemd/network/*usb0* /etc/systemd/network/*maryguider*; do
    [[ -e "$net_f" && ! -L "$net_f" ]] || continue
    rm -f "$net_f"
    log_ok "Removed systemd-networkd tether unit ${net_f}"
    REMOVED_ANY="true"
done

# 3. Guard systemd-networkd-wait-online against usb0 if enabled on node
if systemctl is-enabled --quiet systemd-networkd-wait-online.service 2>/dev/null; then
    if ada_write_if_changed "/etc/systemd/system/systemd-networkd-wait-online.service.d/10-ada-ignore-usb0.conf" 0644 <<'EOF'
# Managed by AdaLovespace — Never block boot on retired usb0 tether
[Service]
ExecStart=
ExecStart=/lib/systemd/systemd-networkd-wait-online --ignore=usb0
EOF
    then
        systemctl daemon-reload
        log_ok "Configured systemd-networkd-wait-online to ignore usb0"
        REMOVED_ANY="true"
    fi
fi

# 4. Retire legacy maryguider-phd2.service if present
if [[ -f /etc/systemd/system/maryguider-phd2.service ]]; then
    systemctl disable --now maryguider-phd2.service 2>/dev/null || true
    rm -f /etc/systemd/system/maryguider-phd2.service
    systemctl daemon-reload
    log_ok "Retired legacy maryguider-phd2.service"
    REMOVED_ANY="true"
fi

if [[ "$REMOVED_ANY" == "false" ]]; then
    log_skip "MaryGuider-RPZ2 usb0 tether & legacy units already absent"
fi
