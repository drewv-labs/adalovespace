# AdaLovespace (`adalovespace`) — Workspace Context & Edge Astro Compute Standards

## 1. Repository Scope & Ecosystem Layering
`AdaLovespace` (`adalovespace/`) is the declarative provisioning engine, systemd cgroup v2 real-time core partitioning layer, and Day-0 Operational Readiness Test (ORT) harness for the `AdaStak` distributed astrophotography & edge ML cluster (`AdaScope` on-OTA controllers + `AdaRak` field rack nodes).

- **One-Way Layering on `RVDK` & `CarrierPigeons`:**
  - On `riscv64` targets (`AdaCtrl-RV2`, `JakeBase-VF2`, `CarolineV-VF2`, `ALOne-V Air`, `ALOne-V Pro`), low-level OS normalization, BSP hardening, `4Kn` NVMe + LVM, PostgreSQL 18.6 (`io_uring`), Mosquitto, NFS-Ganesha, and silicon `deeptune` delegate strictly to [`riscv-data-kit`](https://github.com/drewv-labs/riscv-data-kit) (`/usr/local/bin/rvdk`).
  - Telemetry and Continuous Telemetric Documentation (CTD) delegate to [`CarrierPigeons`](https://github.com/drewv-labs/carrierpigeons) (`pigeoneer` on edge nodes, `pigeoncoop` on `JakeBase`).
  - On transitional `arm64` / `amd64` nodes (`AdaCtrl-RPI5`, `MargiStars-N100`), `AdaLovespace` applies native Debian/Ubuntu headless normalization while sharing the exact same board-parameterized systemd cgroup v2 slice templates (`boards/*.env`) for zero-drift RISC-V cutover.
- **System-Space Engine + Per-Operator Spec:**
  - Engine checkout resides in `/opt/adalovespace/engine` (`install-cli.sh`), linked at `/usr/local/bin/ada` and `/usr/bin/ada`.
  - Per-node operator specification lives in `~/.adalovespace/node.env` (initialized via `sudo ada init`, converged via `sudo ada forge`), with ORT provenance snapshots written to `~/.adalovespace/snapshots/`.

## 2. Node Roles & Board Profiles
- **Roles (`roles/*.env`):**
  - `adactrl` (`AdaCtrl-RPI5` active -> `AdaCtrl-RV2` migration target): Consolidated scope controller running `INDI` (`indiwebmanager.service` + `indiserver` `:7624` / `:8624`), decoupled headless `Xvfb` + `PHD2` (`xvfb-guiding.service` + `phd2.service` `:4400`), and `CarrierPigeons` (`pigeoneer.service`) under strict cgroup v2 CPU-mask partitioning (`MaryGuider-RPZ2` retired).
  - `jakebase` (`JakeBase-VF2`): RVDK Data Broker (`PostgreSQL 18.6 io_uring` + `Mosquitto` + `NFS-Ganesha` + `PigeonCoop`).
  - `caroline-v` (`CarolineV-VF2`): RVDK Edge NPU Inference Engine (`Hailo-8` / `Hailo-10H` + `Pigeoneer`).
  - `margistars` (`MargiStars-N100` -> `MargiMaestro-RV2`): Capture orchestration node (external guiding pointed to `AdaCtrl` `:4400`).
  - `alonev-air` (`ALOne-V Air` on `Orange Pi RV2`): Unified 8-hart `riscv64` scope controller + `Hailo-10H` inference appliance.
- **Board Adapters (`boards/*.env`):**
  - Swap cgroup v2 `AllowedCPUs=` masks declaratively (`rpi5` 4-core BCM2712+RP1 vs `rv2` 8-core SpacemiT Ky X1) without `isolcpus=` or PID 1 `CPUAffinity=` inheritance traps.

## 3. Core Engineering Rules
- **Shell & Python Standards:** All Bash scripts use `set -Eeuo pipefail` (with `zsh` ksh-emulation on entrypoints) and pass `shellcheck -x -S warning`. Python helpers target Python 3.12+ with strict explicit type annotations (`uv` for isolated service environments, `pyarrow` for tabular analytics).
- **Brownfield & Idempotency Safety:** Re-running `sudo ada forge` against a converged node must emit `[SKIP]`, preserve live calibrated `/home/<user>/.indi/*.xml` and `~/.PHDGuidingV2` state, never overwrite source-compiled `libindi` (`>= 2.0`) with older distro `libindi-dev` packages, and trigger zero unnecessary `daemon-reload` or daemon restarts.
- **Repository Hygiene (`python3 tools/ada_ci.py --check`):** Never commit residential GPS coordinates, personal `~/.ssh/config` aliases, `BrakerRak` `10.0.10.0/24` literals, or plaintext secrets.
