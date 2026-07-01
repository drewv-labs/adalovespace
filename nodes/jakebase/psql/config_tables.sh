#!/bin/bash
set -euxo pipefail

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" >&2
    exit 1
fi

# Assumes database and users already created...
#
source ${HOME}/adalovespace/cluster.conf

echo "=== Configuring JakeBase PostgreSQL Host Tables"

{

    cat << EOF

-- # Generated automatically by JakeBase build script
-- # Configuration Date: $(date '+%Y-%m-%d %H:%M:%S')
\c ${PSQL_DB_NAME};
EOF

    for TOPIC in ${MQTT_TOPICS}; do
        TBL="${TOPIC}.${PSQL_TBL_NAME}"
        cat << EOF

CREATE SCHEMA IF NOT EXISTS ${TOPIC};
GRANT USAGE ON SCHEMA ${TOPIC} TO field_agent, coffee_courier;

CREATE TABLE IF NOT EXISTS ${TBL} (
    id BIGSERIAL PRIMARY KEY,
    topic TEXT NOT NULL,
    ${PSQL_MQTT_DEST_FLD} JSONB NOT NULL,
    qos SMALLINT,
    ${PSQL_MQTT_TIMESTAMP_FLD} TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_${TOPIC}_time ON ${TBL}(${PSQL_MQTT_TIMESTAMP_FLD});

GRANT SELECT, INSERT, UPDATE ON ${TBL} TO field_agent;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA ${TOPIC} TO field_agent;
GRANT SELECT, TRUNCATE ON ${TBL} TO coffee_courier;

ALTER DEFAULT PRIVILEGES FOR ROLE field_agent IN SCHEMA ${TOPIC}
GRANT SELECT, TRUNCATE ON TABLES TO coffee_courier;
EOF
    done

} | sudo -u postgres psql > /dev/null
echo ""
