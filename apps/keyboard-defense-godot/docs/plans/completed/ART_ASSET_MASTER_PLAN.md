# Art Asset Master Plan

**Purpose:** Complete visual asset inventory and creation roadmap for Keyboard Defense.
**Target:** A polished, cohesive visual experience for a personal game.

---

## Current Asset Inventory

| Category | Count | Status |
|----------|-------|--------|
| Enemies | 86 | Needs animation polish |
| Buildings | 80 | Needs tier consistency |
| Effects | 130 | Good coverage |
| Animations | 88+ | Walk/idle cycles done |
| UI Elements | ~50 | Needs polish pass |
| Portraits | ~20 | Needs expressions |
| Backgrounds | ~10 | Needs variety |

---

## Art Style Guide

### Visual Identity
- **Grid Size:** 32x32 pixels (standard), 64x64 (large entities), 16x16 (small icons)
- **Color Palette:** Fantasy medieval with warm accents
- **Lighting:** Top-left light source, consistent shadows
- **Style:** Readable pixel art with clear silhouettes

### Color Palette (Hex)

```
BACKGROUNDS:
  Dark Blue:    #1a1a2e (primary bg)
  Medium Blue:  #16213e (panels)
  Light Blue:   #0f3460 (highlights)

ACCENTS:
  Gold:         #ffd700 (primary accent, rewards)
  Orange:       #e94560 (danger, enemies)
  Green:        #4ecca3 (success, health)
  Purple:       #9b59b6 (magic, special)

TERRAIN:
  Grass:        #2d5a27
  Stone:        #5d6d7e
  Water:        #3498db
  Sand:         #d4ac0d
  Snow:         #ecf0f1

FACTIONS:
  Player:       #4169e1 (royal blue)
  Enemy:        #dc143c (crimson)
  Neutral:      #95a5a6 (gray)
```

---

## Phase 1: Core Gameplay Art (Priority: HIGH)

### 1.1 Player Castle States (5 assets)
- [ ] `castle_full.svg` - 100% HP, flags waving
- [ ] `castle_damaged_1.svg` - 75% HP, minor damage
- [ ] `castle_damaged_2.svg` - 50% HP, visible cracks
- [ ] `castle_damaged_3.svg` - 25% HP, crumbling
- [ ] `castle_destroyed.svg` - 0% HP, ruins

**Specifications:**
- Size: 64x64
- Must show clear damage progression
- Animated flag on healthy states
- Smoke/fire particles on damaged states

### 1.2 Core Enemy Sprites (12 enemies x 4 frames each = 48 assets)

#### Tier 1 - Basic Enemies
- [ ] `enemy_raider_walk_01-04.svg` - Basic melee, leather armor
- [ ] `enemy_scout_walk_01-04.svg` - Fast, light, hooded
- [ ] `enemy_archer_walk_01-04.svg` - Ranged, bow visible

#### Tier 2 - Armored Enemies
- [ ] `enemy_knight_walk_01-04.svg` - Heavy armor, slow
- [ ] `enemy_berserker_walk_01-04.svg` - Dual axes, aggressive pose
- [ ] `enemy_shieldbearer_walk_01-04.svg` - Tower shield, defensive

#### Tier 3 - Special Enemies
- [ ] `enemy_mage_walk_01-04.svg` - Robes, glowing staff
- [ ] `enemy_assassin_walk_01-04.svg` - Cloak, daggers, stealthy
- [ ] `enemy_healer_walk_01-04.svg` - White robes, healing glow

#### Tier 4 - Elite Enemies
- [ ] `enemy_champion_walk_01-04.svg` - Ornate armor, cape
- [ ] `enemy_necromancer_walk_01-04.svg` - Dark robes, skull motif
- [ ] `enemy_golem_walk_01-04.svg` - Stone construct, glowing core

**Specifications:**
- Size: 32x32
- 4-frame walk cycle (left foot, neutral, right foot, neutral)
- Clear silhouette distinguishing each type
- Color-coded by tier (darker = higher tier)

### 1.3 Tower Sprites (6 types x 3 tiers = 18 assets)

#### Arrow Tower Line
- [ ] `tower_arrow_t1.svg` - Wooden, basic bow mount
- [ ] `tower_arrow_t2.svg` - Stone base, improved mount
- [ ] `tower_arrow_t3.svg` - Fortified, multiple arrow slots

#### Magic Tower Line
- [ ] `tower_magic_t1.svg` - Crystal focus, simple
- [ ] `tower_magic_t2.svg` - Larger crystal, rune circle
- [ ] `tower_magic_t3.svg` - Floating orbs, energy field

#### Cannon Tower Line
- [ ] `tower_cannon_t1.svg` - Small mortar
- [ ] `tower_cannon_t2.svg` - Bronze cannon
- [ ] `tower_cannon_t3.svg` - Double barrel, reinforced

#### Frost Tower Line
- [ ] `tower_frost_t1.svg` - Ice crystal
- [ ] `tower_frost_t2.svg` - Frozen pillar
- [ ] `tower_frost_t3.svg` - Blizzard generator

#### Lightning Tower Line
- [ ] `tower_lightning_t1.svg` - Copper rod
- [ ] `tower_lightning_t2.svg` - Tesla coil
- [ ] `tower_lightning_t3.svg` - Storm spire

#### Support Tower Line
- [ ] `tower_support_t1.svg` - Banner stand
- [ ] `tower_support_t2.svg` - War drum platform
- [ ] `tower_support_t3.svg` - Command tower

**Specifications:**
- Size: 32x32 (t1), 32x40 (t2), 32x48 (t3) - taller = stronger
- Each tier visually distinct
- Consistent style within each line
- Attack animation frames (2 each): idle, firing

### 1.4 Projectile Effects (12 assets)
- [ ] `projectile_arrow.svg` - Simple arrow
- [ ] `projectile_arrow_fire.svg` - Flaming arrow
- [ ] `projectile_magic_bolt.svg` - Energy projectile
- [ ] `projectile_magic_orb.svg` - Homing sphere
- [ ] `projectile_cannonball.svg` - Metal ball
- [ ] `projectile_cannonball_explosive.svg` - Glowing explosive
- [ ] `projectile_frost_shard.svg` - Ice spike
- [ ] `projectile_frost_wave.svg` - Spreading cold
- [ ] `projectile_lightning_bolt.svg` - Electric arc
- [ ] `projectile_lightning_chain.svg` - Branching lightning
- [ ] `projectile_support_buff.svg` - Golden aura ring
- [ ] `projectile_support_heal.svg` - Green healing wave

**Specifications:**
- Size: 16x16 or 8x8 for small projectiles
- Motion blur/trail effect built in
- Color matches tower type

---

## Phase 2: UI Polish (Priority: HIGH)

### 2.1 Typing Display Elements (15 assets)

#### Letter States
- [ ] `letter_bg_pending.svg` - Gray, untyped
- [ ] `letter_bg_current.svg` - Highlighted, active
- [ ] `letter_bg_correct.svg` - Green, success
- [ ] `letter_bg_incorrect.svg` - Red, error
- [ ] `letter_bg_combo.svg` - Gold glow, streak active

#### Word Display
- [ ] `word_container_normal.svg` - Standard word box
- [ ] `word_container_boss.svg` - Ornate, boss word
- [ ] `word_container_bonus.svg` - Shimmering, bonus word
- [ ] `word_progress_bar.svg` - Typing progress indicator

#### Keyboard Display
- [ ] `key_normal.svg` - Standard key appearance
- [ ] `key_highlighted.svg` - Next key to press
- [ ] `key_pressed.svg` - Currently pressed
- [ ] `key_finger_guide.svg` - Finger zone overlay
- [ ] `keyboard_frame.svg` - Surrounding frame
- [ ] `hand_position_guide.svg` - Home row indicator

**Specifications:**
- Scalable for different display sizes
- High contrast for readability
- Satisfying visual feedback on state change

### 2.2 HUD Elements (20 assets)

#### Resource Icons
- [ ] `icon_gold.svg` - Coin stack
- [ ] `icon_wood.svg` - Log pile
- [ ] `icon_stone.svg` - Rock chunks
- [ ] `icon_food.svg` - Bread/meat
- [ ] `icon_mana.svg` - Crystal/potion

#### Status Icons
- [ ] `icon_health.svg` - Heart
- [ ] `icon_shield.svg` - Defense
- [ ] `icon_damage.svg` - Sword
- [ ] `icon_speed.svg` - Lightning bolt
- [ ] `icon_range.svg` - Target reticle

#### Phase Indicators
- [ ] `phase_day.svg` - Sun icon
- [ ] `phase_night.svg` - Moon icon
- [ ] `phase_combat.svg` - Crossed swords
- [ ] `phase_planning.svg` - Scroll/blueprint

#### Combo/Performance
- [ ] `combo_counter_frame.svg` - Combo display border
- [ ] `grade_s.svg` - S rank badge
- [ ] `grade_a.svg` - A rank badge
- [ ] `grade_b.svg` - B rank badge
- [ ] `grade_c.svg` - C rank badge
- [ ] `streak_fire.svg` - Combo streak flame

**Specifications:**
- Size: 24x24 for icons, 48x48 for badges
- Consistent stroke width and style
- Animated versions for active states

### 2.3 Panel Decorations (10 assets)
- [ ] `panel_frame_default.svg` - Standard panel border
- [ ] `panel_frame_gold.svg` - Reward/special panels
- [ ] `panel_frame_danger.svg` - Warning panels
- [ ] `panel_corner_tl.svg` - Decorative corner (top-left)
- [ ] `panel_corner_tr.svg` - Top-right
- [ ] `panel_corner_bl.svg` - Bottom-left
- [ ] `panel_corner_br.svg` - Bottom-right
- [ ] `panel_divider_h.svg` - Horizontal separator
- [ ] `panel_divider_v.svg` - Vertical separator
- [ ] `panel_scroll_bg.svg` - Parchment texture

---

## Phase 3: Character Art (Priority: MEDIUM)

### 3.1 Elder Lyra (Mentor) - 8 expressions
- [ ] `portrait_lyra_neutral.svg` - Default teaching pose
- [ ] `portrait_lyra_happy.svg` - Proud of progress
- [ ] `portrait_lyra_encouraging.svg` - Supportive smile
- [ ] `portrait_lyra_concerned.svg` - Worried about mistakes
- [ ] `portrait_lyra_excited.svg` - Boss defeated celebration
- [ ] `portrait_lyra_thinking.svg` - Giving tips
- [ ] `portrait_lyra_serious.svg` - Important information
- [ ] `portrait_lyra_surprised.svg` - Unexpected events

**Specifications:**
- Size: 128x128
- Consistent character design across expressions
- Fantasy elder aesthetic (robes, staff, kind eyes)

### 3.2 Boss Portraits (5 bosses)
- [ ] `portrait_boss_grove_guardian.svg` - Ancient treant
- [ ] `portrait_boss_mountain_king.svg` - Dwarf warlord
- [ ] `portrait_boss_fen_seer.svg` - Swamp witch
- [ ] `portrait_boss_sunlord.svg` - Fire elemental lord
- [ ] `portrait_boss_final.svg` - Ultimate antagonist

**Specifications:**
- Size: 128x128
- Menacing but not scary (age-appropriate)
- Unique silhouette for each boss

### 3.3 NPC Portraits (6 characters)
- [ ] `portrait_blacksmith.svg` - Upgrades vendor
- [ ] `portrait_scholar.svg` - Lesson guide
- [ ] `portrait_captain.svg` - Battle tips
- [ ] `portrait_merchant.svg` - Shop keeper
- [ ] `portrait_scout.svg` - Map information
- [ ] `portrait_healer.svg` - Recovery tips

---

## Phase 4: Environmental Art (Priority: MEDIUM)

### 4.1 Terrain Tiles (30 tiles)

#### Grass Set (6)
- [ ] `tile_grass_1.svg` - Basic grass
- [ ] `tile_grass_2.svg` - Grass variation
- [ ] `tile_grass_flowers.svg` - With flowers
- [ ] `tile_grass_rocks.svg` - With small rocks
- [ ] `tile_grass_edge_n/s/e/w.svg` - Edge transitions

#### Stone Set (6)
- [ ] `tile_stone_1.svg` - Basic stone path
- [ ] `tile_stone_2.svg` - Variation
- [ ] `tile_stone_cracked.svg` - Weathered
- [ ] `tile_stone_mossy.svg` - With moss
- [ ] `tile_cobblestone.svg` - Paved path

#### Water Set (6)
- [ ] `tile_water_deep.svg` - Deep water
- [ ] `tile_water_shallow.svg` - Shallow/ford
- [ ] `tile_water_edge_n/s/e/w.svg` - Shore transitions
- [ ] `tile_water_bridge.svg` - Wooden bridge

#### Special Terrain (12)
- [ ] `tile_sand.svg` - Desert
- [ ] `tile_snow.svg` - Winter
- [ ] `tile_mud.svg` - Swamp
- [ ] `tile_lava_edge.svg` - Volcanic
- [ ] `tile_crystal.svg` - Magic terrain
- [ ] `tile_ruins.svg` - Ancient stones
- [ ] `tile_forest_floor.svg` - Under trees
- [ ] `tile_cave_floor.svg` - Underground

### 4.2 Map Decorations (20 assets)
- [ ] `deco_tree_oak.svg` - Standard tree
- [ ] `deco_tree_pine.svg` - Evergreen
- [ ] `deco_tree_dead.svg` - Spooky tree
- [ ] `deco_bush_1.svg` - Small bush
- [ ] `deco_bush_2.svg` - Large bush
- [ ] `deco_rock_small.svg` - Boulder
- [ ] `deco_rock_large.svg` - Rock formation
- [ ] `deco_flowers.svg` - Flower patch
- [ ] `deco_mushroom.svg` - Fungi cluster
- [ ] `deco_fence.svg` - Wooden fence
- [ ] `deco_signpost.svg` - Direction sign
- [ ] `deco_well.svg` - Water well
- [ ] `deco_campfire.svg` - Fire pit
- [ ] `deco_tent.svg` - Camp tent
- [ ] `deco_cart.svg` - Supply cart
- [ ] `deco_barrel.svg` - Storage barrel
- [ ] `deco_crate.svg` - Wooden crate
- [ ] `deco_statue.svg` - Stone statue
- [ ] `deco_fountain.svg` - Water fountain
- [ ] `deco_grave.svg` - Tombstone

### 4.3 Background Scenes (5 scenes)
- [ ] `bg_meadow.svg` - Peaceful plains (Act 1)
- [ ] `bg_forest.svg` - Dense woods (Act 2)
- [ ] `bg_mountains.svg` - Rocky peaks (Act 3)
- [ ] `bg_swamp.svg` - Murky wetlands (Act 4)
- [ ] `bg_fortress.svg` - Final battle (Act 5)

**Specifications:**
- Size: 320x180 (16:9 ratio)
- Parallax layers for depth effect
- Color palette matches act theme

---

## Phase 5: Effects & Particles (Priority: MEDIUM)

### 5.1 Combat Effects (25 assets)

#### Hit Effects
- [ ] `effect_hit_slash.svg` - Melee impact
- [ ] `effect_hit_pierce.svg` - Arrow impact
- [ ] `effect_hit_blunt.svg` - Hammer impact
- [ ] `effect_hit_magic.svg` - Spell impact
- [ ] `effect_hit_critical.svg` - Critical hit burst

#### Status Effects
- [ ] `effect_buff_attack.svg` - Damage up aura
- [ ] `effect_buff_defense.svg` - Shield aura
- [ ] `effect_buff_speed.svg` - Speed lines
- [ ] `effect_debuff_slow.svg` - Ice chains
- [ ] `effect_debuff_poison.svg` - Green bubbles
- [ ] `effect_debuff_burn.svg` - Fire overlay
- [ ] `effect_debuff_stun.svg` - Stars circling

#### Death Effects
- [ ] `effect_death_fade.svg` - Standard fade out
- [ ] `effect_death_explode.svg` - Burst apart
- [ ] `effect_death_dissolve.svg` - Magic dissolution
- [ ] `effect_death_smoke.svg` - Poof of smoke

### 5.2 Typing Effects (15 assets)
- [ ] `effect_keystroke_normal.svg` - Key press ripple
- [ ] `effect_keystroke_combo.svg` - Combo key burst
- [ ] `effect_keystroke_error.svg` - Error shake
- [ ] `effect_word_complete.svg` - Word finished burst
- [ ] `effect_word_perfect.svg` - Perfect word sparkle
- [ ] `effect_combo_5.svg` - 5x combo effect
- [ ] `effect_combo_10.svg` - 10x combo effect
- [ ] `effect_combo_25.svg` - 25x combo effect
- [ ] `effect_combo_50.svg` - 50x combo effect
- [ ] `effect_combo_100.svg` - 100x combo effect (legendary)
- [ ] `effect_streak_fire.svg` - Streak flames
- [ ] `effect_accuracy_sparkle.svg` - High accuracy stars
- [ ] `effect_speed_blur.svg` - Fast typing blur
- [ ] `effect_levelup.svg` - Level up celebration
- [ ] `effect_achievement.svg` - Achievement unlock

### 5.3 Environmental Effects (10 assets)
- [ ] `effect_weather_rain.svg` - Rain drops
- [ ] `effect_weather_snow.svg` - Snowflakes
- [ ] `effect_weather_leaves.svg` - Falling leaves
- [ ] `effect_weather_dust.svg` - Dust particles
- [ ] `effect_torch_flame.svg` - Animated torch
- [ ] `effect_magic_sparkle.svg` - Ambient magic
- [ ] `effect_water_ripple.svg` - Water movement
- [ ] `effect_smoke_rising.svg` - Chimney smoke
- [ ] `effect_flag_wave.svg` - Flag animation
- [ ] `effect_grass_sway.svg` - Wind in grass

---

## Phase 6: Menu & Campaign Art (Priority: LOW)

### 6.1 Main Menu Assets (8 assets)
- [ ] `menu_logo.svg` - Game title logo
- [ ] `menu_bg.svg` - Background scene
- [ ] `menu_castle_silhouette.svg` - Dramatic castle
- [ ] `menu_button_play.svg` - Start game button
- [ ] `menu_button_settings.svg` - Settings button
- [ ] `menu_button_quit.svg` - Exit button
- [ ] `menu_cursor.svg` - Custom cursor
- [ ] `menu_loading.svg` - Loading indicator

### 6.2 Campaign Map (15 assets)
- [ ] `map_node_available.svg` - Unlocked node
- [ ] `map_node_locked.svg` - Locked node
- [ ] `map_node_completed.svg` - Finished node
- [ ] `map_node_current.svg` - Active node
- [ ] `map_node_boss.svg` - Boss battle node
- [ ] `map_path_locked.svg` - Unavailable path
- [ ] `map_path_unlocked.svg` - Available path
- [ ] `map_region_1.svg` - Meadowlands
- [ ] `map_region_2.svg` - Dark Forest
- [ ] `map_region_3.svg` - Mountain Pass
- [ ] `map_region_4.svg` - Cursed Swamp
- [ ] `map_region_5.svg` - Enemy Fortress
- [ ] `map_flag_player.svg` - Player position
- [ ] `map_legend_frame.svg` - Legend box
- [ ] `map_compass.svg` - Decorative compass

### 6.3 Victory/Defeat Screens (6 assets)
- [ ] `screen_victory_bg.svg` - Win background
- [ ] `screen_victory_banner.svg` - Victory text
- [ ] `screen_defeat_bg.svg` - Loss background
- [ ] `screen_defeat_banner.svg` - Defeat text
- [ ] `screen_stats_frame.svg` - Statistics panel
- [ ] `screen_rewards_chest.svg` - Reward container

---

## Animation Specifications

### Standard Walk Cycle (4 frames)
```
Frame 1: Left foot forward, body slightly down
Frame 2: Neutral stance, body at normal height
Frame 3: Right foot forward, body slightly down
Frame 4: Neutral stance, body at normal height
```

### Attack Animation (3 frames)
```
Frame 1: Wind-up (arm/weapon back)
Frame 2: Strike (full extension)
Frame 3: Recovery (return to neutral)
```

### Idle Animation (2 frames)
```
Frame 1: Neutral breathing in
Frame 2: Slight movement (head bob, weapon shift)
```

### Death Animation (4 frames)
```
Frame 1: Hit reaction
Frame 2: Falling/stumbling
Frame 3: Collapse
Frame 4: Fade/dissolve
```

---

## Asset Naming Convention

```
[category]_[type]_[variant]_[state/frame].svg

Examples:
  enemy_raider_walk_01.svg
  tower_arrow_t2_firing.svg
  effect_hit_critical.svg
  ui_button_primary_hover.svg
  portrait_lyra_happy.svg
```

---

## Implementation Priority

### Sprint 1: Core Gameplay (Week 1-2)
1. Castle damage states
2. Core enemy walk cycles (Tier 1-2)
3. Basic tower sprites
4. Essential projectiles
5. Hit effects

### Sprint 2: UI Polish (Week 3-4)
1. Typing display elements
2. HUD icons
3. Combo/grade badges
4. Panel decorations

### Sprint 3: Characters (Week 5-6)
1. Elder Lyra expressions
2. Boss portraits
3. NPC portraits

### Sprint 4: Environment (Week 7-8)
1. Terrain tiles
2. Map decorations
3. Background scenes

### Sprint 5: Effects (Week 9-10)
1. Combat effects
2. Typing effects
3. Environmental effects

### Sprint 6: Menus (Week 11-12)
1. Main menu assets
2. Campaign map
3. Victory/defeat screens

---

## Quality Checklist

For each asset, verify:
- [ ] Correct dimensions (32x32, 64x64, etc.)
- [ ] Consistent color palette
- [ ] Clear silhouette at small sizes
- [ ] Top-left lighting
- [ ] No anti-aliasing artifacts
- [ ] Proper transparency
- [ ] Follows naming convention
- [ ] Added to assets_manifest.json

---

**Total Estimated Assets: ~280 new/revised assets**
**Existing Assets to Audit: ~300 assets**
