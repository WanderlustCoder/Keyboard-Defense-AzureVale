# Complete Item Catalog

**Created:** 2026-01-08

Full catalog of all equipment, consumables, materials, and special items.

---

## Equipment - Headgear (15 items)

### Common Headgear

```json
[
  {
    "id": "helm_cloth_cap",
    "name": "Cloth Cap",
    "slot": "headgear",
    "rarity": "common",
    "stats": {"defense": 1},
    "effect": null,
    "description": "A simple cloth cap offering minimal protection.",
    "sell_value": 5,
    "drop_sources": ["early_enemies", "shop"]
  },
  {
    "id": "helm_leather",
    "name": "Leather Helm",
    "slot": "headgear",
    "rarity": "common",
    "stats": {"defense": 2},
    "effect": null,
    "description": "Sturdy leather headwear for beginning adventurers.",
    "sell_value": 10,
    "drop_sources": ["tier_1_enemies", "shop"]
  },
  {
    "id": "helm_iron",
    "name": "Iron Cap",
    "slot": "headgear",
    "rarity": "common",
    "stats": {"defense": 3},
    "effect": null,
    "description": "A basic iron helmet.",
    "sell_value": 15,
    "drop_sources": ["tier_2_enemies", "shop"]
  }
]
```

### Uncommon Headgear

```json
[
  {
    "id": "helm_focus",
    "name": "Scholar's Hood",
    "slot": "headgear",
    "rarity": "uncommon",
    "stats": {"accuracy_bonus": 0.03, "defense": 2},
    "effect": null,
    "description": "A hood favored by scholars, enhancing mental focus.",
    "sell_value": 25,
    "drop_sources": ["citadel_enemies", "quest_reward"],
    "flavor": "Knowledge is the sharpest weapon."
  },
  {
    "id": "helm_scout",
    "name": "Scout's Cap",
    "slot": "headgear",
    "rarity": "uncommon",
    "stats": {"wpm_bonus": 1, "defense": 2},
    "effect": {
      "name": "Quick Eyes",
      "description": "Enemy words revealed 0.5s earlier"
    },
    "sell_value": 30,
    "drop_sources": ["evergrove_enemies", "ranger_thorne_quest"]
  },
  {
    "id": "helm_warrior",
    "name": "Warrior's Helm",
    "slot": "headgear",
    "rarity": "uncommon",
    "stats": {"defense": 5},
    "effect": {
      "name": "Battle Hardened",
      "description": "+5 max castle HP"
    },
    "sell_value": 35,
    "drop_sources": ["stonepass_enemies"]
  },
  {
    "id": "helm_mystic",
    "name": "Mystic's Circlet",
    "slot": "headgear",
    "rarity": "uncommon",
    "stats": {"accuracy_bonus": 0.02, "tower_damage_bonus": 0.05},
    "effect": null,
    "sell_value": 40,
    "drop_sources": ["mistfen_enemies", "hermit_quest"]
  }
]
```

### Rare Headgear

```json
[
  {
    "id": "helm_speed",
    "name": "Windrunner Helm",
    "slot": "headgear",
    "rarity": "rare",
    "stats": {"wpm_bonus": 3, "defense": 3},
    "effect": {
      "name": "Tailwind",
      "description": "First word of each wave typed 20% faster"
    },
    "sell_value": 75,
    "drop_sources": ["sunfields_boss", "arena_champion"],
    "flavor": "Blessed by wind spirits for swift action."
  },
  {
    "id": "helm_precision",
    "name": "Marksman's Visor",
    "slot": "headgear",
    "rarity": "rare",
    "stats": {"accuracy_bonus": 0.06, "defense": 2},
    "effect": {
      "name": "Steady Aim",
      "description": "Tower accuracy +15%"
    },
    "sell_value": 80,
    "drop_sources": ["corrupted_archer_champion"]
  },
  {
    "id": "helm_forest",
    "name": "Grove Warden's Crown",
    "slot": "headgear",
    "rarity": "rare",
    "stats": {"defense": 4, "hp_regen": 0.5},
    "effect": {
      "name": "Nature's Blessing",
      "description": "Heal 1 HP every 60s in Evergrove"
    },
    "sell_value": 85,
    "drop_sources": ["grove_guardian_boss"]
  },
  {
    "id": "helm_berserker",
    "name": "Berserker's Mask",
    "slot": "headgear",
    "rarity": "rare",
    "stats": {"wpm_bonus": 4, "defense": 1},
    "effect": {
      "name": "Blood Rage",
      "description": "+10% damage when castle HP < 50%"
    },
    "sell_value": 70,
    "drop_sources": ["chaos_berserker_champion"]
  }
]
```

### Epic Headgear

```json
[
  {
    "id": "helm_void",
    "name": "Crown of Clarity",
    "slot": "headgear",
    "rarity": "epic",
    "stats": {"accuracy_bonus": 0.08, "defense": 5, "wpm_bonus": 2},
    "effect": {
      "name": "Clear Mind",
      "description": "Immune to word scrambling effects"
    },
    "sell_value": 200,
    "drop_sources": ["void_assassin_champion", "fen_seer_boss"],
    "flavor": "Protects the mind from void corruption."
  },
  {
    "id": "helm_flame",
    "name": "Inferno Crown",
    "slot": "headgear",
    "rarity": "epic",
    "stats": {"wpm_bonus": 5, "defense": 3},
    "effect": {
      "name": "Burning Speed",
      "description": "+25% WPM for 5s after perfect word"
    },
    "sell_value": 220,
    "drop_sources": ["flame_tyrant_boss"]
  },
  {
    "id": "helm_frost",
    "name": "Frostbound Crown",
    "slot": "headgear",
    "rarity": "epic",
    "stats": {"accuracy_bonus": 0.10, "defense": 4},
    "effect": {
      "name": "Frozen Focus",
      "description": "Mistakes don't break combo (5s cooldown)"
    },
    "sell_value": 220,
    "drop_sources": ["frost_empress_boss"]
  }
]
```

### Legendary Headgear

```json
[
  {
    "id": "helm_legendary",
    "name": "First Typist's Circlet",
    "slot": "headgear",
    "rarity": "legendary",
    "stats": {"accuracy_bonus": 0.15, "wpm_bonus": 5, "defense": 6},
    "effect": {
      "name": "Ancient Knowledge",
      "description": "All lessons count as mastered for word selection"
    },
    "sell_value": 500,
    "drop_sources": ["void_tyrant_boss"],
    "lore": "Worn by the First Typist in the Age of Writing. Its power resonates with ancient keystrokes.",
    "unique": true
  },
  {
    "id": "helm_champion",
    "name": "Eternal Champion's Crown",
    "slot": "headgear",
    "rarity": "legendary",
    "stats": {"wpm_bonus": 8, "accuracy_bonus": 0.05, "defense": 5},
    "effect": {
      "name": "Unbreakable Will",
      "description": "Combo counter never drops below 5"
    },
    "sell_value": 450,
    "drop_sources": ["achievement_arena_legend"],
    "unique": true
  }
]
```

---

## Equipment - Armor (15 items)

### Common Armor

```json
[
  {
    "id": "armor_cloth",
    "name": "Cloth Robes",
    "slot": "armor",
    "rarity": "common",
    "stats": {"defense": 3},
    "sell_value": 8
  },
  {
    "id": "armor_leather",
    "name": "Leather Vest",
    "slot": "armor",
    "rarity": "common",
    "stats": {"defense": 5},
    "sell_value": 15
  },
  {
    "id": "armor_chain",
    "name": "Chainmail",
    "slot": "armor",
    "rarity": "common",
    "stats": {"defense": 8},
    "sell_value": 25
  }
]
```

### Uncommon Armor

```json
[
  {
    "id": "armor_scribe",
    "name": "Scribe's Vestments",
    "slot": "armor",
    "rarity": "uncommon",
    "stats": {"defense": 6, "gold_bonus": 0.05, "xp_bonus": 0.05},
    "effect": null,
    "description": "Traditional garb of the Order of Scribes.",
    "sell_value": 40
  },
  {
    "id": "armor_ranger",
    "name": "Ranger's Leather",
    "slot": "armor",
    "rarity": "uncommon",
    "stats": {"defense": 7, "accuracy_bonus": 0.02},
    "effect": {
      "name": "Forest Movement",
      "description": "+10% movement speed in Evergrove"
    },
    "sell_value": 45
  },
  {
    "id": "armor_guard",
    "name": "Guard's Plate",
    "slot": "armor",
    "rarity": "uncommon",
    "stats": {"defense": 10},
    "effect": {
      "name": "Stalwart",
      "description": "Reduce castle damage by 1 (minimum 1)"
    },
    "sell_value": 50
  }
]
```

### Rare Armor

```json
[
  {
    "id": "armor_warrior",
    "name": "Knight's Plate",
    "slot": "armor",
    "rarity": "rare",
    "stats": {"defense": 15},
    "effect": {
      "name": "Steadfast",
      "description": "Reduce castle damage taken by 20%"
    },
    "sell_value": 100
  },
  {
    "id": "armor_mage",
    "name": "Battlemage Robes",
    "slot": "armor",
    "rarity": "rare",
    "stats": {"defense": 8, "tower_damage_bonus": 0.10},
    "effect": {
      "name": "Arcane Synergy",
      "description": "Arcane towers deal +15% damage"
    },
    "sell_value": 110
  },
  {
    "id": "armor_assassin",
    "name": "Shadow Leathers",
    "slot": "armor",
    "rarity": "rare",
    "stats": {"defense": 6, "wpm_bonus": 3},
    "effect": {
      "name": "Quick Strike",
      "description": "First 3 enemies each wave take +20% damage"
    },
    "sell_value": 95
  }
]
```

### Epic Armor

```json
[
  {
    "id": "armor_arcane",
    "name": "Archmage Robes",
    "slot": "armor",
    "rarity": "epic",
    "stats": {"defense": 10, "tower_damage_bonus": 0.15, "accuracy_bonus": 0.03},
    "effect": {
      "name": "Empowerment",
      "description": "All towers deal +20% damage"
    },
    "sell_value": 250
  },
  {
    "id": "armor_champion",
    "name": "Champion's Plate",
    "slot": "armor",
    "rarity": "epic",
    "stats": {"defense": 18, "combo_bonus": 0.10},
    "effect": {
      "name": "Glory",
      "description": "Gain 1 gold for every 10 combo"
    },
    "sell_value": 275
  },
  {
    "id": "armor_nature",
    "name": "Treant Bark Armor",
    "slot": "armor",
    "rarity": "epic",
    "stats": {"defense": 12, "hp_regen": 1},
    "effect": {
      "name": "Living Armor",
      "description": "Regenerate 2 castle HP every 30s"
    },
    "sell_value": 260
  }
]
```

### Legendary Armor

```json
[
  {
    "id": "armor_legendary",
    "name": "Armor of the True Typist",
    "slot": "armor",
    "rarity": "legendary",
    "stats": {"defense": 20, "accuracy_bonus": 0.05, "wpm_bonus": 3, "all_bonus": 0.10},
    "effect": {
      "name": "Prophecy Fulfilled",
      "description": "Perfect words heal castle for 1 HP"
    },
    "sell_value": 600,
    "unique": true
  },
  {
    "id": "armor_void_conqueror",
    "name": "Void Conqueror's Mail",
    "slot": "armor",
    "rarity": "legendary",
    "stats": {"defense": 22, "void_resistance": 0.25},
    "effect": {
      "name": "Void Immunity",
      "description": "Immune to all void debuffs, +30% damage to void enemies"
    },
    "sell_value": 550,
    "unique": true
  }
]
```

---

## Equipment - Gloves (12 items)

### Common to Rare Gloves

```json
[
  {
    "id": "gloves_cloth",
    "name": "Cloth Gloves",
    "rarity": "common",
    "stats": {"accuracy_bonus": 0.01},
    "sell_value": 5
  },
  {
    "id": "gloves_leather",
    "name": "Leather Gloves",
    "rarity": "common",
    "stats": {"accuracy_bonus": 0.02},
    "sell_value": 10
  },
  {
    "id": "gloves_typing",
    "name": "Typing Gloves",
    "rarity": "uncommon",
    "stats": {"accuracy_bonus": 0.03, "wpm_bonus": 1},
    "sell_value": 25
  },
  {
    "id": "gloves_swift",
    "name": "Quicksilver Gloves",
    "rarity": "uncommon",
    "stats": {"wpm_bonus": 2},
    "effect": {
      "name": "Fleet Fingers",
      "description": "+5% attack speed for towers"
    },
    "sell_value": 35
  },
  {
    "id": "gloves_precision",
    "name": "Surgeon's Touch",
    "rarity": "rare",
    "stats": {"accuracy_bonus": 0.08},
    "effect": {
      "name": "Precise Strike",
      "description": "20% chance for critical hit (2x damage) on perfect words"
    },
    "sell_value": 90
  },
  {
    "id": "gloves_fire",
    "name": "Emberweave Gloves",
    "rarity": "rare",
    "stats": {"wpm_bonus": 4},
    "effect": {
      "name": "Burning Touch",
      "description": "Enemies you damage burn for 1 DPS for 2s"
    },
    "sell_value": 95
  }
]
```

### Epic and Legendary Gloves

```json
[
  {
    "id": "gloves_ice",
    "name": "Frostweave Gloves",
    "rarity": "epic",
    "stats": {"accuracy_bonus": 0.05, "defense": 3},
    "effect": {
      "name": "Ice Grip",
      "description": "Immune to ice terrain penalty, +20% damage to frozen enemies"
    },
    "sell_value": 200
  },
  {
    "id": "gloves_void",
    "name": "Gloves of the Void Walker",
    "rarity": "epic",
    "stats": {"accuracy_bonus": 0.06, "wpm_bonus": 3},
    "effect": {
      "name": "Phase Touch",
      "description": "Typing damage ignores enemy armor"
    },
    "sell_value": 220
  },
  {
    "id": "gloves_legendary",
    "name": "Hands of the Master",
    "rarity": "legendary",
    "stats": {"wpm_bonus": 8, "accuracy_bonus": 0.10},
    "effect": {
      "name": "Perfect Form",
      "description": "Backspace doesn't break combo, mistakes only reduce combo by 1"
    },
    "sell_value": 500,
    "unique": true
  }
]
```

---

## Equipment - Boots (10 items)

```json
[
  {
    "id": "boots_cloth",
    "name": "Cloth Shoes",
    "rarity": "common",
    "stats": {"movement_bonus": 0.05},
    "sell_value": 5
  },
  {
    "id": "boots_leather",
    "name": "Leather Boots",
    "rarity": "common",
    "stats": {"movement_bonus": 0.10},
    "sell_value": 12
  },
  {
    "id": "boots_traveler",
    "name": "Traveler's Boots",
    "rarity": "uncommon",
    "stats": {"movement_bonus": 0.15},
    "effect": {
      "name": "Long Road",
      "description": "+10% gold from exploration"
    },
    "sell_value": 30
  },
  {
    "id": "boots_swamp",
    "name": "Marsh Waders",
    "rarity": "uncommon",
    "stats": {"movement_bonus": 0.10},
    "effect": {
      "name": "Swamp Walker",
      "description": "Immune to swamp terrain penalty"
    },
    "sell_value": 35
  },
  {
    "id": "boots_mountain",
    "name": "Climbing Boots",
    "rarity": "rare",
    "stats": {"movement_bonus": 0.15},
    "effect": {
      "name": "Sure Footed",
      "description": "Immune to mountain terrain penalty, no altitude sickness"
    },
    "sell_value": 85
  },
  {
    "id": "boots_fire",
    "name": "Firewalkers",
    "rarity": "rare",
    "stats": {"movement_bonus": 0.20},
    "effect": {
      "name": "Heat Shield",
      "description": "Immune to lava terrain damage"
    },
    "sell_value": 100
  },
  {
    "id": "boots_shadow",
    "name": "Shadowstep Boots",
    "rarity": "epic",
    "stats": {"movement_bonus": 0.25, "wpm_bonus": 2},
    "effect": {
      "name": "Flicker",
      "description": "5% chance to instantly complete a word on first letter"
    },
    "sell_value": 200
  },
  {
    "id": "boots_legendary",
    "name": "Boots of the Wind",
    "rarity": "legendary",
    "stats": {"movement_bonus": 0.30, "wpm_bonus": 5},
    "effect": {
      "name": "Windstep",
      "description": "Ignore all terrain movement penalties"
    },
    "sell_value": 450,
    "unique": true
  }
]
```

---

## Equipment - Accessories (20 items)

### Amulets

```json
[
  {
    "id": "amulet_copper",
    "name": "Copper Pendant",
    "slot": "amulet",
    "rarity": "common",
    "stats": {"xp_bonus": 0.03},
    "sell_value": 10
  },
  {
    "id": "amulet_silver",
    "name": "Silver Charm",
    "slot": "amulet",
    "rarity": "uncommon",
    "stats": {"xp_bonus": 0.08},
    "sell_value": 30
  },
  {
    "id": "amulet_wisdom",
    "name": "Pendant of Wisdom",
    "slot": "amulet",
    "rarity": "rare",
    "stats": {"xp_bonus": 0.15},
    "effect": {
      "name": "Scholar's Insight",
      "description": "+25% lesson progress rate"
    },
    "sell_value": 100
  },
  {
    "id": "amulet_focus",
    "name": "Amulet of Focus",
    "slot": "amulet",
    "rarity": "epic",
    "stats": {"accuracy_bonus": 0.08, "xp_bonus": 0.10},
    "effect": {
      "name": "Zen State",
      "description": "After 10 perfect words, gain +5% all stats for 30s"
    },
    "sell_value": 200
  },
  {
    "id": "amulet_legendary",
    "name": "Heart of the First Word",
    "slot": "amulet",
    "rarity": "legendary",
    "stats": {"all_bonus": 0.10},
    "effect": {
      "name": "Primordial Power",
      "description": "All typing damage increased by 25%"
    },
    "sell_value": 500,
    "unique": true
  }
]
```

### Rings

```json
[
  {
    "id": "ring_iron",
    "name": "Iron Ring",
    "slot": "ring",
    "rarity": "common",
    "stats": {"defense": 1},
    "sell_value": 8
  },
  {
    "id": "ring_silver",
    "name": "Silver Band",
    "slot": "ring",
    "rarity": "uncommon",
    "stats": {"gold_bonus": 0.05},
    "sell_value": 25
  },
  {
    "id": "ring_combo",
    "name": "Band of Momentum",
    "slot": "ring",
    "rarity": "epic",
    "stats": {"combo_bonus": 0.20},
    "effect": {
      "name": "Momentum",
      "description": "Combo counter decreases 50% slower when idle"
    },
    "sell_value": 180
  },
  {
    "id": "ring_legendary",
    "name": "Ring of Infinite Letters",
    "slot": "ring",
    "rarity": "legendary",
    "stats": {"wpm_bonus": 6, "accuracy_bonus": 0.06},
    "effect": {
      "name": "Endless Flow",
      "description": "Perfect words have 10% chance to not consume word (enemy still damaged)"
    },
    "sell_value": 450,
    "unique": true
  }
]
```

### Belts

```json
[
  {
    "id": "belt_leather",
    "name": "Leather Belt",
    "slot": "belt",
    "rarity": "common",
    "stats": {"inventory_slots": 2},
    "sell_value": 10
  },
  {
    "id": "belt_fortune",
    "name": "Merchant's Sash",
    "slot": "belt",
    "rarity": "uncommon",
    "stats": {"gold_bonus": 0.10},
    "effect": {
      "name": "Lucky Find",
      "description": "+5% item drop chance"
    },
    "sell_value": 40
  },
  {
    "id": "belt_adventure",
    "name": "Adventurer's Belt",
    "slot": "belt",
    "rarity": "rare",
    "stats": {"inventory_slots": 4, "gold_bonus": 0.08},
    "effect": {
      "name": "Well Prepared",
      "description": "Consumables 20% more effective"
    },
    "sell_value": 90
  }
]
```

### Capes

```json
[
  {
    "id": "cape_cloth",
    "name": "Simple Cloak",
    "slot": "cape",
    "rarity": "common",
    "stats": {"defense": 2},
    "sell_value": 12
  },
  {
    "id": "cape_ranger",
    "name": "Ranger's Cloak",
    "slot": "cape",
    "rarity": "uncommon",
    "stats": {"defense": 4, "accuracy_bonus": 0.02},
    "effect": {
      "name": "Camouflage",
      "description": "Enemies target towers 20% more often"
    },
    "sell_value": 45
  },
  {
    "id": "cape_royal",
    "name": "Royal Cape",
    "slot": "cape",
    "rarity": "rare",
    "stats": {"defense": 6, "gold_bonus": 0.15},
    "effect": {
      "name": "Regal Presence",
      "description": "Shop prices reduced by 10%"
    },
    "sell_value": 110
  },
  {
    "id": "cape_void",
    "name": "Voidwalker's Mantle",
    "slot": "cape",
    "rarity": "legendary",
    "stats": {"defense": 15, "void_resistance": 0.50},
    "effect": {
      "name": "Void Resistance",
      "description": "Immune to all void debuffs"
    },
    "sell_value": 450,
    "unique": true
  }
]
```

---

## Consumables - Potions (15 types)

```json
{
  "potions": [
    {
      "id": "potion_health_minor",
      "name": "Minor Health Potion",
      "rarity": "common",
      "effect": "Restore 10 castle HP",
      "heal_amount": 10,
      "cost": 15,
      "sell_value": 5,
      "stack_max": 20,
      "craft_recipe": {"herbs": 2, "water": 1}
    },
    {
      "id": "potion_health_small",
      "name": "Small Health Potion",
      "rarity": "common",
      "effect": "Restore 20 castle HP",
      "heal_amount": 20,
      "cost": 30,
      "sell_value": 10,
      "stack_max": 15
    },
    {
      "id": "potion_health_medium",
      "name": "Health Potion",
      "rarity": "uncommon",
      "effect": "Restore 40 castle HP",
      "heal_amount": 40,
      "cost": 60,
      "sell_value": 20,
      "stack_max": 10
    },
    {
      "id": "potion_health_large",
      "name": "Major Health Potion",
      "rarity": "rare",
      "effect": "Restore 75 castle HP",
      "heal_amount": 75,
      "cost": 100,
      "sell_value": 35,
      "stack_max": 5
    },
    {
      "id": "potion_health_full",
      "name": "Full Restore",
      "rarity": "epic",
      "effect": "Restore castle to full HP",
      "heal_amount": "full",
      "cost": 200,
      "sell_value": 75,
      "stack_max": 3
    },
    {
      "id": "potion_speed_minor",
      "name": "Swiftness Draught",
      "rarity": "uncommon",
      "effect": "+10% WPM bonus for 60 seconds",
      "wpm_bonus": 0.10,
      "duration": 60,
      "cost": 35,
      "sell_value": 12
    },
    {
      "id": "potion_speed",
      "name": "Swiftness Elixir",
      "rarity": "rare",
      "effect": "+20% WPM bonus for 90 seconds",
      "wpm_bonus": 0.20,
      "duration": 90,
      "cost": 75,
      "sell_value": 25
    },
    {
      "id": "potion_accuracy",
      "name": "Focus Tonic",
      "rarity": "uncommon",
      "effect": "+10% accuracy bonus for 60 seconds",
      "accuracy_bonus": 0.10,
      "duration": 60,
      "cost": 40,
      "sell_value": 15
    },
    {
      "id": "potion_accuracy_major",
      "name": "Elixir of Precision",
      "rarity": "rare",
      "effect": "+15% accuracy bonus for 90 seconds",
      "accuracy_bonus": 0.15,
      "duration": 90,
      "cost": 80,
      "sell_value": 28
    },
    {
      "id": "potion_invuln",
      "name": "Shield Potion",
      "rarity": "rare",
      "effect": "Castle invulnerable for 10 seconds",
      "invuln_duration": 10,
      "cost": 100,
      "sell_value": 35,
      "stack_max": 3
    },
    {
      "id": "potion_clear",
      "name": "Purification Draught",
      "rarity": "rare",
      "effect": "Remove all debuffs",
      "cost": 60,
      "sell_value": 20
    },
    {
      "id": "potion_damage",
      "name": "Strength Elixir",
      "rarity": "rare",
      "effect": "+25% typing damage for 60 seconds",
      "damage_bonus": 0.25,
      "duration": 60,
      "cost": 85,
      "sell_value": 30
    },
    {
      "id": "potion_combo",
      "name": "Momentum Brew",
      "rarity": "epic",
      "effect": "Start battle with 20 combo",
      "starting_combo": 20,
      "cost": 120,
      "sell_value": 45
    },
    {
      "id": "potion_tower",
      "name": "Empowerment Draught",
      "rarity": "epic",
      "effect": "All towers deal double damage for 30 seconds",
      "tower_damage_mult": 2.0,
      "duration": 30,
      "cost": 150,
      "sell_value": 55
    },
    {
      "id": "potion_legendary",
      "name": "Elixir of Mastery",
      "rarity": "legendary",
      "effect": "+30% WPM, +20% accuracy, +50% damage for 120 seconds",
      "cost": 300,
      "sell_value": 100,
      "stack_max": 1
    }
  ]
}
```

---

## Consumables - Scrolls (12 types)

```json
{
  "scrolls": [
    {
      "id": "scroll_reveal",
      "name": "Scroll of Revelation",
      "rarity": "common",
      "effect": "Reveal all enemy words for 30 seconds",
      "cost": 25,
      "sell_value": 8
    },
    {
      "id": "scroll_slow",
      "name": "Scroll of Lethargy",
      "rarity": "uncommon",
      "effect": "Slow all enemies by 30% for 15 seconds",
      "slow_percent": 0.30,
      "duration": 15,
      "cost": 50,
      "sell_value": 18
    },
    {
      "id": "scroll_freeze",
      "name": "Scroll of Frost",
      "rarity": "rare",
      "effect": "Freeze all enemies for 5 seconds",
      "freeze_duration": 5,
      "cost": 75,
      "sell_value": 25
    },
    {
      "id": "scroll_lightning",
      "name": "Scroll of Lightning",
      "rarity": "rare",
      "effect": "Deal 10 damage to all enemies",
      "damage": 10,
      "cost": 80,
      "sell_value": 28
    },
    {
      "id": "scroll_fire",
      "name": "Scroll of Flames",
      "rarity": "rare",
      "effect": "Deal 5 damage + 3 DPS burn for 5s to all enemies",
      "damage": 5,
      "burn_dps": 3,
      "burn_duration": 5,
      "cost": 85,
      "sell_value": 30
    },
    {
      "id": "scroll_weakness",
      "name": "Scroll of Weakness",
      "rarity": "uncommon",
      "effect": "All enemies take +25% damage for 20 seconds",
      "vulnerability": 0.25,
      "duration": 20,
      "cost": 55,
      "sell_value": 20
    },
    {
      "id": "scroll_simplify",
      "name": "Scroll of Simplicity",
      "rarity": "epic",
      "effect": "All current enemy words reduced to 3 letters",
      "cost": 150,
      "sell_value": 50
    },
    {
      "id": "scroll_tower_boost",
      "name": "Scroll of Empowerment",
      "rarity": "epic",
      "effect": "All towers attack twice as fast for 20 seconds",
      "attack_speed_mult": 2.0,
      "duration": 20,
      "cost": 130,
      "sell_value": 45
    },
    {
      "id": "scroll_gold",
      "name": "Scroll of Fortune",
      "rarity": "epic",
      "effect": "Next wave drops double gold",
      "gold_mult": 2.0,
      "cost": 100,
      "sell_value": 35
    },
    {
      "id": "scroll_summon",
      "name": "Scroll of Summoning",
      "rarity": "epic",
      "effect": "Summon temporary tower (random type) for 60 seconds",
      "duration": 60,
      "cost": 120,
      "sell_value": 40
    },
    {
      "id": "scroll_time",
      "name": "Scroll of Time",
      "rarity": "legendary",
      "effect": "All enemies frozen, you type at normal speed for 15 seconds",
      "duration": 15,
      "cost": 300,
      "sell_value": 100
    },
    {
      "id": "scroll_clear",
      "name": "Scroll of Annihilation",
      "rarity": "legendary",
      "effect": "Instantly defeat all enemies on screen",
      "cost": 500,
      "sell_value": 175,
      "stack_max": 1,
      "limit": "Once per day"
    }
  ]
}
```

---

## Consumables - Food (10 types)

```json
{
  "food": [
    {
      "id": "food_bread",
      "name": "Fresh Bread",
      "rarity": "common",
      "effect": "+2% all stats for 5 minutes",
      "duration_minutes": 5,
      "cost": 10,
      "sell_value": 3
    },
    {
      "id": "food_apple",
      "name": "Crisp Apple",
      "rarity": "common",
      "effect": "+3% accuracy for 5 minutes",
      "duration_minutes": 5,
      "cost": 8,
      "sell_value": 2
    },
    {
      "id": "food_cheese",
      "name": "Aged Cheese",
      "rarity": "common",
      "effect": "+3% defense for 5 minutes",
      "duration_minutes": 5,
      "cost": 12,
      "sell_value": 4
    },
    {
      "id": "food_stew",
      "name": "Hearty Stew",
      "rarity": "uncommon",
      "effect": "+5% defense, +5% gold for 10 minutes",
      "duration_minutes": 10,
      "cost": 25,
      "sell_value": 8
    },
    {
      "id": "food_pie",
      "name": "Meat Pie",
      "rarity": "uncommon",
      "effect": "+5% WPM for 10 minutes",
      "duration_minutes": 10,
      "cost": 30,
      "sell_value": 10
    },
    {
      "id": "food_fish",
      "name": "Grilled Fish",
      "rarity": "uncommon",
      "effect": "+4% accuracy, +4% XP for 10 minutes",
      "duration_minutes": 10,
      "cost": 28,
      "sell_value": 9
    },
    {
      "id": "food_feast",
      "name": "Champion's Feast",
      "rarity": "rare",
      "effect": "+10% all stats for 15 minutes",
      "duration_minutes": 15,
      "cost": 75,
      "sell_value": 25
    },
    {
      "id": "food_elixir",
      "name": "Alchemist's Brew",
      "rarity": "epic",
      "effect": "+15% WPM, +10% accuracy for 20 minutes",
      "duration_minutes": 20,
      "cost": 150,
      "sell_value": 50
    },
    {
      "id": "food_royal",
      "name": "Royal Banquet",
      "rarity": "epic",
      "effect": "+12% all stats for 30 minutes",
      "duration_minutes": 30,
      "cost": 200,
      "sell_value": 70
    },
    {
      "id": "food_legendary",
      "name": "Ambrosia",
      "rarity": "legendary",
      "effect": "+20% all stats for 60 minutes, +1 HP regen/min",
      "duration_minutes": 60,
      "cost": 400,
      "sell_value": 140,
      "stack_max": 1
    }
  ]
}
```

---

## Materials (30 types)

### Common Materials

```json
[
  {"id": "wood", "name": "Wood", "rarity": "common", "value": 2, "sources": ["evergrove_pois", "forest_enemies"]},
  {"id": "stone", "name": "Stone", "rarity": "common", "value": 3, "sources": ["stonepass_pois", "mountain_enemies"]},
  {"id": "herbs", "name": "Herbs", "rarity": "common", "value": 5, "sources": ["evergrove_pois", "herb_patches"]},
  {"id": "cloth", "name": "Cloth", "rarity": "common", "value": 4, "sources": ["enemy_drops", "shop"]},
  {"id": "iron_ore", "name": "Iron Ore", "rarity": "common", "value": 8, "sources": ["stonepass_mines"]},
  {"id": "leather", "name": "Leather", "rarity": "common", "value": 6, "sources": ["beast_enemies"]},
  {"id": "water", "name": "Pure Water", "rarity": "common", "value": 2, "sources": ["water_pois", "shop"]},
  {"id": "bone", "name": "Bone", "rarity": "common", "value": 4, "sources": ["undead_enemies", "graveyards"]},
  {"id": "feather", "name": "Feather", "rarity": "common", "value": 3, "sources": ["flying_enemies", "nests"]}
]
```

### Uncommon Materials

```json
[
  {"id": "silver_ore", "name": "Silver Ore", "rarity": "uncommon", "value": 15, "sources": ["stonepass_deep_mines"]},
  {"id": "rare_herbs", "name": "Rare Herbs", "rarity": "uncommon", "value": 20, "sources": ["hidden_herb_patches"]},
  {"id": "monster_hide", "name": "Monster Hide", "rarity": "uncommon", "value": 18, "sources": ["tier_2_beasts"]},
  {"id": "ancient_wood", "name": "Ancient Wood", "rarity": "uncommon", "value": 25, "sources": ["ancient_trees"]},
  {"id": "marsh_moss", "name": "Marsh Moss", "rarity": "uncommon", "value": 15, "sources": ["mistfen_pois"]},
  {"id": "volcanic_ash", "name": "Volcanic Ash", "rarity": "uncommon", "value": 22, "sources": ["fire_realm"]}
]
```

### Rare Materials

```json
[
  {"id": "crystal_shard", "name": "Crystal Shard", "rarity": "rare", "value": 25, "sources": ["stonepass_crystals"]},
  {"id": "spirit_essence", "name": "Spirit Essence", "rarity": "rare", "value": 50, "sources": ["spirit_encounters", "shrines"]},
  {"id": "void_fragment", "name": "Void Fragment", "rarity": "rare", "value": 75, "sources": ["elite_typhos", "void_rift"]},
  {"id": "phoenix_feather", "name": "Phoenix Feather", "rarity": "rare", "value": 60, "sources": ["fire_realm_elites"]},
  {"id": "frost_crystal", "name": "Frost Crystal", "rarity": "rare", "value": 55, "sources": ["ice_realm"]},
  {"id": "living_bark", "name": "Living Bark", "rarity": "rare", "value": 45, "sources": ["nature_realm"]}
]
```

### Epic Materials

```json
[
  {"id": "pure_crystal", "name": "Pure Crystal", "rarity": "epic", "value": 100, "sources": ["crystal_vein_challenge"]},
  {"id": "dragon_scale", "name": "Dragon Scale", "rarity": "epic", "value": 200, "sources": ["boss_drops"]},
  {"id": "void_essence", "name": "Void Essence", "rarity": "epic", "value": 150, "sources": ["champion_typhos"]},
  {"id": "ancient_rune", "name": "Ancient Rune", "rarity": "epic", "value": 175, "sources": ["legendary_pois"]}
]
```

### Legendary Materials

```json
[
  {"id": "first_typist_key", "name": "First Typist's Key Fragment", "rarity": "legendary", "value": 500, "sources": ["hidden_locations"], "use": "Crafts legendary equipment"},
  {"id": "void_heart", "name": "Heart of the Void", "rarity": "legendary", "value": 1000, "sources": ["void_tyrant"], "use": "Ultimate crafting material"}
]
```

---

## Quest Items

```json
{
  "quest_items": [
    {"id": "grove_seal", "name": "Seal of the Grove", "quest": "mq_regional_boss", "description": "Proof of the Grove Guardian's blessing"},
    {"id": "champion_seal", "name": "Seal of the Champion", "quest": "mq_regional_boss", "description": "Proof of victory in the arena"},
    {"id": "warden_seal", "name": "Seal of the Warden", "quest": "mq_regional_boss", "description": "Proof of passage through the mountains"},
    {"id": "seer_seal", "name": "Seal of the Seer", "quest": "mq_regional_boss", "description": "Proof of wisdom from the marshes"},
    {"id": "fire_key", "name": "Key of Flames", "quest": "mq_realm_access", "description": "Opens the portal to the Fire Realm"},
    {"id": "ice_key", "name": "Key of Frost", "quest": "mq_realm_access", "description": "Opens the portal to the Ice Realm"},
    {"id": "nature_key", "name": "Key of Life", "quest": "mq_realm_access", "description": "Opens the portal to the Nature Realm"},
    {"id": "void_key", "name": "Key of Silence", "quest": "mq_final", "description": "Opens the way to the Void Rift"},
    {"id": "ancient_key_fragment", "name": "Ancient Key Fragment", "quest": "hidden", "description": "Part of a mysterious ancient key"},
    {"id": "hermit_token", "name": "Hermit's Token", "quest": "rc_mistfen", "description": "Shows the Hermit's trust"},
    {"id": "arena_medal", "name": "Arena Medal", "quest": "rc_sunfields", "description": "Proof of arena victories"},
    {"id": "scribe_badge", "name": "Scribe's Badge", "quest": "rc_citadel", "description": "Mark of the Order of Scribes"}
  ]
}
```

---

## Equipment Sets

### Complete Set Definitions

```json
{
  "equipment_sets": [
    {
      "id": "set_scribe",
      "name": "Scribe's Regalia",
      "pieces": {
        "headgear": "helm_focus",
        "armor": "armor_scribe",
        "gloves": "gloves_precision",
        "boots": "boots_traveler"
      },
      "bonuses": {
        "2_piece": {"accuracy_bonus": 0.05, "description": "+5% accuracy"},
        "4_piece": {"xp_bonus": 0.15, "gold_bonus": 0.10, "description": "+15% XP, +10% gold"}
      },
      "lore": "The traditional garb of the Order of Scribes, worn by those dedicated to preserving the art of typing."
    },
    {
      "id": "set_speed",
      "name": "Windrunner's Gear",
      "pieces": {
        "headgear": "helm_speed",
        "gloves": "gloves_swift",
        "boots": "boots_legendary",
        "cape": "cape_ranger"
      },
      "bonuses": {
        "2_piece": {"wpm_bonus": 3, "description": "+3 WPM"},
        "4_piece": {"wpm_bonus": 7, "first_mistake_ignored": true, "description": "+10 WPM total, first mistake per wave ignored"}
      },
      "lore": "Blessed by wind spirits, this gear allows typists to achieve speeds thought impossible."
    },
    {
      "id": "set_void",
      "name": "Voidwalker's Ensemble",
      "pieces": {
        "headgear": "helm_void",
        "armor": "armor_void_conqueror",
        "gloves": "gloves_void",
        "boots": "boots_shadow",
        "cape": "cape_void"
      },
      "bonuses": {
        "2_piece": {"void_resistance": 0.25, "description": "25% void damage resistance"},
        "3_piece": {"void_immunity": true, "description": "Immune to void debuffs"},
        "5_piece": {"void_damage_bonus": 0.50, "heal_on_void_kill": 2, "description": "+50% damage to void enemies, heal 2 HP per void kill"}
      },
      "lore": "Forged from the essence of defeated void creatures, this armor turns the Tyrant's power against itself."
    },
    {
      "id": "set_nature",
      "name": "Guardian's Raiment",
      "pieces": {
        "headgear": "helm_forest",
        "armor": "armor_nature",
        "boots": "boots_swamp",
        "belt": "belt_adventure"
      },
      "bonuses": {
        "2_piece": {"hp_regen": 1, "description": "Regenerate 1 HP per 30s"},
        "4_piece": {"hp_regen": 3, "nature_affinity": true, "description": "Regenerate 3 HP per 30s, +25% effectiveness in nature regions"}
      }
    },
    {
      "id": "set_champion",
      "name": "Arena Champion's Glory",
      "pieces": {
        "headgear": "helm_legendary",
        "armor": "armor_champion",
        "gloves": "gloves_legendary",
        "ring": "ring_combo"
      },
      "bonuses": {
        "2_piece": {"combo_bonus": 0.25, "description": "+25% combo effectiveness"},
        "4_piece": {"combo_floor": 10, "combo_gold": true, "description": "Combo never drops below 10, earn 1 gold per 5 combo"}
      }
    }
  ]
}
```

---

## References

- `docs/plans/p1/ITEM_EQUIPMENT_SYSTEM.md` - System overview
- `docs/plans/p1/ENEMY_BESTIARY_CATALOG.md` - Drop sources
- `docs/plans/p1/QUEST_SIDE_CONTENT.md` - Quest rewards
