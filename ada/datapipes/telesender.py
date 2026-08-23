#!/usr/bin/env python3
"""
Ada Lovespace — Telesender (telemetry edge node scraper)

Lightweight, single-process systemd service that scrapes system metrics
and publishes them to the local MQTT broker for Telegraf ingestion.

Required environment variables:
    JAKE_IP   — IP or hostname of the MQTT broker (JakeBase)
    NODE_NAME — Unique identifier for this edge node (defaults to hostname)
"""

import json
import logging
import os
import signal
import socket
import sys
import threading
import time

import paho.mqtt.client as mqtt
import psutil

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

BROKER_IP = os.environ.get("JAKE_IP")
if not BROKER_IP:
    print(
        "FATAL: JAKE_IP environment variable is not set.\n"
        "Set it to the IP/hostname of your JakeBase MQTT broker.",
        file=sys.stderr,
    )
    sys.exit(1)

BROKER_PORT = int(os.environ.get("JAKE_PORT", "1883"))
PUBLISH_INTERVAL = int(os.environ.get("TELE_SEND_INTERVAL", "60"))  # seconds
NODE_NAME = os.environ.get("NODE_NAME", socket.gethostname())
TOPIC = f"ada/telemetry/{NODE_NAME}"

logger = logging.getLogger("telesender")
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(name)s] %(levelname)s: %(message)s",
)


# ---------------------------------------------------------------------------
# Telemetry Collection
# ---------------------------------------------------------------------------

def get_cpu_temp():
    """Read CPU temperature from Linux thermal zones. Returns None if unavailable."""
    for path in [
        "/sys/class/thermal/thermal_zone0/temp",
        "/sys/class/hwmon/hwmon0/temp1_input",
        "/sys/devices/platform/rpi_probe/temp1_input",
    ]:
        try:
            with open(path, "r") as f:
                return round(float(f.read().strip()) / 1000.0, 2)
        except (FileNotFoundError, ValueError, PermissionError):
            continue
    return None


def _get_load_avg():
    """Return 1/5/15 min load averages or [None]*3 on failure."""
    try:
        load1, load5, load15 = os.getloadavg()
        return round(load1, 2), round(load5, 2), round(load15, 2)
    except OSError:
        return None, None, None


def _get_swap_pct():
    """Return swap usage percentage or None if no swap configured."""
    try:
        swap = psutil.virtual_memory().swap
        return round(swap.percent, 1) if swap.total > 0 else None
    except Exception:
        return None


def collect_telemetry():
    """Gather system metrics into a flat dictionary."""
    load1, load5, load15 = _get_load_avg()
    disk = psutil.disk_usage("/")

    return {
        "node": NODE_NAME,
        "cpu_pct": psutil.cpu_percent(interval=0.5),
        "mem_pct": round(psutil.virtual_memory().percent, 1),
        "mem_used_mb": round(psutil.virtual_memory().used / (1024 ** 2), 1),
        "swap_pct": _get_swap_pct(),
        "disk_pct": round(disk.percent, 1),
        "disk_free_gb": round(disk.free / (1024 ** 3), 2),
        "load_avg_1m": load1,
        "load_avg_5m": load5,
        "load_avg_15m": load15,
        "temp_c": get_cpu_temp(),
        "uptime_s": round(time.time() - psutil.boot_time(), 0) if psutil.boot_time() else 0,
        "timestamp": int(time.time()),
    }


# ---------------------------------------------------------------------------
# MQTT Client Lifecycle
# ---------------------------------------------------------------------------

_client: mqtt.Client | None = None
_shutdown_event = threading.Event()


def on_connect(client, userdata, flags, rc):
    if rc == 0:
        logger.info("Connected to MQTT broker at %s:%d", BROKER_IP, BROKER_PORT)
    else:
        logger.error("Connection failed — return code %d", rc)


def on_disconnect(client, userdata, rc):
    if rc != 0:
        logger.warning("Unexpected disconnect (rc=%d), will reconnect...", rc)


def setup_client():
    """Create and configure the MQTT client."""
    global _client
    if _client is not None:
        _client.disconnect()
    _client = mqtt.Client(
        callback_api_version=mqtt.CallbackAPIVersion.VERSION2,
        client_id=f"{NODE_NAME}_sender",
        clean_start=True,  # type: ignore[arg-type] — pyright compat
    )
    _client.on_connect = on_connect
    _client.on_disconnect = on_disconnect
    return _client


# ---------------------------------------------------------------------------
# Graceful Shutdown
# ---------------------------------------------------------------------------


def shutdown_handler(signum, frame):
    """Handle SIGTERM / SIGINT for clean process teardown."""
    sig_name = signal.Signals(signum).name if hasattr(signal, "Signals") else signum
    logger.info("Received %s — shutting down...", sig_name)
    _shutdown_event.set()


def main():
    global _client

    # Install signal handlers for clean process teardown
    for sig in (signal.SIGTERM, signal.SIGINT):
        signal.signal(sig, shutdown_handler)

    logger.info(
        "Telesender v1.0 | node=%s broker=%s:%d topic=%s interval=%ds",
        NODE_NAME, BROKER_IP, BROKER_PORT, TOPIC, PUBLISH_INTERVAL,
    )

    retries = 0
    max_retries = 5
    client = None

    while not _shutdown_event.is_set():
        try:
            client = setup_client()

            # Attempt connection with retries for transient broker unavailability
            connected = False
            for attempt in range(1, max_retries + 1):
                try:
                    client.connect(BROKER_IP, BROKER_PORT, keepalive=60)
                    client.loop_start()
                    connected = True
                    break
                except (ConnectionRefusedError, OSError) as exc:
                    logger.warning(
                        "Connect attempt %d/%d failed (%s). Retrying...",
                        attempt, max_retries, exc,
                    )
                    time.sleep(min(attempt * 2, 10))

            if not connected:
                logger.error("All connect attempts failed. Retrying in 30s...")
                _shutdown_event.wait(timeout=30)
                continue

            retries = 0  # reset on successful connection

            # Main publish loop — sleeps until interrupted by shutdown signal or error
            while not _shutdown_event.is_set():
                try:
                    payload = json.dumps(collect_telemetry())
                    result = client.publish(TOPIC, payload, qos=1)
                    result.wait_for_publish(timeout=5)

                    retries = 0
                except Exception as exc:
                    logger.warning("Publish failed (%s). Reconnecting...", exc)
                    _shutdown_event.set()  # break inner loop, outer handles reconnect
                    break

                # Sleep in small increments so shutdown signal is responsive
                for _ in range(PUBLISH_INTERVAL):
                    if _shutdown_event.wait(timeout=1):
                        break

        except Exception as exc:
            logger.error("Unexpected error: %s", exc)

        # Clean up before reconnect attempt
        if client and client.is_connected():
            try:
                client.disconnect()
            except Exception:
                pass

        _shutdown_event.set()  # let outer loop handle reconnection delay
        retry_delay = min(2 ** retries, 30)
        logger.info("Reconnecting in %ds...", retry_delay)
        _shutdown_event.wait(timeout=retry_delay)
        retries += 1

    # Final cleanup
    if client is not None and client.is_connected():
        try:
            client.disconnect()
        except Exception:
            pass
    logger.info("Telesender stopped.")


if __name__ == "__main__":
    main()
