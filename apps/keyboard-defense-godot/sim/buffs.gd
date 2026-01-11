class_name SimBuffs
extends RefCounted
## Buff definitions and effect calculations

const GameState = preload("res://sim/types.gd")
const SimEventEffects = preload("res://sim/event_effects.gd")

const BUFFS_PATH := "res://data/buffs.json"

static var _buffs_cache: Dictionary = {}
static var _loaded: bool = false


static func load_buffs() -> void:
	if _loaded:
		return
	_buffs_cache = {}
	var file := FileAccess.open(BUFFS_PATH, FileAccess.READ)
	if file == null:
		push_warning("SimBuffs: Could not load buffs from %s" % BUFFS_PATH)
		_loaded = true
		return
	var content: String = file.get_as_text()
	file.close()
	var json := JSON.new()
	var error: int = json.parse(content)
	if error != OK:
		push_warning("SimBuffs: JSON parse error: %s" % json.get_error_message())
		_loaded = true
		return
	var data: Dictionary = json.data
	_buffs_cache = data.get("buffs", {})
	_loaded = true


static func get_buff_data(buff_id: String) -> Dictionary:
	load_buffs()
	return _buffs_cache.get(buff_id, {})


static func get_all_buffs() -> Dictionary:
	load_buffs()
	return _buffs_cache


# =============================================================================
# EFFECT CALCULATIONS
# =============================================================================

## Get total resource multiplier from active buffs
static func get_resource_multiplier(state: GameState) -> float:
	var total: float = 0.0
	for buff in SimEventEffects.get_active_buffs(state):
		var buff_id: String = str(buff.get("buff_id", ""))
		var buff_data: Dictionary = get_buff_data(buff_id)
		var effects: Dictionary = buff_data.get("effects", {})
		total += float(effects.get("resource_multiplier", 0.0))
	return total


## Get total threat multiplier from active buffs
static func get_threat_multiplier(state: GameState) -> float:
	var total: float = 0.0
	for buff in SimEventEffects.get_active_buffs(state):
		var buff_id: String = str(buff.get("buff_id", ""))
		var buff_data: Dictionary = get_buff_data(buff_id)
		var effects: Dictionary = buff_data.get("effects", {})
		total += float(effects.get("threat_multiplier", 0.0))
	return total


## Get total damage multiplier from active buffs
static func get_damage_multiplier(state: GameState) -> float:
	var total: float = 0.0
	for buff in SimEventEffects.get_active_buffs(state):
		var buff_id: String = str(buff.get("buff_id", ""))
		var buff_data: Dictionary = get_buff_data(buff_id)
		var effects: Dictionary = buff_data.get("effects", {})
		total += float(effects.get("damage_multiplier", 0.0))
	return total


## Get total damage reduction from active buffs
static func get_damage_reduction(state: GameState) -> int:
	var total: int = 0
	for buff in SimEventEffects.get_active_buffs(state):
		var buff_id: String = str(buff.get("buff_id", ""))
		var buff_data: Dictionary = get_buff_data(buff_id)
		var effects: Dictionary = buff_data.get("effects", {})
		total += int(effects.get("damage_reduction", 0))
	return total


## Get total gold multiplier from active buffs
static func get_gold_multiplier(state: GameState) -> float:
	var total: float = 0.0
	for buff in SimEventEffects.get_active_buffs(state):
		var buff_id: String = str(buff.get("buff_id", ""))
		var buff_data: Dictionary = get_buff_data(buff_id)
		var effects: Dictionary = buff_data.get("effects", {})
		total += float(effects.get("gold_multiplier", 0.0))
	return total


## Get total exploration reward multiplier from active buffs
static func get_explore_reward_multiplier(state: GameState) -> float:
	var total: float = 0.0
	for buff in SimEventEffects.get_active_buffs(state):
		var buff_id: String = str(buff.get("buff_id", ""))
		var buff_data: Dictionary = get_buff_data(buff_id)
		var effects: Dictionary = buff_data.get("effects", {})
		total += float(effects.get("explore_reward_multiplier", 0.0))
	return total


## Get total AP bonus from active buffs (applied at dawn)
static func get_ap_bonus(state: GameState) -> int:
	var total: int = 0
	for buff in SimEventEffects.get_active_buffs(state):
		var buff_id: String = str(buff.get("buff_id", ""))
		var buff_data: Dictionary = get_buff_data(buff_id)
		var effects: Dictionary = buff_data.get("effects", {})
		total += int(effects.get("ap_bonus", 0))
	return total


## Get total HP regen from active buffs (applied at dawn)
static func get_hp_regen(state: GameState) -> int:
	var total: int = 0
	for buff in SimEventEffects.get_active_buffs(state):
		var buff_id: String = str(buff.get("buff_id", ""))
		var buff_data: Dictionary = get_buff_data(buff_id)
		var effects: Dictionary = buff_data.get("effects", {})
		total += int(effects.get("hp_regen", 0))
	return total


## Get accuracy bonus from active buffs
static func get_accuracy_bonus(state: GameState) -> float:
	var total: float = 0.0
	for buff in SimEventEffects.get_active_buffs(state):
		var buff_id: String = str(buff.get("buff_id", ""))
		var buff_data: Dictionary = get_buff_data(buff_id)
		var effects: Dictionary = buff_data.get("effects", {})
		total += float(effects.get("accuracy_bonus", 0.0))
	return total


## Get enemy speed multiplier from active buffs
static func get_enemy_speed_multiplier(state: GameState) -> float:
	var total: float = 0.0
	for buff in SimEventEffects.get_active_buffs(state):
		var buff_id: String = str(buff.get("buff_id", ""))
		var buff_data: Dictionary = get_buff_data(buff_id)
		var effects: Dictionary = buff_data.get("effects", {})
		total += float(effects.get("enemy_speed_multiplier", 0.0))
	return total


# =============================================================================
# DAWN EFFECTS
# =============================================================================

## Apply dawn effects from active buffs (AP bonus, HP regen, etc.)
static func apply_dawn_effects(state: GameState) -> Array[String]:
	var messages: Array[String] = []

	# Apply AP bonus
	var ap_bonus: int = get_ap_bonus(state)
	if ap_bonus > 0:
		state.ap = min(state.ap + ap_bonus, state.ap_max)
		messages.append("Buff: +%d AP from Energized" % ap_bonus)

	# Apply HP regen
	var hp_regen: int = get_hp_regen(state)
	if hp_regen > 0 and state.hp < 10:  # Assume max HP is 10
		var old_hp: int = state.hp
		state.hp = min(state.hp + hp_regen, 10)
		var healed: int = state.hp - old_hp
		if healed > 0:
			messages.append("Buff: +%d HP from Regeneration" % healed)

	# Expire buffs
	var expired: Array = SimEventEffects.expire_buffs(state)
	for buff_id in expired:
		var buff_data: Dictionary = get_buff_data(buff_id)
		var buff_name: String = str(buff_data.get("name", buff_id))
		messages.append("Buff expired: %s" % buff_name)

	return messages


# =============================================================================
# BUFF INFO
# =============================================================================

## Get display info for active buffs
static func get_active_buff_display(state: GameState) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for buff in SimEventEffects.get_active_buffs(state):
		var buff_id: String = str(buff.get("buff_id", ""))
		var buff_data: Dictionary = get_buff_data(buff_id)
		var remaining: int = SimEventEffects.get_buff_remaining_days(state, buff_id)
		result.append({
			"buff_id": buff_id,
			"name": str(buff_data.get("name", buff_id)),
			"description": str(buff_data.get("description", "")),
			"icon": str(buff_data.get("icon", "")),
			"remaining_days": remaining
		})
	return result


## Check if a specific buff is active
static func is_buff_active(state: GameState, buff_id: String) -> bool:
	return SimEventEffects.has_buff(state, buff_id)
