#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "${BASH_SOURCE[0]}"

ada-log "mod" "=== Configuring Passwordless Login for User=${ADA_ADMN}"

sudo groupadd -r nopasswdlogin
sudo gpasswd -a ${ADA_ADMN} nopasswdlogin

sudo tee -a /etc/lightdm/lightdm.conf | cat << EOF
[Seat:*]
    autologin-user=${ADA_ADMN}
    autologin-user-timeout=0
    user-session=xfce
EOF

ada-log "yay" "=== Passwordless Login Configured for User=${ADA_ADMN}\n"
