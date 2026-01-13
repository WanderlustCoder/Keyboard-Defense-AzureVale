class_name DayNightReferencePanel
extends PanelContainer
## Day/Night Reference Panel - Shows day/night cycle and wave mechanics.
## Migrated to use DesignSystem and ThemeColors for consistency.

signal closed

# UI elements
var _close_btn: Button = null
var _content_scroll: ScrollContainer = null
var _content_vbox: VBoxContainer = null

# Phase info - domain-specific colors
const PHASES: Array[Dictionary] = [
	{
		"phase": "day",
		"name": "Day Phase",
		"desc": "Build, move, prepare defenses",
		"activities": "Build structures, assign workers, research, trade",
		"icon": "sun",
		"color": Color(1.0, 0.84, 0.0)
	},
	{
		"phase": "night",
		"name": "Night Phase",
		"desc": "Defend against enemy waves",
		"activities": "Type to attack enemies, use special commands",
		"icon": "moon",
		"color": Color(0.4, 0.4, 0.8)
	}
]

# Day activities - domain-specific colors
const DAY_ACTIVITIES: Array[Dictionary] = [
	{
		"activity": "Build",
		"desc": "Construct buildings on the map",
		"cost": "Resources (wood, stone, etc.)",
		"color": Color(0.5, 0.8, 0.3)
	},
	{
		"activity": "Move",
		"desc": "Navigate cursor to explore and discover tiles",
		"cost": "Action points",
		"color": Color(0.4, 0.8, 1.0)
	},
	{
		"activity": "Upgrade",
		"desc": "Improve existing buildings",
		"cost": "Resources + gold",
		"color": Color(0.9, 0.6, 0.3)
	},
	{
		"activity": "Research",
		"desc": "Unlock permanent upgrades",
		"cost": "Gold + time (waves)",
		"color": Color(0.7, 0.5, 0.9)
	},
	{
		"activity": "Trade",
		"desc": "Buy/sell resources at the market",
		"cost": "Gold or resources",
		"color": Color(1.0, 0.84, 0.0)
	},
	{
		"activity": "Assign",
		"desc": "Assign workers to buildings",
		"cost": "Available workers",
		"color": Color(0.9, 0.5, 0.9)
	}
]

# Wave scaling
const WAVE_SCALING: Array[Dictionary] = [
	{"day": "1", "base_enemies": 2, "desc": "Tutorial wave", "color": Color(0.5, 0.8, 0.3)},
	{"day": "2-3", "base_enemies": 3, "desc": "Early game", "color": Color(0.4, 0.8, 1.0)},
	{"day": "4-5", "base_enemies": 4, "desc": "Mid-early game", "color": Color(0.9, 0.6, 0.3)},
	{"day": "6-7", "base_enemies": 6, "desc": "Mid game", "color": Color(0.9, 0.5, 0.9)},
	{"day": "8+", "base_enemies": 7, "desc": "Late game (scales with day)", "color": Color(0.9, 0.4, 0.4)}
]

# Wave formula components
const WAVE_FORMULA: Array[Dictionary] = [
	{
		"factor": "Base Count",
		"desc": "Starting enemy count based on current day",
		"color": Color(0.4, 0.8, 1.0)
	},
	{
		"factor": "Threat Level",
		"desc": "Accumulated threat adds more enemies",
		"color": Color(0.9, 0.4, 0.4)
	},
	{
		"factor": "Defense",
		"desc": "Your total defense reduces enemies",
		"color": Color(0.5, 0.8, 0.3)
	},
	{
		"factor": "Difficulty",
		"desc": "Difficulty mode multiplies final count",
		"color": Color(0.9, 0.6, 0.3)
	}
]

# Tips
const CYCLE_TIPS: Array[String] = [
	"End day early with NIGHT command to start defense",
	"Build defense structures before nightfall",
	"Production happens at the start of each day",
	"Threat increases if you let enemies reach your castle",
	"Higher defense means fewer enemies per wave",
	"Boss waves occur every 5 days"
]


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	custom_minimum_size = Vector2(DesignSystem.SIZE_PANEL_MD, 620)

	var style := DesignSystem.create_panel_style()
	add_theme_stylebox_override("panel", style)

	var main_vbox := DesignSystem.create_vbox(DesignSystem.SPACE_MD)
	add_child(main_vbox)

	# Header
	var header := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
	main_vbox.add_child(header)

	var title := Label.new()
	title.text = "DAY/NIGHT CYCLE"
	DesignSystem.style_label(title, "h2", ThemeColors.RESOURCE_GOLD)
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
	subtitle.text = "Build by day, defend by night"
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
	footer.text = "Type NIGHT to start defense phase"
	DesignSystem.style_label(footer, "caption", ThemeColors.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(footer)


func _style_close_button() -> void:
	var normal := DesignSystem.create_button_style(ThemeColors.BG_BUTTON, ThemeColors.BORDER)
	var hover := DesignSystem.create_button_style(ThemeColors.ERROR.darkened(0.3), ThemeColors.ERROR)
	_close_btn.add_theme_stylebox_override("normal", normal)
	_close_btn.add_theme_stylebox_override("hover", hover)
	_close_btn.add_theme_color_override("font_color", ThemeColors.TEXT)


func show_day_night_reference() -> void:
	_build_content()
	show()


func refresh() -> void:
	_build_content()


func _clear_content() -> void:
	for child in _content_vbox.get_children():
		child.queue_free()


func _build_content() -> void:
	_clear_content()

	# Phases section
	_build_phases_section()

	# Day activities section
	_build_activities_section()

	# Wave scaling section
	_build_wave_section()

	# Wave formula section
	_build_formula_section()

	# Tips section
	_build_tips_section()


func _build_phases_section() -> void:
	var section := _create_section_panel("GAME PHASES", ThemeColors.RESOURCE_GOLD)
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for phase in PHASES:
		var container := DesignSystem.create_vbox(2)
		vbox.add_child(container)

		var name_label := Label.new()
		name_label.text = str(phase.get("name", ""))
		DesignSystem.style_label(name_label, "caption", phase.get("color", Color.WHITE))
		container.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = "  " + str(phase.get("desc", ""))
		DesignSystem.style_label(desc_label, "caption", ThemeColors.TEXT_DIM)
		container.add_child(desc_label)

		var activities_label := Label.new()
		activities_label.text = "  " + str(phase.get("activities", ""))
		DesignSystem.style_label(activities_label, "caption", ThemeColors.TEXT_DIM.darkened(0.2))
		container.add_child(activities_label)


func _build_activities_section() -> void:
	var section := _create_section_panel("DAY ACTIVITIES", ThemeColors.SUCCESS)
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for activity in DAY_ACTIVITIES:
		var hbox := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
		vbox.add_child(hbox)

		var name_label := Label.new()
		name_label.text = str(activity.get("activity", ""))
		DesignSystem.style_label(name_label, "caption", activity.get("color", Color.WHITE))
		name_label.custom_minimum_size = Vector2(70, 0)
		hbox.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = str(activity.get("desc", ""))
		DesignSystem.style_label(desc_label, "caption", ThemeColors.TEXT_DIM)
		hbox.add_child(desc_label)


func _build_wave_section() -> void:
	var section := _create_section_panel("WAVE SCALING BY DAY", ThemeColors.ERROR)
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for wave in WAVE_SCALING:
		var hbox := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
		vbox.add_child(hbox)

		var day_label := Label.new()
		day_label.text = "Day %s" % wave.get("day", "")
		DesignSystem.style_label(day_label, "caption", wave.get("color", Color.WHITE))
		day_label.custom_minimum_size = Vector2(60, 0)
		hbox.add_child(day_label)

		var count_label := Label.new()
		count_label.text = "%d base" % wave.get("base_enemies", 0)
		DesignSystem.style_label(count_label, "caption", ThemeColors.INFO)
		count_label.custom_minimum_size = Vector2(55, 0)
		hbox.add_child(count_label)

		var desc_label := Label.new()
		desc_label.text = str(wave.get("desc", ""))
		DesignSystem.style_label(desc_label, "caption", ThemeColors.TEXT_DIM)
		hbox.add_child(desc_label)


func _build_formula_section() -> void:
	var section := _create_section_panel("WAVE FORMULA", ThemeColors.INFO)
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	var formula_label := Label.new()
	formula_label.text = "Enemies = Base + Threat - Defense"
	DesignSystem.style_label(formula_label, "caption", ThemeColors.TEXT)
	vbox.add_child(formula_label)

	for factor in WAVE_FORMULA:
		var hbox := DesignSystem.create_hbox(DesignSystem.SPACE_MD)
		vbox.add_child(hbox)

		var factor_label := Label.new()
		factor_label.text = str(factor.get("factor", ""))
		DesignSystem.style_label(factor_label, "caption", factor.get("color", Color.WHITE))
		factor_label.custom_minimum_size = Vector2(100, 0)
		hbox.add_child(factor_label)

		var desc_label := Label.new()
		desc_label.text = str(factor.get("desc", ""))
		DesignSystem.style_label(desc_label, "caption", ThemeColors.TEXT_DIM)
		hbox.add_child(desc_label)


func _build_tips_section() -> void:
	var section := _create_section_panel("CYCLE TIPS", Color(0.7, 0.5, 0.9))
	_content_vbox.add_child(section)

	var vbox: VBoxContainer = section.get_child(0)

	for tip in CYCLE_TIPS:
		var tip_label := Label.new()
		tip_label.text = "- " + tip
		DesignSystem.style_label(tip_label, "caption", ThemeColors.TEXT_DIM)
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
