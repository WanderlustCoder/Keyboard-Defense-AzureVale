#!/usr/bin/env python3
"""
High-Resolution Pixel Art Portrait Generator for Lyra - Version 2
Refined to better match the HighRes.png reference style.

Key improvements:
- Larger, more expressive anime-style eyes
- Rounder face with chibi-like proportions
- More voluminous hair with strand clusters
- Better color palette matching reference
- Improved shading and lighting
"""

import math
import random
from typing import List, Tuple, Optional
from png_writer import Canvas, hex_to_rgba, lerp_color, blend_colors, Color


# ============================================================================
# COLOR PALETTES - Matched to HighRes.png reference
# ============================================================================

class ColorRamp:
    """A color ramp with multiple shades from highlight to deep shadow."""

    def __init__(self, colors: List[str]):
        self.colors = [hex_to_rgba(c) for c in colors]

    def get(self, t: float) -> Color:
        t = max(0.0, min(1.0, t))
        if len(self.colors) == 1:
            return self.colors[0]
        idx = t * (len(self.colors) - 1)
        i = int(idx)
        frac = idx - i
        if i >= len(self.colors) - 1:
            return self.colors[-1]
        return lerp_color(self.colors[i], self.colors[i + 1], frac)


# Palettes matched more closely to HighRes.png
PALETTES = {
    # Hair: Lavender/purple - more saturated pinks in highlights
    'hair': ColorRamp([
        '#f0d8f8',  # Bright pink-white highlight
        '#e0c0e8',  # Pink highlight
        '#c8a0d8',  # Light lavender
        '#b080c8',  # Mid lavender
        '#9060b0',  # Base purple
        '#704090',  # Mid shadow
        '#502870',  # Shadow
        '#381850',  # Deep shadow
        '#201038',  # Darkest
    ]),

    # Skin: Warmer, more orange-peachy tones (matching reference)
    'skin': ColorRamp([
        '#ffe8d0',  # Warm highlight
        '#ffd8b8',  # Light
        '#f0c098',  # Mid-light (the dominant skin tone in reference)
        '#e0a878',  # Base
        '#c08858',  # Mid-shadow
        '#986840',  # Shadow
        '#704828',  # Deep shadow
    ]),

    # Robe: Blue with slight purple undertone
    'robe': ColorRamp([
        '#8898c0',  # Highlight
        '#6878a8',  # Light
        '#506090',  # Mid
        '#384878',  # Base
        '#283460',  # Shadow
        '#182048',  # Deep shadow
        '#101030',  # Darkest
    ]),

    # Glasses: Warm brown/amber frames
    'glasses': ColorRamp([
        '#c89868',  # Highlight
        '#a87848',  # Light
        '#886030',  # Base
        '#684820',  # Shadow
        '#483010',  # Deep
    ]),

    # Book cover
    'book': ColorRamp([
        '#a88060',  # Highlight
        '#886040',  # Light
        '#684828',  # Base
        '#483018',  # Shadow
        '#302010',  # Deep
    ]),

    # Book pages
    'pages': ColorRamp([
        '#f8f0e0',  # Highlight
        '#e8e0d0',  # Light
        '#d8d0c0',  # Base
        '#c0b8a8',  # Shadow
    ]),

    # Background: Deep navy (uniform, matching reference)
    'background': ColorRamp([
        '#181830',  # Slightly brighter than pure dark
        '#141428',  # Main background
        '#101020',  # Darker edge
    ]),

    # Eye whites
    'eye_white': ColorRamp([
        '#ffffff',
        '#f0f0f8',
        '#d0d0e0',
        '#a0a0b8',
    ]),

    # Eye iris - darker, more defined
    'eye_iris': ColorRamp([
        '#607090',
        '#405068',
        '#283848',
        '#182030',
    ]),
}


# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

def distance(x1: float, y1: float, x2: float, y2: float) -> float:
    return math.sqrt((x2 - x1) ** 2 + (y2 - y1) ** 2)


def point_in_ellipse(px: float, py: float, cx: float, cy: float, rx: float, ry: float) -> bool:
    if rx <= 0 or ry <= 0:
        return False
    dx = (px - cx) / rx
    dy = (py - cy) / ry
    return dx * dx + dy * dy <= 1.0


def ellipse_sdf(px: float, py: float, cx: float, cy: float, rx: float, ry: float) -> float:
    """Signed distance field for ellipse - negative inside, positive outside."""
    if rx <= 0 or ry <= 0:
        return float('inf')
    dx = (px - cx) / rx
    dy = (py - cy) / ry
    return math.sqrt(dx * dx + dy * dy) - 1.0


def simple_noise(x: float, y: float, seed: int = 0) -> float:
    n = int(x * 73 + y * 179 + seed * 31)
    n = (n << 13) ^ n
    return 1.0 - ((n * (n * n * 15731 + 789221) + 1376312589) & 0x7fffffff) / 1073741824.0


def perlin_noise(x: float, y: float, seed: int = 0) -> float:
    x0, y0 = int(math.floor(x)), int(math.floor(y))
    fx, fy = x - x0, y - y0
    fx = fx * fx * (3 - 2 * fx)
    fy = fy * fy * (3 - 2 * fy)
    v00 = simple_noise(x0, y0, seed)
    v10 = simple_noise(x0 + 1, y0, seed)
    v01 = simple_noise(x0, y0 + 1, seed)
    v11 = simple_noise(x0 + 1, y0 + 1, seed)
    return (v00 * (1 - fx) + v10 * fx) * (1 - fy) + (v01 * (1 - fx) + v11 * fx) * fy


def fractal_noise(x: float, y: float, octaves: int = 3, seed: int = 0) -> float:
    total, amplitude, max_val = 0.0, 1.0, 0.0
    freq = 1.0
    for _ in range(octaves):
        total += perlin_noise(x * freq, y * freq, seed) * amplitude
        max_val += amplitude
        amplitude *= 0.5
        freq *= 2.0
    return total / max_val


# ============================================================================
# PORTRAIT GENERATOR V2
# ============================================================================

class LyraPortraitV2:
    """
    Generates Lyra portraits with style matching HighRes.png reference.
    Key changes from v1:
    - Smaller character in frame, more hair volume
    - Much larger anime-style eyes
    - Rounder face shape
    - Better strand-based hair rendering
    """

    def __init__(self, size: int = 128, seed: int = None):
        self.size = size
        self.seed = seed if seed is not None else random.randint(0, 10000)
        self.canvas = None
        random.seed(self.seed)

        # Scale factor for size adjustments
        self.scale = size / 128.0

        # Character positioning - smaller in frame, lower
        self.cx = size // 2
        self.cy = int(size * 0.52)  # Character center (slightly below middle)

        # Head proportions (rounder, smaller relative to canvas)
        self.head_w = int(22 * self.scale)  # Half-width of head
        self.head_h = int(24 * self.scale)  # Half-height of head

        # Eye proportions (MUCH larger - anime style)
        self.eye_w = int(10 * self.scale)   # Eye half-width
        self.eye_h = int(8 * self.scale)    # Eye half-height
        self.eye_spacing = int(12 * self.scale)  # Distance from center to eye center

        # Hair extends well beyond head
        self.hair_extra_w = int(18 * self.scale)
        self.hair_extra_h = int(15 * self.scale)

    def generate(self, expression: str = 'neutral') -> Canvas:
        """Generate complete portrait."""
        bg_color = PALETTES['background'].get(0.3)
        self.canvas = Canvas(self.size, self.size, bg_color)

        # Layer order (back to front)
        self._draw_background()
        self._draw_hair_back()
        self._draw_shoulders()
        self._draw_book()
        self._draw_neck()
        self._draw_face()
        self._draw_ears()
        self._draw_eyes(expression)
        self._draw_nose()
        self._draw_mouth(expression)
        self._draw_eyebrows(expression)
        self._draw_glasses()
        self._draw_hair_front()
        self._draw_hair_bangs()
        self._draw_hair_bun()
        self._add_highlights()

        return self.canvas

    def _draw_background(self) -> None:
        """Solid dark navy background."""
        # Already filled in canvas init, but add subtle variation
        for y in range(self.size):
            for x in range(self.size):
                noise = fractal_noise(x * 0.05, y * 0.05, 2, self.seed) * 0.05
                shade = 0.3 + noise
                self.canvas.pixels[y][x] = PALETTES['background'].get(shade)

    def _draw_hair_back(self) -> None:
        """Draw the main hair mass behind the face."""
        cx, cy = self.cx, self.cy

        # Hair region bounds (extends beyond head)
        hair_left = cx - self.head_w - self.hair_extra_w
        hair_right = cx + self.head_w + self.hair_extra_w
        hair_top = cy - self.head_h - self.hair_extra_h
        hair_bottom = cy + self.head_h + int(10 * self.scale)

        for y in range(max(0, hair_top), min(self.size, hair_bottom)):
            for x in range(max(0, hair_left), min(self.size, hair_right)):
                # Skip face area
                face_dist = ellipse_sdf(x, y, cx, cy + 2, self.head_w - 3, self.head_h - 5)
                if face_dist < -2:
                    continue

                # Hair shape - fuller on top and sides
                rel_y = (y - hair_top) / (hair_bottom - hair_top)
                rel_x = (x - cx) / (hair_right - cx) if x > cx else (x - cx) / (cx - hair_left)

                # Width varies with height - very full at top, narrower at bottom
                width_at_y = 1.0 - rel_y * 0.4
                if abs(rel_x) > width_at_y:
                    continue

                # Shading based on position and noise
                light_factor = (1 - rel_y) * 0.3 + (1 - abs(rel_x)) * 0.2

                # Strand-like noise pattern
                strand_noise = fractal_noise(x * 0.15, y * 0.08, 3, self.seed)
                strand_variation = strand_noise * 0.25

                shade = 0.35 + light_factor + strand_variation
                shade = max(0.2, min(0.75, shade))

                # Soft edge
                if face_dist > -5 and face_dist < 0:
                    edge_blend = (face_dist + 5) / 5
                    shade = shade * edge_blend + 0.4 * (1 - edge_blend)

                color = PALETTES['hair'].get(shade)
                self.canvas.set_pixel(x, y, color)

    def _draw_shoulders(self) -> None:
        """Draw shoulders and robe."""
        cx = self.cx
        shoulder_top = self.cy + self.head_h - int(5 * self.scale)

        for y in range(shoulder_top, self.size):
            rel_y = (y - shoulder_top) / (self.size - shoulder_top)

            # Shoulder width expands downward
            half_width = int((self.head_w + rel_y * 25) * self.scale)

            for x in range(cx - half_width, cx + half_width):
                if 0 <= x < self.size:
                    # Shading - light from upper left
                    rel_x = (x - cx) / half_width
                    light = (1 - rel_x) * 0.15 + (1 - rel_y) * 0.2

                    # Cloth folds
                    fold = perlin_noise(x * 0.1, y * 0.05, self.seed + 100)
                    fold_shade = 0.1 if fold > 0.3 else (-0.1 if fold < -0.3 else 0)

                    shade = 0.35 + light + fold_shade
                    shade = max(0.2, min(0.65, shade))

                    color = PALETTES['robe'].get(shade)
                    self.canvas.set_pixel(x, y, color)

    def _draw_book(self) -> None:
        """Draw the book being held."""
        cx = self.cx
        book_top = self.cy + self.head_h + int(15 * self.scale)
        book_bottom = min(self.size - 5, book_top + int(20 * self.scale))
        book_half_w = int(25 * self.scale)

        # Book cover
        for y in range(book_top, book_bottom):
            rel_y = (y - book_top) / (book_bottom - book_top)
            for x in range(cx - book_half_w, cx + book_half_w):
                if 0 <= x < self.size:
                    rel_x = (x - cx) / book_half_w
                    shade = 0.3 + (1 - rel_y) * 0.2 + (1 - abs(rel_x)) * 0.1
                    color = PALETTES['book'].get(shade)
                    self.canvas.set_pixel(x, y, color)

        # Pages
        page_margin = int(4 * self.scale)
        for y in range(book_top + page_margin, book_bottom - page_margin):
            for x in range(cx - book_half_w + page_margin + 2, cx + book_half_w - page_margin - 2):
                if 0 <= x < self.size:
                    shade = 0.1 + random.random() * 0.1
                    color = PALETTES['pages'].get(shade)
                    self.canvas.set_pixel(x, y, color)

        # Text line hints
        for i in range(3):
            line_y = book_top + page_margin + 3 + i * int(4 * self.scale)
            if line_y < book_bottom - page_margin:
                line_len = int((15 + random.randint(-5, 5)) * self.scale)
                for x in range(cx - line_len, cx + line_len):
                    if random.random() > 0.3:
                        self.canvas.set_pixel(x, line_y, PALETTES['book'].get(0.4))

    def _draw_neck(self) -> None:
        """Draw neck."""
        cx = self.cx
        neck_top = self.cy + self.head_h - int(10 * self.scale)
        neck_bottom = self.cy + self.head_h + int(5 * self.scale)
        neck_half_w = int(8 * self.scale)

        for y in range(neck_top, neck_bottom):
            for x in range(cx - neck_half_w, cx + neck_half_w):
                rel_x = (x - cx) / neck_half_w
                shade = 0.35 + (1 - abs(rel_x)) * 0.1 + rel_x * 0.1
                color = PALETTES['skin'].get(shade)
                self.canvas.set_pixel(x, y, color)

    def _draw_face(self) -> None:
        """Draw the face - rounder shape."""
        cx, cy = self.cx, self.cy + 2  # Slightly lower face center

        for y in range(self.size):
            for x in range(self.size):
                dist = ellipse_sdf(x, y, cx, cy, self.head_w - 2, self.head_h - 3)

                if dist < 0:
                    # Inside face
                    norm_dist = -dist / max(self.head_w, self.head_h) * 5  # Normalize

                    # Lighting from upper-left
                    rel_x = (x - cx) / self.head_w
                    rel_y = (y - cy) / self.head_h
                    light = (1 - rel_x) * 0.15 + (1 - rel_y) * 0.2

                    # Subtle variation
                    noise = perlin_noise(x * 0.1, y * 0.1, self.seed + 200) * 0.05

                    shade = 0.25 + light + norm_dist * 0.05 + noise
                    shade = max(0.15, min(0.5, shade))

                    color = PALETTES['skin'].get(shade)
                    self.canvas.set_pixel(x, y, color)

    def _draw_ears(self) -> None:
        """Draw ears peeking from hair."""
        cy = self.cy + 2
        ear_y = cy
        ear_w = int(5 * self.scale)
        ear_h = int(7 * self.scale)

        for side in [-1, 1]:
            ear_x = self.cx + side * (self.head_w - 2)

            for y in range(ear_y - ear_h, ear_y + ear_h):
                for x in range(ear_x - ear_w if side < 0 else ear_x, ear_x if side < 0 else ear_x + ear_w):
                    if point_in_ellipse(x, y, ear_x, ear_y, ear_w, ear_h):
                        dist = distance(x, y, ear_x, ear_y) / max(ear_w, ear_h)
                        shade = 0.3 + dist * 0.15
                        color = PALETTES['skin'].get(shade)
                        self.canvas.set_pixel(x, y, color)

    def _draw_eyes(self, expression: str) -> None:
        """Draw large anime-style eyes."""
        cx, cy = self.cx, self.cy

        # Eye vertical position
        eye_y = cy - int(3 * self.scale)

        # Adjust eye shape for expression
        eye_h = self.eye_h
        if expression == 'surprised':
            eye_h = int(self.eye_h * 1.2)
        elif expression == 'thinking':
            eye_h = int(self.eye_h * 0.75)

        for side in [-1, 1]:
            eye_x = cx + side * self.eye_spacing

            # Eye white (slightly almond shaped)
            for y in range(eye_y - eye_h, eye_y + eye_h + 1):
                for x in range(eye_x - self.eye_w, eye_x + self.eye_w + 1):
                    if point_in_ellipse(x, y, eye_x, eye_y, self.eye_w, eye_h):
                        # Slight shading toward edges
                        dist = distance(x, y, eye_x, eye_y) / max(self.eye_w, eye_h)
                        shade = dist * 0.3
                        color = PALETTES['eye_white'].get(shade)
                        self.canvas.set_pixel(x, y, color)

            # Iris (large, taking up most of eye)
            iris_r = int(self.eye_w * 0.7)
            iris_x = eye_x + side * int(1 * self.scale)  # Slightly toward center
            for y in range(eye_y - iris_r, eye_y + iris_r + 1):
                for x in range(iris_x - iris_r, iris_x + iris_r + 1):
                    if point_in_ellipse(x, y, iris_x, eye_y, iris_r, iris_r):
                        dist = distance(x, y, iris_x, eye_y) / iris_r
                        shade = 0.2 + dist * 0.5
                        color = PALETTES['eye_iris'].get(shade)
                        self.canvas.set_pixel(x, y, color)

            # Pupil
            pupil_r = int(iris_r * 0.45)
            for y in range(eye_y - pupil_r, eye_y + pupil_r + 1):
                for x in range(iris_x - pupil_r, iris_x + pupil_r + 1):
                    if point_in_ellipse(x, y, iris_x, eye_y, pupil_r, pupil_r):
                        self.canvas.set_pixel(x, y, (15, 10, 20, 255))

            # Catchlights (bright reflections) - IMPORTANT for life
            # Main catchlight (upper left of iris)
            hl_x = iris_x - int(2 * self.scale)
            hl_y = eye_y - int(2 * self.scale)
            for dy in range(-1, 2):
                for dx in range(-1, 2):
                    if abs(dx) + abs(dy) <= 1:
                        alpha = 255 if dx == 0 and dy == 0 else 180
                        self.canvas.set_pixel(hl_x + dx, hl_y + dy, (255, 255, 255, alpha))

            # Secondary smaller catchlight
            hl2_x = iris_x + int(1 * self.scale)
            hl2_y = eye_y + int(2 * self.scale)
            self.canvas.set_pixel(hl2_x, hl2_y, (255, 255, 255, 150))

            # Upper eyelid shadow
            for x in range(eye_x - self.eye_w - 1, eye_x + self.eye_w + 2):
                self.canvas.set_pixel(x, eye_y - eye_h - 1, PALETTES['skin'].get(0.5))

    def _draw_nose(self) -> None:
        """Draw subtle nose."""
        cx = self.cx
        nose_y = self.cy + int(7 * self.scale)

        # Just a subtle shadow and highlight
        for y in range(nose_y - 2, nose_y + 3):
            self.canvas.set_pixel(cx - 1, y, PALETTES['skin'].get(0.4))

        # Nose tip highlight
        self.canvas.set_pixel(cx, nose_y + 1, PALETTES['skin'].get(0.2))

    def _draw_mouth(self, expression: str) -> None:
        """Draw mouth based on expression."""
        cx = self.cx
        mouth_y = self.cy + int(14 * self.scale)
        mouth_w = int(8 * self.scale)

        if expression in ['neutral', 'thinking']:
            # Gentle smile
            for i in range(-mouth_w, mouth_w + 1):
                curve = int((i * i) / (mouth_w * 1.5))
                self.canvas.set_pixel(cx + i, mouth_y + curve, PALETTES['skin'].get(0.5))

        elif expression == 'encouraging':
            # Bigger smile
            mouth_w = int(10 * self.scale)
            for i in range(-mouth_w, mouth_w + 1):
                curve = int((i * i) / (mouth_w * 1.2))
                self.canvas.set_pixel(cx + i, mouth_y + curve, PALETTES['skin'].get(0.5))
            # Smile corners
            self.canvas.set_pixel(cx - mouth_w - 1, mouth_y, PALETTES['skin'].get(0.45))
            self.canvas.set_pixel(cx + mouth_w + 1, mouth_y, PALETTES['skin'].get(0.45))

        elif expression == 'surprised':
            # Small O shape
            o_r = int(3 * self.scale)
            for angle in range(0, 360, 20):
                rad = math.radians(angle)
                x = int(cx + math.cos(rad) * o_r)
                y = int(mouth_y + 2 + math.sin(rad) * int(o_r * 0.7))
                self.canvas.set_pixel(x, y, PALETTES['skin'].get(0.55))

        elif expression == 'concerned':
            # Slight downturn
            for i in range(-mouth_w, mouth_w + 1):
                curve = -int((i * i) / (mouth_w * 2.5)) + 1
                self.canvas.set_pixel(cx + i, mouth_y + curve, PALETTES['skin'].get(0.5))

        # Lower lip highlight
        self.canvas.set_pixel(cx, mouth_y + 2, PALETTES['skin'].get(0.25))

    def _draw_eyebrows(self, expression: str) -> None:
        """Draw eyebrows."""
        cx, cy = self.cx, self.cy
        brow_y_base = cy - self.eye_h - int(8 * self.scale)
        brow_len = int(10 * self.scale)

        # Adjust for expression
        y_offset = 0
        if expression == 'surprised':
            y_offset = -2
        elif expression == 'concerned':
            y_offset = 1

        for side in [-1, 1]:
            brow_x = cx + side * self.eye_spacing

            for i in range(brow_len):
                progress = i / brow_len
                x = brow_x - side * (brow_len // 2) + side * i

                # Brow curve varies by expression
                if expression == 'concerned':
                    y_curve = int(progress * 3) * side
                elif expression == 'surprised':
                    y_curve = int(math.sin(progress * math.pi) * -3)
                else:
                    y_curve = int(math.sin(progress * math.pi) * -1.5)

                y = brow_y_base + y_offset + y_curve

                # Thickness
                thick = 2 if 0.2 < progress < 0.8 else 1
                for t in range(thick):
                    shade = 0.7 + t * 0.1
                    self.canvas.set_pixel(x, y + t, PALETTES['hair'].get(shade))

    def _draw_glasses(self) -> None:
        """Draw round glasses."""
        cx, cy = self.cx, self.cy
        eye_y = cy - int(3 * self.scale)
        lens_r = self.eye_w + int(3 * self.scale)

        for side in [-1, 1]:
            lens_x = cx + side * self.eye_spacing

            # Lens frame (circle)
            for angle in range(0, 360, 4):
                rad = math.radians(angle)

                for thick in range(2):
                    r = lens_r + thick
                    x = int(lens_x + math.cos(rad) * r)
                    y = int(eye_y + math.sin(rad) * r)

                    # Lighter on top
                    shade = 0.2 + (1 - math.sin(rad)) * 0.25 + thick * 0.15
                    if 0 <= x < self.size and 0 <= y < self.size:
                        self.canvas.set_pixel(x, y, PALETTES['glasses'].get(shade))

            # Subtle lens glare
            glare_x = lens_x - int(3 * self.scale)
            glare_y = eye_y - int(3 * self.scale)
            for dy in range(-2, 3):
                for dx in range(-2, 3):
                    if abs(dx) + abs(dy) <= 2:
                        dist = (abs(dx) + abs(dy)) / 2
                        alpha = int(25 * (1 - dist / 2))
                        self.canvas.set_pixel(glare_x + dx, glare_y + dy, (255, 255, 255, alpha))

        # Bridge between lenses
        bridge_y = eye_y
        for x in range(cx - int(3 * self.scale), cx + int(4 * self.scale)):
            self.canvas.set_pixel(x, bridge_y, PALETTES['glasses'].get(0.35))
            self.canvas.set_pixel(x, bridge_y + 1, PALETTES['glasses'].get(0.45))

        # Temple arms
        for side in [-1, 1]:
            start_x = cx + side * (self.eye_spacing + lens_r + 1)
            for i in range(int(12 * self.scale)):
                x = start_x + side * i
                y = eye_y + i // 3
                if 0 <= x < self.size:
                    self.canvas.set_pixel(x, y, PALETTES['glasses'].get(0.4))

    def _draw_hair_front(self) -> None:
        """Draw hair strands over the sides of face."""
        cx, cy = self.cx, self.cy

        # Side strands
        for side in [-1, 1]:
            base_x = cx + side * (self.head_w + int(5 * self.scale))

            for strand in range(4):
                strand_x = base_x + side * strand * int(3 * self.scale)
                start_y = cy - self.head_h + int(5 * self.scale)

                for y in range(start_y, start_y + int(35 * self.scale)):
                    wave = math.sin((y - start_y) * 0.12 + strand * 0.8) * 4
                    x = int(strand_x + wave)

                    if 0 <= x < self.size and 0 <= y < self.size:
                        # Strand shading
                        progress = (y - start_y) / int(35 * self.scale)
                        shade = 0.25 + strand * 0.05 + progress * 0.1
                        shade += perlin_noise(x * 0.2, y * 0.1, self.seed + strand) * 0.1

                        for t in range(2):
                            self.canvas.set_pixel(x + side * t, y,
                                                  PALETTES['hair'].get(shade + t * 0.08))

    def _draw_hair_bangs(self) -> None:
        """Draw wispy bangs across forehead."""
        cx = self.cx
        bang_y = self.cy - self.head_h + int(3 * self.scale)

        for i in range(7):
            bang_x = cx - int(18 * self.scale) + i * int(6 * self.scale)
            length = int((8 + random.randint(-2, 4)) * self.scale)

            for y in range(bang_y, bang_y + length):
                wave = math.sin(y * 0.3 + i) * 2
                x = int(bang_x + wave)

                if 0 <= x < self.size and 0 <= y < self.size:
                    progress = (y - bang_y) / length
                    shade = 0.2 + progress * 0.15 + (i % 2) * 0.1
                    self.canvas.set_pixel(x, y, PALETTES['hair'].get(shade))

    def _draw_hair_bun(self) -> None:
        """Draw the hair bun on top."""
        cx = self.cx
        bun_y = self.cy - self.head_h - self.hair_extra_h + int(5 * self.scale)
        bun_rx = int(12 * self.scale)
        bun_ry = int(10 * self.scale)

        for y in range(bun_y - bun_ry, bun_y + bun_ry + 1):
            for x in range(cx - bun_rx, cx + bun_rx + 1):
                if point_in_ellipse(x, y, cx, bun_y, bun_rx, bun_ry):
                    # Spiral texture
                    angle = math.atan2(y - bun_y, x - cx)
                    dist = distance(x, y, cx, bun_y) / bun_rx
                    spiral = (angle + dist * 4) % (math.pi / 2)
                    spiral_shade = 0.08 if spiral < math.pi / 4 else 0

                    # Light from top-left
                    light = (cx - x) / bun_rx * 0.15 + (bun_y - y) / bun_ry * 0.2

                    shade = 0.28 + dist * 0.15 + light + spiral_shade
                    shade = max(0.15, min(0.6, shade))

                    self.canvas.set_pixel(x, y, PALETTES['hair'].get(shade))

        # Bun highlight
        hl_x, hl_y = cx - int(3 * self.scale), bun_y - int(3 * self.scale)
        for dy in range(-2, 3):
            for dx in range(-2, 3):
                if abs(dx) + abs(dy) <= 2:
                    alpha_factor = 1 - (abs(dx) + abs(dy)) / 3
                    shade = 0.05 + (1 - alpha_factor) * 0.15
                    self.canvas.set_pixel(hl_x + dx, hl_y + dy, PALETTES['hair'].get(shade))

    def _add_highlights(self) -> None:
        """Add final sparkle highlights."""
        cx, cy = self.cx, self.cy

        # Hair shine spots
        shines = [
            (cx - int(8 * self.scale), cy - self.head_h + int(8 * self.scale)),
            (cx + int(5 * self.scale), cy - self.head_h + int(5 * self.scale)),
            (cx - int(3 * self.scale), cy - self.head_h),
        ]

        for sx, sy in shines:
            for dy in range(-1, 2):
                for dx in range(-1, 2):
                    if abs(dx) + abs(dy) <= 1:
                        alpha = 200 if dx == 0 and dy == 0 else 100
                        self.canvas.set_pixel(sx + dx, sy + dy, (255, 240, 255, alpha))

    def save(self, filepath: str) -> None:
        """Save the portrait to file."""
        if self.canvas:
            self.canvas.save(filepath)


# ============================================================================
# MAIN
# ============================================================================

if __name__ == "__main__":
    import os

    output_dir = os.path.dirname(os.path.abspath(__file__))

    print("=== Lyra Portrait Generator V2 ===")
    print("Generating with improved anime-style proportions...\n")

    # Main portrait
    print("Generating neutral expression (128px)...")
    gen = LyraPortraitV2(size=128, seed=42)
    canvas = gen.generate('neutral')
    canvas.save(os.path.join(output_dir, 'lyra_v2_neutral_128.png'))
    print("  Saved: lyra_v2_neutral_128.png")

    # Expression variants
    for expr in ['encouraging', 'thinking', 'surprised', 'concerned']:
        print(f"Generating {expr} expression...")
        gen = LyraPortraitV2(size=128, seed=42)
        canvas = gen.generate(expr)
        canvas.save(os.path.join(output_dir, f'lyra_v2_{expr}_128.png'))
        print(f"  Saved: lyra_v2_{expr}_128.png")

    # High-res version
    print("Generating high-res (256px)...")
    gen = LyraPortraitV2(size=256, seed=42)
    canvas = gen.generate('neutral')
    canvas.save(os.path.join(output_dir, 'lyra_v2_neutral_256.png'))
    print("  Saved: lyra_v2_neutral_256.png")

    print("\nAll portraits generated!")
