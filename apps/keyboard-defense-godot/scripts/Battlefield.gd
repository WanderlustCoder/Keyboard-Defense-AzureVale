extends Control

const TypingSystem = preload("res://scripts/TypingSystem.gd")
const SimWords = preload("res://sim/words.gd")
const BattleTutorial = preload("res://scripts/BattleTutorial.gd")
const DEFAULT_RUNE_TARGETS := ["1-2-3", "x^2", "go!", "rune+1", "shield+2"]
const BUFF_DEFS := {
	"focus": {
		"label": "Focus Surge",
		"duration": 8.0,
		"typing_power_multiplier": 1.25
	},
	"ward": {
		"label": "Ward of Calm",
		"duration": 8.0,
		"threat_rate_multiplier": 0.75
	}
}
const BUFF_WORD_STREAK := 4
const BUFF_INPUT_STREAK := 24
const FEEDBACK_DURATION := 0.75
const FEEDBACK_ERROR_DURATION := 0.6
const FEEDBACK_WAVE_DURATION := 1.1
const FEEDBACK_BUFF_DURATION := 0.9

## Returns true if event is a non-repeating key press
func _is_key_pressed(event: InputEvent) -> bool:
	return event is InputEventKey and event.pressed and not event.echo

@onready var lesson_label: Label = $TopBar/LessonLabel
@onready var gold_label: Label = $TopBar/GoldLabel
@onready var exit_button: Button = $TopBar/ExitButton
@onready var word_label: Label = $TypingPanel/Content/TypingReadout/WordLabel
@onready var typed_label: Label = $TypingPanel/Content/TypingReadout/TypedLabel
@onready var accuracy_label: Label = $StatusPanel/Content/AccuracyLabel
@onready var wpm_label: Label = $StatusPanel/Content/WpmLabel
@onready var mistakes_label: Label = $StatusPanel/Content/MistakesLabel
@onready var threat_bar: ProgressBar = $StatusPanel/Content/ThreatBar
@onready var castle_label: Label = $StatusPanel/Content/CastleLabel
@onready var bonus_label: Label = $BonusPanel/Content/BonusLabel
@onready var drill_title_label: Label = $TypingPanel/Content/DrillTitle
@onready var drill_target_label: RichTextLabel = $TypingPanel/Content/DrillTarget
@onready var feedback_label: Label = $TypingPanel/Content/FeedbackLabel
@onready var drill_progress_label: Label = $TargetsLabel
@onready var drill_hint_label: Label = $TypingPanel/Content/DrillHint
@onready var battle_stage: Control = $PlayField/BattleStage
@onready var buff_hud: PanelContainer = $PlayField/BuffHud
@onready var buff_focus_row: HBoxContainer = $PlayField/BuffHud/Content/FocusRow
@onready var buff_focus_label: Label = $PlayField/BuffHud/Content/FocusRow/FocusLabel
@onready var buff_focus_bar: ProgressBar = $PlayField/BuffHud/Content/FocusRow/FocusBar
@onready var buff_ward_row: HBoxContainer = $PlayField/BuffHud/Content/WardRow
@onready var buff_ward_label: Label = $PlayField/BuffHud/Content/WardRow/WardLabel
@onready var buff_ward_bar: ProgressBar = $PlayField/BuffHud/Content/WardRow/WardBar
@onready var result_panel: PanelContainer = $ResultPanel
@onready var result_label: Label = $ResultPanel/Content/ResultLabel
@onready var result_button: Button = $ResultPanel/Content/ResultButton
var result_retry_button: Button = null
var result_hint_label: Label = null
@onready var progression = get_node("/root/ProgressionState")
@onready var game_controller = get_node("/root/GameController")
@onready var audio_manager = get_node_or_null("/root/AudioManager")
@onready var settings_manager = get_node_or_null("/root/SettingsManager")

var pause_panel: PanelContainer = null
var pause_label: Label = null
var pause_resume_button: Button = null
var pause_retreat_button: Button = null
var pause_button: Button = null
var pause_settings_container: VBoxContainer = null
var pause_music_slider: HSlider = null
var pause_sfx_slider: HSlider = null
var pause_shake_toggle: CheckButton = null

var debug_panel: PanelContainer = null
var debug_text: TextEdit = null
var debug_status_label: Label = null
var debug_apply_button: Button = null
var debug_copy_button: Button = null
var debug_close_button: Button = null
var debug_overrides: Dictionary = {}

var typing_system: TypingSystem = TypingSystem.new()
var node_id: String = ""
var node_label: String = ""
var lesson_id: String = ""
var words: Array = []
var lesson_words: Array = []
var drill_plan: Array = []
var drill_index: int = -1
var drill_mode: String = ""
var drill_label: String = ""
var drill_timer: float = 0.0
var drill_word_goal: int = 0
var drill_input_enabled: bool = true
var current_drill: Dictionary = {}

var tutorial_mode: bool = false
var paused: bool = false
var syncing_threat: bool = false

var threat: float = 0.0
var threat_rate: float = 8.0
var threat_relief: float = 12.0
var mistake_penalty: float = 18.0
var castle_health: int = 3
var typing_power: float = 1.0
var mistake_forgiveness: float = 0.0
var base_typing_power: float = 1.0
var base_threat_rate_multiplier: float = 1.0
var base_mistake_forgiveness: float = 0.0
var base_castle_health: int = 3
var base_threat_rate: float = 8.0
var base_threat_relief: float = 12.0
var base_mistake_penalty: float = 18.0
var base_modifiers: Dictionary = {}
var active_buffs: Array = []
var buff_modifiers := {
	"typing_power_multiplier": 1.0,
	"threat_rate_multiplier": 1.0,
	"mistake_forgiveness_bonus": 0.0
}
var input_streak: int = 0
var word_streak: int = 0
var feedback_timer: float = 0.0

var battle_start_time_ms: int = 0
var battle_total_inputs: int = 0
var battle_correct_inputs: int = 0
var battle_errors: int = 0
var battle_words_completed: int = 0

var active = true
var result_action = "map"
var battle_tutorial: BattleTutorial = null

# Screen shake state
var _shake_intensity: float = 0.0
var _shake_duration: float = 0.0
var _shake_initial_duration: float = 0.0
var _shake_offset: Vector2 = Vector2.ZERO
const SHAKE_DECAY := 5.0

# UI caching to avoid redundant updates
var _cached_threat: float = -1.0
var _cached_castle_health: int = -1
var _cached_accuracy: int = -1
var _cached_wpm: int = -1
var _cached_errors: int = -1
var _cached_current_word: String = ""
var _cached_typed: String = ""
var _cached_drill_mode: String = ""

# Combo indicator
var combo_label: Label = null
var _combo_pulse_timer: float = 0.0
var _combo_scale: float = 1.0
const COMBO_PULSE_DURATION := 0.15

# Error shake animation
var _error_shake_tween: Tween = null
var _typed_label_base_pos: Vector2 = Vector2.ZERO
const ERROR_SHAKE_INTENSITY := 4.0
const ERROR_SHAKE_DURATION := 0.15

func _ready() -> void:
	exit_button.pressed.connect(_on_exit_pressed)
	result_button.pressed.connect(_on_result_pressed)
	result_panel.visible = false
	_setup_pause_panel()
	_setup_debug_panel()
	_setup_combo_indicator()
	_setup_result_panel()
	# Store base position for error shake animation
	if typed_label != null:
		_typed_label_base_pos = typed_label.position
	_initialize_battle()

func _initialize_battle() -> void:
	node_id = game_controller.next_battle_node_id
	if node_id == "":
		game_controller.go_to_map()
		return
	var node: Dictionary = progression.map_nodes.get(node_id, {})
	node_label = str(node.get("label", "Battle"))
	lesson_id = str(node.get("lesson_id", ""))
	var lesson: Dictionary = progression.get_lesson(lesson_id)
	lesson_words = lesson.get("words", [])
	if lesson_words.is_empty():
		lesson_words = _generate_words_from_lesson(lesson, node_id)

	var modifiers: Dictionary = progression.get_combat_modifiers()
	base_modifiers = modifiers.duplicate(true)
	base_typing_power = float(modifiers.get("typing_power", 1.0))
	base_threat_rate_multiplier = float(modifiers.get("threat_rate_multiplier", 1.0))
	base_mistake_forgiveness = float(modifiers.get("mistake_forgiveness", 0.0))
	base_castle_health = 3 + int(modifiers.get("castle_health_bonus", 0))
	base_threat_rate = 8.0
	base_threat_relief = 12.0
	base_mistake_penalty = 18.0
	castle_health = base_castle_health
	_set_threat(0.0)
	active_buffs.clear()
	_reset_streaks()
	_clear_feedback()
	_recompute_buff_modifiers()
	_recompute_combat_values()
	if battle_stage != null:
		battle_stage.reset()
	tutorial_mode = progression.completed_nodes.size() == 0

	battle_start_time_ms = Time.get_ticks_msec()
	battle_total_inputs = 0
	battle_correct_inputs = 0
	battle_errors = 0
	battle_words_completed = 0
	# Reset UI caches to force initial update
	_cached_threat = -1.0
	_cached_castle_health = -1
	_cached_accuracy = -1
	_cached_wpm = -1
	_cached_errors = -1
	drill_plan = _build_drill_plan(node, lesson)
	drill_index = -1

	lesson_label.text = "%s - %s" % [node_label, lesson.get("label", "Lesson")]
	gold_label.text = "Gold: %d" % progression.gold
	_refresh_bonus_label(base_modifiers)
	_update_buff_hud()
	_start_next_drill()
	_update_threat()
	# Start battle music
	if audio_manager != null:
		audio_manager.switch_to_battle_music(false)

	# Initialize battle tutorial for first-time players
	_setup_battle_tutorial()

func _setup_battle_tutorial() -> void:
	if battle_tutorial != null:
		battle_tutorial.cleanup()
		battle_tutorial.queue_free()
		battle_tutorial = null

	battle_tutorial = BattleTutorial.new()
	add_child(battle_tutorial)
	battle_tutorial.initialize(self)
	battle_tutorial.tutorial_finished.connect(_on_tutorial_finished)

	if battle_tutorial.is_active():
		progression.mark_battle_started()
		# Delay tutorial start slightly so player sees the battlefield
		await get_tree().create_timer(0.5).timeout
		battle_tutorial.start()

func _on_tutorial_finished() -> void:
	# Tutorial complete, continue normally
	pass

func _process(delta: float) -> void:
	if not active:
		return
	if paused:
		return
	if debug_panel != null and debug_panel.visible:
		return
	_update_buffs(delta)
	_update_feedback(delta)
	_update_screen_shake(delta)
	_update_combo_indicator(delta)
	if drill_mode == "intermission":
		drill_timer = max(0.0, drill_timer - delta)
		if battle_stage != null:
			battle_stage.advance(delta, 0.0)
			battle_stage.apply_relief(threat_relief * 0.4 * delta)
			_sync_threat_from_stage()
		else:
			_set_threat(max(0.0, threat - delta * threat_relief * 0.4))
		_update_threat()
		_update_drill_status()
		if drill_timer <= 0.0:
			_start_next_drill()
		return
	if battle_stage != null:
		battle_stage.advance(delta, threat_rate)
		if battle_stage.consume_breach():
			castle_health -= 1
			battle_stage.reset_after_breach()
			battle_stage.spawn_castle_damage_effect()
			_trigger_screen_shake(12.0, 0.3)
			if audio_manager != null:
				audio_manager.play_hit_player()
			# Tutorial trigger for castle damage
			if battle_tutorial != null:
				battle_tutorial.fire_trigger("castle_damaged")
			if castle_health <= 0:
				_finish_battle(false)
				return
		_sync_threat_from_stage()
		# Adjust music intensity based on threat
		if audio_manager != null:
			audio_manager.set_battle_intensity(threat >= 70.0)
		# Tutorial trigger for threat shown
		if threat > 20.0 and battle_tutorial != null:
			battle_tutorial.fire_trigger("threat_shown")
	else:
		_set_threat(min(100.0, threat + delta * threat_rate))
		if threat >= 100.0:
			castle_health -= 1
			_set_threat(25.0)
			_trigger_screen_shake(12.0, 0.3)
			# Tutorial trigger for castle damage
			if battle_tutorial != null:
				battle_tutorial.fire_trigger("castle_damaged")
			if castle_health <= 0:
				_finish_battle(false)
				return
	_update_threat()

func _unhandled_input(event: InputEvent) -> void:
	# Handle result panel shortcuts
	if result_panel != null and result_panel.visible:
		if _is_key_pressed(event):
			if event.keycode == KEY_R:
				_on_result_retry_pressed()
				return
			if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
				_on_result_pressed()
				return
			if event.keycode == KEY_ESCAPE:
				if audio_manager != null:
					audio_manager.play_ui_cancel()
				game_controller.go_to_map()
				return
		return

	if not active:
		return
	if _is_key_pressed(event):
		if event.keycode == KEY_ESCAPE:
			_toggle_pause()
			return
		if event.keycode == KEY_F1:
			_toggle_debug_panel()
			return
	if paused:
		return
	# Block typing input while tutorial dialogue is showing
	if battle_tutorial != null and battle_tutorial.is_dialogue_open():
		return
	if _is_key_pressed(event):
		if tutorial_mode and drill_mode == "intermission" and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER):
			_skip_intermission()
			return
	if debug_panel != null and debug_panel.visible:
		return
	if not drill_input_enabled:
		return
	if _is_key_pressed(event):
		if event.keycode == KEY_BACKSPACE:
			typing_system.backspace()
			_update_word_display()
			return
		if event.unicode == 0:
			return
		var char_text: String = char(event.unicode)
		var result: Dictionary = typing_system.input_char(char_text)
		_handle_typing_result(result)

func _handle_typing_result(result: Dictionary) -> void:
	var status: String = str(result.get("status", ""))
	if status == "ignored":
		return
	var typing_sounds_enabled: bool = settings_manager == null or settings_manager.typing_sounds
	if status == "error":
		_reset_streaks()
		if audio_manager != null and typing_sounds_enabled:
			audio_manager.play_type_mistake()
			audio_manager.play_combo_break()
		_trigger_error_shake()
	else:
		_advance_streaks(status)
		if audio_manager != null and typing_sounds_enabled:
			audio_manager.play_type_correct()
	_check_buff_triggers()
	_update_feedback_for_status(status)
	_apply_typing_combat(status)
	if status == "lesson_complete":
		_complete_drill()
		return
	# Tutorial trigger for first word typed
	if status == "word_complete" and battle_tutorial != null:
		battle_tutorial.fire_trigger("first_word_typed")
	_update_word_display()
	_update_stats()
	_update_threat()
	_update_drill_status()

func _update_word_display() -> void:
	# Handle intermission state change
	if drill_mode == "intermission":
		if _cached_drill_mode != "intermission":
			_cached_drill_mode = "intermission"
			word_label.text = "Target: --"
			typed_label.text = "Typed: --"
			drill_target_label.text = ""
		return

	# Only update if mode, word, or typed text changed
	var current_word: String = typing_system.get_current_word()
	var typed_text: String = typing_system.typed
	if _cached_drill_mode == drill_mode and _cached_current_word == current_word and _cached_typed == typed_text:
		return

	_cached_drill_mode = drill_mode
	_cached_current_word = current_word
	_cached_typed = typed_text
	word_label.text = "Target: %s" % current_word
	typed_label.text = "Typed: %s" % typed_text
	drill_target_label.text = _format_target_bbcode(current_word, typed_text)

func _update_stats() -> void:
	var stats: Dictionary = _collect_battle_stats(true)
	var accuracy: int = int(round(float(stats.get("accuracy", 1.0)) * 100.0))
	var wpm: int = int(round(float(stats.get("wpm", 0.0))))
	var errors: int = int(stats.get("errors", 0))
	# Only update UI if values changed
	if accuracy != _cached_accuracy:
		_cached_accuracy = accuracy
		accuracy_label.text = "Accuracy: %d%%" % accuracy
	if wpm != _cached_wpm:
		_cached_wpm = wpm
		wpm_label.text = "WPM: %d" % wpm
	if errors != _cached_errors:
		_cached_errors = errors
		mistakes_label.text = "Errors: %d" % errors

func _update_threat() -> void:
	# Only update UI if values changed
	if threat != _cached_threat:
		_cached_threat = threat
		threat_bar.value = threat
	if castle_health != _cached_castle_health:
		_cached_castle_health = castle_health
		castle_label.text = "Castle Health: %d" % castle_health

func _update_feedback(delta: float) -> void:
	if feedback_label == null or feedback_timer <= 0.0:
		return
	feedback_timer = max(0.0, feedback_timer - delta)
	if feedback_timer <= 0.0:
		feedback_label.text = ""
		feedback_label.visible = false

func _clear_feedback() -> void:
	feedback_timer = 0.0
	if feedback_label != null:
		feedback_label.text = ""
		feedback_label.visible = false

func _update_feedback_for_status(status: String) -> void:
	if status == "error":
		_show_feedback("Missed!", Color(0.96, 0.45, 0.45, 1), FEEDBACK_ERROR_DURATION)
	elif status == "word_complete":
		_show_feedback("Strike!", Color(0.98, 0.84, 0.44, 1))
		if audio_manager != null:
			audio_manager.play_combo_up()
	elif status == "lesson_complete":
		_show_feedback("Wave Cleared!", Color(0.65, 0.86, 1, 1), FEEDBACK_WAVE_DURATION)
		if audio_manager != null:
			audio_manager.play_wave_end()

func _show_feedback(message: String, color: Color, duration: float = FEEDBACK_DURATION) -> void:
	if feedback_label == null:
		return
	feedback_label.text = message
	feedback_label.visible = message != ""
	feedback_label.modulate = color
	feedback_timer = max(0.0, duration)

func _set_threat(value: float, sync_stage: bool = true) -> void:
	var clamped = clamp(value, 0.0, 100.0)
	threat = clamped
	if sync_stage and not syncing_threat and battle_stage != null:
		battle_stage.set_progress_percent(clamped)

func _sync_threat_from_stage() -> void:
	if battle_stage == null:
		return
	syncing_threat = true
	_set_threat(battle_stage.get_progress_percent(), false)
	syncing_threat = false

func _apply_typing_combat(status: String) -> void:
	if battle_stage == null:
		_apply_typing_threat_fallback(status)
		return
	if status == "error":
		battle_stage.apply_penalty(mistake_penalty)
		battle_stage.apply_relief(threat_relief * 0.2)
	elif status == "progress":
		battle_stage.apply_relief(threat_relief * 0.2)
	elif status == "word_complete":
		battle_stage.apply_relief(threat_relief)
		battle_stage.spawn_projectile(false)
	elif status == "lesson_complete":
		battle_stage.apply_relief(threat_relief)
		battle_stage.spawn_projectile(true)
	_sync_threat_from_stage()

func _apply_typing_threat_fallback(status: String) -> void:
	if status == "error":
		_set_threat(min(100.0, threat + mistake_penalty))
	if status == "progress" or status == "error":
		_set_threat(max(0.0, threat - threat_relief * 0.2))
	if status == "word_complete" or status == "lesson_complete":
		_set_threat(max(0.0, threat - threat_relief))

func _start_next_drill() -> void:
	drill_index += 1
	if drill_index >= drill_plan.size():
		_finish_battle(true)
		return
	current_drill = drill_plan[drill_index]
	_reset_streaks()
	drill_mode = str(current_drill.get("mode", "lesson"))
	drill_label = str(current_drill.get("label", "Drill"))
	drill_input_enabled = drill_mode != "intermission"
	drill_timer = 0.0
	drill_word_goal = 0
	lesson_label.text = "%s - %s" % [node_label, drill_label]
	if drill_mode == "intermission":
		drill_timer = float(current_drill.get("duration", 2.5))
		words = []
		typing_system.start([])
	else:
		var targets: Array = _build_drill_targets(current_drill, drill_mode)
		if targets.is_empty():
			targets = lesson_words.duplicate()
		words = targets
		var config: Dictionary = _build_typing_config(current_drill)
		typing_system.start(targets, config)
		drill_word_goal = targets.size()
		# Play wave start sound for new drill
		if audio_manager != null:
			audio_manager.play_wave_start()
	_update_word_display()
	_update_stats()
	_update_drill_status()

func _complete_drill() -> void:
	if drill_index + 1 >= drill_plan.size():
		_finish_battle(true)
		return
	# Tutorial trigger when approaching victory (last drill)
	if drill_index + 2 >= drill_plan.size() and battle_tutorial != null:
		battle_tutorial.fire_trigger("near_victory")
	_record_drill_stats()
	_start_next_drill()

func _record_drill_stats() -> void:
	battle_total_inputs += typing_system.total_inputs
	battle_correct_inputs += typing_system.correct_inputs
	battle_errors += typing_system.errors
	battle_words_completed += typing_system.get_words_completed()

func _collect_battle_stats(include_current: bool) -> Dictionary:
	var total_inputs = battle_total_inputs
	var correct_inputs = battle_correct_inputs
	var errors = battle_errors
	var words_completed = battle_words_completed
	if include_current:
		total_inputs += typing_system.total_inputs
		correct_inputs += typing_system.correct_inputs
		errors += typing_system.errors
		words_completed += typing_system.get_words_completed()
	var accuracy: float = 1.0
	if total_inputs > 0:
		accuracy = float(correct_inputs) / float(total_inputs)
	var elapsed_ms: int = Time.get_ticks_msec() - battle_start_time_ms
	var elapsed_seconds: float = max(0.001, float(elapsed_ms) / 1000.0)
	var wpm: float = float(words_completed) / (elapsed_seconds / 60.0)
	return {
		"accuracy": accuracy,
		"wpm": wpm,
		"errors": errors,
		"words_completed": words_completed,
		"total_inputs": total_inputs,
		"correct_inputs": correct_inputs
	}

func _build_drill_plan(node: Dictionary, lesson: Dictionary) -> Array:
	var base_plan: Array = []
	var inline_plan = node.get("drill_plan", [])
	if inline_plan is Array and inline_plan.size() > 0:
		base_plan = inline_plan
	var template_id := str(node.get("drill_template", ""))
	if base_plan.is_empty() and template_id != "":
		var template: Dictionary = progression.get_drill_template(template_id)
		var template_plan = template.get("plan", [])
		if template_plan is Array and template_plan.size() > 0:
			base_plan = template_plan
	if base_plan.is_empty():
		base_plan = _build_default_drill_plan(node, lesson)
	var resolved: Array = base_plan.duplicate(true)
	var overrides = node.get("drill_overrides", {})
	if overrides is Dictionary:
		resolved = _apply_drill_overrides(resolved, overrides)
	return resolved

func _apply_drill_overrides(base_plan: Array, overrides: Dictionary) -> Array:
	var plan: Array = base_plan.duplicate(true)
	if overrides.is_empty():
		return plan
	var replace_list: Array = overrides.get("replace", [])
	if replace_list is Array:
		for entry in replace_list:
			if entry is Dictionary:
				var index: int = int(entry.get("index", -1))
				if index >= 0 and index < plan.size():
					var step = entry.get("step", {})
					if step is Dictionary:
						plan[index] = step
	var step_overrides: Array = overrides.get("steps", [])
	if step_overrides is Array:
		for entry in step_overrides:
			if entry is Dictionary:
				var index: int = int(entry.get("index", -1))
				if index < 0 or index >= plan.size():
					continue
				var data = entry.get("data", {})
				if data is Dictionary:
					var base_step = plan[index]
					if base_step is Dictionary:
						var merged: Dictionary = base_step.duplicate(true)
						for key in data.keys():
							merged[key] = data[key]
						plan[index] = merged
	var remove_list: Array = overrides.get("remove", [])
	if remove_list is Array and remove_list.size() > 0:
		var remove_sorted: Array = []
		for raw in remove_list:
			remove_sorted.append(int(raw))
		remove_sorted.sort()
		for i in range(remove_sorted.size() - 1, -1, -1):
			var index: int = int(remove_sorted[i])
			if index >= 0 and index < plan.size():
				plan.remove_at(index)
	var prepend_steps: Array = overrides.get("prepend", [])
	if prepend_steps is Array and prepend_steps.size() > 0:
		var new_plan: Array = []
		for step in prepend_steps:
			new_plan.append(step)
		for step in plan:
			new_plan.append(step)
		plan = new_plan
	var append_steps: Array = overrides.get("append", [])
	if append_steps is Array and append_steps.size() > 0:
		for step in append_steps:
			plan.append(step)
	return plan

func _build_default_drill_plan(node: Dictionary, lesson: Dictionary) -> Array:
	var warmup_count: int = min(4, lesson_words.size())
	var main_count: int = min(6, lesson_words.size())
	var lesson_label_text := str(lesson.get("label", "Defense Drill"))
	var rune_targets: Array = node.get("rune_targets", DEFAULT_RUNE_TARGETS)
	return [
		{
			"mode": "lesson",
			"label": "Warmup Runes",
			"word_count": warmup_count,
			"shuffle": true
		},
		{
			"mode": "intermission",
			"label": "Scouts Regroup",
			"duration": 2.5,
			"message": "Scouts regroup and the ward recharges."
		},
		{
			"mode": "targets",
			"label": "Rune Marks",
			"targets": rune_targets
		},
		{
			"mode": "lesson",
			"label": lesson_label_text,
			"word_count": main_count,
			"shuffle": true
		}
	]

func _build_drill_targets(drill: Dictionary, mode: String) -> Array:
	if mode == "lesson":
		var selection: Array = lesson_words.duplicate()
		var shuffle_words = bool(drill.get("shuffle", false))
		if shuffle_words:
			selection.shuffle()
		var count: int = int(drill.get("word_count", selection.size()))
		if count > 0 and count < selection.size():
			selection = selection.slice(0, count)
		return selection
	if mode == "targets":
		var targets: Array = drill.get("targets", [])
		return targets
	return []

func _build_typing_config(drill: Dictionary) -> Dictionary:
	var config: Dictionary = {}
	if bool(drill.get("case_sensitive", false)):
		config["case_sensitive"] = true
	if bool(drill.get("allow_spaces", false)):
		config["allow_spaces"] = true
	var allowed_chars: String = str(drill.get("allowed_chars", ""))
	if allowed_chars != "":
		config["allowed_chars"] = allowed_chars
	return config

func _update_drill_status() -> void:
	var step: int = drill_index + 1
	var total: int = drill_plan.size()
	if total <= 0:
		total = 1
	var title_text := "%s (%d/%d)" % [drill_label, step, total]
	drill_title_label.text = title_text
	if drill_mode == "intermission":
		drill_progress_label.text = "Resuming in %.1fs" % drill_timer
		var hint_text := str(current_drill.get("message", "Scouts regroup."))
		if tutorial_mode:
			hint_text += " Press Space to skip."
		drill_hint_label.text = hint_text
		return
	var words_completed: int = typing_system.get_words_completed()
	drill_progress_label.text = "Targets: %d/%d" % [words_completed, drill_word_goal]
	drill_hint_label.text = str(current_drill.get("hint", "Type the runes to strike."))

func _format_target_bbcode(target: String, typed_text: String) -> String:
	var remaining := ""
	if target.length() >= typed_text.length():
		remaining = target.substr(typed_text.length())
	var safe_typed = _escape_bbcode(typed_text)
	var safe_remaining = _escape_bbcode(remaining)
	return "[center][color=#ffd27a]" + safe_typed + "[/color][color=#e6ecff]" + safe_remaining + "[/color][/center]"

func _escape_bbcode(text: String) -> String:
	var escaped := text.replace("[", "\\[")
	escaped = escaped.replace("]", "\\]")
	return escaped

func _generate_words_from_lesson(lesson: Dictionary, seed_id: String) -> Array:
	# Generate words from lesson charset and lengths using SimWords
	var charset: String = str(lesson.get("charset", "")).to_lower()
	if charset == "":
		return _generate_fallback_words("")

	var lengths: Dictionary = lesson.get("lengths", {})
	var words: Array = []
	var used: Dictionary = {}
	var word_count: int = 20  # Generate enough words for drills

	# Generate words for each enemy type to cover different lengths
	var kinds: Array = ["scout", "raider", "armored"]
	var per_kind: int = ceili(float(word_count) / float(kinds.size()))

	for kind in kinds:
		for i in range(per_kind):
			var word: String = SimWords.word_for_enemy(seed_id, 1, kind, i, used, lesson.get("id", ""))
			if word != "" and not used.has(word):
				words.append(word)
				used[word] = true

	# Fallback if generation failed - use charset-based words
	if words.is_empty():
		return _generate_fallback_words(charset)

	return words

func _generate_fallback_words(charset: String) -> Array:
	# Common short words organized by the letters they primarily use
	const WORD_POOL := {
		"asdfjkl": ["ask", "lad", "lass", "flask", "salad", "add", "fall", "sad", "jak"],
		"gh": ["ash", "gash", "hag", "shag", "dash", "flash", "glad", "half"],
		"qwertyuiop": ["quit", "rope", "type", "wire", "power", "write", "equip", "quiet"],
		"zxcvbnm": ["mix", "box", "zinc", "climb", "comb", "blank", "calm", "clam"],
		"": ["guard", "tower", "shield", "banner", "castle", "knight", "sword", "armor"]
	}

	if charset == "":
		return WORD_POOL[""]

	var result: Array = []
	var charset_lower := charset.to_lower()

	# Collect words that match the charset
	for pool_charset in WORD_POOL.keys():
		if pool_charset == "":
			continue
		# Check if any charset letters match this pool
		var match_score := 0
		for c in pool_charset:
			if c in charset_lower:
				match_score += 1
		if match_score > 0:
			for word in WORD_POOL[pool_charset]:
				# Verify word only uses charset letters
				var valid := true
				for letter in word:
					if letter not in charset_lower:
						valid = false
						break
				if valid and word not in result:
					result.append(word)

	# If no matches, generate simple patterns from charset
	if result.is_empty():
		var chars := charset_lower.split("")
		for i in range(min(10, chars.size())):
			var c: String = chars[i % chars.size()]
			result.append(c + c)  # Double letter like "aa", "ss"
			if i + 1 < chars.size():
				result.append(chars[i] + chars[i + 1])  # Two letter combo

	# Ensure we have at least 5 words
	if result.size() < 5:
		result.append_array(WORD_POOL[""])

	return result

func _finish_battle(success: bool) -> void:
	active = false
	paused = false
	if pause_panel != null:
		pause_panel.visible = false
	var stats: Dictionary = _collect_battle_stats(true)
	var accuracy: float = float(stats.get("accuracy", 1.0))
	var wpm: float = float(stats.get("wpm", 0.0))
	var errors: int = int(stats.get("errors", 0))
	var words_completed: int = int(stats.get("words_completed", 0))
	var accuracy_percent = int(round(accuracy * 100.0))
	var wpm_value = int(round(wpm))
	var stats_line = "Accuracy: %d%% | WPM: %d | Errors: %d" % [accuracy_percent, wpm_value, errors]
	var words_line = "Words: %d" % words_completed
	var summary: Dictionary = {
		"node_id": node_id,
		"node_label": node_label,
		"lesson_id": lesson_id,
		"accuracy": accuracy,
		"wpm": wpm,
		"errors": errors,
		"words_completed": words_completed,
		"completed": success,
		"drill_step": drill_index + 1,
		"drill_total": drill_plan.size()
	}
	if success:
		var completed_summary: Dictionary = progression.complete_node(node_id, summary)
		var tier := str(completed_summary.get("performance_tier", ""))
		var bonus := int(completed_summary.get("performance_bonus", 0))
		var practice_gold = int(completed_summary.get("practice_gold", 0))
		var reward_gold = int(completed_summary.get("reward_gold", 0))
		var gold_awarded = int(completed_summary.get("gold_awarded", 0))
		# Play victory sounds
		if audio_manager != null:
			audio_manager.play_victory()
		var lines: Array = ["Victory! The castle stands strong."]
		if tier != "":
			lines.append("Rank: %s" % tier)
		lines.append(stats_line)
		lines.append(words_line)
		var gold_parts: Array = []
		if reward_gold > 0:
			gold_parts.append("Node %dg" % reward_gold)
		if practice_gold > 0:
			gold_parts.append("Practice %dg" % practice_gold)
		if bonus > 0:
			gold_parts.append("Bonus %dg" % bonus)
		if gold_awarded > 0:
			if gold_parts.is_empty():
				lines.append("Gold: +%dg" % gold_awarded)
			else:
				lines.append("Gold: +%dg (%s)" % [gold_awarded, ", ".join(gold_parts)])
		result_label.text = "\n".join(lines)
		result_action = "map"
		result_button.text = "Continue (Enter)"
		if result_retry_button != null:
			result_retry_button.visible = true
			result_retry_button.text = "Retry (R)"
	else:
		progression.record_attempt(summary)
		# Play defeat sounds
		if audio_manager != null:
			audio_manager.play_defeat()
		var lines: Array = ["Defeat. The walls fell.", stats_line, words_line]
		result_label.text = "\n".join(lines)
		result_action = "retry"
		result_button.text = "Retry (Enter)"
		if result_retry_button != null:
			result_retry_button.visible = true
			result_retry_button.text = "Map (Esc)"
			result_retry_button.pressed.disconnect(_on_result_retry_pressed)
			result_retry_button.pressed.connect(_go_to_map_from_result)
	result_panel.visible = true
	gold_label.text = "Gold: %d" % progression.gold

func _on_result_pressed() -> void:
	if audio_manager != null:
		audio_manager.play_ui_confirm()
	if result_action == "retry":
		game_controller.go_to_battle(node_id)
	else:
		game_controller.go_to_map()

func _on_exit_pressed() -> void:
	if paused:
		return
	if audio_manager != null:
		audio_manager.play_ui_cancel()
	game_controller.go_to_map()

func _format_bonus_text(modifiers: Dictionary) -> String:
	var typing_power_bonus: int = int(round((float(modifiers.get("typing_power", 1.0)) - 1.0) * 100.0))
	var threat_rate_bonus: int = int(round((1.0 - float(modifiers.get("threat_rate_multiplier", 1.0))) * 100.0))
	var forgiveness_bonus: int = int(round(float(modifiers.get("mistake_forgiveness", 0.0)) * 100.0))
	var parts: Array = []
	if typing_power_bonus != 0:
		parts.append("Typing Power %+d%%" % typing_power_bonus)
	if threat_rate_bonus != 0:
		parts.append("Threat Slow %+d%%" % threat_rate_bonus)
	if forgiveness_bonus != 0:
		parts.append("Mistake Forgiveness %+d%%" % forgiveness_bonus)
	if int(modifiers.get("castle_health_bonus", 0)) > 0:
		parts.append("Castle +%d" % int(modifiers.get("castle_health_bonus", 0)))
	if parts.is_empty():
		return "Bonuses: None"
	return "Bonuses: " + ", ".join(parts)

func _format_buffs_text() -> String:
	if active_buffs.is_empty():
		return "Buffs: None"
	var entries: Array = []
	for buff in active_buffs:
		if buff is Dictionary:
			var buff_id := str(buff.get("id", ""))
			var remaining: float = float(buff.get("remaining", 0.0))
			var label := _get_buff_label(buff_id)
			entries.append("%s (%.1fs)" % [label, max(0.0, remaining)])
	return "Buffs: " + ", ".join(entries)

func _refresh_bonus_label(modifiers: Dictionary) -> void:
	if bonus_label == null:
		return
	var base_text := _format_bonus_text(modifiers)
	var buff_text := _format_buffs_text()
	bonus_label.text = "%s\n%s" % [base_text, buff_text]

func _setup_pause_panel() -> void:
	pause_panel = get_node_or_null("PausePanel") as PanelContainer
	if pause_panel == null:
		return
	pause_panel.visible = false
	pause_label = pause_panel.get_node("Content/PauseLabel") as Label
	pause_resume_button = pause_panel.get_node("Content/ButtonRow/ResumeButton") as Button
	pause_retreat_button = pause_panel.get_node("Content/ButtonRow/RetreatButton") as Button
	pause_button = get_node_or_null("TopBar/PauseButton") as Button
	if pause_resume_button != null:
		pause_resume_button.pressed.connect(_on_pause_resume_pressed)
	if pause_retreat_button != null:
		pause_retreat_button.pressed.connect(_on_pause_retreat_pressed)
	if pause_button != null:
		pause_button.pressed.connect(_on_pause_pressed)
	_add_pause_settings()

func _add_pause_settings() -> void:
	var content = pause_panel.get_node_or_null("Content") as VBoxContainer
	if content == null:
		return

	# Create settings container
	pause_settings_container = VBoxContainer.new()
	pause_settings_container.add_theme_constant_override("separation", 8)

	# Separator
	var sep = HSeparator.new()
	sep.add_theme_constant_override("separation", 8)
	pause_settings_container.add_child(sep)

	# Settings label
	var settings_title = Label.new()
	settings_title.text = "Quick Settings"
	settings_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	settings_title.add_theme_font_size_override("font_size", 14)
	settings_title.add_theme_color_override("font_color", Color(0.65, 0.7, 0.82, 1))
	pause_settings_container.add_child(settings_title)

	# Music volume
	var music_row = _create_slider_row("Music", 0.0, 1.0, _get_music_volume())
	pause_music_slider = music_row.get_node("Slider") as HSlider
	if pause_music_slider != null:
		pause_music_slider.value_changed.connect(_on_pause_music_changed)
	pause_settings_container.add_child(music_row)

	# SFX volume
	var sfx_row = _create_slider_row("SFX", 0.0, 1.0, _get_sfx_volume())
	pause_sfx_slider = sfx_row.get_node("Slider") as HSlider
	if pause_sfx_slider != null:
		pause_sfx_slider.value_changed.connect(_on_pause_sfx_changed)
	pause_settings_container.add_child(sfx_row)

	# Screen shake toggle
	var shake_row = HBoxContainer.new()
	shake_row.add_theme_constant_override("separation", 12)
	var shake_label = Label.new()
	shake_label.text = "Screen Shake"
	shake_label.add_theme_font_size_override("font_size", 13)
	shake_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shake_row.add_child(shake_label)
	pause_shake_toggle = CheckButton.new()
	pause_shake_toggle.button_pressed = settings_manager != null and settings_manager.screen_shake
	pause_shake_toggle.toggled.connect(_on_pause_shake_toggled)
	shake_row.add_child(pause_shake_toggle)
	pause_settings_container.add_child(shake_row)

	# Insert before button row
	content.add_child(pause_settings_container)
	content.move_child(pause_settings_container, content.get_child_count() - 1)

func _create_slider_row(label_text: String, min_val: float, max_val: float, current_val: float) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var label = Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 13)
	label.custom_minimum_size = Vector2(60, 0)
	row.add_child(label)

	var slider = HSlider.new()
	slider.name = "Slider"
	slider.min_value = min_val
	slider.max_value = max_val
	slider.step = 0.05
	slider.value = current_val
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size = Vector2(120, 0)
	row.add_child(slider)

	return row

func _get_music_volume() -> float:
	if audio_manager != null and audio_manager.has_method("get_music_volume"):
		return audio_manager.get_music_volume()
	return 0.8

func _get_sfx_volume() -> float:
	if audio_manager != null and audio_manager.has_method("get_sfx_volume"):
		return audio_manager.get_sfx_volume()
	return 0.8

func _on_pause_music_changed(value: float) -> void:
	if audio_manager != null and audio_manager.has_method("set_music_volume"):
		audio_manager.set_music_volume(value)

func _on_pause_sfx_changed(value: float) -> void:
	if audio_manager != null and audio_manager.has_method("set_sfx_volume"):
		audio_manager.set_sfx_volume(value)

func _on_pause_shake_toggled(pressed: bool) -> void:
	if settings_manager != null:
		settings_manager.screen_shake = pressed
		settings_manager.save_settings()

func _on_pause_pressed() -> void:
	if audio_manager != null:
		audio_manager.play_ui_confirm()
	_toggle_pause()

func _on_pause_resume_pressed() -> void:
	if audio_manager != null:
		audio_manager.play_ui_confirm()
	_set_paused(false)

func _on_pause_retreat_pressed() -> void:
	if audio_manager != null:
		audio_manager.play_ui_cancel()
	game_controller.go_to_map()

func _toggle_pause() -> void:
	if not active or result_panel.visible:
		return
	_set_paused(not paused)

func _set_paused(value: bool) -> void:
	paused = value
	if pause_panel != null:
		pause_panel.visible = paused

func _skip_intermission() -> void:
	if drill_mode != "intermission":
		return
	_start_next_drill()

func _reset_streaks() -> void:
	input_streak = 0
	word_streak = 0

func _advance_streaks(status: String) -> void:
	if status == "progress" or status == "word_complete" or status == "lesson_complete":
		input_streak += 1
		_pulse_combo_indicator()
	if status == "word_complete" or status == "lesson_complete":
		word_streak += 1
		_pulse_combo_indicator()

func _check_buff_triggers() -> void:
	if word_streak >= BUFF_WORD_STREAK:
		_activate_buff("focus")
		word_streak = 0
	if input_streak >= BUFF_INPUT_STREAK:
		_activate_buff("ward")
		input_streak = 0

func _activate_buff(buff_id: String) -> void:
	if not BUFF_DEFS.has(buff_id):
		return
	var definition: Dictionary = BUFF_DEFS[buff_id]
	var duration: float = float(definition.get("duration", 0.0))
	var refreshed := false
	for buff in active_buffs:
		if buff is Dictionary and str(buff.get("id", "")) == buff_id:
			buff["remaining"] = duration
			refreshed = true
			break
	if not refreshed:
		active_buffs.append({"id": buff_id, "remaining": duration})
		# Tutorial trigger for combo buff achieved
		if battle_tutorial != null:
			battle_tutorial.fire_trigger("combo_achieved")
	_apply_buff_changes()
	var buff_color := Color(0.98, 0.84, 0.44, 1)
	if buff_id == "ward":
		buff_color = Color(0.65, 0.86, 1, 1)
	_show_feedback("%s!" % _get_buff_label(buff_id), buff_color, FEEDBACK_BUFF_DURATION)

func _update_buffs(delta: float) -> void:
	if active_buffs.is_empty():
		return
	var changed := false
	for i in range(active_buffs.size() - 1, -1, -1):
		var buff = active_buffs[i]
		if not buff is Dictionary:
			active_buffs.remove_at(i)
			changed = true
			continue
		var remaining: float = float(buff.get("remaining", 0.0))
		remaining -= delta
		if remaining <= 0.0:
			active_buffs.remove_at(i)
			changed = true
		else:
			buff["remaining"] = remaining
	if changed:
		_apply_buff_changes()
	else:
		_refresh_bonus_label(base_modifiers)
	_update_buff_hud()

func _recompute_buff_modifiers() -> void:
	buff_modifiers = {
		"typing_power_multiplier": 1.0,
		"threat_rate_multiplier": 1.0,
		"mistake_forgiveness_bonus": 0.0
	}
	for buff in active_buffs:
		if not buff is Dictionary:
			continue
		var buff_id := str(buff.get("id", ""))
		if not BUFF_DEFS.has(buff_id):
			continue
		var definition: Dictionary = BUFF_DEFS[buff_id]
		for key in buff_modifiers.keys():
			if not definition.has(key):
				continue
			var value: float = float(definition.get(key, 0.0))
			if key == "mistake_forgiveness_bonus":
				buff_modifiers[key] = float(buff_modifiers[key]) + value
			else:
				buff_modifiers[key] = float(buff_modifiers[key]) * value

func _apply_buff_changes() -> void:
	_recompute_buff_modifiers()
	_recompute_combat_values()
	_refresh_bonus_label(base_modifiers)
	_update_buff_hud()

func _update_buff_hud() -> void:
	if buff_hud == null:
		return
	if active_buffs.is_empty():
		buff_hud.visible = false
		if buff_focus_row != null:
			buff_focus_row.visible = false
		if buff_ward_row != null:
			buff_ward_row.visible = false
		return
	buff_hud.visible = true
	_update_single_buff_row("focus", buff_focus_row, buff_focus_label, buff_focus_bar)
	_update_single_buff_row("ward", buff_ward_row, buff_ward_label, buff_ward_bar)

func _update_single_buff_row(buff_id: String, row, label, bar) -> void:
	if row == null or label == null or bar == null:
		return
	var buff := _get_active_buff(buff_id)
	if buff.is_empty():
		row.visible = false
		bar.value = 0.0
		return
	var definition: Dictionary = BUFF_DEFS.get(buff_id, {})
	var duration: float = float(definition.get("duration", 1.0))
	var remaining: float = float(buff.get("remaining", 0.0))
	var ratio: float = 0.0
	if duration > 0.0:
		ratio = clamp(remaining / duration, 0.0, 1.0)
	row.visible = true
	bar.value = ratio
	label.text = "%s %.1fs" % [_get_buff_label(buff_id), max(0.0, remaining)]

func _get_active_buff(buff_id: String) -> Dictionary:
	for buff in active_buffs:
		if buff is Dictionary and str(buff.get("id", "")) == buff_id:
			return buff
	return {}

func _recompute_combat_values() -> void:
	var typing_multiplier: float = float(buff_modifiers.get("typing_power_multiplier", 1.0))
	var threat_multiplier: float = float(buff_modifiers.get("threat_rate_multiplier", 1.0))
	var forgiveness_bonus: float = float(buff_modifiers.get("mistake_forgiveness_bonus", 0.0))
	typing_power = base_typing_power * typing_multiplier
	mistake_forgiveness = clamp(base_mistake_forgiveness + forgiveness_bonus, 0.0, 0.8)
	threat_rate = base_threat_rate * base_threat_rate_multiplier * threat_multiplier
	threat_relief = base_threat_relief * typing_power
	mistake_penalty = base_mistake_penalty * (1.0 - mistake_forgiveness)

func _get_buff_label(buff_id: String) -> String:
	if BUFF_DEFS.has(buff_id):
		var definition: Dictionary = BUFF_DEFS[buff_id]
		return str(definition.get("label", buff_id))
	return buff_id

func _setup_debug_panel() -> void:
	debug_panel = get_node_or_null("DebugPanel") as PanelContainer
	if debug_panel == null:
		return
	debug_panel.visible = false
	debug_text = debug_panel.get_node("Content/OverridesText") as TextEdit
	debug_status_label = debug_panel.get_node("Content/StatusLabel") as Label
	debug_apply_button = debug_panel.get_node("Content/ButtonRow/ApplyButton") as Button
	debug_copy_button = debug_panel.get_node("Content/ButtonRow/CopyButton") as Button
	debug_close_button = debug_panel.get_node("Content/ButtonRow/CloseButton") as Button
	debug_apply_button.pressed.connect(_on_debug_apply_pressed)
	debug_copy_button.pressed.connect(_on_debug_copy_pressed)
	debug_close_button.pressed.connect(_on_debug_close_pressed)

func _toggle_debug_panel() -> void:
	if debug_panel == null:
		return
	debug_panel.visible = not debug_panel.visible
	if debug_panel.visible:
		_sync_debug_text_from_node()
		debug_panel.raise()

func _sync_debug_text_from_node() -> void:
	if debug_text == null:
		return
	var node: Dictionary = progression.map_nodes.get(node_id, {})
	var overrides = node.get("drill_overrides", {})
	if overrides is Dictionary:
		debug_overrides = overrides
	else:
		debug_overrides = {}
	debug_text.text = JSON.stringify(debug_overrides, "\t")
	if debug_status_label != null:
		debug_status_label.text = "Editing overrides for %s." % node_id

func _on_debug_apply_pressed() -> void:
	if debug_text == null:
		return
	var parsed = JSON.parse_string(debug_text.text)
	if parsed == null or typeof(parsed) != TYPE_DICTIONARY:
		if debug_status_label != null:
			debug_status_label.text = "Invalid JSON. Expected an object."
		return
	debug_overrides = parsed
	_apply_debug_overrides(debug_overrides)
	if debug_status_label != null:
		debug_status_label.text = "Overrides applied to %s." % node_id

func _apply_debug_overrides(overrides: Dictionary) -> void:
	var node: Dictionary = progression.map_nodes.get(node_id, {})
	var updated: Dictionary = node.duplicate(true)
	updated["drill_overrides"] = overrides
	progression.map_nodes[node_id] = updated
	active = true
	result_panel.visible = false
	_initialize_battle()

func _on_debug_copy_pressed() -> void:
	if debug_overrides.is_empty():
		_sync_debug_text_from_node()
	var payload := JSON.stringify(debug_overrides, "\t")
	DisplayServer.clipboard_set(payload)
	if debug_status_label != null:
		debug_status_label.text = "Overrides copied to clipboard."

func _on_debug_close_pressed() -> void:
	if debug_panel != null:
		debug_panel.visible = false

func _trigger_error_shake() -> void:
	# Visual shake on typing error for feedback
	if typed_label == null:
		return
	# Check if screen shake is enabled in settings (respects user preference)
	if settings_manager != null and not settings_manager.screen_shake:
		return

	# Kill existing tween if running
	if _error_shake_tween != null and _error_shake_tween.is_valid():
		_error_shake_tween.kill()
		typed_label.position = _typed_label_base_pos

	# Create shake animation using tween
	_error_shake_tween = create_tween()
	var shake_time := ERROR_SHAKE_DURATION / 4.0

	# Quick shake left-right-center
	_error_shake_tween.tween_property(typed_label, "position",
		_typed_label_base_pos + Vector2(-ERROR_SHAKE_INTENSITY, 0), shake_time)
	_error_shake_tween.tween_property(typed_label, "position",
		_typed_label_base_pos + Vector2(ERROR_SHAKE_INTENSITY, 0), shake_time)
	_error_shake_tween.tween_property(typed_label, "position",
		_typed_label_base_pos + Vector2(-ERROR_SHAKE_INTENSITY * 0.5, 0), shake_time)
	_error_shake_tween.tween_property(typed_label, "position",
		_typed_label_base_pos, shake_time)

	# Also flash the label red briefly
	var original_color: Color = typed_label.modulate
	typed_label.modulate = Color(1.0, 0.5, 0.5, 1.0)
	await get_tree().create_timer(ERROR_SHAKE_DURATION).timeout
	if typed_label != null:
		typed_label.modulate = original_color

func _trigger_screen_shake(intensity: float, duration: float) -> void:
	# Check if screen shake is enabled in settings
	if settings_manager != null and not settings_manager.screen_shake:
		return
	_shake_intensity = intensity
	_shake_duration = duration
	_shake_initial_duration = duration

func _update_screen_shake(delta: float) -> void:
	if _shake_duration <= 0.0:
		if _shake_offset != Vector2.ZERO:
			position -= _shake_offset
			_shake_offset = Vector2.ZERO
		return

	_shake_duration -= delta
	# Use stored initial duration for consistent decay across different shake durations
	var decay_factor := _shake_duration / _shake_initial_duration if _shake_initial_duration > 0.0 else 0.0
	var current_intensity := _shake_intensity * decay_factor

	# Remove previous offset
	position -= _shake_offset

	# Calculate new offset
	_shake_offset = Vector2(
		randf_range(-current_intensity, current_intensity),
		randf_range(-current_intensity, current_intensity)
	)

	# Apply new offset
	position += _shake_offset

	if _shake_duration <= 0.0:
		position -= _shake_offset
		_shake_offset = Vector2.ZERO

func _setup_combo_indicator() -> void:
	combo_label = Label.new()
	combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	combo_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	combo_label.add_theme_font_size_override("font_size", 16)
	combo_label.add_theme_color_override("font_color", Color(0.98, 0.84, 0.44, 0.9))
	combo_label.visible = false
	combo_label.pivot_offset = Vector2(40, 10)  # Center for scaling
	add_child(combo_label)
	# Position near the drill target
	combo_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	combo_label.position = Vector2(-40, 95)
	combo_label.custom_minimum_size = Vector2(80, 20)

func _update_combo_indicator(delta: float) -> void:
	if combo_label == null:
		return

	var total_streak := input_streak + word_streak * 2
	if total_streak < 3:
		combo_label.visible = false
		return

	combo_label.visible = true

	# Determine combo tier and color
	var combo_text := ""
	var combo_color := Color(0.98, 0.84, 0.44, 0.9)  # Gold

	if total_streak >= 30:
		combo_text = "BLAZING x%d" % total_streak
		combo_color = Color(1.0, 0.5, 0.2, 1.0)  # Orange
	elif total_streak >= 20:
		combo_text = "HOT x%d" % total_streak
		combo_color = Color(0.98, 0.84, 0.44, 1.0)  # Gold
	elif total_streak >= 10:
		combo_text = "COMBO x%d" % total_streak
		combo_color = Color(0.65, 0.86, 1.0, 0.95)  # Cyan
	else:
		combo_text = "x%d" % total_streak
		combo_color = Color(0.75, 0.75, 0.82, 0.85)  # Silver

	combo_label.text = combo_text
	combo_label.add_theme_color_override("font_color", combo_color)

	# Handle pulse animation
	if _combo_pulse_timer > 0.0:
		_combo_pulse_timer -= delta
		var pulse_progress := 1.0 - (_combo_pulse_timer / COMBO_PULSE_DURATION)
		_combo_scale = 1.0 + (1.0 - pulse_progress) * 0.3  # Start big, shrink to normal
		combo_label.scale = Vector2(_combo_scale, _combo_scale)
	else:
		combo_label.scale = Vector2(1.0, 1.0)

func _pulse_combo_indicator() -> void:
	_combo_pulse_timer = COMBO_PULSE_DURATION

func _setup_result_panel() -> void:
	if result_panel == null:
		return

	var content = result_panel.get_node_or_null("Content")
	if content == null:
		return

	# Create button row container
	var button_row = HBoxContainer.new()
	button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	button_row.add_theme_constant_override("separation", 16)

	# Move existing button to row
	var button_parent = result_button.get_parent()
	button_parent.remove_child(result_button)
	button_row.add_child(result_button)

	# Create retry button
	result_retry_button = Button.new()
	result_retry_button.text = "Retry (R)"
	result_retry_button.custom_minimum_size = Vector2(140, 44)
	result_retry_button.pressed.connect(_on_result_retry_pressed)
	button_row.add_child(result_retry_button)

	content.add_child(button_row)

	# Create keyboard hint label
	result_hint_label = Label.new()
	result_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_hint_label.add_theme_font_size_override("font_size", 12)
	result_hint_label.add_theme_color_override("font_color", Color(0.65, 0.7, 0.82, 0.8))
	result_hint_label.text = "Press Enter to continue, R to retry, Esc for map"
	content.add_child(result_hint_label)

func _on_result_retry_pressed() -> void:
	if audio_manager != null:
		audio_manager.play_ui_confirm()
	game_controller.go_to_battle(node_id)

func _go_to_map_from_result() -> void:
	if audio_manager != null:
		audio_manager.play_ui_cancel()
	game_controller.go_to_map()
