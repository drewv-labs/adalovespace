-- ==============================================================================
-- 1. Heartbeats (Cluster Health)
-- ==============================================================================
CREATE TABLE node_heartbeats (
    node VARCHAR(50) NOT NULL,
    status VARCHAR(20) DEFAULT 'online',
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Optimized for: SELECT node, MAX(timestamp) FROM node_heartbeats GROUP BY node;
CREATE INDEX idx_heartbeats_node_time
ON node_heartbeats (node, timestamp DESC);

-- ==============================================================================
-- 2. Time-Series Metrics (Thermals, CPU, Guide RMS)
-- ==============================================================================
CREATE TABLE node_metrics (
    node VARCHAR(50) NOT NULL,
    metric VARCHAR(50) NOT NULL,
    value DOUBLE PRECISION NOT NULL,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Optimized for: SELECT timestamp, value FROM node_metrics WHERE node = $1 AND metric = $2 ORDER BY timestamp DESC;
CREATE INDEX idx_metrics_lookup
ON node_metrics (node, metric, timestamp DESC);

-- ==============================================================================
-- 3. Complex Events (JSON Payloads)
-- ==============================================================================
-- Use this when CarrierPigeons needs to dump a complex PHD2 state or Hailo inference result
-- that doesn't fit neatly into a single float value.
CREATE TABLE telemetry_events (
    id BIGSERIAL PRIMARY KEY,
    node VARCHAR(50) NOT NULL,
    event_type VARCHAR(50) NOT NULL,
    payload JSONB NOT NULL,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- B-Tree for time-based filtering
CREATE INDEX idx_events_node_time
ON telemetry_events (node, timestamp DESC);

-- GIN index allows fast querying inside the JSON keys
CREATE INDEX idx_events_payload
ON telemetry_events USING GIN (payload);
