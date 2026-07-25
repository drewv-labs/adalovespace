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
"$debcore/mods/install_indi.sh"
"$margaret/kstars/build.sh"

# // Dynamic GUI Stack Building
case "${1:-}" in
    marpro)
        "$margaret/marpro/build.sh"
        ;;
    margo)
        "$margaret/margo/build.sh"
        "$margaret/margo/configure.sh"
        ;;
    *)
        "$margaret/marpro/build.sh"
        "$margaret/margo/build.sh"
        "$margaret/margo/configure.sh"
        ;;
esac

ada-logger yay "=== Margaret Node Build Complete"
