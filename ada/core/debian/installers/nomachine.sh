#!/usr/bin/env bash
set -euo pipefail
if [ ! $1 ]; then
    echo "Usage: $0 <version>; e.g. $0 1.2.3.4"
    exit 1
fi
v_full="$1"
v_majmin=$(echo "$v_full" | cut -d. -f1,2)
wget https://download.nomachine.com/download/${v_majmin}/Linux/nomachine_${v_full}_amd64.deb
sudo dpkg -i nomachine_${v_full}_amd64.deb
