#!/usr/bin/env bash
set -euo pipefail
source ada-preflight "$BASH_SOURCE"

ada-logger main "=== Validating AdaBrain Node Integrity"

integrity_checks=(
    "if [ $(which indiserver | wc -l) -gt 0 ]; then return 0; else return 1; fi"
)

ada-tegrity "${integrity_checks[@]}"

ada-logger yay "=== AdaBrain Node Integrity Validated"
