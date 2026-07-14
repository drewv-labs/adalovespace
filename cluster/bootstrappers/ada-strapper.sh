#!/bin/zsh
#
# === Assumes running on MacBook
#
# === ada-strapper.sh <node> [cluster_env]
# ---> acceptable node values: adabrain caroline-v jakebase margaret maryguider
# ---> default cluster_env: /opt/adalovespace/cluster.env
#
# ** planning on running from /usr/local/bin/ada-strap on local MacBook to make the bootstrappers
# Local usage:
# $ ada-strap jakebase
# $ ada-strap margaret
#

node="${1}"
cluster_env="${2:-/opt/adalovespace/cluster.env}"

if [[ ! -f "$cluster_env" ]]; then
    echo "Cluster environment file not found: $cluster_env"
    exit 1
fi

source "$cluster_env"

if [[ ! -d "$ADA_CLUSTER/nodes/$node" ]]; then
    echo "Node not found: $node"
    exit 1
fi

scripts="${ADA_CLUSTER}/bootstrappers/scripts"
case "$node" in
    "jakebase")
        "${scripts}/make_host_bootstrapper.sh" "$cluster_env"
        ;;
    *)
        "${scripts}/make_client_bootstrapper.sh" "$cluster_env" "$node"
        ;;
esac
