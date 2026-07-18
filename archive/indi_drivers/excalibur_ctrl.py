#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = [
#     "pyindi-client",
# ]
# ///

import time
import sys
import PyIndi

# Configuration
DEVICE_NAME = "RBF Excalibur"  # Standard device name in indi_Excalibur
HOST = "localhost"             # Change to AdaBrain's IP if running from a remote client
PORT = 7624

class IndiClient(PyIndi.BaseClient):
    def __init__(self):
        super().__init__()
    def newDevice(self, d): pass
    def newProperty(self, p): pass
    def removeProperty(self, p): pass
    def newBLOB(self, bp): pass
    def newSwitch(self, svp): pass
    def newNumber(self, nvp): pass
    def newText(self, tvp): pass
    def newLight(self, lvp): pass
    def newMessage(self, d, m): pass
    def serverConnected(self):
        print(f"[*] Connected to INDI server at {HOST}:{PORT}")
    def serverDisconnected(self, code):
        print("[!] Disconnected from INDI server")

def control_excalibur(action="open"):
    client = IndiClient()
    client.setServer(HOST, PORT)

    if not client.connectServer():
        print(f"[!] Failed to connect to INDI server at {HOST}:{PORT}. Is indiserver running?")
        sys.exit(1)

    time.sleep(1)  # Allow socket connection and initial device discovery

    device = client.getDevice(DEVICE_NAME)
    while not device:
        print(f"[*] Waiting for {DEVICE_NAME} driver to register...")
        time.sleep(0.5)
        device = client.getDevice(DEVICE_NAME)

    # Ensure physical USB/serial connection is active
    connection = device.getSwitch("CONNECTION")
    while not connection:
        time.sleep(0.5)
        connection = device.getSwitch("CONNECTION")

    if not device.isConnected():
        print(f"[*] Establishing connection to {DEVICE_NAME} hardware...")
        connection[0].s = PyIndi.ISS_ON  # CONNECT
        connection[1].s = PyIndi.ISS_OFF # DISCONNECT
        client.sendNewSwitch(connection)
        time.sleep(1)

    # Target the standard INDI Dust Cap Interface property
    cap_prop = device.getSwitch("CAP_PARK")
    while not cap_prop:
        print("[*] Waiting for CAP_PARK property switch...")
        time.sleep(0.5)
        cap_prop = device.getSwitch("CAP_PARK")

    # Reset property switches before asserting the new target state
    cap_prop.reset()

    if action.lower() == "open":
        print("[*] Sending command: UNPARK (Opening Cover)")
        cap_prop.findWidgetByName("CAP_UNPARK").s = PyIndi.ISS_ON
    else:
        print("[*] Sending command: PARK (Closing Cover)")
        cap_prop.findWidgetByName("CAP_PARK").s = PyIndi.ISS_ON

    client.sendNewSwitch(cap_prop)

    print("[*] Motor command dispatched. Allowing 3 seconds for physical travel...")
    time.sleep(3)

    client.disconnectServer()
    print("[*] Done.")

if __name__ == "__main__":
    # Pass "open" or "close" as a command line argument (defaults to open)
    target_action = sys.argv[1] if len(sys.argv) > 1 else "open"
    control_excalibur(target_action)
