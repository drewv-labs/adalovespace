#!/usr/bin/env bash
# Ada Lovespace — MarGo KStars Control Utility
# Manages KStars lifecycle on Margaret (VNC + Ekos)
# Available as "ada-kstars" after ada-strapper (root)
# NODE=margaret  → only linked when running on this hostname
#
# Usage:
#   ada-kstars                  # Start/restart KStars session
#   ada-kstars --status         # Show full MarGo service status
#   ada-kstars --stop           # Stop KStars session
#   ada-kstars --reboot-display # Restart just Xvfb (drops current KStars)

set -euo pipefail

SESSION_NAME="adalovespace-kstars"
DISPLAY_NUM=":99"
VNC_PORT="${MARGO_VNC_PORT:-5900}"
WEBSOCKIFY_PORT="${MARGO_WEBSOCKIFY_PORT:-6080}"

# Resolve the repo root via self-boot (if sourced) or fallback to git walk
_resolve_repo_root() {
    if [[ -n "${ADA_ROOT:-}" ]]; then
        echo "$ADA_ROOT"
        return 0
    fi

    local _candidate="$(cd "$(dirname "$BASH_SOURCE[0]")" && pwd)"
    while [[ "$_candidate" != "/" ]]; do
        if [[ -f "$_candidate/cluster.env" ]]; then
            echo "$_candidate"
            return 0
        fi
        _candidate="$(dirname "$_candidate")"
    done

    # Fallback to /opt/adalovespace if everything else fails
    if [[ -f "/opt/adalovespace/cluster.env" ]]; then
        echo "/opt/adalovespace"
        return 0
    fi

    ada oof "FATAL: [ada-kstars] Could not resolve repo root. Ensure this is on Margaret."
    exit 1
}

_ADA_ROOT="$(_resolve_repo_root)"

# Source logging (if available)
if [[ -f "$_ADA_ROOT/cluster/lib/ada-log.sh" ]]; then
    source "$_ADA_ROOT/cluster/lib/ada-log.sh" >/dev/null 2>&1 || true
fi

_start_vfb() {
    if ! systemctl is-active --quiet adalovespace-margo-vfb.service 2>/dev/null; then
        ada-log main "[kstars] Starting Xvfb display :99..."
        sudo systemctl start adalovespace-margo-vfb.service
        sleep 2
    fi
}

_start_kstars_session() {
    if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        ada-log warn "[kstars] Session '$SESSION_NAME' already running"
        echo "   Reconnect: tmux attach -t $SESSION_NAME"
        return 0
    fi

    # Ensure VFB is up first
    _start_vfb

    ada-log main "[kstars] Starting KStars on display $DISPLAY_NUM..."

    # Launch KStars in a new detached tmux session
    DISPLAY="$DISPLAY_NUM" kstars --nosplash &

    sleep 3

    if pgrep -x kstars &>/dev/null; then
        ada-log yay "[kstars] Started on display $DISPLAY_NUM\n"
        ada-log yay " <3 Browser view: http://<margaret-ip>:$WEBSOCKIFY_PORT/vnc.html?autoconnect=true\n"
    else
        ada-log oof "[kstars] Failed to start — check Xvfb is running"
        return 1
    fi
}

_stop_kstars_session() {
    if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        ada-log main "[kstars] Stopping KStars session..."
        tmux kill-session -t "$SESSION_NAME"
    fi

    # Also kill any lingering kstars processes on display :99
    pkill -f "DISPLAY=$DISPLAY_NUM.*kstars" 2>/dev/null || true

    ada-log yay "[kstars] Stopped"
}

_status_check() {
    echo ""
    echo "  ┌─────────────────────────────────────────────────────────────────┐"
    echo "  │  🌟 Ada Lovespace MarGo — Status Report                       │"
    echo "  ├─────────────────────────────────────────────────────────────────┤"
    echo "  │                                                                 │"

    # Xvfb
    if systemctl is-active --quiet adalovespace-margo-vfb.service 2>/dev/null; then
        echo "  │  ✓ Xvfb display :99      : RUNNING                            │"
    else
        echo "  │  ✗ Xvfb display :99      : NOT running (sudo systemctl start  │"
        echo "  │                             adalovespace-margo-vfb)            │"
    fi

    # x11vnc
    if systemctl is-active --quiet adalovespace-margo-vnc.service 2>/dev/null; then
        echo "  │  ✓ x11vnc server         : RUNNING                            │"
    else
        echo "  │  ✗ x11vnc server         : NOT running (sudo systemctl start  │"
        echo "  │                             adalovespace-margo-vnc)            │"
    fi

    # websockify
    if systemctl is-active --quiet adalovespace-margo-novnc.service 2>/dev/null; then
        echo "  │  ✓ noVNC web viewer      : RUNNING (port $WEBSOCKIFY_PORT)    │"
    else
        echo "  │  ✗ noVNC web viewer      : NOT running (sudo systemctl start  │"
        echo "  │                             adalovespace-margo-novnc)          │"
    fi

    echo "  │                                                                 │"

    # KStars tmux session
    if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        echo "  │  ✓ KStars tmux session   : RUNNING (tmux: $SESSION_NAME)     │"
    else
        echo "  │  ✗ KStars tmux session   : NOT started                         │"
        echo "  │                             ada-kstars --start                 │"
    fi

    # KStars process check
    if DISPLAY=:99 pgrep -x kstars &>/dev/null; then
        echo "  │  ✓ KStars process        : RUNNING on display $DISPLAY_NUM     │"
    else
        echo "  │  ✗ KStars process        : NOT running                         │"
    fi

    # INDI server
    if pgrep -x indid &>/dev/null; then
        echo "  │  ✓ INDI server           : RUNNING                            │"
    else
        echo "  │  ✗ INDI server           : NOT running (start in Ekos)         │"
    fi

    # Telescope hardware detection
    echo "  │                                                                 │"
    echo "  └─────────────────────────────────────────────────────────────────┘"
    echo ""

    ada-log main "[kstars] Hardware Detection:"
    lsusb | grep -i "03c3\|zwo\|asi" &>/dev/null && \
        ada-log yay "  ✓ ZWO ASI camera detected (ASI2600MC Duo likely)" || \
        ada-log error "  ✗ No ZWO camera found — check USB connection"

    lsusb | grep -i "ioptron\|eqmod\|gemini" &>/dev/null && \
        ada-log yay "  ✓ Mount detected (EQMOD/Gemini protocol)" || \
        ada-log error "  ✗ No mount found — check USB/serial connection"

    echo ""
    ada-log main "[kstars] Browser access:"
    echo "  http://$(hostname -I | awk '{print $1}'):${WEBSOCKIFY_PORT}/vnc.html?autoconnect=true"
    echo ""
}

_reboot_display() {
    ada-log main "[kstars] Rebooting virtual display :99 (this will drop KStars)..."

    # Stop KStars first
    if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        tmux kill-session -t "$SESSION_NAME" 2>/dev/null || true
    fi
    pkill -f "DISPLAY=$DISPLAY_NUM.*kstars" 2>/dev/null || true

    # Restart Xvfb
    sudo systemctl restart adalovespace-margo-vfb.service
    sleep 2

    ada-log yay "[kstars] Display :99 rebooted. KStars needs to be restarted: ada-kstars --start"
}

# ==============================================================================
# Main dispatch
# ==============================================================================

case "${1:-}" in
    --start|start|"")
        # Default action: start
        _start_kstars_session
        ;;
    --stop)
        _stop_kstars_session
        ;;
    --status)
        _status_check
        ;;
    --reboot-display|--reset-display)
        _reboot_display
        ;;
    *)
        echo "Usage: ada-kstars [--start|--stop|--status|--reboot-display]"
        echo ""
        echo "  Commands:"
        echo "    (none) or --start   Start KStars in VNC session"
        echo "    --stop              Stop KStars session"
        echo "    --status            Show full MarGo status report"
        echo "    --reboot-display    Restart Xvfb display :99 (drops current session)"
        exit 1
        ;;
esac
