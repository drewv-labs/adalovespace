#!/usr/bin/env bash
# AdaLovespace Preflight — Root check + env loader (merged sudo-check & ada-env)
#
# Usage: source ada-preflight "$BASH_SOURCE[0]"
#
# Checks root, resolves ADA_ROOT, sources cluster.env.

[ -n "${_ADA_PREFLIGHT_LOADED:-}" ] && return 0

_check_root() {
    if [[ "$EUID" -ne 0 ]]; then
        echo "FATAL: [ada-preflight] This script must run as root (EUID=$(id -u))." >&2
        return 1 2>/dev/null || exit 1
    fi
}

_find_ada_root() {
    local input_path="${1}"
    if [[ ! -e "$input_path" ]]; then
        echo "FATAL: [ada-preflight] Input path does not exist: $input_path" >&2
        return 1
    fi

    local cur="$(readlink -f "$input_path")"
    while [[ "$cur" != "/" ]]; do
        if [[ -f "$cur/cluster.env" ]]; then
            echo "$cur"
            return 0
        fi
        cur="$(dirname "$cur")"
    done

    echo "FATAL: [ada-preflight] Could not locate cluster.env from $input_path" >&2
    return 1
}

_load_env() {
    local env_file="${ADALOVESPACE_CONF:-cluster.env}"
    if [[ -f "$ADA_ROOT/$env_file" ]]; then
        set +u
        source "$ADA_ROOT/$env_file"
        set -u
    else
        echo "FATAL: [ada-preflight] Could not locate $env_file in $ADA_ROOT" >&2
        return 1 2>/dev/null || exit 1
    fi
}

_check_root || exit $?
_BASH_SRC="\${BASH_SOURCE[0]}"
_INPUT_PATH="${1:?usage: source ada-preflight \"$_BASH_SRC\"}"
if [[ "$_INPUT_PATH" != /* ]]; then
    _INPUT_PATH="$(pwd)/$_INPUT_PATH"
fi
ADA_ROOT="$(_find_ada_root "$_INPUT_PATH")" || exit $?
export ADA_ROOT

_load_env || exit $?

check_sudo_access() { _check_root; }

_ADA_PREFLIGHT_LOADED=1
