# Art Asset Implementation Guide

## Overview

This guide provides detailed, step-by-step instructions for creating and updating art assets. Each section includes exact SVG code, color values, and file paths.

**Current Asset Count**: ~1499 SVGs
**Art Style**: Pixel art using only `<rect>` and `<ellipse>` elements
**Standard Sizes**: 16x16 (icons), 32x32 (units/buildings), 64x64 (large), 128x128 (bosses)

---

## Part 1: Art Style Reference

### 1.1 SVG Structure Template

Every SVG must follow this exact structure:

```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 WIDTH HEIGHT" width="WIDTH" height="HEIGHT">
  <!-- ASSET_NAME - Brief description -->

  <!-- Shadow (if ground-based) -->
  <ellipse cx="CENTER_X" cy="BOTTOM_Y" rx="SHADOW_RX" ry="SHADOW_RY" fill="#1a252f" opacity="0.4"/>

  <!-- Main elements from back to front -->
  <!-- ... -->
</svg>
```

### 1.2 Color Palette

#### Primary Colors (use these exact hex values)

| Name | Hex | Usage |
|------|-----|-------|
| **Enemy Red** | `#c0392b` | Base enemy color |
| **Enemy Red Light** | `#e74c3c` | Enemy highlights |
| **Enemy Red Dark** | `#922b21` | Enemy shadows |
| **Player Blue** | `#2980b9` | Player/friendly units |
| **Player Blue Light** | `#3498db` | Player highlights |
| **Gold** | `#f4d03f` | Coins, rewards, highlights |
| **Gold Dark** | `#b7950b` | Gold shadows |
| **Health Green** | `#27ae60` | Health, nature, good |
| **Health Green Light** | `#2ecc71` | Green highlights |
| **Danger Red** | `#e74c3c` | Damage, danger |
| **Magic Purple** | `#8e44ad` | Magic, arcane |
| **Magic Purple Light** | `#9b59b6` | Magic highlights |
| **Ice Blue** | `#3498db` | Ice, frost |
| **Ice Blue Light** | `#85c1e9` | Ice highlights |
| **Fire Orange** | `#e67e22` | Fire, burning |
| **Fire Orange Light** | `#f39c12` | Fire highlights |
| **Poison Green** | `#27ae60` | Poison, toxic |
| **Poison Green Dark** | `#1e8449` | Poison dark |

#### Neutral Colors

| Name | Hex | Usage |
|------|-----|-------|
| **Background Dark** | `#1a252f` | Shadows, outlines |
| **Wood Brown** | `#8b4513` | Wood, structures |
| **Wood Brown Light** | `#a0522d` | Wood highlights |
| **Wood Brown Dark** | `#5d4e37` | Wood shadows |
| **Stone Gray** | `#7f8c8d` | Stone, metal |
| **Stone Gray Light** | `#95a5a6` | Stone highlights |
| **Stone Gray Dark** | `#5d6d7e` | Stone shadows |
| **Skin Tone** | `#f5cba7` | Human skin |
| **Bone White** | `#c4b8a0` | Bones, old structures |

### 1.3 Shadow Standards

Every ground-based sprite needs a shadow ellipse at the bottom:

| Sprite Size | Shadow rx | Shadow ry | Shadow cy offset |
|-------------|-----------|-----------|------------------|
| 16x16 | 4 | 1 | 15 |
| 32x32 | 8 | 2 | 30 |
| 64x64 | 16 | 4 | 60 |
| 128x128 | 32 | 8 | 120 |

---

## Part 2: Asset Gap Analysis

### 2.1 What Exists (Sample)

The following categories are well-covered:
- Enemy walk animations (archer, assassin, berserker, champion, dragon, etc.)
- Boss animations (Fen Seer with idle/attack cycles)
- Ambient decorations (bushes, rocks, flowers, etc.)
- Icons (gold, accuracy, wpm, target, wave, threat, etc.)
- Affixes (armored, burning, frozen, shielded, swift, toxic, vampiric, etc.)
- Buildings (various towers)

### 2.2 Gaps to Fill

Based on code references, these assets are referenced but may need updates:

#### Missing Tower Upgrade Tiers
- [ ] `tower_arrow_t2.svg` - Arrow tower tier 2
- [ ] `tower_arrow_t3.svg` - Arrow tower tier 3
- [ ] `tower_fire_t2.svg` - Fire tower tier 2
- [ ] `tower_fire_t3.svg` - Fire tower tier 3
- [ ] `tower_ice_t2.svg` - Ice tower tier 2
- [ ] `tower_ice_t3.svg` - Ice tower tier 3

#### Missing Effect Sprites
- [ ] `effect_word_complete.svg` - Word completion burst
- [ ] `effect_word_error.svg` - Typing error indicator
- [ ] `effect_combo_spark.svg` - Combo spark effect
- [ ] `effect_critical.svg` - Critical hit indicator

#### Missing UI Elements
- [ ] `btn_primary.svg` - Primary button state
- [ ] `btn_primary_hover.svg` - Primary button hover
- [ ] `btn_primary_pressed.svg` - Primary button pressed
- [ ] `panel_tooltip.svg` - Tooltip background

---

## Part 3: Creating New Assets

### 3.1 Tower Upgrade Template

Here's how to create a tier 2 tower (use arrow tower as example):

**File**: `assets/art/src-svg/buildings/tower_arrow_t2.svg`

```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 32" width="24" height="32">
  <!-- Arrow Tower T2 (24x32) - upgraded archer tower with metal reinforcement -->

  <!-- Base/Foundation - larger and reinforced -->
  <rect x="3" y="28" width="18" height="4" fill="#5d6d7e"/>
  <rect x="4" y="29" width="16" height="2" fill="#7f8c8d"/>

  <!-- Tower body - stone reinforced -->
  <rect x="5" y="10" width="14" height="18" fill="#7f8c8d"/>
  <rect x="6" y="11" width="12" height="16" fill="#95a5a6"/>

  <!-- Metal bands -->
  <rect x="5" y="14" width="14" height="2" fill="#5d6d7e"/>
  <rect x="5" y="20" width="14" height="2" fill="#5d6d7e"/>

  <!-- Platform/roof - metal -->
  <rect x="2" y="6" width="20" height="4" fill="#5d6d7e"/>
  <rect x="3" y="7" width="18" height="2" fill="#7f8c8d"/>

  <!-- Battlements - taller -->
  <rect x="2" y="1" width="4" height="5" fill="#5d6d7e"/>
  <rect x="10" y="1" width="4" height="5" fill="#5d6d7e"/>
  <rect x="18" y="1" width="4" height="5" fill="#5d6d7e"/>

  <!-- Arrow slits - larger -->
  <rect x="9" y="13" width="6" height="8" fill="#1a252f"/>
  <rect x="10" y="14" width="4" height="6" fill="#0d0d0d"/>

  <!-- T2 indicator - gold trim -->
  <rect x="2" y="6" width="20" height="1" fill="#f4d03f"/>
  <rect x="2" y="1" width="1" height="5" fill="#f4d03f"/>
  <rect x="21" y="1" width="1" height="5" fill="#f4d03f"/>

  <!-- Highlight -->
  <rect x="3" y="7" width="1" height="1" fill="#b7950b"/>
</svg>
```

**Key differences from T1:**
- Stone/metal materials instead of wood
- Gold trim accents
- Taller battlements
- Larger arrow slits
- More substantial base

### 3.2 Tier 3 Tower Template

**File**: `assets/art/src-svg/buildings/tower_arrow_t3.svg`

```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 32" width="24" height="32">
  <!-- Arrow Tower T3 (24x32) - elite archer tower with magical enhancement -->

  <!-- Base/Foundation - crystalline -->
  <rect x="2" y="28" width="20" height="4" fill="#8e44ad"/>
  <rect x="3" y="29" width="18" height="2" fill="#9b59b6"/>

  <!-- Tower body - enchanted stone -->
  <rect x="4" y="8" width="16" height="20" fill="#7f8c8d"/>
  <rect x="5" y="9" width="14" height="18" fill="#95a5a6"/>

  <!-- Magic runes -->
  <rect x="6" y="12" width="2" height="2" fill="#9b59b6"/>
  <rect x="16" y="12" width="2" height="2" fill="#9b59b6"/>
  <rect x="6" y="18" width="2" height="2" fill="#9b59b6"/>
  <rect x="16" y="18" width="2" height="2" fill="#9b59b6"/>

  <!-- Platform - magical -->
  <rect x="1" y="4" width="22" height="4" fill="#8e44ad"/>
  <rect x="2" y="5" width="20" height="2" fill="#9b59b6"/>

  <!-- Battlements - crystal tipped -->
  <rect x="1" y="0" width="4" height="4" fill="#8e44ad"/>
  <rect x="2" y="0" width="2" height="2" fill="#e8daef"/>
  <rect x="10" y="0" width="4" height="4" fill="#8e44ad"/>
  <rect x="11" y="0" width="2" height="2" fill="#e8daef"/>
  <rect x="19" y="0" width="4" height="4" fill="#8e44ad"/>
  <rect x="20" y="0" width="2" height="2" fill="#e8daef"/>

  <!-- Arrow slit - glowing -->
  <rect x="9" y="11" width="6" height="10" fill="#1a252f"/>
  <rect x="10" y="12" width="4" height="8" fill="#9b59b6" opacity="0.5"/>
  <rect x="11" y="14" width="2" height="4" fill="#e8daef" opacity="0.7"/>

  <!-- T3 indicator - magical aura -->
  <rect x="0" y="4" width="24" height="1" fill="#e8daef" opacity="0.6"/>
  <rect x="0" y="0" width="1" height="8" fill="#e8daef" opacity="0.4"/>
  <rect x="23" y="0" width="1" height="8" fill="#e8daef" opacity="0.4"/>
</svg>
```

**Key differences from T2:**
- Purple/magical color scheme
- Crystal accents on battlements
- Glowing runes on walls
- Magical aura effects
- Larger overall presence

### 3.3 Effect Sprite Template

**File**: `assets/art/src-svg/effects/effect_word_complete.svg`

```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32" width="32" height="32">
  <!-- Word Complete Effect - burst of golden particles -->

  <!-- Center glow -->
  <rect x="14" y="14" width="4" height="4" fill="#f4d03f"/>
  <rect x="12" y="12" width="8" height="8" fill="#f4d03f" opacity="0.5"/>

  <!-- Radial sparks - 8 directions -->
  <!-- Up -->
  <rect x="15" y="4" width="2" height="6" fill="#f4d03f"/>
  <rect x="15" y="2" width="2" height="2" fill="#f9e79f"/>

  <!-- Up-Right -->
  <rect x="22" y="6" width="4" height="2" fill="#f4d03f"/>
  <rect x="20" y="8" width="2" height="2" fill="#f4d03f"/>

  <!-- Right -->
  <rect x="22" y="15" width="6" height="2" fill="#f4d03f"/>
  <rect x="28" y="15" width="2" height="2" fill="#f9e79f"/>

  <!-- Down-Right -->
  <rect x="22" y="24" width="4" height="2" fill="#f4d03f"/>
  <rect x="20" y="22" width="2" height="2" fill="#f4d03f"/>

  <!-- Down -->
  <rect x="15" y="22" width="2" height="6" fill="#f4d03f"/>
  <rect x="15" y="28" width="2" height="2" fill="#f9e79f"/>

  <!-- Down-Left -->
  <rect x="6" y="24" width="4" height="2" fill="#f4d03f"/>
  <rect x="10" y="22" width="2" height="2" fill="#f4d03f"/>

  <!-- Left -->
  <rect x="4" y="15" width="6" height="2" fill="#f4d03f"/>
  <rect x="2" y="15" width="2" height="2" fill="#f9e79f"/>

  <!-- Up-Left -->
  <rect x="6" y="6" width="4" height="2" fill="#f4d03f"/>
  <rect x="10" y="8" width="2" height="2" fill="#f4d03f"/>
</svg>
```

### 3.4 Icon Template (16x16)

**File**: `assets/art/src-svg/icons/ico_combo.svg`

```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="16" height="16">
  <!-- Combo Icon - stacked multiplier symbol -->

  <!-- Background circle -->
  <rect x="2" y="2" width="12" height="12" fill="#e74c3c"/>
  <rect x="1" y="4" width="14" height="8" fill="#e74c3c"/>
  <rect x="4" y="1" width="8" height="14" fill="#e74c3c"/>

  <!-- Inner lighter area -->
  <rect x="3" y="3" width="10" height="10" fill="#c0392b"/>
  <rect x="2" y="5" width="12" height="6" fill="#c0392b"/>
  <rect x="5" y="2" width="6" height="12" fill="#c0392b"/>

  <!-- X symbol for multiplier -->
  <rect x="5" y="5" width="2" height="2" fill="#f4d03f"/>
  <rect x="9" y="5" width="2" height="2" fill="#f4d03f"/>
  <rect x="7" y="7" width="2" height="2" fill="#f4d03f"/>
  <rect x="5" y="9" width="2" height="2" fill="#f4d03f"/>
  <rect x="9" y="9" width="2" height="2" fill="#f4d03f"/>

  <!-- Highlight -->
  <rect x="3" y="3" width="2" height="2" fill="#e74c3c"/>
</svg>
```

---

## Part 4: Animation Frame Guidelines

### 4.1 Walk Cycle Structure

Every enemy walk animation needs 4 frames:

| Frame | Leg Position | Arm Position | Body Offset |
|-------|--------------|--------------|-------------|
| 01 | Left forward | Right forward | Y+0 |
| 02 | Passing | Passing | Y+1 (slight bob) |
| 03 | Right forward | Left forward | Y+0 |
| 04 | Passing | Passing | Y+1 (slight bob) |

### 4.2 Walk Frame Template

**Frame 1**: `enemy_TYPE_walk_01.svg`
```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32" width="32" height="32">
  <!-- Enemy TYPE Walk Frame 1: Left foot forward -->

  <!-- Shadow -->
  <ellipse cx="16" cy="30" rx="8" ry="2" fill="#1a252f" opacity="0.4"/>

  <!-- Left leg (forward) - extended ahead -->
  <rect x="9" y="22" width="5" height="8" fill="BODY_COLOR"/>
  <rect x="7" y="28" width="6" height="3" fill="FOOT_COLOR"/>

  <!-- Right leg (back) - extended behind -->
  <rect x="18" y="23" width="5" height="7" fill="BODY_COLOR"/>
  <rect x="19" y="28" width="6" height="3" fill="FOOT_COLOR"/>

  <!-- Body (no vertical offset) -->
  <rect x="8" y="12" width="16" height="12" fill="BODY_COLOR"/>
  <!-- ... rest of body details ... -->
</svg>
```

**Frame 2**: `enemy_TYPE_walk_02.svg`
```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32" width="32" height="32">
  <!-- Enemy TYPE Walk Frame 2: Legs passing, slight bob -->

  <!-- Shadow (slightly smaller - higher position) -->
  <ellipse cx="16" cy="30" rx="7" ry="2" fill="#1a252f" opacity="0.35"/>

  <!-- Left leg (passing) - under body -->
  <rect x="11" y="23" width="5" height="7" fill="BODY_COLOR"/>
  <rect x="10" y="28" width="6" height="3" fill="FOOT_COLOR"/>

  <!-- Right leg (passing) - under body -->
  <rect x="16" y="23" width="5" height="7" fill="BODY_COLOR"/>
  <rect x="16" y="28" width="6" height="3" fill="FOOT_COLOR"/>

  <!-- Body (Y offset +1 for bob) -->
  <rect x="8" y="11" width="16" height="12" fill="BODY_COLOR"/>
  <!-- ... rest of body details with Y-1 ... -->
</svg>
```

### 4.3 Idle Animation Structure

Idle animations need 2-4 frames for subtle movement:

| Frame | Effect | Duration |
|-------|--------|----------|
| 01 | Neutral | 0.5s |
| 02 | Slight lean/bob | 0.5s |
| 03 | Return to neutral | 0.5s |
| 04 | Slight opposite lean (optional) | 0.5s |

---

## Part 5: Asset Manifest Updates

After creating each new asset, update `data/assets_manifest.json`:

### 5.1 Adding a New Texture Entry

```json
{
  "id": "tower_arrow_t2",
  "path": "res://assets/sprites/buildings/tower_arrow_t2.png",
  "source_svg": "res://assets/art/src-svg/buildings/tower_arrow_t2.svg",
  "expected_width": 24,
  "expected_height": 32,
  "max_kb": 8,
  "pixel_art": true,
  "category": "buildings"
}
```

### 5.2 Adding Animation Entries

```json
{
  "id": "enemy_knight_walk",
  "frames": [
    "res://assets/sprites/animations/enemy_knight_walk_01.png",
    "res://assets/sprites/animations/enemy_knight_walk_02.png",
    "res://assets/sprites/animations/enemy_knight_walk_03.png",
    "res://assets/sprites/animations/enemy_knight_walk_04.png"
  ],
  "frame_duration": 0.15,
  "loop": true,
  "category": "animations"
}
```

---

## Part 6: Step-by-Step Asset Creation Checklist

### Creating a New Enemy Type

1. **Create walk animation frames** (4 frames):
   ```
   assets/art/src-svg/animations/enemy_TYPENAME_walk_01.svg
   assets/art/src-svg/animations/enemy_TYPENAME_walk_02.svg
   assets/art/src-svg/animations/enemy_TYPENAME_walk_03.svg
   assets/art/src-svg/animations/enemy_TYPENAME_walk_04.svg
   ```

2. **Create idle animation frames** (2 frames minimum):
   ```
   assets/art/src-svg/animations/enemy_TYPENAME_idle_01.svg
   assets/art/src-svg/animations/enemy_TYPENAME_idle_02.svg
   ```

3. **Convert to PNG**:
   ```bash
   ./scripts/convert_assets.sh --id enemy_TYPENAME
   ```

4. **Update assets_manifest.json** with entries for each animation

5. **Add to sim/enemies.gd** if new enemy type

6. **Test in game**:
   ```bash
   godot --headless --path . --script res://tests/run_tests.gd
   ```

### Creating a Tower Upgrade

1. **Copy base tower SVG**:
   ```bash
   cp assets/art/src-svg/buildings/tower_TYPE.svg assets/art/src-svg/buildings/tower_TYPE_t2.svg
   ```

2. **Edit for tier upgrades**:
   - T2: Metal reinforcement, gold trim
   - T3: Magical effects, crystal accents

3. **Update color scheme per tier**:
   - T1: Wood/basic materials
   - T2: Stone/metal, gold accents
   - T3: Purple magic, crystal, glow effects

4. **Update assets_manifest.json**

5. **Update sim/buildings.gd** or tower data

### Creating an Effect Sprite

1. **Determine effect type**:
   - Instant burst: Radial sparks from center
   - Continuous: Looping particles
   - Directional: Trail or beam

2. **Create SVG in effects folder**:
   ```
   assets/art/src-svg/effects/effect_NAME.svg
   ```

3. **Use appropriate colors**:
   - Damage: Red/orange
   - Healing: Green
   - Magic: Purple
   - Ice: Blue
   - Fire: Orange/yellow
   - Gold/rewards: Yellow

4. **Update assets_manifest.json**

5. **Wire up in game/hit_effects.gd or appropriate renderer**

---

## Part 7: Quality Checklist

### Per-Asset Verification

- [ ] Uses only `<rect>` and `<ellipse>` elements
- [ ] Colors match palette (exact hex values)
- [ ] Dimensions match category standard
- [ ] Has shadow ellipse if ground-based
- [ ] viewBox matches width/height
- [ ] Includes descriptive comment at top
- [ ] No anti-aliasing or gradients
- [ ] Properly layered (back to front)

### Animation Verification

- [ ] All frames same dimensions
- [ ] Consistent shadow across frames
- [ ] Smooth motion between frames
- [ ] Character stays centered
- [ ] No elements "pop" between frames

### Integration Verification

- [ ] Added to assets_manifest.json
- [ ] PNG exported successfully
- [ ] Referenced in game code
- [ ] Tests pass
- [ ] Displays correctly in game

---

## Part 8: Common Fixes

### Asset Looks Blurry
- Ensure `pixel_art: true` in manifest
- Check Godot import settings for nearest-neighbor filtering

### Animation Stutters
- Verify all frames have same dimensions
- Check frame_duration value (0.15 is standard)

### Colors Don't Match
- Use exact hex values from palette
- Don't use color names, use hex codes

### Shadow Looks Wrong
- Use standard shadow formula from Part 1.3
- Ensure shadow is first element (behind everything)

---

## Appendix A: Complete Tower Tier Specifications

### Arrow Tower Series

| Tier | Materials | Accent Color | Special Feature |
|------|-----------|--------------|-----------------|
| T1 | Wood | None | Basic wooden slats |
| T2 | Stone/Metal | Gold trim | Metal bands |
| T3 | Enchanted Stone | Purple glow | Crystal battlements |

### Fire Tower Series

| Tier | Materials | Accent Color | Special Feature |
|------|-----------|--------------|-----------------|
| T1 | Stone/Brick | Orange glow | Simple brazier |
| T2 | Dark Stone | Bright fire | Multiple flame sources |
| T3 | Obsidian | Blue-white fire | Magical fire runes |

### Ice Tower Series

| Tier | Materials | Accent Color | Special Feature |
|------|-----------|--------------|-----------------|
| T1 | Snow-covered | Light blue | Frost details |
| T2 | Ice blocks | Cyan glow | Icicle accents |
| T3 | Crystal | White glow | Full crystal structure |

---

## Appendix B: Enemy Color Schemes

| Enemy Type | Primary | Secondary | Accent |
|------------|---------|-----------|--------|
| Scout | `#c0392b` | `#e74c3c` | `#f4d03f` |
| Brute | `#6e2c00` | `#8b4513` | `#c0392b` |
| Runner | `#1e8449` | `#27ae60` | `#f4d03f` |
| Tank | `#5d6d7e` | `#7f8c8d` | `#c0392b` |
| Archer | `#1e8449` | `#27ae60` | `#6e2c00` |
| Mage | `#8e44ad` | `#9b59b6` | `#e8daef` |
| Knight | `#5d6d7e` | `#95a5a6` | `#f4d03f` |
| Assassin | `#1a252f` | `#2c3e50` | `#c0392b` |

---

## Appendix C: File Naming Convention

```
CATEGORY_NAME_VARIANT_FRAME.svg

Examples:
- enemy_scout_walk_01.svg
- tower_arrow_t2.svg
- effect_fire_burst.svg
- icon_gold.svg
- boss_dragon_attack_03.svg
```

Categories: `enemy`, `tower`, `building`, `effect`, `icon`, `boss`, `ui`, `ambient`

Variants: `walk`, `idle`, `attack`, `death`, `t1`, `t2`, `t3`, `hover`, `pressed`

Frames: `01`, `02`, `03`, `04` (two-digit, zero-padded)
