# Auto-Defense Tower System

**Version:** 1.0.0
**Last Updated:** 2026-01-09
**Status:** Implementation Ready

## Overview

Auto-Defense Towers provide consistent, hands-free damage while the player focuses on typing-based combat. These towers fire automatically at enemies within range, complementing the core typing gameplay without replacing it.

### Design Philosophy

1. **Support Role**: Auto-towers deal lower damage than typing-activated towers but provide reliable baseline defense
2. **Resource Trade-off**: More expensive to build and upgrade, balancing their passive benefits
3. **Synergy Focus**: Best when combined with typing towers through combo bonuses
4. **Strategic Depth**: Placement becomes more critical since they can't be manually targeted

---

## Auto-Tower Types

### Tier 1 - Basic Auto-Towers

#### Sentry Turret
```json
{
  "tower_id": "auto_sentry",
  "name": "Sentry Turret",
  "type": "auto_defense",
  "tier": 1,
  "description": "A clockwork turret that automatically fires at nearby enemies.",
  "base_stats": {
    "damage": 5,
    "attack_speed": 0.8,
    "range": 3,
    "targeting": "nearest"
  },
  "build_cost": {
    "gold": 80,
    "scrap_metal": 10
  },
  "unlock_requirements": {
    "story_chapter": 2,
    "typing_level": 5
  },
  "flavor_text": "Wind it up and watch it work."
}
```

#### Spark Coil
```json
{
  "tower_id": "auto_spark",
  "name": "Spark Coil",
  "type": "auto_defense",
  "tier": 1,
  "description": "Releases electrical pulses that damage all enemies in range.",
  "base_stats": {
    "damage": 3,
    "attack_speed": 1.5,
    "range": 2,
    "targeting": "aoe_pulse",
    "aoe_radius": 2
  },
  "build_cost": {
    "gold": 100,
    "lightning_crystal": 5
  },
  "unlock_requirements": {
    "story_chapter": 2,
    "complete_region": "voltara_plains"
  },
  "flavor_text": "The air crackles with anticipation."
}
```

#### Thorn Barrier
```json
{
  "tower_id": "auto_thorns",
  "name": "Thorn Barrier",
  "type": "auto_defense",
  "tier": 1,
  "description": "A living barrier that damages enemies passing through.",
  "base_stats": {
    "damage": 8,
    "attack_speed": 0,
    "range": 1,
    "targeting": "contact",
    "damage_type": "piercing"
  },
  "special_mechanics": {
    "passive_damage": true,
    "damage_on_contact": 8,
    "slow_percent": 15
  },
  "build_cost": {
    "gold": 60,
    "living_wood": 8
  },
  "unlock_requirements": {
    "story_chapter": 1,
    "complete_lesson": "home_row_basics"
  },
  "flavor_text": "Nature's first line of defense."
}
```

### Tier 2 - Advanced Auto-Towers

#### Ballista Emplacement
```json
{
  "tower_id": "auto_ballista",
  "name": "Ballista Emplacement",
  "type": "auto_defense",
  "tier": 2,
  "description": "Heavy siege weapon that deals massive damage to single targets.",
  "base_stats": {
    "damage": 25,
    "attack_speed": 0.3,
    "range": 6,
    "targeting": "highest_health",
    "armor_pierce": 50
  },
  "upgrade_from": "auto_sentry",
  "upgrade_cost": {
    "gold": 150,
    "reinforced_steel": 15,
    "siege_blueprint": 1
  },
  "unlock_requirements": {
    "typing_level": 12,
    "defeat_boss": "fortress_guardian"
  },
  "flavor_text": "One shot, one problem solved."
}
```

#### Tesla Array
```json
{
  "tower_id": "auto_tesla",
  "name": "Tesla Array",
  "type": "auto_defense",
  "tier": 2,
  "description": "Chain lightning bounces between multiple enemies.",
  "base_stats": {
    "damage": 8,
    "attack_speed": 1.0,
    "range": 4,
    "targeting": "chain",
    "chain_count": 4,
    "chain_damage_falloff": 0.8
  },
  "upgrade_from": "auto_spark",
  "upgrade_cost": {
    "gold": 180,
    "lightning_crystal": 20,
    "conductor_coil": 3
  },
  "unlock_requirements": {
    "typing_level": 15,
    "craft_item": "storm_capacitor"
  },
  "flavor_text": "Lightning never strikes twice? Think again."
}
```

#### Bramble Maze
```json
{
  "tower_id": "auto_bramble",
  "name": "Bramble Maze",
  "type": "auto_defense",
  "tier": 2,
  "description": "Expanding thorns that create a damage zone.",
  "base_stats": {
    "damage": 4,
    "attack_speed": 0,
    "range": 3,
    "targeting": "zone",
    "zone_shape": "circle"
  },
  "special_mechanics": {
    "dot_damage": 4,
    "dot_interval": 0.5,
    "slow_percent": 30,
    "root_chance": 10
  },
  "upgrade_from": "auto_thorns",
  "upgrade_cost": {
    "gold": 120,
    "living_wood": 20,
    "growth_essence": 5
  },
  "unlock_requirements": {
    "typing_level": 10,
    "complete_region": "verdant_grove"
  },
  "flavor_text": "The forest remembers all who trespass."
}
```

#### Flame Jet
```json
{
  "tower_id": "auto_flame",
  "name": "Flame Jet",
  "type": "auto_defense",
  "tier": 2,
  "description": "Sprays fire in a cone, burning all enemies in its path.",
  "base_stats": {
    "damage": 6,
    "attack_speed": 2.0,
    "range": 3,
    "targeting": "cone",
    "cone_angle": 60
  },
  "special_mechanics": {
    "burn_damage": 3,
    "burn_duration": 3.0,
    "burn_stacks": true
  },
  "build_cost": {
    "gold": 140,
    "fire_crystal": 15,
    "fuel_tank": 2
  },
  "unlock_requirements": {
    "typing_level": 8,
    "complete_lesson": "number_row"
  },
  "flavor_text": "Everything burns eventually."
}
```

### Tier 3 - Elite Auto-Towers

#### Siege Cannon
```json
{
  "tower_id": "auto_cannon",
  "name": "Siege Cannon",
  "type": "auto_defense",
  "tier": 3,
  "description": "Devastating artillery that fires explosive shells.",
  "base_stats": {
    "damage": 50,
    "attack_speed": 0.2,
    "range": 8,
    "targeting": "cluster",
    "splash_radius": 2,
    "splash_damage_percent": 60
  },
  "upgrade_from": "auto_ballista",
  "upgrade_cost": {
    "gold": 300,
    "reinforced_steel": 30,
    "explosive_powder": 10,
    "siege_blueprint": 3
  },
  "unlock_requirements": {
    "typing_level": 25,
    "defeat_boss": "iron_colossus"
  },
  "flavor_text": "When subtlety fails, bring bigger guns."
}
```

#### Storm Spire
```json
{
  "tower_id": "auto_storm",
  "name": "Storm Spire",
  "type": "auto_defense",
  "tier": 3,
  "description": "Calls down lightning storms on enemy clusters.",
  "base_stats": {
    "damage": 15,
    "attack_speed": 0.5,
    "range": 6,
    "targeting": "cluster_aoe",
    "storm_radius": 3,
    "strikes_per_storm": 5
  },
  "special_mechanics": {
    "stun_chance": 20,
    "stun_duration": 1.0,
    "weather_boost": {
      "condition": "stormy",
      "damage_bonus": 50,
      "stun_chance_bonus": 15
    }
  },
  "upgrade_from": "auto_tesla",
  "upgrade_cost": {
    "gold": 350,
    "lightning_crystal": 40,
    "storm_essence": 5,
    "ancient_conduit": 1
  },
  "unlock_requirements": {
    "typing_level": 28,
    "complete_achievement": "storm_caller"
  },
  "flavor_text": "The sky itself bends to your will."
}
```

#### Living Fortress
```json
{
  "tower_id": "auto_fortress",
  "name": "Living Fortress",
  "type": "auto_defense",
  "tier": 3,
  "description": "A massive treant that blocks paths and strikes nearby foes.",
  "base_stats": {
    "damage": 20,
    "attack_speed": 0.8,
    "range": 2,
    "targeting": "melee_aoe",
    "health": 500,
    "armor": 30
  },
  "special_mechanics": {
    "blocks_path": true,
    "regeneration": 5,
    "root_network": {
      "share_damage": 20,
      "nearby_tower_bonus": "10% damage"
    }
  },
  "upgrade_from": "auto_bramble",
  "upgrade_cost": {
    "gold": 400,
    "living_wood": 50,
    "ancient_seed": 1,
    "nature_crystal": 10
  },
  "unlock_requirements": {
    "typing_level": 30,
    "complete_quest": "heart_of_the_forest"
  },
  "flavor_text": "Ancient protector of the realm."
}
```

#### Inferno Engine
```json
{
  "tower_id": "auto_inferno",
  "name": "Inferno Engine",
  "type": "auto_defense",
  "tier": 3,
  "description": "Industrial flame thrower with increasing damage over time.",
  "base_stats": {
    "damage": 10,
    "attack_speed": 3.0,
    "range": 4,
    "targeting": "beam",
    "beam_width": 1
  },
  "special_mechanics": {
    "ramp_up_damage": {
      "max_multiplier": 3.0,
      "ramp_time": 5.0,
      "reset_on_target_change": true
    },
    "fuel_system": {
      "max_fuel": 100,
      "burn_rate": 5,
      "refuel_rate": 10,
      "empty_behavior": "cooldown"
    }
  },
  "upgrade_from": "auto_flame",
  "upgrade_cost": {
    "gold": 320,
    "fire_crystal": 35,
    "magma_core": 2,
    "industrial_parts": 15
  },
  "unlock_requirements": {
    "typing_level": 22,
    "complete_region": "ember_wastes"
  },
  "flavor_text": "Feed the flames, reap the ashes."
}
```

### Tier 4 - Legendary Auto-Towers

#### Arcane Sentinel
```json
{
  "tower_id": "auto_arcane_sentinel",
  "name": "Arcane Sentinel",
  "type": "auto_defense",
  "tier": 4,
  "legendary": true,
  "description": "Ancient construct infused with letter magic. Adapts to enemy weaknesses.",
  "base_stats": {
    "damage": 35,
    "attack_speed": 1.2,
    "range": 5,
    "targeting": "smart",
    "damage_type": "adaptive"
  },
  "special_mechanics": {
    "weakness_detection": {
      "scan_time": 2.0,
      "damage_bonus_vs_weakness": 75
    },
    "spell_rotation": [
      {"spell": "arcane_bolt", "damage": 35, "cooldown": 0},
      {"spell": "void_ray", "damage": 50, "cooldown": 8, "pierce": true},
      {"spell": "mana_burst", "damage": 20, "cooldown": 15, "aoe": 3}
    ],
    "typing_synergy": {
      "trigger": "player_completes_word",
      "effect": "next_attack_crits",
      "duration": 3.0
    }
  },
  "build_cost": {
    "gold": 800,
    "arcane_crystal": 25,
    "ancient_core": 1,
    "legendary_blueprint": 1
  },
  "unlock_requirements": {
    "typing_level": 40,
    "complete_quest": "secrets_of_the_ancients",
    "defeat_boss": "arcane_overlord"
  },
  "limit_per_map": 1,
  "flavor_text": "The letters themselves serve as its ammunition."
}
```

#### Doom Fortress
```json
{
  "tower_id": "auto_doom_fortress",
  "name": "Doom Fortress",
  "type": "auto_defense",
  "tier": 4,
  "legendary": true,
  "description": "Massive automated defense platform with multiple weapon systems.",
  "base_stats": {
    "damage": 0,
    "attack_speed": 0,
    "range": 7,
    "targeting": "multi_system",
    "health": 1000,
    "armor": 50
  },
  "weapon_systems": [
    {
      "system": "main_cannon",
      "damage": 80,
      "attack_speed": 0.15,
      "targeting": "highest_health"
    },
    {
      "system": "anti_air_turrets",
      "count": 4,
      "damage": 12,
      "attack_speed": 2.0,
      "targeting": "flying_priority"
    },
    {
      "system": "flame_moat",
      "damage": 5,
      "tick_rate": 0.5,
      "area": "perimeter"
    },
    {
      "system": "shield_generator",
      "shield_hp": 200,
      "recharge_rate": 10,
      "recharge_delay": 5.0
    }
  ],
  "special_mechanics": {
    "command_aura": {
      "range": 5,
      "ally_damage_bonus": 15,
      "ally_attack_speed_bonus": 10
    },
    "emergency_protocol": {
      "trigger": "health_below_25%",
      "effect": "double_fire_rate",
      "duration": 10.0
    }
  },
  "build_cost": {
    "gold": 1500,
    "reinforced_steel": 100,
    "legendary_blueprint": 1,
    "fortress_core": 1,
    "various_crystals": 50
  },
  "unlock_requirements": {
    "typing_level": 50,
    "complete_all_regions": true,
    "collect_all_blueprints": true
  },
  "limit_per_map": 1,
  "size": "3x3",
  "flavor_text": "An army unto itself."
}
```

---

## Targeting Systems

### Targeting Priority Types

```json
{
  "targeting_modes": {
    "nearest": {
      "description": "Attacks closest enemy within range",
      "update_frequency": "continuous"
    },
    "highest_health": {
      "description": "Prioritizes enemy with most HP",
      "update_frequency": "on_kill"
    },
    "lowest_health": {
      "description": "Prioritizes weakest enemy for quick kills",
      "update_frequency": "continuous"
    },
    "fastest": {
      "description": "Targets fastest-moving enemies",
      "update_frequency": "continuous"
    },
    "cluster": {
      "description": "Finds largest group of enemies for splash",
      "update_frequency": "every_2_seconds"
    },
    "furthest_along_path": {
      "description": "Targets enemy closest to base",
      "update_frequency": "continuous"
    },
    "flying_priority": {
      "description": "Prioritizes flying enemies, then nearest",
      "update_frequency": "continuous"
    },
    "elite_priority": {
      "description": "Prioritizes elite/boss enemies",
      "update_frequency": "on_spawn"
    },
    "smart": {
      "description": "AI-driven optimal target selection",
      "factors": ["threat_level", "weakness", "cluster_value", "path_position"]
    }
  }
}
```

### Targeting Configuration

```json
{
  "targeting_config": {
    "allow_player_override": true,
    "override_ui": "right_click_tower",
    "available_modes_by_tier": {
      "1": ["nearest", "furthest_along_path"],
      "2": ["nearest", "furthest_along_path", "highest_health", "lowest_health"],
      "3": ["all_modes"],
      "4": ["all_modes", "smart"]
    },
    "default_mode": "nearest"
  }
}
```

---

## Balance Mechanics

### Damage Scaling vs Typing Towers

```json
{
  "balance_ratios": {
    "auto_vs_typing_damage": {
      "base_ratio": 0.4,
      "description": "Auto-towers deal 40% of equivalent typing tower damage",
      "rationale": "Passive benefit requires trade-off"
    },
    "auto_vs_typing_cost": {
      "base_ratio": 1.5,
      "description": "Auto-towers cost 50% more than equivalent typing towers",
      "rationale": "Premium for convenience"
    },
    "upgrade_cost_scaling": {
      "tier_2_multiplier": 2.0,
      "tier_3_multiplier": 3.5,
      "tier_4_multiplier": 6.0
    }
  }
}
```

### Efficiency Caps

```json
{
  "efficiency_limits": {
    "max_auto_towers_per_map": {
      "small_map": 4,
      "medium_map": 6,
      "large_map": 8
    },
    "auto_tower_damage_cap": {
      "enabled": true,
      "cap_percent_of_total": 35,
      "description": "Auto-towers can contribute max 35% of total tower damage",
      "overflow_behavior": "reduced_attack_speed"
    },
    "legendary_limit": 1
  }
}
```

### Resource Competition

```json
{
  "resource_design": {
    "shared_resources": {
      "gold": "Used by all towers",
      "crystals": "Shared, creates choice between auto and typing upgrades"
    },
    "auto_exclusive_resources": {
      "scrap_metal": {
        "source": "Salvaging, enemy drops",
        "purpose": "Basic auto-tower construction"
      },
      "industrial_parts": {
        "source": "Crafting, rare drops",
        "purpose": "Advanced auto-tower upgrades"
      },
      "fuel_cells": {
        "source": "Mining, purchases",
        "purpose": "Powers flame and engine-type towers"
      }
    }
  }
}
```

---

## Synergy System

### Auto-Tower + Typing Tower Synergies

```json
{
  "cross_synergies": [
    {
      "synergy_id": "mechanical_precision",
      "name": "Mechanical Precision",
      "description": "Auto-towers gain accuracy from nearby typing towers",
      "requirements": {
        "auto_tower": "any_tier_2+",
        "typing_tower": "arrow_tower",
        "distance": 3
      },
      "effects": {
        "auto_tower_crit_chance": 15,
        "typing_tower_attack_speed": 10
      }
    },
    {
      "synergy_id": "elemental_cascade",
      "name": "Elemental Cascade",
      "description": "Elemental auto-towers amplify typing tower elemental damage",
      "requirements": {
        "auto_tower": ["auto_spark", "auto_tesla", "auto_storm", "auto_flame", "auto_inferno"],
        "typing_tower": ["magic_tower", "arcane_tower"],
        "distance": 4
      },
      "effects": {
        "typing_tower_elemental_damage": 25,
        "auto_tower_proc_chance": 10
      }
    },
    {
      "synergy_id": "living_network",
      "name": "Living Network",
      "description": "Nature auto-towers share resources with typing towers",
      "requirements": {
        "auto_tower": ["auto_thorns", "auto_bramble", "auto_fortress"],
        "typing_tower": "any",
        "distance": 2
      },
      "effects": {
        "nearby_towers_hp_regen": 5,
        "root_on_word_complete": {
          "chance": 20,
          "duration": 1.5
        }
      }
    },
    {
      "synergy_id": "overwatch_protocol",
      "name": "Overwatch Protocol",
      "description": "Auto-towers provide intel to typing towers",
      "requirements": {
        "auto_tower": "auto_sentry",
        "typing_tower": "any",
        "distance": 5
      },
      "effects": {
        "typing_tower_range": 1,
        "reveal_invisible_enemies": true
      }
    },
    {
      "synergy_id": "combo_amplifier",
      "name": "Combo Amplifier",
      "description": "Typing combos boost auto-tower damage temporarily",
      "requirements": {
        "player_combo": 5,
        "auto_tower": "any",
        "distance": "map_wide"
      },
      "effects": {
        "auto_tower_damage_per_combo": 2,
        "max_stacks": 20,
        "duration": 5.0,
        "decay": "gradual"
      }
    }
  ]
}
```

### Auto-Tower Internal Synergies

```json
{
  "auto_synergies": [
    {
      "synergy_id": "defense_grid",
      "name": "Defense Grid",
      "description": "Multiple auto-towers share targeting data",
      "requirements": {
        "auto_towers": 3,
        "distance": 4
      },
      "effects": {
        "no_duplicate_targeting": true,
        "coordinated_fire_bonus": 15
      }
    },
    {
      "synergy_id": "elemental_storm",
      "name": "Elemental Storm",
      "description": "Lightning and fire create devastating combo",
      "requirements": {
        "tower_1": ["auto_spark", "auto_tesla", "auto_storm"],
        "tower_2": ["auto_flame", "auto_inferno"],
        "distance": 3
      },
      "effects": {
        "explosion_on_kill": {
          "damage": 30,
          "radius": 2
        },
        "shock_and_burn_combo": {
          "damage_multiplier": 1.5
        }
      }
    },
    {
      "synergy_id": "fortress_network",
      "name": "Fortress Network",
      "description": "Heavy auto-towers create overlapping fields of fire",
      "requirements": {
        "auto_towers": ["auto_ballista", "auto_cannon"],
        "count": 2,
        "distance": 6
      },
      "effects": {
        "armor_shred_on_hit": 5,
        "stacks": true,
        "max_stacks": 10
      }
    }
  ]
}
```

---

## Upgrade Paths

### Branching Evolution System

```json
{
  "upgrade_trees": {
    "sentry_line": {
      "tier_1": "auto_sentry",
      "tier_2_options": [
        {
          "tower": "auto_ballista",
          "focus": "single_target_damage",
          "description": "Heavy hitter for tough enemies"
        },
        {
          "tower": "auto_minigun",
          "focus": "rapid_fire",
          "description": "High attack speed, lower damage per shot"
        }
      ],
      "tier_3_from_ballista": [
        {
          "tower": "auto_cannon",
          "focus": "siege_aoe",
          "description": "Explosive area damage"
        },
        {
          "tower": "auto_railgun",
          "focus": "pierce",
          "description": "Shots pierce through multiple enemies"
        }
      ],
      "tier_3_from_minigun": [
        {
          "tower": "auto_chaingun",
          "focus": "suppression",
          "description": "Slows enemies with sustained fire"
        },
        {
          "tower": "auto_missile_pod",
          "focus": "tracking",
          "description": "Homing missiles for flying enemies"
        }
      ]
    },
    "spark_line": {
      "tier_1": "auto_spark",
      "tier_2_options": [
        {
          "tower": "auto_tesla",
          "focus": "chain_lightning",
          "description": "Damage bounces between enemies"
        },
        {
          "tower": "auto_emp",
          "focus": "disable",
          "description": "Stuns mechanical enemies, slows others"
        }
      ],
      "tier_3_from_tesla": [
        {
          "tower": "auto_storm",
          "focus": "aoe_storms",
          "description": "Calls lightning storms on enemy groups"
        }
      ],
      "tier_3_from_emp": [
        {
          "tower": "auto_disruptor",
          "focus": "debuff",
          "description": "Reduces enemy damage and speed"
        }
      ]
    },
    "thorn_line": {
      "tier_1": "auto_thorns",
      "tier_2_options": [
        {
          "tower": "auto_bramble",
          "focus": "zone_control",
          "description": "Expanding damage zone"
        },
        {
          "tower": "auto_spore",
          "focus": "poison",
          "description": "Spreads toxic spores"
        }
      ],
      "tier_3_from_bramble": [
        {
          "tower": "auto_fortress",
          "focus": "blocking",
          "description": "Blocks paths and absorbs damage"
        }
      ],
      "tier_3_from_spore": [
        {
          "tower": "auto_plague",
          "focus": "spreading_dot",
          "description": "Poison spreads between enemies"
        }
      ]
    },
    "flame_line": {
      "tier_1": "auto_flame",
      "tier_2_options": [
        {
          "tower": "auto_inferno",
          "focus": "sustained_burn",
          "description": "Ramping damage over time"
        },
        {
          "tower": "auto_napalm",
          "focus": "ground_fire",
          "description": "Creates burning terrain"
        }
      ]
    }
  }
}
```

---

## Special Mechanics

### Overheat System

```json
{
  "overheat_mechanics": {
    "applies_to": ["auto_sentry", "auto_ballista", "auto_cannon", "auto_minigun", "auto_chaingun"],
    "heat_generation": {
      "per_shot": 5,
      "max_heat": 100
    },
    "overheat_threshold": 100,
    "overheat_effects": {
      "attack_speed_reduction": 50,
      "duration": 5.0,
      "cooldown_rate": 20
    },
    "heat_sinks": {
      "upgrade_available": true,
      "max_heat_bonus": 30,
      "cooldown_rate_bonus": 50
    },
    "visual_indicator": {
      "0_50": "normal",
      "50_80": "orange_glow",
      "80_100": "red_glow_steam",
      "overheated": "smoke_sparks_slowdown"
    }
  }
}
```

### Fuel System

```json
{
  "fuel_mechanics": {
    "applies_to": ["auto_flame", "auto_inferno", "auto_napalm"],
    "fuel_capacity": {
      "base": 100,
      "upgraded": 150
    },
    "fuel_consumption": {
      "per_second_firing": 5,
      "idle": 0
    },
    "refuel_mechanics": {
      "auto_refuel_rate": 2,
      "fuel_drop_chance": 15,
      "fuel_drop_amount": 20,
      "supply_depot_synergy": {
        "refuel_rate_bonus": 100
      }
    },
    "empty_behavior": {
      "attack": "disabled",
      "duration": "until_refueled",
      "emergency_reserve": {
        "enabled": true,
        "reserve_amount": 10,
        "reduced_damage": 50
      }
    }
  }
}
```

### Ammunition System

```json
{
  "ammo_mechanics": {
    "applies_to": ["auto_ballista", "auto_cannon", "auto_missile_pod", "auto_railgun"],
    "ammo_types": {
      "standard": {
        "cost": 0,
        "damage_modifier": 1.0
      },
      "armor_piercing": {
        "cost_per_shot": 2,
        "armor_ignore": 75,
        "damage_modifier": 0.9
      },
      "explosive": {
        "cost_per_shot": 5,
        "splash_radius": 2,
        "splash_damage": 50,
        "damage_modifier": 1.2
      },
      "incendiary": {
        "cost_per_shot": 3,
        "burn_damage": 10,
        "burn_duration": 3.0,
        "damage_modifier": 0.8
      }
    },
    "ammo_selection": {
      "ui": "dropdown_on_tower_select",
      "auto_switch": {
        "enabled": true,
        "condition": "optimal_for_target"
      }
    }
  }
}
```

### Power Grid System

```json
{
  "power_grid": {
    "description": "Advanced auto-towers require power from generators",
    "applies_to": ["tier_3", "tier_4"],
    "power_sources": [
      {
        "source_id": "power_crystal",
        "name": "Power Crystal",
        "power_output": 50,
        "range": 4,
        "cost": {"gold": 100, "lightning_crystal": 10}
      },
      {
        "source_id": "generator",
        "name": "Arcane Generator",
        "power_output": 100,
        "range": 6,
        "cost": {"gold": 200, "arcane_crystal": 5, "industrial_parts": 10}
      },
      {
        "source_id": "power_relay",
        "name": "Power Relay",
        "power_output": 0,
        "extends_range": 4,
        "cost": {"gold": 50, "scrap_metal": 5}
      }
    ],
    "power_requirements": {
      "tier_3_towers": 30,
      "tier_4_towers": 75,
      "doom_fortress": 150
    },
    "underpowered_effects": {
      "0_50_percent": "50% attack speed reduction",
      "0_percent": "tower disabled"
    }
  }
}
```

---

## Placement Rules

### Terrain Compatibility

```json
{
  "placement_rules": {
    "auto_sentry": {
      "valid_terrain": ["grass", "stone", "elevated", "fortified"],
      "invalid_terrain": ["water", "lava", "void"],
      "special": "Can be placed on walls"
    },
    "auto_spark": {
      "valid_terrain": ["grass", "stone", "elevated"],
      "bonus_terrain": {
        "water_adjacent": "+25% chain range"
      }
    },
    "auto_thorns": {
      "valid_terrain": ["grass", "forest"],
      "bonus_terrain": {
        "forest": "+50% damage, +1 range"
      },
      "invalid_terrain": ["stone", "lava", "void", "water"]
    },
    "auto_flame": {
      "valid_terrain": ["grass", "stone", "lava_adjacent"],
      "bonus_terrain": {
        "lava_adjacent": "+30% damage"
      },
      "invalid_terrain": ["water", "forest"]
    },
    "auto_fortress": {
      "valid_terrain": ["grass", "forest"],
      "size": "2x2",
      "blocks_path": true,
      "placement_restriction": "Cannot block all paths"
    },
    "doom_fortress": {
      "valid_terrain": ["stone", "fortified"],
      "size": "3x3",
      "placement_restriction": "Requires reinforced foundation"
    }
  }
}
```

### Strategic Placement Bonuses

```json
{
  "placement_bonuses": {
    "elevated_ground": {
      "bonus": "+1 range, +10% damage",
      "applies_to": ["ballistic_type", "beam_type"]
    },
    "chokepoint": {
      "detection": "path_width <= 2",
      "bonus": "+20% damage for AoE towers",
      "applies_to": ["auto_spark", "auto_flame", "auto_bramble"]
    },
    "intersection": {
      "detection": "3+ path branches within range",
      "bonus": "+15% attack speed",
      "applies_to": "all"
    },
    "near_base": {
      "detection": "within 3 tiles of base",
      "bonus": "+25% damage (last stand)",
      "applies_to": "all"
    }
  }
}
```

---

## Unlocking System

### Progression Requirements

```json
{
  "unlock_progression": {
    "auto_tower_access": {
      "requirement": "Complete Chapter 2: 'The Clockwork Frontier'",
      "tutorial": "auto_tower_intro_mission"
    },
    "tier_unlock_requirements": {
      "tier_1": {
        "auto_sentry": "Default unlock with auto-tower access",
        "auto_spark": "Complete 'Storm Plains' region",
        "auto_thorns": "Complete 'Verdant Grove' region",
        "auto_flame": "Purchase from Blacksmith (500 gold)"
      },
      "tier_2": {
        "requirement": "Typing Level 10+",
        "additional": "Defeat specific mini-boss OR craft upgrade"
      },
      "tier_3": {
        "requirement": "Typing Level 20+",
        "additional": "Complete region boss + collect blueprint"
      },
      "tier_4": {
        "requirement": "Typing Level 40+",
        "additional": "Complete legendary quest chain"
      }
    }
  }
}
```

### Blueprint System

```json
{
  "blueprints": {
    "description": "Required to unlock advanced auto-tower upgrades",
    "acquisition": [
      {
        "method": "boss_drops",
        "drop_rate": "guaranteed_first_kill",
        "subsequent": "10% chance"
      },
      {
        "method": "exploration",
        "source": "Hidden caches in regions"
      },
      {
        "method": "achievement_rewards",
        "examples": ["Complete all typing challenges in region"]
      },
      {
        "method": "shop_purchase",
        "currency": "prestige_tokens",
        "availability": "After completing game once"
      }
    ],
    "blueprint_types": {
      "siege_blueprint": ["auto_ballista", "auto_cannon"],
      "energy_blueprint": ["auto_tesla", "auto_storm"],
      "nature_blueprint": ["auto_bramble", "auto_fortress"],
      "industrial_blueprint": ["auto_inferno", "doom_fortress"],
      "legendary_blueprint": ["auto_arcane_sentinel", "doom_fortress"]
    }
  }
}
```

---

## AI Behavior

### Auto-Tower Intelligence

```json
{
  "ai_behaviors": {
    "basic_ai": {
      "applies_to": "tier_1",
      "behavior": "Simple target selection based on chosen priority",
      "features": [
        "Continuous firing while target in range",
        "Immediate retarget on kill",
        "No predictive aiming"
      ]
    },
    "advanced_ai": {
      "applies_to": "tier_2",
      "behavior": "Improved targeting with prediction",
      "features": [
        "Lead shots for moving targets",
        "Prioritize wounded enemies",
        "Avoid overkill on dying targets"
      ]
    },
    "tactical_ai": {
      "applies_to": "tier_3",
      "behavior": "Coordinated with other towers",
      "features": [
        "Share targeting data",
        "Focus fire on priority targets",
        "Reserve ammo for elite enemies",
        "Predictive threat assessment"
      ]
    },
    "strategic_ai": {
      "applies_to": "tier_4",
      "behavior": "Map-wide awareness and optimization",
      "features": [
        "Optimal target selection across all factors",
        "Coordinate with typing towers",
        "Dynamic priority adjustment",
        "Resource conservation mode"
      ]
    }
  }
}
```

### Player Override System

```json
{
  "player_control": {
    "priority_lock": {
      "description": "Lock tower to specific targeting priority",
      "ui": "Right-click tower -> Set Priority",
      "persists": true
    },
    "target_lock": {
      "description": "Force tower to attack specific enemy",
      "ui": "Shift+click enemy while tower selected",
      "duration": "Until enemy dies or leaves range"
    },
    "hold_fire": {
      "description": "Prevent tower from firing",
      "ui": "Toggle in tower panel",
      "use_case": "Save ammo for upcoming wave"
    },
    "free_fire": {
      "description": "Remove all restrictions, attack anything",
      "ui": "Toggle in tower panel",
      "use_case": "Desperate defense situations"
    }
  }
}
```

---

## Integration with Typing Gameplay

### Typing Trigger Bonuses

```json
{
  "typing_integration": {
    "word_completion_bonus": {
      "trigger": "Player completes any word",
      "effect": "All auto-towers gain +10% attack speed for 2 seconds",
      "stacks": false,
      "refreshes": true
    },
    "perfect_word_bonus": {
      "trigger": "Player completes word with no errors",
      "effect": "Nearest auto-tower fires bonus shot",
      "damage_modifier": 1.5
    },
    "combo_bonus": {
      "trigger": "Player reaches combo milestones",
      "effects": {
        "5_combo": "Auto-towers +15% damage for 5 seconds",
        "10_combo": "Auto-towers +25% damage for 5 seconds",
        "20_combo": "Auto-towers +40% damage, +20% attack speed for 5 seconds"
      }
    },
    "speed_bonus": {
      "trigger": "Player WPM exceeds threshold",
      "thresholds": {
        "60_wpm": "Auto-towers +10% damage",
        "80_wpm": "Auto-towers +20% damage",
        "100_wpm": "Auto-towers +30% damage, projectiles pierce"
      },
      "duration": "While maintaining speed"
    }
  }
}
```

### Special Typing Commands

```json
{
  "typing_commands": {
    "description": "Special words that enhance auto-towers when typed",
    "commands": [
      {
        "word": "OVERCHARGE",
        "effect": "All auto-towers fire at 200% speed for 5 seconds",
        "cooldown": 60,
        "difficulty": "medium"
      },
      {
        "word": "BARRAGE",
        "effect": "All auto-towers fire simultaneously at single target",
        "cooldown": 45,
        "difficulty": "easy"
      },
      {
        "word": "FORTIFY",
        "effect": "Auto-towers gain 50% damage reduction for 10 seconds",
        "cooldown": 90,
        "difficulty": "hard"
      },
      {
        "word": "CALIBRATE",
        "effect": "Auto-towers gain 100% crit chance for next 5 shots",
        "cooldown": 30,
        "difficulty": "medium"
      },
      {
        "word": "RESUPPLY",
        "effect": "Instantly refill all ammo and fuel",
        "cooldown": 120,
        "difficulty": "hard"
      }
    ],
    "unlock_requirement": "Complete 'Command Protocol' side quest"
  }
}
```

---

## Economy Balance

### Cost Comparison Table

| Tower Type | Tier 1 Cost | Tier 2 Cost | Tier 3 Cost | DPS | Cost Efficiency |
|------------|-------------|-------------|-------------|-----|-----------------|
| Auto-Sentry | 80g | 230g | 530g | 4.0 | 0.05 DPS/g |
| Arrow Tower (Typing) | 50g | 130g | 280g | 10.0 | 0.20 DPS/g |
| Auto-Spark | 100g | 280g | 630g | 4.5 | 0.045 DPS/g |
| Magic Tower (Typing) | 60g | 150g | 320g | 12.0 | 0.20 DPS/g |
| Auto-Thorns | 60g | 180g | 520g | 3.0* | 0.05 DPS/g |
| Auto-Flame | 140g | 320g | - | 12.0 | 0.086 DPS/g |

*Thorns damage is contact-based, effective DPS varies by enemy path

### Resource Generation

```json
{
  "auto_tower_economy": {
    "gold_generation": {
      "enabled": false,
      "rationale": "Auto-towers should not generate gold to prevent passive income loops"
    },
    "resource_drops": {
      "scrap_metal": {
        "drop_chance": 10,
        "from": "mechanical_enemies",
        "amount": "1-3"
      },
      "fuel_cells": {
        "drop_chance": 5,
        "from": "fire_enemies",
        "amount": "1"
      }
    },
    "salvage_system": {
      "enabled": true,
      "return_rate": 50,
      "returns": "gold_and_materials"
    }
  }
}
```

---

## Visual and Audio Design

### Visual Indicators

```json
{
  "visual_design": {
    "idle_state": {
      "description": "Slow rotation, scanning animation",
      "indicator": "Green status light"
    },
    "targeting_state": {
      "description": "Locks onto enemy, tracking animation",
      "indicator": "Yellow status light, laser sight (optional)"
    },
    "firing_state": {
      "description": "Muzzle flash, recoil animation",
      "indicator": "Orange status light during fire"
    },
    "overheat_state": {
      "description": "Steam, red glow, smoke particles",
      "indicator": "Red pulsing status light"
    },
    "disabled_state": {
      "description": "Dim colors, drooped posture",
      "indicator": "No status light"
    },
    "synergy_active": {
      "description": "Energy link visual between synergized towers",
      "indicator": "Blue connection line"
    }
  }
}
```

### Audio Cues

```json
{
  "audio_design": {
    "sentry_sounds": {
      "idle": "mechanical_hum_loop",
      "fire": "crossbow_twang",
      "overheat": "steam_hiss"
    },
    "spark_sounds": {
      "idle": "electric_crackle_loop",
      "fire": "lightning_zap",
      "chain": "electric_arc"
    },
    "flame_sounds": {
      "idle": "pilot_light_loop",
      "fire": "flamethrower_whoosh",
      "empty": "gas_sputter"
    },
    "fortress_sounds": {
      "idle": "tree_creak_loop",
      "attack": "wood_slam",
      "damaged": "tree_groan"
    },
    "synergy_activation": "power_up_chime"
  }
}
```

---

## Implementation Priority

### Phase 1 - Core System
1. Basic Sentry Turret implementation
2. Targeting system with nearest/furthest modes
3. Overheat mechanic
4. Basic upgrade path to Ballista

### Phase 2 - Variety
1. Spark Coil and Tesla Array
2. Thorn Barrier and Bramble Maze
3. Chain lightning mechanic
4. Zone damage mechanic

### Phase 3 - Advanced Features
1. Flame Jet and Inferno Engine
2. Fuel system
3. Tier 3 towers
4. Synergy system (internal)

### Phase 4 - Integration
1. Typing trigger bonuses
2. Cross-synergies with typing towers
3. Special typing commands
4. Advanced AI behaviors

### Phase 5 - Endgame
1. Tier 4 legendary towers
2. Power grid system
3. Strategic AI
4. Full economy balance pass

---

## Testing Scenarios

```json
{
  "test_scenarios": [
    {
      "name": "Solo Auto Tower Defense",
      "description": "Complete wave using only auto-towers",
      "expected_result": "Possible but difficult, high resource cost",
      "balance_check": "Should require 150%+ gold compared to typing approach"
    },
    {
      "name": "Hybrid Defense Efficiency",
      "description": "Optimal mix of typing and auto towers",
      "expected_result": "75-80% typing, 20-25% auto for best efficiency",
      "balance_check": "Auto-towers should complement, not replace typing"
    },
    {
      "name": "Synergy Activation",
      "description": "Test all synergy combinations",
      "expected_result": "Visual indicators appear, bonuses apply correctly",
      "balance_check": "Synergies should be meaningful but not mandatory"
    },
    {
      "name": "Resource Stress Test",
      "description": "Maximum auto-tower build",
      "expected_result": "Hit efficiency cap, damage cap kicks in",
      "balance_check": "Player incentivized to diversify"
    },
    {
      "name": "Typing Bonus Cascade",
      "description": "High-speed typing while auto-towers fire",
      "expected_result": "Satisfying combo of personal skill + automation",
      "balance_check": "Combined output should feel powerful but earned"
    }
  ]
}
```

---

## Appendix: Quick Reference

### Auto-Tower Summary Table

| Tower | Tier | Type | Key Feature | Best Against |
|-------|------|------|-------------|--------------|
| Sentry Turret | 1 | Physical | Reliable single-target | Standard enemies |
| Spark Coil | 1 | Electric | AoE pulse | Swarms |
| Thorn Barrier | 1 | Nature | Contact damage + slow | Melee enemies |
| Flame Jet | 2 | Fire | Cone AoE + burn | Groups |
| Ballista | 2 | Physical | High damage + pierce | Armored |
| Tesla Array | 2 | Electric | Chain lightning | Clusters |
| Bramble Maze | 2 | Nature | Zone control | Path coverage |
| Siege Cannon | 3 | Physical | Explosive AoE | Everything |
| Storm Spire | 3 | Electric | Lightning storms | Large groups |
| Living Fortress | 3 | Nature | Tank + path block | Boss support |
| Inferno Engine | 3 | Fire | Ramping beam | Single targets |
| Arcane Sentinel | 4 | Magic | Adaptive + smart AI | All enemy types |
| Doom Fortress | 4 | Multi | Multi-weapon platform | Everything |

---

*End of Auto-Defense Tower System Document*
