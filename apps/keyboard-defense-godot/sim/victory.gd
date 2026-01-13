class_name SimVictory
extends RefCounted
## Victory condition tracking system.
## Manages different victory paths and progress toward each.

const SimFactions = preload("res://sim/factions.gd")
const SimResearch = preload("res://sim/research.gd")

# =============================================================================
# VICTORY CONDITION DEFINITIONS
# =============================================================================

## Victory condition types
const VICTORY_CONQUEST := "conquest"
const VICTORY_ECONOMIC := "economic"
const VICTORY_TECHNOLOGICAL := "technological"
const VICTORY_STORY := "story"
const VICTORY_SURVIVAL := "survival"

## Victory thresholds
const ECONOMIC_GOLD_TARGET := 10000
const SURVIVAL_WAVES_TARGET := 50

## All available victory conditions with metadata
const VICTORY_CONDITIONS := {
	VICTORY_CONQUEST: {
		"name": "Conquest",
		"description": "Defeat all enemy factions or establish alliances with all.",
		"icon": "conquest",
		"color": "#F44336"
	},
	VICTORY_ECONOMIC: {
		"name": "Economic Dominance",
		"description": "Accumulate %d gold to become the richest kingdom." % ECONOMIC_GOLD_TARGET,
		"icon": "gold",
		"color": "#FFC107"
	},
	VICTORY_TECHNOLOGICAL: {
		"name": "Technological Supremacy",
		"description": "Complete all research to unlock every technology.",
		"icon": "research",
		"color": "#2196F3"
	},
	VICTORY_STORY: {
		"name": "Campaign Complete",
		"description": "Complete all campaign acts and defeat the final boss.",
		"icon": "story",
		"color": "#9C27B0"
	},
	VICTORY_SURVIVAL: {
		"name": "Survival Champion",
		"description": "Survive %d waves without losing." % SURVIVAL_WAVES_TARGET,
		"icon": "survival",
		"color": "#4CAF50"
	}
}


# =============================================================================
# VICTORY CHECKING
# =============================================================================

## Check all victory conditions and return any achieved
static func check_victory_conditions(state) -> Array[String]:
	var achieved: Array[String] = []

	if check_conquest_victory(state):
		achieved.append(VICTORY_CONQUEST)
	if check_economic_victory(state):
		achieved.append(VICTORY_ECONOMIC)
	if check_technological_victory(state):
		achieved.append(VICTORY_TECHNOLOGICAL)
	if check_story_victory(state):
		achieved.append(VICTORY_STORY)
	if check_survival_victory(state):
		achieved.append(VICTORY_SURVIVAL)

	return achieved


## Conquest: All factions defeated or allied
static func check_conquest_victory(state) -> bool:
	var faction_ids := SimFactions.get_faction_ids()
	if faction_ids.is_empty():
		return false

	for faction_id in faction_ids:
		var at_war := SimFactions.is_at_war(state, faction_id)
		var allied := SimFactions.has_alliance(state, faction_id)
		# Must either be allied or have defeated (not at war and hostile)
		if at_war:
			return false
		if not allied and SimFactions.get_relation(state, faction_id) < SimFactions.RELATION_FRIENDLY:
			return false

	return true


## Economic: Accumulate target gold
static func check_economic_victory(state) -> bool:
	return state.gold >= ECONOMIC_GOLD_TARGET


## Technological: Complete all research
static func check_technological_victory(state) -> bool:
	var research := SimResearch.instance()
	var all_research := research.get_all_research()
	if all_research.is_empty():
		return false

	for item in all_research:
		var research_id: String = str(item.get("id", ""))
		if not state.completed_research.has(research_id):
			return false

	return true


## Story: Complete final campaign act
static func check_story_victory(state) -> bool:
	# Check if the final act is completed
	# This would be tracked in the story manager
	return state.get("story_completed", false)


## Survival: Survive target number of waves
static func check_survival_victory(state) -> bool:
	# Count total waves survived (approximated by day count for wave-based games)
	var waves_survived := _get_waves_survived(state)
	return waves_survived >= SURVIVAL_WAVES_TARGET


static func _get_waves_survived(state) -> int:
	# Each day can have multiple waves, estimate based on day and wave tracking
	# For simplicity, use day * average_waves_per_day
	return state.day * 2  # Assumes ~2 waves per day


# =============================================================================
# PROGRESS TRACKING
# =============================================================================

## Get progress toward all victory conditions
static func get_all_progress(state) -> Dictionary:
	return {
		VICTORY_CONQUEST: get_conquest_progress(state),
		VICTORY_ECONOMIC: get_economic_progress(state),
		VICTORY_TECHNOLOGICAL: get_technological_progress(state),
		VICTORY_STORY: get_story_progress(state),
		VICTORY_SURVIVAL: get_survival_progress(state)
	}


## Get conquest progress
static func get_conquest_progress(state) -> Dictionary:
	var faction_ids := SimFactions.get_faction_ids()
	var total := faction_ids.size()
	var secured := 0

	for faction_id in faction_ids:
		if SimFactions.has_alliance(state, faction_id):
			secured += 1
		elif not SimFactions.is_at_war(state, faction_id) and SimFactions.get_relation(state, faction_id) >= SimFactions.RELATION_FRIENDLY:
			secured += 1

	return {
		"current": secured,
		"target": total,
		"percent": float(secured) / float(maxi(total, 1)) * 100.0,
		"complete": secured >= total and total > 0
	}


## Get economic progress
static func get_economic_progress(state) -> Dictionary:
	var current := state.gold
	var peak_gold := state.get("peak_gold", state.gold)

	return {
		"current": current,
		"peak": peak_gold,
		"target": ECONOMIC_GOLD_TARGET,
		"percent": float(current) / float(ECONOMIC_GOLD_TARGET) * 100.0,
		"complete": current >= ECONOMIC_GOLD_TARGET
	}


## Get technological progress
static func get_technological_progress(state) -> Dictionary:
	var research := SimResearch.instance()
	var all_research := research.get_all_research()
	var total := all_research.size()
	var completed := state.completed_research.size()

	return {
		"current": completed,
		"target": total,
		"percent": float(completed) / float(maxi(total, 1)) * 100.0,
		"complete": completed >= total and total > 0
	}


## Get story progress
static func get_story_progress(state) -> Dictionary:
	# Story progress tracked separately
	var current_act := state.get("current_act", 1)
	var total_acts := 5  # Acts 1-5

	return {
		"current": current_act,
		"target": total_acts,
		"percent": float(current_act - 1) / float(total_acts) * 100.0,
		"complete": state.get("story_completed", false)
	}


## Get survival progress
static func get_survival_progress(state) -> Dictionary:
	var waves := _get_waves_survived(state)

	return {
		"current": waves,
		"target": SURVIVAL_WAVES_TARGET,
		"percent": float(waves) / float(SURVIVAL_WAVES_TARGET) * 100.0,
		"complete": waves >= SURVIVAL_WAVES_TARGET
	}


# =============================================================================
# VICTORY STATE MANAGEMENT
# =============================================================================

## Initialize victory state for new game
static func init_victory_state(state) -> void:
	state.victory_achieved = []
	state.victory_checked = false
	state.peak_gold = 0
	state.story_completed = false
	state.current_act = 1


## Update victory tracking (call each turn/wave)
static func update_victory_tracking(state) -> Dictionary:
	var result := {"newly_achieved": [], "progress": {}}

	# Track peak gold
	if state.gold > state.get("peak_gold", 0):
		state.peak_gold = state.gold

	# Check for newly achieved victories
	var current_achieved := check_victory_conditions(state)
	var previous := state.get("victory_achieved", [])

	for victory_type in current_achieved:
		if not previous.has(victory_type):
			result.newly_achieved.append(victory_type)
			if not state.has("victory_achieved"):
				state.victory_achieved = []
			state.victory_achieved.append(victory_type)

	# Get current progress
	result.progress = get_all_progress(state)

	return result


## Get victory condition info by type
static func get_victory_info(victory_type: String) -> Dictionary:
	return VICTORY_CONDITIONS.get(victory_type, {}).duplicate(true)


## Get all victory condition types
static func get_victory_types() -> Array[String]:
	var types: Array[String] = []
	for key in VICTORY_CONDITIONS.keys():
		types.append(key)
	return types


## Check if any victory has been achieved
static func has_any_victory(state) -> bool:
	var achieved: Array = state.get("victory_achieved", [])
	return not achieved.is_empty()


## Get summary of victory status
static func get_victory_summary(state) -> Dictionary:
	var progress := get_all_progress(state)
	var achieved: Array = state.get("victory_achieved", [])

	# Find closest to completion
	var closest_type := ""
	var closest_percent := 0.0

	for victory_type in VICTORY_CONDITIONS.keys():
		if achieved.has(victory_type):
			continue
		var p: Dictionary = progress.get(victory_type, {})
		var percent: float = float(p.get("percent", 0.0))
		if percent > closest_percent:
			closest_percent = percent
			closest_type = victory_type

	return {
		"total_conditions": VICTORY_CONDITIONS.size(),
		"achieved_count": achieved.size(),
		"achieved": achieved.duplicate(),
		"closest_type": closest_type,
		"closest_percent": closest_percent,
		"progress": progress
	}
