#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = [
#     "paho-mqtt",
# ]
# ///
#  // This daemon is designed to run on AdaBrain in conjunction
#  // with drivers/indi/knob_agent_daemon.py
import os
import time
from pathlib import Path

import paho.mqtt.client as mqtt

SPOOL_DIR = Path("/opt/mqtt_stream/ctrl-knob")
MQTT_BROKER = os.environ["JAKE_IP"]
MQTT_TOPIC = "ada/audit/ctrl-knob"


def flush_spool():
    if not SPOOL_DIR.exists():
        return

    # Grab all stable json files (ignoring our temp write files)
    files = sorted([f for f in SPOOL_DIR.glob("event_*.json")])

    for target_file in files:
        try:
            with open(target_file, "r") as f:
                payload = f.read()

            # Fire at QoS 0. If socket is open, it goes out instantly.
            client.publish(MQTT_TOPIC, payload, qos=0)

            # Immediately purge the spooled file from disk to clear space
            target_file.unlink()
            print(f"[SPOOLER] Shipped and purged: {target_file.name}")

        except Exception as e:
            print(f"[SPOOLER FAULT] Could not process {target_file.name}: {e}")
            # Break the loop; keep remaining files safely on disk until network recovers
            break


if __name__ == "__main__":
    client = mqtt.Client(client_id="AdaBrain_SpoolCourier")
    client.loop_start()

    print("Sidecar MQTT Courier looking for spooled postcards...")
    while True:
        try:
            # Only attempt to flush if the background thread actively sees Jake's broker
            if client.is_connected():
                flush_spool()
        except Exception:
            pass

        time.sleep(1)  # Check the mailbox once every second
