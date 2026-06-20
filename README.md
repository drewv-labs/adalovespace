# Ada Scope

![Status](https://img.shields.io/badge/Status-Planning_%26_Architecture-blue)
![Type](https://img.shields.io/badge/Type-DIY_Hardware-orange)
![License](https://img.shields.io/badge/License-TBD-lightgrey)

> **A fully integrated, automated, DIY Newtonian Astrograph & Datacenter.**

## 🔭 Project Overview
The **Ada Lovespace Scope** is an open-hardware initiative to design a high-performance Newtonian astrograph from the ground up. Unlike traditional DIY builds that require bolting disparate accessories onto a commercial tube, Ada is designed as a unified system.

**The Goal:** To create a fast, stable, and "smart" imaging platform where the mechanics, electronics, and optics are tightly integrated.

### Key Objectives
* **Integrated Automation:** Built-in logic for focus, collimation, and thermal management.
* **Cable Management:** Through-mount cabling design to eliminate snags and drag.
* **Accessible Manufacturing:** Designed for standard 3D printing and CNC routing/machining.
* **Open Architecture:** Modular software and hardware allowing for community mods.

---

## 📂 Repository Structure
This repository acts as the central source of truth for the entire Ada Scope platform.

```text
ada-scope/
├── 📂 cad/              # Mechanical designs (STEP, STL, Native files)
│   ├── 📂 main-assembly
│   └── 📂 components
├── 📂 electronics/      # PCB designs, wiring diagrams, and schematics
│   ├── 📂 eagle         # Board files
│   └── 📂 wiring        # Cable management & pinouts
├── 📂 software/         # Firmware and Control software
│   ├── 📂 firmware      # Microcontroller code (Arduino/ESP32/Pi Pico)
│   └── 📂 drivers       # INDI drivers or Python control scripts
├── 📂 docs/             # Formal specifications and assembly guides
│   ├── 📂 specs         # Optical & Mechanical requirements
│   └── 📂 assembly      # Build instructions
└── 📂 tests/            # Optical simulations and software unit tests
