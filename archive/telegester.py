#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.13"
# dependencies = [
#     "paho-mqtt",
#     "psycopg2-binary",
# ]
# ///

import json

import paho.mqtt.client as mqtt
import psycopg2

with open("cluster.conf") as f:
    config = {}
    for line in f:
        if len(line := line.strip()) == 0:
            continue
        key, value = line.split("=")
        config[key] = value

# MQTT Configuration
MQTT_BROKER_IP = "localhost"  # Since Mosquitto is on the same machine
MQTT_BROKER_PORT = 1883
MQTT_TOPIC = "ada/telemetry/#"  # The '#' catches all sub-topics (all nodes)

# Database Config
DB_HOST = "localhost"
DB_PORT = config["TELEMETRY_DB_PORT"]
DB_NAME = config["TELEMETRY_DB_NAME"]
DB_TABLE = config["TELEMETRY_DB_TABLE"]
DB_USER = config["TELEMETRY_DB_USER"]
DB_PASS = config["TELEMETRY_DB_PASSWORD"]

# Global DB Connection
db_conn = None


def connect_db():
    """Establish connection to Postgres."""
    global db_conn
    try:
        db_conn = psycopg2.connect(
            host=DB_HOST,
            port=DB_PORT,
            database=DB_NAME,
            user=DB_USER,
            password=DB_PASS,
        )
        db_conn.autocommit = True
        print("Connected to PostgreSQL successfully.")
    except Exception as e:
        print(f"Fatal error connecting to database: {e}")
        exit(1)


def on_connect(client, userdata, flags, rc):
    print(f"[Ingest Daemon] Connected to Mosquitto with result code {rc}")
    client.subscribe(MQTT_TOPIC, qos=1)


def on_message(client, userdata, msg):
    """Fires every time a node publishes to the topic."""
    if db_conn is None:
        raise RuntimeError("Database connection is not established.")
    try:
        payload = json.loads(msg.payload.decode("utf-8"))

        # Insert into Postgres
        cursor = db_conn.cursor()
        query = f"""
            INSERT INTO {DB_TABLE} (topic, payload, qos)
            VALUES (%s, %s, %s)
        """
        cursor.execute(query, (msg.topic, payload, msg.qos))
        cursor.close()

        print(f"Logged data for {msg.topic}: {payload}")

    except json.JSONDecodeError:
        print("Received malformed JSON.")
    except psycopg2.InterfaceError:
        print("Database connection lost. Reconnecting...")
        connect_db()
    except Exception as e:
        print(f"Error processing message: {e}")


def main():
    connect_db()

    client = mqtt.Client(client_id="JakebaseTelegester")
    client.on_connect = on_connect
    client.on_message = on_message

    # Optional: client.username_pw_set("your_user", "your_password")

    try:
        client.connect(MQTT_BROKER_IP, MQTT_BROKER_PORT, 60)
        # Blocking loop to keep the script running forever
        client.loop_forever()
    except KeyboardInterrupt:
        print("Shutting down ingest daemon...")
    finally:
        if db_conn:
            db_conn.close()


if __name__ == "__main__":
    main()
