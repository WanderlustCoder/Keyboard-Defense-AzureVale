class_name RecipesPanel
extends PanelContainer
## Recipes Panel - Shows crafting recipes and allows crafting

signal closed
signal craft_requested(recipe_id: String)

const ThemeColors = preload("res://ui/theme_colors.gd")
const SimCrafting = preload("res://sim/crafting.gd")
const TypingProfile = preload("res://game/typing_profile.gd")

var _profile: Dictionary = {}
var _gold: int = 0
var _player_level: int = 1
var _current_category: String = ""

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null
var _category_tabs: HBoxContainer = null
var _gold_label: Label = null

# Category buttons
var _tab_buttons: Dictionary = {}

# Category colors
const CATEGORY_COLORS: Dictionary = {
	"all": Color(0.7, 0.7, 0.7),
	"consumable": Color(0.4, 0.9, 0.4),
	"equipment": Color(0.4, 0.7, 1.0),
	"material": Color(1.0, 0.8, 0.4)
}


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(560, 500)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.09, 0.12, 0.98)
	style.border_color = ThemeColors.BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(12)
	add_theme_stylebox_override("panel", style)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 10)
	add_child(main_vbox)

	# Header
	var header := HBoxContainer.new()
	main_vbox.add_child(header)

	var title := Label.new()
	title.text = "CRAFTING RECIPES"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", ThemeColors.ACCENT)
	header.add_child(title)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)

	_gold_label = Label.new()
	_gold_label.add_theme_font_size_override("font_size", 14)
	_gold_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
	header.add_child(_gold_label)

	var spacer2 := Control.new()
	spacer2.custom_minimum_size = Vector2(15, 0)
	header.add_child(spacer2)

	_close_btn = Button.new()
	_close_btn.text = "X"
	_close_btn.custom_minimum_size = Vector2(30, 30)
	_close_btn.pressed.connect(_on_close_pressed)
	header.add_child(_close_btn)

	# Category tabs
	_category_tabs = HBoxContainer.new()
	_category_tabs.add_theme_constant_override("separation", 5)
	main_vbox.add_child(_category_tabs)

	var categories: Array[Dictionary] = [
		{"id": "all", "label": "All"},
		{"id": "consumable", "label": "Consumables"},
		{"id": "equipment", "label": "Equipment"},
		{"id": "material", "label": "Materials"}
	]

	for cat in categories:
		var btn := Button.new()
		btn.text = str(cat.get("label", ""))
		btn.toggle_mode = true
		btn.custom_minimum_size = Vector2(100, 28)
		btn.pressed.connect(_on_category_selected.bind(str(cat.get("id", ""))))
		_category_tabs.add_child(btn)
		_tab_buttons[str(cat.get("id", ""))] = btn

	# Content scroll
	_content_scroll = ScrollContainer.new()
	_content_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_vbox.add_child(_content_scroll)

	_content_vbox = VBoxContainer.new()
	_content_vbox.add_theme_constant_override("separation", 10)
	_content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_scroll.add_child(_content_vbox)

	# Footer hint
	var footer := Label.new()
	footer.text = "Click 'Craft' to create items (requires materials + gold)"
	footer.add_theme_font_size_override("font_size", 11)
	footer.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func show_recipes(profile: Dictionary, gold: int, category: String = "") -> void:
	_profile = profile
	_gold = gold
	_player_level = int(TypingProfile.get_profile_value(profile, "player_level", 1))
	_current_category = category if not category.is_empty() else "all"
	_gold_label.text = "%d gold" % gold
	_update_tabs()
	_build_content()
	show()


func update_gold(gold: int) -> void:
	_gold = gold
	_gold_label.text = "%d gold" % gold
	_build_content()


func _update_tabs() -> void:
	for cat_id in _tab_buttons.keys():
		var btn: Button = _tab_buttons[cat_id]
		btn.button_pressed = cat_id == _current_category


func _on_category_selected(category_id: String) -> void:
	_current_category = category_id
	_update_tabs()
	_build_content()


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_content() -> void:
	_clear_content()

	var unlocked: Array[String] = SimCrafting.get_unlocked_recipes(_profile)

	if unlocked.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No recipes unlocked yet. Level up to unlock more!"
		empty_label.add_theme_font_size_override("font_size", 12)
		empty_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		_content_vbox.add_child(empty_label)
		return

	# Filter by category
	var filtered: Array[String] = []
	for recipe_id in unlocked:
		if _current_category == "all":
			filtered.append(recipe_id)
		else:
			var recipe: Dictionary = SimCrafting.RECIPES.get(recipe_id, {})
			if str(recipe.get("category", "")) == _current_category:
				filtered.append(recipe_id)

	if filtered.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No recipes in this category."
		empty_label.add_theme_font_size_override("font_size", 12)
		empty_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		_content_vbox.add_child(empty_label)
		return

	# Sort recipes by category then name
	filtered.sort_custom(func(a, b):
		var a_recipe: Dictionary = SimCrafting.RECIPES.get(a, {})
		var b_recipe: Dictionary = SimCrafting.RECIPES.get(b, {})
		var a_cat: String = str(a_recipe.get("category", ""))
		var b_cat: String = str(b_recipe.get("category", ""))
		if a_cat != b_cat:
			return a_cat < b_cat
		return str(a_recipe.get("name", a)) < str(b_recipe.get("name", b))
	)

	# Group by category if showing all
	if _current_category == "all":
		var by_category: Dictionary = {}
		for recipe_id in filtered:
			var recipe: Dictionary = SimCrafting.RECIPES.get(recipe_id, {})
			var cat: String = str(recipe.get("category", "misc"))
			if not by_category.has(cat):
				by_category[cat] = []
			by_category[cat].append(recipe_id)

		for cat in ["consumable", "equipment", "material"]:
			if by_category.has(cat):
				_add_category_section(cat, by_category[cat])
	else:
		for recipe_id in filtered:
			var card := _create_recipe_card(recipe_id)
			_content_vbox.add_child(card)


func _add_category_section(category: String, recipe_ids: Array) -> void:
	var color: Color = CATEGORY_COLORS.get(category, Color.WHITE)

	var header := Label.new()
	header.text = category.to_upper() + "S"
	header.add_theme_font_size_override("font_size", 14)
	header.add_theme_color_override("font_color", color)
	_content_vbox.add_child(header)

	for recipe_id in recipe_ids:
		var card := _create_recipe_card(recipe_id)
		_content_vbox.add_child(card)

	var sep := Control.new()
	sep.custom_minimum_size = Vector2(0, 5)
	_content_vbox.add_child(sep)


func _create_recipe_card(recipe_id: String) -> Control:
	var recipe: Dictionary = SimCrafting.RECIPES.get(recipe_id, {})
	var name: String = str(recipe.get("name", recipe_id))
	var category: String = str(recipe.get("category", "misc"))
	var gold_cost: int = int(recipe.get("gold_cost", 0))
	var ingredients: Array = recipe.get("ingredients", [])
	var output_item: String = str(recipe.get("output_item", ""))
	var output_qty: int = int(recipe.get("output_qty", 1))

	var can_craft_result: Dictionary = SimCrafting.can_craft(_profile, recipe_id, _gold)
	var can_craft: bool = bool(can_craft_result.get("can_craft", false))

	var color: Color = CATEGORY_COLORS.get(category, Color.WHITE)

	var container := PanelContainer.new()

	var container_style := StyleBoxFlat.new()
	if can_craft:
		container_style.bg_color = Color(0.08, 0.1, 0.06, 0.9)
		container_style.border_color = Color(0.4, 0.6, 0.3)
	else:
		container_style.bg_color = Color(0.06, 0.07, 0.1, 0.9)
		container_style.border_color = color.darkened(0.5)
	container_style.set_border_width_all(1)
	container_style.set_corner_radius_all(4)
	container_style.set_content_margin_all(10)
	container.add_theme_stylebox_override("panel", container_style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	container.add_child(vbox)

	# Header row: name, output, gold cost
	var header_hbox := HBoxContainer.new()
	header_hbox.add_theme_constant_override("separation", 10)
	vbox.add_child(header_hbox)

	var name_label := Label.new()
	name_label.text = name
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", color)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(name_label)

	var output_label := Label.new()
	if output_qty > 1:
		output_label.text = "-> %s x%d" % [output_item, output_qty]
	else:
		output_label.text = "-> %s" % output_item
	output_label.add_theme_font_size_override("font_size", 11)
	output_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	header_hbox.add_child(output_label)

	var gold_label := Label.new()
	gold_label.text = "%dg" % gold_cost
	var gold_color: Color = Color(1.0, 0.84, 0.0) if _gold >= gold_cost else Color(0.6, 0.4, 0.4)
	gold_label.add_theme_font_size_override("font_size", 12)
	gold_label.add_theme_color_override("font_color", gold_color)
	header_hbox.add_child(gold_label)

	# Ingredients row
	var ing_hbox := HBoxContainer.new()
	ing_hbox.add_theme_constant_override("separation", 15)
	vbox.add_child(ing_hbox)

	var ing_label := Label.new()
	ing_label.text = "Needs:"
	ing_label.add_theme_font_size_override("font_size", 10)
	ing_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	ing_hbox.add_child(ing_label)

	var materials: Dictionary = SimCrafting.get_materials(_profile)

	for ingredient in ingredients:
		var item_id: String = str(ingredient.get("item", ""))
		var qty_needed: int = int(ingredient.get("qty", 1))
		var qty_have: int = int(materials.get(item_id, 0))
		var mat_info: Dictionary = SimCrafting.MATERIALS.get(item_id, {})
		var mat_name: String = str(mat_info.get("name", item_id))

		var ing_chip := _create_ingredient_chip(mat_name, qty_have, qty_needed)
		ing_hbox.add_child(ing_chip)

	# Craft button
	var btn_hbox := HBoxContainer.new()
	vbox.add_child(btn_hbox)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_hbox.add_child(spacer)

	if not can_craft:
		var reason_label := Label.new()
		reason_label.text = str(can_craft_result.get("reason", ""))
		reason_label.add_theme_font_size_override("font_size", 10)
		reason_label.add_theme_color_override("font_color", Color(0.6, 0.4, 0.4))
		btn_hbox.add_child(reason_label)

		var spacer2 := Control.new()
		spacer2.custom_minimum_size = Vector2(10, 0)
		btn_hbox.add_child(spacer2)

	var craft_btn := Button.new()
	craft_btn.text = "Craft"
	craft_btn.custom_minimum_size = Vector2(70, 26)
	craft_btn.disabled = not can_craft
	craft_btn.pressed.connect(_on_craft_pressed.bind(recipe_id))
	btn_hbox.add_child(craft_btn)

	return container


func _create_ingredient_chip(mat_name: String, qty_have: int, qty_needed: int) -> Control:
	var is_satisfied: bool = qty_have >= qty_needed

	var container := PanelContainer.new()

	var chip_style := StyleBoxFlat.new()
	if is_satisfied:
		chip_style.bg_color = Color(0.1, 0.15, 0.1, 0.8)
	else:
		chip_style.bg_color = Color(0.15, 0.08, 0.08, 0.8)
	chip_style.set_corner_radius_all(3)
	chip_style.set_content_margin_all(4)
	container.add_theme_stylebox_override("panel", chip_style)

	var label := Label.new()
	label.text = "%s: %d/%d" % [mat_name, qty_have, qty_needed]
	label.add_theme_font_size_override("font_size", 10)
	if is_satisfied:
		label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
	else:
		label.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4))
	container.add_child(label)

	return container


func _on_craft_pressed(recipe_id: String) -> void:
	craft_requested.emit(recipe_id)


func _on_close_pressed() -> void:
	hide()
	closed.emit()


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
		get_viewport().set_input_as_handled()
