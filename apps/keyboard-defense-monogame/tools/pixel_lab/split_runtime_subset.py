#!/usr/bin/env python3
"""
Split a Pixel Lab catalog manifest into an active runtime subset.

Active runtime entries are catalog assets whose output.relative_path file exists
under the provided textures root.
"""

from __future__ import annotations

import argparse
import json
import os
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


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


def split_runtime_assets(
    catalog_manifest: dict[str, Any],
    textures_root: Path,
) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    assets = catalog_manifest.get("assets", [])
    if not isinstance(assets, list):
        return [], []

    active: list[dict[str, Any]] = []
    missing: list[dict[str, Any]] = []

    root = textures_root.resolve()

    for asset in assets:
        if not isinstance(asset, dict):
            continue
        output = asset.get("output")
        if not isinstance(output, dict):
            missing.append(asset)
            continue
        rel_path = output.get("relative_path")
        if not isinstance(rel_path, str):
            missing.append(asset)
            continue

        path = (textures_root / rel_path).resolve()
        if not _is_under(root, path):
            missing.append(asset)
            continue

        if path.exists():
            active.append(asset)
        else:
            missing.append(asset)

    active.sort(key=lambda a: str(a.get("id", "")))
    missing.sort(key=lambda a: str(a.get("id", "")))
    return active, missing


def _build_manifest(
    version: str,
    assets: list[dict[str, Any]],
) -> dict[str, Any]:
    return {
        "version": version,
        "generated_utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "assets": assets,
    }


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Split Pixel Lab catalog into active runtime subset"
    )
    parser.add_argument(
        "--catalog",
        required=True,
        help="Path to pixel_lab_manifest.catalog.json",
    )
    parser.add_argument(
        "--textures-root",
        required=True,
        help="Path to Content/Textures root",
    )
    parser.add_argument(
        "--out-active",
        required=True,
        help="Path to pixel_lab_manifest.active_runtime.json",
    )
    parser.add_argument(
        "--out-missing",
        default=None,
        help="Optional path for non-runtime catalog subset",
    )
    args = parser.parse_args()

    catalog_path = Path(args.catalog)
    if not catalog_path.exists():
        raise FileNotFoundError(f"Catalog manifest not found: {catalog_path}")

    textures_root = Path(args.textures_root)
    if not textures_root.exists():
        raise FileNotFoundError(f"Textures root not found: {textures_root}")

    catalog = _load_json(catalog_path)
    if not isinstance(catalog, dict):
        raise ValueError("Catalog manifest root must be a JSON object")

    version = str(catalog.get("version", "1.0.0"))
    active, missing = split_runtime_assets(catalog, textures_root)

    active_manifest = _build_manifest(version, active)
    _write_json(Path(args.out_active), active_manifest)

    if args.out_missing:
        missing_manifest = _build_manifest(version, missing)
        _write_json(Path(args.out_missing), missing_manifest)

    print(
        f"Catalog split complete: active={len(active)} missing={len(missing)} "
        f"from total={len(active) + len(missing)}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
