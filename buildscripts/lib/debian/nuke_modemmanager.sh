#!/bin/bash
#
echo "=== Nuking ModemManager"

sudo systemctl disable --now ModemManager.service
sudo apt purge modemmanager -y
echo ""
