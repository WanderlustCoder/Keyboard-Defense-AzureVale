# Map & Environment Asset Specifications

## Design Philosophy
- **Readability**: Gameplay lanes and paths clearly visible
- **Atmosphere**: Environment tells a story, enhances mood
- **Performance**: Tileable assets minimize memory usage
- **Modularity**: Mix and match for varied layouts

---

## TILE SYSTEM

### Tile Standards
```
Base Tile:        16x16 pixels
Large Tile:       32x32 pixels
Half Tile:        16x8 pixels
Autotile Set:     16 variations (4-bit blob)
Animated Tile:    Multiple frames, same dimensions
```

### Autotile Template
```
┌────┬────┬────┬────┐
│ TL │ T  │ TR │ ISO│  Row 1: Corners + Isolated
├────┼────┼────┼────┤
│ L  │ C  │ R  │ TLR│  Row 2: Sides + Top variants
├────┼────┼────┼────┤
│ BL │ B  │ BR │ LR │  Row 3: Bottom corners + Vert
├────┼────┼────┼────┤
│ TB │TBL │TBR │TBLR│  Row 4: Full connections
└────┴────┴────┴────┘
```

---

## TERRAIN TYPES

### Grass Terrain (tile_grass_*)

#### Basic Grass (tile_grass)
**Dimensions**: 16x16
**Variations**: 4 (random placement)

**Color Palette**:
```
Base:         #27ae60
Dark:         #1e8449
Light:        #2ecc71
Highlight:    #82e0aa
```

---

#### Grass with Flowers (tile_grass_flowers)
**Dimensions**: 16x16
**Variations**: 4

**Flower Colors**:
```
Red:          #e74c3c
Yellow:       #f4d03f
Blue:         #3498db
White:        #fdfefe
```

---

#### Tall Grass (tile_grass_tall)
**Dimensions**: 16x24 (extends upward)
**Frames**: 4 (wind sway)
**Duration**: 2000ms loop

---

### Dirt Terrain (tile_dirt_*)

#### Basic Dirt (tile_dirt)
**Dimensions**: 16x16
**Variations**: 4

**Color Palette**:
```
Base:         #a04000
Dark:         #6e2c00
Light:        #dc7633
Pebbles:      #5d6d7e
```

---

#### Dirt Path (tile_dirt_path)
**Dimensions**: 16x16
**Autotile**: Yes (16 variations)

**Features**:
- Worn center line
- Edge grass tufts
- Footprint details (subtle)

---

#### Mud (tile_mud)
**Dimensions**: 16x16
**Frames**: 2 (subtle ripple)
**Duration**: 1000ms

**Color Palette**:
```
Base:         #6e2c00
Wet:          #4a1c00
Puddle:       #5d4e37 (darker)
```

---

### Stone Terrain (tile_stone_*)

#### Cobblestone (tile_stone_cobble)
**Dimensions**: 16x16
**Autotile**: Yes

**Color Palette**:
```
Light:        #85929e
Medium:       #5d6d7e
Dark:         #34495e
Mortar:       #1a252f
```

---

#### Castle Floor (tile_stone_castle)
**Dimensions**: 16x16
**Variations**: 4

**Features**:
- Large flagstones
- Crack details (variation 3-4)
- Moss in corners (variation 4)

---

#### Broken Stone (tile_stone_broken)
**Dimensions**: 16x16
**Variations**: 4

**Features**:
- Cracked tiles
- Missing sections
- Rubble pieces

---

### Water Terrain (tile_water_*)

#### Still Water (tile_water)
**Dimensions**: 16x16
**Frames**: 4
**Duration**: 800ms loop

**Color Palette**:
```
Deep:         #2980b9
Surface:      #3498db
Highlight:    #85c1e9
Foam:         #d6eaf8
```

---

#### River Flow (tile_water_river)
**Dimensions**: 16x16
**Frames**: 8
**Duration**: 1200ms loop
**Direction**: Configurable (4 directions)

---

#### Waterfall (tile_waterfall)
**Dimensions**: 16x32
**Frames**: 6
**Duration**: 600ms loop

**Components**:
- Falling water
- Splash at base
- Mist particles

---

#### Water Edge (tile_water_edge)
**Dimensions**: 16x16
**Autotile**: Yes
**Frames**: 4 (shore lapping)

---

### Special Terrain

#### Lava (tile_lava)
**Dimensions**: 16x16
**Frames**: 6
**Duration**: 1000ms loop

**Color Palette**:
```
Hot:          #f4d03f
Medium:       #f39c12
Cool:         #e74c3c
Crust:        #922b21
```

**Effects**:
- Ember particles rising
- Glow applied to nearby tiles

---

#### Ice/Snow (tile_ice)
**Dimensions**: 16x16
**Frames**: 2 (shimmer)

**Color Palette**:
```
Ice:          #aed6f1
Frost:        #d6eaf8
Highlight:    #fdfefe
Crack:        #5dade2
```

---

#### Void/Abyss (tile_void)
**Dimensions**: 16x16
**Frames**: 4
**Duration**: 2000ms

**Visual**:
- Pure black center
- Purple wisp edges
- Subtle star sparkles

---

## PATH SYSTEM

### Enemy Path (path_enemy)

#### Path Markers
**Dimensions**: 16x16

**Types**:
| Marker | Visual | Purpose |
|--------|--------|---------|
| path_start | Green glow | Spawn point |
| path_straight | Arrow lines | Direction |
| path_corner | Curved arrow | Turn point |
| path_end | Red glow | Castle entrance |

---

#### Path Decoration
**Dimensions**: 16x16
**Purpose**: Break up monotony

**Options**:
- Worn grass along path
- Footprints in dirt
- Scattered pebbles
- Track marks

---

### Tower Placement Zones

#### Valid Slot (slot_tower_valid)
**Dimensions**: 16x16
**State**: Available for building

**Visual**:
- Green subtle overlay
- Grid pattern
- Pulse on hover

**Color**: #27ae60 (20% opacity)

---

#### Invalid Slot (slot_tower_invalid)
**Dimensions**: 16x16
**State**: Cannot build here

**Visual**:
- Red X overlay
- Gray-out

**Color**: #e74c3c (30% opacity)

---

#### Occupied Slot (slot_tower_occupied)
**Dimensions**: 16x16
**State**: Tower already placed

**Visual**: None (tower covers)

---

## DECORATIVE ELEMENTS

### Trees (deco_tree_*)

#### Deciduous Tree (deco_tree_oak)
**Dimensions**: 24x32
**Variations**: 3

**Color Palette**:
```
Trunk:        #6e2c00
Trunk Dark:   #4a1c00
Leaves:       #27ae60
Leaves Light: #2ecc71
Leaves Dark:  #1e8449
```

---

#### Pine Tree (deco_tree_pine)
**Dimensions**: 20x36
**Variations**: 3

**Color Palette**:
```
Trunk:        #6e2c00
Needles:      #1e8449
Needles Dark: #145a32
Snow (opt):   #fdfefe
```

---

#### Dead Tree (deco_tree_dead)
**Dimensions**: 24x32
**Variations**: 2

**Color Palette**:
```
Trunk:        #5d6d7e
Branches:     #85929e
```

---

#### Stump (deco_stump)
**Dimensions**: 16x12
**Variations**: 2

---

### Rocks (deco_rock_*)

#### Small Rock (deco_rock_small)
**Dimensions**: 8x8
**Variations**: 4

---

#### Medium Rock (deco_rock_medium)
**Dimensions**: 16x12
**Variations**: 3

---

#### Large Rock (deco_rock_large)
**Dimensions**: 24x20
**Variations**: 2

---

#### Rock Formation (deco_rock_cluster)
**Dimensions**: 32x24
**Variations**: 2

---

### Vegetation (deco_plant_*)

#### Bush (deco_bush)
**Dimensions**: 16x12
**Variations**: 3

---

#### Flower Patch (deco_flowers)
**Dimensions**: 16x8
**Variations**: 4 (different colors)
**Frames**: 2 (sway)

---

#### Mushrooms (deco_mushroom)
**Dimensions**: 12x12
**Variations**: 3

**Colors**:
```
Red Mushroom:   #e74c3c, #fdfefe dots
Brown:          #6e2c00, #a04000
Glowing:        #9b59b6, #d2b4de
```

---

#### Vines (deco_vines)
**Dimensions**: 16x32 (hangs from above)
**Frames**: 4 (sway)

---

### Props (deco_prop_*)

#### Fence Post (deco_fence_post)
**Dimensions**: 8x16

---

#### Fence Section (deco_fence)
**Dimensions**: 16x16
**Autotile**: Yes (horizontal connections)

---

#### Crates (deco_crate)
**Dimensions**: 16x16
**Variations**: 2 (intact, broken)

---

#### Barrels (deco_barrel)
**Dimensions**: 12x16
**Variations**: 2

---

#### Campfire (deco_campfire)
**Dimensions**: 16x16
**Frames**: 6
**Duration**: 400ms loop

**Components**:
- Log base
- Flickering flames
- Ember particles

---

#### Torch (deco_torch)
**Dimensions**: 8x24
**Frames**: 4
**Duration**: 300ms loop

---

#### Sign Post (deco_sign)
**Dimensions**: 16x20
**Variations**: 3 (arrow, text, blank)

---

#### Wagon (deco_wagon)
**Dimensions**: 32x24
**Variations**: 2 (intact, wrecked)

---

## STRUCTURES

### Castle Elements

#### Castle Wall (struct_castle_wall)
**Dimensions**: 16x32
**Autotile**: Yes (horizontal)

**Features**:
- Stone texture
- Battlements on top
- Window slots (variation)
- Damage states

---

#### Castle Tower (struct_castle_tower)
**Dimensions**: 32x48

**Features**:
- Conical roof
- Window
- Flag pole

---

#### Castle Gate (struct_castle_gate)
**Dimensions**: 48x40

**States**:
- Open
- Closed
- Damaged

---

#### Castle Keep (struct_castle_main)
**Dimensions**: 64x80

**Features**:
- Main structure
- Multiple towers
- Throne room implied
- Damage progression (HP visual)

---

### Village Elements

#### House Small (struct_house_small)
**Dimensions**: 24x28

---

#### House Large (struct_house_large)
**Dimensions**: 32x36

---

#### Market Stall (struct_market)
**Dimensions**: 24x20
**Variations**: 3 (food, weapons, potions)

---

#### Well (struct_well)
**Dimensions**: 16x20

---

#### Bridge (struct_bridge)
**Dimensions**: 48x16 (span)
**Variations**: Wood, Stone

---

### Ruins

#### Ruined Wall (struct_ruin_wall)
**Dimensions**: 16x24
**Variations**: 3

---

#### Ruined Tower (struct_ruin_tower)
**Dimensions**: 24x32

---

#### Collapsed Building (struct_ruin_building)
**Dimensions**: 32x24

---

## BACKGROUNDS

### Sky Layers

#### Day Sky (bg_sky_day)
**Dimensions**: 320x180 (tileable horizontal)

**Color Gradient**:
```
Top:          #5dade2
Middle:       #85c1e9
Horizon:      #f9e79f
```

---

#### Sunset Sky (bg_sky_sunset)
**Dimensions**: 320x180

**Color Gradient**:
```
Top:          #2c3e50
Middle:       #e74c3c
Horizon:      #f39c12
```

---

#### Night Sky (bg_sky_night)
**Dimensions**: 320x180

**Color Gradient**:
```
Top:          #1a252f
Middle:       #2c3e50
Horizon:      #34495e
```

**Features**:
- Stars (twinkling)
- Moon (phase options)
- Occasional shooting star

---

#### Storm Sky (bg_sky_storm)
**Dimensions**: 320x180
**Frames**: 4 (cloud drift)

**Color Gradient**:
```
Top:          #1a252f
Middle:       #34495e
Horizon:      #5d6d7e
```

**Features**:
- Rolling clouds
- Lightning flashes

---

### Parallax Layers

#### Mountains Far (bg_mountains_far)
**Dimensions**: 640x120
**Scroll Speed**: 0.1x

**Color**: Desaturated, foggy (#5d6d7e)

---

#### Mountains Near (bg_mountains_near)
**Dimensions**: 640x160
**Scroll Speed**: 0.3x

**Color**: More saturated (#34495e)

---

#### Forest Line (bg_forest)
**Dimensions**: 640x80
**Scroll Speed**: 0.5x

**Color**: Dark silhouette (#1e8449)

---

#### Clouds (bg_clouds)
**Dimensions**: 320x60
**Scroll Speed**: 0.8x
**Frames**: 4

---

## BIOME THEMES

### Grassland Biome
```
Ground:       tile_grass, tile_dirt_path
Decorations:  Trees, flowers, bushes
Structures:   Village elements
Sky:          Day sky, clouds
Colors:       Greens, browns, blues
Mood:         Peaceful, tutorial
```

### Forest Biome
```
Ground:       tile_grass (darker), tile_dirt
Decorations:  Dense trees, mushrooms, vines
Structures:   Ruins, clearings
Sky:          Filtered light
Colors:       Deep greens, browns
Mood:         Mysterious, mid-game
```

### Castle Biome
```
Ground:       tile_stone_cobble, tile_stone_castle
Decorations:  Torches, banners, armor stands
Structures:   Castle elements, walls
Sky:          Any (inside is torchlit)
Colors:       Grays, golds, blues
Mood:         Fortified, late-game
```

### Volcanic Biome
```
Ground:       tile_stone (charred), tile_lava
Decorations:  Dead trees, rock formations
Structures:   Ruins, lava flows
Sky:          Red/orange tinted, ash particles
Colors:       Reds, oranges, blacks
Mood:         Dangerous, boss areas
```

### Winter Biome
```
Ground:       tile_ice, tile_snow (white grass)
Decorations:  Snow pines, frozen elements
Structures:   Frozen ruins
Sky:          Gray, snow particles
Colors:       Whites, blues, grays
Mood:         Cold, challenging
```

### Corrupted Biome
```
Ground:       tile_void edges, corrupted grass
Decorations:  Dead vegetation, crystal growths
Structures:   Twisted versions
Sky:          Purple tinted, dark
Colors:       Purples, blacks, sickly greens
Mood:         Endgame, final boss
```

---

## MAP OBJECT LAYERS

### Layer Order (back to front)
```
Layer 0: Sky background
Layer 1: Parallax far (mountains)
Layer 2: Parallax mid (hills)
Layer 3: Parallax near (forest line)
Layer 4: Ground tiles
Layer 5: Ground decorations (flowers, pebbles)
Layer 6: Paths
Layer 7: Large decorations (trees, rocks)
Layer 8: Structures
Layer 9: Tower slots
Layer 10: Towers
Layer 11: Enemies
Layer 12: Effects
Layer 13: UI elements
Layer 14: Weather overlays
```

---

## LIGHTING SYSTEM

### Time of Day Overlays

#### Dawn Filter (overlay_dawn)
```
Color: #f9e79f (10% opacity)
Effect: Warm tint
```

#### Day Filter (overlay_day)
```
Color: None (default)
```

#### Dusk Filter (overlay_dusk)
```
Color: #e74c3c (15% opacity)
Effect: Orange-red tint
```

#### Night Filter (overlay_night)
```
Color: #2c3e50 (30% opacity)
Effect: Blue-dark tint
Light sources glow brighter
```

---

### Point Lights

#### Torch Light (light_torch)
```
Radius: 48px
Color: #f39c12 (50% opacity)
Flicker: Yes
```

#### Campfire Light (light_campfire)
```
Radius: 64px
Color: #f39c12 (60% opacity)
Flicker: Yes (larger variation)
```

#### Magic Light (light_magic)
```
Radius: 32px
Color: Varies (#9b59b6, #3498db, etc.)
Pulse: Yes
```

---

## WEATHER SYSTEMS

### Rain System
```
Particles: Diagonal lines
Density: Low, Medium, High options
Ground: Puddle tiles appear
Sound: Rain ambient
Effect: Slight blue tint overlay
```

### Snow System
```
Particles: White dots, varied sizes
Movement: Drifting, slow fall
Ground: Snow accumulation (optional)
Sound: Wind, muffled ambient
Effect: White tint overlay
```

### Fog System
```
Layers: 2-3 scrolling fog layers
Opacity: 20-40%
Coverage: Ground level to mid-screen
Effect: Visibility reduction
```

### Storm System
```
Rain: Heavy
Lightning: Flashes every 5-10s
Thunder: Sound delay based on "distance"
Effect: Dark overlay, dramatic
```

---

## ANIMATION STANDARDS

### Tile Animations
| Type | Frames | Duration |
|------|--------|----------|
| Water ripple | 4 | 800ms |
| Lava flow | 6 | 1000ms |
| Tall grass sway | 4 | 2000ms |
| Torch flicker | 4 | 300ms |
| Flag wave | 6 | 800ms |

### Decoration Animations
| Type | Frames | Duration |
|------|--------|----------|
| Tree sway | 4 | 3000ms |
| Flower bob | 2 | 1500ms |
| Water fountain | 6 | 600ms |
| Campfire | 6 | 400ms |
| Windmill | 8 | 2000ms |

