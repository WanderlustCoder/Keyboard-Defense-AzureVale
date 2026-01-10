# Crafting Recipes Complete Catalog

**Last updated:** 2026-01-08

This document contains all crafting recipes in Keyboard Defense, organized by category and crafting station.

---

## Table of Contents

1. [Crafting System Overview](#crafting-system-overview)
2. [Blacksmith Recipes](#blacksmith-recipes)
3. [Alchemist Recipes](#alchemist-recipes)
4. [Enchanter Recipes](#enchanter-recipes)
5. [Scribe Recipes](#scribe-recipes)
6. [Special Recipes](#special-recipes)
7. [Material Acquisition](#material-acquisition)

---

## Crafting System Overview

### Recipe Data Structure

```json
{
  "recipe_id": "string",
  "name": "Recipe Name",
  "category": "equipment | consumable | upgrade | special",
  "station": "blacksmith | alchemist | enchanter | scribe",
  "unlock_requirement": {},

  "ingredients": [
    {"item_id": "material_id", "quantity": 0}
  ],

  "gold_cost": 0,
  "crafting_time": 0.0,

  "output": {
    "item_id": "result_item_id",
    "quantity": 1,
    "quality_variance": false
  },

  "skill_requirement": {
    "skill": "crafting_skill_id",
    "level": 0
  }
}
```

### Crafting Stations

| Station | Location | Specialization |
|---------|----------|----------------|
| Blacksmith | Starting Village, Stonepass | Equipment, weapons, armor |
| Alchemist | Starting Village, Mistfen | Potions, elixirs, bombs |
| Enchanter | Mistfen Spire | Enchantments, scrolls |
| Scribe | Library Tower | Books, special items |

---

## Blacksmith Recipes

### Basic Equipment (Tier 1)

```json
{
  "recipes": [
    {
      "recipe_id": "helm_iron",
      "name": "Iron Helm",
      "station": "blacksmith",
      "unlock": "default",
      "ingredients": [
        {"item_id": "iron_ingot", "quantity": 3},
        {"item_id": "leather_strap", "quantity": 1}
      ],
      "gold_cost": 50,
      "output": {"item_id": "helm_iron", "quality_variance": true}
    },
    {
      "recipe_id": "armor_iron",
      "name": "Iron Chestplate",
      "station": "blacksmith",
      "unlock": "default",
      "ingredients": [
        {"item_id": "iron_ingot", "quantity": 5},
        {"item_id": "leather_strap", "quantity": 2}
      ],
      "gold_cost": 75,
      "output": {"item_id": "armor_iron", "quality_variance": true}
    },
    {
      "recipe_id": "gloves_leather",
      "name": "Leather Gloves",
      "station": "blacksmith",
      "unlock": "default",
      "ingredients": [
        {"item_id": "leather", "quantity": 2},
        {"item_id": "thread", "quantity": 1}
      ],
      "gold_cost": 30,
      "output": {"item_id": "gloves_leather"}
    },
    {
      "recipe_id": "boots_leather",
      "name": "Leather Boots",
      "station": "blacksmith",
      "unlock": "default",
      "ingredients": [
        {"item_id": "leather", "quantity": 3},
        {"item_id": "thread", "quantity": 1}
      ],
      "gold_cost": 40,
      "output": {"item_id": "boots_leather"}
    }
  ]
}
```

### Standard Equipment (Tier 2)

```json
{
  "recipes": [
    {
      "recipe_id": "helm_steel",
      "name": "Steel Helm",
      "station": "blacksmith",
      "unlock": {"type": "level", "value": 10},
      "ingredients": [
        {"item_id": "steel_ingot", "quantity": 3},
        {"item_id": "leather_strap", "quantity": 2}
      ],
      "gold_cost": 100,
      "output": {"item_id": "helm_steel", "quality_variance": true}
    },
    {
      "recipe_id": "armor_steel",
      "name": "Steel Chestplate",
      "station": "blacksmith",
      "unlock": {"type": "level", "value": 10},
      "ingredients": [
        {"item_id": "steel_ingot", "quantity": 6},
        {"item_id": "leather_strap", "quantity": 3}
      ],
      "gold_cost": 150,
      "output": {"item_id": "armor_steel", "quality_variance": true}
    },
    {
      "recipe_id": "gloves_chain",
      "name": "Chainmail Gloves",
      "station": "blacksmith",
      "unlock": {"type": "level", "value": 10},
      "ingredients": [
        {"item_id": "steel_ingot", "quantity": 2},
        {"item_id": "iron_ingot", "quantity": 2}
      ],
      "gold_cost": 80,
      "output": {"item_id": "gloves_chain"}
    },
    {
      "recipe_id": "boots_reinforced",
      "name": "Reinforced Boots",
      "station": "blacksmith",
      "unlock": {"type": "level", "value": 10},
      "ingredients": [
        {"item_id": "leather", "quantity": 3},
        {"item_id": "steel_ingot", "quantity": 2}
      ],
      "gold_cost": 90,
      "output": {"item_id": "boots_reinforced"}
    }
  ]
}
```

### Advanced Equipment (Tier 3)

```json
{
  "recipes": [
    {
      "recipe_id": "helm_keysteel",
      "name": "Keysteel Helm",
      "station": "blacksmith",
      "unlock": {"type": "level", "value": 20},
      "ingredients": [
        {"item_id": "keysteel_ingot", "quantity": 3},
        {"item_id": "enchanted_leather", "quantity": 1},
        {"item_id": "sapphire", "quantity": 1}
      ],
      "gold_cost": 300,
      "output": {"item_id": "helm_keysteel", "quality_variance": true}
    },
    {
      "recipe_id": "armor_keysteel",
      "name": "Keysteel Chestplate",
      "station": "blacksmith",
      "unlock": {"type": "level", "value": 20},
      "ingredients": [
        {"item_id": "keysteel_ingot", "quantity": 6},
        {"item_id": "enchanted_leather", "quantity": 2},
        {"item_id": "ruby", "quantity": 1}
      ],
      "gold_cost": 450,
      "output": {"item_id": "armor_keysteel", "quality_variance": true}
    },
    {
      "recipe_id": "gloves_typing",
      "name": "Typist's Gloves",
      "station": "blacksmith",
      "unlock": {"type": "level", "value": 20},
      "ingredients": [
        {"item_id": "enchanted_leather", "quantity": 2},
        {"item_id": "silk_thread", "quantity": 3},
        {"item_id": "letter_essence", "quantity": 2}
      ],
      "gold_cost": 250,
      "output": {"item_id": "gloves_typing"}
    },
    {
      "recipe_id": "boots_swift",
      "name": "Swiftstrider Boots",
      "station": "blacksmith",
      "unlock": {"type": "level", "value": 20},
      "ingredients": [
        {"item_id": "enchanted_leather", "quantity": 3},
        {"item_id": "wind_essence", "quantity": 2},
        {"item_id": "feather", "quantity": 5}
      ],
      "gold_cost": 280,
      "output": {"item_id": "boots_swift"}
    }
  ]
}
```

### Legendary Equipment (Tier 4)

```json
{
  "recipes": [
    {
      "recipe_id": "helm_legendary",
      "name": "First Typist's Circlet",
      "station": "blacksmith",
      "unlock": {"type": "quest", "quest_id": "legend_of_keystos"},
      "ingredients": [
        {"item_id": "words_crystalline", "quantity": 3},
        {"item_id": "keysteel_ingot", "quantity": 5},
        {"item_id": "diamond", "quantity": 1},
        {"item_id": "letter_spirit_blessing", "quantity": 1}
      ],
      "gold_cost": 1000,
      "output": {"item_id": "helm_legendary"}
    },
    {
      "recipe_id": "armor_legendary",
      "name": "Wordweave Mantle",
      "station": "blacksmith",
      "unlock": {"type": "quest", "quest_id": "master_of_words"},
      "ingredients": [
        {"item_id": "words_crystalline", "quantity": 5},
        {"item_id": "dragon_leather", "quantity": 3},
        {"item_id": "spell_thread", "quantity": 10},
        {"item_id": "archmage_essence", "quantity": 1}
      ],
      "gold_cost": 1500,
      "output": {"item_id": "armor_legendary"}
    },
    {
      "recipe_id": "gloves_legendary",
      "name": "Defender's Gauntlets",
      "station": "blacksmith",
      "unlock": {"type": "quest", "quest_id": "garrett_gauntlets"},
      "ingredients": [
        {"item_id": "refined_keysteel", "quantity": 4},
        {"item_id": "spellforged_core", "quantity": 1},
        {"item_id": "guardian_heartwood", "quantity": 1}
      ],
      "gold_cost": 800,
      "output": {"item_id": "gloves_legendary"}
    }
  ]
}
```

### Dwarven Equipment (Regional)

```json
{
  "recipes": [
    {
      "recipe_id": "armor_dwarven",
      "name": "Dwarven Platemail",
      "station": "blacksmith_stonepass",
      "unlock": {"type": "reputation", "faction": "stonepass_dwarves", "level": "honored"},
      "ingredients": [
        {"item_id": "dwarven_steel", "quantity": 8},
        {"item_id": "rune_stone", "quantity": 3},
        {"item_id": "mountain_gem", "quantity": 2}
      ],
      "gold_cost": 600,
      "output": {"item_id": "armor_dwarven"}
    },
    {
      "recipe_id": "helm_forgemaster",
      "name": "Forgemaster's Helm",
      "station": "blacksmith_stonepass",
      "unlock": {"type": "boss_defeated", "boss": "forge_tyrant"},
      "ingredients": [
        {"item_id": "forge_tyrant_essence", "quantity": 1},
        {"item_id": "dwarven_steel", "quantity": 5},
        {"item_id": "fire_ruby", "quantity": 2}
      ],
      "gold_cost": 750,
      "output": {"item_id": "helm_forgemaster"}
    }
  ]
}
```

### Accessories

```json
{
  "recipes": [
    {
      "recipe_id": "amulet_accuracy",
      "name": "Precision Amulet",
      "station": "blacksmith",
      "unlock": {"type": "level", "value": 15},
      "ingredients": [
        {"item_id": "silver_chain", "quantity": 1},
        {"item_id": "sapphire", "quantity": 1},
        {"item_id": "accuracy_essence", "quantity": 2}
      ],
      "gold_cost": 200,
      "output": {"item_id": "amulet_accuracy"}
    },
    {
      "recipe_id": "ring_speed",
      "name": "Ring of Swift Fingers",
      "station": "blacksmith",
      "unlock": {"type": "level", "value": 15},
      "ingredients": [
        {"item_id": "gold_ingot", "quantity": 1},
        {"item_id": "quicksilver", "quantity": 2},
        {"item_id": "wind_essence", "quantity": 1}
      ],
      "gold_cost": 175,
      "output": {"item_id": "ring_speed"}
    },
    {
      "recipe_id": "belt_storage",
      "name": "Adventurer's Belt",
      "station": "blacksmith",
      "unlock": "default",
      "ingredients": [
        {"item_id": "leather", "quantity": 4},
        {"item_id": "iron_buckle", "quantity": 2}
      ],
      "gold_cost": 60,
      "output": {"item_id": "belt_storage"}
    }
  ]
}
```

---

## Alchemist Recipes

### Basic Potions

```json
{
  "recipes": [
    {
      "recipe_id": "potion_healing_minor",
      "name": "Minor Healing Potion",
      "station": "alchemist",
      "unlock": "default",
      "ingredients": [
        {"item_id": "healing_herb", "quantity": 2},
        {"item_id": "water_vial", "quantity": 1}
      ],
      "gold_cost": 15,
      "output": {"item_id": "potion_healing_minor", "quantity": 2}
    },
    {
      "recipe_id": "potion_speed_minor",
      "name": "Minor Speed Potion",
      "station": "alchemist",
      "unlock": "default",
      "ingredients": [
        {"item_id": "swift_root", "quantity": 2},
        {"item_id": "water_vial", "quantity": 1}
      ],
      "gold_cost": 20,
      "output": {"item_id": "potion_speed_minor", "quantity": 2}
    },
    {
      "recipe_id": "potion_accuracy_minor",
      "name": "Minor Accuracy Potion",
      "station": "alchemist",
      "unlock": "default",
      "ingredients": [
        {"item_id": "focus_flower", "quantity": 2},
        {"item_id": "water_vial", "quantity": 1}
      ],
      "gold_cost": 20,
      "output": {"item_id": "potion_accuracy_minor", "quantity": 2}
    }
  ]
}
```

### Standard Potions

```json
{
  "recipes": [
    {
      "recipe_id": "potion_healing",
      "name": "Healing Potion",
      "station": "alchemist",
      "unlock": {"type": "level", "value": 8},
      "ingredients": [
        {"item_id": "healing_herb", "quantity": 4},
        {"item_id": "life_moss", "quantity": 1},
        {"item_id": "purified_water", "quantity": 1}
      ],
      "gold_cost": 40,
      "output": {"item_id": "potion_healing", "quantity": 2}
    },
    {
      "recipe_id": "potion_speed",
      "name": "Speed Potion",
      "station": "alchemist",
      "unlock": {"type": "level", "value": 8},
      "ingredients": [
        {"item_id": "swift_root", "quantity": 4},
        {"item_id": "wind_petal", "quantity": 1},
        {"item_id": "purified_water", "quantity": 1}
      ],
      "gold_cost": 50,
      "output": {"item_id": "potion_speed", "quantity": 2}
    },
    {
      "recipe_id": "potion_accuracy",
      "name": "Accuracy Potion",
      "station": "alchemist",
      "unlock": {"type": "level", "value": 8},
      "ingredients": [
        {"item_id": "focus_flower", "quantity": 4},
        {"item_id": "clarity_crystal", "quantity": 1},
        {"item_id": "purified_water", "quantity": 1}
      ],
      "gold_cost": 50,
      "output": {"item_id": "potion_accuracy", "quantity": 2}
    },
    {
      "recipe_id": "potion_damage",
      "name": "Damage Potion",
      "station": "alchemist",
      "unlock": {"type": "level", "value": 10},
      "ingredients": [
        {"item_id": "rage_pepper", "quantity": 3},
        {"item_id": "fire_essence", "quantity": 1},
        {"item_id": "purified_water", "quantity": 1}
      ],
      "gold_cost": 60,
      "output": {"item_id": "potion_damage", "quantity": 2}
    }
  ]
}
```

### Advanced Potions

```json
{
  "recipes": [
    {
      "recipe_id": "potion_healing_major",
      "name": "Major Healing Potion",
      "station": "alchemist",
      "unlock": {"type": "level", "value": 18},
      "ingredients": [
        {"item_id": "healing_herb", "quantity": 6},
        {"item_id": "life_moss", "quantity": 3},
        {"item_id": "phoenix_feather", "quantity": 1},
        {"item_id": "enchanted_water", "quantity": 1}
      ],
      "gold_cost": 100,
      "output": {"item_id": "potion_healing_major", "quantity": 2}
    },
    {
      "recipe_id": "elixir_perfection",
      "name": "Elixir of Perfection",
      "station": "alchemist",
      "unlock": {"type": "level", "value": 25},
      "ingredients": [
        {"item_id": "potion_speed", "quantity": 1},
        {"item_id": "potion_accuracy", "quantity": 1},
        {"item_id": "words_crystalline_shard", "quantity": 1}
      ],
      "gold_cost": 150,
      "output": {"item_id": "elixir_perfection"}
    },
    {
      "recipe_id": "elixir_forgiveness",
      "name": "Elixir of Second Chances",
      "station": "alchemist",
      "unlock": {"type": "level", "value": 22},
      "ingredients": [
        {"item_id": "time_bloom", "quantity": 2},
        {"item_id": "memory_dew", "quantity": 3},
        {"item_id": "enchanted_water", "quantity": 1}
      ],
      "gold_cost": 120,
      "output": {"item_id": "elixir_forgiveness"}
    }
  ]
}
```

### Bombs & Combat Items

```json
{
  "recipes": [
    {
      "recipe_id": "bomb_fire",
      "name": "Fire Bomb",
      "station": "alchemist",
      "unlock": {"type": "level", "value": 12},
      "ingredients": [
        {"item_id": "sulfur", "quantity": 3},
        {"item_id": "fire_essence", "quantity": 2},
        {"item_id": "clay_pot", "quantity": 1}
      ],
      "gold_cost": 45,
      "output": {"item_id": "bomb_fire", "quantity": 3}
    },
    {
      "recipe_id": "bomb_frost",
      "name": "Frost Bomb",
      "station": "alchemist",
      "unlock": {"type": "level", "value": 12},
      "ingredients": [
        {"item_id": "frost_salt", "quantity": 3},
        {"item_id": "ice_essence", "quantity": 2},
        {"item_id": "clay_pot", "quantity": 1}
      ],
      "gold_cost": 45,
      "output": {"item_id": "bomb_frost", "quantity": 3}
    },
    {
      "recipe_id": "bomb_poison",
      "name": "Poison Bomb",
      "station": "alchemist",
      "unlock": {"type": "level", "value": 15},
      "ingredients": [
        {"item_id": "toxic_spore", "quantity": 4},
        {"item_id": "venom_sac", "quantity": 2},
        {"item_id": "clay_pot", "quantity": 1}
      ],
      "gold_cost": 55,
      "output": {"item_id": "bomb_poison", "quantity": 3}
    },
    {
      "recipe_id": "oil_slick",
      "name": "Slippery Oil",
      "station": "alchemist",
      "unlock": {"type": "level", "value": 10},
      "ingredients": [
        {"item_id": "animal_fat", "quantity": 3},
        {"item_id": "slime_residue", "quantity": 2}
      ],
      "gold_cost": 30,
      "output": {"item_id": "oil_slick", "quantity": 5}
    }
  ]
}
```

### Mistfen Specialties

```json
{
  "recipes": [
    {
      "recipe_id": "potion_clarity",
      "name": "Potion of Clarity",
      "station": "alchemist_mistfen",
      "unlock": {"type": "region_unlocked", "region": "mistfen"},
      "ingredients": [
        {"item_id": "mist_flower", "quantity": 3},
        {"item_id": "clarity_crystal", "quantity": 2},
        {"item_id": "pure_spring_water", "quantity": 1}
      ],
      "gold_cost": 80,
      "output": {"item_id": "potion_clarity"}
    },
    {
      "recipe_id": "antidote_corruption",
      "name": "Corruption Antidote",
      "station": "alchemist_mistfen",
      "unlock": {"type": "quest", "quest_id": "corruption_cure"},
      "ingredients": [
        {"item_id": "purified_heartwood", "quantity": 1},
        {"item_id": "holy_water", "quantity": 2},
        {"item_id": "letter_spirit_tear", "quantity": 1}
      ],
      "gold_cost": 150,
      "output": {"item_id": "antidote_corruption"}
    }
  ]
}
```

---

## Enchanter Recipes

### Basic Enchantments

```json
{
  "recipes": [
    {
      "recipe_id": "enchant_accuracy_1",
      "name": "Lesser Accuracy Enchantment",
      "station": "enchanter",
      "unlock": {"type": "level", "value": 12},
      "ingredients": [
        {"item_id": "accuracy_essence", "quantity": 3},
        {"item_id": "blank_rune", "quantity": 1}
      ],
      "gold_cost": 75,
      "output": {"item_id": "enchant_accuracy_1"},
      "applies_to": ["gloves", "headgear"]
    },
    {
      "recipe_id": "enchant_speed_1",
      "name": "Lesser Speed Enchantment",
      "station": "enchanter",
      "unlock": {"type": "level", "value": 12},
      "ingredients": [
        {"item_id": "wind_essence", "quantity": 3},
        {"item_id": "blank_rune", "quantity": 1}
      ],
      "gold_cost": 75,
      "output": {"item_id": "enchant_speed_1"},
      "applies_to": ["boots", "gloves"]
    },
    {
      "recipe_id": "enchant_defense_1",
      "name": "Lesser Defense Enchantment",
      "station": "enchanter",
      "unlock": {"type": "level", "value": 12},
      "ingredients": [
        {"item_id": "earth_essence", "quantity": 3},
        {"item_id": "blank_rune", "quantity": 1}
      ],
      "gold_cost": 75,
      "output": {"item_id": "enchant_defense_1"},
      "applies_to": ["armor", "headgear"]
    }
  ]
}
```

### Advanced Enchantments

```json
{
  "recipes": [
    {
      "recipe_id": "enchant_accuracy_3",
      "name": "Greater Accuracy Enchantment",
      "station": "enchanter",
      "unlock": {"type": "level", "value": 25},
      "ingredients": [
        {"item_id": "accuracy_essence", "quantity": 8},
        {"item_id": "enchanted_rune", "quantity": 1},
        {"item_id": "sapphire", "quantity": 1}
      ],
      "gold_cost": 250,
      "output": {"item_id": "enchant_accuracy_3"}
    },
    {
      "recipe_id": "enchant_combo",
      "name": "Combo Extension Enchantment",
      "station": "enchanter",
      "unlock": {"type": "level", "value": 22},
      "ingredients": [
        {"item_id": "chain_links", "quantity": 5},
        {"item_id": "time_essence", "quantity": 3},
        {"item_id": "enchanted_rune", "quantity": 1}
      ],
      "gold_cost": 200,
      "output": {"item_id": "enchant_combo"}
    },
    {
      "recipe_id": "enchant_critical",
      "name": "Critical Strike Enchantment",
      "station": "enchanter",
      "unlock": {"type": "level", "value": 20},
      "ingredients": [
        {"item_id": "sharpness_crystal", "quantity": 3},
        {"item_id": "blood_ruby", "quantity": 1},
        {"item_id": "enchanted_rune", "quantity": 1}
      ],
      "gold_cost": 225,
      "output": {"item_id": "enchant_critical"}
    }
  ]
}
```

### Scrolls

```json
{
  "recipes": [
    {
      "recipe_id": "scroll_damage",
      "name": "Scroll of Power",
      "station": "enchanter",
      "unlock": {"type": "level", "value": 15},
      "ingredients": [
        {"item_id": "blank_scroll", "quantity": 1},
        {"item_id": "fire_essence", "quantity": 2},
        {"item_id": "magic_ink", "quantity": 1}
      ],
      "gold_cost": 50,
      "output": {"item_id": "scroll_damage", "quantity": 2}
    },
    {
      "recipe_id": "scroll_protection",
      "name": "Scroll of Protection",
      "station": "enchanter",
      "unlock": {"type": "level", "value": 15},
      "ingredients": [
        {"item_id": "blank_scroll", "quantity": 1},
        {"item_id": "earth_essence", "quantity": 2},
        {"item_id": "magic_ink", "quantity": 1}
      ],
      "gold_cost": 50,
      "output": {"item_id": "scroll_protection", "quantity": 2}
    },
    {
      "recipe_id": "scroll_purification",
      "name": "Scroll of Purification",
      "station": "enchanter",
      "unlock": {"type": "level", "value": 20},
      "ingredients": [
        {"item_id": "blank_scroll", "quantity": 1},
        {"item_id": "holy_water", "quantity": 1},
        {"item_id": "light_essence", "quantity": 3},
        {"item_id": "magic_ink", "quantity": 1}
      ],
      "gold_cost": 100,
      "output": {"item_id": "scroll_purification"}
    },
    {
      "recipe_id": "scroll_teleport",
      "name": "Scroll of Teleportation",
      "station": "enchanter",
      "unlock": {"type": "level", "value": 25},
      "ingredients": [
        {"item_id": "blank_scroll", "quantity": 1},
        {"item_id": "void_essence", "quantity": 2},
        {"item_id": "spatial_crystal", "quantity": 1},
        {"item_id": "magic_ink", "quantity": 2}
      ],
      "gold_cost": 200,
      "output": {"item_id": "scroll_teleport"}
    }
  ]
}
```

---

## Scribe Recipes

### Typing Aids

```json
{
  "recipes": [
    {
      "recipe_id": "word_guide",
      "name": "Word Guide",
      "station": "scribe",
      "unlock": "default",
      "ingredients": [
        {"item_id": "paper", "quantity": 5},
        {"item_id": "ink", "quantity": 2},
        {"item_id": "leather_binding", "quantity": 1}
      ],
      "gold_cost": 30,
      "output": {"item_id": "word_guide"}
    },
    {
      "recipe_id": "advanced_word_guide",
      "name": "Advanced Word Guide",
      "station": "scribe",
      "unlock": {"type": "level", "value": 15},
      "ingredients": [
        {"item_id": "enchanted_paper", "quantity": 10},
        {"item_id": "magic_ink", "quantity": 3},
        {"item_id": "enchanted_binding", "quantity": 1}
      ],
      "gold_cost": 150,
      "output": {"item_id": "advanced_word_guide"}
    }
  ]
}
```

### Special Books

```json
{
  "recipes": [
    {
      "recipe_id": "codex_enemies",
      "name": "Enemy Codex",
      "station": "scribe",
      "unlock": {"type": "quest", "quest_id": "knowledge_seeker"},
      "ingredients": [
        {"item_id": "enchanted_paper", "quantity": 20},
        {"item_id": "monster_essence", "quantity": 5},
        {"item_id": "scholar_binding", "quantity": 1}
      ],
      "gold_cost": 200,
      "output": {"item_id": "codex_enemies"}
    },
    {
      "recipe_id": "codex_towers",
      "name": "Tower Codex",
      "station": "scribe",
      "unlock": {"type": "quest", "quest_id": "architect_apprentice"},
      "ingredients": [
        {"item_id": "enchanted_paper", "quantity": 15},
        {"item_id": "tower_blueprint", "quantity": 3},
        {"item_id": "scholar_binding", "quantity": 1}
      ],
      "gold_cost": 175,
      "output": {"item_id": "codex_towers"}
    },
    {
      "recipe_id": "lore_compilation",
      "name": "Lore Compilation",
      "station": "scribe",
      "unlock": {"type": "lore_collected", "value": 25},
      "ingredients": [
        {"item_id": "lore_page", "quantity": 10},
        {"item_id": "enchanted_paper", "quantity": 5},
        {"item_id": "master_binding", "quantity": 1}
      ],
      "gold_cost": 300,
      "output": {"item_id": "lore_compilation"}
    }
  ]
}
```

---

## Special Recipes

### Quest Rewards

```json
{
  "recipes": [
    {
      "recipe_id": "keystos_keyboard",
      "name": "Keystos's Keyboard Replica",
      "station": "special",
      "unlock": {"type": "quest_chain", "chain_id": "legend_of_keystos"},
      "ingredients": [
        {"item_id": "words_crystalline", "quantity": 10},
        {"item_id": "ancient_keysteel", "quantity": 5},
        {"item_id": "letter_spirit_blessing", "quantity": 5},
        {"item_id": "perfect_word_shard", "quantity": 1}
      ],
      "gold_cost": 5000,
      "output": {"item_id": "keystos_keyboard"}
    }
  ]
}
```

### Set Pieces

```json
{
  "recipes": [
    {
      "recipe_id": "set_defender_helm",
      "name": "Defender's Helm",
      "station": "blacksmith",
      "unlock": {"type": "achievement", "achievement_id": "defender_order_rank_5"},
      "ingredients": [
        {"item_id": "keysteel_ingot", "quantity": 4},
        {"item_id": "defender_crest", "quantity": 1},
        {"item_id": "protection_essence", "quantity": 3}
      ],
      "gold_cost": 400,
      "output": {"item_id": "set_defender_helm"},
      "set_id": "defender_set"
    },
    {
      "recipe_id": "set_defender_armor",
      "name": "Defender's Plate",
      "station": "blacksmith",
      "unlock": {"type": "achievement", "achievement_id": "defender_order_rank_5"},
      "ingredients": [
        {"item_id": "keysteel_ingot", "quantity": 8},
        {"item_id": "defender_crest", "quantity": 2},
        {"item_id": "protection_essence", "quantity": 5}
      ],
      "gold_cost": 600,
      "output": {"item_id": "set_defender_armor"},
      "set_id": "defender_set"
    },
    {
      "recipe_id": "set_defender_gloves",
      "name": "Defender's Gauntlets",
      "station": "blacksmith",
      "unlock": {"type": "achievement", "achievement_id": "defender_order_rank_5"},
      "ingredients": [
        {"item_id": "keysteel_ingot", "quantity": 3},
        {"item_id": "defender_crest", "quantity": 1},
        {"item_id": "accuracy_essence", "quantity": 4}
      ],
      "gold_cost": 350,
      "output": {"item_id": "set_defender_gloves"},
      "set_id": "defender_set"
    },
    {
      "recipe_id": "set_defender_boots",
      "name": "Defender's Greaves",
      "station": "blacksmith",
      "unlock": {"type": "achievement", "achievement_id": "defender_order_rank_5"},
      "ingredients": [
        {"item_id": "keysteel_ingot", "quantity": 3},
        {"item_id": "defender_crest", "quantity": 1},
        {"item_id": "speed_essence", "quantity": 3}
      ],
      "gold_cost": 350,
      "output": {"item_id": "set_defender_boots"},
      "set_id": "defender_set"
    }
  ]
}
```

### Material Refinement

```json
{
  "recipes": [
    {
      "recipe_id": "refine_iron_to_steel",
      "name": "Steel Ingot",
      "station": "blacksmith",
      "unlock": "default",
      "ingredients": [
        {"item_id": "iron_ingot", "quantity": 2},
        {"item_id": "coal", "quantity": 1}
      ],
      "gold_cost": 10,
      "output": {"item_id": "steel_ingot"}
    },
    {
      "recipe_id": "refine_steel_to_keysteel",
      "name": "Keysteel Ingot",
      "station": "blacksmith_stonepass",
      "unlock": {"type": "level", "value": 18},
      "ingredients": [
        {"item_id": "steel_ingot", "quantity": 3},
        {"item_id": "letter_essence", "quantity": 2},
        {"item_id": "dwarven_flux", "quantity": 1}
      ],
      "gold_cost": 50,
      "output": {"item_id": "keysteel_ingot"}
    },
    {
      "recipe_id": "purify_water",
      "name": "Purified Water",
      "station": "alchemist",
      "unlock": "default",
      "ingredients": [
        {"item_id": "water_vial", "quantity": 3},
        {"item_id": "purification_salt", "quantity": 1}
      ],
      "gold_cost": 5,
      "output": {"item_id": "purified_water", "quantity": 2}
    },
    {
      "recipe_id": "enchant_water",
      "name": "Enchanted Water",
      "station": "enchanter",
      "unlock": {"type": "level", "value": 15},
      "ingredients": [
        {"item_id": "purified_water", "quantity": 2},
        {"item_id": "magic_essence", "quantity": 1}
      ],
      "gold_cost": 20,
      "output": {"item_id": "enchanted_water"}
    },
    {
      "recipe_id": "blank_rune",
      "name": "Blank Rune",
      "station": "enchanter",
      "unlock": "default",
      "ingredients": [
        {"item_id": "stone_shard", "quantity": 3},
        {"item_id": "magic_dust", "quantity": 1}
      ],
      "gold_cost": 15,
      "output": {"item_id": "blank_rune", "quantity": 2}
    },
    {
      "recipe_id": "enchanted_rune",
      "name": "Enchanted Rune",
      "station": "enchanter",
      "unlock": {"type": "level", "value": 18},
      "ingredients": [
        {"item_id": "blank_rune", "quantity": 2},
        {"item_id": "magic_essence", "quantity": 3}
      ],
      "gold_cost": 40,
      "output": {"item_id": "enchanted_rune"}
    }
  ]
}
```

---

## Material Acquisition

### Drop Sources

```json
{
  "material_sources": {
    "iron_ingot": {
      "sources": [
        {"type": "enemy_drop", "enemies": ["tier_1", "tier_2"], "drop_rate": 0.15},
        {"type": "mining", "locations": ["stonepass"]},
        {"type": "merchant", "merchant_id": "blacksmith_garrett", "price": 15}
      ]
    },
    "healing_herb": {
      "sources": [
        {"type": "gathering", "locations": ["evergrove"], "skill_required": "herbalism_1"},
        {"type": "merchant", "merchant_id": "merchant_elise", "price": 5}
      ]
    },
    "letter_essence": {
      "sources": [
        {"type": "enemy_drop", "enemies": ["tier_3", "tier_4"], "drop_rate": 0.10},
        {"type": "shrine_blessing", "shrines": ["any_letter_spirit"]}
      ]
    },
    "words_crystalline": {
      "sources": [
        {"type": "boss_drop", "bosses": ["all"], "drop_rate": 0.20},
        {"type": "quest_reward", "quests": ["legendary_quests"]},
        {"type": "mining", "locations": ["stonepass_deep_mines"], "rare": true}
      ]
    },
    "guardian_heartwood": {
      "sources": [
        {"type": "boss_drop", "boss": "grove_guardian", "drop_rate": 1.0}
      ]
    },
    "archmage_essence": {
      "sources": [
        {"type": "boss_drop", "boss": "mist_wraith", "drop_rate": 0.5},
        {"type": "alternate_boss_drop", "boss": "mist_wraith", "condition": "redemption", "drop_rate": 1.0}
      ]
    }
  }
}
```

### Gathering Locations

```json
{
  "gathering_nodes": {
    "evergrove": {
      "herbs": ["healing_herb", "swift_root", "focus_flower", "mist_flower"],
      "special": ["life_moss", "ancient_bark"]
    },
    "stonepass": {
      "ores": ["iron_ore", "steel_ore", "gold_ore", "keysteel_ore"],
      "gems": ["sapphire", "ruby", "diamond"],
      "special": ["dwarven_steel", "rune_stone"]
    },
    "mistfen": {
      "herbs": ["toxic_spore", "time_bloom", "clarity_crystal"],
      "magical": ["magic_essence", "void_essence", "mist_essence"]
    }
  }
}
```

---

## Implementation

```gdscript
class_name CraftingSystem
extends Node

signal recipe_crafted(recipe: Recipe, result: Item)
signal crafting_failed(recipe: Recipe, reason: String)

var known_recipes: Dictionary = {}
var crafting_queue: Array[CraftingJob] = []

func can_craft(recipe_id: String) -> Dictionary:
    var recipe = known_recipes.get(recipe_id)
    if not recipe:
        return {"can_craft": false, "reason": "Recipe not known"}

    # Check ingredients
    for ingredient in recipe.ingredients:
        var owned = Inventory.get_item_count(ingredient.item_id)
        if owned < ingredient.quantity:
            return {
                "can_craft": false,
                "reason": "Missing %s (need %d, have %d)" % [
                    ingredient.item_id, ingredient.quantity, owned
                ]
            }

    # Check gold
    if PlayerData.gold < recipe.gold_cost:
        return {"can_craft": false, "reason": "Insufficient gold"}

    # Check unlock requirements
    if not check_unlock(recipe.unlock_requirement):
        return {"can_craft": false, "reason": "Recipe locked"}

    return {"can_craft": true}

func craft(recipe_id: String) -> void:
    var check = can_craft(recipe_id)
    if not check.can_craft:
        crafting_failed.emit(known_recipes[recipe_id], check.reason)
        return

    var recipe = known_recipes[recipe_id]

    # Consume ingredients
    for ingredient in recipe.ingredients:
        Inventory.remove_item(ingredient.item_id, ingredient.quantity)

    # Consume gold
    PlayerData.spend_gold(recipe.gold_cost)

    # Create output
    var result = create_item(recipe.output)

    # Apply quality variance if applicable
    if recipe.output.get("quality_variance", false):
        result = apply_quality_variance(result)

    Inventory.add_item(result)
    recipe_crafted.emit(recipe, result)
```

---

**Document version:** 1.0
**Total recipes:** 75+
**Crafting stations:** 4
**Material types:** 50+
