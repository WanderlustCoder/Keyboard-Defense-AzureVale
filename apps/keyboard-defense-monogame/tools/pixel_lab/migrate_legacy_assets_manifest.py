#!/usr/bin/env python3
"""
Migrate legacy data/assets_manifest.json texture entries into
pixel_lab_manifest.catalog.json.

This migration converts legacy Godot-style paths and category names into the
MonoGame Pixel Lab contract format.
"""

from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


DEFAULT_MAX_KB_BY_CATEGORY = {
    "icons": 8,
    "ui": 32,
    "effects": 32,
    "tiles": 48,
    "portraits": 64,
    "sprites": 96,
}

LEGACY_TO_CONTRACT_CATEGORY = {
    "icons": "icons",
    "portraits": "portraits",
    "tiles": "tiles",
    "effects": "effects",
    "projectiles": "effects",
    "ui": "ui",
    "keyboard": "ui",
    "cursors": "ui",
    "minimap": "ui",
    "reference": "ui",
    "enemies": "sprites",
    "units": "sprites",
    "sprites": "sprites",
    "buildings": "sprites",
    "characters": "sprites",
    "decorations": "sprites",
    "npcs": "sprites",
}


def _load_json(path: Path) -> Any:
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)


def _to_iso_utc(value: str | None) -> str:
    if not value:
        return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    candidate = value.strip()
    # Legacy file often uses YYYY-MM-DD.
    if len(candidate) == 10 and candidate[4] == "-" and candidate[7] == "-":
        return f"{candidate}T00:00:00Z"
    try:
        dt = datetime.fromisoformat(candidate.replace("Z", "+00:00"))
        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=timezone.utc)
        return dt.astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    except ValueError:
        return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def _map_category(legacy_category: str | None) -> str:
    if legacy_category:
        key = legacy_category.strip().lower()
        if key in LEGACY_TO_CONTRACT_CATEGORY:
            return LEGACY_TO_CONTRACT_CATEGORY[key]
    return "sprites"


def _legacy_path_to_relative_png(legacy_path: str | None, category: str, asset_id: str) -> str:
    if not legacy_path:
        return f"{category}/{asset_id}.png"
    path = legacy_path.strip().replace("\\", "/")
    if path.startswith("res://assets/"):
        path = path[len("res://assets/") :]
    elif path.startswith("res://"):
        path = path[len("res://") :]

    if path.endswith(".png") and "audio/" not in path:
        return path

    # Legacy SVG entry or non-standard location: normalize to canonical PNG target.
    return f"{category}/{asset_id}.png"


def _coerce_int(value: Any, default: int) -> int:
    if isinstance(value, int):
        return value
    if isinstance(value, float):
        return int(value)
    return default


def _derive_animation(legacy_texture: dict[str, Any], out_width: int, out_height: int) -> dict[str, Any] | None:
    anim_obj = legacy_texture.get("animation")
    frame_width = None
    frame_height = None
    frames = None
    duration_ms = None
    loop = True

    if isinstance(anim_obj, dict):
        frame_width = anim_obj.get("frame_width")
        frame_height = anim_obj.get("frame_height")
        frames = anim_obj.get("frames", anim_obj.get("frame_count"))
        duration_ms = anim_obj.get("duration_ms")
        fps = anim_obj.get("fps")
        if duration_ms is None and isinstance(fps, (int, float)) and fps > 0:
            duration_ms = int(round((1000.0 / float(fps)) * max(1, int(frames or 1))))
        if isinstance(anim_obj.get("loop"), bool):
            loop = anim_obj["loop"]

    if frames is None and legacy_texture.get("frames") is not None:
        frames = legacy_texture.get("frames")
    if frame_width is None and legacy_texture.get("frame_width") is not None:
        frame_width = legacy_texture.get("frame_width")
    if frame_height is None and legacy_texture.get("frame_height") is not None:
        frame_height = legacy_texture.get("frame_height")
    if duration_ms is None and legacy_texture.get("duration_ms") is not None:
        duration_ms = legacy_texture.get("duration_ms")

    source_svg_frames = legacy_texture.get("source_svg_frames")
    if frames is None and isinstance(source_svg_frames, list) and source_svg_frames:
        frames = len(source_svg_frames)

    if frames is None:
        return None

    frames_i = max(1, _coerce_int(frames, 1))
    fw_i = max(1, _coerce_int(frame_width, out_width))
    fh_i = max(1, _coerce_int(frame_height, out_height))
    dur_i = max(1, _coerce_int(duration_ms, 100 * frames_i))
    frame_ms = max(1, int(round(dur_i / max(1, frames_i))))

    return {
        "layout": {
            "frame_width": fw_i,
            "frame_height": fh_i,
            "rows": 1,
        },
        "clips": [
            {
                "name": "default",
                "row": 0,
                "start_frame": 0,
                "frames": frames_i,
                "frame_ms": frame_ms,
                "loop": loop,
            }
        ],
    }


def _migrate_texture(
    legacy_texture: dict[str, Any],
    exported_utc: str,
) -> dict[str, Any] | None:
    asset_id = legacy_texture.get("id")
    if not isinstance(asset_id, str) or not asset_id:
        return None

    legacy_category = legacy_texture.get("category")
    contract_category = _map_category(legacy_category if isinstance(legacy_category, str) else None)
    relative_path = _legacy_path_to_relative_png(
        legacy_texture.get("path") if isinstance(legacy_texture.get("path"), str) else None,
        contract_category,
        asset_id,
    )

    width = _coerce_int(legacy_texture.get("expected_width"), 1)
    height = _coerce_int(legacy_texture.get("expected_height"), 1)
    max_kb = _coerce_int(
        legacy_texture.get("max_kb"),
        DEFAULT_MAX_KB_BY_CATEGORY.get(contract_category, 64),
    )
    pixel_art = bool(legacy_texture.get("pixel_art", True))

    tags = ["legacy_import"]
    if isinstance(legacy_category, str) and legacy_category:
        tags.append(f"legacy_category_{legacy_category.lower()}")

    migrated: dict[str, Any] = {
        "id": asset_id,
        "category": contract_category,
        "source": {
            "provider": "manual",
            "artifact_type": "other",
            "artifact_id": f"legacy:{asset_id}",
            "exported_utc": exported_utc,
        },
        "output": {
            "relative_path": relative_path,
            "width": max(1, width),
            "height": max(1, height),
        },
        "constraints": {
            "max_kb": max(1, max_kb),
            "pixel_art": pixel_art,
            "alpha_required": True,
        },
        "tags": tags,
    }

    animation = _derive_animation(migrated_from := legacy_texture, max(1, width), max(1, height))
    if animation is not None:
        migrated["animation"] = animation

    return migrated


def migrate(legacy_manifest: dict[str, Any]) -> dict[str, Any]:
    exported_utc = _to_iso_utc(legacy_manifest.get("generated"))
    textures = legacy_manifest.get("textures", [])
    migrated_assets: list[dict[str, Any]] = []

    if isinstance(textures, list):
        for texture in textures:
            if not isinstance(texture, dict):
                continue
            migrated = _migrate_texture(texture, exported_utc)
            if migrated is not None:
                migrated_assets.append(migrated)

    # Stable output ordering by ID.
    migrated_assets.sort(key=lambda a: a["id"])

    return {
        "version": "1.0.0",
        "generated_utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "assets": migrated_assets,
    }


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Migrate legacy assets_manifest textures to Pixel Lab catalog format"
    )
    parser.add_argument(
        "--legacy-manifest",
        required=True,
        help="Path to legacy data/assets_manifest.json",
    )
    parser.add_argument(
        "--out",
        required=True,
        help="Path to output pixel_lab_manifest.catalog.json",
    )
    args = parser.parse_args()

    legacy_path = Path(args.legacy_manifest)
    out_path = Path(args.out)

    legacy_manifest = _load_json(legacy_path)
    if not isinstance(legacy_manifest, dict):
        raise ValueError("Legacy manifest root must be an object")

    migrated = migrate(legacy_manifest)

    out_path.parent.mkdir(parents=True, exist_ok=True)
    with out_path.open("w", encoding="utf-8") as f:
        json.dump(migrated, f, indent=2)
        f.write("\n")

    print(f"Migrated {len(migrated['assets'])} texture entries to {out_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
