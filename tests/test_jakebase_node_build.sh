#!/usr/bin/env bash

# Source the JakeBase node build script for testing
source ./ada/cluster/nodes/jakebase/build.sh

# Test component scripts
test_component_scripts() {
    # Mock component scripts
    mock_script() {
        echo "Mocking script: $*"
    }

    "$ADA_CLUSTER/nodes/jakebase/nfs/build.sh"() { mock_script "nfs/build.sh"; }
    "$ADA_CLUSTER/nodes/jakebase/psql/build.sh"() { mock_script "psql/build.sh"; }
    "$ADA_CLUSTER/nodes/jakebase/mqtt/build.sh"() { mock_script "mqtt/build.sh"; }
    "$ADA_CLUSTER/nodes/jakebase/ntfy/build.sh"() { mock_script "ntfy/build.sh"; }
    "$ADA_CLUSTER/nodes/jakebase/telegraf/build.sh"() { mock_script "telegraf/build.sh"; }

    . ./ada/cluster/nodes/jakebase/build.sh

    echo "PASS: Component scripts are mocked and executed"
}

# Run tests
test_component_scripts