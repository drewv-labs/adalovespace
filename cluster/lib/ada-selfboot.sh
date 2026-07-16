#!/usr/bin/env bash
# AdaLovespace Self-Boot — resolve source from filesystem, bootstrap symlinks
#
# Usage: source "${BASH_SOURCE[0]%/*}/ada-selfboot.sh" <node_name>
#
# Finds the actual repo root by walking up from the caller's location,
# then ensures /opt/adalovespace and /usr/local/bin/ macros are set up.
# Must be sourced (not executed) so it runs in the caller's context.

[ -n "${_ADA_SELFBOOT_LOADED:-}" ] && return 0

_selfboot_node="${1:?usage: source ada-selfboot.sh <node_name>}"
_selfboot_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Resolve the actual repo root by walking up from this script's location.
# This works regardless of where we're called from and doesn't depend on PATH.
_selfboot_candidate="$_selfboot_dir"
while [[ "$_selfboot_candidate" != "/" ]]; do
    if [[ -f "$_selfboot_candidate/cluster.env" ]]; then
        break
    fi
    _selfboot_candidate="$(dirname "$_selfboot_candidate")"
done

if [[ ! -f "$_selfboot_candidate/cluster.env" ]]; then
    echo "FATAL: [ada-selfboot] Could not locate cluster.env from ${BASH_SOURCE[0]}" >&2
    return 1
fi

# Source cluster.env to get ADA_CODESPACE, etc. (without root check).
set +u
source "$_selfboot_candidate/cluster.env"
set -u

_selfboot_is_root=false
if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    _selfboot_is_root=true
fi

_setup_codespace() {
    # Only set up codespace symlink if we're running from /home/<user>/adalovespace
    local source_path
    if [[ "$_selfboot_candidate" == /home/* ]]; then
        source_path="$_selfboot_candidate"
    else
        return 0
    fi

    if [[ ! -L "${ADA_CODESPACE:-}" ]] && [[ ! -d "${ADA_CODESPACE:-}" ]]; then
        echo "[ada-selfboot] Creating codespace symlink: ${source_path} -> ${ADA_CODESPACE}"
        sudo ln -sf "$source_path" "$ADA_CODESPACE"
    fi

    # Verify the codespace is actually usable (cluster.env should be reachable)
    if [[ ! -f "${ADA_CODESPACE}/cluster.env" ]]; then
        echo "[ada-selfboot] WARNING: Codespace not accessible at ${ADA_CODESPACE}" >&2
        return 0
    fi
}

_setup_libs() {
    local target_dir="/usr/local/bin"

    # Prefer ADA_CODESPACE if available, fallback to the resolved repo root
    local lib_dir=""
    if [[ -e "${ADA_CODESPACE}/cluster/lib" ]]; then
        lib_dir="${ADA_CODESPACE}/cluster/lib"
    else
        lib_dir="$_selfboot_candidate/cluster/lib"
    fi

    for macro in "$lib_dir"/*.sh; do
        [ -f "$macro" ] || continue
        local name="${macro##*/}"
        local link_path="${target_dir}/${name%.sh##*/}"
        sudo ln -sf "$macro" "$link_path" && sudo chmod +x "$link_path"
    done
}

# Only run setup steps when executing as root (the expected use case)
if [[ "$_selfboot_is_root" == true ]]; then
    _setup_codespace
    _setup_libs
fi

_ADA_SELFBOOT_LOADED=1
export ADA_SELFBOOT_NODE="$_selfboot_node"
