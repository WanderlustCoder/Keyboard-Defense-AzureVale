extends Node

var next_battle_node_id: String = ""
var last_battle_summary: Dictionary = {}
var _pending_battle_state: Dictionary = {}  # For resuming saved battles

# Practice mode state
var practice_mode: bool = false
var next_practice_lesson_id: String = ""
var practice_config: Dictionary = {}  # Optional config like difficulty

const SCENE_MENU := "res://scenes/MainMenu.tscn"
const SCENE_MAP := "res://scenes/KingdomDefense.tscn"  # Top-down RTS typing game
const SCENE_MAP_LEGACY := "res://scenes/OpenWorld.tscn"  # Open-world version
const SCENE_BATTLE := "res://scenes/Battlefield.tscn"
const SCENE_KINGDOM := "res://scenes/KingdomHub.tscn"
const SCENE_SETTINGS := "res://scenes/SettingsMenu.tscn"

# Get scene transition autoload (cached)
var _scene_transition: Node = null

func _get_transition() -> Node:
	if _scene_transition == null:
		_scene_transition = get_node_or_null("/root/SceneTransition")
	return _scene_transition

func go_to_menu() -> void:
	var transition := _get_transition()
	if transition != null:
		transition.menu_transition(SCENE_MENU)
	else:
		get_tree().change_scene_to_file(SCENE_MENU)

func go_to_map() -> void:
	var transition := _get_transition()
	if transition != null:
		transition.transition_to_scene(SCENE_MAP, SceneTransition.TransitionType.FADE, 0.4)
	else:
		get_tree().change_scene_to_file(SCENE_MAP)

func go_to_battle(node_id: String) -> void:
	practice_mode = false
	next_practice_lesson_id = ""
	practice_config = {}
	next_battle_node_id = node_id
	last_battle_summary = {}
	var transition := _get_transition()
	if transition != null:
		transition.battle_transition(SCENE_BATTLE)
	else:
		get_tree().change_scene_to_file(SCENE_BATTLE)

func go_to_practice(lesson_id: String, config: Dictionary = {}) -> void:
	practice_mode = true
	next_practice_lesson_id = lesson_id
	practice_config = config
	next_battle_node_id = ""
	last_battle_summary = {}
	var transition := _get_transition()
	if transition != null:
		transition.battle_transition(SCENE_BATTLE)
	else:
		get_tree().change_scene_to_file(SCENE_BATTLE)

func go_to_kingdom() -> void:
	var transition := _get_transition()
	if transition != null:
		transition.transition_to_scene(SCENE_KINGDOM, SceneTransition.TransitionType.FADE, 0.4)
	else:
		get_tree().change_scene_to_file(SCENE_KINGDOM)

func go_to_settings() -> void:
	var transition := _get_transition()
	if transition != null:
		transition.transition_to_scene(SCENE_SETTINGS, SceneTransition.TransitionType.FADE, 0.3)
	else:
		get_tree().change_scene_to_file(SCENE_SETTINGS)

func go_to_battle_with_state(saved_state: Dictionary) -> void:
	_pending_battle_state = saved_state
	next_battle_node_id = str(saved_state.get("node_id", ""))
	last_battle_summary = {}
	var transition := _get_transition()
	if transition != null:
		transition.battle_transition(SCENE_BATTLE)
	else:
		get_tree().change_scene_to_file(SCENE_BATTLE)

func has_pending_battle_state() -> bool:
	return not _pending_battle_state.is_empty()

func get_pending_battle_state() -> Dictionary:
	return _pending_battle_state

func clear_pending_battle_state() -> void:
	_pending_battle_state = {}
