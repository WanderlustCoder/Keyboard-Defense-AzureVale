extends Node2D

const GameState = preload("res://sim/types.gd")
const SimMap = preload("res://sim/map.gd")
const SimEnemies = preload("res://sim/enemies.gd")
const SimPoi = preload("res://sim/poi.gd")
const AssetLoader = preload("res://game/asset_loader.gd")

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
@export var poi_color: Color = Color(0.4, 0.7, 0.9, 1.0)
@export var poi_undiscovered_color: Color = Color(0.3, 0.5, 0.6, 0.6)
@export var font_size: int = 16
@export var use_sprites: bool = true

var map_w: int = 16
var map_h: int = 10
var base_pos: Vector2i = Vector2i(0, 0)
var cursor_pos: Vector2i = Vector2i(0, 0)
var discovered: Dictionary = {}
var terrain: Array = []
var structures: Dictionary = {}
var structure_levels: Dictionary = {}
var enemies: Array = []
var active_pois: Dictionary = {}
var font: Font
var preview_type: String = ""
var overlay_path_enabled: bool = false
var state_ref: GameState
var highlight_enemy_ids: Dictionary = {}
var focus_enemy_id: int = -1

# Asset loader and texture cache
var asset_loader: AssetLoader
var texture_cache: Dictionary = {}

# Hit effect particles
var _active_particles: Array = []
const PARTICLE_LIFETIME := 0.35
const PARTICLE_SPEED := 100.0

func _ready() -> void:
	asset_loader = AssetLoader.new()
	asset_loader._load_manifest()
	_preload_textures()

func _preload_textures() -> void:
	# Preload common textures
	var ids := [
		"bld_wall", "bld_tower_arrow", "bld_tower_slow",
		"bld_barracks", "bld_library", "bld_gate", "bld_castle",
		"castle_base", "castle_damaged",
		"enemy_runner", "enemy_brute", "enemy_flyer",
		"enemy_shielder", "enemy_healer",
		"tile_grass", "tile_evergrove_dense", "tile_dirt", "tile_water"
	]
	for id in ids:
		var tex := asset_loader.get_texture(id)
		if tex != null:
			texture_cache[id] = tex

func _get_texture(id: String) -> Texture2D:
	if texture_cache.has(id):
		return texture_cache[id]
	var tex := asset_loader.get_texture(id)
	if tex != null:
		texture_cache[id] = tex
	return tex

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
	active_pois = state.active_pois.duplicate(true)
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

	# Draw terrain tiles
	for y in range(map_h):
		for x in range(map_w):
			var top_left: Vector2 = origin + Vector2(x * cell_size.x, y * cell_size.y)
			var rect: Rect2 = Rect2(top_left, cell_size)
			var index: int = y * map_w + x
			var is_discovered: bool = discovered.has(index)
			var terrain_type := _terrain_at(index)

			# Draw terrain background
			var fill: Color = undiscovered_color
			if is_discovered:
				if use_sprites:
					var tile_tex := _get_terrain_texture(terrain_type)
					if tile_tex != null:
						_draw_tiled_texture(rect, tile_tex)
					else:
						fill = _terrain_color(terrain_type)
						draw_rect(rect, fill, true)
				else:
					fill = _terrain_color(terrain_type)
					draw_rect(rect, fill, true)
			else:
				draw_rect(rect, fill, true)

			# Draw path overlay
			if overlay_path_enabled and dist_field.size() == map_w * map_h:
				var overlay_color: Color = overlay_reachable_color if dist_field[index] >= 0 else overlay_blocked_color
				draw_rect(rect, overlay_color, true)

			# Draw grid lines
			draw_rect(rect, line_color, false, 1.0)

			# Draw structures
			if is_discovered and structures.has(index):
				var building_type: String = str(structures[index])
				var level: int = int(structure_levels.get(index, 1))
				if use_sprites:
					_draw_structure_sprite(rect, building_type, level)
				else:
					var symbol: String = _structure_char(building_type, level)
					var text_pos: Vector2 = rect.position + Vector2(6, cell_size.y - 10)
					draw_string(font, text_pos, symbol, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, structure_color)

	# Draw POIs
	for poi_id in active_pois:
		var poi_state: Dictionary = active_pois[poi_id]
		var poi_pos: Variant = poi_state.get("pos", null)
		if poi_pos == null or not (poi_pos is Vector2i):
			continue
		var pos: Vector2i = poi_pos
		if not SimMap.in_bounds(pos.x, pos.y, map_w, map_h):
			continue
		var poi_index: int = pos.y * map_w + pos.x
		if not discovered.has(poi_index):
			continue
		var poi_rect: Rect2 = Rect2(origin + Vector2(pos.x * cell_size.x, pos.y * cell_size.y), cell_size)
		var poi_discovered: bool = bool(poi_state.get("discovered", false))
		var poi_interacted: bool = bool(poi_state.get("interacted", false))

		# Get POI data for icon
		var poi_data: Dictionary = SimPoi.get_poi(str(poi_id))
		var icon_name: String = str(poi_data.get("icon", "poi"))

		# Draw POI marker
		if poi_interacted:
			# Dim marker for interacted POIs
			var dim_color := Color(0.4, 0.4, 0.4, 0.5)
			draw_rect(poi_rect.grow(-6.0), dim_color, false, 2.0)
		elif poi_discovered:
			# Bright marker for discovered POIs
			draw_rect(poi_rect.grow(-4.0), poi_color, false, 2.0)
			var poi_symbol := _poi_symbol(icon_name)
			var poi_text_pos: Vector2 = poi_rect.position + Vector2(cell_size.x - 14, 14)
			draw_string(font, poi_text_pos, poi_symbol, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 4, poi_color)
		else:
			# Subtle marker for undiscovered POIs
			draw_rect(poi_rect.grow(-6.0), poi_undiscovered_color, false, 1.0)

	# Draw building preview
	if preview_type != "":
		var preview_index: int = cursor_pos.y * map_w + cursor_pos.x
		var preview_rect: Rect2 = Rect2(origin + Vector2(cursor_pos.x * cell_size.x, cursor_pos.y * cell_size.y), cell_size)
		var preview_buildable: bool = _is_preview_buildable(preview_index)

		if use_sprites:
			var sprite_id := asset_loader.get_building_sprite_id(preview_type)
			var tex := _get_texture(sprite_id)
			if tex != null:
				var mod_color := Color(1, 1, 1, 0.6) if preview_buildable else Color(1, 0.4, 0.4, 0.6)
				_draw_centered_texture(preview_rect, tex, mod_color)
		else:
			var preview_symbol: String = _structure_char(preview_type, 1).to_lower()
			var preview_color_local: Color = preview_color if preview_buildable else preview_blocked_color
			var preview_text_pos: Vector2 = preview_rect.position + Vector2(6, cell_size.y - 10)
			var preview_draw: String = preview_symbol if preview_buildable else "x"
			draw_string(font, preview_text_pos, preview_draw, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, preview_color_local)

	# Draw enemies
	for enemy in enemies:
		if typeof(enemy) != TYPE_DICTIONARY:
			continue
		var pos: Vector2i = enemy.get("pos", Vector2i.ZERO)
		if not SimMap.in_bounds(pos.x, pos.y, map_w, map_h):
			continue
		var enemy_rect: Rect2 = Rect2(origin + Vector2(pos.x * cell_size.x, pos.y * cell_size.y), cell_size)
		var enemy_id: int = int(enemy.get("id", 0))

		# Draw highlight boxes
		if highlight_enemy_ids.has(enemy_id):
			draw_rect(enemy_rect.grow(-3.0), enemy_highlight_color, false, 2.0)
		if enemy_id == focus_enemy_id and focus_enemy_id != -1:
			draw_rect(enemy_rect.grow(-1.0), enemy_focus_color, false, 2.0)

		# Draw enemy sprite or glyph
		var kind: String = str(enemy.get("kind", "raider"))
		if use_sprites:
			var sprite_id := asset_loader.get_enemy_sprite_id(kind)
			var tex := _get_texture(sprite_id)
			if tex != null:
				_draw_centered_texture(enemy_rect, tex)
			else:
				# Fallback to glyph
				var glyph: String = SimEnemies.enemy_glyph(kind)
				var enemy_text_pos: Vector2 = enemy_rect.position + Vector2(6, cell_size.y - 10)
				draw_string(font, enemy_text_pos, glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, enemy_color)
		else:
			var glyph: String = SimEnemies.enemy_glyph(kind)
			var enemy_text_pos: Vector2 = enemy_rect.position + Vector2(6, cell_size.y - 10)
			draw_string(font, enemy_text_pos, glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, enemy_color)

		# Draw HP text
		var hp_text: String = str(enemy.get("hp", 0))
		draw_string(font, enemy_rect.position + Vector2(22, 16), hp_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 4, enemy_color)

		# Draw word initial
		var word: String = str(enemy.get("word", ""))
		if word != "":
			var initial: String = word.substr(0, 1)
			draw_string(font, enemy_rect.position + Vector2(6, 16), initial, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 6, enemy_color)

	# Draw base with state-based sprite
	var base_rect: Rect2 = Rect2(origin + Vector2(base_pos.x * cell_size.x, base_pos.y * cell_size.y), cell_size)
	if use_sprites:
		var castle_tex := _get_castle_texture()
		var castle_tint := _get_castle_tint()
		if castle_tex != null:
			_draw_centered_texture(base_rect.grow(4.0), castle_tex, castle_tint)
		else:
			draw_rect(base_rect.grow(-4.0), base_color, true)
	else:
		draw_rect(base_rect.grow(-4.0), base_color, true)

	# Draw cursor
	var cursor_rect: Rect2 = Rect2(origin + Vector2(cursor_pos.x * cell_size.x, cursor_pos.y * cell_size.y), cell_size)
	draw_rect(cursor_rect.grow(-2.0), cursor_color, false, 2.0)

	# Draw particles on top
	_draw_particles()

func _process(delta: float) -> void:
	update_particles(delta)

func _draw_centered_texture(rect: Rect2, tex: Texture2D, mod_color: Color = Color.WHITE) -> void:
	var tex_size := tex.get_size()
	var scale_factor: float = minf(rect.size.x / tex_size.x, rect.size.y / tex_size.y) * 0.9
	var scaled_size: Vector2 = tex_size * scale_factor
	var offset: Vector2 = (rect.size - scaled_size) * 0.5
	var dest_rect := Rect2(rect.position + offset, scaled_size)
	draw_texture_rect(tex, dest_rect, false, mod_color)

func _draw_tiled_texture(rect: Rect2, tex: Texture2D) -> void:
	# Draw texture scaled to fit cell
	draw_texture_rect(tex, rect, false)

func _draw_structure_sprite(rect: Rect2, building_type: String, level: int) -> void:
	var sprite_id := asset_loader.get_building_sprite_id(building_type)
	# For towers, try to get level-specific sprite
	if building_type == "tower" and level > 1:
		var leveled_id := "bld_tower_slow" if level >= 2 else sprite_id
		var tex := _get_texture(leveled_id)
		if tex != null:
			_draw_centered_texture(rect, tex)
			return
	var tex := _get_texture(sprite_id)
	if tex != null:
		_draw_centered_texture(rect, tex)
	else:
		# Fallback to text
		var symbol: String = _structure_char(building_type, level)
		var text_pos: Vector2 = rect.position + Vector2(6, cell_size.y - 10)
		draw_string(font, text_pos, symbol, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, structure_color)

func _get_terrain_texture(terrain_name: String) -> Texture2D:
	match terrain_name:
		SimMap.TERRAIN_PLAINS:
			return _get_texture("tile_grass")
		SimMap.TERRAIN_FOREST:
			return _get_texture("tile_evergrove_dense")
		SimMap.TERRAIN_MOUNTAIN:
			return _get_texture("tile_dirt")
		SimMap.TERRAIN_WATER:
			return _get_texture("tile_water")
		_:
			return null

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

func _poi_symbol(icon_name: String) -> String:
	match icon_name:
		"wagon":
			return "W"
		"shrine":
			return "S"
		"herbs":
			return "H"
		"ruins":
			return "R"
		"camp":
			return "C"
		"cave":
			return "V"
		_:
			return "?"

## Get castle texture based on HP state
func _get_castle_texture() -> Texture2D:
	if state_ref == null:
		return _get_texture("bld_castle")

	var hp: int = state_ref.hp
	var max_hp: int = state_ref.max_hp

	# Damaged state: HP <= 30% of max
	if hp <= int(max_hp * 0.3):
		var damaged_tex := _get_texture("castle_damaged")
		if damaged_tex != null:
			return damaged_tex

	# Default/healthy castle
	return _get_texture("bld_castle")

## Get castle color tint based on HP and upgrades
func _get_castle_tint() -> Color:
	if state_ref == null:
		return Color.WHITE

	var hp: int = state_ref.hp
	var max_hp: int = state_ref.max_hp
	var hp_percent: float = float(hp) / float(max_hp) if max_hp > 0 else 1.0

	# Critical HP: red tint
	if hp_percent <= 0.25:
		return Color(1.0, 0.7, 0.7, 1.0)
	# Low HP: orange tint
	elif hp_percent <= 0.5:
		return Color(1.0, 0.9, 0.8, 1.0)

	# Check for upgrades that enhance the castle
	var kingdom_upgrades: Array = state_ref.purchased_kingdom_upgrades
	var upgrade_count: int = kingdom_upgrades.size()

	# Many upgrades: golden glow
	if upgrade_count >= 6:
		return Color(1.1, 1.05, 0.95, 1.0)
	# Some upgrades: slight blue glow
	elif upgrade_count >= 3:
		return Color(1.0, 1.0, 1.05, 1.0)

	return Color.WHITE

## Spawn projectile from castle to enemy position
func spawn_projectile(enemy_pos: Vector2i, is_power: bool = false) -> void:
	var start_pos: Vector2 = origin + Vector2(base_pos.x * cell_size.x, base_pos.y * cell_size.y) + cell_size * 0.5
	var end_pos: Vector2 = origin + Vector2(enemy_pos.x * cell_size.x, enemy_pos.y * cell_size.y) + cell_size * 0.5
	var direction: Vector2 = (end_pos - start_pos).normalized()
	var color: Color = Color(1.0, 0.9, 0.4, 1.0) if is_power else Color(0.9, 0.7, 0.3, 1.0)
	var size: Vector2 = Vector2(8, 4) if is_power else Vector2(6, 3)

	_active_particles.append({
		"type": "projectile",
		"pos": start_pos,
		"target": end_pos,
		"velocity": direction * PARTICLE_SPEED * (1.5 if is_power else 1.0),
		"color": color,
		"size": size,
		"lifetime": PARTICLE_LIFETIME * 2.0
	})
	queue_redraw()

## Spawn hit spark particles at position
func spawn_hit_sparks(world_pos: Vector2, is_power: bool = false) -> void:
	var count: int = 8 if is_power else 5
	var base_color: Color = Color(1.0, 0.95, 0.5, 1.0) if is_power else Color(0.95, 0.85, 0.4, 1.0)

	for i in range(count):
		var angle: float = randf() * TAU
		var speed: float = PARTICLE_SPEED * (0.4 + randf() * 0.6) * (1.3 if is_power else 1.0)
		var size: Vector2 = Vector2(5, 2) if i % 2 == 0 else Vector2(3, 3)

		_active_particles.append({
			"type": "spark",
			"pos": world_pos,
			"velocity": Vector2(cos(angle), sin(angle)) * speed,
			"color": base_color,
			"size": size,
			"lifetime": PARTICLE_LIFETIME
		})
	queue_redraw()

## Spawn damage flash at castle
func spawn_damage_flash() -> void:
	var castle_pos: Vector2 = origin + Vector2(base_pos.x * cell_size.x, base_pos.y * cell_size.y) + cell_size * 0.5

	for i in range(6):
		var angle: float = randf() * TAU
		var speed: float = PARTICLE_SPEED * 0.6 * (0.3 + randf() * 0.7)

		_active_particles.append({
			"type": "damage",
			"pos": castle_pos,
			"velocity": Vector2(cos(angle), sin(angle)) * speed,
			"color": Color(1.0, 0.35, 0.25, 1.0),
			"size": Vector2(4, 4),
			"lifetime": PARTICLE_LIFETIME * 0.7
		})
	queue_redraw()

## Update particles - call from _process
func update_particles(delta: float) -> void:
	if _active_particles.is_empty():
		return

	var needs_redraw: bool = false
	for i in range(_active_particles.size() - 1, -1, -1):
		var p: Dictionary = _active_particles[i]
		p["lifetime"] = p.get("lifetime", 0.0) - delta

		if p["lifetime"] <= 0.0:
			_active_particles.remove_at(i)
			needs_redraw = true
			continue

		var vel: Vector2 = p.get("velocity", Vector2.ZERO)
		var ptype: String = str(p.get("type", "spark"))

		# Apply gravity to sparks and damage particles
		if ptype == "spark" or ptype == "damage":
			vel.y += 180.0 * delta
			p["velocity"] = vel

		# Check projectile hit
		if ptype == "projectile":
			var target: Vector2 = p.get("target", Vector2.ZERO)
			if p["pos"].distance_to(target) < 8.0:
				spawn_hit_sparks(target, p["size"].x > 6)
				_active_particles.remove_at(i)
				needs_redraw = true
				continue

		p["pos"] = p["pos"] + vel * delta
		needs_redraw = true

	if needs_redraw:
		queue_redraw()

func _draw_particles() -> void:
	for p in _active_particles:
		var pos: Vector2 = p.get("pos", Vector2.ZERO)
		var color: Color = p.get("color", Color.WHITE)
		var psize: Vector2 = p.get("size", Vector2(4, 4))
		var lifetime: float = p.get("lifetime", 0.0)

		# Fade out
		var alpha: float = clampf(lifetime / (PARTICLE_LIFETIME * 0.5), 0.0, 1.0)
		color.a = alpha

		var rect: Rect2 = Rect2(pos - psize * 0.5, psize)
		draw_rect(rect, color, true)
