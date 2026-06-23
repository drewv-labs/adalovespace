#!/bin/bash

echo "=== Nuking Cloud Bloat"

sudo touch /etc/cloud/cloud-init.disabled
sudo apt purge cloud-init -y
sudo rm -rf /etc/cloud/ /var/lib/cloud/
echo ""
