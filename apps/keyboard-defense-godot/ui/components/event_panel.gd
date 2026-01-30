class_name EventPanel
extends PanelContainer
## Panel for displaying events and handling choice input.
## Migrated to use ThemeColors autoload.

const ButtonFeedbackClass = preload("res://ui/components/button_feedback.gd")
const SimExplorationChallenges = preload("res://sim/exploration_challenges.gd")

signal choice_selected(choice_id: String, input_text: String)
signal event_skipped
signal challenge_completed(choice_id: String, evaluation: Dictionary)
signal challenge_failed(choice_id: String)

const TITLE_FONT_SIZE := 22  # No exact DesignSystem match
const BODY_FONT_SIZE := DesignSystem.FONT_BODY
const CHOICE_FONT_SIZE := DesignSystem.FONT_BODY_SMALL
const INPUT_FONT_SIZE := DesignSystem.FONT_H3
const FADE_DURATION := 0.2

var _current_event: Dictionary = {}
var _current_choice_id: String = ""
var _input_text: String = ""
var _panel_tween: Tween = null

# Challenge mode state
var _challenge_active: bool = false
var _challenge_data: Dictionary = {}
var _challenge_start_time: float = 0.0
var _challenge_input_config: Dictionary = {}

@onready var title_label: Label = $Content/TitleLabel
@onready var body_label: RichTextLabel = $Content/BodyLabel
@onready var choices_container: VBoxContainer = $Content/ChoicesContainer
@onready var input_container: HBoxContainer = $Content/InputContainer
@onready var input_prompt: Label = $Content/InputContainer/InputPrompt
@onready var input_display: Label = $Content/InputContainer/InputDisplay
@onready var skip_hint: Label = $Content/SkipHint

func _ready() -> void:
	visible = false
	_apply_styling()

func _exit_tree() -> void:
	if _panel_tween != null and _panel_tween.is_valid():
		_panel_tween.kill()

func _apply_styling() -> void:
	if title_label:
		title_label.add_theme_font_size_override("font_size", TITLE_FONT_SIZE)
		title_label.add_theme_color_override("font_color", ThemeColors.ACCENT)

	if body_label:
		body_label.add_theme_font_size_override("normal_font_size", BODY_FONT_SIZE)

	if input_prompt:
		input_prompt.add_theme_font_size_override("font_size", INPUT_FONT_SIZE)
		input_prompt.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)

	if input_display:
		input_display.add_theme_font_size_override("font_size", INPUT_FONT_SIZE)
		input_display.add_theme_color_override("font_color", ThemeColors.ACCENT)

	if skip_hint:
		skip_hint.add_theme_font_size_override("font_size", 12)
		skip_hint.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)

func show_event(event_data: Dictionary) -> void:
	_current_event = event_data
	_current_choice_id = ""
	_input_text = ""

	if title_label:
		title_label.text = str(event_data.get("title", "Event"))

	if body_label:
		body_label.text = str(event_data.get("body", ""))

	_build_choices(event_data.get("choices", []))
	_hide_input()

	_fade_in()

func _build_choices(choices: Array) -> void:
	if choices_container == null:
		return

	# Clear existing choice buttons
	for child in choices_container.get_children():
		child.queue_free()

	for choice in choices:
		if typeof(choice) != TYPE_DICTIONARY:
			continue
		var choice_id: String = str(choice.get("id", ""))
		var label: String = str(choice.get("label", ""))
		var input_config: Dictionary = choice.get("input", {})

		var btn := Button.new()
		btn.text = "[%s] %s" % [choice_id.to_upper(), label]
		btn.add_theme_font_size_override("font_size", CHOICE_FONT_SIZE)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.focus_mode = Control.FOCUS_ALL
		btn.pressed.connect(_on_choice_pressed.bind(choice_id, input_config))
		choices_container.add_child(btn)
		ButtonFeedbackClass.apply_to_button(btn)

	# Focus first button
	await get_tree().process_frame
	if choices_container.get_child_count() > 0:
		choices_container.get_child(0).grab_focus()

func _on_choice_pressed(choice_id: String, input_config: Dictionary) -> void:
	_current_choice_id = choice_id
	_input_text = ""
	var mode: String = str(input_config.get("mode", "code"))

	if mode == "code":
		var expected: String = str(input_config.get("text", ""))
		_show_input("Type: %s" % expected, expected)
	elif mode == "phrase":
		var expected: String = str(input_config.get("text", ""))
		_show_input("Type phrase:", expected)
	elif mode == "prompt_burst":
		var prompts: Array = input_config.get("prompts", [])
		var prompt_text: String = " ".join(prompts)
		_show_input("Type words:", prompt_text)
	elif mode == "command":
		var expected: String = str(input_config.get("text", ""))
		_show_input("Command:", expected)
	elif mode == "challenge":
		_challenge_input_config = input_config
		# Request challenge generation from parent (it has game state)
		choice_selected.emit(choice_id, "__CHALLENGE_START__")
	else:
		# No input required, submit immediately
		choice_selected.emit(choice_id, "")

func _show_input(prompt: String, expected: String) -> void:
	if input_container:
		input_container.visible = true
	if input_prompt:
		input_prompt.text = prompt
	if input_display:
		input_display.text = "_"
	if choices_container:
		choices_container.visible = false
	if skip_hint:
		skip_hint.text = "Press Escape to cancel"

func _hide_input() -> void:
	if input_container:
		input_container.visible = false
	if choices_container:
		choices_container.visible = true
	if skip_hint:
		skip_hint.text = "Press Escape to skip event"

func _input(event: InputEvent) -> void:
	if not visible:
		return

	# Handle escape to skip or cancel
	if event.is_action_pressed("ui_cancel"):
		if _challenge_active:
			# Forfeit challenge
			_forfeit_challenge()
		elif _current_choice_id != "":
			# Cancel current input, go back to choices
			_current_choice_id = ""
			_input_text = ""
			_hide_input()
			_build_choices(_current_event.get("choices", []))
		else:
			# Skip event
			event_skipped.emit()
		accept_event()
		return

	# Handle challenge mode input
	if _challenge_active and event is InputEventKey and event.is_pressed():
		if event.keycode == KEY_BACKSPACE:
			if _input_text.length() > 0:
				_input_text = _input_text.substr(0, _input_text.length() - 1)
				_show_challenge_display()
			accept_event()
		elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER or event.keycode == KEY_SPACE:
			# Submit current word
			if not _input_text.strip_edges().is_empty():
				_process_challenge_word()
			accept_event()
		elif event.unicode > 0:
			var char := String.chr(event.unicode)
			if char.length() == 1 and char != " ":
				_input_text += char
				_show_challenge_display()
			accept_event()
		return

	# Handle text input when in input mode (non-challenge)
	if _current_choice_id != "" and event is InputEventKey and event.is_pressed():
		if event.keycode == KEY_BACKSPACE:
			if _input_text.length() > 0:
				_input_text = _input_text.substr(0, _input_text.length() - 1)
				_update_input_display()
			accept_event()
		elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			# Submit input
			choice_selected.emit(_current_choice_id, _input_text)
			accept_event()
		elif event.unicode > 0:
			var char := String.chr(event.unicode)
			if char.length() == 1:
				_input_text += char
				_update_input_display()
			accept_event()

func _update_input_display() -> void:
	if input_display:
		if _input_text == "":
			input_display.text = "_"
		else:
			input_display.text = _input_text + "_"

func show_result(success: bool, message: String) -> void:
	if body_label:
		if success:
			body_label.text = "[color=#88cc88]%s[/color]" % message
		else:
			body_label.text = "[color=#cc8888]%s[/color]" % message

	if choices_container:
		choices_container.visible = false
	if input_container:
		input_container.visible = false
	if skip_hint:
		skip_hint.text = "Press any key to continue"

func hide_panel() -> void:
	_fade_out()

func _fade_in() -> void:
	if _panel_tween != null and _panel_tween.is_valid():
		_panel_tween.kill()
	visible = true
	modulate.a = 0.0
	_panel_tween = create_tween()
	_panel_tween.tween_property(self, "modulate:a", 1.0, FADE_DURATION)

func _fade_out() -> void:
	if _panel_tween != null and _panel_tween.is_valid():
		_panel_tween.kill()
	_panel_tween = create_tween()
	_panel_tween.tween_property(self, "modulate:a", 0.0, FADE_DURATION)
	_panel_tween.tween_callback(func(): visible = false)

func is_active() -> bool:
	return visible

func is_challenge_active() -> bool:
	return _challenge_active

func get_current_event() -> Dictionary:
	return _current_event

func get_challenge_input_config() -> Dictionary:
	return _challenge_input_config

func clear() -> void:
	_current_event = {}
	_current_choice_id = ""
	_input_text = ""
	_challenge_active = false
	_challenge_data = {}
	if title_label:
		title_label.text = ""
	if body_label:
		body_label.text = ""
	if choices_container:
		for child in choices_container.get_children():
			child.queue_free()
	_hide_input()


# =============================================================================
# TYPING CHALLENGE SUPPORT
# =============================================================================

## Start a typing challenge with the given challenge data
func start_challenge(challenge: Dictionary) -> void:
	_challenge_data = challenge
	_challenge_active = true
	_challenge_start_time = Time.get_unix_time_from_system()
	_input_text = ""

	# Start tracking in the challenge
	_challenge_data = SimExplorationChallenges.start_challenge(_challenge_data, _challenge_start_time)

	_show_challenge_display()


## Display the challenge UI
func _show_challenge_display() -> void:
	if choices_container:
		choices_container.visible = false
	if input_container:
		input_container.visible = true

	var words: Array = _challenge_data.get("words", [])
	var current_idx: int = int(_challenge_data.get("current_word_index", 0))
	var difficulty: String = str(_challenge_data.get("difficulty", "medium"))
	var time_limit: float = float(_challenge_data.get("time_limit", 60.0))

	# Build challenge display text
	var body_text: String = "[center][b]TYPING CHALLENGE[/b] - %s[/center]\n\n" % difficulty.to_upper()

	# Show words with highlighting for current word
	body_text += "Words: "
	for i in range(words.size()):
		var word: String = str(words[i])
		if i < current_idx:
			body_text += "[color=#88cc88]%s[/color] " % word  # Completed
		elif i == current_idx:
			body_text += "[color=#ffff88][b]%s[/b][/color] " % word  # Current
		else:
			body_text += "[color=#888888]%s[/color] " % word  # Upcoming

	body_text += "\n\nProgress: %d / %d words" % [current_idx, words.size()]
	body_text += "\nTime limit: %.0f seconds" % time_limit

	if body_label:
		body_label.text = body_text

	# Show current word prompt
	if current_idx < words.size():
		var current_word: String = str(words[current_idx])
		if input_prompt:
			input_prompt.text = "Type: %s" % current_word
	else:
		if input_prompt:
			input_prompt.text = "Challenge complete!"

	if input_display:
		input_display.text = "_" if _input_text == "" else _input_text + "_"

	if skip_hint:
		skip_hint.text = "Press Escape to forfeit challenge"


## Process a word typed during the challenge
func _process_challenge_word() -> void:
	if not _challenge_active or _challenge_data.is_empty():
		return

	var result: Dictionary = SimExplorationChallenges.process_word(_challenge_data, _input_text)
	_input_text = ""

	if result.get("accepted", false):
		var words_remaining: int = int(result.get("words_remaining", 0))
		if words_remaining <= 0:
			# Challenge complete!
			_complete_challenge()
		else:
			# Update display for next word
			_show_challenge_display()
	else:
		# Word not accepted (should still count as attempt in some modes)
		_show_challenge_display()


## Complete and evaluate the challenge
func _complete_challenge() -> void:
	if not _challenge_active:
		return

	var end_time: float = Time.get_unix_time_from_system()
	var evaluation: Dictionary = SimExplorationChallenges.evaluate_challenge(_challenge_data, end_time)

	# Show result
	var result_text: String = SimExplorationChallenges.get_result_description(evaluation)
	show_result(evaluation.get("passed", false), result_text)

	_challenge_active = false

	# Emit result
	challenge_completed.emit(_current_choice_id, evaluation)


## Forfeit the current challenge
func _forfeit_challenge() -> void:
	if not _challenge_active:
		return

	_challenge_active = false
	_challenge_data = {}

	show_result(false, "Challenge forfeited.")
	challenge_failed.emit(_current_choice_id)
