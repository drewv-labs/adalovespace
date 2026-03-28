The beauty of a pre-built 3-key USB macro pad is that it requires absolutely zero microcontroller programming. To the Raspberry Pi 5, that little 3-key pad is indistinguishable from a standard 104-key Dell desktop keyboard.

Here is exactly how the pipeline works from physical press to telescope movement, and how you set it up on a Linux-based node.

1. The Hardware Layer (The "Fake" Keyboard)
Most pre-built macro pads come with a simple piece of software (often Windows/Mac only) that you use once to program the keys. You save the configuration to the pad's onboard memory, and then you can plug it into any machine.

You would program the three keys to output obscure, complex keystrokes that you'd never hit accidentally on a real keyboard. For example:

Key 1: `Ctrl + Alt + Shift + F1` (We'll use this for your horizontal collimation script)

Key 2: `Ctrl + Alt + Shift + F2` (Maybe to slew to Zenith for taking flat frames)

Key 3: `Ctrl + Alt + Shift + F3` (Emergency Park)

## 2. The OS Layer (Catching the Keystroke)
When you press Key 1, the macro pad sends that Ctrl+Alt+Shift+F1 signal over USB. Now, the Pi needs to be listening for it. How you do this depends on how you are running the Pi 5.  
### _Scenario A_: 
The Desktop Way (If you run a GUI like KDE, XFCE, or Ubuntu)
If your Pi boots into a graphical desktop environment and you are VNC-ing into it, this is trivial. You just go into the OS's system settings, find the "Custom Keyboard Shortcuts" menu, add a new shortcut, press the macro key to bind it, and set the action to run:  
&emsp;&emsp;`python3 /home/drew/scripts/collimation_slew.py`  

### _Scenario B_: 
The Headless Way (The Better Astrophotography Route)
Astrophotography nodes are usually run headless (no graphical desktop) to save RAM and CPU cycles. If you don't have a graphical session running, standard keyboard shortcuts won't work. You need to catch the keystroke at the Linux kernel level.

To do this, you use a lightweight Linux daemon called triggerhappy. It is designed specifically for headless servers to map input devices to scripts.  
<br>
## 3. The Execution Layer (Using Triggerhappy)
If you go the headless route, the setup looks like this:

Install it: sudo apt install triggerhappy

Find the key code: You run a command  
&emsp;&emsp;`thd --dump /dev/input/event*`  
and press your macro button. The terminal will spit out the exact kernel name for that key combination (e.g., `KEY_F1+KEY_LEFTCTRL+KEY_LEFTALT+KEY_LEFTSHIFT`).

Map the script: You create a simple one-line configuration file in /etc/triggerhappy/triggers.d/ that looks like this:

(Plaintext)  
&emsp;&emsp;`KEY_F1+KEY_LEFTCTRL+KEY_LEFTALT+KEY_LEFTSHIFT    1    /usr/bin/python3 /home/drew/scripts/collimation_slew.py`  
<br>
## The Result
The triggerhappy daemon runs silently in the background from the moment the Pi boots. You can be SSH'd into the Pi from your laptop, or not connected to it at all. The second you physically press Key 1 on the macro pad out at the telescope, the kernel registers the HID event, triggerhappy intercepts it, and instantly executes your Python INDI script, slewing the mount horizontally so you can hook up the OCAL collimator.
