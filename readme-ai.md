<div id="top">

<!-- HEADER STYLE: CLASSIC -->
<div align="center">

<img src="readmeai/assets/logos/purple.svg" width="30%" style="position: relative; top: 0; right: 0;" alt="Project Logo"/>

# <code>❯ REPLACE-ME</code>

<em></em>

<!-- BADGES -->
<!-- local repository, no metadata badges. -->

<em>Built with the tools and technologies:</em>

<img src="https://img.shields.io/badge/GNU%20Bash-4EAA25.svg?style=default&logo=GNU-Bash&logoColor=white" alt="GNU%20Bash">
<img src="https://img.shields.io/badge/Python-3776AB.svg?style=default&logo=Python&logoColor=white" alt="Python">

</div>
<br>

---

## Table of Contents

- [Table of Contents](#table-of-contents)
- [Overview](#overview)
- [Features](#features)
- [Project Structure](#project-structure)
    - [Project Index](#project-index)
- [Getting Started](#getting-started)
    - [Prerequisites](#prerequisites)
    - [Installation](#installation)
    - [Usage](#usage)
    - [Testing](#testing)
- [Roadmap](#roadmap)
- [Contributing](#contributing)
- [License](#license)
- [Acknowledgments](#acknowledgments)

---

## Overview

[project_name] is your one-stop solution for automating builds, managing dependencies, and ensuring real-time system monitoring. The core features include:

- **🚀 Efficient Data Management:** Simplifies project dependency management and streamlines data processing.
- **🔄 Automated Backups:** Ensures all project files are safely backed up without manual intervention.
- **📊 Real-Time Monitoring:** Provides continuous telemetry data collection and publishing for centralized analysis.

---

## Features

|      | Component       | Details                              |
| :--- | :-------------- | :----------------------------------- |
| ⚙️  | **Architecture**  | <ul><li>Monolithic</li></ul> |
| 🔩 | **Code Quality**  | <ul><li>Basic linting with `flake8`</li><li>No formal code review process documented</li></ul> |
| 📄 | **Documentation** | <ul><li>Limited README.md with basic installation instructions</li><li>No API documentation or user guides</li></ul> |
| 🔌 | **Integrations**  | <ul><li>Uses `requests` for HTTP requests</li><li>Depends on `dbus-python` and `adafruit-circuitpython-requests` for hardware interactions</li></ul> |
| 🧩 | **Modularity**    | <ul><li>No clear separation of concerns; all code in a single file or directory</li></ul> |
| 🧪 | **Testing**       | <ul><li>No unit tests or integration tests mentioned</li></ul> |
| ⚡️  | **Performance**   | <ul><li>No performance optimizations or profiling tools used</li></ul> |
| 🛡️ | **Security**      | <ul><li>No security best practices followed; e.g., no use of environment variables for sensitive data</li></ul> |
| 📦 | **Dependencies**  | <ul><li>Uses `pip` to manage dependencies from `requirements.txt` and `requirements.in`</li><li>Includes a mix of Python libraries, system utilities, and hardware-specific drivers</li></ul> |
| 🚀 | **Scalability**   | <ul><li>No design considerations for scalability; monolithic architecture limits scalability</li></ul> |

### Notes:
- The project appears to be a single-purpose application with limited documentation.
- There is no formal code review process or testing strategy, which could lead to bugs and security vulnerabilities.

---

## Project Structure

```sh
└── /
    ├── README.md
    ├── assets
    │   ├── VisionFive2_Datasheet.pdf
    │   ├── ada-lovespace-lockscreen-wallpaper-1080p.png
    │   ├── ada-lovespace-wallpaper-1080p.jpeg
    │   ├── ada-lovespace-wallpaper-gigares.jpeg
    │   ├── ada_power_mapping.drawio
    │   ├── adascopepi_system_report.txt
    │   └── sayobk.sayobak
    ├── buildscripts
    │   ├── build_adabrain.sh
    │   ├── build_carolinefive.sh
    │   ├── build_jakebase.sh
    │   ├── build_margaret.sh
    │   ├── build_maryguider.sh
    │   ├── build_radiawrt.sh
    │   ├── lib
    │   ├── mary_phd2_server_fluxbox_ignition.sh
    │   ├── mary_phd2_server_install.sh
    │   ├── mary_phd2_server_swap_optics.sh
    │   └── mary_phd2_server_systemd_phd2.service
    ├── datapipelines
    │   ├── dagster_sensor.py
    │   ├── parse_firecapture_logs.py
    │   ├── rename_assets.py
    │   ├── sync_shuttle.sh
    │   ├── telegester.py
    │   ├── telegester.service
    │   ├── telesender.py
    │   └── telesender.service
    ├── docs
    │   ├── Charts&Graphs
    │   ├── Gear
    │   ├── Optical
    │   └── Processing
    ├── models
    │   └── telegester.sql
    ├── package
    │   ├── cli
    │   ├── drivers
    │   └── firmware
    ├── requirements.in
    ├── requirements.txt
    ├── research
    │   └── CarbonTrussRC10
    └── scratch.txt
```

### Project Index

<details open>
	<summary><b><code>/</code></b></summary>
	<!-- __root__ Submodule -->
	<details>
		<summary><b>__root__</b></summary>
		<blockquote>
			<div class='directory-path' style='padding: 8px 0; color: #666;'>
				<code><b>⦿ __root__</b></code>
			<table style='width: 100%; border-collapse: collapse;'>
			<thead>
				<tr style='background-color: #f8f9fa;'>
					<th style='width: 30%; text-align: left; padding: 8px;'>File Name</th>
					<th style='text-align: left; padding: 8px;'>Summary</th>
				</tr>
			</thead>
				<tr style='border-bottom: 1px solid #eee;'>
					<td style='padding: 8px;'><b><a href='/scratch.txt'>scratch.txt</a></b></td>
					<td style='padding: 8px;'>Scratch.txt serves as a temporary storage file for intermediate data processing steps within the projects workflow, facilitating smooth integration and data flow across various components of the codebase.</td>
				</tr>
				<tr style='border-bottom: 1px solid #eee;'>
					<td style='padding: 8px;'><b><a href='/requirements.txt'>requirements.txt</a></b></td>
					<td style='padding: 8px;'>Manages project dependencies, ensuring compatibility and ease of installation across various environments.</td>
				</tr>
				<tr style='border-bottom: 1px solid #eee;'>
					<td style='padding: 8px;'><b><a href='/requirements.in'>requirements.in</a></b></td>
					<td style='padding: 8px;'>Manages project dependencies using pip-tools, ensuring consistent and reproducible installations across environments.</td>
				</tr>
			</table>
		</blockquote>
	</details>
	<!-- datapipelines Submodule -->
	<details>
		<summary><b>datapipelines</b></summary>
		<blockquote>
			<div class='directory-path' style='padding: 8px 0; color: #666;'>
				<code><b>⦿ datapipelines</b></code>
			<table style='width: 100%; border-collapse: collapse;'>
			<thead>
				<tr style='background-color: #f8f9fa;'>
					<th style='width: 30%; text-align: left; padding: 8px;'>File Name</th>
					<th style='text-align: left; padding: 8px;'>Summary</th>
				</tr>
			</thead>
				<tr style='border-bottom: 1px solid #eee;'>
					<td style='padding: 8px;'><b><a href='/datapipelines/rename_assets.py'>rename_assets.py</a></b></td>
					<td style='padding: 8px;'>- The <code>rename_assets.py</code> script sanitizes filenames and directory names by replacing spaces, parentheses, colons, and commas with underscores, ensuring no double underscores<br>- It recursively renames files and directories in a specified path, avoiding hidden items and handling potential collisions<br>- The script outputs all changes made during the renaming process.</td>
				</tr>
				<tr style='border-bottom: 1px solid #eee;'>
					<td style='padding: 8px;'><b><a href='/datapipelines/dagster_sensor.py'>dagster_sensor.py</a></b></td>
					<td style='padding: 8px;'>Monitors the Coffeecan database for new telemetry data from JakeBase, triggering a Dagster pipeline to process it if updates are detected.</td>
				</tr>
				<tr style='border-bottom: 1px solid #eee;'>
					<td style='padding: 8px;'><b><a href='/datapipelines/telesender.py'>telesender.py</a></b></td>
					<td style='padding: 8px;'>- The <code>telesender.py</code> script collects system metrics such as CPU usage, memory, disk space, and temperature, then publishes these telemetry data to an MQTT broker at regular intervals<br>- This script is integral to the projects monitoring and logging infrastructure, ensuring that all nodes can report their status in real-time for centralized analysis and alerting.</td>
				</tr>
				<tr style='border-bottom: 1px solid #eee;'>
					<td style='padding: 8px;'><b><a href='/datapipelines/sync_shuttle.sh'>sync_shuttle.sh</a></b></td>
					<td style='padding: 8px;'>- The <code>sync_shuttle.sh</code> script automates the synchronization of project files from a local directory to an external SHUTTLE drive using rsync<br>- It checks if the drive is mounted, then performs a backup with options to preserve permissions and delete extraneous files on the drive<br>- This ensures that all projects are safely backed up without manual intervention.</td>
				</tr>
				<tr style='border-bottom: 1px solid #eee;'>
					<td style='padding: 8px;'><b><a href='/datapipelines/telesender.service'>telesender.service</a></b></td>
					<td style='padding: 8px;'>Manages the Ada Postgres Telemetry Ingester service, ensuring it runs after network and database services start, with automatic restarts on failure.</td>
				</tr>
				<tr style='border-bottom: 1px solid #eee;'>
					<td style='padding: 8px;'><b><a href='/datapipelines/telegester.service'>telegester.service</a></b></td>
					<td style='padding: 8px;'>Manages the Ada Node Telemetry Sender service, ensuring continuous execution of telemetry data transmission with automatic restarts and buffering disabled.</td>
				</tr>
				<tr style='border-bottom: 1px solid #eee;'>
					<td style='padding: 8px;'><b><a href='/datapipelines/telegester.py'>telegester.py</a></b></td>
					<td style='padding: 8px;'>- The <code>telegester.py</code> script establishes a connection to an MQTT broker and listens for telemetry data from various nodes<br>- Upon receiving data, it parses the JSON payload, extracts relevant metrics, and inserts them into a PostgreSQL database<br>- This script is integral to the systems real-time monitoring capabilities, ensuring that all node statuses are accurately recorded and accessible for analysis.</td>
				</tr>
				<tr style='border-bottom: 1px solid #eee;'>
					<td style='padding: 8px;'><b><a href='/datapipelines/parse_firecapture_logs.py'>parse_firecapture_logs.py</a></b></td>
					<td style='padding: 8px;'>Parse_firecapture_logs.py processes raw fire capture logs, extracting critical data to support real-time monitoring and analysis within the systems architecture.</td>
				</tr>
			</table>
		</blockquote>
	</details>
	<!-- models Submodule -->
	<details>
		<summary><b>models</b></summary>
		<blockquote>
			<div class='directory-path' style='padding: 8px 0; color: #666;'>
				<code><b>⦿ models</b></code>
			<table style='width: 100%; border-collapse: collapse;'>
			<thead>
				<tr style='background-color: #f8f9fa;'>
					<th style='width: 30%; text-align: left; padding: 8px;'>File Name</th>
					<th style='text-align: left; padding: 8px;'>Summary</th>
				</tr>
			</thead>
				<tr style='border-bottom: 1px solid #eee;'>
					<td style='padding: 8px;'><b><a href='/models/telegester.sql'>telegester.sql</a></b></td>
					<td style='padding: 8px;'>- The <code>telegester.sql</code> file defines an incremental SQLMesh model named <code>datalake.core_telemetry</code>, which processes telemetry data from the <code>staging.raw_telemetry</code> table and stores it in the <code>datalake</code> schema<br>- After a successful run, it truncates the raw telemetry table to prepare for new data ingestion.</td>
				</tr>
			</table>
		</blockquote>
	</details>
	<!-- buildscripts Submodule -->
	<details>
		<summary><b>buildscripts</b></summary>
		<blockquote>
			<div class='directory-path' style='padding: 8px 0; color: #666;'>
				<code><b>⦿ buildscripts</b></code>
			<table style='width: 100%; border-collapse: collapse;'>
			<thead>
				<tr style='background-color: #f8f9fa;'>
					<th style='width: 30%; text-align: left; padding: 8px;'>File Name</th>
					<th style='text-align: left; padding: 8px;'>Summary</th>
				</tr>
			</thead>
				<tr style='border-bottom: 1px solid #eee;'>
					<td style='padding: 8px;'><b><a href='/buildscripts/build_jakebase.sh'>build_jakebase.sh</a></b></td>
					<td style='padding: 8px;'>Builds and configures a Debian-based system by installing necessary packages, setting up PostgreSQL, NFS, MQTT broker, updating APT, and rebooting the machine.</td>
				</tr>
				<tr style='border-bottom: 1px solid #eee;'>
					<td style='padding: 8px;'><b><a href='/buildscripts/build_margaret.sh'>build_margaret.sh</a></b></td>
					<td style='padding: 8px;'>- Build_margaret.sh automates the build process for a Debian-based system, installing essential packages, configuring Xfce, and setting up Nomachine and KStars/Ekos<br>- It concludes with an apt update/upgrade/purge and a reboot to finalize the setup.</td>
				</tr>
				<tr style='border-bottom: 1px solid #eee;'>
					<td style='padding: 8px;'><b><a href='/buildscripts/build_maryguider.sh'>build_maryguider.sh</a></b></td>
					<td style='padding: 8px;'>Buildscripts/build_maryguider.sh automates the build process for MaryGuider, ensuring consistent and efficient compilation across different environments.</td>
				</tr>
				<tr style='border-bottom: 1px solid #eee;'>
					<td style='padding: 8px;'><b><a href='/buildscripts/build_adabrain.sh'>build_adabrain.sh</a></b></td>
					<td style='padding: 8px;'>Buildscripts/build_adabrain.sh automates the build process for Adabrain, ensuring consistent and efficient compilation across different environments.</td>
				</tr>
				<tr style='border-bottom: 1px solid #eee;'>
					<td style='padding: 8px;'><b><a href='/buildscripts/mary_phd2_server_install.sh'>mary_phd2_server_install.sh</a></b></td>
					<td style='padding: 8px;'>The <code>mary_phd2_server_install.sh</code> script automates the installation of dependencies and compiles PHD2 on a server, optimizing swap space and configuring the environment for remote access via VNC.</td>
				</tr>
				<tr style='border-bottom: 1px solid #eee;'>
					<td style='padding: 8px;'><b><a href='/buildscripts/mary_phd2_server_systemd_phd2.service'>mary_phd2_server_systemd_phd2.service</a></b></td>
					<td style='padding: 8px;'></td>
				</tr>
				<tr style='border-bottom: 1px solid #eee;'>
					<td style='padding: 8px;'><b><a href='/buildscripts/build_carolinefive.sh'>build_carolinefive.sh</a></b></td>
					<td style='padding: 8px;'>Buildscripts/build_carolinefive.sh automates the build process for CarolineFive, ensuring consistent and efficient compilation across different environments.</td>
				</tr>
				<tr style='border-bottom: 1px solid #eee;'>
					<td style='padding: 8px;'><b><a href='/buildscripts/build_radiawrt.sh'>build_radiawrt.sh</a></b></td>
					<td style='padding: 8px;'>Buildscripts/build_radiawrt.sh automates the build process for Radiawrt firmware, ensuring consistent and efficient compilation across different environments.</td>
				</tr>
				<tr style='border-bottom: 1px solid #eee;'>
					<td style='padding: 8px;'><b><a href='/buildscripts/mary_phd2_server_swap_optics.sh'>mary_phd2_server_swap_optics.sh</a></b></td>
					<td style='padding: 8px;'>- The script <code>mary_phd2_server_swap_optics.sh</code> automates the process of switching optical profiles for PHD2, a popular astronomical guiding software<br>- It accepts an argument to select between different focal lengths (base, paracorr, nexus) and updates the configuration file accordingly<br>- The script ensures that the PHD2 daemon is stopped before making changes and restarted afterward, ensuring seamless operation with the new settings.</td>
				</tr>
				<tr style='border-bottom: 1px solid #eee;'>
					<td style='padding: 8px;'><b><a href='/buildscripts/mary_phd2_server_fluxbox_ignition.sh'>mary_phd2_server_fluxbox_ignition.sh</a></b></td>
					<td style='padding: 8px;'>Stops existing services and starts new ones for a Fluxbox environment with PHD2 and VNC access.</td>
				</tr>
			</table>
			<!-- lib Submodule -->
			<details>
				<summary><b>lib</b></summary>
				<blockquote>
					<div class='directory-path' style='padding: 8px 0; color: #666;'>
						<code><b>⦿ buildscripts.lib</b></code>
					<table style='width: 100%; border-collapse: collapse;'>
					<thead>
						<tr style='background-color: #f8f9fa;'>
							<th style='width: 30%; text-align: left; padding: 8px;'>File Name</th>
							<th style='text-align: left; padding: 8px;'>Summary</th>
						</tr>
					</thead>
						<tr style='border-bottom: 1px solid #eee;'>
							<td style='padding: 8px;'><b><a href='/buildscripts/lib/connect_jake_debian.sh'>connect_jake_debian.sh</a></b></td>
							<td style='padding: 8px;'>Executes Debian-specific scripts to connect Jake services, orchestrating MQTT and NFS connections within the Adalovespace build environment.</td>
						</tr>
						<tr style='border-bottom: 1px solid #eee;'>
							<td style='padding: 8px;'><b><a href='/buildscripts/lib/tune_debian.sh'>tune_debian.sh</a></b></td>
							<td style='padding: 8px;'>The <code>tune_debian.sh</code> script automates the tuning of Debian-based systems by sourcing base configuration and package management scripts, ensuring a standardized setup across environments.</td>
						</tr>
						<tr style='border-bottom: 1px solid #eee;'>
							<td style='padding: 8px;'><b><a href='/buildscripts/lib/tune_ubuntu.sh'>tune_ubuntu.sh</a></b></td>
							<td style='padding: 8px;'>- The <code>tune_ubuntu.sh</code> script automates the tuning of an Ubuntu system by sourcing Debian-specific and Ubuntu-specific configuration scripts, followed by updating and upgrading packages using <code>apt</code><br>- This ensures a standardized setup across different environments.</td>
						</tr>
					</table>
					<!-- debian Submodule -->
					<details>
						<summary><b>debian</b></summary>
						<blockquote>
							<div class='directory-path' style='padding: 8px 0; color: #666;'>
								<code><b>⦿ buildscripts.lib.debian</b></code>
							<table style='width: 100%; border-collapse: collapse;'>
							<thead>
								<tr style='background-color: #f8f9fa;'>
									<th style='width: 30%; text-align: left; padding: 8px;'>File Name</th>
									<th style='text-align: left; padding: 8px;'>Summary</th>
								</tr>
							</thead>
								<tr style='border-bottom: 1px solid #eee;'>
									<td style='padding: 8px;'><b><a href='/buildscripts/lib/debian/disable_unattended_upgrades.sh'>disable_unattended_upgrades.sh</a></b></td>
									<td style='padding: 8px;'>Disables unattended upgrades service and timers on Debian-based systems to prevent automatic package updates during non-maintenance hours.</td>
								</tr>
								<tr style='border-bottom: 1px solid #eee;'>
									<td style='padding: 8px;'><b><a href='/buildscripts/lib/debian/tune_power_mode.sh'>tune_power_mode.sh</a></b></td>
									<td style='padding: 8px;'>Tunes power mode by masking sleep-related targets on Debian systems, enhancing system performance and stability.</td>
								</tr>
								<tr style='border-bottom: 1px solid #eee;'>
									<td style='padding: 8px;'><b><a href='/buildscripts/lib/debian/install_postgresql.sh'>install_postgresql.sh</a></b></td>
									<td style='padding: 8px;'>Installs PostgreSQL on Debian-based systems, configures it to listen on all interfaces, and restarts the service.</td>
								</tr>
								<tr style='border-bottom: 1px solid #eee;'>
									<td style='padding: 8px;'><b><a href='/buildscripts/lib/debian/install_dagster_sqlmesh_stack.sh'>install_dagster_sqlmesh_stack.sh</a></b></td>
									<td style='padding: 8px;'>- The script automates the setup of a Data Engine LXC on Proxmox, installs necessary tools and dependencies, initializes a Dagster-SQLMesh project, and creates a repository file<br>- It streamlines the process of deploying a robust data engineering environment.</td>
								</tr>
								<tr style='border-bottom: 1px solid #eee;'>
									<td style='padding: 8px;'><b><a href='/buildscripts/lib/debian/nuke_storage_spammer.sh'>nuke_storage_spammer.sh</a></b></td>
									<td style='padding: 8px;'>Disables and purges the multipathd service and tools on Debian-based systems, ensuring clean storage management.</td>
								</tr>
								<tr style='border-bottom: 1px solid #eee;'>
									<td style='padding: 8px;'><b><a href='/buildscripts/lib/debian/base_tune.sh'>base_tune.sh</a></b></td>
									<td style='padding: 8px;'>Base_tune.sh automates the setup of a Debian-based system by executing a series of scripts to disable unattended upgrades, remove modemmanager and radios, block storage spamming, and optimize power mode.</td>
								</tr>
								<tr style='border-bottom: 1px solid #eee;'>
									<td style='padding: 8px;'><b><a href='/buildscripts/lib/debian/install_mqtt_broker.sh'>install_mqtt_broker.sh</a></b></td>
									<td style='padding: 8px;'>Installs Mosquitto MQTT broker on Debian systems, configures it to allow anonymous connections, and restarts the service.</td>
								</tr>
								<tr style='border-bottom: 1px solid #eee;'>
									<td style='padding: 8px;'><b><a href='/buildscripts/lib/debian/apt_update_upgrade_slay.sh'>apt_update_upgrade_slay.sh</a></b></td>
									<td style='padding: 8px;'>Updates, upgrades, and purges system packages using <code>apt</code> commands, ensuring the Debian-based system is clean and up-to-date.</td>
								</tr>
								<tr style='border-bottom: 1px solid #eee;'>
									<td style='padding: 8px;'><b><a href='/buildscripts/lib/debian/install_uv_root.sh'>install_uv_root.sh</a></b></td>
									<td style='padding: 8px;'>Installs UV by downloading and executing its installation script with a specified directory.</td>
								</tr>
								<tr style='border-bottom: 1px solid #eee;'>
									<td style='padding: 8px;'><b><a href='/buildscripts/lib/debian/nuke_radios.sh'>nuke_radios.sh</a></b></td>
									<td style='padding: 8px;'>Disables Bluetooth and Wi-Fi services, purges related packages, and ensures they are unheld to prevent future automatic upgrades.</td>
								</tr>
								<tr style='border-bottom: 1px solid #eee;'>
									<td style='padding: 8px;'><b><a href='/buildscripts/lib/debian/install_nomachine_dev.sh'>install_nomachine_dev.sh</a></b></td>
									<td style='padding: 8px;'>Installs NoMachine on Debian-based systems by downloading and executing a DEB package.</td>
								</tr>
								<tr style='border-bottom: 1px solid #eee;'>
									<td style='padding: 8px;'><b><a href='/buildscripts/lib/debian/base_installs.sh'>base_installs.sh</a></b></td>
									<td style='padding: 8px;'>Executes base Debian installations by sourcing <code>install_uv_root.sh</code> from the projects buildscripts directory.</td>
								</tr>
								<tr style='border-bottom: 1px solid #eee;'>
									<td style='padding: 8px;'><b><a href='/buildscripts/lib/debian/connect_jake_mqtt.sh'>connect_jake_mqtt.sh</a></b></td>
									<td style='padding: 8px;'>Installs MQTT clients on Debian-based systems, facilitating communication with MQTT brokers.</td>
								</tr>
								<tr style='border-bottom: 1px solid #eee;'>
									<td style='padding: 8px;'><b><a href='/buildscripts/lib/debian/connect_jake_nfs.sh'>connect_jake_nfs.sh</a></b></td>
									<td style='padding: 8px;'>- The script <code>connect_jake_nfs.sh</code> automates the connection of NFS shares from Jakes server to the local system<br>- It creates mount points, installs necessary packages, updates <code>/etc/fstab</code>, and mounts the shares, ensuring seamless integration into the projects architecture.</td>
								</tr>
								<tr style='border-bottom: 1px solid #eee;'>
									<td style='padding: 8px;'><b><a href='/buildscripts/lib/debian/nuke_modemmanager.sh'>nuke_modemmanager.sh</a></b></td>
									<td style='padding: 8px;'>Disables and purges ModemManager service from Debian-based systems, ensuring a clean environment for other network management tools.</td>
								</tr>
								<tr style='border-bottom: 1px solid #eee;'>
									<td style='padding: 8px;'><b><a href='/buildscripts/lib/debian/build_debian_xfce_lightdm.sh'>build_debian_xfce_lightdm.sh</a></b></td>
									<td style='padding: 8px;'>Installs XFCE desktop environment and LightDM display manager with no password login enabled, automating the setup process for a Debian-based system.</td>
								</tr>
								<tr style='border-bottom: 1px solid #eee;'>
									<td style='padding: 8px;'><b><a href='/buildscripts/lib/debian/install_nfs_host.sh'>install_nfs_host.sh</a></b></td>
									<td style='padding: 8px;'>Installs NFS server, creates share and wheelhouse directories, configures exports, and restarts the service to enable network file sharing.</td>
								</tr>
							</table>
						</blockquote>
					</details>
					<!-- ubuntu Submodule -->
					<details>
						<summary><b>ubuntu</b></summary>
						<blockquote>
							<div class='directory-path' style='padding: 8px 0; color: #666;'>
								<code><b>⦿ buildscripts.lib.ubuntu</b></code>
							<table style='width: 100%; border-collapse: collapse;'>
							<thead>
								<tr style='background-color: #f8f9fa;'>
									<th style='width: 30%; text-align: left; padding: 8px;'>File Name</th>
									<th style='text-align: left; padding: 8px;'>Summary</th>
								</tr>
							</thead>
								<tr style='border-bottom: 1px solid #eee;'>
									<td style='padding: 8px;'><b><a href='/buildscripts/lib/ubuntu/nuke_snap.sh'>nuke_snap.sh</a></b></td>
									<td style='padding: 8px;'>The <code>nuke_snap.sh</code> script disables and purges Snapd from Ubuntu systems, ensuring a clean environment for other package managers.</td>
								</tr>
								<tr style='border-bottom: 1px solid #eee;'>
									<td style='padding: 8px;'><b><a href='/buildscripts/lib/ubuntu/base_tune.sh'>base_tune.sh</a></b></td>
									<td style='padding: 8px;'>Base_tune.sh automates the cleanup of unnecessary files on Ubuntu systems by invoking nuke_cloud_bloat.sh and nuke_snap.sh scripts located in the same directory, thereby optimizing the systems performance.</td>
								</tr>
								<tr style='border-bottom: 1px solid #eee;'>
									<td style='padding: 8px;'><b><a href='/buildscripts/lib/ubuntu/nuke_cloud_bloat.sh'>nuke_cloud_bloat.sh</a></b></td>
									<td style='padding: 8px;'>Disables cloud-init, purges the package, and removes associated files to clean up cloud bloat on Ubuntu systems.</td>
								</tr>
								<tr style='border-bottom: 1px solid #eee;'>
									<td style='padding: 8px;'><b><a href='/buildscripts/lib/ubuntu/install_kstars_ekos.sh'>install_kstars_ekos.sh</a></b></td>
									<td style='padding: 8px;'>Installs Kstars and Ekos on Ubuntu systems by adding a PPA and installing necessary packages.</td>
								</tr>
							</table>
						</blockquote>
					</details>
					<!-- sql Submodule -->
					<details>
						<summary><b>sql</b></summary>
						<blockquote>
							<div class='directory-path' style='padding: 8px 0; color: #666;'>
								<code><b>⦿ buildscripts.lib.sql</b></code>
							<table style='width: 100%; border-collapse: collapse;'>
							<thead>
								<tr style='background-color: #f8f9fa;'>
									<th style='width: 30%; text-align: left; padding: 8px;'>File Name</th>
									<th style='text-align: left; padding: 8px;'>Summary</th>
								</tr>
							</thead>
								<tr style='border-bottom: 1px solid #eee;'>
									<td style='padding: 8px;'><b><a href='/buildscripts/lib/sql/raw_telemetry.sql'>raw_telemetry.sql</a></b></td>
									<td style='padding: 8px;'>- The <code>raw_telemetry.sql</code> file defines a table to store raw telemetry data, capturing event types and associated JSONB data with timestamps<br>- This table serves as the foundation for aggregating and analyzing telemetry information across the system.</td>
								</tr>
								<tr style='border-bottom: 1px solid #eee;'>
									<td style='padding: 8px;'><b><a href='/buildscripts/lib/sql/setup_jake_postgres_fdw.sql'>setup_jake_postgres_fdw.sql</a></b></td>
									<td style='padding: 8px;'>Enables network access to JakeBase database from the home database using PostgreSQL Foreign Data Wrapper (FDW), facilitating data import into a staging schema for SQLMesh integration.</td>
								</tr>
							</table>
						</blockquote>
					</details>
				</blockquote>
			</details>
		</blockquote>
	</details>
	<!-- package Submodule -->
	<details>
		<summary><b>package</b></summary>
		<blockquote>
			<div class='directory-path' style='padding: 8px 0; color: #666;'>
				<code><b>⦿ package</b></code>
			<!-- firmware Submodule -->
			<details>
				<summary><b>firmware</b></summary>
				<blockquote>
					<div class='directory-path' style='padding: 8px 0; color: #666;'>
						<code><b>⦿ package.firmware</b></code>
					<table style='width: 100%; border-collapse: collapse;'>
					<thead>
						<tr style='background-color: #f8f9fa;'>
							<th style='width: 30%; text-align: left; padding: 8px;'>File Name</th>
							<th style='text-align: left; padding: 8px;'>Summary</th>
						</tr>
					</thead>
						<tr style='border-bottom: 1px solid #eee;'>
							<td style='padding: 8px;'><b><a href='/package/firmware/single_usb_key_rpipico.py'>single_usb_key_rpipico.py</a></b></td>
							<td style='padding: 8px;'>The <code>single_usb_key_rpipico.py</code> file configures a Raspberry Pi Pico to act as an arcade button that triggers a specific keyboard shortcut when pressed, facilitating automation in the projects overall architecture.</td>
						</tr>
						<tr style='border-bottom: 1px solid #eee;'>
							<td style='padding: 8px;'><b><a href='/package/firmware/triggerhappy_macro.conf'>triggerhappy_macro.conf</a></b></td>
							<td style='padding: 8px;'>- The <code>triggerhappy_macro.conf</code> file configures key bindings for various actions within the firmware architecture, including collimation, parking, shutdown, and focuser micro-stepping<br>- It also handles an emergency abort sequence.</td>
						</tr>
						<tr style='border-bottom: 1px solid #eee;'>
							<td style='padding: 8px;'><b><a href='/package/firmware/sayodevice_03c_update_screen.py'>sayodevice_03c_update_screen.py</a></b></td>
							<td style='padding: 8px;'>Initializes the Sayo device and updates its screen with temperature and frame data using a custom protocol.</td>
						</tr>
					</table>
				</blockquote>
			</details>
			<!-- drivers Submodule -->
			<details>
				<summary><b>drivers</b></summary>
				<blockquote>
					<div class='directory-path' style='padding: 8px 0; color: #666;'>
						<code><b>⦿ package.drivers</b></code>
					<table style='width: 100%; border-collapse: collapse;'>
					<thead>
						<tr style='background-color: #f8f9fa;'>
							<th style='width: 30%; text-align: left; padding: 8px;'>File Name</th>
							<th style='text-align: left; padding: 8px;'>Summary</th>
						</tr>
					</thead>
						<tr style='border-bottom: 1px solid #eee;'>
							<td style='padding: 8px;'><b><a href='/package/drivers/park_scope.py'>park_scope.py</a></b></td>
							<td style='padding: 8px;'>- The <code>park_scope.py</code> file initializes a connection to an INDI server, locates a telescope mount, and commands it to slew to a predefined horizontal position for collimation<br>- This script is essential for setting up the telescopes initial alignment on an equatorial mount.</td>
						</tr>
						<tr style='border-bottom: 1px solid #eee;'>
							<td style='padding: 8px;'><b><a href='/package/drivers/abort_slew.py'>abort_slew.py</a></b></td>
							<td style='padding: 8px;'>Abort_slew.py connects to an INDI server, identifies the telescope mount, and sends an emergency abort command if the mount is not responding within a specified timeout.</td>
						</tr>
						<tr style='border-bottom: 1px solid #eee;'>
							<td style='padding: 8px;'><b><a href='/package/drivers/corrector-lens-detector.py'>corrector-lens-detector.py</a></b></td>
							<td style='padding: 8px;'>- The <code>corrector-lens-detector.py</code> script monitors magnetic sensors connected to GPIO pins 17 and 27<br>- When a sensor detects a magnetic field, it triggers corresponding functions to switch the optical train in Ekos to Ada 920mm or Ada 600mm<br>- The daemon runs continuously, waiting for sensor inputs until manually stopped.</td>
						</tr>
						<tr style='border-bottom: 1px solid #eee;'>
							<td style='padding: 8px;'><b><a href='/package/drivers/collimation_slew.py'>collimation_slew.py</a></b></td>
							<td style='padding: 8px;'>The <code>collimation_slew.py</code> file initializes an INDI client to connect with a telescope mount and sends commands to slew the mount to specific coordinates for horizontal collimation, ensuring precise alignment.</td>
						</tr>
						<tr style='border-bottom: 1px solid #eee;'>
							<td style='padding: 8px;'><b><a href='/package/drivers/focus_step.py'>focus_step.py</a></b></td>
							<td style='padding: 8px;'>- The <code>focus_step.py</code> file provides a Python script that interacts with an Ekos focuser using the PyIndi library to adjust its absolute position based on a command-line argument or default value<br>- It connects to the focuser, retrieves the current position, calculates a new position, and sends it back to the focuser.</td>
						</tr>
					</table>
				</blockquote>
			</details>
			<!-- cli Submodule -->
			<details>
				<summary><b>cli</b></summary>
				<blockquote>
					<div class='directory-path' style='padding: 8px 0; color: #666;'>
						<code><b>⦿ package.cli</b></code>
					<table style='width: 100%; border-collapse: collapse;'>
					<thead>
						<tr style='background-color: #f8f9fa;'>
							<th style='width: 30%; text-align: left; padding: 8px;'>File Name</th>
							<th style='text-align: left; padding: 8px;'>Summary</th>
						</tr>
					</thead>
						<tr style='border-bottom: 1px solid #eee;'>
							<td style='padding: 8px;'><b><a href='/package/cli/calc_cfz.py'>calc_cfz.py</a></b></td>
							<td style='padding: 8px;'>Calculates the critical focal zone (CFZ) based on f-ratio and wavelength, defaulting to a wavelength of 0.5 micrometers if not provided.</td>
						</tr>
					</table>
				</blockquote>
			</details>
		</blockquote>
	</details>
</details>

---

## Getting Started

### Prerequisites

This project requires the following dependencies:

- **Programming Language:** Shell
- **Package Manager:** Pip

### Installation

Build  from the source and intsall dependencies:

1. **Clone the repository:**

    ```sh
    ❯ git clone ../
    ```

2. **Navigate to the project directory:**

    ```sh
    ❯ cd 
    ```

3. **Install the dependencies:**

<!-- SHIELDS BADGE CURRENTLY DISABLED -->
	<!-- [![pip][pip-shield]][pip-link] -->
	<!-- REFERENCE LINKS -->
	<!-- [pip-shield]: None -->
	<!-- [pip-link]: None -->

	**Using [pip](None):**

	```sh
	❯ echo 'INSERT-INSTALL-COMMAND-HERE'
	```

### Usage

Run the project with:

**Using [pip](None):**
```sh
echo 'INSERT-RUN-COMMAND-HERE'
```

### Testing

 uses the {__test_framework__} test framework. Run the test suite with:

**Using [pip](None):**
```sh
echo 'INSERT-TEST-COMMAND-HERE'
```

---

## Roadmap

- [X] **`Task 1`**: <strike>Implement feature one.</strike>
- [ ] **`Task 2`**: Implement feature two.
- [ ] **`Task 3`**: Implement feature three.

---

## Contributing

- **💬 [Join the Discussions](https://LOCAL///discussions)**: Share your insights, provide feedback, or ask questions.
- **🐛 [Report Issues](https://LOCAL///issues)**: Submit bugs found or log feature requests for the `` project.
- **💡 [Submit Pull Requests](https://LOCAL///blob/main/CONTRIBUTING.md)**: Review open PRs, and submit your own PRs.

<details closed>
<summary>Contributing Guidelines</summary>

1. **Fork the Repository**: Start by forking the project repository to your LOCAL account.
2. **Clone Locally**: Clone the forked repository to your local machine using a git client.
   ```sh
   git clone .
   ```
3. **Create a New Branch**: Always work on a new branch, giving it a descriptive name.
   ```sh
   git checkout -b new-feature-x
   ```
4. **Make Your Changes**: Develop and test your changes locally.
5. **Commit Your Changes**: Commit with a clear message describing your updates.
   ```sh
   git commit -m 'Implemented new feature x.'
   ```
6. **Push to LOCAL**: Push the changes to your forked repository.
   ```sh
   git push origin new-feature-x
   ```
7. **Submit a Pull Request**: Create a PR against the original project repository. Clearly describe the changes and their motivations.
8. **Review**: Once your PR is reviewed and approved, it will be merged into the main branch. Congratulations on your contribution!
</details>

<details closed>
<summary>Contributor Graph</summary>
<br>
<p align="left">
   <a href="https://LOCAL{///}graphs/contributors">
      <img src="https://contrib.rocks/image?repo=/">
   </a>
</p>
</details>

---

## License

 is protected under the [LICENSE](https://choosealicense.com/licenses) License. For more details, refer to the [LICENSE](https://choosealicense.com/licenses/) file.

---

## Acknowledgments

- Credit `contributors`, `inspiration`, `references`, etc.

<div align="right">

[![][back-to-top]](#top)

</div>


[back-to-top]: https://img.shields.io/badge/-BACK_TO_TOP-151515?style=flat-square


---
