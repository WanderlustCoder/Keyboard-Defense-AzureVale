#!/usr/bin/env python3
"""Test pyxelate on our V12 portrait."""

from pyxelate import Pyx, Pal
from skimage import io
import os

# Get the directory this script is in
script_dir = os.path.dirname(os.path.abspath(__file__))

# Load our V12 256px portrait
input_path = os.path.join(script_dir, 'lyra_v12_neutral_256.png')
print(f"Loading: {input_path}")
image = io.imread(input_path)

print(f"Image shape: {image.shape}")

# Define a custom palette matching our Lyra colors
lyra_palette = [
    # Hair colors (lavender/purple)
    [255, 240, 248],  # Pink-white highlight
    [248, 224, 240],  # Light pink
    [232, 208, 232],  # Lavender
    [200, 168, 216],  # Mid lavender
    [152, 120, 184],  # Purple
    [104, 80, 152],   # Dark purple
    [64, 48, 104],    # Deep shadow
    # Skin colors (warm orange)
    [255, 240, 224],  # Highlight
    [240, 192, 144],  # Peach
    [224, 160, 112],  # Orange
    [176, 96, 56],    # Shadow
    # Robe colors (blue)
    [128, 144, 168],  # Light blue
    [96, 120, 152],   # Mid blue
    [64, 80, 104],    # Dark blue
    [48, 64, 88],     # Shadow
    # Background
    [24, 24, 48],     # Dark blue bg
    # Accents
    [216, 168, 96],   # Gold glasses
    [255, 255, 255],  # White (eyes, highlights)
    [16, 24, 32],     # Black (pupils)
]

# Test different pyxelate settings
tests = [
    # (factor, palette_size, dither, name)
    (2, 16, "floyd", "factor2_pal16_floyd"),
    (2, 24, "floyd", "factor2_pal24_floyd"),
    (1, 16, "bayer", "factor1_pal16_bayer"),
    (2, 16, "none", "factor2_pal16_nodither"),
    (3, 12, "atkinson", "factor3_pal12_atkinson"),
    (2, 16, "naive", "factor2_pal16_naive"),
]

for factor, palette, dither, name in tests:
    print(f"\nProcessing: {name}...")

    # Create Pyx instance
    pyx = Pyx(factor=factor, palette=palette, dither=dither)

    # Transform
    result = pyx.fit_transform(image)

    # Save
    output_path = os.path.join(script_dir, f'lyra_pyxelate_{name}.png')
    io.imsave(output_path, result)
    print(f"  Saved: {output_path}")

# Also try with custom palette
print("\nProcessing with custom Lyra palette...")
pyx_custom = Pyx(factor=2, palette=len(lyra_palette), dither="floyd")
pyx_custom.fit(image, palette=lyra_palette)
result_custom = pyx_custom.transform(image)
output_custom = os.path.join(script_dir, f'lyra_pyxelate_custom_palette.png')
io.imsave(output_custom, result_custom)
print(f"  Saved: {output_custom}")

print("\nDone! Check the output files.")
