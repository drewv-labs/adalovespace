#!/bin/bash
# AdaLovespace Preflight No SUDO Check — Env loader only (no root check)
#
# Usage: source ada-preflight-optional "${BASH_SOURCE[0]}"
# Use when root access is not required (e.g., dev environments).

[ -n "${_ADA_PREFLIGHT_LOADED:-}" ] && return 0

_find_ada_root() {
    local input_path="$1"
    if [[ ! -e "$input_path" ]]; then
        echo "FATAL: [ada-preflight-optional] Input path does not exist: ${input_path}" >&2
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

    echo "FATAL: [ada-preflight-optional] Could not locate cluster.env from ${input_path}" >&2
    return 1
}

_load_env() {
    local env_file="${ADALOVESPACE_CONF:-cluster.env}"
    if [[ -f "${ADA_ROOT}/${env_file}" ]]; then
        set +u
        source "${ADA_ROOT}/${env_file}"
        set -u
    else
        echo "FATAL: [ada-preflight-optional] Could not locate ${env_file} in ${ADA_ROOT}" >&2
        return 1 2>/dev/null || exit 1
    fi
}

ADA_ROOT="$(_find_ada_root "${1:?usage: source ada-preflight-optional \"\${BASH_SOURCE[0]}\"}")" || exit $?
export ADA_ROOT

_load_env || exit $?

_ADA_PREFLIGHT_LOADED=1
