extends "res://scripts/tests/e2e/e2e_section.gd"
## E2E tests for MainMenu navigation and buttons.

const SCENE_PATH := "res://scenes/MainMenu.tscn"


func get_section_name() -> String:
	return "menu"


func _run_tests() -> void:
	_test_menu_loads()
	_test_button_existence()
	_test_title_content()
	_test_button_visibility()
	_test_layout_structure()


func _test_menu_loads() -> void:
	var menu = _instantiate_scene(SCENE_PATH)
	_helper.assert_true(menu != null, "MainMenu scene loads")
	if menu == null:
		return

	_helper.assert_true(menu is Control, "MainMenu is Control")
	_add_event("MainMenu instantiated")
	_cleanup(menu)


func _test_button_existence() -> void:
	var menu = _instantiate_scene(SCENE_PATH)
	if menu == null:
		return

	_add_to_root(menu)

	var start_btn = _get_node_safe(menu, "Center/MenuPanel/VBox/StartButton")
	var kingdom_btn = _get_node_safe(menu, "Center/MenuPanel/VBox/KingdomButton")
	var quit_btn = _get_node_safe(menu, "Center/MenuPanel/VBox/QuitButton")

	_helper.assert_true(start_btn != null, "Start button exists")
	_helper.assert_true(kingdom_btn != null, "Kingdom button exists")
	_helper.assert_true(quit_btn != null, "Quit button exists")

	_add_event("Menu buttons validated")
	_cleanup(menu)


func _test_title_content() -> void:
	var menu = _instantiate_scene(SCENE_PATH)
	if menu == null:
		return

	_add_to_root(menu)

	var title = _get_node_safe(menu, "Center/MenuPanel/VBox/TitleLabel") as Label
	var subtitle = _get_node_safe(menu, "Center/MenuPanel/VBox/SubtitleLabel") as Label

	_helper.assert_true(title != null, "Title label exists")
	_helper.assert_true(subtitle != null, "Subtitle label exists")

	if title:
		_helper.assert_true(title.text.strip_edges() != "", "Title has text")
	if subtitle:
		_helper.assert_true(subtitle.text.strip_edges() != "", "Subtitle has text")

	_cleanup(menu)


func _test_button_visibility() -> void:
	var menu = _instantiate_scene(SCENE_PATH)
	if menu == null:
		return

	_add_to_root(menu)

	var start_btn = _get_node_safe(menu, "Center/MenuPanel/VBox/StartButton") as Button
	var kingdom_btn = _get_node_safe(menu, "Center/MenuPanel/VBox/KingdomButton") as Button
	var quit_btn = _get_node_safe(menu, "Center/MenuPanel/VBox/QuitButton") as Button

	if start_btn:
		_helper.assert_true(start_btn.visible, "Start button visible")
		_helper.assert_true(not start_btn.disabled, "Start button enabled")
		_helper.assert_true(start_btn.text.strip_edges() != "", "Start button has text")

	if kingdom_btn:
		_helper.assert_true(kingdom_btn.visible, "Kingdom button visible")
		_helper.assert_true(kingdom_btn.text.strip_edges() != "", "Kingdom button has text")

	if quit_btn:
		_helper.assert_true(quit_btn.visible, "Quit button visible")
		_helper.assert_true(quit_btn.text.strip_edges() != "", "Quit button has text")

	_add_event("Button visibility validated")
	_cleanup(menu)


func _test_layout_structure() -> void:
	var menu = _instantiate_scene(SCENE_PATH)
	if menu == null:
		return

	_add_to_root(menu)

	var background = _get_node_safe(menu, "Background") as ColorRect
	var center = _get_node_safe(menu, "Center") as CenterContainer
	var vbox = _get_node_safe(menu, "Center/MenuPanel/VBox") as VBoxContainer

	_helper.assert_true(background != null, "Background exists")
	_helper.assert_true(center != null, "Center container exists")
	_helper.assert_true(vbox != null, "VBox container exists")

	if vbox:
		_helper.assert_true(vbox.get_child_count() >= 5, "Menu has expected buttons")

	_cleanup(menu)
