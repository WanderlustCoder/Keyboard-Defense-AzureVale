# State Management Patterns

This document explains the state management architecture in Keyboard Defense. Understanding these patterns is critical for safely adding new features.

## Core Principle: Single Source of Truth

All game state lives in a single `GameState` object (`sim/types.gd`). The game layer holds a reference to this object and renders it to the screen.

```
GameState (sim/types.gd)
    ↑
    │ passed to
    ↓
IntentApplier.apply(state, intent)
    │
    │ returns
    ↓
{state: modified_copy, events: [...]}
    │
    │ renders
    ↓
game/main.gd → UI
```

## The Copy-on-Modify Pattern

### Why Copy?

The `apply()` function creates a **copy** of state before modifying it:

```gdscript
static func apply(state: GameState, intent: Dictionary) -> Dictionary:
    var new_state: GameState = _copy_state(state)  # ← COPY HERE
    # ... modify new_state ...
    return {"state": new_state, "events": events}
```

**Reasons:**
1. **Atomicity** - If an operation fails partway, original state is unchanged
2. **Undo potential** - Could keep old state for undo (not currently implemented)
3. **Debugging** - Can compare before/after states
4. **Determinism** - Ensures predictable state transitions

### The `_copy_state()` Function

Located at `sim/apply_intent.gd:1151`:

```gdscript
static func _copy_state(state: GameState) -> GameState:
    var copy: GameState = GameState.new()

    # Primitives - direct copy
    copy.day = state.day
    copy.phase = state.phase
    copy.ap = state.ap
    copy.hp = state.hp
    # ... all primitive fields ...

    # Containers - deep copy required!
    copy.resources = state.resources.duplicate(true)
    copy.buildings = state.buildings.duplicate(true)
    copy.terrain = state.terrain.duplicate(true)
    copy.structures = state.structures.duplicate(true)
    copy.enemies = state.enemies.duplicate(true)
    # ... all container fields ...

    return copy
```

**CRITICAL**: Every field in `GameState` must be copied here!

## Adding New State Fields

When adding a new field to `GameState`:

### Step 1: Add to `sim/types.gd`

```gdscript
# In GameState class
var new_field: int
var new_dict: Dictionary
var new_array: Array
```

### Step 2: Initialize in `_init()`

```gdscript
func _init() -> void:
    # ... existing init ...
    new_field = 0
    new_dict = {}
    new_array = []
```

### Step 3: Add to `_copy_state()`

```gdscript
static func _copy_state(state: GameState) -> GameState:
    # ... existing copies ...

    # New fields - ADD THESE
    copy.new_field = state.new_field
    copy.new_dict = state.new_dict.duplicate(true)
    copy.new_array = state.new_array.duplicate(true)

    return copy
```

### Step 4: Add to Save/Load (`sim/save.gd`)

```gdscript
# In to_dict()
static func to_dict(state: GameState) -> Dictionary:
    return {
        # ... existing fields ...
        "new_field": state.new_field,
        "new_dict": state.new_dict,
        "new_array": state.new_array,
    }

# In from_dict()
static func from_dict(data: Dictionary) -> GameState:
    var state = GameState.new()
    # ... existing loads ...
    state.new_field = data.get("new_field", 0)
    state.new_dict = data.get("new_dict", {})
    state.new_array = data.get("new_array", [])
    return state
```

## State Categories

### Core Session State
```gdscript
var day: int              # Current day number
var phase: String         # "day", "night", "game_over", "victory"
var ap_max: int           # Maximum action points
var ap: int               # Current action points
var hp: int               # Castle health
var threat: int           # Legacy threat (integer)
```

### Map State
```gdscript
var map_w: int            # Map width
var map_h: int            # Map height
var base_pos: Vector2i    # Castle position
var cursor_pos: Vector2i  # Player cursor
var terrain: Array        # Flat array of terrain types
var structures: Dictionary # {tile_index: building_type}
var structure_levels: Dictionary  # {tile_index: level}
var discovered: Dictionary # {tile_index: true}
```

### Combat State
```gdscript
var enemies: Array        # Active combat enemies
var enemy_next_id: int    # ID counter for enemies
var night_prompt: String  # Current word being typed
var night_spawn_remaining: int  # Enemies left to spawn
var night_wave_total: int # Total enemies this wave
```

### Economy State
```gdscript
var resources: Dictionary # {"wood": 0, "stone": 0, "food": 0}
var buildings: Dictionary # {"farm": 0, "lumber": 0, ...}
var gold: int             # Gold currency
```

### Progression State
```gdscript
var lesson_id: String     # Current lesson
var purchased_kingdom_upgrades: Array
var purchased_unit_upgrades: Array
var completed_research: Array
var active_research: String
var research_progress: int
```

### Open World State
```gdscript
var roaming_enemies: Array    # Enemies on world map
var roaming_resources: Array  # Resources on world map
var threat_level: float       # 0.0 to 1.0
var time_of_day: float        # 0.0 to 1.0
var world_tick_accum: float   # Delta accumulator
var activity_mode: String     # Current mode
var encounter_enemies: Array  # Encounter combatants
var wave_cooldown: float      # Wave immunity timer
```

### Event State
```gdscript
var active_pois: Dictionary   # {tile_index: poi_data}
var event_cooldowns: Dictionary
var event_flags: Dictionary
var pending_event: Dictionary
var active_buffs: Array
```

### Settings State
```gdscript
var speed_multiplier: float   # Game speed (accessibility)
var practice_mode: bool       # No damage on miss
```

### RNG State
```gdscript
var rng_seed: String      # Seed string
var rng_state: int        # RNG internal state
```

## Deep Copy Requirements

**Always use `.duplicate(true)` for:**
- Dictionaries containing nested structures
- Arrays containing dictionaries
- Any container with mutable contents

**Examples:**
```gdscript
# Wrong - shallow copy, shares references
copy.enemies = state.enemies.duplicate()

# Right - deep copy, independent data
copy.enemies = state.enemies.duplicate(true)
```

## State Access Patterns

### Reading State (Safe)
```gdscript
# In game layer - read directly
var current_hp = state.hp
var wood = state.resources.get("wood", 0)
```

### Modifying State (Must Use Intents)
```gdscript
# Wrong - direct modification
state.hp -= 1  # DON'T DO THIS

# Right - use intent system
var intent = SimIntents.make("damage", {"amount": 1})
var result = IntentApplier.apply(state, intent)
state = result.state
```

### In Sim Layer (After Copy)
```gdscript
# Inside apply_intent.gd handlers, modifying new_state is safe
static func _apply_some_effect(state: GameState, events: Array[String]) -> void:
    state.hp -= 1  # This is the copied state, OK to modify
    events.append("Lost 1 HP.")
```

## Version Management

State has a version field for save compatibility:

```gdscript
var version: int  # Increment when schema changes

# In save.gd
static func from_dict(data: Dictionary) -> GameState:
    var state = GameState.new()
    var version = data.get("version", 1)

    # Handle old versions
    if version < 2:
        # Migrate from v1 to v2
        state.new_field = calculate_default()
    else:
        state.new_field = data.get("new_field", 0)

    return state
```

## Common Pitfalls

### 1. Forgetting to Copy New Fields
```gdscript
# WRONG - field not copied, becomes stale
# (Field exists in GameState but not in _copy_state)

# RIGHT - add to _copy_state()
copy.new_field = state.new_field
```

### 2. Shallow Copy of Nested Data
```gdscript
# WRONG - enemies share references
copy.enemies = state.enemies

# RIGHT - deep copy
copy.enemies = state.enemies.duplicate(true)
```

### 3. Modifying Passed State
```gdscript
# WRONG - modifies original
static func do_thing(state: GameState) -> void:
    state.hp -= 1  # Modifies original!

# RIGHT - work on copy
static func apply(state: GameState) -> Dictionary:
    var new_state = _copy_state(state)
    new_state.hp -= 1
    return {"state": new_state, ...}
```

### 4. Missing Save/Load Sync
```gdscript
# Adding field to GameState but forgetting save.gd
# Results in: data loss on save/load
```

## Testing State Changes

```gdscript
func test_state_copy():
    var original = GameState.new()
    original.hp = 10
    original.enemies.append({"id": 1})

    var copy = IntentApplier._copy_state(original)
    copy.hp = 5
    copy.enemies[0]["id"] = 99

    # Original should be unchanged
    assert(original.hp == 10, "HP should not change")
    assert(original.enemies[0]["id"] == 1, "Enemy should not change")
    _pass("test_state_copy")
```

## Checklist for New State Fields

- [ ] Added to `sim/types.gd` class definition
- [ ] Initialized in `_init()`
- [ ] Copied in `sim/apply_intent.gd:_copy_state()`
- [ ] Serialized in `sim/save.gd:to_dict()`
- [ ] Deserialized in `sim/save.gd:from_dict()`
- [ ] Default value handles missing data (save compatibility)
- [ ] Deep copy used for containers
- [ ] Version bump if breaking change
