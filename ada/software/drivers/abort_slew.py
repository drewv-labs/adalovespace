import PyIndi
import time
import sys

# Replace with your actual Ekos mount name
MOUNT_NAME = "Telescope Simulator"

class INDIClient(PyIndi.BaseClient):
    def __init__(self):
        super(INDIClient, self).__init__()
        self.device = None
    def newDevice(self, d):
        if d.getDeviceName() == MOUNT_NAME:
            self.device = d
    # (Same dummy callbacks as above needed here for PyIndi)
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

def abort_mount():
    client = INDIClient()
    client.setServer("localhost", 7624)
    client.connectServer()

    timeout = 2
    while not client.device and timeout > 0:
        time.sleep(0.2)
        timeout -= 0.2

    if not client.device or not client.device.isConnected():
        sys.exit(1)

    # Find the abort switch and throw it ON
    abort_prop = client.device.getSwitch("TELESCOPE_ABORT_MOTION")
    if abort_prop:
        abort_prop.findWidgetByName("ABORT").s = PyIndi.ISS_ON
        client.sendNewSwitch(abort_prop)
        print("EMERGENCY ABORT COMMAND SENT.")

    time.sleep(0.5)
    client.disconnectServer()

if __name__ == "__main__":
    abort_mount()
