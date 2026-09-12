#!/usr/bin/env bash
set -euo pipefail
source ada-preflight "$BASH_SOURCE"

# // Tracer — toggle with ADA_TRACE=1
source "$ADA_CLUSTER/lib/ada-tracer.sh" "${ADA_TRACE:-0}"

ada-logger mod "=== Compiling PHD2 Guiding Engine"

ada-logger debug "--> Making 2gb swap space"
sudo sed -i 's/^CONF_SWAPSIZE=.*/CONF_SWAPSIZE=2048/' /etc/dphys-swapfile
sudo systemctl restart dphys-swapfile

ada-logger debug "--> Cloning PHD2 repository"
cd ~
git clone --depth 1 https://github.com/OpenPHDGuiding/phd2.git
cd phd2
mkdir tmp
cd tmp

ada-logger debug "--> Start compilation"
cmake -DOPENSOURCE_ONLY=1 ..
make -j1
sudo make install
ada-logger yay "--> Compilation complete"

ada-logger debug "--> Swap space back to 100mb"
sudo sed -i 's/^CONF_SWAPSIZE=.*/CONF_SWAPSIZE=100/' /etc/dphys-swapfile

sudo systemctl restart dphys-swapfile
