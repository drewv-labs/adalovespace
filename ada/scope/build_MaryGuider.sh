set -euxo pipefail

# ==============================================================================
# Configuration (loaded via preflight → TOML or legacy .env)
# ==============================================================================
source ./ada/lib/ada-preflight.sh "${BASH_SOURCE[0]}"

## // tune_sudoers
# 1. Write the rule atomically into the drop-in directory
sudoers_file="/etc/sudoers.d/010_${ADAUSR_ADM}_nopasswd"
echo "$ADAUSR_ADM ALL=(ALL) NOPASSWD: ALL" | sudo tee "$sudoers_file" > /dev/null

# 2. Enforce strict permissions (Must be 0440 or sudo will reject it)
sudo chmod 0440 "$sudoers_file"

# 3. Validate the syntax safely before completing the build
if ! sudo visudo -cf "$sudoers_file"; then
    echo "Malformed sudoers syntax detected! Removing file to prevent system lockout."
    sudo rm -f "$sudoers_file"
    exit 1
fi

## // sys_tuner
set +e
sudo systemctl disable --now apt-daily-upgrade.timer
sudo systemctl disable --now apt-daily.timer
sudo systemctl disable --now bluetooth.service
sudo systemctl disable --now ModemManager.service
sudo systemctl disable --now multipathd.service multipathd.socket
sudo systemctl disable --now unattended-upgrades.service
sudo systemctl disable --now wpa_supplicant.service

sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target

sudo apt-mark unhold bluez
sudo apt-mark unhold wpasupplicant

sudo apt purge bluez -y
sudo apt purge modemmanager -y
sudo apt purge multipath-tools -y
sudo apt purge wpasupplicant -y

sudo apt update -y && sudo apt autoremove -y && sudo apt autoclean -y
set -e

sudo apt install stress-ng -y

deps=(
    dphys-swapfile
    git
    build-essential
    cmake
    pkg-config
    libwxgtk3.2-dev
    wx-common
    wx3.2-i18n
    gettext
    zlib1g-dev
    libx11-dev
    libcurl4-gnutls-dev
    libeigen3-dev
    libcfitsio-dev
    libnova-dev
    libopencv-dev
    xvfb
    x11vnc
    fluxbox
)
sudo apt install -y "${deps[@]}"

# Allocate extra swap for PHD2 compile (Pi Zero 2W has only 1GB RAM)
sudo sed -i 's/^CONF_SWAPSIZE=.*/CONF_SWAPSIZE=2048/' /etc/dphys-swapfile
sudo systemctl restart dphys-swapfile

cd $HOME
git clone --depth 1 https://github.com/OpenPHDGuiding/phd2.git
cd phd2
mkdir tmp
cd tmp

cmake -DOPENSOURCE_ONLY=1 ..
make -j1
sudo make install

# Restore swap to 100MB
sudo sed -i 's/^CONF_SWAPSIZE=.*/CONF_SWAPSIZE=100/' /etc/dphys-swapfile
sudo systemctl restart dphys-swapfile

sudo tee /etc/systemd/system/maryguider-phd2.service <<EOF
[Unit]
Description=MaryGuider PHD2 Headless Guiding Server for Ada Lovespace Project
After=network.target

[Service]
User=$ADAUSR_SRV
Type=simple
Environment="DISPLAY=:99"
ExecStart=/usr/bin/xvfb-run -a /usr/bin/phd2
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target

EOF

sudo apt update -y
sudo apt full-update -y
sudo apt autoremove -y
sudo apt autoclean -y

echo -n "Reboot? [y/N] " && read -r -t 30 yn
if [[ "${yn,,}" == y ]]; then
    sudo reboot
fi

# // Copyright 2026 Drew Vandagriff
# //
# // Licensed under the Apache License, Version 2.0 <LICENSE-APACHE or
# // http://www.apache.org/licenses/LICENSE-2.0> or the MIT license
# // <LICENSE-MIT or http://opensource.org/licenses/MIT>, at your
# // option. This file may not be copied, modified, or distributed
# // except according to those terms.
