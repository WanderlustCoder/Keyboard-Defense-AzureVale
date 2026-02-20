# Wave Composition System

**Last updated:** 2026-01-08

This document defines the complete wave spawning system, including enemy compositions, spawn patterns, difficulty scaling, and special wave events.

---

## Table of Contents

1. [Wave System Overview](#wave-system-overview)
2. [Standard Wave Templates](#standard-wave-templates)
3. [Regional Wave Modifiers](#regional-wave-modifiers)
4. [Special Wave Types](#special-wave-types)
5. [Boss Wave Patterns](#boss-wave-patterns)
6. [Endless Mode Scaling](#endless-mode-scaling)
7. [Dynamic Difficulty](#dynamic-difficulty)

---

## Wave System Overview

### Wave Data Structure

```json
{
  "wave_id": "string",
  "wave_number": 0,
  "type": "standard | elite | boss | event | endless",

  "spawn_groups": [
    {
      "enemy_type": "enemy_id",
      "count": 0,
      "spawn_delay": 0.0,
      "spawn_interval": 0.0,
      "spawn_point": "spawn_id",
      "affixes": []
    }
  ],

  "wave_modifiers": [],
  "rewards": {},
  "next_wave_delay": 0.0,
  "ambient_corruption": 0.0
}
```

### Spawn Point System

```json
{
  "spawn_points": {
    "main_entrance": {
      "position": {"x": 0, "y": 5},
      "path_id": "main_path",
      "weight": 60
    },
    "side_entrance_left": {
      "position": {"x": -3, "y": 3},
      "path_id": "left_flank",
      "weight": 20
    },
    "side_entrance_right": {
      "position": {"x": 3, "y": 3},
      "path_id": "right_flank",
      "weight": 20
    },
    "flying_spawn": {
      "position": {"x": 0, "y": 8},
      "path_id": "air_path",
      "weight": 0,
      "requires_flying": true
    }
  }
}
```

### Difficulty Tiers

| Tier | Wave Range | Enemy Tiers | Affix Chance | Elite Chance |
|------|------------|-------------|--------------|--------------|
| Tutorial | 1-3 | 1 only | 0% | 0% |
| Easy | 4-10 | 1-2 | 5% | 2% |
| Normal | 11-20 | 1-3 | 15% | 5% |
| Hard | 21-30 | 2-4 | 25% | 10% |
| Nightmare | 31-40 | 3-5 | 40% | 20% |
| Endless | 41+ | 3-5 | 50%+ | 25%+ |

---

## Standard Wave Templates

### Tutorial Waves (1-3)

```json
{
  "tutorial_waves": [
    {
      "wave_number": 1,
      "name": "First Contact",
      "description": "Introduction to basic enemies",
      "spawn_groups": [
        {
          "enemy_type": "typhos_spawn",
          "count": 3,
          "spawn_delay": 0,
          "spawn_interval": 3.0,
          "spawn_point": "main_entrance"
        }
      ],
      "tutorial_prompts": [
        {"trigger": "wave_start", "message": "Type the words above enemies to defeat them!"},
        {"trigger": "first_kill", "message": "Great! Keep typing to defeat the rest!"}
      ],
      "next_wave_delay": 10.0
    },
    {
      "wave_number": 2,
      "name": "Growing Threat",
      "spawn_groups": [
        {
          "enemy_type": "typhos_spawn",
          "count": 5,
          "spawn_delay": 0,
          "spawn_interval": 2.5
        }
      ],
      "tutorial_prompts": [
        {"trigger": "wave_start", "message": "More enemies! Prioritize those closest to your castle."}
      ],
      "next_wave_delay": 8.0
    },
    {
      "wave_number": 3,
      "name": "Introduction to Variety",
      "spawn_groups": [
        {
          "enemy_type": "typhos_spawn",
          "count": 4,
          "spawn_delay": 0,
          "spawn_interval": 2.0
        },
        {
          "enemy_type": "word_imp",
          "count": 2,
          "spawn_delay": 5.0,
          "spawn_interval": 3.0
        }
      ],
      "tutorial_prompts": [
        {"trigger": "word_imp_spawn", "message": "Word Imps are faster but weaker. Type quickly!"}
      ],
      "next_wave_delay": 8.0
    }
  ]
}
```

### Early Waves (4-10)

```json
{
  "early_waves": [
    {
      "wave_number": 4,
      "name": "Steady Stream",
      "spawn_groups": [
        {
          "enemy_type": "typhos_spawn",
          "count": 6,
          "spawn_interval": 2.0
        },
        {
          "enemy_type": "word_imp",
          "count": 3,
          "spawn_delay": 8.0,
          "spawn_interval": 2.5
        }
      ]
    },
    {
      "wave_number": 5,
      "name": "First Rush",
      "spawn_groups": [
        {
          "enemy_type": "typhos_spawn",
          "count": 10,
          "spawn_interval": 1.5
        }
      ],
      "wave_modifiers": ["rush"]
    },
    {
      "wave_number": 6,
      "name": "Flanking Maneuver",
      "spawn_groups": [
        {
          "enemy_type": "typhos_spawn",
          "count": 4,
          "spawn_point": "main_entrance",
          "spawn_interval": 2.0
        },
        {
          "enemy_type": "typhos_spawn",
          "count": 3,
          "spawn_point": "side_entrance_left",
          "spawn_delay": 3.0,
          "spawn_interval": 2.0
        },
        {
          "enemy_type": "typhos_spawn",
          "count": 3,
          "spawn_point": "side_entrance_right",
          "spawn_delay": 3.0,
          "spawn_interval": 2.0
        }
      ]
    },
    {
      "wave_number": 7,
      "name": "Corrupted Scout",
      "spawn_groups": [
        {
          "enemy_type": "typhos_spawn",
          "count": 5,
          "spawn_interval": 2.0
        },
        {
          "enemy_type": "glitch_runner",
          "count": 2,
          "spawn_delay": 6.0,
          "spawn_interval": 4.0
        }
      ]
    },
    {
      "wave_number": 8,
      "name": "Building Pressure",
      "spawn_groups": [
        {
          "enemy_type": "typhos_spawn",
          "count": 8,
          "spawn_interval": 1.8
        },
        {
          "enemy_type": "word_imp",
          "count": 4,
          "spawn_delay": 5.0,
          "spawn_interval": 2.0
        },
        {
          "enemy_type": "letter_crawler",
          "count": 2,
          "spawn_delay": 10.0,
          "spawn_interval": 3.0
        }
      ]
    },
    {
      "wave_number": 9,
      "name": "Armored Approach",
      "spawn_groups": [
        {
          "enemy_type": "typhos_spawn",
          "count": 6,
          "spawn_interval": 2.0
        },
        {
          "enemy_type": "shell_walker",
          "count": 2,
          "spawn_delay": 8.0,
          "spawn_interval": 5.0
        }
      ]
    },
    {
      "wave_number": 10,
      "name": "First Elite",
      "type": "elite",
      "spawn_groups": [
        {
          "enemy_type": "typhos_spawn",
          "count": 8,
          "spawn_interval": 1.5
        },
        {
          "enemy_type": "corrupted_sentinel",
          "count": 1,
          "spawn_delay": 10.0,
          "affixes": ["armored"]
        }
      ],
      "rewards": {
        "gold_bonus": 50,
        "item_drop_chance": 0.3
      }
    }
  ]
}
```

### Mid Waves (11-20)

```json
{
  "mid_waves": [
    {
      "wave_number": 11,
      "name": "Tier 2 Introduction",
      "spawn_groups": [
        {
          "enemy_type": "glitch_runner",
          "count": 4,
          "spawn_interval": 2.5
        },
        {
          "enemy_type": "typo_beast",
          "count": 3,
          "spawn_delay": 6.0,
          "spawn_interval": 3.0
        }
      ]
    },
    {
      "wave_number": 12,
      "name": "Mixed Assault",
      "spawn_groups": [
        {
          "enemy_type": "typhos_spawn",
          "count": 10,
          "spawn_interval": 1.2
        },
        {
          "enemy_type": "glitch_runner",
          "count": 5,
          "spawn_delay": 5.0,
          "spawn_interval": 2.0
        },
        {
          "enemy_type": "syntax_horror",
          "count": 2,
          "spawn_delay": 12.0,
          "spawn_interval": 4.0
        }
      ]
    },
    {
      "wave_number": 13,
      "name": "Swift Swarm",
      "wave_modifiers": ["haste"],
      "spawn_groups": [
        {
          "enemy_type": "word_imp",
          "count": 12,
          "spawn_interval": 1.0
        },
        {
          "enemy_type": "glitch_runner",
          "count": 6,
          "spawn_delay": 8.0,
          "spawn_interval": 1.5
        }
      ]
    },
    {
      "wave_number": 14,
      "name": "Three-Front War",
      "spawn_groups": [
        {
          "enemy_type": "typo_beast",
          "count": 3,
          "spawn_point": "main_entrance",
          "spawn_interval": 3.0
        },
        {
          "enemy_type": "glitch_runner",
          "count": 4,
          "spawn_point": "side_entrance_left",
          "spawn_delay": 2.0,
          "spawn_interval": 2.0
        },
        {
          "enemy_type": "glitch_runner",
          "count": 4,
          "spawn_point": "side_entrance_right",
          "spawn_delay": 2.0,
          "spawn_interval": 2.0
        }
      ]
    },
    {
      "wave_number": 15,
      "name": "Elite Duo",
      "type": "elite",
      "spawn_groups": [
        {
          "enemy_type": "typhos_spawn",
          "count": 10,
          "spawn_interval": 1.5
        },
        {
          "enemy_type": "corrupted_sentinel",
          "count": 2,
          "spawn_delay": 8.0,
          "spawn_interval": 6.0,
          "affixes": ["swift", "armored"]
        }
      ],
      "rewards": {
        "gold_bonus": 75,
        "item_drop_chance": 0.4
      }
    },
    {
      "wave_number": 16,
      "name": "Poison Cloud",
      "wave_modifiers": ["toxic_environment"],
      "spawn_groups": [
        {
          "enemy_type": "glitch_runner",
          "count": 8,
          "spawn_interval": 1.8
        },
        {
          "enemy_type": "venom_crawler",
          "count": 4,
          "spawn_delay": 6.0,
          "spawn_interval": 3.0
        }
      ]
    },
    {
      "wave_number": 17,
      "name": "Heavy Hitters",
      "spawn_groups": [
        {
          "enemy_type": "shell_walker",
          "count": 4,
          "spawn_interval": 4.0
        },
        {
          "enemy_type": "typo_beast",
          "count": 5,
          "spawn_delay": 8.0,
          "spawn_interval": 3.0
        }
      ]
    },
    {
      "wave_number": 18,
      "name": "Scrambler Emergence",
      "spawn_groups": [
        {
          "enemy_type": "glitch_runner",
          "count": 6,
          "spawn_interval": 2.0
        },
        {
          "enemy_type": "word_scrambler",
          "count": 3,
          "spawn_delay": 8.0,
          "spawn_interval": 4.0
        },
        {
          "enemy_type": "syntax_horror",
          "count": 2,
          "spawn_delay": 15.0,
          "spawn_interval": 5.0
        }
      ]
    },
    {
      "wave_number": 19,
      "name": "Pre-Boss Rush",
      "wave_modifiers": ["rush", "desperate"],
      "spawn_groups": [
        {
          "enemy_type": "typhos_spawn",
          "count": 15,
          "spawn_interval": 0.8
        },
        {
          "enemy_type": "glitch_runner",
          "count": 10,
          "spawn_delay": 5.0,
          "spawn_interval": 1.0
        },
        {
          "enemy_type": "typo_beast",
          "count": 5,
          "spawn_delay": 12.0,
          "spawn_interval": 2.0
        }
      ]
    },
    {
      "wave_number": 20,
      "name": "First Boss",
      "type": "boss",
      "spawn_groups": [
        {
          "enemy_type": "typhos_spawn",
          "count": 6,
          "spawn_interval": 2.0
        },
        {
          "enemy_type": "boss_grove_guardian",
          "count": 1,
          "spawn_delay": 10.0
        }
      ],
      "boss_mechanics": {
        "add_spawn_interval": 45.0,
        "add_types": ["typhos_spawn", "corrupted_sapling"],
        "add_counts": [4, 2]
      },
      "rewards": {
        "gold_bonus": 200,
        "item_drop_chance": 1.0,
        "guaranteed_drops": ["guardian_heartwood"]
      }
    }
  ]
}
```

### Late Waves (21-30)

```json
{
  "late_waves": [
    {
      "wave_number": 21,
      "name": "Tier 3 Introduction",
      "spawn_groups": [
        {
          "enemy_type": "typo_beast",
          "count": 6,
          "spawn_interval": 2.5
        },
        {
          "enemy_type": "grammar_abomination",
          "count": 2,
          "spawn_delay": 8.0,
          "spawn_interval": 5.0
        }
      ]
    },
    {
      "wave_number": 22,
      "name": "Affix Storm",
      "wave_modifiers": ["affix_surge"],
      "affix_override": {
        "minimum_affixes": 1,
        "affix_pool": ["swift", "armored", "enraged"]
      },
      "spawn_groups": [
        {
          "enemy_type": "typo_beast",
          "count": 8,
          "spawn_interval": 2.0,
          "affixes": ["random_1"]
        },
        {
          "enemy_type": "syntax_horror",
          "count": 4,
          "spawn_delay": 10.0,
          "spawn_interval": 3.0,
          "affixes": ["random_1"]
        }
      ]
    },
    {
      "wave_number": 25,
      "name": "Double Elite",
      "type": "elite",
      "spawn_groups": [
        {
          "enemy_type": "grammar_abomination",
          "count": 2,
          "spawn_interval": 0,
          "affixes": ["shielded", "enraged"]
        },
        {
          "enemy_type": "typo_beast",
          "count": 10,
          "spawn_delay": 5.0,
          "spawn_interval": 1.5
        }
      ]
    },
    {
      "wave_number": 30,
      "name": "Second Boss",
      "type": "boss",
      "spawn_groups": [
        {
          "enemy_type": "boss_thornweaver_matriarch",
          "count": 1,
          "spawn_delay": 5.0
        }
      ],
      "boss_mechanics": {
        "phase_triggers": [0.65, 0.30],
        "phase_adds": {
          "phase_2": {"enemy_type": "thornling", "count": 3},
          "phase_3": {"enemy_type": "vine_horror", "count": 2}
        }
      }
    }
  ]
}
```

### Nightmare Waves (31-40)

```json
{
  "nightmare_waves": [
    {
      "wave_number": 31,
      "name": "Tier 4 Introduction",
      "spawn_groups": [
        {
          "enemy_type": "grammar_abomination",
          "count": 5,
          "spawn_interval": 3.0
        },
        {
          "enemy_type": "paragraph_horror",
          "count": 2,
          "spawn_delay": 10.0,
          "spawn_interval": 6.0
        }
      ]
    },
    {
      "wave_number": 35,
      "name": "Multi-Affix Assault",
      "spawn_groups": [
        {
          "enemy_type": "paragraph_horror",
          "count": 3,
          "spawn_interval": 5.0,
          "affixes": ["armored", "vampiric"]
        },
        {
          "enemy_type": "syntax_horror",
          "count": 6,
          "spawn_delay": 8.0,
          "spawn_interval": 2.0,
          "affixes": ["swift", "burning"]
        }
      ]
    },
    {
      "wave_number": 40,
      "name": "Region Boss",
      "type": "boss",
      "region_specific": true,
      "spawn_groups": [
        {
          "enemy_type": "boss_stone_colossus",
          "count": 1,
          "spawn_delay": 5.0
        }
      ],
      "rewards": {
        "gold_bonus": 500,
        "item_drop_chance": 1.0,
        "guaranteed_drops": ["colossus_core_fragment", "binding_key_fragment"]
      }
    }
  ]
}
```

---

## Regional Wave Modifiers

### Evergrove Modifiers

```json
{
  "region": "evergrove",
  "modifiers": {
    "nature_themed": {
      "description": "Plant-based enemies more common",
      "enemy_weight_adjustments": {
        "corrupted_sapling": 1.5,
        "vine_horror": 1.3,
        "thornling": 1.4
      }
    },
    "overgrowth": {
      "description": "Random vine obstacles spawn on paths",
      "obstacle_spawn_chance": 0.2,
      "obstacle_type": "vine_wall",
      "obstacle_hp": 20
    },
    "forest_ambush": {
      "description": "Enemies may spawn from forest edges",
      "additional_spawn_points": ["forest_edge_1", "forest_edge_2"],
      "ambush_chance": 0.15
    },
    "corrupted_wildlife": {
      "description": "Nature-based affixes more common",
      "affix_weights": {
        "toxic": 1.5,
        "regenerating": 1.3
      }
    }
  },
  "special_waves": [
    {
      "wave_id": "evergrove_special_1",
      "name": "Root Eruption",
      "trigger": "random_mid_wave",
      "effect": "Roots burst from ground, spawning 10 Corrupted Saplings simultaneously"
    },
    {
      "wave_id": "evergrove_special_2",
      "name": "Pollen Storm",
      "trigger": "random_late_wave",
      "effect": "All enemies gain 'toxic' affix for wave duration"
    }
  ]
}
```

### Stonepass Modifiers

```json
{
  "region": "stonepass",
  "modifiers": {
    "metal_themed": {
      "description": "Armored enemies more common",
      "enemy_weight_adjustments": {
        "shell_walker": 1.5,
        "iron_golem": 1.4,
        "steel_construct": 1.3
      }
    },
    "cave_in": {
      "description": "Random rockfalls deal damage to random tiles",
      "rockfall_chance": 0.1,
      "rockfall_damage": 15,
      "affects_towers": true
    },
    "tunnel_network": {
      "description": "Enemies may emerge from tunnel exits",
      "tunnel_spawn_points": ["tunnel_exit_a", "tunnel_exit_b", "tunnel_exit_c"],
      "tunnel_spawn_chance": 0.2
    },
    "dwarven_fortifications": {
      "description": "Pre-placed defensive structures on some maps",
      "structure_types": ["barricade", "arrow_slit", "oil_trap"]
    }
  },
  "special_waves": [
    {
      "wave_id": "stonepass_special_1",
      "name": "Mining Expedition",
      "trigger": "every_5_waves",
      "effect": "3 heavily armored Forge Constructs emerge from mine entrance"
    },
    {
      "wave_id": "stonepass_special_2",
      "name": "Tunnel Collapse",
      "trigger": "random_late_wave",
      "effect": "All paths blocked except one for 30 seconds"
    }
  ]
}
```

### Mistfen Modifiers

```json
{
  "region": "mistfen",
  "modifiers": {
    "mist_themed": {
      "description": "Enemies may be invisible until close",
      "visibility_reduction": true,
      "reveal_range": 4
    },
    "arcane_corruption": {
      "description": "Magic-based enemies and effects more common",
      "enemy_weight_adjustments": {
        "mist_phantom": 1.5,
        "spell_wraith": 1.4,
        "arcane_horror": 1.3
      }
    },
    "fog_bank": {
      "description": "Random fog patches reduce tower range",
      "fog_spawn_chance": 0.15,
      "range_reduction": 2,
      "fog_duration": 20.0
    },
    "word_scrambling": {
      "description": "Some enemies scramble nearby word displays",
      "scramble_chance": 0.1,
      "scramble_radius": 3
    }
  },
  "special_waves": [
    {
      "wave_id": "mistfen_special_1",
      "name": "Mist Surge",
      "trigger": "random_wave",
      "effect": "Entire map covered in mist, visibility reduced to 2 tiles for 30 seconds"
    },
    {
      "wave_id": "mistfen_special_2",
      "name": "Phantom Legion",
      "trigger": "random_late_wave",
      "effect": "20 Mist Phantoms spawn simultaneously, each with 'phasing' affix"
    }
  ]
}
```

---

## Special Wave Types

### Event Waves

```json
{
  "event_waves": [
    {
      "wave_type": "treasure_goblin",
      "name": "Treasure Horde",
      "trigger_chance": 0.05,
      "spawn_groups": [
        {
          "enemy_type": "gold_imp",
          "count": 5,
          "spawn_interval": 0.5,
          "behavior": "flee_to_exit"
        }
      ],
      "rewards": {
        "gold_per_kill": 50,
        "bonus_all_killed": 200
      },
      "special_rules": {
        "time_limit": 15.0,
        "enemies_flee": true
      }
    },
    {
      "wave_type": "corruption_surge",
      "name": "Corruption Surge",
      "trigger": "corruption_above_75",
      "spawn_groups": [
        {
          "enemy_type": "corruption_spawn",
          "count": 20,
          "spawn_interval": 0.3,
          "spawn_point": "corruption_rift"
        }
      ],
      "wave_modifiers": ["corruption_empowered"],
      "special_rules": {
        "corruption_increases_during_wave": true,
        "rate": 1.0
      }
    },
    {
      "wave_type": "letter_spirit_blessing",
      "name": "Spirit's Challenge",
      "trigger_chance": 0.03,
      "spawn_groups": [
        {
          "enemy_type": "spirit_guardian",
          "count": 1,
          "affixes": ["holy", "challenging"]
        }
      ],
      "special_rules": {
        "accuracy_requirement": 0.98,
        "reward_on_perfect": "letter_spirit_blessing",
        "failure_penalty": "none"
      }
    },
    {
      "wave_type": "merchant_caravan",
      "name": "Caravan Defense",
      "trigger": "random_event",
      "spawn_groups": [
        {
          "enemy_type": "bandit_raider",
          "count": 15,
          "spawn_interval": 1.0,
          "target": "merchant_caravan"
        }
      ],
      "protection_target": {
        "type": "merchant_caravan",
        "hp": 100,
        "path": "caravan_path"
      },
      "rewards": {
        "caravan_survives": {"gold": 300, "item_shop_discount": 0.2},
        "caravan_destroyed": {"gold": 50}
      }
    }
  ]
}
```

### Challenge Waves

```json
{
  "challenge_waves": [
    {
      "challenge_id": "speed_trial",
      "name": "Speed Trial",
      "description": "Complete the wave within time limit",
      "time_limit": 60.0,
      "spawn_groups": [
        {
          "enemy_type": "speed_demon",
          "count": 30,
          "spawn_interval": 0.5
        }
      ],
      "rewards": {
        "completion": {"gold": 200},
        "time_bonus": {"per_second_remaining": 5}
      }
    },
    {
      "challenge_id": "accuracy_trial",
      "name": "Precision Strike",
      "description": "Maintain 98% accuracy throughout wave",
      "accuracy_requirement": 0.98,
      "spawn_groups": [
        {
          "enemy_type": "precision_target",
          "count": 20,
          "spawn_interval": 2.0
        }
      ],
      "fail_condition": "accuracy_below_98",
      "rewards": {
        "completion": {"gold": 300, "item": "accuracy_charm"}
      }
    },
    {
      "challenge_id": "no_damage",
      "name": "Perfect Defense",
      "description": "Complete wave without taking castle damage",
      "no_damage_requirement": true,
      "spawn_groups": [
        {
          "enemy_type": "mixed_tier_2",
          "count": 25,
          "spawn_interval": 1.5
        }
      ],
      "rewards": {
        "completion": {"gold": 400, "castle_repair": 10}
      }
    },
    {
      "challenge_id": "tower_limit",
      "name": "Minimalist",
      "description": "Complete wave using only 3 towers",
      "tower_limit": 3,
      "spawn_groups": [
        {
          "enemy_type": "standard_mix",
          "count": 30,
          "spawn_interval": 1.2
        }
      ],
      "rewards": {
        "completion": {"gold": 500, "skill_point": 1}
      }
    }
  ]
}
```

---

## Boss Wave Patterns

### Boss Add Spawn Patterns

```json
{
  "boss_add_patterns": {
    "grove_guardian": {
      "phase_1_adds": {
        "trigger": "every_30_seconds",
        "enemies": [
          {"type": "corrupted_sapling", "count": 2}
        ]
      },
      "phase_2_adds": {
        "trigger": "every_20_seconds",
        "enemies": [
          {"type": "corrupted_sapling", "count": 3},
          {"type": "vine_horror", "count": 1}
        ]
      },
      "phase_3_adds": {
        "trigger": "every_15_seconds",
        "enemies": [
          {"type": "thornling", "count": 4},
          {"type": "corrupted_treant", "count": 1}
        ]
      }
    },
    "stone_colossus": {
      "phase_1_adds": {
        "trigger": "chain_break",
        "enemies": [
          {"type": "rock_fragment", "count": 5}
        ]
      },
      "phase_2_adds": {
        "trigger": "every_25_seconds",
        "enemies": [
          {"type": "stone_golem", "count": 2}
        ]
      },
      "phase_3_adds": {
        "trigger": "rune_activation",
        "enemies": [
          {"type": "rune_construct", "count": 3}
        ]
      },
      "phase_4_adds": {
        "trigger": "crumbling",
        "continuous": true,
        "enemies": [
          {"type": "debris_swarm", "count": 2, "interval": 5.0}
        ]
      }
    },
    "mist_wraith": {
      "phase_1_adds": {
        "trigger": "clone_creation",
        "enemies": [
          {"type": "mist_clone", "count": 2}
        ]
      },
      "phase_2_adds": {
        "trigger": "memory_attack",
        "enemies": [
          {"type": "memory_fragment", "count": 3}
        ]
      },
      "phase_3_adds": {
        "trigger": "reality_flux",
        "random": true,
        "enemies": [
          {"type": "random_tier_3", "count": 4}
        ]
      }
    }
  }
}
```

### Boss Enrage Patterns

```json
{
  "boss_enrage_patterns": {
    "default": {
      "trigger": "timer",
      "timer_seconds": 300,
      "effects": {
        "damage_multiplier": 2.0,
        "attack_speed_multiplier": 1.5,
        "telegraph_reduction": 0.5
      }
    },
    "grove_guardian_enrage": {
      "trigger": "timer",
      "timer_seconds": 300,
      "effects": {
        "damage_multiplier": 2.0,
        "continuous_root_spawn": true,
        "no_telegraphs": true
      },
      "dialogue": "NO MORE... MERCY... ONLY... CORRUPTION..."
    },
    "mist_wraith_enrage": {
      "trigger": "timer",
      "timer_seconds": 400,
      "effects": {
        "permanent_invisibility": true,
        "attack_speed_multiplier": 2.0,
        "word_scramble_all": true
      },
      "dialogue": "YOU HAVE WASTED... TOO MUCH TIME... NOW FACE... OBLIVION..."
    }
  }
}
```

---

## Endless Mode Scaling

### Scaling Formulas

```json
{
  "endless_scaling": {
    "enemy_hp_scaling": {
      "formula": "base_hp * (1 + (wave - 40) * 0.05)",
      "example": "Wave 50: base_hp * 1.5, Wave 100: base_hp * 4.0"
    },
    "enemy_damage_scaling": {
      "formula": "base_damage * (1 + (wave - 40) * 0.03)",
      "example": "Wave 50: base_damage * 1.3"
    },
    "enemy_count_scaling": {
      "formula": "base_count * (1 + (wave - 40) * 0.02)",
      "max_multiplier": 3.0
    },
    "affix_scaling": {
      "affix_chance_base": 0.5,
      "affix_chance_per_10_waves": 0.05,
      "max_affixes_scaling": {
        "wave_50": 2,
        "wave_75": 3,
        "wave_100": 4,
        "wave_150": 5
      }
    },
    "spawn_interval_scaling": {
      "formula": "base_interval * max(0.3, 1 - (wave - 40) * 0.01)",
      "minimum_interval": 0.3
    }
  }
}
```

### Endless Wave Generation

```json
{
  "endless_wave_generator": {
    "base_template": {
      "main_enemy_pool": ["tier_3", "tier_4", "tier_5"],
      "support_enemy_pool": ["tier_2", "tier_3"],
      "elite_pool": ["tier_4_elite", "tier_5_elite"]
    },
    "wave_composition_rules": {
      "main_enemies": {
        "count_formula": "10 + (wave - 40) * 0.5",
        "tier_weights": {
          "tier_3": "max(0, 60 - (wave - 40))",
          "tier_4": "30 + (wave - 40) * 0.5",
          "tier_5": "(wave - 60) * 2"
        }
      },
      "support_enemies": {
        "count_formula": "5 + (wave - 40) * 0.3"
      },
      "elite_chance": {
        "base": 0.25,
        "per_10_waves": 0.05,
        "max": 0.75
      }
    },
    "special_endless_waves": {
      "every_10_waves": "boss_wave",
      "every_25_waves": "super_elite_wave",
      "every_50_waves": "raid_boss_wave"
    },
    "mutation_system": {
      "description": "Every 10 waves, a random mutation applies to all future waves",
      "mutation_pool": [
        {"id": "speed_mutation", "effect": "All enemies +20% speed"},
        {"id": "armor_mutation", "effect": "All enemies gain 'armored' affix"},
        {"id": "swarm_mutation", "effect": "Enemy count +50%, individual HP -30%"},
        {"id": "champion_mutation", "effect": "Elite chance +25%"},
        {"id": "corruption_mutation", "effect": "Corruption increases faster"}
      ],
      "max_active_mutations": 5
    }
  }
}
```

### Leaderboard Waves

```json
{
  "leaderboard_milestones": [
    {"wave": 50, "title": "Survivor", "reward": "endless_badge_bronze"},
    {"wave": 75, "title": "Defender", "reward": "endless_badge_silver"},
    {"wave": 100, "title": "Champion", "reward": "endless_badge_gold"},
    {"wave": 150, "title": "Legend", "reward": "endless_badge_platinum"},
    {"wave": 200, "title": "Immortal", "reward": "endless_badge_diamond"}
  ]
}
```

---

## Dynamic Difficulty

### Performance-Based Adjustments

```json
{
  "dynamic_difficulty": {
    "metrics_tracked": {
      "recent_accuracy": "last_30_seconds",
      "recent_wpm": "last_30_seconds",
      "castle_hp_percent": "current",
      "wave_completion_time": "last_3_waves",
      "deaths_recent": "last_5_minutes"
    },
    "adjustment_triggers": {
      "struggling": {
        "conditions": {
          "accuracy_below": 0.75,
          "castle_hp_below": 0.3,
          "deaths_recent_above": 2
        },
        "adjustments": {
          "enemy_hp_modifier": 0.85,
          "enemy_speed_modifier": 0.9,
          "spawn_interval_modifier": 1.2,
          "affix_chance_modifier": 0.7
        }
      },
      "dominating": {
        "conditions": {
          "accuracy_above": 0.95,
          "wpm_above": 80,
          "castle_hp_above": 0.9,
          "wave_clear_fast": true
        },
        "adjustments": {
          "enemy_hp_modifier": 1.1,
          "enemy_speed_modifier": 1.05,
          "spawn_interval_modifier": 0.9,
          "affix_chance_modifier": 1.2,
          "reward_modifier": 1.15
        }
      }
    },
    "adjustment_limits": {
      "min_modifier": 0.7,
      "max_modifier": 1.3,
      "change_per_wave": 0.05
    }
  }
}
```

### Accessibility Difficulty Options

```json
{
  "difficulty_presets": {
    "story_mode": {
      "description": "Focus on the story with minimal challenge",
      "enemy_hp_modifier": 0.5,
      "enemy_damage_modifier": 0.5,
      "word_time_bonus": 2.0,
      "castle_hp_modifier": 2.0,
      "gold_modifier": 1.5
    },
    "easy": {
      "enemy_hp_modifier": 0.75,
      "enemy_damage_modifier": 0.75,
      "word_time_bonus": 1.5,
      "castle_hp_modifier": 1.5
    },
    "normal": {
      "all_modifiers": 1.0
    },
    "hard": {
      "enemy_hp_modifier": 1.25,
      "enemy_damage_modifier": 1.25,
      "spawn_interval_modifier": 0.9,
      "affix_chance_modifier": 1.3
    },
    "nightmare": {
      "enemy_hp_modifier": 1.5,
      "enemy_damage_modifier": 1.5,
      "spawn_interval_modifier": 0.8,
      "affix_chance_modifier": 1.5,
      "elite_chance_modifier": 1.5,
      "word_time_modifier": 0.8
    },
    "custom": {
      "allow_individual_sliders": true,
      "achievement_eligible": false
    }
  }
}
```

---

## Implementation Notes

### Wave Controller

```gdscript
class_name WaveController
extends Node

signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)
signal all_waves_completed()
signal enemy_spawned(enemy: Enemy)

var current_wave: int = 0
var wave_data: Array[WaveData]
var spawn_queue: Array[SpawnEntry]
var active_enemies: Array[Enemy]
var is_boss_wave: bool = false

func start_wave(wave_number: int) -> void:
    current_wave = wave_number
    var wave = get_wave_data(wave_number)

    apply_regional_modifiers(wave)
    apply_dynamic_difficulty(wave)

    for spawn_group in wave.spawn_groups:
        queue_spawn_group(spawn_group)

    wave_started.emit(wave_number)

func queue_spawn_group(group: SpawnGroup) -> void:
    for i in range(group.count):
        var entry = SpawnEntry.new()
        entry.enemy_type = group.enemy_type
        entry.spawn_time = group.spawn_delay + (i * group.spawn_interval)
        entry.spawn_point = group.spawn_point
        entry.affixes = determine_affixes(group)
        spawn_queue.append(entry)

    spawn_queue.sort_custom(func(a, b): return a.spawn_time < b.spawn_time)

func _process(delta: float) -> void:
    process_spawn_queue(delta)
    check_wave_completion()

func process_spawn_queue(delta: float) -> void:
    while spawn_queue.size() > 0 and spawn_queue[0].spawn_time <= wave_timer:
        var entry = spawn_queue.pop_front()
        spawn_enemy(entry)

func spawn_enemy(entry: SpawnEntry) -> void:
    var enemy = create_enemy(entry.enemy_type)
    apply_affixes(enemy, entry.affixes)
    place_at_spawn_point(enemy, entry.spawn_point)
    active_enemies.append(enemy)
    enemy_spawned.emit(enemy)
```

---

**Document version:** 1.0
**Wave templates:** 40+ standard waves
**Regional modifiers:** 3 regions
**Special wave types:** 8
**Boss patterns:** 6
