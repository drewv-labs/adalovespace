#!/bin/bash
set -euxo pipefail
source ada-preflight "${BASH_SOURCE[0]}"

echo "${ADA_BLU1}=== Installing GUI (XFCE + LightDM; NoPasswdLogin)"

sudo apt install xorg xserver-xorg dbus-x11 -y
sudo apt install xfce4 xfce4-goodies lightdm -y
sudo apt purge xfce4-power-manager -y

sudo systemctl restart lightdm
echo ""
