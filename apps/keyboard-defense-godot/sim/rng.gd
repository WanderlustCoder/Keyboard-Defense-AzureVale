class_name SimRng
extends RefCounted

const GameState = preload("res://sim/types.gd")

static func seed_to_int(seed: String) -> int:
    var hashed: int = seed.hash()
    if hashed == -9223372036854775808:
        return 0
    return abs(hashed)

static func seed_state(state: GameState, seed_string: String) -> void:
    state.rng_seed = seed_string
    state.rng_state = seed_to_int(seed_string)

static func roll_range(state: GameState, min_value: int, max_value: int) -> int:
    var rng: RandomNumberGenerator = RandomNumberGenerator.new()
    rng.state = state.rng_state
    var value: int = rng.randi_range(min_value, max_value)
    state.rng_state = rng.state
    return value

static func choose(state: GameState, arr: Array) -> Variant:
    if arr.is_empty():
        return null
    var index: int = roll_range(state, 0, arr.size() - 1)
    return arr[index]
