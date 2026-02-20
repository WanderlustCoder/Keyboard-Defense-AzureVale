# Tower Specifications Complete Catalog

**Last updated:** 2026-01-08

This document contains complete specifications for all tower types in Keyboard Defense, including stats, upgrade paths, synergies, and visual/audio specifications.

---

## Table of Contents

1. [Tower System Overview](#tower-system-overview)
2. [Basic Towers](#basic-towers)
3. [Advanced Towers](#advanced-towers)
4. [Specialist Towers](#specialist-towers)
5. [Legendary Towers](#legendary-towers)
6. [Tower Synergies](#tower-synergies)
7. [Placement Rules](#placement-rules)

---

## Tower System Overview

### Tower Data Structure

```json
{
  "tower_id": "string",
  "name": "Display Name",
  "category": "basic | advanced | specialist | legendary",
  "unlock_requirement": {},

  "base_stats": {
    "damage": 0,
    "attack_speed": 0.0,
    "range": 0,
    "word_bonus": "",
    "special_effect": ""
  },

  "upgrade_path": [],
  "placement_cost": 0,
  "footprint": "1x1 | 2x2 | 3x3",
  "terrain_requirements": [],
  "synergies": []
}
```

### Tower Categories

| Category | Unlock | Cost Range | Power Level |
|----------|--------|------------|-------------|
| Basic | Tutorial | 50-150 gold | Standard |
| Advanced | Level 10+ | 200-400 gold | Enhanced |
| Specialist | Level 20+ | 300-600 gold | Situational |
| Legendary | Level 30+ / Quest | 800-1500 gold | Exceptional |

---

## Basic Towers

### Tower 001: Arrow Tower

**ID:** `tower_arrow`
**Category:** Basic
**Unlock:** Tutorial completion

```json
{
  "tower_id": "tower_arrow",
  "name": "Arrow Tower",
  "category": "basic",
  "description": "A reliable tower that fires arrows at enemies. Effective against unarmored targets.",

  "base_stats": {
    "damage": 10,
    "attack_speed": 1.0,
    "range": 4,
    "damage_type": "physical",
    "target_type": "single",
    "word_bonus": "Words starting with 'A' deal +20% damage"
  },

  "placement_cost": 75,
  "footprint": "1x1",
  "terrain_requirements": ["ground"],

  "visual": {
    "sprite": "tower_arrow.png",
    "attack_animation": "arrow_fire",
    "projectile": "arrow_basic",
    "idle_animation": "tower_idle_sway"
  },

  "audio": {
    "attack": "sfx_arrow_fire",
    "hit": "sfx_arrow_impact",
    "upgrade": "sfx_tower_upgrade"
  }
}
```

#### Upgrade Path

```json
{
  "upgrades": [
    {
      "tier": 1,
      "name": "Sharpened Arrows",
      "cost": 50,
      "effect": "+5 damage",
      "new_stats": {"damage": 15}
    },
    {
      "tier": 2,
      "name": "Quick Nocking",
      "cost": 75,
      "effect": "+25% attack speed",
      "new_stats": {"attack_speed": 1.25}
    },
    {
      "tier": 3,
      "name": "Extended Range",
      "cost": 100,
      "effect": "+1 range",
      "new_stats": {"range": 5}
    },
    {
      "tier": 4,
      "choice": true,
      "options": [
        {
          "name": "Piercing Shot",
          "cost": 150,
          "effect": "Arrows pierce through 2 enemies",
          "new_stats": {"pierce": 2},
          "evolves_to": "tower_arrow_piercing"
        },
        {
          "name": "Rapid Fire",
          "cost": 150,
          "effect": "+50% attack speed, -20% damage",
          "new_stats": {"attack_speed": 1.875, "damage": 12},
          "evolves_to": "tower_arrow_rapid"
        },
        {
          "name": "Heavy Draw",
          "cost": 150,
          "effect": "+100% damage, -25% attack speed",
          "new_stats": {"damage": 30, "attack_speed": 0.94},
          "evolves_to": "tower_arrow_heavy"
        }
      ]
    }
  ]
}
```

---

### Tower 002: Magic Tower

**ID:** `tower_magic`
**Category:** Basic
**Unlock:** Tutorial completion

```json
{
  "tower_id": "tower_magic",
  "name": "Magic Tower",
  "category": "basic",
  "description": "Fires bolts of arcane energy. Ignores armor but has slower attack speed.",

  "base_stats": {
    "damage": 15,
    "attack_speed": 0.7,
    "range": 5,
    "damage_type": "magic",
    "target_type": "single",
    "armor_pierce": true,
    "word_bonus": "Words with double letters deal +15% damage"
  },

  "placement_cost": 100,
  "footprint": "1x1",
  "terrain_requirements": ["ground", "elevated"],

  "visual": {
    "sprite": "tower_magic.png",
    "attack_animation": "magic_cast",
    "projectile": "magic_bolt_blue",
    "idle_animation": "tower_magic_glow"
  }
}
```

#### Upgrade Path

```json
{
  "upgrades": [
    {
      "tier": 1,
      "name": "Focused Energy",
      "cost": 60,
      "effect": "+8 damage",
      "new_stats": {"damage": 23}
    },
    {
      "tier": 2,
      "name": "Mana Efficiency",
      "cost": 80,
      "effect": "+20% attack speed",
      "new_stats": {"attack_speed": 0.84}
    },
    {
      "tier": 3,
      "name": "Arcane Reach",
      "cost": 100,
      "effect": "+1 range",
      "new_stats": {"range": 6}
    },
    {
      "tier": 4,
      "choice": true,
      "options": [
        {
          "name": "Chain Lightning",
          "cost": 175,
          "effect": "Attacks jump to 2 nearby enemies (50% damage each)",
          "evolves_to": "tower_magic_chain"
        },
        {
          "name": "Arcane Burst",
          "cost": 175,
          "effect": "Attacks explode for AoE damage (3 damage, 1 tile radius)",
          "evolves_to": "tower_magic_burst"
        },
        {
          "name": "Mana Drain",
          "cost": 175,
          "effect": "Attacks slow enemy by 15% for 2 seconds",
          "evolves_to": "tower_magic_drain"
        }
      ]
    }
  ]
}
```

---

### Tower 003: Slow Tower

**ID:** `tower_slow`
**Category:** Basic
**Unlock:** Level 3

```json
{
  "tower_id": "tower_slow",
  "name": "Frost Tower",
  "category": "basic",
  "description": "Chills enemies, slowing their movement. Low damage but essential for control.",

  "base_stats": {
    "damage": 5,
    "attack_speed": 0.8,
    "range": 3,
    "damage_type": "cold",
    "target_type": "single",
    "slow_percent": 25,
    "slow_duration": 2.0,
    "word_bonus": "Words containing 'ice' or 'cold' apply +10% slow"
  },

  "placement_cost": 80,
  "footprint": "1x1",
  "terrain_requirements": ["ground"],

  "visual": {
    "sprite": "tower_frost.png",
    "attack_animation": "frost_cast",
    "projectile": "frost_shard",
    "idle_animation": "tower_frost_mist",
    "enemy_effect": "frost_overlay"
  }
}
```

#### Upgrade Path

```json
{
  "upgrades": [
    {
      "tier": 1,
      "name": "Deeper Chill",
      "cost": 50,
      "effect": "+10% slow",
      "new_stats": {"slow_percent": 35}
    },
    {
      "tier": 2,
      "name": "Lasting Cold",
      "cost": 70,
      "effect": "+1 second slow duration",
      "new_stats": {"slow_duration": 3.0}
    },
    {
      "tier": 3,
      "name": "Cold Snap",
      "cost": 90,
      "effect": "+1 range, +3 damage",
      "new_stats": {"range": 4, "damage": 8}
    },
    {
      "tier": 4,
      "choice": true,
      "options": [
        {
          "name": "Permafrost",
          "cost": 150,
          "effect": "Slow stacks up to 60%, enemies at max slow take +50% damage from all sources",
          "evolves_to": "tower_frost_perma"
        },
        {
          "name": "Blizzard",
          "cost": 150,
          "effect": "AoE slow in 2 tile radius, -10% slow power",
          "evolves_to": "tower_frost_blizzard"
        },
        {
          "name": "Flash Freeze",
          "cost": 150,
          "effect": "10% chance to freeze enemy for 1 second (stun)",
          "evolves_to": "tower_frost_freeze"
        }
      ]
    }
  ]
}
```

---

### Tower 004: Cannon Tower

**ID:** `tower_cannon`
**Category:** Basic
**Unlock:** Level 5

```json
{
  "tower_id": "tower_cannon",
  "name": "Cannon Tower",
  "category": "basic",
  "description": "Fires explosive shells that damage all enemies in blast radius. Slow but powerful.",

  "base_stats": {
    "damage": 25,
    "attack_speed": 0.4,
    "range": 4,
    "damage_type": "physical",
    "target_type": "aoe",
    "aoe_radius": 1.0,
    "word_bonus": "Words with 6+ letters deal +25% damage"
  },

  "placement_cost": 125,
  "footprint": "2x2",
  "terrain_requirements": ["ground"],

  "visual": {
    "sprite": "tower_cannon.png",
    "attack_animation": "cannon_fire",
    "projectile": "cannonball",
    "impact_animation": "explosion_small",
    "idle_animation": "cannon_idle"
  },

  "audio": {
    "attack": "sfx_cannon_fire",
    "hit": "sfx_explosion_small"
  }
}
```

#### Upgrade Path

```json
{
  "upgrades": [
    {
      "tier": 1,
      "name": "Bigger Shells",
      "cost": 75,
      "effect": "+15 damage",
      "new_stats": {"damage": 40}
    },
    {
      "tier": 2,
      "name": "Extended Barrel",
      "cost": 100,
      "effect": "+1 range",
      "new_stats": {"range": 5}
    },
    {
      "tier": 3,
      "name": "Wider Blast",
      "cost": 125,
      "effect": "+0.5 AoE radius",
      "new_stats": {"aoe_radius": 1.5}
    },
    {
      "tier": 4,
      "choice": true,
      "options": [
        {
          "name": "Artillery",
          "cost": 200,
          "effect": "+3 range, can target anywhere on map, +50% damage",
          "new_stats": {"range": 8, "damage": 60, "global_target": true},
          "evolves_to": "tower_artillery"
        },
        {
          "name": "Cluster Bomb",
          "cost": 200,
          "effect": "Shells split into 3 smaller explosions",
          "evolves_to": "tower_cannon_cluster"
        },
        {
          "name": "Napalm",
          "cost": 200,
          "effect": "Leaves burning ground for 3 seconds (5 damage/second)",
          "evolves_to": "tower_cannon_napalm"
        }
      ]
    }
  ]
}
```

---

## Advanced Towers

### Tower 005: Multi-Shot Tower

**ID:** `tower_multi`
**Category:** Advanced
**Unlock:** Level 10

```json
{
  "tower_id": "tower_multi",
  "name": "Multi-Shot Tower",
  "category": "advanced",
  "description": "Fires multiple projectiles at different targets simultaneously.",

  "base_stats": {
    "damage": 8,
    "attack_speed": 0.8,
    "range": 4,
    "damage_type": "physical",
    "target_type": "multi",
    "target_count": 3,
    "word_bonus": "Typing 3+ words in 5 seconds grants +1 target for next attack"
  },

  "placement_cost": 200,
  "footprint": "1x1",
  "terrain_requirements": ["ground", "elevated"],

  "unlock_requirement": {
    "type": "level",
    "value": 10
  }
}
```

#### Upgrade Path

```json
{
  "upgrades": [
    {
      "tier": 1,
      "name": "Additional Barrel",
      "cost": 100,
      "effect": "+1 target",
      "new_stats": {"target_count": 4}
    },
    {
      "tier": 2,
      "name": "Synchronized Fire",
      "cost": 125,
      "effect": "+4 damage per projectile",
      "new_stats": {"damage": 12}
    },
    {
      "tier": 3,
      "name": "Target Acquisition",
      "cost": 150,
      "effect": "+1 range, +1 target",
      "new_stats": {"range": 5, "target_count": 5}
    },
    {
      "tier": 4,
      "choice": true,
      "options": [
        {
          "name": "Gatling Tower",
          "cost": 250,
          "effect": "8 targets, +50% attack speed, -3 damage",
          "new_stats": {"target_count": 8, "attack_speed": 1.2, "damage": 9},
          "evolves_to": "tower_gatling"
        },
        {
          "name": "Sniper Array",
          "cost": 250,
          "effect": "3 targets, +10 range, +20 damage",
          "new_stats": {"target_count": 3, "range": 15, "damage": 32},
          "evolves_to": "tower_sniper_array"
        }
      ]
    }
  ]
}
```

---

### Tower 006: Arcane Tower

**ID:** `tower_arcane`
**Category:** Advanced
**Unlock:** Level 12

```json
{
  "tower_id": "tower_arcane",
  "name": "Arcane Tower",
  "category": "advanced",
  "description": "Channels powerful arcane energy. Deals bonus damage based on typing accuracy.",

  "base_stats": {
    "damage": 20,
    "attack_speed": 0.6,
    "range": 5,
    "damage_type": "magic",
    "target_type": "single",
    "accuracy_scaling": true,
    "accuracy_bonus": "Damage multiplied by accuracy (95% accuracy = 0.95x, 100% = 1.5x)",
    "word_bonus": "Perfect accuracy words deal double damage"
  },

  "placement_cost": 250,
  "footprint": "1x1",
  "terrain_requirements": ["ground", "arcane_node"]
}
```

#### Tier 3 Evolution: Arcane Spire

```json
{
  "tower_id": "tower_arcane_t3",
  "name": "Arcane Spire",
  "evolved_from": "tower_arcane",
  "tier": 3,

  "base_stats": {
    "damage": 45,
    "attack_speed": 0.5,
    "range": 6,
    "damage_type": "magic",
    "accuracy_scaling": true,
    "special_ability": {
      "name": "Arcane Overload",
      "description": "Every 10th attack deals 3x damage and chains to 3 targets",
      "cooldown_attacks": 10
    }
  }
}
```

---

### Tower 007: Holy Tower

**ID:** `tower_holy`
**Category:** Advanced
**Unlock:** Level 15

```json
{
  "tower_id": "tower_holy",
  "name": "Holy Tower",
  "category": "advanced",
  "description": "Radiates divine light. Deals bonus damage to corrupted enemies and can purify.",

  "base_stats": {
    "damage": 18,
    "attack_speed": 0.7,
    "range": 4,
    "damage_type": "holy",
    "target_type": "single",
    "corruption_bonus": 50,
    "purify_chance": 5,
    "word_bonus": "Words of purity ('cleanse', 'purify', etc.) have 25% purify chance"
  },

  "placement_cost": 275,
  "footprint": "1x1",
  "terrain_requirements": ["ground", "sacred_ground"],

  "special_effects": {
    "purify": "Removes one affix from target enemy",
    "aura": "Nearby towers deal +10% damage to corrupted enemies"
  }
}
```

---

### Tower 008: Siege Tower

**ID:** `tower_siege`
**Category:** Advanced
**Unlock:** Level 18

```json
{
  "tower_id": "tower_siege",
  "name": "Siege Tower",
  "category": "advanced",
  "description": "Massive damage dealer designed for boss fights. Charges up between attacks.",

  "base_stats": {
    "damage": 100,
    "attack_speed": 0.15,
    "range": 6,
    "damage_type": "physical",
    "target_type": "single",
    "charge_mechanic": true,
    "charge_time": 5.0,
    "word_bonus": "Each word typed during charge adds +10% damage (max +100%)"
  },

  "placement_cost": 350,
  "footprint": "2x2",
  "terrain_requirements": ["ground"],

  "mechanics": {
    "charge_system": {
      "base_charge": 5.0,
      "min_charge": 2.0,
      "max_damage_multiplier": 2.0,
      "visual": "siege_charge_glow"
    }
  }
}
```

---

## Specialist Towers

### Tower 009: Poison Tower

**ID:** `tower_poison`
**Category:** Specialist
**Unlock:** Level 20, Mistfen region

```json
{
  "tower_id": "tower_poison",
  "name": "Venomspire",
  "category": "specialist",
  "description": "Applies stacking poison that deals damage over time. Weak initial hit but devastating over time.",

  "base_stats": {
    "damage": 3,
    "attack_speed": 1.2,
    "range": 4,
    "damage_type": "poison",
    "target_type": "single",
    "poison_damage": 5,
    "poison_duration": 5.0,
    "poison_stacks": true,
    "max_stacks": 10,
    "word_bonus": "Words containing 'venom', 'toxic', or 'poison' apply 2 stacks"
  },

  "placement_cost": 300,
  "footprint": "1x1",
  "terrain_requirements": ["ground", "swamp"],

  "unlock_requirement": {
    "type": "compound",
    "conditions": [
      {"type": "level", "value": 20},
      {"type": "region_unlocked", "value": "mistfen"}
    ]
  }
}
```

---

### Tower 010: Tesla Tower

**ID:** `tower_tesla`
**Category:** Specialist
**Unlock:** Level 22, Stonepass region

```json
{
  "tower_id": "tower_tesla",
  "name": "Tesla Coil",
  "category": "specialist",
  "description": "Generates electricity that arcs between nearby enemies. More effective against grouped enemies.",

  "base_stats": {
    "damage": 12,
    "attack_speed": 0.5,
    "range": 3,
    "damage_type": "lightning",
    "target_type": "chain",
    "chain_count": 5,
    "chain_range": 2,
    "chain_falloff": 0.8,
    "word_bonus": "Words with 'Z' or 'X' add +2 chain targets"
  },

  "placement_cost": 325,
  "footprint": "1x1",
  "terrain_requirements": ["ground", "metal_deposit"],

  "mechanics": {
    "chain_lightning": {
      "description": "Each jump deals 80% of previous damage",
      "example": "12 -> 9.6 -> 7.7 -> 6.1 -> 4.9"
    }
  }
}
```

---

### Tower 011: Summoner Tower

**ID:** `tower_summoner`
**Category:** Specialist
**Unlock:** Level 25

```json
{
  "tower_id": "tower_summoner",
  "name": "Summoning Circle",
  "category": "specialist",
  "description": "Summons allied creatures to fight enemies. Summons persist until killed.",

  "base_stats": {
    "damage": 0,
    "attack_speed": 0,
    "range": 0,
    "summon_type": "word_warrior",
    "max_summons": 3,
    "summon_cooldown": 15.0,
    "word_bonus": "Typing creature names summons that specific type"
  },

  "placement_cost": 400,
  "footprint": "2x2",
  "terrain_requirements": ["ground"],

  "summons": {
    "word_warrior": {
      "hp": 50,
      "damage": 8,
      "attack_speed": 1.0,
      "movement_speed": 1.5,
      "duration": "until_killed"
    },
    "letter_sprite": {
      "hp": 25,
      "damage": 15,
      "attack_speed": 1.5,
      "movement_speed": 2.0,
      "special": "flies",
      "trigger_word": "sprite"
    },
    "grammar_golem": {
      "hp": 150,
      "damage": 20,
      "attack_speed": 0.5,
      "movement_speed": 0.8,
      "special": "taunt",
      "trigger_word": "golem"
    }
  }
}
```

---

### Tower 012: Support Tower

**ID:** `tower_support`
**Category:** Specialist
**Unlock:** Level 20

```json
{
  "tower_id": "tower_support",
  "name": "Command Post",
  "category": "specialist",
  "description": "Buffs nearby towers. Does not attack directly.",

  "base_stats": {
    "damage": 0,
    "attack_speed": 0,
    "range": 0,
    "aura_range": 3,
    "damage_buff": 15,
    "speed_buff": 10,
    "word_bonus": "Typing 'boost' grants +50% buffs for 5 seconds"
  },

  "placement_cost": 350,
  "footprint": "1x1",
  "terrain_requirements": ["ground", "elevated"],

  "aura_effects": {
    "base": {
      "damage_percent": 15,
      "attack_speed_percent": 10
    },
    "upgraded": {
      "damage_percent": 30,
      "attack_speed_percent": 20,
      "range_bonus": 1,
      "special": "Towers in range gain word bonus sharing"
    }
  }
}
```

---

### Tower 013: Trap Tower

**ID:** `tower_trap`
**Category:** Specialist
**Unlock:** Level 18

```json
{
  "tower_id": "tower_trap",
  "name": "Trap Nexus",
  "category": "specialist",
  "description": "Places traps on the path that trigger when enemies walk over them.",

  "base_stats": {
    "damage": 30,
    "trap_count": 3,
    "trap_recharge": 10.0,
    "trap_radius": 1.0,
    "placement_range": 5,
    "word_bonus": "Typing 'trap' instantly recharges one trap"
  },

  "placement_cost": 275,
  "footprint": "1x1",
  "terrain_requirements": ["ground"],

  "trap_types": {
    "explosive": {
      "damage": 30,
      "radius": 1.0,
      "effect": "none"
    },
    "frost": {
      "damage": 10,
      "radius": 1.5,
      "effect": "slow_50_3s"
    },
    "poison": {
      "damage": 5,
      "radius": 1.0,
      "effect": "poison_10_5s"
    },
    "stun": {
      "damage": 15,
      "radius": 0.5,
      "effect": "stun_2s"
    }
  }
}
```

---

## Legendary Towers

### Tower 014: Wordsmith's Forge

**ID:** `tower_legendary_wordsmith`
**Category:** Legendary
**Unlock:** Complete "Master of Words" quest chain

```json
{
  "tower_id": "tower_legendary_wordsmith",
  "name": "Wordsmith's Forge",
  "category": "legendary",
  "description": "The ultimate typing tower. Damage scales with typing speed and accuracy.",

  "base_stats": {
    "base_damage": 25,
    "attack_speed": 1.0,
    "range": 5,
    "damage_type": "pure",
    "target_type": "adaptive",
    "wpm_scaling": "damage = base * (1 + WPM/100)",
    "accuracy_scaling": "damage *= accuracy^2",
    "word_bonus": "All word bonuses from other towers apply here at 50% effectiveness"
  },

  "placement_cost": 1000,
  "footprint": "2x2",
  "terrain_requirements": ["ground"],
  "limit": 1,

  "unlock_requirement": {
    "type": "quest",
    "quest_id": "master_of_words",
    "quest_chain": ["apprentice_typist", "journeyman_scribe", "master_of_words"]
  },

  "special_abilities": {
    "word_forge": {
      "description": "Every 50 words typed, creates a 'Forged Word' projectile dealing 200 damage",
      "cooldown_words": 50
    },
    "perfect_strike": {
      "description": "100% accuracy over 10 words triggers a devastating strike (500 damage)",
      "requirement": "10 consecutive perfect words"
    }
  },

  "example_damage_calculation": {
    "scenario": "60 WPM, 95% accuracy",
    "base": 25,
    "wpm_multiplier": 1.6,
    "accuracy_multiplier": 0.9025,
    "final_damage": "25 * 1.6 * 0.9025 = 36.1 per attack"
  }
}
```

---

### Tower 015: Letter Spirit Shrine

**ID:** `tower_legendary_shrine`
**Category:** Legendary
**Unlock:** Collect all 26 Letter Spirit blessings

```json
{
  "tower_id": "tower_legendary_shrine",
  "name": "Letter Spirit Shrine",
  "category": "legendary",
  "description": "A shrine that channels the power of the Letter Spirits. Adapts to the current battle.",

  "base_stats": {
    "damage": "variable",
    "attack_speed": "variable",
    "range": 6,
    "damage_type": "holy",
    "target_type": "adaptive"
  },

  "placement_cost": 1200,
  "footprint": "3x3",
  "terrain_requirements": ["sacred_ground"],
  "limit": 1,

  "spirit_modes": {
    "alpha_mode": {
      "trigger": "Wave contains boss",
      "effect": "Single target, 100 damage, slow attack"
    },
    "epsilon_mode": {
      "trigger": "Wave contains 10+ enemies",
      "effect": "Chain lightning to all enemies in range"
    },
    "omega_mode": {
      "trigger": "Castle HP below 50%",
      "effect": "Aura that heals castle 1 HP per enemy killed"
    }
  },

  "passive_aura": {
    "description": "All towers gain +5% damage for each unique letter typed in the last 10 seconds",
    "max_bonus": 130
  }
}
```

---

### Tower 016: Corruption Purifier

**ID:** `tower_legendary_purifier`
**Category:** Legendary
**Unlock:** Defeat 1000 corrupted enemies with 95%+ accuracy

```json
{
  "tower_id": "tower_legendary_purifier",
  "name": "Corruption Purifier",
  "category": "legendary",
  "description": "Specifically designed to combat corruption. Can permanently remove enemy affixes.",

  "base_stats": {
    "damage": 40,
    "attack_speed": 0.6,
    "range": 5,
    "damage_type": "purification",
    "corruption_damage_bonus": 100,
    "purify_chance": 25,
    "word_bonus": "Words of purity guarantee purification"
  },

  "placement_cost": 1500,
  "footprint": "2x2",
  "terrain_requirements": ["ground"],
  "limit": 1,

  "special_abilities": {
    "mass_purification": {
      "description": "Every 30 seconds, attempt to purify all enemies in range",
      "cooldown": 30.0
    },
    "corruption_shield": {
      "description": "Nearby towers immune to corruption debuffs",
      "range": 4
    },
    "final_word": {
      "description": "Against bosses, typing the purification phrase deals massive damage",
      "phrase": "CORRUPTION END",
      "damage": 500
    }
  }
}
```

---

## Tower Synergies

### Synergy System

Placing certain tower combinations near each other unlocks bonus effects.

```json
{
  "synergies": [
    {
      "synergy_id": "fire_and_ice",
      "name": "Elemental Mastery",
      "towers_required": ["tower_cannon_napalm", "tower_frost_freeze"],
      "proximity": 3,
      "effect": "Frozen enemies take 3x damage from fire, burning enemies take 3x damage from ice",
      "visual": "steam_effect"
    },
    {
      "synergy_id": "arrow_rain",
      "name": "Arrow Storm",
      "towers_required": ["tower_arrow", "tower_arrow", "tower_arrow"],
      "proximity": 2,
      "effect": "Every 15 seconds, all arrow towers fire simultaneously at all targets in range",
      "visual": "arrow_rain_effect"
    },
    {
      "synergy_id": "arcane_support",
      "name": "Arcane Amplification",
      "towers_required": ["tower_arcane", "tower_support"],
      "proximity": 3,
      "effect": "Arcane tower gains +50% accuracy bonus scaling",
      "visual": "arcane_link_beam"
    },
    {
      "synergy_id": "holy_purification",
      "name": "Divine Cleansing",
      "towers_required": ["tower_holy", "tower_legendary_purifier"],
      "proximity": 4,
      "effect": "Purification chance doubled, purified enemies explode dealing holy damage",
      "visual": "holy_explosion"
    },
    {
      "synergy_id": "chain_reaction",
      "name": "Chain Reaction",
      "towers_required": ["tower_tesla", "tower_magic_chain"],
      "proximity": 3,
      "effect": "Chain attacks have +3 jumps and no damage falloff",
      "visual": "electric_arc_enhanced"
    },
    {
      "synergy_id": "death_zone",
      "name": "Kill Box",
      "towers_required": ["tower_slow", "tower_cannon", "tower_poison"],
      "proximity": 2,
      "effect": "Enemies in overlapping range take +25% damage from all sources",
      "visual": "danger_zone_overlay"
    },
    {
      "synergy_id": "summoner_army",
      "name": "Legion",
      "towers_required": ["tower_summoner", "tower_summoner"],
      "proximity": 4,
      "effect": "Max summons increased by 2 for each summoner, summons gain +20% stats",
      "visual": "summon_link"
    },
    {
      "synergy_id": "boss_killer",
      "name": "Titan Slayer",
      "towers_required": ["tower_siege", "tower_support", "tower_arcane"],
      "proximity": 3,
      "effect": "Siege tower charges 50% faster and deals +100% damage to bosses",
      "visual": "siege_power_up"
    }
  ]
}
```

---

## Placement Rules

### Terrain Types

```json
{
  "terrain_types": {
    "ground": {
      "description": "Standard buildable terrain",
      "towers_allowed": "all_ground_towers",
      "visual": "grass_tile"
    },
    "elevated": {
      "description": "Raised platforms with extended range",
      "towers_allowed": ["tower_arrow", "tower_magic", "tower_multi", "tower_support"],
      "bonus": "+1 range for all towers",
      "visual": "platform_tile"
    },
    "water": {
      "description": "Cannot build directly",
      "towers_allowed": [],
      "bridge_buildable": true,
      "visual": "water_tile"
    },
    "swamp": {
      "description": "Poison-themed terrain",
      "towers_allowed": ["tower_poison", "tower_slow"],
      "bonus": "Poison towers gain +2 max stacks",
      "visual": "swamp_tile"
    },
    "sacred_ground": {
      "description": "Holy terrain, limited locations",
      "towers_allowed": ["tower_holy", "tower_legendary_shrine"],
      "bonus": "Holy towers gain +25% purify chance",
      "visual": "sacred_glow_tile"
    },
    "arcane_node": {
      "description": "Magical confluence points",
      "towers_allowed": ["tower_magic", "tower_arcane", "tower_legendary_wordsmith"],
      "bonus": "Magic towers gain +20% damage",
      "visual": "arcane_rune_tile"
    },
    "metal_deposit": {
      "description": "Resource-rich terrain",
      "towers_allowed": ["tower_tesla", "tower_cannon"],
      "bonus": "Tesla tower gains +2 chain targets",
      "visual": "ore_vein_tile"
    }
  }
}
```

### Build Rules

```json
{
  "build_rules": {
    "path_blocking": {
      "description": "Towers cannot completely block enemy paths",
      "minimum_path_width": 1,
      "pathfinding_check": true
    },
    "spacing": {
      "minimum_distance": 0,
      "overlap_allowed": false
    },
    "tower_limits": {
      "legendary_towers": 1,
      "per_type_limit": "none",
      "total_tower_limit": 20
    },
    "selling": {
      "refund_percent": 75,
      "upgrade_refund": 50,
      "cooldown": 5.0
    },
    "repositioning": {
      "allowed": true,
      "cost": "10% of tower value",
      "cooldown": 10.0
    }
  }
}
```

---

## Implementation Notes

### Tower Controller Structure

```gdscript
class_name Tower
extends Node2D

@export var tower_data: TowerData
var current_tier: int = 0
var upgrade_path: Array[UpgradeData]
var current_target: Enemy
var attack_timer: float = 0.0
var word_bonus_active: bool = false

func _process(delta: float) -> void:
    attack_timer += delta
    if attack_timer >= 1.0 / tower_data.attack_speed:
        if current_target and is_target_valid():
            perform_attack()
            attack_timer = 0.0
        else:
            acquire_target()

func perform_attack() -> void:
    var damage = calculate_damage()
    var projectile = spawn_projectile()
    projectile.damage = damage
    projectile.target = current_target
    emit_signal("attack_performed", self, current_target, damage)

func calculate_damage() -> int:
    var base = tower_data.damage
    var multiplier = 1.0

    # Apply word bonus
    if word_bonus_active:
        multiplier *= tower_data.word_bonus_multiplier

    # Apply synergy bonuses
    for synergy in active_synergies:
        multiplier *= synergy.damage_multiplier

    # Apply support tower buffs
    multiplier *= get_support_buff()

    return int(base * multiplier)
```

---

**Document version:** 1.0
**Total towers documented:** 16 base + evolutions
**Synergies documented:** 8
**Terrain types:** 7
