#!/usr/bin/env bash
# Takes in a node name and path to cluster.env, then generates a hardcoded client bootstrapper script.
# SCP the generated script to the client node and execute it to bootstrap the respective node.
usage_str="Usage: ${0} </path/to/cluster.env> <node>"

if [ -z "$2" ]; then
    echo "$usage_str"
    exit 1
fi

cluster_env="$1"
node="$2"

if [[ ! -f "${cluster_env}" ]]; then
    echo "Error: cluster_env=<${cluster_env}> not found"
    exit 1
fi

source "$cluster_env"

if [[ ! -d "${ADA_CLUSTER}/nodes/${node}" ]]; then
    echo "Error: node=<${node}> not found"
    exit 1
fi

output_dir="${BOOTSTRAPPER_OUTPUT_DIR:-${HOME}/Downloads}"
mkdir -p "$output_dir"

output_file="$output_dir/adalovespace_v${ADA_VERSION}-${node}-bootstrapper-$(date +"%Y%m%d_%s").sh"

tee "$output_file" > /dev/null << EOF
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
for macro in "${ADA_CODESPACE}"/cluster/lib/*.sh; do
    sudo ln -sf "$macro" "/usr/local/bin/${macro%.sh##*/}"
done

# 4. Pivot Execution to Local Mirror Context
buildscript="${ADA_CODESPACE}/cluster/nodes/${node}/build_node.sh"
echo "executing ${buildscript}"
exec "${buildscript}"
EOF

chmod +x "$output_file"
echo "Generated bootstrapper script: $output_file"
