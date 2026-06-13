#!/usr/bin/env python3
"""Install a minimal GdUnit4 dev dependency (runtime + CLI, no vendor test suite)."""

from __future__ import annotations

import argparse
import os
import shutil
import stat
import subprocess
import sys
import tempfile
from pathlib import Path

ADDON_ROOT = Path(__file__).resolve().parent.parent
GDUNIT_DIR = ADDON_ROOT / "addons" / "gdUnit4"
GDUNIT_REPO = "https://github.com/godot-gdunit-labs/gdUnit4.git"
VERSION_FILE = Path(__file__).resolve().parent / "gdunit4_version.txt"
CMD_TOOL = GDUNIT_DIR / "bin" / "GdUnitCmdTool.gd"
PLUGIN_SUBPATH = Path("addons") / "gdUnit4"

# GdUnit4's own test suite — not needed to run this project's tests.
REMOVE_FROM_PLUGIN = ("test",)


def read_version() -> str:
    version = VERSION_FILE.read_text(encoding="utf-8").strip()
    if not version:
        raise RuntimeError(f"Missing version in {VERSION_FILE}")
    return version


def is_installed() -> bool:
    return CMD_TOOL.is_file()


def _remove_tree(path: Path) -> None:
    if not path.exists():
        return

    def _on_rm_error(func, rm_path, exc_info):
        if not os.access(rm_path, os.W_OK):
            os.chmod(rm_path, stat.S_IWUSR)
            func(rm_path)
        else:
            raise exc_info[1]

    shutil.rmtree(path, onerror=_on_rm_error)


def install(force: bool = False) -> int:
    if is_installed() and not force:
        print(f"GdUnit4 already installed at {GDUNIT_DIR}")
        return 0

    version = read_version()
    print(f"Installing GdUnit4 {version} into {GDUNIT_DIR}...")

    with tempfile.TemporaryDirectory(prefix="gdunit4-install-") as tmp:
        clone_root = Path(tmp) / "gdUnit4-repo"
        clone = subprocess.run(
            [
                "git",
                "clone",
                "--depth",
                "1",
                "--branch",
                version,
                GDUNIT_REPO,
                str(clone_root),
            ],
            check=False,
        )
        if clone.returncode != 0:
            print(f"Failed to clone GdUnit4 tag {version}.", file=sys.stderr)
            return clone.returncode

        plugin_src = clone_root / PLUGIN_SUBPATH
        if not plugin_src.is_dir():
            print(
                f"Expected plugin at {PLUGIN_SUBPATH} in GdUnit4 {version}.",
                file=sys.stderr,
            )
            return 1

        if GDUNIT_DIR.exists():
            _remove_tree(GDUNIT_DIR)

        GDUNIT_DIR.parent.mkdir(parents=True, exist_ok=True)
        shutil.copytree(plugin_src, GDUNIT_DIR)

    for name in REMOVE_FROM_PLUGIN:
        path = GDUNIT_DIR / name
        if path.exists():
            _remove_tree(path)

    if not is_installed():
        print("GdUnit4 install incomplete — GdUnitCmdTool.gd not found.", file=sys.stderr)
        return 1

    print(f"GdUnit4 {version} installed (src, bin, plugin — without GdUnit4 test suite).")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Install pinned GdUnit4 for dev/CI")
    parser.add_argument("--force", action="store_true", help="Reinstall even if present")
    args = parser.parse_args()
    return install(force=args.force)


if __name__ == "__main__":
    sys.exit(main())
