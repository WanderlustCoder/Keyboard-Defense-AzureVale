#!/usr/bin/env python3
"""
Lyra Portrait Generator V7 - Organic & Fluffy
Focus on:
- Organic bumpy hair silhouette using noise
- Clustered color placement mimicking hand-painting
- Fluffy, cloud-like hair texture
- Fixed robe (no stripes)
- More charm and cuteness
"""

import math
import random
from png_writer import Canvas, hex_to_rgba, lerp_color, Color


# Simple color lists
HAIR_COLORS = [
    hex_to_rgba('#fff0ff'),  # 0 - Brightest
    hex_to_rgba('#f0d8f8'),  # 1 - Very light
    hex_to_rgba('#e0c0f0'),  # 2 - Light
    hex_to_rgba('#c8a0e0'),  # 3 - Mid-light
    hex_to_rgba('#b080d0'),  # 4 - Mid
    hex_to_rgba('#9060b8'),  # 5 - Mid-dark
    hex_to_rgba('#7040a0'),  # 6 - Dark
    hex_to_rgba('#502080'),  # 7 - Darker
    hex_to_rgba('#381060'),  # 8 - Shadow
    hex_to_rgba('#200840'),  # 9 - Deep shadow
]

SKIN_COLORS = [
    hex_to_rgba('#fff8e8'),  # 0 - Highlight
    hex_to_rgba('#ffe0c0'),  # 1 - Light
    hex_to_rgba('#f8c090'),  # 2 - Mid-light
    hex_to_rgba('#e8a068'),  # 3 - Mid
    hex_to_rgba('#d08048'),  # 4 - Shadow
    hex_to_rgba('#a06030'),  # 5 - Dark
]

ROBE_COLORS = [
    hex_to_rgba('#7090b8'),  # 0 - Highlight
    hex_to_rgba('#5070a0'),  # 1 - Light
    hex_to_rgba('#405888'),  # 2 - Mid
    hex_to_rgba('#304870'),  # 3 - Dark
    hex_to_rgba('#203858'),  # 4 - Shadow
    hex_to_rgba('#182840'),  # 5 - Deep
]

BG_COLOR = hex_to_rgba('#16162c')
GLASSES_COLORS = [hex_to_rgba('#c89858'), hex_to_rgba('#a07838'), hex_to_rgba('#805820')]


def noise2d(x, y, seed=0):
    """Simple 2D noise function."""
    n = int(x * 12.9898 + y * 78.233 + seed * 43.12)
    n = (n * 43758) & 0xFFFFFF
    return (n % 1000) / 1000.0


def smooth_noise(x, y, seed=0):
    """Smoothed noise."""
    ix, iy = int(x), int(y)
    fx, fy = x - ix, y - iy
    fx = fx * fx * (3 - 2 * fx)
    fy = fy * fy * (3 - 2 * fy)

    n00 = noise2d(ix, iy, seed)
    n10 = noise2d(ix + 1, iy, seed)
    n01 = noise2d(ix, iy + 1, seed)
    n11 = noise2d(ix + 1, iy + 1, seed)

    nx0 = n00 * (1 - fx) + n10 * fx
    nx1 = n01 * (1 - fx) + n11 * fx
    return nx0 * (1 - fy) + nx1 * fy


def fbm(x, y, octaves=4, seed=0):
    """Fractal noise."""
    value = 0
    amp = 1
    freq = 1
    for i in range(octaves):
        value += smooth_noise(x * freq, y * freq, seed + i * 100) * amp
        amp *= 0.5
        freq *= 2
    return value / 1.875  # Normalize


def dist(x1, y1, x2, y2):
    return math.sqrt((x2-x1)**2 + (y2-y1)**2)


class LyraV7:
    def __init__(self, size=128, seed=42):
        self.size = size
        self.s = size / 128
        self.seed = seed
        random.seed(seed)

        self.cx = size // 2
        self.cy = int(size * 0.52)

        self.face_r = int(16 * self.s)
        self.eye_r = int(7 * self.s)
        self.eye_sep = int(9 * self.s)
        self.hair_r = int(28 * self.s)

    def generate(self, expr='neutral'):
        self.canvas = Canvas(self.size, self.size, BG_COLOR)

        self._hair()
        self._body()
        self._face()
        self._eyes(expr)
        self._details(expr)
        self._hair_front()
        self._highlights()

        return self.canvas

    def _in_hair(self, x, y):
        """Check if point is in the organic hair shape."""
        cx = self.cx
        cy = self.cy - int(5 * self.s)
        hr = self.hair_r

        # Base distance from hair center
        dx = (x - cx) / hr
        dy = (y - cy) / (hr * 0.9)
        base_d = math.sqrt(dx*dx + dy*dy)

        # Add noise to make bumpy edges
        angle = math.atan2(y - cy, x - cx)
        bump = fbm(angle * 2, base_d * 3, 3, self.seed) * 0.25
        bump += math.sin(angle * 7) * 0.08  # High frequency bumps
        bump += math.sin(angle * 12) * 0.04

        # Hair extends more on sides
        side_extend = abs(math.cos(angle)) * 0.15

        threshold = 1.0 + bump + side_extend

        # Extra poofs
        if dist(x, y, cx, cy - hr * 0.5) < hr * 0.45:  # Top poof
            return True
        if dist(x, y, cx - hr * 0.5, cy + hr * 0.1) < hr * 0.5:  # Left
            return True
        if dist(x, y, cx + hr * 0.5, cy + hr * 0.1) < hr * 0.5:  # Right
            return True

        return base_d < threshold

    def _hair(self):
        """Draw fluffy hair with organic texture."""
        cx = self.cx
        cy = self.cy - int(5 * self.s)
        hr = self.hair_r

        for y in range(self.size):
            for x in range(self.size):
                if not self._in_hair(x, y):
                    continue

                # Skip face area
                face_d = dist(x, y, self.cx, self.cy + 2)
                if face_d < self.face_r - 1:
                    continue

                # Calculate color based on position + noise
                rel_x = (x - cx) / hr
                rel_y = (y - (cy - hr)) / (hr * 2)

                # Base lighting (top-left light)
                light = (1 - rel_y) * 0.3 + (0.5 - rel_x) * 0.2

                # Add clustered noise for texture
                n1 = fbm(x * 0.15, y * 0.1, 3, self.seed)
                n2 = fbm(x * 0.08 + 50, y * 0.06 + 50, 2, self.seed + 1)

                # Combine for final shade
                shade = 0.4 + light + (n1 - 0.5) * 0.35 + (n2 - 0.5) * 0.2

                # Quantize to create chunky look
                shade = int(shade * 8) / 8.0
                shade = max(0.15, min(0.85, shade))

                # Pick color
                idx = int(shade * (len(HAIR_COLORS) - 1))
                idx = max(0, min(len(HAIR_COLORS) - 1, idx))

                self.canvas.set_pixel(x, y, HAIR_COLORS[idx])

        # Draw bun
        self._bun(cx, cy - hr * 0.55)

    def _bun(self, cx, by):
        br = int(8 * self.s)

        for y in range(int(by - br), int(by + br) + 1):
            for x in range(int(cx - br), int(cx + br) + 1):
                d = dist(x, y, cx, by)
                if d < br:
                    # Spiral pattern
                    angle = math.atan2(y - by, x - cx)
                    nd = d / br
                    spiral = (angle + nd * 4) % (math.pi * 0.5)

                    # Lighting
                    light = (cx - x) / br * 0.15 + (by - y) / br * 0.2

                    shade = 0.35 + nd * 0.15 + light
                    if spiral < math.pi * 0.2:
                        shade -= 0.1

                    idx = int(max(0.1, min(0.8, shade)) * 9)
                    self.canvas.set_pixel(x, y, HAIR_COLORS[idx])

        # Highlight
        hx, hy = int(cx - 2 * self.s), int(by - br * 0.35)
        for dy in range(-1, 2):
            for dx in range(-1, 2):
                if abs(dx) + abs(dy) <= 1:
                    self.canvas.set_pixel(hx + dx, hy + dy, HAIR_COLORS[1])

    def _body(self):
        """Draw shoulders and robe."""
        cx = self.cx
        top = self.cy + int(self.face_r * 0.7)

        for y in range(top, self.size):
            prog = (y - top) / max(1, self.size - top)
            hw = int(self.face_r * (0.8 + prog * 1.3))

            for x in range(cx - hw, cx + hw + 1):
                if 0 <= x < self.size:
                    rel_x = (x - cx) / max(1, hw)

                    # Simple lighting - no stripes!
                    light = (1 - rel_x) * 0.12 + (1 - prog) * 0.18

                    # Subtle cloth texture
                    n = fbm(x * 0.1, y * 0.08, 2, self.seed + 200) * 0.12

                    shade = 0.35 + light + n
                    idx = int(max(0.1, min(0.9, shade)) * 5)

                    self.canvas.set_pixel(x, y, ROBE_COLORS[idx])

        # Book
        self._book()

    def _book(self):
        cx = self.cx
        bt = self.cy + int(self.face_r * 0.9)
        bb = min(self.size - 2, bt + int(self.face_r * 0.45))
        bw = int(self.face_r * 0.95)

        book_color = hex_to_rgba('#805830')
        page_color = hex_to_rgba('#f8f0e0')

        for y in range(bt, bb):
            for x in range(cx - bw, cx + bw):
                if 0 <= x < self.size:
                    self.canvas.set_pixel(x, y, book_color)

        # Pages
        m = int(2 * self.s)
        for y in range(bt + m, bb - m):
            for x in range(cx - bw + m + 2, cx + bw - m - 2):
                if 0 <= x < self.size:
                    self.canvas.set_pixel(x, y, page_color)

    def _face(self):
        """Draw cute round face."""
        cx = self.cx
        cy = self.cy + int(2 * self.s)
        fr = self.face_r

        for y in range(self.size):
            for x in range(self.size):
                # Slightly oval face
                dx = (x - cx) / fr
                dy = (y - cy) / (fr * 1.05)
                d = math.sqrt(dx*dx + dy*dy)

                if d < 1:
                    # Lighting
                    light = (1 - dx) * 0.1 + (1 - dy) * 0.15
                    shade = 0.3 + light + d * 0.1

                    idx = int(max(0.15, min(0.7, shade)) * 5)
                    self.canvas.set_pixel(x, y, SKIN_COLORS[idx])

        # Neck
        nw = int(fr * 0.3)
        for y in range(cy + int(fr * 0.65), cy + int(fr * 0.85)):
            for x in range(cx - nw, cx + nw):
                if 0 <= x < self.size:
                    self.canvas.set_pixel(x, y, SKIN_COLORS[2])

        # Cheek blush
        blush = hex_to_rgba('#f88878')
        for side in [-1, 1]:
            ch_x = cx + side * int(fr * 0.45)
            ch_y = cy + int(fr * 0.25)
            ch_r = int(fr * 0.18)

            for y in range(ch_y - ch_r, ch_y + ch_r + 1):
                for x in range(ch_x - ch_r, ch_x + ch_r + 1):
                    d = dist(x, y, ch_x, ch_y)
                    if d < ch_r:
                        alpha = int(55 * (1 - d/ch_r) ** 1.3)
                        self.canvas.set_pixel(x, y, (blush[0], blush[1], blush[2], alpha))

    def _eyes(self, expr):
        """Big cute anime eyes."""
        cx, cy = self.cx, self.cy
        ey = cy - int(self.face_r * 0.02)
        er = self.eye_r

        er_v = er
        if expr == 'surprised': er_v = int(er * 1.15)
        elif expr == 'thinking': er_v = int(er * 0.8)

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
            ir = int(er * 0.7)
            ix = ex + side * int(0.5 * self.s)

            iris_colors = [
                hex_to_rgba('#6080a0'),
                hex_to_rgba('#4868888'),
                hex_to_rgba('#385060'),
                hex_to_rgba('#283848'),
            ]

            for y in range(ey - ir, ey + ir + 1):
                for x in range(ix - ir, ix + ir + 1):
                    d = dist(x, y, ix, ey)
                    if d < ir:
                        # Gradient top to bottom
                        zy = (y - (ey - ir)) / (ir * 2)
                        idx = int(zy * 3)
                        self.canvas.set_pixel(x, y, iris_colors[min(3, idx)])

            # Pupil
            pr = int(ir * 0.4)
            pupil = hex_to_rgba('#101820')
            for y in range(ey - pr, ey + pr + 1):
                for x in range(ix - pr, ix + pr + 1):
                    if dist(x, y, ix, ey) < pr:
                        self.canvas.set_pixel(x, y, pupil)

            # Catchlights - essential!
            white = (255, 255, 255, 255)
            hx, hy = ix - int(2 * self.s), ey - int(2 * self.s)
            for dy in range(-1, 2):
                for dx in range(-1, 2):
                    if abs(dx) + abs(dy) <= 1:
                        self.canvas.set_pixel(int(hx + dx), int(hy + dy), white)

            # Small secondary
            self.canvas.set_pixel(int(ix + self.s), int(ey + 2 * self.s), (255, 255, 255, 180))

            # Eyelid
            for x in range(ex - er - 1, ex + er + 2):
                self.canvas.set_pixel(x, ey - er_v - 1, SKIN_COLORS[3])

    def _details(self, expr):
        """Nose, mouth, eyebrows, glasses."""
        cx, cy = self.cx, self.cy
        fr = self.face_r

        # Nose
        ny = cy + int(fr * 0.2)
        self.canvas.set_pixel(cx - 1, ny, SKIN_COLORS[3])
        self.canvas.set_pixel(cx, ny + 1, SKIN_COLORS[2])

        # Mouth
        my = cy + int(fr * 0.45)
        mw = int(fr * 0.28)

        if expr in ['neutral', 'thinking']:
            for i in range(-mw, mw + 1):
                curve = int((i*i) / (mw * 1.3))
                self.canvas.set_pixel(cx + i, my + curve, SKIN_COLORS[4])
        elif expr == 'encouraging':
            mw = int(mw * 1.2)
            for i in range(-mw, mw + 1):
                curve = int((i*i) / (mw * 1.1))
                self.canvas.set_pixel(cx + i, my + curve, SKIN_COLORS[4])
        elif expr == 'surprised':
            for a in range(0, 360, 30):
                r = math.radians(a)
                self.canvas.set_pixel(int(cx + math.cos(r)*2*self.s), int(my + 1 + math.sin(r)*1.5*self.s), SKIN_COLORS[4])
        elif expr == 'concerned':
            for i in range(-mw, mw + 1):
                curve = -int((i*i) / (mw * 2)) + 1
                self.canvas.set_pixel(cx + i, my + curve, SKIN_COLORS[4])

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
                    yc = int(prog * 2) * side
                elif expr == 'surprised':
                    yc = int(math.sin(prog * math.pi) * -2)
                else:
                    yc = int(math.sin(prog * math.pi) * -1)

                y = by + y_off + yc
                self.canvas.set_pixel(x, y, HAIR_COLORS[5])
                self.canvas.set_pixel(x, y + 1, HAIR_COLORS[6])

        # Glasses
        ey = cy - int(fr * 0.02)
        lr = self.eye_r + int(2 * self.s)

        for side in [-1, 1]:
            lx = cx + side * self.eye_sep
            for a in range(0, 360, 5):
                r = math.radians(a)
                for t in range(2):
                    px = int(lx + math.cos(r) * (lr + t))
                    py = int(ey + math.sin(r) * (lr + t))
                    idx = 0 if a < 90 or a > 270 else 1
                    if 0 <= px < self.size and 0 <= py < self.size:
                        self.canvas.set_pixel(px, py, GLASSES_COLORS[min(2, idx + t)])

        # Bridge
        for x in range(cx - int(2*self.s), cx + int(2*self.s)):
            self.canvas.set_pixel(x, ey, GLASSES_COLORS[1])

        # Arms
        for side in [-1, 1]:
            sx = cx + side * (self.eye_sep + lr + 1)
            for i in range(int(7 * self.s)):
                x = sx + side * i
                if 0 <= x < self.size:
                    self.canvas.set_pixel(x, ey + i // 3, GLASSES_COLORS[1])

    def _hair_front(self):
        """Bangs and side strands."""
        cx, cy = self.cx, self.cy

        # Bangs
        for i in range(7):
            bx = cx - int(9 * self.s) + i * int(2.8 * self.s)
            by = cy - self.face_r - int(1 * self.s)
            length = int((3 + (i % 3) * 1.5) * self.s)

            for j in range(length):
                wave = math.sin(j * 0.5 + i * 0.4) * self.s
                x = int(bx + wave)
                y = by + j

                if 0 <= x < self.size and 0 <= y < self.size:
                    idx = 2 + (j * 2 // length)
                    self.canvas.set_pixel(x, y, HAIR_COLORS[idx])

        # Side strands
        for side in [-1, 1]:
            for s in range(3):
                sx = cx + side * (self.face_r + int((2 + s * 2) * self.s))
                sy = cy - int(self.face_r * 0.3)

                for j in range(int(18 * self.s)):
                    wave = math.sin(j * 0.12 + s * 0.6) * 2 * self.s
                    x = int(sx + wave)
                    y = sy + j

                    if 0 <= x < self.size and 0 <= y < self.size:
                        idx = 3 + s + (j // int(8 * self.s))
                        idx = min(7, idx)
                        self.canvas.set_pixel(x, y, HAIR_COLORS[idx])
                        self.canvas.set_pixel(x + side, y, HAIR_COLORS[min(8, idx + 1)])

    def _highlights(self):
        """Sparkle highlights in hair."""
        cx = self.cx
        cy = self.cy - int(5 * self.s)
        hr = self.hair_r

        sparkles = [
            (cx - int(6 * self.s), cy - int(hr * 0.35)),
            (cx + int(4 * self.s), cy - int(hr * 0.4)),
            (cx - int(2 * self.s), cy - int(hr * 0.2)),
        ]

        for sx, sy in sparkles:
            if 0 <= sx < self.size and 0 <= sy < self.size:
                # Cross sparkle
                self.canvas.set_pixel(sx, sy, (255, 255, 255, 255))
                for dd in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
                    self.canvas.set_pixel(sx + dd[0], sy + dd[1], (255, 255, 255, 200))

    def save(self, path):
        self.canvas.save(path)


if __name__ == "__main__":
    import os
    out = os.path.dirname(os.path.abspath(__file__))

    print("=== Lyra V7 - Organic & Fluffy ===\n")

    for expr in ['neutral', 'encouraging', 'thinking', 'surprised', 'concerned']:
        print(f"  {expr}...")
        g = LyraV7(128, 42)
        g.generate(expr)
        g.save(os.path.join(out, f'lyra_v7_{expr}.png'))

    print("\n  256px...")
    g = LyraV7(256, 42)
    g.generate('neutral')
    g.save(os.path.join(out, 'lyra_v7_neutral_256.png'))

    print("\nDone!")
