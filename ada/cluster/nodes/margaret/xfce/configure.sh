#!/usr/bin/env bash
set -euo pipefail
source ada-preflight "$BASH_SOURCE"

# // Tracer — toggle with ADA_TRACE=1
source "$ADA_CLUSTER/lib/ada-tracer.sh" "${ADA_TRACE:-0}"

ada-log app "=== Configuring Passwordless Login for MarPro-User=$ADAUSR_ADM"

sudo groupadd -r nopasswdlogin
sudo gpasswd -a "$ADAUSR_ADM" nopasswdlogin

sudo tee -a /etc/lightdm/lightdm.conf << EOF
[Seat:*]
    autologin-user="$ADAUSR_ADM"
    autologin-user-timeout=0
    user-session=xfce
EOF

ada-log yay "=== Passwordless Login Configured for MarPro-User=$ADAUSR_ADM"
