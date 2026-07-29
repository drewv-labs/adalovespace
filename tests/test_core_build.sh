#!/usr/bin/env bash

# Source the core build script for testing
source ./ada/cluster/core/build.sh

# Test variant validation
test_variant_validation() {
    # Provide an invalid variant and check if script fails
    if ! . ./ada/cluster/core/build.sh invalid; then
        echo "PASS: Variant validation works with invalid variant"
    else
        echo "FAIL: Variant validation did not work with invalid variant"
        exit 1
    fi

    # Provide a valid variant and check if script succeeds
    if . ./ada/cluster/core/build.sh debian; then
        echo "PASS: Variant validation works with valid variant"
    else
        echo "FAIL: Variant validation did not work with valid variant"
        exit 1
    fi
}

# Run tests
test_variant_validation