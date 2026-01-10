# Sim Utilities Guide

Core simulation utilities: state, RNG, intents, commands, tick, and balance.

## Overview

This guide covers the foundational sim-layer utilities that support the game simulation:
- `types.gd` - GameState class definition
- `rng.gd` - Deterministic random number generation
- `intents.gd` - Intent factory and help system
- `command_keywords.gd` - Command registry
- `tick.gd` - Day advancement and wave setup
- `balance.gd` - Balance constants and catch-up mechanics
- `default_state.gd` - Initial state factory

## GameState (sim/types.gd)

Central data structure holding all mutable game state.

### Constants

```gdscript
const RESOURCE_KEYS := ["wood", "stone", "food"]
const BUILDING_KEYS := ["farm", "lumber", "quarry", "wall", "tower", "market", "barracks", "temple", "workshop"]
```

### Core Fields

```gdscript
# Progression
var day: int
var phase: String          # "day", "night", "game_over", "victory"
var ap_max: int
var ap: int                # Current action points
var hp: int                # Castle health
var threat: int            # Accumulated threat level
var gold: int              # Currency for upgrades

# Resources
var resources: Dictionary  # {"wood": 0, "stone": 0, "food": 0}
var buildings: Dictionary  # {"farm": 0, "tower": 2, ...}
```

### Map Fields

```gdscript
var map_w: int
var map_h: int
var base_pos: Vector2i
var cursor_pos: Vector2i
var terrain: Array         # Flat array, index = y * map_w + x
var structures: Dictionary # {index: "building_type"}
var structure_levels: Dictionary  # {index: level}
var discovered: Dictionary # {index: true}
```

### Combat Fields

```gdscript
var enemies: Array         # Array of enemy dictionaries
var enemy_next_id: int
var night_prompt: String
var night_spawn_remaining: int
var night_wave_total: int
var last_path_open: bool
```

### Lesson/Typing Fields

```gdscript
var lesson_id: String
var rng_state: int
var rng_seed: String
```

### Event/Upgrade Fields

```gdscript
var active_pois: Dictionary
var event_cooldowns: Dictionary
var event_flags: Dictionary
var pending_event: Dictionary
var active_buffs: Array
var purchased_kingdom_upgrades: Array
var purchased_unit_upgrades: Array
```

### Worker/Research Fields

```gdscript
var workers: Dictionary    # {"farm": 2, "lumber": 1, ...}
var total_workers: int
var active_research: String
var research_progress: int
var completed_research: Array
var trade_rates: Dictionary
```

### Accessibility/Open-World Fields

```gdscript
var speed_multiplier: float
var practice_mode: bool
var roaming_enemies: Array
var roaming_resources: Array
var threat_level: float
var activity_mode: String  # "exploration", "encounter", "event", "wave_assault"
var time_of_day: float
var wave_cooldown: float
var world_tick_accum: float
```

## SimRng (sim/rng.gd)

Deterministic RNG for reproducible gameplay.

### Functions

```gdscript
# Convert seed string to integer
static func seed_to_int(seed: String) -> int

# Initialize state's RNG
static func seed_state(state: GameState, seed_string: String) -> void

# Roll integer in range [min, max]
static func roll_range(state: GameState, min_value: int, max_value: int) -> int

# Randomly select from array
static func choose(state: GameState, arr: Array) -> Variant
```

### Usage

```gdscript
# Seeding a new game
SimRng.seed_state(state, "my_seed")

# Rolling values
var roll = SimRng.roll_range(state, 1, 100)
var enemy_kind = SimRng.choose(state, ["raider", "scout", "armored"])
```

## SimIntents (sim/intents.gd)

Intent factory and help system.

### Intent Factory

```gdscript
static func make(kind: String, data: Dictionary = {}) -> Dictionary:
    # Returns: {"kind": kind, ...data}

# Examples:
SimIntents.make("help")
# {"kind": "help"}

SimIntents.make("build", {"building": "tower", "x": 5, "y": 3})
# {"kind": "build", "building": "tower", "x": 5, "y": 3}
```

### Help System

```gdscript
static func help_lines() -> Array[String]:
    # Returns 50+ lines of command documentation
```

Help categories:
- Core: help, version, status
- Resources: gather, build, explore
- Events: interact, choice, skip
- Upgrades: upgrades, buy
- Navigation: cursor, inspect, map
- Combat: defend, wait, enemies
- UI: settings, bind, history, trend, goal, report
- Lessons: lesson, lessons, tutorial

## CommandKeywords (sim/command_keywords.gd)

Registry of all valid game commands.

```gdscript
const KEYWORDS: Array[String] = [
    "help", "version", "status", "balance", "gather", "build", "explore",
    "interact", "choice", "skip", "buy", "upgrades", "end", "seed", "defend",
    "wait", "save", "load", "new", "restart", "cursor", "inspect", "map",
    "overlay", "preview", "upgrade", "demolish", "enemies", "goal", "lesson",
    "lessons", "settings", "bind", "report", "history", "trend", "tutorial"
]

static func keywords() -> Array[String]:
    return KEYWORDS
```

Used by command parser for validation and autocomplete.

## SimTick (sim/tick.gd)

Day advancement and night wave setup.

### Constants

```gdscript
const NIGHT_WAVE_BASE_BY_DAY := {1: 2, 2: 3, 3: 3, 4: 4, 5: 5, 6: 6, 7: 7}

const NIGHT_PROMPTS := [
    "bastion", "banner", "citadel", "ember", "forge",
    "lantern", "rune", "shield", "spear", "ward"
]
```

### Day Advancement

```gdscript
static func advance_day(state: GameState) -> Dictionary:
    # 1. Increment day counter
    # 2. Calculate building production
    # 3. Apply midgame bonuses
    # 4. Enforce resource caps
    # Returns: {"state": state, "events": Array[String]}
```

### Night Wave Setup

```gdscript
static func compute_night_wave_total(state: GameState, defense: int) -> int:
    # Base: lookup from NIGHT_WAVE_BASE_BY_DAY
    # + threat contribution
    # - defense reduction
    # Minimum: 1

static func build_night_prompt(state: GameState) -> String:
    # Randomly selects from NIGHT_PROMPTS
```

## SimBalance (sim/balance.gd)

Balance constants and catch-up mechanics.

### Midgame Constants

```gdscript
const MIDGAME_STONE_CATCHUP_DAY := 4
const MIDGAME_STONE_CATCHUP_MIN := 10

const MIDGAME_FOOD_BONUS_DAY := 4
const MIDGAME_FOOD_BONUS_THRESHOLD := 12
const MIDGAME_FOOD_BONUS_AMOUNT := 2
```

### Resource Caps

```gdscript
const MIDGAME_CAPS_DAY5 := {"wood": 40, "stone": 20, "food": 25}
const MIDGAME_CAPS_DAY7 := {"wood": 50, "stone": 35, "food": 35}

static func caps_for_day(day: int) -> Dictionary
static func apply_resource_caps(state: GameState) -> Dictionary
```

### Catch-Up Mechanics

```gdscript
# Redirect explore rewards to stone if lacking
static func maybe_override_explore_reward(state: GameState, reward_resource: String) -> String

# Provide bonus food if below threshold
static func midgame_food_bonus(state: GameState) -> int
```

## DefaultState (sim/default_state.gd)

Factory for creating initial game state.

```gdscript
static func create(seed: String = "default") -> GameState:
    var state: GameState = GameState.new()
    SimRng.seed_state(state, seed)
    state.lesson_id = SimLessons.default_lesson_id()
    SimMap.generate_terrain(state)
    # Find plains tile for base
    state.gold = 10
    return state
```

## Integration Example

```gdscript
# Creating a new game
var state = DefaultState.create("my_seed")

# Processing a command
var parsed = CommandParser.parse("build tower 5 3")
if parsed.ok:
    var intent = parsed.intent
    var result = IntentApplier.apply(state, intent)
    state = result.state
    for event in result.events:
        print(event)

# Advancing to night
var tick_result = SimTick.advance_day(state)
state.phase = "night"
state.night_wave_total = SimTick.compute_night_wave_total(state, defense)
```

## File Dependencies

All utilities are in `sim/` and depend on:
- `sim/types.gd` - GameState class (no dependencies)
- `sim/rng.gd` - Random (depends on types)
- `sim/intents.gd` - Intents (depends on command_keywords, rebindable_actions)
- `sim/command_keywords.gd` - Keywords (no dependencies)
- `sim/tick.gd` - Tick (depends on types, buildings, balance)
- `sim/balance.gd` - Balance (depends on types)
- `sim/default_state.gd` - Factory (depends on types, rng, lessons, map)
