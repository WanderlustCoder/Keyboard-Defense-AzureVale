class_name WorldTick
extends RefCounted

const GameState = preload("res://sim/types.gd")
const SimMap = preload("res://sim/map.gd")
const SimPoi = preload("res://sim/poi.gd")
const SimRng = preload("res://sim/rng.gd")
const SimEnemies = preload("res://sim/enemies.gd")

const WORLD_TICK_INTERVAL := 1.0  # Seconds between world updates
const TIME_ADVANCE_RATE := 0.02  # Time of day advances per tick (full cycle ~50 ticks)
const POI_SPAWN_CHANCE := 0.15  # Chance to spawn POI per tick
const ROAMING_SPAWN_CHANCE := 0.10  # Chance to spawn roaming enemy per tick
const MAX_ACTIVE_POIS := 5
const MAX_ROAMING_ENEMIES := 8
const THREAT_DECAY_RATE := 0.01  # Threat decreases per tick when safe
const THREAT_GROWTH_RATE := 0.02  # Threat grows per tick when enemies near

# Unified threat system constants
const WAVE_ASSAULT_THRESHOLD := 0.8  # Threat level that triggers wave assault
const WAVE_COOLDOWN_DURATION := 30.0  # Seconds before threat can trigger another wave
const ENCOUNTER_RETURN_DELAY := 2.0  # Seconds after encounter ends before returning to exploration
const THREAT_DECAY_IN_EXPLORATION := 0.005  # Passive threat decay when exploring

## Main world tick function - call from _process with accumulated delta
static func tick(state: GameState, delta: float) -> Dictionary:
	state.world_tick_accum += delta
	var events: Array[String] = []
	var state_changed: bool = false

	# Decay wave cooldown
	if state.wave_cooldown > 0:
		state.wave_cooldown = max(0.0, state.wave_cooldown - delta)

	# Process ticks at regular intervals
	while state.world_tick_accum >= WORLD_TICK_INTERVAL:
		state.world_tick_accum -= WORLD_TICK_INTERVAL

		# Advance time of day
		state.time_of_day += TIME_ADVANCE_RATE
		if state.time_of_day >= 1.0:
			state.time_of_day -= 1.0

		# Handle activity mode-specific logic
		match state.activity_mode:
			"exploration":
				# Tick roaming entities
				var roaming_events := _tick_roaming_entities(state)
				events.append_array(roaming_events)

				# Maybe spawn new POI
				var poi_event := _tick_poi_spawns(state)
				if poi_event != "":
					events.append(poi_event)

				# Maybe spawn roaming enemy
				var enemy_event := _tick_roaming_spawns(state)
				if enemy_event != "":
					events.append(enemy_event)

				# Update threat level based on proximity
				_tick_threat_level(state)

				# Check for wave assault trigger
				var wave_event := _check_wave_assault_trigger(state)
				if wave_event != "":
					events.append(wave_event)

			"encounter":
				# Check if encounter is over
				if state.enemies.is_empty():
					_end_encounter(state)
					events.append("Encounter resolved. Continue exploring.")

			"wave_assault":
				# Wave assault uses existing night phase combat
				# Check if wave is cleared
				if state.enemies.is_empty() and state.night_spawn_remaining <= 0:
					_end_wave_assault(state)
					events.append("Wave repelled! The kingdom is safe... for now.")

			"event":
				# Events are handled by the event system, just wait
				pass

		state_changed = true

	return {"events": events, "changed": state_changed}

## Check if threat level triggers a wave assault
static func _check_wave_assault_trigger(state: GameState) -> String:
	if state.wave_cooldown > 0:
		return ""
	if state.threat_level < WAVE_ASSAULT_THRESHOLD:
		return ""

	# Trigger wave assault!
	_start_wave_assault(state)
	return "WAVE ASSAULT! Enemies converge on the castle!"

## Start a wave assault (threat-triggered combat)
static func _start_wave_assault(state: GameState) -> void:
	state.activity_mode = "wave_assault"
	state.phase = "night"

	# Calculate wave size based on threat and day
	var base_size: int = 2 + int(state.day / 2)
	var threat_bonus: int = int(state.threat_level * 3)
	var wave_size: int = base_size + threat_bonus

	state.night_wave_total = wave_size
	state.night_spawn_remaining = wave_size
	state.enemies = []

	# Convert some roaming enemies to combat
	var converted: int = 0
	for i in range(min(2, state.roaming_enemies.size())):
		if state.roaming_enemies.is_empty():
			break
		var roaming: Dictionary = state.roaming_enemies.pop_back()
		_convert_to_combat_enemy(state, roaming)
		converted += 1

	# Reset threat level
	state.threat_level = 0.3

## End wave assault, return to exploration
static func _end_wave_assault(state: GameState) -> void:
	state.activity_mode = "exploration"
	state.phase = "day"
	state.ap = state.ap_max
	state.wave_cooldown = WAVE_COOLDOWN_DURATION
	state.day += 1  # Advance day after wave

## End encounter, return to exploration
static func _end_encounter(state: GameState) -> void:
	state.activity_mode = "exploration"
	state.phase = "day"
	# Don't restore AP for small encounters
	state.encounter_enemies = []

## Spawn POIs on discovered tiles
static func _tick_poi_spawns(state: GameState) -> String:
	if state.active_pois.size() >= MAX_ACTIVE_POIS:
		return ""

	var roll: float = SimRng.roll_range(state, 0, 100) / 100.0
	if roll > POI_SPAWN_CHANCE:
		return ""

	# Get discovered tiles without POIs or structures
	var valid_tiles: Array[int] = []
	for tile_index in state.discovered.keys():
		if state.active_pois.has(tile_index):
			continue
		if state.structures.has(tile_index):
			continue
		var pos: Vector2i = SimMap.pos_from_index(tile_index, state.map_w)
		if pos == state.base_pos:
			continue
		var terrain: String = SimMap.get_terrain(state, pos)
		if terrain == SimMap.TERRAIN_WATER:
			continue
		valid_tiles.append(tile_index)

	if valid_tiles.is_empty():
		return ""

	# Pick random tile
	var pick_idx: int = SimRng.roll_range(state, 0, valid_tiles.size() - 1)
	var tile_index: int = valid_tiles[pick_idx]
	var pos: Vector2i = SimMap.pos_from_index(tile_index, state.map_w)
	var terrain: String = SimMap.get_terrain(state, pos)
	var biome: String = _terrain_to_biome(terrain)

	# Try to spawn POI
	var poi_id: String = SimPoi.try_spawn_random_poi(state, biome, pos)
	if poi_id != "":
		return "A point of interest appeared nearby!"
	return ""

## Spawn roaming enemies at map edges - zone-aware spawn rates
static func _tick_roaming_spawns(state: GameState) -> String:
	if state.roaming_enemies.size() >= MAX_ROAMING_ENEMIES:
		return ""

	# Higher chance at night and high threat
	var time_modifier: float = 0.0
	if state.time_of_day > 0.7 or state.time_of_day < 0.2:  # Night
		time_modifier = 0.15
	var threat_modifier: float = state.threat_level * 0.1

	# Exploration bonus - more spawns when player explores dangerous zones
	var exploration_modifier: float = _get_exploration_spawn_modifier(state)

	var spawn_chance: float = ROAMING_SPAWN_CHANCE + time_modifier + threat_modifier + exploration_modifier

	var roll: float = SimRng.roll_range(state, 0, 100) / 100.0
	if roll > spawn_chance:
		return ""

	# Pick edge spawn position - prefer edges in more dangerous zones
	var edge_pos: Vector2i = _get_weighted_edge_position(state)
	if edge_pos == Vector2i(-1, -1):
		return ""

	# Create roaming enemy
	var enemy := _create_roaming_enemy(state, edge_pos)
	state.roaming_enemies.append(enemy)

	# Notify if elite enemy spawned from depths
	var kind: String = str(enemy.get("kind", ""))
	var spawn_zone: String = str(enemy.get("spawn_zone", ""))
	if spawn_zone == SimMap.ZONE_DEPTHS and kind in ["champion", "healer", "elite"]:
		return "A powerful enemy emerges from the depths!"

	return ""  # Silent spawn for atmosphere

## Calculate spawn rate modifier based on player exploration
static func _get_exploration_spawn_modifier(state: GameState) -> float:
	var modifier: float = 0.0

	# Check if cursor is in a dangerous zone
	var cursor_zone: String = SimMap.get_cursor_zone(state)
	match cursor_zone:
		SimMap.ZONE_WILDERNESS:
			modifier += 0.05
		SimMap.ZONE_DEPTHS:
			modifier += 0.10

	# Additional modifier based on exploration progress
	var exploration: Dictionary = SimMap.get_exploration_by_zone(state)
	var wilderness_explored: float = float(exploration.get(SimMap.ZONE_WILDERNESS, 0.0))
	var depths_explored: float = float(exploration.get(SimMap.ZONE_DEPTHS, 0.0))

	# More exploration = more enemies are "aware" of the player
	modifier += wilderness_explored * 0.02
	modifier += depths_explored * 0.05

	return modifier

## Get edge position weighted toward dangerous zones when threat is high
static func _get_weighted_edge_position(state: GameState) -> Vector2i:
	# When threat is high, spawn more from dangerous zone edges
	var prefer_dangerous: bool = state.threat_level > 0.5

	var attempts: int = 3
	var best_pos: Vector2i = Vector2i(-1, -1)
	var best_tier: int = 0

	for _i in range(attempts):
		var pos: Vector2i = _get_random_edge_position(state)
		if pos == Vector2i(-1, -1):
			continue

		var zone: String = SimMap.get_zone_at(state, pos)
		var tier: int = SimMap.get_zone_enemy_tier_max(zone)

		if prefer_dangerous:
			# Prefer positions in higher-tier zones
			if tier > best_tier:
				best_tier = tier
				best_pos = pos
		else:
			# First valid position is fine
			if best_pos == Vector2i(-1, -1):
				best_pos = pos

	# Fall back to single attempt if all failed
	if best_pos == Vector2i(-1, -1):
		best_pos = _get_random_edge_position(state)

	return best_pos

## Move roaming enemies, check for encounters
static func _tick_roaming_entities(state: GameState) -> Array[String]:
	var events: Array[String] = []

	for i in range(state.roaming_enemies.size() - 1, -1, -1):
		var entity: Dictionary = state.roaming_enemies[i]
		var moved := _move_roaming_enemy(state, entity)

		# Check if reached castle (trigger encounter)
		var pos: Vector2i = entity.get("pos", Vector2i.ZERO)
		if pos == state.base_pos:
			_convert_to_combat_enemy(state, entity)
			state.roaming_enemies.remove_at(i)
			events.append("An enemy attacks the castle!")
			continue

		# Check if too far from map (despawn)
		if not SimMap.in_bounds(pos.x, pos.y, state.map_w, state.map_h):
			state.roaming_enemies.remove_at(i)

	return events

## Update threat level based on roaming enemy proximity and zone danger
static func _tick_threat_level(state: GameState) -> void:
	var threat_contribution: float = 0.0
	var castle_dist_threshold := 5

	for entity in state.roaming_enemies:
		var pos: Vector2i = entity.get("pos", Vector2i.ZERO)
		var dist: int = abs(pos.x - state.base_pos.x) + abs(pos.y - state.base_pos.y)

		if dist <= castle_dist_threshold:
			# Base contribution for being near castle
			var base_threat: float = 1.0

			# Enemies from more dangerous zones contribute more threat
			var spawn_zone: String = str(entity.get("spawn_zone", SimMap.ZONE_SAFE))
			var zone_mult: float = SimMap.get_zone_threat_multiplier(spawn_zone)

			# Current position zone also matters (closer = more threatening)
			var current_zone: String = SimMap.get_zone_at(state, pos)
			var current_mult: float = SimMap.get_zone_threat_multiplier(current_zone)

			# Use average of spawn and current zone multipliers
			var avg_mult: float = (zone_mult + current_mult) / 2.0

			# Closer enemies are more threatening (inverse of distance)
			var proximity_bonus: float = 1.0 + (float(castle_dist_threshold - dist) / float(castle_dist_threshold))

			threat_contribution += base_threat * avg_mult * proximity_bonus

	if threat_contribution > 0:
		# Scale threat growth by contribution
		var growth: float = THREAT_GROWTH_RATE * threat_contribution
		state.threat_level = min(1.0, state.threat_level + growth)
	else:
		# Decay threat when no enemies nearby
		state.threat_level = max(0.0, state.threat_level - THREAT_DECAY_RATE)

	# Additional passive threat based on exploration of dangerous zones
	var exploration: Dictionary = SimMap.get_exploration_by_zone(state)
	var wilderness_explored: float = float(exploration.get(SimMap.ZONE_WILDERNESS, 0.0))
	var depths_explored: float = float(exploration.get(SimMap.ZONE_DEPTHS, 0.0))

	# Exploring dangerous zones slowly increases base threat
	if wilderness_explored > 0.1 or depths_explored > 0.05:
		var exploration_threat: float = (wilderness_explored * 0.002) + (depths_explored * 0.005)
		state.threat_level = min(1.0, state.threat_level + exploration_threat)

## Helper: Convert terrain to biome name
static func _terrain_to_biome(terrain: String) -> String:
	match terrain:
		SimMap.TERRAIN_FOREST:
			return "evergrove"
		SimMap.TERRAIN_MOUNTAIN:
			return "stonepass"
		SimMap.TERRAIN_WATER:
			return "mistfen"
		_:
			return "sunfields"

## Helper: Get random edge position
static func _get_random_edge_position(state: GameState) -> Vector2i:
	var edge: int = SimRng.roll_range(state, 0, 3)
	var pos: Vector2i
	match edge:
		0:  # Top
			pos = Vector2i(SimRng.roll_range(state, 0, state.map_w - 1), 0)
		1:  # Bottom
			pos = Vector2i(SimRng.roll_range(state, 0, state.map_w - 1), state.map_h - 1)
		2:  # Left
			pos = Vector2i(0, SimRng.roll_range(state, 0, state.map_h - 1))
		3:  # Right
			pos = Vector2i(state.map_w - 1, SimRng.roll_range(state, 0, state.map_h - 1))

	# Check terrain is passable
	if not SimMap.is_passable(state, pos):
		return Vector2i(-1, -1)
	return pos

## Create a roaming enemy entity - zone-aware selection
static func _create_roaming_enemy(state: GameState, pos: Vector2i) -> Dictionary:
	# Determine zone and max tier for this spawn position
	var zone: String = SimMap.get_zone_at(state, pos)
	var max_tier: int = SimMap.get_zone_enemy_tier_max(zone)

	# Build kind list based on zone tier and day
	var kind: String = _select_enemy_kind_for_zone(state, max_tier)

	var id: int = state.enemy_next_id
	state.enemy_next_id += 1

	return {
		"id": id,
		"kind": kind,
		"pos": pos,
		"target_pos": state.base_pos,  # Roam toward castle
		"state": "wandering",
		"move_timer": 0.0,
		"spawn_zone": zone  # Track origin zone for threat calculations
	}

## Select enemy kind based on zone tier limits and day progression
static func _select_enemy_kind_for_zone(state: GameState, max_tier: int) -> String:
	# Tier 1: Basic enemies (safe zone)
	var tier1: Array = ["raider", "scout"]

	# Tier 2: Moderate enemies (frontier)
	var tier2: Array = ["armored", "swarm"]

	# Tier 3: Dangerous enemies (wilderness)
	var tier3: Array = ["berserker", "tank", "phantom"]

	# Tier 4: Elite enemies (depths)
	var tier4: Array = ["champion", "healer", "elite"]

	# Build available kinds based on max tier and day
	var available: Array = []
	available.append_array(tier1)

	if max_tier >= 2 and state.day >= 3:
		available.append_array(tier2)
	if max_tier >= 3 and state.day >= 5:
		available.append_array(tier3)
	if max_tier >= 4 and state.day >= 7:
		available.append_array(tier4)

	# Weight selection - higher tier enemies are rarer
	var weights: Dictionary = {
		"raider": 6, "scout": 4,
		"armored": 3, "swarm": 3,
		"berserker": 2, "tank": 2, "phantom": 2,
		"champion": 1, "healer": 1, "elite": 1
	}

	var total_weight: int = 0
	for kind in available:
		total_weight += int(weights.get(kind, 1))

	if total_weight <= 0:
		return "raider"

	var roll: int = SimRng.roll_range(state, 1, total_weight)
	var running: int = 0
	for kind in available:
		running += int(weights.get(kind, 1))
		if roll <= running:
			return kind

	return "raider"

## Move a roaming enemy toward its target
static func _move_roaming_enemy(state: GameState, entity: Dictionary) -> bool:
	var pos: Vector2i = entity.get("pos", Vector2i.ZERO)
	var target: Vector2i = entity.get("target_pos", state.base_pos)

	if pos == target:
		return false

	# Simple movement toward target
	var dx: int = sign(target.x - pos.x)
	var dy: int = sign(target.y - pos.y)

	# Prefer horizontal or vertical based on RNG
	var new_pos: Vector2i = pos
	var prefer_x: bool = SimRng.roll_range(state, 0, 1) == 0

	if prefer_x and dx != 0:
		new_pos = Vector2i(pos.x + dx, pos.y)
	elif dy != 0:
		new_pos = Vector2i(pos.x, pos.y + dy)
	elif dx != 0:
		new_pos = Vector2i(pos.x + dx, pos.y)

	if SimMap.is_passable(state, new_pos):
		entity["pos"] = new_pos
		return true
	return false

## Convert roaming enemy to combat enemy
static func _convert_to_combat_enemy(state: GameState, roaming: Dictionary) -> void:
	var kind: String = roaming.get("kind", "raider")
	var enemy := SimEnemies.make_enemy(state, kind, state.base_pos)
	state.enemy_next_id += 1
	state.enemies.append(enemy)

	# Start encounter if not already in combat
	if state.activity_mode == "exploration":
		state.activity_mode = "encounter"
		state.phase = "night"
		state.night_spawn_remaining = 0
		state.night_wave_total = state.enemies.size()

## Start a focused encounter (player-initiated or enemy reaching castle)
static func start_encounter(state: GameState, enemies_to_add: Array = []) -> void:
	state.activity_mode = "encounter"
	state.phase = "night"
	state.night_spawn_remaining = 0

	for enemy_data in enemies_to_add:
		state.enemies.append(enemy_data)

	state.night_wave_total = state.enemies.size()

# ============================================================================
# Zone-Aware Threat System Utilities
# ============================================================================

## Calculate threat contribution for a roaming enemy based on zone and distance
static func calculate_enemy_threat_contribution(state: GameState, enemy: Dictionary) -> float:
	var pos: Vector2i = enemy.get("pos", Vector2i.ZERO)
	var dist: int = abs(pos.x - state.base_pos.x) + abs(pos.y - state.base_pos.y)
	var castle_dist_threshold := 5

	if dist > castle_dist_threshold:
		return 0.0

	var base_threat: float = 1.0

	# Spawn zone multiplier
	var spawn_zone: String = str(enemy.get("spawn_zone", SimMap.ZONE_SAFE))
	var zone_mult: float = SimMap.get_zone_threat_multiplier(spawn_zone)

	# Current position zone multiplier
	var current_zone: String = SimMap.get_zone_at(state, pos)
	var current_mult: float = SimMap.get_zone_threat_multiplier(current_zone)

	# Average of spawn and current zone
	var avg_mult: float = (zone_mult + current_mult) / 2.0

	# Proximity bonus
	var proximity_bonus: float = 1.0 + (float(castle_dist_threshold - dist) / float(castle_dist_threshold))

	return base_threat * avg_mult * proximity_bonus

## Get threat summary for debugging/display
static func get_threat_breakdown(state: GameState) -> Dictionary:
	var breakdown: Dictionary = {
		"total_threat": state.threat_level,
		"enemy_contributions": [],
		"exploration_pressure": 0.0,
		"cursor_zone": SimMap.get_cursor_zone(state)
	}

	# Calculate individual enemy contributions
	for entity in state.roaming_enemies:
		var contribution: float = calculate_enemy_threat_contribution(state, entity)
		if contribution > 0:
			breakdown["enemy_contributions"].append({
				"id": int(entity.get("id", 0)),
				"kind": str(entity.get("kind", "raider")),
				"spawn_zone": str(entity.get("spawn_zone", "")),
				"contribution": contribution
			})

	# Calculate exploration pressure
	var exploration: Dictionary = SimMap.get_exploration_by_zone(state)
	var wilderness_explored: float = float(exploration.get(SimMap.ZONE_WILDERNESS, 0.0))
	var depths_explored: float = float(exploration.get(SimMap.ZONE_DEPTHS, 0.0))

	if wilderness_explored > 0.1 or depths_explored > 0.05:
		breakdown["exploration_pressure"] = (wilderness_explored * 0.002) + (depths_explored * 0.005)

	return breakdown

## Format threat info for display
static func format_threat_info(state: GameState) -> String:
	var breakdown: Dictionary = get_threat_breakdown(state)
	var lines: Array[String] = []

	lines.append("Threat Level: %.1f%%" % (state.threat_level * 100))
	lines.append("Cursor Zone: %s" % SimMap.get_zone_name(str(breakdown.get("cursor_zone", ""))))

	var contributions: Array = breakdown.get("enemy_contributions", [])
	if not contributions.is_empty():
		lines.append("Nearby Enemies (%d):" % contributions.size())
		for c in contributions:
			lines.append("  %s from %s: +%.2f" % [str(c.get("kind", "")), str(c.get("spawn_zone", "")), float(c.get("contribution", 0))])

	var exploration_pressure: float = float(breakdown.get("exploration_pressure", 0.0))
	if exploration_pressure > 0:
		lines.append("Exploration Pressure: +%.3f/tick" % exploration_pressure)

	return "\n".join(lines)
