extends RefCounted

const TestHelper = preload("res://scripts/tests/test_helper.gd")
const EXTRA_SCALE := 1.5
const MAX_WIDTH_RATIO := 0.9

func run_with_tree(tree: SceneTree) -> Dictionary:
	var helper = TestHelper.new()
	var packed = load("res://scenes/MainMenu.tscn")
	helper.assert_true(packed != null, "scene loads: main menu")
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
	helper.assert_true(instance is Control, "main menu root is Control (%s)" % size_label)
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

func _assert_layout(helper: TestHelper, menu: Control, viewport_size: Vector2, size_label: String) -> void:
	var background := menu.get_node("Background") as ColorRect
	var center := menu.get_node("Center") as CenterContainer
	var vbox := menu.get_node("Center/VBox") as VBoxContainer
	var title := menu.get_node("Center/VBox/TitleLabel") as Label
	var subtitle := menu.get_node("Center/VBox/SubtitleLabel") as Label
	var start_button := menu.get_node("Center/VBox/StartButton") as Button
	var kingdom_button := menu.get_node("Center/VBox/KingdomButton") as Button
	var quit_button := menu.get_node("Center/VBox/QuitButton") as Button

	helper.assert_true(background != null, "Background exists (%s)" % size_label)
	helper.assert_true(center != null, "Center container exists (%s)" % size_label)
	helper.assert_true(vbox != null, "VBox exists (%s)" % size_label)
	helper.assert_true(title != null, "Title label exists (%s)" % size_label)
	helper.assert_true(subtitle != null, "Subtitle label exists (%s)" % size_label)
	helper.assert_true(start_button != null, "Start button exists (%s)" % size_label)
	helper.assert_true(kingdom_button != null, "Kingdom button exists (%s)" % size_label)
	helper.assert_true(quit_button != null, "Quit button exists (%s)" % size_label)

	if background != null:
		helper.assert_eq(background.anchor_left, 0.0, "Background anchored left (%s)" % size_label)
		helper.assert_eq(background.anchor_top, 0.0, "Background anchored top (%s)" % size_label)
		helper.assert_eq(background.anchor_right, 1.0, "Background anchored right (%s)" % size_label)
		helper.assert_eq(background.anchor_bottom, 1.0, "Background anchored bottom (%s)" % size_label)
	if center != null:
		helper.assert_eq(center.anchor_left, 0.0, "Center anchored left (%s)" % size_label)
		helper.assert_eq(center.anchor_top, 0.0, "Center anchored top (%s)" % size_label)
		helper.assert_eq(center.anchor_right, 1.0, "Center anchored right (%s)" % size_label)
		helper.assert_eq(center.anchor_bottom, 1.0, "Center anchored bottom (%s)" % size_label)
	if vbox != null:
		helper.assert_true(vbox.get_child_count() >= 5, "Menu has expected options (%s)" % size_label)
		helper.assert_true(vbox.custom_minimum_size.x > 0.0, "Menu width defined (%s)" % size_label)
		var max_width = viewport_size.x * MAX_WIDTH_RATIO
		helper.assert_true(vbox.custom_minimum_size.x <= max_width, "Menu width fits viewport (%s)" % size_label)
		helper.assert_eq(int(vbox.alignment), BoxContainer.ALIGNMENT_CENTER, "Menu centered (%s)" % size_label)

	if title != null:
		helper.assert_true(title.text.strip_edges() != "", "Title text present (%s)" % size_label)
	if subtitle != null:
		helper.assert_true(subtitle.text.strip_edges() != "", "Subtitle text present (%s)" % size_label)
	if start_button != null:
		helper.assert_true(start_button.text.strip_edges() != "", "Start button text present (%s)" % size_label)
	if kingdom_button != null:
		helper.assert_true(kingdom_button.text.strip_edges() != "", "Kingdom button text present (%s)" % size_label)
	if quit_button != null:
		helper.assert_true(quit_button.text.strip_edges() != "", "Quit button text present (%s)" % size_label)
