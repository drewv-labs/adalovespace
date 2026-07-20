#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "$BASH_SOURCE"

ada-log mod "=== Purging Bluetooth Radios"

sudo systemctl disable --now bluetooth.service
sudo apt-mark unhold bluez
sudo apt purge bluez
