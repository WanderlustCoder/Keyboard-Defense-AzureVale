extends Node
## Asset Loader - Loads and caches textures from assets_manifest.json

const MANIFEST_PATH := "res://data/assets_manifest.json"

var _manifest: Dictionary = {}
var _texture_cache: Dictionary = {}
var _loaded: bool = false

# Texture lookup tables by category
var sprites: Dictionary = {}
var icons: Dictionary = {}
var tiles: Dictionary = {}
var ui: Dictionary = {}

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
		match category:
			"buildings", "units", "enemies", "decorations", "effects", "npcs":
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
