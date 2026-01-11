class_name SimBestiary
extends RefCounted
## Bestiary system - tracks encountered enemies and provides information

const SimEnemyTypes = preload("res://sim/enemy_types.gd")
const SimEnemyAbilities = preload("res://sim/enemy_abilities.gd")
const SimBossEncounters = preload("res://sim/boss_encounters.gd")

# =============================================================================
# LEGACY COMPATIBILITY - Keep old constants for backward compatibility
# =============================================================================

const ENEMY_CATEGORIES := ["minion", "soldier", "elite", "champion", "boss"]

# Legacy enemy info (kept for old saves)
const LEGACY_ENEMY_INFO: Dictionary = {
	"raider": {"name": "Raider", "category": "basic", "description": "Common foot soldier"},
	"scout": {"name": "Scout", "category": "basic", "description": "Fast-moving enemy"},
	"armored": {"name": "Armored", "category": "basic", "description": "Heavily protected enemy"},
	"swarm": {"name": "Swarm", "category": "basic", "description": "Weak but numerous"},
	"tank": {"name": "Tank", "category": "basic", "description": "Slow but very tough"},
	"berserker": {"name": "Berserker", "category": "basic", "description": "Fast and aggressive"},
	"phantom": {"name": "Phantom", "category": "basic", "description": "Can evade attacks"},
	"champion": {"name": "Champion", "category": "elite", "description": "Stronger than normal"},
	"healer": {"name": "Healer", "category": "elite", "description": "Heals nearby allies"},
	"elite": {"name": "Elite", "category": "elite", "description": "Has special abilities"}
}

# =============================================================================
# NEW TYPE SYSTEM QUERIES
# =============================================================================

## Get all enemy IDs by tier
static func get_enemies_by_tier(tier: int) -> Array[String]:
	return SimEnemyTypes.get_enemies_by_tier(tier)


## Get all enemy IDs by category
static func get_enemies_by_category(category: int) -> Array[String]:
	return SimEnemyTypes.get_enemies_by_category(category)


## Get enemy info from new type system
static func get_enemy_info(enemy_id: String) -> Dictionary:
	# Try new type system first
	var type_data: Dictionary = SimEnemyTypes.get_any_enemy(enemy_id)
	if not type_data.is_empty():
		return {
			"name": str(type_data.get("name", enemy_id)),
			"description": str(type_data.get("description", "")),
			"tier": int(type_data.get("tier", SimEnemyTypes.Tier.MINION)),
			"category": int(type_data.get("category", SimEnemyTypes.Category.BASIC)),
			"hp": int(type_data.get("hp", 3)),
			"armor": int(type_data.get("armor", 0)),
			"speed": float(type_data.get("speed", 1.0)),
			"damage": int(type_data.get("damage", 1)),
			"gold": int(type_data.get("gold", 1)),
			"abilities": type_data.get("abilities", []),
			"flavor": str(type_data.get("flavor", "")),
			"glyph": str(type_data.get("glyph", "?")),
			"color": type_data.get("color", Color.WHITE),
			"region": int(type_data.get("region", SimEnemyTypes.Region.ALL))
		}

	# Try boss system
	var boss_data: Dictionary = SimBossEncounters.get_boss(enemy_id)
	if not boss_data.is_empty():
		return {
			"name": str(boss_data.get("name", enemy_id)),
			"title": str(boss_data.get("title", "")),
			"description": str(boss_data.get("description", "")),
			"tier": SimEnemyTypes.Tier.BOSS,
			"category": SimEnemyTypes.Category.COMMANDER,
			"hp": int(boss_data.get("hp", 50)),
			"armor": int(boss_data.get("armor", 2)),
			"speed": float(boss_data.get("speed", 0.3)),
			"damage": int(boss_data.get("damage", 4)),
			"gold": int(boss_data.get("gold", 100)),
			"abilities": boss_data.get("abilities", []),
			"flavor": str(boss_data.get("flavor", "")),
			"glyph": str(boss_data.get("glyph", "B")),
			"color": boss_data.get("color", Color.RED),
			"region": int(boss_data.get("region", SimEnemyTypes.Region.ALL)),
			"is_boss": true,
			"phases": int(boss_data.get("phases", 1))
		}

	# Fall back to legacy
	return LEGACY_ENEMY_INFO.get(enemy_id, {})


## Get ability info
static func get_ability_info(ability_id: String) -> Dictionary:
	var ability: Dictionary = SimEnemyAbilities.get_ability(ability_id)
	if ability.is_empty():
		return {}

	return {
		"name": SimEnemyAbilities.get_ability_name(ability_id),
		"description": SimEnemyAbilities.get_ability_description(ability_id),
		"type": SimEnemyAbilities.get_ability_type(ability_id)
	}


## Get all abilities
static func get_all_abilities() -> Array[String]:
	return SimEnemyAbilities.get_all_ability_ids()


## Get all bosses
static func get_all_bosses() -> Array[String]:
	return SimBossEncounters.get_all_boss_ids()


## Get boss info
static func get_boss_info(boss_id: String) -> Dictionary:
	return get_enemy_info(boss_id)  # Works for both


## Get tier name
static func get_tier_name(tier: int) -> String:
	match tier:
		SimEnemyTypes.Tier.MINION:
			return "Minion"
		SimEnemyTypes.Tier.SOLDIER:
			return "Soldier"
		SimEnemyTypes.Tier.ELITE:
			return "Elite"
		SimEnemyTypes.Tier.CHAMPION:
			return "Champion"
		SimEnemyTypes.Tier.BOSS:
			return "Boss"
	return "Unknown"


## Get tier color
static func get_tier_color(tier: int) -> Color:
	return SimEnemyTypes.TIER_COLORS.get(tier, Color.WHITE)


## Get category name
static func get_category_name(category: int) -> String:
	match category:
		SimEnemyTypes.Category.BASIC:
			return "Basic"
		SimEnemyTypes.Category.SWARM:
			return "Swarm"
		SimEnemyTypes.Category.RANGED:
			return "Ranged"
		SimEnemyTypes.Category.STEALTH:
			return "Stealth"
		SimEnemyTypes.Category.SUPPORT:
			return "Support"
		SimEnemyTypes.Category.TANK:
			return "Tank"
		SimEnemyTypes.Category.BERSERKER:
			return "Berserker"
		SimEnemyTypes.Category.CASTER:
			return "Caster"
		SimEnemyTypes.Category.COMMANDER:
			return "Commander"
		SimEnemyTypes.Category.SIEGE:
			return "Siege"
	return "Unknown"


## Get category color
static func get_category_color(category: int) -> Color:
	return SimEnemyTypes.CATEGORY_COLORS.get(category, Color.WHITE)


## Get region name
static func get_region_name(region: int) -> String:
	return SimEnemyTypes.get_region_name(region)


## Get region color
static func get_region_color(region: int) -> Color:
	return SimEnemyTypes.get_region_color(region)


# =============================================================================
# ENCOUNTER TRACKING
# =============================================================================

static func has_encountered(profile: Dictionary, enemy_id: String) -> bool:
	var bestiary: Dictionary = profile.get("bestiary", {})
	var encounters: Dictionary = bestiary.get("encounters", {})
	return encounters.has(enemy_id)


static func has_encountered_ability(profile: Dictionary, ability_id: String) -> bool:
	var bestiary: Dictionary = profile.get("bestiary", {})
	var abilities: Dictionary = bestiary.get("ability_encounters", {})
	return abilities.has(ability_id)


static func get_defeat_count(profile: Dictionary, enemy_id: String) -> int:
	var bestiary: Dictionary = profile.get("bestiary", {})
	var encounters: Dictionary = bestiary.get("encounters", {})
	var entry: Dictionary = encounters.get(enemy_id, {})
	return int(entry.get("defeats", 0))


static func record_encounter(profile: Dictionary, enemy_id: String, defeated: bool) -> void:
	if not profile.has("bestiary"):
		profile["bestiary"] = {}
	if not profile["bestiary"].has("encounters"):
		profile["bestiary"]["encounters"] = {}

	var encounters: Dictionary = profile["bestiary"]["encounters"]
	if not encounters.has(enemy_id):
		encounters[enemy_id] = {"first_seen": Time.get_unix_time_from_system(), "defeats": 0}

	if defeated:
		encounters[enemy_id]["defeats"] = int(encounters[enemy_id].get("defeats", 0)) + 1


static func record_ability_encounter(profile: Dictionary, ability_id: String) -> void:
	if not profile.has("bestiary"):
		profile["bestiary"] = {}
	if not profile["bestiary"].has("ability_encounters"):
		profile["bestiary"]["ability_encounters"] = {}

	var abilities: Dictionary = profile["bestiary"]["ability_encounters"]
	if not abilities.has(ability_id):
		abilities[ability_id] = {"first_seen": Time.get_unix_time_from_system()}


## Alias for record_ability_encounter (legacy compatibility)
static func record_affix_encounter(profile: Dictionary, affix_id: String) -> void:
	record_ability_encounter(profile, affix_id)


static func has_encountered_affix(profile: Dictionary, affix_id: String) -> bool:
	return has_encountered_ability(profile, affix_id)


static func record_boss_encounter(profile: Dictionary, boss_id: String, defeated: bool, phase_reached: int = 1) -> void:
	if not profile.has("bestiary"):
		profile["bestiary"] = {}
	if not profile["bestiary"].has("boss_encounters"):
		profile["bestiary"]["boss_encounters"] = {}

	var bosses: Dictionary = profile["bestiary"]["boss_encounters"]
	if not bosses.has(boss_id):
		bosses[boss_id] = {
			"first_seen": Time.get_unix_time_from_system(),
			"defeats": 0,
			"highest_phase": 1
		}

	if defeated:
		bosses[boss_id]["defeats"] = int(bosses[boss_id].get("defeats", 0)) + 1

	var current_highest: int = int(bosses[boss_id].get("highest_phase", 1))
	if phase_reached > current_highest:
		bosses[boss_id]["highest_phase"] = phase_reached


# =============================================================================
# SUMMARY AND DISPLAY
# =============================================================================

static func get_summary(profile: Dictionary) -> Dictionary:
	var bestiary: Dictionary = profile.get("bestiary", {})
	var encounters: Dictionary = bestiary.get("encounters", {})
	var ability_encounters: Dictionary = bestiary.get("ability_encounters", {})
	var boss_encounters: Dictionary = bestiary.get("boss_encounters", {})

	# Count total enemies from new system
	var total_base: int = SimEnemyTypes.get_all_enemy_ids().size()
	var total_regional: int = SimEnemyTypes.get_all_regional_ids().size()
	var total_bosses: int = SimBossEncounters.get_all_boss_ids().size()
	var total_abilities: int = SimEnemyAbilities.get_all_ability_ids().size()

	var total_enemies: int = total_base + total_regional + total_bosses
	var seen_enemies: int = encounters.size() + boss_encounters.size()
	var seen_abilities: int = ability_encounters.size()

	# Calculate tier breakdown
	var tier_breakdown: Dictionary = {}
	for tier in [SimEnemyTypes.Tier.MINION, SimEnemyTypes.Tier.SOLDIER, SimEnemyTypes.Tier.ELITE, SimEnemyTypes.Tier.CHAMPION]:
		var tier_total: int = SimEnemyTypes.get_enemies_by_tier(tier).size()
		var tier_seen: int = 0
		for enemy_id in encounters.keys():
			if SimEnemyTypes.get_tier(enemy_id) == tier:
				tier_seen += 1
		tier_breakdown[tier] = {"seen": tier_seen, "total": tier_total}

	tier_breakdown[SimEnemyTypes.Tier.BOSS] = {"seen": boss_encounters.size(), "total": total_bosses}

	return {
		"enemies_seen": seen_enemies,
		"enemies_total": total_enemies,
		"abilities_seen": seen_abilities,
		"abilities_total": total_abilities,
		"bosses_defeated": _count_defeated_bosses(boss_encounters),
		"bosses_total": total_bosses,
		"tier_breakdown": tier_breakdown,
		"completion_percent": int((float(seen_enemies + seen_abilities) / float(total_enemies + total_abilities)) * 100) if (total_enemies + total_abilities) > 0 else 0
	}


static func _count_defeated_bosses(boss_encounters: Dictionary) -> int:
	var count: int = 0
	for boss_id in boss_encounters.keys():
		if int(boss_encounters[boss_id].get("defeats", 0)) > 0:
			count += 1
	return count


static func format_entry(enemy_id: String, profile: Dictionary) -> String:
	var info: Dictionary = get_enemy_info(enemy_id)
	if info.is_empty():
		return "Unknown enemy"

	var lines: Array[String] = []

	# Name and tier
	var name_str: String = str(info.get("name", enemy_id))
	var tier: int = int(info.get("tier", SimEnemyTypes.Tier.MINION))
	lines.append("[b]%s[/b] [color=gray](%s)[/color]" % [name_str, get_tier_name(tier)])

	# Description
	var desc: String = str(info.get("description", ""))
	if not desc.is_empty():
		lines.append(desc)

	# Stats
	var hp: int = int(info.get("hp", 3))
	var armor: int = int(info.get("armor", 0))
	var speed: float = float(info.get("speed", 1.0))
	var damage: int = int(info.get("damage", 1))
	lines.append("")
	lines.append("[color=red]HP: %d[/color]  [color=gray]Armor: %d[/color]  [color=cyan]Speed: %.1f[/color]  [color=orange]Dmg: %d[/color]" % [hp, armor, speed, damage])

	# Abilities
	var abilities: Array = info.get("abilities", [])
	if not abilities.is_empty():
		var ability_names: Array[String] = []
		for ability_id in abilities:
			ability_names.append(SimEnemyAbilities.get_ability_name(ability_id))
		lines.append("")
		lines.append("[color=purple]Abilities:[/color] %s" % ", ".join(ability_names))

	# Flavor text
	var flavor: String = str(info.get("flavor", ""))
	if not flavor.is_empty():
		lines.append("")
		lines.append("[i]\"%s\"[/i]" % flavor)

	# Encounter stats
	var defeats: int = get_defeat_count(profile, enemy_id)
	lines.append("")
	lines.append("[color=gold]Defeats: %d[/color]" % defeats)

	return "\n".join(lines)


static func format_boss_entry(boss_id: String, profile: Dictionary) -> String:
	var info: Dictionary = get_enemy_info(boss_id)
	if info.is_empty():
		return "Unknown boss"

	var lines: Array[String] = []

	# Name and title
	var name_str: String = str(info.get("name", boss_id))
	var title: String = str(info.get("title", ""))
	lines.append("[b][color=red]%s[/color][/b]" % name_str)
	if not title.is_empty():
		lines.append("[i]%s[/i]" % title)

	# Description
	var desc: String = str(info.get("description", ""))
	if not desc.is_empty():
		lines.append("")
		lines.append(desc)

	# Stats
	var hp: int = int(info.get("hp", 50))
	var armor: int = int(info.get("armor", 2))
	var phases: int = int(info.get("phases", 1))
	lines.append("")
	lines.append("[color=red]HP: %d[/color]  [color=gray]Armor: %d[/color]  [color=purple]Phases: %d[/color]" % [hp, armor, phases])

	# Abilities
	var abilities: Array = info.get("abilities", [])
	if not abilities.is_empty():
		var ability_names: Array[String] = []
		for ability_id in abilities:
			ability_names.append(SimEnemyAbilities.get_ability_name(ability_id))
		lines.append("")
		lines.append("[color=purple]Abilities:[/color] %s" % ", ".join(ability_names))

	# Flavor text
	var flavor: String = str(info.get("flavor", ""))
	if not flavor.is_empty():
		lines.append("")
		lines.append("[i]\"%s\"[/i]" % flavor)

	# Encounter stats
	var bestiary: Dictionary = profile.get("bestiary", {})
	var boss_encounters: Dictionary = bestiary.get("boss_encounters", {})
	var entry: Dictionary = boss_encounters.get(boss_id, {})
	var defeats: int = int(entry.get("defeats", 0))
	var highest_phase: int = int(entry.get("highest_phase", 0))

	lines.append("")
	lines.append("[color=gold]Defeats: %d[/color]  [color=cyan]Highest Phase: %d/%d[/color]" % [defeats, highest_phase, phases])

	return "\n".join(lines)


static func format_ability_entry(ability_id: String) -> String:
	var info: Dictionary = get_ability_info(ability_id)
	if info.is_empty():
		return "Unknown ability"

	var lines: Array[String] = []

	var name_str: String = str(info.get("name", ability_id))
	var ability_type: int = int(info.get("type", 0))
	var type_name: String = ""
	match ability_type:
		SimEnemyAbilities.AbilityType.PASSIVE:
			type_name = "Passive"
		SimEnemyAbilities.AbilityType.TRIGGER:
			type_name = "Trigger"
		SimEnemyAbilities.AbilityType.COOLDOWN:
			type_name = "Active"
		SimEnemyAbilities.AbilityType.DEATH:
			type_name = "On Death"

	lines.append("[b]%s[/b] [color=gray](%s)[/color]" % [name_str, type_name])
	lines.append(str(info.get("description", "")))

	return "\n".join(lines)


# =============================================================================
# FILTERING AND SORTING
# =============================================================================

## Get all enemies sorted by tier
static func get_all_enemies_sorted() -> Array[String]:
	var result: Array[String] = []

	# Add by tier order
	for tier in [SimEnemyTypes.Tier.MINION, SimEnemyTypes.Tier.SOLDIER, SimEnemyTypes.Tier.ELITE, SimEnemyTypes.Tier.CHAMPION]:
		result.append_array(SimEnemyTypes.get_enemies_by_tier(tier))

	# Add regional variants
	result.append_array(SimEnemyTypes.get_all_regional_ids())

	return result


## Get enemies for a specific region
static func get_enemies_for_region(region: int) -> Array[String]:
	if region == SimEnemyTypes.Region.ALL:
		return get_all_enemies_sorted()

	var result: Array[String] = []

	# Add base enemies (spawn in all regions)
	result.append_array(SimEnemyTypes.get_all_enemy_ids())

	# Add regional variants for this region
	result.append_array(SimEnemyTypes.get_regional_enemies_by_region(region))

	return result


## Get unencountered enemies (for discovery hints)
static func get_unencountered(profile: Dictionary) -> Array[String]:
	var result: Array[String] = []
	var all_enemies: Array[String] = get_all_enemies_sorted()

	for enemy_id in all_enemies:
		if not has_encountered(profile, enemy_id):
			result.append(enemy_id)

	return result


## Get enemies by ability (which enemies have a specific ability)
static func get_enemies_with_ability(ability_id: String) -> Array[String]:
	var result: Array[String] = []

	for enemy_id in SimEnemyTypes.get_all_ids():
		if SimEnemyTypes.has_ability(enemy_id, ability_id):
			result.append(enemy_id)

	return result
