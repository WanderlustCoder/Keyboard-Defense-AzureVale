class_name SimTowerCombat
extends RefCounted
## Tower combat system - main attack dispatcher for all tower types

const GameState = preload("res://sim/types.gd")
const SimTowerTypes = preload("res://sim/tower_types.gd")
const SimTargeting = preload("res://sim/targeting.gd")
const SimDamageTypes = preload("res://sim/damage_types.gd")

const SimEnemies = preload("res://sim/enemies.gd")
const SimMap = preload("res://sim/map.gd")
const SimBuildings = preload("res://sim/buildings.gd")
const SimUpgrades = preload("res://sim/upgrades.gd")

# =============================================================================
# MAIN TOWER ATTACK STEP
# =============================================================================

## Main tower attack step - replaces existing _tower_attack_step in apply_intent.gd
static func tower_attack_step(
	state: GameState,
	dist_field: PackedInt32Array,
	events: Array[String]
) -> void:
	if state.enemies.is_empty():
		return

	# Collect all towers with their types
	var towers: Array[Dictionary] = []
	for key in state.structures.keys():
		var building_type: String = str(state.structures[key])
		if _is_tower_type(building_type):
			# Skip reference tiles for multi-tile towers
			if ":ref:" in building_type:
				continue
			towers.append({
				"index": int(key),
				"type": building_type,
				"level": int(state.structure_levels.get(key, 1))
			})

	# Sort by index for determinism
	towers.sort_custom(func(a, b): return int(a["index"]) < int(b["index"]))

	# Process each tower
	for tower in towers:
		if state.enemies.is_empty():
			return
		_process_tower_attack(state, tower, dist_field, events)

	# Note: Status effect ticks are handled in _enemy_ability_tick in apply_intent.gd
	# to avoid double-ticking (DoT damage, effect expiration)

	# Check trap triggers
	_check_trap_triggers(state, events)

# =============================================================================
# TOWER ATTACK DISPATCHER
# =============================================================================

static func _process_tower_attack(
	state: GameState,
	tower: Dictionary,
	dist_field: PackedInt32Array,
	events: Array[String]
) -> void:
	var tower_type: String = str(tower.get("type", "tower"))
	var tower_index: int = int(tower.get("index", 0))
	var tower_pos: Vector2i = SimMap.pos_from_index(tower_index, state.map_w)
	var level: int = int(tower.get("level", 1))

	# Get tower stats from type definitions
	var stats: Dictionary = SimTowerTypes.get_base_stats(tower_type)
	if stats.is_empty():
		# Fall back to legacy tower behavior
		_attack_legacy_tower(state, tower_index, tower_pos, level, dist_field, events)
		return

	# Get target type from stats (enum value)
	var target_type: int = int(stats.get("target_type", SimTowerTypes.TargetType.SINGLE))

	# Get support tower buff if applicable
	var support_buff: float = _get_support_buff(state, tower_pos)

	# Dispatch based on target type
	match target_type:
		SimTowerTypes.TargetType.SINGLE:
			_attack_single(state, tower_index, tower_pos, level, tower_type, stats, support_buff, dist_field, events)
		SimTowerTypes.TargetType.MULTI:
			_attack_multi(state, tower_index, tower_pos, level, tower_type, stats, support_buff, dist_field, events)
		SimTowerTypes.TargetType.AOE:
			_attack_aoe(state, tower_index, tower_pos, level, tower_type, stats, support_buff, dist_field, events)
		SimTowerTypes.TargetType.CHAIN:
			_attack_chain(state, tower_index, tower_pos, level, tower_type, stats, support_buff, dist_field, events)
		SimTowerTypes.TargetType.ADAPTIVE:
			_attack_adaptive(state, tower_index, tower_pos, level, tower_type, stats, support_buff, dist_field, events)
		SimTowerTypes.TargetType.NONE:
			# Non-attacking towers (support, summoner, trap)
			_process_non_attacking_tower(state, tower_index, tower_pos, level, tower_type, stats, events)

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

## Calculate effective tower range including level bonus and research effects
static func _get_effective_range(state: GameState, base_range: int, level: int) -> int:
	var range_val: int = base_range + int((level - 1) * 0.5)
	range_val += SimUpgrades.get_tower_range_bonus(state)
	return range_val

# =============================================================================
# ATTACK IMPLEMENTATIONS
# =============================================================================

## Single target attack (Arrow, Magic, Holy, etc.)
static func _attack_single(
	state: GameState,
	tower_index: int,
	tower_pos: Vector2i,
	level: int,
	tower_type: String,
	stats: Dictionary,
	support_buff: float,
	dist_field: PackedInt32Array,
	events: Array[String]
) -> void:
	var range_val: int = _get_effective_range(state, int(stats.get("range", 4)), level)
	var base_damage: int = int(stats.get("damage", 10)) + (level - 1) * 3
	var damage_type: int = int(stats.get("damage_type", SimTowerTypes.DamageType.PHYSICAL))
	var shots: int = int(stats.get("shots_per_attack", 1))

	# Handle attack type modifiers
	var attack_type: int = int(stats.get("attack_type", SimTowerTypes.AttackType.STANDARD))

	for _shot in range(shots):
		if state.enemies.is_empty():
			return

		# Select target
		var target_index: int
		if attack_type == SimTowerTypes.AttackType.PURIFY:
			target_index = SimTargeting.pick_boss_or_affixed_target(
				state.enemies, dist_field, state.map_w, tower_pos, range_val
			)
		else:
			target_index = SimTargeting.pick_single_target(
				state.enemies, dist_field, state.map_w, tower_pos, range_val
			)

		if target_index < 0:
			return

		var enemy: Dictionary = state.enemies[target_index]
		var final_damage: int = SimDamageTypes.calculate_damage(
			base_damage, damage_type, enemy, state
		)

		# Apply support buff
		if support_buff > 0:
			final_damage = int(float(final_damage) * (1.0 + support_buff))

		# Apply attack type specific effects
		_apply_attack_effects(state, target_index, tower_type, stats, level, events)

		# Apply damage
		_apply_damage_to_enemy(state, target_index, final_damage, events, SimTowerTypes.get_tower_name(tower_type))

## Multi-target attack (Multi-Shot)
static func _attack_multi(
	state: GameState,
	tower_index: int,
	tower_pos: Vector2i,
	level: int,
	tower_type: String,
	stats: Dictionary,
	support_buff: float,
	dist_field: PackedInt32Array,
	events: Array[String]
) -> void:
	var range_val: int = _get_effective_range(state, int(stats.get("range", 4)), level)
	var base_damage: int = int(stats.get("damage", 8)) + (level - 1) * 2
	var damage_type: int = int(stats.get("damage_type", SimTowerTypes.DamageType.PHYSICAL))
	var target_count: int = int(stats.get("target_count", 3)) + (level - 1)

	var targets: Array[int] = SimTargeting.pick_multi_targets(
		state.enemies, dist_field, state.map_w, tower_pos, range_val, target_count
	)

	if targets.is_empty():
		return

	var tower_name: String = SimTowerTypes.get_tower_name(tower_type)
	events.append("%s fires at %d targets." % [tower_name, targets.size()])

	# Sort descending to handle removals safely
	targets.sort()
	targets.reverse()

	for enemy_index in targets:
		if enemy_index >= state.enemies.size():
			continue
		var enemy: Dictionary = state.enemies[enemy_index]
		var final_damage: int = SimDamageTypes.calculate_damage(
			base_damage, damage_type, enemy, state
		)
		if support_buff > 0:
			final_damage = int(float(final_damage) * (1.0 + support_buff))
		_apply_damage_to_enemy(state, enemy_index, final_damage, events, tower_name)

## AoE attack (Cannon)
static func _attack_aoe(
	state: GameState,
	tower_index: int,
	tower_pos: Vector2i,
	level: int,
	tower_type: String,
	stats: Dictionary,
	support_buff: float,
	dist_field: PackedInt32Array,
	events: Array[String]
) -> void:
	var range_val: int = _get_effective_range(state, int(stats.get("range", 4)), level)
	var base_damage: int = int(stats.get("damage", 25)) + (level - 1) * 8
	var damage_type: int = int(stats.get("damage_type", SimTowerTypes.DamageType.PHYSICAL))
	var aoe_radius: int = int(stats.get("aoe_radius", 1)) + int((level - 1) * 0.25)

	# Pick primary target
	var aoe_result: Dictionary = SimTargeting.pick_aoe_primary_and_splash(
		state.enemies, dist_field, state.map_w, tower_pos, range_val, aoe_radius
	)

	if aoe_result.primary_index < 0:
		return

	var center: Vector2i = aoe_result.center
	var splash_targets: Array[int] = aoe_result.splash_indices

	var tower_name: String = SimTowerTypes.get_tower_name(tower_type)
	events.append("%s fires at (%d,%d), hitting %d enemies." % [
		tower_name, center.x, center.y, splash_targets.size()
	])

	# Sort descending to handle removals safely
	splash_targets.sort()
	splash_targets.reverse()

	for enemy_index in splash_targets:
		if enemy_index >= state.enemies.size():
			continue
		var enemy: Dictionary = state.enemies[enemy_index]
		var final_damage: int = SimDamageTypes.calculate_aoe_damage(
			base_damage, damage_type, enemy, state, center, false
		)
		if support_buff > 0:
			final_damage = int(float(final_damage) * (1.0 + support_buff))
		_apply_damage_to_enemy(state, enemy_index, final_damage, events, tower_name)

## Chain lightning attack (Tesla)
static func _attack_chain(
	state: GameState,
	tower_index: int,
	tower_pos: Vector2i,
	level: int,
	tower_type: String,
	stats: Dictionary,
	support_buff: float,
	dist_field: PackedInt32Array,
	events: Array[String]
) -> void:
	var range_val: int = _get_effective_range(state, int(stats.get("range", 3)), level)
	var base_damage: int = int(stats.get("damage", 12)) + (level - 1) * 3
	var damage_type: int = int(stats.get("damage_type", SimTowerTypes.DamageType.LIGHTNING))
	var chain_count: int = int(stats.get("chain_count", 5)) + (level - 1)
	var chain_range: int = int(stats.get("chain_range", 2))
	var chain_falloff: float = float(stats.get("chain_damage_falloff", 0.8))

	# Check for synergy boost
	if _has_chain_synergy(state, tower_pos):
		chain_count += 3
		chain_falloff = 1.0  # No falloff

	var chain_targets: Array[int] = SimTargeting.pick_chain_primary_and_jumps(
		state.enemies, dist_field, state.map_w, tower_pos, range_val, chain_count, chain_range
	)

	if chain_targets.is_empty():
		return

	var tower_name: String = SimTowerTypes.get_tower_name(tower_type)
	events.append("%s arcs to %d enemies." % [tower_name, chain_targets.size()])

	# Build damage list with falloff
	var damage_list: Array[Dictionary] = []
	for i in range(chain_targets.size()):
		var enemy_index: int = chain_targets[i]
		var damage: int = SimDamageTypes.calculate_chain_damage(
			base_damage, damage_type, state.enemies[enemy_index], state, i, chain_falloff
		)
		if support_buff > 0:
			damage = int(float(damage) * (1.0 + support_buff))
		damage_list.append({"index": enemy_index, "damage": damage})

	# Sort by index descending
	damage_list.sort_custom(func(a, b): return int(a["index"]) > int(b["index"]))

	for item in damage_list:
		var enemy_index: int = int(item["index"])
		if enemy_index >= state.enemies.size():
			continue
		_apply_damage_to_enemy(state, enemy_index, int(item["damage"]), events, tower_name)

## Adaptive attack (Legendary towers)
static func _attack_adaptive(
	state: GameState,
	tower_index: int,
	tower_pos: Vector2i,
	level: int,
	tower_type: String,
	stats: Dictionary,
	support_buff: float,
	dist_field: PackedInt32Array,
	events: Array[String]
) -> void:
	var range_val: int = _get_effective_range(state, int(stats.get("range", 5)), level)
	var base_damage: int = int(stats.get("damage", 25))
	var damage_type: int = int(stats.get("damage_type", SimTowerTypes.DamageType.PURE))

	var adaptive_result: Dictionary = SimTargeting.pick_adaptive_target(
		state, state.enemies, dist_field, tower_pos, range_val
	)

	if adaptive_result.primary_index < 0:
		return

	var tower_name: String = SimTowerTypes.get_tower_name(tower_type)
	var mode: String = str(adaptive_result.get("mode", "alpha"))

	match mode:
		"alpha":
			# Single target focus
			var enemy: Dictionary = state.enemies[adaptive_result.primary_index]
			var final_damage: int = SimDamageTypes.calculate_damage(
				base_damage, damage_type, enemy, state
			)
			if support_buff > 0:
				final_damage = int(float(final_damage) * (1.0 + support_buff))
			events.append("%s (Alpha) focuses fire!" % tower_name)
			_apply_damage_to_enemy(state, adaptive_result.primary_index, final_damage, events, tower_name)

		"epsilon":
			# Chain all
			var targets: Array = adaptive_result.additional_indices
			targets.insert(0, adaptive_result.primary_index)
			events.append("%s (Epsilon) chains to %d enemies!" % [tower_name, targets.size()])
			targets.sort()
			targets.reverse()
			for enemy_index in targets:
				if enemy_index >= state.enemies.size():
					continue
				var enemy: Dictionary = state.enemies[enemy_index]
				var final_damage: int = SimDamageTypes.calculate_damage(
					base_damage, damage_type, enemy, state
				)
				_apply_damage_to_enemy(state, enemy_index, final_damage, events, tower_name)

		"omega":
			# Heal on kill
			var enemy: Dictionary = state.enemies[adaptive_result.primary_index]
			var final_damage: int = SimDamageTypes.calculate_damage(
				base_damage, damage_type, enemy, state
			)
			events.append("%s (Omega) strikes to heal!" % tower_name)
			var killed: bool = _apply_damage_to_enemy(state, adaptive_result.primary_index, final_damage, events, tower_name)
			if killed:
				state.hp = min(state.hp + 1, 10)  # Heal 1 HP on kill
				events.append("Castle healed! (+1 HP)")

# =============================================================================
# NON-ATTACKING TOWERS
# =============================================================================

static func _process_non_attacking_tower(
	state: GameState,
	tower_index: int,
	tower_pos: Vector2i,
	level: int,
	tower_type: String,
	stats: Dictionary,
	events: Array[String]
) -> void:
	match tower_type:
		SimTowerTypes.TOWER_SUMMONER:
			_process_summoner(state, tower_index, tower_pos, level, stats, events)
		SimTowerTypes.TOWER_TRAP:
			_process_trap_tower(state, tower_index, tower_pos, level, stats, events)
		SimTowerTypes.TOWER_SUPPORT:
			# Support tower aura is passive, handled in _get_support_buff
			pass

## Process summoner tower
static func _process_summoner(
	state: GameState,
	tower_index: int,
	tower_pos: Vector2i,
	level: int,
	stats: Dictionary,
	events: Array[String]
) -> void:
	var max_summons: int = int(stats.get("max_summons", 3)) + (level - 1)
	var summon_cooldown: float = float(stats.get("summon_cooldown", 15.0))
	var summon_type: String = str(stats.get("default_summon", "word_warrior"))

	# Get current summons for this tower
	var current_summons: Array = state.tower_summon_ids.get(tower_index, [])

	# Clean up dead summons
	var alive_summons: Array = []
	for summon_id in current_summons:
		if _summon_exists(state, int(summon_id)):
			alive_summons.append(summon_id)
	state.tower_summon_ids[tower_index] = alive_summons
	current_summons = alive_summons

	# Check cooldown
	var current_cooldown: float = float(state.tower_cooldowns.get(tower_index, 0.0))
	if current_cooldown > 0:
		state.tower_cooldowns[tower_index] = current_cooldown - 1.0
		return

	# Can we summon?
	if current_summons.size() >= max_summons:
		return

	# Summon!
	var summon: Dictionary = _create_summon(state, summon_type, tower_pos, tower_index, level)
	state.summoned_units.append(summon)
	current_summons.append(summon["id"])
	state.tower_summon_ids[tower_index] = current_summons
	state.tower_cooldowns[tower_index] = summon_cooldown

	events.append("Summoner creates %s!" % summon_type.replace("_", " ").capitalize())

## Process trap tower
static func _process_trap_tower(
	state: GameState,
	tower_index: int,
	tower_pos: Vector2i,
	level: int,
	stats: Dictionary,
	events: Array[String]
) -> void:
	var trap_count: int = int(stats.get("trap_count", 3)) + (level - 1)
	var trap_recharge: float = float(stats.get("trap_recharge_time", 10.0)) - float(level - 1)
	var placement_range: int = int(stats.get("placement_range", 5))

	# Count existing traps for this tower
	var existing_traps: int = 0
	for trap in state.active_traps:
		if int(trap.get("owner_index", -1)) == tower_index:
			existing_traps += 1

	if existing_traps >= trap_count:
		return

	# Check cooldown
	var cooldown: float = float(state.tower_cooldowns.get(tower_index, 0.0))
	if cooldown > 0:
		state.tower_cooldowns[tower_index] = cooldown - 1.0
		return

	# Find placement position
	var trap_pos: Vector2i = _find_trap_placement(state, tower_pos, placement_range)
	if trap_pos == Vector2i(-1, -1):
		return

	# Place trap
	var trap := {
		"pos": trap_pos,
		"damage": int(stats.get("damage", 30)) + (level - 1) * 10,
		"radius": int(stats.get("trap_radius", 1)),
		"owner_index": tower_index
	}
	state.active_traps.append(trap)
	state.tower_cooldowns[tower_index] = trap_recharge

	events.append("Trap placed at (%d,%d)." % [trap_pos.x, trap_pos.y])

# =============================================================================
# ATTACK EFFECTS
# =============================================================================

static func _apply_attack_effects(
	state: GameState,
	target_index: int,
	tower_type: String,
	stats: Dictionary,
	level: int,
	events: Array[String]
) -> void:
	var enemy: Dictionary = state.enemies[target_index]
	var enemy_id: int = int(enemy.get("id", 0))

	# Slow effect (Frost tower)
	if stats.has("slow_percent"):
		var slow_percent: int = int(stats.get("slow_percent", 25)) + (level - 1) * 5
		var slow_duration: float = float(stats.get("slow_duration", 2.0)) + float(level - 1) * 0.5
		enemy = SimEnemies.apply_status_effect(enemy, "slow", 1, tower_type)
		state.enemies[target_index] = enemy
		var kind: String = str(enemy.get("kind", "enemy"))
		events.append("%s#%d slowed." % [kind, enemy_id])

	# Poison effect (Poison tower)
	if stats.has("poison_damage_per_tick"):
		enemy = SimEnemies.apply_status_effect(enemy, "poisoned", level, tower_type)
		state.enemies[target_index] = enemy
		events.append("Enemy poisoned! (stack added)")

	# Purify attempt (Holy tower)
	if stats.has("purify_chance"):
		var purify_chance: int = int(stats.get("purify_chance", 5)) + (level - 1) * 3
		var has_affix: bool = enemy.has("affix") and str(enemy.get("affix", "")) != ""
		if has_affix:
			var roll: int = _roll_percent(state)
			if roll <= purify_chance:
				enemy = SimEnemies.apply_status_effect(enemy, "purifying", 1, tower_type)
				state.enemies[target_index] = enemy
				events.append("Purification begun on %s#%d!" % [
					str(enemy.get("kind", "enemy")), enemy_id
				])

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

## Apply damage to enemy, returns true if killed
static func _apply_damage_to_enemy(
	state: GameState,
	enemy_index: int,
	damage: int,
	events: Array[String],
	source: String
) -> bool:
	if enemy_index < 0 or enemy_index >= state.enemies.size():
		return false

	var enemy: Dictionary = state.enemies[enemy_index]
	var enemy_id: int = int(enemy.get("id", 0))
	var kind: String = str(enemy.get("kind", "enemy"))

	enemy["hp"] = int(enemy.get("hp", 0)) - damage
	state.enemies[enemy_index] = enemy

	events.append("%s hits %s#%d for %d." % [source, kind, enemy_id, damage])

	if int(enemy.get("hp", 0)) <= 0:
		_handle_enemy_death(state, enemy_index, events)
		return true

	return false

static func _handle_enemy_death(
	state: GameState,
	enemy_index: int,
	events: Array[String]
) -> void:
	if enemy_index < 0 or enemy_index >= state.enemies.size():
		return

	var enemy: Dictionary = state.enemies[enemy_index]
	var enemy_id: int = int(enemy.get("id", 0))
	var kind: String = str(enemy.get("kind", "enemy"))

	# Handle splitting affix - spawn 2 swarm minions
	if str(enemy.get("affix", "")) == "splitting":
		var enemy_pos: Vector2i = enemy.get("pos", Vector2i.ZERO)
		_spawn_split_enemies(state, enemy_pos, events)

	# Handle explosive affix
	if enemy.get("explosive", false) or str(enemy.get("affix", "")) == "explosive":
		if not state.practice_mode:
			state.hp -= 2
			events.append("Enemy explodes! Castle takes 2 damage.")

	# Award gold
	var gold_reward: int = SimEnemies.gold_reward(kind)
	state.gold += gold_reward

	state.enemies.remove_at(enemy_index)
	events.append("Enemy %s#%d destroyed. +%d gold" % [kind, enemy_id, gold_reward])

static func _is_tower_type(building_type: String) -> bool:
	return building_type.begins_with("tower")

static func _get_support_buff(state: GameState, tower_pos: Vector2i) -> float:
	var buff: float = 0.0

	for key in state.structures.keys():
		var building_type: String = str(state.structures[key])
		if building_type != SimTowerTypes.TOWER_SUPPORT:
			continue

		var support_pos: Vector2i = SimMap.pos_from_index(int(key), state.map_w)
		var support_stats: Dictionary = SimTowerTypes.get_base_stats(SimTowerTypes.TOWER_SUPPORT)
		var aura_range: int = int(support_stats.get("aura_range", 3))

		if SimEnemies.manhattan(tower_pos, support_pos) <= aura_range:
			var level: int = int(state.structure_levels.get(key, 1))
			var damage_buff: float = float(support_stats.get("damage_buff_percent", 15)) / 100.0
			damage_buff += float(level - 1) * 0.05  # +5% per level
			buff = max(buff, damage_buff)

	return buff

static func _has_chain_synergy(state: GameState, tower_pos: Vector2i) -> bool:
	# Check for Chain Reaction synergy (Tesla + Magic Chain)
	for synergy in state.active_synergies:
		if str(synergy.get("synergy_id", "")) == "chain_reaction":
			return true
	return false

static func _summon_exists(state: GameState, summon_id: int) -> bool:
	for summon in state.summoned_units:
		if int(summon.get("id", 0)) == summon_id:
			return true
	return false

static func _create_summon(
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
		"range": int(type_data.get("range", 1)),
		"owner_index": owner_index,
		"attack_cooldown": 0.0
	}

	if type_data.get("flying", false):
		summon["flying"] = true
	if type_data.get("taunt", false):
		summon["taunt"] = true

	state.summoned_next_id += 1
	return summon

static func _find_trap_placement(
	state: GameState,
	origin: Vector2i,
	max_range: int
) -> Vector2i:
	var best_pos: Vector2i = Vector2i(-1, -1)
	var best_dist_to_base: int = 999999
	var dist_field: PackedInt32Array = SimMap.compute_dist_to_base(state)

	for dx in range(-max_range, max_range + 1):
		for dy in range(-max_range, max_range + 1):
			if abs(dx) + abs(dy) > max_range:
				continue

			var pos: Vector2i = origin + Vector2i(dx, dy)
			if not SimMap.in_bounds(pos.x, pos.y, state.map_w, state.map_h):
				continue
			if not SimMap.is_passable(state, pos):
				continue

			# Check for existing trap
			var has_trap: bool = false
			for trap in state.active_traps:
				if trap.get("pos", Vector2i(-1, -1)) == pos:
					has_trap = true
					break
			if has_trap:
				continue

			# Prefer tiles closer to base (enemies will walk there)
			var dist: int = SimEnemies.dist_at(dist_field, pos, state.map_w)
			if dist >= 0 and dist < best_dist_to_base:
				best_dist_to_base = dist
				best_pos = pos

	return best_pos

static func _check_trap_triggers(
	state: GameState,
	events: Array[String]
) -> void:
	var triggered: Array[int] = []

	for i in range(state.active_traps.size()):
		var trap: Dictionary = state.active_traps[i]
		var trap_pos: Vector2i = trap.get("pos", Vector2i.ZERO)
		var trap_radius: int = int(trap.get("radius", 1))
		var trap_damage: int = int(trap.get("damage", 30))

		# Check for enemies in trap radius
		for enemy in state.enemies:
			var enemy_pos: Vector2i = enemy.get("pos", Vector2i.ZERO)
			if SimEnemies.manhattan(trap_pos, enemy_pos) <= trap_radius:
				# Trigger!
				triggered.append(i)

				# Damage all enemies in radius
				var targets: Array[int] = SimTargeting.get_aoe_targets(
					state.enemies, trap_pos, trap_radius
				)

				events.append("TRAP TRIGGERED at (%d,%d)!" % [trap_pos.x, trap_pos.y])

				# Process in reverse
				targets.sort()
				targets.reverse()
				for enemy_index in targets:
					if enemy_index >= state.enemies.size():
						continue
					_apply_damage_to_enemy(state, enemy_index, trap_damage, events, "Trap")

				break

	# Remove triggered traps (reverse order)
	triggered.sort()
	triggered.reverse()
	for i in triggered:
		if i < state.active_traps.size():
			state.active_traps.remove_at(i)

static func _roll_percent(state: GameState) -> int:
	state.rng_state = (state.rng_state * 1103515245 + 12345) % 2147483648
	return (state.rng_state >> 16) % 101

## Legacy tower attack for backward compatibility
static func _attack_legacy_tower(
	state: GameState,
	tower_index: int,
	tower_pos: Vector2i,
	level: int,
	dist_field: PackedInt32Array,
	events: Array[String]
) -> void:
	var stats: Dictionary = SimBuildings.tower_stats(level)
	var range_val: int = _get_effective_range(state, int(stats.get("range", 3)), level)
	var damage: int = int(stats.get("damage", 1))
	var shots: int = int(stats.get("shots", 1))

	for _shot in range(shots):
		if state.enemies.is_empty():
			return

		var target_index: int = SimEnemies.pick_target_index(
			state.enemies, dist_field, state.map_w, tower_pos, range_val
		)

		if target_index < 0:
			return

		_apply_damage_to_enemy(state, target_index, damage, events, "Tower")

## Spawn split enemies when a splitting enemy dies
static func _spawn_split_enemies(
	state: GameState,
	origin_pos: Vector2i,
	events: Array[String]
) -> void:
	# Spawn 2 swarm enemies near the origin position
	var offsets: Array[Vector2i] = [
		Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
		Vector2i(1, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1)
	]
	var spawned: int = 0
	for offset in offsets:
		if spawned >= 2:
			break
		var pos: Vector2i = origin_pos + offset
		if not SimMap.in_bounds(pos.x, pos.y, state.map_w, state.map_h):
			continue
		if pos == state.base_pos:
			continue
		SimMap.ensure_tile_generated(state, pos)
		if not SimMap.is_passable(state, pos):
			continue
		var enemy: Dictionary = SimEnemies.make_enemy(state, "swarm", pos)
		state.enemy_next_id += 1
		state.enemies.append(enemy)
		events.append("Split! Swarm#%d spawns at (%d,%d) word=%s." % [
			int(enemy.get("id", 0)),
			pos.x,
			pos.y,
			str(enemy.get("word", ""))
		])
		spawned += 1
