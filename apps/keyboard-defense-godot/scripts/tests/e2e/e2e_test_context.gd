class_name E2ETestContext
extends RefCounted
## Shared test context for E2E sections.
## Provides isolated state instances for testing.

const ProgressionStateScript = preload("res://scripts/ProgressionState.gd")
const GameControllerScript = preload("res://scripts/GameController.gd")

var tree: SceneTree
var progression  # ProgressionState (Node)
var game_controller  # GameController (Node)
var viewport_size: Vector2


func _init(scene_tree: SceneTree) -> void:
	tree = scene_tree
	viewport_size = _get_viewport_size()
	_setup_test_instances()


func _get_viewport_size() -> Vector2:
	var width = ProjectSettings.get_setting("display/window/size/viewport_width")
	var height = ProjectSettings.get_setting("display/window/size/viewport_height")
	if width == null or height == null:
		return Vector2(1920, 1080)
	return Vector2(float(width), float(height))


func _setup_test_instances() -> void:
	progression = ProgressionStateScript.new()
	progression.persistence_enabled = false
	if progression.has_method("_load_static_data"):
		progression._load_static_data()
	_reset_progression()

	game_controller = GameControllerScript.new()


func _reset_progression() -> void:
	progression.gold = 0
	progression.completed_nodes = {}
	progression.purchased_upgrades = {}
	if "DEFAULT_MODIFIERS" in progression:
		progression.modifiers = progression.DEFAULT_MODIFIERS.duplicate(true)
	if "DEFAULT_MASTERY" in progression:
		progression.mastery = progression.DEFAULT_MASTERY.duplicate(true)
	progression.last_summary = {}


func reset() -> void:
	_reset_progression()
	if game_controller:
		game_controller.next_battle_node_id = ""
		if "last_battle_summary" in game_controller:
			game_controller.last_battle_summary = {}


func cleanup() -> void:
	if is_instance_valid(progression):
		progression.free()
	if is_instance_valid(game_controller):
		game_controller.free()
