class_name GameState
extends RefCounted

const RESOURCE_KEYS := ["wood", "stone", "food"]
const BUILDING_KEYS := ["farm", "lumber", "quarry", "wall", "tower"]

var day: int
var phase: String
var ap_max: int
var ap: int
var hp: int
var threat: int
var resources: Dictionary
var buildings: Dictionary
var map_w: int
var map_h: int
var base_pos: Vector2i
var cursor_pos: Vector2i
var terrain: Array
var structures: Dictionary
var structure_levels: Dictionary
var discovered: Dictionary
var night_prompt: String
var night_spawn_remaining: int
var night_wave_total: int
var enemies: Array
var enemy_next_id: int
var last_path_open: bool
var rng_seed: String
var rng_state: int
var lesson_id: String
var version: int

func _init() -> void:
    day = 1
    phase = "day"
    ap_max = 3
    ap = ap_max
    hp = 10
    threat = 0
    map_w = 16
    map_h = 10
    base_pos = Vector2i(int(map_w / 2), int(map_h / 2))
    cursor_pos = base_pos
    night_prompt = ""
    night_spawn_remaining = 0
    night_wave_total = 0
    enemies = []
    enemy_next_id = 1
    last_path_open = true
    rng_seed = "default"
    rng_state = 0
    lesson_id = "full_alpha"
    version = 1

    resources = {}
    for key in RESOURCE_KEYS:
        resources[key] = 0

    buildings = {}
    for key in BUILDING_KEYS:
        buildings[key] = 0

    terrain = []
    for _i in range(map_w * map_h):
        terrain.append("")

    structures = {}
    structure_levels = {}

    discovered = {}
    discovered[_index(base_pos.x, base_pos.y)] = true

func _index(x: int, y: int) -> int:
    return y * map_w + x
