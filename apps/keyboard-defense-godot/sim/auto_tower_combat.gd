class_name SimAutoTowerCombat
extends RefCounted
## Auto-Tower Combat System - Processes tower attacks with special mechanics

# =============================================================================
# MAIN COMBAT FUNCTION
# =============================================================================

static func process_auto_towers(
	state: GameState,
	enemies: Array,
	tower_cooldowns: Dictionary,
	tower_states: Dictionary,
	delta: float,
	speed_buff: float = 1.0
) -> Dictionary:
	var result := {
		"attacks": [],
		"updated_cooldowns": tower_cooldowns.duplicate(),
		"updated_states": tower_states.duplicate(),
		"damage_events": []
	}

	if enemies.is_empty():
		return result

	var auto_towers: Array[Dictionary] = SimBuildings.get_all_auto_towers(state)
	if auto_towers.is_empty():
		return result

	# Update cooldowns
	for tower_index in result.updated_cooldowns.keys():
		result.updated_cooldowns[tower_index] = maxf(0.0, float(result.updated_cooldowns[tower_index]) - delta)

	# Update special mechanics (heat cooldown, fuel regen)
	_update_tower_states(result.updated_states, auto_towers, delta)

	# Process each auto-tower
	for tower in auto_towers:
		var tower_idx: int = int(tower.get("index", 0))
		var tower_type: String = str(tower.get("type", ""))
		var cooldown_remaining: float = float(result.updated_cooldowns.get(tower_idx, 0))

		if cooldown_remaining > 0:
			continue

		# Check special mechanics that might prevent firing
		if not _can_fire(tower_type, result.updated_states.get(tower_idx, {})):
			continue

		var attack_result := _process_single_tower(tower, enemies, speed_buff, result.updated_states.get(tower_idx, {}))

		if attack_result.hit:
			result.attacks.append(attack_result)
			result.updated_cooldowns[tower_idx] = attack_result.cooldown
			result.damage_events.append_array(attack_result.damage_events)

			# Update tower state for special mechanics
			_apply_firing_effects(tower_type, tower_idx, result.updated_states)

	return result


# =============================================================================
# SINGLE TOWER PROCESSING
# =============================================================================

static func _process_single_tower(tower: Dictionary, enemies: Array, speed_buff: float, tower_state: Dictionary) -> Dictionary:
	var result := {
		"hit": false,
		"tower_index": int(tower.get("index", 0)),
		"tower_type": str(tower.get("type", "")),
		"tower_pos": tower.get("pos", Vector2i.ZERO),
		"cooldown": 0.0,
		"damage_events": [],
		"effect_type": "projectile"
	}

	var tower_pos: Vector2i = tower.get("pos", Vector2i.ZERO)
	var tower_type: String = str(tower.get("type", ""))
	var attack_range: int = int(tower.get("range", 2))
	var base_damage: int = int(tower.get("damage", 1))
	var base_cooldown: float = float(tower.get("cooldown", 1.0))
	var targeting: String = str(tower.get("targeting", "nearest"))

	# Apply speed buff to cooldown
	var cooldown: float = base_cooldown / speed_buff
	result.cooldown = cooldown

	# Get tower type data for special mechanics
	var tower_data: Dictionary = SimAutoTowerTypes.get_tower(tower_type)
	var special: Dictionary = tower_data.get("special", {})
	var damage_type: int = int(tower_data.get("damage_type", SimAutoTowerTypes.DamageType.PHYSICAL))

	# Apply damage ramp for inferno
	var damage: int = base_damage
	if special.get("ramp_max_multiplier", 0) > 0:
		var ramp_mult: float = float(tower_state.get("ramp_multiplier", 1.0))
		damage = int(float(base_damage) * ramp_mult)

	# Get targeting mode
	var target_mode: int = _targeting_string_to_mode(targeting)

	# Convert enemies to targeting format
	var enemy_data: Array = _convert_enemies_for_targeting(enemies)

	# Pick target(s)
	var target_result := SimAutoTargeting.pick_target(enemy_data, tower_pos, attack_range, target_mode)

	if target_result.target_index < 0 and target_result.additional_targets.is_empty():
		return result

	result.hit = true

	# Generate damage events based on targeting mode
	match target_mode:
		SimAutoTowerTypes.TargetMode.ZONE:
			result.effect_type = "aoe"
			for target in target_result.additional_targets:
				result.damage_events.append(_make_damage_event(
					int(target.index), damage, damage_type, tower_type, special
				))

		SimAutoTowerTypes.TargetMode.CHAIN:
			result.effect_type = "chain"
			# Primary target
			result.damage_events.append(_make_damage_event(
				target_result.target_index, damage, damage_type, tower_type, special
			))
			# Chain targets with falloff
			var chain_falloff: float = float(special.get("chain_falloff", 0.8))
			var chain_damage: int = damage
			for target in target_result.additional_targets:
				chain_damage = int(float(chain_damage) * chain_falloff)
				result.damage_events.append(_make_damage_event(
					int(target.index), chain_damage, damage_type, tower_type, special, true
				))

		SimAutoTowerTypes.TargetMode.CLUSTER:
			result.effect_type = "splash"
			# Main target gets full damage
			result.damage_events.append(_make_damage_event(
				target_result.target_index, damage, damage_type, tower_type, special
			))
			# Splash damage to nearby
			var splash_radius: int = int(special.get("splash_radius", 0))
			var splash_percent: float = float(special.get("splash_damage_percent", 60)) / 100.0
			if splash_radius > 0:
				var splash_indices := SimAutoTargeting.get_enemies_in_splash_radius(
					enemy_data, target_result.cluster_center, splash_radius
				)
				for idx in splash_indices:
					if idx != target_result.target_index:
						result.damage_events.append(_make_damage_event(
							idx, int(float(damage) * splash_percent), damage_type, tower_type, {}, true
						))

		SimAutoTowerTypes.TargetMode.CONTACT:
			result.effect_type = "contact"
			for target in target_result.additional_targets:
				result.damage_events.append(_make_damage_event(
					int(target.index), damage, damage_type, tower_type, special
				))

		_:
			# Single target (NEAREST, HIGHEST_HP, LOWEST_HP, FASTEST, SMART)
			result.damage_events.append(_make_damage_event(
				target_result.target_index, damage, damage_type, tower_type, special
			))

	return result


# =============================================================================
# DAMAGE EVENT GENERATION
# =============================================================================

static func _make_damage_event(
	enemy_index: int,
	damage: int,
	damage_type: int,
	tower_type: String,
	special: Dictionary,
	is_secondary: bool = false
) -> Dictionary:
	var event := {
		"enemy_index": enemy_index,
		"damage": damage,
		"damage_type": damage_type,
		"tower_type": tower_type,
		"is_secondary": is_secondary,
		"effects": []
	}

	# Add special effects based on damage type and tower special properties
	match damage_type:
		SimAutoTowerTypes.DamageType.FIRE:
			if special.get("burn_damage", 0) > 0:
				event.effects.append({
					"type": "burning",
					"damage": int(special.get("burn_damage", 3)),
					"duration": float(special.get("burn_duration", 3.0))
				})

		SimAutoTowerTypes.DamageType.LIGHTNING:
			if special.get("stun_chance", 0) > 0:
				event.effects.append({
					"type": "stun_chance",
					"chance": int(special.get("stun_chance", 20)),
					"duration": float(special.get("stun_duration", 1.0))
				})

		SimAutoTowerTypes.DamageType.NATURE:
			if special.get("slow_percent", 0) > 0:
				event.effects.append({
					"type": "slow",
					"percent": int(special.get("slow_percent", 15))
				})
			if special.get("root_chance", 0) > 0:
				event.effects.append({
					"type": "root_chance",
					"chance": int(special.get("root_chance", 10))
				})

		SimAutoTowerTypes.DamageType.SIEGE:
			if special.get("armor_pierce", 0) > 0:
				event.effects.append({
					"type": "armor_pierce",
					"percent": int(special.get("armor_pierce", 50))
				})

	return event


# =============================================================================
# SPECIAL MECHANICS
# =============================================================================

static func _can_fire(tower_type: String, tower_state: Dictionary) -> bool:
	# Check overheat
	if SimAutoTowerTypes.has_overheat(tower_type):
		var heat: float = float(tower_state.get("heat", 0))
		var config := SimAutoTowerTypes.get_overheat_config(tower_type)
		if heat >= float(config.get("max_heat", 100)):
			return false

	# Check fuel
	if SimAutoTowerTypes.uses_fuel(tower_type):
		var fuel: float = float(tower_state.get("fuel", 0))
		if fuel <= 0:
			return false

	return true


static func _apply_firing_effects(tower_type: String, tower_idx: int, states: Dictionary) -> void:
	if not states.has(tower_idx):
		states[tower_idx] = {}

	var state: Dictionary = states[tower_idx]

	# Overheat mechanic
	if SimAutoTowerTypes.has_overheat(tower_type):
		var config := SimAutoTowerTypes.get_overheat_config(tower_type)
		var heat: float = float(state.get("heat", 0))
		heat += float(config.get("heat_per_shot", 5))
		state["heat"] = minf(heat, float(config.get("max_heat", 100)))

	# Fuel consumption (per-shot approximation)
	if SimAutoTowerTypes.uses_fuel(tower_type):
		var fuel: float = float(state.get("fuel", 100))
		var tower_data := SimAutoTowerTypes.get_tower(tower_type)
		var special: Dictionary = tower_data.get("special", {})
		var fuel_per_second: float = float(special.get("fuel_per_second", 5))
		var cooldown: float = 1.0 / float(tower_data.get("attack_speed", 1))
		fuel -= fuel_per_second * cooldown
		state["fuel"] = maxf(0, fuel)

	# Damage ramp mechanic (inferno engine)
	var tower_data := SimAutoTowerTypes.get_tower(tower_type)
	var special: Dictionary = tower_data.get("special", {})
	if special.get("ramp_max_multiplier", 0) > 0:
		var ramp_mult: float = float(state.get("ramp_multiplier", 1.0))
		var ramp_time: float = float(special.get("ramp_time", 5.0))
		var attack_speed: float = float(tower_data.get("attack_speed", 1))
		var ramp_per_shot: float = (float(special.get("ramp_max_multiplier", 3.0)) - 1.0) / (ramp_time * attack_speed)
		ramp_mult = minf(ramp_mult + ramp_per_shot, float(special.get("ramp_max_multiplier", 3.0)))
		state["ramp_multiplier"] = ramp_mult

	states[tower_idx] = state


static func _update_tower_states(states: Dictionary, towers: Array[Dictionary], delta: float) -> void:
	for tower in towers:
		var tower_idx: int = int(tower.get("index", 0))
		var tower_type: String = str(tower.get("type", ""))

		if not states.has(tower_idx):
			states[tower_idx] = _init_tower_state(tower_type)

		var state: Dictionary = states[tower_idx]

		# Cool down heat over time
		if SimAutoTowerTypes.has_overheat(tower_type):
			var config := SimAutoTowerTypes.get_overheat_config(tower_type)
			var heat: float = float(state.get("heat", 0))
			heat = maxf(0, heat - float(config.get("cooldown_rate", 20)) * delta)
			state["heat"] = heat

		# Regenerate fuel over time (when not firing)
		if SimAutoTowerTypes.uses_fuel(tower_type):
			var tower_data := SimAutoTowerTypes.get_tower(tower_type)
			var special: Dictionary = tower_data.get("special", {})
			var fuel: float = float(state.get("fuel", 0))
			var max_fuel: float = float(special.get("max_fuel", 100))
			var refuel_rate: float = float(special.get("refuel_rate", 2))
			fuel = minf(max_fuel, fuel + refuel_rate * delta)
			state["fuel"] = fuel

		# Decay damage ramp when not firing
		var tower_data := SimAutoTowerTypes.get_tower(tower_type)
		var special: Dictionary = tower_data.get("special", {})
		if special.get("ramp_max_multiplier", 0) > 0:
			var ramp_mult: float = float(state.get("ramp_multiplier", 1.0))
			ramp_mult = maxf(1.0, ramp_mult - 0.5 * delta)
			state["ramp_multiplier"] = ramp_mult

		states[tower_idx] = state


static func _init_tower_state(tower_type: String) -> Dictionary:
	var state := {}

	if SimAutoTowerTypes.has_overheat(tower_type):
		state["heat"] = 0.0

	if SimAutoTowerTypes.uses_fuel(tower_type):
		var tower_data := SimAutoTowerTypes.get_tower(tower_type)
		var special: Dictionary = tower_data.get("special", {})
		state["fuel"] = float(special.get("max_fuel", 100))

	var tower_data := SimAutoTowerTypes.get_tower(tower_type)
	var special: Dictionary = tower_data.get("special", {})
	if special.get("ramp_max_multiplier", 0) > 0:
		state["ramp_multiplier"] = 1.0

	return state


# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

static func _targeting_string_to_mode(targeting: String) -> int:
	match targeting:
		"nearest":
			return SimAutoTowerTypes.TargetMode.NEAREST
		"highest_hp":
			return SimAutoTowerTypes.TargetMode.HIGHEST_HP
		"lowest_hp":
			return SimAutoTowerTypes.TargetMode.LOWEST_HP
		"fastest":
			return SimAutoTowerTypes.TargetMode.FASTEST
		"cluster":
			return SimAutoTowerTypes.TargetMode.CLUSTER
		"chain":
			return SimAutoTowerTypes.TargetMode.CHAIN
		"zone", "aoe":
			return SimAutoTowerTypes.TargetMode.ZONE
		"contact":
			return SimAutoTowerTypes.TargetMode.CONTACT
		"smart":
			return SimAutoTowerTypes.TargetMode.SMART
		_:
			return SimAutoTowerTypes.TargetMode.NEAREST


static func _convert_enemies_for_targeting(enemies: Array) -> Array:
	var result: Array = []
	for enemy in enemies:
		var pos: Vector2i = enemy.get("pos", Vector2i.ZERO)
		result.append({
			"x": pos.x,
			"y": pos.y,
			"hp": int(enemy.get("hp", 1)),
			"max_hp": int(enemy.get("max_hp", enemy.get("hp", 1))),
			"speed": float(enemy.get("speed", 50)),
			"damage": int(enemy.get("damage", 1)),
			"is_boss": bool(enemy.get("is_boss", false)),
			"is_elite": bool(enemy.get("is_elite", false))
		})
	return result


# =============================================================================
# APPLY DAMAGE TO ENEMIES
# =============================================================================

static func apply_damage_events(enemies: Array, damage_events: Array) -> Dictionary:
	var result := {
		"kills": [],
		"updated_enemies": enemies.duplicate(true)
	}

	for event in damage_events:
		var idx: int = int(event.get("enemy_index", -1))
		if idx < 0 or idx >= result.updated_enemies.size():
			continue

		var enemy: Dictionary = result.updated_enemies[idx]
		var damage: int = int(event.get("damage", 0))
		var damage_type: int = int(event.get("damage_type", SimAutoTowerTypes.DamageType.PHYSICAL))

		# Apply armor pierce if applicable
		for effect in event.get("effects", []):
			if effect.get("type") == "armor_pierce":
				var armor: int = int(enemy.get("armor", 0))
				var pierce_percent: float = float(effect.get("percent", 0)) / 100.0
				var effective_armor: int = int(float(armor) * (1.0 - pierce_percent))
				damage = maxi(1, damage - effective_armor)

		enemy["hp"] = int(enemy.get("hp", 1)) - damage

		# Apply status effects
		for effect in event.get("effects", []):
			match effect.get("type"):
				"burning":
					enemy["status_burning"] = true
					enemy["burn_damage"] = int(effect.get("damage", 3))
					enemy["burn_duration"] = float(effect.get("duration", 3.0))
				"slow":
					enemy["status_slowed"] = true
					enemy["slow_percent"] = int(effect.get("percent", 15))
				"stun_chance":
					var chance: int = int(effect.get("chance", 20))
					if randi() % 100 < chance:
						enemy["status_stunned"] = true
						enemy["stun_duration"] = float(effect.get("duration", 1.0))
				"root_chance":
					var chance: int = int(effect.get("chance", 10))
					if randi() % 100 < chance:
						enemy["status_rooted"] = true
						enemy["root_duration"] = 2.0

		result.updated_enemies[idx] = enemy

		# Check for kill
		if int(enemy.get("hp", 0)) <= 0:
			result.kills.append({
				"index": idx,
				"tower_type": str(event.get("tower_type", "")),
				"enemy": enemy
			})

	return result
