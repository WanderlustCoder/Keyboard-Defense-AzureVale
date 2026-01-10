extends Node
class_name BattleTutorial
## Manages tutorial prompts during the first battle via Lyra dialogue

signal tutorial_step_completed(step_id: String)
signal tutorial_finished

enum Step {
	WELCOME,
	TYPING_TARGET,
	THREAT_METER,
	CASTLE_HEALTH,
	COMBO_BUFFS,
	VICTORY_HINT,
	COMPLETE
}

const LYRA_DIALOGUE_SCENE := preload("res://ui/components/lyra_dialogue.tscn")

const TUTORIAL_STEPS := {
	Step.WELCOME: {
		"id": "welcome",
		"lines": [
			{"speaker": "Lyra", "text": "Welcome, defender! I'm Lyra, your typing instructor."},
			{"speaker": "Lyra", "text": "Enemies approach from the right. Type the words above them to deal damage!"},
			{"speaker": "Lyra", "text": "Let's begin your training. Watch the target word below."}
		]
	},
	Step.TYPING_TARGET: {
		"id": "typing_target",
		"lines": [
			{"speaker": "Lyra", "text": "See the word displayed? Type it exactly as shown."},
			{"speaker": "Lyra", "text": "Correct letters turn blue. Mistakes show in red."},
			{"speaker": "Lyra", "text": "Complete words to damage enemies. Try it now!"}
		],
		"trigger": "first_word_typed"
	},
	Step.THREAT_METER: {
		"id": "threat_meter",
		"lines": [
			{"speaker": "Lyra", "text": "Well done! Notice the Threat bar on the right."},
			{"speaker": "Lyra", "text": "Threat rises over time. If it fills, enemies attack your castle!"},
			{"speaker": "Lyra", "text": "Type quickly to keep threat low and protect your home."}
		],
		"trigger": "threat_shown"
	},
	Step.CASTLE_HEALTH: {
		"id": "castle_health",
		"lines": [
			{"speaker": "Lyra", "text": "Your castle has limited health. Guard it well!"},
			{"speaker": "Lyra", "text": "If castle health reaches zero, the battle is lost."},
			{"speaker": "Lyra", "text": "Upgrades can increase your castle's durability later."}
		],
		"trigger": "castle_damaged"
	},
	Step.COMBO_BUFFS: {
		"id": "combo_buffs",
		"lines": [
			{"speaker": "Lyra", "text": "Excellent typing! Keep up the streak for bonuses."},
			{"speaker": "Lyra", "text": "Typing accurately in sequence builds combo power."},
			{"speaker": "Lyra", "text": "Combos grant temporary buffs like Focus Surge!"}
		],
		"trigger": "combo_achieved"
	},
	Step.VICTORY_HINT: {
		"id": "victory_hint",
		"lines": [
			{"speaker": "Lyra", "text": "You're doing great! Complete all drill targets to win."},
			{"speaker": "Lyra", "text": "Victory earns gold for kingdom upgrades."},
			{"speaker": "Lyra", "text": "I believe in you, defender. Show them your skill!"}
		],
		"trigger": "near_victory"
	},
	Step.COMPLETE: {
		"id": "complete",
		"lines": [
			{"speaker": "Lyra", "text": "Tutorial complete! You've learned the basics."},
			{"speaker": "Lyra", "text": "Keep practicing to improve your WPM and accuracy."},
			{"speaker": "Lyra", "text": "Return to the kingdom to spend your gold. Good luck!"}
		]
	}
}

const ThemeColors = preload("res://ui/theme_colors.gd")

var _current_step: int = Step.WELCOME
var _dialogue: LyraDialogue = null
var _active: bool = false
var _paused: bool = false
var _triggers_fired: Dictionary = {}
var _parent_control: Control = null
var _progress_panel: PanelContainer = null
var _progress_dots: Array[ColorRect] = []

const DOT_SIZE := 8.0
const DOT_GAP := 6.0
const DOT_COLOR_COMPLETE := Color(0.4, 0.85, 0.5, 1.0)  # Green
const DOT_COLOR_CURRENT := Color(1.0, 0.85, 0.2, 1.0)   # Yellow/gold (pulsing)
const DOT_COLOR_PENDING := Color(0.35, 0.4, 0.5, 0.6)   # Dim gray

@onready var progression = get_node_or_null("/root/ProgressionState")

func initialize(parent: Control) -> void:
	_parent_control = parent
	if progression != null and not progression.should_show_battle_tutorial():
		_active = false
		return

	_active = true
	_setup_dialogue()

func _setup_dialogue() -> void:
	if _parent_control == null:
		return

	_dialogue = LYRA_DIALOGUE_SCENE.instantiate() as LyraDialogue
	_parent_control.add_child(_dialogue)
	_dialogue.dialogue_finished.connect(_on_dialogue_finished)
	_setup_progress_panel()

func _setup_progress_panel() -> void:
	if _parent_control == null:
		return

	_progress_panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.12, 0.18, 0.9)
	style.border_color = ThemeColors.ACCENT_BLUE
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(8)
	_progress_panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	_progress_panel.add_child(vbox)

	# Top row: icon + label + skip hint
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	vbox.add_child(hbox)

	var icon = Label.new()
	icon.text = "📖"
	icon.add_theme_font_size_override("font_size", 14)
	hbox.add_child(icon)

	var label = Label.new()
	label.name = "ProgressLabel"
	label.text = "Tutorial: Step 1/7"
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	hbox.add_child(label)

	var skip_hint = Label.new()
	skip_hint.text = "[ESC to skip]"
	skip_hint.add_theme_font_size_override("font_size", 10)
	skip_hint.add_theme_color_override("font_color", Color(0.5, 0.55, 0.65, 0.7))
	hbox.add_child(skip_hint)

	# Bottom row: progress dots
	var dots_container = HBoxContainer.new()
	dots_container.name = "DotsContainer"
	dots_container.add_theme_constant_override("separation", int(DOT_GAP))
	dots_container.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(dots_container)

	# Create dots for each step (Step.COMPLETE + 1 = 7 total steps)
	_progress_dots.clear()
	var total_steps := Step.COMPLETE + 1
	for i in range(total_steps):
		var dot := ColorRect.new()
		dot.custom_minimum_size = Vector2(DOT_SIZE, DOT_SIZE)
		dot.color = DOT_COLOR_PENDING
		dots_container.add_child(dot)
		_progress_dots.append(dot)

	_parent_control.add_child(_progress_panel)
	# Position in top-right corner
	_progress_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_progress_panel.position = Vector2(-220, 8)
	_progress_panel.visible = false

func _update_progress_display() -> void:
	if _progress_panel == null:
		return

	# Update text label
	var vbox = _progress_panel.get_child(0) as VBoxContainer
	var label: Label = null
	if vbox != null:
		var hbox = vbox.get_child(0) as HBoxContainer
		if hbox != null:
			label = hbox.get_node_or_null("ProgressLabel") as Label

	if label != null:
		var step_num := _current_step + 1
		var total := Step.COMPLETE + 1
		label.text = "Tutorial: Step %d/%d" % [step_num, total]

	# Update progress dots
	for i in range(_progress_dots.size()):
		var dot := _progress_dots[i]
		if i < _current_step:
			# Completed step - green
			dot.color = DOT_COLOR_COMPLETE
		elif i == _current_step:
			# Current step - yellow/gold
			dot.color = DOT_COLOR_CURRENT
		else:
			# Pending step - dim gray
			dot.color = DOT_COLOR_PENDING

	_progress_panel.visible = _active

func start() -> void:
	if not _active or _dialogue == null:
		return

	_update_progress_display()
	_show_step(Step.WELCOME)

func _show_step(step: int) -> void:
	if not _active or _dialogue == null:
		return

	_current_step = step
	_update_progress_display()
	var step_data: Dictionary = TUTORIAL_STEPS.get(step, {})
	var lines: Array = step_data.get("lines", [])

	if lines.is_empty():
		_advance_step()
		return

	# Queue all lines
	for i in range(lines.size()):
		var line: Dictionary = lines[i]
		var speaker: String = str(line.get("speaker", "Lyra"))
		var text: String = str(line.get("text", ""))
		if i == 0:
			_dialogue.show_dialogue(speaker, text)
		else:
			_dialogue.queue_dialogue(speaker, text)

func _on_dialogue_finished() -> void:
	var step_data: Dictionary = TUTORIAL_STEPS.get(_current_step, {})
	var step_id: String = str(step_data.get("id", ""))
	tutorial_step_completed.emit(step_id)

	# Check if this step has a trigger requirement for next step
	var next_step := _current_step + 1
	if next_step < Step.COMPLETE:
		var next_data: Dictionary = TUTORIAL_STEPS.get(next_step, {})
		var trigger: String = str(next_data.get("trigger", ""))
		if trigger != "" and not _triggers_fired.has(trigger):
			# Wait for trigger before showing next step
			return

	_advance_step()

func _advance_step() -> void:
	_current_step += 1
	if _current_step > Step.COMPLETE:
		_finish_tutorial()
		return

	if _current_step == Step.COMPLETE:
		_show_step(Step.COMPLETE)
	else:
		# Check if trigger has been fired
		var step_data: Dictionary = TUTORIAL_STEPS.get(_current_step, {})
		var trigger: String = str(step_data.get("trigger", ""))
		if trigger == "" or _triggers_fired.has(trigger):
			_show_step(_current_step)

func fire_trigger(trigger_name: String) -> void:
	if not _active:
		return

	_triggers_fired[trigger_name] = true

	# Check if we're waiting for this trigger
	var step_data: Dictionary = TUTORIAL_STEPS.get(_current_step, {})
	var expected_trigger: String = str(step_data.get("trigger", ""))

	if expected_trigger == trigger_name and not _dialogue.is_active():
		_show_step(_current_step)

func _finish_tutorial() -> void:
	_active = false
	if _progress_panel != null:
		_progress_panel.visible = false
	if progression != null:
		progression.mark_tutorial_completed()
	tutorial_finished.emit()

func is_active() -> bool:
	return _active

func is_dialogue_open() -> bool:
	return _dialogue != null and _dialogue.is_active()

func skip_tutorial() -> void:
	if _dialogue != null:
		_dialogue.skip_all()
	_finish_tutorial()

func pause_tutorial() -> void:
	_paused = true

func resume_tutorial() -> void:
	_paused = false

func cleanup() -> void:
	if _dialogue != null:
		_dialogue.queue_free()
		_dialogue = null
	if _progress_panel != null:
		_progress_panel.queue_free()
		_progress_panel = null
	_progress_dots.clear()
