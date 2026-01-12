class_name SimPoi
extends RefCounted

const GameState = preload("res://sim/types.gd")
const SimRng = preload("res://sim/rng.gd")
const SimMap = preload("res://sim/map.gd")

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


## Mark a POI as interacted and set respawn timer
static func mark_interacted(state: GameState, poi_id: String) -> void:
	if not state.active_pois.has(poi_id):
		return
	var poi_state: Dictionary = state.active_pois[poi_id]
	var poi_data: Dictionary = get_poi(poi_id)
	poi_state["interacted"] = true
	poi_state["interacted_day"] = state.day
	# Set respawn day based on POI definition
	var respawn_days: int = int(poi_data.get("respawn_days", 0))
	if respawn_days > 0:
		poi_state["respawn_day"] = state.day + respawn_days
	else:
		poi_state["respawn_day"] = 0  # Never respawns
	state.active_pois[poi_id] = poi_state


## Check and respawn eligible POIs (call at dawn)
static func check_respawns(state: GameState) -> Array[String]:
	var respawned: Array[String] = []
	var pois_to_respawn: Array[String] = []

	for poi_id in state.active_pois:
		var poi_state: Dictionary = state.active_pois[poi_id]
		if not poi_state.get("interacted", false):
			continue
		var respawn_day: int = int(poi_state.get("respawn_day", 0))
		if respawn_day > 0 and state.day >= respawn_day:
			pois_to_respawn.append(poi_id)

	for poi_id in pois_to_respawn:
		var poi_state: Dictionary = state.active_pois[poi_id]
		poi_state["interacted"] = false
		poi_state["respawn_day"] = 0
		poi_state["interacted_day"] = 0
		state.active_pois[poi_id] = poi_state
		respawned.append(poi_id)

	return respawned


## Get time until POI respawns (0 if not interacted or never respawns)
static func get_respawn_remaining(state: GameState, poi_id: String) -> int:
	if not state.active_pois.has(poi_id):
		return 0
	var poi_state: Dictionary = state.active_pois[poi_id]
	if not poi_state.get("interacted", false):
		return 0
	var respawn_day: int = int(poi_state.get("respawn_day", 0))
	if respawn_day <= 0:
		return -1  # Never respawns
	return max(0, respawn_day - state.day)

static func serialize_poi_state(poi_state: Dictionary) -> Dictionary:
	var pos: Variant = poi_state.get("pos", Vector2i.ZERO)
	var pos_dict: Dictionary = {"x": 0, "y": 0}
	if pos is Vector2i:
		pos_dict = {"x": pos.x, "y": pos.y}
	return {
		"poi_id": str(poi_state.get("poi_id", "")),
		"pos": pos_dict,
		"discovered": bool(poi_state.get("discovered", false)),
		"interacted": bool(poi_state.get("interacted", false)),
		"interacted_day": int(poi_state.get("interacted_day", 0)),
		"respawn_day": int(poi_state.get("respawn_day", 0))
	}

static func deserialize_poi_state(raw: Dictionary) -> Dictionary:
	var pos_data: Dictionary = raw.get("pos", {})
	var pos: Vector2i = Vector2i(int(pos_data.get("x", 0)), int(pos_data.get("y", 0)))
	return {
		"poi_id": str(raw.get("poi_id", "")),
		"pos": pos,
		"discovered": bool(raw.get("discovered", false)),
		"interacted": bool(raw.get("interacted", false)),
		"interacted_day": int(raw.get("interacted_day", 0)),
		"respawn_day": int(raw.get("respawn_day", 0))
	}

# ============================================================================
# Zone-Aware POI Functions
# ============================================================================

## Get POI tier (1-4, derived from min_day or explicit tier field)
static func get_poi_tier(poi: Dictionary) -> int:
	# Check for explicit tier
	if poi.has("tier"):
		return clamp(int(poi.get("tier", 1)), 1, 4)
	# Derive from min_day
	var min_day: int = int(poi.get("min_day", 1))
	if min_day <= 5:
		return 1
	elif min_day <= 10:
		return 2
	elif min_day <= 15:
		return 3
	else:
		return 4

## Filter POIs by zone requirements
## Higher tier POIs only spawn in more dangerous zones
static func filter_by_zone(state: GameState, pois: Array, pos: Vector2i) -> Array:
	var zone: String = SimMap.get_zone_at(state, pos)
	var max_tier: int = SimMap.get_zone_enemy_tier_max(zone)
	var result: Array = []
	for poi in pois:
		if typeof(poi) != TYPE_DICTIONARY:
			continue
		var poi_tier: int = get_poi_tier(poi)
		# POI tier must be <= zone max tier
		if poi_tier <= max_tier:
			result.append(poi)
	return result

## Get adjusted rarity for a POI at a position (considering zone bonuses)
static func get_adjusted_rarity(state: GameState, poi: Dictionary, pos: Vector2i) -> int:
	var base_rarity: int = int(poi.get("rarity", 50))
	var zone: String = SimMap.get_zone_at(state, pos)
	var rarity_bonus: int = SimMap.get_zone_poi_rarity_bonus(zone)
	# Positive bonus = more common, negative = rarer but better POIs
	return clamp(base_rarity + rarity_bonus, 1, 100)

## Zone-aware POI spawning - considers zone tier limits and rarity bonuses
static func try_spawn_random_poi_zone_aware(state: GameState, biome: String, pos: Vector2i) -> String:
	var candidates: Array = get_pois_for_biome(biome)
	candidates = filter_by_day(candidates, state.day)
	candidates = filter_by_zone(state, candidates, pos)

	var spawnable: Array = []
	for poi in candidates:
		if can_spawn_poi(state, poi):
			spawnable.append(poi)

	if spawnable.is_empty():
		return ""

	# Weight by adjusted rarity
	var total_weight: int = 0
	for poi in spawnable:
		total_weight += get_adjusted_rarity(state, poi, pos)

	if total_weight <= 0:
		return ""

	var roll: int = SimRng.roll_range(state, 1, total_weight)
	var running: int = 0
	for poi in spawnable:
		running += get_adjusted_rarity(state, poi, pos)
		if roll <= running:
			var poi_id: String = str(poi.get("id", ""))
			if spawn_poi_at(state, poi_id, pos):
				return poi_id
			break
	return ""

## Get POIs valid for a specific zone
static func get_pois_for_zone(zone: String) -> Array:
	load_pois()
	var max_tier: int = SimMap.get_zone_enemy_tier_max(zone)
	var result: Array = []
	for poi_id in _pois_cache:
		var poi: Dictionary = _pois_cache[poi_id]
		var poi_tier: int = get_poi_tier(poi)
		if poi_tier <= max_tier:
			result.append(poi)
	return result

## Count POIs available per zone
static func count_pois_by_zone() -> Dictionary:
	var counts: Dictionary = {}
	for zone in SimMap.get_all_zones():
		counts[zone] = get_pois_for_zone(zone).size()
	return counts

## Get summary of POI distribution by zone
static func format_poi_zone_summary() -> String:
	var counts: Dictionary = count_pois_by_zone()
	var lines: Array[String] = ["POI Distribution by Zone:"]
	for zone in SimMap.get_all_zones():
		var name: String = SimMap.get_zone_name(zone)
		var count: int = int(counts.get(zone, 0))
		lines.append("  %s: %d POIs available" % [name, count])
	return "\n".join(lines)
