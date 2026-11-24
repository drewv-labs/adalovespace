#!/usr/bin/env python3
"""
DREW-V Labs // Headless PHD2 wxFileConfig Seeder (`~/.PHDGuidingV2`)
Path: adalovespace/src/adastak/adascope/nodes/adactrl/phd2/seed_phd2_config.py

Idempotently ensures `~/.PHDGuidingV2` enables PHD2's JSON-RPC Event Server
(`ServerMode=1` -> TCP `:4400` on instance 1) and seeds the default `AdaScope-8F4`
equipment profile targeting local `indiserver` (`127.0.0.1:7624`) when absent,
without clobbering existing guiding calibration data on re-runs.
"""

from __future__ import annotations

import argparse
import os
import pwd
import re
from pathlib import Path


def build_initial_config(
    profile_name: str,
    indi_host: str,
    indi_port: int,
    indi_camera: str,
    indi_mount: str,
    pixel_size_um: str,
    focal_length_mm: str,
) -> str:
    return (
        "ConfigVersion=2001\n"
        "LoggingMode=1\n"
        "currentProfile=1\n"
        "ServerMode=1\n"
        "[profile]\n"
        "[profile/1]\n"
        f"name={profile_name}\n"
        "[profile/1/camera]\n"
        "LastMenuChoice=INDI Camera\n"
        f"pixelsize={pixel_size_um}\n"
        "binning=1\n"
        "[profile/1/scope]\n"
        "LastMenuChoice=INDI Mount\n"
        "LastAuxMenuChoice=None\n"
        "[profile/1/guider]\n"
        f"focalLength={focal_length_mm}\n"
        "[profile/1/indi]\n"
        f"INDIhost={indi_host}\n"
        f"INDIport={indi_port}\n"
        f"INDIcam={indi_camera}\n"
        f"INDImount={indi_mount}\n"
    )


def ensure_server_mode_root(existing_text: str) -> tuple[str, bool]:
    """Ensure `ServerMode=1` exists in the root (pre-section) header of `.PHDGuidingV2`."""
    lines = existing_text.splitlines()
    first_section_idx = next((i for i, ln in enumerate(lines) if ln.lstrip().startswith("[")), len(lines))

    root_lines = lines[:first_section_idx]
    rest_lines = lines[first_section_idx:]

    server_re = re.compile(r"^(\s*ServerMode\s*=\s*)(.*)$")
    found = False
    changed = False
    new_root: list[str] = []

    for ln in root_lines:
        m = server_re.match(ln)
        if m:
            found = True
            if m.group(2).strip() != "1":
                new_root.append("ServerMode=1")
                changed = True
            else:
                new_root.append(ln)
        else:
            new_root.append(ln)

    if not found:
        new_root.append("ServerMode=1")
        changed = True

    rendered = "\n".join([*new_root, *rest_lines]) + "\n"
    return rendered, changed


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Seed headless PHD2 ~/.PHDGuidingV2 config.")
    parser.add_argument("--user", required=True)
    parser.add_argument("--profile-name", default="AdaScope-8F4")
    parser.add_argument("--indi-host", default="127.0.0.1")
    parser.add_argument("--indi-port", type=int, default=7624)
    parser.add_argument("--indi-camera", default="ZWO CCD ASI220MM Mini")
    parser.add_argument("--indi-mount", default="ZWO AM5 USB")
    parser.add_argument("--pixel-size-um", default="4.0")
    parser.add_argument("--focal-length-mm", default="300")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    pw = pwd.getpwnam(args.user)
    cfg_path = Path(pw.pw_dir) / ".PHDGuidingV2"

    if not cfg_path.exists():
        content = build_initial_config(
            profile_name=args.profile_name,
            indi_host=args.indi_host,
            indi_port=args.indi_port,
            indi_camera=args.indi_camera,
            indi_mount=args.indi_mount,
            pixel_size_um=args.pixel_size_um,
            focal_length_mm=args.focal_length_mm,
        )
        cfg_path.write_text(content, encoding="utf-8")
        os.chmod(cfg_path, 0o640)
        os.chown(cfg_path, pw.pw_uid, pw.pw_gid)
        print(f"  [OK] Seeded initial PHD2 profile '{args.profile_name}' ({args.indi_host}:{args.indi_port}) -> {cfg_path}")
        return 0

    updated_text, changed = ensure_server_mode_root(cfg_path.read_text(encoding="utf-8"))
    if changed:
        cfg_path.write_text(updated_text, encoding="utf-8")
        os.chown(cfg_path, pw.pw_uid, pw.pw_gid)
        print(f"  [OK] Enabled ServerMode=1 (:4400) in existing {cfg_path}")
    else:
        print(f"[SKIP] PHD2 config {cfg_path} already converged (ServerMode=1)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
