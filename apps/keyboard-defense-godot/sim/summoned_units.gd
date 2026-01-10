class_name SimSummonedUnits
extends RefCounted
## Summoned unit management system for Summoner towers

const GameState = preload("res://sim/types.gd")
const SimEnemies = preload("res://sim/enemies.gd")
const SimMap = preload("res://sim/map.gd")
const SimTowerTypes = preload("res://sim/tower_types.gd")
const SimStatusEffects = preload("res://sim/status_effects.gd")

# =============================================================================
# CONSTANTS
# =============================================================================

const MAX_SUMMONS_PER_TOWER := 3
const DEFAULT_SUMMON_DURATION := 30  # seconds
const SUMMON_ATTACK_RANGE := 1  # melee range

# =============================================================================
# SUMMON MANAGEMENT
# =============================================================================

## Create a new summoned unit
static func create_summon(
	state: GameState,
	summon_type: String,
	pos: Vector2i,
	owner_index: int,
	level: int
) -> Dictionary:
	var type_data: Dictionary = SimTowerTypes.get_summon_type(summon_type)

	var summon := {
		"id": state.summoned_next_id,
		"type": summon_type,
		"pos": pos,
		"hp": int(type_data.get("hp", 50)) + (level - 1) * 10,
		"hp_max": int(type_data.get("hp", 50)) + (level - 1) * 10,
		"damage": int(type_data.get("damage", 8)) + (level - 1) * 2,
		"attack_speed": float(type_data.get("attack_speed", 1.0)),
		"movement_speed": int(type_data.get("movement_speed", 1)),
		"range": int(type_data.get("range", SUMMON_ATTACK_RANGE)),
		"owner_index": owner_index,
		"attack_cooldown": 0.0,
		"duration": float(type_data.get("duration", DEFAULT_SUMMON_DURATION)),
		"spawn_time": Time.get_ticks_msec() / 1000.0
	}

	# Copy special abilities from type data
	if type_data.get("flying", false):
		summon["flying"] = true
	if type_data.get("taunt", false):
		summon["taunt"] = true
	if type_data.get("aoe", false):
		summon["aoe"] = true
		summon["aoe_radius"] = int(type_data.get("aoe_radius", 1))

	state.summoned_next_id += 1
	return summon


## Add a summon to the state
static func spawn_summon(
	state: GameState,
	summon_type: String,
	pos: Vector2i,
	owner_index: int,
	level: int,
	events: Array[String]
) -> bool:
	# Check max summons for this tower
	var current_count: int = count_summons_for_tower(state, owner_index)
	var max_summons: int = get_max_summons(state, owner_index)

	if current_count >= max_summons:
		return false

	var summon: Dictionary = create_summon(state, summon_type, pos, owner_index, level)
	state.summoned_units.append(summon)

	# Track summon ID for the tower
	if not state.tower_summon_ids.has(owner_index):
		state.tower_summon_ids[owner_index] = []
	state.tower_summon_ids[owner_index].append(summon.id)

	var type_data: Dictionary = SimTowerTypes.get_summon_type(summon_type)
	var display_name: String = str(type_data.get("name", summon_type.capitalize()))
	events.append("%s summoned at (%d,%d)!" % [display_name, pos.x, pos.y])

	return true


## Count summons belonging to a tower
static func count_summons_for_tower(state: GameState, owner_index: int) -> int:
	var count: int = 0
	for summon in state.summoned_units:
		if int(summon.get("owner_index", -1)) == owner_index:
			count += 1
	return count


## Get max summons for a tower (affected by synergies)
static func get_max_summons(state: GameState, owner_index: int) -> int:
	var base_max: int = MAX_SUMMONS_PER_TOWER

	# Check for Legion synergy (+2 max summons)
	for synergy in state.active_synergies:
		if str(synergy.get("synergy_id", "")) == "legion":
			base_max += 2
			break

	return base_max


## Remove a summon by ID
static func remove_summon(state: GameState, summon_id: int) -> void:
	for i in range(state.summoned_units.size() - 1, -1, -1):
		if int(state.summoned_units[i].get("id", 0)) == summon_id:
			var owner: int = int(state.summoned_units[i].get("owner_index", -1))
			state.summoned_units.remove_at(i)

			# Remove from tower tracking
			if state.tower_summon_ids.has(owner):
				var ids: Array = state.tower_summon_ids[owner]
				var idx: int = ids.find(summon_id)
				if idx >= 0:
					ids.remove_at(idx)
			break


## Remove all summons belonging to a tower
static func remove_tower_summons(state: GameState, owner_index: int) -> void:
	for i in range(state.summoned_units.size() - 1, -1, -1):
		if int(state.summoned_units[i].get("owner_index", -1)) == owner_index:
			state.summoned_units.remove_at(i)

	if state.tower_summon_ids.has(owner_index):
		state.tower_summon_ids.erase(owner_index)


# =============================================================================
# SUMMON AI TICK
# =============================================================================

## Process all summoned units for one tick
static func tick_summons(
	state: GameState,
	delta: float,
	events: Array[String]
) -> void:
	if state.summoned_units.is_empty():
		return

	var dist_field: PackedInt32Array = SimMap.compute_dist_to_base(state)
	var expired: Array[int] = []
	var current_time: float = Time.get_ticks_msec() / 1000.0

	for i in range(state.summoned_units.size()):
		var summon: Dictionary = state.summoned_units[i]
		var summon_id: int = int(summon.get("id", 0))

		# Check duration expiry
		var spawn_time: float = float(summon.get("spawn_time", 0))
		var duration: float = float(summon.get("duration", DEFAULT_SUMMON_DURATION))
		if current_time - spawn_time > duration:
			expired.append(summon_id)
			continue

		# Update attack cooldown
		var cooldown: float = float(summon.get("attack_cooldown", 0))
		if cooldown > 0:
			summon["attack_cooldown"] = max(0, cooldown - delta)

		# Try to attack nearby enemy
		if float(summon.get("attack_cooldown", 0)) <= 0:
			var attacked: bool = _summon_attack(state, summon, events)
			if attacked:
				var attack_speed: float = float(summon.get("attack_speed", 1.0))
				summon["attack_cooldown"] = 1.0 / attack_speed
		else:
			# Move toward nearest enemy if not attacking
			_summon_move(state, summon, dist_field)

		state.summoned_units[i] = summon

	# Remove expired summons
	for summon_id in expired:
		remove_summon(state, summon_id)
		events.append("Summon faded away.")


## Summon attacks nearby enemies
static func _summon_attack(
	state: GameState,
	summon: Dictionary,
	events: Array[String]
) -> bool:
	if state.enemies.is_empty():
		return false

	var summon_pos: Vector2i = summon.get("pos", Vector2i.ZERO)
	var attack_range: int = int(summon.get("range", SUMMON_ATTACK_RANGE))
	var damage: int = int(summon.get("damage", 8))
	var summon_type: String = str(summon.get("type", "skeleton"))

	# Apply Legion synergy bonus
	for synergy in state.active_synergies:
		if str(synergy.get("synergy_id", "")) == "legion":
			damage = int(float(damage) * 1.2)  # +20% damage
			break

	# Find target - prioritize enemies with taunt targeting this summon
	var target_index: int = -1
	var best_dist: int = 999999

	# If summon has taunt, enemies should prioritize attacking it
	var has_taunt: bool = summon.get("taunt", false)

	for i in range(state.enemies.size()):
		var enemy: Dictionary = state.enemies[i]
		var enemy_pos: Vector2i = enemy.get("pos", Vector2i.ZERO)
		var dist: int = SimEnemies.manhattan(summon_pos, enemy_pos)

		if dist <= attack_range and dist < best_dist:
			best_dist = dist
			target_index = i

	if target_index < 0:
		return false

	# Attack!
	var enemy: Dictionary = state.enemies[target_index]
	var enemy_id: int = int(enemy.get("id", 0))
	var enemy_kind: String = str(enemy.get("kind", "enemy"))

	# AoE attack for certain summon types
	if summon.get("aoe", false):
		var aoe_radius: int = int(summon.get("aoe_radius", 1))
		var center: Vector2i = enemy.get("pos", Vector2i.ZERO)
		var hit_count: int = 0

		# Hit all enemies in radius
		for i in range(state.enemies.size() - 1, -1, -1):
			var e: Dictionary = state.enemies[i]
			var e_pos: Vector2i = e.get("pos", Vector2i.ZERO)
			if SimEnemies.manhattan(center, e_pos) <= aoe_radius:
				e = SimEnemies.apply_damage(e, damage, state)
				state.enemies[i] = e
				hit_count += 1

				if int(e.get("hp", 0)) <= 0:
					state.enemies.remove_at(i)

		var type_data: Dictionary = SimTowerTypes.get_summon_type(summon_type)
		var display_name: String = str(type_data.get("name", summon_type.capitalize()))
		events.append("%s cleaves for %d damage, hitting %d enemies!" % [display_name, damage, hit_count])
	else:
		# Single target attack
		enemy = SimEnemies.apply_damage(enemy, damage, state)
		state.enemies[target_index] = enemy

		var type_data: Dictionary = SimTowerTypes.get_summon_type(summon_type)
		var display_name: String = str(type_data.get("name", summon_type.capitalize()))
		events.append("%s hits %s#%d for %d damage." % [display_name, enemy_kind, enemy_id, damage])

		if int(enemy.get("hp", 0)) <= 0:
			state.enemies.remove_at(target_index)
			events.append("Enemy %s#%d destroyed by summon." % [enemy_kind, enemy_id])

	return true


## Move summon toward nearest enemy
static func _summon_move(
	state: GameState,
	summon: Dictionary,
	dist_field: PackedInt32Array
) -> void:
	if state.enemies.is_empty():
		return

	var summon_pos: Vector2i = summon.get("pos", Vector2i.ZERO)
	var movement_speed: int = int(summon.get("movement_speed", 1))
	var is_flying: bool = summon.get("flying", false)

	# Find nearest enemy
	var target_pos: Vector2i = Vector2i(-1, -1)
	var best_dist: int = 999999

	for enemy in state.enemies:
		var enemy_pos: Vector2i = enemy.get("pos", Vector2i.ZERO)
		var dist: int = SimEnemies.manhattan(summon_pos, enemy_pos)
		if dist < best_dist:
			best_dist = dist
			target_pos = enemy_pos

	if target_pos.x < 0:
		return

	# Move toward target
	var offsets: Array[Vector2i] = [
		Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)
	]

	for _step in range(movement_speed):
		var current_dist: int = SimEnemies.manhattan(summon_pos, target_pos)
		if current_dist <= 1:
			break  # Close enough

		var best_move: Vector2i = summon_pos
		var best_move_dist: int = current_dist

		for offset in offsets:
			var new_pos: Vector2i = summon_pos + offset
			if not SimMap.in_bounds(new_pos.x, new_pos.y, state.map_w, state.map_h):
				continue

			# Flying units ignore terrain
			if not is_flying:
				SimMap.ensure_tile_generated(state, new_pos)
				if not SimMap.is_passable(state, new_pos):
					continue

			var new_dist: int = SimEnemies.manhattan(new_pos, target_pos)
			if new_dist < best_move_dist:
				best_move_dist = new_dist
				best_move = new_pos

		if best_move != summon_pos:
			summon_pos = best_move
			summon["pos"] = summon_pos


# =============================================================================
# SUMMON DAMAGE (from enemies)
# =============================================================================

## Apply damage to a summon
static func apply_damage_to_summon(
	state: GameState,
	summon_id: int,
	damage: int,
	events: Array[String]
) -> void:
	for i in range(state.summoned_units.size()):
		var summon: Dictionary = state.summoned_units[i]
		if int(summon.get("id", 0)) != summon_id:
			continue

		var hp: int = int(summon.get("hp", 0))
		hp = max(0, hp - damage)
		summon["hp"] = hp
		state.summoned_units[i] = summon

		if hp <= 0:
			var summon_type: String = str(summon.get("type", "skeleton"))
			var type_data: Dictionary = SimTowerTypes.get_summon_type(summon_type)
			var display_name: String = str(type_data.get("name", summon_type.capitalize()))
			events.append("%s has been destroyed!" % display_name)
			remove_summon(state, summon_id)
		break


## Find summon with taunt at position for enemy targeting
static func get_taunt_summon_at(state: GameState, pos: Vector2i) -> int:
	for summon in state.summoned_units:
		if not summon.get("taunt", false):
			continue
		var summon_pos: Vector2i = summon.get("pos", Vector2i.ZERO)
		if SimEnemies.manhattan(summon_pos, pos) <= 1:
			return int(summon.get("id", 0))
	return -1


# =============================================================================
# SERIALIZATION
# =============================================================================

## Serialize a summon for saving
static func serialize_summon(summon: Dictionary) -> Dictionary:
	var result: Dictionary = summon.duplicate(true)
	if summon.has("pos"):
		result["pos"] = {"x": summon.pos.x, "y": summon.pos.y}
	return result


## Deserialize a summon from save data
static func deserialize_summon(data: Dictionary) -> Dictionary:
	var result: Dictionary = data.duplicate(true)
	if data.has("pos") and typeof(data["pos"]) == TYPE_DICTIONARY:
		result["pos"] = Vector2i(
			int(data["pos"].get("x", 0)),
			int(data["pos"].get("y", 0))
		)
	return result
