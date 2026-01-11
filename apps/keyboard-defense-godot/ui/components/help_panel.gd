class_name HelpPanel
extends PanelContainer
## Help Panel - Shows game commands organized by category

signal closed

const ThemeColors = preload("res://ui/theme_colors.gd")

enum Tab { BUILDING, INFO, ITEMS, ECONOMY, CHARACTER, QUESTS, MODES, COLLECTIONS, REFERENCE }

var _current_tab: Tab = Tab.BUILDING

# UI elements
var _close_btn: Button = null
var _tab_scroll: ScrollContainer = null
var _tab_container: VBoxContainer = null
var _tab_buttons: Array[Button] = []
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Command data organized by category
const COMMAND_CATEGORIES: Dictionary = {
	"Building": {
		"color": Color(0.4, 0.8, 1.0),
		"commands": [
			{"cmd": "build <type>", "desc": "Build structure at cursor (tower, wall, farm, lumber, quarry, market, barracks, temple, workshop)"},
			{"cmd": "tower/wall/farm", "desc": "Quick build shortcuts"},
			{"cmd": "sentry", "desc": "Build auto-attack sentry tower"},
			{"cmd": "spark", "desc": "Build spark tower (faster, less damage)"},
			{"cmd": "flame", "desc": "Build flame tower (AoE fire damage)"},
			{"cmd": "upgrade", "desc": "Upgrade structure at cursor position"},
			{"cmd": "destroy", "desc": "Destroy structure at cursor (partial refund)"}
		]
	},
	"Information": {
		"color": Color(0.6, 0.8, 1.0),
		"commands": [
			{"cmd": "help / ?", "desc": "Show this help panel"},
			{"cmd": "skills", "desc": "View and upgrade skill trees"},
			{"cmd": "effects", "desc": "View status effects information"},
			{"cmd": "auto", "desc": "View auto-defense tower status"},
			{"cmd": "spells", "desc": "View special typing commands"},
			{"cmd": "wave", "desc": "View current wave theme and modifiers"},
			{"cmd": "difficulty / diff", "desc": "View or change difficulty mode"}
		]
	},
	"Items & Equipment": {
		"color": Color(0.4, 1.0, 0.6),
		"commands": [
			{"cmd": "inventory / inv / items", "desc": "View your inventory"},
			{"cmd": "equipment / gear", "desc": "View equipped items and stats"},
			{"cmd": "equip <item_id>", "desc": "Equip an item from inventory"},
			{"cmd": "unequip <slot>", "desc": "Unequip item from slot"},
			{"cmd": "use <item_id>", "desc": "Use a consumable item"}
		]
	},
	"Economy": {
		"color": Color(1.0, 0.84, 0.0),
		"commands": [
			{"cmd": "shop / store", "desc": "Open the item shop"},
			{"cmd": "buy <item_id>", "desc": "Purchase an item from shop"},
			{"cmd": "mats / materials", "desc": "View crafting materials"},
			{"cmd": "recipes", "desc": "View available crafting recipes"},
			{"cmd": "recipe <id>", "desc": "View recipe details"},
			{"cmd": "craft <id>", "desc": "Craft an item from materials"}
		]
	},
	"Character": {
		"color": Color(0.8, 0.6, 1.0),
		"commands": [
			{"cmd": "skills", "desc": "Open skill tree panel"},
			{"cmd": "learn <tree:skill>", "desc": "Learn a skill (e.g., learn speed:swift_start)"},
			{"cmd": "stats", "desc": "View player statistics summary"},
			{"cmd": "stats full", "desc": "View detailed statistics"},
			{"cmd": "records", "desc": "View personal best records"}
		]
	},
	"Quests": {
		"color": Color(0.4, 0.8, 1.0),
		"commands": [
			{"cmd": "quests / missions / q", "desc": "View active daily and weekly quests"},
			{"cmd": "claim <quest_id>", "desc": "Claim completed quest rewards"}
		]
	},
	"Game Modes": {
		"color": Color(1.0, 0.6, 0.4),
		"commands": [
			{"cmd": "ready", "desc": "Start the defense phase (during planning)"},
			{"cmd": "endless", "desc": "View endless mode status and high scores"},
			{"cmd": "startendless", "desc": "Start an endless mode run"},
			{"cmd": "daily", "desc": "View today's daily challenge"},
			{"cmd": "startdaily", "desc": "Start the daily challenge"},
			{"cmd": "tokens / tokenshop", "desc": "View challenge token shop"}
		]
	},
	"Collections": {
		"color": Color(0.6, 0.6, 0.8),
		"commands": [
			{"cmd": "bestiary / enemies", "desc": "View enemy catalog with stats"},
			{"cmd": "achievements / ach", "desc": "View achievements and progress"},
			{"cmd": "lore / story", "desc": "Read game lore and world history"}
		]
	},
	"Reference": {
		"color": Color(0.5, 0.8, 0.6),
		"commands": [
			{"cmd": "towerref / towers", "desc": "Tower types, tiers, and special attacks"},
			{"cmd": "enemyref / monsters", "desc": "Enemy types, behaviors, and affixes"},
			{"cmd": "expeditionref / journeys", "desc": "Expedition phases, risks, and rewards"},
			{"cmd": "challengeref / daily", "desc": "Daily challenges, streaks, and token shop"},
			{"cmd": "milestoneref / achievements", "desc": "Progression milestones across categories"},
			{"cmd": "loginref / login", "desc": "Login streak rewards and bonuses"},
			{"cmd": "lootref / drops", "desc": "Loot quality tiers and drop mechanics"},
			{"cmd": "questref / missions", "desc": "Quest types, objectives, and rewards"},
			{"cmd": "noderef / harvest", "desc": "Resource node types and harvesting"},
			{"cmd": "statsref / records", "desc": "Player statistics and personal records"},
			{"cmd": "waveref / themes", "desc": "Wave themes, modifiers, and events"}
		]
	}
}


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(620, 520)

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
	title.text = "HELP - COMMANDS"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", ThemeColors.ACCENT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	_close_btn = Button.new()
	_close_btn.text = "X"
	_close_btn.custom_minimum_size = Vector2(30, 30)
	_close_btn.pressed.connect(_on_close_pressed)
	header.add_child(_close_btn)

	# Content area (tabs on left, commands on right)
	var content_hbox := HBoxContainer.new()
	content_hbox.add_theme_constant_override("separation", 10)
	content_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(content_hbox)

	# Left: Category tabs
	_tab_scroll = ScrollContainer.new()
	_tab_scroll.custom_minimum_size = Vector2(140, 0)
	_tab_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content_hbox.add_child(_tab_scroll)

	_tab_container = VBoxContainer.new()
	_tab_container.add_theme_constant_override("separation", 4)
	_tab_scroll.add_child(_tab_container)

	# Build category tabs
	var categories: Array = COMMAND_CATEGORIES.keys()
	for i in range(categories.size()):
		var category: String = categories[i]
		var cat_data: Dictionary = COMMAND_CATEGORIES[category]
		var color: Color = cat_data.get("color", Color.WHITE)

		var btn := Button.new()
		btn.text = category
		btn.custom_minimum_size = Vector2(130, 32)
		btn.pressed.connect(_on_category_selected.bind(i))
		btn.add_theme_color_override("font_color", color)
		_tab_container.add_child(btn)
		_tab_buttons.append(btn)

	# Right: Commands content
	_content_scroll = ScrollContainer.new()
	_content_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content_hbox.add_child(_content_scroll)

	_content_vbox = VBoxContainer.new()
	_content_vbox.add_theme_constant_override("separation", 8)
	_content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_scroll.add_child(_content_vbox)

	# Footer hint
	var footer := Label.new()
	footer.text = "During waves: Type enemy words OR special spell commands!"
	footer.add_theme_font_size_override("font_size", 11)
	footer.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)

	_update_tab_buttons()
	_build_commands_list()


func show_help() -> void:
	_current_tab = Tab.BUILDING
	_update_tab_buttons()
	_build_commands_list()
	show()


func _update_tab_buttons() -> void:
	for i in range(_tab_buttons.size()):
		var btn: Button = _tab_buttons[i]
		if i == _current_tab:
			var style := StyleBoxFlat.new()
			style.bg_color = Color(0.15, 0.18, 0.25)
			style.set_corner_radius_all(4)
			btn.add_theme_stylebox_override("normal", style)
		else:
			btn.remove_theme_stylebox_override("normal")


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_commands_list() -> void:
	_clear_content()

	var categories: Array = COMMAND_CATEGORIES.keys()
	if _current_tab >= categories.size():
		return

	var category_name: String = categories[_current_tab]
	var cat_data: Dictionary = COMMAND_CATEGORIES[category_name]
	var color: Color = cat_data.get("color", Color.WHITE)
	var commands: Array = cat_data.get("commands", [])

	# Category header
	var header := Label.new()
	header.text = category_name.to_upper()
	header.add_theme_font_size_override("font_size", 16)
	header.add_theme_color_override("font_color", color)
	_content_vbox.add_child(header)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 5)
	_content_vbox.add_child(spacer)

	# Commands
	for cmd_data in commands:
		var widget := _create_command_widget(cmd_data, color)
		_content_vbox.add_child(widget)


func _create_command_widget(cmd_data: Dictionary, accent_color: Color) -> Control:
	var cmd: String = str(cmd_data.get("cmd", ""))
	var desc: String = str(cmd_data.get("desc", ""))

	var container := PanelContainer.new()

	var container_style := StyleBoxFlat.new()
	container_style.bg_color = Color(0.06, 0.07, 0.1, 0.8)
	container_style.border_color = accent_color.darkened(0.5)
	container_style.set_border_width_all(1)
	container_style.set_corner_radius_all(4)
	container_style.set_content_margin_all(8)
	container.add_theme_stylebox_override("panel", container_style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	container.add_child(vbox)

	var cmd_label := Label.new()
	cmd_label.text = cmd
	cmd_label.add_theme_font_size_override("font_size", 13)
	cmd_label.add_theme_color_override("font_color", accent_color)
	vbox.add_child(cmd_label)

	var desc_label := Label.new()
	desc_label.text = desc
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_label)

	return container


func _on_category_selected(index: int) -> void:
	_current_tab = index as Tab
	_update_tab_buttons()
	_build_commands_list()


func _on_close_pressed() -> void:
	hide()
	closed.emit()


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
		get_viewport().set_input_as_handled()
