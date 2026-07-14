#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight ${BASH_SOURCE[0]}

ada-log "mod" "=== Configuring JakeBase PostgreSQL Host"

sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" /etc/postgresql/*/main/postgresql.conf
entry="host    all             all             0.0.0.0/0               md5"

safe-tee-sed "/etc/postgresql/*/main/pg_hba.conf" "^${entry}" "$entry" "yes"

sudo psql -U postgres > /dev/null << EOF
CREATE USER ${PSQL_CLUSTER_USER} WITH PASSWORD '${PSQL_CLUSTER_PASSWORD}';
CREATE USER ${PSQL_COURIER_USER} WITH PASSWORD '${PSQL_COURIER_PASSWORD}';

CREATE DATABASE ${PSQL_DB_NAME};
\c ${PSQL_DB_NAME};
EOF
for TOPIC in ${MQTT_SUB_TOPICS}; do
    TBL="${TOPIC}.${PSQL_TBL_NAME}"
    cat << EOF | sudo psql -U postgres > /dev/null

CREATE SCHEMA IF NOT EXISTS ${TOPIC};
GRANT USAGE ON SCHEMA ${TOPIC} TO ${PSQL_CLUSTER_USER}, ${PSQL_COURIER_USER};

CREATE TABLE IF NOT EXISTS ${TBL} (
    id BIGSERIAL PRIMARY KEY,
    topic TEXT NOT NULL,
    ${PSQL_MQTT_DEST_FLD} JSONB NOT NULL,
    qos SMALLINT,
    ${PSQL_MQTT_TIMESTAMP_FLD} TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_${TOPIC}_time ON ${TBL}(${PSQL_MQTT_TIMESTAMP_FLD});
EOF
done

for TOPIC in ${MQTT_SUB_TOPICS}; do
    TBL="${TOPIC}.${PSQL_TBL_NAME}"
    cat << EOF | sudo psql -U postgres > /dev/null

GRANT SELECT, INSERT, UPDATE ON ${TBL} TO ${PSQL_CLUSTER_USER};
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA ${TOPIC} TO ${PSQL_CLUSTER_USER};
GRANT SELECT, TRUNCATE ON ${TBL} TO ${PSQL_COURIER_USER};

ALTER DEFAULT PRIVILEGES FOR ROLE ${PSQL_CLUSTER_USER} IN SCHEMA ${TOPIC}
GRANT SELECT, TRUNCATE ON TABLES TO ${PSQL_COURIER_USER};
EOF
done

sudo systemctl restart postgresql
echo ""
