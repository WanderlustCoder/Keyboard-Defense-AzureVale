#!/usr/bin/env python3
"""
Lyra Portrait Generator V4 - Cute & Detailed
Focus on:
- Pixel cluster painting style (not smooth gradients)
- MUCH more hair texture with scattered highlights
- Bumpy organic silhouette
- Higher contrast
- Chibi proportions (big fluffy hair, cute small face)
- Rich warm colors
"""

import math
import random
from typing import List, Tuple
from png_writer import Canvas, hex_to_rgba, lerp_color, Color


class ColorRamp:
    def __init__(self, colors: List[str]):
        self.colors = [hex_to_rgba(c) for c in colors]

    def get(self, t: float) -> Color:
        t = max(0.0, min(1.0, t))
        idx = t * (len(self.colors) - 1)
        i = min(int(idx), len(self.colors) - 2)
        return lerp_color(self.colors[i], self.colors[i + 1], idx - i)

    def sample(self, t: float, variance: float = 0.1) -> Color:
        """Sample with random variance for painterly effect."""
        t = t + (random.random() - 0.5) * variance
        return self.get(t)


# Richer, more saturated colors matching reference
PALETTE = {
    # Hair: More pink in highlights, richer purples
    'hair': ColorRamp([
        '#fff0ff',  # Brightest - almost white pink
        '#f0d0f8',  # Very light pink
        '#e0b8f0',  # Light pink-lavender
        '#d0a0e8',  # Pink lavender
        '#b880d8',  # Light purple
        '#9860c8',  # Mid purple
        '#7840a8',  # Purple
        '#582888',  # Dark purple
        '#401868',  # Darker
        '#280848',  # Very dark
        '#180030',  # Darkest
    ]),

    # Skin: Warmer, more orange (matching reference)
    'skin': ColorRamp([
        '#fff8e8',  # Highlight
        '#ffe8c8',  # Light
        '#ffd0a0',  # Warm light
        '#f0b078',  # Mid - quite orange
        '#e09058',  # Base orange
        '#c07040',  # Shadow
        '#905028',  # Dark shadow
        '#603818',  # Darkest
    ]),

    # Robe: Richer blue with more variation
    'robe': ColorRamp([
        '#90a8d0',  # Highlight
        '#6888b8',  # Light
        '#4868a0',  # Mid-light
        '#385088',  # Mid
        '#284070',  # Base
        '#183058',  # Shadow
        '#102040',  # Dark
        '#081028',  # Darkest
    ]),

    # Glasses: Warm brown/amber
    'glasses': ColorRamp([
        '#e8b880', '#c89858', '#a87838', '#885820', '#684010',
    ]),

    # Book
    'book': ColorRamp([
        '#c8a070', '#a88050', '#886038', '#684020', '#482810',
    ]),

    'pages': ColorRamp([
        '#fff8e8', '#f0e8d8', '#e0d8c0', '#c8c0a8',
    ]),

    # Background: Deep navy
    'bg': ColorRamp([
        '#202040', '#181830', '#101028', '#080818',
    ]),

    'eye_white': ColorRamp(['#ffffff', '#f0f0ff', '#d8d8f0', '#b0b0c8']),
    'eye_iris': ColorRamp(['#6080a0', '#405870', '#283850', '#182838', '#101820']),
}


def dist(x1, y1, x2, y2):
    return math.sqrt((x2-x1)**2 + (y2-y1)**2)


def in_ellipse(px, py, cx, cy, rx, ry):
    if rx <= 0 or ry <= 0: return False
    return ((px-cx)/rx)**2 + ((py-cy)/ry)**2 <= 1.0


def noise(x, y, seed=0):
    """Fast hash-based noise."""
    n = int(x * 374761393 + y * 668265263 + seed * 1013904223)
    n = (n ^ (n >> 13)) * 1274126177
    return (n & 0x7fffffff) / 2147483648.0


def fbm(x, y, oct=4, seed=0):
    """Fractal brownian motion noise."""
    val, amp, freq = 0, 1, 1
    for i in range(oct):
        val += noise(x * freq, y * freq, seed + i * 1000) * amp
        amp *= 0.5
        freq *= 2
    return val / (2 - 2**(1-oct))


class LyraV4:
    def __init__(self, size=128, seed=42):
        self.size = size
        self.seed = seed
        self.s = size / 128
        random.seed(seed)

        # Character center - positioned to leave room for big hair
        self.cx = size // 2
        self.cy = int(size * 0.55)

        # Smaller face relative to hair (more chibi)
        self.face_r = int(16 * self.s)

        # HUGE eyes (chibi style)
        self.eye_r = int(7 * self.s)
        self.eye_sep = int(9 * self.s)

        # Big fluffy hair
        self.hair_r = int(35 * self.s)

    def generate(self, expr='neutral'):
        self.canvas = Canvas(self.size, self.size, PALETTE['bg'].get(0.3))
        self._background()
        self._hair_base()
        self._hair_texture()
        self._body()
        self._neck()
        self._face()
        self._eyes(expr)
        self._nose_mouth(expr)
        self._eyebrows(expr)
        self._glasses()
        self._hair_front()
        self._hair_highlights()
        self._book()
        return self.canvas

    def _background(self):
        """Subtle background variation."""
        for y in range(self.size):
            for x in range(self.size):
                n = fbm(x * 0.02, y * 0.02, 2, self.seed) * 0.15
                self.canvas.pixels[y][x] = PALETTE['bg'].get(0.25 + n)

    def _hair_base(self):
        """Create fluffy hair silhouette with bumpy organic edges."""
        cx, cy = self.cx, self.cy - int(5 * self.s)
        hr = self.hair_r

        # Create bumpy boundary using multiple overlapping circles
        def in_hair(x, y):
            # Main mass
            if dist(x, y, cx, cy - hr*0.2) < hr * 0.9:
                return True

            # Top poof
            if dist(x, y, cx, cy - hr*0.7) < hr * 0.6:
                return True

            # Left bulge
            if dist(x, y, cx - hr*0.5, cy - hr*0.1) < hr * 0.65:
                return True

            # Right bulge
            if dist(x, y, cx + hr*0.5, cy - hr*0.1) < hr * 0.65:
                return True

            # Left lower
            if dist(x, y, cx - hr*0.4, cy + hr*0.4) < hr * 0.5:
                return True

            # Right lower
            if dist(x, y, cx + hr*0.4, cy + hr*0.4) < hr * 0.5:
                return True

            # Add bumpy edge details using noise
            base_dist = dist(x, y, cx, cy - hr*0.2)
            angle = math.atan2(y - (cy - hr*0.2), x - cx)
            bump = math.sin(angle * 8) * hr * 0.08 + math.sin(angle * 13) * hr * 0.05
            if base_dist < hr * 0.95 + bump:
                return True

            return False

        for y in range(self.size):
            for x in range(self.size):
                if not in_hair(x, y):
                    continue

                # Skip face area
                if dist(x, y, self.cx, self.cy + self.face_r * 0.1) < self.face_r * 0.9:
                    continue

                # Base shading with lots of variation
                rel_y = (y - (cy - hr)) / (hr * 2)
                rel_x = (x - cx) / hr

                # Light from top-left
                light = (1 - rel_y) * 0.2 + (0.3 - rel_x) * 0.15

                # Large-scale noise for color variation
                n1 = fbm(x * 0.08, y * 0.05, 3, self.seed) * 0.25

                shade = 0.4 + light + n1
                shade = max(0.25, min(0.7, shade))

                # Add color with slight random variance for painterly feel
                color = PALETTE['hair'].sample(shade, 0.05)
                self.canvas.set_pixel(x, y, color)

    def _hair_texture(self):
        """Add strand-like texture with scattered pixel clusters."""
        cx, cy = self.cx, self.cy - int(5 * self.s)
        hr = self.hair_r

        # Draw many strand clusters
        for _ in range(int(200 * self.s * self.s)):
            # Random position in hair area
            angle = random.random() * math.pi * 2
            r = random.random() ** 0.7 * hr * 0.85
            sx = int(cx + math.cos(angle) * r)
            sy = int(cy - hr * 0.2 + math.sin(angle) * r * 0.8)

            # Skip if in face area
            if dist(sx, sy, self.cx, self.cy + self.face_r * 0.1) < self.face_r:
                continue

            # Strand direction (flowing outward and down)
            strand_angle = angle + math.pi * 0.1 + random.random() * 0.3
            strand_len = int((3 + random.random() * 5) * self.s)

            # Shade based on position
            rel_y = (sy - (cy - hr)) / (hr * 2)
            base_shade = 0.3 + (1 - rel_y) * 0.2 + random.random() * 0.15

            for i in range(strand_len):
                px = int(sx + math.cos(strand_angle) * i)
                py = int(sy + math.sin(strand_angle) * i)

                if 0 <= px < self.size and 0 <= py < self.size:
                    # Vary shade along strand
                    shade = base_shade + (i / strand_len) * 0.1
                    shade += (random.random() - 0.5) * 0.1
                    shade = max(0.2, min(0.75, shade))

                    color = PALETTE['hair'].get(shade)
                    # Blend with existing
                    self.canvas.set_pixel(px, py, color)

    def _body(self):
        """Draw shoulders and robe with texture."""
        cx = self.cx
        top = self.cy + int(self.face_r * 0.7)

        for y in range(top, self.size):
            prog = (y - top) / (self.size - top)
            hw = int(self.face_r * (0.8 + prog * 1.2))

            for x in range(cx - hw, cx + hw + 1):
                if 0 <= x < self.size:
                    rel_x = (x - cx) / hw

                    # Lighting and fold texture
                    light = (1 - rel_x) * 0.1 + (1 - prog) * 0.15
                    fold = fbm(x * 0.1, y * 0.05, 2, self.seed + 100)
                    fold_v = 0.1 if fold > 0.6 else (-0.08 if fold < 0.35 else 0)

                    shade = 0.35 + light + fold_v
                    color = PALETTE['robe'].sample(max(0.2, min(0.65, shade)), 0.03)
                    self.canvas.set_pixel(x, y, color)

    def _neck(self):
        cx, cy = self.cx, self.cy
        nt = cy + int(self.face_r * 0.6)
        nb = cy + int(self.face_r * 0.9)
        nw = int(self.face_r * 0.3)

        for y in range(nt, nb):
            for x in range(cx - nw, cx + nw):
                if 0 <= x < self.size:
                    rel_x = (x - cx) / nw
                    shade = 0.35 + (1 - abs(rel_x)) * 0.1
                    self.canvas.set_pixel(x, y, PALETTE['skin'].get(shade))

    def _face(self):
        """Draw cute round face."""
        cx = self.cx
        cy = self.cy + int(self.face_r * 0.15)
        fr = self.face_r

        for y in range(self.size):
            for x in range(self.size):
                d = dist(x, y, cx, cy)
                if d < fr:
                    # Normalized distance from center
                    nd = d / fr

                    # Lighting - top-left
                    lx = (cx - x) / fr
                    ly = (cy - y) / fr
                    light = lx * 0.1 + ly * 0.15 + 0.5

                    # Subtle variation
                    n = fbm(x * 0.1, y * 0.1, 2, self.seed + 200) * 0.05

                    shade = 0.25 + light * 0.2 + nd * 0.1 + n
                    shade = max(0.18, min(0.5, shade))

                    self.canvas.set_pixel(x, y, PALETTE['skin'].sample(shade, 0.02))

        # Cheek blush - important for cuteness!
        for side in [-1, 1]:
            chx = cx + side * int(fr * 0.45)
            chy = cy + int(fr * 0.3)
            chr = int(fr * 0.2)

            for y in range(chy - chr, chy + chr + 1):
                for x in range(chx - chr, chx + chr + 1):
                    d = dist(x, y, chx, chy)
                    if d < chr:
                        # Rosy pink blush
                        alpha = int(50 * (1 - d/chr) ** 1.5)
                        self.canvas.set_pixel(x, y, (255, 140, 130, alpha))

    def _eyes(self, expr):
        """Draw BIG cute anime eyes."""
        cx, cy = self.cx, self.cy
        ey = cy - int(self.face_r * 0.05)
        er = self.eye_r

        # Expression adjustments
        er_h = er
        if expr == 'surprised':
            er_h = int(er * 1.2)
        elif expr == 'thinking':
            er_h = int(er * 0.75)

        for side in [-1, 1]:
            ex = cx + side * self.eye_sep

            # Eye white - slightly taller than wide
            for y in range(ey - er_h, ey + er_h + 1):
                for x in range(ex - er, ex + er + 1):
                    if in_ellipse(x, y, ex, ey, er, er_h):
                        d = dist(x, y, ex, ey) / max(er, er_h)
                        self.canvas.set_pixel(x, y, PALETTE['eye_white'].get(d * 0.3))

            # Large iris
            ir = int(er * 0.75)
            ix = ex + side * int(1 * self.s)

            for y in range(ey - ir, ey + ir + 1):
                for x in range(ix - ir, ix + ir + 1):
                    if in_ellipse(x, y, ix, ey, ir, ir):
                        d = dist(x, y, ix, ey) / ir

                        # Gradient from light at top to dark at bottom
                        vert = (y - (ey - ir)) / (ir * 2)
                        shade = 0.1 + d * 0.3 + vert * 0.35

                        self.canvas.set_pixel(x, y, PALETTE['eye_iris'].get(shade))

            # Pupil
            pr = int(ir * 0.4)
            for y in range(ey - pr, ey + pr + 1):
                for x in range(ix - pr, ix + pr + 1):
                    if in_ellipse(x, y, ix, ey, pr, pr):
                        self.canvas.set_pixel(x, y, (10, 5, 15, 255))

            # IMPORTANT: Big bright catchlights for life/cuteness
            # Main catchlight (upper left)
            hx = ix - int(2 * self.s)
            hy = ey - int(2 * self.s)
            for dy in range(-1, 2):
                for dx in range(-1, 2):
                    if abs(dx) + abs(dy) <= 1:
                        a = 255 if dx == 0 and dy == 0 else 200
                        self.canvas.set_pixel(hx + dx, hy + dy, (255, 255, 255, a))

            # Secondary catchlight (lower right)
            hx2 = ix + int(1 * self.s)
            hy2 = ey + int(2 * self.s)
            self.canvas.set_pixel(hx2, hy2, (255, 255, 255, 180))
            self.canvas.set_pixel(hx2 + 1, hy2, (255, 255, 255, 100))

            # Upper eyelid line
            for x in range(ex - er - 1, ex + er + 2):
                for t in range(2):
                    self.canvas.set_pixel(x, ey - er_h - t, PALETTE['skin'].get(0.5 + t * 0.05))

    def _nose_mouth(self, expr):
        """Draw cute small nose and mouth."""
        cx, cy = self.cx, self.cy
        fr = self.face_r

        # Tiny nose - just a hint
        ny = cy + int(fr * 0.25)
        self.canvas.set_pixel(cx, ny, PALETTE['skin'].get(0.4))
        self.canvas.set_pixel(cx - 1, ny + 1, PALETTE['skin'].get(0.42))
        self.canvas.set_pixel(cx + 1, ny + 1, PALETTE['skin'].get(0.38))

        # Mouth
        my = cy + int(fr * 0.5)
        mw = int(fr * 0.3)

        if expr in ['neutral', 'thinking']:
            # Gentle smile curve
            for i in range(-mw, mw + 1):
                curve = int((i * i) / (mw * 1.5))
                self.canvas.set_pixel(cx + i, my + curve, PALETTE['skin'].get(0.5))
        elif expr == 'encouraging':
            # Bigger smile
            mw = int(mw * 1.3)
            for i in range(-mw, mw + 1):
                curve = int((i * i) / (mw * 1.2))
                self.canvas.set_pixel(cx + i, my + curve, PALETTE['skin'].get(0.5))
            # Happy corners
            self.canvas.set_pixel(cx - mw - 1, my, PALETTE['skin'].get(0.45))
            self.canvas.set_pixel(cx + mw + 1, my, PALETTE['skin'].get(0.45))
        elif expr == 'surprised':
            # Small O
            for a in range(0, 360, 30):
                r = math.radians(a)
                px = int(cx + math.cos(r) * 2 * self.s)
                py = int(my + 1 + math.sin(r) * 1.5 * self.s)
                self.canvas.set_pixel(px, py, PALETTE['skin'].get(0.55))
        elif expr == 'concerned':
            # Slight frown
            for i in range(-mw, mw + 1):
                curve = -int((i * i) / (mw * 2.5)) + 1
                self.canvas.set_pixel(cx + i, my + curve, PALETTE['skin'].get(0.5))

    def _eyebrows(self, expr):
        """Draw expressive eyebrows."""
        cx, cy = self.cx, self.cy
        by = cy - self.eye_r - int(5 * self.s)
        bl = int(7 * self.s)

        y_off = 0
        if expr == 'surprised':
            y_off = -2
        elif expr == 'concerned':
            y_off = 1

        for side in [-1, 1]:
            bx = cx + side * self.eye_sep

            for i in range(bl):
                prog = i / bl
                x = bx - side * (bl // 2) + side * i

                # Curve based on expression
                if expr == 'concerned':
                    yc = int(prog * 2.5) * side
                elif expr == 'surprised':
                    yc = int(math.sin(prog * math.pi) * -3)
                else:
                    yc = int(math.sin(prog * math.pi) * -1.5)

                y = by + y_off + yc

                # Thickness varies
                thick = 2 if 0.2 < prog < 0.8 else 1
                for t in range(thick):
                    self.canvas.set_pixel(x, y + t, PALETTE['hair'].get(0.65 + t * 0.08))

    def _glasses(self):
        """Draw cute round glasses."""
        cx, cy = self.cx, self.cy
        ey = cy - int(self.face_r * 0.05)
        lr = self.eye_r + int(2 * self.s)

        for side in [-1, 1]:
            lx = cx + side * self.eye_sep

            # Frame
            for a in range(0, 360, 4):
                r = math.radians(a)
                for t in range(2):
                    px = int(lx + math.cos(r) * (lr + t))
                    py = int(ey + math.sin(r) * (lr + t))

                    # Lighter on top
                    shade = 0.15 + (1 - math.sin(r)) * 0.25 + t * 0.1
                    if 0 <= px < self.size and 0 <= py < self.size:
                        self.canvas.set_pixel(px, py, PALETTE['glasses'].get(shade))

        # Bridge
        for x in range(cx - int(2 * self.s), cx + int(3 * self.s)):
            self.canvas.set_pixel(x, ey, PALETTE['glasses'].get(0.3))

        # Arms
        for side in [-1, 1]:
            sx = cx + side * (self.eye_sep + lr + 1)
            for i in range(int(8 * self.s)):
                x = sx + side * i
                y = ey + i // 3
                if 0 <= x < self.size:
                    self.canvas.set_pixel(x, y, PALETTE['glasses'].get(0.35))

    def _hair_front(self):
        """Draw hair strands in front of face/over forehead."""
        cx, cy = self.cx, self.cy

        # Wispy bangs
        for i in range(9):
            bx = cx - int(12 * self.s) + i * int(3 * self.s)
            by = cy - self.face_r - int(3 * self.s)
            length = int((5 + random.random() * 4) * self.s)

            for j in range(length):
                wave = math.sin(j * 0.4 + i * 0.5) * 1.5
                x = int(bx + wave)
                y = by + j

                if 0 <= x < self.size and 0 <= y < self.size:
                    shade = 0.25 + (j / length) * 0.15 + (i % 2) * 0.08
                    self.canvas.set_pixel(x, y, PALETTE['hair'].get(shade))

        # Side strands
        for side in [-1, 1]:
            for s in range(4):
                sx = cx + side * (self.face_r + int(3 * self.s) + s * int(2 * self.s))
                sy = cy - int(self.face_r * 0.3)

                for j in range(int(25 * self.s)):
                    wave = math.sin(j * 0.08 + s) * 3 * self.s
                    x = int(sx + wave)
                    y = sy + j

                    if 0 <= x < self.size and 0 <= y < self.size:
                        prog = j / (25 * self.s)
                        shade = 0.28 + prog * 0.1 + s * 0.03
                        shade += (random.random() - 0.5) * 0.08
                        self.canvas.set_pixel(x, y, PALETTE['hair'].get(max(0.2, min(0.6, shade))))

    def _hair_highlights(self):
        """Add scattered bright highlight pixels - KEY for the look!"""
        cx, cy = self.cx, self.cy - int(5 * self.s)
        hr = self.hair_r

        # Lots of scattered highlight pixels
        for _ in range(int(150 * self.s * self.s)):
            # Bias toward upper area where light hits
            angle = random.random() * math.pi * 2
            r = random.random() ** 0.5 * hr * 0.8

            hx = int(cx + math.cos(angle) * r)
            hy = int(cy - hr * 0.3 + math.sin(angle) * r * 0.6)

            # Skip face area
            if dist(hx, hy, self.cx, self.cy) < self.face_r * 1.1:
                continue

            if 0 <= hx < self.size and 0 <= hy < self.size:
                # Brighter in upper region
                brightness = 0.05 + (1 - (hy - (cy - hr)) / hr) * 0.15
                brightness = max(0.02, min(0.2, brightness))

                # Single pixel or small cluster
                self.canvas.set_pixel(hx, hy, PALETTE['hair'].get(brightness))

                if random.random() > 0.6:
                    # Add adjacent pixels for cluster
                    for dx, dy in [(1, 0), (0, 1), (-1, 0), (0, -1)]:
                        if random.random() > 0.5:
                            nx, ny = hx + dx, hy + dy
                            if 0 <= nx < self.size and 0 <= ny < self.size:
                                self.canvas.set_pixel(nx, ny, PALETTE['hair'].get(brightness + 0.05))

        # Hair bun with spiral highlights
        bun_y = cy - hr * 0.6
        bun_r = int(10 * self.s)

        for y in range(int(bun_y - bun_r), int(bun_y + bun_r) + 1):
            for x in range(cx - bun_r, cx + bun_r + 1):
                d = dist(x, y, cx, bun_y)
                if d < bun_r:
                    nd = d / bun_r

                    # Spiral pattern
                    ang = math.atan2(y - bun_y, x - cx)
                    spiral = (ang + nd * 4) % (math.pi / 2)
                    sp_shade = 0.08 if spiral < math.pi / 4 else 0

                    # Lighting
                    light = (cx - x) / bun_r * 0.12 + (bun_y - y) / bun_r * 0.15

                    shade = 0.3 + nd * 0.15 + light + sp_shade
                    self.canvas.set_pixel(x, y, PALETTE['hair'].get(max(0.15, min(0.55, shade))))

        # Bun highlight spot
        bhx, bhy = cx - int(2 * self.s), int(bun_y - bun_r * 0.4)
        for dy in range(-2, 3):
            for dx in range(-2, 3):
                if abs(dx) + abs(dy) <= 2:
                    f = 1 - (abs(dx) + abs(dy)) / 3
                    self.canvas.set_pixel(bhx + dx, bhy + dy, PALETTE['hair'].get(0.03 + (1 - f) * 0.1))

        # Add some sparkle highlights
        sparkles = [
            (cx - int(8 * self.s), cy - int(hr * 0.5)),
            (cx + int(5 * self.s), cy - int(hr * 0.6)),
            (cx - int(3 * self.s), cy - int(hr * 0.35)),
            (cx + int(10 * self.s), cy - int(hr * 0.3)),
        ]

        for sx, sy in sparkles:
            if 0 <= sx < self.size and 0 <= sy < self.size:
                for dy in range(-1, 2):
                    for dx in range(-1, 2):
                        if abs(dx) + abs(dy) <= 1:
                            a = 220 if dx == 0 and dy == 0 else 100
                            self.canvas.set_pixel(sx + dx, sy + dy, (255, 250, 255, a))

    def _book(self):
        """Draw book in hands."""
        cx = self.cx
        bt = self.cy + int(self.face_r * 1.1)
        bb = min(self.size - 2, bt + int(self.face_r * 0.6))
        bw = int(self.face_r * 1.1)

        # Book cover
        for y in range(bt, bb):
            py = (y - bt) / max(bb - bt, 1)
            for x in range(cx - bw, cx + bw):
                if 0 <= x < self.size:
                    px = abs(x - cx) / bw
                    shade = 0.3 + (1 - py) * 0.15 + (1 - px) * 0.1
                    self.canvas.set_pixel(x, y, PALETTE['book'].sample(shade, 0.03))

        # Pages
        m = int(3 * self.s)
        for y in range(bt + m, bb - m):
            for x in range(cx - bw + m + 2, cx + bw - m - 2):
                if 0 <= x < self.size:
                    shade = 0.1 + random.random() * 0.1
                    self.canvas.set_pixel(x, y, PALETTE['pages'].get(shade))

    def save(self, path):
        self.canvas.save(path)


if __name__ == "__main__":
    import os
    out_dir = os.path.dirname(os.path.abspath(__file__))

    print("=== Lyra V4 - Cute & Detailed ===\n")

    expressions = ['neutral', 'encouraging', 'thinking', 'surprised', 'concerned']

    for expr in expressions:
        print(f"Generating {expr}...")
        gen = LyraV4(128, seed=42)
        gen.generate(expr)
        gen.save(os.path.join(out_dir, f'lyra_v4_{expr}.png'))

    print("\nGenerating 256px version...")
    gen = LyraV4(256, seed=42)
    gen.generate('neutral')
    gen.save(os.path.join(out_dir, 'lyra_v4_neutral_256.png'))

    print("\nDone! Check lyra_v4_*.png files")
