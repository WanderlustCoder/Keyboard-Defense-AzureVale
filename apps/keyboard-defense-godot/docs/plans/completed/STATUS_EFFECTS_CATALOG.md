# Status Effects & Buffs Catalog

**Last updated:** 2026-01-08

This document contains all status effects, buffs, debuffs, and conditions in Keyboard Defense.

---

## Table of Contents

1. [System Overview](#system-overview)
2. [Enemy Debuffs](#enemy-debuffs)
3. [Player Debuffs](#player-debuffs)
4. [Player Buffs](#player-buffs)
5. [Tower Buffs](#tower-buffs)
6. [Environmental Effects](#environmental-effects)
7. [Boss-Specific Effects](#boss-specific-effects)

---

## System Overview

### Effect Data Structure

```json
{
  "effect_id": "string",
  "name": "Display Name",
  "category": "buff | debuff | neutral",
  "target": "player | enemy | tower | castle | environment",

  "duration": {
    "type": "timed | permanent | stacking | triggered",
    "base_duration": 0.0,
    "max_stacks": 0
  },

  "mechanics": {
    "stat_modifiers": {},
    "special_effects": [],
    "tick_damage": 0,
    "tick_interval": 0.0
  },

  "visual": {
    "icon": "icon_path",
    "particle": "particle_id",
    "tint": "#FFFFFF"
  },

  "audio": {
    "apply": "sfx_id",
    "tick": "sfx_id",
    "expire": "sfx_id"
  },

  "interactions": {
    "can_be_cleansed": true,
    "can_be_dispelled": true,
    "stacks_with": [],
    "conflicts_with": []
  }
}
```

### Effect Categories

| Category | Target | Purpose |
|----------|--------|---------|
| Debuff | Enemy | Slow, damage, weaken enemies |
| Debuff | Player | Hinder player performance |
| Buff | Player | Enhance player stats |
| Buff | Tower | Improve tower performance |
| Neutral | Environment | Area-wide effects |

---

## Enemy Debuffs

### Movement Effects

```json
{
  "effects": [
    {
      "effect_id": "slow",
      "name": "Slowed",
      "description": "Movement speed reduced",
      "category": "debuff",
      "target": "enemy",
      "tiers": [
        {"tier": 1, "slow_percent": 15, "duration": 2.0},
        {"tier": 2, "slow_percent": 25, "duration": 3.0},
        {"tier": 3, "slow_percent": 40, "duration": 4.0},
        {"tier": 4, "slow_percent": 60, "duration": 5.0}
      ],
      "visual": {
        "icon": "icon_slow.png",
        "particle": "frost_particles",
        "tint": "#87CEEB"
      },
      "sources": ["tower_frost", "skill_frost_nova", "item_frost_staff"],
      "can_stack": true,
      "max_slow": 80
    },
    {
      "effect_id": "frozen",
      "name": "Frozen",
      "description": "Completely immobilized",
      "category": "debuff",
      "target": "enemy",
      "duration": {
        "base": 1.5,
        "scaling": "diminishing"
      },
      "mechanics": {
        "immobilize": true,
        "damage_vulnerability": 1.5
      },
      "visual": {
        "icon": "icon_frozen.png",
        "particle": "ice_encase",
        "tint": "#00BFFF"
      },
      "sources": ["tower_frost_freeze", "skill_deep_freeze"],
      "immunity_duration": 5.0
    },
    {
      "effect_id": "rooted",
      "name": "Rooted",
      "description": "Held in place by roots",
      "category": "debuff",
      "target": "enemy",
      "duration": {"base": 2.0},
      "mechanics": {
        "immobilize": true,
        "can_still_attack": true
      },
      "visual": {
        "icon": "icon_rooted.png",
        "particle": "root_tendrils",
        "tint": "#228B22"
      },
      "sources": ["boss_grove_guardian", "trap_root", "skill_entangle"]
    }
  ]
}
```

### Damage Over Time

```json
{
  "effects": [
    {
      "effect_id": "burning",
      "name": "Burning",
      "description": "Taking fire damage over time",
      "category": "debuff",
      "target": "enemy",
      "duration": {"base": 5.0, "max_stacks": 5},
      "mechanics": {
        "tick_damage": 3,
        "tick_interval": 1.0,
        "damage_type": "fire"
      },
      "visual": {
        "icon": "icon_burning.png",
        "particle": "fire_overlay",
        "tint": "#FF4500"
      },
      "sources": ["tower_cannon_napalm", "skill_ignite"],
      "interactions": {
        "amplified_by": ["oil_covered"],
        "removed_by": ["frozen", "wet"]
      }
    },
    {
      "effect_id": "poisoned",
      "name": "Poisoned",
      "description": "Taking poison damage over time",
      "category": "debuff",
      "target": "enemy",
      "duration": {"base": 8.0, "max_stacks": 10},
      "mechanics": {
        "tick_damage": 2,
        "tick_interval": 1.0,
        "damage_type": "poison",
        "healing_reduction": 0.5
      },
      "visual": {
        "icon": "icon_poisoned.png",
        "particle": "poison_bubbles",
        "tint": "#9932CC"
      },
      "sources": ["tower_poison", "enemy_venom_crawler"],
      "can_stack": true,
      "stack_behavior": "damage_increase"
    },
    {
      "effect_id": "bleeding",
      "name": "Bleeding",
      "description": "Losing health from wounds",
      "category": "debuff",
      "target": "enemy",
      "duration": {"base": 6.0, "max_stacks": 3},
      "mechanics": {
        "tick_damage": 4,
        "tick_interval": 2.0,
        "damage_type": "physical",
        "movement_refreshes": true
      },
      "visual": {
        "icon": "icon_bleeding.png",
        "particle": "blood_drip",
        "tint": "#8B0000"
      },
      "sources": ["tower_arrow_piercing", "skill_lacerate"]
    },
    {
      "effect_id": "corrupting",
      "name": "Corrupting",
      "description": "Being unmade by corruption",
      "category": "debuff",
      "target": "enemy",
      "duration": {"base": 10.0},
      "mechanics": {
        "tick_damage": 5,
        "tick_interval": 1.0,
        "damage_type": "corruption",
        "reduces_max_hp": true,
        "hp_reduction_per_tick": 0.02
      },
      "visual": {
        "icon": "icon_corrupting.png",
        "particle": "corruption_spread",
        "tint": "#4B0082"
      },
      "sources": ["tower_legendary_purifier", "friendly_fire_corrupted"]
    }
  ]
}
```

### Defensive Reduction

```json
{
  "effects": [
    {
      "effect_id": "armor_broken",
      "name": "Armor Broken",
      "description": "Armor reduced significantly",
      "category": "debuff",
      "target": "enemy",
      "duration": {"base": 8.0},
      "mechanics": {
        "armor_reduction_percent": 50
      },
      "visual": {
        "icon": "icon_armor_broken.png",
        "particle": "armor_crack",
        "tint": "#808080"
      },
      "sources": ["skill_sunder_armor", "tower_siege"]
    },
    {
      "effect_id": "exposed",
      "name": "Exposed",
      "description": "Taking increased damage from all sources",
      "category": "debuff",
      "target": "enemy",
      "duration": {"base": 5.0},
      "mechanics": {
        "damage_taken_increase": 0.25
      },
      "visual": {
        "icon": "icon_exposed.png",
        "particle": "vulnerability_glow",
        "tint": "#FF69B4"
      },
      "sources": ["synergy_death_zone", "skill_mark_target"]
    },
    {
      "effect_id": "weakened",
      "name": "Weakened",
      "description": "Dealing reduced damage",
      "category": "debuff",
      "target": "enemy",
      "duration": {"base": 6.0},
      "mechanics": {
        "damage_dealt_reduction": 0.30
      },
      "visual": {
        "icon": "icon_weakened.png",
        "particle": "weakness_spiral",
        "tint": "#D3D3D3"
      },
      "sources": ["tower_holy", "skill_enfeeble"]
    }
  ]
}
```

### Special Enemy Debuffs

```json
{
  "effects": [
    {
      "effect_id": "purifying",
      "name": "Purifying",
      "description": "Corruption being cleansed",
      "category": "debuff",
      "target": "enemy",
      "duration": {"type": "channeled", "base": 3.0},
      "mechanics": {
        "remove_affix_on_complete": true,
        "bonus_damage_to_corrupted": 1.5,
        "interrupt_on_damage_taken": true
      },
      "visual": {
        "icon": "icon_purifying.png",
        "particle": "holy_light",
        "tint": "#FFD700"
      },
      "sources": ["tower_holy", "tower_legendary_purifier", "skill_purify"]
    },
    {
      "effect_id": "marked",
      "name": "Marked",
      "description": "Targeted for priority attack",
      "category": "debuff",
      "target": "enemy",
      "duration": {"base": 10.0},
      "mechanics": {
        "all_towers_prioritize": true,
        "critical_chance_against": 0.25
      },
      "visual": {
        "icon": "icon_marked.png",
        "particle": "target_reticle",
        "tint": "#FF0000"
      },
      "sources": ["skill_mark_for_death", "item_targeting_scope"]
    },
    {
      "effect_id": "taunted",
      "name": "Taunted",
      "description": "Forced to attack a specific target",
      "category": "debuff",
      "target": "enemy",
      "duration": {"base": 4.0},
      "mechanics": {
        "forced_target": "taunt_source",
        "ignore_pathfinding": true
      },
      "visual": {
        "icon": "icon_taunted.png",
        "particle": "anger_symbols",
        "tint": "#DC143C"
      },
      "sources": ["summon_grammar_golem", "skill_taunt"]
    },
    {
      "effect_id": "confused",
      "name": "Confused",
      "description": "Moving erratically",
      "category": "debuff",
      "target": "enemy",
      "duration": {"base": 3.0},
      "mechanics": {
        "random_direction_change_interval": 0.5,
        "attack_allies_chance": 0.15
      },
      "visual": {
        "icon": "icon_confused.png",
        "particle": "question_marks",
        "tint": "#FFFF00"
      },
      "sources": ["tower_magic_drain", "skill_confuse"]
    }
  ]
}
```

---

## Player Debuffs

### Typing Impairments

```json
{
  "effects": [
    {
      "effect_id": "word_scramble",
      "name": "Scrambled",
      "description": "Words appear scrambled",
      "category": "debuff",
      "target": "player",
      "duration": {"base": 5.0},
      "mechanics": {
        "scramble_displayed_words": true,
        "correct_word_unchanged": true
      },
      "visual": {
        "icon": "icon_scrambled.png",
        "screen_effect": "text_glitch"
      },
      "sources": ["enemy_word_scrambler", "boss_mist_wraith"],
      "can_be_cleansed": true
    },
    {
      "effect_id": "vision_blur",
      "name": "Blurred Vision",
      "description": "Screen is blurred, words hard to read",
      "category": "debuff",
      "target": "player",
      "duration": {"base": 4.0},
      "mechanics": {
        "blur_intensity": 0.5
      },
      "visual": {
        "icon": "icon_blurred.png",
        "screen_effect": "blur_filter"
      },
      "sources": ["boss_codex_aberration", "environmental_fog"],
      "can_be_cleansed": true
    },
    {
      "effect_id": "input_lag",
      "name": "Lag Spike",
      "description": "Input delay increased",
      "category": "debuff",
      "target": "player",
      "duration": {"base": 3.0},
      "mechanics": {
        "input_delay_ms": 150
      },
      "visual": {
        "icon": "icon_lag.png",
        "screen_effect": "stutter"
      },
      "sources": ["enemy_glitch_runner", "boss_codex_aberration"],
      "can_be_cleansed": true
    },
    {
      "effect_id": "key_disabled",
      "name": "Key Locked",
      "description": "A keyboard key is temporarily disabled",
      "category": "debuff",
      "target": "player",
      "duration": {"base": 8.0},
      "mechanics": {
        "disabled_key": "random_common",
        "words_with_key_unavailable": true
      },
      "visual": {
        "icon": "icon_key_locked.png",
        "keyboard_highlight": "disabled_key"
      },
      "sources": ["boss_first_typo", "affix_key_lock"],
      "can_be_cleansed": true,
      "cleanse_difficulty": "hard"
    },
    {
      "effect_id": "accuracy_penalty",
      "name": "Shaking",
      "description": "Accuracy reduced due to shaking",
      "category": "debuff",
      "target": "player",
      "duration": {"base": 6.0},
      "mechanics": {
        "accuracy_reduction": 0.10,
        "random_typo_chance": 0.05
      },
      "visual": {
        "icon": "icon_shaking.png",
        "screen_effect": "screen_shake_subtle"
      },
      "sources": ["boss_stone_colossus", "environmental_earthquake"]
    }
  ]
}
```

### Combat Debuffs

```json
{
  "effects": [
    {
      "effect_id": "vulnerable",
      "name": "Vulnerable",
      "description": "Castle takes increased damage",
      "category": "debuff",
      "target": "player",
      "duration": {"base": 10.0},
      "mechanics": {
        "castle_damage_increase": 0.50
      },
      "visual": {
        "icon": "icon_vulnerable.png",
        "castle_effect": "red_glow"
      },
      "sources": ["affix_breacher", "boss_phase_ability"]
    },
    {
      "effect_id": "tower_disabled",
      "name": "EMP",
      "description": "Towers temporarily disabled",
      "category": "debuff",
      "target": "player",
      "duration": {"base": 5.0},
      "mechanics": {
        "towers_cannot_attack": true,
        "affected_range": "aoe"
      },
      "visual": {
        "icon": "icon_emp.png",
        "tower_effect": "sparks"
      },
      "sources": ["enemy_static_horror", "boss_stone_colossus"]
    },
    {
      "effect_id": "gold_drain",
      "name": "Gold Drain",
      "description": "Losing gold over time",
      "category": "debuff",
      "target": "player",
      "duration": {"base": 15.0},
      "mechanics": {
        "gold_lost_per_second": 2,
        "minimum_gold": 0
      },
      "visual": {
        "icon": "icon_gold_drain.png",
        "screen_effect": "gold_particles_away"
      },
      "sources": ["enemy_gold_thief", "crimson_quill_encounter"]
    },
    {
      "effect_id": "corruption_spreading",
      "name": "Corruption Surge",
      "description": "Corruption level increasing rapidly",
      "category": "debuff",
      "target": "player",
      "duration": {"type": "triggered"},
      "mechanics": {
        "corruption_increase_per_second": 0.5
      },
      "visual": {
        "icon": "icon_corruption_surge.png",
        "screen_effect": "corruption_vignette"
      },
      "sources": ["wave_corruption_surge", "boss_first_typo"]
    }
  ]
}
```

---

## Player Buffs

### Typing Enhancements

```json
{
  "effects": [
    {
      "effect_id": "typing_speed_boost",
      "name": "Quick Fingers",
      "description": "Typing speed increased",
      "category": "buff",
      "target": "player",
      "tiers": [
        {"tier": 1, "wpm_bonus": 5, "duration": 30.0},
        {"tier": 2, "wpm_bonus": 10, "duration": 30.0},
        {"tier": 3, "wpm_bonus": 20, "duration": 30.0}
      ],
      "visual": {
        "icon": "icon_quick_fingers.png",
        "particle": "speed_lines"
      },
      "sources": ["potion_speed", "inn_rest", "skill_burst_typing"]
    },
    {
      "effect_id": "accuracy_boost",
      "name": "Precision",
      "description": "Accuracy bonus to damage calculations",
      "category": "buff",
      "target": "player",
      "tiers": [
        {"tier": 1, "accuracy_bonus": 0.05, "duration": 30.0},
        {"tier": 2, "accuracy_bonus": 0.10, "duration": 30.0},
        {"tier": 3, "accuracy_bonus": 0.15, "duration": 30.0}
      ],
      "visual": {
        "icon": "icon_precision.png",
        "particle": "targeting_reticle"
      },
      "sources": ["potion_accuracy", "skill_focus", "equipment_set_precision"]
    },
    {
      "effect_id": "combo_extend",
      "name": "Combo Extension",
      "description": "Combo window extended",
      "category": "buff",
      "target": "player",
      "duration": {"base": 60.0},
      "mechanics": {
        "combo_window_extension": 1.0
      },
      "visual": {
        "icon": "icon_combo_extend.png"
      },
      "sources": ["skill_chain_killer", "item_combo_ring"]
    },
    {
      "effect_id": "typo_forgiveness",
      "name": "Second Chance",
      "description": "First typo per word is ignored",
      "category": "buff",
      "target": "player",
      "duration": {"type": "charges", "charges": 5},
      "mechanics": {
        "ignore_first_typo_per_word": true
      },
      "visual": {
        "icon": "icon_second_chance.png"
      },
      "sources": ["potion_forgiveness", "skill_backup_plan"]
    }
  ]
}
```

### Combat Buffs

```json
{
  "effects": [
    {
      "effect_id": "damage_boost",
      "name": "Empowered",
      "description": "All damage increased",
      "category": "buff",
      "target": "player",
      "tiers": [
        {"tier": 1, "damage_percent": 15, "duration": 20.0},
        {"tier": 2, "damage_percent": 30, "duration": 20.0},
        {"tier": 3, "damage_percent": 50, "duration": 20.0}
      ],
      "visual": {
        "icon": "icon_empowered.png",
        "particle": "power_aura"
      },
      "sources": ["potion_damage", "skill_rage", "equipment_set_assault"]
    },
    {
      "effect_id": "critical_boost",
      "name": "Lucky Strike",
      "description": "Critical hit chance increased",
      "category": "buff",
      "target": "player",
      "duration": {"base": 30.0},
      "mechanics": {
        "crit_chance_bonus": 0.15,
        "crit_damage_bonus": 0.25
      },
      "visual": {
        "icon": "icon_lucky_strike.png",
        "particle": "stars"
      },
      "sources": ["potion_luck", "skill_deadly_precision"]
    },
    {
      "effect_id": "gold_find",
      "name": "Gold Rush",
      "description": "Increased gold from enemies",
      "category": "buff",
      "target": "player",
      "duration": {"base": 60.0},
      "mechanics": {
        "gold_bonus_percent": 50
      },
      "visual": {
        "icon": "icon_gold_rush.png",
        "particle": "gold_sparkles"
      },
      "sources": ["potion_wealth", "event_treasure_wave"]
    },
    {
      "effect_id": "xp_boost",
      "name": "Enlightened",
      "description": "Increased XP gain",
      "category": "buff",
      "target": "player",
      "duration": {"base": 300.0},
      "mechanics": {
        "xp_bonus_percent": 25
      },
      "visual": {
        "icon": "icon_enlightened.png",
        "particle": "wisdom_glow"
      },
      "sources": ["potion_wisdom", "inn_study", "equipment_scholars_robe"]
    },
    {
      "effect_id": "shield",
      "name": "Shielded",
      "description": "Absorbs incoming castle damage",
      "category": "buff",
      "target": "player",
      "duration": {"type": "until_depleted"},
      "mechanics": {
        "absorb_amount": 50,
        "max_absorb_per_hit": 20
      },
      "visual": {
        "icon": "icon_shielded.png",
        "castle_effect": "barrier_glow"
      },
      "sources": ["skill_barrier", "scroll_protection", "tower_support_aura"]
    },
    {
      "effect_id": "rested",
      "name": "Well Rested",
      "description": "All stats slightly improved",
      "category": "buff",
      "target": "player",
      "duration": {"base": 600.0},
      "mechanics": {
        "all_stats_bonus": 0.05,
        "stamina_regen_bonus": 0.20
      },
      "visual": {
        "icon": "icon_rested.png"
      },
      "sources": ["inn_rest"]
    }
  ]
}
```

### Letter Spirit Blessings

```json
{
  "effects": [
    {
      "effect_id": "blessing_alpha",
      "name": "Alpha's Strength",
      "description": "First word of each wave deals triple damage",
      "category": "buff",
      "target": "player",
      "duration": {"type": "permanent_passive"},
      "mechanics": {
        "first_word_damage_multiplier": 3.0
      },
      "visual": {
        "icon": "icon_blessing_alpha.png",
        "particle": "alpha_symbol"
      },
      "sources": ["shrine_alpha", "quest_alpha_blessing"]
    },
    {
      "effect_id": "blessing_omega",
      "name": "Omega's Finality",
      "description": "Last enemy of each wave drops bonus loot",
      "category": "buff",
      "target": "player",
      "duration": {"type": "permanent_passive"},
      "mechanics": {
        "last_enemy_bonus_loot": true,
        "loot_quality_bonus": 0.25
      },
      "visual": {
        "icon": "icon_blessing_omega.png",
        "particle": "omega_symbol"
      },
      "sources": ["shrine_omega", "quest_omega_blessing"]
    },
    {
      "effect_id": "blessing_epsilon",
      "name": "Epsilon's Connection",
      "description": "Combo counter decays 50% slower",
      "category": "buff",
      "target": "player",
      "duration": {"type": "permanent_passive"},
      "mechanics": {
        "combo_decay_reduction": 0.50
      },
      "visual": {
        "icon": "icon_blessing_epsilon.png"
      },
      "sources": ["shrine_epsilon"]
    }
  ]
}
```

---

## Tower Buffs

### Support Tower Auras

```json
{
  "effects": [
    {
      "effect_id": "tower_damage_aura",
      "name": "Command Aura - Damage",
      "description": "Nearby towers deal increased damage",
      "category": "buff",
      "target": "tower",
      "duration": {"type": "aura"},
      "mechanics": {
        "damage_bonus_percent": 15,
        "range": 3
      },
      "visual": {
        "aura_ring": "red_glow"
      },
      "sources": ["tower_support"]
    },
    {
      "effect_id": "tower_speed_aura",
      "name": "Command Aura - Speed",
      "description": "Nearby towers attack faster",
      "category": "buff",
      "target": "tower",
      "duration": {"type": "aura"},
      "mechanics": {
        "attack_speed_bonus_percent": 10,
        "range": 3
      },
      "visual": {
        "aura_ring": "yellow_glow"
      },
      "sources": ["tower_support"]
    },
    {
      "effect_id": "tower_range_aura",
      "name": "Command Aura - Range",
      "description": "Nearby towers have extended range",
      "category": "buff",
      "target": "tower",
      "duration": {"type": "aura"},
      "mechanics": {
        "range_bonus": 1,
        "range": 3
      },
      "visual": {
        "aura_ring": "blue_glow"
      },
      "sources": ["tower_support_upgraded"]
    }
  ]
}
```

### Synergy Effects

```json
{
  "effects": [
    {
      "effect_id": "synergy_fire_ice",
      "name": "Elemental Mastery",
      "description": "Fire and ice towers empower each other",
      "category": "buff",
      "target": "tower",
      "duration": {"type": "synergy"},
      "mechanics": {
        "frozen_fire_damage_multiplier": 3.0,
        "burning_ice_damage_multiplier": 3.0
      },
      "visual": {
        "synergy_beam": "fire_ice_link"
      },
      "sources": ["synergy_fire_and_ice"]
    },
    {
      "effect_id": "synergy_chain",
      "name": "Chain Amplification",
      "description": "Chain attacks have no damage falloff",
      "category": "buff",
      "target": "tower",
      "duration": {"type": "synergy"},
      "mechanics": {
        "chain_falloff": 0,
        "chain_bonus": 3
      },
      "visual": {
        "synergy_beam": "lightning_link"
      },
      "sources": ["synergy_chain_reaction"]
    }
  ]
}
```

---

## Environmental Effects

### Weather Effects

```json
{
  "effects": [
    {
      "effect_id": "rain",
      "name": "Rain",
      "description": "Light rain affects the battlefield",
      "category": "neutral",
      "target": "environment",
      "mechanics": {
        "fire_damage_reduction": 0.20,
        "electric_damage_bonus": 0.15,
        "visibility_reduction": 0.10
      },
      "visual": {
        "weather_particle": "rain",
        "ambient_change": "darker"
      }
    },
    {
      "effect_id": "storm",
      "name": "Storm",
      "description": "Heavy storm with lightning",
      "category": "neutral",
      "target": "environment",
      "mechanics": {
        "fire_damage_reduction": 0.40,
        "electric_damage_bonus": 0.30,
        "random_lightning_strikes": true,
        "lightning_damage": 20,
        "visibility_reduction": 0.25
      },
      "visual": {
        "weather_particle": "storm",
        "ambient_change": "very_dark",
        "lightning_flashes": true
      }
    },
    {
      "effect_id": "fog",
      "name": "Dense Fog",
      "description": "Thick fog reduces visibility",
      "category": "neutral",
      "target": "environment",
      "mechanics": {
        "visibility_reduction": 0.50,
        "tower_range_reduction": 1
      },
      "visual": {
        "weather_particle": "fog",
        "ambient_change": "gray"
      }
    },
    {
      "effect_id": "clear",
      "name": "Clear Skies",
      "description": "Perfect conditions",
      "category": "neutral",
      "target": "environment",
      "mechanics": {
        "accuracy_bonus": 0.05,
        "all_damage_bonus": 0.05
      },
      "visual": {
        "weather_particle": null,
        "ambient_change": "bright"
      }
    }
  ]
}
```

### Terrain Effects

```json
{
  "effects": [
    {
      "effect_id": "sacred_ground",
      "name": "Sacred Ground",
      "description": "Holy terrain empowers defenders",
      "category": "buff",
      "target": "environment",
      "mechanics": {
        "holy_damage_bonus": 0.25,
        "corruption_damage_to_enemies": true,
        "healing_bonus": 0.20
      },
      "visual": {
        "ground_glow": "golden"
      }
    },
    {
      "effect_id": "corrupted_ground",
      "name": "Corrupted Ground",
      "description": "Corrupted terrain hinders defenders",
      "category": "debuff",
      "target": "environment",
      "mechanics": {
        "accuracy_penalty": 0.10,
        "enemy_speed_bonus": 0.15,
        "corruption_damage_to_towers": 1
      },
      "visual": {
        "ground_effect": "corruption_tendrils"
      }
    },
    {
      "effect_id": "swamp_ground",
      "name": "Swamp",
      "description": "Swampy terrain slows movement",
      "category": "neutral",
      "target": "environment",
      "mechanics": {
        "movement_slow": 0.25,
        "poison_towers_enhanced": true
      },
      "visual": {
        "ground_effect": "mud_bubbles"
      }
    }
  ]
}
```

---

## Boss-Specific Effects

### Grove Guardian Effects

```json
{
  "effects": [
    {
      "effect_id": "guardian_root_network",
      "name": "Root Network Active",
      "description": "Arena is covered in root obstacles",
      "category": "neutral",
      "target": "environment",
      "phase": 2,
      "mechanics": {
        "obstacle_spawn": true,
        "line_of_sight_blocked": true
      }
    },
    {
      "effect_id": "guardian_corruption_wave",
      "name": "Corruption Spreading",
      "description": "Corruption wave expanding",
      "category": "debuff",
      "target": "player",
      "phase": 3,
      "mechanics": {
        "damage_zone_expanding": true,
        "must_type_purify": true
      }
    }
  ]
}
```

### Mist Wraith Effects

```json
{
  "effects": [
    {
      "effect_id": "wraith_whispers",
      "name": "Whispers of Madness",
      "description": "Words appear scrambled",
      "category": "debuff",
      "target": "player",
      "phase": 1,
      "mechanics": {
        "letter_substitution_chance": 0.15
      }
    },
    {
      "effect_id": "wraith_word_theft",
      "name": "Lexical Drain",
      "description": "Some words stolen from your vocabulary",
      "category": "debuff",
      "target": "player",
      "phase": 2,
      "mechanics": {
        "words_removed": 3,
        "duration": 60.0
      }
    },
    {
      "effect_id": "wraith_reality_flux",
      "name": "Reality Flux",
      "description": "Words may change mid-typing",
      "category": "debuff",
      "target": "player",
      "phase": 3,
      "mechanics": {
        "word_change_chance": 0.10,
        "change_interval": 2.0
      }
    }
  ]
}
```

---

## Implementation

```gdscript
class_name StatusEffect
extends Resource

@export var effect_id: String
@export var name: String
@export var duration: float
@export var max_stacks: int = 1
@export var tick_interval: float = 0.0

var current_stacks: int = 1
var remaining_duration: float
var tick_timer: float = 0.0

func _init(data: Dictionary) -> void:
    effect_id = data.effect_id
    name = data.name
    duration = data.duration.base
    remaining_duration = duration
    max_stacks = data.duration.get("max_stacks", 1)

func tick(delta: float) -> bool:
    remaining_duration -= delta

    if tick_interval > 0:
        tick_timer += delta
        if tick_timer >= tick_interval:
            tick_timer -= tick_interval
            apply_tick_effect()

    return remaining_duration <= 0

func add_stack() -> void:
    if current_stacks < max_stacks:
        current_stacks += 1
        remaining_duration = duration  # Refresh duration

func apply_tick_effect() -> void:
    # Override in subclasses
    pass
```

---

**Document version:** 1.0
**Total effects documented:** 75+
**Categories:** 7
