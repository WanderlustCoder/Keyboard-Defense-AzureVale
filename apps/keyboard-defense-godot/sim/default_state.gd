class_name DefaultState
extends RefCounted

const GameState = preload("res://sim/types.gd")
const SimMap = preload("res://sim/map.gd")
const SimRng = preload("res://sim/rng.gd")
const SimLessons = preload("res://sim/lessons.gd")

static func create(seed: String = "default") -> GameState:
    var state: GameState = GameState.new()
    SimRng.seed_state(state, seed)
    state.lesson_id = SimLessons.default_lesson_id()
    SimMap.generate_terrain(state)
    var base_index: int = SimMap.idx(state.base_pos.x, state.base_pos.y, state.map_w)
    state.terrain[base_index] = SimMap.TERRAIN_PLAINS
    # Starting resources
    state.gold = 10
    # Place starting auto-towers near base
    _place_starting_towers(state)
    return state


static func _place_starting_towers(state: GameState) -> void:
    var base: Vector2i = state.base_pos
    # Try to place towers adjacent to base (left and right)
    var tower_positions: Array[Vector2i] = [
        Vector2i(base.x - 1, base.y),  # Left of base
        Vector2i(base.x + 1, base.y),  # Right of base
    ]
    var tower_types: Array[String] = ["auto_sentry", "auto_spark"]

    for i in tower_positions.size():
        var pos: Vector2i = tower_positions[i]
        if not SimMap.in_bounds(pos.x, pos.y, state.map_w, state.map_h):
            continue
        var index: int = SimMap.idx(pos.x, pos.y, state.map_w)
        # Ensure terrain is buildable
        if state.terrain[index] == SimMap.TERRAIN_WATER:
            state.terrain[index] = SimMap.TERRAIN_PLAINS
        # Place the tower
        state.structures[index] = tower_types[i]
