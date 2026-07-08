#!/bin/bash
set -euxo pipefail
source sudo-check
source ada-env ${BASH_SOURCE[0]}

echo "=== Configuring JakeBase Mosquitto Broker"
echo -e "listener ${MQTT_BROKER_PORT}\nallow_anonymous true" | sudo tee /etc/mosquitto/conf.d/astrolab.conf
sudo systemctl restart mosquitto
echo ""
