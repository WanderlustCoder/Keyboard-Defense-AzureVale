extends SceneTree
## E2E Test Runner CLI Entry Point
##
## Usage:
##   Run all:     godot --headless --script res://scripts/tests/e2e/run_e2e.gd
##   Run section: godot --headless --script res://scripts/tests/e2e/run_e2e.gd -- --section=battle
##   List:        godot --headless --script res://scripts/tests/e2e/run_e2e.gd -- --list
##   Verbose:     godot --headless --script res://scripts/tests/e2e/run_e2e.gd -- --verbose

const E2ERunner = preload("res://scripts/tests/e2e/e2e_runner.gd")


func _init() -> void:
	var args := _parse_args()

	if args.has("help"):
		_print_help()
		quit(0)
		return

	if args.has("list"):
		_list_sections()
		quit(0)
		return

	var runner := E2ERunner.new(self)
	var result: Dictionary

	if args.has("section"):
		var section_id: String = args["section"]
		print("[e2e] Running section: %s" % section_id)
		result = runner.run_section(section_id)
	else:
		print("[e2e] Running all sections")
		result = runner.run_all()

	_print_result(result, args.has("verbose"))

	runner.cleanup()

	var exit_code: int = 0 if int(result.get("failed", 0)) == 0 else 1
	quit(exit_code)


func _parse_args() -> Dictionary:
	var args: Dictionary = {}
	var cmd_args: PackedStringArray = OS.get_cmdline_user_args()

	for arg in cmd_args:
		if arg == "--help" or arg == "-h":
			args["help"] = true
		elif arg == "--list":
			args["list"] = true
		elif arg == "--verbose" or arg == "-v":
			args["verbose"] = true
		elif arg.begins_with("--section="):
			args["section"] = arg.substr(10)

	return args


func _print_help() -> void:
	print("E2E Test Runner for Keyboard Defense")
	print("")
	print("Usage:")
	print("  godot --headless --script res://scripts/tests/e2e/run_e2e.gd [options]")
	print("")
	print("Options:")
	print("  --help, -h       Show this help message")
	print("  --list           List available test sections")
	print("  --section=NAME   Run only the specified section")
	print("  --verbose, -v    Show detailed output including events")
	print("")
	print("Available sections:")
	print("  menu        Main menu navigation and buttons")
	print("  battle      Battle flow, typing combat, victory/defeat")
	print("  campaign    Campaign map, RTS mode, phases")
	print("  kingdom     Kingdom management, upgrades")
	print("  settings    Settings menu, controls")
	print("  pause       Pause menu functionality")
	print("  transitions Scene transitions, panel animations")
	print("")
	print("Examples:")
	print("  Run all tests:    godot --headless --script res://scripts/tests/e2e/run_e2e.gd")
	print("  Run battle only:  godot --headless --script res://scripts/tests/e2e/run_e2e.gd -- --section=battle")


func _list_sections() -> void:
	var runner := E2ERunner.new(self)
	print("Available E2E Test Sections:")
	print("")
	for section_id in runner.list_sections():
		print("  - %s" % section_id)
	print("")
	print("Use --section=NAME to run a specific section")
	runner.cleanup()


func _print_result(result: Dictionary, verbose: bool) -> void:
	var tests: int = int(result.get("tests", 0))
	var failed: int = int(result.get("failed", 0))
	var messages: Array = result.get("messages", [])
	var events: Array = result.get("events", [])

	print("")
	print("=" .repeat(50))

	if failed > 0:
		print("[e2e] FAIL %d/%d tests" % [failed, tests])
		print("")
		print("Failures:")
		for msg in messages:
			printerr("  - %s" % str(msg))
	else:
		print("[e2e] OK %d tests" % tests)

	if verbose and events.size() > 0:
		print("")
		print("Events captured:")
		for event in events:
			print("  * %s" % str(event))

	print("=" .repeat(50))
