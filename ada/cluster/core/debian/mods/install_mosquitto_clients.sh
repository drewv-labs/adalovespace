#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "$BASH_SOURCE"

ada-log mod "=== Installing Mosquitto Clients"

sudo apt install mosquitto-clients -y
