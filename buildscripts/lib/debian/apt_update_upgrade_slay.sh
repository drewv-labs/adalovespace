#!/bin/bash
#
echo "=== Updating, Upgrading, & Purging Packages"

sudo apt update -y
sudo apt full-upgrade -y
sudo apt autoremove --purge -y
sudo apt autoclean -y
echo ""
