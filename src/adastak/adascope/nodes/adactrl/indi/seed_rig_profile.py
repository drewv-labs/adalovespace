#!/usr/bin/env python3
"""
DREW-V Labs // AdaCtrl INDI Web Manager Profile & Device XML Seeder
Path: adalovespace/src/adastak/adascope/nodes/adactrl/indi/seed_rig_profile.py

Idempotently seeds `~/.indi/profiles.db` with the `Ada Lovespace Rig` profile
(`autostart=1`, `autoconnect=1`, `:7624`) and populates missing `~/.indi/*_config.xml`
files from `indi/configs/*.xml.tmpl` without overwriting existing calibrated XMLs.
"""

from __future__ import annotations

import argparse
import glob
import os
import pwd
import sqlite3
from pathlib import Path

RIG_DRIVERS_DEFAULT: tuple[str, ...] = (
    "RBF Excalibur",
    "ZWO CCD",
    "ZWO EFW",
    "ZWO EAF",
    "Rotator Mini V1-2",
    "ZWO AM5 USB",
)

SIMULATOR_DRIVERS: tuple[str, ...] = (
    "Telescope Simulator",
    "CCD Simulator",
    "Focuser Simulator",
)


def resolve_excalibur_port() -> str:
    matches = sorted(glob.glob("/dev/serial/by-id/usb-Espressif_USB_JTAG_serial_debug_unit_*-if00"))
    if matches:
        return matches[0]
    return "/dev/ttyACM1"


def seed_profiles_db(
    db_path: Path,
    profile_name: str,
    indi_port: int,
    include_zwo: bool,
) -> bool:
    """Ensure `profiles.db` exists and holds the active `Ada Lovespace Rig` profile.
    Returns True if database state was modified, False if already converged.
    """
    desired_drivers = [
        d for d in RIG_DRIVERS_DEFAULT if include_zwo or not d.startswith("ZWO ") or d == "ZWO AM5 USB"
    ]

    db_existed = db_path.exists()
    changed = False

    con = sqlite3.connect(str(db_path))
    try:
        cur = con.cursor()
        cur.execute("CREATE TABLE IF NOT EXISTS Version (version TEXT)")
        cur.execute(
            "CREATE TABLE IF NOT EXISTS profile ("
            "id INTEGER PRIMARY KEY AUTOINCREMENT, "
            "name TEXT UNIQUE, "
            "port INTEGER DEFAULT 7624, "
            "autostart INTEGER DEFAULT 0, "
            "autoconnect INTEGER DEFAULT 0, "
            "scripts TEXT DEFAULT NULL)"
        )
        cur.execute(
            "CREATE TABLE IF NOT EXISTS driver ("
            "id INTEGER PRIMARY KEY AUTOINCREMENT, "
            "label TEXT, "
            "profile INTEGER)"
        )
        cur.execute(
            "CREATE TABLE IF NOT EXISTS custom ("
            "id INTEGER PRIMARY KEY AUTOINCREMENT, "
            "label TEXT UNIQUE, "
            "name TEXT, "
            "family TEXT, "
            "exec TEXT, "
            "version TEXT)"
        )
        cur.execute(
            "CREATE TABLE IF NOT EXISTS remote ("
            "id INTEGER PRIMARY KEY AUTOINCREMENT, "
            "drivers TEXT, "
            "profile INTEGER)"
        )

        ver_row = cur.execute("SELECT version FROM Version LIMIT 1").fetchone()
        if ver_row is None:
            cur.execute("INSERT INTO Version (version) VALUES (?)", ("0.1.8",))
            changed = True

        if not db_existed:
            cur.execute(
                "INSERT OR IGNORE INTO profile (name, port, autostart, autoconnect, scripts) "
                "VALUES (?, ?, 0, 0, NULL)",
                ("Simulators", indi_port),
            )
            sim_id_row = cur.execute("SELECT id FROM profile WHERE name = ?", ("Simulators",)).fetchone()
            if sim_id_row is not None:
                for drv in SIMULATOR_DRIVERS:
                    cur.execute("INSERT INTO driver (label, profile) VALUES (?, ?)", (drv, sim_id_row[0]))
            changed = True

        rig_row = cur.execute(
            "SELECT id, port, autostart, autoconnect FROM profile WHERE name = ?",
            (profile_name,),
        ).fetchone()

        if rig_row is None:
            cur.execute("UPDATE profile SET autostart = 0 WHERE autostart != 0")
            cur.execute(
                "INSERT INTO profile (name, port, autostart, autoconnect, scripts) VALUES (?, ?, 1, 1, '')",
                (profile_name, indi_port),
            )
            rig_id = int(cur.lastrowid or 0)
            for drv in desired_drivers:
                cur.execute("INSERT INTO driver (label, profile) VALUES (?, ?)", (drv, rig_id))
            changed = True
        else:
            rig_id, cur_port, cur_autostart, cur_autoconnect = rig_row
            if (cur_port, cur_autostart, cur_autoconnect) != (indi_port, 1, 1):
                cur.execute("UPDATE profile SET autostart = 0 WHERE id != ? AND autostart != 0", (rig_id,))
                cur.execute(
                    "UPDATE profile SET port = ?, autostart = 1, autoconnect = 1 WHERE id = ?",
                    (indi_port, rig_id),
                )
                changed = True

            existing_drivers = [
                r[0] for r in cur.execute("SELECT label FROM driver WHERE profile = ? ORDER BY id", (rig_id,)).fetchall()
            ]
            for drv in desired_drivers:
                if drv not in existing_drivers:
                    cur.execute("INSERT INTO driver (label, profile) VALUES (?, ?)", (drv, rig_id))
                    changed = True

        if changed:
            con.commit()
    finally:
        con.close()

    return changed


def seed_xml_templates(
    indi_dir: Path,
    templates_dir: Path,
    user_home: Path,
    site_lat: str,
    site_lon: str,
    site_elev: str,
    reset_configs: bool,
) -> int:
    excalibur_port = resolve_excalibur_port()
    seeded_count = 0

    for tmpl_path in sorted(templates_dir.glob("*.xml.tmpl")):
        target_name = tmpl_path.name.removesuffix(".tmpl")
        dst_xml = indi_dir / target_name
        dst_default = indi_dir / f"{target_name}.default"

        rendered = (
            tmpl_path.read_text(encoding="utf-8")
            .replace("{{USER_HOME}}", str(user_home))
            .replace("{{SITE_LAT}}", site_lat)
            .replace("{{SITE_LON}}", site_lon)
            .replace("{{SITE_ELEV}}", site_elev)
            .replace("{{EXCALIBUR_PORT}}", excalibur_port)
        )

        if reset_configs or not dst_xml.exists():
            dst_xml.write_text(rendered, encoding="utf-8")
            seeded_count += 1
        if reset_configs or not dst_default.exists():
            dst_default.write_text(rendered, encoding="utf-8")

    return seeded_count


def chown_tree(root: Path, uid: int, gid: int) -> None:
    os.chown(root, uid, gid)
    for entry in root.rglob("*"):
        os.chown(entry, uid, gid)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Seed AdaCtrl INDI profile & XML configs.")
    parser.add_argument("--user", required=True, help="Runtime owner username for ~/.indi")
    parser.add_argument("--profile-name", default="Ada Lovespace Rig")
    parser.add_argument("--indi-port", type=int, default=7624)
    parser.add_argument("--site-lat", default="32.78")
    parser.add_argument("--site-lon", default="263.20")
    parser.add_argument("--site-elev", default="130.0")
    parser.add_argument("--include-zwo", action="store_true")
    parser.add_argument("--reset-configs", action="store_true")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    pw = pwd.getpwnam(args.user)
    user_home = Path(pw.pw_dir)
    indi_dir = user_home / ".indi"
    indi_dir.mkdir(parents=True, exist_ok=True)

    templates_dir = Path(__file__).resolve().parent / "configs"
    db_path = indi_dir / "profiles.db"

    db_changed = seed_profiles_db(
        db_path=db_path,
        profile_name=args.profile_name,
        indi_port=args.indi_port,
        include_zwo=args.include_zwo,
    )
    xml_seeded = seed_xml_templates(
        indi_dir=indi_dir,
        templates_dir=templates_dir,
        user_home=user_home,
        site_lat=args.site_lat,
        site_lon=args.site_lon,
        site_elev=args.site_elev,
        reset_configs=args.reset_configs,
    )
    chown_tree(indi_dir, pw.pw_uid, pw.pw_gid)

    if db_changed or xml_seeded > 0:
        print(f"  [OK] Converged {indi_dir} (db_updated={db_changed}, xml_seeded={xml_seeded})")
    else:
        print(f"[SKIP] INDI profile '{args.profile_name}' and device XMLs in {indi_dir} already converged")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
