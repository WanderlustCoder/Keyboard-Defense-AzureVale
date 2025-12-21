extends Control

const TypingSystem = preload("res://scripts/TypingSystem.gd")

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

var threat: float = 0.0
var threat_rate: float = 8.0
var threat_relief: float = 12.0
var mistake_penalty: float = 18.0
var castle_health: int = 3
var typing_power: float = 1.0
var mistake_forgiveness: float = 0.0

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
	words = lesson.get("words", [])
	if words.is_empty():
		words = ["guard", "tower", "shield", "banner", "castle"]
	typing_system.start(words)

	var modifiers: Dictionary = progression.get_combat_modifiers()
	typing_power = float(modifiers.get("typing_power", 1.0))
	var threat_rate_multiplier: float = float(modifiers.get("threat_rate_multiplier", 1.0))
	mistake_forgiveness = float(modifiers.get("mistake_forgiveness", 0.0))
	castle_health = 3 + int(modifiers.get("castle_health_bonus", 0))
	threat_rate = 8.0 * threat_rate_multiplier
	threat_relief = 12.0 * typing_power
	mistake_penalty = 18.0 * (1.0 - mistake_forgiveness)

	lesson_label.text = "%s - %s" % [node_label, lesson.get("label", "Lesson")]
	gold_label.text = "Gold: %d" % progression.gold
	bonus_label.text = _format_bonus_text(modifiers)
	_update_word_display()
	_update_stats()
	_update_threat()

func _process(delta: float) -> void:
	if not active:
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
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_BACKSPACE:
			typing_system.backspace()
			_update_word_display()
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
		_finish_battle(true)
		return
	_update_word_display()
	_update_stats()
	_update_threat()

func _update_word_display() -> void:
	var current_word: String = typing_system.get_current_word()
	word_label.text = "Word: %s" % current_word
	typed_label.text = "Typed: %s" % typing_system.typed

func _update_stats() -> void:
	var accuracy: int = int(round(typing_system.get_accuracy() * 100.0))
	var wpm: int = int(round(typing_system.get_wpm()))
	accuracy_label.text = "Accuracy: %d%%" % accuracy
	wpm_label.text = "WPM: %d" % wpm
	mistakes_label.text = "Errors: %d" % typing_system.errors

func _update_threat() -> void:
	threat_bar.value = threat
	castle_label.text = "Castle Health: %d" % castle_health

func _finish_battle(success: bool) -> void:
	active = false
	var accuracy: float = typing_system.get_accuracy()
	var wpm: float = typing_system.get_wpm()
	var summary: Dictionary = {
		"node_id": node_id,
		"node_label": node_label,
		"lesson_id": lesson_id,
		"accuracy": accuracy,
		"wpm": wpm,
		"errors": typing_system.errors,
		"words_completed": typing_system.get_words_completed(),
		"completed": success
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
