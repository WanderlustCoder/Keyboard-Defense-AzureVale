#!/usr/bin/env python3
"""
Lyra Portrait Generator V11 - Matching Reference Style
Key changes from V10:
- Hue-shifted hair palette (pink highlights → blue-purple shadows)
- More organic fluffy hair silhouette
- Proportions closer to reference (smaller eyes, fluffier hair)
- Better chunk-based shading with visible color regions
"""

import math
import random
from png_writer import Canvas, hex_to_rgba, Color


# Hair palette with HUE SHIFTING (pink-white → lavender → purple → blue-purple)
HAIR = [
    hex_to_rgba('#fff0f8'),  # 0 - Pink-white highlight
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

# Warm orange skin (like reference)
SKIN = [
    hex_to_rgba('#fff0e0'),  # 0 - Highlight
    hex_to_rgba('#ffd8b8'),  # 1 - Light
    hex_to_rgba('#f0c090'),  # 2 - Peach
    hex_to_rgba('#e0a070'),  # 3 - Mid orange
    hex_to_rgba('#d08050'),  # 4 - Shadow
    hex_to_rgba('#b06038'),  # 5 - Deep shadow
]

# Blue robe
ROBE = [
    hex_to_rgba('#8090a8'),  # 0 - Highlight
    hex_to_rgba('#607898'),  # 1 - Light
    hex_to_rgba('#506080'),  # 2 - Mid
    hex_to_rgba('#405068'),  # 3 - Dark
    hex_to_rgba('#304058'),  # 4 - Shadow
    hex_to_rgba('#203040'),  # 5 - Deep
]

BG = hex_to_rgba('#181830')
GOLD = [hex_to_rgba('#d8a860'), hex_to_rgba('#b88848'), hex_to_rgba('#907038')]


def dist(x1, y1, x2, y2):
    return math.sqrt((x2-x1)**2 + (y2-y1)**2)


class LyraV11:
    def __init__(self, size=128, seed=42):
        self.size = size
        self.s = size / 128
        self.seed = seed
        random.seed(seed)

        self.cx = size // 2
        self.cy = int(size * 0.5)  # Slightly higher

        # Proportions matching reference better
        self.face_r = int(14 * self.s)  # Medium face
        self.eye_r = int(7 * self.s)    # Smaller eyes (reference has smaller)
        self.eye_sep = int(8 * self.s)
        self.hair_r = int(32 * self.s)  # Big fluffy hair

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

    def _in_hair(self, x, y, cx, cy, hr):
        """Check if point is in the fluffy hair shape."""
        dx = (x - cx) / hr
        dy = (y - cy) / (hr * 0.85)

        # Multi-frequency bumps for fluffy look
        angle = math.atan2(y - cy, x - cx)

        bump = 0.0
        bump += math.sin(angle * 4 + 0.5) * 0.12
        bump += math.sin(angle * 7 + 1.0) * 0.08
        bump += math.sin(angle * 11) * 0.05
        bump += math.sin(angle * 16 + 0.3) * 0.03

        # Extra poof on top and sides
        if dy < -0.2:
            bump += 0.15
        bump += abs(math.cos(angle)) * 0.1

        d = math.sqrt(dx*dx + dy*dy)
        return d < (1.0 + bump)

    def _hair_back(self):
        """Draw fluffy hair with chunky color regions."""
        cx = self.cx
        cy = self.cy - int(8 * self.s)
        hr = self.hair_r

        # First pass: Base with chunk shading
        for y in range(self.size):
            for x in range(self.size):
                if not self._in_hair(x, y, cx, cy, hr):
                    continue

                # Skip face area
                face_d = dist(x, y, self.cx, self.cy + int(2 * self.s))
                if face_d < self.face_r - 2:
                    continue

                dx = (x - cx) / hr
                dy = (y - cy) / (hr * 0.85)
                d = math.sqrt(dx*dx + dy*dy)

                # Compute shade with chunk boundaries
                # Light from upper-left
                light_value = -dx * 0.3 - dy * 0.4 + d * 0.25

                # QUANTIZE to create chunky look (key for pixel art feel!)
                # Using 5 levels creates visible bands
                light_value = round(light_value * 5) / 5

                # Map to palette index
                shade = 0.45 + light_value
                shade = max(0.15, min(0.9, shade))
                idx = int(shade * 11)

                self.canvas.set_pixel(x, y, HAIR[idx])

        # Second pass: Deliberate highlight regions
        self._paint_highlights(cx, cy, hr)

        # Third pass: Shadow regions
        self._paint_shadows(cx, cy, hr)

        # Bun
        self._bun(cx, cy - hr * 0.55)

    def _paint_highlights(self, cx, cy, hr):
        """Paint chunky highlight areas."""
        # Each highlight: (x, y, rx, ry, color_idx)
        highlights = [
            # Main upper-left highlight zone
            (cx - hr * 0.4, cy - hr * 0.25, 9, 6, 2),
            (cx - hr * 0.35, cy - hr * 0.32, 6, 4, 1),
            # Center highlight
            (cx - hr * 0.15, cy - hr * 0.4, 7, 5, 3),
            # Left side highlight
            (cx - hr * 0.55, cy - hr * 0.08, 5, 6, 4),
            # Top highlights
            (cx + hr * 0.05, cy - hr * 0.5, 6, 4, 3),
            # Subtle right rim light
            (cx + hr * 0.5, cy - hr * 0.25, 4, 5, 6),
        ]

        for hx, hy, rx, ry, idx in highlights:
            rx = int(rx * self.s)
            ry = int(ry * self.s)
            self._paint_region(hx, hy, rx, ry, HAIR[idx])

    def _paint_shadows(self, cx, cy, hr):
        """Paint chunky shadow areas."""
        shadows = [
            # Right side shadows
            (cx + hr * 0.42, cy + hr * 0.1, 7, 6, 8),
            (cx + hr * 0.5, cy - hr * 0.1, 5, 5, 9),
            # Bottom shadows
            (cx + hr * 0.2, cy + hr * 0.32, 6, 4, 9),
            (cx - hr * 0.2, cy + hr * 0.35, 5, 4, 8),
            # Deep corner shadow
            (cx + hr * 0.35, cy + hr * 0.25, 4, 4, 10),
        ]

        for sx, sy, rx, ry, idx in shadows:
            rx = int(rx * self.s)
            ry = int(ry * self.s)
            self._paint_region(sx, sy, rx, ry, HAIR[idx])

    def _paint_region(self, cx, cy, rx, ry, color):
        """Paint an organic region with slightly irregular edges."""
        for y in range(int(cy - ry - 1), int(cy + ry + 2)):
            for x in range(int(cx - rx - 1), int(cx + rx + 2)):
                if 0 <= x < self.size and 0 <= y < self.size:
                    dx = (x - cx) / max(rx, 1)
                    dy = (y - cy) / max(ry, 1)

                    # Irregular edge
                    angle = math.atan2(dy, dx)
                    wobble = 1.0 + math.sin(angle * 4 + cx * 0.05) * 0.2

                    if dx*dx + dy*dy < wobble:
                        self.canvas.set_pixel(x, y, color)

    def _bun(self, cx, by):
        """Hair bun with shading."""
        br = int(10 * self.s)

        for y in range(int(by - br), int(by + br) + 1):
            for x in range(int(cx - br), int(cx + br) + 1):
                d = dist(x, y, cx, by)
                if d < br:
                    rel_x = (x - cx) / br
                    rel_y = (y - by) / br

                    # Chunky shading
                    shade = 0.4 - rel_x * 0.2 - rel_y * 0.25 + (d/br) * 0.15
                    shade = round(shade * 4) / 4  # Quantize
                    shade = max(0.15, min(0.85, shade))
                    idx = int(shade * 11)

                    self.canvas.set_pixel(x, y, HAIR[idx])

        # Highlight on bun
        self._paint_region(cx - 2 * self.s, by - br * 0.35, 3 * self.s, 2.5 * self.s, HAIR[1])

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

                    # Chunky cloth shading
                    shade = 0.3 + rel_x * 0.2 + prog * 0.15
                    shade = round(shade * 4) / 4
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
                    # Smooth shading with slight quantization
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
        """Anime eyes (proportionally sized like reference)."""
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

            # Secondary catchlight
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

                # Color gradient
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

    print("=== Lyra V11 - Reference Style Match ===\n")

    for expr in ['neutral', 'encouraging', 'thinking', 'surprised', 'concerned']:
        print(f"  {expr}...")
        g = LyraV11(128, 42)
        g.generate(expr)
        g.save(os.path.join(out, f'lyra_v11_{expr}.png'))

    print("\n  256px...")
    g = LyraV11(256, 42)
    g.generate('neutral')
    g.save(os.path.join(out, 'lyra_v11_neutral_256.png'))

    print("\nDone!")
