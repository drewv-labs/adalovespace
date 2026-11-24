#!/usr/bin/env bash
# ==============================================================================
# DREW-V Labs // AdaLovespace Core Shell Library (`lib/common.sh`)
# Path: adalovespace/lib/common.sh
#
# Description:
#   Shared logging, caller resolution, safe non-executing key-value config I/O,
#   atomic drift-checked file writes, and hardware/board discovery across
#   `arm64`, `riscv64`, and `amd64` nodes.
# ==============================================================================

[[ -n "${_ADA_COMMON_SH_LOADED:-}" ]] && return 0
_ADA_COMMON_SH_LOADED=1

log_ada()   { printf "\033[1;35m[ADA]\033[0m %s\n" "$1"; }
log_step()  { printf "\n\033[1;36m=== [%s] %s ===\033[0m\n" "$(date +%H:%M:%S)" "$1"; }
log_info()  { printf "\033[1;34m[INFO]\033[0m %s\n" "$1"; }
log_ok()    { printf "\033[1;32m  [OK]\033[0m %s\n" "$1"; }
log_skip()  { printf "\033[1;33m[SKIP]\033[0m %s\n" "$1"; }
log_warn()  { printf "\033[1;33m[WARN]\033[0m %s\n" "$1"; }
log_fail()  { printf "\033[1;31m[FAIL]\033[0m %s\n" "$1" >&2; }
log_fatal() { printf "\033[1;31m[ADA:FATAL]\033[0m %s\n" "$1" >&2; exit 1; }

# Sanitize SSH-forwarded LC_* (e.g. macOS SendEnv) before package operations
ada_sanitize_locale() {
    if { locale -a 2>/dev/null || true; } | grep -qiE '^en_US\.utf-?8$'; then
        export LANG="en_US.UTF-8" LC_ALL="en_US.UTF-8"
    elif { locale -a 2>/dev/null || true; } | grep -qiE '^C\.utf-?8$'; then
        export LANG="C.UTF-8" LC_ALL="C.UTF-8"
    else
        export LANG="C" LC_ALL="C"
    fi
}

# Resolve invoking non-root operator safely without `eval` tilde expansion
ada_resolve_caller() {
    REAL_USER="${SUDO_USER:-$(logname 2>/dev/null || id -un 2>/dev/null || echo root)}"
    REAL_GRP="$(id -gn "$REAL_USER" 2>/dev/null || echo "$REAL_USER")"
    REAL_HOME=""

    if command -v getent >/dev/null 2>&1; then
        REAL_HOME="$(getent passwd "$REAL_USER" 2>/dev/null | cut -d: -f6 || true)"
    elif command -v dscl >/dev/null 2>&1; then
        REAL_HOME="$(dscl . -read "/Users/${REAL_USER}" NFSHomeDirectory 2>/dev/null | awk '{print $2}' || true)"
    fi
    if [[ -z "$REAL_HOME" ]]; then
        if [[ "$REAL_USER" == "root" ]]; then
            REAL_HOME="/root"
        elif [[ -d "/home/${REAL_USER}" ]]; then
            REAL_HOME="/home/${REAL_USER}"
        else
            REAL_HOME="/root"
        fi
    fi
    export REAL_USER REAL_GRP REAL_HOME
}

# Resolve home directory for an arbitrary username safely
ada_user_home() {
    local target_user="$1"
    local uhome=""
    if command -v getent >/dev/null 2>&1; then
        uhome="$(getent passwd "$target_user" 2>/dev/null | cut -d: -f6 || true)"
    fi
    if [[ -z "$uhome" ]]; then
        if [[ "$target_user" == "root" ]]; then
            uhome="/root"
        else
            uhome="/home/${target_user}"
        fi
    fi
    printf '%s\n' "$uhome"
}

# Atomic write from stdin -> destination with explicit mode and optional owner:group
ada_atomic_write() {
    local dst="$1"
    local mode="${2:-0644}"
    local owner="${3:-}"
    local dir tmp
    dir="$(dirname "$dst")"
    mkdir -p "$dir"
    tmp="$(mktemp "${dir}/.$(basename "$dst").ada.XXXXXX")"
    cat > "$tmp"
    chmod "$mode" "$tmp"
    if [[ -n "$owner" ]]; then
        chown "$owner" "$tmp"
    fi
    mv -f "$tmp" "$dst"
}

# Write stdin to destination ONLY if content or mode differs.
# Returns 0 if file was created/updated, 1 if already converged (no-op).
ada_write_if_changed() {
    local dst="$1"
    local mode="${2:-0644}"
    local owner="${3:-}"
    local dir tmp changed="false"
    dir="$(dirname "$dst")"
    mkdir -p "$dir"
    tmp="$(mktemp "${dir}/.$(basename "$dst").ada.XXXXXX")"
    cat > "$tmp"

    if [[ ! -f "$dst" ]] || ! cmp -s "$tmp" "$dst" 2>/dev/null; then
        changed="true"
    fi

    if [[ "$changed" == "true" ]]; then
        chmod "$mode" "$tmp"
        [[ -n "$owner" ]] && chown "$owner" "$tmp"
        mv -f "$tmp" "$dst"
        return 0
    fi

    rm -f "$tmp"
    return 1
}

# Safe non-executing key-value loader (parses KEY="VALUE" / KEY='VALUE' / KEY=VALUE
# without invoking `source` or shell command substitution).
ada_kv_load() {
    local file_path="$1"
    [[ -f "$file_path" ]] || return 1

    local line key val
    while IFS= read -r line || [[ -n "$line" ]]; do
        line="${line#"${line%%[![:space:]]*}"}"
        [[ -z "$line" || "$line" == \#* ]] && continue
        if [[ "$line" =~ ^([A-Za-z_][A-Za-z0-9_]*)[[:space:]]*=[[:space:]]*(.*)$ ]]; then
            key="${BASH_REMATCH[1]}"
            val="${BASH_REMATCH[2]}"
            # Trim trailing whitespace unless inside quotes
            if [[ "$val" =~ ^\"(.*)\"[[:space:]]*(#.*)?$ ]]; then
                val="${BASH_REMATCH[1]}"
                val="${val//\\\"/\"}"
                val="${val//\\\\/\\}"
            elif [[ "$val" =~ ^\'(.*)\'[[:space:]]*(#.*)?$ ]]; then
                val="${BASH_REMATCH[1]}"
            else
                val="${val%%#*}"
                val="${val%"${val##*[![:space:]]}"}"
            fi
            printf -v "$key" '%s' "$val"
            export "${key?}"
        fi
    done < "$file_path"
}

# Detect primary wired/active network interface dynamically via default route
ada_detect_primary_nic() {
    local nic=""
    if command -v ip >/dev/null 2>&1; then
        nic="$(ip -o -4 route show to default 2>/dev/null | awk '{print $5; exit}' || true)"
        if [[ -z "$nic" ]]; then
            nic="$(ip -o link show up 2>/dev/null | awk -F': ' '{print $2}' | cut -d@ -f1 | grep -vE '^(lo|tailscale0|usb0|docker0|br-|veth|virbr)' | head -n1 || true)"
        fi
    fi
    printf '%s\n' "${nic:-eth0}"
}

# Detect active IPv4 CIDR network (e.g. 10.42.0.0/24) or fall back to 10.42.0.0/24
ada_detect_subnet() {
    local nic cidr
    nic="$(ada_detect_primary_nic)"
    if command -v python3 >/dev/null 2>&1 && command -v ip >/dev/null 2>&1; then
        cidr="$(ip -o -4 addr show dev "$nic" scope global 2>/dev/null | awk '{print $4; exit}' || true)"
        if [[ -n "$cidr" ]]; then
            python3 -c 'import ipaddress, sys; print(ipaddress.ip_interface(sys.argv[1]).network)' "$cidr" 2>/dev/null && return 0
        fi
    fi
    printf '10.42.0.0/24\n'
}

# Normalize board alias -> canonical tag in `boards/<tag>.env`
ada_normalize_board() {
    local raw
    raw="$(tr '[:upper:]' '[:lower:]' <<< "${1:-}")"
    case "$raw" in
        rpi5|pi5|raspberrypi5|bcm2712|adactrl-rpi5)
            printf 'rpi5\n' ;;
        rv2|opirv2|orangepi-rv2|orangepi/rv2|spacemit-k1|ky-x1|adactrl-rv2|alonev-air)
            printf 'rv2\n' ;;
        vf2|visionfive2|starfive-vf2|starfive/vf2|starfive-jh7110|jh7110)
            printf 'vf2\n' ;;
        jptr2|jupiter2|milkv-jupiter2|milkv/jupiter2|spacemit-k3|alonev-pro)
            printf 'jptr2\n' ;;
        n100|x86_64|amd64|alderlake-n|margistars-n100)
            printf 'n100\n' ;;
        *)
            printf '\n' ;;
    esac
}

# Normalize node role alias -> canonical role name in `roles/<role>.env`
ada_normalize_role() {
    local raw
    raw="$(tr '[:upper:]' '[:lower:]' <<< "${1:-}")"
    case "$raw" in
        adactrl|adabrain|scope|adascope|adactrl-rpi5|adactrl-rv2)
            printf 'adactrl\n' ;;
        jakebase|broker|databroker|jakebase-vf2)
            printf 'jakebase\n' ;;
        caroline-v|carolinev|caroline|inference|carolinev-vf2)
            printf 'caroline-v\n' ;;
        margistars|margistar|margimaestro|maestro|margistars-n100|margimaestro-rv2)
            printf 'margistars\n' ;;
        alonev-air|alonev|all-in-one)
            printf 'alonev-air\n' ;;
        *)
            printf '\n' ;;
    esac
}

# Auto-detect board tag + DT model from /etc/rvdk/kit.env -> /proc/device-tree/model -> uname -m
ada_detect_board() {
    ADA_DT_MODEL="Unknown"
    ADA_DETECTED_BOARD=""

    if [[ -r /etc/rvdk/kit.env ]]; then
        ada_kv_load /etc/rvdk/kit.env || true
        [[ -n "${RVDK_DT_MODEL:-}" ]] && ADA_DT_MODEL="$RVDK_DT_MODEL"
        if [[ -n "${RVDK_BOARD_TAG:-}" ]]; then
            ADA_DETECTED_BOARD="$(ada_normalize_board "$RVDK_BOARD_TAG")"
        fi
    fi

    if [[ "$ADA_DT_MODEL" == "Unknown" && -r /proc/device-tree/model ]]; then
        ADA_DT_MODEL="$(tr -d '\0' < /proc/device-tree/model 2>/dev/null || echo "Unknown")"
    fi

    if [[ -z "$ADA_DETECTED_BOARD" ]]; then
        local dt_lc
        dt_lc="$(tr '[:upper:]' '[:lower:]' <<< "$ADA_DT_MODEL")"
        case "$dt_lc" in
            *"raspberry pi 5"*)
                ADA_DETECTED_BOARD="rpi5" ;;
            *"orangepi-rv2"*|*"orangepi rv2"*|*"orange pi rv2"*|*"ky x1"*|*"spacemit"*)
                ADA_DETECTED_BOARD="rv2" ;;
            *"jupiter 2"*|*"k3"*)
                ADA_DETECTED_BOARD="jptr2" ;;
            *"visionfive 2"*|*"vf2"*|*"jh7110"*)
                ADA_DETECTED_BOARD="vf2" ;;
            *)
                case "$(uname -m)" in
                    x86_64|amd64)  ADA_DETECTED_BOARD="n100" ;;
                    aarch64|arm64) ADA_DETECTED_BOARD="rpi5" ;;
                    riscv64)       ADA_DETECTED_BOARD="rv2" ;;
                esac
                ;;
        esac
    fi

    export ADA_DT_MODEL ADA_DETECTED_BOARD
}

# Infer default role from current hostname or detected board
ada_infer_default_role() {
    local hname="${1:-$(hostname 2>/dev/null || echo "")}"
    local btag="${2:-rpi5}"
    local h_lc
    h_lc="$(tr '[:upper:]' '[:lower:]' <<< "$hname")"
    case "$h_lc" in
        *jakebase*)             printf 'jakebase\n' ;;
        *caroline*)             printf 'caroline-v\n' ;;
        *margi*)                printf 'margistars\n' ;;
        *alonev*)               printf 'alonev-air\n' ;;
        *adactrl*|*adabrain*)   printf 'adactrl\n' ;;
        *)
            case "$btag" in
                n100) printf 'margistars\n' ;;
                vf2)  printf 'jakebase\n' ;;
                *)    printf 'adactrl\n' ;;
            esac
            ;;
    esac
}
