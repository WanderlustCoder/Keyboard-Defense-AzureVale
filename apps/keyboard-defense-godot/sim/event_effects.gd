class_name SimEventEffects
extends RefCounted

const GameState = preload("res://sim/types.gd")

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
