#!/usr/bin/env python3
"""
Validate Pixel Lab manifest structure and optional texture files.

This validator is intentionally dependency-light:
- If `jsonschema` is installed, schema validation is used.
- Otherwise, a built-in structural validator is used.
"""

from __future__ import annotations

import argparse
import json
import math
import os
import re
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


ID_RE = re.compile(r"^[a-z0-9_]+$")
TAG_RE = re.compile(r"^[a-z0-9_\-]+$")
SEMVER_RE = re.compile(r"^[0-9]+\.[0-9]+\.[0-9]+$")
DRIVE_RE = re.compile(r"^[A-Za-z]:")

VALID_CATEGORIES = {"icons", "sprites", "portraits", "tiles", "effects", "ui"}
VALID_PROVIDERS = {"pixellab", "procedural", "manual"}
VALID_ARTIFACT_TYPES = {
    "character",
    "animation",
    "isometric_tile",
    "map_object",
    "topdown_tileset",
    "sidescroller_tileset",
    "other",
}

PNG_SIG = b"\x89PNG\r\n\x1a\n"


def _load_json(path: Path) -> Any:
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)


def _parse_iso_utc(value: str) -> bool:
    try:
        # Allow trailing Z and require timezone-aware timestamp.
        dt = datetime.fromisoformat(value.replace("Z", "+00:00"))
        return dt.tzinfo is not None
    except ValueError:
        return False


def _png_meta(path: Path) -> tuple[int, int, int]:
    with path.open("rb") as f:
        header = f.read(26)
    if len(header) < 26 or header[:8] != PNG_SIG:
        raise ValueError(f"{path} is not a valid PNG")
    width = int.from_bytes(header[16:20], "big")
    height = int.from_bytes(header[20:24], "big")
    color_type = header[25]
    return width, height, color_type


def _is_safe_relative_png(path: str) -> bool:
    if path.startswith("res://"):
        return False
    if path.startswith("/") or path.startswith("\\\\"):
        return False
    if DRIVE_RE.match(path):
        return False
    if "\\" in path:
        return False
    if not path.endswith(".png"):
        return False
    return True


def _validate_schema_if_available(manifest: dict[str, Any], schema_path: Path | None) -> list[str]:
    if not schema_path:
        return []
    if not schema_path.exists():
        return [f"Schema file not found: {schema_path}"]
    try:
        import jsonschema  # type: ignore
    except Exception:
        # Optional dependency: built-in validation will still run.
        return []
    try:
        schema = _load_json(schema_path)
        jsonschema.validate(instance=manifest, schema=schema)
        return []
    except Exception as exc:
        return [f"Schema validation failed: {exc}"]


def _validate_manifest_struct(manifest: dict[str, Any]) -> list[str]:
    errors: list[str] = []

    if not isinstance(manifest, dict):
        return ["Manifest must be a JSON object"]

    for key in ("version", "generated_utc", "assets"):
        if key not in manifest:
            errors.append(f"Missing top-level key: {key}")

    version = manifest.get("version")
    if not isinstance(version, str) or not SEMVER_RE.match(version):
        errors.append("version must be a semver string (x.y.z)")

    generated = manifest.get("generated_utc")
    if not isinstance(generated, str) or not _parse_iso_utc(generated):
        errors.append("generated_utc must be an ISO-8601 timestamp with timezone")

    assets = manifest.get("assets")
    if not isinstance(assets, list):
        errors.append("assets must be an array")
        return errors

    seen_ids: set[str] = set()
    seen_paths: set[str] = set()

    for i, asset in enumerate(assets):
        prefix = f"assets[{i}]"
        if not isinstance(asset, dict):
            errors.append(f"{prefix} must be an object")
            continue

        for key in ("id", "category", "source", "output", "constraints"):
            if key not in asset:
                errors.append(f"{prefix} missing key: {key}")

        aid = asset.get("id")
        if not isinstance(aid, str) or not ID_RE.match(aid):
            errors.append(f"{prefix}.id must match {ID_RE.pattern}")
        elif aid in seen_ids:
            errors.append(f"Duplicate asset id: {aid}")
        else:
            seen_ids.add(aid)

        category = asset.get("category")
        if category not in VALID_CATEGORIES:
            errors.append(f"{prefix}.category must be one of {sorted(VALID_CATEGORIES)}")

        source = asset.get("source")
        if not isinstance(source, dict):
            errors.append(f"{prefix}.source must be an object")
        else:
            provider = source.get("provider")
            if provider not in VALID_PROVIDERS:
                errors.append(f"{prefix}.source.provider invalid: {provider}")
            artifact_type = source.get("artifact_type")
            if artifact_type not in VALID_ARTIFACT_TYPES:
                errors.append(f"{prefix}.source.artifact_type invalid: {artifact_type}")
            artifact_id = source.get("artifact_id")
            if not isinstance(artifact_id, str) or not artifact_id:
                errors.append(f"{prefix}.source.artifact_id must be a non-empty string")
            exported_utc = source.get("exported_utc")
            if not isinstance(exported_utc, str) or not _parse_iso_utc(exported_utc):
                errors.append(f"{prefix}.source.exported_utc must be ISO-8601 with timezone")

        output = asset.get("output")
        if not isinstance(output, dict):
            errors.append(f"{prefix}.output must be an object")
        else:
            rel_path = output.get("relative_path")
            if not isinstance(rel_path, str) or not _is_safe_relative_png(rel_path):
                errors.append(f"{prefix}.output.relative_path must be a safe relative .png path")
            elif rel_path in seen_paths:
                errors.append(f"Duplicate output.relative_path: {rel_path}")
            else:
                seen_paths.add(rel_path)

            width = output.get("width")
            height = output.get("height")
            if not isinstance(width, int) or width < 1:
                errors.append(f"{prefix}.output.width must be an integer >= 1")
            if not isinstance(height, int) or height < 1:
                errors.append(f"{prefix}.output.height must be an integer >= 1")

        constraints = asset.get("constraints")
        if not isinstance(constraints, dict):
            errors.append(f"{prefix}.constraints must be an object")
        else:
            max_kb = constraints.get("max_kb")
            if not isinstance(max_kb, int) or max_kb < 1:
                errors.append(f"{prefix}.constraints.max_kb must be an integer >= 1")
            for bool_key in ("pixel_art", "alpha_required"):
                if not isinstance(constraints.get(bool_key), bool):
                    errors.append(f"{prefix}.constraints.{bool_key} must be a boolean")

        tags = asset.get("tags")
        if tags is not None:
            if not isinstance(tags, list):
                errors.append(f"{prefix}.tags must be an array when present")
            else:
                for t in tags:
                    if not isinstance(t, str) or not TAG_RE.match(t):
                        errors.append(f"{prefix}.tags values must match {TAG_RE.pattern}")

        animation = asset.get("animation")
        if animation is not None:
            if not isinstance(animation, dict):
                errors.append(f"{prefix}.animation must be an object")
            else:
                layout = animation.get("layout")
                clips = animation.get("clips")
                if not isinstance(layout, dict):
                    errors.append(f"{prefix}.animation.layout must be an object")
                else:
                    for lk in ("frame_width", "frame_height", "rows"):
                        if not isinstance(layout.get(lk), int) or layout.get(lk, 0) < 1:
                            errors.append(f"{prefix}.animation.layout.{lk} must be int >= 1")
                if not isinstance(clips, list) or not clips:
                    errors.append(f"{prefix}.animation.clips must be a non-empty array")
                else:
                    for ci, clip in enumerate(clips):
                        cprefix = f"{prefix}.animation.clips[{ci}]"
                        if not isinstance(clip, dict):
                            errors.append(f"{cprefix} must be an object")
                            continue
                        name = clip.get("name")
                        if not isinstance(name, str) or not ID_RE.match(name):
                            errors.append(f"{cprefix}.name must match {ID_RE.pattern}")
                        for ik in ("row", "start_frame", "frames", "frame_ms"):
                            val = clip.get(ik)
                            min_v = 0 if ik in {"row", "start_frame"} else 1
                            if not isinstance(val, int) or val < min_v:
                                errors.append(f"{cprefix}.{ik} must be int >= {min_v}")
                        if not isinstance(clip.get("loop"), bool):
                            errors.append(f"{cprefix}.loop must be a boolean")

    return errors


def _validate_files(manifest: dict[str, Any], textures_root: Path) -> list[str]:
    errors: list[str] = []
    root_resolved = textures_root.resolve()

    assets = manifest.get("assets", [])
    for i, asset in enumerate(assets):
        prefix = f"assets[{i}]"
        output = asset.get("output", {})
        constraints = asset.get("constraints", {})
        rel_path = output.get("relative_path")
        if not isinstance(rel_path, str):
            continue

        file_path = (textures_root / rel_path).resolve()
        if os.path.commonpath([str(root_resolved), str(file_path)]) != str(root_resolved):
            errors.append(f"{prefix}: output path escapes textures root: {rel_path}")
            continue

        if not file_path.exists():
            errors.append(f"{prefix}: missing texture file: {file_path}")
            continue

        try:
            width, height, color_type = _png_meta(file_path)
        except Exception as exc:
            errors.append(f"{prefix}: invalid PNG ({file_path}): {exc}")
            continue

        exp_w = output.get("width")
        exp_h = output.get("height")
        if isinstance(exp_w, int) and width != exp_w:
            errors.append(f"{prefix}: width mismatch {width} != {exp_w} ({file_path})")
        if isinstance(exp_h, int) and height != exp_h:
            errors.append(f"{prefix}: height mismatch {height} != {exp_h} ({file_path})")

        max_kb = constraints.get("max_kb")
        if isinstance(max_kb, int):
            size_kb = math.ceil(file_path.stat().st_size / 1024.0)
            if size_kb > max_kb:
                errors.append(f"{prefix}: size {size_kb}KB exceeds max_kb={max_kb} ({file_path})")

        alpha_required = constraints.get("alpha_required")
        if alpha_required is True and color_type not in (4, 6):
            errors.append(
                f"{prefix}: alpha_required=true but PNG color_type={color_type} ({file_path})"
            )

    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate Pixel Lab manifest")
    parser.add_argument(
        "--manifest",
        required=True,
        help="Path to pixel_lab_manifest.catalog.json or pixel_lab_manifest.active_runtime.json",
    )
    parser.add_argument(
        "--schema",
        default=None,
        help="Optional schema path (uses jsonschema if available)",
    )
    parser.add_argument(
        "--textures-root",
        default="Content/Textures",
        help="Texture root used with --check-files",
    )
    parser.add_argument(
        "--check-files",
        action="store_true",
        help="Validate output files (existence, PNG dimensions, budgets)",
    )
    args = parser.parse_args()

    manifest_path = Path(args.manifest)
    if not manifest_path.exists():
        print(f"ERROR: Manifest not found: {manifest_path}", file=sys.stderr)
        return 1

    manifest = _load_json(manifest_path)
    if not isinstance(manifest, dict):
        print("ERROR: Manifest root must be a JSON object", file=sys.stderr)
        return 1

    errors: list[str] = []
    schema_path = Path(args.schema) if args.schema else None
    errors.extend(_validate_schema_if_available(manifest, schema_path))
    errors.extend(_validate_manifest_struct(manifest))

    if args.check_files:
        manifest_dir = manifest_path.parent
        textures_root = (manifest_dir.parent / args.textures_root).resolve()
        if not textures_root.exists():
            errors.append(f"Textures root not found: {textures_root}")
        else:
            errors.extend(_validate_files(manifest, textures_root))

    if errors:
        print("Pixel Lab manifest validation failed:", file=sys.stderr)
        for err in errors:
            print(f"- {err}", file=sys.stderr)
        return 1

    timestamp = datetime.now(timezone.utc).isoformat()
    print(f"Pixel Lab manifest OK ({manifest_path}) at {timestamp}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
