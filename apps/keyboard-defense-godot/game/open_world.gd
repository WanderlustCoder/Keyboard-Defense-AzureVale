extends Node2D

const GameState = preload("res://sim/types.gd")
const DefaultState = preload("res://sim/default_state.gd")
const SimMap = preload("res://sim/map.gd")
const SimIntents = preload("res://sim/intents.gd")
const CommandParser = preload("res://sim/parse_command.gd")
const IntentApplier = preload("res://sim/apply_intent.gd")
const WorldTick = preload("res://sim/world_tick.gd")
const SimEnemies = preload("res://sim/enemies.gd")
const SimTick = preload("res://sim/tick.gd")

@onready var grid_renderer: Node2D = $GridRenderer
@onready var command_bar: LineEdit = $CanvasLayer/HUD/CommandBar
@onready var hp_label: Label = $CanvasLayer/HUD/TopBar/HPLabel
@onready var gold_label: Label = $CanvasLayer/HUD/TopBar/GoldLabel
@onready var day_label: Label = $CanvasLayer/HUD/TopBar/DayLabel
@onready var resources_label: Label = $CanvasLayer/HUD/TopBar/ResourcesLabel
@onready var mode_label: Label = $CanvasLayer/HUD/ModeLabel
@onready var tile_info_label: Label = $CanvasLayer/HUD/TileInfoLabel
@onready var actions_label: Label = $CanvasLayer/HUD/ActionsLabel
@onready var log_label: RichTextLabel = $CanvasLayer/HUD/LogPanel/LogLabel
@onready var menu_button: Button = $CanvasLayer/HUD/MenuButton
@onready var objective_label: RichTextLabel = $CanvasLayer/HUD/ObjectivePanel/ObjectiveLabel
@onready var enemy_panel: Panel = $CanvasLayer/HUD/EnemyPanel
@onready var enemy_list: RichTextLabel = $CanvasLayer/HUD/EnemyPanel/EnemyList
@onready var game_controller = get_node_or_null("/root/GameController")

var state: GameState
var log_lines: Array[String] = []
const MAX_LOG_LINES := 10
var typing_buffer: String = ""

func _ready() -> void:
	state = DefaultState.create("open_world")
	state.activity_mode = "exploration"
	state.resources = {"wood": 10, "stone": 5, "food": 10}  # Starting resources

	# Discover initial area around castle
	_discover_starting_area()

	command_bar.text_submitted.connect(_on_command_submitted)
	command_bar.text_changed.connect(_on_command_changed)
	command_bar.grab_focus()

	if menu_button:
		menu_button.pressed.connect(_on_menu_pressed)

	_refresh_all()
	_append_log("[color=yellow]Welcome to Keyboard Defense![/color]")
	_append_log("Your castle is under threat from roaming enemies.")
	_append_log("Use [color=cyan]arrow keys[/color] to look around.")
	_append_log("Type [color=green]explore[/color] to discover new tiles.")

func _discover_starting_area() -> void:
	# Discover 5x5 area around castle
	for dy in range(-2, 3):
		for dx in range(-2, 3):
			var pos: Vector2i = state.base_pos + Vector2i(dx, dy)
			if SimMap.in_bounds(pos.x, pos.y, state.map_w, state.map_h):
				var idx: int = pos.y * state.map_w + pos.x
				state.discovered[idx] = true
				SimMap.ensure_tile_generated(state, pos)

func _process(delta: float) -> void:
	if state.phase == "game_over":
		return

	var result: Dictionary = WorldTick.tick(state, delta)
	if result.get("changed", false):
		var events: Array = result.get("events", [])
		for event in events:
			_append_log(str(event))
		_refresh_all()

func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed:
		return

	# Arrow key navigation when command bar is empty or not focused
	if command_bar.text.is_empty() or not command_bar.has_focus():
		var moved := false
		match event.keycode:
			KEY_UP:
				_move_cursor(Vector2i(0, -1))
				moved = true
			KEY_DOWN:
				_move_cursor(Vector2i(0, 1))
				moved = true
			KEY_LEFT:
				_move_cursor(Vector2i(-1, 0))
				moved = true
			KEY_RIGHT:
				_move_cursor(Vector2i(1, 0))
				moved = true

		if moved:
			get_viewport().set_input_as_handled()
			return

	# Focus command bar on any letter key
	if event.keycode >= KEY_A and event.keycode <= KEY_Z:
		if not command_bar.has_focus():
			command_bar.grab_focus()

func _move_cursor(direction: Vector2i) -> void:
	var new_pos: Vector2i = state.cursor_pos + direction
	if SimMap.in_bounds(new_pos.x, new_pos.y, state.map_w, state.map_h):
		state.cursor_pos = new_pos
		_refresh_all()

func _on_command_changed(new_text: String) -> void:
	# Live update enemy list highlighting
	if not state.enemies.is_empty():
		_refresh_enemies()

func _on_command_submitted(text: String) -> void:
	command_bar.clear()

	if text.strip_edges().is_empty():
		return

	var input: String = text.strip_edges().to_lower()

	# During combat, check if typing an enemy word
	if state.activity_mode in ["encounter", "wave_assault"] and not state.enemies.is_empty():
		var hit_enemy: Dictionary = {}
		var hit_idx: int = -1
		for i in range(state.enemies.size()):
			var enemy: Dictionary = state.enemies[i]
			var word: String = str(enemy.get("word", "")).to_lower()
			if word == input:
				hit_enemy = enemy
				hit_idx = i
				break

		if hit_idx >= 0:
			# Hit! Damage the enemy
			var damage: int = 1
			hit_enemy["hp"] = int(hit_enemy.get("hp", 1)) - damage
			var kind: String = str(hit_enemy.get("kind", "enemy"))
			var word: String = str(hit_enemy.get("word", ""))

			if int(hit_enemy.get("hp", 0)) <= 0:
				state.enemies.remove_at(hit_idx)
				var gold_reward: int = 5 + state.day
				state.gold += gold_reward
				_append_log("[color=lime]DEFEATED %s![/color] +%d gold" % [kind.to_upper(), gold_reward])

				# Check if combat over
				if state.enemies.is_empty():
					state.activity_mode = "exploration"
					state.phase = "day"
					_append_log("[color=cyan]Combat ended! Back to exploration.[/color]")
			else:
				_append_log("[color=yellow]Hit %s![/color] HP: %d" % [kind, hit_enemy.get("hp", 0)])
				# Give enemy a new word
				hit_enemy["word"] = _get_random_word()

			_refresh_all()
			return

	# Parse and apply command
	var parse_result: Dictionary = CommandParser.parse(text, state)
	if not parse_result.get("ok", false):
		_append_log("[color=gray]Unknown: %s[/color]" % text)
		return

	var intent: Dictionary = parse_result.get("intent", {})
	var apply_result: Dictionary = IntentApplier.apply(state, intent)

	state = apply_result.get("state", state)
	var events: Array = apply_result.get("events", [])

	for event in events:
		_append_log(str(event))

	_refresh_all()

func _get_random_word() -> String:
	var words: Array[String] = ["attack", "defend", "castle", "knight", "sword", "shield", "dragon", "tower", "gold", "stone", "wood", "farm", "wall", "gate", "king", "queen", "army", "battle", "victory", "hero"]
	return words[randi() % words.size()]

func _on_menu_pressed() -> void:
	if game_controller:
		game_controller.go_to_menu()

func _refresh_all() -> void:
	_refresh_hud()
	_refresh_tile_info()
	_refresh_objective()
	_refresh_enemies()
	grid_renderer.update_state(state)

func _refresh_hud() -> void:
	hp_label.text = "HP: %d/10" % state.hp
	gold_label.text = "Gold: %d" % state.gold
	day_label.text = "Day %d" % state.day

	# Resources
	var wood: int = int(state.resources.get("wood", 0))
	var stone: int = int(state.resources.get("stone", 0))
	var food: int = int(state.resources.get("food", 0))
	resources_label.text = "Wood: %d | Stone: %d | Food: %d" % [wood, stone, food]

	# Mode with color
	var mode_text: String = state.activity_mode.to_upper()
	if state.activity_mode == "wave_assault":
		mode_text = "WAVE!"
		mode_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	elif state.activity_mode == "encounter":
		mode_text = "COMBAT"
		mode_label.add_theme_color_override("font_color", Color(1, 0.6, 0.3))
	else:
		mode_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
	mode_label.text = mode_text

	# Update actions based on context
	if state.activity_mode in ["encounter", "wave_assault"]:
		actions_label.text = "[color=red]COMBAT![/color] Type the enemy word to attack! | wait: skip turn"
	else:
		var threat_pct: int = int(state.threat_level * 100)
		actions_label.text = "explore | build wall/tower/farm | gather | end | Threat: %d%%" % threat_pct

func _refresh_objective() -> void:
	var text: String = ""
	if state.activity_mode in ["encounter", "wave_assault"]:
		text = "[color=red][b]DEFEND YOUR CASTLE![/b][/color]\n"
		text += "Type the enemy words to defeat them!"
	elif state.roaming_enemies.size() > 0:
		text = "[b]OBJECTIVE[/b]\n"
		text += "[color=orange]%d enemies[/color] approaching!\n" % state.roaming_enemies.size()
		text += "Explore, build defenses, or engage!"
	elif state.threat_level > 0.5:
		text = "[b]OBJECTIVE[/b]\n"
		text += "[color=yellow]Threat rising![/color] Prepare defenses."
	else:
		text = "[b]OBJECTIVE[/b]\n"
		text += "Explore the land. Build structures.\nDefend when enemies arrive."
	objective_label.text = text

func _refresh_enemies() -> void:
	if state.enemies.is_empty():
		enemy_panel.visible = false
		return

	enemy_panel.visible = true
	var text: String = "[b]Type the word to attack:[/b]\n\n"
	for enemy in state.enemies:
		var word: String = str(enemy.get("word", "???"))
		var hp: int = int(enemy.get("hp", 0))
		var kind: String = str(enemy.get("kind", "enemy"))
		# Highlight matching portion
		var typed: String = command_bar.text.to_lower()
		if word.begins_with(typed) and typed.length() > 0:
			var matched: String = word.substr(0, typed.length())
			var remaining: String = word.substr(typed.length())
			text += "[color=lime]%s[/color][color=yellow]%s[/color] (%s) HP:%d\n" % [matched, remaining, kind, hp]
		else:
			text += "[color=yellow]%s[/color] (%s) HP:%d\n" % [word, kind, hp]
	enemy_list.text = text

func _refresh_tile_info() -> void:
	var pos: Vector2i = state.cursor_pos
	var idx: int = pos.y * state.map_w + pos.x
	var terrain: String = SimMap.get_terrain(state, pos)
	if terrain == "":
		terrain = "Unknown"

	var info: String = "(%d,%d) %s" % [pos.x, pos.y, terrain.capitalize()]

	# Check for things at cursor
	if state.structures.has(idx):
		info += " [%s]" % str(state.structures[idx])

	# Check for roaming enemies
	for enemy in state.roaming_enemies:
		if enemy.get("pos", Vector2i(-1,-1)) == pos:
			info += " [Enemy: %s]" % enemy.get("kind", "?")

	# Check for combat enemies
	for enemy in state.enemies:
		if enemy.get("pos", Vector2i(-1,-1)) == pos:
			var word: String = str(enemy.get("word", ""))
			info += " [ENEMY: type '%s']" % word

	if pos == state.base_pos:
		info += " [YOUR CASTLE]"

	tile_info_label.text = info

func _append_log(text: String) -> void:
	log_lines.append(text)
	while log_lines.size() > MAX_LOG_LINES:
		log_lines.pop_front()

	log_label.text = "\n".join(log_lines)
