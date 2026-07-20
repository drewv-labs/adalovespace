#!/usr/bin/env bash
# AdaLovespace Strapper — resolve source from filesystem, bootstrap symlinks
#
# Usage: source "${BASH_SOURCE[0]%/*}/ada-strapper.sh" <node_name>
#
# Finds the actual repo root by walking up from the caller's location,
# then ensures cluster.env:ADA_CODESPACE and /usr/local/bin/ macros are set up.
# Must be sourced (not executed) so it runs in the caller's context.

[ -n "${_ADA_STRAPPER_LOADED:-}" ] && return 0

_strapper_node="${1:?usage: source ada-strapper.sh <node_name>}"
_strapper_dir="$(cd "$(dirname "$BASH_SOURCE[0]")" && pwd)"
_cluster_env="ada/cluster.env"
# Resolve the actual repo root by walking up from this script's location.
# This works regardless of where we're called from and doesn't depend on PATH.
_strapper_candidate="${_strapper_dir}"
while [[ "${_strapper_candidate}" != "/" ]]; do
    if [[ -f "${_strapper_candidate}/${_cluster_env}" ]]; then
        break
    fi
    _strapper_candidate="$(dirname "${_strapper_candidate}")"
done

if [[ ! -f "${_strapper_candidate}/${_cluster_env}" ]]; then
    echo "FATAL: [ada-strapper] Could not locate cluster.env from ${BASH_SOURCE[0]}" >&2
    return 1
fi

# Source cluster.env to get ADA_CODESPACE, etc. (without root check).
set +u
source "${_strapper_candidate}/${_cluster_env}"
set -u

_strapper_is_root=false
if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    _strapper_is_root=true
fi

_setup_codespace() {
    # Only set up codespace symlink if we're running from /home/<user>/adalovespace
    local source_path
    if [[ "${_strapper_candidate}" == /home/* ]]; then
        source_path="${_strapper_candidate}"
    else
        return 0
    fi

    if [[ ! -L "${ADA_CODESPACE:-}" ]] && [[ ! -d "${ADA_CODESPACE:-}" ]]; then
        echo "[ada-strapper] Creating codespace symlink: ${source_path} -> ${ADA_CODESPACE}"
        sudo ln -sf "${source_path}" "${ADA_CODESPACE}"
    fi

    # Verify the codespace is actually usable (cluster.env should be reachable)
    if [[ ! -f "${ADA_CODESPACE}/${_cluster_env}" ]]; then
        echo "[ada-strapper] WARNING: Codespace not accessible at ${ADA_CODESPACE}" >&2
        return 0
    fi
}

_setup_libs() {
    local target_dir="/usr/local/bin"

    # Prefer ADA_CODESPACE if available, fallback to the resolved repo root
    local lib_dir=""
    if [[ -e "${ADA_CLUSTER}/lib" ]]; then
        lib_dir="${ADA_CLUSTER}/lib"
    else
        lib_dir="${_strapper_candidate}/${ADA_CLUST_S}/lib"
    fi

    for macro in "${lib_dir}"/*.sh; do
        [ -f "${macro}" ] || continue
        local name="${macro##*/}"             # "ada-log.sh"
        local base="${name%.sh}"              # "ada-log" (strip .sh)
        sudo ln -sf "${macro}" "${target_dir}/${base}" && sudo chmod +x "${target_dir}/${base}"
    done

    # Clean up stale symlinks that shouldn't be in /usr/local/bin/
    if [[ -L "${target_dir}/lib" ]]; then
        echo "[ada-strapper] Removing stale symlink: ${target_dir}/lib"
        sudo rm -f "${target_dir}/lib"
    fi
}

# Only run setup steps when executing as root (the expected use case)
if [[ "${_strapper_is_root}" == true ]]; then
    _setup_codespace
    _setup_libs
fi

_ADA_STRAPPER_LOADED=1
export ADA_STRAPPER_NODE="${_strapper_node}"
