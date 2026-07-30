#!/usr/bin/env bash
# set -euxo pipefail

## // tune_sudoers
# 1. Write the rule atomically into the drop-in directory
skag_usr="drew"
sudoers_file="/etc/sudoers.d/010_${skag_usr}_nopasswd"
echo "$skag_usr ALL=(ALL) NOPASSWD: ALL" | sudo tee "$sudoers_file" > /dev/null

# 2. Enforce strict permissions (Must be 0440 or sudo will reject it)
sudo chmod 0440 "$sudoers_file"

# 3. Validate the syntax safely before completing the build
if ! sudo visudo -cf "$sudoers_file"; then
    echo "Malformed sudoers syntax detected! Removing file to prevent system lockout."
    sudo rm -f "$sudoers_file"
    exit 1
fi

## // sys_tuner
sudo apt update -y

sudo systemctl disable --now apt-daily-upgrade.timer
sudo systemctl disable --now apt-daily.timer
sudo systemctl disable --now bluetooth.service
sudo systemctl disable --now ModemManager.service
sudo systemctl disable --now multipathd.service multipathd.socket
sudo systemctl disable --now unattended-upgrades.service
sudo systemctl disable --now wpa_supplicant.service

sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target

sudo touch /etc/cloud/cloud-init.disabled

sudo apt-mark unhold bluez
sudo apt-mark unhold wpasupplicant

sudo apt purge bluez
sudo apt purge modemmanager -y
sudo apt purge multipath-tools -y
sudo apt purge wpasupplicant
sudo apt purge cloud-init -y

sudo rm -rf /etc/cloud/ /var/lib/cloud/

## // base_installs
curl -LsSf https://astral.sh/uv/install.sh | sudo env UV_INSTALL_DIR="/usr/local/bin" sh
sudo apt install stress-ng -y

## // margaret node build
sudo apt install indi-full -y
sudo apt-add-repository ppa:mutlaqja/ppa
sudo apt update -y && sudo apt install kstars-bleeding -y

# -{ marpro }- Full Desktop Experience (XCFE+LightDM+NX)
sudo apt install xorg xserver-xorg dbus-x11 -y
sudo apt install xfce4 xfce4-goodies lightdm -y
sudo apt purge xfce4-power-manager -y

sudo groupadd -r nopasswdlogin
sudo gpasswd -a "$skag_usr" nopasswdlogin

sudo tee -a /etc/lightdm/lightdm.conf << EOF
[Seat:*]
    autologin-user="$skag_usr"
    autologin-user-timeout=0
    user-session=xfce
EOF

sudo systemctl restart lightdm

wget https://download.nomachine.com/download/${v_majmin}/Linux/nomachine_${v_full}_amd64.deb
sudo dpkg -i nomachine_${v_full}_amd64.deb

# - margo
sudo apt install -y \
    xvfb \
    tigervnc-standalone-server \
    websockify \
    novnc \
    x11vnc

# ==============================================================================
# Configuration (override with env vars before calling this script)
# ==============================================================================
VNC_PORT="${MARGO_VNC_PORT:-$VNC_PORT}"
VNC_PASSWORD="${MARGO_VNC_PASSWORD:-$VNC_PASSWORD}"
WEBSOCKIFY_PORT="${MARGO_WEBSOCKIFY_PORT:-$VNC_WEBSOCKIFY_PORT}"
RESOLUTION="${MARGO_RESOLUTION:-$VNC_RESOLUTION}"

# ==============================================================================
# 1. Xvfb Service — Virtual Display (where KStars runs, invisible to user)
# ==============================================================================
sudo tee /etc/systemd/system/adalovespace-margo-vfb.service > /dev/null <<EOF
[Unit]
Description=Ada Lovespace MarGo Virtual Framebuffer
After=network.target

[Service]
Type=forking
User=$ADAUSR_SRV
Environment=DISPLAY=:99
ExecStart=/usr/bin/Xvfb :99 -screen 0 $RESOLUTION -ac +extension GLX +render -noreset
ExecStop=/bin/kill \$(cat /var/run/adalovespace-xvfb.pid)
PIDFile=/var/run/adalovespace-xvfb.pid
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable adalovespace-margo-vfb.service

echo "[MarGo] Xvfb unit created → http://$MARGARET_IP:${WEBSOCKIFY_PORT}/vnc.html"

# ==============================================================================
# 2. x11vnc Service — Captures virtual display to VNC protocol
# ==============================================================================
if [[ -n "$VNC_PASSWORD" ]]; then
    # Create password file
    sudo mkdir -p /home/$skag_usr/.vnc
    echo "$VNC_PASSWORD" | x11vnc -storepasswd - /home/$skag_usr/.vnc/vncpass 2>/dev/null || true
    sudo chown -R $skag_usr:$skag_usr /home/$skag_usr/.vnc/
    VNC_AUTH="-rfbauth /home/$skag_usr/.vnc/vncpass"
else
    VNC_AUTH="-nopw"
fi

sudo tee /etc/systemd/system/adalovespace-margo-vnc.service > /dev/null <<EOF
[Unit]
Description=Ada Lovespace MarGo x11vnc Server
After=adalovespace-margo-vfb.service network-online.target
Wants=adalovespace-margo-vfb.service

[Service]
Type=simple
User=$skag_usr
ExecStart=/usr/bin/x11vnc -display :99 $VNC_AUTH -forever -shared -rfbport $VNC_PORT -bg
Restart=on-failure
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable adalovespace-margo-vnc.service
echo "[MarGo] x11vnc unit created"

# ==============================================================================
# 3. websockify Service — Bridges VNC → WebSocket for noVNC viewer
# ==============================================================================
sudo tee /etc/systemd/system/adalovespace-margo-novnc.service > /dev/null <<EOF
[Unit]
Description=Ada Lovespace MarGo noVNC WebSocket Bridge
After=adalovespace-margo-vfb.service network-online.target

[Service]
Type=simple
User=$skag_usr
ExecStart=/usr/bin/websockify --web /usr/share/novnc $WEBSOCKIFY_PORT localhost:$VNC_PORT
Restart=on-failure
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable adalovespace-margo-novnc.service
echo "[MarGo] websockify unit created"

# ==============================================================================
# 4. Start all services (in order: Xvfb → x11vnc → websockify)
# ==============================================================================
sudo systemctl restart adalovespace-margo-vfb.service
sleep 2
sudo systemctl restart adalovespace-margo-vnc.service
sleep 1
sudo systemctl restart adalovespace-margo-novnc.service
sleep 1

# Verify all services are running
for svc in vfb vnc novnc; do
    if sudo systemctl is-active --quiet "adalovespace-margo-$svc.service"; then
        echo "[MarGo] $svc service: RUNNING"
    else
        echo "[MarGo] $svc service: FAILED to start"
        exit 1
    fi
done

echo ""
echo "  ┌─────────────────────────────────────────────────────────────────────"
echo "  │ 🌟 Ada Lovespace MarGo — Light KStars Access via Browser"
echo "  ├─────────────────────────────────────────────────────────────────────"
echo "  │  Virtual Display :99 ($RESOLUTION)"
echo "  │  VNC Port        : $VNC_PORT"
echo "  │  noVNC Browser URL: http://<margaret-ip>:$WEBSOCKIFY_PORT/vnc.html?autoconnect=true"
echo "  │  Auth            : $(if [[ -n "$VNC_PASSWORD" ]]; then echo 'Enabled'; else echo 'None (local subnet)'; fi)"
echo "  │  KStars          : Must be started manually on display :99"
echo "  └─────────────────────────────────────────────────────────────────────"
echo ""

sudo apt update -y
sudo apt full-upgrade -y
sudo apt autoremove -y
sudo apt autoclean

echo -n "Reboot? [y/N] " && read -r -t 30 yn
if [[ "${yn,,}" == y ]]; then
    sudo reboot
fi
