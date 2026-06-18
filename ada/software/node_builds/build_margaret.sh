#!/bin/bash


### Prescript Hook
sudo apt update -y
sudo apt full-upgrade -y
sudo apt autoremove -y
sudo apt autoclean

### The Snap Purge
echo "Purging Snap"
sudo systemctl disable --now snapd.socket snapd.service
sudo apt purge autoremove snapd
sudo apt-mark hold snapd


### Nuke Radios
echo "Nuking Bluetooth and Wi-Fi Radios"
sudo systemctl disable --now bluetooth.service
sudo systemctl disable --now wpa_supplicant.service
sudo apt-mark unhold bluez wpasupplicant wireless-tools # Just in case
sudo apt purge bluez wpasupplicant wireless-tools -y
sudo apt autoremove --purge -y


### Nuke ModemManager
echo "Nuking ModemManager"
sudo systemctl disable --now ModemManager.service
sudo apt purge modemmanager -y


### Nuke Cloud Bloat
echo "Nuking Cloud Bloat"
sudo touch /etc/cloud/cloud-init.disabled
sudo apt purge cloud-init -y
sudo rm -rf /etc/cloud/ /var/lib/cloud/


### Nuke Storage Spammer
echo "Nuking Storage Spammer"
sudo systemctl disable --now multipathd.service multipathd.socket
sudo apt purge multipath-tools -y


### Quick Cleaning
sudo apt autoremove --purge -y


### Disable Unattended Upgrades Service
# We don't purge this one, we just disable the automatic timer
# so you can still update manually via `sudo apt upgrade`
sudo systemctl disable --now unattended-upgrades.service
sudo systemctl disable --now apt-daily.timer
sudo systemctl disable --now apt-daily-upgrade.timer


### Git Install and Repo Setup
echo "Installing Git"
sudo apt install git -y
git clone https://github.com/dvandagriff/adalovespace.git


### UV (Python) Install
echo "Installing UV"
curl -LsSf https://astral.sh/uv/install.sh | sudo env UV_INSTALL_DIR="/usr/local/bin" sh


### Jake's NFS Config
echo "Setting up Jake's NFS"
sudo mkdir -p /mnt/jake/share
sudo mkdir -p /mnt/jake/wheelhouse
sudo systemctl daemon-reload
sudo mount -a


### Install MQTT and Setup Related Daemons
echo "Installing MQTT"
sudo apt install mosquitto -y


### The GUI Layer (XFCE)
echo "Installing XFCE and a lightdm"
sudo apt update && sudo apt full-upgrade -y
sudo apt install xfce4 xfce4-goodies lightdm -y
