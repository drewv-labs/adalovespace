#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "$BASH_SOURCE[0]"

ada-log "mod" "=== Installing MarGo Stack ==="

# Core VNC streaming packages
sudo apt install -y xvfb tigervnc-standalone-server websockify novnc

# INDI full package (base telescope/camera drivers)
if ! dpkg -l | grep -q "indi-full"; then
    sudo apt install -y indi-full
fi

# ZWO ASI camera driver (ASI2600MC Duo, EFW, EAF all use this)
if ! dpkg -l | grep -q "indi-zwo"; then
    sudo apt install -y indi-zwo
fi

# iOptron Gemini/AM5 mount driver (EQMOD protocol compatible)
if ! dpkg -l | grep -q "indi-gemini"; then
    sudo apt install -y indi-gemini
fi

# RB-Focus Excalibur (if package exists in your repo, otherwise skip)
# ada-log "eh" "RB-Focus driver: check for indi-rb-focus or use INDI network server with Ekos native support"

echo ""
ada-log "yay" "=== MarGo stack installed: Xvfb + VNC + noVNC + ZWO/Gemini drivers"
