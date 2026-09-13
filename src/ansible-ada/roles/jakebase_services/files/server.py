import json
import os
from typing import Any

import aiomqtt
import asyncpg
from mcp.server.fastmcp import FastMCP

# Initialize the FastMCP server
mcp = FastMCP("JakeBase-Cluster-Gateway")

# Environment variables (configured in your systemd service)
PG_DSN = os.getenv("PG_DSN", "postgres://telemetry_user:password@localhost:5432/telemetry_db")
MQTT_BROKER = os.getenv("MQTT_BROKER", "localhost")

@mcp.tool()
async def query_node_telemetry(node_name: str, metric_name: str, limit: int = 10) -> str:
    """
    Fetch the latest telemetry data for a specific edge node.
    Valid nodes: jakebase, margistars, maryguider, adactrl, Caroline-v.
    Valid metrics: cpu_temp, npu_temp, guide_rms, disk_usage.
    """
    conn = await asyncpg.connect(PG_DSN)
    try:
        # Prevent SQL injection by parameterizing the inputs
        query = """
            SELECT timestamp, value
            FROM node_metrics
            WHERE node = $1 AND metric = $2
            ORDER BY timestamp DESC
            LIMIT $3
        """
        records = await conn.fetch(query, node_name, metric_name, limit)

        if not records:
            return f"No recent telemetry found for {node_name} ({metric_name})."

        # Serialize asyncpg Records to a JSON string for the LLM
        return json.dumps([dict(r) for r in records], default=str)
    except Exception as e:
        return f"Database query failed: {e!s}"
    finally:
        await conn.close()

@mcp.tool()
async def publish_edge_command(node_name: str, action: str, payload: dict[str, Any]) -> str:
    """
    Publish an actionable command via MQTT to a specific edge node.
    Example actions: restart_service, slew_mount, flush_logs.
    """
    topic = f"adalovespace/{node_name}/command"
    message = json.dumps({"action": action, "payload": payload})

    try:
        async with aiomqtt.Client(MQTT_BROKER) as client:
            await client.publish(topic, payload=message, qos=1)
        return f"Successfully published action '{action}' to {topic}."
    except Exception as e:
        return f"Failed to publish MQTT message to {node_name}: {e!s}"

@mcp.tool()
async def get_cluster_health() -> str:
    """
    Query PostgreSQL to retrieve the most recent heartbeat timestamp for all 6 nodes.
    Use this to determine if any nodes have dropped off the network.
    """
    conn = await asyncpg.connect(PG_DSN)
    try:
        query = """
            SELECT node, MAX(timestamp) as last_seen
            FROM node_heartbeats
            GROUP BY node
        """
        records = await conn.fetch(query)
        return json.dumps([dict(r) for r in records], default=str)
    finally:
        await conn.close()

if __name__ == "__main__":
    # FastMCP automatically handles the stdio transport protocol for Zed/Claude integration
    mcp.run()
