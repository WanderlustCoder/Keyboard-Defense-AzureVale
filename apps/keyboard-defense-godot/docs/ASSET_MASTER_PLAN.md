# Keyboard Defense - Master Asset Plan

## Current Status
- **Total SVG Assets Created**: 523
- **Categories Covered**: Icons, UI, Sprites, Tiles, Buildings, Enemies, Effects, Characters, Decorations, Minimap

---

## PHASE 1: CORE GAMEPLAY ASSETS (Priority: Critical)

### 1.1 Enemy Variants & Elite Modifiers
**Purpose**: Expand enemy variety for wave diversity

| Asset ID | Dimensions | Frames | Description |
|----------|------------|--------|-------------|
| enemy_necromancer | 16x24 | 4 | Dark caster that summons minions |
| enemy_berserker | 16x24 | 4 | Fast melee, enrages at low HP |
| enemy_archer | 16x24 | 4 | Ranged attacker, stays back |
| enemy_shield_wall | 16x24 | 4 | Heavy shield, blocks projectiles |
| enemy_assassin | 16x24 | 4 | Invisible until close, fast |
| enemy_golem | 20x28 | 4 | Slow, massive HP, boss-tier |
| enemy_swarm | 12x12 | 4 | Tiny, comes in groups |
| enemy_mimic | 16x24 | 4 | Disguises as pickup, surprises |

**Elite Affixes** (overlay effects):
| Asset ID | Dimensions | Frames | Description |
|----------|------------|--------|-------------|
| affix_blazing | 16x16 | 4 | Fire aura overlay |
| affix_frozen | 16x16 | 4 | Ice crystals overlay |
| affix_vampiric | 16x16 | 4 | Blood drain effect |
| affix_arcane | 16x16 | 4 | Magic runes rotating |
| affix_thorns | 16x16 | 4 | Spike aura |
| affix_phasing | 16x16 | 4 | Ghost transparency pulse |

### 1.2 Tower Upgrades & Variants
**Purpose**: Visual progression for tower upgrade paths

| Asset ID | Dimensions | Description |
|----------|------------|-------------|
| tower_arrow_t2 | 16x24 | Upgraded arrow tower |
| tower_arrow_t3 | 16x24 | Max arrow tower with ballista |
| tower_cannon_t2 | 16x24 | Upgraded cannon |
| tower_cannon_t3 | 16x24 | Siege cannon |
| tower_fire_t2 | 16x24 | Blazing inferno |
| tower_fire_t3 | 16x24 | Phoenix flame |
| tower_ice_t2 | 16x24 | Frozen spire |
| tower_ice_t3 | 16x24 | Blizzard tower |
| tower_lightning_t2 | 16x24 | Storm spire |
| tower_lightning_t3 | 16x24 | Tesla coil |
| tower_poison_t2 | 16x24 | Toxic sprayer |
| tower_poison_t3 | 16x24 | Plague tower |
| tower_support_t2 | 16x24 | Enhanced beacon |
| tower_support_t3 | 16x24 | Command center |

**Tower States**:
| Asset ID | Dimensions | Description |
|----------|------------|-------------|
| tower_constructing | 16x24 | 4-frame building animation |
| tower_disabled | 16x24 | Offline/jammed state |
| tower_overcharged | 16x24 | Boosted glow effect |
| tower_targeting | 16x24 | Lock-on indicator |

### 1.3 Projectile Varieties
**Purpose**: Distinct visuals for each tower type's attacks

| Asset ID | Dimensions | Frames | Description |
|----------|------------|--------|-------------|
| proj_arrow_fire | 8x8 | 2 | Flaming arrow |
| proj_arrow_ice | 8x8 | 2 | Frost arrow |
| proj_arrow_poison | 8x8 | 2 | Venomous arrow |
| proj_cannonball_heavy | 12x12 | 2 | Large explosive |
| proj_cannonball_cluster | 8x8 | 2 | Splits into fragments |
| proj_fireball_large | 12x12 | 4 | Boss fire attack |
| proj_ice_shard | 8x8 | 2 | Ice projectile |
| proj_lightning_arc | 16x8 | 4 | Chain lightning |
| proj_poison_cloud | 16x16 | 4 | AOE poison |
| proj_support_beam | 8x16 | 2 | Healing/buff beam |
| proj_enemy_arrow | 8x8 | 2 | Enemy ranged attack |
| proj_enemy_magic | 8x8 | 4 | Enemy spell |

---

## PHASE 2: TYPING INTERFACE ASSETS (Priority: High)

### 2.1 Keyboard Visualization
**Purpose**: Full keyboard display for tutorials and feedback

| Asset ID | Dimensions | Description |
|----------|------------|-------------|
| key_wide | 24x16 | Wide keys (Tab, Caps, Shift) |
| key_space | 64x16 | Spacebar |
| key_enter | 20x16 | Enter key |
| key_backspace | 24x16 | Backspace key |
| keyboard_layout_full | 256x80 | Complete QWERTY layout |
| keyboard_layout_compact | 192x64 | Compact letter keys only |
| keyboard_numpad | 48x64 | Number pad section |

**Finger Color Coding**:
| Asset ID | Dimensions | Description |
|----------|------------|-------------|
| key_finger_pinky_l | 16x16 | Left pinky zone (blue) |
| key_finger_ring_l | 16x16 | Left ring zone (cyan) |
| key_finger_middle_l | 16x16 | Left middle zone (green) |
| key_finger_index_l | 16x16 | Left index zone (yellow) |
| key_finger_index_r | 16x16 | Right index zone (yellow) |
| key_finger_middle_r | 16x16 | Right middle zone (green) |
| key_finger_ring_r | 16x16 | Right ring zone (cyan) |
| key_finger_pinky_r | 16x16 | Right pinky zone (blue) |
| key_finger_thumb | 16x16 | Thumb zone (orange) |

### 2.2 Word Display Elements
**Purpose**: Enhanced word visualization during gameplay

| Asset ID | Dimensions | Description |
|----------|------------|-------------|
| word_container | 64x16 | 9-slice word background |
| word_container_active | 64x16 | Currently typing word |
| word_container_urgent | 64x16 | Low time remaining |
| word_container_bonus | 64x16 | Bonus word (gold border) |
| char_highlight_next | 8x12 | Next character indicator |
| char_highlight_error | 8x12 | Error state (red shake) |
| char_typed_correct | 8x12 | Green confirmed character |
| char_typed_wrong | 8x12 | Red strikethrough |
| word_difficulty_1 | 8x8 | Easy word marker |
| word_difficulty_2 | 8x8 | Medium word marker |
| word_difficulty_3 | 8x8 | Hard word marker |
| word_difficulty_4 | 8x8 | Expert word marker |

### 2.3 Typing Feedback Effects
**Purpose**: Satisfying visual feedback for typing actions

| Asset ID | Dimensions | Frames | Description |
|----------|------------|--------|-------------|
| fx_keystroke_ripple | 32x32 | 6 | Key press ripple effect |
| fx_word_shatter | 64x32 | 8 | Word completion burst |
| fx_combo_flames | 48x24 | 6 | Combo fire effect |
| fx_accuracy_ring | 24x24 | 4 | Accuracy indicator pulse |
| fx_speed_lines | 32x16 | 4 | WPM speed effect |
| fx_perfect_word | 64x32 | 6 | Perfect word completion |
| fx_typo_shake | 32x16 | 4 | Screen shake on error |
| fx_streak_glow | 48x16 | 4 | Streak maintenance aura |

---

## PHASE 3: HUD & INTERFACE ASSETS (Priority: High)

### 3.1 Main HUD Components
**Purpose**: In-game heads-up display elements

| Asset ID | Dimensions | Description |
|----------|------------|-------------|
| hud_frame_main | 320x48 | Main HUD container |
| hud_frame_stats | 128x32 | Stats panel container |
| hud_frame_minimap | 80x80 | Minimap container |
| hud_frame_word_queue | 192x24 | Word queue display |
| hud_wave_counter | 48x24 | Wave number display |
| hud_gold_counter | 64x20 | Gold amount display |
| hud_threat_meter | 96x16 | Threat level bar |
| hud_combo_display | 64x32 | Combo counter |
| hud_wpm_display | 48x24 | Words per minute |
| hud_accuracy_display | 48x24 | Accuracy percentage |
| hud_timer_display | 48x20 | Round timer |

### 3.2 Resource Bars & Indicators
**Purpose**: Health, mana, and resource visualization

| Asset ID | Dimensions | Description |
|----------|------------|-------------|
| bar_health_segmented | 64x8 | Segmented health bar |
| bar_health_boss | 128x12 | Boss health bar |
| bar_shield_overlay | 64x8 | Shield over health |
| bar_energy_pips | 48x8 | Pip-based energy |
| bar_cooldown_radial | 24x24 | Circular cooldown |
| bar_charge_meter | 32x8 | Special ability charge |
| indicator_ammo | 32x8 | Ammunition count |
| indicator_lives | 48x12 | Life counter |
| indicator_streak_flame | 24x24 | Active streak indicator |

### 3.3 Notification & Alert System
**Purpose**: Player notifications and alerts

| Asset ID | Dimensions | Description |
|----------|------------|-------------|
| notif_frame_small | 96x24 | Small notification |
| notif_frame_large | 192x48 | Large notification |
| notif_icon_warning | 16x16 | Warning icon |
| notif_icon_error | 16x16 | Error icon |
| notif_icon_success | 16x16 | Success icon |
| notif_icon_info | 16x16 | Info icon |
| notif_icon_upgrade | 16x16 | Upgrade available |
| notif_icon_wave | 16x16 | Wave incoming |
| notif_icon_boss | 16x16 | Boss warning |
| alert_banner_danger | 256x32 | Danger alert banner |
| alert_banner_bonus | 256x32 | Bonus event banner |
| alert_boss_incoming | 128x64 | Boss arrival alert |

---

## PHASE 4: MENU & SCREEN ASSETS (Priority: Medium)

### 4.1 Main Menu Elements
**Purpose**: Title screen and main navigation

| Asset ID | Dimensions | Description |
|----------|------------|-------------|
| logo_game | 192x64 | Game title logo |
| logo_game_small | 96x32 | Compact logo |
| menu_bg_castle | 320x180 | Castle background scene |
| menu_bg_battlefield | 320x180 | Battle scene background |
| menu_cloud_layer | 320x64 | Parallax cloud layer |
| menu_ground_layer | 320x48 | Parallax ground layer |
| menu_frame_main | 256x192 | Main menu container |
| menu_button_play | 128x32 | Play button |
| menu_button_options | 128x32 | Options button |
| menu_button_quit | 128x32 | Quit button |
| menu_divider_fancy | 128x8 | Decorative divider |

### 4.2 Pause & Options Menus
**Purpose**: In-game pause and settings screens

| Asset ID | Dimensions | Description |
|----------|------------|-------------|
| pause_overlay | 320x180 | Darkened pause overlay |
| pause_frame | 192x160 | Pause menu container |
| options_tab_audio | 48x16 | Audio tab |
| options_tab_video | 48x16 | Video tab |
| options_tab_controls | 48x16 | Controls tab |
| options_tab_gameplay | 48x16 | Gameplay tab |
| volume_speaker_0 | 16x16 | Muted speaker |
| volume_speaker_1 | 16x16 | Low volume |
| volume_speaker_2 | 16x16 | Medium volume |
| volume_speaker_3 | 16x16 | High volume |

### 4.3 Victory & Defeat Screens
**Purpose**: End-of-round result displays

| Asset ID | Dimensions | Description |
|----------|------------|-------------|
| victory_banner | 192x48 | Victory text banner |
| victory_frame | 256x192 | Victory screen container |
| victory_confetti | 64x64 | 8-frame confetti animation |
| victory_trophy_shine | 48x48 | 6-frame trophy animation |
| defeat_banner | 192x48 | Defeat text banner |
| defeat_frame | 256x192 | Defeat screen container |
| defeat_crack_overlay | 320x180 | Screen crack effect |
| stats_row_bg | 192x20 | Stats row background |
| stats_star_filled | 24x24 | Filled rating star |
| stats_star_empty | 24x24 | Empty rating star |
| stats_medal_new | 32x32 | New record indicator |

### 4.4 Loading & Transitions
**Purpose**: Loading screens and scene transitions

| Asset ID | Dimensions | Description |
|----------|------------|-------------|
| loading_bg | 320x180 | Loading background |
| loading_frame | 192x48 | Loading bar container |
| loading_tip_bg | 256x32 | Tip display background |
| transition_wipe_h | 320x180 | Horizontal wipe |
| transition_wipe_v | 320x180 | Vertical wipe |
| transition_fade | 320x180 | Fade overlay |
| transition_diamond | 320x180 | Diamond iris |
| loading_icon_sword | 32x32 | 4-frame spinning sword |
| loading_icon_book | 32x32 | 4-frame page flip |

---

## PHASE 5: MAP & WORLD ASSETS (Priority: Medium)

### 5.1 World Map Elements
**Purpose**: Campaign/level select map visuals

| Asset ID | Dimensions | Description |
|----------|------------|-------------|
| map_bg_parchment | 320x180 | Parchment texture |
| map_region_forest | 64x64 | Forest region icon |
| map_region_mountain | 64x64 | Mountain region icon |
| map_region_swamp | 64x64 | Swamp region icon |
| map_region_desert | 64x64 | Desert region icon |
| map_region_castle | 64x64 | Castle region icon |
| map_path_line | 4x16 | Tileable path segment |
| map_path_dot | 8x8 | Path waypoint dot |
| map_fog_edge | 32x32 | Fog of war edge |
| map_fog_solid | 32x32 | Unexplored fog |
| map_compass | 32x32 | Compass rose |
| map_legend_bg | 96x128 | Legend panel |

### 5.2 Biome Tile Sets
**Purpose**: Additional biome variety for levels

**Desert Biome**:
| Asset ID | Dimensions | Description |
|----------|------------|-------------|
| tile_sand | 16x16 | Base sand tile |
| tile_sand_dune | 16x16 | Sand dune tile |
| tile_oasis | 16x16 | Oasis water |
| tile_cactus | 16x24 | Cactus decoration |
| tile_bones | 16x16 | Skeleton remains |
| tile_pyramid_base | 16x16 | Pyramid structure |

**Swamp Biome**:
| Asset ID | Dimensions | Description |
|----------|------------|-------------|
| tile_swamp_water | 16x16 | Murky water |
| tile_swamp_mud | 16x16 | Muddy ground |
| tile_lily_pad | 16x16 | Lily pad decoration |
| tile_dead_tree | 16x24 | Dead tree |
| tile_mushroom | 12x12 | Swamp mushroom |
| tile_fog_ground | 16x16 | Low fog overlay |

**Mountain Biome**:
| Asset ID | Dimensions | Description |
|----------|------------|-------------|
| tile_rock_dark | 16x16 | Dark stone |
| tile_snow | 16x16 | Snow covered |
| tile_ice | 16x16 | Frozen ice |
| tile_cliff_edge | 16x16 | Cliff face |
| tile_cave_entrance | 24x24 | Cave opening |
| tile_crystal | 12x16 | Crystal formation |

---

## PHASE 6: CHARACTER & NPC ASSETS (Priority: Medium)

### 6.1 Player Character Variants
**Purpose**: Customizable player avatar options

| Asset ID | Dimensions | Frames | Description |
|----------|------------|--------|-------------|
| hero_knight | 16x24 | 4 | Knight class |
| hero_mage | 16x24 | 4 | Mage class |
| hero_ranger | 16x24 | 4 | Ranger class |
| hero_scholar | 16x24 | 4 | Scholar class |
| hero_custom_head_1-8 | 16x16 | 1 | Head variations |
| hero_custom_body_1-8 | 16x16 | 1 | Body variations |
| hero_custom_color_1-8 | 16x24 | 1 | Color palette swaps |

### 6.2 NPC Animations
**Purpose**: Expanded NPC interaction states

| Asset ID | Dimensions | Frames | Description |
|----------|------------|--------|-------------|
| npc_lyra_talk | 16x24 | 4 | Lyra talking animation |
| npc_lyra_happy | 16x24 | 4 | Lyra happy expression |
| npc_lyra_worried | 16x24 | 4 | Lyra concerned |
| npc_merchant_idle | 16x24 | 4 | Merchant idle loop |
| npc_merchant_sell | 16x24 | 4 | Merchant transaction |
| npc_commander_salute | 16x24 | 4 | Commander salute |
| npc_commander_point | 16x24 | 4 | Commander directing |
| npc_scholar_read | 16x24 | 4 | Scholar reading book |

### 6.3 Portrait Expressions
**Purpose**: Dialogue portrait emotion variants

| Asset ID | Dimensions | Description |
|----------|------------|-------------|
| portrait_lyra_neutral | 48x48 | Default expression |
| portrait_lyra_happy | 48x48 | Happy/excited |
| portrait_lyra_sad | 48x48 | Sad/disappointed |
| portrait_lyra_angry | 48x48 | Angry/determined |
| portrait_lyra_surprised | 48x48 | Shocked/surprised |
| portrait_commander_neutral | 48x48 | Default expression |
| portrait_commander_stern | 48x48 | Serious expression |
| portrait_merchant_neutral | 48x48 | Default expression |
| portrait_merchant_happy | 48x48 | Good sale expression |

---

## PHASE 7: ANIMATION & EFFECTS (Priority: Medium)

### 7.1 Environmental Animations
**Purpose**: Living world ambient effects

| Asset ID | Dimensions | Frames | Description |
|----------|------------|--------|-------------|
| anim_torch_flame | 8x16 | 4 | Torch fire flicker |
| anim_water_ripple | 16x16 | 4 | Water surface ripple |
| anim_grass_sway | 16x16 | 4 | Grass wind movement |
| anim_flag_wave | 16x24 | 4 | Banner waving |
| anim_butterfly | 8x8 | 4 | Butterfly flutter |
| anim_bird_fly | 12x8 | 4 | Bird flying across |
| anim_leaves_fall | 16x16 | 6 | Falling leaves |
| anim_dust_mote | 8x8 | 4 | Floating dust particles |
| anim_sparkle_ambient | 8x8 | 4 | Magical sparkles |
| anim_smoke_chimney | 16x24 | 6 | Chimney smoke rise |

### 7.2 Combat Effects
**Purpose**: Battle visual effects

| Asset ID | Dimensions | Frames | Description |
|----------|------------|--------|-------------|
| fx_explosion_small | 24x24 | 6 | Small explosion |
| fx_explosion_large | 48x48 | 8 | Large explosion |
| fx_slash_horizontal | 32x16 | 4 | Horizontal slash |
| fx_slash_vertical | 16x32 | 4 | Vertical slash |
| fx_slash_diagonal | 24x24 | 4 | Diagonal slash |
| fx_stun_stars | 24x24 | 4 | Stun indicator |
| fx_poison_drip | 16x24 | 4 | Poison damage tick |
| fx_burn_ember | 16x16 | 4 | Burn damage tick |
| fx_freeze_crack | 24x24 | 4 | Freeze effect |
| fx_critical_slash | 48x24 | 6 | Critical hit slash |

### 7.3 UI Animations
**Purpose**: Interface animation sprites

| Asset ID | Dimensions | Frames | Description |
|----------|------------|--------|-------------|
| anim_button_pulse | 48x16 | 4 | Button attention pulse |
| anim_notification_pop | 96x24 | 4 | Notification appear |
| anim_star_spin | 24x24 | 8 | Star rating reveal |
| anim_coin_add | 16x16 | 4 | Coin counter increment |
| anim_xp_fill | 64x8 | 6 | XP bar fill animation |
| anim_level_up_glow | 48x48 | 8 | Level up celebration |
| anim_unlock_burst | 32x32 | 6 | Unlock reveal effect |
| anim_cursor_click | 16x16 | 4 | Click feedback |

---

## PHASE 8: ACCESSIBILITY ASSETS (Priority: High)

### 8.1 High Contrast Variants
**Purpose**: Accessibility-focused visual alternatives

| Asset ID | Dimensions | Description |
|----------|------------|-------------|
| hc_enemy_grunt | 16x24 | High contrast enemy |
| hc_enemy_boss | 20x28 | High contrast boss |
| hc_tower_arrow | 16x24 | High contrast tower |
| hc_projectile | 8x8 | High contrast projectile |
| hc_word_container | 64x16 | High contrast word box |
| hc_key_highlight | 16x16 | High contrast key |

### 8.2 Colorblind-Friendly Variants
**Purpose**: Deuteranopia/Protanopia friendly

| Asset ID | Dimensions | Description |
|----------|------------|-------------|
| cb_bar_health | 64x8 | Blue health bar |
| cb_bar_danger | 64x8 | Yellow danger bar |
| cb_indicator_good | 16x16 | Pattern-based good |
| cb_indicator_bad | 16x16 | Pattern-based bad |
| cb_enemy_elite | 16x24 | Shape-based elite |
| cb_word_correct | 8x12 | Checkmark + blue |
| cb_word_wrong | 8x12 | X + orange |

### 8.3 Screen Reader Hints
**Purpose**: Visual cues for important states

| Asset ID | Dimensions | Description |
|----------|------------|-------------|
| hint_danger_border | 320x180 | Danger screen border |
| hint_focus_indicator | 24x24 | Current focus highlight |
| hint_action_required | 32x32 | Action needed pulse |
| hint_tutorial_arrow | 32x32 | Large directional arrow |

---

## PHASE 9: SEASONAL & EVENT ASSETS (Priority: Low)

### 9.1 Holiday Themes
**Purpose**: Limited-time seasonal content

**Winter/Holiday**:
| Asset ID | Dimensions | Description |
|----------|------------|-------------|
| winter_snow_overlay | 320x180 | Snow falling overlay |
| winter_tree_decorated | 16x24 | Decorated tree |
| winter_enemy_snowman | 16x24 | Snowman enemy skin |
| winter_tower_icicle | 16x24 | Icy tower skin |
| winter_gift_pickup | 16x16 | Gift box pickup |

**Halloween**:
| Asset ID | Dimensions | Description |
|----------|------------|-------------|
| halloween_fog_overlay | 320x180 | Spooky fog |
| halloween_pumpkin | 16x16 | Jack-o-lantern |
| halloween_ghost_enemy | 16x24 | Ghost enemy skin |
| halloween_bat_swarm | 32x16 | Bat swarm effect |
| halloween_tombstone | 16x24 | Tombstone decoration |

---

## PHASE 10: POLISH & JUICE ASSETS (Priority: Low)

### 10.1 Screen Shake Assets
**Purpose**: Camera shake and impact effects

| Asset ID | Dimensions | Frames | Description |
|----------|------------|--------|-------------|
| shake_impact_small | 8 frames | - | Position offset data |
| shake_impact_large | 12 frames | - | Heavy impact |
| shake_rumble | 16 frames | - | Continuous rumble |
| shake_explosion | 10 frames | - | Explosion tremor |

### 10.2 Juice Effects
**Purpose**: Satisfying micro-feedback

| Asset ID | Dimensions | Frames | Description |
|----------|------------|--------|-------------|
| juice_pop | 16x16 | 4 | Pop/appear effect |
| juice_squish | 16x16 | 4 | Squash and stretch |
| juice_wobble | 16x16 | 6 | Jelly wobble |
| juice_bounce | 16x16 | 6 | Bounce settle |
| juice_shine | 24x24 | 4 | Gleam/shine pass |
| juice_pulse | 16x16 | 4 | Size pulse |

---

## ASSET SPECIFICATIONS

### Color Palette
```
Primary Colors:
- Dark Navy: #1a252f
- Navy: #2c3e50
- Gray Blue: #34495e
- Light Gray Blue: #5d6d7e
- Silver: #85929e

Accent Colors:
- Green (Success/Health): #27ae60, #2ecc71
- Blue (Mana/Info): #3498db, #5dade2
- Red (Danger/Error): #e74c3c, #c0392b
- Gold (Currency/Rare): #f4d03f, #f39c12
- Purple (Magic/Elite): #9b59b6, #8e44ad

UI Colors:
- White: #fdfefe, #ecf0f1
- Background: #0d1318
```

### Animation Standards
- **Idle loops**: 4 frames @ 150ms per frame
- **Action animations**: 6-8 frames @ 100ms per frame
- **Effects**: 4-6 frames @ 80ms per frame
- **UI transitions**: 4 frames @ 50ms per frame

### File Naming Convention
```
[category]_[name]_[variant]_[state].svg

Examples:
- enemy_grunt_elite_idle.svg
- tower_arrow_t2_firing.svg
- fx_explosion_large.svg
- ui_button_primary_hover.svg
```

### 9-Slice Margins
```
Standard Button: margin 4px all sides
Panel: margin 4px all sides
Tooltip: margin 4-8px
Progress Bar: margin 2px top/bottom, 4px left/right
```

---

## IMPLEMENTATION PRIORITY

### Sprint 1 (Critical Path)
1. Enemy variants (necromancer, berserker, archer)
2. Tower tier 2 upgrades
3. Main HUD components
4. Word display elements

### Sprint 2 (Core Experience)
1. Tower tier 3 upgrades
2. Typing feedback effects
3. Notification system
4. Combat effects expansion

### Sprint 3 (Polish)
1. Menu screens
2. Victory/Defeat screens
3. Loading transitions
4. Environmental animations

### Sprint 4 (Expansion)
1. Additional biomes
2. NPC animations
3. Portrait expressions
4. Accessibility variants

### Sprint 5 (Events)
1. Seasonal themes
2. Juice effects
3. Screen shake assets
4. Achievement badges

---

## TOTAL ESTIMATED NEW ASSETS

| Category | Count |
|----------|-------|
| Enemies & Variants | 45 |
| Towers & Upgrades | 35 |
| Projectiles | 15 |
| Keyboard/Typing | 40 |
| HUD Elements | 50 |
| Menu Screens | 45 |
| Map & World | 60 |
| Characters | 35 |
| Animations | 45 |
| Effects | 40 |
| Accessibility | 25 |
| Seasonal | 20 |
| Polish/Juice | 20 |
| **TOTAL** | **~475** |

Combined with existing 523 assets = **~1000 total assets** for complete game.
