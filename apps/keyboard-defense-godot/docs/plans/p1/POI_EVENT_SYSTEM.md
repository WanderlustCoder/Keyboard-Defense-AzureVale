# POI Event System

**Created:** 2026-01-08

Detailed specification for Points of Interest events, outcomes, and rewards.

---

## Event System Overview

### Event Flow

```
┌─────────────────────────────────────────────────────────────┐
│                      POI DISCOVERY                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. Player explores tile with POI                          │
│  2. POI type and event table determined                    │
│  3. Event rolled based on day + seed (deterministic)       │
│  4. Event presented with choices (if applicable)           │
│  5. Outcome resolved based on choice + typing challenge    │
│  6. Rewards/consequences applied                           │
│  7. POI marked as visited (or respawn timer set)          │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Event Categories

| Category | Description | Frequency |
|----------|-------------|-----------|
| **Discovery** | One-time treasure/lore | 40% |
| **Challenge** | Typing test for reward | 25% |
| **Social** | NPC interaction | 15% |
| **Resource** | Gatherable materials | 10% |
| **Mystery** | Random/unusual effect | 10% |

---

## Event Table Structure

### Schema

```json
{
  "event_table_id": "evergrove_wagon",
  "poi_type": "Abandoned Wagon",
  "events": [
    {
      "id": "wagon_supplies",
      "weight": 50,
      "day_range": [1, 10],
      "description": "You find an old wagon with scattered supplies.",
      "choices": [
        {
          "id": "search_thoroughly",
          "label": "Search thoroughly",
          "challenge": {
            "type": "accuracy",
            "target": 0.85,
            "words": 10
          },
          "success": {
            "text": "Your careful search reveals hidden compartments!",
            "rewards": [
              {"type": "gold", "amount": 15},
              {"type": "item", "id": "healing_herb", "count": 2}
            ]
          },
          "failure": {
            "text": "You find only rotted supplies.",
            "rewards": [
              {"type": "gold", "amount": 5}
            ]
          }
        },
        {
          "id": "quick_grab",
          "label": "Grab what you can quickly",
          "challenge": null,
          "success": {
            "text": "You grab some coins and leave.",
            "rewards": [
              {"type": "gold", "amount": 8}
            ]
          }
        }
      ]
    }
  ]
}
```

---

## Event Tables by Region

### Evergrove Forest

#### Abandoned Wagon (`evergrove_wagon`)

| Event | Weight | Day Range | Description |
|-------|--------|-----------|-------------|
| Old Supplies | 50 | 1-10 | Basic discovery |
| Merchant's Cache | 30 | 3-15 | Better rewards with challenge |
| Creature Nest | 20 | 5-20 | Combat + treasure |

**Event Details:**

```json
{
  "id": "merchant_cache",
  "weight": 30,
  "day_range": [3, 15],
  "description": "The wagon bears a merchant's seal. Something valuable might remain.",
  "choices": [
    {
      "id": "pick_lock",
      "label": "Pick the lock carefully",
      "challenge": {
        "type": "speed",
        "target_wpm": 30,
        "words": 8,
        "time_limit": 20
      },
      "success": {
        "text": "Click! The lock opens to reveal a hidden chest!",
        "rewards": [
          {"type": "gold", "amount": 25},
          {"type": "item", "id": "rare_scroll", "count": 1}
        ]
      },
      "failure": {
        "text": "The lock jams. You manage to pry it open but damage some contents.",
        "rewards": [
          {"type": "gold", "amount": 10}
        ]
      }
    },
    {
      "id": "break_open",
      "label": "Force it open",
      "challenge": null,
      "success": {
        "text": "You break the lock but some contents scatter.",
        "rewards": [
          {"type": "gold", "amount": 12}
        ]
      }
    }
  ]
}
```

#### Quiet Shrine (`evergrove_shrine`)

| Event | Weight | Day Range | Description |
|-------|--------|-----------|-------------|
| Peaceful Rest | 40 | 1-20 | Healing + buff |
| Spirit Blessing | 35 | 3-25 | Lore + ability |
| Ancient Test | 25 | 5-30 | Challenge for major reward |

**Event Details:**

```json
{
  "id": "spirit_blessing",
  "weight": 35,
  "day_range": [3, 25],
  "description": "A faint glow emanates from the shrine. A spirit stirs within.",
  "choices": [
    {
      "id": "meditate",
      "label": "Meditate at the shrine",
      "challenge": {
        "type": "consistency",
        "target": 0.80,
        "words": 15,
        "description": "Type calmly and steadily..."
      },
      "success": {
        "text": "The spirit speaks: 'Your calm mind pleases the forest. Accept this gift.'",
        "rewards": [
          {"type": "buff", "id": "forest_blessing", "duration": 3},
          {"type": "lore", "id": "lore_spirit_01"}
        ]
      },
      "failure": {
        "text": "The spirit fades. 'Return when your mind is still.'",
        "rewards": []
      }
    },
    {
      "id": "offer_gold",
      "label": "Leave a gold offering",
      "challenge": null,
      "cost": {"type": "gold", "amount": 10},
      "success": {
        "text": "The shrine glows warmly. You feel refreshed.",
        "rewards": [
          {"type": "heal", "amount": "full"}
        ]
      }
    }
  ]
}
```

#### Herb Patch (`evergrove_herbs`)

| Event | Weight | Day Range | Description |
|-------|--------|-----------|-------------|
| Common Herbs | 50 | 1-20 | Basic gathering |
| Rare Herbs | 30 | 5-25 | Better herbs with challenge |
| Guarded Herbs | 20 | 8-30 | Combat then gathering |

---

### Stonepass Mountains

#### Abandoned Quarry (`stonepass_quarry`)

| Event | Weight | Day Range | Description |
|-------|--------|-----------|-------------|
| Stone Deposits | 45 | 3-15 | Basic stone |
| Crystal Vein | 35 | 5-20 | Rare crystals |
| Cave-in Risk | 20 | 8-25 | Risk/reward |

**Event Details:**

```json
{
  "id": "crystal_vein",
  "weight": 35,
  "day_range": [5, 20],
  "description": "Deep in the quarry, crystals glint in the darkness.",
  "choices": [
    {
      "id": "careful_extraction",
      "label": "Extract carefully",
      "challenge": {
        "type": "accuracy",
        "target": 0.90,
        "words": 12,
        "description": "Precision is required to extract intact crystals..."
      },
      "success": {
        "text": "You extract three perfect crystals!",
        "rewards": [
          {"type": "item", "id": "pure_crystal", "count": 3},
          {"type": "gold", "amount": 20}
        ]
      },
      "failure": {
        "text": "Some crystals shatter. You salvage what you can.",
        "rewards": [
          {"type": "item", "id": "crystal_shard", "count": 5}
        ]
      }
    },
    {
      "id": "quick_grab_crystals",
      "label": "Grab quickly",
      "challenge": null,
      "success": {
        "text": "You grab some crystal shards.",
        "rewards": [
          {"type": "item", "id": "crystal_shard", "count": 3}
        ]
      }
    }
  ]
}
```

#### Mountain Cave (`stonepass_cave`)

| Event | Weight | Day Range | Description |
|-------|--------|-----------|-------------|
| Empty Cave | 30 | 5-25 | Minor discovery |
| Hidden Passage | 40 | 8-30 | Leads to secret |
| Monster Lair | 30 | 10-35 | Combat encounter |

---

### Mistfen Marshes

#### Hermit's Hut (`mistfen_hut`)

| Event | Weight | Day Range | Description |
|-------|--------|-----------|-------------|
| Empty Hut | 25 | 7-25 | Basic discovery |
| Hermit Home | 45 | 8-30 | Social encounter |
| Dangerous Hermit | 30 | 10-35 | Trickster encounter |

**Event Details:**

```json
{
  "id": "hermit_home",
  "weight": 45,
  "day_range": [8, 30],
  "description": "An old hermit peers at you from the doorway. 'A visitor? How... unexpected.'",
  "choices": [
    {
      "id": "ask_wisdom",
      "label": "Ask for wisdom",
      "challenge": {
        "type": "mixed",
        "requirements": {
          "accuracy": 0.85,
          "wpm": 25
        },
        "words": 10,
        "description": "Speak the ancient greeting to show respect..."
      },
      "success": {
        "text": "'Ah, you know the old ways. Very well, I shall teach you.'",
        "rewards": [
          {"type": "skill_hint", "id": "hermit_technique"},
          {"type": "lore", "id": "lore_hermit_01"}
        ]
      },
      "failure": {
        "text": "'Hmph. Come back when you've learned proper respect.'",
        "rewards": []
      }
    },
    {
      "id": "offer_trade",
      "label": "Offer to trade",
      "challenge": null,
      "success": {
        "text": "'Trade, eh? I have some old potions...'",
        "rewards": [
          {"type": "shop_access", "id": "hermit_shop"}
        ]
      }
    },
    {
      "id": "leave_alone",
      "label": "Leave the hermit be",
      "challenge": null,
      "success": {
        "text": "The hermit nods approvingly at your discretion.",
        "rewards": [
          {"type": "reputation", "faction": "mistfen", "amount": 5}
        ]
      }
    }
  ]
}
```

#### Sunken Altar (`mistfen_altar`)

| Event | Weight | Day Range | Description |
|-------|--------|-----------|-------------|
| Faded Altar | 35 | 8-30 | Minor lore |
| Dark Blessing | 40 | 10-35 | Risk/reward buff |
| Spirit Summoning | 25 | 15-40 | Major encounter |

---

### Sunfields Plains

#### Training Arena (`sunfields_arena`)

| Event | Weight | Day Range | Description |
|-------|--------|-----------|-------------|
| Empty Arena | 20 | 10-30 | Practice mode |
| Local Champion | 50 | 12-35 | Speed duel |
| Tournament Day | 30 | 15-40 | Multi-round event |

**Event Details:**

```json
{
  "id": "local_champion",
  "weight": 50,
  "day_range": [12, 35],
  "description": "A confident typist stands in the arena. 'Think you're fast? Prove it!'",
  "choices": [
    {
      "id": "accept_challenge",
      "label": "Accept the challenge",
      "challenge": {
        "type": "speed_duel",
        "opponent_wpm": 45,
        "words": 20,
        "description": "Race to type 20 words faster than your opponent!"
      },
      "success": {
        "text": "'Incredible! You've bested me fair and square.'",
        "rewards": [
          {"type": "gold", "amount": 40},
          {"type": "title", "id": "arena_victor"},
          {"type": "buff", "id": "speed_confidence", "duration": 5}
        ]
      },
      "failure": {
        "text": "'Not bad, but not good enough. Train more and return!'",
        "rewards": [
          {"type": "gold", "amount": 10}
        ]
      }
    },
    {
      "id": "watch_and_learn",
      "label": "Watch and learn",
      "challenge": null,
      "success": {
        "text": "You observe the champion's technique carefully.",
        "rewards": [
          {"type": "skill_hint", "id": "speed_technique"}
        ]
      }
    }
  ]
}
```

---

## Challenge Types

### Accuracy Challenge

```json
{
  "type": "accuracy",
  "target": 0.90,
  "words": 10,
  "description": "Type these words with precision..."
}
```

**Mechanics:**
- Player must type X words with Y% accuracy
- No time pressure
- Rewards scale with accuracy achieved

### Speed Challenge

```json
{
  "type": "speed",
  "target_wpm": 40,
  "words": 15,
  "time_limit": 30
}
```

**Mechanics:**
- Player must achieve target WPM
- Time limit applies
- Accuracy floor of 75%

### Consistency Challenge

```json
{
  "type": "consistency",
  "target": 0.80,
  "words": 15
}
```

**Mechanics:**
- Measures rhythm stability
- Even pacing required
- Rushing or pausing penalized

### Mixed Challenge

```json
{
  "type": "mixed",
  "requirements": {
    "accuracy": 0.85,
    "wpm": 35
  },
  "words": 12
}
```

**Mechanics:**
- Must meet both requirements
- Balanced skill test
- Higher rewards

### Speed Duel

```json
{
  "type": "speed_duel",
  "opponent_wpm": 45,
  "words": 20
}
```

**Mechanics:**
- Race against AI opponent
- Opponent types at set WPM
- First to finish wins

---

## Reward Types

### Resource Rewards

```json
{"type": "gold", "amount": 25}
{"type": "item", "id": "healing_herb", "count": 3}
{"type": "resource", "id": "wood", "amount": 10}
```

### Buff Rewards

```json
{
  "type": "buff",
  "id": "forest_blessing",
  "duration": 3,
  "effects": {
    "accuracy_bonus": 0.05,
    "description": "Accuracy +5% for 3 battles"
  }
}
```

### Lore Rewards

```json
{
  "type": "lore",
  "id": "lore_spirit_01",
  "title": "The Spirit's Tale",
  "content": "Long ago, when the forest was young..."
}
```

### Skill Hints

```json
{
  "type": "skill_hint",
  "id": "hermit_technique",
  "title": "The Hermit's Technique",
  "description": "Breathe between words. Speed comes from calm, not chaos."
}
```

### Unlocks

```json
{"type": "shop_access", "id": "hermit_shop"}
{"type": "zone_unlock", "id": "secret_cave"}
{"type": "title", "id": "arena_victor"}
```

---

## Event Modifiers

### Day-Based Scaling

```json
{
  "scaling": {
    "gold_multiplier": "1.0 + (day * 0.05)",
    "challenge_difficulty": "base + (day * 0.02)"
  }
}
```

### Mastery Bonuses

```json
{
  "mastery_bonus": {
    "condition": "lesson_mastery >= 3",
    "reward_multiplier": 1.25,
    "extra_choice": true
  }
}
```

### Random Modifiers

```json
{
  "random_modifiers": [
    {"id": "double_treasure", "chance": 0.05},
    {"id": "guardian_appears", "chance": 0.10},
    {"id": "nothing_here", "chance": 0.05}
  ]
}
```

---

## Respawn Rules

| POI Type | Respawn | Condition |
|----------|---------|-----------|
| Discovery | Never | One-time only |
| Resource | 3 days | After depletion |
| Challenge | 1 day | Can retry |
| Social | Varies | Based on NPC schedule |
| Mystery | Random | 10-50% per day |

---

## Implementation Checklist

- [ ] Create event table JSON files for each POI
- [ ] Implement challenge type handlers
- [ ] Add reward distribution system
- [ ] Create event UI with choices
- [ ] Add day-based scaling
- [ ] Implement respawn timers
- [ ] Add lore collection tracking
- [ ] Create buff/debuff system

---

## References

- `data/pois/pois.json` - POI definitions
- `sim/poi.gd` - POI system code
- `docs/plans/p1/WORLD_EXPANSION_PLAN.md` - World structure
- `docs/plans/p1/REGION_SPECIFICATIONS.md` - Region details
