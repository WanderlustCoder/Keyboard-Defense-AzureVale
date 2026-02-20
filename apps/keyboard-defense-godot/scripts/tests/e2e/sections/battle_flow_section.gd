extends "res://scripts/tests/e2e/e2e_section.gd"
## E2E tests for Battlefield typing combat, victory/defeat scenarios.

const SCENE_PATH := "res://scenes/Battlefield.tscn"
const ProgressionStateScript = preload("res://scripts/ProgressionState.gd")
const GameControllerScript = preload("res://scripts/GameController.gd")
const VICTORY_GUARD := 240


func get_section_name() -> String:
	return "battle"


func _run_tests() -> void:
	_test_battle_loads()
	_test_battle_ui_elements()
	_test_typing_system()
	_test_victory_scenario()
	_test_defeat_scenario()


func _test_battle_loads() -> void:
	var battle = _spawn_battle()
	_helper.assert_true(battle != null, "Battlefield scene loads")
	if battle:
		_helper.assert_true(battle.typing_system != null, "TypingSystem initialized")
		_add_event("Battle scene loaded")
		_cleanup_battle(battle)


func _test_battle_ui_elements() -> void:
	var battle = _spawn_battle()
	if battle == null:
		return

	_helper.assert_true(battle.result_panel != null, "Result panel exists")
	_helper.assert_true(battle.threat_bar != null, "Threat bar exists")
	_helper.assert_true(battle.word_label != null, "Word label exists")
	_helper.assert_true(battle.typed_label != null, "Typed label exists")
	_helper.assert_true(battle.accuracy_label != null, "Accuracy label exists")
	_helper.assert_true(battle.wpm_label != null, "WPM label exists")

	_add_event("Battle UI elements validated")
	_cleanup_battle(battle)


func _test_typing_system() -> void:
	var battle = _spawn_battle()
	if battle == null:
		return

	var word: String = battle.typing_system.get_current_word()
	_helper.assert_true(word != "", "Current word available")

	if word != "":
		var first_letter: String = word.substr(0, 1)
		var result: Dictionary = battle.typing_system.input_char(first_letter)
		_helper.assert_true(result.has("status"), "Input returns status")
		battle._handle_typing_result(result)

	_add_event("Typing system tested")
	_cleanup_battle(battle)


func _test_victory_scenario() -> void:
	_context.reset()
	var battle = _spawn_battle()
	if battle == null:
		return

	_autoplay_victory(battle)

	_helper.assert_true(not battle.active, "Battle ends after victory")
	_helper.assert_true(battle.result_panel.visible, "Victory result panel visible")
	_helper.assert_eq(battle.result_action, "map", "Victory returns to map")

	var node_id: String = _get_node_id()
	_helper.assert_true(_context.progression.is_node_completed(node_id), "Node marked complete")

	_add_event("Victory scenario completed")
	_cleanup_battle(battle)


func _test_defeat_scenario() -> void:
	_context.reset()
	var battle = _spawn_battle()
	if battle == null:
		return

	_autoplay_defeat(battle)

	_helper.assert_true(not battle.active, "Battle ends after defeat")
	_helper.assert_true(battle.result_panel.visible, "Defeat result panel visible")
	_helper.assert_eq(battle.result_action, "retry", "Defeat offers retry")

	_add_event("Defeat scenario completed")
	_cleanup_battle(battle)


# --- Battle helper methods ---

func _spawn_battle():
	var node_id: String = _get_node_id()
	if node_id == "":
		_helper.assert_true(false, "Map node available for battle")
		return null

	_context.game_controller.next_battle_node_id = node_id

	var packed = load(SCENE_PATH)
	if packed == null:
		return null

	var instance = packed.instantiate()
	_wire_battle_nodes(instance)
	instance.result_panel.visible = false
	instance._initialize_battle()
	return instance


func _get_node_id() -> String:
	if _context.progression.map_order.size() == 0:
		return ""
	return str(_context.progression.map_order[0])


func _wire_battle_nodes(battle) -> void:
	battle.progression = _context.progression
	battle.game_controller = _context.game_controller
	battle.lesson_label = battle.get_node("TopBar/LessonLabel")
	battle.gold_label = battle.get_node("TopBar/GoldLabel")
	battle.exit_button = battle.get_node("TopBar/ExitButton")
	battle.battle_stage = battle.get_node("PlayField/BattleStage")
	battle.drill_title_label = battle.get_node("TypingPanel/Content/DrillTitle")
	battle.drill_target_label = battle.get_node("TypingPanel/Content/DrillTarget")
	battle.drill_progress_label = battle.get_node("TargetsLabel")
	battle.drill_hint_label = battle.get_node("TypingPanel/Content/DrillHint")
	battle.word_label = battle.get_node("TypingPanel/Content/TypingReadout/WordLabel")
	battle.typed_label = battle.get_node("TypingPanel/Content/TypingReadout/TypedLabel")
	battle.accuracy_label = battle.get_node("StatusPanel/Content/AccuracyLabel")
	battle.wpm_label = battle.get_node("StatusPanel/Content/WpmLabel")
	battle.mistakes_label = battle.get_node("StatusPanel/Content/MistakesLabel")
	battle.threat_bar = battle.get_node("StatusPanel/Content/ThreatBar")
	battle.castle_label = battle.get_node("StatusPanel/Content/CastleLabel")
	battle.bonus_label = battle.get_node("BonusPanel/Content/BonusLabel")
	battle.result_panel = battle.get_node("ResultPanel")
	battle.result_label = battle.get_node("ResultPanel/Content/ResultLabel")
	battle.result_button = battle.get_node("ResultPanel/Content/ResultButton")


func _autoplay_victory(battle) -> void:
	var guard: int = 0
	while battle.active and guard < VICTORY_GUARD:
		if battle.drill_mode == "intermission":
			var step: float = max(battle.drill_timer, 0.1)
			battle._process(step)
			guard += 1
			continue
		var word: String = battle.typing_system.get_current_word()
		if word == "":
			battle._process(0.1)
			guard += 1
			continue
		for i in range(word.length()):
			if not battle.active or battle.drill_mode == "intermission":
				break
			var letter: String = word.substr(i, 1)
			var result: Dictionary = battle.typing_system.input_char(letter)
			battle._handle_typing_result(result)
		guard += 1


func _autoplay_defeat(battle) -> void:
	var guard: int = 0
	var max_guard: int = max(6, battle.castle_health + 2)
	while battle.active and guard < max_guard:
		if battle.drill_mode == "intermission":
			var step: float = max(battle.drill_timer, 0.1)
			battle._process(step)
			guard += 1
			continue
		var word: String = battle.typing_system.get_current_word()
		var wrong: String = "x" if not word.begins_with("x") else "z"
		var result: Dictionary = battle.typing_system.input_char(wrong)
		battle._handle_typing_result(result)
		if battle.battle_stage != null:
			battle.battle_stage.set_progress_percent(100.0)
		else:
			battle.threat = 100.0
		battle._process(0.0)
		guard += 1
	if battle.active:
		battle._finish_battle(false)


func _cleanup_battle(battle) -> void:
	if is_instance_valid(battle):
		battle.free()
