#!/usr/bin/env python3
"""
Lyra Portrait Generator V6 - Chunky Pixel Art Style
Different approach:
- Work with discrete color zones instead of smooth gradients
- More deliberate "hand-placed" pixel clusters
- Chunky pixel art aesthetic matching the reference
- Less anti-aliasing, more crisp color boundaries
"""

import math
import random
from typing import List
from png_writer import Canvas, hex_to_rgba, lerp_color, Color


class Palette:
    """Discrete color palette - pick specific colors, not gradients."""
    def __init__(self, colors: List[str]):
        self.colors = [hex_to_rgba(c) for c in colors]

    def __getitem__(self, i: int) -> Color:
        return self.colors[max(0, min(len(self.colors)-1, i))]

    def pick(self, t: float) -> Color:
        """Pick nearest color for value 0-1."""
        i = int(t * (len(self.colors) - 1) + 0.5)
        return self[i]


# Discrete palettes - specific colors, not gradients
HAIR = Palette([
    '#ffe0ff',  # 0 - Brightest highlight
    '#e8c8f0',  # 1 - Highlight
    '#d0a8e0',  # 2 - Light
    '#b888d0',  # 3 - Mid-light
    '#9868b8',  # 4 - Mid
    '#7848a0',  # 5 - Mid-dark
    '#583080',  # 6 - Dark
    '#401868',  # 7 - Shadow
    '#280850',  # 8 - Deep shadow
])

SKIN = Palette([
    '#fff0d8',  # 0 - Highlight
    '#ffd8b0',  # 1 - Light
    '#f8b888',  # 2 - Mid-light
    '#e89860',  # 3 - Mid
    '#d07840',  # 4 - Shadow
    '#a85828',  # 5 - Dark shadow
])

ROBE = Palette([
    '#8098c0',  # 0 - Highlight
    '#6078a0',  # 1 - Light
    '#486088',  # 2 - Mid
    '#304870',  # 3 - Dark
    '#203858',  # 4 - Shadow
    '#102840',  # 5 - Deep shadow
])

GLASSES = Palette(['#d0a068', '#a87840', '#885828', '#684018'])
BOOK = Palette(['#a88050', '#886030', '#684018', '#482808'])
PAGES = Palette(['#fff8f0', '#f0e8d8', '#e0d8c0'])
BG = Palette(['#1c1c3c', '#141430', '#0c0c20'])


def d(x1, y1, x2, y2):
    return math.sqrt((x2-x1)**2 + (y2-y1)**2)


def in_circle(x, y, cx, cy, r):
    return d(x, y, cx, cy) <= r


def in_ellipse(x, y, cx, cy, rx, ry):
    if rx <= 0 or ry <= 0: return False
    return ((x-cx)/rx)**2 + ((y-cy)/ry)**2 <= 1


class LyraV6:
    def __init__(self, size=128, seed=42):
        self.size = size
        self.s = size / 128
        self.seed = seed
        random.seed(seed)

        # Positioning
        self.cx = size // 2
        self.cy = int(size * 0.5)

        # Proportions (chibi style)
        self.face_r = int(17 * self.s)
        self.eye_r = int(7 * self.s)
        self.eye_sep = int(10 * self.s)
        self.hair_r = int(30 * self.s)

        self.canvas = None

    def generate(self, expr='neutral'):
        self.canvas = Canvas(self.size, self.size, BG[1])

        self._bg()
        self._hair_base()
        self._hair_detail()
        self._bun()
        self._shoulders()
        self._neck()
        self._face()
        self._cheeks()
        self._eyes(expr)
        self._nose()
        self._mouth(expr)
        self._brows(expr)
        self._glasses()
        self._hair_bangs()
        self._book()
        self._sparkles()

        return self.canvas

    def _bg(self):
        """Simple dark background."""
        for y in range(self.size):
            for x in range(self.size):
                self.canvas.set_pixel(x, y, BG[1])

    def _hair_base(self):
        """Draw hair base with chunky color zones."""
        cx, cy = self.cx, self.cy - int(6 * self.s)
        hr = self.hair_r

        for y in range(self.size):
            for x in range(self.size):
                # Check if in hair region (organic shape)
                in_hair = False

                # Main mass
                if in_ellipse(x, y, cx, cy, hr, hr * 0.85):
                    in_hair = True
                # Top bump
                if in_circle(x, y, cx, cy - hr * 0.45, hr * 0.5):
                    in_hair = True
                # Left
                if in_ellipse(x, y, cx - hr * 0.4, cy + hr * 0.15, hr * 0.55, hr * 0.65):
                    in_hair = True
                # Right
                if in_ellipse(x, y, cx + hr * 0.4, cy + hr * 0.15, hr * 0.55, hr * 0.65):
                    in_hair = True

                if not in_hair:
                    continue

                # Skip face
                if in_ellipse(x, y, self.cx, self.cy + 2, self.face_r + 2, self.face_r * 1.05 + 2):
                    continue

                # CHUNKY color zones based on position
                # Light zones on left, dark zones on right (light from left)
                zone_x = (x - (cx - hr)) / (hr * 2)  # 0-1 left to right
                zone_y = (y - (cy - hr)) / (hr * 2)  # 0-1 top to bottom

                # Base color zone
                if zone_y < 0.35:
                    # Top - lighter
                    if zone_x < 0.35:
                        color_idx = 2  # Light
                    elif zone_x < 0.65:
                        color_idx = 3  # Mid-light
                    else:
                        color_idx = 4  # Mid
                elif zone_y < 0.6:
                    # Middle
                    if zone_x < 0.3:
                        color_idx = 3
                    elif zone_x < 0.7:
                        color_idx = 4
                    else:
                        color_idx = 5
                else:
                    # Bottom - darker
                    if zone_x < 0.3:
                        color_idx = 4
                    elif zone_x < 0.7:
                        color_idx = 5
                    else:
                        color_idx = 6

                # Add some local variation
                local_noise = (hash((x * 7 + y * 13 + self.seed)) % 100) / 100
                if local_noise > 0.8:
                    color_idx = max(0, color_idx - 1)
                elif local_noise < 0.15:
                    color_idx = min(7, color_idx + 1)

                self.canvas.set_pixel(x, y, HAIR[color_idx])

    def _hair_detail(self):
        """Add strand-like detail clusters."""
        cx, cy = self.cx, self.cy - int(6 * self.s)
        hr = self.hair_r

        # Light strands (highlights)
        light_strands = [
            (cx - hr * 0.35, cy - hr * 0.3, 0.6, 20),
            (cx - hr * 0.1, cy - hr * 0.4, 0.55, 18),
            (cx + hr * 0.15, cy - hr * 0.35, 0.5, 16),
            (cx - hr * 0.5, cy, 0.58, 22),
            (cx + hr * 0.45, cy - hr * 0.1, 0.48, 18),
        ]

        for sx, sy, angle, length in light_strands:
            for i in range(int(length * self.s)):
                px = int(sx + math.cos(angle * math.pi) * i)
                py = int(sy + math.sin(angle * math.pi) * i)

                if in_ellipse(px, py, self.cx, self.cy + 2, self.face_r, self.face_r * 1.05):
                    continue

                if 0 <= px < self.size and 0 <= py < self.size:
                    # Alternate colors for strand texture
                    idx = 1 if (i % 3) < 2 else 2
                    self.canvas.set_pixel(px, py, HAIR[idx])
                    if i % 2 == 0:
                        self.canvas.set_pixel(px + 1, py, HAIR[idx + 1])

        # Dark accent strands
        dark_strands = [
            (cx + hr * 0.3, cy - hr * 0.15, 0.45, 15),
            (cx + hr * 0.5, cy + hr * 0.2, 0.5, 18),
            (cx - hr * 0.2, cy + hr * 0.3, 0.55, 12),
        ]

        for sx, sy, angle, length in dark_strands:
            for i in range(int(length * self.s)):
                px = int(sx + math.cos(angle * math.pi) * i)
                py = int(sy + math.sin(angle * math.pi) * i)

                if in_ellipse(px, py, self.cx, self.cy + 2, self.face_r, self.face_r * 1.05):
                    continue

                if 0 <= px < self.size and 0 <= py < self.size:
                    idx = 6 if (i % 3) == 0 else 5
                    self.canvas.set_pixel(px, py, HAIR[idx])

    def _bun(self):
        """Hair bun on top."""
        cx = self.cx
        by = self.cy - int(6 * self.s) - int(self.hair_r * 0.55)
        br = int(8 * self.s)

        for y in range(int(by - br), int(by + br) + 1):
            for x in range(int(cx - br), int(cx + br) + 1):
                if in_circle(x, y, cx, by, br):
                    # Zone based coloring
                    dx = (x - cx) / br
                    dy = (y - by) / br

                    if dx < -0.3 and dy < 0:
                        idx = 2  # Highlight
                    elif dy < -0.2:
                        idx = 3
                    elif dy > 0.3:
                        idx = 5
                    else:
                        idx = 4

                    # Spiral hint
                    ang = math.atan2(dy, dx)
                    dist = d(x, y, cx, by) / br
                    if (ang + dist * 4) % 1.2 < 0.3:
                        idx = max(0, idx - 1)

                    self.canvas.set_pixel(x, y, HAIR[idx])

        # Bun highlight
        for dy in range(-2, 2):
            for dx in range(-2, 2):
                if abs(dx) + abs(dy) <= 2:
                    self.canvas.set_pixel(int(cx - 2*self.s + dx), int(by - br*0.3 + dy), HAIR[1 if abs(dx)+abs(dy) < 2 else 2])

    def _shoulders(self):
        """Draw shoulders/robe."""
        cx = self.cx
        top = self.cy + int(self.face_r * 0.75)

        for y in range(top, self.size):
            prog = (y - top) / (self.size - top)
            hw = int(self.face_r * (0.85 + prog * 1.2))

            for x in range(cx - hw, cx + hw + 1):
                if 0 <= x < self.size:
                    # Zone coloring
                    zone_x = (x - (cx - hw)) / (hw * 2)

                    if zone_x < 0.25:
                        idx = 4  # Dark left
                    elif zone_x < 0.4:
                        idx = 3
                    elif zone_x < 0.6:
                        idx = 2
                    elif zone_x < 0.8:
                        idx = 1
                    else:
                        idx = 2  # Rim

                    # Darken toward bottom
                    if prog > 0.6:
                        idx = min(5, idx + 1)

                    self.canvas.set_pixel(x, y, ROBE[idx])

    def _neck(self):
        cx, cy = self.cx, self.cy
        nt = cy + int(self.face_r * 0.65)
        nb = cy + int(self.face_r * 0.85)
        nw = int(self.face_r * 0.32)

        for y in range(nt, nb):
            for x in range(cx - nw, cx + nw):
                if 0 <= x < self.size:
                    zone = (x - (cx - nw)) / (nw * 2)
                    idx = 3 if zone < 0.3 else (2 if zone > 0.7 else 2)
                    self.canvas.set_pixel(x, y, SKIN[idx])

    def _face(self):
        """Draw face with zone-based shading."""
        cx = self.cx
        cy = self.cy + int(2 * self.s)
        fr = self.face_r

        for y in range(self.size):
            for x in range(self.size):
                if in_ellipse(x, y, cx, cy, fr, fr * 1.05):
                    # Zone-based coloring
                    zone_x = (x - (cx - fr)) / (fr * 2)
                    zone_y = (y - (cy - fr)) / (fr * 2)

                    # Light from upper left
                    if zone_y < 0.35:
                        if zone_x < 0.5:
                            idx = 1  # Highlight
                        else:
                            idx = 2
                    elif zone_y < 0.65:
                        if zone_x < 0.3:
                            idx = 1
                        elif zone_x < 0.7:
                            idx = 2
                        else:
                            idx = 3
                    else:
                        if zone_x < 0.3:
                            idx = 2
                        else:
                            idx = 3

                    self.canvas.set_pixel(x, y, SKIN[idx])

    def _cheeks(self):
        """Rosy cheeks - important for cute!"""
        cx, cy = self.cx, self.cy + int(2 * self.s)
        fr = self.face_r

        blush = hex_to_rgba('#f08878')

        for side in [-1, 1]:
            ch_x = cx + side * int(fr * 0.48)
            ch_y = cy + int(fr * 0.25)
            ch_r = int(fr * 0.2)

            for y in range(ch_y - ch_r, ch_y + ch_r + 1):
                for x in range(ch_x - ch_r, ch_x + ch_r + 1):
                    if in_circle(x, y, ch_x, ch_y, ch_r):
                        dist = d(x, y, ch_x, ch_y) / ch_r
                        alpha = int(60 * (1 - dist))
                        self.canvas.set_pixel(x, y, (blush[0], blush[1], blush[2], alpha))

    def _eyes(self, expr):
        """Big cute eyes."""
        cx, cy = self.cx, self.cy
        ey = cy - int(self.face_r * 0.05)
        er = self.eye_r

        er_v = er
        if expr == 'surprised': er_v = int(er * 1.12)
        elif expr == 'thinking': er_v = int(er * 0.8)

        white = hex_to_rgba('#ffffff')
        iris_light = hex_to_rgba('#6888a8')
        iris_mid = hex_to_rgba('#405868')
        iris_dark = hex_to_rgba('#283848')
        pupil = hex_to_rgba('#101820')

        for side in [-1, 1]:
            ex = cx + side * self.eye_sep

            # White
            for y in range(ey - er_v, ey + er_v + 1):
                for x in range(ex - er, ex + er + 1):
                    if in_ellipse(x, y, ex, ey, er, er_v):
                        self.canvas.set_pixel(x, y, white)

            # Iris
            ir = int(er * 0.7)
            ix = ex + side * int(0.5 * self.s)

            for y in range(ey - ir, ey + ir + 1):
                for x in range(ix - ir, ix + ir + 1):
                    if in_circle(x, y, ix, ey, ir):
                        # Zone coloring - lighter at top
                        zy = (y - (ey - ir)) / (ir * 2)
                        if zy < 0.35:
                            c = iris_light
                        elif zy < 0.65:
                            c = iris_mid
                        else:
                            c = iris_dark
                        self.canvas.set_pixel(x, y, c)

            # Pupil
            pr = int(ir * 0.45)
            for y in range(ey - pr, ey + pr + 1):
                for x in range(ix - pr, ix + pr + 1):
                    if in_circle(x, y, ix, ey, pr):
                        self.canvas.set_pixel(x, y, pupil)

            # Catchlights!
            hl = [(ix - int(2*self.s), ey - int(2*self.s), 2),
                  (ix + int(1*self.s), ey + int(1.5*self.s), 1)]
            for hx, hy, size in hl:
                for dy in range(-size, size+1):
                    for dx in range(-size, size+1):
                        if abs(dx) + abs(dy) <= size:
                            self.canvas.set_pixel(int(hx+dx), int(hy+dy), (255, 255, 255, 255))

            # Eyelid
            for x in range(ex - er - 1, ex + er + 2):
                self.canvas.set_pixel(x, ey - er_v - 1, SKIN[3])

    def _nose(self):
        cx, cy = self.cx, self.cy
        ny = cy + int(self.face_r * 0.2)
        self.canvas.set_pixel(cx - 1, ny, SKIN[3])
        self.canvas.set_pixel(cx, ny + 1, SKIN[2])

    def _mouth(self, expr):
        cx, cy = self.cx, self.cy
        my = cy + int(self.face_r * 0.45)
        mw = int(self.face_r * 0.28)

        if expr in ['neutral', 'thinking']:
            for i in range(-mw, mw + 1):
                curve = int((i*i) / (mw * 1.3))
                self.canvas.set_pixel(cx + i, my + curve, SKIN[4])
        elif expr == 'encouraging':
            mw = int(mw * 1.2)
            for i in range(-mw, mw + 1):
                curve = int((i*i) / (mw * 1.1))
                self.canvas.set_pixel(cx + i, my + curve, SKIN[4])
        elif expr == 'surprised':
            for a in range(0, 360, 30):
                r = math.radians(a)
                self.canvas.set_pixel(int(cx + math.cos(r)*2*self.s), int(my + 1 + math.sin(r)*1.5*self.s), SKIN[4])
        elif expr == 'concerned':
            for i in range(-mw, mw + 1):
                curve = -int((i*i) / (mw * 2)) + 1
                self.canvas.set_pixel(cx + i, my + curve, SKIN[4])

    def _brows(self, expr):
        cx, cy = self.cx, self.cy
        by = cy - self.eye_r - int(5 * self.s)
        bl = int(6 * self.s)

        y_off = -2 if expr == 'surprised' else (1 if expr == 'concerned' else 0)

        for side in [-1, 1]:
            bx = cx + side * self.eye_sep
            for i in range(bl):
                prog = i / bl
                x = bx - side * (bl // 2) + side * i

                if expr == 'concerned':
                    yc = int(prog * 2) * side
                elif expr == 'surprised':
                    yc = int(math.sin(prog * math.pi) * -2)
                else:
                    yc = int(math.sin(prog * math.pi) * -1)

                y = by + y_off + yc
                self.canvas.set_pixel(x, y, HAIR[5])
                self.canvas.set_pixel(x, y + 1, HAIR[6])

    def _glasses(self):
        cx, cy = self.cx, self.cy
        ey = cy - int(self.face_r * 0.05)
        lr = self.eye_r + int(2 * self.s)

        for side in [-1, 1]:
            lx = cx + side * self.eye_sep
            for a in range(0, 360, 5):
                r = math.radians(a)
                for t in range(2):
                    px = int(lx + math.cos(r) * (lr + t))
                    py = int(ey + math.sin(r) * (lr + t))
                    idx = 0 if (a < 90 or a > 270) else 2
                    if 0 <= px < self.size and 0 <= py < self.size:
                        self.canvas.set_pixel(px, py, GLASSES[idx + t])

        # Bridge
        for x in range(cx - int(2*self.s), cx + int(2*self.s)):
            self.canvas.set_pixel(x, ey, GLASSES[1])

        # Arms
        for side in [-1, 1]:
            sx = cx + side * (self.eye_sep + lr + 1)
            for i in range(int(7 * self.s)):
                x = sx + side * i
                if 0 <= x < self.size:
                    self.canvas.set_pixel(x, ey + i // 3, GLASSES[1])

    def _hair_bangs(self):
        """Front hair over forehead."""
        cx, cy = self.cx, self.cy

        # Bangs
        for i in range(7):
            bx = cx - int(9 * self.s) + i * int(3 * self.s)
            by = cy - self.face_r - int(1 * self.s)
            length = int((4 + (i % 3)) * self.s)

            for j in range(length):
                x = bx + int(math.sin(j * 0.4 + i) * self.s)
                y = by + j
                if 0 <= x < self.size and 0 <= y < self.size:
                    idx = 2 if j < length * 0.4 else 3
                    self.canvas.set_pixel(x, y, HAIR[idx])

        # Side strands
        for side in [-1, 1]:
            for s in range(3):
                sx = cx + side * (self.face_r + int((2 + s*2) * self.s))
                sy = cy - int(self.face_r * 0.35)

                for j in range(int(20 * self.s)):
                    wave = math.sin(j * 0.12 + s * 0.5) * 2 * self.s
                    x = int(sx + wave)
                    y = sy + j

                    if 0 <= x < self.size and 0 <= y < self.size:
                        idx = 3 + s
                        self.canvas.set_pixel(x, y, HAIR[idx])
                        self.canvas.set_pixel(x + side, y, HAIR[idx + 1])

    def _book(self):
        cx = self.cx
        bt = self.cy + int(self.face_r * 0.95)
        bb = min(self.size - 2, bt + int(self.face_r * 0.45))
        bw = int(self.face_r * 1.0)

        for y in range(bt, bb):
            for x in range(cx - bw, cx + bw):
                if 0 <= x < self.size:
                    zone = (x - (cx - bw)) / (bw * 2)
                    idx = 0 if zone < 0.2 else (2 if zone > 0.8 else 1)
                    self.canvas.set_pixel(x, y, BOOK[idx])

        # Pages
        m = int(2 * self.s)
        for y in range(bt + m, bb - m):
            for x in range(cx - bw + m + 2, cx + bw - m - 2):
                if 0 <= x < self.size:
                    self.canvas.set_pixel(x, y, PAGES[0])

    def _sparkles(self):
        """Add sparkle highlights in hair."""
        cx, cy = self.cx, self.cy - int(6 * self.s)
        hr = self.hair_r

        sparkles = [
            (cx - int(7*self.s), cy - int(hr*0.4)),
            (cx + int(5*self.s), cy - int(hr*0.45)),
            (cx - int(2*self.s), cy - int(hr*0.25)),
        ]

        for sx, sy in sparkles:
            # Cross pattern
            self.canvas.set_pixel(sx, sy, (255, 255, 255, 255))
            for d in range(1, 2):
                self.canvas.set_pixel(sx - d, sy, (255, 255, 255, 200))
                self.canvas.set_pixel(sx + d, sy, (255, 255, 255, 200))
                self.canvas.set_pixel(sx, sy - d, (255, 255, 255, 200))
                self.canvas.set_pixel(sx, sy + d, (255, 255, 255, 200))

    def save(self, path):
        self.canvas.save(path)


if __name__ == "__main__":
    import os
    out = os.path.dirname(os.path.abspath(__file__))

    print("=== Lyra V6 - Chunky Pixel Art ===\n")

    for expr in ['neutral', 'encouraging', 'thinking', 'surprised', 'concerned']:
        print(f"Generating {expr}...")
        g = LyraV6(128, 42)
        g.generate(expr)
        g.save(os.path.join(out, f'lyra_v6_{expr}.png'))

    print("\n256px version...")
    g = LyraV6(256, 42)
    g.generate('neutral')
    g.save(os.path.join(out, 'lyra_v6_neutral_256.png'))

    print("\nDone!")
