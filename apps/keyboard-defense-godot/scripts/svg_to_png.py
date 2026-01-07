#!/usr/bin/env python3
"""
Simple SVG to PNG converter for pixel art assets.
Parses rectangle-based SVGs and outputs PNG files.
No external dependencies required.
"""

import os
import re
import struct
import zlib
from pathlib import Path

def parse_color(color_str):
    """Parse hex color to RGBA tuple."""
    if not color_str or color_str == "none":
        return (0, 0, 0, 0)
    color_str = color_str.strip().lstrip('#')
    if len(color_str) == 3:
        color_str = ''.join(c*2 for c in color_str)
    if len(color_str) == 6:
        r = int(color_str[0:2], 16)
        g = int(color_str[2:4], 16)
        b = int(color_str[4:6], 16)
        return (r, g, b, 255)
    return (0, 0, 0, 0)

def parse_svg(svg_content):
    """Parse SVG content and extract dimensions and rectangles."""
    # Extract viewBox dimensions
    viewbox_match = re.search(r'viewBox="([^"]+)"', svg_content)
    if viewbox_match:
        parts = viewbox_match.group(1).split()
        width = int(float(parts[2]))
        height = int(float(parts[3]))
    else:
        width_match = re.search(r'width="(\d+)"', svg_content)
        height_match = re.search(r'height="(\d+)"', svg_content)
        width = int(width_match.group(1)) if width_match else 16
        height = int(height_match.group(1)) if height_match else 16

    # Extract rectangles
    rects = []
    rect_pattern = re.compile(r'<rect([^>]+)/?>|<rect([^>]+)>[^<]*</rect>', re.DOTALL)

    for match in rect_pattern.finditer(svg_content):
        attrs = match.group(1) or match.group(2)

        x = 0
        y = 0
        w = width
        h = height
        fill = "#000000"
        opacity = 1.0

        x_match = re.search(r'\bx="([^"]+)"', attrs)
        y_match = re.search(r'\by="([^"]+)"', attrs)
        w_match = re.search(r'\bwidth="([^"]+)"', attrs)
        h_match = re.search(r'\bheight="([^"]+)"', attrs)
        fill_match = re.search(r'\bfill="([^"]+)"', attrs)
        opacity_match = re.search(r'\bfill-opacity="([^"]+)"', attrs)

        if x_match:
            x = int(float(x_match.group(1)))
        if y_match:
            y = int(float(y_match.group(1)))
        if w_match:
            w = int(float(w_match.group(1)))
        if h_match:
            h = int(float(h_match.group(1)))
        if fill_match:
            fill = fill_match.group(1)
        if opacity_match:
            opacity = float(opacity_match.group(1))

        color = parse_color(fill)
        if opacity < 1.0:
            color = (color[0], color[1], color[2], int(color[3] * opacity))

        rects.append((x, y, w, h, color))

    return width, height, rects

def render_to_pixels(width, height, rects):
    """Render rectangles to pixel array."""
    # Initialize with transparent pixels
    pixels = [[(0, 0, 0, 0) for _ in range(width)] for _ in range(height)]

    for x, y, w, h, color in rects:
        for py in range(max(0, y), min(height, y + h)):
            for px in range(max(0, x), min(width, x + w)):
                if color[3] == 255:
                    pixels[py][px] = color
                elif color[3] > 0:
                    # Alpha blend
                    old = pixels[py][px]
                    alpha = color[3] / 255.0
                    new_r = int(color[0] * alpha + old[0] * (1 - alpha))
                    new_g = int(color[1] * alpha + old[1] * (1 - alpha))
                    new_b = int(color[2] * alpha + old[2] * (1 - alpha))
                    new_a = max(old[3], color[3])
                    pixels[py][px] = (new_r, new_g, new_b, new_a)

    return pixels

def write_png(filename, width, height, pixels):
    """Write pixels to PNG file."""
    def png_chunk(chunk_type, data):
        chunk_len = struct.pack('>I', len(data))
        chunk_crc = struct.pack('>I', zlib.crc32(chunk_type + data) & 0xffffffff)
        return chunk_len + chunk_type + data + chunk_crc

    # PNG signature
    signature = b'\x89PNG\r\n\x1a\n'

    # IHDR chunk
    ihdr_data = struct.pack('>IIBBBBB', width, height, 8, 6, 0, 0, 0)
    ihdr = png_chunk(b'IHDR', ihdr_data)

    # IDAT chunk (image data)
    raw_data = b''
    for row in pixels:
        raw_data += b'\x00'  # Filter type: None
        for r, g, b, a in row:
            raw_data += bytes([r, g, b, a])

    compressed = zlib.compress(raw_data, 9)
    idat = png_chunk(b'IDAT', compressed)

    # IEND chunk
    iend = png_chunk(b'IEND', b'')

    with open(filename, 'wb') as f:
        f.write(signature + ihdr + idat + iend)

def convert_svg_to_png(svg_path, png_path):
    """Convert a single SVG file to PNG."""
    with open(svg_path, 'r', encoding='utf-8') as f:
        svg_content = f.read()

    width, height, rects = parse_svg(svg_content)
    pixels = render_to_pixels(width, height, rects)
    write_png(png_path, width, height, pixels)

def main():
    script_dir = Path(__file__).parent
    project_dir = script_dir.parent
    src_dir = project_dir / "assets" / "art" / "src-svg"
    out_dir = project_dir / "assets"

    print("Building assets from SVG sources...")
    print(f"Source: {src_dir}")
    print(f"Output: {out_dir}")

    # Create output directories
    (out_dir / "icons").mkdir(parents=True, exist_ok=True)
    (out_dir / "tiles").mkdir(parents=True, exist_ok=True)
    (out_dir / "sprites").mkdir(parents=True, exist_ok=True)
    (out_dir / "ui").mkdir(parents=True, exist_ok=True)

    counts = {"icons": 0, "tiles": 0, "sprites": 0, "ui": 0}

    for category in ["icons", "tiles", "sprites", "ui"]:
        src_category = src_dir / category
        out_category = out_dir / category

        print(f"\nConverting {category}...")

        if not src_category.exists():
            continue

        for svg_file in sorted(src_category.glob("*.svg")):
            png_file = out_category / (svg_file.stem + ".png")
            try:
                convert_svg_to_png(svg_file, png_file)
                print(f"  Converted: {png_file.name}")
                counts[category] += 1
            except Exception as e:
                print(f"  Error converting {svg_file.name}: {e}")

    print("\n" + "="*40)
    print("Asset build complete!")
    print("\nSummary:")
    for category, count in counts.items():
        print(f"  {category.capitalize():10} {count}")
    print(f"  {'Total':10} {sum(counts.values())}")

if __name__ == "__main__":
    main()
