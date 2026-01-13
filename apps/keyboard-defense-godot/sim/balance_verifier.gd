class_name BalanceVerifier
extends RefCounted
## Balance verification utility for validating game balance curves.
## Analyzes economy progression, combat scaling, and identifies potential issues.

const SimEnemies = preload("res://sim/enemies.gd")
const SimTowerTypes = preload("res://sim/tower_types.gd")
const SimBalance = preload("res://sim/balance.gd")

# =============================================================================
# VERIFICATION THRESHOLDS
# =============================================================================

## Economy thresholds
const MIN_PRODUCTION_BY_DAY_3 := 6   # Minimum combined resource production
const MIN_GOLD_BY_DAY_5 := 50        # Minimum gold accumulated
const MAX_DAYS_WITHOUT_TOWER := 3    # Maximum days before first tower affordable

## Combat thresholds
const MIN_DPS_TO_ENEMY_HP_RATIO := 0.3  # Tower DPS should be at least 30% of enemy HP per wave
const MAX_ENEMY_SPEED_DAY_1 := 2        # Max enemy speed on day 1
const MAX_ENEMY_HP_DAY_1 := 4           # Max enemy HP on day 1

## Cost efficiency bounds
const MIN_TOWER_DAMAGE_PER_COST := 0.05  # Minimum damage per total resource cost
const MAX_TOWER_DAMAGE_PER_COST := 0.5   # Maximum damage per total resource cost (prevents OP towers)

# =============================================================================
# ECONOMY VERIFICATION
# =============================================================================

## Verify economy progression curve
static func verify_economy() -> Dictionary:
	var issues: Array[String] = []
	var warnings: Array[String] = []
	var stats: Dictionary = {}

	# Load building data
	var buildings_data := _load_buildings()
	if buildings_data.is_empty():
		issues.append("ERROR: Could not load buildings.json")
		return {"passed": false, "issues": issues, "warnings": warnings, "stats": stats}

	# Analyze production buildings
	var production_buildings := ["farm", "lumber", "quarry"]
	var total_production := 0

	for building_id in production_buildings:
		var building: Dictionary = buildings_data.get(building_id, {})
		var production: Dictionary = building.get("production", {})
		var cost: Dictionary = building.get("cost", {})

		var prod_value := 0
		for resource in production.keys():
			prod_value += int(production[resource])
		total_production += prod_value

		var cost_value := _calculate_total_cost(cost)
		var efficiency := float(prod_value) / max(1.0, float(cost_value)) if cost_value > 0 else 0.0

		stats[building_id] = {
			"production": prod_value,
			"cost": cost_value,
			"efficiency": efficiency
		}

	# Check production threshold
	if total_production < MIN_PRODUCTION_BY_DAY_3:
		warnings.append("Low total production: %d (minimum %d recommended)" % [total_production, MIN_PRODUCTION_BY_DAY_3])

	# Check tier 4 monument costs
	var monuments := ["grand_cathedral", "war_academy", "trade_emporium", "wizard_tower"]
	for monument_id in monuments:
		var monument: Dictionary = buildings_data.get(monument_id, {})
		var cost: Dictionary = monument.get("cost", {})
		var cost_value := _calculate_total_cost(cost)

		if cost_value < 500:
			warnings.append("Monument %s cost too low: %d (should be 500+)" % [monument_id, cost_value])
		elif cost_value > 2000:
			warnings.append("Monument %s cost very high: %d (may be unreachable)" % [monument_id, cost_value])

		stats["monument_" + monument_id] = {"cost": cost_value}

	# Check tower costs are achievable
	var first_tower_cost := _calculate_total_cost({"wood": 4, "stone": 8})  # Arrow tower
	var first_building_cost := _calculate_total_cost({"wood": 10})  # Farm

	stats["first_tower_affordability"] = first_tower_cost
	stats["first_building_affordability"] = first_building_cost

	if first_tower_cost > 20:
		warnings.append("First tower cost may be too high: %d resources" % first_tower_cost)

	return {
		"passed": issues.is_empty(),
		"issues": issues,
		"warnings": warnings,
		"stats": stats
	}


# =============================================================================
# COMBAT VERIFICATION
# =============================================================================

## Verify combat scaling curves
static func verify_combat() -> Dictionary:
	var issues: Array[String] = []
	var warnings: Array[String] = []
	var stats: Dictionary = {}

	# Check enemy scaling by day
	var enemy_kinds := ["raider", "scout", "armored", "swarm", "tank", "berserker"]

	for day in range(1, 8):
		var day_stats: Dictionary = {}
		var max_hp := 0
		var max_speed := 0
		var max_armor := 0

		for kind in enemy_kinds:
			var hp_bonus := SimEnemies.hp_bonus_for_day(kind, day)
			var armor := SimEnemies.armor_for_day(kind, day)
			var speed := SimEnemies.speed_for_day(kind, day)

			# Base HP formula: 2 + day/3 + threat/4
			var base_hp := 2 + int(day / 3)
			var total_hp := base_hp + hp_bonus

			if total_hp > max_hp:
				max_hp = total_hp
			if speed > max_speed:
				max_speed = speed
			if armor > max_armor:
				max_armor = armor

			day_stats[kind] = {
				"hp": total_hp,
				"armor": armor,
				"speed": speed
			}

		stats["day_%d" % day] = {
			"enemies": day_stats,
			"max_hp": max_hp,
			"max_speed": max_speed,
			"max_armor": max_armor
		}

		# Day 1 sanity checks
		if day == 1:
			if max_speed > MAX_ENEMY_SPEED_DAY_1:
				warnings.append("Day 1 max enemy speed too high: %d (max %d)" % [max_speed, MAX_ENEMY_SPEED_DAY_1])
			if max_hp > MAX_ENEMY_HP_DAY_1:
				warnings.append("Day 1 max enemy HP too high: %d (max %d)" % [max_hp, MAX_ENEMY_HP_DAY_1])

	# Check boss scaling
	var boss_days := [5, 10, 15, 20]
	for boss_day in boss_days:
		var boss_kind := SimEnemies.get_boss_for_day(boss_day)
		if boss_kind.is_empty():
			issues.append("No boss defined for day %d" % boss_day)
			continue

		var boss_config: Dictionary = SimEnemies.BOSS_KINDS.get(boss_kind, {})
		var boss_hp_bonus := int(boss_config.get("hp_bonus", 0))
		var boss_base_hp := 10 + int(boss_day / 2)
		var total_boss_hp := boss_base_hp + boss_hp_bonus

		stats["boss_day_%d" % boss_day] = {
			"kind": boss_kind,
			"hp": total_boss_hp,
			"armor": int(boss_config.get("armor", 0))
		}

	# Check tower damage output vs enemy HP
	var basic_towers := SimTowerTypes.CATEGORY_BASIC
	var avg_tower_damage := 0.0
	var tower_count := 0

	for tower_id in basic_towers:
		var tower_stats: Dictionary = SimTowerTypes.get_base_stats(tower_id)
		var damage := float(tower_stats.get("damage", 0))
		var attack_speed := float(tower_stats.get("attack_speed", 1.0))
		var dps := damage * attack_speed
		avg_tower_damage += dps
		tower_count += 1

	if tower_count > 0:
		avg_tower_damage /= float(tower_count)

	stats["avg_basic_tower_dps"] = avg_tower_damage

	# Compare DPS to day 1 enemy HP
	var day1_max_hp: int = stats.get("day_1", {}).get("max_hp", 3)
	var dps_ratio := avg_tower_damage / float(max(1, day1_max_hp))

	stats["dps_to_hp_ratio"] = dps_ratio

	if dps_ratio < MIN_DPS_TO_ENEMY_HP_RATIO:
		warnings.append("Tower DPS may be too low compared to enemy HP (ratio: %.2f)" % dps_ratio)

	return {
		"passed": issues.is_empty(),
		"issues": issues,
		"warnings": warnings,
		"stats": stats
	}


# =============================================================================
# TOWER COST EFFICIENCY
# =============================================================================

## Verify tower cost efficiency balance
static func verify_tower_efficiency() -> Dictionary:
	var issues: Array[String] = []
	var warnings: Array[String] = []
	var stats: Dictionary = {}

	for tower_id in SimTowerTypes.ALL_TOWER_IDS:
		var tower_stats: Dictionary = SimTowerTypes.get_base_stats(tower_id)
		var cost: Dictionary = tower_stats.get("cost", {})
		var damage := float(tower_stats.get("damage", 0))
		var attack_speed := float(tower_stats.get("attack_speed", 1.0))

		var total_cost := _calculate_total_cost(cost)
		var dps := damage * attack_speed
		var efficiency := dps / float(max(1, total_cost))

		stats[tower_id] = {
			"damage": damage,
			"attack_speed": attack_speed,
			"dps": dps,
			"cost": total_cost,
			"efficiency": efficiency
		}

		# Check efficiency bounds (skip non-damaging towers)
		if dps > 0:
			if efficiency < MIN_TOWER_DAMAGE_PER_COST:
				warnings.append("Tower %s may be underpowered (efficiency: %.3f)" % [tower_id, efficiency])
			elif efficiency > MAX_TOWER_DAMAGE_PER_COST:
				warnings.append("Tower %s may be overpowered (efficiency: %.3f)" % [tower_id, efficiency])

	# Check category progression
	var category_avg_efficiency: Dictionary = {}
	for category in [SimTowerTypes.TowerCategory.BASIC, SimTowerTypes.TowerCategory.ADVANCED,
					 SimTowerTypes.TowerCategory.SPECIALIST, SimTowerTypes.TowerCategory.LEGENDARY]:
		var towers := SimTowerTypes.get_towers_in_category(category)
		var total_eff := 0.0
		var count := 0

		for tower_id in towers:
			var tower_stat: Dictionary = stats.get(tower_id, {})
			var eff: float = tower_stat.get("efficiency", 0.0)
			if eff > 0:
				total_eff += eff
				count += 1

		var avg_eff := total_eff / float(max(1, count)) if count > 0 else 0.0
		var category_name := SimTowerTypes.get_category_name(towers[0] if towers.size() > 0 else "")
		category_avg_efficiency[category_name] = avg_eff

	stats["category_efficiency"] = category_avg_efficiency

	return {
		"passed": issues.is_empty(),
		"issues": issues,
		"warnings": warnings,
		"stats": stats
	}


# =============================================================================
# PROGRESSION MILESTONES
# =============================================================================

## Verify progression milestone pacing
static func verify_progression() -> Dictionary:
	var issues: Array[String] = []
	var warnings: Array[String] = []
	var stats: Dictionary = {}

	# Expected progression milestones
	var milestones := {
		1: {"description": "Tutorial complete, first building built"},
		3: {"description": "Basic production chain established"},
		5: {"description": "First boss, basic tower defense"},
		7: {"description": "Market/economy buildings available"},
		10: {"description": "Second boss, advanced towers unlock"},
		15: {"description": "Third boss, specialist content"},
		20: {"description": "Final boss, end-game content"}
	}

	# Enemy unlock progression
	var enemy_unlock_days := {
		"raider": 1,
		"scout": 3,
		"swarm": 4,
		"armored": 5,
		"berserker": 5,
		"tank": 6,
		"phantom": 6,
		"champion": 7,
		"healer": 7,
		"elite": 8
	}

	stats["milestones"] = milestones
	stats["enemy_unlocks"] = enemy_unlock_days

	# Check that enemy unlocks align with progression
	for enemy_kind in enemy_unlock_days.keys():
		var unlock_day: int = enemy_unlock_days[enemy_kind]
		if unlock_day > 10 and enemy_kind not in ["elite"]:
			warnings.append("Enemy %s unlocks late (day %d)" % [enemy_kind, unlock_day])

	# Check affix unlock progression
	var affix_unlock_days := {
		"swift": 6,
		"armored": 6,
		"resilient": 6,
		"shielded": 6,
		"thorny": 6,
		"ghostly": 7,
		"splitting": 8,
		"regenerating": 9,
		"commanding": 9,
		"enraged": 10,
		"vampiric": 10,
		"explosive": 12
	}

	stats["affix_unlocks"] = affix_unlock_days

	# Check boss days have preceding content
	for boss_day in [5, 10, 15, 20]:
		var boss_kind := SimEnemies.get_boss_for_day(boss_day)
		if boss_kind.is_empty():
			issues.append("Missing boss for day %d" % boss_day)

	return {
		"passed": issues.is_empty(),
		"issues": issues,
		"warnings": warnings,
		"stats": stats
	}


# =============================================================================
# FULL BALANCE REPORT
# =============================================================================

## Run all balance verifications and generate comprehensive report
static func generate_full_report() -> Dictionary:
	var economy_result := verify_economy()
	var combat_result := verify_combat()
	var tower_result := verify_tower_efficiency()
	var progression_result := verify_progression()

	var all_passed := (
		economy_result.passed and
		combat_result.passed and
		tower_result.passed and
		progression_result.passed
	)

	var all_issues: Array[String] = []
	var all_warnings: Array[String] = []

	all_issues.append_array(economy_result.issues)
	all_issues.append_array(combat_result.issues)
	all_issues.append_array(tower_result.issues)
	all_issues.append_array(progression_result.issues)

	all_warnings.append_array(economy_result.warnings)
	all_warnings.append_array(combat_result.warnings)
	all_warnings.append_array(tower_result.warnings)
	all_warnings.append_array(progression_result.warnings)

	return {
		"passed": all_passed,
		"issues": all_issues,
		"warnings": all_warnings,
		"sections": {
			"economy": economy_result,
			"combat": combat_result,
			"towers": tower_result,
			"progression": progression_result
		},
		"summary": {
			"total_issues": all_issues.size(),
			"total_warnings": all_warnings.size(),
			"economy_passed": economy_result.passed,
			"combat_passed": combat_result.passed,
			"towers_passed": tower_result.passed,
			"progression_passed": progression_result.passed
		}
	}


## Generate human-readable balance report
static func format_report(report: Dictionary) -> String:
	var lines: Array[String] = []

	lines.append("=" * 60)
	lines.append("KEYBOARD DEFENSE BALANCE VERIFICATION REPORT")
	lines.append("=" * 60)
	lines.append("")

	var summary: Dictionary = report.get("summary", {})
	var status := "PASSED" if report.get("passed", false) else "FAILED"
	lines.append("Overall Status: %s" % status)
	lines.append("Total Issues: %d" % summary.get("total_issues", 0))
	lines.append("Total Warnings: %d" % summary.get("total_warnings", 0))
	lines.append("")

	# Issues
	var issues: Array = report.get("issues", [])
	if issues.size() > 0:
		lines.append("-" * 40)
		lines.append("ISSUES (must fix):")
		for issue in issues:
			lines.append("  ! %s" % str(issue))
		lines.append("")

	# Warnings
	var warnings: Array = report.get("warnings", [])
	if warnings.size() > 0:
		lines.append("-" * 40)
		lines.append("WARNINGS (review recommended):")
		for warning in warnings:
			lines.append("  ? %s" % str(warning))
		lines.append("")

	# Section details
	var sections: Dictionary = report.get("sections", {})

	# Economy section
	if sections.has("economy"):
		var economy: Dictionary = sections["economy"]
		var economy_stats: Dictionary = economy.get("stats", {})
		lines.append("-" * 40)
		lines.append("ECONOMY BALANCE:")
		lines.append("  Production Buildings:")
		for building_id in ["farm", "lumber", "quarry"]:
			var bstats: Dictionary = economy_stats.get(building_id, {})
			lines.append("    %s: production=%d, cost=%d, efficiency=%.2f" % [
				building_id,
				bstats.get("production", 0),
				bstats.get("cost", 0),
				bstats.get("efficiency", 0.0)
			])
		lines.append("")

	# Combat section
	if sections.has("combat"):
		var combat: Dictionary = sections["combat"]
		var combat_stats: Dictionary = combat.get("stats", {})
		lines.append("-" * 40)
		lines.append("COMBAT SCALING:")
		lines.append("  Enemy HP by Day:")
		for day in range(1, 8):
			var day_stats: Dictionary = combat_stats.get("day_%d" % day, {})
			lines.append("    Day %d: max_hp=%d, max_armor=%d, max_speed=%d" % [
				day,
				day_stats.get("max_hp", 0),
				day_stats.get("max_armor", 0),
				day_stats.get("max_speed", 0)
			])
		lines.append("  Avg Basic Tower DPS: %.1f" % combat_stats.get("avg_basic_tower_dps", 0.0))
		lines.append("  DPS to HP Ratio: %.2f" % combat_stats.get("dps_to_hp_ratio", 0.0))
		lines.append("")

	# Tower section
	if sections.has("towers"):
		var towers: Dictionary = sections["towers"]
		var tower_stats: Dictionary = towers.get("stats", {})
		lines.append("-" * 40)
		lines.append("TOWER EFFICIENCY:")
		var category_eff: Dictionary = tower_stats.get("category_efficiency", {})
		for category_name in category_eff.keys():
			lines.append("  %s avg efficiency: %.3f" % [category_name, category_eff[category_name]])
		lines.append("")

	lines.append("=" * 60)
	lines.append("END OF REPORT")
	lines.append("=" * 60)

	return "\n".join(lines)


# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

static func _load_buildings() -> Dictionary:
	var file := FileAccess.open("res://data/buildings.json", FileAccess.READ)
	if file == null:
		return {}

	var text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var error := json.parse(text)
	if error != OK:
		return {}

	var data: Dictionary = json.data
	return data.get("buildings", {})


static func _calculate_total_cost(cost: Dictionary) -> int:
	var total := 0
	# Weight resources differently for comparison
	var weights := {
		"wood": 1,
		"stone": 1,
		"food": 1,
		"gold": 1  # Gold is generally harder to acquire
	}

	for resource in cost.keys():
		var amount: int = int(cost[resource])
		var weight: int = int(weights.get(resource, 1))
		total += amount * weight

	return total
