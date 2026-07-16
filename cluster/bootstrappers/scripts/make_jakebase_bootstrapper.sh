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

downloads="${HOME}/Downloads"
output_dir="${BOOTSTRAPPER_OUTPUT_DIR:-${downloads}}"
mkdir -p "$output_dir"

output_file="$output_dir/adalovespace-jakebase-bootstrapper-v$ADA_VERSION.sh"
buildscript="$ADA_CODESPACE/cluster/nodes/jakebase/build_node.sh"

tee "$output_file" > /dev/null << EOF
#!/usr/bin/env bash
# This buildscript was generated at $(date)
set -euxo pipefail

# 1. Link the codebase from our admin user to system mirror
sudo ln -sf "/home/${ADA_ADMN}/adalovespace" "${ADA_CODESPACE}"
sudo chown -R root:root "${ADA_CODESPACE}"
sudo chmod -R +x "${ADA_CODESPACE}"

# 2. Soft link libs and utils
sudo ln -sf "${ADA_CODESPACE}/cluster/lib/ada-log.sh" /usr/local/bin/ada-log && sudo chmod +x /usr/local/bin/ada-log
sudo ln -sf "${ADA_CODESPACE}/cluster/lib/ada-preflight.sh" /usr/local/bin/ada-preflight && sudo chmod +x /usr/local/bin/ada-preflight
sudo ln -sf "${ADA_CODESPACE}/cluster/lib/ada-preflight-nosudo.sh" /usr/local/bin/ada-preflight-nosudo && sudo chmod +x /usr/local/bin/ada-preflight-nosudo
sudo ln -sf "${ADA_CODESPACE}/cluster/lib/arg-switches.sh" /usr/local/bin/arg-switches && sudo chmod +x /usr/local/bin/arg-switches
sudo ln -sf "${ADA_CODESPACE}/cluster/lib/safe-tee-sed.sh" /usr/local/bin/safe-tee-sed && sudo chmod +x /usr/local/bin/safe-tee-sed

# 3. Pivot Execution to Local Mirror Context
echo "executing $buildscript"
exec sudo "$buildscript"
EOF

chmod +x "$output_file"
echo "Generated bootstrapper script: $output_file"
