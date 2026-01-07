class_name SimEventTables
extends RefCounted

const GameState = preload("res://sim/types.gd")
const SimRng = preload("res://sim/rng.gd")

const TABLES_PATH := "res://data/events/event_tables.json"

static var _tables_cache: Dictionary = {}
static var _loaded: bool = false

static func load_tables() -> void:
	if _loaded:
		return
	_tables_cache = {}
	var file := FileAccess.open(TABLES_PATH, FileAccess.READ)
	if file == null:
		push_warning("SimEventTables: Could not load tables from %s" % TABLES_PATH)
		_loaded = true
		return
	var content: String = file.get_as_text()
	file.close()
	var json := JSON.new()
	var error: int = json.parse(content)
	if error != OK:
		push_warning("SimEventTables: JSON parse error: %s" % json.get_error_message())
		_loaded = true
		return
	var data: Dictionary = json.data
	var tables_array: Array = data.get("tables", [])
	for table_data in tables_array:
		if typeof(table_data) != TYPE_DICTIONARY:
			continue
		var table_id: String = str(table_data.get("id", ""))
		if table_id != "":
			_tables_cache[table_id] = table_data
	_loaded = true

static func get_table(table_id: String) -> Dictionary:
	load_tables()
	return _tables_cache.get(table_id, {})

static func check_conditions(state: GameState, conditions: Array) -> bool:
	for condition in conditions:
		if typeof(condition) != TYPE_DICTIONARY:
			continue
		var cond_type: String = str(condition.get("type", ""))
		match cond_type:
			"day_range":
				var min_day: int = int(condition.get("min", 1))
				var max_day: int = int(condition.get("max", 999))
				if state.day < min_day or state.day > max_day:
					return false
			"resource_min":
				var resource: String = str(condition.get("resource", ""))
				var min_amount: int = int(condition.get("amount", 0))
				var current: int = int(state.resources.get(resource, 0))
				if current < min_amount:
					return false
			"flag_set":
				var flag: String = str(condition.get("flag", ""))
				var expected: bool = bool(condition.get("value", true))
				var actual: bool = bool(state.event_flags.get(flag, false))
				if actual != expected:
					return false
			"flag_not_set":
				var flag: String = str(condition.get("flag", ""))
				if state.event_flags.has(flag) and bool(state.event_flags[flag]):
					return false
	return true

static func is_event_on_cooldown(state: GameState, event_id: String) -> bool:
	if not state.event_cooldowns.has(event_id):
		return false
	var cooldown_until: int = int(state.event_cooldowns[event_id])
	return state.day < cooldown_until

static func filter_entries(state: GameState, entries: Array) -> Array:
	var result: Array = []
	for entry in entries:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var event_id: String = str(entry.get("event_id", ""))
		if event_id == "":
			continue
		if is_event_on_cooldown(state, event_id):
			continue
		var conditions: Array = entry.get("conditions", [])
		if not check_conditions(state, conditions):
			continue
		result.append(entry)
	return result

static func select_event(state: GameState, table_id: String) -> String:
	var table: Dictionary = get_table(table_id)
	if table.is_empty():
		return ""
	# Check table-level conditions
	var table_conditions: Array = table.get("conditions", [])
	if not check_conditions(state, table_conditions):
		return ""
	var entries: Array = table.get("entries", [])
	var filtered: Array = filter_entries(state, entries)
	if filtered.is_empty():
		return ""
	# Calculate total weight
	var total_weight: int = 0
	for entry in filtered:
		total_weight += int(entry.get("weight", 1))
	if total_weight <= 0:
		return ""
	# Roll weighted selection
	var roll: int = SimRng.roll_range(state, 1, total_weight)
	var running: int = 0
	for entry in filtered:
		running += int(entry.get("weight", 1))
		if roll <= running:
			return str(entry.get("event_id", ""))
	return ""

static func set_cooldown(state: GameState, event_id: String, cooldown_days: int) -> void:
	if cooldown_days <= 0:
		return
	state.event_cooldowns[event_id] = state.day + cooldown_days

static func clear_cooldown(state: GameState, event_id: String) -> void:
	if state.event_cooldowns.has(event_id):
		state.event_cooldowns.erase(event_id)

static func decrement_cooldowns(state: GameState) -> void:
	var to_remove: Array[String] = []
	for event_id in state.event_cooldowns:
		var cooldown_until: int = int(state.event_cooldowns[event_id])
		if state.day >= cooldown_until:
			to_remove.append(str(event_id))
	for event_id in to_remove:
		state.event_cooldowns.erase(event_id)
