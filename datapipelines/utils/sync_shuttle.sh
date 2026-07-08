#!/bin/bash

# Define your source directories and the shuttle destination
# Update these paths based on your OS (e.g., /Volumes/SHUTTLE for Mac, /media/drew/SHUTTLE for Linux)
SOURCE_DIR="$HOME/Projects/"
DEST_DIR="/Volumes/SHUTTLE/Projects_Backup/"

# Check if the Shuttle drive is actually plugged in and mounted
if [ ! -d "$DEST_DIR" ]; then
  echo "Error: SHUTTLE drive not found at $DEST_DIR. Is it plugged in?"
  exit 1
fi

echo "Starting sync to SHUTTLE..."

# Run rsync
# -a: Archive mode (preserves permissions, times, etc.)
# -v: Verbose (shows you what it's doing)
# -h: Human-readable file sizes
# --delete: Removes files on the Shuttle that you've deleted on your main machine (optional, but keeps it 1:1)
rsync -avh --delete "$SOURCE_DIR" "$DEST_DIR"

echo "Sync complete! Don't forget to safely eject."
