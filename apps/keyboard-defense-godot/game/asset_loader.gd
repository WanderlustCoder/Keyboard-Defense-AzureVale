extends Node
## Asset Loader - Loads and caches textures from assets_manifest.json

const MANIFEST_PATH := "res://data/assets_manifest.json"

var _manifest: Dictionary = {}
var _texture_cache: Dictionary = {}
var _animation_frame_cache: Dictionary = {}  # sprite_id -> Array[Texture2D]
var _loaded: bool = false

# Texture lookup tables by category
var sprites: Dictionary = {}
var icons: Dictionary = {}
var tiles: Dictionary = {}
var ui: Dictionary = {}
var animations: Dictionary = {}  # Animation entries indexed by id

func _ready() -> void:
	_load_manifest()

func _load_manifest() -> void:
	if _loaded:
		return
	var file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if file == null:
		push_warning("AssetLoader: Could not open manifest at %s" % MANIFEST_PATH)
		return
	var json_text := file.get_as_text()
	file.close()
	var json := JSON.new()
	var err := json.parse(json_text)
	if err != OK:
		push_warning("AssetLoader: Failed to parse manifest JSON")
		return
	_manifest = json.data
	_index_textures()
	_loaded = true

func _index_textures() -> void:
	var textures: Array = _manifest.get("textures", [])
	for entry in textures:
		if not entry is Dictionary:
			continue
		var id: String = entry.get("id", "")
		var category: String = entry.get("category", "")
		if id.is_empty():
			continue
		# Index animations separately
		if entry.has("animation"):
			animations[id] = entry
		match category:
			"buildings", "units", "enemies", "decorations", "effects", "npcs", "portraits":
				sprites[id] = entry
			"icons", "poi", "status", "medals":
				icons[id] = entry
			"tiles":
				tiles[id] = entry
			"ui", "tutorial":
				ui[id] = entry

func get_texture(id: String) -> Texture2D:
	if _texture_cache.has(id):
		return _texture_cache[id]
	var entry := _find_entry(id)
	if entry.is_empty():
		return null
	var path: String = entry.get("path", "")
	if path.is_empty():
		return null
	var texture := load(path) as Texture2D
	if texture != null:
		_texture_cache[id] = texture
	return texture

func get_sprite_texture(id: String) -> Texture2D:
	if sprites.has(id):
		return get_texture(id)
	return null

func get_icon_texture(id: String) -> Texture2D:
	if icons.has(id):
		return get_texture(id)
	return null

func get_tile_texture(id: String) -> Texture2D:
	if tiles.has(id):
		return get_texture(id)
	return null

func get_ui_texture(id: String) -> Texture2D:
	if ui.has(id):
		return get_texture(id)
	return null

func get_entry(id: String) -> Dictionary:
	return _find_entry(id)

func _find_entry(id: String) -> Dictionary:
	if sprites.has(id):
		return sprites[id]
	if icons.has(id):
		return icons[id]
	if tiles.has(id):
		return tiles[id]
	if ui.has(id):
		return ui[id]
	return {}

func get_animation_info(id: String) -> Dictionary:
	var entry := _find_entry(id)
	return entry.get("animation", {})

func get_nineslice_info(id: String) -> Dictionary:
	var entry := _find_entry(id)
	return entry.get("nineslice", {})

## Enemy sprite mapping - maps enemy kind to sprite id
func get_enemy_sprite_id(kind: String) -> String:
	match kind:
		"raider", "runner":
			return "enemy_runner"
		"scout":
			return "enemy_runner"
		"armored", "brute":
			return "enemy_brute"
		"flyer":
			return "enemy_flyer"
		"shielder":
			return "enemy_shielder"
		"healer":
			return "enemy_healer"
		"boss_warlord":
			return "enemy_boss_warlord"
		"boss_mage":
			return "enemy_boss_mage"
		_:
			if kind.ends_with("_elite"):
				var base_kind := kind.trim_suffix("_elite")
				var base_id := get_enemy_sprite_id(base_kind)
				if sprites.has(base_id + "_elite"):
					return base_id + "_elite"
				return base_id
			return "enemy_runner"

## Building sprite mapping
func get_building_sprite_id(building_type: String) -> String:
	match building_type:
		"farm":
			return "bld_barracks"  # Placeholder until farm sprite exists
		"lumber":
			return "bld_library"   # Placeholder
		"quarry":
			return "bld_gate"      # Placeholder
		"wall":
			return "bld_wall"
		"tower":
			return "bld_tower_arrow"
		"castle":
			return "bld_castle"
		_:
			return "bld_wall"

## Unit sprite mapping
func get_unit_sprite_id(unit_type: String) -> String:
	match unit_type:
		"scribe":
			return "unit_scribe"
		"archer":
			return "unit_archer"
		"scout":
			return "unit_scout"
		_:
			return "unit_scribe"

## Effect sprite mapping
func get_effect_sprite_id(effect_type: String) -> String:
	match effect_type:
		"projectile":
			return "fx_projectile"
		"magic_bolt":
			return "fx_magic_bolt"
		"hit_flash":
			return "fx_hit_flash"
		"build_dust":
			return "fx_build_dust"
		"typing_streak":
			return "fx_typing_streak"
		"reward_sparkle":
			return "fx_reward_sparkle"
		_:
			return "fx_projectile"

## Portrait sprite mapping - maps character name to portrait id
func get_portrait_sprite_id(character: String) -> String:
	match character.to_lower():
		"lyra", "elder lyra":
			return "portrait_lyra"
		"commander":
			return "portrait_commander"
		"scholar":
			return "portrait_scholar"
		"merchant":
			return "portrait_merchant"
		"scout":
			return "portrait_scout"
		"blacksmith":
			return "portrait_blacksmith"
		"wizard":
			return "portrait_wizard"
		"king":
			return "portrait_king"

		# Story Bosses
		"shadow scout commander", "shadow scout":
			return "portrait_boss_shadow_scout"
		"storm wraith":
			return "portrait_boss_storm_wraith"
		"stone golem king", "stone golem":
			return "portrait_boss_stone_golem"
		"typhos general":
			return "portrait_boss_typhos_general"
		"void tyrant":
			return "portrait_boss_void_tyrant"

		# Named NPCs
		"elder typhos":
			return "portrait_elder_typhos"
		"lyra the innkeeper", "innkeeper lyra":
			return "portrait_lyra_innkeeper"
		"captain helena", "helena":
			return "portrait_captain_helena"
		"ranger sylva", "sylva":
			return "portrait_ranger_sylva"
		"forgemaster thrain", "thrain":
			return "portrait_forgemaster_thrain"
		"arcanist vera", "vera":
			return "portrait_arcanist_vera"
		"marco the merchant", "marco":
			return "portrait_marco_merchant"
		"the wandering scribe", "wandering scribe":
			return "portrait_wandering_scribe"
		"ghost of the last champion", "last champion":
			return "portrait_ghost_champion"

		# Regional Bosses
		"grove guardian":
			return "portrait_boss_grove_guardian"
		"sunlord champion", "sunlord":
			return "portrait_boss_sunlord"
		"citadel warden":
			return "portrait_boss_citadel_warden"
		"fen seer":
			return "portrait_boss_fen_seer"
		"eternal scribe":
			return "portrait_boss_eternal_scribe"
		"flame tyrant":
			return "portrait_boss_flame_tyrant"
		"frost empress":
			return "portrait_boss_frost_empress"
		"ancient treant":
			return "portrait_boss_ancient_treant"

		_:
			return "portrait_lyra"  # Default to Lyra

## Get portrait texture for a character
func get_portrait_texture(character: String) -> Texture2D:
	var sprite_id := get_portrait_sprite_id(character)
	return get_texture(sprite_id)

## Preload commonly used textures
func preload_battle_textures() -> void:
	var battle_ids := [
		"bld_castle", "enemy_runner", "enemy_brute", "enemy_flyer",
		"fx_projectile", "fx_hit_flash", "fx_magic_bolt"
	]
	for id in battle_ids:
		var _tex := get_texture(id)

func preload_grid_textures() -> void:
	var grid_ids := [
		"bld_wall", "bld_tower_arrow", "bld_tower_slow",
		"bld_barracks", "bld_library", "bld_gate",
		"enemy_runner", "enemy_brute", "enemy_flyer",
		"tile_grass", "tile_forest", "tile_mountain", "tile_water"
	]
	for id in grid_ids:
		var _tex := get_texture(id)

## Animation Frame Loading Support

## Check if a sprite has animation data
func has_animation(sprite_id: String) -> bool:
	return animations.has(sprite_id)

## Get animation frame count for a sprite
func get_animation_frame_count(sprite_id: String) -> int:
	if not animations.has(sprite_id):
		return 1
	var entry: Dictionary = animations[sprite_id]
	var anim_info: Dictionary = entry.get("animation", {})
	return anim_info.get("frame_count", 1)

## Get a specific animation frame texture
## frame_index is 0-based
func get_animation_frame(sprite_id: String, frame_index: int) -> Texture2D:
	var entry: Dictionary = animations.get(sprite_id, {})
	if entry.is_empty():
		# Fallback to base texture if no animation
		return get_texture(sprite_id)

	var frames: Array = entry.get("source_svg_frames", [])
	var anim_info: Dictionary = entry.get("animation", {})
	var frame_count: int = anim_info.get("frame_count", 1)

	# Clamp frame index
	frame_index = clampi(frame_index, 0, frame_count - 1)

	# Try to load from frames array paths
	if frames.size() > frame_index:
		var frame_path: String = frames[frame_index]

		# Try PNG first (if converted)
		var png_path := _svg_to_png_path(frame_path)
		if _texture_cache.has(png_path):
			return _texture_cache[png_path]
		var tex := load(png_path) as Texture2D
		if tex != null:
			_texture_cache[png_path] = tex
			return tex

		# Try SVG directly (Godot imports these as textures)
		if _texture_cache.has(frame_path):
			return _texture_cache[frame_path]
		tex = load(frame_path) as Texture2D
		if tex != null:
			_texture_cache[frame_path] = tex
			return tex

	# Fallback: try frame_XX naming convention
	var frame_id := "%s_%02d" % [sprite_id, frame_index + 1]
	if _texture_cache.has(frame_id):
		return _texture_cache[frame_id]

	# Try to find texture with frame suffix
	var base_entry: Dictionary = _find_entry(sprite_id)
	if not base_entry.is_empty():
		var base_path: String = base_entry.get("path", "")
		if not base_path.is_empty():
			var ext_pos := base_path.rfind(".")
			if ext_pos > 0:
				var frame_path := base_path.insert(ext_pos, "_%02d" % [frame_index + 1])
				var tex := load(frame_path) as Texture2D
				if tex != null:
					_texture_cache[frame_id] = tex
					return tex

	# Ultimate fallback: return base texture
	return get_texture(sprite_id)

## Preload all frames for an animation
func preload_animation_frames(sprite_id: String) -> Array[Texture2D]:
	if _animation_frame_cache.has(sprite_id):
		return _animation_frame_cache[sprite_id]

	var frame_count := get_animation_frame_count(sprite_id)
	var frames: Array[Texture2D] = []

	for i in range(frame_count):
		var tex := get_animation_frame(sprite_id, i)
		if tex != null:
			frames.append(tex)

	_animation_frame_cache[sprite_id] = frames
	return frames

## Convert SVG source path to PNG output path
func _svg_to_png_path(svg_path: String) -> String:
	# res://assets/art/src-svg/sprites/anim/enemy_runner_walk_01.svg
	# -> res://assets/sprites/enemy_runner_walk_01.png
	var path := svg_path.replace("/art/src-svg/", "/")
	path = path.replace("/anim/", "/")
	path = path.replace(".svg", ".png")
	return path

## Get enemy animation sprite ID based on animation type
func get_enemy_animation_id(kind: String, anim_type: String) -> String:
	var base_id := get_enemy_sprite_id(kind)
	var anim_id := "%s_%s" % [base_id, anim_type]
	if animations.has(anim_id):
		return anim_id
	return ""

## Get building animation sprite ID based on animation type
func get_building_animation_id(building_type: String, anim_type: String) -> String:
	var base_id := get_building_sprite_id(building_type)
	var anim_id := "%s_%s" % [base_id, anim_type]
	if animations.has(anim_id):
		return anim_id
	return ""

## Preload common animation textures
func preload_animation_textures() -> void:
	var anim_ids := [
		"enemy_runner_walk", "enemy_runner_death",
		"enemy_brute_walk", "enemy_brute_death",
		"enemy_flyer_hover", "enemy_flyer_death",
		"bld_tower_arrow_fire", "bld_tower_slow_pulse"
	]
	for id in anim_ids:
		if animations.has(id):
			var _frames := preload_animation_frames(id)
