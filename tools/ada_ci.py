#!/usr/bin/env python3
"""AdaLovespace static integrity checker, hygiene gate, and GitHub Pages bundler.

Usage:
    python3 tools/ada_ci.py --check
    python3 tools/ada_ci.py --bundle-dist _site
"""

from __future__ import annotations

import argparse
import gzip
import hashlib
import io
import os
import py_compile
import re
import shutil
import subprocess
import sys
import tarfile
from pathlib import Path
from typing import Protocol


class CheckRule(Protocol):
    """Structural protocol for repository verification passes."""

    def run(self, repo_root: Path) -> list[str]: ...


REQUIRED_FILES: tuple[str, ...] = (
    "CNAME",
    "GEMINI.md",
    "README.md",
    "install-cli.sh",
    "forge.sh",
    "lib/common.sh",
    "lib/cgroups.sh",
    "boards/rpi5.env",
    "boards/rv2.env",
    "boards/vf2.env",
    "boards/jptr2.env",
    "boards/n100.env",
    "roles/adactrl.env",
    "roles/jakebase.env",
    "roles/caroline-v.env",
    "roles/margistars.env",
    "roles/alonev-air.env",
    "scripts/ort-adactrl.sh",
    "scripts/verify-convergence.sh",
    "src/adastak/adascope/nodes/adactrl/build.sh",
    "src/adastak/adascope/nodes/adactrl/decommission-maryguider.sh",
    "src/adastak/adascope/nodes/adactrl/indi/build.sh",
    "src/adastak/adascope/nodes/adactrl/indi/seed_rig_profile.py",
    "src/adastak/adascope/nodes/adactrl/phd2/build.sh",
    "src/adastak/adascope/nodes/adactrl/phd2/seed_phd2_config.py",
    "src/adastak/adarak/nodes/jakebase/build.sh",
    "src/adastak/adarak/nodes/caroline-v/build.sh",
    "src/adastak/adarak/nodes/margistars/build.sh",
)

SKIP_DIRS: frozenset[str] = frozenset({
    ".git",
    "_site",
    "__pycache__",
    ".venv",
    ".pytest_cache",
})


def iter_repo_files(repo_root: Path) -> list[Path]:
    """Return sorted tracked/worktree files excluding ignored directories."""
    results: list[Path] = []
    for root, dirs, files in os.walk(repo_root):
        dirs[:] = sorted(d for d in dirs if d not in SKIP_DIRS)
        for fname in sorted(files):
            if fname == ".DS_Store" or fname.endswith(".pyc"):
                continue
            results.append(Path(root) / fname)
    return results


class ManifestRule:
    """Verify required manifests, CNAME, and executable bits."""

    def run(self, repo_root: Path) -> list[str]:
        errors: list[str] = []
        for rel in REQUIRED_FILES:
            target = repo_root / rel
            if not target.is_file():
                errors.append(f"Missing required file: {rel}")
            elif target.stat().st_size == 0:
                errors.append(f"Empty (0-byte) file: {rel}")

        cname_path = repo_root / "CNAME"
        if cname_path.is_file():
            cname_val = cname_path.read_text(encoding="utf-8").strip()
            if cname_val != "adalovespace.dev":
                errors.append(f"CNAME expected 'adalovespace.dev', got '{cname_val}'")
        return errors


class ShellSyntaxAndLintRule:
    """Run `bash -n` and `shellcheck -x -S warning` across all `.sh` scripts."""

    def run(self, repo_root: Path) -> list[str]:
        errors: list[str] = []
        sh_files = [p for p in iter_repo_files(repo_root) if p.suffix == ".sh"]
        if not sh_files:
            return ["No .sh scripts discovered in repository"]

        for sh_path in sh_files:
            rel = sh_path.relative_to(repo_root)
            proc = subprocess.run(
                ["bash", "-n", str(sh_path)],
                capture_output=True,
                text=True,
                check=False,
            )
            if proc.returncode != 0:
                errors.append(f"bash -n failed for {rel}: {proc.stderr.strip()}")

        shellcheck_bin = shutil.which("shellcheck")
        if shellcheck_bin is not None:
            proc = subprocess.run(
                [shellcheck_bin, "-x", "-S", "warning", *[str(p) for p in sh_files]],
                cwd=repo_root,
                capture_output=True,
                text=True,
                check=False,
            )
            if proc.returncode != 0:
                errors.append(f"shellcheck warnings/errors:\n{proc.stdout}{proc.stderr}".rstrip())
        return errors


class PythonCompileRule:
    """Compile-check all Python modules in the repository."""

    def run(self, repo_root: Path) -> list[str]:
        errors: list[str] = []
        py_files = [p for p in iter_repo_files(repo_root) if p.suffix == ".py"]
        for py_path in py_files:
            try:
                py_compile.compile(str(py_path), doraise=True)
            except py_compile.PyCompileError as exc:
                errors.append(f"py_compile failed for {py_path.relative_to(repo_root)}: {exc}")
        return errors


class HygieneRule:
    """Enforce cross-repo subnet hygiene, coordinate sanitization, and scheduler safety."""

    _BRAKER_SUBNET_RE = re.compile(r"\b10\.0\.10\.\d{1,3}\b")
    _UNSAFE_EVAL_RE = re.compile(r"\beval\s+echo\s+~")
    _HIGH_PREC_COORD_RE = re.compile(r"\b\d{2,3}\.\d{7,}\b")
    _RT_SCHED_RE = re.compile(r"CPUSchedulingPolicy\s*=\s*(fifo|rr)\b", re.IGNORECASE)

    def run(self, repo_root: Path) -> list[str]:
        errors: list[str] = []
        self_rel = Path("tools/ada_ci.py")
        gemini_rel = Path("GEMINI.md")

        for path in iter_repo_files(repo_root):
            rel = path.relative_to(repo_root)
            if rel == self_rel:
                continue
            try:
                text = path.read_text(encoding="utf-8")
            except UnicodeDecodeError:
                continue

            if rel != gemini_rel and self._BRAKER_SUBNET_RE.search(text):
                errors.append(f"{rel}: contains forbidden BrakerRak 10.0.10.0/24 literal")

            if path.suffix == ".sh":
                if self._UNSAFE_EVAL_RE.search(text):
                    errors.append(f"{rel}: contains unsafe 'eval echo ~' construct")
                if self._RT_SCHED_RE.search(text):
                    errors.append(f"{rel}: sets forbidden SCHED_FIFO/SCHED_RR policy")

            if path.suffix in {".tmpl", ".xml", ".env", ".example"}:
                if self._HIGH_PREC_COORD_RE.search(text):
                    errors.append(f"{rel}: contains unsanitized high-precision GPS decimal literal")
        return errors


def resolve_version(repo_root: Path) -> str:
    """Resolve short git SHA or fallback version string."""
    proc = subprocess.run(
        ["git", "-C", str(repo_root), "rev-parse", "--short", "HEAD"],
        capture_output=True,
        text=True,
        check=False,
    )
    if proc.returncode == 0 and proc.stdout.strip():
        return proc.stdout.strip()
    return "0.1.0"


def render_index_html(version: str, tarball_sha256: str) -> str:
    """Render static landing page for https://adalovespace.dev."""
    return f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>AdaLovespace // DREW-V Labs</title>
  <style>
    :root {{
      --bg: #0b0f17;
      --panel: #121926;
      --border: #233047;
      --fg: #e5edf8;
      --muted: #93a4bd;
      --accent: #7dd3fc;
      --ok: #34d399;
    }}
    * {{ box-sizing: border-box; }}
    body {{
      margin: 0;
      padding: 3rem 1.25rem;
      font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
      background: var(--bg);
      color: var(--fg);
      line-height: 1.6;
    }}
    main {{ max-width: 860px; margin: 0 auto; }}
    h1 {{ font-size: 1.65rem; margin: 0 0 0.35rem; color: var(--accent); }}
    h2 {{ font-size: 1.05rem; margin: 2rem 0 0.75rem; color: var(--fg); text-transform: uppercase; letter-spacing: 0.05em; }}
    p {{ color: var(--muted); margin: 0.5rem 0 1rem; }}
    pre {{
      background: var(--panel);
      border: 1px solid var(--border);
      border-radius: 8px;
      padding: 1rem 1.15rem;
      overflow-x: auto;
      color: var(--fg);
      font-size: 0.9rem;
    }}
    .badge {{
      display: inline-block;
      padding: 0.15rem 0.55rem;
      border: 1px solid var(--border);
      border-radius: 999px;
      font-size: 0.78rem;
      color: var(--ok);
      background: var(--panel);
    }}
    table {{
      width: 100%;
      border-collapse: collapse;
      margin-top: 0.5rem;
      font-size: 0.86rem;
    }}
    th, td {{
      text-align: left;
      padding: 0.55rem 0.75rem;
      border-bottom: 1px solid var(--border);
    }}
    th {{ color: var(--accent); }}
    footer {{
      margin-top: 3rem;
      padding-top: 1rem;
      border-top: 1px solid var(--border);
      font-size: 0.78rem;
      color: var(--muted);
    }}
    a {{ color: var(--accent); text-decoration: none; }}
    a:hover {{ text-decoration: underline; }}
  </style>
</head>
<body>
  <main>
    <span class="badge">engine {version}</span>
    <h1>AdaLovespace // AdaStak Bare-Metal Engine</h1>
    <p>Declarative RISC-V &amp; Edge Astrophotography Compute Engine by DREW-V Labs (RVDK + CarrierPigeons + INDI + Headless PHD2).</p>

    <h2>Day-0 Bootstrap &amp; Node Convergence</h2>
    <pre><code>curl -fsSL https://adalovespace.dev/install-cli.sh | sudo bash
sudo ada init
$EDITOR ~/.adalovespace/node.env
sudo ada forge
sudo ada ort</code></pre>

    <h2>Cgroup v2 Core Partitioning (AdaCtrl-RPI5 &rarr; AdaCtrl-RV2)</h2>
    <table>
      <thead>
        <tr>
          <th>Slice</th>
          <th>AdaCtrl-RPI5 (4c)</th>
          <th>AdaCtrl-RV2 (8c)</th>
          <th>Assigned Workloads</th>
        </tr>
      </thead>
      <tbody>
        <tr><td>system / user / observability</td><td>0</td><td>0-1</td><td>RP1 / PLIC IRQs (xhci, eth0), SSH, CarrierPigeons pigeoneer</td></tr>
        <tr><td>indi.slice</td><td>1-2</td><td>2-4</td><td>indiwebmanager (:8624) + indiserver (:7624) + ZWO/AM5/EAF/EFW/Excalibur</td></tr>
        <tr><td>guiding.slice</td><td>3</td><td>5</td><td>Decoupled Xvfb (:99) + Headless PHD2 (:4400, Nice=-10, CLS=TS)</td></tr>
        <tr><td>inference.slice</td><td>stub</td><td>6-7</td><td>Reserved ALOne-V Air Edge NPU (Hailo-10H)</td></tr>
      </tbody>
    </table>

    <footer>
      DREW-V Labs &middot; Dallas, TX &middot;
      <a href="/install-cli.sh">install-cli.sh</a> &middot;
      <a href="/engine.tar.gz">engine.tar.gz</a> &middot;
      SHA-256: <code>{tarball_sha256[:16]}&hellip;</code>
    </footer>
  </main>
</body>
</html>
"""


def build_deterministic_tarball(repo_root: Path, version: str) -> tuple[bytes, str]:
    """Create a deterministic `engine.tar.gz` archive and return `(bytes, sha256_hex)`."""
    buf = io.BytesIO()
    with gzip.GzipFile(filename="engine.tar.gz", mode="wb", fileobj=buf, mtime=0) as gz:
        with tarfile.open(mode="w", fileobj=gz, format=tarfile.PAX_FORMAT) as tf:
            ver_bytes = f"{version}\n".encode("utf-8")
            ver_info = tarfile.TarInfo(name="VERSION")
            ver_info.size = len(ver_bytes)
            ver_info.mtime = 0
            ver_info.mode = 0o644
            ver_info.uid = 0
            ver_info.gid = 0
            ver_info.uname = "root"
            ver_info.gname = "root"
            tf.addfile(ver_info, io.BytesIO(ver_bytes))

            for path in iter_repo_files(repo_root):
                rel = path.relative_to(repo_root).as_posix()
                if rel.startswith(".github/"):
                    continue
                data = path.read_bytes()
                info = tarfile.TarInfo(name=rel)
                info.size = len(data)
                info.mtime = 0
                info.mode = 0o755 if path.suffix in {".sh", ".py"} else 0o644
                info.uid = 0
                info.gid = 0
                info.uname = "root"
                info.gname = "root"
                tf.addfile(info, io.BytesIO(data))

    raw = buf.getvalue()
    digest = hashlib.sha256(raw).hexdigest()
    return raw, digest


def bundle_dist(repo_root: Path, out_dir: Path) -> None:
    """Stage GitHub Pages static distribution into `out_dir`."""
    if out_dir.exists():
        shutil.rmtree(out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    version = resolve_version(repo_root)
    tar_bytes, tar_sha = build_deterministic_tarball(repo_root, version)

    shutil.copy2(repo_root / "CNAME", out_dir / "CNAME")
    shutil.copy2(repo_root / "install-cli.sh", out_dir / "install-cli.sh")
    shutil.copy2(repo_root / "forge.sh", out_dir / "forge.sh")
    (out_dir / ".nojekyll").write_text("", encoding="utf-8")
    (out_dir / "VERSION").write_text(f"{version}\n", encoding="utf-8")
    (out_dir / "engine.tar.gz").write_bytes(tar_bytes)
    (out_dir / "engine.sha256").write_text(f"{tar_sha}  engine.tar.gz\n", encoding="utf-8")
    (out_dir / "index.html").write_text(render_index_html(version, tar_sha), encoding="utf-8")
    print(f"[ADA:CI] Staged Pages bundle in {out_dir} (version={version}, sha256={tar_sha[:16]}...)")


def run_checks(repo_root: Path) -> int:
    """Run all registered verification passes."""
    rules: tuple[CheckRule, ...] = (
        ManifestRule(),
        ShellSyntaxAndLintRule(),
        PythonCompileRule(),
        HygieneRule(),
    )
    all_errors: list[str] = []
    for rule in rules:
        all_errors.extend(rule.run(repo_root))

    if all_errors:
        for err in all_errors:
            print(f"[ADA:CI:FAIL] {err}", file=sys.stderr)
        return 1

    print("[ADA:CI:OK] All manifest, bash -n, shellcheck, py_compile, and hygiene checks passed.")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="AdaLovespace CI & Pages Bundler")
    parser.add_argument("--check", action="store_true", help="Run static integrity & hygiene checks")
    parser.add_argument("--bundle-dist", type=Path, default=None, help="Output directory for GitHub Pages bundle")
    args = parser.parse_args()

    repo_root = Path(__file__).resolve().parent.parent

    if not args.check and args.bundle_dist is None:
        parser.error("Specify --check and/or --bundle-dist <dir>")

    if args.check:
        rc = run_checks(repo_root)
        if rc != 0:
            return rc

    if args.bundle_dist is not None:
        out_dir = args.bundle_dist if args.bundle_dist.is_absolute() else (repo_root / args.bundle_dist)
        bundle_dist(repo_root, out_dir)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
