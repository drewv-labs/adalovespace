#!/bin/bash
# ==============================================================================
# MaryGuider - Headless PHD2 Engine (USB Device Mode)
# Target OS: Raspberry Pi OS Lite (64-bit)
# Hardware: Raspberry Pi Zero 2 W
# ==============================================================================
set -e

# Handle the boot path change introduced in Debian Bookworm
if [ -d "/boot/firmware" ]; then
    BOOT_DIR="/boot/firmware"
else
    BOOT_DIR="/boot"
fi

echo "========================================================"
echo " Phase 1: USB Device Mode (Ethernet Gadget) Injection"
echo "========================================================"
# Enable the DWC2 USB controller overlay
if ! grep -q "^dtoverlay=dwc2" "$BOOT_DIR/config.txt"; then
    echo "⚡ Injecting dwc2 overlay into config.txt..."
    echo "dtoverlay=dwc2" | sudo tee -a "$BOOT_DIR/config.txt" > /dev/null
fi

# Load the dwc2 and g_ether modules directly into the boot command line
if ! grep -q "modules-load=dwc2,g_ether" "$BOOT_DIR/cmdline.txt"; then
    echo "⚡ Modifying kernel cmdline for Ethernet gadget..."
    sudo sed -i 's/rootwait/rootwait modules-load=dwc2,g_ether/' "$BOOT_DIR/cmdline.txt"
fi

echo "========================================================"
echo " Phase 2: X11 Phantom & Native Binaries"
echo "========================================================"
sudo apt-get update -y

# We only install the bare minimum packages.
# indi-bin provides the low-level camera drivers if PHD2 needs direct access.
sudo apt-get install -y \
    phd2 \
    xvfb \
    indi-bin

echo "========================================================"
echo " Phase 3: Headless PHD2 Systemd Daemon"
echo "========================================================"
# We wrap the PHD2 executable in xvfb-run and pass the --server flag.
# This forces PHD2 to expose its API on TCP port 4400.

sudo tee /etc/systemd/system/maryguider.service > /dev/null <<EOF
[Unit]
Description=MaryGuider PHD2 Headless Engine
After=network.target

[Service]
Type=simple
User=$USER
Environment="DISPLAY=:99"
ExecStart=/usr/bin/xvfb-run -a -s "-screen 0 800x600x16" /usr/bin/phd2 --server
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable maryguider.service

echo "========================================================"
echo "✅ MaryGuider Build Complete."
echo "⚠️ REBOOT REQUIRED to initialize the USB Ethernet Kernel Modules."
echo "========================================================"
