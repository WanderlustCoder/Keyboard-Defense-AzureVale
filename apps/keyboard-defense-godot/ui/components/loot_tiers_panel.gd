class_name LootTiersPanel
extends PanelContainer
## Loot Tiers Panel - Shows how accuracy affects loot quality

signal closed

const ThemeColors = preload("res://ui/theme_colors.gd")

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Quality tiers (from SimLoot)
const QUALITY_TIERS: Array[Dictionary] = [
	{
		"name": "Poor",
		"min_accuracy": 0,
		"max_accuracy": 60,
		"multiplier": 0.5,
		"color": Color(0.5, 0.5, 0.5)
	},
	{
		"name": "Normal",
		"min_accuracy": 60,
		"max_accuracy": 85,
		"multiplier": 1.0,
		"color": Color(0.8, 0.8, 0.8)
	},
	{
		"name": "Good",
		"min_accuracy": 85,
		"max_accuracy": 95,
		"multiplier": 1.25,
		"color": Color(0.4, 0.9, 0.4)
	},
	{
		"name": "Excellent",
		"min_accuracy": 95,
		"max_accuracy": 99,
		"multiplier": 1.5,
		"color": Color(0.4, 0.8, 1.0)
	},
	{
		"name": "Perfect",
		"min_accuracy": 99,
		"max_accuracy": 100,
		"multiplier": 2.0,
		"color": Color(1.0, 0.84, 0.0)
	}
]

# Loot mechanics
const LOOT_MECHANICS: Array[Dictionary] = [
	{
		"topic": "Accuracy Matters",
		"desc": "Your typing accuracy determines loot quality tier",
		"color": Color(0.4, 0.8, 1.0)
	},
	{
		"topic": "Quality Multiplier",
		"desc": "Higher tiers multiply all resource drops",
		"color": Color(1.0, 0.84, 0.0)
	},
	{
		"topic": "Perfect Bonus",
		"desc": "100% accuracy unlocks bonus loot drops",
		"color": Color(0.9, 0.5, 0.9)
	},
	{
		"topic": "Boss Loot",
		"desc": "Bosses have separate, more generous loot tables",
		"color": Color(0.9, 0.4, 0.4)
	},
	{
		"topic": "Combo Bonus",
		"desc": "High combos can also increase drop rates",
		"color": Color(0.9, 0.6, 0.3)
	}
]

# Tips
const LOOT_TIPS: Array[String] = [
	"Focus on accuracy over speed for better rewards",
	"Perfect kills (100% accuracy) give double loot",
	"Boss enemies drop rare materials and equipment",
	"Higher difficulty modes increase gold rewards",
	"Use the LOOT special command for bonus drops"
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
	title.text = "LOOT QUALITY"
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
	subtitle.text = "How accuracy affects your rewards"
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
	footer.text = "Type accurately to maximize your rewards!"
	footer.add_theme_font_size_override("font_size", 11)
	footer.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func show_loot_tiers() -> void:
	_build_content()
	show()


func refresh() -> void:
	_build_content()


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_content() -> void:
	_clear_content()

	# Quality tiers section
	_build_tiers_section()

	# Mechanics section
	_build_mechanics_section()

	# Tips section
	_build_tips_section()


func _build_tiers_section() -> void:
	var section := _create_section_panel("QUALITY TIERS", Color(1.0, 0.84, 0.0))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	# Header row
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	vbox.add_child(header)

	var h_tier := Label.new()
	h_tier.text = "Tier"
	h_tier.add_theme_font_size_override("font_size", 10)
	h_tier.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	h_tier.custom_minimum_size = Vector2(70, 0)
	header.add_child(h_tier)

	var h_acc := Label.new()
	h_acc.text = "Accuracy"
	h_acc.add_theme_font_size_override("font_size", 10)
	h_acc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	h_acc.custom_minimum_size = Vector2(100, 0)
	header.add_child(h_acc)

	var h_mult := Label.new()
	h_mult.text = "Multiplier"
	h_mult.add_theme_font_size_override("font_size", 10)
	h_mult.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	header.add_child(h_mult)

	# Tier rows
	for tier in QUALITY_TIERS:
		var row := _create_tier_row(tier)
		vbox.add_child(row)


func _create_tier_row(tier: Dictionary) -> Control:
	var name: String = str(tier.get("name", ""))
	var min_acc: int = int(tier.get("min_accuracy", 0))
	var max_acc: int = int(tier.get("max_accuracy", 100))
	var multiplier: float = float(tier.get("multiplier", 1.0))
	var color: Color = tier.get("color", Color.WHITE)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)

	var name_label := Label.new()
	name_label.text = name
	name_label.add_theme_font_size_override("font_size", 11)
	name_label.add_theme_color_override("font_color", color)
	name_label.custom_minimum_size = Vector2(70, 0)
	hbox.add_child(name_label)

	var acc_label := Label.new()
	if max_acc >= 100:
		acc_label.text = "%d%%+" % min_acc
	else:
		acc_label.text = "%d%% - %d%%" % [min_acc, max_acc]
	acc_label.add_theme_font_size_override("font_size", 10)
	acc_label.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	acc_label.custom_minimum_size = Vector2(100, 0)
	hbox.add_child(acc_label)

	var mult_label := Label.new()
	mult_label.text = "x%.2f" % multiplier
	mult_label.add_theme_font_size_override("font_size", 10)
	mult_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
	hbox.add_child(mult_label)

	return hbox


func _build_mechanics_section() -> void:
	var section := _create_section_panel("HOW LOOT WORKS", Color(0.5, 0.8, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for info in LOOT_MECHANICS:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		vbox.add_child(hbox)

		var topic_label := Label.new()
		topic_label.text = str(info.get("topic", ""))
		topic_label.add_theme_font_size_override("font_size", 10)
		topic_label.add_theme_color_override("font_color", info.get("color", Color.WHITE))
		topic_label.custom_minimum_size = Vector2(110, 0)
		hbox.add_child(topic_label)

		var desc_label := Label.new()
		desc_label.text = str(info.get("desc", ""))
		desc_label.add_theme_font_size_override("font_size", 9)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		hbox.add_child(desc_label)


func _build_tips_section() -> void:
	var section := _create_section_panel("LOOT TIPS", Color(0.4, 0.8, 1.0))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for tip in LOOT_TIPS:
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
	vbox.add_theme_constant_override("separation", 6)
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
