class_name E2ESection
extends RefCounted
## Base class for E2E test sections.
## Each section tests a logical flow through the game.

const TestHelper = preload("res://scripts/tests/test_helper.gd")
const E2ETestContext = preload("res://scripts/tests/e2e/e2e_test_context.gd")
const E2EErrorMonitor = preload("res://scripts/tests/e2e/e2e_error_monitor.gd")
const E2EInputSimulator = preload("res://scripts/tests/e2e/e2e_input_simulator.gd")

var _context: E2ETestContext
var _error_monitor: E2EErrorMonitor
var _helper: TestHelper
var _input: E2EInputSimulator
var _events: Array[String] = []


func set_context(context: E2ETestContext) -> void:
	_context = context
	_input = E2EInputSimulator.new(context.tree)


func set_error_monitor(monitor: E2EErrorMonitor) -> void:
	_error_monitor = monitor


## Override in subclasses to return section name
func get_section_name() -> String:
	return "base"


## Run the section tests
func run() -> Dictionary:
	_helper = TestHelper.new()
	_events.clear()

	_run_tests()

	return _build_result()


## Override this in subclasses to implement tests
func _run_tests() -> void:
	pass


## Add an event message for tracking
func _add_event(message: String) -> void:
	_events.append(message)
	if _error_monitor:
		_error_monitor.record_event(message)


## Build result dictionary in standard format
func _build_result() -> Dictionary:
	var summary: Dictionary = _helper.summary()
	summary["events"] = _events.duplicate()
	return summary


## Helper: Load and instantiate a scene
func _instantiate_scene(scene_path: String) -> Node:
	var packed = load(scene_path)
	if packed == null:
		_helper.assert_true(false, "Scene loads: %s" % scene_path)
		return null
	var instance = packed.instantiate()
	_helper.assert_true(instance != null, "Scene instantiates: %s" % scene_path)
	return instance


## Helper: Add node to tree root for testing
func _add_to_root(node: Node) -> void:
	if _context and _context.tree:
		_context.tree.root.add_child(node)


## Helper: Cleanup node safely
func _cleanup(node: Node) -> void:
	if is_instance_valid(node):
		if node.get_parent() != null:
			node.get_parent().remove_child(node)
		node.free()


## Helper: Find all children recursively
func _find_all_children(node: Node) -> Array:
	var result: Array = []
	for child in node.get_children():
		result.append(child)
		result.append_array(_find_all_children(child))
	return result


## Helper: Get node or null without errors
func _get_node_safe(parent: Node, path: String) -> Node:
	if parent == null:
		return null
	return parent.get_node_or_null(path)
