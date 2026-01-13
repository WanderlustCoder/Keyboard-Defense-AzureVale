class_name TradeReferencePanel
extends PanelContainer
## Trade Reference Panel - Shows trading system and exchange rates.
## Migrated to use DesignSystem and ThemeColors for consistency.

signal closed

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Trade requirements
const TRADE_REQUIREMENTS: Array[Dictionary] = [
	{
		"id": "market_level",
		"name": "Level 3 Market Required",
		"desc": "Trading is unlocked when you build a market and upgrade it to Level 3",
		"color": Color(1.0, 0.84, 0.0)
	},
	{
		"id": "daily_variance",
		"name": "Daily Rate Variance",
		"desc": "Exchange rates fluctuate +/- 15% each day - check for good deals!",
		"color": Color(0.5, 0.7, 0.9)
	}
]

# Base exchange rates
const EXCHANGE_RATES: Array[Dictionary] = [
	{
		"from": "Wood",
		"to": "Stone",
		"rate": "3:2",
		"desc": "3 wood becomes 2 stone",
		"from_color": Color(0.55, 0.27, 0.07),
		"to_color": Color(0.5, 0.5, 0.6)
	},
	{
		"from": "Stone",
		"to": "Wood",
		"rate": "2:3",
		"desc": "2 stone becomes 3 wood",
		"from_color": Color(0.5, 0.5, 0.6),
		"to_color": Color(0.55, 0.27, 0.07)
	},
	{
		"from": "Wood",
		"to": "Food",
		"rate": "1:1",
		"desc": "1 wood becomes 1 food",
		"from_color": Color(0.55, 0.27, 0.07),
		"to_color": Color(0.4, 0.7, 0.3)
	},
	{
		"from": "Food",
		"to": "Wood",
		"rate": "1:1",
		"desc": "1 food becomes 1 wood",
		"from_color": Color(0.4, 0.7, 0.3),
		"to_color": Color(0.55, 0.27, 0.07)
	},
	{
		"from": "Stone",
		"to": "Food",
		"rate": "2:3",
		"desc": "2 stone becomes 3 food",
		"from_color": Color(0.5, 0.5, 0.6),
		"to_color": Color(0.4, 0.7, 0.3)
	},
	{
		"from": "Food",
		"to": "Stone",
		"rate": "3:2",
		"desc": "3 food becomes 2 stone",
		"from_color": Color(0.4, 0.7, 0.3),
		"to_color": Color(0.5, 0.5, 0.6)
	},
	{
		"from": "Wood",
		"to": "Gold",
		"rate": "3:1",
		"desc": "3 wood becomes 1 gold",
		"from_color": Color(0.55, 0.27, 0.07),
		"to_color": Color(1.0, 0.84, 0.0)
	},
	{
		"from": "Gold",
		"to": "Wood",
		"rate": "1:3",
		"desc": "1 gold becomes 3 wood",
		"from_color": Color(1.0, 0.84, 0.0),
		"to_color": Color(0.55, 0.27, 0.07)
	},
	{
		"from": "Stone",
		"to": "Gold",
		"rate": "2:1",
		"desc": "2 stone becomes 1 gold",
		"from_color": Color(0.5, 0.5, 0.6),
		"to_color": Color(1.0, 0.84, 0.0)
	},
	{
		"from": "Gold",
		"to": "Stone",
		"rate": "1:2",
		"desc": "1 gold becomes 2 stone",
		"from_color": Color(1.0, 0.84, 0.0),
		"to_color": Color(0.5, 0.5, 0.6)
	},
	{
		"from": "Food",
		"to": "Gold",
		"rate": "2:1",
		"desc": "2 food becomes 1 gold",
		"from_color": Color(0.4, 0.7, 0.3),
		"to_color": Color(1.0, 0.84, 0.0)
	},
	{
		"from": "Gold",
		"to": "Food",
		"rate": "1:2",
		"desc": "1 gold becomes 2 food",
		"from_color": Color(1.0, 0.84, 0.0),
		"to_color": Color(0.4, 0.7, 0.3)
	}
]

# Market bonuses
const MARKET_BONUSES: Array[Dictionary] = [
	{
		"level": "Level 1 Market",
		"bonus": "+5%",
		"desc": "Slightly better exchange rates",
		"color": Color(0.5, 0.6, 0.7)
	},
	{
		"level": "Level 2 Market",
		"bonus": "+10%",
		"desc": "Better exchange rates",
		"color": Color(0.6, 0.7, 0.8)
	},
	{
		"level": "Level 3 Market",
		"bonus": "+15%",
		"desc": "Trading enabled, good exchange rates",
		"color": Color(1.0, 0.84, 0.0)
	},
	{
		"level": "Multiple Markets",
		"bonus": "Up to +30%",
		"desc": "Bonuses stack across all markets (max 30%)",
		"color": Color(0.4, 0.8, 0.4)
	}
]

# Trade commands
const TRADE_COMMANDS: Array[Dictionary] = [
	{
		"command": "trade [amount] [resource] for [resource]",
		"desc": "Trade one resource for another at current rates",
		"example": "trade 10 wood for stone",
		"color": Color(0.5, 0.8, 0.3)
	},
	{
		"command": "trade [amount] [resource] to [resource]",
		"desc": "Alternative syntax for trading",
		"example": "trade 5 food to gold",
		"color": Color(0.5, 0.8, 0.3)
	},
	{
		"command": "rates",
		"desc": "View current exchange rates (with daily variance)",
		"example": "rates",
		"color": Color(0.5, 0.6, 0.8)
	}
]

# Trade tips
const TRADE_TIPS: Array[String] = [
	"Check rates daily - a 15% swing can make a big difference",
	"Gold is the universal currency but trades at premium rates",
	"Build multiple markets for stacking bonus rates (up to 30%)",
	"When selling to gold, higher market bonus = more gold received",
	"When buying with gold, higher market bonus = less gold spent",
	"Wood-food trades are 1:1 - good for emergency swaps"
]


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(DesignSystem.SIZE_PANEL_LG, 620)

	var style := DesignSystem.create_panel_style()
	add_theme_stylebox_override("panel", style)

	var main_vbox := DesignSystem.create_vbox(DesignSystem.SPACE_MD)
	add_child(main_vbox)

	# Header
	var header := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
	main_vbox.add_child(header)

	var title := Label.new()
	title.text = "TRADE SYSTEM"
	DesignSystem.style_label(title, "h2", Color(1.0, 0.84, 0.0))
	header.add_child(title)

	header.add_child(DesignSystem.create_spacer())

	_close_btn = Button.new()
	_close_btn.text = "✕"
	_close_btn.custom_minimum_size = Vector2(DesignSystem.SIZE_BUTTON_SM, DesignSystem.SIZE_BUTTON_SM)
	_style_close_button()
	_close_btn.pressed.connect(_on_close_pressed)
	header.add_child(_close_btn)

	# Subtitle
	var subtitle := Label.new()
	subtitle.text = "12 exchange pairs with daily rate variance"
	DesignSystem.style_label(subtitle, "body_small", ThemeColors.TEXT_DIM)
	main_vbox.add_child(subtitle)

	# Content scroll
	_content_scroll = ScrollContainer.new()
	_content_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_vbox.add_child(_content_scroll)

	_content_vbox = DesignSystem.create_vbox(DesignSystem.SPACE_MD)
	_content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_scroll.add_child(_content_vbox)

	# Footer
	var footer := Label.new()
	footer.text = "Type 'trade [amt] [from] for [to]' during planning phase"
	DesignSystem.style_label(footer, "caption", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func _style_close_button() -> void:
	var normal := DesignSystem.create_button_style(ThemeColors.BG_BUTTON, ThemeColors.BORDER)
	var hover := DesignSystem.create_button_style(ThemeColors.ERROR.darkened(0.3), ThemeColors.ERROR)
	_close_btn.add_theme_stylebox_override("normal", normal)
	_close_btn.add_theme_stylebox_override("hover", hover)
	_close_btn.add_theme_color_override("font_color", ThemeColors.TEXT)


func show_trade_reference() -> void:
	_build_content()
	show()


func refresh() -> void:
	_build_content()


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_content() -> void:
	_clear_content()

	# Requirements
	_build_requirements_section()

	# Exchange rates
	_build_exchange_rates_section()

	# Market bonuses
	_build_market_bonuses_section()

	# Commands
	_build_commands_section()

	# Tips
	_build_tips_section()


func _build_requirements_section() -> void:
	var section := _create_section_panel("REQUIREMENTS", Color(1.0, 0.5, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for req in TRADE_REQUIREMENTS:
		var container := VBoxContainer.new()
		container.add_theme_constant_override("separation", 1)
		vbox.add_child(container)

		var name_label := Label.new()
		name_label.text = str(req.get("name", ""))
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.add_theme_color_override("font_color", req.get("color", Color.WHITE))
		container.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = "  " + str(req.get("desc", ""))
		desc_label.add_theme_font_size_override("font_size", 9)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		container.add_child(desc_label)


func _build_exchange_rates_section() -> void:
	var section := _create_section_panel("BASE EXCHANGE RATES", Color(0.5, 0.8, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for rate in EXCHANGE_RATES:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 5)
		vbox.add_child(hbox)

		var from_label := Label.new()
		from_label.text = str(rate.get("from", ""))
		from_label.add_theme_font_size_override("font_size", 10)
		from_label.add_theme_color_override("font_color", rate.get("from_color", Color.WHITE))
		from_label.custom_minimum_size = Vector2(50, 0)
		hbox.add_child(from_label)

		var arrow_label := Label.new()
		arrow_label.text = "->"
		arrow_label.add_theme_font_size_override("font_size", 10)
		arrow_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		arrow_label.custom_minimum_size = Vector2(25, 0)
		hbox.add_child(arrow_label)

		var to_label := Label.new()
		to_label.text = str(rate.get("to", ""))
		to_label.add_theme_font_size_override("font_size", 10)
		to_label.add_theme_color_override("font_color", rate.get("to_color", Color.WHITE))
		to_label.custom_minimum_size = Vector2(50, 0)
		hbox.add_child(to_label)

		var rate_label := Label.new()
		rate_label.text = str(rate.get("rate", ""))
		rate_label.add_theme_font_size_override("font_size", 10)
		rate_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
		rate_label.custom_minimum_size = Vector2(40, 0)
		hbox.add_child(rate_label)

		var desc_label := Label.new()
		desc_label.text = str(rate.get("desc", ""))
		desc_label.add_theme_font_size_override("font_size", 9)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		hbox.add_child(desc_label)


func _build_market_bonuses_section() -> void:
	var section := _create_section_panel("MARKET BONUSES", Color(0.5, 0.6, 0.9))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for bonus in MARKET_BONUSES:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		vbox.add_child(hbox)

		var level_label := Label.new()
		level_label.text = str(bonus.get("level", ""))
		level_label.add_theme_font_size_override("font_size", 10)
		level_label.add_theme_color_override("font_color", bonus.get("color", Color.WHITE))
		level_label.custom_minimum_size = Vector2(120, 0)
		hbox.add_child(level_label)

		var bonus_label := Label.new()
		bonus_label.text = str(bonus.get("bonus", ""))
		bonus_label.add_theme_font_size_override("font_size", 10)
		bonus_label.add_theme_color_override("font_color", Color(0.5, 0.8, 0.3))
		bonus_label.custom_minimum_size = Vector2(60, 0)
		hbox.add_child(bonus_label)

		var desc_label := Label.new()
		desc_label.text = str(bonus.get("desc", ""))
		desc_label.add_theme_font_size_override("font_size", 9)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		hbox.add_child(desc_label)


func _build_commands_section() -> void:
	var section := _create_section_panel("COMMANDS", Color(0.5, 0.7, 0.9))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for cmd in TRADE_COMMANDS:
		var container := VBoxContainer.new()
		container.add_theme_constant_override("separation", 1)
		vbox.add_child(container)

		var cmd_label := Label.new()
		cmd_label.text = str(cmd.get("command", ""))
		cmd_label.add_theme_font_size_override("font_size", 10)
		cmd_label.add_theme_color_override("font_color", cmd.get("color", Color.WHITE))
		container.add_child(cmd_label)

		var desc_label := Label.new()
		desc_label.text = "  " + str(cmd.get("desc", ""))
		desc_label.add_theme_font_size_override("font_size", 9)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		container.add_child(desc_label)

		var example_label := Label.new()
		example_label.text = "  Ex: " + str(cmd.get("example", ""))
		example_label.add_theme_font_size_override("font_size", 9)
		example_label.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7))
		container.add_child(example_label)


func _build_tips_section() -> void:
	var section := _create_section_panel("TRADE TIPS", Color(0.5, 0.8, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for tip in TRADE_TIPS:
		var tip_label := Label.new()
		tip_label.text = "- " + tip
		tip_label.add_theme_font_size_override("font_size", 9)
		tip_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		tip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(tip_label)


func _create_section_panel(title: String, color: Color) -> PanelContainer:
	var container := PanelContainer.new()

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = color.darkened(0.85)
	panel_style.border_color = color.darkened(0.5)
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(DesignSystem.RADIUS_SM)
	panel_style.set_content_margin_all(DesignSystem.SPACE_MD)
	container.add_theme_stylebox_override("panel", panel_style)

	var vbox := DesignSystem.create_vbox(DesignSystem.SPACE_SM)
	container.add_child(vbox)

	var header := Label.new()
	header.text = title
	DesignSystem.style_label(header, "body_small", color)
	vbox.add_child(header)

	return container


func _on_close_pressed() -> void:
	hide()
	closed.emit()


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
		get_viewport().set_input_as_handled()
