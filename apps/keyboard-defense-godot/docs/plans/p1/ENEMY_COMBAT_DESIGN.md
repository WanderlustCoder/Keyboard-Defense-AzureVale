# Enemy & Combat Design

**Created:** 2026-01-08

Complete specification for enemy types, behaviors, combat mechanics, and encounter design.

---

## Combat Overview

### Core Combat Loop

```
┌─────────────────────────────────────────────────────────────┐
│                    COMBAT FLOW                              │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. ENEMY SPAWNS                                            │
│     └── Word assigned based on lesson + difficulty          │
│                                                             │
│  2. ENEMY ADVANCES                                          │
│     └── Moves toward castle at set speed                    │
│                                                             │
│  3. PLAYER TARGETS                                          │
│     └── Typing first letter locks target                    │
│                                                             │
│  4. PLAYER TYPES                                            │
│     └── Each correct letter = damage to enemy               │
│     └── Mistakes = penalty (varies by mode)                 │
│                                                             │
│  5. WORD COMPLETE                                           │
│     └── Enemy defeated, rewards granted                     │
│     └── Combo system engaged                                │
│                                                             │
│  6. REPEAT until wave complete                              │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Damage Calculation

```gdscript
# Base damage formula
func calculate_damage(typed_char: String, enemy: Enemy, player: Player) -> int:
    var base_damage = 1
    var speed_bonus = clamp((player.wpm - 30) / 100.0, 0, 0.5)
    var accuracy_bonus = player.current_accuracy * 0.2
    var combo_bonus = min(player.combo * 0.05, 0.5)
    var tower_bonus = get_tower_damage_bonus(enemy.position)

    var total_multiplier = 1.0 + speed_bonus + accuracy_bonus + combo_bonus + tower_bonus
    return int(base_damage * total_multiplier)
```

---

## Enemy Categories

### Tier System

| Tier | Name | Word Length | HP | Speed | Spawn Day |
|------|------|-------------|----|----|-----------|
| T1 | Minion | 3-4 | 3-4 | Fast | Day 1+ |
| T2 | Soldier | 4-6 | 5-7 | Normal | Day 3+ |
| T3 | Elite | 6-8 | 8-12 | Normal | Day 7+ |
| T4 | Champion | 8-12 | 15-20 | Slow | Day 15+ |
| T5 | Boss | 10-15 | 50-100 | Very Slow | Special |

### Base Enemy Types

#### T1: Minions

```json
{
  "enemies": [
    {
      "id": "typhos_spawn",
      "name": "Typhos Spawn",
      "tier": 1,
      "description": "Mindless void creature, easy to defeat",
      "stats": {
        "hp": 3,
        "speed": 1.2,
        "word_length": [3, 4],
        "damage_to_castle": 1
      },
      "appearance": {
        "color": "dark_purple",
        "size": "small",
        "animation": "float_wobble"
      },
      "behavior": "direct_advance",
      "special": null
    },
    {
      "id": "void_wisp",
      "name": "Void Wisp",
      "tier": 1,
      "description": "Fast but fragile",
      "stats": {
        "hp": 2,
        "speed": 1.5,
        "word_length": [3, 3],
        "damage_to_castle": 1
      },
      "behavior": "erratic_path",
      "special": "flicker_visibility"
    },
    {
      "id": "shadow_rat",
      "name": "Shadow Rat",
      "tier": 1,
      "description": "Comes in swarms",
      "stats": {
        "hp": 2,
        "speed": 1.3,
        "word_length": [3, 4],
        "damage_to_castle": 1
      },
      "behavior": "swarm",
      "special": "spawn_in_groups_of_3"
    }
  ]
}
```

#### T2: Soldiers

```json
{
  "enemies": [
    {
      "id": "typhos_scout",
      "name": "Typhos Scout",
      "tier": 2,
      "description": "Standard void soldier",
      "stats": {
        "hp": 5,
        "speed": 1.0,
        "word_length": [4, 5],
        "damage_to_castle": 2
      },
      "behavior": "direct_advance",
      "special": null
    },
    {
      "id": "corrupted_archer",
      "name": "Corrupted Archer",
      "tier": 2,
      "description": "Attacks from range",
      "stats": {
        "hp": 4,
        "speed": 0.8,
        "word_length": [5, 6],
        "damage_to_castle": 1
      },
      "behavior": "stop_and_attack",
      "special": {
        "type": "ranged_attack",
        "range": 3,
        "damage": 2,
        "interval": 5.0
      }
    },
    {
      "id": "void_hound",
      "name": "Void Hound",
      "tier": 2,
      "description": "Fast hunter",
      "stats": {
        "hp": 6,
        "speed": 1.4,
        "word_length": [4, 5],
        "damage_to_castle": 3
      },
      "behavior": "charge_attack",
      "special": "speed_burst_when_damaged"
    }
  ]
}
```

#### T3: Elites

```json
{
  "enemies": [
    {
      "id": "typhos_raider",
      "name": "Typhos Raider",
      "tier": 3,
      "description": "Armored void warrior",
      "stats": {
        "hp": 10,
        "speed": 0.9,
        "word_length": [6, 8],
        "damage_to_castle": 4
      },
      "behavior": "direct_advance",
      "special": {
        "type": "armor",
        "reduction": 1
      }
    },
    {
      "id": "shadow_mage",
      "name": "Shadow Mage",
      "tier": 3,
      "description": "Casts debuffs on player",
      "stats": {
        "hp": 7,
        "speed": 0.7,
        "word_length": [7, 8],
        "damage_to_castle": 2
      },
      "behavior": "support_caster",
      "special": {
        "type": "debuff",
        "effect": "scramble_next_word",
        "interval": 8.0
      }
    },
    {
      "id": "void_knight",
      "name": "Void Knight",
      "tier": 3,
      "description": "Shields nearby enemies",
      "stats": {
        "hp": 12,
        "speed": 0.8,
        "word_length": [6, 7],
        "damage_to_castle": 5
      },
      "behavior": "guardian",
      "special": {
        "type": "aura",
        "effect": "shield_allies",
        "radius": 2,
        "shield_amount": 2
      }
    }
  ]
}
```

#### T4: Champions

```json
{
  "enemies": [
    {
      "id": "typhos_lord",
      "name": "Typhos Lord",
      "tier": 4,
      "description": "Mini-boss, leads waves",
      "stats": {
        "hp": 18,
        "speed": 0.6,
        "word_length": [8, 10],
        "damage_to_castle": 8
      },
      "behavior": "commander",
      "special": {
        "type": "summon",
        "summons": "typhos_spawn",
        "count": 2,
        "interval": 10.0
      }
    },
    {
      "id": "corrupted_giant",
      "name": "Corrupted Giant",
      "tier": 4,
      "description": "Massive, devastating",
      "stats": {
        "hp": 25,
        "speed": 0.4,
        "word_length": [10, 12],
        "damage_to_castle": 15
      },
      "behavior": "siege",
      "special": {
        "type": "ground_pound",
        "effect": "stun_towers",
        "duration": 2.0,
        "interval": 15.0
      }
    },
    {
      "id": "void_assassin",
      "name": "Void Assassin",
      "tier": 4,
      "description": "Teleports, hard to track",
      "stats": {
        "hp": 15,
        "speed": 1.0,
        "word_length": [8, 10],
        "damage_to_castle": 10
      },
      "behavior": "teleporter",
      "special": {
        "type": "teleport",
        "distance": 3,
        "interval": 6.0,
        "resets_word": true
      }
    }
  ]
}
```

---

## Enemy Affixes

Affixes modify base enemies to create variety.

### Affix Types

| Affix | Visual | Effect | Counter |
|-------|--------|--------|---------|
| **Armored** | Metal plates | -1 damage taken | High accuracy combo |
| **Swift** | Speed lines | +30% speed | Quick targeting |
| **Shielded** | Bubble | Must break shield first | Type shield word |
| **Burning** | Fire aura | Damages nearby towers | Holy tower |
| **Frozen** | Ice crystals | Slows towers in range | Fire tower |
| **Toxic** | Green cloud | Poisons on mistake | Accuracy focus |
| **Vampiric** | Red glow | Heals on damage dealt | Kill fast |
| **Enraged** | Pulsing red | +50% damage, -20% HP | Prioritize |

### Affix Application

```json
{
  "affix_rules": {
    "min_day": 5,
    "chance_by_tier": {
      "T1": 0.05,
      "T2": 0.15,
      "T3": 0.30,
      "T4": 0.50
    },
    "max_affixes": {
      "T1": 1,
      "T2": 1,
      "T3": 2,
      "T4": 3
    },
    "incompatible_pairs": [
      ["burning", "frozen"],
      ["swift", "armored"]
    ]
  }
}
```

### Affix Visuals

```json
{
  "affix_visuals": {
    "armored": {
      "sprite_overlay": "affix_armored.svg",
      "particle": "metal_gleam",
      "sound": "metal_clang"
    },
    "swift": {
      "sprite_overlay": "affix_swift.svg",
      "particle": "speed_lines",
      "sound": "whoosh"
    },
    "shielded": {
      "sprite_overlay": "affix_shielded.svg",
      "particle": "shield_shimmer",
      "sound": "shield_hum"
    },
    "burning": {
      "sprite_overlay": "affix_burning.svg",
      "particle": "fire_embers",
      "sound": "fire_crackle"
    },
    "frozen": {
      "sprite_overlay": "affix_frozen.svg",
      "particle": "frost_crystals",
      "sound": "ice_clink"
    },
    "toxic": {
      "sprite_overlay": "affix_toxic.svg",
      "particle": "poison_bubbles",
      "sound": "acid_drip"
    },
    "vampiric": {
      "sprite_overlay": "affix_vampiric.svg",
      "particle": "blood_drain",
      "sound": "life_steal"
    },
    "enraged": {
      "sprite_overlay": "affix_enraged.svg",
      "particle": "rage_pulse",
      "sound": "anger_roar"
    }
  }
}
```

---

## Regional Enemy Variants

### Evergrove Forest

| Enemy | Base | Modification |
|-------|------|--------------|
| Forest Imp | Typhos Spawn | Nature words only |
| Corrupted Deer | Void Hound | Faster, less HP |
| Treant Shambler | Typhos Raider | Regenerates HP |
| Grove Defiler | Typhos Lord | Summons imps |

### Sunfields Plains

| Enemy | Base | Modification |
|-------|------|--------------|
| Dust Devil | Void Wisp | Wider path |
| Plains Marauder | Typhos Scout | Groups of 2 |
| Sunscorched Warrior | Void Knight | Fire aura |
| Heat Mirage | Void Assassin | More teleports |

### Stonepass Mountains

| Enemy | Base | Modification |
|-------|------|--------------|
| Cave Crawler | Shadow Rat | Tighter swarms |
| Stone Sentinel | Typhos Raider | Extra armor |
| Crystal Horror | Shadow Mage | Reflects damage |
| Mountain Troll | Corrupted Giant | More HP |

### Mistfen Marshes

| Enemy | Base | Modification |
|-------|------|--------------|
| Bog Creeper | Typhos Spawn | Poisonous |
| Marsh Stalker | Void Hound | Stealth |
| Fen Witch | Shadow Mage | Stronger debuffs |
| Swamp Horror | Corrupted Giant | Spawns in water |

### Elemental Realms

| Realm | Theme | Special Mechanic |
|-------|-------|------------------|
| Fire | Speed | All enemies faster, less HP |
| Ice | Accuracy | Mistakes empower enemies |
| Nature | Balance | Must maintain WPM/accuracy ratio |
| Void | Chaos | Random affixes, word scrambling |

---

## Boss Encounters

### Regional Bosses

#### Grove Guardian

```json
{
  "id": "boss_grove_guardian",
  "name": "Grove Guardian",
  "region": "evergrove",
  "description": "Ancient protector of the forest, tests worthiness",
  "stats": {
    "hp": 50,
    "phases": 2,
    "word_length": [8, 12]
  },
  "phases": [
    {
      "phase": 1,
      "hp_threshold": 1.0,
      "behavior": "Nature's Test",
      "mechanics": [
        "Spawns vine walls (type to clear)",
        "Nature words only",
        "Healing roots (must type fast to interrupt)"
      ]
    },
    {
      "phase": 2,
      "hp_threshold": 0.5,
      "behavior": "Guardian's Fury",
      "mechanics": [
        "Faster attacks",
        "Summons forest creatures",
        "Root snare (accuracy challenge to escape)"
      ]
    }
  ],
  "rewards": {
    "gold": 200,
    "item": "grove_seal",
    "title": "Grove Protector"
  }
}
```

#### Sunlord Champion

```json
{
  "id": "boss_sunlord",
  "name": "Sunlord Champion",
  "region": "sunfields",
  "description": "Legendary arena fighter, master of speed",
  "stats": {
    "hp": 60,
    "phases": 3,
    "word_length": [6, 10]
  },
  "phases": [
    {
      "phase": 1,
      "hp_threshold": 1.0,
      "behavior": "Opening Bout",
      "mechanics": [
        "Speed duel format",
        "Must match 40 WPM baseline"
      ]
    },
    {
      "phase": 2,
      "hp_threshold": 0.6,
      "behavior": "Champion's Pride",
      "mechanics": [
        "WPM requirement increases to 50",
        "Combo attacks (chain words)"
      ]
    },
    {
      "phase": 3,
      "hp_threshold": 0.3,
      "behavior": "Final Stand",
      "mechanics": [
        "60 WPM required",
        "Time limit per word",
        "Victory lap (type victory phrase)"
      ]
    }
  ],
  "rewards": {
    "gold": 250,
    "item": "champion_seal",
    "title": "Arena Victor"
  }
}
```

#### Citadel Warden

```json
{
  "id": "boss_citadel_warden",
  "name": "Citadel Warden",
  "region": "stonepass",
  "description": "Ancient stone construct, guards the mountain pass",
  "stats": {
    "hp": 80,
    "phases": 2,
    "word_length": [10, 15]
  },
  "phases": [
    {
      "phase": 1,
      "hp_threshold": 1.0,
      "behavior": "Stone Defense",
      "mechanics": [
        "Extremely high armor (accuracy bonus damage)",
        "Long words only",
        "Periodic shield (must type perfectly)"
      ]
    },
    {
      "phase": 2,
      "hp_threshold": 0.4,
      "behavior": "Crumbling Rage",
      "mechanics": [
        "Armor breaks (normal damage)",
        "Debris falls (quick type to avoid)",
        "Exposes core (short words, high speed)"
      ]
    }
  ],
  "rewards": {
    "gold": 300,
    "item": "warden_seal",
    "title": "Mountain Conqueror"
  }
}
```

#### Fen Seer

```json
{
  "id": "boss_fen_seer",
  "name": "Fen Seer",
  "region": "mistfen",
  "description": "Oracle of the marshes, sees all futures",
  "stats": {
    "hp": 55,
    "phases": 3,
    "word_length": [7, 12]
  },
  "phases": [
    {
      "phase": 1,
      "hp_threshold": 1.0,
      "behavior": "Visions",
      "mechanics": [
        "Shows future words (memory test)",
        "Scrambled words",
        "Fog obscures UI"
      ]
    },
    {
      "phase": 2,
      "hp_threshold": 0.6,
      "behavior": "Prophecy",
      "mechanics": [
        "Predicts your mistakes (type carefully)",
        "Mirror words (type backwards)",
        "Time dilation (speed changes)"
      ]
    },
    {
      "phase": 3,
      "hp_threshold": 0.25,
      "behavior": "True Sight",
      "mechanics": [
        "All effects combined",
        "Must achieve consistency",
        "Final prophecy (long phrase)"
      ]
    }
  ],
  "rewards": {
    "gold": 275,
    "item": "seer_seal",
    "title": "Fate Defier"
  }
}
```

### Elemental Realm Bosses

#### Flame Tyrant

```json
{
  "id": "boss_flame_tyrant",
  "name": "Flame Tyrant",
  "realm": "fire",
  "focus": "Pure Speed",
  "stats": {
    "hp": 100,
    "phases": 3
  },
  "mechanics": {
    "heat_meter": "Builds constantly, speed typing cools",
    "fire_waves": "Must clear words before they hit",
    "burn_stacks": "Mistakes add burn damage over time"
  },
  "victory_condition": "Maintain 60+ WPM for final phase"
}
```

#### Frost Empress

```json
{
  "id": "boss_frost_empress",
  "name": "Frost Empress",
  "realm": "ice",
  "focus": "Pure Accuracy",
  "stats": {
    "hp": 100,
    "phases": 3
  },
  "mechanics": {
    "frost_meter": "Builds on mistakes, perfect words clear",
    "ice_shards": "Each error spawns additional enemy",
    "frozen_keys": "Random keys become unusable temporarily"
  },
  "victory_condition": "95%+ accuracy in final phase"
}
```

#### Ancient Treant

```json
{
  "id": "boss_ancient_treant",
  "name": "Ancient Treant",
  "realm": "nature",
  "focus": "Balance",
  "stats": {
    "hp": 120,
    "phases": 4
  },
  "mechanics": {
    "harmony_meter": "Must balance speed and accuracy",
    "growth_cycle": "Boss heals if unbalanced",
    "seasonal_shift": "Mechanics change each phase"
  },
  "victory_condition": "Maintain harmony (±10% balance) throughout"
}
```

### Final Boss: Void Tyrant

```json
{
  "id": "boss_void_tyrant",
  "name": "The Void Tyrant",
  "location": "void_rift",
  "description": "Lord of Silence, Master of Unwritten Words",
  "stats": {
    "hp": 200,
    "phases": 4
  },
  "phases": [
    {
      "phase": 1,
      "name": "Whispers of Doubt",
      "hp_range": [200, 150],
      "mechanics": [
        "Words fade if not typed quickly",
        "Whispers mock the player (flavor text)",
        "Occasional word scrambling"
      ],
      "dialogue": "So... another... who thinks... words have... power..."
    },
    {
      "phase": 2,
      "name": "Silence Falls",
      "hp_range": [150, 100],
      "mechanics": [
        "Audio muted (visual-only cues)",
        "Letters disappear from words",
        "Typhos reinforcements"
      ],
      "dialogue": "Every... mistake... feeds me..."
    },
    {
      "phase": 3,
      "name": "Void Corruption",
      "hp_range": [100, 50],
      "mechanics": [
        "Keys randomly swap positions visually",
        "Words written backwards",
        "Reality glitches (screen effects)"
      ],
      "dialogue": "You type... fast. But can you... type... TRUE?"
    },
    {
      "phase": 4,
      "name": "The Last Word",
      "hp_range": [50, 0],
      "mechanics": [
        "All previous mechanics combined",
        "Must type the Perfect Sentence",
        "One chance (checkpoint if fail)"
      ],
      "dialogue": "The silence... will come... eventually...",
      "perfect_sentence": "The quick brown fox jumps over the lazy dog."
    }
  ],
  "rewards": {
    "gold": 1000,
    "item": "void_crown",
    "title": "True Typist",
    "unlock": "true_ending"
  }
}
```

---

## Wave Composition

### Wave Templates

```json
{
  "wave_templates": {
    "easy_wave": {
      "enemy_count": [5, 8],
      "tier_weights": {"T1": 0.8, "T2": 0.2},
      "spawn_interval": 2.0,
      "affix_chance": 0
    },
    "normal_wave": {
      "enemy_count": [8, 12],
      "tier_weights": {"T1": 0.5, "T2": 0.4, "T3": 0.1},
      "spawn_interval": 1.5,
      "affix_chance": 0.1
    },
    "hard_wave": {
      "enemy_count": [10, 15],
      "tier_weights": {"T1": 0.3, "T2": 0.4, "T3": 0.25, "T4": 0.05},
      "spawn_interval": 1.2,
      "affix_chance": 0.2
    },
    "boss_wave": {
      "enemy_count": [1, 1],
      "tier_weights": {"T5": 1.0},
      "spawn_interval": 0,
      "affix_chance": 0,
      "pre_adds": {"T2": 4, "T3": 2}
    },
    "swarm_wave": {
      "enemy_count": [20, 30],
      "tier_weights": {"T1": 1.0},
      "spawn_interval": 0.5,
      "affix_chance": 0
    },
    "elite_wave": {
      "enemy_count": [5, 8],
      "tier_weights": {"T3": 0.7, "T4": 0.3},
      "spawn_interval": 2.0,
      "affix_chance": 0.4
    }
  }
}
```

### Day-Based Scaling

```json
{
  "scaling": {
    "hp_per_day": 0.05,
    "speed_per_day": 0.01,
    "word_length_per_10_days": 1,
    "affix_chance_per_day": 0.01,
    "tier_upgrade_days": [5, 10, 20, 35]
  }
}
```

---

## Combat Modifiers

### Combo System

```
┌─────────────────────────────────────────────────────────────┐
│                    COMBO SYSTEM                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  COMBO BUILDS:                                              │
│  - Perfect word (no mistakes): +1 combo                     │
│  - Quick kill (under 2 sec): +1 combo                       │
│  - Chain kill (within 1 sec): +2 combo                      │
│                                                             │
│  COMBO BREAKS:                                              │
│  - Any typing mistake                                       │
│  - Enemy reaches castle                                     │
│  - 3 seconds without kill                                   │
│                                                             │
│  COMBO REWARDS:                                             │
│  - 5+ combo: 1.2x damage                                    │
│  - 10+ combo: 1.4x damage, sparkle effect                   │
│  - 20+ combo: 1.6x damage, screen shake                     │
│  - 50+ combo: 2.0x damage, legendary glow                   │
│  - 100+ combo: Achievement unlock                           │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Status Effects

| Effect | Duration | Impact | Source |
|--------|----------|--------|--------|
| **Slowed** | 3s | -30% speed | Ice tower |
| **Burning** | 5s | DoT damage | Fire tower |
| **Stunned** | 2s | Cannot move | Holy tower |
| **Weakened** | 4s | +25% damage taken | Arcane tower |
| **Marked** | 10s | Prioritized targeting | Multi tower |
| **Poisoned** | 6s | DoT + slower heal | Siege tower |

---

## Implementation Checklist

- [ ] Create enemy data files for all tiers
- [ ] Implement affix system
- [ ] Build regional variant generation
- [ ] Create boss encounter scripts
- [ ] Implement wave composition system
- [ ] Add combo system
- [ ] Create status effect handlers
- [ ] Add enemy spawn animations
- [ ] Implement enemy death effects
- [ ] Add boss phase transitions
- [ ] Create enemy sound effects
- [ ] Balance HP/speed/damage values

---

## References

- `sim/types.gd` - Enemy type definitions
- `sim/world_tick.gd` - Combat simulation
- `game/grid_renderer.gd` - Enemy rendering
- `data/enemies.json` - Enemy data (to be created)
- `docs/plans/p1/REGION_SPECIFICATIONS.md` - Regional variants
