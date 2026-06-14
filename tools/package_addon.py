#!/usr/bin/env python3
"""Package the Godot Steam Voice addon for distribution (no tests, docs, or dev tools)."""

from __future__ import annotations

import argparse
import shutil
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_OUT = ROOT / "dist" / "godot-steam-voice"

# Paths relative to repo root — copied into addons/godot-steam-voice/ in a host game.
ADDON_FILES = [
    "voice_session.gd",
    "voice_channel.gd",
    "voice_member.gd",
    "voice_rule.gd",
    "voice_packet.gd",
    "voice_send_context.gd",
    "voice_playback_context.gd",
    "voice_speaker_handle.gd",
    "steam_voice_transport.gd",
    "muffling_map.gd",
    "proximity_volume_math.gd",
]

ADDON_DIRS = [
    "rules",
]

OPTIONAL_DIRS = [
    "adapters",
]


def _copy_uid(src: Path, dest: Path) -> None:
    uid = src.with_suffix(src.suffix + ".uid")
    if uid.is_file():
        shutil.copy2(uid, dest.with_suffix(dest.suffix + ".uid"))


def package_addon(
    out_dir: Path,
    include_adapters: bool = True,
    zip_path: Path | None = None,
) -> Path:
    if out_dir.exists():
        shutil.rmtree(out_dir)
    out_dir.mkdir(parents=True)

    # Keep packaged copies out of Godot's global class scan when dist/ lives inside this repo.
    gdignore = out_dir.parent / ".gdignore"
    if not gdignore.is_file():
        gdignore.touch()

    for name in ADDON_FILES:
        src = ROOT / name
        if not src.is_file():
            raise FileNotFoundError(f"Missing addon file: {src}")
        dest = out_dir / name
        shutil.copy2(src, dest)
        _copy_uid(src, dest)

    for dirname in ADDON_DIRS:
        src_dir = ROOT / dirname
        if not src_dir.is_dir():
            raise FileNotFoundError(f"Missing addon directory: {src_dir}")
        shutil.copytree(src_dir, out_dir / dirname)

    if include_adapters:
        for dirname in OPTIONAL_DIRS:
            src_dir = ROOT / dirname
            if src_dir.is_dir():
                shutil.copytree(src_dir, out_dir / dirname)

    install_md = out_dir / "INSTALL.txt"
    install_md.write_text(
        "Copy this folder into your Godot project:\n\n"
        "  your_game/addons/godot-steam-voice/\n\n"
        "Requires Godot 4.6+ and GodotSteam with voice API.\n",
        encoding="utf-8",
    )

    if zip_path is not None:
        zip_path.parent.mkdir(parents=True, exist_ok=True)
        with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as zf:
            for path in sorted(out_dir.rglob("*")):
                if path.is_file():
                    zf.write(path, path.relative_to(out_dir.parent))
        print(f"Wrote {zip_path}")

    print(f"Packaged addon to {out_dir}")
    return out_dir


def main() -> int:
    parser = argparse.ArgumentParser(description="Package Godot Steam Voice addon")
    parser.add_argument(
        "--out",
        type=Path,
        default=DEFAULT_OUT,
        help=f"Output directory (default: {DEFAULT_OUT})",
    )
    parser.add_argument(
        "--zip",
        type=Path,
        default=None,
        help="Also write a zip archive (e.g. dist/godot-steam-voice.zip)",
    )
    parser.add_argument(
        "--no-adapters",
        action="store_true",
        help="Omit adapters/ (Steam ID helpers)",
    )
    args = parser.parse_args()
    package_addon(args.out, include_adapters=not args.no_adapters, zip_path=args.zip)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
