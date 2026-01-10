class_name SimResearch
extends RefCounted

const GameState = preload("res://sim/types.gd")

var _research_data: Array = []
var _research_by_id: Dictionary = {}
var _loaded: bool = false

func _init() -> void:
	_load_research()

func _load_research() -> void:
	if _loaded:
		return

	var file := FileAccess.open("res://data/research.json", FileAccess.READ)
	if file:
		var json := JSON.new()
		var error := json.parse(file.get_as_text())
		file.close()
		if error == OK:
			var data: Dictionary = json.data
			_research_data = data.get("research", [])
			for item in _research_data:
				_research_by_id[str(item.get("id", ""))] = item
		_loaded = true

# Get all research items
func get_all_research() -> Array:
	return _research_data.duplicate()

# Get a specific research by ID
func get_research(research_id: String) -> Dictionary:
	return _research_by_id.get(research_id, {}).duplicate(true)

# Check if research prerequisites are met
func has_prerequisites(state: GameState, research_id: String) -> bool:
	var research: Dictionary = get_research(research_id)
	if research.is_empty():
		return false

	var requires: Array = research.get("requires", [])
	for req_id in requires:
		if not state.completed_research.has(str(req_id)):
			return false
	return true

# Check if research can be started
func can_start_research(state: GameState, research_id: String) -> Dictionary:
	var result := {"ok": false, "reason": ""}

	var research: Dictionary = get_research(research_id)
	if research.is_empty():
		result.reason = "unknown research"
		return result

	# Check if already completed
	if state.completed_research.has(research_id):
		result.reason = "already completed"
		return result

	# Check if already researching something
	if not state.active_research.is_empty():
		result.reason = "already researching"
		return result

	# Check prerequisites
	if not has_prerequisites(state, research_id):
		result.reason = "prerequisites not met"
		return result

	# Check gold cost
	var cost: Dictionary = research.get("cost", {})
	var gold_cost: int = int(cost.get("gold", 0))
	if state.gold < gold_cost:
		result.reason = "not enough gold"
		return result

	result.ok = true
	return result

# Start researching
func start_research(state: GameState, research_id: String) -> bool:
	var check: Dictionary = can_start_research(state, research_id)
	if not check.ok:
		return false

	var research: Dictionary = get_research(research_id)
	var cost: Dictionary = research.get("cost", {})
	var gold_cost: int = int(cost.get("gold", 0))

	# Deduct cost
	state.gold -= gold_cost

	# Set active research
	state.active_research = research_id
	state.research_progress = 0

	return true

# Cancel current research (refunds half the gold)
func cancel_research(state: GameState) -> bool:
	if state.active_research.is_empty():
		return false

	var research: Dictionary = get_research(state.active_research)
	var cost: Dictionary = research.get("cost", {})
	var gold_cost: int = int(cost.get("gold", 0))

	# Refund half
	state.gold += int(gold_cost / 2)

	# Clear research
	state.active_research = ""
	state.research_progress = 0

	return true

# Advance research progress (called after each wave)
func advance_research(state: GameState) -> Dictionary:
	var result := {"completed": false, "research_id": "", "effects": {}}

	if state.active_research.is_empty():
		return result

	state.research_progress += 1

	var research: Dictionary = get_research(state.active_research)
	var waves_needed: int = int(research.get("waves_to_complete", 1))

	if state.research_progress >= waves_needed:
		# Research completed
		result.completed = true
		result.research_id = state.active_research
		result.effects = research.get("effects", {})

		state.completed_research.append(state.active_research)
		state.active_research = ""
		state.research_progress = 0

	return result

# Get current research progress as a percentage
func get_progress_percent(state: GameState) -> float:
	if state.active_research.is_empty():
		return 0.0

	var research: Dictionary = get_research(state.active_research)
	var waves_needed: int = int(research.get("waves_to_complete", 1))

	return float(state.research_progress) / float(waves_needed)

# Get all available research (not started, prerequisites met)
func get_available_research(state: GameState) -> Array:
	var available: Array = []

	for item in _research_data:
		var research_id: String = str(item.get("id", ""))

		# Skip completed
		if state.completed_research.has(research_id):
			continue

		# Skip currently researching
		if state.active_research == research_id:
			continue

		# Check prerequisites
		if not has_prerequisites(state, research_id):
			continue

		available.append(item.duplicate(true))

	return available

# Get total research effects from all completed research
func get_total_effects(state: GameState) -> Dictionary:
	var effects := {
		"stone_cost_reduction": 0.0,
		"build_limit_bonus": 0,
		"wall_defense_bonus": 0,
		"build_cost_reduction": 0.0,
		"food_production_bonus": 0.0,
		"gold_production_bonus": 0.0,
		"gold_per_building": 0,
		"resource_multiplier": 0.0,
		"tower_range_bonus": 0,
		"typing_power": 0.0,
		"combo_multiplier": 0.0,
		"tower_damage_bonus": 0,
		"critical_chance": 0.0,
		"wave_heal": 0,
		"planning_time_bonus": 0,
		"perfect_word_crit": false,
		"critical_damage": 0.0,
		"castle_health_bonus": 0,
		"mistake_forgiveness": 0.0
	}

	for research_id in state.completed_research:
		var research: Dictionary = get_research(research_id)
		var research_effects: Dictionary = research.get("effects", {})

		for key in research_effects.keys():
			if effects.has(key):
				var value = research_effects[key]
				if typeof(value) == TYPE_BOOL:
					effects[key] = value
				elif typeof(effects[key]) == TYPE_INT:
					effects[key] = int(effects[key]) + int(value)
				else:
					effects[key] = float(effects[key]) + float(value)

	return effects

# Get research status summary
func get_research_summary(state: GameState) -> Dictionary:
	var summary := {
		"active_research": "",
		"active_label": "",
		"progress": 0,
		"waves_needed": 0,
		"progress_percent": 0.0,
		"completed_count": state.completed_research.size(),
		"total_count": _research_data.size(),
		"available_count": get_available_research(state).size()
	}

	if not state.active_research.is_empty():
		var research: Dictionary = get_research(state.active_research)
		summary.active_research = state.active_research
		summary.active_label = str(research.get("label", ""))
		summary.progress = state.research_progress
		summary.waves_needed = int(research.get("waves_to_complete", 1))
		summary.progress_percent = get_progress_percent(state)

	return summary

# Check if a specific research is completed
func is_completed(state: GameState, research_id: String) -> bool:
	return state.completed_research.has(research_id)

# Get research tree organized by category
func get_research_tree(state: GameState) -> Dictionary:
	var tree := {
		"construction": [],
		"economy": [],
		"military": [],
		"mystical": []
	}

	for item in _research_data:
		var category: String = str(item.get("category", ""))
		var research_id: String = str(item.get("id", ""))

		if not tree.has(category):
			continue

		var entry: Dictionary = item.duplicate(true)
		entry["completed"] = state.completed_research.has(research_id)
		entry["active"] = state.active_research == research_id
		entry["available"] = has_prerequisites(state, research_id) and not entry["completed"]
		entry["can_afford"] = state.gold >= int(item.get("cost", {}).get("gold", 0))

		tree[category].append(entry)

	return tree


# Static instance for convenience
static var _instance: SimResearch = null

static func instance() -> SimResearch:
	if _instance == null:
		_instance = SimResearch.new()
	return _instance
