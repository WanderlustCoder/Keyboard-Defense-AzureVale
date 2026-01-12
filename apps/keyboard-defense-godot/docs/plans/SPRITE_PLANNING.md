# Sprite Planning Document

**Version:** 1.0.0
**Last Updated:** 2026-01-12
**Status:** Active Planning

---

## 1. Executive Summary

### Current State

Keyboard Defense has a substantial art asset foundation with approximately **600+ SVG source files** organized across multiple categories. The asset pipeline is well-established with SVG source files that can be converted to PNG sprites.

**Strengths:**
- Comprehensive tower sprite coverage (11 tower types with t1/t2/t3 tiers = 33 tower sprites)
- Strong UI component library (100+ UI elements)
- Good icon coverage (90+ icons including POI, status, medals, difficulty)
- Solid effect/projectile library (60+ effects)
- Terrain tileset for multiple biomes (forest, desert, swamp, mountain)
- Portrait system for NPCs and bosses

**Gaps Identified:**
- Enemy sprites do not fully align with code-defined enemy types
- Boss battle sprites are incomplete (4 bosses defined, only generic boss sprites exist)
- Production building sprites are minimal
- Animation frames are largely absent (static sprites only)
- Some affixes lack visual overlay sprites

### Key Priorities

1. **P0 (Ship Blockers):** Complete enemy-to-sprite mapping for all 10 standard enemy types
2. **P0:** Create boss battle sprites for the 4 defined bosses
3. **P1:** Add missing production building sprites
4. **P1:** Create animation frames for core combat states
5. **P2:** Expand affix overlay library
6. **P2:** Add environmental decoration variants

---

## 2. Asset Inventory Analysis

### Current Asset Counts by Category

| Category | SVG Count | Notes |
|----------|-----------|-------|
| **enemies/** | 31 | 23 enemy sprites + 8 affix overlays |
| **buildings/** | 47 | Towers (33) + castle (2) + building sprites (12) |
| **effects/** | 61 | Projectiles, impacts, typing FX, status effects |
| **tiles/** | 52 | Terrain, roads, walls, biome-specific |
| **sprites/** | 95+ | Units, FX, decorations, NPCs, animations |
| **ui/** | 100+ | Panels, buttons, bars, modals, inputs, tooltips |
| **icons/** | 100+ | Stats, status, POI, achievements, medals, map nodes |
| **portraits/** | 20 | NPCs, bosses, frames |

### Detailed Inventory

#### Enemies (31 total)

**Base Enemy Sprites (23):**
```
enemy_archer, enemy_assassin, enemy_berserker, enemy_boss,
enemy_champion, enemy_dragon, enemy_elemental_fire, enemy_elemental_ice,
enemy_flying, enemy_golem, enemy_grunt, enemy_hydra, enemy_mage,
enemy_mimic, enemy_necromancer, enemy_runner, enemy_shield_wall,
enemy_specter, enemy_swarm, enemy_tank, enemy_titan, enemy_warlord,
enemy_wraith
```

**Affix Overlays (8):**
```
affix_armored, affix_burning, affix_enraged, affix_frozen,
affix_shielded, affix_swift, affix_toxic, affix_vampiric
```

#### Towers (47 total)

**Arrow Tower:** tower_arrow, tower_arrow_t2, tower_arrow_t3
**Arcane Tower:** tower_arcane, tower_arcane_t2, tower_arcane_t3
**Cannon Tower:** tower_cannon, tower_cannon_t2, tower_cannon_t3
**Fire Tower:** tower_fire, tower_fire_t2, tower_fire_t3
**Holy Tower:** tower_holy, tower_holy_t2, tower_holy_t3
**Ice Tower:** tower_ice, tower_ice_t2, tower_ice_t3
**Lightning Tower:** tower_lightning, tower_lightning_t2, tower_lightning_t3
**Multi Tower:** tower_multi, tower_multi_t2, tower_multi_t3
**Poison Tower:** tower_poison, tower_poison_t2, tower_poison_t3
**Siege Tower:** tower_siege, tower_siege_t2, tower_siege_t3
**Support Tower:** tower_support, tower_support_t2, tower_support_t3

**Buildings:** castle_base, castle_damaged, building_barracks, building_castle, building_mine

#### Effects (61 total)

**Projectiles (17):**
```
projectile_arrow, projectile_cannonball, projectile_fireball,
projectile_ice_shard, projectile_lightning, projectile_poison,
projectile_heal, proj_arrow_fire, proj_arrow_ice, proj_arrow_poison,
proj_cannonball_heavy, proj_cannonball_cluster, proj_fireball_large,
proj_lightning_arc, proj_poison_cloud, proj_support_beam,
proj_enemy_arrow, proj_enemy_magic
```

**Impact/Combat (18):**
```
effect_explosion, effect_magic_circle, effect_heal, effect_freeze,
effect_fire_burst, effect_lightning_strike, effect_poison_cloud,
effect_shield_bubble, effect_stun_stars, effect_level_up,
effect_death_skull, effect_critical_hit, effect_poison, effect_burn,
effect_stun, effect_slow, effect_critical, effect_shield
```

**Typing FX (8):**
```
fx_keystroke_ripple, fx_word_shatter, fx_combo_flames,
fx_perfect_word, fx_typo_shake, fx_streak_glow,
fx_accuracy_ring, fx_speed_lines
```

---

## 3. Gap Analysis

### Enemy Sprites vs Code Definitions

**Code-Defined Standard Enemies (sim/enemies.gd):**

| Enemy Type | Sprite Exists? | Current Mapping | Status |
|------------|---------------|-----------------|--------|
| raider | Partial | enemy_grunt | Rename or create |
| scout | Yes | enemy_runner | OK |
| armored | Partial | enemy_shield_wall | OK (close match) |
| swarm | Yes | enemy_swarm | OK |
| tank | Yes | enemy_tank | OK |
| berserker | Yes | enemy_berserker | OK |
| phantom | Partial | enemy_specter | OK (close match) |
| champion | Yes | enemy_champion | OK |
| healer | Partial | Need enemy_healer | **MISSING** |
| elite | Partial | enemy_assassin? | Needs clarification |

**Code-Defined Boss Enemies:**

| Boss | Sprite Exists? | Status |
|------|---------------|--------|
| forest_guardian | No | **MISSING** - Need unique 64x64 or 128x128 sprite |
| stone_golem | Partial | enemy_golem exists but not boss-scale |
| fen_seer | No | **MISSING** - Need unique boss sprite |
| sunlord | No | **MISSING** - Need unique boss sprite |

### Affix Overlays vs Code

**Code-Defined Affixes (sim/enemies.gd):**

| Affix | Overlay Exists? | Status |
|-------|----------------|--------|
| swift | Yes | affix_swift |
| armored | Yes | affix_armored |
| resilient | No | **MISSING** |
| shielded | Yes | affix_shielded |
| thorny | No | **MISSING** |
| ghostly | No | **MISSING** |
| splitting | No | **MISSING** |
| regenerating | No | **MISSING** |
| commanding | No | **MISSING** |
| enraged | Yes | affix_enraged |
| vampiric | Yes | affix_vampiric |
| explosive | No | **MISSING** |

### Building Sprites vs Code

**Code-Defined Buildings (sim/buildings.gd):**

| Building | Sprite Exists? | Status |
|----------|---------------|--------|
| farm | No | **MISSING** - Need production building |
| lumber | No | **MISSING** - Need lumber mill sprite |
| quarry | Partial | building_mine may work |
| wall | Yes | bld_wall, tile_wall_* |
| tower | Yes | Multiple tower types |
| market | No | **MISSING** - Need market/shop sprite |
| barracks | Yes | building_barracks |
| temple | No | **MISSING** - Need temple/shrine sprite |
| workshop | No | **MISSING** - Need workshop sprite |

### UI Gaps

| Component | Coverage | Gaps |
|-----------|----------|------|
| Buttons | Complete | All states covered |
| Panels | Complete | Multiple variants |
| Bars | Complete | Health, mana, XP, threat, shield |
| Modals | Complete | Small, large, victory, defeat |
| Keyboard display | Partial | Keys exist but may need finger color variants |
| Campaign map | Partial | Node states exist |
| Achievement UI | Partial | Locked/unlocked icons exist |

---

## 4. Priority Tiers

### P0 - Ship Blockers (Minimum Viable Sprite Set)

These sprites are required for a playable vertical slice:

**Enemies (5 sprites needed):**
1. `enemy_raider.svg` - Primary grunt enemy, 32x32
2. `enemy_healer.svg` - Support enemy type, 32x32
3. `enemy_elite.svg` - Elite variant with affix capability, 32x32
4. `boss_forest_guardian.svg` - Day 5 boss, 64x64 or 128x128
5. `boss_stone_golem.svg` - Day 10 boss, 128x128

**Buildings (4 sprites needed):**
1. `building_farm.svg` - Food production, 32x48
2. `building_lumber.svg` - Wood production, 32x48
3. `building_market.svg` - Gold generation, 32x48
4. `building_temple.svg` - Healing support, 32x48

**Effects (2 sprites needed):**
1. `effect_word_complete.svg` - Core typing feedback (exists but verify)
2. `effect_word_error.svg` - Error feedback (exists but verify)

### P1 - Important (Polish and Completeness)

**Boss Sprites (2):**
1. `boss_fen_seer.svg` - Day 15 boss, 128x128
2. `boss_sunlord.svg` - Day 20 boss, 128x128

**Affix Overlays (6):**
1. `affix_resilient.svg` - HP bonus visual
2. `affix_thorny.svg` - Damage reflection visual
3. `affix_ghostly.svg` - Transparency/ethereal effect
4. `affix_regenerating.svg` - Healing aura
5. `affix_commanding.svg` - Leadership aura
6. `affix_explosive.svg` - Danger indicator

**Buildings (1):**
1. `building_workshop.svg` - Crafting/upgrade building

**Animation Frames (Priority sprites):**
1. Enemy idle (2-frame) for: raider, scout, tank
2. Enemy walk (4-frame) for: raider, scout
3. Enemy death (4-frame) for: generic enemy death
4. Tower attack (2-frame) for: arrow, fire, ice

### P2 - Nice to Have (Extras and Variants)

**Enemy Variants:**
- Elite versions of each enemy type (golden trim overlay)
- Regional color variants (forest green, desert tan, swamp purple)

**Environmental:**
- Additional decorations per biome (3-5 per region)
- Weather particle variations
- Day/night color shifts

**Animation Frames:**
- Full 6-frame walk cycles for all enemies
- Boss phase transition animations
- Tower construction animations
- Castle damage state transitions

---

## 5. Enemy Sprite Plan

### Standard Enemies

Each standard enemy should have:
- **Base sprite:** 32x32 static
- **Walk animation:** 4-6 frames (P1)
- **Death animation:** 4-6 frames (P2)
- **Hurt flash:** Programmatic (modulate red)

| Enemy | Visual Concept | Color Palette | Current Sprite |
|-------|---------------|---------------|----------------|
| raider | Humanoid soldier, sword | Crimson + gray | enemy_grunt (rename) |
| scout | Light, fast runner | Dark red + brown | enemy_runner |
| armored | Heavy plate, shield | Steel gray + crimson | enemy_shield_wall |
| swarm | Small creatures, many | Dark purple + red | enemy_swarm |
| tank | Large, bulky, slow | Dark steel + blood red | enemy_tank |
| berserker | Dual weapons, aggressive | Crimson + orange | enemy_berserker |
| phantom | Ethereal, semi-transparent | Purple + white glow | enemy_specter |
| champion | Elite warrior, cape | Gold trim + crimson | enemy_champion |
| healer | Robed, staff, green aura | Green + white | **CREATE** |
| elite | Any base + affix glow | Variable + gold | Overlay system |

### Enemy Visual Hierarchy

```
Tier       Size      Outline    Glow
-------    ------    -------    ----
Minion     32x32     1px        None
Soldier    32x32     1px        Subtle
Elite      32x32     2px        Yes
Champion   48x48     2px        Strong
Boss       128x128   3px        Intense
```

---

## 6. Boss Sprite Plan

### Forest Guardian (Day 5)

**Concept:** Ancient tree spirit, defender of Evergrove
**Size:** 128x128 (4x4 tiles)
**Color:** Forest green, brown bark, golden eyes

**Design Elements:**
- Twisted tree trunk body
- Glowing amber eyes
- Leafy crown/canopy
- Root tendrils as limbs
- Moss and vine details

**Phases:**
1. Full health: Lush green leaves
2. 50% health: Leaves turning orange
3. 25% health: Bare branches, bark cracking

**Required Sprites:**
- `boss_forest_guardian.svg` - Base sprite
- `boss_forest_guardian_damaged.svg` - Low health variant (P2)

### Stone Golem (Day 10)

**Concept:** Ancient stone construct from Stonepass mountains
**Size:** 128x128 (4x4 tiles)
**Color:** Gray stone, glowing blue runes

**Design Elements:**
- Massive humanoid form
- Cracked stone texture
- Glowing runic inscriptions
- Heavy fists, no legs (floats)
- Crystal core visible in chest

**Phases:**
1. Full health: Intact, runes bright
2. 50% health: Cracks appearing, runes dimming
3. 25% health: Chunks missing, core exposed

**Required Sprites:**
- `boss_stone_golem.svg` - Base sprite

### Fen Seer (Day 15)

**Concept:** Mystical swamp oracle with summoning powers
**Size:** 128x128 (4x4 tiles)
**Color:** Swamp purple, ghostly green, bone white

**Design Elements:**
- Hooded robed figure
- Multiple spectral arms
- Glowing third eye
- Swamp mist at base
- Floating bone totems

**Phases:**
1. Full health: Strong presence, many arms
2. 50% health: Some arms dissipating
3. 25% health: Hood falls, revealing skull face

**Required Sprites:**
- `boss_fen_seer.svg` - Base sprite

### Sunlord (Day 20)

**Concept:** Blazing warrior king of Sunfields
**Size:** 128x128 (4x4 tiles)
**Color:** Gold, orange fire, white hot core

**Design Elements:**
- Armored titan with crown
- Flaming sword
- Solar halo/corona
- Burning cape
- Molten metal details

**Phases:**
1. Full health: Radiant, controlled flames
2. 50% health: Flames intensifying, enraged
3. 25% health: Supernova aura, unstable

**Required Sprites:**
- `boss_sunlord.svg` - Base sprite

---

## 7. Building/Tower Sprite Plan

### Production Buildings (P0)

| Building | Size | Design Concept |
|----------|------|----------------|
| Farm | 32x48 | Wheat field, small barn, golden tones |
| Lumber Mill | 32x48 | Log pile, saw blade, wood brown |
| Quarry | 32x48 | Stone pit, pickaxe, gray stone |
| Market | 32x48 | Stall, awning, gold coins display |
| Temple | 32x48 | White stone, golden dome, holy glow |
| Workshop | 32x48 | Forge, anvil, tools, orange glow |

### Tower Sprites (Complete)

All 11 tower types with t1/t2/t3 tiers are complete:
- Arrow, Arcane, Cannon, Fire, Holy, Ice, Lightning, Multi, Poison, Siege, Support

**Tier Visual Progression:**
- T1: Basic structure, simple design
- T2: Reinforced, additional details, +8px height
- T3: Elaborate, glowing elements, +16px height

### Building Animation Needs (P2)

- Construction dust cloud (4 frames)
- Production sparkle (2 frames, looping)
- Upgrade glow (4 frames)
- Damage/destruction (6 frames)

---

## 8. Effect Sprite Plan

### Combat Effects (Mostly Complete)

**Tower Projectiles:** All covered
**Impact Effects:** All covered
**Status Effects:** All covered

### Typing Effects (P0 - Verify)

| Effect | Status | Notes |
|--------|--------|-------|
| Word complete sparkle | Exists | fx_word_complete, effect_word_complete |
| Keystroke ripple | Exists | fx_keystroke_ripple |
| Error shake | Exists | fx_typo_shake |
| Combo flames | Exists | fx_combo_flames |
| Perfect word | Exists | fx_perfect_word |
| Streak glow | Exists | fx_streak_glow |

### Missing Effects (P1)

1. `effect_affix_trigger.svg` - When affix activates
2. `effect_phase_change.svg` - Boss phase transition
3. `effect_summon.svg` - When enemies spawn minions
4. `effect_enrage.svg` - When enemies enter enraged state

---

## 9. UI/Icon Priorities

### Complete Coverage

- Button states (normal, hover, pressed, disabled)
- Panel backgrounds
- Progress bars and gauges
- Input fields and dropdowns
- Tabs and scrollbars
- Keyboard key states
- Notification types
- Modals and tooltips

### Verify Completeness (P1)

| UI Element | Check |
|------------|-------|
| Achievement popup | Verify animation support |
| Damage numbers | Font sprites or procedural |
| Wave announcement | Banner exists, verify |
| Boss health bar | Custom or generic bar |
| Combo counter | Verify display sprites |

### Missing Icons (P2)

- Building-specific icons for sidebar
- Worker assignment icons
- Research tree icons
- Trade/market icons

---

## 10. Animation Requirements

### Priority Animation Frames

**High Priority (P0-P1):**

| Entity | Animation | Frames | FPS |
|--------|-----------|--------|-----|
| Enemy (generic) | Walk | 4 | 10 |
| Enemy (generic) | Death | 4 | 12 |
| Tower (all) | Attack | 2 | 12 |
| Castle | Damage states | 3 | N/A |
| Word complete | Burst | 4 | 16 |

**Medium Priority (P1-P2):**

| Entity | Animation | Frames | FPS |
|--------|-----------|--------|-----|
| Enemy (each type) | Walk | 6 | 10 |
| Enemy (each type) | Idle | 4 | 6 |
| Boss (each) | Idle | 4 | 8 |
| Boss (each) | Attack | 6 | 12 |
| Tower | Construction | 4 | 12 |
| Building | Production | 2 | 6 |

### Animation File Naming Convention

```
{entity}_{animation}_{frame}.svg
Example: enemy_raider_walk_01.svg
         enemy_raider_walk_02.svg
         boss_forest_guardian_idle_01.svg
```

Or use sprite sheets:
```
{entity}_spritesheet.svg
With internal layer organization
```

---

## 11. Style Guide Compliance Checklist

### Before Creating Any Sprite

- [ ] Check dimensions match entity type (32x32 standard, 64x64 large, 128x128 boss)
- [ ] Use master palette colors from SPRITE_USAGE_GUIDE.md
- [ ] Apply top-left lighting direction consistently
- [ ] Add 1px outline for entities (2px for bosses)
- [ ] Use correct entity color coding:
  - Player: Royal blue (#4169e1) + gold (#ffd700)
  - Enemies: Crimson (#dc143c), Elite: Purple (#800080), Boss: Blood (#8b0000)
  - Towers: Type-specific (fire=orange, ice=cyan, etc.)

### SVG Template Compliance

- [ ] ViewBox matches expected dimensions
- [ ] No embedded fonts (convert to paths)
- [ ] Optimized for file size
- [ ] Consistent stroke widths

### Animation Compliance

- [ ] Anchor point at bottom-center
- [ ] Consistent timing across frames
- [ ] Looping animations seamless
- [ ] Key poses clearly readable

---

## 12. Production Pipeline

### SVG Creation Workflow

1. **Reference Check**
   - Review existing sprites for style consistency
   - Check SPRITE_USAGE_GUIDE.md for specifications
   - Identify similar sprites to match

2. **Create SVG**
   ```svg
   <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32">
     <!-- Use consistent layer organization -->
     <!-- Shadow layer first -->
     <!-- Body/main shape -->
     <!-- Details -->
     <!-- Outline last -->
   </svg>
   ```

3. **Save Location**
   ```
   assets/art/src-svg/{category}/{filename}.svg

   Categories:
   - enemies/    - Enemy sprites and affixes
   - buildings/  - Towers and structures
   - effects/    - Combat and typing effects
   - tiles/      - Terrain tiles
   - sprites/    - Units, NPCs, decorations
   - ui/         - Interface elements
   - icons/      - Status, achievements, map
   - portraits/  - Character portraits
   ```

4. **Register in Manifest**
   - Add entry to `data/assets_manifest.json`
   - Specify source_svg, dimensions, category

5. **Verify**
   - Run asset validation script
   - Test in-game rendering
   - Check at multiple zoom levels

### Naming Conventions

```
Pattern: {category}_{name}_{variant}.svg

Enemies:    enemy_{type}.svg, affix_{name}.svg
Bosses:     boss_{name}.svg
Towers:     tower_{type}_t{tier}.svg
Buildings:  building_{type}.svg
Effects:    effect_{name}.svg, fx_{name}.svg
Projectiles: projectile_{name}.svg, proj_{name}.svg
UI:         ui_{component}_{state}.svg
Icons:      ico_{name}.svg, status_{name}.svg
Tiles:      tile_{biome}_{type}.svg
Portraits:  portrait_{character}.svg
```

### Animation Sprite Sheets

For animated sprites, prefer sprite sheet format:
```
{entity}_spritesheet.svg

Internal structure:
Row 0: Idle (4-8 frames)
Row 1: Walk (6-8 frames)
Row 2: Attack (4-6 frames)
Row 3: Hurt (2-4 frames)
Row 4: Death (6-10 frames)
```

---

## 13. Recommended Next Steps

### Immediate Actions (This Week)

1. **Create enemy_raider.svg**
   - Or rename/adapt enemy_grunt.svg
   - Update manifest accordingly

2. **Create enemy_healer.svg**
   - Robed figure with staff
   - Green healing aura
   - 32x32 dimensions

3. **Create boss_forest_guardian.svg**
   - 128x128 tree spirit boss
   - Use Evergrove color palette
   - Add glowing eyes

4. **Verify production building sprites**
   - Check if building_farm exists in sprites/
   - Create missing: farm, lumber, market, temple

### Short-Term (Next 2 Weeks)

5. **Complete boss sprite set**
   - boss_stone_golem.svg (128x128)
   - boss_fen_seer.svg (128x128)
   - boss_sunlord.svg (128x128)

6. **Add missing affix overlays**
   - affix_resilient.svg
   - affix_thorny.svg
   - affix_ghostly.svg
   - affix_regenerating.svg
   - affix_commanding.svg
   - affix_explosive.svg

7. **Create basic animations**
   - Generic enemy walk (4 frames)
   - Generic enemy death (4 frames)
   - Tower attack flash (2 frames)

### Medium-Term (Next Month)

8. **Production building sprites**
   - building_workshop.svg
   - Verify all economy buildings complete

9. **Enemy animation frames**
   - Walk cycles for raider, scout, tank
   - Idle frames for champion, berserker

10. **Boss animations**
    - Idle animations (4 frames each)
    - Attack animations (6 frames each)
    - Phase transition effects

### Tracking Progress

Create issues/tasks for:
- [ ] P0: Enemy sprite mapping complete
- [ ] P0: Boss sprites (4 total)
- [ ] P0: Production buildings (4 total)
- [ ] P1: Missing affixes (6 overlays)
- [ ] P1: Basic animations
- [ ] P2: Full animation sets
- [ ] P2: Environmental variants

---

## Appendix A: Quick Reference - Sprite Dimensions

| Entity Type | Dimensions | Notes |
|-------------|------------|-------|
| Standard enemy | 32x32 | Single tile |
| Large enemy | 64x64 | 2x2 tiles |
| Boss enemy | 128x128 | 4x4 tiles |
| Tower T1-T2 | 32x48 | Taller than wide |
| Tower T3 | 48x64 | Larger presence |
| Building | 32x48 | Production structures |
| Castle | 64x64 or 96x96 | Central structure |
| Projectile | 16x16 | Fast moving |
| Effect | 32x32 (64x64 large) | Impacts, explosions |
| UI Icon | 16x16 (32x32 large) | Status, inventory |
| Portrait | 64x64 | Character displays |
| Tile | 32x32 | Map terrain |

## Appendix B: Color Palette Quick Reference

```
Entity Colors:
  Player:     #4169e1 (royal) + #ffd700 (gold)
  Enemy:      #dc143c (crimson)
  Elite:      #800080 (purple)
  Boss:       #8b0000 (blood)

Tower Colors:
  Arrow:      #8b4513 (brown)
  Fire:       #ff4500 (orange)
  Ice:        #87ceeb (light blue)
  Lightning:  #ffd700 (gold/yellow)
  Poison:     #32cd32 (green)
  Arcane:     #9370db (purple)
  Holy:       #ffffff (white/gold)
  Cannon:     #5c5c7a (steel gray)

Status Effects:
  Damage:     #ff4500 (orange-red)
  Healing:    #32cd32 (green)
  Buff:       #ffd700 (gold)
  Debuff:     #800080 (purple)
```

## Appendix C: File Locations

```
SVG Source:     assets/art/src-svg/
PNG Output:     assets/sprites/
Manifest:       data/assets_manifest.json
Style Guide:    docs/plans/p1/SPRITE_USAGE_GUIDE.md
```

---

*End of Sprite Planning Document*
