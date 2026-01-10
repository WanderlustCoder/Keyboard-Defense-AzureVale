class_name SimWorkers
extends RefCounted

const GameState = preload("res://sim/types.gd")
const SimBuildings = preload("res://sim/buildings.gd")
const SimMap = preload("res://sim/map.gd")

const WORKER_PRODUCTION_BONUS := 0.5  # +50% production per worker
const WORKER_UPKEEP := 1  # Food consumed per worker per day

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
	var result := {"ok": true, "food_consumed": 0, "workers_lost": 0}

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
			if to_remove >= at_building:
				state.workers.erase(idx)
			else:
				state.workers[idx] = at_building - to_remove
			workers_to_remove -= to_remove

		result.ok = false

	return result

# Calculate production bonus from workers for a specific building
static func worker_bonus(state: GameState, building_index: int) -> float:
	var workers: int = workers_at(state, building_index)
	if workers <= 0:
		return 0.0
	return workers * WORKER_PRODUCTION_BONUS

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
static func gain_worker(state: GameState) -> bool:
	if state.total_workers >= state.max_workers:
		return false
	state.total_workers += 1
	return true

# Remove workers when a building is destroyed
static func on_building_removed(state: GameState, building_index: int) -> void:
	state.workers.erase(building_index)

# Helper function to check adjacent terrain
static func _adjacent_terrain(state: GameState, pos: Vector2i, terrain: String) -> bool:
	for neighbor in SimMap.neighbors4(pos, state.map_w, state.map_h):
		if SimMap.get_terrain(state, neighbor) == terrain:
			return true
	return false
