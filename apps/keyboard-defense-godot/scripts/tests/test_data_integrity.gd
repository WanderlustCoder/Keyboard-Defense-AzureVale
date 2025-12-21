extends RefCounted

const TestHelper = preload("res://scripts/tests/test_helper.gd")

const LESSONS_PATH := "res://data/lessons.json"
const MAP_PATH := "res://data/map.json"
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
	for node in nodes:
		var lesson_id := str(node.get("lesson_id", ""))
		helper.assert_true(lesson_ids.has(lesson_id), "map node lesson exists")
		var requires: Array = node.get("requires", [])
		for req in requires:
			helper.assert_true(node_ids.has(req), "node requirement exists")

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
