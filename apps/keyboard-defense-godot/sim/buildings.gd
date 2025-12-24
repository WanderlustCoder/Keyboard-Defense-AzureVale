class_name SimBuildings
extends RefCounted

const GameState = preload("res://sim/types.gd")
const SimMap = preload("res://sim/map.gd")

const BUILDINGS := {
    "farm": {
        "cost": {"wood": 10},
        "production": {"food": 2},
        "defense": 0
    },
    "lumber": {
        "cost": {"wood": 5, "food": 2},
        "production": {"wood": 2},
        "defense": 0
    },
    "quarry": {
        "cost": {"wood": 5, "food": 2},
        "production": {"stone": 2},
        "defense": 0
    },
    "wall": {
        "cost": {"wood": 5, "stone": 5},
        "production": {},
        "defense": 1
    },
    "tower": {
        "cost": {"wood": 5, "stone": 10},
        "production": {},
        "defense": 2
    }
}

const TOWER_STATS := {
    1: {"range": 3, "damage": 1, "shots": 1},
    2: {"range": 4, "damage": 1, "shots": 2},
    3: {"range": 5, "damage": 2, "shots": 2}
}

const TOWER_UPGRADE_COSTS := {
    1: {"wood": 5, "stone": 10},
    2: {"wood": 10, "stone": 15}
}

static func is_valid(building_type: String) -> bool:
    return BUILDINGS.has(building_type)

static func cost_for(building_type: String) -> Dictionary:
    return BUILDINGS.get(building_type, {}).get("cost", {})

static func production_for(building_type: String) -> Dictionary:
    return BUILDINGS.get(building_type, {}).get("production", {})

static func defense_for(building_type: String) -> int:
    return int(BUILDINGS.get(building_type, {}).get("defense", 0))

static func tower_max_level() -> int:
    return 3

static func tower_stats(level: int) -> Dictionary:
    return TOWER_STATS.get(level, TOWER_STATS[1])

static func upgrade_cost_for(level: int) -> Dictionary:
    return TOWER_UPGRADE_COSTS.get(level, {})

static func structure_level(state: GameState, index: int) -> int:
    if state.structure_levels.has(index):
        return int(state.structure_levels.get(index, 1))
    if state.structures.has(index):
        return 1
    return 0

static func daily_production(state: GameState) -> Dictionary:
    var totals: Dictionary = {"wood": 0, "stone": 0, "food": 1}
    for key in state.structures.keys():
        var building_type: String = str(state.structures[key])
        if not BUILDINGS.has(building_type):
            continue
        var production: Dictionary = production_for(building_type)
        for resource_key in production.keys():
            totals[resource_key] = int(totals.get(resource_key, 0)) + int(production[resource_key])
        var pos: Vector2i = SimMap.pos_from_index(int(key), state.map_w)
        if building_type == "farm" and _adjacent_terrain(state, pos, SimMap.TERRAIN_WATER):
            totals["food"] = int(totals.get("food", 0)) + 1
        elif building_type == "lumber" and _adjacent_terrain(state, pos, SimMap.TERRAIN_FOREST):
            totals["wood"] = int(totals.get("wood", 0)) + 1
        elif building_type == "quarry" and _adjacent_terrain(state, pos, SimMap.TERRAIN_MOUNTAIN):
            totals["stone"] = int(totals.get("stone", 0)) + 1
    return totals

static func total_defense(state: GameState) -> int:
    var defense: int = 0
    for key in state.structures.keys():
        var building_type: String = str(state.structures[key])
        var base_defense: int = defense_for(building_type)
        if base_defense <= 0:
            continue
        defense += base_defense
        if building_type == "tower":
            var pos: Vector2i = SimMap.pos_from_index(int(key), state.map_w)
            if _adjacent_structure(state, pos, "wall"):
                defense += 1
    return defense

static func list_types() -> Array[String]:
    var types: Array[String] = []
    for building_type in GameState.BUILDING_KEYS:
        types.append(str(building_type))
    return types

static func is_blocking(building_type: String) -> bool:
    return building_type == "wall" or building_type == "tower"

static func get_build_preview(state: GameState, pos: Vector2i, building_type: String) -> Dictionary:
    var preview := {
        "building": building_type,
        "ok": false,
        "reason": "",
        "cost": {},
        "production": {},
        "defense": 0,
        "tower_level": 0,
        "tower_stats": {}
    }
    if not is_valid(building_type):
        preview.reason = "unknown building"
        return preview

    var cost: Dictionary = cost_for(building_type).duplicate(true)
    var production: Dictionary = production_for(building_type).duplicate(true)
    var defense: int = defense_for(building_type)

    if building_type == "farm" and _adjacent_terrain(state, pos, SimMap.TERRAIN_WATER):
        production["food"] = int(production.get("food", 0)) + 1
    elif building_type == "lumber" and _adjacent_terrain(state, pos, SimMap.TERRAIN_FOREST):
        production["wood"] = int(production.get("wood", 0)) + 1
    elif building_type == "quarry" and _adjacent_terrain(state, pos, SimMap.TERRAIN_MOUNTAIN):
        production["stone"] = int(production.get("stone", 0)) + 1

    if building_type == "tower" and _adjacent_structure(state, pos, "wall"):
        defense += 1
    if building_type == "tower":
        preview["tower_level"] = 1
        preview["tower_stats"] = tower_stats(1).duplicate(true)

    preview.cost = cost
    preview.production = production
    preview.defense = defense

    if not SimMap.in_bounds(pos.x, pos.y, state.map_w, state.map_h):
        preview.reason = "out of bounds"
        return preview
    var index: int = SimMap.idx(pos.x, pos.y, state.map_w)
    if not state.discovered.has(index):
        preview.reason = "undiscovered"
        return preview
    if pos == state.base_pos:
        preview.reason = "base tile"
        return preview
    if state.structures.has(index):
        preview.reason = "occupied"
        return preview
    if SimMap.get_terrain(state, pos) == SimMap.TERRAIN_WATER:
        preview.reason = "water tile"
        return preview
    if state.phase != "day":
        preview.reason = "not daytime"
        return preview
    if state.ap <= 0:
        preview.reason = "no AP"
        return preview
    if not _has_resources(state, cost):
        preview.reason = "not enough resources"
        return preview

    preview.ok = true
    return preview

static func get_tile_report(state: GameState, pos: Vector2i) -> Dictionary:
    var report := {
        "pos": pos,
        "in_bounds": false,
        "discovered": false,
        "terrain": "",
        "structure": "",
        "structure_level": 0,
        "is_base": false,
        "buildable": false,
        "adjacency": {"water": 0, "forest": 0, "mountain": 0, "wall": 0},
        "previews": {},
        "tower_stats": {},
        "upgrade_preview": {}
    }
    if SimMap.in_bounds(pos.x, pos.y, state.map_w, state.map_h):
        var index: int = SimMap.idx(pos.x, pos.y, state.map_w)
        report.in_bounds = true
        report.discovered = state.discovered.has(index)
        report.structure = str(state.structures.get(index, ""))
        report.is_base = pos == state.base_pos
        report.buildable = SimMap.is_buildable(state, pos)
        report.structure_level = structure_level(state, index)
        if report.discovered:
            report.terrain = SimMap.get_terrain(state, pos)
            report.adjacency = _adjacency_counts(state, pos)

        if report.structure == "tower":
            var level: int = report.structure_level
            report.tower_stats = tower_stats(level).duplicate(true)
            if level < tower_max_level():
                report.upgrade_preview = {
                    "ok": true,
                    "next_level": level + 1,
                    "cost": upgrade_cost_for(level).duplicate(true),
                    "stats": tower_stats(level + 1).duplicate(true)
                }
            else:
                report.upgrade_preview = {"ok": false, "reason": "max"}

    var previews: Dictionary = {}
    for building_type in list_types():
        previews[building_type] = get_build_preview(state, pos, building_type)
    report.previews = previews
    return report

static func _adjacent_terrain(state: GameState, pos: Vector2i, terrain: String) -> bool:
    for neighbor in SimMap.neighbors4(pos, state.map_w, state.map_h):
        if SimMap.get_terrain(state, neighbor) == terrain:
            return true
    return false

static func _adjacent_structure(state: GameState, pos: Vector2i, building_type: String) -> bool:
    for neighbor in SimMap.neighbors4(pos, state.map_w, state.map_h):
        var index: int = SimMap.idx(neighbor.x, neighbor.y, state.map_w)
        if str(state.structures.get(index, "")) == building_type:
            return true
    return false

static func _adjacency_counts(state: GameState, pos: Vector2i) -> Dictionary:
    var counts := {"water": 0, "forest": 0, "mountain": 0, "wall": 0}
    for neighbor in SimMap.neighbors4(pos, state.map_w, state.map_h):
        var terrain: String = SimMap.get_terrain(state, neighbor)
        match terrain:
            SimMap.TERRAIN_WATER:
                counts["water"] = int(counts.get("water", 0)) + 1
            SimMap.TERRAIN_FOREST:
                counts["forest"] = int(counts.get("forest", 0)) + 1
            SimMap.TERRAIN_MOUNTAIN:
                counts["mountain"] = int(counts.get("mountain", 0)) + 1
        var index: int = SimMap.idx(neighbor.x, neighbor.y, state.map_w)
        if str(state.structures.get(index, "")) == "wall":
            counts["wall"] = int(counts.get("wall", 0)) + 1
    return counts

static func _has_resources(state: GameState, cost: Dictionary) -> bool:
    for key in cost.keys():
        if int(state.resources.get(key, 0)) < int(cost[key]):
            return false
    return true

static func invested_cost(building_type: String, level: int) -> Dictionary:
    var total: Dictionary = cost_for(building_type).duplicate(true)
    if building_type == "tower":
        for upgrade_level in range(1, level):
            var cost: Dictionary = upgrade_cost_for(upgrade_level)
            _add_costs(total, cost)
    return total

static func _add_costs(target: Dictionary, add: Dictionary) -> void:
    for key in add.keys():
        target[key] = int(target.get(key, 0)) + int(add[key])
