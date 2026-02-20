# Player Progression & Skills System

**Created:** 2026-01-08

Complete specification for player advancement, skill trees, and unlock systems.

---

## Progression Overview

### Progression Pillars

```
┌─────────────────────────────────────────────────────────────┐
│                 PROGRESSION SYSTEMS                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. TYPING MASTERY                                          │
│     └── Lesson completion → Star ratings → Mastery badges  │
│                                                             │
│  2. CHARACTER LEVEL                                         │
│     └── XP from battles → Level ups → Stat points          │
│                                                             │
│  3. SKILL TREES                                             │
│     └── Skill points → Unlock abilities → Synergies        │
│                                                             │
│  4. REPUTATION                                              │
│     └── Regional standing → NPC relationships → Rewards    │
│                                                             │
│  5. ACHIEVEMENT PROGRESS                                    │
│     └── Milestones → Titles → Cosmetics                    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Typing Mastery System

### Lesson Progression

```
┌─────────────────────────────────────────────────────────────┐
│                   LESSON MASTERY                            │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Lesson: Home Row Fundamentals                              │
│                                                             │
│  Progress: ████████░░ 80%                                  │
│                                                             │
│  Stars: ★★★☆☆                                               │
│                                                             │
│  Requirements for next star:                                │
│  ┌─────────────────────────────────────────┐               │
│  │ ★ Complete lesson            ✓         │               │
│  │ ★★ 85% accuracy              ✓         │               │
│  │ ★★★ 90% accuracy             ✓         │               │
│  │ ★★★★ 95% accuracy + 30 WPM   ○         │               │
│  │ ★★★★★ 98% accuracy + 40 WPM  ○         │               │
│  └─────────────────────────────────────────┘               │
│                                                             │
│  Mastery Badge: Unlocks at ★★★★★                           │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Star Requirements

| Stars | Accuracy | WPM | Bonus |
|-------|----------|-----|-------|
| ★ | 60%+ | Any | Lesson complete |
| ★★ | 85%+ | Any | +10% XP |
| ★★★ | 90%+ | 25+ | +5% gold |
| ★★★★ | 95%+ | 35+ | Unlock advanced |
| ★★★★★ | 98%+ | 45+ | Mastery badge |

### Mastery Badges

```json
{
  "mastery_badges": {
    "home_row_master": {
      "lessons": ["home_row_1", "home_row_2", "home_row_words"],
      "reward": {
        "title": "Home Row Master",
        "buff": "+5% accuracy on ASDF JKL; keys"
      }
    },
    "reach_row_master": {
      "lessons": ["reach_row_1", "reach_row_2", "reach_row_words"],
      "reward": {
        "title": "Reach Master",
        "buff": "+3 WPM when typing reach row"
      }
    },
    "full_keyboard_master": {
      "lessons": ["all_basic_lessons"],
      "reward": {
        "title": "Keyboard Master",
        "buff": "+10% XP from all sources"
      }
    },
    "sentence_master": {
      "lessons": ["all_sentence_lessons"],
      "reward": {
        "title": "Sentence Sage",
        "buff": "Sentences deal +20% damage"
      }
    }
  }
}
```

---

## Character Level System

### XP Sources

| Source | Base XP | Multipliers |
|--------|---------|-------------|
| Enemy defeated | 5-20 | Tier * 5 |
| Wave completed | 50 | +10% per perfect wave |
| Lesson completed | 100 | Stars * 0.5 |
| Quest completed | 200-500 | Difficulty based |
| Boss defeated | 500-2000 | Boss tier |
| Daily challenge | 100-300 | Challenge difficulty |
| Achievement | 50-500 | Achievement tier |

### Level Progression

```json
{
  "level_curve": {
    "formula": "base_xp * (level ^ 1.5)",
    "base_xp": 100,
    "examples": {
      "level_1_to_2": 100,
      "level_5_to_6": 559,
      "level_10_to_11": 1581,
      "level_20_to_21": 4472,
      "level_50_to_51": 17678
    },
    "max_level": 100
  }
}
```

### Level Rewards

| Level | Reward Type | Amount |
|-------|-------------|--------|
| Every level | Stat point | 1 |
| Every 5 levels | Skill point | 1 |
| Every 10 levels | Equipment slot unlock | 1 |
| Level 25 | Prestige option available | - |
| Level 50 | Elite mode unlocked | - |
| Level 100 | Legendary title | - |

### Stat Points

```
┌─────────────────────────────────────────────────────────────┐
│                   CHARACTER STATS                           │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Available Points: 3                   [Auto-Distribute]    │
│                                                             │
│  PRECISION   ████████░░ 8  [+]                             │
│  → +0.5% accuracy per point                                 │
│                                                             │
│  VELOCITY    ██████░░░░ 6  [+]                             │
│  → +1 WPM bonus per point                                   │
│                                                             │
│  FORTITUDE   ████░░░░░░ 4  [+]                             │
│  → +5 castle HP per point                                   │
│                                                             │
│  FORTUNE     ██░░░░░░░░ 2  [+]                             │
│  → +2% gold bonus per point                                 │
│                                                             │
│  WISDOM      █████░░░░░ 5  [+]                             │
│  → +3% XP bonus per point                                   │
│                                                             │
│                                         [Reset - 100g]      │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Skill Trees

### Skill Tree Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    SKILL TREES                              │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  [SPEED]         [ACCURACY]       [DEFENSE]                │
│     │                │                │                     │
│  Focus on        Focus on         Focus on                  │
│  typing fast     perfect typing   survival                  │
│                                                             │
│  [TOWERS]        [UTILITY]        [MASTERY]                │
│     │                │                │                     │
│  Tower           Quality of       Advanced                  │
│  buffs           life buffs       techniques                │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Speed Tree

```json
{
  "tree": "speed",
  "name": "Way of the Swift",
  "description": "Master the art of rapid typing",
  "skills": [
    {
      "id": "swift_start",
      "name": "Quick Start",
      "tier": 1,
      "cost": 1,
      "max_ranks": 3,
      "effect": "+2 WPM per rank",
      "prerequisites": []
    },
    {
      "id": "momentum",
      "name": "Momentum",
      "tier": 1,
      "cost": 1,
      "max_ranks": 3,
      "effect": "Combo grants +1% speed per rank",
      "prerequisites": []
    },
    {
      "id": "burst_typing",
      "name": "Burst Typing",
      "tier": 2,
      "cost": 2,
      "max_ranks": 2,
      "effect": "First 3 words per wave +20% speed per rank",
      "prerequisites": ["swift_start"]
    },
    {
      "id": "chain_killer",
      "name": "Chain Killer",
      "tier": 2,
      "cost": 2,
      "max_ranks": 2,
      "effect": "+10% damage for kills within 1s per rank",
      "prerequisites": ["momentum"]
    },
    {
      "id": "overdrive",
      "name": "Overdrive",
      "tier": 3,
      "cost": 3,
      "max_ranks": 1,
      "effect": "Active: Double typing speed for 10s, 60s cooldown",
      "prerequisites": ["burst_typing", "chain_killer"]
    },
    {
      "id": "speed_demon",
      "name": "Speed Demon",
      "tier": 4,
      "cost": 5,
      "max_ranks": 1,
      "effect": "Passive: +15% WPM, -5% accuracy",
      "prerequisites": ["overdrive"]
    }
  ]
}
```

### Accuracy Tree

```json
{
  "tree": "accuracy",
  "name": "Way of Precision",
  "description": "Master the art of perfect typing",
  "skills": [
    {
      "id": "steady_hands",
      "name": "Steady Hands",
      "tier": 1,
      "cost": 1,
      "max_ranks": 3,
      "effect": "+1% accuracy per rank"
    },
    {
      "id": "focus",
      "name": "Focus",
      "tier": 1,
      "cost": 1,
      "max_ranks": 3,
      "effect": "Mistake penalty reduced 10% per rank"
    },
    {
      "id": "critical_strike",
      "name": "Critical Strike",
      "tier": 2,
      "cost": 2,
      "max_ranks": 2,
      "effect": "Perfect words have 15% chance for 2x damage per rank",
      "prerequisites": ["steady_hands"]
    },
    {
      "id": "recovery",
      "name": "Quick Recovery",
      "tier": 2,
      "cost": 2,
      "max_ranks": 2,
      "effect": "Mistakes don't break combo (once per 5s, -1s per rank)",
      "prerequisites": ["focus"]
    },
    {
      "id": "perfect_form",
      "name": "Perfect Form",
      "tier": 3,
      "cost": 3,
      "max_ranks": 1,
      "effect": "Active: 100% accuracy for 10s (mistakes don't register), 90s cooldown",
      "prerequisites": ["critical_strike", "recovery"]
    },
    {
      "id": "precision_master",
      "name": "Precision Master",
      "tier": 4,
      "cost": 5,
      "max_ranks": 1,
      "effect": "Passive: Perfect words deal +50% damage",
      "prerequisites": ["perfect_form"]
    }
  ]
}
```

### Defense Tree

```json
{
  "tree": "defense",
  "name": "Way of the Guardian",
  "description": "Master the art of castle defense",
  "skills": [
    {
      "id": "thick_walls",
      "name": "Thick Walls",
      "tier": 1,
      "cost": 1,
      "max_ranks": 5,
      "effect": "+10 castle HP per rank"
    },
    {
      "id": "regeneration",
      "name": "Regeneration",
      "tier": 1,
      "cost": 1,
      "max_ranks": 3,
      "effect": "Restore 1 HP per 30s per rank"
    },
    {
      "id": "damage_reduction",
      "name": "Fortification",
      "tier": 2,
      "cost": 2,
      "max_ranks": 3,
      "effect": "-5% castle damage taken per rank",
      "prerequisites": ["thick_walls"]
    },
    {
      "id": "last_stand",
      "name": "Last Stand",
      "tier": 2,
      "cost": 2,
      "max_ranks": 1,
      "effect": "At <20% HP, +30% typing damage",
      "prerequisites": ["regeneration"]
    },
    {
      "id": "emergency_repair",
      "name": "Emergency Repair",
      "tier": 3,
      "cost": 3,
      "max_ranks": 1,
      "effect": "Active: Restore 50% HP, once per battle",
      "prerequisites": ["damage_reduction", "last_stand"]
    },
    {
      "id": "immortal_fortress",
      "name": "Immortal Fortress",
      "tier": 4,
      "cost": 5,
      "max_ranks": 1,
      "effect": "Passive: Castle cannot die for 5s after reaching 0 HP",
      "prerequisites": ["emergency_repair"]
    }
  ]
}
```

### Tower Tree

```json
{
  "tree": "towers",
  "name": "Way of the Architect",
  "description": "Master the art of tower placement",
  "skills": [
    {
      "id": "tower_damage",
      "name": "Improved Towers",
      "tier": 1,
      "cost": 1,
      "max_ranks": 5,
      "effect": "+5% tower damage per rank"
    },
    {
      "id": "tower_range",
      "name": "Extended Range",
      "tier": 1,
      "cost": 1,
      "max_ranks": 3,
      "effect": "+0.5 tower range per rank"
    },
    {
      "id": "tower_speed",
      "name": "Rapid Fire",
      "tier": 2,
      "cost": 2,
      "max_ranks": 3,
      "effect": "+10% tower attack speed per rank",
      "prerequisites": ["tower_damage"]
    },
    {
      "id": "synergy_bonus",
      "name": "Tower Synergy",
      "tier": 2,
      "cost": 2,
      "max_ranks": 2,
      "effect": "Adjacent tower bonuses +50% per rank",
      "prerequisites": ["tower_range"]
    },
    {
      "id": "supercharge",
      "name": "Supercharge",
      "tier": 3,
      "cost": 3,
      "max_ranks": 1,
      "effect": "Active: All towers deal 3x damage for 10s, 120s cooldown",
      "prerequisites": ["tower_speed", "synergy_bonus"]
    },
    {
      "id": "master_architect",
      "name": "Master Architect",
      "tier": 4,
      "cost": 5,
      "max_ranks": 1,
      "effect": "Passive: Can place +2 additional towers",
      "prerequisites": ["supercharge"]
    }
  ]
}
```

### Utility Tree

```json
{
  "tree": "utility",
  "name": "Way of Prosperity",
  "description": "Master the art of resource gathering",
  "skills": [
    {
      "id": "gold_bonus",
      "name": "Treasure Hunter",
      "tier": 1,
      "cost": 1,
      "max_ranks": 5,
      "effect": "+5% gold per rank"
    },
    {
      "id": "xp_bonus",
      "name": "Quick Learner",
      "tier": 1,
      "cost": 1,
      "max_ranks": 5,
      "effect": "+5% XP per rank"
    },
    {
      "id": "item_find",
      "name": "Lucky Find",
      "tier": 2,
      "cost": 2,
      "max_ranks": 3,
      "effect": "+5% item drop rate per rank",
      "prerequisites": ["gold_bonus"]
    },
    {
      "id": "rare_find",
      "name": "Rare Finder",
      "tier": 2,
      "cost": 2,
      "max_ranks": 2,
      "effect": "+10% rare item chance per rank",
      "prerequisites": ["xp_bonus"]
    },
    {
      "id": "merchant_discount",
      "name": "Haggler",
      "tier": 3,
      "cost": 3,
      "max_ranks": 1,
      "effect": "All shop prices -20%",
      "prerequisites": ["item_find", "rare_find"]
    },
    {
      "id": "jackpot",
      "name": "Jackpot",
      "tier": 4,
      "cost": 5,
      "max_ranks": 1,
      "effect": "Passive: 1% chance for 10x gold on any enemy",
      "prerequisites": ["merchant_discount"]
    }
  ]
}
```

### Mastery Tree

```json
{
  "tree": "mastery",
  "name": "Way of the True Typist",
  "description": "Unlock your full potential",
  "skills": [
    {
      "id": "combo_mastery",
      "name": "Combo Mastery",
      "tier": 1,
      "cost": 1,
      "max_ranks": 3,
      "effect": "Combo bonuses +10% effective per rank"
    },
    {
      "id": "adaptation",
      "name": "Adaptation",
      "tier": 1,
      "cost": 1,
      "max_ranks": 3,
      "effect": "Learn new words 20% faster per rank"
    },
    {
      "id": "flow_state",
      "name": "Flow State",
      "tier": 2,
      "cost": 2,
      "max_ranks": 2,
      "effect": "At 20+ combo, +5% all stats per rank",
      "prerequisites": ["combo_mastery"]
    },
    {
      "id": "pattern_recognition",
      "name": "Pattern Recognition",
      "tier": 2,
      "cost": 2,
      "max_ranks": 2,
      "effect": "Repeated words typed 10% faster per rank",
      "prerequisites": ["adaptation"]
    },
    {
      "id": "transcendence",
      "name": "Transcendence",
      "tier": 3,
      "cost": 3,
      "max_ranks": 1,
      "effect": "Active: Time slows 50% for 15s, you type at normal speed",
      "prerequisites": ["flow_state", "pattern_recognition"]
    },
    {
      "id": "true_typist",
      "name": "True Typist",
      "tier": 4,
      "cost": 5,
      "max_ranks": 1,
      "effect": "Passive: All trees' tier 1 skills +1 rank (free)",
      "prerequisites": ["transcendence"]
    }
  ]
}
```

---

## Reputation System

### Regional Reputation

```json
{
  "reputation_regions": [
    {
      "id": "rep_evergrove",
      "name": "Evergrove Standing",
      "levels": {
        "hostile": { "range": [-1000, -500], "effect": "NPCs won't talk" },
        "unfriendly": { "range": [-499, -100], "effect": "Higher prices" },
        "neutral": { "range": [-99, 99], "effect": "Default" },
        "friendly": { "range": [100, 499], "effect": "-10% prices" },
        "honored": { "range": [500, 999], "effect": "-20% prices, bonus quests" },
        "revered": { "range": [1000, 2499], "effect": "-30% prices, unique items" },
        "exalted": { "range": [2500, null], "effect": "Special title, companion" }
      }
    }
  ]
}
```

### Reputation Gain

| Action | Rep Gain | Notes |
|--------|----------|-------|
| Complete regional quest | +50-200 | Based on difficulty |
| Defeat regional boss | +100 | Once per boss |
| Help NPC | +10-50 | Side content |
| POI discovery | +5 | First time only |
| Daily contribution | +10-25 | Repeatable |

---

## Prestige System

### Prestige Overview

```
┌─────────────────────────────────────────────────────────────┐
│                   PRESTIGE SYSTEM                           │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Available at: Level 25+                                    │
│                                                             │
│  When you prestige:                                         │
│  ✗ Reset to Level 1                                        │
│  ✗ Lose all skill points (refunded as prestige points)     │
│  ✓ Keep all equipment                                       │
│  ✓ Keep all lesson mastery                                  │
│  ✓ Keep all achievements                                    │
│  ✓ Gain Prestige Rank (permanent bonuses)                  │
│                                                             │
│  Prestige Bonuses (permanent):                              │
│  P1: +5% all XP gain                                        │
│  P2: +5% gold gain                                          │
│  P3: +1 starting skill point                                │
│  P4: +10% tower damage                                      │
│  P5: +5% accuracy                                           │
│  P10: Unique title "Eternal Typist"                         │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Prestige Points

```json
{
  "prestige_upgrades": [
    {
      "id": "prestige_xp",
      "name": "Wisdom of Ages",
      "cost": [1, 2, 3, 5, 8],
      "effect": "+5% XP per rank",
      "max_ranks": 5
    },
    {
      "id": "prestige_gold",
      "name": "Fortune's Favor",
      "cost": [1, 2, 3, 5, 8],
      "effect": "+5% gold per rank",
      "max_ranks": 5
    },
    {
      "id": "prestige_speed",
      "name": "Eternal Swiftness",
      "cost": [2, 4, 8],
      "effect": "+3 WPM per rank",
      "max_ranks": 3
    },
    {
      "id": "prestige_accuracy",
      "name": "Eternal Precision",
      "cost": [2, 4, 8],
      "effect": "+2% accuracy per rank",
      "max_ranks": 3
    },
    {
      "id": "prestige_start",
      "name": "Head Start",
      "cost": [5, 10, 20],
      "effect": "Start at level 5/10/15 after prestige",
      "max_ranks": 3
    }
  ]
}
```

---

## Implementation Checklist

- [ ] Implement lesson star rating system
- [ ] Create mastery badge tracking
- [ ] Build XP and level system
- [ ] Implement stat point allocation
- [ ] Create skill tree UI
- [ ] Implement skill effects
- [ ] Add reputation tracking
- [ ] Build prestige system
- [ ] Add skill point respec option
- [ ] Create progression save/load
- [ ] Add level-up notifications
- [ ] Balance XP curve

---

## References

- `docs/plans/p1/LESSON_PROGRESSION_TREE.md` - Lesson unlock flow
- `docs/plans/p1/MASTERY_ASSESSMENT_CRITERIA.md` - Star requirements
- `docs/plans/p1/QUEST_SIDE_CONTENT.md` - XP sources
- `game/typing_profile.gd` - Player stats
- `sim/types.gd` - Stat definitions
