#!/bin/bash
"""
Step 1: Spin up the "Data Engine" LXC on Coffeecan

Instead of cluttering Coffeecan's base OS or spinning up a heavy VM, we use an LXC.

    Create the LXC: In your Proxmox GUI, spin up a new Ubuntu 24.04 LXC. Give it 4-8 cores and 8GB of RAM (plenty for Dagster and SQLMesh).

    Mount the RAID: You need to pass your massive hardware RAID storage through to this container so SQLMesh can write to the Data Lake. You'll do this by editing the LXC's config file in Proxmox (nano /etc/pve/lxc/YOUR_VM_ID.conf) and adding a bind mount point:
    mp0: /path/to/proxmox/raid,mp=/mnt/datalake

    Start the LXC and SSH in.
"""
BASEDIR=${HOME}/adalovespace/buildscripts

# Install uv
${BASEDIR}/lib/debian/install_uv_root.sh

# Create a directory for your pipeline
mkdir -p /opt/ada_pipeline && cd /opt/ada_pipeline

# Initialize a uv project and virtual environment
uv venv && source .venv/bin/activate

# Install Dagster, SQLMesh, and the official bridge between them
uv pip install dagster dagster-webserver sqlmesh dagster-sqlmesh psycopg2-binary

# Initialize the SQLMesh project inside the pipeline folder
sqlmesh init -t postgres

# Create the Dagster repository file
touch repository.py
