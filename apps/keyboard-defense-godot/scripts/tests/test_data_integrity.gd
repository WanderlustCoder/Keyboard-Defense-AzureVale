extends RefCounted

const TestHelper = preload("res://scripts/tests/test_helper.gd")

const LESSONS_PATH := "res://data/lessons.json"
const MAP_PATH := "res://data/map.json"
const DRILLS_PATH := "res://data/drills.json"
const KINGDOM_UPGRADES_PATH := "res://data/kingdom_upgrades.json"
const UNIT_UPGRADES_PATH := "res://data/unit_upgrades.json"
const ASSETS_PATH := "res://data/assets_manifest.json"
const LESSONS_SCHEMA_PATH := "res://data/schemas/lessons.schema.json"
const MAP_SCHEMA_PATH := "res://data/schemas/map.schema.json"
const DRILLS_SCHEMA_PATH := "res://data/schemas/drills.schema.json"
const KINGDOM_UPGRADES_SCHEMA_PATH := "res://data/schemas/kingdom_upgrades.schema.json"
const UNIT_UPGRADES_SCHEMA_PATH := "res://data/schemas/unit_upgrades.schema.json"
const ASSETS_SCHEMA_PATH := "res://data/schemas/assets_manifest.schema.json"
var _pattern_cache: Dictionary = {}

func run() -> Dictionary:
	var helper = TestHelper.new()
	var lessons_schema: Dictionary = _load_schema(helper, LESSONS_SCHEMA_PATH, "lessons")
	var map_schema: Dictionary = _load_schema(helper, MAP_SCHEMA_PATH, "map")
	var drills_schema: Dictionary = _load_schema(helper, DRILLS_SCHEMA_PATH, "drills")
	var kingdom_schema: Dictionary = _load_schema(helper, KINGDOM_UPGRADES_SCHEMA_PATH, "kingdom upgrades")
	var unit_schema: Dictionary = _load_schema(helper, UNIT_UPGRADES_SCHEMA_PATH, "unit upgrades")
	var assets_schema: Dictionary = _load_schema(helper, ASSETS_SCHEMA_PATH, "assets manifest")
	var lessons_data: Dictionary = _load_json(LESSONS_PATH)
	_validate_schema(helper, lessons_data, lessons_schema, "lessons.json")
	var lessons: Array = lessons_data.get("lessons", [])
	helper.assert_true(lessons.size() > 0, "lessons are present")
	var lesson_ids: Dictionary = {}
	for lesson in lessons:
		var lesson_id := str(lesson.get("id", ""))
		helper.assert_true(lesson_id != "", "lesson id exists")
		lesson_ids[lesson_id] = true
		var charset := str(lesson.get("charset", ""))
		helper.assert_true(charset.length() > 0, "lesson charset exists")
		var lengths = lesson.get("lengths", {})
		helper.assert_true(lengths is Dictionary, "lesson lengths is dictionary")
		if lengths is Dictionary:
			helper.assert_true(lengths.has("scout"), "lesson has scout lengths")
			helper.assert_true(lengths.has("raider"), "lesson has raider lengths")
			helper.assert_true(lengths.has("armored"), "lesson has armored lengths")

	var map_data: Dictionary = _load_json(MAP_PATH)
	_validate_schema(helper, map_data, map_schema, "map.json")
	var nodes: Array = map_data.get("nodes", [])
	var node_ids: Dictionary = {}
	for node in nodes:
		var node_id := str(node.get("id", ""))
		helper.assert_true(node_id != "", "map node id exists")
		node_ids[node_id] = true

	var drills_data: Dictionary = _load_json(DRILLS_PATH)
	_validate_schema(helper, drills_data, drills_schema, "drills.json")
	var templates: Array = drills_data.get("templates", [])
	var template_ids: Dictionary = {}
	var template_lookup: Dictionary = {}
	for template in templates:
		var template_id := str(template.get("id", ""))
		helper.assert_true(template_id != "", "drill template id exists")
		template_ids[template_id] = true
		template_lookup[template_id] = template
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
		var base_count: int = 4
		if node.has("drill_plan"):
			var drill_plan = node.get("drill_plan", [])
			helper.assert_true(drill_plan is Array, "drill plan is array")
			if drill_plan is Array:
				base_count = drill_plan.size()
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
		elif template_id != "" and template_lookup.has(template_id):
			var template = template_lookup.get(template_id, {})
			if template is Dictionary:
				var plan: Array = template.get("plan", [])
				if plan is Array:
					base_count = plan.size()
		if node.has("drill_overrides"):
			var overrides = node.get("drill_overrides", {})
			helper.assert_true(overrides is Dictionary, "drill overrides dictionary")
			if overrides is Dictionary:
				var override_steps: Array = overrides.get("steps", [])
				if override_steps is Array:
					for entry in override_steps:
						helper.assert_true(entry is Dictionary, "drill override step dictionary")
						if not entry is Dictionary:
							continue
						var index := int(entry.get("index", -1))
						helper.assert_true(index >= 0, "drill override index non-negative")
						if base_count > 0:
							helper.assert_true(index < base_count, "drill override index in range")
				var replace_steps: Array = overrides.get("replace", [])
				if replace_steps is Array:
					for entry in replace_steps:
						helper.assert_true(entry is Dictionary, "drill replace entry dictionary")
						if not entry is Dictionary:
							continue
						var index := int(entry.get("index", -1))
						helper.assert_true(index >= 0, "drill replace index non-negative")
						if base_count > 0:
							helper.assert_true(index < base_count, "drill replace index in range")
						var step = entry.get("step", {})
						helper.assert_true(step is Dictionary, "drill replace step dictionary")
				var remove_indices: Array = overrides.get("remove", [])
				if remove_indices is Array:
					for raw_index in remove_indices:
						var index := int(raw_index)
						helper.assert_true(index >= 0, "drill remove index non-negative")
						if base_count > 0:
							helper.assert_true(index < base_count, "drill remove index in range")
				var append_steps: Array = overrides.get("append", [])
				if append_steps is Array:
					for step in append_steps:
						helper.assert_true(step is Dictionary, "drill append step dictionary")
				var prepend_steps: Array = overrides.get("prepend", [])
				if prepend_steps is Array:
					for step in prepend_steps:
						helper.assert_true(step is Dictionary, "drill prepend step dictionary")

	var kingdom_data: Dictionary = _load_json(KINGDOM_UPGRADES_PATH)
	_validate_schema(helper, kingdom_data, kingdom_schema, "kingdom_upgrades.json")
	var kingdom_upgrades: Array = kingdom_data.get("upgrades", [])
	for upgrade in kingdom_upgrades:
		var cost := int(upgrade.get("cost", 0))
		helper.assert_true(cost > 0, "kingdom upgrade cost positive")

	var unit_data: Dictionary = _load_json(UNIT_UPGRADES_PATH)
	_validate_schema(helper, unit_data, unit_schema, "unit_upgrades.json")
	var unit_upgrades: Array = unit_data.get("upgrades", [])
	for upgrade in unit_upgrades:
		var cost := int(upgrade.get("cost", 0))
		helper.assert_true(cost > 0, "unit upgrade cost positive")

	var assets_data: Dictionary = _load_json(ASSETS_PATH)
	_validate_schema(helper, assets_data, assets_schema, "assets_manifest.json")

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

func _load_schema(helper: TestHelper, path: String, label: String) -> Dictionary:
	var schema = _load_json(path)
	helper.assert_true(schema.size() > 0, "%s schema loaded" % label)
	return schema

func _validate_schema(helper: TestHelper, data: Dictionary, schema: Dictionary, label: String) -> void:
	if schema.is_empty():
		helper.assert_true(false, "schema missing: %s" % label)
		return
	var ok = _validate_value(data, schema, schema, label, helper)
	helper.assert_true(ok, "schema valid: %s" % label)

func _validate_value(value: Variant, schema: Dictionary, root: Dictionary, path: String, helper: TestHelper) -> bool:
	if not schema is Dictionary:
		helper.assert_true(false, "schema invalid at %s" % path)
		return false
	if schema.has("$ref"):
		var resolved = _resolve_ref(str(schema.get("$ref", "")), root, helper, path)
		if resolved.is_empty():
			return false
		return _validate_value(value, resolved, root, path, helper)
	var expected_type := str(schema.get("type", ""))
	if expected_type != "" and not _matches_type(value, expected_type):
		helper.assert_true(false, "schema type mismatch at %s (expected %s)" % [path, expected_type])
		return false
	if schema.has("enum"):
		var allowed = schema.get("enum", [])
		if allowed is Array and not allowed.has(value):
			helper.assert_true(false, "schema enum mismatch at %s" % path)
			return false
	if schema.has("pattern") and typeof(value) == TYPE_STRING:
		if not _matches_pattern(str(value), str(schema.get("pattern", "")), helper, path):
			return false
	if schema.has("minimum") and (typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT):
		if float(value) < float(schema.get("minimum", 0.0)):
			helper.assert_true(false, "schema minimum failed at %s" % path)
			return false
	if schema.has("exclusiveMinimum") and (typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT):
		if float(value) <= float(schema.get("exclusiveMinimum", 0.0)):
			helper.assert_true(false, "schema exclusive minimum failed at %s" % path)
			return false
	if expected_type == "array" and value is Array:
		if schema.has("minItems") and value.size() < int(schema.get("minItems", 0)):
			helper.assert_true(false, "schema minItems failed at %s" % path)
			return false
		if schema.has("items"):
			var item_schema = schema.get("items")
			var ok = true
			for i in range(value.size()):
				if not _validate_value(value[i], item_schema, root, "%s[%d]" % [path, i], helper):
					ok = false
			return ok
	if expected_type == "object" and value is Dictionary:
		var ok = true
		var required: Array = schema.get("required", [])
		for key in required:
			if not value.has(key):
				helper.assert_true(false, "schema missing required %s at %s" % [str(key), path])
				ok = false
		var properties: Dictionary = schema.get("properties", {})
		var additional = schema.get("additionalProperties", null)
		if additional is bool and not additional:
			for key in value.keys():
				if not properties.has(key):
					helper.assert_true(false, "schema additional property %s at %s" % [str(key), path])
					ok = false
		for key in properties.keys():
			if value.has(key):
				if not _validate_value(value.get(key), properties.get(key, {}), root, "%s.%s" % [path, str(key)], helper):
					ok = false
		return ok
	return true

func _resolve_ref(ref: String, root: Dictionary, helper: TestHelper, path: String) -> Dictionary:
	if not ref.begins_with("#/"):
		helper.assert_true(false, "schema ref invalid at %s" % path)
		return {}
	var trimmed = ref.substr(2)
	var parts = trimmed.split("/")
	var current: Variant = root
	for part in parts:
		if current is Dictionary and current.has(part):
			current = current[part]
		else:
			helper.assert_true(false, "schema ref missing at %s" % path)
			return {}
	if current is Dictionary:
		return current
	helper.assert_true(false, "schema ref not object at %s" % path)
	return {}

func _matches_type(value: Variant, expected: String) -> bool:
	match expected:
		"object":
			return value is Dictionary
		"array":
			return value is Array
		"string":
			return typeof(value) == TYPE_STRING
		"integer":
			if typeof(value) == TYPE_INT:
				return true
			if typeof(value) == TYPE_FLOAT:
				return is_equal_approx(value, floor(value))
			return false
		"number":
			return typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT
		"boolean":
			return typeof(value) == TYPE_BOOL
	return true

func _matches_pattern(text: String, pattern: String, helper: TestHelper, path: String) -> bool:
	if pattern == "":
		return true
	if _pattern_cache.has(pattern):
		var cached = _pattern_cache[pattern]
		if cached is RegEx:
			return cached.search(text) != null
	var regex = RegEx.new()
	var err = regex.compile(pattern)
	if err != OK:
		helper.assert_true(false, "schema pattern invalid at %s" % path)
		return false
	_pattern_cache[pattern] = regex
	if regex.search(text) == null:
		helper.assert_true(false, "schema pattern mismatch at %s" % path)
		return false
	return true
