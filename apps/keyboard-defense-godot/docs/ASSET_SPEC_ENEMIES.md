# Enemy Asset Specifications

## Design Philosophy
All enemies follow a consistent visual language:
- **Silhouette Recognition**: Each enemy type must be identifiable by outline alone
- **Color Coding**: Enemy tier/danger indicated by color intensity
- **Animation Clarity**: Movement patterns visible even at small size
- **Hitbox Alignment**: Visual sprite matches gameplay hitbox

---

## BASE ENEMY TEMPLATES

### Standard Enemy Structure (16x24)
```
┌──────────────────────────────────┐
│  Row 1-4: Head/Face (16x4)       │ ← Identity zone
│  Row 5-12: Body/Torso (16x8)     │ ← Color zone
│  Row 13-20: Legs/Base (16x8)     │ ← Movement zone
│  Row 21-24: Shadow (16x4)        │ ← Grounding
└──────────────────────────────────┘
```

### Animation Frame Layout
- **Frame 1**: Neutral/Base pose
- **Frame 2**: Movement forward (lean)
- **Frame 3**: Alternate step
- **Frame 4**: Return to neutral

---

## ENEMY TYPE SPECIFICATIONS

### 1. NECROMANCER (enemy_necromancer)
**Role**: Summoner - spawns minions, stays at range
**Threat Level**: High

**Visual Design**:
- Hooded figure with glowing eyes
- Tattered robes in dark purple (#4a235a)
- Floating skull orb accessory
- Ethereal wisp effects around hands

**Color Palette**:
```
Primary:   #4a235a (Dark Purple)
Secondary: #7d3c98 (Purple)
Accent:    #d7bde2 (Light Purple glow)
Eyes:      #58d68d (Green glow)
```

**Animation States**:
| State | Frames | Duration | Description |
|-------|--------|----------|-------------|
| idle | 4 | 600ms | Robes sway, orb pulses |
| move | 4 | 400ms | Floating glide |
| cast | 6 | 500ms | Raise arms, summon circle |
| death | 6 | 600ms | Dissolve into mist |

**Behavior Indicators**:
- Casting: Purple runes appear at feet
- Low HP: Orb flickers rapidly
- Summoning: Green portal beneath

---

### 2. BERSERKER (enemy_berserker)
**Role**: Melee DPS - fast, enrages at low HP
**Threat Level**: Medium-High

**Visual Design**:
- Muscular humanoid, bare-chested
- War paint in red patterns
- Dual axes or cleavers
- Wild hair/mane

**Color Palette**:
```
Primary:   #7b241c (Dark Red)
Secondary: #c0392b (Red)
Accent:    #f5b7b1 (Skin highlight)
Weapons:   #5d6d7e (Steel)
Rage:      #f4d03f (Yellow-orange glow)
```

**Animation States**:
| State | Frames | Duration | Description |
|-------|--------|----------|-------------|
| idle | 4 | 500ms | Heavy breathing, axes ready |
| move | 4 | 300ms | Aggressive run |
| attack | 6 | 400ms | Overhead cleave |
| enrage | 4 | 400ms | Scream, aura appears |
| death | 6 | 500ms | Dramatic fall |

**Behavior Indicators**:
- Normal: Standard red coloring
- Enraged (<30% HP): Yellow-red aura, faster animation
- Attacking: Weapon raised high

---

### 3. ARCHER (enemy_archer)
**Role**: Ranged DPS - stays back, consistent damage
**Threat Level**: Medium

**Visual Design**:
- Lean figure with hood
- Longbow as tall as character
- Quiver visible on back
- Cloak for mobility feel

**Color Palette**:
```
Primary:   #1e8449 (Forest Green)
Secondary: #27ae60 (Green)
Accent:    #d5f5e3 (Light green)
Bow:       #6e2c00 (Wood brown)
String:    #f4d03f (Gold)
```

**Animation States**:
| State | Frames | Duration | Description |
|-------|--------|----------|-------------|
| idle | 4 | 600ms | Slight sway, bow ready |
| move | 4 | 400ms | Quick sidestep |
| draw | 4 | 400ms | Pull back bowstring |
| fire | 4 | 200ms | Release arrow |
| death | 6 | 500ms | Crumple fall |

**Projectile**: proj_enemy_arrow (8x4)
- Brown shaft with green fletching
- Slight arc trajectory

---

### 4. SHIELD WALL (enemy_shield_wall)
**Role**: Tank - blocks projectiles, slow
**Threat Level**: Medium

**Visual Design**:
- Heavy armored knight
- Tower shield (half body width)
- Helmet with narrow visor
- Thick leg armor

**Color Palette**:
```
Primary:   #5d6d7e (Steel gray)
Secondary: #85929e (Light steel)
Accent:    #2c3e50 (Dark steel)
Shield:    #f4d03f (Gold trim)
Eyes:      #e74c3c (Red glow in visor)
```

**Animation States**:
| State | Frames | Duration | Description |
|-------|--------|----------|-------------|
| idle | 4 | 800ms | Shield raised, minimal movement |
| move | 4 | 600ms | Heavy trudge forward |
| block | 2 | 200ms | Brace shield (reactive) |
| stagger | 4 | 400ms | Shield pushed back |
| death | 8 | 800ms | Armor collapse |

**Behavior Indicators**:
- Blocking: Shield glows briefly on impact
- Shield HP low: Cracks visible on shield
- Shield broken: Shield disappears, faster movement

---

### 5. ASSASSIN (enemy_assassin)
**Role**: Ambusher - invisible, burst damage
**Threat Level**: High

**Visual Design**:
- Sleek, angular silhouette
- Face mask/bandana
- Twin daggers
- Smoke/shadow particles

**Color Palette**:
```
Primary:   #1a252f (Near black)
Secondary: #34495e (Dark gray)
Accent:    #5dade2 (Blue shadow effects)
Blades:    #aeb6bf (Silver)
Eyes:      #f4d03f (Yellow when revealed)
```

**Animation States**:
| State | Frames | Duration | Description |
|-------|--------|----------|-------------|
| stealth | 4 | 400ms | Shimmer/transparency effect |
| reveal | 4 | 300ms | Solidify from shadow |
| move | 4 | 250ms | Quick dash |
| attack | 6 | 350ms | Double slash |
| death | 6 | 400ms | Dissolve to shadow |

**Visual States**:
- Stealthed: 30% opacity, shimmer distortion
- Detected: Yellow eye glow, 60% opacity
- Revealed: Full opacity, aggression pose

---

### 6. GOLEM (enemy_golem)
**Role**: Mini-boss - massive HP, slow, AOE attacks
**Threat Level**: Boss-tier
**Dimensions**: 20x28

**Visual Design**:
- Rock/crystal formation humanoid
- Glowing core in chest (weak point)
- Moss/vines on shoulders
- Ground cracks beneath feet

**Color Palette**:
```
Primary:   #5d6d7e (Stone gray)
Secondary: #85929e (Light stone)
Moss:      #1e8449 (Green)
Core:      #e74c3c (Red glow)
Core Dim:  #922b21 (Damaged core)
```

**Animation States**:
| State | Frames | Duration | Description |
|-------|--------|----------|-------------|
| idle | 4 | 1000ms | Slow breathing, core pulses |
| move | 6 | 800ms | Earthquake steps |
| slam | 8 | 1000ms | Ground pound AOE |
| throw | 6 | 700ms | Boulder toss |
| stagger | 4 | 600ms | Core exposed |
| death | 10 | 1200ms | Crumble to rubble |

**Core Mechanic**:
- Core visible during stagger
- Typing weak point word does bonus damage
- Core color indicates remaining HP

---

### 7. SWARM (enemy_swarm)
**Role**: Fodder - numerous, individually weak
**Threat Level**: Low (individually)
**Dimensions**: 12x12

**Visual Design**:
- Tiny creature (rat, spider, or imp)
- Simple 2-3 color design
- Group spawns in clusters of 3-5
- Share a single word target

**Color Palette**:
```
Primary:   #6e2c00 (Brown)
Secondary: #a04000 (Orange-brown)
Eyes:      #f4d03f (Yellow dots)
```

**Animation States**:
| State | Frames | Duration | Description |
|-------|--------|----------|-------------|
| idle | 2 | 200ms | Jitter in place |
| move | 4 | 200ms | Scurry movement |
| attack | 2 | 150ms | Quick bite/sting |
| death | 4 | 200ms | Pop/splat |

**Spawn Behavior**:
- Appear in groups of 3-5
- Each swarm group = 1 word
- Killing word kills all in group

---

### 8. MIMIC (enemy_mimic)
**Role**: Trap - disguises as pickup, surprises
**Threat Level**: Medium

**Visual Design**:
- Chest/crate when disguised
- Reveals: Chest with teeth, tentacle legs
- Tongue as lure

**Color Palette**:
```
Disguised:
  Primary:   #6e2c00 (Wood brown)
  Secondary: #f4d03f (Gold lock)

Revealed:
  Primary:   #4a235a (Purple-black)
  Secondary: #e74c3c (Red mouth)
  Teeth:     #fdfefe (White)
  Tongue:    #c0392b (Dark red)
```

**Animation States**:
| State | Frames | Duration | Description |
|-------|--------|----------|-------------|
| disguised | 1 | - | Static chest appearance |
| wobble | 4 | 400ms | Subtle movement hint |
| reveal | 6 | 500ms | Chest opens, transforms |
| move | 4 | 350ms | Hop/waddle |
| attack | 4 | 400ms | Tongue lash/bite |
| death | 6 | 500ms | Collapse, gold spill |

---

## ELITE AFFIX OVERLAYS

### Affix System
Elite enemies display one or more affixes as overlay effects.
Affixes are 16x16 transparent PNGs layered over base enemy.

### 1. BLAZING (affix_blazing)
```
Visual: Fire particles rising from enemy
Colors: #e74c3c, #f39c12, #f4d03f
Animation: 4 frames, 300ms loop
Effect: Leaves fire trail, burn damage on hit
```

### 2. FROZEN (affix_frozen)
```
Visual: Ice crystals on shoulders/head
Colors: #3498db, #5dade2, #85c1e9
Animation: 4 frames, 500ms loop (shimmer)
Effect: Slows player typing speed on hit
```

### 3. VAMPIRIC (affix_vampiric)
```
Visual: Blood droplets orbiting enemy
Colors: #922b21, #c0392b, #f5b7b1
Animation: 4 frames, 400ms loop
Effect: Heals on dealing damage
```

### 4. ARCANE (affix_arcane)
```
Visual: Runic symbols rotating around
Colors: #9b59b6, #d2b4de, #f5eef8
Animation: 6 frames, 600ms loop
Effect: Random spell effects on attack
```

### 5. THORNS (affix_thorns)
```
Visual: Spikes protruding from body
Colors: #5d6d7e, #85929e, #aeb6bf
Animation: 2 frames, 400ms (pulse)
Effect: Reflects damage to towers
```

### 6. PHASING (affix_phasing)
```
Visual: Ghost transparency pulse
Colors: #5dade2 (30% opacity waves)
Animation: 4 frames, 500ms loop
Effect: Periodically untargetable
```

---

## ENEMY DEATH EFFECTS

### Standard Death (fx_enemy_death)
```
Frames: 6
Duration: 400ms
Visual: Flash white → shrink → particles disperse
```

### Elite Death (fx_enemy_death_elite)
```
Frames: 8
Duration: 600ms
Visual: Glow intensifies → explosion → affix-colored particles
Drops: Guaranteed loot sparkle
```

### Boss Death (fx_enemy_death_boss)
```
Frames: 12
Duration: 1000ms
Visual: Dramatic slowdown → flash → massive particle burst
Audio: Special death fanfare
Drops: Treasure chest spawn
```

---

## ENEMY HEALTH BAR VARIATIONS

### Standard Enemy
```
Asset: bar_health_enemy (32x4)
Style: Simple red bar
Position: Above head, centered
```

### Elite Enemy
```
Asset: bar_health_elite (40x6)
Style: Red bar with gold border
Affix icons displayed beside bar
```

### Boss Enemy
```
Asset: bar_health_boss (128x12)
Style: Segmented bar (phase markers)
Name text above bar
Position: Top of screen, fixed
```

---

## SPAWN INDICATORS

### Ground Warning (fx_spawn_warning)
```
Dimensions: 24x24
Frames: 6
Duration: 1000ms (before spawn)
Visual: Red circle expanding → portal opens
```

### Air Warning (fx_spawn_air)
```
Dimensions: 16x16
Frames: 4
Duration: 500ms
Visual: Shadow on ground → enemy drops in
```

### Boss Warning (fx_spawn_boss)
```
Dimensions: 64x64
Frames: 8
Duration: 2000ms
Visual: Ground cracks → screen shake → dramatic entrance
```
