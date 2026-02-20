# Region Specifications

**Created:** 2026-01-08

Detailed specifications for each region in the Greater Realm of Keystonia.

---

## Region Template

Each region follows this specification format:

```
Region ID, Name, Land
├── Theme & Atmosphere
├── Geography & Terrain
├── Zones (6-10 areas)
├── POIs (discoverable locations)
├── NPCs (characters)
├── Enemies (region-specific)
├── Vocabulary Theme (word lists)
├── Typing Challenge Focus
├── Boss Encounter
├── Secrets & Hidden Content
└── Visual & Audio Direction
```

---

## THE VERDANT HEARTLAND

### Region: Evergrove Forest

**ID:** `evergrove`
**Land:** Verdant Heartland
**Theme:** Ancient, nurturing woodland - the cradle of typing mastery

#### Geography & Terrain

```
┌────────────────────────────────────────┐
│          EVERGROVE FOREST              │
│                                        │
│    [Ancient Oak]     [Elder's Glade]   │
│         ▲                ▲             │
│         │                │             │
│    [Mossy Hollow]───[Whisper Grove]    │
│         │                │             │
│         ▼                ▼             │
│    [Grove Guardian]  [Forest Gate]     │
│         Den              ▲             │
│                          │             │
│                    TO CASTLE           │
└────────────────────────────────────────┘
```

**Terrain Distribution:**
| Terrain | Percentage | Notes |
|---------|------------|-------|
| Dense Forest | 40% | Tall oaks, dappled light |
| Forest Path | 25% | Worn trails through woods |
| Clearing | 15% | Open glades, meadows |
| Stream | 10% | Small brooks, crossing points |
| Ancient Grove | 10% | Massive trees, mystical feel |

#### Zones

| Zone ID | Name | Description | Lesson Tie-In |
|---------|------|-------------|---------------|
| `forest-gate` | Forest Gate | Entry point, tutorial area | home_row_1 |
| `whisper-grove` | Whisper Grove | Quiet practice space | home_row_2 |
| `mossy-hollow` | Mossy Hollow | Hidden training spot | home_row_words |
| `elders-glade` | Elder's Glade | Lyra's teaching ground | reach_row_1 |
| `ancient-oak` | Ancient Oak Circle | Sacred gathering place | sentence_basics |
| `grove-guardian-den` | Grove Guardian's Den | First boss arena | boss_grove_guardian |

#### POIs

| POI ID | Name | Type | Event |
|--------|------|------|-------|
| `poi_wagon` | Abandoned Wagon | Discovery | Find old supplies, +10 gold |
| `poi_shrine` | Quiet Shrine | Lore | Learn history of Elder Lyra |
| `poi_herbs` | Herb Patch | Resource | Gather healing herbs |
| `poi_hollow` | Ancient Hollow | Secret | Hidden passage to Elder's Sanctuary |
| `poi_beehives` | Wild Beehives | Risk/Reward | Risk sting for honey (resource) |
| `poi_spring` | Crystal Spring | Healing | Restore health, typing buff |
| `poi_mushroom` | Fairy Ring | Mystery | Random beneficial effect |
| `poi_treehouse` | Abandoned Treehouse | Discovery | Old journal, lore fragment |
| `poi_statue` | Moss-Covered Statue | Lore | History of first typists |
| `poi_cache` | Ranger's Cache | Discovery | Hidden supplies |

#### NPCs

| NPC ID | Name | Role | Location |
|--------|------|------|----------|
| `npc_lyra` | Elder Lyra | Mentor, Main Guide | Elder's Glade |
| `npc_ranger` | Ranger Thorne | Scout, Quest Giver | Forest Gate |
| `npc_herbalist` | Willow the Herbalist | Shop, Healing | Whisper Grove |
| `npc_spirit` | Forest Spirit | Lore, Hints | Ancient Oak (night only) |

#### Enemies

| Enemy Type | Variants | Behavior |
|------------|----------|----------|
| Forest Scout | Basic, Swift | Standard approach |
| Bramble Creeper | Thorned, Giant | Slow but tough |
| Shadow Sprite | Flickering, Dark | Erratic movement |
| Corrupted Deer | Tainted, Frenzied | Fast, low HP |

#### Vocabulary Theme

**Word Categories:**
- Nature: tree, leaf, root, bark, moss, fern, oak, pine, grove, glade
- Animals: deer, owl, fox, hare, bird, wolf, bear, squirrel
- Actions: grow, bloom, rustle, whisper, shelter, nurture
- Concepts: peace, wisdom, ancient, sacred, nature, life

**Sentence Themes:**
- "The ancient oak stands tall in the glade."
- "Elder Lyra teaches beneath the whispering leaves."
- "The forest knows all who walk its paths."

#### Typing Challenge Focus

**Primary:** Accuracy (building good habits)
**Secondary:** Rhythm (steady, consistent pace)

**Target Metrics:**
- Accuracy: 85%+
- WPM: 25-35
- Consistency: High

#### Boss: Grove Guardian

**Name:** Grove Guardian
**Type:** Nature Elemental
**Phase 1:** Slow but accurate - long words, strict accuracy requirement
**Phase 2:** Faster spawns - shorter words, increased speed
**Phase 3:** Mixed assault - alternating patterns

**Defeat Reward:**
- Guardian's Blessing (accuracy +5% for 3 battles)
- Unlock Citadel path

#### Secrets

| Secret | Trigger | Reward |
|--------|---------|--------|
| Elder's Sanctuary | 100% home row mastery | Special training room |
| Spirit's Gift | Visit Ancient Oak at midnight | Rare word pack |
| Ranger's Trust | Complete 5 POI discoveries | Secret cache location |

#### Visual Direction

**Color Palette:**
- Primary: Forest Green (#228B22)
- Secondary: Bark Brown (#8B4513)
- Accent: Dappled Gold (#FFD700)
- UI Tint: Soft Green

**Atmosphere:**
- Dappled sunlight through canopy
- Floating pollen/seeds particles
- Gentle fog in early morning
- Fireflies at dusk

---

### Region: Sunfields Plains

**ID:** `sunfields`
**Land:** Verdant Heartland
**Theme:** Open, bright farmland - speed and clarity

#### Geography & Terrain

```
┌────────────────────────────────────────┐
│          SUNFIELDS PLAINS              │
│                                        │
│  [Sunlord]────[Champion's Field]       │
│   Arena              │                 │
│     │          [Blazing Arena]         │
│     │                │                 │
│  [Valor]───────[Windmill Heights]      │
│  Grounds             │                 │
│     │          [Harvest Road]          │
│     │                │                 │
│  [Golden Meadow]────[Farmer's Road]    │
│         │                              │
│    TO EVERGROVE                        │
└────────────────────────────────────────┘
```

**Terrain Distribution:**
| Terrain | Percentage | Notes |
|---------|------------|-------|
| Open Plains | 45% | Wheat fields, grass |
| Farm Road | 20% | Dirt paths, cart tracks |
| Farmstead | 15% | Buildings, fences |
| Orchard | 10% | Fruit trees |
| Water (irrigation) | 10% | Canals, ponds |

#### Zones

| Zone ID | Name | Description | Lesson Tie-In |
|---------|------|-------------|---------------|
| `farmers-road` | Farmer's Road | Entry from Evergrove | full_alpha |
| `golden-meadow` | Golden Meadow | Open practice field | speed_alpha |
| `harvest-road` | Harvest Road | Busy trade route | biome_sunfields |
| `windmill-heights` | Windmill Heights | Elevated viewpoint | gauntlet_speed |
| `champions-road` | Champion's Road | Competition path | time_trial_sprint |
| `blazing-arena` | Blazing Arena | Speed tournament | gauntlet_speed |
| `valor-grounds` | Valor Grounds | Training camp | sentence_common |
| `sunlord-arena` | Sunlord Arena | Final boss | boss_sunlord |

#### POIs

| POI ID | Name | Type | Event |
|--------|------|------|-------|
| `poi_windmill` | Old Windmill | Discovery | Grain supplies, crafting |
| `poi_orchard` | Golden Orchard | Resource | Gather fruit |
| `poi_arena` | Training Arena | Challenge | Speed trial mini-game |
| `poi_monument` | Victory Monument | Lore | Champions of old |
| `poi_market` | Traveling Market | Shop | Random goods |
| `poi_fountain` | Blessed Fountain | Healing | Full restore |
| `poi_scarecrow` | Dancing Scarecrow | Mystery | Random buff |
| `poi_barn` | Abandoned Barn | Discovery | Hidden supplies |
| `poi_well` | Wishing Well | Gamble | Throw gold for luck |
| `poi_millstone` | Ancient Millstone | Lore | History of farming |

#### NPCs

| NPC ID | Name | Role | Location |
|--------|------|------|----------|
| `npc_farmer` | Old Farmer Giles | Quest Giver | Farmer's Road |
| `npc_champion` | Champion Vera | Speed Trainer | Blazing Arena |
| `npc_merchant` | Marco the Merchant | Traveling Shop | Random |
| `npc_child` | Swift Sarah | Challenger | Champion's Road |

#### Enemies

| Enemy Type | Variants | Behavior |
|------------|----------|----------|
| Plains Runner | Swift, Dust | Very fast, fragile |
| Harvest Golem | Straw, Iron | Slow, durable |
| Sun Sprite | Radiant, Blazing | Erratic, speed-based |
| Wild Boar | Charging, Frenzied | Direct assault |

#### Vocabulary Theme

**Word Categories:**
- Farming: wheat, corn, plow, harvest, seed, grain, barn, silo
- Weather: sun, wind, cloud, rain, storm, breeze, sky, dawn
- Speed: fast, quick, swift, rush, dash, sprint, race, fleet
- Growth: grow, bloom, ripen, flourish, thrive, yield

**Sentence Themes:**
- "The sun rises over golden fields of wheat."
- "Swift fingers harvest words like grain."
- "Champions are forged in the blazing arena."

#### Typing Challenge Focus

**Primary:** Speed (pushing WPM limits)
**Secondary:** Endurance (sustained performance)

**Target Metrics:**
- Accuracy: 80%+
- WPM: 40-60
- Consistency: Medium (burst speed valued)

#### Boss: Sunlord Champion

**Name:** Sunlord Champion
**Type:** Speed Master
**Phase 1:** Rapid short words - 2-3 letter bursts
**Phase 2:** Sustained barrage - no breaks between words
**Phase 3:** Blinding speed - visual effects, max speed test

**Defeat Reward:**
- Sunlord's Swiftness (speed +10% for 3 battles)
- Unlock Outer Frontier path

#### Secrets

| Secret | Trigger | Reward |
|--------|---------|--------|
| Speed Demon's Trial | 60 WPM on any lesson | Hidden speed course |
| Farmer's Gratitude | Complete all Sunfields POIs | Endless harvest mode |
| Solar Blessing | Visit fountain at noon | Permanent +2 WPM |

#### Visual Direction

**Color Palette:**
- Primary: Golden Yellow (#FFD700)
- Secondary: Sky Blue (#87CEEB)
- Accent: Wheat Brown (#DEB887)
- UI Tint: Warm Gold

**Atmosphere:**
- Bright, clear sunlight
- Waving wheat particles
- Dust motes in air
- Long shadows at dawn/dusk

---

## THE CENTRAL KINGDOM

### Region: Stonepass Mountains

**ID:** `stonepass`
**Land:** Central Kingdom
**Theme:** Rugged peaks, dwarven heritage - endurance and precision

#### Geography & Terrain

```
┌────────────────────────────────────────┐
│        STONEPASS MOUNTAINS             │
│                                        │
│         [Frost Peak]                   │
│              │                         │
│    [Citadel Warden]──[Summit Trail]    │
│         Tower         │                │
│              │   [Crystal Mine]        │
│         [Dwarven Forge]                │
│              │                         │
│    [Miner's Descent]──[Mountain Cairn] │
│              │                         │
│       [Stone Gate Pass]                │
│              │                         │
│         TO HEARTLAND                   │
└────────────────────────────────────────┘
```

**Terrain Distribution:**
| Terrain | Percentage | Notes |
|---------|------------|-------|
| Mountain Rock | 35% | Impassable cliffs |
| Mountain Path | 25% | Narrow trails |
| Cave Entrance | 15% | Mine entrances |
| Snow/Ice | 15% | Higher elevations |
| Forest (alpine) | 10% | Sparse pines |

#### Zones

| Zone ID | Name | Description | Lesson Tie-In |
|---------|------|-------------|---------------|
| `stone-gate-pass` | Stone Gate Pass | Mountain entry | reach_row_2 |
| `miners-descent` | Miner's Descent | Deep tunnels | numbers_1 |
| `dwarven-forge` | Dwarven Forge | Ancient smithy | symbols_1 |
| `crystal-mine` | Crystal Mine | Gem deposits | punctuation_1 |
| `summit-trail` | Summit Trail | High path | gauntlet_endurance |
| `frost-peak` | Frost Peak | Icy summit | precision_silver |
| `mountain-cairn` | Mountain Cairn | Ancient marker | sentence_intermediate |
| `citadel-warden-tower` | Citadel Warden's Tower | Boss arena | boss_citadel_warden |

#### POIs

| POI ID | Name | Type | Event |
|--------|------|------|-------|
| `poi_quarry` | Abandoned Quarry | Resource | Stone gathering |
| `poi_watchtower` | Crumbling Watchtower | Discovery | Vista, map reveal |
| `poi_cave` | Mountain Cave | Exploration | Deeper dungeon |
| `poi_cairn` | Ancient Cairn | Lore | Dwarven history |
| `poi_forge` | Dwarven Forge | Crafting | Equipment upgrade |
| `poi_vein` | Crystal Vein | Resource | Rare crystals |
| `poi_shrine_mountain` | Peak Shrine | Blessing | Endurance buff |
| `poi_camp` | Miner's Camp | Rest | Healing, save point |
| `poi_bridge` | Rope Bridge | Risk | Shortcut or fall |
| `poi_echo` | Echo Chamber | Mystery | Voice puzzle |

#### NPCs

| NPC ID | Name | Role | Location |
|--------|------|------|----------|
| `npc_dwarf_elder` | Elder Grimstone | Lore Keeper | Dwarven Forge |
| `npc_miner` | Picks McGee | Quest Giver | Miner's Descent |
| `npc_hermit` | Mountain Hermit | Trainer | Frost Peak |
| `npc_ghost_dwarf` | Spirit of Thorin | Secret NPC | Crystal Mine (night) |

#### Enemies

| Enemy Type | Variants | Behavior |
|------------|----------|----------|
| Stone Golem | Lesser, Greater | Slow, very durable |
| Cave Bat | Swarming, Giant | Fast, group attacks |
| Frost Wolf | Arctic, Alpha | Pack tactics |
| Crystal Spider | Gem, Prismatic | Ambush |

#### Vocabulary Theme

**Word Categories:**
- Mining: ore, gem, crystal, vein, shaft, tunnel, pick, cart
- Stone: rock, boulder, cliff, peak, summit, granite, slate
- Forge: hammer, anvil, forge, smith, iron, steel, craft
- Endurance: climb, ascend, persist, endure, steady, firm

#### Typing Challenge Focus

**Primary:** Endurance (long sessions, no breaks)
**Secondary:** Precision (numbers, symbols)

**Target Metrics:**
- Accuracy: 88%+
- WPM: 35-45
- Consistency: Very High

#### Boss: Citadel Warden

**Name:** Citadel Warden
**Type:** Stone Guardian
**Phase 1:** Fortress defense - must maintain 90% accuracy
**Phase 2:** Siege mode - very long words, endurance test
**Phase 3:** Crumbling assault - increasing speed as armor breaks

**Defeat Reward:**
- Warden's Fortitude (endurance +20%)
- Unlock Citadel access

---

### Region: Mistfen Marshes

**ID:** `mistfen`
**Land:** Central Kingdom
**Theme:** Mysterious swamps - tricky patterns, hidden dangers

#### Geography & Terrain

```
┌────────────────────────────────────────┐
│          MISTFEN MARSHES               │
│                                        │
│  [Fen Seer]────[Sunken Temple]         │
│   Throne            │                  │
│      │        [Ancient Pier]           │
│      │              │                  │
│  [Reed Maze]───[Forgotten Graveyard]   │
│      │              │                  │
│  [Hermit's Hut]──[Weeping Willows]     │
│      │              │                  │
│  [Sunken Ruins]──[Rotting Dock]        │
│      │                                 │
│   TO CITADEL                           │
└────────────────────────────────────────┘
```

**Terrain Distribution:**
| Terrain | Percentage | Notes |
|---------|------------|-------|
| Swamp Water | 30% | Impassable murky water |
| Swamp Shallows | 25% | Slow movement |
| Marsh Path | 20% | Raised walkways |
| Dead Trees | 15% | Atmospheric, some passable |
| Ruins | 10% | Ancient structures |

#### Zones

| Zone ID | Name | Description | Lesson Tie-In |
|---------|------|-------------|---------------|
| `rotting-dock` | Rotting Dock | Entry point | biome_mistfen |
| `weeping-willows` | Weeping Willows | Eerie grove | punctuation_1 |
| `hermits-hut` | Hermit's Hut | Mysterious dwelling | sentence_home_row |
| `sunken-ruins` | Sunken Ruins | Flooded temple | symbols_1 |
| `reed-maze` | Reed Maze | Confusing paths | consonant_clusters |
| `graveyard` | Forgotten Graveyard | Haunted grounds | double_letters |
| `ancient-pier` | Ancient Pier | Old harbor | punctuation_2 |
| `sunken-temple` | Sunken Temple | Half-submerged shrine | symbols_2 |
| `fen-seer-throne` | Fen Seer's Throne | Boss arena | boss_fen_seer |

#### POIs

| POI ID | Name | Type | Event |
|--------|------|------|-------|
| `poi_dock` | Rotting Dock | Discovery | Old boat, supplies |
| `poi_willows` | Weeping Willows | Healing | Mysterious cure |
| `poi_hut` | Hermit's Hut | Social | Cryptic advice |
| `poi_altar` | Sunken Altar | Risk | Dark blessing |
| `poi_graveyard` | Forgotten Graveyard | Lore | Ghost stories |
| `poi_wisps` | Will-o-Wisps | Mystery | Follow for treasure or trap |
| `poi_boat` | Sunken Boat | Discovery | Hidden cargo |
| `poi_totem` | Swamp Totem | Blessing | Poison resistance |
| `poi_monster` | Swamp Thing Lair | Combat | Mini-boss |
| `poi_lantern` | Guiding Lantern | Navigation | Reveals safe path |

#### NPCs

| NPC ID | Name | Role | Location |
|--------|------|------|----------|
| `npc_hermit_fen` | The Hermit | Mystic, Hints | Hermit's Hut |
| `npc_ghost_child` | Lost Spirit | Quest | Forgotten Graveyard |
| `npc_fisherman` | Old Croaker | Ferryman | Rotting Dock |
| `npc_seer_acolyte` | Acolyte Mira | Warning | Sunken Temple |

#### Enemies

| Enemy Type | Variants | Behavior |
|------------|----------|----------|
| Swamp Shambler | Moss, Toxic | Slow, poison |
| Bog Witch | Hexer, Elder | Debuffs, curses |
| Mire Serpent | Lurking, Giant | Ambush from water |
| Phantom | Wisp, Wraith | Erratic, hard to hit |

#### Vocabulary Theme

**Word Categories:**
- Swamp: bog, mire, marsh, fen, murk, mud, reed, lily
- Mystery: fog, mist, haze, shadow, gloom, whisper, secret
- Decay: rot, rust, crumble, wither, fade, sink, drown
- Supernatural: ghost, spirit, haunt, curse, hex, omen

#### Typing Challenge Focus

**Primary:** Pattern Recognition (unusual letter combos)
**Secondary:** Accuracy under pressure (fog effects)

**Target Metrics:**
- Accuracy: 85%+
- WPM: 30-40
- Pattern Mastery: High

#### Boss: Fen Seer

**Name:** Fen Seer
**Type:** Mystic Prophet
**Phase 1:** Prophecy - must type revealed future words
**Phase 2:** Fog of War - reduced visibility, accuracy test
**Phase 3:** Mind Assault - words appear scrambled, unscramble first

**Defeat Reward:**
- Seer's Vision (see word previews)
- Unlock Void Rift path

---

### Region: The Citadel

**ID:** `citadel`
**Land:** Central Kingdom
**Theme:** Royal fortress - hub of civilization, advanced training

#### Geography & Terrain

```
┌────────────────────────────────────────┐
│            THE CITADEL                 │
│                                        │
│      [Eternal Scribe's Archive]        │
│               │                        │
│    [Royal Court]────[Capital Tower]    │
│         │                │             │
│  [Grand Library]──[Scribe's Hall]      │
│         │                │             │
│  [Training Grounds]──[Outer Ward]      │
│         │                              │
│    TO ALL REGIONS                      │
└────────────────────────────────────────┘
```

**Terrain Distribution:**
| Terrain | Percentage | Notes |
|---------|------------|-------|
| Stone Floor | 40% | Paved courtyards |
| Building Interior | 30% | Halls, rooms |
| Garden | 15% | Royal gardens |
| Wall/Battlements | 10% | Defensive structures |
| Water (fountain) | 5% | Decorative |

#### Zones

| Zone ID | Name | Description | Lesson Tie-In |
|---------|------|-------------|---------------|
| `outer-ward` | Outer Ward | Entry courtyard | full_alpha_words |
| `training-grounds` | Training Grounds | Military practice | training_rhythm |
| `scribes-hall` | Scribe's Hall | Writing practice | punctuation_1 |
| `grand-library` | Grand Library | Knowledge center | punctuation_2 |
| `royal-court` | Royal Court | Throne room | capitals_2 |
| `capital-tower` | Capital Tower | Noble quarters | capitals_1 |
| `archive` | Eternal Scribe's Archive | Boss arena | boss_eternal_scribe |

#### NPCs

| NPC ID | Name | Role | Location |
|--------|------|------|----------|
| `npc_king` | King Aldric | Ruler, Quest | Royal Court |
| `npc_captain` | Captain Helena | Military Training | Training Grounds |
| `npc_librarian` | Master Quill | Advanced Lessons | Grand Library |
| `npc_scribe` | Apprentice Ink | Tutorial Help | Scribe's Hall |
| `npc_merchant_citadel` | Castellan's Shop | Main Shop | Outer Ward |

---

## THE OUTER FRONTIER

### Region: Fire Realm

**ID:** `fire_realm`
**Land:** Outer Frontier
**Theme:** Volcanic wasteland - pure speed, no mercy

#### Geography & Terrain

```
┌────────────────────────────────────────┐
│           FIRE REALM                   │
│                                        │
│    [Flame Tyrant's Throne]             │
│              │                         │
│    [Inferno Core]──[Obsidian Spire]    │
│         │                │             │
│    [Volcanic Forge]──[Lava Fields]     │
│         │                              │
│    [Ember Path]                        │
│         │                              │
│    FROM THE NEXUS                      │
└────────────────────────────────────────┘
```

**Terrain Distribution:**
| Terrain | Percentage | Notes |
|---------|------------|-------|
| Cooled Lava | 35% | Dark rock, safe |
| Lava Flow | 25% | Impassable, deadly |
| Volcanic Rock | 20% | Jagged terrain |
| Ash Fields | 15% | Reduced visibility |
| Fire Vents | 5% | Periodic hazard |

#### Typing Challenge Focus

**Primary:** Maximum Speed
**Target:** 50+ WPM with 80% accuracy

---

### Region: Ice Realm

**ID:** `ice_realm`
**Land:** Outer Frontier
**Theme:** Frozen wastes - perfect precision

#### Typing Challenge Focus

**Primary:** Maximum Accuracy
**Target:** 95%+ accuracy at any speed

---

### Region: Nature Realm

**ID:** `nature_realm`
**Land:** Outer Frontier
**Theme:** Primal wilds - balanced mastery

#### Typing Challenge Focus

**Primary:** Balance (speed AND accuracy)
**Target:** 45+ WPM with 90%+ accuracy

---

### Region: The Void Rift

**ID:** `void_rift`
**Land:** Outer Frontier
**Theme:** Corrupted reality - final challenge

#### Zones

| Zone ID | Name | Description | Lesson Tie-In |
|---------|------|-------------|---------------|
| `corrupted-border` | Corrupted Border | Entry point | legendary_forest |
| `shadow-wastes` | Shadow Wastes | Twisted landscape | legendary_citadel |
| `nightmare-valley` | Nightmare Valley | Reality breaks | gauntlet_chaos |
| `void-spire` | Void Spire | Tower of darkness | legendary_apex |
| `tyrant-approach` | Tyrant's Approach | Final path | sentence_advanced |
| `void-throne` | Void Tyrant's Throne | Final boss | boss_void_tyrant |

#### Final Boss: Void Tyrant

**Name:** Void Tyrant
**Type:** Corruption Incarnate
**Phase 1:** Reality Warp - words shift mid-typing
**Phase 2:** Void Storm - all skills tested simultaneously
**Phase 3:** Final Stand - everything at once, no mistakes allowed
**Phase 4:** Purification - type the cleansing incantation perfectly

---

## Region Unlock Flow

```
                    [VOID TYRANT'S THRONE]
                            │
                    [VOID RIFT] ◄─────────────────────┐
                            │                         │
    ┌───────────────────────┼───────────────────────┐ │
    │                       │                       │ │
[FIRE REALM]          [NATURE REALM]          [ICE REALM]
    │                       │                       │ │
    └───────────────────────┼───────────────────────┘ │
                            │                         │
                     [THE NEXUS] ─────────────────────┘
                            │
            ┌───────────────┼───────────────┐
            │               │               │
      [TWILIGHT]      [CITADEL]      [CRYSTALLINE]
        WOODS            HUB           CAVERNS
            │               │               │
            └───────────────┼───────────────┘
                            │
            ┌───────────────┼───────────────┐
            │               │               │
      [STONEPASS]           │         [MISTFEN]
      MOUNTAINS             │         MARSHES
            │               │               │
            └───────────────┼───────────────┘
                            │
            ┌───────────────┼───────────────┐
            │               │               │
      [SUNFIELDS]     [EVERGROVE]    [WHISPERDALE]
       PLAINS          FOREST         VALLEY
            │               │               │
            └───────────────┼───────────────┘
                            │
                    [CASTLE KEYSTONIA]
                        (START)
```

---

## References

- `docs/plans/p1/WORLD_EXPANSION_PLAN.md` - Overall vision
- `data/pois/pois.json` - POI definitions
- `data/map.json` - Map node definitions
- `data/story.json` - Story integration
