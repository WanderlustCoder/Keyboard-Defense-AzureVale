extends RefCounted

const TestHelper = preload("res://scripts/tests/test_helper.gd")
const EXTRA_SCALE := 1.5
const MIN_GAP_TOPBAR_SCROLL := 12.0
const MIN_BOTTOM_MARGIN := 16.0

func run_with_tree(tree: SceneTree) -> Dictionary:
	var helper = TestHelper.new()
	var packed = load("res://scenes/KingdomHub.tscn")
	helper.assert_true(packed != null, "scene loads: kingdom hub")
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
	helper.assert_true(instance is Control, "kingdom hub root is Control (%s)" % size_label)
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

func _assert_layout(helper: TestHelper, hub: Control, viewport_size: Vector2, size_label: String) -> void:
	var top_bar := hub.get_node("TopBar") as Control
	var scroll := hub.get_node("Scroll") as ScrollContainer
	var content := hub.get_node("Scroll/Content") as VBoxContainer
	var modifiers := hub.get_node("Scroll/Content/ModifiersLabel") as Label
	var kingdom_header := hub.get_node("Scroll/Content/KingdomHeader") as Label
	var kingdom_list := hub.get_node("Scroll/Content/KingdomList") as VBoxContainer
	var unit_header := hub.get_node("Scroll/Content/UnitHeader") as Label
	var unit_list := hub.get_node("Scroll/Content/UnitList") as VBoxContainer

	helper.assert_true(top_bar != null, "TopBar exists (%s)" % size_label)
	helper.assert_true(scroll != null, "Scroll exists (%s)" % size_label)
	helper.assert_true(content != null, "Content exists (%s)" % size_label)
	helper.assert_true(modifiers != null, "Modifiers label exists (%s)" % size_label)
	helper.assert_true(kingdom_header != null, "Kingdom header exists (%s)" % size_label)
	helper.assert_true(kingdom_list != null, "Kingdom list exists (%s)" % size_label)
	helper.assert_true(unit_header != null, "Unit header exists (%s)" % size_label)
	helper.assert_true(unit_list != null, "Unit list exists (%s)" % size_label)

	if top_bar != null and scroll != null:
		var top_bar_height = max(top_bar.custom_minimum_size.y, top_bar.get_combined_minimum_size().y)
		var top_bar_bottom = top_bar.offset_top + top_bar_height
		var scroll_top = scroll.anchor_top * viewport_size.y + scroll.offset_top
		var scroll_bottom = scroll.anchor_bottom * viewport_size.y + scroll.offset_bottom
		var gap = scroll_top - top_bar_bottom
		var bottom_margin = viewport_size.y - scroll_bottom
		helper.assert_true(gap >= MIN_GAP_TOPBAR_SCROLL, "Gap TopBar->Scroll >= %.1f (%s)" % [MIN_GAP_TOPBAR_SCROLL, size_label])
		helper.assert_true(bottom_margin >= MIN_BOTTOM_MARGIN, "Scroll bottom margin >= %.1f (%s)" % [MIN_BOTTOM_MARGIN, size_label])
		var scroll_height = scroll_bottom - scroll_top
		helper.assert_true(scroll_height > 0.0, "Scroll height positive (%s)" % size_label)

	if content != null:
		helper.assert_true(content.get_child_count() >= 5, "Kingdom content sections present (%s)" % size_label)

	if modifiers != null:
		helper.assert_true(modifiers.text.strip_edges() != "", "Modifiers text present (%s)" % size_label)
	if kingdom_header != null:
		helper.assert_true(kingdom_header.text.strip_edges() != "", "Kingdom header text present (%s)" % size_label)
	if unit_header != null:
		helper.assert_true(unit_header.text.strip_edges() != "", "Unit header text present (%s)" % size_label)
