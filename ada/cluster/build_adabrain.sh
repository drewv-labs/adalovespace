#!/usr/bin/env bash
# ==============================================================================
# AdaBrain - Headless INDI Edge Node Protocol
# Target OS: Raspberry Pi OS Lite (64-bit)
# Python Engine: uv (Astral)
# ==============================================================================
set -euxo pipefail

# ==============================================================================
# Configuration
# ==============================================================================
source ./ada/cluster.env

## // tune_sudoers
# 1. Write the rule atomically into the drop-in directory
# ada_usr="drew"
sudoers_file="/etc/sudoers.d/010_${USER}_nopasswd"
echo "$USER ALL=(ALL) NOPASSWD: ALL" | sudo tee "$sudoers_file" > /dev/null

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

# ==============================================================================
# Debian Core Programs - UV/StressNG
# ==============================================================================
if ! command -v uv &> /dev/null; then
    echo "uv not found. Installing Astral's uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sudo env UV_INSTALL_DIR="/usr/local/bin" sh
    # Source the environment so uv is immediately available in this script
    source $HOME/.cargo/env
fi
sudo apt install stress-ng -y



# We drop python3-venv and python3-pip entirely.
# Just installing the raw C++ hardware drivers and curl.
sudo apt-get install -y \
    indi-full \
    indi-bin \
    gsc \
    curl

# Create the dedicated directory for the web server
sudo mkdir -p /opt/indiweb
sudo chown -R $USER:$USER /opt/indiweb
cd /opt/indiweb

# uv venv creates the isolated environment in milliseconds
uv venv

# uv pip install automatically detects the .venv in the current directory
# No need to activate/deactivate the shell!
uv pip install indiwebmanager

echo "========================================================"
echo " Phase 3: Systemd Daemon Injection"
echo "========================================================"
# The daemon points directly to the uv-generated binary path
sudo tee /etc/systemd/system/indiweb.service > /dev/null <<EOF
[Unit]
Description=INDI Web Manager (AdaBrain Edge)
After=network.target

[Service]
Type=simple
User=$USER
Environment="PATH=/opt/indiweb/.venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
ExecStart=/opt/indiweb/.venv/bin/indi-web -p 8624
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and enable the background service
sudo systemctl daemon-reload
sudo systemctl enable indiweb.service
sudo systemctl restart indiweb.service

echo "========================================================"
echo "AdaBrain Headless Node is Live! (Built with uv)"
echo "You can now hit the web interface at: http://$ADABRAIN_IP:8624"
echo "========================================================"

sudo apt update -y
sudo apt full-update -y
sudo apt autoremove -y
sudo apt autoclean -y

echo -n "Reboot? [y/N] " && read -r -t 30 yn
if [[ "${yn,,}" == y ]]; then
    sudo reboot
fi
