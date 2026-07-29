#!/usr/bin/env bash

# Run all test scripts
./tests/test_build_jakebase.sh
./tests/test_core_build.sh
./tests/test_apt_update_upgrade_purge.sh
./tests/test_jakebase_node_build.sh