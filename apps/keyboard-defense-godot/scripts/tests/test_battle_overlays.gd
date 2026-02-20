extends RefCounted

const TestHelper = preload("res://scripts/tests/test_helper.gd")
const ProgressionStateScript = preload("res://scripts/ProgressionState.gd")
const GameControllerScript = preload("res://scripts/GameController.gd")
const EXTRA_SCALE := 1.5

func run_with_tree(tree: SceneTree) -> Dictionary:
	var helper = TestHelper.new()
	var packed = load("res://scenes/Battlefield.tscn")
	helper.assert_true(packed != null, "scene loads: battlefield")
	if packed == null:
		return helper.summary()
	var base_size = _get_project_viewport_size(helper)
	var sizes: Array = _build_viewport_sizes(base_size)
	for viewport_size in sizes:
		_assert_layout_for_size(helper, packed, tree, viewport_size)
	return helper.summary()

func _get_project_viewport_size(helper: TestHelper) -> Vector2:
	var width = ProjectSettings.get_setting("display/window/size/viewport_width")
	var height = ProjectSettings.get_setting("display/window/size/viewport_height")
	var has_settings = width != null and height != null
	helper.assert_true(has_settings, "project viewport size configured")
	if not has_settings:
		return Vector2(1280, 720)
	return Vector2(float(width), float(height))

func _build_viewport_sizes(base_size: Vector2) -> Array:
	var sizes: Array = [base_size]
	var scaled = Vector2(base_size.x * EXTRA_SCALE, base_size.y * EXTRA_SCALE)
	if scaled != base_size:
		sizes.append(scaled)
	return sizes

func _assert_layout_for_size(helper: TestHelper, packed: PackedScene, tree: SceneTree, viewport_size: Vector2) -> void:
	var instance = packed.instantiate()
	var size_label = "%dx%d" % [int(viewport_size.x), int(viewport_size.y)]
	helper.assert_true(instance is Control, "battlefield root is Control (%s)" % size_label)
	if instance is Control:
		var root = tree.root
		var original_size = root.size
		root.size = viewport_size
		var control := instance as Control
		control.set_anchors_preset(Control.PRESET_FULL_RECT)
		root.add_child(control)
		var progression = ProgressionStateScript.new()
		var game_controller = GameControllerScript.new()
		progression.persistence_enabled = false
		progression._load_static_data()
		_reset_progression(progression)
		game_controller.next_battle_node_id = _pick_first_node_id(progression)
		_wire_battle_nodes(control, progression, game_controller)
		control._setup_pause_panel()
		control._setup_debug_panel()
		control._initialize_battle()
		_assert_overlays(helper, control, viewport_size, size_label)
		root.remove_child(control)
		control.free()
		progression.free()
		game_controller.free()
		root.size = original_size
	else:
		instance.free()

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
	battle.buff_hud = battle.get_node("PlayField/BuffHud")
	battle.buff_focus_row = battle.get_node("PlayField/BuffHud/Content/FocusRow")
	battle.buff_focus_label = battle.get_node("PlayField/BuffHud/Content/FocusRow/FocusLabel")
	battle.buff_focus_bar = battle.get_node("PlayField/BuffHud/Content/FocusRow/FocusBar")
	battle.buff_ward_row = battle.get_node("PlayField/BuffHud/Content/WardRow")
	battle.buff_ward_label = battle.get_node("PlayField/BuffHud/Content/WardRow/WardLabel")
	battle.buff_ward_bar = battle.get_node("PlayField/BuffHud/Content/WardRow/WardBar")

func _assert_overlays(helper: TestHelper, battle: Control, viewport_size: Vector2, size_label: String) -> void:
	var result_panel := battle.get_node("ResultPanel") as Control
	var pause_panel := battle.get_node("PausePanel") as Control
	var debug_panel := battle.get_node("DebugPanel") as Control
	var pause_label := battle.get_node("PausePanel/Content/PauseLabel") as Label
	var resume_button := battle.get_node("PausePanel/Content/ButtonRow/ResumeButton") as Button
	var retreat_button := battle.get_node("PausePanel/Content/ButtonRow/RetreatButton") as Button
	var debug_text := battle.get_node("DebugPanel/Content/OverridesText") as TextEdit
	var result_button := battle.get_node("ResultPanel/Content/ResultButton") as Button
	var buff_hud := battle.get_node("PlayField/BuffHud") as Control
	var buff_focus_row := battle.get_node("PlayField/BuffHud/Content/FocusRow") as Control
	var buff_ward_row := battle.get_node("PlayField/BuffHud/Content/WardRow") as Control

	helper.assert_true(result_panel != null, "Result panel exists (%s)" % size_label)
	helper.assert_true(pause_panel != null, "Pause panel exists (%s)" % size_label)
	helper.assert_true(debug_panel != null, "Debug panel exists (%s)" % size_label)
	helper.assert_true(pause_label != null, "Pause label exists (%s)" % size_label)
	helper.assert_true(resume_button != null, "Resume button exists (%s)" % size_label)
	helper.assert_true(retreat_button != null, "Retreat button exists (%s)" % size_label)
	helper.assert_true(debug_text != null, "Debug text exists (%s)" % size_label)
	helper.assert_true(result_button != null, "Result button exists (%s)" % size_label)
	helper.assert_true(buff_hud != null, "Buff HUD exists (%s)" % size_label)
	helper.assert_true(buff_focus_row != null, "Buff focus row exists (%s)" % size_label)
	helper.assert_true(buff_ward_row != null, "Buff ward row exists (%s)" % size_label)

	if result_panel != null:
		_assert_panel_bounds(helper, result_panel, viewport_size, "ResultPanel", size_label)
		helper.assert_true(not result_panel.visible, "Result panel hidden by default (%s)" % size_label)
	if pause_panel != null:
		_assert_panel_bounds(helper, pause_panel, viewport_size, "PausePanel", size_label)
		helper.assert_true(not pause_panel.visible, "Pause panel hidden by default (%s)" % size_label)
	if debug_panel != null:
		_assert_panel_bounds(helper, debug_panel, viewport_size, "DebugPanel", size_label)
		helper.assert_true(not debug_panel.visible, "Debug panel hidden by default (%s)" % size_label)
	if buff_hud != null:
		helper.assert_true(not buff_hud.visible, "Buff HUD hidden by default (%s)" % size_label)
		helper.assert_true(buff_focus_row == null or not buff_focus_row.visible, "Buff focus row hidden (%s)" % size_label)
		helper.assert_true(buff_ward_row == null or not buff_ward_row.visible, "Buff ward row hidden (%s)" % size_label)

func _assert_panel_bounds(helper: TestHelper, panel: Control, viewport_size: Vector2, name: String, size_label: String) -> void:
	helper.assert_true(panel.anchor_left >= 0.0, "%s anchor left >= 0 (%s)" % [name, size_label])
	helper.assert_true(panel.anchor_top >= 0.0, "%s anchor top >= 0 (%s)" % [name, size_label])
	helper.assert_true(panel.anchor_right <= 1.0, "%s anchor right <= 1 (%s)" % [name, size_label])
	helper.assert_true(panel.anchor_bottom <= 1.0, "%s anchor bottom <= 1 (%s)" % [name, size_label])
	helper.assert_true(panel.anchor_left < panel.anchor_right, "%s anchors ordered x (%s)" % [name, size_label])
	helper.assert_true(panel.anchor_top < panel.anchor_bottom, "%s anchors ordered y (%s)" % [name, size_label])
	var width = (panel.anchor_right - panel.anchor_left) * viewport_size.x + panel.offset_right - panel.offset_left
	var height = (panel.anchor_bottom - panel.anchor_top) * viewport_size.y + panel.offset_bottom - panel.offset_top
	helper.assert_true(width > 0.0, "%s width positive (%s)" % [name, size_label])
	helper.assert_true(height > 0.0, "%s height positive (%s)" % [name, size_label])
