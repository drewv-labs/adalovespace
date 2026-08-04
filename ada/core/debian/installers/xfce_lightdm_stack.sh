#!/usr/bin/env bash
set -euo pipefail
sudo apt install xorg xserver-xorg dbus-x11 -y
sudo apt install xfce4 xfce4-goodies lightdm -y
sudo apt purge xfce4-power-manager -y
sudo systemctl restart lightdm
