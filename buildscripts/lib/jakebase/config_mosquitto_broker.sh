#!/bin/bash

echo "=== Configuring Jake's Mosquitto Broker"
echo -e "listener 1883\nallow_anonymous true" | sudo tee /etc/mosquitto/conf.d/astrolab.conf
sudo systemctl restart mosquitto
echo ""
