class_name SimTowerSynergies
extends RefCounted
## Tower synergy system for bonus effects when towers are placed adjacently.
## Detects combinations and calculates bonus multipliers.

const SimMap = preload("res://sim/map.gd")
const SimBuildings = preload("res://sim/buildings.gd")

# =============================================================================
# SYNERGY DEFINITIONS
# =============================================================================

## All possible synergy types with their requirements and effects
const SYNERGIES := {
	"lightning_chain": {
		"name": "Chain Resonance",
		"description": "Two adjacent Lightning towers amplify chain damage",
		"required_towers": ["auto_spark", "auto_spark"],
		"min_count": 2,
		"adjacency": "pair",  # Two must be adjacent to each other
		"effects": {
			"chain_damage_bonus": 0.50  # +50% chain damage
		},
		"icon": "⚡⚡",
		"color": Color(0.4, 0.7, 1.0)
	},
	"fire_frost": {
		"name": "Thermal Shock",
		"description": "Fire and Frost towers cause extended burns on slowed enemies",
		"required_towers": ["auto_ember", "auto_thorns"],
		"min_count": 2,
		"adjacency": "pair",
		"effects": {
			"burn_duration_bonus": 1.0  # +100% burn duration
		},
		"icon": "🔥❄",
		"color": Color(0.9, 0.5, 0.3)
	},
	"siege_support": {
		"name": "Artillery Network",
		"description": "Siege tower with adjacent Sentry gains accuracy",
		"required_towers": ["auto_ballista", "auto_sentry"],
		"min_count": 2,
		"adjacency": "pair",
		"effects": {
			"accuracy_bonus": 0.25,  # +25% hit chance
			"splash_bonus": 0.20    # +20% splash radius
		},
		"icon": "🎯",
		"color": Color(0.7, 0.5, 0.3)
	},
	"storm_cluster": {
		"name": "Storm Nexus",
		"description": "Three Lightning-type towers create a devastating storm",
		"required_towers": ["auto_spark", "auto_tempest"],
		"min_count": 3,
		"adjacency": "cluster",  # All must be within range of each other
		"effects": {
			"chain_count_bonus": 2,   # +2 chain targets
			"stun_chance_bonus": 0.15  # +15% stun chance
		},
		"icon": "⛈",
		"color": Color(0.3, 0.5, 0.9)
	},
	"defense_triangle": {
		"name": "Defensive Formation",
		"description": "Three towers in triangle formation create a defense aura",
		"required_towers": ["any", "any", "any"],
		"min_count": 3,
		"adjacency": "triangle",
		"effects": {
			"defense_aura": 0.20,  # +20% defense in area
			"hp_regen": 0.05      # 5% HP regen per wave
		},
		"icon": "🛡",
		"color": Color(0.4, 0.8, 0.5)
	},
	"flame_wall": {
		"name": "Inferno Line",
		"description": "Two Fire towers in a line create a wall of flame",
		"required_towers": ["auto_ember", "auto_ember"],
		"min_count": 2,
		"adjacency": "pair",
		"effects": {
			"burn_damage_bonus": 0.30,  # +30% burn damage
			"area_denial": true         # Leaves burning ground
		},
		"icon": "🔥🔥",
		"color": Color(1.0, 0.4, 0.2)
	},
	"nature_growth": {
		"name": "Living Barrier",
		"description": "Two Nature towers enhance root effects",
		"required_towers": ["auto_thorns", "auto_grove"],
		"min_count": 2,
		"adjacency": "pair",
		"effects": {
			"root_chance_bonus": 0.20,  # +20% root chance
			"slow_bonus": 0.15          # +15% slow effect
		},
		"icon": "🌿🌿",
		"color": Color(0.3, 0.7, 0.3)
	},
	"apex_predator": {
		"name": "Apex Network",
		"description": "Apex tower with supporting towers gains adaptive bonus",
		"required_towers": ["auto_apex", "any"],
		"min_count": 2,
		"adjacency": "supported",  # Apex in center
		"effects": {
			"adaptive_speed_bonus": 0.25,  # +25% adaptation speed
			"damage_bonus": 0.10           # +10% base damage
		},
		"icon": "👁",
		"color": Color(0.9, 0.3, 0.9)
	}
}

## Tower types grouped by damage element
const TOWER_ELEMENTS := {
	"lightning": ["auto_spark", "auto_tempest"],
	"fire": ["auto_ember", "auto_inferno"],
	"nature": ["auto_thorns", "auto_grove"],
	"physical": ["auto_sentry", "auto_ballista", "tower"],
	"siege": ["auto_ballista", "auto_bastion"],
	"adaptive": ["auto_apex"]
}


# =============================================================================
# SYNERGY DETECTION
# =============================================================================

## Find all active synergies in the current game state
static func find_active_synergies(state) -> Array:
	var active := []
	var tower_positions := _get_tower_positions(state)

	if tower_positions.is_empty():
		return active

	# Check each synergy type
	for synergy_id in SYNERGIES:
		var synergy_def: Dictionary = SYNERGIES[synergy_id]
		var instances := _find_synergy_instances(state, tower_positions, synergy_id, synergy_def)

		for instance in instances:
			active.append({
				"id": synergy_id,
				"name": synergy_def.name,
				"description": synergy_def.description,
				"effects": synergy_def.effects,
				"towers": instance.towers,
				"positions": instance.positions,
				"icon": synergy_def.get("icon", ""),
				"color": synergy_def.get("color", Color.WHITE)
			})

	return active


## Get all tower positions from state
static func _get_tower_positions(state) -> Dictionary:
	var result := {}  # {index: tower_type}

	for key in state.structures.keys():
		var building_type: String = str(state.structures[key])
		if _is_tower_type(building_type):
			result[int(key)] = building_type

	return result


## Check if a building type is a tower
static func _is_tower_type(building_type: String) -> bool:
	if building_type == "tower":
		return true
	if building_type.begins_with("auto_"):
		return true
	return false


## Find instances of a specific synergy
static func _find_synergy_instances(state, tower_positions: Dictionary, synergy_id: String, synergy_def: Dictionary) -> Array:
	var instances := []
	var required: Array = synergy_def.required_towers
	var min_count: int = synergy_def.min_count
	var adjacency_type: String = synergy_def.get("adjacency", "pair")

	match adjacency_type:
		"pair":
			instances = _find_pair_synergies(state, tower_positions, required)
		"cluster":
			instances = _find_cluster_synergies(state, tower_positions, required, min_count)
		"triangle":
			instances = _find_triangle_synergies(state, tower_positions)
		"supported":
			instances = _find_supported_synergies(state, tower_positions, required)

	return instances


## Find pair synergies (two adjacent towers)
static func _find_pair_synergies(state, tower_positions: Dictionary, required: Array) -> Array:
	var instances := []
	var checked_pairs := {}  # Avoid duplicate pairs

	for index in tower_positions.keys():
		var tower_type: String = tower_positions[index]
		if not _matches_requirement(tower_type, required[0]):
			continue

		var pos := SimMap.pos_from_index(index, state.map_w)
		var neighbors := SimMap.neighbors4(pos, state.map_w, state.map_h)

		for neighbor_pos in neighbors:
			var neighbor_index: int = SimMap.idx(neighbor_pos.x, neighbor_pos.y, state.map_w)

			if not tower_positions.has(neighbor_index):
				continue

			var neighbor_type: String = tower_positions[neighbor_index]
			if not _matches_requirement(neighbor_type, required[1] if required.size() > 1 else required[0]):
				continue

			# Create sorted pair key to avoid duplicates
			var pair_key := "%d-%d" % [mini(index, neighbor_index), maxi(index, neighbor_index)]
			if checked_pairs.has(pair_key):
				continue
			checked_pairs[pair_key] = true

			instances.append({
				"towers": [tower_type, neighbor_type],
				"positions": [pos, neighbor_pos]
			})

	return instances


## Find cluster synergies (multiple towers near each other)
static func _find_cluster_synergies(state, tower_positions: Dictionary, required: Array, min_count: int) -> Array:
	var instances := []
	var visited := {}

	for index in tower_positions.keys():
		if visited.has(index):
			continue

		var cluster := _flood_fill_towers(state, tower_positions, index, visited)

		if cluster.size() >= min_count:
			# Check if cluster has required tower types
			var has_required := true
			for req in required:
				if req == "any":
					continue
				var found := false
				for tower_data in cluster:
					if _matches_requirement(tower_data.type, req):
						found = true
						break
				if not found:
					has_required = false
					break

			if has_required:
				var towers := []
				var positions := []
				for tower_data in cluster:
					towers.append(tower_data.type)
					positions.append(tower_data.pos)
				instances.append({
					"towers": towers,
					"positions": positions
				})

	return instances


## Flood fill to find connected towers
static func _flood_fill_towers(state, tower_positions: Dictionary, start_index: int, visited: Dictionary) -> Array:
	var cluster := []
	var queue := [start_index]

	while not queue.is_empty():
		var index: int = queue.pop_front()
		if visited.has(index):
			continue
		visited[index] = true

		if not tower_positions.has(index):
			continue

		var pos := SimMap.pos_from_index(index, state.map_w)
		cluster.append({"index": index, "type": tower_positions[index], "pos": pos})

		# Check neighbors
		var neighbors := SimMap.neighbors4(pos, state.map_w, state.map_h)
		for neighbor_pos in neighbors:
			var neighbor_index: int = SimMap.idx(neighbor_pos.x, neighbor_pos.y, state.map_w)
			if tower_positions.has(neighbor_index) and not visited.has(neighbor_index):
				queue.append(neighbor_index)

	return cluster


## Find triangle synergies (3 towers forming a triangle)
static func _find_triangle_synergies(state, tower_positions: Dictionary) -> Array:
	var instances := []
	var tower_list := tower_positions.keys()

	# Need at least 3 towers
	if tower_list.size() < 3:
		return instances

	# Check all combinations of 3 towers
	for i in range(tower_list.size()):
		for j in range(i + 1, tower_list.size()):
			for k in range(j + 1, tower_list.size()):
				var idx1: int = tower_list[i]
				var idx2: int = tower_list[j]
				var idx3: int = tower_list[k]

				var pos1 := SimMap.pos_from_index(idx1, state.map_w)
				var pos2 := SimMap.pos_from_index(idx2, state.map_w)
				var pos3 := SimMap.pos_from_index(idx3, state.map_w)

				# Check if they form a valid triangle (all within 2 tiles of each other)
				if _is_valid_triangle(pos1, pos2, pos3):
					instances.append({
						"towers": [tower_positions[idx1], tower_positions[idx2], tower_positions[idx3]],
						"positions": [pos1, pos2, pos3]
					})

	return instances


## Check if three positions form a valid triangle
static func _is_valid_triangle(p1: Vector2i, p2: Vector2i, p3: Vector2i) -> bool:
	var d12 := _manhattan_distance(p1, p2)
	var d23 := _manhattan_distance(p2, p3)
	var d13 := _manhattan_distance(p1, p3)

	# All sides must be 1-2 tiles (adjacent or diagonal)
	return d12 <= 2 and d23 <= 2 and d13 <= 2 and d12 >= 1 and d23 >= 1 and d13 >= 1


## Find supported synergies (center tower with supporting towers)
static func _find_supported_synergies(state, tower_positions: Dictionary, required: Array) -> Array:
	var instances := []

	for index in tower_positions.keys():
		var tower_type: String = tower_positions[index]
		if not _matches_requirement(tower_type, required[0]):
			continue

		var pos := SimMap.pos_from_index(index, state.map_w)
		var neighbors := SimMap.neighbors4(pos, state.map_w, state.map_h)
		var supporting := []

		for neighbor_pos in neighbors:
			var neighbor_index: int = SimMap.idx(neighbor_pos.x, neighbor_pos.y, state.map_w)
			if tower_positions.has(neighbor_index):
				var neighbor_type: String = tower_positions[neighbor_index]
				if _matches_requirement(neighbor_type, required[1] if required.size() > 1 else "any"):
					supporting.append({"type": neighbor_type, "pos": neighbor_pos})

		if not supporting.is_empty():
			var towers := [tower_type]
			var positions := [pos]
			for s in supporting:
				towers.append(s.type)
				positions.append(s.pos)
			instances.append({
				"towers": towers,
				"positions": positions
			})

	return instances


## Check if a tower type matches a requirement
static func _matches_requirement(tower_type: String, requirement: String) -> bool:
	if requirement == "any":
		return true
	if requirement == tower_type:
		return true

	# Check element groupings
	for element in TOWER_ELEMENTS:
		if requirement == element:
			return tower_type in TOWER_ELEMENTS[element]

	return false


## Manhattan distance between two positions
static func _manhattan_distance(p1: Vector2i, p2: Vector2i) -> int:
	return absi(p1.x - p2.x) + absi(p1.y - p2.y)


# =============================================================================
# EFFECT CALCULATION
# =============================================================================

## Get combined synergy effects for a specific tower
static func get_tower_synergy_effects(state, tower_index: int) -> Dictionary:
	var effects := {}
	var active_synergies := find_active_synergies(state)
	var tower_pos := SimMap.pos_from_index(tower_index, state.map_w)

	for synergy in active_synergies:
		var positions: Array = synergy.positions
		var tower_involved := false

		for pos in positions:
			if pos == tower_pos:
				tower_involved = true
				break

		if tower_involved:
			# Merge effects
			for effect_key in synergy.effects:
				var effect_value = synergy.effects[effect_key]
				if effects.has(effect_key):
					# Stack effects (additive for numeric, OR for boolean)
					if typeof(effect_value) == TYPE_BOOL:
						effects[effect_key] = effects[effect_key] or effect_value
					else:
						effects[effect_key] = effects[effect_key] + effect_value
				else:
					effects[effect_key] = effect_value

	return effects


## Get synergy-modified damage for a tower
static func get_modified_damage(state, tower_index: int, base_damage: float) -> float:
	var effects := get_tower_synergy_effects(state, tower_index)
	var modified := base_damage

	if effects.has("damage_bonus"):
		modified *= (1.0 + effects.damage_bonus)
	if effects.has("chain_damage_bonus"):
		modified *= (1.0 + effects.chain_damage_bonus)
	if effects.has("burn_damage_bonus"):
		modified *= (1.0 + effects.burn_damage_bonus)

	return modified


## Get synergy-modified burn duration
static func get_modified_burn_duration(state, tower_index: int, base_duration: float) -> float:
	var effects := get_tower_synergy_effects(state, tower_index)
	var modified := base_duration

	if effects.has("burn_duration_bonus"):
		modified *= (1.0 + effects.burn_duration_bonus)

	return modified


## Get synergy-modified chain count
static func get_modified_chain_count(state, tower_index: int, base_count: int) -> int:
	var effects := get_tower_synergy_effects(state, tower_index)
	var modified := base_count

	if effects.has("chain_count_bonus"):
		modified += int(effects.chain_count_bonus)

	return modified


# =============================================================================
# STATE MANAGEMENT
# =============================================================================

## Update active synergies in game state
static func update_state_synergies(state) -> void:
	state.active_synergies = find_active_synergies(state)


## Get synergy info for UI display
static func get_synergy_display_info(state) -> Array:
	var info := []
	var active := find_active_synergies(state)

	for synergy in active:
		info.append({
			"name": synergy.name,
			"description": synergy.description,
			"icon": synergy.get("icon", ""),
			"color": synergy.get("color", Color.WHITE),
			"tower_count": synergy.towers.size(),
			"effects": _format_effects(synergy.effects)
		})

	return info


## Format effects for display
static func _format_effects(effects: Dictionary) -> Array:
	var formatted := []

	for key in effects:
		var value = effects[key]
		var text: String

		match key:
			"chain_damage_bonus":
				text = "+%d%% chain damage" % int(value * 100)
			"burn_duration_bonus":
				text = "+%d%% burn duration" % int(value * 100)
			"burn_damage_bonus":
				text = "+%d%% burn damage" % int(value * 100)
			"damage_bonus":
				text = "+%d%% damage" % int(value * 100)
			"accuracy_bonus":
				text = "+%d%% accuracy" % int(value * 100)
			"splash_bonus":
				text = "+%d%% splash radius" % int(value * 100)
			"chain_count_bonus":
				text = "+%d chain targets" % int(value)
			"stun_chance_bonus":
				text = "+%d%% stun chance" % int(value * 100)
			"defense_aura":
				text = "+%d%% defense aura" % int(value * 100)
			"hp_regen":
				text = "+%d%% HP regen" % int(value * 100)
			"root_chance_bonus":
				text = "+%d%% root chance" % int(value * 100)
			"slow_bonus":
				text = "+%d%% slow effect" % int(value * 100)
			"adaptive_speed_bonus":
				text = "+%d%% adaptation" % int(value * 100)
			"area_denial":
				text = "Area denial active" if value else ""
			_:
				text = "%s: %s" % [key, str(value)]

		if not text.is_empty():
			formatted.append(text)

	return formatted


## Check if placing a tower would create any new synergies
static func preview_synergies(state, pos: Vector2i, tower_type: String) -> Array:
	# Create a temporary state with the new tower
	var temp_structures: Dictionary = state.structures.duplicate()
	var temp_index: int = SimMap.idx(pos.x, pos.y, state.map_w)
	temp_structures[temp_index] = tower_type

	# Create a mock state for synergy checking
	var mock_state := {
		"structures": temp_structures,
		"map_w": state.map_w,
		"map_h": state.map_h
	}

	# Find synergies with the new tower
	var new_synergies := find_active_synergies(mock_state)

	# Filter to only synergies involving the new position
	var relevant := []
	for synergy in new_synergies:
		for p in synergy.positions:
			if p == pos:
				relevant.append(synergy)
				break

	return relevant
