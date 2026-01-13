class_name PhaseIndicator
extends HBoxContainer
## Displays current game phase with icon and animated transitions.
## Shows day number, phase name, and wave progress during combat.

signal phase_clicked

## Current phase ("day", "night", "combat", "game_over", "victory")
var current_phase: String = "day":
	set(value):
		var old_phase := current_phase
		current_phase = value
		if old_phase != value:
			_animate_phase_change(old_phase, value)
		_update_display()

## Current day number
var day_number: int = 1:
	set(value):
		day_number = value
		_update_display()

## Current wave (during combat)
var wave_current: int = 0

## Total waves (during combat)
var wave_total: int = 0

# Phase configuration
const PHASE_CONFIG := {
	"day": {
		"icon": "D",
		"label": "PLANNING",
		"color": Color(0.98, 0.84, 0.44),  # Gold
		"bg_color": Color(0.2, 0.18, 0.1)
	},
	"night": {
		"icon": "N",
		"label": "DEFENSE",
		"color": Color(0.65, 0.86, 1.0),  # Sky blue
		"bg_color": Color(0.1, 0.15, 0.2)
	},
	"combat": {
		"icon": "!",
		"label": "COMBAT",
		"color": Color(0.96, 0.45, 0.45),  # Red
		"bg_color": Color(0.2, 0.1, 0.1)
	},
	"wave_assault": {
		"icon": "!",
		"label": "WAVE ASSAULT",
		"color": Color(0.96, 0.45, 0.45),
		"bg_color": Color(0.25, 0.1, 0.1)
	},
	"game_over": {
		"icon": "X",
		"label": "GAME OVER",
		"color": Color(0.5, 0.5, 0.55),
		"bg_color": Color(0.15, 0.15, 0.15)
	},
	"victory": {
		"icon": "V",
		"label": "VICTORY",
		"color": Color(0.45, 0.82, 0.55),  # Green
		"bg_color": Color(0.1, 0.2, 0.1)
	}
}

# Internal references
var _panel: PanelContainer
var _icon_label: Label
var _phase_label: Label
var _day_label: Label
var _wave_label: Label
var _transition_tween: Tween


func _ready() -> void:
	_build_display()
	_update_display()


func _build_display() -> void:
	add_theme_constant_override("separation", DesignSystem.SPACE_MD)
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	gui_input.connect(_on_gui_input)

	# Day counter
	_day_label = Label.new()
	_day_label.text = "Day 1"
	DesignSystem.style_label(_day_label, "h2", ThemeColors.TEXT)
	add_child(_day_label)

	# Phase panel
	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(120, 0)
	add_child(_panel)

	var panel_hbox := HBoxContainer.new()
	panel_hbox.add_theme_constant_override("separation", DesignSystem.SPACE_SM)
	panel_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_panel.add_child(panel_hbox)

	# Phase icon
	_icon_label = Label.new()
	_icon_label.text = "D"
	_icon_label.add_theme_font_size_override("font_size", DesignSystem.FONT_H2)
	_icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_icon_label.custom_minimum_size.x = 24
	panel_hbox.add_child(_icon_label)

	# Phase name
	_phase_label = Label.new()
	_phase_label.text = "PLANNING"
	_phase_label.add_theme_font_size_override("font_size", DesignSystem.FONT_BODY)
	panel_hbox.add_child(_phase_label)

	# Wave indicator (hidden by default)
	_wave_label = Label.new()
	_wave_label.text = ""
	_wave_label.visible = false
	DesignSystem.style_label(_wave_label, "body_small", ThemeColors.TEXT_DIM)
	add_child(_wave_label)


func _update_display() -> void:
	if not _phase_label:
		return

	var config: Dictionary = PHASE_CONFIG.get(current_phase, PHASE_CONFIG["day"])

	# Update day label
	_day_label.text = "Day %d" % day_number

	# Update phase display
	_icon_label.text = config.icon
	_icon_label.add_theme_color_override("font_color", config.color)
	_phase_label.text = config.label
	_phase_label.add_theme_color_override("font_color", config.color)

	# Update panel style
	var style := StyleBoxFlat.new()
	style.bg_color = config.bg_color
	style.border_color = config.color.darkened(0.3)
	style.set_border_width_all(2)
	style.set_corner_radius_all(DesignSystem.RADIUS_SM)
	style.content_margin_left = DesignSystem.SPACE_MD
	style.content_margin_right = DesignSystem.SPACE_MD
	style.content_margin_top = DesignSystem.SPACE_SM
	style.content_margin_bottom = DesignSystem.SPACE_SM
	_panel.add_theme_stylebox_override("panel", style)

	# Show/hide wave indicator
	var show_waves: bool = current_phase in ["night", "combat", "wave_assault"]
	_wave_label.visible = show_waves and wave_total > 0
	if _wave_label.visible:
		_wave_label.text = "Wave %d/%d" % [wave_current, wave_total]


func _animate_phase_change(from_phase: String, to_phase: String) -> void:
	if _transition_tween:
		_transition_tween.kill()

	var config: Dictionary = PHASE_CONFIG.get(to_phase, PHASE_CONFIG["day"])

	_transition_tween = create_tween()
	_transition_tween.set_parallel(true)

	# Scale bounce
	_panel.pivot_offset = _panel.size / 2
	_panel.scale = Vector2(0.8, 0.8)
	_transition_tween.tween_property(_panel, "scale", Vector2.ONE, DesignSystem.ANIM_NORMAL).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	# Flash effect
	_icon_label.modulate = Color.WHITE * 2.0
	_transition_tween.tween_property(_icon_label, "modulate", Color.WHITE, DesignSystem.ANIM_NORMAL)

	# Start phase-specific animations
	_transition_tween.chain().tween_callback(func():
		_start_phase_animation(to_phase)
	)


func _start_phase_animation(phase: String) -> void:
	match phase:
		"night", "combat", "wave_assault":
			_start_combat_pulse()
		_:
			_stop_pulse()


func _start_combat_pulse() -> void:
	_stop_pulse()

	var config: Dictionary = PHASE_CONFIG.get(current_phase, PHASE_CONFIG["night"])

	_transition_tween = create_tween()
	_transition_tween.set_loops()

	# Gentle glow pulse
	_transition_tween.tween_property(_icon_label, "modulate", Color.WHITE * 1.3, 0.8)
	_transition_tween.tween_property(_icon_label, "modulate", Color.WHITE, 0.8)


func _stop_pulse() -> void:
	if _transition_tween:
		_transition_tween.kill()
		_transition_tween = null

	if _icon_label:
		_icon_label.modulate = Color.WHITE


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		phase_clicked.emit()


## Update from game state
func update_from_state(state: RefCounted) -> void:
	day_number = state.day
	current_phase = state.phase

	# Handle activity mode for open-world
	if state.get("activity_mode"):
		match state.activity_mode:
			"wave_assault":
				current_phase = "wave_assault"
			"combat":
				current_phase = "combat"

	# Update wave info
	if current_phase in ["night", "combat", "wave_assault"]:
		wave_current = state.day  # or wave counter
		wave_total = state.night_wave_total if state.get("night_wave_total") else 0


## Set wave progress during combat
func set_wave_progress(current: int, total: int) -> void:
	wave_current = current
	wave_total = total
	_update_display()


## Create a minimal phase indicator (icon only)
static func create_minimal() -> PhaseIndicator:
	var indicator := PhaseIndicator.new()
	# Hide day label for minimal mode
	indicator._day_label.visible = false if indicator._day_label else true
	return indicator
