#!/usr/bin/env python3
"""Run steam_proximity_voice unit tests (standalone — no Friend Slop required)."""

from __future__ import annotations

import argparse
import os
import shutil
import subprocess
import sys
from pathlib import Path

ADDON_ROOT = Path(__file__).resolve().parent.parent
TEST_LOG = ADDON_ROOT / ".cache" / "godot-tests.log"
TEST_SCRIPT = "res://tests/run_tests.gd"


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
    print("Running gdlint on steam_proximity_voice...")
    proc = subprocess.run(
        [str(gdlint), str(ADDON_ROOT)],
        cwd=str(ADDON_ROOT),
    )
    return proc.returncode


def run_tests() -> int:
    godot = _find_godot()
    if godot is None:
        print(
            "Godot not found. Set GODOT_PATH or install Godot 4.6+.",
            file=sys.stderr,
        )
        return 1

    TEST_LOG.parent.mkdir(parents=True, exist_ok=True)
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
        timeout=int(os.environ.get("GODOT_IMPORT_TIMEOUT_SEC", "180")),
    )
    if import_proc.returncode != 0:
        print(import_proc.stdout)
        print("Godot import failed.", file=sys.stderr)
        return import_proc.returncode

    print(f"Running Godot tests in {ADDON_ROOT}...")
    proc = subprocess.run(
        [
            str(godot),
            "--headless",
            "--path",
            str(ADDON_ROOT),
            "--script",
            TEST_SCRIPT,
        ],
        cwd=str(ADDON_ROOT),
        env=env,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        timeout=int(os.environ.get("GODOT_TEST_TIMEOUT_SEC", "120")),
    )
    TEST_LOG.write_text(proc.stdout, encoding="utf-8")
    print(proc.stdout)
    return proc.returncode


def main() -> int:
    parser = argparse.ArgumentParser(description="steam_proximity_voice test runner")
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
