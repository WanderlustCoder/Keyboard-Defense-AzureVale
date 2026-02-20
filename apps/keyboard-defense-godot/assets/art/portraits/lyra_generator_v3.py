#!/usr/bin/env python3
"""
Lyra Portrait Generator V3 - Refined organic shapes
Focus on:
- Rounder, more chibi-like face
- Organic hair silhouette (not blocky)
- Softer, more natural rendering
- Better matching HighRes.png reference
"""

import math
import random
from typing import List, Tuple
from png_writer import Canvas, hex_to_rgba, lerp_color, blend_colors, Color


class ColorRamp:
    def __init__(self, colors: List[str]):
        self.colors = [hex_to_rgba(c) for c in colors]

    def get(self, t: float) -> Color:
        t = max(0.0, min(1.0, t))
        if len(self.colors) == 1:
            return self.colors[0]
        idx = t * (len(self.colors) - 1)
        i = min(int(idx), len(self.colors) - 2)
        frac = idx - i
        return lerp_color(self.colors[i], self.colors[i + 1], frac)


# Refined palettes
PALETTES = {
    'hair': ColorRamp([
        '#f8e8ff', '#e8d0f8', '#d8b8f0', '#c8a0e8',
        '#b080d8', '#9060c0', '#7048a0', '#503080',
        '#382060', '#201040',
    ]),
    'skin': ColorRamp([
        '#fff0e0', '#ffe0c8', '#f8d0b0', '#f0c098',
        '#e0a878', '#c88858', '#a86838', '#804820',
    ]),
    'robe': ColorRamp([
        '#7888b0', '#5868a0', '#405088', '#304070',
        '#203058', '#182040', '#101830',
    ]),
    'glasses': ColorRamp([
        '#d0a070', '#b08050', '#906838', '#705028', '#503818',
    ]),
    'book': ColorRamp([
        '#b08860', '#906840', '#705028', '#503818', '#382810',
    ]),
    'pages': ColorRamp([
        '#fff8f0', '#f0e8d8', '#e0d8c8', '#c8c0b0',
    ]),
    'background': ColorRamp([
        '#1c1c38', '#181830', '#141428', '#101020',
    ]),
    'eye_white': ColorRamp([
        '#ffffff', '#f8f8ff', '#e0e0f0', '#c0c0d0',
    ]),
    'eye_iris': ColorRamp([
        '#708098', '#506078', '#384858', '#203040', '#101820',
    ]),
}


def dist(x1, y1, x2, y2):
    return math.sqrt((x2-x1)**2 + (y2-y1)**2)


def in_ellipse(px, py, cx, cy, rx, ry):
    if rx <= 0 or ry <= 0: return False
    return ((px-cx)/rx)**2 + ((py-cy)/ry)**2 <= 1.0


def ellipse_dist(px, py, cx, cy, rx, ry):
    if rx <= 0 or ry <= 0: return 999
    return math.sqrt(((px-cx)/rx)**2 + ((py-cy)/ry)**2)


def noise(x, y, seed=0):
    n = int(x * 57 + y * 131 + seed * 17)
    n = (n << 13) ^ n
    return ((n * (n * n * 15731 + 789221) + 1376312589) & 0x7fffffff) / 2147483648.0


def smooth_noise(x, y, seed=0):
    x0, y0 = int(x), int(y)
    fx, fy = x - x0, y - y0
    fx, fy = fx*fx*(3-2*fx), fy*fy*(3-2*fy)
    v00 = noise(x0, y0, seed)
    v10 = noise(x0+1, y0, seed)
    v01 = noise(x0, y0+1, seed)
    v11 = noise(x0+1, y0+1, seed)
    return (v00*(1-fx) + v10*fx)*(1-fy) + (v01*(1-fx) + v11*fx)*fy


def fbm(x, y, octaves=3, seed=0):
    total, amp, maxv = 0, 1, 0
    for i in range(octaves):
        total += smooth_noise(x * (2**i), y * (2**i), seed + i) * amp
        maxv += amp
        amp *= 0.5
    return total / maxv


class LyraV3:
    def __init__(self, size=128, seed=42):
        self.size = size
        self.seed = seed
        self.s = size / 128  # scale factor
        random.seed(seed)

        # Position character
        self.cx = size // 2
        self.cy = int(size * 0.48)

        # ROUNDER head - more circular
        self.head_r = int(20 * self.s)  # Base radius for nearly circular head

        # Large anime eyes
        self.eye_r = int(8 * self.s)
        self.eye_sep = int(11 * self.s)

    def generate(self, expr='neutral'):
        self.canvas = Canvas(self.size, self.size, PALETTES['background'].get(0.2))

        self._bg()
        self._hair_mass()
        self._body()
        self._book()
        self._neck()
        self._face()
        self._eyes(expr)
        self._nose()
        self._mouth(expr)
        self._brows(expr)
        self._glasses()
        self._hair_strands()
        self._bun()
        self._sparkles()

        return self.canvas

    def _bg(self):
        for y in range(self.size):
            for x in range(self.size):
                n = fbm(x*0.03, y*0.03, 2, self.seed) * 0.08
                self.canvas.pixels[y][x] = PALETTES['background'].get(0.2 + n)

    def _hair_mass(self):
        """Draw organic hair shape - rounded cloud-like silhouette."""
        cx, cy = self.cx, self.cy
        hr = self.head_r

        for y in range(self.size):
            for x in range(self.size):
                # Create organic hair boundary using multiple overlapping ellipses
                in_hair = False

                # Main hair mass (larger than head, offset upward)
                if in_ellipse(x, y, cx, cy - hr*0.3, hr*1.8, hr*1.6):
                    in_hair = True

                # Left hair bulge
                if in_ellipse(x, y, cx - hr*0.8, cy - hr*0.1, hr*1.1, hr*1.3):
                    in_hair = True

                # Right hair bulge
                if in_ellipse(x, y, cx + hr*0.8, cy - hr*0.1, hr*1.1, hr*1.3):
                    in_hair = True

                # Lower left continuation
                if in_ellipse(x, y, cx - hr*0.6, cy + hr*0.5, hr*0.8, hr*1.0):
                    in_hair = True

                # Lower right continuation
                if in_ellipse(x, y, cx + hr*0.6, cy + hr*0.5, hr*0.8, hr*1.0):
                    in_hair = True

                if not in_hair:
                    continue

                # Skip face area (more generous margin)
                face_d = ellipse_dist(x, y, cx, cy + hr*0.1, hr*0.85, hr*0.95)
                if face_d < 0.85:
                    continue

                # Shading
                rel_y = (y - (cy - hr)) / (hr * 3)
                rel_x = (x - cx) / (hr * 2)

                # Light from top-left
                light = (1 - rel_y) * 0.25 + (0.5 - rel_x) * 0.15

                # Strand-like texture
                strand = fbm(x * 0.12, y * 0.06, 3, self.seed) * 0.3

                shade = 0.32 + light + strand
                shade = max(0.18, min(0.72, shade))

                # Softer edge near face
                if face_d < 1.1:
                    edge_t = (face_d - 0.85) / 0.25
                    shade = shade * edge_t + 0.45 * (1 - edge_t)

                self.canvas.set_pixel(x, y, PALETTES['hair'].get(shade))

    def _body(self):
        cx = self.cx
        body_top = self.cy + int(self.head_r * 0.8)

        for y in range(body_top, self.size):
            prog = (y - body_top) / (self.size - body_top)
            hw = int((self.head_r * 0.8 + prog * self.head_r * 1.5))

            for x in range(cx - hw, cx + hw + 1):
                if 0 <= x < self.size:
                    rx = (x - cx) / max(hw, 1)
                    light = (1 - rx) * 0.12 + (1 - prog) * 0.15
                    fold = smooth_noise(x*0.08, y*0.04, self.seed+50)
                    fold_v = 0.08 if fold > 0.55 else (-0.06 if fold < 0.35 else 0)

                    shade = 0.32 + light + fold_v
                    self.canvas.set_pixel(x, y, PALETTES['robe'].get(max(0.18, min(0.62, shade))))

    def _book(self):
        cx = self.cx
        bt = self.cy + int(self.head_r * 1.4)
        bb = min(self.size - 3, bt + int(self.head_r * 0.8))
        bw = int(self.head_r * 1.3)

        for y in range(bt, bb):
            py = (y - bt) / max(bb - bt, 1)
            for x in range(cx - bw, cx + bw):
                if 0 <= x < self.size:
                    px = abs(x - cx) / bw
                    shade = 0.28 + (1-py)*0.18 + (1-px)*0.08
                    self.canvas.set_pixel(x, y, PALETTES['book'].get(shade))

        # Pages
        m = int(3 * self.s)
        for y in range(bt + m, bb - m):
            for x in range(cx - bw + m + 2, cx + bw - m - 2):
                shade = 0.08 + random.random() * 0.08
                self.canvas.set_pixel(x, y, PALETTES['pages'].get(shade))

    def _neck(self):
        cx, cy = self.cx, self.cy
        nt = cy + int(self.head_r * 0.7)
        nb = cy + int(self.head_r * 1.1)
        nw = int(self.head_r * 0.35)

        for y in range(nt, nb):
            for x in range(cx - nw, cx + nw):
                rx = (x - cx) / nw
                shade = 0.32 + (1 - abs(rx)) * 0.08 + rx * 0.08
                self.canvas.set_pixel(x, y, PALETTES['skin'].get(shade))

    def _face(self):
        """Draw rounder face - nearly circular."""
        cx, cy = self.cx, self.cy + int(self.head_r * 0.1)
        rx, ry = self.head_r * 0.88, self.head_r * 0.95  # Nearly circular

        for y in range(self.size):
            for x in range(self.size):
                d = ellipse_dist(x, y, cx, cy, rx, ry)
                if d < 1.0:
                    # Lighting
                    lx = (cx - x) / rx * 0.12
                    ly = (cy - y) / ry * 0.18
                    light = lx + ly + 0.5

                    # Soft variation
                    n = smooth_noise(x*0.08, y*0.08, self.seed+100) * 0.04

                    shade = 0.22 + light * 0.25 + d * 0.08 + n
                    shade = max(0.15, min(0.48, shade))

                    self.canvas.set_pixel(x, y, PALETTES['skin'].get(shade))

        # Subtle cheek blush
        for side in [-1, 1]:
            chx = cx + side * int(rx * 0.55)
            chy = cy + int(ry * 0.25)
            chr = int(rx * 0.22)
            for y in range(chy - chr, chy + chr):
                for x in range(chx - chr, chx + chr):
                    d = dist(x, y, chx, chy)
                    if d < chr:
                        alpha = int(30 * (1 - d/chr))
                        self.canvas.set_pixel(x, y, (230, 160, 150, alpha))

    def _eyes(self, expr):
        cx, cy = self.cx, self.cy
        ey = cy - int(self.head_r * 0.08)
        er = self.eye_r

        # Adjust for expression
        er_v = er
        if expr == 'surprised': er_v = int(er * 1.15)
        elif expr == 'thinking': er_v = int(er * 0.8)

        for side in [-1, 1]:
            ex = cx + side * self.eye_sep

            # White
            for y in range(ey - er_v, ey + er_v + 1):
                for x in range(ex - er, ex + er + 1):
                    if in_ellipse(x, y, ex, ey, er, er_v):
                        d = ellipse_dist(x, y, ex, ey, er, er_v)
                        self.canvas.set_pixel(x, y, PALETTES['eye_white'].get(d * 0.35))

            # Iris
            ir = int(er * 0.72)
            ix = ex + side * int(self.s)
            for y in range(ey - ir, ey + ir + 1):
                for x in range(ix - ir, ix + ir + 1):
                    if in_ellipse(x, y, ix, ey, ir, ir):
                        d = dist(x, y, ix, ey) / ir
                        self.canvas.set_pixel(x, y, PALETTES['eye_iris'].get(0.15 + d * 0.55))

            # Pupil
            pr = int(ir * 0.45)
            for y in range(ey - pr, ey + pr + 1):
                for x in range(ix - pr, ix + pr + 1):
                    if in_ellipse(x, y, ix, ey, pr, pr):
                        self.canvas.set_pixel(x, y, (12, 8, 18, 255))

            # Catchlights - crucial!
            hx, hy = ix - int(2*self.s), ey - int(2*self.s)
            for dy in range(-1, 2):
                for dx in range(-1, 2):
                    if abs(dx)+abs(dy) <= 1:
                        a = 255 if dx==0 and dy==0 else 160
                        self.canvas.set_pixel(hx+dx, hy+dy, (255,255,255,a))

            # Small secondary highlight
            self.canvas.set_pixel(ix + int(self.s), ey + int(2*self.s), (255,255,255,120))

            # Eyelid shadow
            for x in range(ex - er - 1, ex + er + 2):
                self.canvas.set_pixel(x, ey - er_v - 1, PALETTES['skin'].get(0.48))

    def _nose(self):
        cx = self.cx
        ny = self.cy + int(self.head_r * 0.35)
        self.canvas.set_pixel(cx-1, ny, PALETTES['skin'].get(0.38))
        self.canvas.set_pixel(cx-1, ny+1, PALETTES['skin'].get(0.40))
        self.canvas.set_pixel(cx, ny+2, PALETTES['skin'].get(0.22))

    def _mouth(self, expr):
        cx = self.cx
        my = self.cy + int(self.head_r * 0.6)
        mw = int(self.head_r * 0.35)

        if expr in ['neutral', 'thinking']:
            for i in range(-mw, mw+1):
                c = int((i*i) / (mw*1.2))
                self.canvas.set_pixel(cx+i, my+c, PALETTES['skin'].get(0.48))

        elif expr == 'encouraging':
            mw = int(mw * 1.2)
            for i in range(-mw, mw+1):
                c = int((i*i) / mw)
                self.canvas.set_pixel(cx+i, my+c, PALETTES['skin'].get(0.48))

        elif expr == 'surprised':
            for a in range(0, 360, 25):
                r = math.radians(a)
                x = int(cx + math.cos(r)*3*self.s)
                y = int(my + 2 + math.sin(r)*2*self.s)
                self.canvas.set_pixel(x, y, PALETTES['skin'].get(0.52))

        elif expr == 'concerned':
            for i in range(-mw, mw+1):
                c = -int((i*i) / (mw*2)) + 1
                self.canvas.set_pixel(cx+i, my+c, PALETTES['skin'].get(0.48))

        # Lip highlight
        self.canvas.set_pixel(cx, my+2, PALETTES['skin'].get(0.22))

    def _brows(self, expr):
        cx, cy = self.cx, self.cy
        by = cy - self.eye_r - int(6*self.s)
        bl = int(8*self.s)

        y_off = -2 if expr == 'surprised' else (1 if expr == 'concerned' else 0)

        for side in [-1, 1]:
            bx = cx + side * self.eye_sep
            for i in range(bl):
                p = i / bl
                x = bx - side*(bl//2) + side*i

                if expr == 'concerned':
                    yc = int(p * 2.5) * side
                elif expr == 'surprised':
                    yc = int(math.sin(p*math.pi) * -2.5)
                else:
                    yc = int(math.sin(p*math.pi) * -1.2)

                y = by + y_off + yc
                th = 2 if 0.15 < p < 0.85 else 1
                for t in range(th):
                    self.canvas.set_pixel(x, y+t, PALETTES['hair'].get(0.68 + t*0.08))

    def _glasses(self):
        cx, cy = self.cx, self.cy
        ey = cy - int(self.head_r * 0.08)
        lr = self.eye_r + int(3*self.s)

        for side in [-1, 1]:
            lx = cx + side * self.eye_sep

            for a in range(0, 360, 5):
                r = math.radians(a)
                for t in range(2):
                    px = int(lx + math.cos(r)*(lr+t))
                    py = int(ey + math.sin(r)*(lr+t))
                    shade = 0.18 + (1-math.sin(r))*0.22 + t*0.12
                    if 0 <= px < self.size and 0 <= py < self.size:
                        self.canvas.set_pixel(px, py, PALETTES['glasses'].get(shade))

        # Bridge
        for x in range(cx - int(2*self.s), cx + int(3*self.s)):
            self.canvas.set_pixel(x, ey, PALETTES['glasses'].get(0.32))
            self.canvas.set_pixel(x, ey+1, PALETTES['glasses'].get(0.42))

        # Arms
        for side in [-1, 1]:
            sx = cx + side*(self.eye_sep + lr + 1)
            for i in range(int(10*self.s)):
                x = sx + side*i
                y = ey + i//3
                if 0 <= x < self.size:
                    self.canvas.set_pixel(x, y, PALETTES['glasses'].get(0.38))

    def _hair_strands(self):
        """Softer side strands."""
        cx, cy = self.cx, self.cy

        for side in [-1, 1]:
            bx = cx + side * int(self.head_r * 1.2)

            for s in range(3):
                sx = bx + side * s * int(2.5*self.s)
                sy = cy - int(self.head_r * 0.5)

                for y in range(sy, sy + int(28*self.s)):
                    wave = math.sin((y-sy)*0.1 + s*0.7) * 3 * self.s
                    x = int(sx + wave)

                    if 0 <= x < self.size and 0 <= y < self.size:
                        prog = (y - sy) / (28*self.s)
                        shade = 0.22 + s*0.04 + prog*0.12
                        shade += smooth_noise(x*0.15, y*0.08, self.seed+s) * 0.08

                        self.canvas.set_pixel(x, y, PALETTES['hair'].get(shade))
                        if s < 2:
                            self.canvas.set_pixel(x + side, y, PALETTES['hair'].get(shade + 0.06))

    def _bun(self):
        cx = self.cx
        by = self.cy - int(self.head_r * 1.55)
        brx, bry = int(10*self.s), int(8*self.s)

        for y in range(by - bry, by + bry + 1):
            for x in range(cx - brx, cx + brx + 1):
                if in_ellipse(x, y, cx, by, brx, bry):
                    # Spiral pattern
                    ang = math.atan2(y-by, x-cx)
                    d = dist(x, y, cx, by) / brx
                    spiral = (ang + d*3.5) % (math.pi/2)
                    sp_v = 0.06 if spiral < math.pi/4 else 0

                    light = (cx-x)/brx*0.12 + (by-y)/bry*0.18
                    shade = 0.25 + d*0.12 + light + sp_v
                    self.canvas.set_pixel(x, y, PALETTES['hair'].get(max(0.12, min(0.55, shade))))

        # Highlight
        for dy in range(-2, 2):
            for dx in range(-2, 2):
                if abs(dx)+abs(dy) <= 2:
                    f = 1 - (abs(dx)+abs(dy))/3
                    self.canvas.set_pixel(cx-2+dx, by-2+dy, PALETTES['hair'].get(0.05 + (1-f)*0.12))

    def _sparkles(self):
        cx, cy = self.cx, self.cy
        spots = [
            (cx - int(7*self.s), cy - int(self.head_r*0.9)),
            (cx + int(4*self.s), cy - int(self.head_r*1.0)),
            (cx - int(2*self.s), cy - int(self.head_r*0.75)),
        ]
        for sx, sy in spots:
            for dy in range(-1, 2):
                for dx in range(-1, 2):
                    if abs(dx)+abs(dy) <= 1:
                        a = 180 if dx==0 and dy==0 else 80
                        self.canvas.set_pixel(sx+dx, sy+dy, (255, 245, 255, a))

    def save(self, path):
        self.canvas.save(path)


if __name__ == "__main__":
    import os
    out = os.path.dirname(os.path.abspath(__file__))

    print("=== Lyra V3 - Organic Shapes ===\n")

    for expr in ['neutral', 'encouraging', 'thinking', 'surprised', 'concerned']:
        print(f"Generating {expr}...")
        g = LyraV3(128, 42)
        g.generate(expr)
        g.save(os.path.join(out, f'lyra_v3_{expr}.png'))

    print("Generating 256px version...")
    g = LyraV3(256, 42)
    g.generate('neutral')
    g.save(os.path.join(out, 'lyra_v3_neutral_256.png'))

    print("\nDone!")
