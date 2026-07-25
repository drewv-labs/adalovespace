#!/usr/bin/env bash
set -euo pipefail
source ada-preflight "$BASH_SOURCE"

# // Tracer — toggle with ADA_TRACE=1
source "$ADA_CLUSTER/lib/ada-tracer.sh" "${ADA_TRACE:-0}"

ada-logger mod "=== Installing VNC"

sudo apt install -y \
    xvfb \
    tigervnc-standalone-server \
    websockify \
    novnc \
    x11vnc
