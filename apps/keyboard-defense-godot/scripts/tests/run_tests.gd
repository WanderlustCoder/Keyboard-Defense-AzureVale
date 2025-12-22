extends SceneTree

const TESTS := [
	"res://scripts/tests/test_typing_system.gd",
	"res://scripts/tests/test_data_integrity.gd",
	"res://scripts/tests/test_progression_state.gd",
	"res://scripts/tests/test_scene_load.gd",
	"res://scripts/tests/test_battle_layout.gd",
	"res://scripts/tests/test_map_layout.gd",
	"res://scripts/tests/test_battle_smoke.gd",
	"res://scripts/tests/test_battle_autoplay.gd",
	"res://scripts/tests/test_battle_buffs.gd"
]

func _init() -> void:
	print("[tests] starting")
	var total_tests := 0
	var total_failed := 0
	for path in TESTS:
		print("[tests] running: %s" % path)
		var script = load(path)
		if script == null:
			printerr("[tests] Failed to load: %s" % path)
			total_failed += 1
			continue
		var instance = script.new()
		if not instance.has_method("run") and not instance.has_method("run_with_tree"):
			printerr("[tests] Missing run(): %s" % path)
			total_failed += 1
			continue
		var result = null
		if instance.has_method("run_with_tree"):
			result = instance.run_with_tree(self)
		else:
			result = instance.run()
		if result is Object and result.has_method("resume"):
			printerr("[tests] async test not supported: %s" % path)
			total_failed += 1
			continue
		if typeof(result) != TYPE_DICTIONARY:
			printerr("[tests] invalid result: %s" % path)
			total_failed += 1
			continue
		print("[tests] ran: %s" % path)
		var tests := int(result.get("tests", 0))
		var failed := int(result.get("failed", 0))
		var messages: Array = result.get("messages", [])
		total_tests += tests
		total_failed += failed
		for message in messages:
			printerr("[tests] %s" % str(message))
	if total_failed > 0:
		print("[tests] FAIL %d/%d" % [total_failed, total_tests])
		quit(1)
	else:
		print("[tests] OK %d" % total_tests)
		quit(0)
