#!/bin/bash
set -euxo pipefail

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" >&2
    exit 1
fi

source /opt/adalovespace/cluster.env

echo "=== Configuring JakeBase Mosquitto Broker"
echo -e "listener ${MQTT_BROKER_PORT}\nallow_anonymous true" | sudo tee /etc/mosquitto/conf.d/astrolab.conf
sudo systemctl restart mosquitto
echo ""
