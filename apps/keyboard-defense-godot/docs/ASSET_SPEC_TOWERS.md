# Tower Asset Specifications

## Design Philosophy
- **Silhouette Clarity**: Each tower type identifiable at a glance
- **Upgrade Progression**: Visual complexity increases with tier
- **State Communication**: Active/idle/disabled clearly shown
- **Attack Animation**: Firing state visible and satisfying

---

## TOWER TIER SYSTEM

### Visual Tier Progression
```
Tier 1: Simple structure, basic colors, minimal detail
Tier 2: Enhanced structure, added elements, richer colors
Tier 3: Complex design, special effects, premium appearance
```

### Size Standards
```
Base Footprint: 16x16 (1 tile)
Tower Height: 16x24 (base + structure)
With Effects: May extend to 20x28
```

---

## ARROW TOWER LINE

### Arrow Tower T1 (tower_arrow)
**Current/Base Design**

**Visual Elements**:
- Stone base (4px height)
- Wooden frame (8px height)
- Arrow slot opening
- Simple flag

**Color Palette**:
```
Stone Base:  #5d6d7e, #85929e
Wood Frame:  #6e2c00, #a04000
Metal Parts: #2c3e50, #34495e
Flag:        #3498db
```

---

### Arrow Tower T2 (tower_arrow_t2)
**Upgraded Design**

**Visual Elements**:
- Reinforced stone base
- Metal-banded frame
- Dual arrow slots
- Larger flag with emblem
- Covered archer platform

**Color Palette**:
```
Stone Base:  #5d6d7e, #85929e
Wood Frame:  #6e2c00, #a04000 (darker)
Metal Bands: #34495e, #2c3e50
Flag:        #2980b9 (richer blue)
Emblem:      #f4d03f (gold)
```

**New Visual Features**:
- Metal corner reinforcements
- Arrow quiver visible
- Slight height increase

---

### Arrow Tower T3 (tower_arrow_t3)
**Maximum Upgrade - Ballista Tower**

**Visual Elements**:
- Full stone construction
- Mounted ballista weapon
- Mechanical components visible
- Royal banner
- Ammunition rack

**Color Palette**:
```
Stone:       #85929e, #aeb6bf
Ballista:    #6e2c00, #a04000
Metal:       #5d6d7e, #85929e
Gold Trim:   #f4d03f, #d4ac0d
Banner:      #1a5276 (deep blue)
```

**Animation**:
- Ballista rotates toward target
- Reload mechanism visible
- Larger projectile effect

---

## CANNON TOWER LINE

### Cannon Tower T1 (tower_cannon)
**Current/Base Design**

**Visual Elements**:
- Heavy stone fortification
- Single cannon barrel
- Cannon balls stacked
- Smoke vent

---

### Cannon Tower T2 (tower_cannon_t2)
**Upgraded Design**

**Visual Elements**:
- Reinforced walls
- Twin cannon barrels
- Larger ammunition storage
- Metal plating
- Steam/smoke effects

**Color Palette**:
```
Stone:       #5d6d7e, #85929e
Metal:       #2c3e50, #1a252f
Cannon:      #34495e, #5d6d7e
Brass:       #b7950b, #d4ac0d
Fire Glow:   #e74c3c, #f39c12
```

---

### Cannon Tower T3 (tower_cannon_t3)
**Maximum Upgrade - Siege Cannon**

**Visual Elements**:
- Massive fortified position
- Oversized siege cannon
- Ammunition conveyor
- Multiple operators implied
- Fortress-like appearance

**Color Palette**:
```
Stone:       #85929e, #aeb6bf (white stone)
Metal:       #2c3e50, #1a252f
Siege Gun:   #1a252f (black steel)
Brass Trim:  #f4d03f, #d4ac0d
Fire Effect: #e74c3c, #f39c12, #f4d03f
```

**Special Effects**:
- Ground shake on fire
- Larger explosion radius
- Smoke cloud lingers

---

## FIRE TOWER LINE

### Fire Tower T1 (tower_fire)
**Current/Base Design**

**Visual Elements**:
- Brazier on stone pedestal
- Eternal flame burning
- Heat shimmer effect
- Rune markings

---

### Fire Tower T2 (tower_fire_t2)
**Upgraded - Blazing Inferno**

**Visual Elements**:
- Larger brazier
- Dual flame jets
- Molten stone accents
- Fire runes glowing
- Ember particles

**Color Palette**:
```
Stone:       #922b21, #641e16 (volcanic)
Metal:       #5d6d7e (heat-treated)
Flames:      #e74c3c, #f39c12, #f4d03f
Embers:      #f4d03f, #fdfefe
Runes:       #f39c12 (glowing)
```

---

### Fire Tower T3 (tower_fire_t3)
**Maximum Upgrade - Phoenix Flame**

**Visual Elements**:
- Phoenix statue centerpiece
- Wings spread as flame jets
- Eternal fire core
- Lava pool at base
- Intense heat distortion

**Color Palette**:
```
Phoenix:     #f4d03f, #f39c12, #e74c3c
Base:        #641e16, #4a1813
Flames:      #fdfefe (core), #f4d03f, #f39c12, #e74c3c
Lava:        #e74c3c, #922b21
```

**Special Animation**:
- Phoenix wings flap
- Flame core pulses
- Continuous ember particles

---

## ICE TOWER LINE

### Ice Tower T1 (tower_ice)
**Current/Base Design**

**Visual Elements**:
- Ice crystal formation
- Frost mist effect
- Frozen ground ring
- Blue glow core

---

### Ice Tower T2 (tower_ice_t2)
**Upgraded - Frozen Spire**

**Visual Elements**:
- Taller ice spire
- Multiple crystal points
- Snowflake patterns
- Frozen chains
- Intensified frost aura

**Color Palette**:
```
Ice:         #85c1e9, #5dade2, #3498db
Deep Ice:    #2980b9, #1a5276
Frost:       #d6eaf8, #ebf5fb
Snow:        #fdfefe
Core:        #aed6f1 (bright glow)
```

---

### Ice Tower T3 (tower_ice_t3)
**Maximum Upgrade - Blizzard Engine**

**Visual Elements**:
- Mechanical/magical hybrid
- Rotating frost core
- Ice crystal array
- Blizzard vortex effect
- Frozen victims (decorative)

**Color Palette**:
```
Core:        #fdfefe (intense glow)
Ice:         #3498db, #2980b9
Metal:       #5d6d7e (frost-covered)
Vortex:      #aed6f1, #d6eaf8
Snow:        #fdfefe, #d5d8dc
```

**Special Effects**:
- Continuous snow particles
- AOE slow field visible
- Frozen ground texture

---

## LIGHTNING TOWER LINE

### Lightning Tower T1 (tower_lightning)
**Current/Base Design**

**Visual Elements**:
- Metal spire/rod
- Crackling electricity
- Stone base with coils
- Arc discharge

---

### Lightning Tower T2 (tower_lightning_t2)
**Upgraded - Storm Spire**

**Visual Elements**:
- Taller conductive spire
- Multiple discharge points
- Tesla coil aesthetic
- Storm cloud formation
- Chain lightning ready

**Color Palette**:
```
Metal:       #5d6d7e, #85929e
Copper:      #b7950b, #d4ac0d
Lightning:   #f4d03f, #fdfefe
Storm:       #2c3e50, #5d6d7e
Energy:      #85c1e9 (core glow)
```

---

### Lightning Tower T3 (tower_lightning_t3)
**Maximum Upgrade - Tesla Coil Array**

**Visual Elements**:
- Triple coil configuration
- Constant arc between coils
- Floating orb centerpiece
- Massive discharge capability
- Ground scorching

**Color Palette**:
```
Coils:       #d4ac0d, #b7950b, #876600
Orb:         #f4d03f, #fdfefe
Arcs:        #fdfefe, #f4d03f
Base:        #2c3e50 (scorched)
Energy:      #f4d03f, #aed6f1
```

**Special Effects**:
- Constant electrical arcs
- Ground electrification zone
- Chain lightning jumps visibly

---

## POISON TOWER LINE

### Poison Tower T1 (tower_poison)
**Current/Base Design**

**Visual Elements**:
- Cauldron/vat design
- Bubbling liquid
- Toxic fumes rising
- Skull warning sign

---

### Poison Tower T2 (tower_poison_t2)
**Upgraded - Toxic Sprayer**

**Visual Elements**:
- Industrial sprayer nozzles
- Larger containment vat
- Pipe system visible
- Hazmat aesthetic
- Wider spray arc

**Color Palette**:
```
Vat:         #1e8449, #145a32
Poison:      #27ae60, #2ecc71, #82e0aa
Bubbles:     #d5f5e3, #fdfefe
Metal:       #5d6d7e, #2c3e50
Warning:     #f4d03f, #e74c3c
```

---

### Poison Tower T3 (tower_poison_t3)
**Maximum Upgrade - Plague Engine**

**Visual Elements**:
- Massive plague engine
- Multiple spray heads
- Toxic cloud generator
- Biohazard containment
- Infected ground zone

**Color Palette**:
```
Engine:      #145a32, #0b5345
Plague:      #27ae60, #2ecc71, #abebc6
Cloud:       #82e0aa (translucent)
Metal:       #2c3e50, #1a252f
Biohazard:   #f4d03f, #e74c3c
```

**Special Effects**:
- Persistent poison cloud
- Ground contamination visual
- Dripping toxic effect

---

## SUPPORT TOWER LINE

### Support Tower T1 (tower_support)
**Current/Base Design**

**Visual Elements**:
- Beacon/crystal tower
- Aura ring effect
- Warm glow
- Buff indicator

---

### Support Tower T2 (tower_support_t2)
**Upgraded - Enhanced Beacon**

**Visual Elements**:
- Larger crystal array
- Rotating aura effect
- Multiple buff types shown
- Brighter, wider range
- Healing particles

**Color Palette**:
```
Crystal:     #f4d03f, #f9e79f
Aura:        #aed6f1 (buff), #abebc6 (heal)
Base:        #5d6d7e, #85929e
Glow:        #fdfefe (core)
Particles:   #82e0aa, #f9e79f
```

---

### Support Tower T3 (tower_support_t3)
**Maximum Upgrade - Command Center**

**Visual Elements**:
- Fortified command post
- Multiple crystal arrays
- Command flags/banners
- Strategy table implied
- Ultimate buff presence

**Color Palette**:
```
Structure:   #2c3e50, #34495e
Crystals:    #f4d03f, #f9e79f, #fdfefe
Banners:     #3498db (friendly blue)
Aura:        #fdfefe (intense)
Gold:        #f4d03f, #d4ac0d
```

**Special Effects**:
- Multiple rotating aura rings
- Buff icons floating
- Command radius clearly visible

---

## TOWER STATES

### Constructing (tower_constructing)
```
Frames: 4
Duration: 400ms per frame
Visual: Scaffold → walls rising → completion flash
Colors: Desaturated base colors + construction tan
```

### Idle (default state)
```
Frames: 1-2
Duration: 1000ms
Visual: Slight ambient movement, ready state
```

### Targeting (tower_targeting)
```
Frames: 2
Duration: 200ms
Visual: Aim adjustment, target lock indicator
```

### Firing (tower_firing)
```
Frames: 4-6
Duration: 300-500ms (varies by type)
Visual: Attack animation, muzzle flash/effect
```

### Disabled (tower_disabled)
```
Frames: 1
Duration: Static
Visual: Grayed out, broken indicator, sparks
Colors: Desaturated, #5d6d7e overlay
```

### Overcharged (tower_overcharged)
```
Frames: 4
Duration: 400ms loop
Visual: Glowing aura, enhanced effects
Colors: Gold/white highlights added
```

---

## TOWER PLACEMENT SYSTEM

### Valid Placement (tower_slot)
```
Dimensions: 16x16
Visual: Green highlighted tile
State: Pulse animation when hovering
```

### Invalid Placement (tower_slot_invalid)
```
Dimensions: 16x16
Visual: Red X overlay
State: Shake animation on click attempt
```

### Active Slot (tower_slot_active)
```
Dimensions: 16x16
Visual: Occupied indicator
State: Tower silhouette shown
```

---

## TOWER RANGE INDICATORS

### Range Circle (tower_range)
```
Asset: Procedural circle overlay
Color: #3498db at 20% opacity
Border: #3498db at 50% opacity, 2px
Style: Dashed line circle
```

### Upgrade Range Comparison
```
Current: Solid fill
Upgraded: Dashed outline (larger)
Colors: Green for increase, yellow for same
```

---

## TOWER UPGRADE UI

### Upgrade Panel (tower_upgrade_panel)
```
Dimensions: 96x128
Content:
  - Tower icon (current tier)
  - Arrow indicator
  - Tower icon (next tier)
  - Cost display
  - Stat changes
```

### Stat Change Indicators
```
Positive: Green arrow up + value
Negative: Red arrow down + value
Neutral: Gray dash
New: Gold star + effect name
```
