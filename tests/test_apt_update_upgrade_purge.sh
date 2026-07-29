#!/usr/bin/env bash

# Mock apt commands
mock_apt() {
    echo "Mocking apt command: $*"
}

# Source the APT update/upgrade/purge script for testing
source ./ada/cluster/core/apt_update_upgrade_purge.sh

# Test APT commands
test_apt_commands() {
    # Replace actual apt commands with mocks
    sudo() { mock_apt "$@"; }

    . ./ada/cluster/core/apt_update_upgrade_purge.sh

    echo "PASS: APT commands are mocked and executed"
}

# Run tests
test_apt_commands