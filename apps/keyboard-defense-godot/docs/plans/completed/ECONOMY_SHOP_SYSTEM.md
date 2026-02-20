# Economy and Shop System

**Version:** 1.0.0
**Last Updated:** 2026-01-09
**Status:** Implementation Ready

## Overview

The economy system governs resource acquisition, spending, and progression in Keyboard Defense. As an edutainment game, the economy is designed to reward learning and skill improvement rather than grinding or purchases. All progression is achievable through normal gameplay.

---

## Currency Types

### Primary Currency: Gold

```json
{
  "currency_id": "gold",
  "name": "Gold",
  "icon": "coin_gold",
  "description": "The standard currency of Keystonia, earned through combat and exploration.",
  "acquisition": [
    "Enemy defeats",
    "Wave completion bonuses",
    "Level completion",
    "Quest rewards",
    "Treasure chests",
    "Selling items"
  ],
  "uses": [
    "Building towers",
    "Upgrading towers",
    "Purchasing items from shops",
    "Unlocking regions",
    "Hiring NPCs"
  ],
  "max_storage": 999999,
  "display_format": "abbreviated"
}
```

### Secondary Currency: Letter Essence

```json
{
  "currency_id": "letter_essence",
  "name": "Letter Essence",
  "icon": "essence_glow",
  "description": "Magical energy crystallized from perfect typing. Used for advanced upgrades.",
  "acquisition": [
    "Perfect word completions",
    "High combo achievements",
    "Boss defeats",
    "Mastery challenges",
    "Story milestones"
  ],
  "uses": [
    "Legendary item crafting",
    "Skill tree unlocks",
    "Prestige upgrades",
    "Cosmetic purchases"
  ],
  "rarity": "uncommon",
  "max_storage": 9999
}
```

### Crafting Materials

```json
{
  "materials": [
    {
      "material_id": "scrap_metal",
      "name": "Scrap Metal",
      "tier": "common",
      "sources": ["Mechanical enemies", "Salvaging towers", "Mining POIs"],
      "uses": ["Auto-tower construction", "Siege equipment"]
    },
    {
      "material_id": "living_wood",
      "name": "Living Wood",
      "tier": "common",
      "sources": ["Forest enemies", "Verdant Grove region", "Nature shrines"],
      "uses": ["Nature towers", "Wooden equipment"]
    },
    {
      "material_id": "fire_crystal",
      "name": "Fire Crystal",
      "tier": "uncommon",
      "sources": ["Fire enemies", "Ember Wastes region", "Volcanic areas"],
      "uses": ["Fire towers", "Flame enchantments"]
    },
    {
      "material_id": "lightning_crystal",
      "name": "Lightning Crystal",
      "tier": "uncommon",
      "sources": ["Electric enemies", "Storm areas", "Voltara Plains"],
      "uses": ["Electric towers", "Speed enchantments"]
    },
    {
      "material_id": "arcane_crystal",
      "name": "Arcane Crystal",
      "tier": "rare",
      "sources": ["Magic enemies", "Arcane bosses", "Ancient ruins"],
      "uses": ["Magic towers", "Legendary crafting"]
    },
    {
      "material_id": "ancient_core",
      "name": "Ancient Core",
      "tier": "legendary",
      "sources": ["World bosses", "Hidden dungeons", "Quest rewards"],
      "uses": ["Legendary tower upgrades", "Ultimate abilities"]
    }
  ]
}
```

---

## Gold Economy Balance

### Income Sources

```json
{
  "gold_income": {
    "enemy_kills": {
      "grunt": {"base": 5, "range": [3, 7]},
      "runner": {"base": 4, "range": [2, 6]},
      "tank": {"base": 12, "range": [8, 16]},
      "elite": {"base": 25, "range": [20, 35]},
      "mini_boss": {"base": 100, "range": [75, 150]},
      "boss": {"base": 500, "range": [400, 750]}
    },
    "wave_completion": {
      "base": 50,
      "per_enemy_killed": 2,
      "perfect_wave_bonus": 100,
      "difficulty_scaling": {
        "story": 1.2,
        "adventure": 1.0,
        "champion": 1.3,
        "nightmare": 1.75
      }
    },
    "level_completion": {
      "base": 200,
      "first_time_bonus": 500,
      "star_bonuses": {
        "1_star": 0,
        "2_stars": 100,
        "3_stars": 250
      }
    },
    "exploration": {
      "treasure_chest_small": {"range": [25, 50]},
      "treasure_chest_medium": {"range": [75, 150]},
      "treasure_chest_large": {"range": [200, 400]},
      "hidden_cache": {"range": [100, 300]}
    },
    "quests": {
      "side_quest": {"range": [100, 500]},
      "main_quest": {"range": [500, 2000]},
      "mastery_challenge": {"range": [200, 1000]}
    }
  }
}
```

### Expenditures

```json
{
  "gold_costs": {
    "towers": {
      "tier_1_average": 60,
      "tier_2_average": 150,
      "tier_3_average": 350,
      "tier_4_average": 800
    },
    "tower_upgrades": {
      "tier_1_to_2": 100,
      "tier_2_to_3": 250,
      "tier_3_to_4": 600
    },
    "shop_items": {
      "consumable_common": {"range": [20, 50]},
      "consumable_uncommon": {"range": [75, 150]},
      "equipment_common": {"range": [100, 200]},
      "equipment_uncommon": {"range": [250, 500]},
      "equipment_rare": {"range": [750, 1500]}
    },
    "region_unlock": {
      "early_regions": 0,
      "mid_regions": 500,
      "late_regions": 1500,
      "secret_regions": 3000
    },
    "services": {
      "tower_repair": "20% of tower cost",
      "full_heal": 100,
      "item_identify": 25,
      "fast_travel": 10
    }
  }
}
```

### Economy Curve

```json
{
  "economy_progression": {
    "early_game": {
      "chapters": [1, 2],
      "expected_gold_per_level": 300,
      "expected_spending": 200,
      "net_gain": 100,
      "purpose": "Learn basics, afford tier 1 towers"
    },
    "mid_game": {
      "chapters": [3, 4, 5],
      "expected_gold_per_level": 600,
      "expected_spending": 450,
      "net_gain": 150,
      "purpose": "Upgrade to tier 2, experiment with builds"
    },
    "late_game": {
      "chapters": [6, 7, 8],
      "expected_gold_per_level": 1000,
      "expected_spending": 800,
      "net_gain": 200,
      "purpose": "Tier 3 towers, strategic choices"
    },
    "end_game": {
      "chapters": [9, 10],
      "expected_gold_per_level": 1500,
      "expected_spending": 1200,
      "net_gain": 300,
      "purpose": "Legendary items, full builds"
    }
  }
}
```

---

## Shop System

### Shop Types

#### Regional Shops

```json
{
  "shop_type": "regional",
  "description": "Standard shops found in each region with thematic inventory",
  "shops": [
    {
      "shop_id": "verdant_grove_shop",
      "name": "Leafweaver's Emporium",
      "region": "Verdant Grove",
      "shopkeeper": "Thornleaf",
      "specialty": "Nature items and living wood equipment",
      "inventory_refresh": "on_region_revisit",
      "discount_condition": "Complete Verdant Grove story"
    },
    {
      "shop_id": "ember_wastes_shop",
      "name": "The Cinder Forge",
      "region": "Ember Wastes",
      "shopkeeper": "Pyrus",
      "specialty": "Fire items and forged equipment",
      "inventory_refresh": "on_region_revisit",
      "discount_condition": "Complete Ember Wastes story"
    },
    {
      "shop_id": "voltara_plains_shop",
      "name": "Spark & Circuit",
      "region": "Voltara Plains",
      "shopkeeper": "Zappel",
      "specialty": "Electric items and mechanical parts",
      "inventory_refresh": "on_region_revisit",
      "discount_condition": "Complete Voltara Plains story"
    },
    {
      "shop_id": "frost_peaks_shop",
      "name": "Glacier's Gift",
      "region": "Frost Peaks",
      "shopkeeper": "Iceweave",
      "specialty": "Ice items and resilience equipment",
      "inventory_refresh": "on_region_revisit",
      "discount_condition": "Complete Frost Peaks story"
    }
  ]
}
```

#### Specialty Shops

```json
{
  "specialty_shops": [
    {
      "shop_id": "blacksmith",
      "name": "The Master Forge",
      "location": "Capital City",
      "shopkeeper": "Ironfist",
      "services": [
        "Sell weapons and armor",
        "Repair equipment",
        "Craft custom items",
        "Upgrade equipment"
      ],
      "inventory": "equipment_focused",
      "unlock": "Chapter 2 completion"
    },
    {
      "shop_id": "alchemist",
      "name": "Bubbling Cauldron",
      "location": "Capital City",
      "shopkeeper": "Mixwell",
      "services": [
        "Sell potions and consumables",
        "Craft potions from materials",
        "Identify unknown items"
      ],
      "inventory": "consumables_focused",
      "unlock": "Chapter 3 completion"
    },
    {
      "shop_id": "enchanter",
      "name": "Glyph & Quill",
      "location": "Arcane Academy",
      "shopkeeper": "Runescribe",
      "services": [
        "Sell enchantments and scrolls",
        "Apply enchantments to items",
        "Remove enchantments"
      ],
      "inventory": "magical_focused",
      "unlock": "Chapter 4 completion"
    },
    {
      "shop_id": "collector",
      "name": "Curious Collections",
      "location": "Hidden Alley",
      "shopkeeper": "Dusty",
      "services": [
        "Buy rare items",
        "Sell unique finds",
        "Trade for special items"
      ],
      "inventory": "rare_and_unique",
      "unlock": "Find secret entrance"
    }
  ]
}
```

### Shop Inventory System

```json
{
  "inventory_system": {
    "stock_categories": {
      "always_available": {
        "description": "Core items always in stock",
        "restock": "instant",
        "examples": ["Basic potions", "Common materials", "Repair kits"]
      },
      "rotating_stock": {
        "description": "Changes on refresh",
        "restock": "on_refresh_trigger",
        "quantity": "limited",
        "examples": ["Uncommon equipment", "Special consumables"]
      },
      "rare_stock": {
        "description": "Randomly available",
        "appear_chance": 20,
        "restock": "on_refresh_trigger",
        "quantity": 1,
        "examples": ["Rare items", "Unique equipment"]
      },
      "quest_stock": {
        "description": "Appears after quest completion",
        "trigger": "specific_quest",
        "quantity": 1,
        "examples": ["Quest rewards", "Story items"]
      }
    },
    "refresh_triggers": [
      "Level completion",
      "Region change",
      "Story milestone",
      "In-game time passage"
    ]
  }
}
```

### Pricing System

```json
{
  "pricing": {
    "base_prices": {
      "common": {"min": 20, "max": 100},
      "uncommon": {"min": 100, "max": 300},
      "rare": {"min": 300, "max": 800},
      "epic": {"min": 800, "max": 2000},
      "legendary": {"min": 2000, "max": 5000}
    },
    "modifiers": {
      "shop_specialty_discount": 0.85,
      "region_completion_discount": 0.90,
      "reputation_discount": {
        "friendly": 0.95,
        "trusted": 0.90,
        "honored": 0.85
      },
      "bulk_discount": {
        "5_items": 0.95,
        "10_items": 0.90
      }
    },
    "sell_prices": {
      "default_ratio": 0.40,
      "collector_ratio": 0.60,
      "quest_item_ratio": 0
    }
  }
}
```

---

## Shop UI/UX

### Shop Interface

```json
{
  "shop_ui": {
    "layout": "split_panel",
    "left_panel": {
      "content": "Shop inventory",
      "tabs": ["All", "Equipment", "Consumables", "Materials", "Special"],
      "sorting": ["Price", "Rarity", "Type", "New"],
      "filtering": true
    },
    "right_panel": {
      "content": "Item details",
      "shows": [
        "Item name and icon",
        "Rarity indicator",
        "Description",
        "Stats comparison (if equipment)",
        "Price",
        "Stock remaining"
      ]
    },
    "bottom_bar": {
      "content": ["Player gold", "Buy button", "Sell mode toggle"]
    },
    "shopkeeper_portrait": {
      "location": "top_center",
      "dialogue_on_browse": true,
      "reactions_to_purchases": true
    }
  }
}
```

### Purchase Flow

```json
{
  "purchase_flow": {
    "single_item": {
      "click": "Select item",
      "double_click": "Quick buy",
      "confirmation": "Only for items > 500 gold"
    },
    "bulk_purchase": {
      "quantity_selector": true,
      "max_quantity": "stock_or_affordable",
      "price_preview": true
    },
    "sell_mode": {
      "toggle": "Tab key or button",
      "shows": "Player inventory",
      "quick_sell": "Shift+click",
      "sell_all_junk": "Button option"
    },
    "feedback": {
      "purchase_success": "Coin sound + flash",
      "insufficient_funds": "Error sound + shake",
      "out_of_stock": "Grayed out + tooltip"
    }
  }
}
```

---

## Merchant NPCs

### Shopkeeper Personalities

```json
{
  "shopkeepers": [
    {
      "npc_id": "thornleaf",
      "name": "Thornleaf",
      "shop": "Leafweaver's Emporium",
      "personality": "Gentle, nature-loving, speaks in plant metaphors",
      "greeting": "Welcome, young sapling! Let's see what's taken root in my inventory today.",
      "purchase_reaction": "May this serve you well, as the oak serves the forest.",
      "haggle_response": "Hmm, the prices are like the seasons - they change, but slowly.",
      "farewell": "May your roots grow deep and your branches reach high!"
    },
    {
      "npc_id": "pyrus",
      "name": "Pyrus",
      "shop": "The Cinder Forge",
      "personality": "Gruff, passionate, fiery temper but warm heart",
      "greeting": "Welcome to the forge! Everything here's been through the flames - only the best survives!",
      "purchase_reaction": "Ha! Good choice. That'll serve you well in the heat of battle.",
      "haggle_response": "Bah! You trying to cool my fires? These prices are fair as they come!",
      "farewell": "Keep the flames burning, friend!"
    },
    {
      "npc_id": "zappel",
      "name": "Zappel",
      "shop": "Spark & Circuit",
      "personality": "Eccentric, fast-talking, easily distracted",
      "greeting": "Oh-oh-OH! A customer! Quick quick, lots to see, much to buy, time is energy, energy is everything!",
      "purchase_reaction": "Excellent-excellent! That'll give you quite the SPARK, hehe!",
      "haggle_response": "Lower prices? But-but the components! The calibration! Fine-fine, small discount, you drive hard bargain!",
      "farewell": "Stay charged, stay bright, don't get grounded! Hehe!"
    },
    {
      "npc_id": "dusty",
      "name": "Dusty",
      "shop": "Curious Collections",
      "personality": "Mysterious, knows more than they let on, cryptic",
      "greeting": "Ah, you found your way here. Most don't. Browse carefully - everything has a history.",
      "purchase_reaction": "Interesting choice. That item has been waiting for the right owner.",
      "haggle_response": "The price is what the price is. Some things are worth more than gold.",
      "farewell": "Until the paths cross again. They always do."
    }
  ]
}
```

### Reputation System

```json
{
  "reputation": {
    "per_shop": true,
    "levels": [
      {"level": "Stranger", "threshold": 0, "discount": 0},
      {"level": "Customer", "threshold": 500, "discount": 0},
      {"level": "Regular", "threshold": 2000, "discount": 5},
      {"level": "Valued", "threshold": 5000, "discount": 10},
      {"level": "Friend", "threshold": 10000, "discount": 15}
    ],
    "gain_from": [
      "Purchases (1 rep per 10 gold spent)",
      "Sales (1 rep per 20 gold received)",
      "Shop-specific quests (varies)",
      "Story progression"
    ],
    "benefits": [
      "Price discounts",
      "Exclusive inventory access",
      "Shop-specific quests",
      "Unique dialogue",
      "Free items on milestones"
    ]
  }
}
```

---

## Special Transactions

### Item Trading

```json
{
  "trading": {
    "enabled_at": "Curious Collections only",
    "trade_offers": [
      {
        "give": {"item": "Ancient Relic", "quantity": 3},
        "receive": {"item": "Legendary Blueprint", "quantity": 1}
      },
      {
        "give": {"item": "Fire Crystal", "quantity": 10},
        "receive": {"item": "Inferno Core", "quantity": 1}
      },
      {
        "give": {"item": "Any Legendary", "quantity": 1},
        "receive": {"item": "Mystery Legendary", "quantity": 1}
      }
    ],
    "refresh": "Weekly"
  }
}
```

### Crafting Services

```json
{
  "crafting_services": {
    "blacksmith": {
      "craft_weapon": {
        "cost": "Materials + 100 gold service fee",
        "time": "Instant",
        "quality_range": "Depends on materials"
      },
      "upgrade_equipment": {
        "cost": "Materials + 50% of item value",
        "success_rate": 100,
        "max_upgrades": 3
      },
      "repair": {
        "cost": "20% of item value",
        "restores": "Full durability"
      }
    },
    "alchemist": {
      "brew_potion": {
        "cost": "Materials + 20 gold service fee",
        "time": "Instant",
        "potency_range": "Depends on materials"
      },
      "identify_item": {
        "cost": 25,
        "reveals": "Hidden properties"
      }
    },
    "enchanter": {
      "apply_enchantment": {
        "cost": "Scroll + 100 gold service fee",
        "success_rate": 100,
        "max_enchants": 2
      },
      "remove_enchantment": {
        "cost": 50,
        "recovers_scroll": false
      }
    }
  }
}
```

---

## Economy Safeguards

### Anti-Farming Measures

```json
{
  "economy_safeguards": {
    "diminishing_returns": {
      "enabled": true,
      "trigger": "Replaying same level repeatedly",
      "reduction": "10% per replay, minimum 50%",
      "reset": "After playing different level"
    },
    "gold_caps": {
      "per_enemy_type_per_wave": true,
      "max_gold_per_wave": 500,
      "max_gold_per_level": 3000
    },
    "no_real_money": {
      "description": "All content achievable through gameplay",
      "no_premium_currency": true,
      "no_microtransactions": true
    }
  }
}
```

### New Player Protection

```json
{
  "new_player_protection": {
    "starter_gold": 200,
    "tutorial_purchases": {
      "guided": true,
      "refundable": true
    },
    "early_game_prices": {
      "chapters_1_2": "Reduced by 20%"
    },
    "bankruptcy_prevention": {
      "minimum_gold": 50,
      "free_basic_items": ["Basic Health Potion", "Repair Kit"],
      "message": "Here's a little help to get back on your feet!"
    }
  }
}
```

---

## Inventory Management

### Player Inventory

```json
{
  "inventory": {
    "equipment_slots": {
      "weapon": 1,
      "armor": 1,
      "accessory_1": 1,
      "accessory_2": 1
    },
    "backpack": {
      "initial_slots": 20,
      "max_slots": 50,
      "expansion_cost": [100, 250, 500, 1000, 2000]
    },
    "material_storage": {
      "separate_from_backpack": true,
      "unlimited_stacking": true,
      "auto_deposit": true
    },
    "sorting_options": [
      "Type",
      "Rarity",
      "Value",
      "Recently Acquired",
      "Name"
    ],
    "quick_actions": {
      "equip": "Double-click",
      "use": "Right-click",
      "drop": "Drag out",
      "sell": "Shift+click (in shop)"
    }
  }
}
```

### Item Management

```json
{
  "item_management": {
    "compare_equipped": {
      "enabled": true,
      "shows": "Side-by-side stats",
      "highlights": "Better/worse values"
    },
    "junk_marking": {
      "enabled": true,
      "auto_mark": "Items below threshold",
      "sell_all_junk": true
    },
    "favorites": {
      "enabled": true,
      "prevents": "Accidental sale",
      "marked_with": "Star icon"
    },
    "item_sets": {
      "enabled": true,
      "quick_swap": true,
      "max_sets": 3
    }
  }
}
```

---

## Testing Scenarios

```json
{
  "test_scenarios": [
    {
      "name": "Early Game Economy",
      "scenario": "New player, chapters 1-2",
      "expected": "Can afford basic towers and consumables",
      "gold_target": "~500 per chapter"
    },
    {
      "name": "Mid Game Progression",
      "scenario": "Player completing chapter 5",
      "expected": "Can upgrade to tier 2 towers, buy uncommon gear",
      "gold_target": "~2000 accumulated"
    },
    {
      "name": "Late Game Build",
      "scenario": "Player at chapter 8",
      "expected": "Can afford tier 3 towers and rare items",
      "gold_target": "~8000 accumulated"
    },
    {
      "name": "Shop Interaction",
      "scenario": "Player browses regional shop",
      "expected": "Clear prices, easy navigation, helpful tooltips",
      "success": "Purchase completed in <5 clicks"
    },
    {
      "name": "Material Collection",
      "scenario": "Player wants to craft specific item",
      "expected": "Can see material sources, reasonable gather time",
      "success": "Materials gathered in 2-3 levels"
    }
  ]
}
```

---

*End of Economy and Shop System Document*
