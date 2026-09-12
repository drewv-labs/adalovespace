#!/usr/bin/env bash
set -euo pipefail
sudo apt install mosquitto -y
sudo systemctl enable --now mosquitto
