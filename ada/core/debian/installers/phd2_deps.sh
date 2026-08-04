#!/usr/bin/env bash
set -euo pipefail
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
sudo apt install -y "${deps[@]}"
