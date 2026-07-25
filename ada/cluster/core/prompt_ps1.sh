#!/usr/bin/env bash
#
set -euo pipefail
source ada-preflight "$BASH_SOURCE"

# // Tracer — toggle with ADA_TRACE=1
source "$ADA_CLUSTER/lib/ada-tracer.sh" "${ADA_TRACE:-0}"

ada-log sys "=== Setting up Ada's Custom Prompt"

target=/etc/bash.bashrc
pattern="export PS1="
data="$pattern'\[\e[38;5;27m\]\u\[\e[38;5;53m\]<3\[\e[38;5;39m\][\w] \[\e[38;5;240m\]\$ \[\e[0m\]'"

safe-tee-sed "$target" "$pattern" "$data" yes
