extends "res://scripts/tests/e2e/e2e_section.gd"
## E2E tests for pause menu functionality.

const BATTLE_SCENE := "res://scenes/Battlefield.tscn"


func get_section_name() -> String:
	return "pause"


func _run_tests() -> void:
	_test_pause_panel_exists()
	_test_pause_panel_structure()


func _test_pause_panel_exists() -> void:
	var battle = _spawn_battle()
	if battle == null:
		return

	var pause_panel = _get_node_safe(battle, "PausePanel")
	_helper.assert_true(pause_panel != null, "Pause panel exists in battle")

	if pause_panel:
		_helper.assert_true(not pause_panel.visible, "Pause panel hidden by default")

	_add_event("Pause panel existence validated")
	_cleanup_battle(battle)


func _test_pause_panel_structure() -> void:
	var battle = _spawn_battle()
	if battle == null:
		return

	var pause_panel = _get_node_safe(battle, "PausePanel")
	if pause_panel == null:
		_helper.assert_true(false, "Pause panel exists for structure test")
		_cleanup_battle(battle)
		return

	var children: Array = _find_all_children(pause_panel)
	var has_buttons: bool = false

	for child in children:
		if child is Button:
			has_buttons = true
			break

	_helper.assert_true(has_buttons, "Pause panel has action buttons")
	_add_event("Pause panel structure validated")
	_cleanup_battle(battle)


# --- Battle helper methods ---

func _spawn_battle():
	var node_id: String = _get_node_id()
	if node_id == "":
		_helper.assert_true(false, "Map node available for battle")
		return null

	_context.game_controller.next_battle_node_id = node_id

	var packed = load(BATTLE_SCENE)
	if packed == null:
		return null

	var instance = packed.instantiate()
	_wire_minimal_battle(instance)
	return instance


func _get_node_id() -> String:
	if _context.progression.map_order.size() == 0:
		return ""
	return str(_context.progression.map_order[0])


func _wire_minimal_battle(battle) -> void:
	battle.progression = _context.progression
	battle.game_controller = _context.game_controller
	battle.result_panel = battle.get_node("ResultPanel")
	battle.result_panel.visible = false


func _cleanup_battle(battle) -> void:
	if is_instance_valid(battle):
		battle.free()
