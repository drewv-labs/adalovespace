#!/usr/bin/env bash
# DEPRECATED (2025-07-16): JakeBase now self-bootstraps via ada-selfboot.sh
# No longer generates a separate bootstrapper. Instead:
#
#   ssh jakebase
#   cd /home/drew/adalovespace && git pull
#   sudo ./cluster/nodes/jakebase/build_node.sh
#

echo "DEPRECATED: JakeBase build_node.sh now self-bootstraps."
echo "New flow:"
echo ""
echo "  ssh jakebase"
echo "  cd /home/drew/adalovespace && git pull"
echo "  sudo ./cluster/nodes/jakebase/build_node.sh"
exit 0
