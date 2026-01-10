extends SceneTree
## Balance Simulator - Headless Game Balance Testing
##
## Simulates game scenarios to validate balance without running full Godot.
## Run with: godot --headless --path . --script res://tools/balance_simulator.gd
##
## Usage:
##   godot --headless --path . --script res://tools/balance_simulator.gd
##   godot --headless --path . --script res://tools/balance_simulator.gd -- --scenario economy
##   godot --headless --path . --script res://tools/balance_simulator.gd -- --days 10
##   godot --headless --path . --script res://tools/balance_simulator.gd -- --verify

const GameState = preload("res://sim/types.gd")
const SimBalance = preload("res://sim/balance.gd")
const SimBalanceReport = preload("res://sim/balance_report.gd")
const SimBuildings = preload("res://sim/buildings.gd")
const SimEnemies = preload("res://sim/enemies.gd")

# Simulation results
var _results: Dictionary = {}
var _warnings: Array[String] = []
var _errors: Array[String] = []

func _init() -> void:
	# Parse command line arguments
	var args := OS.get_cmdline_user_args()
	var scenario := "all"
	var days := 7
	var verify_only := false
	var json_output := false
	var verbose := false

	var i := 0
	while i < args.size():
		var arg: String = args[i]
		match arg:
			"--scenario", "-s":
				if i + 1 < args.size():
					scenario = args[i + 1]
					i += 1
			"--days", "-d":
				if i + 1 < args.size():
					days = int(args[i + 1])
					i += 1
			"--verify", "-v":
				verify_only = true
			"--json", "-j":
				json_output = true
			"--verbose":
				verbose = true
			"--help", "-h":
				_print_help()
				quit(0)
				return
		i += 1

	print("=" .repeat(60))
	print("BALANCE SIMULATOR")
	print("=" .repeat(60))
	print("")

	if verify_only:
		_run_verification(json_output)
	else:
		_run_scenarios(scenario, days, verbose, json_output)

	# Print summary
	_print_summary(json_output)

	# Exit with error code if there were errors
	var exit_code := 0 if _errors.is_empty() else 1
	quit(exit_code)

func _print_help() -> void:
	print("""
Balance Simulator - Headless Game Balance Testing

Usage:
  godot --headless --path . --script res://tools/balance_simulator.gd -- [OPTIONS]

Options:
  --scenario, -s NAME    Run specific scenario (economy, waves, towers, all)
  --days, -d N           Simulate N days (default: 7)
  --verify, -v           Run balance verification only
  --json, -j             Output results as JSON
  --verbose              Show detailed simulation output
  --help, -h             Show this help

Scenarios:
  economy     Simulate resource production and spending
  waves       Simulate wave compositions and threat levels
  towers      Simulate tower damage output vs enemy HP
  combat      Simulate full combat encounters
  all         Run all scenarios (default)

Examples:
  # Run all scenarios for 7 days
  godot --headless --path . --script res://tools/balance_simulator.gd

  # Run economy simulation for 10 days
  godot --headless --path . --script res://tools/balance_simulator.gd -- --scenario economy --days 10

  # Verify balance constraints
  godot --headless --path . --script res://tools/balance_simulator.gd -- --verify
""")

func _run_verification(json_output: bool) -> void:
	print("-" .repeat(40))
	print("BALANCE VERIFICATION")
	print("-" .repeat(40))

	var output: String = SimBalanceReport.balance_verify_output()
	print(output)

	if "FAIL" in output:
		_errors.append("Balance verification failed")

func _run_scenarios(scenario: String, days: int, verbose: bool, json_output: bool) -> void:
	var scenarios_to_run: Array[String] = []

	match scenario:
		"all":
			scenarios_to_run = ["economy", "waves", "towers", "combat"]
		"economy", "waves", "towers", "combat":
			scenarios_to_run = [scenario]
		_:
			_errors.append("Unknown scenario: %s" % scenario)
			return

	for s in scenarios_to_run:
		match s:
			"economy":
				_simulate_economy(days, verbose)
			"waves":
				_simulate_waves(days, verbose)
			"towers":
				_simulate_towers(days, verbose)
			"combat":
				_simulate_combat(days, verbose)

func _simulate_economy(days: int, verbose: bool) -> void:
	print("")
	print("-" .repeat(40))
	print("ECONOMY SIMULATION (%d days)" % days)
	print("-" .repeat(40))

	var state := GameState.new()
	state.day = 1
	state.phase = "day"
	state.resources = {"wood": 10, "stone": 5, "food": 8}
	state.ap = 5
	state.gold = 0

	var economy_log: Array[Dictionary] = []

	for day in range(1, days + 1):
		state.day = day

		# Record start of day resources
		var day_start := {
			"day": day,
			"resources_start": state.resources.duplicate(),
			"gold_start": state.gold,
		}

		# Simulate building production
		var production := _simulate_production(state)
		day_start["production"] = production

		# Apply production
		for resource in production.keys():
			var current: int = int(state.resources.get(resource, 0))
			state.resources[resource] = current + int(production[resource])

		# Apply resource caps
		var caps := SimBalance.caps_for_day(day)
		var trimmed := SimBalance.apply_resource_caps(state)
		day_start["caps"] = caps
		day_start["trimmed"] = trimmed

		# Record end of day
		day_start["resources_end"] = state.resources.duplicate()
		day_start["gold_end"] = state.gold

		economy_log.append(day_start)

		if verbose:
			print("Day %d: %s -> %s (prod: %s, caps: %s)" % [
				day,
				day_start["resources_start"],
				day_start["resources_end"],
				production,
				caps
			])

	_results["economy"] = economy_log

	# Validate economy
	var final_resources: Dictionary = economy_log[-1]["resources_end"]
	print("Final resources after %d days: %s" % [days, final_resources])

	# Check for negative resources (shouldn't happen)
	for resource in final_resources.keys():
		if int(final_resources[resource]) < 0:
			_errors.append("Negative %s on day %d" % [resource, days])

	# Check resource growth is reasonable
	var initial_total: int = 10 + 5 + 8  # Starting resources
	var final_total: int = 0
	for v in final_resources.values():
		final_total += int(v)

	if final_total < initial_total:
		_warnings.append("Resources decreased over %d days (started %d, ended %d)" % [days, initial_total, final_total])

	print("Economy simulation: OK")

func _simulate_production(state: GameState) -> Dictionary:
	# Simplified production based on assumed buildings
	# In real game, would call SimBuildings.calculate_production()
	var production := {"wood": 0, "stone": 0, "food": 0}

	# Base production increases with day
	var base: int = 1 + state.day / 2
	production["wood"] = base
	production["stone"] = maxi(0, base - 1)
	production["food"] = base

	# Food bonus from balance system
	production["food"] += SimBalance.midgame_food_bonus(state)

	return production

func _simulate_waves(days: int, verbose: bool) -> void:
	print("")
	print("-" .repeat(40))
	print("WAVE SIMULATION (%d days)" % days)
	print("-" .repeat(40))

	var wave_log: Array[Dictionary] = []

	for day in range(1, days + 1):
		var wave_data := _generate_wave_for_day(day)
		wave_log.append(wave_data)

		if verbose:
			print("Day %d wave: %d enemies, %d total HP, threat level %.1f" % [
				day,
				wave_data["enemy_count"],
				wave_data["total_hp"],
				wave_data["threat_level"]
			])

	_results["waves"] = wave_log

	# Validate wave progression
	var prev_threat: float = 0.0
	for i in range(wave_log.size()):
		var wave: Dictionary = wave_log[i]
		var threat: float = float(wave["threat_level"])

		# Threat should generally increase
		if threat < prev_threat * 0.8:  # Allow some variance
			_warnings.append("Day %d threat (%.1f) lower than day %d (%.1f)" % [
				i + 1, threat, i, prev_threat
			])

		prev_threat = threat

	# Check day 7 isn't impossibly hard
	var day7_threat: float = float(wave_log[mini(6, wave_log.size() - 1)]["threat_level"])
	if day7_threat > 100:
		_warnings.append("Day 7 threat level (%.1f) may be too high" % day7_threat)

	print("Wave simulation: OK")

func _generate_wave_for_day(day: int) -> Dictionary:
	# Simplified wave generation
	# In real game, would use actual wave composition from SimEnemies
	var base_count: int = 3 + day
	var enemy_count: int = base_count

	# Calculate total HP based on day
	var base_hp: int = 10
	var hp_per_day: int = 5
	var total_hp: int = enemy_count * (base_hp + day * hp_per_day)

	# Threat level is a composite score
	var threat_level: float = enemy_count * (1.0 + day * 0.3)

	return {
		"day": day,
		"enemy_count": enemy_count,
		"total_hp": total_hp,
		"threat_level": threat_level,
		"composition": _get_wave_composition(day)
	}

func _get_wave_composition(day: int) -> Dictionary:
	# Simplified wave composition
	var comp := {}

	# Scouts always present
	comp["scout"] = 2 + day / 2

	# Raiders from day 2
	if day >= 2:
		comp["raider"] = 1 + day / 3

	# Armored from day 4
	if day >= 4:
		comp["armored"] = day / 4

	return comp

func _simulate_towers(days: int, verbose: bool) -> void:
	print("")
	print("-" .repeat(40))
	print("TOWER SIMULATION (%d days)" % days)
	print("-" .repeat(40))

	var tower_log: Array[Dictionary] = []

	# Tower types and base stats
	var tower_types := ["arrow", "fire", "ice"]

	for day in range(1, days + 1):
		var day_data := {"day": day, "towers": {}}

		for tower_type in tower_types:
			var tower_data := _calculate_tower_stats(tower_type, day)
			day_data["towers"][tower_type] = tower_data

			if verbose:
				print("Day %d %s tower: %d damage, %.1f DPS" % [
					day, tower_type,
					tower_data["damage"],
					tower_data["dps"]
				])

		tower_log.append(day_data)

	_results["towers"] = tower_log

	# Validate tower scaling
	for tower_type in tower_types:
		var day1_dps: float = float(tower_log[0]["towers"][tower_type]["dps"])
		var day7_dps: float = float(tower_log[mini(6, tower_log.size() - 1)]["towers"][tower_type]["dps"])

		# DPS should increase but not exponentially
		var growth_factor: float = day7_dps / day1_dps if day1_dps > 0 else 0

		if growth_factor > 5:
			_warnings.append("%s tower DPS growth too steep (%.1fx from day 1 to 7)" % [tower_type, growth_factor])
		elif growth_factor < 1.5:
			_warnings.append("%s tower DPS growth too flat (%.1fx from day 1 to 7)" % [tower_type, growth_factor])

	print("Tower simulation: OK")

func _calculate_tower_stats(tower_type: String, day: int) -> Dictionary:
	# Simplified tower stats
	# In real game, would use SimTowerTypes
	var base_damage: int
	var base_cooldown: float

	match tower_type:
		"arrow":
			base_damage = 5
			base_cooldown = 1.0
		"fire":
			base_damage = 8
			base_cooldown = 1.5
		"ice":
			base_damage = 4
			base_cooldown = 1.2
		_:
			base_damage = 5
			base_cooldown = 1.0

	# Scale with day
	var damage: int = base_damage + day * 2
	var cooldown: float = maxf(0.5, base_cooldown - day * 0.05)
	var dps: float = float(damage) / cooldown

	return {
		"damage": damage,
		"cooldown": cooldown,
		"dps": dps,
		"range": 3 + day / 3
	}

func _simulate_combat(days: int, verbose: bool) -> void:
	print("")
	print("-" .repeat(40))
	print("COMBAT SIMULATION (%d days)" % days)
	print("-" .repeat(40))

	var combat_log: Array[Dictionary] = []

	for day in range(1, days + 1):
		var wave := _generate_wave_for_day(day)
		var tower_dps := _calculate_total_tower_dps(day)
		var time_to_kill := float(wave["total_hp"]) / tower_dps if tower_dps > 0 else 999.0

		var combat_data := {
			"day": day,
			"wave_hp": wave["total_hp"],
			"tower_dps": tower_dps,
			"time_to_kill": time_to_kill,
			"survivable": time_to_kill < 60.0  # Must kill wave in 60 seconds
		}

		combat_log.append(combat_data)

		if verbose:
			print("Day %d: %d HP wave vs %.1f DPS = %.1fs TTK (%s)" % [
				day,
				wave["total_hp"],
				tower_dps,
				time_to_kill,
				"OK" if combat_data["survivable"] else "HARD"
			])

	_results["combat"] = combat_log

	# Validate combat balance
	var unwinnable_days: Array[int] = []
	for combat in combat_log:
		if not combat["survivable"]:
			unwinnable_days.append(int(combat["day"]))

	if not unwinnable_days.is_empty():
		_errors.append("Days potentially unwinnable: %s" % str(unwinnable_days))

	# Check difficulty curve
	var day1_ttk: float = float(combat_log[0]["time_to_kill"])
	var day7_ttk: float = float(combat_log[mini(6, combat_log.size() - 1)]["time_to_kill"])

	if day7_ttk > day1_ttk * 3:
		_warnings.append("Difficulty spike too steep (day 7 TTK %.1fs vs day 1 %.1fs)" % [day7_ttk, day1_ttk])

	print("Combat simulation: OK")

func _calculate_total_tower_dps(day: int) -> float:
	# Assume player has built towers appropriate for the day
	var num_towers: int = 1 + day / 2

	var arrow_stats := _calculate_tower_stats("arrow", day)
	var total_dps: float = num_towers * float(arrow_stats["dps"])

	return total_dps

func _print_summary(json_output: bool) -> void:
	print("")
	print("=" .repeat(60))
	print("SIMULATION SUMMARY")
	print("=" .repeat(60))

	if json_output:
		var output := {
			"results": _results,
			"warnings": _warnings,
			"errors": _errors,
			"success": _errors.is_empty()
		}
		print(JSON.stringify(output, "  "))
		return

	if _errors.is_empty() and _warnings.is_empty():
		print("All simulations passed with no issues.")
	else:
		if not _errors.is_empty():
			print("")
			print("ERRORS (%d):" % _errors.size())
			for err in _errors:
				print("  [ERROR] %s" % err)

		if not _warnings.is_empty():
			print("")
			print("WARNINGS (%d):" % _warnings.size())
			for warn in _warnings:
				print("  [WARN] %s" % warn)

	print("")
	print("Result: %s" % ("PASS" if _errors.is_empty() else "FAIL"))
