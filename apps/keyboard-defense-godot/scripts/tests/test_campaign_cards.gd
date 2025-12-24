extends RefCounted

const TestHelper = preload("res://scripts/tests/test_helper.gd")
const ProgressionStateScript = preload("res://scripts/ProgressionState.gd")

func run_with_tree(tree: SceneTree) -> Dictionary:
	var helper = TestHelper.new()
	var packed = load("res://scenes/CampaignMap.tscn")
	helper.assert_true(packed != null, "scene loads: campaign map")
	if packed == null:
		return helper.summary()
	var instance = packed.instantiate()
	helper.assert_true(instance is Control, "campaign map root is Control")
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
	progression.persistence_enabled = false
	progression._load_static_data()
	_wire_map_nodes(control, progression)
	if control.has_method("_refresh"):
		control.call("_refresh")
	_assert_cards(helper, control, progression)
	root.remove_child(control)
	control.free()
	progression.free()
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

func _wire_map_nodes(map: Control, progression) -> void:
	map.progression = progression
	map.map_grid = map.get_node("MapPanel/MapGrid")
	map.gold_label = map.get_node("TopBar/GoldLabel")
	map.summary_label = map.get_node("SummaryPanel/Content/SummaryLabel")
	map.modifiers_label = map.get_node("SummaryPanel/Content/ModifiersLabel")

func _assert_cards(helper: TestHelper, map: Control, progression) -> void:
	var map_grid := map.get_node("MapPanel/MapGrid") as GridContainer
	helper.assert_true(map_grid != null, "MapGrid exists")
	if map_grid == null:
		return
	var nodes = progression.get_map_nodes()
	var cards: Array = []
	for child in map_grid.get_children():
		if child is Control:
			cards.append(child)
	helper.assert_true(cards.size() == nodes.size(), "Map cards match node count")
	helper.assert_true(cards.size() > 0, "Map cards present")
	if cards.is_empty():
		return

	var unlocked_count = 0
	var locked_count = 0
	for i in range(min(cards.size(), nodes.size())):
		var card := cards[i] as Control
		var node: Dictionary = nodes[i]
		_assert_card_content(helper, card, node, progression)
		if card.mouse_default_cursor_shape == Control.CURSOR_POINTING_HAND:
			unlocked_count += 1
		else:
			locked_count += 1
		var min_size = card.get_combined_minimum_size()
		helper.assert_true(card.custom_minimum_size.x >= 0.0, "Card custom min width set")
		helper.assert_true(card.custom_minimum_size.y >= 0.0, "Card custom min height set")
		helper.assert_true(min_size.x > 0.0 and min_size.y > 0.0, "Card min size positive")

	if nodes.size() > 1:
		helper.assert_true(unlocked_count >= 1, "At least one unlocked card")
		helper.assert_true(locked_count >= 1, "At least one locked card")

func _assert_card_content(helper: TestHelper, card: Control, node: Dictionary, progression) -> void:
	var labels: Array = []
	var panels: Array = []
	for child in card.get_children():
		if child is Panel:
			panels.append(child)
		elif child is Label:
			labels.append(child)
	helper.assert_true(panels.size() >= 1, "Card panel present")
	helper.assert_true(labels.size() >= 2, "Card labels present")
	if labels.is_empty():
		return

	var node_label = str(node.get("label", ""))
	var lesson_id = str(node.get("lesson_id", ""))
	var lesson = progression.get_lesson(lesson_id)
	var lesson_label = str(lesson.get("label", ""))
	var reward_gold = int(node.get("reward_gold", 0))

	var title_ok = false
	var lesson_ok = false
	var reward_ok = reward_gold <= 0
	for label in labels:
		var text = label.text.strip_edges()
		if text == node_label:
			title_ok = true
		if text == "Lesson: %s" % lesson_label:
			lesson_ok = true
		if reward_gold > 0 and text == "Reward: %dg" % reward_gold:
			reward_ok = true

	helper.assert_true(title_ok, "Card title matches node label")
	helper.assert_true(lesson_ok, "Card lesson label matches lesson")
	helper.assert_true(reward_ok, "Card reward label matches reward")
