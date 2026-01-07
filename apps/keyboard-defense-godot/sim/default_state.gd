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
    return state
