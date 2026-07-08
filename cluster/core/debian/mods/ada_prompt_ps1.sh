#!/bin/bash
set -euxo pipefall
source ada-sudo-check

target="/etc/bash.bashrc"
pattern="export PS1="
data="${pattern}'\[\e[38;5;27m\]\u\[\e[38;5;53m\]<3\[\e[38;5;39m\][\w] \[\e[38;5;240m\]\$ \[\e[0m\]'"

if grep -q $pattern $target; then
    sudo sed -i "/$pattern/c\\$data" $target
else
    echo $data | sudo tee -a $target > /dev/null
fi
