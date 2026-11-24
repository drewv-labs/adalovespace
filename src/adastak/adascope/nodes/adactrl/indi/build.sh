#!/usr/bin/env bash
# ==============================================================================
# DREW-V Labs // AdaCtrl INDI Core + ZWO ASI + `indiwebmanager` Builder
# Path: adalovespace/src/adastak/adascope/nodes/adactrl/indi/build.sh
#
# Description:
#   1. Preserves existing source-compiled INDI >= 2.0 (`indi_Excalibur`,
#      `indi_wanderer_rotator_mini`, `indi_lx200am5`, `indi_asi_*`), or compiles
#      `indilib/indi` + `indilib/indi-3rdparty` (`libasi`, `indi-asi`) on fresh nodes.
#   2. Provisions `/opt/adalovespace/indiweb/.venv` via Astral `uv` (`indiweb`).
#   3. Seeds `~/.indi/profiles.db` & missing `~/.indi/*_config.xml` safely.
#   4. Converges `indiwebmanager.service` (`Alias=indiweb.service`) inside `indi.slice`.
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
INDIWEB_PORT="${INDIWEB_PORT:-8624}"
INDI_RIG_PROFILE="${INDI_RIG_PROFILE:-Ada Lovespace Rig}"
ENABLE_ZWO_ASI="${ENABLE_ZWO_ASI:-true}"
INDI_GIT_REF="${INDI_GIT_REF:-v2.1.9}"
INDI_3RDPARTY_GIT_REF="${INDI_3RDPARTY_GIT_REF:-v2.1.9.1}"
SITE_LAT="${SITE_LAT:-32.78}"
SITE_LON="${SITE_LON:-263.20}"
SITE_ELEV="${SITE_ELEV:-130.0}"

SRC_CACHE="/var/cache/adalovespace/src"
INDIWEB_ROOT="/opt/adalovespace/indiweb"
INDIWEB_VENV="${INDIWEB_ROOT}/.venv"
INDIWEB_BIN="${INDIWEB_VENV}/bin/indi-web"

export DEBIAN_FRONTEND=noninteractive
APT_FLAGS=(-y -o DPkg::Lock::Timeout=120 -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold")

# ------------------------------------------------------------------------------
# 1. Check / Build INDI Server & Hardware Drivers
# ------------------------------------------------------------------------------
CORE_INDI_READY="false"
if command -v indiserver >/dev/null 2>&1 \
   && pkg-config --atleast-version=2.0 libindi 2>/dev/null \
   && [[ -x /usr/bin/indi_Excalibur ]] \
   && [[ -x /usr/bin/indi_wanderer_rotator_mini ]] \
   && [[ -e /usr/bin/indi_lx200am5 ]]; then
    CORE_INDI_READY="true"
fi

ZWO_ASI_READY="true"
if [[ "$ENABLE_ZWO_ASI" == "true" ]]; then
    if [[ ! -x /usr/bin/indi_asi_ccd || ! -x /usr/bin/indi_asi_wheel || ! -x /usr/bin/indi_asi_focuser ]]; then
        ZWO_ASI_READY="false"
    fi
fi

if [[ "${ADA_REBUILD_INDI:-false}" != "true" && "$CORE_INDI_READY" == "true" && "$ZWO_ASI_READY" == "true" ]]; then
    INDI_VER="$(pkg-config --modversion libindi 2>/dev/null || echo "2.x")"
    log_skip "INDI ${INDI_VER} + AdaScope-8F4 drivers already installed in /usr/bin"
else
    if [[ "$ENABLE_ZWO_ASI" == "true" && "$(uname -m)" == "riscv64" ]]; then
        log_fatal "ENABLE_ZWO_ASI=true requested on riscv64, but ZWO's closed-source libASICamera2 SDK in indi-3rdparty/libasi does not yet ship a riscv64 ELF binary. Set ENABLE_ZWO_ASI=\"false\" in ~/.adalovespace/node.env for riscv64 validation."
    fi

    log_info "Installing INDI C++ compilation dependencies..."
    if [[ "${ADA_NO_APT_UPDATE:-false}" != "true" ]]; then
        apt-get -o DPkg::Lock::Timeout=120 update -q
        export ADA_NO_APT_UPDATE="true"
    fi
    apt-get "${APT_FLAGS[@]}" install \
        build-essential cmake git pkg-config udev \
        zlib1g-dev libcfitsio-dev libnova-dev libusb-1.0-0-dev \
        libcurl4-gnutls-dev libgsl-dev libjpeg-dev libfftw3-dev \
        libftdi1-dev libgps-dev libraw-dev libdc1394-dev libev-dev \
        libtheora-dev libogg-dev

    mkdir -p "$SRC_CACHE"
    JOBS="$(nproc 2>/dev/null || echo 4)"

    if [[ "$CORE_INDI_READY" != "true" || "${ADA_REBUILD_INDI:-false}" == "true" ]]; then
        log_info "Compiling indilib/indi (${INDI_GIT_REF}) -> /usr..."
        rm -rf "${SRC_CACHE}/indi"
        git clone --depth 1 --branch "$INDI_GIT_REF" https://github.com/indilib/indi.git "${SRC_CACHE}/indi"
        cmake -S "${SRC_CACHE}/indi" -B "${SRC_CACHE}/indi/build" \
            -DCMAKE_INSTALL_PREFIX=/usr \
            -DCMAKE_BUILD_TYPE=Release \
            -DINDI_INSTALL_UDEV_RULES=ON \
            -DINDI_BUILD_UNITTESTS=OFF \
            -DINDI_BUILD_INTEGTESTS=OFF \
            -DINDI_BUILD_QT_CLIENT=OFF
        cmake --build "${SRC_CACHE}/indi/build" -j "$JOBS"
        cmake --install "${SRC_CACHE}/indi/build"
        ldconfig
        log_ok "Installed indilib/indi (${INDI_GIT_REF}) into /usr"
    fi

    if [[ "$ENABLE_ZWO_ASI" == "true" && ( "$ZWO_ASI_READY" != "true" || "${ADA_REBUILD_INDI:-false}" == "true" ) ]]; then
        log_info "Compiling indilib/indi-3rdparty libasi + indi-asi (${INDI_3RDPARTY_GIT_REF}) -> /usr..."
        rm -rf "${SRC_CACHE}/indi-3rdparty"
        git clone --depth 1 --branch "$INDI_3RDPARTY_GIT_REF" https://github.com/indilib/indi-3rdparty.git "${SRC_CACHE}/indi-3rdparty"

        cmake -S "${SRC_CACHE}/indi-3rdparty/libasi" -B "${SRC_CACHE}/indi-3rdparty/build-libasi" \
            -DCMAKE_INSTALL_PREFIX=/usr \
            -DCMAKE_BUILD_TYPE=Release
        cmake --build "${SRC_CACHE}/indi-3rdparty/build-libasi" -j "$JOBS"
        cmake --install "${SRC_CACHE}/indi-3rdparty/build-libasi"
        ldconfig

        cmake -S "${SRC_CACHE}/indi-3rdparty/indi-asi" -B "${SRC_CACHE}/indi-3rdparty/build-indi-asi" \
            -DCMAKE_INSTALL_PREFIX=/usr \
            -DCMAKE_BUILD_TYPE=Release
        cmake --build "${SRC_CACHE}/indi-3rdparty/build-indi-asi" -j "$JOBS"
        cmake --install "${SRC_CACHE}/indi-3rdparty/build-indi-asi"
        ldconfig
        udevadm control --reload-rules 2>/dev/null || true
        udevadm trigger 2>/dev/null || true
        log_ok "Installed ZWO ASI SDK (libasi) + indi-asi drivers"
    fi
fi

# ------------------------------------------------------------------------------
# 2. Provision Isolated `indiweb` Environment via Astral `uv`
# ------------------------------------------------------------------------------
UV_BIN="/usr/local/bin/uv"
if ! command -v uv >/dev/null 2>&1 && [[ ! -x "$UV_BIN" ]]; then
    log_info "Installing Astral uv -> /usr/local/bin/uv..."
    curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR="/usr/local/bin" sh
fi
UV_BIN="$(command -v uv || echo /usr/local/bin/uv)"

if [[ -x "$INDIWEB_BIN" ]]; then
    log_skip "indi-web venv already provisioned at ${INDIWEB_VENV}"
else
    log_info "Provisioning indiweb Python environment via uv at ${INDIWEB_VENV}..."
    install -d -m 0755 -o "$ADMIN_USER" -g "$ADMIN_GRP" "$INDIWEB_ROOT"
    sudo -u "$ADMIN_USER" "$UV_BIN" venv "$INDIWEB_VENV"
    sudo -u "$ADMIN_USER" "$UV_BIN" pip install --python "${INDIWEB_VENV}/bin/python" indiweb
    log_ok "Installed indiweb in ${INDIWEB_VENV}"
fi

# ------------------------------------------------------------------------------
# 3. Seed `~/.indi/profiles.db` & Missing Device XML Templates
# ------------------------------------------------------------------------------
SEED_ARGS=(
    --user "$ADMIN_USER"
    --profile-name "$INDI_RIG_PROFILE"
    --indi-port "$INDI_PORT"
    --site-lat "$SITE_LAT"
    --site-lon "$SITE_LON"
    --site-elev "$SITE_ELEV"
)
[[ "$ENABLE_ZWO_ASI" == "true" ]] && SEED_ARGS+=(--include-zwo)
[[ "${ADA_RESET_INDI_CONFIGS:-false}" == "true" ]] && SEED_ARGS+=(--reset-configs)

python3 "${SCRIPT_DIR}/seed_rig_profile.py" "${SEED_ARGS[@]}"

# ------------------------------------------------------------------------------
# 4. Migrate Legacy `indiweb.service` & Converge `indiwebmanager.service`
# ------------------------------------------------------------------------------
LEGACY_MIGRATED="false"
if [[ -f /etc/systemd/system/indiweb.service && ! -L /etc/systemd/system/indiweb.service ]]; then
    log_info "Migrating legacy standalone indiweb.service -> indiwebmanager.service..."
    systemctl stop indiweb.service 2>/dev/null || true
    systemctl disable indiweb.service 2>/dev/null || true
    rm -f /etc/systemd/system/indiweb.service
    # Reap any detached indiserver processes spawned under legacy unit so they respawn inside indi.slice
    pkill -x indiserver 2>/dev/null || true
    rm -f /tmp/indiFIFO /tmp/indiFIFO_sock 2>/dev/null || true
    LEGACY_MIGRATED="true"
fi

UNIT_CHANGED="false"
if ada_write_if_changed "/etc/systemd/system/indiwebmanager.service" 0644 <<EOF
# Managed by AdaLovespace (ada forge) — INDI Web Manager + indiserver Supervisor
[Unit]
Description=AdaLovespace INDI Web Manager (:${INDIWEB_PORT} -> indiserver :${INDI_PORT})
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=${ADMIN_USER}
Group=${ADMIN_GRP}
WorkingDirectory=${ADMIN_HOME}
Environment="HOME=${ADMIN_HOME}"
Environment="PATH=${INDIWEB_VENV}/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
ExecStart=${INDIWEB_BIN} -v -p ${INDIWEB_PORT}
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
Alias=indiweb.service
EOF
then
    UNIT_CHANGED="true"
    log_ok "Wrote /etc/systemd/system/indiwebmanager.service (Alias=indiweb.service)"
else
    log_skip "indiwebmanager.service unit file already converged"
fi

CUR_INDI_SLICE="$(systemctl show -p Slice --value indiwebmanager.service 2>/dev/null || true)"
if [[ "$UNIT_CHANGED" == "true" || "$LEGACY_MIGRATED" == "true" || "${ADA_INDI_SLICE_DIRTY:-false}" == "true" ]]; then
    systemctl daemon-reload
    systemctl enable indiwebmanager.service >/dev/null 2>&1 || true
    pkill -x indiserver 2>/dev/null || true
    rm -f /tmp/indiFIFO /tmp/indiFIFO_sock 2>/dev/null || true
    systemctl restart indiwebmanager.service
    log_ok "Started indiwebmanager.service inside ${CUR_INDI_SLICE:-indi.slice}"
elif ! systemctl is-active --quiet indiwebmanager.service 2>/dev/null; then
    systemctl daemon-reload
    systemctl enable --now indiwebmanager.service
    log_ok "Enabled & started indiwebmanager.service"
else
    log_skip "indiwebmanager.service active and converged in ${CUR_INDI_SLICE}"
fi
