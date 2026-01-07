class_name TypingDisplay
extends PanelContainer
## The main typing display component showing the current word and progress.

const ThemeColors = preload("res://ui/theme_colors.gd")

@onready var drill_title: Label = $Content/DrillTitle
@onready var drill_hint: Label = $Content/DrillHint
@onready var typed_label: Label = $Content/WordDisplay/TypedLabel
@onready var current_char: Label = $Content/WordDisplay/CurrentChar
@onready var remaining_label: Label = $Content/WordDisplay/RemainingLabel
@onready var feedback_label: Label = $Content/FeedbackLabel

var _feedback_tween: Tween = null

func _ready() -> void:
	_apply_styling()

func _apply_styling() -> void:
	if drill_title:
		drill_title.add_theme_font_size_override("font_size", 18)
		drill_title.add_theme_color_override("font_color", ThemeColors.ACCENT)

	if drill_hint:
		drill_hint.add_theme_font_size_override("font_size", 14)
		drill_hint.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)

	if typed_label:
		typed_label.add_theme_font_size_override("font_size", 32)
		typed_label.add_theme_color_override("font_color", ThemeColors.TYPED_CORRECT)

	if current_char:
		current_char.add_theme_font_size_override("font_size", 32)
		current_char.add_theme_color_override("font_color", ThemeColors.ACCENT)

	if remaining_label:
		remaining_label.add_theme_font_size_override("font_size", 32)
		remaining_label.add_theme_color_override("font_color", ThemeColors.TYPED_PENDING)

	if feedback_label:
		feedback_label.add_theme_font_size_override("font_size", 20)
		feedback_label.modulate.a = 0.0

## Set the drill title
func set_drill_title(text: String) -> void:
	if drill_title:
		drill_title.text = text

## Set the drill hint
func set_drill_hint(text: String) -> void:
	if drill_hint:
		drill_hint.text = text
		drill_hint.visible = text != ""

## Update the word display with current typing progress
func update_word(full_word: String, typed_count: int) -> void:
	if typed_count < 0:
		typed_count = 0
	if typed_count > full_word.length():
		typed_count = full_word.length()

	var typed_part := full_word.substr(0, typed_count)
	var current := ""
	var remaining := ""

	if typed_count < full_word.length():
		current = full_word[typed_count]
		remaining = full_word.substr(typed_count + 1)

	if typed_label:
		typed_label.text = typed_part

	if current_char:
		current_char.text = current

	if remaining_label:
		remaining_label.text = remaining

## Show feedback message with fade animation
func show_feedback(text: String, color: Color = ThemeColors.TEXT, duration: float = 0.75) -> void:
	if feedback_label == null:
		return

	if _feedback_tween and _feedback_tween.is_running():
		_feedback_tween.kill()

	feedback_label.text = text
	feedback_label.add_theme_color_override("font_color", color)
	feedback_label.modulate.a = 1.0

	_feedback_tween = create_tween()
	_feedback_tween.tween_property(feedback_label, "modulate:a", 0.0, duration * 0.4).set_delay(duration * 0.6)

## Show error feedback (red, quick)
func show_error(text: String = "Missed!") -> void:
	show_feedback(text, ThemeColors.ERROR, 0.6)

## Show success feedback (accent color)
func show_success(text: String = "Strike!") -> void:
	show_feedback(text, ThemeColors.ACCENT, 0.75)

## Show special feedback (blue, longer)
func show_special(text: String) -> void:
	show_feedback(text, ThemeColors.ACCENT_BLUE, 1.1)

## Clear the display
func clear() -> void:
	if drill_title:
		drill_title.text = ""
	if drill_hint:
		drill_hint.text = ""
		drill_hint.visible = false
	if typed_label:
		typed_label.text = ""
	if current_char:
		current_char.text = ""
	if remaining_label:
		remaining_label.text = ""
	if feedback_label:
		feedback_label.text = ""
		feedback_label.modulate.a = 0.0
