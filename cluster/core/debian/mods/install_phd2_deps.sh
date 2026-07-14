#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "${BASH_SOURCE[0]}"

ada-log "mod" "=== Installing PHD2 Dependencies"

deps=(
    dphys-swapfile
    git
    build-essential
    cmake
    pkg-config
    libwxgtk3.2-dev
    wx-common
    wx3.2-i18n
    gettext
    zlib1g-dev
    libx11-dev
    libcurl4-gnutls-dev
    libeigen3-dev
    libcfitsio-dev
    libnova-dev
    libopencv-dev
    x11vnc
    fluxbox
)

sudo apt update -y
for dep in "${deps[@]}"; do
    sudo apt install "$dep" -y
done

echo ""
