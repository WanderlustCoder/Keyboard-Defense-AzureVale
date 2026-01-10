#!/usr/bin/env python3
"""
Unused Asset Finder

Finds assets that are not referenced anywhere in the codebase:
- SVG files not in assets_manifest.json
- PNG files not referenced in code or scenes
- Audio files not referenced in sfx_presets.json or code
- Orphan sprite IDs in manifest (files don't exist)

Usage:
    python scripts/find_unused_assets.py              # Full report
    python scripts/find_unused_assets.py --json       # JSON output
    python scripts/find_unused_assets.py --svg        # SVG only
    python scripts/find_unused_assets.py --audio      # Audio only
    python scripts/find_unused_assets.py --verbose    # Show where assets ARE used
"""

import json
import re
import sys
from collections import defaultdict
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, List, Set, Optional

# Project paths
SCRIPT_DIR = Path(__file__).parent
PROJECT_ROOT = SCRIPT_DIR.parent


@dataclass
class AssetReport:
    """Report of asset usage."""
    # SVG files
    svg_total: int = 0
    svg_in_manifest: int = 0
    svg_not_in_manifest: List[str] = field(default_factory=list)

    # PNG files
    png_total: int = 0
    png_referenced: int = 0
    png_unreferenced: List[str] = field(default_factory=list)

    # Audio files
    audio_total: int = 0
    audio_referenced: int = 0
    audio_unreferenced: List[str] = field(default_factory=list)

    # Manifest entries without source files
    orphan_manifest_entries: List[str] = field(default_factory=list)

    # Manifest entries with missing PNG targets
    missing_png_targets: List[str] = field(default_factory=list)


def load_assets_manifest() -> Dict:
    """Load the assets manifest."""
    manifest_path = PROJECT_ROOT / "data" / "assets_manifest.json"
    if not manifest_path.exists():
        return {}
    try:
        return json.loads(manifest_path.read_text(encoding="utf-8"))
    except Exception:
        return {}


def load_sfx_presets() -> Dict:
    """Load the SFX presets."""
    presets_path = PROJECT_ROOT / "data" / "audio" / "sfx_presets.json"
    if not presets_path.exists():
        return {}
    try:
        return json.loads(presets_path.read_text(encoding="utf-8"))
    except Exception:
        return {}


def get_all_svgs() -> Set[str]:
    """Get all SVG files in src-svg directory."""
    svg_dir = PROJECT_ROOT / "assets" / "art" / "src-svg"
    if not svg_dir.exists():
        return set()

    svgs = set()
    for svg_file in svg_dir.glob("**/*.svg"):
        rel_path = str(svg_file.relative_to(svg_dir))
        svgs.add(rel_path)
    return svgs


def get_all_pngs() -> Set[str]:
    """Get all PNG files in sprites directory."""
    sprite_dir = PROJECT_ROOT / "assets" / "sprites"
    if not sprite_dir.exists():
        return set()

    pngs = set()
    for png_file in sprite_dir.glob("**/*.png"):
        rel_path = str(png_file.relative_to(sprite_dir))
        pngs.add(rel_path)
    return pngs


def get_all_audio() -> Set[str]:
    """Get all audio files."""
    audio_dir = PROJECT_ROOT / "assets" / "audio"
    if not audio_dir.exists():
        return set()

    audio_files = set()
    for ext in ["*.wav", "*.ogg", "*.mp3"]:
        for audio_file in audio_dir.glob(f"**/{ext}"):
            rel_path = str(audio_file.relative_to(audio_dir))
            audio_files.add(rel_path)
    return audio_files


def get_svgs_in_manifest(manifest: Dict) -> Set[str]:
    """Get all SVG paths referenced in manifest."""
    svgs = set()
    textures = manifest.get("textures", [])

    # Handle both list and dict formats
    if isinstance(textures, list):
        items = textures
    elif isinstance(textures, dict):
        items = textures.values()
    else:
        return svgs

    for data in items:
        if isinstance(data, dict):
            # Single source SVG
            if "source_svg" in data:
                source = data["source_svg"]
                if isinstance(source, str):
                    # Extract relative path from res:// path
                    if source.startswith("res://assets/art/src-svg/"):
                        source = source.replace("res://assets/art/src-svg/", "")
                    svgs.add(source)
                elif isinstance(source, list):
                    for s in source:
                        if isinstance(s, str):
                            if s.startswith("res://assets/art/src-svg/"):
                                s = s.replace("res://assets/art/src-svg/", "")
                            svgs.add(s)

            # Animation frames
            if "source_svg_frames" in data:
                frames = data["source_svg_frames"]
                if isinstance(frames, str):
                    if frames.startswith("res://assets/art/src-svg/"):
                        frames = frames.replace("res://assets/art/src-svg/", "")
                    svgs.add(frames)
                elif isinstance(frames, list):
                    for f in frames:
                        if isinstance(f, str):
                            if f.startswith("res://assets/art/src-svg/"):
                                f = f.replace("res://assets/art/src-svg/", "")
                            svgs.add(f)

    return svgs


def get_audio_in_presets(presets: Dict) -> Set[str]:
    """Get all audio paths referenced in SFX presets."""
    audio = set()

    def extract_paths(obj, prefix=""):
        if isinstance(obj, dict):
            for key, value in obj.items():
                if key == "file" and isinstance(value, str):
                    audio.add(value)
                elif key == "files" and isinstance(value, list):
                    audio.update(value)
                else:
                    extract_paths(value, f"{prefix}{key}.")
        elif isinstance(obj, list):
            for item in obj:
                extract_paths(item, prefix)

    extract_paths(presets)
    return audio


def find_code_references(pattern: str) -> Set[str]:
    """Find all occurrences of a pattern in code files."""
    references = set()

    # Search GDScript files
    for gd_file in PROJECT_ROOT.glob("**/*.gd"):
        if ".godot" in str(gd_file):
            continue
        try:
            content = gd_file.read_text(encoding="utf-8")
            for match in re.finditer(pattern, content):
                references.add(match.group(1))
        except Exception:
            pass

    # Search scene files
    for tscn_file in PROJECT_ROOT.glob("**/*.tscn"):
        if ".godot" in str(tscn_file):
            continue
        try:
            content = tscn_file.read_text(encoding="utf-8")
            for match in re.finditer(pattern, content):
                references.add(match.group(1))
        except Exception:
            pass

    return references


def find_sprite_id_references() -> Set[str]:
    """Find all sprite ID references in code."""
    # Look for patterns like: get_texture("sprite_id") or "sprite_id" in context
    ids = set()

    for gd_file in PROJECT_ROOT.glob("**/*.gd"):
        if ".godot" in str(gd_file):
            continue
        try:
            content = gd_file.read_text(encoding="utf-8")
            # get_texture("id"), get_sprite("id"), etc.
            for match in re.finditer(r'get_(?:texture|sprite|icon|tile)\s*\(\s*["\'](\w+)["\']', content):
                ids.add(match.group(1))
            # AssetLoader patterns
            for match in re.finditer(r'AssetLoader\.\w+\s*\(\s*["\'](\w+)["\']', content):
                ids.add(match.group(1))
        except Exception:
            pass

    return ids


def analyze_assets() -> AssetReport:
    """Analyze all assets and find unused ones."""
    report = AssetReport()

    # Load data files
    manifest = load_assets_manifest()
    sfx_presets = load_sfx_presets()

    # Get all files
    all_svgs = get_all_svgs()
    all_pngs = get_all_pngs()
    all_audio = get_all_audio()

    report.svg_total = len(all_svgs)
    report.png_total = len(all_pngs)
    report.audio_total = len(all_audio)

    # SVG analysis
    svgs_in_manifest = get_svgs_in_manifest(manifest)
    report.svg_in_manifest = len(svgs_in_manifest & all_svgs)
    report.svg_not_in_manifest = sorted(all_svgs - svgs_in_manifest)

    # Check for orphan manifest entries (SVG doesn't exist)
    for svg_path in svgs_in_manifest:
        svg_full = PROJECT_ROOT / "assets" / "art" / "src-svg" / svg_path
        if not svg_full.exists():
            report.orphan_manifest_entries.append(svg_path)

    # Check for missing PNG targets
    textures = manifest.get("textures", [])
    texture_items = textures if isinstance(textures, list) else list(textures.values())
    texture_ids = set()

    for data in texture_items:
        if isinstance(data, dict):
            sprite_id = data.get("id", "")
            texture_ids.add(sprite_id)
            # Expected PNG path based on sprite_id
            category = data.get("category", "misc")
            expected_png = f"{category}/{sprite_id}.png"
            png_full = PROJECT_ROOT / "assets" / "sprites" / expected_png
            if not png_full.exists():
                # Check alternate locations
                found = False
                for png in all_pngs:
                    if png.endswith(f"{sprite_id}.png"):
                        found = True
                        break
                if not found:
                    report.missing_png_targets.append(sprite_id)

    # PNG analysis - find which are referenced in code/scenes
    png_refs = find_code_references(r'res://assets/sprites/([^"\']+\.png)')
    sprite_id_refs = find_sprite_id_references()

    # Build set of PNG files that correspond to referenced sprite IDs
    referenced_pngs = set()
    for png in all_pngs:
        # Check direct path reference
        if png in png_refs:
            referenced_pngs.add(png)
            continue

        # Check sprite ID reference
        png_name = Path(png).stem
        if png_name in sprite_id_refs:
            referenced_pngs.add(png)
            continue

        # Check if in manifest (manifest entries are considered "used")
        if png_name in texture_ids:
            referenced_pngs.add(png)
            continue

    report.png_referenced = len(referenced_pngs)
    report.png_unreferenced = sorted(all_pngs - referenced_pngs)

    # Audio analysis
    audio_in_presets = get_audio_in_presets(sfx_presets)
    audio_in_code = find_code_references(r'res://assets/audio/([^"\']+)')

    referenced_audio = audio_in_presets | audio_in_code

    # Normalize paths for comparison
    normalized_refs = set()
    for ref in referenced_audio:
        # Remove leading path components if present
        if "/" in ref:
            normalized_refs.add(ref.split("/")[-1])
        normalized_refs.add(ref)

    for audio in all_audio:
        audio_name = Path(audio).name
        if audio in normalized_refs or audio_name in normalized_refs:
            report.audio_referenced += 1
        else:
            report.audio_unreferenced.append(audio)

    return report


def format_text(report: AssetReport, verbose: bool = False) -> str:
    """Format report as text."""
    lines = []
    lines.append("=" * 60)
    lines.append("UNUSED ASSET FINDER - KEYBOARD DEFENSE")
    lines.append("=" * 60)
    lines.append("")

    # Summary
    lines.append("## SUMMARY")
    lines.append(f"  SVG files:    {report.svg_total} total, {report.svg_in_manifest} in manifest, {len(report.svg_not_in_manifest)} unused")
    lines.append(f"  PNG files:    {report.png_total} total, {report.png_referenced} referenced, {len(report.png_unreferenced)} unused")
    lines.append(f"  Audio files:  {report.audio_total} total, {report.audio_referenced} referenced, {len(report.audio_unreferenced)} unused")
    lines.append("")

    # Manifest issues
    if report.orphan_manifest_entries:
        lines.append("## ORPHAN MANIFEST ENTRIES (SVG doesn't exist)")
        for entry in report.orphan_manifest_entries[:20]:
            lines.append(f"  {entry}")
        if len(report.orphan_manifest_entries) > 20:
            lines.append(f"  ... and {len(report.orphan_manifest_entries) - 20} more")
        lines.append("")

    if report.missing_png_targets:
        lines.append("## MISSING PNG TARGETS (in manifest but PNG not generated)")
        for entry in report.missing_png_targets[:30]:
            lines.append(f"  {entry}")
        if len(report.missing_png_targets) > 30:
            lines.append(f"  ... and {len(report.missing_png_targets) - 30} more")
        lines.append("")

    # SVGs not in manifest
    if report.svg_not_in_manifest:
        lines.append("## SVGs NOT IN MANIFEST")
        for svg in report.svg_not_in_manifest[:30]:
            lines.append(f"  {svg}")
        if len(report.svg_not_in_manifest) > 30:
            lines.append(f"  ... and {len(report.svg_not_in_manifest) - 30} more")
        lines.append("")

    # Unreferenced PNGs
    if report.png_unreferenced:
        lines.append("## UNREFERENCED PNG FILES")
        for png in report.png_unreferenced[:20]:
            lines.append(f"  {png}")
        if len(report.png_unreferenced) > 20:
            lines.append(f"  ... and {len(report.png_unreferenced) - 20} more")
        lines.append("")

    # Unreferenced audio
    if report.audio_unreferenced:
        lines.append("## UNREFERENCED AUDIO FILES")
        for audio in report.audio_unreferenced[:20]:
            lines.append(f"  {audio}")
        if len(report.audio_unreferenced) > 20:
            lines.append(f"  ... and {len(report.audio_unreferenced) - 20} more")
        lines.append("")

    # Health summary
    lines.append("## HEALTH INDICATORS")

    svg_usage = report.svg_in_manifest * 100 // max(report.svg_total, 1)
    if svg_usage < 50:
        lines.append(f"  [WARN] Low SVG usage: {svg_usage}% in manifest")
    else:
        lines.append(f"  [OK] SVG usage: {svg_usage}% in manifest")

    if report.orphan_manifest_entries:
        lines.append(f"  [ERROR] {len(report.orphan_manifest_entries)} orphan manifest entries (SVGs don't exist)")
    else:
        lines.append("  [OK] All manifest entries have source SVGs")

    if report.missing_png_targets:
        lines.append(f"  [WARN] {len(report.missing_png_targets)} manifest entries without PNGs")
    else:
        lines.append("  [OK] All manifest entries have PNG targets")

    lines.append("")
    return "\n".join(lines)


def format_json(report: AssetReport) -> str:
    """Format report as JSON."""
    data = {
        "summary": {
            "svg_total": report.svg_total,
            "svg_in_manifest": report.svg_in_manifest,
            "svg_unused": len(report.svg_not_in_manifest),
            "png_total": report.png_total,
            "png_referenced": report.png_referenced,
            "png_unused": len(report.png_unreferenced),
            "audio_total": report.audio_total,
            "audio_referenced": report.audio_referenced,
            "audio_unused": len(report.audio_unreferenced),
        },
        "orphan_manifest_entries": report.orphan_manifest_entries,
        "missing_png_targets": report.missing_png_targets,
        "svg_not_in_manifest": report.svg_not_in_manifest,
        "png_unreferenced": report.png_unreferenced,
        "audio_unreferenced": report.audio_unreferenced,
    }
    return json.dumps(data, indent=2)


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Find unused assets")
    parser.add_argument("--json", "-j", action="store_true", help="JSON output")
    parser.add_argument("--svg", action="store_true", help="SVG only")
    parser.add_argument("--png", action="store_true", help="PNG only")
    parser.add_argument("--audio", action="store_true", help="Audio only")
    parser.add_argument("--verbose", "-v", action="store_true", help="Show usage details")
    args = parser.parse_args()

    report = analyze_assets()

    # Filter if requested
    if args.svg:
        report.png_unreferenced = []
        report.audio_unreferenced = []
    elif args.png:
        report.svg_not_in_manifest = []
        report.audio_unreferenced = []
    elif args.audio:
        report.svg_not_in_manifest = []
        report.png_unreferenced = []

    if args.json:
        print(format_json(report))
    else:
        print(format_text(report, args.verbose))


if __name__ == "__main__":
    main()
