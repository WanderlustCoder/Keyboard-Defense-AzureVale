extends Node2D

const GameState = preload("res://sim/types.gd")
const DefaultState = preload("res://sim/default_state.gd")
const SimMap = preload("res://sim/map.gd")

const CommandParser = preload("res://sim/parse_command.gd")
const IntentApplier = preload("res://sim/apply_intent.gd")
const WorldTick = preload("res://sim/world_tick.gd")
const StoryManager = preload("res://game/story_manager.gd")
const SimPoi = preload("res://sim/poi.gd")
const SimEvents = preload("res://sim/events.gd")
const SimEventEffects = preload("res://sim/event_effects.gd")
const DIALOGUE_BOX_SCENE := preload("res://scenes/DialogueBox.tscn")

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

# Story integration
var dialogue_box: Node = null
var waiting_for_dialogue: bool = false
var has_shown_welcome: bool = false
var tiles_explored_count: int = 0
var first_combat_message_shown: bool = false

# POI/Event integration
var pending_event_choices: Array = []
var current_event_data: Dictionary = {}

func _ready() -> void:
	state = DefaultState.create("open_world")
	state.activity_mode = "exploration"
	state.resources = {"wood": 10, "stone": 5, "food": 10}  # Starting resources

	# Discover initial area around castle
	_discover_starting_area()

	# Initialize dialogue box for story integration
	_init_dialogue_box()

	command_bar.text_submitted.connect(_on_command_submitted)
	command_bar.text_changed.connect(_on_command_changed)
	command_bar.grab_focus()

	if menu_button:
		menu_button.pressed.connect(_on_menu_pressed)

	_refresh_all()

	# Show welcome dialogue from Elder Lyra
	_show_welcome_dialogue()


func _init_dialogue_box() -> void:
	dialogue_box = DIALOGUE_BOX_SCENE.instantiate()
	add_child(dialogue_box)
	dialogue_box.dialogue_finished.connect(_on_dialogue_finished)


func _show_welcome_dialogue() -> void:
	if has_shown_welcome:
		return
	has_shown_welcome = true

	var lines: Array[String] = [
		"Welcome, young defender, to the Open World of Keystonia.",
		"Here you may explore freely, gathering resources and discovering new lands.",
		"But beware - the Typhos Horde sends scouts to probe our defenses.",
		"Use the arrow keys to look around. Type 'explore' to venture into unknown territory.",
		"Build walls and towers to protect your castle. Type 'help' for more commands."
	]

	waiting_for_dialogue = true
	dialogue_box.show_dialogue("Elder Lyra", lines)


func _on_dialogue_finished() -> void:
	waiting_for_dialogue = false
	command_bar.grab_focus()


func _show_exploration_milestone(tiles: int) -> void:
	if waiting_for_dialogue:
		return

	var lines: Array[String] = []

	if tiles == 10:
		lines = [
			"You have discovered ten tiles of Keystonia.",
			"Each terrain offers different opportunities - forests yield wood, mountains yield stone.",
			"Keep exploring to find the best resources for your defenses."
		]
	elif tiles == 25:
		lines = [
			"Twenty-five tiles explored! Your knowledge of the land grows.",
			"Remember: the Typhos Horde grows bolder as you expand.",
			"Consider building defensive structures before venturing too far."
		]
	elif tiles == 50:
		lines = [
			"Fifty tiles! You have mapped much of Keystonia.",
			"But be warned - the deeper lands hold greater dangers.",
			"Your typing skills will be tested in the battles to come."
		]

	if not lines.is_empty():
		waiting_for_dialogue = true
		dialogue_box.show_dialogue("Elder Lyra", lines)


func _show_first_combat_message() -> void:
	if first_combat_message_shown or waiting_for_dialogue:
		return
	first_combat_message_shown = true

	var lines: Array[String] = [
		"Enemies approach! This is your first battle in the Open World.",
		"Type the word shown next to each enemy to strike them down.",
		"Speed and accuracy are your weapons - good luck, defender!"
	]

	waiting_for_dialogue = true
	dialogue_box.show_dialogue("Elder Lyra", lines)


func _show_victory_message(gold_earned: int) -> void:
	if waiting_for_dialogue:
		return

	var tip: String = StoryManager.get_contextual_tip("practice")
	if tip.is_empty():
		tip = "Practice makes perfect!"

	_append_log("[color=cyan]Elder Lyra: Well fought! Remember: %s[/color]" % tip)


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

	# Don't tick world while dialogue is showing
	if waiting_for_dialogue:
		return

	var prev_activity: String = state.activity_mode
	var result: Dictionary = WorldTick.tick(state, delta)
	if result.get("changed", false):
		var events: Array = result.get("events", [])
		for event in events:
			_append_log(str(event))

		# Check for combat start
		if prev_activity == "exploration" and state.activity_mode in ["encounter", "wave_assault"]:
			_show_first_combat_message()

		_refresh_all()

func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed:
		return

	# Skip input handling while dialogue is showing (dialogue handles its own input)
	if waiting_for_dialogue:
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
					_show_victory_message(gold_reward)
			else:
				_append_log("[color=yellow]Hit %s![/color] HP: %d" % [kind, hit_enemy.get("hp", 0)])
				# Give enemy a new word
				hit_enemy["word"] = _get_random_word()

			_refresh_all()
			return

	# Check for event choice resolution
	if SimEvents.has_pending_event(state):
		if _try_resolve_event_choice(input):
			_refresh_all()
			return

	# Handle interact command for POIs
	if input == "interact":
		_handle_interact_command()
		_refresh_all()
		return

	# Parse and apply command
	var parse_result: Dictionary = CommandParser.parse(text)
	if not parse_result.get("ok", false):
		_append_log("[color=gray]Unknown: %s[/color]" % text)
		return

	var intent: Dictionary = parse_result.get("intent", {})
	var prev_discovered: int = _count_discovered_tiles()
	var apply_result: Dictionary = IntentApplier.apply(state, intent)

	state = apply_result.get("state", state)
	var events: Array = apply_result.get("events", [])

	for event in events:
		_append_log(str(event))

	# Check for exploration milestone
	var new_discovered: int = _count_discovered_tiles()
	if new_discovered > prev_discovered:
		tiles_explored_count = new_discovered
		_show_exploration_milestone(tiles_explored_count)
		# Try to spawn POI on newly discovered tiles
		_try_spawn_poi_on_explored()

	# Check if we moved onto a POI
	_check_poi_discovery()

	_refresh_all()

func _count_discovered_tiles() -> int:
	var count: int = 0
	for discovered in state.discovered:
		if discovered:
			count += 1
	return count


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
	elif SimEvents.has_pending_event(state):
		actions_label.text = "[color=cyan]EVENT![/color] Type your choice to respond."
	else:
		var threat_pct: int = int(state.threat_level * 100)
		var actions: String = "explore | build | gather | end"
		# Check if there's a POI at cursor
		var poi_id: String = SimPoi.get_poi_at(state, state.cursor_pos)
		if poi_id != "" and not state.active_pois.get(poi_id, {}).get("interacted", false):
			actions = "[color=cyan]interact[/color] | " + actions
		actions_label.text = actions + " | Threat: %d%%" % threat_pct

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

	# Check for POI at cursor
	var poi_id: String = SimPoi.get_poi_at(state, pos)
	if poi_id != "":
		var poi_data: Dictionary = SimPoi.get_poi(poi_id)
		var poi_name: String = str(poi_data.get("name", "Unknown Location"))
		var poi_state: Dictionary = state.active_pois.get(poi_id, {})
		if poi_state.get("interacted", false):
			info += " [%s - explored]" % poi_name
		else:
			info += " [color=cyan][%s - type 'interact'][/color]" % poi_name

	tile_info_label.text = info

func _append_log(text: String) -> void:
	log_lines.append(text)
	while log_lines.size() > MAX_LOG_LINES:
		log_lines.pop_front()

	log_label.text = "\n".join(log_lines)


# POI/Event System Functions

func _try_spawn_poi_on_explored() -> void:
	# Try to spawn POIs on recently discovered tiles
	var pos: Vector2i = state.cursor_pos
	var terrain: String = SimMap.get_terrain(state, pos)
	var biome: String = _terrain_to_biome(terrain)

	# Random chance to spawn POI (10% base)
	if randf() < 0.10:
		var poi_id: String = SimPoi.try_spawn_random_poi(state, biome, pos)
		if poi_id != "":
			var poi_data: Dictionary = SimPoi.get_poi(poi_id)
			var poi_name: String = str(poi_data.get("name", "Something"))
			_append_log("[color=cyan]You discover %s![/color]" % poi_name)


func _terrain_to_biome(terrain: String) -> String:
	# Map terrain types to biomes for POI spawning
	match terrain.to_lower():
		"forest", "woods":
			return "evergrove"
		"mountain", "mountains", "hills":
			return "stonepass"
		"swamp", "marsh", "bog":
			return "mistfen"
		"plains", "grassland", "fields":
			return "sunfields"
		_:
			return "sunfields"  # Default biome


func _check_poi_discovery() -> void:
	var pos: Vector2i = state.cursor_pos
	var poi_id: String = SimPoi.get_poi_at(state, pos)
	if poi_id == "":
		return

	# Try to discover the POI
	if SimPoi.discover_poi(state, poi_id):
		var poi_data: Dictionary = SimPoi.get_poi(poi_id)
		var poi_name: String = str(poi_data.get("name", "Unknown Location"))
		var description: String = str(poi_data.get("description", ""))
		_append_log("[color=cyan]You approach %s.[/color]" % poi_name)
		if not description.is_empty():
			_append_log("[color=gray]%s[/color]" % description)
		_append_log("Type 'interact' to investigate.")


func _handle_interact_command() -> void:
	var pos: Vector2i = state.cursor_pos
	var poi_id: String = SimPoi.get_poi_at(state, pos)

	if poi_id == "":
		_append_log("[color=gray]Nothing to interact with here.[/color]")
		return

	var poi_state: Dictionary = state.active_pois.get(poi_id, {})
	if poi_state.get("interacted", false):
		_append_log("[color=gray]You have already explored this location.[/color]")
		return

	# Trigger event from POI
	var result: Dictionary = SimEvents.trigger_event_from_poi(state, poi_id)
	if not result.get("success", false):
		var error: String = str(result.get("error", "unknown"))
		if error == "no_valid_event":
			_append_log("[color=gray]Nothing of interest here right now.[/color]")
			# Mark as interacted anyway
			if state.active_pois.has(poi_id):
				state.active_pois[poi_id]["interacted"] = true
		else:
			_append_log("[color=gray]Cannot interact: %s[/color]" % error)
		return

	# Show event dialogue
	var event_data: Dictionary = result.get("event", {})
	current_event_data = event_data
	_show_event_dialogue(event_data)


func _show_event_dialogue(event_data: Dictionary) -> void:
	if not dialogue_box:
		return

	var name: String = str(event_data.get("name", "Event"))
	var description: String = str(event_data.get("description", ""))
	var prompt: String = str(event_data.get("prompt", ""))
	var choices: Array = event_data.get("choices", [])

	var lines: Array[String] = []
	if not description.is_empty():
		lines.append(description)
	if not prompt.is_empty():
		lines.append("")
		lines.append(prompt)

	# Add choice options
	if not choices.is_empty():
		lines.append("")
		lines.append("Your options:")
		pending_event_choices.clear()
		for choice in choices:
			var choice_id: String = str(choice.get("id", ""))
			var label: String = str(choice.get("label", "Option"))
			var choice_desc: String = str(choice.get("description", ""))
			var input_config: Dictionary = choice.get("input", {})
			var input_text: String = str(input_config.get("text", choice_id))
			lines.append("  Type '%s' - %s" % [input_text, label])
			if not choice_desc.is_empty():
				lines.append("    (%s)" % choice_desc)
			pending_event_choices.append({"id": choice_id, "input": input_text.to_lower()})

	waiting_for_dialogue = true
	dialogue_box.show_dialogue(name, lines)


func _try_resolve_event_choice(input: String) -> bool:
	if not SimEvents.has_pending_event(state):
		return false

	# Find matching choice
	var choice_id: String = ""
	for choice in pending_event_choices:
		if str(choice.get("input", "")).to_lower() == input.to_lower():
			choice_id = str(choice.get("id", ""))
			break

	if choice_id == "":
		return false

	# Resolve the choice
	var result: Dictionary = SimEvents.resolve_choice(state, choice_id, input)
	if result.get("success", false):
		var effects: Array = result.get("effects_applied", [])
		for effect_result in effects:
			var msg: String = str(effect_result.get("message", ""))
			if not msg.is_empty():
				_append_log("[color=lime]%s[/color]" % msg)
		_append_log("[color=cyan]You made your choice.[/color]")
		pending_event_choices.clear()
		current_event_data = {}
		return true
	else:
		var error: String = str(result.get("error", "unknown"))
		if error == "input_incomplete":
			_append_log("[color=yellow]Type the full response.[/color]")
		return false

	return false
