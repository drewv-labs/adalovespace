#!/usr/bin/env bash
# ==============================================================================
# DREW-V Labs // Declarative systemd Cgroup v2 Core Partitioning (`lib/cgroups.sh`)
# Path: adalovespace/lib/cgroups.sh
#
# Description:
#   Applies RP1- & PLIC-aware systemd cgroup v2 CPU-mask partitioning and memory
#   envelopes across `AdaCtrl-RPI5` (4-core BCM2712) and `AdaCtrl-RV2` (8-core
#   SpacemiT Ky X1) without legacy `isolcpus=` or PID 1 `CPUAffinity=` traps.
# ==============================================================================

[[ -n "${_ADA_CGROUPS_SH_LOADED:-}" ]] && return 0
_ADA_CGROUPS_SH_LOADED=1

# Ensure kernel boot parameters enable `cpuset` and `memory` cgroup controllers
# and strictly forbid `isolcpus=`. Sets ADA_REBOOT_REQUIRED="true" if live
# `/sys/fs/cgroup/cgroup.controllers` does not yet expose `cpuset` + `memory`.
ada_converge_cgroup_boot_cmdline() {
    local boot_mode="${CGROUP_BOOT_MODE:-rpi-cmdline}"
    local cmdline_file="${CGROUP_CMDLINE_FILE:-/boot/firmware/cmdline.txt}"
    local backup_dir="/var/lib/adalovespace/backups"

    export ADA_REBOOT_REQUIRED="${ADA_REBOOT_REQUIRED:-false}"

    if [[ -r /proc/cmdline ]] && grep -qw 'isolcpus' /proc/cmdline; then
        log_fatal "Legacy 'isolcpus=' detected in /proc/cmdline ($(cat /proc/cmdline)). Remove 'isolcpus=' to allow cgroup v2 AllowedCPUs partitioning."
    fi

    # Guard against PID 1 CPUAffinity inheritance overriding child slices
    local conf_f
    for conf_f in /etc/systemd/system.conf /etc/systemd/system.conf.d/*.conf; do
        [[ -f "$conf_f" ]] || continue
        if grep -Eq '^[[:space:]]*CPUAffinity[[:space:]]*=' "$conf_f"; then
            log_fatal "Active 'CPUAffinity=' found in ${conf_f}. Remove PID 1 CPUAffinity so child cgroup v2 slices control AllowedCPUs."
        fi
    done

    case "$boot_mode" in
        rpi-cmdline)
            if [[ ! -f "$cmdline_file" && -f /boot/cmdline.txt ]]; then
                cmdline_file="/boot/cmdline.txt"
            fi
            if [[ ! -f "$cmdline_file" ]]; then
                log_fatal "Expected Raspberry Pi kernel cmdline file not found at ${cmdline_file}"
            fi

            local current_line updated_line tok
            # Enforce single-line invariant on Raspberry Pi cmdline.txt
            current_line="$(tr '\n\r' '  ' < "$cmdline_file" | sed -E 's/[[:space:]]+/ /g; s/^ //; s/ $//')"

            if grep -Eq '(^|[[:space:]])isolcpus=' <<< "$current_line"; then
                log_fatal "Refusing to proceed: 'isolcpus=' present in ${cmdline_file}. Remove 'isolcpus=' first."
            fi

            updated_line="$current_line"
            for tok in "cgroup_enable=cpuset" "cgroup_enable=memory" "cgroup_memory=1"; do
                if ! grep -Eq "(^|[[:space:]])${tok}([[:space:]]|$)" <<< "$updated_line"; then
                    updated_line="${updated_line} ${tok}"
                fi
            done

            if [[ "$updated_line" != "$current_line" ]]; then
                mkdir -p "$backup_dir"
                if [[ ! -f "${backup_dir}/cmdline.txt.orig" ]]; then
                    cp -a "$cmdline_file" "${backup_dir}/cmdline.txt.orig"
                fi
                printf '%s\n' "$updated_line" | ada_atomic_write "$cmdline_file" 0644
                ADA_REBOOT_REQUIRED="true"
                log_ok "Updated ${cmdline_file} with cgroup v2 controllers (reboot required to activate)"
            else
                log_skip "Boot cmdline already includes cgroup v2 controllers (${cmdline_file})"
            fi
            ;;
        uboot-env)
            # Stub / Orange Pi RV2 (`spacemit-k1` `/boot/orangepiEnv.txt` `extraargs=`)
            if [[ -f "$cmdline_file" ]]; then
                local req_args="cgroup_enable=cpuset cgroup_enable=memory cgroup_memory=1"
                if grep -q '^extraargs=' "$cmdline_file"; then
                    local cur_extra new_extra t
                    cur_extra="$(grep '^extraargs=' "$cmdline_file" | head -n1 | cut -d= -f2-)"
                    new_extra="$cur_extra"
                    for t in $req_args; do
                        if ! grep -Eq "(^|[[:space:]])${t}([[:space:]]|$)" <<< "$new_extra"; then
                            new_extra="${new_extra:+${new_extra} }${t}"
                        fi
                    done
                    if [[ "$new_extra" != "$cur_extra" ]]; then
                        mkdir -p "$backup_dir"
                        [[ -f "${backup_dir}/orangepiEnv.txt.orig" ]] || cp -a "$cmdline_file" "${backup_dir}/orangepiEnv.txt.orig"
                        sed -E "s|^extraargs=.*$|extraargs=${new_extra}|" "$cmdline_file" | ada_atomic_write "$cmdline_file" 0644
                        ADA_REBOOT_REQUIRED="true"
                        log_ok "Updated ${cmdline_file} extraargs with cgroup v2 controllers"
                    else
                        log_skip "U-Boot ${cmdline_file} extraargs already converged"
                    fi
                else
                    mkdir -p "$backup_dir"
                    [[ -f "${backup_dir}/orangepiEnv.txt.orig" ]] || cp -a "$cmdline_file" "${backup_dir}/orangepiEnv.txt.orig"
                    {
                        cat "$cmdline_file"
                        printf 'extraargs=%s\n' "$req_args"
                    } | ada_atomic_write "$cmdline_file" 0644
                    ADA_REBOOT_REQUIRED="true"
                    log_ok "Appended extraargs cgroup v2 controllers to ${cmdline_file}"
                fi
            else
                log_skip "U-Boot env file ${cmdline_file} not present on this rootfs; relying on kernel default cgroup v2 controllers"
            fi
            ;;
        none|*)
            log_skip "Boot cmdline mutation skipped for CGROUP_BOOT_MODE=${boot_mode}"
            ;;
    esac

    local controllers=""
    if [[ -r /sys/fs/cgroup/cgroup.controllers ]]; then
        controllers="$(cat /sys/fs/cgroup/cgroup.controllers)"
    fi
    if ! grep -qw 'cpuset' <<< "$controllers" || ! grep -qw 'memory' <<< "$controllers"; then
        ADA_REBOOT_REQUIRED="true"
        log_warn "Live /sys/fs/cgroup/cgroup.controllers is '${controllers}'; reboot node after forge to activate 'cpuset' + 'memory' controllers."
    fi
    export ADA_REBOOT_REQUIRED
}

# Render and converge all AdaCtrl cgroup v2 slices and service drop-ins
ada_converge_cgroup_slices() {
    local sys_cpus="${SLICE_SYSTEM_CPUS:?SLICE_SYSTEM_CPUS required}"
    local usr_cpus="${SLICE_USER_CPUS:?SLICE_USER_CPUS required}"
    local obs_cpus="${SLICE_OBSERVABILITY_CPUS:?SLICE_OBSERVABILITY_CPUS required}"
    local indi_cpus="${SLICE_INDI_CPUS:?SLICE_INDI_CPUS required}"
    local guide_cpus="${SLICE_GUIDING_CPUS:?SLICE_GUIDING_CPUS required}"
    local inf_cpus="${SLICE_INFERENCE_CPUS:-}"

    local systemd_dirty="false"
    local pigeoneer_dirty="false"
    local indi_dirty="false"

    # 1. system.slice & user.slice AllowedCPUs drop-ins (pins RP1 IRQ sink, SSH & housekeeping)
    if ada_write_if_changed "/etc/systemd/system/system.slice.d/10-ada-cpuset.conf" 0644 <<EOF
# Managed by AdaLovespace (ada forge) — Do not edit manually
[Slice]
AllowedCPUs=${sys_cpus}
EOF
    then
        systemd_dirty="true"
        log_ok "Converged system.slice AllowedCPUs=${sys_cpus}"
    else
        log_skip "system.slice AllowedCPUs=${sys_cpus} already converged"
    fi

    if ada_write_if_changed "/etc/systemd/system/user.slice.d/10-ada-cpuset.conf" 0644 <<EOF
# Managed by AdaLovespace (ada forge) — Do not edit manually
[Slice]
AllowedCPUs=${usr_cpus}
EOF
    then
        systemd_dirty="true"
        log_ok "Converged user.slice AllowedCPUs=${usr_cpus}"
    else
        log_skip "user.slice AllowedCPUs=${usr_cpus} already converged"
    fi

    # 2. observability.slice + pigeoneer.service drop-in
    if ada_write_if_changed "/etc/systemd/system/observability.slice" 0644 <<EOF
# Managed by AdaLovespace (ada forge) — CarrierPigeons Edge Telemetry Slice
[Unit]
Description=AdaLovespace Observability Slice (CarrierPigeons Telemetry)
Before=slices.target

[Slice]
AllowedCPUs=${obs_cpus}
CPUWeight=50
CPUAccounting=yes
MemoryAccounting=yes
EOF
    then
        systemd_dirty="true"
        pigeoneer_dirty="true"
        log_ok "Converged observability.slice (AllowedCPUs=${obs_cpus})"
    else
        log_skip "observability.slice already converged"
    fi

    if ada_write_if_changed "/etc/systemd/system/pigeoneer.service.d/10-ada-observability.conf" 0644 <<EOF
# Managed by AdaLovespace (ada forge) — Bound pigeoneer into observability.slice
[Service]
Slice=observability.slice
CPUWeight=50
CPUQuota=15%
Nice=10
MemoryHigh=192M
MemoryMax=256M
EOF
    then
        systemd_dirty="true"
        pigeoneer_dirty="true"
        log_ok "Converged pigeoneer.service drop-in (observability.slice, CPUQuota=15%, Nice=10, MemoryMax=256M)"
    else
        log_skip "pigeoneer.service drop-in already converged"
    fi

    # 3. indi.slice + indiwebmanager.service drop-in (inherited by indiserver + drivers)
    if ada_write_if_changed "/etc/systemd/system/indi.slice" 0644 <<EOF
# Managed by AdaLovespace (ada forge) — INDI Server & Hardware Drivers Slice
[Unit]
Description=AdaLovespace INDI Device & Imaging Slice
Before=slices.target

[Slice]
AllowedCPUs=${indi_cpus}
CPUWeight=500
CPUAccounting=yes
MemoryAccounting=yes
EOF
    then
        systemd_dirty="true"
        indi_dirty="true"
        log_ok "Converged indi.slice (AllowedCPUs=${indi_cpus})"
    else
        log_skip "indi.slice already converged"
    fi

    if ada_write_if_changed "/etc/systemd/system/indiwebmanager.service.d/10-ada-indi.conf" 0644 <<EOF
# Managed by AdaLovespace (ada forge) — Inherited by indiserver + indi_* drivers
[Service]
Slice=indi.slice
CPUWeight=500
MemoryHigh=2G
MemoryMax=3G
OOMScoreAdjust=-200
EOF
    then
        systemd_dirty="true"
        indi_dirty="true"
        log_ok "Converged indiwebmanager.service drop-in (indi.slice, CPUWeight=500, MemoryHigh=2G, MemoryMax=3G, OOMScoreAdjust=-200)"
    else
        log_skip "indiwebmanager.service drop-in already converged"
    fi

    # 4. guiding.slice (Xvfb + PHD2 dedicated core & memory protection)
    if ada_write_if_changed "/etc/systemd/system/guiding.slice" 0644 <<EOF
# Managed by AdaLovespace (ada forge) — Dedicated Headless PHD2 Autoguiding Slice
[Unit]
Description=AdaLovespace Real-Time Centroid Guiding Slice (Xvfb + PHD2)
Before=slices.target

[Slice]
AllowedCPUs=${guide_cpus}
CPUWeight=1000
MemoryLow=512M
MemoryHigh=1G
CPUAccounting=yes
MemoryAccounting=yes
EOF
    then
        systemd_dirty="true"
        log_ok "Converged guiding.slice (AllowedCPUs=${guide_cpus}, CPUWeight=1000, MemoryLow=512M, MemoryHigh=1G)"
    else
        log_skip "guiding.slice already converged"
    fi

    # 5. inference.slice (stub on 4-core RPi5; active AllowedCPUs=6-7 on 8-core RV2 / ALOne-V Air)
    local inf_directive="# AllowedCPUs reserved for 8-core AdaCtrl-RV2 / ALOne-V Air (Hailo-10H)"
    if [[ -n "$inf_cpus" ]]; then
        inf_directive="AllowedCPUs=${inf_cpus}"
    fi
    if ada_write_if_changed "/etc/systemd/system/inference.slice" 0644 <<EOF
# Managed by AdaLovespace (ada forge) — Edge NPU Inference Slice Stub (ALOne-V Air / Hailo-10H)
[Unit]
Description=AdaLovespace Edge NPU Inference Slice (Reserved for ALOne-V Air / Hailo-10H)
Before=slices.target

[Slice]
${inf_directive}
CPUAccounting=yes
MemoryAccounting=yes
EOF
    then
        systemd_dirty="true"
        log_ok "Converged inference.slice (${inf_cpus:-stub})"
    else
        log_skip "inference.slice (${inf_cpus:-stub}) already converged"
    fi

    if [[ "$systemd_dirty" == "true" ]]; then
        systemctl daemon-reload
        systemctl start observability.slice indi.slice guiding.slice 2>/dev/null || true
    fi

    # Ensure live pigeoneer.service moves into observability.slice if running
    if systemctl list-unit-files pigeoneer.service >/dev/null 2>&1; then
        local cur_pig_slice=""
        cur_pig_slice="$(systemctl show -p Slice --value pigeoneer.service 2>/dev/null || true)"
        if [[ "$pigeoneer_dirty" == "true" || "$cur_pig_slice" != "observability.slice" ]]; then
            if systemctl is-active --quiet pigeoneer.service 2>/dev/null; then
                systemctl daemon-reload
                systemctl restart pigeoneer.service
                log_ok "Restarted pigeoneer.service into observability.slice"
            fi
        fi
    fi

    export ADA_INDI_SLICE_DIRTY="$indi_dirty"
}
