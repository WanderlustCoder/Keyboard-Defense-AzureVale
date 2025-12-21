extends RefCounted

const TestHelper = preload("res://scripts/tests/test_helper.gd")

const LESSONS_PATH := "res://data/lessons.json"
const MAP_PATH := "res://data/map.json"
const DRILLS_PATH := "res://data/drills.json"
const KINGDOM_UPGRADES_PATH := "res://data/kingdom_upgrades.json"
const UNIT_UPGRADES_PATH := "res://data/unit_upgrades.json"

func run() -> Dictionary:
	var helper = TestHelper.new()
	var lessons_data: Dictionary = _load_json(LESSONS_PATH)
	var lessons: Array = lessons_data.get("lessons", [])
	helper.assert_true(lessons.size() > 0, "lessons are present")
	var lesson_ids: Dictionary = {}
	for lesson in lessons:
		var lesson_id := str(lesson.get("id", ""))
		helper.assert_true(lesson_id != "", "lesson id exists")
		lesson_ids[lesson_id] = true
		var words: Array = lesson.get("words", [])
		helper.assert_true(words.size() > 0, "lesson words exist")
		for word in words:
			var text := str(word)
			helper.assert_true(text.length() >= 2, "word has length")

	var map_data: Dictionary = _load_json(MAP_PATH)
	var nodes: Array = map_data.get("nodes", [])
	var node_ids: Dictionary = {}
	for node in nodes:
		var node_id := str(node.get("id", ""))
		helper.assert_true(node_id != "", "map node id exists")
		node_ids[node_id] = true

	var drills_data: Dictionary = _load_json(DRILLS_PATH)
	var templates: Array = drills_data.get("templates", [])
	var template_ids: Dictionary = {}
	for template in templates:
		var template_id := str(template.get("id", ""))
		helper.assert_true(template_id != "", "drill template id exists")
		template_ids[template_id] = true
		var plan: Array = template.get("plan", [])
		helper.assert_true(plan.size() > 0, "drill template plan present")
		for step in plan:
			helper.assert_true(step is Dictionary, "drill template step is dictionary")
			if not step is Dictionary:
				continue
			var mode := str(step.get("mode", ""))
			helper.assert_true(mode != "", "drill template mode exists")
			if mode == "lesson" and step.has("word_count"):
				var count := int(step.get("word_count", 0))
				helper.assert_true(count > 0, "drill template word_count positive")
			if mode == "targets":
				var targets: Array = step.get("targets", [])
				helper.assert_true(targets.size() > 0, "drill template targets present")
			if mode == "intermission":
				var duration := float(step.get("duration", 0.0))
				helper.assert_true(duration > 0.0, "drill template duration positive")
	for node in nodes:
		var lesson_id := str(node.get("lesson_id", ""))
		helper.assert_true(lesson_ids.has(lesson_id), "map node lesson exists")
		var requires: Array = node.get("requires", [])
		for req in requires:
			helper.assert_true(node_ids.has(req), "node requirement exists")
		var template_id := str(node.get("drill_template", ""))
		if template_id != "":
			helper.assert_true(template_ids.has(template_id), "map node drill template exists")
		if node.has("drill_plan"):
			var drill_plan = node.get("drill_plan", [])
			helper.assert_true(drill_plan is Array, "drill plan is array")
			if drill_plan is Array:
				for step in drill_plan:
					helper.assert_true(step is Dictionary, "drill step is dictionary")
					if not step is Dictionary:
						continue
					var mode := str(step.get("mode", ""))
					helper.assert_true(mode != "", "drill step mode exists")
					if mode == "lesson" and step.has("word_count"):
						var count := int(step.get("word_count", 0))
						helper.assert_true(count > 0, "drill lesson word_count positive")
					if mode == "targets":
						var targets: Array = step.get("targets", [])
						helper.assert_true(targets.size() > 0, "drill targets present")
						for target in targets:
							var target_text := str(target)
							helper.assert_true(target_text.length() > 0, "drill target text")
					if mode == "intermission":
						var duration := float(step.get("duration", 0.0))
						helper.assert_true(duration > 0.0, "drill intermission duration positive")

	var kingdom_data: Dictionary = _load_json(KINGDOM_UPGRADES_PATH)
	var kingdom_upgrades: Array = kingdom_data.get("upgrades", [])
	for upgrade in kingdom_upgrades:
		var cost := int(upgrade.get("cost", 0))
		helper.assert_true(cost > 0, "kingdom upgrade cost positive")

	var unit_data: Dictionary = _load_json(UNIT_UPGRADES_PATH)
	var unit_upgrades: Array = unit_data.get("upgrades", [])
	for upgrade in unit_upgrades:
		var cost := int(upgrade.get("cost", 0))
		helper.assert_true(cost > 0, "unit upgrade cost positive")

	return helper.summary()

func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var text := file.get_as_text()
	var parsed = JSON.parse_string(text)
	if parsed == null or typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed
