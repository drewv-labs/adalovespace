#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Margaret Node — Build Orchestrator
# ==============================================================================
# Usage: build.sh [margo|marpro]
#   margo    — Lightweight KStars/Ekos via VNC (xvfb + websockify + noVNC)
#   marpro   — Full Ubuntu Server + XFCE + LightDM + NoMachine + KStars
#   <none>   — Installs both MarGo + MarPro stacks
# ==============================================================================

source ada-preflight "$BASH_SOURCE"

# // Tracer — toggle with ADA_TRACE=1
source "$ADA_CLUSTER/lib/ada-tracer.sh" "${ADA_TRACE:-0}"

ada-logger main "=== Building Margaret Node ==="

debcore="$ADA_CLUSTER/core/debian"
margaret="$ADA_CLUSTER/nodes/margaret"

# // Build out the common Margaret kit
"$margaret/kstars/build.sh"

margo() {
    ada-logger main "=== Building MarGo Stack (VNC)"
    "$ADA_CLUSTER/nodes/margaret/margo/build.sh"
}

marpro() {
    ada-logger main "=== Building MarPro Stack (XFCE)"
    "$margaret/marpro/build.sh"
}

# // Dynamic GUI Stack Building
case "${1:-}" in
    marpro)
        marpro
        ;;
    margo)
        margo
        ;;
    *)
        marpro
        margo
        ;;
esac

ada-logger yay "=== Margaret Node Build Complete"
