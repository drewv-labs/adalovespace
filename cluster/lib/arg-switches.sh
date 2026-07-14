#!/usr/bin/env bash
# Reusable argument parser for mod scripts.
# Usage inside mod: source arg-switches param1 param2 param3
# Expects parameters without dashes (e.g., 'keep-wifi', not '--keep-wifi').

# 1. Initialize all registered arguments to false in the caller's environment
for param in "$@"; do
    # Replace dashes with underscores for valid variable names
    var_name="switch_${param//-/_}"
    declare -g "$var_name=false"
done

# 2. Parse the actual arguments passed to the parent script ($@ of the caller)
# Note: We must loop until we've evaluated every position parameter.
while [[ $# -gt 0 ]]; do
    # Strip leading dashes from the passed flag (e.g., --keep-wifi -> keep-wifi)
    incoming_flag="${1#--}"
    incoming_flag="${incoming_flag#-}"

    # Check if this incoming flag matches any of the registered parameters
    match=false
    for param in "$@"; do
        if [[ "$incoming_flag" == "$param" ]]; then
            var_name="switch_${param//-/_}"
            declare -g "$var_name=true"
            match=true
            break
        fi
    done

    # Drop the handled argument and advance to the next one
    shift
done
