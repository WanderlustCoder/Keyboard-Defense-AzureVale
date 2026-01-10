# Tower Targeting & Pathfinding Guide

This document explains how towers target enemies and how enemies navigate to the castle using the distance field pathfinding system.

## Overview

The game uses a **distance field** (also called a flow field) for pathfinding. Instead of computing paths per-enemy, a single BFS from the castle creates a field where each tile knows its distance to the base. Enemies simply follow the gradient downhill.

```
Distance Field Example (castle at center):
  4 3 2 3 4
  3 2 1 2 3
  2 1 B 1 2   (B = base, distance 0)
  3 2 1 2 3
  4 3 2 3 4

Enemies always move to adjacent tile with lower distance.
```

## Distance Field Computation

### BFS Algorithm (`sim/map.gd:109`)

```gdscript
static func compute_dist_to_base(state: GameState) -> PackedInt32Array:
    var total = state.map_w * state.map_h
    var dist = PackedInt32Array()
    dist.resize(total)

    # Initialize all tiles to -1 (unreachable)
    for i in range(total):
        dist[i] = -1

    # Start BFS from base
    var base = state.base_pos
    var base_index = idx(base.x, base.y, state.map_w)
    dist[base_index] = 0
    var queue = [base]

    while not queue.is_empty():
        var current = queue.pop_front()
        var current_dist = dist[idx(current.x, current.y, state.map_w)]

        for neighbor in neighbors4(current, state.map_w, state.map_h):
            var neighbor_index = idx(neighbor.x, neighbor.y, state.map_w)

            # Skip if already visited
            if dist[neighbor_index] >= 0:
                continue

            # Skip impassable tiles (water, walls, towers)
            if not is_passable(state, neighbor) and neighbor != base:
                continue

            dist[neighbor_index] = current_dist + 1
            queue.append(neighbor)

    return dist
```

### Passability Rules

```gdscript
static func is_passable(state: GameState, pos: Vector2i) -> bool:
    # Out of bounds = impassable
    if not in_bounds(pos.x, pos.y, state.map_w, state.map_h):
        return false

    # Blocking structures (walls, towers)
    var index = idx(pos.x, pos.y, state.map_w)
    if state.structures.has(index):
        var building_type = state.structures[index]
        if building_type == "wall" or building_type == "tower":
            return false

    # Water terrain = impassable
    var terrain = get_terrain(state, pos)
    return terrain != TERRAIN_WATER
```

### Blocking Structures

| Structure | Blocks Movement | Blocks Path |
|-----------|-----------------|-------------|
| Farm | No | No |
| Lumber | No | No |
| Quarry | No | No |
| Wall | **Yes** | **Yes** |
| Tower | **Yes** | **Yes** |
| Market | No | No |

## Enemy Movement

### Movement Algorithm (`sim/apply_intent.gd:538`)

Each combat tick, enemies move toward the castle:

```gdscript
static func _enemy_move_step(state: GameState, dist_field: PackedInt32Array, events: Array[String]):
    var offsets = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]

    for enemy in state.enemies:
        var speed = enemy.get("speed", 1)

        for _step in range(speed):
            var pos = enemy.get("pos", Vector2i.ZERO)
            var current_dist = dist_at(dist_field, pos, state.map_w)

            # Find adjacent tile with lower distance
            var next_pos = pos
            for offset in offsets:
                var candidate = pos + offset
                var candidate_dist = dist_at(dist_field, candidate, state.map_w)

                if candidate_dist >= 0 and candidate_dist < current_dist:
                    next_pos = candidate
                    break  # Take first valid option

            if next_pos != pos:
                enemy["pos"] = next_pos

            # Check if reached base
            if next_pos == state.base_pos:
                # Deal damage and remove enemy
                state.hp -= 1
                enemies.remove(enemy)
                break
```

### Movement Direction Priority

Enemies check directions in this order:
1. Up (0, -1)
2. Right (1, 0)
3. Down (0, 1)
4. Left (-1, 0)

This means when two directions have equal distance, **up** is preferred, then **right**, etc.

### Speed System

Enemy speed determines moves per tick:

| Speed | Moves/Tick | Effect |
|-------|------------|--------|
| 1 | 1 | Normal |
| 2 | 2 | Fast |
| 3 | 3 | Very Fast |

Speed modifiers:
- Swift affix: +1 speed
- Enraged affix: +1 speed when triggered
- Upgrade reduction: Multiplier from `SimUpgrades.get_enemy_speed_reduction()`

## Tower Targeting

### Target Selection (`sim/enemies.gd:547`)

Towers select targets using priority:
1. **Closest to base** (lowest distance field value)
2. **Lowest enemy ID** (tie-breaker for consistency)

```gdscript
static func pick_target_index(enemies: Array, dist: PackedInt32Array, map_w: int, origin: Vector2i, max_range: int) -> int:
    var best_index = -1
    var best_dist = 999999
    var best_id = 999999

    for i in range(enemies.size()):
        var enemy = enemies[i]
        var pos = enemy.get("pos", Vector2i.ZERO)

        # Range check (Manhattan distance)
        if max_range >= 0 and manhattan(origin, pos) > max_range:
            continue

        # Get distance to base
        var d = dist_at(dist, pos, map_w)
        if d < 0:
            continue  # Unreachable

        var enemy_id = enemy.get("id", 0)

        # Priority: closest to base, then lowest ID
        if d < best_dist or (d == best_dist and enemy_id < best_id):
            best_dist = d
            best_id = enemy_id
            best_index = i

    return best_index
```

### Range Calculation

Towers use **Manhattan distance** for range:

```gdscript
static func manhattan(a: Vector2i, b: Vector2i) -> int:
    return abs(a.x - b.x) + abs(a.y - b.y)
```

Example: Tower at (5,5) with range 3 can hit enemies at:
- (5,2) to (5,8) vertically
- (2,5) to (8,5) horizontally
- (4,4), (6,6), (3,5), etc. diagonally

### Tower Stats by Level

```gdscript
# sim/buildings.gd
static func tower_stats(level: int) -> Dictionary:
    match level:
        1: return {"range": 3, "damage": 1, "shots": 1}
        2: return {"range": 4, "damage": 2, "shots": 1}
        3: return {"range": 5, "damage": 3, "shots": 2}
        _: return {"range": 3, "damage": 1, "shots": 1}
```

| Level | Range | Damage | Shots |
|-------|-------|--------|-------|
| 1 | 3 | 1 | 1 |
| 2 | 4 | 2 | 1 |
| 3 | 5 | 3 | 2 |

### Tower Attack Flow (`sim/apply_intent.gd:494`)

```gdscript
static func _tower_attack_step(state: GameState, dist_field: PackedInt32Array, events: Array[String]):
    # Get all tower indices, sorted for determinism
    var tower_indices = []
    for key in state.structures.keys():
        if state.structures[key] == "tower":
            tower_indices.append(key)
    tower_indices.sort()

    # Each tower attacks
    for index in tower_indices:
        var tower_pos = SimMap.pos_from_index(index, state.map_w)
        var level = state.structure_levels.get(index, 1)
        var stats = SimBuildings.tower_stats(level)

        # Fire each shot
        for _shot in range(stats.shots):
            var target_index = SimEnemies.pick_target_index(
                state.enemies, dist_field, state.map_w,
                tower_pos, stats.range
            )

            if target_index < 0:
                break  # No valid targets

            var enemy = state.enemies[target_index]
            enemy = SimEnemies.apply_damage(enemy, stats.damage, state)

            if enemy.hp <= 0:
                # Handle death (splitting, etc.)
                state.enemies.remove_at(target_index)
```

## Path Validation

### Checking Path to Base

Before building walls/towers, verify path remains open:

```gdscript
static func path_open_to_base(state: GameState) -> bool:
    var dist = compute_dist_to_base(state)

    # Check all edge tiles
    for x in range(state.map_w):
        var top = idx(x, 0, state.map_w)
        var bottom = idx(x, state.map_h - 1, state.map_w)
        if dist[top] >= 0 or dist[bottom] >= 0:
            return true

    for y in range(state.map_h):
        var left = idx(0, y, state.map_w)
        var right = idx(state.map_w - 1, y, state.map_w)
        if dist[left] >= 0 or dist[right] >= 0:
            return true

    return false  # No edge tile can reach base
```

### Build Validation

```gdscript
# In _apply_build()
if building_type == "wall" or building_type == "tower":
    # Temporarily place structure
    state.structures[index] = building_type

    # Check path
    if not SimMap.path_open_to_base(state):
        # Revert
        state.structures.erase(index)
        events.append("Cannot build: would block all paths to base.")
        return

    # Keep placement
```

## Combat Tick Sequence

Every combat tick follows this order:

```
1. Player attack (if typed word)
2. Spawn enemies (if spawns remaining)
3. Tower attacks ← Uses distance field
4. Enemy movement ← Uses distance field
5. Enemy abilities (regeneration, etc.)
6. Check victory/defeat
```

The distance field is computed **once** at the start of each tick:

```gdscript
static func _advance_night_step(state, hit_enemy_index, apply_miss_penalty, events, hit_word):
    var dist_field = SimMap.compute_dist_to_base(state)  # Compute once

    if hit_enemy_index >= 0:
        _apply_player_attack_target(state, hit_enemy_index, hit_word, events)

    _spawn_enemy_step(state, events)
    _tower_attack_step(state, dist_field, events)  # Pass to towers
    _enemy_move_step(state, dist_field, events)    # Pass to enemies
    _enemy_ability_tick(state, events)
```

## Strategic Implications

### Maze Building

Players can build walls/towers to create longer paths:

```
Before:                    After maze:
E → → → B                  E → ↓
                             ↓ ←
                             → ↓
                               → B

Distance: 4                Distance: 8 (enemies walk further)
```

**Important**: At least one path must remain open from any map edge to the base.

### Tower Placement

Optimal tower positions:
- **Chokepoints**: Where enemies must pass through narrow gaps
- **Near base**: Catch enemies close to base (last defense)
- **Along paths**: Where enemies walk predictably

### Distance Field Visualization

For debugging, render the distance field:

```gdscript
func debug_draw_dist_field(dist_field: PackedInt32Array):
    for y in range(state.map_h):
        for x in range(state.map_w):
            var index = y * state.map_w + x
            var d = dist_field[index]
            if d >= 0:
                draw_string(font, Vector2(x * 32, y * 32), str(d))
```

## Adding New Tower Types

1. **Add stats function**:
```gdscript
# In sim/buildings.gd
static func slow_tower_stats(level: int) -> Dictionary:
    match level:
        1: return {"range": 4, "damage": 0, "shots": 1, "slow": 0.5}
        # ...
```

2. **Handle in tower attack**:
```gdscript
# In _tower_attack_step()
if building_type == "slow_tower":
    # Apply slow instead of damage
    enemy["speed_modifier"] = stats.slow
```

3. **Check in enemy movement**:
```gdscript
var speed = enemy.get("speed", 1)
var modifier = enemy.get("speed_modifier", 1.0)
var effective_speed = int(speed * modifier)
```

## Common Patterns

### Get Enemies in Range

```gdscript
func get_enemies_in_range(state: GameState, origin: Vector2i, range: int) -> Array:
    var result = []
    for enemy in state.enemies:
        var pos = enemy.get("pos", Vector2i.ZERO)
        if SimEnemies.manhattan(origin, pos) <= range:
            result.append(enemy)
    return result
```

### Check if Tile Reachable

```gdscript
func is_reachable(state: GameState, pos: Vector2i) -> bool:
    var dist_field = SimMap.compute_dist_to_base(state)
    var index = pos.y * state.map_w + pos.x
    return dist_field[index] >= 0
```

### Predict Enemy Path

```gdscript
func predict_path(state: GameState, start: Vector2i) -> Array[Vector2i]:
    var dist_field = SimMap.compute_dist_to_base(state)
    var path = [start]
    var pos = start
    var offsets = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]

    while pos != state.base_pos:
        var current_dist = SimEnemies.dist_at(dist_field, pos, state.map_w)
        var next_pos = pos

        for offset in offsets:
            var candidate = pos + offset
            var candidate_dist = SimEnemies.dist_at(dist_field, candidate, state.map_w)
            if candidate_dist >= 0 and candidate_dist < current_dist:
                next_pos = candidate
                break

        if next_pos == pos:
            break  # Stuck

        path.append(next_pos)
        pos = next_pos

    return path
```
