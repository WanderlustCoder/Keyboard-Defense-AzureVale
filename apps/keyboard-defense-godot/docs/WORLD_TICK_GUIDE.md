# World Tick Guide

Real-time exploration world updates and threat management system.

## Overview

`WorldTick` (sim/world_tick.gd) manages the real-time simulation for open-world exploration mode. It handles POI spawning, roaming enemies, threat level dynamics, and wave assault triggers.

## Constants

```gdscript
const WORLD_TICK_INTERVAL := 1.0      # Seconds between world updates
const TIME_ADVANCE_RATE := 0.02       # Time of day per tick (~50 ticks = full cycle)
const POI_SPAWN_CHANCE := 0.15        # Chance to spawn POI per tick
const ROAMING_SPAWN_CHANCE := 0.10    # Chance to spawn roaming enemy per tick
const MAX_ACTIVE_POIS := 5
const MAX_ROAMING_ENEMIES := 8
const THREAT_DECAY_RATE := 0.01       # Threat decreases per tick when safe
const THREAT_GROWTH_RATE := 0.02      # Threat grows per tick when enemies near
const WAVE_ASSAULT_THRESHOLD := 0.8   # Threat level that triggers wave assault
const WAVE_COOLDOWN_DURATION := 30.0  # Seconds before another wave can trigger
const ENCOUNTER_RETURN_DELAY := 2.0   # Seconds after encounter ends
const THREAT_DECAY_IN_EXPLORATION := 0.005
```

## Main Tick Function

```gdscript
static func tick(state: GameState, delta: float) -> Dictionary:
    # Returns: {"events": Array[String], "changed": bool}
```

Called from `_process()` with accumulated delta time. Processes world updates at `WORLD_TICK_INTERVAL` intervals.

## Activity Modes

The world tick handles different activity states:

### Exploration Mode
- Tick roaming entities (movement)
- Spawn new POIs
- Spawn roaming enemies
- Update threat level
- Check for wave assault trigger

### Encounter Mode
- Check if encounter is resolved (enemies cleared)
- Return to exploration when done

### Wave Assault Mode
- Uses existing night phase combat system
- Check if wave is cleared
- Return to exploration with cooldown

### Event Mode
- Wait for event system to handle interaction

## Threat System

Threat level (0.0 - 1.0) determines danger. The system is zone-aware, with enemies from dangerous zones contributing more threat.

### Zone-Based Threat Calculation

```gdscript
static func _tick_threat_level(state: GameState) -> void:
    var threat_contribution: float = 0.0
    var castle_dist_threshold := 5

    for entity in state.roaming_enemies:
        var pos: Vector2i = entity.get("pos", Vector2i.ZERO)
        var dist: int = abs(pos.x - state.base_pos.x) + abs(pos.y - state.base_pos.y)

        if dist <= castle_dist_threshold:
            # Base contribution
            var base_threat: float = 1.0

            # Zone multipliers (enemies from dangerous zones are more threatening)
            var spawn_zone: String = str(entity.get("spawn_zone", SimMap.ZONE_SAFE))
            var zone_mult: float = SimMap.get_zone_threat_multiplier(spawn_zone)
            var current_zone: String = SimMap.get_zone_at(state, pos)
            var current_mult: float = SimMap.get_zone_threat_multiplier(current_zone)
            var avg_mult: float = (zone_mult + current_mult) / 2.0

            # Proximity bonus (closer = more threatening)
            var proximity_bonus: float = 1.0 + (float(castle_dist_threshold - dist) / float(castle_dist_threshold))

            threat_contribution += base_threat * avg_mult * proximity_bonus

    # Apply threat growth/decay
    if threat_contribution > 0:
        var growth: float = THREAT_GROWTH_RATE * threat_contribution
        state.threat_level = min(1.0, state.threat_level + growth)
    else:
        state.threat_level = max(0.0, state.threat_level - THREAT_DECAY_RATE)

    # Exploration pressure from dangerous zones
    var exploration: Dictionary = SimMap.get_exploration_by_zone(state)
    var wilderness_explored: float = float(exploration.get(SimMap.ZONE_WILDERNESS, 0.0))
    var depths_explored: float = float(exploration.get(SimMap.ZONE_DEPTHS, 0.0))
    if wilderness_explored > 0.1 or depths_explored > 0.05:
        var exploration_threat: float = (wilderness_explored * 0.002) + (depths_explored * 0.005)
        state.threat_level = min(1.0, state.threat_level + exploration_threat)
```

### Zone Threat Multipliers

| Zone | Multiplier | Description |
|------|------------|-------------|
| Safe | 0.5x | Close to castle, enemies contribute less threat |
| Frontier | 1.0x | Standard threat contribution |
| Wilderness | 1.5x | Enemies from here are more dangerous |
| Depths | 2.0x | Maximum threat contribution |

### Threat Utility Functions

```gdscript
# Calculate threat contribution for a single enemy
static func calculate_enemy_threat_contribution(state: GameState, enemy: Dictionary) -> float

# Get detailed threat breakdown for debugging/display
static func get_threat_breakdown(state: GameState) -> Dictionary
# Returns: {"total_threat", "enemy_contributions", "exploration_pressure", "cursor_zone"}

# Format threat info for human-readable display
static func format_threat_info(state: GameState) -> String
```

## Wave Assault Trigger

When threat reaches threshold, combat begins:

```gdscript
static func _check_wave_assault_trigger(state: GameState) -> String:
    if state.wave_cooldown > 0:
        return ""
    if state.threat_level < WAVE_ASSAULT_THRESHOLD:
        return ""

    _start_wave_assault(state)
    return "WAVE ASSAULT! Enemies converge on the castle!"
```

## Wave Assault Setup

```gdscript
static func _start_wave_assault(state: GameState) -> void:
    state.activity_mode = "wave_assault"
    state.phase = "night"

    # Wave size based on threat and day
    var base_size: int = 2 + int(state.day / 2)
    var threat_bonus: int = int(state.threat_level * 3)
    var wave_size: int = base_size + threat_bonus

    state.night_wave_total = wave_size
    state.night_spawn_remaining = wave_size
    state.enemies = []

    # Convert roaming enemies to combat
    for i in range(min(2, state.roaming_enemies.size())):
        var roaming: Dictionary = state.roaming_enemies.pop_back()
        _convert_to_combat_enemy(state, roaming)

    state.threat_level = 0.3  # Reset after assault starts
```

## POI Spawning

POIs spawn on discovered tiles without structures:

```gdscript
static func _tick_poi_spawns(state: GameState) -> String:
    if state.active_pois.size() >= MAX_ACTIVE_POIS:
        return ""

    var roll: float = SimRng.roll_range(state, 0, 100) / 100.0
    if roll > POI_SPAWN_CHANCE:
        return ""

    # Find valid tiles (discovered, no POI, no structure, not water)
    var valid_tiles: Array[int] = []
    for tile_index in state.discovered.keys():
        # ... filter valid tiles ...

    # Pick random tile and spawn POI
    var poi_id: String = SimPoi.try_spawn_random_poi(state, biome, pos)
```

## Roaming Enemy Spawning

Enemies spawn at map edges with zone-aware kind selection. Spawn chance increases at night, high threat, and when exploring dangerous zones.

### Spawn Chance Modifiers

```gdscript
static func _tick_roaming_spawns(state: GameState) -> String:
    # Base spawn chance: 10%
    var spawn_chance: float = ROAMING_SPAWN_CHANCE

    # +15% at night (time 0.7-1.0 or 0.0-0.2)
    var time_modifier: float = 0.0
    if state.time_of_day > 0.7 or state.time_of_day < 0.2:
        time_modifier = 0.15

    # +0-10% based on threat level
    var threat_modifier: float = state.threat_level * 0.1

    # +0-15% based on exploration (cursor zone + exploration progress)
    var exploration_modifier: float = _get_exploration_spawn_modifier(state)

    spawn_chance += time_modifier + threat_modifier + exploration_modifier
```

### Exploration Spawn Modifier

```gdscript
static func _get_exploration_spawn_modifier(state: GameState) -> float:
    var modifier: float = 0.0

    # +5-10% if cursor is in dangerous zone
    var cursor_zone: String = SimMap.get_cursor_zone(state)
    match cursor_zone:
        SimMap.ZONE_WILDERNESS: modifier += 0.05
        SimMap.ZONE_DEPTHS: modifier += 0.10

    # Additional modifier based on exploration progress
    var exploration: Dictionary = SimMap.get_exploration_by_zone(state)
    modifier += float(exploration.get(SimMap.ZONE_WILDERNESS, 0.0)) * 0.02
    modifier += float(exploration.get(SimMap.ZONE_DEPTHS, 0.0)) * 0.05

    return modifier
```

### Zone-Aware Enemy Kind Selection

Enemies are selected based on the spawn position's zone tier:

```gdscript
static func _select_enemy_kind_for_zone(state: GameState, max_tier: int) -> String:
    # Tier 1: raider, scout
    # Tier 2: + armored, swarm (day 3+)
    # Tier 3: + berserker, tank, phantom (day 5+)
    # Tier 4: + champion, healer, elite (day 7+)
```

| Zone | Max Tier | Available Enemies |
|------|----------|-------------------|
| Safe | 1 | raider, scout |
| Frontier | 2 | + armored, swarm |
| Wilderness | 3 | + berserker, tank, phantom |
| Depths | 4 | + champion, healer, elite |

### Weighted Edge Position

At high threat (>0.5), the system prefers spawning from dangerous zone edges:

```gdscript
static func _get_weighted_edge_position(state: GameState) -> Vector2i:
    var prefer_dangerous: bool = state.threat_level > 0.5
    # Attempts multiple edge positions and picks highest tier zone
```

## Roaming Entity Structure

```gdscript
{
    "id": int,
    "kind": String,        # "raider", "scout", "armored", etc.
    "pos": Vector2i,
    "target_pos": Vector2i, # Usually castle position
    "state": String,        # "wandering"
    "move_timer": float,
    "spawn_zone": String   # Zone where enemy spawned (for threat calculation)
}
```

## Roaming Enemy Movement

Enemies move toward the castle using simple pathfinding:

```gdscript
static func _move_roaming_enemy(state: GameState, entity: Dictionary) -> bool:
    var pos: Vector2i = entity.get("pos", Vector2i.ZERO)
    var target: Vector2i = entity.get("target_pos", state.base_pos)

    # Simple movement toward target
    var dx: int = sign(target.x - pos.x)
    var dy: int = sign(target.y - pos.y)

    # Prefer horizontal or vertical randomly
    var prefer_x: bool = SimRng.roll_range(state, 0, 1) == 0
    # ... choose new_pos ...

    if SimMap.is_passable(state, new_pos):
        entity["pos"] = new_pos
        return true
```

## Enemy Conversion

When roaming enemies reach the castle or wave assault triggers:

```gdscript
static func _convert_to_combat_enemy(state: GameState, roaming: Dictionary) -> void:
    var kind: String = roaming.get("kind", "raider")
    var enemy := SimEnemies.make_enemy(state, kind, state.base_pos)
    state.enemy_next_id += 1
    state.enemies.append(enemy)

    # Start encounter if in exploration
    if state.activity_mode == "exploration":
        state.activity_mode = "encounter"
        state.phase = "night"
```

## Encounter Management

```gdscript
# Start focused encounter (player-initiated)
static func start_encounter(state: GameState, enemies_to_add: Array = []) -> void:
    state.activity_mode = "encounter"
    state.phase = "night"
    state.night_spawn_remaining = 0
    for enemy_data in enemies_to_add:
        state.enemies.append(enemy_data)
    state.night_wave_total = state.enemies.size()

# End encounter, return to exploration
static func _end_encounter(state: GameState) -> void:
    state.activity_mode = "exploration"
    state.phase = "day"
    state.encounter_enemies = []

# End wave assault
static func _end_wave_assault(state: GameState) -> void:
    state.activity_mode = "exploration"
    state.phase = "day"
    state.ap = state.ap_max
    state.wave_cooldown = WAVE_COOLDOWN_DURATION
    state.day += 1  # Advance day after wave
```

## Terrain to Biome Mapping

```gdscript
static func _terrain_to_biome(terrain: String) -> String:
    match terrain:
        SimMap.TERRAIN_FOREST:
            return "evergrove"
        SimMap.TERRAIN_MOUNTAIN:
            return "stonepass"
        SimMap.TERRAIN_WATER:
            return "mistfen"
        _:
            return "sunfields"
```

## Edge Position Generation

```gdscript
static func _get_random_edge_position(state: GameState) -> Vector2i:
    var edge: int = SimRng.roll_range(state, 0, 3)
    match edge:
        0:  # Top
            pos = Vector2i(SimRng.roll_range(state, 0, state.map_w - 1), 0)
        1:  # Bottom
            pos = Vector2i(SimRng.roll_range(state, 0, state.map_w - 1), state.map_h - 1)
        2:  # Left
            pos = Vector2i(0, SimRng.roll_range(state, 0, state.map_h - 1))
        3:  # Right
            pos = Vector2i(state.map_w - 1, SimRng.roll_range(state, 0, state.map_h - 1))
```

## State Fields Used

```gdscript
state.world_tick_accum   # Accumulated time for tick interval
state.time_of_day        # 0.0-1.0 day/night cycle
state.activity_mode      # "exploration", "encounter", "wave_assault", "event"
state.phase              # "day", "night"
state.threat_level       # 0.0-1.0 danger level
state.wave_cooldown      # Seconds until wave can trigger again
state.roaming_enemies    # Array of roaming entity dictionaries
state.active_pois        # Dictionary of active POI positions
state.enemies            # Combat enemies (when in combat)
```

## Integration Example

```gdscript
# In open_world.gd _process()
func _process(delta: float) -> void:
    if state.activity_mode == "exploration":
        var result = WorldTick.tick(state, delta)
        for event in result.events:
            _display_event(event)
        if result.changed:
            _refresh_display()
```

## File Dependencies

- `sim/types.gd` - GameState
- `sim/map.gd` - SimMap for terrain, pathfinding, and zone system
- `sim/poi.gd` - SimPoi for POI spawning
- `sim/rng.gd` - SimRng for random rolls
- `sim/enemies.gd` - SimEnemies for enemy creation

## Zone System Integration

The world tick system integrates with the zone system from `sim/map.gd`:

| Zone Constant | Radius from Castle | Enemy Tier Max | Threat Mult |
|---------------|-------------------|----------------|-------------|
| `ZONE_SAFE` | 0-3 tiles | 1 | 0.5x |
| `ZONE_FRONTIER` | 4-6 tiles | 2 | 1.0x |
| `ZONE_WILDERNESS` | 7-10 tiles | 3 | 1.5x |
| `ZONE_DEPTHS` | 11+ tiles | 4 | 2.0x |

Key zone functions used:
- `SimMap.get_zone_at(state, pos)` - Get zone ID for position
- `SimMap.get_zone_threat_multiplier(zone)` - Get threat contribution multiplier
- `SimMap.get_zone_enemy_tier_max(zone)` - Get max enemy tier for zone
- `SimMap.get_exploration_by_zone(state)` - Get exploration percentages by zone
