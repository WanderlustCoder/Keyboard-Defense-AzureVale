"""
Pure Python PNG Writer - No Dependencies Required
Creates valid PNG files using only Python standard library.
"""

import struct
import zlib
from typing import List, Tuple

# Type aliases
Color = Tuple[int, int, int, int]  # RGBA


def create_png(width: int, height: int, pixels: List[List[Color]]) -> bytes:
    """
    Create a PNG file from pixel data.

    Args:
        width: Image width in pixels
        height: Image height in pixels
        pixels: 2D list of RGBA tuples, pixels[y][x] = (r, g, b, a)

    Returns:
        PNG file as bytes
    """
    def make_chunk(chunk_type: bytes, data: bytes) -> bytes:
        """Create a PNG chunk with CRC."""
        chunk = chunk_type + data
        crc = zlib.crc32(chunk) & 0xffffffff
        return struct.pack('>I', len(data)) + chunk + struct.pack('>I', crc)

    # PNG signature
    png_data = b'\x89PNG\r\n\x1a\n'

    # IHDR chunk (image header)
    ihdr_data = struct.pack('>IIBBBBB', width, height, 8, 6, 0, 0, 0)
    # 8 = bit depth, 6 = RGBA color type, 0 = compression, 0 = filter, 0 = interlace
    png_data += make_chunk(b'IHDR', ihdr_data)

    # IDAT chunk (image data)
    raw_data = b''
    for y in range(height):
        raw_data += b'\x00'  # Filter type: None
        for x in range(width):
            r, g, b, a = pixels[y][x]
            raw_data += struct.pack('BBBB', r, g, b, a)

    compressed = zlib.compress(raw_data, 9)
    png_data += make_chunk(b'IDAT', compressed)

    # IEND chunk (image end)
    png_data += make_chunk(b'IEND', b'')

    return png_data


def save_png(filepath: str, width: int, height: int, pixels: List[List[Color]]) -> None:
    """Save pixel data as a PNG file."""
    png_bytes = create_png(width, height, pixels)
    with open(filepath, 'wb') as f:
        f.write(png_bytes)


def create_blank_canvas(width: int, height: int, color: Color = (0, 0, 0, 0)) -> List[List[Color]]:
    """Create a blank canvas filled with a single color."""
    return [[color for _ in range(width)] for _ in range(height)]


def blend_colors(base: Color, overlay: Color) -> Color:
    """Alpha blend overlay color onto base color."""
    br, bg, bb, ba = base
    or_, og, ob, oa = overlay

    if oa == 0:
        return base
    if oa == 255:
        return overlay

    # Alpha blending
    alpha = oa / 255.0
    inv_alpha = 1.0 - alpha

    nr = int(or_ * alpha + br * inv_alpha)
    ng = int(og * alpha + bg * inv_alpha)
    nb = int(ob * alpha + bb * inv_alpha)
    na = max(ba, oa)

    return (nr, ng, nb, na)


def lerp_color(c1: Color, c2: Color, t: float) -> Color:
    """Linear interpolation between two colors."""
    t = max(0.0, min(1.0, t))
    return (
        int(c1[0] + (c2[0] - c1[0]) * t),
        int(c1[1] + (c2[1] - c1[1]) * t),
        int(c1[2] + (c2[2] - c1[2]) * t),
        int(c1[3] + (c2[3] - c1[3]) * t)
    )


def hex_to_rgba(hex_color: str, alpha: int = 255) -> Color:
    """Convert hex color string to RGBA tuple."""
    hex_color = hex_color.lstrip('#')
    r = int(hex_color[0:2], 16)
    g = int(hex_color[2:4], 16)
    b = int(hex_color[4:6], 16)
    return (r, g, b, alpha)


class Canvas:
    """Drawing canvas with various shape primitives."""

    def __init__(self, width: int, height: int, bg_color: Color = (0, 0, 0, 0)):
        self.width = width
        self.height = height
        self.pixels = create_blank_canvas(width, height, bg_color)

    def set_pixel(self, x: int, y: int, color: Color) -> None:
        """Set a single pixel with alpha blending."""
        if 0 <= x < self.width and 0 <= y < self.height:
            self.pixels[y][x] = blend_colors(self.pixels[y][x], color)

    def fill_rect(self, x: int, y: int, w: int, h: int, color: Color) -> None:
        """Fill a rectangle."""
        for py in range(max(0, y), min(self.height, y + h)):
            for px in range(max(0, x), min(self.width, x + w)):
                self.set_pixel(px, py, color)

    def fill_ellipse(self, cx: int, cy: int, rx: int, ry: int, color: Color) -> None:
        """Fill an ellipse centered at (cx, cy) with radii rx, ry."""
        for py in range(max(0, cy - ry), min(self.height, cy + ry + 1)):
            for px in range(max(0, cx - rx), min(self.width, cx + rx + 1)):
                # Check if point is inside ellipse
                dx = (px - cx) / max(rx, 0.1)
                dy = (py - cy) / max(ry, 0.1)
                if dx * dx + dy * dy <= 1.0:
                    self.set_pixel(px, py, color)

    def fill_circle(self, cx: int, cy: int, r: int, color: Color) -> None:
        """Fill a circle."""
        self.fill_ellipse(cx, cy, r, r, color)

    def draw_line(self, x1: int, y1: int, x2: int, y2: int, color: Color, thickness: int = 1) -> None:
        """Draw a line using Bresenham's algorithm with optional thickness."""
        dx = abs(x2 - x1)
        dy = abs(y2 - y1)
        sx = 1 if x1 < x2 else -1
        sy = 1 if y1 < y2 else -1
        err = dx - dy

        while True:
            if thickness == 1:
                self.set_pixel(x1, y1, color)
            else:
                self.fill_circle(x1, y1, thickness // 2, color)

            if x1 == x2 and y1 == y2:
                break

            e2 = 2 * err
            if e2 > -dy:
                err -= dy
                x1 += sx
            if e2 < dx:
                err += dx
                y1 += sy

    def fill_polygon(self, points: List[Tuple[int, int]], color: Color) -> None:
        """Fill a polygon using scanline algorithm."""
        if len(points) < 3:
            return

        # Find bounding box
        min_y = max(0, min(p[1] for p in points))
        max_y = min(self.height - 1, max(p[1] for p in points))

        for y in range(min_y, max_y + 1):
            # Find intersections with polygon edges
            intersections = []
            n = len(points)
            for i in range(n):
                p1 = points[i]
                p2 = points[(i + 1) % n]

                if p1[1] == p2[1]:
                    continue

                if p1[1] > p2[1]:
                    p1, p2 = p2, p1

                if p1[1] <= y < p2[1]:
                    x = p1[0] + (y - p1[1]) * (p2[0] - p1[0]) / (p2[1] - p1[1])
                    intersections.append(int(x))

            intersections.sort()

            # Fill between pairs of intersections
            for i in range(0, len(intersections) - 1, 2):
                x1 = max(0, intersections[i])
                x2 = min(self.width - 1, intersections[i + 1])
                for x in range(x1, x2 + 1):
                    self.set_pixel(x, y, color)

    def gradient_fill_vertical(self, x: int, y: int, w: int, h: int,
                                top_color: Color, bottom_color: Color) -> None:
        """Fill rectangle with vertical gradient."""
        for py in range(max(0, y), min(self.height, y + h)):
            t = (py - y) / max(h - 1, 1)
            color = lerp_color(top_color, bottom_color, t)
            for px in range(max(0, x), min(self.width, x + w)):
                self.set_pixel(px, py, color)

    def gradient_fill_radial(self, cx: int, cy: int, r: int,
                              center_color: Color, edge_color: Color) -> None:
        """Fill circle with radial gradient."""
        for py in range(max(0, cy - r), min(self.height, cy + r + 1)):
            for px in range(max(0, cx - r), min(self.width, cx + r + 1)):
                dist = ((px - cx) ** 2 + (py - cy) ** 2) ** 0.5
                if dist <= r:
                    t = dist / r
                    color = lerp_color(center_color, edge_color, t)
                    self.set_pixel(px, py, color)

    def save(self, filepath: str) -> None:
        """Save canvas to PNG file."""
        save_png(filepath, self.width, self.height, self.pixels)


if __name__ == "__main__":
    # Test: create a simple gradient
    canvas = Canvas(64, 64, hex_to_rgba("#1a1a2e"))
    canvas.gradient_fill_radial(32, 32, 25, hex_to_rgba("#ff6b6b"), hex_to_rgba("#4a235a"))
    canvas.fill_circle(32, 20, 8, hex_to_rgba("#f5cba7"))
    canvas.save("test_png.png")
    print("Created test_png.png")
