extends Node

const LESSONS_PATH := "res://data/lessons.json"
const MAP_PATH := "res://data/map.json"
const DRILLS_PATH := "res://data/drills.json"
const KINGDOM_UPGRADES_PATH := "res://data/kingdom_upgrades.json"
const UNIT_UPGRADES_PATH := "res://data/unit_upgrades.json"
const SAVE_PATH := "user://typing_kingdom_save.json"
const DEFAULT_MODIFIERS := {
	"typing_power": 1.0,
	"threat_rate_multiplier": 1.0,
	"mistake_forgiveness": 0.0,
	"castle_health_bonus": 0
}
const DEFAULT_MASTERY := {
	"best_accuracy": 0.0,
	"best_wpm": 0.0,
	"last_accuracy": 0.0,
	"last_wpm": 0.0
}
const PERFORMANCE_TIERS := [
	{
		"id": "S",
		"accuracy": 0.96,
		"wpm": 32.0,
		"bonus_gold": 6
	},
	{
		"id": "A",
		"accuracy": 0.93,
		"wpm": 26.0,
		"bonus_gold": 4
	},
	{
		"id": "B",
		"accuracy": 0.88,
		"wpm": 18.0,
		"bonus_gold": 2
	},
	{
		"id": "C",
		"accuracy": 0.0,
		"wpm": 0.0,
		"bonus_gold": 0
	}
]

var lessons: Dictionary = {}
var map_nodes: Dictionary = {}
var map_order: Array = []
var drill_templates: Dictionary = {}
var kingdom_upgrades: Dictionary = {}
var kingdom_order: Array = []
var unit_upgrades: Dictionary = {}
var unit_order: Array = []

var persistence_enabled: bool = true
var gold: int = 0
var completed_nodes: Dictionary = {}
var purchased_upgrades: Dictionary = {}
var modifiers := DEFAULT_MODIFIERS.duplicate(true)
var mastery := DEFAULT_MASTERY.duplicate(true)
var last_summary: Dictionary = {}
var tutorial_completed: bool = false
var battles_played: int = 0

func _ready() -> void:
	_load_static_data()
	_load_save()

func _load_static_data() -> void:
	lessons.clear()
	map_nodes.clear()
	map_order.clear()
	drill_templates.clear()
	kingdom_upgrades.clear()
	kingdom_order.clear()
	unit_upgrades.clear()
	unit_order.clear()

	var lessons_data = _load_json(LESSONS_PATH)
	for entry in lessons_data.get("lessons", []):
		var lesson_id := str(entry.get("id", ""))
		if lesson_id != "":
			lessons[lesson_id] = entry

	var map_data = _load_json(MAP_PATH)
	for node in map_data.get("nodes", []):
		var node_id := str(node.get("id", ""))
		if node_id != "":
			map_nodes[node_id] = node
			map_order.append(node_id)

	var drills_data = _load_json(DRILLS_PATH)
	for entry in drills_data.get("templates", []):
		var template_id := str(entry.get("id", ""))
		if template_id != "":
			drill_templates[template_id] = entry

	var kingdom_data = _load_json(KINGDOM_UPGRADES_PATH)
	for upgrade in kingdom_data.get("upgrades", []):
		var upgrade_id := str(upgrade.get("id", ""))
		if upgrade_id != "":
			kingdom_upgrades[upgrade_id] = upgrade
			kingdom_order.append(upgrade_id)

	var unit_data = _load_json(UNIT_UPGRADES_PATH)
	for upgrade in unit_data.get("upgrades", []):
		var upgrade_id := str(upgrade.get("id", ""))
		if upgrade_id != "":
			unit_upgrades[upgrade_id] = upgrade
			unit_order.append(upgrade_id)

func _load_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return {}
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var text := file.get_as_text()
	var data = JSON.parse_string(text)
	if data == null:
		return {}
	return data

func get_lesson(lesson_id: String) -> Dictionary:
	return lessons.get(lesson_id, {})

func get_map_nodes() -> Array:
	var result: Array = []
	for node_id in map_order:
		if map_nodes.has(node_id):
			result.append(map_nodes[node_id])
	return result

func get_drill_template(template_id: String) -> Dictionary:
	return drill_templates.get(template_id, {})

func is_node_unlocked(node_id: String) -> bool:
	var node = map_nodes.get(node_id)
	if node == null:
		return false
	var requires: Array = node.get("requires", [])
	for req in requires:
		if not completed_nodes.has(req):
			return false
	return true

func is_node_completed(node_id: String) -> bool:
	return completed_nodes.has(node_id)

func complete_node(node_id: String, summary: Dictionary) -> Dictionary:
	var node = map_nodes.get(node_id)
	if node == null:
		return summary
	var is_first := not completed_nodes.has(node_id)
	completed_nodes[node_id] = true
	var reward_gold := int(node.get("reward_gold", 0))
	var practice_gold := 3
	var performance := _evaluate_performance(summary)
	var performance_bonus := int(performance.get("bonus_gold", 0))
	var gold_awarded := practice_gold + performance_bonus
	if is_first:
		gold_awarded += reward_gold
	gold += gold_awarded
	last_summary = summary.duplicate()
	last_summary["gold_awarded"] = gold_awarded
	last_summary["reward_gold"] = reward_gold
	last_summary["practice_gold"] = practice_gold
	last_summary["performance_tier"] = performance.get("id", "")
	last_summary["performance_bonus"] = performance_bonus
	_update_mastery(summary)
	_save()
	return last_summary

func _update_mastery(summary: Dictionary) -> void:
	var accuracy := float(summary.get("accuracy", 0.0))
	var wpm := float(summary.get("wpm", 0.0))
	mastery["last_accuracy"] = accuracy
	mastery["last_wpm"] = wpm
	mastery["best_accuracy"] = max(mastery.get("best_accuracy", 0.0), accuracy)
	mastery["best_wpm"] = max(mastery.get("best_wpm", 0.0), wpm)

func get_last_summary() -> Dictionary:
	return last_summary

func record_attempt(summary: Dictionary) -> void:
	last_summary = summary.duplicate()
	_update_mastery(summary)
	_save()

func _evaluate_performance(summary: Dictionary) -> Dictionary:
	var accuracy := float(summary.get("accuracy", 0.0))
	var wpm := float(summary.get("wpm", 0.0))
	for tier in PERFORMANCE_TIERS:
		if not tier is Dictionary:
			continue
		if accuracy >= float(tier.get("accuracy", 0.0)) and wpm >= float(tier.get("wpm", 0.0)):
			return tier
	return PERFORMANCE_TIERS[PERFORMANCE_TIERS.size() - 1]

func get_combat_modifiers() -> Dictionary:
	var typing_power: float = clamp(float(modifiers.get("typing_power", 1.0)), 0.6, 2.5)
	var threat_rate_multiplier: float = clamp(float(modifiers.get("threat_rate_multiplier", 1.0)), 0.4, 1.6)
	var mistake_forgiveness: float = clamp(float(modifiers.get("mistake_forgiveness", 0.0)), 0.0, 0.6)
	var castle_health_bonus := int(modifiers.get("castle_health_bonus", 0))
	return {
		"typing_power": typing_power,
		"threat_rate_multiplier": threat_rate_multiplier,
		"mistake_forgiveness": mistake_forgiveness,
		"castle_health_bonus": castle_health_bonus
	}

func get_kingdom_upgrades() -> Array:
	var result: Array = []
	for upgrade_id in kingdom_order:
		if kingdom_upgrades.has(upgrade_id):
			result.append(kingdom_upgrades[upgrade_id])
	return result

func get_unit_upgrades() -> Array:
	var result: Array = []
	for upgrade_id in unit_order:
		if unit_upgrades.has(upgrade_id):
			result.append(unit_upgrades[upgrade_id])
	return result

func is_upgrade_owned(upgrade_id: String) -> bool:
	return purchased_upgrades.has(upgrade_id)

func apply_upgrade(upgrade_id: String) -> bool:
	if purchased_upgrades.has(upgrade_id):
		return false
	var upgrade = kingdom_upgrades.get(upgrade_id, null)
	if upgrade == null:
		upgrade = unit_upgrades.get(upgrade_id, null)
	if upgrade == null:
		return false
	var cost := int(upgrade.get("cost", 0))
	if gold < cost:
		return false
	gold -= cost
	purchased_upgrades[upgrade_id] = true
	var effects: Dictionary = upgrade.get("effects", {})
	for key in effects.keys():
		if key == "castle_health_bonus":
			modifiers["castle_health_bonus"] = int(modifiers.get("castle_health_bonus", 0)) + int(effects[key])
		else:
			modifiers[key] = float(modifiers.get(key, 0.0)) + float(effects[key])
	_save()
	return true

func _load_save() -> void:
	if not persistence_enabled:
		return
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var data = _load_json(SAVE_PATH)
	gold = int(data.get("gold", 0))
	completed_nodes = data.get("completed_nodes", {})
	purchased_upgrades = data.get("purchased_upgrades", {})
	var saved_modifiers: Dictionary = data.get("modifiers", {})
	modifiers = DEFAULT_MODIFIERS.duplicate(true)
	for key in saved_modifiers.keys():
		modifiers[key] = saved_modifiers[key]
	var saved_mastery: Dictionary = data.get("mastery", {})
	mastery = DEFAULT_MASTERY.duplicate(true)
	for key in saved_mastery.keys():
		mastery[key] = saved_mastery[key]
	last_summary = data.get("last_summary", {})
	tutorial_completed = bool(data.get("tutorial_completed", false))
	battles_played = int(data.get("battles_played", 0))

func _save() -> void:
	if not persistence_enabled:
		return
	var data := {
		"gold": gold,
		"completed_nodes": completed_nodes,
		"purchased_upgrades": purchased_upgrades,
		"modifiers": modifiers,
		"mastery": mastery,
		"last_summary": last_summary,
		"tutorial_completed": tutorial_completed,
		"battles_played": battles_played
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(data))

func should_show_battle_tutorial() -> bool:
	return not tutorial_completed and battles_played == 0

func mark_battle_started() -> void:
	battles_played += 1
	_save()

func mark_tutorial_completed() -> void:
	tutorial_completed = true
	_save()

func reset_tutorial() -> void:
	tutorial_completed = false
	_save()

func reset_campaign() -> void:
	gold = 0
	completed_nodes = {}
	purchased_upgrades = {}
	modifiers = DEFAULT_MODIFIERS.duplicate(true)
	mastery = DEFAULT_MASTERY.duplicate(true)
	last_summary = {}
	tutorial_completed = false
	battles_played = 0
	_save()
