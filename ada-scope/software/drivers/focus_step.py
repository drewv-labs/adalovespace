import PyIndi
import time
import sys

# Replace with your actual Ekos focuser name
FOCUSER_NAME = "Focuser Simulator"

# Grab the step value passed from the command line (default to 50 if none provided)
try:
    step_change = int(sys.argv[1])
except IndexError:
    step_change = 50

class INDIClient(PyIndi.BaseClient):
    def __init__(self):
        super(INDIClient, self).__init__()
        self.device = None
    def newDevice(self, d):
        if d.getDeviceName() == FOCUSER_NAME:
            self.device = d
    def newProperty(self, p): pass
    def removeProperty(self, p): pass
    def newBLOB(self, bp): pass
    def newSwitch(self, svp): pass
    def newNumber(self, nvp): pass
    def newText(self, tvp): pass
    def newLight(self, lvp): pass
    def newMessage(self, d, m): pass
    def serverConnected(self): pass
    def serverDisconnected(self, code): pass

def step_focuser():
    client = INDIClient()
    client.setServer("localhost", 7624)
    client.connectServer()

    timeout = 3
    while not client.device and timeout > 0:
        time.sleep(0.5)
        timeout -= 0.5

    if not client.device or not client.device.isConnected():
        print("Focuser not found or not connected.")
        sys.exit(1)

    # Grab the current absolute position
    focus_prop = client.device.getNumber("ABS_FOCUS_POSITION")
    if focus_prop:
        current_pos = focus_prop[0].value
        new_pos = current_pos + step_change

        # Send the new position back to the focuser
        focus_prop[0].value = new_pos
        client.sendNewNumber(focus_prop)
        print(f"Focuser moved from {current_pos} to {new_pos}")
    else:
        print("Error: Could not find absolute focus property.")

    time.sleep(0.5)
    client.disconnectServer()

if __name__ == "__main__":
    step_focuser()
