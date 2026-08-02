#!/usr/bin/env bash
set -euo pipefail
source ada-preflight "$BASH_SOURCE"

# // Tracer — toggle with ADA_TRACE=1
source "$ADA_CLUSTER/lib/ada-tracer.sh" "${ADA_TRACE:-0}"

ada-logger app "=== Configuring MarGo Stack (VNC)"

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

ada-logger app "[MarGo] Xvfb unit created → http://$MARGARET_IP:${WEBSOCKIFY_PORT}/vnc.html"

# ==============================================================================
# 2. x11vnc Service — Captures virtual display to VNC protocol
# ==============================================================================
if [[ -n "$VNC_PASSWORD" ]]; then
    # Create password file
    sudo mkdir -p /home/$ADAUSR_SRV/.vnc
    echo "$VNC_PASSWORD" | x11vnc -storepasswd - /home/$ADAUSR_SRV/.vnc/vncpass 2>/dev/null || true
    sudo chown -R $ADAUSR_SRV:$ADAUSR_SRV /home/$ADAUSR_SRV/.vnc/
    VNC_AUTH="-rfbauth /home/$ADAUSR_SRV/.vnc/vncpass"
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
User=$ADAUSR_SRV
ExecStart=/usr/bin/x11vnc -display :99 $VNC_AUTH -forever -shared -rfbport $VNC_PORT -bg
Restart=on-failure
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable adalovespace-margo-vnc.service
ada-logger app "[MarGo] x11vnc unit created"

# ==============================================================================
# 3. websockify Service — Bridges VNC → WebSocket for noVNC viewer
# ==============================================================================
sudo tee /etc/systemd/system/adalovespace-margo-novnc.service > /dev/null <<EOF
[Unit]
Description=Ada Lovespace MarGo noVNC WebSocket Bridge
After=adalovespace-margo-vfb.service network-online.target

[Service]
Type=simple
User=$ADAUSR_SRV
ExecStart=/usr/bin/websockify --web /usr/share/novnc $WEBSOCKIFY_PORT localhost:$VNC_PORT
Restart=on-failure
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable adalovespace-margo-novnc.service
ada-logger app "[MarGo] websockify unit created"

# ==============================================================================
# 4. Start all services (in order: Xvfb → x11vnc → websockify)
# ==============================================================================
ada-logger app "=== Starting MarGo Services"

sudo systemctl restart adalovespace-margo-vfb.service
sleep 2

sudo systemctl restart adalovespace-margo-vnc.service
sleep 1

sudo systemctl restart adalovespace-margo-novnc.service
sleep 1

# Verify all services are running
for svc in vfb vnc novnc; do
    if sudo systemctl is-active --quiet "adalovespace-margo-$svc.service"; then
        ada-logger yay "[MarGo] $svc service: RUNNING"
    else
        ada-logger oof "[MarGo] $svc service: FAILED to start"
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
