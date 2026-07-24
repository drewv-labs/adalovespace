#!/usr/bin/env bash
set -euo pipefail
source ada-preflight "$BASH_SOURCE"

ada-log mod "=== Installing VNC"

sudo apt install -y \
    xvfb \
    tigervnc-standalone-server \
    websockify \
    novnc \
    x11vnc
