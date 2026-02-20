class_name E2ERunner
extends RefCounted
## Orchestrates E2E test section execution.
## Can run all sections or individual sections by ID.

const E2ETestContext = preload("res://scripts/tests/e2e/e2e_test_context.gd")
const E2EErrorMonitor = preload("res://scripts/tests/e2e/e2e_error_monitor.gd")

const SECTIONS := {
	"menu": "res://scripts/tests/e2e/sections/menu_flow_section.gd",
	"battle": "res://scripts/tests/e2e/sections/battle_flow_section.gd",
	"campaign": "res://scripts/tests/e2e/sections/campaign_flow_section.gd",
	"kingdom": "res://scripts/tests/e2e/sections/kingdom_flow_section.gd",
	"settings": "res://scripts/tests/e2e/sections/settings_flow_section.gd",
	"pause": "res://scripts/tests/e2e/sections/pause_flow_section.gd",
	"transitions": "res://scripts/tests/e2e/sections/transitions_flow_section.gd"
}

var _context: E2ETestContext
var _error_monitor: E2EErrorMonitor
var _tree: SceneTree


func _init(tree: SceneTree) -> void:
	_tree = tree
	_context = E2ETestContext.new(tree)
	_error_monitor = E2EErrorMonitor.new()


## Run all sections
func run_all() -> Dictionary:
	var results: Array[Dictionary] = []
	for section_id in SECTIONS.keys():
		print("[e2e] running section: %s" % section_id)
		var result: Dictionary = run_section(section_id)
		results.append(result)
		_context.reset()
	return _aggregate_results(results)


## Run a single section by ID
func run_section(section_id: String) -> Dictionary:
	if not SECTIONS.has(section_id):
		return {
			"tests": 0,
			"failed": 1,
			"messages": ["Unknown section: %s" % section_id],
			"section": section_id
		}

	var script = load(SECTIONS[section_id])
	if script == null:
		return {
			"tests": 0,
			"failed": 1,
			"messages": ["Failed to load section: %s" % section_id],
			"section": section_id
		}

	var section = script.new()
	section.set_context(_context)
	section.set_error_monitor(_error_monitor)

	_error_monitor.start_capture()
	var result: Dictionary = section.run()
	var captured_errors: Array = _error_monitor.stop_capture()

	result = _merge_errors(result, captured_errors)
	result["section"] = section_id
	return result


## List available section IDs
func list_sections() -> Array[String]:
	var section_ids: Array[String] = []
	for key in SECTIONS.keys():
		section_ids.append(key)
	return section_ids


## Aggregate results from multiple sections
func _aggregate_results(results: Array[Dictionary]) -> Dictionary:
	var total_tests: int = 0
	var total_failed: int = 0
	var all_messages: Array = []
	var all_events: Array = []

	for result in results:
		total_tests += int(result.get("tests", 0))
		total_failed += int(result.get("failed", 0))
		var section_id: String = str(result.get("section", "unknown"))
		for msg in result.get("messages", []):
			all_messages.append("[%s] %s" % [section_id, msg])
		for event in result.get("events", []):
			all_events.append("[%s] %s" % [section_id, event])

	return {
		"tests": total_tests,
		"failed": total_failed,
		"messages": all_messages,
		"events": all_events
	}


## Merge captured errors into result
func _merge_errors(result: Dictionary, captured_errors: Array) -> Dictionary:
	var messages: Array = result.get("messages", [])
	var added_failures: int = 0

	for error_entry in captured_errors:
		var error_type: String = str(error_entry.get("type", "error"))
		var error_msg: String = str(error_entry.get("message", ""))
		if error_type == "error":
			messages.append("[CAPTURED ERROR] %s" % error_msg)
			added_failures += 1
		elif error_type == "perf":
			messages.append("[PERF WARNING] %s" % error_msg)

	result["messages"] = messages
	result["failed"] = int(result.get("failed", 0)) + added_failures
	return result


## Cleanup resources
func cleanup() -> void:
	if _context:
		_context.cleanup()
