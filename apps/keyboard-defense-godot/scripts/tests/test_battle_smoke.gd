extends RefCounted

const TestHelper = preload("res://scripts/tests/test_helper.gd")
const BATTLE_SCENE = "res://scenes/Battlefield.tscn"
const ProgressionStateScript = preload("res://scripts/ProgressionState.gd")
const GameControllerScript = preload("res://scripts/GameController.gd")

func run() -> Dictionary:
	var helper = TestHelper.new()
	print("[battle_smoke] begin")
	var progression = ProgressionStateScript.new()
	var game_controller = GameControllerScript.new()
	var battle = null
	var battle_fail = null
	progression.persistence_enabled = false
	progression._load_static_data()
	_reset_progression(progression)

	var node_id = _pick_first_node_id(progression)
	print("[battle_smoke] node_id=%s" % node_id)
	helper.assert_true(node_id != "", "map node available for battle")
	if node_id == "":
		var summary = helper.summary()
		_cleanup_battle(battle, battle_fail, progression, game_controller)
		return summary

	game_controller.next_battle_node_id = node_id
	battle = _spawn_battle(progression, game_controller)
	helper.assert_true(battle != null, "battle scene instantiates")
	if battle == null:
		var summary = helper.summary()
		_cleanup_battle(battle, battle_fail, progression, game_controller)
		return summary
	print("[battle_smoke] victory battle ready")
	_type_lesson_words(battle)
	helper.assert_true(not battle.active, "battle ends after typing lesson")
	helper.assert_true(battle.result_panel.visible, "victory result panel visible")
	helper.assert_true(battle.result_action == "map", "victory returns to map")
	helper.assert_true(progression.is_node_completed(node_id), "node marked complete")
	if is_instance_valid(battle):
		battle.free()
		battle = null

	game_controller.next_battle_node_id = node_id
	battle_fail = _spawn_battle(progression, game_controller)
	helper.assert_true(battle_fail != null, "battle scene instantiates (defeat)")
	if battle_fail == null:
		var summary = helper.summary()
		_cleanup_battle(battle, battle_fail, progression, game_controller)
		return summary
	print("[battle_smoke] defeat battle ready")
	_force_defeat(battle_fail)
	helper.assert_true(not battle_fail.active, "battle ends on defeat")
	helper.assert_true(battle_fail.result_panel.visible, "defeat result panel visible")
	helper.assert_true(battle_fail.result_action == "retry", "defeat offers retry")
	if is_instance_valid(battle_fail):
		battle_fail.free()
		battle_fail = null

	var summary = helper.summary()
	_cleanup_battle(battle, battle_fail, progression, game_controller)
	return summary

func _cleanup_battle(battle, battle_fail, progression, game_controller) -> void:
	if is_instance_valid(battle):
		battle.free()
	if is_instance_valid(battle_fail):
		battle_fail.free()
	if is_instance_valid(progression):
		progression.free()
	if is_instance_valid(game_controller):
		game_controller.free()

func _reset_progression(progression) -> void:
	progression.gold = 0
	progression.completed_nodes = {}
	progression.purchased_upgrades = {}
	progression.modifiers = progression.DEFAULT_MODIFIERS.duplicate(true)
	progression.mastery = progression.DEFAULT_MASTERY.duplicate(true)
	progression.last_summary = {}

func _pick_first_node_id(progression) -> String:
	if progression.map_order.size() == 0:
		return ""
	return str(progression.map_order[0])

func _spawn_battle(progression, game_controller):
	var packed = load(BATTLE_SCENE)
	if packed == null:
		return null
	var instance = packed.instantiate()
	_wire_battle_nodes(instance, progression, game_controller)
	instance.result_panel.visible = false
	instance._initialize_battle()
	return instance

func _wire_battle_nodes(battle, progression, game_controller) -> void:
	battle.progression = progression
	battle.game_controller = game_controller
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
	battle.bonus_label = battle.get_node("BonusPanel/BonusLabel")
	battle.result_panel = battle.get_node("ResultPanel")
	battle.result_label = battle.get_node("ResultPanel/Content/ResultLabel")
	battle.result_button = battle.get_node("ResultPanel/Content/ResultButton")

func _type_lesson_words(battle) -> void:
	var guard = 0
	while battle.active and guard < 120:
		if battle.drill_mode == "intermission":
			battle._process(1.0)
			guard += 1
			continue
		var current_word: String = battle.typing_system.get_current_word()
		if current_word == "":
			battle._process(0.1)
			guard += 1
			continue
		for i in range(current_word.length()):
			if not battle.active or battle.drill_mode == "intermission":
				break
			var letter = current_word.substr(i, 1)
			var result: Dictionary = battle.typing_system.input_char(letter)
			battle._handle_typing_result(result)
		guard += 1

func _force_defeat(battle) -> void:
	var guard = 0
	while battle.active and guard < 6:
		if battle.drill_mode == "intermission":
			battle._process(1.0)
			guard += 1
			continue
		var current_word = battle.typing_system.get_current_word()
		var wrong_letter = "x"
		if current_word.begins_with(wrong_letter):
			wrong_letter = "z"
		var result: Dictionary = battle.typing_system.input_char(wrong_letter)
		battle._handle_typing_result(result)
		if battle.battle_stage != null:
			battle.battle_stage.set_progress_percent(100.0)
		else:
			battle.threat = 100.0
		battle._process(0.0)
		guard += 1
	if battle.active:
		battle._finish_battle(false)
