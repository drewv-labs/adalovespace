#!/bin/bash
set -euxo pipefall
source ada-sudo-check
if ! check_sudo_access; then
    echo "Aborting deployment"
    exit 1
fi

source ada-env "${BASH_SOURCE[0]}"

target="/etc/bash.bashrc"
pattern="export PS1="
data="${pattern}'\[${ADA_BLU2}\]\u\[${ADA_PLUM}\]<3\[${ADA_BLU1}\][\w] \[${ADA_GRAY}\]\$ \[\e[0m\]'"

if grep -q $pattern $target; then
    sudo sed -i "/$pattern/c\\$data" $target
else
    echo $data | sudo tee -a $target > /dev/null
fi
