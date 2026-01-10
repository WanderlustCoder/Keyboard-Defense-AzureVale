# Worker Economy Guide

This document explains the worker system, production bonuses, food upkeep, and resource management in Keyboard Defense. Workers provide production bonuses but require food upkeep.

## Overview

Workers are a core economic mechanic that creates meaningful decisions:

```
Assign workers → +50% production per worker
      ↓
Workers need food → Must balance farms vs. other buildings
      ↓
Not enough food → Workers leave (production drops)
```

## Worker Constants

```gdscript
# sim/workers.gd
const WORKER_PRODUCTION_BONUS := 0.5  # +50% production per worker
const WORKER_UPKEEP := 1              # Food consumed per worker per day
```

## Worker State

Workers are tracked in `GameState`:

```gdscript
# sim/types.gd
var total_workers: int = 0     # Total workers available
var max_workers: int = 10      # Maximum worker capacity
var workers: Dictionary = {}   # {building_index: worker_count}
var worker_upkeep: int = 1     # Food cost per worker
```

## Worker Assignment

### Check Assignment

```gdscript
# sim/workers.gd:35
static func can_assign(state: GameState, building_index: int) -> Dictionary:
    var result := {"ok": false, "reason": ""}

    if not state.structures.has(building_index):
        result.reason = "no building"
        return result

    var capacity: int = worker_capacity(state, building_index)
    if capacity <= 0:
        result.reason = "building does not support workers"
        return result

    var current: int = workers_at(state, building_index)
    if current >= capacity:
        result.reason = "building at capacity"
        return result

    if available_workers(state) <= 0:
        result.reason = "no available workers"
        return result

    result.ok = true
    return result
```

### Assign Worker

```gdscript
# sim/workers.gd:65
static func assign_worker(state: GameState, building_index: int) -> bool:
    var check: Dictionary = can_assign(state, building_index)
    if not check.ok:
        return false

    var current: int = workers_at(state, building_index)
    state.workers[building_index] = current + 1
    return true
```

### Unassign Worker

```gdscript
# sim/workers.gd:91
static func unassign_worker(state: GameState, building_index: int) -> bool:
    var current: int = workers_at(state, building_index)
    if current <= 1:
        state.workers.erase(building_index)
    else:
        state.workers[building_index] = current - 1
    return true
```

## Worker Capacity by Building

Worker slots scale with building level:

| Building | Level 1 | Level 2 | Level 3 |
|----------|---------|---------|---------|
| Farm | 1 | 2 | 3 |
| Lumber | 1 | 2 | 2 |
| Quarry | 1 | 2 | 2 |
| Market | 1 | 2 | 3 |
| Workshop | 2 | 3 | 4 |
| Temple | 1 | 2 | 2 |
| Barracks | 2 | 3 | 4 |

**Note:** Walls and Towers do not accept workers.

```gdscript
# sim/workers.gd:27
static func worker_capacity(state: GameState, building_index: int) -> int:
    var building_type: String = str(state.structures[building_index])
    var level: int = SimBuildings.structure_level(state, building_index)
    return SimBuildings.worker_slots_for(building_type, level)
```

## Production Bonuses

### Bonus Calculation

Each worker provides +50% production:

```gdscript
# sim/workers.gd:178
static func worker_bonus(state: GameState, building_index: int) -> float:
    var workers: int = workers_at(state, building_index)
    if workers <= 0:
        return 0.0
    return workers * WORKER_PRODUCTION_BONUS
```

### Production Examples

| Building | Base | 1 Worker | 2 Workers | 3 Workers |
|----------|------|----------|-----------|-----------|
| Farm (L1) | 3 food | 4 food | 6 food | 7 food |
| Farm (L3) | 8 food | 12 food | 16 food | 20 food |
| Lumber (L1) | 3 wood | 4 wood | 6 wood | - |
| Market (L2) | 8 gold | 12 gold | 16 gold | 20 gold |

### Full Production Calculation

```gdscript
# sim/workers.gd:185
static func daily_production_with_workers(state: GameState) -> Dictionary:
    var totals: Dictionary = {"wood": 0, "stone": 0, "food": 1, "gold": 0}

    for key in state.structures.keys():
        var building_type: String = str(state.structures[key])
        var index: int = int(key)
        var level: int = SimBuildings.structure_level(state, index)
        var production: Dictionary = SimBuildings.production_for_level(building_type, level)

        # Calculate worker bonus multiplier
        var bonus_mult: float = 1.0 + worker_bonus(state, index)

        # Add base production with worker bonus
        for resource_key in production.keys():
            var base_amount: int = int(production[resource_key])
            var boosted: int = int(floor(float(base_amount) * bonus_mult))
            totals[resource_key] += boosted

        # Add adjacency bonuses (not affected by workers)
        var pos: Vector2i = SimMap.pos_from_index(index, state.map_w)
        if building_type == "farm" and _adjacent_terrain(state, pos, TERRAIN_WATER):
            totals["food"] += 1
        elif building_type == "lumber" and _adjacent_terrain(state, pos, TERRAIN_FOREST):
            totals["wood"] += 1
        elif building_type == "quarry" and _adjacent_terrain(state, pos, TERRAIN_MOUNTAIN):
            totals["stone"] += 1
        elif building_type == "market":
            var adjacent_count: int = SimBuildings.count_adjacent_buildings(state, pos)
            var per_adj: int = 1 if level == 1 else (2 if level == 2 else 3)
            totals["gold"] += adjacent_count * per_adj

    return totals
```

## Food Upkeep System

### Daily Upkeep

```gdscript
# sim/workers.gd:130
static func daily_upkeep(state: GameState) -> int:
    return total_assigned(state) * state.worker_upkeep
```

### Applying Upkeep

Called at day transition:

```gdscript
# sim/workers.gd:134
static func apply_upkeep(state: GameState) -> Dictionary:
    var result := {"ok": true, "food_consumed": 0, "workers_lost": 0}

    var upkeep: int = daily_upkeep(state)
    var food: int = int(state.resources.get("food", 0))

    if food >= upkeep:
        # Can afford all upkeep
        state.resources["food"] = food - upkeep
        result.food_consumed = upkeep
    else:
        # Not enough food - consume what we have and lose workers
        state.resources["food"] = 0
        result.food_consumed = food

        # Calculate unfed workers
        var unfed: int = ceili(float(upkeep - food) / float(state.worker_upkeep))
        result.workers_lost = min(unfed, total_assigned(state))

        # Remove workers starting from buildings with most workers
        var building_indices: Array = state.workers.keys()
        building_indices.sort_custom(func(a, b):
            return int(state.workers.get(a, 0)) > int(state.workers.get(b, 0))
        )

        var workers_to_remove: int = result.workers_lost
        for idx in building_indices:
            if workers_to_remove <= 0:
                break
            var at_building: int = int(state.workers[idx])
            var to_remove: int = min(workers_to_remove, at_building)
            if to_remove >= at_building:
                state.workers.erase(idx)
            else:
                state.workers[idx] = at_building - to_remove
            workers_to_remove -= to_remove

        result.ok = false

    return result
```

### Starvation Priority

When food runs out, workers leave buildings with the most workers first. This ensures critical single-worker buildings keep working longer.

## Worker Summary

Get a complete overview of worker allocation:

```gdscript
# sim/workers.gd:227
static func get_worker_summary(state: GameState) -> Dictionary:
    return {
        "total_workers": state.total_workers,
        "max_workers": state.max_workers,
        "assigned": total_assigned(state),
        "available": available_workers(state),
        "upkeep": daily_upkeep(state),
        "assignments": [
            {
                "index": 42,
                "building_type": "farm",
                "position": Vector2i(5, 3),
                "workers": 2,
                "capacity": 3,
                "bonus": 1.0  # +100% production
            }
        ]
    }
```

## Gaining Workers

Workers are gained through game progression:

```gdscript
# sim/workers.gd:258
static func gain_worker(state: GameState) -> bool:
    if state.total_workers >= state.max_workers:
        return false
    state.total_workers += 1
    return true
```

Common triggers:
- Completing certain days
- Building specific structures (Barracks)
- Purchasing kingdom upgrades
- Event rewards

## Building Removal

When a building is destroyed, its workers return to the pool:

```gdscript
# sim/workers.gd:265
static func on_building_removed(state: GameState, building_index: int) -> void:
    state.workers.erase(building_index)
```

## Economic Balance

### Early Game (Days 1-5)

```
Workers: 2-3
Strategy: Focus on farms first
- 1 farm with 1 worker = 4 food (3 base + 50% bonus)
- Upkeep = 1 food
- Net food = +3 per day
```

### Mid Game (Days 6-12)

```
Workers: 4-6
Strategy: Diversify production
- 2 farms with workers = food security
- 1 lumber with worker = faster building
- Keep 1-2 workers reserve
```

### Late Game (Days 13+)

```
Workers: 7-10
Strategy: Maximize bonuses
- Upgrade production buildings to L3 for more slots
- Fully staff highest-output buildings
- Markets with adjacency + workers = major gold income
```

## Integration Points

### Day Phase Transition

```gdscript
# In world_tick.gd or apply_intent.gd
func _apply_day_transition(state: GameState, events: Array[String]):
    # Apply worker upkeep first
    var upkeep_result = SimWorkers.apply_upkeep(state)

    if upkeep_result.workers_lost > 0:
        events.append("Lost %d workers to starvation!" % upkeep_result.workers_lost)

    # Then apply production
    var production = SimWorkers.daily_production_with_workers(state)
    for resource in production.keys():
        state.resources[resource] += production[resource]

    events.append("Harvested: %d wood, %d stone, %d food, %d gold" % [
        production.wood, production.stone, production.food, production.gold
    ])
```

### Building Construction

```gdscript
# When placing a building
func _apply_build(state: GameState, building_type: String, pos: Vector2i):
    var index = SimMap.idx(pos.x, pos.y, state.map_w)
    state.structures[index] = building_type

    # Barracks might grant workers
    if building_type == "barracks":
        SimWorkers.gain_worker(state)
```

### Building Upgrade

```gdscript
# When upgrading a building
func _apply_upgrade(state: GameState, building_index: int):
    var old_capacity = SimWorkers.worker_capacity(state, building_index)
    state.structure_levels[building_index] += 1
    var new_capacity = SimWorkers.worker_capacity(state, building_index)

    if new_capacity > old_capacity:
        events.append("Building can now hold %d workers." % new_capacity)
```

## Common Patterns

### Check Worker Efficiency

```gdscript
func get_efficiency_report(state: GameState) -> Dictionary:
    var summary = SimWorkers.get_worker_summary(state)
    var total_capacity: int = 0
    for assignment in summary.assignments:
        total_capacity += assignment.capacity

    return {
        "assigned": summary.assigned,
        "capacity": total_capacity,
        "utilization": float(summary.assigned) / float(total_capacity) if total_capacity > 0 else 0.0
    }
```

### Auto-Assign Workers

```gdscript
func auto_assign_workers(state: GameState) -> int:
    var assigned: int = 0
    # Prioritize farms first
    for idx in state.structures.keys():
        if state.structures[idx] == "farm":
            while SimWorkers.can_assign(state, idx).ok:
                SimWorkers.assign_worker(state, idx)
                assigned += 1
    return assigned
```

### Food Safety Check

```gdscript
func is_food_safe(state: GameState) -> bool:
    var upkeep = SimWorkers.daily_upkeep(state)
    var production = SimWorkers.daily_production_with_workers(state)
    var food_net = production.get("food", 0) - upkeep
    return food_net >= 0
```

## Testing Workers

```gdscript
func test_worker_assignment():
    var state = GameState.new()
    state.total_workers = 5
    state.structures[0] = "farm"

    var check = SimWorkers.can_assign(state, 0)
    assert(check.ok, "Should be able to assign to farm")

    SimWorkers.assign_worker(state, 0)
    assert(SimWorkers.workers_at(state, 0) == 1)
    assert(SimWorkers.available_workers(state) == 4)
    _pass("test_worker_assignment")

func test_worker_production_bonus():
    var state = GameState.new()
    state.structures[0] = "farm"
    state.workers[0] = 2

    var bonus = SimWorkers.worker_bonus(state, 0)
    assert(bonus == 1.0, "2 workers should give +100% bonus")
    _pass("test_worker_production_bonus")

func test_upkeep_starvation():
    var state = GameState.new()
    state.total_workers = 3
    state.workers[0] = 3
    state.structures[0] = "farm"
    state.resources["food"] = 1  # Only 1 food, need 3

    var result = SimWorkers.apply_upkeep(state)
    assert(not result.ok, "Should fail with insufficient food")
    assert(result.workers_lost == 2, "Should lose 2 workers")
    _pass("test_upkeep_starvation")
```
