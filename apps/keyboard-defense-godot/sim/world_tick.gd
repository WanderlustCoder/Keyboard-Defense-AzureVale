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

## Spawn roaming enemies at map edges
static func _tick_roaming_spawns(state: GameState) -> String:
	if state.roaming_enemies.size() >= MAX_ROAMING_ENEMIES:
		return ""

	# Higher chance at night and high threat
	var time_modifier: float = 0.0
	if state.time_of_day > 0.7 or state.time_of_day < 0.2:  # Night
		time_modifier = 0.15
	var threat_modifier: float = state.threat_level * 0.1
	var spawn_chance: float = ROAMING_SPAWN_CHANCE + time_modifier + threat_modifier

	var roll: float = SimRng.roll_range(state, 0, 100) / 100.0
	if roll > spawn_chance:
		return ""

	# Pick edge spawn position
	var edge_pos: Vector2i = _get_random_edge_position(state)
	if edge_pos == Vector2i(-1, -1):
		return ""

	# Create roaming enemy
	var enemy := _create_roaming_enemy(state, edge_pos)
	state.roaming_enemies.append(enemy)

	return ""  # Silent spawn for atmosphere

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

## Update threat level based on roaming enemy proximity
static func _tick_threat_level(state: GameState) -> void:
	var enemies_near_castle: int = 0
	var castle_dist_threshold := 5

	for entity in state.roaming_enemies:
		var pos: Vector2i = entity.get("pos", Vector2i.ZERO)
		var dist: int = abs(pos.x - state.base_pos.x) + abs(pos.y - state.base_pos.y)
		if dist <= castle_dist_threshold:
			enemies_near_castle += 1

	if enemies_near_castle > 0:
		state.threat_level = min(1.0, state.threat_level + THREAT_GROWTH_RATE * enemies_near_castle)
	else:
		state.threat_level = max(0.0, state.threat_level - THREAT_DECAY_RATE)

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

## Create a roaming enemy entity
static func _create_roaming_enemy(state: GameState, pos: Vector2i) -> Dictionary:
	var kinds: Array = ["raider", "scout", "armored"]
	if state.day >= 3:
		kinds.append("swarm")
	if state.day >= 5:
		kinds.append("berserker")

	var kind_idx: int = SimRng.roll_range(state, 0, kinds.size() - 1)
	var kind: String = kinds[kind_idx]

	var id: int = state.enemy_next_id
	state.enemy_next_id += 1

	return {
		"id": id,
		"kind": kind,
		"pos": pos,
		"target_pos": state.base_pos,  # Roam toward castle
		"state": "wandering",
		"move_timer": 0.0
	}

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
