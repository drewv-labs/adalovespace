#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "${BASH_SOURCE[0]}"

echo "${ADA_BLU1}=== Installing Mosquitto Clients"

sudo apt install mosquitto-clients -y
echo ""
