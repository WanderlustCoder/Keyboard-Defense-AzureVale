#!/usr/bin/env python3
"""
Run the Pixel Lab manifest pipeline end-to-end and emit a summary report.

Pipeline:
1) migrate legacy manifest -> catalog
2) curate runtime subset + merge catalog
3) dedupe catalog
4) validate catalog schema/structure
5) validate active runtime schema/structure/files
6) gate active IDs are present in catalog
7) build runtime texture manifest from active subset

If a generated file only differs by top-level generated timestamp fields, this
script restores the original file to avoid timestamp-only git drift.
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from datetime import datetime, timezone
from hashlib import sha256
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


def _normalize_for_compare(value: Any) -> Any:
    if isinstance(value, dict):
        out: dict[str, Any] = {}
        for key, child in value.items():
            if key in {"generated_utc", "generated"}:
                continue
            out[key] = _normalize_for_compare(child)
        return out
    if isinstance(value, list):
        return [_normalize_for_compare(item) for item in value]
    return value


def _file_sha256(path: Path) -> str:
    return sha256(path.read_bytes()).hexdigest()


def _run_python(script_path: Path, args: list[str]) -> list[str]:
    command = [sys.executable, str(script_path), *args]
    subprocess.run(command, check=True)
    return command


def _capture_original(path: Path) -> tuple[str | None, Any | None]:
    if not path.exists():
        return None, None
    text = path.read_text(encoding="utf-8")
    try:
        payload = json.loads(text)
    except Exception:
        payload = None
    return text, payload


def _restore_when_timestamp_only(
    path: Path,
    original_text: str | None,
    original_payload: Any | None,
) -> bool:
    if original_text is None or original_payload is None:
        return False
    if not path.exists():
        return False
    try:
        generated_payload = _load_json(path)
    except Exception:
        return False
    if _normalize_for_compare(original_payload) == _normalize_for_compare(generated_payload):
        path.write_text(original_text, encoding="utf-8")
        return True
    return False


def _asset_count(payload: Any, key: str) -> int:
    if not isinstance(payload, dict):
        return 0
    values = payload.get(key, [])
    if isinstance(values, list):
        return len(values)
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Run Pixel Lab manifest pipeline")
    parser.add_argument(
        "--legacy-manifest",
        default="data/assets_manifest.json",
        help="Path to legacy data/assets_manifest.json",
    )
    parser.add_argument(
        "--runtime-texture-manifest",
        default="Content/Textures/texture_manifest.json",
        help="Path to runtime Content/Textures/texture_manifest.json",
    )
    parser.add_argument(
        "--textures-root",
        default="Content/Textures",
        help="Path to Content/Textures root for file checks",
    )
    parser.add_argument(
        "--catalog",
        default="data/pixel_lab_manifest.catalog.json",
        help="Path to catalog manifest",
    )
    parser.add_argument(
        "--active",
        default="data/pixel_lab_manifest.active_runtime.json",
        help="Path to active runtime manifest",
    )
    parser.add_argument(
        "--runtime-out",
        default="src/KeyboardDefense.Game/Content/Textures/texture_manifest.pixel_lab.json",
        help="Path to generated runtime texture manifest",
    )
    parser.add_argument(
        "--schema",
        default="data/schemas/pixel_lab_manifest.schema.json",
        help="Path to Pixel Lab schema",
    )
    parser.add_argument(
        "--report",
        default="artifacts/summaries/pixel-lab-pipeline.json",
        help="Path to summary report JSON",
    )
    args = parser.parse_args()

    tools_dir = Path(__file__).resolve().parent
    catalog_path = Path(args.catalog)
    active_path = Path(args.active)
    runtime_out_path = Path(args.runtime_out)
    report_path = Path(args.report)

    tracked_paths = [catalog_path, active_path, runtime_out_path]
    originals: dict[Path, tuple[str | None, Any | None]] = {
        path: _capture_original(path) for path in tracked_paths
    }

    steps: list[dict[str, Any]] = []
    try:
        command = _run_python(
            tools_dir / "migrate_legacy_assets_manifest.py",
            [
                "--legacy-manifest",
                args.legacy_manifest,
                "--out",
                args.catalog,
            ],
        )
        steps.append({"name": "migrate_legacy_assets_manifest", "command": command, "status": "ok"})

        command = _run_python(
            tools_dir / "curate_active_runtime.py",
            [
                "--catalog",
                args.catalog,
                "--runtime-texture-manifest",
                args.runtime_texture_manifest,
                "--textures-root",
                args.textures_root,
                "--out-catalog",
                args.catalog,
                "--out-active",
                args.active,
            ],
        )
        steps.append({"name": "curate_active_runtime", "command": command, "status": "ok"})

        command = _run_python(
            tools_dir / "dedupe_catalog.py",
            [
                "--catalog",
                args.catalog,
                "--out",
                args.catalog,
            ],
        )
        steps.append({"name": "dedupe_catalog", "command": command, "status": "ok"})

        command = _run_python(
            tools_dir / "validate_manifest.py",
            [
                "--manifest",
                args.catalog,
                "--schema",
                args.schema,
            ],
        )
        steps.append({"name": "validate_catalog_manifest", "command": command, "status": "ok"})

        command = _run_python(
            tools_dir / "validate_manifest.py",
            [
                "--manifest",
                args.active,
                "--schema",
                args.schema,
                "--textures-root",
                args.textures_root,
                "--check-files",
            ],
        )
        steps.append({"name": "validate_active_manifest", "command": command, "status": "ok"})

        command = _run_python(
            tools_dir / "verify_active_in_catalog.py",
            [
                "--catalog",
                args.catalog,
                "--active",
                args.active,
            ],
        )
        steps.append({"name": "verify_active_in_catalog", "command": command, "status": "ok"})

        command = _run_python(
            tools_dir / "build_texture_manifest.py",
            [
                "--manifest",
                args.active,
                "--out",
                args.runtime_out,
            ],
        )
        steps.append({"name": "build_runtime_texture_manifest", "command": command, "status": "ok"})
    except subprocess.CalledProcessError as exc:
        report = {
            "status": "failed",
            "generated_utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
            "failed_command": exc.cmd,
            "exit_code": exc.returncode,
            "steps": steps,
        }
        _write_json(report_path, report)
        return exc.returncode

    stabilized_files: list[str] = []
    for path in tracked_paths:
        original_text, original_payload = originals[path]
        if _restore_when_timestamp_only(path, original_text, original_payload):
            stabilized_files.append(path.as_posix())

    catalog_payload = _load_json(catalog_path)
    active_payload = _load_json(active_path)
    runtime_payload = _load_json(runtime_out_path)

    outputs: dict[str, Any] = {}
    for label, path in (
        ("catalog_manifest", catalog_path),
        ("active_runtime_manifest", active_path),
        ("runtime_texture_manifest", runtime_out_path),
    ):
        outputs[label] = {
            "path": path.as_posix(),
            "sha256": _file_sha256(path),
        }

    report = {
        "status": "ok",
        "generated_utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "steps": steps,
        "counts": {
            "catalog_assets": _asset_count(catalog_payload, "assets"),
            "active_assets": _asset_count(active_payload, "assets"),
            "runtime_textures": _asset_count(runtime_payload, "textures"),
        },
        "stabilized_timestamp_only_files": stabilized_files,
        "outputs": outputs,
    }
    _write_json(report_path, report)
    print(
        "Pixel Lab pipeline complete "
        f"(catalog={report['counts']['catalog_assets']}, "
        f"active={report['counts']['active_assets']}, "
        f"runtime_textures={report['counts']['runtime_textures']})"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
