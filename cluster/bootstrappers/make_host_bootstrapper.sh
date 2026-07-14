#!/usr/bin/env bash
# Takes in a path to cluster.env, then generates a hardcoded host bootstrapper script for JakeBase Node.

if [ -z "$1" ]; then
    echo "Usage: $0 </path/to/cluster.env>"
    exit 1
fi

cluster_env=$1

if [[ ! -f "$cluster_env" ]]; then
    echo "Error: $cluster_env not found"
    exit 1
fi

source $cluster_env

output_dir="${BOOTSTRAPPER_OUTPUT_DIR:-~/Downloads}"
mkdir -p "$output_dir"

output_file="$output_dir/adalovespace_v${ADA_VERSION}-${node}-bootstrapper-$(date +"%Y%m%d_%s").sh"

tee $output_file << EOF
#!/usr/bin/env bash
# This buildscript was generated at $(date)
set -euxo pipefail

# 1. Mount the central file systems from JakeBase if not present
if ! mountpoint -q "${NFS_CODE}"; then
    sudo mkdir -p "${NFS_CODE}"
    sudo mount -t nfs "${NFS_HOST}:${NFS_CODE}" "${NFS_CODE}"
fi

# 2. Synchronize Code to Local Solid-State Runtime Mirror
sudo mkdir -p "${ADA_CODESPACE}"
sudo rsync -aq --delete --progress "${NFS_CODE}/adalovespace/" "${ADA_CODESPACE}"
echo "Bootstrapper cloned from JakeBaseNFS"

# 3. Soft link libs and utils
sudo ln -s ${ADA_CODESPACE}/cluster/lib/ada-log.sh /usr/local/bin/ada-log
sudo ln -s ${ADA_CODESPACE}/cluster/lib/ada-preflight.sh /usr/local/bin/ada-preflight
sudo ln -s ${ADA_CODESPACE}/cluster/lib/ada-preflight-nosudo.sh /usr/local/bin/ada-preflight-nosudo
sudo ln -s ${ADA_CODESPACE}/cluster/lib/arg-switches.sh /usr/local/bin/arg-switches
sudo ln -s ${ADA_CODESPACE}/cluster/lib/safe-tee-sed.sh /usr/local/bin/safe-tee-sed

# 4. Pivot Execution to Local Mirror Context
buildscript="${ADA_CODESPACE}/cluster/nodes/${node}/build_node.sh"
echo "executing ${buildscript}"
exec "${buildscript}"
EOF

chmod +x $output_file
echo "Generated bootstrapper script: $output_file"
