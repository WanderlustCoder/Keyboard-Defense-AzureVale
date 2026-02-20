#!/usr/bin/env python3
"""
Deduplicate Pixel Lab catalog manifest by asset id and output.relative_path.
"""

from __future__ import annotations

import argparse
import copy
import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


def _load_json(path: Path) -> Any:
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)


def _score(asset: dict[str, Any]) -> int:
    score = 0
    tags = asset.get("tags")
    if isinstance(tags, list) and "runtime_curated" in tags:
        score += 50

    source = asset.get("source")
    if isinstance(source, dict):
        provider = source.get("provider")
        if provider == "pixellab":
            score += 20
        elif provider == "manual":
            score += 10

    if isinstance(asset.get("animation"), dict):
        score += 5

    constraints = asset.get("constraints")
    if isinstance(constraints, dict):
        if constraints.get("pixel_art") is True:
            score += 2
        if constraints.get("alpha_required") is True:
            score += 1

    return score


def _prefer(a: dict[str, Any], b: dict[str, Any]) -> dict[str, Any]:
    sa = _score(a)
    sb = _score(b)
    if sb > sa:
        return b
    return a


def dedupe(catalog: dict[str, Any]) -> tuple[dict[str, Any], int]:
    assets = catalog.get("assets", [])
    if not isinstance(assets, list):
        raise ValueError("Catalog assets must be an array")

    by_id: dict[str, dict[str, Any]] = {}
    for asset in assets:
        if not isinstance(asset, dict):
            continue
        aid = asset.get("id")
        if not isinstance(aid, str) or not aid:
            continue
        existing = by_id.get(aid)
        if existing is None:
            by_id[aid] = copy.deepcopy(asset)
        else:
            by_id[aid] = copy.deepcopy(_prefer(existing, asset))

    # Resolve path collisions after ID dedupe.
    by_path: dict[str, dict[str, Any]] = {}
    for aid in sorted(by_id.keys()):
        asset = by_id[aid]
        output = asset.get("output")
        path = None
        if isinstance(output, dict):
            rp = output.get("relative_path")
            if isinstance(rp, str):
                path = rp
        if not path:
            key = f"__missing_path__:{aid}"
            by_path[key] = asset
            continue
        existing = by_path.get(path)
        if existing is None:
            by_path[path] = asset
        else:
            by_path[path] = copy.deepcopy(_prefer(existing, asset))

    deduped_assets = sorted(by_path.values(), key=lambda a: str(a.get("id", "")))
    removed = len(assets) - len(deduped_assets)

    out = {
        "version": str(catalog.get("version", "1.0.0")),
        "generated_utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "assets": deduped_assets,
    }
    return out, removed


def main() -> int:
    parser = argparse.ArgumentParser(description="Deduplicate catalog manifest")
    parser.add_argument("--catalog", required=True, help="Path to catalog manifest")
    parser.add_argument("--out", required=True, help="Output path")
    args = parser.parse_args()

    catalog_path = Path(args.catalog)
    out_path = Path(args.out)
    catalog = _load_json(catalog_path)
    if not isinstance(catalog, dict):
        raise ValueError("Catalog root must be a JSON object")

    deduped, removed = dedupe(catalog)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    with out_path.open("w", encoding="utf-8") as f:
        json.dump(deduped, f, indent=2)
        f.write("\n")

    print(f"Deduped catalog written: {out_path} (removed {removed} duplicate entries)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
