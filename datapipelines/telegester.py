#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = [
#     "paho-mqtt",
#     "psycopg2-binary",
# ]
# ///

import json

import paho.mqtt.client as mqtt
import psycopg2

# Configuration
BROKER_IP = "localhost"  # Since Mosquitto is on the same machine
BROKER_PORT = 1883
SUBSCRIBE_TOPIC = "ada/telemetry/#"  # The '#' catches all sub-topics (all nodes)

# Database Config
DB_HOST = "localhost"
DB_NAME = "ada_db"
DB_USER = "ada_admin"
DB_PASS = "your_secure_password"

# Global DB Connection
db_conn = None


def connect_db():
    """Establish connection to Postgres."""
    global db_conn
    try:
        db_conn = psycopg2.connect(
            host=DB_HOST, database=DB_NAME, user=DB_USER, password=DB_PASS
        )
        db_conn.autocommit = True
        print("Connected to PostgreSQL successfully.")
    except Exception as e:
        print(f"Fatal error connecting to database: {e}")
        exit(1)


def on_connect(client, userdata, flags, rc):
    print(f"[Ingest Daemon] Connected to Mosquitto with result code {rc}")
    client.subscribe(SUBSCRIBE_TOPIC, qos=1)


def on_message(client, userdata, msg):
    """Fires every time a node publishes to the topic."""
    try:
        payload = json.loads(msg.payload.decode("utf-8"))

        # Parse the JSON
        node = payload.get("node", "Unknown")
        cpu = payload.get("cpu_pct", 0.0)
        mem = payload.get("mem_pct", 0.0)
        disk = payload.get("disk_pct", 0.0)
        temp = payload.get("temp_c", 0.0)

        # Insert into Postgres
        cursor = db_conn.cursor()
        query = """
            INSERT INTO system_logs (node, cpu_pct, mem_pct, disk_pct, temp_c)
            VALUES (%s, %s, %s, %s, %s)
        """
        cursor.execute(query, (node, cpu, mem, disk, temp))
        cursor.close()

        print(f"Logged data for {node}: {temp}°C, CPU {cpu}%")

    except json.JSONDecodeError:
        print("Received malformed JSON.")
    except psycopg2.InterfaceError:
        print("Database connection lost. Reconnecting...")
        connect_db()
    except Exception as e:
        print(f"Error processing message: {e}")


def main():
    connect_db()

    client = mqtt.Client(client_id="JakeBase_Ingester")
    client.on_connect = on_connect
    client.on_message = on_message

    # Optional: client.username_pw_set("your_user", "your_password")

    try:
        client.connect(BROKER_IP, BROKER_PORT, 60)
        # Blocking loop to keep the script running forever
        client.loop_forever()
    except KeyboardInterrupt:
        print("Shutting down ingest daemon...")
    finally:
        if db_conn:
            db_conn.close()


if __name__ == "__main__":
    main()
