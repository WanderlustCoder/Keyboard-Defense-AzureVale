extends RefCounted

const TestHelper = preload("res://scripts/tests/test_helper.gd")
const ProgressionStateScript = preload("res://scripts/ProgressionState.gd")
const EXTRA_SCALE := 1.5

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
		control.progression = progression
		control.map_grid = control.get_node("MapPanel/MapGrid")
		control.gold_label = control.get_node("TopBar/GoldLabel")
		control.summary_label = control.get_node("SummaryPanel/Content/SummaryLabel")
		control.modifiers_label = control.get_node("SummaryPanel/Content/ModifiersLabel")
		if control.has_method("_refresh"):
			control.call("_refresh")
		_assert_map_layout(helper, control, viewport_size, size_label)
		root.remove_child(control)
		control.free()
		progression.free()
		root.size = original_size
	else:
		instance.free()

func _assert_map_layout(helper: TestHelper, map: Control, viewport_size: Vector2, size_label: String) -> void:
	var map_panel := map.get_node("MapPanel") as Control
	var map_grid := map.get_node("MapPanel/MapGrid") as GridContainer
	helper.assert_true(map_panel != null, "MapPanel exists (%s)" % size_label)
	helper.assert_true(map_grid != null, "MapGrid exists (%s)" % size_label)
	if map_panel == null or map_grid == null:
		return

	var panel_size = _resolve_control_size(map_panel, viewport_size)
	var grid_size = _resolve_control_size(map_grid, panel_size)
	helper.assert_true(grid_size.x > 0.0 and grid_size.y > 0.0, "MapGrid has size (%s)" % size_label)

	var controls: Array = []
	for child in map_grid.get_children():
		if child is Control:
			controls.append(child)
	var total = controls.size()
	helper.assert_true(total > 0, "Map nodes exist (%s)" % size_label)
	if total == 0:
		return

	var columns = max(map_grid.columns, 1)
	var rows = int(ceil(float(total) / float(columns)))
	var h_sep = float(map_grid.get_theme_constant("h_separation"))
	var v_sep = float(map_grid.get_theme_constant("v_separation"))
	var cell_width = (grid_size.x - (columns - 1) * h_sep) / float(columns)
	var cell_height = (grid_size.y - (rows - 1) * v_sep) / float(rows)
	helper.assert_true(cell_width > 0.0 and cell_height > 0.0, "MapGrid cells positive (%s)" % size_label)

	for button in controls:
		var min_size = button.get_combined_minimum_size()
		var target_width = button.custom_minimum_size.x
		if target_width <= 0.0:
			target_width = min_size.x
		var target_height = max(button.custom_minimum_size.y, min_size.y)
		helper.assert_true(target_width <= cell_width + 0.5, "Map card fits width (%s)" % size_label)
		helper.assert_true(target_height <= cell_height + 0.5, "Map card fits height (%s)" % size_label)
		helper.assert_true(_has_visible_text(button), "Map card has text (%s)" % size_label)

func _resolve_control_size(control: Control, parent_size: Vector2) -> Vector2:
	var width = (control.anchor_right - control.anchor_left) * parent_size.x + control.offset_right - control.offset_left
	var height = (control.anchor_bottom - control.anchor_top) * parent_size.y + control.offset_bottom - control.offset_top
	return Vector2(width, height)

func _has_visible_text(node: Node) -> bool:
	if node is Button:
		var button := node as Button
		if button.text.strip_edges() != "":
			return true
	if node is Label:
		var label := node as Label
		if label.text.strip_edges() != "":
			return true
	if node is RichTextLabel:
		var rich := node as RichTextLabel
		if rich.text.strip_edges() != "":
			return true
	for child in node.get_children():
		if _has_visible_text(child):
			return true
	return false
