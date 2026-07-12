#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "${BASH_SOURCE[0]}"

echo "${ADA_PLUM}=== Configuring Passwordless Login for User=${ADA_ADMN}"

sudo groupadd -r nopasswdlogin
sudo gpasswd -a ${ADA_ADMN} nopasswdlogin

sudo tee -a /etc/lightdm/lightdm.conf | cat << EOF
[Seat:*]
    autologin-user=${ADA_ADMN}
    autologin-user-timeout=0
    user-session=xfce
EOF

echo "${YAY_GRN}=== Passwordless Login Configured for User=${ADA_ADMN}\n"
