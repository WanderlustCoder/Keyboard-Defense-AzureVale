# Progression State Guide

This document explains the campaign progression system that manages map nodes, upgrades, gold, combat modifiers, and player mastery tracking.

## Overview

The ProgressionState autoload manages campaign progression:

```
Load Static Data → Track Progress → Apply Upgrades → Save/Load
       ↓                ↓               ↓              ↓
   lessons.json    completed_nodes   modifiers    save.json
   map.json        purchased_upgrades
   drills.json
```

## Data Paths

```gdscript
# scripts/ProgressionState.gd
const LESSONS_PATH := "res://data/lessons.json"
const MAP_PATH := "res://data/map.json"
const DRILLS_PATH := "res://data/drills.json"
const KINGDOM_UPGRADES_PATH := "res://data/kingdom_upgrades.json"
const UNIT_UPGRADES_PATH := "res://data/unit_upgrades.json"
const SAVE_PATH := "user://typing_kingdom_save.json"
```

## State Variables

### Static Data (loaded once)

```gdscript
var lessons: Dictionary = {}           # lesson_id -> lesson data
var map_nodes: Dictionary = {}         # node_id -> node data
var map_order: Array = []              # Ordered node IDs
var drill_templates: Dictionary = {}   # template_id -> drill plan
var kingdom_upgrades: Dictionary = {}  # upgrade_id -> upgrade data
var kingdom_order: Array = []          # Ordered kingdom upgrade IDs
var unit_upgrades: Dictionary = {}     # upgrade_id -> upgrade data
var unit_order: Array = []             # Ordered unit upgrade IDs
```

### Dynamic State (saved/loaded)

```gdscript
var persistence_enabled: bool = true
var gold: int = 0
var completed_nodes: Dictionary = {}    # node_id -> true
var purchased_upgrades: Dictionary = {} # upgrade_id -> true
var modifiers: Dictionary = {}          # Combat modifiers
var mastery: Dictionary = {}            # Best/last performance
var last_summary: Dictionary = {}       # Last battle summary
var tutorial_completed: bool = false
var battles_played: int = 0
```

## Default Values

### Combat Modifiers

```gdscript
const DEFAULT_MODIFIERS := {
    "typing_power": 1.0,            # Damage multiplier
    "threat_rate_multiplier": 1.0,  # Threat accumulation rate
    "mistake_forgiveness": 0.0,     # Error damage reduction (0-0.6)
    "castle_health_bonus": 0        # Extra HP
}
```

### Mastery Tracking

```gdscript
const DEFAULT_MASTERY := {
    "best_accuracy": 0.0,
    "best_wpm": 0.0,
    "last_accuracy": 0.0,
    "last_wpm": 0.0
}
```

## Performance Tiers

```gdscript
const PERFORMANCE_TIERS := [
    {
        "id": "S",
        "accuracy": 0.96,     # 96%+
        "wpm": 32.0,          # 32+ WPM
        "bonus_gold": 6
    },
    {
        "id": "A",
        "accuracy": 0.93,
        "wpm": 26.0,
        "bonus_gold": 4
    },
    {
        "id": "B",
        "accuracy": 0.88,
        "wpm": 18.0,
        "bonus_gold": 2
    },
    {
        "id": "C",
        "accuracy": 0.0,
        "wpm": 0.0,
        "bonus_gold": 0
    }
]
```

| Tier | Accuracy | WPM | Bonus Gold |
|------|----------|-----|------------|
| S | 96%+ | 32+ | +6g |
| A | 93%+ | 26+ | +4g |
| B | 88%+ | 18+ | +2g |
| C | Any | Any | +0g |

## Initialization

```gdscript
# scripts/ProgressionState.gd:67
func _ready() -> void:
    _load_static_data()
    _load_save()

func _load_static_data() -> void:
    # Clear all caches
    lessons.clear()
    map_nodes.clear()
    # ...

    # Load lessons
    var lessons_data = _load_json(LESSONS_PATH)
    for entry in lessons_data.get("lessons", []):
        var lesson_id := str(entry.get("id", ""))
        if lesson_id != "":
            lessons[lesson_id] = entry

    # Load map nodes
    var map_data = _load_json(MAP_PATH)
    for node in map_data.get("nodes", []):
        var node_id := str(node.get("id", ""))
        if node_id != "":
            map_nodes[node_id] = node
            map_order.append(node_id)

    # Load drill templates
    var drills_data = _load_json(DRILLS_PATH)
    for entry in drills_data.get("templates", []):
        var template_id := str(entry.get("id", ""))
        if template_id != "":
            drill_templates[template_id] = entry

    # Load upgrades
    # ...
```

## Node Progression

### Check Unlock Status

```gdscript
# scripts/ProgressionState.gd:139
func is_node_unlocked(node_id: String) -> bool:
    var node = map_nodes.get(node_id)
    if node == null:
        return false
    var requires: Array = node.get("requires", [])
    for req in requires:
        if not completed_nodes.has(req):
            return false
    return true

func is_node_completed(node_id: String) -> bool:
    return completed_nodes.has(node_id)
```

### Complete Node

```gdscript
# scripts/ProgressionState.gd:152
func complete_node(node_id: String, summary: Dictionary) -> Dictionary:
    var node = map_nodes.get(node_id)
    if node == null:
        return summary

    var is_first := not completed_nodes.has(node_id)
    completed_nodes[node_id] = true

    # Calculate gold rewards
    var reward_gold := int(node.get("reward_gold", 0))
    var practice_gold := 3  # Base reward for any completion
    var performance := _evaluate_performance(summary)
    var performance_bonus := int(performance.get("bonus_gold", 0))

    var gold_awarded := practice_gold + performance_bonus
    if is_first:
        gold_awarded += reward_gold  # First-time bonus

    gold += gold_awarded

    # Build result summary
    last_summary = summary.duplicate()
    last_summary["gold_awarded"] = gold_awarded
    last_summary["reward_gold"] = reward_gold
    last_summary["practice_gold"] = practice_gold
    last_summary["performance_tier"] = performance.get("id", "")
    last_summary["performance_bonus"] = performance_bonus

    _update_mastery(summary)
    _save()

    return last_summary
```

### Gold Reward Calculation

| Source | Amount | When |
|--------|--------|------|
| Practice Gold | +3g | Every completion |
| First-Time Bonus | +node.reward_gold | First completion only |
| Performance Bonus | +0 to +6g | Based on tier |

## Combat Modifiers

### Get Active Modifiers

```gdscript
# scripts/ProgressionState.gd:202
func get_combat_modifiers() -> Dictionary:
    var typing_power: float = clamp(float(modifiers.get("typing_power", 1.0)), 0.6, 2.5)
    var threat_rate_multiplier: float = clamp(float(modifiers.get("threat_rate_multiplier", 1.0)), 0.4, 1.6)
    var mistake_forgiveness: float = clamp(float(modifiers.get("mistake_forgiveness", 0.0)), 0.0, 0.6)
    var castle_health_bonus := int(modifiers.get("castle_health_bonus", 0))

    return {
        "typing_power": typing_power,
        "threat_rate_multiplier": threat_rate_multiplier,
        "mistake_forgiveness": mistake_forgiveness,
        "castle_health_bonus": castle_health_bonus
    }
```

### Modifier Bounds

| Modifier | Min | Max | Effect |
|----------|-----|-----|--------|
| typing_power | 0.6 | 2.5 | Damage multiplier |
| threat_rate_multiplier | 0.4 | 1.6 | Threat speed |
| mistake_forgiveness | 0.0 | 0.6 | Error reduction |
| castle_health_bonus | - | - | Extra HP |

## Upgrade System

### Apply Upgrade

```gdscript
# scripts/ProgressionState.gd:231
func apply_upgrade(upgrade_id: String) -> bool:
    # Check if already owned
    if purchased_upgrades.has(upgrade_id):
        return false

    # Find upgrade definition
    var upgrade = kingdom_upgrades.get(upgrade_id, null)
    if upgrade == null:
        upgrade = unit_upgrades.get(upgrade_id, null)
    if upgrade == null:
        return false

    # Check cost
    var cost := int(upgrade.get("cost", 0))
    if gold < cost:
        return false

    # Purchase
    gold -= cost
    purchased_upgrades[upgrade_id] = true

    # Apply effects
    var effects: Dictionary = upgrade.get("effects", {})
    for key in effects.keys():
        if key == "castle_health_bonus":
            modifiers["castle_health_bonus"] = int(modifiers.get("castle_health_bonus", 0)) + int(effects[key])
        else:
            modifiers[key] = float(modifiers.get(key, 0.0)) + float(effects[key])

    _save()
    return true
```

### Upgrade Effects

Upgrades modify combat through effects like:
```json
{
    "effects": {
        "typing_power": 0.1,           // +10% damage
        "threat_rate_multiplier": -0.05, // -5% threat rate
        "mistake_forgiveness": 0.1,     // +10% error reduction
        "castle_health_bonus": 1        // +1 HP
    }
}
```

## Mastery Tracking

```gdscript
# scripts/ProgressionState.gd:176
func _update_mastery(summary: Dictionary) -> void:
    var accuracy := float(summary.get("accuracy", 0.0))
    var wpm := float(summary.get("wpm", 0.0))

    mastery["last_accuracy"] = accuracy
    mastery["last_wpm"] = wpm
    mastery["best_accuracy"] = max(mastery.get("best_accuracy", 0.0), accuracy)
    mastery["best_wpm"] = max(mastery.get("best_wpm", 0.0), wpm)
```

## Tutorial Tracking

```gdscript
# scripts/ProgressionState.gd:292
func should_show_battle_tutorial() -> bool:
    return not tutorial_completed and battles_played == 0

func mark_battle_started() -> void:
    battles_played += 1
    _save()

func mark_tutorial_completed() -> void:
    tutorial_completed = true
    _save()

func reset_tutorial() -> void:
    tutorial_completed = false
    _save()
```

## Save/Load

### Save Format

```gdscript
# scripts/ProgressionState.gd:274
func _save() -> void:
    if not persistence_enabled:
        return

    var data := {
        "gold": gold,
        "completed_nodes": completed_nodes,
        "purchased_upgrades": purchased_upgrades,
        "modifiers": modifiers,
        "mastery": mastery,
        "last_summary": last_summary,
        "tutorial_completed": tutorial_completed,
        "battles_played": battles_played
    }

    var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file == null:
        return
    file.store_string(JSON.stringify(data))
```

### Load

```gdscript
# scripts/ProgressionState.gd:253
func _load_save() -> void:
    if not persistence_enabled:
        return
    if not FileAccess.file_exists(SAVE_PATH):
        return

    var data = _load_json(SAVE_PATH)
    gold = int(data.get("gold", 0))
    completed_nodes = data.get("completed_nodes", {})
    purchased_upgrades = data.get("purchased_upgrades", {})

    # Merge saved modifiers with defaults
    var saved_modifiers: Dictionary = data.get("modifiers", {})
    modifiers = DEFAULT_MODIFIERS.duplicate(true)
    for key in saved_modifiers.keys():
        modifiers[key] = saved_modifiers[key]

    # Merge mastery
    var saved_mastery: Dictionary = data.get("mastery", {})
    mastery = DEFAULT_MASTERY.duplicate(true)
    for key in saved_mastery.keys():
        mastery[key] = saved_mastery[key]

    last_summary = data.get("last_summary", {})
    tutorial_completed = bool(data.get("tutorial_completed", false))
    battles_played = int(data.get("battles_played", 0))
```

## API Reference

### Lesson Access

```gdscript
func get_lesson(lesson_id: String) -> Dictionary:
    return lessons.get(lesson_id, {})
```

### Map Access

```gdscript
func get_map_nodes() -> Array:
    var result: Array = []
    for node_id in map_order:
        if map_nodes.has(node_id):
            result.append(map_nodes[node_id])
    return result
```

### Drill Templates

```gdscript
func get_drill_template(template_id: String) -> Dictionary:
    return drill_templates.get(template_id, {})
```

### Upgrades

```gdscript
func get_kingdom_upgrades() -> Array
func get_unit_upgrades() -> Array
func is_upgrade_owned(upgrade_id: String) -> bool
```

## Testing

```gdscript
func test_node_unlock_chain():
    var progression := preload("res://scripts/ProgressionState.gd").new()
    progression.persistence_enabled = false
    progression._load_static_data()

    # Node B requires Node A
    assert(not progression.is_node_unlocked("node_b"))

    progression.completed_nodes["node_a"] = true
    assert(progression.is_node_unlocked("node_b"))

    _pass("test_node_unlock_chain")

func test_upgrade_application():
    var progression := preload("res://scripts/ProgressionState.gd").new()
    progression.persistence_enabled = false
    progression._load_static_data()
    progression.gold = 100

    var initial_power := progression.modifiers.get("typing_power", 1.0)
    var success := progression.apply_upgrade("upgrade_typing_1")

    if success:
        assert(progression.modifiers.get("typing_power", 1.0) > initial_power)

    _pass("test_upgrade_application")

func test_performance_tiers():
    var progression := preload("res://scripts/ProgressionState.gd").new()

    var summary_s := {"accuracy": 0.98, "wpm": 35.0}
    var tier_s := progression._evaluate_performance(summary_s)
    assert(tier_s.get("id", "") == "S")

    var summary_c := {"accuracy": 0.70, "wpm": 10.0}
    var tier_c := progression._evaluate_performance(summary_c)
    assert(tier_c.get("id", "") == "C")

    _pass("test_performance_tiers")
```
