#!/bin/bash
set -euxo pipefail
source ada-preflight "${BASH_SOURCE[0]}"

echo "=== Installing Mosquitto Clients"

sudo apt install mosquitto-clients -y
echo ""
