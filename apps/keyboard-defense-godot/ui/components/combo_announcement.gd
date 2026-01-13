class_name ComboAnnouncement
extends Control
## Shows celebratory combo milestone announcements with visual flair.
## Partially migrated to use DesignSystem - keeps domain-specific animation values.

# Milestone thresholds
const MILESTONES := [5, 10, 15, 20, 25, 30, 40, 50]

# Animation settings (domain-specific, kept as constants)
const ANNOUNCE_DURATION := 1.5
const SCALE_IN_DURATION := 0.2
const SCALE_OUT_DURATION := 0.4
const SCALE_PEAK := 1.3
const SCALE_FINAL := 1.0
const SHAKE_INTENSITY := 4.0
const SHAKE_FREQUENCY := 20.0

# Visual settings (larger than DesignSystem typography for celebratory effect)
const FONT_SIZE_BASE := 36
const FONT_SIZE_MAX := 48
const GLOW_EXPAND := 6.0

# Combo tier colors (domain-specific milestone colors)
const COMBO_TIER_COLORS := {
	1: Color(0.4, 0.8, 0.9, 1.0),  # 5x - Cyan
	2: Color(0.3, 0.9, 0.5, 1.0),  # 10x - Green
	3: Color(0.9, 0.8, 0.2, 1.0),  # 15x - Gold
	4: Color(0.9, 0.5, 0.2, 1.0),  # 20x - Orange
	5: Color(0.9, 0.3, 0.9, 1.0)   # 25x+ - Purple
}

# Titles per milestone
const TITLES := {
	5: "NICE!",
	10: "GREAT!",
	15: "AMAZING!",
	20: "INCREDIBLE!",
	25: "UNSTOPPABLE!",
	30: "LEGENDARY!",
	40: "GODLIKE!",
	50: "TRANSCENDENT!"
}

var _announcement_label: Label = null
var _combo_label: Label = null
var _container: VBoxContainer = null
var _tween: Tween = null
var _shake_time: float = 0.0
var _is_animating: bool = false
var _base_position: Vector2 = Vector2.ZERO
var _settings_manager = null
var _audio_manager = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_setup_ui()
	visible = false
	_settings_manager = get_node_or_null("/root/SettingsManager")
	_audio_manager = get_node_or_null("/root/AudioManager")


func _setup_ui() -> void:
	# Container for centering - use negative spacing for tight vertical layout
	_container = VBoxContainer.new()
	_container.set_anchors_preset(Control.PRESET_CENTER)
	_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_container.add_theme_constant_override("separation", -DesignSystem.SPACE_XS)
	add_child(_container)

	# Title label (e.g., "AMAZING!")
	_announcement_label = Label.new()
	_announcement_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_announcement_label.add_theme_font_size_override("font_size", FONT_SIZE_BASE)
	_container.add_child(_announcement_label)

	# Combo count label (e.g., "x15 COMBO")
	_combo_label = Label.new()
	_combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_combo_label.add_theme_font_size_override("font_size", int(FONT_SIZE_BASE * 0.7))
	_container.add_child(_combo_label)

	# Store base position for shake effect
	_base_position = _container.position


func _process(delta: float) -> void:
	if not _is_animating:
		return

	# Check reduced motion
	var reduced_motion := false
	if _settings_manager != null and _settings_manager.get("reduced_motion") != null:
		reduced_motion = _settings_manager.reduced_motion

	if not reduced_motion:
		# Apply shake effect
		_shake_time += delta * SHAKE_FREQUENCY
		var shake_decay := modulate.a  # Fade shake with alpha
		var offset_x := sin(_shake_time) * SHAKE_INTENSITY * shake_decay
		if _container != null:
			_container.position = _base_position + Vector2(offset_x, 0)


## Check if a combo value is a milestone and show announcement if so
func check_combo(combo: int) -> void:
	if combo in MILESTONES:
		show_milestone(combo)


## Show a milestone announcement for the given combo
func show_milestone(combo: int) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()

	# Get title and color for this milestone
	var title: String = TITLES.get(combo, "COMBO!")
	var color := _get_milestone_color(combo)

	# Calculate font size based on milestone (bigger for higher milestones)
	var milestone_index := MILESTONES.find(combo)
	var size_factor := 1.0 + (milestone_index * 0.08) if milestone_index >= 0 else 1.0
	var font_size := int(FONT_SIZE_BASE * size_factor)
	font_size = min(font_size, FONT_SIZE_MAX)

	# Set labels
	_announcement_label.text = title
	_announcement_label.add_theme_font_size_override("font_size", font_size)
	_announcement_label.add_theme_color_override("font_color", color)

	_combo_label.text = "x%d COMBO" % combo
	_combo_label.add_theme_font_size_override("font_size", int(font_size * 0.6))
	_combo_label.add_theme_color_override("font_color", color.darkened(0.2))

	# Animate
	_is_animating = true
	_shake_time = 0.0
	visible = true
	scale = Vector2(0.3, 0.3)
	modulate.a = 1.0

	# Check reduced motion for animation
	var reduced_motion := false
	if _settings_manager != null and _settings_manager.get("reduced_motion") != null:
		reduced_motion = _settings_manager.reduced_motion

	_tween = create_tween()

	if reduced_motion:
		# Simple fade without scale animation
		_tween.tween_property(self, "scale", Vector2.ONE, 0.1)
		_tween.tween_interval(ANNOUNCE_DURATION - 0.5)
		_tween.tween_property(self, "modulate:a", 0.0, 0.4)
	else:
		# Full animation: scale in with overshoot, hold, fade out
		_tween.set_ease(Tween.EASE_OUT)
		_tween.set_trans(Tween.TRANS_BACK)
		_tween.tween_property(self, "scale", Vector2(SCALE_PEAK, SCALE_PEAK), SCALE_IN_DURATION)
		_tween.tween_property(self, "scale", Vector2(SCALE_FINAL, SCALE_FINAL), 0.1)
		_tween.tween_interval(ANNOUNCE_DURATION - SCALE_IN_DURATION - SCALE_OUT_DURATION - 0.1)
		_tween.set_trans(Tween.TRANS_QUAD)
		_tween.tween_property(self, "modulate:a", 0.0, SCALE_OUT_DURATION)

	_tween.tween_callback(_on_animation_finished)

	# Play sound
	if _audio_manager != null:
		if combo >= 10 and _audio_manager.has_method("play_combo_milestone_10"):
			_audio_manager.play_combo_milestone_10()
		elif _audio_manager.has_method("play_combo_milestone_5"):
			_audio_manager.play_combo_milestone_5()


func _on_animation_finished() -> void:
	_is_animating = false
	visible = false
	# Reset shake offset
	if _container != null:
		_container.position = _base_position


func _get_milestone_color(combo: int) -> Color:
	if combo >= 25:
		return COMBO_TIER_COLORS[5]
	elif combo >= 20:
		return COMBO_TIER_COLORS[4]
	elif combo >= 15:
		return COMBO_TIER_COLORS[3]
	elif combo >= 10:
		return COMBO_TIER_COLORS[2]
	else:
		return COMBO_TIER_COLORS[1]
