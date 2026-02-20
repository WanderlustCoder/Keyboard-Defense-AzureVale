# Phase 7: Art Assets - Granular Implementation Guide

## Overview

This document covers creating and integrating new art assets for polish. The project uses SVG pixel art (rect/ellipse only) that can be converted to PNG for use in Godot.

---

## Art Style Reference

### Canvas Sizes
| Asset Type | Canvas Size | Notes |
|------------|-------------|-------|
| Tower/Building | 24x32 | Vertical, base at bottom |
| Enemy (regular) | 16x16 | Small, can scale up |
| Enemy (boss) | 32x32 | Larger, more detail |
| Effect/Projectile | 8x8 to 16x16 | Small, simple |
| Icon | 16x16 | UI icons |
| Character portrait | 48x48 | NPC faces |

### Color Palette
```
Primary Colors:
  Gold/Reward:      #ffd700
  Health Full:      #32cd32
  Health Low:       #ff4500
  Mana/Magic:       #6a5acd
  Enemy:            #dc143c

UI Colors:
  Panel Background: #1a1a2e
  Panel Border:     #2d2d44
  Text Primary:     #f0f0f5
  Text Secondary:   #a0a0b0

Tower Colors:
  Arrow Tower:      #5d4e37 (wood base)
  Magic Tower:      #3a3a5c (stone base)
  Fire Tower:       #8b4513 (brick)
  Ice Tower:        #4682b4 (blue stone)

Enemy Colors:
  Runner:           #8b0000 (dark red)
  Tank:             #4a4a4a (gray)
  Fast:             #228b22 (green)
  Boss:             #4b0082 (indigo)

Material Colors:
  Wood:             #8b7355, #6b5344, #5d4e37
  Stone:            #708090, #5a6a7a, #4a5a6a
  Metal:            #c0c0c0, #a0a0a0, #808080
  Crystal:          #87ceeb, #6bb3d9, #4a9cc9
```

---

## Task 7.1: Create Missing Effect SVGs

**Time**: 30 minutes
**Files to create**: Multiple SVG files in `assets/art/src-svg/effects/`

### Effect: Projectile Trail Particle

**File**: `assets/art/src-svg/effects/fx_trail_particle.svg`

```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 4 4" width="4" height="4">
  <!-- Trail particle (4x4) - small glow dot -->
  <ellipse cx="2" cy="2" rx="1.5" ry="1.5" fill="#ffeedd"/>
  <ellipse cx="2" cy="2" rx="1" ry="1" fill="#ffffff"/>
</svg>
```

### Effect: Hit Spark

**File**: `assets/art/src-svg/effects/fx_hit_spark.svg`

```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 8 8" width="8" height="8">
  <!-- Hit spark (8x8) - star burst -->
  <!-- Center -->
  <rect x="3" y="3" width="2" height="2" fill="#ffffff"/>
  <!-- Arms -->
  <rect x="3" y="0" width="2" height="2" fill="#ffffaa"/>
  <rect x="3" y="6" width="2" height="2" fill="#ffffaa"/>
  <rect x="0" y="3" width="2" height="2" fill="#ffffaa"/>
  <rect x="6" y="3" width="2" height="2" fill="#ffffaa"/>
</svg>
```

### Effect: Critical Hit Flash

**File**: `assets/art/src-svg/effects/fx_critical_flash.svg`

```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="16" height="16">
  <!-- Critical hit flash (16x16) - expanding ring -->
  <!-- Outer ring -->
  <rect x="6" y="0" width="4" height="2" fill="#ff6600"/>
  <rect x="6" y="14" width="4" height="2" fill="#ff6600"/>
  <rect x="0" y="6" width="2" height="4" fill="#ff6600"/>
  <rect x="14" y="6" width="2" height="4" fill="#ff6600"/>
  <!-- Corner accents -->
  <rect x="2" y="2" width="2" height="2" fill="#ff9933"/>
  <rect x="12" y="2" width="2" height="2" fill="#ff9933"/>
  <rect x="2" y="12" width="2" height="2" fill="#ff9933"/>
  <rect x="12" y="12" width="2" height="2" fill="#ff9933"/>
  <!-- Center bright -->
  <rect x="6" y="6" width="4" height="4" fill="#ffffff"/>
</svg>
```

### Effect: Word Complete Burst

**File**: `assets/art/src-svg/effects/fx_word_complete.svg`

```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="16" height="16">
  <!-- Word complete burst (16x16) - celebratory sparkle -->
  <!-- Center star -->
  <rect x="7" y="4" width="2" height="8" fill="#ffd700"/>
  <rect x="4" y="7" width="8" height="2" fill="#ffd700"/>
  <!-- Diagonal sparkles -->
  <rect x="3" y="3" width="2" height="2" fill="#ffee88"/>
  <rect x="11" y="3" width="2" height="2" fill="#ffee88"/>
  <rect x="3" y="11" width="2" height="2" fill="#ffee88"/>
  <rect x="11" y="11" width="2" height="2" fill="#ffee88"/>
  <!-- Small dots -->
  <rect x="7" y="1" width="2" height="1" fill="#ffffff"/>
  <rect x="7" y="14" width="2" height="1" fill="#ffffff"/>
  <rect x="1" y="7" width="1" height="2" fill="#ffffff"/>
  <rect x="14" y="7" width="1" height="2" fill="#ffffff"/>
</svg>
```

### Verification:
1. SVGs render correctly in browser
2. Pixel art style is maintained (rect/ellipse only)
3. Colors match palette

---

## Task 7.2: Create Status Effect Icons

**Time**: 25 minutes
**Files to create**: Multiple SVG files in `assets/art/src-svg/effects/`

### Status: Burn

**File**: `assets/art/src-svg/effects/status_burn.svg`

```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 8 8" width="8" height="8">
  <!-- Burn status (8x8) - flame icon -->
  <!-- Flame base -->
  <rect x="2" y="5" width="4" height="3" fill="#ff4400"/>
  <!-- Flame middle -->
  <rect x="3" y="3" width="2" height="3" fill="#ff6600"/>
  <!-- Flame tip -->
  <rect x="3" y="1" width="2" height="2" fill="#ffaa00"/>
  <!-- Inner highlight -->
  <rect x="3" y="4" width="2" height="2" fill="#ffcc00"/>
</svg>
```

### Status: Slow

**File**: `assets/art/src-svg/effects/status_slow.svg`

```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 8 8" width="8" height="8">
  <!-- Slow status (8x8) - ice crystal -->
  <!-- Vertical bar -->
  <rect x="3" y="0" width="2" height="8" fill="#66ccff"/>
  <!-- Horizontal bar -->
  <rect x="0" y="3" width="8" height="2" fill="#66ccff"/>
  <!-- Center bright -->
  <rect x="3" y="3" width="2" height="2" fill="#ffffff"/>
</svg>
```

### Status: Poison

**File**: `assets/art/src-svg/effects/status_poison.svg`

```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 8 8" width="8" height="8">
  <!-- Poison status (8x8) - droplet -->
  <!-- Droplet body -->
  <rect x="2" y="3" width="4" height="4" fill="#44cc44"/>
  <rect x="3" y="2" width="2" height="2" fill="#44cc44"/>
  <!-- Droplet tip -->
  <rect x="3" y="0" width="2" height="2" fill="#66ee66"/>
  <!-- Highlight -->
  <rect x="2" y="3" width="1" height="2" fill="#88ff88"/>
</svg>
```

### Status: Shield

**File**: `assets/art/src-svg/effects/status_shield.svg`

```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 8 8" width="8" height="8">
  <!-- Shield status (8x8) - shield shape -->
  <!-- Shield body -->
  <rect x="1" y="0" width="6" height="5" fill="#ffd700"/>
  <rect x="2" y="5" width="4" height="2" fill="#ffd700"/>
  <rect x="3" y="7" width="2" height="1" fill="#ffd700"/>
  <!-- Inner dark -->
  <rect x="2" y="1" width="4" height="3" fill="#ccaa00"/>
  <!-- Highlight -->
  <rect x="2" y="1" width="1" height="2" fill="#ffee88"/>
</svg>
```

### Verification:
1. Icons are recognizable at 8x8
2. Colors are distinct per status type
3. Work well when scaled up

---

## Task 7.3: Create New Enemy Sprites

**Time**: 40 minutes
**Files to create**: Multiple SVG files in `assets/art/src-svg/enemies/`

### Enemy: Specter (Fast Ghost Type)

**File**: `assets/art/src-svg/enemies/enemy_specter.svg`

```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="16" height="16">
  <!-- Specter enemy (16x16) - ghostly fast enemy -->
  <!-- Body glow -->
  <rect x="3" y="4" width="10" height="8" fill="#6666aa" opacity="0.5"/>
  <!-- Main body -->
  <rect x="4" y="5" width="8" height="7" fill="#8888cc"/>
  <!-- Wavy bottom -->
  <rect x="4" y="12" width="2" height="2" fill="#8888cc"/>
  <rect x="7" y="13" width="2" height="1" fill="#8888cc"/>
  <rect x="10" y="12" width="2" height="2" fill="#8888cc"/>
  <!-- Eyes (glowing) -->
  <rect x="5" y="7" width="2" height="2" fill="#ff0000"/>
  <rect x="9" y="7" width="2" height="2" fill="#ff0000"/>
  <!-- Eye glow -->
  <rect x="6" y="8" width="1" height="1" fill="#ffffff"/>
  <rect x="10" y="8" width="1" height="1" fill="#ffffff"/>
</svg>
```

### Enemy: Brute (Heavy Tank Type)

**File**: `assets/art/src-svg/enemies/enemy_brute.svg`

```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="16" height="16">
  <!-- Brute enemy (16x16) - armored tank enemy -->
  <!-- Body -->
  <rect x="2" y="6" width="12" height="9" fill="#555566"/>
  <!-- Armor plates -->
  <rect x="3" y="7" width="4" height="3" fill="#666677"/>
  <rect x="9" y="7" width="4" height="3" fill="#666677"/>
  <!-- Helmet -->
  <rect x="4" y="2" width="8" height="5" fill="#444455"/>
  <rect x="5" y="1" width="6" height="2" fill="#555566"/>
  <!-- Face slit -->
  <rect x="5" y="4" width="6" height="2" fill="#220000"/>
  <!-- Eyes in slit -->
  <rect x="6" y="4" width="1" height="1" fill="#ff3333"/>
  <rect x="9" y="4" width="1" height="1" fill="#ff3333"/>
  <!-- Feet -->
  <rect x="3" y="14" width="3" height="2" fill="#333344"/>
  <rect x="10" y="14" width="3" height="2" fill="#333344"/>
</svg>
```

### Verification:
1. Enemies are visually distinct
2. Specter looks ghostly/fast
3. Brute looks heavy/armored
4. Both readable at small sizes

---

## Task 7.4: Create New Tower Sprites

**Time**: 35 minutes
**Files to create**: Multiple SVG files in `assets/art/src-svg/buildings/`

### Tower: Arcane Tower (Magic)

**File**: `assets/art/src-svg/buildings/tower_arcane.svg`

```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 32" width="24" height="32">
  <!-- Arcane Tower (24x32) - magical crystal tower -->
  <!-- Base/foundation -->
  <rect x="2" y="28" width="20" height="4" fill="#3a3a5c"/>
  <rect x="4" y="26" width="16" height="4" fill="#4a4a6c"/>
  <!-- Tower body -->
  <rect x="6" y="12" width="12" height="16" fill="#5a5a7c"/>
  <!-- Crystal top -->
  <rect x="8" y="4" width="8" height="10" fill="#9966ff"/>
  <rect x="9" y="2" width="6" height="4" fill="#aa88ff"/>
  <rect x="10" y="0" width="4" height="3" fill="#cc99ff"/>
  <!-- Crystal glow -->
  <rect x="10" y="6" width="4" height="4" fill="#ddaaff"/>
  <!-- Windows -->
  <rect x="9" y="18" width="2" height="3" fill="#6666aa"/>
  <rect x="13" y="18" width="2" height="3" fill="#6666aa"/>
  <!-- Door -->
  <rect x="9" y="24" width="6" height="4" fill="#333355"/>
</svg>
```

### Tower: Siege Tower (Slow but Powerful)

**File**: `assets/art/src-svg/buildings/tower_siege.svg`

```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 32" width="24" height="32">
  <!-- Siege Tower (24x32) - heavy cannon tower -->
  <!-- Base platform -->
  <rect x="0" y="28" width="24" height="4" fill="#5d4e37"/>
  <rect x="2" y="26" width="20" height="4" fill="#6d5e47"/>
  <!-- Tower body (brick) -->
  <rect x="4" y="10" width="16" height="18" fill="#8b4513"/>
  <!-- Brick detail -->
  <rect x="4" y="12" width="8" height="3" fill="#9b5523"/>
  <rect x="12" y="15" width="8" height="3" fill="#9b5523"/>
  <rect x="4" y="18" width="8" height="3" fill="#9b5523"/>
  <rect x="12" y="21" width="8" height="3" fill="#9b5523"/>
  <!-- Cannon -->
  <rect x="6" y="6" width="12" height="6" fill="#444444"/>
  <rect x="5" y="8" width="3" height="4" fill="#333333"/>
  <rect x="16" y="8" width="3" height="4" fill="#333333"/>
  <!-- Cannon barrel -->
  <rect x="9" y="4" width="6" height="4" fill="#555555"/>
  <rect x="10" y="2" width="4" height="3" fill="#666666"/>
  <!-- Cannon hole -->
  <rect x="10" y="5" width="4" height="2" fill="#111111"/>
</svg>
```

### Verification:
1. Towers are visually distinct from each other
2. Arcane looks magical (purple crystal)
3. Siege looks heavy/military
4. Both fit 24x32 standard size

---

## Task 7.5: Update Assets Manifest

**Time**: 15 minutes
**File to modify**: `data/assets_manifest.json`

### Step 7.5.1: Add new effect entries

**File**: `data/assets_manifest.json`
**Action**: Add to entries

```json
{
  "id": "fx_trail_particle",
  "src_svg": "effects/fx_trail_particle.svg",
  "dimensions": {"w": 4, "h": 4},
  "category": "effect"
},
{
  "id": "fx_hit_spark",
  "src_svg": "effects/fx_hit_spark.svg",
  "dimensions": {"w": 8, "h": 8},
  "category": "effect"
},
{
  "id": "fx_critical_flash",
  "src_svg": "effects/fx_critical_flash.svg",
  "dimensions": {"w": 16, "h": 16},
  "category": "effect"
},
{
  "id": "fx_word_complete",
  "src_svg": "effects/fx_word_complete.svg",
  "dimensions": {"w": 16, "h": 16},
  "category": "effect"
}
```

### Step 7.5.2: Add status effect entries

```json
{
  "id": "status_burn",
  "src_svg": "effects/status_burn.svg",
  "dimensions": {"w": 8, "h": 8},
  "category": "status"
},
{
  "id": "status_slow",
  "src_svg": "effects/status_slow.svg",
  "dimensions": {"w": 8, "h": 8},
  "category": "status"
},
{
  "id": "status_poison",
  "src_svg": "effects/status_poison.svg",
  "dimensions": {"w": 8, "h": 8},
  "category": "status"
},
{
  "id": "status_shield",
  "src_svg": "effects/status_shield.svg",
  "dimensions": {"w": 8, "h": 8},
  "category": "status"
}
```

### Step 7.5.3: Add enemy entries

```json
{
  "id": "enemy_specter",
  "src_svg": "enemies/enemy_specter.svg",
  "dimensions": {"w": 16, "h": 16},
  "category": "enemy"
},
{
  "id": "enemy_brute",
  "src_svg": "enemies/enemy_brute.svg",
  "dimensions": {"w": 16, "h": 16},
  "category": "enemy"
}
```

### Step 7.5.4: Add tower entries

```json
{
  "id": "tower_arcane",
  "src_svg": "buildings/tower_arcane.svg",
  "dimensions": {"w": 24, "h": 32},
  "category": "building"
},
{
  "id": "tower_siege",
  "src_svg": "buildings/tower_siege.svg",
  "dimensions": {"w": 24, "h": 32},
  "category": "building"
}
```

### Verification:
1. Run `./scripts/convert_assets.sh` to generate PNGs
2. All new assets appear in `assets/sprites/`
3. No manifest validation errors

---

## Task 7.6: Create Animation Frames

**Time**: 30 minutes
**Files to create**: Animation frame SVGs

### Animation: Enemy Walk Cycle

Create 4 frames for enemy walking animation.

**File**: `assets/art/src-svg/enemies/enemy_runner_walk_01.svg`

```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="16" height="16">
  <!-- Runner walk frame 1 - neutral stance -->
  <rect x="4" y="2" width="8" height="8" fill="#8b0000"/>
  <rect x="5" y="4" width="2" height="2" fill="#ffcc00"/>
  <rect x="9" y="4" width="2" height="2" fill="#ffcc00"/>
  <rect x="4" y="10" width="3" height="4" fill="#660000"/>
  <rect x="9" y="10" width="3" height="4" fill="#660000"/>
  <rect x="4" y="14" width="3" height="2" fill="#440000"/>
  <rect x="9" y="14" width="3" height="2" fill="#440000"/>
</svg>
```

**File**: `assets/art/src-svg/enemies/enemy_runner_walk_02.svg`

```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="16" height="16">
  <!-- Runner walk frame 2 - left leg forward -->
  <rect x="4" y="2" width="8" height="8" fill="#8b0000"/>
  <rect x="5" y="4" width="2" height="2" fill="#ffcc00"/>
  <rect x="9" y="4" width="2" height="2" fill="#ffcc00"/>
  <rect x="2" y="10" width="3" height="4" fill="#660000"/>
  <rect x="10" y="10" width="3" height="4" fill="#660000"/>
  <rect x="2" y="14" width="3" height="2" fill="#440000"/>
  <rect x="10" y="14" width="3" height="2" fill="#440000"/>
</svg>
```

**File**: `assets/art/src-svg/enemies/enemy_runner_walk_03.svg`

```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="16" height="16">
  <!-- Runner walk frame 3 - neutral (same as 1) -->
  <rect x="4" y="2" width="8" height="8" fill="#8b0000"/>
  <rect x="5" y="4" width="2" height="2" fill="#ffcc00"/>
  <rect x="9" y="4" width="2" height="2" fill="#ffcc00"/>
  <rect x="4" y="10" width="3" height="4" fill="#660000"/>
  <rect x="9" y="10" width="3" height="4" fill="#660000"/>
  <rect x="4" y="14" width="3" height="2" fill="#440000"/>
  <rect x="9" y="14" width="3" height="2" fill="#440000"/>
</svg>
```

**File**: `assets/art/src-svg/enemies/enemy_runner_walk_04.svg`

```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="16" height="16">
  <!-- Runner walk frame 4 - right leg forward -->
  <rect x="4" y="2" width="8" height="8" fill="#8b0000"/>
  <rect x="5" y="4" width="2" height="2" fill="#ffcc00"/>
  <rect x="9" y="4" width="2" height="2" fill="#ffcc00"/>
  <rect x="3" y="10" width="3" height="4" fill="#660000"/>
  <rect x="11" y="10" width="3" height="4" fill="#660000"/>
  <rect x="3" y="14" width="3" height="2" fill="#440000"/>
  <rect x="11" y="14" width="3" height="2" fill="#440000"/>
</svg>
```

### Add to manifest as animation set:

```json
{
  "id": "enemy_runner_walk",
  "type": "animation",
  "frames": [
    "enemies/enemy_runner_walk_01.svg",
    "enemies/enemy_runner_walk_02.svg",
    "enemies/enemy_runner_walk_03.svg",
    "enemies/enemy_runner_walk_04.svg"
  ],
  "frame_duration_ms": 150,
  "loop": true,
  "dimensions": {"w": 16, "h": 16},
  "category": "enemy"
}
```

### Verification:
1. Animation plays at ~6-7 FPS
2. Walk cycle looks natural
3. Loop is seamless

---

## Summary Checklist

After completing all Phase 7 tasks, verify:

- [ ] Effect SVGs created (trail, spark, flash, burst)
- [ ] Status icons created (burn, slow, poison, shield)
- [ ] New enemy sprites (specter, brute)
- [ ] New tower sprites (arcane, siege)
- [ ] All entries added to assets_manifest.json
- [ ] PNGs generated with convert_assets.sh
- [ ] Animation frames for enemy walk
- [ ] All assets use pixel art style (rect/ellipse only)
- [ ] Colors match project palette

---

## SVG Template Reference

### Basic Rect Template
```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 WIDTH HEIGHT" width="WIDTH" height="HEIGHT">
  <!-- Description -->
  <rect x="X" y="Y" width="W" height="H" fill="#COLOR"/>
</svg>
```

### Ellipse for Rounded Elements
```xml
<ellipse cx="CENTER_X" cy="CENTER_Y" rx="RADIUS_X" ry="RADIUS_Y" fill="#COLOR"/>
```

### Rules
1. **Only use `<rect>` and `<ellipse>`** - no paths, no complex shapes
2. **No gradients** - solid colors only
3. **No strokes** - fill only
4. **Integer coordinates** - pixel-perfect alignment
5. **Consistent palette** - use defined colors

---

## Files Created Summary

| File | Type | Size |
|------|------|------|
| `effects/fx_trail_particle.svg` | Effect | 4x4 |
| `effects/fx_hit_spark.svg` | Effect | 8x8 |
| `effects/fx_critical_flash.svg` | Effect | 16x16 |
| `effects/fx_word_complete.svg` | Effect | 16x16 |
| `effects/status_burn.svg` | Status | 8x8 |
| `effects/status_slow.svg` | Status | 8x8 |
| `effects/status_poison.svg` | Status | 8x8 |
| `effects/status_shield.svg` | Status | 8x8 |
| `enemies/enemy_specter.svg` | Enemy | 16x16 |
| `enemies/enemy_brute.svg` | Enemy | 16x16 |
| `buildings/tower_arcane.svg` | Tower | 24x32 |
| `buildings/tower_siege.svg` | Tower | 24x32 |
| `enemies/enemy_runner_walk_*.svg` | Anim | 16x16 x4 |

**Total new assets**: 16 SVG files
