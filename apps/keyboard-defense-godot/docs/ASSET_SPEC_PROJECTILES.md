# Projectile Asset Specifications

## Design Philosophy
- **Instant Recognition**: Projectile type identifiable in motion
- **Trajectory Clarity**: Path visible without obscuring gameplay
- **Impact Satisfaction**: Hit feedback feels impactful
- **Performance**: Lightweight sprites for many simultaneous projectiles

---

## PROJECTILE STANDARDS

### Base Dimensions
```
Small:    4x4   (arrows, bolts)
Medium:   8x8   (fireballs, ice shards)
Large:    12x12 (cannon balls, boulders)
Massive:  16x16 (siege projectiles, boss attacks)
```

### Animation Structure
```
Each projectile sprite sheet:
- Frame 1-4: Flight animation (looping)
- Separate asset: Impact effect
- Optional: Charge/launch effect
```

---

## TOWER PROJECTILES

### Arrow (proj_arrow)
**Dimensions**: 8x4
**Frames**: 2 (rotation blur)
**Duration**: 100ms loop

**Visual Design**:
- Brown wooden shaft
- Gray metal tip
- Feather fletching

**Color Palette**:
```
Shaft:      #6e2c00
Tip:        #5d6d7e
Fletching:  #85929e
```

**Motion**: Straight line, slight arc for long range
**Trail**: proj_trail_arrow (faint gray streak)

---

### Arrow Tier 2 (proj_arrow_t2)
**Dimensions**: 10x4
**Frames**: 2

**Enhancements**:
- Reinforced steel tip
- Longer shaft
- Blue fletching

**Color Palette**:
```
Shaft:      #6e2c00
Tip:        #34495e (darker steel)
Fletching:  #3498db
```

---

### Arrow Tier 3 - Ballista Bolt (proj_ballista)
**Dimensions**: 16x6
**Frames**: 2

**Visual Design**:
- Massive siege bolt
- Metal reinforced
- Stabilizer fins

**Color Palette**:
```
Shaft:      #5d6d7e
Tip:        #2c3e50
Fins:       #34495e
Glow:       #f4d03f (enchanted)
```

**Special**: Screen shake on impact

---

### Cannonball (proj_cannonball)
**Dimensions**: 8x8
**Frames**: 4 (spin)
**Duration**: 200ms loop

**Visual Design**:
- Iron sphere
- Highlight/shadow for 3D feel
- Smoke trail

**Color Palette**:
```
Main:       #2c3e50
Highlight:  #5d6d7e
Shadow:     #1a252f
```

**Motion**: Arcing trajectory
**Trail**: proj_trail_smoke

---

### Cannonball Tier 2 (proj_cannonball_t2)
**Dimensions**: 10x10
**Frames**: 4

**Enhancements**:
- Larger caliber
- Glowing hot (red tint)
- Heavier smoke

**Color Palette**:
```
Main:       #2c3e50
Hot Glow:   #e74c3c
Smoke:      #5d6d7e
```

---

### Cannonball Tier 3 - Siege Shell (proj_siege_shell)
**Dimensions**: 14x14
**Frames**: 4

**Visual Design**:
- Explosive shell
- Fuse visible (sparking)
- Brass bands

**Color Palette**:
```
Shell:      #2c3e50
Bands:      #d4ac0d
Fuse:       #f39c12, #e74c3c (spark)
```

**Special**: Explosion effect on impact, AOE damage indicator

---

### Fireball (proj_fireball)
**Dimensions**: 10x10
**Frames**: 6
**Duration**: 300ms loop

**Visual Design**:
- Core flame (bright)
- Outer flames (darker)
- Ember particles trailing

**Color Palette**:
```
Core:       #f4d03f, #fdfefe
Outer:      #f39c12, #e74c3c
Embers:     #f39c12
```

**Trail**: proj_trail_fire (flame particles)

---

### Fireball Tier 2 - Inferno Bolt (proj_inferno)
**Dimensions**: 12x12
**Frames**: 6

**Enhancements**:
- Larger, more intense
- Blue-white core
- Spiral flame pattern

**Color Palette**:
```
Core:       #fdfefe
Inner:      #f4d03f
Outer:      #e74c3c
Spiral:     #f39c12
```

---

### Fireball Tier 3 - Phoenix Flame (proj_phoenix)
**Dimensions**: 16x16
**Frames**: 8

**Visual Design**:
- Phoenix-shaped flame
- Wings spread in flight
- Intense heat distortion

**Color Palette**:
```
Body:       #f4d03f
Wings:      #f39c12, #e74c3c
Eyes:       #fdfefe
Trail:      #e74c3c (feather particles)
```

---

### Ice Shard (proj_ice_shard)
**Dimensions**: 8x8
**Frames**: 4 (shimmer)
**Duration**: 200ms loop

**Visual Design**:
- Crystalline structure
- Faceted surfaces
- Cold mist trailing

**Color Palette**:
```
Crystal:    #85c1e9
Facets:     #3498db, #d6eaf8
Highlight:  #fdfefe
```

**Trail**: proj_trail_frost (ice particles)

---

### Ice Shard Tier 2 - Frost Spike (proj_frost_spike)
**Dimensions**: 10x10
**Frames**: 4

**Enhancements**:
- Larger crystal
- Multiple points
- Freezing aura

**Color Palette**:
```
Crystal:    #3498db
Points:     #85c1e9
Aura:       #d6eaf8 (20% opacity)
```

---

### Ice Shard Tier 3 - Blizzard Core (proj_blizzard)
**Dimensions**: 14x14
**Frames**: 6

**Visual Design**:
- Rotating ice cluster
- Snowflake pattern
- Freeze-on-contact visual

**Color Palette**:
```
Core:       #fdfefe
Crystals:   #85c1e9, #3498db
Snowflakes: #d6eaf8
```

**Special**: AOE freeze indicator

---

### Lightning Bolt (proj_lightning)
**Dimensions**: Variable (procedural)
**Frames**: 6
**Duration**: 150ms (fast)

**Visual Design**:
- Jagged electric arc
- Branching patterns
- Bright core, fading edges

**Color Palette**:
```
Core:       #fdfefe
Arc:        #f4d03f
Branches:   #aed6f1
Glow:       #f4d03f (bloom)
```

**Motion**: Instant hit (no travel time)
**Special**: Chain to nearby enemies

---

### Lightning Tier 2 - Storm Arc (proj_storm_arc)
**Dimensions**: Variable
**Frames**: 8

**Enhancements**:
- Thicker main arc
- More branches
- Lingering sparks

---

### Lightning Tier 3 - Tesla Discharge (proj_tesla)
**Dimensions**: Variable
**Frames**: 10

**Visual Design**:
- Multiple simultaneous arcs
- Sphere of electricity
- Ground scorch marks

**Special**: Hits multiple targets simultaneously

---

### Poison Glob (proj_poison_glob)
**Dimensions**: 8x8
**Frames**: 4 (wobble)
**Duration**: 200ms loop

**Visual Design**:
- Gelatinous blob
- Bubble texture
- Dripping particles

**Color Palette**:
```
Main:       #27ae60
Bubbles:    #82e0aa, #d5f5e3
Drips:      #1e8449
```

**Trail**: proj_trail_drip (poison drops)

---

### Poison Tier 2 - Toxic Spray (proj_toxic_spray)
**Dimensions**: 12x8 (wide spray)
**Frames**: 4

**Visual Design**:
- Cone-shaped spray
- Multiple droplets
- Mist effect

**Color Palette**:
```
Spray:      #27ae60, #2ecc71
Mist:       #82e0aa (30% opacity)
```

---

### Poison Tier 3 - Plague Cloud (proj_plague)
**Dimensions**: 20x20
**Frames**: 6

**Visual Design**:
- Expanding toxic cloud
- Skull shapes in mist
- Corrosive edges

**Color Palette**:
```
Cloud:      #27ae60 (50% opacity)
Skull:      #145a32
Edges:      #82e0aa
```

**Special**: Persistent AOE, DOT indicator

---

### Support Beam (proj_support_beam)
**Dimensions**: Variable length × 4 width
**Frames**: 4 (pulse)
**Duration**: 400ms loop

**Visual Design**:
- Golden healing beam
- Sparkle particles
- Connects tower to target

**Color Palette**:
```
Beam:       #f4d03f (60% opacity)
Core:       #fdfefe
Sparkles:   #f9e79f
```

---

### Support Tier 2 - Aura Pulse (proj_aura_pulse)
**Dimensions**: 32x32 (expanding ring)
**Frames**: 6

**Visual Design**:
- Circular expansion
- Buff symbols
- Fading edge

---

### Support Tier 3 - Command Wave (proj_command_wave)
**Dimensions**: 48x48
**Frames**: 8

**Visual Design**:
- Multiple buff rings
- Tower-to-ally connections
- Royal banner particles

---

## ENEMY PROJECTILES

### Enemy Arrow (proj_enemy_arrow)
**Dimensions**: 8x4
**Frames**: 2

**Visual Design**:
- Crude construction
- Dark coloring
- Jagged tip

**Color Palette**:
```
Shaft:      #4a1c00
Tip:        #2c3e50
Fletching:  #922b21
```

---

### Enemy Fireball (proj_enemy_fire)
**Dimensions**: 10x10
**Frames**: 6

**Visual Design**:
- Sickly green-orange fire
- Corrupted appearance
- Dark core

**Color Palette**:
```
Core:       #5d6d7e
Flames:     #e74c3c, #f39c12
Corruption: #27ae60 (highlights)
```

---

### Enemy Magic Bolt (proj_enemy_magic)
**Dimensions**: 8x8
**Frames**: 4

**Visual Design**:
- Purple energy sphere
- Spinning runes
- Shadow trail

**Color Palette**:
```
Core:       #9b59b6
Runes:      #d2b4de
Shadow:     #4a235a
```

---

### Boss Projectile - Tyrant's Blade (proj_boss_blade)
**Dimensions**: 16x8
**Frames**: 4

**Visual Design**:
- Flying sword
- Red energy glow
- Spin attack

**Color Palette**:
```
Blade:      #5d6d7e
Edge:       #fdfefe
Glow:       #e74c3c
```

---

### Boss Projectile - Witch Skull (proj_boss_skull)
**Dimensions**: 12x12
**Frames**: 6

**Visual Design**:
- Screaming skull
- Green flame eyes
- Soul trail

**Color Palette**:
```
Bone:       #fdfefe, #d5d8dc
Eyes:       #27ae60
Flames:     #2ecc71, #82e0aa
```

---

### Boss Projectile - Dragon Fire (proj_boss_dragon)
**Dimensions**: 24x12
**Frames**: 8

**Visual Design**:
- Stream of dragon fire
- Blue-white core (hotter)
- Massive destruction

**Color Palette**:
```
Core:       #85c1e9 (blue-hot)
Middle:     #fdfefe
Outer:      #f4d03f, #f39c12, #e74c3c
```

---

## PROJECTILE TRAILS

### Arrow Trail (proj_trail_arrow)
```
Dimensions: 4x2
Frames: 3
Duration: 150ms
Visual: Gray streak, quick fade
Spawn Rate: Every 2px movement
```

### Smoke Trail (proj_trail_smoke)
```
Dimensions: 8x8
Frames: 4
Duration: 400ms
Visual: Puff expands and fades
Color: #5d6d7e → transparent
Spawn Rate: Every 4px movement
```

### Fire Trail (proj_trail_fire)
```
Dimensions: 6x6
Frames: 4
Duration: 300ms
Visual: Ember particles, fade to smoke
Colors: #f39c12 → #5d6d7e
Spawn Rate: Every 3px movement
```

### Frost Trail (proj_trail_frost)
```
Dimensions: 6x6
Frames: 4
Duration: 350ms
Visual: Ice crystals shatter
Colors: #85c1e9 → transparent
Spawn Rate: Every 4px movement
```

### Electric Trail (proj_trail_electric)
```
Dimensions: 4x4
Frames: 3
Duration: 100ms
Visual: Spark flashes
Color: #f4d03f
Spawn Rate: Random along path
```

### Poison Trail (proj_trail_drip)
```
Dimensions: 4x6
Frames: 4
Duration: 400ms
Visual: Drop falls, splat
Colors: #27ae60
Spawn Rate: Every 6px movement
Leaves: Ground puddle (temporary)
```

### Magic Trail (proj_trail_magic)
```
Dimensions: 6x6
Frames: 4
Duration: 300ms
Visual: Sparkle burst
Colors: #9b59b6, #d2b4de
Spawn Rate: Every 4px movement
```

---

## IMPACT EFFECTS

### Arrow Impact (fx_impact_arrow)
```
Dimensions: 16x16
Frames: 4
Duration: 200ms
Visual: Arrow sticks, wood splinters fly
```

### Explosion Impact (fx_impact_explosion)
```
Dimensions: 32x32
Frames: 8
Duration: 400ms
Visual: Fire burst, debris, smoke ring
Screen Shake: Small
```

### Fire Impact (fx_impact_fire)
```
Dimensions: 24x24
Frames: 6
Duration: 350ms
Visual: Flame burst, embers scatter
Ground Effect: Fire patch (temporary)
```

### Ice Impact (fx_impact_ice)
```
Dimensions: 24x24
Frames: 6
Duration: 300ms
Visual: Crystal shatter, freeze flash
Ground Effect: Ice patch (temporary)
```

### Lightning Impact (fx_impact_lightning)
```
Dimensions: 20x20
Frames: 4
Duration: 150ms
Visual: Electric burst, ground scorch
```

### Poison Impact (fx_impact_poison)
```
Dimensions: 24x24
Frames: 6
Duration: 400ms
Visual: Splash, bubbles rise
Ground Effect: Poison pool (temporary)
```

### Support Impact (fx_impact_support)
```
Dimensions: 24x24
Frames: 6
Duration: 400ms
Visual: Golden sparkle burst, heal particles rise
```

---

## SPECIAL PROJECTILES

### Homing Missile (proj_homing)
**Dimensions**: 8x8
**Frames**: 4

**Visual Design**:
- Magical orb
- Target-seeking trail
- Color matches damage type

**Behavior**: Curves toward target

---

### Piercing Shot (proj_pierce)
**Dimensions**: 12x4
**Frames**: 2

**Visual Design**:
- Elongated bolt
- Energy core
- Continues through enemies

**Special**: No impact until final target

---

### Bouncing Shot (proj_bounce)
**Dimensions**: 8x8
**Frames**: 4

**Visual Design**:
- Spherical
- Runic markings
- Glows on bounce

**Special**: Impact effect on each bounce

---

### Explosive Shot (proj_explosive)
**Dimensions**: 10x10
**Frames**: 4

**Visual Design**:
- Bomb shape
- Lit fuse
- Warning glow before impact

**Special**: AOE indicator on ground

---

### Chain Shot (proj_chain)
**Dimensions**: 6x6
**Frames**: 4

**Visual Design**:
- Energy orb
- Connection beam to next target
- Diminishes with each chain

---

## PROJECTILE STATES

### Standard Flight
```
Animation: Looping flight frames
Rotation: Faces direction of travel
Speed: Type-dependent
```

### Charged/Empowered
```
Visual: Glowing aura added
Size: +20% scale
Trail: Enhanced particles
Color: Brighter/more saturated
```

### Critical Hit
```
Visual: Gold outline
Trail: Star particles
Impact: Enhanced explosion
Text: "CRIT!" popup
```

### Weakened
```
Visual: Faded colors
Size: -10% scale
Trail: Reduced particles
Impact: Smaller effect
```

---

## PROJECTILE BEHAVIORS

### Straight Line
```
Motion: Direct A to B
Used By: Arrows, bolts, beams
Speed: Fast
```

### Arc/Parabola
```
Motion: Curved trajectory
Used By: Cannonballs, thrown objects
Speed: Medium
Gravity: Simulated
```

### Homing
```
Motion: Curves toward target
Used By: Magic missiles, tracking shots
Speed: Medium
Turn Rate: Configurable
```

### Instant
```
Motion: No travel time
Used By: Lightning, beams
Visual: Line from source to target
```

### Spiral
```
Motion: Rotating path
Used By: Special attacks
Speed: Slow-medium
Visual: Interesting but readable
```

---

## PERFORMANCE GUIDELINES

### Projectile Limits
```
On Screen Maximum: 50 projectiles
Per Tower/Second: 2-4 projectiles
Trail Particles: Max 5 per projectile
Impact Particles: Max 15 per explosion
```

### Optimization
- Pool projectile objects
- Simple collision shapes
- LOD for distant projectiles
- Cull off-screen immediately
- Combine trail particles where possible

### Priority Rendering
```
1. Player's projectiles (always visible)
2. Enemy projectiles (always visible)
3. Projectile trails (can reduce)
4. Impact effects (can queue)
```

---

## SOUND DESIGN NOTES

### Launch Sounds
| Projectile | Sound Character |
|------------|-----------------|
| Arrow | Twang, whoosh |
| Cannonball | Boom, rumble |
| Fireball | Woosh, crackle |
| Ice | Crystalline chime |
| Lightning | Zap, crackle |
| Poison | Splurt, bubble |

### Impact Sounds
| Projectile | Sound Character |
|------------|-----------------|
| Arrow | Thunk |
| Cannonball | Explosion |
| Fireball | Burst, sizzle |
| Ice | Shatter, freeze |
| Lightning | Thunder crack |
| Poison | Splat, hiss |

---

## ASSET CHECKLIST

### Per Projectile Type
- [ ] Flight animation (4-8 frames)
- [ ] Trail effect
- [ ] Impact effect
- [ ] Launch effect (optional)
- [ ] Charged variant (if applicable)
- [ ] Sound effects defined
- [ ] Added to manifest

### Per Tier
- [ ] T1 base projectile
- [ ] T2 enhanced projectile
- [ ] T3 ultimate projectile
- [ ] Visual progression clear

