# /// script
# requires-python = ">=3.10"
# dependencies = [
#     "psutil",
#     "paho-mqtt",
# ]
# ///

import json
import socket
import time

import paho.mqtt.client as mqtt
import psutil

# Configuration
BROKER_IP = "10.42.0.99"  # Replace with JakeBase's IP
BROKER_PORT = 1883
PUBLISH_INTERVAL = 60  # Seconds between updates
NODE_NAME = socket.gethostname()
TOPIC = f"ada/telemetry/{NODE_NAME}"


def get_cpu_temp():
    """Attempt to read CPU temperature, specific to Linux/Raspberry Pi."""
    try:
        with open("/sys/class/thermal/thermal_zone0/temp", "r") as f:
            return float(f.read().strip()) / 1000.0
    except FileNotFoundError:
        return 0.0


def collect_telemetry():
    """Gather system metrics into a dictionary."""
    return {
        "node": NODE_NAME,
        "cpu_pct": psutil.cpu_percent(interval=1),
        "mem_pct": psutil.virtual_memory().percent,
        "disk_pct": psutil.disk_usage("/").percent,
        "temp_c": round(get_cpu_temp(), 2),
        "timestamp": int(time.time()),
    }


def on_connect(client, userdata, flags, rc):
    if rc == 0:
        print(f"[{NODE_NAME}] Connected to Mosquitto Broker at {BROKER_IP}")
    else:
        print(f"Failed to connect, return code {rc}")


def main():
    client = mqtt.Client(client_id=f"{NODE_NAME}_sender")
    client.on_connect = on_connect

    # Optional: Add authentication if you locked down Mosquitto
    # client.username_pw_set("your_user", "your_password")

    while True:
        try:
            client.connect(BROKER_IP, BROKER_PORT, 60)
            client.loop_start()

            while True:
                payload = collect_telemetry()
                client.publish(TOPIC, json.dumps(payload), qos=1)
                time.sleep(PUBLISH_INTERVAL)

        except Exception as e:
            print(f"Connection lost or error: {e}. Retrying in 10 seconds...")
            time.sleep(10)


if __name__ == "__main__":
    main()
