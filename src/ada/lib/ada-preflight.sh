#!/usr/bin/env bash
# AdaLovespace Preflight — Root check + env loader (merged sudo-check & ada-env)
#
# Usage: source ada-preflight "$BASH_SOURCE[0]"
#
# Checks root, resolves ADA_ROOT, sources cluster.env.

set -euo pipefail

[ -n "${_ADA_PREFLIGHT_LOADED:-}" ] && return 0

_check_root() {
    if [[ "$EUID" -ne 0 ]]; then
        echo "FATAL: [ada-preflight] This script requires root privileges (EUID=$(id -u))." >&2
        return 1
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
        # Prefer ada_config.toml (TOML), fall back to cluster.env (legacy)
        if [[ -f "$cur/ada/ada_config.toml" ]]; then
            echo "$cur"
            return 0
        fi
        cur="$(dirname "$cur")"
    done

    # Second pass: look for legacy cluster.env
    cur="$(readlink -f "$input_path")"
    while [[ "$cur" != "/" ]]; do
        if [[ -f "$cur/ada/.env" ]]; then
            echo "$cur"
            return 0
        fi
        cur="$(dirname "$cur")"
    done

    echo "FATAL: [ada-preflight] Could not locate ada_config.toml or cluster.env from $input_path" >&2
    return 1
}

_load_env() {
    # Resolve config path — prefer explicit override, fall back to TOML then legacy .env
    local conf_file="${ADALOVESPACE_CONF:-ada_config.toml}"
    local resolved="${ADA_ROOT}/ada/${conf_file}"

    if [[ ! -f "$resolved" ]]; then
        echo "FATAL: [ada-preflight] Could not locate $conf_file in $ADA_ROOT" >&2
        return 1 2>/dev/null || exit 1
    fi

    # If TOML, use Python loader to produce flat env vars; otherwise source directly.
    if [[ "$resolved" == *.toml ]]; then
        local loader="${ADA_ROOT}/ada/lib/env-loader.py"
        if [[ ! -f "$loader" ]]; then
            # ADA_ROOT may point inside 'ada/' subdir — look up one level
            loader="$(dirname "$ADA_ROOT")/lib/env-loader.py"
        fi
        if [[ -f "$loader" ]]; then
            set +u
            eval "$(python3 "$loader")"
            set -u
        else
            echo "FATAL: [ada-preflight] TOML loader not found at $loader" >&2
            return 1 2>/dev/null || exit 1
        fi
    else
        # Legacy .env / cluster.env — source as-is
        set +u
        source "$resolved"
        set -u
    fi
}

_check_root || true  # Don't fail if run non-root; scripts that need root can call _check_root themselves
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
