#!/bin/bash

echo "=== Creating JakeBase PostgreSQL Host Core"
# Execute via peer authentication over the local UNIX socket
sudo -u postgres psql << 'EOF'

-- 1. Create the database and bind to it
CREATE DATABASE IF NOT EXISTS adaspace;
\c adaspace;

-- Scaffold the staging schema
CREATE SCHEMA IF NOT EXISTS telemetry;

-- Scaffold the core telemetry buffer table
CREATE TABLE IF NOT EXISTS telemetry.staging (
    id BIGSERIAL PRIMARY KEY,
    topic TEXT NOT NULL,
    payload JSONB NOT NULL,
    qos SMALLINT,
    msg_time TIMESTAMPTZ NOT NULL,
    insert_time TIMESTAMPTZ DEFAULT NOW()
);

-- Create an index on the timestamp for blistering fast time-delta FDW queries
CREATE INDEX IF NOT EXISTS idx_raw_telemetry_time ON telemetry.staging(msg_time);


-- =====================================================================
-- 2. CREATE COFFEE_COURIER (The Homelab Pull & Wipe Role)
-- =====================================================================
CREATE USER coffee_courier WITH PASSWORD 'coffeecourier';

GRANT CONNECT ON DATABASE jake_telemetry TO coffee_courier;
GRANT USAGE ON SCHEMA staging TO coffee_courier;

-- Allow Coffeecan to read rows and wipe the buffer clean
GRANT SELECT, TRUNCATE ON ALL TABLES IN SCHEMA staging TO coffee_courier;


-- =====================================================================
-- 3. CREATE FIELD_AGENT (The Local Telegraf Ingest Role)
-- =====================================================================
CREATE USER field_agent WITH PASSWORD 'fieldagent';

GRANT CONNECT ON DATABASE jake_telemetry TO field_agent;
GRANT USAGE ON SCHEMA staging TO field_agent;

-- Grant DDL rights so Telegraf/Python can dynamically spawn tables if needed
GRANT CREATE ON SCHEMA staging TO field_agent;

-- Grant standard DML write rights
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA staging TO field_agent;

-- Grant sequence rights so BIGSERIAL auto-incrementing Primary Keys work smoothly
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA staging TO field_agent;


-- =====================================================================
-- 4. INHERITANCE MAPPING (The Safety Bridge)
-- =====================================================================
-- CRITICAL: Ensure any future tables spawned by field_agent out in the dark
-- can be immediately read and wiped clean by coffee_courier back in the garage.

ALTER DEFAULT PRIVILEGES FOR ROLE field_agent IN SCHEMA staging
GRANT SELECT, TRUNCATE ON TABLES TO coffee_courier;

EOF
