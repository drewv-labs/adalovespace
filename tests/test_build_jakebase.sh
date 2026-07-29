#!/usr/bin/env bash

# Source the main build script for testing
source ./ada/cluster/build_jakebase.sh

# Test environment variable validation
test_env_var_validation() {
    # Unset required variables and check if script fails
    unset ADA_CODESPACE
    if ! . ./ada/cluster/build_jakebase.sh; then
        echo "PASS: Environment variable validation works"
    else
        echo "FAIL: Environment variable validation did not work"
        exit 1
    fi

    # Set required variables and check if script succeeds
    export ADA_CODESPACE="$HOME/adalovespace/ada/clusters"
    export ADA_CLUST_S="ada/cluster"
    export ADA_CLUSTER="ada/clusters/jakebase"
    export JAKEBASE_HW="jakebase-hw"

    if . ./ada/cluster/build_jakebase.sh; then
        echo "PASS: Environment variable validation works with valid variables"
    else
        echo "FAIL: Environment variable validation did not work with valid variables"
        exit 1
    fi
}

# Test script presence validation
test_script_validation() {
    # Remove a required script and check if script fails
    mv ./ada/cluster/core/build.sh ./ada/cluster/core/build.sh.bak
    if ! . ./ada/cluster/build_jakebase.sh; then
        echo "PASS: Script presence validation works"
    else
        echo "FAIL: Script presence validation did not work"
        exit 1
    fi

    # Restore the required script and check if script succeeds
    mv ./ada/cluster/core/build.sh.bak ./ada/cluster/core/build.sh
    if . ./ada/cluster/build_jakebase.sh; then
        echo "PASS: Script presence validation works with valid scripts"
    else
        echo "FAIL: Script presence validation did not work with valid scripts"
        exit 1
    fi
}

# Run tests
test_env_var_validation
test_script_validation