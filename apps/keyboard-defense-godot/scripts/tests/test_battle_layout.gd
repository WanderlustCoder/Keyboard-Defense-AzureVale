extends RefCounted

const TestHelper = preload("res://scripts/tests/test_helper.gd")
const EXTRA_SCALE := 1.5
const MIN_GAP_PLAYFIELD_TYPING := 12.0
const MIN_GAP_TYPING_STATUS := 12.0
const MIN_BOTTOM_MARGIN := 16.0

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
		_assert_layout(helper, control, viewport_size, size_label)
		root.remove_child(control)
		control.free()
		root.size = original_size
	else:
		instance.free()

func _assert_layout(helper: TestHelper, battle: Control, viewport_size: Vector2, size_label: String) -> void:
	var playfield := battle.get_node("PlayField") as Control
	var typing_panel := battle.get_node("TypingPanel") as Control
	var status_panel := battle.get_node("StatusPanel") as Control
	var bonus_panel := battle.get_node("BonusPanel") as Control
	var threat_bar := battle.get_node("StatusPanel/Content/ThreatBar") as Control

	helper.assert_true(playfield != null, "PlayField exists (%s)" % size_label)
	helper.assert_true(typing_panel != null, "TypingPanel exists (%s)" % size_label)
	helper.assert_true(status_panel != null, "StatusPanel exists (%s)" % size_label)
	helper.assert_true(bonus_panel != null, "BonusPanel exists (%s)" % size_label)
	helper.assert_true(threat_bar != null, "Threat bar exists (%s)" % size_label)

	helper.assert_true(playfield.anchor_bottom <= typing_panel.anchor_top, "PlayField above TypingPanel (%s)" % size_label)
	helper.assert_true(typing_panel.anchor_bottom <= status_panel.anchor_top, "TypingPanel above StatusPanel (%s)" % size_label)
	helper.assert_true(typing_panel.anchor_bottom <= bonus_panel.anchor_top, "TypingPanel above BonusPanel (%s)" % size_label)

	var gap_playfield_typing = (typing_panel.anchor_top - playfield.anchor_bottom) * viewport_size.y
	var gap_typing_status = (status_panel.anchor_top - typing_panel.anchor_bottom) * viewport_size.y
	var gap_typing_bonus = (bonus_panel.anchor_top - typing_panel.anchor_bottom) * viewport_size.y
	var bottom_margin_status = (1.0 - status_panel.anchor_bottom) * viewport_size.y
	var bottom_margin_bonus = (1.0 - bonus_panel.anchor_bottom) * viewport_size.y

	helper.assert_true(gap_playfield_typing >= MIN_GAP_PLAYFIELD_TYPING, "Gap PlayField->Typing >= %.1f (%s)" % [MIN_GAP_PLAYFIELD_TYPING, size_label])
	helper.assert_true(gap_typing_status >= MIN_GAP_TYPING_STATUS, "Gap Typing->Status >= %.1f (%s)" % [MIN_GAP_TYPING_STATUS, size_label])
	helper.assert_true(gap_typing_bonus >= MIN_GAP_TYPING_STATUS, "Gap Typing->Bonus >= %.1f (%s)" % [MIN_GAP_TYPING_STATUS, size_label])
	helper.assert_true(bottom_margin_status >= MIN_BOTTOM_MARGIN, "Status bottom margin >= %.1f (%s)" % [MIN_BOTTOM_MARGIN, size_label])
	helper.assert_true(bottom_margin_bonus >= MIN_BOTTOM_MARGIN, "Bonus bottom margin >= %.1f (%s)" % [MIN_BOTTOM_MARGIN, size_label])

	_assert_fits_panel(helper, typing_panel, "TypingPanel", viewport_size, size_label)
	_assert_fits_panel(helper, status_panel, "StatusPanel", viewport_size, size_label)
	_assert_fits_panel(helper, bonus_panel, "BonusPanel", viewport_size, size_label)

func _assert_fits_panel(helper: TestHelper, panel: Control, name: String, viewport_size: Vector2, size_label: String) -> void:
	var available := viewport_size.y * (panel.anchor_bottom - panel.anchor_top)
	var min_height := panel.get_combined_minimum_size().y
	helper.assert_true(panel.anchor_top >= 0.0, "%s anchor top within bounds (%s)" % [name, size_label])
	helper.assert_true(panel.anchor_bottom <= 1.0, "%s anchor bottom within bounds (%s)" % [name, size_label])
	helper.assert_true(panel.anchor_top < panel.anchor_bottom, "%s anchors ordered (%s)" % [name, size_label])
	helper.assert_true(min_height <= available + 0.5, "%s fits (min %.2f <= %.2f) (%s)" % [name, min_height, available, size_label])
