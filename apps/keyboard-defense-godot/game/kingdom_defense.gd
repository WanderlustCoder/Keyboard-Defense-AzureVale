extends Control

## Kingdom Defense - Top-Down RTS Typing Game
## Inspired by Super Fantasy Kingdom with typing-based combat and commands

const GameState = preload("res://sim/types.gd")
const SimMap = preload("res://sim/map.gd")
const SimEnemies = preload("res://sim/enemies.gd")
const SimLessons = preload("res://sim/lessons.gd")
const SimWords = preload("res://sim/words.gd")
const DefaultState = preload("res://sim/default_state.gd")
const StoryManager = preload("res://game/story_manager.gd")
const SimBuildings = preload("res://sim/buildings.gd")
const SimWorkers = preload("res://sim/workers.gd")
const SimResearch = preload("res://sim/research.gd")
const SimTrade = preload("res://sim/trade.gd")
const KingdomDashboard = preload("res://ui/components/kingdom_dashboard.gd")
const SettingsPanel = preload("res://ui/components/settings_panel.gd")
const GamePersistence = preload("res://game/persistence.gd")
const TypingProfile = preload("res://game/typing_profile.gd")
const AchievementChecker = preload("res://game/achievement_checker.gd")
const AchievementPanel = preload("res://ui/components/achievement_panel.gd")
const ACHIEVEMENT_POPUP_SCENE := preload("res://ui/components/achievement_popup.tscn")
const LorePanel = preload("res://ui/components/lore_panel.gd")
const SimDifficulty = preload("res://sim/difficulty.gd")
const SimCombo = preload("res://sim/combo.gd")
const SimStatusEffects = preload("res://sim/status_effects.gd")
const SimSkills = preload("res://sim/skills.gd")
const SimItems = preload("res://sim/items.gd")
const SimSpecialCommands = preload("res://sim/special_commands.gd")
const SimQuests = preload("res://sim/quests.gd")

# UI Node references
@onready var grid_renderer: Node2D = $GridRenderer
@onready var day_label: Label = $HUD/TopBar/HBox/DayLabel
@onready var wave_label: Label = $HUD/TopBar/HBox/WaveLabel
@onready var hp_value: Label = $HUD/TopBar/HBox/HPBar/HPValue
@onready var gold_value: Label = $HUD/TopBar/HBox/GoldBar/GoldValue
@onready var resources_label: Label = $HUD/TopBar/HBox/ResourceBar/ResourcesLabel
@onready var lesson_label: Label = $HUD/TopBar/HBox/LessonLabel
@onready var phase_label: Label = $HUD/TopBar/HBox/PhaseLabel
@onready var menu_button: Button = $HUD/TopBar/HBox/MenuButton
@onready var enemy_panel: Panel = $HUD/EnemyPanel
@onready var current_enemy_label: RichTextLabel = $HUD/EnemyPanel/VBox/CurrentEnemy/CurrentLabel
@onready var queue_list: RichTextLabel = $HUD/EnemyPanel/VBox/QueueList
@onready var typing_panel: Panel = $HUD/TypingPanel
@onready var word_display: RichTextLabel = $HUD/TypingPanel/VBox/WordDisplay
@onready var input_display: Label = $HUD/TypingPanel/VBox/InputDisplay
@onready var input_field: LineEdit = $HUD/TypingPanel/VBox/InputField
@onready var wpm_label: Label = $HUD/TypingPanel/VBox/StatsBar/WPMLabel
@onready var accuracy_label: Label = $HUD/TypingPanel/VBox/StatsBar/AccuracyLabel
@onready var combo_label: Label = $HUD/TypingPanel/VBox/StatsBar/ComboLabel
@onready var power_label: Label = $HUD/TypingPanel/VBox/StatsBar/PowerLabel
@onready var hint_label: Label = $HUD/TypingPanel/VBox/HintLabel
@onready var tip_label: Label = $HUD/TypingPanel/VBox/TipLabel
@onready var finger_hint_label: Label = $HUD/TypingPanel/VBox/FingerHintLabel
@onready var objective_label: RichTextLabel = $HUD/ObjectivePanel/ObjectiveLabel
@onready var keyboard_display: Control = $HUD/TypingPanel/VBox/KeyboardPanel
@onready var act_label: Label = $HUD/TopBar/HBox/ActLabel
@onready var dialogue_box: Control = $DialogueBox
@onready var game_controller = get_node_or_null("/root/GameController")

# Game state
var state: GameState
var current_phase: String = "planning"  # "planning" or "defense"
var day: int = 1
var wave: int = 1
var waves_per_day: int = 3
var castle_hp: int = 10
var castle_max_hp: int = 10
var gold: int = 50

# Enemy management
var active_enemies: Array = []  # Enemies on the field with real-time positions
var enemy_queue: Array = []  # Enemies waiting to spawn
var spawn_timer: float = 0.0
var spawn_interval: float = 2.0
var target_enemy_id: int = -1  # Currently targeted enemy

# Typing state
var current_word: String = ""
var typed_text: String = ""
var combo: int = 0
var max_combo: int = 0
var correct_chars: int = 0
var total_chars: int = 0
var words_typed: int = 0
var wave_start_time: float = 0.0
var word_start_time: float = 0.0
var current_wave_composition: Dictionary = {}  # Wave composer output

# Skill system tracking
var words_typed_this_wave: int = 0
var last_kill_time: float = 0.0
var chain_kill_count: int = 0
var active_skill_buffs: Dictionary = {}  # {skill_id: {remaining: float, effect: value}}

# Active item buffs
var active_item_buffs: Dictionary = {}  # {buff_type: {remaining: float, value: float}}

# Auto-tower cooldowns
var auto_tower_cooldowns: Dictionary = {}  # {tower_index: remaining_cooldown}

# Special command tracking
var command_cooldowns: Dictionary = {}  # {command_id: remaining_cooldown}
var command_effects: Dictionary = {}  # Active effects like {damage_charges: 5, crit_charges: 3, etc.}
var auto_tower_speed_buff: float = 1.0  # Multiplier for auto-tower attack speed

# Quest tracking
var quest_state: Dictionary = {}  # Stores daily/weekly/challenge quest progress
var session_stats: Dictionary = {}  # Tracks stats for quest progress this session

# Endless mode tracking
var is_endless_mode: bool = false
var endless_run_kills: int = 0
var endless_day_start_time: float = 0.0

# Daily challenge tracking
var is_challenge_mode: bool = false
var challenge_state: Dictionary = {}
var challenge_kills: int = 0
var challenge_words: int = 0
var challenge_gold_earned: int = 0
var challenge_boss_kills: int = 0

# Lesson progression
var lesson_order: Array[String] = [
	"home_row_1", "home_row_2",
	"reach_row_1", "reach_row_2",
	"bottom_row_1", "bottom_row_2",
	"upper_row_1", "upper_row_2",
	"mixed_rows", "speed_alpha",
	"nexus_blend", "apex_mastery"
]
var current_lesson_index: int = 0
var lesson_accuracy_threshold: float = 0.8  # 80% accuracy to unlock next

# Planning phase
var planning_timer: float = 30.0
var cursor_grid_pos: Vector2i = Vector2i(8, 5)

# Story state
var last_act_intro_day: int = 0
var game_started: bool = false
var waiting_for_dialogue: bool = false

# Educational tracking
var tip_timer: float = 0.0
var tip_interval: float = 8.0
var last_wpm_milestone: int = 0
var previous_lesson_id: String = ""
var show_finger_hints: bool = true

# Key practice mode
var practice_mode: bool = false
var practice_keys: Array[String] = []
var practice_index: int = 0
var practice_lesson_id: String = ""
var practice_correct_count: int = 0
var practice_attempts: int = 0
var pending_practice_lesson: String = ""  # Lesson to practice after dialogue

# Build commands
const BUILD_COMMANDS := {
	"build tower": "tower",
	"build wall": "wall",
	"build farm": "farm",
	"build lumber": "lumber",
	"build quarry": "quarry",
	"build market": "market",
	"build barracks": "barracks",
	"build temple": "temple",
	"build workshop": "workshop",
	"build sentry": "sentry",
	"build spark": "spark",
	"build flame": "flame",
	"tower": "tower",
	"wall": "wall",
	"farm": "farm",
	"lumber": "lumber",
	"quarry": "quarry",
	"market": "market",
	"barracks": "barracks",
	"temple": "temple",
	"workshop": "workshop",
	"sentry": "sentry",
	"spark": "spark",
	"flame": "flame"
}

# Kingdom management
var kingdom_dashboard: KingdomDashboard = null
var settings_panel: SettingsPanel = null
var research_instance: SimResearch = null

# Achievement and profile system
var profile: Dictionary = {}
var achievement_checker: AchievementChecker = null
var achievement_popup: Node = null
var achievement_panel: AchievementPanel = null
var damage_taken_this_wave: int = 0
var damage_taken_this_day: int = 0
var lore_panel: LorePanel = null
var difficulty_mode: String = "adventure"

func _ready() -> void:
	_init_game_state()
	_init_kingdom_systems()
	_init_achievement_system()
	_connect_signals()
	_show_game_start_dialogue()

func _init_kingdom_systems() -> void:
	# Initialize research system
	research_instance = SimResearch.instance()

	# Create kingdom dashboard
	kingdom_dashboard = KingdomDashboard.new()
	add_child(kingdom_dashboard)
	kingdom_dashboard.update_state(state)
	kingdom_dashboard.closed.connect(_on_dashboard_closed)
	kingdom_dashboard.upgrade_requested.connect(_on_upgrade_requested)
	kingdom_dashboard.research_started.connect(_on_research_started)
	kingdom_dashboard.trade_executed.connect(_on_trade_executed)

	# Create settings panel
	settings_panel = SettingsPanel.new()
	add_child(settings_panel)
	settings_panel.close_requested.connect(_on_settings_closed)

func _init_achievement_system() -> void:
	# Load player profile
	var load_result: Dictionary = TypingProfile.load_profile()
	if load_result.get("ok", false):
		profile = load_result.get("profile", TypingProfile.default_profile())
	else:
		profile = TypingProfile.default_profile()

	# Load difficulty mode from profile
	difficulty_mode = TypingProfile.get_difficulty_mode(profile)

	# Update daily streak
	var streak_result: Dictionary = TypingProfile.update_daily_streak(profile)
	if streak_result.get("changed", false):
		TypingProfile.save_profile(profile)
		if streak_result.get("extended", false):
			var streak: int = int(streak_result.get("streak", 1))
			if streak >= 3:
				_show_streak_message(streak)

	# Initialize quest system
	_init_quest_system()

	# Create achievement checker
	achievement_checker = AchievementChecker.new()
	achievement_checker.achievement_unlocked.connect(_on_achievement_unlocked)

	# Create achievement popup
	achievement_popup = ACHIEVEMENT_POPUP_SCENE.instantiate()
	add_child(achievement_popup)

	# Create achievement panel
	achievement_panel = AchievementPanel.new()
	add_child(achievement_panel)
	achievement_panel.close_requested.connect(_on_achievement_panel_closed)

	# Create lore panel
	lore_panel = LorePanel.new()
	add_child(lore_panel)
	lore_panel.close_requested.connect(_on_lore_panel_closed)

func _show_streak_message(streak: int) -> void:
	var message: String = StoryManager.get_daily_streak_message(streak)
	if not message.is_empty() and dialogue_box:
		var lines: Array[String] = [message]
		dialogue_box.show_dialogue("Elder Lyra", lines)

func _on_achievement_unlocked(achievement_id: String, achievement_data: Dictionary) -> void:
	if achievement_popup != null and achievement_popup.has_method("show_achievement"):
		achievement_popup.show_achievement(achievement_id, achievement_data)

func _on_achievement_panel_closed() -> void:
	if input_field:
		input_field.grab_focus()

func _on_lore_panel_closed() -> void:
	if input_field:
		input_field.grab_focus()

func _toggle_lore() -> void:
	if lore_panel:
		if lore_panel.visible:
			lore_panel.hide_lore()
		else:
			lore_panel.show_lore()

func _on_dashboard_closed() -> void:
	if input_field:
		input_field.grab_focus()

func _on_settings_closed() -> void:
	if input_field:
		input_field.grab_focus()

func _toggle_settings() -> void:
	if settings_panel:
		if settings_panel.visible:
			settings_panel.hide_settings()
		else:
			settings_panel.show_settings()

func _on_upgrade_requested(building_index: int) -> void:
	_update_objective("[color=green]Building upgraded![/color]")
	_update_grid_renderer()

func _on_research_started(research_id: String) -> void:
	var research: Dictionary = research_instance.get_research(research_id)
	var label: String = str(research.get("label", research_id))
	_update_objective("[color=cyan]Started research: %s[/color]" % label)

func _on_trade_executed(from: String, to: String, amount: int) -> void:
	_update_objective("[color=green]Trade complete![/color]")

func _init_game_state() -> void:
	state = DefaultState.create()
	state.base_pos = Vector2i(1, state.map_h / 2)
	state.cursor_pos = cursor_grid_pos
	state.lesson_id = lesson_order[current_lesson_index]
	previous_lesson_id = state.lesson_id

	# Discover entire map for RTS view
	for y in range(state.map_h):
		for x in range(state.map_w):
			var index: int = y * state.map_w + x
			state.discovered[index] = true

	# Generate terrain
	SimMap.generate_terrain(state)

	# Starting resources
	state.resources["wood"] = 10
	state.resources["stone"] = 5
	state.resources["food"] = 10

	_update_grid_renderer()

func _connect_signals() -> void:
	if input_field:
		input_field.text_changed.connect(_on_input_changed)
		input_field.text_submitted.connect(_on_input_submitted)
		input_field.grab_focus()

	if menu_button:
		menu_button.pressed.connect(_on_menu_pressed)

	if dialogue_box:
		dialogue_box.dialogue_finished.connect(_on_dialogue_finished)

func _process(delta: float) -> void:
	# Pause game during dialogue
	if waiting_for_dialogue:
		_update_ui()
		return

	match current_phase:
		"planning":
			_process_planning(delta)
		"defense":
			_process_defense(delta)
		"practice":
			_process_practice(delta)

	_update_ui()

func _process_planning(delta: float) -> void:
	planning_timer -= delta
	if planning_timer <= 0:
		_start_defense_phase()

	# Rotate typing tips
	tip_timer += delta
	if tip_timer >= tip_interval:
		tip_timer = 0.0
		_show_random_tip()

func _process_practice(delta: float) -> void:
	# Practice mode is event-driven via input, not delta-based
	pass

func _process_defense(delta: float) -> void:
	# Tick item buffs
	_tick_item_buffs(delta)

	# Tick command cooldowns and effects
	_tick_command_cooldowns(delta)

	# Process auto-tower attacks
	_process_auto_towers(delta)

	# Spawn enemies from queue
	spawn_timer -= delta
	if spawn_timer <= 0 and not enemy_queue.is_empty():
		_spawn_next_enemy()
		spawn_timer = spawn_interval

	# Move all active enemies toward castle
	var dist_field: PackedInt32Array = SimMap.compute_dist_to_base(state)
	for i in range(active_enemies.size() - 1, -1, -1):
		var enemy: Dictionary = active_enemies[i]
		_move_enemy(enemy, dist_field, delta)
		active_enemies[i] = enemy

		# Check if reached castle
		var pos: Vector2i = enemy.get("pos", Vector2i.ZERO)
		if pos == state.base_pos:
			_enemy_reached_castle(i)

	# Update state enemies for grid renderer
	state.enemies = active_enemies.duplicate(true)
	_update_grid_renderer()

	# Check wave completion
	if active_enemies.is_empty() and enemy_queue.is_empty():
		_wave_complete()

func _move_enemy(enemy: Dictionary, dist_field: PackedInt32Array, delta: float) -> void:
	var pos: Vector2i = enemy.get("pos", Vector2i.ZERO)
	var speed: float = float(enemy.get("speed", 1)) * 0.5  # Tiles per second

	# Accumulate movement progress
	var progress: float = enemy.get("move_progress", 0.0) + speed * delta
	enemy["move_progress"] = progress

	if progress >= 1.0:
		enemy["move_progress"] = 0.0
		# Find next tile toward castle
		var next_pos: Vector2i = _get_next_tile(pos, dist_field)
		if next_pos != pos:
			enemy["pos"] = next_pos

func _get_next_tile(from: Vector2i, dist_field: PackedInt32Array) -> Vector2i:
	var neighbors: Array[Vector2i] = SimMap.neighbors4(from, state.map_w, state.map_h)
	var best_pos: Vector2i = from
	var best_dist: int = _dist_at(from, dist_field)

	for neighbor in neighbors:
		var d: int = _dist_at(neighbor, dist_field)
		if d >= 0 and d < best_dist:
			best_dist = d
			best_pos = neighbor

	return best_pos

func _dist_at(pos: Vector2i, dist_field: PackedInt32Array) -> int:
	var index: int = pos.y * state.map_w + pos.x
	if index < 0 or index >= dist_field.size():
		return 999999
	var d: int = dist_field[index]
	return d if d >= 0 else 999999

func _spawn_next_enemy() -> void:
	if enemy_queue.is_empty():
		return

	var enemy: Dictionary = enemy_queue.pop_front()
	var spawn_edge: int = randi() % 3  # 0=top, 1=right, 2=bottom
	var spawn_pos: Vector2i

	match spawn_edge:
		0:  # Top edge
			spawn_pos = Vector2i(randi() % state.map_w, 0)
		1:  # Right edge
			spawn_pos = Vector2i(state.map_w - 1, randi() % state.map_h)
		2:  # Bottom edge
			spawn_pos = Vector2i(randi() % state.map_w, state.map_h - 1)

	enemy["pos"] = spawn_pos
	enemy["move_progress"] = 0.0
	active_enemies.append(enemy)

	# Auto-target first enemy
	if target_enemy_id < 0 and not active_enemies.is_empty():
		_target_closest_enemy()

func _target_closest_enemy() -> void:
	if active_enemies.is_empty():
		target_enemy_id = -1
		current_word = ""
		return

	var dist_field: PackedInt32Array = SimMap.compute_dist_to_base(state)
	var best_index: int = SimEnemies.pick_target_index(active_enemies, dist_field, state.map_w, state.base_pos, -1)

	if best_index >= 0:
		target_enemy_id = int(active_enemies[best_index].get("id", -1))
		current_word = str(active_enemies[best_index].get("word", ""))
		word_start_time = Time.get_unix_time_from_system()
		input_field.clear()
		typed_text = ""
	else:
		target_enemy_id = -1
		current_word = ""

func _enemy_reached_castle(enemy_index: int) -> void:
	var enemy: Dictionary = active_enemies[enemy_index]
	var damage: int = max(1, int(enemy.get("hp", 1)))

	# Apply equipment defense and damage reduction
	var equipment: Dictionary = TypingProfile.get_equipment(profile)
	var equip_stats: Dictionary = SimItems.calculate_equipment_stats(equipment)
	var defense: int = int(equip_stats.get("defense", 0))
	var damage_reduction: float = float(equip_stats.get("damage_reduction", 0))
	var dodge_chance: float = float(equip_stats.get("dodge_chance", 0))

	# Check for shield block charges
	if int(command_effects.get("block_charges", 0)) > 0:
		command_effects["block_charges"] = int(command_effects["block_charges"]) - 1
		if int(command_effects.get("block_charges", 0)) <= 0:
			command_effects.erase("block_charges")
		_update_objective("[color=cyan]BLOCKED![/color] Shield absorbed the hit!")
		active_enemies.remove_at(enemy_index)
		if target_enemy_id == int(enemy.get("id", -1)):
			_target_closest_enemy()
		return

	# Check for dodge
	if dodge_chance > 0 and randf() < dodge_chance:
		_update_objective("[color=cyan]DODGED![/color] Avoided all damage!")
		active_enemies.remove_at(enemy_index)
		if target_enemy_id == int(enemy.get("id", -1)):
			_target_closest_enemy()
		return

	# Reduce damage by defense (1 defense = 1 less damage)
	damage = max(1, damage - defense)

	# Apply % damage reduction from equipment
	if damage_reduction > 0:
		damage = max(1, int(float(damage) * (1.0 - damage_reduction)))

	# Apply fortify damage reduction from command
	var fortify_reduction: float = float(command_effects.get("fortify", 0))
	if fortify_reduction > 0:
		damage = max(1, int(float(damage) * (1.0 - fortify_reduction)))

	castle_hp = max(0, castle_hp - damage)
	damage_taken_this_wave += damage
	damage_taken_this_day += damage
	combo = 0  # Break combo

	active_enemies.remove_at(enemy_index)

	if target_enemy_id == int(enemy.get("id", -1)):
		_target_closest_enemy()

	if castle_hp <= 0:
		_game_over()

func _start_planning_phase() -> void:
	current_phase = "planning"
	planning_timer = 30.0
	tip_timer = 0.0
	cursor_grid_pos = state.base_pos + Vector2i(2, 0)
	state.cursor_pos = cursor_grid_pos

	_update_objective("Build defenses! [color=cyan]Ctrl+Arrows[/color] to move cursor.\n[color=cyan]Tab[/color] for Kingdom Dashboard | Type [color=cyan]ready[/color] to start.")
	_update_hint("PLANNING: build <type> | upgrade | research | trade | status | ach | ready | Tab=dashboard")
	_update_grid_renderer()

	# Update dashboard state
	if kingdom_dashboard:
		kingdom_dashboard.update_state(state)

	# Show initial typing tip
	_show_random_tip()

	# Show act intro on first day of each act
	_show_act_intro()

func _start_defense_phase() -> void:
	current_phase = "defense"
	wave_start_time = Time.get_unix_time_from_system()
	damage_taken_this_wave = 0

	# Show boss intro on boss days (final wave only)
	if wave == waves_per_day and StoryManager.is_boss_day(day):
		_show_boss_intro()

	# Generate enemies for this wave
	_generate_wave_enemies()

	# Spawn first enemy immediately
	spawn_timer = 0.0

	# Display wave theme if non-standard
	var theme_name: String = str(current_wave_composition.get("theme_name", ""))
	var modifiers: Array = current_wave_composition.get("modifier_names", [])
	if not theme_name.is_empty() and theme_name != "Standard Assault":
		var wave_info: String = "[color=yellow]%s[/color]" % theme_name
		if not modifiers.is_empty():
			wave_info += " [color=orange](%s)[/color]" % ", ".join(modifiers)
		_update_objective(wave_info)
	else:
		_update_objective("Defeat the enemies! Type their words to attack.")

	_update_hint("Type the highlighted word to damage enemies. Combos increase power!")
	_update_grid_renderer()

func _generate_wave_enemies() -> void:
	enemy_queue.clear()
	active_enemies.clear()
	target_enemy_id = -1

	# Check if enemies are disabled (Zen mode)
	if SimDifficulty.are_enemies_disabled(difficulty_mode):
		return

	var is_boss_wave: bool = wave == waves_per_day and StoryManager.is_boss_day(day)

	# Use wave composer for varied enemy composition
	current_wave_composition = SimWaveComposer.compose_wave(day, wave, waves_per_day, state.rng_seed)
	var wave_size: int = SimDifficulty.apply_wave_size_modifier(int(current_wave_composition.get("enemy_count", 5)), difficulty_mode)
	var enemy_list: Array = current_wave_composition.get("enemies", [])
	var used_words: Dictionary = {}

	# Composition modifiers
	var hp_mult: float = float(current_wave_composition.get("hp_mult", 1.0))
	var speed_mult: float = float(current_wave_composition.get("speed_mult", 1.0))
	var affix_chances: Dictionary = current_wave_composition.get("affix_chances", {})

	# Apply endless mode scaling
	if is_endless_mode:
		var endless_scaling: Dictionary = SimEndlessMode.get_scaling(day)
		hp_mult *= float(endless_scaling.get("hp_mult", 1.0))
		speed_mult *= float(endless_scaling.get("speed_mult", 1.0))
		wave_size = int(float(wave_size) * float(endless_scaling.get("count_mult", 1.0)))

		# Check for swarm wave
		if SimEndlessMode.is_swarm_wave(day, wave, state.rng_seed):
			wave_size = int(wave_size * 2)
			hp_mult *= 0.5

		# Add endless mode affix chances
		var mods: Array[String] = SimEndlessMode.get_active_modifiers(day)
		if "affix_surge" in mods:
			affix_chances["armored"] = 0.2
			affix_chances["swift"] = 0.2

	# Generate enemies from composition
	for i in range(min(wave_size, enemy_list.size())):
		var kind: String = str(enemy_list[i]) if i < enemy_list.size() else "raider"

		# Validate enemy type exists, fallback to raider
		if not SimEnemies.ENEMY_TYPES.has(kind):
			kind = "raider"

		var base_hp: int = _get_enemy_hp(kind)
		var base_speed: float = SimEnemies.speed_for_day(kind, day)
		var modified_hp: int = max(1, int(float(base_hp) * hp_mult))
		var modified_speed: float = SimDifficulty.apply_speed_modifier(base_speed * speed_mult, difficulty_mode)

		var enemy: Dictionary = {
			"id": state.enemy_next_id,
			"kind": kind,
			"hp": modified_hp,
			"speed": modified_speed,
			"armor": SimEnemies.armor_for_day(kind, day),
			"pos": Vector2i.ZERO,
			"word": "",
			"move_progress": 0.0,
			"is_boss": false,
			"affixes": []
		}

		# Apply random affixes from composition
		for affix in affix_chances.keys():
			var roll: float = randf()
			if roll < float(affix_chances[affix]):
				enemy["affixes"].append(affix)

		# Assign word from current lesson
		var word: String = SimWords.word_for_enemy(state.rng_seed, day, kind, state.enemy_next_id, used_words, state.lesson_id)
		enemy["word"] = word.to_lower()
		used_words[enemy["word"]] = true

		state.enemy_next_id += 1
		enemy_queue.append(enemy)

	# Fill remaining slots if enemy_list was shorter than wave_size
	while enemy_queue.size() < wave_size:
		var kind: String = SimEnemies.choose_spawn_kind(state)
		var base_hp: int = _get_enemy_hp(kind)
		var base_speed: float = SimEnemies.speed_for_day(kind, day)
		var modified_hp: int = max(1, int(float(base_hp) * hp_mult))
		var modified_speed: float = SimDifficulty.apply_speed_modifier(base_speed * speed_mult, difficulty_mode)

		var enemy: Dictionary = {
			"id": state.enemy_next_id,
			"kind": kind,
			"hp": modified_hp,
			"speed": modified_speed,
			"armor": SimEnemies.armor_for_day(kind, day),
			"pos": Vector2i.ZERO,
			"word": "",
			"move_progress": 0.0,
			"is_boss": false,
			"affixes": []
		}

		var word: String = SimWords.word_for_enemy(state.rng_seed, day, kind, state.enemy_next_id, used_words, state.lesson_id)
		enemy["word"] = word.to_lower()
		used_words[enemy["word"]] = true

		state.enemy_next_id += 1
		enemy_queue.append(enemy)

	# Add boss enemy on boss waves
	if is_boss_wave:
		var boss: Dictionary = _create_boss_enemy(used_words)
		enemy_queue.append(boss)

func _create_boss_enemy(used_words: Dictionary) -> Dictionary:
	var boss_data: Dictionary = StoryManager.get_boss_for_day(day)
	var boss_kind: String = str(boss_data.get("kind", "boss"))
	var boss_name: String = str(boss_data.get("name", "Boss"))

	# Boss has significantly more HP
	var boss_hp: int = _get_enemy_hp(boss_kind) * 5 + day * 2

	# Boss uses harder words - get a longer word from the lesson
	var boss_word: String = SimWords.get_boss_word(state.lesson_id, used_words)
	if boss_word.is_empty():
		boss_word = SimWords.word_for_enemy(state.rng_seed, day, boss_kind, state.enemy_next_id, used_words, state.lesson_id)
	boss_word = boss_word.to_lower()
	used_words[boss_word] = true

	var base_boss_speed: float = max(1, SimEnemies.speed_for_day(boss_kind, day) - 1)  # Slower but tankier
	var modified_boss_speed: float = SimDifficulty.apply_speed_modifier(base_boss_speed, difficulty_mode)

	var boss: Dictionary = {
		"id": state.enemy_next_id,
		"kind": boss_kind,
		"name": boss_name,
		"hp": boss_hp,
		"max_hp": boss_hp,
		"speed": modified_boss_speed,
		"armor": SimEnemies.armor_for_day(boss_kind, day) + 2,
		"pos": Vector2i.ZERO,
		"word": boss_word,
		"move_progress": 0.0,
		"is_boss": true,
		"phase": 1,
		"max_phases": 3
	}

	state.enemy_next_id += 1
	return boss

func _get_enemy_hp(kind: String) -> int:
	var base: int = 2 + int(day / 3)
	var bonus: int = SimEnemies.hp_bonus_for_day(kind, day)
	var raw_hp: int = max(1, base + bonus)
	# Apply difficulty modifier
	return SimDifficulty.apply_health_modifier(raw_hp, difficulty_mode)

func _wave_complete() -> void:
	var was_boss_day: bool = wave == waves_per_day and StoryManager.is_boss_day(day)
	var old_lesson_id: String = state.lesson_id

	wave += 1

	# Gold reward
	var wave_bonus: int = 10 + wave * 5
	if castle_hp == castle_max_hp:
		wave_bonus = int(wave_bonus * 1.5)  # Perfect defense bonus
	gold += wave_bonus
	state.gold = gold

	# Check wave achievements
	_check_wave_achievements()

	# Show contextual tip based on performance
	_show_contextual_tip_after_wave()

	# Advance research
	if research_instance and not state.active_research.is_empty():
		var research_result: Dictionary = research_instance.advance_research(state)
		if research_result.completed:
			_update_objective("[color=lime]Research complete: %s![/color]" % research_result.research_id)

	# Apply building effects (wave healing from temples)
	var building_effects: Dictionary = SimBuildings.get_total_effects(state)
	var total_wave_heal: int = 2 + int(building_effects.get("wave_heal", 0))

	# Also add research wave heal bonus
	if research_instance:
		var research_effects: Dictionary = research_instance.get_total_effects(state)
		total_wave_heal += int(research_effects.get("wave_heal", 0))

	# Add skill wave heal bonus
	var learned_skills: Dictionary = TypingProfile.get_learned_skills(profile)
	total_wave_heal += SimSkills.get_wave_heal(learned_skills)

	# Add regen buff heal bonus
	var regen_value: float = _get_item_buff_value("regen")
	if regen_value > 0:
		total_wave_heal += int(regen_value)

	# Reset wave counters
	words_typed_this_wave = 0
	chain_kill_count = 0

	# Check lesson progression
	var accuracy: float = _get_accuracy()
	if accuracy >= lesson_accuracy_threshold and current_lesson_index < lesson_order.size() - 1:
		current_lesson_index += 1
		state.lesson_id = lesson_order[current_lesson_index]

	# Quest progress: wave completion
	_update_quest_progress("waves", 1)
	_update_quest_progress("accuracy", int(accuracy * 100))
	if damage_taken_this_wave == 0:
		_update_quest_progress("no_damage_wave", 1)
	if accuracy >= 0.95:
		_update_quest_progress("perfect_waves", 1)
	var wave_time: int = int(Time.get_unix_time_from_system() - wave_start_time)
	_update_quest_progress("fast_wave", wave_time)

	# Heal between waves
	castle_hp = min(castle_hp + total_wave_heal, castle_max_hp)

	# Day advancement
	if wave > waves_per_day:
		var completed_day: int = day  # Store before incrementing
		wave = 1
		day += 1
		state.day = day

		# Quest progress: day survived and no-damage day
		_update_quest_progress("days_survived", day)
		if damage_taken_this_day == 0:
			_update_quest_progress("no_damage_day", 1)
		damage_taken_this_day = 0  # Reset for next day

		# Check for act completion
		_check_act_completion(completed_day)

		# Apply daily production at the start of each new day
		_apply_daily_production()

		# Gain a worker each day (up to max)
		SimWorkers.gain_worker(state)

		# Autosave on day completion
		var save_result: Dictionary = GamePersistence.save_state(state)
		if save_result.ok:
			print("[Kingdom Defense] Autosaved on day %d" % day)

	# Show boss defeat dialogue if we just beat a boss
	if was_boss_day:
		_show_boss_defeat()
	elif state.lesson_id != old_lesson_id:
		# Lesson unlocked - show intro
		_show_lesson_intro(state.lesson_id)
	else:
		# Show wave feedback
		_show_wave_feedback()

	# Update dashboard
	if kingdom_dashboard:
		kingdom_dashboard.update_state(state)

	# Short delay then planning phase
	await get_tree().create_timer(1.5).timeout
	_start_planning_phase()

func _apply_daily_production() -> void:
	# Calculate and apply daily production
	var production: Dictionary = SimWorkers.daily_production_with_workers(state)

	# Apply worker upkeep first
	var upkeep_result: Dictionary = SimWorkers.apply_upkeep(state)
	if not upkeep_result.ok and upkeep_result.workers_lost > 0:
		_update_objective("[color=red]Lost %d workers due to food shortage![/color]" % upkeep_result.workers_lost)

	# Add production (food already reduced by upkeep)
	for res_key in production.keys():
		if res_key == "gold":
			state.gold += int(production[res_key])
		else:
			state.resources[res_key] = int(state.resources.get(res_key, 0)) + int(production[res_key])

	# Sync gold
	gold = state.gold

func _game_over() -> void:
	word_display.text = "[center][color=red]GAME OVER[/color]\nCastle Destroyed![/center]"
	input_field.editable = false
	current_phase = "gameover"

	# Handle endless mode game over
	if is_endless_mode:
		_end_endless_run()
		_update_objective("[color=yellow]ENDLESS RUN ENDED![/color] Final: Day %d, Wave %d, Kills %d, Max Combo %d" % [day, wave, endless_run_kills, max_combo])
	else:
		_update_objective("Game Over! Final score: Day %d, Gold %d, Max Combo %d" % [day, gold, max_combo])

func _on_input_changed(new_text: String) -> void:
	var old_len: int = typed_text.length()
	typed_text = new_text.to_lower()

	# Handle practice mode input specially
	if current_phase == "practice" and typed_text.length() > old_len:
		var last_char: String = typed_text[typed_text.length() - 1]
		_handle_practice_input(last_char)
		# Clear input after each key in practice mode
		if input_field:
			input_field.call_deferred("clear")
		return

	# Flash keyboard key on new character typed
	if keyboard_display and typed_text.length() > old_len:
		var last_char: String = typed_text[typed_text.length() - 1]
		var expected: String = ""
		if current_phase == "defense" and current_word.length() >= typed_text.length():
			expected = current_word[typed_text.length() - 1]
		elif current_phase == "planning":
			# In planning, any letter is valid
			expected = last_char
		var is_correct: bool = (last_char == expected)
		keyboard_display.flash_key(last_char, is_correct)

	if current_phase == "defense":
		_process_combat_typing()
	elif current_phase == "planning":
		_process_command_typing()

func _on_input_submitted(text: String) -> void:
	var lower_text: String = text.to_lower().strip_edges()

	if current_phase == "planning":
		if lower_text == "ready":
			_start_defense_phase()
		elif BUILD_COMMANDS.has(lower_text):
			_try_build(BUILD_COMMANDS[lower_text])
		elif lower_text == "upgrade":
			_try_upgrade_at_cursor()
		elif lower_text.begins_with("upgrade "):
			var building_type: String = lower_text.substr(8).strip_edges()
			_try_upgrade_building_type(building_type)
		elif lower_text == "status" or lower_text == "kingdom":
			_toggle_dashboard()
		elif lower_text == "settings" or lower_text == "options":
			_toggle_settings()
		elif lower_text == "workers":
			_show_dashboard_tab(1)  # Workers tab
		elif lower_text == "research":
			_show_dashboard_tab(3)  # Research tab
		elif lower_text.begins_with("research "):
			var research_name: String = lower_text.substr(9).strip_edges()
			_try_start_research(research_name)
		elif lower_text == "trade":
			_show_dashboard_tab(4)  # Trade tab
		elif lower_text.begins_with("trade "):
			_try_execute_trade(lower_text)
		elif lower_text == "info":
			_show_tile_info()
		elif lower_text == "achievements" or lower_text == "ach":
			_toggle_achievements()
		elif lower_text == "lore" or lower_text == "story":
			_toggle_lore()
		elif lower_text == "difficulty" or lower_text == "diff":
			_show_difficulty_options()
		elif lower_text.begins_with("diff "):
			_try_set_difficulty(lower_text.substr(5).strip_edges())
		elif lower_text == "effects" or lower_text == "debuffs":
			_show_status_effects_info()
		elif lower_text == "skills" or lower_text == "skill":
			_show_skills_info()
		elif lower_text.begins_with("learn "):
			_try_learn_skill(lower_text.substr(6).strip_edges())
		elif lower_text == "inventory" or lower_text == "inv" or lower_text == "items":
			_show_inventory()
		elif lower_text.begins_with("equip "):
			_try_equip_item(lower_text.substr(6).strip_edges())
		elif lower_text.begins_with("unequip "):
			_try_unequip_slot(lower_text.substr(8).strip_edges())
		elif lower_text == "equipment" or lower_text == "gear":
			_show_equipment()
		elif lower_text.begins_with("use "):
			_try_use_consumable(lower_text.substr(4).strip_edges())
		elif lower_text == "shop" or lower_text == "store":
			_show_shop()
		elif lower_text.begins_with("buy "):
			_try_buy_item(lower_text.substr(4).strip_edges())
		elif lower_text == "auto" or lower_text == "sentries" or lower_text == "autotowers":
			_show_auto_towers()
		elif lower_text == "help" or lower_text == "commands" or lower_text == "?":
			_show_help()
		elif lower_text == "spells" or lower_text == "abilities" or lower_text == "powers":
			_show_special_commands()
		elif lower_text == "quests" or lower_text == "missions" or lower_text == "q":
			_show_quests()
		elif lower_text.begins_with("claim "):
			_try_claim_quest(lower_text.substr(6).strip_edges())
		elif lower_text == "wave" or lower_text == "waveinfo":
			_show_wave_info()
		elif lower_text == "endless" or lower_text == "infinite":
			_show_endless_mode()
		elif lower_text == "startendless" or lower_text == "endless start":
			_start_endless_mode()
		elif lower_text == "daily" or lower_text == "challenge":
			_show_daily_challenge()
		elif lower_text == "startdaily" or lower_text == "startchallenge":
			_start_daily_challenge()
		elif lower_text == "tokens" or lower_text == "tokenshop":
			_show_token_shop()
		elif lower_text.begins_with("tokenbuy "):
			_try_buy_token_item(lower_text.substr(9).strip_edges())
		input_field.clear()
	elif current_phase == "defense":
		# Check for special commands first
		var command_id: String = SimSpecialCommands.match_command(typed_text)
		if not command_id.is_empty():
			_try_execute_command(command_id)
		elif typed_text == current_word:
			_attack_target_enemy()
		input_field.clear()

func _process_combat_typing() -> void:
	if current_word.is_empty():
		return

	# Check if typed text matches start of word
	if not current_word.begins_with(typed_text) and typed_text.length() > 0:
		# Mistake - break combo
		combo = 0
		total_chars += 1

	# Auto-complete on exact match
	if typed_text == current_word:
		_attack_target_enemy()

func _process_command_typing() -> void:
	# Highlight matching commands as user types
	pass  # Could add autocomplete hints here

func _attack_target_enemy() -> void:
	if target_enemy_id < 0:
		return

	var enemy_index: int = _find_enemy_index(target_enemy_id)
	if enemy_index < 0:
		_target_closest_enemy()
		return

	var enemy: Dictionary = active_enemies[enemy_index]
	var learned_skills: Dictionary = TypingProfile.get_learned_skills(profile)
	var equipment: Dictionary = TypingProfile.get_equipment(profile)
	var item_stats: Dictionary = SimItems.calculate_equipment_stats(equipment)

	# Calculate damage with power multiplier
	var power: float = _calculate_power()
	var damage: int = max(1, int(ceil(power)))

	# Apply equipment damage bonus
	var equip_damage_bonus: float = float(item_stats.get("damage_bonus", 0))
	if equip_damage_bonus > 0:
		damage = int(float(damage) * (1.0 + equip_damage_bonus))

	# Apply consumable damage buff
	var consumable_damage_buff: float = _get_item_buff_value("damage_buff")
	if consumable_damage_buff > 0:
		damage = int(float(damage) * (1.0 + consumable_damage_buff))

	# Apply all_buff (affects damage too)
	var all_buff_value: float = _get_item_buff_value("all_buff")
	if all_buff_value > 0:
		damage = int(float(damage) * (1.0 + all_buff_value))

	# Apply special command damage buff
	var cmd_damage_buff: float = float(command_effects.get("damage_buff", 0))
	if cmd_damage_buff > 0:
		damage = int(float(damage) * (1.0 + cmd_damage_buff))

	# Apply damage charges (BARRAGE)
	if int(command_effects.get("damage_charges", 0)) > 0:
		var mult: float = float(command_effects.get("damage_charge_mult", 2.0))
		damage = int(float(damage) * mult)
		command_effects["damage_charges"] = int(command_effects["damage_charges"]) - 1
		if int(command_effects.get("damage_charges", 0)) <= 0:
			command_effects.erase("damage_charges")
			command_effects.erase("damage_charge_mult")

	# Apply skill bonuses to damage
	# Burst typing (first 3 words per wave)
	var burst_bonus: float = SimSkills.get_burst_damage_bonus(learned_skills, words_typed_this_wave)
	if burst_bonus > 0:
		damage = int(float(damage) * (1.0 + burst_bonus))

	# Combo damage bonus
	var combo_bonus: float = SimSkills.get_combo_damage_bonus(learned_skills, combo)
	if combo_bonus > 0:
		damage = int(float(damage) * (1.0 + combo_bonus))

	# Perfect combo bonus (10+ combo)
	if SimSkills.has_perfect_combo_bonus(learned_skills, combo):
		damage = int(float(damage) * (1.0 + SimSkills.get_perfect_combo_damage(learned_skills)))

	# Chain kill bonus (kills within 2s)
	var current_time: float = Time.get_unix_time_from_system()
	if current_time - last_kill_time < 2.0:
		chain_kill_count += 1
		var chain_bonus: float = SimSkills.get_chain_damage_bonus(learned_skills) * float(chain_kill_count)
		if chain_bonus > 0:
			damage = int(float(damage) * (1.0 + chain_bonus))
	else:
		chain_kill_count = 0

	# Check for critical strike (skills + equipment + commands)
	var equip_crit_chance: float = float(item_stats.get("crit_chance", 0))
	var equip_crit_damage: float = float(item_stats.get("crit_damage", 0))
	var crit_chance: float = 0.05 + SimSkills.get_crit_chance_bonus(learned_skills) + equip_crit_chance
	var crit_damage_mult: float = 2.0 + SimSkills.get_crit_damage_bonus(learned_skills) + equip_crit_damage

	# Guaranteed crit from CRITICAL command
	var guaranteed_crit: bool = false
	if int(command_effects.get("crit_charges", 0)) > 0:
		guaranteed_crit = true
		command_effects["crit_charges"] = int(command_effects["crit_charges"]) - 1
		if int(command_effects.get("crit_charges", 0)) <= 0:
			command_effects.erase("crit_charges")

	var is_crit: bool = guaranteed_crit or randf() < crit_chance
	if is_crit:
		damage = int(float(damage) * crit_damage_mult)

	# Check for cleave effect (hit ALL enemies)
	var cleave_mult: float = float(command_effects.get("cleave_next", 0))
	if cleave_mult > 0:
		command_effects.erase("cleave_next")
		var cleave_damage: int = max(1, int(float(damage) * cleave_mult))
		var kills: int = 0
		for i in range(active_enemies.size() - 1, -1, -1):
			var e: Dictionary = active_enemies[i]
			if int(e.get("id", -1)) != int(enemy.get("id", -1)):
				e["hp"] = int(e.get("hp", 1)) - cleave_damage
				if int(e.get("hp", 0)) <= 0:
					kills += 1
					gold += 2  # Small gold for cleave kills
					active_enemies.remove_at(i)
				else:
					active_enemies[i] = e
		if kills > 0:
			_update_objective("[color=red]CLEAVE![/color] Hit all enemies, killed %d!" % kills)

	# Apply damage to main target
	enemy["hp"] = int(enemy.get("hp", 1)) - damage

	# Track stats
	correct_chars += current_word.length()
	total_chars += current_word.length()
	words_typed += 1
	words_typed_this_wave += 1
	var prev_combo: int = combo
	combo += 1
	max_combo = max(max_combo, combo)

	# Quest progress: words typed and combo
	_update_quest_progress("words_typed", 1)
	_update_quest_progress("max_combo", combo)

	# Challenge progress: words and combo
	if is_challenge_mode:
		_update_challenge_progress("words_typed", 1)
		_update_challenge_progress("words_without_break", 1)
		_update_challenge_progress("max_combo", combo)

	# Check for tier milestone and announce
	if SimCombo.is_tier_milestone(prev_combo, combo):
		var announcement: String = SimCombo.get_tier_announcement(combo)
		if not announcement.is_empty():
			_update_objective("[color=yellow]%s[/color]" % announcement)

	# Check combo achievements
	if achievement_checker != null and combo >= 5:
		achievement_checker.check_combo(profile, combo)
		TypingProfile.save_profile(profile)

	# Fire projectile visual
	if grid_renderer.has_method("fire_projectile"):
		var enemy_pos: Vector2i = enemy.get("pos", Vector2i.ZERO)
		grid_renderer.fire_projectile(state.base_pos, enemy_pos, Color(1, 0.8, 0.3))

	if int(enemy.get("hp", 0)) <= 0:
		# Enemy defeated
		var enemy_kind: String = str(enemy.get("kind", "raider"))
		var is_boss: bool = bool(enemy.get("is_boss", false)) or StoryManager.is_boss_kind(enemy_kind)
		var gold_reward: int = SimEnemies.gold_reward(enemy_kind)

		# Apply wave composition gold multiplier
		var wave_gold_mult: float = float(current_wave_composition.get("gold_mult", 1.0))
		if wave_gold_mult != 1.0:
			gold_reward = max(1, int(float(gold_reward) * wave_gold_mult))

		# Boss bonus rewards
		if is_boss:
			gold_reward = gold_reward * 5 + 50  # Significant boss bonus
			_update_objective("[color=lime]BOSS DEFEATED![/color] +%d Gold!" % gold_reward)

		# Apply combo tier bonus (replaces simple combo bonus)
		gold_reward = SimCombo.apply_gold_bonus(gold_reward, combo)

		# Apply skill gold bonus
		var skill_gold_bonus: float = SimSkills.get_gold_bonus(learned_skills)
		if skill_gold_bonus > 0:
			gold_reward = int(float(gold_reward) * (1.0 + skill_gold_bonus))

		# Apply equipment gold bonus
		var equip_gold_bonus: float = float(item_stats.get("gold_bonus", 0))
		if equip_gold_bonus > 0:
			gold_reward = int(float(gold_reward) * (1.0 + equip_gold_bonus))

		# Apply consumable gold buff
		var consumable_gold_buff: float = _get_item_buff_value("gold_buff")
		if consumable_gold_buff > 0:
			gold_reward = int(float(gold_reward) * (1.0 + consumable_gold_buff))

		# Apply all_buff (affects gold too)
		var all_buff_for_gold: float = _get_item_buff_value("all_buff")
		if all_buff_for_gold > 0:
			gold_reward = int(float(gold_reward) * (1.0 + all_buff_for_gold))

		# Apply special command gold buff
		var cmd_gold_buff: float = float(command_effects.get("gold_buff", 0))
		if cmd_gold_buff > 0:
			gold_reward = int(float(gold_reward) * (1.0 + cmd_gold_buff))

		# Apply difficulty modifier to gold
		gold_reward = SimDifficulty.apply_gold_modifier(gold_reward, difficulty_mode)
		gold += gold_reward

		# Award XP for kills (with equipment bonus)
		var base_xp: int = 10 if not is_boss else 100
		var equip_xp_bonus: float = float(item_stats.get("xp_bonus", 0))
		if equip_xp_bonus > 0:
			base_xp = int(float(base_xp) * (1.0 + equip_xp_bonus))
		var xp_result: Dictionary = TypingProfile.add_xp(profile, base_xp)
		if int(xp_result.get("levels_gained", 0)) > 0:
			var new_level: int = int(xp_result.get("new_level", 1))
			var sp_gained: int = int(xp_result.get("skill_points_gained", 0))
			_update_objective("[color=yellow]LEVEL UP![/color] Now level %d! +%d skill point(s)" % [new_level, sp_gained])

		# Track chain kills
		last_kill_time = Time.get_unix_time_from_system()

		# Check achievements for enemy defeat
		if achievement_checker != null:
			achievement_checker.on_enemy_defeated(profile, is_boss, enemy_kind)
			TypingProfile.save_profile(profile)

		# Roll for item drop
		var drop_seed: int = state.rng_seed + int(enemy.get("id", 0)) * 7
		var dropped_item: String = SimItems.roll_drop(day, is_boss, drop_seed)
		if not dropped_item.is_empty():
			TypingProfile.add_to_inventory(profile, dropped_item)
			TypingProfile.save_profile(profile)
			var item_display: String = SimItems.format_item_display(dropped_item)
			_update_objective("[color=lime]LOOT![/color] Found %s!" % item_display)

		# Quest progress: kills and gold
		_update_quest_progress("kills", 1)
		_update_quest_progress("total_kills", 1)
		_update_quest_progress("gold_earned", gold_reward)
		if is_boss:
			_update_quest_progress("boss_kills", 1)

		# Challenge mode progress: kills
		if is_challenge_mode:
			_update_challenge_progress("kill_count", 1)
			_update_challenge_progress("gold_earned", gold_reward)
			if is_boss:
				_update_challenge_progress("boss_kills", 1)

		# Endless mode kill tracking
		if is_endless_mode:
			endless_run_kills += 1

		# Critical hit visual
		if is_crit and grid_renderer.has_method("spawn_hit_particles"):
			var pos: Vector2i = enemy.get("pos", Vector2i.ZERO)
			grid_renderer.spawn_hit_particles(pos, 20, Color(1, 1, 0))

		# Spawn hit particles - more for bosses
		if grid_renderer.has_method("spawn_hit_particles"):
			var pos: Vector2i = enemy.get("pos", Vector2i.ZERO)
			var particle_count: int = 12 if not is_boss else 30
			var particle_color: Color = Color(1, 0.5, 0.2) if not is_boss else Color(1, 0.8, 0.1)
			grid_renderer.spawn_hit_particles(pos, particle_count, particle_color)

		active_enemies.remove_at(enemy_index)
		_target_closest_enemy()
	else:
		# Enemy damaged but alive - assign new word
		var used: Dictionary = {}
		for e in active_enemies:
			var w: String = str(e.get("word", ""))
			if w != "":
				used[w] = true
		var new_word: String = SimWords.word_for_enemy(state.rng_seed, day, str(enemy.get("kind", "raider")), int(enemy.get("id", 0)), used, state.lesson_id)
		enemy["word"] = new_word.to_lower()
		current_word = enemy["word"]
		active_enemies[enemy_index] = enemy

	input_field.clear()
	typed_text = ""
	word_start_time = Time.get_unix_time_from_system()

func _find_enemy_index(enemy_id: int) -> int:
	for i in range(active_enemies.size()):
		if int(active_enemies[i].get("id", -1)) == enemy_id:
			return i
	return -1

func _try_build(building_type: String) -> void:
	# Validate building type
	if not SimBuildings.is_valid(building_type):
		_update_objective("[color=red]Unknown building type![/color]")
		return

	# Get cost from SimBuildings
	var cost: Dictionary = SimBuildings.cost_for(building_type)

	# Check resources
	var can_afford: bool = true
	for res in cost.keys():
		var have: int = int(state.resources.get(res, 0))
		if res == "gold":
			have = state.gold
		if have < int(cost.get(res, 0)):
			can_afford = false
			break

	if not can_afford:
		_update_objective("[color=red]Not enough resources![/color]")
		return

	# Check if buildable at cursor
	if not SimMap.is_buildable(state, cursor_grid_pos):
		_update_objective("[color=red]Cannot build there![/color]")
		return

	# Check path still open after build (only for blocking buildings)
	var test_index: int = cursor_grid_pos.y * state.map_w + cursor_grid_pos.x
	if SimBuildings.is_blocking(building_type):
		state.structures[test_index] = building_type
		if not SimMap.path_open_to_base(state):
			state.structures.erase(test_index)
			_update_objective("[color=red]Would block enemy path![/color]")
			return
	else:
		state.structures[test_index] = building_type

	# Deduct resources
	for res in cost.keys():
		if res == "gold":
			state.gold -= int(cost[res])
		else:
			state.resources[res] = int(state.resources.get(res, 0)) - int(cost.get(res, 0))

	# Update building counts
	state.buildings[building_type] = int(state.buildings.get(building_type, 0)) + 1

	_update_objective("[color=green]Built %s![/color]" % building_type)
	_update_grid_renderer()
	if kingdom_dashboard:
		kingdom_dashboard.update_state(state)

# Kingdom management command handlers

func _toggle_dashboard() -> void:
	if kingdom_dashboard:
		if kingdom_dashboard.visible:
			kingdom_dashboard.hide_dashboard()
		else:
			kingdom_dashboard.update_state(state)
			kingdom_dashboard.show_dashboard()

func _show_dashboard_tab(tab_index: int) -> void:
	if kingdom_dashboard:
		kingdom_dashboard.update_state(state)
		kingdom_dashboard.show_dashboard()
		if kingdom_dashboard._tabs:
			kingdom_dashboard._tabs.current_tab = tab_index

func _try_upgrade_at_cursor() -> void:
	var index: int = cursor_grid_pos.y * state.map_w + cursor_grid_pos.x
	if not state.structures.has(index):
		_update_objective("[color=red]No building at cursor![/color]")
		return

	var check: Dictionary = SimBuildings.can_upgrade(state, index)
	if not check.ok:
		_update_objective("[color=red]Cannot upgrade: %s[/color]" % check.reason)
		return

	if SimBuildings.apply_upgrade(state, index):
		var building_type: String = str(state.structures[index])
		_update_objective("[color=green]Upgraded %s to level %d![/color]" % [building_type, check.next_level])
		_update_grid_renderer()
		if kingdom_dashboard:
			kingdom_dashboard.update_state(state)

func _try_upgrade_building_type(building_type: String) -> void:
	# Find first building of this type that can be upgraded
	for key in state.structures.keys():
		if str(state.structures[key]) == building_type:
			var check: Dictionary = SimBuildings.can_upgrade(state, int(key))
			if check.ok:
				if SimBuildings.apply_upgrade(state, int(key)):
					_update_objective("[color=green]Upgraded %s to level %d![/color]" % [building_type, check.next_level])
					_update_grid_renderer()
					if kingdom_dashboard:
						kingdom_dashboard.update_state(state)
					return

	_update_objective("[color=red]No %s available to upgrade![/color]" % building_type)

func _try_start_research(research_name: String) -> void:
	if research_instance == null:
		return

	# Find research by label or id
	var all_research: Array = research_instance.get_all_research()
	var research_id: String = ""

	for item in all_research:
		var item_id: String = str(item.get("id", ""))
		var item_label: String = str(item.get("label", "")).to_lower()
		if item_id == research_name or item_label == research_name:
			research_id = item_id
			break

	if research_id.is_empty():
		_update_objective("[color=red]Unknown research: %s[/color]" % research_name)
		return

	var check: Dictionary = research_instance.can_start_research(state, research_id)
	if not check.ok:
		_update_objective("[color=red]Cannot research: %s[/color]" % check.reason)
		return

	if research_instance.start_research(state, research_id):
		var research: Dictionary = research_instance.get_research(research_id)
		_update_objective("[color=cyan]Started research: %s[/color]" % str(research.get("label", research_id)))
		if kingdom_dashboard:
			kingdom_dashboard.update_state(state)

func _try_execute_trade(command: String) -> void:
	var parsed: Dictionary = SimTrade.parse_trade_command(command)
	if not parsed.ok:
		_update_objective("[color=red]Invalid trade: %s[/color]" % parsed.reason)
		return

	var result: Dictionary = SimTrade.execute_trade(state, parsed.from_resource, parsed.to_resource, parsed.amount)
	if result.ok:
		_update_objective("[color=green]Traded %d %s for %d %s![/color]" % [result.from_amount, result.from_resource, result.to_amount, result.to_resource])
		if kingdom_dashboard:
			kingdom_dashboard.update_state(state)
	else:
		_update_objective("[color=red]Trade failed: %s[/color]" % result.reason)

func _show_tile_info() -> void:
	var report: Dictionary = SimBuildings.get_tile_report(state, cursor_grid_pos)
	var info_parts: Array = []

	info_parts.append("Pos: (%d,%d)" % [cursor_grid_pos.x, cursor_grid_pos.y])
	info_parts.append("Terrain: %s" % report.terrain)

	if not report.structure.is_empty():
		info_parts.append("Building: %s Lv%d" % [report.structure, report.structure_level])
		var preview: Dictionary = SimBuildings.get_building_upgrade_preview(state, cursor_grid_pos.y * state.map_w + cursor_grid_pos.x)
		if preview.can_upgrade:
			info_parts.append("Upgrade available!")

	_update_objective("[color=cyan]%s[/color]" % " | ".join(info_parts))

func _calculate_power() -> float:
	var accuracy: float = _get_accuracy()
	var combo_bonus: float = min(combo * 0.1, 1.0)  # Max +100% from combo
	var accuracy_bonus: float = accuracy * 0.5  # Max +50% from accuracy

	# Add typing power bonuses from buildings and research
	var typing_power_bonus: float = 0.0

	# Building effects (barracks, etc.)
	var building_effects: Dictionary = SimBuildings.get_total_effects(state)
	typing_power_bonus += float(building_effects.get("typing_power", 0.0))

	# Research effects
	if research_instance:
		var research_effects: Dictionary = research_instance.get_total_effects(state)
		typing_power_bonus += float(research_effects.get("typing_power", 0.0))

		# Apply combo multiplier from research
		var combo_mult: float = float(research_effects.get("combo_multiplier", 0.0))
		if combo_mult > 0:
			combo_bonus = combo_bonus * (1.0 + combo_mult)

	return 1.0 + combo_bonus + accuracy_bonus + typing_power_bonus

func _get_accuracy() -> float:
	if total_chars == 0:
		return 1.0
	return float(correct_chars) / float(total_chars)

func _get_wpm() -> float:
	if words_typed == 0:
		return 0.0
	var elapsed: float = Time.get_unix_time_from_system() - wave_start_time
	if elapsed < 1.0:
		return 0.0
	return (float(words_typed) / elapsed) * 60.0

func _update_ui() -> void:
	# Top bar - show day and difficulty
	var diff_short: String = difficulty_mode.capitalize().substr(0, 3)
	day_label.text = "Day %d [%s]" % [day, diff_short]
	wave_label.text = "Wave %d/%d" % [wave, waves_per_day]
	hp_value.text = "%d/%d" % [castle_hp, castle_max_hp]
	gold_value.text = "%d" % gold
	resources_label.text = "Wood: %d | Stone: %d | Food: %d" % [
		int(state.resources.get("wood", 0)),
		int(state.resources.get("stone", 0)),
		int(state.resources.get("food", 0))
	]

	var lesson_name: String = SimLessons.lesson_label(state.lesson_id)
	lesson_label.text = "Lesson: %s" % lesson_name

	# Update act label
	if act_label:
		var act_progress: Dictionary = StoryManager.get_act_progress(day)
		act_label.text = "Act %d: %s (Day %d/%d)" % [
			int(act_progress.get("act_number", 1)),
			str(act_progress.get("act_name", "Unknown")),
			int(act_progress.get("day_in_act", 1)),
			int(act_progress.get("total_days", 1))
		]

	phase_label.text = current_phase.to_upper()
	if current_phase == "planning":
		phase_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
	elif current_phase == "practice":
		phase_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.3))
	else:
		phase_label.add_theme_color_override("font_color", Color(0.9, 0.5, 0.4))

	# Stats bar
	wpm_label.text = "WPM: %d" % int(_get_wpm())
	accuracy_label.text = "Accuracy: %d%%" % int(_get_accuracy() * 100)

	# Combo with tier display
	var combo_display: String = SimCombo.format_combo_display(combo)
	if combo_display.is_empty():
		combo_label.text = "Combo: %d" % combo
		combo_label.add_theme_color_override("font_color", Color.WHITE)
	else:
		combo_label.text = combo_display
		combo_label.add_theme_color_override("font_color", SimCombo.get_tier_color(combo))

	power_label.text = "Power: %.1fx" % _calculate_power()

	# Word display
	if current_phase == "defense" and not current_word.is_empty():
		_update_word_display()
	elif current_phase == "planning":
		word_display.text = "[center][color=white]Planning Phase[/color]\nTime: %d seconds[/center]" % int(planning_timer)

	# Enemy panel
	_update_enemy_panel()

	# Update keyboard display
	_update_keyboard_display()

func _update_word_display() -> void:
	var display: String = "[center]"
	for i in range(current_word.length()):
		var ch: String = current_word[i]
		if i < typed_text.length():
			if typed_text[i] == ch:
				display += "[color=lime]%s[/color]" % ch
			else:
				display += "[color=red]%s[/color]" % ch
		else:
			display += "[color=yellow]%s[/color]" % ch
	display += "[/center]"
	word_display.text = display
	input_display.text = typed_text

func _update_enemy_panel() -> void:
	# Current target
	if target_enemy_id >= 0:
		var enemy_index: int = _find_enemy_index(target_enemy_id)
		if enemy_index >= 0:
			var enemy: Dictionary = active_enemies[enemy_index]
			# Get effective speed with status effects
			var effective_speed: int = SimEnemies.get_effective_speed(enemy)
			var base_speed: int = int(enemy.get("speed", 1))
			var speed_text: String = str(effective_speed)
			if effective_speed < base_speed:
				speed_text = "[color=cyan]%d[/color]" % effective_speed  # Slowed
			elif SimEnemies.is_immobilized(enemy):
				speed_text = "[color=aqua]FROZEN[/color]"
			# Get status effects summary
			var effects_text: String = ""
			var effects: Array[Dictionary] = SimEnemies.get_status_summary(enemy)
			if effects.size() > 0:
				var effect_parts: Array[String] = []
				for eff in effects:
					var color_hex: String = str(eff.get("color", Color.WHITE)).substr(0, 7)
					var stacks: int = int(eff.get("stacks", 1))
					var name: String = str(eff.get("name", ""))
					if stacks > 1:
						effect_parts.append("[color=%s]%s x%d[/color]" % [color_hex, name, stacks])
					else:
						effect_parts.append("[color=%s]%s[/color]" % [color_hex, name])
				effects_text = "\n" + ", ".join(effect_parts)
			current_enemy_label.text = "[center][color=yellow]TARGET[/color]\n[color=orange]%s[/color]\nHP: %d  Speed: %s%s[/center]" % [
				str(enemy.get("kind", "enemy")).to_upper(),
				int(enemy.get("hp", 0)),
				speed_text,
				effects_text
			]
		else:
			current_enemy_label.text = "[center][color=gray]No target[/color][/center]"
	else:
		current_enemy_label.text = "[center][color=gray]No target[/color][/center]"

	# Queue list
	var queue_text: String = ""
	var combined: Array = active_enemies.duplicate()
	var count: int = 1
	for enemy in combined.slice(0, 5):
		if int(enemy.get("id", -1)) == target_enemy_id:
			queue_text += "[color=yellow]> %d. %s (HP: %d)[/color]\n" % [count, str(enemy.get("word", "")), int(enemy.get("hp", 0))]
		else:
			queue_text += "%d. %s (HP: %d)\n" % [count, str(enemy.get("kind", "enemy")), int(enemy.get("hp", 0))]
		count += 1

	var remaining: int = combined.size() + enemy_queue.size() - 5
	if remaining > 0:
		queue_text += "... and %d more" % remaining

	queue_list.text = queue_text

func _update_keyboard_display() -> void:
	if not keyboard_display:
		return

	# Get charset from current lesson
	var lesson: Dictionary = SimLessons.get_lesson(state.lesson_id)
	var charset: String = str(lesson.get("charset", "abcdefghijklmnopqrstuvwxyz"))

	# Determine next key to press
	var next_key: String = ""
	if current_phase == "defense" and current_word.length() > typed_text.length():
		next_key = current_word[typed_text.length()]
	elif current_phase == "planning":
		# In planning phase, show command keys as active
		charset = "abcdefghijklmnopqrstuvwxyz "

	keyboard_display.update_state(charset, next_key)

	# Update finger hint
	_update_finger_hint(next_key)

func _update_finger_hint(next_key: String) -> void:
	if not finger_hint_label:
		return

	if not show_finger_hints or next_key.is_empty():
		finger_hint_label.text = ""
		return

	var finger: String = StoryManager.get_finger_for_key(next_key)
	if finger.is_empty():
		finger_hint_label.text = ""
	else:
		finger_hint_label.text = "Next key '%s' - Use: %s" % [next_key.to_upper(), finger]

func _update_objective(text: String) -> void:
	objective_label.text = "[b]OBJECTIVE[/b]\n%s" % text

func _update_hint(text: String) -> void:
	hint_label.text = text

func _update_grid_renderer() -> void:
	if grid_renderer and grid_renderer.has_method("update_state"):
		state.cursor_pos = cursor_grid_pos
		grid_renderer.update_state(state)

		# Highlight target enemy
		var highlights: Array = []
		if target_enemy_id >= 0:
			highlights.append(target_enemy_id)
		if grid_renderer.has_method("set_enemy_highlights"):
			grid_renderer.set_enemy_highlights(highlights, target_enemy_id)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		# F1 key toggles settings panel
		if event.keycode == KEY_F1:
			_toggle_settings()
			get_viewport().set_input_as_handled()
			return

		# Tab key toggles kingdom dashboard during planning phase
		if event.keycode == KEY_TAB and current_phase == "planning":
			_toggle_dashboard()
			get_viewport().set_input_as_handled()
			return

		# Handle planning phase input
		if current_phase == "planning":
			# Use Ctrl+Arrow keys for grid cursor movement (doesn't conflict with typing)
			var moved: bool = false

			if event.ctrl_pressed:
				match event.keycode:
					KEY_UP:
						cursor_grid_pos.y = max(0, cursor_grid_pos.y - 1)
						moved = true
					KEY_DOWN:
						cursor_grid_pos.y = min(state.map_h - 1, cursor_grid_pos.y + 1)
						moved = true
					KEY_LEFT:
						cursor_grid_pos.x = max(0, cursor_grid_pos.x - 1)
						moved = true
					KEY_RIGHT:
						cursor_grid_pos.x = min(state.map_w - 1, cursor_grid_pos.x + 1)
						moved = true

			if moved:
				state.cursor_pos = cursor_grid_pos
				_update_grid_renderer()
				get_viewport().set_input_as_handled()

func _on_menu_pressed() -> void:
	if game_controller:
		game_controller.go_to_menu()

# Story dialogue functions
func _show_game_start_dialogue() -> void:
	if not dialogue_box:
		game_started = true
		_start_key_practice(state.lesson_id)
		return

	var speaker: String = StoryManager.get_dialogue_speaker("game_start")
	var lines: Array[String] = StoryManager.get_dialogue_lines("game_start")

	if lines.is_empty():
		game_started = true
		_show_lesson_intro(state.lesson_id)
		return

	waiting_for_dialogue = true
	dialogue_box.show_dialogue(speaker, lines)

func _show_act_intro() -> void:
	if not dialogue_box:
		return

	if not StoryManager.should_show_act_intro(day, last_act_intro_day):
		return

	last_act_intro_day = day
	var act: Dictionary = StoryManager.get_act_for_day(day)
	if act.is_empty():
		return

	var speaker: String = StoryManager.get_mentor_name(day)
	var intro_text: String = StoryManager.get_act_intro_text(day)

	if intro_text.is_empty():
		return

	var lines: Array[String] = [intro_text]
	waiting_for_dialogue = true
	dialogue_box.show_dialogue(speaker, lines)

func _show_boss_intro() -> void:
	if not dialogue_box:
		return

	var boss: Dictionary = StoryManager.get_boss_for_day(day)
	if boss.is_empty():
		return

	var boss_name: String = str(boss.get("name", "Boss"))
	var intro_text: String = str(boss.get("intro", ""))
	var taunt: String = str(boss.get("taunt", ""))

	var lines: Array[String] = []
	if not intro_text.is_empty():
		lines.append(intro_text)
	if not taunt.is_empty():
		lines.append("[color=red]%s[/color]: \"%s\"" % [boss_name, taunt])

	if lines.is_empty():
		return

	waiting_for_dialogue = true
	dialogue_box.show_dialogue("", lines)

func _show_boss_defeat() -> void:
	if not dialogue_box:
		return

	var boss: Dictionary = StoryManager.get_boss_for_day(day)
	if boss.is_empty():
		return

	var boss_name: String = str(boss.get("name", "Boss"))
	var defeat_text: String = str(boss.get("defeat", ""))

	if defeat_text.is_empty():
		return

	var lines: Array[String] = ["[color=red]%s[/color]: \"%s\"" % [boss_name, defeat_text]]

	var speaker: String = StoryManager.get_mentor_name(day)
	var victory_lines: Array[String] = StoryManager.get_dialogue_lines("boss_victory", {"boss_name": boss_name})
	lines.append_array(victory_lines)

	waiting_for_dialogue = true
	dialogue_box.show_dialogue(speaker, lines)

func _on_dialogue_finished() -> void:
	waiting_for_dialogue = false

	if not game_started:
		game_started = true
		# Show lesson intro for first lesson with practice
		_show_lesson_intro(state.lesson_id)
		return

	# Check if we have a pending practice session
	if not pending_practice_lesson.is_empty():
		var lesson_to_practice: String = pending_practice_lesson
		pending_practice_lesson = ""
		_start_key_practice(lesson_to_practice)
		return

	# Check if practice just completed
	if current_phase == "practice" and not practice_mode:
		_start_planning_phase()
		return

	# Default: return focus to input
	if input_field:
		input_field.grab_focus()

# Educational feature functions
func _show_random_tip(context: String = "") -> void:
	if not tip_label:
		return

	var tip: String = ""

	# Use contextual tips when context is provided
	if not context.is_empty():
		tip = StoryManager.get_contextual_tip(context)
	else:
		# Try to get a lesson-specific tip first, fall back to general tips
		tip = StoryManager.get_random_lesson_tip(state.lesson_id)

	if not tip.is_empty():
		tip_label.text = "Tip: " + tip

func _show_contextual_tip_after_wave() -> void:
	# Determine context based on performance
	var accuracy: float = _get_accuracy()
	var context: String = ""

	if accuracy < 0.7:
		context = "error"  # Many errors - show error recovery tips
	elif accuracy < 0.85:
		context = "accuracy"  # Needs accuracy work
	elif _get_wpm() < 20:
		context = "slow"  # Needs rhythm tips
	else:
		context = "practice"  # General practice tips

	_show_random_tip(context)

func _show_lesson_intro(lesson_id: String) -> void:
	if not dialogue_box:
		# No dialogue box - go straight to practice
		_start_key_practice(lesson_id)
		return

	var lines: Array[String] = StoryManager.get_lesson_intro_lines(lesson_id)
	if lines.is_empty():
		# No intro lines - go straight to practice
		_start_key_practice(lesson_id)
		return

	var title: String = StoryManager.get_lesson_title(lesson_id)
	var speaker: String = "Elder Lyra"
	var intro: Dictionary = StoryManager.get_lesson_intro(lesson_id)
	if intro.has("speaker"):
		speaker = str(intro.get("speaker", speaker))

	# Prepend title if available
	if not title.is_empty():
		lines.insert(0, "[color=yellow]" + title + "[/color]")

	# Add practice prompt at the end
	lines.append("[color=cyan]Now let's practice these keys![/color]")

	# Mark that we should start practice after this dialogue
	pending_practice_lesson = lesson_id

	waiting_for_dialogue = true
	dialogue_box.show_dialogue(speaker, lines)

func _show_wave_feedback() -> void:
	if not dialogue_box:
		return

	var accuracy_pct: float = _get_accuracy() * 100.0
	var wpm: float = _get_wpm()

	var feedback_lines: Array[String] = []

	# Accuracy feedback
	var acc_feedback: String = StoryManager.get_accuracy_feedback(accuracy_pct)
	if not acc_feedback.is_empty():
		feedback_lines.append(acc_feedback)

	# Speed feedback
	var speed_feedback: String = StoryManager.get_speed_feedback(wpm)
	if not speed_feedback.is_empty():
		feedback_lines.append(speed_feedback)

	# Combo feedback
	if max_combo >= 5:
		var combo_feedback: String = StoryManager.get_combo_feedback(max_combo)
		if not combo_feedback.is_empty():
			feedback_lines.append(combo_feedback)

	# WPM milestone check
	var wpm_int: int = int(wpm)
	var milestone_thresholds: Array[int] = [100, 80, 70, 60, 50, 40, 30, 20]
	for threshold in milestone_thresholds:
		if wpm_int >= threshold and last_wpm_milestone < threshold:
			last_wpm_milestone = threshold
			var milestone_msg: String = StoryManager.get_wpm_milestone_message(wpm_int)
			if not milestone_msg.is_empty():
				feedback_lines.insert(0, "[color=gold]" + milestone_msg + "[/color]")
			break

	if feedback_lines.is_empty():
		return

	# Add a random tip
	var tip: String = StoryManager.get_random_typing_tip()
	if not tip.is_empty():
		feedback_lines.append("[color=cyan]Tip: " + tip + "[/color]")

	waiting_for_dialogue = true
	dialogue_box.show_dialogue("Elder Lyra", feedback_lines)

func _check_lesson_progression() -> void:
	var old_lesson: String = previous_lesson_id
	var new_lesson: String = state.lesson_id

	if old_lesson != new_lesson and not old_lesson.is_empty():
		# Lesson changed - show introduction
		_show_lesson_intro(new_lesson)

	previous_lesson_id = new_lesson

# Key Practice Mode Functions
func _start_key_practice(lesson_id: String) -> void:
	# Get the keys to practice from the lesson intro
	var intro: Dictionary = StoryManager.get_lesson_intro(lesson_id)
	var keys: Array = intro.get("keys", [])

	if keys.is_empty():
		# No specific keys to practice, skip to planning
		_start_planning_phase()
		return

	# Convert to typed array
	practice_keys.clear()
	for k in keys:
		practice_keys.append(str(k).to_lower())

	practice_lesson_id = lesson_id
	practice_index = 0
	practice_correct_count = 0
	practice_attempts = 0
	practice_mode = true
	current_phase = "practice"

	# Clear input field and set focus
	if input_field:
		input_field.clear()
		input_field.grab_focus()

	_update_practice_ui()

func _update_practice_ui() -> void:
	if practice_index >= practice_keys.size():
		return

	var current_key: String = practice_keys[practice_index]
	var finger: String = StoryManager.get_finger_for_key(current_key)
	var progress: String = "%d / %d" % [practice_index + 1, practice_keys.size()]

	# Update word display to show practice prompt
	if word_display:
		var display_key: String = current_key.to_upper() if current_key != " " else "SPACE"
		word_display.text = "[center][color=yellow]Practice Key:[/color]\n[color=white][font_size=48]%s[/font_size][/color][/center]" % display_key

	# Update finger hint
	if finger_hint_label:
		if not finger.is_empty():
			finger_hint_label.text = "Press '%s' with your %s" % [current_key.to_upper() if current_key != " " else "SPACE", finger]
		else:
			finger_hint_label.text = "Press the highlighted key"

	# Update hint label with progress
	if hint_label:
		hint_label.text = "KEY PRACTICE: %s - Press each key as it's highlighted" % progress

	# Update objective
	if objective_label:
		var title: String = StoryManager.get_lesson_title(practice_lesson_id)
		if title.is_empty():
			title = "New Lesson"
		objective_label.text = "[b]%s[/b]\nPractice pressing each new key.\nWatch the keyboard highlight!" % title

	# Update keyboard display to highlight the practice key
	# Use practice keys as the active charset so all practice keys are visible
	if keyboard_display:
		var practice_charset: String = ""
		for k in practice_keys:
			practice_charset += k
		keyboard_display.update_state(practice_charset, current_key)

func _handle_practice_input(key_pressed: String) -> void:
	if not practice_mode or practice_index >= practice_keys.size():
		return

	var expected_key: String = practice_keys[practice_index]
	practice_attempts += 1

	if key_pressed.to_lower() == expected_key:
		# Correct key pressed!
		practice_correct_count += 1
		practice_index += 1

		# Flash the key green
		if keyboard_display:
			keyboard_display.flash_key(key_pressed, true)

		# Check if practice is complete
		if practice_index >= practice_keys.size():
			_complete_key_practice()
		else:
			# Move to next key after short delay
			await get_tree().create_timer(0.3).timeout
			if practice_mode:  # Check still in practice mode
				_update_practice_ui()
	else:
		# Wrong key - flash red and show encouragement
		if keyboard_display:
			keyboard_display.flash_key(key_pressed, false)

		# Show hint about correct key
		if tip_label:
			var finger: String = StoryManager.get_finger_for_key(expected_key)
			tip_label.text = "Try again! Look for the highlighted key on the keyboard."

func _complete_key_practice() -> void:
	practice_mode = false

	var accuracy: float = 100.0
	if practice_attempts > 0:
		accuracy = (float(practice_correct_count) / float(practice_attempts)) * 100.0

	# Show completion message
	var lines: Array[String] = []
	if accuracy >= 100.0:
		lines.append("[color=lime]Perfect![/color] You pressed every key correctly!")
	elif accuracy >= 80.0:
		lines.append("[color=yellow]Well done![/color] You're getting the hang of these keys.")
	else:
		lines.append("Good effort! These keys will become easier with practice.")

	lines.append("Now let's put your new skills to the test in battle!")

	if dialogue_box:
		waiting_for_dialogue = true
		dialogue_box.show_dialogue("Elder Lyra", lines)
	else:
		_start_planning_phase()

func _skip_practice() -> void:
	practice_mode = false
	practice_keys.clear()
	practice_index = 0
	_start_planning_phase()

# Achievement System Functions

func _toggle_achievements() -> void:
	if achievement_panel:
		if achievement_panel.visible:
			achievement_panel.hide_achievements()
		else:
			achievement_panel.show_achievements(profile)

func _check_wave_achievements() -> void:
	if achievement_checker == null:
		return

	# Build stats dictionary for achievement checker
	var accuracy: float = _get_accuracy()
	var wpm: float = _get_wpm()
	var won: bool = castle_hp > 0

	var stats: Dictionary = {
		"accuracy": accuracy,
		"wpm": wpm,
		"damage_taken": damage_taken_this_wave,
		"hp_remaining": castle_hp,
		"won": won,
		"best_combo": max_combo
	}

	# Check wave-related achievements
	achievement_checker.on_wave_complete(profile, stats)

	# Also check lesson mastery achievements
	var mastered: Array = []
	var progress_map: Dictionary = TypingProfile.get_lesson_progress_map(profile)
	for lesson_id in progress_map.keys():
		var progress: Dictionary = progress_map[lesson_id]
		if int(progress.get("goal_passes", 0)) >= 3:
			mastered.append(lesson_id)

	if not mastered.is_empty():
		achievement_checker.check_lesson_mastery(profile, mastered)

	# Save profile with any new achievements
	TypingProfile.save_profile(profile)

func _show_difficulty_options() -> void:
	var current_name: String = SimDifficulty.get_mode_name(difficulty_mode)
	var unlocked: Array[String] = SimDifficulty.get_unlocked_modes(profile)

	var lines: Array[String] = []
	lines.append("[color=yellow]Current Difficulty: %s[/color]" % current_name)
	lines.append("")
	lines.append("Available modes (type 'diff <mode>'):")

	for mode_id in unlocked:
		var mode: Dictionary = SimDifficulty.get_mode(mode_id)
		var name: String = str(mode.get("name", mode_id))
		var desc: String = str(mode.get("description", ""))
		var marker: String = " [CURRENT]" if mode_id == difficulty_mode else ""
		lines.append("  [color=cyan]%s[/color]%s - %s" % [mode_id, marker, desc])

	# Show locked modes
	var all_modes: Array[String] = SimDifficulty.get_all_mode_ids()
	for mode_id in all_modes:
		if not mode_id in unlocked:
			var mode: Dictionary = SimDifficulty.get_mode(mode_id)
			var name: String = str(mode.get("name", mode_id))
			lines.append("  [color=gray]%s[/color] [LOCKED] - Complete more acts to unlock" % mode_id)

	_update_log(lines)

func _try_set_difficulty(mode_id: String) -> void:
	if not SimDifficulty.is_mode_unlocked(mode_id, profile):
		_update_objective("[color=red]Difficulty '%s' is locked. Complete more acts to unlock.[/color]" % mode_id)
		return

	var mode: Dictionary = SimDifficulty.get_mode(mode_id)
	if mode.is_empty():
		_update_objective("[color=red]Unknown difficulty '%s'. Type 'diff' to see options.[/color]" % mode_id)
		return

	difficulty_mode = mode_id
	TypingProfile.set_difficulty_mode(profile, mode_id)
	TypingProfile.save_profile(profile)

	var name: String = SimDifficulty.get_mode_name(mode_id)
	_update_objective("[color=lime]Difficulty set to: %s[/color]" % name)

func _show_status_effects_info() -> void:
	var lines: Array[String] = []
	lines.append("[color=yellow]STATUS EFFECTS[/color]")
	lines.append("")
	lines.append("[color=cyan]Movement Effects:[/color]")
	lines.append("  [color=#87CEEB]Slowed[/color] - Movement speed reduced (15-60%)")
	lines.append("  [color=#00BFFF]Frozen[/color] - Completely immobilized, +50% damage taken")
	lines.append("  [color=#228B22]Rooted[/color] - Held in place by roots")
	lines.append("")
	lines.append("[color=orange]Damage Over Time:[/color]")
	lines.append("  [color=#FF4500]Burning[/color] - 3 fire damage/sec (stacks x5)")
	lines.append("  [color=#9932CC]Poisoned[/color] - 2 poison damage/sec, reduces healing (stacks x10)")
	lines.append("  [color=#8B0000]Bleeding[/color] - 4 physical damage/2sec (stacks x3)")
	lines.append("  [color=#4B0082]Corrupting[/color] - 5 corruption damage/sec, reduces max HP")
	lines.append("")
	lines.append("[color=gray]Defensive Reduction:[/color]")
	lines.append("  [color=#808080]Armor Broken[/color] - Armor reduced by 50%")
	lines.append("  [color=#FF69B4]Exposed[/color] - Takes +25% damage from all sources")
	lines.append("  [color=#D3D3D3]Weakened[/color] - Deals 30% less damage")
	lines.append("")
	lines.append("[color=white]Special towers and skills can apply these effects!")
	_update_log(lines)

func _show_skills_info() -> void:
	var lines: Array[String] = []
	var level: int = TypingProfile.get_player_level(profile)
	var xp: int = TypingProfile.get_player_xp(profile)
	var xp_needed: int = TypingProfile.xp_for_level(level)
	var skill_points: int = TypingProfile.get_skill_points(profile)
	var learned_skills: Dictionary = TypingProfile.get_learned_skills(profile)

	lines.append("[color=yellow]SKILLS[/color]")
	lines.append("Level %d | XP: %d/%d | [color=lime]%d Skill Points[/color]" % [level, xp, xp_needed, skill_points])
	lines.append("")

	# Show skill trees
	for tree_id in SimSkills.get_all_trees():
		var tree_name: String = SimSkills.get_tree_name(tree_id)
		lines.append("[color=cyan]== %s ==[/color]" % tree_name)

		var skills: Dictionary = SimSkills.get_tree_skills(tree_id)
		for skill_id in skills.keys():
			var skill: Dictionary = skills[skill_id]
			var name: String = str(skill.get("name", skill_id))
			var ranks: int = SimSkills.get_skill_rank(tree_id, skill_id, learned_skills)
			var max_ranks: int = int(skill.get("max_ranks", 1))
			var cost: int = int(skill.get("cost", 1))
			var effect: String = str(skill.get("effect", ""))
			var tier: int = int(skill.get("tier", 1))
			var can_learn: bool = SimSkills.can_learn_skill(tree_id, skill_id, learned_skills)
			var at_max: bool = ranks >= max_ranks

			var indent: String = "  " if tier == 1 else "    " if tier == 2 else "      " if tier == 3 else "        "

			if at_max:
				lines.append("%s[color=lime]%s[/color] [MAXED %d/%d] - %s" % [indent, name, ranks, max_ranks, effect])
			elif ranks > 0:
				lines.append("%s[color=yellow]%s[/color] [%d/%d] (%d SP) - %s" % [indent, name, ranks, max_ranks, cost, effect])
			elif can_learn:
				lines.append("%s[color=white]%s[/color] [0/%d] (%d SP) - %s" % [indent, name, max_ranks, cost, effect])
			else:
				lines.append("%s[color=gray]%s[/color] [LOCKED] - %s" % [indent, name, effect])

		lines.append("")

	lines.append("Type 'learn <tree>:<skill>' to learn (e.g., 'learn speed:swift_start')")
	_update_log(lines)

func _try_learn_skill(input: String) -> void:
	var parts: PackedStringArray = input.split(":")
	if parts.size() != 2:
		_update_objective("[color=red]Invalid format. Use 'learn tree:skill' (e.g., 'learn speed:swift_start')[/color]")
		return

	var tree_id: String = parts[0].strip_edges()
	var skill_id: String = parts[1].strip_edges()

	# Validate tree
	var tree: Dictionary = SimSkills.get_tree(tree_id)
	if tree.is_empty():
		_update_objective("[color=red]Unknown skill tree '%s'. Valid: speed, accuracy, defense[/color]" % tree_id)
		return

	# Validate skill
	var skill: Dictionary = SimSkills.get_skill(tree_id, skill_id)
	if skill.is_empty():
		_update_objective("[color=red]Unknown skill '%s' in tree '%s'[/color]" % [skill_id, tree_id])
		return

	var learned_skills: Dictionary = TypingProfile.get_learned_skills(profile)
	var skill_points: int = TypingProfile.get_skill_points(profile)
	var cost: int = SimSkills.get_skill_cost(tree_id, skill_id)
	var max_ranks: int = SimSkills.get_skill_max_ranks(tree_id, skill_id)
	var current_rank: int = SimSkills.get_skill_rank(tree_id, skill_id, learned_skills)

	# Check max rank
	if current_rank >= max_ranks:
		_update_objective("[color=yellow]%s is already at max rank![/color]" % str(skill.get("name", skill_id)))
		return

	# Check prerequisites
	if not SimSkills.can_learn_skill(tree_id, skill_id, learned_skills):
		var prereqs: Array[String] = SimSkills.get_skill_prerequisites(tree_id, skill_id)
		_update_objective("[color=red]Must learn prerequisites first: %s[/color]" % ", ".join(prereqs))
		return

	# Check skill points
	if skill_points < cost:
		_update_objective("[color=red]Not enough skill points! Need %d, have %d[/color]" % [cost, skill_points])
		return

	# Learn the skill
	learned_skills = SimSkills.learn_skill(tree_id, skill_id, learned_skills)
	TypingProfile.set_learned_skills(profile, learned_skills)
	TypingProfile.set_skill_points(profile, skill_points - cost)
	TypingProfile.save_profile(profile)

	var skill_name: String = str(skill.get("name", skill_id))
	var new_rank: int = current_rank + 1
	_update_objective("[color=lime]Learned %s (rank %d/%d)![/color]" % [skill_name, new_rank, max_ranks])

func _show_inventory() -> void:
	var inventory: Array = TypingProfile.get_inventory(profile)
	var lines: Array[String] = []
	lines.append("[color=yellow]INVENTORY[/color]")
	lines.append("")

	if inventory.is_empty():
		lines.append("[color=gray]Your inventory is empty.[/color]")
		lines.append("Defeat enemies to find loot!")
	else:
		lines.append("Items (%d):" % inventory.size())
		var item_counts: Dictionary = {}
		for item_id in inventory:
			item_counts[item_id] = int(item_counts.get(item_id, 0)) + 1

		var index: int = 1
		for item_id in item_counts.keys():
			var count: int = item_counts[item_id]
			var display: String = SimItems.format_item_display(item_id)
			var slot: String = SimItems.get_slot(item_id)
			if count > 1:
				lines.append("  %d. %s x%d (%s)" % [index, display, count, slot])
			else:
				lines.append("  %d. %s (%s)" % [index, display, slot])
			index += 1

	lines.append("")
	lines.append("Type 'equip <item_id>' to equip | 'gear' to see equipment")
	_update_log(lines)

func _show_equipment() -> void:
	var equipment: Dictionary = TypingProfile.get_equipment(profile)
	var item_stats: Dictionary = SimItems.calculate_equipment_stats(equipment)
	var lines: Array[String] = []
	lines.append("[color=yellow]EQUIPMENT[/color]")
	lines.append("")

	for slot in SimItems.EQUIPMENT_SLOTS:
		var item_id: String = str(equipment.get(slot, ""))
		var slot_name: String = slot.capitalize()
		if item_id.is_empty():
			lines.append("  [%s]: [color=gray]Empty[/color]" % slot_name)
		else:
			lines.append("  [%s]: %s" % [slot_name, SimItems.format_item_display(item_id)])

	lines.append("")
	lines.append("[color=cyan]Total Stats:[/color]")
	var stat_parts: Array[String] = []
	if int(item_stats.get("defense", 0)) > 0:
		stat_parts.append("DEF +%d" % int(item_stats.get("defense", 0)))
	if float(item_stats.get("damage_bonus", 0)) > 0:
		stat_parts.append("DMG +%.0f%%" % (float(item_stats.get("damage_bonus", 0)) * 100))
	if float(item_stats.get("gold_bonus", 0)) > 0:
		stat_parts.append("Gold +%.0f%%" % (float(item_stats.get("gold_bonus", 0)) * 100))
	if float(item_stats.get("crit_chance", 0)) > 0:
		stat_parts.append("Crit +%.0f%%" % (float(item_stats.get("crit_chance", 0)) * 100))
	if float(item_stats.get("accuracy_bonus", 0)) > 0:
		stat_parts.append("Acc +%.0f%%" % (float(item_stats.get("accuracy_bonus", 0)) * 100))
	if int(item_stats.get("wpm_bonus", 0)) > 0:
		stat_parts.append("WPM +%d" % int(item_stats.get("wpm_bonus", 0)))

	if stat_parts.is_empty():
		lines.append("  [color=gray]No stat bonuses[/color]")
	else:
		lines.append("  " + ", ".join(stat_parts))

	lines.append("")
	lines.append("Type 'unequip <slot>' to remove | 'inv' to see inventory")
	_update_log(lines)

func _try_equip_item(item_id: String) -> void:
	var inventory: Array = TypingProfile.get_inventory(profile)

	# Check if item is in inventory
	if not TypingProfile.has_item(profile, item_id):
		_update_objective("[color=red]You don't have '%s' in your inventory![/color]" % item_id)
		return

	# Check if it's equipment
	if not SimItems.is_equipment(item_id):
		_update_objective("[color=red]'%s' is not equippable![/color]" % item_id)
		return

	var slot: String = SimItems.get_slot(item_id)
	var equipment: Dictionary = TypingProfile.get_equipment(profile)
	var old_item: String = str(equipment.get(slot, ""))

	# Remove from inventory
	TypingProfile.remove_from_inventory(profile, item_id)

	# If something was equipped, add it back to inventory
	if not old_item.is_empty():
		TypingProfile.add_to_inventory(profile, old_item)

	# Equip the new item
	TypingProfile.equip_item(profile, item_id)
	TypingProfile.save_profile(profile)

	var item_display: String = SimItems.format_item_display(item_id)
	_update_objective("[color=lime]Equipped %s![/color]" % item_display)
	if not old_item.is_empty():
		var old_display: String = SimItems.format_item_display(old_item)
		_update_objective("[color=lime]Equipped %s![/color] (Unequipped %s)" % [item_display, old_display])

func _try_unequip_slot(slot: String) -> void:
	slot = slot.to_lower()
	var equipment: Dictionary = TypingProfile.get_equipment(profile)

	# Check if valid slot
	if not slot in SimItems.EQUIPMENT_SLOTS:
		_update_objective("[color=red]Invalid slot '%s'! Valid: %s[/color]" % [slot, ", ".join(SimItems.EQUIPMENT_SLOTS)])
		return

	var item_id: String = str(equipment.get(slot, ""))
	if item_id.is_empty():
		_update_objective("[color=yellow]Nothing equipped in %s slot.[/color]" % slot.capitalize())
		return

	# Unequip and add to inventory
	TypingProfile.unequip_item(profile, slot)
	TypingProfile.add_to_inventory(profile, item_id)
	TypingProfile.save_profile(profile)

	var item_display: String = SimItems.format_item_display(item_id)
	_update_objective("[color=lime]Unequipped %s from %s slot.[/color]" % [item_display, slot.capitalize()])

func _try_use_consumable(item_id: String) -> void:
	# Check if item is in inventory
	if not TypingProfile.has_item(profile, item_id):
		_update_objective("[color=red]You don't have '%s' in your inventory![/color]" % item_id)
		return

	# Check if it's a consumable
	if not SimItems.is_consumable(item_id):
		_update_objective("[color=red]'%s' cannot be used![/color]" % item_id)
		return

	var item: Dictionary = SimItems.get_item(item_id)
	var effect: Dictionary = item.get("effect", {})
	var effect_type: String = str(effect.get("type", ""))
	var effect_value: float = float(effect.get("value", 0))
	var duration: float = float(effect.get("duration", 0))
	var item_name: String = str(item.get("name", item_id))

	# Apply effect based on type
	match effect_type:
		"heal":
			var heal_amount: int = int(effect_value)
			var old_hp: int = castle_hp
			castle_hp = min(castle_hp + heal_amount, castle_max_hp)
			var healed: int = castle_hp - old_hp
			TypingProfile.remove_from_inventory(profile, item_id)
			TypingProfile.save_profile(profile)
			_update_objective("[color=lime]Used %s![/color] Restored %d HP." % [item_name, healed])

		"damage_buff":
			active_item_buffs["damage_buff"] = {"remaining": duration, "value": effect_value}
			TypingProfile.remove_from_inventory(profile, item_id)
			TypingProfile.save_profile(profile)
			_update_objective("[color=lime]Used %s![/color] +%.0f%% damage for %.0f seconds." % [item_name, effect_value * 100, duration])

		"gold_buff":
			active_item_buffs["gold_buff"] = {"remaining": duration, "value": effect_value}
			TypingProfile.remove_from_inventory(profile, item_id)
			TypingProfile.save_profile(profile)
			_update_objective("[color=lime]Used %s![/color] +%.0f%% gold for %.0f seconds." % [item_name, effect_value * 100, duration])

		"freeze_all":
			# Apply frozen status to all active enemies
			for i in range(active_enemies.size()):
				var enemy: Dictionary = active_enemies[i]
				enemy = SimEnemies.apply_status_effect(enemy, "frozen", 1, "scroll")
				active_enemies[i] = enemy
			TypingProfile.remove_from_inventory(profile, item_id)
			TypingProfile.save_profile(profile)
			_update_objective("[color=cyan]Used %s![/color] All enemies frozen!" % item_name)

		"regen":
			active_item_buffs["regen"] = {"remaining": duration, "value": effect_value}
			TypingProfile.remove_from_inventory(profile, item_id)
			TypingProfile.save_profile(profile)
			_update_objective("[color=lime]Used %s![/color] Regenerating HP over time." % item_name)

		"all_buff":
			active_item_buffs["all_buff"] = {"remaining": duration, "value": effect_value}
			TypingProfile.remove_from_inventory(profile, item_id)
			TypingProfile.save_profile(profile)
			_update_objective("[color=lime]Used %s![/color] All stats boosted for %.0f seconds." % [item_name, duration])

		_:
			_update_objective("[color=yellow]Unknown effect type '%s'.[/color]" % effect_type)

func _tick_item_buffs(delta: float) -> void:
	var expired: Array[String] = []
	for buff_type in active_item_buffs.keys():
		active_item_buffs[buff_type]["remaining"] = float(active_item_buffs[buff_type].get("remaining", 0)) - delta
		if float(active_item_buffs[buff_type].get("remaining", 0)) <= 0:
			expired.append(buff_type)

	for buff_type in expired:
		active_item_buffs.erase(buff_type)
		_update_objective("[color=gray]%s buff expired.[/color]" % buff_type.replace("_", " ").capitalize())

func _process_auto_towers(delta: float) -> void:
	if active_enemies.is_empty():
		return

	var auto_towers: Array[Dictionary] = SimBuildings.get_all_auto_towers(state)
	if auto_towers.is_empty():
		return

	# Update cooldowns
	for tower_index in auto_tower_cooldowns.keys():
		auto_tower_cooldowns[tower_index] = max(0.0, float(auto_tower_cooldowns[tower_index]) - delta)

	# Process each auto-tower
	for tower in auto_towers:
		var tower_idx: int = int(tower.get("index", 0))
		var cooldown_remaining: float = float(auto_tower_cooldowns.get(tower_idx, 0))

		if cooldown_remaining > 0:
			continue

		var tower_pos: Vector2i = tower.get("pos", Vector2i.ZERO)
		var attack_range: int = int(tower.get("range", 2))
		var damage: int = int(tower.get("damage", 1))
		var targeting: String = str(tower.get("targeting", "nearest"))
		var aoe_radius: int = int(tower.get("aoe_radius", 0))
		var apply_burn: bool = bool(tower.get("burn", false))
		# Apply speed buff to cooldown (lower cooldown = faster attacks)
		var cooldown: float = float(tower.get("cooldown", 1.0)) / auto_tower_speed_buff

		# Find targets based on targeting type
		if targeting == "aoe":
			# Damage all enemies in range
			var hit_count: int = 0
			for i in range(active_enemies.size() - 1, -1, -1):
				var enemy: Dictionary = active_enemies[i]
				var enemy_pos: Vector2i = enemy.get("pos", Vector2i.ZERO)
				var dist: int = abs(tower_pos.x - enemy_pos.x) + abs(tower_pos.y - enemy_pos.y)

				if dist <= attack_range:
					enemy["hp"] = int(enemy.get("hp", 1)) - damage
					hit_count += 1

					# Apply burn if applicable
					if apply_burn:
						enemy = SimEnemies.apply_status_effect(enemy, "burning", 1, "auto_tower")
						active_enemies[i] = enemy

					# Check for kill
					if int(enemy.get("hp", 0)) <= 0:
						_auto_tower_kill(i, tower.get("type", "sentry"))
					else:
						active_enemies[i] = enemy

			if hit_count > 0:
				auto_tower_cooldowns[tower_idx] = cooldown
				_spawn_auto_tower_effect(tower_pos, "aoe", hit_count)

		else:
			# Nearest targeting - find closest enemy in range
			var best_target: int = -1
			var best_dist: int = 999

			for i in range(active_enemies.size()):
				var enemy: Dictionary = active_enemies[i]
				var enemy_pos: Vector2i = enemy.get("pos", Vector2i.ZERO)
				var dist: int = abs(tower_pos.x - enemy_pos.x) + abs(tower_pos.y - enemy_pos.y)

				if dist <= attack_range and dist < best_dist:
					best_dist = dist
					best_target = i

			if best_target >= 0:
				var enemy: Dictionary = active_enemies[best_target]
				enemy["hp"] = int(enemy.get("hp", 1)) - damage

				# Apply burn if applicable
				if apply_burn:
					enemy = SimEnemies.apply_status_effect(enemy, "burning", 1, "auto_tower")

				# Set cooldown
				auto_tower_cooldowns[tower_idx] = cooldown

				# Spawn effect
				var enemy_pos: Vector2i = enemy.get("pos", Vector2i.ZERO)
				_spawn_auto_tower_effect(tower_pos, "projectile", 1, enemy_pos)

				# Check for kill
				if int(enemy.get("hp", 0)) <= 0:
					_auto_tower_kill(best_target, tower.get("type", "sentry"))
				else:
					active_enemies[best_target] = enemy

func _auto_tower_kill(enemy_index: int, tower_type: String) -> void:
	var enemy: Dictionary = active_enemies[enemy_index]
	var is_boss: bool = bool(enemy.get("is_boss", false))
	var enemy_kind: String = str(enemy.get("kind", "unknown"))

	# Award gold (reduced compared to typing kills)
	var gold_reward: int = 2 if not is_boss else 10
	gold += gold_reward

	# Remove enemy
	active_enemies.remove_at(enemy_index)

	# Update targeting if needed
	if target_enemy_id == int(enemy.get("id", -1)):
		_target_closest_enemy()

	# Visual feedback
	var pos: Vector2i = enemy.get("pos", Vector2i.ZERO)
	if grid_renderer and grid_renderer.has_method("spawn_hit_particles"):
		grid_renderer.spawn_hit_particles(pos, 8, Color(0.5, 0.5, 1.0))

func _spawn_auto_tower_effect(tower_pos: Vector2i, effect_type: String, count: int, target_pos: Vector2i = Vector2i.ZERO) -> void:
	if not grid_renderer:
		return

	if effect_type == "aoe" and grid_renderer.has_method("spawn_hit_particles"):
		grid_renderer.spawn_hit_particles(tower_pos, count * 5, Color(1.0, 1.0, 0.0))
	elif effect_type == "projectile" and grid_renderer.has_method("spawn_projectile"):
		grid_renderer.spawn_projectile(tower_pos, target_pos, Color(0.5, 0.8, 1.0))

func _get_item_buff_value(buff_type: String) -> float:
	if active_item_buffs.has(buff_type):
		return float(active_item_buffs[buff_type].get("value", 0))
	return 0.0

func _show_shop() -> void:
	var lines: Array[String] = []
	lines.append("[color=yellow]SHOP[/color]")
	lines.append("Your Gold: [color=gold]%d[/color]" % gold)
	lines.append("")
	lines.append("Available Items:")

	for item_id in SimItems.CONSUMABLES.keys():
		var item: Dictionary = SimItems.CONSUMABLES[item_id]
		var name: String = str(item.get("name", item_id))
		var price: int = int(item.get("price", 0))
		var desc: String = str(item.get("description", ""))
		var rarity: String = str(item.get("rarity", "common"))
		var color: String = SimItems.RARITY_COLORS.get(rarity, "#FFFFFF")

		var afford_color: String = "lime" if gold >= price else "red"
		lines.append("  [color=%s]%s[/color] - [color=%s]%d gold[/color]" % [color, name, afford_color, price])
		lines.append("    %s" % desc)
		lines.append("    ID: [color=cyan]%s[/color]" % item_id)

	lines.append("")
	lines.append("Type 'buy <item_id>' to purchase")
	_update_log(lines)

func _try_buy_item(item_id: String) -> void:
	# Check if item exists
	if not SimItems.is_consumable(item_id):
		_update_objective("[color=red]'%s' is not available in the shop![/color]" % item_id)
		return

	var item: Dictionary = SimItems.get_item(item_id)
	var price: int = int(item.get("price", 0))
	var item_name: String = str(item.get("name", item_id))

	# Check if player can afford
	if gold < price:
		_update_objective("[color=red]Not enough gold! Need %d, have %d.[/color]" % [price, gold])
		return

	# Purchase the item
	gold -= price
	state.gold = gold
	TypingProfile.add_to_inventory(profile, item_id)
	TypingProfile.save_profile(profile)

	_update_objective("[color=lime]Purchased %s for %d gold![/color]" % [item_name, price])

func _show_auto_towers() -> void:
	var lines: Array[String] = []
	lines.append("[color=yellow]AUTO-DEFENSE TOWERS[/color]")
	lines.append("")

	var auto_towers: Array[Dictionary] = SimBuildings.get_all_auto_towers(state)
	if auto_towers.is_empty():
		lines.append("[color=gray]No auto-towers built.[/color]")
		lines.append("")
		lines.append("Available auto-towers to build:")
		lines.append("  [color=cyan]sentry[/color] - Single target, 3 DMG, 1.5s cooldown (30g)")
		lines.append("  [color=cyan]spark[/color] - AoE damage, 2 DMG to all nearby (50g)")
		lines.append("  [color=cyan]flame[/color] - Rapid fire + burn, 4 DMG (60g)")
	else:
		lines.append("Your Towers (%d):" % auto_towers.size())
		for tower in auto_towers:
			var tower_type: String = str(tower.get("type", "unknown"))
			var pos: Vector2i = tower.get("pos", Vector2i.ZERO)
			var damage: int = int(tower.get("damage", 1))
			var attack_range: int = int(tower.get("range", 2))
			var cooldown: float = float(tower.get("cooldown", 1.0))
			var targeting: String = str(tower.get("targeting", "nearest"))

			var type_color: String = "white"
			match tower_type:
				"sentry": type_color = "cyan"
				"spark": type_color = "yellow"
				"flame": type_color = "orange"

			lines.append("  [color=%s]%s[/color] at (%d,%d)" % [type_color, tower_type.capitalize(), pos.x, pos.y])
			lines.append("    DMG: %d | Range: %d | Cooldown: %.1fs | Mode: %s" % [damage, attack_range, cooldown, targeting])

	lines.append("")
	lines.append("Auto-towers attack automatically during waves!")
	_update_log(lines)

func _show_help() -> void:
	var lines: Array[String] = []
	lines.append("[color=yellow]KEYBOARD DEFENSE - COMMANDS[/color]")
	lines.append("")
	lines.append("[color=cyan]BUILDING[/color]")
	lines.append("  build <type> - Build structure (tower, wall, farm, etc.)")
	lines.append("  sentry/spark/flame - Build auto-defense tower")
	lines.append("  upgrade - Upgrade structure at cursor")
	lines.append("")
	lines.append("[color=cyan]INFORMATION[/color]")
	lines.append("  help - Show this help")
	lines.append("  skills - View skill trees and learned skills")
	lines.append("  effects - View status effects info")
	lines.append("  auto - View auto-defense towers")
	lines.append("  spells - View special typing commands")
	lines.append("  wave - View current wave theme/modifiers")
	lines.append("")
	lines.append("[color=cyan]ITEMS & EQUIPMENT[/color]")
	lines.append("  inv/items - View inventory")
	lines.append("  gear - View equipped items")
	lines.append("  equip <id> - Equip an item")
	lines.append("  unequip <slot> - Unequip from slot")
	lines.append("  use <id> - Use a consumable")
	lines.append("")
	lines.append("[color=cyan]ECONOMY[/color]")
	lines.append("  shop - View consumable shop")
	lines.append("  buy <id> - Purchase item")
	lines.append("")
	lines.append("[color=cyan]CHARACTER[/color]")
	lines.append("  learn <tree:skill> - Learn a skill")
	lines.append("")
	lines.append("[color=cyan]QUESTS[/color]")
	lines.append("  quests/q - View active quests")
	lines.append("  claim <id> - Claim completed quest reward")
	lines.append("")
	lines.append("[color=cyan]GAME MODES[/color]")
	lines.append("  endless - View endless mode status/scores")
	lines.append("  startendless - Start an endless mode run")
	lines.append("")
	lines.append("[color=gray]During waves: Type words OR spell commands![/color]")
	_update_log(lines)

func _show_wave_info() -> void:
	var lines: Array[String] = []
	lines.append("[color=yellow]WAVE INFORMATION[/color]")
	lines.append("Day %d, Wave %d/%d" % [day, wave, waves_per_day])
	lines.append("")

	if current_wave_composition.is_empty():
		lines.append("[color=gray]No wave composition data available.[/color]")
	else:
		var theme_name: String = str(current_wave_composition.get("theme_name", "Standard"))
		var description: String = str(current_wave_composition.get("description", ""))
		lines.append("[color=cyan]Theme:[/color] %s" % theme_name)
		lines.append("  %s" % description)
		lines.append("")

		# Show modifiers
		var modifiers: Array = current_wave_composition.get("modifier_names", [])
		if not modifiers.is_empty():
			lines.append("[color=orange]Modifiers:[/color] %s" % ", ".join(modifiers))

		# Show stat changes
		var stats: Array[String] = []
		var hp_mult: float = float(current_wave_composition.get("hp_mult", 1.0))
		var speed_mult: float = float(current_wave_composition.get("speed_mult", 1.0))
		var gold_mult: float = float(current_wave_composition.get("gold_mult", 1.0))

		if hp_mult != 1.0:
			stats.append("HP: x%.1f" % hp_mult)
		if speed_mult != 1.0:
			stats.append("Speed: x%.1f" % speed_mult)
		if gold_mult != 1.0:
			stats.append("Gold: x%.1f" % gold_mult)

		if not stats.is_empty():
			lines.append("[color=gray]Stats: %s[/color]" % ", ".join(stats))

		# Show enemy count
		lines.append("")
		lines.append("Enemies: %d" % int(current_wave_composition.get("enemy_count", 0)))

	_update_log(lines)

func _show_endless_mode() -> void:
	var lines: Array[String] = []

	if is_endless_mode:
		# Show current run status
		lines.append(SimEndlessMode.format_run_status(day, wave, max_combo, endless_run_kills))
	else:
		# Show general endless mode status
		lines.append(SimEndlessMode.format_status(profile))

		if SimEndlessMode.is_unlocked(profile):
			lines.append("")
			lines.append("[color=cyan]Type 'startendless' to begin an endless run![/color]")

	_update_log(lines)

func _start_endless_mode() -> void:
	if not SimEndlessMode.is_unlocked(profile):
		var max_day_reached: int = int(TypingProfile.get_profile_value(profile, "max_day_reached", 0))
		_update_objective("[color=red]Endless mode locked![/color] Reach Day %d to unlock (currently: %d)" % [SimEndlessMode.UNLOCK_DAY, max_day_reached])
		return

	# Reset game state for endless mode
	is_endless_mode = true
	endless_run_kills = 0
	endless_day_start_time = Time.get_unix_time_from_system()

	# Reset to day 1
	day = 1
	wave = 1
	state.day = day
	castle_hp = castle_max_hp
	gold = 50  # Starting gold for endless
	combo = 0
	max_combo = 0

	# Start the run counter
	SimEndlessMode.start_run(profile)
	TypingProfile.save_profile(profile)

	_update_objective("[color=yellow]ENDLESS MODE STARTED![/color]")
	_update_hint("Survive as long as you can! Difficulty scales infinitely.")

	# Start first wave
	_start_planning_phase()

func _end_endless_run() -> void:
	if not is_endless_mode:
		return

	# Calculate day time
	var day_time: float = Time.get_unix_time_from_system() - endless_day_start_time

	# Update high scores
	var result: Dictionary = SimEndlessMode.update_high_scores(profile, day, wave + (day - 1) * waves_per_day, max_combo, endless_run_kills, day_time)
	TypingProfile.save_profile(profile)

	# Show results
	var lines: Array[String] = []
	lines.append("[color=yellow]ENDLESS RUN COMPLETE![/color]")
	lines.append("")
	lines.append("Final Day: %d, Wave: %d" % [day, wave])
	lines.append("Total Kills: %d" % endless_run_kills)
	lines.append("Max Combo: %d" % max_combo)

	# Show new records
	var new_records: Array = result.get("new_records", [])
	if not new_records.is_empty():
		lines.append("")
		lines.append("[color=lime]NEW RECORDS![/color]")
		for record in new_records:
			lines.append("  • %s" % str(record))

	# Show milestones reached
	var milestones: Array = result.get("milestones_reached", [])
	for milestone_day in milestones:
		var reward: Dictionary = SimEndlessMode.get_milestone_reward(milestone_day)
		if not reward.is_empty():
			lines.append("")
			lines.append("[color=orange]MILESTONE: %s (Day %d)[/color]" % [str(reward.get("name", "")), milestone_day])
			var gold_reward: int = int(reward.get("gold", 0))
			var xp_reward: int = int(reward.get("xp", 0))
			gold += gold_reward
			TypingProfile.add_xp(profile, xp_reward)
			lines.append("  +%d gold, +%d XP" % [gold_reward, xp_reward])

	_update_log(lines)
	is_endless_mode = false

func _show_daily_challenge() -> void:
	var challenge: Dictionary = SimDailyChallenges.get_daily_challenge(profile)
	var lines: Array[String] = []

	lines.append("[color=yellow]DAILY CHALLENGE[/color]")
	lines.append("")

	if is_challenge_mode:
		# Show current run progress
		var goal: Dictionary = challenge_state.get("challenge", {}).get("goal", {})
		var target: int = int(goal.get("target", 0))
		var progress: int = int(challenge_state.get("progress", 0))
		lines.append("[color=cyan]IN PROGRESS[/color]")
		lines.append("Progress: %d / %d" % [progress, target])
		lines.append("")

	lines.append(SimDailyChallenges.format_challenge(challenge))

	var streak: int = SimDailyChallenges.get_streak(profile)
	if streak > 0:
		lines.append("")
		lines.append("[color=orange]Current Streak: %d days[/color]" % streak)

	if not bool(challenge.get("completed_today", false)) and not is_challenge_mode:
		lines.append("")
		lines.append("[color=cyan]Type 'startdaily' to begin![/color]")

	_update_log(lines)

func _start_daily_challenge() -> void:
	var challenge: Dictionary = SimDailyChallenges.get_daily_challenge(profile)

	if bool(challenge.get("completed_today", false)):
		_update_objective("[color=yellow]Already completed today's challenge![/color] Come back tomorrow.")
		return

	if is_challenge_mode:
		_update_objective("[color=yellow]Challenge already in progress![/color]")
		return

	if is_endless_mode:
		_update_objective("[color=red]Cannot start challenge while in endless mode![/color]")
		return

	# Start the challenge
	is_challenge_mode = true
	challenge_state = SimDailyChallenges.start_challenge(profile)
	challenge_kills = 0
	challenge_words = 0
	challenge_gold_earned = 0
	challenge_boss_kills = 0

	# Reset game state for challenge
	day = 1
	wave = 1
	state.day = day
	combo = 0
	max_combo = 0

	# Apply challenge modifiers
	var modifiers: Dictionary = challenge_state.get("challenge", {}).get("modifiers", {})
	if modifiers.has("max_hp"):
		castle_max_hp = int(modifiers.get("max_hp", 10))
	else:
		castle_max_hp = 10
	castle_hp = castle_max_hp
	gold = 50

	var challenge_name: String = str(challenge_state.get("challenge", {}).get("name", "Daily Challenge"))
	_update_objective("[color=yellow]%s STARTED![/color]" % challenge_name)
	_update_hint("Complete the goal to earn tokens!")

	_start_planning_phase()

func _update_challenge_progress(stat_type: String, value: int) -> void:
	if not is_challenge_mode:
		return

	challenge_state = SimDailyChallenges.update_progress(challenge_state, stat_type, value)

	# Check for completion
	if SimDailyChallenges.is_complete(challenge_state):
		_complete_daily_challenge()

func _complete_daily_challenge() -> void:
	if not is_challenge_mode:
		return

	var result: Dictionary = SimDailyChallenges.complete_challenge(profile, challenge_state)
	TypingProfile.save_profile(profile)

	# Grant rewards
	gold += int(result.get("gold", 0))
	TypingProfile.add_xp(profile, int(result.get("xp", 0)))

	var lines: Array[String] = []
	lines.append("[color=lime]DAILY CHALLENGE COMPLETE![/color]")
	lines.append("")
	lines.append("Rewards:")
	lines.append("  +%d gold" % int(result.get("gold", 0)))
	lines.append("  +%d XP" % int(result.get("xp", 0)))
	lines.append("  +%d tokens" % int(result.get("tokens", 0)))

	if not str(result.get("streak_milestone", "")).is_empty():
		lines.append("")
		lines.append("[color=orange]STREAK BONUS: %s![/color]" % str(result.get("streak_milestone", "")))
		lines.append("  +%d bonus tokens" % int(result.get("streak_bonus", 0)))

	lines.append("")
	lines.append("Total Tokens: %d" % SimDailyChallenges.get_token_balance(profile))

	_update_log(lines)
	is_challenge_mode = false

func _fail_daily_challenge(reason: String) -> void:
	if not is_challenge_mode:
		return

	var lines: Array[String] = []
	lines.append("[color=red]DAILY CHALLENGE FAILED![/color]")
	lines.append(reason)
	lines.append("")

	var goal: Dictionary = challenge_state.get("challenge", {}).get("goal", {})
	var target: int = int(goal.get("target", 0))
	var progress: int = int(challenge_state.get("progress", 0))
	lines.append("Progress: %d / %d" % [progress, target])
	lines.append("")
	lines.append("[color=gray]Try again tomorrow or restart now![/color]")

	_update_log(lines)
	is_challenge_mode = false

func _show_token_shop() -> void:
	_update_log([SimDailyChallenges.format_shop(profile)])

func _try_buy_token_item(item_id: String) -> void:
	var result: Dictionary = SimDailyChallenges.purchase_token_item(profile, item_id)

	if bool(result.get("success", false)):
		var item: Dictionary = result.get("item", {})
		var name: String = str(item.get("name", item_id))
		TypingProfile.save_profile(profile)
		_update_objective("[color=lime]Purchased %s![/color]" % name)
	else:
		_update_objective("[color=red]%s[/color]" % str(result.get("error", "Purchase failed")))

func _show_special_commands() -> void:
	var player_level: int = int(TypingProfile.get_profile_value(profile, "player_level", 1))
	var unlocked: Array[String] = SimSpecialCommands.get_unlocked_commands(player_level)
	var all_commands: Array[String] = SimSpecialCommands.get_all_command_ids()

	var lines: Array[String] = []
	lines.append("[color=yellow]SPECIAL COMMANDS[/color]")
	lines.append("Type these words during combat to trigger effects!")
	lines.append("Player Level: %d" % player_level)
	lines.append("")

	lines.append("[color=cyan]UNLOCKED:[/color]")
	if unlocked.is_empty():
		lines.append("  [color=gray]None yet - level up![/color]")
	else:
		for cmd_id in unlocked:
			var cooldown_remaining: float = float(command_cooldowns.get(cmd_id, 0))
			lines.append("  " + SimSpecialCommands.format_command(cmd_id, cooldown_remaining))

	# Show locked commands
	var locked: Array[String] = []
	for cmd_id in all_commands:
		if not cmd_id in unlocked:
			locked.append(cmd_id)

	if not locked.is_empty():
		lines.append("")
		lines.append("[color=gray]LOCKED:[/color]")
		for cmd_id in locked:
			var unlock_level: int = SimSpecialCommands.get_unlock_level(cmd_id)
			var cmd: Dictionary = SimSpecialCommands.get_command(cmd_id)
			var word: String = str(cmd.get("word", ""))
			lines.append("  [color=gray]%s - Unlocks at level %d[/color]" % [word, unlock_level])

	_update_log(lines)

func _tick_command_cooldowns(delta: float) -> void:
	# Tick cooldowns
	var expired: Array[String] = []
	for cmd_id in command_cooldowns.keys():
		command_cooldowns[cmd_id] = max(0.0, float(command_cooldowns[cmd_id]) - delta)
		if float(command_cooldowns[cmd_id]) <= 0:
			expired.append(cmd_id)

	for cmd_id in expired:
		command_cooldowns.erase(cmd_id)

	# Tick duration-based effects
	if command_effects.has("damage_buff_duration"):
		command_effects["damage_buff_duration"] = float(command_effects["damage_buff_duration"]) - delta
		if float(command_effects["damage_buff_duration"]) <= 0:
			command_effects.erase("damage_buff")
			command_effects.erase("damage_buff_duration")
			_update_objective("[color=gray]Damage buff expired.[/color]")

	if command_effects.has("gold_buff_duration"):
		command_effects["gold_buff_duration"] = float(command_effects["gold_buff_duration"]) - delta
		if float(command_effects["gold_buff_duration"]) <= 0:
			command_effects.erase("gold_buff")
			command_effects.erase("gold_buff_duration")
			_update_objective("[color=gray]Gold buff expired.[/color]")

	if command_effects.has("fortify_duration"):
		command_effects["fortify_duration"] = float(command_effects["fortify_duration"]) - delta
		if float(command_effects["fortify_duration"]) <= 0:
			command_effects.erase("fortify")
			command_effects.erase("fortify_duration")
			_update_objective("[color=gray]Fortify expired.[/color]")

	if command_effects.has("auto_speed_duration"):
		command_effects["auto_speed_duration"] = float(command_effects["auto_speed_duration"]) - delta
		if float(command_effects["auto_speed_duration"]) <= 0:
			auto_tower_speed_buff = 1.0
			command_effects.erase("auto_speed_duration")
			_update_objective("[color=gray]Overcharge expired.[/color]")

func _try_execute_command(command_id: String) -> void:
	var player_level: int = int(TypingProfile.get_profile_value(profile, "player_level", 1))

	# Check if unlocked
	if not SimSpecialCommands.is_unlocked(command_id, player_level):
		var unlock_level: int = SimSpecialCommands.get_unlock_level(command_id)
		_update_objective("[color=red]Command locked! Requires level %d.[/color]" % unlock_level)
		return

	# Check cooldown
	var cooldown_remaining: float = float(command_cooldowns.get(command_id, 0))
	if cooldown_remaining > 0:
		_update_objective("[color=red]Command on cooldown! %.0f seconds remaining.[/color]" % cooldown_remaining)
		return

	# Execute the command
	var cmd: Dictionary = SimSpecialCommands.get_command(command_id)
	var effect: Dictionary = cmd.get("effect", {})
	var effect_type: String = str(effect.get("type", ""))
	var cooldown: float = SimSpecialCommands.get_cooldown(command_id)
	var cmd_name: String = str(cmd.get("name", command_id))

	match effect_type:
		"heal":
			var heal_amount: int = int(effect.get("value", 3))
			var old_hp: int = castle_hp
			castle_hp = min(castle_hp + heal_amount, castle_max_hp)
			var healed: int = castle_hp - old_hp
			_update_objective("[color=lime]%s![/color] Restored %d HP." % [cmd_name, healed])

		"damage_buff":
			var value: float = float(effect.get("value", 0.5))
			var duration: float = float(effect.get("duration", 10.0))
			command_effects["damage_buff"] = value
			command_effects["damage_buff_duration"] = duration
			_update_objective("[color=lime]%s![/color] +%.0f%% damage for %.0fs!" % [cmd_name, value * 100, duration])

		"gold_buff":
			var value: float = float(effect.get("value", 1.0))
			var duration: float = float(effect.get("duration", 20.0))
			command_effects["gold_buff"] = value
			command_effects["gold_buff_duration"] = duration
			_update_objective("[color=gold]%s![/color] +%.0f%% gold for %.0fs!" % [cmd_name, value * 100, duration])

		"damage_charges":
			var value: float = float(effect.get("value", 2.0))
			var charges: int = int(effect.get("charges", 5))
			command_effects["damage_charges"] = charges
			command_effects["damage_charge_mult"] = value
			_update_objective("[color=lime]%s![/color] Next %d attacks deal %.0fx damage!" % [cmd_name, charges, value])

		"crit_charges":
			var charges: int = int(effect.get("charges", 3))
			command_effects["crit_charges"] = charges
			_update_objective("[color=orange]%s![/color] Next %d attacks are guaranteed crits!" % [cmd_name, charges])

		"freeze_all":
			var duration: float = float(effect.get("duration", 3.0))
			for i in range(active_enemies.size()):
				var enemy: Dictionary = active_enemies[i]
				enemy = SimEnemies.apply_status_effect(enemy, "frozen", 1, "spell")
				active_enemies[i] = enemy
			_update_objective("[color=cyan]%s![/color] All enemies frozen!" % cmd_name)

		"damage_reduction":
			var value: float = float(effect.get("value", 0.5))
			var duration: float = float(effect.get("duration", 15.0))
			command_effects["fortify"] = value
			command_effects["fortify_duration"] = duration
			_update_objective("[color=cyan]%s![/color] Castle takes %.0f%% less damage for %.0fs!" % [cmd_name, value * 100, duration])

		"auto_tower_speed":
			var value: float = float(effect.get("value", 2.0))
			var duration: float = float(effect.get("duration", 5.0))
			auto_tower_speed_buff = value
			command_effects["auto_speed_duration"] = duration
			_update_objective("[color=yellow]%s![/color] Auto-towers firing at %.0f%% speed!" % [cmd_name, value * 100])

		"combo_boost":
			var value: int = int(effect.get("value", 10))
			combo += value
			_update_objective("[color=purple]%s![/color] +%d combo!" % [cmd_name, value])

		"cleave_next":
			var value: float = float(effect.get("value", 0.5))
			command_effects["cleave_next"] = value
			_update_objective("[color=red]%s![/color] Next attack hits ALL enemies!" % cmd_name)

		"execute":
			var threshold: float = float(effect.get("threshold", 0.3))
			if target_enemy_id >= 0:
				for i in range(active_enemies.size()):
					var enemy: Dictionary = active_enemies[i]
					if int(enemy.get("id", -1)) == target_enemy_id:
						var current_hp: int = int(enemy.get("hp", 0))
						var max_hp: int = int(enemy.get("max_hp", current_hp))
						if float(current_hp) / float(max_hp) <= threshold:
							enemy["hp"] = 0
							_update_objective("[color=red]%s![/color] Target executed!" % cmd_name)
							# Kill will be processed in next tick
						else:
							_update_objective("[color=yellow]%s![/color] Target HP too high (need below %.0f%%)." % [cmd_name, threshold * 100])
						break
			else:
				_update_objective("[color=yellow]No target for Execute.[/color]")

		"block_charges":
			var charges: int = int(effect.get("charges", 2))
			command_effects["block_charges"] = charges
			_update_objective("[color=cyan]%s![/color] Next %d enemies blocked!" % [cmd_name, charges])

		_:
			_update_objective("[color=yellow]Unknown command effect.[/color]")
			return

	# Set cooldown
	command_cooldowns[command_id] = cooldown

	# Track for quest progress
	_update_quest_progress("spells_used", 1)

func _init_quest_system() -> void:
	# Load quest state from profile or create new
	var saved_quests: Dictionary = TypingProfile.get_profile_value(profile, "quest_state", {})
	if saved_quests.is_empty():
		quest_state = SimQuests.create_quest_state()
	else:
		quest_state = SimQuests.deserialize(saved_quests)

	# Initialize session stats
	session_stats = {
		"kills": 0,
		"boss_kills": 0,
		"max_combo": 0,
		"waves": 0,
		"gold_earned": 0,
		"words_typed": 0,
		"perfect_waves": 0,
		"no_damage_wave": 0,
		"no_damage_day": 0,
		"fast_wave": 999,
		"spells_used": 0,
		"accuracy": 0,
		"days_survived": day,
		"total_kills": int(TypingProfile.get_profile_value(profile, "total_kills", 0))
	}

	# Check if daily quests need refresh (new day)
	var current_day: int = int(Time.get_unix_time_from_system() / 86400)
	if int(quest_state.get("last_daily_refresh", 0)) != current_day:
		quest_state["daily_quests"] = SimQuests.generate_daily_quests(current_day)
		quest_state["daily_progress"] = {}
		quest_state["last_daily_refresh"] = current_day
		_save_quest_state()

	# Check if weekly quests need refresh (new week)
	var current_week: int = int(Time.get_unix_time_from_system() / 604800)
	if int(quest_state.get("last_weekly_refresh", 0)) != current_week:
		quest_state["weekly_quests"] = SimQuests.generate_weekly_quests(current_week)
		quest_state["weekly_progress"] = {}
		quest_state["last_weekly_refresh"] = current_week
		_save_quest_state()

func _save_quest_state() -> void:
	TypingProfile.set_profile_value(profile, "quest_state", SimQuests.serialize(quest_state))
	TypingProfile.save_profile(profile)

func _update_quest_progress(stat_type: String, amount: int) -> void:
	# Update session stats
	if stat_type == "max_combo":
		session_stats["max_combo"] = max(int(session_stats.get("max_combo", 0)), amount)
	elif stat_type == "fast_wave":
		session_stats["fast_wave"] = min(int(session_stats.get("fast_wave", 999)), amount)
	elif stat_type == "accuracy":
		session_stats["accuracy"] = amount
	else:
		session_stats[stat_type] = int(session_stats.get(stat_type, 0)) + amount

	# Update daily quest progress
	var daily_progress: Dictionary = quest_state.get("daily_progress", {})
	if stat_type == "max_combo":
		daily_progress["max_combo"] = max(int(daily_progress.get("max_combo", 0)), amount)
	elif stat_type == "accuracy":
		daily_progress["accuracy"] = max(int(daily_progress.get("accuracy", 0)), amount)
	else:
		daily_progress[stat_type] = int(daily_progress.get(stat_type, 0)) + amount
	quest_state["daily_progress"] = daily_progress

	# Update weekly quest progress
	var weekly_progress: Dictionary = quest_state.get("weekly_progress", {})
	if stat_type == "max_combo":
		weekly_progress["max_combo"] = max(int(weekly_progress.get("max_combo", 0)), amount)
	else:
		weekly_progress[stat_type] = int(weekly_progress.get(stat_type, 0)) + amount
	quest_state["weekly_progress"] = weekly_progress

	# Update challenge progress
	var challenge_progress: Dictionary = quest_state.get("challenge_progress", {})
	if stat_type == "max_combo":
		challenge_progress["max_combo"] = max(int(challenge_progress.get("max_combo", 0)), amount)
	elif stat_type == "total_kills":
		challenge_progress["total_kills"] = int(challenge_progress.get("total_kills", 0)) + amount
	elif stat_type == "days_survived":
		challenge_progress["days_survived"] = max(int(challenge_progress.get("days_survived", 0)), amount)
	elif stat_type == "no_damage_day":
		challenge_progress["no_damage_day"] = int(challenge_progress.get("no_damage_day", 0)) + amount
	elif stat_type == "fast_wave":
		challenge_progress["fast_wave"] = min(int(challenge_progress.get("fast_wave", 999)), amount)
	quest_state["challenge_progress"] = challenge_progress

	_save_quest_state()

	# Check for newly completed quests
	_check_quest_completions()

func _check_quest_completions() -> void:
	# Check daily quests
	var daily_quests: Array = quest_state.get("daily_quests", [])
	var daily_progress: Dictionary = quest_state.get("daily_progress", {})
	for quest_id in daily_quests:
		if SimQuests.check_objective(quest_id, daily_progress):
			var quest: Dictionary = SimQuests.get_quest(quest_id)
			if not quest.is_empty():
				# Only notify once per quest
				var claimed: Array = quest_state.get("daily_claimed", [])
				if not quest_id in claimed:
					var notified: Array = quest_state.get("daily_notified", [])
					if not quest_id in notified:
						notified.append(quest_id)
						quest_state["daily_notified"] = notified
						_update_objective("[color=lime]Quest Complete![/color] %s - Type 'claim %s'" % [str(quest.get("name", "")), quest_id])

	# Check weekly quests
	var weekly_quests: Array = quest_state.get("weekly_quests", [])
	var weekly_progress: Dictionary = quest_state.get("weekly_progress", {})
	for quest_id in weekly_quests:
		if SimQuests.check_objective(quest_id, weekly_progress):
			var quest: Dictionary = SimQuests.get_quest(quest_id)
			if not quest.is_empty():
				var claimed: Array = quest_state.get("weekly_claimed", [])
				if not quest_id in claimed:
					var notified: Array = quest_state.get("weekly_notified", [])
					if not quest_id in notified:
						notified.append(quest_id)
						quest_state["weekly_notified"] = notified
						_update_objective("[color=lime]Weekly Quest Complete![/color] %s" % str(quest.get("name", "")))

func _show_quests() -> void:
	var lines: Array[String] = []
	lines.append("[color=yellow]QUESTS[/color]")
	lines.append("")

	# Daily quests
	lines.append("[color=cyan]DAILY QUESTS:[/color]")
	var daily_quests: Array = quest_state.get("daily_quests", [])
	var daily_progress: Dictionary = quest_state.get("daily_progress", {})
	var daily_claimed: Array = quest_state.get("daily_claimed", [])

	if daily_quests.is_empty():
		lines.append("  [color=gray]No daily quests available[/color]")
	else:
		for quest_id in daily_quests:
			var status: String = SimQuests.STATUS_ACTIVE
			if quest_id in daily_claimed:
				status = SimQuests.STATUS_CLAIMED
			elif SimQuests.check_objective(quest_id, daily_progress):
				status = SimQuests.STATUS_COMPLETED
			lines.append("  " + SimQuests.format_quest(quest_id, daily_progress, status))

	lines.append("")

	# Weekly quests
	lines.append("[color=purple]WEEKLY QUESTS:[/color]")
	var weekly_quests: Array = quest_state.get("weekly_quests", [])
	var weekly_progress: Dictionary = quest_state.get("weekly_progress", {})
	var weekly_claimed: Array = quest_state.get("weekly_claimed", [])

	if weekly_quests.is_empty():
		lines.append("  [color=gray]No weekly quests available[/color]")
	else:
		for quest_id in weekly_quests:
			var status: String = SimQuests.STATUS_ACTIVE
			if quest_id in weekly_claimed:
				status = SimQuests.STATUS_CLAIMED
			elif SimQuests.check_objective(quest_id, weekly_progress):
				status = SimQuests.STATUS_COMPLETED
			lines.append("  " + SimQuests.format_quest(quest_id, weekly_progress, status))

	lines.append("")
	lines.append("Type 'claim <quest_id>' to claim completed quest rewards")
	_update_log(lines)

func _try_claim_quest(quest_id: String) -> void:
	var quest: Dictionary = SimQuests.get_quest(quest_id)
	if quest.is_empty():
		_update_objective("[color=red]Unknown quest '%s'[/color]" % quest_id)
		return

	var quest_type: String = str(quest.get("type", ""))
	var progress: Dictionary = {}
	var claimed_list: Array = []

	# Determine which progress/claimed list to use
	if quest_type == "daily":
		progress = quest_state.get("daily_progress", {})
		claimed_list = quest_state.get("daily_claimed", [])
		if not quest_id in quest_state.get("daily_quests", []):
			_update_objective("[color=red]Quest '%s' is not active today[/color]" % quest_id)
			return
	elif quest_type == "weekly":
		progress = quest_state.get("weekly_progress", {})
		claimed_list = quest_state.get("weekly_claimed", [])
		if not quest_id in quest_state.get("weekly_quests", []):
			_update_objective("[color=red]Quest '%s' is not active this week[/color]" % quest_id)
			return
	elif quest_type == "challenge":
		progress = quest_state.get("challenge_progress", {})
		claimed_list = quest_state.get("completed_challenges", [])
	else:
		_update_objective("[color=red]Invalid quest type[/color]")
		return

	# Check if already claimed
	if quest_id in claimed_list:
		_update_objective("[color=yellow]Quest already claimed![/color]")
		return

	# Check if complete
	if not SimQuests.check_objective(quest_id, progress):
		var pct: float = SimQuests.get_progress_percent(quest_id, progress)
		_update_objective("[color=yellow]Quest not complete! (%.0f%%)[/color]" % (pct * 100))
		return

	# Grant rewards
	var rewards: Dictionary = quest.get("rewards", {})
	var reward_text: Array[String] = []

	if int(rewards.get("gold", 0)) > 0:
		var gold_reward: int = int(rewards.get("gold", 0))
		gold += gold_reward
		state.gold = gold
		reward_text.append("+%d gold" % gold_reward)

	if int(rewards.get("xp", 0)) > 0:
		var xp_reward: int = int(rewards.get("xp", 0))
		var xp_result: Dictionary = TypingProfile.add_xp(profile, xp_reward)
		reward_text.append("+%d XP" % xp_reward)
		if int(xp_result.get("levels_gained", 0)) > 0:
			reward_text.append("LEVEL UP!")

	if rewards.has("item"):
		var item_id: String = str(rewards.get("item", ""))
		TypingProfile.add_to_inventory(profile, item_id)
		var item_name: String = SimItems.get_item_name(item_id)
		reward_text.append("+%s" % item_name)

	# Mark as claimed
	claimed_list.append(quest_id)
	if quest_type == "daily":
		quest_state["daily_claimed"] = claimed_list
	elif quest_type == "weekly":
		quest_state["weekly_claimed"] = claimed_list
	elif quest_type == "challenge":
		quest_state["completed_challenges"] = claimed_list

	_save_quest_state()
	TypingProfile.save_profile(profile)

	var quest_name: String = str(quest.get("name", quest_id))
	_update_objective("[color=lime]Claimed %s![/color] %s" % [quest_name, ", ".join(reward_text)])

func _update_log(lines: Array[String]) -> void:
	# Use word_display for multi-line info during planning
	if word_display:
		word_display.text = "\n".join(lines)

func _check_act_completion(completed_day: int) -> void:
	if not StoryManager.is_act_complete_day(completed_day):
		return

	var completion_info: Dictionary = StoryManager.get_act_completion_info(completed_day)
	if completion_info.is_empty():
		return

	var act_name: String = completion_info.get("act_name", "")
	var completion_text: String = completion_info.get("completion_text", "")
	var reward: String = completion_info.get("reward", "")

	# Award badge if there's a reward
	if not reward.is_empty():
		var badge_id: String = StoryManager.get_act_reward_id(reward)
		var newly_awarded: bool = TypingProfile.award_badge(profile, badge_id)
		if newly_awarded:
			TypingProfile.save_profile(profile)

	# Show completion dialogue
	if dialogue_box and not completion_text.is_empty():
		var lines: Array[String] = []
		lines.append("[color=lime]Act Complete: %s[/color]" % act_name)
		lines.append(completion_text)
		if not reward.is_empty():
			lines.append("[color=yellow]Reward: %s[/color]" % reward)
		dialogue_box.show_dialogue("Elder Lyra", lines)
