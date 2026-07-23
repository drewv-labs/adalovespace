#!/usr/bin/env bash
set -euxo pipefail
source ada-preflight "$BASH_SOURCE"

ada-log mod "=== Configuring JakeBase PostgreSQL Host"

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
CREATE USER $PSQL_CLUSTER_USER WITH PASSWORD '$PSQL_CLUSTER_PASSWORD';
CREATE USER $PSQL_COURIER_USER WITH PASSWORD '$PSQL_COURIER_PASSWORD';

CREATE DATABASE $PSQL_DB_NAME;
\c $PSQL_DB_NAME;
EOF

for TOPIC in $MQTT_SUB_TOPICS; do
    TBL="$TOPIC.$PSQL_TBL_NAME"
    sudo -u postgres psql << EOF
CREATE SCHEMA IF NOT EXISTS $TOPIC;
GRANT USAGE ON SCHEMA $TOPIC TO $PSQL_CLUSTER_USER, $PSQL_COURIER_USER;

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
GRANT SELECT, INSERT, UPDATE ON $TBL TO $PSQL_CLUSTER_USER;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA $TOPIC TO $PSQL_CLUSTER_USER;
GRANT SELECT, TRUNCATE ON $TBL TO $PSQL_COURIER_USER;

ALTER DEFAULT PRIVILEGES FOR ROLE $PSQL_CLUSTER_USER IN SCHEMA $TOPIC
GRANT SELECT, TRUNCATE ON TABLES TO $PSQL_COURIER_USER;
EOF
done

sudo systemctl restart postgresql
