#!/usr/bin/env python3
"""
Curate active runtime and catalog manifests from runtime texture usage.

Behavior:
- Reads runtime texture manifest (Content/Textures/texture_manifest.json).
- Keeps entries whose files exist in Content/Textures.
- Builds active_runtime from these entries.
- Updates catalog:
  - Existing IDs are refreshed with runtime path/size.
  - Missing IDs are added as runtime-curated entries.
"""

from __future__ import annotations

import argparse
import copy
import json
import os
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

RUNTIME_TO_CONTRACT_CATEGORY = {
    "icons": "icons",
    "ui": "ui",
    "effects": "effects",
    "tiles": "tiles",
    "portraits": "portraits",
    "sprites": "sprites",
    "enemies": "sprites",
    "units": "sprites",
    "buildings": "sprites",
}


def _load_json(path: Path) -> Any:
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)


def _write_json(path: Path, payload: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as f:
        json.dump(payload, f, indent=2)
        f.write("\n")


def _is_under(root: Path, candidate: Path) -> bool:
    return os.path.commonpath([str(root), str(candidate)]) == str(root)


def _map_category(runtime_category: str | None, rel_path: str) -> str:
    if runtime_category:
        key = runtime_category.strip().lower()
        if key in RUNTIME_TO_CONTRACT_CATEGORY:
            return RUNTIME_TO_CONTRACT_CATEGORY[key]
    if rel_path.startswith("icons/"):
        return "icons"
    if rel_path.startswith("tiles/"):
        return "tiles"
    if rel_path.startswith("portraits/"):
        return "portraits"
    if rel_path.startswith("ui/"):
        return "ui"
    if rel_path.startswith("effects/"):
        return "effects"
    return "sprites"


def _runtime_anims_to_contract(texture: dict[str, Any], width: int, height: int) -> dict[str, Any] | None:
    anims = texture.get("animations")
    if not isinstance(anims, dict) or not anims:
        return None

    max_frames = 1
    for clip in anims.values():
        if isinstance(clip, dict):
            try:
                max_frames = max(max_frames, int(clip.get("frames", 1)))
            except Exception:
                pass

    frame_width = width
    if max_frames > 1 and width % max_frames == 0:
        frame_width = width // max_frames

    clips: list[dict[str, Any]] = []
    for name in sorted(anims.keys()):
        clip = anims[name]
        if not isinstance(clip, dict):
            continue
        frames = max(1, int(clip.get("frames", 1)))
        duration = float(clip.get("duration", 0.1))
        frame_ms = max(1, int(round(duration * 1000.0)))
        clips.append(
            {
                "name": name,
                "row": 0,
                "start_frame": 0,
                "frames": frames,
                "frame_ms": frame_ms,
                "loop": bool(clip.get("loop", True)),
            }
        )

    if not clips:
        return None

    return {
        "layout": {
            "frame_width": max(1, int(frame_width)),
            "frame_height": max(1, int(height)),
            "rows": 1,
        },
        "clips": clips,
    }


def _build_or_update_asset(
    runtime_texture: dict[str, Any],
    existing: dict[str, Any] | None,
    exported_utc: str,
) -> dict[str, Any]:
    aid = str(runtime_texture["id"])
    rel_path = str(runtime_texture["path"]).replace("\\", "/")
    width = int(runtime_texture.get("width", 1))
    height = int(runtime_texture.get("height", 1))
    category = _map_category(runtime_texture.get("category"), rel_path)

    if existing:
        asset = copy.deepcopy(existing)
    else:
        asset = {
            "id": aid,
            "category": category,
            "source": {
                "provider": "manual",
                "artifact_type": "other",
                "artifact_id": f"runtime:{aid}",
                "exported_utc": exported_utc,
            },
            "constraints": {
                "max_kb": DEFAULT_MAX_KB_BY_CATEGORY.get(category, 64),
                "pixel_art": True,
                "alpha_required": True,
            },
            "tags": ["runtime_curated"],
        }

    asset["category"] = category
    asset["output"] = {
        "relative_path": rel_path,
        "width": max(1, width),
        "height": max(1, height),
    }

    if "constraints" not in asset or not isinstance(asset["constraints"], dict):
        asset["constraints"] = {
            "max_kb": DEFAULT_MAX_KB_BY_CATEGORY.get(category, 64),
            "pixel_art": True,
            "alpha_required": True,
        }
    else:
        asset["constraints"].setdefault("max_kb", DEFAULT_MAX_KB_BY_CATEGORY.get(category, 64))
        asset["constraints"].setdefault("pixel_art", True)
        asset["constraints"].setdefault("alpha_required", True)

    if "source" not in asset or not isinstance(asset["source"], dict):
        asset["source"] = {
            "provider": "manual",
            "artifact_type": "other",
            "artifact_id": f"runtime:{aid}",
            "exported_utc": exported_utc,
        }
    else:
        asset["source"].setdefault("provider", "manual")
        asset["source"].setdefault("artifact_type", "other")
        asset["source"].setdefault("artifact_id", f"runtime:{aid}")
        asset["source"].setdefault("exported_utc", exported_utc)

    anim = _runtime_anims_to_contract(runtime_texture, max(1, width), max(1, height))
    if anim:
        asset["animation"] = anim
    elif "animation" in asset:
        # Keep pre-existing animation if catalog already had one.
        pass

    tags = asset.get("tags")
    if not isinstance(tags, list):
        tags = []
    if "runtime_curated" not in tags:
        tags.append("runtime_curated")
    asset["tags"] = tags

    return asset


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Curate active runtime + catalog manifests from runtime texture usage"
    )
    parser.add_argument("--catalog", required=True, help="Path to catalog manifest")
    parser.add_argument("--runtime-texture-manifest", required=True, help="Path to runtime texture_manifest.json")
    parser.add_argument("--textures-root", required=True, help="Path to Content/Textures")
    parser.add_argument("--out-catalog", required=True, help="Output path for updated catalog manifest")
    parser.add_argument("--out-active", required=True, help="Output path for active runtime manifest")
    args = parser.parse_args()

    catalog_path = Path(args.catalog)
    runtime_manifest_path = Path(args.runtime_texture_manifest)
    textures_root = Path(args.textures_root).resolve()

    catalog = _load_json(catalog_path)
    runtime_manifest = _load_json(runtime_manifest_path)
    if not isinstance(catalog, dict):
        raise ValueError("Catalog manifest root must be an object")
    if not isinstance(runtime_manifest, dict):
        raise ValueError("Runtime texture manifest root must be an object")

    catalog_assets = catalog.get("assets", [])
    if not isinstance(catalog_assets, list):
        raise ValueError("Catalog manifest assets must be an array")

    runtime_textures = runtime_manifest.get("textures", [])
    if not isinstance(runtime_textures, list):
        raise ValueError("Runtime texture manifest textures must be an array")

    catalog_by_id: dict[str, dict[str, Any]] = {}
    for asset in catalog_assets:
        if isinstance(asset, dict) and isinstance(asset.get("id"), str):
            catalog_by_id[str(asset["id"])] = asset

    exported_utc = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    curated_active: list[dict[str, Any]] = []
    touched_ids: set[str] = set()

    for texture in runtime_textures:
        if not isinstance(texture, dict):
            continue
        aid = texture.get("id")
        rel_path = texture.get("path")
        if not isinstance(aid, str) or not aid:
            continue
        if not isinstance(rel_path, str) or not rel_path:
            continue

        file_path = (textures_root / rel_path).resolve()
        if not _is_under(textures_root, file_path):
            continue
        if not file_path.exists():
            continue

        existing = catalog_by_id.get(aid)
        curated = _build_or_update_asset(texture, existing, exported_utc)
        curated_active.append(curated)
        touched_ids.add(aid)

    # Merge curated entries back into catalog.
    merged_catalog: list[dict[str, Any]] = []
    existing_ids_in_order: list[str] = []
    for asset in catalog_assets:
        if isinstance(asset, dict) and isinstance(asset.get("id"), str):
            aid = str(asset["id"])
            existing_ids_in_order.append(aid)
            if aid in touched_ids:
                merged_catalog.append(next(a for a in curated_active if a["id"] == aid))
            else:
                merged_catalog.append(asset)

    # Append curated IDs that were not in the original catalog.
    known = set(existing_ids_in_order)
    appended = [a for a in curated_active if a["id"] not in known]
    merged_catalog.extend(sorted(appended, key=lambda a: a["id"]))

    merged_catalog.sort(key=lambda a: str(a.get("id", "")))
    curated_active.sort(key=lambda a: str(a.get("id", "")))

    version = str(catalog.get("version", "1.0.0"))
    out_catalog_payload = {
        "version": version,
        "generated_utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "assets": merged_catalog,
    }
    out_active_payload = {
        "version": version,
        "generated_utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "assets": curated_active,
    }

    _write_json(Path(args.out_catalog), out_catalog_payload)
    _write_json(Path(args.out_active), out_active_payload)

    print(
        f"Curated runtime manifests: active={len(curated_active)} "
        f"catalog={len(merged_catalog)}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
