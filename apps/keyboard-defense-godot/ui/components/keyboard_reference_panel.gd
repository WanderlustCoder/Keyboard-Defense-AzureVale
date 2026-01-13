class_name KeyboardReferencePanel
extends PanelContainer
## Keyboard Reference Panel - Shows finger zones and proper typing technique.
## Migrated to use DesignSystem and ThemeColors for consistency.

signal closed

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Finger zone definitions (QWERTY layout) - domain-specific colors
const FINGER_ZONES: Dictionary = {
	"left_pinky": {
		"name": "Left Pinky",
		"color": Color(0.9, 0.4, 0.4),
		"keys": ["Q", "A", "Z", "1", "`"]
	},
	"left_ring": {
		"name": "Left Ring",
		"color": Color(0.9, 0.6, 0.3),
		"keys": ["W", "S", "X", "2"]
	},
	"left_middle": {
		"name": "Left Middle",
		"color": Color(0.9, 0.9, 0.4),
		"keys": ["E", "D", "C", "3"]
	},
	"left_index": {
		"name": "Left Index",
		"color": Color(0.4, 0.9, 0.4),
		"keys": ["R", "T", "F", "G", "V", "B", "4", "5"]
	},
	"thumbs": {
		"name": "Thumbs",
		"color": Color(0.7, 0.7, 0.8),
		"keys": ["SPACE"]
	},
	"right_index": {
		"name": "Right Index",
		"color": Color(0.4, 0.9, 0.4),
		"keys": ["Y", "U", "H", "J", "N", "M", "6", "7"]
	},
	"right_middle": {
		"name": "Right Middle",
		"color": Color(0.9, 0.9, 0.4),
		"keys": ["I", "K", ",", "8"]
	},
	"right_ring": {
		"name": "Right Ring",
		"color": Color(0.9, 0.6, 0.3),
		"keys": ["O", "L", ".", "9"]
	},
	"right_pinky": {
		"name": "Right Pinky",
		"color": Color(0.9, 0.4, 0.4),
		"keys": ["P", ";", "/", "0", "-", "=", "[", "]", "'", "ENTER"]
	}
}

# Home row keys
const HOME_ROW: Array[String] = ["A", "S", "D", "F", "J", "K", "L", ";"]

# Tips for proper technique
const TECHNIQUE_TIPS: Array[Dictionary] = [
	{"title": "Home Row Position", "desc": "Keep your fingers on A-S-D-F and J-K-L-; when idle"},
	{"title": "Touch Typing", "desc": "Look at the screen, not the keyboard"},
	{"title": "Use All Fingers", "desc": "Each key has a designated finger - use them!"},
	{"title": "F and J Bumps", "desc": "The bumps on F and J help you find home position"},
	{"title": "Relax Your Hands", "desc": "Tension slows you down and causes fatigue"},
	{"title": "Proper Posture", "desc": "Keep wrists elevated and elbows at 90 degrees"}
]


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(DesignSystem.SIZE_PANEL_LG, 580)

	var style := DesignSystem.create_panel_style()
	add_theme_stylebox_override("panel", style)

	var main_vbox := DesignSystem.create_vbox(DesignSystem.SPACE_MD)
	add_child(main_vbox)

	# Header
	var header := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
	main_vbox.add_child(header)

	var title := Label.new()
	title.text = "KEYBOARD REFERENCE"
	DesignSystem.style_label(title, "h2", ThemeColors.INFO)
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
	subtitle.text = "Finger zones and proper typing technique"
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
	footer.text = "Practice consistently to build muscle memory"
	DesignSystem.style_label(footer, "caption", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func _style_close_button() -> void:
	var normal := DesignSystem.create_button_style(ThemeColors.BG_BUTTON, ThemeColors.BORDER)
	var hover := DesignSystem.create_button_style(ThemeColors.ERROR.darkened(0.3), ThemeColors.ERROR)
	_close_btn.add_theme_stylebox_override("normal", normal)
	_close_btn.add_theme_stylebox_override("hover", hover)
	_close_btn.add_theme_color_override("font_color", ThemeColors.TEXT)


func show_keyboard_reference() -> void:
	_build_content()
	show()


func refresh() -> void:
	_build_content()


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_content() -> void:
	_clear_content()

	# Visual keyboard layout
	_build_keyboard_visual()

	# Home row section
	_build_home_row_section()

	# Finger zones section
	_build_finger_zones_section()

	# Technique tips section
	_build_technique_tips_section()


func _build_keyboard_visual() -> void:
	var section := PanelContainer.new()

	var section_style := StyleBoxFlat.new()
	section_style.bg_color = ThemeColors.BG_DARK.darkened(0.3)
	section_style.border_color = ThemeColors.BORDER
	section_style.set_border_width_all(1)
	section_style.set_corner_radius_all(DesignSystem.RADIUS_SM)
	section_style.set_content_margin_all(DesignSystem.SPACE_MD)
	section.add_theme_stylebox_override("panel", section_style)

	_content_vbox.add_child(section)

	var vbox := DesignSystem.create_vbox(DesignSystem.SPACE_XS)
	section.add_child(vbox)

	# Build keyboard rows
	var rows: Array[Array] = [
		["`", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "="],
		["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P", "[", "]"],
		["A", "S", "D", "F", "G", "H", "J", "K", "L", ";", "'"],
		["Z", "X", "C", "V", "B", "N", "M", ",", ".", "/"]
	]

	for row in rows:
		var row_container := HBoxContainer.new()
		row_container.add_theme_constant_override("separation", 3)
		row_container.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_child(row_container)

		for key in row:
			var key_panel := _create_key_visual(key)
			row_container.add_child(key_panel)

	# Space bar row
	var space_row := HBoxContainer.new()
	space_row.add_theme_constant_override("separation", 3)
	space_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(space_row)

	var space_key := _create_key_visual("SPACE", 200)
	space_row.add_child(space_key)


func _create_key_visual(key: String, width: int = 32) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(width, 28)

	var color: Color = _get_key_color(key)
	var is_home: bool = HOME_ROW.has(key)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = color.darkened(0.7)
	panel_style.border_color = color.darkened(0.4) if is_home else color.darkened(0.5)
	panel_style.set_border_width_all(2 if is_home else 1)
	panel_style.set_corner_radius_all(DesignSystem.RADIUS_XS)
	panel.add_theme_stylebox_override("panel", panel_style)

	var label := Label.new()
	if key == "SPACE":
		label.text = ""
	else:
		label.text = key
	DesignSystem.style_label(label, "caption", color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(label)

	return panel


func _get_key_color(key: String) -> Color:
	for zone_id in FINGER_ZONES.keys():
		var zone: Dictionary = FINGER_ZONES[zone_id]
		if zone.get("keys", []).has(key):
			return zone.get("color", Color.WHITE)
	return Color(0.5, 0.5, 0.5)


func _build_home_row_section() -> void:
	var section := _create_section_panel("HOME ROW", ThemeColors.SUCCESS)
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	var desc := Label.new()
	desc.text = "Your fingers should rest on these keys when not typing:"
	DesignSystem.style_label(desc, "caption", ThemeColors.TEXT_DIM)
	vbox.add_child(desc)

	var keys_row := DesignSystem.create_hbox(DesignSystem.SPACE_SM)
	keys_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(keys_row)

	var left_label := Label.new()
	left_label.text = "Left Hand:"
	DesignSystem.style_label(left_label, "caption", ThemeColors.TEXT_DIM)
	keys_row.add_child(left_label)

	for key in ["A", "S", "D", "F"]:
		var key_panel := _create_key_visual(key)
		keys_row.add_child(key_panel)

	var sep := Control.new()
	sep.custom_minimum_size = Vector2(20, 0)
	keys_row.add_child(sep)

	var right_label := Label.new()
	right_label.text = "Right Hand:"
	DesignSystem.style_label(right_label, "caption", ThemeColors.TEXT_DIM)
	keys_row.add_child(right_label)

	for key in ["J", "K", "L", ";"]:
		var key_panel := _create_key_visual(key)
		keys_row.add_child(key_panel)


func _build_finger_zones_section() -> void:
	var section := _create_section_panel("FINGER ZONES", ThemeColors.INFO)
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	# Left hand
	var left_header := Label.new()
	left_header.text = "Left Hand"
	DesignSystem.style_label(left_header, "caption", ThemeColors.TEXT)
	vbox.add_child(left_header)

	for zone_id in ["left_pinky", "left_ring", "left_middle", "left_index"]:
		var row := _create_finger_zone_row(zone_id)
		vbox.add_child(row)

	# Thumbs
	var thumb_row := _create_finger_zone_row("thumbs")
	vbox.add_child(thumb_row)

	# Right hand
	var right_header := Label.new()
	right_header.text = "Right Hand"
	DesignSystem.style_label(right_header, "caption", ThemeColors.TEXT)
	vbox.add_child(right_header)

	for zone_id in ["right_index", "right_middle", "right_ring", "right_pinky"]:
		var row := _create_finger_zone_row(zone_id)
		vbox.add_child(row)


func _create_finger_zone_row(zone_id: String) -> Control:
	var zone: Dictionary = FINGER_ZONES.get(zone_id, {})
	var zone_name: String = str(zone.get("name", zone_id))
	var color: Color = zone.get("color", Color.WHITE)
	var keys: Array = zone.get("keys", [])

	var hbox := DesignSystem.create_hbox(DesignSystem.SPACE_MD)

	# Color indicator
	var color_rect := ColorRect.new()
	color_rect.color = color
	color_rect.custom_minimum_size = Vector2(12, 12)
	hbox.add_child(color_rect)

	# Finger name
	var name_label := Label.new()
	name_label.text = zone_name
	DesignSystem.style_label(name_label, "caption", color)
	name_label.custom_minimum_size = Vector2(90, 0)
	hbox.add_child(name_label)

	# Keys
	var keys_label := Label.new()
	var key_display: String = ", ".join(keys)
	if key_display.length() > 30:
		key_display = key_display.substr(0, 30) + "..."
	keys_label.text = key_display
	DesignSystem.style_label(keys_label, "caption", ThemeColors.TEXT_DIM)
	hbox.add_child(keys_label)

	return hbox


func _build_technique_tips_section() -> void:
	var section := _create_section_panel("TECHNIQUE TIPS", Color(0.9, 0.7, 0.4))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for tip in TECHNIQUE_TIPS:
		var row := DesignSystem.create_hbox(DesignSystem.SPACE_SM)
		vbox.add_child(row)

		var title_label := Label.new()
		title_label.text = str(tip.get("title", ""))
		DesignSystem.style_label(title_label, "caption", Color(0.9, 0.7, 0.4))
		title_label.custom_minimum_size = Vector2(120, 0)
		row.add_child(title_label)

		var desc_label := Label.new()
		desc_label.text = str(tip.get("desc", ""))
		DesignSystem.style_label(desc_label, "caption", ThemeColors.TEXT_DIM)
		row.add_child(desc_label)


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
