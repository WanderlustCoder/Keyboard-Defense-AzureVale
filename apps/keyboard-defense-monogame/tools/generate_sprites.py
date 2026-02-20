#!/usr/bin/env python3
"""
Generate procedural pixel-art PNG sprites for Keyboard Defense MonoGame.

Uses Pillow to create simple but recognizable sprites for enemies, buildings,
terrain tiles, and icons. No SVG conversion needed.

Usage:
    python tools/generate_sprites.py [--output DIR]
"""

import argparse
import json
import os
from pathlib import Path
from PIL import Image, ImageDraw


def make_pixel_image(size, draw_fn):
    """Create a pixel-art image at the given size."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw_fn(draw, size)
    return img


def make_sprite_sheet(size, draw_fn, frame_count=2, row_count=2):
    """Create a multi-frame sprite sheet (horizontal strip per row).

    Row 0 = idle: subtle 1px vertical shift between frames.
    Row 1 = walk: slight horizontal shift between frames.
    Returns (image, animation_metadata).
    """
    sheet_w = size * frame_count
    sheet_h = size * row_count
    sheet = Image.new("RGBA", (sheet_w, sheet_h), (0, 0, 0, 0))

    # Base frame
    base = make_pixel_image(size, draw_fn)

    # Shifted variant: 1px up
    shifted_up = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    shifted_up.paste(base.crop((0, 1, size, size)), (0, 0))

    # Shifted variant: 1px right
    shifted_right = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    shifted_right.paste(base.crop((0, 0, size - 1, size)), (1, 0))

    # Row 0: idle (base, shifted_up)
    sheet.paste(base, (0, 0))
    sheet.paste(shifted_up, (size, 0))

    if row_count >= 2:
        # Row 1: walk (base, shifted_right)
        sheet.paste(base, (0, size))
        sheet.paste(shifted_right, (size, size))

    animations = {
        "idle": {"frames": frame_count, "duration": 0.3, "loop": True},
    }
    if row_count >= 2:
        animations["walk"] = {"frames": frame_count, "duration": 0.15, "loop": True}

    return sheet, animations


def save_sprite(img, output_dir, category, name, animations=None):
    """Save sprite and return manifest entry."""
    cat_dir = output_dir / category
    cat_dir.mkdir(parents=True, exist_ok=True)
    path = cat_dir / f"{name}.png"
    img.save(path, "PNG")
    entry = {
        "id": name,
        "path": f"{category}/{name}.png",
        "category": category,
        "width": img.width,
        "height": img.height,
    }
    if animations:
        entry["animations"] = animations
    return entry


# =====================================================================
# ENEMY SPRITES (32x32)
# =====================================================================

def draw_enemy_runner(draw, s):
    """Fast enemy - slim, angular."""
    c = (50, 200, 50)
    draw.rectangle([10, 4, 22, 12], fill=c)  # head
    draw.rectangle([8, 12, 24, 24], fill=c)  # body
    draw.rectangle([8, 24, 12, 30], fill=c)  # left leg
    draw.rectangle([20, 24, 24, 30], fill=c)  # right leg
    draw.point([12, 7], fill=(255, 255, 255))  # eye
    draw.point([19, 7], fill=(255, 255, 255))  # eye

def draw_enemy_brute(draw, s):
    """Tank enemy - wide, bulky."""
    c = (200, 60, 60)
    draw.rectangle([8, 2, 24, 12], fill=c)  # head
    draw.rectangle([4, 12, 28, 26], fill=c)  # wide body
    draw.rectangle([6, 26, 12, 31], fill=c)  # left leg
    draw.rectangle([20, 26, 26, 31], fill=c)  # right leg
    draw.point([12, 6], fill=(255, 255, 255))
    draw.point([20, 6], fill=(255, 255, 255))

def draw_enemy_flyer(draw, s):
    """Flying enemy - wings spread."""
    c = (100, 100, 220)
    draw.rectangle([12, 8, 20, 16], fill=c)  # body
    draw.polygon([(2, 10), (12, 8), (12, 16)], fill=c)  # left wing
    draw.polygon([(30, 10), (20, 8), (20, 16)], fill=c)  # right wing
    draw.rectangle([14, 16, 18, 24], fill=c)  # tail
    draw.point([14, 10], fill=(255, 255, 255))
    draw.point([17, 10], fill=(255, 255, 255))

def draw_enemy_healer(draw, s):
    """Healer - cross symbol."""
    c = (50, 200, 200)
    draw.rectangle([10, 4, 22, 14], fill=c)  # head
    draw.rectangle([8, 14, 24, 26], fill=c)  # body
    # Cross on body
    draw.rectangle([14, 16, 18, 24], fill=(255, 255, 255))
    draw.rectangle([11, 18, 21, 22], fill=(255, 255, 255))
    draw.rectangle([10, 26, 14, 30], fill=c)
    draw.rectangle([18, 26, 22, 30], fill=c)

def draw_enemy_shielder(draw, s):
    """Shield enemy - shield in front."""
    c = (150, 150, 170)
    draw.rectangle([12, 4, 22, 12], fill=c)  # head
    draw.rectangle([10, 12, 24, 24], fill=c)  # body
    draw.rectangle([4, 8, 10, 22], fill=(100, 120, 180))  # shield
    draw.rectangle([10, 24, 14, 30], fill=c)
    draw.rectangle([20, 24, 24, 30], fill=c)

def draw_enemy_swarm(draw, s):
    """Swarm - small cluster."""
    c = (220, 160, 40)
    for pos in [(6, 6), (18, 4), (10, 16), (22, 14), (14, 24)]:
        draw.rectangle([pos[0], pos[1], pos[0]+6, pos[1]+6], fill=c)
        draw.point([pos[0]+2, pos[1]+2], fill=(255, 255, 255))

def draw_enemy_armored(draw, s):
    """Armored - helmet + plate."""
    c = (130, 130, 140)
    draw.rectangle([8, 2, 24, 8], fill=(80, 80, 90))  # helmet
    draw.rectangle([10, 8, 22, 14], fill=c)  # head
    draw.rectangle([6, 14, 26, 26], fill=(80, 80, 90))  # armor
    draw.rectangle([8, 26, 12, 31], fill=c)
    draw.rectangle([20, 26, 24, 31], fill=c)

def draw_enemy_boss_warlord(draw, s):
    """Boss warlord - large, crowned."""
    c = (200, 30, 30)
    # Crown
    draw.rectangle([8, 0, 24, 4], fill=(250, 214, 112))
    draw.rectangle([8, 0, 10, 2], fill=(250, 214, 112))
    draw.rectangle([15, 0, 17, 2], fill=(250, 214, 112))
    draw.rectangle([22, 0, 24, 2], fill=(250, 214, 112))
    draw.rectangle([8, 4, 24, 12], fill=c)  # head
    draw.rectangle([4, 12, 28, 26], fill=c)  # body
    draw.rectangle([6, 26, 12, 31], fill=c)
    draw.rectangle([20, 26, 26, 31], fill=c)
    draw.point([12, 7], fill=(255, 200, 0))
    draw.point([20, 7], fill=(255, 200, 0))

def draw_enemy_boss_mage(draw, s):
    """Boss mage - robed, glowing."""
    c = (120, 40, 180)
    draw.rectangle([10, 2, 22, 10], fill=c)  # head
    draw.polygon([(8, 2), (16, -2), (24, 2)], fill=(80, 20, 140))  # hat
    draw.rectangle([6, 10, 26, 26], fill=(80, 20, 140))  # robe
    draw.rectangle([2, 14, 6, 20], fill=c)  # left arm (staff)
    draw.rectangle([3, 12, 5, 14], fill=(100, 200, 255))  # staff glow
    draw.point([13, 5], fill=(200, 200, 255))
    draw.point([19, 5], fill=(200, 200, 255))

def draw_enemy_scout(draw, s):
    """Scout - small, fast."""
    c = (180, 180, 60)
    draw.rectangle([12, 6, 20, 12], fill=c)  # head
    draw.rectangle([10, 12, 22, 22], fill=c)  # body
    draw.rectangle([10, 22, 14, 28], fill=c)
    draw.rectangle([18, 22, 22, 28], fill=c)
    draw.point([14, 8], fill=(255, 255, 255))
    draw.point([18, 8], fill=(255, 255, 255))

def draw_enemy_raider(draw, s):
    """Raider - slim with blade."""
    c = (50, 200, 50)
    draw.rectangle([10, 4, 22, 12], fill=c)  # head
    draw.rectangle([8, 12, 24, 24], fill=c)  # body
    draw.rectangle([8, 24, 12, 30], fill=c)  # left leg
    draw.rectangle([20, 24, 24, 30], fill=c)  # right leg
    # Blade
    draw.line([(24, 10), (30, 4)], fill=(200, 200, 210), width=2)
    draw.point([12, 7], fill=(255, 255, 255))
    draw.point([19, 7], fill=(255, 255, 255))

def draw_enemy_tank(draw, s):
    """Tank - very wide and bulky with heavy armor."""
    c = (120, 100, 80)
    draw.rectangle([6, 4, 26, 10], fill=(80, 80, 90))  # helmet
    draw.rectangle([8, 10, 24, 14], fill=c)  # head
    draw.rectangle([2, 14, 30, 28], fill=(80, 80, 90))  # heavy armor
    draw.rectangle([6, 28, 12, 31], fill=c)
    draw.rectangle([20, 28, 26, 31], fill=c)
    draw.point([12, 7], fill=(255, 80, 80))
    draw.point([20, 7], fill=(255, 80, 80))

def draw_enemy_berserker(draw, s):
    """Berserker - wild, red-tinged."""
    c = (200, 60, 60)
    draw.rectangle([8, 2, 24, 12], fill=c)  # head
    draw.rectangle([6, 12, 26, 24], fill=c)  # body
    # Spiky hair
    for x in [8, 12, 16, 20]:
        draw.polygon([(x, 2), (x+2, -2), (x+4, 2)], fill=(220, 40, 40))
    draw.rectangle([6, 24, 12, 31], fill=c)
    draw.rectangle([20, 24, 26, 31], fill=c)
    draw.point([12, 6], fill=(255, 255, 100))
    draw.point([20, 6], fill=(255, 255, 100))

def draw_enemy_phantom(draw, s):
    """Phantom - ghostly, semi-transparent look."""
    c = (140, 120, 200)
    draw.rectangle([10, 4, 22, 12], fill=c)  # head
    draw.rectangle([8, 12, 24, 24], fill=c)  # body
    # Tattered bottom (no legs, wispy)
    draw.polygon([(8, 24), (10, 30), (14, 26)], fill=c)
    draw.polygon([(14, 24), (18, 30), (20, 26)], fill=c)
    draw.polygon([(20, 24), (24, 28), (22, 24)], fill=c)
    draw.point([13, 7], fill=(255, 200, 255))
    draw.point([19, 7], fill=(255, 200, 255))

def draw_enemy_champion(draw, s):
    """Champion - armored warrior with shield."""
    c = (180, 160, 60)
    draw.rectangle([10, 2, 22, 10], fill=(150, 140, 50))  # helm
    draw.rectangle([12, 10, 20, 14], fill=c)  # head
    draw.rectangle([8, 14, 24, 26], fill=c)  # body
    draw.rectangle([2, 10, 8, 24], fill=(100, 120, 180))  # shield
    draw.rectangle([24, 12, 28, 16], fill=(200, 200, 210))  # sword hilt
    draw.line([(26, 12), (30, 4)], fill=(200, 200, 210), width=2)
    draw.rectangle([8, 26, 12, 31], fill=c)
    draw.rectangle([20, 26, 24, 31], fill=c)

def draw_enemy_elite(draw, s):
    """Elite - tall, imposing."""
    c = (160, 80, 160)
    draw.rectangle([10, 2, 22, 10], fill=c)  # head
    draw.rectangle([8, 10, 24, 24], fill=(140, 60, 140))  # body
    # Shoulder pads
    draw.rectangle([4, 10, 10, 14], fill=(120, 40, 120))
    draw.rectangle([22, 10, 28, 14], fill=(120, 40, 120))
    draw.rectangle([8, 24, 12, 31], fill=c)
    draw.rectangle([20, 24, 24, 31], fill=c)
    draw.point([13, 5], fill=(255, 200, 255))
    draw.point([19, 5], fill=(255, 200, 255))

def draw_enemy_forest_guardian(draw, s):
    """Boss: Forest Guardian - tree-like, massive."""
    c = (40, 120, 40)
    draw.rectangle([8, 6, 24, 14], fill=c)  # head
    draw.rectangle([4, 14, 28, 28], fill=(60, 90, 40))  # body
    # Leaf crown
    draw.polygon([(6, 6), (10, 0), (14, 6)], fill=(30, 150, 30))
    draw.polygon([(14, 6), (18, 0), (22, 6)], fill=(30, 150, 30))
    draw.polygon([(22, 6), (26, 0), (28, 6)], fill=(30, 150, 30))
    # Bark texture
    draw.line([(10, 16), (10, 26)], fill=(50, 70, 30))
    draw.line([(22, 16), (22, 26)], fill=(50, 70, 30))
    draw.rectangle([6, 28, 12, 31], fill=(60, 90, 40))
    draw.rectangle([20, 28, 26, 31], fill=(60, 90, 40))
    draw.point([12, 9], fill=(200, 255, 100))
    draw.point([20, 9], fill=(200, 255, 100))

def draw_enemy_stone_golem(draw, s):
    """Boss: Stone Golem - blocky, massive."""
    c = (130, 130, 140)
    draw.rectangle([6, 4, 26, 12], fill=c)  # head
    draw.rectangle([2, 12, 30, 28], fill=(110, 110, 120))  # body
    # Cracks
    draw.line([(10, 14), (8, 20), (12, 24)], fill=(80, 80, 90))
    draw.line([(22, 16), (24, 22)], fill=(80, 80, 90))
    draw.rectangle([4, 28, 12, 31], fill=c)
    draw.rectangle([20, 28, 28, 31], fill=c)
    draw.point([10, 7], fill=(200, 100, 100))
    draw.point([22, 7], fill=(200, 100, 100))

def draw_enemy_fen_seer(draw, s):
    """Boss: Fen Seer - mystical swamp creature."""
    c = (60, 120, 100)
    draw.rectangle([10, 2, 22, 10], fill=c)  # head
    draw.polygon([(8, 2), (16, -4), (24, 2)], fill=(40, 100, 80))  # hood
    draw.rectangle([6, 10, 26, 26], fill=(40, 100, 80))  # robe
    # Glowing orb
    draw.ellipse([12, 14, 20, 22], fill=(100, 255, 200))
    draw.ellipse([14, 16, 18, 20], fill=(150, 255, 220))
    draw.point([13, 5], fill=(100, 255, 200))
    draw.point([19, 5], fill=(100, 255, 200))

def draw_enemy_sunlord(draw, s):
    """Boss: Sunlord - radiant, powerful."""
    c = (220, 180, 40)
    # Solar crown
    for angle_x in [6, 10, 14, 18, 22]:
        draw.polygon([(angle_x, 4), (angle_x+2, -2), (angle_x+4, 4)], fill=(255, 220, 60))
    draw.rectangle([8, 4, 24, 12], fill=c)  # head
    draw.rectangle([4, 12, 28, 26], fill=(200, 160, 30))  # body
    # Armor plates
    draw.rectangle([6, 14, 10, 18], fill=(240, 200, 60))
    draw.rectangle([22, 14, 26, 18], fill=(240, 200, 60))
    draw.rectangle([6, 26, 12, 31], fill=c)
    draw.rectangle([20, 26, 26, 31], fill=c)
    draw.point([12, 7], fill=(255, 255, 200))
    draw.point([20, 7], fill=(255, 255, 200))


# =====================================================================
# BUILDING SPRITES (48x48)
# =====================================================================

def draw_bld_castle(draw, s):
    """Castle - main structure."""
    c = (160, 140, 100)
    draw.rectangle([8, 16, 40, 44], fill=c)  # main
    # Battlements
    for x in range(8, 40, 8):
        draw.rectangle([x, 12, x+4, 16], fill=c)
    # Gate
    draw.rectangle([18, 30, 30, 44], fill=(60, 40, 20))
    draw.arc([18, 26, 30, 34], 180, 0, fill=c, width=2)
    # Towers
    draw.rectangle([4, 8, 12, 44], fill=(140, 120, 80))
    draw.rectangle([36, 8, 44, 44], fill=(140, 120, 80))

def draw_bld_farm(draw, s):
    """Farm - barn with wheat."""
    draw.rectangle([8, 20, 40, 44], fill=(140, 90, 40))  # barn
    draw.polygon([(8, 20), (24, 8), (40, 20)], fill=(160, 60, 40))  # roof
    draw.rectangle([20, 32, 28, 44], fill=(80, 50, 20))  # door
    # Wheat
    for x in [4, 42, 44]:
        draw.line([(x, 44), (x, 36)], fill=(200, 180, 50), width=1)

def draw_bld_wall(draw, s):
    """Wall segment."""
    c = (120, 110, 100)
    draw.rectangle([4, 16, 44, 44], fill=c)
    # Brick lines
    for y in range(20, 44, 6):
        draw.line([(4, y), (44, y)], fill=(100, 90, 80))
    for y in range(20, 44, 12):
        for x in range(4, 44, 10):
            draw.line([(x, y), (x, y+6)], fill=(100, 90, 80))
    # Battlements
    for x in range(4, 44, 10):
        draw.rectangle([x, 12, x+6, 16], fill=c)

def draw_bld_tower_arrow(draw, s):
    """Arrow tower."""
    c = (140, 120, 100)
    draw.rectangle([14, 12, 34, 44], fill=c)
    draw.polygon([(14, 12), (24, 4), (34, 12)], fill=(120, 100, 80))
    # Arrow slit
    draw.rectangle([22, 18, 26, 28], fill=(40, 30, 20))
    # Arrow tip
    draw.polygon([(22, 6), (24, 2), (26, 6)], fill=(200, 200, 200))

def draw_bld_tower_slow(draw, s):
    """Slow tower - ice themed."""
    c = (100, 150, 200)
    draw.rectangle([14, 12, 34, 44], fill=c)
    draw.polygon([(14, 12), (24, 4), (34, 12)], fill=(80, 120, 180))
    draw.rectangle([20, 18, 28, 30], fill=(150, 200, 255))  # crystal
    draw.polygon([(20, 18), (24, 10), (28, 18)], fill=(180, 220, 255))

def draw_bld_tower_fire(draw, s):
    """Fire tower."""
    c = (160, 80, 40)
    draw.rectangle([14, 12, 34, 44], fill=c)
    draw.polygon([(14, 12), (24, 4), (34, 12)], fill=(140, 60, 20))
    # Flame
    draw.polygon([(20, 16), (24, 6), (28, 16)], fill=(255, 160, 40))
    draw.polygon([(22, 16), (24, 10), (26, 16)], fill=(255, 220, 60))

def draw_bld_library(draw, s):
    """Library building."""
    c = (120, 100, 140)
    draw.rectangle([8, 20, 40, 44], fill=c)
    draw.polygon([(8, 20), (24, 10), (40, 20)], fill=(100, 80, 120))
    draw.rectangle([18, 30, 30, 44], fill=(80, 60, 100))  # door
    # Windows
    draw.rectangle([12, 24, 16, 28], fill=(200, 200, 160))
    draw.rectangle([32, 24, 36, 28], fill=(200, 200, 160))
    # Book symbol
    draw.rectangle([20, 14, 28, 18], fill=(200, 180, 100))

def draw_bld_barracks(draw, s):
    """Barracks."""
    c = (100, 80, 60)
    draw.rectangle([6, 18, 42, 44], fill=c)
    draw.rectangle([6, 14, 42, 18], fill=(80, 60, 40))  # roof edge
    draw.polygon([(6, 14), (24, 6), (42, 14)], fill=(120, 60, 40))
    # Doors
    draw.rectangle([12, 30, 18, 44], fill=(60, 40, 20))
    draw.rectangle([30, 30, 36, 44], fill=(60, 40, 20))
    # Flag
    draw.line([(24, 6), (24, 0)], fill=(80, 60, 40), width=1)
    draw.rectangle([24, 0, 30, 4], fill=(200, 40, 40))

def draw_bld_market(draw, s):
    """Market building."""
    c = (180, 150, 80)
    draw.rectangle([8, 22, 40, 44], fill=c)
    # Awning
    draw.rectangle([4, 16, 44, 22], fill=(200, 60, 40))
    draw.rectangle([4, 16, 14, 22], fill=(220, 80, 40))
    draw.rectangle([24, 16, 34, 22], fill=(220, 80, 40))
    # Door
    draw.rectangle([20, 32, 28, 44], fill=(120, 90, 40))
    # Gold coin symbol
    draw.ellipse([22, 24, 26, 28], fill=(250, 214, 112))


# =====================================================================
# TERRAIN TILES (32x32)
# =====================================================================

def draw_tile_forest(draw, s):
    """Forest terrain."""
    draw.rectangle([0, 0, 31, 31], fill=(30, 70, 30))
    # Trees
    for pos in [(4, 4), (16, 2), (24, 8), (8, 18), (20, 20)]:
        draw.polygon([(pos[0], pos[1]+8), (pos[0]+4, pos[1]), (pos[0]+8, pos[1]+8)], fill=(40, 100, 40))
        draw.rectangle([pos[0]+3, pos[1]+8, pos[0]+5, pos[1]+12], fill=(80, 50, 30))

def draw_tile_mountain(draw, s):
    """Mountain terrain."""
    draw.rectangle([0, 0, 31, 31], fill=(100, 90, 70))
    draw.polygon([(4, 28), (12, 8), (20, 28)], fill=(130, 120, 100))
    draw.polygon([(14, 28), (24, 4), (31, 28)], fill=(140, 130, 110))
    # Snow cap
    draw.polygon([(22, 8), (24, 4), (26, 8)], fill=(220, 220, 230))

def draw_tile_water(draw, s):
    """Water terrain."""
    draw.rectangle([0, 0, 31, 31], fill=(30, 60, 130))
    # Waves
    for y in range(4, 28, 8):
        draw.arc([0, y, 16, y+8], 0, 180, fill=(50, 80, 160), width=1)
        draw.arc([16, y+4, 32, y+12], 0, 180, fill=(50, 80, 160), width=1)

def draw_tile_plain(draw, s):
    """Plain/grass terrain."""
    draw.rectangle([0, 0, 31, 31], fill=(60, 110, 40))
    # Grass tufts
    for pos in [(6, 8), (18, 6), (26, 16), (10, 22), (22, 24)]:
        draw.line([(pos[0], pos[1]+4), (pos[0], pos[1])], fill=(70, 130, 50))
        draw.line([(pos[0]+2, pos[1]+4), (pos[0]+1, pos[1]+1)], fill=(70, 130, 50))

def draw_tile_road(draw, s):
    """Road terrain."""
    draw.rectangle([0, 0, 31, 31], fill=(80, 75, 65))
    draw.rectangle([10, 0, 22, 31], fill=(110, 100, 85))
    # Center line
    for y in range(2, 30, 8):
        draw.rectangle([15, y, 17, y+4], fill=(130, 120, 100))

def draw_tile_desert(draw, s):
    """Desert terrain."""
    draw.rectangle([0, 0, 31, 31], fill=(190, 170, 120))
    # Sand dunes
    draw.arc([0, 16, 20, 28], 180, 0, fill=(200, 180, 130), width=2)
    draw.arc([12, 20, 32, 30], 180, 0, fill=(200, 180, 130), width=2)


# =====================================================================
# ICONS (16x16)
# =====================================================================

def draw_ico_gold(draw, s):
    """Gold coin icon."""
    draw.ellipse([2, 2, 13, 13], fill=(250, 214, 112))
    draw.ellipse([4, 4, 11, 11], fill=(220, 184, 82))
    draw.text((6, 3), "G", fill=(250, 214, 112))

def draw_ico_wood(draw, s):
    """Wood resource icon."""
    draw.rectangle([3, 4, 7, 14], fill=(140, 90, 40))
    draw.rectangle([9, 2, 13, 12], fill=(160, 100, 50))
    draw.rectangle([3, 2, 7, 4], fill=(50, 100, 40))

def draw_ico_stone(draw, s):
    """Stone resource icon."""
    draw.polygon([(2, 12), (8, 2), (14, 12)], fill=(130, 130, 140))
    draw.polygon([(4, 14), (10, 8), (14, 14)], fill=(110, 110, 120))

def draw_ico_food(draw, s):
    """Food resource icon."""
    draw.ellipse([3, 6, 13, 14], fill=(200, 60, 40))  # apple
    draw.rectangle([7, 2, 9, 6], fill=(80, 50, 30))  # stem
    draw.polygon([(9, 2), (13, 4), (9, 4)], fill=(50, 120, 40))  # leaf

def draw_ico_hp(draw, s):
    """HP/heart icon."""
    draw.polygon([(8, 14), (2, 6), (6, 2), (8, 4), (10, 2), (14, 6)], fill=(220, 40, 40))

def draw_ico_threat(draw, s):
    """Threat/skull icon."""
    draw.ellipse([3, 2, 13, 12], fill=(200, 200, 200))
    draw.rectangle([4, 10, 12, 14], fill=(200, 200, 200))
    draw.rectangle([5, 5, 7, 8], fill=(40, 40, 40))  # eye
    draw.rectangle([9, 5, 11, 8], fill=(40, 40, 40))  # eye
    draw.rectangle([7, 10, 9, 12], fill=(40, 40, 40))  # nose

def draw_ico_shield(draw, s):
    """Shield icon."""
    draw.polygon([(8, 14), (2, 4), (8, 2), (14, 4)], fill=(100, 120, 180))
    draw.polygon([(8, 12), (4, 5), (8, 3), (12, 5)], fill=(120, 140, 200))

def draw_ico_sword(draw, s):
    """Sword/attack icon."""
    draw.line([(4, 12), (12, 4)], fill=(200, 200, 210), width=2)
    draw.polygon([(12, 4), (14, 2), (14, 6)], fill=(200, 200, 210))
    draw.rectangle([3, 11, 5, 13], fill=(140, 100, 40))  # handle


# =====================================================================
# MAIN
# =====================================================================

ENEMIES = {
    # Regular kinds (match Core/Combat/Enemies.cs EnemyKinds)
    "enemy_scout": draw_enemy_scout,
    "enemy_raider": draw_enemy_raider,
    "enemy_armored": draw_enemy_armored,
    "enemy_swarm": draw_enemy_swarm,
    "enemy_tank": draw_enemy_tank,
    "enemy_berserker": draw_enemy_berserker,
    "enemy_phantom": draw_enemy_phantom,
    "enemy_champion": draw_enemy_champion,
    "enemy_healer": draw_enemy_healer,
    "enemy_elite": draw_enemy_elite,
    # Boss kinds (match Core/Combat/Enemies.cs BossKinds)
    "enemy_forest_guardian": draw_enemy_forest_guardian,
    "enemy_stone_golem": draw_enemy_stone_golem,
    "enemy_fen_seer": draw_enemy_fen_seer,
    "enemy_sunlord": draw_enemy_sunlord,
    # Legacy aliases
    "enemy_runner": draw_enemy_runner,
    "enemy_brute": draw_enemy_brute,
    "enemy_flyer": draw_enemy_flyer,
    "enemy_shielder": draw_enemy_shielder,
    "enemy_boss_warlord": draw_enemy_boss_warlord,
    "enemy_boss_mage": draw_enemy_boss_mage,
}

BUILDINGS = {
    "bld_castle": draw_bld_castle,
    "bld_farm": draw_bld_farm,
    "bld_wall": draw_bld_wall,
    "bld_tower_arrow": draw_bld_tower_arrow,
    "bld_tower_slow": draw_bld_tower_slow,
    "bld_tower_fire": draw_bld_tower_fire,
    "bld_library": draw_bld_library,
    "bld_barracks": draw_bld_barracks,
    "bld_market": draw_bld_market,
}

TILES = {
    "tile_forest": draw_tile_forest,
    "tile_mountain": draw_tile_mountain,
    "tile_water": draw_tile_water,
    "tile_plain": draw_tile_plain,
    "tile_road": draw_tile_road,
    "tile_desert": draw_tile_desert,
}

ICONS = {
    "ico_gold": draw_ico_gold,
    "ico_wood": draw_ico_wood,
    "ico_stone": draw_ico_stone,
    "ico_food": draw_ico_food,
    "ico_hp": draw_ico_hp,
    "ico_threat": draw_ico_threat,
    "ico_shield": draw_ico_shield,
    "ico_sword": draw_ico_sword,
}


def main():
    parser = argparse.ArgumentParser(description="Generate procedural sprites")
    parser.add_argument("--output", default=None, help="Output directory")
    args = parser.parse_args()

    # Script lives at apps/keyboard-defense-monogame/tools/generate_sprites.py
    # so parent.parent is already the monogame project root
    monogame_root = Path(__file__).parent.parent
    output_dir = Path(args.output) if args.output else monogame_root / "Content" / "Textures"

    output_dir.mkdir(parents=True, exist_ok=True)
    manifest_entries = []

    # Generate enemies as 2-frame sprite sheets (64x64: 2 cols x 2 rows of 32x32)
    print("Generating enemy sprite sheets...")
    for name, draw_fn in ENEMIES.items():
        sheet, anims = make_sprite_sheet(32, draw_fn, frame_count=2, row_count=2)
        entry = save_sprite(sheet, output_dir, "sprites", name, animations=anims)
        manifest_entries.append(entry)
        print(f"  {name} -> {entry['path']} ({sheet.width}x{sheet.height})")

    # Generate buildings as 2-frame sprite sheets (96x48: 2 cols x 1 row of 48x48)
    print("Generating building sprite sheets...")
    for name, draw_fn in BUILDINGS.items():
        sheet, anims = make_sprite_sheet(48, draw_fn, frame_count=2, row_count=1)
        entry = save_sprite(sheet, output_dir, "sprites", name, animations=anims)
        manifest_entries.append(entry)
        print(f"  {name} -> {entry['path']} ({sheet.width}x{sheet.height})")

    # Generate terrain tiles (32x32)
    print("Generating terrain tiles...")
    for name, draw_fn in TILES.items():
        img = make_pixel_image(32, draw_fn)
        entry = save_sprite(img, output_dir, "tiles", name)
        manifest_entries.append(entry)
        print(f"  {name} -> {entry['path']}")

    # Generate icons (16x16)
    print("Generating icons...")
    for name, draw_fn in ICONS.items():
        img = make_pixel_image(16, draw_fn)
        entry = save_sprite(img, output_dir, "icons", name)
        manifest_entries.append(entry)
        print(f"  {name} -> {entry['path']}")

    # Write manifest
    manifest_path = output_dir / "texture_manifest.json"
    with open(manifest_path, "w") as f:
        json.dump({
            "version": "1.0.0",
            "generated": "procedural",
            "textures": manifest_entries,
        }, f, indent=2)

    total = len(manifest_entries)
    print(f"\nDone: {total} sprites generated")
    print(f"  Enemies: {len(ENEMIES)}")
    print(f"  Buildings: {len(BUILDINGS)}")
    print(f"  Tiles: {len(TILES)}")
    print(f"  Icons: {len(ICONS)}")
    print(f"Manifest: {manifest_path}")


if __name__ == "__main__":
    main()
