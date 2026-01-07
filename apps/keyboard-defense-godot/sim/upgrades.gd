class_name SimUpgrades
extends RefCounted

const GameState = preload("res://sim/types.gd")

static var _kingdom_upgrades: Array = []
static var _unit_upgrades: Array = []
static var _loaded: bool = false

static func _ensure_loaded() -> void:
	if _loaded:
		return
	_kingdom_upgrades = _load_upgrades("res://data/kingdom_upgrades.json")
	_unit_upgrades = _load_upgrades("res://data/unit_upgrades.json")
	_loaded = true

static func _load_upgrades(path: String) -> Array:
	if not FileAccess.file_exists(path):
		push_warning("Upgrades file not found: %s" % path)
		return []
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("Failed to open upgrades file: %s" % path)
		return []
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err != OK:
		push_warning("Failed to parse upgrades JSON: %s" % path)
		return []
	var data: Dictionary = json.get_data()
	return data.get("upgrades", [])

static func get_kingdom_upgrade(id: String) -> Dictionary:
	_ensure_loaded()
	for upgrade in _kingdom_upgrades:
		if str(upgrade.get("id", "")) == id:
			return upgrade
	return {}

static func get_unit_upgrade(id: String) -> Dictionary:
	_ensure_loaded()
	for upgrade in _unit_upgrades:
		if str(upgrade.get("id", "")) == id:
			return upgrade
	return {}

static func get_all_kingdom_upgrades() -> Array:
	_ensure_loaded()
	return _kingdom_upgrades.duplicate()

static func get_all_unit_upgrades() -> Array:
	_ensure_loaded()
	return _unit_upgrades.duplicate()

static func can_purchase_kingdom_upgrade(state: GameState, upgrade_id: String) -> Dictionary:
	var upgrade: Dictionary = get_kingdom_upgrade(upgrade_id)
	if upgrade.is_empty():
		return {"ok": false, "error": "Upgrade not found: %s" % upgrade_id}

	# Check if already purchased
	if upgrade_id in state.purchased_kingdom_upgrades:
		return {"ok": false, "error": "Already purchased: %s" % upgrade_id}

	# Check requirements
	var requires: Array = upgrade.get("requires", [])
	for req_id in requires:
		if str(req_id) not in state.purchased_kingdom_upgrades:
			return {"ok": false, "error": "Requires: %s" % str(req_id)}

	# Check cost
	var cost: int = int(upgrade.get("cost", 0))
	if state.gold < cost:
		return {"ok": false, "error": "Not enough gold (need %d, have %d)" % [cost, state.gold]}

	return {"ok": true, "cost": cost, "upgrade": upgrade}

static func can_purchase_unit_upgrade(state: GameState, upgrade_id: String) -> Dictionary:
	var upgrade: Dictionary = get_unit_upgrade(upgrade_id)
	if upgrade.is_empty():
		return {"ok": false, "error": "Upgrade not found: %s" % upgrade_id}

	# Check if already purchased
	if upgrade_id in state.purchased_unit_upgrades:
		return {"ok": false, "error": "Already purchased: %s" % upgrade_id}

	# Check requirements
	var requires: Array = upgrade.get("requires", [])
	for req_id in requires:
		if str(req_id) not in state.purchased_unit_upgrades:
			return {"ok": false, "error": "Requires: %s" % str(req_id)}

	# Check cost
	var cost: int = int(upgrade.get("cost", 0))
	if state.gold < cost:
		return {"ok": false, "error": "Not enough gold (need %d, have %d)" % [cost, state.gold]}

	return {"ok": true, "cost": cost, "upgrade": upgrade}

static func purchase_kingdom_upgrade(state: GameState, upgrade_id: String) -> Dictionary:
	var check: Dictionary = can_purchase_kingdom_upgrade(state, upgrade_id)
	if not check.get("ok", false):
		return check

	var cost: int = int(check.get("cost", 0))
	state.gold -= cost
	state.purchased_kingdom_upgrades.append(upgrade_id)

	var upgrade: Dictionary = check.get("upgrade", {})
	var label: String = str(upgrade.get("label", upgrade_id))

	return {"ok": true, "message": "Purchased %s for %d gold" % [label, cost]}

static func purchase_unit_upgrade(state: GameState, upgrade_id: String) -> Dictionary:
	var check: Dictionary = can_purchase_unit_upgrade(state, upgrade_id)
	if not check.get("ok", false):
		return check

	var cost: int = int(check.get("cost", 0))
	state.gold -= cost
	state.purchased_unit_upgrades.append(upgrade_id)

	var upgrade: Dictionary = check.get("upgrade", {})
	var label: String = str(upgrade.get("label", upgrade_id))

	return {"ok": true, "message": "Purchased %s for %d gold" % [label, cost]}

## Calculate total effect value from all purchased upgrades
static func get_total_effect(state: GameState, effect_key: String) -> float:
	var total: float = 0.0

	# Sum kingdom upgrade effects
	for upgrade_id in state.purchased_kingdom_upgrades:
		var upgrade: Dictionary = get_kingdom_upgrade(str(upgrade_id))
		var effects: Dictionary = upgrade.get("effects", {})
		if effects.has(effect_key):
			total += float(effects.get(effect_key, 0))

	# Sum unit upgrade effects
	for upgrade_id in state.purchased_unit_upgrades:
		var upgrade: Dictionary = get_unit_upgrade(str(upgrade_id))
		var effects: Dictionary = upgrade.get("effects", {})
		if effects.has(effect_key):
			total += float(effects.get(effect_key, 0))

	return total

## Get typing power multiplier (base 1.0 + upgrades)
static func get_typing_power(state: GameState) -> float:
	return 1.0 + get_total_effect(state, "typing_power")

## Get threat rate multiplier (base 1.0 + upgrades, negative means slower)
static func get_threat_rate_multiplier(state: GameState) -> float:
	return 1.0 + get_total_effect(state, "threat_rate_multiplier")

## Get gold multiplier (base 1.0 + upgrades)
static func get_gold_multiplier(state: GameState) -> float:
	return 1.0 + get_total_effect(state, "gold_multiplier")

## Get resource multiplier (base 1.0 + upgrades)
static func get_resource_multiplier(state: GameState) -> float:
	return 1.0 + get_total_effect(state, "resource_multiplier")

## Get damage reduction (0.0 to 1.0)
static func get_damage_reduction(state: GameState) -> float:
	var reduction: float = get_total_effect(state, "damage_reduction")
	return clampf(reduction, 0.0, 0.75)  # Cap at 75% reduction

## Get castle health bonus
static func get_castle_health_bonus(state: GameState) -> int:
	return int(get_total_effect(state, "castle_health_bonus"))

## Get wave heal amount
static func get_wave_heal(state: GameState) -> int:
	return int(get_total_effect(state, "wave_heal"))

## Get critical hit chance (0.0 to 1.0)
static func get_critical_chance(state: GameState) -> float:
	var chance: float = get_total_effect(state, "critical_chance")
	return clampf(chance, 0.0, 0.5)  # Cap at 50% crit chance

## Get mistake forgiveness (reduces penalty)
static func get_mistake_forgiveness(state: GameState) -> float:
	return get_total_effect(state, "mistake_forgiveness")

## Get enemy armor reduction
static func get_enemy_armor_reduction(state: GameState) -> int:
	return int(get_total_effect(state, "enemy_armor_reduction"))

## Get armor pierce
static func get_armor_pierce(state: GameState) -> int:
	return int(get_total_effect(state, "armor_pierce"))

## Get enemy speed reduction (0.0 to 1.0)
static func get_enemy_speed_reduction(state: GameState) -> float:
	var reduction: float = get_total_effect(state, "enemy_speed_reduction")
	return clampf(reduction, 0.0, 0.5)  # Cap at 50% speed reduction

## List available upgrades for purchase
static func list_available_kingdom_upgrades(state: GameState) -> Array:
	_ensure_loaded()
	var available: Array = []
	for upgrade in _kingdom_upgrades:
		var id: String = str(upgrade.get("id", ""))
		var check: Dictionary = can_purchase_kingdom_upgrade(state, id)
		if check.get("ok", false):
			available.append(upgrade)
	return available

static func list_available_unit_upgrades(state: GameState) -> Array:
	_ensure_loaded()
	var available: Array = []
	for upgrade in _unit_upgrades:
		var id: String = str(upgrade.get("id", ""))
		var check: Dictionary = can_purchase_unit_upgrade(state, id)
		if check.get("ok", false):
			available.append(upgrade)
	return available

## Format upgrade tree for display
static func format_upgrade_tree(state: GameState, category: String) -> Array[String]:
	_ensure_loaded()
	var lines: Array[String] = []
	var upgrades: Array = _kingdom_upgrades if category == "kingdom" else _unit_upgrades
	var purchased: Array = state.purchased_kingdom_upgrades if category == "kingdom" else state.purchased_unit_upgrades

	lines.append("[b]%s Upgrades[/b] (Gold: %d)" % [category.capitalize(), state.gold])

	for tier in [1, 2, 3]:
		var tier_upgrades: Array = []
		for upgrade in upgrades:
			if int(upgrade.get("tier", 1)) == tier:
				tier_upgrades.append(upgrade)

		if tier_upgrades.is_empty():
			continue

		lines.append("Tier %d:" % tier)
		for upgrade in tier_upgrades:
			var id: String = str(upgrade.get("id", ""))
			var label: String = str(upgrade.get("label", id))
			var cost: int = int(upgrade.get("cost", 0))
			var status: String = ""

			if id in purchased:
				status = "[color=green]OWNED[/color]"
			else:
				var check: Dictionary
				if category == "kingdom":
					check = can_purchase_kingdom_upgrade(state, id)
				else:
					check = can_purchase_unit_upgrade(state, id)

				if check.get("ok", false):
					status = "[color=yellow]%d gold[/color]" % cost
				else:
					status = "[color=gray]Locked[/color]"

			lines.append("  %s - %s" % [label, status])

	return lines
