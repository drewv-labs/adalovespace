#!/bin/bash
#
echo "=== Updating, Upgrading, & Cleaning Up APT Packages"
sudo apt update -y
sudo apt full-upgrade -y
sudo apt autoremove --purge -y
sudo apt autoclean -y
echo ""
