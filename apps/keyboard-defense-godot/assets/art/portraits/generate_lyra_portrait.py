#!/usr/bin/env python3
"""
Lyra Portrait Generator - 48x48 Pixel Art
Follows the Pixel Art Style Guide for Wise-Mentor Character
"""

from PIL import Image

# === PALETTE (16 colors max) ===
# Skin tones (3 shades)
SKIN_LIGHT = (255, 220, 185)    # Highlight
SKIN_MID = (245, 203, 167)      # #f5cba7 - Base
SKIN_DARK = (210, 165, 125)     # Shadow

# Hair - Silver-purple (3 shades)
HAIR_LIGHT = (140, 100, 160)    # Highlight
HAIR_MID = (100, 65, 120)       # Mid
HAIR_DARK = (74, 35, 90)        # #4a235a - Base/outline

# Robe - Deep blue (3 shades)
ROBE_LIGHT = (50, 120, 170)     # Highlight
ROBE_MID = (26, 82, 118)        # #1a5276 - Base
ROBE_DARK = (15, 50, 80)        # Shadow/outline

# Accents
TRIM_GOLD = (244, 208, 63)      # #f4d03f
TRIM_DARK = (180, 150, 40)      # Gold shadow
BOOK_LIGHT = (150, 80, 30)      # Book highlight
BOOK_BROWN = (110, 44, 0)       # #6e2c00
GLASSES_LIGHT = (160, 175, 185) # Glasses highlight
GLASSES_MID = (133, 146, 158)   # #85929e

# Eyes
EYE_WHITE = (250, 250, 255)
EYE_IRIS = (80, 100, 140)       # Blue-gray iris
EYE_PUPIL = (30, 20, 40)

# Transparent
TRANSPARENT = (0, 0, 0, 0)


def draw_lyra_portrait():
    """Generate a 48x48 pixel art portrait of Lyra the wise mentor."""
    img = Image.new("RGBA", (48, 48), TRANSPARENT)
    pixels = img.load()

    # Helper function to draw filled ellipse-ish shapes
    def fill_region(coords, color):
        for (x, y) in coords:
            if 0 <= x < 48 and 0 <= y < 48:
                pixels[x, y] = color + (255,) if len(color) == 3 else color

    def rect(x1, y1, x2, y2, color):
        for x in range(x1, x2):
            for y in range(y1, y2):
                if 0 <= x < 48 and 0 <= y < 48:
                    pixels[x, y] = color + (255,) if len(color) == 3 else color

    def hline(x1, x2, y, color):
        for x in range(x1, x2):
            if 0 <= x < 48 and 0 <= y < 48:
                pixels[x, y] = color + (255,) if len(color) == 3 else color

    def vline(x, y1, y2, color):
        for y in range(y1, y2):
            if 0 <= x < 48 and 0 <= y < 48:
                pixels[x, y] = color + (255,) if len(color) == 3 else color

    # === HAIR (back layer, including bun) ===
    # Hair bun on top
    for y in range(3, 8):
        width = 5 - abs(y - 5)
        for x in range(24 - width, 24 + width):
            pixels[x, y] = HAIR_MID + (255,)
    # Bun outline
    for x in range(21, 27):
        pixels[x, 3] = HAIR_DARK + (255,)
    pixels[20, 4] = HAIR_DARK + (255,)
    pixels[27, 4] = HAIR_DARK + (255,)
    pixels[20, 5] = HAIR_DARK + (255,)
    pixels[27, 5] = HAIR_DARK + (255,)
    # Bun highlight
    for x in range(22, 25):
        pixels[x, 4] = HAIR_LIGHT + (255,)

    # Main hair mass
    for y in range(8, 18):
        # Hair gets wider at top, narrower at bottom
        if y < 12:
            left = 10 - (y - 8)
            right = 38 + (y - 8)
        else:
            left = 8 + (y - 12) // 2
            right = 40 - (y - 12) // 2
        for x in range(left, right):
            # Skip face area
            if y >= 13 and 14 <= x <= 34:
                continue
            pixels[x, y] = HAIR_MID + (255,)

    # Hair outline (top arc)
    for x in range(12, 36):
        pixels[x, 7] = HAIR_DARK + (255,)
    for x in range(10, 14):
        pixels[x, 8] = HAIR_DARK + (255,)
    for x in range(34, 38):
        pixels[x, 8] = HAIR_DARK + (255,)
    # Side outlines
    vline(8, 10, 16, HAIR_DARK)
    vline(39, 10, 16, HAIR_DARK)

    # Hair highlights (light strands)
    for y in range(9, 14):
        pixels[15, y] = HAIR_LIGHT + (255,)
        pixels[20, y] = HAIR_LIGHT + (255,)
        pixels[28, y] = HAIR_LIGHT + (255,)
        pixels[33, y] = HAIR_LIGHT + (255,)

    # === FACE ===
    # Base face shape (oval)
    for y in range(12, 30):
        if y < 15:
            left = 15 - (y - 12)
            right = 33 + (y - 12)
        elif y < 25:
            left = 12
            right = 36
        else:
            left = 12 + (y - 25)
            right = 36 - (y - 25)
        for x in range(left, right):
            pixels[x, y] = SKIN_MID + (255,)

    # Face shading (left side darker - light from top-left)
    for y in range(14, 28):
        if y < 20:
            pixels[13, y] = SKIN_DARK + (255,)
            pixels[14, y] = SKIN_DARK + (255,)
        if y >= 22:
            # Jawline shadow
            for x in range(13, 16):
                if 0 <= x < 48 and 0 <= y < 48 and pixels[x, y][3] > 0:
                    pixels[x, y] = SKIN_DARK + (255,)
            for x in range(32, 35):
                if 0 <= x < 48 and 0 <= y < 48 and pixels[x, y][3] > 0:
                    pixels[x, y] = SKIN_DARK + (255,)

    # Face highlight (right side)
    for y in range(14, 22):
        pixels[34, y] = SKIN_LIGHT + (255,)
        pixels[33, y] = SKIN_LIGHT + (255,)

    # Forehead highlight
    for x in range(18, 26):
        pixels[x, 13] = SKIN_LIGHT + (255,)

    # === EYES ===
    # Left eye
    # Eye white
    for x in range(16, 21):
        for y in range(18, 22):
            pixels[x, y] = EYE_WHITE + (255,)
    # Iris
    for x in range(17, 20):
        for y in range(18, 22):
            pixels[x, y] = EYE_IRIS + (255,)
    # Pupil
    pixels[18, 19] = EYE_PUPIL + (255,)
    pixels[18, 20] = EYE_PUPIL + (255,)
    # Eye highlight
    pixels[17, 18] = EYE_WHITE + (255,)
    # Eyelid line
    hline(15, 22, 17, HAIR_DARK)

    # Right eye
    # Eye white
    for x in range(27, 32):
        for y in range(18, 22):
            pixels[x, y] = EYE_WHITE + (255,)
    # Iris
    for x in range(28, 31):
        for y in range(18, 22):
            pixels[x, y] = EYE_IRIS + (255,)
    # Pupil
    pixels[29, 19] = EYE_PUPIL + (255,)
    pixels[29, 20] = EYE_PUPIL + (255,)
    # Eye highlight
    pixels[28, 18] = EYE_WHITE + (255,)
    # Eyelid line
    hline(26, 33, 17, HAIR_DARK)

    # === EYEBROWS ===
    # Gentle arched eyebrows (wise/kind expression)
    for x in range(15, 21):
        pixels[x, 15] = HAIR_DARK + (255,)
    pixels[14, 16] = HAIR_DARK + (255,)

    for x in range(27, 33):
        pixels[x, 15] = HAIR_DARK + (255,)
    pixels[33, 16] = HAIR_DARK + (255,)

    # === GLASSES ===
    # Left lens frame
    hline(14, 22, 16, GLASSES_MID)
    hline(14, 22, 23, GLASSES_MID)
    vline(14, 16, 24, GLASSES_MID)
    vline(21, 16, 24, GLASSES_MID)
    # Right lens frame
    hline(26, 34, 16, GLASSES_MID)
    hline(26, 34, 23, GLASSES_MID)
    vline(26, 16, 24, GLASSES_MID)
    vline(33, 16, 24, GLASSES_MID)
    # Bridge
    hline(22, 26, 19, GLASSES_MID)
    # Temple arms (going to sides)
    hline(10, 14, 18, GLASSES_MID)
    hline(34, 38, 18, GLASSES_MID)
    # Glasses highlights
    pixels[15, 17] = GLASSES_LIGHT + (255,)
    pixels[27, 17] = GLASSES_LIGHT + (255,)

    # === NOSE ===
    pixels[24, 22] = SKIN_DARK + (255,)
    pixels[24, 23] = SKIN_DARK + (255,)
    pixels[23, 24] = SKIN_DARK + (255,)
    pixels[25, 24] = SKIN_LIGHT + (255,)

    # === MOUTH (gentle smile) ===
    hline(20, 28, 27, SKIN_DARK)
    # Slight upturn at corners for smile
    pixels[19, 26] = SKIN_DARK + (255,)
    pixels[28, 26] = SKIN_DARK + (255,)

    # === ROBE / SHOULDERS ===
    # Shoulder and robe base
    for y in range(32, 47):
        width = min((y - 32) * 2 + 10, 22)
        left = 24 - width
        right = 24 + width
        for x in range(max(1, left), min(47, right)):
            pixels[x, y] = ROBE_MID + (255,)

    # Robe shading (left side darker)
    for y in range(34, 47):
        for x in range(4, 14):
            if pixels[x, y][3] > 0:
                pixels[x, y] = ROBE_DARK + (255,)

    # Robe highlight (right side)
    for y in range(34, 45):
        for x in range(34, 42):
            if pixels[x, y][3] > 0:
                pixels[x, y] = ROBE_LIGHT + (255,)

    # Robe collar / neckline
    for y in range(30, 34):
        left = 18 - (y - 30)
        right = 30 + (y - 30)
        hline(left, right, y, ROBE_MID)
    # Collar highlight
    hline(26, 32, 31, ROBE_LIGHT)
    hline(28, 34, 32, ROBE_LIGHT)

    # === GOLD TRIM ===
    # Collar trim
    for y in range(31, 35):
        left = 17 - (y - 31)
        right = 31 + (y - 31)
        pixels[left, y] = TRIM_GOLD + (255,)
        pixels[right, y] = TRIM_GOLD + (255,)
    # Trim shadow
    for y in range(32, 35):
        left = 16 - (y - 31)
        pixels[left, y] = TRIM_DARK + (255,)

    # Central robe trim line
    for y in range(35, 47):
        pixels[24, y] = TRIM_GOLD + (255,)
        pixels[23, y] = TRIM_DARK + (255,)

    # === BOOK (held in front) ===
    # Book cover
    rect(16, 40, 32, 46, BOOK_BROWN)
    # Book pages (white edge)
    rect(17, 41, 31, 45, EYE_WHITE)
    # Book text lines suggestion
    for y in range(42, 44):
        hline(19, 29, y, SKIN_DARK)
    # Book highlight
    hline(17, 31, 41, BOOK_LIGHT)
    # Book shadow
    hline(16, 32, 46, (80, 30, 0))

    # === FACE OUTLINE (subtle) ===
    # Just darken edges slightly for definition
    for y in range(12, 30):
        if y < 15:
            left = 15 - (y - 12) - 1
            right = 33 + (y - 12)
        elif y < 25:
            left = 11
            right = 35
        else:
            left = 12 + (y - 25) - 1
            right = 35 - (y - 25)
        if 0 <= left < 48 and pixels[left, y][3] == 0:
            pass  # Don't outline into transparent
        elif 0 <= left < 48:
            pixels[left, y] = SKIN_DARK + (255,)

    return img


def draw_lyra_encouraging():
    """Generate encouraging expression variant - raised eyebrows, bigger smile."""
    img = draw_lyra_portrait()
    pixels = img.load()

    # Modify eyebrows - raise them slightly
    # Clear old eyebrows
    for x in range(14, 22):
        if pixels[x, 15][0:3] == HAIR_DARK or pixels[x, 16][0:3] == HAIR_DARK:
            pixels[x, 15] = SKIN_MID + (255,)
    for x in range(27, 34):
        if pixels[x, 15][0:3] == HAIR_DARK or pixels[x, 16][0:3] == HAIR_DARK:
            pixels[x, 15] = SKIN_MID + (255,)
    pixels[14, 16] = SKIN_MID + (255,)
    pixels[33, 16] = SKIN_MID + (255,)

    # Draw raised eyebrows
    for x in range(15, 21):
        pixels[x, 14] = HAIR_DARK + (255,)
    pixels[15, 15] = HAIR_DARK + (255,)

    for x in range(27, 33):
        pixels[x, 14] = HAIR_DARK + (255,)
    pixels[32, 15] = HAIR_DARK + (255,)

    # Bigger smile
    for x in range(20, 28):
        pixels[x, 27] = SKIN_DARK + (255,)
    pixels[19, 26] = SKIN_DARK + (255,)
    pixels[28, 26] = SKIN_DARK + (255,)
    pixels[18, 25] = SKIN_DARK + (255,)
    pixels[29, 25] = SKIN_DARK + (255,)

    return img


if __name__ == "__main__":
    # Generate main portrait
    portrait = draw_lyra_portrait()
    portrait.save("portrait_lyra_neutral.png")
    print("Generated: portrait_lyra_neutral.png")

    # Generate encouraging expression
    encouraging = draw_lyra_encouraging()
    encouraging.save("portrait_lyra_encouraging.png")
    print("Generated: portrait_lyra_encouraging.png")

    # Generate 4x scaled version for preview
    portrait_4x = portrait.resize((192, 192), Image.NEAREST)
    portrait_4x.save("portrait_lyra_neutral_4x.png")
    print("Generated: portrait_lyra_neutral_4x.png (4x scale preview)")

    print("\nAll portraits generated successfully!")
