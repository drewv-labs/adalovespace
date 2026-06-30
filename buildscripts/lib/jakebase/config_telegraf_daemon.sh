#!/bin/bash

source ${HOME}/adalovespace/cluster.conf

echo "=== Generating Dynamic Telegraf Schema Mappings"

{
    echo "# Generated automatically by Jakebase build script"
    echo ""

    echo "# ======================================================================"
    echo "# GLOBAL AGENT TUNING"
    echo "# ======================================================================"
    echo "[agent]"
    echo "\tinterval = \"${TG_INTERVAL}\""
    echo "\tflush_interval = \"${TG_FLUSH_INTERVAL}\""
    echo "\tomit_hostname = ${TG_OMIT_HOSTNAME}"
    echo ""

    echo "# ======================================================================"
    echo "# IN-MEMORY PROCESSORS (Column Mapping)"
    echo "# ======================================================================"
    echo "[[processors.rename]]"
    echo "\t[[processors.rename.replace]]"
    echo "\t\tfield = \"value\""
    echo "\t\tdest = \"${PSQL_MQTT_DEST_FLD}\""
    echo ""

    echo "# ======================================================================"
    echo "# INGESTION SOURCES (Topic-Specific Consumers)"
    echo "# ======================================================================"
    echo ""
    for TOPIC in ${MQTT_TOPICS}; do
        echo "# // ${TOPIC} consumer"
        echo "[[inputs.mqtt_consumer]]"
        echo "\tservers = [\"tcp://127.0.0.1:1883\"]"
        echo "\ttopics = [\"${MQTT_ROOT_TOPIC}/${TOPIC}/#\"]"
        echo "\tdata_format = \"value\""
        echo "\tdata_type = \"string\""
        echo "\tname_override = \"route_${TOPIC}\""
        echo ""
    done
    echo ""

    echo "# ======================================================================"
    echo "# STORAGE SINKS (Schema-Routed Outputs)"
    echo "# ======================================================================"
    echo ""
    for TOPIC in ${MQTT_TOPICS}; do
        echo "# // ${TOPIC} route"
        echo "[[outputs.postgresql]]"
        echo "\tconnection = \"host=127.0.0.1 user=${PSQL_FIELD_USER} password=${PSQL_FIELD_PASSWORD} dbname=${PSQL_DB_NAME} sslmode=disable\""
        echo "\tschema = \"${TOPIC}\""
        echo "\ttable_name = \"${PSQL_TBL_NAME}\""
        echo "\ttimestamp_column = \"${PSQL_MQTT_TIMESTAMP_FLD}\""
        echo "\tnamepass = [\"route_${TOPIC}\"]"
    done
    echo ""

} | sudo tee /etc/telegraf/telegraf.conf


echo ""
