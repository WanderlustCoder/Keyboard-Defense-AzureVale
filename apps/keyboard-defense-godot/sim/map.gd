class_name SimMap
extends RefCounted

const GameState = preload("res://sim/types.gd")
const SimRng = preload("res://sim/rng.gd")

const TERRAIN_PLAINS := "plains"
const TERRAIN_FOREST := "forest"
const TERRAIN_MOUNTAIN := "mountain"
const TERRAIN_WATER := "water"

# Zone/Region system - difficulty tiers based on distance from castle
const ZONE_SAFE := "safe"           # Close to castle, beginner-friendly
const ZONE_FRONTIER := "frontier"   # Medium distance, moderate challenge
const ZONE_WILDERNESS := "wilderness"  # Far from castle, high difficulty
const ZONE_DEPTHS := "depths"       # Very far, endgame content

# Zone thresholds (in tiles from castle)
const ZONE_SAFE_RADIUS := 3
const ZONE_FRONTIER_RADIUS := 6
const ZONE_WILDERNESS_RADIUS := 10
# Beyond ZONE_WILDERNESS_RADIUS is ZONE_DEPTHS

# Zone properties
const ZONE_DATA := {
    ZONE_SAFE: {
        "name": "Safe Zone",
        "description": "The area around your castle. Enemies are weak and resources are common.",
        "threat_multiplier": 0.5,
        "loot_multiplier": 0.8,
        "enemy_tier_max": 1,
        "poi_rarity_bonus": 20,
        "resource_quality": 1.0,
        "color": Color(0.2, 0.6, 0.2)  # Green
    },
    ZONE_FRONTIER: {
        "name": "Frontier",
        "description": "The edges of your domain. Moderate challenge with better rewards.",
        "threat_multiplier": 1.0,
        "loot_multiplier": 1.0,
        "enemy_tier_max": 2,
        "poi_rarity_bonus": 0,
        "resource_quality": 1.25,
        "color": Color(0.6, 0.6, 0.2)  # Yellow
    },
    ZONE_WILDERNESS: {
        "name": "Wilderness",
        "description": "Dangerous territory. Strong enemies guard valuable treasures.",
        "threat_multiplier": 1.5,
        "loot_multiplier": 1.5,
        "enemy_tier_max": 3,
        "poi_rarity_bonus": -20,
        "resource_quality": 1.5,
        "color": Color(0.7, 0.3, 0.1)  # Orange
    },
    ZONE_DEPTHS: {
        "name": "The Depths",
        "description": "The most dangerous regions. Only the bravest venture here.",
        "threat_multiplier": 2.0,
        "loot_multiplier": 2.0,
        "enemy_tier_max": 4,
        "poi_rarity_bonus": -40,
        "resource_quality": 2.0,
        "color": Color(0.6, 0.1, 0.1)  # Red
    }
}

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

## Get a spawn position on the map edge (typically right side for bosses)
static func get_spawn_pos(state: GameState) -> Vector2i:
    var w: int = state.map_w
    var h: int = state.map_h
    # Spawn on right edge, vertically centered
    return Vector2i(w - 1, h / 2)

# ============================================================================
# Zone/Region System Functions
# ============================================================================

## Calculate Manhattan distance from position to castle
static func distance_to_castle(state: GameState, pos: Vector2i) -> int:
    return abs(pos.x - state.base_pos.x) + abs(pos.y - state.base_pos.y)

## Calculate Chebyshev distance (allows diagonal) from position to castle
static func chebyshev_distance_to_castle(state: GameState, pos: Vector2i) -> int:
    return max(abs(pos.x - state.base_pos.x), abs(pos.y - state.base_pos.y))

## Get the zone ID for a position based on distance from castle
static func get_zone_at(state: GameState, pos: Vector2i) -> String:
    var dist: int = chebyshev_distance_to_castle(state, pos)
    if dist <= ZONE_SAFE_RADIUS:
        return ZONE_SAFE
    elif dist <= ZONE_FRONTIER_RADIUS:
        return ZONE_FRONTIER
    elif dist <= ZONE_WILDERNESS_RADIUS:
        return ZONE_WILDERNESS
    else:
        return ZONE_DEPTHS

## Get zone data dictionary for a zone ID
static func get_zone_data(zone_id: String) -> Dictionary:
    return ZONE_DATA.get(zone_id, ZONE_DATA[ZONE_SAFE])

## Get zone at current cursor position
static func get_cursor_zone(state: GameState) -> String:
    return get_zone_at(state, state.cursor_pos)

## Get zone name for display
static func get_zone_name(zone_id: String) -> String:
    var data: Dictionary = get_zone_data(zone_id)
    return str(data.get("name", zone_id.capitalize()))

## Get zone description
static func get_zone_description(zone_id: String) -> String:
    var data: Dictionary = get_zone_data(zone_id)
    return str(data.get("description", ""))

## Get zone color for UI/rendering
static func get_zone_color(zone_id: String) -> Color:
    var data: Dictionary = get_zone_data(zone_id)
    return data.get("color", Color.WHITE) as Color

## Get threat multiplier for zone (affects enemy spawn rate/power)
static func get_zone_threat_multiplier(zone_id: String) -> float:
    var data: Dictionary = get_zone_data(zone_id)
    return float(data.get("threat_multiplier", 1.0))

## Get loot multiplier for zone (affects rewards)
static func get_zone_loot_multiplier(zone_id: String) -> float:
    var data: Dictionary = get_zone_data(zone_id)
    return float(data.get("loot_multiplier", 1.0))

## Get max enemy tier that can spawn in zone
static func get_zone_enemy_tier_max(zone_id: String) -> int:
    var data: Dictionary = get_zone_data(zone_id)
    return int(data.get("enemy_tier_max", 1))

## Get POI rarity bonus (positive = more common, negative = rarer/better)
static func get_zone_poi_rarity_bonus(zone_id: String) -> int:
    var data: Dictionary = get_zone_data(zone_id)
    return int(data.get("poi_rarity_bonus", 0))

## Get resource quality multiplier for zone
static func get_zone_resource_quality(zone_id: String) -> float:
    var data: Dictionary = get_zone_data(zone_id)
    return float(data.get("resource_quality", 1.0))

## Check if position is in safe zone
static func is_in_safe_zone(state: GameState, pos: Vector2i) -> bool:
    return get_zone_at(state, pos) == ZONE_SAFE

## Check if position is in dangerous territory (wilderness or depths)
static func is_dangerous_zone(state: GameState, pos: Vector2i) -> bool:
    var zone: String = get_zone_at(state, pos)
    return zone == ZONE_WILDERNESS or zone == ZONE_DEPTHS

## Get all zone IDs in order of difficulty
static func get_all_zones() -> Array[String]:
    return [ZONE_SAFE, ZONE_FRONTIER, ZONE_WILDERNESS, ZONE_DEPTHS]

## Count discovered tiles per zone
static func count_discovered_by_zone(state: GameState) -> Dictionary:
    var counts: Dictionary = {
        ZONE_SAFE: 0,
        ZONE_FRONTIER: 0,
        ZONE_WILDERNESS: 0,
        ZONE_DEPTHS: 0
    }
    for index in state.discovered.keys():
        var pos: Vector2i = pos_from_index(int(index), state.map_w)
        var zone: String = get_zone_at(state, pos)
        counts[zone] = int(counts.get(zone, 0)) + 1
    return counts

## Get total tiles in each zone
static func count_tiles_by_zone(state: GameState) -> Dictionary:
    var counts: Dictionary = {
        ZONE_SAFE: 0,
        ZONE_FRONTIER: 0,
        ZONE_WILDERNESS: 0,
        ZONE_DEPTHS: 0
    }
    for y in range(state.map_h):
        for x in range(state.map_w):
            var zone: String = get_zone_at(state, Vector2i(x, y))
            counts[zone] = int(counts.get(zone, 0)) + 1
    return counts

## Calculate exploration percentage per zone
static func get_exploration_by_zone(state: GameState) -> Dictionary:
    var discovered: Dictionary = count_discovered_by_zone(state)
    var total: Dictionary = count_tiles_by_zone(state)
    var result: Dictionary = {}
    for zone in get_all_zones():
        var d: int = int(discovered.get(zone, 0))
        var t: int = int(total.get(zone, 1))
        result[zone] = float(d) / float(t) if t > 0 else 0.0
    return result

## Get overall exploration percentage
static func get_total_exploration(state: GameState) -> float:
    var discovered: int = state.discovered.size()
    var total: int = state.map_w * state.map_h
    return float(discovered) / float(total) if total > 0 else 0.0

## Format zone info for display
static func format_zone_info(state: GameState, pos: Vector2i) -> String:
    var zone: String = get_zone_at(state, pos)
    var data: Dictionary = get_zone_data(zone)
    var name: String = str(data.get("name", "Unknown"))
    var desc: String = str(data.get("description", ""))
    var threat: float = float(data.get("threat_multiplier", 1.0))
    var loot: float = float(data.get("loot_multiplier", 1.0))
    return "%s\n%s\nThreat: x%.1f | Loot: x%.1f" % [name, desc, threat, loot]

## Get a summary of exploration progress
static func format_exploration_summary(state: GameState) -> String:
    var by_zone: Dictionary = get_exploration_by_zone(state)
    var total: float = get_total_exploration(state)
    var lines: Array[String] = ["Exploration: %.0f%%" % (total * 100)]
    for zone in get_all_zones():
        var pct: float = float(by_zone.get(zone, 0.0)) * 100
        var name: String = get_zone_name(zone)
        lines.append("  %s: %.0f%%" % [name, pct])
    return "\n".join(lines)
