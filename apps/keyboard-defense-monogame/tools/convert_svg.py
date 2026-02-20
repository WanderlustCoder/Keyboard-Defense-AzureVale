#!/usr/bin/env python3
"""
Batch convert SVGs from Godot art source to PNGs for MonoGame.

Usage:
    python tools/convert_svg.py --input <DIR> --output <DIR> --manifest <FILE>
    python tools/convert_svg.py --help

Default paths (run from apps/keyboard-defense-monogame/):
    python tools/convert_svg.py

Requires one of:
    pip install cairosvg   (preferred, high quality)
    pip install Pillow     (fallback, basic rasterization)
    inkscape on PATH       (external process)
"""

import argparse
import json
import subprocess
import sys
import time
from pathlib import Path

# ---------------------------------------------------------------------------
# Category configuration
# ---------------------------------------------------------------------------

# Default pixel sizes per top-level SVG category.
# Maps the first path component under the input root to a square output size.
CATEGORY_SIZES: dict[str, int] = {
    "enemies":    32,
    "buildings":  48,
    "tiles":      32,
    "effects":    32,
    "icons":      16,
    # Everything else falls through to the --size default (32).
}

# The categories that get their own top-level key in the grouped manifest.
# Others are collected under a generic "sprites" key.
MANIFEST_CATEGORIES = {"enemies", "buildings", "tiles", "effects", "icons"}

# ---------------------------------------------------------------------------
# Conversion backends
# ---------------------------------------------------------------------------

_cairosvg_available: bool | None = None
_pillow_available: bool | None = None


def _check_cairosvg() -> bool:
    global _cairosvg_available
    if _cairosvg_available is None:
        try:
            import cairosvg  # noqa: F401
            _cairosvg_available = True
        except (ImportError, OSError):
            _cairosvg_available = False
    return _cairosvg_available


def _check_pillow() -> bool:
    global _pillow_available
    if _pillow_available is None:
        try:
            from PIL import Image  # noqa: F401
            _pillow_available = True
        except ImportError:
            _pillow_available = False
    return _pillow_available


def convert_with_cairosvg(svg_path: Path, png_path: Path, width: int, height: int) -> bool:
    """High-quality SVG->PNG via cairosvg."""
    if not _check_cairosvg():
        return False
    try:
        import cairosvg  # noqa: F811
        cairosvg.svg2png(
            url=str(svg_path),
            write_to=str(png_path),
            output_width=width,
            output_height=height,
        )
        return True
    except (ImportError, OSError):
        return False
    except Exception as exc:
        print(f"  cairosvg error for {svg_path.name}: {exc}")
        return False


def convert_with_pillow(svg_path: Path, png_path: Path, width: int, height: int) -> bool:
    """Fallback SVG->PNG via Pillow (limited SVG support)."""
    if not _check_pillow():
        return False
    try:
        from PIL import Image

        # Pillow doesn't natively render SVG.  We try two paths:
        # 1) If pillow-svg (or cairosvg-backed PIL plugin) is present, use it.
        # 2) Otherwise, read the SVG as a generic image (works only if a
        #    Pillow plugin for SVG is installed, e.g. pillow-avif-plugin).
        img = Image.open(str(svg_path))
        img = img.resize((width, height), Image.LANCZOS)
        img.save(str(png_path), "PNG")
        return True
    except Exception as exc:
        print(f"  Pillow error for {svg_path.name}: {exc}")
        return False


def convert_with_inkscape(svg_path: Path, png_path: Path, width: int, height: int) -> bool:
    """External Inkscape CLI conversion."""
    try:
        result = subprocess.run(
            [
                "inkscape",
                str(svg_path),
                f"--export-filename={png_path}",
                "-w", str(width),
                "-h", str(height),
            ],
            capture_output=True,
            timeout=30,
        )
        return result.returncode == 0
    except (FileNotFoundError, subprocess.TimeoutExpired):
        return False


def convert_svg(svg_path: Path, png_path: Path, width: int, height: int) -> bool:
    """Try converters in preference order: cairosvg -> Pillow -> Inkscape."""
    png_path.parent.mkdir(parents=True, exist_ok=True)

    if convert_with_cairosvg(svg_path, png_path, width, height):
        return True
    if convert_with_pillow(svg_path, png_path, width, height):
        return True
    if convert_with_inkscape(svg_path, png_path, width, height):
        return True
    return False


# ---------------------------------------------------------------------------
# Manifest generation
# ---------------------------------------------------------------------------

def build_texture_manifest(entries: list[dict]) -> dict:
    """Build a texture_manifest.json compatible with AssetLoader.LoadManifest().

    The format expected by AssetLoader is:
        {
            "textures": [
                {"id": "<stem>", "path": "<relative/path.png>", ...},
                ...
            ]
        }
    """
    return {
        "version": "1.0.0",
        "generated": time.strftime("%Y-%m-%d"),
        "textures": entries,
    }


def build_assets_manifest(entries: list[dict]) -> dict:
    """Build a category-grouped assets_manifest.json.

    Output:
        {
            "enemies":   {"scout": "enemies/enemy_scout.png", ...},
            "buildings": {"tower": "buildings/building_tower.png", ...},
            "tiles":     {"grass": "tiles/tile_grass.png", ...},
            "effects":   {"explosion": "effects/effect_explosion.png", ...},
            "icons":     {"gold": "icons/ico_gold.png", ...},
            "sprites":   {"<id>": "<path>", ...}
        }
    """
    grouped: dict[str, dict[str, str]] = {}
    for entry in entries:
        cat = entry["category"]
        key = cat if cat in MANIFEST_CATEGORIES else "sprites"
        grouped.setdefault(key, {})

        # Derive a short display name from the id by stripping common prefixes.
        asset_id: str = entry["id"]
        short = _strip_category_prefix(asset_id, cat)
        grouped[key][short] = entry["path"]

    return grouped


def _strip_category_prefix(asset_id: str, category: str) -> str:
    """Remove conventional prefixes like 'enemy_', 'tile_', 'ico_', etc."""
    prefixes = {
        "enemies":   ["enemy_", "boss_", "affix_"],
        "buildings": ["building_", "tower_", "castle_"],
        "tiles":     ["tile_"],
        "effects":   ["effect_", "fx_", "projectile_", "proj_", "affix_",
                       "tower_", "status_"],
        "icons":     ["ico_", "poi_", "status_", "medal_", "mini_",
                       "marker_", "map_node_", "rank_", "star_"],
    }
    for prefix in prefixes.get(category, []):
        if asset_id.startswith(prefix):
            return asset_id[len(prefix):]
    return asset_id


# ---------------------------------------------------------------------------
# Category / size helpers
# ---------------------------------------------------------------------------

def resolve_category(rel_path: Path) -> str:
    """Determine the output category from the relative path inside src-svg/."""
    if len(rel_path.parts) > 1:
        return rel_path.parts[0]
    return "sprites"


def resolve_size(category: str, override: int | None, default: int) -> tuple[int, int]:
    """Return (width, height) for a given category."""
    if override is not None:
        return (override, override)
    s = CATEGORY_SIZES.get(category, default)
    return (s, s)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def detect_backends() -> list[str]:
    """Return list of available converter names."""
    available = []
    if _check_cairosvg():
        available.append("cairosvg")
    if _check_pillow():
        available.append("Pillow")
    try:
        r = subprocess.run(["inkscape", "--version"], capture_output=True, timeout=5)
        if r.returncode == 0:
            available.append("Inkscape")
    except (FileNotFoundError, subprocess.TimeoutExpired):
        pass
    return available


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Batch-convert Godot SVG assets to PNG textures for MonoGame.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Use defaults (run from apps/keyboard-defense-monogame/)
  python tools/convert_svg.py

  # Explicit paths
  python tools/convert_svg.py \\
      --input  ../keyboard-defense-godot/assets/art/src-svg \\
      --output src/KeyboardDefense.Game/Content/Textures \\
      --manifest src/KeyboardDefense.Game/Content/assets_manifest.json

  # Override all sizes to 64x64
  python tools/convert_svg.py --size 64
""",
    )
    parser.add_argument(
        "--input", default=None,
        help="Root directory containing SVG subdirectories "
             "(default: ../keyboard-defense-godot/assets/art/src-svg)",
    )
    parser.add_argument(
        "--output", default=None,
        help="Output directory for PNG textures "
             "(default: src/KeyboardDefense.Game/Content/Textures)",
    )
    parser.add_argument(
        "--manifest", default=None,
        help="Path for the generated assets_manifest.json "
             "(default: <output>/assets_manifest.json)",
    )
    parser.add_argument(
        "--size", type=int, default=None,
        help="Override output size for ALL categories (e.g. --size 64). "
             "Without this flag, each category uses its own default size.",
    )
    parser.add_argument(
        "--dry-run", action="store_true",
        help="List files that would be converted without writing anything.",
    )
    args = parser.parse_args()

    # ------------------------------------------------------------------
    # Resolve paths (default to project-relative locations)
    # ------------------------------------------------------------------
    script_dir = Path(__file__).resolve().parent          # tools/
    monogame_root = script_dir.parent                     # apps/keyboard-defense-monogame/
    project_root = monogame_root.parent.parent            # repo root

    godot_svg_root = (
        project_root / "apps" / "keyboard-defense-godot"
        / "assets" / "art" / "src-svg"
    )

    input_dir = Path(args.input).resolve() if args.input else godot_svg_root
    output_dir = (
        Path(args.output).resolve()
        if args.output
        else monogame_root / "src" / "KeyboardDefense.Game" / "Content" / "Textures"
    )
    manifest_path = (
        Path(args.manifest).resolve()
        if args.manifest
        else output_dir / "assets_manifest.json"
    )

    # ------------------------------------------------------------------
    # Validate input
    # ------------------------------------------------------------------
    if not input_dir.exists():
        print(f"ERROR: Input directory not found: {input_dir}")
        return 1

    # ------------------------------------------------------------------
    # Check converter availability
    # ------------------------------------------------------------------
    backends = detect_backends()
    if not backends and not args.dry_run:
        print("ERROR: No SVG conversion backend available.")
        print()
        print("Install one of the following:")
        print("  pip install cairosvg        # recommended (high quality)")
        print("  pip install Pillow          # basic fallback")
        print("  Install Inkscape and add it to PATH")
        print()
        print("On Windows, cairosvg requires the GTK3 runtime or similar.")
        print("See: https://cairosvg.org/documentation/")
        return 1

    print(f"SVG -> PNG converter for Keyboard Defense (MonoGame port)")
    print(f"  Input:    {input_dir}")
    print(f"  Output:   {output_dir}")
    print(f"  Manifest: {manifest_path}")
    print(f"  Backends: {', '.join(backends) if backends else '(dry-run)'}")
    if args.size is not None:
        print(f"  Size override: {args.size}x{args.size}")
    print()

    # ------------------------------------------------------------------
    # Discover SVGs
    # ------------------------------------------------------------------
    svg_files = sorted(input_dir.rglob("*.svg"))
    if not svg_files:
        print("No SVG files found in input directory.")
        return 0

    print(f"Found {len(svg_files)} SVG files.\n")

    # ------------------------------------------------------------------
    # Convert
    # ------------------------------------------------------------------
    output_dir.mkdir(parents=True, exist_ok=True)

    default_size = 32
    converted: list[dict] = []
    failed: list[str] = []

    for svg_file in svg_files:
        rel = svg_file.relative_to(input_dir)
        category = resolve_category(rel)
        w, h = resolve_size(category, args.size, default_size)

        png_name = svg_file.stem + ".png"
        # Flatten subdirectories into the category folder.
        # e.g. tiles/desert/tile_sand.svg -> tiles/tile_sand.png
        png_rel = Path(category) / png_name
        png_path = output_dir / png_rel

        if args.dry_run:
            print(f"  [dry-run] {rel}  ->  {png_rel}  ({w}x{h})")
            converted.append({
                "id": svg_file.stem,
                "path": str(png_rel).replace("\\", "/"),
                "category": category,
                "width": w,
                "height": h,
                "source_svg": str(rel).replace("\\", "/"),
            })
            continue

        # Actual conversion
        ok = convert_svg(svg_file, png_path, w, h)
        if ok:
            print(f"  OK   {rel}  ->  {png_rel}  ({w}x{h})")
            converted.append({
                "id": svg_file.stem,
                "path": str(png_rel).replace("\\", "/"),
                "category": category,
                "width": w,
                "height": h,
                "source_svg": str(rel).replace("\\", "/"),
            })
        else:
            print(f"  FAIL {rel}")
            failed.append(str(rel))

    # ------------------------------------------------------------------
    # Write manifests
    # ------------------------------------------------------------------
    if converted:
        # 1) texture_manifest.json (for AssetLoader.LoadManifest)
        tex_manifest_path = output_dir / "texture_manifest.json"
        tex_manifest = build_texture_manifest(converted)
        if not args.dry_run:
            tex_manifest_path.parent.mkdir(parents=True, exist_ok=True)
            with open(tex_manifest_path, "w", encoding="utf-8") as f:
                json.dump(tex_manifest, f, indent=2)

        # 2) assets_manifest.json (category-grouped, human-friendly)
        assets_manifest = build_assets_manifest(converted)
        if not args.dry_run:
            manifest_path.parent.mkdir(parents=True, exist_ok=True)
            with open(manifest_path, "w", encoding="utf-8") as f:
                json.dump(assets_manifest, f, indent=2)

    # ------------------------------------------------------------------
    # Summary
    # ------------------------------------------------------------------
    print()
    print("=" * 60)
    print(f"  Total SVGs found:  {len(svg_files)}")
    print(f"  Converted:         {len(converted)}")
    print(f"  Failed:            {len(failed)}")
    if not args.dry_run and converted:
        print(f"  texture_manifest:  {output_dir / 'texture_manifest.json'}")
        print(f"  assets_manifest:   {manifest_path}")
    print("=" * 60)

    if failed:
        print()
        print("Failed files:")
        for f in failed:
            print(f"  - {f}")

    return 1 if failed and not converted else 0


if __name__ == "__main__":
    sys.exit(main())
