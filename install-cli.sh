#!/usr/bin/env bash
# ==============================================================================
# DREW-V Labs // AdaLovespace CLI & System Engine Installer
# Path: adalovespace/install-cli.sh
# Description: Installs or updates the AdaLovespace engine in /opt/adalovespace/engine
#              and links /usr/local/bin/ada (+ /usr/bin/ada on Linux) without
#              mutating OS, INDI, PHD2, or CarrierPigeons state.
#
# Usage:
#   curl -fsSL https://adalovespace.dev/install-cli.sh | sudo bash
#   curl -fsSL adalovespace.dev/install-cli.sh | sudo bash
# ==============================================================================

if [[ -n "${ZSH_VERSION:-}" ]]; then
    emulate -L ksh
    setopt PIPE_FAIL ERR_RETURN NO_UNSET
else
    set -Eeuo pipefail
fi

SCRIPT_SELF="${BASH_SOURCE[0]:-}"
for _arg in "$@"; do
    if [[ "$_arg" == "-h" || "$_arg" == "--help" ]]; then
        cat <<'EOF'
Usage:
  curl -fsSL https://adalovespace.dev/install-cli.sh | sudo bash [-s -- --quiet]

Options:
  -q, --quiet   Suppress post-install banner
  -h, --help    Show this help message and exit
EOF
        exit 0
    fi
done

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    if [[ -n "$SCRIPT_SELF" && -f "$SCRIPT_SELF" ]] && command -v sudo >/dev/null 2>&1; then
        exec sudo -E bash "$SCRIPT_SELF" "$@"
    else
        echo "[ADA:FATAL] Pipe into 'sudo bash': curl -fsSL https://adalovespace.dev/install-cli.sh | sudo bash" >&2
        exit 1
    fi
fi

umask 022

if { locale -a 2>/dev/null || true; } | grep -qiE '^en_US\.utf-?8$'; then
    export LANG="en_US.UTF-8" LC_ALL="en_US.UTF-8"
elif { locale -a 2>/dev/null || true; } | grep -qiE '^C\.utf-?8$'; then
    export LANG="C.UTF-8" LC_ALL="C.UTF-8"
else
    export LANG="C" LC_ALL="C"
fi

REAL_USER="${SUDO_USER:-$(logname 2>/dev/null || id -un 2>/dev/null || echo root)}"
REAL_GRP="$(id -gn "$REAL_USER" 2>/dev/null || echo "$REAL_USER")"
REAL_HOME=""
if command -v getent >/dev/null 2>&1; then
    REAL_HOME="$(getent passwd "$REAL_USER" 2>/dev/null | cut -d: -f6 || true)"
elif command -v dscl >/dev/null 2>&1; then
    REAL_HOME="$(dscl . -read "/Users/${REAL_USER}" NFSHomeDirectory 2>/dev/null | awk '{print $2}' || true)"
fi
if [[ -z "$REAL_HOME" ]]; then
    [[ "$REAL_USER" == "root" ]] && REAL_HOME="/root" || REAL_HOME="/home/${REAL_USER}"
fi

SYS_ROOT="${ADA_SYS_ROOT:-/opt/adalovespace}"
ENGINE_DIR="${ADA_ENGINE_DIR:-${SYS_ROOT}/engine}"
USER_ADA_DIR="${REAL_HOME}/.adalovespace"
SNAP_DIR="${USER_ADA_DIR}/snapshots"
REPO_URL="${ADA_REPO_URL:-https://github.com/drewv-labs/adalovespace.git}"
SSH_REPO_URL="${ADA_SSH_REPO_URL:-git@github.com:drewv-labs/adalovespace.git}"
REPO_BRANCH="${ADA_BRANCH:-main}"
PAGES_BASE_URL="${ADA_BASE_URL:-https://adalovespace.dev}"
QUIET_MODE="false"

for arg in "$@"; do
    case "$arg" in
        -q|--quiet) QUIET_MODE="true" ;;
        *)
            echo "[ADA:FATAL] Unknown argument: ${arg} (try --help)" >&2
            exit 1
            ;;
    esac
done

if [[ ! "$REPO_BRANCH" =~ ^[a-zA-Z0-9._/-]+$ ]]; then
    echo "[ADA:FATAL] Invalid ADA_BRANCH '${REPO_BRANCH}'" >&2
    exit 1
fi

log_info()  { printf "\033[1;35m[ADA:CLI]\033[0m %s\n" "$1"; }
log_ok()    { printf "\033[1;32m  [OK]\033[0m %s\n" "$1"; }
log_fatal() { printf "\033[1;31m[ADA:FATAL]\033[0m %s\n" "$1" >&2; exit 1; }

# 1. Ensure git, curl, ca-certificates, and tar are installed
if ! command -v git >/dev/null 2>&1 || ! command -v curl >/dev/null 2>&1 || ! command -v tar >/dev/null 2>&1; then
    if command -v apt-get >/dev/null 2>&1; then
        log_info "Installing git, curl, and ca-certificates prerequisites..."
        export DEBIAN_FRONTEND=noninteractive
        apt-get -o Acquire::Check-Valid-Until=false -o DPkg::Lock::Timeout=120 update -q || true
        apt-get -o DPkg::Lock::Timeout=120 install -y git ca-certificates curl tar
    else
        log_fatal "Missing git, curl, or tar."
    fi
fi

# 2. Ensure /opt/adalovespace and ~/.adalovespace/snapshots exist cleanly
#    (preserving sibling directories such as /opt/adalovespace/indi_drivers)
install -d -m 0755 "$SYS_ROOT"
install -d -m 0750 -o "$REAL_USER" -g "$REAL_GRP" "$USER_ADA_DIR" "$SNAP_DIR"

fetch_pages_tarball() {
    local tmp_dir tar_url sha_url expected_sha actual_sha stage_dir
    tmp_dir="$(mktemp -d)"
    tar_url="${PAGES_BASE_URL}/engine.tar.gz"
    sha_url="${PAGES_BASE_URL}/engine.sha256"

    log_info "Fetching signed engine bundle from ${tar_url}..."
    if ! curl -fsSL -o "${tmp_dir}/engine.tar.gz" "$tar_url"; then
        rm -rf "$tmp_dir"
        return 1
    fi
    if curl -fsSL -o "${tmp_dir}/engine.sha256" "$sha_url" 2>/dev/null; then
        expected_sha="$(awk '{print $1; exit}' "${tmp_dir}/engine.sha256")"
        if command -v sha256sum >/dev/null 2>&1; then
            actual_sha="$(sha256sum "${tmp_dir}/engine.tar.gz" | awk '{print $1}')"
        else
            actual_sha="$(shasum -a 256 "${tmp_dir}/engine.tar.gz" | awk '{print $1}')"
        fi
        if [[ -z "$expected_sha" || "$actual_sha" != "$expected_sha" ]]; then
            rm -rf "$tmp_dir"
            log_fatal "SHA-256 mismatch on ${tar_url} (expected ${expected_sha:-<empty>}, got ${actual_sha})"
        fi
    fi

    stage_dir="${SYS_ROOT}/.engine.stage.$$"
    rm -rf "$stage_dir"
    mkdir -p "$stage_dir"
    tar -xzf "${tmp_dir}/engine.tar.gz" -C "$stage_dir"
    rm -rf "$ENGINE_DIR"
    mv "$stage_dir" "$ENGINE_DIR"
    rm -rf "$tmp_dir"
    return 0
}

SYNCED="false"
if [[ -d "${ENGINE_DIR}/.git" ]]; then
    log_info "Updating AdaLovespace engine in ${ENGINE_DIR} (${REPO_BRANCH})..."
    if GIT_TERMINAL_PROMPT=0 git -C "$ENGINE_DIR" fetch origin "$REPO_BRANCH" -q 2>/dev/null; then
        git -C "$ENGINE_DIR" reset --hard "origin/${REPO_BRANCH}" -q
        SYNCED="true"
    elif [[ "$REAL_USER" != "root" ]] && sudo -u "$REAL_USER" env GIT_TERMINAL_PROMPT=0 git -C "$ENGINE_DIR" fetch origin "$REPO_BRANCH" -q 2>/dev/null; then
        sudo -u "$REAL_USER" git -C "$ENGINE_DIR" reset --hard "origin/${REPO_BRANCH}" -q
        chown -R root:root "$ENGINE_DIR"
        SYNCED="true"
    fi
fi

if [[ "$SYNCED" != "true" ]]; then
    STAGE_CLONE="${SYS_ROOT}/.engine.clone.$$"
    rm -rf "$STAGE_CLONE"
    log_info "Staging AdaLovespace engine into ${ENGINE_DIR}..."
    if GIT_TERMINAL_PROMPT=0 git clone --branch "$REPO_BRANCH" "$REPO_URL" "$STAGE_CLONE" -q 2>/dev/null; then
        rm -rf "$ENGINE_DIR"
        mv "$STAGE_CLONE" "$ENGINE_DIR"
        SYNCED="true"
    elif [[ "$REAL_USER" != "root" && -d "${REAL_HOME}/.ssh" ]] && \
         sudo -u "$REAL_USER" install -d -m 0755 "$STAGE_CLONE" 2>/dev/null && \
         sudo -u "$REAL_USER" env GIT_TERMINAL_PROMPT=0 GIT_SSH_COMMAND="ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new" \
             git clone --branch "$REPO_BRANCH" "$SSH_REPO_URL" "$STAGE_CLONE" -q 2>/dev/null; then
        chown -R root:root "$STAGE_CLONE"
        rm -rf "$ENGINE_DIR"
        mv "$STAGE_CLONE" "$ENGINE_DIR"
        SYNCED="true"
    else
        rm -rf "$STAGE_CLONE"
        if fetch_pages_tarball; then
            SYNCED="true"
        fi
    fi
fi

if [[ "$SYNCED" != "true" ]]; then
    log_fatal "Unable to download AdaLovespace engine from ${REPO_URL} or ${PAGES_BASE_URL}/engine.tar.gz"
fi

find "$ENGINE_DIR" -type f \( -name '*.sh' -o -name '*.py' \) -exec chmod +x {} + 2>/dev/null || true

# 3. Link /usr/local/bin/ada (+ /usr/bin/ada on Linux for Debian sudo secure_path)
install -d -m 0755 /usr/local/bin
ln -sf "${ENGINE_DIR}/forge.sh" /usr/local/bin/ada
if [[ "$(uname -s)" == "Linux" && -d /usr/bin ]]; then
    ln -sf "${ENGINE_DIR}/forge.sh" /usr/bin/ada
fi

COMMIT_SHA="bundle"
if [[ -d "${ENGINE_DIR}/.git" ]]; then
    COMMIT_SHA="$(git -C "$ENGINE_DIR" rev-parse --short HEAD 2>/dev/null || echo "main")"
elif [[ -f "${ENGINE_DIR}/VERSION" ]]; then
    COMMIT_SHA="$(head -n1 "${ENGINE_DIR}/VERSION" | tr -d '[:space:]')"
fi

log_ok "Linked /usr/local/bin/ada -> ${ENGINE_DIR}/forge.sh (${COMMIT_SHA})"

if [[ "$QUIET_MODE" == "false" ]]; then
    DT_MODEL="Unknown"
    if [[ -r /proc/device-tree/model ]]; then
        DT_MODEL="$(tr -d '\0' < /proc/device-tree/model 2>/dev/null || echo "Unknown")"
    elif [[ "$(uname -s)" == "Darwin" ]]; then
        DT_MODEL="$(sysctl -n machdep.cpu.brand_string 2>/dev/null || uname -m) (macOS Host)"
    fi

    OS_PRETTY="Unknown"
    if [[ -f /etc/os-release ]]; then
        OS_PRETTY="$(. /etc/os-release 2>/dev/null && echo "${PRETTY_NAME:-Unknown}" || echo "Unknown")"
    fi

    cat <<EOF

======================================================================
 DREW-V Labs // AdaLovespace CLI Installed (${COMMIT_SHA})
   Board  : ${DT_MODEL}
   OS     : ${OS_PRETTY}
   Engine : ${ENGINE_DIR}
   Spec   : ${USER_ADA_DIR}/node.env

 Quickstart:
   sudo ada init                # Generate ~/.adalovespace/node.env for this node
   \$EDITOR ~/.adalovespace/node.env
   sudo ada forge               # Converge node according to ~/.adalovespace/node.env
   sudo ada ort                 # Run Day-0 Operational Readiness Test & provenance check
   sudo ada status              # Inspect active cgroup v2 slices, services & TCP ports
   sudo ada verify              # Run 2-pass convergence + [SKIP] idempotency harness
   sudo ada update              # Pull latest AdaLovespace (+ RVDK on riscv64) engine
======================================================================
EOF
fi
