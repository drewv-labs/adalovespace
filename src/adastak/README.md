# AdaLovespace // AdaStak

AdaStak is a multi-node research cluster to study & measure open source astrophotography software for RISC-V silicon as independent sandboxes that work together as a full distributed Astrolab. 

The intention of this research is research and optimize stable RISC-V Astro software and systems in explicit isolated environments to converge into a single, all-in-one RISC-V astro computer that comfortably rides on the scope. We want to design & build the worlds first & most powerful RISC-V Astro Compute + high fidelity data brokering + edge AI solutions. We want to open up the RISC-V frontier, introduce edge AI platform, & provide rich data ecosystem to astrophotography community.

Composed of two main groups:
- **AdaRak**: 4U mini-rack mounted nodes meant to either sit on the ground near the scope rig or inside ground control center where operator is working from. 
  - **RadiaWrt-One**: BananaPi OpenWrt One router servering as network manager and high-power WiFi AP.
  - **JakeBase-VF2**: Starfive VisionFive 2 + 2TB SN770 M.2 NVMe drive as RVDK built & tuned Astro edge data broker with PSQL 18.6 io_uring, NFS Ganesha, MQTT broker and serving as Ada's PigeonCoop broker.
  - **CarolineV-VF2**: Starfive VisionFive 2 + Hailo-8 (26 TOPS) M.2 NVMe NPU module as RVDK built & tuned Astro edge AI engine.
  - **MargiStar-N100**: HUNSN RJ35 N100 mini PC + 500GB SATA SD drive as x86 KStars+Ekos machine with NoMachine for remote graphical interface from operator laptop/workstation. Built using Ubuntu Server OS + XFCE lightweight desktop env + Lightroom

- **AdaScope**: On-Scope nodes
  - **AdaCtrl-RPI5**: Raspberry Pi 5 4GB INDI server + headless PHD2 engine.

## Roadmap:

- **AdaCtrl RISC-V Migration**: **AdaCtrl-RPI5** to be rebuilt as **AdaCtrl-RV2**, swapping the RPI5 `arm64` for OrangePi RV2 `riscv64` node.

- **MargiMaestro Orchestration**: Replacing **MargiStars-N100**, **MargiMaestro-RV2** node will serve upcoming `MaestroEngine` Go-powered general purpose (not just astro centric) inference injection optimized event orchestration that integrates natively with CarrierPigeons. The goal here is remove support for KStars/Ekos from software stack & x86 compute nodes from hardware stack in favor of our mission for pure RISC-V Astro implementation that gives users superpowers while sipping watts.

- **ALOne-V Air**: The first all-in-one RISC-V compute product this Lab aims to delivery through **AdaStack** R&D work. Based on OPi RV2's 8 hart K1 derivative + 8gb of RAM + 2 M.2 PCIe slots, this is a great platform for the **ALOne-V Air** build as a open source RISC-V ASI Air killer.

- **ALOne-V Pro**: The second all-in-one RISC-V compute product based on Milk-V Jupiter 2 as an Eagle killer.


## Other goals:

- **Flashable Per-built Images**: Ideally I want to get to a place where we have prebuilt headless Debian images for each node that one could flash onto SD or USB media then simply configure users, hostnames, etc through `RVDK`. 
  - `sudo rvdk flash alonev-air-rv2 sd 4`
  - `ssh user@12.34.56.78`
  - `sudo ada config --user drew --nopasswd && sudo ada apply-config`
(or something like that)
