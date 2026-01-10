# Complete Skill Tree Specification

**Created:** 2026-01-08

Full details for all skill trees, abilities, and synergies.

---

## Skill System Overview

### Point Acquisition

| Source | Points | Frequency |
|--------|--------|-----------|
| Level up (every 5 levels) | 1 | Levels 5, 10, 15... |
| Mastery badge | 1 | Per badge earned |
| Quest completion (major) | 1 | Story milestones |
| Achievement | 1 | Select achievements |

### Respec Rules

- Cost: 100 gold per skill point to reset
- Full tree reset available for 500 gold
- First respec free (tutorial)

---

## Speed Tree - Way of the Swift

*"Speed is survival. The fastest fingers win."*

### Tier 1 (1 point each)

```json
{
  "tier": 1,
  "skills": [
    {
      "id": "swift_start",
      "name": "Quick Start",
      "icon": "speed_lightning",
      "max_ranks": 5,
      "cost_per_rank": 1,
      "effect_per_rank": "+1 WPM",
      "total_at_max": "+5 WPM",
      "description": "Your fingers are ready from the first keystroke.",
      "prerequisites": []
    },
    {
      "id": "momentum",
      "name": "Momentum",
      "icon": "speed_wave",
      "max_ranks": 5,
      "cost_per_rank": 1,
      "effect_per_rank": "Combo grants +0.5% speed",
      "total_at_max": "Combo grants +2.5% speed",
      "description": "Build speed as your combo grows.",
      "prerequisites": []
    },
    {
      "id": "rapid_recovery",
      "name": "Rapid Recovery",
      "icon": "speed_rewind",
      "max_ranks": 3,
      "cost_per_rank": 1,
      "effect_per_rank": "-0.3s to regain full speed after mistake",
      "total_at_max": "-0.9s recovery time",
      "description": "Quickly recover your rhythm after errors.",
      "prerequisites": []
    }
  ]
}
```

### Tier 2 (2 points each, requires 3 tier 1)

```json
{
  "tier": 2,
  "skills": [
    {
      "id": "burst_typing",
      "name": "Burst Typing",
      "icon": "speed_burst",
      "max_ranks": 3,
      "cost_per_rank": 2,
      "effect_per_rank": "First 2 words per wave typed +15% faster",
      "total_at_max": "First 6 words per wave typed +15% faster",
      "description": "Start each wave with explosive speed.",
      "prerequisites": ["swift_start:2"]
    },
    {
      "id": "chain_killer",
      "name": "Chain Killer",
      "icon": "speed_chain",
      "max_ranks": 3,
      "cost_per_rank": 2,
      "effect_per_rank": "+8% damage for kills within 1.5s of each other",
      "total_at_max": "+24% damage for chain kills",
      "description": "Rapid kills deal escalating damage.",
      "prerequisites": ["momentum:2"]
    },
    {
      "id": "finger_memory",
      "name": "Finger Memory",
      "icon": "speed_memory",
      "max_ranks": 2,
      "cost_per_rank": 2,
      "effect_per_rank": "Repeated words typed +10% faster",
      "total_at_max": "Repeated words typed +20% faster",
      "description": "Your fingers remember frequently typed words.",
      "prerequisites": ["rapid_recovery:1"]
    }
  ]
}
```

### Tier 3 (3 points each, requires 5 tier 1+2)

```json
{
  "tier": 3,
  "skills": [
    {
      "id": "overdrive",
      "name": "Overdrive",
      "icon": "speed_overdrive",
      "max_ranks": 1,
      "cost_per_rank": 3,
      "type": "active",
      "effect": "Double typing speed for 10 seconds",
      "cooldown": 90,
      "description": "Push beyond your limits for a brief moment.",
      "prerequisites": ["burst_typing:2", "chain_killer:2"],
      "activation": "Hotkey or button"
    },
    {
      "id": "adrenaline_rush",
      "name": "Adrenaline Rush",
      "icon": "speed_heart",
      "max_ranks": 2,
      "cost_per_rank": 3,
      "effect_per_rank": "When castle HP < 30%, +15% speed",
      "total_at_max": "+30% speed when low HP",
      "description": "Desperation fuels incredible speed.",
      "prerequisites": ["chain_killer:3"]
    },
    {
      "id": "flow_state_speed",
      "name": "In the Zone",
      "icon": "speed_zen",
      "max_ranks": 2,
      "cost_per_rank": 3,
      "effect_per_rank": "At 15+ combo, maintain +8% base speed",
      "total_at_max": "+16% speed while combo > 15",
      "description": "Enter a flow state of sustained high performance.",
      "prerequisites": ["finger_memory:2", "momentum:3"]
    }
  ]
}
```

### Tier 4 (5 points, requires 8 total)

```json
{
  "tier": 4,
  "skills": [
    {
      "id": "speed_demon",
      "name": "Speed Demon",
      "icon": "speed_demon",
      "max_ranks": 1,
      "cost_per_rank": 5,
      "type": "passive",
      "effect": "+20% WPM permanently, -5% accuracy",
      "description": "Embrace raw speed at the cost of precision.",
      "prerequisites": ["overdrive:1"],
      "warning": "Reduces accuracy - ensure you can handle the tradeoff"
    },
    {
      "id": "lightning_reflexes",
      "name": "Lightning Reflexes",
      "icon": "speed_lightning_master",
      "max_ranks": 1,
      "cost_per_rank": 5,
      "type": "passive",
      "effect": "Words under 4 letters completed instantly on correct first letter (5s cooldown)",
      "cooldown": 5,
      "description": "Short words fall before they're even fully typed.",
      "prerequisites": ["flow_state_speed:2", "adrenaline_rush:2"]
    }
  ]
}
```

---

## Accuracy Tree - Way of Precision

*"One perfect keystroke is worth a hundred hasty ones."*

### Tier 1

```json
{
  "tier": 1,
  "skills": [
    {
      "id": "steady_hands",
      "name": "Steady Hands",
      "icon": "accuracy_hands",
      "max_ranks": 5,
      "cost_per_rank": 1,
      "effect_per_rank": "+1% accuracy",
      "total_at_max": "+5% accuracy",
      "prerequisites": []
    },
    {
      "id": "focus",
      "name": "Focus",
      "icon": "accuracy_focus",
      "max_ranks": 5,
      "cost_per_rank": 1,
      "effect_per_rank": "Mistake penalty reduced 8%",
      "total_at_max": "Mistake penalty reduced 40%",
      "description": "Errors disrupt you less.",
      "prerequisites": []
    },
    {
      "id": "patience",
      "name": "Patience",
      "icon": "accuracy_patience",
      "max_ranks": 3,
      "cost_per_rank": 1,
      "effect_per_rank": "+0.5s grace period before combo breaks",
      "total_at_max": "+1.5s grace period",
      "prerequisites": []
    }
  ]
}
```

### Tier 2

```json
{
  "tier": 2,
  "skills": [
    {
      "id": "critical_strike",
      "name": "Critical Strike",
      "icon": "accuracy_crit",
      "max_ranks": 3,
      "cost_per_rank": 2,
      "effect_per_rank": "Perfect words have 10% chance for 2x damage",
      "total_at_max": "30% crit chance on perfect words",
      "prerequisites": ["steady_hands:2"]
    },
    {
      "id": "recovery",
      "name": "Quick Recovery",
      "icon": "accuracy_recovery",
      "max_ranks": 3,
      "cost_per_rank": 2,
      "effect_per_rank": "Mistakes don't break combo (7s cooldown, -2s per rank)",
      "total_at_max": "Mistake immunity every 3s",
      "prerequisites": ["focus:2"]
    },
    {
      "id": "word_sense",
      "name": "Word Sense",
      "icon": "accuracy_sense",
      "max_ranks": 2,
      "cost_per_rank": 2,
      "effect_per_rank": "Highlight next letter more prominently",
      "visual_enhancement": true,
      "prerequisites": ["patience:1"]
    }
  ]
}
```

### Tier 3

```json
{
  "tier": 3,
  "skills": [
    {
      "id": "perfect_form",
      "name": "Perfect Form",
      "icon": "accuracy_perfect",
      "max_ranks": 1,
      "cost_per_rank": 3,
      "type": "active",
      "effect": "100% accuracy for 10s (mistakes don't register)",
      "cooldown": 120,
      "prerequisites": ["critical_strike:2", "recovery:2"]
    },
    {
      "id": "eagle_eye",
      "name": "Eagle Eye",
      "icon": "accuracy_eagle",
      "max_ranks": 2,
      "cost_per_rank": 3,
      "effect_per_rank": "See words 1s earlier per rank",
      "total_at_max": "See words 2s earlier",
      "prerequisites": ["word_sense:2"]
    },
    {
      "id": "measured_strikes",
      "name": "Measured Strikes",
      "icon": "accuracy_measure",
      "max_ranks": 2,
      "cost_per_rank": 3,
      "effect_per_rank": "Perfect words deal +15% damage",
      "total_at_max": "+30% damage on perfect words",
      "prerequisites": ["critical_strike:3"]
    }
  ]
}
```

### Tier 4

```json
{
  "tier": 4,
  "skills": [
    {
      "id": "precision_master",
      "name": "Precision Master",
      "icon": "accuracy_master",
      "max_ranks": 1,
      "cost_per_rank": 5,
      "type": "passive",
      "effect": "Perfect words deal +50% damage and restore 1 combo",
      "prerequisites": ["perfect_form:1", "measured_strikes:2"]
    },
    {
      "id": "flawless_execution",
      "name": "Flawless Execution",
      "icon": "accuracy_flawless",
      "max_ranks": 1,
      "cost_per_rank": 5,
      "type": "passive",
      "effect": "After 5 perfect words in a row, next word is auto-completed",
      "cooldown": 30,
      "prerequisites": ["eagle_eye:2", "precision_master:1"]
    }
  ]
}
```

---

## Defense Tree - Way of the Guardian

*"The castle must stand. You are its last defender."*

### Tier 1

```json
{
  "tier": 1,
  "skills": [
    {
      "id": "thick_walls",
      "name": "Thick Walls",
      "icon": "defense_walls",
      "max_ranks": 5,
      "cost_per_rank": 1,
      "effect_per_rank": "+10 castle max HP",
      "total_at_max": "+50 castle max HP",
      "prerequisites": []
    },
    {
      "id": "regeneration",
      "name": "Regeneration",
      "icon": "defense_regen",
      "max_ranks": 5,
      "cost_per_rank": 1,
      "effect_per_rank": "Restore 1 HP per 45s",
      "total_at_max": "Restore 1 HP per 9s",
      "prerequisites": []
    },
    {
      "id": "stone_skin",
      "name": "Stone Skin",
      "icon": "defense_stone",
      "max_ranks": 3,
      "cost_per_rank": 1,
      "effect_per_rank": "-3% damage taken",
      "total_at_max": "-9% damage taken",
      "prerequisites": []
    }
  ]
}
```

### Tier 2

```json
{
  "tier": 2,
  "skills": [
    {
      "id": "fortification",
      "name": "Fortification",
      "icon": "defense_fort",
      "max_ranks": 3,
      "cost_per_rank": 2,
      "effect_per_rank": "-5% castle damage taken",
      "total_at_max": "-15% castle damage taken",
      "prerequisites": ["thick_walls:2"]
    },
    {
      "id": "last_stand",
      "name": "Last Stand",
      "icon": "defense_laststand",
      "max_ranks": 2,
      "cost_per_rank": 2,
      "effect_per_rank": "At <20% HP, +20% typing damage",
      "total_at_max": "+40% damage when low HP",
      "prerequisites": ["regeneration:2"]
    },
    {
      "id": "armor_plating",
      "name": "Armor Plating",
      "icon": "defense_armor",
      "max_ranks": 2,
      "cost_per_rank": 2,
      "effect_per_rank": "Reduce all damage by 1 (minimum 1)",
      "total_at_max": "Reduce all damage by 2",
      "prerequisites": ["stone_skin:2"]
    }
  ]
}
```

### Tier 3

```json
{
  "tier": 3,
  "skills": [
    {
      "id": "emergency_repair",
      "name": "Emergency Repair",
      "icon": "defense_repair",
      "max_ranks": 1,
      "cost_per_rank": 3,
      "type": "active",
      "effect": "Restore 50% castle HP",
      "limit": "Once per battle",
      "prerequisites": ["fortification:2", "last_stand:1"]
    },
    {
      "id": "shield_wall",
      "name": "Shield Wall",
      "icon": "defense_shield",
      "max_ranks": 1,
      "cost_per_rank": 3,
      "type": "active",
      "effect": "Immune to damage for 8 seconds",
      "cooldown": 180,
      "prerequisites": ["armor_plating:2"]
    },
    {
      "id": "counterattack",
      "name": "Counterattack",
      "icon": "defense_counter",
      "max_ranks": 2,
      "cost_per_rank": 3,
      "effect_per_rank": "When damaged, 15% chance to instantly kill attacker",
      "total_at_max": "30% counterattack chance",
      "prerequisites": ["last_stand:2"]
    }
  ]
}
```

### Tier 4

```json
{
  "tier": 4,
  "skills": [
    {
      "id": "immortal_fortress",
      "name": "Immortal Fortress",
      "icon": "defense_immortal",
      "max_ranks": 1,
      "cost_per_rank": 5,
      "type": "passive",
      "effect": "Castle cannot be destroyed for 5s after reaching 0 HP",
      "description": "A final chance to turn the tide.",
      "prerequisites": ["emergency_repair:1", "shield_wall:1"]
    },
    {
      "id": "retribution",
      "name": "Retribution",
      "icon": "defense_retribution",
      "max_ranks": 1,
      "cost_per_rank": 5,
      "type": "passive",
      "effect": "All enemies take 3 damage when castle is hit",
      "prerequisites": ["counterattack:2", "immortal_fortress:1"]
    }
  ]
}
```

---

## Towers Tree - Way of the Architect

*"A well-placed tower is worth a hundred keystrokes."*

### Tier 1

```json
{
  "tier": 1,
  "skills": [
    {
      "id": "tower_damage",
      "name": "Improved Towers",
      "icon": "tower_damage",
      "max_ranks": 5,
      "cost_per_rank": 1,
      "effect_per_rank": "+4% tower damage",
      "total_at_max": "+20% tower damage",
      "prerequisites": []
    },
    {
      "id": "tower_range",
      "name": "Extended Range",
      "icon": "tower_range",
      "max_ranks": 3,
      "cost_per_rank": 1,
      "effect_per_rank": "+0.3 tower range",
      "total_at_max": "+0.9 tower range",
      "prerequisites": []
    },
    {
      "id": "tower_cost",
      "name": "Efficient Construction",
      "icon": "tower_cost",
      "max_ranks": 3,
      "cost_per_rank": 1,
      "effect_per_rank": "-5% tower build cost",
      "total_at_max": "-15% tower cost",
      "prerequisites": []
    }
  ]
}
```

### Tier 2

```json
{
  "tier": 2,
  "skills": [
    {
      "id": "tower_speed",
      "name": "Rapid Fire",
      "icon": "tower_speed",
      "max_ranks": 3,
      "cost_per_rank": 2,
      "effect_per_rank": "+8% tower attack speed",
      "total_at_max": "+24% attack speed",
      "prerequisites": ["tower_damage:2"]
    },
    {
      "id": "synergy_bonus",
      "name": "Tower Synergy",
      "icon": "tower_synergy",
      "max_ranks": 3,
      "cost_per_rank": 2,
      "effect_per_rank": "Adjacent tower bonuses +30% effective",
      "total_at_max": "+90% synergy bonus",
      "prerequisites": ["tower_range:2"]
    },
    {
      "id": "tower_durability",
      "name": "Reinforced Structures",
      "icon": "tower_durability",
      "max_ranks": 2,
      "cost_per_rank": 2,
      "effect_per_rank": "Towers take 20% less damage",
      "total_at_max": "Towers take 40% less damage",
      "prerequisites": ["tower_cost:2"]
    }
  ]
}
```

### Tier 3

```json
{
  "tier": 3,
  "skills": [
    {
      "id": "supercharge",
      "name": "Supercharge",
      "icon": "tower_supercharge",
      "max_ranks": 1,
      "cost_per_rank": 3,
      "type": "active",
      "effect": "All towers deal 3x damage for 12 seconds",
      "cooldown": 150,
      "prerequisites": ["tower_speed:2", "synergy_bonus:2"]
    },
    {
      "id": "tower_specialization",
      "name": "Specialization",
      "icon": "tower_special",
      "max_ranks": 3,
      "cost_per_rank": 3,
      "effect_per_rank": "Choose a tower type to gain +20% damage",
      "selection": ["arrow", "arcane", "holy", "siege", "multi"],
      "prerequisites": ["tower_speed:3"]
    },
    {
      "id": "mass_production",
      "name": "Mass Production",
      "icon": "tower_mass",
      "max_ranks": 1,
      "cost_per_rank": 3,
      "effect": "Can build 2 additional towers",
      "prerequisites": ["tower_cost:3", "tower_durability:2"]
    }
  ]
}
```

### Tier 4

```json
{
  "tier": 4,
  "skills": [
    {
      "id": "master_architect",
      "name": "Master Architect",
      "icon": "tower_master",
      "max_ranks": 1,
      "cost_per_rank": 5,
      "type": "passive",
      "effect": "All towers start at Tier 2",
      "prerequisites": ["supercharge:1", "mass_production:1"]
    },
    {
      "id": "tower_mastery",
      "name": "Tower Mastery",
      "icon": "tower_ultimate",
      "max_ranks": 1,
      "cost_per_rank": 5,
      "type": "passive",
      "effect": "Towers gain +5% damage for every 10 typing combo",
      "max_bonus": "+50% at 100 combo",
      "prerequisites": ["tower_specialization:3", "master_architect:1"]
    }
  ]
}
```

---

## Utility Tree - Way of Prosperity

*"Fortune favors the prepared mind."*

### Tier 1

```json
{
  "tier": 1,
  "skills": [
    {
      "id": "gold_bonus",
      "name": "Treasure Hunter",
      "icon": "utility_gold",
      "max_ranks": 5,
      "cost_per_rank": 1,
      "effect_per_rank": "+4% gold",
      "total_at_max": "+20% gold",
      "prerequisites": []
    },
    {
      "id": "xp_bonus",
      "name": "Quick Learner",
      "icon": "utility_xp",
      "max_ranks": 5,
      "cost_per_rank": 1,
      "effect_per_rank": "+4% XP",
      "total_at_max": "+20% XP",
      "prerequisites": []
    },
    {
      "id": "item_find",
      "name": "Lucky Find",
      "icon": "utility_luck",
      "max_ranks": 3,
      "cost_per_rank": 1,
      "effect_per_rank": "+3% item drop rate",
      "total_at_max": "+9% item drops",
      "prerequisites": []
    }
  ]
}
```

### Tier 2-4

```json
{
  "tier_2_to_4": [
    {
      "id": "rare_find",
      "tier": 2,
      "name": "Rare Finder",
      "max_ranks": 3,
      "effect": "+8% rare+ item chance per rank",
      "prerequisites": ["item_find:2"]
    },
    {
      "id": "merchant_discount",
      "tier": 2,
      "name": "Haggler",
      "max_ranks": 2,
      "effect": "-8% shop prices per rank",
      "prerequisites": ["gold_bonus:2"]
    },
    {
      "id": "lesson_mastery",
      "tier": 2,
      "name": "Dedicated Student",
      "max_ranks": 2,
      "effect": "+15% lesson completion speed per rank",
      "prerequisites": ["xp_bonus:2"]
    },
    {
      "id": "jackpot",
      "tier": 3,
      "name": "Jackpot",
      "max_ranks": 1,
      "cost": 3,
      "effect": "1% chance for 10x gold on any enemy",
      "prerequisites": ["merchant_discount:2", "rare_find:2"]
    },
    {
      "id": "double_rewards",
      "tier": 4,
      "name": "Double or Nothing",
      "max_ranks": 1,
      "cost": 5,
      "effect": "End-of-battle rewards have 20% chance to double",
      "prerequisites": ["jackpot:1"]
    }
  ]
}
```

---

## Mastery Tree - Way of the True Typist

*"Balance speed and accuracy. Master both, master all."*

### Skills

```json
{
  "mastery_skills": [
    {
      "id": "combo_mastery",
      "tier": 1,
      "name": "Combo Mastery",
      "max_ranks": 5,
      "effect": "Combo bonuses +8% effective per rank"
    },
    {
      "id": "adaptation",
      "tier": 1,
      "name": "Adaptation",
      "max_ranks": 3,
      "effect": "Learn new words +15% faster per rank"
    },
    {
      "id": "flow_state",
      "tier": 2,
      "name": "Flow State",
      "max_ranks": 3,
      "effect": "At 20+ combo, +4% all stats per rank"
    },
    {
      "id": "pattern_recognition",
      "tier": 2,
      "name": "Pattern Recognition",
      "max_ranks": 2,
      "effect": "Repeated letter patterns typed +12% faster per rank"
    },
    {
      "id": "transcendence",
      "tier": 3,
      "name": "Transcendence",
      "type": "active",
      "effect": "Time slows 50% for 15s while you type at normal speed",
      "cooldown": 180
    },
    {
      "id": "true_typist",
      "tier": 4,
      "name": "True Typist",
      "cost": 5,
      "effect": "All tier 1 skills in all trees gain +1 free rank"
    },
    {
      "id": "keyboard_mastery",
      "tier": 4,
      "name": "Keyboard Mastery",
      "cost": 5,
      "effect": "Unlock hidden 27th letter techniques",
      "hidden_bonus": "+10% all stats when fully mastered"
    }
  ]
}
```

---

## Skill Synergies

### Cross-Tree Combinations

```json
{
  "synergies": [
    {
      "name": "Speed Demon + Precision Master",
      "skills": ["speed_demon", "precision_master"],
      "bonus": "Speed penalty from Speed Demon reduced to -2%",
      "description": "Your precision compensates for raw speed."
    },
    {
      "name": "Tower Mastery + Combo Mastery",
      "skills": ["tower_mastery", "combo_mastery"],
      "bonus": "Tower combo bonus cap increased to +75%",
      "description": "Your towers benefit even more from sustained combos."
    },
    {
      "name": "Last Stand + Counterattack",
      "skills": ["last_stand", "counterattack"],
      "bonus": "Counterattack chance increased to 50% when below 20% HP",
      "description": "Cornered defenders are the most dangerous."
    },
    {
      "name": "Jackpot + Critical Strike",
      "skills": ["jackpot", "critical_strike"],
      "bonus": "Critical hits have 5% chance to also trigger Jackpot gold",
      "description": "Perfect timing brings perfect rewards."
    },
    {
      "name": "Flow State + Overdrive",
      "skills": ["flow_state", "overdrive"],
      "bonus": "Overdrive cooldown reduced by 1s per combo above 20",
      "description": "Flow state fuels your overdrive capability."
    }
  ]
}
```

---

## Build Archetypes

### Speed Build

```
Recommended Skills:
- Swift Start 5/5
- Momentum 5/5
- Burst Typing 3/3
- Chain Killer 3/3
- Overdrive 1/1
- Speed Demon 1/1

Total Points: 18
Focus: Maximum WPM, chain kills
Playstyle: Aggressive, fast-paced
```

### Precision Build

```
Recommended Skills:
- Steady Hands 5/5
- Focus 5/5
- Critical Strike 3/3
- Measured Strikes 2/2
- Perfect Form 1/1
- Precision Master 1/1

Total Points: 17
Focus: Perfect words, high damage
Playstyle: Careful, methodical
```

### Tank Build

```
Recommended Skills:
- Thick Walls 5/5
- Regeneration 5/5
- Fortification 3/3
- Shield Wall 1/1
- Emergency Repair 1/1
- Immortal Fortress 1/1

Total Points: 16
Focus: Survival, HP sustain
Playstyle: Defensive, patient
```

### Tower Build

```
Recommended Skills:
- Tower Damage 5/5
- Tower Speed 3/3
- Synergy Bonus 3/3
- Supercharge 1/1
- Mass Production 1/1
- Master Architect 1/1

Total Points: 14
Focus: Tower effectiveness
Playstyle: Strategic placement
```

### Balanced Build

```
Recommended Skills:
- Swift Start 3/5
- Steady Hands 3/5
- Thick Walls 3/5
- Combo Mastery 3/5
- Flow State 3/3
- True Typist 1/1

Total Points: 16
Focus: Well-rounded
Playstyle: Adaptable
```

---

## References

- `docs/plans/p1/PLAYER_PROGRESSION_SKILLS.md` - Overview
- `game/typing_profile.gd` - Player data
- `sim/types.gd` - Stat definitions
