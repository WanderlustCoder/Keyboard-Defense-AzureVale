#!/usr/bin/env python3
"""
Verify that every active runtime asset ID exists in the catalog manifest.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any


def _load_json(path: Path) -> Any:
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Verify active runtime manifest is a subset of catalog by asset id"
    )
    parser.add_argument("--catalog", required=True, help="Path to catalog manifest")
    parser.add_argument("--active", required=True, help="Path to active runtime manifest")
    args = parser.parse_args()

    catalog = _load_json(Path(args.catalog))
    active = _load_json(Path(args.active))

    if not isinstance(catalog, dict) or not isinstance(active, dict):
        print("ERROR: Manifest roots must be JSON objects", file=sys.stderr)
        return 1

    catalog_assets = catalog.get("assets", [])
    active_assets = active.get("assets", [])
    if not isinstance(catalog_assets, list) or not isinstance(active_assets, list):
        print("ERROR: assets must be arrays in both manifests", file=sys.stderr)
        return 1

    catalog_ids = {
        a.get("id")
        for a in catalog_assets
        if isinstance(a, dict) and isinstance(a.get("id"), str)
    }

    missing: list[str] = []
    for item in active_assets:
        if not isinstance(item, dict):
            continue
        aid = item.get("id")
        if isinstance(aid, str) and aid not in catalog_ids:
            missing.append(aid)

    if missing:
        missing = sorted(set(missing))
        print("Active manifest contains IDs that are missing from catalog:", file=sys.stderr)
        for aid in missing:
            print(f"- {aid}", file=sys.stderr)
        return 1

    print(
        f"Active subset gate OK: {len(active_assets)} active assets are present in catalog"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
