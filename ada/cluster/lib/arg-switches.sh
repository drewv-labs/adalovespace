#!/usr/bin/env bash
# Reusable argument parser for mod scripts.
# Usage inside mod: source arg-switches param1 param2 param3
# Expects parameters without dashes (e.g., 'keep-wifi', not '--keep-wifi').
#
arg-switch-if() {
    param="${1}"
    target="${2}"
    cmd="${3}"
    if [ "${param}" = "${target}" ]; then
        eval "${cmd}"
    fi
}

# 1. Initialize all registered arguments to false in the caller's environment
for param in "$@"; do
    var_name="switch_${param//-/_}"
    declare -g "${var_name}=false"
done

# Save original positional parameters
original_args=("$@")

# 2. Parse the actual arguments passed to the parent script ($@ of the caller)
while [[ $# -gt 0 ]]; do
    incoming_flag="${1#--}"
    incoming_flag="${incoming_flag#-}"

    match=false
    for param in "${original_args[@]}"; do
        if [[ "${incoming_flag}" == "${param}" ]]; then
            var_name="switch_${param//-/_}"
            declare -g "${var_name}=true"
            match=true
            break
        fi
    done

    shift
done
