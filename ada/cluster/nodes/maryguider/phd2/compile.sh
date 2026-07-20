#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "$BASH_SOURCE[0]"

ada-log "mod" "=== Compiling PHD2 Guiding Engine"

ada-log "debug" "---> Making 2gb swap space"
sudo sed -i 's/^CONF_SWAPSIZE=.*/CONF_SWAPSIZE=2048/' /etc/dphys-swapfile
sudo systemctl restart dphys-swapfile

ada-log "debug" "---> Cloning PHD2 repository"
cd ~
git clone --depth 1 https://github.com/OpenPHDGuiding/phd2.git
cd phd2
mkdir tmp
cd tmp

ada-log "debug" "---> Start compilation"
cmake -DOPENSOURCE_ONLY=1 ..
make -j1
sudo make install
ada-log "yay" "---> Compilation complete"

ada-log "debug" "---> Swap space back to 100mb"
sudo sed -i 's/^CONF_SWAPSIZE=.*/CONF_SWAPSIZE=100/' /etc/dphys-swapfile

ada-log "yay" "=== PHD2 Guiding Engine Compiled Successfully"

sudo systemctl restart dphys-swapfile
