from gpiozero import Button
from time import sleep

# Define the GPIO pins connected to the Hall Effect sensors
# Pull-up resistors are enabled internally by gpiozero by default
sensor_paracorr = Button(17)
sensor_nexus = Button(27)

def set_train_920mm():
    print("Magnet detected on Sensor A!")
    print("Action: Paracorr inserted. Switching Ekos to 'Ada 920mm' Optical Train.")
    # TODO: Insert INDI/DBus command here to tell KStars to switch profiles

def set_train_600mm():
    print("Magnet detected on Sensor B!")
    print("Action: Nexus inserted. Switching Ekos to 'Ada 600mm' Optical Train.")
    # TODO: Insert INDI/DBus command here to tell KStars to switch profiles

# Event listeners that trigger the functions when the magnetic field is detected (button pressed)
sensor_paracorr.when_pressed = set_train_920mm
sensor_nexus.when_pressed = set_train_600mm

print("Ada Lovespace Auto-Detect Daemon Running. Waiting for optical trains...")

# Keep the script running in the background
try:
    while True:
        sleep(1)
except KeyboardInterrupt:
    print("Daemon stopped.")
