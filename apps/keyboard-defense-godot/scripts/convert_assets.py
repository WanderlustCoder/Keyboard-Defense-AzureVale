#!/usr/bin/env python3
"""
Asset Pipeline - SVG to PNG Converter

Converts SVG source files to PNG sprites based on assets_manifest.json.
Supports multiple conversion backends: cairosvg (Python), Inkscape, or rsvg-convert.

Usage:
    python scripts/convert_assets.py              # Convert all missing PNGs
    python scripts/convert_assets.py --all        # Reconvert everything
    python scripts/convert_assets.py --id enemy_scout  # Convert specific asset
    python scripts/convert_assets.py --dry-run    # Show what would be converted
"""

import json
import os
import sys
import subprocess
import shutil
from pathlib import Path
from typing import Optional, List, Dict, Any

# Project paths
SCRIPT_DIR = Path(__file__).parent
PROJECT_ROOT = SCRIPT_DIR.parent
MANIFEST_PATH = PROJECT_ROOT / "data" / "assets_manifest.json"
SVG_ROOT = PROJECT_ROOT / "assets" / "art" / "src-svg"
PNG_ROOT = PROJECT_ROOT / "assets" / "sprites"


class ConversionBackend:
    """Base class for SVG to PNG conversion backends."""

    name: str = "base"

    @classmethod
    def is_available(cls) -> bool:
        return False

    @classmethod
    def convert(cls, svg_path: Path, png_path: Path, width: int, height: int) -> bool:
        raise NotImplementedError


class CairoSVGBackend(ConversionBackend):
    """Python cairosvg library backend."""

    name = "cairosvg"

    @classmethod
    def is_available(cls) -> bool:
        try:
            import cairosvg
            return True
        except ImportError:
            return False

    @classmethod
    def convert(cls, svg_path: Path, png_path: Path, width: int, height: int) -> bool:
        try:
            import cairosvg
            cairosvg.svg2png(
                url=str(svg_path),
                write_to=str(png_path),
                output_width=width,
                output_height=height
            )
            return True
        except Exception as e:
            print(f"  cairosvg error: {e}")
            return False


class InkscapeBackend(ConversionBackend):
    """Inkscape command-line backend."""

    name = "inkscape"

    @classmethod
    def is_available(cls) -> bool:
        return shutil.which("inkscape") is not None

    @classmethod
    def convert(cls, svg_path: Path, png_path: Path, width: int, height: int) -> bool:
        try:
            result = subprocess.run([
                "inkscape",
                str(svg_path),
                "--export-type=png",
                f"--export-filename={png_path}",
                f"--export-width={width}",
                f"--export-height={height}"
            ], capture_output=True, text=True, timeout=30)
            return result.returncode == 0
        except Exception as e:
            print(f"  inkscape error: {e}")
            return False


class RsvgConvertBackend(ConversionBackend):
    """rsvg-convert command-line backend (from librsvg)."""

    name = "rsvg-convert"

    @classmethod
    def is_available(cls) -> bool:
        return shutil.which("rsvg-convert") is not None

    @classmethod
    def convert(cls, svg_path: Path, png_path: Path, width: int, height: int) -> bool:
        try:
            result = subprocess.run([
                "rsvg-convert",
                str(svg_path),
                "-w", str(width),
                "-h", str(height),
                "-o", str(png_path)
            ], capture_output=True, text=True, timeout=30)
            return result.returncode == 0
        except Exception as e:
            print(f"  rsvg-convert error: {e}")
            return False


class ImageMagickBackend(ConversionBackend):
    """ImageMagick convert backend."""

    name = "imagemagick"

    @classmethod
    def is_available(cls) -> bool:
        # Check for 'magick' (v7) or 'convert' (v6)
        return shutil.which("magick") is not None or shutil.which("convert") is not None

    @classmethod
    def convert(cls, svg_path: Path, png_path: Path, width: int, height: int) -> bool:
        try:
            cmd = "magick" if shutil.which("magick") else "convert"
            result = subprocess.run([
                cmd,
                "-background", "none",
                "-resize", f"{width}x{height}",
                str(svg_path),
                str(png_path)
            ], capture_output=True, text=True, timeout=30)
            return result.returncode == 0
        except Exception as e:
            print(f"  imagemagick error: {e}")
            return False


# Available backends in preference order
BACKENDS = [CairoSVGBackend, InkscapeBackend, RsvgConvertBackend, ImageMagickBackend]


def get_backend() -> Optional[ConversionBackend]:
    """Find the first available conversion backend."""
    for backend in BACKENDS:
        if backend.is_available():
            return backend
    return None


def load_manifest() -> Dict[str, Any]:
    """Load the assets manifest."""
    if not MANIFEST_PATH.exists():
        print(f"ERROR: Manifest not found: {MANIFEST_PATH}")
        sys.exit(1)

    with open(MANIFEST_PATH, "r", encoding="utf-8") as f:
        return json.load(f)


def resolve_svg_path(texture: Dict[str, Any]) -> Optional[Path]:
    """Resolve the SVG source path for a texture."""
    # Check source_svg field
    source_svg = texture.get("source_svg", "")
    if source_svg:
        # Convert res:// path to filesystem path
        if source_svg.startswith("res://"):
            rel_path = source_svg[6:]  # Remove res://
            full_path = PROJECT_ROOT / rel_path
            if full_path.exists():
                return full_path

    # Try to find SVG based on texture ID
    texture_id = texture.get("id", "")
    if texture_id:
        # Search in common SVG locations
        search_paths = [
            SVG_ROOT / "sprites" / f"{texture_id}.svg",
            SVG_ROOT / "enemies" / f"{texture_id}.svg",
            SVG_ROOT / "buildings" / f"{texture_id}.svg",
            SVG_ROOT / "effects" / f"{texture_id}.svg",
            SVG_ROOT / "ui" / f"{texture_id}.svg",
            SVG_ROOT / "terrain" / f"{texture_id}.svg",
            SVG_ROOT / "items" / f"{texture_id}.svg",
        ]
        for path in search_paths:
            if path.exists():
                return path

    return None


def resolve_png_path(texture: Dict[str, Any]) -> Path:
    """Resolve the PNG output path for a texture."""
    path = texture.get("path", "")
    if path.startswith("res://"):
        rel_path = path[6:]
        return PROJECT_ROOT / rel_path

    # Fallback: generate path from ID
    texture_id = texture.get("id", "unknown")
    return PNG_ROOT / f"{texture_id}.png"


def convert_texture(texture: Dict[str, Any], backend: ConversionBackend, dry_run: bool = False) -> bool:
    """Convert a single texture from SVG to PNG."""
    texture_id = texture.get("id", "unknown")

    # Get paths
    svg_path = resolve_svg_path(texture)
    png_path = resolve_png_path(texture)

    if not svg_path:
        return False  # No SVG source

    # Get dimensions
    width = texture.get("expected_width", 32)
    height = texture.get("expected_height", 32)

    if dry_run:
        print(f"  Would convert: {svg_path.name} -> {png_path.name} ({width}x{height})")
        return True

    # Ensure output directory exists
    png_path.parent.mkdir(parents=True, exist_ok=True)

    # Convert
    print(f"  Converting: {texture_id} ({width}x{height})...", end=" ")
    success = backend.convert(svg_path, png_path, width, height)

    if success:
        print("OK")
    else:
        print("FAILED")

    return success


def convert_animation_frames(texture: Dict[str, Any], backend: ConversionBackend, dry_run: bool = False) -> int:
    """Convert animation frames from SVG to PNG sprite sheet or individual frames."""
    texture_id = texture.get("id", "unknown")
    source_svg_frames = texture.get("source_svg_frames")

    if not source_svg_frames:
        return 0

    # Handle both string (pattern) and array (list of files)
    if isinstance(source_svg_frames, str):
        # Pattern like "res://assets/art/src-svg/sprites/anim/enemy_walk_{frame}.svg"
        # Need to find matching files
        pattern_path = source_svg_frames
        if pattern_path.startswith("res://"):
            pattern_path = pattern_path[6:]

        # For now, skip pattern-based (would need glob expansion)
        return 0

    elif isinstance(source_svg_frames, list):
        converted = 0
        frame_width = texture.get("frame_width", texture.get("expected_width", 32))
        frame_height = texture.get("frame_height", texture.get("expected_height", 32))

        for i, frame_svg in enumerate(source_svg_frames):
            if frame_svg.startswith("res://"):
                svg_path = PROJECT_ROOT / frame_svg[6:]
            else:
                svg_path = Path(frame_svg)

            if not svg_path.exists():
                continue

            # Output path for frame
            png_path = resolve_png_path(texture)
            frame_png = png_path.parent / f"{png_path.stem}_frame{i}.png"

            if dry_run:
                print(f"  Would convert frame {i}: {svg_path.name} -> {frame_png.name}")
                converted += 1
                continue

            print(f"  Converting frame {i}: {texture_id}...", end=" ")
            if backend.convert(svg_path, frame_png, frame_width, frame_height):
                print("OK")
                converted += 1
            else:
                print("FAILED")

        return converted

    return 0


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Convert SVG assets to PNG")
    parser.add_argument("--all", action="store_true", help="Reconvert all assets, not just missing")
    parser.add_argument("--id", type=str, help="Convert specific asset by ID")
    parser.add_argument("--dry-run", action="store_true", help="Show what would be converted")
    parser.add_argument("--backend", type=str, choices=["cairosvg", "inkscape", "rsvg-convert", "imagemagick"],
                        help="Force specific backend")
    args = parser.parse_args()

    print("=" * 60)
    print("ASSET PIPELINE - SVG TO PNG CONVERTER")
    print("=" * 60)

    # Find backend
    if args.backend:
        backend_map = {b.name: b for b in BACKENDS}
        backend = backend_map.get(args.backend)
        if not backend or not backend.is_available():
            print(f"ERROR: Backend '{args.backend}' not available")
            sys.exit(1)
    else:
        backend = get_backend()

    if not backend:
        print("\nERROR: No conversion backend available!")
        print("\nInstall one of:")
        print("  pip install cairosvg     (recommended)")
        print("  apt install inkscape")
        print("  apt install librsvg2-bin  (for rsvg-convert)")
        print("  apt install imagemagick")
        sys.exit(1)

    print(f"\nUsing backend: {backend.name}")

    # Load manifest
    manifest = load_manifest()
    textures = manifest.get("textures", [])

    print(f"Found {len(textures)} textures in manifest\n")

    # Filter textures
    if args.id:
        textures = [t for t in textures if t.get("id") == args.id]
        if not textures:
            print(f"ERROR: No texture found with ID '{args.id}'")
            sys.exit(1)

    # Process textures
    converted = 0
    skipped = 0
    failed = 0
    no_source = 0

    for texture in textures:
        texture_id = texture.get("id", "unknown")
        png_path = resolve_png_path(texture)
        svg_path = resolve_svg_path(texture)

        # Check if we should convert
        if not svg_path:
            no_source += 1
            continue

        if png_path.exists() and not args.all:
            skipped += 1
            continue

        # Convert main texture
        if convert_texture(texture, backend, args.dry_run):
            converted += 1
        else:
            failed += 1

        # Convert animation frames if present
        frame_count = convert_animation_frames(texture, backend, args.dry_run)
        converted += frame_count

    # Summary
    print("\n" + "=" * 60)
    print("SUMMARY")
    print("=" * 60)
    print(f"  Converted: {converted}")
    print(f"  Skipped (exists): {skipped}")
    print(f"  No SVG source: {no_source}")
    print(f"  Failed: {failed}")

    if args.dry_run:
        print("\n  (Dry run - no files were modified)")

    if failed > 0:
        sys.exit(1)


if __name__ == "__main__":
    main()
