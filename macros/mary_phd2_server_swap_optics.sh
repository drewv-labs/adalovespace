#!/bin/bash

# Define the PHD2 configuration file path
CONFIG_FILE="$HOME/.PHDGuidingV2"

# Ensure an argument is provided
if [ -z "$1" ]; then
    echo "Error: No optical profile specified."
    echo "Usage: ./swap_optics.sh {base|paracorr|nexus}"
    exit 1
fi

# Map the input to the exact focal length
case "$1" in
    base)
        FL=800
        echo "Optical Profile: Native 8\" f/4 ($FL mm)"
        ;;
    paracorr)
        FL=920
        echo "Optical Profile: Paracorr 1.15x ($FL mm)"
        ;;
    nexus)
        FL=600
        echo "Optical Profile: Starizona Nexus 0.75x ($FL mm)"
        ;;
    *)
        echo "Error: Unknown profile '$1'."
        echo "Available profiles: base, paracorr, nexus"
        exit 1
        ;;
esac

# Execute the swap sequence
echo "Stopping PHD2 daemon..."
sudo systemctl stop phd2

echo "Injecting new focal length ($FL) into brain..."
# Use sed to find any line starting with FocalLength= and replace the whole line
sed -i "s/^FocalLength=.*/FocalLength=$FL/" "$CONFIG_FILE"

echo "Rebooting PHD2 daemon..."
sudo systemctl start phd2

echo "Swap complete. Mary is primed and awaiting Margaret's connection."
