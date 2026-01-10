# SVG Templates for Claude Code

This document provides ready-to-use SVG templates for common asset types in Keyboard Defense. Copy and modify these templates when creating new assets.

## Quick Reference

| Asset Type | Size | Location |
|------------|------|----------|
| Enemy | 16x16 or 32x32 | `assets/art/src-svg/sprites/` |
| Building | 32x32 | `assets/art/src-svg/sprites/` |
| Tower | 32x32 | `assets/art/src-svg/sprites/` |
| Icon | 16x16 | `assets/art/src-svg/icons/` |
| Tile | 16x16 | `assets/art/src-svg/tiles/` |
| Effect | 16x16 or 32x32 | `assets/art/src-svg/sprites/` |
| UI Element | Varies | `assets/art/src-svg/ui/` |
| Boss | 64x64 or 128x128 | `assets/art/src-svg/sprites/` |

## Color Palette

### Core Colors
```
Enemy Red:       #dc143c (primary), #922b21 (dark), #c0392b (mid), #e74c3c (bright)
Player Blue:     #4169e1 (primary), #2c3e50 (dark), #5dade2 (bright)
Gold:            #ffd700 (primary), #f4d03f (light), #b7950b (shadow)
Health Green:    #32cd32 (full), #27ae60 (mid)
Health Low:      #ff4500 (low), #e74c3c (critical)
```

### UI Colors
```
Background:      #1a1a2e (dark), #2a2a3a (mid), #16213e (panel)
Text:            #f0f0f5 (primary), #eaeaea (secondary), #b0b0b5 (muted)
Border:          #0d0d0d (dark), #3a3a4a (light)
Highlight:       #f9e79f (gold glow), #5dade2 (blue glow)
```

### Terrain Colors
```
Grass:           #4a7c59 (base), #5d8c6a (light), #3d6b4a (dark)
Dirt:            #8b7355 (base), #a08060 (light), #705840 (dark)
Stone:           #6b6b6b (base), #808080 (light), #505050 (dark)
Water:           #4a90a4 (base), #5ba5b8 (light), #3a7a8a (dark)
```

---

## Enemy Templates

### Basic Enemy (16x16)
```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="16" height="16">
  <!-- Enemy: [NAME] - 16x16 [DESCRIPTION] -->

  <!-- Shadow -->
  <rect x="3" y="14" width="10" height="2" fill="#2a2a3a"/>

  <!-- Body -->
  <rect x="4" y="6" width="8" height="8" fill="#922b21"/>

  <!-- Body highlight -->
  <rect x="4" y="6" width="2" height="6" fill="#c0392b"/>

  <!-- Head -->
  <rect x="5" y="2" width="6" height="5" fill="#c0392b"/>

  <!-- Eyes -->
  <rect x="6" y="4" width="2" height="1" fill="#f4d03f"/>
  <rect x="9" y="4" width="2" height="1" fill="#f4d03f"/>
  <!-- Pupils -->
  <rect x="7" y="4" width="1" height="1" fill="#e74c3c"/>
  <rect x="10" y="4" width="1" height="1" fill="#e74c3c"/>
</svg>
```

### Elite Enemy (16x16)
```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="16" height="16">
  <!-- Elite Enemy: [NAME] - 16x16 [DESCRIPTION] -->

  <!-- Shadow -->
  <rect x="2" y="14" width="12" height="2" fill="#2a2a3a"/>

  <!-- Body (larger, armored) -->
  <rect x="3" y="5" width="10" height="9" fill="#922b21"/>

  <!-- Armor plates -->
  <rect x="4" y="6" width="8" height="2" fill="#6b6b6b"/>
  <rect x="5" y="8" width="6" height="2" fill="#6b6b6b"/>

  <!-- Body highlight -->
  <rect x="3" y="5" width="2" height="7" fill="#c0392b"/>

  <!-- Head -->
  <rect x="4" y="1" width="8" height="5" fill="#c0392b"/>

  <!-- Helmet -->
  <rect x="4" y="1" width="8" height="2" fill="#6b6b6b"/>
  <rect x="6" y="0" width="4" height="1" fill="#6b6b6b"/>

  <!-- Eyes (glowing) -->
  <rect x="5" y="3" width="2" height="2" fill="#f4d03f"/>
  <rect x="9" y="3" width="2" height="2" fill="#f4d03f"/>

  <!-- Elite glow effect -->
  <rect x="2" y="4" width="1" height="8" fill="#f4d03f" opacity="0.3"/>
  <rect x="13" y="4" width="1" height="8" fill="#f4d03f" opacity="0.3"/>
</svg>
```

### Boss Enemy (64x64)
```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="64" height="64">
  <!-- Boss: [NAME] - 64x64 [DESCRIPTION] -->

  <!-- Shadow -->
  <rect x="8" y="58" width="48" height="6" fill="#2a2a3a"/>

  <!-- Body -->
  <rect x="12" y="24" width="40" height="34" fill="#922b21"/>

  <!-- Body highlight -->
  <rect x="12" y="24" width="8" height="28" fill="#c0392b"/>

  <!-- Armor/details -->
  <rect x="16" y="28" width="32" height="8" fill="#6b6b6b"/>
  <rect x="20" y="36" width="24" height="4" fill="#6b6b6b"/>

  <!-- Head -->
  <rect x="16" y="4" width="32" height="22" fill="#c0392b"/>

  <!-- Crown/helmet -->
  <rect x="16" y="4" width="32" height="4" fill="#6b6b6b"/>
  <rect x="20" y="0" width="8" height="4" fill="#f4d03f"/>
  <rect x="36" y="0" width="8" height="4" fill="#f4d03f"/>

  <!-- Eyes (menacing, large) -->
  <rect x="20" y="12" width="8" height="6" fill="#f4d03f"/>
  <rect x="36" y="12" width="8" height="6" fill="#f4d03f"/>
  <!-- Pupils -->
  <rect x="24" y="14" width="4" height="4" fill="#e74c3c"/>
  <rect x="40" y="14" width="4" height="4" fill="#e74c3c"/>

  <!-- Mouth (teeth) -->
  <rect x="24" y="20" width="16" height="4" fill="#1a1a2e"/>
  <rect x="26" y="20" width="2" height="2" fill="#eaeaea"/>
  <rect x="30" y="20" width="2" height="2" fill="#eaeaea"/>
  <rect x="34" y="20" width="2" height="2" fill="#eaeaea"/>
  <rect x="38" y="20" width="2" height="2" fill="#eaeaea"/>
</svg>
```

---

## Building Templates

### Basic Building (32x32)
```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32" width="32" height="32">
  <!-- Building: [NAME] - 32x32 [DESCRIPTION] -->

  <!-- Shadow -->
  <rect x="4" y="28" width="24" height="4" fill="#2a2a3a"/>

  <!-- Base/foundation -->
  <rect x="4" y="24" width="24" height="6" fill="#6b6b6b"/>

  <!-- Walls -->
  <rect x="6" y="12" width="20" height="14" fill="#8b7355"/>

  <!-- Wall highlight -->
  <rect x="6" y="12" width="4" height="12" fill="#a08060"/>

  <!-- Roof -->
  <rect x="4" y="8" width="24" height="6" fill="#705840"/>
  <rect x="8" y="4" width="16" height="6" fill="#705840"/>
  <rect x="12" y="2" width="8" height="4" fill="#705840"/>

  <!-- Roof highlight -->
  <rect x="4" y="8" width="4" height="4" fill="#8b7355"/>

  <!-- Door -->
  <rect x="12" y="18" width="8" height="10" fill="#4a3628"/>
  <rect x="18" y="22" width="2" height="2" fill="#b7950b"/>

  <!-- Window -->
  <rect x="20" y="14" width="4" height="4" fill="#4a90a4"/>
  <rect x="21" y="15" width="2" height="2" fill="#5ba5b8"/>
</svg>
```

### Tower (32x32)
```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32" width="32" height="32">
  <!-- Tower: [NAME] - 32x32 [DESCRIPTION] -->

  <!-- Shadow -->
  <rect x="6" y="28" width="20" height="4" fill="#2a2a3a"/>

  <!-- Base -->
  <rect x="8" y="24" width="16" height="6" fill="#6b6b6b"/>

  <!-- Tower body -->
  <rect x="10" y="8" width="12" height="18" fill="#6b6b6b"/>

  <!-- Body highlight -->
  <rect x="10" y="8" width="3" height="16" fill="#808080"/>

  <!-- Crenellations -->
  <rect x="8" y="4" width="4" height="6" fill="#6b6b6b"/>
  <rect x="14" y="4" width="4" height="6" fill="#6b6b6b"/>
  <rect x="20" y="4" width="4" height="6" fill="#6b6b6b"/>

  <!-- Weapon/turret top -->
  <rect x="12" y="2" width="8" height="4" fill="#505050"/>

  <!-- Window slits -->
  <rect x="14" y="12" width="4" height="2" fill="#1a1a2e"/>
  <rect x="14" y="18" width="4" height="2" fill="#1a1a2e"/>

  <!-- Range indicator (optional, for game use) -->
  <!-- <circle cx="16" cy="16" r="48" fill="none" stroke="#4169e1" stroke-width="1" opacity="0.3"/> -->
</svg>
```

---

## Icon Templates

### Resource Icon (16x16)
```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="16" height="16">
  <!-- Icon: [NAME] - 16x16 [DESCRIPTION] -->

  <!-- Circular background (optional) -->
  <rect x="2" y="1" width="12" height="14" fill="#f4d03f"/>
  <rect x="1" y="3" width="14" height="10" fill="#f4d03f"/>
  <rect x="3" y="0" width="10" height="2" fill="#f4d03f"/>
  <rect x="3" y="14" width="10" height="2" fill="#f4d03f"/>

  <!-- Shadow on coin -->
  <rect x="11" y="3" width="2" height="10" fill="#b7950b"/>
  <rect x="7" y="13" width="4" height="2" fill="#b7950b"/>

  <!-- Highlight on coin -->
  <rect x="3" y="3" width="2" height="4" fill="#f9e79f"/>

  <!-- Symbol (replace with appropriate symbol) -->
  <rect x="6" y="5" width="4" height="6" fill="#b7950b"/>
  <rect x="5" y="6" width="2" height="4" fill="#b7950b"/>
  <rect x="9" y="6" width="2" height="4" fill="#b7950b"/>
</svg>
```

### Status Icon (16x16)
```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="16" height="16">
  <!-- Icon: [NAME] - 16x16 [DESCRIPTION] -->

  <!-- Background glow -->
  <rect x="3" y="2" width="10" height="12" fill="#4169e1" opacity="0.3"/>

  <!-- Main shape -->
  <rect x="4" y="3" width="8" height="10" fill="#4169e1"/>

  <!-- Highlight -->
  <rect x="4" y="3" width="2" height="8" fill="#5dade2"/>

  <!-- Inner detail -->
  <rect x="6" y="5" width="4" height="6" fill="#2c3e50"/>
</svg>
```

### POI Icon (16x16)
```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="16" height="16">
  <!-- POI: [NAME] - 16x16 [DESCRIPTION] -->

  <!-- Shadow -->
  <rect x="3" y="14" width="10" height="2" fill="#2a2a3a"/>

  <!-- Base structure -->
  <rect x="4" y="8" width="8" height="7" fill="#8b7355"/>

  <!-- Roof/top -->
  <rect x="3" y="4" width="10" height="5" fill="#705840"/>
  <rect x="5" y="2" width="6" height="3" fill="#705840"/>

  <!-- Detail (window/door) -->
  <rect x="6" y="10" width="4" height="4" fill="#4a3628"/>

  <!-- Highlight -->
  <rect x="4" y="8" width="2" height="5" fill="#a08060"/>
</svg>
```

---

## Tile Templates

### Ground Tile (16x16)
```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="16" height="16">
  <!-- Tile: [NAME] - 16x16 ground tile -->

  <!-- Base fill -->
  <rect x="0" y="0" width="16" height="16" fill="#4a7c59"/>

  <!-- Texture variation -->
  <rect x="2" y="3" width="2" height="2" fill="#5d8c6a"/>
  <rect x="8" y="1" width="2" height="2" fill="#5d8c6a"/>
  <rect x="12" y="5" width="2" height="2" fill="#5d8c6a"/>
  <rect x="4" y="9" width="2" height="2" fill="#5d8c6a"/>
  <rect x="10" y="11" width="2" height="2" fill="#5d8c6a"/>

  <!-- Shadow spots -->
  <rect x="6" y="4" width="2" height="2" fill="#3d6b4a"/>
  <rect x="1" y="10" width="2" height="2" fill="#3d6b4a"/>
  <rect x="13" y="12" width="2" height="2" fill="#3d6b4a"/>
</svg>
```

### Path Tile (16x16)
```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="16" height="16">
  <!-- Tile: [NAME] - 16x16 path tile -->

  <!-- Base ground -->
  <rect x="0" y="0" width="16" height="16" fill="#4a7c59"/>

  <!-- Path surface -->
  <rect x="2" y="0" width="12" height="16" fill="#8b7355"/>

  <!-- Path texture -->
  <rect x="4" y="2" width="2" height="2" fill="#a08060"/>
  <rect x="8" y="6" width="2" height="2" fill="#a08060"/>
  <rect x="5" y="11" width="2" height="2" fill="#a08060"/>

  <!-- Edge shadows -->
  <rect x="2" y="0" width="1" height="16" fill="#705840"/>
  <rect x="13" y="0" width="1" height="16" fill="#705840"/>
</svg>
```

### Water Tile (16x16)
```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="16" height="16">
  <!-- Tile: [NAME] - 16x16 water tile -->

  <!-- Base water -->
  <rect x="0" y="0" width="16" height="16" fill="#4a90a4"/>

  <!-- Wave highlights -->
  <rect x="2" y="3" width="4" height="1" fill="#5ba5b8"/>
  <rect x="10" y="7" width="4" height="1" fill="#5ba5b8"/>
  <rect x="4" y="11" width="4" height="1" fill="#5ba5b8"/>

  <!-- Darker depths -->
  <rect x="6" y="5" width="3" height="1" fill="#3a7a8a"/>
  <rect x="1" y="9" width="3" height="1" fill="#3a7a8a"/>
  <rect x="11" y="13" width="3" height="1" fill="#3a7a8a"/>
</svg>
```

---

## Effect Templates

### Hit Effect (16x16)
```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="16" height="16">
  <!-- Effect: Hit Flash - 16x16 -->

  <!-- Burst center -->
  <rect x="6" y="6" width="4" height="4" fill="#ffffff"/>

  <!-- Rays -->
  <rect x="7" y="2" width="2" height="4" fill="#f9e79f"/>
  <rect x="7" y="10" width="2" height="4" fill="#f9e79f"/>
  <rect x="2" y="7" width="4" height="2" fill="#f9e79f"/>
  <rect x="10" y="7" width="4" height="2" fill="#f9e79f"/>

  <!-- Diagonal rays -->
  <rect x="3" y="3" width="2" height="2" fill="#f4d03f"/>
  <rect x="11" y="3" width="2" height="2" fill="#f4d03f"/>
  <rect x="3" y="11" width="2" height="2" fill="#f4d03f"/>
  <rect x="11" y="11" width="2" height="2" fill="#f4d03f"/>
</svg>
```

### Magic Effect (16x16)
```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="16" height="16">
  <!-- Effect: Magic Burst - 16x16 -->

  <!-- Outer glow -->
  <rect x="1" y="6" width="14" height="4" fill="#5dade2" opacity="0.5"/>
  <rect x="6" y="1" width="4" height="14" fill="#5dade2" opacity="0.5"/>

  <!-- Core -->
  <rect x="5" y="5" width="6" height="6" fill="#4169e1"/>

  <!-- Bright center -->
  <rect x="6" y="6" width="4" height="4" fill="#ffffff"/>
  <rect x="7" y="7" width="2" height="2" fill="#5dade2"/>

  <!-- Sparkles -->
  <rect x="2" y="2" width="1" height="1" fill="#ffffff"/>
  <rect x="13" y="2" width="1" height="1" fill="#ffffff"/>
  <rect x="2" y="13" width="1" height="1" fill="#ffffff"/>
  <rect x="13" y="13" width="1" height="1" fill="#ffffff"/>
</svg>
```

### Projectile (16x16)
```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="16" height="16">
  <!-- Effect: Arrow Projectile - 16x16 (pointing right) -->

  <!-- Shaft -->
  <rect x="2" y="7" width="10" height="2" fill="#8b7355"/>

  <!-- Arrowhead -->
  <rect x="11" y="6" width="2" height="4" fill="#6b6b6b"/>
  <rect x="13" y="7" width="2" height="2" fill="#6b6b6b"/>
  <rect x="14" y="7" width="1" height="2" fill="#808080"/>

  <!-- Fletching -->
  <rect x="2" y="5" width="2" height="2" fill="#c0392b"/>
  <rect x="2" y="9" width="2" height="2" fill="#c0392b"/>

  <!-- Motion trail -->
  <rect x="0" y="7" width="2" height="2" fill="#8b7355" opacity="0.5"/>
</svg>
```

---

## UI Templates

### Button Background (32x12)
```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 12" width="32" height="12">
  <!-- UI: Button - 32x12 -->

  <!-- Shadow -->
  <rect x="1" y="2" width="30" height="10" fill="#0d0d0d"/>

  <!-- Base -->
  <rect x="0" y="0" width="30" height="10" fill="#2a2a3a"/>

  <!-- Highlight top -->
  <rect x="1" y="1" width="28" height="2" fill="#3a3a4a"/>

  <!-- Border -->
  <rect x="0" y="0" width="30" height="1" fill="#3a3a4a"/>
  <rect x="0" y="9" width="30" height="1" fill="#1a1a2e"/>
  <rect x="0" y="0" width="1" height="10" fill="#3a3a4a"/>
  <rect x="29" y="0" width="1" height="10" fill="#1a1a2e"/>
</svg>
```

### Panel Background (64x64)
```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="64" height="64">
  <!-- UI: Panel Background - 64x64 -->

  <!-- Outer border -->
  <rect x="0" y="0" width="64" height="64" fill="#0d0d0d"/>

  <!-- Main fill -->
  <rect x="2" y="2" width="60" height="60" fill="#1a1a2e"/>

  <!-- Inner border -->
  <rect x="2" y="2" width="60" height="2" fill="#2a2a3a"/>
  <rect x="2" y="2" width="2" height="60" fill="#2a2a3a"/>
  <rect x="2" y="58" width="60" height="2" fill="#16213e"/>
  <rect x="58" y="2" width="2" height="58" fill="#16213e"/>

  <!-- Corner accents -->
  <rect x="4" y="4" width="4" height="4" fill="#3a3a4a"/>
  <rect x="56" y="4" width="4" height="4" fill="#3a3a4a"/>
  <rect x="4" y="56" width="4" height="4" fill="#16213e"/>
  <rect x="56" y="56" width="4" height="4" fill="#16213e"/>
</svg>
```

### Progress Bar (32x8)
```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 8" width="32" height="8">
  <!-- UI: Progress Bar Background - 32x8 -->

  <!-- Outer border -->
  <rect x="0" y="0" width="32" height="8" fill="#0d0d0d"/>

  <!-- Inner background -->
  <rect x="1" y="1" width="30" height="6" fill="#1a1a2e"/>

  <!-- Fill area (adjust width for progress) -->
  <rect x="2" y="2" width="20" height="4" fill="#32cd32"/>

  <!-- Fill highlight -->
  <rect x="2" y="2" width="20" height="1" fill="#5dde5d"/>
</svg>
```

---

## Animation Frame Templates

### Walking Animation (4 frames, 16x16 each)
```svg
<!-- Frame 1: Left foot forward -->
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="16" height="16">
  <rect x="3" y="14" width="10" height="2" fill="#2a2a3a"/>
  <rect x="5" y="4" width="6" height="10" fill="#922b21"/>
  <rect x="4" y="6" width="8" height="6" fill="#922b21"/>
  <!-- Left leg forward -->
  <rect x="3" y="12" width="3" height="3" fill="#922b21"/>
  <!-- Right leg back -->
  <rect x="10" y="13" width="3" height="2" fill="#922b21"/>
</svg>

<!-- Frame 2: Standing -->
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="16" height="16">
  <rect x="3" y="14" width="10" height="2" fill="#2a2a3a"/>
  <rect x="5" y="4" width="6" height="10" fill="#922b21"/>
  <rect x="4" y="6" width="8" height="6" fill="#922b21"/>
  <!-- Both legs centered -->
  <rect x="4" y="12" width="3" height="3" fill="#922b21"/>
  <rect x="9" y="12" width="3" height="3" fill="#922b21"/>
</svg>

<!-- Frame 3: Right foot forward -->
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="16" height="16">
  <rect x="3" y="14" width="10" height="2" fill="#2a2a3a"/>
  <rect x="5" y="4" width="6" height="10" fill="#922b21"/>
  <rect x="4" y="6" width="8" height="6" fill="#922b21"/>
  <!-- Right leg forward -->
  <rect x="10" y="12" width="3" height="3" fill="#922b21"/>
  <!-- Left leg back -->
  <rect x="3" y="13" width="3" height="2" fill="#922b21"/>
</svg>

<!-- Frame 4: Standing (same as frame 2) -->
```

### Death Animation (3 frames, 16x16 each)
```svg
<!-- Frame 1: Hit stagger -->
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="16" height="16">
  <rect x="4" y="14" width="10" height="2" fill="#2a2a3a"/>
  <rect x="6" y="4" width="6" height="10" fill="#922b21"/>
  <!-- Tilted slightly -->
  <rect x="5" y="6" width="8" height="6" fill="#922b21"/>
  <!-- Flash overlay -->
  <rect x="5" y="4" width="8" height="10" fill="#ffffff" opacity="0.5"/>
</svg>

<!-- Frame 2: Falling -->
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="16" height="16">
  <rect x="3" y="14" width="12" height="2" fill="#2a2a3a"/>
  <!-- Body horizontal -->
  <rect x="3" y="10" width="10" height="4" fill="#922b21"/>
  <rect x="2" y="11" width="12" height="3" fill="#922b21"/>
</svg>

<!-- Frame 3: Dissolved/fading -->
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="16" height="16">
  <rect x="3" y="14" width="12" height="2" fill="#2a2a3a"/>
  <!-- Scattered particles -->
  <rect x="4" y="12" width="2" height="2" fill="#922b21" opacity="0.7"/>
  <rect x="8" y="11" width="2" height="2" fill="#922b21" opacity="0.5"/>
  <rect x="11" y="13" width="2" height="2" fill="#922b21" opacity="0.3"/>
  <rect x="6" y="10" width="2" height="2" fill="#922b21" opacity="0.4"/>
</svg>
```

---

## Naming Conventions

```
enemies:     enemy_[type].svg, enemy_[type]_elite.svg, enemy_boss_[name].svg
buildings:   bld_[type].svg, bld_[type]_t[tier].svg
towers:      tower_[type].svg, tower_[type]_t[tier].svg
units:       unit_[type].svg
effects:     fx_[name].svg
icons:       ico_[name].svg
pois:        poi_[name].svg
tiles:       tile_[terrain]_[variant].svg
ui:          ui_[element]_[state].svg
decorations: deco_[name].svg
```

## File Checklist

When creating a new SVG:

1. [ ] Correct viewBox and dimensions
2. [ ] Uses palette colors (no custom colors without reason)
3. [ ] Has comment header describing asset
4. [ ] Shadow included for sprites
5. [ ] Highlight/shading for depth
6. [ ] Readable at target size
7. [ ] Saved to correct directory
8. [ ] Added to `data/assets_manifest.json`
