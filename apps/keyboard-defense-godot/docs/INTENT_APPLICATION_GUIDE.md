# Intent Application Guide

Core state mutation engine that routes game intents to state modifications.

## Overview

`IntentApplier` (sim/apply_intent.gd) is the central hub for all game state changes. It receives intent dictionaries from the command parser, validates preconditions, applies state modifications, and generates event messages.

## Core Architecture

```
CommandParser.parse() -> Intent Dictionary -> IntentApplier.apply() -> {state, events}
```

All state modifications flow through `apply()` to maintain determinism and enable replay.

## Main Entry Point

```gdscript
static func apply(state: GameState, intent: Dictionary) -> Dictionary:
    # Returns: {"state": GameState, "events": Array[String], "request": Dictionary?}
```

Return values:
- `state` - Modified game state (always a copy, never mutates input)
- `events` - Array of event strings for UI display
- `request` - Optional side-effect request (save, load, autosave)

## Intent Kinds

### Core Game Actions

| Intent | Description | Parameters |
|--------|-------------|------------|
| `help` | Show help text | - |
| `status` | Show current status | - |
| `seed` | Set RNG seed | `seed: String` |
| `restart` | Restart after game over | - |
| `new` | Start fresh run | - |
| `save` | Request save | - |
| `load` | Request load | - |

### Day Phase Actions

| Intent | Description | Parameters |
|--------|-------------|------------|
| `gather` | Gather resources | `resource, amount` |
| `build` | Build structure | `building, x?, y?` |
| `explore` | Discover new tile | - |
| `demolish` | Remove structure | `x?, y?` |
| `upgrade` | Upgrade tower | `x?, y?` |
| `end` | End day, start night | - |

### Navigation Actions

| Intent | Description | Parameters |
|--------|-------------|------------|
| `cursor` | Set cursor position | `x, y` |
| `cursor_move` | Move cursor by delta | `dx, dy, steps?` |
| `inspect` | Inspect tile at cursor | `x?, y?` |
| `map` | Show full map | - |

### Night Phase Actions

| Intent | Description | Parameters |
|--------|-------------|------------|
| `defend_input` | Type word to attack | `text: String` |
| `wait` | Skip turn in combat | - |
| `enemies` | List active enemies | - |

### Lesson/Practice Actions

| Intent | Description | Parameters |
|--------|-------------|------------|
| `lesson_show` | Show current lesson | - |
| `lesson_set` | Change lesson | `lesson_id` |
| `lesson_next` | Cycle to next lesson | - |
| `lesson_prev` | Cycle to previous lesson | - |
| `lesson_sample` | Show sample words | `count?` |

### Event/POI Actions

| Intent | Description | Parameters |
|--------|-------------|------------|
| `interact_poi` | Interact with POI | - |
| `event_choice` | Make event choice | `choice_id, input?` |
| `event_skip` | Skip current event | - |

### Upgrade Actions

| Intent | Description | Parameters |
|--------|-------------|------------|
| `buy_upgrade` | Purchase upgrade | `category, upgrade_id` |
| `ui_upgrades` | Show upgrades list | `category` |

### Open-World Quick Actions

| Intent | Description | Parameters |
|--------|-------------|------------|
| `inspect_tile` | Look at cursor tile | - |
| `gather_at_cursor` | Gather from cursor | - |
| `engage_enemy` | Attack roaming enemy | - |

### UI-Only Actions

| Intent | Description | Parameters |
|--------|-------------|------------|
| `ui_preview` | Set build preview | `building` |
| `ui_overlay` | Toggle map overlay | `name, enabled` |

## State Copy Pattern

All modifications work on a state copy to maintain purity:

```gdscript
static func apply(state: GameState, intent: Dictionary) -> Dictionary:
    var events: Array[String] = []
    var new_state: GameState = _copy_state(state)  # Deep copy
    # ... modify new_state ...
    return {"state": new_state, "events": events}
```

## Common Helper Functions

### Phase Validation

```gdscript
static func _require_day(state: GameState, events: Array[String]) -> bool:
    if state.phase != "day":
        events.append("Can only do that during the day.")
        return false
    return true
```

### Action Point Consumption

```gdscript
static func _consume_ap(state: GameState, events: Array[String]) -> bool:
    if state.ap <= 0:
        events.append("No action points remaining.")
        return false
    state.ap -= 1
    return true
```

### Resource Validation

```gdscript
static func _has_resources(state: GameState, cost: Dictionary) -> bool:
    for key in cost.keys():
        if int(state.resources.get(key, 0)) < int(cost.get(key, 0)):
            return false
    return true

static func _apply_cost(state: GameState, cost: Dictionary) -> void:
    for key in cost.keys():
        state.resources[key] = int(state.resources.get(key, 0)) - int(cost.get(key, 0))
```

### Position Resolution

```gdscript
static func _intent_position(state: GameState, intent: Dictionary) -> Vector2i:
    if intent.has("x") and intent.has("y"):
        return Vector2i(int(intent.x), int(intent.y))
    return state.cursor_pos
```

## Night Phase Combat Flow

The night phase uses a step-based combat system:

```gdscript
static func _advance_night_step(state, hit_enemy_index, apply_miss_penalty, events, hit_word) -> bool:
    # 1. Compute distance field for pathfinding
    var dist_field = SimMap.compute_dist_to_base(state)

    # 2. Apply player attack if hit
    if hit_enemy_index >= 0:
        _apply_player_attack_target(state, hit_enemy_index, hit_word, events)
    else:
        # Apply miss penalty (reduced by upgrades)
        ...

    # 3. Spawn new enemies
    _spawn_enemy_step(state, events)

    # 4. Towers attack
    _tower_attack_step(state, dist_field, events)

    # 5. Enemies move toward base
    _enemy_move_step(state, dist_field, events)

    # 6. Apply enemy abilities
    _enemy_ability_tick(state, events)

    # 7. Check victory/defeat conditions
    if state.hp <= 0:
        state.phase = "game_over"
    if state.night_spawn_remaining <= 0 and state.enemies.is_empty():
        state.phase = "day"
        return true  # Dawn breaks

    return false
```

## Upgrade Integration

Upgrades modify gameplay through multipliers:

```gdscript
# Typing power affects damage
var typing_power: float = SimUpgrades.get_typing_power(state)
var damage: int = int(float(base_damage) * typing_power)

# Critical hits
var crit_chance: float = SimUpgrades.get_critical_chance(state)
if roll <= crit_chance:
    damage *= 2

# Armor pierce
var armor_pierce: int = SimUpgrades.get_armor_pierce(state)
var effective_armor: int = max(0, enemy_armor - armor_pierce)

# Mistake forgiveness
var forgiveness: float = SimUpgrades.get_mistake_forgiveness(state)
if roll <= forgiveness:
    # Miss forgiven, no damage

# Speed reduction
var speed_reduction: float = SimUpgrades.get_enemy_speed_reduction(state)
var reduced_speed: float = float(base_speed) * (1.0 - speed_reduction)
```

## Side Effect Requests

Some intents trigger side effects outside the sim:

```gdscript
# After ending day, request autosave
if _apply_end(new_state, events):
    request = {"kind": "autosave", "reason": "night"}

# After dawn, request autosave
if _apply_defend_input(...):
    request = {"kind": "autosave", "reason": "dawn"}

# Explicit save/load
"save": request = {"kind": "save"}
"load": request = {"kind": "load"}
```

## Adding New Intents

To add a new intent:

1. Add to apply() match statement:
```gdscript
"new_intent":
    _apply_new_intent(new_state, intent, events)
```

2. Implement handler function:
```gdscript
static func _apply_new_intent(state: GameState, intent: Dictionary, events: Array[String]) -> void:
    # Validate preconditions
    if not _require_day(state, events):
        return

    # Extract parameters
    var param: String = str(intent.get("param", ""))

    # Modify state
    state.some_value = param

    # Generate events
    events.append("Did something with %s." % param)
```

3. Add parsing in parse_command.gd (see COMMAND_PARSER_GUIDE.md)

## File Dependencies

- `sim/types.gd` - GameState class
- `sim/default_state.gd` - State factory
- `sim/intents.gd` - Intent factory and help text
- `sim/tick.gd` - Day advancement logic
- `sim/buildings.gd` - Building costs and stats
- `sim/map.gd` - Map operations
- `sim/enemies.gd` - Enemy creation and damage
- `sim/typing_feedback.gd` - Input normalization
- `sim/lessons.gd` - Lesson data
- `sim/words.gd` - Word generation
- `sim/balance.gd` - Balance constants
- `sim/poi.gd` - POI system
- `sim/events.gd` - Event system
- `sim/event_effects.gd` - Event effects
- `sim/upgrades.gd` - Upgrade effects
- `sim/world_tick.gd` - Open-world ticking
