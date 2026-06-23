#!/bin/bash

echo "=== Purging Snap"

sudo systemctl disable --now snapd.socket snapd.service

sudo apt purge autoremove snapd
sudo apt-mark hold snapd
echo ""
