#!/usr/bin/env bash
set -euo pipefail
source ada-preflight "$BASH_SOURCE"

ada-logger main "=== Validating JakeBase Node Integrity"

integrity_checks=(
    "if [ $(which psql | wc -l) -gt 0 ]; then return 0; else return 1; fi"
)

ada-tegrity "${integrity_checks[@]}"

ada-logger yay "=== JakeBase Node Integrity Validated"
