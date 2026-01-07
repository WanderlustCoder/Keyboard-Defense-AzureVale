class_name SimSave
extends RefCounted

const GameState = preload("res://sim/types.gd")
const SimMap = preload("res://sim/map.gd")
const SimBuildings = preload("res://sim/buildings.gd")
const SimEnemies = preload("res://sim/enemies.gd")
const SimLessons = preload("res://sim/lessons.gd")

const SAVE_VERSION := 1

static func state_to_dict(state: GameState) -> Dictionary:
    var discovered_indices: Array[int] = []
    for key in state.discovered.keys():
        discovered_indices.append(int(key))

    var structures: Dictionary = {}
    for key in state.structures.keys():
        structures[int(key)] = str(state.structures[key])

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
        "lesson_id": state.lesson_id
    }

static func state_from_dict(data: Dictionary) -> Dictionary:
    var version: int = int(data.get("version", 1))
    if version > SAVE_VERSION:
        return {"ok": false, "error": "Save version %d is newer than supported %d." % [version, SAVE_VERSION]}

    var state: GameState = GameState.new()
    state.version = version
    state.day = int(data.get("day", state.day))
    state.phase = str(data.get("phase", state.phase))
    state.ap_max = int(data.get("ap_max", state.ap_max))
    state.ap = int(data.get("ap", state.ap))
    state.hp = int(data.get("hp", state.hp))
    state.threat = int(data.get("threat", state.threat))
    state.map_w = int(data.get("map_w", state.map_w))
    state.map_h = int(data.get("map_h", state.map_h))
    state.base_pos = _vec_from_dict(data.get("base_pos", {}), state.base_pos)
    state.cursor_pos = _vec_from_dict(data.get("cursor_pos", {}), state.base_pos)
    state.night_prompt = str(data.get("night_prompt", state.night_prompt))
    var legacy_remaining: int = int(data.get("night_remaining", -1))
    state.night_spawn_remaining = int(data.get("night_spawn_remaining", legacy_remaining if legacy_remaining >= 0 else state.night_spawn_remaining))
    state.night_wave_total = int(data.get("night_wave_total", legacy_remaining if legacy_remaining >= 0 else state.night_wave_total))
    state.enemies = _deserialize_enemies(data.get("enemies", []))
    state.enemy_next_id = int(data.get("enemy_next_id", state.enemy_next_id))
    state.last_path_open = bool(data.get("last_path_open", true))
    state.rng_seed = str(data.get("rng_seed", state.rng_seed))
    state.rng_state = int(data.get("rng_state", state.rng_state))
    state.lesson_id = SimLessons.normalize_lesson_id(str(data.get("lesson_id", state.lesson_id)))

    SimEnemies.ensure_enemy_words(state)

    state.terrain = _load_terrain(data.get("terrain", []), state.map_w, state.map_h)
    if state.terrain.size() != state.map_w * state.map_h:
        return {"ok": false, "error": "Terrain size mismatch."}

    state.resources = _normalize_resources(data.get("resources", {}))
    state.structures = _load_structures(data.get("structures", {}), state.map_w, state.map_h)
    state.structure_levels = _load_structure_levels(data.get("structure_levels", {}), state.structures)
    state.buildings = _recount_buildings(state.structures)
    state.discovered = _load_discovered(data.get("discovered", []), state.map_w, state.map_h)

    var base_index: int = SimMap.idx(state.base_pos.x, state.base_pos.y, state.map_w)
    state.discovered[base_index] = true

    if state.night_wave_total <= 0:
        state.night_wave_total = state.night_spawn_remaining
    if state.enemy_next_id <= 0:
        state.enemy_next_id = _next_enemy_id(state.enemies)

    return {"ok": true, "state": state}

static func _vec_to_dict(vec: Vector2i) -> Dictionary:
    return {"x": vec.x, "y": vec.y}

static func _vec_from_dict(data: Dictionary, fallback: Vector2i) -> Vector2i:
    if typeof(data) != TYPE_DICTIONARY:
        return fallback
    if not data.has("x") or not data.has("y"):
        return fallback
    return Vector2i(int(data.get("x", fallback.x)), int(data.get("y", fallback.y)))

static func _normalize_resources(raw: Dictionary) -> Dictionary:
    var resources: Dictionary = {}
    for key in GameState.RESOURCE_KEYS:
        resources[key] = int(raw.get(key, 0))
    return resources

static func _recount_buildings(structures: Dictionary) -> Dictionary:
    var buildings: Dictionary = {}
    for key in GameState.BUILDING_KEYS:
        buildings[key] = 0
    for index in structures.keys():
        var building_type: String = str(structures[index])
        if not SimBuildings.is_valid(building_type):
            continue
        buildings[building_type] = int(buildings.get(building_type, 0)) + 1
    return buildings

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

static func _load_structures(raw: Variant, w: int, h: int) -> Dictionary:
    var structures: Dictionary = {}
    if typeof(raw) == TYPE_DICTIONARY:
        for key in raw.keys():
            var index: int = int(key)
            if index >= 0 and index < w * h:
                structures[index] = str(raw[key])
    return structures

static func _load_structure_levels(raw: Variant, structures: Dictionary) -> Dictionary:
    var levels: Dictionary = {}
    if typeof(raw) == TYPE_DICTIONARY:
        for key in raw.keys():
            levels[int(key)] = max(1, int(raw.get(key, 1)))
    for key in structures.keys():
        var index: int = int(key)
        if not levels.has(index):
            levels[index] = 1
    return levels

static func _load_discovered(raw: Variant, w: int, h: int) -> Dictionary:
    var discovered: Dictionary = {}
    if raw is Array:
        for item in raw:
            var index: int = int(item)
            if index >= 0 and index < w * h:
                discovered[index] = true
    return discovered

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

static func _next_enemy_id(enemies: Array) -> int:
    var max_id: int = 0
    for enemy in enemies:
        if typeof(enemy) != TYPE_DICTIONARY:
            continue
        max_id = max(max_id, int(enemy.get("id", 0)))
    return max_id + 1
