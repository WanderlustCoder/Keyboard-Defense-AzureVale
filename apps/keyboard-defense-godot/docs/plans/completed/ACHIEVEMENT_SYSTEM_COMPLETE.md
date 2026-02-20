# Achievement System Complete Catalog

**Last updated:** 2026-01-08

This document contains the complete list of all achievements in Keyboard Defense, organized by category with unlock conditions, rewards, and tracking details.

---

## Table of Contents

1. [Achievement System Overview](#achievement-system-overview)
2. [Story Achievements](#story-achievements)
3. [Combat Achievements](#combat-achievements)
4. [Typing Achievements](#typing-achievements)
5. [Collection Achievements](#collection-achievements)
6. [Exploration Achievements](#exploration-achievements)
7. [Challenge Achievements](#challenge-achievements)
8. [Secret Achievements](#secret-achievements)
9. [Seasonal Achievements](#seasonal-achievements)

---

## Achievement System Overview

### Achievement Data Structure

```json
{
  "achievement_id": "string",
  "name": "Display Name",
  "description": "Achievement description",
  "category": "story | combat | typing | collection | exploration | challenge | secret",
  "rarity": "common | uncommon | rare | epic | legendary",

  "unlock_conditions": {
    "type": "condition_type",
    "value": 0,
    "additional_requirements": []
  },

  "rewards": {
    "xp": 0,
    "gold": 0,
    "title": "optional_title",
    "cosmetic": "optional_cosmetic_id",
    "skill_point": 0
  },

  "tracking": {
    "progress_type": "counter | boolean | percentage",
    "current": 0,
    "target": 0,
    "display_progress": true
  },

  "hidden": false,
  "hint": "Optional hint for secret achievements"
}
```

### Rarity Distribution

| Rarity | Count | XP Reward | Point Value |
|--------|-------|-----------|-------------|
| Common | 50 | 25-50 | 5 |
| Uncommon | 40 | 75-150 | 15 |
| Rare | 30 | 200-400 | 30 |
| Epic | 15 | 500-1000 | 50 |
| Legendary | 10 | 1500-3000 | 100 |

**Total Achievements:** 145

---

## Story Achievements

### Tutorial & Early Game

```json
{
  "achievements": [
    {
      "achievement_id": "first_word",
      "name": "First Word",
      "description": "Type your first word to defeat an enemy",
      "category": "story",
      "rarity": "common",
      "unlock_conditions": {"type": "enemies_defeated", "value": 1},
      "rewards": {"xp": 25}
    },
    {
      "achievement_id": "defender_initiate",
      "name": "Defender Initiate",
      "description": "Complete the tutorial",
      "category": "story",
      "rarity": "common",
      "unlock_conditions": {"type": "tutorial_complete"},
      "rewards": {"xp": 50, "gold": 50, "title": "Initiate"}
    },
    {
      "achievement_id": "first_tower",
      "name": "Tower Builder",
      "description": "Place your first tower",
      "category": "story",
      "rarity": "common",
      "unlock_conditions": {"type": "towers_placed", "value": 1},
      "rewards": {"xp": 25}
    },
    {
      "achievement_id": "first_upgrade",
      "name": "Improvement",
      "description": "Upgrade a tower for the first time",
      "category": "story",
      "rarity": "common",
      "unlock_conditions": {"type": "towers_upgraded", "value": 1},
      "rewards": {"xp": 25}
    },
    {
      "achievement_id": "first_wave_clear",
      "name": "Wave Crusher",
      "description": "Complete your first wave",
      "category": "story",
      "rarity": "common",
      "unlock_conditions": {"type": "waves_completed", "value": 1},
      "rewards": {"xp": 30}
    }
  ]
}
```

### Regional Progress

```json
{
  "achievements": [
    {
      "achievement_id": "evergrove_entered",
      "name": "Into the Grove",
      "description": "Enter the Evergrove region",
      "category": "story",
      "rarity": "common",
      "unlock_conditions": {"type": "region_entered", "region": "evergrove"},
      "rewards": {"xp": 50}
    },
    {
      "achievement_id": "evergrove_cleared",
      "name": "Grove Defender",
      "description": "Clear all corruption from the Evergrove",
      "category": "story",
      "rarity": "uncommon",
      "unlock_conditions": {"type": "region_corruption", "region": "evergrove", "value": 0},
      "rewards": {"xp": 200, "gold": 150, "title": "Grove Defender"}
    },
    {
      "achievement_id": "stonepass_entered",
      "name": "Mountain Passage",
      "description": "Enter the Stonepass region",
      "category": "story",
      "rarity": "common",
      "unlock_conditions": {"type": "region_entered", "region": "stonepass"},
      "rewards": {"xp": 75}
    },
    {
      "achievement_id": "stonepass_cleared",
      "name": "Stone Sentinel",
      "description": "Clear all corruption from Stonepass",
      "category": "story",
      "rarity": "uncommon",
      "unlock_conditions": {"type": "region_corruption", "region": "stonepass", "value": 0},
      "rewards": {"xp": 250, "gold": 200, "title": "Stone Sentinel"}
    },
    {
      "achievement_id": "mistfen_entered",
      "name": "Lost in the Mist",
      "description": "Enter the Mistfen region",
      "category": "story",
      "rarity": "uncommon",
      "unlock_conditions": {"type": "region_entered", "region": "mistfen"},
      "rewards": {"xp": 100}
    },
    {
      "achievement_id": "mistfen_cleared",
      "name": "Mist Walker",
      "description": "Clear all corruption from Mistfen",
      "category": "story",
      "rarity": "rare",
      "unlock_conditions": {"type": "region_corruption", "region": "mistfen", "value": 0},
      "rewards": {"xp": 300, "gold": 250, "title": "Mist Walker"}
    },
    {
      "achievement_id": "all_regions_cleared",
      "name": "Keystonia's Champion",
      "description": "Clear all corruption from all regions",
      "category": "story",
      "rarity": "epic",
      "unlock_conditions": {"type": "all_regions_cleared"},
      "rewards": {"xp": 1000, "gold": 500, "title": "Champion of Keystonia", "cosmetic": "champion_cape"}
    }
  ]
}
```

### Boss Victories

```json
{
  "achievements": [
    {
      "achievement_id": "grove_guardian_slain",
      "name": "Guardian Slain",
      "description": "Defeat the Grove Guardian",
      "category": "story",
      "rarity": "uncommon",
      "unlock_conditions": {"type": "boss_defeated", "boss": "grove_guardian"},
      "rewards": {"xp": 200, "gold": 100}
    },
    {
      "achievement_id": "grove_guardian_purified",
      "name": "Nature's Mercy",
      "description": "Purify the Grove Guardian instead of destroying it",
      "category": "story",
      "rarity": "rare",
      "unlock_conditions": {"type": "boss_purified", "boss": "grove_guardian"},
      "rewards": {"xp": 350, "gold": 150, "title": "Nature's Friend"}
    },
    {
      "achievement_id": "stone_colossus_defeated",
      "name": "Titan Fall",
      "description": "Defeat the Stone Colossus",
      "category": "story",
      "rarity": "rare",
      "unlock_conditions": {"type": "boss_defeated", "boss": "stone_colossus"},
      "rewards": {"xp": 400, "gold": 200}
    },
    {
      "achievement_id": "mist_wraith_defeated",
      "name": "Silence the Whispers",
      "description": "Defeat the Mist Wraith",
      "category": "story",
      "rarity": "rare",
      "unlock_conditions": {"type": "boss_defeated", "boss": "mist_wraith"},
      "rewards": {"xp": 400, "gold": 200}
    },
    {
      "achievement_id": "mist_wraith_redeemed",
      "name": "Archmage Redeemed",
      "description": "Redeem Archmage Vorthan through the purification ritual",
      "category": "story",
      "rarity": "epic",
      "unlock_conditions": {"type": "boss_purified", "boss": "mist_wraith"},
      "rewards": {"xp": 750, "gold": 300, "title": "Redeemer", "cosmetic": "archmage_robes"}
    },
    {
      "achievement_id": "all_bosses_defeated",
      "name": "Boss Slayer",
      "description": "Defeat all regional bosses",
      "category": "story",
      "rarity": "epic",
      "unlock_conditions": {"type": "all_bosses_defeated"},
      "rewards": {"xp": 1000, "gold": 500, "title": "Boss Slayer"}
    },
    {
      "achievement_id": "first_typo_defeated",
      "name": "The Correction",
      "description": "Defeat The First-Typo raid boss",
      "category": "story",
      "rarity": "legendary",
      "unlock_conditions": {"type": "boss_defeated", "boss": "first_typo"},
      "rewards": {"xp": 3000, "gold": 1500, "title": "The Corrector", "cosmetic": "correction_aura"}
    }
  ]
}
```

---

## Combat Achievements

### Kill Counts

```json
{
  "achievements": [
    {
      "achievement_id": "enemies_100",
      "name": "Century",
      "description": "Defeat 100 enemies",
      "category": "combat",
      "rarity": "common",
      "unlock_conditions": {"type": "enemies_defeated", "value": 100},
      "rewards": {"xp": 50},
      "tracking": {"progress_type": "counter", "target": 100}
    },
    {
      "achievement_id": "enemies_1000",
      "name": "Millennium",
      "description": "Defeat 1,000 enemies",
      "category": "combat",
      "rarity": "uncommon",
      "unlock_conditions": {"type": "enemies_defeated", "value": 1000},
      "rewards": {"xp": 150, "gold": 100},
      "tracking": {"progress_type": "counter", "target": 1000}
    },
    {
      "achievement_id": "enemies_10000",
      "name": "Decimator",
      "description": "Defeat 10,000 enemies",
      "category": "combat",
      "rarity": "rare",
      "unlock_conditions": {"type": "enemies_defeated", "value": 10000},
      "rewards": {"xp": 400, "gold": 300, "title": "Decimator"},
      "tracking": {"progress_type": "counter", "target": 10000}
    },
    {
      "achievement_id": "enemies_100000",
      "name": "Extinction Event",
      "description": "Defeat 100,000 enemies",
      "category": "combat",
      "rarity": "legendary",
      "unlock_conditions": {"type": "enemies_defeated", "value": 100000},
      "rewards": {"xp": 2000, "gold": 1000, "title": "Extinction", "cosmetic": "death_aura"},
      "tracking": {"progress_type": "counter", "target": 100000}
    }
  ]
}
```

### Enemy Type Kills

```json
{
  "achievements": [
    {
      "achievement_id": "tier5_first",
      "name": "Nightmare Slayer",
      "description": "Defeat your first Tier 5 enemy",
      "category": "combat",
      "rarity": "uncommon",
      "unlock_conditions": {"type": "enemy_tier_defeated", "tier": 5, "count": 1},
      "rewards": {"xp": 100}
    },
    {
      "achievement_id": "tier5_100",
      "name": "Horror Hunter",
      "description": "Defeat 100 Tier 5 enemies",
      "category": "combat",
      "rarity": "rare",
      "unlock_conditions": {"type": "enemy_tier_defeated", "tier": 5, "count": 100},
      "rewards": {"xp": 400, "title": "Horror Hunter"},
      "tracking": {"progress_type": "counter", "target": 100}
    },
    {
      "achievement_id": "elite_25",
      "name": "Elite Eliminator",
      "description": "Defeat 25 elite enemies",
      "category": "combat",
      "rarity": "uncommon",
      "unlock_conditions": {"type": "elites_defeated", "value": 25},
      "rewards": {"xp": 150},
      "tracking": {"progress_type": "counter", "target": 25}
    },
    {
      "achievement_id": "elite_100",
      "name": "Champion's Bane",
      "description": "Defeat 100 elite enemies",
      "category": "combat",
      "rarity": "rare",
      "unlock_conditions": {"type": "elites_defeated", "value": 100},
      "rewards": {"xp": 350, "gold": 200},
      "tracking": {"progress_type": "counter", "target": 100}
    },
    {
      "achievement_id": "affix_variety",
      "name": "Affix Collector",
      "description": "Defeat enemies with every affix type",
      "category": "combat",
      "rarity": "rare",
      "unlock_conditions": {"type": "all_affixes_defeated"},
      "rewards": {"xp": 300, "title": "Affix Expert"}
    }
  ]
}
```

### Wave Achievements

```json
{
  "achievements": [
    {
      "achievement_id": "wave_10",
      "name": "Getting Started",
      "description": "Reach wave 10",
      "category": "combat",
      "rarity": "common",
      "unlock_conditions": {"type": "wave_reached", "value": 10},
      "rewards": {"xp": 50}
    },
    {
      "achievement_id": "wave_25",
      "name": "Holding Strong",
      "description": "Reach wave 25",
      "category": "combat",
      "rarity": "uncommon",
      "unlock_conditions": {"type": "wave_reached", "value": 25},
      "rewards": {"xp": 100}
    },
    {
      "achievement_id": "wave_50",
      "name": "Endurance",
      "description": "Reach wave 50",
      "category": "combat",
      "rarity": "rare",
      "unlock_conditions": {"type": "wave_reached", "value": 50},
      "rewards": {"xp": 250, "gold": 150}
    },
    {
      "achievement_id": "wave_100",
      "name": "Century Defense",
      "description": "Reach wave 100",
      "category": "combat",
      "rarity": "epic",
      "unlock_conditions": {"type": "wave_reached", "value": 100},
      "rewards": {"xp": 750, "gold": 400, "title": "Centurion"}
    },
    {
      "achievement_id": "wave_200",
      "name": "Immortal Defender",
      "description": "Reach wave 200",
      "category": "combat",
      "rarity": "legendary",
      "unlock_conditions": {"type": "wave_reached", "value": 200},
      "rewards": {"xp": 2500, "gold": 1000, "title": "Immortal", "cosmetic": "immortal_crown"}
    },
    {
      "achievement_id": "perfect_wave",
      "name": "Flawless",
      "description": "Complete a wave without any enemy reaching the castle",
      "category": "combat",
      "rarity": "uncommon",
      "unlock_conditions": {"type": "wave_no_damage"},
      "rewards": {"xp": 100}
    },
    {
      "achievement_id": "perfect_10_waves",
      "name": "Perfect Ten",
      "description": "Complete 10 consecutive waves without castle damage",
      "category": "combat",
      "rarity": "rare",
      "unlock_conditions": {"type": "consecutive_no_damage", "value": 10},
      "rewards": {"xp": 350, "gold": 200}
    }
  ]
}
```

### Tower Achievements

```json
{
  "achievements": [
    {
      "achievement_id": "tower_max_upgrade",
      "name": "Fully Upgraded",
      "description": "Fully upgrade a tower to tier 4",
      "category": "combat",
      "rarity": "uncommon",
      "unlock_conditions": {"type": "tower_max_tier"},
      "rewards": {"xp": 75}
    },
    {
      "achievement_id": "tower_all_types",
      "name": "Tower Collector",
      "description": "Build every type of tower at least once",
      "category": "combat",
      "rarity": "rare",
      "unlock_conditions": {"type": "all_tower_types_built"},
      "rewards": {"xp": 300, "title": "Architect"}
    },
    {
      "achievement_id": "synergy_first",
      "name": "Better Together",
      "description": "Activate your first tower synergy",
      "category": "combat",
      "rarity": "uncommon",
      "unlock_conditions": {"type": "synergy_activated", "count": 1},
      "rewards": {"xp": 100}
    },
    {
      "achievement_id": "synergy_all",
      "name": "Synergy Master",
      "description": "Activate all tower synergies",
      "category": "combat",
      "rarity": "epic",
      "unlock_conditions": {"type": "all_synergies_activated"},
      "rewards": {"xp": 600, "gold": 300, "title": "Synergist"}
    },
    {
      "achievement_id": "legendary_tower",
      "name": "Legendary Arsenal",
      "description": "Build a legendary tower",
      "category": "combat",
      "rarity": "rare",
      "unlock_conditions": {"type": "legendary_tower_built"},
      "rewards": {"xp": 400, "gold": 200}
    }
  ]
}
```

---

## Typing Achievements

### Speed Achievements

```json
{
  "achievements": [
    {
      "achievement_id": "wpm_30",
      "name": "Finding Your Rhythm",
      "description": "Reach 30 WPM in combat",
      "category": "typing",
      "rarity": "common",
      "unlock_conditions": {"type": "wpm_reached", "value": 30},
      "rewards": {"xp": 50}
    },
    {
      "achievement_id": "wpm_50",
      "name": "Speeding Up",
      "description": "Reach 50 WPM in combat",
      "category": "typing",
      "rarity": "uncommon",
      "unlock_conditions": {"type": "wpm_reached", "value": 50},
      "rewards": {"xp": 100}
    },
    {
      "achievement_id": "wpm_75",
      "name": "Swift Fingers",
      "description": "Reach 75 WPM in combat",
      "category": "typing",
      "rarity": "rare",
      "unlock_conditions": {"type": "wpm_reached", "value": 75},
      "rewards": {"xp": 250, "title": "Swift"}
    },
    {
      "achievement_id": "wpm_100",
      "name": "Lightning Fingers",
      "description": "Reach 100 WPM in combat",
      "category": "typing",
      "rarity": "epic",
      "unlock_conditions": {"type": "wpm_reached", "value": 100},
      "rewards": {"xp": 500, "gold": 250, "title": "Lightning"}
    },
    {
      "achievement_id": "wpm_150",
      "name": "Keyboard Virtuoso",
      "description": "Reach 150 WPM in combat",
      "category": "typing",
      "rarity": "legendary",
      "unlock_conditions": {"type": "wpm_reached", "value": 150},
      "rewards": {"xp": 2000, "gold": 750, "title": "Virtuoso", "cosmetic": "lightning_trail"}
    }
  ]
}
```

### Accuracy Achievements

```json
{
  "achievements": [
    {
      "achievement_id": "accuracy_90",
      "name": "Careful Typist",
      "description": "Complete a battle with 90% accuracy",
      "category": "typing",
      "rarity": "common",
      "unlock_conditions": {"type": "battle_accuracy", "value": 0.90},
      "rewards": {"xp": 50}
    },
    {
      "achievement_id": "accuracy_95",
      "name": "Precision Typing",
      "description": "Complete a battle with 95% accuracy",
      "category": "typing",
      "rarity": "uncommon",
      "unlock_conditions": {"type": "battle_accuracy", "value": 0.95},
      "rewards": {"xp": 100}
    },
    {
      "achievement_id": "accuracy_98",
      "name": "Near Perfect",
      "description": "Complete a battle with 98% accuracy",
      "category": "typing",
      "rarity": "rare",
      "unlock_conditions": {"type": "battle_accuracy", "value": 0.98},
      "rewards": {"xp": 250, "title": "Precise"}
    },
    {
      "achievement_id": "accuracy_100",
      "name": "Flawless Execution",
      "description": "Complete a battle with 100% accuracy (minimum 50 words)",
      "category": "typing",
      "rarity": "epic",
      "unlock_conditions": {"type": "battle_accuracy", "value": 1.0, "min_words": 50},
      "rewards": {"xp": 600, "gold": 300, "title": "Flawless"}
    },
    {
      "achievement_id": "accuracy_100_sustained",
      "name": "Perfection Incarnate",
      "description": "Maintain 100% accuracy for an entire session (minimum 200 words)",
      "category": "typing",
      "rarity": "legendary",
      "unlock_conditions": {"type": "session_accuracy", "value": 1.0, "min_words": 200},
      "rewards": {"xp": 2000, "gold": 1000, "title": "Perfect", "cosmetic": "perfection_halo"}
    }
  ]
}
```

### Word Achievements

```json
{
  "achievements": [
    {
      "achievement_id": "words_1000",
      "name": "Wordsmith Apprentice",
      "description": "Type 1,000 words correctly",
      "category": "typing",
      "rarity": "common",
      "unlock_conditions": {"type": "words_typed", "value": 1000},
      "rewards": {"xp": 75},
      "tracking": {"progress_type": "counter", "target": 1000}
    },
    {
      "achievement_id": "words_10000",
      "name": "Wordsmith Journeyman",
      "description": "Type 10,000 words correctly",
      "category": "typing",
      "rarity": "uncommon",
      "unlock_conditions": {"type": "words_typed", "value": 10000},
      "rewards": {"xp": 200, "gold": 100},
      "tracking": {"progress_type": "counter", "target": 10000}
    },
    {
      "achievement_id": "words_100000",
      "name": "Master Wordsmith",
      "description": "Type 100,000 words correctly",
      "category": "typing",
      "rarity": "rare",
      "unlock_conditions": {"type": "words_typed", "value": 100000},
      "rewards": {"xp": 500, "gold": 250, "title": "Wordsmith"},
      "tracking": {"progress_type": "counter", "target": 100000}
    },
    {
      "achievement_id": "words_1000000",
      "name": "Living Lexicon",
      "description": "Type 1,000,000 words correctly",
      "category": "typing",
      "rarity": "legendary",
      "unlock_conditions": {"type": "words_typed", "value": 1000000},
      "rewards": {"xp": 3000, "gold": 1500, "title": "Lexicon", "cosmetic": "word_aura"},
      "tracking": {"progress_type": "counter", "target": 1000000}
    },
    {
      "achievement_id": "long_word",
      "name": "Sesquipedalian",
      "description": "Type a word with 15 or more letters",
      "category": "typing",
      "rarity": "uncommon",
      "unlock_conditions": {"type": "word_length", "value": 15},
      "rewards": {"xp": 100}
    },
    {
      "achievement_id": "combo_10",
      "name": "Combo Starter",
      "description": "Achieve a 10-word combo",
      "category": "typing",
      "rarity": "common",
      "unlock_conditions": {"type": "combo_reached", "value": 10},
      "rewards": {"xp": 50}
    },
    {
      "achievement_id": "combo_50",
      "name": "Combo Master",
      "description": "Achieve a 50-word combo",
      "category": "typing",
      "rarity": "rare",
      "unlock_conditions": {"type": "combo_reached", "value": 50},
      "rewards": {"xp": 300, "title": "Combo Master"}
    },
    {
      "achievement_id": "combo_100",
      "name": "Unstoppable",
      "description": "Achieve a 100-word combo",
      "category": "typing",
      "rarity": "epic",
      "unlock_conditions": {"type": "combo_reached", "value": 100},
      "rewards": {"xp": 750, "gold": 400, "cosmetic": "combo_counter_enhanced"}
    }
  ]
}
```

### Lesson Achievements

```json
{
  "achievements": [
    {
      "achievement_id": "lesson_first",
      "name": "Student",
      "description": "Complete your first typing lesson",
      "category": "typing",
      "rarity": "common",
      "unlock_conditions": {"type": "lessons_completed", "value": 1},
      "rewards": {"xp": 25}
    },
    {
      "achievement_id": "lesson_all_basic",
      "name": "Basic Training Complete",
      "description": "Complete all basic typing lessons",
      "category": "typing",
      "rarity": "uncommon",
      "unlock_conditions": {"type": "lesson_category_complete", "category": "basic"},
      "rewards": {"xp": 150, "title": "Graduate"}
    },
    {
      "achievement_id": "lesson_all_advanced",
      "name": "Advanced Graduate",
      "description": "Complete all advanced typing lessons",
      "category": "typing",
      "rarity": "rare",
      "unlock_conditions": {"type": "lesson_category_complete", "category": "advanced"},
      "rewards": {"xp": 350, "gold": 200}
    },
    {
      "achievement_id": "lesson_mastery",
      "name": "Lesson Master",
      "description": "Achieve mastery (3 stars) on all lessons",
      "category": "typing",
      "rarity": "epic",
      "unlock_conditions": {"type": "all_lessons_mastered"},
      "rewards": {"xp": 1000, "gold": 500, "title": "Master Typist"}
    }
  ]
}
```

---

## Collection Achievements

### Lore Collection

```json
{
  "achievements": [
    {
      "achievement_id": "lore_10",
      "name": "Curious Mind",
      "description": "Collect 10 lore pages",
      "category": "collection",
      "rarity": "common",
      "unlock_conditions": {"type": "lore_collected", "value": 10},
      "rewards": {"xp": 50},
      "tracking": {"progress_type": "counter", "target": 10}
    },
    {
      "achievement_id": "lore_25",
      "name": "Scholar",
      "description": "Collect 25 lore pages",
      "category": "collection",
      "rarity": "uncommon",
      "unlock_conditions": {"type": "lore_collected", "value": 25},
      "rewards": {"xp": 150, "title": "Scholar"},
      "tracking": {"progress_type": "counter", "target": 25}
    },
    {
      "achievement_id": "lore_all",
      "name": "Lore Master",
      "description": "Collect all lore pages",
      "category": "collection",
      "rarity": "epic",
      "unlock_conditions": {"type": "lore_collected", "value": 50},
      "rewards": {"xp": 750, "gold": 400, "title": "Lore Master", "cosmetic": "scholar_robes"},
      "tracking": {"progress_type": "counter", "target": 50}
    },
    {
      "achievement_id": "lore_category_creation",
      "name": "Origin Scholar",
      "description": "Collect all Creation lore pages",
      "category": "collection",
      "rarity": "rare",
      "unlock_conditions": {"type": "lore_category_complete", "category": "creation"},
      "rewards": {"xp": 200}
    },
    {
      "achievement_id": "lore_category_spirits",
      "name": "Spirit Scholar",
      "description": "Collect all Letter Spirit lore pages",
      "category": "collection",
      "rarity": "rare",
      "unlock_conditions": {"type": "lore_category_complete", "category": "letter_spirits"},
      "rewards": {"xp": 200}
    }
  ]
}
```

### Item Collection

```json
{
  "achievements": [
    {
      "achievement_id": "items_unique_25",
      "name": "Collector",
      "description": "Collect 25 unique items",
      "category": "collection",
      "rarity": "common",
      "unlock_conditions": {"type": "unique_items", "value": 25},
      "rewards": {"xp": 75},
      "tracking": {"progress_type": "counter", "target": 25}
    },
    {
      "achievement_id": "items_unique_100",
      "name": "Hoarder",
      "description": "Collect 100 unique items",
      "category": "collection",
      "rarity": "rare",
      "unlock_conditions": {"type": "unique_items", "value": 100},
      "rewards": {"xp": 350, "gold": 200},
      "tracking": {"progress_type": "counter", "target": 100}
    },
    {
      "achievement_id": "legendary_item_first",
      "name": "Legendary Find",
      "description": "Obtain your first legendary item",
      "category": "collection",
      "rarity": "rare",
      "unlock_conditions": {"type": "item_rarity", "rarity": "legendary", "count": 1},
      "rewards": {"xp": 300}
    },
    {
      "achievement_id": "equipment_set",
      "name": "Set Collector",
      "description": "Complete an equipment set",
      "category": "collection",
      "rarity": "rare",
      "unlock_conditions": {"type": "set_complete"},
      "rewards": {"xp": 400, "gold": 250}
    },
    {
      "achievement_id": "all_sets",
      "name": "Fashion Master",
      "description": "Complete all equipment sets",
      "category": "collection",
      "rarity": "legendary",
      "unlock_conditions": {"type": "all_sets_complete"},
      "rewards": {"xp": 2000, "gold": 1000, "title": "Fashion Master"}
    }
  ]
}
```

### Enemy Codex

```json
{
  "achievements": [
    {
      "achievement_id": "codex_25",
      "name": "Monster Hunter",
      "description": "Discover 25 enemy types in the codex",
      "category": "collection",
      "rarity": "common",
      "unlock_conditions": {"type": "codex_entries", "value": 25},
      "rewards": {"xp": 75}
    },
    {
      "achievement_id": "codex_complete",
      "name": "Bestiary Complete",
      "description": "Discover all enemy types",
      "category": "collection",
      "rarity": "epic",
      "unlock_conditions": {"type": "codex_complete"},
      "rewards": {"xp": 600, "gold": 300, "title": "Monster Expert"}
    }
  ]
}
```

---

## Exploration Achievements

### POI Discovery

```json
{
  "achievements": [
    {
      "achievement_id": "poi_10",
      "name": "Explorer",
      "description": "Discover 10 Points of Interest",
      "category": "exploration",
      "rarity": "common",
      "unlock_conditions": {"type": "pois_discovered", "value": 10},
      "rewards": {"xp": 50}
    },
    {
      "achievement_id": "poi_50",
      "name": "Cartographer",
      "description": "Discover 50 Points of Interest",
      "category": "exploration",
      "rarity": "uncommon",
      "unlock_conditions": {"type": "pois_discovered", "value": 50},
      "rewards": {"xp": 200, "title": "Cartographer"}
    },
    {
      "achievement_id": "poi_all",
      "name": "World Explorer",
      "description": "Discover all Points of Interest",
      "category": "exploration",
      "rarity": "epic",
      "unlock_conditions": {"type": "pois_discovered", "value": 161},
      "rewards": {"xp": 1000, "gold": 500, "cosmetic": "explorer_map"}
    },
    {
      "achievement_id": "shrine_all",
      "name": "Pilgrim",
      "description": "Visit all Letter Spirit shrines",
      "category": "exploration",
      "rarity": "rare",
      "unlock_conditions": {"type": "shrines_visited", "value": 26},
      "rewards": {"xp": 400, "title": "Pilgrim"}
    },
    {
      "achievement_id": "standing_stones",
      "name": "Stone Seeker",
      "description": "Find all Standing Stone circles",
      "category": "exploration",
      "rarity": "rare",
      "unlock_conditions": {"type": "standing_stones_found"},
      "rewards": {"xp": 350, "gold": 200}
    }
  ]
}
```

### NPC Interactions

```json
{
  "achievements": [
    {
      "achievement_id": "npc_all_met",
      "name": "Social Butterfly",
      "description": "Meet all NPCs",
      "category": "exploration",
      "rarity": "rare",
      "unlock_conditions": {"type": "npcs_met", "value": 50},
      "rewards": {"xp": 300, "title": "Socialite"}
    },
    {
      "achievement_id": "merchant_all",
      "name": "Frequent Customer",
      "description": "Purchase from every merchant",
      "category": "exploration",
      "rarity": "uncommon",
      "unlock_conditions": {"type": "merchants_visited"},
      "rewards": {"xp": 150, "gold": 100}
    },
    {
      "achievement_id": "quests_100",
      "name": "Quest Master",
      "description": "Complete 100 quests",
      "category": "exploration",
      "rarity": "rare",
      "unlock_conditions": {"type": "quests_completed", "value": 100},
      "rewards": {"xp": 500, "gold": 300}
    }
  ]
}
```

---

## Challenge Achievements

### Speed Challenges

```json
{
  "achievements": [
    {
      "achievement_id": "speed_challenge_bronze",
      "name": "Speed Runner Bronze",
      "description": "Complete a speed challenge with bronze rating",
      "category": "challenge",
      "rarity": "common",
      "unlock_conditions": {"type": "speed_challenge", "rating": "bronze"},
      "rewards": {"xp": 50}
    },
    {
      "achievement_id": "speed_challenge_gold",
      "name": "Speed Runner Gold",
      "description": "Complete a speed challenge with gold rating",
      "category": "challenge",
      "rarity": "rare",
      "unlock_conditions": {"type": "speed_challenge", "rating": "gold"},
      "rewards": {"xp": 250}
    },
    {
      "achievement_id": "speed_challenges_all_gold",
      "name": "Speed Demon",
      "description": "Complete all speed challenges with gold rating",
      "category": "challenge",
      "rarity": "epic",
      "unlock_conditions": {"type": "all_speed_challenges_gold"},
      "rewards": {"xp": 750, "title": "Speed Demon"}
    }
  ]
}
```

### Difficulty Challenges

```json
{
  "achievements": [
    {
      "achievement_id": "nightmare_complete",
      "name": "Nightmare Survivor",
      "description": "Complete a region on Nightmare difficulty",
      "category": "challenge",
      "rarity": "rare",
      "unlock_conditions": {"type": "region_complete_difficulty", "difficulty": "nightmare"},
      "rewards": {"xp": 400, "gold": 200}
    },
    {
      "achievement_id": "nightmare_all",
      "name": "Nightmare Conqueror",
      "description": "Complete all regions on Nightmare difficulty",
      "category": "challenge",
      "rarity": "legendary",
      "unlock_conditions": {"type": "all_regions_nightmare"},
      "rewards": {"xp": 2000, "gold": 1000, "title": "Nightmare Conqueror", "cosmetic": "nightmare_aura"}
    },
    {
      "achievement_id": "no_towers",
      "name": "Keyboard Warrior",
      "description": "Complete a wave using no towers",
      "category": "challenge",
      "rarity": "rare",
      "unlock_conditions": {"type": "wave_no_towers"},
      "rewards": {"xp": 300, "title": "Keyboard Warrior"}
    },
    {
      "achievement_id": "one_life",
      "name": "One Shot",
      "description": "Complete a region without the castle taking any damage",
      "category": "challenge",
      "rarity": "epic",
      "unlock_conditions": {"type": "region_no_damage"},
      "rewards": {"xp": 800, "gold": 400}
    }
  ]
}
```

### Daily/Weekly Challenges

```json
{
  "achievements": [
    {
      "achievement_id": "daily_7",
      "name": "Weekly Warrior",
      "description": "Complete daily challenges 7 days in a row",
      "category": "challenge",
      "rarity": "uncommon",
      "unlock_conditions": {"type": "daily_streak", "value": 7},
      "rewards": {"xp": 150}
    },
    {
      "achievement_id": "daily_30",
      "name": "Monthly Champion",
      "description": "Complete daily challenges 30 days in a row",
      "category": "challenge",
      "rarity": "rare",
      "unlock_conditions": {"type": "daily_streak", "value": 30},
      "rewards": {"xp": 500, "gold": 250, "title": "Dedicated"}
    },
    {
      "achievement_id": "daily_365",
      "name": "Year of Dedication",
      "description": "Complete daily challenges for an entire year",
      "category": "challenge",
      "rarity": "legendary",
      "unlock_conditions": {"type": "daily_streak", "value": 365},
      "rewards": {"xp": 3000, "gold": 1500, "title": "Eternal Defender", "cosmetic": "anniversary_crown"}
    }
  ]
}
```

---

## Secret Achievements

```json
{
  "secret_achievements": [
    {
      "achievement_id": "secret_perfect_word",
      "name": "The Perfect Word",
      "description": "???",
      "hint": "Legends speak of a word that can end corruption...",
      "category": "secret",
      "rarity": "legendary",
      "hidden": true,
      "unlock_conditions": {"type": "type_phrase", "phrase": "PERFECTION"},
      "rewards": {"xp": 2000, "title": "Wordkeeper"}
    },
    {
      "achievement_id": "secret_konami",
      "name": "Classic Code",
      "description": "???",
      "hint": "Up up down down...",
      "category": "secret",
      "rarity": "rare",
      "hidden": true,
      "unlock_conditions": {"type": "input_sequence", "sequence": "up up down down left right left right b a"},
      "rewards": {"xp": 100, "cosmetic": "retro_keyboard"}
    },
    {
      "achievement_id": "secret_all_letters",
      "name": "Pangram Master",
      "description": "???",
      "hint": "The quick brown fox...",
      "category": "secret",
      "rarity": "uncommon",
      "hidden": true,
      "unlock_conditions": {"type": "type_phrase", "phrase": "the quick brown fox jumps over the lazy dog"},
      "rewards": {"xp": 150}
    },
    {
      "achievement_id": "secret_midnight",
      "name": "Midnight Typist",
      "description": "???",
      "hint": "When the clock strikes twelve...",
      "category": "secret",
      "rarity": "uncommon",
      "hidden": true,
      "unlock_conditions": {"type": "play_at_time", "time": "00:00"},
      "rewards": {"xp": 100, "title": "Night Owl"}
    },
    {
      "achievement_id": "secret_same_word",
      "name": "Repetition",
      "description": "???",
      "hint": "Sometimes you just need to say it again and again...",
      "category": "secret",
      "rarity": "rare",
      "hidden": true,
      "unlock_conditions": {"type": "same_word_consecutive", "count": 10},
      "rewards": {"xp": 200}
    },
    {
      "achievement_id": "secret_backwards",
      "name": "Mirror Writer",
      "description": "???",
      "hint": ".sdrawkcab epyt ot yrT",
      "category": "secret",
      "rarity": "rare",
      "hidden": true,
      "unlock_conditions": {"type": "type_backwards_word", "length_min": 8},
      "rewards": {"xp": 200, "title": "Inverter"}
    },
    {
      "achievement_id": "secret_1337",
      "name": "1337 H4X0R",
      "description": "???",
      "hint": "Numbers can be letters too...",
      "category": "secret",
      "rarity": "rare",
      "hidden": true,
      "unlock_conditions": {"type": "reach_score", "score": 1337},
      "rewards": {"xp": 133, "cosmetic": "hacker_glasses"}
    },
    {
      "achievement_id": "secret_alphabet",
      "name": "Alphabetical",
      "description": "???",
      "hint": "A to Z, in order...",
      "category": "secret",
      "rarity": "epic",
      "hidden": true,
      "unlock_conditions": {"type": "type_phrase", "phrase": "abcdefghijklmnopqrstuvwxyz"},
      "rewards": {"xp": 500, "title": "Alphabetizer"}
    },
    {
      "achievement_id": "secret_fall_50",
      "name": "This Is Fine",
      "description": "???",
      "hint": "Sometimes you just have to accept defeat... many times...",
      "category": "secret",
      "rarity": "rare",
      "hidden": true,
      "unlock_conditions": {"type": "castle_destroyed", "count": 50},
      "rewards": {"xp": 200, "title": "Persistent"}
    },
    {
      "achievement_id": "secret_idle",
      "name": "The Watcher",
      "description": "???",
      "hint": "Sometimes doing nothing is the hardest thing...",
      "category": "secret",
      "rarity": "uncommon",
      "hidden": true,
      "unlock_conditions": {"type": "idle_time", "minutes": 10},
      "rewards": {"xp": 50}
    }
  ]
}
```

---

## Seasonal Achievements

```json
{
  "seasonal_achievements": [
    {
      "achievement_id": "seasonal_winter_2026",
      "name": "Winter Warrior 2026",
      "description": "Complete the Winter Festival event",
      "category": "seasonal",
      "rarity": "rare",
      "time_limited": true,
      "available_from": "2026-12-15",
      "available_until": "2027-01-05",
      "unlock_conditions": {"type": "event_complete", "event": "winter_festival_2026"},
      "rewards": {"xp": 500, "cosmetic": "winter_crown_2026"}
    },
    {
      "achievement_id": "seasonal_anniversary",
      "name": "Anniversary Celebration",
      "description": "Play during the game's anniversary week",
      "category": "seasonal",
      "rarity": "uncommon",
      "recurring": true,
      "unlock_conditions": {"type": "play_during_anniversary"},
      "rewards": {"xp": 200, "gold": 100}
    }
  ]
}
```

---

## Achievement Tracking Implementation

```gdscript
class_name AchievementManager
extends Node

signal achievement_unlocked(achievement: Achievement)
signal achievement_progress(achievement: Achievement, current: int, target: int)

var achievements: Dictionary = {}
var unlocked: Array[String] = []
var progress: Dictionary = {}

func check_achievement(achievement_id: String) -> void:
    if achievement_id in unlocked:
        return

    var achievement = achievements[achievement_id]
    if evaluate_condition(achievement.unlock_conditions):
        unlock_achievement(achievement_id)

func unlock_achievement(achievement_id: String) -> void:
    if achievement_id in unlocked:
        return

    unlocked.append(achievement_id)
    var achievement = achievements[achievement_id]

    # Grant rewards
    if achievement.rewards.has("xp"):
        PlayerStats.add_xp(achievement.rewards.xp)
    if achievement.rewards.has("gold"):
        PlayerStats.add_gold(achievement.rewards.gold)
    if achievement.rewards.has("title"):
        PlayerStats.unlock_title(achievement.rewards.title)
    if achievement.rewards.has("cosmetic"):
        PlayerStats.unlock_cosmetic(achievement.rewards.cosmetic)

    achievement_unlocked.emit(achievement)
    save_achievements()

func update_progress(achievement_id: String, value: int) -> void:
    var achievement = achievements[achievement_id]
    if not achievement.tracking:
        return

    progress[achievement_id] = value
    achievement_progress.emit(achievement, value, achievement.tracking.target)

    if value >= achievement.tracking.target:
        check_achievement(achievement_id)
```

---

**Document version:** 1.0
**Total achievements:** 145
**Categories:** 9
**Legendary achievements:** 10
