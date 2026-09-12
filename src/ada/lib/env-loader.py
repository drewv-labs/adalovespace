#!/usr/bin/env python3
"""ada/lib/env-loader.py — Extract config values from TOML as flat KEY=VALUE pairs.

Usage:
    # Load all values into current shell (bootstrap scripts):
    set -a; source <(python3 ada/lib/env-loader.py); set +a

    # Load specific keys only:
    python3 ada/lib/env-loader.py mqtt_broker psql_db_name

    # Output as flat key=value for Go/Rust/Python consumers:
    python3 ada/lib/env-loader.py --as-toml

Environment:
    ADALOVESPACE_CONF  — override config path (default: ./ada/ada_config.toml)

Exit codes:
    0 — success
    1 — config not found or parse error
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import tomllib
from pathlib import Path


def load_config() -> dict:
    """Load and return parsed TOML configuration."""
    conf_path = Path(
        os.environ.get(
            "ADALOVESPACE_CONF",
            str(Path(__file__).resolve().parent.parent / "ada_config.toml"),
        )
    )
    if not conf_path.is_file():
        print(f"FATAL: config not found at {conf_path}", file=sys.stderr)
        sys.exit(1)
    try:
        with open(conf_path, "rb") as f:
            return tomllib.load(f)
    except tomllib.TOMLDecodeError as e:
        print(f"FATAL: TOML parse error in {conf_path}: {e}", file=sys.stderr)
        sys.exit(1)


def to_env_string(data: dict, keys: list[str] | None = None) -> str:
    """Flatten config and format as export KEY=VALUE lines."""
    if keys:
        key_set = {k.lower() for k in keys}
        data = {k: v for k, v in data.items() if k.lower() in key_set}

    lines: list[str] = []
    for key, value in sorted(data.items()):
        env_key = key.upper().replace("-", "_")
        if isinstance(value, bool):
            # Bash-compatible boolean strings
            str_value = "true" if value else "false"
        elif isinstance(value, int):
            str_value = str(value)
        elif isinstance(value, list):
            # Arrays become space-separated strings (bash-friendly)
            str_value = " ".join(str(v) for v in value)
        else:
            str_value = str(value)
        lines.append(f'export {env_key}="{str_value}"')
    return "\n".join(lines) + "\n"


def to_toml_string(data: dict, keys: list[str] | None = None) -> str:
    """Format as flat key=value pairs for Go/Rust/Python consumers."""
    if keys:
        key_set = {k.lower() for k in keys}
        data = {k: v for k, v in data.items() if k.lower() in key_set}

    lines: list[str] = []
    for key, value in sorted(data.items()):
        env_key = key.upper().replace("-", "_")
        if isinstance(value, bool):
            lines.append(f'{env_key} = {str(value).lower()}')
        elif isinstance(value, int):
            lines.append(f"{env_key} = {value}")
        elif isinstance(value, list):
            # JSON array format for multi-valued fields
            lines.append(f'{env_key} = {json.dumps([str(v) for v in value])}')
        else:
            lines.append(f'{env_key} = "{value}"')
    return "\n".join(lines) + "\n"


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Extract AdaLovespace config as flat environment variables."
    )
    parser.add_argument(
        "keys",
        nargs="*",
        help="Specific keys to extract (e.g., mqtt_broker psql_db_name). Omit for all.",
    )
    parser.add_argument(
        "--as-toml",
        action="store_true",
        help="Output as flat key=value pairs (no export prefix) for TOML consumers.",
    )
    args = parser.parse_args()

    config = load_config()

    if args.as_toml:
        print(to_toml_string(config, args.keys or None))
    else:
        print(to_env_string(config, args.keys or None))


if __name__ == "__main__":
    main()
