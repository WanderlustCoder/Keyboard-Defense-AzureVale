class_name SimMap
extends RefCounted

const GameState = preload("res://sim/types.gd")
const SimRng = preload("res://sim/rng.gd")

const TERRAIN_PLAINS := "plains"
const TERRAIN_FOREST := "forest"
const TERRAIN_MOUNTAIN := "mountain"
const TERRAIN_WATER := "water"

static func idx(x: int, y: int, w: int) -> int:
    return y * w + x

static func pos_from_index(index: int, w: int) -> Vector2i:
    return Vector2i(index % w, int(index / w))

static func in_bounds(x: int, y: int, w: int, h: int) -> bool:
    return x >= 0 and y >= 0 and x < w and y < h

static func neighbors4(pos: Vector2i, w: int, h: int) -> Array[Vector2i]:
    var results: Array[Vector2i] = []
    var offsets: Array[Vector2i] = [
        Vector2i(1, 0),
        Vector2i(-1, 0),
        Vector2i(0, 1),
        Vector2i(0, -1)
    ]
    for offset in offsets:
        var nx: int = pos.x + offset.x
        var ny: int = pos.y + offset.y
        if in_bounds(nx, ny, w, h):
            results.append(Vector2i(nx, ny))
    return results

static func is_discovered(state: GameState, pos: Vector2i) -> bool:
    var index: int = idx(pos.x, pos.y, state.map_w)
    return state.discovered.has(index)

static func get_terrain(state: GameState, pos: Vector2i) -> String:
    if not in_bounds(pos.x, pos.y, state.map_w, state.map_h):
        return ""
    _ensure_terrain_size(state)
    var index: int = idx(pos.x, pos.y, state.map_w)
    if index < 0 or index >= state.terrain.size():
        return ""
    return str(state.terrain[index])

static func ensure_tile_generated(state: GameState, pos: Vector2i) -> void:
    if not in_bounds(pos.x, pos.y, state.map_w, state.map_h):
        return
    _ensure_terrain_size(state)
    var index: int = idx(pos.x, pos.y, state.map_w)
    if index < 0 or index >= state.terrain.size():
        return
    if str(state.terrain[index]) != "":
        return
    state.terrain[index] = _roll_terrain(state)

static func generate_terrain(state: GameState) -> void:
    _ensure_terrain_size(state)
    var total: int = state.map_w * state.map_h
    for i in range(total):
        if str(state.terrain[i]) == "":
            state.terrain[i] = _roll_terrain(state)

static func is_buildable(state: GameState, pos: Vector2i) -> bool:
    if not in_bounds(pos.x, pos.y, state.map_w, state.map_h):
        return false
    if pos == state.base_pos:
        return false
    var index: int = idx(pos.x, pos.y, state.map_w)
    if not state.discovered.has(index):
        return false
    if state.structures.has(index):
        return false
    var terrain: String = get_terrain(state, pos)
    if terrain == TERRAIN_WATER:
        return false
    return true

static func is_passable(state: GameState, pos: Vector2i) -> bool:
    if not in_bounds(pos.x, pos.y, state.map_w, state.map_h):
        return false
    var index: int = idx(pos.x, pos.y, state.map_w)
    if state.structures.has(index):
        var building_type: String = str(state.structures[index])
        if _is_blocking_structure(building_type):
            return false
    var terrain: String = get_terrain(state, pos)
    if terrain == "":
        terrain = TERRAIN_PLAINS
    return terrain != TERRAIN_WATER

static func path_open_to_base(state: GameState) -> bool:
    var dist: PackedInt32Array = compute_dist_to_base(state)
    for x in range(state.map_w):
        var top_idx: int = idx(x, 0, state.map_w)
        var bottom_idx: int = idx(x, state.map_h - 1, state.map_w)
        if dist[top_idx] >= 0 or dist[bottom_idx] >= 0:
            return true
    for y in range(state.map_h):
        var left_idx: int = idx(0, y, state.map_w)
        var right_idx: int = idx(state.map_w - 1, y, state.map_w)
        if dist[left_idx] >= 0 or dist[right_idx] >= 0:
            return true
    return false

static func compute_dist_to_base(state: GameState) -> PackedInt32Array:
    _ensure_terrain_size(state)
    for y in range(state.map_h):
        for x in range(state.map_w):
            ensure_tile_generated(state, Vector2i(x, y))
    var total: int = state.map_w * state.map_h
    var dist := PackedInt32Array()
    dist.resize(total)
    for i in range(total):
        dist[i] = -1

    var base: Vector2i = state.base_pos
    var base_index: int = idx(base.x, base.y, state.map_w)
    dist[base_index] = 0
    var queue: Array[Vector2i] = [base]

    while not queue.is_empty():
        var current: Vector2i = queue.pop_front()
        var current_index: int = idx(current.x, current.y, state.map_w)
        var current_dist: int = dist[current_index]
        for neighbor in neighbors4(current, state.map_w, state.map_h):
            var neighbor_index: int = idx(neighbor.x, neighbor.y, state.map_w)
            if dist[neighbor_index] >= 0:
                continue
            if not is_passable(state, neighbor) and neighbor != base:
                continue
            dist[neighbor_index] = current_dist + 1
            queue.append(neighbor)

    return dist

static func render_ascii(state: GameState) -> String:
    var lines: Array[String] = []
    for y in range(state.map_h):
        var line := ""
        for x in range(state.map_w):
            var pos := Vector2i(x, y)
            var index: int = idx(x, y, state.map_w)
            var ch := "?"
            if state.discovered.has(index):
                ch = _terrain_char(get_terrain(state, pos))
            if pos == state.base_pos:
                ch = "B"
            if state.structures.has(index):
                ch = _structure_char(str(state.structures[index]))
            if pos == state.cursor_pos:
                ch = "@"
            line += ch
        lines.append(line)
    lines.append("Legend: ? unknown . plains f forest m mountain ~ water B base F farm L lumber Q quarry W wall T tower @ cursor")
    return "\n".join(lines)

static func _enqueue_if_passable(state: GameState, queue: Array, visited: Dictionary, pos: Vector2i) -> void:
    if visited.has(pos):
        return
    if not is_passable(state, pos) and pos != state.base_pos:
        return
    visited[pos] = true
    queue.append(pos)

static func _ensure_terrain_size(state: GameState) -> void:
    var total: int = state.map_w * state.map_h
    if state.terrain.size() == total:
        return
    state.terrain = []
    for _i in range(total):
        state.terrain.append("")

static func _roll_terrain(state: GameState) -> String:
    var roll: int = SimRng.roll_range(state, 1, 100)
    if roll <= 45:
        return TERRAIN_PLAINS
    if roll <= 75:
        return TERRAIN_FOREST
    if roll <= 90:
        return TERRAIN_MOUNTAIN
    return TERRAIN_WATER

static func _is_blocking_structure(building_type: String) -> bool:
    return building_type == "wall" or building_type == "tower"

static func _terrain_char(terrain: String) -> String:
    match terrain:
        TERRAIN_PLAINS:
            return "."
        TERRAIN_FOREST:
            return "f"
        TERRAIN_MOUNTAIN:
            return "m"
        TERRAIN_WATER:
            return "~"
        _:
            return "?"

static func _structure_char(building_type: String) -> String:
    match building_type:
        "farm":
            return "F"
        "lumber":
            return "L"
        "quarry":
            return "Q"
        "wall":
            return "W"
        "tower":
            return "T"
        _:
            return "?"
