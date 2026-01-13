extends Node2D

const GameState = preload("res://sim/types.gd")
const SimMap = preload("res://sim/map.gd")
const SimEnemies = preload("res://sim/enemies.gd")
const SimPoi = preload("res://sim/poi.gd")
const SimUpgrades = preload("res://sim/upgrades.gd")
const SimBuildings = preload("res://sim/buildings.gd")
const SimTowerSynergies = preload("res://sim/tower_synergies.gd")
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
@export var show_grid_lines: bool = false

# Visual placement system colors
@export var range_circle_color: Color = Color(0.4, 0.7, 1.0, 0.25)
@export var range_circle_border_color: Color = Color(0.4, 0.7, 1.0, 0.5)
@export var grid_overlay_buildable_color: Color = Color(0.2, 0.6, 0.3, 0.15)
@export var grid_overlay_unbuildable_color: Color = Color(0.6, 0.2, 0.2, 0.1)
@export var cost_tooltip_bg_color: Color = Color(0.08, 0.08, 0.12, 0.95)
@export var cost_affordable_color: Color = Color(0.4, 0.85, 0.5, 1.0)
@export var cost_unaffordable_color: Color = Color(0.9, 0.4, 0.4, 1.0)

# Synergy visualization colors
@export var synergy_line_color: Color = Color(0.5, 0.8, 1.0, 0.4)
@export var synergy_glow_color: Color = Color(0.4, 0.7, 1.0, 0.25)
@export var synergy_preview_color: Color = Color(0.3, 0.9, 0.5, 0.5)

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
var roaming_enemies: Array = []
var time_of_day: float = 0.25
var threat_level: float = 0.0
var activity_mode: String = "exploration"
var font: Font
var preview_type: String = ""
var overlay_path_enabled: bool = false
var show_placement_grid: bool = false  # Show buildable/unbuildable overlay when previewing
var current_resources: Dictionary = {}  # For cost affordability checks
var active_synergies: Array = []  # Cached active tower synergies
var preview_synergies: Array = []  # Synergies that would activate with current preview
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
const TRAIL_SPAWN_INTERVAL := 0.03
const MAX_PARTICLES := 200  # Performance limit

# Combo visualization state
var _combo_count: int = 0
var _combo_pulse_time: float = 0.0
var _combo_ring_radius: float = 0.0

# Reduced motion setting (synced from main)
var reduced_motion: bool = false
var _aura_pulse_time: float = 0.0

# Animation state tracking
var _enemy_anim_state: Dictionary = {}  # enemy_id -> {anim_name, frame, timer, kind}
var _hit_flash_timers: Dictionary = {}  # enemy_id -> flash_time_remaining
var _damage_numbers: Array = []  # Array of damage number data
var _building_anim_state: Dictionary = {}  # building_index -> {anim_name, frame, timer}
var _combo_announcements: Array = []  # Combo milestone text popups
var _insufficient_pulses: Array = []  # Red pulse effects for insufficient resources
const HIT_FLASH_DURATION := 0.12
const DAMAGE_NUMBER_LIFETIME := 0.9
const DAMAGE_NUMBER_RISE_SPEED := 50.0
const COMBO_ANNOUNCEMENT_LIFETIME := 1.2
const INSUFFICIENT_PULSE_LIFETIME := 0.4

# Terrain autotiling configuration
const TERRAIN_PRIORITY := {
	"water": 0,
	"plains": 1,
	"forest": 2,
	"mountain": 3
}

# Direction offsets for neighbor checking
const NEIGHBOR_OFFSETS := {
	"n": Vector2i(0, -1),
	"ne": Vector2i(1, -1),
	"e": Vector2i(1, 0),
	"se": Vector2i(1, 1),
	"s": Vector2i(0, 1),
	"sw": Vector2i(-1, 1),
	"w": Vector2i(-1, 0),
	"nw": Vector2i(-1, -1)
}

# Terrain variant tiles for visual variety
const TERRAIN_VARIANTS := {
	"plains": ["tile_grass"],
	"forest": ["tile_evergrove_dense"],
	"mountain": ["tile_dirt"],
	"water": ["tile_water"]
}

# Animation configuration
const ENEMY_WALK_FPS := 8.0
const ENEMY_DEATH_FPS := 10.0

## Helper to add particle with limit check
func _add_particle(p: Dictionary) -> void:
	if _active_particles.size() < MAX_PARTICLES:
		_active_particles.append(p)

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
		"enemy_runner", "enemy_raider", "enemy_brute", "enemy_flyer",
		"enemy_shielder", "enemy_healer",
		"tile_grass", "tile_evergrove_dense", "tile_dirt", "tile_water"
	]
	for id in ids:
		var tex := asset_loader.get_texture(id)
		if tex != null:
			texture_cache[id] = tex

	# Preload animation frames
	if asset_loader.has_method("preload_animation_textures"):
		asset_loader.preload_animation_textures()

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
	current_resources = state.resources.duplicate(true)

	# Compute active tower synergies
	active_synergies = SimTowerSynergies.find_active_synergies(state)

	# Track enemy animations - register new, unregister removed
	_sync_enemy_animations(state.enemies)

	enemies = state.enemies.duplicate(true)
	active_pois = state.active_pois.duplicate(true)
	roaming_enemies = state.roaming_enemies.duplicate(true)
	time_of_day = state.time_of_day
	threat_level = state.threat_level
	activity_mode = state.activity_mode
	queue_redraw()

func set_preview_type(building_type: String) -> void:
	preview_type = building_type
	show_placement_grid = building_type != ""  # Show grid overlay when previewing
	# Compute preview synergies if placing a tower
	if building_type != "" and state_ref != null and building_type.begins_with("auto_") or building_type == "tower":
		preview_synergies = SimTowerSynergies.preview_synergies(state_ref, cursor_pos, building_type)
	else:
		preview_synergies = []
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

			# Draw terrain background with autotiling transitions
			var fill: Color = undiscovered_color
			if is_discovered:
				if use_sprites:
					_draw_terrain_with_transitions(rect, x, y, terrain_type)
				else:
					fill = _terrain_color(terrain_type)
					draw_rect(rect, fill, true)
			else:
				draw_rect(rect, fill, true)

			# Draw path overlay
			if overlay_path_enabled and dist_field.size() == map_w * map_h:
				var overlay_color: Color = overlay_reachable_color if dist_field[index] >= 0 else overlay_blocked_color
				draw_rect(rect, overlay_color, true)

			# Draw grid lines (optional)
			if show_grid_lines:
				draw_rect(rect, line_color, false, 1.0)

			# Draw structures
			if is_discovered and structures.has(index):
				var building_type: String = str(structures[index])
				var level: int = int(structure_levels.get(index, 1))
				if use_sprites:
					_draw_structure_sprite(rect, building_type, level, index)
				else:
					var symbol: String = _structure_char(building_type, level)
					var text_pos: Vector2 = rect.position + Vector2(6, cell_size.y - 10)
					draw_string(font, text_pos, symbol, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, structure_color)

	# Draw tower synergy connections
	_draw_tower_synergies()

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

	# Draw placement grid overlay (shows buildable/unbuildable tiles)
	if show_placement_grid and preview_type != "":
		_draw_placement_grid_overlay()

	# Draw building preview
	if preview_type != "":
		var preview_index: int = cursor_pos.y * map_w + cursor_pos.x
		var preview_rect: Rect2 = Rect2(origin + Vector2(cursor_pos.x * cell_size.x, cursor_pos.y * cell_size.y), cell_size)
		var preview_result: Dictionary = _get_preview_buildable_info(preview_index)
		var preview_buildable: bool = preview_result.get("buildable", false)
		var block_reason: String = preview_result.get("reason", "")

		# Draw range circle for towers BEFORE the building preview
		var tower_range: int = _get_building_range(preview_type)
		if tower_range > 0:
			_draw_range_circle(cursor_pos, tower_range, preview_buildable)

		# Draw glow effect for valid placements
		if preview_buildable and not reduced_motion:
			var pulse := (sin(_aura_pulse_time * 4.0) + 1.0) * 0.5
			var glow_alpha := 0.15 + pulse * 0.15
			var glow_color := Color(0.3, 0.9, 0.4, glow_alpha)
			draw_rect(preview_rect.grow(2.0 + pulse * 2.0), glow_color)

		# Draw blocked indicator with pulsing red border
		if not preview_buildable and not reduced_motion:
			var pulse := (sin(_aura_pulse_time * 5.0) + 1.0) * 0.5
			var border_color := Color(0.9, 0.3, 0.2, 0.5 + pulse * 0.3)
			draw_rect(preview_rect, border_color, false, 2.0)

		if use_sprites:
			var sprite_id := asset_loader.get_building_sprite_id(preview_type)
			var tex := _get_texture(sprite_id)
			if tex != null:
				var mod_color := Color(1, 1, 1, 0.7) if preview_buildable else Color(1, 0.4, 0.4, 0.5)
				_draw_centered_texture(preview_rect, tex, mod_color)
		else:
			var preview_symbol: String = _structure_char(preview_type, 1).to_lower()
			var preview_color_local: Color = preview_color if preview_buildable else preview_blocked_color
			var preview_text_pos: Vector2 = preview_rect.position + Vector2(6, cell_size.y - 10)
			var preview_draw: String = preview_symbol if preview_buildable else "x"
			draw_string(font, preview_text_pos, preview_draw, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, preview_color_local)

		# Draw enhanced tooltip with cost info or block reason
		_draw_preview_tooltip(preview_rect, preview_buildable, block_reason)

		# Draw preview synergies (potential synergies if tower is placed here)
		if preview_buildable:
			_draw_preview_synergies()

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

			# Try to get animated frame if animation is registered
			var frame_tex: Texture2D = null
			if _enemy_anim_state.has(enemy_id):
				var anim_state: Dictionary = _enemy_anim_state[enemy_id]
				var anim_type: String = anim_state.get("anim_type", "walk")
				var frame: int = anim_state.get("frame", 0)
				var anim_id := asset_loader.get_enemy_animation_id(kind, anim_type)
				if not anim_id.is_empty():
					frame_tex = asset_loader.get_animation_frame(anim_id, frame)

			var tex: Texture2D = frame_tex if frame_tex != null else _get_texture(sprite_id)
			if tex != null:
				# Use enhanced enemy sprite drawing with backdrop and outline
				_draw_enemy_sprite(enemy_rect, tex, kind, Color.WHITE, enemy_id)

				# Draw hit flash overlay
				if _hit_flash_timers.has(enemy_id):
					var flash_alpha: float = _hit_flash_timers[enemy_id] / HIT_FLASH_DURATION
					var flash_color := Color(1.0, 1.0, 1.0, flash_alpha * 0.7)
					draw_rect(enemy_rect.grow(-4.0), flash_color, true)
			else:
				# Fallback to glyph with background
				_draw_enemy_glyph(enemy_rect, kind)
		else:
			_draw_enemy_glyph(enemy_rect, kind)

		# Draw HP text
		var hp_text: String = str(enemy.get("hp", 0))
		draw_string(font, enemy_rect.position + Vector2(22, 16), hp_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 4, enemy_color)

		# Draw word initial
		var word: String = str(enemy.get("word", ""))
		if word != "":
			var initial: String = word.substr(0, 1)
			draw_string(font, enemy_rect.position + Vector2(6, 16), initial, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 6, enemy_color)

	# Draw roaming enemies (semi-transparent, wandering)
	for entity in roaming_enemies:
		if typeof(entity) != TYPE_DICTIONARY:
			continue
		var pos: Vector2i = entity.get("pos", Vector2i.ZERO)
		if not SimMap.in_bounds(pos.x, pos.y, map_w, map_h):
			continue
		var roam_rect: Rect2 = Rect2(origin + Vector2(pos.x * cell_size.x, pos.y * cell_size.y), cell_size)
		var kind: String = str(entity.get("kind", "raider"))

		# Draw with pulsing effect for wandering enemies
		var pulse: float = (sin(Time.get_ticks_msec() * 0.003) + 1.0) * 0.15
		var pulse_alpha: float = 0.6 + pulse * 0.3

		if use_sprites:
			var sprite_id := asset_loader.get_enemy_sprite_id(kind)
			var tex := _get_texture(sprite_id)
			if tex != null:
				# Use enhanced enemy sprite with pulsing alpha
				var pulse_mod := Color(1.0, 1.0, 1.0, pulse_alpha)
				_draw_enemy_sprite(roam_rect, tex, kind, pulse_mod)
			else:
				_draw_enemy_glyph(roam_rect, kind)
		else:
			_draw_enemy_glyph(roam_rect, kind)

		# Draw "?" to indicate not yet engaged
		var question_color := Color(0.9, 0.8, 0.4, pulse_alpha)
		draw_string(font, roam_rect.position + Vector2(22, 16), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 4, question_color)

	# Draw base with state-based sprite
	var base_rect: Rect2 = Rect2(origin + Vector2(base_pos.x * cell_size.x, base_pos.y * cell_size.y), cell_size)
	var castle_center: Vector2 = base_rect.position + base_rect.size * 0.5
	var castle_tier: int = _get_castle_tier()

	# Draw tier-based decorative elements behind castle
	if castle_tier >= 1 and not reduced_motion:
		var tier_color: Color
		var tier_radius: float
		if castle_tier >= 2:
			# Fortress: golden rotating glow
			tier_color = Color(1.0, 0.85, 0.4, 0.35)
			tier_radius = 32.0
			var rotation: float = Time.get_ticks_msec() * 0.001
			for i in range(4):
				var angle: float = rotation + (float(i) / 4.0) * TAU
				var offset: Vector2 = Vector2(cos(angle), sin(angle)) * 8.0
				draw_arc(castle_center + offset, tier_radius, 0.0, TAU, 16, tier_color, 1.5)
		else:
			# Improved: subtle silver glow
			tier_color = Color(0.7, 0.8, 1.0, 0.25)
			tier_radius = 26.0
			draw_arc(castle_center, tier_radius, 0.0, TAU, 16, tier_color, 1.0)

	# Draw tier badge corners for upgraded castles
	if castle_tier >= 1:
		var badge_color: Color = Color(1.0, 0.85, 0.4, 0.8) if castle_tier >= 2 else Color(0.7, 0.8, 1.0, 0.6)
		var badge_size: float = 4.0 if castle_tier >= 2 else 3.0
		# Draw corner dots
		draw_rect(Rect2(base_rect.position - Vector2(2, 2), Vector2(badge_size, badge_size)), badge_color, true)
		draw_rect(Rect2(base_rect.position + Vector2(base_rect.size.x - badge_size + 2, -2), Vector2(badge_size, badge_size)), badge_color, true)

	if use_sprites:
		var castle_tex := _get_castle_texture()
		var castle_tint := _get_castle_tint()
		if castle_tex != null:
			_draw_centered_texture(base_rect.grow(4.0), castle_tex, castle_tint)
		else:
			draw_rect(base_rect.grow(-4.0), base_color, true)
	else:
		draw_rect(base_rect.grow(-4.0), base_color, true)

	# Draw combo indicator ring around castle
	if _combo_count >= 3 and not reduced_motion:
		var combo_tier: int = mini(_combo_count / 5, 3)  # Tiers at 5, 10, 15+
		var ring_color: Color
		match combo_tier:
			0:
				ring_color = Color(0.9, 0.8, 0.3, 0.6)  # Yellow
			1:
				ring_color = Color(1.0, 0.6, 0.2, 0.7)  # Orange
			2:
				ring_color = Color(0.9, 0.3, 0.9, 0.8)  # Purple
			_:
				ring_color = Color(0.3, 0.9, 1.0, 0.9)  # Cyan (legendary)

		# Pulsing ring
		var pulse: float = sin(Time.get_ticks_msec() * 0.006) * 0.15 + 0.85
		var base_radius: float = 28.0 + float(combo_tier) * 4.0
		draw_arc(castle_center, base_radius * pulse, 0.0, TAU, 24, ring_color, 2.0)

		# Expanding pulse ring on combo milestone
		if _combo_pulse_time > 0.0:
			var pulse_alpha: float = _combo_pulse_time / 0.4
			var pulse_color: Color = ring_color
			pulse_color.a = pulse_alpha * 0.5
			draw_arc(castle_center, _combo_ring_radius, 0.0, TAU, 24, pulse_color, 1.5)

	# Draw time-of-day overlay (night darkening)
	if time_of_day > 0.7 or time_of_day < 0.2:
		var night_alpha: float = 0.0
		if time_of_day > 0.7:
			night_alpha = (time_of_day - 0.7) / 0.3 * 0.3  # Fade in to 30%
		else:
			night_alpha = (0.2 - time_of_day) / 0.2 * 0.3  # Fade out from 30%
		var night_overlay: Color = Color(0.05, 0.05, 0.15, night_alpha)
		var map_rect: Rect2 = Rect2(origin, Vector2(map_w * cell_size.x, map_h * cell_size.y))
		draw_rect(map_rect, night_overlay, true)

	# Draw threat level indicator bar (top of map)
	_draw_threat_bar()

	# Draw activity mode indicator
	_draw_activity_mode()

	# Draw cursor
	var cursor_rect: Rect2 = Rect2(origin + Vector2(cursor_pos.x * cell_size.x, cursor_pos.y * cell_size.y), cell_size)
	draw_rect(cursor_rect.grow(-2.0), cursor_color, false, 2.0)

	# Draw particles on top
	_draw_particles()

	# Draw damage numbers above everything
	_draw_damage_numbers()

	# Draw combo announcements (big text for milestones)
	_draw_combo_announcements()

	# Draw insufficient resource pulses
	_draw_insufficient_pulses()

func _process(delta: float) -> void:
	update_particles(delta)
	_update_animations(delta)
	_update_hit_flashes(delta)
	_update_damage_numbers(delta)
	_update_combo_announcements(delta)
	_update_insufficient_pulses(delta)
	_aura_pulse_time += delta

func _draw_centered_texture(rect: Rect2, tex: Texture2D, mod_color: Color = Color.WHITE) -> void:
	var tex_size := tex.get_size()
	var scale_factor: float = minf(rect.size.x / tex_size.x, rect.size.y / tex_size.y) * 0.95
	var scaled_size: Vector2 = tex_size * scale_factor
	var offset: Vector2 = (rect.size - scaled_size) * 0.5
	var dest_rect := Rect2(rect.position + offset, scaled_size)
	draw_texture_rect(tex, dest_rect, false, mod_color)

## Draw enemy sprite with enhanced visibility (shadow + outline)
## enemy_id is optional - pass -1 to skip procedural animation
func _draw_enemy_sprite(rect: Rect2, tex: Texture2D, kind: String, mod_color: Color = Color.WHITE, enemy_id: int = -1) -> void:
	var tex_size := tex.get_size()
	var scale_factor: float = minf(rect.size.x / tex_size.x, rect.size.y / tex_size.y) * 0.95
	var scaled_size: Vector2 = tex_size * scale_factor
	var offset: Vector2 = (rect.size - scaled_size) * 0.5

	# Apply procedural animation if we have animation state
	var anim_offset := Vector2.ZERO
	var anim_scale := 1.0
	var anim_rotation := 0.0

	if enemy_id >= 0 and _enemy_anim_state.has(enemy_id) and not reduced_motion:
		var anim_state: Dictionary = _enemy_anim_state[enemy_id]
		var frame: int = anim_state.get("frame", 0)
		var frame_count: int = anim_state.get("frame_count", 4)
		var anim_type: String = anim_state.get("anim_type", "walk")
		var phase: float = float(frame) / float(max(1, frame_count))

		if anim_type == "walk":
			# Bobbing motion - sine wave based on frame
			anim_offset.y = sin(phase * TAU) * 2.5
			# Subtle lean - simulates stepping motion
			anim_rotation = sin(phase * TAU) * 0.08
			# Slight scale pulse
			anim_scale = 1.0 + sin(phase * TAU * 2.0) * 0.03
		elif anim_type == "death":
			# Death animation - sink and fade
			var death_progress := phase
			anim_offset.y = death_progress * 8.0  # Sink down
			anim_scale = 1.0 - death_progress * 0.4  # Shrink
			anim_rotation = death_progress * 0.3  # Tilt
			mod_color.a *= (1.0 - death_progress * 0.7)  # Fade

	# Apply animation transforms
	scaled_size *= anim_scale
	offset = (rect.size - scaled_size) * 0.5 + anim_offset
	var dest_rect := Rect2(rect.position + offset, scaled_size)

	# Draw dark backdrop circle for contrast
	var center := rect.position + rect.size * 0.5 + anim_offset
	var backdrop_radius := scaled_size.x * 0.55

	# Draw subtle colored outline based on enemy type
	var outline_color: Color
	var is_elite := false
	match kind:
		"runner", "raider", "scout":
			outline_color = Color(0.9, 0.3, 0.2, 0.6)  # Red (fast)
		"brute", "armored":
			outline_color = Color(0.6, 0.3, 0.7, 0.6)  # Purple (tanky)
		"flyer":
			outline_color = Color(0.4, 0.6, 0.9, 0.6)  # Blue (aerial)
		"shielder":
			outline_color = Color(0.3, 0.7, 0.9, 0.6)  # Cyan (defensive)
		"healer":
			outline_color = Color(0.3, 0.8, 0.4, 0.6)  # Green (support)
		"boss_warlord", "boss_mage":
			outline_color = Color(1.0, 0.7, 0.2, 0.9)  # Gold (boss)
			is_elite = true
		_:
			outline_color = Color(0.8, 0.3, 0.3, 0.5)  # Default red

	# Draw pulsing outer aura for elite/boss enemies
	if not reduced_motion and is_elite:
		var pulse := (sin(_aura_pulse_time * 3.0) + 1.0) * 0.5  # 0 to 1
		var aura_alpha := 0.15 + pulse * 0.2
		var aura_radius := backdrop_radius + 4.0 + pulse * 3.0
		var aura_color := outline_color
		aura_color.a = aura_alpha
		draw_circle(center, aura_radius, aura_color)

	# Draw backdrop
	draw_circle(center, backdrop_radius, Color(0.08, 0.08, 0.12, 0.85))

	# Draw type indicator ring
	draw_arc(center, backdrop_radius + 1.5, 0.0, TAU, 16, outline_color, 2.0)

	# Draw the sprite with rotation if needed
	if abs(anim_rotation) > 0.001:
		# For rotation, we need to use draw_set_transform
		var sprite_center := dest_rect.position + dest_rect.size * 0.5
		draw_set_transform(sprite_center, anim_rotation, Vector2.ONE)
		var rotated_rect := Rect2(-dest_rect.size * 0.5, dest_rect.size)
		draw_texture_rect(tex, rotated_rect, false, mod_color)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)  # Reset transform
	else:
		draw_texture_rect(tex, dest_rect, false, mod_color)

func _draw_tiled_texture(rect: Rect2, tex: Texture2D) -> void:
	# Draw texture scaled to fit cell
	draw_texture_rect(tex, rect, false)

## Draw enemy glyph fallback with backdrop for visibility
func _draw_enemy_glyph(rect: Rect2, kind: String) -> void:
	var center := rect.position + rect.size * 0.5
	var backdrop_radius := rect.size.x * 0.4

	# Draw dark backdrop circle
	draw_circle(center, backdrop_radius, Color(0.08, 0.08, 0.12, 0.85))

	# Get outline color based on enemy type
	var outline_color: Color
	match kind:
		"runner", "raider", "scout":
			outline_color = Color(0.9, 0.3, 0.2, 0.6)
		"brute", "armored":
			outline_color = Color(0.5, 0.4, 0.6, 0.6)
		"flyer":
			outline_color = Color(0.6, 0.3, 0.7, 0.6)
		"shielder":
			outline_color = Color(0.3, 0.5, 0.7, 0.6)
		"healer":
			outline_color = Color(0.3, 0.7, 0.4, 0.6)
		"boss_warlord", "boss_mage":
			outline_color = Color(1.0, 0.7, 0.2, 0.8)
		_:
			outline_color = Color(0.8, 0.3, 0.3, 0.5)

	draw_arc(center, backdrop_radius + 1.5, 0.0, TAU, 16, outline_color, 2.0)

	# Draw glyph
	var glyph: String = SimEnemies.enemy_glyph(kind)
	var text_pos: Vector2 = rect.position + Vector2(rect.size.x * 0.3, rect.size.y * 0.65)
	draw_string(font, text_pos, glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, enemy_color)

func _draw_structure_sprite(rect: Rect2, building_type: String, level: int, building_index: int = -1) -> void:
	var sprite_id := asset_loader.get_building_sprite_id(building_type)
	# For towers, try to get level-specific sprite
	if building_type == "tower" and level > 1:
		var leveled_id := "bld_tower_slow" if level >= 2 else sprite_id
		sprite_id = leveled_id

	var tex := _get_texture(sprite_id)
	if tex == null:
		# Fallback to text
		var symbol: String = _structure_char(building_type, level)
		var text_pos: Vector2 = rect.position + Vector2(6, cell_size.y - 10)
		draw_string(font, text_pos, symbol, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, structure_color)
		return

	# Check for animation state
	var anim_offset := Vector2.ZERO
	var anim_scale := 1.0
	var mod_color := Color.WHITE
	var draw_muzzle_flash := false

	if building_index >= 0 and _building_anim_state.has(building_index) and not reduced_motion:
		var anim_state: Dictionary = _building_anim_state[building_index]
		var anim_type: String = anim_state.get("anim_type", "")
		var frame: int = anim_state.get("frame", 0)
		var frame_count: int = anim_state.get("frame_count", 3)
		var phase: float = float(frame) / float(max(1, frame_count))

		match anim_type:
			"fire":
				# Tower firing animation - recoil and flash
				if frame == 0:
					# Recoil backwards (up for top-down view)
					anim_offset.y = -3.0
					anim_scale = 1.05
					draw_muzzle_flash = true
				elif frame == 1:
					anim_offset.y = -1.0
					anim_scale = 1.02
				else:
					# Return to normal
					anim_offset.y = 0.0
					anim_scale = 1.0
			"pulse":
				# Slow tower pulse effect
				var pulse := sin(phase * TAU)
				anim_scale = 1.0 + pulse * 0.08
				# Glow effect
				mod_color = Color(1.0 + pulse * 0.15, 1.0 + pulse * 0.1, 1.2 + pulse * 0.2, 1.0)
			"construct":
				# Construction animation - rise up and fade in
				var rise := (1.0 - phase) * 6.0
				anim_offset.y = rise
				mod_color.a = 0.5 + phase * 0.5
				anim_scale = 0.85 + phase * 0.15

	# Draw with animation transforms
	var tex_size := tex.get_size()
	var scale_factor: float = minf(rect.size.x / tex_size.x, rect.size.y / tex_size.y) * 0.95 * anim_scale
	var scaled_size: Vector2 = tex_size * scale_factor
	var offset: Vector2 = (rect.size - scaled_size) * 0.5 + anim_offset
	var dest_rect := Rect2(rect.position + offset, scaled_size)
	draw_texture_rect(tex, dest_rect, false, mod_color)

	# Draw muzzle flash effect for tower firing
	if draw_muzzle_flash and building_type == "tower":
		var flash_center := rect.position + rect.size * 0.5 + Vector2(0, -rect.size.y * 0.35)
		var flash_radius: float = rect.size.x * 0.25
		draw_circle(flash_center, flash_radius, Color(1.0, 0.95, 0.6, 0.9))
		draw_circle(flash_center, flash_radius * 0.5, Color(1.0, 1.0, 0.9, 1.0))

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

## Get terrain type at grid position, or center terrain if out of bounds
func _terrain_at_pos(x: int, y: int, center_terrain: String) -> String:
	if x < 0 or x >= map_w or y < 0 or y >= map_h:
		return center_terrain
	var idx := y * map_w + x
	return _terrain_at(idx)

## Get neighbor terrains for a tile position
func _get_neighbor_terrains(x: int, y: int, center_terrain: String) -> Dictionary:
	var neighbors := {}
	for dir in NEIGHBOR_OFFSETS:
		var offset: Vector2i = NEIGHBOR_OFFSETS[dir]
		neighbors[dir] = _terrain_at_pos(x + offset.x, y + offset.y, center_terrain)
	return neighbors

## Get the canonical terrain pair key (lower priority first)
func _get_terrain_pair_key(terrain_a: String, terrain_b: String) -> String:
	var priority_a: int = TERRAIN_PRIORITY.get(terrain_a, 1)
	var priority_b: int = TERRAIN_PRIORITY.get(terrain_b, 1)
	if priority_a <= priority_b:
		return "%s_%s" % [terrain_a, terrain_b]
	return "%s_%s" % [terrain_b, terrain_a]

## Convert terrain name to short form for tile IDs
func _terrain_short_name(terrain_name: String) -> String:
	match terrain_name:
		"plains": return "grass"
		"forest": return "forest"
		"mountain": return "mountain"
		"water": return "water"
		_: return "grass"

## Get transition tiles needed for a tile based on neighbors
func _get_transition_tiles(x: int, y: int, center_terrain: String) -> Array:
	var result := []
	var neighbors := _get_neighbor_terrains(x, y, center_terrain)
	var center_priority: int = TERRAIN_PRIORITY.get(center_terrain, 1)

	# Check each cardinal direction for higher priority terrain
	var n_terrain: String = neighbors.get("n", center_terrain)
	var s_terrain: String = neighbors.get("s", center_terrain)
	var e_terrain: String = neighbors.get("e", center_terrain)
	var w_terrain: String = neighbors.get("w", center_terrain)
	var ne_terrain: String = neighbors.get("ne", center_terrain)
	var nw_terrain: String = neighbors.get("nw", center_terrain)
	var se_terrain: String = neighbors.get("se", center_terrain)
	var sw_terrain: String = neighbors.get("sw", center_terrain)

	var n_priority: int = TERRAIN_PRIORITY.get(n_terrain, 1)
	var s_priority: int = TERRAIN_PRIORITY.get(s_terrain, 1)
	var e_priority: int = TERRAIN_PRIORITY.get(e_terrain, 1)
	var w_priority: int = TERRAIN_PRIORITY.get(w_terrain, 1)

	var center_short := _terrain_short_name(center_terrain)

	# Check for edge transitions (cardinal neighbors with higher priority)
	# North edge
	if n_priority > center_priority and n_terrain == e_terrain and n_terrain == w_terrain:
		# Both N and E and W are same higher terrain - just draw N edge
		var other_short := _terrain_short_name(n_terrain)
		result.append("tile_%s_%s_n" % [center_short, other_short])
	elif n_priority > center_priority and e_priority > center_priority and n_terrain == e_terrain:
		# NE corner (both N and E are same higher terrain)
		var other_short := _terrain_short_name(n_terrain)
		result.append("tile_%s_%s_ne" % [center_short, other_short])
	elif n_priority > center_priority and w_priority > center_priority and n_terrain == w_terrain:
		# NW corner
		var other_short := _terrain_short_name(n_terrain)
		result.append("tile_%s_%s_nw" % [center_short, other_short])
	elif n_priority > center_priority:
		var other_short := _terrain_short_name(n_terrain)
		result.append("tile_%s_%s_n" % [center_short, other_short])

	# South edge (only if not already covered by corner)
	if s_priority > center_priority and n_priority <= center_priority:
		if s_terrain == e_terrain and e_priority > center_priority:
			var other_short := _terrain_short_name(s_terrain)
			result.append("tile_%s_%s_se" % [center_short, other_short])
		elif s_terrain == w_terrain and w_priority > center_priority:
			var other_short := _terrain_short_name(s_terrain)
			result.append("tile_%s_%s_sw" % [center_short, other_short])
		else:
			var other_short := _terrain_short_name(s_terrain)
			result.append("tile_%s_%s_s" % [center_short, other_short])

	# East edge (only if not already part of a corner)
	if e_priority > center_priority and n_terrain != e_terrain and s_terrain != e_terrain:
		var other_short := _terrain_short_name(e_terrain)
		result.append("tile_%s_%s_e" % [center_short, other_short])

	# West edge
	if w_priority > center_priority and n_terrain != w_terrain and s_terrain != w_terrain:
		var other_short := _terrain_short_name(w_terrain)
		result.append("tile_%s_%s_w" % [center_short, other_short])

	# Inner corners (diagonal-only transitions)
	var ne_priority: int = TERRAIN_PRIORITY.get(ne_terrain, 1)
	var nw_priority: int = TERRAIN_PRIORITY.get(nw_terrain, 1)
	var se_priority: int = TERRAIN_PRIORITY.get(se_terrain, 1)
	var sw_priority: int = TERRAIN_PRIORITY.get(sw_terrain, 1)

	# NE inner corner: NE is different but N and E are same as center
	if ne_priority > center_priority and n_priority <= center_priority and e_priority <= center_priority:
		var other_short := _terrain_short_name(ne_terrain)
		result.append("tile_%s_%s_inner_ne" % [center_short, other_short])

	# NW inner corner
	if nw_priority > center_priority and n_priority <= center_priority and w_priority <= center_priority:
		var other_short := _terrain_short_name(nw_terrain)
		result.append("tile_%s_%s_inner_nw" % [center_short, other_short])

	# SE inner corner
	if se_priority > center_priority and s_priority <= center_priority and e_priority <= center_priority:
		var other_short := _terrain_short_name(se_terrain)
		result.append("tile_%s_%s_inner_se" % [center_short, other_short])

	# SW inner corner
	if sw_priority > center_priority and s_priority <= center_priority and w_priority <= center_priority:
		var other_short := _terrain_short_name(sw_terrain)
		result.append("tile_%s_%s_inner_sw" % [center_short, other_short])

	return result

## Draw terrain with transition blending
func _draw_terrain_with_transitions(rect: Rect2, x: int, y: int, center_terrain: String) -> void:
	# Draw base terrain tile
	var base_tex := _get_terrain_texture(center_terrain)
	if base_tex != null:
		_draw_tiled_texture(rect, base_tex)
	else:
		draw_rect(rect, _terrain_color(center_terrain), true)

	# Draw transition overlays
	var transitions := _get_transition_tiles(x, y, center_terrain)
	for tile_id in transitions:
		var trans_tex := _get_texture(tile_id)
		if trans_tex != null:
			_draw_tiled_texture(rect, trans_tex)

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
	return _get_preview_buildable_info(index).get("buildable", false)

func _get_preview_buildable_info(index: int) -> Dictionary:
	if index < 0 or index >= map_w * map_h:
		return {"buildable": false, "reason": "Out of bounds"}
	var pos: Vector2i = Vector2i(index % map_w, int(index / map_w))
	if pos == base_pos:
		return {"buildable": false, "reason": "Castle"}
	if not discovered.has(index):
		return {"buildable": false, "reason": "Unexplored"}
	if structures.has(index):
		return {"buildable": false, "reason": "Occupied"}
	if _terrain_at(index) == SimMap.TERRAIN_WATER:
		return {"buildable": false, "reason": "Water"}
	return {"buildable": true, "reason": ""}

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
	var max_hp: int = 10 + SimUpgrades.get_castle_health_bonus(state_ref)

	# Damaged state: HP <= 30% of max
	if hp <= int(max_hp * 0.3):
		var damaged_tex := _get_texture("castle_damaged")
		if damaged_tex != null:
			return damaged_tex

	# Default/healthy castle
	return _get_texture("bld_castle")

## Get castle upgrade tier (0=basic, 1=improved, 2=fortress)
func _get_castle_tier() -> int:
	if state_ref == null:
		return 0
	var kingdom_upgrades: Array = state_ref.purchased_kingdom_upgrades
	var upgrade_count: int = kingdom_upgrades.size()
	if upgrade_count >= 6:
		return 2  # Fortress
	elif upgrade_count >= 3:
		return 1  # Improved
	return 0  # Basic

## Get castle color tint based on HP and upgrades
func _get_castle_tint() -> Color:
	if state_ref == null:
		return Color.WHITE

	var hp: int = state_ref.hp
	var max_hp: int = 10 + SimUpgrades.get_castle_health_bonus(state_ref)
	var hp_percent: float = float(hp) / float(max_hp) if max_hp > 0 else 1.0

	# Critical HP: red tint
	if hp_percent <= 0.25:
		return Color(1.0, 0.7, 0.7, 1.0)
	# Low HP: orange tint
	elif hp_percent <= 0.5:
		return Color(1.0, 0.9, 0.8, 1.0)

	# Check for upgrades that enhance the castle
	var tier: int = _get_castle_tier()

	# Fortress tier: golden glow
	if tier >= 2:
		return Color(1.15, 1.1, 0.9, 1.0)
	# Improved tier: blue-silver glow
	elif tier >= 1:
		return Color(1.0, 1.0, 1.05, 1.0)

	return Color.WHITE

## Set combo count for visualization
func set_combo(count: int) -> void:
	if count > _combo_count and count >= 3:
		# New combo milestone - pulse effect
		_combo_pulse_time = 0.4
		_combo_ring_radius = 0.0
	_combo_count = count
	if count == 0:
		_combo_pulse_time = 0.0
		_combo_ring_radius = 0.0
	queue_redraw()

## Spawn projectile from castle to enemy position
func spawn_projectile(enemy_pos: Vector2i, is_power: bool = false) -> void:
	if reduced_motion:
		return
	var start_pos: Vector2 = origin + Vector2(base_pos.x * cell_size.x, base_pos.y * cell_size.y) + cell_size * 0.5
	var end_pos: Vector2 = origin + Vector2(enemy_pos.x * cell_size.x, enemy_pos.y * cell_size.y) + cell_size * 0.5
	var direction: Vector2 = (end_pos - start_pos).normalized()
	var distance: float = start_pos.distance_to(end_pos)

	# Calculate speed so projectile reaches target in ~0.25 seconds
	var flight_time: float = 0.25
	var speed: float = distance / flight_time
	speed = maxf(speed, 200.0)  # Minimum speed

	var color: Color = Color(1.0, 0.85, 0.3, 1.0) if is_power else Color(0.85, 0.65, 0.25, 1.0)
	var arrow_length: float = 16.0 if is_power else 12.0

	_add_particle({
		"type": "arrow",
		"pos": start_pos,
		"target": end_pos,
		"velocity": direction * speed,
		"direction": direction,
		"color": color,
		"arrow_length": arrow_length,
		"lifetime": flight_time + 0.1,
		"trail_timer": 0.0,
		"is_power": is_power
	})
	queue_redraw()

## Spawn hit spark particles at position
func spawn_hit_sparks(world_pos: Vector2, is_power: bool = false) -> void:
	if reduced_motion:
		return
	var count: int = 8 if is_power else 5
	var base_color: Color = Color(1.0, 0.95, 0.5, 1.0) if is_power else Color(0.95, 0.85, 0.4, 1.0)

	for i in range(count):
		var angle: float = randf() * TAU
		var speed: float = PARTICLE_SPEED * (0.4 + randf() * 0.6) * (1.3 if is_power else 1.0)
		var size: Vector2 = Vector2(5, 2) if i % 2 == 0 else Vector2(3, 3)

		_add_particle({
			"type": "spark",
			"pos": world_pos,
			"velocity": Vector2(cos(angle), sin(angle)) * speed,
			"color": base_color,
			"size": size,
			"lifetime": PARTICLE_LIFETIME
		})
	queue_redraw()

## Spawn enemy defeat burst at position
func spawn_defeat_burst(enemy_pos: Vector2i, is_boss: bool = false) -> void:
	if reduced_motion:
		return
	var world_pos: Vector2 = origin + Vector2(enemy_pos.x * cell_size.x, enemy_pos.y * cell_size.y) + cell_size * 0.5
	var ring_count: int = 16 if is_boss else 10
	var base_color: Color = Color(0.9, 0.4, 0.9, 1.0) if is_boss else Color(0.95, 0.6, 0.3, 1.0)
	var accent_color: Color = Color(1.0, 0.7, 1.0, 1.0) if is_boss else Color(1.0, 0.85, 0.5, 1.0)

	# Primary expanding ring effect
	for i in range(ring_count):
		var angle: float = (float(i) / float(ring_count)) * TAU
		var speed: float = PARTICLE_SPEED * (1.4 if is_boss else 1.0)

		_add_particle({
			"type": "defeat",
			"pos": world_pos,
			"velocity": Vector2(cos(angle), sin(angle)) * speed,
			"color": base_color,
			"size": Vector2(6, 6) if is_boss else Vector2(4, 4),
			"lifetime": PARTICLE_LIFETIME * 1.3
		})

	# Secondary slower ring with accent color
	var inner_count: int = 8 if is_boss else 5
	for i in range(inner_count):
		var angle: float = (float(i) / float(inner_count)) * TAU + 0.3
		var speed: float = PARTICLE_SPEED * (0.7 if is_boss else 0.5)

		_add_particle({
			"type": "defeat",
			"pos": world_pos,
			"velocity": Vector2(cos(angle), sin(angle)) * speed,
			"color": accent_color,
			"size": Vector2(5, 5) if is_boss else Vector2(3, 3),
			"lifetime": PARTICLE_LIFETIME * 1.0
		})

	# Rising particles (gold coins / essence effect)
	var rise_count: int = 6 if is_boss else 3
	for i in range(rise_count):
		var x_offset: float = randf_range(-12, 12) if is_boss else randf_range(-8, 8)
		_add_particle({
			"type": "rise",
			"pos": world_pos + Vector2(x_offset, 0),
			"velocity": Vector2(randf_range(-15, 15), -80.0 - randf() * 40.0),
			"color": Color(1.0, 0.9, 0.4, 0.9),
			"size": Vector2(4, 4) if is_boss else Vector2(3, 3),
			"lifetime": PARTICLE_LIFETIME * 1.5
		})

	# Center flash
	_add_particle({
		"type": "flash",
		"pos": world_pos,
		"velocity": Vector2.ZERO,
		"color": Color(1.0, 1.0, 0.95, 1.0),
		"size": Vector2(22, 22) if is_boss else Vector2(14, 14),
		"lifetime": PARTICLE_LIFETIME * 0.5
	})

	# Boss gets extra dramatic outer ring
	if is_boss:
		for i in range(8):
			var angle: float = (float(i) / 8.0) * TAU + randf() * 0.2
			_add_particle({
				"type": "defeat",
				"pos": world_pos,
				"velocity": Vector2(cos(angle), sin(angle)) * PARTICLE_SPEED * 2.0,
				"color": Color(1.0, 0.5, 1.0, 0.7),
				"size": Vector2(8, 8),
				"lifetime": PARTICLE_LIFETIME * 0.8
			})

	queue_redraw()

## Spawn combo break effect
func spawn_combo_break() -> void:
	if reduced_motion:
		return
	var castle_pos: Vector2 = origin + Vector2(base_pos.x * cell_size.x, base_pos.y * cell_size.y) + cell_size * 0.5

	# Red particles dispersing outward
	for i in range(4):
		var angle: float = randf() * TAU
		var speed: float = PARTICLE_SPEED * 0.5

		_add_particle({
			"type": "combo_break",
			"pos": castle_pos + Vector2(randf_range(-10, 10), randf_range(-10, 10)),
			"velocity": Vector2(cos(angle), sin(angle)) * speed,
			"color": Color(1.0, 0.3, 0.3, 0.8),
			"size": Vector2(3, 3),
			"lifetime": PARTICLE_LIFETIME * 0.6
		})
	queue_redraw()

## Spawn damage flash at castle
func spawn_damage_flash() -> void:
	if reduced_motion:
		return
	var castle_pos: Vector2 = origin + Vector2(base_pos.x * cell_size.x, base_pos.y * cell_size.y) + cell_size * 0.5

	for i in range(6):
		var angle: float = randf() * TAU
		var speed: float = PARTICLE_SPEED * 0.6 * (0.3 + randf() * 0.7)

		_add_particle({
			"type": "damage",
			"pos": castle_pos,
			"velocity": Vector2(cos(angle), sin(angle)) * speed,
			"color": Color(1.0, 0.35, 0.25, 1.0),
			"size": Vector2(4, 4),
			"lifetime": PARTICLE_LIFETIME * 0.7
		})
	queue_redraw()

## Spawn construction dust effect at grid position
func spawn_build_effect(grid_pos: Vector2i) -> void:
	if reduced_motion:
		return
	var world_pos: Vector2 = origin + Vector2(grid_pos.x * cell_size.x, grid_pos.y * cell_size.y) + cell_size * 0.5

	# Rising dust particles
	for i in range(8):
		var x_offset: float = randf_range(-8, 8)
		_add_particle({
			"type": "rise",
			"pos": world_pos + Vector2(x_offset, 4),
			"velocity": Vector2(randf_range(-10, 10), -40.0 - randf() * 20.0),
			"color": Color(0.8, 0.7, 0.5, 0.8),
			"size": Vector2(3, 3),
			"lifetime": PARTICLE_LIFETIME * 0.6
		})

	# Sparks for "construction" feel
	for i in range(4):
		var angle: float = randf() * TAU
		var speed: float = PARTICLE_SPEED * 0.4
		_add_particle({
			"type": "spark",
			"pos": world_pos,
			"velocity": Vector2(cos(angle), sin(angle)) * speed,
			"color": Color(1.0, 0.9, 0.3, 1.0),
			"size": Vector2(2, 2),
			"lifetime": PARTICLE_LIFETIME * 0.4
		})
	queue_redraw()

## Spawn gold sparkle effect at castle for resource gains
func spawn_gold_sparkle() -> void:
	if reduced_motion:
		return
	var castle_pos: Vector2 = origin + Vector2(base_pos.x * cell_size.x, base_pos.y * cell_size.y) + cell_size * 0.5

	# Gold-colored rising particles
	for i in range(5):
		var x_offset: float = randf_range(-10, 10)
		_add_particle({
			"type": "rise",
			"pos": castle_pos + Vector2(x_offset, 0),
			"velocity": Vector2(randf_range(-5, 5), -35.0 - randf() * 15.0),
			"color": Color(1.0, 0.84, 0.0, 1.0),  # Gold color
			"size": Vector2(3, 3),
			"lifetime": PARTICLE_LIFETIME * 0.8
		})
	queue_redraw()

## Spawn healing sparkle effect at castle
func spawn_heal_sparkle() -> void:
	if reduced_motion:
		return
	var castle_pos: Vector2 = origin + Vector2(base_pos.x * cell_size.x, base_pos.y * cell_size.y) + cell_size * 0.5

	# Green healing particles
	for i in range(6):
		var angle: float = randf() * TAU
		var speed: float = PARTICLE_SPEED * 0.3
		_add_particle({
			"type": "rise",
			"pos": castle_pos + Vector2(randf_range(-8, 8), randf_range(-8, 8)),
			"velocity": Vector2(cos(angle) * speed * 0.3, -30.0 - randf() * 20.0),
			"color": Color(0.2, 1.0, 0.4, 1.0),  # Green heal color
			"size": Vector2(4, 4),
			"lifetime": PARTICLE_LIFETIME * 0.6
		})
	queue_redraw()

## Spawn exploration reveal effect at grid position
func spawn_explore_reveal(grid_pos: Vector2i) -> void:
	if reduced_motion:
		return
	var world_pos: Vector2 = origin + Vector2(grid_pos.x * cell_size.x, grid_pos.y * cell_size.y) + cell_size * 0.5

	# Expanding reveal particles (light blue/cyan)
	for i in range(8):
		var angle: float = (float(i) / 8.0) * TAU
		var speed: float = PARTICLE_SPEED * 0.5
		_add_particle({
			"type": "spark",
			"pos": world_pos,
			"velocity": Vector2(cos(angle), sin(angle)) * speed,
			"color": Color(0.5, 0.8, 1.0, 0.9),  # Light blue
			"size": Vector2(3, 3),
			"lifetime": PARTICLE_LIFETIME * 0.5
		})

	# Center flash
	_add_particle({
		"type": "flash",
		"pos": world_pos,
		"velocity": Vector2.ZERO,
		"color": Color(0.8, 0.9, 1.0, 0.7),
		"size": Vector2(16, 16),
		"lifetime": PARTICLE_LIFETIME * 0.3
	})
	queue_redraw()

## Spawn enemy appear effect at grid position
func spawn_enemy_appear(grid_pos: Vector2i) -> void:
	if reduced_motion:
		return
	var world_pos: Vector2 = origin + Vector2(grid_pos.x * cell_size.x, grid_pos.y * cell_size.y) + cell_size * 0.5

	# Dark/red smoke particles rising
	for i in range(6):
		var x_offset: float = randf_range(-6, 6)
		_add_particle({
			"type": "rise",
			"pos": world_pos + Vector2(x_offset, 4),
			"velocity": Vector2(randf_range(-8, 8), -35.0 - randf() * 20.0),
			"color": Color(0.6, 0.2, 0.2, 0.7),  # Dark red
			"size": Vector2(4, 4),
			"lifetime": PARTICLE_LIFETIME * 0.5
		})

	# Quick flash at spawn point
	_add_particle({
		"type": "flash",
		"pos": world_pos,
		"velocity": Vector2.ZERO,
		"color": Color(1.0, 0.4, 0.3, 0.5),
		"size": Vector2(12, 12),
		"lifetime": PARTICLE_LIFETIME * 0.2
	})
	queue_redraw()

## Spawn wave start visual effect (screen edges pulse)
func spawn_wave_start_effect() -> void:
	if reduced_motion:
		return
	var castle_pos: Vector2 = origin + Vector2(base_pos.x * cell_size.x, base_pos.y * cell_size.y) + cell_size * 0.5

	# Ring of warning particles around map edges
	for i in range(12):
		var angle: float = (float(i) / 12.0) * TAU
		var dist: float = 60.0
		var spawn_pos: Vector2 = castle_pos + Vector2(cos(angle), sin(angle)) * dist
		_add_particle({
			"type": "spark",
			"pos": spawn_pos,
			"velocity": Vector2(cos(angle), sin(angle)) * PARTICLE_SPEED * 0.3,
			"color": Color(1.0, 0.5, 0.2, 0.8),  # Orange warning
			"size": Vector2(3, 3),
			"lifetime": PARTICLE_LIFETIME * 0.6
		})
	queue_redraw()

## Spawn victory celebration effect
func spawn_victory_effect() -> void:
	if reduced_motion:
		return
	var castle_pos: Vector2 = origin + Vector2(base_pos.x * cell_size.x, base_pos.y * cell_size.y) + cell_size * 0.5

	# Golden fireworks-like particles
	for wave_i in range(3):
		for i in range(16):
			var angle: float = (float(i) / 16.0) * TAU
			var speed: float = PARTICLE_SPEED * (0.6 + float(wave_i) * 0.2)
			var delay_offset: Vector2 = Vector2(randf_range(-5, 5), randf_range(-5, 5))
			_add_particle({
				"type": "spark",
				"pos": castle_pos + delay_offset,
				"velocity": Vector2(cos(angle), sin(angle)) * speed,
				"color": Color(1.0, 0.84, 0.0, 1.0),  # Gold
				"size": Vector2(4, 4),
				"lifetime": PARTICLE_LIFETIME * (0.8 + float(wave_i) * 0.3)
			})

	# Rising celebration particles
	for i in range(10):
		var x_offset: float = randf_range(-20, 20)
		_add_particle({
			"type": "rise",
			"pos": castle_pos + Vector2(x_offset, 0),
			"velocity": Vector2(randf_range(-15, 15), -60.0 - randf() * 30.0),
			"color": Color(0.8, 1.0, 0.5, 1.0),  # Light green
			"size": Vector2(5, 5),
			"lifetime": PARTICLE_LIFETIME * 1.2
		})
	queue_redraw()

## Spawn game over/defeat effect
func spawn_defeat_effect() -> void:
	if reduced_motion:
		return
	var castle_pos: Vector2 = origin + Vector2(base_pos.x * cell_size.x, base_pos.y * cell_size.y) + cell_size * 0.5

	# Dark, falling debris particles
	for i in range(12):
		var angle: float = randf() * TAU
		var speed: float = PARTICLE_SPEED * 0.5
		_add_particle({
			"type": "defeat",
			"pos": castle_pos + Vector2(randf_range(-10, 10), randf_range(-10, 10)),
			"velocity": Vector2(cos(angle) * speed, sin(angle) * speed + 20),
			"color": Color(0.4, 0.3, 0.3, 0.9),  # Dark gray
			"size": Vector2(5, 5),
			"lifetime": PARTICLE_LIFETIME * 0.8
		})

	# Red flash
	_add_particle({
		"type": "flash",
		"pos": castle_pos,
		"velocity": Vector2.ZERO,
		"color": Color(0.8, 0.2, 0.1, 0.6),
		"size": Vector2(40, 40),
		"lifetime": PARTICLE_LIFETIME * 0.4
	})
	queue_redraw()

## Spawn upgrade purchase effect at castle
func spawn_upgrade_effect() -> void:
	if reduced_motion:
		return
	var castle_pos: Vector2 = origin + Vector2(base_pos.x * cell_size.x, base_pos.y * cell_size.y) + cell_size * 0.5

	# Purple/magical upgrade particles
	for i in range(8):
		var angle: float = (float(i) / 8.0) * TAU
		var speed: float = PARTICLE_SPEED * 0.4
		_add_particle({
			"type": "spark",
			"pos": castle_pos,
			"velocity": Vector2(cos(angle), sin(angle)) * speed,
			"color": Color(0.7, 0.4, 1.0, 0.9),  # Purple
			"size": Vector2(3, 3),
			"lifetime": PARTICLE_LIFETIME * 0.5
		})

	# Rising enhancement sparkles
	for i in range(5):
		var x_offset: float = randf_range(-8, 8)
		_add_particle({
			"type": "rise",
			"pos": castle_pos + Vector2(x_offset, 0),
			"velocity": Vector2(randf_range(-5, 5), -45.0 - randf() * 20.0),
			"color": Color(0.9, 0.7, 1.0, 1.0),  # Light purple
			"size": Vector2(3, 3),
			"lifetime": PARTICLE_LIFETIME * 0.7
		})
	queue_redraw()

## Spawn dawn/wave complete celebration effect
func spawn_dawn_effect() -> void:
	if reduced_motion:
		return
	var castle_pos: Vector2 = origin + Vector2(base_pos.x * cell_size.x, base_pos.y * cell_size.y) + cell_size * 0.5

	# Warm golden rays rising from edges
	for i in range(10):
		var x_offset: float = randf_range(-40, 40)
		_add_particle({
			"type": "rise",
			"pos": castle_pos + Vector2(x_offset, 20),
			"velocity": Vector2(randf_range(-5, 5), -50.0 - randf() * 25.0),
			"color": Color(1.0, 0.9, 0.6, 0.8),  # Warm gold/yellow
			"size": Vector2(4, 4),
			"lifetime": PARTICLE_LIFETIME * 1.0
		})

	# Soft ambient sparkles
	for i in range(8):
		var angle: float = randf() * TAU
		var dist: float = randf_range(20, 50)
		_add_particle({
			"type": "spark",
			"pos": castle_pos + Vector2(cos(angle), sin(angle)) * dist,
			"velocity": Vector2(randf_range(-10, 10), -20.0),
			"color": Color(1.0, 0.95, 0.7, 0.7),
			"size": Vector2(3, 3),
			"lifetime": PARTICLE_LIFETIME * 0.8
		})
	queue_redraw()

## Spawn boss appear dramatic effect
func spawn_boss_appear_effect() -> void:
	if reduced_motion:
		return
	var castle_pos: Vector2 = origin + Vector2(base_pos.x * cell_size.x, base_pos.y * cell_size.y) + cell_size * 0.5

	# Dark ominous particles from screen edges
	for i in range(16):
		var angle: float = (float(i) / 16.0) * TAU
		var dist: float = 70.0
		var spawn_pos: Vector2 = castle_pos + Vector2(cos(angle), sin(angle)) * dist
		_add_particle({
			"type": "spark",
			"pos": spawn_pos,
			"velocity": Vector2(-cos(angle), -sin(angle)) * PARTICLE_SPEED * 0.4,
			"color": Color(0.5, 0.2, 0.3, 0.9),  # Dark red/purple
			"size": Vector2(4, 4),
			"lifetime": PARTICLE_LIFETIME * 0.7
		})

	# Central warning flash
	_add_particle({
		"type": "flash",
		"pos": castle_pos,
		"velocity": Vector2.ZERO,
		"color": Color(0.8, 0.3, 0.2, 0.5),
		"size": Vector2(50, 50),
		"lifetime": PARTICLE_LIFETIME * 0.3
	})
	queue_redraw()

## Spawn POI discovery effect at grid position
func spawn_poi_effect(grid_pos: Vector2i) -> void:
	if reduced_motion:
		return
	var world_pos: Vector2 = origin + Vector2(grid_pos.x * cell_size.x, grid_pos.y * cell_size.y) + cell_size * 0.5

	# Mysterious glowing particles
	for i in range(8):
		var angle: float = (float(i) / 8.0) * TAU
		var speed: float = PARTICLE_SPEED * 0.35
		_add_particle({
			"type": "spark",
			"pos": world_pos,
			"velocity": Vector2(cos(angle), sin(angle)) * speed,
			"color": Color(0.4, 0.8, 1.0, 0.9),  # Cyan/teal
			"size": Vector2(3, 3),
			"lifetime": PARTICLE_LIFETIME * 0.6
		})

	# Rising mystery sparkles
	for i in range(4):
		var x_offset: float = randf_range(-6, 6)
		_add_particle({
			"type": "rise",
			"pos": world_pos + Vector2(x_offset, 0),
			"velocity": Vector2(randf_range(-8, 8), -35.0 - randf() * 15.0),
			"color": Color(0.6, 0.9, 1.0, 1.0),
			"size": Vector2(3, 3),
			"lifetime": PARTICLE_LIFETIME * 0.7
		})
	queue_redraw()

## Update particles - call from _process
func update_particles(delta: float) -> void:
	# Update combo pulse animation
	if _combo_pulse_time > 0.0:
		_combo_pulse_time -= delta
		_combo_ring_radius += delta * 80.0
		queue_redraw()

	if _active_particles.is_empty():
		return

	var needs_redraw: bool = false
	var trails_to_spawn: Array = []

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

		# Rising particles slow down and fade
		if ptype == "rise":
			vel.y *= 0.95  # Decelerate upward movement
			vel.x *= 0.98  # Slight horizontal drag
			p["velocity"] = vel

		# Check projectile hit and spawn trails
		if ptype == "projectile":
			var target: Vector2 = p.get("target", Vector2.ZERO)
			if p["pos"].distance_to(target) < 8.0:
				var is_power: bool = p.get("is_power", false)
				spawn_hit_sparks(target, is_power)
				# Spawn defeat burst at target position
				var grid_pos: Vector2i = _world_to_grid(target)
				spawn_defeat_burst(grid_pos, is_power)
				_active_particles.remove_at(i)
				needs_redraw = true
				continue

			# Spawn trail particles
			p["trail_timer"] = p.get("trail_timer", 0.0) + delta
			if p["trail_timer"] >= TRAIL_SPAWN_INTERVAL:
				p["trail_timer"] = 0.0
				var is_power: bool = p.get("is_power", false)
				var trail_color: Color = p.get("color", Color.WHITE)
				trail_color.a = 0.5
				trails_to_spawn.append({
					"type": "trail",
					"pos": p["pos"],
					"velocity": Vector2.ZERO,
					"color": trail_color,
					"size": Vector2(3, 3) if is_power else Vector2(2, 2),
					"lifetime": PARTICLE_LIFETIME * 0.5
				})

		# Arrow projectile - check hit and spawn trails
		if ptype == "arrow":
			var target: Vector2 = p.get("target", Vector2.ZERO)
			if p["pos"].distance_to(target) < 12.0:
				var is_power: bool = p.get("is_power", false)
				spawn_hit_sparks(target, is_power)
				_active_particles.remove_at(i)
				needs_redraw = true
				continue

			# Spawn trail particles for arrow
			p["trail_timer"] = p.get("trail_timer", 0.0) + delta
			if p["trail_timer"] >= TRAIL_SPAWN_INTERVAL * 0.5:
				p["trail_timer"] = 0.0
				var trail_color: Color = p.get("color", Color.WHITE)
				trail_color.a = 0.4
				trails_to_spawn.append({
					"type": "trail",
					"pos": p["pos"],
					"velocity": Vector2.ZERO,
					"color": trail_color,
					"size": Vector2(2, 2),
					"lifetime": PARTICLE_LIFETIME * 0.3
				})

		p["pos"] = p["pos"] + vel * delta
		needs_redraw = true

	# Add trail particles after iteration
	for trail in trails_to_spawn:
		_add_particle(trail)

	if needs_redraw:
		queue_redraw()

func _draw_particles() -> void:
	for p in _active_particles:
		var pos: Vector2 = p.get("pos", Vector2.ZERO)
		var color: Color = p.get("color", Color.WHITE)
		var ptype: String = str(p.get("type", ""))
		var lifetime: float = p.get("lifetime", 0.0)

		# Draw arrow projectiles as arrow shapes
		if ptype == "arrow":
			var direction: Vector2 = p.get("direction", Vector2.RIGHT)
			var arrow_length: float = p.get("arrow_length", 12.0)
			var is_power: bool = p.get("is_power", false)

			# Arrow tip (front)
			var tip: Vector2 = pos + direction * (arrow_length * 0.5)
			# Arrow tail (back)
			var tail: Vector2 = pos - direction * (arrow_length * 0.5)
			# Arrow head wings
			var perp: Vector2 = Vector2(-direction.y, direction.x)
			var head_size: float = 4.0 if is_power else 3.0
			var wing1: Vector2 = pos + direction * (arrow_length * 0.2) + perp * head_size
			var wing2: Vector2 = pos + direction * (arrow_length * 0.2) - perp * head_size

			# Draw arrow shaft
			var shaft_color: Color = color
			shaft_color.a = 1.0
			draw_line(tail, tip, shaft_color, 2.0 if is_power else 1.5)

			# Draw arrow head (triangle)
			var head_points: PackedVector2Array = PackedVector2Array([tip, wing1, wing2])
			draw_colored_polygon(head_points, shaft_color)

			# Draw glow effect for power shots
			if is_power:
				var glow_color: Color = Color(1.0, 0.95, 0.6, 0.4)
				draw_line(tail, tip, glow_color, 4.0)
		else:
			# Default particle rendering
			var psize: Vector2 = p.get("size", Vector2(4, 4))

			# Fade out
			var alpha: float = clampf(lifetime / (PARTICLE_LIFETIME * 0.5), 0.0, 1.0)
			color.a = alpha

			var rect: Rect2 = Rect2(pos - psize * 0.5, psize)
			draw_rect(rect, color, true)

## Convert world position to grid position
func _world_to_grid(world_pos: Vector2) -> Vector2i:
	var local_pos: Vector2 = world_pos - origin
	var gx: int = int(local_pos.x / cell_size.x)
	var gy: int = int(local_pos.y / cell_size.y)
	return Vector2i(gx, gy)

## Draw threat level bar at top of map
func _draw_threat_bar() -> void:
	var bar_width: float = map_w * cell_size.x
	var bar_height: float = 6.0
	var bar_pos: Vector2 = origin + Vector2(0, -12)

	# Background
	var bg_rect: Rect2 = Rect2(bar_pos, Vector2(bar_width, bar_height))
	draw_rect(bg_rect, Color(0.15, 0.15, 0.2, 0.8), true)
	draw_rect(bg_rect, Color(0.3, 0.3, 0.35, 1.0), false, 1.0)

	# Filled portion based on threat_level
	var fill_width: float = bar_width * threat_level
	if fill_width > 0:
		var fill_rect: Rect2 = Rect2(bar_pos, Vector2(fill_width, bar_height))
		# Color interpolates from yellow to red as threat increases
		var threat_color: Color
		if threat_level < 0.5:
			threat_color = Color(0.9, 0.8, 0.2, 0.9)  # Yellow
		elif threat_level < 0.8:
			threat_color = Color(0.95, 0.5, 0.2, 0.9)  # Orange
		else:
			threat_color = Color(0.95, 0.25, 0.2, 0.9)  # Red (danger!)
		draw_rect(fill_rect, threat_color, true)

	# Threshold marker at 80%
	var threshold_x: float = bar_pos.x + bar_width * 0.8
	draw_line(
		Vector2(threshold_x, bar_pos.y),
		Vector2(threshold_x, bar_pos.y + bar_height),
		Color(1.0, 0.3, 0.3, 0.8),
		2.0
	)

	# Label
	if font != null:
		var label: String = "THREAT"
		draw_string(font, bar_pos + Vector2(2, -2), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.7, 0.7, 0.75, 0.8))

## Draw activity mode indicator
func _draw_activity_mode() -> void:
	if font == null:
		return

	var indicator_pos: Vector2 = origin + Vector2(map_w * cell_size.x - 100, -22)
	var mode_color: Color
	var mode_text: String

	match activity_mode:
		"exploration":
			mode_color = Color(0.4, 0.8, 0.4, 0.9)
			mode_text = "EXPLORE"
		"encounter":
			mode_color = Color(0.9, 0.6, 0.3, 0.9)
			mode_text = "COMBAT"
		"wave_assault":
			mode_color = Color(0.95, 0.3, 0.3, 0.95)
			mode_text = "WAVE!"
			# Pulsing effect for wave assault
			if not reduced_motion:
				var pulse: float = (sin(Time.get_ticks_msec() * 0.008) + 1.0) * 0.3
				mode_color.a = 0.7 + pulse
		"event":
			mode_color = Color(0.5, 0.7, 0.9, 0.9)
			mode_text = "EVENT"
		_:
			mode_color = Color(0.6, 0.6, 0.6, 0.8)
			mode_text = activity_mode.to_upper()

	# Draw mode badge
	var text_size: float = 12.0
	var badge_width: float = 80.0
	var badge_rect: Rect2 = Rect2(indicator_pos, Vector2(badge_width, 16))
	draw_rect(badge_rect, Color(mode_color.r * 0.3, mode_color.g * 0.3, mode_color.b * 0.3, 0.8), true)
	draw_rect(badge_rect, mode_color, false, 1.5)
	draw_string(font, indicator_pos + Vector2(badge_width / 2 - 20, 12), mode_text, HORIZONTAL_ALIGNMENT_LEFT, -1, int(text_size), mode_color)

## Animation System Methods

## Update enemy walk/idle animations
func _update_animations(delta: float) -> void:
	if reduced_motion:
		return

	var needs_redraw := false

	# Update enemy animations
	for enemy_id in _enemy_anim_state:
		var state: Dictionary = _enemy_anim_state[enemy_id]
		var fps: float = state.get("fps", ENEMY_WALK_FPS)
		var frame_count: int = state.get("frame_count", 4)
		var loop: bool = state.get("loop", true)

		state["timer"] = state.get("timer", 0.0) + delta
		var frame_duration: float = 1.0 / fps

		if state["timer"] >= frame_duration:
			state["timer"] -= frame_duration
			state["frame"] = state.get("frame", 0) + 1

			if state["frame"] >= frame_count:
				if loop:
					state["frame"] = 0
				else:
					state["frame"] = frame_count - 1
					# Oneshot complete - handle callback if any
					if state.has("on_complete"):
						var callback: Callable = state["on_complete"]
						if callback.is_valid():
							callback.call()
						_enemy_anim_state.erase(enemy_id)

			needs_redraw = true

	# Update building animations
	var building_anims_to_remove: Array = []
	for bld_idx in _building_anim_state:
		var state: Dictionary = _building_anim_state[bld_idx]
		var fps: float = state.get("fps", 6.0)
		var frame_count: int = state.get("frame_count", 3)
		var anim_type: String = state.get("anim_type", "")

		state["timer"] = state.get("timer", 0.0) + delta
		var frame_duration: float = 1.0 / fps

		if state["timer"] >= frame_duration:
			state["timer"] -= frame_duration
			var next_frame: int = state.get("frame", 0) + 1

			# Fire and construct are oneshot animations
			if anim_type == "fire" or anim_type == "construct":
				if next_frame >= frame_count:
					building_anims_to_remove.append(bld_idx)
				else:
					state["frame"] = next_frame
			else:
				# Loop for pulse and other continuous animations
				state["frame"] = next_frame % frame_count
			needs_redraw = true

	for bld_idx in building_anims_to_remove:
		_building_anim_state.erase(bld_idx)

	if needs_redraw:
		queue_redraw()

## Update hit flash effect timers
func _update_hit_flashes(delta: float) -> void:
	if _hit_flash_timers.is_empty():
		return

	var expired: Array = []
	for enemy_id in _hit_flash_timers:
		_hit_flash_timers[enemy_id] -= delta
		if _hit_flash_timers[enemy_id] <= 0:
			expired.append(enemy_id)

	for enemy_id in expired:
		_hit_flash_timers.erase(enemy_id)

	if not expired.is_empty():
		queue_redraw()

## Update floating damage numbers
func _update_damage_numbers(delta: float) -> void:
	if _damage_numbers.is_empty():
		return

	var needs_redraw := false
	for i in range(_damage_numbers.size() - 1, -1, -1):
		var dn: Dictionary = _damage_numbers[i]
		dn["lifetime"] -= delta
		dn["pos"] = dn["pos"] + Vector2(0, -DAMAGE_NUMBER_RISE_SPEED * delta)

		if dn["lifetime"] <= 0:
			_damage_numbers.remove_at(i)
			needs_redraw = true

	if needs_redraw or not _damage_numbers.is_empty():
		queue_redraw()

## Draw damage numbers overlay (call from _draw after particles)
func _draw_damage_numbers() -> void:
	if font == null or _damage_numbers.is_empty():
		return

	for dn in _damage_numbers:
		var pos: Vector2 = dn["pos"]
		var value: int = dn["value"]
		var color: Color = dn["color"]
		var is_crit: bool = dn.get("is_crit", false)
		var lifetime: float = dn["lifetime"]
		var prefix: String = dn.get("prefix", "")

		# Fade out
		var alpha: float = clampf(lifetime / (DAMAGE_NUMBER_LIFETIME * 0.5), 0.0, 1.0)
		color.a = alpha

		var text := prefix + str(value)
		var fsize: int = 16 if is_crit else 14

		# Crit numbers scale up briefly
		if is_crit and lifetime > DAMAGE_NUMBER_LIFETIME * 0.7:
			fsize = 20

		# Draw with outline for better visibility
		var outline_color := Color(0.0, 0.0, 0.0, alpha * 0.8)
		for ox in [-1, 0, 1]:
			for oy in [-1, 0, 1]:
				if ox != 0 or oy != 0:
					draw_string(font, pos + Vector2(ox, oy), text, HORIZONTAL_ALIGNMENT_CENTER, -1, fsize, outline_color)
		draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, -1, fsize, color)


## Update combo announcements
func _update_combo_announcements(delta: float) -> void:
	if _combo_announcements.is_empty():
		return

	var needs_redraw := false
	for i in range(_combo_announcements.size() - 1, -1, -1):
		var ann: Dictionary = _combo_announcements[i]
		ann["lifetime"] -= delta

		# Animate scale (grow quickly at start, then stabilize)
		var t: float = 1.0 - (float(ann["lifetime"]) / COMBO_ANNOUNCEMENT_LIFETIME)
		if t < 0.2:
			# Quick grow phase
			ann["scale"] = 0.5 + (t / 0.2) * 0.6
		else:
			ann["scale"] = 1.1 - (t - 0.2) * 0.1  # Slight shrink back

		# Move upward slightly
		ann["pos"] = ann["pos"] + Vector2(0, -20.0 * delta)

		if ann["lifetime"] <= 0:
			_combo_announcements.remove_at(i)
			needs_redraw = true

	if needs_redraw or not _combo_announcements.is_empty():
		queue_redraw()


## Draw combo announcements
func _draw_combo_announcements() -> void:
	if font == null or _combo_announcements.is_empty():
		return

	for ann in _combo_announcements:
		var pos: Vector2 = ann["pos"]
		var text: String = ann["text"]
		var color: Color = ann["color"]
		var size_mult: float = ann["size_mult"]
		var lifetime: float = ann["lifetime"]
		var scale: float = ann["scale"]

		# Fade out in last 30%
		var alpha := 1.0
		if lifetime < COMBO_ANNOUNCEMENT_LIFETIME * 0.3:
			alpha = lifetime / (COMBO_ANNOUNCEMENT_LIFETIME * 0.3)
		color.a = alpha

		var fsize: int = int(24 * size_mult * scale)

		# Draw with thick outline for visibility
		var outline_color := Color(0.0, 0.0, 0.0, alpha * 0.9)
		for ox in [-2, -1, 0, 1, 2]:
			for oy in [-2, -1, 0, 1, 2]:
				if ox != 0 or oy != 0:
					draw_string(font, pos + Vector2(ox, oy), text, HORIZONTAL_ALIGNMENT_CENTER, -1, fsize, outline_color)
		draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, -1, fsize, color)


## Update insufficient resource pulses
func _update_insufficient_pulses(delta: float) -> void:
	if _insufficient_pulses.is_empty():
		return

	var needs_redraw := false
	for i in range(_insufficient_pulses.size() - 1, -1, -1):
		var pulse: Dictionary = _insufficient_pulses[i]
		pulse["lifetime"] -= delta
		pulse["radius"] += 80.0 * delta  # Expand outward

		if pulse["lifetime"] <= 0:
			_insufficient_pulses.remove_at(i)
			needs_redraw = true

	if needs_redraw or not _insufficient_pulses.is_empty():
		queue_redraw()


## Draw insufficient resource pulses (red expanding rings)
func _draw_insufficient_pulses() -> void:
	if _insufficient_pulses.is_empty():
		return

	for pulse in _insufficient_pulses:
		var pos: Vector2 = pulse["pos"]
		var lifetime: float = pulse["lifetime"]
		var radius: float = pulse["radius"]

		# Fade out
		var alpha := lifetime / INSUFFICIENT_PULSE_LIFETIME
		var color := Color(0.9, 0.3, 0.2, alpha * 0.6)

		# Draw expanding ring
		draw_arc(pos, radius, 0, TAU, 24, color, 2.0)

		# Inner ring slightly delayed
		if radius > 10:
			var inner_color := Color(0.9, 0.3, 0.2, alpha * 0.4)
			draw_arc(pos, radius - 10, 0, TAU, 24, inner_color, 1.5)


## Trigger hit flash effect on enemy
func trigger_hit_flash(enemy_id: int) -> void:
	if reduced_motion:
		return
	_hit_flash_timers[enemy_id] = HIT_FLASH_DURATION
	queue_redraw()

## Spawn floating damage number
func spawn_damage_number(enemy_pos: Vector2i, damage: int, is_crit: bool = false) -> void:
	if reduced_motion:
		return

	var world_pos: Vector2 = origin + Vector2(enemy_pos.x * cell_size.x, enemy_pos.y * cell_size.y)
	world_pos += cell_size * 0.5 + Vector2(randf_range(-8, 8), -10)

	var color: Color = Color(1.0, 0.95, 0.3, 1.0) if is_crit else Color(1.0, 1.0, 1.0, 1.0)

	_damage_numbers.append({
		"pos": world_pos,
		"value": damage,
		"color": color,
		"is_crit": is_crit,
		"lifetime": DAMAGE_NUMBER_LIFETIME
	})
	queue_redraw()

## Spawn production indicator (+resource) at building position
func spawn_production_indicator(building_pos: Vector2i, resource: String, amount: int) -> void:
	if reduced_motion or amount <= 0:
		return

	var world_pos: Vector2 = origin + Vector2(building_pos.x * cell_size.x, building_pos.y * cell_size.y)
	world_pos += cell_size * 0.5 + Vector2(randf_range(-5, 5), -8)

	# Color based on resource type
	var color: Color
	match resource:
		"food":
			color = Color(0.4, 0.85, 0.4, 1.0)  # Green
		"wood":
			color = Color(0.7, 0.5, 0.3, 1.0)  # Brown
		"stone":
			color = Color(0.6, 0.6, 0.65, 1.0)  # Gray
		"gold":
			color = Color(1.0, 0.85, 0.3, 1.0)  # Gold
		_:
			color = Color(0.9, 0.9, 0.9, 1.0)  # White

	_damage_numbers.append({
		"pos": world_pos,
		"value": amount,
		"color": color,
		"is_crit": false,
		"lifetime": DAMAGE_NUMBER_LIFETIME * 0.8,
		"prefix": "+"  # Will show as "+3" instead of just "3"
	})

	# Also trigger a subtle pulse on the building
	var bld_index: int = building_pos.y * map_w + building_pos.x
	if not _building_anim_state.has(bld_index):
		register_building_animation(bld_index, "pulse")

	queue_redraw()


## Spawn resource spend indicator (-resource) at a position
func spawn_resource_spend_indicator(screen_pos: Vector2, resource: String, amount: int) -> void:
	if reduced_motion or amount <= 0:
		return

	var world_pos: Vector2 = screen_pos + Vector2(randf_range(-5, 5), -5)

	# Color based on resource type (slightly desaturated compared to gain)
	var color: Color
	match resource:
		"food":
			color = Color(0.5, 0.7, 0.5, 1.0)
		"wood":
			color = Color(0.6, 0.45, 0.3, 1.0)
		"stone":
			color = Color(0.55, 0.55, 0.6, 1.0)
		"gold":
			color = Color(0.9, 0.75, 0.3, 1.0)
		_:
			color = Color(0.8, 0.8, 0.8, 1.0)

	_damage_numbers.append({
		"pos": world_pos,
		"value": amount,
		"color": color,
		"is_crit": false,
		"lifetime": DAMAGE_NUMBER_LIFETIME * 0.6,
		"prefix": "-"
	})
	queue_redraw()


## Spawn combo milestone announcement
func spawn_combo_announcement(combo_count: int) -> void:
	if reduced_motion:
		return

	# Only show announcements for milestones
	if combo_count < 5:
		return
	if combo_count > 5 and combo_count % 5 != 0:
		return

	# Position at center of grid
	var center_x := origin.x + (map_w * cell_size.x) * 0.5
	var center_y := origin.y + (map_h * cell_size.y) * 0.3  # Upper third

	var text: String
	var color: Color
	var size_mult: float = 1.0

	if combo_count >= 20:
		text = "COMBO x%d!" % combo_count
		color = Color(1.0, 0.3, 0.8, 1.0)  # Magenta
		size_mult = 1.4
	elif combo_count >= 15:
		text = "x%d STREAK!" % combo_count
		color = Color(0.4, 0.9, 1.0, 1.0)  # Cyan
		size_mult = 1.3
	elif combo_count >= 10:
		text = "x%d!" % combo_count
		color = Color(1.0, 0.85, 0.3, 1.0)  # Gold
		size_mult = 1.2
	else:  # 5
		text = "x%d" % combo_count
		color = Color(0.9, 0.9, 0.9, 1.0)  # White
		size_mult = 1.0

	_combo_announcements.append({
		"pos": Vector2(center_x, center_y),
		"text": text,
		"color": color,
		"size_mult": size_mult,
		"lifetime": COMBO_ANNOUNCEMENT_LIFETIME,
		"scale": 0.5  # Start small, grow
	})
	queue_redraw()


## Spawn insufficient resources pulse at screen position
func spawn_insufficient_pulse(screen_pos: Vector2) -> void:
	if reduced_motion:
		return

	_insufficient_pulses.append({
		"pos": screen_pos,
		"lifetime": INSUFFICIENT_PULSE_LIFETIME,
		"radius": 0.0
	})
	queue_redraw()


## Register enemy for walk animation
func register_enemy_animation(enemy_id: int, kind: String, anim_type: String = "walk") -> void:
	if reduced_motion:
		return

	var frame_count: int = 4
	var fps: float = ENEMY_WALK_FPS
	var loop: bool = true

	# Configure based on enemy kind and animation type
	match anim_type:
		"walk":
			match kind:
				"runner", "raider", "scout":
					frame_count = 4
					fps = 10.0
				"brute", "armored":
					frame_count = 3
					fps = 6.0
				"flyer":
					frame_count = 3
					fps = 8.0
				_:
					frame_count = 3
					fps = 7.0
		"death":
			frame_count = 3
			fps = ENEMY_DEATH_FPS
			loop = false
		"hover":
			frame_count = 3
			fps = 8.0

	_enemy_anim_state[enemy_id] = {
		"kind": kind,
		"anim_type": anim_type,
		"frame": 0,
		"timer": randf() * 0.5,  # Stagger start times
		"frame_count": frame_count,
		"fps": fps,
		"loop": loop
	}

## Play enemy death animation
func play_enemy_death_anim(enemy_id: int, kind: String, on_complete: Callable = Callable()) -> void:
	if reduced_motion:
		if on_complete.is_valid():
			on_complete.call()
		return

	var frame_count: int = 3
	match kind:
		"brute", "armored":
			frame_count = 4
		"boss_warlord", "boss_mage":
			frame_count = 5
		_:
			frame_count = 3

	_enemy_anim_state[enemy_id] = {
		"kind": kind,
		"anim_type": "death",
		"frame": 0,
		"timer": 0.0,
		"frame_count": frame_count,
		"fps": ENEMY_DEATH_FPS,
		"loop": false,
		"on_complete": on_complete
	}
	queue_redraw()

## Unregister enemy animation (when enemy removed)
func unregister_enemy_animation(enemy_id: int) -> void:
	_enemy_anim_state.erase(enemy_id)
	_hit_flash_timers.erase(enemy_id)

## Sync enemy animations with current enemy list - register new, unregister removed
func _sync_enemy_animations(new_enemies: Array) -> void:
	if reduced_motion:
		return

	# Build set of current enemy IDs
	var current_ids: Dictionary = {}
	for enemy in enemies:
		var eid: int = int(enemy.get("id", -1))
		if eid >= 0:
			current_ids[eid] = true

	# Build set of new enemy IDs
	var new_ids: Dictionary = {}
	for enemy in new_enemies:
		var eid: int = int(enemy.get("id", -1))
		if eid >= 0:
			new_ids[eid] = enemy

	# Register new enemies
	for eid in new_ids:
		if not current_ids.has(eid):
			var enemy: Dictionary = new_ids[eid]
			var kind: String = str(enemy.get("kind", "runner"))
			var anim_type := "hover" if kind == "flyer" else "walk"
			register_enemy_animation(eid, kind, anim_type)

	# Unregister removed enemies (unless death animation is playing)
	for eid in current_ids:
		if not new_ids.has(eid):
			# Check if death animation is playing - don't unregister if so
			if _enemy_anim_state.has(eid):
				var state: Dictionary = _enemy_anim_state[eid]
				if state.get("anim_type", "") == "death":
					continue  # Let death animation complete
			unregister_enemy_animation(eid)

## Get current animation frame for enemy
func get_enemy_animation_frame(enemy_id: int) -> int:
	if _enemy_anim_state.has(enemy_id):
		return _enemy_anim_state[enemy_id].get("frame", 0)
	return 0

## Check if enemy has hit flash active
func has_hit_flash(enemy_id: int) -> bool:
	return _hit_flash_timers.has(enemy_id)

## Register building for animation (e.g., tower firing)
func register_building_animation(building_index: int, anim_type: String) -> void:
	if reduced_motion:
		return

	var frame_count: int = 3
	var fps: float = 8.0

	match anim_type:
		"fire":
			frame_count = 3
			fps = 12.0
		"pulse":
			frame_count = 3
			fps = 6.0
		"construct":
			frame_count = 4
			fps = 8.0

	_building_anim_state[building_index] = {
		"anim_type": anim_type,
		"frame": 0,
		"timer": 0.0,
		"frame_count": frame_count,
		"fps": fps
	}

## Clear all animation states (e.g., on scene change)
func clear_animation_states() -> void:
	_enemy_anim_state.clear()
	_hit_flash_timers.clear()
	_damage_numbers.clear()
	_building_anim_state.clear()
	_combo_announcements.clear()
	_insufficient_pulses.clear()

## Trigger tower fire animation at position
func trigger_tower_fire(tower_pos: Vector2i) -> void:
	if reduced_motion:
		return
	var index: int = tower_pos.y * map_w + tower_pos.x
	register_building_animation(index, "fire")

## Find and animate the closest tower to an enemy position
func trigger_nearest_tower_fire(enemy_pos: Vector2i) -> void:
	if reduced_motion or structures.is_empty():
		return

	var closest_index: int = -1
	var closest_dist: int = 999

	for key in structures.keys():
		if str(structures[key]) == "tower":
			var idx: int = int(key)
			var tx: int = idx % map_w
			var ty: int = idx / map_w
			var dist: int = absi(tx - enemy_pos.x) + absi(ty - enemy_pos.y)
			if dist < closest_dist:
				closest_dist = dist
				closest_index = idx

	if closest_index >= 0:
		register_building_animation(closest_index, "fire")


# =============================================================================
# VISUAL PLACEMENT SYSTEM
# =============================================================================

## Draw grid overlay showing buildable/unbuildable tiles
func _draw_placement_grid_overlay() -> void:
	for y in range(map_h):
		for x in range(map_w):
			var index: int = y * map_w + x
			var rect: Rect2 = Rect2(origin + Vector2(x * cell_size.x, y * cell_size.y), cell_size)

			# Skip cursor position (it has its own highlight)
			if x == cursor_pos.x and y == cursor_pos.y:
				continue

			# Only show overlay for discovered tiles
			if not discovered.has(index):
				continue

			var buildable: bool = _is_preview_buildable(index)
			var overlay_color: Color = grid_overlay_buildable_color if buildable else grid_overlay_unbuildable_color
			draw_rect(rect.grow(-1), overlay_color)


## Get the attack range for a building type (0 if not a tower)
func _get_building_range(building_type: String) -> int:
	var building_data: Dictionary = SimBuildings.BUILDINGS.get(building_type, {})

	# Check for auto-tower attack stats
	var auto_attack: Dictionary = building_data.get("auto_attack", {})
	if not auto_attack.is_empty():
		return int(auto_attack.get("range", 0))

	# Check for regular tower combat stats
	if building_type == "tower":
		var combat: Dictionary = SimBuildings.TOWER_STATS.get(1, {})
		return int(combat.get("range", 3))

	return 0


## Draw range circle for towers
func _draw_range_circle(center_pos: Vector2i, tile_range: int, is_valid: bool) -> void:
	var center_pixel := origin + Vector2(center_pos.x * cell_size.x, center_pos.y * cell_size.y) + cell_size / 2

	# Calculate radius in pixels (range is in tiles)
	var radius_pixels: float = tile_range * cell_size.x + cell_size.x / 2

	# Pulsing effect
	var pulse := (sin(_aura_pulse_time * 2.0) + 1.0) * 0.5

	# Color based on validity
	var fill_color: Color = range_circle_color
	var border_color: Color = range_circle_border_color
	if not is_valid:
		fill_color = Color(0.8, 0.3, 0.3, 0.15)
		border_color = Color(0.8, 0.3, 0.3, 0.4)

	# Pulse the alpha slightly
	fill_color.a = fill_color.a * (0.7 + pulse * 0.3)
	border_color.a = border_color.a * (0.7 + pulse * 0.3)

	# Draw filled circle (approximate with polygon)
	var points := PackedVector2Array()
	var segments: int = 32
	for i in range(segments):
		var angle := float(i) / float(segments) * TAU
		points.append(center_pixel + Vector2(cos(angle), sin(angle)) * radius_pixels)

	draw_colored_polygon(points, fill_color)

	# Draw border
	for i in range(segments):
		var angle1 := float(i) / float(segments) * TAU
		var angle2 := float(i + 1) / float(segments) * TAU
		var p1 := center_pixel + Vector2(cos(angle1), sin(angle1)) * radius_pixels
		var p2 := center_pixel + Vector2(cos(angle2), sin(angle2)) * radius_pixels
		draw_line(p1, p2, border_color, 2.0)

	# Also highlight tiles within range
	_draw_range_tile_highlights(center_pos, tile_range, is_valid)


## Highlight individual tiles within tower range
func _draw_range_tile_highlights(center_pos: Vector2i, tile_range: int, is_valid: bool) -> void:
	var highlight_color: Color = Color(0.4, 0.7, 1.0, 0.08) if is_valid else Color(0.8, 0.3, 0.3, 0.08)

	for dy in range(-tile_range, tile_range + 1):
		for dx in range(-tile_range, tile_range + 1):
			var tx: int = center_pos.x + dx
			var ty: int = center_pos.y + dy

			# Skip out of bounds
			if tx < 0 or tx >= map_w or ty < 0 or ty >= map_h:
				continue

			# Check if within circular range (Manhattan for simplicity, or Euclidean)
			var dist: float = sqrt(dx * dx + dy * dy)
			if dist > tile_range:
				continue

			# Skip the center tile
			if dx == 0 and dy == 0:
				continue

			var rect := Rect2(origin + Vector2(tx * cell_size.x, ty * cell_size.y), cell_size)
			draw_rect(rect.grow(-2), highlight_color)


## Draw enhanced tooltip with cost breakdown or block reason
func _draw_preview_tooltip(preview_rect: Rect2, buildable: bool, block_reason: String) -> void:
	var tooltip_y := preview_rect.position.y + cell_size.y + 6
	var tooltip_x := preview_rect.position.x

	# Get building cost
	var cost: Dictionary = SimBuildings.BUILDINGS.get(preview_type, {}).get("cost", {})

	if not buildable:
		# Show block reason
		if block_reason != "":
			var tooltip_text := block_reason
			var text_width: float = font.get_string_size(tooltip_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
			var bg_rect := Rect2(tooltip_x - 4, tooltip_y - 2, text_width + 12, 18)
			draw_rect(bg_rect, cost_tooltip_bg_color)
			draw_rect(bg_rect, Color(0.8, 0.3, 0.3, 0.5), false, 1.0)
			draw_string(font, Vector2(tooltip_x, tooltip_y + 11), tooltip_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, cost_unaffordable_color)
	else:
		# Show cost breakdown
		if cost.is_empty():
			return

		var cost_parts := []
		var can_afford := true

		for resource in ["wood", "stone", "food", "gold"]:
			var amount: int = int(cost.get(resource, 0))
			if amount > 0:
				var have: int = int(current_resources.get(resource, 0))
				var affordable: bool = have >= amount
				if not affordable:
					can_afford = false
				var color_tag: String = "affordable" if affordable else "unaffordable"
				cost_parts.append({"resource": resource, "amount": amount, "affordable": affordable})

		if cost_parts.is_empty():
			return

		# Calculate tooltip width
		var total_width: float = 8.0  # padding
		for part in cost_parts:
			var resource_char: String = _resource_char(part.resource)
			var amount_str: String = str(part.amount)
			total_width += font.get_string_size(resource_char + amount_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x + 8

		# Draw background
		var bg_rect := Rect2(tooltip_x - 4, tooltip_y - 2, total_width, 18)
		draw_rect(bg_rect, cost_tooltip_bg_color)

		# Border color based on affordability
		var border_col: Color = Color(0.3, 0.7, 0.4, 0.6) if can_afford else Color(0.7, 0.3, 0.3, 0.6)
		draw_rect(bg_rect, border_col, false, 1.0)

		# Draw cost items
		var x_offset := tooltip_x
		for part in cost_parts:
			var resource_char: String = _resource_char(part.resource)
			var amount_str: String = str(part.amount)
			var color: Color = cost_affordable_color if part.affordable else cost_unaffordable_color

			# Resource icon
			var resource_color := _resource_icon_color(part.resource)
			draw_string(font, Vector2(x_offset, tooltip_y + 11), resource_char, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, resource_color)
			x_offset += font.get_string_size(resource_char, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x + 2

			# Amount
			draw_string(font, Vector2(x_offset, tooltip_y + 11), amount_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, color)
			x_offset += font.get_string_size(amount_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x + 6


## Get single-char representation of a resource
func _resource_char(resource: String) -> String:
	match resource:
		"wood": return "W"
		"stone": return "S"
		"food": return "F"
		"gold": return "G"
		_: return "?"


## Get color for resource icon
func _resource_icon_color(resource: String) -> Color:
	match resource:
		"wood": return Color(0.6, 0.4, 0.2)
		"stone": return Color(0.5, 0.5, 0.6)
		"food": return Color(0.4, 0.7, 0.3)
		"gold": return Color(0.9, 0.75, 0.3)
		_: return Color.WHITE


# =============================================================================
# TOWER SYNERGY VISUALIZATION
# =============================================================================

## Draw connections between towers that have active synergies
func _draw_tower_synergies() -> void:
	if active_synergies.is_empty():
		return

	# Draw connection lines between synergized towers
	for synergy in active_synergies:
		var positions: Array = synergy.get("positions", [])
		var synergy_color: Color = synergy.get("color", synergy_line_color)

		if positions.size() < 2:
			continue

		# Draw lines connecting all towers in the synergy
		for i in range(positions.size()):
			var pos1: Vector2i = positions[i]
			var center1 := _tile_center(pos1)

			# Draw glow on each tower
			_draw_synergy_glow(pos1, synergy_color)

			# Connect to all other towers in the synergy
			for j in range(i + 1, positions.size()):
				var pos2: Vector2i = positions[j]
				var center2 := _tile_center(pos2)

				# Draw connection line
				_draw_synergy_connection(center1, center2, synergy_color)

		# Draw synergy icon at the center of the formation
		_draw_synergy_icon(positions, synergy)


## Draw a glow effect around a synergized tower
func _draw_synergy_glow(pos: Vector2i, base_color: Color) -> void:
	if reduced_motion:
		return

	var rect := Rect2(origin + Vector2(pos.x * cell_size.x, pos.y * cell_size.y), cell_size)

	# Pulsing glow effect
	var pulse := (sin(_aura_pulse_time * 3.0) + 1.0) * 0.5
	var glow_alpha := 0.1 + pulse * 0.15
	var glow_color := Color(base_color.r, base_color.g, base_color.b, glow_alpha)

	# Draw multiple expanding rings for glow effect
	for ring in range(3):
		var ring_alpha := glow_alpha * (1.0 - float(ring) * 0.3)
		var ring_color := Color(glow_color.r, glow_color.g, glow_color.b, ring_alpha)
		var grow_amount := 2.0 + float(ring) * 3.0 + pulse * 2.0
		draw_rect(rect.grow(grow_amount), ring_color, false, 1.5)


## Draw a connection line between two synergized towers
func _draw_synergy_connection(from: Vector2, to: Vector2, color: Color) -> void:
	# Main line
	var line_alpha := 0.3 if reduced_motion else 0.4 + (sin(_aura_pulse_time * 2.0) + 1.0) * 0.15
	var line_color := Color(color.r, color.g, color.b, line_alpha)

	# Draw main line with glow
	if not reduced_motion:
		# Outer glow
		var glow_color := Color(color.r, color.g, color.b, line_alpha * 0.3)
		draw_line(from, to, glow_color, 6.0)

	# Core line
	draw_line(from, to, line_color, 2.0)

	# Draw energy particles along the line (if not reduced motion)
	if not reduced_motion:
		_draw_line_particles(from, to, color)


## Draw animated particles along a synergy connection line
func _draw_line_particles(from: Vector2, to: Vector2, color: Color) -> void:
	var dir := (to - from).normalized()
	var dist := from.distance_to(to)
	var particle_count := int(dist / 15.0)

	for i in range(particle_count):
		# Animated position along the line
		var base_t := float(i) / float(particle_count)
		var animated_t := fmod(base_t + _aura_pulse_time * 0.5, 1.0)
		var pos := from.lerp(to, animated_t)

		# Particle size based on position in animation
		var particle_alpha := sin(animated_t * PI) * 0.6
		var particle_color := Color(color.r, color.g, color.b, particle_alpha)
		var particle_size := 2.0 + sin(animated_t * PI) * 1.5

		draw_circle(pos, particle_size, particle_color)


## Draw synergy icon at the center of the tower formation
func _draw_synergy_icon(positions: Array, synergy: Dictionary) -> void:
	if positions.is_empty():
		return

	# Calculate center of all positions
	var center_sum := Vector2.ZERO
	for pos in positions:
		center_sum += _tile_center(pos)
	var icon_center := center_sum / float(positions.size())

	var icon_text: String = synergy.get("icon", "")
	var synergy_color: Color = synergy.get("color", Color.WHITE)

	if icon_text.is_empty():
		# Draw a generic synergy indicator
		var indicator_radius := 8.0
		var indicator_alpha := 0.7 if reduced_motion else 0.6 + (sin(_aura_pulse_time * 4.0) + 1.0) * 0.2
		var indicator_color := Color(synergy_color.r, synergy_color.g, synergy_color.b, indicator_alpha)

		# Draw diamond shape
		var diamond_points := PackedVector2Array([
			icon_center + Vector2(0, -indicator_radius),
			icon_center + Vector2(indicator_radius, 0),
			icon_center + Vector2(0, indicator_radius),
			icon_center + Vector2(-indicator_radius, 0)
		])
		draw_colored_polygon(diamond_points, indicator_color)

		# Border
		for i in range(4):
			var p1 := diamond_points[i]
			var p2 := diamond_points[(i + 1) % 4]
			draw_line(p1, p2, Color(synergy_color.r, synergy_color.g, synergy_color.b, 0.8), 1.5)
	else:
		# Draw icon text with background
		var bg_radius := 12.0
		var bg_alpha := 0.85
		var bg_color := Color(0.1, 0.1, 0.15, bg_alpha)

		# Background circle
		draw_circle(icon_center, bg_radius, bg_color)
		draw_arc(icon_center, bg_radius, 0, TAU, 24, synergy_color, 1.5)

		# Icon text (centered)
		var text_offset := Vector2(-font.get_string_size(icon_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x * 0.5, 4)
		draw_string(font, icon_center + text_offset, icon_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE)


## Draw preview synergies (potential synergies when placing a tower)
func _draw_preview_synergies() -> void:
	if preview_synergies.is_empty():
		return

	# Re-compute preview synergies based on current cursor position
	if preview_type != "" and state_ref != null:
		if preview_type.begins_with("auto_") or preview_type == "tower":
			preview_synergies = SimTowerSynergies.preview_synergies(state_ref, cursor_pos, preview_type)

	for synergy in preview_synergies:
		var positions: Array = synergy.get("positions", [])
		var synergy_color: Color = synergy.get("color", synergy_preview_color)

		# Make preview synergies more visible with distinct color
		var preview_col := Color(synergy_color.r * 1.2, synergy_color.g * 1.2, synergy_color.b, 0.6)

		if positions.size() < 2:
			continue

		# Draw dashed preview lines connecting towers
		for i in range(positions.size()):
			var pos1: Vector2i = positions[i]
			var center1 := _tile_center(pos1)

			for j in range(i + 1, positions.size()):
				var pos2: Vector2i = positions[j]
				var center2 := _tile_center(pos2)

				# Draw dashed preview line
				_draw_preview_synergy_line(center1, center2, preview_col)

		# Draw preview synergy label
		_draw_preview_synergy_label(positions, synergy)


## Draw a dashed line for preview synergies
func _draw_preview_synergy_line(from: Vector2, to: Vector2, color: Color) -> void:
	var dir := (to - from).normalized()
	var dist := from.distance_to(to)
	var dash_length := 8.0
	var gap_length := 4.0
	var segment_length := dash_length + gap_length

	var num_segments := int(dist / segment_length)
	var offset := fmod(_aura_pulse_time * 30.0, segment_length)  # Animated offset

	for i in range(num_segments + 1):
		var start_dist := float(i) * segment_length + offset
		var end_dist := minf(start_dist + dash_length, dist)

		if start_dist >= dist:
			break

		var start_pos := from + dir * start_dist
		var end_pos := from + dir * end_dist

		draw_line(start_pos, end_pos, color, 2.0)


## Draw preview synergy label showing what synergy would activate
func _draw_preview_synergy_label(positions: Array, synergy: Dictionary) -> void:
	if positions.is_empty():
		return

	# Calculate center of all positions
	var center_sum := Vector2.ZERO
	for pos in positions:
		center_sum += _tile_center(pos)
	var label_center := center_sum / float(positions.size())

	var synergy_name: String = synergy.get("name", "Synergy")
	var synergy_color: Color = synergy.get("color", Color.WHITE)

	# Draw label above the center
	var label_pos := label_center + Vector2(0, -20)

	# Background
	var text_width := font.get_string_size(synergy_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
	var bg_rect := Rect2(label_pos.x - text_width * 0.5 - 4, label_pos.y - 12, text_width + 8, 16)
	draw_rect(bg_rect, Color(0.1, 0.15, 0.1, 0.9))
	draw_rect(bg_rect, synergy_color, false, 1.0)

	# Text
	var text_pos := Vector2(label_pos.x - text_width * 0.5, label_pos.y)
	draw_string(font, text_pos, synergy_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.8, 1.0, 0.8))


## Get the pixel center of a tile
func _tile_center(pos: Vector2i) -> Vector2:
	return origin + Vector2(pos.x * cell_size.x + cell_size.x * 0.5, pos.y * cell_size.y + cell_size.y * 0.5)
