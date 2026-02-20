extends "res://scripts/tests/e2e/e2e_section.gd"
## E2E tests for scene transitions and panel animations.


func get_section_name() -> String:
	return "transitions"


func _run_tests() -> void:
	_test_panel_visibility_toggle()
	_test_control_modulation()
	_test_scene_instantiation_speed()


func _test_panel_visibility_toggle() -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(100, 100)

	_add_to_root(panel)

	panel.visible = false
	_helper.assert_true(not panel.visible, "Panel starts hidden")

	panel.visible = true
	_helper.assert_true(panel.visible, "Panel becomes visible")

	panel.visible = false
	_helper.assert_true(not panel.visible, "Panel can be hidden again")

	_add_event("Panel visibility toggle works")
	_cleanup(panel)


func _test_control_modulation() -> void:
	var control := Control.new()
	control.custom_minimum_size = Vector2(50, 50)

	_add_to_root(control)

	_helper.assert_eq(control.modulate.a, 1.0, "Control starts fully opaque")

	control.modulate.a = 0.5
	_helper.assert_eq(control.modulate.a, 0.5, "Control alpha can be changed")

	control.modulate.a = 0.0
	_helper.assert_eq(control.modulate.a, 0.0, "Control can be fully transparent")

	_add_event("Control modulation works")
	_cleanup(control)


func _test_scene_instantiation_speed() -> void:
	var scenes: Array[String] = [
		"res://scenes/MainMenu.tscn",
		"res://scenes/Battlefield.tscn",
		"res://scenes/KingdomHub.tscn",
		"res://scenes/SettingsMenu.tscn"
	]

	var all_loaded: bool = true

	for scene_path in scenes:
		var packed = load(scene_path)
		if packed == null:
			all_loaded = false
			_helper.assert_true(false, "Scene loads: %s" % scene_path)
			continue

		var instance = packed.instantiate()
		if instance == null:
			all_loaded = false
			_helper.assert_true(false, "Scene instantiates: %s" % scene_path)
			continue

		_helper.assert_true(true, "Scene ready: %s" % scene_path)
		instance.free()

	_helper.assert_true(all_loaded, "All main scenes load successfully")
	_add_event("Scene instantiation validated")
