# $__AdaLovespace_ `@<3[\s]`

A Heterogeneous Distributed Edge AI Field Lab for Real-Time Astrophysical Analysis  

### > What is this?

The intention of the Ada Lovespase project is to build a high fidelity prototype of modern astrophotography and observatory based research infrastructure through designing and building a small, highly resilient, high throughput, low energy distributed edge AI cluster that can be used to expand automation and data pipelining applications with no bounds. Whether its running a swarm of IoT sensors to real time inference driven event detection, expiriment with distributed scope clustering, or the desire to process and analyze large volumes of astrophysical data onsite without disturbing core imaging processes, Ada Lovespace aims to push the boundaries of what is possible in astrophotography and observatory based research while sipping watts. This project is intended for the hardcore hobbiest and/or those looking for opportunities to learn a variety of technologies such as MQTT pipelines, distributed computing, machine learning & AI, data science & engineering, niche architectures like RISC-V, and so much more while honoring the legacies of STEM's most badass ladies.

With that, lets meet the Ada Lovespace gang...

### > Namesakes & Tributes

Ada Lovespace is currently comprised of 6 nodes; Two on-scope and four in a mini-rack enclosure placed near the rig. Each node is named after a pioneering woman in STEM whose work laid the groundwork for precision computing, network architecture, or observational astronomy.

#### `AdaBrain` | Ada Lovelace (1815-1852)
English mathematician and writer Ada Lovelace envisioned programmable computation long before mechanical computers existed, authoring the first algorithm for Charles Babbage’s Analytical Engine and proving that machines could manipulate abstract symbols—not just perform arithmetic. While her work predated modern astronomy by decades, her computational framework became indispensable to today’s automated observatories, where precise control logic and real-time data routing turn raw photon counts into publishable catalogs. AdaBrain channels this pioneering architecture as your scope-mounted INDI web server: exposing local telemetry, managing mount/camera parameters via the INDIGO/INDI protocol stack, and serving as the conceptual heart of Ada Lovespace itself. Positioned at the optical frontier, it reminds us that every exposure begins with a single well-crafted instruction—and that modern astrophotography pipelines still run on her original blueprint for programmable machines.

#### `Caroline-V` | Caroline Herschel (1750-1848)
German-British astronomer Caroline Herschel independently discovered eight comets, cataloged hundreds of nebulae, and pioneered systematic data reduction techniques that turned observational astronomy into a reproducible science. She also developed efficient mechanical calculation methods to automate ephemeris computations—early computational optimization in practice. Caroline-V honors her as your RISC-V inference engine: delivering low-power, high-efficiency AI processing for real-time object detection, defect mapping, and image analysis at the edge of your observatory stack, where every watt counts.

#### `JakeBase` | Elizabeth “Jake” Feinler (1931-present)
Elizabeth “Jake” Feinler was instrumental in building the early Internet, managing ARPANET’s first Network Information Center and designing the host directory that made distributed computing scalable and discoverable. She championed open data standards when most networks were proprietary silos. JakeBase channels her infrastructure-first philosophy as your central NFS/PostgreSQL/MQTT broker—routing telemetry, persisting raw FITS catalogs, and ensuring every edge node can reliably publish, subscribe, and back up its astronomical findings across the lab’s local fabric without single-point bottlenecks.

#### `Margaret` | Margaret Hamilton (1936-present)
As lead software engineer for NASA's Apollo missions, Margaret Hamilton pioneered real-time flight systems architecture and effectively founded modern software engineering. Her team demonstrated that rigorous design patterns, exhaustive testing, and graceful error recovery can keep critical systems functional under extreme failure conditions. While her work was aerospace rather than astronomical, the same principles of timing-critical orchestration apply directly to astrophotography: Margaret runs your Kstars/Ekos stack, synchronizing mount tracking, filter wheels, camera triggers, and environmental sensors into a single fault-tolerant capture pipeline.

#### `MaryGuider` | Mary Somerville (1780-1827)
Scottish polymath Mary Somerville transformed observational astronomy into a mathematical science through her work in celestial mechanics and geodesy. She translated Laplace's Mécanique Céleste, authored foundational textbooks, and calculated planetary perturbations that directly enabled John Couch Adams to predict Neptune's existence before it was observed. Her legacy of precision-driven computation aligns perfectly with MaryGuider's role as a dedicated PHD2 guiding engine—where sub-arcsecond tracking accuracy and unwavering loop discipline keep your optics locked on target through the longest, coldest exposures.

#### `RadiaWrt` | Radia Perlman (1951-present)
Network architect Radia Perlman invented Spanning Tree Protocol (STP), solving critical routing loops in early Ethernet networks and enabling reliable, scalable topologies to become the backbone of modern networking. Her designs prioritize resilience without sacrificing throughput or introducing unnecessary latency. RadiaWrt embodies this engineering philosophy as your dedicated OpenWrt router—handling inter-node synchronization, traffic shaping, and fault-tolerant connectivity so data flows cleanly between capture, processing, and storage layers even when cables are swapped or nodes reboot mid-session.

### > Mission
Use this project to perform 3 demos; 

1. Single scope `SynapseHorde` build, which will be a system of custom ESP32 sensor pods im calling “Synapse Pods” and the idea is to place these systematically inside and outside the Newtonian tube and around the local area around the rig to feed the pod sensor data via MQTT payload at a variable rate to the edge lab where we can use python tools like Plotly to visualize a 3D model of things like temp, humidity, pressure, light level, and sound while combining these data points + accelerometer and guiding image data into the inferencing engine to detect things like micro vibrations, macro vibrations from wind, light leaks inside the tube in real time, heat currents, etc. So for example if the plan is set to start the run at 8pm but we’re detecting heat currents inside the tube then run a “pre-run heatcurrent-hold” subroutine that puts none-essential systems on low power and basically just watch heat current data until its clear then recalc the plan/ refocus and go. Or like during the run if we detect light leak inside the tube, pause the run and shoot me a NTFY alert to come inspect. This is the “Set it and forget it” build so after setup I can just get high and actually enjoy the night sky.

2. Multi scope `NarrowBandCannon`, this one is a 3+ (but factors of 3) distributed mutually exclusive scope rig build using minimalistic small wide field refactors with monochrome cameras and each scope node is responsible for a single channel for the entirety of the session and 1/n of broadband data for star processing to concurrently collect narrowband light data. This reduces real capture time for total integration time required to process the given target and all channels represent data for the same time window. USing centralized NPU via this astro edge lab in conglomeration with federated NPU nodes will help ensure each scope node is framed precisely and optics/focus are all within a reasonable tolerance via measures like FWHM. Scope NPU will help trigger local events like refocus and plan recalc to maintain master plan criteria while astro lab supports cluster wide events like “clouds incoming, finish current sub then sleep for N mins then report in for further instructions”. Each scope is free to drizzle at will. 

3. multi scope `BroadBandBazooka` build, 2+ (no factor constraint) scope cluster using color cams and using same multinodal mixmanager strategy in NarrowBandCannon but instead of the cluster hard focusing the same target the cluster would do more of a panelling operation where each scope node hard focuses on a designated pane within the greater panelled image area. This will cut down panelled image area by N times and with enough scopes private citizens could engage in their own self hosted Vera Reubin like “all sky scan” projects where the cluster panel frame slews around the sky as an aggregated panelled plan with high total integration time/real imaging time value. Given enough scope nodes in the cluster, one could do an all sky scan where each scope hard focuses the same pane the entire night and stitch together an all sky image with session time * N scope nodes total integration time. 

### > Drew's Current Setup

#### `AdaScope` | Automagical Astrograph

* `AdaBrain`: 
  * namesake: Ada Lovelace
  * role: Scope Pilot
  * services:
    * INDI Web
  * hardware:
    * RPi5:
      * arch: arm64
      * cpu: 
      * mem: 4GB
      * storage1: SD Card
      * nets: 
        * 1x 1gpbs ETH to cluster
        * 1x UBS-as-Ethernet to MaryGuider
      * pwr: 5v PoE Adapter

* `MaryGuider`: 
  * namesake: Mary Somerville
  * role: Navigator
  * services:
    * PHD2
  * hardware:
    * Pi Zero 2W:
      * arch: arm64
      * cpu:
      * mem: 512MB
      * storage1: SD Card
      * nets:
        * 1x UBS-as-Ethernet to AdaBrain
        * Wi-Fi comms for cluster
      * pwr: Single USB tether to AdaBrain


#### `AdaStack` | Astro Edge Lab

* `RadiaWrt`: 
  * namesake: Radia Perlman
  * role: Network Operator
  * hardware:
    * BananaPi OpenWrt One
    * Netgear GS308PP 
      * bandwidth: 1gbps
      * poe: 83w+

* `Margaret`: 
  * namesake: Margaret Hamilton
  * role: Orchestration Maestro
  * services:
    * NoMachine
    * KStars
    * Ekos
  * hardware:
    * Hunsn RJ35:
      * arch: x86_64
      * cpu: N100 
      * mem: 16GB 
      * storage1: 256GB SATA SSD
      * nets:
        * 4x 2.5gbps ETH
      * pwr: 12v 

* `JakeBase`: 
  * namesake: Elizabeth "Jake" Feinler.
  * role: Data Broker
  * services:
    * NAS
    * PostgreSQL
    * MQTT broker
    * Ntfy server
    * Telegraf
  * hardware: 
    * RPi5:
      * arch: arm64
      * cpu:
      * mem: 8GB
      * storage1: 2TB NVMe SSD via 52pi NVMe+PoE HAT
      * nets: 
        * 1x 1gbps ETH
      * pwd: PoE HAT

* `Caroline-V`: 
  * namesake: Caroline Herschel
  * role: Data Scientist, 
  * hardware:
    * VisionFive2:
      * arch: riscv64
      * cpu: 
      * npu: Hailo-8L@13TOPS NVMe 
      * mem: 8GB 
      * storage1: 64GB SD card
      * nets:
        * 2x 1gpbs ETH
      * pwr: PoE HAT 

#### `NookStack` | Mainframe, Research Lab, & Studio

* `LabWrt`: 
  * role: Network Operator
  * where: rack-shelf
  * hardware:
    * NanoPi R6S
      * os: OpenWrt
      * arch: arm64
    * switch: Sodola 24 Port 2.5Gbps unmanaged switch

* `MacDaddyPro`: 
  * role: Development, Research, Studio
  * where: desk, mobile
  * hardware: 
    * MacBook Pro
      * os: MacOS 15.7.5
      * arch: arm64
      * cpu: M2 Max
      * gpu: M2 Max
      * mem: 96GB unified
      * storage1: 4TB NVMe SSD

* `CoffeeCan`: 
  * role: Hypervisor, Data Broker
  * where: rack-mount
  * hardware:
    * node: 2013 MacPro 6,1:
      * os: Proxmox
      * arch: x86_64
      * cpu: 24 x Intel(R) Xeon(R) CPU E5-2697 v2 @ 2.70GHz (1 Socket)
      * gpu: AMD Fire
      * mem: 64GB RAM
      * store1: 1TB NVMe SSD
    * raid_drive1: 
      * name: BigRed, BigRedDrive
      * size: 36TB USB RAID1 Drive
    * raid_drive2: 
      * name: LilBlu, LittleBlueDrive
      * size: 12TB USB RAID5 Drive 

* `Poggerbox`: 
  * role: CUDA Engine, Gaming
  * hardware:
    * DIY-PC
      * where: rack mount
      * os: Linux Mint Cinnamon 22.3 LTS
      * arch: x86_64
      * cpu: i9-9900k
      * gpu: RTX3080Ti 
      * mem: 32GB DDR4
      * storage1: 500GB M.2 NVMe SSD
      * network1: 2.5gbps ETH
