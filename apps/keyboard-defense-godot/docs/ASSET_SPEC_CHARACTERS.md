# Character Asset Specifications

## Design Philosophy
- **Personality Through Pixels**: Characters express emotion despite limited resolution
- **Role Clarity**: Function immediately apparent from appearance
- **Animation Priority**: Key poses sell the character
- **Consistency**: All characters share proportions and style

---

## CHARACTER STANDARDS

### Base Proportions (16x24)
```
┌──────────────────────────────────┐
│  Row 1-6: Head (16x6)            │ ← 25% - Face, hair, accessories
│  Row 7-16: Torso (16x10)         │ ← 42% - Body, arms, clothing
│  Row 17-22: Legs (16x6)          │ ← 25% - Legs, feet
│  Row 23-24: Ground Shadow (16x2) │ ← 8% - Grounding
└──────────────────────────────────┘
```

### Animation Frame Counts
| Action | Frames | Duration |
|--------|--------|----------|
| Idle | 4 | 2000ms |
| Walk | 6 | 600ms |
| Run | 6 | 400ms |
| Attack | 6-8 | 400-600ms |
| Cast | 6 | 500ms |
| Death | 6-8 | 600-800ms |
| React | 4 | 300ms |

---

## PLAYER AVATAR

### Default Avatar (char_player)
**Dimensions**: 16x24
**Role**: Player representation on map/menu

**Visual Design**:
- Young adult figure
- Neutral, customizable appearance
- Light armor (typing knight theme)
- Determined expression

**Color Palette**:
```
Skin:         #f5cba7
Hair:         #6e2c00 (default, customizable)
Armor Base:   #5d6d7e
Armor Trim:   #f4d03f
Cloth:        #3498db
```

**Animation States**:
| State | Description |
|-------|-------------|
| idle | Slight breathing, alert stance |
| walk | Map navigation |
| victory | Celebratory pose, arm raised |
| defeat | Slumped, dejected |
| typing | Hands at keyboard stance |

---

### Avatar Customization Options

#### Hair Styles (8 options)
```
hair_short, hair_medium, hair_long
hair_spiky, hair_ponytail, hair_braided
hair_bald, hair_hooded
```

#### Hair Colors (12 options)
```
#6e2c00 (Brown), #1a252f (Black), #f4d03f (Blonde)
#e74c3c (Red), #85929e (Gray), #fdfefe (White)
#9b59b6 (Purple), #3498db (Blue), #27ae60 (Green)
#f39c12 (Orange), #c0392b (Crimson), #1abc9c (Teal)
```

#### Skin Tones (6 options)
```
#fdebd0 (Light), #f5cba7 (Fair), #dc7633 (Medium)
#a04000 (Tan), #6e2c00 (Dark), #4a1c00 (Deep)
```

---

## MENTOR CHARACTERS

### Lyra - Typing Mentor (char_lyra)
**Dimensions**: 16x24
**Role**: Tutorial guide, lesson presenter

**Visual Design**:
- Wise, approachable woman
- Librarian/scholar aesthetic
- Glasses
- Book or scroll accessory
- Warm color palette

**Color Palette**:
```
Skin:         #f5cba7
Hair:         #4a235a (silver-purple)
Robe:         #1a5276 (deep blue)
Trim:         #f4d03f (gold)
Book:         #6e2c00
Glasses:      #85929e
```

**Expressions**:
| Expression | Use Case |
|------------|----------|
| neutral | Default |
| encouraging | Correct answers |
| thinking | Hints |
| excited | Level complete |
| concerned | Mistakes |

---

### General Kael - Battle Mentor (char_kael)
**Dimensions**: 16x24
**Role**: Tower/combat tutorial

**Visual Design**:
- Grizzled military veteran
- Scar across face
- Heavy armor
- Cape
- Strategic pointer/baton

**Color Palette**:
```
Skin:         #dc7633
Hair:         #85929e (gray)
Armor:        #34495e
Cape:         #c0392b (dark red)
Trim:         #f4d03f
Scar:         #c0392b
```

**Expressions**:
| Expression | Use Case |
|------------|----------|
| stern | Instructions |
| approving | Good strategy |
| alarmed | Danger warning |
| proud | Victory |

---

## CASTLE STAFF NPCs

### Blacksmith (char_blacksmith)
**Dimensions**: 16x24
**Role**: Upgrade shop

**Visual Design**:
- Burly, muscular
- Leather apron
- Hammer tool
- Soot marks
- Friendly demeanor

**Color Palette**:
```
Skin:         #dc7633
Apron:        #6e2c00
Hammer:       #5d6d7e
Soot:         #1a252f
Hair:         #a04000
```

---

### Arcanist (char_arcanist)
**Dimensions**: 16x24
**Role**: Magic/special upgrades

**Visual Design**:
- Mystical robe
- Glowing eyes
- Staff with crystal
- Floating runes (idle animation)

**Color Palette**:
```
Robe:         #4a235a
Trim:         #9b59b6
Crystal:      #85c1e9
Runes:        #f4d03f
Eyes:         #85c1e9 (glow)
```

---

### Quartermaster (char_quartermaster)
**Dimensions**: 16x24
**Role**: Resource management

**Visual Design**:
- Organized appearance
- Clipboard/ledger
- Apron with pouches
- Counting gesture

**Color Palette**:
```
Clothing:     #27ae60
Apron:        #1e8449
Ledger:       #f5cba7
Belt:         #6e2c00
```

---

### Royal Courier (char_courier)
**Dimensions**: 16x24
**Role**: Quest/message delivery

**Visual Design**:
- Light armor
- Messenger bag
- Scroll in hand
- Swift appearance

**Color Palette**:
```
Armor:        #5d6d7e
Bag:          #6e2c00
Scroll:       #f5cba7
Cape:         #3498db
```

---

## PORTRAIT SYSTEM

### Portrait Frame (portrait_frame)
**Dimensions**: 64x80 (9-slice)
**Components**:
- Ornate border
- Name plate area
- Expression area (48x48)

**9-Slice Margins**:
```
margin_left: 8
margin_right: 8
margin_top: 8
margin_bottom: 16 (name area)
```

---

### Portrait Expressions
Each character has expressions in 48x48 format:

| Expression | Filename Suffix | Use |
|------------|-----------------|-----|
| Neutral | _neutral | Default |
| Happy | _happy | Positive feedback |
| Sad | _sad | Defeat, bad news |
| Angry | _angry | Warning, danger |
| Surprised | _surprised | Discovery |
| Thinking | _thinking | Hints, puzzles |
| Confident | _confident | Victory, mastery |
| Worried | _worried | Low HP, mistakes |

---

### Lyra Portraits (portrait_lyra_*)
**Dimensions**: 48x48 each
**Total**: 8 expressions

**Specific Expressions**:
- neutral: Slight smile, glasses glint
- encouraging: Warm smile, eyes bright
- thinking: Finger to chin, looking up
- excited: Wide eyes, open smile
- concerned: Furrowed brow, slight frown
- proud: Closed eyes, satisfied smile
- explaining: Hand gesture, engaged
- surprised: Raised eyebrows, "oh!"

---

### Kael Portraits (portrait_kael_*)
**Dimensions**: 48x48 each
**Total**: 8 expressions

**Specific Expressions**:
- neutral: Stern, watchful
- stern: Intense stare
- approving: Slight nod, hint of smile
- alarmed: Wide eye (scar side darker)
- proud: Rare smile, salute
- commanding: Pointing gesture
- concerned: Narrowed eyes
- victorious: Fist raised, grin

---

## ENEMY LEADER CHARACTERS

### The Tyrant (char_boss_tyrant)
**Dimensions**: 24x32 (larger boss scale)
**Role**: Act 1 Boss

**Visual Design**:
- Massive armored figure
- Crown/helmet fusion
- Glowing weapon
- Cape of shadows

**Color Palette**:
```
Armor:        #1a252f
Trim:         #c0392b
Crown:        #f4d03f
Glow:         #e74c3c
Cape:         #4a235a (shadow effect)
```

**Portrait**: 48x48, menacing expressions

---

### The Witch Queen (char_boss_witch)
**Dimensions**: 20x28
**Role**: Act 2 Boss

**Visual Design**:
- Ethereal, floating
- Staff with skull
- Tattered elegant dress
- Magic aura

**Color Palette**:
```
Dress:        #4a235a
Hair:         #1a252f (wild)
Staff:        #6e2c00
Skull:        #fdfefe
Aura:         #9b59b6, #d2b4de
Eyes:         #27ae60 (unnatural)
```

---

### The Dragon King (char_boss_dragon)
**Dimensions**: 32x40 (major boss scale)
**Role**: Final Boss

**Visual Design**:
- Dragon-humanoid hybrid
- Multiple wings
- Crown of fire
- Typing challenge: longest words

**Color Palette**:
```
Scales:       #c0392b, #922b21
Wings:        #6e2c00 (membrane)
Crown:        #f4d03f, #f39c12 (flames)
Eyes:         #f4d03f
Claws:        #1a252f
Fire:         #e74c3c, #f39c12, #f4d03f
```

---

## COMPANION PETS

### Cat Companion (pet_cat)
**Dimensions**: 12x12
**Purpose**: Cosmetic, follows player

**Visual Design**:
- Simple sitting/walking cat
- Various color options
- Occasional paw wave

**Variations**:
```
Orange tabby, Black, White, Gray
Calico, Tuxedo, Siamese
```

**Animations**:
- idle: Tail swish
- walk: Trot alongside
- sit: Curled up
- react: Ears perk

---

### Owl Companion (pet_owl)
**Dimensions**: 12x12
**Purpose**: Cosmetic, typing mascot

**Visual Design**:
- Small wise owl
- Big eyes
- Perches on shoulder

**Animations**:
- idle: Head bob, blink
- fly: Flapping movement
- perch: On shoulder/stand
- hoot: Opens beak

---

### Dragon Whelp (pet_dragon)
**Dimensions**: 14x14
**Purpose**: Premium/achievement unlock

**Visual Design**:
- Baby dragon
- Tiny wings
- Playful personality

**Animations**:
- idle: Flaps wings, looks around
- walk: Bouncy hop
- fly: Hovering
- fire: Tiny flame puff

---

## CROWD/BACKGROUND CHARACTERS

### Villager Generic (char_villager)
**Dimensions**: 12x20
**Purpose**: Background population

**Variations**: 8 (4 male, 4 female)
- Different hair/clothing colors
- Simple 2-frame idle

---

### Guard (char_guard)
**Dimensions**: 14x22
**Purpose**: Castle background

**Visual**: Armor, spear, helmet
**Animation**: 2-frame standing patrol

---

### Merchant (char_merchant)
**Dimensions**: 12x20
**Purpose**: Market background

**Visual**: Apron, gesturing at wares

---

## SILHOUETTE SPRITES

### Mystery Character (char_silhouette)
**Dimensions**: 16x24
**Purpose**: Locked/unknown characters

**Visual**:
- Pure black filled shape
- Character outline
- "?" mark
- Subtle shimmer

---

### Coming Soon Character (char_coming_soon)
**Dimensions**: 16x24
**Purpose**: Unreleased characters

**Visual**:
- Grayed out
- "Coming Soon" overlay
- Lock icon

---

## CHARACTER ANIMATION SHEETS

### Standard Animation Layout
```
Row 1: Idle (4-6 frames)
Row 2: Walk (6 frames)
Row 3: Attack/Action (6-8 frames)
Row 4: Special (6 frames)
Row 5: Death/Defeat (6-8 frames)
Row 6: React/Emote (4 frames)
```

### Frame Dimensions
```
Standard Character:  16x24 per frame
Large Character:     24x32 per frame
Boss Character:      32x40+ per frame
Portrait:            48x48 per expression
Mini/Companion:      12x12 per frame
```

---

## EMOTE SYSTEM

### Emote Bubble (emote_bubble)
**Dimensions**: 16x16
**Position**: Above character head

### Emote Icons (emote_*)
**Dimensions**: 12x12

| Emote | Icon | Use |
|-------|------|-----|
| happy | Smiley | Positive |
| angry | Rage symbol | Negative |
| question | ? mark | Confused |
| exclaim | ! mark | Alert |
| heart | Heart | Affection |
| star | Star | Success |
| sweat | Drop | Nervous |
| sleep | Zzz | Idle/bored |
| idea | Lightbulb | Discovery |
| skull | Skull | Danger |

**Animation**: 4 frames, pop in and bob

---

## ACCESSIBILITY CONSIDERATIONS

### High Visibility Mode
- Character outlines thickened (2px)
- Higher contrast colors
- Name labels always visible
- Larger hitboxes

### Colorblind Patterns
- Add shape indicators to color-coded characters
- Name plates for identification
- Unique silhouettes maintained

### Screen Reader Support
- Alt text for all character images
- Audio descriptions for expressions
- Voiced lines where possible

---

## NAMING CONVENTIONS

### File Structure
```
characters/
├── player/
│   ├── char_player_idle.png
│   ├── char_player_walk.png
│   └── customization/
│       ├── hair_short.png
│       └── skin_fair.png
├── mentors/
│   ├── char_lyra_sheet.png
│   └── portrait_lyra_neutral.png
├── npcs/
│   ├── char_blacksmith.png
│   └── char_quartermaster.png
├── bosses/
│   ├── char_boss_tyrant.png
│   └── portrait_boss_tyrant_angry.png
├── pets/
│   ├── pet_cat_orange.png
│   └── pet_owl.png
└── background/
    ├── char_villager_1.png
    └── char_guard.png
```

---

## ANIMATION TIMING REFERENCE

### Idle Animations
- Period: 2000-3000ms full cycle
- Subtle movement only
- Breathing, blinking, shifting weight

### Walk Cycles
- 6 frames recommended
- 100ms per frame (600ms cycle)
- Contact, passing, reach positions

### Action Animations
- Anticipation: 1-2 frames
- Action: 2-3 frames
- Recovery: 2-3 frames
- Total: 400-600ms

### Expression Transitions
- Blend between expressions: 150ms
- Hold expression: minimum 500ms
- Return to neutral: 300ms

