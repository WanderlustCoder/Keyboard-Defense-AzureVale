extends "res://scripts/tests/e2e/e2e_section.gd"
## E2E tests for KingdomDefense RTS mode and campaign map.

const SCENE_PATH := "res://scenes/KingdomDefense.tscn"


func get_section_name() -> String:
	return "campaign"


func _run_tests() -> void:
	_test_scene_loads()
	_test_hud_elements()
	_test_typing_panel()
	_test_phase_label()
	_test_resource_display()


func _test_scene_loads() -> void:
	var campaign = _instantiate_scene(SCENE_PATH)
	_helper.assert_true(campaign != null, "KingdomDefense scene loads")
	if campaign:
		_helper.assert_true(campaign is Control, "KingdomDefense is Control")
		_add_event("Campaign scene loaded")
		_cleanup(campaign)


func _test_hud_elements() -> void:
	var campaign = _instantiate_scene(SCENE_PATH)
	if campaign == null:
		return

	_add_to_root(campaign)

	var day_label = _get_node_safe(campaign, "HUDLayer/HUD/TopBar/HBox/DayLabel")
	var wave_label = _get_node_safe(campaign, "HUDLayer/HUD/TopBar/HBox/WaveLabel")
	var hp_value = _get_node_safe(campaign, "HUDLayer/HUD/TopBar/HBox/HPBar/HPValue")
	var gold_value = _get_node_safe(campaign, "HUDLayer/HUD/TopBar/HBox/GoldBar/GoldValue")

	_helper.assert_true(day_label != null, "Day label exists")
	_helper.assert_true(wave_label != null, "Wave label exists")
	_helper.assert_true(hp_value != null, "HP value label exists")
	_helper.assert_true(gold_value != null, "Gold value label exists")

	_add_event("HUD elements validated")
	_cleanup(campaign)


func _test_typing_panel() -> void:
	var campaign = _instantiate_scene(SCENE_PATH)
	if campaign == null:
		return

	_add_to_root(campaign)

	var typing_panel = _get_node_safe(campaign, "HUDLayer/HUD/TypingPanel")
	_helper.assert_true(typing_panel != null, "Typing panel exists")

	if typing_panel:
		var word_display = _get_node_safe(typing_panel, "VBox/WordDisplay")
		var input_display = _get_node_safe(typing_panel, "VBox/InputDisplay")
		_helper.assert_true(word_display != null, "Word display exists")
		_helper.assert_true(input_display != null, "Input display exists")

	_add_event("Typing panel validated")
	_cleanup(campaign)


func _test_phase_label() -> void:
	var campaign = _instantiate_scene(SCENE_PATH)
	if campaign == null:
		return

	_add_to_root(campaign)

	var phase_label = _get_node_safe(campaign, "HUDLayer/HUD/TopBar/HBox/PhaseLabel")
	_helper.assert_true(phase_label != null, "Phase label exists")

	_cleanup(campaign)


func _test_resource_display() -> void:
	var campaign = _instantiate_scene(SCENE_PATH)
	if campaign == null:
		return

	_add_to_root(campaign)

	var resources_label = _get_node_safe(campaign, "HUDLayer/HUD/TopBar/HBox/ResourceBar/ResourcesLabel")
	_helper.assert_true(resources_label != null, "Resources label exists")

	_add_event("Resource display validated")
	_cleanup(campaign)
