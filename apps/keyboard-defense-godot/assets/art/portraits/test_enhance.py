#!/usr/bin/env python3
"""Test various enhancement techniques on our V12 portrait using Pillow."""

from PIL import Image
import os

script_dir = os.path.dirname(os.path.abspath(__file__))
input_path = os.path.join(script_dir, 'lyra_v12_neutral_256.png')

print(f"Loading: {input_path}")
img = Image.open(input_path).convert('RGBA')
print(f"Size: {img.size}")

# Define our custom palette
lyra_colors = [
    # Hair (lavender/purple)
    (255, 240, 248), (248, 224, 240), (232, 208, 232), (216, 192, 224),
    (200, 168, 216), (176, 144, 200), (152, 120, 184), (128, 96, 168),
    (104, 80, 152), (80, 64, 128), (64, 48, 104), (48, 32, 80),
    # Skin (warm orange)
    (255, 240, 224), (255, 216, 184), (240, 192, 144), (224, 160, 112),
    (208, 128, 80), (176, 96, 56),
    # Robe (blue)
    (128, 144, 168), (96, 120, 152), (80, 96, 128), (64, 80, 104),
    (48, 64, 88), (32, 48, 64),
    # Accents
    (216, 168, 96), (184, 136, 72), (144, 112, 56),  # Gold
    (255, 255, 255), (220, 220, 220),  # White
    (16, 24, 32), (24, 24, 48),  # Dark
    (240, 128, 112),  # Blush
]

def create_palette_image(colors):
    """Create a PIL palette image from color list."""
    pal_img = Image.new('P', (1, 1))
    flat_palette = []
    for r, g, b in colors:
        flat_palette.extend([r, g, b])
    # Pad to 256 colors
    while len(flat_palette) < 768:
        flat_palette.extend([0, 0, 0])
    pal_img.putpalette(flat_palette)
    return pal_img

# Test 1: Quantize to custom palette
print("\nTest 1: Custom palette quantization...")
pal_img = create_palette_image(lyra_colors)
rgb = img.convert('RGB')
quantized = rgb.quantize(colors=len(lyra_colors), palette=pal_img, dither=Image.Dither.NONE)
result1 = quantized.convert('RGBA')
result1.save(os.path.join(script_dir, 'lyra_enhanced_palette.png'))
print("  Saved: lyra_enhanced_palette.png")

# Test 2: Quantize with Floyd-Steinberg dithering
print("\nTest 2: Floyd-Steinberg dithering...")
quantized_dither = rgb.quantize(colors=len(lyra_colors), palette=pal_img, dither=Image.Dither.FLOYDSTEINBERG)
result2 = quantized_dither.convert('RGBA')
result2.save(os.path.join(script_dir, 'lyra_enhanced_dither.png'))
print("  Saved: lyra_enhanced_dither.png")

# Test 3: Posterize effect (reduce color depth)
print("\nTest 3: Posterize effect...")
from PIL import ImageOps
posterized = ImageOps.posterize(rgb, bits=4)  # 4 bits = 16 levels per channel
posterized.save(os.path.join(script_dir, 'lyra_enhanced_posterize.png'))
print("  Saved: lyra_enhanced_posterize.png")

# Test 4: Adaptive palette (let PIL choose best colors)
print("\nTest 4: Adaptive 16-color palette...")
adaptive16 = rgb.quantize(colors=16, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE)
adaptive16.convert('RGBA').save(os.path.join(script_dir, 'lyra_enhanced_adaptive16.png'))
print("  Saved: lyra_enhanced_adaptive16.png")

# Test 5: Adaptive 24-color with dither
print("\nTest 5: Adaptive 24-color with dither...")
adaptive24d = rgb.quantize(colors=24, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.FLOYDSTEINBERG)
adaptive24d.convert('RGBA').save(os.path.join(script_dir, 'lyra_enhanced_adaptive24_dither.png'))
print("  Saved: lyra_enhanced_adaptive24_dither.png")

# Test 6: Downscale then upscale (sharper pixels)
print("\nTest 6: Crisp pixel effect (downscale/upscale)...")
small = img.resize((128, 128), Image.Resampling.NEAREST)
crisp = small.resize((256, 256), Image.Resampling.NEAREST)
crisp.save(os.path.join(script_dir, 'lyra_enhanced_crisp.png'))
print("  Saved: lyra_enhanced_crisp.png")

# Test 7: Combine - downscale, quantize, upscale
print("\nTest 7: Full pixel art treatment...")
small_rgb = small.convert('RGB')
small_quant = small_rgb.quantize(colors=20, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE)
small_quant_rgba = small_quant.convert('RGBA')
final = small_quant_rgba.resize((256, 256), Image.Resampling.NEAREST)
final.save(os.path.join(script_dir, 'lyra_enhanced_full.png'))
print("  Saved: lyra_enhanced_full.png")

print("\nDone! Check the output files.")
