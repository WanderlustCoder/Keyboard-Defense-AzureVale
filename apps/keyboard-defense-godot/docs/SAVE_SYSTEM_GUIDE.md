# Save System Guide

This document explains the game state serialization and deserialization system in Keyboard Defense.

## Overview

The save system converts GameState to/from Dictionary format for persistence:

```
GameState → state_to_dict() → Dictionary → JSON → File
File → JSON → Dictionary → state_from_dict() → GameState
```

## Save Version

```gdscript
# sim/save.gd:13
const SAVE_VERSION := 1
```

The version number enables forward compatibility - older saves can be loaded but newer saves are rejected.

## State Serialization

### Main Serialization Function

```gdscript
# sim/save.gd:15
static func state_to_dict(state: GameState) -> Dictionary:
    return {
        "version": SAVE_VERSION,
        "day": state.day,
        "phase": state.phase,
        "ap_max": state.ap_max,
        "ap": state.ap,
        "hp": state.hp,
        "threat": state.threat,
        "resources": state.resources.duplicate(true),
        "buildings": state.buildings.duplicate(true),
        "map_w": state.map_w,
        "map_h": state.map_h,
        "base_pos": _vec_to_dict(state.base_pos),
        "cursor_pos": _vec_to_dict(state.cursor_pos),
        "terrain": state.terrain.duplicate(true),
        "structures": structures,
        "structure_levels": state.structure_levels.duplicate(true),
        "discovered": discovered_indices,
        "night_prompt": state.night_prompt,
        "night_spawn_remaining": state.night_spawn_remaining,
        "night_wave_total": state.night_wave_total,
        "enemies": _serialize_enemies(state.enemies),
        "enemy_next_id": state.enemy_next_id,
        "last_path_open": state.last_path_open,
        "rng_seed": state.rng_seed,
        "rng_state": state.rng_state,
        "lesson_id": state.lesson_id,
        "active_pois": _serialize_active_pois(state.active_pois),
        "event_cooldowns": state.event_cooldowns.duplicate(true),
        "event_flags": state.event_flags.duplicate(true),
        "pending_event": SimEvents.serialize_pending_event(state.pending_event),
        "active_buffs": SimEventEffects.serialize_buffs(state.active_buffs),
        "purchased_kingdom_upgrades": state.purchased_kingdom_upgrades.duplicate(),
        "purchased_unit_upgrades": state.purchased_unit_upgrades.duplicate(),
        "gold": state.gold
    }
```

### Saved Fields by Category

| Category | Fields |
|----------|--------|
| Core | day, phase, ap_max, ap, hp, threat, gold |
| Map | map_w, map_h, base_pos, cursor_pos, terrain, structures, structure_levels, discovered |
| Resources | resources, buildings |
| Combat | enemies, enemy_next_id, night_prompt, night_spawn_remaining, night_wave_total |
| Progression | lesson_id, purchased_kingdom_upgrades, purchased_unit_upgrades |
| Events | active_pois, event_cooldowns, event_flags, pending_event, active_buffs |
| RNG | rng_seed, rng_state, last_path_open |

## State Deserialization

### Main Deserialization Function

```gdscript
# sim/save.gd:61
static func state_from_dict(data: Dictionary) -> Dictionary:
    var version: int = int(data.get("version", 1))
    if version > SAVE_VERSION:
        return {"ok": false, "error": "Save version %d is newer than supported %d." % [version, SAVE_VERSION]}

    var state: GameState = GameState.new()
    # ... populate fields from data ...

    return {"ok": true, "state": state}
```

### Result Format

| Field | Type | Description |
|-------|------|-------------|
| `ok` | bool | True if deserialization succeeded |
| `state` | GameState | The restored state (only if ok=true) |
| `error` | String | Error message (only if ok=false) |

## Helper Functions

### Vector Serialization

```gdscript
# sim/save.gd:123
static func _vec_to_dict(vec: Vector2i) -> Dictionary:
    return {"x": vec.x, "y": vec.y}

static func _vec_from_dict(data: Dictionary, fallback: Vector2i) -> Vector2i:
    if not data.has("x") or not data.has("y"):
        return fallback
    return Vector2i(int(data.get("x", fallback.x)), int(data.get("y", fallback.y)))
```

### Resource Normalization

```gdscript
# sim/save.gd:133
static func _normalize_resources(raw: Dictionary) -> Dictionary:
    var resources: Dictionary = {}
    for key in GameState.RESOURCE_KEYS:
        resources[key] = int(raw.get(key, 0))
    return resources
```

Ensures all resource keys exist with valid integer values.

### Building Recount

```gdscript
# sim/save.gd:139
static func _recount_buildings(structures: Dictionary) -> Dictionary:
    var buildings: Dictionary = {}
    for key in GameState.BUILDING_KEYS:
        buildings[key] = 0
    for index in structures.keys():
        var building_type: String = str(structures[index])
        if SimBuildings.is_valid(building_type):
            buildings[building_type] = int(buildings.get(building_type, 0)) + 1
    return buildings
```

Reconstructs building counts from structure map for data integrity.

### Enemy Serialization

```gdscript
# sim/save.gd:190
static func _serialize_enemies(enemies: Array) -> Array:
    var output: Array = []
    for enemy in enemies:
        if typeof(enemy) == TYPE_DICTIONARY:
            output.append(SimEnemies.serialize(enemy))
    return output

static func _deserialize_enemies(raw: Variant) -> Array:
    var output: Array = []
    if raw is Array:
        for entry in raw:
            if typeof(entry) == TYPE_DICTIONARY:
                var enemy: Dictionary = SimEnemies.deserialize(entry)
                output.append(SimEnemies.normalize_enemy(enemy))
    return output
```

Delegates to SimEnemies for enemy-specific serialization logic.

### POI Serialization

```gdscript
# sim/save.gd:214
static func _serialize_active_pois(active_pois: Dictionary) -> Dictionary:
    var result: Dictionary = {}
    for poi_id in active_pois:
        var poi_state: Dictionary = active_pois[poi_id]
        result[str(poi_id)] = SimPoi.serialize_poi_state(poi_state)
    return result

static func _deserialize_active_pois(raw: Variant) -> Dictionary:
    var result: Dictionary = {}
    for poi_id in raw:
        var poi_data: Variant = raw[poi_id]
        if typeof(poi_data) == TYPE_DICTIONARY:
            result[str(poi_id)] = SimPoi.deserialize_poi_state(poi_data)
    return result
```

### Terrain Loading

```gdscript
# sim/save.gd:150
static func _load_terrain(raw: Variant, w: int, h: int) -> Array:
    var terrain: Array = []
    if raw is Array:
        for item in raw:
            terrain.append(str(item))
    if terrain.size() != w * h:
        terrain = []
        for _i in range(w * h):
            terrain.append("")
    return terrain
```

Falls back to empty terrain if size mismatch is detected.

### Discovered Tiles

```gdscript
# sim/save.gd:181
static func _load_discovered(raw: Variant, w: int, h: int) -> Dictionary:
    var discovered: Dictionary = {}
    if raw is Array:
        for item in raw:
            var index: int = int(item)
            if index >= 0 and index < w * h:
                discovered[index] = true
    return discovered
```

Converts flat array of indices back to Dictionary lookup.

## Validation Steps

During deserialization, the system performs these validations:

1. **Version Check** - Rejects saves from newer game versions
2. **Terrain Size** - Ensures terrain array matches map dimensions
3. **Enemy Words** - Calls `SimEnemies.ensure_enemy_words()` to fill missing words
4. **Base Discovery** - Forces base tile to be discovered
5. **Wave Total** - Fixes legacy saves missing `night_wave_total`
6. **Enemy IDs** - Recalculates `enemy_next_id` if needed

## Legacy Field Handling

```gdscript
# sim/save.gd:79-81
var legacy_remaining: int = int(data.get("night_remaining", -1))
state.night_spawn_remaining = int(data.get("night_spawn_remaining",
    legacy_remaining if legacy_remaining >= 0 else state.night_spawn_remaining))
state.night_wave_total = int(data.get("night_wave_total",
    legacy_remaining if legacy_remaining >= 0 else state.night_wave_total))
```

Supports old saves that used `night_remaining` instead of split fields.

## Integration Examples

### Saving Game State

```gdscript
func save_game(state: GameState, path: String) -> bool:
    var data: Dictionary = SimSave.state_to_dict(state)
    var json: String = JSON.stringify(data, "  ")
    var file := FileAccess.open(path, FileAccess.WRITE)
    if file == null:
        return false
    file.store_string(json)
    file.close()
    return true
```

### Loading Game State

```gdscript
func load_game(path: String) -> Dictionary:
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        return {"ok": false, "error": "Cannot open file."}
    var json := JSON.new()
    var err := json.parse(file.get_as_text())
    file.close()
    if err != OK:
        return {"ok": false, "error": "Invalid JSON."}
    return SimSave.state_from_dict(json.data)
```

### Usage Pattern

```gdscript
# Load and validate
var result := load_game("user://save.json")
if not result.ok:
    push_error("Load failed: %s" % result.error)
    return

var state: GameState = result.state
# Continue game with restored state
```

## Testing

```gdscript
func test_save_roundtrip():
    var state := GameState.new()
    state.day = 5
    state.phase = "night"
    state.resources["wood"] = 25
    state.gold = 100

    var data := SimSave.state_to_dict(state)
    var result := SimSave.state_from_dict(data)

    assert(result.ok)
    var restored: GameState = result.state
    assert(restored.day == 5)
    assert(restored.phase == "night")
    assert(restored.resources["wood"] == 25)
    assert(restored.gold == 100)

    _pass("test_save_roundtrip")

func test_version_check():
    var data := {"version": 999, "day": 1}
    var result := SimSave.state_from_dict(data)
    assert(not result.ok)
    assert("newer" in result.error)

    _pass("test_version_check")

func test_terrain_validation():
    var data := {
        "version": 1,
        "map_w": 5,
        "map_h": 5,
        "terrain": ["grass", "grass"]  # Wrong size
    }
    var result := SimSave.state_from_dict(data)
    assert(not result.ok)
    assert("mismatch" in result.error)

    _pass("test_terrain_validation")
```
