class_name SimSynergyDetector
extends RefCounted
## Tower synergy detection system

const GameState = preload("res://sim/types.gd")
const SimTowerTypes = preload("res://sim/tower_types.gd")
const SimMap = preload("res://sim/map.gd")
const SimEnemies = preload("res://sim/enemies.gd")

# =============================================================================
# SYNERGY DEFINITIONS
# =============================================================================

## All synergy definitions with requirements
const SYNERGIES := {
	"fire_ice": {
		"id": "fire_ice",
		"name": "Fire & Ice",
		"description": "Frozen enemies take 3x fire damage, burning enemies take 3x cold damage",
		"required_towers": [SimTowerTypes.TOWER_FROST],
		"any_of_towers": [],  # Requires fire damage tower nearby (implicit from combat)
		"min_count": {},
		"proximity": 5,
		"effects": {
			"frozen_fire_mult": 3.0,
			"burning_cold_mult": 3.0
		}
	},
	"arrow_rain": {
		"id": "arrow_rain",
		"name": "Arrow Rain",
		"description": "3 Arrow Towers coordinate a devastating rain of arrows every 15s",
		"required_towers": [],
		"any_of_towers": [],
		"min_count": {SimTowerTypes.TOWER_ARROW: 3},
		"proximity": 6,
		"effects": {
			"coordinated_attack_interval": 15.0,
			"coordinated_attack_mult": 2.0
		}
	},
	"arcane_support": {
		"id": "arcane_support",
		"name": "Arcane Support",
		"description": "Support Tower boosts Arcane Tower accuracy scaling by 50%",
		"required_towers": [SimTowerTypes.TOWER_SUPPORT, SimTowerTypes.TOWER_ARCANE],
		"any_of_towers": [],
		"min_count": {},
		"proximity": 4,
		"effects": {
			"accuracy_scaling_bonus": 0.5
		}
	},
	"holy_purification": {
		"id": "holy_purification",
		"name": "Holy Purification",
		"description": "Holy + Purifier: 2x purify chance, purified enemies explode",
		"required_towers": [SimTowerTypes.TOWER_HOLY, SimTowerTypes.TOWER_PURIFIER],
		"any_of_towers": [],
		"min_count": {},
		"proximity": 5,
		"effects": {
			"purify_chance_mult": 2.0,
			"purify_explosion": true,
			"purify_explosion_damage": 20
		}
	},
	"chain_reaction": {
		"id": "chain_reaction",
		"name": "Chain Reaction",
		"description": "Tesla + Magic: +3 chain jumps, no damage falloff",
		"required_towers": [SimTowerTypes.TOWER_TESLA, SimTowerTypes.TOWER_MAGIC],
		"any_of_towers": [],
		"min_count": {},
		"proximity": 4,
		"effects": {
			"extra_chain_jumps": 3,
			"no_chain_falloff": true
		}
	},
	"kill_box": {
		"id": "kill_box",
		"name": "Kill Box",
		"description": "Slow + Cannon + Poison: +25% damage to slowed enemies in the zone",
		"required_towers": [SimTowerTypes.TOWER_FROST, SimTowerTypes.TOWER_CANNON, SimTowerTypes.TOWER_POISON],
		"any_of_towers": [],
		"min_count": {},
		"proximity": 5,
		"effects": {
			"slow_damage_bonus": 0.25
		}
	},
	"legion": {
		"id": "legion",
		"name": "Legion",
		"description": "2 Summoner Towers: +2 max summons, +20% summon stats",
		"required_towers": [],
		"any_of_towers": [],
		"min_count": {SimTowerTypes.TOWER_SUMMONER: 2},
		"proximity": 8,
		"effects": {
			"max_summons_bonus": 2,
			"summon_stat_bonus": 0.2
		}
	},
	"titan_slayer": {
		"id": "titan_slayer",
		"name": "Titan Slayer",
		"description": "Siege + Support + Arcane: 50% faster charge, +100% boss damage",
		"required_towers": [SimTowerTypes.TOWER_SIEGE, SimTowerTypes.TOWER_SUPPORT, SimTowerTypes.TOWER_ARCANE],
		"any_of_towers": [],
		"min_count": {},
		"proximity": 5,
		"effects": {
			"charge_speed_bonus": 0.5,
			"boss_damage_bonus": 1.0
		}
	}
}


# =============================================================================
# SYNERGY DETECTION
# =============================================================================

## Detect all active synergies based on current tower placement
static func detect_synergies(state: GameState) -> Array:
	var active: Array = []

	# Build tower position map
	var tower_positions: Dictionary = _build_tower_position_map(state)

	# Check each synergy
	for synergy_id in SYNERGIES:
		var synergy: Dictionary = SYNERGIES[synergy_id]

		if _check_synergy_requirements(tower_positions, synergy, state):
			var synergy_data: Dictionary = synergy.duplicate(true)

			# Find participating towers
			synergy_data["participating_towers"] = _find_participating_towers(
				tower_positions, synergy, state
			)

			active.append(synergy_data)

	return active


## Update state's active synergies
static func update_synergies(state: GameState) -> void:
	state.active_synergies = detect_synergies(state)


## Check if a specific synergy is active
static func is_synergy_active(state: GameState, synergy_id: String) -> bool:
	for synergy in state.active_synergies:
		if str(synergy.get("id", "")) == synergy_id:
			return true
	return false


## Get synergy effect value
static func get_synergy_effect(state: GameState, synergy_id: String, effect_key: String) -> Variant:
	for synergy in state.active_synergies:
		if str(synergy.get("id", "")) == synergy_id:
			var effects: Dictionary = synergy.get("effects", {})
			return effects.get(effect_key, null)
	return null


# =============================================================================
# INTERNAL HELPERS
# =============================================================================

## Build a map of tower types to their positions
static func _build_tower_position_map(state: GameState) -> Dictionary:
	var map: Dictionary = {}  # {tower_type: [positions]}

	for key in state.structures.keys():
		var building_type: String = str(state.structures[key])

		# Skip non-tower buildings and reference tiles
		if not building_type.begins_with("tower"):
			continue
		if ":ref:" in building_type:
			continue

		var pos: Vector2i = SimMap.pos_from_index(int(key), state.map_w)

		if not map.has(building_type):
			map[building_type] = []
		map[building_type].append({"index": int(key), "pos": pos})

	return map


## Check if synergy requirements are met
static func _check_synergy_requirements(
	tower_positions: Dictionary,
	synergy: Dictionary,
	state: GameState
) -> bool:
	var required: Array = synergy.get("required_towers", [])
	var any_of: Array = synergy.get("any_of_towers", [])
	var min_count: Dictionary = synergy.get("min_count", {})
	var proximity: int = int(synergy.get("proximity", 5))

	# Check required towers all present
	for tower_type in required:
		if not tower_positions.has(tower_type):
			return false
		if tower_positions[tower_type].is_empty():
			return false

	# Check any_of towers (at least one)
	if not any_of.is_empty():
		var found: bool = false
		for tower_type in any_of:
			if tower_positions.has(tower_type) and not tower_positions[tower_type].is_empty():
				found = true
				break
		if not found:
			return false

	# Check minimum counts
	for tower_type in min_count:
		var required_count: int = int(min_count[tower_type])
		if not tower_positions.has(tower_type):
			return false
		if tower_positions[tower_type].size() < required_count:
			return false

	# Check proximity requirements
	if not _check_proximity(tower_positions, synergy, proximity):
		return false

	return true


## Check if towers are within proximity range
static func _check_proximity(
	tower_positions: Dictionary,
	synergy: Dictionary,
	max_distance: int
) -> bool:
	var required: Array = synergy.get("required_towers", [])
	var min_count: Dictionary = synergy.get("min_count", {})

	# For required towers, check if they're all near each other
	if required.size() >= 2:
		var first_type: String = str(required[0])
		if not tower_positions.has(first_type):
			return false

		for first_tower in tower_positions[first_type]:
			var first_pos: Vector2i = first_tower["pos"]
			var all_near: bool = true

			for i in range(1, required.size()):
				var other_type: String = str(required[i])
				if not tower_positions.has(other_type):
					all_near = false
					break

				var found_near: bool = false
				for other_tower in tower_positions[other_type]:
					var other_pos: Vector2i = other_tower["pos"]
					if SimEnemies.manhattan(first_pos, other_pos) <= max_distance:
						found_near = true
						break

				if not found_near:
					all_near = false
					break

			if all_near:
				return true

		return false

	# For min_count synergies, check if enough towers are near each other
	for tower_type in min_count:
		var required_count: int = int(min_count[tower_type])
		if not tower_positions.has(tower_type):
			return false

		var positions: Array = tower_positions[tower_type]
		if positions.size() < required_count:
			return false

		# Check if we can find a group of towers within proximity
		if not _find_tower_cluster(positions, required_count, max_distance):
			return false

	return true


## Find a cluster of towers within proximity
static func _find_tower_cluster(positions: Array, min_count: int, max_distance: int) -> bool:
	if positions.size() < min_count:
		return false

	# For each tower, check if enough other towers are nearby
	for i in range(positions.size()):
		var center: Vector2i = positions[i]["pos"]
		var nearby_count: int = 1  # Count self

		for j in range(positions.size()):
			if i == j:
				continue
			var other: Vector2i = positions[j]["pos"]
			if SimEnemies.manhattan(center, other) <= max_distance:
				nearby_count += 1

		if nearby_count >= min_count:
			return true

	return false


## Find towers participating in a synergy
static func _find_participating_towers(
	tower_positions: Dictionary,
	synergy: Dictionary,
	state: GameState
) -> Array[int]:
	var participants: Array[int] = []
	var required: Array = synergy.get("required_towers", [])
	var min_count: Dictionary = synergy.get("min_count", {})
	var proximity: int = int(synergy.get("proximity", 5))

	# Add required towers
	for tower_type in required:
		if tower_positions.has(tower_type):
			for tower in tower_positions[tower_type]:
				if not tower["index"] in participants:
					participants.append(tower["index"])

	# Add min_count towers
	for tower_type in min_count:
		if tower_positions.has(tower_type):
			for tower in tower_positions[tower_type]:
				if not tower["index"] in participants:
					participants.append(tower["index"])

	return participants


# =============================================================================
# SYNERGY EFFECT QUERIES
# =============================================================================

## Get total damage bonus from all active synergies
static func get_total_damage_bonus(state: GameState, tower_id: String) -> float:
	var bonus: float = 0.0

	# Kill Box: slow damage bonus
	if is_synergy_active(state, "kill_box"):
		# This would be applied during damage calculation based on enemy state
		pass

	# Titan Slayer: boss damage bonus
	if is_synergy_active(state, "titan_slayer") and tower_id == SimTowerTypes.TOWER_SIEGE:
		bonus += float(get_synergy_effect(state, "titan_slayer", "boss_damage_bonus") or 0)

	return bonus


## Check if Fire+Ice synergy affects damage
static func get_fire_ice_multiplier(
	state: GameState,
	damage_type: int,
	enemy: Dictionary
) -> float:
	if not is_synergy_active(state, "fire_ice"):
		return 1.0

	var effects: Variant = get_synergy_effect(state, "fire_ice", "frozen_fire_mult")
	var frozen_mult: float = float(effects) if effects != null else 1.0

	effects = get_synergy_effect(state, "fire_ice", "burning_cold_mult")
	var burning_mult: float = float(effects) if effects != null else 1.0

	# Check enemy status
	var has_frozen: bool = enemy.get("status_effects", {}).has("frozen")
	var has_burning: bool = enemy.get("status_effects", {}).has("burning")

	# Fire damage vs frozen
	if damage_type == SimTowerTypes.DamageType.FIRE and has_frozen:
		return frozen_mult

	# Cold damage vs burning
	if damage_type == SimTowerTypes.DamageType.COLD and has_burning:
		return burning_mult

	return 1.0


## Get extra chain jumps from Chain Reaction synergy
static func get_extra_chain_jumps(state: GameState) -> int:
	if not is_synergy_active(state, "chain_reaction"):
		return 0

	var effect: Variant = get_synergy_effect(state, "chain_reaction", "extra_chain_jumps")
	return int(effect) if effect != null else 0


## Check if chain has no falloff (Chain Reaction synergy)
static func has_no_chain_falloff(state: GameState) -> bool:
	if not is_synergy_active(state, "chain_reaction"):
		return false

	var effect: Variant = get_synergy_effect(state, "chain_reaction", "no_chain_falloff")
	return bool(effect) if effect != null else false


## Get charge speed bonus from Titan Slayer
static func get_charge_speed_bonus(state: GameState) -> float:
	if not is_synergy_active(state, "titan_slayer"):
		return 0.0

	var effect: Variant = get_synergy_effect(state, "titan_slayer", "charge_speed_bonus")
	return float(effect) if effect != null else 0.0


## Get purify chance multiplier from Holy Purification
static func get_purify_chance_multiplier(state: GameState) -> float:
	if not is_synergy_active(state, "holy_purification"):
		return 1.0

	var effect: Variant = get_synergy_effect(state, "holy_purification", "purify_chance_mult")
	return float(effect) if effect != null else 1.0


## Check if purified enemies should explode
static func should_purify_explode(state: GameState) -> bool:
	if not is_synergy_active(state, "holy_purification"):
		return false

	var effect: Variant = get_synergy_effect(state, "holy_purification", "purify_explosion")
	return bool(effect) if effect != null else false


## Get Arrow Rain timer and check if ready
static func check_arrow_rain(state: GameState, delta: float) -> Dictionary:
	if not is_synergy_active(state, "arrow_rain"):
		return {"ready": false}

	var interval: Variant = get_synergy_effect(state, "arrow_rain", "coordinated_attack_interval")
	var attack_interval: float = float(interval) if interval != null else 15.0

	state.arrow_rain_timer += delta

	if state.arrow_rain_timer >= attack_interval:
		state.arrow_rain_timer = 0.0
		var mult: Variant = get_synergy_effect(state, "arrow_rain", "coordinated_attack_mult")
		return {
			"ready": true,
			"damage_mult": float(mult) if mult != null else 2.0
		}

	return {
		"ready": false,
		"time_remaining": attack_interval - state.arrow_rain_timer
	}


# =============================================================================
# UI HELPERS
# =============================================================================

## Get list of all synergy IDs
static func get_all_synergy_ids() -> Array[String]:
	var ids: Array[String] = []
	for id in SYNERGIES:
		ids.append(str(id))
	return ids


## Get synergy definition by ID
static func get_synergy_definition(synergy_id: String) -> Dictionary:
	if SYNERGIES.has(synergy_id):
		return SYNERGIES[synergy_id].duplicate(true)
	return {}


## Get formatted synergy info for UI
static func get_synergy_display_info(synergy_id: String) -> Dictionary:
	var synergy: Dictionary = get_synergy_definition(synergy_id)
	if synergy.is_empty():
		return {}

	return {
		"name": synergy.get("name", synergy_id),
		"description": synergy.get("description", ""),
		"required_towers": synergy.get("required_towers", []),
		"min_count": synergy.get("min_count", {})
	}
