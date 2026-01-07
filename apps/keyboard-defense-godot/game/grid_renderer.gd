extends Node2D

const GameState = preload("res://sim/types.gd")
const SimMap = preload("res://sim/map.gd")
const SimEnemies = preload("res://sim/enemies.gd")

@export var cell_size: Vector2 = Vector2(40, 40)
@export var origin: Vector2 = Vector2(560, 40)
@export var line_color: Color = Color(0.25, 0.25, 0.32, 1.0)
@export var undiscovered_color: Color = Color(0.08, 0.09, 0.12, 1.0)
@export var plains_color: Color = Color(0.2, 0.22, 0.18, 1.0)
@export var forest_color: Color = Color(0.13, 0.2, 0.13, 1.0)
@export var mountain_color: Color = Color(0.2, 0.2, 0.22, 1.0)
@export var water_color: Color = Color(0.1, 0.16, 0.25, 1.0)
@export var base_color: Color = Color(0.25, 0.4, 0.25, 1.0)
@export var cursor_color: Color = Color(0.9, 0.8, 0.35, 1.0)
@export var structure_color: Color = Color(0.95, 0.95, 0.95, 1.0)
@export var preview_color: Color = Color(0.9, 0.9, 0.9, 0.6)
@export var preview_blocked_color: Color = Color(0.9, 0.4, 0.4, 0.6)
@export var overlay_reachable_color: Color = Color(0.1, 0.4, 0.2, 0.25)
@export var overlay_blocked_color: Color = Color(0.4, 0.1, 0.1, 0.25)
@export var enemy_color: Color = Color(0.9, 0.3, 0.3, 1.0)
@export var enemy_highlight_color: Color = Color(0.95, 0.85, 0.4, 0.8)
@export var enemy_focus_color: Color = Color(1.0, 0.85, 0.2, 0.95)
@export var font_size: int = 16

var map_w: int = 16
var map_h: int = 10
var base_pos: Vector2i = Vector2i(0, 0)
var cursor_pos: Vector2i = Vector2i(0, 0)
var discovered: Dictionary = {}
var terrain: Array = []
var structures: Dictionary = {}
var structure_levels: Dictionary = {}
var enemies: Array = []
var font: Font
var preview_type: String = ""
var overlay_path_enabled: bool = false
var state_ref: GameState
var highlight_enemy_ids: Dictionary = {}
var focus_enemy_id: int = -1

func update_state(state: GameState) -> void:
    state_ref = state
    map_w = state.map_w
    map_h = state.map_h
    base_pos = state.base_pos
    cursor_pos = state.cursor_pos
    discovered = state.discovered.duplicate(true)
    terrain = state.terrain.duplicate(true)
    structures = state.structures.duplicate(true)
    structure_levels = state.structure_levels.duplicate(true)
    enemies = state.enemies.duplicate(true)
    queue_redraw()

func set_preview_type(building_type: String) -> void:
    preview_type = building_type
    queue_redraw()

func set_path_overlay(enabled: bool) -> void:
    overlay_path_enabled = enabled
    queue_redraw()

func set_enemy_highlights(candidate_ids: Array, focus_id: int) -> void:
    highlight_enemy_ids.clear()
    for enemy_id in candidate_ids:
        highlight_enemy_ids[int(enemy_id)] = true
    focus_enemy_id = focus_id
    queue_redraw()

func _draw() -> void:
    if font == null:
        font = ThemeDB.fallback_font
    var dist_field: PackedInt32Array = PackedInt32Array()
    if overlay_path_enabled and state_ref != null:
        dist_field = SimMap.compute_dist_to_base(state_ref)
    for y in range(map_h):
        for x in range(map_w):
            var top_left: Vector2 = origin + Vector2(x * cell_size.x, y * cell_size.y)
            var rect: Rect2 = Rect2(top_left, cell_size)
            var index: int = y * map_w + x
            var is_discovered: bool = discovered.has(index)
            var fill: Color = undiscovered_color
            if is_discovered:
                fill = _terrain_color(_terrain_at(index))
            draw_rect(rect, fill, true)
            if overlay_path_enabled and dist_field.size() == map_w * map_h:
                var overlay_color: Color = overlay_reachable_color if dist_field[index] >= 0 else overlay_blocked_color
                draw_rect(rect, overlay_color, true)
            draw_rect(rect, line_color, false, 1.0)

            if is_discovered and structures.has(index):
                var building_type: String = str(structures[index])
                var symbol: String = _structure_char(building_type, int(structure_levels.get(index, 1)))
                var text_pos: Vector2 = rect.position + Vector2(6, cell_size.y - 10)
                draw_string(font, text_pos, symbol, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, structure_color)

    if preview_type != "":
        var preview_index: int = cursor_pos.y * map_w + cursor_pos.x
        var preview_rect: Rect2 = Rect2(origin + Vector2(cursor_pos.x * cell_size.x, cursor_pos.y * cell_size.y), cell_size)
        var preview_buildable: bool = _is_preview_buildable(preview_index)
        var preview_symbol: String = _structure_char(preview_type, 1).to_lower()
        var preview_color_local: Color = preview_color if preview_buildable else preview_blocked_color
        var preview_text_pos: Vector2 = preview_rect.position + Vector2(6, cell_size.y - 10)
        var preview_draw: String = preview_symbol if preview_buildable else "x"
        draw_string(font, preview_text_pos, preview_draw, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, preview_color_local)

    for enemy in enemies:
        if typeof(enemy) != TYPE_DICTIONARY:
            continue
        var pos: Vector2i = enemy.get("pos", Vector2i.ZERO)
        if not SimMap.in_bounds(pos.x, pos.y, map_w, map_h):
            continue
        var enemy_rect: Rect2 = Rect2(origin + Vector2(pos.x * cell_size.x, pos.y * cell_size.y), cell_size)
        var enemy_id: int = int(enemy.get("id", 0))
        if highlight_enemy_ids.has(enemy_id):
            draw_rect(enemy_rect.grow(-3.0), enemy_highlight_color, false, 2.0)
        if enemy_id == focus_enemy_id and focus_enemy_id != -1:
            draw_rect(enemy_rect.grow(-1.0), enemy_focus_color, false, 2.0)
        var enemy_text_pos: Vector2 = enemy_rect.position + Vector2(6, cell_size.y - 10)
        var glyph: String = SimEnemies.enemy_glyph(str(enemy.get("kind", "raider")))
        draw_string(font, enemy_text_pos, glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, enemy_color)
        var hp_text: String = str(enemy.get("hp", 0))
        draw_string(font, enemy_rect.position + Vector2(22, 16), hp_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 4, enemy_color)
        var word: String = str(enemy.get("word", ""))
        if word != "":
            var initial: String = word.substr(0, 1)
            draw_string(font, enemy_rect.position + Vector2(6, 16), initial, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 6, enemy_color)

    var base_rect: Rect2 = Rect2(origin + Vector2(base_pos.x * cell_size.x, base_pos.y * cell_size.y), cell_size)
    draw_rect(base_rect.grow(-4.0), base_color, true)

    var cursor_rect: Rect2 = Rect2(origin + Vector2(cursor_pos.x * cell_size.x, cursor_pos.y * cell_size.y), cell_size)
    draw_rect(cursor_rect.grow(-2.0), cursor_color, false, 2.0)

func _terrain_at(index: int) -> String:
    if index < 0 or index >= terrain.size():
        return ""
    return str(terrain[index])

func _terrain_color(terrain_name: String) -> Color:
    match terrain_name:
        SimMap.TERRAIN_PLAINS:
            return plains_color
        SimMap.TERRAIN_FOREST:
            return forest_color
        SimMap.TERRAIN_MOUNTAIN:
            return mountain_color
        SimMap.TERRAIN_WATER:
            return water_color
        _:
            return plains_color

func _structure_char(building_type: String, level: int) -> String:
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
            return "T%d" % level
        _:
            return "?"

func _is_preview_buildable(index: int) -> bool:
    if index < 0 or index >= map_w * map_h:
        return false
    var pos: Vector2i = Vector2i(index % map_w, int(index / map_w))
    if pos == base_pos:
        return false
    if not discovered.has(index):
        return false
    if structures.has(index):
        return false
    if _terrain_at(index) == SimMap.TERRAIN_WATER:
        return false
    return true
