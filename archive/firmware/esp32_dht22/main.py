import socket
import time

import dht
import network
from machine import Pin

# --- Configuration ---
WIFI_SSID = "AdaLovespace"
WIFI_PASSWORD = "@D@L0V3$P@C3"
DHT_PIN = 4  # The GPIO pin connected to the DHT data line


def connect_wifi():
    """Connects to the specified WiFi network and returns the IP address."""
    wlan = network.WLAN(network.STA_IF)
    wlan.active(True)

    if not wlan.isconnected():
        print(f"Connecting to 2.4GHz network: {WIFI_SSID}...")
        wlan.connect(WIFI_SSID, WIFI_PASSWORD)

        # Wait for connection to establish
        timeout = 10
        while not wlan.isconnected() and timeout > 0:
            time.sleep(1)
            timeout -= 1

        if not wlan.isconnected():
            raise RuntimeError(
                "Network connection failed. Check credentials or signal."
            )

    ip_address = wlan.ifconfig()[0]
    print(f"Connected successfully. Network config: {wlan.ifconfig()}")
    return ip_address


def start_metrics_server(ip, sensor):
    """Starts a lightweight HTTP server to expose sensor readings."""
    addr = socket.getaddrinfo("0.0.0.0", 80)[0][-1]
    s = socket.socket()

    # Allow socket reuse to prevent "Address in use" errors on soft resets
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    s.bind(addr)
    s.listen(1)
    print(f"Listening for HTTP requests on http://{ip}")

    while True:
        cl, addr = s.accept()
        try:
            # DHT sensors need a moment between readings; the request acts as the trigger
            sensor.measure()
            temp_c = sensor.temperature()
            hum = sensor.humidity()

            # JSON format for easy ingestion by cluster monitoring tools
            response = '{{"temperature_c": {}, "humidity": {}}}'.format(temp_c, hum)

            # Send HTTP headers and JSON payload
            cl.send("HTTP/1.0 200 OK\r\nContent-type: application/json\r\n\r\n")
            cl.send(response)

        except OSError as e:
            # DHT sensors can occasionally fail to read; handle gracefully
            print("Sensor read error.")
            cl.send("HTTP/1.0 500 Internal Server Error\r\n\r\n")
        finally:
            cl.close()


def main():
    try:
        ip = connect_wifi()

        # Initialize sensor. Change to dht.DHT11(Pin(DHT_PIN)) if using the older DHT11 module.
        sensor = dht.DHT22(Pin(DHT_PIN))

        start_metrics_server(ip, sensor)

    except Exception as e:
        print(f"Fatal error: {e}")
        # Consider adding a machine.reset() here for autonomous recovery in a production cluster


if __name__ == "__main__":
    main()
