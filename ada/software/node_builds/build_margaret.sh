#!/bin/bash

### The Snap Purge
echo "=== Purging Snap"
sudo systemctl disable --now snapd.socket snapd.service
sudo apt purge autoremove snapd
sudo apt-mark hold snapd
echo ""

### Nuke Radios
echo "=== Nuking Bluetooth and Wi-Fi Radios"
sudo systemctl disable --now bluetooth.service
sudo systemctl disable --now wpa_supplicant.service
sudo apt-mark unhold bluez wpasupplicant wireless-tools # Just in case
sudo apt purge bluez wpasupplicant wireless-tools -y
echo ""

### Nuke ModemManager
echo "=== Nuking ModemManager"
sudo systemctl disable --now ModemManager.service
sudo apt purge modemmanager -y
echo ""

### Nuke Cloud Bloat
echo "=== Nuking Cloud Bloat"
sudo touch /etc/cloud/cloud-init.disabled
sudo apt purge cloud-init -y
sudo rm -rf /etc/cloud/ /var/lib/cloud/
echo ""

### Nuke Storage Spammer
echo "=== Nuking Storage Spammer"
sudo systemctl disable --now multipathd.service multipathd.socket
sudo apt purge multipath-tools -y
echo ""

### Disable Unattended Upgrades Service
# We don't purge this one, we just disable the automatic timer
# so you can still update manually via `sudo apt upgrade`
echo "=== Disabling Unattended Upgrades Service"
sudo systemctl disable --now unattended-upgrades.service
sudo systemctl disable --now apt-daily.timer
sudo systemctl disable --now apt-daily-upgrade.timer
echo ""

### Update, Upgrade, and Clean Up
echo "=== Updating, Upgrading, and Cleaning Up Surviving Packages"
sudo apt update -y
sudo apt full-upgrade -y
sudo apt autoremove --purge -y
sudo apt autoclean
echo ""

### Jake's NFS Config
# TODO: jakedev box with NFS
echo "=== Setting up Jake's NFS"
sudo mkdir -p /mnt/jake/share
sudo mkdir -p /mnt/jake/wheelhouse
sudo apt install nfs-common -y
echo "{$JAKE_IP}:/mnt/adaspace_share /mnt/jake/share nfs defaults,bg,noatime,nolock 0 0" | sudo tee -a /etc/fstab
echo "{$JAKE_IP}:/opt/ada/wheelhouse /mnt/jake/wheelhouse nfs defaults,bg,noatime,nolock 0 0" | sudo tee -a /etc/fstab
sudo systemctl daemon-reload
sudo mount -a
echo ""

### UV (Python) Install
echo "=== Installing UV"
curl -LsSf https://astral.sh/uv/install.sh | sudo env UV_INSTALL_DIR="/usr/local/bin" sh
echo ""

### Install MQTT and Setup Related Daemons
# echo "=== Installing MQTT"
# sudo apt install mosquitto -y
# echo ""

### The GUI Layer (XFCE)
echo "=== Installing XFCE and a lightdm"
sudo apt install xfce4 xfce4-goodies lightdm -y
echo ""

### NoMachine
# TODO: dpkg-deb: error: 'nomachine_8.11.3_4_amd64.deb' is not a Debian format archive
# echo "=== Installing NoMachine"
# wget https://download.nomachine.com/download/8.11/Linux/nomachine_8.11.3_4_amd64.deb
# sudo dpkg -i nomachine_8.11.3_4_amd64.deb
# echo ""

### Kstars and Ekos
echo "=== Installing Kstars and Ekos"
sudo apt-add-repository ppa:mutlaqja/ppa
sudo apt install indi-full kstars-bleeding -y
echo ""

### Fin
echo "=== Fin!"
sudo reboot

# TODO: Login splashscreen rendered successfully
# but there was an issue with session start
