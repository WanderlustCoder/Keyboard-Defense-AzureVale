# Threat & Wave System Guide

This document explains the unified threat system that drives combat pacing in Keyboard Defense. Inspired by Super Fantasy Kingdom's day/night cycle, this system creates tension through escalating threat that triggers combat waves.

## System Overview

```
Exploration → Threat Rises → Wave Assault Triggered → Combat → Threat Resets → Exploration
```

The threat system replaces rigid day/night phases with a dynamic flow where player actions and enemy proximity influence when combat occurs.

## Activity Modes

The game operates in four activity modes:

| Mode | Phase | Description |
|------|-------|-------------|
| `exploration` | day | Player explores, builds, gathers |
| `encounter` | night | Small fight (enemy reached castle) |
| `wave_assault` | night | Full wave triggered by high threat |
| `event` | day | POI event in progress |

```gdscript
# In GameState (sim/types.gd)
var activity_mode: String  # "exploration", "encounter", "event", "wave_assault"
var threat_level: float    # 0.0 to 1.0
var wave_cooldown: float   # Seconds until next wave can trigger
```

## Threat Mechanics

### Threat Level (`sim/world_tick.gd`)

Threat is a float from 0.0 to 1.0 that represents danger level:

```gdscript
const THREAT_DECAY_RATE := 0.01    # Per tick when safe
const THREAT_GROWTH_RATE := 0.02   # Per tick per nearby enemy
const WAVE_ASSAULT_THRESHOLD := 0.8 # Triggers wave assault
```

### Threat Growth

Threat increases when roaming enemies are near the castle:

```gdscript
static func _tick_threat_level(state: GameState) -> void:
    var enemies_near_castle: int = 0
    var castle_dist_threshold := 5

    for entity in state.roaming_enemies:
        var pos = entity.get("pos", Vector2i.ZERO)
        var dist = abs(pos.x - state.base_pos.x) + abs(pos.y - state.base_pos.y)
        if dist <= castle_dist_threshold:
            enemies_near_castle += 1

    if enemies_near_castle > 0:
        state.threat_level = min(1.0, state.threat_level + THREAT_GROWTH_RATE * enemies_near_castle)
    else:
        state.threat_level = max(0.0, state.threat_level - THREAT_DECAY_RATE)
```

### Wave Assault Trigger

When threat reaches 80%, a wave assault begins:

```gdscript
static func _check_wave_assault_trigger(state: GameState) -> String:
    if state.wave_cooldown > 0:
        return ""  # On cooldown
    if state.threat_level < WAVE_ASSAULT_THRESHOLD:
        return ""  # Not high enough

    _start_wave_assault(state)
    return "WAVE ASSAULT! Enemies converge on the castle!"
```

## Wave Assault

### Wave Size Calculation

Wave size scales with day and current threat:

```gdscript
static func _start_wave_assault(state: GameState) -> void:
    # Base size increases with day
    var base_size: int = 2 + int(state.day / 2)

    # Bonus from threat level
    var threat_bonus: int = int(state.threat_level * 3)

    var wave_size: int = base_size + threat_bonus

    state.night_wave_total = wave_size
    state.night_spawn_remaining = wave_size
```

| Day | Base Size | At 80% Threat | At 100% Threat |
|-----|-----------|---------------|----------------|
| 1 | 2 | 4 | 5 |
| 5 | 4 | 6 | 7 |
| 10 | 7 | 9 | 10 |
| 15 | 9 | 11 | 12 |
| 20 | 12 | 14 | 15 |

### Wave Combat Flow

During wave assault:
1. `phase` set to "night"
2. Roaming enemies converted to combat enemies
3. New enemies spawn each combat step
4. Player types to defeat enemies
5. Wave ends when all spawns defeated

```gdscript
# In world_tick.gd during "wave_assault" mode
if state.enemies.is_empty() and state.night_spawn_remaining <= 0:
    _end_wave_assault(state)
    events.append("Wave repelled! The kingdom is safe... for now.")
```

### After Wave

```gdscript
static func _end_wave_assault(state: GameState) -> void:
    state.activity_mode = "exploration"
    state.phase = "day"
    state.ap = state.ap_max
    state.wave_cooldown = WAVE_COOLDOWN_DURATION  # 30 seconds
    state.day += 1  # Day advances after wave
```

## Roaming Enemies

### Spawn Mechanics

Roaming enemies spawn at map edges during exploration:

```gdscript
const ROAMING_SPAWN_CHANCE := 0.10  # Base 10% per tick
const MAX_ROAMING_ENEMIES := 8

static func _tick_roaming_spawns(state: GameState) -> String:
    if state.roaming_enemies.size() >= MAX_ROAMING_ENEMIES:
        return ""

    # Higher chance at night and high threat
    var time_modifier: float = 0.0
    if state.time_of_day > 0.7 or state.time_of_day < 0.2:  # Night time
        time_modifier = 0.15

    var threat_modifier: float = state.threat_level * 0.1
    var spawn_chance: float = ROAMING_SPAWN_CHANCE + time_modifier + threat_modifier

    # Roll and spawn
    if roll > spawn_chance:
        return ""

    var edge_pos: Vector2i = _get_random_edge_position(state)
    var enemy := _create_roaming_enemy(state, edge_pos)
    state.roaming_enemies.append(enemy)
```

### Roaming Enemy Types

Available types scale with day:

```gdscript
var kinds: Array = ["raider", "scout", "armored"]
if state.day >= 3:
    kinds.append("swarm")
if state.day >= 5:
    kinds.append("berserker")
```

### Movement

Roaming enemies move toward the castle:

```gdscript
static func _move_roaming_enemy(state: GameState, entity: Dictionary) -> bool:
    var pos = entity.get("pos", Vector2i.ZERO)
    var target = entity.get("target_pos", state.base_pos)

    # Simple movement toward target
    var dx = sign(target.x - pos.x)
    var dy = sign(target.y - pos.y)

    # Random preference for horizontal vs vertical
    var prefer_x = SimRng.roll_range(state, 0, 1) == 0

    var new_pos = pos
    if prefer_x and dx != 0:
        new_pos = Vector2i(pos.x + dx, pos.y)
    elif dy != 0:
        new_pos = Vector2i(pos.x, pos.y + dy)

    if SimMap.is_passable(state, new_pos):
        entity["pos"] = new_pos
        return true
    return false
```

### Castle Arrival (Encounter)

When a roaming enemy reaches the castle, it triggers an encounter:

```gdscript
if pos == state.base_pos:
    _convert_to_combat_enemy(state, entity)
    state.roaming_enemies.remove_at(i)
    events.append("An enemy attacks the castle!")

# Convert to combat enemy
static func _convert_to_combat_enemy(state: GameState, roaming: Dictionary) -> void:
    var kind = roaming.get("kind", "raider")
    var enemy = SimEnemies.make_enemy(state, kind, state.base_pos)
    state.enemies.append(enemy)

    # Start encounter if exploring
    if state.activity_mode == "exploration":
        state.activity_mode = "encounter"
        state.phase = "night"
```

## Encounters vs Wave Assaults

| Aspect | Encounter | Wave Assault |
|--------|-----------|--------------|
| Trigger | Enemy reaches castle | Threat >= 80% |
| Size | 1-3 enemies | 4-15+ enemies |
| AP restored | No | Yes (at end) |
| Day advances | No | Yes |
| Cooldown | None | 30 seconds |

## Time of Day

The world has a continuous time cycle:

```gdscript
const TIME_ADVANCE_RATE := 0.02  # Per tick (full cycle ~50 ticks)

# In tick()
state.time_of_day += TIME_ADVANCE_RATE
if state.time_of_day >= 1.0:
    state.time_of_day -= 1.0

# Time interpretation:
# 0.0 = Midnight
# 0.25 = Morning (game starts here)
# 0.5 = Noon
# 0.75 = Evening
# 0.7-0.2 = Night (higher spawn rates)
```

## Points of Interest (POI)

POIs spawn during exploration and offer events:

```gdscript
const POI_SPAWN_CHANCE := 0.15  # Per tick
const MAX_ACTIVE_POIS := 5

static func _tick_poi_spawns(state: GameState) -> String:
    if state.active_pois.size() >= MAX_ACTIVE_POIS:
        return ""

    # Roll for spawn
    if roll > POI_SPAWN_CHANCE:
        return ""

    # Find valid tile (discovered, no structure, not water)
    var valid_tiles = get_valid_poi_tiles(state)
    var tile_index = pick_random(valid_tiles)
    var biome = _terrain_to_biome(terrain)

    var poi_id = SimPoi.try_spawn_random_poi(state, biome, pos)
```

## Constants Reference

```gdscript
# sim/world_tick.gd
const WORLD_TICK_INTERVAL := 1.0      # Seconds between ticks
const TIME_ADVANCE_RATE := 0.02       # Day cycle speed
const POI_SPAWN_CHANCE := 0.15        # POI spawn rate
const ROAMING_SPAWN_CHANCE := 0.10    # Enemy spawn rate
const MAX_ACTIVE_POIS := 5            # POI cap
const MAX_ROAMING_ENEMIES := 8        # Roaming cap
const THREAT_DECAY_RATE := 0.01       # Threat decrease
const THREAT_GROWTH_RATE := 0.02      # Threat increase per enemy
const WAVE_ASSAULT_THRESHOLD := 0.8   # Wave trigger point
const WAVE_COOLDOWN_DURATION := 30.0  # Post-wave immunity
const ENCOUNTER_RETURN_DELAY := 2.0   # After encounter ends
```

## Integration with Main Loop

The world tick is called from `game/main.gd`:

```gdscript
func _process(delta: float) -> void:
    if state.activity_mode == "exploration":
        var tick_result = WorldTick.tick(state, delta)
        if tick_result.changed:
            _render_state()
        for event in tick_result.events:
            _log(event)
```

## Adding New Threat Sources

To add a new source of threat:

1. **In `_tick_threat_level()`**:
```gdscript
# Add new threat source
if state.some_condition:
    state.threat_level += CUSTOM_THREAT_RATE
```

2. **For player actions that increase threat**:
```gdscript
# In apply_intent.gd
var threat_mult = 1.0 + SimUpgrades.get_threat_rate_multiplier(state)
var threat_gain = max(0, int(base_threat * threat_mult))
state.threat += threat_gain
```

## Debugging Threat

```gdscript
# Print threat status
print("Threat: %.2f / %.2f (cooldown: %.1fs)" % [
    state.threat_level,
    WAVE_ASSAULT_THRESHOLD,
    state.wave_cooldown
])

# Force wave for testing
state.threat_level = 1.0
state.wave_cooldown = 0.0
```

## Design Philosophy

The threat system embodies key design pillars:

1. **Paced for Learning** - Cooldowns prevent overwhelming players
2. **Clear Progression** - Day number correlates with wave difficulty
3. **Player Agency** - Exploring/building affects threat growth
4. **Tension Without Frustration** - Threat rises predictably, not randomly

The system creates a natural rhythm:
- Explore and build (threat rises slowly)
- Defend against wave (threat resets)
- Brief respite (cooldown)
- Repeat with increased difficulty
