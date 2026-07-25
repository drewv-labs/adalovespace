#!/usr/bin/env bash
# AdaLovespace Strapper — resolve source from filesystem, bootstrap symlinks
#
# Usage: source ada-strapper jakebase
# # This will install jakebase from local git repo
#
# Usage: source ada-strapper margaret
# # This will install margaret from jakebase nfs
#
# Usage: source ada-strapper margaret local
# # This will install margaret from local git repo

set -euo pipefail

[ -n "${_ADA_STRAPPER_LOADED:-}" ] && return 0

# Resolve local build flag for non-jakebase nodes
# flag is irrelevant for jakebase nodes
_is_local_build=false
if [[ "${2:-}" == "local" ]]; then
    _is_local_build=true
fi

_strapper_node="${1:?usage: source ada-strapper.sh <node_name> [local:-]}"
_strapper_dir="$(cd "$(dirname "$BASH_SOURCE")" && pwd)"
_cluster_env="ada/cluster.env"
# Resolve the actual repo root by walking up from this script's location.
# This works regardless of where we're called from and doesn't depend on PATH.
_strapper_candidate="$_strapper_dir"
while [[ "$_strapper_candidate" != "/" ]]; do
    if [[ -f "$_strapper_candidate/$_cluster_env" ]]; then
        break
    fi
    _strapper_candidate="$(dirname "$_strapper_candidate")"
done

if [[ ! -f "$_strapper_candidate/$_cluster_env" ]]; then
    ada-logger oof "FATAL: [ada-strapper] Could not locate cluster.env from $BASH_SOURCE"
    return 1
fi

# Source cluster.env to get ADA_CODESPACE, etc. (without root check).
set +u
source "$_strapper_candidate/$_cluster_env"
set -u

_strapper_is_root=false
if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    _strapper_is_root=true
fi

_setup_codespace_from_local() {
    # // This guy will mainly run on JakeBase or if we need to spin up a
    # // node manually from git repo.
    # // Otherwise, for standard operating procedure, all nodes except JakeBase & RadiaWrt
    # // will setup codebase from JakeBase NFS
    # Only set up codespace symlink if we're running from /home/<user>/adalovespace
    local source_path
    if [[ "$_strapper_candidate" == /home/* ]]; then
        source_path="$_strapper_candidate"
    else
        return 0
    fi

    if [[ ! -L "${ADA_CODESPACE:-}" ]] && [[ ! -d "${ADA_CODESPACE:-}" ]]; then
        ada yay "[ada-strapper] Creating codespace symlink: $source_path -> $ADA_CODESPACE"
        sudo ln -sf "$source_path" "$ADA_CODESPACE"
    fi
}

_setup_codespace_from_remote() {
    if [[ ! -d "${NFS_ROOT:-}" ]]; then
        if ! sudo "$ADA_CLUSTER/nodes/jakebase/connect.sh" root; then
            ada-logger oof "FATAL: Could not connect to JakeBase NFS. Is the node reachable?"
            return 1
        fi
    fi

    if [[ ! -L "${ADA_CODESPACE:-}" ]] && [[ ! -d "${ADA_CODESPACE:-}" ]]; then
        ada yay "[ada-strapper] Creating codespace symlink: $NFS_ROOT -> $ADA_CODESPACE"
        sudo ln -sf "$NFS_ROOT" "$ADA_CODESPACE"
    fi
}

_setup_libs() {
    local target_dir="/usr/local/bin"

    # Prefer ADA_CODESPACE if available, fallback to the resolved repo root
    local lib_dir=""
    if [[ -e "$ADA_CLUSTER/lib" ]]; then
        lib_dir="$ADA_CLUSTER/lib"
    else
        lib_dir="$_strapper_candidate/$ADA_CLUST_S/lib"
    fi

    for macro in "$lib_dir"/*.sh; do
        [ -f "$macro" ] || continue
        local name="${macro##*/}"
        local macrosrc="$lib_dir/$macro"
        local base="${name%.sh}"
        local target="$target_dir/$base"
        sudo ln -sf "$macrosrc" "$target" && sudo chmod +x "$target"
        ada-logger yay "[ada-strapper] Installed $target from $macrosrc"
    done
}

# Only run setup steps when executing as root (the expected use case)
if [[ "$_strapper_is_root" == true ]]; then
    case $_strapper_node in
        jakebase)
            _setup_codespace_from_local
            ;;
        *)
            if [[ "$_is_local_build" == true ]]; then
                _setup_codespace_from_local
            else
                _setup_codespace_from_remote
            fi
            ;;
    esac

    if ! _validate_codespace; then
        return 1
    fi

    _setup_libs
fi

_ADA_STRAPPER_LOADED=1
export ADA_STRAPPER_NODE="$_strapper_node"
