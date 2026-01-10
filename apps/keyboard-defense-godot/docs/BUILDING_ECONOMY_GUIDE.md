# Building & Economy Guide

This document explains the building system, resource economy, and upgrade mechanics in Keyboard Defense. Inspired by Super Fantasy Kingdom's resource chains and workforce allocation.

## Overview

The economy follows a classic strategy game loop:
1. Build production buildings
2. Assign workers for bonuses
3. Gather resources
4. Spend on defenses and upgrades
5. Survive waves, earn gold
6. Buy permanent upgrades

## Buildings

### Building Categories

| Category | Buildings | Purpose |
|----------|-----------|---------|
| Production | Farm, Lumber, Quarry | Generate resources |
| Defense | Wall, Tower | Block/attack enemies |
| Economy | Market | Generate gold |
| Military | Barracks | Combat bonuses |
| Support | Temple, Workshop | Special effects |

### Building Data Structure

```gdscript
# sim/buildings.gd
const BUILDINGS := {
    "farm": {
        "cost": {"wood": 10},
        "production": {"food": 3},
        "defense": 0,
        "worker_slots": 1,
        "category": "production"
    },
    "tower": {
        "cost": {"wood": 4, "stone": 8},
        "production": {},
        "defense": 2,
        "worker_slots": 0,
        "category": "defense"
    }
}
```

### Building Stats

| Building | Cost | Production | Defense | Workers |
|----------|------|------------|---------|---------|
| Farm | 10 wood | 3 food | 0 | 1 |
| Lumber | 5 wood, 2 food | 3 wood | 0 | 1 |
| Quarry | 5 wood, 2 food | 3 stone | 0 | 1 |
| Wall | 4 wood, 4 stone | - | 1 | 0 |
| Tower | 4 wood, 8 stone | - | 2 | 0 |
| Market | 8 wood, 5 stone | 5 gold | 0 | 1 |
| Barracks | 10 wood, 8 stone | - | 1 | 2 |
| Temple | 15 stone, 20 gold | - | 0 | 1 |
| Workshop | 12 wood, 6 stone | - | 0 | 2 |

## Resource System

### Resource Types

| Resource | Primary Source | Used For |
|----------|---------------|----------|
| Wood | Lumber Mill | Buildings, upgrades |
| Stone | Quarry | Buildings, upgrades |
| Food | Farm | Upkeep, some upgrades |
| Gold | Market, waves | Upgrades |

### Daily Production

```gdscript
static func daily_production(state: GameState) -> Dictionary:
    var totals = {"wood": 0, "stone": 0, "food": 1}  # Base 1 food

    for key in state.structures.keys():
        var building_type = state.structures[key]
        var production = production_for(building_type)

        for resource in production.keys():
            totals[resource] += production[resource]

        # Adjacency bonuses
        var pos = SimMap.pos_from_index(key, state.map_w)
        if building_type == "farm" and adjacent_to_water(state, pos):
            totals["food"] += 1
        elif building_type == "lumber" and adjacent_to_forest(state, pos):
            totals["wood"] += 1
        elif building_type == "quarry" and adjacent_to_mountain(state, pos):
            totals["stone"] += 1

    return totals
```

### Adjacency Bonuses

Strategic placement provides bonuses:

| Building | Adjacent To | Bonus |
|----------|-------------|-------|
| Farm | Water | +1 food |
| Lumber | Forest | +1 wood |
| Quarry | Mountain | +1 stone |
| Tower | Wall | +1 defense |
| Market (L2+) | Buildings | +gold per adjacent |

## Building Upgrades

All buildings can be upgraded to level 3, improving stats and unlocking effects.

### Upgrade System

```gdscript
const BUILDING_UPGRADES := {
    "farm": {
        "max_level": 3,
        "levels": {
            2: {"cost": {"wood": 8}, "production": {"food": 5}, "worker_slots": 2},
            3: {"cost": {"wood": 12, "stone": 5}, "production": {"food": 8}, "worker_slots": 3}
        }
    }
}
```

### Farm Upgrades

| Level | Cost | Food | Workers |
|-------|------|------|---------|
| 1 | 10 wood | 3 | 1 |
| 2 | 8 wood | 5 | 2 |
| 3 | 12 wood, 5 stone | 8 | 3 |

### Tower Upgrades

| Level | Cost | Range | Damage | Shots |
|-------|------|-------|--------|-------|
| 1 | 4 wood, 8 stone | 3 | 1 | 1 |
| 2 | 4 wood, 8 stone | 4 | 2 | 2 |
| 3 | 8 wood, 12 stone | 5 | 3 | 2 |

Level 3 tower also adds 15% enemy slow effect.

### Support Building Effects

| Building | Level | Effects |
|----------|-------|---------|
| Temple L1 | 15s, 20g | +1 HP heal per wave |
| Temple L2 | 10s, 15g | +2 HP heal, +10% morale |
| Temple L3 | 20s, 40g | +3 HP heal, +20% morale, +2 castle HP |
| Workshop L1 | 12w, 6s | -10% build cost |
| Workshop L2 | 8w, 10s | -15% build, -10% upgrade cost |
| Workshop L3 | 15w, 15s, 20g | -20% build, -15% upgrade, +1 tower damage |

### Applying Upgrades

```gdscript
# Check if upgrade available
var check = SimBuildings.can_upgrade(state, tile_index)
if check.ok:
    # Deduct costs
    for res in check.cost.keys():
        state.resources[res] -= check.cost[res]

    # Apply level
    state.structure_levels[tile_index] = check.next_level
```

## Accumulated Building Effects

Buildings provide passive effects that accumulate:

```gdscript
static func get_total_effects(state: GameState) -> Dictionary:
    var effects = {
        "wave_heal": 0,
        "typing_power": 0.0,
        "combo_bonus": 0.0,
        "build_cost_reduction": 0.0,
        "upgrade_cost_reduction": 0.0,
        "tower_damage": 0,
        "enemy_slow": 0.0,
        "castle_hp": 0,
        "morale": 0.0
    }

    for key in state.structures.keys():
        var building_type = state.structures[key]
        var level = structure_level(state, key)
        var building_effects = effects_for_level(building_type, level)

        for effect in building_effects.keys():
            effects[effect] += building_effects[effect]

    return effects
```

## Kingdom Upgrades

Permanent upgrades purchased with gold, loaded from JSON.

### Upgrade Categories

| Category | Examples | Effect Types |
|----------|----------|--------------|
| Castle | Reinforced Walls | +HP, damage reduction |
| Economy | Granary | Resource bonuses |
| Combat | War Academy | Typing power, crit |
| Support | Healers | Wave heal, HP restore |

### Upgrade Data Structure

```json
// data/kingdom_upgrades.json
{
  "upgrades": [
    {
      "id": "reinforced_walls",
      "name": "Reinforced Walls",
      "description": "+2 Castle HP",
      "cost": 50,
      "requires": [],
      "effects": {
        "castle_health_bonus": 2
      }
    }
  ]
}
```

### Prerequisite System

Upgrades can require other upgrades:

```gdscript
static func can_purchase_kingdom_upgrade(state: GameState, upgrade_id: String) -> Dictionary:
    var upgrade = get_kingdom_upgrade(upgrade_id)

    # Check prerequisites
    var requires = upgrade.get("requires", [])
    for req_id in requires:
        if req_id not in state.purchased_kingdom_upgrades:
            return {"ok": false, "error": "Requires: %s" % req_id}

    # Check gold
    var cost = upgrade.get("cost", 0)
    if state.gold < cost:
        return {"ok": false, "error": "Not enough gold"}

    return {"ok": true, "cost": cost}
```

### Effect Accumulation

```gdscript
static func get_typing_power(state: GameState) -> float:
    var power = 1.0
    for upgrade_id in state.purchased_kingdom_upgrades:
        var upgrade = get_kingdom_upgrade(upgrade_id)
        var effects = upgrade.get("effects", {})
        power += effects.get("typing_power", 0.0)
    return power
```

## Unit Upgrades

Combat-focused upgrades from `data/unit_upgrades.json`:

| Effect | Description | Example |
|--------|-------------|---------|
| `typing_power` | Damage multiplier | +10% damage |
| `crit_chance` | Critical hit chance | +5% crit |
| `mistake_forgiveness` | Chance to avoid miss penalty | 10% forgive |
| `enemy_speed_reduction` | Slow enemies | -10% speed |
| `damage_reduction` | Chance to block damage | 15% block |

## Gold Economy

### Gold Sources

| Source | Amount | Frequency |
|--------|--------|-----------|
| Wave completion | Variable | Per wave |
| Market production | 5-12/day | Daily |
| Event rewards | Variable | Random |
| Achievement bonuses | Fixed | One-time |

### Gold Sinks

| Use | Cost Range |
|-----|------------|
| Kingdom upgrades | 25-200 gold |
| Unit upgrades | 30-150 gold |
| Temple/Workshop | 15-40 gold |
| Late-game buildings | 20-50 gold |

## Build Preview System

Before building, get a preview of what will happen:

```gdscript
static func get_build_preview(state: GameState, pos: Vector2i, building_type: String) -> Dictionary:
    var preview = {
        "building": building_type,
        "ok": false,
        "reason": "",
        "cost": {},
        "production": {},
        "defense": 0
    }

    // Calculate adjacency bonuses
    var production = production_for(building_type).duplicate()
    if building_type == "farm" and adjacent_to_water(state, pos):
        production["food"] += 1

    // Validate placement
    if not in_bounds(pos):
        preview.reason = "out of bounds"
        return preview

    if not discovered(pos):
        preview.reason = "undiscovered"
        return preview

    if occupied(pos):
        preview.reason = "occupied"
        return preview

    if not enough_resources(cost):
        preview.reason = "not enough resources"
        return preview

    preview.ok = true
    preview.production = production
    return preview
```

## Economic Flow

### Early Game (Days 1-3)

```
Start: 0 wood, 0 stone, 0 food, 0 gold

Day 1: Build lumber mill (need to gather wood first)
Day 2: Build farm (need food for upkeep)
Day 3: Build quarry (need stone for towers)
```

### Mid Game (Days 4-10)

```
Focus: Balance production and defense
- Upgrade production buildings
- Build first towers
- Save gold for upgrades
- Temple for wave healing
```

### Late Game (Days 11-20)

```
Focus: Maximize defense
- Tower upgrades
- Workshop for cost reduction
- Barracks for combat bonuses
- Kingdom upgrades
```

## Adding New Buildings

### Step 1: Add to BUILDINGS constant

```gdscript
"new_building": {
    "cost": {"wood": 10, "stone": 5},
    "production": {"special": 2},
    "defense": 0,
    "worker_slots": 1,
    "category": "special",
    "effects": {"special_effect": 0.1}
}
```

### Step 2: Add to BUILDING_UPGRADES

```gdscript
"new_building": {
    "max_level": 3,
    "levels": {
        2: {"cost": {...}, "production": {...}},
        3: {"cost": {...}, "production": {...}, "effects": {...}}
    }
}
```

### Step 3: Add to GameState.BUILDING_KEYS

```gdscript
const BUILDING_KEYS := [..., "new_building"]
```

### Step 4: Handle effects in apply_intent.gd

```gdscript
# If the effect needs special handling
var effects = SimBuildings.get_total_effects(state)
if effects.special_effect > 0:
    // Apply effect
```

## Common Patterns

### Check Building at Position

```gdscript
var index = SimMap.idx(pos.x, pos.y, state.map_w)
var building = state.structures.get(index, "")
var level = SimBuildings.structure_level(state, index)
```

### Get Production Summary

```gdscript
var daily = SimBuildings.daily_production(state)
print("Daily: %d wood, %d stone, %d food" % [
    daily.wood, daily.stone, daily.food
])
```

### Calculate Total Defense

```gdscript
var defense = SimBuildings.total_defense(state)
// Includes wall/tower defense + adjacency bonuses
```

### Apply Building Effects

```gdscript
var effects = SimBuildings.get_total_effects(state)
var heal = effects.wave_heal
if heal > 0:
    state.hp = min(max_hp, state.hp + heal)
```
