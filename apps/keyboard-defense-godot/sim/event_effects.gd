class_name SimEventEffects
extends RefCounted

const GameState = preload("res://sim/types.gd")
const SimEnemies = preload("res://sim/enemies.gd")
const SimMap = preload("res://sim/map.gd")

static func apply_effects(state: GameState, effects: Array) -> Array:
	var results: Array = []
	for effect in effects:
		if typeof(effect) != TYPE_DICTIONARY:
			continue
		var result: Dictionary = apply_effect(state, effect)
		results.append(result)
	return results

static func apply_effect(state: GameState, effect: Dictionary) -> Dictionary:
	var effect_type: String = str(effect.get("type", ""))
	match effect_type:
		"resource_add":
			return apply_resource_add(state, effect)
		"buff_apply":
			return apply_buff(state, effect)
		"damage_castle":
			return apply_damage_castle(state, effect)
		"set_flag":
			return apply_set_flag(state, effect)
		"clear_flag":
			return apply_clear_flag(state, effect)
		"heal_castle":
			return apply_heal_castle(state, effect)
		"threat_add":
			return apply_threat_add(state, effect)
		"ap_add":
			return apply_ap_add(state, effect)
		"gold_add":
			return apply_gold_add(state, effect)
		"spawn_enemies":
			return apply_spawn_enemies(state, effect)
		"modify_terrain":
			return apply_modify_terrain(state, effect)
		"unlock_lesson":
			return apply_unlock_lesson(state, effect)
		"unlock_achievement":
			return apply_unlock_achievement(state, effect)
		_:
			return {"type": effect_type, "error": "unknown_effect_type"}

static func apply_resource_add(state: GameState, effect: Dictionary) -> Dictionary:
	var resource: String = str(effect.get("resource", ""))
	var amount: int = int(effect.get("amount", 0))
	if resource == "" or not resource in GameState.RESOURCE_KEYS:
		return {"type": "resource_add", "error": "invalid_resource", "resource": resource}
	var old_value: int = int(state.resources.get(resource, 0))
	var new_value: int = max(0, old_value + amount)
	state.resources[resource] = new_value
	var sign_str: String = "+" if amount >= 0 else ""
	return {
		"type": "resource_add",
		"resource": resource,
		"amount": amount,
		"old_value": old_value,
		"new_value": new_value,
		"message": "%s%d %s" % [sign_str, amount, resource]
	}

static func apply_buff(state: GameState, effect: Dictionary) -> Dictionary:
	var buff_id: String = str(effect.get("buff", ""))
	var duration: int = int(effect.get("duration", 1))
	if buff_id == "":
		return {"type": "buff_apply", "error": "no_buff_id"}
	# Check if buff already exists
	var found_index: int = -1
	for i in range(state.active_buffs.size()):
		var existing: Dictionary = state.active_buffs[i]
		if str(existing.get("buff_id", "")) == buff_id:
			found_index = i
			break
	var buff_data: Dictionary = {
		"buff_id": buff_id,
		"expires_day": state.day + duration,
		"applied_day": state.day
	}
	var buff_name: String = buff_id.replace("_", " ").capitalize()
	if found_index >= 0:
		# Refresh duration
		state.active_buffs[found_index] = buff_data
		return {
			"type": "buff_apply",
			"buff_id": buff_id,
			"duration": duration,
			"refreshed": true,
			"message": "Buff refreshed: %s (%d days)" % [buff_name, duration]
		}
	else:
		state.active_buffs.append(buff_data)
		return {
			"type": "buff_apply",
			"buff_id": buff_id,
			"duration": duration,
			"refreshed": false,
			"message": "Buff gained: %s (%d days)" % [buff_name, duration]
		}

static func apply_damage_castle(state: GameState, effect: Dictionary) -> Dictionary:
	var amount: int = int(effect.get("amount", 1))
	var old_hp: int = state.hp
	state.hp = max(0, state.hp - amount)
	return {
		"type": "damage_castle",
		"amount": amount,
		"old_hp": old_hp,
		"new_hp": state.hp,
		"message": "Castle damaged: -%d HP" % amount
	}

static func apply_heal_castle(state: GameState, effect: Dictionary) -> Dictionary:
	var amount: int = int(effect.get("amount", 1))
	var max_hp: int = int(effect.get("max_hp", 10))
	var old_hp: int = state.hp
	state.hp = min(max_hp, state.hp + amount)
	var healed: int = state.hp - old_hp
	return {
		"type": "heal_castle",
		"amount": amount,
		"old_hp": old_hp,
		"new_hp": state.hp,
		"message": "Castle healed: +%d HP" % healed if healed > 0 else "Castle already at full health"
	}

static func apply_set_flag(state: GameState, effect: Dictionary) -> Dictionary:
	var flag: String = str(effect.get("flag", ""))
	var value: Variant = effect.get("value", true)
	if flag == "":
		return {"type": "set_flag", "error": "no_flag_name"}
	var old_value: Variant = state.event_flags.get(flag, null)
	state.event_flags[flag] = value
	return {
		"type": "set_flag",
		"flag": flag,
		"value": value,
		"old_value": old_value
	}

static func apply_clear_flag(state: GameState, effect: Dictionary) -> Dictionary:
	var flag: String = str(effect.get("flag", ""))
	if flag == "":
		return {"type": "clear_flag", "error": "no_flag_name"}
	var had_flag: bool = state.event_flags.has(flag)
	if had_flag:
		state.event_flags.erase(flag)
	return {
		"type": "clear_flag",
		"flag": flag,
		"removed": had_flag
	}

static func apply_threat_add(state: GameState, effect: Dictionary) -> Dictionary:
	var amount: int = int(effect.get("amount", 1))
	var old_threat: int = state.threat
	state.threat = max(0, state.threat + amount)
	var sign_str: String = "+" if amount >= 0 else ""
	return {
		"type": "threat_add",
		"amount": amount,
		"old_threat": old_threat,
		"new_threat": state.threat,
		"message": "Threat %s%d" % [sign_str, amount]
	}

static func apply_ap_add(state: GameState, effect: Dictionary) -> Dictionary:
	var amount: int = int(effect.get("amount", 1))
	var old_ap: int = state.ap
	state.ap = clamp(state.ap + amount, 0, state.ap_max)
	var actual: int = state.ap - old_ap
	var sign_str: String = "+" if actual >= 0 else ""
	return {
		"type": "ap_add",
		"amount": amount,
		"old_ap": old_ap,
		"new_ap": state.ap,
		"message": "%s%d AP" % [sign_str, actual] if actual != 0 else "AP unchanged"
	}

static func has_buff(state: GameState, buff_id: String) -> bool:
	for buff in state.active_buffs:
		if typeof(buff) != TYPE_DICTIONARY:
			continue
		if str(buff.get("buff_id", "")) == buff_id:
			if int(buff.get("expires_day", 0)) > state.day:
				return true
	return false

static func get_buff_remaining_days(state: GameState, buff_id: String) -> int:
	for buff in state.active_buffs:
		if typeof(buff) != TYPE_DICTIONARY:
			continue
		if str(buff.get("buff_id", "")) == buff_id:
			var expires: int = int(buff.get("expires_day", 0))
			if expires > state.day:
				return expires - state.day
	return 0

static func expire_buffs(state: GameState) -> Array:
	var expired: Array = []
	var remaining: Array = []
	for buff in state.active_buffs:
		if typeof(buff) != TYPE_DICTIONARY:
			continue
		var expires: int = int(buff.get("expires_day", 0))
		if state.day >= expires:
			expired.append(str(buff.get("buff_id", "")))
		else:
			remaining.append(buff)
	state.active_buffs = remaining
	return expired

static func get_active_buffs(state: GameState) -> Array:
	var result: Array = []
	for buff in state.active_buffs:
		if typeof(buff) != TYPE_DICTIONARY:
			continue
		if int(buff.get("expires_day", 0)) > state.day:
			result.append(buff)
	return result

static func serialize_buffs(buffs: Array) -> Array:
	var result: Array = []
	for buff in buffs:
		if typeof(buff) != TYPE_DICTIONARY:
			continue
		result.append({
			"buff_id": str(buff.get("buff_id", "")),
			"expires_day": int(buff.get("expires_day", 0)),
			"applied_day": int(buff.get("applied_day", 0))
		})
	return result

static func deserialize_buffs(raw: Array) -> Array:
	var result: Array = []
	for item in raw:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		result.append({
			"buff_id": str(item.get("buff_id", "")),
			"expires_day": int(item.get("expires_day", 0)),
			"applied_day": int(item.get("applied_day", 0))
		})
	return result

# New effect types for deeper exploration outcomes

static func apply_gold_add(state: GameState, effect: Dictionary) -> Dictionary:
	var amount: int = int(effect.get("amount", 0))
	var old_value: int = state.gold
	state.gold = max(0, state.gold + amount)
	var sign_str: String = "+" if amount >= 0 else ""
	return {
		"type": "gold_add",
		"amount": amount,
		"old_value": old_value,
		"new_value": state.gold,
		"message": "%s%d gold" % [sign_str, amount]
	}

static func apply_spawn_enemies(state: GameState, effect: Dictionary) -> Dictionary:
	var kind: String = str(effect.get("kind", "raider"))
	var count: int = int(effect.get("count", 1))
	var at_cursor: bool = bool(effect.get("at_cursor", true))

	# Validate enemy kind
	if not SimEnemies.ENEMY_KINDS.has(kind):
		return {"type": "spawn_enemies", "error": "invalid_enemy_kind", "kind": kind}

	var spawn_pos: Vector2i = state.cursor_pos if at_cursor else state.base_pos
	var spawned: int = 0
	var spawned_ids: Array = []

	for i in range(count):
		# Find valid spawn position (offset from base for multiple enemies)
		var offset := Vector2i(i % 3, i / 3)
		var pos := spawn_pos + offset

		# Clamp to map bounds
		pos.x = clamp(pos.x, 0, state.map_w - 1)
		pos.y = clamp(pos.y, 0, state.map_h - 1)

		# Check if passable
		if not SimMap.is_passable(state, pos):
			continue

		var enemy: Dictionary = SimEnemies.make_enemy(state, kind, pos)
		state.enemy_next_id += 1
		state.enemies.append(enemy)
		spawned_ids.append(int(enemy.get("id", 0)))
		spawned += 1

	if spawned == 0:
		return {
			"type": "spawn_enemies",
			"kind": kind,
			"count": count,
			"spawned": 0,
			"message": "No enemies could spawn - blocked terrain"
		}

	var kind_name: String = kind.replace("_", " ").capitalize()
	var plural: String = "s" if spawned > 1 else ""
	return {
		"type": "spawn_enemies",
		"kind": kind,
		"count": count,
		"spawned": spawned,
		"enemy_ids": spawned_ids,
		"message": "%d %s%s appeared!" % [spawned, kind_name, plural]
	}

static func apply_modify_terrain(state: GameState, effect: Dictionary) -> Dictionary:
	var terrain: String = str(effect.get("terrain", ""))
	var at_cursor: bool = bool(effect.get("at_cursor", true))
	var x: int = int(effect.get("x", state.cursor_pos.x))
	var y: int = int(effect.get("y", state.cursor_pos.y))

	if at_cursor:
		x = state.cursor_pos.x
		y = state.cursor_pos.y

	# Validate position
	if x < 0 or x >= state.map_w or y < 0 or y >= state.map_h:
		return {"type": "modify_terrain", "error": "position_out_of_bounds", "x": x, "y": y}

	# Validate terrain type
	var valid_terrains := [SimMap.TERRAIN_PLAINS, SimMap.TERRAIN_FOREST, SimMap.TERRAIN_MOUNTAIN, SimMap.TERRAIN_WATER, ""]
	if not terrain in valid_terrains:
		return {"type": "modify_terrain", "error": "invalid_terrain", "terrain": terrain}

	var index: int = y * state.map_w + x
	var old_terrain: String = str(state.terrain[index]) if index < state.terrain.size() else ""

	if index < state.terrain.size():
		state.terrain[index] = terrain

	var terrain_name: String = terrain.capitalize() if terrain != "" else "Clear"
	return {
		"type": "modify_terrain",
		"terrain": terrain,
		"x": x,
		"y": y,
		"old_terrain": old_terrain,
		"message": "Terrain changed to %s at (%d, %d)" % [terrain_name, x, y]
	}

static func apply_unlock_lesson(state: GameState, effect: Dictionary) -> Dictionary:
	var lesson_id: String = str(effect.get("lesson", ""))
	if lesson_id == "":
		return {"type": "unlock_lesson", "error": "no_lesson_id"}

	# Set flag to indicate lesson unlocked (profile handles actual unlock)
	var flag_name: String = "lesson_unlocked_%s" % lesson_id
	var already_unlocked: bool = state.event_flags.has(flag_name)
	state.event_flags[flag_name] = true

	var lesson_name: String = lesson_id.replace("_", " ").capitalize()
	return {
		"type": "unlock_lesson",
		"lesson": lesson_id,
		"already_unlocked": already_unlocked,
		"message": "Lesson unlocked: %s!" % lesson_name if not already_unlocked else "Already unlocked: %s" % lesson_name
	}

static func apply_unlock_achievement(state: GameState, effect: Dictionary) -> Dictionary:
	var achievement_id: String = str(effect.get("achievement", ""))
	if achievement_id == "":
		return {"type": "unlock_achievement", "error": "no_achievement_id"}

	# Set flag to indicate achievement earned (profile handles persistence)
	var flag_name: String = "achievement_%s" % achievement_id
	var already_earned: bool = state.event_flags.has(flag_name)
	state.event_flags[flag_name] = true

	var achievement_name: String = achievement_id.replace("_", " ").capitalize()
	return {
		"type": "unlock_achievement",
		"achievement": achievement_id,
		"already_earned": already_earned,
		"message": "Achievement earned: %s!" % achievement_name if not already_earned else "Already earned: %s" % achievement_name
	}
