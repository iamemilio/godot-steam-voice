#!/usr/bin/env python3
"""Launch the dev-only audio fixture recorder as a standalone window (not shipped in the addon)."""

from __future__ import annotations

import os
import shutil
import subprocess
import sys
from pathlib import Path

ADDON_ROOT = Path(__file__).resolve().parent.parent
SCENE = "res://tools/audio_recording/audio_recording.tscn"


def _find_godot() -> Path | None:
    env_path = os.environ.get("GODOT_PATH") or os.environ.get("GODOT")
    if env_path:
        candidate = Path(env_path)
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


def main() -> int:
    godot = _find_godot()
    if godot is None:
        print("Godot not found — set GODOT_PATH or tools/godot_path.local.txt", file=sys.stderr)
        return 1

    fixture_dir = ADDON_ROOT / "tests" / "fixtures" / "audio"
    fixture_dir.mkdir(parents=True, exist_ok=True)
    print(f"Launching audio recorder (fixtures -> {fixture_dir})")
    return subprocess.run(
        [str(godot), "--path", str(ADDON_ROOT), "--scene", SCENE],
        cwd=str(ADDON_ROOT),
    ).returncode


if __name__ == "__main__":
    raise SystemExit(main())
