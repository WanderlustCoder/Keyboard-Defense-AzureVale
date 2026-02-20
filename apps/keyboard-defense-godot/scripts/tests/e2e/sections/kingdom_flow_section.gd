extends "res://scripts/tests/e2e/e2e_section.gd"
## E2E tests for KingdomHub management screen.

const SCENE_PATH := "res://scenes/KingdomHub.tscn"


func get_section_name() -> String:
	return "kingdom"


func _run_tests() -> void:
	_test_scene_loads()
	_test_top_bar()
	_test_upgrade_lists()
	_test_scroll_content()
	_test_layout_structure()


func _test_scene_loads() -> void:
	var hub = _instantiate_scene(SCENE_PATH)
	_helper.assert_true(hub != null, "KingdomHub scene loads")
	if hub:
		_helper.assert_true(hub is Control, "KingdomHub is Control")
		_add_event("Kingdom hub loaded")
		_cleanup(hub)


func _test_top_bar() -> void:
	var hub = _instantiate_scene(SCENE_PATH)
	if hub == null:
		return

	_add_to_root(hub)

	var top_bar = _get_node_safe(hub, "TopBar")
	_helper.assert_true(top_bar != null, "TopBar exists")

	_add_event("TopBar validated")
	_cleanup(hub)


func _test_upgrade_lists() -> void:
	var hub = _instantiate_scene(SCENE_PATH)
	if hub == null:
		return

	_add_to_root(hub)

	var kingdom_list = _get_node_safe(hub, "ContentPanel/Scroll/Content/KingdomList") as VBoxContainer
	var unit_list = _get_node_safe(hub, "ContentPanel/Scroll/Content/UnitList") as VBoxContainer

	_helper.assert_true(kingdom_list != null, "Kingdom upgrades list exists")
	_helper.assert_true(unit_list != null, "Unit upgrades list exists")

	_add_event("Upgrade lists validated")
	_cleanup(hub)


func _test_scroll_content() -> void:
	var hub = _instantiate_scene(SCENE_PATH)
	if hub == null:
		return

	_add_to_root(hub)

	var scroll = _get_node_safe(hub, "ContentPanel/Scroll") as ScrollContainer
	var content = _get_node_safe(hub, "ContentPanel/Scroll/Content") as VBoxContainer

	_helper.assert_true(scroll != null, "Scroll container exists")
	_helper.assert_true(content != null, "Content container exists")

	if content:
		_helper.assert_true(content.get_child_count() >= 5, "Content has expected sections")

	_cleanup(hub)


func _test_layout_structure() -> void:
	var hub = _instantiate_scene(SCENE_PATH)
	if hub == null:
		return

	_add_to_root(hub)

	var modifiers = _get_node_safe(hub, "ContentPanel/Scroll/Content/ModifiersLabel") as Label
	var kingdom_header = _get_node_safe(hub, "ContentPanel/Scroll/Content/KingdomHeader") as Label
	var unit_header = _get_node_safe(hub, "ContentPanel/Scroll/Content/UnitHeader") as Label

	_helper.assert_true(modifiers != null, "Modifiers label exists")
	_helper.assert_true(kingdom_header != null, "Kingdom header exists")
	_helper.assert_true(unit_header != null, "Unit header exists")

	if modifiers:
		_helper.assert_true(modifiers.text.strip_edges() != "", "Modifiers has text")
	if kingdom_header:
		_helper.assert_true(kingdom_header.text.strip_edges() != "", "Kingdom header has text")
	if unit_header:
		_helper.assert_true(unit_header.text.strip_edges() != "", "Unit header has text")

	_add_event("Layout structure validated")
	_cleanup(hub)
