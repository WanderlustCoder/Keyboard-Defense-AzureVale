extends Control

const TypingSystem = preload("res://scripts/TypingSystem.gd")
const DEFAULT_RUNE_TARGETS := ["1-2-3", "x^2", "go!", "rune+1", "shield+2"]

@onready var lesson_label: Label = $TopBar/LessonLabel
@onready var gold_label: Label = $TopBar/GoldLabel
@onready var exit_button: Button = $TopBar/ExitButton
@onready var word_label: Label = $StatusPanel/Content/WordLabel
@onready var typed_label: Label = $StatusPanel/Content/TypedLabel
@onready var accuracy_label: Label = $StatusPanel/Content/AccuracyLabel
@onready var wpm_label: Label = $StatusPanel/Content/WpmLabel
@onready var mistakes_label: Label = $StatusPanel/Content/MistakesLabel
@onready var threat_bar: ProgressBar = $ThreatPanel/ThreatBar
@onready var castle_label: Label = $ThreatPanel/CastleLabel
@onready var bonus_label: Label = $BonusPanel/BonusLabel
@onready var drill_title_label: Label = $PlayField/DrillHud/DrillTitle
@onready var drill_target_label: RichTextLabel = $PlayField/DrillHud/DrillTarget
@onready var drill_progress_label: Label = $PlayField/DrillHud/DrillProgress
@onready var drill_hint_label: Label = $PlayField/DrillHud/DrillHint
@onready var result_panel: PanelContainer = $ResultPanel
@onready var result_label: Label = $ResultPanel/Content/ResultLabel
@onready var result_button: Button = $ResultPanel/Content/ResultButton
@onready var progression = get_node("/root/ProgressionState")
@onready var game_controller = get_node("/root/GameController")

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

var threat: float = 0.0
var threat_rate: float = 8.0
var threat_relief: float = 12.0
var mistake_penalty: float = 18.0
var castle_health: int = 3
var typing_power: float = 1.0
var mistake_forgiveness: float = 0.0
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
		lesson_words = ["guard", "tower", "shield", "banner", "castle"]

	var modifiers: Dictionary = progression.get_combat_modifiers()
	typing_power = float(modifiers.get("typing_power", 1.0))
	var threat_rate_multiplier: float = float(modifiers.get("threat_rate_multiplier", 1.0))
	mistake_forgiveness = float(modifiers.get("mistake_forgiveness", 0.0))
	castle_health = 3 + int(modifiers.get("castle_health_bonus", 0))
	threat_rate = 8.0 * threat_rate_multiplier
	threat_relief = 12.0 * typing_power
	mistake_penalty = 18.0 * (1.0 - mistake_forgiveness)

	battle_start_time_ms = Time.get_ticks_msec()
	battle_total_inputs = 0
	battle_correct_inputs = 0
	battle_errors = 0
	battle_words_completed = 0
	drill_plan = _build_drill_plan(node, lesson)
	drill_index = -1

	lesson_label.text = "%s - %s" % [node_label, lesson.get("label", "Lesson")]
	gold_label.text = "Gold: %d" % progression.gold
	bonus_label.text = _format_bonus_text(modifiers)
	_start_next_drill()
	_update_threat()

func _process(delta: float) -> void:
	if not active:
		return
	if drill_mode == "intermission":
		drill_timer = max(0.0, drill_timer - delta)
		threat = max(0.0, threat - delta * threat_relief * 0.4)
		_update_threat()
		_update_drill_status()
		if drill_timer <= 0.0:
			_start_next_drill()
		return
	threat = min(100.0, threat + delta * threat_rate)
	if threat >= 100.0:
		castle_health -= 1
		threat = 25.0
		if castle_health <= 0:
			_finish_battle(false)
			return
	_update_threat()

func _unhandled_input(event: InputEvent) -> void:
	if not active:
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
		threat = min(100.0, threat + mistake_penalty)
	if status == "progress" or status == "error":
		threat = max(0.0, threat - threat_relief * 0.2)
	if status == "word_complete":
		threat = max(0.0, threat - threat_relief)
	if status == "lesson_complete":
		threat = max(0.0, threat - threat_relief)
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

func _start_next_drill() -> void:
	drill_index += 1
	if drill_index >= drill_plan.size():
		_finish_battle(true)
		return
	current_drill = drill_plan[drill_index]
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
	var plan = node.get("drill_plan", [])
	if plan is Array and plan.size() > 0:
		return plan
	var template_id := str(node.get("drill_template", ""))
	if template_id != "":
		var template: Dictionary = progression.get_drill_template(template_id)
		var template_plan = template.get("plan", [])
		if template_plan is Array and template_plan.size() > 0:
			return template_plan
	return _build_default_drill_plan(node, lesson)

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
		drill_hint_label.text = str(current_drill.get("message", "Scouts regroup."))
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
	return "[color=#f6d37a]" + safe_typed + "[/color][color=#9aa0b4]" + safe_remaining + "[/color]"

func _escape_bbcode(text: String) -> String:
	var escaped := text.replace("[", "\\[")
	escaped = escaped.replace("]", "\\]")
	return escaped

func _finish_battle(success: bool) -> void:
	active = false
	var stats: Dictionary = _collect_battle_stats(true)
	var accuracy: float = float(stats.get("accuracy", 1.0))
	var wpm: float = float(stats.get("wpm", 0.0))
	var errors: int = int(stats.get("errors", 0))
	var words_completed: int = int(stats.get("words_completed", 0))
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
		progression.complete_node(node_id, summary)
		result_label.text = "Victory! The castle stands strong."
		result_action = "map"
		result_button.text = "Return to Map"
	else:
		progression.record_attempt(summary)
		result_label.text = "Defeat. The walls fell."
		result_action = "retry"
		result_button.text = "Retry Battle"
	result_panel.visible = true
	gold_label.text = "Gold: %d" % progression.gold

func _on_result_pressed() -> void:
	if result_action == "retry":
		game_controller.go_to_battle(node_id)
	else:
		game_controller.go_to_map()

func _on_exit_pressed() -> void:
	game_controller.go_to_map()

func _format_bonus_text(modifiers: Dictionary) -> String:
	var typing_power_bonus: int = int(round((float(modifiers.get("typing_power", 1.0)) - 1.0) * 100.0))
	var threat_rate_bonus: int = int(round((1.0 - float(modifiers.get("threat_rate_multiplier", 1.0))) * 100.0))
	var parts: Array = []
	if typing_power_bonus != 0:
		parts.append("Typing Power %+d%%" % typing_power_bonus)
	if threat_rate_bonus != 0:
		parts.append("Threat Slow %+d%%" % threat_rate_bonus)
	if int(modifiers.get("castle_health_bonus", 0)) > 0:
		parts.append("Castle +%d" % int(modifiers.get("castle_health_bonus", 0)))
	if parts.is_empty():
		return "Bonuses: None"
	return "Bonuses: " + ", ".join(parts)
