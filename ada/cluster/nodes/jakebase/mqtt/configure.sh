#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "$BASH_SOURCE[0]"

ada-log "mod" "=== Configuring JakeBase Mosquitto Broker"

echo -e "listener ${MQTT_BROKER_PORT}\nallow_anonymous true" | sudo tee /etc/mosquitto/conf.d/astrolab.conf
sudo systemctl restart mosquitto

echo ""
