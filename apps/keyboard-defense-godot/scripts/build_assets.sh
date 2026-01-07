#!/bin/bash
# Build script to convert SVG assets to PNG
# Requires: Inkscape, ImageMagick, or rsvg-convert

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SRC_DIR="$PROJECT_DIR/assets/art/src-svg"
OUT_DIR="$PROJECT_DIR/assets"

echo "Building assets from SVG sources..."
echo "Source: $SRC_DIR"
echo "Output: $OUT_DIR"

# Check for conversion tool
if command -v rsvg-convert &> /dev/null; then
    CONVERTER="rsvg-convert"
elif command -v inkscape &> /dev/null; then
    CONVERTER="inkscape"
else
    echo "Error: No SVG converter found. Please install rsvg-convert or inkscape."
    exit 1
fi

echo "Using converter: $CONVERTER"

# Create output directories
mkdir -p "$OUT_DIR/icons"
mkdir -p "$OUT_DIR/tiles"
mkdir -p "$OUT_DIR/sprites"
mkdir -p "$OUT_DIR/ui"

convert_svg() {
    local src="$1"
    local dst="$2"

    if [ "$CONVERTER" = "rsvg-convert" ]; then
        rsvg-convert -o "$dst" "$src"
    else
        inkscape --export-filename="$dst" "$src" 2>/dev/null
    fi
    echo "  Converted: $(basename "$dst")"
}

# Convert icons
echo ""
echo "Converting icons..."
for svg in "$SRC_DIR/icons"/*.svg; do
    [ -f "$svg" ] || continue
    name=$(basename "$svg" .svg)
    convert_svg "$svg" "$OUT_DIR/icons/${name}.png"
done

# Convert tiles
echo ""
echo "Converting tiles..."
for svg in "$SRC_DIR/tiles"/*.svg; do
    [ -f "$svg" ] || continue
    name=$(basename "$svg" .svg)
    convert_svg "$svg" "$OUT_DIR/tiles/${name}.png"
done

# Convert sprites (buildings, units, enemies, effects)
echo ""
echo "Converting sprites..."
for svg in "$SRC_DIR/sprites"/*.svg; do
    [ -f "$svg" ] || continue
    name=$(basename "$svg" .svg)
    convert_svg "$svg" "$OUT_DIR/sprites/${name}.png"
done

# Convert UI elements
echo ""
echo "Converting UI elements..."
for svg in "$SRC_DIR/ui"/*.svg; do
    [ -f "$svg" ] || continue
    name=$(basename "$svg" .svg)
    convert_svg "$svg" "$OUT_DIR/ui/${name}.png"
done

echo ""
echo "Asset build complete!"
echo ""

# Count assets
icon_count=$(find "$OUT_DIR/icons" -name "*.png" 2>/dev/null | wc -l)
tile_count=$(find "$OUT_DIR/tiles" -name "*.png" 2>/dev/null | wc -l)
sprite_count=$(find "$OUT_DIR/sprites" -name "*.png" 2>/dev/null | wc -l)
ui_count=$(find "$OUT_DIR/ui" -name "*.png" 2>/dev/null | wc -l)

echo "Summary:"
echo "  Icons:   $icon_count"
echo "  Tiles:   $tile_count"
echo "  Sprites: $sprite_count"
echo "  UI:      $ui_count"
echo "  Total:   $((icon_count + tile_count + sprite_count + ui_count))"
