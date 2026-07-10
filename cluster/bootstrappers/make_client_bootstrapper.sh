#!/bin/bash
# Takes in a node name and path to cluster.env, then generates a hardcoded client bootstrapper script.
# SCP the generated script to the client node and execute it to bootstrap the respective node.

# Check if the node argument is provided
if [ -z "$2" ]; then
    echo "Usage: $0 <node> </path/to/cluster.env>"
    exit 1
fi

node=$1
cluster_env=$2

if [[ -f "$cluster_env" ]]; then
    source $cluster_env
else
    echo "Error: $cluster_env not found"
    exit 1
fi

output_file="~/Downloads/client-${node}-adalovespace-v${ADA_VERSION}-$(date +"%Y%m%d.%s").sh"

tee -a $output_file << EOF
#!/bin/bash
# This buildscript was generated at $(date)
set -euxo pipefail

# 1. Mount the central file systems from JakeBase if not present
if ! mountpoint -q "${NFS_CODE}"; then
    sudo mkdir -p "${NFS_CODE}"
    sudo mount -t nfs "${NFS_HOST}:${NFS_CODE}" "${NFS_CODE}"
fi

# 2. Synchronize Code to Local Solid-State Runtime Mirror
# This is blistering fast and detaches runtime execution from network I/O
sudo mkdir -p "${ADA_CODESPACE}"
sudo rsync -aq --delete --progress "${NFS_CODE}/adalovespace/" "${ADA_CODESPACE}"
echo "Bootstrapper cloned from JakeBaseNFS"

# 3. Soft link libs and utils
sudo ln -s ${ADA_CODESPACE}/cluster/lib/ada-preflight.sh /usr/local/bin/ada-preflight
sudo ln -s ${ADA_CODESPACE}/cluster/lib/ada-preflight-nosudo.sh /usr/local/bin/ada-preflight-nosudo
sudo ln -s ${ADA_CODESPACE}/cluster/lib/safe-tee-sed.sh /usr/local/bin/safe-tee-sed

# 4. Pivot Execution to Local Mirror Context
# Your scripts run with local IOPS speeds, completely immune to field network drops!
buildscript="${ADA_CODESPACE}/cluster/nodes/${node}/build_node.sh"
echo "executing ${buildscript}"
exec "${buildscript}"
EOF
