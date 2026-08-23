#!/usr/bin/env bash
# ==============================================================================
# Ada Lovespace — JakeBase Data Broker Build Script
# Standalone one-shot installer for a centralized data broker node.
#
# Usage:
#   ssh into the target node, then:
#     cd ~ && git clone https://github.com/dvandagriff/adalovespace
#     cd adalovespace && ./ada/stack/build_JakeBase.sh
#
# Pre-flight requirement: your user must have passwordless sudo. If it doesn't,
# this script will prompt you to add the rule before continuing.
# ==============================================================================

set -euo pipefail

# ==============================================================================
# 0. Global Logging Helpers
# ==============================================================================

log_ok()   { printf '[OK]   %s\n' "$*"; }
log_step() { printf '\n[%-20s] %s\n' "STEP" "$*"; }
log_warn() { printf '[WARN] %s\n' "$*" >&2; }

# ==============================================================================
# 1. Root Check & Repo Resolution
# ==============================================================================

if [[ "$(id -u)" -ne 0 ]]; then
    echo "FATAL: This script requires root privileges (run with sudo or as root)." >&2
    exit 1
fi

# Determine repo root by walking up from current directory until .git is found.
REPO_DIR="$(pwd)"
while [[ "$REPO_DIR" != "/" ]] && [[ ! -d "$REPO_DIR/.git" ]]; do
    REPO_DIR="$(dirname "$REPO_DIR")"
done

if [[ "$REPO_DIR" == "/" ]]; then
    echo "FATAL: Could not find .git — run this script from inside the cloned repo." >&2
    exit 1
fi

CONFIG_TOML="${REPO_DIR}/ada/ada_config.toml"

if [[ ! -f "$CONFIG_TOML" ]]; then
    echo "FATAL: Configuration file not found at $CONFIG_TOML" >&2
    exit 1
fi

# ==============================================================================
# 2. Config Loading — parse TOML into bash variables via python3 (tomllib)
# ==============================================================================

if ! command -v python3 &>/dev/null; then
    echo "FATAL: python3 is required for config loading. Install it first:" >&2
    echo "  sudo apt update && sudo apt install python3 -y" >&2
    exit 1
fi

eval "$(python3 - "$CONFIG_TOML" <<'PYEOF'
import sys, tomllib

path = sys.argv[1]
with open(path, "rb") as f:
    cfg = tomllib.load(f)

for key, val in sorted(cfg.items()):
    var = key.upper().replace("-", "_")

    if isinstance(val, bool):
        print(f'export {var}="{str(val).lower()}"')
    elif isinstance(val, int):
        print(f'export {var}="{val}"')
    elif isinstance(val, list):
        print(f'export {var}="{" ".join(str(v) for v in val)}"')
    else:
        print(f'export {var}="{val}"')
PYEOF
)"

# Validate critical variables loaded from config
REQUIRED_VARS=(NFS_ROOT NFS_CODE NFS_LOGS NFS_SHARE PSQL_DB_NAME PSQL_SERVICE_USER \
               PSQL_SERVICE_PASSWORD PSQL_COURIER_USER PSQL_COURIER_PASSWORD MQTT_ROOT_TOPIC \
               MQTT_SUB_TOPICS MQTT_PORT TG_INTERVAL TG_FLUSH_INTERVAL TG_OMIT_HOSTNAME \
               TG_METRIC_BATCH_SIZE TG_METRIC_BUFFER_LIMIT PSQL_TBL_NAME PSQL_MQTT_DEST_FLD \
               PSQL_MQTT_TIMESTAMP_FLD)

missing=()
for var in "${REQUIRED_VARS[@]}"; do
    if [[ -z "${!var:-}" ]]; then
        missing+=("$var")
    fi
done

if [[ ${#missing[@]} -gt 0 ]]; then
    echo "FATAL: Missing config variables: ${missing[*]}" >&2
    exit 1
fi

log_ok "Configuration loaded from ada_config.toml"

# ==============================================================================
# 3. NOPASSWD Sudo Setup (admin user)
# ==============================================================================

ADMIN_USER="$(whoami)"
SUDOERS_RULE="${ADMIN_USER} ALL=(ALL) NOPASSWD: ALL"
SUDOERS_TMP="/tmp/adalovespace-sudoers-$$"
SUDOERS_D_FILE="/etc/sudoers.d/99-adalovespace-nopasswd"

# Check whether NOPASSWD sudo already exists for this user (ignoring comments)
_has_nopasswd() {
    # Main sudoers file — strip comments, match rule
    if grep -v '^\s*#' /etc/sudoers 2>/dev/null | grep -qF "$SUDOERS_RULE"; then
        return 0
    fi
    # Drop-in directory — same check
    for f in /etc/sudoers.d/*; do
        [[ -f "$f" ]] || continue
        if grep -v '^\s*#' "$f" 2>/dev/null | grep -qF "$SUDOERS_RULE"; then
            return 0
        fi
    done
    return 1
}

if _has_nopasswd; then
    log_ok "NOPASSWD sudo already configured for $ADMIN_USER"
else
    log_warn "NOPASSWD sudo not found for $ADMIN_USER."
    echo ""
    echo "The build script requires passwordless sudo to run non-interactively."
    echo "Add the following rule before continuing:"
    echo ""
    echo "  sudo visudo -f /etc/sudoers.d/99-adalovespace-nopasswd"
    echo "  # Add this line:"
    echo "  ${SUDOERS_RULE}"
    echo ""
    log_warn "Pausing — press Enter after adding the rule, or Ctrl+C to abort."
    read -r _pause
fi

log_ok "Proceeding with NOPASSWD sudo for $ADMIN_USER"

# ==============================================================================
# 4. Service User Creation (adanaut)
# ==============================================================================

log_step "Service user: $adausr_srv"

if id "$adausr_srv" &>/dev/null; then
    log_ok "Service user '$adausr_srv' already exists — skipping"
else
    useradd --create-home --shell /bin/bash "$adausr_srv"
    log_ok "Created service user '$adausr_srv'"
fi

# ==============================================================================
# 5. NFS Host
# ==============================================================================

log_step "NFS host server"

# Install package
sudo apt install -y nfs-kernel-server

# Create export directories
for d in "$NFS_ROOT" "$NFS_CODE" "$NFS_LOGS" "$NFS_SHARE"; do
    if [[ ! -d "$d" ]]; then
        sudo mkdir -p "$d"
        log_ok "Created NFS directory: $d"
    else
        log_ok "NFS directory already exists: $d"
    fi
done

# Chown/chmod the root export tree — all_squash maps everything to nobody:nogroup
sudo chown -R nobody:nogroup "$NFS_ROOT"
sudo chmod -R 777 "$NFS_ROOT"

# Symlink repo code into NFS share (idempotent)
CODE_LINK="${NFS_CODE}/adalovespace"
if [[ -L "$CODE_LINK" ]]; then
    # Fix broken symlinks and recreate if target changed
    if [[ ! -e "$CODE_LINK" ]]; then
        sudo rm -f "$CODE_LINK"
        sudo ln -sf "$REPO_DIR" "$CODE_LINK"
        log_ok "Fixed broken NFS code symlink: $CODE_LINK -> $REPO_DIR"
    fi
elif [[ ! -d "$CODE_LINK" ]]; then
    sudo ln -sf "$REPO_DIR" "$CODE_LINK"
    log_ok "Created NFS code symlink: $CODE_LINK -> $REPO_DIR"
else
    log_ok "NFS code link already configured: $CODE_LINK"
fi

# Write /etc/exports entry (idempotent — only append if not present)
EXPORT_LINE="${NFS_ROOT} *(rw,sync,no_subtree_check,all_squash,insecure)"
if grep -qF "$NFS_ROOT" /etc/exports 2>/dev/null; then
    log_ok "NFS export already present in /etc/exports — skipping"
else
    echo "$EXPORT_LINE" | sudo tee -a /etc/exports > /dev/null
    log_ok "Added NFS export to /etc/exports"
fi

sudo exportfs -ra
sudo systemctl restart nfs-kernel-server
sudo systemctl enable nfs-kernel-server
log_ok "NFS host server ready"

# ==============================================================================
# 6. PostgreSQL
# ==============================================================================

log_step "PostgreSQL database"

# Detect installed PG version (Debian package naming: postgresql-15, postgresql-16, etc.)
PG_VERSION="$(ls /etc/postgresql/ | tail -n1)"
if [[ -z "$PG_VERSION" ]]; then
    sudo apt install -y postgresql
fi

PG_CONF="/etc/postgresql/${PG_VERSION}/main/postgresql.conf"
PG_HBA="/etc/postgresql/${PG_VERSION}/main/pg_hba.conf"

# Update listen_addresses for remote connections (idempotent)
sudo sed -i "s/^#\?listen_addresses\s*=.*/listen_addresses = '*'/g" "$PG_CONF"
log_ok "PostgreSQL configured for remote access (listen_addresses = '*')"

# Update pg_hba.conf: scram-sha-256 for remote and local socket connections.

HBA_REMOTE_RULE="host    all             all             0.0.0.0/0               scram-sha-256"
HBA_LOCAL_RULE="local   all             all                                     scram-sha-256"

if ! grep -qF "0.0.0.0" "$PG_HBA"; then
    echo "" >> "$PG_HBA"
    echo "# Ada Lovespace — generated by build script" >> "$PG_HBA"
    echo "$HBA_REMOTE_RULE" >> "$PG_HBA"
    log_ok "Added remote scram-sha-256 auth rule to pg_hba.conf"
else
    log_ok "Remote scram-sha-256 auth already present in pg_hba.conf"
fi

if ! grep -qxF "$HBA_LOCAL_RULE" "$PG_HBA"; then
    # Replace peer with scram-sha-256 for local socket connections
    sudo sed -i \
        's/^local\s\+all\s\+all\s\+peer/local   all             all                                     scram-sha-256/' \
        "$PG_HBA"
    if grep -qxF "$HBA_LOCAL_RULE" "$PG_HBA"; then
        log_ok "Local socket auth switched to scram-sha-256 in pg_hba.conf"
    else
        log_warn "Could not update local socket auth — peer may still be in use"
    fi
else
    log_ok "Local scram-sha-256 auth already present in pg_hba.conf"
fi

# Start PostgreSQL
sudo systemctl enable postgresql
sudo systemctl restart postgresql

# Wait for PG to accept connections (max 30s)
log_ok "Waiting for PostgreSQL to start..."
for _i in $(seq 1 30); do
    if sudo -u postgres psql -c "SELECT 1" &>/dev/null; then
        break
    fi
    sleep 1
done

if ! sudo -u postgres psql -c "SELECT 1" &>/dev/null; then
    echo "FATAL: PostgreSQL failed to start within 30 seconds. Check logs:" >&2
    echo "  journalctl -u postgresql --no-pager -n 50" >&2
    exit 1
fi

log_ok "PostgreSQL is running"

# Set superuser password first (needed because we switched local auth to scram-sha-256)
sudo -u postgres psql -c \
    "ALTER USER postgres PASSWORD 'ChangeMeOnDeploy!';" || true

# Create application users and database (idempotent via DO blocks)
sudo -u postgres psql <<EOF
-- Users (skip if already exist — PostgreSQL errors out otherwise)
DO \$\$ BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '${PSQL_SERVICE_USER}') THEN
        CREATE USER ${PSQL_SERVICE_USER} WITH PASSWORD '${PSQL_SERVICE_PASSWORD}'
            ROLE postgres;
    END IF;
END \$\$;

DO \$\$ BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '${PSQL_COURIER_USER}') THEN
        CREATE USER ${PSQL_COURIER_USER} WITH PASSWORD '${PSQL_COURIER_PASSWORD}';
    END IF;
END \$\$;

-- Database (skip if already exists)
DO \$\$ BEGIN
    IF NOT EXISTS (SELECT FROM pg_database WHERE datname = '${PSQL_DB_NAME}') THEN
        CREATE DATABASE ${PSQL_DB_NAME};
    END IF;
END \$\$;
EOF

log_ok "PostgreSQL users and database created"

# Create per-topic schemas, tables, and grants (fully idempotent)
for TOPIC in $MQTT_SUB_TOPICS; do
    TBL="${TOPIC}.${PSQL_TBL_NAME}"

    sudo -u postgres psql <<EOF
\c ${PSQL_DB_NAME}

-- Schema + table (IF NOT EXISTS = safe to rerun)
CREATE SCHEMA IF NOT EXISTS "${TOPIC}";
GRANT USAGE ON SCHEMA "${TOPIC}" TO "${PSQL_SERVICE_USER}", "${PSQL_COURIER_USER}";

CREATE TABLE IF NOT EXISTS "${TOPIC}"."${PSQL_TBL_NAME}" (
    id              BIGSERIAL PRIMARY KEY,
    topic           TEXT NOT NULL,
    "${PSQL_MQTT_DEST_FLD}"   JSONB NOT NULL,
    qos             SMALLINT,
    "${PSQL_MQTT_TIMESTAMP_FLD}"  TIMESTAMPTZ DEFAULT NOW()
);

-- Index on timestamp for time-range queries (IF NOT EXISTS = safe)
CREATE INDEX IF NOT EXISTS idx_${TOPIC}_time
    ON "${TOPIC}"."${PSQL_TBL_NAME}"("${PSQL_MQTT_TIMESTAMP_FLD}");

-- Role grants
GRANT SELECT, INSERT, UPDATE ON "${TOPIC}"."${PSQL_TBL_NAME}" TO "${PSQL_SERVICE_USER}";
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA "${TOPIC}" TO "${PSQL_SERVICE_USER}";
GRANT SELECT, TRUNCATE ON "${TOPIC}"."${PSQL_TBL_NAME}" TO "${PSQL_COURIER_USER}";

-- Default privileges for FUTURE tables (postgres creates these, not the service user)
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA "${TOPIC}"
    GRANT SELECT, TRUNCATE ON TABLES TO "${PSQL_COURIER_USER}";
EOF
done

log_ok "Per-topic schemas and tables configured"

# Final restart to flush any lingering auth changes
sudo systemctl restart postgresql
sleep 2
log_ok "PostgreSQL setup complete"

# ==============================================================================
# 7. MQTT Broker (Mosquitto)
# ==============================================================================

log_step "MQTT broker — Mosquitto"

sudo apt install -y mosquitto mosquitto-clients
sudo systemctl enable mosquitto

# Write listener config (idempotent: skip if port already configured)
MOSQUITTO_CONF="/etc/mosquitto/conf.d/astrolab.conf"
if grep -q "listener ${MQTT_PORT}" "$MOSQUITTO_CONF" 2>/dev/null; then
    log_ok "Mosquitto listener on port $MQTT_PORT already configured — skipping"
else
    {
        echo "# Ada Lovespace — generated by build script"
        echo "listener ${MQTT_PORT}"
        echo "allow_anonymous true"
    } | sudo tee "$MOSQUITTO_CONF" > /dev/null
    log_ok "Mosquitto listener configured on port $MQTT_PORT (anonymous = true)"
fi

sudo systemctl restart mosquitto
log_ok "MQTT broker ready"

# ==============================================================================
# 8. Telegraf — MQTT → PostgreSQL Ingestion Pipeline
# ==============================================================================

log_step "Telegraf — MQTT to PostgreSQL ingestion"

# InfluxData upstream repo contains critical connection-retry bugfixes for the
# PostgreSQL output driver not present in distro packages.
GPG_KEY="/etc/apt/trusted.gpg.d/influxdata-archive-compat.gpg"
if [[ ! -f "$GPG_KEY" ]]; then
    curl -fsSL https://repos.influxdata.com/influxdata-archive_compat.key \
        | gpg --dearmor \
        | sudo tee "$GPG_KEY" > /dev/null
    log_ok "InfluxData GPG key installed"
else
    log_ok "InfluxData GPG key already present"
fi

INFLUX_LIST="/etc/apt/sources.list.d/influxdata.list"
if [[ ! -f "$INFLUX_LIST" ]] || ! grep -q "repos.influxdata.com" "$INFLUX_LIST"; then
    echo "deb [signed-by=${GPG_KEY}] https://repos.influxdata.com/debian stable main" \
        | sudo tee "$INFLUX_LIST" > /dev/null
    sudo apt update
    log_ok "InfluxData APT repository added"
else
    log_ok "InfluxData APT repository already configured"
fi

sudo apt install -y telegraf
log_ok "Telegraf installed"

# Build Telegraf configuration from config variables.
# The pipeline: mqtt_consumer (input) → processors.rename (column map)
# → outputs.postgresql (per-topic schema routing via namepass filters).
TARGET_CONF="/etc/telegraf/telegraf.conf"

{
    cat <<EOF
# ==============================================================================
# Telegraf Configuration — Generated by Ada Lovespace JakeBase Build Script
# Date: $(date '+%Y-%m-%d %H:%M:%S')
#
# Pipeline: MQTT → PostgreSQL (per-topic schema routing)
# ==============================================================================

[agent]
  interval              = "${TG_INTERVAL}"
  flush_interval        = "${TG_FLUSH_INTERVAL}"
  omit_hostname         = ${TG_OMIT_HOSTNAME}
  metric_batch_size     = ${TG_METRIC_BATCH_SIZE}
  metric_buffer_limit   = ${TG_METRIC_BUFFER_LIMIT}

# --------------------------------------------------------------------------
# INPUTS: MQTT Consumer (per-topic)
# --------------------------------------------------------------------------
EOF

    for TOPIC in $MQTT_SUB_TOPICS; do
        cat <<EOF

[[inputs.mqtt_consumer]]
  servers     = ["tcp://127.0.0.1:${MQTT_PORT}"]
  topics      = ["${MQTT_ROOT_TOPIC}/${TOPIC}/#"]
  data_format = "value"
  data_type   = "string"
  name_override = "route_${TOPIC}"
EOF
    done

    cat <<EOF

# --------------------------------------------------------------------------
# PROCESSOR: Rename "value" field → payload (matches PG table schema)
# --------------------------------------------------------------------------

[[processors.rename]]
  [[processors.rename.replace]]
    field = "value"
    dest  = "${PSQL_MQTT_DEST_FLD}"

# --------------------------------------------------------------------------
# OUTPUTS: PostgreSQL (per-topic via namepass filter)
# --------------------------------------------------------------------------
EOF

    for TOPIC in $MQTT_SUB_TOPICS; do
        cat <<EOF

[[outputs.postgresql]]
  connection     = "host=127.0.0.1 user=${PSQL_SERVICE_USER} password=${PSQL_SERVICE_PASSWORD} dbname=${PSQL_DB_NAME} sslmode=disable"
  schema         = "${TOPIC}"
  table_name     = "${PSQL_TBL_NAME}"
  timestamp_column = "${PSQL_MQTT_TIMESTAMP_FLD}"
  namepass       = ["route_${TOPIC}"]
EOF
    done

    cat <<EOF
EOF
} | sudo tee "$TARGET_CONF" > /dev/null

log_ok "Telegraf configuration written to $TARGET_CONF"

# Validate config before starting (fail fast on syntax errors)
if ! telegraf --test --config "$TARGET_CONF" &>/dev/null; then
    log_warn "telegraf --test reported issues — reviewing config..."
    echo "Config preview:"
    echo "---"
    sudo cat "$TARGET_CONF" | grep -v '^#' | grep -v '^$' || true
    echo "---"
    echo "Attempting to start anyway (Telegraf may be tolerant of some warnings)..."
else
    log_ok "Telegraf config validation passed"
fi

# Set ownership so the telegraf service user can read its own config
sudo chown telegraf:telegraf "$TARGET_CONF"
sudo chmod 644 "$TARGET_CONF"

sudo systemctl enable telegraf
sudo systemctl restart telegraf

log_ok "Telegraf pipeline ready"

# ==============================================================================
# 9. System Housekeeping
# ==============================================================================

log_step "System housekeeping"

sudo apt update -y
sudo apt full-upgrade -y
sudo apt autoremove -y
sudo apt autoclean -y
log_ok "Package cache cleaned"

# ==============================================================================
# 10. Summary
# ==============================================================================

echo ""
echo "==============================================================================="
echo "  JakeBase Build Complete"
echo "==============================================================================="
echo ""
echo "  NFS Host      → ${NFS_ROOT} (exports: $(sudo exportfs -v 2>/dev/null | grep -c ${NFS_ROOT:-/mnt/ada}) share(s))"
echo "  PostgreSQL    → ${PSQL_DB_NAME} (${PG_VERSION}, ${MQTT_SUB_TOPICS// /,} topics)"
echo "  MQTT Broker   → tcp://$(hostname -I | awk '{print $1}'):${MQTT_PORT} (anonymous)"
echo "  Telegraf      → ingesting mqtt → psql per-topic"
echo ""
echo "==============================================================================="
