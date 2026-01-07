class_name SimPoi
extends RefCounted

const GameState = preload("res://sim/types.gd")
const SimRng = preload("res://sim/rng.gd")

const POIS_PATH := "res://data/pois/pois.json"

static var _pois_cache: Dictionary = {}
static var _loaded: bool = false

static func load_pois() -> void:
	if _loaded:
		return
	_pois_cache = {}
	var file := FileAccess.open(POIS_PATH, FileAccess.READ)
	if file == null:
		push_warning("SimPoi: Could not load POIs from %s" % POIS_PATH)
		_loaded = true
		return
	var content: String = file.get_as_text()
	file.close()
	var json := JSON.new()
	var error: int = json.parse(content)
	if error != OK:
		push_warning("SimPoi: JSON parse error in POIs: %s" % json.get_error_message())
		_loaded = true
		return
	var data: Dictionary = json.data
	var pois_array: Array = data.get("pois", [])
	for poi_data in pois_array:
		if typeof(poi_data) != TYPE_DICTIONARY:
			continue
		var poi_id: String = str(poi_data.get("id", ""))
		if poi_id != "":
			_pois_cache[poi_id] = poi_data
	_loaded = true

static func get_poi(poi_id: String) -> Dictionary:
	load_pois()
	return _pois_cache.get(poi_id, {})

static func get_all_pois() -> Array:
	load_pois()
	var result: Array = []
	for poi_id in _pois_cache:
		result.append(_pois_cache[poi_id])
	return result

static func get_pois_for_biome(biome: String) -> Array:
	load_pois()
	var result: Array = []
	for poi_id in _pois_cache:
		var poi: Dictionary = _pois_cache[poi_id]
		if str(poi.get("biome", "")) == biome:
			result.append(poi)
	return result

static func filter_by_day(pois: Array, day: int) -> Array:
	var result: Array = []
	for poi in pois:
		if typeof(poi) != TYPE_DICTIONARY:
			continue
		var min_day: int = int(poi.get("min_day", 1))
		var max_day: int = int(poi.get("max_day", 999))
		if day >= min_day and day <= max_day:
			result.append(poi)
	return result

static func filter_by_tags(pois: Array, required_tags: Array) -> Array:
	if required_tags.is_empty():
		return pois
	var result: Array = []
	for poi in pois:
		if typeof(poi) != TYPE_DICTIONARY:
			continue
		var poi_tags: Array = poi.get("tags", [])
		var has_all: bool = true
		for tag in required_tags:
			if not poi_tags.has(str(tag)):
				has_all = false
				break
		if has_all:
			result.append(poi)
	return result

static func can_spawn_poi(state: GameState, poi: Dictionary) -> bool:
	var poi_id: String = str(poi.get("id", ""))
	if poi_id == "":
		return false
	# Already active
	if state.active_pois.has(poi_id):
		return false
	# Day range check
	var min_day: int = int(poi.get("min_day", 1))
	var max_day: int = int(poi.get("max_day", 999))
	if state.day < min_day or state.day > max_day:
		return false
	return true

static func roll_spawn(state: GameState, poi: Dictionary) -> bool:
	var rarity: int = int(poi.get("rarity", 50))
	var roll: int = SimRng.roll_range(state, 1, 100)
	return roll <= rarity

static func spawn_poi_at(state: GameState, poi_id: String, pos: Vector2i) -> bool:
	var poi: Dictionary = get_poi(poi_id)
	if poi.is_empty():
		return false
	if not can_spawn_poi(state, poi):
		return false
	state.active_pois[poi_id] = {
		"poi_id": poi_id,
		"pos": pos,
		"discovered": false,
		"interacted": false
	}
	return true

static func try_spawn_random_poi(state: GameState, biome: String, pos: Vector2i) -> String:
	var candidates: Array = get_pois_for_biome(biome)
	candidates = filter_by_day(candidates, state.day)
	var spawnable: Array = []
	for poi in candidates:
		if can_spawn_poi(state, poi):
			spawnable.append(poi)
	if spawnable.is_empty():
		return ""
	# Weight by rarity
	var total_weight: int = 0
	for poi in spawnable:
		total_weight += int(poi.get("rarity", 50))
	if total_weight <= 0:
		return ""
	var roll: int = SimRng.roll_range(state, 1, total_weight)
	var running: int = 0
	for poi in spawnable:
		running += int(poi.get("rarity", 50))
		if roll <= running:
			var poi_id: String = str(poi.get("id", ""))
			if spawn_poi_at(state, poi_id, pos):
				return poi_id
			break
	return ""

static func discover_poi(state: GameState, poi_id: String) -> bool:
	if not state.active_pois.has(poi_id):
		return false
	var poi_state: Dictionary = state.active_pois[poi_id]
	if poi_state.get("discovered", false):
		return false
	poi_state["discovered"] = true
	state.active_pois[poi_id] = poi_state
	return true

static func get_poi_at(state: GameState, pos: Vector2i) -> String:
	for poi_id in state.active_pois:
		var poi_state: Dictionary = state.active_pois[poi_id]
		var poi_pos: Variant = poi_state.get("pos", null)
		if poi_pos is Vector2i and poi_pos == pos:
			return poi_id
	return ""

static func get_discovered_pois(state: GameState) -> Array:
	var result: Array = []
	for poi_id in state.active_pois:
		var poi_state: Dictionary = state.active_pois[poi_id]
		if poi_state.get("discovered", false):
			result.append(poi_id)
	return result

static func remove_poi(state: GameState, poi_id: String) -> bool:
	if not state.active_pois.has(poi_id):
		return false
	state.active_pois.erase(poi_id)
	return true

static func serialize_poi_state(poi_state: Dictionary) -> Dictionary:
	var pos: Variant = poi_state.get("pos", Vector2i.ZERO)
	var pos_dict: Dictionary = {"x": 0, "y": 0}
	if pos is Vector2i:
		pos_dict = {"x": pos.x, "y": pos.y}
	return {
		"poi_id": str(poi_state.get("poi_id", "")),
		"pos": pos_dict,
		"discovered": bool(poi_state.get("discovered", false)),
		"interacted": bool(poi_state.get("interacted", false))
	}

static func deserialize_poi_state(raw: Dictionary) -> Dictionary:
	var pos_data: Dictionary = raw.get("pos", {})
	var pos: Vector2i = Vector2i(int(pos_data.get("x", 0)), int(pos_data.get("y", 0)))
	return {
		"poi_id": str(raw.get("poi_id", "")),
		"pos": pos,
		"discovered": bool(raw.get("discovered", false)),
		"interacted": bool(raw.get("interacted", false))
	}
