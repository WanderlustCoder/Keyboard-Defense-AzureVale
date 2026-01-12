# Sprite Design Specifications - Keyboard Defense: The Siege of Keystonia

**Version:** 1.0.0
**Created:** 2026-01-12
**Status:** Publication Ready
**Priority:** P0 (Core Assets)

---

## Document Purpose

This document provides AAA-quality pixel art specifications for all P0 priority sprites in Keyboard Defense. Each specification is designed to enable any skilled pixel artist to create consistent, professional assets that match the game's established visual language.

---

## Art Direction Summary

### Visual Identity

**Style:** Modern Pixel Art with clean edges, strong silhouettes, and readable details at multiple zoom levels.

**Inspirations:**
- Kingdom Rush (character personality, readable silhouettes)
- Wargroove (color coding, military precision)
- Into the Breach (mechanical clarity, tactical readability)

**Core Principles:**
1. **Readability First** - Every sprite must be instantly identifiable at 1x zoom
2. **Consistent Lighting** - Top-left light source (315 degrees) on all assets
3. **Color Coding** - Enemies in warm reds/purples, allies in blues/golds
4. **Strong Silhouettes** - Recognizable even as solid black shapes
5. **Personality Through Pose** - Each character tells a story through stance

### Technical Standards

| Attribute | Specification |
|-----------|--------------|
| Grid Size | 32px base unit |
| Standard Enemy | 32x32 pixels |
| Large Enemy | 64x64 pixels |
| Boss | 128x128 pixels |
| Building | 32x48 pixels (1 tile wide, 1.5 tiles tall) |
| Outline | 1px for standard, 2-3px for bosses |
| Anti-aliasing | Minimal (selective AA only on curves) |
| Anchor Point | Bottom-center for all entities |
| Export Format | PNG-32 with alpha transparency |

---

## Master Color Palette

### Base Colors

```
BLACKS & GRAYS
  Void Black:     #0a0a0f (deepest shadows)
  Charcoal:       #1a1a2e (outlines, deep shadow)
  Slate:          #3d3d5c (shadow)
  Stone:          #5c5c7a (mid-shadow)
  Silver:         #8b8ba8 (base neutral)
  Cloud:          #c4c4d4 (highlight)
  White:          #f0f0f5 (brightest highlight)

ENEMY PALETTE (Warm Hostiles)
  Blood:          #8b0000 (boss accent, elite base)
  Crimson:        #dc143c (standard enemy base)
  Flame:          #ff4500 (fire, rage effects)
  Orange:         #ff8c00 (warning, caution)
  Gold:           #ffd700 (reward, treasure)
  Yellow:         #ffeb3b (light, holy)

ALLY PALETTE (Cool Defenders)
  Navy:           #000080 (deep ally shadow)
  Royal:          #4169e1 (player/ally base)
  Sky:            #87ceeb (ally highlight)
  Cyan:           #00ffff (magic, energy)
  Teal:           #008080 (support, healing)

NATURE PALETTE
  Forest:         #228b22 (deep green, forest shadow)
  Grass:          #32cd32 (healing, nature base)
  Lime:           #90ee90 (nature highlight)
  Earth:          #8b4513 (wood, organic shadow)
  Sand:           #deb887 (wood highlight)

MAGIC PALETTE
  Purple:         #800080 (elite, corruption)
  Violet:         #9370db (magic base)
  Magenta:        #ff00ff (intense magic)
  Pink:           #ff69b4 (charm, support magic)
```

### Entity Color Coding Quick Reference

| Entity Type | Primary | Secondary | Accent |
|-------------|---------|-----------|--------|
| Standard Enemy | #dc143c | #8b0000 | #ff4500 |
| Elite Enemy | #800080 | #4a0e4e | #c084fc |
| Boss | #8b0000 | (unique) | #ffd700 |
| Healer Enemy | #32cd32 | #228b22 | #90ee90 |
| Buildings | #8b4513 | #5c5c7a | #deb887 |

---

## Sprite Specifications

---

# 1. ENEMY: HEALER

## Overview

| Attribute | Value |
|-----------|-------|
| **Name** | Void Mender |
| **Sprite ID** | `enemy_healer` |
| **Dimensions** | 32x32 pixels |
| **Category** | Standard Enemy (Support) |
| **Role** | Support enemy that heals other enemies; high priority target |
| **Visual Keywords** | Nurturing, corrupted, glowing, ethereal, menacing compassion |

## Silhouette & Shape Language

**Primary Shape:** Organic flowing form (suggests care/healing)
**Secondary Shape:** Hood/cowl (religious connotation, mystery)
**Tertiary Shape:** Raised hands (active casting pose)

**Silhouette Description:**
A robed figure with arms raised in a blessing gesture. The silhouette should be distinctly different from combat enemies - softer edges, more vertical, clearly non-aggressive. A slight hunch forward suggests focus on others rather than self-preservation.

**Key Distinguishing Features (visible in silhouette):**
1. Raised hands with splayed fingers
2. Flowing robe/cloak creating bell shape at bottom
3. Pointed hood or cowl
4. Subtle aura effect extending from hands

**ASCII Silhouette Sketch:**
```
      @@
     @  @
    @@@@@@     <- Hood
     @@@@
    @@@@@@     <- Torso
   @  @@  @    <- Raised arms
  @@  @@  @@   <- Hands casting
     @@@@
    @@@@@@     <- Flowing robe
   @@@@@@@@
  @@@@@@@@@@   <- Bell-shaped bottom
```

## Color Palette

| Role | Color | Hex | Usage |
|------|-------|-----|-------|
| **Primary** | Corrupted Grass | #32cd32 | Robes, main body (40%) |
| **Secondary** | Deep Forest | #228b22 | Shadow areas, inner robe (25%) |
| **Accent** | Toxic Lime | #90ee90 | Healing energy, glow effects (15%) |
| **Shadow** | Dark Forest | #14532d | Deepest folds, under hood (10%) |
| **Highlight** | Light Lime | #98fb98 | Energy highlights, rim light (10%) |
| **Outline** | Charcoal Green | #1a2e1a | 1px outline |
| **Corruption** | Purple | #800080 | Veins, corruption marks |

## Anatomy & Structure

**Head (8x6 pixels):**
- Pointed hood completely covering face
- Deep shadow under hood (mystery, void connection)
- Two small glowing eyes visible in shadow (#90ee90)

**Torso (10x8 pixels):**
- Hunched posture leaning forward
- Flowing robes with vertical fold lines
- Corruption veins visible on shoulder area
- Belt or sash at waist

**Arms (6x10 pixels each):**
- Raised above head in blessing pose
- Sleeves flow downward with gravity
- Hands open with fingers spread
- Energy particles between/around hands

**Lower Body (12x10 pixels):**
- Wide flowing robe
- Bell-shaped silhouette
- 3-4 fold lines for depth
- Slight transparency at hem (ethereal)

**Proportions:**
- Head: 25% of height
- Torso: 25% of height
- Arms extend 30% of width on each side
- Lower body: 50% of height, 75% of width

**Layer Order (back to front):**
1. Shadow/ground effect
2. Back of robe
3. Body and arms
4. Front of robe folds
5. Hands
6. Healing energy effect
7. Eyes glow

## Key Details

**Must-Have Features:**
1. Glowing hands with visible energy particles
2. Deep hood obscuring face except eyes
3. Corruption veins on visible skin/robe
4. Distinct healing aura (green glow)
5. Bell-shaped robe silhouette

**Nice-to-Have Features:**
- Floating healing runes near hands
- Subtle pulse animation on energy
- Trailing particles when moving
- Staff or totem (if space allows)

**Unique Identifiers:**
- Only green enemy in standard roster
- Only enemy with hands raised (non-threatening pose)
- Glow effect makes it visible even in chaos

## Lighting & Shading

**Light Source:** Top-left (315 degrees)

**Shading Levels:**
1. **Highlight** (#98fb98) - Top of hood, tops of hands, robe shoulders
2. **Base** (#32cd32) - Main robe body, mid-tones
3. **Shadow 1** (#228b22) - Robe folds, under arms
4. **Shadow 2** (#14532d) - Under hood, deepest folds

**Special Lighting Effects:**
- **Subsurface glow:** Hands emit light that illuminates nearby robe folds
- **Eye glow:** Small 2px glow from eyes under hood
- **Aura:** 1-2px transparent green border around entire sprite during healing

**Rim Light:**
- 1px lighter edge on right side (opposite light source)
- Color: #90ee90 at 50% opacity

## Animation Considerations

**Idle Animation (4 frames, 8 FPS, loop):**
- Frame 1: Base pose, energy particles low
- Frame 2: Slight arm raise, particles gather
- Frame 3: Peak energy glow, particles bright
- Frame 4: Energy release pulse, particles disperse

**Walk Animation (6 frames, 10 FPS, loop):**
- Gliding motion (feet hidden under robe)
- Robe sways side to side
- Hands remain raised but bob slightly
- Energy trail follows movement

**Heal Cast Animation (6 frames, 12 FPS, one-shot):**
- Wind-up: Arms draw in closer
- Charge: Energy intensifies, glow expands
- Release: Beam/pulse toward target
- Recovery: Arms return to idle position

**Death Animation (8 frames, 10 FPS, one-shot):**
- Energy sputters and fails
- Figure collapses inward
- Robe crumples
- Dissipates into green particles
- Final frame: Small pile of robes

**Secondary Motion:**
- Robe hem constantly ripples (2-frame loop)
- Energy particles orbit hands (independent timing)
- Hood fabric rustles with movement

## Pixel-Perfect Details

**Outline Style:**
- 1px selective outline
- Color: #1a2e1a (slightly green-tinted charcoal)
- Break outline where strong highlights occur
- No outline on energy effects

**Anti-Aliasing:**
- Minimal AA on robe curves (1 intermediate pixel)
- No AA on hood point (keep sharp)
- Soft AA on energy glow edges

**Dithering:**
- 25% dither on robe shadow transitions
- No dithering on energy (keep clean)
- Optional: subtle dither on ground shadow

**Sub-Pixel Techniques:**
- Alternating pixel rows on robe hem for transparency effect
- Offset pixels on energy particles between frames

## Reference Mood Board

**Reference 1: Traditional Healer Archetype**
- Source inspiration: Fantasy RPG clerics/priests
- Take: Robed silhouette, raised hands blessing pose
- Avoid: Holy symbols, overly ornate details

**Reference 2: Corrupted Kindness**
- Source inspiration: Dark fantasy healing creatures
- Take: The unsettling nature of corrupted benevolence
- Avoid: Purely evil appearance (should still read as "healer")

**Reference 3: Kingdom Rush Support Enemies**
- Source inspiration: Kingdom Rush shamans
- Take: Readability at small size, clear support role
- Avoid: Exact copying, overly busy design

**Reference 4: Glowing Magic Effects**
- Source inspiration: Pixel art magic tutorials
- Take: Clean glow techniques, particle effects
- Avoid: Over-complicated particle systems

**Reference 5: Wargroove Unit Design**
- Source inspiration: Wargroove character clarity
- Take: Strong pose, immediate role recognition
- Avoid: Military rigidity (healer should feel softer)

## Implementation Notes

**SVG Structure:**
```
enemy_healer.svg
  /background-glow (filtered blur)
  /shadow-layer
  /robe-back
  /body-core
  /arms-group
    /arm-left
    /arm-right
  /robe-front
  /hood
  /eyes
  /energy-effects
    /particles
    /glow-aura
```

**Layer Naming Convention:**
- Use descriptive names: `robe_shadow`, `hand_right`, `glow_particles`
- Group related elements
- Keep effects in separate exportable groups

**Export Considerations:**
- Export at 1x and 2x resolution
- Separate animation frames as individual files or sprite sheet row
- Include glow effects as separate layer for optional use
- Export shadow as separate element for dynamic lighting

**Game Integration Notes:**
- Healing aura should pulse when heal ability is active
- Consider tinting sprite when buffed/debuffed
- Priority target indicator should be especially visible

---

# 2. ENEMY: RAIDER (Basic Grunt)

## Overview

| Attribute | Value |
|-----------|-------|
| **Name** | Typhos Raider |
| **Sprite ID** | `enemy_raider` |
| **Dimensions** | 32x32 pixels |
| **Category** | Standard Enemy (Grunt) |
| **Role** | Basic grunt enemy, most common threat, balanced stats |
| **Visual Keywords** | Aggressive, corrupted, barbaric, menacing, relentless |

## Silhouette & Shape Language

**Primary Shape:** Triangle (aggressive, forward-leaning)
**Secondary Shape:** Rectangle (body armor, solid presence)
**Tertiary Shape:** Sharp angles (spikes, weapon)

**Silhouette Description:**
A hunched, aggressive humanoid warrior leaning forward in a charging stance. Broad shoulders tapering to narrower legs creates an imposing triangular form. The silhouette should immediately read as "threat approaching."

**Key Distinguishing Features (visible in silhouette):**
1. Forward-leaning aggressive stance
2. Raised weapon (club, axe, or crude blade)
3. Spiked shoulder armor or natural protrusions
4. Slightly oversized head (corruption mutation)

**ASCII Silhouette Sketch:**
```
        @@@
       @@@@@        <- Spiked head
      @@@ @@@
     @@@@@@@@@      <- Shoulders with spikes
    @@@@   @@@@
      @@@@@@@       <- Torso
       @@@@@@@      <- Weapon arm raised
      @@@@ @@
      @@@ @@@       <- Legs
     @@@   @@@
```

## Color Palette

| Role | Color | Hex | Usage |
|------|-------|-----|-------|
| **Primary** | Crimson | #dc143c | Skin/body, main mass (40%) |
| **Secondary** | Blood Red | #8b0000 | Armor, darker areas (25%) |
| **Accent** | Flame Orange | #ff4500 | Eyes, weapon glow, corruption veins (15%) |
| **Shadow** | Dark Purple | #4c1d95 | Deepest shadows, void tint (10%) |
| **Highlight** | Light Coral | #f08080 | Skin highlights (10%) |
| **Outline** | Charcoal | #1a1a2e | 1px outline |
| **Metal** | Slate | #5c5c7a | Weapon, armor plates |

## Anatomy & Structure

**Head (8x8 pixels):**
- Slightly oversized (1.2x normal proportions)
- Glowing eyes (2 pixels each, #ff4500)
- Open mouth with visible teeth (aggression)
- Small horns or corruption spikes (2-3 pixels)
- Heavy brow creating deep eye shadow

**Torso (12x10 pixels):**
- Broad, muscular
- Forward-leaning 15-20 degrees
- Crude armor plates (2-3 pieces)
- Corruption veins visible on exposed skin
- Belt with hanging trophies (optional)

**Arms (6x12 pixels each):**
- Right arm raised with weapon
- Left arm forward for balance
- Muscular, slightly elongated
- Bandaged or armored forearms

**Weapon (8x12 pixels):**
- Crude axe, club, or cleaver
- Notched and battle-worn appearance
- Slight glow on edge (corruption energy)
- Held high in ready-to-strike pose

**Legs (6x10 pixels each):**
- Slightly bent, ready to charge
- Wrapped or armored
- Clawed feet (optional)
- Wide stance for stability

**Proportions:**
- Head: 30% of height (intentionally large)
- Torso: 35% of height
- Legs: 35% of height
- Weapon extends above head
- Width at shoulders: 85% of sprite width

**Layer Order (back to front):**
1. Shadow
2. Back leg
3. Back arm
4. Torso
5. Front leg
6. Front arm
7. Weapon
8. Head
9. Eyes/glow effects

## Key Details

**Must-Have Features:**
1. Glowing orange/red eyes (corruption indicator)
2. Raised weapon (immediate threat recognition)
3. Forward-leaning aggressive stance
4. Visible corruption marks (veins or skin discoloration)
5. Spiked or angular silhouette elements

**Nice-to-Have Features:**
- Dripping corruption from weapon
- Breath effect (cold or smoke)
- Battle damage on armor
- Trophy or bones on belt

**Unique Identifiers:**
- Most "standard enemy" silhouette in roster
- Weapon pose is signature identifier
- Base crimson color establishes "enemy" coding

## Lighting & Shading

**Light Source:** Top-left (315 degrees)

**Shading Levels:**
1. **Highlight** (#f08080) - Top of head, raised weapon, front shoulder
2. **Base** (#dc143c) - Main skin/body areas
3. **Shadow 1** (#8b0000) - Under arms, back areas, armor
4. **Shadow 2** (#4c1d95) - Deepest recesses, under chin, inner legs

**Special Lighting Effects:**
- **Eye glow:** 2px emanating light affecting nearby pixels
- **Weapon edge:** Subtle 1px highlight on blade
- **Corruption glow:** Very subtle inner light on veins

**Material Differentiation:**
- Skin: Smooth gradient, warmer
- Armor: Hard edges, cooler tones
- Weapon: Metallic highlight, single bright pixel

## Animation Considerations

**Idle Animation (4 frames, 8 FPS, loop):**
- Frame 1: Base stance
- Frame 2: Slight weight shift forward
- Frame 3: Weapon raised slightly higher (anticipation)
- Frame 4: Return to base

**Walk Animation (6 frames, 10 FPS, loop):**
- Aggressive march, weapon stays raised
- Body bobs up and down with steps
- Arms swing minimally (weapon-focused)
- Shoulders lead the movement

**Attack Animation (4 frames, 12 FPS, one-shot):**
- Wind-up: Weapon pulled back
- Swing: Fast forward motion (can use smear frame)
- Impact: Weapon at lowest point
- Recovery: Returns to raised position

**Death Animation (6 frames, 10 FPS, one-shot):**
- Weapon drops first
- Body staggers backward
- Falls to knees
- Collapses forward
- Corruption dissipates
- Final frame: Empty armor/pile

**Key Poses:**
- Idle: Coiled aggression, ready to strike
- Walk: Relentless forward march
- Attack: Full extension, maximum threat
- Death: Dramatic collapse, corruption leaving body

## Pixel-Perfect Details

**Outline Style:**
- 1px full outline
- Color: #1a1a2e (charcoal)
- Darker outline on shadow side
- Break at brightest highlights optional

**Anti-Aliasing:**
- Minimal AA on shoulder curves
- Sharp edges on weapon
- Soft AA on head shape

**Dithering:**
- 25% dither on skin shadow transitions
- No dithering on armor (hard edges)
- Optional dither on ground shadow

## Reference Mood Board

**Reference 1: Orc/Goblin Warriors**
- Take: Barbaric silhouette, crude weapons
- Avoid: Overly comical proportions

**Reference 2: Corruption/Void Aesthetics**
- Take: Glowing eyes, corruption veins
- Avoid: Too abstract or formless

**Reference 3: Kingdom Rush Enemies**
- Take: Readability, clear threat posture
- Avoid: Over-detailed or busy designs

**Reference 4: Wargroove Basic Units**
- Take: Clean silhouette, immediate recognition
- Avoid: Too generic or forgettable

**Reference 5: Dark Souls Hollows**
- Take: Twisted, tragic warrior feel
- Avoid: Too horror-focused

## Implementation Notes

**SVG Structure:**
```
enemy_raider.svg
  /shadow
  /back-leg
  /back-arm
  /torso
    /armor-plates
    /corruption-veins
  /front-leg
  /weapon
    /blade
    /handle
    /glow-effect
  /front-arm
  /head
    /face
    /horns
    /eyes-glow
```

**Export Considerations:**
- Standard enemy, will appear in large numbers
- Optimize for batch rendering
- Variations: Consider 2-3 color/armor variants

---

# 3. BOSS: FOREST GUARDIAN (Day 5 - Evergrove)

## Overview

| Attribute | Value |
|-----------|-------|
| **Name** | Forest Guardian |
| **Sprite ID** | `boss_forest_guardian` |
| **Dimensions** | 128x128 pixels |
| **Category** | Boss |
| **Region** | Evergrove (Day 5) |
| **Lore** | Ancient tree spirit, defender of the sacred grove, corrupted by void energy |
| **Visual Keywords** | Ancient, majestic, nature, corrupted, towering, tragic |

## Silhouette & Shape Language

**Primary Shape:** Vertical trunk/pillar (strength, age, stability)
**Secondary Shape:** Organic branching (nature, reaching, grasping)
**Tertiary Shape:** Corrupted asymmetry (something wrong, twisted)

**Silhouette Description:**
A towering treant-like figure with a humanoid upper body emerging from a massive trunk base. Branches extend like arms and crown. The left side appears healthy and natural; the right side shows corruption - twisted, darker, with void tendrils. This asymmetry is the visual heart of the design.

**Key Distinguishing Features (visible in silhouette):**
1. Massive size (fills most of 128x128)
2. Branch-arms reaching outward
3. Crown of branches/leaves at top
4. Asymmetrical corruption (left healthy, right corrupted)
5. Root-feet anchoring into ground

**ASCII Silhouette Sketch:**
```
           @@@@@@@@@@@@@
         @@@@@@   @@@@@@@@
        @@@@@       @@@@@@@@    <- Crown with corruption
       @@@@           @@@@@@@
      @@@@   @@@@@@@   @@@@@@   <- Face area
       @@@@ @@@@@@@@@@ @@@@
        @@@@@@@@@@@@@@@@@       <- Shoulders
     @@@@@@@@@@@@@@@@@@@@@@     <- Arms spread
   @@@@   @@@@@@@@@@@   @@@@@@
  @@@       @@@@@@@@@     @@@@@
            @@@@@@@@@           <- Trunk
            @@@@@@@@@
           @@@@@@@@@@@          <- Widening base
          @@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@      <- Root-feet
```

## Color Palette

| Role | Color | Hex | Usage |
|------|-------|-----|-------|
| **Primary (Healthy)** | Forest Green | #228b22 | Left side, healthy bark/leaves (30%) |
| **Primary (Corrupt)** | Purple | #4c1d95 | Right side corruption (25%) |
| **Secondary (Healthy)** | Earth Brown | #8b4513 | Bark, trunk texture (15%) |
| **Secondary (Corrupt)** | Void Black | #1a1a2e | Corruption veins, void areas (10%) |
| **Accent (Healthy)** | Lime | #90ee90 | Leaf highlights, healthy glow (8%) |
| **Accent (Corrupt)** | Violet | #c084fc | Corruption glow, void eyes (7%) |
| **Shadow** | Dark Earth | #3d2817 | Deep bark shadows (5%) |
| **Highlight** | Gold | #ffd700 | Ancient energy, core light |

## Anatomy & Structure

**Crown (40x30 pixels, top):**
- Left side: Healthy leaves and branches, spring green
- Right side: Bare twisted branches, purple corruption
- Center: Ancient runes glowing faintly
- Asymmetrical but balanced composition

**Head/Face (30x25 pixels):**
- Located in upper trunk
- Eyes: Left eye warm green glow, right eye purple void
- Mouth: Carved/grown expression, bark texture
- Expression: Pained, conflicted (not evil)

**Torso/Upper Trunk (50x40 pixels):**
- Broad, barrel-like
- Ancient carved patterns visible
- Left side: Healthy bark with moss
- Right side: Cracked, void energy seeping through
- Core: Faint heartwood glow visible through cracks

**Arms/Branches (35x50 pixels each):**
- Left arm: Strong, healthy, leafy
- Right arm: Twisted, blackened, thorn-covered
- Both reach outward and slightly up
- Fingers are branch-like (5-7 digits)

**Lower Trunk (40x35 pixels):**
- Wider at base
- Ancient carved runes
- Moss and growth on healthy side
- Corruption spreading up from roots on right

**Root-Feet (60x20 pixels, bottom):**
- Spread wide for stability
- Some roots above ground, some implied below
- Left roots: Healthy, anchoring
- Right roots: Corrupted, tentacle-like movement

**Proportions:**
- Crown: 25% of height
- Face/Head: 20% of height
- Torso: 30% of height
- Lower trunk: 15% of height
- Roots: 10% of height
- Total width with arms: 100% of sprite
- Trunk width: 40% of sprite

## Key Details

**Must-Have Features:**
1. Clear left/right health/corruption divide
2. Two differently-colored eyes (key identifier)
3. Ancient rune markings (story element)
4. Visible heartwood core glow
5. Root system showing connection to earth

**Nice-to-Have Features:**
- Small animals/spirits in healthy branches
- Void particles drifting from corrupted side
- Falling leaves (healthy) vs falling void ash (corrupt)
- Moss and texture details on bark

**Unique Identifiers:**
- Asymmetrical corruption is signature visual
- First boss players encounter
- Largest nature-based enemy
- Tragic villain (not purely evil appearance)

## Lighting & Shading

**Light Source:** Top-left (315 degrees)

**Shading Levels (Healthy Side):**
1. **Highlight** (#90ee90) - Top of crown, forward-facing leaves
2. **Base** (#228b22) - Main foliage and bark
3. **Shadow 1** (#1a5f1a) - Under branches, behind leaves
4. **Shadow 2** (#0f3d0f) - Deepest bark crevices

**Shading Levels (Corrupted Side):**
1. **Highlight** (#c084fc) - Void energy glow points
2. **Base** (#4c1d95) - Corrupted areas
3. **Shadow 1** (#2d1157) - Corruption depth
4. **Shadow 2** (#1a1a2e) - Void black in cracks

**Special Lighting Effects:**
- **Heartwood glow:** Warm golden light emanating from chest, visible through bark cracks
- **Eye differentiation:** Left eye casts green light, right casts purple
- **Corruption energy:** Subtle pulse on void sections
- **Rim light:** Green on left edge, purple on right

**Boss Outline:**
- 2px outline
- Left side: #0f3d0f (dark forest green)
- Right side: #1a1a2e (void black)
- Transition point at center creates interesting break

## Animation Considerations

**Idle Animation (8 frames, 6 FPS, loop):**
- Gentle sway like a tree in wind
- Leaves rustle on healthy side
- Corruption pulses on right side
- Eyes blink at different times
- Heartwood glow pulses slowly

**Walk Animation (8 frames, 8 FPS, loop):**
- Root-feet pull from ground and replant
- Trunk shifts side to side
- Arms for balance
- Ground cracks where corrupted foot lands
- Leaves/particles trail behind

**Attack 1 - Root Snare (6 frames, 12 FPS, one-shot):**
- Roots burst from ground toward player area
- Both healthy and corrupted roots
- Wrap/grasp motion
- Return to ground

**Attack 2 - Branch Slam (6 frames, 12 FPS, one-shot):**
- Arms raise high
- Dramatic swing downward
- Impact with ground shake
- Recovery to neutral

**Special - Regeneration (10 frames, 8 FPS, one-shot):**
- Heartwood glows brighter
- Green energy flows through healthy side
- Corruption temporarily pushed back
- Healthy glow spreads briefly

**Death Animation (12 frames, 10 FPS, one-shot):**
- Light fades from eyes
- Corruption rapidly spreads
- Then suddenly retreats
- Guardian returns to pure form briefly
- Crumbles into peaceful pile of leaves/wood
- Single seed remains glowing (hope)

**Secondary Motion:**
- Leaves constantly drift (2 independent loops)
- Corruption particles rise from right side
- Small creatures occasionally peek from left branches

## Phase Variations

### Phase 1 (100% - 70% HP): "Nature's Test"

**Visual State:**
- Corruption contained to right 30% of body
- Both eyes active and expressive
- Healthier overall appearance
- Crown mostly intact

**Color Shifts:**
- Healthy green more vibrant
- Corruption visually "held back"
- Heartwood glow strong and golden

**Added Elements:**
- Vine barriers spawn (separate sprites)
- Healing root networks visible on ground

### Phase 2 (70% - 35% HP): "Guardian's Fury"

**Visual State:**
- Corruption spread to right 50%
- Struggling expression
- Crown losing leaves on right
- Cracks spreading across trunk

**Color Shifts:**
- Healthy side slightly desaturated
- Corruption more vibrant/active
- Purple glow increases
- Heartwood flickers

**Added Elements:**
- Corruption tendrils visible
- Root attacks more frequent
- Treant summons appear (separate sprites)

### Phase 3 (35% - 0% HP): "Heart of Corruption"

**Visual State:**
- Corruption at 70% of body
- Only left arm and part of face healthy
- Crown mostly bare/corrupted
- Core visible through massive cracks

**Color Shifts:**
- Green barely visible
- Purple dominates
- Heartwood desperate golden pulse
- Eyes both flickering

**Added Elements:**
- Exposed weak point (heartwood core)
- Corruption waves emanating
- Final stand desperation evident

**Transition Animations:**
- Phase 1->2: Roar animation, corruption surge
- Phase 2->3: Bark cracking, core revelation

## Pixel-Perfect Details

**Outline Style:**
- 2-3px outline (boss scale)
- Color varies by side
- Breaks at major glow points
- Thicker on bottom (grounding)

**Anti-Aliasing:**
- Moderate AA on organic curves
- Sharp edges on corruption crystals
- Soft transitions on glow effects

**Dithering:**
- 25% dither on bark texture
- Gradient dithering on corruption spread
- No dithering on core glow

**Texture Details:**
- Bark has vertical line patterns
- Corruption has vein/crack patterns
- Leaves are clustered, not individual at this scale

## Reference Mood Board

**Reference 1: Treants/Ents from Fantasy**
- Take: Majestic tree-being form, ancient wisdom
- Avoid: Generic "angry tree" appearance

**Reference 2: Corruption Spreading (Hollow Knight, Ori)**
- Take: Clear visual boundary between healthy/corrupt
- Avoid: Corruption looking "cool" rather than tragic

**Reference 3: Studio Ghibli Forest Spirits**
- Take: Sense of ancient nature spirit
- Avoid: Too cute or non-threatening

**Reference 4: Dark Souls Corrupted Bosses**
- Take: Tragic fallen guardian archetype
- Avoid: Pure grotesque horror

**Reference 5: Kingdom Rush Boss Scale/Presence**
- Take: Screen presence, readable at boss scale
- Avoid: Too much small detail lost at gameplay distance

## Implementation Notes

**SVG Structure:**
```
boss_forest_guardian.svg
  /ground-shadow
  /root-system
    /roots-healthy
    /roots-corrupt
  /lower-trunk
    /bark-healthy
    /bark-corrupt
    /runes
  /torso
    /bark-main
    /corruption-cracks
    /heartwood-core
  /arms
    /arm-left-healthy
      /branches
      /leaves
    /arm-right-corrupt
      /branches-twisted
      /thorns
      /corruption-glow
  /head-face
    /bark-face
    /mouth
    /eye-left
    /eye-right
  /crown
    /branches-healthy
    /leaves
    /branches-corrupt
  /effects
    /corruption-particles
    /leaf-particles
    /glow-effects
```

**Phase Variant Handling:**
- Use overlay layers that change opacity
- Corruption layer increases coverage per phase
- Damage cracks are additive layers
- Core glow changes via color property

**Export Considerations:**
- Full sprite sheet for all animations
- Separate effect layers for compositing
- Phase indicators as separate assets
- Consider low-res preview for distant view

---

# 4. BOSS: STONE GOLEM (Day 10 - Stonepass)

## Overview

| Attribute | Value |
|-----------|-------|
| **Name** | Stone Golem |
| **Sprite ID** | `boss_stone_golem` |
| **Dimensions** | 128x128 pixels |
| **Category** | Boss |
| **Region** | Stonepass (Day 10) |
| **Lore** | Ancient dwarven construct awakened from the mountains, bound by keysteel runes |
| **Visual Keywords** | Massive, ancient, mechanical, runic, unyielding, crystalline |

## Silhouette & Shape Language

**Primary Shape:** Rectangle/Square (stability, immovability, defense)
**Secondary Shape:** Geometric blocks (constructed, deliberate)
**Tertiary Shape:** Crystals (power source, vulnerability)

**Silhouette Description:**
A towering humanoid construct of stacked stone blocks and carved rock. Shoulders wider than head, creating an imposing rectangular frame. Glowing runes trace ancient patterns across its surface. Crystal formations protrude from shoulders, back, and joints - these are both power sources and visual weak points.

**Key Distinguishing Features (visible in silhouette):**
1. Blocky, geometric construction
2. Massive shoulders and small head
3. Crystal protrusions on shoulders/back
4. Heavy grounded stance
5. Segmented body (visible joints)

**ASCII Silhouette Sketch:**
```
            @@@@@
           @@@@@@@          <- Small head
          @@@@@@@@@
    @@@@ @@@@@@@@@@@ @@@@   <- Crystal shoulders
   @@@@@@@@@@@@@@@@@@@@@@@
   @@@@@@@@@@@@@@@@@@@@@@@  <- Massive chest
     @@@@@@@@@@@@@@@@@@@
      @@@@@@@@@@@@@@@@@     <- Armored torso
       @@@@@@@@@@@@@@@
        @@@@@   @@@@@       <- Waist
       @@@@@@@   @@@@@@@    <- Hips
      @@@@@@@     @@@@@@@   <- Legs
     @@@@@@@@     @@@@@@@@
    @@@@@@@@@     @@@@@@@@@
   @@@@@@@@@@     @@@@@@@@@@<- Wide base feet
```

## Color Palette

| Role | Color | Hex | Usage |
|------|-------|-----|-------|
| **Primary** | Stone Gray | #5c5c7a | Main stone body (40%) |
| **Secondary** | Dark Slate | #3d3d5c | Deep crevices, shadow stone (25%) |
| **Accent** | Rune Gold | #ffd700 | Active runes, eyes (10%) |
| **Crystal** | Cyan | #00ffff | Power crystals (10%) |
| **Shadow** | Charcoal | #1a1a2e | Deepest shadows (10%) |
| **Highlight** | Silver | #c4c4d4 | Stone edges, polish (5%) |
| **Outline** | Dark Stone | #2d2d3d | 2-3px outline |

## Anatomy & Structure

**Head (25x25 pixels):**
- Small relative to body (emphasizes mass below)
- Geometric, almost cubic
- Two rune-marked eye slits glowing gold
- Angular jaw/chin structure
- Ancient carved patterns

**Shoulders (50x30 pixels):**
- Massive, wider than body
- Crystal formations protruding upward (8-12 pixels)
- Segmented armor plates
- Glowing rune bands connecting to arms

**Torso (55x45 pixels):**
- Barrel-like, constructed from blocks
- Central rune circle (power core visible)
- Segmented plates with visible seams
- Ancient dwarven inscriptions

**Arms (25x55 pixels each):**
- Heavy, blocky construction
- Multiple joint segments
- Ends in massive fists
- Rune bands at wrist, elbow, shoulder

**Legs (25x45 pixels each):**
- Pillar-like, very stable
- Wide at base, narrower at knee
- Heavy foot blocks
- Grinding movement implied

**Crystal Points (various sizes):**
- Shoulder crystals: 10x15 pixels each
- Back crystals: 8x12 pixels (partially visible)
- Joint crystals: 4x6 pixels

**Proportions:**
- Head: 15% of height
- Shoulders/chest: 30% of height
- Torso: 20% of height
- Legs: 35% of height
- Shoulder width: 90% of sprite
- Leg stance: 60% of sprite width

## Key Details

**Must-Have Features:**
1. Glowing gold rune patterns (dwarven magic)
2. Cyan crystal power sources
3. Visible segmentation (constructed feel)
4. Small head, massive body proportion
5. Central power core/chest rune

**Nice-to-Have Features:**
- Damage showing inner workings
- Floating debris around crystals
- Steam/dust from joints
- Ancient text inscriptions

**Unique Identifiers:**
- Only geometric/constructed boss
- Crystal weak points are gameplay element
- Dwarven aesthetic ties to Stonepass region
- Rune glow indicates attack charging

## Lighting & Shading

**Light Source:** Top-left (315 degrees)

**Shading Levels:**
1. **Highlight** (#c4c4d4) - Top surfaces, crystal reflections
2. **Base** (#5c5c7a) - Main stone mass
3. **Shadow 1** (#3d3d5c) - Undersides, recesses
4. **Shadow 2** (#1a1a2e) - Deep joints, behind plates

**Special Lighting Effects:**
- **Rune glow:** Gold light emanating from carved channels
- **Crystal glow:** Cyan light pulses, affects nearby stone
- **Core glow:** Central chest radiates warmth
- **Eye glow:** Directed golden light beams

**Material Properties:**
- Stone: Matte surface, subtle texture
- Crystals: Highly reflective, internal refraction effect
- Runes: Emissive glow, no shadow on them
- Metal bands: Hard specular highlight

## Animation Considerations

**Idle Animation (6 frames, 4 FPS, loop):**
- Minimal movement (stone is patient)
- Runes pulse slowly
- Crystals flicker with energy
- Subtle settling/grinding sounds implied

**Walk Animation (8 frames, 6 FPS, loop):**
- Heavy, deliberate steps
- Ground shake effect (separate)
- Arms swing minimally
- Dust/debris particles from feet

**Attack 1 - Ground Pound (8 frames, 12 FPS, one-shot):**
- Both arms raise
- Dramatic pause at apex
- Slam down with screen shake
- AoE indicator spreads

**Attack 2 - Crystal Barrier (6 frames, 10 FPS, one-shot):**
- Crystals glow intensely
- Shield effect manifests
- Barrier solidifies around boss
- Maintained until broken

**Special - Seismic Charge (8 frames, 10 FPS, one-shot):**
- Runes flare brightly
- Energy draws to core
- Builds to critical point
- Releases in wave pattern

**Death Animation (14 frames, 8 FPS, one-shot):**
- Crystals shatter first (Phase 3 vulnerability)
- Runes flicker and fade
- Segments separate
- Collapses in sequence (top to bottom)
- Core releases energy burst
- Rubble pile remains

## Phase Variations

### Phase 1 (100% - 70% HP): "Awakening"

**Visual State:**
- Full armor, crystals pristine
- Runes glowing steady gold
- Imposing and undamaged
- Maximum height/presence

**Color Shifts:**
- Crystals brightest cyan
- Runes consistent glow
- Stone clean and solid

**Added Elements:**
- Shield aura occasionally visible
- Ground cracks beneath feet
- Dust cloud ambient

### Phase 2 (70% - 35% HP): "Rampage"

**Visual State:**
- Armor showing cracks
- One shoulder crystal damaged
- Runes flickering
- Steam from joints

**Color Shifts:**
- Crystals slightly dimmer
- Runes more erratic glow
- Stone shows stress fractures

**Added Elements:**
- Visible damage cracks (overlay)
- More debris particles
- Inner glow visible through cracks

### Phase 3 (35% - 0% HP): "Core Meltdown"

**Visual State:**
- Major armor sections broken
- Crystals critically damaged/partially shattered
- Runes failing
- Core fully exposed

**Color Shifts:**
- Crystals dim and cracked
- Runes intermittent
- Core glow orange (overheating)
- Stone shows severe damage

**Added Elements:**
- Weak point clearly visible (core)
- Desperate energy surges
- Pieces falling off
- Critical damage indicators

## Pixel-Perfect Details

**Outline Style:**
- 2-3px outline (boss scale)
- Color: #2d2d3d (dark stone)
- Consistent weight throughout
- Breaks at crystal glow points

**Anti-Aliasing:**
- Minimal AA (geometric shapes)
- Sharp edges on stone blocks
- Soft glow on crystals and runes

**Dithering:**
- 25% dither for stone texture
- Gradient dithering for glow falloff
- No dithering on crystals (clarity)

**Texture Notes:**
- Stone has subtle noise pattern
- Rune channels are carved indentations
- Crystals have internal line pattern (facets)

## Reference Mood Board

**Reference 1: Iron Golem (Minecraft/D&D)**
- Take: Blocky construction, deliberate movement
- Avoid: Too simple or modern

**Reference 2: Dwarven Architecture**
- Take: Runic patterns, ancient craftsmanship
- Avoid: Nordic/Viking (wrong culture)

**Reference 3: Crystal Magic Fantasy**
- Take: Power source visual language
- Avoid: Too technological/sci-fi

**Reference 4: Shadow of the Colossus**
- Take: Weak point visibility, massive scale feel
- Avoid: Overwhelming complexity

**Reference 5: Into the Breach Mechs**
- Take: Readable mechanical clarity
- Avoid: Too detailed at small scale

## Implementation Notes

**SVG Structure:**
```
boss_stone_golem.svg
  /ground-effects
    /shadow
    /crack-marks
    /dust-particles
  /legs
    /leg-left
      /foot
      /shin
      /thigh
      /joint-glow
    /leg-right
      /... (mirror)
  /torso
    /lower-torso
    /upper-torso
    /armor-plates
    /core
      /core-glow
      /core-runes
  /arms
    /arm-left
      /shoulder
      /upper-arm
      /forearm
      /fist
      /rune-bands
    /arm-right
      /... (mirror)
  /shoulders
    /shoulder-plate-left
    /shoulder-plate-right
    /crystal-left
    /crystal-right
  /head
    /head-base
    /eye-left
    /eye-right
    /rune-patterns
  /effects
    /rune-glow-layer
    /crystal-glow-layer
    /damage-overlays
```

**Phase Damage System:**
- Damage cracks are additive layers
- Crystal states: intact > cracked > shattered
- Armor plates can be hidden/shown per damage
- Core exposure increases per phase

---

# 5. BOSS: FEN SEER (Day 15 - Mistfen)

## Overview

| Attribute | Value |
|-----------|-------|
| **Name** | Fen Seer |
| **Sprite ID** | `boss_fen_seer` |
| **Dimensions** | 128x128 pixels |
| **Category** | Boss |
| **Region** | Mistfen (Day 15) |
| **Lore** | Mystical swamp oracle with dark powers, master of illusion and toxins |
| **Visual Keywords** | Ethereal, mysterious, toxic, mystical, deceptive, haunting |

## Silhouette & Shape Language

**Primary Shape:** Flowing/amorphous (unpredictable, ethereal)
**Secondary Shape:** Serpentine curves (danger, mysticism)
**Tertiary Shape:** Multiple layers (illusion, deception)

**Silhouette Description:**
A floating spectral figure with no clear lower body - the form dissolves into mist and tentacles below the waist. Multiple floating elements surround the main body: orbs, runes, and ghostly hands. The silhouette should feel unstable, as if it might shift at any moment.

**Key Distinguishing Features (visible in silhouette):**
1. Floating pose (no visible legs/feet)
2. Flowing robes/mist trails
3. Multiple floating orbs around figure
4. Hood or crown-like head element
5. Extended arms with long fingers

**ASCII Silhouette Sketch:**
```
          @@@@@@@@@
         @@@@@@@@@@@         <- Crown/hood
    @@  @@@@@@@@@@@@@  @@    <- Floating orbs
   @@@@ @@@@@ @@@@@@@ @@@@
        @@@@@@@@@@@@@        <- Face area
   @@   @@@@@@@@@@@@@   @@   <- Orbs
       @@@@@@@@@@@@@@@       <- Shoulders
      @@@@@@@@@@@@@@@@@      <- Torso
     @@@@@@ @@@@@ @@@@@@     <- Arms spread
    @@@@@   @@@@@   @@@@@
   @@@@@    @@@@@    @@@@@   <- Dissolving form
    @@@     @@@@@     @@@
     @@    @@@@@@@    @@     <- Mist tendrils
      @   @@@@@@@@@   @
          @@@@@@@@@          <- Dissipating
            @@@@@
```

## Color Palette

| Role | Color | Hex | Usage |
|------|-------|-----|-------|
| **Primary** | Swamp Green | #14532d | Main robes, base form (35%) |
| **Secondary** | Mist Purple | #9370db | Magic effects, ethereal parts (25%) |
| **Accent** | Toxic Lime | #84cc16 | Poison effects, eye glow (15%) |
| **Shadow** | Void Black | #0f172a | Deepest shadows, void spaces (10%) |
| **Highlight** | Ghostly White | #e2e8f0 | Ethereal highlights (10%) |
| **Mist** | Purple Haze | #6366f1 | Mist trails, illusion effects (5%) |
| **Outline** | Dark Teal | #134e4a | Selective outline |

## Anatomy & Structure

**Head/Crown (30x35 pixels):**
- Elaborate crown or antler-like formation
- Face partially obscured by hood
- Multiple eyes visible (3-5, some illusory)
- Main eyes glow toxic green
- Floating mask element (optional)

**Torso (40x40 pixels):**
- Spectral/transparent at edges
- Elaborate robes with swamp motifs
- Central eye or orb (third eye power source)
- Corruption veins visible beneath fabric

**Arms (30x45 pixels each):**
- Elongated, unnatural proportions
- Long spindly fingers
- Floating independently at times
- Mist trails from movements
- Grasping, casting poses

**Lower Body (50x40 pixels):**
- No defined legs
- Dissolves into mist tentacles
- Multiple trailing wisps
- Occasionally reforms briefly
- Toxic pools drip below

**Floating Elements (various):**
- 4-6 spectral orbs (8-12 pixels each)
- Orbit around main body
- Independent glow and movement
- Illusion indicators

**Proportions:**
- Head/crown: 25% of height
- Torso: 35% of height
- Lower mist form: 40% of height
- Arms extend 40% beyond body width
- Floating orbs at 20% distance from body

## Key Details

**Must-Have Features:**
1. Multiple eyes (illusion theme)
2. Floating orbs around body
3. Lower body dissolves to mist
4. Toxic green glow accents
5. Ethereal transparency on edges

**Nice-to-Have Features:**
- Faces in the mist (absorbed souls)
- Floating runes/symbols
- Dripping poison effects
- Illusory second form faintly visible

**Unique Identifiers:**
- Only floating/ethereal boss
- Most magical/mystical appearance
- Illusion theme visible in design
- Connection to swamp environment

## Lighting & Shading

**Light Source:** Ambient/internal (ethereal being)

**Shading Levels:**
1. **Highlight** (#e2e8f0) - Crown points, orb centers
2. **Base** (#14532d) - Main robe body
3. **Shadow 1** (#0a2618) - Robe folds, depth
4. **Shadow 2** (#0f172a) - Void areas, deepest shadows

**Special Lighting Effects:**
- **Self-luminous:** Figure generates own light
- **Eye glow:** Multiple toxic green glows
- **Orb glow:** Each orb pulses independently
- **Mist glow:** Purple ambient light in mist
- **Transparency:** Edge areas fade to transparent

**Ethereal Effects:**
- 50% opacity on outer edges
- Internal glow visible through form
- Color shifts subtly through spectrum
- Afterimage trails on movement

## Animation Considerations

**Idle Animation (8 frames, 6 FPS, loop):**
- Floating bob motion
- Orbs orbit slowly
- Mist tendrils writhe
- Eyes blink in sequence (not simultaneously)
- Robes billow without wind

**Float Animation (8 frames, 8 FPS, loop):**
- Gliding movement (no walking)
- Mist trail extends behind
- Orbs follow in delayed pattern
- Arms flow with movement

**Attack 1 - Word Scramble (8 frames, 10 FPS, one-shot):**
- Hands raise, orbs gather
- Magical symbols appear
- Energy releases toward UI
- Player's words visually scramble

**Attack 2 - Toxic Cloud (6 frames, 10 FPS, one-shot):**
- Mouth opens (or hand gesture)
- Green mist builds
- Cloud spreads across arena
- Poison particles drift

**Attack 3 - Summon Illusions (8 frames, 10 FPS, one-shot):**
- Multiple copies appear
- Shimmer and solidify
- Real one briefly indistinguishable
- Illusions fade slightly

**Special - Evasion Phase (loop during effect):**
- Form becomes highly transparent
- Multiple afterimages
- Harder to track visually
- All orbs merge and separate

**Death Animation (14 frames, 8 FPS, one-shot):**
- Illusions all converge
- Form solidifies briefly
- Shatters into multiple pieces
- Each piece fades separately
- Final orb remains, then cracks
- Mist dissipates to nothing

## Phase Variations

### Phase 1 (100% - 70% HP): "The Oracle Speaks"

**Visual State:**
- Most solid/corporeal
- 3 visible eyes
- 4 floating orbs
- Mist form minimal

**Color Shifts:**
- Greens dominant
- Purple accents subtle
- Clear, readable form

**Added Elements:**
- Prophecy runes occasionally visible
- Calm mist flow
- Eyes track player

### Phase 2 (70% - 35% HP): "Veil of Deception"

**Visual State:**
- Less solid, more ethereal
- 5 eyes visible (some illusory)
- 6 orbs (harder to count)
- More mist, less body

**Color Shifts:**
- Purple increases
- Edges more transparent
- Toxic green more frequent

**Added Elements:**
- Illusion duplicates appear
- Word scramble effects visible
- Mist pools on ground

### Phase 3 (35% - 0% HP): "Desperate Visions"

**Visual State:**
- Almost entirely ethereal
- Eyes everywhere (7+, flickering)
- Orbs erratic, hard to track
- More mist than form

**Color Shifts:**
- Highly saturated chaos
- Colors shift rapidly
- Transparent core visible

**Added Elements:**
- Reality distortion effects
- Multiple phantom forms
- Desperate attack patterns visible

## Pixel-Perfect Details

**Outline Style:**
- Selective outline (not complete)
- Outline fades out at ethereal edges
- Stronger outline on solid elements
- No outline on mist effects

**Anti-Aliasing:**
- Heavy AA on edges (ethereal feel)
- Gradient transparency on mist
- Soft glow effects throughout

**Dithering:**
- Extensive dithering for transparency
- Pattern dithering for mist density
- Gradient dithering for fades

**Transparency Techniques:**
- Multiple opacity layers
- Color key for deepest transparency
- Additive blending for glows

## Reference Mood Board

**Reference 1: Swamp Witches/Hags**
- Take: Mysterious, dangerous wisdom
- Avoid: Ugly/grotesque (should be eerily beautiful)

**Reference 2: Ethereal Spirits**
- Take: Floating, transparent qualities
- Avoid: Too generic ghost appearance

**Reference 3: Medusa/Naga Aesthetics**
- Take: Multiple eyes, serpentine grace
- Avoid: Direct snake body (too literal)

**Reference 4: Warframe Spectral Effects**
- Take: Modern ghost visual techniques
- Avoid: Too technological/sci-fi

**Reference 5: Hollow Knight Dream Bosses**
- Take: Ethereal boss presence
- Avoid: Too abstract or formless

## Implementation Notes

**SVG Structure:**
```
boss_fen_seer.svg
  /mist-background
    /mist-layer-1
    /mist-layer-2
    /mist-layer-3
  /lower-form
    /mist-tendrils
    /poison-drip
  /main-body
    /robes-back
    /torso
    /robes-front
    /corruption-veins
  /arms
    /arm-left
    /arm-right
    /fingers-extended
  /head
    /hood
    /face
    /crown
    /eyes
      /eye-1
      /eye-2
      /eye-3
      /eye-4
      /eye-5
  /floating-orbs
    /orb-1
    /orb-2
    /orb-3
    /orb-4
    /orb-5
    /orb-6
  /effects
    /glow-layers
    /transparency-masks
    /illusion-overlay
```

**Transparency Handling:**
- Use multiple SVG filter effects
- Layer masks for edge fading
- Additive blend mode for glows
- Separate export for game engine blending

---

# 6. BOSS: SUNLORD (Day 20 - Sunfields, Final Boss)

## Overview

| Attribute | Value |
|-----------|-------|
| **Name** | Sunlord |
| **Sprite ID** | `boss_sunlord` |
| **Dimensions** | 128x128 pixels |
| **Category** | Boss (Final) |
| **Region** | Sunfields (Day 20) |
| **Lore** | Blazing warrior king, leader of the Typhos Horde, consumed by righteous fury |
| **Visual Keywords** | Majestic, blazing, kingly, overwhelming, climactic, infernal |

## Silhouette & Shape Language

**Primary Shape:** Inverted triangle (power, dominance, warrior)
**Secondary Shape:** Crown/flame formation (royalty, fire)
**Tertiary Shape:** Sharp angles (aggression, danger)

**Silhouette Description:**
A towering armored warrior wreathed in flames, holding a massive burning blade. Crown of fire rises from the helm. Broad shoulders with war banner or cape flowing behind. The silhouette should immediately read as "final boss" - the most imposing, most dangerous enemy in the game.

**Key Distinguishing Features (visible in silhouette):**
1. Crown of flames rising high
2. Massive flaming sword
3. Broad armored shoulders
4. War banner/cape billowing
5. Imposing warrior stance

**ASCII Silhouette Sketch:**
```
            @@@@@
           @@@@@@@            <- Flame crown
          @@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@   <- Crown + flame
   @@@@@@@@@@@@@@@@@@@@@@@@
      @@@@@@@@@@@@@@@@@@      <- Helm
       @@@@@@@@@@@@@@@@       <- Shoulders
    @@@@@@@@@@@@@@@@@@@@@@@   <- Armor/cape
   @@@@@@@@@@@@@@@@@@@@@@@@@
      @@@@@@@@@@@@@@@@@@      <- Torso
       @@@@@@@@@@@@@@@@
   @@@@ @@@@@@@@@@@@@@@ @@@@  <- Arms/sword
  @@@@@  @@@@@@@@@@@@@  @@@@@
 @@@@@@   @@@@@@@@@@@   @@@@@@<- Weapon
  @@@@@    @@@@@@@@@    @@@@@
           @@@@@@@@@           <- Legs
          @@@@@@@@@@@
         @@@@@@@@@@@@@
        @@@@@@@@@@@@@@@        <- Wide stance
```

## Color Palette

| Role | Color | Hex | Usage |
|------|-------|-----|-------|
| **Primary** | Royal Gold | #ffd700 | Armor, crown base (30%) |
| **Secondary** | Blood Red | #8b0000 | Cape, accent armor (20%) |
| **Accent** | Flame Orange | #ff4500 | Fire effects, hot metal (20%) |
| **Fire Highlight** | Yellow | #ffeb3b | Flame cores, hottest points (10%) |
| **Shadow** | Dark Red | #4a0000 | Deep shadows, cooled metal (10%) |
| **Outline** | Charcoal | #1a1a2e | 3px outline |
| **Armor Dark** | Bronze | #cd7f32 | Armor shadows |

## Anatomy & Structure

**Crown/Flames (40x30 pixels, above head):**
- Burning crown with 5-7 flame points
- Hottest at center (yellow-white)
- Cools to orange at tips
- Constantly animated movement

**Head/Helm (25x25 pixels):**
- Imposing war helm
- T-shaped visor with fire glow within
- Ornate decorations
- Part of armor, not separate

**Shoulders/Cape (60x35 pixels):**
- Massive pauldrons with decorative elements
- War banner/cape flows from one shoulder
- Cape has Typhos Horde sigil
- Fire effects along edges

**Torso (45x40 pixels):**
- Heavy plate armor
- Ornate chest plate with sun motif
- Belt with skulls/trophies
- Glowing core at center (power source)

**Arms (30x50 pixels each):**
- Armored gauntlets
- Main hand holds massive sword
- Off hand: fist, shield, or summoning pose
- Flame effects around both

**Weapon - Burning Blade (35x60 pixels):**
- Enormous two-handed sword
- Blade is on fire (not just hot metal)
- Ornate hilt with sun design
- Trails fire when swung

**Legs (30x40 pixels each):**
- Heavy armored greaves
- Wide powerful stance
- Ground cracking beneath feet
- Fire effects at base

**Proportions:**
- Crown/flames: 25% of height (extends above)
- Helm: 15% of height
- Torso: 30% of height
- Legs: 30% of height
- Sword: 50% of total height
- Shoulder span: 95% of width

## Key Details

**Must-Have Features:**
1. Crown of flames (signature identifier)
2. Massive burning sword (weapon focus)
3. Golden armor with sun motifs
4. War banner/cape with horde sigil
5. Fire effects throughout

**Nice-to-Have Features:**
- Skulls/trophies on belt
- Burning footprints effect
- Aura of heat distortion
- Ancient war medals/decorations

**Unique Identifiers:**
- Final boss, most fire effects
- Most regal/kingly appearance
- Largest weapon of any boss
- Sun imagery throughout

## Lighting & Shading

**Light Source:** Self-illuminated (fire) + top-left secondary

**Shading Levels:**
1. **Hottest** (#ffeb3b) - Flame cores, weapon center
2. **Hot** (#ff4500) - Active flames, hot metal
3. **Warm** (#ffd700) - Illuminated armor
4. **Shadow** (#cd7f32) - Armor recesses
5. **Deep Shadow** (#4a0000) - Coolest shadows

**Special Lighting Effects:**
- **Self-illumination:** Figure lights surrounding area
- **Fire glow:** All edges cast orange/yellow light
- **Molten metal:** Armor has heated appearance
- **Heat distortion:** Air around figure shimmers

**Material Properties:**
- Armor: Golden with warm specular highlights
- Fire: Additive blending, animated
- Cape: Dramatic cloth physics, catches light
- Weapon: Hottest at edge, cooler at hilt

## Animation Considerations

**Idle Animation (8 frames, 6 FPS, loop):**
- Flames constantly animate
- Cape billows
- Breathing motion in armor
- Sword held ready
- Ground particles/heat

**Walk Animation (8 frames, 8 FPS, loop):**
- Powerful, deliberate march
- Ground shakes with steps
- Burning footprints left behind
- Cape trails dramatically

**Attack 1 - Sword Slam (8 frames, 12 FPS, one-shot):**
- Sword raises high
- Flames intensify
- Devastating downward strike
- Fire explosion on impact

**Attack 2 - Burning Ground (6 frames, 10 FPS, one-shot):**
- Sword drags across ground
- Fire spreads in line
- Stays burning (separate effect)

**Attack 3 - War Banner Buff (6 frames, 10 FPS, one-shot):**
- Banner raised high
- Fire intensifies
- Buff aura emanates outward
- Nearby enemies glow

**Special - Summon Marauders (8 frames, 10 FPS, one-shot):**
- Calls with gesture
- Fire portals open
- Warriors emerge
- Sunlord returns to combat

**Death Animation (16 frames, 8 FPS, one-shot):**
- Flames begin to die
- Staggers but refuses to fall
- Sword drops first
- Crown flames extinguish
- Final defiant pose
- Collapses in slow segments
- Flames scatter as embers
- Armor remains, flames gone

## Phase Variations

### Phase 1 (100% - 70% HP): "The Warrior King"

**Visual State:**
- Full regal appearance
- Controlled flames
- Perfect armor
- Composed combat stance

**Color Shifts:**
- Gold dominant
- Flames orange-yellow
- Noble appearance

**Added Elements:**
- War banner visible
- Summoned marauders
- Ground burning effects

### Phase 2 (70% - 35% HP): "Burning Fury"

**Visual State:**
- More aggressive stance
- Flames larger, wilder
- Armor heating up
- Cape starting to burn away

**Color Shifts:**
- More orange/red
- Armor glowing hotter
- Flames more intense

**Added Elements:**
- Enraged mode indicators
- Burning ground persistent
- More fire particles

### Phase 3 (35% - 0% HP): "Inferno Unleashed"

**Visual State:**
- Nearly all flame
- Armor white-hot
- Cape destroyed
- Primal fury

**Color Shifts:**
- White-yellow dominant
- Armor barely visible through flames
- Maximum intensity

**Added Elements:**
- Constant fire damage aura
- Screen distortion effects
- Desperation attacks
- Final stand appearance

## Pixel-Perfect Details

**Outline Style:**
- 3px outline (final boss scale)
- Color varies: dark red to orange based on heat
- Breaks at flame effects (no outline on fire)
- Strongest on silhouette edges

**Anti-Aliasing:**
- AA on armor curves
- No AA on flame shapes (sharp pixel fire)
- Soft glow effects around figure

**Dithering:**
- Fire uses no dithering (clean shapes)
- Armor can use subtle noise texture
- Heat distortion uses pattern dithering

**Fire Rendering:**
- Distinct flame shapes, not gradient blurs
- 4-5 colors per flame
- Animation is shape change, not just color

## Reference Mood Board

**Reference 1: Dark Souls Nameless King**
- Take: Regal warrior presence, final boss gravitas
- Avoid: Too muted colors (we want vibrant fire)

**Reference 2: Sauron (LotR)**
- Take: Imposing armored dark lord silhouette
- Avoid: Pure evil (Sunlord is corrupted, not inherently evil)

**Reference 3: Kingdom Rush Final Bosses**
- Take: Screen presence, readable at game scale
- Avoid: Overly complex detail

**Reference 4: Fire Lord Ozai (Avatar)**
- Take: Fire crown, dramatic fire effects
- Avoid: Too human, too animated style

**Reference 5: Into the Breach Final Boss**
- Take: Clear mechanical readability
- Avoid: Lack of personality

## Implementation Notes

**SVG Structure:**
```
boss_sunlord.svg
  /ground-effects
    /burning-ground
    /heat-distortion
    /shadow
  /cape
    /cape-back-layer
    /banner
    /cape-front-layer
  /legs
    /leg-left
    /leg-right
    /armor-greaves
    /burning-feet
  /torso
    /armor-back
    /armor-front
    /chest-emblem
    /core-glow
    /belt
  /arms
    /arm-left
      /pauldron
      /arm-armor
      /gauntlet
    /arm-right
      /pauldron
      /arm-armor
      /gauntlet
      /sword-hand
  /weapon
    /hilt
    /blade
    /blade-fire
  /head
    /helm
    /visor
    /visor-glow
  /crown-flames
    /flame-1 through /flame-7
  /effects
    /fire-particles
    /heat-aura
    /ember-trails
```

**Phase Intensity System:**
- Fire opacity/scale increases per phase
- Armor emission increases
- Particle count increases
- Screen effects layer at Phase 3

---

# 7. BUILDING: FARM

## Overview

| Attribute | Value |
|-----------|-------|
| **Name** | Farm |
| **Sprite ID** | `building_farm` |
| **Dimensions** | 32x48 pixels |
| **Category** | Production Building |
| **Function** | Food production (+3 food/day) |
| **Worker Slots** | 1 |
| **Visual Keywords** | Rural, productive, growing, peaceful, established |

## Silhouette & Shape Language

**Primary Shape:** Rectangle with peaked roof (traditional building)
**Secondary Shape:** Organic elements (crops, fences)
**Tertiary Shape:** Horizontal lines (plowed fields)

**Silhouette Description:**
A cozy farmhouse with a peaked roof, accompanied by a small fenced crop area. The building should feel warm, productive, and established. A windmill, silo, or grain storage element adds visual interest.

**ASCII Silhouette Sketch:**
```
         @@
        @@@@        <- Roof peak
       @@@@@@
      @@@@@@@@      <- Main roof
     @@@@@@@@@@
    @@@@@@@@@@@@
   @@@@@@@@@@@@@@   <- Upper floor
   @@ @@@@@@@@ @@   <- Windows
   @@@@@@@@@@@@@@   <- Lower floor
   @@@@@ @@ @@@@@   <- Door
   @@@@@@@@@@@@@@   <- Ground floor
  @ @@ @@ @@ @@ @   <- Fence/crops
  @@@@@@@@@@@@@@@   <- Field row
```

## Color Palette

| Role | Color | Hex | Usage |
|------|-------|-----|-------|
| **Primary** | Wood Brown | #8b4513 | Main structure (40%) |
| **Secondary** | Straw Yellow | #daa520 | Roof thatch, hay (25%) |
| **Accent** | Crop Green | #228b22 | Growing crops (15%) |
| **Shadow** | Dark Brown | #5d3a1a | Wood shadows (10%) |
| **Highlight** | Light Wood | #deb887 | Wood highlights (10%) |
| **Outline** | Charcoal | #1a1a2e | 1px outline |

## Anatomy & Structure

**Roof (16x12 pixels):**
- Thatched or wooden shingle appearance
- Peaked center with slight overhang
- Chimney with subtle smoke (optional)
- Weathered texture

**Main Structure (24x20 pixels):**
- Wooden plank construction
- 2 windows with warm glow
- Central door
- Worn but sturdy appearance

**Ground Level/Field (28x12 pixels):**
- Wooden fence posts
- Crop rows visible
- Tilled earth texture
- Small tools or barrels (detail)

**Proportions:**
- Roof: 25% of height
- Main building: 45% of height
- Ground/field: 30% of height
- Width at base: 90% of sprite

## Animation Considerations

**Idle Animation (4 frames, 4 FPS, loop):**
- Crops sway gently
- Smoke from chimney drifts
- Light flickers in window

**Production Active (4 frames, 6 FPS, loop):**
- Crops more vibrant
- Possible worker movement
- Harvest particles

## Implementation Notes

- Simple, iconic design
- Warm, inviting colors
- Clear production type (food/agriculture)
- Worker position near crops

---

# 8. BUILDING: LUMBER MILL

## Overview

| Attribute | Value |
|-----------|-------|
| **Name** | Lumber Mill |
| **Sprite ID** | `building_lumber` |
| **Dimensions** | 32x48 pixels |
| **Category** | Production Building |
| **Function** | Wood production (+3 wood/day) |
| **Worker Slots** | 1 |
| **Visual Keywords** | Industrial, wooden, productive, mechanical |

## Silhouette & Shape Language

**Primary Shape:** Rectangle with sawblade element
**Secondary Shape:** Log pile (resource indicator)
**Tertiary Shape:** Mechanical elements (wheel, saw)

**Silhouette Description:**
A wooden mill building with prominent sawblade or log processing equipment. Log piles surround the structure. The building should feel productive and industrious while maintaining the medieval fantasy aesthetic.

**ASCII Silhouette Sketch:**
```
        @@@@
       @@@@@@       <- Roof
      @@@@@@@@
     @@@@@@@@@@     <- Water wheel or saw
    @@ @@@@@@@ @@
    @@@@@@@@@@@@    <- Main structure
   @@@@ @@@@ @@@@
   @@@@@@@@@@@@@@   <- Work area
   @@@@@@@@@@@@@@@
  @@@@ @@@@@ @@@@@  <- Log piles
  @@@@@@@@@@@@@@@
```

## Color Palette

| Role | Color | Hex | Usage |
|------|-------|-----|-------|
| **Primary** | Raw Wood | #8b4513 | Logs, structure (45%) |
| **Secondary** | Weathered Wood | #a0522d | Planks, details (25%) |
| **Accent** | Metal Gray | #5c5c7a | Sawblade, tools (15%) |
| **Shadow** | Dark Wood | #3d2817 | Shadows (10%) |
| **Highlight** | Light Wood | #deb887 | Fresh cut wood (5%) |

## Anatomy & Structure

**Roof (14x10 pixels):**
- Simple peaked design
- Wooden shingles
- Functional appearance

**Mill Equipment (16x16 pixels):**
- Large sawblade OR water wheel
- Visible mechanical elements
- Wood being processed

**Base Structure (28x14 pixels):**
- Open-sided work area
- Support beams visible
- Log storage

**Log Piles (28x8 pixels):**
- Stacked logs
- Various sizes
- Production indicator

## Animation Considerations

**Idle (4 frames, 4 FPS):**
- Sawblade/wheel rotates slowly
- Dust particles

**Active Production (6 frames, 8 FPS):**
- Faster rotation
- Sawdust flying
- Log being cut

---

# 9. BUILDING: MARKET

## Overview

| Attribute | Value |
|-----------|-------|
| **Name** | Market |
| **Sprite ID** | `building_market` |
| **Dimensions** | 32x48 pixels |
| **Category** | Economy Building |
| **Function** | Gold generation (+5 gold/day), enables trading |
| **Worker Slots** | 1 |
| **Visual Keywords** | Bustling, prosperous, colorful, commercial |

## Silhouette & Shape Language

**Primary Shape:** Open-sided structure (accessibility)
**Secondary Shape:** Awnings/canopies (market stalls)
**Tertiary Shape:** Goods/wares (commerce)

**Silhouette Description:**
An open market stall or bazaar structure with colorful awnings. Displayed goods are visible. The building should feel prosperous, active, and welcoming to trade.

**ASCII Silhouette Sketch:**
```
      @@@@@@@@@@@
     @@@@@@@@@@@@@   <- Awning
    @@@ @@@@@ @@@@@
   @@@@@@@@@@@@@@@   <- Support posts
       @@@@@@@
      @@@@@@@@@      <- Counter
     @@@@@@@@@@@
    @@ @@ @@ @@ @@   <- Displayed goods
   @@@@@@@@@@@@@@@   <- Base/floor
```

## Color Palette

| Role | Color | Hex | Usage |
|------|-------|-----|-------|
| **Primary** | Market Gold | #ffd700 | Accents, coins (30%) |
| **Secondary** | Wood Brown | #8b4513 | Structure (25%) |
| **Accent 1** | Awning Red | #dc143c | Canopy (15%) |
| **Accent 2** | Goods Colors | various | Merchandise (15%) |
| **Shadow** | Dark Wood | #5d3a1a | Shadows (10%) |
| **Highlight** | Light Gold | #ffeb3b | Gold highlights (5%) |

## Anatomy & Structure

**Awning (24x12 pixels):**
- Colorful striped canopy
- Red/gold/white stripes
- Scalloped edge (decorative)

**Counter/Stall (24x14 pixels):**
- Wooden counter
- Displayed goods (coins, goods, scales)
- Open front

**Base (24x12 pixels):**
- Goods crates
- Coin pouches visible
- Stone or wood floor

## Animation Considerations

**Idle (4 frames, 4 FPS):**
- Awning sways slightly
- Coins glint

**Trading Active (4 frames, 6 FPS):**
- More movement
- Gold particles
- Exchange indication

---

# 10. BUILDING: TEMPLE

## Overview

| Attribute | Value |
|-----------|-------|
| **Name** | Temple |
| **Sprite ID** | `building_temple` |
| **Dimensions** | 32x48 pixels |
| **Category** | Support Building |
| **Function** | Healing/support, buffs nearby units |
| **Worker Slots** | 0 |
| **Visual Keywords** | Sacred, glowing, peaceful, protective, divine |

## Silhouette & Shape Language

**Primary Shape:** Vertical with spire (reaching upward, divine)
**Secondary Shape:** Circular/arched (holy, sacred geometry)
**Tertiary Shape:** Symmetrical (balance, order)

**Silhouette Description:**
A small sacred building with a central spire topped by a glowing symbol. Arched doorway and windows. Symmetrical design conveys stability and divine order. Subtle holy glow emanates from the structure.

**ASCII Silhouette Sketch:**
```
          @
         @@@        <- Spire tip
         @@@
        @@@@@       <- Spire
        @@@@@
       @@@@@@@      <- Upper structure
      @@@@@@@@@
     @@@@@@@@@@@    <- Main building
    @@@@ @@@ @@@@   <- Windows
    @@@@@@@@@@@@@   <- Walls
    @@@@@ @ @@@@@   <- Arched door
    @@@@@@@@@@@@@   <- Base
   @@@@@@@@@@@@@@@  <- Foundation
```

## Color Palette

| Role | Color | Hex | Usage |
|------|-------|-----|-------|
| **Primary** | Temple Stone | #c4c4d4 | Main structure (40%) |
| **Secondary** | Sacred Gold | #ffd700 | Accents, symbols (20%) |
| **Accent** | Holy Glow | #ffeb3b | Light effects (15%) |
| **Shadow** | Stone Gray | #5c5c7a | Shadows (15%) |
| **Highlight** | White | #f0f0f5 | Brightest areas (10%) |
| **Outline** | Charcoal | #1a1a2e | 1px outline |

## Anatomy & Structure

**Spire (8x16 pixels):**
- Central tall spire
- Symbol at top (sun, star, or custom)
- Glowing effect

**Main Building (24x20 pixels):**
- Stone construction
- Arched windows with glow
- Symmetrical design
- Ornate details

**Entrance (10x8 pixels):**
- Arched doorway
- Light emanating from within
- Small steps

**Foundation (28x8 pixels):**
- Raised platform
- Decorative stonework
- Sacred geometry patterns

## Animation Considerations

**Idle (6 frames, 4 FPS):**
- Holy glow pulses slowly
- Symbol shimmers
- Light from windows flickers

**Healing Active (6 frames, 8 FPS):**
- Brighter glow
- Healing particles emanate
- Golden light spreads

## Special Effects

- Healing aura effect (separate layer)
- Buff indicator when active
- Connection lines to affected units

---

## Appendix A: Animation Frame Specifications

### Standard Enemy Animations

| Animation | Frames | FPS | Loop | Notes |
|-----------|--------|-----|------|-------|
| Idle | 4 | 8 | Yes | Subtle breathing/movement |
| Walk | 6 | 10 | Yes | Clear directional movement |
| Attack | 4-6 | 12 | No | Quick, impactful |
| Hurt | 2-3 | 16 | No | Fast reaction |
| Death | 6-8 | 10 | No | Dramatic finish |

### Boss Animations

| Animation | Frames | FPS | Loop | Notes |
|-----------|--------|-----|------|-------|
| Idle | 6-8 | 6 | Yes | Impressive presence |
| Walk | 8 | 8 | Yes | Weighty movement |
| Attack 1 | 6-8 | 12 | No | Primary attack |
| Attack 2 | 6-8 | 12 | No | Secondary attack |
| Special | 8-10 | 10 | No | Signature move |
| Phase Transition | 8-12 | 10 | No | Between phases |
| Death | 12-16 | 8 | No | Epic conclusion |

### Building Animations

| Animation | Frames | FPS | Loop | Notes |
|-----------|--------|-----|------|-------|
| Idle | 4 | 4 | Yes | Ambient movement |
| Production Active | 4-6 | 6 | Yes | Worker/process visible |
| Construction | 6-8 | 10 | No | Build animation |
| Destruction | 6-8 | 10 | No | Collapse/damage |

---

## Appendix B: Export Checklist

### Per Sprite Deliverables

- [ ] Source SVG with organized layers
- [ ] PNG export at 1x resolution
- [ ] PNG export at 2x resolution (if needed)
- [ ] Sprite sheet for animations
- [ ] Separate effect layers (glows, particles)
- [ ] Shadow as separate element
- [ ] Phase variants (bosses only)
- [ ] Color palette documentation

### Quality Verification

- [ ] Silhouette readable at 50% zoom
- [ ] Colors match palette specification
- [ ] Lighting direction consistent (top-left)
- [ ] Animation loops smoothly
- [ ] Outline weight appropriate
- [ ] No anti-aliasing artifacts
- [ ] Transparency correct
- [ ] File naming follows convention

---

## Appendix C: File Naming Convention

```
[category]_[name]_[variant]_[state].png

Categories:
- enemy_
- boss_
- building_
- effect_
- ui_

Examples:
- enemy_healer_idle_01.png
- boss_forest_guardian_phase2_attack.png
- building_farm_production.png
- enemy_raider_walk_sheet.png
```

---

## Document Revision History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2026-01-12 | Initial specification document |

---

*This document is property of the Keyboard Defense project. All specifications are subject to revision as development progresses.*
