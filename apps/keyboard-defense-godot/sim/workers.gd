class_name SimWorkers
extends RefCounted

const GameState = preload("res://sim/types.gd")
const SimBuildings = preload("res://sim/buildings.gd")
const SimMap = preload("res://sim/map.gd")
const SimCitizens = preload("res://sim/citizens.gd")

const WORKER_PRODUCTION_BONUS := 0.5  # +50% production per worker
const WORKER_UPKEEP := 1  # Food consumed per worker per day

## Whether to use the citizen system for workers
const USE_CITIZEN_SYSTEM := true

# Get the number of workers assigned to a building
static func workers_at(state: GameState, building_index: int) -> int:
	return int(state.workers.get(building_index, 0))

# Get total workers assigned across all buildings
static func total_assigned(state: GameState) -> int:
	var total: int = 0
	for idx in state.workers.keys():
		total += int(state.workers[idx])
	return total

# Get available (unassigned) workers
static func available_workers(state: GameState) -> int:
	return max(0, state.total_workers - total_assigned(state))

# Get worker capacity for a building at its current level
static func worker_capacity(state: GameState, building_index: int) -> int:
	if not state.structures.has(building_index):
		return 0
	var building_type: String = str(state.structures[building_index])
	var level: int = SimBuildings.structure_level(state, building_index)
	return SimBuildings.worker_slots_for(building_type, level)

# Check if we can assign a worker to a building
static func can_assign(state: GameState, building_index: int) -> Dictionary:
	var result := {"ok": false, "reason": ""}

	if not state.structures.has(building_index):
		result.reason = "no building"
		return result

	var building_type: String = str(state.structures[building_index])

	# Check if building supports workers
	var capacity: int = worker_capacity(state, building_index)
	if capacity <= 0:
		result.reason = "building does not support workers"
		return result

	# Check current assignment
	var current: int = workers_at(state, building_index)
	if current >= capacity:
		result.reason = "building at capacity"
		return result

	# Check available workers
	if available_workers(state) <= 0:
		result.reason = "no available workers"
		return result

	result.ok = true
	return result

# Assign a worker to a building
static func assign_worker(state: GameState, building_index: int) -> bool:
	var check: Dictionary = can_assign(state, building_index)
	if not check.ok:
		return false

	var current: int = workers_at(state, building_index)
	state.workers[building_index] = current + 1

	# Also assign an unassigned citizen if available
	if USE_CITIZEN_SYSTEM:
		var unassigned: Array = SimCitizens.get_unassigned_citizens(state)
		if not unassigned.is_empty():
			var citizen: Dictionary = unassigned[0]
			SimCitizens.assign_to_building(state, citizen.get("id", -1), building_index)

	return true


# Assign a specific citizen to a building
static func assign_citizen(state: GameState, citizen_id: int, building_index: int) -> bool:
	var check: Dictionary = can_assign(state, building_index)
	if not check.ok:
		return false

	var citizen: Dictionary = SimCitizens.find_citizen(state, citizen_id)
	if citizen.is_empty():
		return false

	# If citizen was assigned elsewhere, unassign first
	var prev_building: int = citizen.get("assigned_building", -1)
	if prev_building >= 0 and prev_building != building_index:
		unassign_worker(state, prev_building)

	var current: int = workers_at(state, building_index)
	state.workers[building_index] = current + 1
	SimCitizens.assign_to_building(state, citizen_id, building_index)
	return true

# Check if we can unassign a worker from a building
static func can_unassign(state: GameState, building_index: int) -> Dictionary:
	var result := {"ok": false, "reason": ""}

	if not state.structures.has(building_index):
		result.reason = "no building"
		return result

	var current: int = workers_at(state, building_index)
	if current <= 0:
		result.reason = "no workers assigned"
		return result

	result.ok = true
	return result

# Unassign a worker from a building
static func unassign_worker(state: GameState, building_index: int) -> bool:
	var check: Dictionary = can_unassign(state, building_index)
	if not check.ok:
		return false

	var current: int = workers_at(state, building_index)
	if current <= 1:
		state.workers.erase(building_index)
	else:
		state.workers[building_index] = current - 1

	# Also unassign a citizen from this building
	if USE_CITIZEN_SYSTEM:
		var citizens: Array = SimCitizens.find_citizens_at_building(state, building_index)
		if not citizens.is_empty():
			var citizen: Dictionary = citizens[0]
			SimCitizens.unassign_from_building(state, citizen.get("id", -1))

	return true


# Unassign a specific citizen from their building
static func unassign_citizen(state: GameState, citizen_id: int) -> bool:
	var citizen: Dictionary = SimCitizens.find_citizen(state, citizen_id)
	if citizen.is_empty():
		return false

	var building_index: int = citizen.get("assigned_building", -1)
	if building_index < 0:
		return false

	# Decrement worker count
	var current: int = workers_at(state, building_index)
	if current <= 1:
		state.workers.erase(building_index)
	else:
		state.workers[building_index] = current - 1

	SimCitizens.unassign_from_building(state, citizen_id)
	return true

# Set workers at a building to a specific count
static func set_workers(state: GameState, building_index: int, count: int) -> bool:
	if not state.structures.has(building_index):
		return false

	var capacity: int = worker_capacity(state, building_index)
	if capacity <= 0:
		return false

	# Get current and calculate needed change
	var current: int = workers_at(state, building_index)
	var delta: int = count - current

	# Check if we have enough available workers
	if delta > 0:
		if available_workers(state) < delta:
			return false

	# Apply the change
	count = clamp(count, 0, capacity)
	if count == 0:
		state.workers.erase(building_index)
	else:
		state.workers[building_index] = count
	return true

# Calculate food upkeep for all workers
static func daily_upkeep(state: GameState) -> int:
	return total_assigned(state) * state.worker_upkeep

# Apply daily worker upkeep (consume food)
static func apply_upkeep(state: GameState) -> Dictionary:
	var result := {"ok": true, "food_consumed": 0, "workers_lost": 0, "citizens_lost": []}

	var upkeep: int = daily_upkeep(state)
	var food: int = int(state.resources.get("food", 0))

	if food >= upkeep:
		# Can afford all upkeep
		state.resources["food"] = food - upkeep
		result.food_consumed = upkeep
	else:
		# Not enough food - consume what we have and lose workers
		state.resources["food"] = 0
		result.food_consumed = food

		# Calculate workers that can't be fed
		var unfed: int = ceili(float(upkeep - food) / float(state.worker_upkeep))
		result.workers_lost = min(unfed, total_assigned(state))

		# Remove workers from buildings (starting from buildings with most workers)
		var workers_to_remove: int = result.workers_lost
		var building_indices: Array = state.workers.keys()

		# Sort by worker count descending
		building_indices.sort_custom(func(a, b):
			return int(state.workers.get(a, 0)) > int(state.workers.get(b, 0))
		)

		for idx in building_indices:
			if workers_to_remove <= 0:
				break
			var at_building: int = int(state.workers[idx])
			var to_remove: int = min(workers_to_remove, at_building)

			# Also remove citizens from this building
			if USE_CITIZEN_SYSTEM:
				var citizens: Array = SimCitizens.find_citizens_at_building(state, int(idx))
				for i in range(mini(to_remove, citizens.size())):
					var citizen: Dictionary = citizens[i]
					result.citizens_lost.append({
						"id": citizen.get("id"),
						"name": SimCitizens.get_full_name(citizen)
					})
					SimCitizens.remove_citizen(state, citizen.get("id", -1))

			if to_remove >= at_building:
				state.workers.erase(idx)
			else:
				state.workers[idx] = at_building - to_remove
			workers_to_remove -= to_remove

		# Update total workers count
		state.total_workers = maxi(0, state.total_workers - result.workers_lost)

		result.ok = false

	return result

# Calculate production bonus from workers for a specific building
static func worker_bonus(state: GameState, building_index: int) -> float:
	var workers: int = workers_at(state, building_index)
	if workers <= 0:
		return 0.0
	return workers * WORKER_PRODUCTION_BONUS


# Calculate production bonus using citizen skills and morale
static func citizen_enhanced_bonus(state: GameState, building_index: int) -> float:
	if not USE_CITIZEN_SYSTEM:
		return worker_bonus(state, building_index)

	# Get citizens at this building
	var citizens: Array = SimCitizens.find_citizens_at_building(state, building_index)
	if citizens.is_empty():
		# Fall back to basic worker bonus if no citizens assigned
		return worker_bonus(state, building_index)

	var total_bonus := 0.0
	for citizen in citizens:
		# Base bonus per worker
		var base := WORKER_PRODUCTION_BONUS

		# Apply skill bonus (10% per level above 1)
		var skill_mult: float = SimCitizens.get_skill_bonus(citizen)

		# Apply morale multiplier
		var morale_mult: float = SimCitizens.get_productivity_multiplier(citizen)

		total_bonus += base * skill_mult * morale_mult

	return total_bonus

# Calculate total daily production including worker bonuses
static func daily_production_with_workers(state: GameState) -> Dictionary:
	var totals: Dictionary = {"wood": 0, "stone": 0, "food": 1, "gold": 0}

	for key in state.structures.keys():
		var building_type: String = str(state.structures[key])
		if not SimBuildings.BUILDINGS.has(building_type):
			continue

		var index: int = int(key)
		var level: int = SimBuildings.structure_level(state, index)
		var production: Dictionary = SimBuildings.production_for_level(building_type, level)

		# Calculate worker bonus multiplier
		var bonus_mult: float = 1.0 + worker_bonus(state, index)

		# Add base production with worker bonus
		for resource_key in production.keys():
			var base_amount: int = int(production[resource_key])
			var boosted: int = int(floor(float(base_amount) * bonus_mult))
			totals[resource_key] = int(totals.get(resource_key, 0)) + boosted

		# Add adjacency bonuses
		var pos: Vector2i = SimMap.pos_from_index(index, state.map_w)
		if building_type == "farm" and _adjacent_terrain(state, pos, SimMap.TERRAIN_WATER):
			totals["food"] = int(totals.get("food", 0)) + 1
		elif building_type == "lumber" and _adjacent_terrain(state, pos, SimMap.TERRAIN_FOREST):
			totals["wood"] = int(totals.get("wood", 0)) + 1
		elif building_type == "quarry" and _adjacent_terrain(state, pos, SimMap.TERRAIN_MOUNTAIN):
			totals["stone"] = int(totals.get("stone", 0)) + 1
		elif building_type == "market":
			# Markets get gold per adjacent building
			var adjacent_count: int = SimBuildings.count_adjacent_buildings(state, pos)
			var per_adj: int = 1
			if level >= 2:
				per_adj = 2
			if level >= 3:
				per_adj = 3
			totals["gold"] = int(totals.get("gold", 0)) + (adjacent_count * per_adj)

	return totals

# Get a summary of all worker assignments
static func get_worker_summary(state: GameState) -> Dictionary:
	var summary := {
		"total_workers": state.total_workers,
		"max_workers": state.max_workers,
		"assigned": total_assigned(state),
		"available": available_workers(state),
		"upkeep": daily_upkeep(state),
		"assignments": []
	}

	for idx in state.structures.keys():
		var building_type: String = str(state.structures[idx])
		var capacity: int = worker_capacity(state, int(idx))
		if capacity <= 0:
			continue

		var current: int = workers_at(state, int(idx))
		var pos: Vector2i = SimMap.pos_from_index(int(idx), state.map_w)

		summary.assignments.append({
			"index": int(idx),
			"building_type": building_type,
			"position": pos,
			"workers": current,
			"capacity": capacity,
			"bonus": worker_bonus(state, int(idx))
		})

	return summary

# Add a new worker to the pool (called on day advancement)
static func gain_worker(state: GameState, rng: RandomNumberGenerator = null) -> bool:
	if state.total_workers >= state.max_workers:
		return false
	state.total_workers += 1

	# Create a citizen for this worker if system is enabled
	if USE_CITIZEN_SYSTEM:
		var new_citizen: Dictionary = SimCitizens.create_citizen("", rng)
		SimCitizens.add_citizen(state, new_citizen)

	return true


# Get citizen info for a gained worker (for UI feedback)
static func gain_worker_with_info(state: GameState, rng: RandomNumberGenerator = null) -> Dictionary:
	if state.total_workers >= state.max_workers:
		return {"success": false, "citizen": {}}

	state.total_workers += 1

	var new_citizen: Dictionary = {}
	if USE_CITIZEN_SYSTEM:
		new_citizen = SimCitizens.create_citizen("", rng)
		SimCitizens.add_citizen(state, new_citizen)

	return {"success": true, "citizen": new_citizen}

# Remove workers when a building is destroyed
static func on_building_removed(state: GameState, building_index: int) -> void:
	# Unassign all citizens from this building
	if USE_CITIZEN_SYSTEM:
		var citizens: Array = SimCitizens.find_citizens_at_building(state, building_index)
		for citizen in citizens:
			SimCitizens.unassign_from_building(state, citizen.get("id", -1))

	state.workers.erase(building_index)


# Get citizen-enhanced worker summary
static func get_citizen_summary(state: GameState) -> Dictionary:
	var summary := get_worker_summary(state)

	if not USE_CITIZEN_SYSTEM:
		return summary

	# Add citizen details
	summary.total_citizens = SimCitizens.count_citizens(state)
	summary.average_morale = SimCitizens.get_average_morale(state)
	summary.unassigned_citizens = SimCitizens.get_unassigned_citizens(state).size()

	# Enhance assignment info with citizen details
	for i in range(summary.assignments.size()):
		var assignment: Dictionary = summary.assignments[i]
		var building_index: int = assignment.get("index", -1)
		var citizens: Array = SimCitizens.find_citizens_at_building(state, building_index)

		var citizen_info := []
		var total_skill := 0.0
		var total_morale := 0.0

		for cit in citizens:
			var cit_dict: Dictionary = cit
			citizen_info.append({
				"id": cit_dict.get("id"),
				"name": SimCitizens.get_full_name(cit_dict),
				"title": SimCitizens.get_title(cit_dict),
				"skill_level": cit_dict.get("skill_level", 1),
				"morale": cit_dict.get("morale", 50.0),
				"traits": cit_dict.get("traits", [])
			})
			total_skill += cit_dict.get("skill_level", 1)
			total_morale += cit_dict.get("morale", 50.0)

		assignment.citizens = citizen_info
		if not citizens.is_empty():
			assignment.avg_skill = total_skill / citizens.size()
			assignment.avg_morale = total_morale / citizens.size()
			assignment.citizen_bonus = citizen_enhanced_bonus(state, building_index)
		else:
			assignment.avg_skill = 0.0
			assignment.avg_morale = 0.0
			assignment.citizen_bonus = 0.0

	return summary

# Helper function to check adjacent terrain
static func _adjacent_terrain(state: GameState, pos: Vector2i, terrain: String) -> bool:
	for neighbor in SimMap.neighbors4(pos, state.map_w, state.map_h):
		if SimMap.get_terrain(state, neighbor) == terrain:
			return true
	return false
