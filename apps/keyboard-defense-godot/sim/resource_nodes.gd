class_name SimResourceNodes
extends RefCounted

## POI-based resource harvesting system.
## Resource nodes spawn on terrain and require typing challenges to harvest.

const NODES_PATH := "res://data/resource_nodes.json"
const SimRng = preload("res://sim/rng.gd")

# Challenge types
const CHALLENGE_WORD_BURST := "word_burst"
const CHALLENGE_SPEED_TYPE := "speed_type"
const CHALLENGE_ACCURACY_TEST := "accuracy_test"

static var _node_data: Dictionary = {}
static var _loaded: bool = false


static func _load_if_needed() -> void:
	if _loaded:
		return
	if not FileAccess.file_exists(NODES_PATH):
		push_warning("SimResourceNodes: Node data not found at %s" % NODES_PATH)
		_loaded = true
		return
	var file := FileAccess.open(NODES_PATH, FileAccess.READ)
	if file == null:
		push_warning("SimResourceNodes: Failed to open node data")
		_loaded = true
		return
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	if err != OK:
		push_warning("SimResourceNodes: JSON parse error: %s" % json.get_error_message())
		_loaded = true
		return
	_node_data = json.data
	_loaded = true


static func get_node_type_definition(node_type: String) -> Dictionary:
	_load_if_needed()
	var node_types: Dictionary = _node_data.get("node_types", {})
	return node_types.get(node_type, {})


static func get_spawn_rates_for_terrain(terrain: String) -> Dictionary:
	_load_if_needed()
	var spawn_rates: Dictionary = _node_data.get("spawn_rates", {})
	return spawn_rates.get(terrain, {})


static func try_spawn_random_node(state: GameState, terrain: String, pos: Vector2i) -> String:
	## Try to spawn a random resource node at position based on terrain type.
	## Returns node_id if spawned, empty string otherwise.
	var spawn_rates := get_spawn_rates_for_terrain(terrain)
	if spawn_rates.is_empty():
		return ""

	# Roll for which node type
	var roll: float = float(SimRng.roll_range(state, 0, 1000)) / 1000.0
	var cumulative: float = 0.0
	var selected_type := ""

	for node_type in spawn_rates.keys():
		cumulative += float(spawn_rates[node_type])
		if roll <= cumulative:
			selected_type = node_type
			break

	if selected_type == "":
		return ""

	return spawn_node_at(state, pos, selected_type)


static func spawn_node_at(state: GameState, pos: Vector2i, node_type: String) -> String:
	## Spawn a specific resource node at position. Returns node_id.
	var definition := get_node_type_definition(node_type)
	if definition.is_empty():
		return ""

	var tile_index: int = pos.y * state.map_w + pos.x

	# Don't spawn on existing nodes
	if state.resource_nodes.has(tile_index):
		return ""

	# Don't spawn on structures
	if state.structures.has(tile_index):
		return ""

	var node_id := "node_%d_%d_%d" % [pos.x, pos.y, state.day]

	var node := {
		"node_id": node_id,
		"node_type": node_type,
		"pos_x": pos.x,
		"pos_y": pos.y,
		"tile_index": tile_index,
		"base_yield": definition.get("base_yield", {}).duplicate(),
		"harvests_remaining": int(definition.get("max_harvests", 1)),
		"max_harvests": int(definition.get("max_harvests", 1)),
		"respawn_days": int(definition.get("respawn_days", 5)),
		"discovered": true,
		"last_harvested_day": 0
	}

	state.resource_nodes[tile_index] = node
	return node_id


static func get_node_at(state: GameState, pos: Vector2i) -> Dictionary:
	## Get resource node at position, if any.
	var tile_index: int = pos.y * state.map_w + pos.x
	return state.resource_nodes.get(tile_index, {})


static func can_harvest(state: GameState, pos: Vector2i) -> Dictionary:
	## Check if node at position can be harvested. Returns {ok: bool, error: String}.
	if state.phase != "day":
		return {"ok": false, "error": "Can only harvest during day phase."}

	var node := get_node_at(state, pos)
	if node.is_empty():
		return {"ok": false, "error": "No resource node at this location."}

	var harvests: int = int(node.get("harvests_remaining", 0))
	if harvests <= 0:
		return {"ok": false, "error": "Node is depleted. Wait for respawn."}

	# Check if already harvesting
	if state.pending_event.get("event_id") == "_harvest_challenge":
		return {"ok": false, "error": "Already harvesting a node."}

	return {"ok": true, "node": node}


static func start_harvest_challenge(state: GameState, pos: Vector2i) -> Dictionary:
	## Start a harvest challenge at position. Returns challenge data.
	var check := can_harvest(state, pos)
	if not check.get("ok", false):
		return check

	var node: Dictionary = check["node"]
	var node_type: String = str(node.get("node_type", ""))
	var definition := get_node_type_definition(node_type)

	if definition.is_empty():
		return {"ok": false, "error": "Unknown node type."}

	var challenge: Dictionary = definition.get("challenge", {})
	var challenge_type: String = str(challenge.get("type", CHALLENGE_WORD_BURST))
	var word_theme: String = str(challenge.get("word_theme", "common"))
	var word_count: int = int(challenge.get("word_count", 4))

	# Generate challenge words from theme
	var words := _generate_challenge_words(state, word_theme, word_count)

	var challenge_data := {
		"type": challenge_type,
		"words": words,
		"word_count": word_count,
		"time_limit": float(challenge.get("time_limit", 15)),
		"target_wpm": int(challenge.get("target_wpm", 40)),
		"min_accuracy": float(challenge.get("min_accuracy", 0.9)),
		"node_id": str(node.get("node_id", "")),
		"node_type": node_type,
		"pos_x": pos.x,
		"pos_y": pos.y
	}

	return {
		"ok": true,
		"node_id": str(node.get("node_id", "")),
		"node_name": str(definition.get("name", node_type)),
		"challenge": challenge_data,
		"challenge_description": _get_challenge_description(challenge_data),
		"challenge_words": words
	}


static func complete_harvest(state: GameState, pos: Vector2i, performance: Dictionary) -> Dictionary:
	## Complete a harvest based on performance. Returns yields.
	var tile_index: int = pos.y * state.map_w + pos.x
	if not state.resource_nodes.has(tile_index):
		return {"ok": false, "error": "No node at position."}

	var node: Dictionary = state.resource_nodes[tile_index]
	var node_type: String = str(node.get("node_type", ""))
	var definition := get_node_type_definition(node_type)

	# Calculate performance multiplier
	var multiplier: float = _calculate_performance_multiplier(performance)

	# Calculate yields
	var base_yield: Dictionary = node.get("base_yield", {})
	var yields: Dictionary = {}

	for resource in base_yield.keys():
		var amount: int = int(float(base_yield[resource]) * multiplier)
		if amount > 0:
			yields[resource] = amount

	# Apply bonus effect if any
	var bonus_effect: Dictionary = definition.get("bonus_effect", {})
	if not bonus_effect.is_empty() and multiplier >= 1.5:
		_apply_bonus_effect(state, bonus_effect)

	# Apply yields to state
	for resource in yields.keys():
		var amount: int = int(yields[resource])
		if resource == "gold":
			state.gold += amount
		elif state.resources.has(resource):
			state.resources[resource] += amount

	# Update node state
	node["harvests_remaining"] = int(node.get("harvests_remaining", 1)) - 1
	node["last_harvested_day"] = state.day

	# Remove if depleted
	if node["harvests_remaining"] <= 0:
		state.harvested_nodes[str(node.get("node_id", ""))] = state.day
		state.resource_nodes.erase(tile_index)

	# Build result
	var yield_parts: Array[String] = []
	for resource in yields.keys():
		yield_parts.append("+%d %s" % [int(yields[resource]), resource])

	var quality_label := _get_performance_label(multiplier)

	return {
		"ok": true,
		"yields": yields,
		"multiplier": multiplier,
		"quality": quality_label,
		"message": "%s harvest! %s" % [quality_label, ", ".join(yield_parts) if not yield_parts.is_empty() else "Nothing gathered."],
		"depleted": node.get("harvests_remaining", 0) <= 0
	}


static func tick_node_respawns(state: GameState) -> void:
	## Check and respawn depleted nodes based on respawn timers.
	var nodes_to_respawn: Array[String] = []

	for node_id in state.harvested_nodes.keys():
		var depleted_day: int = int(state.harvested_nodes[node_id])
		# Would need node definition to know respawn days
		# For now, use a default respawn time
		if state.day - depleted_day >= 5:
			nodes_to_respawn.append(node_id)

	for node_id in nodes_to_respawn:
		state.harvested_nodes.erase(node_id)
		# Note: The node would need to be re-discovered/spawned
		# This is a simplified implementation


static func get_discovered_nodes(state: GameState) -> Array:
	## Get list of all discovered resource nodes.
	var nodes: Array = []
	for tile_index in state.resource_nodes.keys():
		var node: Dictionary = state.resource_nodes[tile_index]
		if node.get("discovered", false):
			nodes.append(node)
	return nodes


static func _generate_challenge_words(state: GameState, theme: String, count: int) -> Array:
	## Generate words for a harvest challenge based on theme.
	_load_if_needed()
	var themes: Dictionary = _node_data.get("challenge_word_themes", {})
	var word_pool: Array = themes.get(theme, ["word", "type", "fast", "good"])

	var words: Array = []
	var available := word_pool.duplicate()

	for i in range(count):
		if available.is_empty():
			available = word_pool.duplicate()
		var idx: int = SimRng.roll_range(state, 0, available.size() - 1)
		words.append(str(available[idx]))
		available.remove_at(idx)

	return words


static func _calculate_performance_multiplier(performance: Dictionary) -> float:
	## Calculate yield multiplier based on challenge performance.
	var passed: bool = performance.get("passed", false)
	if not passed:
		return 0.5  # Failed challenge = 50% yield

	var accuracy: float = float(performance.get("accuracy", 0.0))
	var wpm: float = float(performance.get("wpm", 0.0))
	var time_remaining: float = float(performance.get("time_remaining", 0.0))

	# Base multiplier for passing
	var mult := 1.0

	# Accuracy bonus
	if accuracy >= 1.0:
		mult += 0.5  # Perfect accuracy
	elif accuracy >= 0.95:
		mult += 0.25

	# Speed bonus (if applicable)
	if wpm >= 60:
		mult += 0.25
	elif wpm >= 45:
		mult += 0.1

	# Time bonus
	if time_remaining > 5:
		mult += 0.15

	return minf(2.0, mult)  # Cap at 200%


static func _get_performance_label(multiplier: float) -> String:
	if multiplier >= 2.0:
		return "Perfect"
	elif multiplier >= 1.5:
		return "Excellent"
	elif multiplier >= 1.25:
		return "Good"
	elif multiplier >= 1.0:
		return "Standard"
	else:
		return "Poor"


static func _get_challenge_description(challenge: Dictionary) -> String:
	var challenge_type: String = str(challenge.get("type", ""))
	match challenge_type:
		CHALLENGE_WORD_BURST:
			return "Type %d words within %d seconds!" % [
				int(challenge.get("word_count", 4)),
				int(challenge.get("time_limit", 15))
			]
		CHALLENGE_SPEED_TYPE:
			return "Maintain %d WPM across %d words!" % [
				int(challenge.get("target_wpm", 40)),
				int(challenge.get("word_count", 5))
			]
		CHALLENGE_ACCURACY_TEST:
			return "Type %d words with %d%% accuracy!" % [
				int(challenge.get("word_count", 6)),
				int(float(challenge.get("min_accuracy", 0.9)) * 100)
			]
		_:
			return "Complete the typing challenge!"


static func _apply_bonus_effect(state: GameState, effect: Dictionary) -> void:
	## Apply bonus effect from excellent harvest performance.
	var effect_type: String = str(effect.get("type", ""))
	match effect_type:
		"heal_castle":
			var amount: int = int(effect.get("amount", 1))
			state.hp = mini(state.hp + amount, 10)  # Cap at max HP
		_:
			pass
