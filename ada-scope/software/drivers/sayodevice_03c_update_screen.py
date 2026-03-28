import hid  # pip install hidapi

# Initialize the device
dev = hid.device()
dev.open(0x8089, 0x0009)


def update_sayo_screen(temp, frames):
    # This is a simplified example of the packet structure
    # The actual O3C protocol requires a specific byte header
    report = [0x00] * 64
    report[0] = 0x02  # Report ID
    report[1] = 0x01  # Command for "Set Text"

    # Encode your data string (Temp and Frames)
    info_str = f"T:{temp}C F:{frames}"
    data_bytes = info_str.encode("utf-16le")  # Sayo often uses UTF-16

    # Fill the buffer and send
    report[3 : 3 + len(data_bytes)] = data_bytes
    dev.write(report)


# Call this whenever your DHT sensor reads or a frame is captured
# update_sayo_screen(24.5, 1200)
#
