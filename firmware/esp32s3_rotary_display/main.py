## Add to the top of Knob's boot.py
# import micropython
# micropython.kbd_intr(-1)  # Disable Ctrl+C throwing KeyboardInterrupts from wire


import json
import sys
import time

import lvgl as lv
import machine
import uselect

# ---------------------------------------------------------
# 1. COMMAND MAPPING & CONFIGURATION
# ---------------------------------------------------------
# Human-readable UI labels mapped directly to AdaBrain's whitelist slugs
PROTOCOLS = [
    {"label": "Slew Collimation", "slug": "slew_collimation"},
    {"label": "Park Telescope", "slug": "park_scope"},
    {"label": "Zero Focuser", "slug": "eaf_zero"},
    {"label": "Clear Dew Pads", "slug": "dew_clear"},
    {"label": "Rig Shutdown", "slug": "safe_shutdown"},
]

# Hardware Pins (Adjust to your Elecrow board's exact rotary breakout)
ENC_A_PIN = 18
ENC_B_PIN = 19
ENC_BTN_PIN = 20

# ---------------------------------------------------------
# 2. LVGL "RED OCTOBER" THEME INITIALIZATION
# ---------------------------------------------------------
# Assuming boot.py has executed lv.init() and initialized the GC9A01 display driver

COLOR_BLACK = lv.color_hex(0x000000)
COLOR_PURE_RED = lv.color_hex(0xFF0000)
COLOR_DARK_RED = lv.color_hex(0x400000)
COLOR_AMBER = lv.color_hex(0xFF9900)  # Used exclusively for errors/warnings

scr = lv.obj()
scr.set_style_bg_color(COLOR_BLACK, lv.PART_MAIN)
scr.set_style_bg_opa(lv.OPA.COVER, lv.PART_MAIN)

# Top Status Indicator (Gives you telemetry feedback from 6 feet away)
status_label = lv.label(scr)
status_label.set_text("SYSTEM READY")
status_label.set_style_text_color(COLOR_PURE_RED, lv.PART_MAIN)
status_label.set_style_text_font(lv.font_montserrat_12, lv.PART_MAIN)
status_label.align(lv.ALIGN.TOP_MID, 0, 15)

# Main Protocol Roller
roller = lv.roller(scr)
roller_options = "\n".join([item["label"] for item in PROTOCOLS])
roller.set_options(roller_options, lv.roller.MODE.INFINITE)
roller.set_visible_row_count(3)
roller.set_width(190)
roller.align(lv.ALIGN.CENTER, 0, 0)

# Unselected options (Curving into the bezel)
roller.set_style_bg_color(COLOR_BLACK, lv.PART_MAIN)
roller.set_style_text_color(COLOR_DARK_RED, lv.PART_MAIN)
roller.set_style_border_width(0, lv.PART_MAIN)

# Highlighted active option dead-center
roller.set_style_bg_color(COLOR_DARK_RED, lv.PART_SELECTED)
roller.set_style_text_color(COLOR_PURE_RED, lv.PART_SELECTED)

lv.scr_load(scr)

# ---------------------------------------------------------
# 3. ASYNCHRONOUS USB SERIAL LISTENER
# ---------------------------------------------------------
# Register standard input (USB wire) with the OS poll engine
usb_rx_poll = uselect.poll()
usb_rx_poll.register(sys.stdin, uselect.POLLIN)


def check_adabrain_feedback():
    """Polls the USB line for incoming status strings without blocking UI."""
    if usb_rx_poll.poll(0):  # 0ms timeout = instant non-blocking check
        try:
            raw_line = sys.stdin.readline().strip()
            if raw_line.startswith("STATUS:"):
                state = raw_line.split(":")[1]

                if state == "RUNNING":
                    status_label.set_text("PROCESSING...")
                    status_label.set_style_text_color(COLOR_AMBER, lv.PART_MAIN)
                    roller.set_style_border_color(COLOR_AMBER, lv.PART_MAIN)
                    roller.set_style_border_width(2, lv.PART_MAIN)

                elif state == "COMPLETE":
                    status_label.set_text("SYSTEM READY")
                    status_label.set_style_text_color(COLOR_PURE_RED, lv.PART_MAIN)
                    roller.set_style_border_width(0, lv.PART_MAIN)

                elif state in ["ERROR", "INVALID_CMD"]:
                    status_label.set_text(f"FAULT: {state}")
                    status_label.set_style_text_color(COLOR_AMBER, lv.PART_MAIN)
        except Exception:
            pass


# ---------------------------------------------------------
# 4. HARDWARE INTERRUPTS & DISPATCH LOGIC
# ---------------------------------------------------------
current_idx = 0
is_executing = False


def button_callback(pin):
    global is_executing
    # Prevent double-firing or stacking commands while mount is moving
    if is_executing or status_label.get_text() == "PROCESSING...":
        return

    # 1. Grab the slug corresponding to the highlighted option
    selected_slug = PROTOCOLS[roller.get_selected()]["slug"]

    # 2. Package into compact JSON
    outbound_payload = json.dumps({"command": selected_slug})

    # 3. Blast directly down the USB serial wire
    print(outbound_payload)

    # 4. Immediate visual feedback on the control plane
    status_label.set_text("DISPATCHED...")
    status_label.set_style_text_color(COLOR_AMBER, lv.PART_MAIN)
    roller.set_style_bg_color(COLOR_AMBER, lv.PART_SELECTED)
    time.sleep(0.01)
    roller.set_style_bg_color(COLOR_DARK_RED, lv.PART_SELECTED)


btn = machine.Pin(ENC_BTN_PIN, machine.Pin.IN, machine.Pin.PULL_UP)
btn.irq(trigger=machine.Pin.IRQ_FALLING, handler=button_callback)

# --- Main keep-alive loop ---
while True:
    # 1. Check if AdaBrain talked back
    check_adabrain_feedback()

    # 2. Render graphics frame
    lv.timer_handler()

    # 3. 5ms sleep keeps CPU thermal profile low inside your custom enclosure
    time.sleep(0.05)
