#!/usr/bin/env python3
"""
High-Resolution Pixel Art Portrait Generator for Lyra
Generates 128x128+ portraits matching the HighRes.png reference style.

Features:
- Multi-shade color ramps with hue shifting
- Layered rendering (background, body, face, hair, details)
- Procedural noise for organic textures
- Soft anti-aliased pixel clusters
"""

import math
import random
from typing import List, Tuple, Dict, Optional, Callable
from png_writer import Canvas, hex_to_rgba, lerp_color, blend_colors, Color


# ============================================================================
# COLOR PALETTES - Full ramps with hue shifting
# ============================================================================

class ColorRamp:
    """A color ramp with multiple shades from highlight to deep shadow."""

    def __init__(self, colors: List[str]):
        """Initialize with hex color strings from lightest to darkest."""
        self.colors = [hex_to_rgba(c) for c in colors]

    def get(self, t: float) -> Color:
        """Get color at position t (0=lightest, 1=darkest)."""
        t = max(0.0, min(1.0, t))
        if len(self.colors) == 1:
            return self.colors[0]

        # Find which two colors to interpolate between
        idx = t * (len(self.colors) - 1)
        i = int(idx)
        frac = idx - i

        if i >= len(self.colors) - 1:
            return self.colors[-1]

        return lerp_color(self.colors[i], self.colors[i + 1], frac)


# Lyra's color palette based on HighRes.png reference
PALETTES = {
    # Hair: Lavender/purple with pink highlights
    'hair': ColorRamp([
        '#e8d4f0',  # Brightest highlight (pink-white)
        '#d4b8e8',  # Light highlight
        '#b490d0',  # Light
        '#9670b8',  # Mid-light
        '#7850a0',  # Base
        '#5c3d7a',  # Mid-shadow
        '#402860',  # Shadow
        '#2a1845',  # Deep shadow
    ]),

    # Skin: Warm peachy tones
    'skin': ColorRamp([
        '#fff0e0',  # Highlight (warm white)
        '#ffe4d0',  # Light highlight
        '#f5d4b8',  # Light
        '#e8c0a0',  # Mid-light
        '#d4a888',  # Base
        '#b88868',  # Mid-shadow
        '#906848',  # Shadow
        '#684830',  # Deep shadow
    ]),

    # Robe: Deep blue with slight purple tint
    'robe': ColorRamp([
        '#7090c0',  # Highlight (lighter blue)
        '#5878a8',  # Light
        '#406090',  # Mid-light
        '#304878',  # Base
        '#203460',  # Mid-shadow
        '#182448',  # Shadow
        '#101830',  # Deep shadow
        '#080c18',  # Darkest
    ]),

    # Glasses frames: Warm brown/amber
    'glasses': ColorRamp([
        '#d0a878',  # Highlight
        '#b08858',  # Light
        '#907040',  # Base
        '#705830',  # Shadow
        '#504020',  # Deep shadow
    ]),

    # Book: Warm brown leather
    'book': ColorRamp([
        '#c8a070',  # Highlight
        '#a88050',  # Light
        '#886438',  # Base
        '#684820',  # Shadow
        '#483010',  # Deep shadow
    ]),

    # Book pages: Cream/off-white
    'pages': ColorRamp([
        '#fff8f0',  # Highlight
        '#f0e8d8',  # Light
        '#e0d8c8',  # Base
        '#c8c0b0',  # Shadow
    ]),

    # Gold accents
    'gold': ColorRamp([
        '#fff0a0',  # Bright highlight
        '#ffd860',  # Highlight
        '#e8c040',  # Light
        '#c8a030',  # Base
        '#a08020',  # Shadow
        '#786010',  # Deep shadow
    ]),

    # Background: Deep navy
    'background': ColorRamp([
        '#1a1a2e',  # Base
        '#141424',  # Darker
        '#0e0e1a',  # Darkest
    ]),

    # Eyes
    'eye_white': ColorRamp([
        '#ffffff',
        '#f0f0f8',
        '#d8d8e0',
        '#b0b0c0',
    ]),

    'eye_iris': ColorRamp([
        '#6080a0',  # Light
        '#405070',  # Base
        '#283848',  # Dark
        '#182028',  # Darkest
    ]),
}


# ============================================================================
# NOISE AND TEXTURE FUNCTIONS
# ============================================================================

def simple_noise(x: float, y: float, seed: int = 0) -> float:
    """Simple pseudo-random noise function."""
    n = int(x * 73 + y * 179 + seed * 31)
    n = (n << 13) ^ n
    return 1.0 - ((n * (n * n * 15731 + 789221) + 1376312589) & 0x7fffffff) / 1073741824.0


def smoothstep(t: float) -> float:
    """Smooth interpolation function."""
    t = max(0.0, min(1.0, t))
    return t * t * (3 - 2 * t)


def perlin_noise(x: float, y: float, scale: float = 1.0, seed: int = 0) -> float:
    """Simple Perlin-like noise."""
    x = x * scale
    y = y * scale

    x0 = int(math.floor(x))
    y0 = int(math.floor(y))

    fx = x - x0
    fy = y - y0

    # Get corner values
    v00 = simple_noise(x0, y0, seed)
    v10 = simple_noise(x0 + 1, y0, seed)
    v01 = simple_noise(x0, y0 + 1, seed)
    v11 = simple_noise(x0 + 1, y0 + 1, seed)

    # Smooth interpolation
    fx = smoothstep(fx)
    fy = smoothstep(fy)

    # Bilinear interpolation
    v0 = v00 + (v10 - v00) * fx
    v1 = v01 + (v11 - v01) * fx

    return v0 + (v1 - v0) * fy


def fractal_noise(x: float, y: float, octaves: int = 4, persistence: float = 0.5, seed: int = 0) -> float:
    """Multi-octave fractal noise for more natural textures."""
    total = 0.0
    amplitude = 1.0
    frequency = 1.0
    max_value = 0.0

    for _ in range(octaves):
        total += perlin_noise(x * frequency, y * frequency, 1.0, seed) * amplitude
        max_value += amplitude
        amplitude *= persistence
        frequency *= 2.0

    return total / max_value


# ============================================================================
# SHAPE AND DRAWING UTILITIES
# ============================================================================

def distance(x1: float, y1: float, x2: float, y2: float) -> float:
    """Euclidean distance between two points."""
    return math.sqrt((x2 - x1) ** 2 + (y2 - y1) ** 2)


def point_in_ellipse(px: float, py: float, cx: float, cy: float, rx: float, ry: float) -> bool:
    """Check if point is inside an ellipse."""
    if rx <= 0 or ry <= 0:
        return False
    dx = (px - cx) / rx
    dy = (py - cy) / ry
    return dx * dx + dy * dy <= 1.0


def ellipse_distance(px: float, py: float, cx: float, cy: float, rx: float, ry: float) -> float:
    """Get normalized distance from center of ellipse (0 at center, 1 at edge)."""
    if rx <= 0 or ry <= 0:
        return float('inf')
    dx = (px - cx) / rx
    dy = (py - cy) / ry
    return math.sqrt(dx * dx + dy * dy)


# ============================================================================
# PORTRAIT GENERATOR
# ============================================================================

class LyraPortraitGenerator:
    """Generates high-resolution pixel art portraits of Lyra."""

    def __init__(self, size: int = 128, seed: int = None):
        self.size = size
        self.seed = seed if seed is not None else random.randint(0, 10000)
        self.canvas = None

        # Character positioning (relative to size)
        self.center_x = size // 2
        self.center_y = int(size * 0.45)  # Slightly above center

        # Feature sizes (relative to canvas size)
        scale = size / 128.0
        self.head_rx = int(28 * scale)
        self.head_ry = int(32 * scale)
        self.eye_size = int(6 * scale)
        self.hair_extra = int(12 * scale)

    def generate(self, expression: str = 'neutral') -> Canvas:
        """Generate a complete portrait with the given expression."""
        self.canvas = Canvas(self.size, self.size, PALETTES['background'].get(0))

        # Render in layers (back to front)
        self._draw_background()
        self._draw_hair_back()
        self._draw_body_and_robe()
        self._draw_book()
        self._draw_neck()
        self._draw_face()
        self._draw_eyes(expression)
        self._draw_eyebrows(expression)
        self._draw_nose()
        self._draw_mouth(expression)
        self._draw_glasses()
        self._draw_hair_front()
        self._draw_hair_bun()
        self._draw_highlights()

        return self.canvas

    def _draw_background(self) -> None:
        """Draw the dark navy background with subtle gradient."""
        for y in range(self.size):
            for x in range(self.size):
                # Slight radial darkening toward edges
                dist = distance(x, y, self.center_x, self.center_y)
                max_dist = self.size * 0.7
                t = min(1.0, dist / max_dist) * 0.3
                color = PALETTES['background'].get(t)
                self.canvas.set_pixel(x, y, color)

    def _draw_hair_back(self) -> None:
        """Draw the back layer of hair."""
        cx, cy = self.center_x, self.center_y
        rx, ry = self.head_rx + self.hair_extra, self.head_ry + self.hair_extra // 2

        for y in range(self.size):
            for x in range(self.size):
                # Hair shape: wider at top, narrows toward shoulders
                local_rx = rx
                if y > cy:
                    # Narrow toward bottom
                    narrowing = (y - cy) / (self.size - cy)
                    local_rx = rx * (1 - narrowing * 0.4)

                if point_in_ellipse(x, y, cx, cy - 5, local_rx, ry):
                    # Skip face area
                    if point_in_ellipse(x, y, cx, cy + 5, self.head_rx - 5, self.head_ry - 8):
                        continue

                    # Calculate shading based on position
                    dist = ellipse_distance(x, y, cx, cy - 5, local_rx, ry)

                    # Light from top-left
                    light_x = -0.5
                    light_y = -0.7
                    light_factor = ((x - cx) / local_rx * light_x + (y - cy) / ry * light_y)
                    light_factor = (light_factor + 1) / 2  # Normalize to 0-1

                    # Add noise for hair texture
                    noise = fractal_noise(x * 0.1, y * 0.15, 3, 0.5, self.seed)

                    # Combine factors
                    shade = 0.3 + light_factor * 0.4 + noise * 0.15
                    shade = max(0.2, min(0.85, shade))

                    color = PALETTES['hair'].get(shade)
                    self.canvas.set_pixel(x, y, color)

    def _draw_body_and_robe(self) -> None:
        """Draw shoulders and robe."""
        cx = self.center_x
        shoulder_y = self.center_y + self.head_ry - 5

        for y in range(shoulder_y, self.size):
            for x in range(self.size):
                # Shoulder/body shape
                progress = (y - shoulder_y) / (self.size - shoulder_y)
                width = int(self.head_rx * (1 + progress * 1.5))

                if abs(x - cx) <= width:
                    # Shading
                    light_factor = (cx - x) / width * 0.5 + 0.5
                    noise = fractal_noise(x * 0.08, y * 0.08, 2, 0.5, self.seed + 100)

                    shade = 0.25 + light_factor * 0.35 + noise * 0.1

                    # Add fold lines
                    fold_noise = perlin_noise(x * 0.15, y * 0.05, 1.0, self.seed + 200)
                    if fold_noise > 0.6:
                        shade += 0.15
                    elif fold_noise < -0.5:
                        shade -= 0.1

                    shade = max(0.15, min(0.75, shade))
                    color = PALETTES['robe'].get(shade)
                    self.canvas.set_pixel(x, y, color)

        # Gold trim at neckline
        self._draw_gold_trim(shoulder_y)

    def _draw_gold_trim(self, shoulder_y: int) -> None:
        """Draw gold trim on the robe."""
        cx = self.center_x
        trim_width = 3

        for y in range(shoulder_y, shoulder_y + 15):
            progress = (y - shoulder_y) / 15
            # V-neck shape
            neck_width = int(8 + progress * 12)

            for offset in range(-trim_width, trim_width + 1):
                x_left = cx - neck_width + offset
                x_right = cx + neck_width + offset

                shade = 0.3 + abs(offset) / trim_width * 0.3
                if offset < 0:
                    shade += 0.1

                color = PALETTES['gold'].get(shade)
                self.canvas.set_pixel(x_left, y, color)
                self.canvas.set_pixel(x_right, y, color)

    def _draw_book(self) -> None:
        """Draw the book Lyra is holding."""
        cx = self.center_x
        book_y = self.center_y + self.head_ry + 20
        book_w = int(self.head_rx * 1.2)
        book_h = int(self.head_ry * 0.5)

        # Book cover
        for y in range(book_y, book_y + book_h):
            for x in range(cx - book_w, cx + book_w):
                if 0 <= x < self.size and 0 <= y < self.size:
                    # Perspective: slightly angled
                    local_y = y - book_y
                    angle_offset = int((local_y / book_h) * 5)

                    if abs(x - cx) <= book_w - angle_offset:
                        # Shading
                        shade = 0.3 + (cx - x) / book_w * 0.2
                        shade += (book_y + book_h - y) / book_h * 0.2
                        shade = max(0.2, min(0.7, shade))

                        color = PALETTES['book'].get(shade)
                        self.canvas.set_pixel(x, y, color)

        # Book pages (lighter area in middle)
        page_margin = 4
        for y in range(book_y + page_margin, book_y + book_h - page_margin):
            for x in range(cx - book_w + page_margin + 3, cx + book_w - page_margin - 3):
                if 0 <= x < self.size and 0 <= y < self.size:
                    shade = 0.1 + (y - book_y) / book_h * 0.3
                    color = PALETTES['pages'].get(shade)
                    self.canvas.set_pixel(x, y, color)

        # Text lines suggestion
        for line in range(3):
            line_y = book_y + page_margin + 4 + line * 5
            line_start = cx - book_w + page_margin + 8
            line_end = cx + book_w - page_margin - 8 - random.randint(0, 15)
            for x in range(line_start, line_end):
                if random.random() > 0.2:  # Dashed effect
                    self.canvas.set_pixel(x, line_y, PALETTES['book'].get(0.5))

    def _draw_neck(self) -> None:
        """Draw the neck."""
        cx = self.center_x
        neck_top = self.center_y + self.head_ry - 12
        neck_bottom = self.center_y + self.head_ry + 5
        neck_width = int(self.head_rx * 0.35)

        for y in range(neck_top, neck_bottom):
            for x in range(cx - neck_width, cx + neck_width):
                if 0 <= x < self.size and 0 <= y < self.size:
                    # Shading
                    shade = 0.3 + (cx - x) / neck_width * 0.15
                    shade = max(0.25, min(0.5, shade))
                    color = PALETTES['skin'].get(shade)
                    self.canvas.set_pixel(x, y, color)

    def _draw_face(self) -> None:
        """Draw the face base."""
        cx, cy = self.center_x, self.center_y
        rx, ry = self.head_rx - 3, self.head_ry - 3

        for y in range(self.size):
            for x in range(self.size):
                if point_in_ellipse(x, y, cx, cy + 3, rx, ry):
                    # Calculate shading
                    dist = ellipse_distance(x, y, cx, cy + 3, rx, ry)

                    # Light from top-left
                    light_x = (cx - x) / rx
                    light_y = (cy - y) / ry
                    light_factor = light_x * 0.3 + light_y * 0.4 + 0.5

                    # Subtle variation
                    noise = perlin_noise(x * 0.1, y * 0.1, 1.0, self.seed + 300) * 0.05

                    shade = 0.2 + light_factor * 0.25 + dist * 0.15 + noise
                    shade = max(0.15, min(0.55, shade))

                    color = PALETTES['skin'].get(shade)
                    self.canvas.set_pixel(x, y, color)

        # Cheek blush (subtle)
        self._draw_cheek_blush()

    def _draw_cheek_blush(self) -> None:
        """Add subtle rosy cheeks."""
        cx = self.center_x
        cy = self.center_y
        cheek_y = cy + 8
        cheek_offset = int(self.head_rx * 0.5)
        cheek_r = int(self.head_rx * 0.25)

        blush_color = (220, 160, 140, 40)  # Very subtle pink

        for offset in [-cheek_offset, cheek_offset]:
            cheek_x = cx + offset
            for y in range(cheek_y - cheek_r, cheek_y + cheek_r):
                for x in range(cheek_x - cheek_r, cheek_x + cheek_r):
                    if 0 <= x < self.size and 0 <= y < self.size:
                        dist = distance(x, y, cheek_x, cheek_y)
                        if dist < cheek_r:
                            alpha = int(40 * (1 - dist / cheek_r))
                            color = (220, 160, 140, alpha)
                            self.canvas.set_pixel(x, y, color)

    def _draw_eyes(self, expression: str) -> None:
        """Draw the eyes."""
        cx = self.center_x
        cy = self.center_y
        eye_y = cy - 2
        eye_offset = int(self.head_rx * 0.35)
        eye_rx = self.eye_size
        eye_ry = int(self.eye_size * 0.8)

        # Adjust for expression
        if expression == 'surprised':
            eye_ry = int(self.eye_size * 1.0)
        elif expression == 'thinking':
            eye_ry = int(self.eye_size * 0.6)

        for side in [-1, 1]:
            ex = cx + side * eye_offset

            # Eye white
            for y in range(eye_y - eye_ry, eye_y + eye_ry + 1):
                for x in range(ex - eye_rx, ex + eye_rx + 1):
                    if point_in_ellipse(x, y, ex, eye_y, eye_rx, eye_ry):
                        dist = ellipse_distance(x, y, ex, eye_y, eye_rx, eye_ry)
                        shade = dist * 0.4
                        color = PALETTES['eye_white'].get(shade)
                        self.canvas.set_pixel(x, y, color)

            # Iris
            iris_x = ex + side * 1  # Slight offset toward center
            iris_r = int(eye_rx * 0.6)
            for y in range(eye_y - iris_r, eye_y + iris_r + 1):
                for x in range(iris_x - iris_r, iris_x + iris_r + 1):
                    if point_in_ellipse(x, y, iris_x, eye_y, iris_r, iris_r):
                        dist = ellipse_distance(x, y, iris_x, eye_y, iris_r, iris_r)
                        shade = 0.2 + dist * 0.5
                        color = PALETTES['eye_iris'].get(shade)
                        self.canvas.set_pixel(x, y, color)

            # Pupil
            pupil_r = int(iris_r * 0.5)
            for y in range(eye_y - pupil_r, eye_y + pupil_r + 1):
                for x in range(iris_x - pupil_r, iris_x + pupil_r + 1):
                    if point_in_ellipse(x, y, iris_x, eye_y, pupil_r, pupil_r):
                        self.canvas.set_pixel(x, y, (20, 15, 25, 255))

            # Catchlight (white reflection)
            highlight_x = iris_x - 2
            highlight_y = eye_y - 2
            self.canvas.set_pixel(highlight_x, highlight_y, (255, 255, 255, 255))
            self.canvas.set_pixel(highlight_x + 1, highlight_y, (255, 255, 255, 200))
            self.canvas.set_pixel(highlight_x, highlight_y + 1, (255, 255, 255, 150))

            # Upper eyelid shadow
            for x in range(ex - eye_rx - 1, ex + eye_rx + 2):
                self.canvas.set_pixel(x, eye_y - eye_ry - 1, PALETTES['skin'].get(0.55))
                self.canvas.set_pixel(x, eye_y - eye_ry, PALETTES['skin'].get(0.45))

    def _draw_eyebrows(self, expression: str) -> None:
        """Draw eyebrows based on expression."""
        cx = self.center_x
        cy = self.center_y
        brow_y = cy - self.eye_size - 6
        brow_offset = int(self.head_rx * 0.35)
        brow_length = int(self.eye_size * 1.8)

        # Adjust position based on expression
        if expression == 'surprised':
            brow_y -= 3
        elif expression == 'concerned':
            brow_y += 1

        for side in [-1, 1]:
            start_x = cx + side * (brow_offset - brow_length // 2)

            for i in range(brow_length):
                x = start_x + side * i

                # Brow curve
                progress = i / brow_length
                if expression == 'concerned':
                    y_offset = int(progress * 3 * side)  # Furrowed
                elif expression == 'surprised':
                    y_offset = int(math.sin(progress * math.pi) * -2)  # Arched
                elif expression == 'encouraging':
                    y_offset = int(progress * 2 * side)  # Slightly raised outer
                else:
                    y_offset = int(math.sin(progress * math.pi) * -1)  # Gentle arch

                y = brow_y + y_offset

                # Thickness varies
                thickness = 2 if 0.2 < progress < 0.8 else 1

                for t in range(thickness):
                    shade = 0.7 + t * 0.1
                    self.canvas.set_pixel(x, y + t, PALETTES['hair'].get(shade))

    def _draw_nose(self) -> None:
        """Draw a subtle nose."""
        cx = self.center_x
        cy = self.center_y
        nose_y = cy + 6

        # Nose shadow (very subtle)
        for y in range(nose_y - 2, nose_y + 4):
            shade = 0.4 + (y - nose_y) * 0.02
            # Left shadow
            self.canvas.set_pixel(cx - 1, y, PALETTES['skin'].get(shade))

        # Nose tip highlight
        self.canvas.set_pixel(cx, nose_y + 2, PALETTES['skin'].get(0.2))

        # Nostril hints
        self.canvas.set_pixel(cx - 2, nose_y + 3, PALETTES['skin'].get(0.5))
        self.canvas.set_pixel(cx + 2, nose_y + 3, PALETTES['skin'].get(0.45))

    def _draw_mouth(self, expression: str) -> None:
        """Draw the mouth based on expression."""
        cx = self.center_x
        cy = self.center_y
        mouth_y = cy + 14
        mouth_width = int(self.head_rx * 0.4)

        # Mouth line
        if expression in ['neutral', 'thinking']:
            # Gentle smile
            for i in range(-mouth_width, mouth_width + 1):
                x = cx + i
                curve = int(abs(i) * abs(i) / (mouth_width * 2))
                y = mouth_y + curve
                self.canvas.set_pixel(x, y, PALETTES['skin'].get(0.55))

        elif expression == 'encouraging':
            # Bigger smile
            for i in range(-mouth_width - 2, mouth_width + 3):
                x = cx + i
                curve = int(abs(i) * abs(i) / (mouth_width * 1.5))
                y = mouth_y + curve
                self.canvas.set_pixel(x, y, PALETTES['skin'].get(0.55))
            # Smile corners
            self.canvas.set_pixel(cx - mouth_width - 2, mouth_y, PALETTES['skin'].get(0.5))
            self.canvas.set_pixel(cx + mouth_width + 2, mouth_y, PALETTES['skin'].get(0.5))

        elif expression == 'surprised':
            # Open mouth - small O
            for angle in range(0, 360, 15):
                rad = math.radians(angle)
                x = int(cx + math.cos(rad) * 4)
                y = int(mouth_y + 2 + math.sin(rad) * 3)
                self.canvas.set_pixel(x, y, PALETTES['skin'].get(0.6))

        elif expression == 'concerned':
            # Slight frown
            for i in range(-mouth_width, mouth_width + 1):
                x = cx + i
                curve = -int(abs(i) * abs(i) / (mouth_width * 3))
                y = mouth_y + 1 + curve
                self.canvas.set_pixel(x, y, PALETTES['skin'].get(0.55))

        # Lower lip highlight
        self.canvas.set_pixel(cx, mouth_y + 2, PALETTES['skin'].get(0.25))
        self.canvas.set_pixel(cx - 1, mouth_y + 2, PALETTES['skin'].get(0.28))
        self.canvas.set_pixel(cx + 1, mouth_y + 2, PALETTES['skin'].get(0.28))

    def _draw_glasses(self) -> None:
        """Draw round glasses frames."""
        cx = self.center_x
        cy = self.center_y
        eye_y = cy - 2
        eye_offset = int(self.head_rx * 0.35)
        lens_r = self.eye_size + 3

        for side in [-1, 1]:
            lens_x = cx + side * eye_offset

            # Lens frame (circle outline)
            for angle in range(0, 360, 3):
                rad = math.radians(angle)
                for thickness in range(2):
                    r = lens_r + thickness
                    x = int(lens_x + math.cos(rad) * r)
                    y = int(eye_y + math.sin(rad) * r)

                    # Frame shading (lighter on top)
                    shade = 0.2 + (1 - math.sin(rad)) * 0.3
                    if thickness == 1:
                        shade += 0.15

                    self.canvas.set_pixel(x, y, PALETTES['glasses'].get(shade))

            # Lens reflection (subtle)
            for y in range(eye_y - lens_r + 2, eye_y - lens_r + 5):
                for x in range(lens_x - 3, lens_x + 1):
                    if point_in_ellipse(x, y, lens_x, eye_y, lens_r - 1, lens_r - 1):
                        self.canvas.set_pixel(x, y, (255, 255, 255, 20))

        # Bridge between lenses
        bridge_y = eye_y - 1
        for x in range(cx - 3, cx + 4):
            self.canvas.set_pixel(x, bridge_y, PALETTES['glasses'].get(0.35))
            self.canvas.set_pixel(x, bridge_y + 1, PALETTES['glasses'].get(0.45))

        # Temple arms going to sides
        for side in [-1, 1]:
            start_x = cx + side * (eye_offset + lens_r + 1)
            for i in range(10):
                x = start_x + side * i
                y = eye_y + i // 3
                if 0 <= x < self.size:
                    self.canvas.set_pixel(x, y, PALETTES['glasses'].get(0.4))

    def _draw_hair_front(self) -> None:
        """Draw front hair pieces that overlap the face."""
        cx = self.center_x
        cy = self.center_y

        # Side hair strands
        for side in [-1, 1]:
            base_x = cx + side * (self.head_rx - 5)

            for strand in range(3):
                strand_x = base_x + side * strand * 3
                start_y = cy - self.head_ry + 10

                for y in range(start_y, start_y + 25):
                    # Wavy pattern
                    wave = math.sin((y - start_y) * 0.3 + strand) * 3
                    x = int(strand_x + wave)

                    if 0 <= x < self.size and 0 <= y < self.size:
                        # Strand shading
                        noise = perlin_noise(x * 0.2, y * 0.2, 1.0, self.seed + strand)
                        shade = 0.3 + noise * 0.2 + (strand / 3) * 0.1

                        for thickness in range(2):
                            self.canvas.set_pixel(x + side * thickness, y,
                                                  PALETTES['hair'].get(shade + thickness * 0.1))

        # Forehead bangs/fringe (wispy pieces)
        for i in range(5):
            x = cx - 15 + i * 7
            for y in range(cy - self.head_ry + 5, cy - self.head_ry + 15):
                wave = math.sin(y * 0.4 + i) * 2
                px = int(x + wave)
                if 0 <= px < self.size:
                    shade = 0.25 + (i % 2) * 0.15
                    self.canvas.set_pixel(px, y, PALETTES['hair'].get(shade))

    def _draw_hair_bun(self) -> None:
        """Draw the hair bun on top."""
        cx = self.center_x
        bun_y = self.center_y - self.head_ry - 8
        bun_r = int(self.head_rx * 0.4)

        for y in range(bun_y - bun_r, bun_y + bun_r + 1):
            for x in range(cx - bun_r, cx + bun_r + 1):
                if point_in_ellipse(x, y, cx, bun_y, bun_r, int(bun_r * 0.8)):
                    dist = ellipse_distance(x, y, cx, bun_y, bun_r, int(bun_r * 0.8))

                    # Spiral pattern for bun texture
                    angle = math.atan2(y - bun_y, x - cx)
                    spiral = (angle + dist * 3) % (math.pi / 2)
                    spiral_shade = 0.1 if spiral < math.pi / 4 else 0

                    # Light from top-left
                    light = (cx - x) / bun_r * 0.2 + (bun_y - y) / bun_r * 0.3

                    shade = 0.25 + dist * 0.2 + light + spiral_shade
                    shade = max(0.15, min(0.7, shade))

                    self.canvas.set_pixel(x, y, PALETTES['hair'].get(shade))

        # Bun highlight
        for y in range(bun_y - bun_r // 2, bun_y - bun_r // 2 + 3):
            for x in range(cx - 3, cx + 2):
                if point_in_ellipse(x, y, cx - 1, bun_y - bun_r // 2 + 1, 3, 2):
                    self.canvas.set_pixel(x, y, PALETTES['hair'].get(0.05))

    def _draw_highlights(self) -> None:
        """Add final highlight touches."""
        cx = self.center_x
        cy = self.center_y

        # Hair shine spots
        shine_positions = [
            (cx - 10, cy - self.head_ry + 15),
            (cx + 8, cy - self.head_ry + 12),
            (cx - 5, cy - self.head_ry + 8),
        ]

        for sx, sy in shine_positions:
            for dy in range(-1, 2):
                for dx in range(-1, 2):
                    if abs(dx) + abs(dy) <= 1:
                        alpha = 180 if dx == 0 and dy == 0 else 80
                        self.canvas.set_pixel(sx + dx, sy + dy,
                                              (255, 240, 255, alpha))

        # Rim light on shadow side (right edge of face)
        rim_x = cx + self.head_rx - 5
        for y in range(cy - 10, cy + 15):
            if 0 <= rim_x < self.size and 0 <= y < self.size:
                self.canvas.set_pixel(rim_x, y, PALETTES['skin'].get(0.2))

    def save(self, filepath: str) -> None:
        """Save the generated portrait."""
        if self.canvas:
            self.canvas.save(filepath)


# ============================================================================
# MAIN - Generate portraits
# ============================================================================

if __name__ == "__main__":
    import os

    output_dir = os.path.dirname(os.path.abspath(__file__))

    # Generate main portrait
    print("Generating Lyra portrait (neutral)...")
    generator = LyraPortraitGenerator(size=128, seed=42)
    canvas = generator.generate('neutral')
    canvas.save(os.path.join(output_dir, 'lyra_neutral_128.png'))
    print("  Saved: lyra_neutral_128.png")

    # Generate expression variants
    expressions = ['encouraging', 'thinking', 'surprised', 'concerned']
    for expr in expressions:
        print(f"Generating Lyra portrait ({expr})...")
        generator = LyraPortraitGenerator(size=128, seed=42)
        canvas = generator.generate(expr)
        canvas.save(os.path.join(output_dir, f'lyra_{expr}_128.png'))
        print(f"  Saved: lyra_{expr}_128.png")

    # Generate larger version
    print("Generating high-res version (256px)...")
    generator = LyraPortraitGenerator(size=256, seed=42)
    canvas = generator.generate('neutral')
    canvas.save(os.path.join(output_dir, 'lyra_neutral_256.png'))
    print("  Saved: lyra_neutral_256.png")

    print("\nAll portraits generated successfully!")
