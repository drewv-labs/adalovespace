#!/usr/bin/env bash
set -euo pipefail

ada-logger main "=== Validating Core Integrity"

integrity_checks=(
    "if [ $(which uv | wc -l) -gt 0 ]; then return 0; else return 1; fi"
)

ada-tegrity "${integrity_checks[@]}"

ada-logger yay "=== Core Integrity Validated"
