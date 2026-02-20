extends "res://scripts/tests/e2e/e2e_section.gd"
## E2E tests for SettingsMenu screen.

const SCENE_PATH := "res://scenes/SettingsMenu.tscn"


func get_section_name() -> String:
	return "settings"


func _run_tests() -> void:
	_test_scene_loads()
	_test_audio_controls()
	_test_accessibility_controls()
	_test_navigation_buttons()


func _test_scene_loads() -> void:
	var settings = _instantiate_scene(SCENE_PATH)
	_helper.assert_true(settings != null, "SettingsMenu scene loads")
	if settings:
		_helper.assert_true(settings is Control, "SettingsMenu is Control")
		_add_event("Settings menu loaded")
		_cleanup(settings)


func _test_audio_controls() -> void:
	var settings = _instantiate_scene(SCENE_PATH)
	if settings == null:
		return

	_add_to_root(settings)

	var has_volume_control: bool = false
	var children: Array = _find_all_children(settings)

	for child in children:
		if child is HSlider:
			has_volume_control = true
			break
		if child is Label:
			var label_text: String = child.text.to_lower()
			if "volume" in label_text or "music" in label_text or "sfx" in label_text:
				has_volume_control = true

	_helper.assert_true(has_volume_control, "Settings has volume controls")
	_add_event("Audio controls validated")
	_cleanup(settings)


func _test_accessibility_controls() -> void:
	var settings = _instantiate_scene(SCENE_PATH)
	if settings == null:
		return

	_add_to_root(settings)

	var has_accessibility: bool = false
	var children: Array = _find_all_children(settings)

	for child in children:
		if child is CheckButton or child is CheckBox:
			has_accessibility = true
			break

	_helper.assert_true(has_accessibility, "Settings has accessibility toggles")
	_add_event("Accessibility controls validated")
	_cleanup(settings)


func _test_navigation_buttons() -> void:
	var settings = _instantiate_scene(SCENE_PATH)
	if settings == null:
		return

	_add_to_root(settings)

	var has_back: bool = false
	var children: Array = _find_all_children(settings)

	for child in children:
		if child is Button:
			var btn_text: String = child.text.to_lower()
			if "back" in btn_text or "close" in btn_text or "done" in btn_text:
				has_back = true
				break

	_helper.assert_true(has_back, "Settings has back/close button")
	_add_event("Navigation buttons validated")
	_cleanup(settings)
