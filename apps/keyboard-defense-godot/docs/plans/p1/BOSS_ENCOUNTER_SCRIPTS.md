# Boss Encounter Scripts - Complete Collection

**Last updated:** 2026-01-08

This document contains complete phase-by-phase scripts for all boss encounters in Keyboard Defense, including mechanics, dialogue triggers, attack patterns, and special conditions.

---

## Table of Contents

1. [Boss Encounter Framework](#boss-encounter-framework)
2. [Evergrove Bosses](#evergrove-bosses)
3. [Stonepass Bosses](#stonepass-bosses)
4. [Mistfen Bosses](#mistfen-bosses)
5. [World Bosses](#world-bosses)
6. [Raid Bosses](#raid-bosses)

---

## Boss Encounter Framework

### Boss Data Structure

```json
{
  "boss_id": "string",
  "name": "Display Name",
  "title": "The Boss Title",
  "region": "region_id",
  "difficulty": 1-10,
  "recommended_level": 0,
  "recommended_wpm": 0,
  "recommended_accuracy": 0.0,

  "base_stats": {
    "total_hp": 0,
    "phase_count": 0,
    "enrage_timer": 0,
    "word_difficulty": "tier"
  },

  "phases": [],
  "special_mechanics": [],
  "rewards": {},
  "achievements": [],
  "dialogue": {}
}
```

### Phase Structure

```json
{
  "phase_number": 1,
  "phase_name": "Phase Name",
  "hp_threshold": 1.0,
  "duration_limit": null,

  "mechanics": [],
  "attacks": [],
  "word_pool": [],

  "transition": {
    "trigger": "hp_threshold | timer | special",
    "animation": "animation_id",
    "dialogue": "dialogue_id",
    "effect": "effect_id"
  }
}
```

### Attack Pattern Structure

```json
{
  "attack_id": "string",
  "name": "Attack Name",
  "type": "direct | aoe | dot | debuff | summon | special",
  "damage": 0,
  "word_requirement": {
    "word_pool": [],
    "length_min": 0,
    "length_max": 0,
    "time_limit": 0.0,
    "accuracy_threshold": 0.0
  },
  "telegraph": {
    "duration": 0.0,
    "visual": "telegraph_visual_id",
    "audio": "telegraph_audio_id"
  },
  "on_success": "effect_id",
  "on_failure": "effect_id"
}
```

---

## Evergrove Bosses

### Boss 1: Grove Guardian

**Boss ID:** `grove_guardian`
**Title:** The Corrupted Protector
**Difficulty:** 3/10
**Recommended:** Level 5+, 30 WPM, 85% accuracy

#### Overview

The Grove Guardian was once the spirit protector of the Evergrove, blessed by Gamma herself to defend the ancient forest. Corruption has twisted its protective nature into aggression - it now attacks everything, including the trees it once protected.

#### Full Stats

```json
{
  "boss_id": "grove_guardian",
  "name": "Grove Guardian",
  "title": "The Corrupted Protector",
  "region": "evergrove",
  "difficulty": 3,
  "recommended_level": 5,
  "recommended_wpm": 30,
  "recommended_accuracy": 0.85,

  "base_stats": {
    "total_hp": 500,
    "phase_count": 3,
    "enrage_timer": 300,
    "word_difficulty": "tier_2"
  },

  "lore_connection": "lore_021",
  "music_track": "boss_grove_guardian",
  "arena": "evergrove_grove_heart"
}
```

#### Phase 1: Awakening (100% - 70% HP)

**Phase Name:** "The Guardian Stirs"

```json
{
  "phase_number": 1,
  "phase_name": "The Guardian Stirs",
  "hp_threshold": 1.0,
  "hp_end": 0.7,

  "mechanics": [
    {
      "id": "root_growth",
      "description": "Roots periodically emerge from the ground, creating obstacles",
      "interval": 15.0,
      "effect": "Spawns 2-3 root obstacles that block typing line of sight"
    }
  ],

  "attacks": [
    {
      "attack_id": "branch_swipe",
      "name": "Branch Swipe",
      "type": "direct",
      "damage": 15,
      "frequency": "primary",
      "word_requirement": {
        "word_pool": ["oak", "elm", "ash", "bark", "leaf", "root", "tree", "wood"],
        "length_min": 3,
        "length_max": 4,
        "time_limit": 3.0,
        "accuracy_threshold": 0.9
      },
      "telegraph": {
        "duration": 1.5,
        "visual": "branch_wind_up",
        "audio": "sfx_wood_creak"
      },
      "on_success": "Attack blocked, Guardian staggers briefly",
      "on_failure": "Player takes 15 damage, knockback effect"
    },
    {
      "attack_id": "thorn_spray",
      "name": "Thorn Spray",
      "type": "aoe",
      "damage": 8,
      "frequency": "every 20 seconds",
      "word_requirement": {
        "word_pool": ["shield", "dodge", "evade", "cover"],
        "length_min": 5,
        "length_max": 6,
        "time_limit": 2.5,
        "accuracy_threshold": 0.95
      },
      "telegraph": {
        "duration": 2.0,
        "visual": "thorns_gathering",
        "audio": "sfx_thorns_rattle"
      },
      "on_success": "Player protected, thorns miss",
      "on_failure": "Player takes 8 damage and 3 DoT for 5 seconds"
    }
  ],

  "dialogue_triggers": [
    {
      "trigger": "phase_start",
      "speaker": "grove_guardian",
      "text": "INTRUDERS... IN MY... GROVE..."
    },
    {
      "trigger": "player_hit",
      "speaker": "grove_guardian",
      "text": "THE TREES... DEMAND... RETRIBUTION...",
      "chance": 0.3
    }
  ],

  "transition": {
    "trigger": "hp_threshold",
    "threshold": 0.7,
    "animation": "guardian_roar",
    "dialogue": {
      "speaker": "grove_guardian",
      "text": "YOU WOUND ME... BUT THE FOREST... IS STRONG..."
    },
    "effect": "Root network activates - arena terrain shifts"
  }
}
```

#### Phase 2: Awakened Fury (70% - 35% HP)

**Phase Name:** "Nature's Wrath"

```json
{
  "phase_number": 2,
  "phase_name": "Nature's Wrath",
  "hp_threshold": 0.7,
  "hp_end": 0.35,

  "mechanics": [
    {
      "id": "root_network",
      "description": "Roots now connect, creating maze-like obstacles",
      "effect": "Players must navigate root walls while typing"
    },
    {
      "id": "healing_sap",
      "description": "Guardian heals from connected trees",
      "interval": 30.0,
      "effect": "Heals 5% HP unless player destroys healing tree (requires typing 'sever')"
    }
  ],

  "attacks": [
    {
      "attack_id": "branch_slam",
      "name": "Branch Slam",
      "type": "direct",
      "damage": 25,
      "frequency": "primary",
      "word_requirement": {
        "word_pool": ["ancient", "timber", "forest", "branch", "canopy"],
        "length_min": 5,
        "length_max": 7,
        "time_limit": 2.5,
        "accuracy_threshold": 0.9
      },
      "telegraph": {
        "duration": 1.2,
        "visual": "branch_raise_high",
        "audio": "sfx_wood_stress"
      },
      "on_success": "Attack parried, Guardian exposed for bonus damage window",
      "on_failure": "Player takes 25 damage, stunned for 1 second"
    },
    {
      "attack_id": "root_eruption",
      "name": "Root Eruption",
      "type": "aoe",
      "damage": 12,
      "frequency": "every 15 seconds",
      "word_requirement": {
        "word_pool": ["jump", "leap", "spring", "vault", "bound"],
        "length_min": 4,
        "length_max": 6,
        "time_limit": 1.8,
        "accuracy_threshold": 0.95
      },
      "telegraph": {
        "duration": 1.5,
        "visual": "ground_cracking",
        "audio": "sfx_earth_rumble"
      },
      "on_success": "Player jumps, roots miss",
      "on_failure": "Player rooted in place for 3 seconds, takes 12 damage"
    },
    {
      "attack_id": "summon_saplings",
      "name": "Call of the Grove",
      "type": "summon",
      "damage": 0,
      "frequency": "every 45 seconds",
      "word_requirement": null,
      "telegraph": {
        "duration": 2.0,
        "visual": "seeds_falling",
        "audio": "sfx_growth_magic"
      },
      "effect": "Spawns 3 Corrupted Saplings (Tier 1 enemies) that must be defeated"
    }
  ],

  "special_attack": {
    "attack_id": "photosynthesis_burst",
    "name": "Photosynthesis Burst",
    "type": "special",
    "frequency": "once at 50% HP",
    "description": "Guardian channels sunlight into devastating beam",
    "word_requirement": {
      "word_pool": ["darkness", "shadow", "eclipse", "nightfall", "obscure"],
      "count": 3,
      "time_limit": 8.0,
      "accuracy_threshold": 0.95
    },
    "telegraph": {
      "duration": 3.0,
      "visual": "sunlight_gathering",
      "audio": "sfx_energy_charge"
    },
    "on_success": "Beam redirected at Guardian, bonus damage",
    "on_failure": "Player takes 40 damage, blinded for 2 seconds"
  },

  "dialogue_triggers": [
    {
      "trigger": "phase_start",
      "speaker": "grove_guardian",
      "text": "THE CORRUPTION... BURNS... I CANNOT... CONTROL..."
    },
    {
      "trigger": "heal_successful",
      "speaker": "grove_guardian",
      "text": "THE GROVE... SUSTAINS ME..."
    },
    {
      "trigger": "heal_prevented",
      "speaker": "grove_guardian",
      "text": "NO... MY TREES... MY CHILDREN..."
    }
  ],

  "transition": {
    "trigger": "hp_threshold",
    "threshold": 0.35,
    "animation": "guardian_corrupt_surge",
    "dialogue": {
      "speaker": "grove_guardian",
      "text": "FORGIVE ME... I CANNOT... STOP..."
    },
    "effect": "Guardian fully transforms, bark cracks revealing corruption within"
  }
}
```

#### Phase 3: Corrupted Core (35% - 0% HP)

**Phase Name:** "Heart of Corruption"

```json
{
  "phase_number": 3,
  "phase_name": "Heart of Corruption",
  "hp_threshold": 0.35,
  "hp_end": 0,

  "mechanics": [
    {
      "id": "exposed_core",
      "description": "Guardian's corrupted core is now visible",
      "effect": "Critical hits possible when targeting the glowing weak point"
    },
    {
      "id": "desperation",
      "description": "All attacks are faster but less accurate telegraphs",
      "effect": "Attack speed +30%, telegraph duration -20%"
    },
    {
      "id": "purification_option",
      "description": "Player can attempt purification instead of destruction",
      "effect": "Typing the ancient phrase 'GAMMA RESTORE YOUR CHILD' perfectly triggers alternate ending"
    }
  ],

  "attacks": [
    {
      "attack_id": "corrupted_slam",
      "name": "Corrupted Slam",
      "type": "direct",
      "damage": 35,
      "frequency": "primary",
      "word_requirement": {
        "word_pool": ["corruption", "darkness", "twisted", "broken", "infected"],
        "length_min": 6,
        "length_max": 10,
        "time_limit": 2.0,
        "accuracy_threshold": 0.92
      },
      "telegraph": {
        "duration": 0.9,
        "visual": "arm_corruption_pulse",
        "audio": "sfx_corruption_roar"
      },
      "on_success": "Attack deflected, corruption damages Guardian instead",
      "on_failure": "Player takes 35 damage, corruption debuff (accuracy -5% for 10 seconds)"
    },
    {
      "attack_id": "corruption_wave",
      "name": "Corruption Wave",
      "type": "aoe",
      "damage": 20,
      "frequency": "every 12 seconds",
      "word_requirement": {
        "word_pool": ["purify", "cleanse", "restore", "clarity", "purity"],
        "length_min": 5,
        "length_max": 7,
        "time_limit": 2.0,
        "accuracy_threshold": 0.95
      },
      "telegraph": {
        "duration": 1.8,
        "visual": "corruption_expanding",
        "audio": "sfx_corruption_pulse"
      },
      "on_success": "Wave dispelled, small area cleared of corruption",
      "on_failure": "Player takes 20 damage, arena corruption increases"
    },
    {
      "attack_id": "death_grasp",
      "name": "Death Grasp",
      "type": "special",
      "damage": 50,
      "frequency": "every 30 seconds",
      "word_requirement": {
        "word_pool": ["freedom", "escape", "release", "liberate"],
        "count": 2,
        "time_limit": 4.0,
        "accuracy_threshold": 0.98
      },
      "telegraph": {
        "duration": 1.5,
        "visual": "root_hands_emerge",
        "audio": "sfx_ground_break"
      },
      "on_success": "Player breaks free immediately",
      "on_failure": "Player grabbed, takes 50 damage over 5 seconds unless freed"
    }
  ],

  "enrage": {
    "trigger": "timer",
    "time": 300,
    "effect": "Guardian enters permanent frenzy - attack damage doubled, no telegraph warnings",
    "dialogue": {
      "speaker": "grove_guardian",
      "text": "NO MORE... MERCY... ONLY... CORRUPTION..."
    }
  },

  "dialogue_triggers": [
    {
      "trigger": "phase_start",
      "speaker": "grove_guardian",
      "text": "THE DARKNESS... CONSUMES... EVERYTHING I WAS..."
    },
    {
      "trigger": "hp_below_15",
      "speaker": "grove_guardian",
      "text": "END... THIS... PLEASE..."
    },
    {
      "trigger": "purification_started",
      "speaker": "grove_guardian",
      "text": "THAT PHRASE... I REMEMBER... GAMMA..."
    }
  ]
}
```

#### Defeat Outcomes

```json
{
  "outcomes": {
    "standard_defeat": {
      "condition": "HP reaches 0 without purification",
      "animation": "guardian_collapse",
      "dialogue": {
        "speaker": "grove_guardian",
        "text": "THANK... YOU... THE PAIN... ENDS..."
      },
      "effect": "Guardian crumbles, corruption disperses",
      "rewards": {
        "xp": 500,
        "gold": 150,
        "items": [
          {"id": "guardian_heartwood", "chance": 1.0},
          {"id": "corrupted_bark", "chance": 0.8},
          {"id": "ancient_seed", "chance": 0.3}
        ],
        "achievement": "grove_guardian_slain"
      }
    },
    "purification_success": {
      "condition": "Player types 'GAMMA RESTORE YOUR CHILD' with 100% accuracy",
      "animation": "guardian_purified",
      "dialogue": [
        {
          "speaker": "grove_guardian",
          "text": "THE... CORRUPTION... FADES... I REMEMBER... WHO I WAS..."
        },
        {
          "speaker": "grove_guardian",
          "text": "THANK YOU, DEFENDER. THE GROVE WILL NOT FORGET THIS MERCY."
        }
      ],
      "effect": "Guardian restored, becomes ally NPC",
      "rewards": {
        "xp": 750,
        "gold": 200,
        "items": [
          {"id": "purified_heartwood", "chance": 1.0},
          {"id": "gamma_blessing", "chance": 1.0},
          {"id": "guardian_seed", "chance": 1.0}
        ],
        "achievement": "guardian_restored",
        "unlock": "guardian_ally_quests"
      }
    }
  }
}
```

---

### Boss 2: Thornweaver Matriarch

**Boss ID:** `thornweaver_matriarch`
**Title:** Queen of Thorns
**Difficulty:** 5/10
**Recommended:** Level 10+, 40 WPM, 88% accuracy

#### Overview

Deep within the corrupted sections of the Evergrove, the Thornweaver Matriarch has established her web of poisonous vines. Once a benevolent nature spirit that helped gardens grow, corruption has transformed her into a creature of pain and entanglement.

#### Full Stats

```json
{
  "boss_id": "thornweaver_matriarch",
  "name": "Thornweaver Matriarch",
  "title": "Queen of Thorns",
  "region": "evergrove",
  "difficulty": 5,
  "recommended_level": 10,
  "recommended_wpm": 40,
  "recommended_accuracy": 0.88,

  "base_stats": {
    "total_hp": 800,
    "phase_count": 3,
    "enrage_timer": 360,
    "word_difficulty": "tier_3"
  }
}
```

#### Phase 1: The Web (100% - 65% HP)

```json
{
  "phase_number": 1,
  "phase_name": "The Web",
  "hp_threshold": 1.0,
  "hp_end": 0.65,

  "mechanics": [
    {
      "id": "vine_web",
      "description": "Arena covered in sticky vines that slow movement",
      "effect": "Players typing below 30 WPM become rooted"
    },
    {
      "id": "spawn_thornlings",
      "description": "Thornling adds spawn periodically",
      "interval": 20.0,
      "effect": "2 Thornlings spawn, must type their words to kill"
    }
  ],

  "attacks": [
    {
      "attack_id": "thorn_lash",
      "name": "Thorn Lash",
      "type": "direct",
      "damage": 18,
      "word_requirement": {
        "word_pool": ["dodge", "duck", "weave", "sway", "sidestep"],
        "time_limit": 2.5
      }
    },
    {
      "attack_id": "poison_spit",
      "name": "Venomous Spray",
      "type": "dot",
      "damage": 5,
      "dot_duration": 10,
      "word_requirement": {
        "word_pool": ["antidote", "remedy", "cure", "neutralize"],
        "time_limit": 3.0
      }
    },
    {
      "attack_id": "web_shot",
      "name": "Binding Web",
      "type": "debuff",
      "effect": "speed_reduction_50",
      "word_requirement": {
        "word_pool": ["cut", "slice", "rend", "tear", "sever"],
        "time_limit": 2.0
      }
    }
  ],

  "dialogue_triggers": [
    {
      "trigger": "phase_start",
      "speaker": "thornweaver_matriarch",
      "text": "Welcome to my garden, little prey. The thorns have been hungry."
    }
  ]
}
```

#### Phase 2: Entanglement (65% - 30% HP)

```json
{
  "phase_number": 2,
  "phase_name": "Entanglement",
  "hp_threshold": 0.65,
  "hp_end": 0.30,

  "mechanics": [
    {
      "id": "living_vines",
      "description": "Vines actively pursue the player",
      "effect": "Must type 'escape' every 10 seconds or take damage"
    },
    {
      "id": "pollen_cloud",
      "description": "Poison pollen fills portions of the arena",
      "effect": "Standing in pollen causes accuracy debuff"
    }
  ],

  "attacks": [
    {
      "attack_id": "constrict",
      "name": "Constricting Embrace",
      "type": "special",
      "damage": 30,
      "word_requirement": {
        "word_pool": ["struggle", "resist", "fight", "break"],
        "count": 3,
        "time_limit": 5.0
      },
      "on_failure": "Player takes 30 damage and is stunned"
    },
    {
      "attack_id": "thorn_barrage",
      "name": "Thorn Barrage",
      "type": "aoe",
      "damage": 12,
      "hits": 5,
      "word_requirement": {
        "word_pool": ["deflect", "parry", "block", "guard", "protect"],
        "count": 5,
        "time_limit": 6.0
      }
    }
  ],

  "dialogue_triggers": [
    {
      "trigger": "phase_start",
      "speaker": "thornweaver_matriarch",
      "text": "You cut through my children. Now you face the mother's wrath."
    }
  ]
}
```

#### Phase 3: Bloom of Corruption (30% - 0% HP)

```json
{
  "phase_number": 3,
  "phase_name": "Bloom of Corruption",
  "hp_threshold": 0.30,
  "hp_end": 0,

  "mechanics": [
    {
      "id": "death_bloom",
      "description": "Matriarch transforms into corrupted flower form",
      "effect": "New attack patterns, arena-wide effects"
    },
    {
      "id": "regeneration",
      "description": "Slowly heals unless corruption sources destroyed",
      "effect": "Heals 2% HP per 10 seconds, type 'wither' at corruption nodes to stop"
    }
  ],

  "attacks": [
    {
      "attack_id": "petal_storm",
      "name": "Corrupted Petal Storm",
      "type": "aoe",
      "damage": 25,
      "word_requirement": {
        "word_pool": ["shelter", "barrier", "haven", "sanctuary"],
        "time_limit": 2.0
      }
    },
    {
      "attack_id": "root_prison",
      "name": "Root Prison",
      "type": "special",
      "damage": 40,
      "word_requirement": {
        "word_pool": ["freedom", "liberty", "escape", "release", "break", "shatter"],
        "count": 4,
        "time_limit": 6.0
      }
    },
    {
      "attack_id": "corruption_bloom",
      "name": "Final Bloom",
      "type": "ultimate",
      "damage": 60,
      "frequency": "once at 10% HP",
      "word_requirement": {
        "word_pool": ["destroy", "annihilate", "obliterate", "eradicate"],
        "time_limit": 3.0,
        "accuracy_threshold": 0.98
      }
    }
  ],

  "dialogue_triggers": [
    {
      "trigger": "phase_start",
      "speaker": "thornweaver_matriarch",
      "text": "BEHOLD MY TRUE FORM! The corruption has made me BEAUTIFUL!"
    },
    {
      "trigger": "defeat",
      "speaker": "thornweaver_matriarch",
      "text": "The garden... wilts... but new seeds... will grow..."
    }
  ]
}
```

---

## Stonepass Bosses

### Boss 3: Stone Colossus

**Boss ID:** `stone_colossus`
**Title:** The Unbound Titan
**Difficulty:** 6/10
**Recommended:** Level 15+, 45 WPM, 90% accuracy

#### Overview

Created by the ancient dwarves as the ultimate guardian, the Stone Colossus was sealed away when it became uncontrollable. Corruption has weakened its bindings, and now it rampages through the deep mines, destroying everything in its path.

#### Full Stats

```json
{
  "boss_id": "stone_colossus",
  "name": "Stone Colossus",
  "title": "The Unbound Titan",
  "region": "stonepass",
  "difficulty": 6,
  "recommended_level": 15,
  "recommended_wpm": 45,
  "recommended_accuracy": 0.90,

  "base_stats": {
    "total_hp": 1200,
    "phase_count": 4,
    "enrage_timer": 420,
    "word_difficulty": "tier_3"
  }
}
```

#### Phase 1: Awakening (100% - 75% HP)

```json
{
  "phase_number": 1,
  "phase_name": "Awakening",
  "hp_threshold": 1.0,
  "hp_end": 0.75,

  "mechanics": [
    {
      "id": "binding_chains",
      "description": "Remnant chains still slow the Colossus",
      "effect": "Attack speed reduced 20% while chains remain"
    },
    {
      "id": "chain_destruction",
      "description": "Colossus breaks chains when hit hard enough",
      "effect": "Each 10% HP lost breaks one chain, increasing attack speed"
    }
  ],

  "attacks": [
    {
      "attack_id": "stone_fist",
      "name": "Stone Fist",
      "type": "direct",
      "damage": 25,
      "word_requirement": {
        "word_pool": ["stone", "rock", "granite", "marble", "boulder"],
        "time_limit": 3.0
      },
      "telegraph": {
        "duration": 2.0,
        "visual": "fist_raise"
      }
    },
    {
      "attack_id": "ground_pound",
      "name": "Ground Pound",
      "type": "aoe",
      "damage": 15,
      "word_requirement": {
        "word_pool": ["jump", "leap", "vault", "spring"],
        "time_limit": 2.0
      }
    }
  ],

  "dialogue_triggers": [
    {
      "trigger": "phase_start",
      "speaker": "stone_colossus",
      "text": "[RUNES PULSE] SEALED... FOR AGES... NOW... FREE..."
    }
  ]
}
```

#### Phase 2: Rampage (75% - 50% HP)

```json
{
  "phase_number": 2,
  "phase_name": "Rampage",
  "hp_threshold": 0.75,
  "hp_end": 0.50,

  "mechanics": [
    {
      "id": "collapsing_tunnels",
      "description": "Colossus's movements cause cave-ins",
      "effect": "Random rock falls require typing 'dodge' to avoid"
    },
    {
      "id": "rune_glow",
      "description": "Runes on Colossus glow when attacks charge",
      "effect": "Visual indicator of incoming attack type"
    }
  ],

  "attacks": [
    {
      "attack_id": "charge",
      "name": "Unstoppable Charge",
      "type": "special",
      "damage": 40,
      "word_requirement": {
        "word_pool": ["sidestep", "evade", "dodge", "avoid", "escape"],
        "time_limit": 1.5
      },
      "telegraph": {
        "duration": 1.0,
        "visual": "colossus_crouch"
      }
    },
    {
      "attack_id": "seismic_slam",
      "name": "Seismic Slam",
      "type": "aoe",
      "damage": 30,
      "word_requirement": {
        "word_pool": ["earthquake", "tremor", "seismic", "quake"],
        "time_limit": 2.5
      }
    },
    {
      "attack_id": "boulder_throw",
      "name": "Boulder Hurl",
      "type": "direct",
      "damage": 35,
      "word_requirement": {
        "word_pool": ["shatter", "destroy", "smash", "break", "crush"],
        "time_limit": 2.0
      }
    }
  ],

  "dialogue_triggers": [
    {
      "trigger": "phase_start",
      "speaker": "stone_colossus",
      "text": "THE CHAINS... BROKEN... NOW... DESTRUCTION..."
    }
  ]
}
```

#### Phase 3: Rune Overload (50% - 25% HP)

```json
{
  "phase_number": 3,
  "phase_name": "Rune Overload",
  "hp_threshold": 0.50,
  "hp_end": 0.25,

  "mechanics": [
    {
      "id": "rune_activation",
      "description": "Ancient runes activate, granting new abilities",
      "effect": "Colossus gains elemental attacks based on rune type"
    },
    {
      "id": "binding_phrase",
      "description": "If learned pre-fight, binding phrase can stun Colossus",
      "effect": "Typing 'FORGEBORN SEAL ETERNAL' stuns for 5 seconds"
    }
  ],

  "attacks": [
    {
      "attack_id": "rune_beam",
      "name": "Rune Beam",
      "type": "direct",
      "damage": 45,
      "word_requirement": {
        "word_pool": ["deflect", "reflect", "redirect", "absorb"],
        "time_limit": 1.8
      }
    },
    {
      "attack_id": "stone_prison",
      "name": "Stone Prison",
      "type": "debuff",
      "effect": "immobilize",
      "duration": 5.0,
      "word_requirement": {
        "word_pool": ["freedom", "escape", "break", "shatter", "crack"],
        "count": 3,
        "time_limit": 5.0
      }
    },
    {
      "attack_id": "rune_surge",
      "name": "Rune Surge",
      "type": "aoe",
      "damage": 25,
      "word_requirement": {
        "word_pool": ["counter", "dispel", "negate", "nullify"],
        "time_limit": 2.0
      }
    }
  ],

  "dialogue_triggers": [
    {
      "trigger": "phase_start",
      "speaker": "stone_colossus",
      "text": "THE RUNES... REMEMBER... POWER... UNLIMITED..."
    },
    {
      "trigger": "binding_used",
      "speaker": "stone_colossus",
      "text": "THOSE WORDS... NO... THE BINDING..."
    }
  ]
}
```

#### Phase 4: Core Meltdown (25% - 0% HP)

```json
{
  "phase_number": 4,
  "phase_name": "Core Meltdown",
  "hp_threshold": 0.25,
  "hp_end": 0,

  "mechanics": [
    {
      "id": "crumbling",
      "description": "Colossus is falling apart, pieces flying everywhere",
      "effect": "Constant minor damage unless typing 'shield' periodically"
    },
    {
      "id": "exposed_core",
      "description": "Keysteel core is visible and vulnerable",
      "effect": "Critical hits deal triple damage"
    },
    {
      "id": "final_protocol",
      "description": "Colossus attempts self-destruct",
      "effect": "Must type deactivation sequence or take massive damage"
    }
  ],

  "attacks": [
    {
      "attack_id": "desperate_swings",
      "name": "Desperate Swings",
      "type": "multi_hit",
      "damage": 20,
      "hits": 4,
      "word_requirement": {
        "word_pool": ["parry", "block", "deflect", "guard"],
        "count": 4,
        "time_limit": 5.0
      }
    },
    {
      "attack_id": "self_destruct",
      "name": "Final Protocol",
      "type": "ultimate",
      "damage": 100,
      "word_requirement": {
        "word_pool": ["deactivate", "shutdown", "terminate", "abort", "cancel"],
        "count": 5,
        "time_limit": 8.0,
        "accuracy_threshold": 0.95
      },
      "on_failure": "Player takes 100 damage, boss dies anyway"
    }
  ],

  "dialogue_triggers": [
    {
      "trigger": "phase_start",
      "speaker": "stone_colossus",
      "text": "SYSTEM... FAILING... INITIATING... FINAL... PROTOCOL..."
    },
    {
      "trigger": "defeat",
      "speaker": "stone_colossus",
      "text": "PURPOSE... FULFILLED... AT LAST... PEACE..."
    }
  ]
}
```

#### Defeat Rewards

```json
{
  "rewards": {
    "xp": 1000,
    "gold": 350,
    "items": [
      {"id": "colossus_core_fragment", "chance": 1.0},
      {"id": "ancient_rune_stone", "chance": 0.7},
      {"id": "binding_key_fragment", "chance": 0.4},
      {"id": "colossus_gauntlets", "chance": 0.15}
    ],
    "achievement": "titan_slain"
  }
}
```

---

### Boss 4: Forge Tyrant

**Boss ID:** `forge_tyrant`
**Title:** Master of the Burning Depths
**Difficulty:** 7/10
**Recommended:** Level 20+, 50 WPM, 90% accuracy

#### Overview

Once the greatest dwarf smith of Stonepass, the Forge Tyrant was consumed by obsession with creating the perfect weapon. He delved too deep, found corrupted keysteel, and merged with his own forge. Now he crafts only weapons of destruction.

#### Full Stats

```json
{
  "boss_id": "forge_tyrant",
  "name": "Forge Tyrant",
  "title": "Master of the Burning Depths",
  "region": "stonepass",
  "difficulty": 7,
  "recommended_level": 20,
  "recommended_wpm": 50,
  "recommended_accuracy": 0.90,

  "base_stats": {
    "total_hp": 1500,
    "phase_count": 3,
    "enrage_timer": 480,
    "word_difficulty": "tier_4"
  }
}
```

#### Phase 1: The Forgemaster (100% - 60% HP)

```json
{
  "phase_number": 1,
  "phase_name": "The Forgemaster",

  "mechanics": [
    {
      "id": "weapon_crafting",
      "description": "Tyrant crafts weapons mid-fight",
      "effect": "Every 30 seconds, creates a new weapon with different attack patterns"
    },
    {
      "id": "heat_zones",
      "description": "Forge vents create danger zones",
      "effect": "Standing in heat deals DoT, typing 'cool' or 'freeze' removes temporarily"
    }
  ],

  "attacks": [
    {
      "attack_id": "hammer_strike",
      "name": "Forge Hammer",
      "type": "direct",
      "damage": 30,
      "word_requirement": {
        "word_pool": ["anvil", "hammer", "forge", "smith", "metal"],
        "time_limit": 2.5
      }
    },
    {
      "attack_id": "molten_spray",
      "name": "Molten Metal Spray",
      "type": "aoe",
      "damage": 20,
      "dot": 5,
      "dot_duration": 8,
      "word_requirement": {
        "word_pool": ["shield", "barrier", "protect", "guard"],
        "time_limit": 2.0
      }
    },
    {
      "attack_id": "summon_construct",
      "name": "Forge Construct",
      "type": "summon",
      "effect": "Summons 1 Forge Construct (Tier 3 enemy)"
    }
  ],

  "dialogue_triggers": [
    {
      "trigger": "phase_start",
      "speaker": "forge_tyrant",
      "text": "You dare enter MY forge? I'll melt you down and make something useful."
    }
  ]
}
```

#### Phase 2: The Corrupted Smith (60% - 30% HP)

```json
{
  "phase_number": 2,
  "phase_name": "The Corrupted Smith",

  "mechanics": [
    {
      "id": "forge_merge",
      "description": "Tyrant merges partially with his forge",
      "effect": "Cannot be moved, but gains access to forge weapons"
    },
    {
      "id": "weapon_cycle",
      "description": "Cycles through forged weapons",
      "effect": "Different weapons require different counter-words"
    }
  ],

  "attacks": [
    {
      "attack_id": "flaming_sword",
      "name": "Burning Blade",
      "type": "direct",
      "damage": 35,
      "element": "fire",
      "word_requirement": {
        "word_pool": ["water", "quench", "extinguish", "douse"],
        "time_limit": 2.0
      }
    },
    {
      "attack_id": "ice_axe",
      "name": "Frozen Cleave",
      "type": "direct",
      "damage": 35,
      "element": "ice",
      "word_requirement": {
        "word_pool": ["heat", "warm", "melt", "thaw"],
        "time_limit": 2.0
      }
    },
    {
      "attack_id": "thunder_mace",
      "name": "Lightning Strike",
      "type": "direct",
      "damage": 35,
      "element": "lightning",
      "word_requirement": {
        "word_pool": ["ground", "earth", "insulate", "rubber"],
        "time_limit": 2.0
      }
    },
    {
      "attack_id": "forge_eruption",
      "name": "Forge Eruption",
      "type": "aoe",
      "damage": 40,
      "word_requirement": {
        "word_pool": ["retreat", "escape", "flee", "withdraw"],
        "time_limit": 1.5
      }
    }
  ],

  "dialogue_triggers": [
    {
      "trigger": "phase_start",
      "speaker": "forge_tyrant",
      "text": "The forge and I are ONE! Feel the heat of a thousand years of crafting!"
    }
  ]
}
```

#### Phase 3: The Living Forge (30% - 0% HP)

```json
{
  "phase_number": 3,
  "phase_name": "The Living Forge",

  "mechanics": [
    {
      "id": "full_merge",
      "description": "Tyrant becomes the forge itself",
      "effect": "Room transforms into boss arena, walls attack"
    },
    {
      "id": "heat_rising",
      "description": "Temperature constantly increasing",
      "effect": "DoT that increases over time, must type 'endure' to resist"
    }
  ],

  "attacks": [
    {
      "attack_id": "forge_breath",
      "name": "Forge Breath",
      "type": "aoe",
      "damage": 50,
      "word_requirement": {
        "word_pool": ["survive", "endure", "withstand", "resist", "persist"],
        "time_limit": 2.0
      }
    },
    {
      "attack_id": "anvil_rain",
      "name": "Anvil Rain",
      "type": "multi_hit",
      "damage": 25,
      "hits": 4,
      "word_requirement": {
        "word_pool": ["dodge", "evade", "sidestep", "duck"],
        "count": 4,
        "time_limit": 6.0
      }
    },
    {
      "attack_id": "ultimate_weapon",
      "name": "Ultimate Creation",
      "type": "ultimate",
      "description": "Forges ultimate weapon, instant kill unless stopped",
      "word_requirement": {
        "word_pool": ["sabotage", "destroy", "ruin", "break", "shatter", "corrupt"],
        "count": 6,
        "time_limit": 10.0,
        "accuracy_threshold": 0.95
      }
    }
  ],

  "dialogue_triggers": [
    {
      "trigger": "phase_start",
      "speaker": "forge_tyrant",
      "text": "I AM THE FORGE! I AM THE FIRE! I AM PERFECTION IN METAL!"
    },
    {
      "trigger": "defeat",
      "speaker": "forge_tyrant",
      "text": "The flames... cooling... my greatest work... unfinished..."
    }
  ]
}
```

---

## Mistfen Bosses

### Boss 5: Mist Wraith

**Boss ID:** `mist_wraith`
**Title:** The Lost Archmage
**Difficulty:** 7/10
**Recommended:** Level 20+, 50 WPM, 92% accuracy

#### Overview

Archmage Vorthan, who caused the Great Silence in his pursuit of the Perfect Word, has become a creature of mist and corruption. He haunts the corrupted sections of Mistfen, simultaneously seeking the knowledge he lost and spreading the corruption he created.

#### Full Stats

```json
{
  "boss_id": "mist_wraith",
  "name": "Mist Wraith",
  "title": "The Lost Archmage",
  "region": "mistfen",
  "difficulty": 7,
  "recommended_level": 20,
  "recommended_wpm": 50,
  "recommended_accuracy": 0.92,

  "base_stats": {
    "total_hp": 1000,
    "phase_count": 4,
    "enrage_timer": 400,
    "word_difficulty": "tier_4"
  }
}
```

#### Phase 1: Manifestation (100% - 70% HP)

```json
{
  "phase_number": 1,
  "phase_name": "Manifestation",

  "mechanics": [
    {
      "id": "mist_form",
      "description": "Wraith is semi-corporeal",
      "effect": "50% damage reduction unless typing 'clarity' or 'reveal'"
    },
    {
      "id": "whispers",
      "description": "Wraith's whispers confuse",
      "effect": "Random letter substitutions in word prompts"
    }
  ],

  "attacks": [
    {
      "attack_id": "mist_touch",
      "name": "Mist Touch",
      "type": "direct",
      "damage": 20,
      "word_requirement": {
        "word_pool": ["dispel", "banish", "repel", "ward"],
        "time_limit": 2.5
      }
    },
    {
      "attack_id": "confusion",
      "name": "Word Scramble",
      "type": "debuff",
      "effect": "Next 3 words are scrambled",
      "word_requirement": {
        "word_pool": ["focus", "concentrate", "clarity", "clear"],
        "time_limit": 2.0
      }
    },
    {
      "attack_id": "mist_clones",
      "name": "Mist Clones",
      "type": "summon",
      "effect": "Creates 3 illusions, only one takes damage"
    }
  ],

  "dialogue_triggers": [
    {
      "trigger": "phase_start",
      "speaker": "mist_wraith",
      "text": "Ssso... another ssseeker... The perfect word... you want it too..."
    }
  ]
}
```

#### Phase 2: Memory Fragments (70% - 45% HP)

```json
{
  "phase_number": 2,
  "phase_name": "Memory Fragments",

  "mechanics": [
    {
      "id": "memory_attack",
      "description": "Wraith uses memories of past defenders",
      "effect": "Attacks mimic techniques of fallen defenders"
    },
    {
      "id": "knowledge_drain",
      "description": "Wraith steals words from player",
      "effect": "Some common words become unavailable temporarily"
    }
  ],

  "attacks": [
    {
      "attack_id": "stolen_technique",
      "name": "Stolen Technique",
      "type": "variable",
      "damage": 25,
      "description": "Randomly copies player's most-used word counter",
      "word_requirement": {
        "word_pool": ["original", "unique", "novel", "new"],
        "time_limit": 2.0
      }
    },
    {
      "attack_id": "memory_barrage",
      "name": "Memory Barrage",
      "type": "multi_hit",
      "damage": 15,
      "hits": 5,
      "word_requirement": {
        "word_pool": ["forget", "erase", "delete", "remove", "clear"],
        "count": 5,
        "time_limit": 7.0
      }
    },
    {
      "attack_id": "word_theft",
      "name": "Lexical Drain",
      "type": "debuff",
      "effect": "Steals 3 random words from player's pool for 60 seconds"
    }
  ],

  "dialogue_triggers": [
    {
      "trigger": "phase_start",
      "speaker": "mist_wraith",
      "text": "I have consumed... ssso many... their words... are mine now..."
    },
    {
      "trigger": "technique_stolen",
      "speaker": "mist_wraith",
      "text": "Yesss... I know this move... I know YOU..."
    }
  ]
}
```

#### Phase 3: The Scholar's Madness (45% - 20% HP)

```json
{
  "phase_number": 3,
  "phase_name": "The Scholar's Madness",

  "mechanics": [
    {
      "id": "reality_flux",
      "description": "Reality becomes unstable",
      "effect": "Arena shifts randomly, words may change mid-typing"
    },
    {
      "id": "arcane_knowledge",
      "description": "Wraith uses forbidden word-magic",
      "effect": "Special attacks require typing backwards or in patterns"
    }
  ],

  "attacks": [
    {
      "attack_id": "word_reversal",
      "name": "Word Reversal",
      "type": "special",
      "damage": 35,
      "description": "Must type the counter word backwards",
      "word_requirement": {
        "word_pool": ["reverse", "mirror", "reflect", "invert"],
        "modifier": "backwards",
        "time_limit": 3.0
      }
    },
    {
      "attack_id": "silence_zone",
      "name": "Zone of Silence",
      "type": "aoe",
      "damage": 0,
      "effect": "All typing disabled for 3 seconds unless broken with perfect accuracy"
    },
    {
      "attack_id": "forbidden_word",
      "name": "Forbidden Word",
      "type": "direct",
      "damage": 50,
      "word_requirement": {
        "word_pool": ["[corrupted text that shifts]"],
        "time_limit": 2.5,
        "accuracy_threshold": 0.98
      }
    }
  ],

  "dialogue_triggers": [
    {
      "trigger": "phase_start",
      "speaker": "mist_wraith",
      "text": "The Perfect Word... I was ssso close... IT SSSHOULD HAVE WORKED!"
    }
  ]
}
```

#### Phase 4: Echo of Vorthan (20% - 0% HP)

```json
{
  "phase_number": 4,
  "phase_name": "Echo of Vorthan",

  "mechanics": [
    {
      "id": "human_form",
      "description": "Wraith briefly remembers humanity",
      "effect": "More predictable attacks, but also more vulnerable"
    },
    {
      "id": "redemption_path",
      "description": "Can be saved instead of destroyed",
      "effect": "Typing 'ARCHMAGE VORTHAN FIND PEACE' triggers alternate ending"
    }
  ],

  "attacks": [
    {
      "attack_id": "desperate_casting",
      "name": "Desperate Casting",
      "type": "multi_hit",
      "damage": 20,
      "hits": 6,
      "word_requirement": {
        "word_pool": ["counter", "dispel", "negate", "cancel", "stop", "halt"],
        "count": 6,
        "time_limit": 8.0
      }
    },
    {
      "attack_id": "final_silence",
      "name": "Final Silence",
      "type": "ultimate",
      "damage": 80,
      "description": "Attempts to recreate the Great Silence",
      "word_requirement": {
        "word_pool": ["speak", "voice", "sound", "word", "language", "meaning"],
        "count": 6,
        "time_limit": 10.0,
        "accuracy_threshold": 0.95
      }
    }
  ],

  "dialogue_triggers": [
    {
      "trigger": "phase_start",
      "speaker": "mist_wraith",
      "text": "I... remember... I was... Vorthan... I sought... to save..."
    },
    {
      "trigger": "hp_below_10",
      "speaker": "mist_wraith",
      "text": "Please... end this... I am so... tired..."
    }
  ]
}
```

#### Defeat Outcomes

```json
{
  "outcomes": {
    "standard_defeat": {
      "dialogue": {
        "speaker": "mist_wraith",
        "text": "The silence... calls me... finally... quiet..."
      },
      "rewards": {
        "xp": 1200,
        "gold": 400,
        "items": [
          {"id": "archmage_essence", "chance": 1.0},
          {"id": "forbidden_scroll", "chance": 0.5},
          {"id": "vorthan_staff", "chance": 0.2}
        ],
        "achievement": "wraith_banished"
      }
    },
    "redemption_success": {
      "dialogue": [
        {
          "speaker": "mist_wraith",
          "text": "Those words... they reach... the man I was..."
        },
        {
          "speaker": "vorthan_spirit",
          "text": "Thank you, defender. I could not find peace on my own. Take my knowledge - use it better than I did."
        }
      ],
      "rewards": {
        "xp": 1500,
        "gold": 500,
        "items": [
          {"id": "purified_archmage_essence", "chance": 1.0},
          {"id": "vorthan_codex_page", "chance": 1.0},
          {"id": "word_mage_robes", "chance": 1.0}
        ],
        "achievement": "archmage_redeemed",
        "unlock": "advanced_word_magic"
      }
    }
  }
}
```

---

### Boss 6: Codex Aberration

**Boss ID:** `codex_aberration`
**Title:** The Living Library
**Difficulty:** 8/10
**Recommended:** Level 25+, 55 WPM, 92% accuracy

#### Overview

Created from corrupted pages of the Luminara Codex, the Codex Aberration is a being of pure corrupted text. It absorbs knowledge, corrupts it, and spreads misinformation. Every book it touches becomes unreadable.

#### Full Stats

```json
{
  "boss_id": "codex_aberration",
  "name": "Codex Aberration",
  "title": "The Living Library",
  "region": "mistfen",
  "difficulty": 8,
  "recommended_level": 25,
  "recommended_wpm": 55,
  "recommended_accuracy": 0.92,

  "base_stats": {
    "total_hp": 1400,
    "phase_count": 3,
    "enrage_timer": 420,
    "word_difficulty": "tier_5"
  }
}
```

#### Phase 1: Index (100% - 65% HP)

```json
{
  "phase_number": 1,
  "phase_name": "Index",

  "mechanics": [
    {
      "id": "page_shield",
      "description": "Surrounded by floating pages that absorb damage",
      "effect": "Must destroy 5 pages (typing their words) before core is vulnerable"
    },
    {
      "id": "word_catalog",
      "description": "Categorizes player's typing patterns",
      "effect": "Future attacks target player's weak letter combinations"
    }
  ],

  "attacks": [
    {
      "attack_id": "paper_cut",
      "name": "Paper Storm",
      "type": "multi_hit",
      "damage": 10,
      "hits": 8,
      "word_requirement": {
        "word_pool": ["shield", "guard", "protect", "defend", "block", "ward", "barrier", "shelter"],
        "count": 8,
        "time_limit": 10.0
      }
    },
    {
      "attack_id": "ink_blast",
      "name": "Ink Blast",
      "type": "direct",
      "damage": 25,
      "debuff": "vision_blur",
      "word_requirement": {
        "word_pool": ["clean", "wipe", "clear", "wash"],
        "time_limit": 2.0
      }
    },
    {
      "attack_id": "summon_chapter",
      "name": "Summon Chapter",
      "type": "summon",
      "effect": "Summons themed enemies based on book chapter"
    }
  ]
}
```

#### Phase 2: Contents (65% - 35% HP)

```json
{
  "phase_number": 2,
  "phase_name": "Contents",

  "mechanics": [
    {
      "id": "chapter_shifts",
      "description": "Boss changes 'chapters' with different abilities",
      "effect": "Every 45 seconds, new attack set based on chapter theme"
    },
    {
      "id": "bibliography",
      "description": "Boss references other bosses",
      "effect": "May use attacks from previously defeated bosses"
    }
  ],

  "chapter_themes": [
    {
      "chapter": "Nature",
      "attacks": ["vine_bind", "thorn_spray", "root_eruption"],
      "word_pool": ["botanical", "flora", "fauna", "ecosystem", "photosynthesis"]
    },
    {
      "chapter": "Elements",
      "attacks": ["fire_burst", "ice_shard", "lightning_strike"],
      "word_pool": ["combustion", "crystalline", "electrostatic", "thermodynamic"]
    },
    {
      "chapter": "History",
      "attacks": ["ancient_curse", "memory_drain", "time_slow"],
      "word_pool": ["chronological", "archaeological", "antiquarian", "prehistoric"]
    }
  ]
}
```

#### Phase 3: Appendix of Corruption (35% - 0% HP)

```json
{
  "phase_number": 3,
  "phase_name": "Appendix of Corruption",

  "mechanics": [
    {
      "id": "corruption_text",
      "description": "All text becomes partially corrupted",
      "effect": "Words display with random corrupted letters that must be corrected"
    },
    {
      "id": "unwriting",
      "description": "Aberration attempts to unwrite reality",
      "effect": "Arena features disappear unless 'restore' is typed"
    }
  ],

  "attacks": [
    {
      "attack_id": "corrupted_knowledge",
      "name": "Corrupted Knowledge",
      "type": "special",
      "damage": 40,
      "description": "Word appears corrupted, must type correct version",
      "word_requirement": {
        "displayed": "[corrupted version]",
        "correct": "[uncorrupted version]",
        "time_limit": 3.0
      }
    },
    {
      "attack_id": "erasure",
      "name": "Total Erasure",
      "type": "ultimate",
      "damage": 100,
      "word_requirement": {
        "word_pool": ["exist", "persist", "remain", "endure", "survive", "continue", "preserve", "maintain"],
        "count": 8,
        "time_limit": 12.0,
        "accuracy_threshold": 0.98
      }
    }
  ],

  "dialogue_triggers": [
    {
      "trigger": "defeat",
      "speaker": "codex_aberration",
      "text": "[pages scatter, revealing final message] THE KNOWLEDGE... WAS NEVER... LOST... ONLY... WAITING..."
    }
  ]
}
```

---

## World Bosses

### World Boss 1: The Word-Eater

**Boss ID:** `word_eater`
**Title:** Devourer of Language
**Difficulty:** 9/10
**Recommended:** Level 30+, 60 WPM, 94% accuracy

#### Overview

A Beast Lord of terrifying power, the Word-Eater consumes language itself. Where it passes, words fade from the Great Script. Settlements lose their names. Concepts become meaningless. It is perhaps the greatest threat to Keystonia's existence.

#### Full Stats

```json
{
  "boss_id": "word_eater",
  "name": "The Word-Eater",
  "title": "Devourer of Language",
  "region": "world",
  "difficulty": 9,
  "recommended_level": 30,
  "recommended_wpm": 60,
  "recommended_accuracy": 0.94,

  "base_stats": {
    "total_hp": 2500,
    "phase_count": 4,
    "enrage_timer": 600,
    "word_difficulty": "tier_5"
  },

  "special_notes": "World boss - spawns in random regions, requires group coordination"
}
```

#### Phase Summaries

**Phase 1: Hunger (100% - 75% HP)**
- Word-Eater is partially submerged in the ground
- Consumes words from the environment, healing
- Players must "feed" it decoy words while dealing damage
- Attacks: Word Vacuum, Language Drain, Devour

**Phase 2: Emergence (75% - 50% HP)**
- Word-Eater rises fully, revealing serpentine form
- Moves across the arena, leaving language-dead zones
- Must be herded away from important landmarks
- Attacks: Tail Sweep, Corruption Breath, Swallow Whole

**Phase 3: Frenzy (50% - 25% HP)**
- Word-Eater enters feeding frenzy
- Attacks become rapid and unpredictable
- Each successful attack heals the boss
- Attacks: Rapid Strikes, Area Consumption, Word Vortex

**Phase 4: Starvation (25% - 0% HP)**
- Word-Eater is weakened from lack of sustenance
- Desperate, powerful attacks but with longer recovery times
- Victory requires coordinated burst damage
- Attacks: Final Feast (ultimate), Desperate Lunge, Death Throes

---

### World Boss 2: The Echo-Horror

**Boss ID:** `echo_horror`
**Title:** Choir of the Fallen
**Difficulty:** 9/10
**Recommended:** Level 30+, 60 WPM, 94% accuracy

#### Overview

Made from the stolen voices of defeated defenders, the Echo-Horror is a nightmare of stolen techniques and corrupted memories. It speaks with the voices of the dead and fights with their skills.

#### Special Mechanics

```json
{
  "unique_mechanics": [
    {
      "id": "absorbed_defenders",
      "description": "Boss contains souls of fallen defenders",
      "effect": "Uses real typing techniques from game's most successful players (anonymized)"
    },
    {
      "id": "voice_recognition",
      "description": "Boss recognizes returning players",
      "effect": "Players who have died to this boss before face personalized attacks"
    },
    {
      "id": "memory_extraction",
      "description": "Upon defeat, boss extracts player memory",
      "effect": "Next encounter, boss has learned from your techniques"
    }
  ]
}
```

---

## Raid Bosses

### Raid Boss: The First-Typo

**Boss ID:** `first_typo`
**Title:** The Original Error
**Difficulty:** 10/10
**Recommended:** Level 35+, 70 WPM, 96% accuracy, 8-player group

#### Overview

The ultimate expression of the Corruption - some believe this IS the Typo Primordial given form. Fighting it means confronting the fundamental brokenness at the heart of reality.

#### Full Stats

```json
{
  "boss_id": "first_typo",
  "name": "The First-Typo",
  "title": "The Original Error",
  "region": "corruption_heart",
  "difficulty": 10,
  "recommended_level": 35,
  "recommended_wpm": 70,
  "recommended_accuracy": 0.96,
  "group_size": 8,

  "base_stats": {
    "total_hp": 10000,
    "phase_count": 5,
    "enrage_timer": 900,
    "word_difficulty": "tier_5+"
  }
}
```

#### Encounter Overview

The First-Typo encounter is a five-phase battle requiring perfect coordination between eight defenders, each with a specific role:

**Roles:**
- 2 Tanks (high accuracy, defensive words)
- 2 Healers (support words, cleanse debuffs)
- 4 DPS (high speed, damage words)

#### Phase 1: PERFCTION (100% - 80% HP)

The arena displays the original error: "PERFCTION"

```json
{
  "phase_number": 1,
  "phase_name": "PERFCTION",

  "mechanics": [
    {
      "id": "corrupted_display",
      "description": "The word PERFCTION floats above the boss",
      "effect": "All player typing has E key disabled unless cleansed"
    },
    {
      "id": "error_propagation",
      "description": "Boss spreads its error to players",
      "effect": "Random players get corrupted keyboards (random key disabled)"
    },
    {
      "id": "group_coordination",
      "description": "Certain attacks require multiple players typing simultaneously",
      "effect": "Typed words must sync within 0.5 seconds"
    }
  ],

  "attacks": [
    {
      "attack_id": "primal_error",
      "name": "Primal Error",
      "type": "raid_wide",
      "damage": 30,
      "word_requirement": {
        "pool": ["correction", "accuracy", "precision", "perfect"],
        "players_required": 8,
        "sync_window": 1.0
      }
    }
  ]
}
```

#### Phase 2: THE ECHO (80% - 60% HP)

The First-Typo manifests echoes of every error ever made

```json
{
  "phase_number": 2,
  "phase_name": "THE ECHO",

  "mechanics": [
    {
      "id": "error_storm",
      "description": "Every typo ever made manifests as an attack",
      "effect": "Constant barrage of words with intentional errors - type correct versions"
    },
    {
      "id": "personal_errors",
      "description": "Players face their own past mistakes",
      "effect": "Words you've recently mistyped appear as enemies"
    }
  ]
}
```

#### Phase 3: THE VOID (60% - 40% HP)

The First-Typo reveals the void behind all errors

```json
{
  "phase_number": 3,
  "phase_name": "THE VOID",

  "mechanics": [
    {
      "id": "void_zones",
      "description": "Sections of arena become void",
      "effect": "Players in void cannot type - must be pulled out by others"
    },
    {
      "id": "meaning_drain",
      "description": "Words lose meaning",
      "effect": "Word prompts display as symbols - must remember what word was shown"
    }
  ]
}
```

#### Phase 4: RECONSTRUCTION (40% - 20% HP)

Players must type the word PERFECTION correctly to damage the boss

```json
{
  "phase_number": 4,
  "phase_name": "RECONSTRUCTION",

  "mechanics": [
    {
      "id": "the_correction",
      "description": "Players must collectively type PERFECTION",
      "effect": "Each player types one letter in sequence - must be perfect"
    },
    {
      "id": "resistance",
      "description": "Boss actively fights the correction",
      "effect": "Constant interruption attacks between letters"
    }
  ],

  "special_attack": {
    "name": "Spelling PERFECTION",
    "description": "8 players, 10 letters - each player must type their assigned letter at exactly the right moment",
    "sequence": ["P", "E", "R", "F", "E", "C", "T", "I", "O", "N"],
    "assignment": "Dynamic based on player position",
    "timing": "0.5 second windows",
    "on_success": "Massive damage to boss, phase ends",
    "on_failure": "Boss heals 10%, attack restarts"
  }
}
```

#### Phase 5: THE CHOICE (20% - 0% HP)

The First-Typo offers a choice: correct the error or embrace it

```json
{
  "phase_number": 5,
  "phase_name": "THE CHOICE",

  "mechanics": [
    {
      "id": "the_choice",
      "description": "Players vote on how to end the fight",
      "options": [
        {
          "choice": "Correct",
          "effect": "Type PERFECTION together - boss is corrected out of existence",
          "outcome": "Standard ending - boss destroyed, corruption reduced globally"
        },
        {
          "choice": "Embrace",
          "effect": "Type PERFCTION together - accept error as part of existence",
          "outcome": "Alternative ending - boss transforms, becomes neutral, corruption remains but stabilized"
        }
      ]
    }
  ],

  "dialogue": {
    "trigger": "phase_start",
    "speaker": "first_typo",
    "text": "YOU STAND AT THE MOMENT OF CHOICE. WILL YOU CORRECT ME... AND LOSE ALL THAT MY ERROR CREATED? OR ACCEPT ME... AND LEARN TO LIVE WITH IMPERFECTION?"
  }
}
```

#### Rewards

```json
{
  "rewards": {
    "correction_ending": {
      "xp": 5000,
      "gold": 2000,
      "items": [
        {"id": "shard_of_perfection", "chance": 1.0, "description": "Grants +5% accuracy permanently"},
        {"id": "correctors_crown", "chance": 0.1, "description": "Legendary headgear"},
        {"id": "perfect_keysteel", "chance": 0.5}
      ],
      "achievement": "the_correction",
      "world_effect": "Global corruption reduced by 5%"
    },
    "embrace_ending": {
      "xp": 5000,
      "gold": 2000,
      "items": [
        {"id": "shard_of_acceptance", "chance": 1.0, "description": "Grants +5% damage permanently"},
        {"id": "embracers_mantle", "chance": 0.1, "description": "Legendary armor"},
        {"id": "corrupted_keysteel", "chance": 0.5}
      ],
      "achievement": "the_acceptance",
      "world_effect": "Corruption stabilized - no longer spreads, but cannot be reduced below current level"
    }
  }
}
```

---

## Implementation Notes

### Boss State Machine

```gdscript
class_name BossController
extends Node

enum BossState {
    INTRO,
    PHASE_ACTIVE,
    PHASE_TRANSITION,
    ENRAGE,
    DEFEAT,
    SPECIAL_ENDING
}

var current_state: BossState = BossState.INTRO
var current_phase: int = 0
var hp_current: int
var hp_max: int
var phase_thresholds: Array[float]
var enrage_timer: float
var is_enraged: bool = false

func _process(delta: float) -> void:
    match current_state:
        BossState.PHASE_ACTIVE:
            process_phase(delta)
            check_phase_transition()
            check_enrage(delta)
        BossState.PHASE_TRANSITION:
            process_transition()
        BossState.ENRAGE:
            process_enraged_phase(delta)

func check_phase_transition() -> void:
    var hp_percent = float(hp_current) / float(hp_max)
    if hp_percent <= phase_thresholds[current_phase + 1]:
        begin_phase_transition()

func begin_phase_transition() -> void:
    current_state = BossState.PHASE_TRANSITION
    emit_signal("phase_transition_started", current_phase)
    # Play transition animation, dialogue, etc.
```

### Word Pool Generation

```gdscript
func get_attack_word_pool(attack_data: Dictionary) -> Array[String]:
    var base_pool = attack_data.word_requirement.word_pool

    # Adjust difficulty based on boss phase
    if current_phase >= 3:
        base_pool = filter_to_harder_words(base_pool)

    # Add player-weakness words if boss has that mechanic
    if boss_data.has_mechanic("player_weakness_targeting"):
        var weak_letters = player_stats.get_weak_letters()
        base_pool.append_array(get_words_with_letters(weak_letters))

    return base_pool
```

### Dialogue Trigger System

```gdscript
func check_dialogue_triggers(trigger_type: String, context: Dictionary = {}) -> void:
    for trigger in current_phase_data.dialogue_triggers:
        if trigger.trigger == trigger_type:
            if evaluate_trigger_condition(trigger, context):
                display_boss_dialogue(trigger.speaker, trigger.text)
                break

func evaluate_trigger_condition(trigger: Dictionary, context: Dictionary) -> bool:
    match trigger.trigger:
        "phase_start":
            return true
        "hp_below_15":
            return hp_current < hp_max * 0.15
        "player_hit":
            return randf() < trigger.get("chance", 1.0)
        _:
            return false
```

---

**Document version:** 1.0
**Bosses documented:** 8 regional + 2 world + 1 raid
**Total encounter scripts:** 11
**Total phase scripts:** 35+
