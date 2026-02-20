#!/usr/bin/env python3
"""
Lyra Portrait Generator V9 - Hand-Painted Chunky Style
Key changes from V8:
- NO scattered pixel noise - use deliberate chunky blocks
- Paint in distinct color zones like hand-pixel art
- Larger highlight/shadow patches, not individual pixels
- Even bigger eyes for maximum cuteness
- More cohesive hair mass with clear light/shadow regions
"""

import math
import random
from png_writer import Canvas, hex_to_rgba, Color


# Hair palette - rich lavender/purple
HAIR = [
    hex_to_rgba('#fff8ff'),  # 0 - Brightest highlight
    hex_to_rgba('#f8e8ff'),  # 1 - Light lavender
    hex_to_rgba('#e8d0f8'),  # 2 - Soft lavender
    hex_to_rgba('#d8b8f0'),  # 3 - Light purple
    hex_to_rgba('#c8a0e0'),  # 4 - Mid lavender
    hex_to_rgba('#b888d0'),  # 5 - Mid purple
    hex_to_rgba('#a070c0'),  # 6 - Purple
    hex_to_rgba('#8858a8'),  # 7 - Darker purple
    hex_to_rgba('#704890'),  # 8 - Dark
    hex_to_rgba('#583878'),  # 9 - Shadow
    hex_to_rgba('#402860'),  # 10 - Deep shadow
    hex_to_rgba('#302050'),  # 11 - Darkest
]

# Warm orange skin
SKIN = [
    hex_to_rgba('#fff8e8'),  # 0 - Highlight
    hex_to_rgba('#ffe8c8'),  # 1 - Light
    hex_to_rgba('#ffd0a0'),  # 2 - Peach
    hex_to_rgba('#f0b078'),  # 3 - Mid
    hex_to_rgba('#e09058'),  # 4 - Orange
    hex_to_rgba('#c87040'),  # 5 - Shadow
]

# Blue robe
ROBE = [
    hex_to_rgba('#90a8c8'),  # 0 - Highlight
    hex_to_rgba('#7090b8'),  # 1 - Light
    hex_to_rgba('#5878a0'),  # 2 - Mid
    hex_to_rgba('#486088'),  # 3 - Dark
    hex_to_rgba('#384870'),  # 4 - Shadow
    hex_to_rgba('#283050'),  # 5 - Deep
]

BG = hex_to_rgba('#181830')
GOLD = [hex_to_rgba('#f0d080'), hex_to_rgba('#d0a858'), hex_to_rgba('#a08040')]


def dist(x1, y1, x2, y2):
    return math.sqrt((x2-x1)**2 + (y2-y1)**2)


class LyraV9:
    def __init__(self, size=128, seed=42):
        self.size = size
        self.s = size / 128
        self.seed = seed
        random.seed(seed)

        self.cx = size // 2
        self.cy = int(size * 0.52)

        # Proportions: HUGE hair, small face, BIG eyes
        self.face_r = int(13 * self.s)
        self.eye_r = int(9 * self.s)    # Even bigger eyes!
        self.eye_sep = int(7 * self.s)  # Closer together
        self.hair_r = int(34 * self.s)  # Massive fluffy hair

    def generate(self, expr='neutral'):
        self.canvas = Canvas(self.size, self.size, BG)

        self._hair_back()
        self._body()
        self._face()
        self._eyes(expr)
        self._details(expr)
        self._hair_front()
        self._final_touches()

        return self.canvas

    def _fill_blob(self, cx, cy, rx, ry, color, squash=0):
        """Fill an organic blob shape - chunky, not smooth."""
        for y in range(int(cy - ry - 2), int(cy + ry + 3)):
            for x in range(int(cx - rx - 2), int(cx + rx + 3)):
                if 0 <= x < self.size and 0 <= y < self.size:
                    dx = (x - cx) / max(rx, 1)
                    dy = (y - cy) / max(ry, 1)

                    # Add some squish for organic feel
                    angle = math.atan2(dy, dx)
                    squish = 1.0 + squash * math.sin(angle * 3)

                    if (dx*dx + dy*dy) < squish:
                        self.canvas.set_pixel(x, y, color)

    def _hair_back(self):
        """Draw the main hair mass with chunky zones, not noise."""
        cx = self.cx
        cy = self.cy - int(10 * self.s)
        hr = self.hair_r

        # STEP 1: Fill base hair shape with mid-tone
        for y in range(self.size):
            for x in range(self.size):
                dx = (x - cx) / hr
                dy = (y - cy) / (hr * 0.88)

                # Bumpy edges for fluffiness
                angle = math.atan2(y - cy, x - cx)
                bump = 0.0
                bump += math.sin(angle * 5) * 0.1
                bump += math.sin(angle * 8 + 0.5) * 0.06
                bump += math.sin(angle * 13) * 0.04

                # Extra poof on sides
                side_bump = abs(math.cos(angle)) * 0.08
                # Extra poof on top
                if dy < 0:
                    bump += 0.12

                threshold = 1.0 + bump + side_bump
                d = math.sqrt(dx*dx + dy*dy)

                if d < threshold:
                    # Skip face
                    face_d = dist(x, y, self.cx, self.cy + 2)
                    if face_d < self.face_r - 1:
                        continue

                    # Base shading: simple zones not gradients
                    # Divide into rough quadrants
                    zone = 5  # Default mid

                    # Upper left = lightest
                    if dx < -0.2 and dy < -0.2:
                        zone = 3
                    elif dx < 0 and dy < 0:
                        zone = 4
                    # Lower right = darkest
                    elif dx > 0.2 and dy > 0.2:
                        zone = 8
                    elif dx > 0 or dy > 0.3:
                        zone = 6
                    # Edges get darker
                    if d > 0.75:
                        zone = min(9, zone + 2)

                    self.canvas.set_pixel(x, y, HAIR[zone])

        # STEP 2: Paint chunky highlight BLOBS (not scattered pixels!)
        self._paint_hair_highlights(cx, cy, hr)

        # STEP 3: Paint shadow blobs
        self._paint_hair_shadows(cx, cy, hr)

        # STEP 4: Bun on top
        self._bun(cx, cy - hr * 0.58)

    def _paint_hair_highlights(self, cx, cy, hr):
        """Paint deliberate highlight blobs - chunky hand-painted look."""

        # Define highlight regions as blobs: (x, y, rx, ry, color_index)
        highlights = [
            # Main upper-left highlight area
            (cx - hr * 0.35, cy - hr * 0.25, 7, 5, 2),
            (cx - hr * 0.45, cy - hr * 0.15, 5, 4, 3),
            (cx - hr * 0.25, cy - hr * 0.4, 6, 4, 2),
            # Brighter center of highlights
            (cx - hr * 0.38, cy - hr * 0.28, 4, 3, 1),
            # Top highlights
            (cx - hr * 0.1, cy - hr * 0.55, 5, 4, 3),
            (cx + hr * 0.15, cy - hr * 0.5, 4, 3, 4),
            # Left edge highlight
            (cx - hr * 0.6, cy - hr * 0.05, 4, 5, 4),
        ]

        for hx, hy, rx, ry, idx in highlights:
            rx = int(rx * self.s)
            ry = int(ry * self.s)
            self._fill_blob(hx, hy, rx, ry, HAIR[idx], 0.15)

    def _paint_hair_shadows(self, cx, cy, hr):
        """Paint deliberate shadow blobs."""

        shadows = [
            # Right side shadows
            (cx + hr * 0.45, cy + hr * 0.1, 6, 6, 8),
            (cx + hr * 0.55, cy - hr * 0.1, 5, 5, 9),
            # Bottom shadows
            (cx + hr * 0.2, cy + hr * 0.35, 7, 4, 9),
            (cx - hr * 0.3, cy + hr * 0.4, 5, 4, 8),
            # Under bun shadow
            (cx, cy - hr * 0.35, 6, 3, 7),
        ]

        for sx, sy, rx, ry, idx in shadows:
            rx = int(rx * self.s)
            ry = int(ry * self.s)
            self._fill_blob(sx, sy, rx, ry, HAIR[idx], 0.1)

    def _bun(self, cx, by):
        """Draw hair bun with simple shading."""
        br = int(11 * self.s)

        # Base bun
        for y in range(int(by - br), int(by + br) + 1):
            for x in range(int(cx - br), int(cx + br) + 1):
                d = dist(x, y, cx, by)
                if d < br:
                    # Simple quadrant shading
                    rel_x = (x - cx) / br
                    rel_y = (y - by) / br

                    if rel_x < -0.2 and rel_y < -0.2:
                        idx = 3  # Upper-left highlight
                    elif rel_x < 0.2 and rel_y < 0.2:
                        idx = 5  # Center
                    else:
                        idx = 7  # Right/bottom shadow

                    # Edge darkening
                    if d > br * 0.75:
                        idx = min(9, idx + 1)

                    self.canvas.set_pixel(x, y, HAIR[idx])

        # Bun highlight blob
        self._fill_blob(cx - 2 * self.s, by - br * 0.35, 3 * self.s, 2.5 * self.s, HAIR[1], 0.2)

    def _body(self):
        """Draw shoulders and robe."""
        cx = self.cx
        top = self.cy + int(self.face_r * 0.55)

        for y in range(top, self.size):
            prog = (y - top) / max(1, self.size - top)
            hw = int(self.face_r * (0.65 + prog * 1.5))

            for x in range(cx - hw, cx + hw + 1):
                if 0 <= x < self.size:
                    rel_x = (x - cx) / max(1, hw)

                    # Simple zone shading for cloth
                    if rel_x < -0.3:
                        idx = 1  # Left highlight
                    elif rel_x < 0.2:
                        idx = 2  # Center
                    else:
                        idx = 4  # Right shadow

                    # Darker toward bottom
                    if prog > 0.6:
                        idx = min(5, idx + 1)

                    self.canvas.set_pixel(x, y, ROBE[idx])

        self._book()

    def _book(self):
        """Draw the book."""
        cx = self.cx
        bt = self.cy + int(self.face_r * 0.8)
        bh = int(self.face_r * 0.55)
        bw = int(self.face_r * 1.05)

        cover = hex_to_rgba('#8b5a2b')
        cover_hi = hex_to_rgba('#a06830')
        pages = hex_to_rgba('#f5f0e0')

        for y in range(bt, min(self.size, bt + bh)):
            for x in range(cx - bw, cx + bw):
                if 0 <= x < self.size:
                    c = cover_hi if x < cx - bw // 2 else cover
                    self.canvas.set_pixel(x, y, c)

        # Pages
        m = int(2 * self.s)
        for y in range(bt + m, min(self.size, bt + bh - m)):
            for x in range(cx - bw + m + 2, cx + bw - m - 2):
                if 0 <= x < self.size:
                    self.canvas.set_pixel(x, y, pages)

    def _face(self):
        """Draw cute round face."""
        cx = self.cx
        cy = self.cy + int(2 * self.s)
        fr = self.face_r

        for y in range(self.size):
            for x in range(self.size):
                dx = (x - cx) / fr
                dy = (y - cy) / fr
                d = dx*dx + dy*dy

                if d < 1.0:
                    # Zone-based shading for face
                    if dx < -0.3 and dy < -0.2:
                        idx = 1  # Upper-left highlight
                    elif dx < 0 and dy < 0.3:
                        idx = 2  # Light side
                    elif dy > 0.5:
                        idx = 4  # Bottom shadow
                    else:
                        idx = 3  # Mid tone

                    # Edge shadow
                    if d > 0.7:
                        idx = min(5, idx + 1)

                    self.canvas.set_pixel(x, y, SKIN[idx])

        # Neck
        nw = int(fr * 0.26)
        for y in range(cy + int(fr * 0.7), cy + int(fr * 0.88)):
            for x in range(cx - nw, cx + nw):
                if 0 <= x < self.size:
                    self.canvas.set_pixel(x, y, SKIN[3])

        # Blush - soft pink circles
        blush = hex_to_rgba('#ff8878')
        for side in [-1, 1]:
            bx = cx + side * int(fr * 0.52)
            by = cy + int(fr * 0.32)
            br = int(fr * 0.2)

            for y in range(by - br, by + br + 1):
                for x in range(bx - br, bx + br + 1):
                    d = dist(x, y, bx, by)
                    if d < br:
                        alpha = int(40 * (1 - d/br))
                        if 0 <= x < self.size and 0 <= y < self.size:
                            self.canvas.set_pixel(x, y, (blush[0], blush[1], blush[2], alpha))

    def _eyes(self, expr):
        """Draw BIG cute anime eyes."""
        cx, cy = self.cx, self.cy
        ey = cy - int(self.face_r * 0.08)
        er = self.eye_r  # Already huge!

        er_v = er
        if expr == 'surprised':
            er_v = int(er * 1.2)
        elif expr == 'thinking':
            er_v = int(er * 0.82)

        for side in [-1, 1]:
            ex = cx + side * self.eye_sep

            # Eye white
            for y in range(ey - er_v - 1, ey + er_v + 2):
                for x in range(ex - er - 1, ex + er + 2):
                    dx = (x - ex) / (er + 0.5)
                    dy = (y - ey) / (er_v + 0.5)
                    if dx*dx + dy*dy <= 1:
                        self.canvas.set_pixel(x, y, (255, 255, 255, 255))

            # Iris - vertical gradient
            ir = int(er * 0.78)
            ix = ex + side * int(1 * self.s)

            iris = [
                hex_to_rgba('#8098b8'),  # Top
                hex_to_rgba('#6080a0'),
                hex_to_rgba('#506888'),
                hex_to_rgba('#405068'),  # Bottom
            ]

            for y in range(ey - ir, ey + ir + 1):
                for x in range(ix - ir, ix + ir + 1):
                    d = dist(x, y, ix, ey)
                    if d < ir:
                        prog = (y - (ey - ir)) / (ir * 2)
                        idx = int(prog * 3.5)
                        self.canvas.set_pixel(x, y, iris[min(3, idx)])

            # Pupil
            pr = int(ir * 0.48)
            pupil = hex_to_rgba('#101820')
            for y in range(ey - pr, ey + pr + 1):
                for x in range(ix - pr, ix + pr + 1):
                    if dist(x, y, ix, ey) < pr:
                        self.canvas.set_pixel(x, y, pupil)

            # Catchlights - BIG and prominent!
            white = (255, 255, 255, 255)

            # Main highlight - upper left, 3x3ish
            hx, hy = int(ix - 3 * self.s), int(ey - 3 * self.s)
            for dy in range(-1, 2):
                for dx in range(-1, 2):
                    self.canvas.set_pixel(hx + dx, hy + dy, white)
            self.canvas.set_pixel(hx - 1, hy - 1, white)
            self.canvas.set_pixel(hx + 1, hy - 1, white)

            # Secondary highlight - lower right, smaller
            hx2, hy2 = int(ix + 2 * self.s), int(ey + 2.5 * self.s)
            self.canvas.set_pixel(hx2, hy2, white)
            self.canvas.set_pixel(hx2 + 1, hy2, (255, 255, 255, 200))

            # Upper eyelid
            for x in range(ex - er - 1, ex + er + 2):
                if 0 <= x < self.size:
                    self.canvas.set_pixel(x, ey - er_v - 1, SKIN[4])

    def _details(self, expr):
        """Nose, mouth, eyebrows, glasses."""
        cx, cy = self.cx, self.cy
        fr = self.face_r

        # Tiny nose
        ny = cy + int(fr * 0.18)
        self.canvas.set_pixel(cx, ny, SKIN[4])
        self.canvas.set_pixel(cx + 1, ny, SKIN[3])

        # Mouth
        my = cy + int(fr * 0.5)
        mw = int(fr * 0.22)
        mc = SKIN[5]

        if expr in ['neutral', 'thinking']:
            for i in range(-mw, mw + 1):
                curve = int((i*i) / (mw * 1.5))
                self.canvas.set_pixel(cx + i, my + curve, mc)
        elif expr == 'encouraging':
            mw = int(mw * 1.25)
            for i in range(-mw, mw + 1):
                curve = int((i*i) / (mw * 1.2))
                self.canvas.set_pixel(cx + i, my + curve, mc)
        elif expr == 'surprised':
            for a in range(0, 360, 30):
                r = math.radians(a)
                self.canvas.set_pixel(int(cx + math.cos(r)*2*self.s), int(my + 1 + math.sin(r)*1.5*self.s), mc)
        elif expr == 'concerned':
            for i in range(-mw, mw + 1):
                curve = -int((i*i) / (mw * 2.5)) + 1
                self.canvas.set_pixel(cx + i, my + curve, mc)

        # Eyebrows
        by = cy - self.eye_r - int(5 * self.s)
        bl = int(6 * self.s)
        y_off = -2 if expr == 'surprised' else (1 if expr == 'concerned' else 0)

        for side in [-1, 1]:
            bx = cx + side * self.eye_sep
            for i in range(bl):
                prog = i / bl
                x = bx - side * (bl // 2) + side * i

                if expr == 'concerned':
                    yc = int(prog * 2.5) * side
                elif expr == 'surprised':
                    yc = int(math.sin(prog * math.pi) * -2.5)
                else:
                    yc = int(math.sin(prog * math.pi) * -1)

                y = by + y_off + yc
                if 0 <= x < self.size and 0 <= y < self.size:
                    self.canvas.set_pixel(x, y, HAIR[7])
                    self.canvas.set_pixel(x, y + 1, HAIR[9])

        # Glasses
        ey = cy - int(fr * 0.08)
        lr = self.eye_r + int(3 * self.s)

        for side in [-1, 1]:
            lx = cx + side * self.eye_sep

            for a in range(0, 360, 4):
                rad = math.radians(a)
                for t in range(int(2 * self.s)):
                    px = int(lx + math.cos(rad) * (lr + t))
                    py = int(ey + math.sin(rad) * (lr + t))

                    c = GOLD[0] if (a < 180 and t == 0) else GOLD[1] if t == 0 else GOLD[2]
                    if 0 <= px < self.size and 0 <= py < self.size:
                        self.canvas.set_pixel(px, py, c)

        # Bridge
        for x in range(cx - int(3 * self.s), cx + int(3 * self.s)):
            self.canvas.set_pixel(x, ey, GOLD[1])
            self.canvas.set_pixel(x, ey + 1, GOLD[2])

        # Arms
        for side in [-1, 1]:
            sx = cx + side * (self.eye_sep + lr + 2)
            for i in range(int(9 * self.s)):
                x = sx + side * i
                if 0 <= x < self.size:
                    self.canvas.set_pixel(x, ey + i // 4, GOLD[1])

    def _hair_front(self):
        """Draw bangs and side hair."""
        cx, cy = self.cx, self.cy
        fr = self.face_r

        # Bangs - chunky strands, not thin lines
        bangs = [
            (-0.55, 0.6, 2.5),
            (-0.3, 0.75, 3),
            (-0.05, 0.82, 3),
            (0.2, 0.75, 2.5),
            (0.45, 0.6, 2),
        ]

        for bx_off, length_r, width in bangs:
            bx = cx + int(bx_off * fr)
            by_start = cy - fr - int(3 * self.s)
            length = int(length_r * fr * 0.5)
            w = int(width * self.s)

            for j in range(length):
                prog = j / length
                wave = math.sin(j * 0.35 + bx_off * 3) * self.s * 0.8

                # Color: lighter at base, darker at tip
                if prog < 0.3:
                    idx = 3
                elif prog < 0.6:
                    idx = 5
                else:
                    idx = 6

                # Draw thick strand
                for dx in range(-w, w + 1):
                    x = int(bx + wave + dx)
                    y = by_start + j
                    if 0 <= x < self.size and 0 <= y < self.size:
                        # Lighter center
                        c_idx = idx - 1 if abs(dx) == 0 else idx
                        self.canvas.set_pixel(x, y, HAIR[c_idx])

        # Side strands
        for side in [-1, 1]:
            base_x = cx + side * (fr + int(5 * self.s))
            base_y = cy - int(fr * 0.35)

            for strand in range(3):
                sx = base_x + side * strand * int(2.5 * self.s)
                sy = base_y + strand * int(3 * self.s)
                length = int((20 - strand * 4) * self.s)
                w = int((2.5 - strand * 0.4) * self.s)

                for j in range(length):
                    prog = j / length
                    wave = math.sin(j * 0.1 + strand * 0.7) * 2 * self.s

                    # Gradient shading
                    base_idx = 4 + strand
                    idx = base_idx + int(prog * 2.5)
                    idx = min(10, idx)

                    for dx in range(-w, w + 1):
                        x = int(sx + wave + dx * 0.8)
                        y = sy + j
                        if 0 <= x < self.size and 0 <= y < self.size:
                            c_idx = max(2, idx - 1) if abs(dx) <= 1 else idx
                            self.canvas.set_pixel(x, y, HAIR[c_idx])

    def _final_touches(self):
        """Add sparkle highlights."""
        cx = self.cx
        cy = self.cy - int(10 * self.s)
        hr = self.hair_r

        # Small sparkle highlights
        sparkles = [
            (cx - int(10 * self.s), cy - int(hr * 0.3)),
            (cx + int(6 * self.s), cy - int(hr * 0.45)),
            (cx - int(3 * self.s), cy - int(hr * 0.6)),
        ]

        white = (255, 255, 255, 255)
        for sx, sy in sparkles:
            if 0 <= sx < self.size and 0 <= sy < self.size:
                # Simple cross sparkle
                self.canvas.set_pixel(sx, sy, white)
                for dx, dy in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
                    px, py = sx + dx, sy + dy
                    if 0 <= px < self.size and 0 <= py < self.size:
                        self.canvas.set_pixel(px, py, (255, 255, 255, 200))

    def save(self, path):
        self.canvas.save(path)


if __name__ == "__main__":
    import os
    out = os.path.dirname(os.path.abspath(__file__))

    print("=== Lyra V9 - Chunky Hand-Painted ===\n")

    for expr in ['neutral', 'encouraging', 'thinking', 'surprised', 'concerned']:
        print(f"  {expr}...")
        g = LyraV9(128, 42)
        g.generate(expr)
        g.save(os.path.join(out, f'lyra_v9_{expr}.png'))

    print("\n  256px...")
    g = LyraV9(256, 42)
    g.generate('neutral')
    g.save(os.path.join(out, 'lyra_v9_neutral_256.png'))

    print("\nDone!")
