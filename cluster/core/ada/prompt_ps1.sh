#!/bin/bash
set -euxo pipefall
source ada-preflight "${BASH_SOURCE[0]}"

target="/etc/bash.bashrc"
pattern="export PS1="
data="${pattern}'\[${ADA_BLU2}\]\u\[${ADA_PLUM}\]<3\[${ADA_BLU1}\][\w] \[${ADA_GRAY}\]\$ \[\e[0m\]'"

if grep -q $pattern $target; then
    sudo sed -i "/$pattern/c\\$data" $target
else
    echo $data | sudo tee -a $target > /dev/null
fi
