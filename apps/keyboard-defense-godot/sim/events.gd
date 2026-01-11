class_name SimEvents
extends RefCounted

const GameState = preload("res://sim/types.gd")
const SimEventTables = preload("res://sim/event_tables.gd")
const SimEventEffects = preload("res://sim/event_effects.gd")
const SimPoi = preload("res://sim/poi.gd")
const SimExplorationChallenges = preload("res://sim/exploration_challenges.gd")

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


# =============================================================================
# TYPING CHALLENGE SUPPORT
# =============================================================================

## Create a typing challenge for an event choice
static func create_challenge_for_choice(state: GameState, choice: Dictionary) -> Dictionary:
	var input_config: Dictionary = choice.get("input", {})
	var mode: String = str(input_config.get("mode", ""))

	if mode != "challenge":
		return {}

	var challenge_config: Dictionary = input_config.get("challenge", {})
	return SimExplorationChallenges.generate_challenge(state, challenge_config)


## Check if a choice requires a typing challenge
static func choice_is_challenge(choice: Dictionary) -> bool:
	var input_config: Dictionary = choice.get("input", {})
	return str(input_config.get("mode", "")) == "challenge"


## Get challenge words to display to player
static func get_challenge_words(challenge: Dictionary) -> Array:
	return challenge.get("words", [])


## Get current word in challenge
static func get_current_challenge_word(challenge: Dictionary) -> String:
	var idx: int = int(challenge.get("current_word_index", 0))
	var words: Array = challenge.get("words", [])
	if idx < words.size():
		return str(words[idx])
	return ""


## Process a word typed during a challenge
static func process_challenge_word(challenge: Dictionary, typed_word: String) -> Dictionary:
	return SimExplorationChallenges.process_word(challenge, typed_word)


## Evaluate completed challenge
static func evaluate_challenge(challenge: Dictionary, end_time: float) -> Dictionary:
	return SimExplorationChallenges.evaluate_challenge(challenge, end_time)


## Scale event rewards based on challenge performance
static func scale_event_rewards(state: GameState, choice: Dictionary, evaluation: Dictionary) -> Array:
	var effects: Array = choice.get("effects", [])
	return SimExplorationChallenges.scale_rewards(effects, evaluation, state.day)


## Get challenge description for UI
static func get_challenge_description(challenge: Dictionary) -> String:
	return SimExplorationChallenges.get_challenge_description(challenge)


## Get challenge result description for UI
static func get_challenge_result(evaluation: Dictionary) -> String:
	return SimExplorationChallenges.get_result_description(evaluation)


# =============================================================================
# DIFFICULTY SCALING
# =============================================================================

## Apply difficulty scaling to event based on day and distance from base
static func get_scaled_event(state: GameState, event_data: Dictionary, distance: int = 0) -> Dictionary:
	if event_data.is_empty():
		return event_data

	var scaled: Dictionary = event_data.duplicate(true)
	var day: int = state.day

	# Calculate difficulty multiplier
	var day_mult: float = 1.0 + (float(day - 1) * 0.1)  # 10% per day
	var dist_mult: float = 1.0 + (float(distance) * 0.05)  # 5% per tile from base
	var total_mult: float = day_mult * dist_mult

	# Scale rewards in choices
	var choices: Array = scaled.get("choices", [])
	for i in range(choices.size()):
		if typeof(choices[i]) != TYPE_DICTIONARY:
			continue
		var choice: Dictionary = choices[i]
		var effects: Array = choice.get("effects", [])
		var scaled_effects: Array = _scale_effects(effects, total_mult)
		choice["effects"] = scaled_effects
		choices[i] = choice

	scaled["choices"] = choices
	scaled["difficulty_multiplier"] = total_mult

	return scaled


## Scale effect values
static func _scale_effects(effects: Array, multiplier: float) -> Array:
	var scaled: Array = []
	for effect in effects:
		if typeof(effect) != TYPE_DICTIONARY:
			scaled.append(effect)
			continue

		var effect_copy: Dictionary = effect.duplicate()
		var effect_type: String = str(effect.get("type", ""))

		# Scale numeric rewards
		match effect_type:
			"resource_add", "gold_add", "heal_castle", "ap_add":
				var amount: int = int(effect.get("amount", 0))
				if amount > 0:  # Only scale positive rewards
					effect_copy["amount"] = int(float(amount) * multiplier)

		scaled.append(effect_copy)

	return scaled


## Get event tier based on day (for filtering high-tier events early game)
static func get_event_tier_for_day(day: int) -> int:
	if day <= 3:
		return 1  # Basic events only
	elif day <= 7:
		return 2  # Include uncommon events
	elif day <= 14:
		return 3  # Include rare events
	else:
		return 4  # All events available
