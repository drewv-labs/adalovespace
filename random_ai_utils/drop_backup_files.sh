#!/bin/bash

# Directory to search for .sh files
BASE_DIR="/Users/drew/workspace/github.com/dvandagriff/adalovespace/cluster"

# Find all .sh.bak files and drop
files=$(find "$BASE_DIR" -type f -name "*.sh.bak")
for file in $files; do
    rm "$file"
    echo "Dropped $file"
done
