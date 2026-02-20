#!/usr/bin/env python3
"""
Lyra Portrait Generator V5 - Clean & Cute
Key improvements over V4:
- Intentional hair strand clusters with directional flow
- Cleaner rendering (less random noise)
- Better face shape - oval with small chin
- Careful highlight placement along hair strands
- More polished pixel art look
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


# Clean, rich colors
PAL = {
    'hair': ColorRamp([
        '#ffe8ff', '#f0d0f0', '#e0b8e8', '#d0a0e0',
        '#b880d0', '#9858b8', '#7840a0', '#582080',
        '#401060', '#280840', '#180028',
    ]),
    'skin': ColorRamp([
        '#fff0e0', '#ffe0c0', '#ffc898', '#f0a870',
        '#e08850', '#c06830', '#904820', '#603010',
    ]),
    'robe': ColorRamp([
        '#8090c0', '#6070a8', '#485890', '#384878',
        '#283860', '#182848', '#101830',
    ]),
    'glasses': ColorRamp(['#d8a870', '#b88850', '#986830', '#784818', '#583008']),
    'book': ColorRamp(['#b89060', '#987040', '#785028', '#583818', '#382008']),
    'pages': ColorRamp(['#fff8f0', '#f0e8d8', '#e0d8c0', '#c8c0a8']),
    'bg': ColorRamp(['#1c1c3c', '#161630', '#101028', '#0a0a18']),
    'eye_w': ColorRamp(['#ffffff', '#f0f0f8', '#d8d8e8', '#b8b8c8']),
    'eye_i': ColorRamp(['#5878a0', '#405068', '#283848', '#182830', '#101820']),
}


def dist(x1, y1, x2, y2):
    return math.sqrt((x2-x1)**2 + (y2-y1)**2)


def in_ellipse(px, py, cx, cy, rx, ry):
    if rx <= 0 or ry <= 0: return False
    return ((px-cx)/rx)**2 + ((py-cy)/ry)**2 <= 1.0


def smoothstep(t):
    t = max(0, min(1, t))
    return t * t * (3 - 2 * t)


class LyraV5:
    def __init__(self, size=128, seed=42):
        self.size = size
        self.seed = seed
        self.s = size / 128
        random.seed(seed)

        self.cx = size // 2
        self.cy = int(size * 0.52)

        # Cute proportions
        self.face_w = int(18 * self.s)  # Face half-width
        self.face_h = int(20 * self.s)  # Face half-height (slightly taller)

        # Big eyes
        self.eye_r = int(7 * self.s)
        self.eye_sep = int(10 * self.s)

        # Big fluffy hair
        self.hair_r = int(32 * self.s)

    def generate(self, expr='neutral'):
        self.canvas = Canvas(self.size, self.size, PAL['bg'].get(0.2))

        self._draw_bg()
        self._draw_hair()
        self._draw_body()
        self._draw_neck()
        self._draw_face()
        self._draw_eyes(expr)
        self._draw_nose_mouth(expr)
        self._draw_brows(expr)
        self._draw_glasses()
        self._draw_hair_front()
        self._draw_book()

        return self.canvas

    def _draw_bg(self):
        """Simple gradient background."""
        for y in range(self.size):
            for x in range(self.size):
                # Subtle radial gradient
                d = dist(x, y, self.cx, self.cy) / self.size
                shade = 0.2 + d * 0.15
                self.canvas.pixels[y][x] = PAL['bg'].get(shade)

    def _draw_hair(self):
        """Draw hair with intentional strand clusters."""
        cx = self.cx
        cy = self.cy - int(8 * self.s)
        hr = self.hair_r

        # First pass: base hair shape with smooth shading
        for y in range(self.size):
            for x in range(self.size):
                # Organic hair boundary
                in_hair = False

                # Main oval
                if in_ellipse(x, y, cx, cy, hr * 0.95, hr * 0.85):
                    in_hair = True
                # Top poof
                if in_ellipse(x, y, cx, cy - hr * 0.5, hr * 0.55, hr * 0.45):
                    in_hair = True
                # Left side
                if in_ellipse(x, y, cx - hr * 0.45, cy + hr * 0.1, hr * 0.6, hr * 0.7):
                    in_hair = True
                # Right side
                if in_ellipse(x, y, cx + hr * 0.45, cy + hr * 0.1, hr * 0.6, hr * 0.7):
                    in_hair = True

                if not in_hair:
                    continue

                # Skip face region
                if in_ellipse(x, y, self.cx, self.cy + 2, self.face_w + 2, self.face_h + 2):
                    continue

                # Base shading - light from top-left
                rel_y = (y - (cy - hr)) / (hr * 2)
                rel_x = (x - cx) / hr

                light = (1 - rel_y) * 0.25 + (0.5 - rel_x) * 0.15
                shade = 0.38 + light
                shade = max(0.25, min(0.65, shade))

                self.canvas.set_pixel(x, y, PAL['hair'].get(shade))

        # Second pass: draw strand clusters
        self._draw_hair_strands(cx, cy, hr)

        # Third pass: bun
        self._draw_bun(cx, cy - hr * 0.55)

        # Fourth pass: highlights
        self._draw_hair_highlights(cx, cy, hr)

    def _draw_hair_strands(self, cx, cy, hr):
        """Draw flowing strand clusters."""
        # Define strand flow directions for different regions
        # Each strand: (start_x, start_y, angle, length, count, shade_base)

        strands = []

        # Top strands - flowing outward and down
        for i in range(12):
            angle = math.pi * 0.3 + (i / 12) * math.pi * 0.4  # Arc across top
            start_x = cx + math.cos(angle) * hr * 0.3
            start_y = cy - hr * 0.4 + abs(math.cos(angle)) * hr * 0.1
            flow_angle = angle + math.pi * 0.4  # Flow outward-down
            strands.append((start_x, start_y, flow_angle, hr * 0.4, 3, 0.32))

        # Left side strands - flowing down
        for i in range(8):
            start_x = cx - hr * 0.5 - i * 2 * self.s
            start_y = cy - hr * 0.2 + i * 3 * self.s
            flow_angle = math.pi * 0.55 + random.random() * 0.1
            strands.append((start_x, start_y, flow_angle, hr * 0.5, 2, 0.35))

        # Right side strands - flowing down
        for i in range(8):
            start_x = cx + hr * 0.5 + i * 2 * self.s
            start_y = cy - hr * 0.2 + i * 3 * self.s
            flow_angle = math.pi * 0.45 - random.random() * 0.1
            strands.append((start_x, start_y, flow_angle, hr * 0.5, 2, 0.35))

        # Draw each strand cluster
        for sx, sy, angle, length, width, shade_base in strands:
            self._draw_strand_cluster(sx, sy, angle, length, width, shade_base)

    def _draw_strand_cluster(self, sx, sy, angle, length, width, shade_base):
        """Draw a single strand cluster - a flowing line of pixels."""
        steps = int(length)

        for i in range(steps):
            t = i / steps
            # Slight wave in the strand
            wave = math.sin(t * 3 + sx * 0.1) * 2 * self.s

            # Position along strand
            px = sx + math.cos(angle) * i + math.cos(angle + math.pi/2) * wave
            py = sy + math.sin(angle) * i + math.sin(angle + math.pi/2) * wave

            # Skip if in face region
            if in_ellipse(px, py, self.cx, self.cy + 2, self.face_w + 3, self.face_h + 3):
                continue

            # Shade varies along strand - lighter at start
            shade = shade_base + t * 0.12
            shade += (random.random() - 0.5) * 0.06

            # Draw cluster width
            for w in range(-width, width + 1):
                wx = int(px + math.cos(angle + math.pi/2) * w * 0.5)
                wy = int(py + math.sin(angle + math.pi/2) * w * 0.5)

                if 0 <= wx < self.size and 0 <= wy < self.size:
                    w_shade = shade + abs(w) * 0.03
                    self.canvas.set_pixel(wx, wy, PAL['hair'].get(max(0.2, min(0.7, w_shade))))

    def _draw_bun(self, cx, by):
        """Draw hair bun on top."""
        br = int(9 * self.s)

        for y in range(int(by - br), int(by + br) + 1):
            for x in range(int(cx - br), int(cx + br) + 1):
                d = dist(x, y, cx, by)
                if d < br:
                    nd = d / br

                    # Spiral texture
                    ang = math.atan2(y - by, x - cx)
                    spiral = (ang * 2 + nd * 5) % math.pi
                    sp_v = 0.06 if spiral < math.pi * 0.4 else 0

                    # Lighting
                    light = (cx - x) / br * 0.1 + (by - y) / br * 0.15

                    shade = 0.32 + nd * 0.12 + light + sp_v
                    self.canvas.set_pixel(x, y, PAL['hair'].get(max(0.18, min(0.55, shade))))

        # Bun highlight
        hx, hy = int(cx - 2 * self.s), int(by - br * 0.35)
        for dy in range(-2, 3):
            for dx in range(-2, 3):
                if abs(dx) + abs(dy) <= 2:
                    f = 1 - (abs(dx) + abs(dy)) / 3
                    self.canvas.set_pixel(hx + dx, hy + dy, PAL['hair'].get(0.08 + (1-f) * 0.12))

    def _draw_hair_highlights(self, cx, cy, hr):
        """Add intentional highlight streaks along hair flow."""
        # Highlight streaks - follow the hair flow
        highlights = [
            # (x, y, angle, length) - positioned along strand flow
            (cx - hr * 0.35, cy - hr * 0.3, math.pi * 0.6, hr * 0.25),
            (cx - hr * 0.15, cy - hr * 0.4, math.pi * 0.55, hr * 0.2),
            (cx + hr * 0.1, cy - hr * 0.35, math.pi * 0.45, hr * 0.22),
            (cx + hr * 0.3, cy - hr * 0.25, math.pi * 0.4, hr * 0.2),
            (cx - hr * 0.5, cy + hr * 0.1, math.pi * 0.52, hr * 0.15),
            (cx + hr * 0.45, cy + hr * 0.05, math.pi * 0.48, hr * 0.15),
        ]

        for hx, hy, angle, length in highlights:
            for i in range(int(length)):
                t = i / length
                px = int(hx + math.cos(angle) * i)
                py = int(hy + math.sin(angle) * i)

                if in_ellipse(px, py, self.cx, self.cy + 2, self.face_w + 2, self.face_h + 2):
                    continue

                if 0 <= px < self.size and 0 <= py < self.size:
                    # Fade highlight along length
                    shade = 0.1 + t * 0.15
                    alpha = int(180 * (1 - t * 0.5))
                    color = PAL['hair'].get(shade)
                    self.canvas.set_pixel(px, py, (color[0], color[1], color[2], alpha))

        # Sparkle points
        sparkles = [
            (cx - int(6 * self.s), cy - int(hr * 0.45)),
            (cx + int(4 * self.s), cy - int(hr * 0.5)),
            (cx - int(2 * self.s), cy - int(hr * 0.3)),
        ]
        for sx, sy in sparkles:
            for dy in range(-1, 2):
                for dx in range(-1, 2):
                    if abs(dx) + abs(dy) <= 1:
                        a = 230 if dx == 0 and dy == 0 else 120
                        self.canvas.set_pixel(sx + dx, sy + dy, (255, 250, 255, a))

    def _draw_body(self):
        """Draw shoulders and robe."""
        cx = self.cx
        top_y = self.cy + int(self.face_h * 0.75)

        for y in range(top_y, self.size):
            prog = (y - top_y) / (self.size - top_y)
            hw = int(self.face_w * (0.9 + prog * 1.3))

            for x in range(cx - hw, cx + hw + 1):
                if 0 <= x < self.size:
                    rel_x = (x - cx) / hw
                    light = (1 - rel_x) * 0.12 + (1 - prog) * 0.15

                    # Cloth fold hints
                    fold_x = math.sin(x * 0.15 + y * 0.05) * 0.08
                    shade = 0.35 + light + fold_x

                    self.canvas.set_pixel(x, y, PAL['robe'].get(max(0.2, min(0.6, shade))))

    def _draw_neck(self):
        cx, cy = self.cx, self.cy
        nt = cy + int(self.face_h * 0.6)
        nb = cy + int(self.face_h * 0.85)
        nw = int(self.face_w * 0.35)

        for y in range(nt, nb):
            for x in range(cx - nw, cx + nw):
                if 0 <= x < self.size:
                    rel_x = (x - cx) / nw
                    shade = 0.35 + (1 - abs(rel_x)) * 0.08
                    self.canvas.set_pixel(x, y, PAL['skin'].get(shade))

    def _draw_face(self):
        """Draw cute oval face with small chin."""
        cx = self.cx
        cy = self.cy + int(2 * self.s)
        fw, fh = self.face_w, self.face_h

        for y in range(self.size):
            for x in range(self.size):
                # Oval face shape
                if in_ellipse(x, y, cx, cy, fw, fh):
                    # Distance from center
                    dx = (x - cx) / fw
                    dy = (y - cy) / fh
                    d = math.sqrt(dx*dx + dy*dy)

                    # Lighting from top-left
                    light = (1 - dx) * 0.08 + (1 - dy) * 0.12

                    shade = 0.25 + light + d * 0.08
                    shade = max(0.18, min(0.48, shade))

                    self.canvas.set_pixel(x, y, PAL['skin'].get(shade))

        # Cheek blush - essential for cute!
        for side in [-1, 1]:
            ch_x = cx + side * int(fw * 0.5)
            ch_y = cy + int(fh * 0.25)
            ch_r = int(fw * 0.22)

            for y in range(ch_y - ch_r, ch_y + ch_r + 1):
                for x in range(ch_x - ch_r, ch_x + ch_r + 1):
                    d = dist(x, y, ch_x, ch_y)
                    if d < ch_r:
                        alpha = int(45 * (1 - d/ch_r) ** 1.5)
                        self.canvas.set_pixel(x, y, (255, 140, 135, alpha))

    def _draw_eyes(self, expr):
        """Draw big cute eyes."""
        cx, cy = self.cx, self.cy
        ey = cy - int(self.face_h * 0.08)
        er = self.eye_r

        # Adjust for expression
        er_v = er
        if expr == 'surprised': er_v = int(er * 1.15)
        elif expr == 'thinking': er_v = int(er * 0.8)

        for side in [-1, 1]:
            ex = cx + side * self.eye_sep

            # Eye white
            for y in range(ey - er_v, ey + er_v + 1):
                for x in range(ex - er, ex + er + 1):
                    if in_ellipse(x, y, ex, ey, er, er_v):
                        d = dist(x, y, ex, ey) / max(er, er_v)
                        self.canvas.set_pixel(x, y, PAL['eye_w'].get(d * 0.25))

            # Iris - large
            ir = int(er * 0.72)
            ix = ex + side * int(0.8 * self.s)

            for y in range(ey - ir, ey + ir + 1):
                for x in range(ix - ir, ix + ir + 1):
                    if in_ellipse(x, y, ix, ey, ir, ir):
                        d = dist(x, y, ix, ey) / ir
                        # Gradient: lighter at top
                        vert = (y - (ey - ir)) / (ir * 2)
                        shade = 0.08 + d * 0.25 + vert * 0.4
                        self.canvas.set_pixel(x, y, PAL['eye_i'].get(shade))

            # Pupil
            pr = int(ir * 0.42)
            for y in range(ey - pr, ey + pr + 1):
                for x in range(ix - pr, ix + pr + 1):
                    if in_ellipse(x, y, ix, ey, pr, pr):
                        self.canvas.set_pixel(x, y, (8, 4, 12, 255))

            # Catchlights - IMPORTANT!
            hx, hy = ix - int(2 * self.s), ey - int(2 * self.s)
            for dy in range(-1, 2):
                for dx in range(-1, 2):
                    if abs(dx) + abs(dy) <= 1:
                        a = 255 if dx == 0 and dy == 0 else 180
                        self.canvas.set_pixel(hx + dx, hy + dy, (255, 255, 255, a))

            # Secondary catchlight
            self.canvas.set_pixel(ix + int(self.s), ey + int(2*self.s), (255, 255, 255, 150))

            # Eyelid line
            for x in range(ex - er - 1, ex + er + 2):
                self.canvas.set_pixel(x, ey - er_v - 1, PAL['skin'].get(0.48))

    def _draw_nose_mouth(self, expr):
        """Draw cute small nose and mouth."""
        cx, cy = self.cx, self.cy
        fh = self.face_h

        # Tiny nose
        ny = cy + int(fh * 0.2)
        self.canvas.set_pixel(cx, ny, PAL['skin'].get(0.38))
        self.canvas.set_pixel(cx - 1, ny + 1, PAL['skin'].get(0.4))

        # Mouth
        my = cy + int(fh * 0.45)
        mw = int(self.face_w * 0.32)

        if expr in ['neutral', 'thinking']:
            for i in range(-mw, mw + 1):
                curve = int((i * i) / (mw * 1.4))
                self.canvas.set_pixel(cx + i, my + curve, PAL['skin'].get(0.48))

        elif expr == 'encouraging':
            mw = int(mw * 1.25)
            for i in range(-mw, mw + 1):
                curve = int((i * i) / (mw * 1.15))
                self.canvas.set_pixel(cx + i, my + curve, PAL['skin'].get(0.48))

        elif expr == 'surprised':
            for a in range(0, 360, 30):
                r = math.radians(a)
                px = int(cx + math.cos(r) * 2.5 * self.s)
                py = int(my + 1 + math.sin(r) * 2 * self.s)
                self.canvas.set_pixel(px, py, PAL['skin'].get(0.52))

        elif expr == 'concerned':
            for i in range(-mw, mw + 1):
                curve = -int((i * i) / (mw * 2.2)) + 1
                self.canvas.set_pixel(cx + i, my + curve, PAL['skin'].get(0.48))

    def _draw_brows(self, expr):
        """Draw expressive eyebrows."""
        cx, cy = self.cx, self.cy
        by = cy - self.eye_r - int(5 * self.s)
        bl = int(7 * self.s)

        y_off = -2 if expr == 'surprised' else (1 if expr == 'concerned' else 0)

        for side in [-1, 1]:
            bx = cx + side * self.eye_sep

            for i in range(bl):
                prog = i / bl
                x = bx - side * (bl // 2) + side * i

                if expr == 'concerned':
                    yc = int(prog * 2.2) * side
                elif expr == 'surprised':
                    yc = int(math.sin(prog * math.pi) * -2.5)
                else:
                    yc = int(math.sin(prog * math.pi) * -1.2)

                y = by + y_off + yc
                thick = 2 if 0.2 < prog < 0.8 else 1

                for t in range(thick):
                    self.canvas.set_pixel(x, y + t, PAL['hair'].get(0.62 + t * 0.06))

    def _draw_glasses(self):
        """Draw round glasses."""
        cx, cy = self.cx, self.cy
        ey = cy - int(self.face_h * 0.08)
        lr = self.eye_r + int(2.5 * self.s)

        for side in [-1, 1]:
            lx = cx + side * self.eye_sep

            for a in range(0, 360, 4):
                r = math.radians(a)
                for t in range(2):
                    px = int(lx + math.cos(r) * (lr + t))
                    py = int(ey + math.sin(r) * (lr + t))
                    shade = 0.15 + (1 - math.sin(r)) * 0.22 + t * 0.1
                    if 0 <= px < self.size and 0 <= py < self.size:
                        self.canvas.set_pixel(px, py, PAL['glasses'].get(shade))

        # Bridge
        for x in range(cx - int(2 * self.s), cx + int(3 * self.s)):
            self.canvas.set_pixel(x, ey, PAL['glasses'].get(0.28))

        # Arms
        for side in [-1, 1]:
            sx = cx + side * (self.eye_sep + lr + 1)
            for i in range(int(8 * self.s)):
                x = sx + side * i
                y = ey + i // 3
                if 0 <= x < self.size:
                    self.canvas.set_pixel(x, y, PAL['glasses'].get(0.32))

    def _draw_hair_front(self):
        """Draw bangs and side strands over face edge."""
        cx, cy = self.cx, self.cy

        # Wispy bangs
        for i in range(8):
            bx = cx - int(10 * self.s) + i * int(2.8 * self.s)
            by = cy - self.face_h - int(1 * self.s)
            length = int((4 + random.random() * 3) * self.s)

            for j in range(length):
                wave = math.sin(j * 0.5 + i * 0.4) * self.s
                x = int(bx + wave)
                y = by + j

                if 0 <= x < self.size and 0 <= y < self.size:
                    shade = 0.25 + (j / length) * 0.12 + (i % 2) * 0.06
                    self.canvas.set_pixel(x, y, PAL['hair'].get(shade))

        # Side strands
        for side in [-1, 1]:
            for s in range(3):
                sx = cx + side * (self.face_w + int((2 + s * 2) * self.s))
                sy = cy - int(self.face_h * 0.4)

                for j in range(int(22 * self.s)):
                    wave = math.sin(j * 0.1 + s * 0.6) * 2.5 * self.s
                    x = int(sx + wave)
                    y = sy + j

                    if 0 <= x < self.size and 0 <= y < self.size:
                        prog = j / (22 * self.s)
                        shade = 0.28 + prog * 0.1 + s * 0.04
                        self.canvas.set_pixel(x, y, PAL['hair'].get(max(0.22, min(0.55, shade))))
                        # Width
                        self.canvas.set_pixel(x + side, y, PAL['hair'].get(shade + 0.05))

    def _draw_book(self):
        """Draw book being held."""
        cx = self.cx
        bt = self.cy + int(self.face_h * 0.95)
        bb = min(self.size - 2, bt + int(self.face_h * 0.5))
        bw = int(self.face_w * 1.1)

        for y in range(bt, bb):
            py = (y - bt) / max(bb - bt, 1)
            for x in range(cx - bw, cx + bw):
                if 0 <= x < self.size:
                    px = abs(x - cx) / bw
                    shade = 0.3 + (1 - py) * 0.12 + (1 - px) * 0.08
                    self.canvas.set_pixel(x, y, PAL['book'].get(shade))

        # Pages
        m = int(2 * self.s)
        for y in range(bt + m, bb - m):
            for x in range(cx - bw + m + 2, cx + bw - m - 2):
                if 0 <= x < self.size:
                    self.canvas.set_pixel(x, y, PAL['pages'].get(0.12))

    def save(self, path):
        self.canvas.save(path)


if __name__ == "__main__":
    import os
    out = os.path.dirname(os.path.abspath(__file__))

    print("=== Lyra V5 - Clean & Cute ===\n")

    for expr in ['neutral', 'encouraging', 'thinking', 'surprised', 'concerned']:
        print(f"Generating {expr}...")
        g = LyraV5(128, 42)
        g.generate(expr)
        g.save(os.path.join(out, f'lyra_v5_{expr}.png'))

    print("\nGenerating 256px...")
    g = LyraV5(256, 42)
    g.generate('neutral')
    g.save(os.path.join(out, 'lyra_v5_neutral_256.png'))

    print("\nDone!")
