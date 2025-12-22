extends RefCounted

const TestHelper = preload("res://scripts/tests/test_helper.gd")
const BATTLE_SCENE = "res://scenes/Battlefield.tscn"
const ProgressionStateScript = preload("res://scripts/ProgressionState.gd")
const GameControllerScript = preload("res://scripts/GameController.gd")

const VICTORY_GUARD := 240

func run() -> Dictionary:
	var helper = TestHelper.new()
	print("[battle_autoplay] begin")
	var node_ids = _collect_node_ids()
	helper.assert_true(node_ids.size() > 0, "map nodes available for autoplay")
	for node_id in node_ids:
		_run_victory_scenario(node_id, helper)
		_run_defeat_scenario(node_id, helper)
	return helper.summary()

func _collect_node_ids() -> Array:
	var progression = _build_progression()
	var node_ids: Array = []
	for node_id in progression.map_order:
		node_ids.append(str(node_id))
	progression.free()
	return node_ids

func _run_victory_scenario(node_id: String, helper) -> void:
	var progression = _build_progression()
	var game_controller = GameControllerScript.new()
	game_controller.next_battle_node_id = node_id
	var battle = _spawn_battle(progression, game_controller)
	helper.assert_true(battle != null, "battle instantiates for %s (victory)" % node_id)
	if battle == null:
		_cleanup_battle(battle, progression, game_controller)
		return
	print("[battle_autoplay] victory node_id=%s" % node_id)
	_autoplay_victory(battle)
	helper.assert_true(not battle.active, "battle ends after autoplay %s" % node_id)
	helper.assert_true(battle.result_panel.visible, "victory result panel visible %s" % node_id)
	helper.assert_true(battle.result_action == "map", "victory returns to map %s" % node_id)
	helper.assert_true(progression.is_node_completed(node_id), "node marked complete %s" % node_id)
	_cleanup_battle(battle, progression, game_controller)

func _run_defeat_scenario(node_id: String, helper) -> void:
	var progression = _build_progression()
	var game_controller = GameControllerScript.new()
	game_controller.next_battle_node_id = node_id
	var battle = _spawn_battle(progression, game_controller)
	helper.assert_true(battle != null, "battle instantiates for %s (defeat)" % node_id)
	if battle == null:
		_cleanup_battle(battle, progression, game_controller)
		return
	print("[battle_autoplay] defeat node_id=%s" % node_id)
	_autoplay_defeat(battle)
	helper.assert_true(not battle.active, "battle ends after defeat %s" % node_id)
	helper.assert_true(battle.result_panel.visible, "defeat result panel visible %s" % node_id)
	helper.assert_true(battle.result_action == "retry", "defeat offers retry %s" % node_id)
	helper.assert_true(not progression.is_node_completed(node_id), "node not completed after defeat %s" % node_id)
	_cleanup_battle(battle, progression, game_controller)

func _build_progression():
	var progression = ProgressionStateScript.new()
	progression.persistence_enabled = false
	progression._load_static_data()
	_reset_progression(progression)
	return progression

func _reset_progression(progression) -> void:
	progression.gold = 0
	progression.completed_nodes = {}
	progression.purchased_upgrades = {}
	progression.modifiers = progression.DEFAULT_MODIFIERS.duplicate(true)
	progression.mastery = progression.DEFAULT_MASTERY.duplicate(true)
	progression.last_summary = {}

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
	battle.drill_title_label = battle.get_node("PlayField/DrillHud/DrillTitle")
	battle.drill_target_label = battle.get_node("PlayField/DrillHud/DrillTarget")
	battle.drill_progress_label = battle.get_node("PlayField/DrillHud/DrillProgress")
	battle.drill_hint_label = battle.get_node("PlayField/DrillHud/DrillHint")
	battle.word_label = battle.get_node("StatusPanel/Content/WordLabel")
	battle.typed_label = battle.get_node("StatusPanel/Content/TypedLabel")
	battle.accuracy_label = battle.get_node("StatusPanel/Content/AccuracyLabel")
	battle.wpm_label = battle.get_node("StatusPanel/Content/WpmLabel")
	battle.mistakes_label = battle.get_node("StatusPanel/Content/MistakesLabel")
	battle.threat_bar = battle.get_node("ThreatPanel/ThreatBar")
	battle.castle_label = battle.get_node("ThreatPanel/CastleLabel")
	battle.bonus_label = battle.get_node("BonusPanel/BonusLabel")
	battle.result_panel = battle.get_node("ResultPanel")
	battle.result_label = battle.get_node("ResultPanel/Content/ResultLabel")
	battle.result_button = battle.get_node("ResultPanel/Content/ResultButton")

func _autoplay_victory(battle) -> void:
	var guard = 0
	while battle.active and guard < VICTORY_GUARD:
		if battle.drill_mode == "intermission":
			var step = max(battle.drill_timer, 0.1)
			battle._process(step)
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

func _autoplay_defeat(battle) -> void:
	var guard = 0
	var max_guard = max(6, battle.castle_health + 2)
	while battle.active and guard < max_guard:
		if battle.drill_mode == "intermission":
			var step = max(battle.drill_timer, 0.1)
			battle._process(step)
			guard += 1
			continue
		var current_word = battle.typing_system.get_current_word()
		var wrong_letter = "x"
		if current_word.begins_with(wrong_letter):
			wrong_letter = "z"
		var result: Dictionary = battle.typing_system.input_char(wrong_letter)
		battle._handle_typing_result(result)
		battle.threat = 100.0
		battle._process(0.0)
		guard += 1

func _cleanup_battle(battle, progression, game_controller) -> void:
	if is_instance_valid(battle):
		battle.free()
	if is_instance_valid(progression):
		progression.free()
	if is_instance_valid(game_controller):
		game_controller.free()
