extends RefCounted

const TestHelper = preload("res://scripts/tests/test_helper.gd")
const ProgressionStateScript = preload("res://scripts/ProgressionState.gd")
const GameControllerScript = preload("res://scripts/GameController.gd")

func run_with_tree(tree: SceneTree) -> Dictionary:
	var helper = TestHelper.new()
	var packed = load("res://scenes/Battlefield.tscn")
	helper.assert_true(packed != null, "scene loads: battlefield")
	if packed == null:
		return helper.summary()
	var instance = packed.instantiate()
	helper.assert_true(instance is Control, "battlefield root is Control")
	if not instance is Control:
		if instance != null:
			instance.free()
		return helper.summary()

	var control := instance as Control
	var root = tree.root
	var original_size = root.size
	root.size = _get_project_viewport_size(helper)
	control.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(control)

	var progression = ProgressionStateScript.new()
	var game_controller = GameControllerScript.new()
	progression.persistence_enabled = false
	progression._load_static_data()
	_reset_progression(progression)
	game_controller.next_battle_node_id = _pick_first_node_id(progression)
	_wire_battle_nodes(control, progression, game_controller)
	control._initialize_battle()
	_assert_hud_state(helper, control, progression)

	root.remove_child(control)
	control.free()
	progression.free()
	game_controller.free()
	root.size = original_size
	return helper.summary()

func _get_project_viewport_size(helper: TestHelper) -> Vector2:
	var width = ProjectSettings.get_setting("display/window/size/viewport_width")
	var height = ProjectSettings.get_setting("display/window/size/viewport_height")
	var has_settings = width != null and height != null
	helper.assert_true(has_settings, "project viewport size configured")
	if not has_settings:
		return Vector2(1280, 720)
	return Vector2(float(width), float(height))

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

func _wire_battle_nodes(battle: Control, progression, game_controller) -> void:
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
	battle.bonus_label = battle.get_node("BonusPanel/Content/BonusLabel")
	battle.result_panel = battle.get_node("ResultPanel")
	battle.result_label = battle.get_node("ResultPanel/Content/ResultLabel")
	battle.result_button = battle.get_node("ResultPanel/Content/ResultButton")

func _assert_hud_state(helper: TestHelper, battle: Control, progression) -> void:
	var lesson_label := battle.get_node("TopBar/LessonLabel") as Label
	var gold_label := battle.get_node("TopBar/GoldLabel") as Label
	var drill_title := battle.get_node("TypingPanel/Content/DrillTitle") as Label
	var drill_hint := battle.get_node("TypingPanel/Content/DrillHint") as Label
	var drill_target := battle.get_node("TypingPanel/Content/DrillTarget") as RichTextLabel
	var targets_label := battle.get_node("TargetsLabel") as Label
	var word_label := battle.get_node("TypingPanel/Content/TypingReadout/WordLabel") as Label
	var typed_label := battle.get_node("TypingPanel/Content/TypingReadout/TypedLabel") as Label
	var accuracy_label := battle.get_node("StatusPanel/Content/AccuracyLabel") as Label
	var wpm_label := battle.get_node("StatusPanel/Content/WpmLabel") as Label
	var mistakes_label := battle.get_node("StatusPanel/Content/MistakesLabel") as Label
	var threat_bar := battle.get_node("StatusPanel/Content/ThreatBar") as ProgressBar
	var castle_label := battle.get_node("StatusPanel/Content/CastleLabel") as Label
	var bonus_label := battle.get_node("BonusPanel/Content/BonusLabel") as Label
	var buff_hud := battle.get_node("PlayField/BuffHud") as Control

	helper.assert_true(lesson_label != null, "Lesson label exists")
	helper.assert_true(gold_label != null, "Gold label exists")
	helper.assert_true(drill_title != null, "Drill title exists")
	helper.assert_true(drill_hint != null, "Drill hint exists")
	helper.assert_true(drill_target != null, "Drill target exists")
	helper.assert_true(targets_label != null, "Targets label exists")
	helper.assert_true(word_label != null, "Word label exists")
	helper.assert_true(typed_label != null, "Typed label exists")
	helper.assert_true(accuracy_label != null, "Accuracy label exists")
	helper.assert_true(wpm_label != null, "WPM label exists")
	helper.assert_true(mistakes_label != null, "Mistakes label exists")
	helper.assert_true(threat_bar != null, "Threat bar exists")
	helper.assert_true(castle_label != null, "Castle label exists")
	helper.assert_true(bonus_label != null, "Bonus label exists")
	helper.assert_true(buff_hud != null, "Buff HUD exists")

	if lesson_label != null:
		helper.assert_true(lesson_label.text.find("-") != -1, "Lesson label includes node and lesson")
	if gold_label != null:
		helper.assert_true(gold_label.text.find("Gold:") != -1, "Gold label formatted")
	if drill_title != null:
		helper.assert_true(drill_title.text.find("(") != -1, "Drill title includes step counter")
	if drill_hint != null:
		helper.assert_true(drill_hint.text.strip_edges() != "", "Drill hint text present")
	if drill_target != null:
		helper.assert_true(drill_target.bbcode_enabled, "Drill target uses BBCode")
		var current_word: String = battle.typing_system.get_current_word()
		helper.assert_true(current_word != "", "Current word exists")
		if current_word != "":
			helper.assert_true(drill_target.text.find(current_word) != -1, "Drill target shows word")
	if targets_label != null:
		helper.assert_true(targets_label.text.find("Targets:") != -1, "Targets label formatted")
	if word_label != null:
		helper.assert_true(word_label.text.find("Target:") != -1, "Word label formatted")
	if typed_label != null:
		helper.assert_true(typed_label.text.find("Typed:") != -1, "Typed label formatted")
	if accuracy_label != null:
		helper.assert_true(accuracy_label.text.find("Accuracy:") != -1, "Accuracy label formatted")
	if wpm_label != null:
		helper.assert_true(wpm_label.text.find("WPM:") != -1, "WPM label formatted")
	if mistakes_label != null:
		helper.assert_true(mistakes_label.text.find("Errors:") != -1, "Mistakes label formatted")
	if castle_label != null:
		helper.assert_true(castle_label.text.find("Castle Health:") != -1, "Castle label formatted")
	if bonus_label != null:
		helper.assert_true(bonus_label.text.find("Bonuses:") != -1, "Bonus label formatted")
	if threat_bar != null:
		helper.assert_true(threat_bar.value >= 0.0, "Threat bar value set")
	if buff_hud != null:
		helper.assert_true(not buff_hud.visible, "Buff HUD hidden by default")
