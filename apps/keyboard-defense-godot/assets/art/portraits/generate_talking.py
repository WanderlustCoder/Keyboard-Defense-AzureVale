"""Generate a talking animation from Lyra's south-facing sprite.

Creates 4 portrait frames with visible mouth open/close animation.
Crops tightly to the face/upper body and scales up for the dialogue box.

Cycle: closed -> half-open -> open -> half-open (loop)
"""
from PIL import Image
import os

SPRITE_PATH = os.path.join(os.path.dirname(__file__), "lyra_pixellab", "rotations", "south.png")
PORTRAIT_DIR = os.path.join(os.path.dirname(__file__), "lyra_pixellab", "portraits")

# Key coordinates (from pixel analysis of the south-facing 128x128 sprite)
MOUTH_Y = 47
MOUTH_CENTER_X = 64

# Portrait crop: tight on face + shoulders (hair bun through neckline)
CROP_BOX = (44, 5, 84, 58)  # 40x53 region
PORTRAIT_SIZE = (128, 128)

# Colors sampled from the sprite
MOUTH_DARK = (86, 45, 34, 255)
MOUTH_INTERIOR = (45, 20, 18, 255)    # darker interior for visibility
SKIN_BASE = (218, 167, 144, 255)
SKIN_SHADOW = (163, 104, 83, 255)
SKIN_MID = (203, 151, 126, 255)
SKIN_DEEP = (148, 96, 84, 255)
BG_COLOR = (26, 26, 46, 255)


def make_frame_closed(base):
    """Frame 0: Mouth closed (original)."""
    return base.copy()


def make_frame_half_open(base):
    """Frame 1: Mouth slightly parted — 1px dark gap below mouth line."""
    img = base.copy()
    px = img.load()

    # The mouth line is at y=47, spanning roughly x=61-67
    # Push chin pixels (y=48-52) down by 1 to make room
    for y in range(52, 47, -1):  # bottom-up to avoid overwrite
        for x in range(59, 70):
            if y + 1 < 128:
                px[x, y + 1] = px[x, y]

    # Paint the gap row (y=48) as mouth interior
    # Wider than the original mouth line for visibility
    for x in range(61, 68):
        dist = abs(x - MOUTH_CENTER_X)
        if dist <= 1:
            px[x, 48] = MOUTH_INTERIOR
        elif dist <= 2:
            px[x, 48] = MOUTH_DARK
        else:
            px[x, 48] = SKIN_DEEP

    return img


def make_frame_open(base):
    """Frame 2: Mouth wide open — 3px tall dark opening."""
    img = base.copy()
    px = img.load()

    # Push chin pixels (y=48-53) down by 3 to make a bigger gap
    for y in range(55, 47, -1):
        for x in range(57, 72):
            if y + 3 < 128:
                px[x, y + 3] = px[x, y]

    # Paint 3 rows of mouth interior (y=48, 49, 50)
    for row in range(48, 51):
        # Slightly narrower at top and bottom for rounded shape
        width = 3 if row == 48 or row == 50 else 4
        for x in range(MOUTH_CENTER_X - width, MOUTH_CENTER_X + width + 1):
            dist = abs(x - MOUTH_CENTER_X)
            if dist <= 1:
                px[x, row] = MOUTH_INTERIOR
            elif dist <= width - 1:
                px[x, row] = MOUTH_DARK
            else:
                px[x, row] = SKIN_DEEP

    # Darken the original mouth line (top lip emphasis)
    for x in range(61, 68):
        r, g, b, a = px[x, MOUTH_Y]
        if a > 0:
            px[x, MOUTH_Y] = (max(r - 20, 0), max(g - 15, 0), max(b - 10, 0), a)

    # Bottom lip highlight below the opening
    for x in range(MOUTH_CENTER_X - 2, MOUTH_CENTER_X + 3):
        px[x, 51] = SKIN_MID

    return img


def crop_to_portrait(frame):
    """Crop to face region and scale up with nearest-neighbor."""
    cropped = frame.crop(CROP_BOX)
    crop_w, crop_h = cropped.size

    # Integer scale factor that fits in portrait size
    scale = min(PORTRAIT_SIZE[0] // crop_w, PORTRAIT_SIZE[1] // crop_h)
    new_w = crop_w * scale
    new_h = crop_h * scale
    scaled = cropped.resize((new_w, new_h), Image.NEAREST)

    # Center on dark background
    portrait = Image.new("RGBA", PORTRAIT_SIZE, BG_COLOR)
    ox = (PORTRAIT_SIZE[0] - new_w) // 2
    oy = (PORTRAIT_SIZE[1] - new_h) // 2
    portrait.paste(scaled, (ox, oy), scaled)
    return portrait


def main():
    os.makedirs(PORTRAIT_DIR, exist_ok=True)
    base = Image.open(SPRITE_PATH).convert("RGBA")

    frames = [
        make_frame_closed(base),
        make_frame_half_open(base),
        make_frame_open(base),
        make_frame_half_open(base),
    ]

    labels = ["closed", "half_open", "open", "half_open2"]
    for i, frame in enumerate(frames):
        portrait = crop_to_portrait(frame)
        path = os.path.join(PORTRAIT_DIR, f"talking_{i:03d}_{labels[i]}.png")
        portrait.save(path)
        print(f"Saved: {path}")

    # Static idle portrait
    static = crop_to_portrait(frames[0])
    static.save(os.path.join(PORTRAIT_DIR, "lyra_portrait_static.png"))

    crop_w = CROP_BOX[2] - CROP_BOX[0]
    crop_h = CROP_BOX[3] - CROP_BOX[1]
    scale = min(PORTRAIT_SIZE[0] // crop_w, PORTRAIT_SIZE[1] // crop_h)
    print(f"\nCrop: {crop_w}x{crop_h} -> {scale}x scale -> {crop_w*scale}x{crop_h*scale} in {PORTRAIT_SIZE}")
    print("Mouth opening: 3px tall at full open (visible at this scale)")
    print("Cycle: closed -> half -> open -> half (loop at 4-6 FPS)")


if __name__ == "__main__":
    main()
