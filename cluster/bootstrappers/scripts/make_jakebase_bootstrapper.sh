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

output_file="$output_dir/adalovespace-jakebase-bootstrapper-v${ADA_VERSION}.sh"

tee "$output_file" > /dev/null << EOF
#!/usr/bin/env bash
# This buildscript was generated at $(date)
set -euxo pipefail

# 1. Link the codebase from our admin user to system mirror
sudo ln -sf "/home/${ADA_ADMN}/adalovespace" "${ADA_CODESPACE}"
sudo chmod -R +x "${ADA_CODESPACE}"

# 2. Soft link libs and utils
for macro in "${ADA_CODESPACE}"/cluster/lib/*.sh; do
    target="/usr/local/bin/${macro%.sh##*/}"
    sudo ln -sf "$macro" "$target"
    sudo chmod +x "$target"
done

# 3. Pivot Execution to Local Mirror Context
buildscript="${ADA_CODESPACE}/cluster/nodes/jakebase/build_node.sh"
echo "executing ${buildscript}"
exec "${buildscript}"
EOF

chmod +x "$output_file"
echo "Generated bootstrapper script: $output_file"
