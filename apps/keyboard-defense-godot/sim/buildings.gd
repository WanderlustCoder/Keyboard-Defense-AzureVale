class_name SimBuildings
extends RefCounted

const GameState = preload("res://sim/types.gd")
const SimMap = preload("res://sim/map.gd")

const BUILDINGS := {
    "farm": {
        "cost": {"wood": 10},
        "production": {"food": 3},
        "defense": 0,
        "worker_slots": 1,
        "category": "production"
    },
    "lumber": {
        "cost": {"wood": 5, "food": 2},
        "production": {"wood": 3},
        "defense": 0,
        "worker_slots": 1,
        "category": "production"
    },
    "quarry": {
        "cost": {"wood": 5, "food": 2},
        "production": {"stone": 3},
        "defense": 0,
        "worker_slots": 1,
        "category": "production"
    },
    "wall": {
        "cost": {"wood": 4, "stone": 4},
        "production": {},
        "defense": 1,
        "worker_slots": 0,
        "category": "defense"
    },
    "tower": {
        "cost": {"wood": 4, "stone": 8},
        "production": {},
        "defense": 2,
        "worker_slots": 0,
        "category": "auto_defense",
        "tier": 1,
        "auto_attack": {"damage": 3, "range": 3, "cooldown": 1.5, "targeting": "nearest", "damage_type": "physical"}
    },
    "market": {
        "cost": {"wood": 8, "stone": 5},
        "production": {"gold": 5},
        "defense": 0,
        "worker_slots": 1,
        "category": "economy"
    },
    "barracks": {
        "cost": {"wood": 10, "stone": 8},
        "production": {},
        "defense": 1,
        "worker_slots": 2,
        "category": "military"
    },
    "temple": {
        "cost": {"stone": 15, "gold": 20},
        "production": {},
        "defense": 0,
        "worker_slots": 1,
        "category": "support",
        "effects": {"wave_heal": 1}
    },
    "workshop": {
        "cost": {"wood": 12, "stone": 6},
        "production": {},
        "defense": 0,
        "worker_slots": 2,
        "category": "support",
        "effects": {"build_cost_reduction": 0.1}
    },
    # =========================================================================
    # AUTO-DEFENSE TOWERS - Tier 1
    # =========================================================================
    "auto_sentry": {
        "cost": {"wood": 6, "stone": 10, "gold": 80},
        "production": {},
        "defense": 1,
        "worker_slots": 0,
        "category": "auto_defense",
        "tier": 1,
        "auto_attack": {"damage": 5, "range": 3, "cooldown": 1.25, "targeting": "nearest", "damage_type": "physical"}
    },
    "auto_spark": {
        "cost": {"wood": 4, "stone": 8, "gold": 100},
        "production": {},
        "defense": 0,
        "worker_slots": 0,
        "category": "auto_defense",
        "tier": 1,
        "auto_attack": {"damage": 3, "range": 2, "cooldown": 1.5, "targeting": "zone", "aoe_radius": 2, "damage_type": "lightning"}
    },
    "auto_thorns": {
        "cost": {"wood": 8, "gold": 60},
        "production": {},
        "defense": 0,
        "worker_slots": 0,
        "category": "auto_defense",
        "tier": 1,
        "auto_attack": {"damage": 8, "range": 1, "cooldown": 0, "targeting": "contact", "slow_percent": 15, "damage_type": "nature"}
    },
    # =========================================================================
    # AUTO-DEFENSE TOWERS - Tier 2
    # =========================================================================
    "auto_ballista": {
        "cost": {"wood": 10, "stone": 15, "gold": 230},
        "production": {},
        "defense": 1,
        "worker_slots": 0,
        "category": "auto_defense",
        "tier": 2,
        "auto_attack": {"damage": 25, "range": 6, "cooldown": 3.3, "targeting": "highest_hp", "armor_pierce": 50, "damage_type": "siege"}
    },
    "auto_tesla": {
        "cost": {"wood": 6, "stone": 12, "gold": 280},
        "production": {},
        "defense": 0,
        "worker_slots": 0,
        "category": "auto_defense",
        "tier": 2,
        "auto_attack": {"damage": 8, "range": 4, "cooldown": 1.0, "targeting": "chain", "chain_count": 4, "chain_falloff": 0.8, "damage_type": "lightning"}
    },
    "auto_bramble": {
        "cost": {"wood": 15, "stone": 5, "gold": 180},
        "production": {},
        "defense": 0,
        "worker_slots": 0,
        "category": "auto_defense",
        "tier": 2,
        "auto_attack": {"damage": 4, "range": 3, "cooldown": 0.5, "targeting": "zone", "slow_percent": 30, "root_chance": 10, "damage_type": "nature"}
    },
    "auto_flame": {
        "cost": {"wood": 8, "stone": 10, "gold": 250},
        "production": {},
        "defense": 0,
        "worker_slots": 0,
        "category": "auto_defense",
        "tier": 2,
        "auto_attack": {"damage": 6, "range": 3, "cooldown": 0.5, "targeting": "nearest", "burn_damage": 3, "burn_duration": 3.0, "damage_type": "fire"}
    },
    # =========================================================================
    # AUTO-DEFENSE TOWERS - Tier 3
    # =========================================================================
    "auto_cannon": {
        "cost": {"wood": 15, "stone": 30, "gold": 530},
        "production": {},
        "defense": 2,
        "worker_slots": 0,
        "category": "auto_defense",
        "tier": 3,
        "auto_attack": {"damage": 50, "range": 8, "cooldown": 5.0, "targeting": "cluster", "splash_radius": 2, "splash_percent": 60, "damage_type": "siege"}
    },
    "auto_storm": {
        "cost": {"wood": 8, "stone": 20, "gold": 630},
        "production": {},
        "defense": 1,
        "worker_slots": 0,
        "category": "auto_defense",
        "tier": 3,
        "auto_attack": {"damage": 15, "range": 6, "cooldown": 2.0, "targeting": "cluster", "strikes": 5, "stun_chance": 20, "stun_duration": 1.0, "damage_type": "lightning"}
    },
    "auto_fortress": {
        "cost": {"wood": 30, "stone": 10, "gold": 520},
        "production": {},
        "defense": 3,
        "worker_slots": 0,
        "category": "auto_defense",
        "tier": 3,
        "auto_attack": {"damage": 20, "range": 2, "cooldown": 1.25, "targeting": "zone", "damage_type": "nature"},
        "special": {"hp": 500, "armor": 30, "regen": 5, "blocks_path": true}
    },
    "auto_inferno": {
        "cost": {"wood": 12, "stone": 15, "gold": 580},
        "production": {},
        "defense": 1,
        "worker_slots": 0,
        "category": "auto_defense",
        "tier": 3,
        "auto_attack": {"damage": 10, "range": 4, "cooldown": 0.33, "targeting": "nearest", "ramp_max": 3.0, "uses_fuel": true, "damage_type": "fire"}
    },
    # =========================================================================
    # AUTO-DEFENSE TOWERS - Tier 4 (Legendary)
    # =========================================================================
    "auto_arcane": {
        "cost": {"wood": 20, "stone": 30, "gold": 1200},
        "production": {},
        "defense": 2,
        "worker_slots": 0,
        "category": "auto_defense",
        "tier": 4,
        "auto_attack": {"damage": 35, "range": 5, "cooldown": 0.83, "targeting": "smart", "adaptive": true, "damage_type": "physical"},
        "legendary": true,
        "limit_per_map": 1
    },
    "auto_doom": {
        "cost": {"wood": 50, "stone": 80, "gold": 2000},
        "production": {},
        "defense": 5,
        "worker_slots": 0,
        "category": "auto_defense",
        "tier": 4,
        "auto_attack": {"damage": 80, "range": 7, "cooldown": 6.67, "targeting": "cluster", "multi_system": true, "damage_type": "siege"},
        "legendary": true,
        "limit_per_map": 1,
        "size": "3x3"
    },
    # Legacy aliases for backward compatibility
    "sentry": {
        "cost": {"wood": 6, "stone": 10, "gold": 80},
        "production": {},
        "defense": 1,
        "worker_slots": 0,
        "category": "auto_defense",
        "tier": 1,
        "auto_attack": {"damage": 5, "range": 3, "cooldown": 1.25, "targeting": "nearest"},
        "alias_of": "auto_sentry"
    },
    "spark": {
        "cost": {"wood": 4, "stone": 8, "gold": 100},
        "production": {},
        "defense": 0,
        "worker_slots": 0,
        "category": "auto_defense",
        "tier": 1,
        "auto_attack": {"damage": 3, "range": 2, "cooldown": 1.5, "targeting": "zone", "aoe_radius": 2},
        "alias_of": "auto_spark"
    },
    "flame": {
        "cost": {"wood": 8, "stone": 10, "gold": 250},
        "production": {},
        "defense": 0,
        "worker_slots": 0,
        "category": "auto_defense",
        "tier": 2,
        "auto_attack": {"damage": 6, "range": 3, "cooldown": 0.5, "targeting": "nearest", "burn_damage": 3},
        "alias_of": "auto_flame"
    }
}

const TOWER_STATS := {
    1: {"range": 3, "damage": 1, "shots": 1},
    2: {"range": 4, "damage": 2, "shots": 2},
    3: {"range": 5, "damage": 3, "shots": 2}
}

const TOWER_UPGRADE_COSTS := {
    1: {"wood": 4, "stone": 8},
    2: {"wood": 8, "stone": 12}
}

# Generic upgrade definitions for all buildings
const BUILDING_UPGRADES := {
    "farm": {
        "max_level": 3,
        "levels": {
            2: {"cost": {"wood": 8}, "production": {"food": 5}, "worker_slots": 2},
            3: {"cost": {"wood": 12, "stone": 5}, "production": {"food": 8}, "worker_slots": 3}
        }
    },
    "lumber": {
        "max_level": 3,
        "levels": {
            2: {"cost": {"wood": 6, "stone": 4}, "production": {"wood": 5}, "worker_slots": 2},
            3: {"cost": {"wood": 10, "stone": 8}, "production": {"wood": 8}, "worker_slots": 3}
        }
    },
    "quarry": {
        "max_level": 3,
        "levels": {
            2: {"cost": {"wood": 6, "stone": 4}, "production": {"stone": 5}, "worker_slots": 2},
            3: {"cost": {"wood": 10, "stone": 8}, "production": {"stone": 8}, "worker_slots": 3}
        }
    },
    "market": {
        "max_level": 3,
        "levels": {
            2: {"cost": {"wood": 10, "stone": 8}, "production": {"gold": 8}, "worker_slots": 2, "per_adjacent": 2},
            3: {"cost": {"wood": 15, "stone": 12, "gold": 30}, "production": {"gold": 12}, "worker_slots": 3, "per_adjacent": 3, "enables_trade": true}
        }
    },
    "wall": {
        "max_level": 3,
        "levels": {
            2: {"cost": {"stone": 4}, "defense": 2, "effects": {"enemy_slow": 0.2}},
            3: {"cost": {"stone": 8, "wood": 4}, "defense": 3, "effects": {"enemy_slow": 0.3, "thorns": 1}}
        }
    },
    "tower": {
        "max_level": 3,
        "levels": {
            2: {"cost": {"wood": 4, "stone": 8}, "defense": 3, "combat": {"range": 4, "damage": 2, "shots": 2}},
            3: {"cost": {"wood": 8, "stone": 12}, "defense": 4, "combat": {"range": 5, "damage": 3, "shots": 2}, "effects": {"enemy_slow": 0.15}}
        }
    },
    "barracks": {
        "max_level": 3,
        "levels": {
            2: {"cost": {"wood": 8, "stone": 10}, "defense": 2, "worker_slots": 3, "effects": {"typing_power": 0.1}},
            3: {"cost": {"wood": 12, "stone": 15, "gold": 25}, "defense": 3, "worker_slots": 4, "effects": {"typing_power": 0.2, "combo_bonus": 0.15}}
        }
    },
    "temple": {
        "max_level": 3,
        "levels": {
            2: {"cost": {"stone": 10, "gold": 15}, "worker_slots": 2, "effects": {"wave_heal": 2, "morale": 0.1}},
            3: {"cost": {"stone": 20, "gold": 40}, "worker_slots": 3, "effects": {"wave_heal": 3, "morale": 0.2, "castle_hp": 2}}
        }
    },
    "workshop": {
        "max_level": 3,
        "levels": {
            2: {"cost": {"wood": 8, "stone": 10}, "worker_slots": 3, "effects": {"build_cost_reduction": 0.15, "upgrade_cost_reduction": 0.1}},
            3: {"cost": {"wood": 15, "stone": 15, "gold": 20}, "worker_slots": 4, "effects": {"build_cost_reduction": 0.2, "upgrade_cost_reduction": 0.15, "tower_damage": 1}}
        }
    }
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

static func get_tower_effects(level: int) -> Dictionary:
    ## Get status effect abilities for tower at given level
    var upgrade_data: Dictionary = BUILDING_UPGRADES.get("tower", {})
    var levels: Dictionary = upgrade_data.get("levels", {})
    if levels.has(level):
        return levels[level].get("effects", {})
    return {}

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

static func is_auto_tower(building_type: String) -> bool:
    # "tower" is a legacy tower with level-based upgrades, not an auto-tower
    if building_type == "tower":
        return false
    return BUILDINGS.get(building_type, {}).get("category", "") == "auto_defense"

static func get_auto_attack_stats(building_type: String) -> Dictionary:
    return BUILDINGS.get(building_type, {}).get("auto_attack", {})

static func get_all_auto_towers(state: GameState) -> Array[Dictionary]:
    var auto_towers: Array[Dictionary] = []
    for key in state.structures.keys():
        var building_type: String = str(state.structures[key])
        if is_auto_tower(building_type):
            var stats: Dictionary = get_auto_attack_stats(building_type)
            var pos: Vector2i = SimMap.pos_from_index(int(key), state.map_w)
            auto_towers.append({
                "index": int(key),
                "type": building_type,
                "pos": pos,
                "damage": int(stats.get("damage", 1)),
                "range": int(stats.get("range", 2)),
                "cooldown": float(stats.get("cooldown", 1.0)),
                "targeting": str(stats.get("targeting", "nearest")),
                "aoe_radius": int(stats.get("aoe_radius", 0)),
                "burn": bool(stats.get("burn", false))
            })
    return auto_towers


static func get_auto_tower_tier(building_type: String) -> int:
    return int(BUILDINGS.get(building_type, {}).get("tier", 0))


static func get_auto_tower_upgrade_options(building_type: String) -> Array[String]:
    return SimAutoTowerTypes.get_upgrade_options(building_type)


static func can_upgrade_auto_tower(state: GameState, index: int) -> Dictionary:
    var result := {"can_upgrade": false, "reason": "", "options": [], "costs": {}}

    if not state.structures.has(index):
        result.reason = "no structure at index"
        return result

    var building_type: String = str(state.structures[index])
    if not is_auto_tower(building_type):
        result.reason = "not an auto-tower"
        return result

    var options: Array[String] = get_auto_tower_upgrade_options(building_type)
    if options.is_empty():
        result.reason = "no upgrade available"
        return result

    # Check each upgrade option
    for option in options:
        var cost: Dictionary = SimAutoTowerTypes.get_upgrade_cost(option)
        var can_afford := true
        for res_key in cost.keys():
            var res_name: String = str(res_key)
            var required: int = int(cost[res_key])
            var current: int = 0
            if res_name == "gold":
                current = state.gold
            else:
                current = int(state.resources.get(res_name, 0))
            if current < required:
                can_afford = false
                break

        result.options.append(option)
        result.costs[option] = cost
        if can_afford:
            result.can_upgrade = true

    if not result.can_upgrade:
        result.reason = "cannot afford upgrade"

    return result


static func apply_auto_tower_upgrade(state: GameState, index: int, target_type: String) -> bool:
    var check := can_upgrade_auto_tower(state, index)
    if not check.can_upgrade:
        return false

    if not target_type in check.options:
        return false

    # Deduct cost
    var cost: Dictionary = check.costs.get(target_type, {})
    for res_key in cost.keys():
        var res_name: String = str(res_key)
        var amount: int = int(cost[res_key])
        if res_name == "gold":
            state.gold -= amount
        else:
            state.resources[res_name] = int(state.resources.get(res_name, 0)) - amount

    # Replace structure
    state.structures[index] = target_type
    return true


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

# Generic building upgrade functions

static func max_level(building_type: String) -> int:
    if BUILDING_UPGRADES.has(building_type):
        return int(BUILDING_UPGRADES[building_type].get("max_level", 1))
    return 1

static func building_upgrade_cost(building_type: String, current_level: int) -> Dictionary:
    if not BUILDING_UPGRADES.has(building_type):
        return {}
    var upgrades: Dictionary = BUILDING_UPGRADES[building_type]
    var next_level: int = current_level + 1
    if not upgrades.get("levels", {}).has(next_level):
        return {}
    return upgrades["levels"][next_level].get("cost", {}).duplicate(true)

static func worker_slots_for(building_type: String, level: int) -> int:
    var base_slots: int = int(BUILDINGS.get(building_type, {}).get("worker_slots", 0))
    if level <= 1:
        return base_slots
    if not BUILDING_UPGRADES.has(building_type):
        return base_slots
    var level_data: Dictionary = BUILDING_UPGRADES[building_type].get("levels", {}).get(level, {})
    return int(level_data.get("worker_slots", base_slots))

static func production_for_level(building_type: String, level: int) -> Dictionary:
    var base_prod: Dictionary = production_for(building_type).duplicate(true)
    if level <= 1:
        return base_prod
    if not BUILDING_UPGRADES.has(building_type):
        return base_prod
    var level_data: Dictionary = BUILDING_UPGRADES[building_type].get("levels", {}).get(level, {})
    if level_data.has("production"):
        return level_data["production"].duplicate(true)
    return base_prod

static func defense_for_level(building_type: String, level: int) -> int:
    var base_def: int = defense_for(building_type)
    if level <= 1:
        return base_def
    if not BUILDING_UPGRADES.has(building_type):
        return base_def
    var level_data: Dictionary = BUILDING_UPGRADES[building_type].get("levels", {}).get(level, {})
    return int(level_data.get("defense", base_def))

static func effects_for_level(building_type: String, level: int) -> Dictionary:
    var base_effects: Dictionary = BUILDINGS.get(building_type, {}).get("effects", {}).duplicate(true)
    if level <= 1:
        return base_effects
    if not BUILDING_UPGRADES.has(building_type):
        return base_effects
    var level_data: Dictionary = BUILDING_UPGRADES[building_type].get("levels", {}).get(level, {})
    if level_data.has("effects"):
        return level_data["effects"].duplicate(true)
    return base_effects

static func can_upgrade(state: GameState, index: int) -> Dictionary:
    var result := {"ok": false, "reason": "", "cost": {}, "next_level": 0}

    if not state.structures.has(index):
        result.reason = "no building"
        return result

    var building_type: String = str(state.structures[index])
    var current_level: int = structure_level(state, index)
    var max_lvl: int = max_level(building_type)

    if current_level >= max_lvl:
        result.reason = "max level"
        return result

    var cost: Dictionary = building_upgrade_cost(building_type, current_level)
    if cost.is_empty():
        result.reason = "no upgrade available"
        return result

    # Check resources
    for res_key in cost.keys():
        var have: int = int(state.resources.get(res_key, 0))
        if res_key == "gold":
            have = state.gold
        if have < int(cost[res_key]):
            result.reason = "not enough " + res_key
            return result

    result.ok = true
    result.cost = cost
    result.next_level = current_level + 1
    return result

static func get_building_upgrade_preview(state: GameState, index: int) -> Dictionary:
    var preview := {
        "building_type": "",
        "current_level": 0,
        "can_upgrade": false,
        "reason": "",
        "cost": {},
        "next_level": 0,
        "current_stats": {},
        "next_stats": {}
    }

    if not state.structures.has(index):
        return preview

    var building_type: String = str(state.structures[index])
    var current_level: int = structure_level(state, index)

    preview.building_type = building_type
    preview.current_level = current_level
    preview.current_stats = {
        "production": production_for_level(building_type, current_level),
        "defense": defense_for_level(building_type, current_level),
        "worker_slots": worker_slots_for(building_type, current_level),
        "effects": effects_for_level(building_type, current_level)
    }

    var upgrade_check: Dictionary = can_upgrade(state, index)
    preview.can_upgrade = upgrade_check.ok
    preview.reason = upgrade_check.reason
    preview.cost = upgrade_check.cost
    preview.next_level = upgrade_check.next_level

    if upgrade_check.ok:
        var next_level: int = upgrade_check.next_level
        preview.next_stats = {
            "production": production_for_level(building_type, next_level),
            "defense": defense_for_level(building_type, next_level),
            "worker_slots": worker_slots_for(building_type, next_level),
            "effects": effects_for_level(building_type, next_level)
        }

    return preview

static func apply_upgrade(state: GameState, index: int) -> bool:
    var check: Dictionary = can_upgrade(state, index)
    if not check.ok:
        return false

    # Deduct costs
    for res_key in check.cost.keys():
        if res_key == "gold":
            state.gold -= int(check.cost[res_key])
        else:
            state.resources[res_key] = int(state.resources.get(res_key, 0)) - int(check.cost[res_key])

    # Apply level
    state.structure_levels[index] = check.next_level
    return true

static func count_adjacent_buildings(state: GameState, pos: Vector2i) -> int:
    var count: int = 0
    for neighbor in SimMap.neighbors4(pos, state.map_w, state.map_h):
        var idx: int = SimMap.idx(neighbor.x, neighbor.y, state.map_w)
        if state.structures.has(idx):
            count += 1
    return count

static func get_total_effects(state: GameState) -> Dictionary:
    var effects := {
        "wave_heal": 0,
        "typing_power": 0.0,
        "combo_bonus": 0.0,
        "build_cost_reduction": 0.0,
        "upgrade_cost_reduction": 0.0,
        "tower_damage": 0,
        "enemy_slow": 0.0,
        "castle_hp": 0,
        "morale": 0.0
    }

    for key in state.structures.keys():
        var building_type: String = str(state.structures[key])
        var level: int = structure_level(state, int(key))
        var building_effects: Dictionary = effects_for_level(building_type, level)

        for effect_key in building_effects.keys():
            if effects.has(effect_key):
                if effect_key in ["wave_heal", "tower_damage", "castle_hp"]:
                    effects[effect_key] = int(effects[effect_key]) + int(building_effects[effect_key])
                else:
                    effects[effect_key] = float(effects[effect_key]) + float(building_effects[effect_key])

    return effects

static func get_available_buildings(_state: GameState) -> Array:
    ## Returns list of building IDs that can be constructed (excludes aliases and legendary towers)
    var available: Array = []
    for building_id in BUILDINGS.keys():
        var info: Dictionary = BUILDINGS[building_id]
        # Skip alias buildings
        if info.has("alias_of"):
            continue
        # Skip legendary towers (require special unlock)
        if info.get("legendary", false):
            continue
        # Skip advanced auto-towers for now (tier 2+) - unlocked via research
        if info.get("category", "") == "auto_defense" and int(info.get("tier", 1)) > 1:
            continue
        available.append(building_id)
    return available

static func get_building_info(building_id: String) -> Dictionary:
    ## Returns full building info dictionary for display purposes
    if not BUILDINGS.has(building_id):
        return {}
    return BUILDINGS[building_id].duplicate(true)

static func can_afford(state: GameState, cost: Dictionary) -> bool:
    ## Returns true if player can afford the given cost dictionary
    for res_key in cost.keys():
        var required: int = int(cost[res_key])
        var current: int = 0
        if res_key == "gold":
            current = state.gold
        else:
            current = int(state.resources.get(res_key, 0))
        if current < required:
            return false
    return true
