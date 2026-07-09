#!/bin/bash
# Define variables based on the node argument
# This script assumes the node is a valid directory within /opt/ada-codespace/nodes/
# and that the bootstrapper.sh script exists in that directory.

# Check if the node argument is provided
if [ -z "$2" ]; then
    echo "Usage: $0 <node> </path/to/cluster.env>"
    exit 1
fi

source $cluster_env

node = $1
cluster_env = $2
codespace = "/opt/adalovespace"
output_file = "~/Downloads/client-${node}-adalovespace-v${ADA_VERSION}-$(date +"%Y%m%d.$(date +%s)").sh"

tee -a $output_file << EOF
#!/bin/bash
# This buildscript was generated at $(date)
set -euxo pipefail

# 1. Mount the central file systems from JakeBase if not present
if ! mountpoint -q ${NFS_CODE}; then
    sudo mkdir -p ${NFS_CODE}
    sudo mount -t nfs ${NFS_HOST}:${NFS_CODE} ${NFS_CODE}
fi

# 2. Synchronize Code to Local Solid-State Runtime Mirror
# This is blistering fast and detaches runtime execution from network I/O
sudo mkdir -p ${codespace}
sudo rsync -aq --delete --progress ${NFS_CODE}/adalovespace/ ${codespace}
echo "Bootstrapper cloned from JakeBaseNFS"

# 3. Soft link libs and utils
sudo ln -s ${codespace}/cluster/lib/ada-preflight.sh /usr/local/bin/ada-preflight
sudo ln -s ${codespace}/cluster/lib/ada-preflight-nosudo.sh /usr/local/bin/ada-preflight-nosudo
sudo ln -s ${codespace}/cluster/lib/safe-tee-sed.sh /usr/local/bin/safe-tee-sed

# 4. Pivot Execution to Local Mirror Context
# Your scripts run with local IOPS speeds, completely immune to field network drops!
buildscript = "${codespace}/cluster/nodes/${node}/build_node.sh"
echo "executing ${buildscript}"
exec ${buildscript}
EOF
