class_name SimAutoTargeting
extends RefCounted
## Auto-Tower Targeting System - Algorithms for selecting attack targets

# =============================================================================
# MAIN TARGETING FUNCTION
# =============================================================================

static func pick_target(enemies: Array, tower_pos: Vector2i, range_val: int, mode: int) -> Dictionary:
	var result := {
		"target_index": -1,
		"target_pos": Vector2i.ZERO,
		"additional_targets": [],
		"cluster_center": Vector2i.ZERO
	}

	if enemies.is_empty():
		return result

	var in_range: Array[Dictionary] = _get_enemies_in_range(enemies, tower_pos, range_val)
	if in_range.is_empty():
		return result

	match mode:
		SimAutoTowerTypes.TargetMode.NEAREST:
			return _pick_nearest(in_range, tower_pos)
		SimAutoTowerTypes.TargetMode.HIGHEST_HP:
			return _pick_highest_hp(in_range, tower_pos)
		SimAutoTowerTypes.TargetMode.LOWEST_HP:
			return _pick_lowest_hp(in_range, tower_pos)
		SimAutoTowerTypes.TargetMode.FASTEST:
			return _pick_fastest(in_range, tower_pos)
		SimAutoTowerTypes.TargetMode.CLUSTER:
			return _pick_cluster(in_range, tower_pos)
		SimAutoTowerTypes.TargetMode.CHAIN:
			return _pick_chain(in_range, tower_pos)
		SimAutoTowerTypes.TargetMode.ZONE:
			return _pick_zone(in_range, tower_pos)
		SimAutoTowerTypes.TargetMode.CONTACT:
			return _pick_contact(enemies, tower_pos)
		SimAutoTowerTypes.TargetMode.SMART:
			return _pick_smart(in_range, tower_pos, enemies)
		_:
			return _pick_nearest(in_range, tower_pos)


# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

static func _get_enemies_in_range(enemies: Array, tower_pos: Vector2i, range_val: int) -> Array[Dictionary]:
	var in_range: Array[Dictionary] = []
	for i in enemies.size():
		var enemy: Dictionary = enemies[i]
		var enemy_pos := Vector2i(int(enemy.get("x", 0)), int(enemy.get("y", 0)))
		var dist: float = _distance(tower_pos, enemy_pos)
		if dist <= float(range_val):
			var entry := enemy.duplicate()
			entry["original_index"] = i
			entry["distance"] = dist
			in_range.append(entry)
	return in_range


static func _distance(a: Vector2i, b: Vector2i) -> float:
	return Vector2(a).distance_to(Vector2(b))


static func _make_result(enemy: Dictionary, tower_pos: Vector2i) -> Dictionary:
	return {
		"target_index": int(enemy.get("original_index", -1)),
		"target_pos": Vector2i(int(enemy.get("x", 0)), int(enemy.get("y", 0))),
		"additional_targets": [],
		"cluster_center": Vector2i.ZERO
	}


# =============================================================================
# TARGETING MODES
# =============================================================================

static func _pick_nearest(in_range: Array[Dictionary], tower_pos: Vector2i) -> Dictionary:
	var best: Dictionary = in_range[0]
	var best_dist: float = float(best.get("distance", 9999))

	for enemy in in_range:
		var dist: float = float(enemy.get("distance", 9999))
		if dist < best_dist:
			best = enemy
			best_dist = dist

	return _make_result(best, tower_pos)


static func _pick_highest_hp(in_range: Array[Dictionary], tower_pos: Vector2i) -> Dictionary:
	var best: Dictionary = in_range[0]
	var best_hp: int = int(best.get("hp", 0))

	for enemy in in_range:
		var hp: int = int(enemy.get("hp", 0))
		if hp > best_hp:
			best = enemy
			best_hp = hp

	return _make_result(best, tower_pos)


static func _pick_lowest_hp(in_range: Array[Dictionary], tower_pos: Vector2i) -> Dictionary:
	var best: Dictionary = in_range[0]
	var best_hp: int = int(best.get("hp", 9999))

	for enemy in in_range:
		var hp: int = int(enemy.get("hp", 0))
		if hp < best_hp:
			best = enemy
			best_hp = hp

	return _make_result(best, tower_pos)


static func _pick_fastest(in_range: Array[Dictionary], tower_pos: Vector2i) -> Dictionary:
	var best: Dictionary = in_range[0]
	var best_speed: float = float(best.get("speed", 0))

	for enemy in in_range:
		var speed: float = float(enemy.get("speed", 0))
		if speed > best_speed:
			best = enemy
			best_speed = speed

	return _make_result(best, tower_pos)


static func _pick_cluster(in_range: Array[Dictionary], tower_pos: Vector2i) -> Dictionary:
	if in_range.size() < 2:
		return _pick_nearest(in_range, tower_pos)

	# Find the enemy with most neighbors within 2 tiles
	var best: Dictionary = in_range[0]
	var best_neighbor_count: int = 0
	var cluster_center := Vector2i.ZERO

	for enemy in in_range:
		var enemy_pos := Vector2i(int(enemy.get("x", 0)), int(enemy.get("y", 0)))
		var neighbor_count: int = 0
		var center_sum := Vector2.ZERO

		for other in in_range:
			if other == enemy:
				continue
			var other_pos := Vector2i(int(other.get("x", 0)), int(other.get("y", 0)))
			if _distance(enemy_pos, other_pos) <= 2.0:
				neighbor_count += 1
				center_sum += Vector2(other_pos)

		if neighbor_count > best_neighbor_count:
			best = enemy
			best_neighbor_count = neighbor_count
			if neighbor_count > 0:
				center_sum += Vector2(enemy_pos)
				center_sum /= float(neighbor_count + 1)
				cluster_center = Vector2i(int(center_sum.x), int(center_sum.y))

	var result := _make_result(best, tower_pos)
	result.cluster_center = cluster_center if best_neighbor_count > 0 else result.target_pos
	return result


static func _pick_chain(in_range: Array[Dictionary], tower_pos: Vector2i) -> Dictionary:
	# Pick nearest as primary, then find chain targets
	var result := _pick_nearest(in_range, tower_pos)
	var primary_pos: Vector2i = result.target_pos
	var additional: Array[Dictionary] = []

	# Find up to 4 nearby enemies to chain to
	var chain_range := 2.0
	for enemy in in_range:
		if int(enemy.get("original_index", -1)) == result.target_index:
			continue
		var enemy_pos := Vector2i(int(enemy.get("x", 0)), int(enemy.get("y", 0)))
		if _distance(primary_pos, enemy_pos) <= chain_range:
			additional.append({
				"index": int(enemy.get("original_index", -1)),
				"pos": enemy_pos
			})
			if additional.size() >= 4:
				break

	result.additional_targets = additional
	return result


static func _pick_zone(in_range: Array[Dictionary], tower_pos: Vector2i) -> Dictionary:
	# For zone damage, return all enemies in range as additional targets
	var result := _pick_nearest(in_range, tower_pos)
	var additional: Array[Dictionary] = []

	for enemy in in_range:
		additional.append({
			"index": int(enemy.get("original_index", -1)),
			"pos": Vector2i(int(enemy.get("x", 0)), int(enemy.get("y", 0)))
		})

	result.additional_targets = additional
	return result


static func _pick_contact(enemies: Array, tower_pos: Vector2i) -> Dictionary:
	# Contact damage - enemies on the same tile or adjacent
	var result := {
		"target_index": -1,
		"target_pos": Vector2i.ZERO,
		"additional_targets": [],
		"cluster_center": Vector2i.ZERO
	}

	var contacts: Array[Dictionary] = []
	for i in enemies.size():
		var enemy: Dictionary = enemies[i]
		var enemy_pos := Vector2i(int(enemy.get("x", 0)), int(enemy.get("y", 0)))
		var dist: float = _distance(tower_pos, enemy_pos)
		if dist <= 1.0:
			contacts.append({
				"index": i,
				"pos": enemy_pos
			})

	if contacts.is_empty():
		return result

	result.target_index = contacts[0].index
	result.target_pos = contacts[0].pos
	result.additional_targets = contacts
	return result


static func _pick_smart(in_range: Array[Dictionary], tower_pos: Vector2i, all_enemies: Array) -> Dictionary:
	# AI-driven selection: prioritize threats based on multiple factors
	var best: Dictionary = in_range[0]
	var best_score: float = 0.0

	for enemy in in_range:
		var score: float = 0.0
		var hp: int = int(enemy.get("hp", 1))
		var max_hp: int = int(enemy.get("max_hp", hp))
		var speed: float = float(enemy.get("speed", 50))
		var dist: float = float(enemy.get("distance", 1))
		var damage: int = int(enemy.get("damage", 1))

		# Prioritize by threat level
		# Low HP enemies (finishable) get bonus
		if hp <= max_hp * 0.25:
			score += 30.0

		# High damage enemies are more threatening
		score += float(damage) * 5.0

		# Fast enemies get priority
		score += speed * 0.2

		# Closer enemies get slight priority
		score += (10.0 - dist) * 2.0

		# Bosses/elites get priority
		if enemy.get("is_boss", false) or enemy.get("is_elite", false):
			score += 50.0

		if score > best_score:
			best = enemy
			best_score = score

	return _make_result(best, tower_pos)


# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

static func get_enemies_in_splash_radius(enemies: Array, center: Vector2i, radius: int) -> Array[int]:
	var indices: Array[int] = []
	for i in enemies.size():
		var enemy: Dictionary = enemies[i]
		var enemy_pos := Vector2i(int(enemy.get("x", 0)), int(enemy.get("y", 0)))
		if _distance(center, enemy_pos) <= float(radius):
			indices.append(i)
	return indices


static func get_chain_targets(enemies: Array, start_pos: Vector2i, chain_count: int, chain_range: float) -> Array[int]:
	var chain_indices: Array[int] = []
	var current_pos := start_pos
	var used_indices: Array[int] = []

	for _i in chain_count:
		var best_index: int = -1
		var best_dist: float = chain_range + 1.0

		for j in enemies.size():
			if j in used_indices:
				continue
			var enemy: Dictionary = enemies[j]
			var enemy_pos := Vector2i(int(enemy.get("x", 0)), int(enemy.get("y", 0)))
			var dist: float = _distance(current_pos, enemy_pos)
			if dist <= chain_range and dist < best_dist:
				best_index = j
				best_dist = dist

		if best_index >= 0:
			chain_indices.append(best_index)
			used_indices.append(best_index)
			var target: Dictionary = enemies[best_index]
			current_pos = Vector2i(int(target.get("x", 0)), int(target.get("y", 0)))
		else:
			break

	return chain_indices
