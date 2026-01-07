# Asset Specification Index

## Quick Reference Guide

This document serves as the master index for all Keyboard Defense asset specifications. Each specification document provides detailed requirements for asset creation.

---

## SPECIFICATION DOCUMENTS

### Core Visual Assets
| Document | Description | Asset Count |
|----------|-------------|-------------|
| [ASSET_MASTER_PLAN.md](ASSET_MASTER_PLAN.md) | Overall production plan, phases, priorities | ~475 planned |
| [ASSET_SPEC_ENEMIES.md](ASSET_SPEC_ENEMIES.md) | Enemy types, affixes, death effects | ~50 assets |
| [ASSET_SPEC_TOWERS.md](ASSET_SPEC_TOWERS.md) | Tower types, tiers, states, upgrades | ~70 assets |
| [ASSET_SPEC_CHARACTERS.md](ASSET_SPEC_CHARACTERS.md) | Player, NPCs, bosses, companions | ~60 assets |
| [ASSET_SPEC_PROJECTILES.md](ASSET_SPEC_PROJECTILES.md) | Projectiles, trails, impacts per tower | ~85 assets |

### Interface & Systems
| Document | Description | Asset Count |
|----------|-------------|-------------|
| [ASSET_SPEC_UI.md](ASSET_SPEC_UI.md) | HUD, menus, dialogs, controls | ~100 assets |
| [ASSET_SPEC_TYPING.md](ASSET_SPEC_TYPING.md) | Typing interface, keyboard, feedback | ~60 assets |
| [ASSET_SPEC_PICKUPS.md](ASSET_SPEC_PICKUPS.md) | Currency, power-ups, loot containers | ~70 assets |
| [ASSET_SPEC_PROGRESSION.md](ASSET_SPEC_PROGRESSION.md) | XP, achievements, unlockables | ~90 assets |
| [ASSET_SPEC_TUTORIAL.md](ASSET_SPEC_TUTORIAL.md) | Onboarding, hints, practice mode | ~55 assets |

### Environment & Effects
| Document | Description | Asset Count |
|----------|-------------|-------------|
| [ASSET_SPEC_MAP.md](ASSET_SPEC_MAP.md) | Tiles, terrain, decorations, structures | ~120 assets |
| [ASSET_SPEC_EFFECTS.md](ASSET_SPEC_EFFECTS.md) | Particles, trails, impacts, weather | ~80 assets |

### Audio & Accessibility
| Document | Description | Asset Count |
|----------|-------------|-------------|
| [ASSET_SPEC_AUDIO.md](ASSET_SPEC_AUDIO.md) | Music, SFX, voice, ambience | ~150 assets |
| [ASSET_SPEC_ACCESSIBILITY.md](ASSET_SPEC_ACCESSIBILITY.md) | Colorblind, high contrast, assists | ~40 assets |

**Total Documented Assets: ~1,030+**

---

## UNIVERSAL STANDARDS

### Pixel Art Rules
- **No anti-aliasing**: Hard pixel edges only
- **Limited palette**: Max 16 colors per sprite
- **Consistent lighting**: Top-left light source
- **Black outlines**: 1px outline on all sprites
- **Readable at 1x**: Must be clear at native resolution

### File Format Standards
| Type | Format | Notes |
|------|--------|-------|
| Source | SVG | Using only `<rect>` elements |
| Export | PNG | Transparency supported |
| Animation | Sprite sheet | Horizontal frame layout |
| Tileset | PNG atlas | 16x16 grid aligned |

### Naming Convention
```
[category]_[type]_[variant]_[state].svg

Examples:
enemy_necromancer_idle.svg
tower_arrow_t2_firing.svg
ui_btn_primary_hover.svg
tile_grass_flowers_02.svg
fx_impact_fire.svg
```

---

## COLOR PALETTE MASTER

### Core Colors
| Name | Hex | Usage |
|------|-----|-------|
| Navy | #2c3e50 | Primary background |
| Dark Navy | #1a252f | Deep background, shadows |
| Steel Gray | #5d6d7e | Secondary, borders |
| Light Gray | #85929e | Highlights, inactive |
| Cloud Gray | #d5d8dc | Light elements |
| White | #fdfefe | Text, bright highlights |

### Semantic Colors
| Name | Hex | Usage |
|------|-----|-------|
| Success Green | #27ae60 | Correct, health, positive |
| Warning Orange | #f39c12 | Caution, alerts |
| Danger Red | #e74c3c | Error, damage, negative |
| Info Blue | #3498db | Information, mana, water |
| Gold | #f4d03f | Currency, rewards, premium |
| Purple | #9b59b6 | Magic, special, rare |

### Extended Palette
```
Greens:  #145a32, #1e8449, #27ae60, #2ecc71, #82e0aa, #d5f5e3
Blues:   #1a5276, #2980b9, #3498db, #5dade2, #85c1e9, #d6eaf8
Reds:    #641e16, #922b21, #c0392b, #e74c3c, #f5b7b1, #fadbd8
Oranges: #6e2c00, #a04000, #d35400, #e67e22, #f39c12, #fad7a0
Purples: #4a235a, #6c3483, #7d3c98, #9b59b6, #d2b4de, #f5eef8
Browns:  #4a1c00, #6e2c00, #a04000, #dc7633
Grays:   #1a252f, #2c3e50, #34495e, #5d6d7e, #85929e, #aeb6bf
```

---

## DIMENSION REFERENCE

### Common Sprite Sizes
| Type | Dimensions | Notes |
|------|------------|-------|
| Icon (small) | 8x8 | Minimap, tiny indicators |
| Icon (standard) | 16x16 | Most UI icons |
| Icon (large) | 24x24 | Featured icons |
| Character (standard) | 16x24 | Most characters, enemies |
| Character (large) | 24x32 | Bosses, special units |
| Character (huge) | 32x40+ | Final boss, major enemies |
| Tile | 16x16 | Map tiles |
| Portrait | 48x48 | Character portraits |
| Button | 9-slice | Variable width |
| Panel | 9-slice | Variable dimensions |

### 9-Slice Margin Standards
| Element | Left | Right | Top | Bottom |
|---------|------|-------|-----|--------|
| Button | 4 | 4 | 4 | 4 |
| Panel | 8 | 8 | 8 | 8 |
| Dialog | 12 | 12 | 12 | 12 |
| Tooltip | 6 | 6 | 6 | 6 |
| Input | 8 | 8 | 4 | 4 |

---

## ANIMATION REFERENCE

### Standard Frame Counts
| Animation Type | Frames | Duration |
|----------------|--------|----------|
| Idle (subtle) | 2-4 | 1000-2000ms |
| Idle (active) | 4-6 | 800-1200ms |
| Walk | 4-6 | 400-600ms |
| Run | 6-8 | 300-400ms |
| Attack | 4-8 | 300-600ms |
| Death | 6-10 | 400-800ms |
| Effect (quick) | 4 | 200-300ms |
| Effect (medium) | 6-8 | 400-600ms |
| Effect (large) | 8-12 | 600-1000ms |

### Sprite Sheet Layout
```
Single row: Frame 1 | Frame 2 | Frame 3 | Frame 4 | ...
Total width = frame_width × frame_count
Height = single frame height
```

---

## ASSET CATEGORIES

### icons/ (16x16 default)
- Game mechanics (damage, defense, speed)
- Resources (gold, gems, materials)
- Status effects (buffs, debuffs)
- Actions (attack, build, upgrade)
- Navigation (arrows, menu)

### enemies/ (16x24 default)
- Base enemy types (8+ varieties)
- Elite affixes (6 overlays)
- Boss characters (larger sizes)
- Spawn/death effects

### towers/ (16x24 default, tower height 16x32)
- 7 tower lines (Arrow, Cannon, Fire, Ice, Lightning, Poison, Support)
- 3 tiers each (T1, T2, T3)
- States (idle, firing, disabled, overcharged)
- Projectiles per type

### ui/ (variable, mostly 9-slice)
- HUD elements
- Menu components
- Buttons, inputs, controls
- Panels, dialogs, tooltips
- Progress bars, sliders

### typing/ (variable)
- Word bubbles
- Keyboard visualization
- Letter states
- Combo displays
- Accuracy indicators

### effects/ (variable, particle sheets)
- Combat trails and impacts
- Status effect indicators
- Environmental particles
- UI feedback effects
- Screen overlays

### tiles/ (16x16)
- Terrain types (grass, dirt, stone, water)
- Autotile sets (16 per type)
- Animated tiles (water, lava)
- Path indicators

### decorations/ (variable)
- Trees, rocks, plants
- Props (crates, barrels, signs)
- Structures (ruins, buildings)
- Ambient elements

### characters/ (16x24 default)
- Player avatar + customization
- Mentor NPCs
- Shop/castle NPCs
- Boss characters
- Companion pets
- Background characters

### portraits/ (48x48)
- Character expressions (8 per character)
- Dialogue portraits
- Unlockable variants

---

## PRODUCTION PRIORITY

### Phase 1: Core Gameplay (CRITICAL)
```
□ Basic enemies (4 types)
□ Tower T1s (all 7 lines)
□ Main HUD elements
□ Typing input bar
□ Word display system
□ Basic effects (impact, death)
```

### Phase 2: Enhanced Gameplay (HIGH)
```
□ Remaining enemies
□ Tower T2 upgrades
□ Elite affixes
□ Keyboard visualization
□ Combo system visuals
□ Enhanced effects
```

### Phase 3: Polish (MEDIUM)
```
□ Tower T3 upgrades
□ Boss characters
□ Character portraits
□ Environmental tiles
□ Weather effects
□ Ambient particles
```

### Phase 4: Content Expansion (LOW)
```
□ Alternate biomes
□ Companion pets
□ Avatar customization
□ Achievement icons
□ Premium cosmetics
□ Seasonal variants
```

---

## ASSET MANIFEST INTEGRATION

All assets must be registered in `data/assets_manifest.json`:

```json
{
  "id": "unique_asset_id",
  "path": "res://assets/sprites/category/asset.png",
  "source_svg": "res://assets/art/src-svg/category/asset.svg",
  "expected_width": 64,
  "expected_height": 24,
  "max_kb": 2,
  "pixel_art": true,
  "category": "category_name",
  "frames": 4,
  "frame_width": 16,
  "frame_height": 24,
  "duration_ms": 400
}
```

### Required Fields
- `id`: Unique identifier
- `path`: Export PNG location
- `source_svg`: Source SVG location
- `expected_width`, `expected_height`: Dimensions
- `category`: Asset category

### Optional Fields
- `frames`, `frame_width`, `frame_height`, `duration_ms`: Animation data
- `margin_*`: 9-slice margins
- `tileable`: For repeating patterns
- `max_kb`: File size limit

---

## QUALITY CHECKLIST

### Per-Asset Checklist
- [ ] Follows pixel art rules (no AA, hard edges)
- [ ] Uses only approved palette colors
- [ ] Correct dimensions per spec
- [ ] Readable at 1x scale
- [ ] Consistent with existing style
- [ ] Proper naming convention
- [ ] Registered in manifest
- [ ] Animation timing feels right
- [ ] States clearly distinguished

### Per-Category Checklist
- [ ] All required variants present
- [ ] Consistent across category
- [ ] Proper layering order
- [ ] Performance budget met
- [ ] Accessibility considered

---

## TOOLS & WORKFLOW

### Recommended Tools
- **SVG Editing**: Any text editor (SVG uses rect elements only)
- **Preview**: Browser or Inkscape
- **Export**: Inkscape CLI or custom script
- **Validation**: Manifest validation script
- **Version Control**: Git LFS for binary exports

### Asset Creation Workflow
1. Read relevant spec document
2. Create SVG using rect elements
3. Validate dimensions and colors
4. Test in-engine at actual scale
5. Add to manifest
6. Commit source and export

### Review Criteria
- Matches spec exactly
- Consistent with existing assets
- Performs well (file size, rendering)
- Accessible (contrast, readability)

---

## QUICK LINKS

### Core Assets
- [Master Plan](ASSET_MASTER_PLAN.md) - Production schedule & phases
- [Enemies](ASSET_SPEC_ENEMIES.md) - Enemy types, affixes, behaviors
- [Towers](ASSET_SPEC_TOWERS.md) - Tower lines, tiers, states
- [Characters](ASSET_SPEC_CHARACTERS.md) - Player, NPCs, bosses
- [Projectiles](ASSET_SPEC_PROJECTILES.md) - Attacks, trails, impacts

### Interface & Systems
- [UI/HUD](ASSET_SPEC_UI.md) - Interface elements
- [Typing](ASSET_SPEC_TYPING.md) - Typing system visuals
- [Pickups](ASSET_SPEC_PICKUPS.md) - Collectibles, power-ups
- [Progression](ASSET_SPEC_PROGRESSION.md) - XP, achievements, unlocks
- [Tutorial](ASSET_SPEC_TUTORIAL.md) - Onboarding, hints

### Environment & Effects
- [Map/Environment](ASSET_SPEC_MAP.md) - Tiles, terrain, structures
- [Effects](ASSET_SPEC_EFFECTS.md) - Particles, weather, impacts

### Audio & Accessibility
- [Audio](ASSET_SPEC_AUDIO.md) - Music, SFX, voice, ambience
- [Accessibility](ASSET_SPEC_ACCESSIBILITY.md) - Colorblind, contrast, assists

### Data
- [Manifest](../data/assets_manifest.json) - Asset registry

---

## CHANGELOG

| Date | Change |
|------|--------|
| Session 1 | Created core spec documents (Enemies, Towers, UI, Typing, Effects, Map, Characters) |
| Session 2 | Added Projectiles, Audio, Pickups, Progression, Tutorial, Accessibility specs |
| - | Updated index with organized categories and 1,030+ documented assets |

