#!/usr/bin/env python3
"""
Lyra Portrait Generator V10 - Soft Chunky Style
Key changes from V9:
- Softer zone transitions (not hard quadrant boundaries)
- Gradient-based base with chunky highlights/shadows on top
- More organic blob shapes
- Better hair silhouette
- Smoother color flow while keeping hand-painted feel
"""

import math
import random
from png_writer import Canvas, hex_to_rgba, Color


# Hair palette
HAIR = [
    hex_to_rgba('#fff8ff'),  # 0 - Brightest
    hex_to_rgba('#f8e8ff'),  # 1
    hex_to_rgba('#e8d0f8'),  # 2
    hex_to_rgba('#d8b8f0'),  # 3
    hex_to_rgba('#c8a0e0'),  # 4
    hex_to_rgba('#b888d0'),  # 5
    hex_to_rgba('#a070c0'),  # 6
    hex_to_rgba('#8858a8'),  # 7
    hex_to_rgba('#704890'),  # 8
    hex_to_rgba('#583878'),  # 9
    hex_to_rgba('#402860'),  # 10
    hex_to_rgba('#302050'),  # 11
]

SKIN = [
    hex_to_rgba('#fff8e8'),  # 0
    hex_to_rgba('#ffe8c8'),  # 1
    hex_to_rgba('#ffd0a0'),  # 2
    hex_to_rgba('#f0b078'),  # 3
    hex_to_rgba('#e09058'),  # 4
    hex_to_rgba('#c87040'),  # 5
]

ROBE = [
    hex_to_rgba('#90a8c8'),  # 0
    hex_to_rgba('#7090b8'),  # 1
    hex_to_rgba('#5878a0'),  # 2
    hex_to_rgba('#486088'),  # 3
    hex_to_rgba('#384870'),  # 4
    hex_to_rgba('#283050'),  # 5
]

BG = hex_to_rgba('#181830')
GOLD = [hex_to_rgba('#f0d080'), hex_to_rgba('#d0a858'), hex_to_rgba('#a08040')]


def dist(x1, y1, x2, y2):
    return math.sqrt((x2-x1)**2 + (y2-y1)**2)


class LyraV10:
    def __init__(self, size=128, seed=42):
        self.size = size
        self.s = size / 128
        self.seed = seed
        random.seed(seed)

        self.cx = size // 2
        self.cy = int(size * 0.52)

        self.face_r = int(13 * self.s)
        self.eye_r = int(9 * self.s)
        self.eye_sep = int(7 * self.s)
        self.hair_r = int(34 * self.s)

    def generate(self, expr='neutral'):
        self.canvas = Canvas(self.size, self.size, BG)

        self._hair_back()
        self._body()
        self._face()
        self._eyes(expr)
        self._details(expr)
        self._hair_front()
        self._sparkles()

        return self.canvas

    def _organic_blob(self, cx, cy, rx, ry, color, irregularity=0.2):
        """Draw an organic blob with irregular edges."""
        random.seed(int(cx * 100 + cy))  # Consistent randomness per blob

        for y in range(int(cy - ry * 1.3), int(cy + ry * 1.3) + 1):
            for x in range(int(cx - rx * 1.3), int(cx + rx * 1.3) + 1):
                if 0 <= x < self.size and 0 <= y < self.size:
                    dx = (x - cx) / max(rx, 1)
                    dy = (y - cy) / max(ry, 1)
                    d = dx*dx + dy*dy

                    # Add angle-based irregularity
                    angle = math.atan2(dy, dx)
                    wobble = 1.0
                    wobble += math.sin(angle * 3 + cx * 0.1) * irregularity
                    wobble += math.sin(angle * 5 + cy * 0.1) * irregularity * 0.5

                    if d < wobble:
                        self.canvas.set_pixel(x, y, color)

    def _hair_back(self):
        """Draw hair with soft gradient base + chunky overlay."""
        cx = self.cx
        cy = self.cy - int(10 * self.s)
        hr = self.hair_r

        # Pass 1: Soft gradient base
        for y in range(self.size):
            for x in range(self.size):
                dx = (x - cx) / hr
                dy = (y - cy) / (hr * 0.88)

                # Fluffy edges
                angle = math.atan2(y - cy, x - cx)
                bump = 0.0
                bump += math.sin(angle * 5) * 0.1
                bump += math.sin(angle * 8 + 1) * 0.06
                bump += math.sin(angle * 13) * 0.04

                # Extra poof
                if dy < 0:
                    bump += 0.12
                bump += abs(math.cos(angle)) * 0.08

                threshold = 1.0 + bump
                d = math.sqrt(dx*dx + dy*dy)

                if d < threshold:
                    # Skip face
                    face_d = dist(x, y, self.cx, self.cy + 2)
                    if face_d < self.face_r - 1:
                        continue

                    # SMOOTH gradient shading
                    # Light direction from upper-left
                    light = 0.0
                    light -= dx * 0.25  # Lighter on left
                    light -= dy * 0.35  # Lighter on top
                    light += d * 0.2    # Darker at edges

                    # Base shade (0=light, 1=dark)
                    shade = 0.4 + light

                    # Quantize slightly for chunky feel (but not too much)
                    shade = round(shade * 6) / 6
                    shade = max(0.15, min(0.85, shade))

                    idx = int(shade * 10)
                    self.canvas.set_pixel(x, y, HAIR[idx])

        # Pass 2: Chunky highlight blobs
        self._hair_highlights(cx, cy, hr)

        # Pass 3: Chunky shadow blobs
        self._hair_shadows(cx, cy, hr)

        # Bun
        self._bun(cx, cy - hr * 0.58)

    def _hair_highlights(self, cx, cy, hr):
        """Add chunky highlight patches."""
        highlights = [
            # Main highlight area (upper left)
            (cx - hr * 0.38, cy - hr * 0.28, 8, 6, 2, 0.25),
            (cx - hr * 0.32, cy - hr * 0.35, 5, 4, 1, 0.2),
            # Secondary highlights
            (cx - hr * 0.48, cy - hr * 0.1, 5, 5, 3, 0.3),
            (cx - hr * 0.18, cy - hr * 0.48, 6, 4, 2, 0.25),
            # Top
            (cx + hr * 0.08, cy - hr * 0.52, 5, 4, 3, 0.2),
            # Rim light right side (subtle)
            (cx + hr * 0.48, cy - hr * 0.35, 4, 5, 5, 0.15),
        ]

        for hx, hy, rx, ry, idx, irr in highlights:
            rx = int(rx * self.s)
            ry = int(ry * self.s)
            self._organic_blob(hx, hy, rx, ry, HAIR[idx], irr)

    def _hair_shadows(self, cx, cy, hr):
        """Add chunky shadow patches."""
        shadows = [
            # Right side
            (cx + hr * 0.4, cy + hr * 0.15, 7, 6, 8, 0.2),
            (cx + hr * 0.52, cy - hr * 0.08, 5, 5, 9, 0.25),
            # Bottom
            (cx + hr * 0.15, cy + hr * 0.35, 6, 4, 9, 0.2),
            (cx - hr * 0.25, cy + hr * 0.38, 5, 4, 8, 0.2),
            # Under bun
            (cx, cy - hr * 0.38, 5, 3, 7, 0.15),
        ]

        for sx, sy, rx, ry, idx, irr in shadows:
            rx = int(rx * self.s)
            ry = int(ry * self.s)
            self._organic_blob(sx, sy, rx, ry, HAIR[idx], irr)

    def _bun(self, cx, by):
        """Hair bun with soft shading."""
        br = int(11 * self.s)

        for y in range(int(by - br), int(by + br) + 1):
            for x in range(int(cx - br), int(cx + br) + 1):
                d = dist(x, y, cx, by)
                if d < br:
                    rel_x = (x - cx) / br
                    rel_y = (y - by) / br

                    # Smooth shading
                    shade = 0.4 - rel_x * 0.15 - rel_y * 0.2 + (d/br) * 0.15
                    shade = max(0.15, min(0.85, shade))
                    idx = int(shade * 10)

                    self.canvas.set_pixel(x, y, HAIR[idx])

        # Highlight blob
        self._organic_blob(cx - 2 * self.s, by - br * 0.4, 3.5 * self.s, 3 * self.s, HAIR[1], 0.25)

    def _body(self):
        """Shoulders and robe."""
        cx = self.cx
        top = self.cy + int(self.face_r * 0.55)

        for y in range(top, self.size):
            prog = (y - top) / max(1, self.size - top)
            hw = int(self.face_r * (0.65 + prog * 1.5))

            for x in range(cx - hw, cx + hw + 1):
                if 0 <= x < self.size:
                    rel_x = (x - cx) / max(1, hw)

                    # Smooth cloth shading
                    shade = 0.35 + rel_x * 0.18 + prog * 0.12
                    shade = round(shade * 4) / 4  # Slight quantize
                    shade = max(0.1, min(0.9, shade))

                    idx = int(shade * 5)
                    self.canvas.set_pixel(x, y, ROBE[idx])

        self._book()

    def _book(self):
        """Book in hands."""
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
                    c = cover_hi if x < cx - bw // 3 else cover
                    self.canvas.set_pixel(x, y, c)

        # Pages
        m = int(2 * self.s)
        for y in range(bt + m, min(self.size, bt + bh - m)):
            for x in range(cx - bw + m + 2, cx + bw - m - 2):
                if 0 <= x < self.size:
                    self.canvas.set_pixel(x, y, pages)

    def _face(self):
        """Cute round face."""
        cx = self.cx
        cy = self.cy + int(2 * self.s)
        fr = self.face_r

        for y in range(self.size):
            for x in range(self.size):
                dx = (x - cx) / fr
                dy = (y - cy) / fr
                d = dx*dx + dy*dy

                if d < 1.0:
                    # Smooth shading
                    shade = 0.25 - dx * 0.08 - dy * 0.1 + math.sqrt(d) * 0.12
                    shade = max(0.1, min(0.7, shade))
                    idx = int(shade * 5)
                    self.canvas.set_pixel(x, y, SKIN[idx])

        # Neck
        nw = int(fr * 0.26)
        for y in range(cy + int(fr * 0.7), cy + int(fr * 0.88)):
            for x in range(cx - nw, cx + nw):
                if 0 <= x < self.size:
                    self.canvas.set_pixel(x, y, SKIN[3])

        # Blush
        blush = hex_to_rgba('#ff8878')
        for side in [-1, 1]:
            bx = cx + side * int(fr * 0.52)
            by = cy + int(fr * 0.32)
            br = int(fr * 0.2)

            for y in range(by - br, by + br + 1):
                for x in range(bx - br, bx + br + 1):
                    d = dist(x, y, bx, by)
                    if d < br and 0 <= x < self.size and 0 <= y < self.size:
                        alpha = int(45 * (1 - d/br))
                        self.canvas.set_pixel(x, y, (blush[0], blush[1], blush[2], alpha))

    def _eyes(self, expr):
        """Big anime eyes."""
        cx, cy = self.cx, self.cy
        ey = cy - int(self.face_r * 0.08)
        er = self.eye_r

        er_v = er
        if expr == 'surprised':
            er_v = int(er * 1.2)
        elif expr == 'thinking':
            er_v = int(er * 0.82)

        for side in [-1, 1]:
            ex = cx + side * self.eye_sep

            # White
            for y in range(ey - er_v - 1, ey + er_v + 2):
                for x in range(ex - er - 1, ex + er + 2):
                    dx = (x - ex) / (er + 0.5)
                    dy = (y - ey) / (er_v + 0.5)
                    if dx*dx + dy*dy <= 1:
                        self.canvas.set_pixel(x, y, (255, 255, 255, 255))

            # Iris
            ir = int(er * 0.78)
            ix = ex + side * int(1 * self.s)

            iris = [
                hex_to_rgba('#8098b8'),
                hex_to_rgba('#6080a0'),
                hex_to_rgba('#506888'),
                hex_to_rgba('#405068'),
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

            # Catchlights
            white = (255, 255, 255, 255)
            hx, hy = int(ix - 3 * self.s), int(ey - 3 * self.s)
            for dy in range(-1, 2):
                for dx in range(-1, 2):
                    self.canvas.set_pixel(hx + dx, hy + dy, white)
            self.canvas.set_pixel(hx - 1, hy - 1, white)
            self.canvas.set_pixel(hx + 1, hy - 1, white)

            hx2, hy2 = int(ix + 2 * self.s), int(ey + 2.5 * self.s)
            self.canvas.set_pixel(hx2, hy2, white)
            self.canvas.set_pixel(hx2 + 1, hy2, (255, 255, 255, 200))

            # Eyelid
            for x in range(ex - er - 1, ex + er + 2):
                if 0 <= x < self.size:
                    self.canvas.set_pixel(x, ey - er_v - 1, SKIN[4])

    def _details(self, expr):
        """Nose, mouth, eyebrows, glasses."""
        cx, cy = self.cx, self.cy
        fr = self.face_r

        # Nose
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
        """Bangs and side strands."""
        cx, cy = self.cx, self.cy
        fr = self.face_r

        # Bangs
        bangs = [
            (-0.55, 0.58, 2.8),
            (-0.3, 0.72, 3.2),
            (-0.05, 0.8, 3.2),
            (0.2, 0.72, 2.8),
            (0.45, 0.55, 2.2),
        ]

        for bx_off, length_r, width in bangs:
            bx = cx + int(bx_off * fr)
            by_start = cy - fr - int(3 * self.s)
            length = int(length_r * fr * 0.5)
            w = int(width * self.s)

            for j in range(length):
                prog = j / length
                wave = math.sin(j * 0.35 + bx_off * 3) * self.s * 0.8

                # Gradient coloring
                base = 3 + int(prog * 3)
                base = min(7, base)

                for dx in range(-w, w + 1):
                    x = int(bx + wave + dx)
                    y = by_start + j
                    if 0 <= x < self.size and 0 <= y < self.size:
                        idx = base - 1 if abs(dx) <= 1 else base
                        self.canvas.set_pixel(x, y, HAIR[max(1, idx)])

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

                    base = 4 + strand + int(prog * 2.5)
                    base = min(10, base)

                    for dx in range(-w, w + 1):
                        x = int(sx + wave + dx * 0.8)
                        y = sy + j
                        if 0 <= x < self.size and 0 <= y < self.size:
                            idx = max(2, base - 1) if abs(dx) <= 1 else base
                            self.canvas.set_pixel(x, y, HAIR[idx])

    def _sparkles(self):
        """Highlight sparkles."""
        cx = self.cx
        cy = self.cy - int(10 * self.s)
        hr = self.hair_r

        sparkles = [
            (cx - int(10 * self.s), cy - int(hr * 0.3)),
            (cx + int(6 * self.s), cy - int(hr * 0.45)),
            (cx - int(3 * self.s), cy - int(hr * 0.62)),
        ]

        white = (255, 255, 255, 255)
        for sx, sy in sparkles:
            if 0 <= sx < self.size and 0 <= sy < self.size:
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

    print("=== Lyra V10 - Soft Chunky ===\n")

    for expr in ['neutral', 'encouraging', 'thinking', 'surprised', 'concerned']:
        print(f"  {expr}...")
        g = LyraV10(128, 42)
        g.generate(expr)
        g.save(os.path.join(out, f'lyra_v10_{expr}.png'))

    print("\n  256px...")
    g = LyraV10(256, 42)
    g.generate('neutral')
    g.save(os.path.join(out, 'lyra_v10_neutral_256.png'))

    print("\nDone!")
