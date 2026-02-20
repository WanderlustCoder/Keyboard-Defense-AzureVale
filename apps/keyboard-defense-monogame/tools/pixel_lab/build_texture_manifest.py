#!/usr/bin/env python3
"""
Generate MonoGame runtime texture manifest from Pixel Lab source manifest.
"""

from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


def _load_json(path: Path) -> Any:
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)


def _normalize_path(path: str) -> str:
    return path.replace("\\", "/")


def _to_runtime_texture_entry(asset: dict[str, Any]) -> dict[str, Any]:
    output = asset["output"]
    entry: dict[str, Any] = {
        "id": asset["id"],
        "path": _normalize_path(output["relative_path"]),
        "category": asset["category"],
        "width": output["width"],
        "height": output["height"],
    }

    animation = asset.get("animation")
    if isinstance(animation, dict):
        clips = animation.get("clips", [])
        runtime_clips: dict[str, Any] = {}
        if isinstance(clips, list):
            for clip in clips:
                if not isinstance(clip, dict):
                    continue
                name = clip.get("name")
                if not isinstance(name, str) or not name:
                    continue
                frames = int(clip.get("frames", 1))
                frame_ms = int(clip.get("frame_ms", 100))
                runtime_clips[name] = {
                    "frames": max(1, frames),
                    "duration": max(0.001, frame_ms / 1000.0),
                    "loop": bool(clip.get("loop", True)),
                }
        if runtime_clips:
            entry["animations"] = runtime_clips

    return entry


def build_runtime_manifest(source_manifest: dict[str, Any]) -> dict[str, Any]:
    source_assets = source_manifest.get("assets", [])
    textures: list[dict[str, Any]] = []
    if isinstance(source_assets, list):
        for asset in source_assets:
            if not isinstance(asset, dict):
                continue
            if "id" not in asset or "output" not in asset or "category" not in asset:
                continue
            textures.append(_to_runtime_texture_entry(asset))

    textures.sort(key=lambda t: t["id"])

    return {
        "version": source_manifest.get("version", "1.0.0"),
        "generated": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "textures": textures,
    }


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Build runtime texture manifest from Pixel Lab manifest"
    )
    parser.add_argument(
        "--manifest",
        required=True,
        help="Path to pixel_lab_manifest.active_runtime.json",
    )
    parser.add_argument(
        "--out",
        required=True,
        help="Output path for runtime texture_manifest.json",
    )
    args = parser.parse_args()

    manifest_path = Path(args.manifest)
    out_path = Path(args.out)

    source_manifest = _load_json(manifest_path)
    if not isinstance(source_manifest, dict):
        raise ValueError("Source manifest root must be a JSON object")

    runtime_manifest = build_runtime_manifest(source_manifest)

    out_path.parent.mkdir(parents=True, exist_ok=True)
    with out_path.open("w", encoding="utf-8") as f:
        json.dump(runtime_manifest, f, indent=2)
        f.write("\n")

    print(f"Wrote runtime manifest: {out_path} ({len(runtime_manifest['textures'])} textures)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
