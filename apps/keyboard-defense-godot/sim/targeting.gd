class_name SimTargeting
extends RefCounted
## Targeting system for tower attacks - handles single, multi, AoE, and chain targeting

const GameState = preload("res://sim/types.gd")
const SimEnemies = preload("res://sim/enemies.gd")
const SimMap = preload("res://sim/map.gd")
const SimStatusEffects = preload("res://sim/status_effects.gd")

## Target priority for selecting enemies
enum TargetPriority {
	CLOSEST_TO_BASE,     # Default: lowest distance field value (about to reach castle)
	HIGHEST_HP,          # Tanks/bosses first
	LOWEST_HP,           # Finish off weak enemies
	MARKED,              # Prioritize marked enemies
	BOSS,                # Always target bosses if present
	RANDOM               # For chaos effects
}

# =============================================================================
# SINGLE TARGET
# =============================================================================

## Pick single target (Arrow, Magic, Holy, etc.)
## Returns enemy index, or -1 if no valid target
static func pick_single_target(
	enemies: Array,
	dist_field: PackedInt32Array,
	map_w: int,
	origin: Vector2i,
	max_range: int,
	priority: int = TargetPriority.CLOSEST_TO_BASE
) -> int:
	var candidates := _get_candidates_in_range(enemies, origin, max_range)
	if candidates.is_empty():
		return -1

	# Sort by priority
	_sort_by_priority(candidates, enemies, dist_field, map_w, priority)

	return candidates[0]


## Pick single target with boss priority (for Holy/Purifier towers)
static func pick_boss_or_affixed_target(
	enemies: Array,
	dist_field: PackedInt32Array,
	map_w: int,
	origin: Vector2i,
	max_range: int
) -> int:
	var candidates := _get_candidates_in_range(enemies, origin, max_range)
	if candidates.is_empty():
		return -1

	# Check for bosses first
	for i in candidates:
		var enemy: Dictionary = enemies[i]
		if enemy.get("is_boss", false):
			return i

	# Then check for affixed enemies
	for i in candidates:
		var enemy: Dictionary = enemies[i]
		if enemy.has("affix") and str(enemy.get("affix", "")) != "":
			return i

	# Fall back to closest to base
	_sort_by_priority(candidates, enemies, dist_field, map_w, TargetPriority.CLOSEST_TO_BASE)
	return candidates[0]


# =============================================================================
# MULTI TARGET
# =============================================================================

## Pick multiple targets (Multi-Shot)
## Returns array of enemy indices
static func pick_multi_targets(
	enemies: Array,
	dist_field: PackedInt32Array,
	map_w: int,
	origin: Vector2i,
	max_range: int,
	target_count: int,
	priority: int = TargetPriority.CLOSEST_TO_BASE
) -> Array[int]:
	var targets: Array[int] = []
	var candidates := _get_candidates_in_range(enemies, origin, max_range)

	if candidates.is_empty():
		return targets

	# Sort by priority
	_sort_by_priority(candidates, enemies, dist_field, map_w, priority)

	# Take top N
	for i in range(min(target_count, candidates.size())):
		targets.append(candidates[i])

	return targets


# =============================================================================
# AOE TARGET
# =============================================================================

## Get all enemies in AoE radius around a center point (Cannon)
## Returns array of enemy indices
static func get_aoe_targets(
	enemies: Array,
	center: Vector2i,
	radius: int
) -> Array[int]:
	var targets: Array[int] = []
	for i in range(enemies.size()):
		var enemy: Dictionary = enemies[i]
		var pos: Vector2i = enemy.get("pos", Vector2i.ZERO)
		if _manhattan(center, pos) <= radius:
			targets.append(i)
	return targets


## Pick primary target and get all AoE targets around it
static func pick_aoe_primary_and_splash(
	enemies: Array,
	dist_field: PackedInt32Array,
	map_w: int,
	origin: Vector2i,
	max_range: int,
	aoe_radius: int,
	priority: int = TargetPriority.CLOSEST_TO_BASE
) -> Dictionary:
	var result := {
		"primary_index": -1,
		"splash_indices": [] as Array[int],
		"center": Vector2i.ZERO
	}

	# Pick primary target
	var primary_index := pick_single_target(enemies, dist_field, map_w, origin, max_range, priority)
	if primary_index < 0:
		return result

	result.primary_index = primary_index
	var primary_pos: Vector2i = enemies[primary_index].get("pos", Vector2i.ZERO)
	result.center = primary_pos

	# Get all enemies in AoE radius
	result.splash_indices = get_aoe_targets(enemies, primary_pos, aoe_radius)

	return result


# =============================================================================
# CHAIN TARGET
# =============================================================================

## Get chain targets starting from an enemy (Tesla)
## Returns array of enemy indices in chain order
static func get_chain_targets(
	enemies: Array,
	start_index: int,
	chain_count: int,
	chain_range: int
) -> Array[int]:
	if start_index < 0 or start_index >= enemies.size():
		return []

	var targets: Array[int] = [start_index]
	var visited: Dictionary = {start_index: true}
	var current_index: int = start_index

	for _i in range(chain_count - 1):
		var current_pos: Vector2i = enemies[current_index].get("pos", Vector2i.ZERO)
		var next_index: int = _find_nearest_unvisited(
			enemies, current_pos, chain_range, visited
		)
		if next_index < 0:
			break
		targets.append(next_index)
		visited[next_index] = true
		current_index = next_index

	return targets


## Pick primary chain target and get all chain targets
static func pick_chain_primary_and_jumps(
	enemies: Array,
	dist_field: PackedInt32Array,
	map_w: int,
	origin: Vector2i,
	max_range: int,
	chain_count: int,
	chain_range: int,
	priority: int = TargetPriority.CLOSEST_TO_BASE
) -> Array[int]:
	# Pick primary target
	var primary_index := pick_single_target(enemies, dist_field, map_w, origin, max_range, priority)
	if primary_index < 0:
		return []

	# Get chain targets
	return get_chain_targets(enemies, primary_index, chain_count, chain_range)


# =============================================================================
# ADAPTIVE TARGET (Legendary towers)
# =============================================================================

## Pick target based on current battle situation (Letter Spirit Shrine)
static func pick_adaptive_target(
	state: GameState,
	enemies: Array,
	dist_field: PackedInt32Array,
	origin: Vector2i,
	max_range: int
) -> Dictionary:
	var result := {
		"mode": "alpha",
		"primary_index": -1,
		"additional_indices": [] as Array[int]
	}

	var candidates := _get_candidates_in_range(enemies, origin, max_range)
	if candidates.is_empty():
		return result

	# Check for boss (Alpha mode - single target focus)
	for i in candidates:
		var enemy: Dictionary = enemies[i]
		if enemy.get("is_boss", false):
			result.mode = "alpha"
			result.primary_index = i
			return result

	# Check for many enemies (Epsilon mode - chain all)
	if enemies.size() >= 10:
		result.mode = "epsilon"
		_sort_by_priority(candidates, enemies, dist_field, state.map_w, TargetPriority.CLOSEST_TO_BASE)
		result.primary_index = candidates[0]
		result.additional_indices = candidates.duplicate()
		if result.additional_indices.size() > 0:
			result.additional_indices.remove_at(0)  # Remove primary
		return result

	# Check castle HP (Omega mode - heal on kill)
	if state.hp < state.hp / 2:  # Below 50% HP
		result.mode = "omega"
		# Target lowest HP enemy for quick kill
		_sort_by_priority(candidates, enemies, dist_field, state.map_w, TargetPriority.LOWEST_HP)
		result.primary_index = candidates[0]
		return result

	# Default: Alpha mode with closest target
	result.mode = "alpha"
	_sort_by_priority(candidates, enemies, dist_field, state.map_w, TargetPriority.CLOSEST_TO_BASE)
	result.primary_index = candidates[0]
	return result


# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

## Get all enemy indices within range of origin
static func _get_candidates_in_range(
	enemies: Array,
	origin: Vector2i,
	max_range: int
) -> Array[int]:
	var result: Array[int] = []
	for i in range(enemies.size()):
		var enemy: Dictionary = enemies[i]
		var pos: Vector2i = enemy.get("pos", Vector2i.ZERO)
		# max_range < 0 means unlimited range
		if max_range < 0 or _manhattan(origin, pos) <= max_range:
			result.append(i)
	return result


## Find nearest enemy not in visited set
static func _find_nearest_unvisited(
	enemies: Array,
	origin: Vector2i,
	max_range: int,
	visited: Dictionary
) -> int:
	var best_index: int = -1
	var best_dist: int = 999999

	for i in range(enemies.size()):
		if visited.has(i):
			continue
		var enemy: Dictionary = enemies[i]
		var pos: Vector2i = enemy.get("pos", Vector2i.ZERO)
		var dist: int = _manhattan(origin, pos)
		if dist <= max_range and dist < best_dist:
			best_dist = dist
			best_index = i

	return best_index


## Sort candidate indices by priority
static func _sort_by_priority(
	candidates: Array[int],
	enemies: Array,
	dist_field: PackedInt32Array,
	map_w: int,
	priority: int
) -> void:
	candidates.sort_custom(func(a: int, b: int) -> bool:
		return _compare_by_priority(enemies[a], enemies[b], dist_field, map_w, priority)
	)


## Compare two enemies by priority
static func _compare_by_priority(
	a: Dictionary,
	b: Dictionary,
	dist_field: PackedInt32Array,
	map_w: int,
	priority: int
) -> bool:
	match priority:
		TargetPriority.CLOSEST_TO_BASE:
			var dist_a: int = SimEnemies.dist_at(dist_field, a.get("pos", Vector2i.ZERO), map_w)
			var dist_b: int = SimEnemies.dist_at(dist_field, b.get("pos", Vector2i.ZERO), map_w)
			if dist_a != dist_b:
				return dist_a < dist_b
			return int(a.get("id", 0)) < int(b.get("id", 0))
		TargetPriority.HIGHEST_HP:
			var hp_a: int = int(a.get("hp", 0))
			var hp_b: int = int(b.get("hp", 0))
			if hp_a != hp_b:
				return hp_a > hp_b
			return int(a.get("id", 0)) < int(b.get("id", 0))
		TargetPriority.LOWEST_HP:
			var hp_a: int = int(a.get("hp", 0))
			var hp_b: int = int(b.get("hp", 0))
			if hp_a != hp_b:
				return hp_a < hp_b
			return int(a.get("id", 0)) < int(b.get("id", 0))
		TargetPriority.MARKED:
			var marked_a: bool = SimStatusEffects.has_effect(a, "marked") if a.has("status_effects") else false
			var marked_b: bool = SimStatusEffects.has_effect(b, "marked") if b.has("status_effects") else false
			if marked_a != marked_b:
				return marked_a
			# Fall back to closest
			var dist_a: int = SimEnemies.dist_at(dist_field, a.get("pos", Vector2i.ZERO), map_w)
			var dist_b: int = SimEnemies.dist_at(dist_field, b.get("pos", Vector2i.ZERO), map_w)
			return dist_a < dist_b
		TargetPriority.BOSS:
			var boss_a: bool = a.get("is_boss", false)
			var boss_b: bool = b.get("is_boss", false)
			if boss_a != boss_b:
				return boss_a
			# Fall back to closest
			var dist_a: int = SimEnemies.dist_at(dist_field, a.get("pos", Vector2i.ZERO), map_w)
			var dist_b: int = SimEnemies.dist_at(dist_field, b.get("pos", Vector2i.ZERO), map_w)
			return dist_a < dist_b
		_:
			return int(a.get("id", 0)) < int(b.get("id", 0))


## Manhattan distance between two points
static func _manhattan(a: Vector2i, b: Vector2i) -> int:
	return abs(a.x - b.x) + abs(a.y - b.y)


## Check if enemy is valid target (alive, not ghostly/phased, etc.)
static func is_valid_target(enemy: Dictionary) -> bool:
	if int(enemy.get("hp", 0)) <= 0:
		return false
	# Add other conditions as needed (phased, invulnerable, etc.)
	return true


## Get position from tower index
static func get_tower_position(state: GameState, tower_index: int) -> Vector2i:
	return SimMap.pos_from_index(tower_index, state.map_w)
