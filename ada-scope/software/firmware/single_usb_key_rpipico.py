"""
When you plug the Pico into your Pi 5 via USB, the OS will just see a standard keyboard.
When you press your arcade button, it will instantly fire off a specific, obscure
keyboard shortcut (like Ctrl + Shift + Alt + H).

The Pico Wiring
Connect one side of your arcade button to GP15 on the Pico.

Connect the other side of the button to any GND (Ground) pin on the Pico.
(We use the Pico's internal pull-up resistor in the code, so no external resistors are needed).

The CircuitPython Code (code.py)
First, make sure you have installed CircuitPython on the Pico, and drop the adafruit_hid library
folder into the Pico's lib drive. Then, save this code as code.py on the root of the Pico drive.

Once you have this running, you can use the evdev library on the Pi 5 (or just the standard global
keyboard shortcuts menu if you are running a desktop environment like KDE Plasma or MATE) to map
Ctrl+Shift+Alt+H directly to that collimation_slew.py script we wrote.
"""

import board
import digitalio
import time
import usb_hid
from adafruit_hid.keyboard import Keyboard
from adafruit_hid.keycode import Keycode

# Set up the keyboard interface
kbd = Keyboard(usb_hid.devices)

# Set up the button on GP15
# Pull.UP means the pin reads True normally, and False when the button connects it to Ground
collimation_btn = digitalio.DigitalInOut(board.GP15)
collimation_btn.direction = digitalio.Direction.INPUT
collimation_btn.pull = digitalio.Pull.UP

print("Macro pad ready. Waiting for button press...")

while True:
    # If the button is pressed (reads False because it's connected to Ground)
    if not collimation_btn.value:
        print("Slew command triggered!")

        # Send the obscure key combination
        kbd.press(Keycode.CONTROL, Keycode.SHIFT, Keycode.ALT, Keycode.H)
        time.sleep(0.1) # Brief pause
        kbd.release_all()

        # Debounce: Wait for the button to be released before continuing
        while not collimation_btn.value:
            time.sleep(0.1)

    time.sleep(0.05) # Small sleep to prevent maxing out the Pico's CPU
