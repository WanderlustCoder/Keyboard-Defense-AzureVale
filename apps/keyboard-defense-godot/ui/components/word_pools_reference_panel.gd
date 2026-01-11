class_name WordPoolsReferencePanel
extends PanelContainer
## Word Pools Reference Panel - Shows word generation modes and pools

signal closed

const ThemeColors = preload("res://ui/theme_colors.gd")

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Word generation modes
const WORD_MODES: Array[Dictionary] = [
	{
		"mode": "charset",
		"name": "Charset Mode",
		"desc": "Generate words from specific characters (e.g., home row keys)",
		"example": "asdf -> 'dfsa', 'ffad', 'sdaf'",
		"color": Color(0.4, 0.8, 1.0)
	},
	{
		"mode": "wordlist",
		"name": "Wordlist Mode",
		"desc": "Use predefined words from a curated list",
		"example": "harvest, harbor, forest, meadow",
		"color": Color(0.5, 0.8, 0.3)
	},
	{
		"mode": "sentence",
		"name": "Sentence Mode",
		"desc": "Type complete sentences or phrases",
		"example": "The quick brown fox jumps over the lazy dog",
		"color": Color(0.9, 0.6, 0.3)
	}
]

# Enemy word lengths (by kind)
const WORD_LENGTHS: Array[Dictionary] = [
	{
		"kind": "Scout",
		"min": 3,
		"max": 4,
		"desc": "Fast enemies with short words",
		"color": Color(0.4, 0.8, 1.0)
	},
	{
		"kind": "Raider",
		"min": 4,
		"max": 6,
		"desc": "Standard enemies with medium words",
		"color": Color(0.9, 0.6, 0.3)
	},
	{
		"kind": "Armored",
		"min": 6,
		"max": 8,
		"desc": "Tough enemies with long words",
		"color": Color(0.5, 0.5, 0.6)
	},
	{
		"kind": "Boss",
		"min": 7,
		"max": 10,
		"desc": "Boss enemies with challenging words",
		"color": Color(0.9, 0.4, 0.4)
	}
]

# Sample word pools
const SAMPLE_POOLS: Array[Dictionary] = [
	{
		"name": "Short Words",
		"count": 12,
		"examples": "mist, fern, glow, bolt, rift, lark",
		"color": Color(0.4, 0.8, 1.0)
	},
	{
		"name": "Medium Words",
		"count": 14,
		"examples": "harvest, harbor, citron, amber, copper",
		"color": Color(0.5, 0.8, 0.3)
	},
	{
		"name": "Long Words",
		"count": 12,
		"examples": "sentinel, fortress, vanguard, monolith",
		"color": Color(0.9, 0.6, 0.3)
	}
]

# Word mechanics
const WORD_MECHANICS: Array[Dictionary] = [
	{
		"topic": "Reserved Words",
		"desc": "Command keywords are never used as enemy words",
		"color": Color(0.9, 0.4, 0.4)
	},
	{
		"topic": "No Duplicates",
		"desc": "Each word appears at most once per wave",
		"color": Color(0.4, 0.8, 1.0)
	},
	{
		"topic": "Lesson-Based",
		"desc": "Words match your current typing lesson",
		"color": Color(0.5, 0.8, 0.3)
	},
	{
		"topic": "Deterministic",
		"desc": "Same seed produces same words each run",
		"color": Color(0.7, 0.5, 0.9)
	}
]

# Tips
const WORD_TIPS: Array[String] = [
	"Practice lessons to master specific key groups",
	"Harder enemies have longer, more complex words",
	"Boss words are the longest and most challenging",
	"Charset mode helps practice specific finger positions",
	"Sentence mode improves typing fluency"
]


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(520, 600)

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
	title.text = "WORD GENERATION"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
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
	subtitle.text = "How enemy words are generated"
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
	footer.text = "Type LESSON to change word pool"
	footer.add_theme_font_size_override("font_size", 11)
	footer.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func show_word_pools() -> void:
	_build_content()
	show()


func refresh() -> void:
	_build_content()


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_content() -> void:
	_clear_content()

	# Modes section
	_build_modes_section()

	# Word lengths section
	_build_lengths_section()

	# Mechanics section
	_build_mechanics_section()

	# Sample pools section
	_build_pools_section()

	# Tips section
	_build_tips_section()


func _build_modes_section() -> void:
	var section := _create_section_panel("GENERATION MODES", Color(0.4, 0.8, 1.0))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for mode in WORD_MODES:
		var container := VBoxContainer.new()
		container.add_theme_constant_override("separation", 2)
		vbox.add_child(container)

		var name_label := Label.new()
		name_label.text = str(mode.get("name", ""))
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.add_theme_color_override("font_color", mode.get("color", Color.WHITE))
		container.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = "  " + str(mode.get("desc", ""))
		desc_label.add_theme_font_size_override("font_size", 9)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		container.add_child(desc_label)

		var example_label := Label.new()
		example_label.text = "  Ex: " + str(mode.get("example", ""))
		example_label.add_theme_font_size_override("font_size", 9)
		example_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		container.add_child(example_label)


func _build_lengths_section() -> void:
	var section := _create_section_panel("WORD LENGTHS BY ENEMY", Color(0.9, 0.6, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for length_info in WORD_LENGTHS:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		vbox.add_child(hbox)

		var kind_label := Label.new()
		kind_label.text = str(length_info.get("kind", ""))
		kind_label.add_theme_font_size_override("font_size", 10)
		kind_label.add_theme_color_override("font_color", length_info.get("color", Color.WHITE))
		kind_label.custom_minimum_size = Vector2(60, 0)
		hbox.add_child(kind_label)

		var range_label := Label.new()
		range_label.text = "%d-%d chars" % [length_info.get("min", 3), length_info.get("max", 6)]
		range_label.add_theme_font_size_override("font_size", 9)
		range_label.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
		range_label.custom_minimum_size = Vector2(70, 0)
		hbox.add_child(range_label)

		var desc_label := Label.new()
		desc_label.text = str(length_info.get("desc", ""))
		desc_label.add_theme_font_size_override("font_size", 9)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		hbox.add_child(desc_label)


func _build_mechanics_section() -> void:
	var section := _create_section_panel("WORD MECHANICS", Color(0.5, 0.8, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for info in WORD_MECHANICS:
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


func _build_pools_section() -> void:
	var section := _create_section_panel("FALLBACK WORD POOLS", Color(0.7, 0.5, 0.9))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for pool in SAMPLE_POOLS:
		var container := VBoxContainer.new()
		container.add_theme_constant_override("separation", 2)
		vbox.add_child(container)

		var header_row := HBoxContainer.new()
		header_row.add_theme_constant_override("separation", 10)
		container.add_child(header_row)

		var name_label := Label.new()
		name_label.text = str(pool.get("name", ""))
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.add_theme_color_override("font_color", pool.get("color", Color.WHITE))
		header_row.add_child(name_label)

		var count_label := Label.new()
		count_label.text = "(%d words)" % pool.get("count", 0)
		count_label.add_theme_font_size_override("font_size", 9)
		count_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		header_row.add_child(count_label)

		var examples_label := Label.new()
		examples_label.text = "  " + str(pool.get("examples", ""))
		examples_label.add_theme_font_size_override("font_size", 9)
		examples_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		container.add_child(examples_label)


func _build_tips_section() -> void:
	var section := _create_section_panel("WORD TIPS", Color(0.9, 0.4, 0.4))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for tip in WORD_TIPS:
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
