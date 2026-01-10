# Event Tables Guide

This document explains the weighted event selection system that controls which random events can occur based on game state conditions.

## Overview

The event tables system provides conditional, weighted random event selection:

```
Table ID → Load Entries → Filter by Conditions → Check Cooldowns → Weighted Roll
    ↓           ↓                 ↓                    ↓                ↓
"explore"   entries[]      day_range, flags      skip if recent     select one
```

## Table Loading

### Cache System

```gdscript
# sim/event_tables.gd
const TABLES_PATH := "res://data/events/event_tables.json"

static var _tables_cache: Dictionary = {}
static var _loaded: bool = false

static func load_tables() -> void:
    if _loaded:
        return
    _tables_cache = {}
    var file := FileAccess.open(TABLES_PATH, FileAccess.READ)
    if file == null:
        push_warning("SimEventTables: Could not load tables from %s" % TABLES_PATH)
        _loaded = true
        return
    # ... parse JSON and populate cache
    var tables_array: Array = data.get("tables", [])
    for table_data in tables_array:
        var table_id: String = str(table_data.get("id", ""))
        if table_id != "":
            _tables_cache[table_id] = table_data
    _loaded = true
```

### Getting a Table

```gdscript
# sim/event_tables.gd:39
static func get_table(table_id: String) -> Dictionary:
    load_tables()
    return _tables_cache.get(table_id, {})
```

## Condition System

### Check Conditions

```gdscript
# sim/event_tables.gd:43
static func check_conditions(state: GameState, conditions: Array) -> bool:
    for condition in conditions:
        var cond_type: String = str(condition.get("type", ""))
        match cond_type:
            "day_range":
                var min_day: int = int(condition.get("min", 1))
                var max_day: int = int(condition.get("max", 999))
                if state.day < min_day or state.day > max_day:
                    return false
            "resource_min":
                var resource: String = str(condition.get("resource", ""))
                var min_amount: int = int(condition.get("amount", 0))
                var current: int = int(state.resources.get(resource, 0))
                if current < min_amount:
                    return false
            "flag_set":
                var flag: String = str(condition.get("flag", ""))
                var expected: bool = bool(condition.get("value", true))
                var actual: bool = bool(state.event_flags.get(flag, false))
                if actual != expected:
                    return false
            "flag_not_set":
                var flag: String = str(condition.get("flag", ""))
                if state.event_flags.has(flag) and bool(state.event_flags[flag]):
                    return false
    return true
```

### Condition Types

| Type | Parameters | Description |
|------|------------|-------------|
| `day_range` | min, max | Event only valid on days within range |
| `resource_min` | resource, amount | Requires minimum resource amount |
| `flag_set` | flag, value | Requires flag to be set to specific value |
| `flag_not_set` | flag | Requires flag to not be set (or false) |

### Condition Examples

```json
{
  "conditions": [
    {"type": "day_range", "min": 3, "max": 10},
    {"type": "resource_min", "resource": "gold", "amount": 50},
    {"type": "flag_set", "flag": "quest_started", "value": true},
    {"type": "flag_not_set", "flag": "quest_completed"}
  ]
}
```

## Cooldown System

### Check Cooldown

```gdscript
# sim/event_tables.gd:72
static func is_event_on_cooldown(state: GameState, event_id: String) -> bool:
    if not state.event_cooldowns.has(event_id):
        return false
    var cooldown_until: int = int(state.event_cooldowns[event_id])
    return state.day < cooldown_until
```

### Set Cooldown

```gdscript
# sim/event_tables.gd:121
static func set_cooldown(state: GameState, event_id: String, cooldown_days: int) -> void:
    if cooldown_days <= 0:
        return
    state.event_cooldowns[event_id] = state.day + cooldown_days
```

### Clear/Decrement Cooldowns

```gdscript
# sim/event_tables.gd:126
static func clear_cooldown(state: GameState, event_id: String) -> void:
    if state.event_cooldowns.has(event_id):
        state.event_cooldowns.erase(event_id)

static func decrement_cooldowns(state: GameState) -> void:
    var to_remove: Array[String] = []
    for event_id in state.event_cooldowns:
        var cooldown_until: int = int(state.event_cooldowns[event_id])
        if state.day >= cooldown_until:
            to_remove.append(str(event_id))
    for event_id in to_remove:
        state.event_cooldowns.erase(event_id)
```

## Entry Filtering

```gdscript
# sim/event_tables.gd:78
static func filter_entries(state: GameState, entries: Array) -> Array:
    var result: Array = []
    for entry in entries:
        var event_id: String = str(entry.get("event_id", ""))
        if event_id == "":
            continue
        if is_event_on_cooldown(state, event_id):
            continue
        var conditions: Array = entry.get("conditions", [])
        if not check_conditions(state, conditions):
            continue
        result.append(entry)
    return result
```

Entries are filtered out if:
1. Missing event_id
2. On cooldown
3. Conditions not met

## Event Selection

### Main Selection Function

```gdscript
# sim/event_tables.gd:94
static func select_event(state: GameState, table_id: String) -> String:
    var table: Dictionary = get_table(table_id)
    if table.is_empty():
        return ""

    # Check table-level conditions
    var table_conditions: Array = table.get("conditions", [])
    if not check_conditions(state, table_conditions):
        return ""

    var entries: Array = table.get("entries", [])
    var filtered: Array = filter_entries(state, entries)
    if filtered.is_empty():
        return ""

    # Calculate total weight
    var total_weight: int = 0
    for entry in filtered:
        total_weight += int(entry.get("weight", 1))
    if total_weight <= 0:
        return ""

    # Roll weighted selection
    var roll: int = SimRng.roll_range(state, 1, total_weight)
    var running: int = 0
    for entry in filtered:
        running += int(entry.get("weight", 1))
        if roll <= running:
            return str(entry.get("event_id", ""))
    return ""
```

### Weighted Selection Algorithm

1. Filter entries by conditions and cooldowns
2. Sum all weights
3. Roll random number 1 to total_weight
4. Walk through entries, accumulating weights
5. Return first entry where accumulated weight >= roll

## JSON Schema

### Table Structure

```json
{
  "tables": [
    {
      "id": "exploration_events",
      "conditions": [],
      "entries": [
        {
          "event_id": "merchant_encounter",
          "weight": 10,
          "conditions": [
            {"type": "day_range", "min": 2}
          ]
        },
        {
          "event_id": "resource_cache",
          "weight": 20,
          "conditions": []
        },
        {
          "event_id": "ambush",
          "weight": 15,
          "conditions": [
            {"type": "day_range", "min": 3}
          ]
        }
      ]
    }
  ]
}
```

### Entry Fields

| Field | Type | Description |
|-------|------|-------------|
| `event_id` | String | ID of event to trigger |
| `weight` | int | Selection weight (higher = more likely) |
| `conditions` | Array | Entry-specific conditions |

## Integration Examples

### Exploration Event Selection

```gdscript
func _on_explore() -> void:
    var event_id: String = SimEventTables.select_event(state, "exploration_events")
    if event_id != "":
        _trigger_event(event_id)
        # Set cooldown so same event doesn't repeat immediately
        SimEventTables.set_cooldown(state, event_id, 3)
```

### Daily Event Check

```gdscript
func _on_day_start() -> void:
    # Clean up expired cooldowns
    SimEventTables.decrement_cooldowns(state)

    # Check for daily random event
    var event_id: String = SimEventTables.select_event(state, "daily_events")
    if event_id != "":
        _queue_event(event_id)
```

### Conditional Table Selection

```gdscript
func _select_combat_event() -> String:
    # Try special combat events first
    var special: String = SimEventTables.select_event(state, "special_combat")
    if special != "":
        return special

    # Fall back to normal combat events
    return SimEventTables.select_event(state, "normal_combat")
```

### Building Event Tables

```gdscript
# Example data/events/event_tables.json
var tables_data := {
    "tables": [
        {
            "id": "poi_discovery",
            "conditions": [],
            "entries": [
                {"event_id": "ruins_found", "weight": 15},
                {"event_id": "village_found", "weight": 20},
                {"event_id": "shrine_found", "weight": 10, "conditions": [
                    {"type": "day_range", "min": 5}
                ]},
                {"event_id": "nothing_found", "weight": 30}
            ]
        }
    ]
}
```

## Testing

```gdscript
func test_condition_day_range():
    var state := GameState.new()
    state.day = 5

    var conditions := [{"type": "day_range", "min": 3, "max": 10}]
    assert(SimEventTables.check_conditions(state, conditions))

    state.day = 2
    assert(not SimEventTables.check_conditions(state, conditions))

    state.day = 11
    assert(not SimEventTables.check_conditions(state, conditions))

    _pass("test_condition_day_range")

func test_condition_resource_min():
    var state := GameState.new()
    state.resources["gold"] = 100

    var conditions := [{"type": "resource_min", "resource": "gold", "amount": 50}]
    assert(SimEventTables.check_conditions(state, conditions))

    state.resources["gold"] = 25
    assert(not SimEventTables.check_conditions(state, conditions))

    _pass("test_condition_resource_min")

func test_cooldown_system():
    var state := GameState.new()
    state.day = 5

    assert(not SimEventTables.is_event_on_cooldown(state, "test_event"))

    SimEventTables.set_cooldown(state, "test_event", 3)
    assert(SimEventTables.is_event_on_cooldown(state, "test_event"))

    state.day = 8
    assert(not SimEventTables.is_event_on_cooldown(state, "test_event"))

    _pass("test_cooldown_system")

func test_weighted_selection():
    # Note: This test uses mocked RNG for determinism
    var state := GameState.new()
    state.day = 1

    # With weights [10, 20, 30], total = 60
    # Roll 1-10 = first, 11-30 = second, 31-60 = third

    _pass("test_weighted_selection")
```
