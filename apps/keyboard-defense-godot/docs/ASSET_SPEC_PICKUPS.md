# Pickups & Power-ups Asset Specifications

## Design Philosophy
- **Instant Recognition**: Each pickup type identifiable at a glance
- **Value Communication**: Rarity/power shown through visuals
- **Satisfying Collection**: Pickup animations feel rewarding
- **Clear Effects**: Active power-ups clearly visible

---

## PICKUP STANDARDS

### Base Dimensions
```
Small Pickup:    12x12 (common drops)
Standard Pickup: 16x16 (most pickups)
Large Pickup:    20x20 (rare/special)
Chest:           24x24 (loot containers)
```

### Animation Standards
```
Idle:     4 frames, 800ms loop (gentle bob/glow)
Spawn:    4 frames, 300ms (appear effect)
Collect:  6 frames, 400ms (fly to HUD)
Expire:   4 frames, 500ms (fade warning)
```

---

## CURRENCY PICKUPS

### Gold Coin (pickup_gold)
**Dimensions**: 12x12
**Frames**: 4 (spin)
**Duration**: 400ms loop

**Visual Design**:
- Classic coin shape
- Raised emblem (crown/castle)
- Metallic shine animation

**Color Palette**:
```
Main:       #f4d03f
Shadow:     #d4ac0d
Highlight:  #fdfefe
Emblem:     #b7950b
```

**Variants by Value**:
| Variant | Value | Visual |
|---------|-------|--------|
| gold_small | 1 | Single small coin |
| gold_medium | 5 | Larger coin |
| gold_large | 25 | Shiny large coin |
| gold_pile | 100 | Stack of coins |

---

### Gem (pickup_gem)
**Dimensions**: 14x14
**Frames**: 4 (sparkle)
**Duration**: 600ms loop

**Visual Design**:
- Faceted crystal
- Internal glow
- Sparkle particles

**Color Variants**:
| Type | Color | Value |
|------|-------|-------|
| gem_red | #e74c3c | Common |
| gem_blue | #3498db | Uncommon |
| gem_green | #27ae60 | Rare |
| gem_purple | #9b59b6 | Epic |
| gem_gold | #f4d03f | Legendary |

---

## HEALTH PICKUPS

### Health Orb (pickup_health)
**Dimensions**: 16x16
**Frames**: 4 (pulse)
**Duration**: 600ms loop

**Visual Design**:
- Glowing heart shape
- Red energy core
- Healing particles

**Color Palette**:
```
Core:       #e74c3c
Glow:       #f5b7b1
Particles:  #27ae60
Pulse:      #fdfefe
```

**Variants**:
| Variant | Heal | Size |
|---------|------|------|
| health_small | 10% | 12x12 |
| health_medium | 25% | 16x16 |
| health_large | 50% | 20x20 |
| health_full | 100% | 24x24 |

---

### Health Potion (pickup_potion_health)
**Dimensions**: 12x16
**Frames**: 2 (liquid slosh)
**Duration**: 800ms loop

**Visual Design**:
- Glass bottle
- Red liquid
- Cork stopper
- Bubble animation

**Color Palette**:
```
Glass:      #aeb6bf (transparent effect)
Liquid:     #e74c3c
Cork:       #6e2c00
Bubbles:    #f5b7b1
```

---

## MANA/ENERGY PICKUPS

### Mana Orb (pickup_mana)
**Dimensions**: 16x16
**Frames**: 4 (swirl)
**Duration**: 600ms loop

**Visual Design**:
- Blue energy sphere
- Internal swirl
- Magical particles

**Color Palette**:
```
Core:       #3498db
Swirl:      #5dade2
Particles:  #aed6f1
Glow:       #d6eaf8
```

---

### Mana Potion (pickup_potion_mana)
**Dimensions**: 12x16
**Frames**: 2
**Duration**: 800ms loop

**Visual Design**:
- Glass bottle
- Blue glowing liquid
- Magical runes on bottle

**Color Palette**:
```
Glass:      #aeb6bf
Liquid:     #3498db
Runes:      #5dade2
Cork:       #6e2c00
```

---

## POWER-UPS

### Speed Boost (pickup_speed)
**Dimensions**: 16x16
**Frames**: 6 (motion lines)
**Duration**: 400ms loop

**Visual Design**:
- Lightning bolt shape
- Motion blur lines
- Energy trail

**Color Palette**:
```
Bolt:       #f4d03f
Lines:      #f39c12
Energy:     #fdfefe
```

**Effect Duration**: 10 seconds
**Effect**: +50% typing speed bonus

---

### Shield (pickup_shield)
**Dimensions**: 16x16
**Frames**: 4 (glow pulse)
**Duration**: 600ms loop

**Visual Design**:
- Shield shape
- Protective aura
- Defensive runes

**Color Palette**:
```
Shield:     #3498db
Aura:       #aed6f1
Runes:      #fdfefe
```

**Effect Duration**: 15 seconds
**Effect**: Block next 3 hits

---

### Damage Boost (pickup_damage)
**Dimensions**: 16x16
**Frames**: 4 (flame pulse)
**Duration**: 500ms loop

**Visual Design**:
- Sword/power icon
- Fire aura
- Aggressive energy

**Color Palette**:
```
Icon:       #e74c3c
Fire:       #f39c12, #f4d03f
Energy:     #fdfefe
```

**Effect Duration**: 10 seconds
**Effect**: +100% tower damage

---

### Freeze Bomb (pickup_freeze)
**Dimensions**: 16x16
**Frames**: 4 (frost particles)
**Duration**: 600ms loop

**Visual Design**:
- Ice crystal bomb
- Frost emanating
- Cold mist

**Color Palette**:
```
Crystal:    #85c1e9
Frost:      #d6eaf8
Mist:       #fdfefe
```

**Effect**: Freeze all enemies for 5 seconds

---

### Fire Storm (pickup_firestorm)
**Dimensions**: 18x18
**Frames**: 6 (flames)
**Duration**: 400ms loop

**Visual Design**:
- Flame orb
- Spiraling fire
- Ember particles

**Color Palette**:
```
Core:       #fdfefe
Inner:      #f4d03f
Outer:      #e74c3c
Embers:     #f39c12
```

**Effect**: Deal AOE damage to all enemies

---

### Double Points (pickup_double)
**Dimensions**: 16x16
**Frames**: 4 (number pulse)
**Duration**: 500ms loop

**Visual Design**:
- "x2" text
- Golden glow
- Sparkle effect

**Color Palette**:
```
Text:       #f4d03f
Glow:       #f9e79f
Sparkle:    #fdfefe
```

**Effect Duration**: 20 seconds
**Effect**: Double all point gains

---

### Combo Extender (pickup_combo)
**Dimensions**: 16x16
**Frames**: 4 (chain pulse)
**Duration**: 500ms loop

**Visual Design**:
- Chain link icon
- Energy connecting
- Timer extension visual

**Color Palette**:
```
Chain:      #f4d03f
Links:      #d4ac0d
Energy:     #fdfefe
```

**Effect**: +5 seconds to combo timer

---

### Word Clear (pickup_clear)
**Dimensions**: 18x18
**Frames**: 6 (explosion)
**Duration**: 500ms loop

**Visual Design**:
- Burst icon
- Radiating energy
- Letter particles

**Color Palette**:
```
Center:     #fdfefe
Burst:      #9b59b6
Letters:    #d2b4de
```

**Effect**: Instantly complete current word

---

### Multi-Target (pickup_multi)
**Dimensions**: 16x16
**Frames**: 4 (arrows)
**Duration**: 400ms loop

**Visual Design**:
- Multiple arrow icon
- Splitting effect
- Target indicators

**Color Palette**:
```
Arrows:     #27ae60
Targets:    #2ecc71
Glow:       #d5f5e3
```

**Effect Duration**: 15 seconds
**Effect**: Each word hits multiple enemies

---

## SPECIAL PICKUPS

### Key (pickup_key)
**Dimensions**: 14x14
**Frames**: 4 (shine)
**Duration**: 800ms loop

**Visual Design**:
- Ornate key shape
- Metallic shine
- Magical glow for special keys

**Variants**:
| Type | Color | Use |
|------|-------|-----|
| key_bronze | #cd6155 | Common chests |
| key_silver | #85929e | Uncommon chests |
| key_gold | #f4d03f | Rare chests |
| key_crystal | #9b59b6 | Special chests |

---

### Star (pickup_star)
**Dimensions**: 16x16
**Frames**: 6 (twinkle)
**Duration**: 600ms loop

**Visual Design**:
- Five-point star
- Bright core
- Sparkle rays

**Color Palette**:
```
Core:       #fdfefe
Body:       #f4d03f
Rays:       #f9e79f
```

**Use**: Level completion rating, achievements

---

### Mystery Box (pickup_mystery)
**Dimensions**: 18x18
**Frames**: 4 (shake/glow)
**Duration**: 600ms loop

**Visual Design**:
- Gift box with "?"
- Rainbow shimmer
- Unknown contents implied

**Color Palette**:
```
Box:        #9b59b6
Ribbon:     #f4d03f
Question:   #fdfefe
Shimmer:    Rainbow gradient
```

**Effect**: Random power-up on collect

---

## LOOT CONTAINERS

### Chest - Common (chest_common)
**Dimensions**: 24x20
**Frames**: 8 (open sequence)
**Duration**: 600ms (one-shot)

**Visual Design**:
- Wooden chest
- Simple metal bands
- Basic lock

**Color Palette**:
```
Wood:       #6e2c00
Bands:      #5d6d7e
Lock:       #85929e
```

**Contents**: 1-3 common drops

---

### Chest - Uncommon (chest_uncommon)
**Dimensions**: 24x20
**Frames**: 8

**Visual Design**:
- Reinforced chest
- Silver bands
- Better lock

**Color Palette**:
```
Wood:       #6e2c00
Bands:      #85929e
Lock:       #aeb6bf
Accent:     #3498db
```

**Contents**: 2-4 drops, uncommon chance

---

### Chest - Rare (chest_rare)
**Dimensions**: 26x22
**Frames**: 10

**Visual Design**:
- Ornate chest
- Gold decorations
- Magical glow

**Color Palette**:
```
Body:       #34495e
Gold:       #f4d03f
Glow:       #aed6f1
Gems:       #e74c3c, #3498db
```

**Contents**: 3-5 drops, rare guaranteed

---

### Chest - Epic (chest_epic)
**Dimensions**: 28x24
**Frames**: 12

**Visual Design**:
- Magical chest
- Floating particles
- Pulsing aura

**Color Palette**:
```
Body:       #4a235a
Trim:       #f4d03f
Aura:       #9b59b6
Particles:  #d2b4de
```

**Contents**: 4-6 drops, epic chance

---

### Chest - Legendary (chest_legendary)
**Dimensions**: 32x28
**Frames**: 16

**Visual Design**:
- Legendary artifact chest
- Intense magical effects
- Unique design

**Color Palette**:
```
Body:       #f4d03f, #d4ac0d
Glow:       #fdfefe
Magic:      Rainbow shimmer
Particles:  Prismatic
```

**Contents**: 5+ drops, legendary guaranteed

---

### Boss Loot (chest_boss)
**Dimensions**: 32x32
**Frames**: 16

**Visual Design**:
- Unique per boss
- Trophy elements
- Victory spoils

**Contents**: Boss-specific rewards

---

## PICKUP EFFECTS

### Spawn Effect (fx_pickup_spawn)
```
Dimensions: 24x24
Frames: 6
Duration: 300ms
Visual: Burst from source, sparkle settle
```

### Collect Effect (fx_pickup_collect)
```
Dimensions: 20x20
Frames: 8
Duration: 400ms
Visual: Swirl into player, flash
```

### Magnet Effect (fx_pickup_magnet)
```
Dimensions: Variable
Frames: Continuous
Duration: While active
Visual: Trail from pickup to player
```

### Expire Warning (fx_pickup_expire)
```
Dimensions: Match pickup
Frames: 4
Duration: 500ms loop
Visual: Flashing, fading
Trigger: 3 seconds before despawn
```

---

## ACTIVE EFFECT INDICATORS

### Speed Boost Active (indicator_speed)
**Dimensions**: 16x16
**Position**: HUD status area

**Visual**: Lightning icon with timer

---

### Shield Active (indicator_shield)
**Dimensions**: 16x16

**Visual**: Shield icon with hit counter

---

### Damage Boost Active (indicator_damage)
**Dimensions**: 16x16

**Visual**: Sword icon with timer

---

### Double Points Active (indicator_double)
**Dimensions**: 16x16

**Visual**: x2 icon with timer

---

## PICKUP BEHAVIOR

### Spawn Conditions
```
Enemy Death:     70% chance of drop
Elite Death:     100% chance, better quality
Boss Death:      Guaranteed chest + extras
Wave Complete:   Bonus pickups spawn
Typing Streak:   Combo milestones drop rewards
```

### Attraction Range
```
No Magnet:       Must walk over (8px)
Magnet Power-up: 64px attraction radius
Permanent Magnet: 32px (upgrade)
```

### Despawn Timing
```
Common Pickup:   15 seconds
Rare Pickup:     30 seconds
Power-up:        20 seconds
Currency:        30 seconds
Warning Start:   5 seconds before despawn
```

---

## RARITY VISUAL LANGUAGE

### Common (Gray border)
```
No special effects
Simple animation
Basic colors
```

### Uncommon (Green border)
```
Slight glow
Sparkle occasionally
Enhanced colors
```

### Rare (Blue border)
```
Constant glow
Regular sparkles
Saturated colors
Subtle particles
```

### Epic (Purple border)
```
Strong glow
Frequent sparkles
Vibrant colors
Particle trail
```

### Legendary (Gold border)
```
Intense glow
Constant sparkles
Premium colors
Heavy particles
Unique sound
```

---

## DROP TABLES

### Standard Enemy Drops
```
Nothing:        30%
Gold (small):   40%
Gold (medium):  15%
Health (small): 10%
Power-up:       5%
```

### Elite Enemy Drops
```
Gold (medium):  40%
Gold (large):   25%
Health (medium):15%
Power-up:       15%
Rare item:      5%
```

### Boss Drops
```
Gold (pile):    100%
Health (large): 50%
Power-up (2-3): 100%
Rare item:      75%
Epic item:      25%
Legendary:      5%
Unique boss drop: 100%
```

---

## ASSET CHECKLIST

### Per Pickup Type
- [ ] Idle animation (4+ frames)
- [ ] Spawn effect
- [ ] Collect effect
- [ ] Audio defined
- [ ] Rarity variants (if applicable)
- [ ] Active indicator (for power-ups)
- [ ] Expire warning
- [ ] Added to manifest

### Per Container
- [ ] Closed state
- [ ] Opening animation
- [ ] Open state (empty)
- [ ] Loot spawn effect
- [ ] Rarity visual differences
- [ ] Audio (open, loot)

