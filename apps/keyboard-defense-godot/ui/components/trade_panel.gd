class_name TradePanel
extends PanelContainer
## Trade Panel - Shows trade rates and market information

signal closed
signal trade_requested(from_resource: String, to_resource: String, amount: int)

const ThemeColors = preload("res://ui/theme_colors.gd")

var _trade_summary: Dictionary = {}

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Resource colors
const RESOURCE_COLORS: Dictionary = {
	"wood": Color(0.6, 0.4, 0.2),
	"stone": Color(0.6, 0.6, 0.7),
	"food": Color(0.5, 0.8, 0.3),
	"gold": Color(1.0, 0.84, 0.0)
}

# Base exchange rates reference
const EXCHANGE_RATES: Array[Dictionary] = [
	{"from": "wood", "to": "stone", "desc": "3 Wood -> 2 Stone"},
	{"from": "stone", "to": "wood", "desc": "2 Stone -> 3 Wood"},
	{"from": "wood", "to": "food", "desc": "1 Wood -> 1 Food"},
	{"from": "food", "to": "wood", "desc": "1 Food -> 1 Wood"},
	{"from": "stone", "to": "food", "desc": "2 Stone -> 3 Food"},
	{"from": "food", "to": "stone", "desc": "3 Food -> 2 Stone"},
	{"from": "wood", "to": "gold", "desc": "3 Wood -> 1 Gold"},
	{"from": "gold", "to": "wood", "desc": "1 Gold -> 3 Wood"},
	{"from": "stone", "to": "gold", "desc": "2 Stone -> 1 Gold"},
	{"from": "gold", "to": "stone", "desc": "1 Gold -> 2 Stone"},
	{"from": "food", "to": "gold", "desc": "2 Food -> 1 Gold"},
	{"from": "gold", "to": "food", "desc": "1 Gold -> 2 Food"}
]


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(480, 540)

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
	title.text = "TRADE MARKET"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
	header.add_child(title)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)

	_close_btn = Button.new()
	_close_btn.text = "X"
	_close_btn.custom_minimum_size = Vector2(30, 30)
	_close_btn.pressed.connect(_on_close_pressed)
	header.add_child(_close_btn)

	# Subtitle
	var subtitle := Label.new()
	subtitle.text = "Exchange resources at the market (requires Level 3 Market)"
	subtitle.add_theme_font_size_override("font_size", 12)
	subtitle.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	main_vbox.add_child(subtitle)

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

	# Footer
	var footer := Label.new()
	footer.text = "Trade rates fluctuate daily"
	footer.add_theme_font_size_override("font_size", 11)
	footer.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func show_trade_market(summary: Dictionary = {}) -> void:
	_trade_summary = summary
	_build_content()
	show()


func refresh(summary: Dictionary = {}) -> void:
	_trade_summary = summary
	_build_content()


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_content() -> void:
	_clear_content()

	var enabled: bool = bool(_trade_summary.get("enabled", false))

	# Status section
	_build_status_section(enabled)

	if enabled:
		# Current resources
		_build_resources_section()

		# Exchange rates section
		_build_rates_section()

		# Suggested trades
		_build_suggestions_section()

	# How to trade section
	_build_help_section()


func _build_status_section(enabled: bool) -> void:
	var section := PanelContainer.new()

	var section_style := StyleBoxFlat.new()
	if enabled:
		section_style.bg_color = Color(0.15, 0.25, 0.15, 0.9)
		section_style.border_color = Color(0.4, 0.7, 0.4, 0.7)
	else:
		section_style.bg_color = Color(0.25, 0.15, 0.15, 0.9)
		section_style.border_color = Color(0.7, 0.4, 0.4, 0.7)
	section_style.set_border_width_all(2)
	section_style.set_corner_radius_all(6)
	section_style.set_content_margin_all(10)
	section.add_theme_stylebox_override("panel", section_style)

	_content_vbox.add_child(section)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 15)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	section.add_child(hbox)

	var status_label := Label.new()
	if enabled:
		status_label.text = "MARKET OPEN"
		status_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
	else:
		status_label.text = "MARKET CLOSED"
		status_label.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4))
	status_label.add_theme_font_size_override("font_size", 16)
	hbox.add_child(status_label)

	if enabled:
		var bonus: float = float(_trade_summary.get("market_bonus", 0))
		if bonus > 0:
			var bonus_label := Label.new()
			bonus_label.text = "+%.0f%% Market Bonus" % (bonus * 100)
			bonus_label.add_theme_font_size_override("font_size", 12)
			bonus_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
			hbox.add_child(bonus_label)
	else:
		var req_label := Label.new()
		req_label.text = "(Build Level 3 Market)"
		req_label.add_theme_font_size_override("font_size", 11)
		req_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		hbox.add_child(req_label)


func _build_resources_section() -> void:
	var section := _create_section_panel("YOUR RESOURCES", Color(0.6, 0.8, 1.0))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	var resources: Dictionary = _trade_summary.get("resources", {})

	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 4)
	vbox.add_child(grid)

	for res_name in ["wood", "stone", "food", "gold"]:
		var amount: int = int(resources.get(res_name, 0))
		var color: Color = RESOURCE_COLORS.get(res_name, Color.WHITE)

		var res_vbox := VBoxContainer.new()
		res_vbox.add_theme_constant_override("separation", 0)
		grid.add_child(res_vbox)

		var name_label := Label.new()
		name_label.text = res_name.capitalize()
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		res_vbox.add_child(name_label)

		var amount_label := Label.new()
		amount_label.text = str(amount)
		amount_label.add_theme_font_size_override("font_size", 16)
		amount_label.add_theme_color_override("font_color", color)
		amount_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		res_vbox.add_child(amount_label)


func _build_rates_section() -> void:
	var section := _create_section_panel("EXCHANGE RATES", Color(1.0, 0.84, 0.0))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	var rates: Dictionary = _trade_summary.get("rates", {})

	var desc_label := Label.new()
	desc_label.text = "Current rates (fluctuate daily):"
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	vbox.add_child(desc_label)

	# Group by from_resource
	var grouped: Dictionary = {}
	for exchange in EXCHANGE_RATES:
		var from_res: String = str(exchange.get("from", ""))
		if not grouped.has(from_res):
			grouped[from_res] = []
		grouped[from_res].append(exchange)

	for from_res in ["wood", "stone", "food", "gold"]:
		if not grouped.has(from_res):
			continue

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		vbox.add_child(row)

		var from_label := Label.new()
		from_label.text = from_res.capitalize() + ":"
		from_label.add_theme_font_size_override("font_size", 10)
		from_label.add_theme_color_override("font_color", RESOURCE_COLORS.get(from_res, Color.WHITE))
		from_label.custom_minimum_size = Vector2(50, 0)
		row.add_child(from_label)

		for exchange in grouped[from_res]:
			var to_res: String = str(exchange.get("to", ""))
			var rate_key: String = from_res + "_to_" + to_res
			var rate: float = float(rates.get(rate_key, 0))

			if rate > 0:
				var rate_label := Label.new()
				rate_label.text = "-> %.2f %s" % [rate, to_res.capitalize()]
				rate_label.add_theme_font_size_override("font_size", 10)
				rate_label.add_theme_color_override("font_color", RESOURCE_COLORS.get(to_res, Color.WHITE))
				row.add_child(rate_label)


func _build_suggestions_section() -> void:
	var section := _create_section_panel("TRADE COMMANDS", Color(0.4, 0.9, 0.4))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	var desc := Label.new()
	desc.text = "Type during planning phase:"
	desc.add_theme_font_size_override("font_size", 11)
	desc.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	vbox.add_child(desc)

	var examples: Array[String] = [
		"trade 10 wood for stone",
		"trade 5 stone to gold",
		"trade 20 food for wood"
	]

	for example in examples:
		var example_label := Label.new()
		example_label.text = "  " + example
		example_label.add_theme_font_size_override("font_size", 11)
		example_label.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9))
		vbox.add_child(example_label)


func _build_help_section() -> void:
	var section := PanelContainer.new()

	var section_style := StyleBoxFlat.new()
	section_style.bg_color = Color(0.12, 0.15, 0.18, 0.8)
	section_style.border_color = Color(0.3, 0.4, 0.5)
	section_style.set_border_width_all(1)
	section_style.set_corner_radius_all(6)
	section_style.set_content_margin_all(10)
	section.add_theme_stylebox_override("panel", section_style)

	_content_vbox.add_child(section)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	section.add_child(vbox)

	var header := Label.new()
	header.text = "TRADING TIPS"
	header.add_theme_font_size_override("font_size", 12)
	header.add_theme_color_override("font_color", Color(0.6, 0.7, 0.9))
	vbox.add_child(header)

	var tips: Array[String] = [
		"Build and upgrade Markets for better exchange rates",
		"Trade rates change daily - watch for good deals",
		"Convert excess resources to gold for flexibility",
		"Market bonus stacks from multiple Markets"
	]

	for tip in tips:
		var tip_label := Label.new()
		tip_label.text = "- " + tip
		tip_label.add_theme_font_size_override("font_size", 10)
		tip_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		tip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(tip_label)


func _create_section_panel(title: String, color: Color) -> PanelContainer:
	var container := PanelContainer.new()

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = color.darkened(0.85)
	panel_style.border_color = color.darkened(0.5)
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(6)
	panel_style.set_content_margin_all(10)
	container.add_theme_stylebox_override("panel", panel_style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	container.add_child(vbox)

	var header := Label.new()
	header.text = title
	header.add_theme_font_size_override("font_size", 12)
	header.add_theme_color_override("font_color", color)
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
