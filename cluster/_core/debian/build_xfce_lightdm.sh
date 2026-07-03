#!/bin/bash
set -euxo pipefail

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" >&2
    exit 1
fi
#
echo "=== Installing GUI (XFCE + LightDM; NoPasswdLogin)"

sudo apt install xorg xserver-xorg dbus-x11 -y
sudo apt install xfce4 xfce4-goodies lightdm -y
sudo apt purge xfce4-power-manager -y

sudo groupadd -r nopasswdlogin
sudo gpasswd -a $(whoami) nopasswdlogin

sudo tee -a /etc/lightdm/lightdm.conf | cat << EOF
[Seat:*]
    autologin-user=$(whoami)
    autologin-user-timeout=0
    user-session=xfce
EOF

sudo systemctl restart lightdm
echo ""
