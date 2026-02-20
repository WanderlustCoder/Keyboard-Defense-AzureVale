# Item & Equipment System

**Created:** 2026-01-08

Complete specification for items, inventory, equipment, and consumables.

---

## System Overview

### Item Categories

```
┌─────────────────────────────────────────────────────────────┐
│                    ITEM HIERARCHY                           │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  EQUIPMENT (Permanent)                                      │
│  ├── Weapons (Damage bonus)                                 │
│  ├── Armor (Defense bonus)                                  │
│  ├── Accessories (Utility)                                  │
│  └── Keyboard Skins (Cosmetic)                             │
│                                                             │
│  CONSUMABLES (Single use)                                   │
│  ├── Potions (Instant effect)                              │
│  ├── Scrolls (Battle use)                                  │
│  └── Food (Buff duration)                                  │
│                                                             │
│  MATERIALS (Crafting/Selling)                               │
│  ├── Common (Gold value)                                   │
│  ├── Rare (Crafting)                                       │
│  └── Quest (Story items)                                   │
│                                                             │
│  SPECIAL (Unique)                                           │
│  ├── Keys (Unlock areas)                                   │
│  ├── Lore Pages (Collection)                               │
│  └── Artifacts (Legendary)                                 │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Equipment System

### Equipment Slots

```
┌─────────────────────────────────────────────────────────────┐
│                    EQUIPMENT SLOTS                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│                    [Headgear]                               │
│                        │                                    │
│           [Amulet]────[Armor]────[Cape]                    │
│                        │                                    │
│           [Gloves]────[Belt]────[Ring]                     │
│                        │                                    │
│                    [Boots]                                  │
│                                                             │
│  Total Slots: 8                                             │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Equipment Rarities

| Rarity | Color | Stat Bonus | Drop Rate | Special |
|--------|-------|------------|-----------|---------|
| **Common** | White | 1-5% | 60% | None |
| **Uncommon** | Green | 5-10% | 25% | Minor effect |
| **Rare** | Blue | 10-20% | 10% | Special effect |
| **Epic** | Purple | 20-35% | 4% | Powerful effect |
| **Legendary** | Orange | 35-50% | 1% | Unique effect |

---

### Equipment Types

#### Headgear

```json
{
  "slot": "headgear",
  "items": [
    {
      "id": "helm_basic",
      "name": "Leather Cap",
      "rarity": "common",
      "stats": {"defense": 2},
      "effect": null,
      "description": "Simple protective headwear."
    },
    {
      "id": "helm_focus",
      "name": "Scholar's Hood",
      "rarity": "uncommon",
      "stats": {"accuracy_bonus": 0.03},
      "effect": null,
      "description": "Helps maintain focus while typing."
    },
    {
      "id": "helm_speed",
      "name": "Windrunner Helm",
      "rarity": "rare",
      "stats": {"wpm_bonus": 3},
      "effect": {
        "name": "Tailwind",
        "description": "First word of each wave typed 20% faster"
      },
      "description": "Blessed by wind spirits for swift action."
    },
    {
      "id": "helm_void",
      "name": "Crown of Clarity",
      "rarity": "epic",
      "stats": {"accuracy_bonus": 0.08, "defense": 5},
      "effect": {
        "name": "Clear Mind",
        "description": "Immune to word scrambling effects"
      },
      "description": "Protects the mind from void corruption."
    },
    {
      "id": "helm_legendary",
      "name": "First Typist's Circlet",
      "rarity": "legendary",
      "stats": {"accuracy_bonus": 0.15, "wpm_bonus": 5},
      "effect": {
        "name": "Ancient Knowledge",
        "description": "All lessons count as mastered for word selection"
      },
      "description": "Worn by the First Typist in the Age of Writing."
    }
  ]
}
```

#### Armor

```json
{
  "slot": "armor",
  "items": [
    {
      "id": "armor_basic",
      "name": "Cloth Robes",
      "rarity": "common",
      "stats": {"defense": 5},
      "effect": null
    },
    {
      "id": "armor_scribe",
      "name": "Scribe's Vestments",
      "rarity": "uncommon",
      "stats": {"defense": 8, "gold_bonus": 0.05}
    },
    {
      "id": "armor_warrior",
      "name": "Knight's Plate",
      "rarity": "rare",
      "stats": {"defense": 15},
      "effect": {
        "name": "Steadfast",
        "description": "Reduce castle damage taken by 20%"
      }
    },
    {
      "id": "armor_arcane",
      "name": "Archmage Robes",
      "rarity": "epic",
      "stats": {"defense": 10, "tower_damage_bonus": 0.15},
      "effect": {
        "name": "Empowerment",
        "description": "Arcane towers deal +25% damage"
      }
    },
    {
      "id": "armor_legendary",
      "name": "Armor of the True Typist",
      "rarity": "legendary",
      "stats": {"defense": 20, "all_bonus": 0.10},
      "effect": {
        "name": "Prophecy Fulfilled",
        "description": "Perfect words heal castle for 1 HP"
      }
    }
  ]
}
```

#### Gloves

```json
{
  "slot": "gloves",
  "items": [
    {
      "id": "gloves_basic",
      "name": "Typing Gloves",
      "rarity": "common",
      "stats": {"accuracy_bonus": 0.02}
    },
    {
      "id": "gloves_swift",
      "name": "Quicksilver Gloves",
      "rarity": "uncommon",
      "stats": {"wpm_bonus": 2},
      "effect": {
        "name": "Fleet Fingers",
        "description": "+5% attack speed for towers"
      }
    },
    {
      "id": "gloves_precision",
      "name": "Surgeon's Touch",
      "rarity": "rare",
      "stats": {"accuracy_bonus": 0.08},
      "effect": {
        "name": "Precise Strike",
        "description": "Critical hits on 100% accuracy words"
      }
    },
    {
      "id": "gloves_ice",
      "name": "Frostweave Gloves",
      "rarity": "epic",
      "stats": {"accuracy_bonus": 0.05},
      "effect": {
        "name": "Ice Grip",
        "description": "Immune to ice terrain penalty"
      }
    },
    {
      "id": "gloves_legendary",
      "name": "Hands of the Master",
      "rarity": "legendary",
      "stats": {"wpm_bonus": 8, "accuracy_bonus": 0.10},
      "effect": {
        "name": "Perfect Form",
        "description": "Backspace doesn't break combo"
      }
    }
  ]
}
```

#### Accessories (Amulet, Ring, Belt, Cape)

```json
{
  "accessories": [
    {
      "slot": "amulet",
      "id": "amulet_wisdom",
      "name": "Pendant of Wisdom",
      "rarity": "rare",
      "stats": {"xp_bonus": 0.15},
      "effect": {
        "name": "Scholar's Insight",
        "description": "+25% lesson progress"
      }
    },
    {
      "slot": "ring",
      "id": "ring_combo",
      "name": "Band of Momentum",
      "rarity": "epic",
      "stats": {"combo_bonus": 0.20},
      "effect": {
        "name": "Momentum",
        "description": "Combo counter decreases 50% slower"
      }
    },
    {
      "slot": "belt",
      "id": "belt_fortune",
      "name": "Merchant's Sash",
      "rarity": "uncommon",
      "stats": {"gold_bonus": 0.10},
      "effect": {
        "name": "Lucky Find",
        "description": "+5% item drop chance"
      }
    },
    {
      "slot": "cape",
      "id": "cape_void",
      "name": "Voidwalker's Mantle",
      "rarity": "legendary",
      "stats": {"defense": 15},
      "effect": {
        "name": "Void Resistance",
        "description": "Immune to all void debuffs"
      }
    }
  ]
}
```

#### Boots

```json
{
  "slot": "boots",
  "items": [
    {
      "id": "boots_basic",
      "name": "Traveler's Boots",
      "rarity": "common",
      "stats": {"movement_bonus": 0.10}
    },
    {
      "id": "boots_swamp",
      "name": "Marsh Waders",
      "rarity": "uncommon",
      "stats": {"movement_bonus": 0.05},
      "effect": {
        "name": "Swamp Walker",
        "description": "Immune to swamp terrain penalty"
      }
    },
    {
      "id": "boots_fire",
      "name": "Firewalkers",
      "rarity": "rare",
      "stats": {"movement_bonus": 0.15},
      "effect": {
        "name": "Heat Shield",
        "description": "Immune to lava terrain damage"
      }
    },
    {
      "id": "boots_legendary",
      "name": "Boots of the Wind",
      "rarity": "legendary",
      "stats": {"movement_bonus": 0.30, "wpm_bonus": 5},
      "effect": {
        "name": "Windstep",
        "description": "Ignore all terrain movement penalties"
      }
    }
  ]
}
```

---

## Consumables

### Potions

```json
{
  "potions": [
    {
      "id": "potion_health_small",
      "name": "Minor Health Potion",
      "rarity": "common",
      "effect": "Restore 10 castle HP",
      "cost": 20,
      "stack_max": 10
    },
    {
      "id": "potion_health_large",
      "name": "Major Health Potion",
      "rarity": "uncommon",
      "effect": "Restore 30 castle HP",
      "cost": 50,
      "stack_max": 5
    },
    {
      "id": "potion_speed",
      "name": "Swiftness Elixir",
      "rarity": "uncommon",
      "effect": "+20% WPM bonus for 60 seconds",
      "cost": 40,
      "stack_max": 5
    },
    {
      "id": "potion_accuracy",
      "name": "Focus Tonic",
      "rarity": "uncommon",
      "effect": "+10% accuracy bonus for 60 seconds",
      "cost": 40,
      "stack_max": 5
    },
    {
      "id": "potion_invuln",
      "name": "Shield Potion",
      "rarity": "rare",
      "effect": "Castle invulnerable for 10 seconds",
      "cost": 100,
      "stack_max": 3
    },
    {
      "id": "potion_clear",
      "name": "Purification Draught",
      "rarity": "rare",
      "effect": "Remove all debuffs",
      "cost": 60,
      "stack_max": 5
    }
  ]
}
```

### Scrolls

```json
{
  "scrolls": [
    {
      "id": "scroll_reveal",
      "name": "Scroll of Revelation",
      "rarity": "uncommon",
      "effect": "Reveal all enemy words for 30 seconds",
      "cost": 30
    },
    {
      "id": "scroll_freeze",
      "name": "Scroll of Frost",
      "rarity": "rare",
      "effect": "Freeze all enemies for 5 seconds",
      "cost": 75
    },
    {
      "id": "scroll_lightning",
      "name": "Scroll of Lightning",
      "rarity": "rare",
      "effect": "Deal 10 damage to all enemies",
      "cost": 80
    },
    {
      "id": "scroll_simplify",
      "name": "Scroll of Simplicity",
      "rarity": "epic",
      "effect": "All current words reduced to 3 letters",
      "cost": 150
    },
    {
      "id": "scroll_clear",
      "name": "Scroll of Annihilation",
      "rarity": "legendary",
      "effect": "Instantly kill all enemies on screen",
      "cost": 500,
      "limit": "Once per day"
    }
  ]
}
```

### Food

```json
{
  "food": [
    {
      "id": "food_bread",
      "name": "Fresh Bread",
      "rarity": "common",
      "effect": "+2% all stats for 5 minutes",
      "cost": 10
    },
    {
      "id": "food_stew",
      "name": "Hearty Stew",
      "rarity": "uncommon",
      "effect": "+5% defense, +5% gold for 10 minutes",
      "cost": 25
    },
    {
      "id": "food_feast",
      "name": "Champion's Feast",
      "rarity": "rare",
      "effect": "+10% all stats for 15 minutes",
      "cost": 75
    },
    {
      "id": "food_elixir",
      "name": "Alchemist's Brew",
      "rarity": "epic",
      "effect": "+15% WPM, +10% accuracy for 20 minutes",
      "cost": 150
    }
  ]
}
```

---

## Materials

### Common Materials

| Material | Source | Value | Use |
|----------|--------|-------|-----|
| Wood | Forest POIs | 2g | Sell, basic craft |
| Stone | Mountain POIs | 3g | Sell, basic craft |
| Herbs | Various | 5g | Potion crafting |
| Cloth | Enemy drops | 4g | Armor crafting |
| Iron Ore | Mines | 8g | Weapon crafting |

### Rare Materials

| Material | Source | Value | Use |
|----------|--------|-------|-----|
| Crystal Shard | Stonepass | 25g | Arcane items |
| Pure Crystal | Stonepass (challenge) | 100g | Epic items |
| Spirit Essence | Evergrove | 50g | Holy items |
| Void Fragment | Void enemies | 75g | Legendary items |
| Dragon Scale | Boss drops | 200g | Legendary items |

### Quest Materials

| Material | Quest | Purpose |
|----------|-------|---------|
| Grove Seal | Grove Guardian | Unlock Fire Realm |
| Champion Seal | Sunlord Champion | Unlock Ice Realm |
| Warden Seal | Citadel Warden | Unlock Nature Realm |
| Seer Seal | Fen Seer | Unlock Void Rift |
| Ancient Key Fragment | Various | Unlock secret areas |

---

## Crafting System

### Crafting Recipes

```json
{
  "recipes": [
    {
      "id": "recipe_health_small",
      "output": {"item": "potion_health_small", "count": 3},
      "ingredients": [
        {"item": "herbs", "count": 2},
        {"item": "water", "count": 1}
      ],
      "unlock": "default"
    },
    {
      "id": "recipe_gloves_swift",
      "output": {"item": "gloves_swift", "count": 1},
      "ingredients": [
        {"item": "cloth", "count": 5},
        {"item": "spirit_essence", "count": 1}
      ],
      "unlock": "complete_evergrove"
    },
    {
      "id": "recipe_scroll_freeze",
      "output": {"item": "scroll_freeze", "count": 1},
      "ingredients": [
        {"item": "crystal_shard", "count": 3},
        {"item": "ancient_paper", "count": 1}
      ],
      "unlock": "complete_stonepass"
    }
  ]
}
```

### Crafting UI

```
┌─────────────────────────────────────────────────────────────┐
│ CRAFTING                                   Gold: 500        │
├─────────────────────────────────────────────────────────────┤
│ [Potions] [Scrolls] [Equipment] [Special]                  │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│ Recipe: Swiftness Elixir (x1)                              │
│                                                             │
│ Ingredients:                                                │
│   Herbs         3/3  ✓                                     │
│   Crystal Shard 2/1  ✓                                     │
│   Pure Water    0/1  ✗                                     │
│                                                             │
│ Effect: +20% WPM bonus for 60 seconds                      │
│                                                             │
│ [Craft]  (Missing ingredients)                             │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Inventory System

### Inventory Layout

```
┌─────────────────────────────────────────────────────────────┐
│ INVENTORY                                  Gold: 1,234      │
├─────────────────────────────────────────────────────────────┤
│ [Equipment] [Consumables] [Materials] [Quest] [Keyboard]   │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌───┬───┬───┬───┬───┬───┬───┬───┐                        │
│  │ ◆ │ ◆ │ ○ │ ○ │ ○ │ ○ │ ○ │ ○ │  Row 1                │
│  ├───┼───┼───┼───┼───┼───┼───┼───┤                        │
│  │ ○ │ ○ │ ○ │ ○ │ ○ │ ○ │ ○ │ ○ │  Row 2                │
│  ├───┼───┼───┼───┼───┼───┼───┼───┤                        │
│  │ ○ │ ○ │ ○ │ ○ │ ○ │   │   │   │  Row 3                │
│  └───┴───┴───┴───┴───┴───┴───┴───┘                        │
│                                                             │
│  ◆ = Equipped    ○ = Item    Empty = Available             │
│                                                             │
│  Capacity: 20/24 slots                                      │
│                                                             │
│  [Sort] [Sell All Junk] [Expand (+8 slots: 100g)]          │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Inventory Limits

| Category | Base Slots | Max Slots | Expansion Cost |
|----------|------------|-----------|----------------|
| Equipment | 16 | 32 | 100g per 8 |
| Consumables | 20 | 40 | 75g per 10 |
| Materials | 30 | 60 | 50g per 10 |
| Quest | Unlimited | - | - |

---

## Keyboard Skins

### Cosmetic Keyboards

```json
{
  "keyboard_skins": [
    {
      "id": "skin_default",
      "name": "Standard Keyboard",
      "unlock": "default",
      "description": "Classic keyboard appearance"
    },
    {
      "id": "skin_forest",
      "name": "Evergrove Keys",
      "unlock": "complete_evergrove",
      "description": "Natural wood and vine aesthetic"
    },
    {
      "id": "skin_crystal",
      "name": "Crystal Board",
      "unlock": "collect_all_crystals",
      "description": "Shimmering crystal keys"
    },
    {
      "id": "skin_fire",
      "name": "Inferno Keys",
      "unlock": "complete_fire_realm",
      "description": "Burning ember keyboard"
    },
    {
      "id": "skin_ice",
      "name": "Frostbound Board",
      "unlock": "complete_ice_realm",
      "description": "Frozen crystalline keys"
    },
    {
      "id": "skin_void",
      "name": "Void Keyboard",
      "unlock": "defeat_void_tyrant",
      "description": "Dark matter and corrupted light"
    },
    {
      "id": "skin_gold",
      "name": "Golden Keyboard",
      "unlock": "earn_10000_gold",
      "description": "Solid gold luxury keyboard"
    },
    {
      "id": "skin_rainbow",
      "name": "Chromatic Keys",
      "unlock": "100_percent_completion",
      "description": "Shifting rainbow colors"
    }
  ]
}
```

---

## Set Bonuses

### Equipment Sets

```json
{
  "equipment_sets": [
    {
      "id": "set_scribe",
      "name": "Scribe's Regalia",
      "pieces": ["helm_focus", "armor_scribe", "gloves_precision", "boots_basic"],
      "bonuses": {
        "2_piece": "+5% accuracy",
        "4_piece": "+15% XP gain, +10% gold"
      }
    },
    {
      "id": "set_speed",
      "name": "Windrunner's Gear",
      "pieces": ["helm_speed", "gloves_swift", "boots_legendary", "cape_wind"],
      "bonuses": {
        "2_piece": "+3 WPM",
        "4_piece": "+10 WPM, first mistake per wave ignored"
      }
    },
    {
      "id": "set_void",
      "name": "Voidwalker's Ensemble",
      "pieces": ["helm_void", "armor_legendary", "gloves_legendary", "cape_void", "boots_legendary"],
      "bonuses": {
        "2_piece": "Immune to one debuff type",
        "3_piece": "Immune to all debuffs",
        "5_piece": "+25% damage to void enemies, heal on void kill"
      }
    }
  ]
}
```

---

## Implementation Checklist

- [ ] Create item data files
- [ ] Implement inventory system
- [ ] Build equipment slots UI
- [ ] Add stat calculation from equipment
- [ ] Implement consumable use system
- [ ] Create crafting system
- [ ] Add material gathering
- [ ] Implement keyboard skin system
- [ ] Add set bonus detection
- [ ] Create item drop tables
- [ ] Build shop buying/selling
- [ ] Add item tooltips

---

## References

- `sim/types.gd` - Item type definitions
- `game/main.gd` - Inventory management
- `docs/plans/p1/QUEST_SIDE_CONTENT.md` - Reward integration
- `docs/plans/p1/ENEMY_COMBAT_DESIGN.md` - Drop tables
