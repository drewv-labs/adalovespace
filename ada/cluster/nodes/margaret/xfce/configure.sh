#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "$BASH_SOURCE"

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
