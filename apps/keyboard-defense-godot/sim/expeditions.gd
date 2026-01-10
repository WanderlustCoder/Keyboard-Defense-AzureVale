class_name SimExpeditions
extends RefCounted

## Worker expedition system - send workers on timed gathering trips.
## Workers become unavailable during expedition but return with resources.

const EXPEDITIONS_PATH := "res://data/expeditions.json"

# Expedition states
const STATE_TRAVELING := "traveling"
const STATE_GATHERING := "gathering"
const STATE_RETURNING := "returning"
const STATE_COMPLETE := "complete"
const STATE_FAILED := "failed"

static var _expedition_data: Dictionary = {}
static var _loaded: bool = false


static func _load_if_needed() -> void:
	if _loaded:
		return
	if not FileAccess.file_exists(EXPEDITIONS_PATH):
		push_warning("SimExpeditions: Expedition data not found at %s" % EXPEDITIONS_PATH)
		_loaded = true
		return
	var file := FileAccess.open(EXPEDITIONS_PATH, FileAccess.READ)
	if file == null:
		push_warning("SimExpeditions: Failed to open expedition data")
		_loaded = true
		return
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	if err != OK:
		push_warning("SimExpeditions: JSON parse error: %s" % json.get_error_message())
		_loaded = true
		return
	_expedition_data = json.data
	_loaded = true


static func get_expedition_definition(expedition_id: String) -> Dictionary:
	_load_if_needed()
	var expeditions: Array = _expedition_data.get("expeditions", [])
	for exp in expeditions:
		if str(exp.get("id", "")) == expedition_id:
			return exp
	return {}


static func get_available_expeditions(state: GameState) -> Array:
	## Get list of expeditions available to start based on current state.
	_load_if_needed()
	var available: Array = []
	var expeditions: Array = _expedition_data.get("expeditions", [])

	for exp in expeditions:
		# Check day requirement
		if state.day < int(exp.get("min_day", 1)):
			continue

		# Check building requirements
		var requires: Array = exp.get("requires", [])
		var meets_requirements := true
		for req in requires:
			if not state.buildings.has(req) or state.buildings[req] <= 0:
				meets_requirements = false
				break

		if meets_requirements:
			available.append(exp)

	return available


static func get_workers_on_expedition(state: GameState) -> int:
	## Get total workers currently assigned to expeditions.
	var total := 0
	for exp in state.active_expeditions:
		total += int(exp.get("workers_assigned", 0))
	return total


static func available_workers_for_expedition(state: GameState) -> int:
	## Get workers available to assign to new expeditions.
	var assigned := SimWorkers.total_assigned(state) if Engine.has_singleton("SimWorkers") else 0
	var on_expedition := get_workers_on_expedition(state)
	return maxi(0, state.total_workers - assigned - on_expedition)


static func can_start_expedition(state: GameState, expedition_id: String, worker_count: int) -> Dictionary:
	## Check if an expedition can be started. Returns {ok: bool, error: String}.
	var definition := get_expedition_definition(expedition_id)
	if definition.is_empty():
		return {"ok": false, "error": "Unknown expedition: %s" % expedition_id}

	# Check day phase
	if state.phase != "day":
		return {"ok": false, "error": "Can only start expeditions during day phase."}

	# Check worker count range
	var min_workers: int = int(definition.get("min_workers", 1))
	var max_workers: int = int(definition.get("max_workers", 1))
	if worker_count < min_workers:
		return {"ok": false, "error": "Expedition requires at least %d workers." % min_workers}
	if worker_count > max_workers:
		return {"ok": false, "error": "Expedition supports at most %d workers." % max_workers}

	# Check worker availability
	var available := available_workers_for_expedition(state)
	if worker_count > available:
		return {"ok": false, "error": "Not enough available workers. Have %d, need %d." % [available, worker_count]}

	# Check building requirements
	var requires: Array = definition.get("requires", [])
	for req in requires:
		if not state.buildings.has(req) or state.buildings[req] <= 0:
			return {"ok": false, "error": "Requires a %s building." % req}

	# Check day requirement
	if state.day < int(definition.get("min_day", 1)):
		return {"ok": false, "error": "Expedition not yet available."}

	return {"ok": true}


static func start_expedition(state: GameState, expedition_id: String, worker_count: int) -> Dictionary:
	## Start an expedition. Returns {ok: bool, ...} with expedition data on success.
	var check := can_start_expedition(state, expedition_id, worker_count)
	if not check.get("ok", false):
		return check

	var definition := get_expedition_definition(expedition_id)
	var duration: float = float(definition.get("duration_seconds", 180))

	var expedition := {
		"id": state.expedition_next_id,
		"expedition_type_id": expedition_id,
		"workers_assigned": worker_count,
		"start_day": state.day,
		"state": STATE_TRAVELING,
		"progress": 0.0,
		"duration_remaining": duration,
		"total_duration": duration,
		"yields": {},
		"events_triggered": []
	}

	state.expedition_next_id += 1
	state.active_expeditions.append(expedition)

	return {
		"ok": true,
		"expedition": expedition,
		"label": str(definition.get("label", expedition_id)),
		"duration_text": _format_duration(duration)
	}


static func tick_expeditions(state: GameState, delta: float) -> Array[String]:
	## Tick all active expeditions. Returns array of event messages.
	var events: Array[String] = []
	var completed_indices: Array[int] = []

	for i in range(state.active_expeditions.size()):
		var exp: Dictionary = state.active_expeditions[i]
		exp["duration_remaining"] = float(exp.get("duration_remaining", 0)) - delta
		exp["progress"] = 1.0 - (float(exp["duration_remaining"]) / float(exp.get("total_duration", 1)))

		# Update state based on progress
		if exp["progress"] < 0.33:
			exp["state"] = STATE_TRAVELING
		elif exp["progress"] < 0.67:
			exp["state"] = STATE_GATHERING
		else:
			exp["state"] = STATE_RETURNING

		# Check completion
		if exp["duration_remaining"] <= 0:
			exp["state"] = STATE_COMPLETE
			completed_indices.append(i)

	# Process completions (reverse order to preserve indices)
	completed_indices.reverse()
	for idx in completed_indices:
		var result := complete_expedition(state, state.active_expeditions[idx]["id"])
		if result.get("ok", false):
			events.append(result.get("message", "Expedition completed."))

	return events


static func complete_expedition(state: GameState, expedition_id: int) -> Dictionary:
	## Complete an expedition and award resources.
	var exp_index := -1
	var expedition: Dictionary = {}

	for i in range(state.active_expeditions.size()):
		if state.active_expeditions[i].get("id") == expedition_id:
			exp_index = i
			expedition = state.active_expeditions[i]
			break

	if exp_index < 0:
		return {"ok": false, "error": "Expedition not found."}

	var definition := get_expedition_definition(str(expedition.get("expedition_type_id", "")))
	if definition.is_empty():
		state.active_expeditions.remove_at(exp_index)
		return {"ok": false, "error": "Unknown expedition type."}

	# Calculate yields
	var yields := calculate_expedition_yield(state, definition, int(expedition.get("workers_assigned", 1)))

	# Check for risk events
	var risk_chance: float = float(definition.get("risk_chance", 0.0))
	var risk_occurred := SimRng.roll_float(state) < risk_chance
	var risk_message := ""

	if risk_occurred:
		var risk_effect: Dictionary = definition.get("risk_effect", {})
		risk_message = _apply_risk_effect(state, risk_effect, yields)

	# Apply yields to state
	for resource in yields.keys():
		var amount: int = int(yields[resource])
		if resource == "gold":
			state.gold += amount
		elif state.resources.has(resource):
			state.resources[resource] += amount

	# Record in history
	var history_entry := {
		"expedition_type_id": expedition.get("expedition_type_id"),
		"day_completed": state.day,
		"workers": expedition.get("workers_assigned"),
		"yields": yields,
		"had_risk": risk_occurred
	}
	state.expedition_history.append(history_entry)
	if state.expedition_history.size() > 10:
		state.expedition_history.pop_front()

	# Remove from active
	state.active_expeditions.remove_at(exp_index)

	# Build message
	var yield_parts: Array[String] = []
	for resource in yields.keys():
		if int(yields[resource]) > 0:
			yield_parts.append("+%d %s" % [int(yields[resource]), resource])

	var message := "Expedition '%s' completed! %s" % [
		str(definition.get("label", "Unknown")),
		", ".join(yield_parts) if not yield_parts.is_empty() else "No resources gathered."
	]
	if risk_message != "":
		message += " " + risk_message

	return {"ok": true, "message": message, "yields": yields}


static func calculate_expedition_yield(state: GameState, definition: Dictionary, workers: int) -> Dictionary:
	## Calculate resource yield for an expedition based on worker count.
	var yields: Dictionary = {}
	var base_yield: Dictionary = definition.get("base_yield", {})
	var bonus_yield: Dictionary = definition.get("bonus_yield", {})
	var worker_bonus: float = float(definition.get("worker_bonus", 0.4))
	var min_workers: int = int(definition.get("min_workers", 1))

	# Base yield
	for resource in base_yield.keys():
		yields[resource] = int(base_yield[resource])

	# Worker bonus: extra workers beyond minimum provide bonus
	var extra_workers := workers - min_workers
	if extra_workers > 0:
		var bonus_mult: float = 1.0 + (extra_workers * worker_bonus)
		for resource in yields.keys():
			yields[resource] = int(float(yields[resource]) * bonus_mult)

		# Add bonus yield items
		for resource in bonus_yield.keys():
			var bonus_amount: int = int(float(bonus_yield[resource]) * (extra_workers * 0.5))
			yields[resource] = yields.get(resource, 0) + bonus_amount

	return yields


static func cancel_expedition(state: GameState, expedition_id: int) -> Dictionary:
	## Cancel an active expedition. Workers return immediately, partial refund.
	var exp_index := -1

	for i in range(state.active_expeditions.size()):
		if state.active_expeditions[i].get("id") == expedition_id:
			exp_index = i
			break

	if exp_index < 0:
		return {"ok": false, "error": "Expedition not found."}

	var expedition: Dictionary = state.active_expeditions[exp_index]
	var progress: float = float(expedition.get("progress", 0.0))

	# Partial yield based on progress (only if past traveling phase)
	var partial_yield: Dictionary = {}
	if progress > 0.33:
		var definition := get_expedition_definition(str(expedition.get("expedition_type_id", "")))
		var full_yield := calculate_expedition_yield(state, definition, int(expedition.get("workers_assigned", 1)))
		var yield_mult := (progress - 0.33) / 0.67  # 0 at 33%, 1 at 100%
		for resource in full_yield.keys():
			partial_yield[resource] = int(float(full_yield[resource]) * yield_mult * 0.5)  # 50% of earned

	# Apply partial yields
	for resource in partial_yield.keys():
		var amount: int = int(partial_yield[resource])
		if resource == "gold":
			state.gold += amount
		elif state.resources.has(resource):
			state.resources[resource] += amount

	state.active_expeditions.remove_at(exp_index)

	var message := "Expedition cancelled. Workers returned."
	if not partial_yield.is_empty():
		var parts: Array[String] = []
		for resource in partial_yield.keys():
			if int(partial_yield[resource]) > 0:
				parts.append("+%d %s" % [int(partial_yield[resource]), resource])
		if not parts.is_empty():
			message += " Partial yield: " + ", ".join(parts)

	return {"ok": true, "message": message}


static func get_expedition_status(state: GameState, expedition_id: int) -> Dictionary:
	## Get detailed status of a specific expedition.
	for exp in state.active_expeditions:
		if exp.get("id") == expedition_id:
			var definition := get_expedition_definition(str(exp.get("expedition_type_id", "")))
			return {
				"ok": true,
				"expedition": exp,
				"label": str(definition.get("label", "Unknown")),
				"state_label": _get_state_label(str(exp.get("state", ""))),
				"progress_percent": int(float(exp.get("progress", 0)) * 100),
				"time_remaining": _format_duration(float(exp.get("duration_remaining", 0)))
			}
	return {"ok": false, "error": "Expedition not found."}


static func get_active_count(state: GameState) -> int:
	return state.active_expeditions.size()


static func _apply_risk_effect(state: GameState, effect: Dictionary, yields: Dictionary) -> String:
	## Apply a risk event effect. Returns description message.
	var effect_type: String = str(effect.get("type", ""))

	match effect_type:
		"worker_injury":
			# Worker becomes unavailable for duration (simplified: just report it)
			return "A worker was injured!"
		"resource_spoil":
			var spoil_amount: int = int(effect.get("amount", 0))
			for resource in yields.keys():
				yields[resource] = maxi(0, int(yields[resource]) - spoil_amount)
			return "Some resources spoiled during the journey."
		"bandit_attack":
			var gold_loss: int = int(effect.get("gold_loss", 0))
			yields["gold"] = maxi(0, yields.get("gold", 0) - gold_loss)
			return "Bandits attacked! Lost some gold."
		"combat_encounter":
			# Could trigger combat, for now just reduce yields
			for resource in yields.keys():
				yields[resource] = int(float(yields[resource]) * 0.7)
			return "Encountered hostile creatures!"
		"cave_in":
			# Serious risk - major yield reduction
			for resource in yields.keys():
				yields[resource] = int(float(yields[resource]) * 0.5)
			return "Cave-in occurred! Lost significant resources."
		_:
			return ""


static func _get_state_label(state_str: String) -> String:
	match state_str:
		STATE_TRAVELING:
			return "Traveling..."
		STATE_GATHERING:
			return "Gathering resources"
		STATE_RETURNING:
			return "Returning home"
		STATE_COMPLETE:
			return "Complete!"
		STATE_FAILED:
			return "Failed"
		_:
			return "Unknown"


static func _format_duration(seconds: float) -> String:
	var mins := int(seconds) / 60
	var secs := int(seconds) % 60
	if mins > 0:
		return "%dm %ds" % [mins, secs]
	return "%ds" % secs
