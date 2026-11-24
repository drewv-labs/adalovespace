#!/usr/bin/env bash
# ==============================================================================
# DREW-V Labs // Decoupled Headless `Xvfb` + `PHD2` Builder (`guiding.slice`)
# Path: adalovespace/src/adastak/adascope/nodes/adactrl/phd2/build.sh
#
# Description:
#   1. Installs `xvfb` and compiles `OpenPHDGuiding/phd2` (`-DOPENSOURCE_ONLY=1`)
#      against in-place `libindi` without clobbering source-built INDI 2.1.9.
#   2. Seeds `~/.PHDGuidingV2` (`ServerMode=1` on `:4400` -> `127.0.0.1:7624`).
#   3. Deploys decoupled `xvfb-guiding.service` and `phd2.service` (`Nice=-10`,
#      `OOMScoreAdjust=-500`, strictly `SCHED_OTHER` / `CLS=TS`) in `guiding.slice`.
# ==============================================================================
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ADA_ENGINE_ROOT="${ADA_ENGINE_ROOT:-$(cd "${SCRIPT_DIR}/../../../../../.." && pwd)}"
# shellcheck source=../../../../../../lib/common.sh
source "${ADA_ENGINE_ROOT}/lib/common.sh"

ADMIN_USER="${ADMIN_USER:?ADMIN_USER required}"
ADMIN_GRP="$(id -gn "$ADMIN_USER" 2>/dev/null || echo "$ADMIN_USER")"
ADMIN_HOME="$(ada_user_home "$ADMIN_USER")"

INDI_PORT="${INDI_PORT:-7624}"
PHD2_PORT="${PHD2_PORT:-4400}"
PHD2_DISPLAY="${PHD2_DISPLAY:-:99}"
PHD2_SCREEN_GEOM="${PHD2_SCREEN_GEOM:-1280x800x24}"
PHD2_INDI_HOST="${PHD2_INDI_HOST:-127.0.0.1}"
PHD2_INDI_CAMERA="${PHD2_INDI_CAMERA:-ZWO CCD ASI220MM Mini}"
PHD2_INDI_MOUNT="${PHD2_INDI_MOUNT:-ZWO AM5 USB}"
PHD2_PIXEL_SIZE_UM="${PHD2_PIXEL_SIZE_UM:-4.0}"
PHD2_FOCAL_LENGTH_MM="${PHD2_FOCAL_LENGTH_MM:-300}"
PHD2_GIT_REF="${PHD2_GIT_REF:-master}"

SRC_CACHE="/var/cache/adalovespace/src"
PHD2_BIN="/usr/local/bin/phd2"

export DEBIAN_FRONTEND=noninteractive
APT_FLAGS=(-y -o DPkg::Lock::Timeout=120 -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold")

# ------------------------------------------------------------------------------
# 1. Install `xvfb` & Compile `OpenPHDGuiding/phd2` (Native — Zero Flatpak/Snap)
# ------------------------------------------------------------------------------
if [[ -x /usr/bin/Xvfb ]]; then
    log_skip "Xvfb binary already installed (/usr/bin/Xvfb)"
else
    log_info "Installing xvfb via apt-get..."
    if [[ "${ADA_NO_APT_UPDATE:-false}" != "true" ]]; then
        apt-get -o DPkg::Lock::Timeout=120 update -q
        export ADA_NO_APT_UPDATE="true"
    fi
    apt-get "${APT_FLAGS[@]}" install xvfb xauth
    log_ok "Installed /usr/bin/Xvfb"
fi

if [[ -x "$PHD2_BIN" && "${ADA_REBUILD_PHD2:-false}" != "true" ]]; then
    log_skip "PHD2 binary already installed (${PHD2_BIN})"
else
    log_info "Installing PHD2 C++ build dependencies (preserving existing libindi)..."
    if [[ "${ADA_NO_APT_UPDATE:-false}" != "true" ]]; then
        apt-get -o DPkg::Lock::Timeout=120 update -q
        export ADA_NO_APT_UPDATE="true"
    fi

    PHD2_DEPS=(
        build-essential
        cmake
        git
        pkg-config
        gettext
        zlib1g-dev
        libwxgtk3.2-dev
        wx-common
        wx3.2-i18n
        libx11-dev
        libcurl4-gnutls-dev
        libeigen3-dev
        libcfitsio-dev
        libnova-dev
        libopencv-dev
        libusb-1.0-0-dev
    )
    # Guardrail: NEVER install Debian `libindi-dev` (1.9.9) if source-built `libindi` (>= 2.0) is already present!
    if ! pkg-config --exists libindi 2>/dev/null && [[ ! -d /usr/include/libindi ]]; then
        PHD2_DEPS+=(libindi-dev)
    else
        log_info "Detected existing libindi ($(pkg-config --modversion libindi 2>/dev/null || echo 'custom')); skipping apt libindi-dev to protect INDI 2.x"
    fi

    apt-get "${APT_FLAGS[@]}" install "${PHD2_DEPS[@]}"

    mkdir -p "$SRC_CACHE"
    JOBS="$(nproc 2>/dev/null || echo 4)"
    log_info "Cloning & compiling OpenPHDGuiding/phd2 (${PHD2_GIT_REF}, -j${JOBS}) -> /usr/local..."
    rm -rf "${SRC_CACHE}/phd2"
    git clone --depth 1 --branch "$PHD2_GIT_REF" https://github.com/OpenPHDGuiding/phd2.git "${SRC_CACHE}/phd2"
    cmake -S "${SRC_CACHE}/phd2" -B "${SRC_CACHE}/phd2/build" \
        -DOPENSOURCE_ONLY=1 \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr/local
    cmake --build "${SRC_CACHE}/phd2/build" -j "$JOBS"
    cmake --install "${SRC_CACHE}/phd2/build"
    ldconfig
    log_ok "Compiled and installed PHD2 at ${PHD2_BIN}"
fi

# ------------------------------------------------------------------------------
# 2. Seed `~/.PHDGuidingV2` (`ServerMode=1` on `:4400` -> `127.0.0.1:7624`)
# ------------------------------------------------------------------------------
python3 "${SCRIPT_DIR}/seed_phd2_config.py" \
    --user "$ADMIN_USER" \
    --profile-name "AdaScope-8F4" \
    --indi-host "$PHD2_INDI_HOST" \
    --indi-port "$INDI_PORT" \
    --indi-camera "$PHD2_INDI_CAMERA" \
    --indi-mount "$PHD2_INDI_MOUNT" \
    --pixel-size-um "$PHD2_PIXEL_SIZE_UM" \
    --focal-length-mm "$PHD2_FOCAL_LENGTH_MM"

# ------------------------------------------------------------------------------
# 3. Converge Decoupled `xvfb-guiding.service` & `phd2.service` (`guiding.slice`)
# ------------------------------------------------------------------------------
XVFB_CHANGED="false"
if ada_write_if_changed "/etc/systemd/system/xvfb-guiding.service" 0644 <<EOF
# Managed by AdaLovespace (ada forge) — Dedicated Xvfb Display for Headless PHD2
[Unit]
Description=AdaLovespace Headless Guiding Virtual Framebuffer (${PHD2_DISPLAY})
After=network.target

[Service]
Type=simple
Slice=guiding.slice
User=${ADMIN_USER}
Group=${ADMIN_GRP}
ExecStart=/usr/bin/Xvfb ${PHD2_DISPLAY} -screen 0 ${PHD2_SCREEN_GEOM} -nolisten tcp
Restart=always
RestartSec=2

[Install]
WantedBy=multi-user.target
EOF
then
    XVFB_CHANGED="true"
    log_ok "Wrote /etc/systemd/system/xvfb-guiding.service"
else
    log_skip "xvfb-guiding.service unit file already converged"
fi

PHD2_CHANGED="false"
if ada_write_if_changed "/etc/systemd/system/phd2.service" 0644 <<EOF
# Managed by AdaLovespace (ada forge) — Headless PHD2 Autoguiding Engine (:4400)
# Strictly SCHED_OTHER (TS) with Nice=-10 (no SCHED_RR/SCHED_FIFO to prevent USB spin-locks)
[Unit]
Description=AdaLovespace Headless PHD2 Guiding Server (:${PHD2_PORT} -> ${PHD2_INDI_HOST}:${INDI_PORT})
Requires=xvfb-guiding.service
After=xvfb-guiding.service indiwebmanager.service

[Service]
Type=simple
Slice=guiding.slice
User=${ADMIN_USER}
Group=${ADMIN_GRP}
WorkingDirectory=${ADMIN_HOME}
Environment=HOME=${ADMIN_HOME}
Environment=DISPLAY=${PHD2_DISPLAY}
Environment=WXSUPPRESS_SIZER_FLAGS_CHECK=1
Nice=-10
OOMScoreAdjust=-500
ExecStart=${PHD2_BIN}
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF
then
    PHD2_CHANGED="true"
    log_ok "Wrote /etc/systemd/system/phd2.service"
else
    log_skip "phd2.service unit file already converged"
fi

if [[ "$XVFB_CHANGED" == "true" || "$PHD2_CHANGED" == "true" ]]; then
    systemctl daemon-reload
fi

if [[ "$XVFB_CHANGED" == "true" ]] || ! systemctl is-active --quiet xvfb-guiding.service 2>/dev/null; then
    systemctl enable xvfb-guiding.service >/dev/null 2>&1 || true
    systemctl restart xvfb-guiding.service
    log_ok "Started xvfb-guiding.service in guiding.slice"
else
    log_skip "xvfb-guiding.service active in guiding.slice"
fi

# Wait up to 5 seconds for X11 Unix domain socket (`/tmp/.X11-unix/X99`) before launching PHD2
DISP_NUM="${PHD2_DISPLAY#:}"
for _ in {1..25}; do
    [[ -S "/tmp/.X11-unix/X${DISP_NUM}" ]] && break
    sleep 0.2
done

if [[ "$PHD2_CHANGED" == "true" || "$XVFB_CHANGED" == "true" ]] || ! systemctl is-active --quiet phd2.service 2>/dev/null; then
    systemctl enable phd2.service >/dev/null 2>&1 || true
    systemctl restart phd2.service
    log_ok "Started phd2.service in guiding.slice (:${PHD2_PORT})"
else
    log_skip "phd2.service active in guiding.slice"
fi
