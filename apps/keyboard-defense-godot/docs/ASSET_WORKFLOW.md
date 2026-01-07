# Asset Creation Workflow & Pipeline Guide

## Overview

This document describes the complete workflow for creating, validating, and integrating assets into Keyboard Defense.

---

## DIRECTORY STRUCTURE

```
apps/keyboard-defense-godot/
├── assets/
│   ├── art/
│   │   └── src-svg/           # Source SVG files
│   │       ├── icons/
│   │       ├── sprites/
│   │       ├── tiles/
│   │       ├── ui/
│   │       ├── effects/
│   │       └── characters/
│   ├── sprites/               # Exported PNG files
│   ├── audio/
│   │   ├── music/
│   │   ├── sfx/
│   │   └── voice/
│   └── fonts/
├── data/
│   ├── assets_manifest.json   # Asset registry
│   └── schemas/
│       └── assets_manifest.schema.json
└── docs/
    └── ASSET_SPEC_*.md        # Specification documents
```

---

## ASSET CREATION WORKFLOW

### Step 1: Consult Specification

Before creating any asset:
1. Open relevant `ASSET_SPEC_*.md` document
2. Find exact specifications for asset
3. Note dimensions, colors, frame counts
4. Check naming convention

---

### Step 2: Create SVG Source

#### SVG Template Structure
```xml
<svg xmlns="http://www.w3.org/2000/svg"
     viewBox="0 0 [WIDTH] [HEIGHT]"
     width="[WIDTH]"
     height="[HEIGHT]">

  <!-- Asset Name: [category]_[type]_[variant] -->
  <!-- Dimensions: [WIDTH]x[HEIGHT] -->
  <!-- Frames: [N] (if animated) -->

  <!-- Frame 1 -->
  <rect x="0" y="0" width="..." height="..." fill="#..."/>
  <!-- ... more rects ... -->

  <!-- Frame 2 (if animated) -->
  <rect x="[frame_width]" y="0" width="..." height="..." fill="#..."/>
  <!-- ... more rects ... -->

</svg>
```

#### SVG Rules
- Use ONLY `<rect>` elements (no paths, circles, etc.)
- Integer coordinates only (no decimals)
- Colors as hex codes (#RRGGBB)
- No transforms, gradients, or filters
- Comments for documentation

---

### Step 3: Validate Asset

#### Dimension Check
```
Single frame:      width × height match spec
Multi-frame:       width = frame_width × frame_count
                   height = frame_height
```

#### Color Check
- Only approved palette colors
- Check against ASSET_SPEC_INDEX.md color palette

#### Visual Check
- Open SVG in browser at 100% and 400% zoom
- Verify readability at game scale
- Check animation flow (if applicable)

---

### Step 4: Export to PNG

#### Manual Export (Inkscape)
```bash
inkscape input.svg --export-type=png --export-filename=output.png
```

#### Batch Export Script
```bash
# scripts/export_sprites.sh
for svg in assets/art/src-svg/**/*.svg; do
  png="${svg/src-svg/..\/sprites}"
  png="${png/.svg/.png}"
  inkscape "$svg" --export-type=png --export-filename="$png"
done
```

---

### Step 5: Register in Manifest

#### Add Entry to assets_manifest.json
```json
{
  "id": "enemy_necromancer_idle",
  "path": "res://assets/sprites/enemies/enemy_necromancer_idle.png",
  "source_svg": "res://assets/art/src-svg/enemies/enemy_necromancer_idle.svg",
  "expected_width": 64,
  "expected_height": 24,
  "max_kb": 2,
  "pixel_art": true,
  "category": "enemies",
  "frames": 4,
  "frame_width": 16,
  "frame_height": 24,
  "duration_ms": 600
}
```

#### Manifest Fields
| Field | Required | Type | Description |
|-------|----------|------|-------------|
| id | Yes | string | Unique identifier |
| path | Yes | string | Export PNG path |
| source_svg | Yes | string | Source SVG path |
| expected_width | Yes | int | Total width in pixels |
| expected_height | Yes | int | Total height in pixels |
| max_kb | No | int | Max file size |
| pixel_art | Yes | bool | Always true for SVG assets |
| category | Yes | string | Asset category |
| frames | No | int | Frame count (animations) |
| frame_width | No | int | Single frame width |
| frame_height | No | int | Single frame height |
| duration_ms | No | int | Animation duration |
| margin_left | No | int | 9-slice left margin |
| margin_right | No | int | 9-slice right margin |
| margin_top | No | int | 9-slice top margin |
| margin_bottom | No | int | 9-slice bottom margin |
| tileable | No | bool | Pattern repeats |

---

### Step 6: Validate Manifest

#### Run Validation Script
```bash
node scripts/validate_manifest.js
```

#### Validation Checks
- All referenced files exist
- Dimensions match spec
- No duplicate IDs
- Required fields present
- File sizes within limits

---

### Step 7: Test In-Engine

1. Open Godot project
2. Import new assets
3. Create test scene or use existing
4. Verify visual appearance
5. Test animations at actual speed
6. Check performance impact

---

### Step 8: Commit

```bash
# Stage source and export
git add assets/art/src-svg/category/new_asset.svg
git add assets/sprites/category/new_asset.png
git add data/assets_manifest.json

# Commit with descriptive message
git commit -m "Add [asset_name]: [description]"
```

---

## ANIMATION WORKFLOW

### Creating Sprite Sheets

1. **Plan frames**: Sketch keyframes
2. **Create first frame**: Complete, polished
3. **Duplicate and modify**: Each subsequent frame
4. **Horizontal arrangement**: All frames in row
5. **Test timing**: View as animation

### Frame Layout Example
```
┌────────┬────────┬────────┬────────┐
│ Frame 1│ Frame 2│ Frame 3│ Frame 4│
│  16x24 │  16x24 │  16x24 │  16x24 │
└────────┴────────┴────────┴────────┘
Total: 64x24 (4 frames of 16x24)
```

### Testing Animations

#### Browser Test
Create HTML test file:
```html
<!DOCTYPE html>
<html>
<head>
  <style>
    .sprite {
      width: 16px;
      height: 24px;
      background: url('sprite_sheet.png');
      animation: play 0.6s steps(4) infinite;
    }
    @keyframes play {
      from { background-position: 0 0; }
      to { background-position: -64px 0; }
    }
  </style>
</head>
<body>
  <div class="sprite"></div>
</body>
</html>
```

---

## 9-SLICE WORKFLOW

### Creating 9-Slice Assets

1. Design at minimum size
2. Identify stretchable areas
3. Mark corners (fixed size)
4. Document margins in manifest

### 9-Slice Structure
```
┌─────┬───────────┬─────┐
│ TL  │    Top    │ TR  │  Fixed corners
├─────┼───────────┼─────┤
│Left │  Center   │Right│  Stretchable middle
├─────┼───────────┼─────┤
│ BL  │  Bottom   │ BR  │  Fixed corners
└─────┴───────────┴─────┘
```

### Manifest Entry for 9-Slice
```json
{
  "id": "panel_dialog",
  "path": "res://assets/sprites/ui/panel_dialog.png",
  "source_svg": "res://assets/art/src-svg/ui/panel_dialog.svg",
  "expected_width": 48,
  "expected_height": 48,
  "category": "ui",
  "margin_left": 12,
  "margin_right": 12,
  "margin_top": 12,
  "margin_bottom": 12
}
```

---

## TILEABLE PATTERN WORKFLOW

### Creating Tileable Patterns

1. Design base tile
2. Test seamless edges
3. Verify pattern at 2x2 minimum
4. Mark as tileable in manifest

### Edge Matching
```
Ensure:
- Left edge matches right edge
- Top edge matches bottom edge
- Corners align when tiled
```

### Testing Tileability
```html
<style>
  .tiled {
    width: 256px;
    height: 256px;
    background: url('tile.png');
    background-repeat: repeat;
  }
</style>
```

---

## BATCH PROCESSING

### Export All SVGs
```bash
#!/bin/bash
# scripts/export_all.sh

find assets/art/src-svg -name "*.svg" | while read svg; do
  relative="${svg#assets/art/src-svg/}"
  png="assets/sprites/${relative%.svg}.png"
  mkdir -p "$(dirname "$png")"
  inkscape "$svg" --export-type=png --export-filename="$png"
  echo "Exported: $png"
done
```

### Validate All Assets
```bash
#!/bin/bash
# scripts/validate_all.sh

# Check SVG structure
echo "Checking SVG structure..."
for svg in assets/art/src-svg/**/*.svg; do
  # Verify only rect elements
  if grep -q "<path\|<circle\|<ellipse" "$svg"; then
    echo "WARNING: Non-rect elements in $svg"
  fi
done

# Check manifest
echo "Validating manifest..."
node scripts/validate_manifest.js

# Check file sizes
echo "Checking file sizes..."
for png in assets/sprites/**/*.png; do
  size=$(stat -f%z "$png" 2>/dev/null || stat -c%s "$png")
  if [ "$size" -gt 10240 ]; then
    echo "WARNING: Large file ($size bytes): $png"
  fi
done
```

---

## QUALITY CONTROL

### Pre-Commit Checklist
- [ ] SVG uses only rect elements
- [ ] Colors from approved palette
- [ ] Dimensions match specification
- [ ] Animation frames align correctly
- [ ] Manifest entry complete
- [ ] PNG exported and current
- [ ] Tested in Godot

### Code Review Focus
- Correct category/naming
- Specification compliance
- Visual consistency
- Performance impact

---

## COMMON ISSUES & FIXES

### Issue: Blurry Export
**Cause**: Anti-aliasing or fractional coordinates
**Fix**: Use integer coordinates, disable AA in export

### Issue: Wrong Colors
**Cause**: Color profile conversion
**Fix**: Use sRGB, export without color management

### Issue: Animation Jitter
**Cause**: Inconsistent frame positioning
**Fix**: Align all frames to same grid

### Issue: Large File Size
**Cause**: Too many colors or complex patterns
**Fix**: Reduce colors, simplify shapes

### Issue: Import Errors in Godot
**Cause**: Path mismatch or missing files
**Fix**: Verify paths in manifest match actual files

---

## OPTIMIZATION GUIDELINES

### File Size Targets
| Type | Max Size |
|------|----------|
| Icon (16x16) | 1 KB |
| Sprite (16x24) | 2 KB |
| Sprite Sheet (64x24) | 4 KB |
| Large Sprite (32x40) | 4 KB |
| UI Panel (48x48) | 3 KB |
| Tile (16x16) | 1 KB |

### Optimization Techniques
1. Reduce color count
2. Simplify shapes
3. Combine similar colors
4. Use indexed color PNG
5. Remove metadata

---

## COLLABORATION

### Asset Assignment
```
Format: [Category] [Asset Name] - [Assignee] - [Status]

Examples:
[Enemies] Necromancer Idle - @artist1 - In Progress
[UI] Button Primary - @artist2 - Review
[Effects] Fire Impact - @artist1 - Complete
```

### Review Process
1. Create PR with new assets
2. Include before/after screenshots
3. Reference specification
4. Run validation scripts
5. Test in Godot
6. Approve and merge

### Feedback Format
```
Asset: [asset_id]
Issue: [description]
Spec Reference: [ASSET_SPEC_*.md section]
Suggested Fix: [how to resolve]
```

---

## TOOLS REFERENCE

### Required Tools
- Text editor (VSCode, etc.)
- Inkscape (export)
- Web browser (preview)
- Godot 4.x (integration)

### Recommended Tools
- Color picker with palette
- Pixel art preview extension
- Animation preview tool
- Git GUI client

### Validation Scripts
```
scripts/
├── export_all.sh          # Batch SVG to PNG
├── validate_manifest.js   # Check manifest
├── validate_svgs.sh       # Check SVG structure
├── check_colors.js        # Verify color palette
└── size_report.sh         # File size report
```

---

## QUICK REFERENCE

### New Asset Checklist
1. [ ] Read spec document
2. [ ] Create SVG with rects only
3. [ ] Use approved colors
4. [ ] Match dimensions exactly
5. [ ] Export to PNG
6. [ ] Add to manifest
7. [ ] Run validation
8. [ ] Test in Godot
9. [ ] Commit with message

### File Naming
```
[category]_[type]_[variant]_[state].svg

category:   icons, sprites, tiles, ui, effects, enemies, towers
type:       specific asset type (arrow, health, grass)
variant:    optional variation (t2, small, blue)
state:      optional state (idle, hover, pressed)
```

### Color Codes (Most Common)
```
#1a252f - Dark Navy (background)
#2c3e50 - Navy (panels)
#5d6d7e - Steel Gray (borders)
#fdfefe - White (text)
#27ae60 - Green (success)
#e74c3c - Red (danger)
#3498db - Blue (info)
#f4d03f - Gold (rewards)
#9b59b6 - Purple (magic)
```

