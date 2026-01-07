class_name SimEvents
extends RefCounted

const GameState = preload("res://sim/types.gd")
const SimEventTables = preload("res://sim/event_tables.gd")
const SimEventEffects = preload("res://sim/event_effects.gd")
const SimPoi = preload("res://sim/poi.gd")

const EVENTS_PATH := "res://data/events/events.json"

static var _events_cache: Dictionary = {}
static var _loaded: bool = false

static func load_events() -> void:
	if _loaded:
		return
	_events_cache = {}
	var file := FileAccess.open(EVENTS_PATH, FileAccess.READ)
	if file == null:
		push_warning("SimEvents: Could not load events from %s" % EVENTS_PATH)
		_loaded = true
		return
	var content: String = file.get_as_text()
	file.close()
	var json := JSON.new()
	var error: int = json.parse(content)
	if error != OK:
		push_warning("SimEvents: JSON parse error: %s" % json.get_error_message())
		_loaded = true
		return
	var data: Dictionary = json.data
	var events_array: Array = data.get("events", [])
	for event_data in events_array:
		if typeof(event_data) != TYPE_DICTIONARY:
			continue
		var event_id: String = str(event_data.get("id", ""))
		if event_id != "":
			_events_cache[event_id] = event_data
	_loaded = true

static func get_event(event_id: String) -> Dictionary:
	load_events()
	return _events_cache.get(event_id, {})

static func get_all_events() -> Array:
	load_events()
	var result: Array = []
	for event_id in _events_cache:
		result.append(_events_cache[event_id])
	return result

static func trigger_event_from_poi(state: GameState, poi_id: String) -> Dictionary:
	var poi_data: Dictionary = SimPoi.get_poi(poi_id)
	if poi_data.is_empty():
		return {"success": false, "error": "poi_not_found"}
	var table_id: String = str(poi_data.get("event_table_id", ""))
	if table_id == "":
		return {"success": false, "error": "no_event_table"}
	var event_id: String = SimEventTables.select_event(state, table_id)
	if event_id == "":
		return {"success": false, "error": "no_valid_event"}
	return start_event(state, event_id, poi_id)

static func start_event(state: GameState, event_id: String, source_poi: String = "") -> Dictionary:
	var event_data: Dictionary = get_event(event_id)
	if event_data.is_empty():
		return {"success": false, "error": "event_not_found"}
	state.pending_event = {
		"event_id": event_id,
		"source_poi": source_poi,
		"started_day": state.day,
		"choice_index": -1,
		"input_progress": "",
		"resolved": false
	}
	return {
		"success": true,
		"event_id": event_id,
		"event": event_data
	}

static func get_pending_event(state: GameState) -> Dictionary:
	if state.pending_event.is_empty():
		return {}
	var event_id: String = str(state.pending_event.get("event_id", ""))
	return get_event(event_id)

static func has_pending_event(state: GameState) -> bool:
	return not state.pending_event.is_empty() and not state.pending_event.get("resolved", true)

static func get_choice(event_data: Dictionary, choice_id: String) -> Dictionary:
	var choices: Array = event_data.get("choices", [])
	for choice in choices:
		if typeof(choice) != TYPE_DICTIONARY:
			continue
		if str(choice.get("id", "")) == choice_id:
			return choice
	return {}

static func get_choice_by_index(event_data: Dictionary, index: int) -> Dictionary:
	var choices: Array = event_data.get("choices", [])
	if index < 0 or index >= choices.size():
		return {}
	var choice: Variant = choices[index]
	if typeof(choice) != TYPE_DICTIONARY:
		return {}
	return choice

static func validate_input(choice: Dictionary, input_text: String) -> Dictionary:
	var input_config: Dictionary = choice.get("input", {})
	var mode: String = str(input_config.get("mode", "code"))
	match mode:
		"code":
			var expected: String = str(input_config.get("text", "")).to_lower()
			var actual: String = input_text.to_lower().strip_edges()
			return {
				"valid": actual == expected,
				"complete": actual == expected,
				"partial_match": expected.begins_with(actual) if actual != "" else false
			}
		"phrase":
			var expected: String = str(input_config.get("text", "")).to_lower()
			var actual: String = input_text.to_lower()
			return {
				"valid": actual == expected,
				"complete": actual == expected,
				"partial_match": expected.begins_with(actual) if actual != "" else false
			}
		"prompt_burst":
			var prompts: Array = input_config.get("prompts", [])
			var typed_words: Array = input_text.split(" ", false)
			var matched: int = 0
			for i in range(min(typed_words.size(), prompts.size())):
				if typed_words[i].to_lower() == str(prompts[i]).to_lower():
					matched += 1
			return {
				"valid": matched == prompts.size(),
				"complete": matched == prompts.size(),
				"matched": matched,
				"total": prompts.size()
			}
		"command":
			var expected: String = str(input_config.get("text", "")).to_lower()
			var actual: String = input_text.to_lower().strip_edges()
			return {
				"valid": actual == expected,
				"complete": actual == expected,
				"partial_match": expected.begins_with(actual) if actual != "" else false
			}
		_:
			return {"valid": false, "complete": false, "error": "unknown_mode"}

static func resolve_choice(state: GameState, choice_id: String, input_text: String) -> Dictionary:
	if not has_pending_event(state):
		return {"success": false, "error": "no_pending_event"}
	var event_data: Dictionary = get_pending_event(state)
	if event_data.is_empty():
		return {"success": false, "error": "event_not_found"}
	var choice: Dictionary = get_choice(event_data, choice_id)
	if choice.is_empty():
		return {"success": false, "error": "choice_not_found"}
	var validation: Dictionary = validate_input(choice, input_text)
	if not validation.get("complete", false):
		return {"success": false, "error": "input_incomplete", "validation": validation}
	# Apply effects
	var effects: Array = choice.get("effects", [])
	var results: Array = SimEventEffects.apply_effects(state, effects)
	# Set cooldown
	var cooldown: int = int(event_data.get("cooldown_days", 0))
	var event_id: String = str(state.pending_event.get("event_id", ""))
	SimEventTables.set_cooldown(state, event_id, cooldown)
	# Mark POI as interacted
	var source_poi: String = str(state.pending_event.get("source_poi", ""))
	if source_poi != "" and state.active_pois.has(source_poi):
		var poi_state: Dictionary = state.active_pois[source_poi]
		poi_state["interacted"] = true
		state.active_pois[source_poi] = poi_state
	# Check for chain event
	var next_event_id: String = str(choice.get("next_event_id", ""))
	# Clear pending event
	state.pending_event["resolved"] = true
	state.pending_event["choice_id"] = choice_id
	var result: Dictionary = {
		"success": true,
		"event_id": event_id,
		"choice_id": choice_id,
		"effects_applied": results
	}
	# Start chain event if specified
	if next_event_id != "":
		var chain_result: Dictionary = start_event(state, next_event_id, source_poi)
		result["chain_event"] = chain_result
	else:
		state.pending_event = {}
	return result

static func fail_choice(state: GameState, choice_id: String) -> Dictionary:
	if not has_pending_event(state):
		return {"success": false, "error": "no_pending_event"}
	var event_data: Dictionary = get_pending_event(state)
	if event_data.is_empty():
		return {"success": false, "error": "event_not_found"}
	var choice: Dictionary = get_choice(event_data, choice_id)
	if choice.is_empty():
		return {"success": false, "error": "choice_not_found"}
	# Apply fail effects
	var fail_effects: Array = choice.get("fail_effects", [])
	var results: Array = SimEventEffects.apply_effects(state, fail_effects)
	var event_id: String = str(state.pending_event.get("event_id", ""))
	# Clear pending event
	state.pending_event = {}
	return {
		"success": true,
		"failed": true,
		"event_id": event_id,
		"choice_id": choice_id,
		"effects_applied": results
	}

static func skip_event(state: GameState) -> Dictionary:
	if not has_pending_event(state):
		return {"success": false, "error": "no_pending_event"}
	var event_id: String = str(state.pending_event.get("event_id", ""))
	state.pending_event = {}
	return {
		"success": true,
		"skipped": true,
		"event_id": event_id
	}

static func serialize_pending_event(pending: Dictionary) -> Dictionary:
	if pending.is_empty():
		return {}
	return {
		"event_id": str(pending.get("event_id", "")),
		"source_poi": str(pending.get("source_poi", "")),
		"started_day": int(pending.get("started_day", 0)),
		"choice_index": int(pending.get("choice_index", -1)),
		"input_progress": str(pending.get("input_progress", "")),
		"resolved": bool(pending.get("resolved", false))
	}

static func deserialize_pending_event(raw: Dictionary) -> Dictionary:
	if raw.is_empty():
		return {}
	return {
		"event_id": str(raw.get("event_id", "")),
		"source_poi": str(raw.get("source_poi", "")),
		"started_day": int(raw.get("started_day", 0)),
		"choice_index": int(raw.get("choice_index", -1)),
		"input_progress": str(raw.get("input_progress", "")),
		"resolved": bool(raw.get("resolved", false))
	}
