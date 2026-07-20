#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "$BASH_SOURCE[0]"

ada-log "mod" "=== Installing Telegraf"

# Debian Bookworm includes Telegraf in its default apt mirrors,
# the upstream InfluxData repository contains critical
# connection-retry bugfixes for the PostgreSQL output driver

# Import the official InfluxData GPG repository key
curl -s https://repos.influxdata.com/influxdata-archive_compat.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/influxdata-archive_compat.gpg > /dev/null
echo "deb [signed-by=/etc/apt/trusted.gpg.d/influxdata-archive_compat.gpg] https://repos.influxdata.com/debian stable main" | sudo tee /etc/apt/sources.list.d/influxdata.list

sudo apt install telegraf -y
echo ""
