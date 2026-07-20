#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "$BASH_SOURCE"

ada-log mod "=== Configuring PHD2 Guiding Engine"

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

ada-log yay "=== PHD2 Guiding Engine Configured Successfully"
echo ""
