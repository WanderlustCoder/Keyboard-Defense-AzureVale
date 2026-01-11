extends Control

## Typing Defense - On-rails typing tutor with kingdom building rewards
## Better typing = more attack power = faster enemy defeats = more gold

const StoryManager = preload("res://game/story_manager.gd")
const DIALOGUE_BOX_SCENE := preload("res://scenes/DialogueBox.tscn")

@onready var wave_label: Label = $TopBar/WaveLabel
@onready var hp_label: Label = $TopBar/HPLabel
@onready var gold_label: Label = $TopBar/GoldLabel
@onready var lesson_label: Label = $TopBar/LessonLabel
@onready var wpm_label: Label = $StatsBar/WPMLabel
@onready var accuracy_label: Label = $StatsBar/AccuracyLabel
@onready var combo_label: Label = $StatsBar/ComboLabel
@onready var power_label: Label = $StatsBar/PowerLabel
@onready var menu_button: Button = $MenuButton
@onready var word_display: RichTextLabel = $TypingPanel/VBox/WordDisplay
@onready var typed_display: Label = $TypingPanel/VBox/TypedDisplay
@onready var input_field: LineEdit = $TypingPanel/VBox/InputField
@onready var feedback_label: Label = $TypingPanel/VBox/FeedbackLabel
@onready var queue_list: RichTextLabel = $EnemyQueue/QueueList
@onready var wave_progress: ProgressBar = $WaveProgress
@onready var enemy_lane: Control = $BattleArea/EnemyLane
@onready var game_controller = get_node_or_null("/root/GameController")

# Game state
var castle_hp: int = 10
var castle_max_hp: int = 10
var gold: int = 0
var wave: int = 1
var enemies_defeated: int = 0
var wave_enemies_total: int = 5

# Current enemy
var current_enemy: Dictionary = {}
var enemy_queue: Array[Dictionary] = []

# Typing stats
var combo: int = 0
var max_combo: int = 0
var correct_chars: int = 0
var total_chars: int = 0
var words_typed: int = 0
var typing_start_time: float = 0.0
var wave_start_time: float = 0.0

# Lesson words by difficulty
var lesson_words: Dictionary = {
	"home_row": ["asdf", "jkl", "sad", "dad", "lad", "ask", "all", "fall", "salad", "flask"],
	"top_row": ["we", "you", "type", "query", "write", "power", "tower", "poetry", "equity"],
	"bottom_row": ["mix", "box", "zen", "vim", "zap", "zoom", "comic", "maximum"],
	"numbers": ["123", "456", "789", "2024", "1000", "42", "365", "100"],
	"full": ["castle", "defend", "knight", "dragon", "shield", "sword", "attack", "victory", "kingdom", "throne", "battle", "archer", "wizard", "fortress", "treasure"]
}
var current_lesson: String = "home_row"

# Enemy types
var enemy_types: Array[Dictionary] = [
	{"kind": "scout", "hp": 1, "speed": 2.0, "gold": 3},
	{"kind": "raider", "hp": 2, "speed": 1.5, "gold": 5},
	{"kind": "brute", "hp": 4, "speed": 1.0, "gold": 10},
	{"kind": "knight", "hp": 3, "speed": 1.2, "gold": 8},
]

# Visual enemy nodes
var enemy_visuals: Array[Control] = []

# Story integration
var dialogue_box: Node = null
var waiting_for_dialogue: bool = false
var has_shown_welcome: bool = false
var last_lesson_intro: String = ""

func _ready() -> void:
	input_field.text_changed.connect(_on_input_changed)
	input_field.text_submitted.connect(_on_input_submitted)
	input_field.grab_focus()

	if menu_button:
		menu_button.pressed.connect(_on_menu_pressed)

	_init_dialogue_box()
	_show_welcome_dialogue()
	_start_wave()


func _init_dialogue_box() -> void:
	dialogue_box = DIALOGUE_BOX_SCENE.instantiate()
	add_child(dialogue_box)
	dialogue_box.dialogue_finished.connect(_on_dialogue_finished)


func _on_dialogue_finished() -> void:
	waiting_for_dialogue = false
	input_field.grab_focus()


func _show_welcome_dialogue() -> void:
	if has_shown_welcome:
		return
	has_shown_welcome = true

	var lines: Array[String] = [
		"Welcome to the Typing Arena, defender!",
		"Here you will hone your skills against endless waves of enemies.",
		"Type the words quickly and accurately to build power.",
		"Higher combos mean more damage - and more gold!",
		"Good luck, and may your fingers be swift!"
	]

	waiting_for_dialogue = true
	dialogue_box.show_dialogue("Elder Lyra", lines)

func _process(delta: float) -> void:
	if waiting_for_dialogue:
		return
	_update_enemies(delta)
	_update_wpm()

func _start_wave() -> void:
	enemy_queue.clear()
	enemies_defeated = 0
	wave_enemies_total = 3 + wave * 2
	wave_start_time = Time.get_unix_time_from_system()

	# Generate enemies for this wave
	for i in range(wave_enemies_total):
		var template: Dictionary = enemy_types[randi() % enemy_types.size()]
		var word: String = _get_lesson_word()
		enemy_queue.append({
			"kind": template.kind,
			"hp": template.hp,
			"max_hp": template.hp,
			"speed": template.speed,
			"gold": template.gold,
			"word": word,
			"position": 1.0  # 1.0 = far right, 0.0 = at castle
		})

	_next_enemy()
	_refresh_ui()

func _next_enemy() -> void:
	if enemy_queue.is_empty():
		_wave_complete()
		return

	current_enemy = enemy_queue.pop_front()
	typing_start_time = Time.get_unix_time_from_system()
	input_field.clear()
	_refresh_word_display()
	_refresh_queue_display()

func _get_lesson_word() -> String:
	var words: Array = lesson_words.get(current_lesson, lesson_words["home_row"])
	return words[randi() % words.size()]

func _on_input_changed(new_text: String) -> void:
	if waiting_for_dialogue:
		return

	var target: String = current_enemy.get("word", "")
	var typed: String = new_text.to_lower()

	# Update typed display with color coding
	_refresh_word_display()

	# Check for mistakes
	if not target.begins_with(typed) and typed.length() > 0:
		# Mistake! Break combo
		if combo > 0:
			feedback_label.text = "[color=red]Mistake! Combo broken.[/color]"
			feedback_label.add_theme_color_override("font_color", Color(1, 0.4, 0.4))
		combo = 0
		total_chars += 1
		_refresh_ui()

	# Auto-complete on exact match
	if typed == target:
		_attack_enemy()

func _on_input_submitted(_text: String) -> void:
	var target: String = current_enemy.get("word", "")
	var typed: String = input_field.text.to_lower()

	if typed == target:
		_attack_enemy()
	else:
		feedback_label.text = "Not quite - keep typing!"
		feedback_label.add_theme_color_override("font_color", Color(1, 0.7, 0.3))

func _attack_enemy() -> void:
	# Calculate damage based on typing performance
	var base_damage: int = 1
	var power_multiplier: float = _calculate_power()
	var damage: int = max(1, int(base_damage * power_multiplier))

	current_enemy["hp"] = int(current_enemy.get("hp", 1)) - damage

	# Stats tracking
	correct_chars += current_enemy.get("word", "").length()
	total_chars += current_enemy.get("word", "").length()
	words_typed += 1
	combo += 1
	max_combo = max(max_combo, combo)

	if int(current_enemy.get("hp", 0)) <= 0:
		# Enemy defeated!
		var gold_reward: int = int(current_enemy.get("gold", 5))
		# Bonus gold for high combo
		if combo >= 10:
			gold_reward = int(gold_reward * 1.5)
		elif combo >= 5:
			gold_reward = int(gold_reward * 1.2)

		gold += gold_reward
		enemies_defeated += 1

		feedback_label.text = "DEFEATED! +%d gold (Combo: %d)" % [gold_reward, combo]
		feedback_label.add_theme_color_override("font_color", Color(0.4, 1, 0.4))

		_remove_enemy_visual()
		_next_enemy()
	else:
		# Enemy damaged but not dead - new word
		current_enemy["word"] = _get_lesson_word()
		feedback_label.text = "Hit! %d damage (HP: %d)" % [damage, current_enemy.get("hp", 0)]
		feedback_label.add_theme_color_override("font_color", Color(1, 0.8, 0.3))
		input_field.clear()
		_refresh_word_display()

	_refresh_ui()

func _calculate_power() -> float:
	# Power scales with accuracy and combo
	var accuracy: float = _get_accuracy()
	var combo_bonus: float = min(combo * 0.1, 1.0)  # Max +100% from combo
	var accuracy_bonus: float = accuracy * 0.5  # Max +50% from accuracy
	return 1.0 + combo_bonus + accuracy_bonus

func _get_accuracy() -> float:
	if total_chars == 0:
		return 1.0
	return float(correct_chars) / float(total_chars)

func _update_wpm() -> void:
	if words_typed == 0:
		return
	var elapsed: float = Time.get_unix_time_from_system() - wave_start_time
	if elapsed < 1.0:
		return
	var wpm: float = (float(words_typed) / elapsed) * 60.0
	wpm_label.text = "WPM: %d" % int(wpm)

func _update_enemies(delta: float) -> void:
	if current_enemy.is_empty():
		return

	# Move current enemy toward castle
	var speed: float = current_enemy.get("speed", 1.0) * 0.05 * delta
	current_enemy["position"] = max(0.0, float(current_enemy.get("position", 1.0)) - speed)

	# Update visual position
	_update_enemy_visual()

	# Check if reached castle
	if float(current_enemy.get("position", 0.0)) <= 0.0:
		_enemy_reached_castle()

func _enemy_reached_castle() -> void:
	castle_hp -= 1
	combo = 0  # Break combo

	feedback_label.text = "ENEMY BREACHED! Castle damaged!"
	feedback_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))

	if castle_hp <= 0:
		_game_over()
	else:
		_remove_enemy_visual()
		_next_enemy()

	_refresh_ui()

func _wave_complete() -> void:
	wave += 1

	# Wave completion bonus
	var wave_bonus: int = 20 * wave
	if castle_hp == castle_max_hp:
		wave_bonus = int(wave_bonus * 1.5)  # Perfect defense bonus
	gold += wave_bonus

	feedback_label.text = "WAVE COMPLETE! +%d gold bonus!" % wave_bonus
	feedback_label.add_theme_color_override("font_color", Color(0.3, 1, 0.5))

	# Progress lesson difficulty with story integration
	var lesson_changed: bool = false
	var new_lesson_id: String = ""
	if wave >= 3 and current_lesson == "home_row":
		current_lesson = "top_row"
		new_lesson_id = "upper_row_1"
		lesson_changed = true
	elif wave >= 6 and current_lesson == "top_row":
		current_lesson = "bottom_row"
		new_lesson_id = "bottom_row_1"
		lesson_changed = true
	elif wave >= 9 and current_lesson == "bottom_row":
		current_lesson = "full"
		new_lesson_id = "full_alpha"
		lesson_changed = true

	# Heal castle between waves
	castle_hp = min(castle_hp + 2, castle_max_hp)

	# Show lesson introduction for new lessons
	if lesson_changed and new_lesson_id != last_lesson_intro:
		last_lesson_intro = new_lesson_id
		_show_lesson_intro(new_lesson_id)
	else:
		# Show contextual tip
		_show_wave_tip()

	# Short delay then start next wave
	await get_tree().create_timer(2.0).timeout
	_start_wave()


func _show_lesson_intro(lesson_id: String) -> void:
	if not dialogue_box or waiting_for_dialogue:
		return

	var lines: Array[String] = StoryManager.get_lesson_intro_lines(lesson_id)
	if lines.is_empty():
		# Fallback for lessons without story intros
		var lesson_name: String = lesson_id.replace("_", " ").capitalize()
		lines = [
			"Excellent progress, defender!",
			"You are now ready for: %s" % lesson_name,
			"New keys will test your expanding abilities!"
		]

	waiting_for_dialogue = true
	dialogue_box.show_dialogue("Elder Lyra", lines)


func _show_wave_tip() -> void:
	if waiting_for_dialogue:
		return

	# Get contextual tip based on performance
	var tip: String = ""
	var accuracy: float = _get_accuracy()
	if accuracy < 0.8:
		tip = StoryManager.get_contextual_tip("accuracy")
	elif max_combo < 5:
		tip = StoryManager.get_contextual_tip("combo")
	else:
		tip = StoryManager.get_contextual_tip("practice")

	if not tip.is_empty():
		feedback_label.text += " Tip: " + tip

func _game_over() -> void:
	word_display.text = "[center][color=red]GAME OVER[/color][/center]"
	input_field.editable = false
	feedback_label.text = "Castle destroyed! Final gold: %d | Max combo: %d" % [gold, max_combo]
	feedback_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))

	# Show story game over message
	if dialogue_box:
		var accuracy: float = _get_accuracy()
		var lines: Array[String] = []

		if wave >= 10:
			lines = [
				"You fought valiantly, defender!",
				"Wave %d is an impressive achievement." % wave,
				"Rest now, and return stronger than before."
			]
		elif accuracy >= 0.9:
			lines = [
				"The castle has fallen, but your accuracy was remarkable!",
				"Keep that precision - it will serve you well.",
				"Try again when you are ready."
			]
		else:
			lines = [
				"The Typhos Horde has overwhelmed us!",
				"Practice your typing accuracy and speed.",
				"Every keystroke matters in battle."
			]

		waiting_for_dialogue = true
		dialogue_box.show_dialogue("Elder Lyra", lines)

func _refresh_ui() -> void:
	wave_label.text = "Wave %d" % wave
	hp_label.text = "Castle HP: %d/%d" % [castle_hp, castle_max_hp]
	gold_label.text = "Gold: %d" % gold
	lesson_label.text = "Lesson: %s" % current_lesson.replace("_", " ").capitalize()

	accuracy_label.text = "Accuracy: %d%%" % int(_get_accuracy() * 100)
	combo_label.text = "Combo: %d" % combo
	power_label.text = "Power: %.1fx" % _calculate_power()

	wave_progress.max_value = wave_enemies_total
	wave_progress.value = enemies_defeated

func _refresh_word_display() -> void:
	var target: String = current_enemy.get("word", "")
	var typed: String = input_field.text.to_lower()

	# Build colored display
	var display: String = "[center]"
	for i in range(target.length()):
		var char: String = target[i]
		if i < typed.length():
			if typed[i] == char:
				display += "[color=lime]%s[/color]" % char
			else:
				display += "[color=red]%s[/color]" % char
		else:
			display += "[color=yellow]%s[/color]" % char
	display += "[/center]"

	word_display.text = display
	typed_display.text = typed

func _refresh_queue_display() -> void:
	var text: String = ""
	var count: int = 1
	for enemy in enemy_queue.slice(0, 5):  # Show next 5
		text += "%d. %s (HP: %d)\n" % [count, enemy.get("kind", "enemy"), enemy.get("hp", 1)]
		count += 1
	if enemy_queue.size() > 5:
		text += "... and %d more" % (enemy_queue.size() - 5)
	queue_list.text = text

func _update_enemy_visual() -> void:
	# Simple visual: show enemy position as text for now
	var pos: float = float(current_enemy.get("position", 1.0))
	var kind: String = str(current_enemy.get("kind", "enemy"))
	var hp: int = int(current_enemy.get("hp", 0))

	# Could add actual sprites here - for now show in queue title
	$EnemyQueue/QueueTitle.text = "CURRENT: %s [HP:%d] %.0f%%" % [kind.to_upper(), hp, pos * 100]

func _remove_enemy_visual() -> void:
	$EnemyQueue/QueueTitle.text = "INCOMING ENEMIES:"

func _on_menu_pressed() -> void:
	if game_controller:
		game_controller.go_to_menu()
