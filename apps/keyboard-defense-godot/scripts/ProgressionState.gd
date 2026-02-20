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
const DEFAULT_LESSON_MASTERY := {
	"best_accuracy": 0.0,
	"best_wpm": 0.0,
	"attempt_count": 0,
	"completion_count": 0
}
const DEFAULT_PATH_PROGRESS := {
	"current_stage": 0,
	"completed_stages": [],
	"lessons_completed": []
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
var lesson_mastery: Dictionary = {}  # {lesson_id: mastery_dict}
var graduation_progress: Dictionary = {}  # {path_id: progress_dict}
var graduation_paths: Dictionary = {}  # Cached from lessons.json
var last_summary: Dictionary = {}
var tutorial_completed: bool = false
var battles_played: int = 0
var active_battle: Dictionary = {}  # Stores battle state for resume

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

	# Load graduation paths
	graduation_paths = lessons_data.get("graduation_paths", {})

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

	# Load per-lesson mastery
	var saved_lesson_mastery: Dictionary = data.get("lesson_mastery", {})
	lesson_mastery = {}
	for lesson_id in saved_lesson_mastery.keys():
		lesson_mastery[lesson_id] = saved_lesson_mastery[lesson_id]

	# Load graduation progress
	var saved_graduation: Dictionary = data.get("graduation_progress", {})
	graduation_progress = {}
	for path_id in saved_graduation.keys():
		graduation_progress[path_id] = saved_graduation[path_id]

	last_summary = data.get("last_summary", {})
	tutorial_completed = bool(data.get("tutorial_completed", false))
	battles_played = int(data.get("battles_played", 0))
	active_battle = data.get("active_battle", {})

func _save() -> void:
	if not persistence_enabled:
		return
	var data := {
		"gold": gold,
		"completed_nodes": completed_nodes,
		"purchased_upgrades": purchased_upgrades,
		"modifiers": modifiers,
		"mastery": mastery,
		"lesson_mastery": lesson_mastery,
		"graduation_progress": graduation_progress,
		"last_summary": last_summary,
		"tutorial_completed": tutorial_completed,
		"battles_played": battles_played,
		"active_battle": active_battle
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
	lesson_mastery = {}
	graduation_progress = {}
	last_summary = {}
	tutorial_completed = false
	battles_played = 0
	active_battle = {}
	_save()

func add_gold(amount: int) -> void:
	gold += amount
	_save()

func get_gold() -> int:
	return gold

func save_active_battle(battle_state: Dictionary) -> void:
	active_battle = battle_state
	_save()

func clear_active_battle() -> void:
	active_battle = {}
	_save()

func has_active_battle() -> bool:
	return not active_battle.is_empty()

# --- Per-Lesson Mastery ---

func get_lesson_mastery(lesson_id: String) -> Dictionary:
	if lesson_mastery.has(lesson_id):
		return lesson_mastery[lesson_id]
	return DEFAULT_LESSON_MASTERY.duplicate(true)

func _update_lesson_mastery(lesson_id: String, summary: Dictionary, completed: bool) -> void:
	if not lesson_mastery.has(lesson_id):
		lesson_mastery[lesson_id] = DEFAULT_LESSON_MASTERY.duplicate(true)

	var entry: Dictionary = lesson_mastery[lesson_id]
	var accuracy := float(summary.get("accuracy", 0.0))
	var wpm := float(summary.get("wpm", 0.0))

	entry["best_accuracy"] = max(float(entry.get("best_accuracy", 0.0)), accuracy)
	entry["best_wpm"] = max(float(entry.get("best_wpm", 0.0)), wpm)
	entry["attempt_count"] = int(entry.get("attempt_count", 0)) + 1
	if completed:
		entry["completion_count"] = int(entry.get("completion_count", 0)) + 1

func record_practice_attempt(lesson_id: String, summary: Dictionary) -> Dictionary:
	var completed := bool(summary.get("completed", false))
	_update_lesson_mastery(lesson_id, summary, completed)
	_update_mastery(summary)

	# Update graduation progress if lesson is part of a path
	if completed:
		update_graduation_progress(lesson_id)

	# Calculate gold reward (practice only, no first-clear bonus)
	var practice_gold := 3
	var performance := _evaluate_performance(summary)
	var performance_bonus := int(performance.get("bonus_gold", 0))
	var gold_awarded := practice_gold + performance_bonus
	gold += gold_awarded

	last_summary = summary.duplicate()
	last_summary["gold_awarded"] = gold_awarded
	last_summary["practice_gold"] = practice_gold
	last_summary["performance_tier"] = performance.get("id", "")
	last_summary["performance_bonus"] = performance_bonus

	_save()
	return last_summary

# --- Graduation Path Progress ---

func get_path_progress(path_id: String) -> Dictionary:
	if graduation_progress.has(path_id):
		return graduation_progress[path_id]
	return DEFAULT_PATH_PROGRESS.duplicate(true)

func update_graduation_progress(lesson_id: String) -> void:
	# Find which path(s) contain this lesson
	for path_id in graduation_paths.keys():
		var path_data: Dictionary = graduation_paths.get(path_id, {})
		var stages: Array = path_data.get("stages", [])

		for stage_data in stages:
			if not stage_data is Dictionary:
				continue
			var stage_lessons: Array = stage_data.get("lessons", [])
			if lesson_id in stage_lessons:
				_update_path_lesson_completion(path_id, lesson_id, int(stage_data.get("stage", 0)))

func _update_path_lesson_completion(path_id: String, lesson_id: String, stage_num: int) -> void:
	if not graduation_progress.has(path_id):
		graduation_progress[path_id] = DEFAULT_PATH_PROGRESS.duplicate(true)

	var progress: Dictionary = graduation_progress[path_id]
	var completed_lessons: Array = progress.get("lessons_completed", [])
	var completed_stages: Array = progress.get("completed_stages", [])

	# Add lesson to completed list if not already there
	if lesson_id not in completed_lessons:
		completed_lessons.append(lesson_id)
		progress["lessons_completed"] = completed_lessons

	# Check if stage is now complete
	if stage_num > 0 and stage_num not in completed_stages:
		if _is_stage_lessons_complete(path_id, stage_num):
			completed_stages.append(stage_num)
			completed_stages.sort()
			progress["completed_stages"] = completed_stages

			# Update current stage to next incomplete
			var next_stage := stage_num + 1
			if next_stage > int(progress.get("current_stage", 0)):
				progress["current_stage"] = next_stage

func _is_stage_lessons_complete(path_id: String, stage_num: int) -> bool:
	var path_data: Dictionary = graduation_paths.get(path_id, {})
	var stages: Array = path_data.get("stages", [])

	for stage_data in stages:
		if not stage_data is Dictionary:
			continue
		if int(stage_data.get("stage", 0)) == stage_num:
			var stage_lessons: Array = stage_data.get("lessons", [])
			var progress: Dictionary = get_path_progress(path_id)
			var completed_lessons: Array = progress.get("lessons_completed", [])
			for req_lesson in stage_lessons:
				if req_lesson not in completed_lessons:
					return false
			return true
	return false

func is_stage_complete(path_id: String, stage_num: int) -> bool:
	var progress: Dictionary = get_path_progress(path_id)
	var completed_stages: Array = progress.get("completed_stages", [])
	return stage_num in completed_stages

func get_path_completion_percent(path_id: String) -> float:
	var path_data: Dictionary = graduation_paths.get(path_id, {})
	var stages: Array = path_data.get("stages", [])

	var total_lessons := 0
	for stage_data in stages:
		if stage_data is Dictionary:
			var stage_lessons: Array = stage_data.get("lessons", [])
			total_lessons += stage_lessons.size()

	if total_lessons <= 0:
		return 0.0

	var progress: Dictionary = get_path_progress(path_id)
	var completed_lessons: Array = progress.get("lessons_completed", [])
	return float(completed_lessons.size()) / float(total_lessons)
