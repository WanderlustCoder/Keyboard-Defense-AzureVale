# NPC & Character Roster

**Created:** 2026-01-08

Complete roster of characters populating the world of Keystonia.

---

## Character Categories

1. **Main Characters** - Story-critical, appear throughout game
2. **Regional NPCs** - Fixed location, regional content
3. **Wandering NPCs** - Move between locations
4. **Boss Characters** - Major encounters
5. **Minor NPCs** - Flavor, background

---

## Main Characters

### Elder Lyra

**Role:** Primary Mentor, Narrator
**Location:** Evergrove (primary), appears in all regions via visions

```
┌─────────────────────────────────────────────────────────────┐
│ ELDER LYRA                                                  │
├─────────────────────────────────────────────────────────────┤
│ Title: Keeper of the Ancient Keys                          │
│ Age: Ancient (appears elderly but timeless)                │
│ Voice: Warm, wise, encouraging                             │
├─────────────────────────────────────────────────────────────┤
│ APPEARANCE                                                  │
│ - Flowing silver robes with key motifs                     │
│ - Staff topped with glowing keyboard key                   │
│ - Kind eyes, gentle smile                                  │
│ - Floating runes around her                                │
├─────────────────────────────────────────────────────────────┤
│ PERSONALITY                                                 │
│ - Patient and nurturing                                    │
│ - Speaks in metaphors about typing                         │
│ - Never discourages, always finds positives                │
│ - Hints at deeper lore without spoiling                    │
├─────────────────────────────────────────────────────────────┤
│ FUNCTIONS                                                   │
│ - Introduces each lesson with thematic context             │
│ - Provides finger placement guidance                       │
│ - Offers encouragement after failures                      │
│ - Reveals story through dialogue                           │
│ - Teaches advanced techniques                              │
├─────────────────────────────────────────────────────────────┤
│ KEY DIALOGUE THEMES                                         │
│ - "Your fingers remember what your mind forgets..."        │
│ - "The keys are an extension of your thoughts."            │
│ - "Speed without accuracy is chaos. Balance is key."       │
│ - "Every master was once a beginner who never gave up."    │
└─────────────────────────────────────────────────────────────┘
```

**Dialogue Examples:**

```json
{
  "greeting_first": "Welcome, young typist. I am Elder Lyra, keeper of the Ancient Keys. Your journey to mastery begins with a single keystroke.",

  "lesson_intro_home_row": "Place your fingers upon the home row - ASDF for your left hand, JKL; for your right. These eight keys are your foundation, your anchor in every storm.",

  "encouragement_after_failure": "Even the swiftest typists stumbled in their early days. What matters is that you return to the keys. Shall we try again?",

  "story_hint": "The Typhos Horde grows bolder. They sense weakness in our defenses. But I sense strength in you...",

  "mastery_celebration": "Magnificent! Your fingers dance across the keys like leaves in the wind. The Ancient Ones would be proud."
}
```

---

### King Aldric

**Role:** Ruler of Keystonia, Quest Authority
**Location:** The Citadel, Royal Court

```
┌─────────────────────────────────────────────────────────────┐
│ KING ALDRIC                                                 │
├─────────────────────────────────────────────────────────────┤
│ Title: King of Keystonia, Defender of the Realm            │
│ Age: Middle-aged, battle-worn                              │
│ Voice: Commanding but fair                                 │
├─────────────────────────────────────────────────────────────┤
│ APPEARANCE                                                  │
│ - Royal armor with keyboard key crest                      │
│ - Crown with embedded letter gems                          │
│ - Greying beard, stern eyes                                │
│ - Battle scars visible                                     │
├─────────────────────────────────────────────────────────────┤
│ PERSONALITY                                                 │
│ - Duty-bound, serious                                      │
│ - Secretly worried about the kingdom                       │
│ - Respects skill over birthright                           │
│ - Becomes warmer as player proves themselves               │
├─────────────────────────────────────────────────────────────┤
│ FUNCTIONS                                                   │
│ - Assigns major story quests                               │
│ - Provides kingdom defense missions                        │
│ - Rewards major achievements                               │
│ - Unlocks advanced regions                                 │
└─────────────────────────────────────────────────────────────┘
```

---

### The Void Tyrant

**Role:** Primary Antagonist, Final Boss
**Location:** Void Rift (final area)

```
┌─────────────────────────────────────────────────────────────┐
│ THE VOID TYRANT                                             │
├─────────────────────────────────────────────────────────────┤
│ Title: Lord of Silence, Master of Unwritten Words          │
│ Nature: Corruption incarnate, anti-typing                  │
│ Voice: Distorted, echoing, multiple overlapping            │
├─────────────────────────────────────────────────────────────┤
│ APPEARANCE                                                  │
│ - Shifting dark form, vaguely humanoid                     │
│ - Broken keyboard keys floating around body                │
│ - Eyes like corrupted screens                              │
│ - Tendrils of static and glitch                            │
├─────────────────────────────────────────────────────────────┤
│ PERSONALITY                                                 │
│ - Speaks in fragmented sentences                           │
│ - Mocks the value of words                                 │
│ - Represents fear, doubt, giving up                        │
│ - Surprisingly philosophical at times                      │
├─────────────────────────────────────────────────────────────┤
│ MOTIVATION                                                  │
│ - Seeks to silence all keyboards                           │
│ - Feeds on typing errors and frustration                   │
│ - Wants to return world to wordless void                   │
└─────────────────────────────────────────────────────────────┘
```

**Dialogue Examples:**

```json
{
  "first_encounter": "So... another... who thinks... words have... power. How... quaint.",

  "taunt_during_battle": "Every... mistake... feeds me. Every... hesitation... makes me... stronger.",

  "phase_transition": "You type... fast. But can you... type... TRUE?",

  "defeat_speech": "The silence... will come... eventually. Even... if not... today...",

  "secret_revelation": "I was... once... like you. A typist... who grew... tired..."
}
```

---

## Regional NPCs

### Verdant Heartland NPCs

| NPC | Location | Role | Key Dialogue |
|-----|----------|------|--------------|
| **Ranger Thorne** | Forest Gate | Scout, Early Quests | "The forest paths are safe... for now. But darkness stirs in the deeper woods." |
| **Willow the Herbalist** | Whisper Grove | Healing, Shop | "These herbs will soothe tired fingers. Rest is as important as practice." |
| **Forest Spirit** | Ancient Oak (night) | Lore, Secrets | "The trees remember when the first keyboard was carved from sacred oak..." |
| **Old Farmer Giles** | Farmer's Road | Quest Giver | "These fields need defending! Type the harvest words to bring in the crop!" |
| **Champion Vera** | Blazing Arena | Speed Training | "Speed is life in the arena! Let's see what those fingers can do!" |
| **Swift Sarah** | Champion's Road | Challenger | "I'm the fastest typer in Sunfields! ...Or I was, until you showed up." |

### Central Kingdom NPCs

| NPC | Location | Role | Key Dialogue |
|-----|----------|------|--------------|
| **Elder Grimstone** | Dwarven Forge | Lore, Crafting | "In my grandfather's day, we forged keyboards from mountain iron. Strong keys for strong fingers." |
| **Picks McGee** | Miner's Descent | Quest Giver | "The deep mines are full of crystal keys! Help me excavate them!" |
| **Mountain Hermit** | Frost Peak | Advanced Training | "At this altitude, every breath matters. Every keystroke must be precise." |
| **The Hermit** | Mistfen Hut | Mystic | "The fog shows many paths... not all lead where you wish to go." |
| **Lost Spirit** | Graveyard | Quest | "I cannot rest... my final words were never typed. Will you complete them?" |
| **Old Croaker** | Rotting Dock | Ferryman | "Coin for passage? Nah. Type me a shanty and we'll call it even." |
| **Captain Helena** | Training Grounds | Military | "Soldiers type orders, not excuses! Again! Faster! ACCURATE!" |
| **Master Quill** | Grand Library | Scholar | "Every book here was typed by masters. Study their patterns." |

### Outer Frontier NPCs

| NPC | Location | Role | Key Dialogue |
|-----|----------|------|--------------|
| **Ember Knight** | Fire Realm | Challenge | "The flames respect only speed. Hesitate and you burn." |
| **Frost Sage** | Ice Realm | Challenge | "One. Wrong. Key. And the ice claims you forever." |
| **Druid Elder** | Nature Realm | Wisdom | "Balance in all things. The forest teaches patience AND urgency." |
| **Void Wanderer** | Void Rift Edge | Warning | "Turn back... while you still... remember... words..." |

---

## Wandering NPCs

### Marco the Merchant

**Appears:** Random location each day
**Function:** Traveling shop with rare items

```json
{
  "id": "npc_marco",
  "name": "Marco the Merchant",
  "type": "wandering_shop",
  "spawn_chance": 0.3,
  "valid_regions": ["evergrove", "sunfields", "stonepass", "citadel"],
  "inventory_type": "random_rare",
  "dialogue": {
    "greeting": "Ah, a customer! Marco has wares from across the realm!",
    "no_gold": "Come back when your pockets are heavier, friend.",
    "purchase": "A fine choice! May it serve you well!",
    "farewell": "Marco must move on. Perhaps we meet again!"
  }
}
```

### The Wandering Scribe

**Appears:** Near completion of word-heavy areas
**Function:** Bonus challenges, lore

```json
{
  "id": "npc_wandering_scribe",
  "name": "The Wandering Scribe",
  "type": "challenge_giver",
  "trigger": "area_75_percent_complete",
  "dialogue": {
    "greeting": "I collect words from every corner of the realm. Care to add yours?",
    "challenge": "Type this ancient phrase perfectly, and I shall reward you.",
    "success": "Magnificent! The old words live again through your fingers.",
    "failure": "The phrase escapes you... for now. I shall wait."
  }
}
```

### Ghost of the Last Champion

**Appears:** After defeating all regional bosses
**Function:** Ultimate challenge, true ending hint

---

## Boss Characters

### Regional Bosses

| Boss | Region | Type | Personality |
|------|--------|------|-------------|
| **Grove Guardian** | Evergrove | Nature Spirit | Protective, tests worthiness |
| **Sunlord Champion** | Sunfields | Speed Master | Arrogant, respects skill |
| **Citadel Warden** | Stonepass | Stone Golem | Silent, immovable |
| **Fen Seer** | Mistfen | Oracle | Cryptic, sees futures |
| **Eternal Scribe** | Citadel | Ancient Scholar | Pedantic, respects knowledge |

### Elemental Realm Bosses

| Boss | Realm | Challenge Focus | Personality |
|------|-------|-----------------|-------------|
| **Flame Tyrant** | Fire | Pure Speed | Raging, impatient |
| **Frost Empress** | Ice | Pure Accuracy | Cold, precise, unforgiving |
| **Ancient Treant** | Nature | Balance | Ancient, wise, tests all skills |

### Final Boss

| Boss | Location | Phases | Reward |
|------|----------|--------|--------|
| **Void Tyrant** | Void Rift | 4 phases | True ending, game completion |

---

## Minor NPCs (Background/Flavor)

### Castle Keystonia

- **Guard Captain** - Patrols, generic dialogue
- **Servant** - Directions to areas
- **Cook** - Food-related idle chatter
- **Stable Hand** - Horse/travel hints

### Villages

- **Farmer** - Weather/crop talk
- **Blacksmith** - Equipment hints
- **Innkeeper** - Rest point, rumors
- **Child** - Playful, mini-challenges
- **Elder** - Local history

### Wilderness

- **Traveling Pilgrim** - Religious lore
- **Lost Explorer** - Map hints
- **Wounded Soldier** - Danger warnings
- **Animal Companion** - Non-verbal, follows briefly

---

## NPC Relationship System

### Affinity Levels

| Level | Name | Unlock |
|-------|------|--------|
| 0 | Stranger | Default state |
| 1 | Acquaintance | First conversation |
| 2 | Friendly | 3+ interactions |
| 3 | Trusted | Complete their quest |
| 4 | Allied | Special conditions |
| 5 | Bonded | Max relationship |

### Affinity Rewards

- **Level 2:** Discount at shops (10%)
- **Level 3:** Unique dialogue, hints
- **Level 4:** Special items/abilities
- **Level 5:** Companion assistance in battles

---

## Dialogue System

### Dialogue Tags

```json
{
  "tags": {
    "story": "Main plot progression",
    "lore": "World history and background",
    "hint": "Gameplay tips",
    "quest": "Quest-related",
    "shop": "Commercial transactions",
    "idle": "Random ambient dialogue",
    "reaction": "Response to player actions"
  }
}
```

### Dialogue Conditions

```json
{
  "conditions": {
    "day_range": [1, 10],
    "lesson_mastery": ["home_row_1", "home_row_2"],
    "quest_complete": "quest_forest_gate",
    "time_of_day": "night",
    "accuracy_above": 0.90,
    "wpm_above": 50,
    "has_item": "ancient_key"
  }
}
```

---

## Character Art Direction

### Style Guide

**General:**
- Semi-realistic fantasy style
- Expressive faces, clear silhouettes
- Keyboard/typing motifs in clothing/accessories
- Each NPC has signature color

**Main Characters:**
- Full portrait art
- Multiple expressions
- Animated idle poses

**Regional NPCs:**
- Half-body portraits
- 2-3 expressions
- Static or minimal animation

**Minor NPCs:**
- Head/bust portraits
- Single expression
- No animation

---

## Implementation Data

### NPC Schema

```json
{
  "id": "npc_lyra",
  "name": "Elder Lyra",
  "title": "Keeper of the Ancient Keys",
  "type": "main_character",
  "location": {
    "region": "evergrove",
    "zone": "elders-glade",
    "wandering": false
  },
  "portrait": "portraits/lyra.png",
  "expressions": ["neutral", "happy", "concerned", "proud"],
  "dialogue_file": "dialogue/lyra.json",
  "functions": ["mentor", "lesson_intro", "story"],
  "affinity_trackable": false,
  "shop_inventory": null,
  "quest_giver": true,
  "quests": ["quest_first_lesson", "quest_mastery_path"]
}
```

---

## References

- `docs/plans/p1/WORLD_EXPANSION_PLAN.md` - World structure
- `docs/plans/p1/REGION_SPECIFICATIONS.md` - Region details
- `data/story.json` - Story dialogue
- `game/dialogue_box.gd` - Dialogue system
