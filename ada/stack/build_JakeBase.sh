#!/usr/bin/env bash
# > cd ~ && git clone https://github.com/dvandagriff/adalovespace
# > cd adalovespace && ./ada/stack/build_JakeBase.sh

set -euxo pipefail

# // Configuration (loaded via preflight → TOML or legacy .env)
source ./ada/lib/ada-preflight.sh "$BASH_SOURCE"

# // Sys Core Build
"${ADACODESPACE}/ada/core/build.sh" "rpi"


# ==============================================================================
# JakeBase Core Build
# ==============================================================================

# // NFS
sudo apt install nfs-kernel-server -y

sudo mkdir -p "$NFS_ROOT"
sudo mkdir -p "$NFS_CODE"
sudo mkdir -p "$NFS_LOGS"
sudo mkdir -p "$NFS_SHARE"

sudo ln -s "$ADA_CODESPACE" "$NFS_CODE/adalovespace"

sudo chown -R nobody:nogroup "$NFS_ROOT"
sudo chmod -R 777 "$NFS_ROOT"

safe-tee-sed /etc/exports "^$NFS_ROOT" "$NFS_ROOT *(rw,sync,no_subtree_check,all_squash,insecure)" "yes"

sudo exportfs -a
sudo systemctl restart nfs-kernel-server

# // PSQL
sudo apt install postgresql postgresql-contrib -y

# Update listen_addresses to allow remote connections
PG_LISTEN="listen_addresses = '*'"
shopt -s nullglob
pgconf_files=(/etc/postgresql/*/main/postgresql.conf)
shopt -u nullglob
if [[ ${#pgconf_files[@]} -gt 0 ]]; then
    for pgconf in "${pgconf_files[@]}"; do
        # Try to replace the default commented localhost setting
        sudo sed -i "s/#listen_addresses = 'localhost'/$PG_LISTEN/" "$pgconf"
        # If no uncommented listen_addresses exists yet, uncomment any commented variant
        if ! grep -q '^listen_addresses' "$pgconf"; then
            sudo sed -i "/^# *listen_addresses/c\\    ${PG_LISTEN}" "$pgconf"
        fi
    done
fi

# Add md5 auth rule for external connections to pg_hba.conf (before peer rules)
shopt -s nullglob
pghba_files=(/etc/postgresql/*/main/pg_hba.conf)
shopt -u nullglob
if [[ ${#pghba_files[@]} -gt 0 ]]; then
    entry="host    all             all             0.0.0.0/0               md5"
    for pghba in "${pghba_files[@]}"; do
        safe-tee-sed "$pghba" "$entry" "$entry" "yes"
        # Allow local socket connections via md5 too (so psql -U works with sudo -u postgres)
        sudo sed -i 's/^local  \+all  \+all  \+peer/local    all             all                                     md5/' "$pghba"
    done
fi

# Restart to apply pg_hba.conf and listen_addresses changes
sudo systemctl restart postgresql

# Verify postgres is running and ready
sleep 2
sudo -u postgres psql -c "SELECT 1" > /dev/null

# Create application users
sudo -u postgres psql << EOF
CREATE USER $PSQL_SERVICE_USER WITH PASSWORD '$PSQL_SERVICE_PASSWORD';
CREATE USER $PSQL_COURIER_USER WITH PASSWORD '$PSQL_COURIER_PASSWORD';
CREATE DATABASE $PSQL_DB_NAME;
\c $PSQL_DB_NAME;
EOF

for TOPIC in $MQTT_SUB_TOPICS; do
    TBL="$TOPIC.$PSQL_TBL_NAME"
    sudo -u postgres psql << EOF
CREATE SCHEMA IF NOT EXISTS $TOPIC;
GRANT USAGE ON SCHEMA $TOPIC TO $PSQL_SERVICE_USER, $PSQL_COURIER_USER;
CREATE TABLE IF NOT EXISTS $TBL (
    id BIGSERIAL PRIMARY KEY,
    topic TEXT NOT NULL,
    ${PSQL_MQTT_DEST_FLD} JSONB NOT NULL,
    qos SMALLINT,
    ${PSQL_MQTT_TIMESTAMP_FLD} TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_${TOPIC}_time ON $TBL($PSQL_MQTT_TIMESTAMP_FLD);
EOF
done

for TOPIC in $MQTT_SUB_TOPICS; do
    TBL="$TOPIC.$PSQL_TBL_NAME"
    sudo -u postgres psql << EOF
GRANT SELECT, INSERT, UPDATE ON $TBL TO $PSQL_SERVICE_USER;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA $TOPIC TO $PSQL_SERVICE_USER;
GRANT SELECT, TRUNCATE ON $TBL TO $PSQL_COURIER_USER;
ALTER DEFAULT PRIVILEGES FOR ROLE $PSQL_SERVICE_USER IN SCHEMA $TOPIC
GRANT SELECT, TRUNCATE ON TABLES TO $PSQL_COURIER_USER;
EOF
done

sudo systemctl restart postgresql

# // MQTT
sudo apt install mosquitto mosquitto-clients -y
sudo systemctl enable --now mosquitto
echo -e "listener $MQTT_PORT\nallow_anonymous true" | sudo tee /etc/mosquitto/conf.d/astrolab.conf
sudo systemctl restart mosquitto

# // TELEGRAF
# Debian Bookworm includes Telegraf in its default apt mirrors,
# the upstream InfluxData repository contains critical
# connection-retry bugfixes for the PostgreSQL output driver
# Import the official InfluxData GPG repository key
curl -s https://repos.influxdata.com/influxdata-archive_compat.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/influxdata-archive_compat.gpg > /dev/null
echo "deb [signed-by=/etc/apt/trusted.gpg.d/influxdata-archive_compat.gpg] https://repos.influxdata.com/debian stable main" | sudo tee /etc/apt/sources.list.d/influxdata.list
sudo apt install telegraf -y
target_conf=/etc/telegraf/telegraf.conf
# Group the initialization core and template generation into a single execution stream
{
    cat << EOF
# Generated automatically by JakeBase build script
# Configuration Date: $(date '+%Y-%m-%d %H:%M:%S')

# ======================================================================
# GLOBAL AGENT TUNING
# ======================================================================
[agent]
  interval = "${TG_INTERVAL:-1s}"
  flush_interval = "${TG_FLUSH_INTERVAL:-1s}"
  omit_hostname = ${TG_OMIT_HOSTNAME:-false}
  metric_batch_size = ${TG_METRIC_BATCH_SIZE:-500}
  metric_buffer_limit = ${TG_METRIC_BUFFER_LIMIT:-10000}

# ======================================================================
# INGESTION SOURCES (Topic-Specific Consumers)
# ======================================================================
EOF

    # Dynamically inject an input target structure for every active subsystem domain topic
    for TOPIC in $MQTT_SUB_TOPICS; do
        cat << EOF

# // $TOPIC consumer proxy
[[inputs.mqtt_consumer]]
  servers = ["tcp://127.0.0.1:1883"]
  topics = ["$MQTT_ROOT_TOPIC/$TOPIC/#"]
  data_format = "value"
  data_type = "string"
  name_override = "route_$TOPIC"
EOF
    done

    cat << EOF

# ======================================================================
# IN-MEMORY PROCESSORS (Column Mapping)
# ======================================================================
[[processors.rename]]
  [[processors.rename.replace]]
    field = "value"
    dest = "$PSQL_MQTT_DEST_FLD"

# ======================================================================
# STORAGE SINKS (Schema-Routed Outputs)
# ======================================================================
EOF

    # Dynamically map the target outputs into isolated relational schemas inside Postgres
    for TOPIC in $MQTT_SUB_TOPICS; do
        cat << EOF

# // $TOPIC target data lake route
[[outputs.postgresql]]
  connection = "host=127.0.0.1 user=$PSQL_SERVICE_USER password=$PSQL_SERVICE_PASSWORD dbname=$PSQL_DB_NAME sslmode=disable"
  schema = "$TOPIC"
  table_name = "${PSQL_TBL_NAME:-staging}"
  timestamp_column = "$PSQL_MQTT_TIMESTAMP_FLD"
  namepass = ["route_$TOPIC"]
EOF
    done
} | sudo tee "$target_conf" > /dev/null

sudo systemctl restart telegraf

# // NTFY
sudo apt install ntfy -y

sudo apt update -y
sudo apt full-update -y
sudo apt autoremove -y
sudo apt autoclean -y

echo -n "Reboot? [y/N] " && read -r -t 30 yn
if [[ "${yn,,}" == y ]]; then
    sudo reboot
fi

# // Copyright 2026 Drew Vandagriff
# //
# // Licensed under the Apache License, Version 2.0 <LICENSE-APACHE or
# // http://www.apache.org/licenses/LICENSE-2.0> or the MIT license
# // <LICENSE-MIT or http://opensource.org/licenses/MIT>, at your
# // option. This file may not be copied, modified, or distributed
# // except according to those terms.
