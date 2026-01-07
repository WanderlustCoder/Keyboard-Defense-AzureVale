extends Control

const TypingSystem = preload("res://scripts/TypingSystem.gd")
const SimWords = preload("res://sim/words.gd")
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
@onready var progression = get_node("/root/ProgressionState")
@onready var game_controller = get_node("/root/GameController")
@onready var audio_manager = get_node("/root/AudioManager")

var pause_panel: PanelContainer = null
var pause_label: Label = null
var pause_resume_button: Button = null
var pause_retreat_button: Button = null
var pause_button: Button = null

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

func _ready() -> void:
	exit_button.pressed.connect(_on_exit_pressed)
	result_button.pressed.connect(_on_result_pressed)
	result_panel.visible = false
	_setup_pause_panel()
	_setup_debug_panel()
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

func _process(delta: float) -> void:
	if not active:
		return
	if paused:
		return
	if debug_panel != null and debug_panel.visible:
		return
	_update_buffs(delta)
	_update_feedback(delta)
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
			if audio_manager != null:
				audio_manager.play_hit_player()
			if castle_health <= 0:
				_finish_battle(false)
				return
		_sync_threat_from_stage()
		# Adjust music intensity based on threat
		if audio_manager != null:
			audio_manager.set_battle_intensity(threat >= 70.0)
	else:
		_set_threat(min(100.0, threat + delta * threat_rate))
		if threat >= 100.0:
			castle_health -= 1
			_set_threat(25.0)
			if castle_health <= 0:
				_finish_battle(false)
				return
	_update_threat()

func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			_toggle_pause()
			return
		if event.keycode == KEY_F1:
			_toggle_debug_panel()
			return
	if paused:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if tutorial_mode and drill_mode == "intermission" and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER):
			_skip_intermission()
			return
	if debug_panel != null and debug_panel.visible:
		return
	if not drill_input_enabled:
		return
	if event is InputEventKey and event.pressed and not event.echo:
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
	if status == "error":
		_reset_streaks()
		if audio_manager != null:
			audio_manager.play_type_mistake()
			audio_manager.play_combo_break()
	else:
		_advance_streaks(status)
		if audio_manager != null:
			audio_manager.play_type_correct()
	_check_buff_triggers()
	_update_feedback_for_status(status)
	_apply_typing_combat(status)
	if status == "lesson_complete":
		_complete_drill()
		return
	_update_word_display()
	_update_stats()
	_update_threat()
	_update_drill_status()

func _update_word_display() -> void:
	if drill_mode == "intermission":
		word_label.text = "Target: --"
		typed_label.text = "Typed: --"
		drill_target_label.text = ""
		return
	var current_word: String = typing_system.get_current_word()
	word_label.text = "Target: %s" % current_word
	typed_label.text = "Typed: %s" % typing_system.typed
	drill_target_label.text = _format_target_bbcode(current_word, typing_system.typed)

func _update_stats() -> void:
	var stats: Dictionary = _collect_battle_stats(true)
	var accuracy: int = int(round(float(stats.get("accuracy", 1.0)) * 100.0))
	var wpm: int = int(round(float(stats.get("wpm", 0.0))))
	var errors: int = int(stats.get("errors", 0))
	accuracy_label.text = "Accuracy: %d%%" % accuracy
	wpm_label.text = "WPM: %d" % wpm
	mistakes_label.text = "Errors: %d" % errors

func _update_threat() -> void:
	threat_bar.value = threat
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
		return ["guard", "tower", "shield", "banner", "castle"]

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

	# Fallback if generation failed
	if words.is_empty():
		return ["guard", "tower", "shield", "banner", "castle"]

	return words

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
		result_button.text = "Return to Map"
	else:
		progression.record_attempt(summary)
		# Play defeat sounds
		if audio_manager != null:
			audio_manager.play_defeat()
		var lines: Array = ["Defeat. The walls fell.", stats_line, words_line]
		result_label.text = "\n".join(lines)
		result_action = "retry"
		result_button.text = "Retry Battle"
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
	if status == "word_complete" or status == "lesson_complete":
		word_streak += 1

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
