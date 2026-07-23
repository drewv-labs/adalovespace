#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "$BASH_SOURCE"

ada-log mod "=== Installing Mosquitto for Broker"

sudo apt install mosquitto -y

# Enable and start the broker service
sudo systemctl enable --now mosquitto
