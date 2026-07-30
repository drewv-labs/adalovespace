#!/bin/bash

# Directory to search for .sh files
BASE_DIR="/Users/drew/workspace/github.com/dvandagriff/adalovespace/cluster"

# Find all .sh files and update the shebang line
find "$BASE_DIR" -type f -name "*.sh" | while read -r file; do
    # Check if the file starts with a different shebang
    if grep -q '^#!' "$file"; then
        # Update the shebang line to use /usr/bin/env bash
        sed -i.bak '1s|^#!/.*bash|#!/usr/bin/env bash|' "$file"
        echo "Updated $file"
    else
        echo "$file does not have a shebang. Skipping."
    fi
done
