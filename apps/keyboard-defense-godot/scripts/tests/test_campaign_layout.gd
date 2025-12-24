extends RefCounted

const TestHelper = preload("res://scripts/tests/test_helper.gd")
const ProgressionStateScript = preload("res://scripts/ProgressionState.gd")
const EXTRA_SCALE := 1.5
const MIN_GAP_TOPBAR_MAP := 12.0
const MIN_GAP_MAP_SUMMARY := 12.0
const MIN_BOTTOM_MARGIN := 16.0

func run_with_tree(tree: SceneTree) -> Dictionary:
	var helper = TestHelper.new()
	var packed = load("res://scenes/CampaignMap.tscn")
	helper.assert_true(packed != null, "scene loads: campaign map")
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
	helper.assert_true(instance is Control, "campaign map root is Control (%s)" % size_label)
	if instance is Control:
		var root = tree.root
		var original_size = root.size
		root.size = viewport_size
		var control := instance as Control
		control.set_anchors_preset(Control.PRESET_FULL_RECT)
		root.add_child(control)
		var progression = ProgressionStateScript.new()
		progression.persistence_enabled = false
		progression._load_static_data()
		_wire_map_nodes(control, progression)
		if control.has_method("_refresh"):
			control.call("_refresh")
		_assert_layout(helper, control, viewport_size, size_label)
		root.remove_child(control)
		control.free()
		progression.free()
		root.size = original_size
	else:
		instance.free()

func _wire_map_nodes(map: Control, progression) -> void:
	map.progression = progression
	map.map_grid = map.get_node("MapPanel/MapGrid")
	map.gold_label = map.get_node("TopBar/GoldLabel")
	map.summary_label = map.get_node("SummaryPanel/Content/SummaryLabel")
	map.modifiers_label = map.get_node("SummaryPanel/Content/ModifiersLabel")

func _assert_layout(helper: TestHelper, map: Control, viewport_size: Vector2, size_label: String) -> void:
	var top_bar := map.get_node("TopBar") as Control
	var title := map.get_node("TopBar/TitleLabel") as Label
	var gold_label := map.get_node("TopBar/GoldLabel") as Label
	var kingdom_button := map.get_node("TopBar/KingdomButton") as Button
	var back_button := map.get_node("TopBar/BackButton") as Button
	var map_panel := map.get_node("MapPanel") as Control
	var summary_panel := map.get_node("SummaryPanel") as Control
	var summary_label := map.get_node("SummaryPanel/Content/SummaryLabel") as Label
	var modifiers_label := map.get_node("SummaryPanel/Content/ModifiersLabel") as Label

	helper.assert_true(top_bar != null, "TopBar exists (%s)" % size_label)
	helper.assert_true(title != null, "Title label exists (%s)" % size_label)
	helper.assert_true(gold_label != null, "Gold label exists (%s)" % size_label)
	helper.assert_true(kingdom_button != null, "Kingdom button exists (%s)" % size_label)
	helper.assert_true(back_button != null, "Back button exists (%s)" % size_label)
	helper.assert_true(map_panel != null, "MapPanel exists (%s)" % size_label)
	helper.assert_true(summary_panel != null, "SummaryPanel exists (%s)" % size_label)
	helper.assert_true(summary_label != null, "Summary label exists (%s)" % size_label)
	helper.assert_true(modifiers_label != null, "Modifiers label exists (%s)" % size_label)

	if title != null:
		helper.assert_true(title.text.strip_edges() != "", "Title text present (%s)" % size_label)
	if gold_label != null:
		helper.assert_true(gold_label.text.strip_edges() != "", "Gold text present (%s)" % size_label)
	if kingdom_button != null:
		helper.assert_true(kingdom_button.text.strip_edges() != "", "Kingdom button text present (%s)" % size_label)
	if back_button != null:
		helper.assert_true(back_button.text.strip_edges() != "", "Back button text present (%s)" % size_label)
	if summary_label != null:
		helper.assert_true(summary_label.text.strip_edges() != "", "Summary text present (%s)" % size_label)
	if modifiers_label != null:
		helper.assert_true(modifiers_label.text.strip_edges() != "", "Modifiers text present (%s)" % size_label)

	if top_bar != null and map_panel != null and summary_panel != null:
		var top_bar_height = max(top_bar.custom_minimum_size.y, top_bar.get_combined_minimum_size().y)
		var top_bar_bottom = top_bar.offset_top + top_bar_height
		var map_top = _resolve_anchor_top(map_panel, viewport_size)
		var map_bottom = _resolve_anchor_bottom(map_panel, viewport_size)
		var summary_top = _resolve_anchor_top(summary_panel, viewport_size)
		var summary_bottom = _resolve_anchor_bottom(summary_panel, viewport_size)
		var gap_topbar_map = map_top - top_bar_bottom
		var gap_map_summary = summary_top - map_bottom
		var bottom_margin = viewport_size.y - summary_bottom

		helper.assert_true(map_panel.anchor_top < map_panel.anchor_bottom, "MapPanel anchors ordered (%s)" % size_label)
		helper.assert_true(summary_panel.anchor_top < summary_panel.anchor_bottom, "SummaryPanel anchors ordered (%s)" % size_label)
		helper.assert_true(gap_topbar_map >= MIN_GAP_TOPBAR_MAP, "Gap TopBar->Map >= %.1f (%s)" % [MIN_GAP_TOPBAR_MAP, size_label])
		helper.assert_true(gap_map_summary >= MIN_GAP_MAP_SUMMARY, "Gap Map->Summary >= %.1f (%s)" % [MIN_GAP_MAP_SUMMARY, size_label])
		helper.assert_true(bottom_margin >= MIN_BOTTOM_MARGIN, "Summary bottom margin >= %.1f (%s)" % [MIN_BOTTOM_MARGIN, size_label])

func _resolve_anchor_top(control: Control, parent_size: Vector2) -> float:
	return control.anchor_top * parent_size.y + control.offset_top

func _resolve_anchor_bottom(control: Control, parent_size: Vector2) -> float:
	return control.anchor_bottom * parent_size.y + control.offset_bottom
