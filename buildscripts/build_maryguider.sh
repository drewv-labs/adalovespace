#!/bin/bash

sudo apt update -y
sudo apt install dphys-swapfile -y
sudo apt install git -y
sudo apt install build-essential -y
sudo apt install cmake -y
sudo apt install pkg-config -y
sudo apt install libwxgtk3.2-dev -y
sudo apt install wx-common -y
sudo apt install wx3.2-i18n -y
sudo apt install gettext -y
sudo apt install zlib1g-dev -y
sudo apt install libx11-dev -y
sudo apt install libcurl4-gnutls-dev -y
sudo apt install libeigen3-dev -y
sudo apt install libcfitsio-dev -y
sudo apt install libnova-dev -y
sudo apt install libopencv-dev -y
sudo apt install x11vnc -y
sudo apt install fluxbox -y

# // Make 2gb swap space
/etc/dphys-swapfile CONF_SWAPSIZE=2048
sudo systemctl restart dphys-swapfile

# // Compile PHD2 service
cd ~
git clone --depth 1 https://github.com/OpenPHDGuiding/phd2.git
cd phd2
mkdir tmp
cd tmp
cmake -DOPENSOURCE_ONLY=1 ..
make -j1
sudo make install

# // Swap space back to 100mb oh shit mem
/etc/dphys-swapfile CONF_SWAPSIZE=100
sudo systemctl restart dphys-swapfile
