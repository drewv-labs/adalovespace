#!/usr/bin/env bash
# Takes in a path to cluster.env, then generates a hardcoded host bootstrapper script for JakeBase Node.

if [ -z "$1" ]; then
    echo "Usage: $0 </path/to/cluster.env>"
    exit 1
fi

cluster_env="$1"

if [[ ! -f "$cluster_env" ]]; then
    echo "Error: $cluster_env not found"
    exit 1
fi

source "$cluster_env"

output_dir="${BOOTSTRAPPER_OUTPUT_DIR:-${HOME}/Downloads}"
mkdir -p "$output_dir"

output_file="$output_dir/adalovespace_v${ADA_VERSION}-jakebase-bootstrapper-$(date +"%Y%m%d_%s").sh"

tee "$output_file" > /dev/null << EOF
#!/usr/bin/env bash
# This buildscript was generated at $(date)
set -euxo pipefail

# 1. Clone Code to Local Solid-State Runtime Mirror
git clone --depth 1 https://github.com/adalovespace/adalovespace.git "${ADA_CODESPACE}"
sudo chmod -R +x "${ADA_CODESPACE}"

# 2. Soft link libs and utils
for macro in "${ADA_CODESPACE}"/cluster/lib/*.sh; do
    sudo ln -sf "$macro" "/usr/local/bin/${macro%.sh##*/}"
done

# 3. Pivot Execution to Local Mirror Context
buildscript="${ADA_CODESPACE}/cluster/nodes/jakebase/build_node.sh"
echo "executing ${buildscript}"
exec "${buildscript}"
EOF

chmod +x "$output_file"
echo "Generated bootstrapper script: $output_file"
