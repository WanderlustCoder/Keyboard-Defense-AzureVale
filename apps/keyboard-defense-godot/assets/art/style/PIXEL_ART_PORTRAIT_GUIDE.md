# Pixel Art Style Guide for Wise-Mentor Character

This document provides practical guidance for generating pixel-art assets that match the wise mentor portrait aesthetic used in the project. It is intended for code-generation models such as Claude Code and Codex to produce art assets programmatically. The guidelines combine design specifications from the project repository with modern high-resolution pixel-art techniques.

## 1. Canvas and Resolution

### High-Resolution Portraits (Primary Style)

Use a **128×128 pixel canvas** (or larger) for detailed character portraits. This allows for:
- Expressive facial features with visible eye reflections and subtle emotions
- Rich hair texture with individual strand clusters
- Cloth folds and material detail in clothing
- Smooth color gradients using pixel clusters rather than hard edges

Reference: `assets/art/portraits/HighRes.png`

Include the character from approximately chest-up, with the head taking roughly 40-50% of the frame height.

### Background

Use a **solid dark navy background** (`#1a1a2e` to `#0d1b2a`) to make the character pop. The background should be darker than any shadow tones on the character.

### Low-Resolution Sprites (For in-game use)

Use a 16×24-pixel frame for in-game characters. The character spec defines base proportions: the head occupies rows 1–6 (25%), the torso rows 7–16 (42%), the legs rows 17–22 (25%) and a 2-pixel ground shadow.

## 2. Color Palette Philosophy

Unlike strict 16-bit limitations, high-res pixel art uses **expanded palettes** with smooth color ramps:

### Color Ramp Approach

For each material, create a **5-8 shade ramp** from highlight to deep shadow:
- **Highlight** - Brightest point where light hits directly
- **Light** - General lit areas
- **Mid-light** - Transition zone
- **Base** - The "local color" of the material
- **Mid-shadow** - Transition to shadow
- **Shadow** - General shadowed areas
- **Deep shadow** - Darkest crevices and outlines

### Hue Shifting

Shift hues as values change:
- **Highlights** - Shift toward warm (yellow/orange) or toward the light source color
- **Shadows** - Shift toward cool (blue/purple) or complementary colors
- This creates more vibrant, lively colors than just darkening/lightening

### Mentor Palette (Expanded)

| Element  | Highlight | Light | Base | Shadow | Deep Shadow |
|----------|-----------|-------|------|--------|-------------|
| Skin     | #ffe4c4   | #f5d4b3 | #e8b896 | #c49477 | #8b6550 |
| Hair     | #d4b8e8   | #b490d0 | #8b68a8 | #5c3d7a | #3a2255 |
| Robe     | #5a8ab0   | #3d6a8f | #2a5070 | #1a3550 | #0f2238 |
| Book     | #c49660   | #a67840 | #7a5020 | #503010 | #2a1808 |
| Glasses  | #c0c8d0   | #98a4b0 | #707880 | #484850 | #282830 |
| Gold trim| #ffe070   | #f0c840 | #d4a020 | #a07010 | #604008 |

## 3. Shading and Rendering Techniques

### Soft Pixel Clusters (Anti-Aliased Style)

Instead of hard 1-pixel outlines, use **pixel clusters** to create soft edges:
- Group 2-4 pixels of similar shades to form gradient transitions
- Outlines should blend into the surrounding colors rather than being a stark single color
- Use darker versions of adjacent colors for outlines, not pure black

### Light Source

Use **top-left lighting** as the primary light source:
- Brightest highlights on top-left edges of forms (hair, forehead, shoulders)
- Core shadows on bottom-right
- Add subtle **rim lighting** on the shadow side for depth (a thin line of lighter color)

### Hair Rendering

Hair is one of the most detailed elements:
- Create visible **strand clusters** - groups of 3-8 pixels flowing in the same direction
- Use **5+ shades** from bright highlight to deep shadow
- Add individual bright pixels as **shine spots** on the crown
- The bun should have circular highlight patterns showing its rounded form

### Face and Skin

- **Eyes**: Large, expressive with visible white highlights (catchlights) in the pupils
- **Glasses**: Show frame thickness with highlight on top edge, shadow on bottom
- **Nose and mouth**: Subtle, suggested with minimal lines - use shadow shapes rather than hard outlines
- **Cheeks**: Warm undertones, slightly rosier than surrounding skin

### Clothing Folds

- Show fabric weight through fold patterns
- Robes have soft, flowing folds with gradual shadow transitions
- Use **4-6 shades** minimum for cloth
- Gold trim should have strong contrast (bright yellow highlights, deep orange-brown shadows)

## 4. Character Design - Lyra the Mentor

Based on the reference portrait (`HighRes.png`), Lyra has these defining characteristics:

### Hair
- **Color**: Lavender/purple with pink-tinted highlights
- **Style**: Voluminous, wavy hair pulled up into a high bun
- **Detail level**: Individual strand clusters visible, lots of highlight variation
- **Bun**: Rounded with spiral highlight pattern, secured at the crown

### Face
- **Shape**: Soft, youthful oval with gentle features
- **Skin tone**: Warm peachy-tan with golden undertones
- **Eyes**: Large and expressive behind glasses, dark pupils with bright catchlights
- **Expression**: Warm, knowing smile - approachable and wise

### Glasses
- **Style**: Round frames, slightly oversized
- **Color**: Warm brown/amber frames (not gray)
- **Rendering**: Show lens reflection as subtle highlight, frame thickness visible

### Clothing
- **Robe**: Deep blue/navy with visible fabric texture
- **Style**: Scholar's robe with soft draping folds
- **Shoulders**: Slightly puffed or layered look

### Accessories
- **Book**: Open book held at chest level
- **Pages**: Cream/off-white with visible text lines suggested
- **Binding**: Warm brown leather with gold accents

### Expression Variants

For different expressions, modify:
- **Eyebrow angle**: Raised (surprised/encouraging), furrowed (concerned/thinking)
- **Eye shape**: Wide (excited), softened (proud), squinted (thinking)
- **Mouth**: Smile width, open/closed, slight frown for concern
- Keep changes subtle - this style conveys emotion through small adjustments

## 5. Programmatic Generation Approaches

### Complexity Note

High-resolution pixel art like the reference image requires **thousands of carefully placed pixels** with nuanced color choices. Fully programmatic generation is challenging but possible with these approaches:

### Approach 1: Region-Based with Gradient Fills (Python + Pillow)

Define regions (hair, face, robe) as polygons, then fill with multi-step gradients based on distance from light source.

### Approach 2: Layer Composition

Create separate layers for:
1. Base silhouette fills
2. Shadow shapes
3. Highlight shapes
4. Detail overlays (hair strands, cloth folds)
5. Final touches (catchlights, rim light)

### Approach 3: Procedural with Hand-Tuned Parameters

Use noise functions and color ramps to generate organic-looking textures, with hand-tuned parameters per material type.

### Simple Starting Example (32×32)

Below is a minimal example showing the basic structure. For high-res output, expand this to 128×128+ and add many more gradient steps and detail layers:

```python
from PIL import Image

# Define palette (RGB)
SKIN_LIGHT  = (245, 203, 167)   # #f5cba7
HAIR_DARK   = (74, 35, 90)      # #4a235a
HAIR_LIGHT  = (116, 75, 140)    # lighter hair shade
ROBE_MID    = (26, 82, 118)     # #1a5276
ROBE_LIGHT  = (40, 108, 156)    # lighter robe shade
TRIM_GOLD   = (244, 208, 63)    # #f4d03f
BOOK_BROWN  = (110, 44, 0)      # #6e2c00

def draw_mentor():
    # Create blank image with transparent background (RGBA)
    img = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    pixels = img.load()

    # Draw simple hair silhouette
    for x in range(6, 26):
        for y in range(4, 10):
            pixels[x, y] = HAIR_DARK
    for x in range(8, 24):
        for y in range(6, 8):
            pixels[x, y] = HAIR_LIGHT

    # Face
    for x in range(10, 22):
        for y in range(10, 20):
            pixels[x, y] = SKIN_LIGHT

    # Eyes
    for x in [12, 18]:
        pixels[x, 14] = (255, 255, 255)  # white
        pixels[x+1, 14] = (0, 0, 0)      # pupil

    # Glasses (simple line)
    for x in range(11, 21):
        pixels[x, 13] = HAIR_DARK

    # Robe
    for x in range(8, 24):
        for y in range(20, 30):
            pixels[x, y] = ROBE_MID
    for x in range(10, 22):
        for y in range(22, 30):
            pixels[x, y] = ROBE_LIGHT

    # Trim (gold border at top of robe)
    for x in range(8, 24):
        pixels[x, 20] = TRIM_GOLD

    # Book (brown rectangle in hands)
    for x in range(12, 20):
        for y in range(22, 24):
            pixels[x, y] = BOOK_BROWN

    img.save("mentor_portrait_example.png")

if __name__ == "__main__":
    draw_mentor()
```

This code outlines a simple process: define a palette, create a blank pixel canvas, and set pixel values region by region. To build more detailed sprites, expand the coordinate ranges and introduce additional shades following the palette guidelines.

## 6. Tools and Workflow Tips

### Recommended Tools

- **Aseprite** - Industry standard for pixel art, excellent for this style
- **Pyxel Edit** - Good for larger canvases and tile work
- **Photoshop/GIMP** - With pencil tool (no anti-aliasing) and indexed color mode

### Workflow for High-Res Portraits

1. **Sketch silhouette** - Block in major shapes at 25-50% opacity
2. **Establish values** - Paint in grayscale first to nail the lighting
3. **Add local color** - Apply base hues to each material
4. **Refine shadows** - Add shadow color ramps with hue shifting
5. **Add highlights** - Bright spots, rim lights, catchlights
6. **Detail pass** - Hair strands, cloth texture, small features
7. **Polish** - Final color adjustments, cleanup stray pixels

### Export

- **PNG** - Primary format, supports transparency
- **128×128 or 256×256** - Standard portrait sizes
- Save at 1x scale (not upscaled) - let the game engine handle scaling with nearest-neighbor filtering

### Quality Checklist

- [ ] Background is solid dark navy
- [ ] Hair has 5+ distinct shades with visible strand clusters
- [ ] Eyes have bright catchlight reflections
- [ ] Glasses frames show thickness and light reflection
- [ ] Skin has warm undertones with subtle color variation
- [ ] Clothing shows fabric folds with gradient shading
- [ ] No pure black outlines (use dark versions of local colors)
- [ ] Overall reads clearly when scaled down to 64×64

Following these guidelines will help produce pixel-art assets that match the high-quality reference style in `HighRes.png`.
