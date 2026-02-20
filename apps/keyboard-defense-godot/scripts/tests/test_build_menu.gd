extends RefCounted
## Tests for BuildMenu and AoE-style building placement feature

const TestHelper = preload("res://scripts/tests/test_helper.gd")
const BuildMenu = preload("res://ui/build_menu.gd")

func run_with_tree(tree: SceneTree) -> Dictionary:
	var helper = TestHelper.new()

	# Test 1: BuildMenu script loads
	_test_build_menu_script_loads(helper)

	# Test 2: Buildings data loads correctly
	_test_buildings_data_loads(helper)

	# Test 3: BuildMenu creates buttons for each building
	_test_build_menu_creates_buttons(helper, tree)

	# Test 4: BuildMenu emits building_selected signal
	_test_build_menu_signal_emission(helper, tree)

	# Test 5: KingdomDefense scene has BuildSection node
	_test_kingdom_defense_has_build_section(helper, tree)

	# Test 6: KingdomDefense connects to build menu signal
	_test_kingdom_defense_signal_connection(helper, tree)

	# Test 7: Placement mode activates correctly
	_test_placement_mode_activation(helper, tree)

	# Test 8: Placement mode cancellation
	_test_placement_mode_cancellation(helper, tree)

	return helper.summary()


func _test_build_menu_script_loads(helper: TestHelper) -> void:
	var script = load("res://ui/build_menu.gd")
	helper.assert_true(script != null, "BuildMenu script loads")


func _test_buildings_data_loads(helper: TestHelper) -> void:
	var path = "res://data/buildings.json"
	helper.assert_true(FileAccess.file_exists(path), "buildings.json exists")

	if not FileAccess.file_exists(path):
		return

	var file = FileAccess.open(path, FileAccess.READ)
	helper.assert_true(file != null, "buildings.json opens")
	if file == null:
		return

	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	file.close()
	helper.assert_true(error == OK, "buildings.json parses without error")

	if error != OK:
		return

	var data: Dictionary = json.data
	helper.assert_true(data.has("buildings"), "buildings.json has 'buildings' key")

	var buildings: Dictionary = data.get("buildings", {})
	helper.assert_true(buildings.size() > 0, "buildings.json has at least one building")

	# Check that essential buildings exist
	helper.assert_true(buildings.has("farm"), "buildings.json has 'farm'")
	helper.assert_true(buildings.has("tower"), "buildings.json has 'tower'")
	helper.assert_true(buildings.has("wall"), "buildings.json has 'wall'")


func _test_build_menu_creates_buttons(helper: TestHelper, tree: SceneTree) -> void:
	# Create a minimal scene structure for BuildMenu
	var build_menu = _create_build_menu_with_children()
	tree.root.add_child(build_menu)

	# Wait for _ready to complete
	await tree.process_frame
	await tree.process_frame

	# Check that buttons were created
	var grid = build_menu.get_node_or_null("ScrollContainer/Grid")
	helper.assert_true(grid != null, "BuildMenu has Grid node")

	if grid:
		helper.assert_true(grid.get_child_count() > 0, "BuildMenu Grid has children (buttons)")
		helper.assert_true(build_menu.building_buttons.size() > 0, "BuildMenu building_buttons dictionary populated")

	# Cleanup
	tree.root.remove_child(build_menu)
	build_menu.queue_free()


func _test_build_menu_signal_emission(helper: TestHelper, tree: SceneTree) -> void:
	var build_menu = _create_build_menu_with_children()
	tree.root.add_child(build_menu)

	await tree.process_frame
	await tree.process_frame

	# Track signal emission
	var signal_received = {"building_id": ""}
	build_menu.building_selected.connect(func(id): signal_received["building_id"] = id)

	# Simulate button press for first building
	if build_menu.building_buttons.size() > 0:
		var first_building_id = build_menu.building_buttons.keys()[0]
		var button = build_menu.building_buttons[first_building_id]
		button.emit_signal("pressed")

		helper.assert_true(signal_received["building_id"] == first_building_id,
			"building_selected signal emitted with correct building_id")
	else:
		helper.assert_true(false, "No building buttons to test signal emission")

	# Cleanup
	tree.root.remove_child(build_menu)
	build_menu.queue_free()


func _test_kingdom_defense_has_build_section(helper: TestHelper, tree: SceneTree) -> void:
	var packed = load("res://scenes/KingdomDefense.tscn")
	helper.assert_true(packed != null, "KingdomDefense.tscn loads")

	if packed == null:
		return

	var instance = packed.instantiate()
	tree.root.add_child(instance)

	await tree.process_frame

	# Check for BuildSection node
	var build_section = instance.get_node_or_null("MainLayout/GameArea/RightSidebar/SidebarContent/BuildSection")
	helper.assert_true(build_section != null, "KingdomDefense has BuildSection node")

	if build_section:
		# Check that it has the BuildMenu script
		helper.assert_true(build_section.get_script() != null, "BuildSection has a script attached")

		# Check for required child nodes
		var scroll = build_section.get_node_or_null("ScrollContainer")
		var grid = build_section.get_node_or_null("ScrollContainer/Grid")
		var tooltip = build_section.get_node_or_null("TooltipPanel")

		helper.assert_true(scroll != null, "BuildSection has ScrollContainer")
		helper.assert_true(grid != null, "BuildSection has Grid")
		helper.assert_true(tooltip != null, "BuildSection has TooltipPanel")

	# Cleanup
	tree.root.remove_child(instance)
	instance.queue_free()


func _test_kingdom_defense_signal_connection(helper: TestHelper, tree: SceneTree) -> void:
	var packed = load("res://scenes/KingdomDefense.tscn")
	if packed == null:
		helper.assert_true(false, "KingdomDefense.tscn loads for signal test")
		return

	var instance = packed.instantiate()
	tree.root.add_child(instance)

	# Wait for _ready to complete
	await tree.process_frame
	await tree.process_frame
	await tree.process_frame

	# Check that build_menu reference exists
	var has_build_menu_ref = instance.get("build_menu") != null
	helper.assert_true(has_build_menu_ref, "KingdomDefense has build_menu reference")

	# Check that placement_building variable exists
	var has_placement_var = "placement_building" in instance
	helper.assert_true(has_placement_var, "KingdomDefense has placement_building variable")

	# Cleanup
	tree.root.remove_child(instance)
	instance.queue_free()


func _test_placement_mode_activation(helper: TestHelper, tree: SceneTree) -> void:
	var packed = load("res://scenes/KingdomDefense.tscn")
	if packed == null:
		helper.assert_true(false, "KingdomDefense.tscn loads for placement test")
		return

	var instance = packed.instantiate()
	tree.root.add_child(instance)

	# Wait for initialization
	await tree.process_frame
	await tree.process_frame
	await tree.process_frame

	var build_menu = instance.get("build_menu")
	if build_menu == null:
		helper.assert_true(false, "build_menu reference exists for placement test")
		tree.root.remove_child(instance)
		instance.queue_free()
		return

	# Initial state: no building selected
	var initial_placement = instance.get("placement_building")
	helper.assert_eq(initial_placement, "", "Initial placement_building is empty")

	# Simulate selecting a building
	if build_menu.building_buttons.size() > 0:
		var first_building_id = build_menu.building_buttons.keys()[0]

		# Call the handler directly (simulating signal)
		if instance.has_method("_on_building_selected_for_placement"):
			instance._on_building_selected_for_placement(first_building_id)

			var after_placement = instance.get("placement_building")
			helper.assert_eq(after_placement, first_building_id, "placement_building set after selection")

			# Check grid_renderer preview
			var grid_renderer = instance.get("grid_renderer")
			if grid_renderer and "preview_type" in grid_renderer:
				helper.assert_eq(grid_renderer.preview_type, first_building_id, "grid_renderer preview_type set")
		else:
			helper.assert_true(false, "KingdomDefense has _on_building_selected_for_placement method")
	else:
		helper.assert_true(false, "BuildMenu has buttons for placement test")

	# Cleanup
	tree.root.remove_child(instance)
	instance.queue_free()


func _test_placement_mode_cancellation(helper: TestHelper, tree: SceneTree) -> void:
	var packed = load("res://scenes/KingdomDefense.tscn")
	if packed == null:
		helper.assert_true(false, "KingdomDefense.tscn loads for cancellation test")
		return

	var instance = packed.instantiate()
	tree.root.add_child(instance)

	# Wait for initialization
	await tree.process_frame
	await tree.process_frame
	await tree.process_frame

	# Set placement mode
	instance.set("placement_building", "tower")

	# Call cancel method
	if instance.has_method("_cancel_building_placement"):
		instance._cancel_building_placement()

		var after_cancel = instance.get("placement_building")
		helper.assert_eq(after_cancel, "", "placement_building cleared after cancel")

		# Check grid_renderer preview cleared
		var grid_renderer = instance.get("grid_renderer")
		if grid_renderer and "preview_type" in grid_renderer:
			helper.assert_eq(grid_renderer.preview_type, "", "grid_renderer preview_type cleared after cancel")
	else:
		helper.assert_true(false, "KingdomDefense has _cancel_building_placement method")

	# Cleanup
	tree.root.remove_child(instance)
	instance.queue_free()


## Helper to create a BuildMenu with required child nodes
func _create_build_menu_with_children() -> Control:
	var build_menu = Control.new()
	build_menu.set_script(load("res://ui/build_menu.gd"))

	# Create required child structure
	var scroll = ScrollContainer.new()
	scroll.name = "ScrollContainer"
	build_menu.add_child(scroll)

	var grid = GridContainer.new()
	grid.name = "Grid"
	scroll.add_child(grid)

	var tooltip = Panel.new()
	tooltip.name = "TooltipPanel"
	tooltip.visible = false
	build_menu.add_child(tooltip)

	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	tooltip.add_child(vbox)

	var name_label = Label.new()
	name_label.name = "NameLabel"
	vbox.add_child(name_label)

	var desc_label = Label.new()
	desc_label.name = "DescLabel"
	vbox.add_child(desc_label)

	var cost_label = Label.new()
	cost_label.name = "CostLabel"
	vbox.add_child(cost_label)

	return build_menu
