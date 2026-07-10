#!/bin/bash
set -euxo pipefail
source ada-preflight "${BASH_SOURCE[0]}"

echo "${ADA_BLU1}=== Setting up Ada's Custom Prompt"
target="/etc/bash.bashrc"
pattern="export PS1="
data="${pattern}'\[${ADA_BLU2}\]\u\[${ADA_PLUM}\]<3\[${ADA_BLU1}\][\w] \[${ADA_GRAY}\]\$ \[\e[0m\]'"

safe-tee-quote "$target" "$pattern" "$data" "yes"
