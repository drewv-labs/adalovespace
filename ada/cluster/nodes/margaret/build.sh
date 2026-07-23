#!/usr/bin/env bash
# ==============================================================================
# Margaret Node — Build Orchestrator
# ==============================================================================
# Usage: build.sh [margo|marpro]
#   margo    — Lightweight KStars/Ekos via VNC (xvfb + websockify + noVNC)
#   marpro   — Full Ubuntu Server + XFCE + LightDM + NoMachine + KStars
#   <none>   — Installs both margo + marpro stacks
# ==============================================================================

set -euxo pipefail
source ada-preflight "$BASH_SOURCE"

ada-log main "=== Building Margaret Node ==="

margaret="$ADA_CLUSTER/nodes/margaret"

_build_margo() {
    ada-log main "--> Installing Margo stack (VNC/KStars/Ekos)"
    "$margaret/margo/build.sh"
    "$margaret/margo/configure.sh"
}

_build_marpro() {
    ada-log main "--> Installing MarPro stack (XFCE/NoMachine/KStars)"
    "$margaret/marpro/build.sh"
}

case "${1:-}" in
    margo)
        _build_margo
        ;;
    marpro)
        _build_marpro
        ;;
    *)
        # Default: install both stacks
        _build_margo
        _build_marpro
        ;;
esac

ada-log yay "=== Margaret Node Build Complete"
