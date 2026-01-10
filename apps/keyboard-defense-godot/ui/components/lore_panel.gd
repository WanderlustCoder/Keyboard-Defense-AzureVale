class_name LorePanel
extends PanelContainer
## Lore Browser Panel - View game lore and backstory

signal close_requested

const ThemeColors = preload("res://ui/theme_colors.gd")
const StoryManager = preload("res://game/story_manager.gd")

var _category_list: ItemList = null
var _lore_display: RichTextLabel = null
var _close_btn: Button = null
var _title_label: Label = null
var _categories: Array[String] = []

func _ready() -> void:
	_build_ui()
	_populate_categories()
	hide()

func _build_ui() -> void:
	custom_minimum_size = Vector2(600, 400)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	# Header
	var header := HBoxContainer.new()
	vbox.add_child(header)

	_title_label = Label.new()
	_title_label.text = "Lore of Keystonia"
	_title_label.add_theme_font_size_override("font_size", 20)
	_title_label.add_theme_color_override("font_color", ThemeColors.GOLD)
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title_label)

	_close_btn = Button.new()
	_close_btn.text = "X"
	_close_btn.pressed.connect(_on_close_pressed)
	header.add_child(_close_btn)

	# Separator
	var sep := HSeparator.new()
	vbox.add_child(sep)

	# Content area - split view
	var content := HBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(content)

	# Category list
	_category_list = ItemList.new()
	_category_list.custom_minimum_size = Vector2(150, 0)
	_category_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_category_list.item_selected.connect(_on_category_selected)
	content.add_child(_category_list)

	# Lore display
	_lore_display = RichTextLabel.new()
	_lore_display.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lore_display.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_lore_display.bbcode_enabled = true
	_lore_display.scroll_active = true
	content.add_child(_lore_display)

	# Hint
	var hint := Label.new()
	hint.text = "Select a category to view lore. Press ESC or type 'close' to exit."
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", ThemeColors.MUTED_TEXT)
	vbox.add_child(hint)

func _populate_categories() -> void:
	_categories.clear()
	_category_list.clear()

	var lore: Dictionary = StoryManager.get_all_lore()
	if lore.is_empty():
		return

	# Add main lore categories
	if lore.has("kingdom"):
		_categories.append("kingdom")
		_category_list.add_item("The Kingdom")

	if lore.has("typhos_horde"):
		_categories.append("typhos_horde")
		_category_list.add_item("The Typhos Horde")

	if lore.has("characters"):
		var characters: Dictionary = lore.get("characters", {})
		for char_id in characters.keys():
			_categories.append("character:" + char_id)
			var char_data: Dictionary = characters[char_id]
			var name: String = str(char_data.get("name", char_id.capitalize()))
			_category_list.add_item(name)

func _on_category_selected(index: int) -> void:
	if index < 0 or index >= _categories.size():
		return

	var category: String = _categories[index]
	_display_lore(category)

func _display_lore(category: String) -> void:
	var lore: Dictionary = StoryManager.get_all_lore()
	if lore.is_empty():
		_lore_display.text = "No lore available."
		return

	var text: String = ""

	if category.begins_with("character:"):
		var char_id: String = category.substr(10)
		var characters: Dictionary = lore.get("characters", {})
		var char_data: Dictionary = characters.get(char_id, {})
		text = _format_character_lore(char_data)
	elif category == "kingdom":
		text = _format_kingdom_lore(lore.get("kingdom", {}))
	elif category == "typhos_horde":
		text = _format_horde_lore(lore.get("typhos_horde", {}))

	_lore_display.text = text

func _format_kingdom_lore(data: Dictionary) -> String:
	var name: String = str(data.get("name", "Keystonia"))
	var desc: String = str(data.get("description", ""))
	var history: String = str(data.get("history", ""))

	var text: String = "[color=#ffd700][b]%s[/b][/color]\n\n" % name
	if not desc.is_empty():
		text += "%s\n\n" % desc
	if not history.is_empty():
		text += "[color=#b0b0b0][i]History:[/i][/color]\n%s" % history

	return text

func _format_horde_lore(data: Dictionary) -> String:
	var name: String = str(data.get("name", "The Typhos Horde"))
	var desc: String = str(data.get("description", ""))
	var origin: String = str(data.get("origin", ""))
	var weakness: String = str(data.get("weakness", ""))

	var text: String = "[color=#dc143c][b]%s[/b][/color]\n\n" % name
	if not desc.is_empty():
		text += "%s\n\n" % desc
	if not origin.is_empty():
		text += "[color=#b0b0b0][i]Origin:[/i][/color]\n%s\n\n" % origin
	if not weakness.is_empty():
		text += "[color=#32cd32][i]Weakness:[/i][/color]\n%s" % weakness

	return text

func _format_character_lore(data: Dictionary) -> String:
	var name: String = str(data.get("name", "Unknown"))
	var title: String = str(data.get("title", ""))
	var desc: String = str(data.get("description", ""))
	var backstory: String = str(data.get("backstory", ""))
	var quotes: Array = data.get("quotes", [])

	var text: String = "[color=#4169e1][b]%s[/b][/color]" % name
	if not title.is_empty():
		text += "\n[i]%s[/i]" % title
	text += "\n\n"

	if not desc.is_empty():
		text += "%s\n\n" % desc
	if not backstory.is_empty():
		text += "[color=#b0b0b0][i]Backstory:[/i][/color]\n%s\n\n" % backstory

	if not quotes.is_empty():
		text += "[color=#ffd700][i]Notable Quotes:[/i][/color]\n"
		for quote in quotes:
			text += '  "%s"\n' % str(quote)

	return text

func show_lore() -> void:
	_populate_categories()
	show()
	if _category_list.item_count > 0:
		_category_list.select(0)
		_on_category_selected(0)

func hide_lore() -> void:
	hide()
	close_requested.emit()

func _on_close_pressed() -> void:
	hide_lore()

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		hide_lore()
		get_viewport().set_input_as_handled()
