import json
import os
import time
from pathlib import Path

import serial


# Placeholder for your actual INDI binding (e.g., indipyclient or subprocess call)
class IndiHandler:
    def __init__(self, host="localhost", port=7624):
        self.host = host
        self.port = port
        print(f"[INDI] Bound to local server at {host}:{port}")

    def execute_preprogrammed_slew(self, command_str):
        # Insert your actual Ekos/INDI property injection logic here
        print(f"[INDI EXEC] Slewing mount for protocol: {command_str}")
        time.sleep(1)  # Simulating non-blocking or threaded dispatch
        return True


class AdaKnobAgent:
    def __init__(
        self,
        port="/dev/adaknob",
        baud=115200,
        spool_dir="/opt/mqtt_stream/ada_knob",
    ):
        self.ser = serial.Serial(port, baud, timeout=1.0)
        self.ser.reset_input_buffer()  # Purge microcontroller boot text
        self.spool_dir = Path(spool_dir)
        self.spool_dir.mkdir(parents=True, exist_ok=True)
        print(f"[KNOB] Secure USB pipe open on {port}")

    def await_command(self):
        if self.ser.in_waiting > 0:
            try:
                raw = self.ser.readline().decode("utf-8").strip()
                if raw:
                    payload = json.loads(raw)
                    return payload.get("command")
            except Exception as e:
                print(f"[SERIAL NOISE] {e}")
        return None

    def send_feedback(self, status):
        # Blast visual state back down the USB wire to the Elecrow screen
        # e.g., "STATUS:RUNNING", "STATUS:COMPLETE", "STATUS:ERROR"
        msg = f"STATUS:{status}\n".encode("utf-8")
        self.ser.write(msg)

    def spool_audit_event(self, cmd_str, success):
        event_meta = {
            "source": "AdaKnob_Direct_USB",
            "timestamp": time.time(),
            "command_dispatched": cmd_str,
            "indi_status": "success" if success else "failed",
        }
        # Write atomically to disk using a temporary file flip to prevent race conditions
        temp_path = self.spool_dir / f"tmp_{time.time_ns()}.json"
        final_path = self.spool_dir / f"event_{time.time_ns()}.json"

        with open(temp_path, "w") as f:
            json.dumps(event_meta, f)
        temp_path.rename(final_path)


# --- THE SURVIVAL LOOP ---
if __name__ == "__main__":
    indi = IndiHandler()
    knob = AdaKnobAgent()

    # Pre-authorized emergency & maintenance whitelist
    VALID_COMMANDS = {"slew_collimation", "park_scope", "eaf_zero", "dew_clear"}

    print("AdaBrain Cockpit Override Loop Active.")
    while True:
        cmd = knob.await_command()
        if cmd:
            print(f"\n[INTERCEPT] Knob Dial requested: '{cmd}'")

            if cmd in VALID_COMMANDS:
                # 1. Immediately turn the knob screen RED (Processing)
                knob.send_feedback("RUNNING")

                # 2. Command the physical mount
                success = indi.execute_preprogrammed_slew(cmd)

                # 3. Drop the audit postcard into the spool directory
                knob.spool_audit_event(cmd, success)

                # 4. Turn the knob screen back to GREEN/RED-READY
                knob.send_feedback("COMPLETE" if success else "ERROR")
            else:
                print(f"[SECURITY] Rejected invalid local command: {cmd}")
                knob.send_feedback("INVALID_CMD")

        time.sleep(0.01)  # 10ms cycle sleep to keep CPU idling cool
