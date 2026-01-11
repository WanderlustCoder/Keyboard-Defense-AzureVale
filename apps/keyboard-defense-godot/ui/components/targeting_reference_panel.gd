class_name TargetingReferencePanel
extends PanelContainer
## Targeting Reference Panel - Shows tower targeting priorities and selection methods

signal closed

const ThemeColors = preload("res://ui/theme_colors.gd")

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Target priorities
const TARGET_PRIORITIES: Array[Dictionary] = [
	{
		"priority": "CLOSEST_TO_BASE",
		"name": "Closest to Base",
		"desc": "Targets enemy with lowest distance field value (about to reach castle)",
		"usage": "Default for most towers",
		"color": Color(0.9, 0.4, 0.4)
	},
	{
		"priority": "HIGHEST_HP",
		"name": "Highest HP",
		"desc": "Targets enemies with the most health first",
		"usage": "Tanks and bosses get priority",
		"color": Color(0.4, 0.8, 1.0)
	},
	{
		"priority": "LOWEST_HP",
		"name": "Lowest HP",
		"desc": "Targets enemies with least health first",
		"usage": "Finish off weak enemies quickly",
		"color": Color(0.5, 0.8, 0.3)
	},
	{
		"priority": "MARKED",
		"name": "Marked",
		"desc": "Prioritizes enemies with 'marked' status effect",
		"usage": "Focus fire on marked targets",
		"color": Color(0.9, 0.6, 0.3)
	},
	{
		"priority": "BOSS",
		"name": "Boss Priority",
		"desc": "Always targets bosses if present in range",
		"usage": "Holy Tower, special abilities",
		"color": Color(0.7, 0.5, 0.9)
	},
	{
		"priority": "RANDOM",
		"name": "Random",
		"desc": "Picks random valid target in range",
		"usage": "Chaos effects, special abilities",
		"color": Color(0.8, 0.8, 0.8)
	}
]

# Selection types
const SELECTION_TYPES: Array[Dictionary] = [
	{
		"type": "single",
		"name": "Single Target",
		"desc": "Picks one enemy based on priority",
		"towers": "Arrow, Magic, Holy, Poison, Frost",
		"color": Color(0.4, 0.8, 1.0)
	},
	{
		"type": "multi",
		"name": "Multi Target",
		"desc": "Picks multiple enemies, sorted by priority",
		"towers": "Multi-Shot towers",
		"color": Color(0.5, 0.8, 0.3)
	},
	{
		"type": "aoe",
		"name": "Area of Effect",
		"desc": "Picks primary target, damages all in radius",
		"towers": "Cannon, Bomb, Meteor",
		"color": Color(0.9, 0.6, 0.3)
	},
	{
		"type": "chain",
		"name": "Chain",
		"desc": "Picks primary, then chains to nearest unvisited",
		"towers": "Tesla, Lightning",
		"color": Color(0.7, 0.5, 0.9)
	},
	{
		"type": "adaptive",
		"name": "Adaptive",
		"desc": "Changes targeting based on battle situation",
		"towers": "Letter Spirit Shrine (Legendary)",
		"color": Color(0.9, 0.4, 0.4)
	}
]

# Adaptive modes
const ADAPTIVE_MODES: Array[Dictionary] = [
	{
		"mode": "Alpha",
		"trigger": "Boss detected in range",
		"behavior": "Single target focus on boss",
		"color": Color(0.9, 0.4, 0.4)
	},
	{
		"mode": "Epsilon",
		"trigger": "10+ enemies on field",
		"behavior": "Chain to all enemies in range",
		"color": Color(0.7, 0.5, 0.9)
	},
	{
		"mode": "Omega",
		"trigger": "Castle HP below 50%",
		"behavior": "Target lowest HP for quick kills (heal on kill)",
		"color": Color(0.5, 0.8, 0.3)
	}
]

# Tips
const TARGETING_TIPS: Array[String] = [
	"Towers auto-select targets every attack cycle",
	"Chain attacks find nearest unvisited enemy each jump",
	"AoE radius is centered on the primary target",
	"Multi-shot splits damage across all targets",
	"Adaptive towers are powerful but rare (Legendary)"
]


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(520, 620)

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
	title.text = "TARGETING SYSTEM"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.9, 0.6, 0.3))
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
	subtitle.text = "How towers select and prioritize targets"
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
	footer.text = "Targeting affects tower effectiveness"
	footer.add_theme_font_size_override("font_size", 11)
	footer.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func show_targeting_reference() -> void:
	_build_content()
	show()


func refresh() -> void:
	_build_content()


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_content() -> void:
	_clear_content()

	# Priorities section
	_build_priorities_section()

	# Selection types section
	_build_selection_section()

	# Adaptive modes section
	_build_adaptive_section()

	# Tips section
	_build_tips_section()


func _build_priorities_section() -> void:
	var section := _create_section_panel("TARGET PRIORITIES", Color(0.9, 0.6, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for info in TARGET_PRIORITIES:
		var container := VBoxContainer.new()
		container.add_theme_constant_override("separation", 2)
		vbox.add_child(container)

		var name_label := Label.new()
		name_label.text = str(info.get("name", ""))
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.add_theme_color_override("font_color", info.get("color", Color.WHITE))
		container.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = "  " + str(info.get("desc", ""))
		desc_label.add_theme_font_size_override("font_size", 9)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		container.add_child(desc_label)


func _build_selection_section() -> void:
	var section := _create_section_panel("SELECTION TYPES", Color(0.4, 0.8, 1.0))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for info in SELECTION_TYPES:
		var container := VBoxContainer.new()
		container.add_theme_constant_override("separation", 2)
		vbox.add_child(container)

		var name_label := Label.new()
		name_label.text = str(info.get("name", ""))
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.add_theme_color_override("font_color", info.get("color", Color.WHITE))
		container.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = "  " + str(info.get("desc", ""))
		desc_label.add_theme_font_size_override("font_size", 9)
		desc_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		container.add_child(desc_label)

		var towers_label := Label.new()
		towers_label.text = "  Towers: " + str(info.get("towers", ""))
		towers_label.add_theme_font_size_override("font_size", 9)
		towers_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		container.add_child(towers_label)


func _build_adaptive_section() -> void:
	var section := _create_section_panel("ADAPTIVE MODES", Color(0.7, 0.5, 0.9))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for info in ADAPTIVE_MODES:
		var container := VBoxContainer.new()
		container.add_theme_constant_override("separation", 2)
		vbox.add_child(container)

		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		container.add_child(hbox)

		var mode_label := Label.new()
		mode_label.text = str(info.get("mode", ""))
		mode_label.add_theme_font_size_override("font_size", 10)
		mode_label.add_theme_color_override("font_color", info.get("color", Color.WHITE))
		mode_label.custom_minimum_size = Vector2(60, 0)
		hbox.add_child(mode_label)

		var trigger_label := Label.new()
		trigger_label.text = str(info.get("trigger", ""))
		trigger_label.add_theme_font_size_override("font_size", 9)
		trigger_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		hbox.add_child(trigger_label)

		var behavior_label := Label.new()
		behavior_label.text = "  -> " + str(info.get("behavior", ""))
		behavior_label.add_theme_font_size_override("font_size", 9)
		behavior_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		container.add_child(behavior_label)


func _build_tips_section() -> void:
	var section := _create_section_panel("TARGETING TIPS", Color(0.5, 0.8, 0.3))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for tip in TARGETING_TIPS:
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
