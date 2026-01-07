# Visual Effects Asset Specifications

## Design Philosophy
- **Clarity Over Flash**: Effects enhance gameplay, never obscure it
- **Performance Budget**: Effects should be lightweight, particle limits enforced
- **Consistent Style**: All effects share pixel-art aesthetic
- **Meaningful Feedback**: Every effect communicates game state

---

## PARTICLE SYSTEMS

### Particle Size Standards
```
Tiny:     2x2 (dust, sparkles)
Small:    4x4 (standard particles)
Medium:   8x8 (explosions, impacts)
Large:    16x16 (major effects)
```

### Particle Count Limits
```
Per Effect:     20-50 particles max
Screen Total:   200 particles max
Priority:       Gameplay > Decorative
```

---

## COMBAT EFFECTS

### Projectile Trails

#### Arrow Trail (fx_trail_arrow)
```
Dimensions: 4x2
Frames: 4
Duration: 200ms
Color: #5d6d7e → transparent
Visual: Thin gray line, fades quickly
```

#### Cannon Trail (fx_trail_cannon)
```
Dimensions: 8x8
Frames: 6
Duration: 300ms
Color: #5d6d7e, #85929e (smoke)
Visual: Puff of smoke, expands and fades
```

#### Fire Trail (fx_trail_fire)
```
Dimensions: 8x8
Frames: 6
Duration: 400ms
Color: #e74c3c, #f39c12, #f4d03f
Visual: Flickering flame, diminishes
```

#### Ice Trail (fx_trail_ice)
```
Dimensions: 6x6
Frames: 4
Duration: 250ms
Color: #85c1e9, #d6eaf8, #fdfefe
Visual: Frost crystals, shatter
```

#### Lightning Trail (fx_trail_lightning)
```
Dimensions: Variable (procedural)
Frames: 6
Duration: 200ms
Color: #f4d03f, #fdfefe
Visual: Crackling arc, branches
```

#### Poison Trail (fx_trail_poison)
```
Dimensions: 8x8
Frames: 6
Duration: 400ms
Color: #27ae60, #82e0aa
Visual: Dripping globs, splash
```

---

### Impact Effects

#### Arrow Impact (fx_impact_arrow)
```
Dimensions: 16x16
Frames: 6
Duration: 300ms
Visual: Arrow sticks, wood splinter particles
Colors: #6e2c00, #a04000
```

#### Cannon Impact (fx_impact_cannon)
```
Dimensions: 32x32
Frames: 8
Duration: 400ms
Visual: Explosion, debris, smoke ring
Colors: #f39c12, #e74c3c, #5d6d7e
Screen Shake: Yes (small)
```

#### Fire Impact (fx_impact_fire)
```
Dimensions: 24x24
Frames: 8
Duration: 500ms
Visual: Flame burst, ember scatter
Colors: #e74c3c, #f39c12, #f4d03f
DoT Indicator: Small flames linger
```

#### Ice Impact (fx_impact_ice)
```
Dimensions: 24x24
Frames: 8
Duration: 400ms
Visual: Ice crystal burst, freeze flash
Colors: #3498db, #85c1e9, #fdfefe
Slow Indicator: Ice chunks orbit target
```

#### Lightning Impact (fx_impact_lightning)
```
Dimensions: 24x24
Frames: 6
Duration: 250ms
Visual: Electric burst, arc discharge
Colors: #f4d03f, #fdfefe
Chain Effect: Arc to nearby enemies
```

#### Poison Impact (fx_impact_poison)
```
Dimensions: 24x24
Frames: 8
Duration: 500ms
Visual: Splash, bubbling puddle
Colors: #27ae60, #82e0aa, #d5f5e3
DoT Indicator: Bubble particles rise
```

---

### Damage Numbers

#### Standard Damage (dmg_number)
```
Dimensions: Variable (text)
Animation: Float up, fade out
Duration: 800ms
Color: #fdfefe (white)
Font: Bold pixel font
```

#### Critical Damage (dmg_critical)
```
Dimensions: Variable (larger text)
Animation: Scale up, shake, float, fade
Duration: 1000ms
Color: #f4d03f (gold)
Effect: Star particles around number
```

#### Weak Damage (dmg_weak)
```
Dimensions: Variable (smaller text)
Animation: Float up (short), fade
Duration: 600ms
Color: #85929e (gray)
```

#### Healing (dmg_heal)
```
Dimensions: Variable
Animation: Float up with plus sign
Duration: 800ms
Color: #27ae60 (green)
Effect: Plus particles
```

#### Shield Block (dmg_blocked)
```
Dimensions: Variable
Animation: Bounce, fade
Duration: 600ms
Color: #3498db (blue)
Text: "BLOCKED" or shield icon
```

---

## TOWER EFFECTS

### Tower Attack Animations

#### Arrow Tower Fire (fx_tower_arrow_fire)
```
Dimensions: 16x16
Frames: 4
Duration: 200ms
Visual: Bow draw, release, arrow spawn
```

#### Cannon Tower Fire (fx_tower_cannon_fire)
```
Dimensions: 24x24
Frames: 6
Duration: 400ms
Visual: Recoil, muzzle flash, smoke
Screen Shake: Yes (tiny)
```

#### Fire Tower Fire (fx_tower_fire_fire)
```
Dimensions: 24x24
Frames: 6
Duration: 300ms
Visual: Flame jet, heat shimmer
```

#### Ice Tower Fire (fx_tower_ice_fire)
```
Dimensions: 24x24
Frames: 6
Duration: 350ms
Visual: Frost beam, crystal formation
```

#### Lightning Tower Fire (fx_tower_lightning_fire)
```
Dimensions: 32x32
Frames: 8
Duration: 400ms
Visual: Charge up, arc discharge
Sound: Electrical crackle
```

#### Poison Tower Fire (fx_tower_poison_fire)
```
Dimensions: 24x24
Frames: 6
Duration: 350ms
Visual: Spray nozzle, glob launch
```

---

### Tower State Effects

#### Tower Idle (fx_tower_idle)
```
Frames: 4
Duration: 2000ms loop
Visual: Subtle breathing animation
Particles: Occasional ambient (type-specific)
```

#### Tower Overcharged (fx_tower_overcharged)
```
Dimensions: 24x24
Frames: 8
Duration: 800ms loop
Visual: Glowing aura, energy particles
Color: Golden (#f4d03f)
```

#### Tower Disabled (fx_tower_disabled)
```
Dimensions: 16x16
Frames: 4
Duration: 600ms loop
Visual: Sparks, smoke wisps
Color: Gray, red sparks
```

---

### Tower Build Animation

#### Construction Start (fx_construct_start)
```
Dimensions: 24x24
Frames: 4
Duration: 300ms
Visual: Dust cloud, foundation appear
```

#### Construction Progress (fx_construct_progress)
```
Dimensions: 24x32
Frames: 8
Duration: 2000ms
Visual: Scaffold, walls rising, workers implied
```

#### Construction Complete (fx_construct_complete)
```
Dimensions: 32x32
Frames: 6
Duration: 500ms
Visual: Flash, sparkles, dust settle
Sound: Completion fanfare
```

---

### Tower Upgrade Animation

#### Upgrade Flash (fx_upgrade_flash)
```
Dimensions: 32x32
Frames: 8
Duration: 600ms
Visual: Golden spiral, tower transforms
Particles: Stars rise around tower
```

---

## ENEMY EFFECTS

### Enemy Spawn

#### Ground Spawn (fx_spawn_ground)
```
Dimensions: 24x24
Frames: 8
Duration: 800ms
Visual: Dark portal opens, enemy rises
Colors: #4a235a, #7d3c98 (purple)
```

#### Air Spawn (fx_spawn_air)
```
Dimensions: 16x16
Frames: 6
Duration: 500ms
Visual: Shadow on ground, enemy drops in
Colors: #1a252f (shadow)
```

#### Boss Spawn (fx_spawn_boss)
```
Dimensions: 64x64
Frames: 12
Duration: 2000ms
Visual: Ground crack, dramatic entrance
Screen Shake: Yes (medium)
Colors: #e74c3c, #c0392b
```

---

### Enemy Death

#### Standard Death (fx_death_standard)
```
Dimensions: 24x24
Frames: 6
Duration: 400ms
Visual: Flash white, shrink, particle burst
Particles: Enemy-colored fragments
```

#### Elite Death (fx_death_elite)
```
Dimensions: 32x32
Frames: 8
Duration: 600ms
Visual: Glow intensify, explosion, affix particles
Particles: Extra loot sparkles
```

#### Boss Death (fx_death_boss)
```
Dimensions: 64x64
Frames: 12
Duration: 1500ms
Visual: Slow-mo, dramatic flash, massive particle burst
Screen Shake: Yes (large)
Audio: Epic defeat fanfare
Drops: Treasure chest spawn
```

---

### Status Effect Indicators

#### Burning (fx_status_burning)
```
Dimensions: 16x16
Frames: 4
Duration: 400ms loop
Visual: Small flames on enemy
Colors: #e74c3c, #f39c12
Particles: Ember rise
```

#### Frozen (fx_status_frozen)
```
Dimensions: 16x16
Frames: 4
Duration: 600ms loop
Visual: Ice crystals, slow movement
Colors: #3498db, #85c1e9
Enemy tint: Blue overlay
```

#### Poisoned (fx_status_poisoned)
```
Dimensions: 16x16
Frames: 4
Duration: 500ms loop
Visual: Bubble particles rising
Colors: #27ae60, #82e0aa
Enemy tint: Green overlay
```

#### Shocked (fx_status_shocked)
```
Dimensions: 16x16
Frames: 6
Duration: 300ms loop
Visual: Electric arcs around enemy
Colors: #f4d03f, #fdfefe
```

#### Slowed (fx_status_slowed)
```
Dimensions: 16x16
Frames: 4
Duration: 800ms loop
Visual: Clock symbol, trailing afterimages
Colors: #3498db
```

---

## TYPING EFFECTS

### Keystroke Effects

#### Correct Key (fx_key_correct)
```
Dimensions: 16x16
Frames: 4
Duration: 150ms
Visual: Green ripple from key
Colors: #27ae60
Particles: 2-3 green sparkles
```

#### Wrong Key (fx_key_wrong)
```
Dimensions: 16x16
Frames: 4
Duration: 200ms
Visual: Red X, shake
Colors: #e74c3c
Screen: Micro-shake (optional)
```

---

### Word Effects

#### Word Complete (fx_word_complete)
```
Dimensions: 32x32
Frames: 8
Duration: 400ms
Visual: Golden burst, letters scatter outward
Colors: #f4d03f, #27ae60
Particles: 8-12 letter-shaped fragments
```

#### Perfect Word (100% accuracy)
```
Extension of word_complete
Additional: Rainbow flash, extra particles
Bonus text: "PERFECT!" popup
```

#### Word Failed (fx_word_failed)
```
Dimensions: 32x32
Frames: 6
Duration: 400ms
Visual: Red flash, letters fall/crumble
Colors: #e74c3c
```

---

### Combo Effects

#### Combo Increase (fx_combo_up)
```
Dimensions: 48x48
Frames: 6
Duration: 400ms
Visual: Number pops up, glow expands
Colors: Scale from blue to gold to rainbow
```

#### Combo Drop (fx_combo_drop)
```
Dimensions: 48x48
Frames: 6
Duration: 400ms
Visual: Crack effect, number shatters
Colors: #5d6d7e (gray fragments)
```

#### Combo Milestone (x5, x10, x15, x20)
```
Dimensions: 64x64
Frames: 8
Duration: 600ms
Visual: Major burst, screen-wide flash
Colors: Tier-specific (see combo colors)
Screen: Flash overlay
```

---

## ENVIRONMENTAL EFFECTS

### Weather Effects

#### Rain (fx_rain)
```
Dimensions: Full screen overlay
Frames: 8
Duration: 400ms loop
Visual: Diagonal rain lines
Colors: #85c1e9 (30% opacity)
Density: Configurable
```

#### Snow (fx_snow)
```
Dimensions: Full screen overlay
Frames: 6
Duration: 2000ms loop
Visual: Drifting snowflakes
Colors: #fdfefe
Particles: Various sizes, random drift
```

#### Storm (fx_storm)
```
Components: Rain + lightning flashes
Lightning: Random intervals (3-8 seconds)
Screen: Brief white flash
Sound: Thunder rumble
```

#### Fog (fx_fog)
```
Dimensions: Scrolling overlay
Frames: 4
Duration: 4000ms loop
Visual: Drifting mist layers
Colors: #d5d8dc (20% opacity)
```

---

### Ambient Particles

#### Dust Motes (fx_dust)
```
Dimensions: 2x2
Count: 10-20 on screen
Movement: Slow random drift
Colors: #d5d8dc (40% opacity)
```

#### Fireflies (fx_fireflies)
```
Dimensions: 3x3
Count: 5-10 on screen
Movement: Gentle bobbing paths
Colors: #f4d03f (pulsing glow)
```

#### Embers (fx_embers)
```
Dimensions: 3x3
Count: 8-15 on screen
Movement: Rise and drift
Colors: #f39c12, #e74c3c
```

#### Magic Particles (fx_magic)
```
Dimensions: 4x4
Count: 10-15 on screen
Movement: Spiral patterns
Colors: #9b59b6, #d2b4de
```

---

## UI EFFECTS

### Button Feedback

#### Button Press (fx_btn_press)
```
Dimensions: Match button
Frames: 4
Duration: 100ms
Visual: Darken, slight shrink
```

#### Button Hover (fx_btn_hover)
```
Dimensions: Match button
Frames: 4
Duration: 200ms
Visual: Brighten, subtle glow
```

---

### Menu Transitions

#### Screen Fade (fx_screen_fade)
```
Duration: 300ms
Visual: Black overlay fade in/out
```

#### Screen Slide (fx_screen_slide)
```
Duration: 400ms
Visual: Screens slide left/right
Easing: ease-out
```

#### Screen Zoom (fx_screen_zoom)
```
Duration: 500ms
Visual: Scale from/to center
Easing: ease-in-out
```

---

### Notification Effects

#### Toast Enter (fx_toast_enter)
```
Duration: 300ms
Visual: Slide in from right
Easing: ease-out
```

#### Achievement Unlock (fx_achievement)
```
Dimensions: 64x64
Frames: 12
Duration: 800ms
Visual: Golden burst, confetti, glow
Sound: Fanfare
```

---

## CASTLE EFFECTS

### Castle Damage

#### Castle Hit (fx_castle_hit)
```
Dimensions: 32x32
Frames: 6
Duration: 400ms
Visual: Stone debris, flash red
Screen: Flash vignette
```

#### Castle Critical (fx_castle_critical)
```
Dimensions: 48x48
Frames: 8
Duration: 600ms
Visual: Major debris, crack appears
Screen: Red vignette pulses
Audio: Warning alarm
```

---

### Castle Repair

#### Repair Sparkle (fx_castle_repair)
```
Dimensions: 24x24
Frames: 6
Duration: 400ms
Visual: Green sparkles, stone reforms
Colors: #27ae60, #fdfefe
```

---

## REWARD EFFECTS

### Gold Pickup (fx_gold_pickup)
```
Dimensions: 16x16
Frames: 6
Duration: 300ms
Visual: Coin flips, flies to counter
Colors: #f4d03f
Trail: Golden sparkles
```

#### Gold Burst (fx_gold_burst)
```
Dimensions: 32x32
Frames: 8
Duration: 500ms
Visual: Coins scatter from source
Count: 5-10 coin particles
```

---

### Experience Gain

#### XP Orb Pickup (fx_xp_pickup)
```
Dimensions: 12x12
Frames: 4
Duration: 200ms
Visual: Orb flies to XP bar
Colors: #9b59b6, #d2b4de
Trail: Purple sparkles
```

#### Level Up (fx_level_up)
```
Dimensions: Full screen
Frames: 12
Duration: 1000ms
Visual: Light pillar, radial burst
Colors: #f4d03f, #fdfefe
Screen: Flash overlay
Audio: Level up fanfare
```

---

## SPECIAL EFFECTS

### Critical Hit (fx_critical)
```
Dimensions: 48x48
Frames: 8
Duration: 500ms
Visual: Impact star, radial lines
Colors: #f4d03f, #fdfefe
```

### Shield Block (fx_shield_block)
```
Dimensions: 32x32
Frames: 6
Duration: 300ms
Visual: Shield flash, ripple
Colors: #3498db, #aed6f1
```

### Stun Effect (fx_stun)
```
Dimensions: 24x24
Frames: 8
Duration: 800ms loop
Visual: Stars circling head
Colors: #f4d03f
```

### Knockback (fx_knockback)
```
Dimensions: 24x24
Frames: 4
Duration: 200ms
Visual: Speed lines, dust puff
```

---

## EFFECT LAYERING ORDER

```
Layer 0: Background weather (rain, snow)
Layer 1: Ground effects (puddles, fire patches)
Layer 2: Enemy effects (status, spawn)
Layer 3: Tower effects (fire, impact)
Layer 4: Projectiles
Layer 5: Damage numbers, pickups
Layer 6: UI effects (typing feedback)
Layer 7: Screen overlays (flash, vignette)
Layer 8: Foreground weather (fog)
```

---

## PERFORMANCE GUIDELINES

### Particle Limits per Effect
```
Tiny (dust, sparkles):    Max 30
Small (impacts):          Max 20
Medium (explosions):      Max 15
Large (screen effects):   Max 8
```

### Effect Duration Limits
```
Combat effects:           Max 500ms
Ambient effects:          Continuous (low count)
UI effects:               Max 400ms
Screen effects:           Max 1000ms
```

### Memory Optimization
- Reuse particle textures across effects
- Pool particle systems
- Disable off-screen effects
- LOD for distant effects (reduce particles)

