#!/usr/bin/env python3
"""Run Godot Steam Voice tests via GdUnit4."""

from __future__ import annotations

import argparse
import os
import shutil
import subprocess
import sys
from pathlib import Path

ADDON_ROOT = Path(__file__).resolve().parent.parent
TEST_LOG = ADDON_ROOT / ".cache" / "godot-tests.log"
REPORTS_DIR = ADDON_ROOT / "reports"
GDUNIT_CMD = "res://addons/gdUnit4/bin/GdUnitCmdTool.gd"
INSTALL_GDUNIT4 = ADDON_ROOT / "tools" / "install_gdunit4.py"


def ensure_gdunit4() -> int:
    if (ADDON_ROOT / "addons" / "gdUnit4" / "bin" / "GdUnitCmdTool.gd").is_file():
        return 0
    print("GdUnit4 not found — running tools/install_gdunit4.py...")
    proc = subprocess.run([sys.executable, str(INSTALL_GDUNIT4)], cwd=str(ADDON_ROOT))
    return proc.returncode


def _find_godot() -> Path | None:
    env_path = os.environ.get("GODOT_PATH") or os.environ.get("GODOT")
    if env_path:
        candidate = Path(env_path)
        if candidate.exists():
            return candidate

    versions_env = ADDON_ROOT.parent.parent / "tools" / "versions.env"
    if versions_env.exists():
        for line in versions_env.read_text(encoding="utf-8").splitlines():
            if line.startswith("GODOT_EDITOR_WIN="):
                candidate = Path(line.split("=", 1)[1].strip().strip('"'))
                if candidate.exists():
                    return candidate

    local_path = ADDON_ROOT / "tools" / "godot_path.local.txt"
    if local_path.is_file():
        candidate = Path(local_path.read_text(encoding="utf-8").strip().strip('"'))
        if candidate.exists():
            return candidate

    which_godot = shutil.which("godot")
    if which_godot:
        return Path(which_godot)
    return None


def _find_gdlint() -> Path | None:
    try:
        scripts_dir = subprocess.check_output(
            [sys.executable, "-c", "import sysconfig; print(sysconfig.get_path('scripts'))"],
            text=True,
        ).strip()
    except subprocess.CalledProcessError:
        return None
    for name in ("gdlint.exe", "gdlint"):
        candidate = Path(scripts_dir) / name
        if candidate.exists():
            return candidate
    return None


def run_lint() -> int:
    gdlint = _find_gdlint()
    if gdlint is None:
        print("gdlint not found — skip lint or install gdtoolkit", file=sys.stderr)
        return 0
    print("Running gdlint on Godot Steam Voice...")
    proc = subprocess.run(
        [str(gdlint), str(ADDON_ROOT)],
        cwd=str(ADDON_ROOT),
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        encoding="utf-8",
        errors="replace",
    )
    output = proc.stdout or ""
    if output.strip():
        print(output, end="" if output.endswith("\n") else "\n")
    if proc.returncode != 0:
        print(f"gdlint failed with exit code {proc.returncode}.", file=sys.stderr)
    return proc.returncode


def run_tests() -> int:
    gdunit_code = ensure_gdunit4()
    if gdunit_code != 0:
        return gdunit_code

    godot = _find_godot()
    if godot is None:
        print(
            "Godot not found. Set GODOT_PATH or install Godot 4.6+.",
            file=sys.stderr,
        )
        return 1

    TEST_LOG.parent.mkdir(parents=True, exist_ok=True)
    REPORTS_DIR.mkdir(parents=True, exist_ok=True)
    env = os.environ.copy()
    env["STEAM_PROXIMITY_VOICE_TEST"] = "1"

    print(f"Importing Godot project at {ADDON_ROOT}...")
    import_proc = subprocess.run(
        [str(godot), "--headless", "--path", str(ADDON_ROOT), "--import"],
        cwd=str(ADDON_ROOT),
        env=env,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        encoding="utf-8",
        errors="replace",
        timeout=int(os.environ.get("GODOT_IMPORT_TIMEOUT_SEC", "180")),
    )
    if import_proc.returncode != 0:
        print(import_proc.stdout)
        print("Godot import failed.", file=sys.stderr)
        return import_proc.returncode

    print(f"Running GdUnit4 tests in {ADDON_ROOT}...")
    proc = subprocess.run(
        [
            str(godot),
            "--headless",
            "--path",
            str(ADDON_ROOT),
            "-s",
            GDUNIT_CMD,
            "-a",
            "res://tests",
            "-rd",
            "reports",
            "-c",
            "--ignoreHeadlessMode",
        ],
        cwd=str(ADDON_ROOT),
        env=env,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        encoding="utf-8",
        errors="replace",
        timeout=int(os.environ.get("GODOT_TEST_TIMEOUT_SEC", "180")),
    )
    output = proc.stdout or ""
    TEST_LOG.write_text(output, encoding="utf-8")
    print(output)
    if proc.returncode != 0:
        print("GdUnit4 tests failed.", file=sys.stderr)
    elif list(REPORTS_DIR.glob("**/results.xml")):
        print(f"JUnit report: {next(REPORTS_DIR.glob('**/results.xml'))}")
    return proc.returncode


def main() -> int:
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    if hasattr(sys.stderr, "reconfigure"):
        sys.stderr.reconfigure(encoding="utf-8", errors="replace")
    parser = argparse.ArgumentParser(description="Godot Steam Voice test runner")
    group = parser.add_mutually_exclusive_group()
    group.add_argument("--lint-only", action="store_true")
    group.add_argument("--tests-only", action="store_true")
    args = parser.parse_args()

    run_lint_flag = not args.tests_only
    run_tests_flag = not args.lint_only

    if run_lint_flag:
        lint_code = run_lint()
        if lint_code != 0:
            return lint_code

    if run_tests_flag:
        return run_tests()

    return 0


if __name__ == "__main__":
    sys.exit(main())
