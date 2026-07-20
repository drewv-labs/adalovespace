#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "$BASH_SOURCE"

target_conf=/etc/telegraf/telegraf.conf

ada-log mod "=== Generating Dynamic Telegraf Schema Mappings ==="

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
  connection = "host=127.0.0.1 user=$PSQL_CLUSTER_USER password=$PSQL_CLUSTER_PASSWORD dbname=$PSQL_DB_NAME sslmode=disable"
  schema = "$TOPIC"
  table_name = "${PSQL_TBL_NAME:-staging}"
  timestamp_column = "$PSQL_MQTT_TIMESTAMP_FLD"
  namepass = ["route_$TOPIC"]
EOF
    done

} | sudo tee "$target_conf" > /dev/null

sudo systemctl restart telegraf
