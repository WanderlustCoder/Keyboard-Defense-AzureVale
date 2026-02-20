#!/usr/bin/env python3
"""
Lyra Portrait Generator V12 - Unified Fluffy Hair
Key changes from V11:
- Integrated shading (no separate overlay blobs that create patches)
- Smoother color flow within hair while keeping chunky feel
- Better rim lighting
- More cohesive hair mass
"""

import math
import random
from png_writer import Canvas, hex_to_rgba, Color


# Hair palette with hue shift
HAIR = [
    hex_to_rgba('#fff0f8'),  # 0 - Pink-white
    hex_to_rgba('#f8e0f0'),  # 1 - Light pink
    hex_to_rgba('#e8d0e8'),  # 2 - Lavender pink
    hex_to_rgba('#d8c0e0'),  # 3 - Light lavender
    hex_to_rgba('#c8a8d8'),  # 4 - Lavender
    hex_to_rgba('#b090c8'),  # 5 - Mid purple
    hex_to_rgba('#9878b8'),  # 6 - Purple
    hex_to_rgba('#8060a8'),  # 7 - Darker purple
    hex_to_rgba('#685098'),  # 8 - Blue-purple
    hex_to_rgba('#504080'),  # 9 - Dark blue-purple
    hex_to_rgba('#403068'),  # 10 - Deep shadow
    hex_to_rgba('#302050'),  # 11 - Darkest
]

SKIN = [
    hex_to_rgba('#fff0e0'),
    hex_to_rgba('#ffd8b8'),
    hex_to_rgba('#f0c090'),
    hex_to_rgba('#e0a070'),
    hex_to_rgba('#d08050'),
    hex_to_rgba('#b06038'),
]

ROBE = [
    hex_to_rgba('#8090a8'),
    hex_to_rgba('#607898'),
    hex_to_rgba('#506080'),
    hex_to_rgba('#405068'),
    hex_to_rgba('#304058'),
    hex_to_rgba('#203040'),
]

BG = hex_to_rgba('#181830')
GOLD = [hex_to_rgba('#d8a860'), hex_to_rgba('#b88848'), hex_to_rgba('#907038')]


def dist(x1, y1, x2, y2):
    return math.sqrt((x2-x1)**2 + (y2-y1)**2)


def smoothstep(edge0, edge1, x):
    t = max(0, min(1, (x - edge0) / (edge1 - edge0)))
    return t * t * (3 - 2 * t)


class LyraV12:
    def __init__(self, size=128, seed=42):
        self.size = size
        self.s = size / 128
        self.seed = seed
        random.seed(seed)

        self.cx = size // 2
        self.cy = int(size * 0.5)

        self.face_r = int(14 * self.s)
        self.eye_r = int(7 * self.s)
        self.eye_sep = int(8 * self.s)
        self.hair_r = int(32 * self.s)

    def generate(self, expr='neutral'):
        self.canvas = Canvas(self.size, self.size, BG)

        self._hair()
        self._body()
        self._face()
        self._eyes(expr)
        self._details(expr)
        self._hair_front()
        self._sparkles()

        return self.canvas

    def _hair_in_shape(self, x, y, cx, cy, hr):
        """Check if point is in fluffy hair silhouette."""
        dx = (x - cx) / hr
        dy = (y - cy) / (hr * 0.85)

        angle = math.atan2(y - cy, x - cx)

        # Multiple frequencies for organic bumps
        bump = 0.0
        bump += math.sin(angle * 4 + 0.5) * 0.11
        bump += math.sin(angle * 7 + 1.0) * 0.07
        bump += math.sin(angle * 11) * 0.04
        bump += math.sin(angle * 15 + 0.3) * 0.025

        # Extra volume at top and sides
        if dy < -0.2:
            bump += 0.12
        bump += abs(math.cos(angle)) * 0.08

        d = math.sqrt(dx*dx + dy*dy)
        return d < (1.0 + bump), d, angle

    def _hair(self):
        """Draw hair with unified chunky shading."""
        cx = self.cx
        cy = self.cy - int(8 * self.s)
        hr = self.hair_r

        for y in range(self.size):
            for x in range(self.size):
                in_hair, d, angle = self._hair_in_shape(x, y, cx, cy, hr)
                if not in_hair:
                    continue

                # Skip face area
                face_d = dist(x, y, self.cx, self.cy + int(2 * self.s))
                if face_d < self.face_r - 2:
                    continue

                dx = (x - cx) / hr
                dy = (y - cy) / (hr * 0.85)

                # UNIFIED lighting calculation
                # Light from upper-left (like reference)
                light = -dx * 0.35 - dy * 0.45

                # Add subtle variation based on position (for texture)
                # This creates soft "bands" without hard blob edges
                local_var = math.sin(x * 0.3 + y * 0.2) * 0.08
                local_var += math.sin(angle * 6) * 0.05

                # Edge darkening
                edge_dark = smoothstep(0.5, 1.0, d) * 0.25

                # Rim light on right edge (subtle)
                rim = 0.0
                if dx > 0.4 and abs(dy) < 0.5:
                    rim = smoothstep(0.4, 0.8, dx) * 0.15

                # Combine all lighting
                shade = 0.45 + light + local_var + edge_dark - rim

                # QUANTIZE for chunky pixel art look
                # 6 levels gives nice visible bands
                shade = round(shade * 6) / 6
                shade = max(0.12, min(0.92, shade))

                idx = int(shade * 11)
                self.canvas.set_pixel(x, y, HAIR[idx])

        # Bun on top
        self._bun(cx, cy - hr * 0.55)

        # Additional highlight touches
        self._hair_highlights(cx, cy, hr)

    def _hair_highlights(self, cx, cy, hr):
        """Add a few strategic bright highlights."""
        # Small bright spots (not big blobs)
        spots = [
            (cx - hr * 0.35, cy - hr * 0.3, 3, 1),
            (cx - hr * 0.2, cy - hr * 0.42, 2.5, 2),
            (cx - hr * 0.45, cy - hr * 0.1, 2, 2),
        ]

        for hx, hy, r, idx in spots:
            r = int(r * self.s)
            for dy in range(-r, r + 1):
                for dx in range(-r, r + 1):
                    if dx*dx + dy*dy <= r*r:
                        px, py = int(hx + dx), int(hy + dy)
                        if 0 <= px < self.size and 0 <= py < self.size:
                            self.canvas.set_pixel(px, py, HAIR[idx])

    def _bun(self, cx, by):
        """Hair bun."""
        br = int(10 * self.s)

        for y in range(int(by - br), int(by + br) + 1):
            for x in range(int(cx - br), int(cx + br) + 1):
                d = dist(x, y, cx, by)
                if d < br:
                    rel_x = (x - cx) / br
                    rel_y = (y - by) / br

                    shade = 0.4 - rel_x * 0.2 - rel_y * 0.25 + (d/br) * 0.15
                    shade = round(shade * 5) / 5
                    shade = max(0.15, min(0.85, shade))
                    idx = int(shade * 11)

                    self.canvas.set_pixel(x, y, HAIR[idx])

        # Bright highlight on bun
        hx, hy = int(cx - 2 * self.s), int(by - br * 0.35)
        for dy in range(-1, 2):
            for dx in range(-1, 2):
                if abs(dx) + abs(dy) <= 1:
                    self.canvas.set_pixel(hx + dx, hy + dy, HAIR[1])

    def _body(self):
        """Shoulders and robe."""
        cx = self.cx
        top = self.cy + int(self.face_r * 0.6)

        for y in range(top, self.size):
            prog = (y - top) / max(1, self.size - top)
            hw = int(self.face_r * (0.7 + prog * 1.4))

            for x in range(cx - hw, cx + hw + 1):
                if 0 <= x < self.size:
                    rel_x = (x - cx) / max(1, hw)

                    shade = 0.3 + rel_x * 0.2 + prog * 0.12
                    shade = round(shade * 5) / 5
                    shade = max(0.1, min(0.9, shade))
                    idx = int(shade * 5)

                    self.canvas.set_pixel(x, y, ROBE[idx])

        self._book()

    def _book(self):
        """Book in hands."""
        cx = self.cx
        bt = self.cy + int(self.face_r * 0.85)
        bh = int(self.face_r * 0.55)
        bw = int(self.face_r * 1.0)

        cover = hex_to_rgba('#8b5a2b')
        cover_hi = hex_to_rgba('#a06830')
        pages = hex_to_rgba('#f8f0e0')

        for y in range(bt, min(self.size, bt + bh)):
            for x in range(cx - bw, cx + bw):
                if 0 <= x < self.size:
                    c = cover_hi if x < cx - bw // 3 else cover
                    self.canvas.set_pixel(x, y, c)

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
                    shade = 0.25 - dx * 0.1 - dy * 0.12 + math.sqrt(d) * 0.15
                    shade = max(0.1, min(0.7, shade))
                    idx = int(shade * 5)
                    self.canvas.set_pixel(x, y, SKIN[idx])

        # Neck
        nw = int(fr * 0.28)
        for y in range(cy + int(fr * 0.68), cy + int(fr * 0.85)):
            for x in range(cx - nw, cx + nw):
                if 0 <= x < self.size:
                    self.canvas.set_pixel(x, y, SKIN[3])

        # Blush
        blush = hex_to_rgba('#f08070')
        for side in [-1, 1]:
            bx = cx + side * int(fr * 0.5)
            by = cy + int(fr * 0.3)
            br = int(fr * 0.22)

            for y in range(by - br, by + br + 1):
                for x in range(bx - br, bx + br + 1):
                    d = dist(x, y, bx, by)
                    if d < br and 0 <= x < self.size and 0 <= y < self.size:
                        alpha = int(50 * (1 - d/br) ** 1.2)
                        self.canvas.set_pixel(x, y, (blush[0], blush[1], blush[2], alpha))

    def _eyes(self, expr):
        """Anime eyes."""
        cx, cy = self.cx, self.cy
        ey = cy - int(self.face_r * 0.02)
        er = self.eye_r

        er_v = er
        if expr == 'surprised':
            er_v = int(er * 1.15)
        elif expr == 'thinking':
            er_v = int(er * 0.85)

        for side in [-1, 1]:
            ex = cx + side * self.eye_sep

            # White
            for y in range(ey - er_v, ey + er_v + 1):
                for x in range(ex - er, ex + er + 1):
                    dx = (x - ex) / er
                    dy = (y - ey) / er_v
                    if dx*dx + dy*dy <= 1:
                        self.canvas.set_pixel(x, y, (255, 255, 255, 255))

            # Iris
            ir = int(er * 0.72)
            ix = ex + side * int(0.5 * self.s)

            iris = [
                hex_to_rgba('#7090a8'),
                hex_to_rgba('#587898'),
                hex_to_rgba('#486080'),
                hex_to_rgba('#385060'),
            ]

            for y in range(ey - ir, ey + ir + 1):
                for x in range(ix - ir, ix + ir + 1):
                    d = dist(x, y, ix, ey)
                    if d < ir:
                        prog = (y - (ey - ir)) / (ir * 2)
                        idx = int(prog * 3.5)
                        self.canvas.set_pixel(x, y, iris[min(3, idx)])

            # Pupil
            pr = int(ir * 0.45)
            pupil = hex_to_rgba('#101820')
            for y in range(ey - pr, ey + pr + 1):
                for x in range(ix - pr, ix + pr + 1):
                    if dist(x, y, ix, ey) < pr:
                        self.canvas.set_pixel(x, y, pupil)

            # Catchlights
            white = (255, 255, 255, 255)
            hx, hy = int(ix - 2 * self.s), int(ey - 2 * self.s)
            for dy in range(-1, 2):
                for dx in range(-1, 2):
                    if abs(dx) + abs(dy) <= 1:
                        self.canvas.set_pixel(hx + dx, hy + dy, white)

            self.canvas.set_pixel(int(ix + 1.5 * self.s), int(ey + 2 * self.s), white)

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
        my = cy + int(fr * 0.45)
        mw = int(fr * 0.25)
        mc = SKIN[5]

        if expr in ['neutral', 'thinking']:
            for i in range(-mw, mw + 1):
                curve = int((i*i) / (mw * 1.5))
                self.canvas.set_pixel(cx + i, my + curve, mc)
        elif expr == 'encouraging':
            mw = int(mw * 1.2)
            for i in range(-mw, mw + 1):
                curve = int((i*i) / (mw * 1.1))
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
        bl = int(5 * self.s)
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
                if 0 <= x < self.size and 0 <= y < self.size:
                    self.canvas.set_pixel(x, y, HAIR[7])
                    self.canvas.set_pixel(x, y + 1, HAIR[9])

        # Glasses
        ey = cy - int(fr * 0.02)
        lr = self.eye_r + int(2 * self.s)

        for side in [-1, 1]:
            lx = cx + side * self.eye_sep

            for a in range(0, 360, 5):
                rad = math.radians(a)
                for t in range(int(1.5 * self.s) + 1):
                    px = int(lx + math.cos(rad) * (lr + t))
                    py = int(ey + math.sin(rad) * (lr + t))

                    c = GOLD[0] if (a < 180 and t == 0) else GOLD[1] if t == 0 else GOLD[2]
                    if 0 <= px < self.size and 0 <= py < self.size:
                        self.canvas.set_pixel(px, py, c)

        # Bridge
        for x in range(cx - int(2 * self.s), cx + int(2 * self.s) + 1):
            self.canvas.set_pixel(x, ey, GOLD[1])

        # Arms
        for side in [-1, 1]:
            sx = cx + side * (self.eye_sep + lr + 1)
            for i in range(int(7 * self.s)):
                x = sx + side * i
                if 0 <= x < self.size:
                    self.canvas.set_pixel(x, ey + i // 4, GOLD[1])

    def _hair_front(self):
        """Bangs and side strands."""
        cx, cy = self.cx, self.cy
        fr = self.face_r

        # Bangs
        bangs = [
            (-0.5, 0.55, 3),
            (-0.25, 0.7, 3.5),
            (0.0, 0.75, 3.5),
            (0.25, 0.65, 3),
            (0.45, 0.5, 2.5),
        ]

        for bx_off, length_r, width in bangs:
            bx = cx + int(bx_off * fr)
            by_start = cy - fr - int(2 * self.s)
            length = int(length_r * fr * 0.5)
            w = int(width * self.s)

            for j in range(length):
                prog = j / length
                wave = math.sin(j * 0.4 + bx_off * 3) * self.s * 0.6

                base = 3 + int(prog * 3)
                base = min(7, base)

                for dx in range(-w, w + 1):
                    x = int(bx + wave + dx)
                    y = by_start + j
                    if 0 <= x < self.size and 0 <= y < self.size:
                        idx = max(1, base - 1) if abs(dx) <= 1 else base
                        self.canvas.set_pixel(x, y, HAIR[idx])

        # Side strands
        for side in [-1, 1]:
            base_x = cx + side * (fr + int(4 * self.s))
            base_y = cy - int(fr * 0.3)

            for strand in range(3):
                sx = base_x + side * strand * int(2 * self.s)
                sy = base_y + strand * int(2 * self.s)
                length = int((18 - strand * 3) * self.s)
                w = int((2.5 - strand * 0.5) * self.s)

                for j in range(length):
                    prog = j / length
                    wave = math.sin(j * 0.12 + strand * 0.8) * 2 * self.s

                    base = 4 + strand + int(prog * 2.5)
                    base = min(10, base)

                    for dx in range(-w, w + 1):
                        x = int(sx + wave + dx * 0.7)
                        y = sy + j
                        if 0 <= x < self.size and 0 <= y < self.size:
                            idx = max(2, base - 1) if abs(dx) <= 1 else base
                            self.canvas.set_pixel(x, y, HAIR[idx])

    def _sparkles(self):
        """Highlight sparkles."""
        cx = self.cx
        cy = self.cy - int(8 * self.s)
        hr = self.hair_r

        sparkles = [
            (cx - int(9 * self.s), cy - int(hr * 0.28)),
            (cx + int(5 * self.s), cy - int(hr * 0.4)),
            (cx - int(2 * self.s), cy - int(hr * 0.55)),
        ]

        white = (255, 255, 255, 255)
        for sx, sy in sparkles:
            if 0 <= sx < self.size and 0 <= sy < self.size:
                self.canvas.set_pixel(sx, sy, white)
                for ddx, ddy in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
                    px, py = sx + ddx, sy + ddy
                    if 0 <= px < self.size and 0 <= py < self.size:
                        self.canvas.set_pixel(px, py, (255, 255, 255, 180))

    def save(self, path):
        self.canvas.save(path)


if __name__ == "__main__":
    import os
    out = os.path.dirname(os.path.abspath(__file__))

    print("=== Lyra V12 - Unified Fluffy Hair ===\n")

    for expr in ['neutral', 'encouraging', 'thinking', 'surprised', 'concerned']:
        print(f"  {expr}...")
        g = LyraV12(128, 42)
        g.generate(expr)
        g.save(os.path.join(out, f'lyra_v12_{expr}.png'))

    print("\n  256px...")
    g = LyraV12(256, 42)
    g.generate('neutral')
    g.save(os.path.join(out, 'lyra_v12_neutral_256.png'))

    print("\nDone!")
