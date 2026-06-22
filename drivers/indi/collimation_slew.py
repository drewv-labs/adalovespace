import PyIndi
import time
import sys

# Change this to match the exact name of your mount in INDI (e.g., "EQMod Mount", "Telescope Simulator")
MOUNT_NAME = "Telescope Simulator"

class SlewClient(PyIndi.BaseClient):
    def __init__(self, host, port):
        super(SlewClient, self).__init__()
        self.setServer(host, port)
        self.device = None

    def newDevice(self, d):
        if d.getDeviceName() == MOUNT_NAME:
            self.device = d

    def newProperty(self, p):
        pass

    def removeProperty(self, p):
        pass

    def newBLOB(self, bp):
        pass

    def newSwitch(self, svp):
        pass

    def newNumber(self, nvp):
        pass

    def newText(self, tvp):
        pass

    def newLight(self, lvp):
        pass

    def newMessage(self, d, m):
        pass

    def serverConnected(self):
        print(f"Connected to INDI server. Looking for {MOUNT_NAME}...")

    def serverDisconnected(self, code):
        print("Disconnected from INDI server.")

def slew_to_horizontal():
    # 1. Initialize and connect to the local INDI server on the Pi 5
    client = SlewClient("localhost", 7624)
    client.connectServer()

    # 2. Wait for the device to populate
    timeout = 5
    while not client.device and timeout > 0:
        time.sleep(1)
        timeout -= 1

    if not client.device:
        print(f"Error: Could not find {MOUNT_NAME}. Is the driver running?")
        sys.exit(1)

    # 3. Ensure we are connected to the mount hardware
    if not client.device.isConnected():
        connect_prop = client.device.getSwitch("CONNECTION")
        connect_prop[0].s = PyIndi.ISS_ON  # Set CONNECT to ON
        connect_prop[1].s = PyIndi.ISS_OFF # Set DISCONNECT to OFF
        client.sendNewSwitch(connect_prop)
        time.sleep(2) # Give it a second to physically connect

    # 4. Set the mount behavior to SLEW (instead of TRACK or SYNC)
    # The property is usually 'ON_COORD_SET'
    coord_set = client.device.getSwitch("ON_COORD_SET")
    if coord_set:
        for switch in coord_set:
            switch.s = PyIndi.ISS_OFF
        coord_set.findWidgetByName("SLEW").s = PyIndi.ISS_ON
        client.sendNewSwitch(coord_set)

    # 5. Send the target coordinates
    # For a horizontal collimation on an Equatorial mount, you will need to determine
    # the specific Right Ascension (RA) and Declination (DEC) that lays your tube flat.
    # Replace these placeholder numbers with your specific collimation coordinates.
    target_ra = 6.0   # Hours
    target_dec = 0.0  # Degrees

    eq_coords = client.device.getNumber("EQUATORIAL_EOD_COORD")
    if not eq_coords:
        eq_coords = client.device.getNumber("EQUATORIAL_COORD") # Fallback for some drivers

    if eq_coords:
        eq_coords[0].value = target_ra
        eq_coords[1].value = target_dec
        print(f"Slewing {MOUNT_NAME} to RA: {target_ra}, DEC: {target_dec}...")
        client.sendNewNumber(eq_coords)
    else:
        print("Error: Could not find coordinate property on this mount.")

    # Disconnect cleanly
    time.sleep(1)
    client.disconnectServer()

if __name__ == "__main__":
    slew_to_horizontal()
