#!/usr/bin/env python3
"""
Lyra Portrait Generator V8 - Fluffy & Cute
Major improvements:
- Much fluffier hair with chunky pixel clusters (not noise-based scatter)
- Warmer, more orange skin tones
- Larger eyes for cuter look
- Hand-painted style highlights
- Better chibi proportions (bigger hair volume)
- Deliberate color zones instead of gradients
"""

import math
import random
from png_writer import Canvas, hex_to_rgba, Color


# Expanded, warmer hair palette - more pink/lavender tones
HAIR_COLORS = [
    hex_to_rgba('#fffff8'),  # 0 - Pure highlight
    hex_to_rgba('#fff0ff'),  # 1 - Brightest pink-white
    hex_to_rgba('#f0d8f8'),  # 2 - Very light lavender
    hex_to_rgba('#e8c8f0'),  # 3 - Light lavender
    hex_to_rgba('#d8b0e8'),  # 4 - Light purple
    hex_to_rgba('#c898d8'),  # 5 - Mid lavender
    hex_to_rgba('#b080c8'),  # 6 - Mid purple
    hex_to_rgba('#9868b8'),  # 7 - Purple
    hex_to_rgba('#8050a0'),  # 8 - Darker purple
    hex_to_rgba('#684090'),  # 9 - Dark purple
    hex_to_rgba('#503078'),  # 10 - Shadow purple
    hex_to_rgba('#382060'),  # 11 - Deep shadow
]

# Warmer, more orange skin (matching reference)
SKIN_COLORS = [
    hex_to_rgba('#fff8e8'),  # 0 - Highlight
    hex_to_rgba('#ffe8c8'),  # 1 - Very light
    hex_to_rgba('#ffd0a0'),  # 2 - Light peach
    hex_to_rgba('#f0b078'),  # 3 - Mid peach
    hex_to_rgba('#e09058'),  # 4 - Warm orange
    hex_to_rgba('#c87040'),  # 5 - Shadow
    hex_to_rgba('#a05830'),  # 6 - Deep shadow
]

ROBE_COLORS = [
    hex_to_rgba('#90a8c8'),  # 0 - Highlight
    hex_to_rgba('#7090b8'),  # 1 - Light
    hex_to_rgba('#5878a0'),  # 2 - Mid-light
    hex_to_rgba('#486088'),  # 3 - Mid
    hex_to_rgba('#385070'),  # 4 - Dark
    hex_to_rgba('#283858'),  # 5 - Shadow
    hex_to_rgba('#182840'),  # 6 - Deep shadow
]

BG_COLOR = hex_to_rgba('#181830')
GLASSES_GOLD = [hex_to_rgba('#e8c070'), hex_to_rgba('#c89850'), hex_to_rgba('#a07838')]
BLUSH_COLOR = hex_to_rgba('#ff9080')


def dist(x1, y1, x2, y2):
    return math.sqrt((x2-x1)**2 + (y2-y1)**2)


class LyraV8:
    def __init__(self, size=128, seed=42):
        self.size = size
        self.s = size / 128  # Scale factor
        self.seed = seed
        random.seed(seed)

        # Center of canvas
        self.cx = size // 2
        self.cy = int(size * 0.52)

        # Key dimensions - BIGGER hair, smaller face for cuter proportions
        self.face_r = int(14 * self.s)  # Smaller face
        self.eye_r = int(8 * self.s)    # Bigger eyes!
        self.eye_sep = int(8 * self.s)  # Eyes closer together
        self.hair_r = int(32 * self.s)  # MUCH bigger hair!

    def generate(self, expr='neutral'):
        self.canvas = Canvas(self.size, self.size, BG_COLOR)

        # Layer order matters!
        self._draw_hair_back()
        self._draw_body()
        self._draw_face()
        self._draw_eyes(expr)
        self._draw_details(expr)
        self._draw_hair_front()
        self._draw_sparkles()

        return self.canvas

    def _draw_cluster(self, cx, cy, radius, color, density=0.7):
        """Draw a chunky pixel cluster - key for hand-painted look."""
        r = int(radius)
        for dy in range(-r, r + 1):
            for dx in range(-r, r + 1):
                d = math.sqrt(dx*dx + dy*dy)
                if d <= radius:
                    # Higher chance near center
                    chance = density * (1 - d / radius * 0.5)
                    if random.random() < chance:
                        x, y = int(cx + dx), int(cy + dy)
                        if 0 <= x < self.size and 0 <= y < self.size:
                            self.canvas.set_pixel(x, y, color)

    def _draw_hair_back(self):
        """Draw fluffy hair mass with chunky clusters."""
        cx = self.cx
        cy = self.cy - int(8 * self.s)  # Hair center above face
        hr = self.hair_r

        # First pass: fill base hair shape with mid tones
        for y in range(self.size):
            for x in range(self.size):
                # Main hair ellipse
                dx = (x - cx) / hr
                dy = (y - cy) / (hr * 0.85)
                d = dx*dx + dy*dy

                # Add bumpy edges for fluffiness
                angle = math.atan2(y - cy, x - cx)
                bump = math.sin(angle * 5) * 0.08 + math.sin(angle * 9) * 0.05
                bump += math.sin(angle * 13) * 0.03

                # Extra poof at top
                if y < cy:
                    bump += 0.15

                if d < (1.0 + bump) ** 2:
                    # Skip face area
                    face_d = dist(x, y, self.cx, self.cy + int(2 * self.s))
                    if face_d < self.face_r - 2:
                        continue

                    # Base shading - light from upper left
                    shade = 0.5
                    shade -= dx * 0.15  # Lighter on left
                    shade -= dy * 0.2   # Lighter on top
                    shade += d * 0.15   # Darker at edges

                    idx = int(max(0.2, min(0.85, shade)) * 11)
                    self.canvas.set_pixel(x, y, HAIR_COLORS[idx])

        # Second pass: add fluffy clusters for texture
        self._add_hair_clusters(cx, cy, hr)

        # Draw the bun on top
        self._draw_bun(cx, cy - int(hr * 0.6))

    def _add_hair_clusters(self, cx, cy, hr):
        """Add chunky highlight and shadow clusters."""
        random.seed(self.seed + 100)

        # Highlight clusters (upper left area)
        highlight_spots = [
            (cx - hr * 0.4, cy - hr * 0.3, 6, 2),
            (cx - hr * 0.2, cy - hr * 0.45, 5, 3),
            (cx + hr * 0.1, cy - hr * 0.5, 4, 2),
            (cx - hr * 0.5, cy - hr * 0.1, 4, 3),
            (cx - hr * 0.3, cy - hr * 0.15, 5, 2),
        ]

        for hx, hy, radius, color_idx in highlight_spots:
            r = int(radius * self.s)
            self._draw_cluster(hx, hy, r, HAIR_COLORS[color_idx], 0.8)
            # Add brighter center
            self._draw_cluster(hx, hy, r * 0.5, HAIR_COLORS[max(0, color_idx - 1)], 0.9)

        # Mid-tone texture clusters
        for _ in range(12):
            angle = random.uniform(0, math.pi * 2)
            dist_f = random.uniform(0.3, 0.8)
            hx = cx + math.cos(angle) * hr * dist_f
            hy = cy + math.sin(angle) * hr * dist_f * 0.85

            # Skip if in face area
            if dist(hx, hy, self.cx, self.cy + 2) < self.face_r + 5:
                continue

            r = random.uniform(3, 6) * self.s
            # Lighter clusters toward top-left
            base_idx = 5 if (hx < cx and hy < cy) else 7
            self._draw_cluster(hx, hy, r, HAIR_COLORS[base_idx], 0.6)

        # Shadow clusters (lower right, edges)
        shadow_spots = [
            (cx + hr * 0.5, cy + hr * 0.2, 5, 9),
            (cx + hr * 0.3, cy + hr * 0.3, 6, 10),
            (cx - hr * 0.6, cy + hr * 0.25, 4, 9),
            (cx + hr * 0.55, cy - hr * 0.1, 5, 8),
        ]

        for sx, sy, radius, color_idx in shadow_spots:
            r = int(radius * self.s)
            self._draw_cluster(sx, sy, r, HAIR_COLORS[color_idx], 0.7)

    def _draw_bun(self, cx, by):
        """Draw the hair bun with spiral pattern."""
        br = int(10 * self.s)

        # Base bun circle
        for y in range(int(by - br), int(by + br) + 1):
            for x in range(int(cx - br), int(cx + br) + 1):
                d = dist(x, y, cx, by)
                if d < br:
                    # Spiral shading
                    angle = math.atan2(y - by, x - cx)
                    nd = d / br
                    spiral = (angle + nd * 5) % (math.pi * 0.6)

                    # Light from top-left
                    light = (cx - x) / br * 0.12 + (by - y) / br * 0.18

                    shade = 0.4 + nd * 0.15 + light
                    if spiral < math.pi * 0.2:
                        shade += 0.1  # Lighter spiral bands

                    idx = int(max(0.15, min(0.85, shade)) * 11)
                    self.canvas.set_pixel(x, y, HAIR_COLORS[idx])

        # Bun highlights
        self._draw_cluster(cx - 2 * self.s, by - br * 0.4, 2 * self.s, HAIR_COLORS[1], 0.9)
        self._draw_cluster(cx + 1 * self.s, by - br * 0.3, 1.5 * self.s, HAIR_COLORS[2], 0.8)

    def _draw_body(self):
        """Draw shoulders, robe, and book."""
        cx = self.cx
        top = self.cy + int(self.face_r * 0.6)

        for y in range(top, self.size):
            prog = (y - top) / max(1, self.size - top)
            hw = int(self.face_r * (0.7 + prog * 1.4))

            for x in range(cx - hw, cx + hw + 1):
                if 0 <= x < self.size:
                    rel_x = (x - cx) / max(1, hw)

                    # Simple cloth shading - light from left
                    shade = 0.4
                    shade -= rel_x * 0.12  # Lighter on left
                    shade -= prog * 0.08   # Darker toward bottom

                    # Subtle fold shadows
                    if abs(rel_x) > 0.5:
                        shade += 0.08

                    idx = int(max(0.15, min(0.9, shade)) * 6)
                    self.canvas.set_pixel(x, y, ROBE_COLORS[idx])

        # Draw book
        self._draw_book()

    def _draw_book(self):
        """Draw the book Lyra is holding."""
        cx = self.cx
        bt = self.cy + int(self.face_r * 0.85)
        bh = int(self.face_r * 0.5)
        bw = int(self.face_r * 1.0)

        cover = hex_to_rgba('#8b5a2b')
        cover_dark = hex_to_rgba('#6b4423')
        pages = hex_to_rgba('#f5f0e0')
        pages_line = hex_to_rgba('#d8d0c0')

        # Book cover
        for y in range(bt, min(self.size, bt + bh)):
            for x in range(cx - bw, cx + bw):
                if 0 <= x < self.size:
                    # Slight gradient
                    shade = cover if x < cx else cover_dark
                    self.canvas.set_pixel(x, y, shade)

        # Pages
        m = int(2 * self.s)
        for y in range(bt + m, min(self.size, bt + bh - m)):
            for x in range(cx - bw + m + 2, cx + bw - m - 2):
                if 0 <= x < self.size:
                    # Page lines
                    if (y - bt) % 4 == 0:
                        self.canvas.set_pixel(x, y, pages_line)
                    else:
                        self.canvas.set_pixel(x, y, pages)

    def _draw_face(self):
        """Draw cute round face with warm skin."""
        cx = self.cx
        cy = self.cy + int(2 * self.s)
        fr = self.face_r

        for y in range(self.size):
            for x in range(self.size):
                # Round face shape
                dx = (x - cx) / fr
                dy = (y - cy) / fr
                d = math.sqrt(dx*dx + dy*dy)

                if d < 1.0:
                    # Soft shading - light from upper left
                    shade = 0.25
                    shade -= dx * 0.08  # Lighter on left
                    shade -= dy * 0.1   # Lighter on top
                    shade += d * 0.12   # Slightly darker at edges

                    idx = int(max(0.1, min(0.7, shade)) * 6)
                    self.canvas.set_pixel(x, y, SKIN_COLORS[idx])

        # Draw neck
        nw = int(fr * 0.28)
        for y in range(cy + int(fr * 0.7), cy + int(fr * 0.9)):
            for x in range(cx - nw, cx + nw):
                if 0 <= x < self.size:
                    self.canvas.set_pixel(x, y, SKIN_COLORS[3])

        # Cheek blush - rosy pink
        for side in [-1, 1]:
            ch_x = cx + side * int(fr * 0.5)
            ch_y = cy + int(fr * 0.3)
            ch_r = int(fr * 0.22)

            for y in range(ch_y - ch_r, ch_y + ch_r + 1):
                for x in range(ch_x - ch_r, ch_x + ch_r + 1):
                    d = dist(x, y, ch_x, ch_y)
                    if d < ch_r:
                        # Soft falloff
                        alpha = int(50 * (1 - d / ch_r) ** 1.5)
                        if 0 <= x < self.size and 0 <= y < self.size:
                            self.canvas.set_pixel(x, y, (BLUSH_COLOR[0], BLUSH_COLOR[1], BLUSH_COLOR[2], alpha))

    def _draw_eyes(self, expr):
        """Draw big cute anime eyes."""
        cx, cy = self.cx, self.cy
        ey = cy - int(self.face_r * 0.05)  # Eyes slightly above center
        er = self.eye_r  # Already bigger!

        # Expression adjustments
        er_v = er  # Vertical radius
        if expr == 'surprised':
            er_v = int(er * 1.2)
        elif expr == 'thinking':
            er_v = int(er * 0.85)

        for side in [-1, 1]:
            ex = cx + side * self.eye_sep

            # White of eye
            for y in range(ey - er_v, ey + er_v + 1):
                for x in range(ex - er, ex + er + 1):
                    dx = (x - ex) / er
                    dy = (y - ey) / er_v
                    if dx*dx + dy*dy <= 1:
                        self.canvas.set_pixel(x, y, (255, 255, 255, 255))

            # Iris - gradient from light blue-gray to dark
            ir = int(er * 0.75)
            ix = ex + side * int(1 * self.s)  # Slight offset toward center

            iris = [
                hex_to_rgba('#7090b0'),  # Top - lighter
                hex_to_rgba('#5878a0'),
                hex_to_rgba('#486088'),
                hex_to_rgba('#384868'),  # Bottom - darker
            ]

            for y in range(ey - ir, ey + ir + 1):
                for x in range(ix - ir, ix + ir + 1):
                    d = dist(x, y, ix, ey)
                    if d < ir:
                        # Vertical gradient
                        zy = (y - (ey - ir)) / (ir * 2)
                        idx = int(zy * 3.5)
                        self.canvas.set_pixel(x, y, iris[min(3, idx)])

            # Pupil
            pr = int(ir * 0.45)
            pupil = hex_to_rgba('#101820')
            for y in range(ey - pr, ey + pr + 1):
                for x in range(ix - pr, ix + pr + 1):
                    if dist(x, y, ix, ey) < pr:
                        self.canvas.set_pixel(x, y, pupil)

            # Catchlights - ESSENTIAL for cute look!
            white = (255, 255, 255, 255)

            # Main large catchlight (upper left)
            hx, hy = int(ix - 2.5 * self.s), int(ey - 2.5 * self.s)
            for dy in range(-1, 2):
                for dx in range(-1, 2):
                    if abs(dx) + abs(dy) <= 1:
                        self.canvas.set_pixel(hx + dx, hy + dy, white)
            # Extra pixel for larger highlight
            self.canvas.set_pixel(hx - 1, hy - 1, white)

            # Secondary smaller catchlight (lower right)
            self.canvas.set_pixel(int(ix + 1.5 * self.s), int(ey + 2 * self.s), white)
            self.canvas.set_pixel(int(ix + 2 * self.s), int(ey + 2.5 * self.s), (255, 255, 255, 200))

            # Upper eyelid line
            for x in range(ex - er - 1, ex + er + 2):
                if 0 <= x < self.size:
                    self.canvas.set_pixel(x, ey - er_v - 1, SKIN_COLORS[4])
                    # Slight shadow
                    self.canvas.set_pixel(x, ey - er_v, (200, 180, 160, 80))

    def _draw_details(self, expr):
        """Draw nose, mouth, eyebrows, glasses."""
        cx, cy = self.cx, self.cy
        fr = self.face_r

        # Simple nose - just a small shadow
        ny = cy + int(fr * 0.2)
        self.canvas.set_pixel(cx, ny, SKIN_COLORS[3])
        self.canvas.set_pixel(cx + 1, ny + 1, SKIN_COLORS[2])

        # Mouth
        my = cy + int(fr * 0.48)
        mw = int(fr * 0.25)
        mouth_color = SKIN_COLORS[5]

        if expr in ['neutral', 'thinking']:
            # Small gentle smile
            for i in range(-mw, mw + 1):
                curve = int((i * i) / (mw * 1.5))
                self.canvas.set_pixel(cx + i, my + curve, mouth_color)
        elif expr == 'encouraging':
            # Bigger smile
            mw = int(mw * 1.3)
            for i in range(-mw, mw + 1):
                curve = int((i * i) / (mw * 1.2))
                self.canvas.set_pixel(cx + i, my + curve, mouth_color)
        elif expr == 'surprised':
            # Small 'o' mouth
            for a in range(0, 360, 25):
                r = math.radians(a)
                px = int(cx + math.cos(r) * 2 * self.s)
                py = int(my + 1 + math.sin(r) * 1.5 * self.s)
                self.canvas.set_pixel(px, py, mouth_color)
        elif expr == 'concerned':
            # Slight frown
            for i in range(-mw, mw + 1):
                curve = -int((i * i) / (mw * 2.5)) + 1
                self.canvas.set_pixel(cx + i, my + curve, mouth_color)

        # Eyebrows
        by = cy - self.eye_r - int(5 * self.s)
        bl = int(6 * self.s)

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

                # Expression curves
                if expr == 'concerned':
                    yc = int(prog * 2.5) * side
                elif expr == 'surprised':
                    yc = int(math.sin(prog * math.pi) * -2.5)
                else:
                    yc = int(math.sin(prog * math.pi) * -1)

                y = by + y_off + yc
                if 0 <= x < self.size and 0 <= y < self.size:
                    self.canvas.set_pixel(x, y, HAIR_COLORS[7])
                    self.canvas.set_pixel(x, y + 1, HAIR_COLORS[9])

        # Glasses
        self._draw_glasses()

    def _draw_glasses(self):
        """Draw round golden glasses."""
        cx, cy = self.cx, self.cy
        ey = cy - int(self.face_r * 0.05)
        lr = self.eye_r + int(3 * self.s)  # Lens radius

        for side in [-1, 1]:
            lx = cx + side * self.eye_sep

            # Draw circular frame
            for a in range(0, 360, 4):
                r = math.radians(a)

                # Frame thickness
                for t in range(int(2 * self.s)):
                    px = int(lx + math.cos(r) * (lr + t))
                    py = int(ey + math.sin(r) * (lr + t))

                    # Highlight on top, shadow on bottom
                    if a < 180:
                        color = GLASSES_GOLD[0] if t == 0 else GLASSES_GOLD[1]
                    else:
                        color = GLASSES_GOLD[1] if t == 0 else GLASSES_GOLD[2]

                    if 0 <= px < self.size and 0 <= py < self.size:
                        self.canvas.set_pixel(px, py, color)

        # Bridge between lenses
        bridge_y = ey
        for x in range(cx - int(3 * self.s), cx + int(3 * self.s)):
            self.canvas.set_pixel(x, bridge_y, GLASSES_GOLD[1])
            self.canvas.set_pixel(x, bridge_y + 1, GLASSES_GOLD[2])

        # Temple arms (sides)
        for side in [-1, 1]:
            sx = cx + side * (self.eye_sep + lr + int(2 * self.s))
            for i in range(int(8 * self.s)):
                x = sx + side * i
                y = ey + i // 4
                if 0 <= x < self.size and 0 <= y < self.size:
                    self.canvas.set_pixel(x, y, GLASSES_GOLD[1])

    def _draw_hair_front(self):
        """Draw bangs and side strands over face."""
        cx, cy = self.cx, self.cy
        fr = self.face_r

        # Bangs - chunky strands
        bang_positions = [
            (-0.6, 0.7, 3),  # (x offset ratio, length ratio, color base)
            (-0.35, 0.85, 2),
            (-0.1, 0.9, 3),
            (0.15, 0.85, 2),
            (0.4, 0.75, 3),
            (0.6, 0.65, 4),
        ]

        for bx_off, length_r, color_base in bang_positions:
            bx = cx + int(bx_off * fr)
            by = cy - fr - int(2 * self.s)
            length = int(length_r * fr * 0.5)

            # Draw each bang strand as chunky pixels
            width = int(2.5 * self.s)
            for j in range(length):
                prog = j / length
                wave = math.sin(j * 0.4 + bx_off * 2) * self.s

                for w in range(-width, width + 1):
                    x = int(bx + wave + w)
                    y = by + j

                    if 0 <= x < self.size and 0 <= y < self.size:
                        # Gradient from light to dark
                        idx = color_base + int(prog * 3)
                        # Lighter in center
                        if abs(w) == 0:
                            idx = max(1, idx - 1)
                        idx = min(10, idx)
                        self.canvas.set_pixel(x, y, HAIR_COLORS[idx])

        # Side strands - flowing hair beside face
        for side in [-1, 1]:
            strand_base_x = cx + side * (fr + int(4 * self.s))
            strand_base_y = cy - int(fr * 0.4)

            # Multiple strands per side
            for strand in range(3):
                sx = strand_base_x + side * strand * int(3 * self.s)
                sy = strand_base_y + strand * int(2 * self.s)

                length = int((22 - strand * 3) * self.s)
                width = int((3 - strand * 0.5) * self.s)

                for j in range(length):
                    prog = j / length
                    # Gentle wave
                    wave = math.sin(j * 0.1 + strand * 0.8) * 2.5 * self.s

                    for w in range(-width, width + 1):
                        x = int(sx + wave + w * 0.7)
                        y = sy + j

                        if 0 <= x < self.size and 0 <= y < self.size:
                            # Color gradient
                            base = 4 + strand
                            idx = base + int(prog * 3)
                            # Lighter center
                            if abs(w) <= 1:
                                idx = max(2, idx - 1)
                            idx = min(10, idx)
                            self.canvas.set_pixel(x, y, HAIR_COLORS[idx])

    def _draw_sparkles(self):
        """Add sparkle highlights for that magical touch."""
        cx = self.cx
        cy = self.cy - int(8 * self.s)
        hr = self.hair_r

        # Strategic sparkle positions
        sparkles = [
            (cx - int(8 * self.s), cy - int(hr * 0.35), 2),  # Left hair
            (cx + int(5 * self.s), cy - int(hr * 0.45), 2),  # Top
            (cx - int(3 * self.s), cy - int(hr * 0.15), 1),  # Center-left
            (cx - int(2 * self.s), cy - int(hr * 0.65), 2),  # Bun area
        ]

        for sx, sy, size in sparkles:
            if 0 <= sx < self.size and 0 <= sy < self.size:
                # Cross-shaped sparkle
                white = (255, 255, 255, 255)
                white_soft = (255, 255, 255, 180)

                self.canvas.set_pixel(sx, sy, white)

                for d in range(1, size + 1):
                    alpha = int(255 * (1 - d / (size + 1)))
                    c = (255, 255, 255, alpha)

                    for dx, dy in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
                        px, py = sx + dx * d, sy + dy * d
                        if 0 <= px < self.size and 0 <= py < self.size:
                            self.canvas.set_pixel(px, py, c)

    def save(self, path):
        self.canvas.save(path)


if __name__ == "__main__":
    import os
    out = os.path.dirname(os.path.abspath(__file__))

    print("=== Lyra V8 - Fluffy & Cute ===\n")

    for expr in ['neutral', 'encouraging', 'thinking', 'surprised', 'concerned']:
        print(f"  {expr}...")
        g = LyraV8(128, 42)
        g.generate(expr)
        g.save(os.path.join(out, f'lyra_v8_{expr}.png'))

    # High-res version
    print("\n  256px...")
    g = LyraV8(256, 42)
    g.generate('neutral')
    g.save(os.path.join(out, 'lyra_v8_neutral_256.png'))

    print("\nDone!")
