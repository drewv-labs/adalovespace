#!/bin/bash
#
echo "=== Installing UV"

curl -LsSf https://astral.sh/uv/install.sh | sudo env UV_INSTALL_DIR="/usr/local/bin" sh
echo ""
